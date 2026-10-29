extends Node
## Change 36 final-boss audit (non-gating, run deliberately; Playbook 60.1 / 140).
## Green Alien, Spring II (Stage 8), behind the 13-key route. Every build in the builds file is
## constructed through real game operations wherever one exists and proven obtainable before a duel:
## - Prestige cards come from a real Prestige transaction (begin_prestige/choose_card) over the
##   opportunities a named earlier run would have made ready; the run reset then clears inventory.
## - Gem and Coin upgrades are bought with buy_upgrade; the currency granted for them is recorded.
## - Every weapon, outfit and skill must be a non-legacy id an enemy drops, or (weapons) the evolution
##   of one; its merge level is within the cap; the copies it needs are reported. Equips are asserted.
## - Supply mastery is set as successful uses (3 per level, Change 36); stock as owned copies.
## - Keys are the 13 real non-final boss ids. Player level is set, with the XP it needs reported.
## Fixture injections (level, merge levels, stock, uses, granted currency) are labelled in the CSV.
## Each duel steps the unmodified simulation at 0.1 s (basic attacks, auto-cast skills, auto supplies,
## boss Heal/skills/summons, helpers) until a kill, a death or the time limit. Seeds vary crits and
## the boss's skill picks. A death ends the attempt: the boss regenerates to full out of combat.
## Usage: godot --headless --path . res://tests/change_36_final_boss_audit.tscn -- --probe
##        --profile=audit36 --no-autosave --first-run-complete [--builds=res://...json] [--only=id,id]
##        [--csv=res://...csv] [--limit=900]
## Farm mode (--mode=farm): each entry of the file's "farms" list builds its farmer the same way, buys
## that spot's per-type upgrades with recorded currency, focuses the spot and plays the unmodified
## simulation for the given minutes; it reports kills, XP, Coins, Gems, deaths and every drop rolled.
const FINAL_ID:="boss-green-alien"
var sim
var checks:=0
var failures:=0
var limit:=900.0
var rows: Array=[]

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)

func arg(key: String,default):
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--"+key+"="):return a.split("=",true,1)[1]
    return default

func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(3000.0,true,false,true).timeout.connect(func():print("AUDIT36 watchdog");get_tree().quit(2))
    limit=float(arg("limit",900))
    var path: String=arg("builds","res://docs/Change_36_Evidence/final_boss_builds.json")
    var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
    if not parsed is Dictionary:
        print("AUDIT36 cannot read builds file ",path);get_tree().quit(2);return
    var spec: Dictionary=parsed
    sim=LootSimulation.new();add_child(sim);sim.set_physics_process(false)
    var only: Array=Array(str(arg("only","")).split(",",false))
    if str(arg("mode","duel"))=="farm":
        farm_all(spec)
        print("AUDIT36_CHECKS %d FAILURES %d" % [checks,failures])
        get_tree().quit(1 if failures else 0)
        return
    encounter_summary()
    for build in spec.builds:
        if not only.is_empty() and not only.has(str(build.id)):continue
        for seed in build.get("seeds",spec.get("seeds",[1,2,3])):
            var row:=duel(build,spec.card_sets,int(seed))
            rows.append(row)
            print("AUDIT_ROW %-5s seed %d %-7s %5.0fs | boss left %5.1f%% min %5.1f%% | player %5.1f%% | dmg %6.0f hp %6.0f def %4.0f crit %.2f x%.2f ls %.3f | heals %d (%.0f) summons %d | supplies %s | cast %s" % [
                build.id,seed,row.result,row.time,row.boss_left*100,row.boss_min*100,row.player_left*100,row.damage,row.hp,row.defense,row.crit,row.crit_damage,row.lifesteal,row.boss_heals,row.boss_healed,row.helpers,row.supplies,row.player_casts])
    write_csv(str(arg("csv","res://docs/Change_36_Evidence/final_boss_trials.csv")))
    print("AUDIT36_CHECKS %d FAILURES %d" % [checks,failures])
    get_tree().quit(1 if failures else 0)

