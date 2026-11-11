extends Node
## Change 17: production actions with deterministic fixtures; no presentation required.
var sim: LootSimulation
var checks:=0
var failures:=0
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func near(a: float,b: float) -> bool:return absf(a-b)<.0001*maxf(1,absf(b))
func fresh() -> void:
    sim.new_profile();sim.set_physics_process(false);sim.state.tutorial.mode="none";sim.suspended=false
    get_tree().paused=false;SaveService.write_blocked=false
func _ready() -> void:call_deferred("run")
func run() -> void:
    sim=LootSimulation.new();add_child(sim);sim.set_physics_process(false)
    fresh()
    upgrades_and_assignments()
    supplies()
    skills_and_statuses()
    bosses()
    rewards()
    persistence()
    print("CHANGE_17_CHECKS ",checks," FAILURES ",failures)
    get_tree().quit(1 if failures else 0)
func upgrades_and_assignments() -> void:
    sim.state.gems=10000000;sim.state.coins=100000
    for id in ["critical_chance","critical_damage"]:
        var base:=25 if id=="critical_chance" else 15 # Change 68: 25 / 15 Gems, x1.25
        for i in range(20):
            check(sim.upgrade_cost(id)==ceili(base*pow(1.25,i)),id+" price "+str(i))
            check(sim.buy_upgrade(id),id+" buy "+str(i))
        check(not sim.buy_upgrade(id),id+" capped")
    check(near(sim.stats().crit,.25) and near(sim.stats().crit_damage,3.1),"Permanent critical stats applied once")
    sim.record("wood_sword").extras={"crit":10.0,"crit_damage":10.0};sim.add_item("wood_sword");sim.equip("wood_sword")
    check(near(sim.stats().crit,.75) and near(sim.stats().crit_damage,4),"Critical caps respected")
    sim.add_item("skill_heal");sim.campaign.equip_skill("skill_heal")
    check(sim.buy_upgrade("skill_slots") and sim.buy_upgrade("skill_slots"),"Purchase equipped slots")
    sim.add_item("skill_fire");sim.campaign.equip_skill("skill_fire",2)
    check(sim.upgrade_cost("skill_auto_slots")==100 and sim.buy_upgrade("skill_auto_slots"),"Buy capacity")
    check(sim.assign_automatic_skills([2]) and sim.automatic_skill_assignments()==[2],"First capacity assigned to third equipped slot")
    check(not sim.assign_automatic_skills([0,2]) and not sim.assign_automatic_skills([1]),"Capacity and equipped validation")
    check(not sim.assign_automatic_skills([2,2]) and not sim.assign_automatic_skills([-1]) and not sim.assign_automatic_skills([2.5]),"Duplicate invalid indices refused")
    check(sim.assign_automatic_skills([0]),"Atomic reassignment")
    sim.state.player.hp=sim.stats().hp*.99
    var hp: float=sim.state.player.hp
    sim.campaign.automate(.1)
    check(sim.state.player.hp>hp,"Automatic Heal outside combat at 99%")
    check(sim.upgrade_cost("skill_auto_slots")==250 and sim.buy_upgrade("skill_auto_slots"),"Second capacity 250")
    check(sim.upgrade_cost("skill_auto_slots")==500 and sim.buy_upgrade("skill_auto_slots"),"Third capacity 500")
    check(not sim.buy_upgrade("skill_auto_slots"),"Capacity cap")
    get_tree().paused=true
    check(not sim.assign_automatic_skills([]),"Assignment pause lock")
    get_tree().paused=false
func supplies() -> void:
    fresh();sim.state.coins=100000;sim.state.gems=10000
    check(sim.upgrade_cost("auto_use")==100 and sim.buy_upgrade("auto_use"),"Supply auto slot 100 Gems")
    check(sim.upgrade_cost("use_speed")==100,"Supply interval starts 100")
    for i in range(8):check(sim.buy_upgrade("use_speed"),"Interval purchase "+str(i))
    check(near(sim.player_upgrade_value("use_speed"),2) and not sim.buy_upgrade("use_speed"),"2 second minimum")
    for i in range(4):sim.buy_upgrade("supply_slots")
    var price:=100
    for id in sim.supply_ids():
        check(int(sim.supply(id).price)==price and sim.purchase_consumable(id),"Supply shop "+id)
        check(sim.supply_mastery(id)==0,"Buying gives no mastery "+id)
        sim.add_item(id,10)
        check(sim.supply_mastery(id)==0,"Collecting gives no mastery "+id)
        var per: int=int(sim.catalog.progression.change17.supply_uses_per_level)
        for i in range(per):
            sim.state.player.hp=sim.stats().hp*.5;sim.state.use_cd=0;sim.state.boost_time=0;sim.state.buffs={}
            check(sim.use_item(id),"Actual use "+id+str(i))
            check(sim.supply_mastery(id)==(1 if i==per-1 else 0),"Uses per mastery level "+id+str(i))
        price+=100
    sim.state.player.hp=sim.stats().hp*.999;sim.state.use_cd=0
    check(sim.use_item("potion"),"Potion at 99.9% out of combat")
    var uses: int=sim.state.supply_uses.potion
    check(not sim.use_item("potion") and sim.state.supply_uses.potion==uses,"Blocked use no mastery")
    sim.state.player.hp=sim.stats().hp*.99;sim.state.use_cd=0;sim.bind_auto(sim.state.supplies.find("potion"))
    sim.campaign.automate(2)
    check(sim.state.supply_uses.potion==uses+1,"Auto potion outside combat")
    sim.state.supply_uses.potion=500;sim.touch()
    check(sim.supply_mastery("potion")==100 and near(sim.supply_cooldown("potion"),10),"Mastery cap and cooldown floor")
