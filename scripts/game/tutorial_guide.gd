extends Control
## One guide owns all guidance presentation (playbook 18.8).
## - Logical progress: tutorial.done / tutorial.seen in the profile (kept by prestige, cleared by Hard Reset).
## - Pending step: derived from game state every frame, with the surface it belongs to; never saved.
## - Presentation: caption card, owned arrow pointer and frame, recomputed from the live control each
##   frame. Nothing here takes input except the "Got it" button of an introduction card.
## An unrelated panel, a confirmation, pause or a prestige choice suspends (hides) all guidance; the
## step stays pending and returns when that surface closes.
## Change 25: the three modes differ in what is open and how much is explained (campaign.onboarding).
## Guided keeps its staged reveal and pointer lessons (guided_progress.gd). Basic opens every menu and
## shows only BASIC_DECK, a short up-front overview (the same cards Help shows), each card retired by
## Got it or after OnboardingRules.card_seconds on screen, the whole deck by Skip; no later cards,
## tips or pointers. None opens every menu and explains nothing. All modes share one game-goals
## announcement, The Road Ahead: Guided at its end, Basic after the overview, None at once.
const FRAME=preload("res://assets/KenneyFantasyUI/PNG/Default/Transparent center/panel-transparent-center-000.png")
const ARROW=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-273.png")
const ITEM_ROOT="res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-%d.png"
const LESSONS=["move","kill","collect","equip","merge","missions","upgrade","camp","slots","snowman","prestige"]
## Change 25 Basic overview, in order (texts GUIDE_<ID>/_DETAIL). Help shows the same deck; in Guided,
## a card about a system the staged reveal has not opened yet is left out of Help (no spoilers).
## Change 35: basic_target (drag from the hero to an enemy, release to target it) follows the overview.
const BASIC_DECK:=["overview","basic_target","basic_gear","basic_growth","basic_world","basic_prestige"]
const DECK_FEATURE:={"basic_growth":"upgrades","basic_world":"world","basic_prestige":"prestige"}
## Guided introduction cards that also point (the Next Stage chip, the Follow button).
const POINTING_INTROS:=["snowman","prestige_follow","prestige_info"]
## The cropped arrow art points up-left; its tip sits about 0.45 of the pointer size from the center.
const ARROW_BASE_ANGLE:=-PI*.75
const POINTER_SIZE:=64.0
var ui
var sim
var blocker: Control
var final_backdrop: ColorRect
var chooser: PanelContainer
var chooser_heading: Label
var card: PanelContainer
var title: Label
var support: Label
var picture: TextureRect
var highlight: NinePatchRect
var shade: NinePatchRect
var pointer: TextureRect
var intro_button: Button
var skip_button: Button
var pending: String=""
var step: String=""
var surfaces: Array=[]
var suspended_by: String=""
var intro_id: String=""
var target: Control
var world_target:=Vector2.INF
## Change 16: the opening lesson's direction arrow, from the player toward this world point (INF: none).
var path_point:=Vector2.INF
var scrolled_for: String=""
var scroll_retries:=0
const SCROLL_RETRY_FRAMES:=20
var pulse: float=0
## Change 14: seconds the Focused Farming pointer has been on screen; it retires after FOCUS_HINT_SECONDS.
const ROAD_AHEAD_ID:="road_ahead"
const FOCUS_HINT_SECONDS:=45.0
var focus_shown: float=0
## Change 15: seconds the current Basic card has been on screen, and which card that is.
var card_shown: float=0
var card_for:=""
## Change 35: the Guided targeting demonstration, drawn over the map from the player to the enemy it
## suggests: a dashed path, a ring on the hero (start here) and on the enemy (release here), and the
## pointer travelling along it. Drawn only; it never takes input, so the real drag reaches the map.
var aim: Control
var aim_from:=Vector2.ZERO
var aim_to:=Vector2.ZERO
var aim_progress:=0.0
const AIM_TRAVEL_SECONDS:=1.3
const AIM_HOLD_SECONDS:=0.6
const AIM_COLOR:=Color(1,.75,.2)
## Change 41: the three mode choices as large cards: art, the mode's name and one line on what it gives
## (GUIDE_MODE_<MODE> and GUIDE_MODE_<MODE>_DETAIL). Every mode plays the same game; Guided, the
## beginner's mode, uses the primary style, and None is never styled as a recommendation.
const MODES:=["guided","basic","none"]
const MODE_ART:={"guided":273,"basic":60,"none":1}
const MODE_TITLE_COLORS:={"guided":Color(1,.93,.7),"basic":Color(.72,.88,1),"none":Color(.86,.88,.92)}
const MODE_MIN_HEIGHT:=112.0
## The chooser is shown at its settled size only (Playbook 16.3): transparent until its wanted size has
## held for two frames, never longer than CHOOSER_SETTLE_CAP frames.
const CHOOSER_SETTLE_CAP:=12
var chooser_detail: Label
var chooser_settled:=0
var chooser_frames:=0
var chooser_wanted:=Vector2.ZERO
## Change 41: during the Guided movement lesson, the real joystick is framed and a ghost knob shows the
## drag toward the path (stick_demo), wherever Settings placed the stick; drawn only, never input.
var stick_demo: Control
var stick_direction:=Vector2.LEFT
var stick_progress:=0.0
const STICK_TRAVEL_SECONDS:=0.9
const STICK_HOLD_SECONDS:=0.5

