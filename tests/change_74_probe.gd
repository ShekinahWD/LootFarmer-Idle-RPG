extends Node
## Change 74 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## - Prestige scrolling with Android-style touch (a ScreenTouch/ScreenDrag stream with the mouse events Android
##   emulates for finger 0, through the viewport): an open Prestige panel's refreshes during play are not
##   structural (the owned cards used to be rebuilt every refresh); a drag that starts over an opportunity card,
##   a Follow button or an owned card scrolls while the game keeps changing state, and its fling continues; a
##   structural refresh waits for the gesture to end and never restores an old offset; a tap still acts.
## - Sizes: minimap, the three enemy controls and the enemy name at least 30% larger than Change 72.
## - Map Explored is a caption under the minimap, right-aligned with it, never over it.
## - No fight form: a blow or a locked target changes no pill, chip text or place.
## - Pills name the tracked objective (outfit, enemy, item), follow its progress and the language.
## - The rails at four screen shapes and every joystick position: no overlaps, upper half, joystick clear.
## - Toasts: shown in a fight with three pills, never over the HUD, the joystick or the fight; the top lane
##   on a wide canvas.
## - The enemy name: 24 px in every enabled language, ellipsis inside its room.
## - Map buttons (World Travel grid, Teleport) carry the icons of the followed objectives progressing there.
## - Toasts stay long enough to read (a boss weapon's ITEM_ENHANCED); one may pass over the joystick.
## - No text collapses: a long pill title wraps and the pill grows.
## - Change 75: Next Stage on two lines at the minimap's width in every language; the zoom slider plate is one
##   row at the minimap's width, hides only the Mastery chip and has a round grabber.
## Run: Godot --headless --path . res://tests/change_74_probe.tscn -- --probe --profile=probe-c74 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim
var map: Control
var scroll: ScrollContainer

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
    SettingsState.set_joystick_position(1)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    map=game.get_node("Safe/Layout/Map")
    scroll=game.get_node("Sheet/Margin/Content/Scroll")
    await frames(6)
    await prestige_scroll_checks()
    await size_checks()
    await fight_checks()
    await name_checks()
    await rail_checks()
    await toast_checks()
    await enemy_name_checks()
    await map_button_checks()
    await toast_time_checks()
    await wrap_checks()
    await gate_and_zoom_checks()
    SettingsState.set_joystick_position(1)
    get_window().size=Vector2i(720,1280)
    LocalizationService.select_language("automatic")
    print("CHANGE_74_CHECKS %d FAILURES %d" % [checks,failures])
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
    game.zoom_open_time=0.0;game.toast_time=0.0

## Fixture: Winter I with the Snowman found, the nearest enemy known, and three followed objectives that each
## name one thing: Mastery Hunt, a daily Hunt mission, Collection I.
func fixture() -> void:
    fresh()
    sim.state.bosses_found.append("boss-snowman")
    var g: int=sim.nearest_group()
    sim.state.discovered[str(g)]=true;sim.campaign.discover_spot(g,0)
    game.combat_group=g
    sim.campaign.refresh_missions()
    sim.state.follow_mission="main:0"
    for i in range(sim.state.missions.size()):
        if str(sim.state.missions[i].kind)=="kill":sim.state.follow_mission=sim.campaign.mission_follow_key("daily",i);break
    sim.state.opportunities["collection_o1"]={"ready":false,"baseline":{}}
    sim.state.follow="collection_o1"
    sim.state.follow_mastery="1:hunt"
    sim.clear_target()
    sim.touch()

func hud_ticks(n:=4) -> void:
    for i in range(n):
        game.elapsed=1.0
        await frames(2)

func pills() -> Array:
    return [game.mastery_tracker,node("MissionTracker"),node("FollowTracker")].filter(func(t):return t.visible)
func title(t: Control) -> String:return t.get_node("Row/Text/Name").text

# ---------------------------------------------------------------- touch
## Android delivers the touch, then (finger 0, Input emulate_mouse_from_touch) the emulated mouse event.
func send(event: InputEvent) -> void:
    get_viewport().push_input(event)
    if event is InputEventScreenTouch and event.index==0:
        var mb:=InputEventMouseButton.new()
        mb.button_index=MOUSE_BUTTON_LEFT;mb.pressed=event.pressed;mb.position=event.position;mb.global_position=event.position
        mb.button_mask=MOUSE_BUTTON_MASK_LEFT if event.pressed else 0
        get_viewport().push_input(mb)
    elif event is InputEventScreenDrag and event.index==0:
        var mm:=InputEventMouseMotion.new()
        mm.position=event.position;mm.global_position=event.position;mm.relative=event.relative;mm.button_mask=MOUSE_BUTTON_MASK_LEFT
        get_viewport().push_input(mm)