func skills_and_statuses() -> void:
    fresh();sim.state.upgrades.gear_slots=67;sim.state.gear.resize(70);sim.state.gear.fill("")
    var expected: Dictionary=sim.catalog.progression.change17.skill_curve
    for id in sim.catalog.items:
        if sim.catalog.items[id].kind!="skill":continue
        sim.add_item(id,2)
        var family: String=sim.catalog.items[id].skill
        for m in [0,100,250,500]:
            sim.record(id).merge=m;sim.touch()
            var t:=sim.merge_levels(id,m)/sim.merge_levels(id,500)
            var power:=lerpf(expected[family][0],expected[family][1],t)
            check(near(sim.skill_base_power(id),power),"Effective curve "+id+" ^"+str(m))
            check(near(sim.skill_power(id),power*(sim.stats().hp if family=="heal" else 1)),"Cast power "+id+" ^"+str(m))
        sim.record(id).qty=10000
        check(near(sim.skill_base_power(id),expected[family][1]),"No stock inflation "+id)
    for key in sim.catalog.skills:
        check(sim.player_upgrade_value("cooldown_"+key)==20,"20 seconds "+key)
        sim.state.upgrades["cooldown_"+key]=6
        check(near(sim.player_upgrade_value("cooldown_"+key),14),"Cooldown upgrade "+key)
    sim.campaign.equip_skill("skill_heal",0);sim.state.player.hp=sim.stats().hp*.99
    check(sim.campaign.cast(0) and near(sim.state.player.hp,sim.stats().hp),"Heal actual missing health only")
    var normal: Dictionary=sim.state.enemies[0]
    var boss: Dictionary={}
    for a in sim.state.enemies:
        if sim.catalog.groups[int(a.group)].boss:boss=a;break
    for a in [normal,boss]:
        sim.campaign.apply_timed_status(a,"future_effect",3)
        check(near(a.future_effect,1.5 if a==boss else 3),"Reusable boss duration")
    # Place a target in revealed ground; keep HP high to observe a cast and its actual timers.
    sim.state.player.x=normal.x;sim.state.player.y=normal.y;sim.campaign.reveal();sim.select_target(normal.id)
    normal.hp=1000000;normal.cooldown=2;normal.aggro=true
    var other: Dictionary=sim.state.enemies[1];var other_hp: float=other.hp
    check(sim.campaign.apply_skill(sim.state.player,"lightning",1.25),"Lightning cast")
    check(near(normal.attack_slow,3) and near(normal.attack_rate,.5) and other.hp==other_hp,"Single-target attack slow")
    check(near(float(normal.get("slow",0)),0),"Lightning does not slow movement")
    sim._actor_timers(normal,1)
    check(near(normal.cooldown,1.5),"Slow changes actual attack cooldown")
    normal.attack_slow=.5;normal.cooldown=2;sim._actor_timers(normal,1)
    check(near(normal.cooldown,1.25),"Partial expiry timing")
    normal.windup=1;normal.target="player";normal.attack_slow=3
    sim._resolve_attack(normal,1)
    check(near(normal.windup,.5),"Slow changes pending attack timing")
    sim.state.player.focus_time=5;sim.state.player.focus_power=50
    check(near(sim.campaign.effective_skill_multiplier(sim.state.player,normal,"fire",300),3),"Fire cap after Focus and skill bonuses")
    var before: float=normal.hp
    sim.campaign.apply_skill(sim.state.player,"fire",300)
    check(before-normal.hp<=sim.stats().damage*3+.0001,"Actual Fire damage capped")
    sim.campaign.apply_skill(sim.state.player,"frost",.5)
    check(near(normal.slow,3),"Frost normal duration")
    sim.state.player.x=boss.x;sim.state.player.y=boss.y;sim.campaign.reveal();sim.select_target(boss.id);boss.hp=1000000
    sim.campaign.apply_skill(sim.state.player,"lightning",1.25)
    check(near(float(boss.get("attack_slow",0)),1.5),"Actual Lightning boss duration")
    sim.campaign.apply_skill(sim.state.player,"frost",.5)
    check(near(float(boss.get("slow",0)),1.5),"Actual Frost boss duration")
