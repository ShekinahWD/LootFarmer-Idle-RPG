extends Node
## Player-feedback balance audit (2026-11-06; report docs/LootFarmer_Player_Feedback_Balance_Audit_Report.md).
## Non-gating (Playbook 60.1 / 112.1 / 112.2): run deliberately, never from tools/run_probes.py.
## Steps the unmodified LootSimulation at 0.1 s (real aggro/assist, enemy skills, boss telegraphs, heals and
## summons, supplies, auto-cast). Builds come from a JSON file (tools/player_feedback_audit_builds.py);
## every seeded value is labelled (level, merge levels, lifetime kills, supply mastery/stock, currency
## granted for purchases). Prestige cards come from the game's real Prestige transaction (begin_prestige /
## choose_card) over a named opportunity set. Gear must be a non-legacy id an enemy drops (or its
## evolution) and the equip slot is asserted. Nothing here edits catalog files or production code:
## what-if counterfactuals only replace cached enemy definitions in memory or hold attackers back from
## this script's loop, and are labelled in the CSV "whatif" column.
## Encounter kinds: boss (duel), spot (one variant spot of N actors, no respawn), single (one actor),
## farm (Focus-farm one spot with real respawns for N minutes).
## Usage (see docs/Player_Feedback_Audit_Evidence/README.md):
##   godot --headless --path . res://tests/player_feedback_audit.tscn -- --probe --profile=probe-audit48
##         --no-autosave --first-run-complete --builds=res://docs/Player_Feedback_Audit_Evidence/builds_main.json
##         --csv=res://tests/tmp/player_feedback_audit/trials_main.csv [--only=build_id,...]
## Exit code: 0 all rows valid, 1 any invalid build/encounter, 2 unreadable builds or watchdog.
var sim
var rows: Array=[]
var failures:=0
var policy_potion:=0.0
var policy_cast:=false
## What-if counterfactuals (in memory only, labelled in the CSV "whatif" column; never project edits):
## cap3: at most 3 normal enemies may attack at once (extras wait); desync: a normal's first skill cast
## comes 2-8 s after it aggroes instead of at once; v3_115: skill-variant damage x1.15 instead of x1.35.
var whatif: Array=[]
var wrng:=RandomNumberGenerator.new()

func arg(key: String,default):
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--"+key+"="):return a.split("=",true,1)[1]
    return default

func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(5400.0,true,false,true).timeout.connect(func():print("PFA_AUDIT watchdog");get_tree().quit(2))
    var spec=JSON.parse_string(FileAccess.get_file_as_string(str(arg("builds","res://docs/Player_Feedback_Audit_Evidence/builds_main.json"))))
    if not spec is Dictionary:
        print("PFA_AUDIT cannot read builds");get_tree().quit(2);return
    sim=load("res://scripts/game/simulation.gd").new();add_child(sim);sim.set_physics_process(false)
    var started:=Time.get_ticks_msec()
    var only: Array=Array(str(arg("only","")).split(",",false))
    for b in spec.builds:
        if not only.is_empty() and not only.has(str(b.id)):continue
        for enc in b.encounters:
            for seed in enc.get("seeds",b.get("seeds",spec.get("seeds",[1,2,3]))):
                var row:=encounter(b,enc,spec.card_sets,int(seed))
                rows.append(row)
                print("ROW %s %s %s v%d n%d s%d %s %.1fs left %.0f%% min %.0f%% dps_in %.1f pot %d" % [b.id,row.enc,row.target,int(row.variant),int(row.count),int(seed),row.result,float(row.time),float(row.player_left)*100,float(row.player_min)*100,float(row.incoming_dps),int(row.potions)])
    write_csv(str(arg("csv","res://tests/tmp/player_feedback_audit/trials.csv")))
    print("PFA_AUDIT rows %d failures %d runtime %.0fs" % [rows.size(),failures,(Time.get_ticks_msec()-started)/1000.0])
    get_tree().quit(1 if failures else 0)

func gi(id: String) -> int:
    for g in range(sim.catalog.groups.size()):
        if sim.catalog.groups[g].id==id:return g
    return -1

