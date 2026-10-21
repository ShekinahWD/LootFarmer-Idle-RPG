extends SceneTree
## Change 6 authoring utility. Moves each existing boss court (Clearings tiles) and its
## hand-authored BossLandmarks node to the boss center now in the catalog. Everything else in
## the baked stage scenes (terrain, paths, props, camps, landmark composition) is preserved.
## Run: godot --headless --path . --script res://tools/relocate_boss_arenas.gd
const COURT_SOURCE:=1
const COURT_BASE:=Vector2i(25,12)
func _initialize() -> void:call_deferred("run")
func court(center: Vector2) -> Dictionary:
    var pos:=Vector2i(int(center.x/16),int(center.y/16))
    var r:=Rect2i(pos-Vector2i(5,4),Vector2i(11,9))
    var m: Dictionary={}
    for y in range(r.position.y,r.end.y):
        for x in range(r.position.x,r.end.x):m[Vector2i(x,y)]=true
    for corner in [r.position,Vector2i(r.end.x-1,r.position.y),Vector2i(r.position.x,r.end.y-1),r.end-Vector2i.ONE]:m.erase(corner)
    return m
func camp_cells(stage: Dictionary) -> Dictionary:
    var keep: Dictionary={}
    for point in stage.spawns:
        var at:=Vector2i(int(point[0]/16),int(point[1]/16))
        for y in range(at.y-2,at.y+3):
            for x in range(at.x-3,at.x+4):keep[Vector2i(x,y)]=true
    return keep
func paint(layer: TileMapLayer,cells: Dictionary) -> void:
    for p in cells:
        var x:=0 if not cells.has(p+Vector2i.LEFT) else (2 if not cells.has(p+Vector2i.RIGHT) else 1)
        var y:=0 if not cells.has(p+Vector2i.UP) else (2 if not cells.has(p+Vector2i.DOWN) else 1)
        layer.set_cell(p,COURT_SOURCE,COURT_BASE+Vector2i(x,y))
func run() -> void:
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/game/catalog.json"))
    for stage in data.stages:
        var path:="res://scenes/game/stages/stage_%d.tscn" % int(stage.id)
        var root: Node=load(path).instantiate()
        var layer: TileMapLayer=root.get_node("Clearings")
        var keep:=camp_cells(stage)
        var moved:=0
        for g in stage.groups:
            var def: Dictionary=data.groups[int(g)]
            if not def.boss:continue
            var mark: Node2D=root.get_node("BossLandmarks/"+str(def.id).replace("-","_"))
            var target:=Vector2(def.center[0],def.center[1])
            if mark.position.is_equal_approx(target):continue
            for cell in court(mark.position):
                if not keep.has(cell):layer.erase_cell(cell)
            mark.position=target
            moved+=1
        # Repaint every boss court after erasing, so overlapping old/new courts stay whole.
        for g in stage.groups:
            var def: Dictionary=data.groups[int(g)]
            if def.boss:paint(layer,court(Vector2(def.center[0],def.center[1])))
        var packed:=PackedScene.new()
        var error:=packed.pack(root)
        if error==OK:error=ResourceSaver.save(packed,path)
        print("BOSS_ARENA stage=%d moved=%d result=%d" % [int(stage.id),moved,error])
        root.free()
    quit(0)
