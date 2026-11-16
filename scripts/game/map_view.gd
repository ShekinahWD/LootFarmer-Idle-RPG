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
## Change 61: any drawn enemy marker was tapped (every Map Details rank; selected still needs rank 2).
signal marker_tapped(group: int,variant: int)
signal camp_selected(camp: int)
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
## Change 15 fix: the panel reconciler must not prune the player dot this view adds in _ready.
func _init() -> void:
    set_meta("own_children",true)
func _ready() -> void:
    plain_body=AtlasTexture.new();plain_body.atlas=load(PLAIN_BODY);plain_body.region=Rect2(0,0,24,24)
    player_dot=TextureRect.new()
    player_dot.texture=UiArt.cropped(STAR)
    player_dot.modulate=Color(.5,.9,1)
    player_dot.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    player_dot.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    player_dot.mouse_filter=Control.MOUSE_FILTER_IGNORE
    player_dot.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    # Every other map marker is drawn at the parent layer. Player is explicitly above it.
    # Keep this below management panels (layer 10) and confirmations (layer 20).
    player_dot.z_index=1
    var outline:=TextureRect.new()
    outline.texture=player_dot.texture;outline.modulate=Color.BLACK
    outline.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    outline.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    outline.mouse_filter=Control.MOUSE_FILTER_IGNORE
    outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outline.offset_left=-3;outline.offset_top=-3;outline.offset_right=3;outline.offset_bottom=3
    outline.show_behind_parent=true
    player_dot.add_child(outline)
    add_child(player_dot)
func _process(dt: float) -> void:
    refresh+=dt
    if sim==null:return
    if refresh<.15 and signature!="":return
    refresh=0
    var rect:=transform_rect()
    var side:=24.0 if mini else 20.0
    player_dot.size=Vector2.ONE*side
    player_dot.position=rect.position+sim.position_of(sim.state.player)*(rect.size.x/float(sim.catalog.world.size[0]))-Vector2.ONE*side*.5
    var next:="%s:%s:%s:%s:%s:%s:%s" % [size,sim.state.stage,sim.campaign.discovery_revision,sim.level("map_detail",int(sim.state.stage)),_bosses_alive(),sim.state.spawns,sim.campaign.gate_status()]
    if next!=signature:signature=next;queue_redraw()
    elif _final_drawn:queue_redraw()
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
                points.append([(center+(sim.campaign.spot(g,v)-center)*spread)*scale_factor,_size_factor(g)])
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
var _final_drawn:=false
func _draw() -> void:
    _final_drawn=false
    if sim==null:return
    var rect=transform_rect()
    var scale_factor=rect.size.x/float(sim.catalog.world.size[0])
    draw_rect(rect,Color(.06,.08,.1))
    draw_explored(self,sim,int(sim.state.stage),rect.position,scale_factor)
    for i in range(sim.campaign.stage().spawns.size()):
        var point=sim.campaign.stage().spawns[i];var pos=Vector2(point[0],point[1])
        if sim.campaign.camp_known(i) or sim.state.spawns.has(i):
            var side:=24.0
            draw_texture_rect(UiArt.cropped(CAMP),Rect2(rect.position+pos*scale_factor-Vector2.ONE*side*.5,Vector2.ONE*side),false,Color.WHITE if sim.state.spawns.has(i) else Color(.55,.55,.55))
    var rank=sim.level("map_detail",int(sim.state.stage))
    if rank>0:
        var side:=marker_side(scale_factor)
        for entry in spots(rect,scale_factor):
            _marker(entry[0],entry[1],entry[2],side,rank)
            if bool(sim.catalog.groups[entry[0]].get("final",false)):_final_drawn=true
