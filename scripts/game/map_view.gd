extends Control
## Minimap and expanded map. Both read the one discovery store (playbook 117.9 / 124.12): explored
## cells, sighted camps and found encounter spots. Change 8: one small marker per found spot (never
## per type), so neighbouring spots stay separate; nothing is drawn or tappable for a spot the
## player has not found, whatever the Map Details rank.
## Rank 1 generic spot markers, rank 2 the enemy's identity, rank 3 its loadout: weapon badge
## (bottom right) when that spot carries a weapon, outfit shown by the portrait, skill badge (top
## right) on skill spots.
signal selected(group: int,variant: int)
signal open_map
@export var mini: bool=false
## Marker side as a share of the on-map distance between neighbouring spots, and its limits.
@export var marker_share:=0.42
@export var marker_min:=7.0
@export var marker_max:=26.0
var sim
var refresh: float=0
var signature: String=""
const BADGE=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-248.png")
const STAR=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-211.png")
const CAMP=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-249.png")
const PLAIN_BODY="res://assets/PixelPlains/Characters 24x24/Basic character v2.png"
var plain_body: AtlasTexture
func _ready() -> void:
    plain_body=AtlasTexture.new();plain_body.atlas=load(PLAIN_BODY);plain_body.region=Rect2(0,0,24,24)
func _process(dt: float) -> void:
    refresh+=dt
    if sim==null:return
    if refresh<.15 and signature!="":return
    refresh=0
    var next:="%s:%s:%s:%s:%s:%s" % [size,sim.state.stage,sim.campaign.discovery_revision,sim.level("map_detail",int(sim.state.stage)),sim.position_of(sim.state.player),_bosses_alive()]
    if next!=signature:signature=next;queue_redraw()
## A boss marker only shows while that boss is alive on this stage (and, as for every marker, only
## once discovered and with map detail bought): defeated bosses lose it until they respawn.
func boss_alive(g: int) -> bool:
    for e in sim.state.enemies:
        if int(e.group)==g and float(e.hp)>0:return true
    return false
func _bosses_alive() -> String:
    var bits:=""
    for g in sim.campaign.stage().groups:
        if sim.catalog.groups[g].boss:bits+="1" if boss_alive(g) else "0"
    return bits
func marker_visible(g: int,v: int=2) -> bool:
    return sim.campaign.spot_discovered(g,v) and (not sim.catalog.groups[g].boss or boss_alive(g))
## Every found spot of the current stage as [group, variant, map position].
func spots(rect: Rect2,scale_factor: float) -> Array:
    var result: Array=[]
    for g in sim.campaign.stage().groups:
        for v in sim.campaign.variants(g):
            if marker_visible(g,v):result.append([g,v,rect.position+sim.campaign.spot(g,v)*scale_factor])
    return result
func marker_side(scale_factor: float) -> float:
    return clampf(sim.campaign.spot_offset()*2.0*scale_factor*marker_share,marker_min*(.7 if mini else 1.0),marker_max*(.45 if mini else 1.0))
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
    if rank>0:
        var side:=marker_side(scale_factor)
        for entry in spots(rect,scale_factor):
            _marker(entry[0],entry[1],entry[2],side,rank)
    for i in range(sim.campaign.stage().spawns.size()):
        var point=sim.campaign.stage().spawns[i];var pos=Vector2(point[0],point[1])
        if sim.campaign.camp_known(i):draw_texture_rect(CAMP,Rect2(rect.position+pos*scale_factor-Vector2.ONE*6,Vector2.ONE*12),false,Color.WHITE if sim.state.spawns.has(i) else Color(.55,.55,.55))
    draw_texture_rect(STAR,Rect2(rect.position+sim.position_of(sim.state.player)*scale_factor-Vector2.ONE*5,Vector2.ONE*10),false,Color(.5,.9,1))
func _marker(g: int,v: int,pos: Vector2,side: float,rank: int) -> void:
    var boss: bool=sim.catalog.groups[g].boss
    if boss:side*=1.25
    var box:=Rect2(pos-Vector2.ONE*side*.5,Vector2.ONE*side)
    if rank==1 or mini:
        draw_texture_rect(STAR if boss else BADGE,box,false)
        return
    var def: Dictionary=sim.enemy_definition(g,v)
    draw_rect(box.grow(1),Color(0,0,0,.55))
    draw_texture_rect(sim.catalog.icon(def.body) if def.body!="" else plain_body,box,false)
    if boss:draw_rect(box.grow(1),Color(1,.84,.34),false,1.5)
    if rank<3:return
    var badge:=maxf(5,side*.55)
    if def.weapon!="":
        var w:=Rect2(box.end-Vector2.ONE*badge*.8,Vector2.ONE*badge)
        draw_rect(w,Color(0,0,0,.6));draw_texture_rect(sim.catalog.icon(def.weapon),w,false)
    if not def.skills.is_empty():
        var k:=Rect2(Vector2(box.end.x-badge*.8,box.position.y-badge*.2),Vector2.ONE*badge)
        draw_rect(k,Color(.25,.1,.4,.85));draw_texture_rect(sim.catalog.icon("skill_"+str(def.skills[0])),k,false)
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
        if mini:open_map.emit();accept_event();return
        var rect=transform_rect()
        if not rect.has_point(event.position) or sim.level("map_detail",int(sim.state.stage))<2:return
        var scale_factor=rect.size.x/float(sim.catalog.world.size[0])
        # Only drawn (found) spots are candidates; the nearest one within reach wins.
        var reach:=maxf(20.0,marker_side(scale_factor)*.75)
        var best: Array=[]
        for entry in spots(rect,scale_factor):
            var d: float=entry[2].distance_to(event.position)
            if d<reach and (best.is_empty() or d<best[2].distance_to(event.position)):best=entry
        if not best.is_empty():selected.emit(best[0],best[1]);accept_event()
