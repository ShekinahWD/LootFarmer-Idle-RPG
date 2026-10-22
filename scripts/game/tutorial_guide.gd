extends Control
## One guide owns all guidance presentation (playbook 18.8).
## - Logical progress: tutorial.done / tutorial.seen in the profile (kept by prestige, cleared by Hard Reset).
## - Pending step: derived from game state every frame, with the surface it belongs to; never saved.
## - Presentation: caption card, owned arrow pointer and frame, recomputed from the live control each
##   frame. Nothing here takes input except the "Got it" button of an introduction card.
## An unrelated panel, a confirmation, pause or a prestige choice suspends (hides) all guidance; the
## step stays pending and returns when that surface closes.
const FRAME=preload("res://assets/KenneyFantasyUI/PNG/Default/Transparent center/panel-transparent-center-000.png")
const ARROW=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-273.png")
const ITEM_ROOT="res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-%d.png"
const LESSONS=["move","kill","collect","equip","merge","upgrade","camp"]
## The cropped arrow art points up-left; its tip sits about 0.45 of the pointer size from the center.
const ARROW_BASE_ANGLE:=-PI*.75
const POINTER_SIZE:=64.0
var ui
var sim
var blocker: Control
var chooser: PanelContainer
var card: PanelContainer
var title: Label
var support: Label
var picture: TextureRect
var highlight: NinePatchRect
var shade: NinePatchRect
var pointer: TextureRect
var intro_button: Button
var pending: String=""
var step: String=""
var surfaces: Array=[]
var suspended_by: String=""
var intro_id: String=""
var target: Control
var world_target:=Vector2.INF
var scrolled_for: String=""
var pulse: float=0

func setup(owner_ui) -> void:
    ui=owner_ui;sim=ui.sim
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    theme=ui.theme
    # The first-launch chooser is the only modal: it is a decision, shown before the first tick.
    blocker=Control.new();blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);blocker.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(blocker)
    chooser=PanelContainer.new();add_child(chooser)
    var list:=VBoxContainer.new();list.add_theme_constant_override("separation",12);chooser.add_child(list)
    var heading:=Label.new();heading.text=tr("GUIDE_CHOOSE");heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(heading)
    for mode in ["guided","basic","none"]:
        var button:=Button.new();button.custom_minimum_size.y=76;button.text=tr("GUIDE_MODE_"+mode.to_upper());list.add_child(button)
        button.pressed.connect(func()->void:choose(mode))
    card=PanelContainer.new();card.theme_type_variation=&"Backing";card.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(card)
    var content:=VBoxContainer.new();content.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_theme_constant_override("separation",4);card.add_child(content)
    var row:=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_theme_constant_override("separation",12);content.add_child(row)
    picture=TextureRect.new();picture.custom_minimum_size=Vector2(44,44);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(picture)
    title=Label.new();title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_theme_font_size_override("font_size",24);title.add_theme_color_override("font_color",Color(1,.88,.5));title.add_theme_constant_override("outline_size",4);title.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(title)
    support=Label.new();support.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;support.add_theme_font_size_override("font_size",20);support.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(support)
    intro_button=Button.new();intro_button.text=tr("GUIDE_GOT_IT");intro_button.custom_minimum_size=Vector2(180,64);intro_button.size_flags_horizontal=Control.SIZE_SHRINK_END;content.add_child(intro_button)
    intro_button.pressed.connect(func()->void:
        if intro_id!="" and not sim.state.tutorial.seen.has(intro_id):sim.state.tutorial.seen.append(intro_id);sim.touch())
    shade=_frame(Color(0,0,0,.85));highlight=_frame(Color(1,.85,.4))
    pointer=TextureRect.new();pointer.texture=ui.cropped(ARROW);pointer.custom_minimum_size=Vector2.ONE*POINTER_SIZE;pointer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;pointer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    pointer.size=Vector2.ONE*POINTER_SIZE;pointer.pivot_offset=pointer.size*.5;pointer.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(pointer)
    sim.suspended=sim.state.tutorial.mode=="pending"

func _frame(color: Color) -> NinePatchRect:
    var f:=NinePatchRect.new();f.texture=FRAME
    f.patch_margin_left=8;f.patch_margin_right=8;f.patch_margin_top=8;f.patch_margin_bottom=8
    f.draw_center=false;f.mouse_filter=Control.MOUSE_FILTER_IGNORE;f.modulate=color;add_child(f)
    return f