func setup(owner_ui) -> void:
    ui=owner_ui;sim=ui.sim
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    theme=ui.theme
    # The first-launch chooser is the only modal: it is a decision, shown before the first tick.
    blocker=Control.new();blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);blocker.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(blocker)
    chooser=PanelContainer.new();add_child(chooser)
    var list:=VBoxContainer.new();list.add_theme_constant_override("separation",14);chooser.add_child(list)
    chooser_heading=Label.new();chooser_heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;chooser_heading.add_theme_font_size_override("font_size",26);chooser_heading.add_theme_color_override("font_color",Color(1,.88,.5));list.add_child(chooser_heading)
    chooser_detail=Label.new();chooser_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;chooser_detail.add_theme_font_size_override("font_size",18);chooser_detail.add_theme_color_override("font_color",Color(.8,.84,.9));list.add_child(chooser_detail)
    for mode in MODES:list.add_child(_mode_button(mode))
    aim=Control.new();aim.mouse_filter=Control.MOUSE_FILTER_IGNORE;aim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(aim);aim.hide()
    aim.draw.connect(_draw_aim)
    stick_demo=Control.new();stick_demo.mouse_filter=Control.MOUSE_FILTER_IGNORE;stick_demo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(stick_demo);stick_demo.hide()
    stick_demo.draw.connect(_draw_stick_demo)
    final_backdrop=ColorRect.new();final_backdrop.color=Color(0,0,0,0.72);final_backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;final_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(final_backdrop);final_backdrop.hide()
    card=PanelContainer.new();card.theme_type_variation=&"Backing";card.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(card)
    var content:=VBoxContainer.new();content.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_theme_constant_override("separation",4);card.add_child(content)
    var row:=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_theme_constant_override("separation",12);content.add_child(row)
    picture=TextureRect.new();picture.custom_minimum_size=Vector2(44,44);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(picture)
    title=Label.new();title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_theme_font_size_override("font_size",24);title.add_theme_color_override("font_color",Color(1,.88,.5));title.add_theme_constant_override("outline_size",4);title.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(title)
    support=Label.new();support.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;support.add_theme_font_size_override("font_size",20);support.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(support)
    var buttons:=HBoxContainer.new();buttons.alignment=BoxContainer.ALIGNMENT_END;buttons.add_theme_constant_override("separation",12);buttons.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(buttons)
    skip_button=Button.new();skip_button.custom_minimum_size=Vector2(180,64);buttons.add_child(skip_button)
    skip_button.pressed.connect(skip_overview)
    intro_button=Button.new();intro_button.custom_minimum_size=Vector2(180,64);buttons.add_child(intro_button)
    intro_button.pressed.connect(func()->void:
        if intro_id.begins_with("flow:"):
            sim.campaign.guided.acknowledge(intro_id.trim_prefix("flow:"));return
        if intro_id==ROAD_AHEAD_ID:
            if float(sim.state.tutorial.get("road_ahead_seconds",0.0))<float(sim.campaign.guided.rules().final_delay):return
            if not sim.state.tutorial.seen.has(ROAD_AHEAD_ID):
                sim.state.tutorial.seen.append(ROAD_AHEAD_ID);sim.touch();SaveService.mark_dirty()
            return
        if intro_id=="focus":sim.campaign.focus_hint=-1;return
        if intro_id!="" and not sim.state.tutorial.seen.has(intro_id):sim.state.tutorial.seen.append(intro_id);sim.touch())
    shade=_frame(Color(0,0,0,.85));highlight=_frame(Color(1,.85,.4))
    pointer=TextureRect.new();pointer.texture=ui.cropped(ARROW);pointer.custom_minimum_size=Vector2.ONE*POINTER_SIZE;pointer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;pointer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    pointer.size=Vector2.ONE*POINTER_SIZE;pointer.pivot_offset=pointer.size*.5;pointer.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(pointer)
    sim.suspended=sim.state.tutorial.mode=="pending"
    _localize()

## Fixed texts built in code; the card's title and detail are re-read every frame (_present).
## Localization Batch 01: redrawn when the language changes.
func _localize() -> void:
    chooser_heading.text=tr("GUIDE_CHOOSE")
    chooser_detail.text=tr("GUIDE_CHOOSE_DETAIL")
    for button in chooser_heading.get_parent().get_children():
        if button is Button:
            var key:="GUIDE_MODE_"+str(button.get_meta("mode")).to_upper()
            button.get_node("Row/Text/Title").text=tr(key)
            button.get_node("Row/Text/Detail").text=tr(key+"_DETAIL")
    chooser_settled=0;chooser_frames=0
    skip_button.text=tr("GUIDE_SKIP")
    intro_button.text=tr("GUIDE_GOT_IT")

func _notification(what: int) -> void:
    if what==NOTIFICATION_TRANSLATION_CHANGED and chooser_heading!=null:_localize()

## One mode card: a full-size button holding its art, name and one line of detail. The content ignores
## input, so the whole card is the touch target; its height follows the wrapped detail (_fit_chooser).
func _mode_button(mode: String) -> Button:
    var button:=Button.new();button.set_meta("mode",mode);button.name="Mode_"+mode
    button.custom_minimum_size.y=MODE_MIN_HEIGHT;button.focus_mode=Control.FOCUS_NONE
    if mode=="guided":button.theme_type_variation=&"Primary"
    button.pressed.connect(func()->void:choose(mode))
    var row:=HBoxContainer.new();row.name="Row";row.mouse_filter=Control.MOUSE_FILTER_IGNORE
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);row.offset_left=16;row.offset_right=-16;row.offset_top=10;row.offset_bottom=-10
    row.add_theme_constant_override("separation",16);button.add_child(row)
    var art:=TextureRect.new();art.texture=ui._art(int(MODE_ART[mode]));art.custom_minimum_size=Vector2(56,56);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;art.size_flags_vertical=Control.SIZE_SHRINK_CENTER;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(art)
    var text:=VBoxContainer.new();text.name="Text";text.mouse_filter=Control.MOUSE_FILTER_IGNORE;text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.alignment=BoxContainer.ALIGNMENT_CENTER;text.add_theme_constant_override("separation",2);row.add_child(text)
    var heading:=Label.new();heading.name="Title";heading.mouse_filter=Control.MOUSE_FILTER_IGNORE;heading.add_theme_font_size_override("font_size",28)
    heading.add_theme_color_override("font_color",MODE_TITLE_COLORS[mode]);heading.add_theme_color_override("font_outline_color",Color(0,0,0,.85));heading.add_theme_constant_override("outline_size",4);text.add_child(heading)
    var detail:=Label.new();detail.name="Detail";detail.mouse_filter=Control.MOUSE_FILTER_IGNORE;detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_theme_font_size_override("font_size",19)
    detail.add_theme_color_override("font_color",Color(1,.97,.9) if mode=="guided" else Color(.86,.9,.95));detail.add_theme_color_override("font_outline_color",Color(0,0,0,.7));detail.add_theme_constant_override("outline_size",3);text.add_child(detail)
    return button