func touch(at: Vector2,pressed: bool) -> void:
    var t:=InputEventScreenTouch.new();t.index=0;t.pressed=pressed;t.position=at
    send(t)
## A finger drag of steps x step px; `during` runs before each step (the game going on).
func drag(at: Vector2,steps: int,step: Vector2,during:=Callable()) -> Vector2:
    touch(at,true);await frames(1)
    var p:=at
    for i in range(steps):
        if during.is_valid():during.call(i)
        var d:=InputEventScreenDrag.new();d.index=0;d.relative=step;p+=step;d.position=p;d.velocity=step*60
        send(d);await frames(1)
    return p

func prestige_fixture() -> void:
    fixture()
    var ids: Array=sim.catalog.campaign.cards.keys()
    for i in range(6):sim.state.owned_cards.append(ids[i])
    for op in sim.catalog.campaign.opportunities:
        if not sim.state.opportunities.has(op.id):sim.state.opportunities[op.id]={"ready":false,"baseline":{},"step":0,"count":0}
    sim.state.unlocked_stage=3
    sim.touch()

## The first control of this kind fully inside the scroller's visible area, scrolled to if needed.
func visible_in_scroll(pick: Callable) -> Control:
    var area: Rect2=scroll.get_global_rect()
    for offset in range(0,int(scroll.get_v_scroll_bar().max_value),200):
        scroll.scroll_vertical=offset;await frames(3)
        for c in game.rows.find_children("*","Control",true,false):
            var r: Rect2=c.get_global_rect()
            if c.is_visible_in_tree() and pick.call(c) and r.position.y>=area.position.y+20 and r.end.y<=area.end.y-20 and area.has_point(r.get_center()):return c
    return null

func prestige_scroll_checks() -> void:
    print("-- Prestige scrolling")
    prestige_fixture()
    game._open("prestige");await frames(10)
    var bar: ScrollBar=scroll.get_v_scroll_bar()
    check(bar.max_value-bar.page>2000,"Fixture: the Prestige list overflows (%d px of content)" % int(bar.max_value))
    # Refreshes while the game runs (each sim.touch is a revision, as kills and loot are).
    var refreshes:=0;var structural:=0;var gen: int=game.panel_generation
    for i in range(120):
        if i%5==0:sim.touch()
        await frames(1)
        if game.panel_generation!=gen:
            gen=game.panel_generation;refreshes+=1
            if game.settle_frames>0:structural+=1
    check(refreshes>=3 and structural==0,"An open Prestige panel refreshes during play (%d times) without rebuilding its controls (%d structural)" % [refreshes,structural])
    var card: Button=null
    for c in game.rows.find_children("*","Button",true,false):
        if c.get_script()==game.PRESTIGE_CARD_SCRIPT:card=c;break
    check(card!=null and card.get_meta("designed_minimum",Vector2.ZERO)==Vector2(150,190) and card.size.y>=card.get_node("Content").get_combined_minimum_size().y+28-.5,"An owned card keeps its designed size as meta and still grows to its text (%s, content %s)" % [card.size if card else Vector2.ZERO,card.get_node("Content").get_combined_minimum_size() if card else Vector2.ZERO])
    # A drag starting over each kind of control, with the game changing state under it.
    var targets: Dictionary={
        "an opportunity card":func(c):return c is PanelContainer and c.has_meta("guide_row"),
        "a Follow button":func(c):return c is Button and c.has_meta("guide") and str(c.get_meta("guide")) in ["follow","unfollow"],
        "an owned Prestige card":func(c):return c.get_script()==game.PRESTIGE_CARD_SCRIPT}
    for label in targets:
        var target: Control=await visible_in_scroll(targets[label])
        if target==null:
            check(false,"Fixture: %s is on screen" % label);continue
        var start: int=scroll.scroll_vertical
        var at: Vector2=target.get_global_rect().get_center()
        # Near the end of the list the finger pulls it back down instead (the content moves the other way).
        var sign: float=1.0 if bar.max_value-bar.page-start>=600 else -1.0
        var follow_before: String=str(sim.state.follow)
        var p: Vector2=await drag(at,12,Vector2(0,-25*sign),func(i):if i%3==0:sim.touch())
        var during: int=int((scroll.scroll_vertical-start)*sign)
        touch(p,false)
        for i in range(30):
            if i%3==0:sim.touch()
            await frames(1)
        var after: int=int((scroll.scroll_vertical-start)*sign)
        check(during>=250 and after>during and str(sim.state.follow)==follow_before,"A 300 px drag starting over %s scrolls %d px while the game runs, and the fling carries on to %d (no tap)" % [label,during,after])
    # A structural change mid-drag (an opportunity turns ready and moves to the top) waits for the gesture.
    scroll.scroll_vertical=400;await frames(4)
    var area: Rect2=scroll.get_global_rect()
    var p2: Vector2=await drag(Vector2(area.get_center().x,area.position.y+area.size.y*.75),8,Vector2(0,-30))
    var mid: int=scroll.scroll_vertical
    var generation: int=game.panel_generation
    sim.state.opportunities["hunter_o1"].ready=true;sim.touch()
    await frames(20)
    check(scroll.gesturing and game.panel_generation==generation and scroll.scroll_vertical>=mid,"During the gesture the refresh waits (offset %d, was %d)" % [scroll.scroll_vertical,mid])
    touch(p2,false)
    for i in range(240):
        await frames(1)
        if not scroll.gesturing:break
    await frames(6)
    check(not scroll.gesturing and game.panel_generation>generation and scroll.scroll_vertical>=mid,"When the list comes to rest the refresh runs and keeps the offset (%d)" % scroll.scroll_vertical)
    # A tap (no movement) on Follow still follows.
    var follow: Control=await visible_in_scroll(func(c):return c is Button and c.has_meta("guide") and str(c.get_meta("guide"))=="follow" and not c.disabled)
    if follow!=null:
        var before: String=str(sim.state.follow)
        var at: Vector2=follow.get_global_rect().get_center()
        touch(at,true);await frames(2);touch(at,false);await frames(6)
        check(str(sim.state.follow)!=before and str(sim.state.follow)!="","A tap on a Follow button still follows (%s -> %s)" % [before,sim.state.follow])
    else:check(false,"Fixture: a Follow button is on screen")
    game._close();await frames(2)

