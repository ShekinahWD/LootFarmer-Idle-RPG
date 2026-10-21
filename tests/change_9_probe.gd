extends Node
## Change 9 probe: outfit growth, equipped-only milestones, passive shares, Recovery, Spring II.
## Real main scene and simulation. State set directly is labelled "fixture".
var checks:=0
var failures:=0
var sim
var game
const T5:="unit-sprout_outfit_t5"
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func near(a: float,b: float,tolerance:=.01) -> bool:return absf(a-b)<=tolerance*maxf(1.0,absf(b))
func _ready() -> void:call_deferred("run")
func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=99123;game._close()
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false);fresh()
    merge_curve_checks()
    milestone_checks()
    passive_checks()
    recovery_checks()
    defense_checks()
    spring_two_checks()
    earlier_stage_checks()
    await save_checks()
    prestige_checks()
    await ui_checks()
    print("CHANGE_9_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

## Own one copy of an outfit at merge m with no random extras (fixture), so only core stats show.
func own(id: String,m: int,qty:=1) -> void:
    sim.add_item(id,qty)
    var r: Dictionary=sim.record(id)
    r.merge=m;r.extras={} # fixture: merge level and no random roll
    sim.touch()

func base_hp(id: String) -> float:return float(sim.catalog.items[id].normal.hp[0])

## §3 Core stat = base x (1 + 0.02 min(m,100) + 0.01 max(0,m-100)), capped at ^500.
func merge_curve_checks() -> void:
    fresh()
    own(T5,0)
    for pair in [[0,1.0],[100,3.0],[200,4.0],[300,5.0],[400,6.0],[500,7.0]]:
        sim.record(T5).merge=pair[0];sim.touch() # fixture
        check(near(sim.normal(T5).hp,base_hp(T5)*pair[1],.0001),"Outfit ^%d is %.0fx base (%.1f HP)" % [pair[0],pair[1],sim.normal(T5).hp])
    sim.record(T5).merge=650;sim.touch() # fixture: corrupt over-cap value
    check(near(sim.normal(T5).hp,base_hp(T5)*7.0,.0001),"Over-cap merge is clamped to the ^500 value")
    fresh()
    sim.add_item("unit-blue-cap_outfit",700)
    check(sim.merge("unit-blue-cap_outfit",true) and int(sim.record("unit-blue-cap_outfit").merge)==500 and not sim.merge("unit-blue-cap_outfit"),"Merging stops at ^500")
    check(near(sim.merge_levels("skill_frost",500),100+100*log(5.0),.0001),"Skills keep the Change 8 logarithmic tail")
    check(sim.merge_levels("wood_sword",60)==60.0 and sim.merge_cap("wood_sword")==100,"Weapons unchanged: linear to ^100")
    check(sim.catalog.items.values().all(func(e):return e.kind!="outfit" or near(float(e.merge_gain.hp),float(e.normal.hp[0])*.02,.0001)),"Every outfit's merge gain is 2% of its base (the formula's premise)")

## §3 Milestones: tier-scaled, replacing, equipped-only.
func milestone_checks() -> void:
    fresh()
    own(T5,99);sim.equip(T5)
    var expect:=[[99,0.0,0.0,0.0],[100,15.0,0.0,0.0],[200,15.0,0.0,.1],[300,15.0,.0025,.1],[400,30.0,.0025,.1],[500,50.0,.004,.1]]
    for e in expect:
        sim.record(T5).merge=e[0];sim.touch() # fixture
        var s: Dictionary=sim.stats()
        var core: float=sim.normal(T5).hp
        check(near(s.defense,e[1],.0001) and near(s.regen_pct,e[2],.0001) and near(sim.outfit_milestones(T5).hp,core*e[3],.0001),"Tier 5 ^%d: Defense %s, Recovery %s%%/s, milestone HP %s%% of core" % [e[0],e[1],e[2]*100,e[3]*100])
    var worn: float=sim.stats().hp
    sim.equip(T5) # toggles off
    var s0: Dictionary=sim.stats()
    check(sim.state.outfit=="" and s0.defense==0.0 and s0.regen_pct==0.0 and not sim.stat_sources().has("SOURCE_MILESTONE"),"Unequipped: no Guard, Recovery or milestone HP")
    check(worn>s0.hp,"Unequipping removes worn HP immediately")
    own("boss-red-panda_outfit_t5",500);own("unit-plain_outfit_t5",100)
    sim.equip("unit-plain_outfit_t5")
    check(near(sim.stats().defense,15.0,.0001) and sim.stats().regen_pct==0.0,"Stored ^500 outfits add no Guard or Recovery; only the worn ^100 one counts")
    sim.equip("boss-red-panda_outfit_t5")
    check(near(sim.stats().defense,50.0,.0001) and near(sim.stats().regen_pct,.004,.0001),"Switching outfits replaces the milestone effects at once")
    check(near(sim.stats_with(sim.state.weapon,"unit-plain_outfit_t5").defense,15.0,.0001) and near(sim.stats().defense,50.0,.0001),"Comparison preview uses the same milestone rules and leaves the live stats unchanged")
    fresh()
    own("unit-blue-cap_outfit",500);sim.equip("unit-blue-cap_outfit")
    check(near(sim.stats().defense,10.0,.0001) and near(sim.stats().regen_pct,.0008,.0001),"Tier 1 Mastery is small: 10 Defense, 0.08%/s")

## §4 Stored outfits 15% (core only), stored weapons 30%, the equipped item counted once.
func passive_checks() -> void:
    fresh()
    own(T5,300);own("diamond_axe",0)
    var stored: Dictionary=sim.stat_sources().SOURCE_STORED
    var outfit_core: float=sim.normal(T5).hp
    check(near(float(stored.hp),.15*outfit_core+.3*float(sim.normal("diamond_axe").hp),.0001),"Stored: outfit core HP at 15%, weapon at 30%")
    check(near(float(stored.damage),.3*float(sim.normal("diamond_axe").damage),.0001),"Stored weapon damage at 30% (kept, see notes)")
    check(not stored.has("defense") and not sim.stat_sources().has("SOURCE_MILESTONE"),"A stored ^300 outfit gives no milestone share")
    fresh()
    own(T5,300,7);sim.equip(T5)
    var sources: Dictionary=sim.stat_sources()
    check(near(float(sources.SOURCE_EQUIPPED.hp),sim.normal(T5).hp,.0001) and not sources.SOURCE_STORED.has("hp"),"The worn outfit counts once at full value even with spare copies")
    var total: float=100.0+float(sim.stat_sources().SOURCE_LEVEL.hp)+float(sim.normal(T5).hp)+float(sim.outfit_milestones(T5).hp)
    check(near(sim.stats().hp,total,.0001),"HP total = base + level + worn core + milestone HP (no double counting)")

## §3 Recovery heals through the simulation step only while alive and running.
func recovery_checks() -> void:
    fresh()
    own(T5,500);sim.equip(T5)
    for e in sim.state.enemies:e.hp=0.0;e.respawn=999.0 # fixture: no enemies nearby
    var p: Dictionary=sim.state.player
    var s: Dictionary=sim.stats()
    p.hp=s.hp*.5
    var rest: float=sim.campaign.rest_rate()
    var expected: float=p.hp+(float(s.regen)+float(s.hp)*(rest+float(s.regen_pct)))*.1
    sim.step(.1)
    check(near(p.hp,expected,.0001) and s.regen_pct>0,"Recovery adds 0.4%% max HP/s on top of rest (%.2f HP per 0.1 s)" % (float(s.hp)*float(s.regen_pct)*.1))
    var paused: float=p.hp
    get_tree().paused=true;sim.step(.1);get_tree().paused=false
    check(p.hp==paused,"No Recovery while paused")
    p.hp=0.0;p.respawn=99.0 # fixture: dead
    sim.step(.1)
    check(p.hp==0.0,"No Recovery while dead")

## §3 Guard uses the existing reduction 100/(100+Defense) in the real attack resolution.
func defense_checks() -> void:
    fresh()
    own(T5,500);sim.equip(T5)
    var p: Dictionary=sim.state.player
    var e: Dictionary=sim.state.enemies[0]
    p.hp=sim.stats().hp
    e.hp=1.0;e.x=p.x+4;e.y=p.y;e.target="player";e.windup=.01 # fixture: one contact this step
    var raw: float=float(sim.enemy_definition(int(e.group),int(e.variant)).damage)
    var before: float=p.hp
    sim._resolve_attack(e,.05)
    check(near(before-p.hp,maxf(1,raw*100.0/150.0),.0001),"A hit is reduced by Guard 50 to two thirds")

## §5 Spring II tiers, levels and the final boss factor; stages 1-7 untouched.
func spring_two_checks() -> void:
    fresh()
    var c=sim.catalog
    var levels:={"unit-flower-crown":195,"unit-green-cap":201,"unit-pink-cap":207,"unit-pink-flower-hood":213,"unit-plain":219,"unit-sprout":225,"boss-red-panda":235,"boss-sunflower":240,"boss-green-alien":250}
    var ok:=true
    for g in c.groups:
        if int(g.stage)!=8:continue
        ok=ok and int(g.level)==levels[g.id]
        var weapon_tier:=int(c.items[g.weapon].tier)
        var outfit: String=g.loot[1]
        ok=ok and weapon_tier==(6 if g.boss else 5) and g.loot[0]==g.weapon and int(c.items[outfit].tier)==5 and not c.items[outfit].get("legacy",false) and c.art_id(outfit)==g.body
    check(ok,"Spring II: levels 195-225 / 235 / 240 / 250, normals carry and drop Diamond + Tier 5 outfits, bosses Emerald + Tier 5 boss outfits")
    var b: Dictionary=c.progression.balance
    var final: Dictionary=c.groups[-1]
    var at_level:=func(L: int)->float:return float(b.hp_base)*pow(float(b.hp_growth),L-1)*(1+minf(L,float(b.ramp_cap))/float(b.ramp_hp_div))
    check(final.final and near(float(final.hp)/at_level.call(250),18.0,.0001) and near(float(b.final_hp),18.0,.0001),"Final boss HP uses its own 18x factor (%.0f HP, %.1f damage)" % [final.hp,final.damage])
    var panda: Dictionary=c.groups.filter(func(g):return g.id=="boss-red-panda")[0]
    check(near(float(panda.hp)/at_level.call(235),float(b.boss_hp),.0001),"Other bosses keep the shared 14.5x factor")
    check(float(final.hp)>250000 and float(final.hp)<350000 and float(final.damage)>300 and float(final.damage)<400,"Final boss near the investigation anchors (305K HP, 346 damage)")
    var g8:=-1
    for i in range(c.groups.size()):
        if c.groups[i].id=="unit-sprout":g8=i
    check(sim.enemy_definition(g8,0).loot==[T5] and sim.enemy_definition(g8,1).loot==["diamond_sword"],"Variants: outfit-only and weapon-only spots drop what they wear")
    # Real drop path: forced gear rolls (fixture: max Loot Chance and a large prestige gear bonus).
    sim.state.upgrades["loot:%d" % g8]=15
    sim.state.owned_cards=[];sim.state.pickups=[]
    var seen:={}
    for i in range(80):
        sim._reward({"group":g8,"variant":2,"x":0.0,"y":0.0})
    for d in sim.state.pickups:seen[d.item]=true
    check(seen.has("diamond_sword") and seen.has(T5) and not seen.has("gold_sword") and not seen.has("unit-sprout_outfit_t4"),"Sprout kills drop Diamond Swords and Tier 5 outfits only")

func earlier_stage_checks() -> void:
    # Pre-Change 9 values (Change 8 catalog) for a sample of Stage 1-7 groups.
    var before:={"boss-snowman":[7,600.0,"stone_axe"],"unit-straw-hat":[22,83.0,"stone_sword"],"boss-black-cat":[135,20084.0,"gold_sword"],"unit-elf-ears":[170,2967.0,"gold_axe"],"boss-bee":[190,66474.0,"diamond_axe"],"boss-orange-tabby-cat":[195,74114.0,"diamond_axe"]}
    var ok:=true
    for g in sim.catalog.groups:
        if before.has(g.id):ok=ok and int(g.level)==before[g.id][0] and absf(float(g.hp)-before[g.id][1])<1.0 and g.weapon==before[g.id][2]
        if int(g.stage)<=7:ok=ok and int(sim.catalog.items[g.loot[1]].tier)==1+(int(g.stage)-1)/2 and float(g.gear_chance)==(.3 if g.boss else .05)
    check(ok,"Stages 1-7: levels, HP, weapons, outfit tiers and drop chances unchanged")

## §7 Change 8 saves: legacy Tier 4 Spring II outfits and evolved legacy tiers keep working.
func save_checks() -> void:
    fresh()
    own("unit-sprout_outfit_t4",300);own("boss-green-alien_outfit_t7",150);own("skill_frost",200)
    sim.equip("unit-sprout_outfit_t4")
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    sim.restore(snap)
    await frames(2)
    check(SaveService.last_load_result not in ["development_reset","invalid_profile_reset"],"Change 8 save with a legacy Tier 4 Spring II outfit loads")
    check(sim.state.outfit=="unit-sprout_outfit_t4" and int(sim.record("unit-sprout_outfit_t4").merge)==300 and int(sim.record("boss-green-alien_outfit_t7").merge)==150,"Owned legacy outfits and merges are kept")
    check(near(sim.normal("unit-sprout_outfit_t4").hp,base_hp("unit-sprout_outfit_t4")*5.0,.0001) and near(sim.stats().defense,12.0,.0001) and near(sim.stats().regen_pct,.002,.0001),"A ^300 legacy Tier 4 outfit: 5x HP, Guard 12, Recovery 0.2%/s")
    sim.equip("boss-green-alien_outfit_t7")
    check(near(sim.stats().defense,21.0,.0001),"An evolved Tier 7 legacy outfit at ^150 uses its own tier (Guard 21)")
    check(sim.campaign.valid_snapshot(JSON.parse_string(JSON.stringify(sim.snapshot()))),"Save validates after the change")

func prestige_checks() -> void:
    fresh()
    own(T5,500);sim.equip(T5)
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1 # fixture: Snowman defeated
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready opportunity
    check(sim.campaign.begin_prestige() and sim.prestige(sim.campaign.offered_cards()[0]),"Prestige completes with a ^500 outfit worn")
    check(sim.quantity(T5)==0 and sim.state.outfit=="" and sim.stats().defense==0.0 and sim.stats().regen_pct==0.0,"The run reset clears gear and leaves no milestone residue")

func ui_checks() -> void:
    fresh()
    own(T5,250);sim.equip(T5)
    game.selected=T5;game.selected_slot=-1;game._open("item");await frames(3)
    check(_label_containing(tr("MILESTONES_ACTIVE").split("%")[0])!=null and _label_containing("Guard +15")!=null,"Item details list the active milestones")
    check(_label_containing(tr("MILESTONE_NEXT") % [300,""])!=null and _label_containing("Recovery 0.25%")!=null,"Item details show the next milestone (^300 Recovery)")
    own("unit-plain_outfit_t5",0)
    game.selected="unit-plain_outfit_t5";game._open("item");await frames(3)
    check(_label_containing(tr("MILESTONES_NONE"))!=null and _label_containing(tr("COMPARE_DOWNGRADE"))!=null,"An unmerged outfit shows no milestones, and swapping is a downgrade")
    sim.record(T5).merge=500;sim.touch() # fixture
    game.selected=T5;game._open("item");await frames(3)
    check(_label_containing(tr("MILESTONES_COMPLETE"))!=null,"A ^500 outfit shows Mastery reached")
    game._open("stats");await frames(3)
    check(_label_containing("0.4% max HP/s")!=null and _label_containing("Outfits 15%")!=null,"Stats shows Recovery and both stored shares")
    game._close()

func _label_containing(text: String) -> Label:
    for l in game.rows.find_children("*","Label",true,false):
        if l.text.contains(text):return l
    return null
