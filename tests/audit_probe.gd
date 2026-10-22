extends Node
var checks:=0
var failures:=0
var game
func check(ok: bool,message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(message)
func _ready() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    call_deferred("run")
func settle() -> void:
    for i in range(4):await get_tree().process_frame
func touch(point: Vector2,pressed: bool) -> void:
    var e:=InputEventScreenTouch.new()
    e.position=point
    e.index=0
    e.pressed=pressed
    get_viewport().push_input(e,true)
    # Viewport.push_input bypasses OS emulation: inject the companion mouse
    # event that Godot emits for a physical Android touch.
    var mouse:=InputEventMouseButton.new()
    mouse.device=InputEvent.DEVICE_ID_EMULATION
    mouse.button_index=MOUSE_BUTTON_LEFT
    mouse.position=point
    mouse.pressed=pressed
    get_viewport().push_input(mouse,true)
func drag(point: Vector2,relative: Vector2) -> void:
    var e:=InputEventScreenDrag.new()
    e.index=0
    e.position=point
    e.relative=relative
    get_viewport().push_input(e,true)
    var mouse:=InputEventMouseMotion.new()
    mouse.device=InputEvent.DEVICE_ID_EMULATION
    mouse.position=point
    mouse.relative=relative
    mouse.button_mask=MOUSE_BUTTON_MASK_LEFT
    get_viewport().push_input(mouse,true)
func blockers(node: Node) -> void:
    for child in node.get_children():
        if child is ScrollBar or child is Slider:continue
        if child is Control:check(child.mouse_filter!=Control.MOUSE_FILTER_STOP,"No input blocker: "+str(child.get_path()))
        blockers(child)
func run() -> void:
    get_tree().root.size=Vector2i(720,1280)
    Input.emulate_mouse_from_touch=true
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    var sim=game.sim
    sim.set_physics_process(false)
    sim.new_profile()
    sim.state.coins=1000000.0
    sim.state.gems=1000000
    sim.add_item("wood_sword",5)
    sim.add_item("potion",5)
    sim.state.player.hp=20
    await settle()
    # Pause is enforced by commands, not merely disabled controls.
    get_tree().paused=true
    var before:=JSON.stringify(sim.snapshot())
    for command in [func():return sim.buy_upgrade("loot",0),func():return sim.merge("wood_sword"),func():return sim.equip("wood_sword"),func():return sim.use_item("potion"),func():return sim.sell("wood_sword"),func():return sim.purchase_consumable("potion"),func():return sim.select_spawn(1),func():return sim.toggle_sell("wood_sword"),func():return sim.bind_auto(0),func():return sim.focus(0)]:
        check(not command.call(),"Paused mutation refused")
        check(JSON.stringify(sim.snapshot())==before,"Paused action leaves save unchanged")
    check(not sim.stats().is_empty(),"Stats can be read while paused")
    get_tree().paused=false
    sim.state.paused=true
    var saved: Dictionary=sim.snapshot()
    sim.restore(saved)
    check(not get_tree().paused,"Legacy saved pause is not restored")
    sim.state.coins=1000000
    sim.state.gems=1000000
    game.group=0
    game.enemy_tab=1
    game._open("enemy")
    await settle()
    var scroll=game.get_node("Sheet/Margin/Content/Scroll")
    blockers(scroll)
    var button: Button
    for info in game.action_buttons:
        if info.id=="loot":button=info.node
    check(button!=null,"Find real gear-drop purchase button")
    scroll.scroll_vertical=int(button.position.y) # reset below using its actual global rectangle
    scroll.ensure_control_visible(button)
    await settle()
    var button_id:=button.get_instance_id()
    var old_scroll: int=scroll.scroll_vertical
    sim.buy_upgrade("loot",0)
    game._refresh_panel()
    await settle()
    check(is_instance_valid(button) and button.get_instance_id()==button_id,"Purchase retains live button")
    check(scroll.scroll_vertical==old_scroll,"Purchase retains scroll position")
    var before_level: int=sim.level("loot",0)
    var start: Vector2=button.get_global_rect().get_center()
    touch(start,true)
    for i in range(8):
        drag(start+Vector2(0,-18*(i+1)),Vector2(0,-18))
        await get_tree().process_frame
    touch(start+Vector2(0,-144),false)
    await settle()
    check(scroll.scroll_vertical>old_scroll,"Real drag starting on buy button scrolls")
    check(sim.level("loot",0)==before_level,"Scroll does not buy upgrade")
    scroll.ensure_control_visible(button)
    await settle()
    start=button.get_global_rect().get_center()
    touch(start,true)
    touch(start,false)
    await settle()
    check(sim.level("loot",0)==before_level+1,"Real tap still buys exactly once")
    # Card paper also passes input, and dynamic additions inherit the rule.
    var card=game.rows.get_child(3)
    scroll.ensure_control_visible(card)
    await settle()
    old_scroll=scroll.scroll_vertical
    start=Vector2(card.global_position.x+4,maxf(scroll.global_position.y+8,card.global_position.y+8))
    touch(start,true)
    for i in range(6):
        drag(start+Vector2(0,-20*(i+1)),Vector2(0,-20))
        await get_tree().process_frame
    touch(start+Vector2(0,-120),false)
    await settle()
    check(scroll.scroll_vertical>old_scroll,"Drag starting on card paper scrolls")
    var extra:=Button.new()
    game.rows.add_child(extra)
    check(extra.mouse_filter==Control.MOUSE_FILTER_PASS,"Late button inherits pass-through")
    extra.queue_free()
    sim.state.coins=0
    game._refresh_panel()
    await settle()
    for info in game.action_buttons:
        if info.id=="loot":
            check(info.node.disabled,"Unaffordable upgrade disabled")
            check(info.node.tooltip_text==tr("NOT_ENOUGH_COINS"),"Shared affordability reason displayed")
    check(is_equal_approx(sim.group_upgrade_value("loot",0),sim.gear_chance(0)),"Upgrade preview uses combat getter")
    check(is_equal_approx(sim.group_upgrade_value("group_xp",0),sim.group_xp(0)),"XP preview uses reward getter")
    check(is_equal_approx(sim.group_upgrade_value("coin_amount",0),sim.coin_reward(0)),"Coin preview uses reward getter")
    sim.equip("wood_sword")
    var sum:=0.0
    for bucket in sim.stat_sources().values():sum+=float(bucket.get("damage",0))
    check(is_equal_approx(sum*sim.card("damage"),sim.stats().damage),"Source contributions reconstruct effective damage")
    game._close()
    var enemy: Dictionary=sim.state.enemies[0]
    sim.select_target(enemy.id)
    await settle()
    check(game.world.views[enemy.id].get_node("Marker").visible,"Manual target arrow survives actor processing")
    sim.clear_target()
    await settle()
    check(not game.world.views[enemy.id].get_node("Marker").visible,"Cleared target hides arrow")
    check(game.fmt(1250)=="1.25K","Shared formatter retains compact decimals")
    # Expanded inventory routes real scroll gestures without consuming.
    sim.state.supplies=["potion","","","","",""]
    game._refresh_slots()
    await settle()
    var supply_scroll=game.dock.get_node("Inventory/SupplyColumn/SupplyScroll")
    var slot=supply_scroll.get_node("Supplies").get_child(0)
    var quantity: int=sim.quantity("potion")
    start=slot.get_global_rect().get_center()
    touch(start,true)
    for i in range(5):
        drag(start+Vector2(0,-20*(i+1)),Vector2(0,-20))
        await get_tree().process_frame
    touch(start+Vector2(0,-100),false)
    await settle()
    check(supply_scroll.scroll_vertical>0,"Inventory touch drag reaches scroll parent")
    check(sim.quantity("potion")==quantity and not game.sheet.visible,"Inventory drag neither consumes nor opens")
    print("AUDIT_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free()
    await settle()
    get_tree().quit(1 if failures else 0)
