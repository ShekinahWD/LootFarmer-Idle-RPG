extends Node
## Change 69 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## - The map's contextual stack: Achievements -> Upgrades -> one Auto Farm button, vertically, touch-sized.
##   OFF red (ToggleOff), ON green (ToggleOn), Locked grey (ToggleLocked) before the global 25-Gem purchase;
##   locked taps explain and open Player Upgrades without charging. Group A ON / group B OFF; switching
##   updates both the quick button and the enemy panel's Farm button (one action: sim.focus).
## - Walking countdown: 5 continuous real seconds of manual walking stop Focused Farming once; shorter walks
##   (and two separate 3 s walks) keep it and the hero resumes; jitter, pause, hold, death, non-manual
##   motion and game speed never advance it; save/load drops only the countdown; explicit taps act at once.
## - The countdown label (5..1) above the joystick; hidden under a panel.
## - Toggle audit: every tr("ON"/"OFF"/STATE_*_CAPS) button in game_ui.gd goes through _toggle_style;
##   rendered Settings mutes, Missions auto-claim and the enemy Farm reflect their real state.
## - Guided: the Focused Farming hint points at the live quick button near the hinted type.
## Run: Godot --headless --path . tests/change_69_probe.tscn -- --no-autosave --first-run-complete
## Pass --realtime to also time a held stick at 3x game speed against the wall clock (about 5 s).
const HelpCards=preload("res://scripts/game/help_cards.gd")
var checks:=0
var failures:=0
var game
var sim
var guide
var events: Array=[]
var a: Array=[]
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;guide=game.guide
    sim.event.connect(func(key: String)->void:events.append(key))
    await frames()
    for g in sim.catalog.stages[0].groups:
        if not sim.catalog.groups[int(g)].boss:a.append(int(g))
    await stack_checks()
    await sync_checks()
    countdown_checks()
    await countdown_ui_checks()
    await toggle_checks()
    await guided_checks()
    if OS.get_cmdline_user_args().has("--realtime"):await realtime_check()
    Engine.time_scale=1.0
    print("CHANGE_69_CHECKS %d FAILURES %d" % [checks,failures])
    get_tree().quit(1 if failures>0 else 0)

func fresh(mode:="none") -> void:
    get_tree().paused=false
    Engine.time_scale=1.0
    if game.help_viewer.visible:game.help_viewer.hide()
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode=mode
    if mode!="guided":sim.campaign.onboarding.reveal_all(true)
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()
    game.stick_input=Vector2.ZERO;sim.movement=Vector2.ZERO
    sim.state.player.quiet=1e9
    for e in sim.state.enemies:e.aggro=false
    sim.campaign.focus_hint=-1;sim.clear_target()
    for g in a:
        for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,v) # fixture: every Winter I spot found
    events.clear()
func own_focus() -> void:
    sim.state.gems=float(sim.state.gems)+25;sim.buy_upgrade("focus")
func stand_at(g: int,v: int) -> void:
    var at: Vector2=sim.campaign.spot(g,v)+Vector2(0,40)
    sim.state.player.x=at.x;sim.state.player.y=at.y;sim.clear_target()
func quick() -> Button:return game.get_node("Safe/Layout/Map/QuickFarm")
func refresh() -> void:game._refresh_combat_achievement()
func press_quick() -> void:
    game.quick_changed_msec=-100000 # fixture: the settle delay has passed
    quick().pressed.emit()
func button_meta(root: Node,key: String) -> Button:
    for b in root.find_children("*","Button",true,false):
        if b.get_meta("guide","")==key or b.get_meta("setting","")==key:return b
    return null
func reload() -> void:
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
func walk(seconds: float,dt:=.05,direction:=Vector2.RIGHT) -> void:
    sim.movement=direction
    for i in range(roundi(seconds/dt)):sim.step(dt)
func release(seconds:=.1) -> void:
    sim.movement=Vector2.ZERO
    for i in range(roundi(seconds/.05)):sim.step(.05)

# ---------------------------------------------------------------- stack, locked, purchase

