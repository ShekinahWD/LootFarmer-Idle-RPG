extends Node
## Change 64 rendered capture and bounds audit (run windowed at 432x960 and 540x960, not headless):
##   Godot --path . --resolution 432x960 tests/change_64_capture.tscn -- --no-autosave --first-run-complete [--locale=de_DE] [--only=prestige]
## Writes PNGs to docs/Change_64_Evidence/<width>x<height>[_<locale>]/ and prints one BOUNDS line per
## control that leaves the viewport, its scroll viewport (horizontally) or its card, plus TRUNCATED for a
## single-line label or button whose text is cut. Surfaces: the visual Teleport picker, the Prestige
## panel with maximum content (every map, every opportunity, long names), the largest offered-card set
## with a selection, both Prestige confirmations, and the Offline receipt locked / partial / unlocked.
## State set directly is a fixture (labelled); every screen is the real UI.
var sim
var game
var out:=""
var problems:=0
var only:=""
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name: String) -> void:
    await frames(10)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out+name+".png"))
    print("SHOT ",out+name+".png")

func run() -> void:
    var locale:=""
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--locale="):locale=arg.trim_prefix("--locale=")
        if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
    var view:=Vector2(DisplayServer.window_get_size())
    out="res://docs/Change_64_Evidence/%dx%d%s/" % [int(view.x),int(view.y),"" if locale=="" else "_"+locale]
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.set_physics_process(false)
    # A real language selection (as Settings does); "automatic" is restored before quitting.
    if locale!="":LocalizationService.select_language(locale);await frames(4)
    if only in ["","teleport"]:await teleport_shots()
    if only in ["","prestige"]:await prestige_shots()
    if only in ["","offline"]:await offline_shots()
    if only in ["","banner"]:await banner_shots()
    print("CHANGE_64_CAPTURE ",out," PROBLEMS ",problems)
    if locale!="":LocalizationService.select_language("automatic")
    get_tree().quit(0)

func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.campaign.onboarding.reveal_all(true);sim.suspended=false
    sim.state.player.quiet=1e9
    for e in sim.state.enemies:e.aggro=false
    game._close();game.toast_queue.clear();game.get_node("Toast").hide()
    game.get_node("PrestigeConfirm").close();game._cancel_confirm()

# ---------------------------------------------------------------- bounds audit
## Every visible control under root must stay inside the viewport, horizontally inside the nearest
## scroll viewport, and inside the card (PanelContainer / Button) that holds it.
func audit(surface: String,root: Control) -> void:
    var view:=get_viewport().get_visible_rect()
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var safe:=Rect2(view.position+Vector2(insets.x,insets.y),view.size-Vector2(insets.x+insets.z,insets.y+insets.w))
    var nodes: Array=[root]+root.find_children("*","Control",true,false)
    for node in nodes:
        if not node.is_visible_in_tree() or node.size==Vector2.ZERO:continue
        var r: Rect2=node.get_global_rect()
        var scroll:=_ancestor(node,"ScrollContainer")
        if scroll==null:
            if r.position.x<safe.position.x-.5 or r.end.x>safe.end.x+.5 or r.position.y<safe.position.y-.5 or r.end.y>safe.end.y+.5:_report(surface,"BOUNDS viewport",node,r,safe)
        else:
            var s: Rect2=scroll.get_global_rect()
            if r.position.x<s.position.x-.5 or r.end.x>s.end.x+.5:_report(surface,"BOUNDS scroll-width",node,r,s)
            if s.position.x<safe.position.x-.5 or s.end.x>safe.end.x+.5:_report(surface,"BOUNDS scroll-viewport",scroll,s,safe)
        var card:=_card_ancestor(node)
        if card!=null:
            var c: Rect2=card.get_global_rect()
            if r.position.x<c.position.x-.5 or r.end.x>c.end.x+.5 or r.end.y>c.end.y+.5:_report(surface,"BOUNDS card",node,r,c)
        if (node is Label or node is Button) and node.text!="" and node.autowrap_mode==TextServer.AUTOWRAP_OFF and node.text_overrun_behavior!=TextServer.OVERRUN_NO_TRIMMING:
            var font: Font=node.get_theme_font("font")
            var width: float=0.0
            for line in node.text.split("\n"):width=maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,node.get_theme_font_size("font_size")).x)
            var room: float=node.size.x-(node.get_theme_stylebox("normal").get_minimum_size().x if node is Button else 0.0)
            if node is Button and node.icon!=null:room-=node.get_theme_constant("icon_max_width")+node.get_theme_constant("h_separation")
            if width>room+1:_report(surface,"TRUNCATED",node,r,Rect2(Vector2.ZERO,Vector2(width,0)))
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
        if p is PanelContainer and p.theme_type_variation==&"Card":return p
        if p is Button:return p
        if p is ScrollContainer:return null
        p=p.get_parent()
    return null