# ---------------------------------------------------------------- sizes and caption
func size_checks() -> void:
    print("-- sizes")
    fixture()
    await frames(4);await hud_ticks()
    var mini: Rect2=node("MiniMap").get_rect();var ex: Rect2=node("Explored").get_rect()
    check(mini.size.x>=168*1.3 and mini.size.y>=168*1.3 and absf(mini.end.x-(map.size.x-game.HUD_MARGIN))<1 and absf(mini.position.y-game.HUD_MARGIN)<1,"Minimap %s: at least 30%% larger than 168, top right" % mini.size)
    check(ex.position.y>=mini.end.y and not ex.intersects(mini) and absf(ex.end.x-mini.end.x)<1 and ex.size.x>=mini.size.x-.5 and node("Explored").horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER,"Map Explored is a caption under the minimap, aligned with it (%s under %s)" % [ex,mini])
    check(node("Explored").get_theme_font_size("font_size")>=18 and node("Explored").text.begins_with("Map Explored: "),"…at its 18 px font: \"%s\"" % node("Explored").text)
    var a: Rect2=node("Achievement").get_rect();var u: Rect2=node("EnemyUpgrades").get_rect();var q: Rect2=node("QuickFarm").get_rect()
    check(a.size.x>=124*1.3 and a.size.y>=62*1.3 and u.size.x>=58*1.3 and u.size.y>=62*1.3 and q.size.x>=58*1.3 and q.size.y>=62*1.3,"Achievements %s, Upgrades %s, Auto Farm %s: each at least 30%% larger" % [a.size,u.size,q.size])
    for path in ["Achievement","EnemyUpgrades","QuickFarm"]:
        var b: Button=node(path)
        check(b.get_theme_constant("icon_max_width")>=int(28*1.3) and b.get_theme_font_size("font_size")>=16,"%s: icon %d px, text %d px" % [path,b.get_theme_constant("icon_max_width"),b.get_theme_font_size("font_size")])
    var name_label: Label=node("EnemySection")
    check(name_label.get_theme_font_size("font_size")>=ceili(18*1.3) and name_label.size.y>=name_label.get_theme_font_size("font_size"),"The enemy name is %d px (was 18)" % name_label.get_theme_font_size("font_size"))
    # Behaviour kept: the toggle styles and taps.
    var quick: Button=node("QuickFarm")
    check(quick.theme_type_variation in [&"ToggleOn",&"ToggleOff",&"ToggleLocked"] and quick.visible,"Auto Farm keeps its toggle style (%s)" % quick.theme_type_variation)
    node("Achievement").pressed.emit();await frames(3)
    check(game.panel=="enemy" or game.panel=="upgrades","A tap on Achievements opens its panel (%s)" % game.panel)
    game._close();await frames(2)
    node("EnemyUpgrades").pressed.emit();await frames(3)
    check(game.panel!="","A tap on Upgrades opens its panel (%s)" % game.panel)
    game._close();await frames(2)