func stack_checks() -> void:
    print("-- contextual stack")
    fresh()
    stand_at(a[0],2);refresh();await frames(2)
    var ach: Button=game.get_node("Safe/Layout/Map/Achievement")
    var up: Button=game.get_node("Safe/Layout/Map/EnemyUpgrades")
    var q:=quick()
    check(ach.visible and up.visible and q.visible,"Near a discovered type: Achievements, Upgrades and Auto Farm are shown")
    var r1:=ach.get_global_rect();var r2:=up.get_global_rect();var r3:=q.get_global_rect()
    # Change 72: one row in the left rail (Achievements with its count, then the Upgrades and Auto Farm tiles).
    check(r1.end.x<=r2.position.x and r2.end.x<=r3.position.x and is_equal_approx(r1.position.y,r3.position.y),"One row: Achievements -> Upgrades -> Auto Farm (%s / %s / %s)" % [r1,r2,r3])
    check(is_equal_approx(r1.size.y,r3.size.y) and r2.size.is_equal_approx(r3.size),"Same height; the two tiles share one size")
    check(r3.size.y>=56 and r3.size.x>=56,"Touch-sized (%s)" % r3.size)
    check(not r3.intersects(game.get_node("Safe/Layout/Map/Joystick").get_global_rect()) and not r3.intersects(game.get_node("Safe/Layout/Map/MiniMap").get_global_rect()),"Clear of the joystick and minimap")
    check(game.get_node("Safe/Layout/Map").find_children("QuickFarm*","Button",false,false).size()==1,"Exactly one Auto Farm button")
    # Locked
    check(not sim.focus_owned() and str(q.get_meta("state_text"))==tr("AUTO_FARM_LOCKED") and q.text=="" and q.tooltip_text.contains(tr("AUTO_FARM_LOCKED")) and q.theme_type_variation==&"ToggleLocked","Before the purchase: 'Auto Farm · Locked', grey locked style")
    check(q.tooltip_text.contains(tr("FOCUS_LOCKED_GLOBAL")),"The locked tooltip states why")
    sim.state.gems=100.0
    game.notice.text="";game.toast_queue.clear()
    press_quick();await frames(4)
    check(int(sim.state.focus)==-1 and float(sim.state.gems)==100.0 and not sim.focus_owned(),"A locked tap starts nothing and charges nothing")
    check(game.sheet.visible and game.panel=="upgrades" and game.player_tab==0 and button_meta(game.rows,"buy_focus")!=null,"It opens Player Upgrades at the 25-Gem Focused Farming purchase")
    check(game.notice.text==tr("FOCUS_LOCKED_GLOBAL") or game.toast_queue.has(tr("FOCUS_LOCKED_GLOBAL")),"…and explains the restriction")
    button_meta(game.rows,"buy_focus").pressed.emit();await frames(4)
    check(sim.focus_owned() and float(sim.state.gems)==75.0,"Buying it there charges 25 Gems once")
    game._close();await frames(2)
    stand_at(a[0],2);refresh()
    check(str(q.get_meta("state_text"))==tr("AUTO_FARM_STATE") % tr("STATE_OFF_CAPS") and q.text==tr("STATE_OFF_CAPS") and q.theme_type_variation==&"ToggleOff","Owned, not farming: 'Auto Farm OFF' in red")
    press_quick();refresh()
    check(sim.focus_active(a[0],2) and float(sim.state.gems)==75.0,"OFF tap starts farming this spot, no second charge")
    check(str(q.get_meta("state_text"))==tr("AUTO_FARM_STATE") % tr("STATE_ON_CAPS") and q.text==tr("STATE_ON_CAPS") and q.theme_type_variation==&"ToggleOn","…and the button reads 'Auto Farm ON' in green")
    press_quick();refresh()
    check(int(sim.state.focus)==-1 and q.text==tr("STATE_OFF_CAPS"),"ON tap stops farming at once")
    # Settle guard: a tap right after the button changed target is ignored.
    press_quick();refresh()
    game.quick_changed_msec=Time.get_ticks_msec()
    q.pressed.emit()
    check(sim.focus_active(a[0],2),"A tap within 400 ms of a target change is ignored (no accidental toggle)")
    # The automation of other upgrades is independent.
    check(sim.level("collect",a[0])==0 and sim.level("merge_gear",a[0])==0,"Auto-Collect / Auto-Merge untouched")
    # Hidden until the Upgrades route exists.
    fresh("guided");stand_at(a[0],2);refresh()
    check(not quick().visible or game.revealed("upgrades"),"Guided: the quick button appears only with the Upgrades route")

