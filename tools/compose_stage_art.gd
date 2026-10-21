extends SceneTree
## Change 8 environment pass: deterministic composition of every stage scene from owned PixelPlains
## art. Run: godot --headless --path . --script res://tools/compose_stage_art.gd -- [--stage=N]
##
## Keeps the authored Ground, Clearings, border Scenery, Camps and BossLandmarks (and every node id).
## Rebuilds, idempotently:
##   Regions  (TileMapLayer) darker ground patches that carry the forests
##   Paths    (TileMapLayer) one connected route network: camps -> encounter areas -> boss courts
##   Water    (TileMapLayer) ponds (frozen in Winter)
##   Details  (TileMapLayer) non-blocking decals: tufts, flowers, small rocks, mushrooms
##   Decor    (Node2D, y-sorted with actors) trees, boulders, pillars, lamps, signs, fenced fields
## Large props carry an editor-visible "Block" (StaticBody2D, no physics layers) whose shape is the
## trunk/base footprint; the simulation reads these shapes (campaign.obstacles()). Gameplay rules:
## nothing solid inside a camp, spot or boss keep-clear disk; every pair of solids leaves a gap an
## actor can walk through (no concave traps); a grid BFS proves every camp, actor home and boss court
## is reachable from the arrival camp, removing the nearest solid until it is.
## Everything placed here is ordinary scene content: move, delete or resize it in the editor.
const ART="res://assets/PixelPlains/"
## Actor clearance the simulation inflates every solid by, and the walkable gap kept between solids.
const CLEARANCE:=6.0
const GAP:=14.0
## Keep-clear radii around gameplay places (world units).
const KEEP_CAMP:=96.0
const KEEP_SPOT:=64.0
const KEEP_BOSS:=110.0
const EDGE:=28.0
## Stage looks: tree colour variants (sheet column groups 0..3), forest share, ponds, extras.
const LOOKS:={
    1:{"trees":[0,2,3],"birch":.3,"zones":.55,"ponds":1,"rocks":8,"pillars":3,"flowers":.012,"tufts":.02,"mushrooms":0.0,"field":""},
    2:{"trees":[0,1,2],"birch":.35,"zones":.6,"ponds":2,"rocks":12,"pillars":5,"flowers":.012,"tufts":.02,"mushrooms":0.0,"field":""},
    3:{"trees":[2,3,2,3,2,1],"birch":.1,"zones":.6,"ponds":2,"rocks":8,"pillars":0,"flowers":.03,"tufts":.03,"mushrooms":.004,"field":"flowers"},
    4:{"trees":[2,3,2,3,0,1],"birch":.15,"zones":.6,"ponds":3,"rocks":12,"pillars":0,"flowers":.03,"tufts":.03,"mushrooms":.004,"field":"flowers"},
    5:{"trees":[1,2,3,3,2,0],"birch":.2,"zones":.42,"ponds":1,"rocks":10,"pillars":4,"flowers":.012,"tufts":.025,"mushrooms":.012,"field":"pumpkins"},
    6:{"trees":[1,2,3,1,2,0],"birch":.25,"zones":.45,"ponds":2,"rocks":12,"pillars":6,"flowers":.012,"tufts":.025,"mushrooms":.012,"field":"sunflowers"},
    7:{"trees":[2,3,2,0,1],"birch":.15,"zones":.58,"ponds":2,"rocks":8,"pillars":0,"flowers":.04,"tufts":.025,"mushrooms":.008,"field":"flowers"},
    8:{"trees":[2,3,2,3,0,1],"birch":.15,"zones":.6,"ponds":3,"rocks":14,"pillars":2,"flowers":.04,"tufts":.025,"mushrooms":.008,"field":"flowers"}}
var data: Dictionary
var rng:=RandomNumberGenerator.new()
var scene: Node2D
var tiles: TileSet
var stage: Dictionary
var season:=""
var size:=Vector2.ZERO
var keep: Array=[]       # [Vector2 center, float radius]
var solids: Array=[]     # {"pos","r"} circles or {"pos","rect"} rects (world rect)
var road: Dictionary={}  # tile -> true
var blocked_tiles: Dictionary={} # tiles not available for decals/regions (paths, water, courts)
var serial:=0
var report: Array=[]

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    data=JSON.parse_string(FileAccess.get_file_as_string("res://data/game/catalog.json"))
    var only:=0
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--stage="):only=int(a.get_slice("=",1))
    for st in data.stages:
        if only==0 or int(st.id)==only:
            var error:=compose(st)
            if error!=OK:quit(error);return
    print("COMPOSE_REPORT ",JSON.stringify(report))
    quit(0)

