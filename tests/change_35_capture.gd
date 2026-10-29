extends Node
## Change 35 rendered desktop evidence (not a gate, not Android validation): the review invitation for
## both storefront buttons (and its launch-failure state), the Basic targeting card and its Help entry,
## and the Guided targeting lesson (the drawn demo, the player's real aim line, the next lesson).
## Run windowed: --resolution 540x960 (or 432x960, 768x1024) -- --probe --profile=probe-c35cap
## --no-autosave --first-run-complete --shape=<suffix>
var game
var sim
var suffix:="540"
const OUT="res://docs/Change_35_Evidence/"
func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name_: String) -> void:
    game.banner.queue.clear();game.banner._finish()
    game.toast_queue.clear();game.get_node("Toast").hide()
    await frames(3)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name_+"_"+suffix+".png"))
func fresh(mode: String) -> void:
    get_tree().paused=false
    if game.get_node("ReviewInvitation").visible:game.get_node("ReviewInvitation").close()
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode=mode;sim.campaign.onboarding.reveal_all(true)
    game._close();game._cancel_confirm()
## A quiet, healthy moment one hour in, with the player's own gear equipped.
func quiet(channel: String) -> void:
    BootContext.store_channel_override=channel
    fresh("none");sim.state.tutorial.seen.append("road_ahead");sim.state.playtime_total=3600.0
    for id in ["wood_sword"]:
        if sim.catalog.items.has(id):sim.add_item(id,1);sim.equip(id)
    sim.state.player.hp=sim.stats().hp;sim.state.player.quiet=9.0
    game.world.follow_player();await frames(6)
func guided_at_target() -> Dictionary:
    BootContext.store_channel_override=""
    fresh("guided");sim.campaign.guided.data().done=["move"]
    var rules: OnboardingRules=sim.campaign.onboarding.rules
    sim.state.player.x=rules.path_target.x;sim.state.player.y=rules.path_target.y
    var foe: Dictionary={}
    for e in sim.state.enemies:
        if not sim.catalog.groups[int(e.group)].boss and foe.is_empty():foe=e
        elif not sim.catalog.groups[int(e.group)].boss and e.hp>0 and Vector2(e.x,e.y).distance_to(sim.position_of(sim.state.player))<70:e.hp=0;e.respawn=999.0
    foe.x=sim.state.player.x+60;foe.y=sim.state.player.y-30
    sim.campaign.reveal_circle(sim.position_of(foe),90)
    game.world.follow_player();await frames(10)
    return foe
func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):suffix=arg.trim_prefix("--shape=")
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.campaign.review.opener=func(_url: String)->int:return ERR_CANT_OPEN
    await frames(10)
    # Review invitation, opened by the real quiet-moment offer.
    for channel in ["google_play","itch_io"]:
        await quiet(channel)
        for i in range(12):game._offer_review(.25)
        await frames(1)
        await shot("01_review_"+channel)
        if channel=="google_play":
            game.get_node("ReviewInvitation").review_button.pressed.emit()
            await shot("02_review_open_failed")
        game._review_later()
    # Basic: the targeting card (2/6) and Help.
    BootContext.store_channel_override=""
    fresh("pending");sim.state.tutorial.seen=[]
    game.guide.choose("basic");await frames(4)
    game.guide.intro_button.pressed.emit();await frames(4)
    await shot("03_basic_target_card")
    sim.state.tutorial.seen.append_array(game.guide.BASIC_DECK);sim.state.tutorial.seen.append("road_ahead")
    game._open("settings");await frames(3);game._open("help");await frames(6)
    await shot("04_help_target_card")
    game._close()
    # Guided: the demo at two moments, the real aim line, then the next lesson.
    var foe: Dictionary=await guided_at_target()
    var guide=game.guide
    guide.pulse=floor(guide.pulse/1.9)*1.9+.55;await frames(1);guide.pulse=floor(guide.pulse/1.9)*1.9+.55
    await shot("05_guided_target_demo_mid")
    guide.pulse=floor(guide.pulse/1.9)*1.9+1.6
    await shot("06_guided_target_demo_release")
    var surface=game.get_node("Safe/Layout/Map/GestureSurface")
    var scale_: Vector2=surface.size/game.world.get_viewport_rect().size
    var hero: Vector2=game.world.player_screen_position()*scale_
    var at: Vector2=(game.world.get_canvas_transform()*(sim.position_of(foe)+Vector2(0,-10)))*scale_
    surface.begin_pointer(0,hero);surface.move_pointer(0,hero.lerp(at,.5));surface.move_pointer(0,at)
    await shot("07_guided_player_aiming")
    surface.end_pointer(0,at);await frames(6)
    await shot("08_guided_target_done_next_lesson")
    print("CHANGE_35_CAPTURE complete selected=%s done=%s" % [sim.manual_target==foe.id,sim.campaign.guided.data().done.has("target")])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()