# ---------------------------------------------------------------- A/B and panel synchronisation

func sync_checks() -> void:
    print("-- A/B and panel sync")
    fresh();own_focus()
    stand_at(a[0],2);refresh();press_quick();refresh()
    check(sim.focus_active(a[0],2),"Group A is farmed")
    # Walk toward B: while walking, the controls follow the group approached.
    stand_at(a[1],2);sim.movement=Vector2.RIGHT;refresh()
    check(game.combat_group==a[1] and quick().theme_type_variation==&"ToggleOff" and game.get_node("Safe/Layout/Map/EnemySection").text==sim.catalog.groups[a[1]].name,"Near group B while A is farmed: B's button is OFF (red), labelled B")
    check(int(sim.state.focus)==a[0],"…and A is still the target")
    press_quick();sim.movement=Vector2.ZERO;refresh()
    check(sim.focus_active(a[1],2) and quick().theme_type_variation==&"ToggleOn","OFF on B switches the target to B at once (green)")
    # The enemy panel's Farm button reads the same state.
    game.group=a[0];game.enemy_variant=2;game.enemy_tab=0;game._open("enemy");await frames(4)
    var farm: Button=button_meta(game.rows,"focus_toggle")
    check(farm!=null and farm.text.ends_with(tr("OFF")) and farm.theme_type_variation==&"ToggleOff","A's panel Farm now reads OFF (red)")
    game.group=a[1];game._refresh_panel(true);await frames(2)
    farm=button_meta(game.rows,"focus_toggle")
    check(farm!=null and farm.text.ends_with(tr("ON")) and farm.theme_type_variation==&"ToggleOn","B's panel Farm reads ON (green)")
    farm.pressed.emit();await frames(2)
    check(int(sim.state.focus)==-1,"The panel's Farm stops it (the same sim.focus action)")
    game._close();await frames(2)
    stand_at(a[1],2);refresh()
    check(quick().theme_type_variation==&"ToggleOff","…and the quick button follows to OFF")
    # Another spot of the same type is a different target.
    sim.focus(a[1],0);stand_at(a[1],3);refresh()
    check(quick().theme_type_variation==&"ToggleOn" and int(quick().get_meta("variant"))==0,"Focused on a type, its button shows the selected spot (ON) rather than switching spots")
    # Locked panel style
    fresh()
    game.group=a[0];game.enemy_variant=2;game._open("enemy");await frames(4)
    var locked: Button=button_meta(game.rows,"focus_locked")
    check(locked!=null and locked.disabled and locked.theme_type_variation==&"ToggleLocked","Unowned: the panel's Farm is the grey locked style, with its reason")
    game._close()

# ---------------------------------------------------------------- the walking countdown

