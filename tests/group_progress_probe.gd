extends Node
var checks:=0
var failures:=0
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(label_)
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    var game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    var sim=game.sim
    sim.set_physics_process(false)
    sim.new_profile()
    await get_tree().process_frame
    sim.state.coins=10000000
    sim.state.gems=10000000
    check(not sim.buy_upgrade("focus") and not sim.focus(0),"Global focus purchase and locked group are rejected")
    check(sim.buy_upgrade("focus",0) and sim.focus(0),"Group-specific focused farming unlock")
    check(not sim.focus(1),"Unlock does not affect other enemy types")
    for i in range(15):
        sim.buy_upgrade("loot",0)
        sim.buy_upgrade("supply_drop",1)
    check(is_equal_approx(sim.gear_chance(0),.25) and is_equal_approx(sim.gear_chance(1),.09),"Gear bonus caps at 15 points and stays local")
    var coins: int=sim.state.coins
    check(not sim.buy_upgrade("loot",0) and sim.state.coins==coins,"Capped purchase does not spend currency")
    check(is_equal_approx(sim.consumable_chance(1,"potion"),.25) and is_equal_approx(sim.consumable_chance(1,"coin_boost"),.175),"Consumable bonus applies to each eligible drop")
    check(is_equal_approx(sim.consumable_chance(0,"potion"),.1) and sim.consumable_chance(0,"coin_boost")==0,"Separate upgrades preserve other groups and unavailable drops")
    var xp: float=sim.group_xp(1,0)
    sim.buy_upgrade("group_xp",1)
    check(is_equal_approx(sim.group_xp(1,0),xp*1.1) and is_equal_approx(sim.group_xp(0,0),6),"XP upgrade is per type")
    sim.state.group_kills[0]=24
    var enemy: Dictionary=sim.state.enemies[0]
    enemy.hp=0
    sim._kill(enemy)
    check(sim.state.group_kills[0]==25 and sim.achievement_level(0)==1,"Kill automatically earns first milestone")
    check(is_equal_approx(sim.achievement_damage(0),.05) and is_equal_approx(sim.gem_chance(0),.085),"Milestone grants local damage and gem bonus")
    check(sim.achievement_damage(1)==0 and is_equal_approx(sim.gem_chance(1),.08),"Achievement cannot affect other types")
    var variant_enemy: Dictionary=sim.state.enemies[3]
    variant_enemy.hp=0
    sim._kill(variant_enemy)
    check(sim.state.group_kills[0]==26,"All camp variants share kill progress")
    var victim: Dictionary=sim.state.enemies[1]
    victim.hp=1000
    victim.x=sim.state.player.x+5
    victim.y=sim.state.player.y
    var hp_before: float=victim.hp
    sim._start_attack(sim.state.player,victim,1.0)
    sim._resolve_attack(sim.state.player,.23)
    var expected_damage: float=sim.stats().damage*1.05*(sim.stats().crit_damage if victim.get("critical_hit",false) else 1.0)
    check(is_equal_approx(hp_before-victim.hp,expected_damage),"Permanent damage bonus is applied to real combat contact")
    var save: Dictionary=sim.snapshot()
    sim.new_profile()
    sim.restore(save)
    check(not SaveService.write_blocked and sim.state.group_kills[0]==26,"Achievements survive save restore")
    var old: Dictionary=save.duplicate(true)
    old.schema=2
    old.erase("group_kills")
    old.upgrades["focus"]=1
    sim.restore(old)
    check(not SaveService.write_blocked and sim.state.schema==5 and sim.state.group_kills==[0,0,0,0],"Schema 2 migrates without fabricated past kills")
    check(sim.level("focus",0)==1 and sim.level("focus",3)==1 and not sim.state.upgrades.has("focus"),"Legacy global focus unlock preserved per type for current run")
    sim.restore(save)
    sim.state.victory=true
    sim.state.offer=["hp"]
    check(sim.prestige("hp"),"Prestige saves")
    check(sim.state.group_kills[0]==26 and sim.achievement_level(0)==1,"Prestige keeps permanent progress")
    check(sim.level("focus",0)==0 and sim.level("loot",0)==0 and sim.level("supply_drop",1)==0 and sim.level("group_xp",1)==0,"Prestige resets group purchases")
    sim.state.group_kills[3]=1
    check(sim.achievement_level(3)==1,"Boss uses lower milestone thresholds")
    sim.new_profile()
    check(sim.state.group_kills==[0,0,0,0],"Hard reset clears achievements")
    game.group=0
    game.enemy_tab=2
    game._open("enemy")
    check(game.rows.get_child_count()>8,"Enemy achievements tab displays milestones")
    sim.state.player.x=sim.state.enemies[0].x
    sim.state.player.y=sim.state.enemies[0].y
    sim.select_target(sim.state.enemies[0].id)
    game._refresh_combat_achievement()
    check(game.get_node("Safe/Layout/Map/Achievement").visible,"Fighting shows relevant achievement progress")
    game._open_combat_achievements()
    check(game.group==0 and game.enemy_tab==2,"Combat indicator opens matching group details")
    print("GROUP_PROGRESS_PROBE checks=%d failures=%d" % [checks,failures])
    await get_tree().create_timer(2.0).timeout
    game.queue_free()
    await get_tree().process_frame
    await get_tree().process_frame
    get_tree().quit(1 if failures else 0)