# ---------------------------------------------------------------- setup

func compose(st: Dictionary) -> int:
    stage=st;season=str(st.season);size=Vector2(st.size[0],st.size[1])
    rng.seed=80000+int(st.id)*7919
    var path:="res://scenes/game/stages/stage_%d.tscn" % int(st.id)
    scene=load(path).instantiate()
    tiles=(scene.get_node("Ground") as TileMapLayer).tile_set
    keep.clear();solids.clear();road.clear();blocked_tiles.clear();serial=0
    for name_ in ["Regions","Water","Details","Decor"]:
        var old:=scene.get_node_or_null(name_)
        if old:scene.remove_child(old);old.free()
    _keep_zones()
    var regions:=_layer("Regions",1)
    var paths: TileMapLayer=scene.get_node("Paths")
    paths.clear()
    var water:=_layer("Water",scene.get_node("Clearings").get_index()+1)
    var details:=_layer("Details",water.get_index()+1)
    var decor:=Node2D.new();decor.name="Decor";decor.y_sort_enabled=true
    # Same absolute z as the Actors node: trees and actors sort by their feet.
    decor.z_as_relative=false;decor.z_index=1
    scene.add_child(decor);decor.owner=scene
    scene.move_child(decor,scene.get_node("Scenery").get_index()+1)
    # The stage scene joins the World y-sort so Decor sorts with Actors; every other layer gets an
    # absolute z below them, so y-sorting never reorders ground layers.
    scene.y_sort_enabled=true
    var z:=-12
    for name_ in ["Ground","Regions","Paths","Clearings","Water","Details","Scenery","BossLandmarks","Camps"]:
        var n: CanvasItem=scene.get_node_or_null(name_)
        if n:n.z_as_relative=false;n.z_index=z;z+=1
    _courts()
    _paths(paths)
    var look: Dictionary=LOOKS[int(st.id)]
    _ponds(water,int(look.ponds))
    var zones:=_zones(float(look.zones))
    _regions(regions,zones)
    if str(look.field)!="":_field(decor,str(look.field))
    _forests(decor,zones,look)
    _singles(decor,look)
    _rocks(decor,int(look.rocks),int(look.pillars))
    _camp_props(decor)
    _route_lamps(decor)
    # Ponds: a marker node per pond carries its solid (the water itself is tiles).
    for r in pond_rects:
        serial+=1
        var marker:=Sprite2D.new();marker.name="Pond%d" % serial;marker.position=r.get_center()
        decor.add_child(marker);marker.owner=scene
        for s in solids:
            if s.has("rect") and s.rect==r:s.node=marker
        var body:=StaticBody2D.new();body.name="Block";body.collision_layer=0;body.collision_mask=0
        var shape:=CollisionShape2D.new();shape.name="Shape";var box:=RectangleShape2D.new();box.size=r.size;shape.shape=box
        body.add_child(shape);marker.add_child(body);body.owner=scene;shape.owner=scene
    var removed:=_validate_reachability(decor)
    _details(details,look)
    var packed:=PackedScene.new()
    var error:=packed.pack(scene)
    if error==OK:error=ResourceSaver.save(packed,path)
    var count:=0
    for n in decor.get_children():count+=1
    report.append({"stage":int(st.id),"decor":count,"solids":solids.size(),"removed_for_reach":removed,"result":error})
    print("STAGE_COMPOSE ",st.id," decor=",count," solids=",solids.size()," removed=",removed," result=",error)
    scene.free()
    return error

func _layer(name_: String,index: int) -> TileMapLayer:
    var n:=TileMapLayer.new()
    n.name=name_;n.tile_set=tiles
    scene.add_child(n);n.owner=scene
    scene.move_child(n,index)
    return n

func _tile(n: TileMapLayer,p: Vector2i,source: int,atlas: Vector2i) -> void:
    var a: TileSetAtlasSource=tiles.get_source(source)
    if not a.has_tile(atlas):a.create_tile(atlas)
    n.set_cell(p,source,atlas)

## 3x3 autotile with inner corners (2x2 block: missing TL,TR,BL,BR diagonal).
func _paint(n: TileMapLayer,m: Dictionary,source: int,base: Vector2i,inner:=Vector2i(-1,-1),fill: Array=[]) -> void:
    for p in m:
        var x:=0 if not m.has(p+Vector2i.LEFT) else (2 if not m.has(p+Vector2i.RIGHT) else 1)
        var y:=0 if not m.has(p+Vector2i.UP) else (2 if not m.has(p+Vector2i.DOWN) else 1)
        var atlas:=base+Vector2i(x,y)
        if x==1 and y==1:
            if inner.x>=0:
                if not m.has(p+Vector2i(-1,-1)):atlas=inner
                elif not m.has(p+Vector2i(1,-1)):atlas=inner+Vector2i(1,0)
                elif not m.has(p+Vector2i(-1,1)):atlas=inner+Vector2i(0,1)
                elif not m.has(p+Vector2i(1,1)):atlas=inner+Vector2i(1,1)
            if atlas==base+Vector2i(1,1) and not fill.is_empty() and rng.randf()<.18:atlas=fill[rng.randi_range(0,fill.size()-1)]
        _tile(n,p,source,atlas)