## Sizes the chooser for the safe area and its mode cards for their wrapped text, then reveals it only
## once that size has held (a wrapped label measures one word per line on its first pass).
func _fit_chooser() -> void:
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var width:=minf(640,ui.size.x-insets.x-insets.z-32)
    var inner:=width-chooser.get_theme_stylebox("panel").get_minimum_size().x
    if chooser_heading.custom_minimum_size.x!=inner:chooser_heading.custom_minimum_size.x=inner;chooser_detail.custom_minimum_size.x=inner
    for button in chooser_heading.get_parent().get_children():
        if not button is Button:continue
        var row: Control=button.get_node("Row")
        var detail: Label=row.get_node("Text/Detail")
        var room:=inner-32-56-16
        if detail.custom_minimum_size.x!=room:detail.custom_minimum_size.x=room
        var height:=maxf(MODE_MIN_HEIGHT,row.get_combined_minimum_size().y+20)
        if button.custom_minimum_size.y!=height:button.custom_minimum_size.y=height
    var wanted:=Vector2(width,chooser.get_combined_minimum_size().y)
    if not chooser.size.is_equal_approx(wanted):chooser.size=wanted
    var at:=Vector2(ui.centered_x(chooser.size.x,insets),(ui.size.y-chooser.size.y)*.5)
    if not chooser.position.is_equal_approx(at):chooser.position=at
    chooser_frames+=1
    chooser_settled=chooser_settled+1 if wanted.is_equal_approx(chooser_wanted) else 0
    chooser_wanted=wanted
    var shown:=chooser_settled>=2 or chooser_frames>=CHOOSER_SETTLE_CAP
    if chooser.modulate.a!=(1.0 if shown else 0.0):chooser.modulate.a=1.0 if shown else 0.0

func _frame(color: Color) -> NinePatchRect:
    var f:=NinePatchRect.new();f.texture=FRAME
    f.patch_margin_left=8;f.patch_margin_right=8;f.patch_margin_top=8;f.patch_margin_bottom=8
    f.draw_center=false;f.mouse_filter=Control.MOUSE_FILTER_IGNORE;f.modulate=color;add_child(f)
    return f

func choose(mode: String) -> void:
    sim.campaign.onboarding.choose_mode(mode);sim.suspended=false;SaveService.save_now()

## Basic: Skip retires the rest of the overview at once; The Road Ahead follows.
func skip_overview() -> void:
    var seen: Array=sim.state.tutorial.seen
    for id in BASIC_DECK:
        if not seen.has(id):seen.append(id)
    sim.touch();SaveService.mark_committed()

func _process(dt: float) -> void:
    if sim==null:return
    pulse+=dt
    var data: Dictionary=sim.state.tutorial
    chooser.visible=data.mode=="pending"
    blocker.visible=chooser.visible
    if chooser.visible:
        sim.suspended=true
        # Change 10: centred on the X axis of the safe area. Change 41: the cards wrap to the width.
        _fit_chooser()
        _hide_all();return
    chooser_settled=0;chooser_frames=0
    var running: bool=not get_tree().paused and not sim.suspended and not sim.held and sim.state.prestige_batch.is_empty()
    if running:
        sim.campaign.guided.advance_waits(dt)
    _complete_lessons()
    evaluate()
    _present()
    # Change 35: the targeting lesson's escape counts only active time with no enemy to target.
    if running and step=="target_find":sim.campaign.guided.target_unavailable(dt)
    if card.visible and not get_tree().paused:
        if intro_id=="flow:tutorial_final":sim.campaign.guided.shown(dt)
        elif intro_id==ROAD_AHEAD_ID:
            var delay: float=float(sim.campaign.guided.rules().final_delay)
            var elapsed: float=float(data.get("road_ahead_seconds",0.0))
            if elapsed<delay:
                data["road_ahead_seconds"]=minf(delay,elapsed+dt)
                SaveService.mark_dirty()
    if pending=="focus" and (card.visible or pointer.visible):focus_shown+=dt
    if card.visible and pending in LONG_STEPS:long_shown[pending]=float(long_shown.get(pending,0.0))+dt
    # Basic overview cards retire on their own after a readable time on screen.
    if data.mode=="basic" and BASIC_DECK.has(intro_id) and card.visible:
        if card_for!=intro_id:card_for=intro_id;card_shown=0
        card_shown+=dt
        if card_shown>=sim.campaign.onboarding.rules.card_seconds and not data.seen.has(intro_id):
            data.seen.append(intro_id);card_shown=0;sim.touch()

## A lesson completes when its learned state exists, however and whenever the player reached it.
func _complete_lessons() -> void:
    var data: Dictionary=sim.state.tutorial
    var claimed: bool=not sim.state.main_claimed.is_empty() or sim.campaign.counter("mission")>0
    var complete: Array=[_path_followed() or sim.campaign.counter("kill")>0,
        sim.campaign.counter("kill")>0,not sim.state.items.is_empty(),sim.state.weapon!="" or sim.state.outfit!="",
        sim.state.items.values().any(func(r):return r.merge>0),
        claimed or (data.seen.has("opened:missions") and not sim.campaign.has_claimable()),
        not sim.state.upgrades.is_empty(),sim.campaign.counter("camp")>0,
        sim.campaign.onboarding.player_purchase(),
        data.seen.has("snowman") or sim.campaign.prestige_unlocked(),
        str(sim.state.follow)!="" or data.seen.has("prestige_intro")]
    for i in range(LESSONS.size()):
        if complete[i] and not data.done.has(LESSONS[i]):data.done.append(LESSONS[i]);sim.touch()

## Change 16: the opening lesson is done once the player has walked the path to the left (within
## OnboardingRules.path_reach of path_target on Winter I). Elsewhere, leaving the arrival camp counts
## as before. A first defeat also completes it (see _complete_lessons), so walking another way first
## never strands the tutorial.
func _path_followed() -> bool:
    var rules: OnboardingRules=sim.campaign.onboarding.rules
    var at: Vector2=sim.position_of(sim.state.player)
    if int(sim.state.stage)==1:return at.distance_to(rules.path_target)<=rules.path_reach
    var arrival: Array=sim.campaign.stage().spawns[0]
    return at.distance_to(Vector2(arrival[0],arrival[1]))>48

func evaluate() -> void:
    pending="";step="";surfaces=[""];target=null;world_target=Vector2.INF;intro_id="";path_point=Vector2.INF;screen_target=Rect2()
    var data: Dictionary=sim.state.tutorial
    # Change 24 (UI-05): None shows no guide at all; The Road Ahead is its only exception. Auto Claim
    # is explained by the Missions panel's own text there, without a pointer.
    if data.mode=="none":
        _road_ahead_if_ready(data)
        return
    if data.mode=="guided":
        if sim.campaign.guided.complete():
            if not _mission_auto_hint():_focus_hint()
        else:_guided_lesson()
        return
    # Basic: the overview deck, then The Road Ahead; nothing after that (no tips or pointers).
    if data.mode=="basic" and not _basic_card():_road_ahead_if_ready(data)

