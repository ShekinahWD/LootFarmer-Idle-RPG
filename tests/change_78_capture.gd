extends Node
## Change 78 rendered desktop evidence (not a gate, not Android validation): the merge preview beside each stat
## (weapon, outfit comparison card, merge cap), a boss outfit with its two boss attributes, the supply panel and
## the world's supply name label, and a boss's cheaper Auto-Collect / Auto-Merge in the enemy panel.
## Run windowed (432x960, 540x960; the monitor clamps taller windows):
##   godot --path . --resolution 540x960 res://tests/change_78_capture.tscn -- --probe --profile=probe-c78cap
##       --no-autosave --first-run-complete --shape=540x960
## --hidpi renders the game offscreen at 1080x1920 (a 1.5x phone) and saves the supply panel title with the
## Change 78 text filtering and with the earlier inherited nearest filtering, for a side-by-side crop.
## Output: tests/tmp/change_78_capture/<shape>_<name>.png (ignored by Git).
var game
var sim
var shape:="540x960"
var host: Viewport

func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame

func shot(name_: String) -> void:
    await frames(4)
    var dir:="res://tests/tmp/change_78_capture/"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    var file:=dir+shape+"_"+name_+".png"
    host.get_texture().get_image().save_png(ProjectSettings.globalize_path(file))
    print("SHOT ",file)

func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game._cancel_confirm()
    game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide();game.toast_time=0.0
    sim.state.gems=10000.0 # fixture
    for i in range(6):sim.buy_upgrade("gear_slots") # fixture: room for the items shown
    sim.state.gems=0.0

func run() -> void:
    var hidpi:=false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
        elif arg=="--hidpi":hidpi=true
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    host=get_viewport()
    if hidpi:
        shape="1080x1920"
        var vp:=SubViewport.new()
        vp.size=Vector2i(1080,1920);vp.size_2d_override=Vector2i(720,1280);vp.size_2d_override_stretch=true
        vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
        add_child(vp);host=vp
    game=load("res://scenes/game/main.tscn").instantiate();host.add_child(game);sim=game.sim
    await frames(10)
    if hidpi:
        await hidpi_run()
    else:
        await shots()
    print("CHANGE_78_CAPTURE complete shape=%s" % shape)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit()

func shots() -> void:
    # 1. Equipped weapon: the next merge's Damage gain beside the stat.
    fresh()
    sim.add_item("iron_sword",4);sim.state.items.iron_sword.merge=7;sim.equip("iron_sword") # fixture
    sim.add_item("boss-cyan-robot_outfit",3);sim.state.items["boss-cyan-robot_outfit"].merge=12;sim.equip("boss-cyan-robot_outfit") # fixture
    game.selected="iron_sword";game._open("item");await frames(14)
    await shot("01_weapon_merge_gain")
    # 2. An outfit not equipped: the comparison card with the merge gain and the equip deltas.
    sim.add_item("unit-yellow-cap_outfit_t2",5);sim.state.items["unit-yellow-cap_outfit_t2"].merge=30 # fixture
    game.selected="unit-yellow-cap_outfit_t2";game._open("item");await frames(14)
    await shot("02_outfit_compare_merge_gain")
    # 3. A weapon at its merge cap: no gain, the stock bonus line instead.
    sim.state.items.iron_sword.merge=sim.merge_cap("iron_sword") # fixture
    game.selected="iron_sword";game._open("item");await frames(14)
    await shot("03_weapon_at_cap")
    # 4. A boss outfit collected from its boss: two boss attributes and the explanation.
    var g: int=sim.campaign.group_id("boss-gray-cat")
    sim._drop("boss-gray-cat_outfit_t2",{"group":g,"x":200.0,"y":200.0})
    sim.collect(int(sim.state.pickups.back().uid))
    game.selected="boss-gray-cat_outfit_t2";game._open("item");await frames(14)
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    for l in game.rows.find_children("*","Label",true,false):
        if str(l.text).contains(tr("ITEM_BOSS_BONUS")):
            scroll.scroll_vertical=int(l.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical)-160;break
    await frames(4)
    await shot("04_boss_outfit_attributes")
    # 5. The supply panel (Health Potion).
    sim.add_item("potion",12)
    game.selected="potion";game._open("item");await frames(14)
    await shot("05_supply_panel_potion")
    # 6. The world's supply name label as the potion is used (camera zoomed in).
    game._close();await frames(4)
    sim.state.player.hp=sim.stats().hp*.4 # fixture: hurt, so the potion can be used
    sim.use_item("potion");await frames(3)
    await shot("06_world_supply_name")
    # 7. A boss's automation upgrades: the cheaper Auto-Collect and Auto-Merge.
    fresh()
    var b: int=sim.campaign.group_id("boss-red-fox")
    sim.state.unlocked_stage=5;sim.campaign.discover_spot(b,2) # fixture: Autumn I reached, Red Fox found
    game.group=b;game.enemy_tab=1;game._open("enemy");await frames(14)
    for l in game.rows.find_children("*","Label",true,false):
        if str(l.text)==tr("SECTION_AUTOMATION"):
            scroll.scroll_vertical=int(l.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical)-40;break
    await frames(4)
    await shot("07_boss_automation_prices")

func hidpi_run() -> void:
    fresh()
    sim.add_item("coin_boost",5)
    game.selected="coin_boost";game._open("item");await frames(14)
    await shot("hidpi_supply_after")
    # The earlier look: every label back on the UI root's inherited nearest filtering.
    for l in game.find_children("*","Label",true,false):l.texture_filter=CanvasItem.TEXTURE_FILTER_PARENT_NODE
    await frames(4)
    await shot("hidpi_supply_before")
