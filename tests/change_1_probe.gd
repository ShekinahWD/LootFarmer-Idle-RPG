extends Node
var checks:=0
var failures:=0
var game
var sim
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(label_)
func _ready() -> void:call_deferred("run")
func frames() -> void:
    for i in range(6):await get_tree().process_frame
func fresh() -> void:
    sim.new_profile()
    sim.state.gems=1000000
    sim.state.coins=1000000
    SaveService.write_blocked=false
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    sim=game.sim
    sim.set_physics_process(false)
    fresh()
    var prices: Array=[50,75,105,140,180,220,265,320,400,500]
    for i in range(10):
        check(sim.upgrade_cost("gem_amount")==prices[i],"Exact authored amount cost")
        check(sim.buy_upgrade("gem_amount"),"Buy global gem amount")
    check(sim.gem_amount()==6 and not sim.buy_upgrade("gem_amount"),"Six gems and capped purchase")
    for i in range(12):check(sim.buy_upgrade("gem_chance"),"Buy chance track")
    for g in range(4):sim.state.group_kills[g]=10000
    sim.state.cards.gems=100
    for g in range(3):check(is_equal_approx(sim.gem_chance(g),.2),"Normal total cap includes achievements and cards")
    sim.state.cards={}
    sim.state.group_kills=[0,0,0,0]
    for i in range(8):
        check(sim.upgrade_cost("boss_gem_chance",3)==[100,150,225,325,450,600,800,1000][i],"Boss cost is not multiplied again")
        check(sim.buy_upgrade("boss_gem_chance",3),"Boss chance purchased")
    for i in range(10):check(sim.buy_upgrade("boss_gem_amount",3),"Boss amount purchased")
    check(is_equal_approx(sim.gem_chance(3),.6) and sim.gem_amount(0,3)==16,"Boss combined maximum")
    check(sim.gem_amount()==6 and not sim.buy_upgrade("boss_gem_amount",0),"Boss bonus stays boss-only")
    sim.rng.seed=7
    var before: float=sim.state.gems
    for i in range(100):sim._reward(sim.state.enemies[-1])
    var gained: float=sim.state.gems-before
    check(gained>0 and is_equal_approx(gained/16,round(gained/16)),"Boss actual reward includes bonus")
    fresh()
    for g in range(3):
        check(sim.upgrade_cost("spawn_amount",g)==150*(g+1),"Later enemy spawn prices scale")
        for i in range(3):check(sim.buy_upgrade("spawn_amount",g),"Buy capacity")
        check(sim.spawn_amount(g)==6 and not sim.buy_upgrade("spawn_amount",g),"Capacity caps at six")
        for variant in range(3):
            var count:=0
            for enemy in sim.state.enemies:
                if enemy.group==g and enemy.variant==variant:count+=1
            check(count==6,"Six real actors per spot")
        for i in range(5):sim.buy_upgrade("spawn_cooldown",g)
        var actor: Dictionary=sim.state.enemies.filter(func(a: Dictionary)->bool:return int(a.group)==g)[0]
        sim._kill(actor)
        check(is_equal_approx(actor.respawn,float(sim.catalog.groups[g].respawn)*.5),"Death uses upgraded cooldown")
    check(not sim.buy_upgrade("spawn_amount",3) and not sim.buy_upgrade("spawn_cooldown",3),"Boss excludes spawn upgrades")
    check(sim.spawn_amount(3)==1 and sim.spawn_cooldown(3)==30,"Single boss with thirty-second respawn")
    var save: Dictionary=sim.snapshot()
    sim.new_profile()
    sim.restore(save)
    check(not SaveService.write_blocked and sim.state.enemies.size()==55,"Spawn count persists without duplicate actors")
    fresh()
    check(not sim.buy_upgrade("collect") and sim.buy_upgrade("collect",0),"Collection only purchases per type")
    sim.state.player.x=500
    sim.state.player.y=500
    sim._drop("wood_sword",{"group":0,"x":500,"y":500})
    sim._drop("stone_sword",{"group":1,"x":500,"y":500})
    sim._drop("potion",{"group":1,"x":500,"y":500})
    sim._automate(9.9)
    check(sim.quantity("wood_sword")==0,"No collection before ten seconds")
    sim._automate(.1)
    check(sim.quantity("wood_sword")==1 and sim.quantity("stone_sword")==0 and sim.quantity("potion")==0,"Collector cannot collect other types including shared consumables")
    sim.buy_upgrade("collect",1)
    sim.buy_upgrade("collect_batch",1)
    sim._automate(10)
    check(sim.quantity("stone_sword")==1 and sim.quantity("potion")==1,"Per-type batch collects its own drops")
    for i in range(5):sim.buy_upgrade("collect_speed",0)
    check(sim.group_upgrade_value("collect_speed",0)==5 and sim.group_upgrade_value("collect_speed",1)==10,"Independent collection intervals")
    sim.buy_upgrade("collect_range",0)
    check(sim.group_upgrade_value("collect_range",0)==120 and sim.group_upgrade_value("collect_range",1)==100,"Independent collection ranges")
    fresh()
    var old: Dictionary=sim.snapshot()
    old.schema=4
    old.erase("collect_clocks")
    old.upgrades={"collect":1,"collect_range":2,"collect_batch":1,"collect_speed":3,"gem_chance":2,"gem_amount":1}
    old.gems=7.5
    sim.restore(old)
    check(not SaveService.write_blocked and sim.state.schema==5 and sim.state.gems==247.5,"Migration refunds exact old global gem prices")
    for g in range(4):check(sim.level("collect",g)==1 and sim.level("collect_speed",g)==3,"Old collection purchases retained for every type")
    var migrated: Dictionary=sim.snapshot()
    sim.restore(migrated)
    check(sim.state.gems==247.5,"Migration refund occurs once")
    sim.state.victory=true
    sim.state.offer=["hp"]
    check(sim.prestige("hp") and sim.level("collect",1)==1,"Collection retains original permanence after prestige")
    await frames()
    game.player_tab=0
    game._open("upgrades")
    check(game.action_buttons.size()==1 and game.action_buttons[0].id=="respawn","Player only has respawn")
    for g in range(4):
        game.group=g
        game.enemy_tab=1
        game._open("enemy")
        var ids: Array=[]
        for action in game.action_buttons:ids.append(action.id)
        check(ids.has("collect") and ids.has("collect_speed") and ids.has("collect_range") and ids.has("collect_batch"),"Collection is visible in each enemy panel")
        check(ids.has("boss_gem_amount") if g==3 else ids.has("spawn_amount"),"Correct special upgrades per type")
    fresh()
    sim.add_item("wood_sword",3)
    game._select_slot(0,0)
    check(not _has_text(game.rows,tr("MORE_OPTIONS")) and _has_prefix(game.rows,tr("REROLL").split("%")[0]),"Item advanced actions are always visible")
    for viewport_size in [Vector2i(360,640),Vector2i(450,800),Vector2i(720,1280),Vector2i(640,360)]:
        get_window().size=viewport_size
        await frames()
        game._confirm(tr("RESET_CONFIRM"),func()->void:SaveService.hard_reset())
        await frames()
        var box: Control=game.get_node("Confirm/Panel")
        check(game.get_global_rect().encloses(box.get_global_rect()),"Confirmation stays within viewport")
        for name_ in ["Confirm","Cancel"]:
            var button: Control=game.get_node("Confirm/Panel/Margin/Content/Actions/"+name_)
            check(box.get_global_rect().encloses(button.get_global_rect()),"Confirmation buttons stay inside panel")
        game._cancel_confirm()
    get_tree().paused=true
    game._confirm(tr("RESET_CONFIRM"),func()->void:SaveService.hard_reset())
    game.get_node("Confirm/Panel/Margin/Content/Actions/Confirm").pressed.emit()
    check(not get_tree().paused and sim.state.items.is_empty() and not game.get_node("Confirm").visible,"Hard reset confirmation works while paused")
    print("CHANGE_1_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free()
    await frames()
    get_tree().quit(1 if failures else 0)
func _has_text(node: Node,value: String) -> bool:
    for child in node.find_children("*","Button",true,false):
        if child.text==value:return true
    return false
func _has_prefix(node: Node,value: String) -> bool:
    for child in node.find_children("*","Button",true,false):
        if child.text.begins_with(value):return true
    return false