# ---------------------------------------------------------------- legitimacy
func source_of(id: String) -> Dictionary:
    if not sim.catalog.items.has(id):return {"ok":false,"why":"unknown id"}
    var e: Dictionary=sim.catalog.items[id]
    if e.get("legacy",false):return {"ok":false,"why":"legacy id"}
    var droppers: Array=[]
    for g in sim.catalog.groups:
        if e.kind=="skill":
            if id=="skill_"+str(e.skill) and g.skills.has(e.skill):droppers.append(str(g.id))
        elif g.loot.has(id):droppers.append(str(g.id))
    if not droppers.is_empty():return {"ok":true,"how":"drop","from":droppers}
    if e.kind=="weapon":
        for other in sim.catalog.items:
            if sim.catalog.items[other].get("next","")==id and source_of(other).ok:
                return {"ok":true,"how":"evolution","from":[other]}
    return {"ok":false,"why":"not obtainable"}

var gems_granted:=0.0
var coins_granted:=0.0
func buy(id: String,times: int,group:=-1) -> bool:
    for i in range(times):
        var cost:=float(sim.upgrade_cost(id,group))
        if str(sim.catalog.upgrades[id].currency)=="gems":sim.state.gems=float(sim.state.gems)+cost;gems_granted+=cost
        else:sim.state.coins=float(sim.state.coins)+cost;coins_granted+=cost
        if not sim.buy_upgrade(id,group):return false
    return true

func prestige(set_: Dictionary) -> String:
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman")
    if int(sim.state.group_kills[gi("boss-snowman")])<1:sim.state.group_kills[gi("boss-snowman")]=1
    for id in set_.ready:
        if sim.state.consumed.has(id):return "opportunity already consumed "+str(id)
        sim.state.opportunities[id]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: completed in the earlier run
    if not sim.campaign.begin_prestige():return "Prestige refused: "+sim.campaign.prestige_block_reason()
    var guard:=0
    while not sim.state.prestige_batch.is_empty() and guard<80:
        guard+=1
        var offered: Array=sim.campaign.offered_cards()
        var pick: String=str(offered[0])
        for want in set_.picks:
            if offered.has(want):pick=want;break
        if not sim.campaign.choose_card(pick):return "card refused "+pick
    return "" if sim.state.prestige_batch.is_empty() else "batch unfinished"

func give(id: String,m: int) -> String:
    var src:=source_of(id)
    if not src.ok:return id+": "+str(src.why)
    if m<0 or m>sim.merge_cap(id):return id+": merge beyond cap"
    if not sim.add_item(id,1):return id+": no room"
    var r: Dictionary=sim.record(id)
    r.merge=m;r.extras={} # fixture: merge level from copies; random extra roll removed for comparability
    return ""

func build(b: Dictionary,card_sets: Dictionary,seed: int) -> String:
    gems_granted=0.0;coins_granted=0.0
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;sim.held=false
    SaveService.write_blocked=false;sim.rng.seed=seed
    for name in b.get("prestige",[]):
        var why:=prestige(card_sets[str(name)])
        if why!="":return why
    sim.rng.seed=seed
    var st: int=int(b.stage)
    sim.state.player_level=int(b.level);sim.state.xp=0.0 # fixture: level (XP reported)
    sim.state.stage=st;sim.state.unlocked_stage=maxi(st,int(sim.state.unlocked_stage));sim.state.reward_stage=maxi(st,int(sim.state.reward_stage)) # fixture: stage reached
    for id in b.get("kills",{}):
        var g:=gi(str(id))
        if g<0:return "unknown kill id "+str(id)
        sim.state.group_kills[g]=maxi(int(sim.state.group_kills[g]),int(b.kills[id])) # fixture: lifetime kills (achievements)
    var gear: Array=[]
    if b.get("weapon",[]).size()>0:gear.append(b.weapon)
    if b.get("outfit",[]).size()>0:gear.append(b.outfit)
    gear.append_array(b.get("stored",[]))
    var skills: Array=b.get("skills",[])
    var room: int=gear.size()+skills.size()-sim.equipment_slot_count()
    if room>0 and not buy("gear_slots",room):return "gear slots"
    for pair in gear+skills:
        var why:=give(str(pair[0]),int(pair[1]))
        if why!="":return why
    if b.get("weapon",[]).size()>0 and (not sim.equip(str(b.weapon[0])) or sim.state.weapon!=str(b.weapon[0])):return "weapon equip"
    if b.get("outfit",[]).size()>0 and (not sim.equip(str(b.outfit[0])) or sim.state.outfit!=str(b.outfit[0])):return "outfit equip"
    if skills.size()>1 and not buy("skill_slots",skills.size()-1):return "skill slots"
    var auto_skills: bool=str(b.get("cast","none"))=="auto"
    if auto_skills and skills.size()>0 and not buy("skill_auto_slots",skills.size()):return "auto skill slots"
    for i in range(skills.size()):
        if not sim.campaign.equip_skill(str(skills[i][0]),i) or sim.state.skills[i]!=str(skills[i][0]):return "skill equip "+str(skills[i][0])
        if auto_skills:sim.state.skill_auto[i]=true
        if not buy("cooldown_"+str(sim.catalog.items[skills[i][0]].skill),int(b.get("cooldown_levels",0))):return "cooldown upgrade"
    var supplies: Dictionary=b.get("supplies",{})
    if supplies.size()>1 and not buy("supply_slots",supplies.size()-1):return "supply slots"
    for id in supplies:
        sim.state.supply_uses[id]=int(supplies[id][0])*int(sim.catalog.progression.change17.supply_uses_per_level) # fixture: successful uses
        if not sim.add_item(id,int(supplies[id][1]),false):return "supply room "+id
    var auto: Array=b.get("auto",[])
    if not auto.is_empty():
        if not buy("auto_use",auto.size()) or not buy("use_speed",int(b.get("use_speed",0))):return "auto supply"
        for id in auto:
            if not sim.bind_auto(sim.state.supplies.find(id)):return "auto bind "+str(id)
    for id in b.get("type_upgrades",{}):
        for target in b.type_upgrades[id]:
            var g:=gi(str(target[0]))
            sim.campaign.discover_spot(g,2) # fixture: type found while exploring
            if not buy(str(id),int(target[1]),g):return "type upgrade "+str(id)+" "+sim.upgrade_block_reason(str(id),g)
    sim.state.coins=0.0;sim.state.gems=0.0
    return ""