func _report(surface: String,kind: String,node: Control,r: Rect2,limit: Rect2) -> void:
    problems+=1
    var text:=""
    if "text" in node:text=str(node.text).substr(0,60).replace("\n"," / ")
    print("%s %s %s rect=%s limit=%s text=\"%s\"" % [kind,surface,str(game.get_path_to(node)),str(r),str(limit),text])

# ---------------------------------------------------------------- teleport
func teleport_shots() -> void:
    fresh()
    sim.state.unlocked_stage=8 # fixture: every map reached
    for st in range(1,9):
        var n: int=sim.catalog.stages[st-1].spawns.size()
        sim.state.camps[str(st)]=[0] if st!=3 else range(n)
        sim.state.camps_known[str(st)]=range(n)
    sim.state.camps["1"]=[0,1];sim.state.spawns=sim.state.camps["1"]
    var a: Array=sim.campaign.stage().spawns[0];sim.state.player.x=a[0];sim.state.player.y=a[1]
    sim.campaign.reveal()
    game._settle_camp();game.selected_camp=0;game._open("camp")
    await shot("teleport_01_camp_menu")
    game.teleport_target=[];game.teleport_stage=0;game._open("teleport")
    await shot("teleport_02_picker_current_map")
    audit("teleport",game.sheet)
    game.teleport_target=[1,1];game._refresh_panel(true)
    await shot("teleport_03_selected_same_map")
    audit("teleport_selected",game.sheet)
    game.teleport_stage=3;game.teleport_target=[3,2];game._refresh_panel(true)
    await shot("teleport_04_other_map_selected")
    audit("teleport_other",game.sheet)
    game.teleport_stage=5;game._refresh_panel(true)
    await shot("teleport_05_map_one_camp_no_selection_here")
    var e: Dictionary=sim.state.enemies[0];e.aggro=true # fixture: combat starts while choosing
    game.teleport_stage=3;game._refresh_panel(true)
    await shot("teleport_06_blocked_in_combat")
    audit("teleport_combat",game.sheet)
    e.aggro=false
    game._close()

# ---------------------------------------------------------------- prestige
func prestige_fixture() -> void:
    fresh()
    sim.state.unlocked_stage=8 # fixture
    var g:int=sim.campaign.prestige_unlock_group();sim.state.group_kills[g]=1 # fixture: Snowman defeated
    var i:=0
    for op in sim.catalog.campaign.opportunities:
        # fixture: every opportunity discovered; a third ready, a few consumed, the rest in progress
        sim.state.opportunities[op.id]={"ready":i%3==0,"baseline":{},"step":0,"count":0}
        if i%7==3:sim.state.consumed.append(op.id)
        i+=1
    var by_path: Dictionary={}
    for key in sim.catalog.campaign.cards:
        var p: String=sim.catalog.campaign.cards[key].path
        if not by_path.has(p):by_path[p]=[]
        by_path[p].append(key)
    # fixture: one owned card per path (owned grid with many cards, offers still open)
    # (Expedition keeps all eight: the catalog's largest offer.)
    for p in by_path:
        if p!="expedition":sim.state.owned_cards.append(by_path[p][0])
    for st in range(0,9):sim.state.prestige_collapsed[str(st)]=false
    for op in sim.catalog.campaign.opportunities:
        if sim.campaign.can_follow(op.id):sim.campaign.toggle_follow(op.id);break
    sim.touch()

