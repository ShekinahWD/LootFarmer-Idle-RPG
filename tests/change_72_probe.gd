extends Node
## Change 72 focused checks (HUD declutter, Layout B "edge rails"; real main scene and simulation; state set
## directly is labelled "fixture"):
## - Rails: the enemy controls in one row, the followed objectives as one-line pills under them, the minimap with
##   Map Explored on its lower edge, the zoom button, the Mastery and Next Stage chips; nothing persistent below
##   the middle of the map except the joystick, at four screen shapes and every joystick position.
## - Fight form: with a locked target (and for 3 s after the last blow) pills keep icon and progress, the two
##   chips drop their words; places and heights do not change; everything returns after the hold.
## - Pills: progress values and the green Claim; the step sentence stays in the tooltip.
## - Zoom: the button opens the slider, a second tap or 4 s closes it; pinch-independent value text.
## - Recent finds: one right-aligned feed, rows leave after 8 s; the separate Gem counter stays hidden.
## - Notices: a toast uses the lane between the rails, under a banner; the banner stays at the top.
## - Both chips are tappable (Mastery page, World).
## Run: Godot --headless --path . res://tests/change_72_probe.tscn -- --probe --profile=probe-c72 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim
var map: Control

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")
func node(path: String) -> Control:return map.get_node(path)