## This is the same one-time game-goals announcement in modes without the Guided final step.
## Basic finishes its overview deck first (or skips it); None receives goals immediately.
func _road_ahead_if_ready(data: Dictionary) -> bool:
    if data.seen.has(ROAD_AHEAD_ID):return false
    if data.mode=="none" or (data.mode=="basic" and BASIC_DECK.all(func(id):return data.seen.has(id))):
        pending=ROAD_AHEAD_ID;step="tutorial_final";intro_id=ROAD_AHEAD_ID
        return true
    return false

## Basic (Change 25): the next overview card not seen yet, whatever the player has done meanwhile.
func _basic_card() -> bool:
    var data: Dictionary=sim.state.tutorial
    if data.seen.has(ROAD_AHEAD_ID):return false
    for id in BASIC_DECK:
        if not data.seen.has(id):
            pending=id;intro_id=id;step=id
            return true
    return false

func _lesson(lesson: String) -> void:
    step=lesson
    match lesson:
        # Change 16: "Follow the path to your left." with the arrow pointing from the player along
        # the path toward the first enemies (Winter I); elsewhere the joystick as before.
        "move":
            if int(sim.state.stage)==1:path_point=sim.campaign.onboarding.rules.path_target
            else:target=ui.stick
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
            var id:=_first_item(func(i):return sim.can_merge(i))
            if id=="":step="merge_wait";world_target=_nearest_enemy();return
            var open: String=ui.selected if ui.sheet.visible and ui.panel=="item" else ""
            if open!="" and sim.can_merge(open):step="merge_tap";target=_panel_control("merge")
            else:step="merge";target=_slot(id)
        "upgrade":
            surfaces=["","enemy"]
            var g: int=ui.combat_group if sim.campaign.discovered(ui.combat_group) else sim.nearest_group()
            if not sim.campaign.discovered(g):step="upgrade_find";world_target=_nearest_enemy();return
            var price: int=sim.upgrade_cost("loot",g)
            if sim.state.coins<price:step="upgrade_earn";support_value=float(price)-float(sim.state.coins);return
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
            if sim.state.coins<price:step="camp_earn";support_value=float(price)-float(sim.state.coins);return
            if ui.sheet.visible and ui.panel in ["world","camp"]:
                step="camp_buy";target=_panel_control("camp_buy_%d" % camp)
            elif ui.view_camp==camp:
                # Change 16: standing at that camp, its View Camp button is the next tap.
                step="camp_view";target=ui.get_node("Safe/Layout/Map/ViewCamp")
            else:step="camp";target=ui.dock.get_node("Navigation/World")
        # Change 15 lessons, each on the system the reveal table has just opened.
        "missions":
            surfaces=["","missions"]
            if ui.sheet.visible and ui.panel=="missions":
                target=_panel_control("claim",true)
                step="missions_claim" if target!=null else "missions_wait"
            else:step="missions";target=ui.dock.get_node("Navigation/Missions")
        "slots":
            surfaces=["","upgrades"]
            # The first Player Upgrade: an equipment slot when the Gems allow it, else a Health Potion.
            var slot_ok: bool=sim.upgrade_block_reason("gear_slots")==""
            var potion_price: int=int(sim.supply("potion").get("price",0))
            var potion_ok: bool=potion_price>0 and sim.state.coins>=potion_price and sim.can_add("potion")
            if not slot_ok and not potion_ok:
                step="slots_earn";support_value=float(potion_price)-float(sim.state.coins);return
            if ui.sheet.visible and ui.panel=="upgrades":
                var tab:=1 if slot_ok else 2
                if ui.player_tab!=tab:
                    step="slots_tab" if slot_ok else "slots_supply_tab"
                    target=_panel_control("tab_tab_inventory" if slot_ok else "tab_tab_supplies")
                else:
                    step="slots_buy" if slot_ok else "slots_potion"
                    target=_panel_control("buy_gear_slots" if slot_ok else "buy_supply_potion",true)
            else:step="slots";target=ui.dock.get_node("Navigation/Upgrades")
        "snowman":
            # The main objective, once: why the Snowman matters, pointing at the Next Stage chip.
            intro_id="snowman";target=ui.get_node("Safe/Layout/Map/Gate")
        "prestige":
            surfaces=["","prestige"]
            if ui.sheet.visible and ui.panel=="prestige":
                intro_id="prestige_intro"
                target=_panel_control("follow",true)
                step="prestige_follow" if target!=null else "prestige_info"
            else:step="prestige_open";target=ui.dock.get_node("Navigation/Prestige")

