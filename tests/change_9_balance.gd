extends Node
## Change 9 balance fixture: a few realistic late-game loadouts fought in the real simulation.
## Every item must exist, be obtainable (dropped by some enemy, weapon tier no higher than the best
## drop) and actually be equipped before a fight is measured; impossible inventories are rejected.
## Each duel steps the real simulation (basic attacks, auto-cast skills, boss skills and heals,
## Defense, Recovery, lifesteal) at 0.1 s for at most 600 s. One seed; results are indicative only.
var checks:=0
var failures:=0
var sim
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func _ready() -> void:call_deferred("run")

const CARDS:=["arsenal_c1","hunter_c1","arsenal_c3","arsenal_c2","hunter_c2","challenge_c2"] # HP +20%, boss damage +25%, guard 10%, damage +15%
const STAGE_7:={"stage":7,"level":190,"weapon":["gold_sword",100],"stored":[["gold_axe",100],["iron_sword",100],["iron_axe",100]],
    "outfit":["unit-elf-ears_outfit_t4",100],"stored_outfits":[["unit-bunny-ears_outfit_t4",50]],
    "skills":[["skill_lightning",50],["skill_fire",50]],"cards":2}
const SPRING_II:={"stage":8,"level":225,"weapon":["diamond_sword",100],"stored":[["diamond_axe",50],["gold_sword",100],["gold_axe",100]],
    "outfit":["unit-sprout_outfit_t5",100],"stored_outfits":[["boss-bee_outfit_t4",100]],
    "skills":[["skill_lightning",50],["skill_fire",50],["skill_strike",50]],"cards":4}
const FINAL:={"stage":8,"level":240,"weapon":["emerald_sword",50],"stored":[["diamond_sword",100],["diamond_axe",100],["gold_sword",100],["gold_axe",100]],
    "outfit":["boss-sunflower_outfit_t5",100],"stored_outfits":[["unit-sprout_outfit_t5",100]],
    "skills":[["skill_lightning",50],["skill_fire",50],["skill_strike",50]],"cards":4}

func run() -> void:
    # Watchdog: a script error must never leave a headless run hanging.
    get_tree().create_timer(240.0,true,false,true).timeout.connect(func():print("CHANGE_9_BALANCE watchdog");get_tree().quit(2))
    sim=LootSimulation.new();add_child(sim);sim.set_physics_process(false)
    var r:={}
    # Stage 7 regression guard: the same Bee first-kill loadout under Change 8 rules (fixture: no
    # milestones, stored outfits 30%; the curve is identical up to ^100) and under Change 9.
    r.bee_c8=duel("Bee first kill, Change 8 rules","boss-bee",STAGE_7,{"rules":"change8"})
    r.bee=duel("Bee first kill, Change 9","boss-bee",STAGE_7,{})
    r.bee_farmed=duel("Bee, elf-ears ^300, 4 cards","boss-bee",STAGE_7,{"outfit":["unit-elf-ears_outfit_t4",300],"cards":4})
    r.panda_100=duel("Red Panda, sprout ^100","boss-red-panda",SPRING_II,{})
    r.panda_300=duel("Red Panda, sprout ^300","boss-red-panda",SPRING_II,{"outfit":["unit-sprout_outfit_t5",300]})
    r.panda_300_6=duel("Red Panda, sprout ^300, 6 cards","boss-red-panda",SPRING_II,{"outfit":["unit-sprout_outfit_t5",300],"cards":6})
    r.panda_500=duel("Red Panda, sprout ^500","boss-red-panda",SPRING_II,{"outfit":["unit-sprout_outfit_t5",500]})
    r.final_100=duel("Final, Sunflower outfit ^100","boss-green-alien",FINAL,{})
    r.final_300=duel("Final, Sunflower outfit ^300","boss-green-alien",FINAL,{"outfit":["boss-sunflower_outfit_t5",300]})
    r.final_nocards=duel("Final, ^300, no cards","boss-green-alien",FINAL,{"outfit":["boss-sunflower_outfit_t5",300],"cards":0})
    r.final_noskills=duel("Final, ^300, no skills","boss-green-alien",FINAL,{"outfit":["boss-sunflower_outfit_t5",300],"skills":[]})
    r.final_w15=duel("Final, ^300, stored weapons 15%","boss-green-alien",FINAL,{"outfit":["boss-sunflower_outfit_t5",300],"rules":"weapons15"})
    r.final_500=duel("Final, Sunflower outfit ^500","boss-green-alien",FINAL,{"outfit":["boss-sunflower_outfit_t5",500]})
    for k in r:
        var row: Dictionary=r[k]
        print("BALANCE_ROW %-34s %-7s %4.0fs | boss left %5.1f%% | player left %5.1f%% | dmg %5.0f hp %6.0f def %3.0f rec %.2f%%/s" % [row.label,row.result,row.time,row.boss_left*100,row.player_left*100,row.damage,row.hp,row.defense,row.regen_pct*100])
    check(r.bee.result=="win" or r.bee_c8.result!="win","Stage 7: Change 9 never turns a Bee win into a loss")
    check(r.bee.boss_left<=r.bee_c8.boss_left+.005 and r.bee.time>=r.bee_c8.time-.05,"Stage 7: the Bee first kill is no harder than under Change 8 rules")
    check(r.panda_500.result=="win" and r.panda_300_6.result=="win","Red Panda: beatable at ^500, or at ^300 with six cards")
    check(r.final_300.result=="win","Final boss beatable before ^500 with a plausible loadout, three skills and four cards")
    check(r.final_100.result!="win","Final boss is not trivial: an ^100 outfit is not enough")
    weapon_share_comparison()
    impossible_loadout_rejected()
    level_feasibility()
    print("CHANGE_9_BALANCE_CHECKS ",checks," FAILURES ",failures)
    get_tree().quit(1 if failures else 0)

