extends Button
signal quick_tap
signal held
const HOLD_SECONDS:=0.5
var pointer: int=-2
var origin:=Vector2.ZERO
var age:=0.0
var cancelled:=false

func _process(delta: float) -> void:
    if pointer==-2 or cancelled:
        return
    age+=delta
    if age>=HOLD_SECONDS:
        cancelled=true
        held.emit()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _begin(event.index,event.position)
        elif pointer==event.index:
            _finish(event.position)
    elif event is InputEventScreenDrag and pointer==event.index:
        _move(event.position)
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if event.device==InputEvent.DEVICE_ID_EMULATION:
            return
        if event.pressed:
            _begin(-1,event.position)
        elif pointer==-1:
            _finish(event.position)
    elif event is InputEventMouseMotion and pointer==-1:
        _move(event.position)

func _begin(id: int,point: Vector2) -> void:
    if pointer!=-2:
        return
    pointer=id
    origin=point
    age=0
    cancelled=false

func _move(point: Vector2) -> void:
    if point.distance_to(origin)>12:
        cancelled=true

func _finish(point: Vector2) -> void:
    _move(point)
    var activate:=not cancelled and Rect2(Vector2.ZERO,size).has_point(point)
    pointer=-2
    if activate:
        quick_tap.emit()

func _input(event: InputEvent) -> void:
    # Releases outside this control must never leave a pending hold.
    if (event is InputEventScreenTouch and not event.pressed and event.index==pointer) or (event is InputEventMouseButton and not event.pressed and pointer==-1):
        if not get_global_rect().has_point(event.position):
            pointer=-2

func _notification(what: int) -> void:
    if what in [NOTIFICATION_SCROLL_BEGIN,NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_VISIBILITY_CHANGED]:
        pointer=-2
        cancelled=true