## Removes cells that would need a 1-tile-wide edge (the autotile has no such pieces).
func _clean(m: Dictionary) -> void:
    var changed:=true
    while changed:
        changed=false
        for p in m.keys():
            var h:=m.has(p+Vector2i.LEFT) or m.has(p+Vector2i.RIGHT)
            var v:=m.has(p+Vector2i.UP) or m.has(p+Vector2i.DOWN)
            var thin:=(not m.has(p+Vector2i.LEFT) and not m.has(p+Vector2i.RIGHT)) or (not m.has(p+Vector2i.UP) and not m.has(p+Vector2i.DOWN))
            # A cell with neighbours only on opposite diagonals also has no piece.
            if thin or not h or not v:
                m.erase(p);changed=true

# ---------------------------------------------------------------- gameplay places

func _spot(g: int,v: int) -> Vector2:
    var d: Dictionary=data.groups[g]
    var pos:=Vector2(d.center[0],d.center[1])
    if not d.boss:pos+=Vector2(-100.0 if v%2==0 else 100.0,-100.0 if v<2 else 100.0)
    return pos

func _variants(g: int) -> Array:
    if data.groups[g].boss:return [2]
    return [0,1,2,3] if not data.groups[g].skills.is_empty() else [0,1,2]

## Actor homes for up to six actors per spot (simulation.spawn_home).
func _homes(g: int,v: int) -> Array:
    var out: Array=[]
    for i in range(6 if not data.groups[g].boss else 1):out.append(_spot(g,v)+Vector2((i%3-1)*24,(i/3)*26))
    return out

func _keep_zones() -> void:
    for camp in stage.spawns:keep.append([Vector2(camp[0],camp[1]),KEEP_CAMP])
    for g in stage.groups:
        for v in _variants(g):
            keep.append([_spot(g,v)+Vector2(0,13),KEEP_BOSS if data.groups[g].boss else KEEP_SPOT])

## Camp courts become dirt plazas joined to the route network; boss courts dark ground. The Change 6
## court tiles (a mis-indexed snow block that drew as stripes) are replaced. Winter camps also get
## the Winter sheet's fountain, bench and marker (the builder had used Spring sheet coordinates).
func _courts() -> void:
    var courts: TileMapLayer=scene.get_node("Clearings")
    courts.clear()
    var camp_mask: Dictionary={}
    for camp in stage.spawns:
        var c:=Vector2i(Vector2(camp[0],camp[1])/16.0)
        for y in range(c.y-2,c.y+3):
            for x in range(c.x-3,c.x+4):camp_mask[Vector2i(x,y)]=true
    _paint(courts,camp_mask,0,Vector2i(20,6),Vector2i(18,7))
    var boss_mask: Dictionary={}
    for g in stage.groups:
        if not data.groups[g].boss:continue
        var c:=Vector2i(Vector2(data.groups[g].center[0],data.groups[g].center[1])/16.0)
        for y in range(c.y-4,c.y+5):
            for x in range(c.x-5,c.x+6):
                if absi(x-c.x)+absi(y-c.y)<=8:boss_mask[Vector2i(x,y)]=true
    _clean(boss_mask)
    _paint(courts,boss_mask,0,Vector2i(20,9),Vector2i(18,10),[Vector2i(21,5),Vector2i(22,5),Vector2i(23,5)])
    for p in courts.get_used_cells():blocked_tiles[p]=true
    for p in camp_mask:road[p]=true
    if season.begins_with("Winter"):
        for camp in scene.get_node("Camps").get_children():
            (camp.get_node("Fountain") as Sprite2D).region_rect=Rect2(304,374,48,60)
            (camp.get_node("Bench") as Sprite2D).region_rect=Rect2(225,107,47,37)
            (camp.get_node("Selected") as Sprite2D).region_rect=Rect2(160,373,16,30)

func _kept(pos: Vector2,margin: float) -> bool:
    if pos.x<EDGE+margin or pos.y<EDGE+margin or pos.x>size.x-EDGE-margin or pos.y>size.y-EDGE-margin:return true
    for k in keep:
        if pos.distance_to(k[0])<float(k[1])+margin:return true
    return false

