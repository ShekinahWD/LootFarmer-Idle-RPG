extends "res://tests/change_65_capture.gd"
## Change 69 rendered capture and bounds audit (windowed at 432x960 and 540x960, not headless):
##   Godot --path . --resolution 432x960 tests/change_69_capture.tscn -- --no-autosave --first-run-complete [--out=<dir>]
## Reuses the Change 65 capture helpers (shot, audit: BOUNDS / TRUNCATED / CLIPPED lines). Surfaces: the map's
## contextual stack (Achievements, Upgrades, Auto Farm Locked / OFF / ON), group B OFF while A is farmed with
## the walking countdown, the countdown with a toast, the enemy panel Farm ON, Settings mutes, Missions
## Automatic Claiming, the Guided pointer on the quick button, the Advanced Farming help card, and a
## pseudo-long label run. State set directly is a fixture (labelled).
var a: Array=[]

func run() -> void:
    var root:="user://change_69_capture/"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--out="):root=arg.trim_prefix("--out=").trim_suffix("/")+"/"
    var view:=Vector2(DisplayServer.window_get_size())
    out=root+"%dx%d/" % [int(view.x),int(view.y)]
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;viewer=game.help_viewer
    sim.set_physics_process(false)
    TranslationServer.set_locale("en")
    for g in sim.catalog.stages[0].groups:
        if not sim.catalog.groups[int(g)].boss:a.append(int(g))
    await stack_shots()
    await countdown_shots()
    await toggle_shots()
    await guided_shot()
    await help_shot()
    await long_label_shots()
    print("CHANGE_69_CAPTURE ",ProjectSettings.globalize_path(out)," PROBLEMS ",problems)
    get_tree().quit(0)

func setup(owned: bool) -> void:
    fresh("none")
    HelpCards.progress(sim.state.tutorial).basic_done=true
    for g in a:
        for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,int(v)) # fixture: Winter I spots found
    if owned:sim.state.upgrades["focus"]=1 # fixture: Focused Farming owned
    game.stick_input=Vector2.ZERO;sim.movement=Vector2.ZERO
    await stand(a[0],2)

func stand(g: int,v: int) -> void:
    var at: Vector2=sim.campaign.spot(g,v)+Vector2(0,60)
    sim.state.player.x=at.x;sim.state.player.y=at.y;sim.clear_target();sim.campaign.reveal()
    game.world.follow_player()
    await frames(20)
    game._refresh_combat_achievement()

func hud_audit(surface: String) -> void:
    audit(surface,game.get_node("Safe/Layout/Map"))
    var stack: Array=["Achievement","EnemyUpgrades","QuickFarm"].map(func(n):return game.get_node("Safe/Layout/Map/"+n))
    for i in range(2):
        if stack[i].get_global_rect().end.y>stack[i+1].get_global_rect().position.y:
            problems+=1;print("OVERLAP ",surface," ",stack[i].name," ",stack[i+1].name)
    for b in stack:
        if b.size.y<56:problems+=1;print("SMALL ",surface," ",b.name," ",b.size)
    var js: Rect2=game.get_node("Safe/Layout/Map/Joystick").get_global_rect()
    if stack[2].get_global_rect().intersects(js):problems+=1;print("OVERLAP ",surface," QuickFarm joystick")
    if game.get_node("FocusCountdown").visible and game.get_node("FocusCountdown").get_global_rect().intersects(js):problems+=1;print("OVERLAP ",surface," countdown joystick")

func stack_shots() -> void:
    await setup(false)
    await stand(a[0],2)
    await shot("01_stack_locked");hud_audit("stack_locked")
    await setup(true)
    await stand(a[0],2)
    await shot("02_stack_off");hud_audit("stack_off")
    sim.focus(a[0],2);game._refresh_combat_achievement()
    await shot("03_stack_on");hud_audit("stack_on")

func walk_for(seconds: float) -> void:
    game.stick_input=Vector2.RIGHT
    await frames(2)
    for i in range(roundi(seconds/.05)):sim.step(.05)
    await frames(4)