func countdown_checks() -> void:
    print("-- walking countdown")
    fresh();own_focus();stand_at(a[0],2);sim.focus(a[0],2);events.clear()
    walk(1.0)
    check(int(sim.state.focus)==a[0] and sim.focus_walk_remaining()==4,"1 s of walking: still farming, countdown at 4")
    walk(3.85)
    check(int(sim.state.focus)==a[0] and sim.focus_walk_remaining()==1,"4.85 s: still farming, countdown at 1")
    var away: float=sim.position_of(sim.state.player).distance_to(sim.farming_position())
    release(.05)
    check(sim.focus_walk_time==0.0 and sim.focus_walk_remaining()==0 and int(sim.state.focus)==a[0],"Releasing cancels the countdown and keeps the target")
    release(2.0)
    check(sim.position_of(sim.state.player).distance_to(sim.farming_position())<away-20,"…and the hero walks back to farm it (%.0f -> %.0f)" % [away,sim.position_of(sim.state.player).distance_to(sim.farming_position())])
    walk(3.0);release(.1);walk(3.0)
    check(int(sim.state.focus)==a[0] and not events.has("FOCUS_WALK_STOPPED"),"Two separate 3 s walks never add up")
    release(.1)
    walk(5.0)
    check(int(sim.state.focus)==-1 and events.count("FOCUS_WALK_STOPPED")==1,"One continuous 5 s walk stops farming exactly once")
    walk(6.0)
    check(events.count("FOCUS_WALK_STOPPED")==1 and sim.focus_walk_time==0.0,"Further walking stops nothing more")
    release()
    # Jitter below the dead zone
    sim.focus(a[0],2);events.clear()
    walk(6.0,.05,Vector2(.05,0))
    check(int(sim.state.focus)==a[0] and sim.focus_walk_time==0.0,"Joystick jitter inside the dead zone never counts")
    release()
    # Game speed: 3x simulation time counts as one third.
    Engine.time_scale=3.0
    walk(5.0)
    check(int(sim.state.focus)==a[0] and sim.focus_walk_remaining()==4,"At 3x: 5 simulated seconds are only ~1.67 real seconds (countdown %d)" % sim.focus_walk_remaining())
    walk(9.9)
    check(int(sim.state.focus)==a[0],"At 3x: 14.9 simulated seconds (4.97 real) still farming")
    walk(.2)
    check(int(sim.state.focus)==-1,"At 3x: stops at 15 simulated = 5 real seconds")
    Engine.time_scale=1.0;release()
    # Pause / hold / background interrupt a walk.
    sim.focus(a[0],2)
    walk(3.0);get_tree().paused=true;sim.step(.05);get_tree().paused=false
    check(sim.focus_walk_time==0.0,"A pause resets the walk")
    walk(3.0);sim.held=true;sim.step(.05);sim.held=false
    check(sim.focus_walk_time==0.0,"A held world (full-screen panel) resets the walk")
    walk(3.0);sim.suspended=true;sim.step(.05);sim.suspended=false
    check(sim.focus_walk_time==0.0 and int(sim.state.focus)==a[0],"Background resets the walk; the target stays")
    release()
    # Automatic movement never counts.
    stand_at(a[0],2);sim.state.player.x+=300;release(6.0)
    check(int(sim.state.focus)==a[0] and sim.focus_walk_time==0.0,"Auto-navigation back to the spot never counts")
    # Death and respawn
    walk(3.0)
    sim.state.player.hp=0;sim._kill(sim.state.player)
    sim.movement=Vector2.RIGHT
    var dead_counted:=0.0
    var guard:=0
    while sim.state.player.hp<=0 and guard<1000:
        sim.step(.05);guard+=1
        if sim.state.player.hp<=0:dead_counted=maxf(dead_counted,sim.focus_walk_time)
    check(dead_counted==0.0 and guard>20,"A held stick while dead never counts (%.1f s dead)" % (guard*.05))
    release(.1)
    check(int(sim.state.focus)==a[0] and sim.state.player.hp>0 and sim.focus_walk_time==0.0,"Respawn keeps the target with no countdown")
    # Save/load mid-countdown
    walk(3.0)
    reload()
    check(int(sim.state.focus)==a[0] and int(sim.state.focus_variant)==2 and sim.focus_walk_time==0.0,"Reload mid-countdown keeps the target, drops only the countdown")
    check(not JSON.stringify(sim.snapshot()).contains("focus_walk"),"The countdown is never saved")
    # Explicit stop and switch
    walk(3.0)
    check(sim.focus(a[0],2) and int(sim.state.focus)==-1 and sim.focus_walk_time==0.0,"Explicit ON tap mid-countdown stops at once")
    sim.focus(a[0],2);walk(3.0)
    check(sim.focus(a[1],2) and int(sim.state.focus)==a[1] and sim.focus_walk_time==0.0,"Explicit switch to another type cancels the countdown")
    release()
    # Manual targeting (existing rule) still ends focus at once.
    var enemy: Dictionary={}
    for e in sim.state.enemies:
        if int(e.group)==a[1] and e.hp>0:enemy=e;break
    sim.state.player.x=enemy.x-30;sim.state.player.y=enemy.y;sim.campaign.reveal()
    if sim.select_target(str(enemy.id)):check(int(sim.state.focus)==-1,"Existing rule kept: choosing a target by hand ends Focused Farming")

