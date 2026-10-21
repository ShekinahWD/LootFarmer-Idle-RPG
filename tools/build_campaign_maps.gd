extends SceneTree
## Deterministic authoring utility. Bakes editable TileMapLayers and props;
## never runs during gameplay. Destructive rebuild requires -- --rebuild-campaign-layout. Existing scenes contain hand-authored landmarks.
var ROOT="res://assets/PixelPlains/"
var world: Node2D
var tiles:=TileSet.new()
var sources: Array=[]
var serial:=0
var rng:=RandomNumberGenerator.new()
var theme=preload("res://resources/game/theme.tres")
func _initialize() -> void:
    call_deferred("build")
func add(node: Node,parent: Node) -> void:
    parent.add_child(node)
    node.owner=world
func layer(name_: String) -> TileMapLayer:
    var n:=TileMapLayer.new()
    n.name=name_
    n.tile_set=tiles
    add(n,world)
    return n
func tile(n: TileMapLayer,p: Vector2i,source: int,atlas: Vector2i) -> void:
    var a: TileSetAtlasSource=sources[source]
    if not a.has_tile(atlas):
        a.create_tile(atlas)
    n.set_cell(p,source,atlas)
func rect_mask(r: Rect2i) -> Dictionary:
    var m: Dictionary={}
    for y in range(r.position.y,r.end.y):
        for x in range(r.position.x,r.end.x):m[Vector2i(x,y)]=true
    if r.size.x>=6 and r.size.y>=6:
        for corner in [r.position,Vector2i(r.end.x-1,r.position.y),Vector2i(r.position.x,r.end.y-1),r.end-Vector2i.ONE]:m.erase(corner)
    return m
func paint(n: TileMapLayer,m: Dictionary,source: int,base: Vector2i) -> void:
    for p in m:
        var x:=0 if not m.has(p+Vector2i.LEFT) else (2 if not m.has(p+Vector2i.RIGHT) else 1)
        var y:=0 if not m.has(p+Vector2i.UP) else (2 if not m.has(p+Vector2i.DOWN) else 1)
        var atlas:=base+Vector2i(x,y)
        if x==1 and y==1:
            if source==0 and base==Vector2i(20,6) and rng.randf()<.2:
                atlas=Vector2i(rng.randi_range(21,27),0)
            elif source==0 and base==Vector2i(25,9) and rng.randf()<.12:
                atlas=Vector2i(rng.randi_range(21,27),5)
            elif source==1 and rng.randf()<.22:
                atlas=Vector2i(rng.randi_range(35,38),16)
            elif source==2 and rng.randf()<.12:
                atlas=Vector2i(rng.randi_range(18,20),9)
        tile(n,p,source,atlas)
func sprite(parent: Node,path: String,region: Rect2,pos: Vector2,name_: String="") -> Sprite2D:
    var n:=Sprite2D.new()
    serial+=1
    n.name=name_ if name_!="" else "Prop%d" % serial
    n.texture=load(ROOT+path)
    n.region_enabled=true
    n.region_rect=region
    n.position=pos
    add(n,parent)
    return n
func label(parent: Node,text: String,pos: Vector2,width: float,size_: int,name_: String="Label") -> Label:
    var n:=Label.new()
    n.name=name_
    n.text=text
    n.position=pos
    n.size=Vector2(width,32)
    n.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    n.theme=theme
    n.add_theme_font_size_override("font_size",size_)
    n.add_theme_constant_override("outline_size",2)
    n.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    n.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add(n,parent)
    return n
