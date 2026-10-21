extends Node
var checks:=0
var failures:=0
var sim
var game
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func _ready() -> void:call_deferred("run")
func fresh() -> void:
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=55123
func frames() -> void:
    for i in range(6):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false);fresh()
    # Healing roles across the entire authored evolution chain.
    var potion="potion"
    var heal="skill_heal"
    for tier in range(1,8):
        fresh();sim.state.player_level=1000;sim.touch()
        check(sim.add_item(potion,3) and sim.add_item(heal,3),"Healing items fit storage")
        sim.equip(heal)
        for merge in [0,50,100]:
            sim.record(potion).merge=merge;sim.record(heal).merge=merge;sim.touch()
            var potion_hp: float=sim.normal(potion).heal
            var skill_hp: float=minf(sim.normal(heal).power,sim.stats().hp*.12)
            check(potion_hp>skill_hp*2,"Potion burst exceeds sustain at tier %d merge %d" % [tier,merge])
        sim.state.player.hp=1;sim.state.skill_cooldowns={};sim.state.use_cd=0
        var qty=sim.quantity(heal);var hp=sim.state.player.hp
        check(sim.campaign.cast(0),"Heal casts while hurt")
        check(sim.quantity(heal)==qty and sim.state.player.hp-hp<=sim.stats().hp*.12+.001,"Free Heal respects HP cap")
        check(not sim.campaign.cast(0),"Heal cannot bypass cooldown")
        sim.state.player.hp=1;hp=sim.state.player.hp;qty=sim.quantity(potion)
        check(sim.use_item(potion),"Potion works during Heal cooldown")
        check(sim.quantity(potion)==qty-1 and sim.state.player.hp>hp,"Potion restores HP and consumes exactly one")
        check(not sim.use_item(potion),"Potion cooldown prevents double use")
        sim.state.player.hp=sim.stats().hp;sim.state.skill_cooldowns={};sim.state.use_cd=0;qty=sim.quantity(potion)
        check(not sim.campaign.cast(0) and not sim.use_item(potion) and sim.quantity(potion)==qty,"Full health wastes neither healing source")
        potion=sim.catalog.items[potion].next;heal=sim.catalog.items[heal].next
    fresh();sim.add_item("potion",2);sim.add_item("skill_heal",2);sim.equip("skill_heal")
    check(sim.normal("potion").heal==25 and sim.normal("skill_heal").power==10,"Distinct tier-one base heals (Change 6: Heal 6 -> 10)")
    check(sim.player_upgrade_value("cooldown_heal")==18,"Heal base cooldown")
    sim.state.upgrades.cooldown_heal=6
    check(is_equal_approx(sim.player_upgrade_value("cooldown_heal"),12.6),"Max cooldown upgrade stays meaningful")
    # Real save/load with JSON serialization and registered provider.
    fresh();sim.add_item("potion",4);sim.add_item("wood_sword",3);sim.equip("wood_sword");sim.merge("wood_sword")
    sim.state.coins=123.5;sim.state.gems=55.25;sim.buy_upgrade("coin_amount",0)
    sim.state.main_claimed=[0];sim.state.auto_slots=[0]
    sim.state.tutorial.done=["move","kill"];sim.state.tutorial.seen=["overview"]
    sim.campaign.reveal_segment(sim.position_of(sim.state.player),Vector2(350,350))
    var expected=sim.snapshot();check(sim._valid_snapshot(expected),"Current save validates")
    check(SaveService.save_now(),"Current snapshot writes to disk")
    sim.state.coins=0;sim.state.items={};SaveService.load_and_apply()
    check(not SaveService.write_blocked and sim.quantity("potion")==4 and sim.quantity("wood_sword")==2,"Disk reload preserves inventory")
    check(is_equal_approx(sim.state.coins,expected.coins) and sim.state.weapon==expected.weapon,"Disk reload preserves currency and equipment")
    check(sim.state.tutorial.done==expected.tutorial.done and sim.state.explored==expected.explored,"Disk reload preserves guidance and exploration")
    check(sim.state.spawns.has(0) and sim.state.camps["1"].has(0) and sim.state.main_claimed.has(0) and sim.state.auto_slots.has(0),"JSON round trip preserves integer membership")
    var old=sim.snapshot();old.schema=6;sim.restore(old)
    check(sim.state.schema==7 and sim.state.coins==0 and not SaveService.write_blocked and SaveService.save_now(),"Obsolete profile resets to writable state")
    var bad=sim.snapshot();bad.explored['1']['999999,0']=true
    check(not sim._valid_snapshot(bad),"Out-of-bounds fog cells rejected")
    sim.restore(bad);check(not SaveService.write_blocked and SaveService.save_now(),"Invalid development profile recovers to writable state")
    # One opponent at a time, even with nearby actors in the first two types.
    for group in [0,1]:
        fresh()
        var targets=sim.state.enemies.filter(func(e):return e.group==group)
        var enemy=targets[0]
        sim.state.player.x=enemy.x;sim.state.player.y=enemy.y;sim.state.player.idle=-100
        sim.step(.1)
        check(targets.all(func(e):return not e.aggro),"Early neighbors do not aggro on approach")
        sim.state.player.target=enemy.id;sim._start_attack(sim.state.player,enemy,1.0);sim._resolve_attack(sim.state.player,1.0)
        check(targets.filter(func(e):return e.aggro).size()==1,"Only struck early enemy retaliates")
    for g in sim.catalog.groups:
        if g.stage==1:check(g.skills.is_empty(),"Stage 1 has no skills")
        if g.boss:check(g.visual_scale>=2 or g.id in ["boss-bee","boss-squirrel"],"Boss has deliberate scale")
    fresh();var before=sim.state.explored.duplicate(true);game.world.pan_camera(Vector2(200,200));await frames()
    check(sim.state.explored==before,"Camera reveals nothing")
    sim.campaign.reveal_segment(Vector2(150,150),Vector2(750,750))
    for i in range(1,9):check(sim.campaign.cell_known(Vector2.ONE*(150+60*i)),"Continuous movement leaves no holes")
    sim.state.player.hp=0;before=sim.state.explored.duplicate(true);sim.campaign.reveal_segment(Vector2.ZERO,Vector2(950,950));check(sim.state.explored==before,"Dead actor reveals nothing")
    fresh();await frames()
    var boss=sim.state.enemies.filter(func(e):return sim.catalog.groups[e.group].boss)[0]
    sim.campaign.reveal_circle(sim.position_of(boss),200);await frames()
    check(game.world.views[boss.id].visual_scale==2,"Boss view receives scale")
    game.world._spell("player","heal",sim.position_of(sim.state.player));await frames()
    for child in game.world.get_children():
        if child is AnimatedSprite2D:check(child.z_index<game.world.get_node("Actors").z_index,"Spell renders beneath actors")
    for route in ["missions","upgrades","stats","prestige","map","travel","inventory","settings","offline"]:
        game._open(route);await frames();check(game.rows.get_child_count()>0,"UI route builds: "+route)
    game._close();game.guide.choose("guided");await frames();check(game.guide.pending=="move","Fresh guided lesson")
    game._open("stats");await frames();check(not game.guide.card.visible and game.guide.suspended_by=="stats","Unrelated panel suspends guidance")
    game._close();await frames();check(game.guide.card.visible,"Closing panel restores guidance")
    game.guide.choose("none");await frames();check(not game.guide.card.visible,"None mode has no instruction")
    check(SaveService.hard_reset() and sim.state.tutorial.mode=="pending","Hard Reset returns onboarding chooser")
    print("CHANGE_5_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)
