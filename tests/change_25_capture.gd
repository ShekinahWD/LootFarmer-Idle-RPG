extends Node
## Change 25 rendered desktop evidence (not a gate, not Android validation): the three onboarding
## modes at their first moments, the open-but-locked panels, the Back exit confirmation, and world
## readability (fog shader, rain, respawn countdown, wide-zoom culling) at the zoom limits.
## Run windowed: --resolution 540x960 (or 432x960) -- --probe --profile=probe-c25cap --no-autosave
## --first-run-complete --shape=<suffix>.
var game
var sim
var suffix:="540"
const OUT="res://docs/Change_25_Evidence/ui/"
func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name_: String,clear_banner:=true) -> void:
    if clear_banner:game.banner.queue.clear();game.banner._finish()
    game.toast_queue.clear();game.get_node("Toast").hide()
    await frames(12)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name_+"_"+suffix+".png"))
func chooser() -> void:
    sim.new_profile();sim.set_physics_process(false)
    sim.state.onboarding.reveal=[];sim.state.tutorial.seen=[];sim.state.tutorial.mode="pending"
    game._close();game._cancel_confirm()
func go(st: int) -> void:
    sim.state.unlocked_stage=maxi(int(sim.state.unlocked_stage),st);sim.state.stage=st;sim.state.spawn=0
    sim._reset_world();sim.campaign.reveal()
func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):suffix=arg.trim_prefix("--shape=")
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    chooser();await shot("01_chooser")
    game.guide.choose("basic");await shot("02_basic_card_1")
    for id in game.guide.BASIC_DECK.slice(0,game.guide.BASIC_DECK.size()-1):sim.state.tutorial.seen.append(id)
    await shot("03_basic_card_last")
    chooser();game.guide.choose("none");await shot("04_none_road_ahead")
    sim.state.tutorial.seen.append("road_ahead");await shot("05_none_hud_all_menus")
    game._open("prestige");await shot("06_prestige_locked_before_snowman")
    game._close();game.mastery_stage=0;game._open("mastery");await shot("07_mastery_open")
    game._close();game._open("upgrades");await shot("08_player_upgrades")
    game._close();await frames(2);game.back();await shot("09_back_exit_confirm")
    game._cancel_confirm()
    # World readability: Spring II rain under fog, at both zoom limits.
    go(8);sim.state.explored.erase("8");sim.campaign.discovery_revision+=1;sim.campaign.reveal();game.world.follow_player()
    for z in [1.0,3.0]:
        SettingsState.set_camera_zoom(z);await frames(30);await shot("10_spring2_rain_fog_zoom_%d" % int(z))
    # Respawn countdown after a boss defeat, at both zoom limits.
    go(1)
    for enemy in sim.state.enemies:
        if sim.catalog.groups[int(enemy.group)].boss:
            sim.state.player.x=enemy.x;sim.state.player.y=enemy.y
            sim.campaign.reveal();game.world.follow_player()
            enemy.hp=0;sim._kill(enemy);break
    for z in [1.0,3.0]:
        SettingsState.set_camera_zoom(z);game.world._boss_countdowns();await frames(20);await shot("11_respawn_countdown_zoom_%d" % int(z))
    SettingsState.set_camera_zoom(2.0)
    print("CHANGE_25_CAPTURE complete")
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()