## Change 24: explored cells as one rectangle per horizontal run of explored cells (from the stage's
## byte mask), the same covered area and colour as one rectangle per cell. Shared with camp_picker.
const EXPLORED_COLOR:=Color(.28,.4,.32)
static func draw_explored(canvas: CanvasItem,sim_ref,st: int,origin: Vector2,scale_factor: float) -> void:
    var mask: PackedByteArray=sim_ref.campaign.explored_mask(st)
    var columns: int=sim_ref.campaign.fog_columns(st)
    var side: float=sim_ref.campaign.fog_rules.cell_size*scale_factor
    for y in range(sim_ref.campaign.fog_rows(st)):
        var row:=y*columns
        var start:=-1
        for x in range(columns+1):
            var known: bool=x<columns and mask[row+x]!=0
            if known and start<0:start=x
            elif not known and start>=0:
                canvas.draw_rect(Rect2(origin+Vector2(start,y)*side,Vector2(x-start,1)*side),EXPLORED_COLOR)
                start=-1
## Marker size against a normal type's: bosses 1.25x; Change 83: the final boss FINAL_SCALE x a boss's.
const BOSS_SCALE:=1.25
const FINAL_SCALE:=1.4
const FINAL_GREEN:=Color(.45,1,.5)
const FINAL_GOLD:=Color(1,.84,.34)
func _size_factor(g: int) -> float:
    var d: Dictionary=sim.catalog.groups[g]
    return BOSS_SCALE*(FINAL_SCALE if bool(d.get("final",false)) else 1.0) if d.boss else 1.0
func _marker(g: int,v: int,pos: Vector2,side: float,rank: int) -> void:
    var boss: bool=sim.catalog.groups[g].boss
    var final: bool=bool(sim.catalog.groups[g].get("final",false))
    side*=_size_factor(g)
    var box:=Rect2(pos-Vector2.ONE*side*.5,Vector2.ONE*side)
    # Change 83: the Green Alien's final-boss treatment, the same wherever this view draws it (minimap, World map),
    # sealed, ready or unsealed: a soft pulsing green glow, a double green/gold border and a gold crown on top.
    if final:_final_glow(box)
    if rank==1:
        draw_texture_rect(STAR if boss else BADGE,box,false,FINAL_GREEN.lightened(.35) if final else Color.WHITE)
        if final:_final_frame(box)
        _gate_badge(g,box)
        return
    var def: Dictionary=sim.enemy_definition(g,v)
    var identity: String=str(sim.catalog.groups[g].body)
    draw_rect(box.grow(1),Color(0,0,0,.6))
    # The type's own portrait is its identity; a weapon-only spot (rank 3) shows it dimmed.
    var dim: bool=rank>=3 and def.body=="" and not boss
    draw_texture_rect(sim.catalog.icon(identity) if sim.catalog.items.has(identity) else plain_body,box,false,Color(.5,.5,.55) if dim else Color.WHITE)
    if final:_final_frame(box)
    elif boss:draw_rect(box.grow(1),Color(1,.84,.34),false,1.5)
    _gate_badge(g,box)
    if rank<3:return
    var badge:=maxf(7.0,side*.55)
    if def.weapon!="":
        var w:=Rect2(box.end-Vector2.ONE*badge*.8,Vector2.ONE*badge)
        draw_rect(w,Color(0,0,0,.65));draw_texture_rect(sim.catalog.icon(def.weapon),w,false)
    if not def.skills.is_empty():
        var k:=Rect2(Vector2(box.end.x-badge*.8,box.position.y-badge*.2),Vector2.ONE*badge)
        draw_rect(k,Color(.25,.1,.4,.85));draw_texture_rect(sim.catalog.icon("skill_"+str(def.skills[0])),k,false)
func _final_glow(box: Rect2) -> void:
    var pulse:=.5+.5*sin(Time.get_ticks_msec()/1000.0*3.0)
    var c:=box.get_center()
    for i in range(3):
        draw_circle(c,box.size.x*(.62+.12*i+.05*pulse),Color(FINAL_GREEN,.16-.045*i))
