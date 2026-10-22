extends Control
## Minimap and expanded map. Both read the one discovery store (playbook 117.9 / 124.12): explored
## cells, sighted camps and found encounter spots. Change 8: one marker per found spot (never per
## type), so neighbouring spots stay separate; nothing is drawn or tappable for a spot the player has
## not found, whatever the Map Details rank.
## Rank 1 generic spot markers, rank 2 the enemy's identity (its type portrait), rank 3 its loadout.
## Change 11: the minimap follows the same ranks (it used to draw generic dots only) and its markers
## are sized for a phone. Loadout reads at a glance: a weapon badge (bottom right) when the spot
## carries a weapon, a skill badge (top right) on skill spots, and a dimmed portrait on weapon-only
## spots, whose enemies do not wear (or drop) the outfit.
signal selected(group: int,variant: int)
signal open_map
@export var mini: bool=false
## Marker side as a share of the on-map distance between neighbouring spots, and its limits.
@export var marker_share:=0.42
@export var marker_min:=7.0
@export var marker_max:=26.0
## Minimap marker side limits (Change 11). When markers are wider than the real spacing of a type's
## spots, the spots are pushed apart around the type centre so they never overlap.
@export var mini_marker_min:=16.0
@export var mini_marker_max:=24.0
@export var mini_gap:=2.0
var sim
var refresh: float=0
var signature: String=""
const BADGE=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-248.png")
const STAR=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-211.png")
const CAMP=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-249.png")
const PLAIN_BODY="res://assets/PixelPlains/Characters 24x24/Basic character v2.png"
var plain_body: AtlasTexture
## The player marker is its own small node: walking moves it without redrawing the cells and markers.
var player_dot: TextureRect
func _ready() -> void:
    plain_body=AtlasTexture.new();plain_body.atlas=load(PLAIN_BODY);plain_body.region=Rect2(0,0,24,24)
    player_dot=TextureRect.new()
    player_dot.texture=STAR
    player_dot.modulate=Color(.5,.9,1)
    player_dot.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    player_dot.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    player_dot.mouse_filter=Control.MOUSE_FILTER_IGNORE
    player_dot.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(player_dot)
func _process(dt: float) -> void:
    refresh+=dt
    if sim==null:return
    if refresh<.15 and signature!="":return
    refresh=0
    var rect:=transform_rect()
    var side:=12.0 if mini else 10.0
    player_dot.size=Vector2.ONE*side
    player_dot.position=rect.position+sim.position_of(sim.state.player)*(rect.size.x/float(sim.catalog.world.size[0]))-Vector2.ONE*side*.5
    var next:="%s:%s:%s:%s:%s:%s:%s" % [size,sim.state.stage,sim.campaign.discovery_revision,sim.level("map_detail",int(sim.state.stage)),_bosses_alive(),sim.state.spawns,sim.campaign.gate_status()]
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
## Every found spot of the current stage as [group, variant, map position]. A type's spots spread
## around its centre when their markers would otherwise touch (see marker_spread).
func spots(rect: Rect2,scale_factor: float) -> Array:
    var result: Array=[]
    var spread:=marker_spread(scale_factor)
    for g in sim.campaign.stage().groups:
        var center:=Vector2(sim.catalog.groups[g].center[0],sim.catalog.groups[g].center[1])
        for v in sim.campaign.variants(g):
            if marker_visible(g,v):result.append([g,v,rect.position+(center+(sim.campaign.spot(g,v)-center)*spread)*scale_factor])
    return result
## On-map distance between neighbouring spots of one type.
func spot_spacing(scale_factor: float) -> float:
    return sim.campaign.spot_offset()*2.0*scale_factor
## Preferred marker side before fitting to this map.
func _wanted_side(scale_factor: float) -> float:
    if mini:return clampf(spot_spacing(scale_factor)*.92,mini_marker_min,mini_marker_max)
    return clampf(spot_spacing(scale_factor)*marker_share,marker_min,marker_max)
