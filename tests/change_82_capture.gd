extends Node
## Change 82 rendered desktop evidence (not Android validation). One real-time playback, at normal speed with the
## simulation running on its own physics clock: the hero walks up to the Green Alien with 13 keys, the unsealing
## ceremony plays (keys appear, orbit, gather, fly, the seal breaks, the banner reads), the fight starts and the
## arena closes, the hero presses against the barrier, the hero falls and the barrier opens.
## Stills at fixed ceremony times plus every frame at 10 fps for a playback video (assembled outside Godot).
## Prints AUDIT lines: the ceremony keys inside the map and clear of the joystick, the barrier on screen.
## Run windowed (432x960, 540x960; the monitor clamps taller windows):
##   godot --path . --resolution 432x960 res://tests/change_82_capture.tscn -- --probe --profile=probe-c82cap
##       --no-autosave --first-run-complete --shape=432x960
## Output: generated/evidence/change_82/<shape>/ (ignored by Git).
var game
var sim
var shape:="540x960"
var dir:=""
var frame_index:=0
var record:=false
var record_clock:=0.0

func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame

func save(name_: String) -> void:
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dir+name_+".png"))
    print("SHOT ",dir+name_+".png")
func shot(name_: String) -> void:
    await frames(2)
    save(name_)

func _process(delta: float) -> void:
    if not record:return
    record_clock+=delta
    if record_clock>=.1:
        record_clock-=.1
        get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dir+"seq/f%04d.png" % frame_index))
        frame_index+=1

func alien() -> Dictionary:
    for a in sim.state.enemies:
        if bool(sim.catalog.groups[int(a.group)].final) and not sim.is_helper(a):return a
    return {}

func wait_until(cond: Callable,limit:=20.0) -> void:
    var t:=0.0
    while not cond.call() and t<limit:
        await get_tree().process_frame
        t+=get_process_delta_time()

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
    dir="res://generated/evidence/change_82/%s/" % shape
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir+"seq"))
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    get_tree().paused=false
    sim.new_profile();sim.suspended=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append_array(["road_ahead","final_intro"])
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()
    sim.state.stage=8;sim.state.unlocked_stage=8;sim.state.spawns=[0,1,2];sim.state.camps["8"]=[0,1,2]
    sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II reached
    sim.state.final_discovered=true;sim.state.keys=[];sim.state.bosses_found.append("boss-green-alien") # fixture: met before
    for d in sim.catalog.groups:
        if d.boss and not d.final:sim.state.keys.append(str(d.id)) # fixture: 13 keys
    sim.state.player_level=500;sim._stats_revision=-1;sim.state.player.hp=sim.stats().hp # fixture: survives a while
    for id in ["obsidian_sword","boss-red-panda_outfit_t5"]:
        if sim.catalog.items.has(id):sim.add_item(id,1,false,false);sim.equip(id) # fixture: an endgame look
    var a:=alien()
    sim.state.player.x=float(a.home_x)-10;sim.state.player.y=float(a.home_y)+150 # fixture: south of it, out of range
    sim.campaign.reveal();sim.touch()
    game.world.follow_player()
    game.elapsed=1.0
    await frames(30)
    game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()
    sim.state.player.hp=sim.stats().hp
    await frames(4)
    await shot("00_approach_13_keys")
    # Walk north with the stick until the ceremony takes over (real time, physics clock).
    record=true
    game.stick_input=Vector2.UP # the stick, as the player would hold it
    await wait_until(func()->bool:return sim.campaign.ceremony_active(),10.0)
    game.stick_input=Vector2.ZERO
    var marks:=[[.3,"01_keys_appear"],[1.4,"02_orbit"],[2.7,"03_orbit_fast"],[3.3,"04_gather"],[3.75,"05_fly"],[4.3,"06_seal_breaks"],[5.2,"07_worth_banner"]]
    for m in marks:
        await wait_until(func()->bool:return not sim.campaign.ceremony_active() or sim.campaign.ceremony_time>=float(m[0]),10.0)
        save(str(m[1]))
        audit_ceremony(str(m[1]))
    await wait_until(func()->bool:return sim.campaign.arena_active(),5.0)
    await get_tree().create_timer(.3).timeout
    save("08_arena_closing")
    await get_tree().create_timer(.7).timeout
    save("09_arena_establishing")
    audit_arena("09_arena_establishing")
    await get_tree().create_timer(1.8).timeout
    save("09b_arena_fight_normal_zoom")
    # Press against the barrier (east) for a moment.
    game.stick_input=Vector2.RIGHT
    await get_tree().create_timer(2.6).timeout
    save("10_barrier_press")
    game.stick_input=Vector2.ZERO
    await get_tree().create_timer(.6).timeout
    # The hero falls: the barrier opens.
    sim.state.player.hp=0.0;sim._kill(sim.state.player) # fixture: defeat now (no waiting for the boss)
    await get_tree().create_timer(.2).timeout
    save("11_barrier_opens")
    await get_tree().create_timer(1.0).timeout
    save("12_after_defeat")
    record=false
    print("FRAMES ",frame_index)
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(0)

func audit_ceremony(name_: String) -> void:
    var problems: Array=[]
    var map: Control=game.get_node("Safe/Layout/Map")
    var rect: Rect2=map.get_global_rect()
    var xf: Transform2D=game.world.get_canvas_transform()
    var scale_: Vector2=map.size/Vector2(game.world.get_viewport_rect().size)
    for k in game.world.ceremony_fx.keys:
        if not k.is_visible_in_tree():continue
        var p: Vector2=map.global_position+(xf*k.global_position)*scale_
        if not rect.has_point(p):problems.append("key off the map %s" % [p])
        var stick: Control=game.stick
        if stick.is_visible_in_tree() and stick.get_global_rect().has_point(p):problems.append("key over the joystick")
    print("AUDIT %s %s %s" % [shape,name_,"ok" if problems.is_empty() else "AUDIT_FAIL "+str(problems)])

func audit_arena(name_: String) -> void:
    var problems: Array=[]
    if not game.world.arena_fx.visible:problems.append("barrier hidden")
    var xf: Transform2D=game.world.get_canvas_transform()
    var c: Vector2=xf*sim.campaign.arena_center()
    var vp: Vector2=game.world.get_viewport_rect().size
    if not Rect2(Vector2.ZERO,vp).has_point(c):problems.append("arena centre off screen")
    print("AUDIT %s %s radius_px=%.0f view=%s shot=%.2f w=%.2f cam=%s %s" % [shape,name_,sim.campaign.arena_radius()*xf.get_scale().x,vp,game.world.arena_shot,game.world.cine_weight,game.world.get_node("Camera").zoom,"ok" if problems.is_empty() else "AUDIT_FAIL "+str(problems)])
