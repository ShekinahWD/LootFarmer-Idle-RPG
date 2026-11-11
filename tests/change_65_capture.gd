extends Node
## Change 65 rendered capture and bounds audit (run windowed at 432x960 and 540x960, not headless):
##   Godot --path . --resolution 432x960 tests/change_65_capture.tscn -- --no-autosave --first-run-complete [--locale=de_DE] [--only=cards] [--out=<dir>]
## Writes PNGs to <out>/<width>x<height>[_<locale>]/ (default: user://change_65_capture/) and prints one
## BOUNDS line per control that leaves the safe viewport, its scroll viewport or its card, plus TRUNCATED
## for a single-line label or button whose text is cut. Surfaces: Player Upgrades with Focused Farming
## locked / owned, the enemy panel (Farm locked with its path, Farm owned, per-type automation), the
## Basic opening cards 1/2/5/6/8, Help (landing, topics, a category, an advanced card, Auto-Advance), the
## mode chooser's Help line, every one of the 14 card demonstrations at its key frame, and the Guided
## first-attack gesture and its Auto-Attack explanation. State set directly is a fixture (labelled).
const HelpCards=preload("res://scripts/game/help_cards.gd")
var sim
var game
var viewer
var out:=""
var problems:=0
var only:=""
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name: String) -> void:
    await frames(10)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out)+name+".png")
    print("SHOT ",ProjectSettings.globalize_path(out)+name+".png")

func run() -> void:
    var locale:=""
    var root:="user://change_65_capture/"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--locale="):locale=arg.trim_prefix("--locale=")
        if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
        if arg.begins_with("--out="):root=arg.trim_prefix("--out=").trim_suffix("/")+"/"
    var view:=Vector2(DisplayServer.window_get_size())
    out=root+"%dx%d%s/" % [int(view.x),int(view.y),"" if locale=="" else "_"+locale]
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;viewer=game.help_viewer
    sim.set_physics_process(false)
    if locale!="":LocalizationService.select_language(locale);await frames(4)
    if only in ["","chooser"]:await chooser_shots()
    if only in ["","focus"]:await focus_shots()
    if only in ["","basic"]:await basic_shots()
    if only in ["","help"]:await help_shots()
    if only in ["","cards"]:await card_shots()
    if only in ["","guided"]:await guided_shots()
    print("CHANGE_65_CAPTURE ",ProjectSettings.globalize_path(out)," PROBLEMS ",problems)
    if locale!="":LocalizationService.select_language("automatic")
    get_tree().quit(0)

func fresh(mode:="none") -> void:
    get_tree().paused=false
    viewer.hide();sim.held=false
    sim.new_profile();sim.state.tutorial.mode=mode;sim.suspended=false
    if mode!="guided":sim.campaign.onboarding.reveal_all(true)
    HelpCards.progress(sim.state.tutorial).basic_done=mode!="basic"
    sim.state.tutorial.seen.append("road_ahead") # fixture: the goals card is not part of these screens
    sim.state.player.quiet=1e9
    for e in sim.state.enemies:e.aggro=false
    game._close();game.toast_queue.clear();game.get_node("Toast").hide()
    game.get_node("PrestigeConfirm").close();game._cancel_confirm()

# ---------------------------------------------------------------- bounds audit (as change_64_capture)
func audit(surface: String,root: Control) -> void:
    var view:=get_viewport().get_visible_rect()
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var safe:=Rect2(view.position+Vector2(insets.x,insets.y),view.size-Vector2(insets.x+insets.z,insets.y+insets.w))
    var nodes: Array=[root]+root.find_children("*","Control",true,false)
    for node in nodes:
        if not node.is_visible_in_tree() or node.size==Vector2.ZERO:continue
        if node==viewer or node==viewer.backdrop:continue
        var r: Rect2=node.get_global_rect()
        var scroll:=_ancestor(node,"ScrollContainer")
        if scroll==null:
            if r.position.x<safe.position.x-.5 or r.end.x>safe.end.x+.5 or r.position.y<safe.position.y-.5 or r.end.y>safe.end.y+.5:_report(surface,"BOUNDS viewport",node,r,safe)
        else:
            var s: Rect2=scroll.get_global_rect()
            if r.position.x<s.position.x-.5 or r.end.x>s.end.x+.5:_report(surface,"BOUNDS scroll-width",node,r,s)
        var card:=_card_ancestor(node)
        # The panel sheet scrolls its rows; it is not a card that must contain them.
        if card!=null and not (scroll!=null and card.is_ancestor_of(scroll)):
            var c: Rect2=card.get_global_rect()
            if r.position.x<c.position.x-.5 or r.end.x>c.end.x+.5 or r.end.y>c.end.y+.5:_report(surface,"BOUNDS card",node,r,c)
        if (node is Label or node is Button) and node.text!="" and node.autowrap_mode==TextServer.AUTOWRAP_OFF and node.text_overrun_behavior!=TextServer.OVERRUN_NO_TRIMMING:
            var font: Font=node.get_theme_font("font")
            var width: float=0.0
            for line in node.text.split("\n"):width=maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,node.get_theme_font_size("font_size")).x)
            var room: float=node.size.x-(node.get_theme_stylebox("normal").get_minimum_size().x if node is Button else 0.0)
            if node is Button and node.icon!=null:room-=node.get_theme_constant("icon_max_width")+node.get_theme_constant("h_separation")
            if width>room+1:_report(surface,"TRUNCATED",node,r,Rect2(Vector2.ZERO,Vector2(width,0)))
        # Wrapped labels must fit their reserved height (no text below the panel).
        if node is Label and node.autowrap_mode!=TextServer.AUTOWRAP_OFF and node.get_line_count()>0 and node.get_visible_line_count()<node.get_line_count():_report(surface,"CLIPPED lines",node,r,Rect2())
    print("AUDIT ",surface," done")

