extends Node
var checks=0
var failures=0
var game
var sim
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func _ready() -> void:call_deferred("run")
func fresh() -> void:
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;sim.rng.seed=90210;SaveService.write_blocked=false
func safe() -> void:
    sim.state.player.quiet=6;sim.state.player.windup=0
    for a in sim.state.enemies:a.aggro=false;a.windup=0
func frames() -> void:
    for i in range(5):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false);fresh()
    check(sim.catalog.stages.size()==8 and sim.catalog.groups.size()==48,"Eight stages and 48 types")
    check(not sim.has_method("sell") and not sim.catalog.upgrades.has("sell"),"No selling APIs or upgrade")
    var counts=[[3,1],[6,1],[3,1],[6,2],[3,2],[4,2],[3,2],[6,3]]
    var skills={}
    for st in range(1,9):
        sim.state.unlocked_stage=8;safe();check(sim.campaign.camp_action(st,0,true),"Travel to stage %d"%st)
        await frames()
        var normals=0;var bosses=0
        for g in sim.campaign.stage().groups:
            var d=sim.catalog.groups[g]
            if d.boss:bosses+=1
            else:normals+=1
            for key in d.skills:skills[key]=true
            for v in sim.campaign.variants(g):
                check(sim.state.enemies.filter(func(a):return a.group==g and a.variant==v).size()==(1 if d.boss else 3),"Spawn count per actual spot")
            check(sim.enemy_definition(g,2).skills.is_empty() if not d.boss else true,"Skills restricted to fourth normal spot")
        check([normals,bosses]==counts[st-1],"Stage roster %d"%st)
        if st==4:check(skills.size()==6,"All six skills introduced by stage four")
        check(game.world.active_stage==st,"World stage scene switches")
    fresh();safe();sim.state.player.windup=.2
    check(not sim.campaign.camp_action(1,0,true),"Windup prevents teleport")
    safe();sim.state.enemies[0].aggro=true
    check(not sim.campaign.camp_action(1,0,true),"Enemy aggro prevents teleport")
    safe();sim.state.player.quiet=1
    check(not sim.campaign.camp_action(1,0,true),"Recent combat prevents teleport")
    safe();check(sim.campaign.camp_action(1,0,true),"Safe camp travel succeeds")
    var before=sim.state.explored.duplicate(true)
    game.world.pan_camera(Vector2(100,100));await frames()
    check(sim.state.explored==before,"Camera panning does not reveal fog")
    sim.state.coins=1000000
    check(sim.buy_upgrade("camp_radius",10),"Camp reveal upgrade")
    check(sim.state.explored['1'].size()>before['1'].size(),"Camp upgrade really reveals larger area")
    fresh();sim.state.gear.resize(20);sim.state.gear.fill("")
    var id="wood_sword"
    sim.add_item(id,201);sim.merge(id,true)
    check(sim.quantity(id)==101 and sim.record(id).merge==100,"Merge consumes 100 duplicates")
    var d=sim.catalog.items[id];var intrinsic=float(d.normal.damage[0])+float(d.merge_gain.damage)*100
    check(is_equal_approx(sim.normal(id).damage,intrinsic*1.05),"Stock grants derived 5% without consumption")
    check(sim.evolve(id),"Evolution succeeds")
    check(sim.quantity(id)==1 and sim.quantity(d.next)==1,"Evolution consumes only 100 spare copies")
    check(is_equal_approx(sim.normal(d.next).damage,intrinsic*.85),"Evolution retains 85% intrinsic power")
    check(is_equal_approx(sim.normal(id).damage,intrinsic),"Consuming spare copies removes stock bonus")
    var tier7="obsidian_sword";sim.add_item(tier7,201);sim.merge(tier7,true)
    check(not sim.evolve(tier7) and sim.normal(tier7).damage>sim.catalog.items[tier7].normal.damage[0]*3,"Final tier keeps stock growth")
    sim.add_item("skill_heal",3);sim.equip("skill_heal");sim.state.player.hp=1
    check(sim.campaign.cast(0),"Heal casts")
    check(sim.quantity("skill_heal")==3 and sim.state.player.hp>1,"Skills do not consume stock")
    sim.equip("skill_heal");sim.equip("skill_heal")
    check(not sim.campaign.cast(0),"Unequip/equip cannot reset cooldown")
    for key in sim.catalog.skills:game.world._spell("player",key,sim.position_of(sim.state.player))
    await frames()
    fresh();sim.state.gems=1000000;sim.state.discovered["0"]=true;sim.buy_upgrade("merge_gear",0)
    for i in range(9):sim.buy_upgrade("gear_merge_speed",0)
    check(sim.group_upgrade_value("gear_merge_speed",0)==1,"Automerge interval goes from 10 to 1")
    sim.add_item("unit-blue-cap_outfit",3);sim.campaign.merge_cycle("0",1,.5,0)
    check(sim.record("unit-blue-cap_outfit").merge==0,"No early automatic merge")
    sim.campaign.merge_cycle("0",1,.5,0)
    check(sim.record("unit-blue-cap_outfit").merge==1,"One automatic merge at interval")
    fresh();sim.state.unlocked_stage=8;safe();sim.campaign.camp_action(8,0,true)
    var final=sim.state.enemies.filter(func(a):return sim.catalog.groups[a.group].final)[0]
    sim.state.player.x=final.x;sim.state.player.y=final.y;sim.campaign.reveal()
    sim.step(.2)
    check(sim.state.final_discovered and not final.aggro and final.windup==0,"Approach discovers mission but sealed boss cannot fight")
    check(not sim.campaign.target_allowed(final),"Final boss untargetable without keys")
    for g in range(48):
        if sim.catalog.groups[g].boss and not sim.catalog.groups[g].final:
            sim.campaign.killed({"group":g,"encounter_uses":0})
    check(sim.state.keys.size()==13 and sim.campaign.target_allowed(final),"Thirteen unique keys unlock final boss")
    for g in sim.campaign.stage().groups:
        sim.campaign.killed({"group":g,"encounter_uses":0})
    check(sim.state.world_complete and sim.state.main_ready.has("15"),"All nine final stage types required")
    check(sim.campaign.claim_main(15) and not sim.campaign.claim_main(15),"Final reward claim is once-only")
    # Batch all three same-path opportunities: shrinking options, one reset, unique cards.
    sim.state.opportunities={}
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1   # fixture: first boss opens Prestige (Change 8)
    for i in range(1,4):sim.state.opportunities["hunter_o"+str(i)]={"ready":true,"baseline":{}}
    var fog_before: Dictionary=sim.state.explored.duplicate(true)
    check(sim.campaign.begin_prestige(),"Prestige batch begins")
    check(sim.campaign.offered_cards().size()==3,"First choice three cards")
    check(sim.prestige(sim.campaign.offered_cards()[0]) and sim.state.prestiges==0,"First choice saved without reset")
    var mid=sim.snapshot();sim.restore(mid)
    check(sim.campaign.offered_cards().size()==2,"Batch resumes with two unique remaining cards")
    sim.prestige(sim.campaign.offered_cards()[0]);check(sim.campaign.offered_cards().size()==1,"Last choice one remaining card")
    sim.prestige(sim.campaign.offered_cards()[0])
    check(sim.state.prestiges==1 and sim.state.owned_cards.size()==3,"Exactly one reset for whole batch")
    check(sim.state.keys.size()==13 and sim.state.final_complete and sim.state.main_claimed.has(15),"Keys and claimed final reward persist")
    # Change 16: Prestige keeps explored map areas; stages and gate kills still reset.
    var fog_kept:=true
    for key in fog_before:fog_kept=fog_kept and sim.state.explored.get(key,{}).size()>=fog_before[key].size()
    check(sim.state.stage==1 and fog_kept and sim.state.run_kills.is_empty(),"Stages and gate kills reset; explored cells are kept (Change 16)")
    check(sim.campaign.combo_owned(sim.catalog.campaign.combos[0]),"Same-path set activated idempotently")
    fresh();sim.add_item("wood_sword");sim.state.upgrades.offline_weapon=1
    sim.state.offline_snapshot=sim.campaign.offline_snapshot();sim.state.offline_snapshot.time=1000
    sim.campaign.settle_offline(1000+10*3600)
    # Change 7: settlement only records a pending claim; the in-game claim pays it.
    check(sim.state.coins==0 and sim.quantity("wood_sword")==1 and sim.state.offline_total==0 and not sim.state.offline_pending.is_empty(),"Offline settlement waits for the claim")
    check(sim.campaign.claim_offline() and sim.state.offline_pending.is_empty(),"Offline claim pays once")
    var coins=sim.state.coins;var qty=sim.quantity("wood_sword")
    check(is_equal_approx(coins,600) and qty==6,"Offline cap limits five hours and owned-only drops")
    check(sim.state.offline_total==36000 and sim.state.counters.is_empty(),"True absence counts, offline gives no online objective progress")
    sim.campaign.settle_offline(1000+10*3600)
    check(sim.state.coins==coins and sim.quantity("wood_sword")==qty and sim.state.offline_pending.is_empty() and not sim.campaign.claim_offline(),"Same interval cannot settle or claim twice")
    sim.campaign.settle_offline(900)
    check(sim.state.coins==coins,"Clock rollback grants nothing")
    fresh();sim.state.offline_snapshot=sim.campaign.offline_snapshot();sim.state.offline_snapshot.time=1000
    SaveService.write_blocked=true;sim.campaign.settle_offline(5000)
    check(sim.state.coins==0 and sim.state.offline_snapshot.time==1000 and sim.state.offline_pending.is_empty(),"Failed save rolls back offline grant")
    SaveService.write_blocked=false
    fresh();var m=sim.state.missions[0];m.progress=m.goal
    check(sim.campaign.claim_mission(0),"Mission claim succeeds")
    var reward=sim.state.coins;check(not sim.campaign.claim_mission(0) and sim.state.coins==reward,"Mission cannot claim twice")
    sim.state.missions[1].day="2000-01-01";sim.state.missions[1].progress=1;sim.campaign.refresh_missions()
    check(sim.state.missions[1].progress==1,"Unfinished missions survive midnight")
    # Validate malformed records rather than overwriting existing progress.
    var good=sim.snapshot();check(sim._valid_snapshot(good),"Current snapshot accepted")
    var bad=good.duplicate(true);bad.stage=9;check(not sim._valid_snapshot(bad),"Invalid stage rejected")
    for name in ["travel","map","missions","offline","prestige","upgrades","inventory","stats","settings"]:
        game._open(name);await frames();check(game.sheet.visible,"Panel opens: "+name)
    game._close()
    game.queue_free();await frames()
    print("CAMPAIGN_PROBE checks=",checks," failures=",failures)
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(0 if failures==0 else 1)