func _near_road(pos: Vector2,px: float) -> bool:
    var t:=Vector2i(pos/16.0)
    var r:=int(ceil(px/16.0))
    for y in range(t.y-r,t.y+r+1):
        for x in range(t.x-r,t.x+r+1):
            if road.has(Vector2i(x,y)) and (Vector2(x,y)*16+Vector2(8,8)).distance_to(pos)<px+8:return true
    return false

# ---------------------------------------------------------------- paths

## Minimum spanning tree over camps, encounter-type centres and boss courts, drawn as 3-tile L routes.
func _paths(paths: TileMapLayer) -> void:
    var nodes: Array=[]
    for camp in stage.spawns:nodes.append(Vector2(camp[0],camp[1]))
    for g in stage.groups:nodes.append(Vector2(data.groups[g].center[0],data.groups[g].center[1]))
    var linked: Array=[0]
    var edges: Array=[]
    route_bends.clear()
    while linked.size()<nodes.size():
        var best:=[-1,-1,INF]
        for a in linked:
            for b in range(nodes.size()):
                if linked.has(b):continue
                var d: float=nodes[a].distance_to(nodes[b])
                if d<best[2]:best=[a,b,d]
        linked.append(best[1]);edges.append([best[0],best[1]])
    for e in edges:
        var a: Vector2=nodes[e[0]];var b: Vector2=nodes[e[1]]
        var ta:=Vector2i(a/16.0);var tb:=Vector2i(b/16.0)
        # Bend at the end that keeps the route off the larger keep-clear disk.
        var corner:=Vector2i(tb.x,ta.y) if rng.randf()<.5 else Vector2i(ta.x,tb.y)
        _strip(ta,corner);_strip(corner,tb)
        if corner!=ta and corner!=tb:route_bends.append(Vector2(corner)*16+Vector2(8,8))
    var edge:=Vector2i(size/16.0)
    for p in road.keys():
        if p.x<1 or p.y<1 or p.x>=edge.x-1 or p.y>=edge.y-1:road.erase(p)
    _clean(road)
    _paint(paths,road,0,Vector2i(20,6),Vector2i(18,7),[Vector2i(21,0),Vector2i(22,0),Vector2i(23,0),Vector2i(24,0),Vector2i(25,0)])
    for p in road:blocked_tiles[p]=true

var route_bends: Array=[]
## A lamp on the outside of each route bend: a rhythm of small landmarks along the paths.
func _route_lamps(decor: Node) -> void:
    var winter:=season.begins_with("Winter")
    var lamp:=Rect2(482,99,12,45) if winter else Rect2(354,3,12,45)
    for bend in route_bends:
        for offset in [Vector2(34,-30),Vector2(-34,-30),Vector2(34,40),Vector2(-34,40)]:
            var p: Vector2=bend+offset
            if _kept(p,0) or _near_road(p,22) or blocked_tiles.has(Vector2i(p/16.0)) or not _separated({"pos":p,"r":4.0}):continue
            _block(_sprite(decor,ART+season+"Props.png",lamp,p,2),4.0)
            break

func _strip(a: Vector2i,b: Vector2i) -> void:
    var step:=Vector2i(signi(b.x-a.x),signi(b.y-a.y))
    var p:=a
    while true:
        for dy in range(-1,2):
            for dx in range(-1,2):road[p+Vector2i(dx,dy)]=true
        if p==b:break
        p+=step

# ---------------------------------------------------------------- zones, regions and water

## Free-space anchors on a jittered grid: away from keep-clear disks, roads and the map edge.
func _zones(share: float) -> Array:
    var out: Array=[]
    var spacing:=135.0
    var y:=spacing*.5
    while y<size.y:
        var x:=spacing*.5
        while x<size.x:
            var p:=Vector2(x,y)+Vector2(rng.randf_range(-40,40),rng.randf_range(-40,40))
            if not _kept(p,24) and not _near_road(p,32) and rng.randf()<share:out.append(p)
            x+=spacing
        y+=spacing
    return out

