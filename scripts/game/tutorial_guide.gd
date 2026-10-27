extends Control
## One guide owns all guidance presentation (playbook 18.8).
## - Logical progress: tutorial.done / tutorial.seen in the profile (kept by prestige, cleared by Hard Reset).
## - Pending step: derived from game state every frame, with the surface it belongs to; never saved.
## - Presentation: caption card, owned arrow pointer and frame, recomputed from the live control each
##   frame. Nothing here takes input except the "Got it" button of an introduction card.
## An unrelated panel, a confirmation, pause or a prestige choice suspends (hides) all guidance; the
## step stays pending and returns when that surface closes.
## Change 15: what exists is the first-profile reveal table (campaign.onboarding), the same in every
## mode; the mode decides how much is explained. Guided teaches each revealed system with the pointer,
## one lesson at a time, ending with Prestige after the Snowman. Basic shows one short card (or tip)
## when something new appears, retired by Got it or after OnboardingRules.card_seconds on screen.
## None shows no guide at all (badges, objectives and milestone banners are game feedback, not guide).
const FRAME=preload("res://assets/KenneyFantasyUI/PNG/Default/Transparent center/panel-transparent-center-000.png")
const ARROW=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-273.png")
const ITEM_ROOT="res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-%d.png"
const LESSONS=["move","kill","collect","equip","merge","missions","upgrade","camp","slots","snowman","prestige"]
## A lesson waits (and shows nothing) until the feature it teaches is revealed.
const LESSON_FEATURE:={"missions":"missions","upgrade":"enemy","camp":"world","slots":"upgrades","snowman":"objective","prestige":"prestige"}
## Guided introduction cards that also point (the Next Stage chip, the Follow button).
const POINTING_INTROS:=["snowman","prestige_follow","prestige_info"]
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
## Change 16: the opening lesson's direction arrow, from the player toward this world point (INF: none).
var path_point:=Vector2.INF
var scrolled_for: String=""
var pulse: float=0
## Change 14: seconds the Focused Farming pointer has been on screen; it retires after FOCUS_HINT_SECONDS.
const FOCUS_HINT_SECONDS:=45.0
var focus_shown: float=0
## Change 15: seconds the current Basic card has been on screen, and which card that is.
var card_shown: float=0
var card_for:=""

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
        if intro_id.begins_with("flow:"):
            sim.campaign.guided.acknowledge(intro_id.trim_prefix("flow:"));return
        if intro_id=="focus":sim.campaign.focus_hint=-1;return
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
    if card.visible and intro_id=="flow:tutorial_final" and not get_tree().paused:sim.campaign.guided.shown(dt)
    if pending=="focus" and (card.visible or pointer.visible):focus_shown+=dt
    # Basic cards retire on their own after a readable time on screen (no permanent instructions).
    if data.mode=="basic" and intro_id!="" and pending!="focus" and card.visible:
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
    pending="";step="";surfaces=[""];target=null;world_target=Vector2.INF;intro_id="";path_point=Vector2.INF
    var data: Dictionary=sim.state.tutorial
    if data.mode=="none":return
    if data.mode=="guided":
        if sim.campaign.guided.complete():
            _focus_hint()
        else:_guided_lesson()
        return
    if _focus_hint():return
    if data.mode=="guided":
        for lesson in LESSONS:
            if not data.done.has(lesson):pending=lesson;break
        # A lesson whose system is not revealed yet waits; the contextual cards below may show meanwhile.
        if pending!="" and (not LESSON_FEATURE.has(pending) or sim.campaign.onboarding.revealed(LESSON_FEATURE[pending])):
            _lesson(pending);return
        pending=""
    elif _basic_card():return
    # Contextual introductions in every mode except None: shown once, on the HUD only. (Change 15:
    # Prestige is introduced by its reveal, after the Snowman, not by the first opportunity found.)
    for pair in [["camp_done",sim.campaign.counter("camp")>0 and data.mode=="guided"],["aggression",sim.state.stage>=2],["skills",sim.campaign.skill_count()>0],["groups",sim.state.stage>=3],["rest",sim.state.player.hp>0 and sim.state.player.hp<sim.stats().hp*.4 and not sim.campaign.in_combat()]]:
        if pair[1] and not data.seen.has(pair[0]):pending=pair[0];intro_id=pair[0];step=pair[0];return

