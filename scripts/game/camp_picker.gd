extends Control
## Visual destination picker: real stage coordinates and remembered exploration, no state switching.
signal chosen(camp: int)
var sim
var stage_id: int=1
const CAMP=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-249.png")

func _init() -> void:
    set_meta("own_children",true)

func map_rect() -> Rect2:
    var d: Dictionary=sim.catalog.stages[stage_id-1]
    var bounds:=Vector2(d.size[0],d.size[1])
    var factor:=minf((size.x-48)/bounds.x,(size.y-48)/bounds.y)
    return Rect2((size-bounds*factor)*.5,bounds*factor)

func _draw() -> void:
    if sim==null:return
    # Change 24: the player is choosing a camp on this map, so parse its scene in the background now
    # (travel then only instantiates it). Idempotent; nothing happens for a cached or loading map.
    if stage_id!=int(sim.state.stage):preload("res://scripts/game/stage_scenes.gd").request(stage_id)
    var d: Dictionary=sim.catalog.stages[stage_id-1]
    var rect:=map_rect()
    var factor:=rect.size.x/float(d.size[0])
    draw_rect(rect,Color(.06,.08,.1))
    preload("res://scripts/game/map_view.gd").draw_explored(self,sim,stage_id,rect.position,factor)
    for i in range(d.spawns.size()):
        var at:=rect.position+Vector2(d.spawns[i][0],d.spawns[i][1])*factor
        var owned: bool=sim.state.camps.get(str(stage_id),[0]).has(i)
        draw_circle(at,44,Color(.12,.18,.2))
        draw_texture_rect(UiArt.cropped(CAMP),Rect2(at-Vector2.ONE*40,Vector2.ONE*80),false,Color.WHITE if owned else Color(.35,.35,.35))
        draw_arc(at,44,0,TAU,32,Color(.5,1,.7) if owned else Color(.5,.5,.5),2)
        draw_string(get_theme_default_font(),at+Vector2(-4,59),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,16)

var press_at:=Vector2.INF
var press_finger:=-2
var dragged:=false

func _gui_input(event: InputEvent) -> void:
    # Release-only activation lets a drag beginning on a camp scroll the enclosing sheet.
    if event is InputEventScreenDrag and event.index==press_finger:
        dragged=dragged or event.position.distance_to(press_at)>12;return
    if event is InputEventMouseMotion and press_finger==-1:
        dragged=dragged or event.position.distance_to(press_at)>12;return
    var finger:=-2
    if event is InputEventScreenTouch:finger=event.index
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if press_finger>=0:return # touch may also generate mouse events
        finger=-1
    else:return
    if event.pressed:
        press_at=event.position;press_finger=finger;dragged=false;return
    if press_finger!=finger or press_at==Vector2.INF:return
    var tap: bool=not dragged and event.position.distance_to(press_at)<=12
    press_at=Vector2.INF;press_finger=-2
    if tap:_choose_at(event.position)

func _choose_at(point: Vector2) -> void:
    var d: Dictionary=sim.catalog.stages[stage_id-1]
    var rect:=map_rect()
    for i in sim.state.camps.get(str(stage_id),[0]):
        var at:=rect.position+Vector2(d.spawns[int(i)][0],d.spawns[int(i)][1])*(rect.size.x/float(d.size[0]))
        if at.distance_to(point)<=48:
            if sim.campaign.travel_reason(stage_id,int(i)).is_empty():chosen.emit(int(i))
            accept_event();return