func prestige_shots() -> void:
    await prestige_fixture()
    game._open("prestige")
    await shot("prestige_01_panel_top")
    audit("prestige_panel",game.sheet)
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    # Pages through the whole list (the long stage-grouped opportunity cards, chips and actions).
    var page:=0
    while scroll.scroll_vertical<int(scroll.get_v_scroll_bar().max_value-scroll.size.y) and page<6:
        scroll.scroll_vertical+=int(scroll.size.y*.9);page+=1
        if page in [1,3,5]:await shot("prestige_02_panel_page_%d" % page)
    scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value)
    await shot("prestige_03_panel_bottom_owned_cards")
    # The Prestige confirmation with every ready opportunity.
    game._open_prestige_confirm(sim.campaign.awardable_ids())
    await shot("prestige_04_confirm")
    audit("prestige_confirm",game.get_node("PrestigeConfirm"))
    var body: ScrollContainer=game.get_node("PrestigeConfirm/Plate/Margin/Content/Scroll")
    body.scroll_vertical=int(body.get_v_scroll_bar().max_value)
    await shot("prestige_05_confirm_bottom")
    game.get_node("PrestigeConfirm").close()
    # The largest offered-card set: the path with the most cards first in the batch (fixture order).
    var counts: Dictionary={}
    for key in sim.catalog.campaign.cards:
        var p: String=sim.catalog.campaign.cards[key].path
        counts[p]=int(counts.get(p,0))+(0 if sim.state.owned_cards.has(key) else 1)
    var ids: Array=sim.campaign.awardable_ids()
    ids.sort_custom(func(x,y):return int(counts.get(x.rsplit("_",true,1)[0],0))>int(counts.get(y.rsplit("_",true,1)[0],0)))
    check_begin()
    sim.state.prestige_batch={"ids":ids,"choices":[],"transaction":"capture"} # fixture: batch order
    sim.touch()
    game.selected_card="";game._open("prestige")
    print("OFFERED ",sim.campaign.offered_cards().size()," of path ",ids[0])
    await shot("prestige_06_choice_offers")
    audit("prestige_choice",game.sheet)
    game.selected_card=sim.campaign.offered_cards()[sim.campaign.offered_cards().size()-1];game._refresh_panel(true)
    scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value)
    await shot("prestige_07_choice_selected_bottom")
    audit("prestige_choice_selected",game.sheet)
    game._confirm(tr("PRESTIGE_CARD_CONFIRM") % sim.catalog.campaign.cards[game.selected_card].name,func()->void:pass)
    await shot("prestige_08_card_confirm")
    audit("prestige_card_confirm",game.get_node("Confirm"))
    game._cancel_confirm()
    sim.state.prestige_batch={};game.selected_card="";game._close()

func check_begin() -> void:
    print("PRESTIGE_BLOCK ",sim.campaign.prestige_block_reason()," READY ",sim.campaign.awardable_ids().size())

# ---------------------------------------------------------------- offline
func pending(items: Dictionary) -> void:
    sim.state.offline_pending={"id":"cap-%d" % randi(),"seconds":7.5*3600,"longest":7.5*3600,"rewarded_hours":5.0,"coins":1250.0,"gems":15.0,"items":items} # fixture

func offline_shots() -> void:
    fresh()
    pending({})
    game._open("offline")
    await shot("offline_01_locked")
    audit("offline_locked",game.sheet)
    game._close()
    fresh()
    sim.state.upgrades["offline_weapon"]=1 # fixture: Weapons unlocked, nothing earned this time
    pending({})
    game._open("offline")
    await shot("offline_02_partial")
    audit("offline_partial",game.sheet)
    game._close()
    fresh()
    for u in ["offline_weapon","offline_outfit","offline_consumable"]:sim.state.upgrades[u]=1 # fixture
    var weapon:="";var outfit:=""
    for id in sim.catalog.items:
        var kind: String=sim.catalog.items[id].kind
        if kind=="weapon" and weapon=="":weapon=id
        if kind=="outfit" and outfit=="":outfit=id
    pending({weapon:3,outfit:2,"potion":4})
    game._open("offline")
    await shot("offline_03_unlocked_items")
    audit("offline_unlocked",game.sheet)
    game._close()

# ---------------------------------------------------------------- discovery banner
## The in-game banner shown when an opportunity is discovered / ready: one reward chip per card of its
## path. Every path size is shown once; the largest (eight cards) are captured.
func banner_shots() -> void:
    fresh()
    sim.state.tutorial.seen.append("road_ahead") # fixture: the one-time goals card already read
    await frames(4)
    var largest:=0
    var by_size: Dictionary={}
    for op in sim.catalog.campaign.opportunities:
        var n: int=game._path_cards(str(op.path)).size()
        if not by_size.has(n):by_size[n]=op.id
        largest=maxi(largest,n)
    var sizes: Array=by_size.keys();sizes.sort()
    for n in sizes:
        game.banner.queue.clear();game.banner._finish()
        game._milestone("ready" if n==largest else "discovered",str(by_size[n]))
        await frames(20)
        audit("banner_%d_cards" % n,game.banner.get_node("Plate"))
        if n==largest or n==sizes[0]:await shot("banner_%d_cards" % n)
    game.banner.queue.clear();game.banner._finish()
