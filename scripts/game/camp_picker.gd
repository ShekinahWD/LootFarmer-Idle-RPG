extends Control
## Visual destination picker: real stage coordinates and remembered exploration, no state switching.
## Two modes share the drawing, the hit test and the drag rule:
## - travel (World → another map): a tap on an owned camp emits `chosen` and the caller travels.
## - select (Change 64, a camp's Teleport): a tap only emits `chosen` so the caller marks the camp as the
##   selected destination; the caller's Confirm performs the move through the one travel action
##   (game_ui._travel_to → campaign.camp_action). The camp the player stands in emits `refused` instead.
## Only camps the player owns or has sighted (campaign.camp_known) are drawn, so no map reveals more.
signal chosen(camp: int)
signal refused(reason: String)
var sim
var stage_id: int=1
var select_mode:=false
## Select mode: the chosen destination on this map (-1: none here) and the camp the player stands in
## when this map is the current stage (-1: not on this map / not in a camp).
var selected:=-1
var here:=-1
const CAMP=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-249.png")
const OWNED_RING:=Color(.5,1,.7)
const LOCKED_RING:=Color(.5,.5,.5)
const HERE_RING:=Color(.45,.8,1)
const SELECTED_RING:=Color(1,.84,.34)

func _init() -> void:
    set_meta("own_children",true)

func map_rect() -> Rect2:
    var d: Dictionary=sim.catalog.stages[stage_id-1]
    var bounds:=Vector2(d.size[0],d.size[1])
    var pad:=32.0 if select_mode else 48.0
    var factor:=minf((size.x-pad)/bounds.x,(size.y-pad)/bounds.y)
    return Rect2((size-bounds*factor)*.5,bounds*factor)

## Marker radius: the travel picker's 44, smaller only when a short map would make neighbours overlap.
func radius() -> float:
    return clampf(map_rect().size.x*.07,30.0,44.0)

## Local position of a camp marker (the Guided pointer targets it).
func camp_point(i: int) -> Vector2:
    var d: Dictionary=sim.catalog.stages[stage_id-1]
    var rect:=map_rect()
    return rect.position+Vector2(d.spawns[i][0],d.spawns[i][1])*(rect.size.x/float(d.size[0]))

func _owned(i: int) -> bool:
    return sim.state.camps.get(str(stage_id),[0]).has(i)

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
    draw_rect(rect,Color(.35,.42,.5),false,2)
    var r:=radius()
    var font:=get_theme_default_font()
    for i in range(d.spawns.size()):
        if not sim.campaign.camp_known(i,stage_id):continue
        var at:=camp_point(i)
        var owned:=_owned(i)
        var is_here: bool=select_mode and i==here
        var is_selected: bool=select_mode and i==selected
        if is_selected:draw_circle(at,r+10,Color(SELECTED_RING,.35))
        draw_circle(at,r,Color(.12,.18,.2))
        var tint:=Color.WHITE if owned else Color(.35,.35,.35)
        if is_here:tint=Color(.6,.85,1)
        draw_texture_rect(UiArt.cropped(CAMP),Rect2(at-Vector2.ONE*r*.9,Vector2.ONE*r*1.8),false,tint)
        var ring:=OWNED_RING if owned else LOCKED_RING
        if is_here:ring=HERE_RING
        if is_selected:ring=SELECTED_RING
        draw_arc(at,r,0,TAU,40,ring,4.0 if (is_here or is_selected) else 2.0)
        var number:=str(i+1)
        var font_size:=18
        var width:=font.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
        var base:=at+Vector2(-width*.5,r+20)
        draw_string_outline(font,base,number,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,4,Color.BLACK)
        draw_string(font,base,number,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ring)
    # The player's own position on the map they are on (select mode), over the markers.
    if select_mode and stage_id==int(sim.state.stage) and sim.state.player.hp>0:
        var p: Vector2=rect.position+sim.position_of(sim.state.player)*factor
        draw_circle(p,9,Color.BLACK)
        draw_circle(p,7,HERE_RING)

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

## The drawn camp nearest the tap, within its marker (plus a small touch margin); -1 when none.
func camp_at(point: Vector2) -> int:
    var d: Dictionary=sim.catalog.stages[stage_id-1]
    var best:=-1
    var reach:=maxf(radius()+8,48.0)
    for i in range(d.spawns.size()):
        if not sim.campaign.camp_known(i,stage_id):continue
        var distance:=camp_point(i).distance_to(point)
        if distance<=reach and (best<0 or distance<camp_point(best).distance_to(point)):best=i
    return best

func _choose_at(point: Vector2) -> void:
    var i:=camp_at(point)
    if i<0:return
    accept_event()
    if not _owned(i):
        if select_mode:refused.emit("TELEPORT_CAMP_LOCKED")
        return
    if select_mode:
        # Selecting never travels; the camp the player stands in is not a destination.
        if i==here:refused.emit("TELEPORT_HERE")
        else:chosen.emit(i)
        return
    if sim.campaign.travel_reason(stage_id,i).is_empty():chosen.emit(i)