func choose(mode: String) -> void:
    sim.state.tutorial.mode=mode;sim.suspended=false;sim.touch();SaveService.save_now()

func _process(dt: float) -> void:
    if sim==null:return
    pulse+=dt
    var data: Dictionary=sim.state.tutorial
    chooser.visible=data.mode=="pending"
    blocker.visible=chooser.visible
    if chooser.visible:
        sim.suspended=true
        # Change 10: centred from the chooser's real size on the X axis of the safe area (it was
        # placed by its smaller minimum width while drawn 600 wide, so it sat right of centre).
        var insets:=LayoutService.get_safe_area_insets_canvas()
        var width:=minf(600,ui.size.x-insets.x-insets.z-48)
        var wanted:=Vector2(maxf(width,chooser.get_combined_minimum_size().x),chooser.get_combined_minimum_size().y)
        if not chooser.size.is_equal_approx(wanted):chooser.size=wanted
        var at:=Vector2(ui.centered_x(chooser.size.x,insets),(ui.size.y-chooser.size.y)*.5)
        if not chooser.position.is_equal_approx(at):chooser.position=at
        _hide_all();return
    _complete_lessons()
    evaluate()
    _present()

## A lesson completes when its learned state exists, however and whenever the player reached it.
func _complete_lessons() -> void:
    var data: Dictionary=sim.state.tutorial
    var arrival: Array=sim.campaign.stage().spawns[0]
    var complete: Array=[sim.position_of(sim.state.player).distance_to(Vector2(arrival[0],arrival[1]))>48 or sim.campaign.counter("kill")>0,
        sim.campaign.counter("kill")>0,not sim.state.items.is_empty(),sim.state.weapon!="" or sim.state.outfit!="",
        sim.state.items.values().any(func(r):return r.merge>0),not sim.state.upgrades.is_empty(),sim.campaign.counter("camp")>0]
    for i in range(LESSONS.size()):
        if complete[i] and not data.done.has(LESSONS[i]):data.done.append(LESSONS[i]);sim.touch()

func evaluate() -> void:
    pending="";step="";surfaces=[""];target=null;world_target=Vector2.INF;intro_id=""
    var data: Dictionary=sim.state.tutorial
    if data.mode=="none":return
    if data.mode=="guided":
        for lesson in LESSONS:
            if not data.done.has(lesson):pending=lesson;break
        if pending!="":_lesson(pending);return
    elif not data.seen.has("overview"):
        pending="overview";intro_id="overview";step="overview";return
    # Contextual introductions in every mode except None: shown once, on the HUD only.
    for pair in [["camp_done",sim.campaign.counter("camp")>0 and data.mode=="guided"],["aggression",sim.state.stage>=2],["skills",sim.campaign.skill_count()>0],["groups",sim.state.stage>=3],["prestige",not sim.state.opportunities.is_empty()],["rest",sim.state.player.hp>0 and sim.state.player.hp<sim.stats().hp*.4 and not sim.campaign.in_combat()]]:
        if pair[1] and not data.seen.has(pair[0]):pending=pair[0];intro_id=pair[0];step=pair[0];return