func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=4242

func max_drop_tier() -> int:
    var best:=0
    for g in sim.catalog.groups:best=maxi(best,int(sim.catalog.items[g.weapon].tier))
    return best

func obtainable(id: String) -> bool:
    if not sim.catalog.items.has(id):return false
    var e: Dictionary=sim.catalog.items[id]
    if e.kind=="skill":return true
    if e.get("legacy",false):return false
    if e.kind=="weapon":return int(e.tier)<=max_drop_tier()
    return sim.catalog.groups.any(func(g):return g.loot.has(id))

func give(id: String,m: int) -> bool:
    if not obtainable(id):return false
    if not sim.add_item(id,1):return false
    var r: Dictionary=sim.record(id)
    r.merge=m;r.extras={} # fixture: merge level and no random roll
    sim.touch()
    return true

## Builds the loadout; returns "" or the reason it was rejected.
func build(spec: Dictionary) -> String:
    fresh()
    sim.state.gear.resize(40);sim.state.gear.fill("") # fixture: enough slots for the stored set
    sim.state.player_level=int(spec.level)
    sim.state.stage=int(spec.stage);sim.state.unlocked_stage=int(spec.stage)
    for pair in [spec.weapon,spec.outfit]+spec.stored+spec.stored_outfits+spec.skills:
        if not give(pair[0],pair[1]):return "not obtainable or no room: "+str(pair[0])
    if not sim.equip(spec.weapon[0]) or sim.state.weapon!=spec.weapon[0]:return "weapon equip failed"
    if not sim.equip(spec.outfit[0]) or sim.state.outfit!=spec.outfit[0]:return "outfit equip failed"
    sim.state.upgrades["skill_slots"]=2
    for i in range(spec.skills.size()):
        sim.state.upgrades["skill_auto_%d" % i]=1;sim.state.skill_auto[i]=true
        if not sim.campaign.equip_skill(spec.skills[i][0],i):return "skill equip failed: "+str(spec.skills[i][0])
    sim.state.owned_cards=CARDS.slice(0,int(spec.cards))
    sim.state.keys=[];for i in range(13):sim.state.keys.append("key%d" % i) # fixture: final boss unlocked
    sim.state.final_unsealed=true;sim.state.final_experience=true;sim.state.final_warning_ok=true # fixture: Change 82 ceremony and Change 83 introduction done
    sim._reset_world()
    return ""