func _regions(layer: TileMapLayer,zones: Array) -> void:
    var m: Dictionary={}
    for z in zones:
        var c:=Vector2i(z/16.0)
        for i in range(rng.randi_range(2,3)):
            var w:=rng.randi_range(5,9);var h:=rng.randi_range(4,8)
            var o:=c+Vector2i(rng.randi_range(-4,1),rng.randi_range(-4,1))
            for y in range(o.y,o.y+h):
                for x in range(o.x,o.x+w):m[Vector2i(x,y)]=true
    var edge:=Vector2i(size/16.0)
    for p in m.keys():
        var center:=Vector2(p)*16+Vector2(8,8)
        if p.x<1 or p.y<1 or p.x>=edge.x-1 or p.y>=edge.y-1 or blocked_tiles.has(p) or _near_road(center,24) or _kept(center,-26):m.erase(p)
    _clean(m)
    _paint(layer,m,0,Vector2i(20,9),Vector2i(18,10),[Vector2i(21,5),Vector2i(22,5),Vector2i(23,5),Vector2i(24,5),Vector2i(25,5)])
    for p in m:blocked_tiles[p]=true # no decals on the darker ground (it reads cleaner)

var shores: Array=[]
var pond_rects: Array=[]
func _ponds(layer: TileMapLayer,count: int) -> void:
    shores.clear();pond_rects.clear()
    var base:=Vector2i(26,8) if season.begins_with("Winter") else Vector2i(30,8)
    var placed:=0
    for attempt in range(300):
        if placed>=count:break
        var w:=rng.randi_range(6,10);var h:=rng.randi_range(4,6)
        var o:=Vector2i(rng.randi_range(2,int(size.x/16)-w-2),rng.randi_range(2,int(size.y/16)-h-2))
        var rect:=Rect2(Vector2(o)*16,Vector2(w,h)*16)
        var ok:=true
        for corner in [rect.position,rect.end,Vector2(rect.position.x,rect.end.y),Vector2(rect.end.x,rect.position.y),rect.get_center()]:
            if _kept(corner,30) or _near_road(corner,36):ok=false
        for y in range(o.y-2,o.y+h+2):
            for x in range(o.x-2,o.x+w+2):
                if blocked_tiles.has(Vector2i(x,y)):ok=false
        var solid:={"pos":rect.get_center(),"rect":rect.grow(-4)}
        if not ok or not _separated(solid):continue
        var m: Dictionary={}
        for y in range(o.y,o.y+h):
            for x in range(o.x,o.x+w):m[Vector2i(x,y)]=true;blocked_tiles[Vector2i(x,y)]=true
        _paint(layer,m,2,base)
        pond_rects.append(solid.rect)
        solids.append(solid)
        shores.append(Rect2i(o-Vector2i.ONE,Vector2i(w,h)+Vector2i(2,2)))
        placed+=1

# ---------------------------------------------------------------- props

## Tree art: [rect, foot offset from the sprite bottom, trunk radius]. Variant column groups are
## 144 px apart on every season's Trees & Bushes sheet; "birch" rows use the pale trunks.
func _tree(variant: int,kind: int,birch: bool) -> Array:
    var ox:=144*variant
    var dy:=128 if birch else 0
    match kind:
        0:return [Rect2(56+ox,0+dy,31,43),5,6.0]
        1:return [Rect2(98+ox,0+dy,44,43),5,7.0]
        2:return [Rect2(12+ox,53+dy,24,54),5,6.0]
        3:return [Rect2(60+ox,65+dy,23,42),5,6.0]
        4:return [Rect2(98+ox,64+dy,44,43),5,7.0]
    return [Rect2(17+64*variant,320 if birch else 240,46,75),6,9.0]

func _separated(s: Dictionary) -> bool:
    for o in solids:
        if _solid_gap(s,o)<GAP+CLEARANCE*2:return false
    return true

func _solid_gap(a: Dictionary,b: Dictionary) -> float:
    if a.has("r") and b.has("r"):return a.pos.distance_to(b.pos)-float(a.r)-float(b.r)
    if a.has("rect") and b.has("rect"):
        var ra: Rect2=a.rect;var rb: Rect2=b.rect
        var dx:=maxf(0,maxf(ra.position.x-rb.end.x,rb.position.x-ra.end.x))
        var dy:=maxf(0,maxf(ra.position.y-rb.end.y,rb.position.y-ra.end.y))
        return Vector2(dx,dy).length()
    var c: Dictionary=a if a.has("r") else b
    var r: Rect2=(b if a.has("r") else a).rect
    var q:=Vector2(clampf(c.pos.x,r.position.x,r.end.x),clampf(c.pos.y,r.position.y,r.end.y))
    return q.distance_to(c.pos)-float(c.r)

func _sprite(parent: Node,texture_path: String,region: Rect2,foot: Vector2,foot_offset: float,flip:=false) -> Sprite2D:
    serial+=1
    var s:=Sprite2D.new()
    s.name="Decor%d" % serial
    s.texture=load(texture_path)
    s.region_enabled=true
    s.region_rect=region
    s.position=foot.round()
    s.offset=Vector2(0,-region.size.y*.5+foot_offset)
    s.flip_h=flip
    parent.add_child(s);s.owner=scene
    return s