func bosses() -> void:
    fresh()
    var boss: Dictionary={}
    for a in sim.state.enemies:
        if sim.catalog.groups[int(a.group)].boss:boss=a;break
    for g in range(sim.catalog.groups.size()):
        check(near(sim.gem_chance(g),.05),"5% base including bosses "+str(g))
    var g:=int(boss.group)
    sim.state.upgrades.gem_chance=1;sim.state.upgrades.boss_gem_chance=1
    check(near(sim.gem_chance(g),.105),"Boss chance upgrades additive")
    boss.hp=0;sim._kill(boss)
    var rows:=sim.boss_respawn_countdowns(1)
    check(rows.size()==1 and rows[0].position==sim.spawn_home(g,2,0),"Boss countdown home")
    var start: float=rows[0].remaining
    get_tree().paused=true;sim.step(.1);get_tree().paused=false
    check(near(sim.boss_respawn_countdowns()[0].remaining,start),"Pause freezes online boss timer")

    sim.tick_boss_respawns(7)
    check(near(sim.boss_respawn_countdowns()[0].remaining,start-7),"Countdown progress")
    sim.state.unlocked_stage=2
    check(sim.campaign.camp_action(2,0,true),"Travel while boss dead")
    sim.tick_boss_respawns(8)
    check(near(sim.boss_respawn_countdowns()[0].remaining,start-15),"Inactive boss progresses")
    var data: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    data.boss_saved_at=Time.get_unix_time_from_system()-10
    sim.restore(data)
    check(sim.boss_respawn_countdowns().size()==1 and absf(sim.boss_respawn_countdowns()[0].remaining-(start-25))<1,"Restart settles offline countdown")
    sim.tick_boss_respawns(start)
    check(sim.boss_respawn_countdowns().is_empty(),"Countdown expires once")
    sim.campaign.camp_action(1,0,true);sim.step(.1)
    check(sim._find_actor(str(boss.id)).hp>0,"Return spawns expired boss")
    fresh();sim.state.stage=4;sim.state.unlocked_stage=4;sim._reset_world()
    var killed: Array=[]
    for a in sim.state.enemies:
        if sim.catalog.groups[int(a.group)].boss:
            a.hp=0;sim._kill(a);killed.append(str(a.id))
    check(killed.size()==2 and sim.boss_respawn_countdowns(4).size()==2,"Independent bosses on same map")
    sim.state.boss_respawns[killed[0]].remaining=10;sim.state.boss_respawns[killed[1]].remaining=30
    sim.tick_boss_respawns(11)
    check(sim.boss_respawn_countdowns(4).size()==1 and near(sim.state.boss_respawns[killed[1]].remaining,19),"One boss expires without resetting another")
    var legacy: Dictionary=sim.snapshot();legacy.erase("boss_respawns");legacy.erase("boss_saved_at")
    sim.restore(JSON.parse_string(JSON.stringify(legacy)))
    check(sim.boss_respawn_countdowns(4).size()==1 and absf(sim.boss_respawn_countdowns(4)[0].remaining-19)<.5,"Legacy dead-actor timer migrated")
func rewards() -> void:
    fresh()
    for stage in range(1,9):
        sim.state.unlocked_stage=stage
        var regular: Dictionary={"kind":"gear","base_gems":3.0}
        var boss: Dictionary={"kind":"boss","base_gems":5.0}
        var a: Dictionary=sim.campaign.mission_rewards(regular)
        var b: Dictionary=sim.campaign.mission_rewards(boss)
        check(near(a.coins,40*sim.campaign.mission_coin_income()) and near(b.coins,80*sim.campaign.mission_coin_income()),"Kill-equivalent reward stage "+str(stage))
        check(near(a.gems,3*sim.catalog.progression.change17.mission_gem_multipliers[stage-1]),"Gem stage multiplier "+str(stage))
        sim.campaign.price_mission(regular);var first: float=regular.gems
        for i in range(5):sim.campaign.price_mission(regular)
        check(near(first,regular.gems),"No repeat scaling")
    sim.state.reward_stage=8;sim.state.unlocked_stage=1
    # Change 50 (approved): missions are priced from the current run's map access, not the highest ever.
    check(sim.campaign.reward_stage()==1,"Run-scoped reward stage (Change 50)")
    sim.state.unlocked_stage=8
    sim.state.cards={"mission_coins":2,"mission_gems":3,"coins":4};sim.touch()
    var boosted: Dictionary=sim.campaign.mission_rewards({"kind":"gear","base_gems":3.0})
    check(near(boosted.coins,40*sim.campaign.mission_coin_income()*1.1) and near(boosted.gems,3*25*1.15),"Mission bonuses applied once")
    sim.state.stage=1
    check(near(sim.campaign.mission_rewards({"kind":"gear","base_gems":3.0}).coins,boosted.coins),"Visiting early map does not lower reward")
    sim.state.missions=[{"kind":"gear","target":"","goal":1.0,"progress":1.0,"coins":0.0,"gems":999.0,"claimed":false,"day":Time.get_date_string_from_system()}]
    var reward: Dictionary=sim.campaign.mission_rewards(sim.state.missions[0])
    check(sim.campaign.claim_mission(0) and near(sim.state.gems,reward.gems),"Claim credits recalculated reward once")
    check(not sim.campaign.claim_mission(0),"No double claim")