# ---------------------------------------------------------------- encounter
var tally:={}
func _on_feedback(actor_id: String,amount: float,healing: bool) -> void:
    if actor_id=="player" and not healing:tally.taken+=amount
    elif actor_id!="player" and healing:tally.enemy_heal+=amount
func _on_cast(actor_id: String,key: String,_pos: Vector2) -> void:
    if actor_id=="player":tally.casts+=1
    else:tally.enemy_casts+=1

func encounter(b: Dictionary,enc: Dictionary,card_sets: Dictionary,seed: int) -> Dictionary:
    var row:={"build":b.id,"label":b.get("label",""),"evidence":b.get("evidence","constructed fixture"),"stage":int(b.stage),"level":int(b.level),
        "prestiges":0,"cards":"","enc":str(enc.kind),"target":str(enc.get("group","")),"variant":int(enc.get("variant",2)),"count":int(enc.get("count",1)),"seed":seed,
        "result":"invalid","time":0.0,"player_left":0.0,"player_min":1.0,"taken":0.0,"incoming_dps":0.0,"potions":0,"casts":0,"enemy_casts":0,"enemy_heal":0.0,
        "enemies_left":0,"target_hp_left":0.0,"damage":0.0,"hp":0.0,"defense":0.0,"lifesteal":0.0,"kills":0,"deaths":0,"coins":0.0,"xp":0.0,"minutes":0.0,
        "gems_granted":0.0,"coins_granted":0.0,"why":""}
    var why:=build(b,card_sets,seed)
    var g:=gi(str(enc.get("group","")))
    if why=="" and g<0:why="unknown group"
    var variant:=int(enc.get("variant",2))
    var count:=int(enc.get("count",3))
    if why=="" and not sim.catalog.groups[g].boss:
        sim.campaign.discover_spot(g,variant) # fixture: spot found
        if count>3 and not buy("spawn_amount",count-3,g):why="spawn upgrade "+sim.upgrade_block_reason("spawn_amount",g)
    if why=="" and str(enc.kind)=="farm":
        if not buy("focus",1,g):why="focus"
    if why=="" and int(sim.catalog.groups[g].stage)!=int(b.stage):why="encounter on another stage"
    row.gems_granted=gems_granted;row.coins_granted=coins_granted
    if why!="":
        row.why=why;failures+=1;push_error(str(b.id)+": "+why);return row
    sim._reset_world()
    var s: Dictionary=sim.stats()
    row.damage=s.damage;row.hp=s.hp;row.defense=s.defense;row.lifesteal=s.lifesteal
    row.prestiges=int(sim.state.prestiges);row.cards=" ".join(sim.state.owned_cards)
    policy_potion=float(b.get("potion_at",0.0));policy_cast=str(b.get("cast","none"))=="manual"
    whatif=Array(enc.get("whatif",b.get("whatif",[])));wrng.seed=seed*7919
    row["whatif"]="+".join(whatif)
    var patched: Array=[]
    if whatif.has("v3_115"):
        for gg in range(sim.catalog.groups.size()):
            if sim.catalog.groups[gg].boss or sim.catalog.groups[gg].skills.is_empty():continue
            var d: Dictionary=sim._build_definition(gg,3)
            d.damage=float(d.damage)*1.15/1.35;d.make_read_only()
            sim._definitions[gg*8+3]=d;patched.append(gg*8+3)
    for tag in whatif:
        if not str(tag).begins_with("late_dmg"):continue
        var f: float=float(str(tag).trim_prefix("late_dmg"))/100.0
        for gg in range(sim.catalog.groups.size()):
            if sim.catalog.groups[gg].boss or int(sim.catalog.groups[gg].stage)<7:continue
            for vv in [0,1,2,3]:
                var d2: Dictionary=sim._build_definition(gg,vv)
                d2.damage=float(d2.damage)*f;d2.make_read_only()
                sim._definitions[gg*8+vv]=d2;patched.append(gg*8+vv)
    tally={"taken":0.0,"enemy_heal":0.0,"casts":0,"enemy_casts":0}
    sim.feedback.connect(_on_feedback);sim.spell_cast.connect(_on_cast)
    if str(enc.kind)=="farm":farm(row,g,variant,float(enc.get("minutes",10)))
    else:duel(row,enc,g,variant,count)
    sim.feedback.disconnect(_on_feedback);sim.spell_cast.disconnect(_on_cast)
    for key in patched:sim._definitions.erase(key)
    row.taken=tally.taken;row.casts=tally.casts;row.enemy_casts=tally.enemy_casts;row.enemy_heal=tally.enemy_heal
    row.incoming_dps=tally.taken/maxf(.1,float(row.time))
    return row