## The trunk/base footprint as an editor-visible, physics-free StaticBody2D the simulation reads.
func _block(sprite: Sprite2D,radius: float,rect:=Rect2()) -> void:
    var body:=StaticBody2D.new()
    body.name="Block";body.collision_layer=0;body.collision_mask=0
    var shape:=CollisionShape2D.new()
    shape.name="Shape"
    if rect.size==Vector2.ZERO:
        var circle:=CircleShape2D.new();circle.radius=radius;shape.shape=circle
        solids.append({"pos":sprite.position,"r":radius,"node":sprite})
    else:
        var box:=RectangleShape2D.new();box.size=rect.size;shape.shape=box
        shape.position=rect.get_center()-sprite.position
        solids.append({"pos":rect.get_center(),"rect":rect,"node":sprite})
    body.add_child(shape)
    sprite.add_child(body);body.owner=scene;shape.owner=scene

func _try_tree(decor: Node,pos: Vector2,look: Dictionary,big_share:=.18) -> bool:
    if _kept(pos,10) or _near_road(pos,30):return false
    var t:=Vector2i(pos/16.0)
    if blocked_tiles.has(t) and not _on_region(t):return false
    var variants: Array=look.trees
    var kind:=5 if rng.randf()<big_share else rng.randi_range(0,4)
    var art:=_tree(int(variants[rng.randi_range(0,variants.size()-1)]),kind,rng.randf()<float(look.birch))
    var solid:={"pos":pos,"r":float(art[2])}
    if not _separated(solid):return false
    var s:=_sprite(decor,ART+season+"Basic Tiles 4 (Trees & Bushes).png",art[0],pos,float(art[1]),rng.randf()<.5)
    _block(s,float(art[2]))
    return true

var region_tiles: Dictionary={}
func _on_region(t: Vector2i) -> bool:
    return (scene.get_node("Regions") as TileMapLayer).get_cell_source_id(t)>=0

func _forests(decor: Node,zones: Array,look: Dictionary) -> void:
    for z in zones:
        # A loose grove: trunks at least GAP apart, canopies overlapping.
        for i in range(rng.randi_range(12,18)):
            var p: Vector2=z+Vector2(rng.randf_range(-84,84),rng.randf_range(-72,72))
            _try_tree(decor,p,look,.25)

func _singles(decor: Node,look: Dictionary) -> void:
    # Sparse lone trees break up open ground; a denser ring lines the map edge.
    var n:=int(size.x*size.y/52000.0)
    for i in range(n*6):
        _try_tree(decor,Vector2(rng.randf_range(0,size.x),rng.randf_range(0,size.y)),look,.1)
    var step:=56.0
    for side in range(4):
        var length:=size.x if side<2 else size.y
        var t:=step*.5
        while t<length:
            var inset:=rng.randf_range(34,52)
            var p:=Vector2(t,inset) if side==0 else (Vector2(t,size.y-inset) if side==1 else (Vector2(inset,t) if side==2 else Vector2(size.x-inset,t)))
            if rng.randf()<.7:_try_tree(decor,p,look,.3)
            t+=step+rng.randf_range(-10,10)

func _rocks(decor: Node,count: int,pillars: int) -> void:
    var sheet:=ART+season+"Basic Tiles 1.png"
    var props:=ART+season+"Props.png"
    var winter:=season.begins_with("Winter")
    var pillar_art: Array=[Rect2(5,180,23,25),Rect2(39,176,23,32),Rect2(68,176,23,30),Rect2(104,177,18,29)] if winter else [Rect2(37,150,23,23),Rect2(71,144,23,32),Rect2(100,144,23,30),Rect2(136,147,18,27)]
    for kind in [["rock",count],["pillar",pillars]]:
        var placed:=0
        for attempt in range(int(kind[1])*25):
            if placed>=int(kind[1]):break
            var p:=Vector2(rng.randf_range(40,size.x-40),rng.randf_range(40,size.y-40))
            if _kept(p,14) or _near_road(p,26) or blocked_tiles.has(Vector2i(p/16.0)):continue
            var art: Rect2;var r:=8.0;var path:=sheet
            if kind[0]=="rock":
                var big:=rng.randf()<.45
                art=Rect2(144,128,32,24) if big else Rect2(64,128,22,20)
                r=10.0 if big else 7.0
            else:
                art=pillar_art[rng.randi_range(0,3)];path=props;r=8.0
            if not _separated({"pos":p,"r":r}):continue
            _block(_sprite(decor,path,art,p,3,rng.randf()<.5),r)
            placed+=1

