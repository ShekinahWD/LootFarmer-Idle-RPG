extends Node
## Change 77 rendered desktop evidence (not a gate, not Android validation): the Regional Prestige choice with
## Camp Supplies offered (formerly Camp Survey), the owned card in the Prestige panel, and the Camp Supplies
## reward toast on the HUD after arriving at a camp.
## Run windowed (432x960, 540x960; the monitor clamps taller windows):
##   godot --path . --resolution 540x960 res://tests/change_77_capture.tscn -- --probe --profile=probe-c77cap
##       --no-autosave --first-run-complete --shape=540x960 [--lang=de_DE]
## Output: tests/tmp/change_77_capture/<shape>[_<lang>]_<name>.png (ignored by Git).
var game
var sim
var shape:="540x960"
var lang:=""

func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame

func shot(name_: String) -> void:
    await frames(4)
    var dir:="res://tests/tmp/change_77_capture/"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    var file:=dir+shape+("_"+lang if lang!="" else "")+"_"+name_+".png"
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(file))
    print("SHOT ",file)

func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game._cancel_confirm()
    game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide();game.toast_time=0.0

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
        elif arg.begins_with("--lang="):lang=arg.trim_prefix("--lang=")
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic" if lang=="" else lang)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    # 1. A Regional Prestige choice: Camp Supplies is offered.
    fresh()
    sim.state.owned_cards=["regional_c1","regional_c2"] # fixture: earlier Regional cards owned
    var g: int=sim.campaign.prestige_unlock_group()
    sim.state.bosses_found.append("boss-snowman");sim.state.group_kills[g]=1 # fixture: Prestige unlocked
    sim.state.opportunities["regional_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    sim.campaign.begin_prestige()
    game._open("prestige");await frames(20)
    await shot("01_prestige_choice_camp_supplies")
    # 2. The owned card in the Prestige panel.
    sim.campaign.choose_card("regional_c3");await frames(4)
    fresh()
    sim.state.owned_cards=["regional_c1","regional_c2","regional_c3"]
    game._open("prestige");await frames(20)
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    for l in game.rows.find_children("*","",true,false):
        if (l is Label or l is Button) and str(l.text).contains(tr("CONTENT_REGIONAL_C3_NAME")):
            scroll.scroll_vertical=int(l.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical)-120;break
    await frames(4)
    await shot("02_prestige_owned_card")
    # 3. The reward toast on the HUD, just after the first visit to the arrival camp.
    fresh()
    sim.state.owned_cards=["regional_c3"]
    var a: Array=sim.campaign.stage().spawns[0];sim.state.player.x=a[0];sim.state.player.y=a[1]
    sim.campaign.camp_supply_step()
    for i in range(10):game._update_toast(.1)
    await frames(6)
    await shot("03_camp_supply_toast")
    print("CHANGE_77_CAPTURE complete shape=%s" % shape)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()