# ---------------------------------------------------------------- no fight form
func snapshot() -> Array:
    var out: Array=[]
    for t in pills():out.append([t.get_rect(),title(t),t.get_node("Row/Text").visible,t.get_node("Row/Progress").text])
    for path in ["Mastery","Gate","Explored"]:out.append([node(path).get_rect(),node(path).get_node("Row/Label").text if path=="Gate" else node(path).text])
    return out
func fight_checks() -> void:
    print("-- no fight form")
    fixture()
    await frames(4);await hud_ticks()
    var calm:=snapshot()
    check(not ("hud_combat" in game) and not ("hud_combat_time" in game),"The fight form is gone from the HUD")
    sim.feedback.emit("player",5.0,false)
    var enemy: Dictionary={}
    for e in sim.state.enemies:
        if float(e.hp)>0:enemy=e;break
    sim.locked_target=str(enemy.id) # fixture: the lock the simulation takes when an enemy is in reach
    await frames(4);await hud_ticks(3)
    var fight:=snapshot()
    check(fight==calm,"A blow and a locked target change no pill, chip or place")
    check(node("Mastery").text.begins_with("Mastery ") and node("Gate/Row/Label").text=="Next Stage · Bosses 0/1","In a fight the chips read \"%s\" and \"%s\"" % [node("Mastery").text,node("Gate/Row/Label").text])
    check(pills().all(func(t):return t.get_node("Row/Text").visible and title(t)!="" and t.get_node("Row/Progress").text!=""),"In a fight every pill keeps its name and progress")
    var pending: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/localization_pending.json"))
    check(["MASTERY_CHIP_SHORT","GATE_HUD_SHORT","GATE_HUD_WORLD_SHORT"].all(func(k):return not pending.keys.has(k) and tr(k)==k),"The three short strings are retired")
    sim.clear_target()