func countdown_ui_checks() -> void:
    print("-- countdown UI")
    fresh();own_focus();stand_at(a[0],2);sim.focus(a[0],2)
    var box: PanelContainer=game.get_node("FocusCountdown")
    game.stick_input=Vector2.RIGHT
    await frames(2)
    for i in range(20):sim.step(.05) # 1 s
    await frames(3)
    check(box.visible and box.get_node("Text").text==tr("FOCUS_WALK_COUNTDOWN") % 4,"Held stick: '%s'" % box.get_node("Text").text)
    var js: Rect2=game.get_node("Safe/Layout/Map/Joystick").get_global_rect()
    check(box.get_global_rect().end.y<=js.position.y and game.get_node("Safe/Layout/Map").get_global_rect().encloses(box.get_global_rect()),"Above the joystick, inside the map")
    game._toast("probe toast");await frames(3)
    check(not game.get_node("Toast").visible or not game.get_node("Toast").get_global_rect().intersects(box.get_global_rect()),"A toast never covers it")
    game._open("upgrades");await frames(3)
    check(not box.visible and sim.movement==Vector2.ZERO,"A panel hides it (and stops manual walking)")
    sim.step(.05)
    check(sim.focus_walk_time==0.0,"…and the walk is reset")
    game._close();await frames(2)
    game.stick_input=Vector2.ZERO;await frames(2);sim.step(.05);await frames(2)
    check(not box.visible,"Released: hidden")
    game.stick_input=Vector2.RIGHT;await frames(2)
    for i in range(101):sim.step(.05)
    await frames(3)
    check(int(sim.state.focus)==-1 and not box.visible,"After 5 s: farming off, countdown gone")
    check(game.toast_queue.has(tr("FOCUS_WALK_STOPPED")) or game.get_node("Toast/Text").text==tr("FOCUS_WALK_STOPPED"),"…with a short confirmation")
    game.stick_input=Vector2.ZERO;await frames(2)

# ---------------------------------------------------------------- ON/OFF toggle audit

func toggle_checks() -> void:
    print("-- toggle audit")
    var unstyled: Array=[]
    for path in ["res://scripts/game/game_ui.gd","res://scripts/game/help_viewer.gd"]:
        unstyled.append_array(_unstyled_toggles(path))
    check(unstyled.is_empty(),"Every ON/OFF button in game_ui.gd and help_viewer.gd is styled by _toggle_style (unstyled: %s)" % str(unstyled))
    await rendered_toggle_checks()

func _unstyled_toggles(path: String) -> Array:
    var unstyled: Array=[]
    var lines:=FileAccess.get_file_as_string(path).split("\n")
    for i in range(lines.size()):
        var line: String=lines[i]
        if not (line.contains("_action(") or line.contains("_pinned(") or line.contains("_button.text=")) or line.strip_edges().begins_with("#") or line.strip_edges().begins_with("func "):continue
        if not (line.contains("tr(\"ON\"") or line.contains("tr(\"OFF\"") or line.contains("\"ON\" if") or line.contains("\"OFF\" if") or line.contains("STATE_ON_CAPS")):continue
        var styled: bool=line.contains("_toggle_style(")
        if not styled:
            # the call may be stored and styled on a following line (Missions auto-claim)
            for j in range(i+1,mini(i+8,lines.size())):
                if lines[j].contains("_toggle_style("):styled=true;break
        if not styled:unstyled.append(path.get_file()+":"+str(i+1))
    return unstyled