func _ancestor(node: Node,type: String) -> Control:
    var p:=node.get_parent()
    while p!=null and p is Control:
        if p.is_class(type):return p
        p=p.get_parent()
    return null
func _card_ancestor(node: Node) -> Control:
    var p:=node.get_parent()
    while p!=null and p is Control:
        if p is PanelContainer or p is Button:return p
        p=p.get_parent()
    return null
func _report(surface: String,kind: String,node: Control,r: Rect2,limit: Rect2) -> void:
    problems+=1
    print("%s %s %s '%s' %s limit %s" % [kind,surface,node.get_path(),str(node.get("text")).left(40) if node.get("text")!=null else "",r,limit])

func sheet_audit(surface: String) -> void:
    audit(surface,game.get_node("Sheet"))

# ---------------------------------------------------------------- surfaces
func chooser_shots() -> void:
    sim.new_profile();viewer.hide();game._close();await frames(8)
    await shot("01_chooser_help_line")
    audit("chooser",game.guide.chooser)

func focus_shots() -> void:
    fresh("none")
    var g: int=int(sim.catalog.stages[0].groups[0])
    for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,int(v)) # fixture: spot found
    sim.state.gems=12.0 # fixture: not enough for the unlock
    game.player_tab=0;game._open("upgrades");await frames(4)
    var buy: Control=_meta("buy_focus")
    if buy!=null:game.get_node("Sheet/Margin/Content/Scroll").ensure_control_visible(buy)
    await shot("02_player_focus_locked");sheet_audit("player_focus_locked")
    sim.state.gems=40.0;game._refresh_panel(true);await frames(4)
    if _meta("buy_focus")!=null:game.get_node("Sheet/Margin/Content/Scroll").ensure_control_visible(_meta("buy_focus"))
    await shot("03_player_focus_buyable")
    sim.buy_upgrade("focus");game._refresh_panel(true);await frames(4)
    if _meta("buy_focus")!=null:game.get_node("Sheet/Margin/Content/Scroll").ensure_control_visible(_meta("buy_focus"))
    await shot("04_player_focus_owned");sheet_audit("player_focus_owned")
    sim.state.upgrades.erase("focus") # fixture: back to locked for the enemy panel
    game.group=g;game.enemy_tab=1;game.enemy_variant=2;game._open("enemy");await frames(4)
    await shot("05_enemy_farm_locked_automation");sheet_audit("enemy_locked")
    sim.state.upgrades["focus"]=1 # fixture: owned
    sim.state.gems=200.0;sim.buy_upgrade("collect",g)
    game._refresh_panel(true);await frames(4)
    await shot("06_enemy_farm_owned_automation");sheet_audit("enemy_owned")
    game._close()

func freeze(id: String,t: float) -> void:
    viewer.demo.playing=false;viewer.demo.time=t;viewer.demo._apply_fade();viewer.demo.queue_redraw()

func basic_shots() -> void:
    fresh("basic")
    sim.state.tutorial.seen.erase("road_ahead") # the opening shows only before The Road Ahead
    game.guide.choose("basic");await frames(6)
    if not viewer.visible or viewer.context!="basic":
        problems+=1;print("BASIC viewer did not open");return
    var order: Array=HelpCards.essential()
    for n in [1,2,5,6,8]:
        for k in range(8):
            if viewer.index>=n-1:break
            viewer.step(1)
        freeze(viewer.current(),float(viewer.demo.KEY_TIMES.get(viewer.current(),2.0)))
        await shot("07_basic_card_%d_%s" % [n,order[n-1]])
        audit("basic_card_%d" % n,viewer.panel)
    viewer.demo.playing=true
    viewer.close_viewer();await frames(2)

