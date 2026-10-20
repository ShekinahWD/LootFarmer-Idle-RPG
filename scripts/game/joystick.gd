extends Control
signal direction_changed(value: Vector2)
@export var radius:=64.0
var pointer: int=-2
var direction:=Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and pointer==-2:
            pointer=event.index
            _drag(event.position)
        elif not event.pressed and event.index==pointer:
            release()
        accept_event()
    elif event is InputEventScreenDrag and event.index==pointer:
        _drag(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if event.pressed and pointer==-2:
            pointer=-1
            _drag(event.position)
        elif not event.pressed and pointer==-1:
            release()
        accept_event()
    elif event is InputEventMouseMotion and pointer==-1:
        _drag(event.position)
        accept_event()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and not event.pressed and event.index==pointer:
        release()
    elif event is InputEventMouseButton and not event.pressed and pointer==-1:
        release()

func _drag(point: Vector2) -> void:
    direction=((point-size*.5)/radius).limit_length()
    $Knob.position=size*.5-$Knob.size*.5+direction*radius
    direction_changed.emit(direction)

func release() -> void:
    pointer=-2
    direction=Vector2.ZERO
    $Knob.position=size*.5-$Knob.size*.5
    direction_changed.emit(direction)

func _notification(what: int) -> void:
    if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_VISIBILITY_CHANGED:
        if is_node_ready():
            release()
