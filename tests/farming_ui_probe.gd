extends Node
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(message)
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    var game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    var sim=game.sim
    sim.set_physics_process(false)
    sim.new_profile()
    await get_tree().process_frame
    await get_tree().process_frame
    sim.state.coins=1000000.0
    sim.state.gems=1000000
    sim.add_item("potion",2)
    sim.merge("potion")
    check(is_equal_approx(sim.normal("potion").heal,10.4),"Potion gains 0.4 HP per merge")
    sim.record("potion").merge=100
    check(is_equal_approx(sim.normal("potion").heal,50),"Existing potion merge levels recalculate")
    check(not sim.buy_upgrade("merge_gear"),"Global gear auto merge is rejected")
    check(sim.buy_upgrade("merge_gear",0),"Per-type gear auto merge can be bought")
    sim.add_item("wood_sword",2)
    sim.add_item("sprout",2)
    sim.add_item("stone_sword",2)
    sim._automate(5.1)
    check(sim.record("wood_sword").merge==1 and sim.record("sprout").merge==1,"One type unlock automerges its weapons and outfits")
    check(sim.record("stone_sword").merge==0,"Other enemy gear remains unmerged")
    check(not sim.can_auto_merge("potion"),"Consumables still require the player unlock")
    sim.buy_upgrade("merge_supplies")
    check(sim.can_auto_merge("potion"),"Player consumable unlock remains functional")
    for g in range(4):
        check(sim.upgrade_cost("loot",g)==20*(g+1),"General prices scale by group")
        check(sim.upgrade_cost("coin_amount",g)==[30,120,360,900][g],"Coin upgrade has stronger tier scaling")
    sim.buy_upgrade("coin_amount",0)
    check(is_equal_approx(sim.coin_reward(0),float(sim.catalog.groups[0].coins)+.5),"Sprout coin reward retains half coin")
    var before: float=sim.state.coins
    sim._reward(sim.state.enemies[0])
    check(is_equal_approx(sim.state.coins-before,sim.coin_reward(0)),"Fractional coins credited exactly")
    var save: Dictionary=sim.snapshot()
    sim.new_profile()
    sim.restore(save)
    check(is_equal_approx(sim.state.coins,save.coins),"Fractional balance survives save restore")
    save.upgrades["merge_gear"]=1
    sim.restore(save)
    check(sim.level("merge_gear",3)==1 and not sim.state.upgrades.has("merge_gear"),"Legacy global gear auto merge migrates per type")
    check(game.fmt(1250)=="1.25K" and game.fmt(1.5)=="1.50" and game.fmt(2500000)=="2.50M","Shared decimal/suffix formatter")
    sim.select_target(sim.state.enemies[0].id)
    game._refresh_combat_achievement()
    sim.state.enemies[0].hp=0
    sim._kill(sim.state.enemies[0])
    game._refresh_combat_achievement()
    check(game.get_node("Safe/Layout/Map/Achievement").visible and game.get_node("Safe/Layout/Map/EnemyUpgrades").visible,"Group shortcuts persist after instant kill")
    var robot: Dictionary=sim.state.enemies[9]
    sim._start_attack(sim.state.player,robot,1.0)
    robot.hp=0
    sim._kill(robot)
    game._refresh_combat_achievement()
    check(game.combat_group==1,"One-hit kill in a new type updates shortcuts before UI polling")
    game.combat_group=0
    game._refresh_combat_achievement()
    game.get_node("Safe/Layout/Map/EnemyUpgrades").pressed.emit()
    check(game.group==0 and game.enemy_tab==1,"Upgrade shortcut opens correct type")
    check(game.rows.find_children("*","ProgressBar",true,false).size()==12,"Type upgrades include collection and spawn tracks")
    game.enemy_tab=2
    game._refresh_panel()
    check(game.rows.find_children("*","ProgressBar",true,false).size()==8,"Achievement milestones show filled bars")
    for viewport_size in [Vector2i(600,1100),Vector2i(720,1280)]:
        get_tree().root.size=viewport_size
        for i in range(4):await get_tree().process_frame
        game.enemy_tab=1
        game._refresh_panel()
        for i in range(4):await get_tree().process_frame
        check(game.rows.size.x<=game.sheet.size.x,"Upgrade cards fit portrait width")
    sim.state.victory=true
    sim.state.offer=["hp"]
    sim.prestige("hp")
    check(sim.level("merge_gear",0)==0 and sim.level("merge_supplies")==1,"Prestige resets group gear unlock but retains global consumable unlock")
    print("FARMING_UI_PROBE checks=%d failures=%d" % [checks,failures])
    await get_tree().create_timer(2).timeout
    game.queue_free()
    await get_tree().process_frame
    await get_tree().process_frame
    get_tree().quit(1 if failures else 0)
