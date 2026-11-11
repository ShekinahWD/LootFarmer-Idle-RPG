extends Node
## Change 67 rendered motion capture (run windowed at 432x960 and 540x960, not headless):
##   Godot --path . --resolution 432x960 tests/change_67_capture.tscn -- --no-autosave --first-run-complete [--only=merge|evolve|all|auto] [--out=<dir>]
## Plays each presentation in real time and saves the viewport every STEP seconds as
## <out>/<w>x<h>/<sequence>_<index>_<ms>.png (default user://change_67_capture/), so a contact sheet or a GIF
## shows the real motion. Prints BOUNDS for any visible evolution-panel control outside the safe area.
## State set directly is a fixture (labelled). Desktop captures do not certify phone frame rates.
var sim
var game
var out:=""
var only:=""
var problems:=0
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func wait(seconds: float) -> void:
    await get_tree().create_timer(seconds,true,false,true).timeout

func run() -> void:
    var root:="user://change_67_capture/"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
        if arg.begins_with("--out="):root=arg.trim_prefix("--out=").trim_suffix("/")+"/"
    var view:=Vector2(DisplayServer.window_get_size())
    out=root+"%dx%d/" % [int(view.x),int(view.y)]
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
    TranslationServer.set_locale("en")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.set_physics_process(false)
    await frames(10)
    if only in ["","merge"]:await merge_sequence()
    if only in ["","evolve"]:await evolution_sequence("wood_sword","evolve_wood",3.0)
    if only in ["","evolve"]:await evolution_sequence("iron_sword","evolve_iron",3.0)
    if only in ["","evolve"]:await skip_sequence()
    if only in ["","all"]:await merge_all_sequence()
    if only in ["","auto"]:await auto_sequence()
    print("CHANGE_67_CAPTURE ",ProjectSettings.globalize_path(out)," PROBLEMS ",problems)
    get_tree().quit(0)

func fresh() -> void:
    get_tree().paused=false
    game.help_viewer.hide();game.evolution_show.visible=false;sim.held=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead") # fixture: the goals card is not part of these screens
    sim.state.player.quiet=1e9
    for e in sim.state.enemies:e.aggro=false
    game._close();game.toast_queue.clear();game.get_node("Toast").hide()
    game.banner.queue.clear();game.banner._finish()
    game.get_node("PrestigeConfirm").close();game._cancel_confirm()
    game.merge_fx.stop();game.merge_fx.clear_glints()

func save(name: String) -> void:
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out)+name+".png")

## Saves a frame every step seconds of real time for length seconds, starting now.
func record(prefix: String,length: float,step: float) -> void:
    var start:=Time.get_ticks_msec()
    var next:=0.0
    var index:=0
    while true:
        await get_tree().process_frame
        var t:=(Time.get_ticks_msec()-start)/1000.0
        if t>=next:
            await RenderingServer.frame_post_draw
            save("%s_%02d_%04d" % [prefix,index,int(t*1000)])
            index+=1
            next+=step
        if t>=length:break
    print("SEQUENCE ",prefix," frames ",index)

func open_item(id: String) -> void:
    game.selected=id;game.selected_slot=-1;game._open("item")
    await frames(12)

func merge_sequence() -> void:
    fresh()
    sim.add_item("cloth_shirt",2) # fixture: an outfit equipped so the card compares
    sim.equip("cloth_shirt")
    sim.add_item("wood_sword",5)
    sim.merge("wood_sword",true);sim.add_item("wood_sword",4) # fixture: ^4 with spares
    await open_item("wood_sword")
    save("merge_before")
    game._manual_merge("wood_sword")
    await record("merge",1.05,.05)
    await wait(.4)
    save("merge_after")
    # Merge all copies from the card.
    game._manual_merge("wood_sword",true)
    await record("merge_many",.7,.1)

func evolution_sequence(id: String,prefix: String,length: float) -> void:
    fresh()
    var copies: int=sim.evolution_spare_cost(id)+1
    sim.add_item(id,copies+int(sim.merge_cap(id)))
    sim.merge(id,true) # fixture: at ^20 with the spares an evolution needs
    await open_item(id)
    save(prefix+"_panel")
    game._manual_evolve(id)
    await record(prefix,length,.1)
    audit(prefix)
    save(prefix+"_result")
    game.evolution_show.close()
    await wait(.4)
    save(prefix+"_closed")

## A tap at 0.6 s skips straight to the result.
func skip_sequence() -> void:
    fresh()
    sim.add_item("stone_sword",11+20);sim.merge("stone_sword",true)
    await open_item("stone_sword")
    game._manual_evolve("stone_sword")
    await wait(.6)
    save("skip_before_tap")
    var tap:=InputEventMouseButton.new()
    tap.button_index=MOUSE_BUTTON_LEFT;tap.pressed=true;tap.position=get_viewport().get_visible_rect().size*Vector2(.5,.2)
    Input.parse_input_event(tap)
    var up:=tap.duplicate();up.pressed=false;Input.parse_input_event(up)
    await frames(3)
    save("skip_after_tap")
    audit("skip")
    game.evolution_show.close()
    await wait(.4)

func merge_all_sequence() -> void:
    fresh()
    sim.state.upgrades["merge_all"]=1
    for id in ["wood_sword","wood_axe","cloth_shirt","stone_sword","leather_armor"]:
        if sim.catalog.items.has(id):sim.add_item(id,4)
    game._open("filters")
    await frames(12)
    var button: Button=game._guide_button("merge_all")
    save("merge_all_before")
    button.pressed.emit()
    await record("merge_all",.7,.07)

func auto_sequence() -> void:
    fresh()
    var blue:=-1
    for i in range(sim.catalog.groups.size()):
        if sim.catalog.groups[i].id=="unit-blue-cap":blue=i
    sim.state.upgrades["merge_gear:%d" % blue]=1 # fixture: Auto-Merge and Auto Evolution owned
    sim.state.upgrades["auto_evolve:%d" % blue]=1
    sim.add_item("wood_sword",31)
    await frames(10)
    sim.campaign.merge_cycle(str(blue),0.0,1.0,blue)
    await record("auto_merge",.5,.08)
    for i in range(40):sim.campaign.merge_cycle(str(blue),0.0,1.0,blue)
    await wait(1.0)
    sim.campaign.evolve_clock=1.0;sim.campaign.auto_evolve()
    await record("auto_evolve",.8,.1)

func audit(surface: String) -> void:
    var view:=get_viewport().get_visible_rect()
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var safe:=Rect2(view.position+Vector2(insets.x,insets.y),view.size-Vector2(insets.x+insets.z,insets.y+insets.w))
    var show: Control=game.evolution_show
    for node in show.find_children("*","Control",true,false):
        if not node.is_visible_in_tree() or node.size==Vector2.ZERO or node is ColorRect:continue
        var r: Rect2=node.get_global_rect()
        # Global rects are in the 720-wide base canvas; compare against the canvas-space safe area.
        var canvas_safe:=Rect2(Vector2(insets.x,insets.y),show.size-Vector2(insets.x+insets.z,insets.y+insets.w))
        if r.position.x<canvas_safe.position.x-.5 or r.end.x>canvas_safe.end.x+.5 or r.position.y<canvas_safe.position.y-.5 or r.end.y>canvas_safe.end.y+.5:
            problems+=1
            print("BOUNDS ",surface," ",node.name," ",r," safe ",canvas_safe)
        if node is Label and node.autowrap_mode==TextServer.AUTOWRAP_OFF and node.get_line_count()>1:
            problems+=1;print("TRUNCATED ",surface," ",node.name)