func run() -> void:
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    get_window().size=Vector2i(720,1280)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    map=game.get_node("Safe/Layout/Map")
    await frames(6)
    await rail_checks()
    await combat_checks()
    await pill_checks()
    await zoom_checks()
    await loot_checks()
    await notice_checks()
    await chip_checks()
    SettingsState.set_joystick_position(1)
    get_window().size=Vector2i(720,1280)
    print("CHANGE_72_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func fresh() -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()
    game.hud_combat_time=0.0;game.zoom_open_time=0.0;game.toast_time=0.0

## Fixture: Winter I with the Snowman found, the nearest enemy known and three followed objectives.
func fixture() -> void:
    fresh()
    sim.state.bosses_found.append("boss-snowman")
    var g: int=sim.nearest_group()
    sim.state.discovered[str(g)]=true;sim.campaign.discover_spot(g,0)
    game.combat_group=g
    sim.state.follow_mission="main:0"
    sim.state.opportunities["expedition_o1"]={"ready":false,"baseline":{},"step":0,"count":3}
    sim.state.follow="expedition_o1"
    sim.state.follow_mastery="1:hunt"
    sim.clear_target()
    sim.touch()

func hud_ticks(n:=4) -> void:
    for i in range(n):
        game.elapsed=1.0
        await frames(2)

func pills() -> Array:
    return [game.mastery_tracker,node("MissionTracker"),node("FollowTracker")].filter(func(t):return t.visible)

func rail_checks() -> void:
    print("-- rails")
    for shape in [Vector2i(720,1280),Vector2i(720,1600),Vector2i(720,1440),Vector2i(960,1280)]:
        for stick in [0,1,2]:
            get_window().size=shape
            SettingsState.set_joystick_position(stick)
            fixture()
            await frames(4);await hud_ticks()
            var tag:="%dx%d stick %d" % [shape.x,shape.y,stick]
            var a: Rect2=node("Achievement").get_rect();var u: Rect2=node("EnemyUpgrades").get_rect();var q: Rect2=node("QuickFarm").get_rect()
            var list:=pills()
            var ok: bool=list.size()==3 and a.end.x<=u.position.x and u.end.x<=q.position.x and is_equal_approx(a.position.y,q.position.y)
            var y: float=a.end.y
            for t in list:
                ok=ok and t.position.y>=y and is_equal_approx(t.position.x,a.position.x) and t.size.y<=48 and is_equal_approx(t.size.x,game.LEFT_COLUMN_WIDTH)
                y=t.get_rect().end.y
            check(ok,"%s: one row of enemy controls, three one-line pills under it" % tag)
            var mini: Rect2=node("MiniMap").get_rect();var ex: Rect2=node("Explored").get_rect()
            var chip: Rect2=node("Mastery").get_rect();var gate: Rect2=node("Gate").get_rect();var zb: Rect2=node("ZoomButton").get_rect()
            check(is_equal_approx(mini.size.x,game.MINIMAP_SIDE) and absf(mini.end.x-(map.size.x-game.HUD_MARGIN))<1 and absf(ex.end.y-mini.end.y)<1 and absf(ex.end.x-mini.end.x)<1 and zb.end.x<=mini.position.x and not zb.intersects(ex) and chip.position.y>=mini.end.y and gate.position.y>=chip.end.y and absf(gate.end.x-mini.end.x)<1,"%s: minimap with Map Explored on it, zoom button beside, Mastery then Next Stage under" % tag)
            # Nothing persistent in the lower half but the joystick; the rails do not meet.
            var low:=true
            var rails: Array=[node("Achievement"),node("EnemyUpgrades"),node("QuickFarm"),node("MiniMap"),node("Explored"),node("Mastery"),node("Gate"),node("ZoomButton")]+list
            for n in rails:
                if n.get_rect().end.y>map.size.y*.5:low=false
                if n.get_global_rect().intersects(node("Joystick").get_global_rect()):low=false
            check(low and y+8<=map.size.y*.5 and list[0].get_rect().end.x<zb.position.x,"%s: both rails stay in the upper half, clear of the joystick and of each other" % tag)
            check(node("Achievement").size.y>=56 and u.size.x>=56 and q.size.x>=56 and zb.size.y>=44 and chip.size.y>=44,"%s: touch sizes kept (tiles %s, zoom %s, Mastery %s)" % [tag,u.size,zb.size,chip.size])
            check(not node("Zoom").visible and not node("GemPickup").visible,"%s: no permanent zoom slider, no separate Gem counter" % tag)
    get_window().size=Vector2i(720,1280)
    SettingsState.set_joystick_position(1)
    await frames(4)

func combat_checks() -> void:
    print("-- fight form")
    fixture()
    await frames(4);await hud_ticks()
    var list:=pills()
    var before: Array=list.map(func(t):return t.get_rect())
    var chip: Button=node("Mastery");var gate: Label=node("Gate/Row/Label")
    var st:=int(sim.state.stage)
    check(not game.hud_combat and chip.text.begins_with("Mastery ") and gate.text=="Next Stage · Bosses 0/1","Out of a fight: \"%s\" and \"%s\"" % [chip.text,gate.text])
    check(list.all(func(t):return t.get_node("Row/Text").visible and t.get_node("Row/Text/Name").text!=""),"Out of a fight the pills show their titles")
    # A blow dealt or taken starts the fight form.
    sim.feedback.emit("player",5.0,false)
    await frames(2)
    check(game.hud_combat,"A blow puts the HUD in its fight form")
    await hud_ticks(2)
    var ok:=true
    for i in range(list.size()):
        var r: Rect2=list[i].get_rect()
        ok=ok and r.position.is_equal_approx(before[i].position) and is_equal_approx(r.size.y,before[i].size.y) and is_equal_approx(r.size.x,game.PILL_COMBAT_WIDTH)
        ok=ok and not list[i].get_node("Row/Text").visible and list[i].get_node("Row/Icon").texture!=null and list[i].get_node("Row/Progress").text!=""
    check(ok,"In a fight each pill keeps its place and height, icon and progress, and narrows to %d" % int(game.PILL_COMBAT_WIDTH))
    check(chip.text==tr("MASTERY_CHIP_SHORT") % [sim.campaign.mastery.map_percent(st),0,5] and not chip.text.contains("Mastery") and gate.text=="Bosses 0/1","In a fight the chips read \"%s\" and \"%s\"" % [chip.text,gate.text])
    check(chip.icon!=null and node("Gate/Row/Icon").texture!=null and node("Gate").visible and chip.visible,"Both chips keep their icons")
    check(is_equal_approx(chip.size.x,game.MINIMAP_SIDE) and is_equal_approx(node("Gate").size.x,game.MINIMAP_SIDE),"Short chips are the minimap's width")
    # A healing number is not a blow; the hold runs out in real time.
    game.hud_combat_time=.05
    sim.feedback.emit("player",5.0,true)
    await frames(8)
    await hud_ticks(2)
    check(not game.hud_combat and chip.text.begins_with("Mastery ") and gate.text=="Next Stage · Bosses 0/1","After the hold the words return (a heal does not extend it)")
    ok=true
    for i in range(list.size()):ok=ok and list[i].get_rect().is_equal_approx(before[i]) and list[i].get_node("Row/Text").visible
    check(ok,"…and the pills return to their full form in the same places")
    check(is_equal_approx(game.HUD_COMBAT_HOLD,3.0),"The hold is 3 s")
    # A locked target holds the fight form by itself.
    var enemy: Dictionary={}
    for e in sim.state.enemies:
        if float(e.hp)>0:enemy=e;break
    sim.locked_target=str(enemy.id) # fixture: the lock the simulation takes when an enemy is in reach
    check(not sim._find_actor(sim.locked_target).is_empty(),"Fixture: a target is locked")
    await frames(3)
    check(game.hud_combat and is_equal_approx(game.hud_combat_time,game.HUD_COMBAT_HOLD),"A locked target keeps the fight form")
    get_tree().paused=true
    game.hud_combat_time=.05;sim.clear_target()
    await frames(6)
    check(game.hud_combat,"A pause freezes the hold")
    get_tree().paused=false
    await frames(8)
    check(not game.hud_combat,"…which runs out after it")
    # German: the long word grows the chip leftward at the full font; the short form is language-neutral.
    LocalizationService.select_language("de_DE")
    await frames(4)
    game.mastery_text="";game.gate_text=""
    await hud_ticks(3)
    check(chip.text.begins_with("Meisterschaft") and chip.get_theme_font_size("font_size")>=17 and chip.size.x>=game._chip_width(chip)-.5 and absf(chip.get_rect().end.x-node("MiniMap").get_rect().end.x)<1 and chip.position.x>pills()[0].get_rect().end.x,"de_DE: \"%s\" at %d px, %d wide, grown leftward" % [chip.text,chip.get_theme_font_size("font_size"),int(chip.size.x)])
    LocalizationService.select_language("automatic")
    await frames(4)
    game.mastery_text="";game.gate_text=""
    await hud_ticks(2)

func pill_checks() -> void:
    print("-- pills")
    fixture()
    await frames(4);await hud_ticks()
    var follow: Control=node("FollowTracker");var mission: Control=node("MissionTracker");var mastery: Control=game.mastery_tracker
    var chain: Array=sim.campaign.chain_for("expedition_o1")
    check(follow.get_node("Row/Progress").text=="3/%d" % int(chain[0][2]) and sim.campaign.follow_progress("expedition_o1")==follow.get_node("Row/Progress").text,"Prestige pill: %s" % follow.get_node("Row/Progress").text)
    check(mission.get_node("Row/Progress").text=="0/5","Mission pill: %s" % mission.get_node("Row/Progress").text)
    var objective: Dictionary=sim.campaign.mastery.objective(1,"hunt")
    check(mastery.get_node("Row/Progress").text.contains("/"),"Mastery pill: %s (%d parts)" % [mastery.get_node("Row/Progress").text,objective.parts.size()])
    check(not follow.get_node("Row/Text/Step").visible and follow.tooltip_text==follow.get_node("Row/Text/Step").text and follow.tooltip_text!="","The step sentence is kept as the pill's tooltip")
    sim.state.follow_mastery="1:explore";sim.touch()
    await hud_ticks(2)
    check(mastery.get_node("Row/Progress").text.ends_with("%"),"Exploration shows a percentage: %s" % mastery.get_node("Row/Progress").text)
    # Ready: Claim, in green, in both forms.
    sim.state.opportunities.expedition_o1.ready=true;sim.touch()
    await hud_ticks(2)
    var label: Label=follow.get_node("Row/Progress")
    check(label.text==tr("CLAIM") and label.get_theme_color("font_color").g>.99 and label.get_theme_color("font_color").r<.6,"A ready opportunity reads Claim in green")
    game.hud_combat_time=3.0
    await frames(2);await hud_ticks(2)
    check(label.text==tr("CLAIM") and label.is_visible_in_tree(),"…also in the fight form")
    game.hud_combat_time=0.0
    await frames(2)
    for path in ["collection_o1","hunter_o1","trophy_o1","arsenal_o1"]:
        sim.state.opportunities[path]={"ready":false,"baseline":{},"step":0,"count":0}
        var text: String=sim.campaign.follow_progress(path)
        check(text.contains("/") and text.split("/").size()==2,"%s progress is one count: %s" % [path,text])
    check(sim.campaign.follow_progress("missing_o1")=="","No opportunity, no count")
    # A tap still opens the panel.
    var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true
    mission.gui_input.emit(press);await frames(3)
    check(game.panel=="missions","A tap on the mission pill opens Missions")
    game._close();await frames(2)

func zoom_checks() -> void:
    print("-- zoom")
    fixture()
    await frames(4);await hud_ticks()
    var button: Button=node("ZoomButton");var zoom: Control=node("Zoom")
    SettingsState.set_camera_zoom(2.0)
    check(button.text=="2.0×" and not zoom.visible,"The button shows the zoom (%s); the slider is closed" % button.text)
    button.pressed.emit();await frames(3)
    var plate: Control=node("ZoomPlate")
    check(zoom.visible and plate.visible and plate.get_rect().position.y>=node("MiniMap").get_rect().end.y and absf(plate.get_rect().end.x-node("MiniMap").get_rect().end.x)<1 and plate.get_rect().encloses(zoom.get_rect()),"A tap opens the slider on its plate under the minimap")
    check(node("Mastery").modulate.a==0.0 and plate.get_rect().encloses(node("Mastery").get_rect().intersection(plate.get_rect())) and plate.get_index()>node("Mastery").get_index(),"The plate takes the chips' place while it is open")
    zoom.get_node("Slider").value=1.5;await frames(2)
    check(is_equal_approx(SettingsState.camera_zoom,1.5) and button.text=="1.5×" and game.zoom_open_time>game.ZOOM_OPEN_SECONDS-.5,"Moving the slider zooms, updates the button and restarts the 4 s")
    game.zoom_open_time=.05;await frames(8)
    check(not zoom.visible and not plate.visible and node("Mastery").modulate.a==1.0,"It closes by itself and the chips return")
    button.pressed.emit();await frames(2)
    button.pressed.emit();await frames(2)
    check(not zoom.visible,"A second tap closes it")
    SettingsState.set_camera_zoom(2.0)

func loot_checks() -> void:
    print("-- recent finds")
    fixture()
    sim.state.clock=100.0
    sim.history("HISTORY_CURRENCY","gems",1.0,0.0)
    sim.state.clock=103.0
    sim.history("HISTORY_ITEM","wood_sword",1.0,0.0)
    sim.touch()
    await hud_ticks(3)
    var feed: Control=node("History")
    var rows: Array=feed.get_children().filter(func(r):return r.visible)
    check(rows.size()==2 and rows.all(func(r):return absf(r.get_global_rect().end.x-node("MiniMap").get_global_rect().end.x)<1 and r.get_global_rect().position.y>=node("Gate").get_global_rect().end.y),"Two finds show right-aligned under the chips")
    check(not node("GemPickup").visible,"A Gem find shows as a feed row only")
    sim.state.clock=107.5
    await hud_ticks(2)
    rows=feed.get_children().filter(func(r):return r.visible)
    check(rows.size()==2 and rows[1].modulate.a<1.0 and rows[1].modulate.a>0.0 and is_equal_approx(rows[0].modulate.a,1.0),"7.5 s after it the older find is fading")
    sim.state.clock=108.5
    await hud_ticks(2)
    rows=feed.get_children().filter(func(r):return r.visible)
    check(rows.size()==1,"After 8 s it is gone; the newer one stays")
    sim.state.clock=120.0
    await hud_ticks(2)
    check(feed.get_children().filter(func(r):return r.visible).is_empty() and sim.state.history.size()==2,"Both gone from the HUD; the history itself is kept")

func notice_checks() -> void:
    print("-- notices")
    for shape in [Vector2i(720,1280),Vector2i(720,1600),Vector2i(960,1280)]:
        get_window().size=shape
        fixture()
        await frames(4);await hud_ticks()
        game._toast(tr("OFFLINE_CLAIMED"))
        await frames(4)
        var toast: Control=game.get_node("Toast")
        var r: Rect2=toast.get_global_rect()
        var tag:="%dx%d" % [shape.x,shape.y]
        check(toast.visible and r.position.x>pills()[0].get_global_rect().end.x and r.end.x<node("MiniMap").get_global_rect().position.x and r.end.y<map.global_position.y+map.size.y*.42 and not game._toast_overlaps(r),"%s: the toast sits in the lane between the rails, in the upper map (%s; pill end %s, minimap x %s, limit %s, overlaps %s)" % [tag,r,pills()[0].get_global_rect().end.x,node("MiniMap").get_global_rect().position.x,map.global_position.y+map.size.y*.42,game._toast_overlaps(r)])
        sim.milestone.emit("discovered","expedition_o1")
        await frames(12)
        var b: Rect2=game.banner.get_global_rect()
        r=toast.get_global_rect()
        check(game.banner.visible and b.position.y<=map.global_position.y+game.banner_top_gap+60,"%s: the banner keeps the top of the map (y %d)" % [tag,int(b.position.y)])
        check(not toast.visible or (r.position.y>=b.end.y and not r.intersects(b) and r.end.y<map.global_position.y+map.size.y*.42),"%s: with a banner the toast is under it or waits, never in the fight (%s, shown %s)" % [tag,r,toast.visible])
        game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();toast.hide()
    get_window().size=Vector2i(720,1280)
    await frames(4)

func chip_checks() -> void:
    print("-- chips")
    fixture()
    await frames(4);await hud_ticks()
    var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true
    node("Gate").gui_input.emit(press);await frames(3)
    check(game.panel=="world","A tap on Next Stage opens World")
    game._close();await frames(2)
    node("Mastery").pressed.emit();await frames(3)
    check(game.panel=="mastery","A tap on the Mastery chip opens its page")
    game._close();await frames(2)
    game.hud_combat_time=3.0;await frames(2);await hud_ticks(2)
    check(node("Gate").mouse_filter==Control.MOUSE_FILTER_STOP and not node("Mastery").disabled and node("Gate").size.y>=38 and node("Mastery").size.y>=44,"Both stay tappable in the fight form")
    game.hud_combat_time=0.0
    var pending: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/localization_pending.json")).keys
    check(["MASTERY_CHIP_SHORT","GATE_HUD_SHORT","GATE_HUD_WORLD_SHORT"].all(func(k):return pending.has(k) and tr(k)!=k),"The three short strings exist in English and are in the translation handoff")