func policy_step() -> void:
    var p: Dictionary=sim.state.player
    if p.hp<=0:return
    if policy_potion>0 and p.hp<sim.stats().hp*policy_potion and sim.quantity("potion")>0 and sim.state.use_cd<=0 and sim.campaign.in_combat():
        if sim.use_item("potion"):tally["pots"]=int(tally.get("pots",0))+1
    if policy_cast:
        for i in range(1+sim.level("skill_slots")):sim.campaign.cast(i)
    if whatif.has("desync"):
        for e in sim.state.enemies:
            if e.hp<=0 or sim.catalog.groups[int(e.group)].boss:continue
            if e.aggro and not e.get("_ds",false):
                e["_ds"]=true;e.skill_timer=maxf(float(e.get("skill_timer",0)),wrng.randf_range(2.0,8.0))
            elif not e.aggro:e["_ds"]=false
    if whatif.has("cap3"):
        var attackers: Array=[]
        for e in sim.state.enemies:
            if e.hp>0 and e.aggro and not e.get("returning",false) and not sim.catalog.groups[int(e.group)].boss:attackers.append(e)
        if attackers.size()>3:
            var pp: Vector2=sim.position_of(p)
            attackers.sort_custom(func(a,b2):return sim.position_of(a).distance_to(pp)<sim.position_of(b2).distance_to(pp))
            for e in attackers.slice(3):
                e.cooldown=maxf(float(e.cooldown),.15);e.windup=0.0
                e.skill_timer=maxf(float(e.get("skill_timer",0)),.15)