# ---------------------------------------------------------------- names
func name_checks() -> void:
    print("-- objective names")
    fixture()
    await frames(4);await hud_ticks()
    var follow: Control=node("FollowTracker");var mission: Control=node("MissionTracker");var mastery: Control=game.mastery_tracker
    var names: Array=sim.campaign.collection_names(1)
    var outfit: String=sim.campaign.contract_outfit(names[0])
    # Change 79: every pill states the action with its target (supersedes Change 74's name-only titles).
    check(title(follow)==tr("TRACK_COLLECT_ITEM") % sim.catalog.display_name(outfit) and title(follow).ends_with(" Outfit") and title(follow)!=str(game._opportunity("collection_o1").name),"Collection pill names the action and outfit: \"%s\" (not \"%s\")" % [title(follow),game._opportunity("collection_o1").name])
    # Progress moves the pill to the next outfit (fixture: the first one is complete).
    var goal: int=sim.campaign.collection_goal(1)
    sim.state.online_items[outfit]=goal;sim.state.opportunities.collection_o1["item_"+outfit]=goal
    sim.add_item(outfit,goal+1,false,false)
    sim.touch();await hud_ticks(2)
    var next: String=sim.catalog.display_name(sim.campaign.contract_outfit(names[1]))
    check(title(follow)==tr("TRACK_COLLECT_ITEM") % next,"With the first outfit collected the pill moves on: \"%s\"" % title(follow))
    var m: Dictionary=sim.state.missions[int(sim.campaign.followed_mission().index)]
    var g: int=sim.campaign.group_id(str(m.target))
    check(title(mission)==sim.campaign.mission_action(int(sim.campaign.followed_mission().index)) and title(mission).contains(str(sim.catalog.groups[g].name)),"Daily Hunt pill says what to do with the enemy: \"%s\"" % title(mission))
    var objective: Dictionary=sim.campaign.mastery.objective(1,"hunt")
    var part: Array=[]
    for p in objective.parts:
        if int(p[2])<int(p[3]):part=p;break
    check(not part.is_empty() and title(mastery)==tr("FOLLOW_GOAL_KILL_TARGET") % game._mastery_target(part) and not title(mastery).contains("·"),"Mastery Hunt pill: defeat its enemy: \"%s\"" % title(mastery))
    sim.state.follow_mastery="1:explore";sim.touch();await hud_ticks(2)
    check(title(mastery)==tr("TRACK_EXPLORE_MAP") % str(sim.catalog.stages[0].name),"Exploration says to explore the map: \"%s\"" % title(mastery))
    for pair in [["hunter_o1","boss-snowman"],["trophy_o1",""]]:
        sim.state.opportunities[pair[0]]={"ready":false,"baseline":{},"step":0,"count":0}
        sim.state.follow=pair[0];sim.touch();await hud_ticks(2)
        var focus: Dictionary=sim.campaign.follow_focus(pair[0])
        var want: String=tr("FOLLOW_GOAL_KILL_TARGET") % str(sim.catalog.groups[int(focus.group)].name)
        check(title(follow)==want,"%s pill: defeat the boss: \"%s\"" % [pair[0],title(follow)])
    sim.state.opportunities["expedition_o1"]={"ready":false,"baseline":{},"step":0,"count":0}
    sim.state.follow="expedition_o1";sim.touch();await hud_ticks(2)
    var chain: Array=sim.campaign.chain_for("expedition_o1")
    var eg: int=sim.campaign.group_id(str(chain[0][1]))
    check(title(follow)==(tr("FOLLOW_GOAL_KILL_TARGET") % str(sim.catalog.groups[eg].name) if eg>=0 else tr("FOLLOW_GOAL_"+str(chain[0][0]).to_upper())),"Expedition step pill: \"%s\"" % title(follow))
    sim.state.opportunities["arsenal_o1"]={"ready":false,"baseline":{}}
    sim.state.follow="arsenal_o1";sim.touch();await hud_ticks(2)
    check(title(follow)==sim.campaign.follow_summary("arsenal_o1",true).get_slice("
",0),"A requirement naming no single thing shows its step sentence: \"%s\"" % title(follow))
    # Language: the same objective in German.
    sim.state.follow="collection_o1";sim.touch()
    LocalizationService.select_language("de_DE");await frames(4);await hud_ticks(2)
    check(title(follow)==tr("TRACK_COLLECT_ITEM") % sim.catalog.display_name(sim.campaign.contract_outfit(names[1])) and not title(follow).contains(next),"de_DE: \"%s\"" % title(follow))
    LocalizationService.select_language("automatic");await frames(4);await hud_ticks(2)

# ---------------------------------------------------------------- rails
func rail_checks() -> void:
    print("-- rails")
    for shape in [Vector2i(720,1280),Vector2i(720,1600),Vector2i(720,1440),Vector2i(960,1280)]:
        for stick in [0,1,2]:
            get_window().size=shape
            SettingsState.set_joystick_position(stick)
            fixture()
            await frames(4);await hud_ticks()
            var tag:="%dx%d stick %d" % [shape.x,shape.y,stick]
            var list:=pills()
            var nodes: Array=[node("EnemySection"),node("Achievement"),node("EnemyUpgrades"),node("QuickFarm"),node("MiniMap"),node("ZoomButton"),node("Explored"),node("Mastery"),node("Gate")]+list
            var clear:=true;var meets: Array=[]
            for i in range(nodes.size()):
                for j in range(i+1,nodes.size()):
                    if nodes[i].get_global_rect().intersects(nodes[j].get_global_rect()):clear=false;meets.append("%s/%s" % [nodes[i].name,nodes[j].name])
            check(clear and list.size()==3,"%s: no two HUD elements overlap %s" % [tag,meets])
            var low:=true
            for n in nodes:
                if n.get_rect().end.y>map.size.y*.5 or n.get_global_rect().intersects(node("Joystick").get_global_rect()):low=false
            check(low,"%s: everything stays in the upper half, clear of the joystick" % tag)
            var y: float=node("Achievement").get_rect().end.y
            var ok:=true
            for t in list:
                # Change 79: an action-and-target title may wrap (at most three lines here); nothing is cut.
                var name_label: Label=t.get_node("Row/Text/Name")
                ok=ok and t.position.y>=y and t.size.x<=game.LEFT_COLUMN_WIDTH+.5 and t.size.x>=game.ACHIEVEMENT_WIDTH-.5 and t.size.y<=80 and name_label.get_visible_line_count()>=name_label.get_line_count()
                y=t.get_rect().end.y
            check(ok,"%s: three pills under the enemy controls, wrapping without cutting, %s wide, %s tall" % [tag,list.map(func(t):return int(t.size.x)),list.map(func(t):return int(t.size.y))])
    get_window().size=Vector2i(720,1280)
    SettingsState.set_joystick_position(1)
    await frames(4)

# ---------------------------------------------------------------- toasts
func toast_checks() -> void:
    print("-- toasts")
    for shape in [Vector2i(720,1280),Vector2i(720,1600),Vector2i(960,1280)]:
        for stick in [0,1,2]:
            get_window().size=shape
            SettingsState.set_joystick_position(stick)
            fixture()
            sim.feedback.emit("player",5.0,false)
            await frames(4);await hud_ticks()
            var toast: Control=game.get_node("Toast")
            var tag:="%dx%d stick %d" % [shape.x,shape.y,stick]
            for text in [tr("OFFLINE_CLAIMED"),tr("OFFLINE_CLAIMED")+" "+tr("OFFLINE_CLAIMED")+" "+tr("OFFLINE_CLAIMED")]:
                game.toast_queue.clear();toast.hide();game.toast_time=0.0
                game._toast(text)
                await frames(4)
                var r: Rect2=toast.get_global_rect()
                var player: Vector2=map.global_position+map.size*.5
                check(toast.visible and map.get_global_rect().encloses(r) and not game._toast_overlaps(r),"%s: a %d-line toast shows clear of the HUD and the joystick (%s)" % [tag,1 if text.length()<40 else 2,r])
                check(not r.has_point(player) and (r.end.y<=player.y-40 or r.position.y>=player.y+40 or r.end.x<=player.x-60 or r.position.x>=player.x+60),"%s: …and away from the middle of the map" % tag)
            if shape.x==960:
                var top: bool=toast.get_global_rect().position.y<map.global_position.y+map.size.y*.3
                check(top,"%s: a wide canvas keeps the top lane between the rails" % tag)
            sim.milestone.emit("discovered","expedition_o1")
            await frames(12)
            var b: Rect2=game.banner.get_global_rect()
            check(game.banner.visible and b.position.y<=map.global_position.y+game.banner_top_gap+60 and (not toast.visible or not toast.get_global_rect().intersects(b)),"%s: the banner keeps the top and the toast never covers it" % tag)
            game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();toast.hide()
    get_window().size=Vector2i(720,1280)
    SettingsState.set_joystick_position(1)
    await frames(4)

# ---------------------------------------------------------------- enemy name
func enemy_name_checks() -> void:
    print("-- enemy name")
    fixture()
    await frames(4);await hud_ticks()
    var label: Label=node("EnemySection")
    var room: float=node("MiniMap").get_rect().position.x-game.HUD_GAP-label.position.x
    var longest:="";var widest:=0.0;var language:=""
    for locale in LocalizationService.ENABLED_LANGUAGES:
        LocalizationService.select_language(locale);await frames(2)
        for g in sim.catalog.groups:
            var w: float=label.get_theme_font("font").get_string_size(str(g.name),HORIZONTAL_ALIGNMENT_LEFT,-1,24).x
            if w>widest:widest=w;longest=str(g.name);language=locale
    LocalizationService.select_language(language);await frames(2)
    print("  longest enemy name: %s \"%s\" %d px at 24 px, room %d" % [language,longest,int(widest),int(room)])
    label.text=longest
    game._layout_hud()
    print("  laid out: %s" % label.get_rect())
    check(widest<=room and label.size.x>=widest and label.get_rect().end.x<=node("MiniMap").get_rect().position.x and not label.get_rect().intersects(node("ZoomButton").get_rect()) and label.get_theme_font_size("font_size")==24,"The longest name in 20 languages (%s, %d px) shows whole at 24 px, left of the minimap and above the zoom button (room %d)" % [language,int(widest),int(room)])
    check(label.text_overrun_behavior==TextServer.OVERRUN_TRIM_ELLIPSIS,"A longer future name would end in an ellipsis inside its room")
    LocalizationService.select_language("automatic");await frames(2)

# ---------------------------------------------------------------- map buttons
func map_button_checks() -> void:
    print("-- map buttons")
    fixture()
    sim.state.unlocked_stage=4
    sim.state.follow_mastery="2:explore"
    sim.touch()
    var marks: Dictionary=sim.campaign.follow_stages()
    check(marks.get(2,[]).has("mastery") and marks.get(1,[]).has("mission") and marks.get(1,[]).has("prestige"),"follow_stages: Mastery on Winter II, the daily Hunt and Collection I on Winter I (%s)" % marks)
    sim.state.stage=3;sim.touch()
    game._open("world");await frames(8)
    var buttons: Array=game.rows.find_children("*","Button",true,false).filter(func(b):return b.has_meta("follow_marks"))
    var grid: GridContainer=buttons[0].get_parent() if not buttons.is_empty() else null
    check(buttons.size()==3 and grid!=null and grid.columns==2,"World Travel lists the other three maps in a two-column grid (%d buttons, %s columns)" % [buttons.size(),grid.columns if grid else 0])
    var w1: Button=null;var w2: Button=null;var w4: Button=null
    for b in buttons:
        if str(b.get_meta("guide",""))=="travel_stage_1":w1=b
        elif str(b.get_meta("guide",""))=="travel_stage_2":w2=b
        elif str(b.get_meta("guide",""))=="travel_stage_4":w4=b
    var icons:=func(b: Button)->int:return b.get_child(0).get_child_count() if b!=null and b.get_child_count()>0 else -1
    check(icons.call(w1)==2 and icons.call(w2)==1 and icons.call(w4)==0,"Winter I carries the mission and Prestige icons, Winter II the Mastery icon, the fourth map none (%d, %d, %d)" % [icons.call(w1),icons.call(w2),icons.call(w4)])
    var ok:=true
    for b in buttons:
        var r: Rect2=b.get_global_rect()
        ok=ok and r.size.y>=56 and b.get_child(0).get_global_rect().end.x<=r.end.x and b.get_theme_default_font().get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+16<=b.get_child(0).get_global_rect().position.x-r.position.x+1
    check(ok,"Names and icons fit inside each button, tap height 56 or more")
    w2.pressed.emit();await frames(4)
    check(int(sim.state.stage)==2 or game.panel=="travel_map","A map button still travels (stage %d, panel %s)" % [int(sim.state.stage),game.panel])
    game._close();await frames(2)
    var t: Button=game._map_button(1,null,Callable())
    check(t.get_child(0).get_child_count()==2 and t.text==str(sim.catalog.stages[0].name),"The Teleport picker uses the same map button")
    t.free()

# ---------------------------------------------------------------- toast time and lanes
func toast_time_checks() -> void:
    print("-- toast time")
    var enhanced: String=tr("ITEM_ENHANCED")
    check(game.toast_reading_time(enhanced,false)>=4.0 and game.toast_reading_time(enhanced,true)>=3.0,"A boss weapon's \"%s\" stays %.1f s (%.1f s with more waiting; was 2.4 / 1.4)" % [enhanced,game.toast_reading_time(enhanced,false),game.toast_reading_time(enhanced,true)])
    check(is_equal_approx(game.toast_reading_time("Saved",false),game.toast_seconds) and game.toast_reading_time("x".repeat(400),false)<=game.TOAST_MAX_SECONDS,"Short toasts keep %.1f s; the longest stay at most %.0f s" % [game.toast_seconds,game.TOAST_MAX_SECONDS])
    fixture()
    await frames(4);await hud_ticks()
    sim.event.emit("ITEM_ENHANCED")
    await frames(4)
    var toast: Control=game.get_node("Toast")
    check(toast.visible and toast.get_node("Text").text==enhanced and game.toast_time>=3.9,"Picking up a boss weapon shows its toast for %.1f s" % game.toast_time)
    # Over the joystick: the lane exists and is allowed to cross the stick at the bottom of the map.
    var lanes: Array=game._toast_lanes()
    var over: Array=lanes.filter(func(l):return l.get("over_stick",false))
    check(over.size()==1,"An over-the-joystick lane is offered after the free side")
    var at: Vector2=game._toast_slot(over[0])
    var r:=Rect2(at,toast.size)
    check(at!=Vector2.INF and r.intersects(node("Joystick").get_global_rect()) and not game._toast_overlaps(r) and r.position.y>map.global_position.y+map.size.y*.62,"…which places a toast over the stick, clear of everything else (%s)" % r)
    game.toast_queue.clear();toast.hide();game.toast_time=0.0

# ---------------------------------------------------------------- no collapsing text
func wrap_checks() -> void:
    print("-- no collapsing text")
    for lang in ["automatic","de_DE","ru_RU"]:
        LocalizationService.select_language(lang)
        fixture()
        sim.state.follow_mastery="1:explore"
        sim.state.opportunities["regional_o1"]={"ready":false,"baseline":{}}
        sim.touch()
        await frames(4);await hud_ticks(4)
        var ok:=true;var detail: Array=[]
        for t in pills():
            var title_label: Label=t.get_node("Row/Text/Name")
            var need: float=title_label.get_theme_font("font").get_multiline_string_size(title_label.text,HORIZONTAL_ALIGNMENT_LEFT,title_label.size.x,16).y
            var full: bool=not title_label.clip_text and title_label.text_overrun_behavior==TextServer.OVERRUN_NO_TRIMMING and title_label.size.y>=need-1 and t.get_rect().encloses(title_label.get_global_rect().intersection(t.get_global_rect()))
            ok=ok and full and t.size.x<=game.LEFT_COLUMN_WIDTH+.5
            detail.append("%s %dx%d" % [title_label.text,int(t.size.x),int(t.size.y)])
        check(ok,"%s: every pill title shows whole (wrapping when long): %s" % [lang,detail])
        # A deliberately long title wraps onto two lines and the pill grows, nothing is cut.
        var follow: Control=node("FollowTracker")
        follow.get_node("Row/Text/Name").text="Extraordinarily long objective name for wrapping"
        game._layout_trackers();await frames(3);game._layout_trackers();await frames(2)
        var label: Label=follow.get_node("Row/Text/Name")
        check(follow.size.y>game.PILL_HEIGHT and label.get_line_count()>=2 and label.get_visible_line_count()>=label.get_line_count() and follow.size.x<=game.LEFT_COLUMN_WIDTH+.5,"%s: a long title wraps (%d lines) and its pill grows to %d" % [lang,label.get_line_count(),int(follow.size.y)])
    LocalizationService.select_language("automatic");await frames(4)

# ---------------------------------------------------------------- Change 75: Next Stage chip, zoom plate
func gate_and_zoom_checks() -> void:
    print("-- Next Stage chip and zoom plate (Change 75)")
    var worst:="";var widest:=0.0
    for lang in LocalizationService.ENABLED_LANGUAGES:
        LocalizationService.select_language(lang)
        fixture()
        game.gate_text=""
        await frames(4);await hud_ticks(3)
        var gate: Control=node("Gate");var caption: Label=gate.get_node("Row/Lines/Caption");var value: Label=gate.get_node("Row/Lines/Value")
        var full: String=gate.get_node("Row/Label").text
        var ok: bool=caption.visible and caption.text!="" and value.text.ends_with("0/1") and full.begins_with(caption.text) and full.to_lower().ends_with(value.text.to_lower()) and value.text.left(1)==value.text.left(1).to_upper() and not gate.get_node("Row/Label").visible
        ok=ok and absf(gate.size.x-game.MINIMAP_SIDE)<.5 and absf(gate.get_rect().end.x-node("MiniMap").get_rect().end.x)<1 and gate.size.y>=gate.get_combined_minimum_size().y-.5
        if gate.get_combined_minimum_size().x>widest:widest=gate.get_combined_minimum_size().x;worst=lang
        check(ok,"%s: \"%s\" over \"%s\", %dx%d" % [lang,caption.text,value.text,int(gate.size.x),int(gate.size.y)])
    check(widest<=game.MINIMAP_SIDE,"Every language fits the minimap's width (widest %s, %d)" % [worst,int(widest)])
    LocalizationService.select_language("automatic")
    fixture()
    sim.state.unlocked_stage=8;sim.state.stage=8;game.gate_text="";sim.touch()
    await frames(4);await hud_ticks(3)
    check(node("Gate/Row/Lines/Value").text.ends_with("/%d" % int(sim.campaign.gate_status().total)) and node("Gate/Row/Lines/Caption").text==game.gate_lines(node("Gate/Row/Label").text)[0],"The final map's World clear chip splits too: \"%s\" / \"%s\"" % [node("Gate/Row/Lines/Caption").text,node("Gate/Row/Lines/Value").text])
    check(game.gate_lines("No separator here")==["","No separator here"],"A text without a separator stays one line")
    fixture()
    await frames(4);await hud_ticks(3)
    node("ZoomButton").pressed.emit();await frames(3)
    var plate: Rect2=node("ZoomPlate").get_rect();var mastery: Rect2=node("Mastery").get_rect()
    check(absf(plate.size.x-game.MINIMAP_SIDE)<.5 and plate.size.y<=game.ZOOM_PLATE_HEIGHT+.5 and absf(plate.end.x-node("MiniMap").get_rect().end.x)<1 and plate.encloses(node("Zoom").get_rect()),"The open slider is one row at the minimap's width (%s)" % plate)
    check(node("Mastery").modulate.a==0.0 and plate.intersects(mastery) and node("Gate").modulate.a==1.0 and not plate.intersects(node("Gate").get_rect()),"It takes the Mastery chip's place only; Next Stage stays visible")
    var slider: HSlider=node("Zoom/Slider")
    var knob: Texture2D=slider.get_theme_icon("grabber")
    check(slider.has_theme_icon_override("grabber") and knob.get_width()==26 and knob.get_image().get_pixel(13,13).a==1.0 and knob.get_image().get_pixel(0,0).a==0.0,"The grabber is round (26 px), not the white square")
    slider.value=1.5;await frames(2)
    check(is_equal_approx(SettingsState.camera_zoom,1.5) and node("ZoomButton").text=="1.5×","Moving it still zooms")
    node("ZoomButton").pressed.emit();await frames(3)
    check(not node("Zoom").visible and node("Mastery").modulate.a==1.0,"A second tap closes it and Mastery returns")
    SettingsState.set_camera_zoom(2.0)