## Authored numbers of the encounter, read from the live catalog and ability rules.
func encounter_summary() -> void:
    var g:=group_index(FINAL_ID)
    var d: Dictionary=sim.enemy_definition(g,2)
    var rule: SummonRule=sim.abilities.summon_rule(FINAL_ID)
    var helper: Dictionary=sim.enemy_definition(group_index(rule.helper_id),LootSimulation.HELPER_VARIANT)
    print("ENCOUNTER boss %s level %d hp %.0f damage %.1f interval %.1fs defense %.0f final %s stage %d" % [FINAL_ID,int(d.level),float(d.hp),float(d.damage),float(d.interval),float(d.defense),str(d.final),int(d.stage)])
    print("ENCOUNTER heal below %.0f%%: %.1f%% of max (%.0f HP), cooldown %.0fs; action gap %.0fs; telegraph %.1fs; attack pool %s + focus" % [sim.abilities.final_heal_below*100,sim.abilities.final_heal_fraction*100,float(d.hp)*sim.abilities.final_heal_fraction,sim.campaign.enemy_skill_cooldown(d,"heal"),sim.abilities.final_action_gap,sim.abilities.telegraph,str(sim.abilities.final_attack_pool)])
    for key in Array(sim.abilities.final_attack_pool)+["focus"]:
        print("ENCOUNTER skill %s power %.2f (%.0f damage before Defense), cooldown %.0fs" % [key,float(sim.catalog.skills[key].power),float(sim.catalog.skills[key].power)*float(d.damage) if key!="focus" else 0.0,sim.campaign.enemy_skill_cooldown(d,key)])
    print("ENCOUNTER summons %s: first %.0fs, every %.0fs, %d per call, %d alive max; helper hp %.0f damage %.1f interval %.1fs" % [rule.helper_id,rule.first_delay,rule.cooldown,rule.per_cast,rule.max_alive,float(helper.hp),float(helper.damage),float(helper.interval)])
    print("ENCOUNTER keys required 13: %s" % ", ".join(key_ids()))

func group_index(id: String) -> int:
    for g in range(sim.catalog.groups.size()):
        if sim.catalog.groups[g].id==id:return g
    return -1

func key_ids() -> Array:
    var ids: Array=[]
    for g in sim.catalog.groups:
        if g.boss and not g.final:ids.append(str(g.id))
    return ids

# ---------------------------------------------------------------- obtainability proof
## "" when the id is legitimately obtainable, else why not. source describes how.
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
            if sim.catalog.items[other].get("next","")==id and source_of(other).ok and str(source_of(other).how)=="drop":
                return {"ok":true,"how":"evolution","from":[other]}
    return {"ok":false,"why":"no enemy drops it and nothing obtainable evolves into it"}

## Copies a merge level consumes (^m = m+1 copies). An evolved weapon also needs its source at ^100
## plus evolution.spare_cost spare copies (catalog.progression.evolution), reported by give().
func copies_needed(_id: String,m: int) -> int:
    return m+1

# ---------------------------------------------------------------- build
func fresh(seed: int) -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;sim.held=false
    SaveService.write_blocked=false;sim.rng.seed=seed

var gems_spent:=0.0
var coins_spent:=0.0
func buy(id: String,times: int,group:=-1) -> bool:
    for i in range(times):
        var cost:=float(sim.upgrade_cost(id,group))
        var currency: String=sim.catalog.upgrades[id].currency
        if currency=="gems":sim.state.gems=float(sim.state.gems)+cost;gems_spent+=cost # fixture: earned Gems
        else:sim.state.coins=float(sim.state.coins)+cost;coins_spent+=cost # fixture: earned Coins
        if not sim.buy_upgrade(id,group):return false
    return true

## Real Prestige transaction: the opportunities a previous run made ready, then card picks in order.
func prestige(set_: Dictionary) -> String:
    if set_.ready.is_empty():return ""
    sim.state.bosses_found.append("boss-snowman")
    for id in set_.ready:
        if not sim.catalog.campaign.opportunities.any(func(o):return o.id==id):return "unknown opportunity "+str(id)
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
    return "" if sim.state.prestige_batch.is_empty() else "Prestige batch unfinished"

func give(id: String,m: int,legit: Array) -> String:
    var src:=source_of(id)
    if not src.ok:return id+": "+str(src.why)
    if m>sim.merge_cap(id) or m<0:return id+": merge ^%d beyond cap ^%d" % [m,sim.merge_cap(id)]
    if not sim.add_item(id,1):return id+": no inventory room"
    var r: Dictionary=sim.record(id)
    r.merge=m;r.extras={} # fixture: merge level from copies; no random roll
    var how: String=str(src.how)
    if how=="evolution":how="evolution of %s ^%d + %d spare copies" % [src.from[0],int(sim.catalog.progression.evolution.required_merge),int(sim.catalog.progression.evolution.spare_cost)]
    else:how="drop: "+"/".join(src.from)
    legit.append("%s ^%d (%d copies; %s)" % [id,m,copies_needed(id,m),how])
    return ""