func build() -> void:
    if not OS.get_cmdline_user_args().has("--rebuild-campaign-layout"):
        push_warning("Campaign scenes are authored assets. Pass --rebuild-campaign-layout only to discard scene edits, including boss landmarks.")
        quit(0)
        return
    var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/game/catalog.json"))
    DirAccess.make_dir_recursive_absolute("res://scenes/game/stages")
    for stage in data.stages:
        rng.seed=43021+int(stage.id)
        ROOT="res://assets/PixelPlains/"+stage.season
        world=Node2D.new()
        world.name="Stage%d" % stage.id
        world.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
        tiles=TileSet.new();tiles.tile_size=Vector2i(16,16);sources=[]
        for file in ["Basic Tiles 1.png","Basic Tiles 2.png","Basic Tiles 3 (Water).png"]:
            var a=TileSetAtlasSource.new()
            a.texture=load(ROOT+file);a.texture_region_size=Vector2i(16,16)
            tiles.add_source(a,sources.size());sources.append(a)
        var edge=int(stage.size[0]/16)
        var grass=layer("Ground")
        for y in range(-18,edge+18):
            for x in range(-18,edge+18):
                tile(grass,Vector2i(x,y),0,Vector2i(rng.randi_range(21,27),3) if rng.randf()<.07 else Vector2i(26,7))
        var paths=layer("Paths")
        var road={}
        # A loop joins the two columns; each clearing has a short approach spur.
        for y in range(8,edge-5):
            for x in [int(edge*.3),int(edge*.7)]:
                for dx in range(-1,2):road[Vector2i(x+dx,y)]=true
        for cy in [10,edge-7,int(edge*.5)]:
            for x in range(int(edge*.12),int(edge*.89)):
                for dy in range(-1,2):road[Vector2i(x,cy+dy)]=true
        for point in stage.spawns:
            var at=Vector2i(int(point[0]/16),int(point[1]/16))
            for x in range(mini(at.x,int(edge*.5)),maxi(at.x,int(edge*.5))+1):
                for dy in range(-1,2):road[Vector2i(x,at.y+dy)]=true
        paint(paths,road,0,Vector2i(20,6))
        var courts=layer("Clearings")
        for g in stage.groups:
            var def=data.groups[g]
            var pos=Vector2i(int(def.center[0]/16),int(def.center[1]/16))
            if def.boss:paint(courts,rect_mask(Rect2i(pos-Vector2i(5,4),Vector2i(11,9))),1,Vector2i(25,12))
        var decor=Node2D.new();decor.name="Scenery";decor.y_sort_enabled=true;add(decor,world)
        # Trees beyond the walk boundary frame the square without hidden obstacles.
        for y in range(-200,int(stage.size[1])+201,48):
            for x in [-80,-32,int(stage.size[0])+32,int(stage.size[0])+80]:
                sprite(decor,"Basic Tiles 4 (Trees & Bushes).png",Rect2(336,0,48,56),Vector2(x+rng.randi_range(-8,8),y))
        for x in range(0,int(stage.size[0])+1,48):
            for y in [-40,int(stage.size[1])+40]:sprite(decor,"Basic Tiles 4 (Trees & Bushes).png",Rect2(528,0,48,56),Vector2(x,y))
        var camps=Node2D.new();camps.name="Camps";add(camps,world)
        for i in range(stage.spawns.size()):
            var point=stage.spawns[i];var c=Node2D.new();c.name="Camp%d" % i;c.position=Vector2(point[0],point[1]);add(c,camps)
            paint(courts,rect_mask(Rect2i(Vector2i(c.position/16)-Vector2i(3,2),Vector2i(7,5))),1,Vector2i(25,12))
            sprite(c,"Props.png",Rect2(176,272,48,64),Vector2(0,-18),"Fountain")
            sprite(c,"Props.png",Rect2(64,0,48,48),Vector2(35,10),"Bench")
            sprite(c,"Props.png",Rect2(96,216,16,32),Vector2(-34,-18),"Selected")
            label(c,"",Vector2(-55,-77),110,9)
        var packed=PackedScene.new();var error=packed.pack(world)
        if error==OK:error=ResourceSaver.save(packed,"res://scenes/game/stages/stage_%d.tscn" % stage.id)
        print("STAGE_BUILD ",stage.id," result=",error)
        world.free()
        if error!=OK:quit(error);return
    quit(0)