## A fenced crop field (Autumn pumpkins or sunflowers, Summer/Spring flowers) as one solid block.
func _field(decor: Node,crop: String) -> void:
    var winter:=season.begins_with("Winter")
    var props:=ART+season+"Props.png"
    for attempt in range(400):
        var w:=rng.randi_range(5,7);var h:=rng.randi_range(3,4)
        var rect:=Rect2(Vector2(rng.randf_range(60,size.x-60-w*16),rng.randf_range(60,size.y-60-h*16)).snapped(Vector2(16,16)),Vector2(w,h)*16)
        var ok:=true
        for y in range(int(rect.position.y),int(rect.end.y)+17,16):
            for x in range(int(rect.position.x),int(rect.end.x)+17,16):
                var q:=Vector2(x,y)
                if _kept(q,4) or _near_road(q,12) or (blocked_tiles.has(Vector2i(q/16.0)) and not _on_region(Vector2i(q/16.0))):ok=false
        var solid:={"pos":rect.get_center(),"rect":rect.grow(2)}
        if not ok or not _separated(solid):continue
        # Fence: horizontal runs top and bottom, posts down the sides.
        var hpiece:=Rect2(433,288,30,13) if winter else Rect2(305,192,30,13)
        var vpiece:=Rect2(417,240,6,45) if winter else Rect2(289,144,6,45)
        var x:=rect.position.x+16
        while x<rect.end.x:
            _sprite(decor,props,hpiece,Vector2(x,rect.position.y+6),2)
            _sprite(decor,props,hpiece,Vector2(x,rect.end.y+6),2)
            x+=32
        var y:=rect.position.y+45
        while y<=rect.end.y+6:
            _sprite(decor,props,vpiece,Vector2(rect.position.x,y),2)
            _sprite(decor,props,vpiece,Vector2(rect.end.x,y),2)
            y+=45
        # Crops on a grid inside.
        var cy:=rect.position.y+22
        while cy<rect.end.y:
            var cx:=rect.position.x+14
            while cx<rect.end.x-6:
                match crop:
                    "pumpkins":_sprite(decor,ART+"Fall/Pumpkins.png",Rect2(1+16*rng.randi_range(0,3),1,14,15),Vector2(cx,cy),1)
                    "sunflowers":_sprite(decor,ART+"Fall/Sunflowers.png",[Rect2(8,2,17,30),Rect2(40,2,17,30)][rng.randi_range(0,1)],Vector2(cx,cy),2)
                    _:_sprite(decor,ART+season+"Basic Tiles 1.png",Rect2(Vector2(12+rng.randi_range(0,3),8+rng.randi_range(0,2))*16,Vector2(16,16)),Vector2(cx,cy),3)
                cx+=18
            cy+=18
        var anchor:=_sprite(decor,props,Rect2(128,151,16,18) if winter else Rect2(0,55,16,18),rect.position+Vector2(-12,rect.size.y*.5),2)
        anchor.name="FieldSign%d" % serial
        _block(anchor,0,rect.grow(2))
        for y2 in range(int(rect.position.y/16)-1,int(rect.end.y/16)+2):
            for x2 in range(int(rect.position.x/16)-1,int(rect.end.x/16)+2):blocked_tiles[Vector2i(x2,y2)]=true
        return

## Lamps flank each camp court and a sign stands on its route side: readable landmarks.
func _camp_props(decor: Node) -> void:
    var winter:=season.begins_with("Winter")
    var props:=ART+season+"Props.png"
    var lamp:=Rect2(482,99,12,45) if winter else Rect2(354,3,12,45)
    for camp in stage.spawns:
        var c:=Vector2(camp[0],camp[1])
        for side in [-1,1]:
            var p:=c+Vector2(66*side,26)
            if not _separated({"pos":p,"r":4.0}):continue
            var s:=_sprite(decor,props,lamp,p,2)
            _block(s,4.0)

# ---------------------------------------------------------------- details