func build(b: Dictionary,card_sets: Dictionary,seed: int) -> Dictionary:
    gems_spent=0.0;coins_spent=0.0
    fresh(seed)
    var legit: Array=[]
    var out:={"why":"","legit":legit}
    var why:=prestige(card_sets[str(b.get("prestige","none"))])
    if why!="":out.why=why;return out
    sim.rng.seed=seed
    sim.state.player_level=int(b.level);sim.state.xp=0.0 # fixture: level reached (XP reported below)
    sim.state.stage=8;sim.state.unlocked_stage=8;sim.state.reward_stage=8 # fixture: Stage 8 reached this run
    sim.state.keys=key_ids().duplicate();sim.state.final_discovered=true # fixture: the 13 boss keys
    var gear: Array=[b.weapon,b.outfit]+b.get("stored_weapons",[])+b.get("stored_outfits",[])
    var room: int=gear.size()+b.skills.size()+2-sim.equipment_slot_count()
    if room>0 and not buy("gear_slots",room):out.why="gear slots";return out
    for pair in gear+b.skills:
        why=give(str(pair[0]),int(pair[1]),legit)
        if why!="":out.why=why;return out
    if not sim.equip(str(b.weapon[0])) or sim.state.weapon!=str(b.weapon[0]):out.why="weapon equip failed";return out
    if not sim.equip(str(b.outfit[0])) or sim.state.outfit!=str(b.outfit[0]):out.why="outfit equip failed";return out
    var skill_count: int=b.skills.size()
    if skill_count>1 and not buy("skill_slots",skill_count-1):out.why="skill slots";return out
    if skill_count>0 and not buy("skill_auto_slots",skill_count):out.why="auto skill slots";return out
    for i in range(skill_count):
        if not sim.campaign.equip_skill(str(b.skills[i][0]),i) or sim.state.skills[i]!=str(b.skills[i][0]):out.why="skill equip failed "+str(b.skills[i][0]);return out
        sim.state.skill_auto[i]=true
        if not buy("cooldown_"+str(sim.catalog.items[b.skills[i][0]].skill),int(b.get("skill_cooldown_levels",0))):out.why="cooldown upgrade";return out
    if sim.automatic_skill_assignments().size()!=skill_count:out.why="auto-cast assignment";return out
    if not buy("critical_chance",int(b.get("crit",[0,0])[0])) or not buy("critical_damage",int(b.get("crit",[0,0])[1])):out.why="critical upgrades";return out
    var supplies: Dictionary=b.get("supplies",{})
    if supplies.size()>1 and not buy("supply_slots",supplies.size()-1):out.why="supply slots";return out
    for id in supplies:
        var mastery: int=int(supplies[id][0]);var stock: int=int(supplies[id][1])
        if mastery>int(sim.catalog.progression.supply_mastery.cap):out.why="supply mastery beyond cap";return out
        sim.state.supply_uses[id]=mastery*int(sim.catalog.progression.change17.supply_uses_per_level) # fixture: successful uses
        if not sim.add_item(id,stock,false):out.why="supply room "+id;return out
        if sim.supply_mastery(id)!=mastery:out.why="supply mastery mismatch "+id;return out
        legit.append("%s stock %d ^%d (%d successful uses; %d under the old 5-use rule)" % [id,stock,mastery,mastery*3,mastery*5])
    var auto: Array=b.get("auto",[])
    if not auto.is_empty():
        if not buy("auto_use",auto.size()) or not buy("use_speed",int(b.get("use_speed",0))):out.why="auto supply upgrades";return out
        for id in auto:
            if not sim.bind_auto(sim.state.supplies.find(id)):out.why="auto bind "+str(id);return out
    sim.state.coins=0.0;sim.state.gems=0.0
    sim._reset_world()
    return out

## XP needed from level 1 to reach this level (no overflow).
func xp_to(level: int) -> float:
    var total:=0.0
    for l in range(1,level):total+=sim.xp_required(l)
    return total

# ---------------------------------------------------------------- duel
var boss_id:=""
var tally:={}
func _on_feedback(actor_id: String,amount: float,healing: bool) -> void:
    if actor_id==boss_id and healing:tally.boss_heals+=1;tally.boss_healed+=amount
    elif actor_id=="player" and not healing:tally.taken+=amount
