extends SceneTree
## Deterministic authoring utility. Bakes editable TileMapLayers and props;
## never runs during gameplay. Regenerate with --headless --script tools/build_map.gd.
const ROOT="res://assets/PixelPlains/"
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
    for dx in range(3):
        n.set_cell(Vector2i(p.x*3+dx,p.y),source,atlas)
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
    n.position=Vector2(pos.x*3,pos.y) if parent.name=="Scenery" else pos
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
    rng.seed=43021
    world=Node2D.new()
    world.name="World"
    world.set_script(load("res://scripts/game/world.gd"))
    world.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    tiles.tile_size=Vector2i(16,16)
    for file in ["Basic Tiles 1.png","Basic Tiles 2.png","Basic Tiles 3 (Water).png"]:
        var a:=TileSetAtlasSource.new()
        a.texture=load(ROOT+file)
        a.texture_region_size=Vector2i(16,16)
        tiles.add_source(a,sources.size())
        sources.append(a)
    var grass:=layer("Ground")
    # Overscan surrounds every legal camera center at minimum zoom, including tall phones.
    for y in range(-64,160):
        for x in range(-48,72):
            var atlas:=Vector2i(rng.randi_range(21,27),3) if rng.randf()<.09 else Vector2i(26,7)
            tile(grass,Vector2i(x,y),0,atlas)
    var woodland:=layer("Woodland")
    for cy in range(-56,156,12):
        for cx in [-40,-22,-9,26,40,55]:
            var w:=rng.randi_range(6,10)
            var h:=rng.randi_range(6,11)
            paint(woodland,rect_mask(Rect2i(cx+rng.randi_range(-2,2),cy+rng.randi_range(-2,2),w,h)),0,Vector2i(25,9))
    # Enemy clearings have different ground treatments and quiet combat interiors.
    paint(woodland,rect_mask(Rect2i(1,65,21,14)),0,Vector2i(25,9))
    paint(woodland,rect_mask(Rect2i(1,23,21,14)),0,Vector2i(25,9))
    var stone:=layer("StoneCourts")
    paint(stone,rect_mask(Rect2i(2,44,19,12)),1,Vector2i(25,12))
    paint(stone,rect_mask(Rect2i(2,3,19,10)),1,Vector2i(25,12))
    var water:=layer("Ponds")
    for r in [Rect2i(-13,70,9,14),Rect2i(27,42,10,17),Rect2i(-15,17,10,14),Rect2i(29,4,9,12),Rect2i(-16,99,11,15),Rect2i(30,113,12,17),Rect2i(-20,-28,13,19)]:
        var m:=rect_mask(r)
        for dx in range(2):
            for dy in range(2):
                m.erase(r.position+Vector2i(dx,dy))
                m.erase(r.end-Vector2i(1+dx,1+dy))
        paint(water,m,2,Vector2i(40,12))
    var path:=layer("Paths")
    var road: Dictionary={}
    for y in range(-6,101):
        var center:=11+int(round(sin(float(y)*.12)*1.5))
        for x in range(center-1,center+2):road[Vector2i(x,y)]=true
    for cy in [87,60,39]:
        for y in range(cy-1,cy+2):
            for x in range(3,13):road[Vector2i(x,y)]=true
    paint(path,road,0,Vector2i(20,6))
    var decor:=Node2D.new()
    decor.name="Scenery"
    decor.y_sort_enabled=true
    add(decor,world)
    # All large non-interactive props remain outside the walkable combat strip.
    for y in range(-900,2500,56):
        for x in [-650,-500,-350,-240,-64,-20,390,440,580,730,950,1080]:
            var at:=Vector2(x+rng.randi_range(-12,12),y+rng.randi_range(-14,14))
            var cell:=Vector2i(floor(at.x/16),floor(at.y/16))
            if water.get_cell_source_id(cell)!=-1:continue
            var region:=Rect2(336,0,48,56) if rng.randf()<.6 else Rect2(528,0,48,56)
            sprite(decor,"Basic Tiles 4 (Trees & Bushes).png",region,at-Vector2(0,24))
    # Small accents grouped by borders, leaving player/enemy/loot silhouettes readable.
    for y in range(-650,2200,48):
        for x in [-150,4,350,510]:
            if rng.randf()<.45:continue
            var at:=Vector2(x+rng.randi_range(-8,8),y)
            if water.get_cell_source_id(Vector2i(floor(at.x/16),floor(at.y/16)))!=-1:continue
            if rng.randf()<.45:
                sprite(decor,"Basic Tiles 1.png",Rect2(64,128,32,16),at)
            else:
                sprite(decor,"Basic Tiles 1.png",Rect2(192,128,32,32),at)
    for y in [300,665,1005,1325]:
        for x in [100,264]:
            sprite(decor,"Basic Tiles 1.png",Rect2(192,128,32,32),Vector2(x,y))
            sprite(decor,"Basic Tiles 1.png",Rect2(64,128,32,16),Vector2(x+18,y+22))
    for pos in [Vector2(36,726),Vector2(324,726),Vector2(36,60),Vector2(324,60)]:
        sprite(decor,"Props.png",Rect2(32,144,32,32),pos)
    var camps:=Node2D.new()
    camps.name="Camps"
    add(camps,world)
    for i in range(3):
        var cy: int=[1390,960,620][i]
        var c:=Node2D.new()
        c.name="Camp%d" % i
        c.position=Vector2(64,cy)
        add(c,camps)
        # Recognizable fountain shrine + bench, framed by its own stone plaza.
        paint(stone,rect_mask(Rect2i(1,int(cy/16)-3,7,6)),1,Vector2i(25,12))
        sprite(c,"Props.png",Rect2(176,272,48,64),Vector2(0,-18),"Fountain")
        sprite(c,"Props.png",Rect2(64,0,48,48),Vector2(35,10),"Bench")
        var selected:=sprite(c,"Props.png",Rect2(96,216,16,32),Vector2(-34,-18),"Selected")
        selected.visible=i==0
        label(c,"CAMP_NAME",Vector2(-55,-77),110,9)
    for i in range(4):
        var cy: int=[1150,810,470,130][i]
        label(world,"GROUP_%d" % i,Vector2(390,cy-100),300,12,"Group%d" % i)
        if i<3:
            for variant in range(3):
                var x:=180+variant*360
                label(world,["VARIANT_OUTFIT","VARIANT_WEAPON","VARIANT_BOTH"][variant],Vector2(x-100,cy-60),200,10,"Variant%d_%d" % [i,variant])
                var local_road: Dictionary={}
                for y in range(int(cy/16)+4,int(cy/16)+6):
                    for tx in range(2,22):local_road[Vector2i(tx,y)]=true
                paint(path,local_road,0,Vector2i(20,6))
    var actors:=Node2D.new()
    actors.name="Actors"
    actors.y_sort_enabled=true
    add(actors,world)
    var pickups:=Node2D.new()
    pickups.name="Pickups"
    add(pickups,world)
    var camera:=Camera2D.new()
    camera.name="Camera"
    camera.position=Vector2(180,1390)
    camera.zoom=Vector2(4,4)
    add(camera,world)
    var scene:=PackedScene.new()
    var result:=scene.pack(world)
    if result==OK:result=ResourceSaver.save(scene,"res://scenes/game/world.tscn")
    print("MAP_BUILD result=",result)
    world.free()
    quit(result)