func _lesson(lesson: String) -> void:
    step=lesson
    match lesson:
        "move":target=ui.stick
        "kill":world_target=_nearest_enemy()
        "collect":
            world_target=_nearest_pickup()
            if world_target==Vector2.INF:step="collect_wait";world_target=_nearest_enemy()
        "equip":
            surfaces=["","item"]
            var id:=_first_item(func(i):return sim.catalog.items[i].kind in ["weapon","outfit"])
            # The first find may be a supply. Progress follows the real inventory: with no gear to
            # equip, ask for an attainable step (pick up gear on the ground, or farm for it, pointing
            # at an empty gear slot when no enemy is in sight) instead of an impossible Equip.
            if id=="":
                var drop:=_nearest_pickup(true)
                if drop!=Vector2.INF:step="equip_collect";world_target=drop;return
                step="equip_find";world_target=_nearest_enemy()
                if world_target==Vector2.INF:target=_slot("")
                return
            if ui.sheet.visible and ui.panel=="item" and ui.selected!="" and sim.catalog.items[ui.selected].kind in ["weapon","outfit"]:
                step="equip_tap";target=_panel_control("equip")
            else:
                step="equip";target=_slot(id)
        "merge":
            surfaces=["","item"]
            var id:=_first_item(func(i):return sim.quantity(i)>1 and sim.record(i).merge<sim.merge_cap(i))
            if id=="":step="merge_wait";world_target=_nearest_enemy();return
            var open: String=ui.selected if ui.sheet.visible and ui.panel=="item" else ""
            if open!="" and sim.catalog.items.has(open) and sim.quantity(open)>1 and sim.record(open).merge<sim.merge_cap(open):step="merge_tap";target=_panel_control("merge")
            else:step="merge";target=_slot(id)
        "upgrade":
            surfaces=["","enemy"]
            var g: int=ui.combat_group if sim.campaign.discovered(ui.combat_group) else sim.nearest_group()
            if not sim.campaign.discovered(g):step="upgrade_find";world_target=_nearest_enemy();return
            var price: int=sim.upgrade_cost("loot",g)
            if sim.state.coins<price:step="upgrade_earn";support_value=price-int(sim.state.coins);return
            if ui.sheet.visible and ui.panel=="enemy":
                if ui.enemy_tab!=1:step="upgrade_tab";target=_panel_control("tab_tab_upgrades")
                else:
                    step="upgrade_buy";target=_panel_control("buy_loot",true)
                    if target==null:target=_panel_control("buy_upgrade",true)
            else:step="upgrade";target=ui.get_node("Safe/Layout/Map/EnemyUpgrades")
        "camp":
            surfaces=["","world","camp"]
            var camp:=-1
            for i in range(sim.campaign.stage().spawns.size()):
                var a: Array=sim.campaign.stage().spawns[i]
                if not sim.state.spawns.has(i) and sim.campaign.camp_known(i):camp=i;break
            # Never point at an undiscovered place: ask for exploration instead.
            if camp<0:step="camp_explore";target=ui.stick;return
            var price: int=sim.campaign.camp_price(camp)
            if sim.state.coins<price:step="camp_earn";support_value=price-int(sim.state.coins);return
            if ui.sheet.visible and ui.panel in ["world","camp"]:
                step="camp_buy";target=_panel_control("camp_buy_%d" % camp)
            else:step="camp";target=ui.dock.get_node("Navigation/World")

var support_value:=0

func _nearest_enemy() -> Vector2:
    var best:=Vector2.INF
    for e in sim.state.enemies:
        if e.hp<=0 or not sim.campaign.can_see(sim.position_of(e)) or sim.catalog.groups[int(e.group)].boss:continue
        if best==Vector2.INF or sim.position_of(e).distance_to(sim.position_of(sim.state.player))<best.distance_to(sim.position_of(sim.state.player)):best=sim.position_of(e)
    return best

func _nearest_pickup(gear_only:=false) -> Vector2:
    var best:=Vector2.INF
    for d in sim.state.pickups:
        if gear_only and sim.catalog.items[d.item].kind not in ["weapon","outfit"]:continue
        var p:=Vector2(d.x,d.y)
        if sim.campaign.can_see(p) and (best==Vector2.INF or p.distance_to(sim.position_of(sim.state.player))<best.distance_to(sim.position_of(sim.state.player))):best=p
    return best

func _first_item(test: Callable) -> String:
    for id in sim.state.gear+sim.state.supplies:
        if id!="" and test.call(id):return id
    return ""

func _slot(id: String) -> Control:
    var index: int=sim.state.gear.find(id)
    var grid: Node=ui.dock.get_node("Inventory/GearColumn/GearScroll/Gear")
    return grid.get_child(index) if index>=0 and index<grid.get_child_count() else null

## Controls are found by their guide tag, only in the open panel (rows and pinned actions).
func _panel_control(key: String,enabled_only:=false) -> Control:
    for root in [ui.actions,ui.rows]:
        for node in root.find_children("*","Button",true,false):
            if node.get_meta("guide","")==key and node.is_visible_in_tree() and not node.is_queued_for_deletion() and (not enabled_only or not node.disabled):return node
    return null

func _hide_all() -> void:
    card.hide();highlight.hide();shade.hide();pointer.hide()

