extends Node
## Change 15 UI capture (rendered, not headless): the fresh-profile HUD with the hidden navigation
## slots, a newly revealed menu with its ✦, the Basic feature card, the Guided Snowman objective
## pointing at the Next Stage chip, Settings → Tutorial and help, World with the Map Mastery entry,
## the Map Mastery list and a map page, and Stats with game completion. Writes PNGs to
## docs/Change_15_Evidence/ui/. Desktop evidence only, not proof of phone layout, colour or speed.
## Run without --first-run-complete (it shows the progression itself).
var sim
var game
const OUT="res://docs/Change_15_Evidence/ui/"
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name: String,settle:=10,keep_banner:=false) -> void:
    if not keep_banner:game.banner.queue.clear();game.banner._finish()
    game.toast_queue.clear();game.get_node("Toast").hide()
    await frames(settle)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func run() -> void:
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
    SettingsState.set_camera_zoom(2.0)
    sim.state.tutorial.seen.append("overview")
    await shot("01_fresh_hud_hidden_menus")
    # Missions revealed (fixture: first merge), with its ✦ until opened.
    sim.add_item("wood_sword",2);sim.merge("wood_sword");sim.equip("wood_sword")
    sim.campaign.onboarding.evaluate()
    await shot("02_missions_revealed_badge")
    # Basic: the card for the newly revealed system.
    sim.state.tutorial.mode="basic"
    await shot("03_basic_feature_card")
    # Guided: the Snowman objective card pointing at the Next Stage chip (fixture: earlier lessons done).
    sim.state.tutorial.mode="guided"
    sim.state.tutorial.done.append_array(["move","kill","collect","equip","merge","missions","upgrade","camp","slots"])
    sim.state.onboarding.reveal=["missions","enemy","world","upgrades","objective"]
    for f in ["missions","enemy","world","upgrades"]:sim.state.tutorial.seen.append("opened:"+f)
    sim.campaign.reveal_circle(sim.position_of(sim.state.player),300.0)
    await shot("04_guided_snowman_objective",20)
    sim.state.tutorial.seen.append("snowman")
    game._open("settings")
    await shot("05_settings_tutorial_and_help")
    game._close()
    # Snowman defeated: Prestige revealed (banner kept in the shot).
    sim.state.tutorial.mode="none"
    var snow: int=sim.campaign.group_id("boss-snowman")
    sim.state.group_kills[snow]=1;sim.state.run_kills["boss-snowman"]=1;sim.state.unlocked_stage=2
    sim.campaign.onboarding.evaluate()
    await shot("06_prestige_unlocked_banner",6,true)
    # Map Mastery with some progress (fixture).
    for g in sim.campaign.stage().groups:
        sim.state.group_kills[g]=maxi(int(sim.state.group_kills[g]),40)
        sim.state.upgrades["reveal_stats:%d" % g]=1
        sim.campaign.discover_spot(g,2)
    sim.state.upgrades["reveal_drops:0"]=1
    sim.state.mastery.explored["1"]=86;sim.state.mastery.found["unit-blue-cap_outfit"]=true;sim.state.mastery.merge["unit-blue-cap_outfit"]=25
    sim.campaign.mastery.evaluate(false)
    game._open("world")
    game.get_node("Sheet/Margin/Content/Scroll").scroll_vertical=100000
    await shot("07_world_mastery_entry")
    game.mastery_stage=0;game._open("mastery")
    await shot("08_mastery_maps")
    game.mastery_stage=1;game._refresh_panel(true)
    await shot("09_mastery_winter1")
    game._close()
    game._open("stats")
    await shot("10_stats_completion")
    game._close()
    print("CHANGE_15_CAPTURE done")
    get_tree().quit()