func duel(label: String,boss_id: String,base: Dictionary,override: Dictionary) -> Dictionary:
    var spec:=base.duplicate(true)
    for k in override:spec[k]=override[k]
    var why:=build(spec)
    check(why=="",label+": loadout valid ("+why+")")
    var saved:=[sim.catalog.progression.outfit_milestones,sim.catalog.progression.stored_outfit_factor,sim.catalog.progression.stored_weapon_factor]
    if spec.get("rules","")=="weapons15":
        sim.catalog.progression.stored_weapon_factor=.15;sim.touch() # fixture: the rejected alternative
        sim.state.player.hp=sim.stats().hp
    if spec.get("rules","")=="change8":
        sim.catalog.progression.outfit_milestones=[];sim.catalog.progression.stored_outfit_factor=.3;sim.touch() # fixture: Change 8 rules
        sim.state.player.hp=sim.stats().hp
    var s: Dictionary=sim.stats().duplicate()
    var row:={"label":label,"result":"invalid","time":0.0,"boss_left":1.0,"player_left":0.0,"damage":s.damage,"hp":s.hp,"defense":s.defense,"regen_pct":s.regen_pct}
    if why!="":return row
    var boss: Dictionary={}
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id==boss_id:boss=e
    check(not boss.is_empty(),label+": boss present")
    if boss.is_empty():return row
    for e in sim.state.enemies:
        if e!=boss:e.hp=0.0;e.respawn=1e9 # fixture: only the boss is present
    var p: Dictionary=sim.state.player
    p.x=float(boss.x)-30;p.y=float(boss.y);p.idle=1.0;p.hp=s.hp
    sim.campaign.reveal()
    boss.aggro=true
    var max_hp: float=sim.enemy_definition(int(boss.group),2).hp
    var t:=0.0
    while t<600.0:
        sim.step(.1);t+=.1
        if boss.hp<=0:row.result="win";break
        if p.hp<=0:row.result="loss";break
    if row.result=="invalid":row.result="timeout"
    row.time=t;row.boss_left=maxf(0,boss.hp)/max_hp;row.player_left=maxf(0,p.hp)/float(sim.stats().hp)
    sim.catalog.progression.outfit_milestones=saved[0];sim.catalog.progression.stored_outfit_factor=saved[1];sim.catalog.progression.stored_weapon_factor=saved[2];sim.touch()
    return row

## §4 weapon decision: the same Spring II loadouts with stored weapons at 15% instead of 30%.
func weapon_share_comparison() -> void:
    for spec in [SPRING_II,FINAL]:
        build(spec)
        var at30: float=sim.stats().damage
        sim.catalog.progression.stored_weapon_factor=.15;sim.touch() # fixture: alternative value
        var at15: float=sim.stats().damage
        sim.catalog.progression.stored_weapon_factor=.3;sim.touch()
        print("WEAPON_SHARE level %d: damage %.0f at 30%%, %.0f at 15%% (%.1f%% less)" % [spec.level,at30,at15,(1-at15/at30)*100])
        check(at15<at30,"Stored weapons matter to damage")

func impossible_loadout_rejected() -> void:
    var spec:=FINAL.duplicate(true)
    spec.weapon=["obsidian_sword",100]
    check(build(spec)!="","Obsidian weapons are rejected (no enemy drops tier 7)")
    spec=FINAL.duplicate(true)
    spec.outfit=["boss-green-alien_outfit_t7",100]
    check(build(spec)!="","Legacy tier 7 outfits are rejected as natural-progression proxies")

## Kills of the strongest Spring II normal type needed to reach the fixture levels from level 1.
func level_feasibility() -> void:
    var xp:=0.0
    var top: Dictionary=sim.catalog.groups.filter(func(g):return g.id=="unit-sprout")[0]
    for level in range(1,241):
        xp+=sim.xp_required(level)
        if level+1 in [225,240]:print("LEVEL_FEASIBILITY level %d: %.2fM XP total, about %.0f sprout kills (%.0f XP each)" % [level+1,xp/1e6,xp/float(top.xp),top.xp])
