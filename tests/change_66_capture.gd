extends "res://tests/change_65_capture.gd"
## Change 66 rendered capture and bounds audit (windowed at 432x960 and 540x960, not headless):
##   Godot --path . --resolution 432x960 tests/change_66_capture.tscn -- --no-autosave --first-run-complete [--out=<dir>]
## Reuses the Change 65 capture helpers (shot, audit: BOUNDS / TRUNCATED / CLIPPED lines). Surfaces: the
## Guided Map Mastery lesson (HUD chip, the five goals with the arrow on Close, the World route's Map
## Mastery button and Details), the enemy Achievements tab (damage only), Player Upgrades with the Focused
## Farming description (locked and owned) and the Gems tab (Gem Chance 10), and the Help cards Player
## Upgrades, Map Details & Mastery and Advanced Farming. State set directly is a fixture (labelled).

func run() -> void:
    var root:="user://change_66_capture/"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--out="):root=arg.trim_prefix("--out=").trim_suffix("/")+"/"
    var view:=Vector2(DisplayServer.window_get_size())
    out=root+"%dx%d/" % [int(view.x),int(view.y)]
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;viewer=game.help_viewer
    sim.set_physics_process(false)
    await mastery_lesson_shots()
    await achievement_shots()
    await upgrade_shots()
    await help_card_shots()
    print("CHANGE_66_CAPTURE ",ProjectSettings.globalize_path(out)," PROBLEMS ",problems)
    get_tree().quit(0)

func at_mastery_lesson() -> void:
    fresh("guided")
    var flow=sim.campaign.guided
    flow.data().done=flow.STEPS.slice(0,flow.STEPS.find("map_mastery")) # fixture: at the lesson
    var snow: Dictionary={}
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id=="boss-snowman":snow=e
    var keep:=Vector2(sim.state.player.x,sim.state.player.y)
    sim.state.player.x=snow.x;sim.state.player.y=snow.y+40;sim.campaign.reveal();sim.campaign.evaluate() # fixture: Snowman found
    sim.state.player.x=keep.x;sim.state.player.y=keep.y
    await frames(2)
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()
    game.world.follow_player()
    await frames(30)

func mastery_lesson_shots() -> void:
    await at_mastery_lesson()
    await shot("01_mastery_chip_pointer")
    audit("mastery_chip",game)
    game.get_node("Safe/Layout/Map/Mastery").pressed.emit();await frames(20)
    await shot("02_mastery_goals_close")
    audit("mastery_goals",game)
    game.get_node("Sheet/Margin/Content/Scroll").scroll_vertical=100000;await frames(6)
    await shot("03_mastery_goals_scrolled")
    game._close();await frames(4)
    await at_mastery_lesson()
    game._open("world");await frames(20)
    await shot("04_mastery_world_button")
    audit("mastery_world",game)
    for b in game.rows.find_children("*","Button",true,false)+game.actions.find_children("*","Button",true,false):
        if b.get_meta("guide","")=="mastery" and b.is_visible_in_tree():b.pressed.emit();break
    await frames(20)
    await shot("05_mastery_overview_details")
    audit("mastery_overview",game)
    game._close();await frames(4)

func achievement_shots() -> void:
    fresh("none")
    var g:=0
    sim.state.group_kills[g]=300 # fixture: 3 milestones
    for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,int(v)) # fixture: spot found
    game.group=g;game.enemy_tab=2;game._open("enemy");await frames(20)
    await shot("10_enemy_achievements")
    audit("enemy_achievements",game)
    game._close();await frames(4)

func upgrade_shots() -> void:
    fresh("none");sim.state.gems=10.0 # fixture: 10 Gems
    game.player_tab=0;game._open("upgrades");await frames(20)
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("upgrade","")=="focus":game.get_node("Sheet/Margin/Content/Scroll").ensure_control_visible(b)
    await shot("20_upgrades_focus_locked")
    audit("upgrades_focus_locked",game)
    game.player_tab=3;game._refresh_panel(true);await frames(20)
    await shot("21_upgrades_gems_tab")
    audit("upgrades_gems",game)
    sim.state.upgrades["focus"]=1 # fixture: owned
    game.player_tab=0;game._refresh_panel(true);await frames(20)
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("upgrade","")=="focus":game.get_node("Sheet/Margin/Content/Scroll").ensure_control_visible(b)
    await frames(6)
    await shot("22_upgrades_focus_owned")
    audit("upgrades_focus_owned",game)
    game._close();await frames(4)

func help_card_shots() -> void:
    fresh("none")
    var ids: Array=HelpCards.ids()
    for pair in [["player_upgrades",1.2],["player_upgrades",3.0],["map_details_mastery",6.6],["advanced_farming",4.0]]:
        viewer.open_help("help_all",ids.find(pair[0]))
        freeze(pair[0],float(pair[1]))
        await shot("30_card_%s_%s" % [pair[0],str(pair[1]).replace(".","_")])
        audit("card_"+str(pair[0]),viewer.panel)
        viewer.demo.playing=true
    viewer.close_viewer();await frames(2)