## The current brief supersedes the historical reveal/lesson order for Guided only.
func _guided_lesson() -> void:
    var flow=sim.campaign.guided
    var current: String=flow.next_step()
    if current=="":return
    pending=current;step=current
    if current in ["mission_wait","upgrade_wait"]:
        pending="";return
    if current.begins_with("close_"):
        var expected: String={"close_equip":"item","close_merge":"item","close_missions":"missions","close_upgrade":"upgrades","close_inventory":"upgrades"}[current]
        if not ui.sheet.visible:
            flow.panel_closed(expected);pending="";return
        surfaces=[expected]
        step="close_panel"
        target=ui.get_node("Sheet/Margin/Content/Header/Close")
        return
    if current in ["move","kill","collect","equip","merge","missions"]:
        _lesson(current);return
    if current=="target":
        # Change 35: demonstrate the real gesture toward the nearest enemy that can be targeted; with
        # none in sight, ask the player to walk until one is (the escape timer runs only then).
        world_target=_nearest_enemy(true)
        if world_target==Vector2.INF:world_target=_nearest_enemy()
        if world_target==Vector2.INF:step="target_find";target=ui.stick
        return
    if current=="tutorial_final":
        intro_id="flow:"+current
        return
    if _guided_change61(current):return
    if current in ["player_upgrade","expand_inventory"]:
        surfaces=["","upgrades"]
        var upgrade: String="respawn" if current=="player_upgrade" else "gear_slots"
        var wanted_tab:=0 if current=="player_upgrade" else 1
        var reason: String=sim.upgrade_block_reason(upgrade)
        if reason in ["NOT_ENOUGH_COINS","NOT_ENOUGH_GEMS"]:
            step="upgrade_earn";support_value=maxf(0,sim.upgrade_cost(upgrade)-sim.state.coins);world_target=_nearest_enemy();return
        if ui.sheet.visible and ui.panel=="upgrades":
            if ui.player_tab!=wanted_tab:target=_panel_control("tab_"+ui.UPGRADE_TABS[wanted_tab].to_lower())
            else:target=_panel_control("buy_"+upgrade,true) if upgrade=="gear_slots" else _panel_control("buy_upgrade",true)
        else:target=ui.dock.get_node("Navigation/Upgrades")
        return
    if current=="camp":
        surfaces=["","camp","world"]
        var camp:=-1
        for i in range(1,sim.campaign.stage().spawns.size()):
            if not sim.state.spawns.has(i):camp=i;break
        if camp<0:flow.mark("camp");return
        var at: Array=sim.campaign.stage().spawns[camp]
        path_point=Vector2(at[0],at[1])
        if not sim.campaign.camp_known(camp):step="camp_approach";return
        var price: int=sim.campaign.camp_price(camp)
        if sim.state.coins<price:
            step="camp_earn";support_value=price-sim.state.coins;path_point=Vector2.INF
            if ui.sheet.visible:target=ui.get_node("Sheet/Margin/Content/Header/Close")
            else:world_target=_nearest_enemy()
            return
        if ui.sheet.visible and ui.panel in ["camp","world"]:
            step="camp_buy";target=_panel_control("camp_buy_%d" % camp);path_point=Vector2.INF
        elif ui.view_camp==camp:
            step="camp_view";target=ui.get_node("Safe/Layout/Map/ViewCamp");path_point=Vector2.INF
        else:step="camp_approach"
        return
    if current=="boss_find":
        var g: int=sim.campaign.prestige_unlock_group()
        path_point=sim.campaign.spot(g,2)
        return
    if current=="potion_buy":
        surfaces=["","upgrades","item"]
        if not sim.can_add("potion"):
            step="potion_capacity"
            if ui.sheet.visible and ui.panel=="upgrades":
                if ui.player_tab!=1:target=_panel_control("tab_tab_inventory")
                else:target=_panel_control("buy_supply_slots",true)
            else:target=ui.dock.get_node("Navigation/Upgrades")
            return
        if sim.state.coins<int(sim.supply("potion").price):
            step="camp_earn";support_value=int(sim.supply("potion").price)-sim.state.coins;world_target=_nearest_enemy();return
        if ui.sheet.visible and ui.panel=="upgrades":
            if ui.player_tab!=2:target=_panel_control("tab_tab_supplies")
            else:target=_panel_control("buy_supply_potion",true)
        else:target=ui.dock.get_node("Navigation/Upgrades")
        return
    if current=="potion_use":
        surfaces=["","item"]
        if sim.quantity("potion")<=0:
            step="potion_buy";target=ui.dock.get_node("Navigation/Upgrades");return
        if sim.state.player.hp>=sim.stats().hp:
            step="potion_wait_hurt";world_target=_nearest_enemy();return
        if ui.sheet.visible and ui.panel=="item" and ui.selected=="potion":target=_panel_control("use",true)
        else:
            var index: int=sim.state.supplies.find("potion")
            if index>=0:target=ui.dock.get_node("Inventory/SupplyColumn/SupplyScroll/Supplies").get_child(index)
        return
    if current=="winter_two":
        surfaces=["","world","travel_map"]
        if ui.sheet.visible and ui.panel=="world":
            step="winter_two_travel";target=_panel_control("travel_stage_2")
        elif ui.sheet.visible and ui.panel=="travel_map":step="winter_two_travel"
        else:target=ui.dock.get_node("Navigation/World")

## Change 61 lessons. Each names the live control of the next real tap (or the world / a map marker);
## the step itself finishes only through guided_progress (real action or real screen).
func _guided_change61(current: String) -> bool:
    var nav: Node=ui.dock.get_node("Navigation")
    var open: String=ui.panel if ui.sheet.visible else ""
    match current:
        "gear_bonus":
            # Stats opens from the level bar's Player Level & Growth (or from Settings).
            surfaces=["","level","settings","stats"]
            if open=="stats":step="gear_bonus_stats";target=_panel_row("stored_share")
            elif open in ["level","settings"]:step="gear_bonus_open";target=_panel_control("open_stats")
            else:target=ui.top.get_node("Meters/XP/Open")
        "offline_rewards":
            surfaces=["","upgrades"]
            if open=="upgrades":target=_panel_control("tab_tab_offline")
            else:target=nav.get_node("Upgrades")
        "respawn_select":
            surfaces=["","world","camp"]
            var camp:=_additional_camp()
            if open in ["world","camp"]:
                step="respawn_select_tap";target=_panel_control("camp_select_%d" % camp)
            elif camp>=0 and ui.view_camp==camp:target=ui.get_node("Safe/Layout/Map/ViewCamp")
            else:target=nav.get_node("World")
        "camp_travel":
            surfaces=["","world","camp","teleport"]
            var here: int=ui._camp_at_player()
            var goal:=-1
            for camp in sim.state.spawns:
                if int(camp)==here:continue
                if goal<0 or (int(goal)==int(sim.state.spawn) and int(camp)!=int(sim.state.spawn)):goal=int(camp)
            if goal<0:return true
            if sim.campaign.in_combat() or sim.state.player.hp<=0:
                step="camp_travel_wait";world_target=Vector2.INF
                return true
            if open=="world":step="camp_travel_tap";target=_panel_control("camp_travel_%d" % goal,true)
            elif open=="camp":step="camp_travel_tap";target=_panel_control("camp_teleport",true)
            elif open=="teleport":
                step="camp_travel_tap"
                target=_panel_control("teleport_go",true) if ui.teleport_target==[1,goal] else _panel_control("teleport_1_%d" % goal)
            else:target=nav.get_node("World")
        "map_details":
            surfaces=["","world"]
            var price: int=sim.upgrade_cost("map_detail",int(sim.state.stage))
            if sim.state.coins<price:
                step="map_details_earn";support_value=price-sim.state.coins
                if open=="":world_target=_nearest_enemy()
                return true
            if open=="world":target=_panel_control("buy_map_detail",true)
            else:step="boss_found";target=nav.get_node("World")
        "enemy_pins":
            surfaces=["","world"]
            if open=="world":
                step="enemy_pins_tap"
                var map: Control=_panel_row("",true)
                var points: Array=map.enemy_marker_points() if map!=null else []
                if points.is_empty():step="enemy_pins_explore";return true
                var best: Vector2=points[0]
                var player: Vector2=map.player_dot.position+map.player_dot.size*.5
                for point in points:
                    if point.distance_to(player)<best.distance_to(player):best=point
                target=map
                screen_target=Rect2(map.global_position+best-Vector2.ONE*14,Vector2.ONE*28)
            else:target=nav.get_node("World")
        "hunt_follow","hunt_claim":
            surfaces=["","missions"]
            if open=="missions":target=_panel_control("follow_hunt" if current=="hunt_follow" else "claim_hunt",true)
            else:target=nav.get_node("Missions")
        "hunt_farm":
            # Following again if the player unfollowed it keeps the 0/30 tracker on screen.
            if sim.campaign.followed_mission().get("kind","")!="hunt":
                step="hunt_follow";surfaces=["","missions"]
                if open=="missions":target=_panel_control("follow_hunt",true)
                else:target=nav.get_node("Missions")
            elif float(long_shown.get(current,0.0))>=LONG_CARD_SECONDS:pending=""
        "prestige_follow":
            surfaces=["","prestige"]
            step="boss_prestige_follow"
            if open=="prestige":
                target=_panel_control("follow_"+sim.campaign.guided.FIRST_BOSS_OPPORTUNITY,true)
                # Its stage section may be collapsed: the Winter I heading opens it.
                if target==null:target=_panel_control("prestige_stage_1")
            else:target=nav.get_node("Prestige")
        "boss_win":
            if float(long_shown.get(current,0.0))>=LONG_CARD_SECONDS:pending=""
        "world_open":
            surfaces=[""]
            target=nav.get_node("World")
        "prestige_optional":
            surfaces=["","prestige"]
            if open=="prestige":
                step="prestige_optional_panel"
                target=_panel_row("opportunity_"+sim.campaign.guided.FIRST_BOSS_OPPORTUNITY)
            else:target=nav.get_node("Prestige")
        _:return false
    return true

