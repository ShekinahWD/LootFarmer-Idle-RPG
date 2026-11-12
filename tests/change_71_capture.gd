extends Node
## Change 71 rendered desktop evidence (not a gate, not Android validation): the HUD with three followed
## objectives and the left enemy controls, the top-right map stack, the inventory organised by a filter and
## a sort (dock and Filters panel), the Supplies shop, the three Follow/Unfollow surfaces (Mastery, Missions,
## Prestige), Coin upgrade cards and the Prestige celebration at fixed moments.
## Run windowed (432x960, 540x960, 768x1024; the monitor clamps taller windows):
##   godot --path . --resolution 540x960 res://tests/change_71_capture.tscn -- --probe --profile=probe-c71cap
##       --no-autosave --first-run-complete --shape=540x960 [--tag=before|after] [--inset=48,90,0,60]
##       [--joystick=0|1|2] [--lang=de_DE] [--only=hud,inventory,supplies,follow,upgrades,vfx]
## Output: tests/tmp/change_71_capture/<tag>/<shape>[_<variant>]_<name>.png (ignored by Git).
var game
var sim
var shape:="540x960"
var tag:="after"
var variant:=""
var only: Array=[]
var inset:=Vector4.ZERO
var joystick:=1
var lang:=""

func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame

func shot(name_: String,clear_notices:=true) -> void:
    if clear_notices:
        game.banner.queue.clear();game.banner._finish()
        game.toast_queue.clear();game.get_node("Toast").hide()
    await frames(3)
    var dir:="res://tests/tmp/change_71_capture/%s/" % tag
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    var file:=dir+shape+("_"+variant if variant!="" else "")+"_"+name_+".png"
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(file))
    print("SHOT ",file)

func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game._cancel_confirm()

func want(section: String) -> bool:
    return only.is_empty() or only.has(section)

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
        elif arg.begins_with("--tag="):tag=arg.trim_prefix("--tag=")
        elif arg.begins_with("--only="):only=Array(arg.trim_prefix("--only=").split(","))
        elif arg.begins_with("--joystick="):joystick=int(arg.trim_prefix("--joystick="))
        elif arg.begins_with("--lang="):lang=arg.trim_prefix("--lang=")
        elif arg.begins_with("--inset="):
            var p:=arg.trim_prefix("--inset=").split(",")
            inset=Vector4(float(p[0]),float(p[1]),float(p[2]),float(p[3]))
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic" if lang=="" else lang)
    SettingsState.set_joystick_position(joystick)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    if inset!=Vector4.ZERO:
        # A notch / gesture-bar phone: the same margins _safe_area() applies on Android.
        LayoutService.set_meta("c71_inset",inset)
        for pair in [["margin_left",inset.x],["margin_top",inset.y],["margin_right",inset.z],["margin_bottom",inset.w]]:
            game.get_node("Safe").add_theme_constant_override(pair[0],int(pair[1]))
        variant="inset"
    if joystick!=1:variant+=("_" if variant!="" else "")+"stick"+str(joystick)
    if lang!="":variant+=("_" if variant!="" else "")+lang
    if want("hud"):await hud()
    if want("inventory"):await inventory()
    if want("supplies"):await supplies()
    if want("follow"):await follow_panels()
    if want("upgrades"):await upgrades()
    if want("vfx"):await vfx()
    print("CHANGE_71_CAPTURE complete shape=%s tag=%s" % [shape,tag])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()

## The Winter I start with the Snowman found (Prestige revealed), an enemy in reach and three followed objectives.
func hud_fixture() -> void:
    fresh()
    var snow: int=sim.campaign.prestige_unlock_group()
    sim.state.bosses_found.append(str(sim.catalog.groups[snow].id))
    var g: int=sim.nearest_group()
    sim.state.discovered[str(g)]=true
    sim.campaign.discover_spot(g,0)
    game.combat_group=g
    sim.campaign.refresh_missions()
    sim.state.follow_mission="main:0"
    # An expedition chain mid-way (its compact card used to carry a "Next:" line).
    sim.state.opportunities["expedition_o1"]={"ready":false,"baseline":{},"step":0,"count":3}
    sim.state.follow="expedition_o1"
    sim.state.follow_mastery="1:hunt"
    sim.touch()

