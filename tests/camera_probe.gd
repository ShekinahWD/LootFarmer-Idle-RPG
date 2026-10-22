extends Node
var game
var surface
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(message)
func touch(id: int,point: Vector2,pressed: bool) -> void:
    var event:=InputEventScreenTouch.new()
    event.index=id
    event.position=point
    event.pressed=pressed
    get_viewport().push_input(event,true)
func drag(id: int,point: Vector2) -> void:
    var event:=InputEventScreenDrag.new()
    event.index=id
    event.position=point
    get_viewport().push_input(event,true)
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    SettingsState.set_sfx_enabled(false)
    SettingsState.set_camera_zoom(2.0)
    game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    game.sim.set_physics_process(false)
    game.sim.new_profile()
    game.sim.state.tutorial.mode="none";game.sim.suspended=false # fixture: onboarding chooser answered (Change 11)
    game.sim.state.player.x=180
    game.sim.state.player.y=800
    await get_tree().process_frame
    await get_tree().process_frame
    surface=game.get_node("Safe/Layout/Map/GestureSurface")
    var center: Vector2=surface.get_global_transform_with_canvas()*(surface.size*.5)
    game.sim._drop("potion",game.sim.state.player)
    var pan_start:=center+Vector2(220,0)
    touch(0,pan_start,true)
    check(surface.pointers.has(0),"Real GUI routing captures map touch")
    drag(0,pan_start+Vector2(60,0))
    touch(0,pan_start+Vector2(60,0),false)
    check(not game.world.following_player,"Dragging unlocks camera")
    check(game.world.camera_position.x<180,"Camera pans with drag at current zoom")
    check(game.sim.quantity("potion")==0,"Dragging over loot does not collect")
    var held: Vector2=game.world.camera_position
    game.sim.state.player.x+=15
    game.world.update_camera()
    check(game.world.camera_position==held,"Auto movement does not steal panned camera")
    touch(1,center-Vector2(40,0),true)
    touch(2,center+Vector2(40,0),true)
    drag(2,center+Vector2(80,0))
    check(is_equal_approx(SettingsState.camera_zoom,3.0),"Two-touch pinch zooms in and respects maximum")
    check(game.world.camera_position==held,"Pinch does not accidentally pan")
    check(is_equal_approx(game.get_node("Safe/Layout/Map/Zoom/Slider").value,3.0),"Slider immediately reflects pinch")
    touch(2,center+Vector2(80,0),false)
    drag(1,center)
    touch(1,center,false)
    check(game.world.camera_position==held and game.sim.quantity("potion")==0,"Remaining pinch finger neither pans nor collects")
    game.stick.direction_changed.emit(Vector2.RIGHT)
    check(game.world.following_player and game.world.camera_position==game.sim.position_of(game.sim.state.player),"Joystick restores player follow immediately")
    game.stick.direction_changed.emit(Vector2.ZERO)
    touch(3,center-Vector2(60,0),true)
    touch(4,center+Vector2(60,0),true)
    drag(4,center-Vector2(20,0))
    check(is_equal_approx(SettingsState.camera_zoom,1.0),"Pinch zooms out to original minimum")
    touch(3,center-Vector2(60,0),false)
    touch(4,center-Vector2(20,0),false)
    var joystick_point: Vector2=game.stick.global_position+game.stick.size*.5+Vector2(40,0)
    touch(5,joystick_point,true)
    check(not surface.pointers.has(5),"Joystick touch cannot join map pinch")
    touch(5,joystick_point,false)
    var slider: HSlider=game.get_node("Safe/Layout/Map/Zoom/Slider")
    touch(6,slider.global_position+slider.size*.5,true)
    check(not surface.pointers.has(6),"Slider touch cannot join map pinch")
    touch(6,slider.global_position+slider.size*.5,false)
    game.world.follow_player()
    game.sim.state.pickups[0].x=game.sim.state.player.x
    game.sim.state.pickups[0].y=game.sim.state.player.y
    touch(7,center,true)
    check(game.sim.quantity("potion")==0,"Loot waits for tap release")
    touch(7,center,false)
    check(game.sim.quantity("potion")==1,"Tap release still collects loot")
    touch(8,center,true)
    surface._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
    check(surface.pointers.is_empty(),"Focus loss clears gesture ownership")
    get_tree().paused=true
    touch(9,center,true)
    drag(9,center+Vector2(40,0))
    touch(9,center+Vector2(40,0),false)
    check(not game.world.following_player,"Map drag works during pause")
    get_tree().paused=false
    print("CAMERA_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free()
    await get_tree().process_frame
    get_tree().quit(1 if failures else 0)
