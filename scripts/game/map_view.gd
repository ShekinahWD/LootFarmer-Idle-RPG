extends Control
signal selected(group: int)
signal open_map
@export var mini: bool=false
var sim
var refresh: float=0
var signature: String=""
const BADGE=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-248.png")
const STAR=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-211.png")
const CAMP=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-249.png")
func _process(dt: float) -> void:
    refresh+=dt
    if sim==null:return
    if refresh<.15 and signature!="":return
    refresh=0
    var next:="%s:%s:%s:%s:%s" % [size,sim.state.stage,sim.campaign.discovery_revision,sim.level("map_detail",int(sim.state.stage)),sim.position_of(sim.state.player)]
    if next!=signature:signature=next;queue_redraw()
func transform_rect() -> Rect2:
    var bounds=Vector2(sim.catalog.world.size[0],sim.catalog.world.size[1])
    var scale_factor=minf(size.x/bounds.x,size.y/bounds.y)
    return Rect2((size-bounds*scale_factor)*.5,bounds*scale_factor)
func _draw() -> void:
    if sim==null:return
    var rect=transform_rect()
    var scale_factor=rect.size.x/float(sim.catalog.world.size[0])
    draw_rect(rect,Color(.06,.08,.1))
    var cell: float=sim.campaign.fog_rules.cell_size
    for key in sim.state.explored.get(str(sim.state.stage),{}):
        var bits=key.split(",");var pos=Vector2(int(bits[0]),int(bits[1]))*cell
        draw_rect(Rect2(rect.position+pos*scale_factor,Vector2.ONE*cell*scale_factor),Color(.28,.4,.32))
    var rank=sim.level("map_detail",int(sim.state.stage))
    for g in sim.campaign.stage().groups:
        if rank==0 or not sim.campaign.discovered(g):continue
        var d=sim.catalog.groups[g];var pos=rect.position+Vector2(d.center[0],d.center[1])*scale_factor
        if rank==1:draw_texture_rect(STAR if d.boss else BADGE,Rect2(pos-Vector2.ONE*7,Vector2.ONE*14),false)
        else:draw_texture_rect(sim.catalog.icon(d.body),Rect2(pos-Vector2(12,12),Vector2(24,24)),false)
    for i in range(sim.campaign.stage().spawns.size()):
        var point=sim.campaign.stage().spawns[i];var pos=Vector2(point[0],point[1])
        if sim.campaign.cell_known(pos):draw_texture_rect(CAMP,Rect2(rect.position+pos*scale_factor-Vector2.ONE*6,Vector2.ONE*12),false,Color.WHITE if sim.state.spawns.has(i) else Color(.55,.55,.55))
    draw_texture_rect(STAR,Rect2(rect.position+sim.position_of(sim.state.player)*scale_factor-Vector2.ONE*5,Vector2.ONE*10),false,Color(.5,.9,1))
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
        if mini:open_map.emit();accept_event();return
        var rect=transform_rect()
        if not rect.has_point(event.position) or sim.level("map_detail",int(sim.state.stage))<2:return
        var scale_factor=rect.size.x/float(sim.catalog.world.size[0])
        for g in sim.campaign.stage().groups:
            if not sim.campaign.discovered(g):continue
            var d=sim.catalog.groups[g];var p=rect.position+Vector2(d.center[0],d.center[1])*scale_factor
            if p.distance_to(event.position)<20:selected.emit(g);accept_event();return