## The first owned camp of the current map other than its arrival camp (-1 when none).
func _additional_camp() -> int:
    var owned: Array=sim.state.spawns.duplicate()
    owned.sort()
    for camp in owned:
        if int(camp)!=0:return int(camp)
    return -1

## A non-button control of the open panel by its guide_row tag (Stats rows, opportunity cards); with
## map=true, the World panel's map view.
func _panel_row(key: String,map:=false) -> Control:
    for node in ui.rows.find_children("*","Control",true,false):
        if node.is_queued_for_deletion() or not node.is_visible_in_tree():continue
        if map and node.has_meta("guide_map"):return node
        if not map and str(node.get_meta("guide_row",""))==key:return node
    return null

var support_value:=0.0
## Change 61: a screen-space pointer target (a World map marker) when the target is not a control.
var screen_target:=Rect2()
## Long farming lessons (hunt_farm, boss_win) keep their card on screen this many seconds per session,
## then let the player play with the tracker alone (the step stays pending and its gate unchanged).
const LONG_CARD_SECONDS:=20.0
const LONG_STEPS:=["hunt_farm","boss_win"]
var long_shown: Dictionary={}

## Change 14: right after the first Focused Farming purchase (campaign.focus_hint), point at the next
## real tap toward that type's Farm button: the button itself in its enemy panel (both tabs show it),
## else the HUD Upgrades button when it opens that type, else the minimap (map, then the enemy). It
## ends when Focus is turned on, on "Got it", after FOCUS_HINT_SECONDS on screen, or when it no longer
## applies (another map, the upgrade gone). Another enemy's panel suspends it like any other panel.
## A newly bought automation is OFF until explicitly enabled. Use the same live-control
## highlight/arrow as Focused Farming, never an unsolicited modal or auto-enable on purchase.
func _mission_auto_hint() -> bool:
    if sim.level("mission_claim")<=0 or sim.state.mission_auto or sim.state.tutorial.seen.has("mission_auto_enabled"):
        return false
    pending="mission_auto_hint";step="mission_auto_open";surfaces=["","missions"]
    if ui.sheet.visible and ui.panel=="missions":
        step="mission_auto_hint";target=_panel_control("mission_auto_toggle")
    elif not ui.sheet.visible:
        target=ui.dock.get_node("Navigation/Missions")
    return true

func _focus_hint() -> bool:
    var g: int=sim.campaign.focus_hint
    if g<0:
        focus_shown=0;return false
    if int(sim.state.focus)>=0 or g>=sim.catalog.groups.size() or sim.level("focus",g)==0 or not sim.campaign.stage().groups.has(g) or focus_shown>=FOCUS_HINT_SECONDS:
        sim.campaign.focus_hint=-1;focus_shown=0;return false
    pending="focus";intro_id="focus";surfaces=["","enemy"]
    if ui.sheet.visible and ui.panel=="enemy":
        if ui.group!=g:
            surfaces=[""];step="focus_open";return true
        target=_panel_control("focus_toggle",true)
        step="focus_tap" if target!=null else "focus_spot"
        return true
    var hud: Control=ui.get_node("Safe/Layout/Map/EnemyUpgrades")
    if hud.visible and ui.combat_group==g:
        step="focus_open";target=hud
    else:
        step="focus_find";target=ui.get_node("Safe/Layout/Map/MiniMap")
    return true

## on_map (Change 35, the targeting demo): only enemies drawn inside the visible map.
func _nearest_enemy(on_map:=false) -> Vector2:
    var best:=Vector2.INF
    var view=sim.campaign.sight()
    var map: Control=ui.get_node("Safe/Layout/Map")
    var scale: Vector2=map.size/Vector2(ui.world.get_viewport_rect().size)
    for e in sim.state.enemies:
        if e.hp<=0 or not view.sees(sim.position_of(e)) or sim.catalog.groups[int(e.group)].boss:continue
        if on_map and not map.get_global_rect().grow(-32).has_point(map.global_position+(ui.world.get_canvas_transform()*sim.position_of(e))*scale):continue
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
            if (node.get_meta("guide","")==key or node.get_meta("guide_alt","")==key) and node.is_visible_in_tree() and not node.is_queued_for_deletion() and (not enabled_only or not node.disabled):return node
    return null

func _hide_all() -> void:
    card.hide();final_backdrop.hide();highlight.hide();shade.hide();pointer.hide();aim.hide();stick_demo.hide()