func rendered_toggle_checks() -> void:
    fresh()
    var mute_before: bool=SettingsState.mute_gameplay
    game._open("settings");await frames(4)
    var mute: Button=button_meta(game.rows,"mute_gameplay")
    check(mute!=null and mute.theme_type_variation==(&"ToggleOn" if SettingsState.mute_gameplay else &"ToggleOff"),"Settings mute reflects its real state (%s)" % mute.theme_type_variation)
    mute.pressed.emit();await frames(3)
    mute=button_meta(game.rows,"mute_gameplay")
    check(SettingsState.mute_gameplay!=mute_before and mute.theme_type_variation==(&"ToggleOn" if SettingsState.mute_gameplay else &"ToggleOff") and mute.text.ends_with(tr("ON" if SettingsState.mute_gameplay else "OFF")),"Toggling flips colour and label together")
    mute.pressed.emit();await frames(2)
    check(SettingsState.mute_gameplay==mute_before,"Setting restored")
    game._close()
    sim.state.upgrades["mission_claim"]=1 # fixture: Auto Claim owned
    sim.state.mission_auto=false
    game._open("missions");await frames(4)
    var auto: Button=button_meta(game.rows,"mission_auto_toggle")
    check(auto!=null and auto.theme_type_variation==&"ToggleOff" and auto.text.contains(tr("STATE_OFF_CAPS")),"Missions Automatic Claiming OFF: red with OFF")
    auto.pressed.emit();await frames(3)
    auto=button_meta(game.rows,"mission_auto_toggle")
    check(sim.state.mission_auto and auto.theme_type_variation==&"ToggleOn" and auto.text.contains(tr("STATE_ON_CAPS")),"…ON: green with ON")
    get_tree().paused=true;game._refresh_panel(true);await frames(2)
    auto=button_meta(game.rows,"mission_auto_toggle")
    check(auto.disabled and auto.text.contains(tr("STATE_ON_CAPS")),"Paused: blocked, but still states ON (not OFF)")
    get_tree().paused=false
    game._close()
    var viewer=game.help_viewer
    viewer.open_help("help_topic",HelpCards.ids().find("advanced_farming"));await frames(2)
    var was: bool=viewer.auto
    check(viewer.auto_button.theme_type_variation==(&"ToggleOn" if viewer.auto else &"ToggleOff"),"Help Auto-Advance reflects its state")
    viewer.toggle_auto();await frames(2)
    check(viewer.auto!=was and viewer.auto_button.theme_type_variation==(&"ToggleOn" if viewer.auto else &"ToggleOff") and viewer.auto_button.text.ends_with(tr("ON" if viewer.auto else "OFF")),"…and flips with it")
    if viewer.auto!=was:viewer.toggle_auto()
    viewer.close_viewer();sim.held=false;await frames(2)

# ---------------------------------------------------------------- Guided pointer

func guided_checks() -> void:
    print("-- guided pointer")
    fresh("guided")
    var flow=sim.campaign.guided
    flow.data().done=flow.STEPS.duplicate() # fixture: every Guided lesson finished (all menus revealed)
    sim.state.tutorial.seen.append("road_ahead") # fixture: the goals card already read
    own_focus()
    sim.campaign.focus_hint=a[0];guide.focus_shown=0
    stand_at(a[0],2);game.world.follow_player()
    await frames(30)
    refresh();await frames(10)
    check(quick().visible and game.combat_group==a[0],"The hinted type's quick button is on screen")
    check(guide.step=="focus_quick" and guide.target==quick(),"Guided points at the live Auto Farm button (step %s)" % guide.step)
    check(tr("GUIDE_FOCUS_QUICK_DETAIL").contains("5"),"Its caption states the 5-second walking rule")
    game.quick_changed_msec=-100000
    quick().pressed.emit();await frames(6)
    check(sim.focus_active(a[0],2) and guide.pending!="focus","Tapping it starts farming and ends the hint")
    fresh("basic");HelpCards.progress(sim.state.tutorial).basic_done=true # fixture: Basic opening finished
    own_focus();stand_at(a[0],2);await frames(10)
    check(sim.campaign.focus_hint==-1 and guide.pending!="focus","Basic: no Focused Farming pointer")

func realtime_check() -> void:
    print("-- real time at 3x")
    fresh();own_focus();stand_at(a[0],2);sim.focus(a[0],2)
    SettingsState.set_game_speed(3.0)
    sim.set_physics_process(true)
    game.stick_input=Vector2.RIGHT
    var t0:=Time.get_ticks_msec()
    while int(sim.state.focus)>=0 and Time.get_ticks_msec()-t0<12000:await get_tree().process_frame
    var took:=(Time.get_ticks_msec()-t0)/1000.0
    game.stick_input=Vector2.ZERO;sim.set_physics_process(false);SettingsState.set_game_speed(1.0)
    check(took>=4.8 and took<=5.6,"Held stick at 3x stops after %.2f real seconds (about 5)" % took)
