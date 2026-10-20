extends Node
var sim: LootSimulation
var checks:=0
var failures: Array[String]=[]

func check(value: bool,description: String) -> void:
    checks+=1
    if not value:
        failures.append(description)
        push_error(description)

func _ready() -> void:
    call_deferred("run")

func reset() -> void:
    get_tree().paused=false
    sim.new_profile()
    sim.rng.seed=12345

func run() -> void:
    check(BootContext.is_probe and BootContext.profile_name.begins_with("probe-"),"Probe is isolated before save load")
    sim=LootSimulation.new()
    add_child(sim)
    sim.set_physics_process(false)
    reset()
    check(sim.add_item("wood_sword",4),"Acquire initial weapon stack")
    var extras: Dictionary=sim.record("wood_sword").extras.duplicate()
    sim.equip("wood_sword")
    sim.merge("wood_sword",true)
    check(sim.quantity("wood_sword")==1 and sim.record("wood_sword").merge==3,"Three duplicates yield three merges and one retained copy")
    check(sim.record("wood_sword").extras==extras,"Merge never changes extra stats")
    check(not sim.sell("wood_sword",true),"Last equipped copy is protected")
    sim.equip("wood_sword")
    sim.sell("wood_sword",true)
    check(sim.quantity("wood_sword")==0,"Unequipped last copy can be sold")
    sim.add_item("wood_sword")
    check(sim.record("wood_sword").merge==3 and sim.record("wood_sword").extras==extras,"Zero quantity retains merge and extras")
    sim.add_item("sprout")
    sim.add_item("robot")
    check(not sim.add_item("iron_sword"),"Full inventory rejects new identity")
    check(sim.add_item("wood_sword"),"Full inventory still stacks existing identity")
    sim.state.upgrades.sell=1
    sim.record("iron_sword")
    sim.toggle_sell("iron_sword")
    var coins: int=sim.state.coins
    check(sim.add_item("iron_sword") and sim.state.coins==coins+15 and sim.quantity("iron_sword")==0,"Marked identity sells through full inventory")
    reset()
    sim.add_item("wood_sword",201)
    sim.merge("wood_sword",true)
    sim.equip("wood_sword")
    check(sim.record("wood_sword").merge==100 and sim.quantity("wood_sword")==101,"Merge cap preserves evolution stock")
    check(not sim.merge("wood_sword"),"At cap merge consumes nothing")
    check(sim.evolve("wood_sword"),"Eligible evolution succeeds")
    check(sim.quantity("wood_sword")==1 and sim.quantity("stone_sword")==1 and sim.state.weapon=="wood_sword","Evolution keeps source equipped and creates one target")
    check(sim.record("wood_sword").merge==100 and sim.record("stone_sword").merge==0,"Evolution preserves independent identity progression")
    sim.add_item("wood_sword",100)
    sim.record("stone_sword").merge=9
    var target_extras: Dictionary=sim.record("stone_sword").extras.duplicate()
    sim.evolve("wood_sword")
    check(sim.record("stone_sword").merge==9 and sim.record("stone_sword").extras==target_extras,"Existing target merge and roll survive evolution")
    reset()
    sim.add_item("wood_sword",201)
    sim.merge("wood_sword",true)
    sim.add_item("sprout")
    sim.add_item("robot")
    check(not sim.evolve("wood_sword") and sim.quantity("wood_sword")==101,"Full inventory blocks evolution before spending")
    reset()
    sim.add_item("potion",5)
    sim.merge("potion",true)
    sim.add_item("potion")
    sim.state.player.hp=80.0
    check(not sim.use_item("potion") and sim.quantity("potion")==2,"Exactly 80 percent rejects potion without spending")
    sim.state.player.hp=79.9
    check(sim.use_item("potion") and sim.quantity("potion")==1 and sim.record("potion").merge==4,"Below 80 percent uses one upgraded dose")
    check(not sim.use_item("potion"),"Cooldown prevents duplicate use")
    sim.state.supplies.append("")
    sim.add_item("coin_boost",2)
    sim.use_item("coin_boost")
    sim.record("coin_boost").merge=100
    sim.use_item("coin_boost")
    check(is_equal_approx(sim.state.boost_time,60) and is_equal_approx(sim.state.boost_power,.55),"Boost extends duration and improves potency")
    reset()
    var enemy: Dictionary=sim.state.enemies[0]
    sim.state.player.x=enemy.x-25
    sim.state.player.y=enemy.y
    sim.step(.49)
    check(enemy.hp==sim.enemy_definition(0,0).hp,"Stop-to-attack delay prevents early damage")
    sim.step(.02)
    check(sim.state.player.windup>0,"Attack starts after half a second")
    var before_hp: float=enemy.hp
    sim.movement=Vector2.DOWN
    sim.step(.3)
    check(enemy.hp==before_hp and sim.state.player.windup==0,"Manual movement cancels pending contact")
    sim.movement=Vector2.ZERO
    sim.state.player.x=enemy.x-25
    sim.state.player.y=enemy.y
    sim.step(1.01)
    sim.step(.23)
    var after: float=enemy.hp
    sim.step(.01)
    check(after<before_hp and is_equal_approx(enemy.hp,after),"Contact resolves once")
    var assisted:=false
    for other in sim.state.enemies:
        if other.group==0 and other.id!=enemy.id and other.aggro:
            assisted=true
    check(not assisted,"First group does not alert neighbors")
    enemy.hp=1
    sim.state.player.cooldown=0.0
    sim.step(.1)
    sim.step(.23)
    var earned: int=sim.state.coins
    var snap:=sim.snapshot()
    sim.restore(snap)
    sim.step(.1)
    check(sim.state.coins==earned and sim.state.enemies[0].hp<=0,"Reload does not resurrect or reward a killed enemy")
    reset()
    sim.state.player.hp=0
    sim._kill(sim.state.player)
    sim.step(9)
    check(sim.state.player.hp==0,"Respawn respects ten second delay")
    sim.step(1.01)
    check(sim.state.player.hp==sim.stats().hp and sim.state.player.y==1390,"Respawn restores HP at selected camp")
    check(sim.state.coins==0 and sim.state.gems==0,"Death costs no currency")
    reset()
    sim._drop("wood_sword",sim.state.player)
    var time: float=sim.state.clock
    var ttl: float=sim.state.pickups[0].ttl
    get_tree().paused=true
    sim.step(100)
    check(sim.state.clock==time and sim.state.pickups[0].ttl==ttl,"Explicit pause freezes all simulation clocks")
    get_tree().paused=false
    sim.suspended=true
    sim.step(100)
    check(sim.state.clock==time,"Background suspension does not simulate")
    sim.suspended=false
    sim.step(301)
    check(sim.state.pickups.is_empty(),"Ground loot expires in simulated time")
    reset()
    sim.state.coins=123
    sim.state.gems=45
    sim.state.upgrades={"collect:0":1,"collect_range:0":2,"gear_slots":1,"respawn":3,"loot:0":2,"sell":1,"auto_use":1}
    sim.state.gear.append("")
    sim.state.sell_list=["wood_sword"]
    sim.state.auto_slots=[0]
    sim.state.spawns=[0,1]
    sim.state.spawn=1
    sim.state.focus=1
    sim.add_item("wood_sword",5)
    sim.state.victory=true
    sim.state.offer=["hp","damage","merge"]
    sim.state.cards={"damage":1}
    check(sim.prestige("hp"),"Prestige commits durable new profile")
    check(sim.state.coins==0 and sim.state.gems==0 and sim.state.items.is_empty(),"Prestige resets run economy and identity progress")
    check(sim.level("collect",0)==1 and sim.level("collect_range",0)==2 and sim.state.gear.size()==4,"Prestige retains automation levels and capacity")
    check(sim.level("respawn")==0 and sim.level("loot",0)==0 and sim.state.spawn==0,"Prestige clears run upgrades and camps")
    check(sim.state.sell_list.is_empty() and sim.state.auto_slots.is_empty() and sim.state.focus==-1,"Prestige clears unsafe automation bindings")
    check(sim.state.cards.hp==1 and sim.state.cards.damage==1 and sim.state.prestiges==1,"Cards accumulate exactly once")
    check(not sim.prestige("damage"),"Cannot repeat prestige claim")
    SaveService.load_and_apply()
    check(sim.state.cards.hp==1 and sim.state.prestiges==1,"Prestige survives reloading")
    get_tree().paused=true
    check(SaveService.hard_reset(),"Hard Reset commits from pause")
    check(not get_tree().paused and sim.state.cards.is_empty() and sim.state.prestiges==0,"Hard Reset clears progression and resumes")
    SaveService.load_and_apply()
    check(sim.state.cards.is_empty(),"Reset backup does not resurrect cards")
    check(TranslationServer.get_locale().begins_with("en"),"English-only gate remains active")
    reset()
    var malformed:=sim.snapshot()
    malformed.items={"wood_sword":{"qty":2,"merge":101,"extras":{}}}
    sim.restore(malformed)
    check(SaveService.write_blocked and sim.state.items.is_empty(),"Malformed gameplay section cannot overwrite or load invalid state")
    SaveService.write_blocked=false
    reset()
    var guard: Dictionary=sim.state.enemies[4]
    guard.x=guard.home_x+250
    guard.y=1100
    guard.aggro=true
    sim.state.player.x=guard.x-10
    sim.state.player.y=1100
    sim.step(.1)
    check(guard.returning and not guard.aggro,"Leashed enemy returns without immediate proximity re-aggro")
    guard.hp=20.0
    guard.quiet=4.9
    sim.step(.2)
    check(guard.hp>20,"Enemy begins regeneration after five seconds without a hit")
    reset()
    sim.state.upgrades={"collect:0":1,"merge_gear:0":1,"auto_use":1}
    sim.add_item("wood_sword",3)
    sim.add_item("potion",2)
    sim.bind_auto(0)
    sim.state.player.hp=40
    sim._drop("wood_sword",sim.state.player)
    sim._automate(10.1)
    check(sim.state.pickups.is_empty() and sim.record("wood_sword").merge==1,"Collection and gear auto-merge use shared inventory rules")
    check(sim.quantity("potion")==1 and sim.state.player.hp>40,"Bound auto-use consumes a potion on its scheduled check")
    reset()
    sim.state.upgrades={"focus:1":1}
    sim.focus(1)
    sim.state.player.hp=0
    sim._kill(sim.state.player)
    sim.step(10.1)
    var start_y: float=sim.state.player.y
    sim.step(1.1)
    check(sim.state.player.y<start_y and sim.state.focus==1,"Focus resumes travel after respawn")
    sim.movement=Vector2.RIGHT
    sim.step(.1)
    check(sim.state.focus==-1,"Manual movement cancels focus")
    print("GAMEPLAY_PROBE checks=%d failures=%d" % [checks,failures.size()])
    get_tree().quit(0 if failures.is_empty() else 1)