func _present() -> void:
    var data: Dictionary=sim.state.tutorial
    suspended_by=""
    if get_tree().paused:suspended_by="pause"
    elif ui.modal_open():suspended_by="confirmation"
    elif not sim.state.prestige_batch.is_empty():suspended_by="prestige"
    elif not ui.banner.current.is_empty():suspended_by="milestone"
    elif ui.sheet.visible and not surfaces.has(ui.panel):suspended_by=ui.panel
    elif not ui.sheet.visible and not surfaces.has(""):suspended_by="closed"
    if pending=="" or suspended_by!="" or (ui.sheet.visible and ui.sheet.modulate.a<1.0):
        _hide_all();return
    title.text=tr("GUIDE_"+step.to_upper())
    var deck_index:=BASIC_DECK.find(intro_id) if data.mode=="basic" else -1
    if deck_index>=0:title.text+="  %d/%d" % [deck_index+1,BASIC_DECK.size()]
    var skippable:=deck_index>=0 and deck_index<BASIC_DECK.size()-1
    if skip_button.visible!=skippable:skip_button.visible=skippable
    support.text=tr("GUIDE_"+step.to_upper()+"_DETAIL")
    # Coins still needed, in the shared currency format rounded up (Change 13).
    if "%s" in support.text:support.text=support.text % NumberFormat.currency(support_value,true)
    picture.texture=_picture()
    var is_final:=intro_id in ["flow:tutorial_final",ROAD_AHEAD_ID]
    var final_ready:=true
    if intro_id=="flow:tutorial_final":
        final_ready=float(sim.campaign.guided.data().final_seconds)>=float(sim.campaign.guided.rules().final_delay)
    elif intro_id==ROAD_AHEAD_ID:
        final_ready=float(data.get("road_ahead_seconds",0.0))>=float(sim.campaign.guided.rules().final_delay)
    intro_button.visible=intro_id!="" and final_ready
    final_backdrop.visible=is_final
    title.add_theme_font_size_override("font_size",32 if is_final else 24)
    support.add_theme_font_size_override("font_size",23 if is_final else 20)
    intro_button.size_flags_horizontal=Control.SIZE_SHRINK_CENTER if is_final else Control.SIZE_SHRINK_END
    card.mouse_filter=Control.MOUSE_FILTER_IGNORE
    _place_card()
    # Introductions are text only, except in Guided: the Focused Farming and Auto Claim hints and
    # the Snowman objective and Prestige cards point at their control. Basic and None never point.
    if data.mode!="guided" or (pending not in ["focus","mission_auto_hint","mission_auto_open"] and intro_id!="" and not step in POINTING_INTROS):
        highlight.hide();shade.hide();pointer.hide();aim.hide();stick_demo.hide();return
    _point()

func _picture() -> Texture2D:
    if step in ["snowman","feature_objective","boss_found","boss_win","world_open","boss_prestige_follow"]:return ui.icon_cache.get("boss-snowman_outfit")
    if step.begins_with("gear_bonus"):return ui._art(211)
    if step.begins_with("offline"):return ui._art(147)
    if step.begins_with("respawn") or step.begins_with("camp_travel") or step.begins_with("winter_two"):return ui._art(249)
    if step.begins_with("map_details") or step.begins_with("enemy_pins") or step.begins_with("hunt"):return ui._art(1)
    if BASIC_DECK.has(step):return ui._art(int(ui.HELP_ART.get(step,60)))
    if step.begins_with("focus") or step.begins_with("slots") or step=="feature_upgrades":return ui._art(147)
    if step in ["skills","rest"]:return ui._art(212)
    if step.begins_with("camp") or step=="feature_world":return ui._art(249)
    if step.begins_with("prestige") or step.begins_with("missions") or step in ["feature_prestige","feature_missions"]:return ui._art(211)
    if step in ["kill","aggression","groups","collect_wait","merge_wait","upgrade_find","equip_find","equip_collect","feature_enemy","target","target_find"]:return ui._art(1)
    return ui._art(60)

## The caption never covers the open panel: above it when there is room, otherwise hidden
## (the pointer alone continues the lesson). Without a panel it sits above the joystick.
func _place_card() -> void:
    var map: Control=ui.get_node("Safe/Layout/Map")
    var is_final:=intro_id in ["flow:tutorial_final",ROAD_AHEAD_ID]
    var width:=minf(680 if is_final else 600,map.size.x-32)
    # Resize only on change: assigning a size every frame forces a relayout every frame.
    var height:=card.get_combined_minimum_size().y
    if not card.size.is_equal_approx(Vector2(width,height)):card.size=Vector2(width,height)
    if is_final:
        card.position=Vector2(map.global_position.x+(map.size.x-width)*.5,map.global_position.y+(map.size.y-height)*.5)
        card.show()
        return
    var y:=map.global_position.y+map.size.y-206-height
    if ui.sheet.visible:
        y=ui.sheet.position.y-12-height
        if y<map.global_position.y+8:card.hide();return
    card.position=Vector2(map.global_position.x+(map.size.x-width)*.5,maxf(map.global_position.y+8,y))
    card.show()

## Change 16: the opening direction arrow. The owned pointer art sits beside the player, turned toward
## the path's point and bobbing along that direction; it never covers the player or leaves the map.
const PATH_ARROW_DISTANCE:=88.0
func _point_path() -> void:
    highlight.hide();shade.hide()
    var map: Control=ui.get_node("Safe/Layout/Map")
    var scale: Vector2=map.size/Vector2(ui.world.get_viewport_rect().size)
    var from: Vector2=map.global_position+(ui.world.get_canvas_transform()*(sim.position_of(sim.state.player)+Vector2(0,-10)))*scale
    var to: Vector2=map.global_position+(ui.world.get_canvas_transform()*path_point)*scale
    if from.distance_to(to)<4:
        pointer.hide();return
    var direction:=(to-from).normalized()
    stick_direction=direction
    var bob:=6.0*sin(pulse*5)
    pointer.rotation=direction.angle()-ARROW_BASE_ANGLE
    var center:=from+direction*(PATH_ARROW_DISTANCE+bob)
    pointer.position=(center-pointer.size*.5).clamp(map.global_position+Vector2(4,4),map.global_position+map.size-pointer.size-Vector2(4,4))
    pointer.show()