func _details(layer: TileMapLayer,look: Dictionary) -> void:
    var edge:=Vector2i(size/16.0)
    var flowers: Array=[];var mushrooms: Array=[]
    for r in range(8,11):
        for c in range(12,16):flowers.append(Vector2i(c,r))
    for r in range(11,18):
        for c in range(7,12):mushrooms.append(Vector2i(c,r))
    var tufts: Array=[Vector2i(3,10),Vector2i(4,10),Vector2i(5,10),Vector2i(6,10),Vector2i(9,10)]
    var pebbles: Array=[Vector2i(6,8),Vector2i(7,8),Vector2i(10,8)]
    var regions: TileMapLayer=scene.get_node("Regions")
    # Reeds and pebbles along pond shores.
    for r in shores:
        for y in range(r.position.y,r.end.y):
            for x in range(r.position.x,r.end.x):
                var t:=Vector2i(x,y)
                if (x==r.position.x or y==r.position.y or x==r.end.x-1 or y==r.end.y-1) and not road.has(t) and regions.get_cell_source_id(t)<0 and rng.randf()<.45:
                    _tile(layer,t,0,(tufts+pebbles)[rng.randi_range(0,tufts.size()+pebbles.size()-1)])
    for y in range(1,edge.y-1):
        for x in range(1,edge.x-1):
            var t:=Vector2i(x,y)
            if blocked_tiles.has(t) or regions.get_cell_source_id(t)>=0:continue
            var roll:=rng.randf()
            # Clustered rhythm: flowers bunch where a low-frequency wave is high.
            var wave:=.5+.5*sin(x*.31+y*.17)*cos(y*.23-x*.11)
            if roll<float(look.flowers)*wave*2.0:_tile(layer,t,0,flowers[rng.randi_range(0,flowers.size()-1)])
            elif roll<float(look.flowers)*2.0+float(look.tufts):_tile(layer,t,0,tufts[rng.randi_range(0,tufts.size()-1)])
            elif roll<float(look.flowers)*2.0+float(look.tufts)+.004:_tile(layer,t,0,pebbles[rng.randi_range(0,pebbles.size()-1)])
            elif roll<float(look.flowers)*2.0+float(look.tufts)+.004+float(look.mushrooms):_tile(layer,t,0,mushrooms[rng.randi_range(0,mushrooms.size()-1)])

# ---------------------------------------------------------------- validation

## Grid BFS (8 px) from the arrival camp with solids inflated by the actor clearance. Every camp, every
## actor home and every boss home must be reachable; otherwise the solid nearest the first unreachable
## target is removed and the search repeats. No actor home may sit inside a solid.
const CELL:=8.0
var blocked_grid: Dictionary={}

func _raster(s: Dictionary,amount: int) -> void:
    var box: Rect2=(Rect2(s.pos-Vector2.ONE*float(s.r),Vector2.ONE*float(s.r)*2) if s.has("r") else s.rect).grow(CLEARANCE+CELL)
    for y in range(int(box.position.y/CELL),int(box.end.y/CELL)+1):
        for x in range(int(box.position.x/CELL),int(box.end.x/CELL)+1):
            var c:=Vector2i(x,y)
            if _solid_gap({"pos":Vector2(c)*CELL+Vector2.ONE*CELL*.5,"r":0.0},s)<CLEARANCE:
                blocked_grid[c]=int(blocked_grid.get(c,0))+amount
                if int(blocked_grid[c])<=0:blocked_grid.erase(c)

func _validate_reachability(decor: Node) -> int:
    blocked_grid.clear()
    for s in solids:_raster(s,1)
    var removed:=0
    var targets: Array=[]
    for camp in stage.spawns:targets.append(Vector2(camp[0],camp[1]))
    for g in stage.groups:
        for v in _variants(g):targets.append_array(_homes(g,v))
    for i in range(200):
        var bad:=_first_unreachable(targets)
        if bad==Vector2.INF:return removed
        var best:=-1;var dist:=INF
        for k in range(solids.size()):
            var d:=_solid_gap({"pos":bad,"r":0.0},solids[k])
            if d<dist:dist=d;best=k
        if best<0:return removed
        _raster(solids[best],-1)
        var node: Node=solids[best].node
        if is_instance_valid(node):node.get_parent().remove_child(node);node.free()
        solids.remove_at(best)
        removed+=1
    push_error("Stage %d: reachability not resolved" % int(stage.id))
    return removed

func _first_unreachable(targets: Array) -> Vector2:
    var w:=int(size.x/CELL);var h:=int(size.y/CELL)
    var start:=Vector2i(Vector2(stage.spawns[0][0],stage.spawns[0][1])/CELL)
    var seen: Dictionary={start:true}
    var queue: Array=[start]
    var head:=0
    while head<queue.size():
        var c: Vector2i=queue[head];head+=1
        for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
            var n: Vector2i=c+d
            if n.x<1 or n.y<3 or n.x>=w-1 or n.y>=h-1 or seen.has(n) or blocked_grid.has(n):continue
            seen[n]=true;queue.append(n)
    for t in targets:
        var tc:=Vector2i(t/CELL)
        if blocked_grid.has(tc) or not seen.has(tc):return t
    return Vector2.INF
