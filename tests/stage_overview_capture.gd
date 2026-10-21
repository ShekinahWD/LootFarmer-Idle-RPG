extends Node
## Renders each baked stage with its camps (blue), farming spots (white, ring = acquisition range)
## and bosses (red) so encounter layout can be reviewed as a composition.
## godot --path . tests/stage_overview_capture.tscn -- --probe --no-autosave --out=after
var sim
class Overlay extends Node2D:
    var sim
    var stage: Dictionary
    func _draw() -> void:
        var acq: float=sim.catalog.world.acquisition
        for i in range(stage.spawns.size()):
            var p:=Vector2(stage.spawns[i][0],stage.spawns[i][1])
            draw_circle(p,22,Color(.2,.5,1,.9));draw_arc(p,acq,0,TAU,48,Color(.2,.5,1),3)
        for g in stage.groups:
            var d: Dictionary=sim.catalog.groups[g]
            for v in sim.campaign.variants(g):
                var p: Vector2=sim.campaign.spot(g,v)
                var c:=Color(1,.2,.2) if d.boss else Color(1,1,1)
                draw_circle(p,18 if d.boss else 10,c);draw_arc(p,acq,0,TAU,48,Color(c,.6),2)
func _ready() -> void:call_deferred("run")
func run() -> void:
    var out:="before"
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--out="):out=a.split("=")[1]
    var dir:="res://docs/Change_6_Evidence/%s/" % out
    DirAccess.make_dir_recursive_absolute(dir)
    sim=load("res://scripts/game/simulation.gd").new();add_child(sim);sim.set_physics_process(false)
    for stage in sim.catalog.stages:
        var vp:=SubViewport.new();vp.size=Vector2i(stage.size[0],stage.size[1]);vp.render_target_update_mode=SubViewport.UPDATE_ONCE
        add_child(vp)
        var scene: Node2D=load("res://scenes/game/stages/stage_%d.tscn" % stage.id).instantiate();vp.add_child(scene)
        var overlay:=Overlay.new();overlay.sim=sim;overlay.stage=stage;overlay.z_index=10;vp.add_child(overlay)
        for i in range(3):await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var img:=vp.get_texture().get_image()
        img.resize(int(stage.size[0]*480.0/stage.size[0]),int(stage.size[1]*480.0/stage.size[0]),Image.INTERPOLATE_BILINEAR)
        img.save_png(dir+"stage_%d_layout.png" % stage.id)
        vp.queue_free()
    get_tree().quit()