func _point() -> void:
    if step!="move":stick_demo.hide()
    if step=="target":
        _point_aim()
        return
    aim.hide()
    if path_point!=Vector2.INF:
        _point_path()
        if step=="move":_point_stick()
        return
    var rect:=Rect2()
    var have:=false
    if is_instance_valid(target) and target.is_visible_in_tree() and not target.is_queued_for_deletion():
        var key:=step+":"+str(target.get_instance_id())
        var scroll: ScrollContainer=ui.get_node("Sheet/Margin/Content/Scroll")
        if scrolled_for!=key and scroll.is_ancestor_of(target):
            scroll.ensure_control_visible(target)
            scrolled_for=key;scroll_retries=SCROLL_RETRY_FRAMES
        rect=target.get_global_rect() if screen_target.size==Vector2.ZERO else screen_target
        # Inside the scroll list only the visible part counts; never point at off-screen controls.
        if scroll.is_ancestor_of(target):
            var visible_rect:=scroll.get_global_rect()
            have=visible_rect.encloses(rect.grow(-4))
            # Change 61: a list still settling (rows growing after the first layout) can leave the target
            # cut off; scrolling is retried for a few frames, never after that (the player may scroll away).
            if not have and scroll_retries>0:
                scroll_retries-=1;scroll.ensure_control_visible(target)
        else:have=ui.get_global_rect().encloses(rect)
    elif world_target!=Vector2.INF:
        var map: Control=ui.get_node("Safe/Layout/Map")
        var screen: Vector2=ui.world.get_canvas_transform()*world_target
        screen=map.global_position+screen*map.size/Vector2(ui.world.get_viewport_rect().size)
        rect=Rect2(screen-Vector2(16,40),Vector2(32,44))
        have=map.get_global_rect().grow(-24).has_point(screen) and not (ui.sheet.visible and ui.sheet.get_global_rect().has_point(screen))
    if not have:
        highlight.hide();shade.hide();pointer.hide();stick_demo.hide();return
    if step=="move" and target==ui.stick:stick_direction=Vector2.UP;_show_stick_demo(rect)
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

## Change 41: the Guided movement lesson on Winter I also frames the real joystick (wherever Settings put
## it) and plays the drag on it toward the path arrow's direction. The frame and the ghost knob follow the
## stick's live rectangle every frame and step aside while the player's thumb is on it.
func _point_stick() -> void:
    var stick: Control=ui.stick
    if not stick.is_visible_in_tree() or stick.pointer!=-2:
        highlight.hide();shade.hide();stick_demo.hide();return
    var rect: Rect2=stick.get_global_rect()
    var glow:=.75+.25*sin(pulse*4)
    highlight.position=rect.position-Vector2.ONE*4;highlight.size=rect.size+Vector2.ONE*8
    shade.position=rect.position-Vector2.ONE*7;shade.size=rect.size+Vector2.ONE*14
    highlight.modulate=Color(1,.85,.4,glow);highlight.show();shade.show()
    _show_stick_demo(rect)

func _show_stick_demo(rect: Rect2) -> void:
    if ui.stick.pointer!=-2:stick_demo.hide();return
    var cycle: float=fmod(pulse,STICK_TRAVEL_SECONDS+STICK_HOLD_SECONDS)
    stick_progress=minf(1.0,cycle/STICK_TRAVEL_SECONDS)
    stick_rect=rect
    stick_demo.show();stick_demo.queue_redraw()

## The ghost knob: from the stick's centre toward the lesson's direction, in the aim colours.
var stick_rect:=Rect2()
func _draw_stick_demo() -> void:
    if stick_rect.size==Vector2.ZERO:return
    var center:=stick_rect.get_center()
    var reach: float=float(ui.stick.radius)
    var eased:=stick_progress*stick_progress*(3.0-2.0*stick_progress)
    var knob:=center+stick_direction*reach*eased
    var d:=0.0
    while d<reach:
        stick_demo.draw_line(center+stick_direction*d,center+stick_direction*minf(reach,d+10),Color(0,0,0,.6),6,true)
        stick_demo.draw_line(center+stick_direction*d,center+stick_direction*minf(reach,d+10),Color(AIM_COLOR,.9),3,true)
        d+=18
    var glow:=.6+.4*sin(pulse*6)
    stick_demo.draw_circle(knob,30,Color(AIM_COLOR,.3+.15*glow))
    stick_demo.draw_arc(knob,30,0,TAU,40,Color(0,0,0,.75),7,true)
    stick_demo.draw_arc(knob,30,0,TAU,40,Color(AIM_COLOR,.75+.25*glow),4,true)
    stick_demo.draw_circle(center,6,Color(1,1,1,.9))

## Change 35: the targeting demonstration, from the player's screen position to the suggested enemy
## (world_target), in map coordinates like _point_path. Hidden while the player is already aiming
## (the real aim line takes over) and when either end leaves the visible map.
func _point_aim() -> void:
    highlight.hide();shade.hide()
    var map: Control=ui.get_node("Safe/Layout/Map")
    var scale: Vector2=map.size/Vector2(ui.world.get_viewport_rect().size)
    aim_from=map.global_position+ui.world.player_screen_position()*scale
    aim_to=map.global_position+(ui.world.get_canvas_transform()*(world_target+Vector2(0,-10)))*scale
    var inside: Rect2=map.get_global_rect().grow(-16)
    var gesture=ui.get_node("Safe/Layout/Map/GestureSurface")
    if not inside.has_point(aim_from) or not inside.has_point(aim_to) or aim_from.distance_to(aim_to)<24 or (gesture.aiming and gesture.dragging):
        pointer.hide();aim.hide();return
    var cycle: float=fmod(pulse,AIM_TRAVEL_SECONDS+AIM_HOLD_SECONDS)
    aim_progress=minf(1.0,cycle/AIM_TRAVEL_SECONDS)
    var eased:=aim_progress*aim_progress*(3.0-2.0*aim_progress)
    var finger:=aim_from.lerp(aim_to,eased)
    # The arrow's tip sits on the moving touch point, pointing the way the finger travels.
    var direction:=(aim_to-aim_from).normalized()
    pointer.rotation=direction.angle()-ARROW_BASE_ANGLE
    pointer.position=finger-direction*POINTER_SIZE*.45-pointer.size*.5
    pointer.show();aim.show();aim.queue_redraw()

func _draw_aim() -> void:
    var finger:=aim_from.lerp(aim_to,aim_progress*aim_progress*(3.0-2.0*aim_progress))
    var length:=aim_from.distance_to(aim_to)
    var direction:=(aim_to-aim_from)/maxf(1.0,length)
    # Dashed guide for the whole path, the travelled part drawn like the real aim line.
    var d:=0.0
    while d<length:
        aim.draw_line(aim_from+direction*d,aim_from+direction*minf(length,d+12),Color(AIM_COLOR,.45),3,true)
        d+=22
    aim.draw_line(aim_from,finger,Color(0,0,0,.6),6,true)
    aim.draw_line(aim_from,finger,AIM_COLOR,3,true)
    var glow:=.6+.4*sin(pulse*6)
    aim.draw_arc(aim_from,22,0,TAU,40,Color(1,1,1,.9),3,true)
    aim.draw_arc(aim_to,20+4*glow,0,TAU,40,Color(AIM_COLOR,.55+.45*glow),3,true)
    if aim_progress>=1.0:aim.draw_circle(aim_to,8,Color(AIM_COLOR,.8))