func duel(row: Dictionary,enc: Dictionary,g: int,variant: int,count: int) -> void:
    var fighters: Array=[]
    var single: bool=str(enc.kind)=="single"
    for e in sim.state.enemies:
        var mine: bool=int(e.group)==g and (sim.catalog.groups[g].boss or int(e.get("variant",2))==variant)
        if mine and single and not fighters.is_empty():mine=false
        if mine:fighters.append(e)
        else:e.hp=0.0;e.respawn=1e9 # fixture: only this encounter fights
    if fighters.is_empty():row.why="no actors";failures+=1;return
    var p: Dictionary=sim.state.player
    var left_x:=INF
    for e in fighters:left_x=minf(left_x,float(e.x))
    p.x=left_x-(30.0 if sim.catalog.groups[g].boss else 40.0);p.y=float(fighters[0].y);p.idle=1.0;p.hp=sim.stats().hp
    sim.campaign.reveal()
    var nearest: Dictionary=fighters[0]
    for e in fighters:
        if sim.position_of(e).distance_to(sim.position_of(p))<sim.position_of(nearest).distance_to(sim.position_of(p)):nearest=e
    sim.select_target(str(nearest.id))
    if sim.catalog.groups[g].boss:nearest.aggro=true
    var stock: int=sim.quantity("potion")
    var limit: float=float(enc.get("limit",600))
    var t:=0.0
    var maxhp: float=sim.stats().hp
    var result:="timeout"
    while t<limit:
        policy_step()
        sim.step(.1);t+=.1
        for e in fighters:
            if e.hp<=0:e.respawn=1e9
        row.player_min=minf(row.player_min,maxf(0,p.hp)/maxhp)
        if p.hp<=0:result="loss";break
        if fighters.all(func(e):return e.hp<=0):result="win";break
    row.result=result;row.time=t
    row.player_left=maxf(0,p.hp)/maxhp
    row.potions=stock-sim.quantity("potion")
    var alive:=0;var hp_left:=0.0;var hp_max:=0.0
    for e in fighters:
        var mx: float=sim.enemy_definition(int(e.group),int(e.get("variant",2))).hp
        hp_max+=mx;hp_left+=maxf(0,e.hp)
        if e.hp>0:alive+=1
    row.enemies_left=alive;row.target_hp_left=hp_left/maxf(1,hp_max)

func farm(row: Dictionary,g: int,variant: int,minutes: float) -> void:
    for e in sim.state.enemies:
        if int(e.group)!=g or int(e.get("variant",2))!=variant:e.hp=0.0;e.respawn=1e9 # fixture: isolate the farmed spot
    if not sim.focus(g,variant):row.why="focus refused";failures+=1;return
    var spot: Vector2=sim.campaign.spot(g,variant)
    sim.state.player.x=spot.x-60;sim.state.player.y=spot.y
    sim.campaign.reveal()
    var deaths:=[0]
    var on_dead:=func():deaths[0]+=1
    sim.revived.connect(on_dead)
    var kills0:=int(sim.state.group_kills[g]);var coins0:=float(sim.state.coins)
    var xp0:=xp_total()
    var stock: int=sim.quantity("potion")
    var t:=0.0
    var maxhp: float=sim.stats().hp
    while t<minutes*60.0:
        policy_step()
        sim.step(.1);t+=.1
        if sim.state.player.hp>0:row.player_min=minf(row.player_min,float(sim.state.player.hp)/maxhp)
    sim.revived.disconnect(on_dead)
    row.time=t;row.minutes=minutes;row.result="farm"
    row.kills=int(sim.state.group_kills[g])-kills0;row.deaths=deaths[0]
    row.coins=float(sim.state.coins)-coins0;row.xp=xp_total()-xp0
    row.potions=stock-sim.quantity("potion")
    row.player_left=float(sim.state.player.hp)/maxhp

func xp_total() -> float:
    var total:=float(sim.state.xp)
    for l in range(1,int(sim.state.player_level)):total+=sim.xp_required(l)
    return total

## Results never go to production folders: res:// paths are globalized; the parent folder is created
## (tests/tmp/ is git-ignored).
func write_csv(path: String) -> void:
    if path=="":return
    path=ProjectSettings.globalize_path(path)
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    var cols:=["build","whatif","label","evidence","stage","level","prestiges","cards","enc","target","variant","count","seed","result","time","player_left","player_min","taken","incoming_dps","potions","casts","enemy_casts","enemy_heal","enemies_left","target_hp_left","damage","hp","defense","lifesteal","kills","deaths","coins","xp","minutes","gems_granted","coins_granted","why"]
    var f:=FileAccess.open(path,FileAccess.WRITE)
    if f==null:print("PFA_AUDIT cannot write ",path);return
    f.store_line(",".join(cols))
    for r in rows:
        var cells: Array=[]
        for c in cols:
            var v=r.get(c,"")
            cells.append("\""+(("%.4f" % v) if v is float else str(v)).replace("\"","\"\"")+"\"")
        f.store_line(",".join(cells))
    f.close()
    print("PFA_AUDIT wrote ",path)