func _final_frame(box: Rect2) -> void:
    draw_rect(box.grow(2.5),Color(0,0,0,.75),false,2.0)
    draw_rect(box.grow(1),FINAL_GREEN,false,2.0)
    draw_rect(box.grow(3.5),FINAL_GOLD,false,1.5)
    # A small crown centred on the top edge.
    var w:=maxf(8.0,box.size.x*.5)
    var h:=w*.5
    var base:=Vector2(box.get_center().x,box.position.y-2.0)
    var pts:=PackedVector2Array([base+Vector2(-w*.5,0),base+Vector2(-w*.5,-h),base+Vector2(-w*.25,-h*.45),base+Vector2(0,-h*1.1),base+Vector2(w*.25,-h*.45),base+Vector2(w*.5,-h),base+Vector2(w*.5,0)])
    draw_colored_polygon(pts,FINAL_GOLD)
    pts.append(pts[0])
    draw_polyline(pts,Color(0,0,0,.85),1.0)
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
var press_at:=Vector2.INF
var press_finger:=-2
var dragged:=false

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenDrag and event.index==press_finger:
        dragged=dragged or event.position.distance_to(press_at)>12;return
    if event is InputEventMouseMotion and press_finger==-1:
        dragged=dragged or event.position.distance_to(press_at)>12;return
    var finger:=-2
    if event is InputEventScreenTouch:finger=event.index
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if press_finger>=0:return
        finger=-1
    else:return
    if event.pressed:
        press_at=event.position;press_finger=finger;dragged=false;return
    if finger!=press_finger or press_at==Vector2.INF:return
    var tap: bool=not dragged and event.position.distance_to(press_at)<=12
    press_at=Vector2.INF;press_finger=-2
    if tap:_choose_at(event.position)

func _choose_at(point: Vector2) -> void:
    if mini:open_map.emit();accept_event();return
    var rect:=transform_rect()
    var factor: float=rect.size.x/float(sim.catalog.world.size[0])
    var nearest:=-1
    var distance:=32.0
    for i in sim.state.spawns:
        var pos: Array=sim.campaign.stage().spawns[int(i)]
        var at:=rect.position+Vector2(pos[0],pos[1])*factor
        var d:=at.distance_to(point)
        if d<distance:nearest=int(i);distance=d
    if nearest>=0:
        if sim.campaign.travel_reason(int(sim.state.stage),nearest).is_empty():camp_selected.emit(nearest)
        accept_event();return
    if not rect.has_point(point) or sim.level("map_detail",int(sim.state.stage))<1:return
    var best:=marker_at(point)
    if best.is_empty():return
    marker_tapped.emit(best[0],best[1])
    if sim.level("map_detail",int(sim.state.stage))>=2:selected.emit(best[0],best[1])
    accept_event()
## The drawn marker under a local point ([group, variant, position]) or [].
func marker_at(point: Vector2) -> Array:
    var rect:=transform_rect()
    var factor: float=rect.size.x/float(sim.catalog.world.size[0])
    var reach:=maxf(20.0,marker_side(factor)*.75)
    var best: Array=[]
    for entry in spots(rect,factor):
        var d: float=entry[2].distance_to(point)
        # Change 83: the larger final-boss marker answers across its whole drawn size (at least 24 px away).
        var r:=maxf(24.0,reach*_size_factor(entry[0])/BOSS_SCALE) if bool(sim.catalog.groups[entry[0]].get("final",false)) else reach
        if d<r and (best.is_empty() or d<best[2].distance_to(point)):best=entry
    return best
## Change 61: local positions of the drawn markers of normal (non-boss) enemies, for the Guided
## enemy-marker lesson. Empty without Map Details: nothing hidden is ever pointed at.
func enemy_marker_points() -> Array:
    if sim==null or sim.level("map_detail",int(sim.state.stage))<1:return []
    var rect:=transform_rect()
    var factor: float=rect.size.x/float(sim.catalog.world.size[0])
    var points: Array=[]
    for entry in spots(rect,factor):
        if not sim.catalog.groups[entry[0]].boss:points.append(entry[2])
    return points
