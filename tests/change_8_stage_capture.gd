extends Node
## Change 8 map pass review: each stage scene rendered whole (scaled to 720 px wide) with spot and
## camp markers, plus one 1:2 crop around the arrival camp. Rendered, not headless.
## godot --path . res://tests/change_8_stage_capture.tscn -- --out=after [--stage=N] [--plain]
var sim
class Overlay extends Node2D:
    var sim
    var stage: Dictionary
    func _draw() -> void:
        for i in range(stage.spawns.size()):
            draw_arc(Vector2(stage.spawns[i][0],stage.spawns[i][1]),104,0,TAU,48,Color(.2,.5,1,.8),3)
        for g in stage.groups:
            for v in sim.campaign.variants(g):
                draw_arc(sim.campaign.spot(g,v)+Vector2(0,13),118.0 if sim.catalog.groups[g].boss else 74.0,0,TAU,40,Color(1,.2,.2,.8) if sim.catalog.groups[g].boss else Color(1,1,1,.7),2)
func _ready() -> void:call_deferred("run")
func run() -> void:
    var out:="after";var only:=0;var plain:=false
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--out="):out=a.get_slice("=",1)
        if a.begins_with("--stage="):only=int(a.get_slice("=",1))
        if a=="--plain":plain=true
    var dir:="res://docs/Change_8_Evidence/maps/%s/" % out
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    sim=load("res://scripts/game/simulation.gd").new();add_child(sim);sim.set_physics_process(false)
    for stage in sim.catalog.stages:
        if only>0 and int(stage.id)!=only:continue
        var vp:=SubViewport.new();vp.size=Vector2i(stage.size[0],stage.size[1]);vp.render_target_update_mode=SubViewport.UPDATE_ONCE
        vp.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
        add_child(vp)
        var holder:=Node2D.new();holder.y_sort_enabled=true;vp.add_child(holder)
        var scene: Node2D=load("res://scenes/game/stages/stage_%d.tscn" % stage.id).instantiate();holder.add_child(scene)
        if not plain:
            var overlay:=Overlay.new();overlay.sim=sim;overlay.stage=stage;overlay.z_index=20;vp.add_child(overlay)
        for i in range(3):await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var img:=vp.get_texture().get_image()
        var crop_center:=Vector2(stage.spawns[0][0],stage.spawns[0][1])-Vector2(0,140)
        var crop:=Rect2i(Vector2i(crop_center-Vector2(180,160)).clamp(Vector2i.ZERO,Vector2i(stage.size[0]-360,stage.size[1]-320)),Vector2i(360,320))
        var detail:=img.get_region(crop);detail.resize(720,640,Image.INTERPOLATE_NEAREST)
        detail.save_png(ProjectSettings.globalize_path(dir+"stage_%d_detail.png" % stage.id))
        img.resize(720,int(stage.size[1]*720.0/stage.size[0]),Image.INTERPOLATE_BILINEAR)
        img.save_png(ProjectSettings.globalize_path(dir+"stage_%d.png" % stage.id))
        vp.queue_free()
    get_tree().quit()