func countdown_shots() -> void:
    await setup(true)
    sim.focus(a[0],2)
    await stand(a[1],2) # fixture: walked over to group B
    await walk_for(.6)
    await shot("04_group_b_off_countdown_5");hud_audit("b_off_countdown")
    await walk_for(2.0)
    game._toast(tr("FOCUS_UNLOCKED"));await frames(8)
    await shot("05_countdown_3_with_toast");hud_audit("countdown_toast")
    game.stick_input=Vector2.ZERO;await frames(4)
    sim.step(.05);await frames(6)
    await shot("06_released_resumes");hud_audit("released")
    await walk_for(5.1)
    await shot("07_after_5s_off");hud_audit("after_5s")
    game.stick_input=Vector2.ZERO;await frames(4)

func toggle_shots() -> void:
    await setup(true)
    sim.focus(a[0],2)
    game.group=a[0];game.enemy_tab=0;game.enemy_variant=2;game._open("enemy");await frames(6)
    await shot("08_enemy_farm_on");sheet_audit("enemy_farm_on")
    game.enemy_variant=0;game._refresh_panel(true);await frames(6)
    await shot("09_enemy_farm_off_other_spot");sheet_audit("enemy_farm_off")
    game._close()
    var keep_g: bool=SettingsState.mute_gameplay
    var keep_s: bool=SettingsState.mute_special
    SettingsState.set_mute_gameplay(true);SettingsState.set_mute_special(false) # fixture: one ON, one OFF
    game._open("settings");await frames(6)
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("setting","")=="mute_gameplay":game.get_node("Sheet/Margin/Content/Scroll").ensure_control_visible(b)
    await shot("10_settings_mutes");sheet_audit("settings_mutes")
    game._close()
    SettingsState.set_mute_gameplay(keep_g);SettingsState.set_mute_special(keep_s)
    sim.state.upgrades["mission_claim"]=1;sim.state.mission_auto=false # fixture: Auto Claim owned, OFF
    game._open("missions");await frames(6)
    var t: Control=_meta("mission_auto_toggle")
    if t!=null:game.get_node("Sheet/Margin/Content/Scroll").ensure_control_visible(t)
    await shot("11_missions_auto_off");sheet_audit("missions_off")
    sim.state.mission_auto=true;game._refresh_panel(true);await frames(6)
    t=_meta("mission_auto_toggle")
    if t!=null:game.get_node("Sheet/Margin/Content/Scroll").ensure_control_visible(t)
    await shot("12_missions_auto_on")
    game._close()

func guided_shot() -> void:
    fresh("guided")
    var flow=sim.campaign.guided
    flow.data().done=flow.STEPS.duplicate() # fixture: every Guided lesson finished
    for g in a:
        for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,int(v))
    sim.state.upgrades["focus"]=1
    sim.campaign.focus_hint=a[0];game.guide.focus_shown=0 # fixture: just bought Focused Farming
    await stand(a[0],2)
    await frames(20)
    await shot("13_guided_points_quick");hud_audit("guided_quick")
    print("GUIDE step ",game.guide.step," target ",game.guide.target)

func help_shot() -> void:
    fresh("none")
    HelpCards.progress(sim.state.tutorial).basic_done=true
    game.help_page="home";game._open("help");await frames(4)
    viewer.open_help("help_topic",HelpCards.ids().find("advanced_farming"))
    freeze("advanced_farming",5.2)
    await shot("14_help_advanced_farming");audit("help_card",viewer.panel)
    viewer.demo.playing=true;viewer.close_viewer();await frames(2)
    game._close()

func long_label_shots() -> void:
    # Godot's pseudolocalization (accents, 40% expansion, brackets) stands in for the longest locales.
    ProjectSettings.set_setting("internationalization/pseudolocalization/expansion_ratio",0.4)
    TranslationServer.pseudolocalization_enabled=true
    TranslationServer.reload_pseudolocalization()
    await setup(true)
    sim.focus(a[0],2)
    await stand(a[1],2)
    await walk_for(.6)
    await shot("15_pseudo_long");hud_audit("pseudo_long")
    print("PSEUDO quick '",game.get_node("Safe/Layout/Map/QuickFarm").text,"' countdown '",game.get_node("FocusCountdown/Text").text,"'")
    game.stick_input=Vector2.ZERO
    TranslationServer.pseudolocalization_enabled=false