## Marker side: the preferred size, reduced if needed so the closest two spots of this map (of
## different types too, bosses drawn 1.25x) keep mini_gap between their markers. It is measured over
## every spot of the stage, found or not, so the size never hints at undiscovered spots.
var _fit_cache: Dictionary={}
func marker_side(scale_factor: float) -> float:
    var wanted:=_wanted_side(scale_factor)
    var key:="%d:%s:%s" % [int(sim.state.stage),scale_factor,mini]
    if not _fit_cache.has(key):
        var spread:=marker_spread(scale_factor)
        var points: Array=[]
        for g in sim.campaign.stage().groups:
            var center:=Vector2(sim.catalog.groups[g].center[0],sim.catalog.groups[g].center[1])
            for v in sim.campaign.variants(g):
                points.append([(center+(sim.campaign.spot(g,v)-center)*spread)*scale_factor,1.25 if sim.catalog.groups[g].boss else 1.0])
        var fit:=INF
        for i in range(points.size()):
            for j in range(i+1,points.size()):
                var d: Vector2=(points[i][0]-points[j][0]).abs()
                fit=minf(fit,(maxf(d.x,d.y)-mini_gap)*2.0/(points[i][1]+points[j][1]))
        _fit_cache[key]=fit
    return maxf(6.0,minf(wanted,float(_fit_cache[key])))
## How far a type's spots are pushed apart from its centre so neighbouring markers keep a gap.
func marker_spread(scale_factor: float) -> float:
    var spacing:=spot_spacing(scale_factor)
    if spacing<=0:return 1.0
    return maxf(1.0,(_wanted_side(scale_factor)+mini_gap)/spacing)
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
    for i in range(sim.campaign.stage().spawns.size()):
        var point=sim.campaign.stage().spawns[i];var pos=Vector2(point[0],point[1])
        if sim.campaign.camp_known(i):draw_texture_rect(CAMP,Rect2(rect.position+pos*scale_factor-Vector2.ONE*6,Vector2.ONE*12),false,Color.WHITE if sim.state.spawns.has(i) else Color(.55,.55,.55))
    var rank=sim.level("map_detail",int(sim.state.stage))
    if rank>0:
        var side:=marker_side(scale_factor)
        for entry in spots(rect,scale_factor):
            _marker(entry[0],entry[1],entry[2],side,rank)
func _marker(g: int,v: int,pos: Vector2,side: float,rank: int) -> void:
    var boss: bool=sim.catalog.groups[g].boss
    if boss:side*=1.25
    var box:=Rect2(pos-Vector2.ONE*side*.5,Vector2.ONE*side)
    if rank==1:
        draw_texture_rect(STAR if boss else BADGE,box,false)
        _gate_badge(g,box)
        return
    var def: Dictionary=sim.enemy_definition(g,v)
    var identity: String=str(sim.catalog.groups[g].body)
    draw_rect(box.grow(1),Color(0,0,0,.6))
    # The type's own portrait is its identity; a weapon-only spot (rank 3) shows it dimmed.
    var dim: bool=rank>=3 and def.body=="" and not boss
    draw_texture_rect(sim.catalog.icon(identity) if sim.catalog.items.has(identity) else plain_body,box,false,Color(.5,.5,.55) if dim else Color.WHITE)
    if boss:draw_rect(box.grow(1),Color(1,.84,.34),false,1.5)
    _gate_badge(g,box)
    if rank<3:return
    var badge:=maxf(7.0,side*.55)
    if def.weapon!="":
        var w:=Rect2(box.end-Vector2.ONE*badge*.8,Vector2.ONE*badge)
        draw_rect(w,Color(0,0,0,.65));draw_texture_rect(sim.catalog.icon(def.weapon),w,false)
    if not def.skills.is_empty():
        var k:=Rect2(Vector2(box.end.x-badge*.8,box.position.y-badge*.2),Vector2.ONE*badge)
        draw_rect(k,Color(.25,.1,.4,.85));draw_texture_rect(sim.catalog.icon("skill_"+str(def.skills[0])),k,false)
## Change 13: a discovered boss the next map still needs carries a small gold World banner on its
## marker's top-left corner (the World button's icon). Only drawn markers can carry it, so an
## undiscovered boss, its identity and its place stay hidden.
func _gate_badge(g: int,box: Rect2) -> void:
    if not sim.campaign.gate_required(g):return
    var side:=maxf(8.0,box.size.x*.5)
    var b:=Rect2(box.position-Vector2.ONE*side*.3,Vector2.ONE*side)
    draw_rect(b,Color(0,0,0,.65))
    draw_texture_rect(CAMP,b,false,GATE_COLOR)
const GATE_COLOR:=Color(1,.84,.34)
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