## Basic (Change 15): a concrete opening card, two short tips for the first equip and merge while they
## apply, then one card per system as it is revealed, in reveal order. Text only, never a pointer.
func _basic_card() -> bool:
    var data: Dictionary=sim.state.tutorial
    var order: Array=[["overview",true],
        ["tip_equip",not data.done.has("equip") and _first_item(func(i):return sim.catalog.items[i].kind in ["weapon","outfit"])!=""],
        ["tip_merge",not data.done.has("merge") and _first_item(func(i):return sim.can_merge(i) and sim.catalog.items[i].kind in ["weapon","outfit"])!=""]]
    for feature in sim.campaign.onboarding.FEATURES:order.append(["feature_"+feature,sim.campaign.onboarding.revealed(feature)])
    for pair in order:
        if pair[1] and not data.seen.has(pair[0]):
            pending=pair[0];intro_id=pair[0];step=pair[0]
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
    if current in ["boss_preparation","prestige_intro","world_intro","travel_intro","milestones_intro","tutorial_final"]:
        intro_id="flow:"+current
        if current=="prestige_intro" and not sim.campaign.ready_ids().is_empty():step="prestige_eligible"
        return
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
    if current in ["boss_farm","boss_win"]:
        if current=="boss_farm":world_target=_nearest_enemy()
        else:pending=""
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
        if ui.sheet.visible and ui.panel=="world":target=_panel_control("travel_stage_2")
        else:target=ui.dock.get_node("Navigation/World")

var support_value:=0.0

## Change 14: right after the first Focused Farming purchase (campaign.focus_hint), point at the next
## real tap toward that type's Farm button: the button itself in its enemy panel (both tabs show it),
## else the HUD Upgrades button when it opens that type, else the minimap (map, then the enemy). It
## ends when Focus is turned on, on "Got it", after FOCUS_HINT_SECONDS on screen, or when it no longer
## applies (another map, the upgrade gone). Another enemy's panel suspends it like any other panel.
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
    elif ui.modal_open():suspended_by="confirmation"
    elif not sim.state.prestige_batch.is_empty():suspended_by="prestige"
    elif not ui.banner.current.is_empty():suspended_by="milestone"
    elif ui.sheet.visible and not surfaces.has(ui.panel):suspended_by=ui.panel
    elif not ui.sheet.visible and not surfaces.has(""):suspended_by="closed"
    if pending=="" or suspended_by!="" or (ui.sheet.visible and ui.sheet.modulate.a<1.0):
        _hide_all();return
    title.text=tr("GUIDE_"+step.to_upper())
    support.text=tr("GUIDE_"+step.to_upper()+"_DETAIL")
    # Coins still needed, in the shared currency format rounded up (Change 13).
    if "%s" in support.text:support.text=support.text % NumberFormat.currency(support_value,true)
    picture.texture=_picture()
    intro_button.visible=intro_id!="" and (intro_id!="flow:tutorial_final" or float(sim.campaign.guided.data().final_seconds)>=float(sim.campaign.guided.rules().final_delay))
    card.mouse_filter=Control.MOUSE_FILTER_IGNORE
    _place_card()
    # Introductions are text only, except the Focused Farming hint (every mode but None) and the
    # Guided Snowman objective and Prestige cards, which point at their control.
    if pending!="focus" and (data.mode!="guided" or (intro_id!="" and not step in POINTING_INTROS)):
        highlight.hide();shade.hide();pointer.hide();return
    _point()

func _picture() -> Texture2D:
    if step in ["snowman","feature_objective"]:return ui.icon_cache.get("boss-snowman_outfit")
    if step.begins_with("focus") or step.begins_with("slots") or step=="feature_upgrades":return ui._art(147)
    if step in ["skills","rest"]:return ui._art(212)
    if step.begins_with("camp") or step=="feature_world":return ui._art(249)
    if step.begins_with("prestige") or step.begins_with("missions") or step in ["feature_prestige","feature_missions"]:return ui._art(211)
    if step in ["kill","aggression","groups","collect_wait","merge_wait","upgrade_find","equip_find","equip_collect","feature_enemy"]:return ui._art(1)
    return ui._art(60)

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
    var bob:=6.0*sin(pulse*5)
    pointer.rotation=direction.angle()-ARROW_BASE_ANGLE
    var center:=from+direction*(PATH_ARROW_DISTANCE+bob)
    pointer.position=(center-pointer.size*.5).clamp(map.global_position+Vector2(4,4),map.global_position+map.size-pointer.size-Vector2(4,4))
    pointer.show()

func _point() -> void:
    if path_point!=Vector2.INF:
        _point_path()
        return
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