func _on_cast(actor_id: String,key: String,_pos: Vector2) -> void:
    var bucket: Dictionary=tally.player_casts if actor_id=="player" else (tally.boss_casts if actor_id==boss_id else {})
    bucket[key]=int(bucket.get(key,0))+1
func _on_summoned(summoner_id: String,helper_ids: Array) -> void:
    if summoner_id==boss_id:tally.helpers+=helper_ids.size()

func duel(b: Dictionary,card_sets: Dictionary,seed: int) -> Dictionary:
    var made:=build(b,card_sets,seed)
    var row:={"id":b.id,"label":b.get("label",""),"boss":FINAL_ID,"seed":seed,"result":"invalid","time":0.0,"boss_left":1.0,"boss_min":1.0,"player_left":0.0,
        "damage":0.0,"hp":0.0,"defense":0.0,"crit":0.0,"crit_damage":0.0,"lifesteal":0.0,"regen_pct":0.0,"boss_heals":0,"boss_healed":0.0,"helpers":0,
        "supplies":"","player_casts":"","boss_casts":"","taken":0.0,"cards":"","gems":gems_spent,"coins":coins_spent,"xp":xp_to(int(b.level)),"legit":"; ".join(made.legit),"why":made.why}
    check(made.why=="",str(b.id)+": build legitimate and complete ("+str(made.why)+")")
    if made.why!="":return row
    var s: Dictionary=sim.stats()
    row.damage=s.damage;row.hp=s.hp;row.defense=s.defense;row.crit=s.crit;row.crit_damage=s.crit_damage;row.lifesteal=s.lifesteal;row.regen_pct=s.regen_pct
    row.cards=" ".join(sim.state.owned_cards)
    # A build may name another Spring II boss ("boss"), to check the key prerequisites it implies.
    var target_id: String=str(b.get("boss",FINAL_ID))
    row.boss=target_id
    var boss: Dictionary={}
    for e in sim.state.enemies:
        if e.group>=0 and sim.catalog.groups[int(e.group)].id==target_id:boss=e
    check(not boss.is_empty(),str(b.id)+": final boss present")
    if boss.is_empty():return row
    for e in sim.state.enemies:
        if e!=boss:e.hp=0.0;e.respawn=1e9 # fixture: only the boss and its own helpers fight
    boss_id=str(boss.id)
    tally={"boss_heals":0,"boss_healed":0.0,"taken":0.0,"helpers":0,"player_casts":{},"boss_casts":{}}
    sim.feedback.connect(_on_feedback);sim.spell_cast.connect(_on_cast);sim.summoned.connect(_on_summoned)
    var stock_before:={}
    for id in b.get("supplies",{}):stock_before[id]=sim.quantity(id)
    var p: Dictionary=sim.state.player
    p.x=float(boss.x)-30;p.y=float(boss.y);p.idle=1.0;p.hp=s.hp
    sim.campaign.reveal()
    boss.aggro=true
    var max_hp: float=sim.enemy_definition(int(boss.group),2).hp
    var t:=0.0
    while t<limit:
        sim.step(.1);t+=.1
        row.boss_min=minf(row.boss_min,maxf(0,boss.hp)/max_hp)
        if boss.hp<=0:row.result="win";break
        if p.hp<=0:row.result="loss";break
    if row.result=="invalid":row.result="timeout"
    sim.feedback.disconnect(_on_feedback);sim.spell_cast.disconnect(_on_cast);sim.summoned.disconnect(_on_summoned)
    row.time=t;row.boss_left=maxf(0,boss.hp)/max_hp;row.player_left=maxf(0,p.hp)/float(sim.stats().hp)
    row.boss_heals=tally.boss_heals;row.boss_healed=tally.boss_healed;row.helpers=tally.helpers;row.taken=tally.taken
    var used: Array=[]
    for id in stock_before:used.append("%s %d/%d" % [id,int(stock_before[id])-sim.quantity(id),int(stock_before[id])])
    row.supplies=" ".join(used)
    row.player_casts=JSON.stringify(tally.player_casts);row.boss_casts=JSON.stringify(tally.boss_casts)
    return row

