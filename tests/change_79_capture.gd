extends Node
## Change 79 rendered desktop evidence (not a gate, not Android validation):
## trackers  the followed Map Mastery (Defeat Teal Dinosaur), daily mission (longest Summer II enemy name) and Prestige
##           (Challenge II) pills on the Summer II HUD. Uses no Change 79 API, so the same script renders the
##           "before" state on a checkout of the previous commit.
## reroll    a boss-enhanced weapon with one boss bonus locked: Lock toggles and the Reroll Stats price.
## offline   Welcome back with a skill copy pending (Skills row, Locked), and Upgrades → Offline with Offline Skills.
## Run windowed (432x960, 540x960; the monitor clamps taller windows):
##   godot --path . --resolution 540x960 res://tests/change_79_capture.tscn -- --probe --profile=probe-c79cap
##       --no-autosave --first-run-complete --shape=540x960 [--lang=de_DE] [--parts=trackers] [--tag=before]
## Output: tests/tmp/change_79_capture/<tag>_<shape>[_<lang>]_<name>.png (ignored by Git).
var game
var sim
var shape:="540x960"
var lang:=""
var tag:="after"
var parts:="trackers,reroll,offline"

func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame

func shot(name_: String) -> void:
    await frames(4)
    var dir:="res://tests/tmp/change_79_capture/"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    var file:=dir+tag+"_"+shape+("_"+lang if lang!="" else "")+"_"+name_+".png"
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
        elif arg.begins_with("--tag="):tag=arg.trim_prefix("--tag=")
        elif arg.begins_with("--parts="):parts=arg.trim_prefix("--parts=")
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic" if lang=="" else lang)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    if parts.contains("trackers"):await trackers()
    if parts.contains("reroll"):await reroll()
    if parts.contains("offline"):await offline()
    print("CHANGE_79_CAPTURE complete shape=%s tag=%s" % [shape,tag])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()

func trackers() -> void:
    fresh()
    sim.state.unlocked_stage=4;sim.state.reward_stage=4;sim.state.stage=4 # fixture: Summer II reached
    sim._reset_world();sim.campaign.reveal()
    var teal=sim.campaign.group_id("boss-teal-dinosaur")
    var c: Dictionary=sim.campaign.mastery.content(4)
    for g in c.groups:
        if int(g)!=teal:sim.state.group_kills[int(g)]=sim.campaign.mastery.hunt_target(int(g)) # fixture: the other hunts done
    sim.state.discovered[str(teal)]=true
    sim.campaign.mastery.toggle_follow(4,"hunt")
    var long_g:=-1
    for g in sim.campaign.stage().groups:
        if not sim.catalog.groups[g].boss and (long_g<0 or str(sim.catalog.groups[g].name).length()>str(sim.catalog.groups[long_g].name).length()):long_g=g
    sim.state.missions[0]={"kind":"kill","target":str(sim.catalog.groups[long_g].id),"progress":2.0,"goal":40.0,"claimed":false,"rewards":sim.state.missions[0].get("rewards",{}),"day":sim.state.missions[0].get("day",""),"coins":600.0,"gems":0.0,"base_gems":0.0} # fixture: today's mission
    sim.campaign.toggle_follow_mission("daily",0)
    sim.state.opportunities["challenge_o2"]={"ready":false,"baseline":{},"step":0,"count":0} # fixture: discovered
    sim.state.follow="challenge_o2"
    for i in range(4):
        game._refresh_follow_tracker();game._refresh_mission_tracker();game._refresh_mastery_tracker();game._layout_trackers()
        await frames(3)
    await frames(10)
    await shot("01_hud_followed_objectives")

func reroll() -> void:
    fresh()
    sim._drop("wood_axe",{"group":sim.campaign.group_id("boss-snowman"),"x":200.0,"y":200.0})
    sim.collect(int(sim.state.pickups.back().uid))
    sim.state.gems=500.0
    sim.set_reroll_lock("wood_axe","boss:0",true)
    game.selected="wood_axe";game.selected_slot=-1;game._open("item");await frames(20)
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    for b in game.rows.find_children("RerollLock","Button",true,false):
        scroll.scroll_vertical=int(b.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical)-160;break
    await frames(6)
    await shot("02_item_reroll_locks")
    for b in game.rows.find_children("RerollStats","Button",true,false):
        scroll.scroll_vertical=int(b.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical)-260;break
    await frames(6)
    await shot("03_item_reroll_button")
    game._close()

func offline() -> void:
    fresh()
    sim.add_item("skill_fire",1);sim.add_item("wood_sword",1)
    sim.state.offline_pending={"id":"cap","seconds":14400.0,"longest":14400.0,"rewarded_hours":4.0,"coins":480.0,"gems":8.0,"items":{"wood_sword":2,"skill_fire":2}} # fixture: a pending claim
    game._open("offline");await frames(20)
    await shot("04_welcome_back_skills")
    game._close();sim.state.offline_pending={}
    game.player_tab=4;game._open("upgrades");await frames(20)
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    for l in game.rows.find_children("*","Label",true,false):
        if str(l.text)==tr("UP_OFFLINE_SKILL"):
            scroll.scroll_vertical=int(l.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical)-200;break
    await frames(6)
    await shot("05_upgrades_offline_skills")
    game._close()
