extends Control
## Own only pointers that start on the map. HUD/joystick touches never join a pinch.
@export var drag_threshold:=10.0
var world: Node2D
var pointers: Dictionary={}
var origin:=Vector2.ZERO
var aiming:=false
var aim_point:=Vector2.ZERO
var dragging:=false
var pinched:=false
var pinch_distance:=0.0
var pinch_zoom:=2.0

func _gui_input(event: InputEvent) -> void:
    if world==null:
        return
    if event is InputEventScreenTouch and event.pressed:
        begin_pointer(event.index,event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
        if event.device!=InputEvent.DEVICE_ID_EMULATION:
            begin_pointer(-1,event.position)
        accept_event()

func _input(event: InputEvent) -> void:
    if pointers.is_empty():
        return
    var local_position:=Vector2.ZERO
    if event is InputEventScreenDrag or event is InputEventScreenTouch or event is InputEventMouseMotion or event is InputEventMouseButton:
        local_position=get_global_transform_with_canvas().affine_inverse()*event.position
    if event is InputEventScreenDrag and pointers.has(event.index):
        move_pointer(event.index,local_position)
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch and not event.pressed and pointers.has(event.index):
        end_pointer(event.index,local_position,event.canceled)
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and pointers.has(-1):
        move_pointer(-1,local_position)
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT and pointers.has(-1):
        end_pointer(-1,local_position)
        get_viewport().set_input_as_handled()

func begin_pointer(id: int,point: Vector2) -> void:
    if pointers.size()>=2 or pointers.has(id) or (id==-1 and not pointers.is_empty()):
        return
    pointers[id]=point
    if pointers.size()==1:
        aiming=not get_tree().paused and not world.sim.suspended and not world.actor_at_screen(point*world.get_viewport_rect().size/size,true).is_empty()
        aim_point=point
        origin=point
        dragging=false
        pinched=false
    elif pointers.size()==2:
        aiming=false
        queue_redraw()
        pinched=true
        var positions:=pointers.values()
        pinch_distance=maxf(1.0,positions[0].distance_to(positions[1]))
        pinch_zoom=SettingsState.camera_zoom

func move_pointer(id: int,point: Vector2) -> void:
    if not pointers.has(id):
        return
    var previous: Vector2=pointers[id]
    pointers[id]=point
    if pointers.size()==2:
        var positions:=pointers.values()
        SettingsState.set_camera_zoom(pinch_zoom*positions[0].distance_to(positions[1])/pinch_distance)
        world.update_camera()
    elif pointers.size()==1 and not pinched:
        if not dragging and point.distance_to(origin)>=drag_threshold:
            dragging=true
            previous=origin
        if aiming:
            aim_point=point
            queue_redraw()
        elif dragging:
            world.pan_camera((point-previous)*world.get_viewport_rect().size/size)

func end_pointer(id: int,point: Vector2,canceled:=false) -> void:
    if not pointers.has(id):
        return
    if aiming and dragging and not canceled and not pinched and Rect2(Vector2.ZERO,size).has_point(point):
        var target: Dictionary=world.actor_at_screen(point*world.get_viewport_rect().size/size)
        if not target.is_empty():
            world.sim.select_target(target.id)
    if not canceled and not dragging and not pinched and point.distance_to(origin)<drag_threshold and Rect2(Vector2.ZERO,size).has_point(point):
        world.collect_at(point*world.get_viewport_rect().size/size)
    pointers.erase(id)
    if pointers.is_empty():
        cancel_gesture()

func cancel_gesture() -> void:
    aiming=false
    queue_redraw()
    pointers.clear()
    dragging=false
    pinched=false

func _notification(what: int) -> void:
    if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:
        cancel_gesture()

func _process(_delta: float) -> void:
    if aiming:
        queue_redraw()

func _draw() -> void:
    if not aiming or not dragging or world==null:
        return
    var start: Vector2=world.player_screen_position()*size/world.get_viewport_rect().size
    var target: Dictionary=world.actor_at_screen(aim_point*world.get_viewport_rect().size/size)
    var color:=Color(1,.75,.2) if not target.is_empty() else Color(.8,.85,.9)
    draw_line(start,aim_point,Color(0,0,0,.7),6,true)
    draw_line(start,aim_point,color,3,true)
    draw_arc(aim_point,12,0,TAU,32,color,2,true)