func write_csv(path: String) -> void:
    var cols:=["id","label","boss","seed","result","time","boss_left","boss_min","player_left","damage","hp","defense","crit","crit_damage","lifesteal","regen_pct","boss_heals","boss_healed","helpers","taken","supplies","player_casts","boss_casts","cards","gems","coins","xp","legit","why"]
    var f:=FileAccess.open(ProjectSettings.globalize_path(path),FileAccess.WRITE)
    if f==null:print("AUDIT36 cannot write ",path);return
    f.store_line(",".join(cols))
    for r in rows:
        var cells: Array=[]
        for c in cols:
            var v=r.get(c,"")
            var text:=("%.4f" % v) if v is float else str(v)
            cells.append("\""+text.replace("\"","\"\"")+"\"")
        f.store_line(",".join(cells))
    f.close()
    print("AUDIT36 wrote ",path," rows ",rows.size())

# ---------------------------------------------------------------- farm rates
var drops:={}
func farm_all(spec: Dictionary) -> void:
    var builds:={}
    for b in spec.builds:builds[str(b.id)]=b
    var lines: Array=["id,farmer,spot,variant,minutes,kills,kills_per_min,xp_per_min,coins_per_min,gems_per_min,deaths,upgrade_coins,upgrade_gems,drops"]
    for f in spec.farms:
        var seed: int=int(f.get("seed",1))
        var made:=build(builds[str(f.farmer)],spec.card_sets,seed)
        check(made.why=="",str(f.id)+": farmer build ("+str(made.why)+")")
        if made.why!="":continue
        var g:=group_index(str(f.group))
        var variant: int=int(f.get("variant",2))
        coins_spent=0.0;gems_spent=0.0
        sim.campaign.discover_spot(g,variant) # fixture: spot found while exploring
        for id in f.get("upgrades",{}):
            if not buy(str(id),int(f.upgrades[id]),g):check(false,str(f.id)+": upgrade "+str(id)+" "+sim.upgrade_block_reason(str(id),g));break
        for id in f.get("global_upgrades",{}):
            if not buy(str(id),int(f.global_upgrades[id])):check(false,str(f.id)+": upgrade "+str(id)+" "+sim.upgrade_block_reason(str(id),-1));break
        if not sim.buy_upgrade("focus",g) and sim.level("focus",g)==0:
            sim.state.gems=float(sim.state.gems)+float(sim.upgrade_cost("focus",g));gems_spent+=float(sim.upgrade_cost("focus",g));sim.buy_upgrade("focus",g)
        check(sim.focus(g,variant) and int(sim.state.focus)==g,str(f.id)+": focus on the spot")
        var spot: Vector2=sim.campaign.spot(g,variant)
        sim.state.player.x=spot.x-60;sim.state.player.y=spot.y
        sim.campaign.reveal()
        drops={}
        var seen:=int(sim.state.next_pickup)
        var deaths:=[0]
        var on_dead:=func():deaths[0]+=1
        sim.revived.connect(on_dead)
        var kills_before:=int(sim.state.group_kills[g])
        var xp_before:=xp_to(int(sim.state.player_level))+float(sim.state.xp)
        var coins_before:=float(sim.state.coins);var gems_before:=float(sim.state.gems)
        var minutes: float=float(f.get("minutes",10))
        var t:=0.0
        while t<minutes*60.0:
            sim.step(.1);t+=.1
            if int(sim.state.next_pickup)>seen:
                for pickup in sim.state.pickups:
                    if int(pickup.uid)>seen and int(pickup.get("group",-1))>=0:drops[str(pickup.item)]=int(drops.get(str(pickup.item),0))+1
                seen=int(sim.state.next_pickup)
        sim.revived.disconnect(on_dead)
        var kills:=int(sim.state.group_kills[g])-kills_before
        var xp:=xp_to(int(sim.state.player_level))+float(sim.state.xp)-xp_before
        var line:="%s,%s,%s,%d,%.0f,%d,%.2f,%.0f,%.0f,%.2f,%d,%.0f,%.0f,\"%s\"" % [f.id,f.farmer,f.group,variant,minutes,kills,kills/minutes,xp/minutes,(float(sim.state.coins)-coins_before)/minutes,(float(sim.state.gems)-gems_before)/minutes,deaths[0],coins_spent,gems_spent,JSON.stringify(drops).replace("\"","'")]
        print("FARM_ROW ",line)
        lines.append(line)
    var path: String=str(arg("csv","res://docs/Change_36_Evidence/farm_rates.csv"))
    var file:=FileAccess.open(ProjectSettings.globalize_path(path),FileAccess.WRITE)
    if file!=null:
        file.store_string("
".join(lines)+"
");file.close();print("AUDIT36 wrote ",path)