func hud() -> void:
    await hud_fixture()
    await frames(20)
    await shot("01_hud_three_trackers")
    # A toast and a banner at the same time as the three trackers.
    game._say("Auto Farm turned off")
    sim.milestone.emit("explored","1")
    await frames(30)
    await shot("02_hud_notices",false)
    # Zoomed out / in: the slider below the minimap.
    SettingsState.set_camera_zoom(1.0);await frames(6)
    await shot("03_hud_zoom_min")
    SettingsState.set_camera_zoom(2.0)

func inventory_fixture() -> void:
    fresh()
    sim.state.upgrades["gear_slots"]=9
    sim.state.gear.resize(sim.equipment_slot_count());sim.state.gear.fill("")
    for pair in [["wood_sword",3],["unit-blue-cap_outfit",12],["stone_axe",1],["skill_heal",2],["wood_axe",7],["unit-calico-cat_outfit",1],["gold_sword",2]]:
        if sim.catalog.items.has(pair[0]):sim.add_item(pair[0],pair[1],false,false)
    sim.touch()

func inventory() -> void:
    await inventory_fixture()
    await frames(10)
    await shot("10_inventory_default")
    game._open("filters");await frames(14)
    await shot("11_filters_panel_open")
    if "inventory_sort" in game:
        game._set_inventory_view(1,3)
        await frames(8)
        await shot("12_filters_weapons_quantity")
    game._close();await frames(8)
    await shot("13_inventory_after_close")

func supplies() -> void:
    fresh()
    sim.state.coins=480.0
    sim.add_item("potion",3,false,false)
    game.player_tab=2;game._open("upgrades");await frames(14)
    await shot("20_supplies_shop")
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    scroll.scroll_vertical=100000;await frames(6)
    await shot("21_supplies_shop_bottom")
    game._close()

func follow_panels() -> void:
    await hud_fixture()
    sim.state.follow_mastery=""
    game.mastery_stage=1;game._open("mastery");await frames(14)
    await shot("30_mastery_follow")
    sim.state.follow_mastery="1:hunt";game._refresh_panel(true);await frames(8)
    await shot("31_mastery_unfollow")
    game._open("missions");await frames(14)
    await shot("32_missions_follow")
    game._open("prestige");await frames(14)
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    for node in game.rows.find_children("*","Button",true,false):
        if str(node.text) in [tr("FOLLOW"),tr("UNFOLLOW")]:
            scroll.ensure_control_visible(node);break
    await frames(6)
    await shot("33_prestige_follow")
    game._close()

func upgrades() -> void:
    fresh()
    sim.state.coins=5000.0
    var g: int=sim.nearest_group()
    sim.state.discovered[str(g)]=true
    game.group=g;game.enemy_tab=1;game._open("enemy");await frames(14)
    await shot("40_enemy_upgrades")
    game._close()

## The celebration at the real camera zoom over Winter I, with 9 owned cards (a typical early collection)
## and with 30 (a large one), at fixed moments of the sequence.
func vfx() -> void:
    for count in [9,30]:
        fresh()
        var ids: Array=sim.catalog.campaign.cards.keys()
        for i in range(mini(count,ids.size())):sim.state.owned_cards.append(ids[i])
        await frames(8)
        var fx=game.world.prestige_fx
        fx.play()
        # Real playback (particles included), captured as each moment is reached.
        for t in fx.CAPTURE_MOMENTS:
            while fx.active and fx.clock<float(t):await get_tree().process_frame
            await shot("50_vfx_%dcards_t%03d" % [count,int(float(t)*100)])
        fx.stop()
    # The same moments at the minimum and maximum camera zoom (the node compensates by sqrt(2 / zoom)).
    for zoom in [1.0,3.0]:
        SettingsState.set_camera_zoom(zoom);await frames(6)
        var fx=game.world.prestige_fx
        fx.play()
        for t in [1.0,1.95,2.4]:
            while fx.active and fx.clock<t:await get_tree().process_frame
            await shot("51_vfx_zoom%d_t%03d" % [int(zoom),int(t*100)])
        fx.stop()
    SettingsState.set_camera_zoom(2.0)