func _present() -> void:
    var data: Dictionary=sim.state.tutorial
    suspended_by=""
    if get_tree().paused:suspended_by="pause"
    elif ui.get_node("Confirm").visible:suspended_by="confirmation"
    elif not sim.state.prestige_batch.is_empty():suspended_by="prestige"
    elif not ui.banner.current.is_empty():suspended_by="milestone"
    elif ui.sheet.visible and not surfaces.has(ui.panel):suspended_by=ui.panel
    elif not ui.sheet.visible and not surfaces.has(""):suspended_by="closed"
    if pending=="" or suspended_by!="" or (ui.sheet.visible and ui.sheet.modulate.a<1.0):
        _hide_all();return
    title.text=tr("GUIDE_"+step.to_upper())
    support.text=tr("GUIDE_"+step.to_upper()+"_DETAIL")
    if "%d" in support.text:support.text=support.text % support_value
    picture.texture=ui._art( (212 if step in ["skills","rest"] else (249 if step.begins_with("camp") else (211 if step=="prestige" else (1 if step in ["kill","aggression","groups","collect_wait","merge_wait","upgrade_find","equip_find","equip_collect"] else 60)))))
    intro_button.visible=intro_id!=""
    card.mouse_filter=Control.MOUSE_FILTER_IGNORE
    _place_card()
    if data.mode!="guided" or intro_id!="":
        highlight.hide();shade.hide();pointer.hide();return
    _point()

## The caption never covers the open panel: above it when there is room, otherwise hidden
## (the pointer alone continues the lesson). Without a panel it sits above the joystick.
func _place_card() -> void:
    var map: Control=ui.get_node("Safe/Layout/Map")
    var width:=minf(600,map.size.x-32)
    # Resize only on change: assigning a size every frame forces a relayout every frame.
    var height:=card.get_combined_minimum_size().y
    if not card.size.is_equal_approx(Vector2(width,height)):card.size=Vector2(width,height)
    var y:=map.global_position.y+map.size.y-206-height
    if ui.sheet.visible:
        y=ui.sheet.position.y-12-height
        if y<map.global_position.y+8:card.hide();return
    card.position=Vector2(map.global_position.x+(map.size.x-width)*.5,maxf(map.global_position.y+8,y))
    card.show()

func _point() -> void:
    var rect:=Rect2()
    var have:=false
    if is_instance_valid(target) and target.is_visible_in_tree() and not target.is_queued_for_deletion():
        var key:=step+":"+str(target.get_instance_id())
        var scroll: ScrollContainer=ui.get_node("Sheet/Margin/Content/Scroll")
        if scrolled_for!=key and scroll.is_ancestor_of(target):
            scroll.ensure_control_visible(target)
            scrolled_for=key
        rect=target.get_global_rect()
        # Inside the scroll list only the visible part counts; never point at off-screen controls.
        if scroll.is_ancestor_of(target):
            var visible_rect:=scroll.get_global_rect()
            have=visible_rect.encloses(rect.grow(-4))
        else:have=ui.get_global_rect().encloses(rect)
    elif world_target!=Vector2.INF:
        var map: Control=ui.get_node("Safe/Layout/Map")
        var screen: Vector2=ui.world.get_canvas_transform()*world_target
        screen=map.global_position+screen*map.size/Vector2(ui.world.get_viewport_rect().size)
        rect=Rect2(screen-Vector2(16,40),Vector2(32,44))
        have=map.get_global_rect().grow(-24).has_point(screen) and not (ui.sheet.visible and ui.sheet.get_global_rect().has_point(screen))
    if not have:
        highlight.hide();shade.hide();pointer.hide();return
    var glow:=.75+.25*sin(pulse*4)
    if is_instance_valid(target) and world_target==Vector2.INF:
        highlight.position=rect.position-Vector2.ONE*4;highlight.size=rect.size+Vector2.ONE*8
        shade.position=rect.position-Vector2.ONE*7;shade.size=rect.size+Vector2.ONE*14
        highlight.modulate=Color(1,.85,.4,glow);highlight.show();shade.show()
    else:
        highlight.hide();shade.hide()
    # Point from above unless the target is in the top third, then from below.
    var from_above: bool=rect.get_center().y>ui.size.y*.33
    var direction:=Vector2.DOWN if from_above else Vector2.UP
    var tip:=Vector2(rect.get_center().x,rect.position.y if from_above else rect.end.y)
    var bob:=6.0*sin(pulse*5)
    pointer.rotation=direction.angle()-ARROW_BASE_ANGLE
    pointer.position=tip-direction*(POINTER_SIZE*.45+6+bob)-pointer.size*.5
    pointer.position.x=clampf(pointer.position.x,4,ui.size.x-POINTER_SIZE-4)
    pointer.show()