func help_shots() -> void:
    fresh("none")
    HelpCards.mark_viewed(sim.state.tutorial,"movement_combat");HelpCards.mark_viewed(sim.state.tutorial,"merge_gear") # fixture: two read
    HelpCards.set_last(sim.state.tutorial,"collect_equip")
    game.help_page="home";game._open("help");await frames(4)
    await shot("08_help_landing");sheet_audit("help_landing")
    game.help_page="topics";game._refresh_panel(true);await frames(4)
    await shot("09_help_topics");sheet_audit("help_topics")
    game.help_page="equipment";game._refresh_panel(true);await frames(4)
    await shot("10_help_category_equipment");sheet_audit("help_category")
    viewer.open_help("help_topic",HelpCards.ids().find("weapon_evolution"))
    freeze("weapon_evolution",5.4)
    await shot("11_help_advanced_weapon_evolution");audit("help_card",viewer.panel)
    viewer.close_viewer();await frames(2)
    viewer.open_help("help_all",HelpCards.ids().find("prestige"));viewer.toggle_auto()
    for k in range(20):viewer._process(.25)
    freeze("prestige",5.6)
    await shot("12_help_read_all_auto_advance");audit("help_auto",viewer.panel)
    viewer.toggle_auto();viewer.close_viewer();await frames(2)
    # The longest card texts (by rendered height) for the language, kept inside the fixed panel.
    var longest:="";var most:=0
    for id in HelpCards.ids():
        var n:=(tr(HelpCards.action_key(id))+tr(HelpCards.support_key(id))).length()
        if n>most:most=n;longest=id
    viewer.open_help("help_topic",HelpCards.ids().find(longest));freeze(longest,2.0)
    await shot("13_help_longest_card_"+longest);audit("help_longest",viewer.panel)
    viewer.demo.playing=true;viewer.close_viewer();await frames(2)

func card_shots() -> void:
    fresh("none")
    var ids: Array=HelpCards.ids()
    for i in range(ids.size()):
        viewer.open_help("help_all",i)
        freeze(ids[i],float(viewer.demo.KEY_TIMES.get(ids[i],2.0)))
        await shot("20_card_%02d_%s" % [i+1,ids[i]])
        audit("card_"+str(ids[i]),viewer.panel)
        viewer.demo.playing=true
    viewer.close_viewer();await frames(2)

func guided_shots() -> void:
    fresh("guided")
    sim.campaign.guided.mark("move") # fixture: path walked
    var best: Dictionary={}
    for e in sim.state.enemies:
        if float(e.hp)>0 and not sim.catalog.groups[int(e.group)].boss and (best.is_empty() or sim.position_of(e).distance_to(sim.position_of(sim.state.player))<sim.position_of(best).distance_to(sim.position_of(sim.state.player))):best=e
    sim.state.player.x=float(best.x)-70;sim.state.player.y=float(best.y)+6 # fixture: an enemy in view
    sim.campaign.reveal();game.world.follow_player()
    await frames(40)
    await shot("30_guided_target_gesture")
    print("GUIDED step=%s aim=%s pointer=%s" % [game.guide.step,game.guide.aim.visible,game.guide.pointer.visible])
    # The real lesson: select the enemy, let the simulation run until the hero's first hit.
    var picked: bool=sim.select_target(best.id)
    print("GUIDED selected=%s" % picked)
    var t:=0.0
    while t<6.0 and not sim.campaign.guided.data().done.has("target"):
        sim.step(.05);t+=.05
    print("GUIDED lesson done=%s after %.2f s" % [sim.campaign.guided.data().done.has("target"),t])
    game.world.follow_player();await frames(20)
    await shot("31_guided_auto_attack_enabled")
    var map: Control=game.get_node("Safe/Layout/Map")
    var scale: Vector2=map.size/Vector2(game.world.get_viewport_rect().size)
    var hero: Vector2=map.global_position+game.world.player_screen_position()*scale
    var foe: Vector2=map.global_position+(game.world.get_canvas_transform()*sim.position_of(best))*scale
    var covered: bool=game.guide.card.get_global_rect().has_point(hero) or game.guide.card.get_global_rect().has_point(foe)
    print("GUIDED auto_attack card=%s hero=%s foe=%s covers=%s" % [game.guide.card.get_global_rect(),hero,foe,covered])
    if covered:problems+=1
    audit("guided_auto_attack",game.guide.card)

func _meta(key: String) -> Control:
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("guide","")==key and not b.is_queued_for_deletion():return b
    return null
