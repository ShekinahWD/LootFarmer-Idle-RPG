extends Node
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    var sim:=LootSimulation.new()
    add_child(sim)
    sim.set_physics_process(false)
    var wins:=0
    for outfit in ["dinosaur","robot","sprout"]:
        sim.new_profile()
        sim.rng.seed=420
        sim.add_item("iron_sword",101)
        sim.merge("iron_sword",true)
        sim.equip("iron_sword")
        sim.add_item(outfit,101)
        sim.merge(outfit,true)
        sim.equip(outfit)
        sim.add_item("potion",400)
        sim.merge("potion",true)
        sim.state.upgrades={"auto_use":1,"use_speed":8}
        sim.bind_auto(0)
        sim.record("iron_sword").extras={"speed":.06,"lifesteal":.015}
        sim.record(outfit).extras={"hp":15.0,"defense":4.0}
        sim.touch()
        sim.state.player.hp=sim.stats().hp
        var boss: Dictionary=sim.state.enemies.filter(func(a: Dictionary)->bool:return int(a.group)==3)[0]
        sim.state.player.x=boss.x
        sim.state.player.y=boss.y+35
        var seconds:=0.0
        while not sim.state.victory and sim.state.player.hp>0 and seconds<180:
            sim.step(1.0/60.0)
            seconds+=1.0/60.0
        if sim.state.victory:
            wins+=1
        print("BOSS_BUILD ",outfit," won=",sim.state.victory," seconds=",snappedf(seconds,.1)," hp=",sim.state.player.hp," stats=",sim.stats())
    print("BOSS_LOADOUT_GATE wins=",wins," required=2")
    get_tree().quit(0 if wins>=2 else 1)
