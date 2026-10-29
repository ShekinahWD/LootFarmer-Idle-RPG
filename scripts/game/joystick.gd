extends Control
signal direction_changed(value: Vector2)
@export var radius:=64.0
## Change 41: Settings → Joystick position (SettingsState.joystick_position) moves the stick only along
## the bottom of the map, anchored to its left edge, centre or right edge; its size, height and feel
## never change. The margins keep it off the map edges (the map already sits inside the safe area).
@export var edge_margin:=16.0
@export var bottom_margin:=16.0
const POSITIONS:=["left","center","right"]
var slot:=1

## Anchors the stick to the bottom-left, bottom-centre or bottom-right of its parent (0, 1, 2). A thumb
## still on the stick is released first, so a move can never leave a direction held.
func place(value: int) -> void:
    value=clampi(value,0,2)
    if value!=slot and pointer!=-2:release()
    slot=value
    var side: Vector2=custom_minimum_size
    var anchor: float=[0.0,0.5,1.0][value]
    anchor_left=anchor;anchor_right=anchor;anchor_top=1.0;anchor_bottom=1.0
    offset_left=[edge_margin,-side.x*.5,-side.x-edge_margin][value]
    offset_right=offset_left+side.x
    offset_top=-side.y-bottom_margin
    offset_bottom=-bottom_margin
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