func persistence() -> void:
    fresh();sim.add_item("potion",3);sim.add_item("skill_heal");sim.campaign.equip_skill("skill_heal")
    var old: Dictionary=sim.snapshot()
    old.erase("supply_uses");old.erase("supply_mastery_credit");old.erase("boss_respawns");old.erase("boss_saved_at");old.erase("reward_stage")
    old.supply_found.potion=26;old.upgrades.skill_auto_0=1;old.skill_auto[0]=true
    sim.restore(JSON.parse_string(JSON.stringify(old)))
    check(sim.supply_mastery("potion")==25 and sim.automatic_skill_capacity()==1 and sim.state.skill_auto[0],"Legacy mastery and capacity migration")
    check(SaveService.save_now(),"Disk save")
    sim.state.supply_mastery_credit={};sim.state.upgrades={};SaveService.load_and_apply()
    check(sim.supply_mastery("potion")==25 and sim.automatic_skill_capacity()==1,"Disk load")
    var again:=sim.snapshot();sim.restore(JSON.parse_string(JSON.stringify(again)))
    check(sim.supply_mastery("potion")==25 and sim.automatic_skill_capacity()==1,"Migration idempotent")
    var invalid:=sim.snapshot()
    invalid.supply_uses={"potion":-10,"invalid":500};invalid.skill_auto=[true,true,true]
    invalid.upgrades.critical_chance=999;invalid.upgrades.critical_damage=-5
    invalid.boss_respawns={"fake":{"group":-1,"stage":1,"remaining":50,"x":0,"y":0}}
    sim.restore(JSON.parse_string(JSON.stringify(invalid)))
    check(sim.level("critical_chance")==20 and sim.level("critical_damage")==0 and sim.state.supply_uses.get("potion",0)==0 and sim.state.boss_respawns.is_empty(),"Malformed progression normalized")
    check(sim.automatic_skill_assignments()==[0],"Loaded assignments bounded by capacity")
    sim.state.upgrades.erase("critical_chance")
    sim.state.supply_uses.potion=int(sim.catalog.progression.change17.supply_uses_per_level)-1
    sim.state.player.hp=sim.stats().hp*.5;sim.state.use_cd=0
    check(sim.use_item("potion") and sim.supply_mastery("potion")==26,"Legacy credit plus new level-completing use")
    # Real Prestige transaction with an earned opportunity, using the existing test fixture convention.
    sim.state.gems=10000;sim.buy_upgrade("critical_chance");sim.buy_upgrade("critical_damage");sim.buy_upgrade("auto_use");sim.buy_upgrade("use_speed")
    sim.state.reward_stage=8
    sim.state.bosses_found.append("boss-snowman")
    sim.state.opportunities.expedition_1={"ready":true,"baseline":{},"step":0,"count":0}
    var ids: Array=sim.campaign.awardable_ids()
    if not ids.is_empty() and sim.campaign.begin_prestige():
        var guard:=0
        while not sim.state.prestige_batch.is_empty() and guard<40:
            guard+=1
            sim.campaign.choose_card(str(sim.campaign.offered_cards()[0]))
        check(sim.state.prestiges==1 and sim.supply_mastery("potion")==0 and sim.automatic_skill_capacity()==1,"Prestige resets mastery and retains automation")
        check(sim.level("critical_chance")==1 and sim.level("critical_damage")==1 and sim.level("use_speed")==1 and sim.campaign.reward_stage()==1,"Prestige retains Gem upgrades; the new run's missions are priced from Winter I (Change 50)")
    else:check(false,"Prestige fixture must earn an opportunity")
    check(SaveService.hard_reset(),"Hard Reset committed to disk")
    SaveService.load_and_apply()
    check(sim.supply_mastery("potion")==0 and sim.automatic_skill_capacity()==0 and sim.campaign.reward_stage()==1 and sim.boss_respawn_countdowns().is_empty(),"Hard reset defaults")
