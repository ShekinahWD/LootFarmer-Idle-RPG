extends Control
## Gameplay HUD and the single panel host. Panels are built from state. While a panel keeps the
## same context (panel, selection, tab), a refresh copies only changed values into the existing
## controls, so buttons keep their identity, focus and scroll position. The sheet is sized to its
## content, anchored to the bottom of the map, with its primary actions pinned in one place.
@export var sheet_inset:=Vector2(12,10)
## Minimum seconds between value refreshes of an open panel (state revisions arrive every kill).
@export var refresh_interval:=0.25
@export var toast_seconds:=2.4
@export var toast_busy_seconds:=1.4
## Walking (by hand) to within this many world units of a sighted camp opens its panel once; it
## opens again only after leaving and coming back (Change 8).
@export var camp_open_radius:=64.0
## Prestige milestone banner: width cap and gap below the top safe-area edge.
@export var banner_max_width:=640.0
@export var banner_top_gap:=12.0
const INFO_CARD=preload("res://scenes/game/info_card.tscn")
const PRESTIGE_CARD=preload("res://scenes/game/prestige_card.tscn")
const PRESTIGE_CARD_SCRIPT=preload("res://scripts/game/prestige_card.gd")
const ITEM_ART="res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-%d.png"
const ARROW=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-273.png")
const COIN=preload("res://resources/game/coin.tres")
const GEM=preload("res://resources/game/gem.tres")
const SLOT=preload("res://scenes/game/slot.tscn")
const ROW=preload("res://scenes/game/action_row.tscn")
## Values copied from a freshly built description into the live control of the same shape.
const SYNC_PROPERTIES:=["text","disabled","tooltip_text","value","max_value","texture","icon","modulate","self_modulate","visible","theme_type_variation"]
const PANEL_ALIASES:={"travel":"world","map":"world"}
const UPGRADE_TABS:=["TAB_PLAYER","TAB_INVENTORY","TAB_SUPPLIES","TAB_GEMS","TAB_OFFLINE"]
var guide
@onready var sim: LootSimulation=$Simulation
@onready var world=$Safe/Layout/Map/ViewportContainer/Viewport/World
@onready var top=$Safe/Layout/Top/Content
@onready var dock=$Safe/Layout/Dock/Content
@onready var sheet=$Sheet
@onready var rows=$Sheet/Margin/Content/Scroll/Rows
@onready var actions=$Sheet/Margin/Content/Actions
## Non-scrolling area under the panel header (the Inventory panel's equipped section).
@onready var pinned_rows=$Sheet/Margin/Content/Pinned
@onready var notice=$Sheet/Margin/Content/Notice
@onready var stick=$Safe/Layout/Map/Joystick
@onready var banner=$Banner
var combat_group: int=-1
var history_signature: String=""
var gem_pickup_time:=0.0
var gem_pickup_amount:=0.0
var panel: String=""
var player_tab:=0
var enemy_tab:=0
var enemy_variant:=2
var selected_camp:=0
var selected: String=""
var selected_slot: int=-1
var selected_card:=""
var group: int=0
var elapsed:=0.0
var last_revision: int=-1
var toast_time:=0.0
var toast_queue: Array=[]
var confirm_action: Callable
var icon_cache: Dictionary={}
var art_cache: Dictionary={}
var stick_input:=Vector2.ZERO
var action_buttons: Array=[]
var panel_generation:=0
var panel_context:=""
var panel_clock:=0.0
var panel_revision:=-1
var settle_frames:=0
var previous_pause:=false
var inventory_filter:=0
var slot_signatures: Dictionary={}
var tier_styles: Dictionary={}
var arrow_art: Texture2D
## Offline claim already offered for this pending settlement id (the panel opens once per return).
var offline_prompted:=""
var show_completed_main:=false
## Camp the player currently stands in (-1 outside) and whether entering it still owes the panel.
var camp_inside:=-1
var camp_pending:=false

func _ready() -> void:
    world.setup(sim)
    $Safe/Layout/Map/MiniMap.sim=sim
    $Safe/Layout/Map/MiniMap.open_map.connect(func()->void:_open("world"))
    world.actor_selected.connect(func(index: int,variant: int)->void:
        enemy_variant=variant
        if index==-1:
            _open("upgrades")
        else:
            group=index
            enemy_tab=0
            _open("enemy"))
    world.camp_selected.connect(func(index: int)->void:
        selected_camp=index
        _open("camp"))
    $Safe/Layout/Map/GestureSurface.world=world
    $Safe/Layout/Map/Zoom/Slider.value_changed.connect(SettingsState.set_camera_zoom)
    SettingsState.settings_changed.connect(_sync_zoom)
    _sync_zoom()
    for id in sim.catalog.items:
        icon_cache[id]=sim.catalog.icon(id)
    arrow_art=cropped(ARROW)
    # Shape the panel type scale once at load: the first panel open otherwise pays the per-size
    # glyph cache (measured ~25 ms on the first Upgrades open).
    var font: Font=get_theme_default_font()
    var sample:="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;%+−→▲▼✓·/()^"
    for font_size in [17,18,20,24,34]:font.get_string_size(sample,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
    # Crop the fixed UI art at load with the item icons, so no panel pays the readback on first open.
    for index in [1,42,57,60,94,97,147,171,208,209,211,212,216,249,264,266,269,12,44]:_art(index)
    for page in ["World","Missions","Prestige","Upgrades","Settings"]:
        var nav_button: Button=dock.get_node("Navigation/"+page)
        nav_button.icon=cropped(nav_button.icon)
    stick.direction_changed.connect(func(value: Vector2)->void:
        stick_input=value
        if value.length()>.1:
            $Safe/Layout/Map/GestureSurface.cancel_gesture()
            world.follow_player())
    top.get_node("Bar/Pause").pressed.connect(_pause)
    $Sheet/Margin/Content/Header/Close.pressed.connect(_close)
    sim.gem_pickup.connect(_show_gem_pickup)
    sim.combat_group_changed.connect(func(g: int)->void:combat_group=g)
    sim.milestone.connect(_milestone)
    # Revival always brings the view back to the player, even after the camera was dragged away.
    sim.revived.connect(func()->void:
        $Safe/Layout/Map/GestureSurface.cancel_gesture()
        world.follow_player()
        _settle_camp())
    sim.skill_discovered.connect(func(family: String)->void:
        _say(tr("SKILL_UPGRADES_UNLOCKED") % sim.catalog.skills[family].name))
    var nav: Node=dock.get_node("Navigation")
    for page in ["World","Missions","Prestige","Upgrades","Settings"]:
        nav.get_node(page).pressed.connect(func()->void:_nav(page.to_lower()))
    var pinned: Node=dock.get_node("Inventory/GearColumn/Head/Equipped")
    for kind in ["Weapon","Outfit"]:
        pinned.get_node(kind).pressed.connect(func()->void:_open_equipped(kind.to_lower()))
    $Safe/Layout/Map/FollowTracker.gui_input.connect(func(event: InputEvent)->void:
        if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
            accept_event();_open("prestige"))
    _settle_camp()
    $Confirm/Panel/Margin/Content/Actions/Confirm.pressed.connect(func()->void:
        var action:=confirm_action
        _cancel_confirm()
        if action.is_valid():action.call())
    $Confirm/Panel/Margin/Content/Actions/Cancel.pressed.connect(_cancel_confirm)
    $Safe/Layout/Map/Achievement.pressed.connect(_open_combat_achievements)
    $Safe/Layout/Map/EnemyUpgrades.pressed.connect(func()->void:
        group=combat_group
        enemy_tab=1
        _open("enemy"))
    banner.opened.connect(func(kind: String)->void:
        if kind in ["discovered","ready","card","prestiged"]:_open("prestige"))
    sim.event.connect(_event)
    SaveService.save_failed.connect(func(_reason: String)->void:_event("SAVE_ERROR"))
    get_viewport().size_changed.connect(_safe_area)
    $Safe/Layout/Map.resized.connect(func()->void:if sheet.visible:_layout_sheet())
    _safe_area()
    dock.get_node("Inventory").resized.connect(_layout_inventory)
    AudioService.register_sfx("button",preload("res://assets/Audio/button.wav"))
    AudioService.register_sfx("prestige",preload("res://assets/Audio/prestige.wav"))
    for i in range(3):
        $Safe/Layout/Skills.get_child(i).pressed.connect(func()->void:sim.campaign.cast(i))
    _refresh_slots()
    if not sim.state.prestige_batch.is_empty():_open("prestige")
    guide=preload("res://scripts/game/tutorial_guide.gd").new()
    add_child(guide);guide.setup(self)
    if SaveService.last_load_result in ["development_reset","invalid_profile_reset"]:_event("DEVELOPMENT_SAVE_RESET")
    if SaveService.write_blocked:
        _event("SAVE_INCOMPATIBLE")

func _sync_zoom() -> void:
    $Safe/Layout/Map/Zoom/Slider.set_value_no_signal(SettingsState.camera_zoom)
    $Safe/Layout/Map/Zoom/Value.text="%.2f×" % SettingsState.camera_zoom

func _safe_area() -> void:
    var i:=LayoutService.get_safe_area_insets_canvas()
    $Safe.add_theme_constant_override("margin_left",int(i.x))
    $Safe.add_theme_constant_override("margin_top",int(i.y))
    $Safe.add_theme_constant_override("margin_right",int(i.z))
    $Safe.add_theme_constant_override("margin_bottom",int(i.w))

func _process(dt: float) -> void:
    if $Confirm.visible:_layout_confirm()
    gem_pickup_time=maxf(0,gem_pickup_time-dt)
    $Safe/Layout/Map/GemPickup.visible=gem_pickup_time>0
    world.update_camera()
    _update_skill_buttons()
    _update_supply_cooldowns()
    var keys:=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
    sim.movement=Vector2.ZERO if get_tree().paused or sim.suspended or $Confirm.visible or sheet.visible else (stick_input if stick_input.length()>.1 else keys.limit_length())
    if stick_input.length()>.1 or keys.length()>.1:
        $Safe/Layout/Map/GestureSurface.cancel_gesture()
        world.follow_player()
    _update_toast(dt)
    _layout_banner()
    banner.held=sheet.visible or $Confirm.visible or not sim.state.prestige_batch.is_empty() or sim.state.tutorial.mode=="pending"
    if settle_frames>0:
        settle_frames-=1
        _layout_sheet()
        if settle_frames==0:sheet.modulate.a=1.0
    panel_clock+=dt
    # Stats (playtime) and an item with a running Coin Tonic also tick without state revisions.
    var ticking: bool=panel=="stats" or (panel=="item" and sim.state.boost_time>0)
    if sheet.visible and (panel_revision!=sim.revision or previous_pause!=get_tree().paused or (ticking and panel_clock>=1.0)) and panel_clock>=refresh_interval:
        _refresh_panel()
    elapsed+=dt
    if elapsed<.15:
        return
    elapsed=0.0
    var p: Dictionary=sim.state.player
    var s:=sim.stats()
    top.get_node("Bar/Coins").text=fmt_currency(sim.state.coins)
    top.get_node("Bar/Gems").text=fmt_currency(sim.state.gems)
    top.get_node("Bar/Pause").text=tr("RESUME" if get_tree().paused else "PAUSE")
    top.get_node("Meters/HP").value=100*p.hp/s.hp
    top.get_node("Meters/HP/Text").text=tr("HUD_HP") % [fmt_count(p.hp),fmt_count(s.hp)]
    if p.hp<=0:
        top.get_node("Meters/HP/Text").text=tr("HUD_REVIVE") % p.respawn
    elif sim.campaign.rest_rate()>=float(sim.catalog.progression.rest.camp) and p.hp<s.hp:
        top.get_node("Meters/HP/Text").text+="  "+tr("HUD_RESTING")
    top.get_node("Meters/XP").value=100.0 if sim.state.player_level==1000 else 100.0*sim.state.xp/sim.xp_required()
    top.get_node("Meters/XP/Text").text=tr("HUD_LEVEL") % [sim.state.player_level,tr("VALUE_MAX") if sim.state.player_level==1000 else tr("XP_PROGRESS") % [fmt_count(sim.state.xp),fmt_count(sim.xp_required())]]
    if sim.state.boost_time>0:top.get_node("Meters/XP/Text").text+="  "+tr("BOOST_ACTIVE") % int(ceil(sim.state.boost_time))
    _refresh_combat_achievement()
    _refresh_loot_notifications()
    _refresh_badges()
    _refresh_follow_tracker()
    _offer_offline_claim()
    _check_camp_entry()
    if last_revision!=sim.revision or previous_pause!=get_tree().paused:
        last_revision=sim.revision
        _refresh_slots()
    previous_pause=get_tree().paused

## Prestige discovery banner: horizontally centred at the top of the safe area (Change 8).
func _layout_banner() -> void:
    if not banner.visible:return
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var available:=size.x-insets.x-insets.z-24
    var width:=minf(banner_max_width,available)
    var plate: Control=banner.get_node("Plate")
    var height:=maxf(plate.get_combined_minimum_size().y,96)
    var wanted:=Vector2(width,height)
    if not banner.size.is_equal_approx(wanted):banner.size=wanted
    var at:=Vector2(insets.x+12+(available-width)*.5,insets.y+banner_top_gap)
    if not banner.position.is_equal_approx(at):banner.position=at

## The camp the player stands in, by hand: entering one (sighted, in this stage) opens its panel
## once; dismissing it keeps it closed until the player leaves and comes back. Arrivals by respawn,
## teleport or load count as already inside, so they never pop the panel.
func _camp_at_player() -> int:
    if sim.state.player.hp<=0:return -1
    var p: Vector2=sim.position_of(sim.state.player)
    var spawns: Array=sim.campaign.stage().spawns
    for i in range(spawns.size()):
        if sim.campaign.camp_known(i) and p.distance_to(Vector2(spawns[i][0],spawns[i][1]))<=camp_open_radius:return i
    return -1

func _settle_camp() -> void:
    camp_inside=_camp_at_player()
    camp_pending=false

func _check_camp_entry() -> void:
    var here:=_camp_at_player()
    if here!=camp_inside:
        # Only a walk-in by hand owes the panel; auto-farm routes passing a camp never pop it.
        camp_pending=here>=0 and sim.movement.length()>.1
        camp_inside=here
    if not camp_pending or here<0:return
    if sheet.visible or $Confirm.visible or get_tree().paused or sim.suspended or not sim.state.prestige_batch.is_empty() or sim.state.tutorial.mode=="pending" or sim.campaign.in_combat():return
    camp_pending=false
    selected_camp=here
    _open("camp")

func _open_equipped(kind: String) -> void:
    var id: String=sim.state[kind]
    if id=="":
        _say(tr("NOTHING_EQUIPPED"))
        return
    selected=id
    selected_slot=-1
    _open("item")

## Lower-left HUD for the followed prestige opportunity: name, icon and the next step only.
func _refresh_follow_tracker() -> void:
    var tracker: Control=$Safe/Layout/Map/FollowTracker
    var id: String=str(sim.state.follow)
    var o: Dictionary=sim.state.opportunities.get(id,{})
    var ready: bool=not o.is_empty() and bool(o.ready) and not sim.state.consumed.has(id)
    var show: bool=id!="" and not o.is_empty() and not sim.state.consumed.has(id) and sim.state.prestige_batch.is_empty()
    if tracker.visible!=show:tracker.visible=show
    if not show:return
    var op: Dictionary=_opportunity(id)
    var name_label: Label=tracker.get_node("Row/Text/Name")
    var step: Label=tracker.get_node("Row/Text/Step")
    if name_label.text!=str(op.name):name_label.text=str(op.name)
    var text: String=sim.campaign.follow_summary(id)
    if step.text!=text:step.text=text
    var color:=Color(.45,1,.55) if ready else Color(.94,.95,.97)
    if step.get_theme_color("font_color")!=color:step.add_theme_color_override("font_color",color)
    var icon: TextureRect=tracker.get_node("Row/Icon")
    var art:=_path_art(str(op.path))
    if icon.texture!=art:icon.texture=art
    if tracker.mouse_filter!=Control.MOUSE_FILTER_STOP:tracker.mouse_filter=Control.MOUSE_FILTER_STOP

## Offline earnings are claimed in game: offer the claim once per settlement, when nothing else
## (a panel, a confirmation, the guide chooser or a prestige choice) is in front of the player.
func _offer_offline_claim() -> void:
    var pending_id: String=str(sim.state.offline_pending.get("id",""))
    if pending_id=="" or pending_id==offline_prompted or sheet.visible or $Confirm.visible:return
    if not sim.state.prestige_batch.is_empty() or sim.state.tutorial.mode=="pending" or sim.suspended:return
    offline_prompted=pending_id
    _open("offline")

func _update_skill_buttons() -> void:
    var owned:=sim.campaign.skill_count()>0
    for i in range(3):
        var button: Button=$Safe/Layout/Skills.get_child(i)
        button.visible=owned and i<1+sim.level("skill_slots")
        if not button.visible:continue
        var id: String=sim.state.skills[i]
        var text:=tr("SKILL_EMPTY") % (i+1) if id=="" else sim.catalog.display_name(id)
        var disabled:=true
        if id!="":
            var cd: float=sim.state.skill_cooldowns.get(sim.catalog.items[id].skill,0)
            if cd>0:text+=" · "+tr("SECONDS_VALUE") % str(ceili(cd))
            disabled=cd>0 or not sim.action_lock_reason().is_empty()
        if button.text!=text:button.text=text
        button.icon=icon_cache.get(id)
        button.disabled=disabled

func fmt(value: float) -> String:
    return NumberFormat.number(value,2)

func fmt_count(value: float) -> String:
    return NumberFormat.number(value,2) if absf(value)>=1000 else NumberFormat.count(floorf(value))

## Whole numbers without decimals, otherwise two decimals without trailing zeros.
func fmt_value(value: float) -> String:
    if absf(value)>=1000:return NumberFormat.number(value,2)
    if is_equal_approx(value,roundf(value)):return str(int(roundf(value)))
    return str(snappedf(value,.01))

## Currencies are fractional values; show whole amounts and at most one decimal below 100.
func fmt_currency(value: float) -> String:
    if absf(value)>=1000:return NumberFormat.number(value,2)
    if absf(value)>=100 or is_equal_approx(value,floorf(value)):return NumberFormat.count(floorf(value))
    return NumberFormat.number(floorf(value*10)/10.0,1)

func _refresh_slots() -> void:
    var containers: Array=[dock.get_node("Inventory/GearColumn/GearScroll/Gear"),dock.get_node("Inventory/SupplyColumn/SupplyScroll/Supplies")]
    var lists: Array=[sim.state.gear,sim.state.supplies]
    for type in range(2):
        var container: GridContainer=containers[type]
        var list: Array=lists[type]
        while container.get_child_count()<list.size():
            var slot=SLOT.instantiate()
            var index:=container.get_child_count()
            container.add_child(slot)
            slot.quick_tap.connect(func()->void:_activate_slot(type,index))
            slot.held.connect(func()->void:_select_slot(type,index))
        while container.get_child_count()>list.size():
            var child=container.get_child(container.get_child_count()-1)
            container.remove_child(child)
            child.queue_free()
        for i in range(list.size()):
            var node: Button=container.get_child(i)
            var id: String=list[i]
            var badge:=tr("EQUIPPED") if id!="" and sim.equipped(id) else (tr("AUTO") if type==1 and sim.state.auto_slots.has(i) else "")
            var shown: bool=type==1 or inventory_filter==0 or (id!="" and sim.catalog.items[id].kind==["","weapon","outfit","skill"][inventory_filter])
            var signature:="%s|%d|%d|%s|%s|%s" % [id,sim.quantity(id),int(sim.state.items.get(id,{}).get("merge",0)),badge,shown,panel=="item" and selected==id]
            if slot_signatures.get(node.get_instance_id(),"")==signature:continue
            slot_signatures[node.get_instance_id()]=signature
            node.get_node("Icon").texture=icon_cache.get(id)
            node.get_node("Count").text=tr("EMPTY_SLOT") if id=="" else "%s · ^%d" % [fmt_count(sim.quantity(id)),sim.record(id).merge]
            node.get_node("Badge").text=badge
            node.add_theme_stylebox_override("normal",_tier_style(id,panel=="item" and selected==id))
            node.add_theme_stylebox_override("hover",_tier_style(id,true))
            node.tooltip_text=sim.catalog.display_name(id) if id!="" else tr("EMPTY_SLOT")
            node.visible=shown
    _layout_inventory()
    dock.get_node("Inventory/GearColumn/Head/Heading").text=tr("HUD_GEAR") % [sim.state.gear.size()-sim.state.gear.count(""),sim.state.gear.size()]
    # Pinned equipped weapon and outfit: views of the equipped ids, never extra inventory entries.
    for kind in ["weapon","outfit"]:
        var button: Button=dock.get_node("Inventory/GearColumn/Head/Equipped/"+kind.capitalize())
        var id: String=sim.state[kind]
        button.icon=icon_cache.get(id) if id!="" else null
        button.text="" if id!="" else "—"
        button.tooltip_text=(tr("EQUIPPED_WEAPON" if kind=="weapon" else "EQUIPPED_OUTFIT")+": "+(sim.catalog.display_name(id) if id!="" else tr("NOTHING_EQUIPPED_SHORT")))
        button.add_theme_stylebox_override("normal",_tier_style(id,panel=="item" and selected==id and id!=""))
    dock.get_node("Inventory/SupplyColumn/SupplyHeading").text=tr("HUD_SUPPLIES") % [sim.state.supplies.size()-sim.state.supplies.count(""),sim.state.supplies.size()]

## One cached style per tier color and highlight state; slots never duplicate styles per refresh.
func _tier_style(id: String,highlight: bool) -> StyleBoxTexture:
    var key:="%s:%s" % [_tier_color(id).to_html(),highlight]
    if not tier_styles.has(key):
        var style: StyleBoxTexture=theme.get_stylebox("normal","Slot").duplicate()
        style.modulate_color=_tier_color(id).lightened(.22) if highlight else _tier_color(id)
        tier_styles[key]=style
    return tier_styles[key]

func _layout_inventory() -> void:
    var inventory: Control=dock.get_node("Inventory")
    var gear_width: float=inventory.get_node("GearColumn/GearScroll").size.x
    var supply_width: float=inventory.get_node("SupplyColumn/SupplyScroll").size.x
    var side:=floorf(minf((gear_width-36.0)/3.0,supply_width-20.0))
    side=clampf(side,88,156)
    for path in ["GearColumn/GearScroll/Gear","SupplyColumn/SupplyScroll/Supplies"]:
        for slot in inventory.get_node(path).get_children():
            if slot.custom_minimum_size.x!=side:slot.custom_minimum_size=Vector2(side,side)
    var height:=side+12
    for path in ["GearColumn/GearScroll","SupplyColumn/SupplyScroll"]:
        inventory.get_node(path).custom_minimum_size.y=height

func _update_supply_cooldowns() -> void:
    var slots=dock.get_node("Inventory/SupplyColumn/SupplyScroll/Supplies")
    for i in range(mini(slots.get_child_count(),sim.state.supplies.size())):
        var node=slots.get_child(i)
        var art: String=sim.catalog.art_id(sim.state.supplies[i])
        var cooling: bool=art=="potion" and sim.state.use_cd>0
        # A running Coin Tonic shows its remaining time on its own slot (gold, icon not dimmed).
        var boosting: bool=art=="coin_boost" and sim.state.boost_time>0
        var text:=tr("SECONDS_VALUE") % fmt(sim.state.use_cd) if cooling else (tr("SECONDS_VALUE") % str(ceili(sim.state.boost_time)) if boosting else "")
        var label: Label=node.get_node("Cooldown")
        if label.text!=text:
            label.text=text
            label.add_theme_color_override("font_color",Color(1,.84,.34) if boosting else Color.WHITE)
        node.get_node("Icon").modulate=Color(1,1,1,.4) if cooling else Color.WHITE

func _activate_slot(type: int,index: int) -> void:
    if type==0 or sim.state.supplies[index]=="":
        _select_slot(type,index)
        return
    if get_tree().paused or sim.suspended:
        return
    sim.use_item(sim.state.supplies[index])
    _refresh_slots()

func _select_slot(type: int,index: int) -> void:
    selected_slot=index if type==1 else -1
    selected=sim.state.supplies[index] if type==1 else sim.state.gear[index]
    _open("item")

## A navigation button toggles its own panel: tapping the open one closes it, another switches.
func _nav(which: String) -> void:
    if sheet.visible and panel==PANEL_ALIASES.get(which,which):
        _close()
        AudioService.play_sfx("button")
        return
    # The Prestige system opens with the first boss defeated; until then the button says so.
    if which=="prestige" and not sim.campaign.prestige_unlocked() and sim.state.prestige_batch.is_empty():
        _event("PRESTIGE_LOCKED_FIRST_BOSS")
        AudioService.play_sfx("button")
        return
    _open(which)

func _open(which: String) -> void:
    which=PANEL_ALIASES.get(which,which)
    $Safe/Layout/Map/GestureSurface.cancel_gesture()
    var reopening: bool=sheet.visible and panel==which
    panel=which
    notice.text=""
    stick.release()
    if not reopening:
        $Sheet/Margin/Content/Scroll.scroll_vertical=0
        sheet.modulate.a=0.0 if not sheet.visible else 1.0
    sheet.show()
    _refresh_panel(true)
    AudioService.play_sfx("button")

func _close() -> void:
    sheet.hide()
    # Free the hidden panel's rows so the tree returns to its baseline; reopening rebuilds anyway.
    for root in [rows,actions,pinned_rows]:
        for child in root.get_children():
            root.remove_child(child)
            child.queue_free()
    panel=""
    panel_context=""
    selected_card=""
    notice.text=""
    _refresh_slots()

func _pause() -> void:
    $Safe/Layout/Map/GestureSurface.cancel_gesture()
    get_tree().paused=not get_tree().paused
    stick.release()
    SaveService.save_now()

## Short feedback. With a panel open it uses the panel's fixed notice line; otherwise it queues a
## backed toast. Major milestones go to the banner instead (see _milestone).
func _event(key: String) -> void:
    if key in ["PRESTIGE_DISCOVERED","PRESTIGE_READY","STAGE_UNLOCKED"]:return
    var text:=tr(key)
    if key=="PLAYER_LEVEL_UP":text=tr("LEVEL_UP_NOTICE") % sim.state.player_level
    if key=="PRESTIGED":
        _close()
        return
    _say(text)

## Short text on the open panel's notice line, otherwise as a toast.
func _say(text: String) -> void:
    if sheet.visible:notice.text=text
    else:_toast(text)

func _toast(text: String) -> void:
    if text.is_empty() or (not toast_queue.is_empty() and toast_queue.back()==text) or ($Toast.visible and $Toast/Text.text==text):return
    toast_queue.append(text)
    while toast_queue.size()>4:toast_queue.pop_front()

func _update_toast(dt: float) -> void:
    if sheet.visible:
        $Toast.hide()
        return
    toast_time=maxf(0,toast_time-dt)
    if toast_time<=0:
        if toast_queue.is_empty():
            $Toast.hide()
            return
        $Toast/Text.text=toast_queue.pop_front()
        toast_time=toast_busy_seconds if not toast_queue.is_empty() else toast_seconds
        $Toast.show()
    # Free band of the map: above the joystick, below the player, never over an open panel.
    var map: Control=$Safe/Layout/Map
    var width:=minf(560,map.size.x-48)
    if $Toast/Text.custom_minimum_size.x!=width-28:$Toast/Text.custom_minimum_size.x=width-28
    var wanted:=Vector2(width,$Toast.get_combined_minimum_size().y)
    if not $Toast.size.is_equal_approx(wanted):$Toast.size=wanted
    $Toast.position=Vector2(map.global_position.x+(map.size.x-width)*.5,map.global_position.y+map.size.y-212-$Toast.get_combined_minimum_size().y)

func _milestone(kind: String,id: String) -> void:
    var cards: Array=[]
    match kind:
        "reset":
            banner.queue.clear();banner._finish();toast_queue.clear()
        "discovered","ready":
            var op: Dictionary=_opportunity(id)
            for card_id in _path_cards(str(op.path)):
                var d: Dictionary=sim.catalog.campaign.cards[card_id]
                cards.append({"icon":_path_art(str(op.path)),"text":PRESTIGE_CARD_SCRIPT.headline(d)})
            banner.push(kind,tr("MILESTONE_DISCOVERED" if kind=="discovered" else "MILESTONE_READY"),op.name,cards)
            AudioService.play_sfx("prestige")
        "card":
            var d: Dictionary=sim.catalog.campaign.cards[id]
            banner.push(kind,tr("MILESTONE_CARD") % d.name,d.description,[{"icon":_path_art(str(d.path)),"text":PRESTIGE_CARD_SCRIPT.headline(d)}])
        "prestiged":
            banner.push(kind,tr("MILESTONE_PRESTIGED"),tr("MILESTONE_PRESTIGED_DETAIL") % id.split(",").size())
        "stage":
            banner.push(kind,tr("MILESTONE_STAGE"),sim.catalog.stages[int(id)-1].name)

func _text(value: String,font_size:=20,color:=Color(.94,.95,.97)) -> Label:
    var label:=Label.new()
    label.text=value
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    rows.add_child(label)
    return label

func _section(value: String) -> void:
    _text(value,18,Color(1,.86,.5))

func _action(text: String,callback: Callable,enabled: bool=true,reason: String="ACTION_UNAVAILABLE",parent: Node=null) -> Button:
    var button: Button=ROW.instantiate()
    button.text=text
    # Full-width rows wrap; buttons inside a flow keep their text width so the flow can wrap them.
    button.autowrap_mode=TextServer.AUTOWRAP_OFF if parent is HFlowContainer else TextServer.AUTOWRAP_WORD_SMART
    button.custom_minimum_size.y=64
    button.disabled=not enabled
    button.tooltip_text=tr(reason) if not enabled else ""
    if not enabled:button.text+="\n"+tr(reason)
    (rows if parent==null else parent).add_child(button)
    button.pressed.connect(func()->void:
        callback.call()
        AudioService.play_sfx("button")
        if sheet.visible:
            _refresh_panel())
    return button

func _game_action(text: String,callback: Callable,enabled: bool=true,reason: String="ACTION_UNAVAILABLE",parent: Node=null) -> Button:
    var lock:=sim.action_lock_reason()
    return _action(text,callback,enabled and lock.is_empty(),lock if not lock.is_empty() else reason,parent)

## A primary action in the pinned bar. Disabled reasons go to its tooltip and the notice line, so
## the bar never changes height.
func _pinned(text: String,callback: Callable,enabled: bool=true,reason: String="",primary:=true,guide_key:="",respect_lock:=true) -> Button:
    var button:=Button.new()
    button.text=text
    button.custom_minimum_size=Vector2(0,76)
    button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
    button.add_theme_font_size_override("font_size",20)
    # The prestige batch locks gameplay actions but never its own choice controls.
    var lock:=sim.action_lock_reason() if respect_lock else ""
    button.disabled=not enabled or not lock.is_empty()
    button.tooltip_text=tr(lock if not lock.is_empty() else reason) if button.disabled and (reason!="" or lock!="") else ""
    if primary and not button.disabled:button.theme_type_variation=&"Primary"
    if guide_key!="":button.set_meta("guide",guide_key)
    actions.add_child(button)
    button.pressed.connect(func()->void:
        callback.call()
        AudioService.play_sfx("button")
        if sheet.visible:_refresh_panel())
    return button

## Previous/next item arrows, built from the owned PixelPlains arrow rotated by code.
func _arrow_button(direction: int,enabled: bool,callback: Callable) -> Button:
    var button:=Button.new()
    button.custom_minimum_size=Vector2(76,76)
    button.disabled=not enabled
    button.set_meta("guide","prev" if direction<0 else "next")
    button.tooltip_text=tr("ITEM_PREVIOUS" if direction<0 else "ITEM_NEXT")
    var art:=TextureRect.new()
    art.texture=arrow_art
    art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.mouse_filter=Control.MOUSE_FILTER_IGNORE
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    art.offset_left=16;art.offset_top=16;art.offset_right=-16;art.offset_bottom=-16
    art.pivot_offset=Vector2(22,22)
    # The source arrow points up-left (-135 degrees).
    art.rotation=-PI*.25 if direction<0 else PI*.75
    art.modulate=Color.WHITE if enabled else Color(1,1,1,.3)
    button.add_child(art)
    actions.add_child(button)
    button.pressed.connect(func()->void:
        callback.call()
        AudioService.play_sfx("button"))
    return button

func _confirm(text: String,callback: Callable) -> void:
    confirm_action=callback
    $Confirm/Panel/Margin/Content/Scroll/Text.text=text
    $Confirm/Panel/Margin/Content/Title.text=tr("CONFIRM")
    $Confirm/Panel/Margin/Content/Actions/Confirm.text=tr("CONFIRM")
    $Confirm/Panel/Margin/Content/Actions/Cancel.text=tr("CANCEL")
    $Confirm/Panel/Margin/Content/Scroll.scroll_vertical=0
    _layout_confirm()
    $Confirm.show()
    $Confirm/Panel/Margin/Content/Actions/Cancel.grab_focus()

func _cancel_confirm() -> void:
    $Confirm.hide()
    confirm_action=Callable()

## Content-sized confirmation: width first, then the wrapped text decides the height.
func _layout_confirm() -> void:
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var available:=size-Vector2(insets.x+insets.z,insets.y+insets.w)-Vector2(40,40)
    var box: Control=$Confirm/Panel
    var width:=minf(600,available.x)
    var text: Label=$Confirm/Panel/Margin/Content/Scroll/Text
    text.custom_minimum_size.x=width-60
    var wanted:=box.get_combined_minimum_size().y+text.get_combined_minimum_size().y
    box.size=Vector2(width,clampf(wanted,220,available.y))
    box.position=Vector2(insets.x+20,insets.y+20)+(available-box.size)*.5

func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if $Confirm.visible:_cancel_confirm()
        elif sheet.visible:_close()
        else:return
        get_viewport().set_input_as_handled()

func _panel_context() -> String:
    return "%s:%s:%d:%d:%d:%d:%d:%s:%d:%d:%s" % [panel,selected,selected_slot,group,player_tab,enemy_tab,enemy_variant,selected_card,inventory_filter,sim.state.prestige_batch.get("choices",[]).size(),show_completed_main]

func _refresh_panel(force_layout:=false) -> void:
    panel_clock=0.0
    panel_revision=sim.revision
    panel_generation+=1
    var generation:=panel_generation
    var scroll: int=$Sheet/Margin/Content/Scroll.scroll_vertical
    var live_rows: VBoxContainer=rows
    var live_actions: HBoxContainer=actions
    var live_pinned: VBoxContainer=pinned_rows
    var draft:=VBoxContainer.new()
    var draft_actions:=HBoxContainer.new()
    var draft_pinned:=VBoxContainer.new()
    rows=draft
    actions=draft_actions
    pinned_rows=draft_pinned
    action_buttons.clear()
    _set_title(tr("PANEL_"+panel.to_upper()))
    match panel:
        "item":_item_panel()
        "upgrades":_upgrades_panel()
        "enemy":_enemy_panel()
        "camp":_camp_panel()
        "world":_world_panel()
        "stats":_stats_panel()
        "settings":_settings_panel()
        "history":_history_panel()
        "prestige":_prestige_panel()
        "missions":_missions_panel()
        "inventory":_inventory_panel()
        "offline":_offline_panel()
    var context:=_panel_context()
    var replace:=context!=panel_context
    var mapping: Dictionary={}
    var structural:=_sync_panel_children(live_rows,draft,mapping,replace)
    structural=_sync_panel_children(live_actions,draft_actions,mapping,replace) or structural
    structural=_sync_panel_children(live_pinned,draft_pinned,mapping,replace) or structural
    for info in action_buttons:
        info.node=mapping.get(info.node,info.node)
    rows=live_rows
    actions=live_actions
    pinned_rows=live_pinned
    draft.free()
    draft_actions.free()
    draft_pinned.free()
    actions.visible=actions.get_child_count()>0
    pinned_rows.visible=pinned_rows.get_child_count()>0
    panel_context=context
    if get_tree().paused:
        $Sheet/Margin/Content/Header/Title.text+=" · "+tr("PAUSE")
    if structural or force_layout:
        settle_frames=2
        if not replace:_restore_panel_scroll(scroll,generation)

func _set_title(text: String,color:=Color(.94,.95,.97)) -> void:
    var title: Label=$Sheet/Margin/Content/Header/Title
    title.text=text
    title.add_theme_color_override("font_color",color)

## Bottom-anchored over the map, sized to header + content + pinned actions, capped to the map.
## Scrolling appears only when the content is taller than the cap.
func _layout_sheet() -> void:
    var map: Control=$Safe/Layout/Map
    var width:=map.size.x-sheet_inset.x*2
    var available:=map.size.y-sheet_inset.y*2
    sheet.set_anchors_preset(Control.PRESET_TOP_LEFT)
    if sheet.size.x!=width:sheet.size.x=width
    var chrome: float=sheet.get_combined_minimum_size().y
    var content: float=rows.get_combined_minimum_size().y
    var height:=clampf(chrome+content+4,minf(200,available),available)
    sheet.size=Vector2(width,height)
    sheet.position=Vector2(map.global_position.x+sheet_inset.x,map.global_position.y+map.size.y-sheet_inset.y-height)

func _sync_panel_children(live: Node,draft: Node,mapping: Dictionary,replace_all:=false) -> bool:
    # Build descriptions off-tree; reconcile them into live controls of the same shape. Only
    # values that differ are written, so an unchanged panel does no layout work at all.
    var changed:=false
    var desired:=draft.get_children()
    for i in range(desired.size()):
        var incoming: Node=desired[i]
        if i>=live.get_child_count() or replace_all or not _same_shape(live.get_child(i),incoming):
            if i<live.get_child_count():
                var old:=live.get_child(i)
                live.remove_child(old)
                old.queue_free()
            draft.remove_child(incoming)
            live.add_child(incoming)
            live.move_child(incoming,i)
            mapping[incoming]=incoming
            changed=true
        else:
            var existing:=live.get_child(i)
            mapping[incoming]=existing
            for key in incoming.get_meta_list():existing.set_meta(key,incoming.get_meta(key))
            for key in SYNC_PROPERTIES:
                if key in incoming:
                    var value=incoming.get(key)
                    if existing.get(key)!=value:existing.set(key,value)
            if (incoming is Label or incoming is Button) and incoming.has_theme_color_override("font_color"):
                var color: Color=incoming.get_theme_color("font_color")
                if existing.get_theme_color("font_color")!=color:existing.add_theme_color_override("font_color",color)
            if incoming is BaseButton:
                for connection in existing.get_signal_connection_list("pressed"):
                    existing.disconnect("pressed",connection.callable)
                for connection in incoming.get_signal_connection_list("pressed"):
                    existing.connect("pressed",connection.callable)
            changed=_sync_panel_children(existing,incoming,mapping) or changed
    while live.get_child_count()>desired.size():
        var old:=live.get_child(live.get_child_count()-1)
        live.remove_child(old)
        old.queue_free()
        changed=true
    return changed

## A live control is reused only for a description of the same class and layout role.
func _same_shape(live: Node,incoming: Node) -> bool:
    if live.get_class()!=incoming.get_class() or live.get_script()!=incoming.get_script():return false
    if live is Control:
        if live.custom_minimum_size!=incoming.custom_minimum_size or live.theme_type_variation!=incoming.theme_type_variation and not (live is Button):return false
        # Only explicit overrides: off-tree descriptions cannot resolve theme defaults.
        if (live is Label or live is Button) and (live.has_theme_font_size_override("font_size")!=incoming.has_theme_font_size_override("font_size") or (incoming.has_theme_font_size_override("font_size") and live.get_theme_font_size("font_size")!=incoming.get_theme_font_size("font_size"))):return false
    return true

func _restore_panel_scroll(offset: int,generation: int) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if generation==panel_generation and is_instance_valid(rows):
        $Sheet/Margin/Content/Scroll.scroll_vertical=offset

# ---------------------------------------------------------------- item details

## Items in the inventory's stable display order for the current category (gear grid respects
## the dock filter; supplies are their own list).
func _browse_list() -> Array:
    var supplies: bool=selected_slot>=0 or (sim.catalog.items.has(selected) and sim.catalog.items[selected].kind=="consumable")
    var result: Array=[]
    for id in (sim.state.supplies if supplies else sim.state.gear):
        if id=="" or result.has(id):continue
        if not supplies and inventory_filter>0 and sim.catalog.items[id].kind!=["","weapon","outfit","skill"][inventory_filter]:continue
        result.append(id)
    return result

func _browse(direction: int) -> void:
    var list:=_browse_list()
    var index:=list.find(selected)
    if index<0 or list.is_empty():return
    var next:=clampi(index+direction,0,list.size()-1)
    if next==index:return
    selected=list[next]
    if selected_slot>=0:selected_slot=sim.state.supplies.find(selected)
    _refresh_panel(true)
    _refresh_slots()

func _item_panel() -> void:
    if selected!="" and sim.quantity(selected)==0:
        # The item ran out while open (used, merged or evolved away): show its neighbour.
        var list:=_browse_list()
        selected=list[0] if not list.is_empty() else ""
    if selected=="" or not sim.catalog.items.has(selected):
        _set_title(tr("EMPTY_SLOT"))
        _text(tr("EMPTY_SLOT_HELP"))
        if selected_slot>=0:
            var row:=HFlowContainer.new();rows.add_child(row)
            _game_action(tr("BUY_POTION"),func()->void:sim.purchase_consumable("potion"),true,"",row)
            _game_action(tr("BUY_BOOST"),func()->void:sim.purchase_consumable("coin_boost"),true,"",row)
            _game_action(tr("AUTO_SLOT_STATUS") % tr("ON" if sim.state.auto_slots.has(selected_slot) else "OFF"),func()->void:sim.bind_auto(selected_slot),true,"",row)
        return
    var id:=selected
    var def: Dictionary=sim.catalog.items[id]
    var r:=sim.record(id)
    var list:=_browse_list()
    _set_title(sim.catalog.display_name(id),_tier_color(id).lightened(.55))
    # Comparison layout (Change 8): the equipped item of this slot on top, the prospective item
    # below it, next to the pinned Equip button. Deltas come from the simulation's own stat getter.
    var comparing: bool=def.kind in ["weapon","outfit"] and not sim.equipped(id)
    var deltas: Dictionary={}
    if comparing:
        var current: String=sim.state[def.kind]
        var equipped_box:=_item_summary_card(current,tr("COMPARE_EQUIPPED"),Color(.6,1,.75))
        if current!="":
            for key in sim.normal(current):_stat_line(equipped_box,_stat_text(key,sim.normal(current)[key],true),0.0,key,18,Color(.86,.89,.93))
            for key in sim.record(current).extras:_stat_line(equipped_box,"+ "+_stat_text(key,sim.record(current).extras[key],true),0.0,key,17,Color(.7,.75,.82))
        var now: Dictionary=sim.stats()
        var after: Dictionary=sim.stats_with(id if def.kind=="weapon" else sim.state.weapon,id if def.kind=="outfit" else sim.state.outfit)
        for key in now:deltas[key]=float(after[key])-float(now[key])
    var ribbon:=tr("COMPARE_SELECTED") if comparing else (tr("COMPARE_EQUIPPED") if sim.equipped(id) else tr("COMPARE_ITEM"))
    var details:=_item_summary_card(id,ribbon,Color(1,.86,.5) if comparing else Color(.6,1,.75),list.find(id),list.size())
    var shown: Dictionary={}
    for key in sim.normal(id):
        _stat_line(details,_stat_text(key,sim.normal(id)[key],true),deltas.get(key,0.0),key,22)
        shown[key]=true
    for key in r.extras:
        _stat_line(details,"+ "+_stat_text(key,r.extras[key],true),0.0 if shown.has(key) else deltas.get(key,0.0),key,19,Color(.75,.8,.87))
        shown[key]=true
    # Stats only the equipped item gives: shown as what equipping this one would lose.
    for key in ["damage","hp","defense","crit","crit_damage","speed","lifesteal","regen"]:
        if not shown.has(key) and absf(deltas.get(key,0.0))>=.005:
            _stat_line(details,tr("STAT_"+key.to_upper())+"  —",deltas[key],key,19,Color(.7,.75,.82))
    if comparing:
        var effect:=[]
        var gains:=0;var losses:=0
        for key in ["damage","hp","crit","speed","defense","lifesteal","regen"]:
            if absf(deltas.get(key,0.0))>=.005:effect.append(_signed_stat(key,deltas[key]))
            if deltas.get(key,0.0)>=.005:gains+=1
            elif deltas.get(key,0.0)<=-.005:losses+=1
        # The summary takes the colour of its overall direction: all gains, all losses or mixed.
        var tone:=Color(.45,1,.55) if gains>0 and losses==0 else (Color(1,.5,.45) if losses>0 and gains==0 else (Color(1,.86,.5) if gains>0 else Color(.72,.9,1)))
        var verdict:=tr("COMPARE_UPGRADE") if gains>0 and losses==0 else (tr("COMPARE_DOWNGRADE") if losses>0 and gains==0 else (tr("COMPARE_MIXED") if gains>0 else tr("NO_CHANGE")))
        _card_line(details,verdict+" · "+(tr("EQUIP_EFFECT") % (", ".join(effect) if not effect.is_empty() else tr("NO_CHANGE"))),18,tone)
    var owned:=tr("ITEM_OWNED") % fmt_count(r.qty)
    if def.kind in ["weapon","outfit"]:owned+=" · "+tr("ITEM_EQUIPPED_SHORT" if sim.equipped(id) else "ITEM_STORED_SHORT")
    _card_line(details,owned,17,Color(.8,.84,.9))
    var cap:=sim.merge_cap(id)
    if r.merge<cap:
        var gains: Array[String]=[]
        for stat in def.normal:
            var gain: float=sim.next_merge_gain(id,stat)
            if gain>0:gains.append(_stat_text(stat,gain,true))
        _card_line(details,tr("NEXT_MERGE_GAIN")+" "+", ".join(gains),17,Color(.5,1,.65))
    else:
        _card_line(details,tr("STOCK_BONUS") % fmt(maxi(0,int(r.qty)-1)*float(sim.catalog.progression.merge.stock_bonus_per_copy)*100),17,Color(.5,1,.65))
    if sim.catalog.art_id(id)=="potion":_text(tr("POTION_ROLE") % fmt_value(float(sim.catalog.progression.potion_cooldown)),17,Color(.8,.84,.9))
    if sim.catalog.art_id(id)=="coin_boost":
        _text(tr("COIN_TONIC_ROLE") % [fmt(sim.normal(id).coin_bonus*100),fmt_value(sim.coin_boost_duration())],17,Color(.8,.84,.9))
        if sim.state.boost_time>0:_text(tr("COIN_TONIC_ACTIVE") % [fmt(float(sim.state.boost_power)*100),ceili(sim.state.boost_time)],18,Color(1,.84,.34))
    if def.get("skill","")=="heal":_text(tr("HEAL_ROLE") % [fmt(minf(sim.normal(id).power*(1+sim.campaign.bonus("skill")),sim.stats().hp*.12)),fmt(sim.player_upgrade_value("cooldown_heal"))],17,Color(.8,.84,.9))
    # Secondary actions: a wrapping row, sized for their widest label.
    var more:=HFlowContainer.new()
    more.add_theme_constant_override("h_separation",8)
    more.add_theme_constant_override("v_separation",8)
    var amount:=mini(int(r.qty)-1,cap-int(r.merge))
    if r.merge<cap and amount>1:_game_action(tr("MERGE_ALL") % amount,func()->void:if selected==id:sim.merge(id,true),true,"",more)
    if def.next!="" and r.merge>=cap:
        _game_action(tr("EVOLVE") % sim.catalog.display_name(def.next),func()->void:if selected==id:sim.evolve(id),r.qty>=101,"EVOLUTION_NEEDS",more)
    if def.kind=="skill":
        for i in range(1+sim.level("skill_slots")):
            _game_action(tr("EQUIP_SKILL_SLOT") % (i+1),func()->void:if selected==id:sim.campaign.equip_skill(id,i),true,"",more)
    if def.kind=="consumable" and selected_slot>=0:
        _game_action(tr("AUTO_SLOT_STATUS") % tr("ON" if sim.state.auto_slots.has(selected_slot) else "OFF"),func()->void:sim.bind_auto(selected_slot),true,"",more)
    if not def.extras.is_empty():
        var cost:=ceili(float(def.reroll)*(1-sim.campaign.bonus("reroll_discount")))
        _game_action(tr("REROLL") % cost,func()->void:_confirm(tr("REROLL_CONFIRM") % cost,func()->void:if selected==id:sim.reroll(id)),true,"",more)
    for button in more.get_children():
        button.size_flags_horizontal=0
        button.custom_minimum_size=Vector2(0,64)
        button.add_theme_font_size_override("font_size",18)
    if more.get_child_count()>0:rows.add_child(more)
    else:more.free()
    if sim.copy_growth(id):
        _text(tr("COPY_GROWTH_EXPLAIN") % cap,17,Color(.8,.84,.9))
    elif def.next!="" and r.merge>=cap:
        _text(tr("EVOLUTION_EXPLAIN"),17,Color(.8,.84,.9))
    elif def.next=="":
        _text(tr("MAX_ITEM_TIER"),17,Color(.8,.84,.9))
    # Pinned: previous, primary, merge, next. Positions never change while browsing.
    var index:=list.find(id)
    _arrow_button(-1,index>0,func()->void:_browse(-1))
    if def.kind=="consumable":
        _pinned(tr("USE"),func()->void:if selected==id:sim.use_item(id),true,"",true,"use")
    else:
        _pinned(tr("UNEQUIP" if sim.equipped(id) else "EQUIP"),func()->void:if selected==id:sim.equip(id),true,"",not sim.equipped(id),"equip")
    _pinned(tr("ITEM_MERGE_ACTION"),func()->void:if selected==id:sim.merge(id),r.qty>1 and r.merge<cap,"NEED_DUPLICATES" if r.qty<2 else "MERGE_MAX",false,"merge")
    _arrow_button(1,index>=0 and index<list.size()-1,func()->void:_browse(1))

## One item card: a small ribbon (Equipped / Selected), the tier-framed icon and the name with tier
## and merge level. Returns the details column for stat lines. An empty id is the slot placeholder.
func _item_summary_card(id: String,ribbon: String,ribbon_color: Color,at:=-1,count:=0) -> VBoxContainer:
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    rows.add_child(card)
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",4)
    card.add_child(box)
    var head:=HBoxContainer.new()
    box.add_child(head)
    var tag:=Label.new()
    tag.text=ribbon
    tag.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    tag.add_theme_font_size_override("font_size",16)
    tag.add_theme_color_override("font_color",ribbon_color)
    head.add_child(tag)
    var where:=Label.new()
    where.text=tr("ITEM_POSITION") % [at+1,count] if count>1 and at>=0 else ""
    where.add_theme_font_size_override("font_size",16)
    where.add_theme_color_override("font_color",Color(.7,.75,.82))
    head.add_child(where)
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",14)
    box.add_child(line)
    var frame:=PanelContainer.new()
    frame.add_theme_stylebox_override("panel",_tier_style(id,false))
    frame.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
    line.add_child(frame)
    var icon:=TextureRect.new()
    icon.texture=icon_cache.get(id) if id!="" else null
    icon.custom_minimum_size=Vector2(72,72)
    icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    frame.add_child(icon)
    var details:=VBoxContainer.new()
    details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation",3)
    line.add_child(details)
    if id=="":
        _card_line(details,tr("NOTHING_EQUIPPED"),18,Color(.7,.75,.82))
        return details
    _card_line(details,sim.catalog.display_name(id),21,_tier_color(id).lightened(.55))
    var merge_text:=(tr("ITEM_TIER_MERGE_CAP") % [int(sim.catalog.items[id].tier),int(sim.record(id).merge),sim.merge_cap(id)]) if sim.copy_growth(id) else (tr("ITEM_TIER_MERGE") % [int(sim.catalog.items[id].tier),int(sim.record(id).merge)])
    _card_line(details,merge_text,17,Color(.75,.8,.87))
    return details

func _stat_line(parent: Control,text: String,delta: float,key: String,font_size: int,color:=Color.WHITE) -> void:
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",10)
    parent.add_child(line)
    var label:=Label.new()
    label.text=text
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    line.add_child(label)
    if absf(delta)>=.005:
        var change:=Label.new()
        change.text=("▲ " if delta>0 else "▼ ")+_signed_stat(key,delta)
        change.add_theme_font_size_override("font_size",font_size-3)
        change.add_theme_color_override("font_color",Color(.45,1,.55) if delta>0 else Color(1,.5,.45))
        change.add_theme_constant_override("outline_size",3)
        line.add_child(change)

func _signed_stat(key: String,value: float) -> String:
    var sign:="+" if value>=0 else "−"
    if key in ["crit","lifesteal","speed","coin_bonus"]:return sign+fmt(absf(value)*100)+"% "+tr("STAT_"+key.to_upper())
    return sign+fmt(absf(value))+" "+tr("STAT_"+key.to_upper())

func _tabs(keys: Array,active: int,callback: Callable) -> void:
    var bar:=HBoxContainer.new()
    bar.name="Tabs"
    bar.add_theme_constant_override("separation",6)
    rows.add_child(bar)
    for i in range(keys.size()):
        var button:=Button.new()
        button.text=tr(keys[i])
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.custom_minimum_size.y=56
        button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
        button.add_theme_font_size_override("font_size",18)
        if i==active:button.theme_type_variation=&"Primary"
        button.set_meta("guide","tab_"+str(keys[i]).to_lower())
        bar.add_child(button)
        button.pressed.connect(func()->void:
            callback.call(i)
            $Sheet/Margin/Content/Scroll.scroll_vertical=0
            _refresh_panel(true))

func _portrait_texture(body: String) -> Texture2D:
    if body in sim.catalog.items:return icon_cache[body]
    var atlas:=AtlasTexture.new()
    atlas.atlas=load("res://assets/PixelPlains/Characters 24x24/"+("Autumn 4 v2.png" if body=="death" else ("Gato 4 v2.png" if body=="cat" else "Basic character v2.png")))
    atlas.region=Rect2(0,0,24,24)
    return atlas

## Owned PixelPlains item art cropped to its used pixels (the files carry wide transparent margins).
func _art(index: int) -> Texture2D:
    if not art_cache.has(index):art_cache[index]=cropped(load(ITEM_ART % index))
    return art_cache[index]

static func cropped(source: Texture2D) -> Texture2D:
    return UiArt.cropped(source)

# ---------------------------------------------------------------- upgrades

func _upgrades_panel() -> void:
    _tabs(UPGRADE_TABS,player_tab,func(i: int)->void:player_tab=i)
    var sections: Array=[["respawn","movement","skill_slots","skill_auto_0","skill_auto_1","skill_auto_2"],["gear_slots","supply_slots"],["merge_supplies","merge_speed","auto_use","use_speed"],["gem_chance","gem_amount","boss_gem_chance","boss_gem_amount"],["offline_cap","offline_coins","offline_gems","offline_weapon","offline_outfit","offline_consumable","offline_weapon_rate","offline_outfit_rate","offline_consumable_rate"]]
    if player_tab==0:_text(tr("UPGRADES_PLAYER_HINT"),17,Color(.75,.8,.87))
    if player_tab==4:
        if not sim.state.offline_pending.is_empty():
            _text(tr("OFFLINE_PENDING_NOTE"),18,Color(1,.86,.5))
            _action(tr("OFFLINE_CLAIM"),func()->void:_open("offline"))
        else:
            var r: Dictionary=sim.campaign.offline_receipt
            if not r.is_empty():
                _text(tr("OFFLINE_CLAIMED_RECEIPT") % [fmt(r.rewarded_hours),fmt(r.coins),fmt(r.gems)])
                for id in r.items:_text(sim.catalog.display_name(id)+" ×"+fmt(r.items[id]),18)
        var snap: Dictionary=sim.campaign.offline_snapshot()
        _text(tr("OFFLINE_RATES") % [fmt(snap.coins),fmt(snap.gems),fmt(snap.cap/3600)],18,Color(.8,.84,.9))
    for id in sections[player_tab]:
        # Skill slots and auto-cast appear with the first skill found (Change 8).
        if id.begins_with("skill_") and sim.state.skills_seen.is_empty():continue
        _group_upgrade_card(id,-1)
    if player_tab==0:
        for i in range(1+sim.level("skill_slots")):
            if sim.level("skill_auto_"+str(i))>0:
                _game_action(tr("SKILL_AUTO_TOGGLE") % [i+1,tr("ON" if sim.state.skill_auto[i] else "OFF")],func()->void:sim.state.skill_auto[i]=not sim.state.skill_auto[i];sim.touch())
        # A skill's own upgrades stay hidden until that skill has been obtained once.
        for key in sim.catalog.skills:
            if sim.skill_seen(key):_group_upgrade_card("cooldown_"+key,-1)
    if player_tab==1:_action(tr("PANEL_INVENTORY"),func()->void:_open("inventory"))
    if player_tab==2:
        var row:=HFlowContainer.new();rows.add_child(row)
        _game_action(tr("BUY_POTION"),func()->void:sim.purchase_consumable("potion"),true,"",row)
        _game_action(tr("BUY_BOOST"),func()->void:sim.purchase_consumable("coin_boost"),true,"",row)

## Compact upgrade card: icon, name, computed benefit, a fixed status line and the buy button.
## The status line is always present, so a reason never changes the card's height.
func _group_upgrade_card(id: String,g: int) -> void:
    var def: Dictionary=sim.catalog.upgrades[id]
    var current:=sim.level(id,g)
    var maxed:=sim.upgrade_maxed(id,g)
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    rows.add_child(card)
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",12)
    card.add_child(line)
    _card_icon(line,_upgrade_icon(id,g))
    var text:=VBoxContainer.new()
    text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    text.add_theme_constant_override("separation",2)
    line.add_child(text)
    _card_line(text,tr("UP_"+id.to_upper()),20,Color.WHITE)
    _card_line(text,_upgrade_benefit(id,g),18,Color(.6,1,.75))
    var reason:=sim.upgrade_block_reason(id,g)
    var status:=Label.new()
    status.name="BlockReason"
    status.text=(tr("UPGRADE_LEVEL") % [current,def.cap])+("" if reason.is_empty() or reason=="UPGRADE_MAX" else "  ·  "+tr(reason))
    status.tooltip_text=tr(reason) if not reason.is_empty() else ""
    status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
    status.add_theme_font_size_override("font_size",17)
    status.add_theme_color_override("font_color",Color(1,.72,.45) if not reason.is_empty() and reason!="UPGRADE_MAX" else Color(.7,.75,.82))
    text.add_child(status)
    var buy:=Button.new()
    buy.custom_minimum_size=Vector2(128,76)
    buy.text=tr("UPGRADE_MAX") if maxed else fmt_currency(sim.upgrade_cost(id,g))
    buy.icon=null if maxed else (COIN if def.currency=="coins" else GEM)
    buy.expand_icon=true
    buy.add_theme_constant_override("icon_max_width",26)
    buy.disabled=not reason.is_empty()
    buy.theme_type_variation=&"Primary" if reason.is_empty() else &""
    buy.tooltip_text=tr(reason) if not reason.is_empty() else tr("UP_"+id.to_upper())
    buy.set_meta("upgrade",id)
    buy.set_meta("guide","buy_"+id if id=="loot" else "buy_upgrade")
    buy.pressed.connect(func()->void:sim.buy_upgrade(id,g))
    line.add_child(buy)
    action_buttons.append({"node":buy,"kind":"upgrade","id":id,"group":g})

func _upgrade_icon(id: String,g: int) -> Texture2D:
    var def: Dictionary=sim.catalog.upgrades[id]
    var icon: Texture2D=icon_cache.get(sim.catalog.groups[g].body) if g>=0 and def.scope in ["type","normal_type"] else _art(147)
    if id.begins_with("cooldown_"):icon=icon_cache.get("skill_"+id.trim_prefix("cooldown_"))
    elif id in ["auto_use","use_speed","merge_supplies","merge_speed","supply_slots","supply_drop"]:icon=icon_cache.get("potion")
    elif id in ["map_detail","camp_radius","reveal_radius"]:icon=_art(249)
    elif id.begins_with("offline_"):icon=_art(171)
    if id=="coin_amount":icon=COIN
    elif id in ["gem_chance","gem_amount","boss_gem_chance","boss_gem_amount"]:icon=GEM
    elif id in ["loot","merge_gear"] and g>=0:icon=icon_cache.get(sim.catalog.groups[g].weapon)
    return icon

func _upgrade_row(id: String,g: int=-1) -> void:
    _group_upgrade_card(id,g)

func _upgrade_benefit(id: String,g: int) -> String:
    var next:=0 if sim.upgrade_maxed(id,g) else 1
    if int(sim.catalog.upgrades[id].cap)==1:
        return tr("UPGRADE_TRANSITION") % [tr("ON" if sim.level(id,g)>0 else "OFF"),tr("ON")]
    var current:=sim.group_upgrade_value(id,g,enemy_variant) if g>=0 else sim.player_upgrade_value(id)
    var future:=sim.group_upgrade_value(id,g,enemy_variant,next) if g>=0 else sim.player_upgrade_value(id,next)
    var percent:=id in ["loot","supply_drop","skill_drop","gem_chance","boss_gem_chance","movement","reveal_radius","camp_radius"]
    var left:=fmt_value(current*100)+"%" if percent else fmt_value(current)
    var right:=fmt_value(future*100)+"%" if percent else fmt_value(future)
    var value:=tr("UPGRADE_TRANSITION") % [left,right]
    if id in ["respawn","collect_speed","merge_speed","gear_merge_speed","use_speed","spawn_cooldown"]:value=tr("SECONDS_VALUE") % value
    if id=="supply_drop":value=tr("POTION_CHANCE_VALUE") % value
    return value

# ---------------------------------------------------------------- enemy

func _enemy_panel() -> void:
    if group<0 or group>=sim.catalog.groups.size() or not sim.campaign.discovered(group):
        _text(tr("UNDISCOVERED"));return
    var d: Dictionary=sim.catalog.groups[group]
    _set_title(d.name)
    var head:=HBoxContainer.new()
    head.add_theme_constant_override("separation",12)
    rows.add_child(head)
    var portrait:=TextureRect.new()
    portrait.texture=_portrait_texture(d.body)
    portrait.custom_minimum_size=Vector2(64,64)
    portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    head.add_child(portrait)
    var summary:=VBoxContainer.new()
    summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    head.add_child(summary)
    _card_line(summary,tr("ENEMY_LEVEL") % d.level+("  ·  "+tr("BOSS_LABEL") if d.boss else ""),20,Color(1,.86,.5) if d.boss else Color.WHITE)
    _card_line(summary,tr("ENEMY_KILLS") % fmt_count(sim.state.group_kills[group]),17,Color(.75,.8,.87))
    if not d.skills.is_empty() and not d.boss and enemy_variant==3:_text(tr("SKILL_TUTORIAL"),17,Color(.8,.84,.9))
    var variants: Array=sim.campaign.variants(group)
    if not variants.has(enemy_variant):enemy_variant=variants[0]
    if not d.boss:_tabs(["VARIANT_OUTFIT","VARIANT_WEAPON","VARIANT_BOTH","VARIANT_SKILL"].slice(0,variants.size()),enemy_variant,func(i: int)->void:enemy_variant=i)
    _tabs(["TAB_OVERVIEW","TAB_UPGRADES","TAB_ACHIEVEMENTS"],enemy_tab,func(i: int)->void:enemy_tab=i)
    if enemy_tab==2:_group_achievements_panel();return
    if sim.level("focus",group)>0:_game_action(tr("FOCUS_GROUP") % [d.name,tr("ON" if sim.state.focus==group and sim.state.focus_variant==enemy_variant else "OFF")],func()->void:sim.focus(group,enemy_variant),sim.campaign.spot_discovered(group,enemy_variant),"SPOT_UNDISCOVERED")
    if enemy_tab==1:
        _section(tr("SECTION_REWARDS"))
        for id in ["loot","coin_amount","group_xp","supply_drop"]:_group_upgrade_card(id,group)
        if not d.skills.is_empty():_group_upgrade_card("skill_drop",group)
        if not d.boss:
            _group_upgrade_card("spawn_amount",group);_group_upgrade_card("spawn_cooldown",group)
        # Automation refinements appear once their automation is unlocked.
        _section(tr("SECTION_AUTOMATION"))
        for pair in [["focus",""],["collect",""],["collect_range","collect"],["collect_batch","collect"],["collect_speed","collect"],["merge_gear",""],["gear_merge_speed","merge_gear"]]:
            if pair[1]=="" or sim.level(pair[1],group)>0:_group_upgrade_card(pair[0],group)
        return
    var def: Dictionary=sim.enemy_definition(group,enemy_variant)
    if sim.level("reveal_stats",group)==0:_group_upgrade_card("reveal_stats",group)
    else:_text(tr("ENEMY_STATS_VALUES") % [fmt(def.hp),fmt(def.damage),fmt(def.interval),fmt(def.defense)],20)
    if sim.level("reveal_drops",group)==0:_group_upgrade_card("reveal_drops",group)
    else:
        _text(tr("DROP_COINS") % fmt(sim.coin_reward(group))+"  ·  "+tr("DROP_GEMS") % [fmt(sim.gem_chance(group)*100),fmt(sim.gem_amount(0,group))],18)
        for id in def.loot:_loot_row(id,sim.gear_chance(group)*100)
        for skill in def.skills:_loot_row("skill_"+skill,sim.group_upgrade_value("skill_drop",group)*100/def.skills.size())
        _loot_row("potion",sim.consumable_chance(group,"potion")*80)
        _loot_row("coin_boost",sim.consumable_chance(group,"coin_boost")*20)

func _loot_row(id: String,chance: float,count:=0) -> void:
    var row:=HBoxContainer.new()
    var icon:=TextureRect.new()
    icon.texture=icon_cache[id]
    icon.custom_minimum_size=Vector2(34,34)
    icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    row.add_child(icon)
    var label:=Label.new()
    label.text=(sim.catalog.display_name(id)+(" ×"+fmt_count(count) if count>0 else "")) if chance<0 else tr("DROP_ITEM") % [sim.catalog.display_name(id),fmt(chance)]
    label.add_theme_font_size_override("font_size",18)
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    row.add_child(label)
    rows.add_child(row)

func _group_achievements_panel() -> void:
    _text(tr("ACHIEVEMENT_BONUS") % [sim.achievement_damage(group)*100,sim.achievement_gems(group)*100],20,Color(.6,1,.75))
    var kills: int=sim.state.group_kills[group]
    for threshold in sim.achievement_thresholds(group):
        var line:=HBoxContainer.new()
        line.add_theme_constant_override("separation",10)
        rows.add_child(line)
        var label:=Label.new()
        label.custom_minimum_size.x=150
        label.text=("✓ " if kills>=threshold else "")+"%s / %s" % [fmt_count(mini(kills,threshold)),fmt_count(threshold)]
        label.add_theme_font_size_override("font_size",18)
        label.add_theme_color_override("font_color",Color(.5,1,.65) if kills>=threshold else Color.WHITE)
        line.add_child(label)
        var bar:=ProgressBar.new()
        bar.theme_type_variation=&"XP"
        bar.custom_minimum_size=Vector2(0,18)
        bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
        bar.max_value=threshold
        bar.value=minf(kills,threshold)
        bar.show_percentage=false
        line.add_child(bar)
    _text(tr("ACHIEVEMENT_REWARD_SHORT") % [sim.catalog.progression.achievements.damage_per_milestone*100,sim.catalog.progression.achievements.gems_per_milestone*100]+"  ·  "+tr("ACHIEVEMENT_PERMANENT"),17,Color(.75,.8,.87))

func _refresh_combat_achievement() -> void:
    var target: Dictionary=sim._find_actor(sim.locked_target)
    if not target.is_empty() and int(target.group) in range(sim.catalog.groups.size()):
        combat_group=int(target.group)
    elif int(sim.state.focus) in range(sim.catalog.groups.size()):
        combat_group=int(sim.state.focus)
    elif not sim.campaign.stage().groups.has(combat_group) or sim.movement.length()>.1:
        combat_group=sim.nearest_group()
    # Keep this section available between kills, including one-hit kills.
    var g:=combat_group
    var button: Button=$Safe/Layout/Map/Achievement
    var known: bool=sim.campaign.discovered(g)
    button.visible=known
    $Safe/Layout/Map/EnemyUpgrades.visible=known
    $Safe/Layout/Map/EnemySection.visible=known
    $Safe/Layout/Map/EnemySection.text=sim.catalog.groups[g].name if known else ""
    var milestones: Array=sim.achievement_thresholds(g)
    var tier:=sim.achievement_level(g)
    var progress:=tr("ACHIEVEMENT_DONE") if tier==milestones.size() else "%s / %s" % [fmt_count(sim.state.group_kills[g]),fmt_count(milestones[tier])]
    var text:=tr("TAB_ACHIEVEMENTS")+"\n"+progress
    if button.text!=text:button.text=text
    button.set_meta("group",g)

func _open_combat_achievements() -> void:
    group=int($Safe/Layout/Map/Achievement.get_meta("group",0))
    enemy_tab=2
    _open("enemy")

# ---------------------------------------------------------------- world, camps and travel

func _camp_status(st: int,i: int) -> String:
    if st==int(sim.state.stage) and int(sim.state.spawn)==i:return tr("CAMP_STATE_SELECTED")
    if sim.state.camps.get(str(st),[0]).has(i):return tr("CAMP_STATE_OWNED")
    return tr("CAMP_STATE_LOCKED") % sim.campaign.camp_price(i)

## Camps of the current stage first (where the camp lesson points), then the map, then travel.
func _world_panel() -> void:
    var stage: Dictionary=sim.campaign.stage()
    _set_title(stage.name)
    var gates: Array=stage.gates
    var count:=0
    for id in gates:
        if sim.state.run_kills.get(id,0)>0:count+=1
    if int(sim.state.stage)<8:_text(tr("GATE_PROGRESS") % [count,gates.size()],18,Color(1,.86,.5))
    else:
        var killed:=0
        for g in stage.groups:
            if sim.state.run_kills.get(sim.catalog.groups[g].id,0)>0:killed+=1
        _text(tr("FINAL_CLEAR_PROGRESS") % killed,18,Color(1,.86,.5))
    _section(tr("SECTION_CAMPS"))
    var hidden:=0
    for i in range(stage.spawns.size()):
        if not sim.campaign.camp_known(i):
            hidden+=1
            continue
        _camp_row(i)
    if hidden>0:_text(tr("CAMPS_HIDDEN") % hidden,17,Color(.7,.75,.82))
    var map=preload("res://scripts/game/map_view.gd").new()
    map.sim=sim
    # Taller than Change 7 (300) so one marker per spot stays tappable on the largest stages.
    map.custom_minimum_size=Vector2(0,420)
    map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    map.selected.connect(func(g: int,v: int)->void:group=g;enemy_variant=v;enemy_tab=0;_open("enemy"))
    rows.add_child(map)
    if sim.level("map_detail",int(sim.state.stage))>=2:
        var known:=HFlowContainer.new()
        known.add_theme_constant_override("h_separation",8)
        rows.add_child(known)
        for g in stage.groups:
            if sim.campaign.discovered(g):
                var b:=_action(sim.catalog.groups[g].name,func()->void:group=g;enemy_variant=2;enemy_tab=0;_open("enemy"),true,"",known)
                b.size_flags_horizontal=0;b.custom_minimum_size=Vector2(0,56);b.add_theme_font_size_override("font_size",17)
    else:_text(tr("MAP_LEGEND"),17,Color(.7,.75,.82))
    if int(sim.state.unlocked_stage)>1:
        _section(tr("SECTION_TRAVEL"))
        for st in range(1,int(sim.state.unlocked_stage)+1):
            if st==int(sim.state.stage):continue
            var d: Dictionary=sim.catalog.stages[st-1]
            for i in sim.state.camps.get(str(st),[0]):
                var reason: String=sim.campaign.travel_reason(st,int(i))
                _action(tr("TRAVEL_CAMP") % [d.name,int(i)+1],func()->void:if sim.campaign.camp_action(st,int(i),true):world.follow_player();_close(),reason=="",reason)
    _section(tr("SECTION_MAP_UPGRADES"))
    for id in ["map_detail","reveal_radius"]:_group_upgrade_card(id,int(sim.state.stage))
    for i in sim.state.spawns:_group_upgrade_card("camp_radius",int(sim.state.stage)*10+int(i))

func _camp_row(i: int) -> void:
    var st:=int(sim.state.stage)
    var owned: bool=sim.state.spawns.has(i)
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    rows.add_child(card)
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",10)
    card.add_child(line)
    _card_icon(line,_art(249),Color.WHITE if owned else Color(.55,.55,.55))
    var text:=VBoxContainer.new()
    text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    line.add_child(text)
    _card_line(text,tr("CAMP_NAME") % (i+1),20,Color.WHITE)
    _card_line(text,_camp_status(st,i),17,Color(.6,1,.75) if owned else Color(1,.86,.5))
    if not owned:
        var buy:=_inline_button(tr("CAMP_UNLOCK"),func()->void:sim.select_spawn(i),sim.state.coins>=sim.campaign.camp_price(i),"NOT_ENOUGH_COINS",line,true)
        buy.set_meta("guide","camp_buy_%d" % i)
    else:
        if int(sim.state.spawn)!=i:
            _inline_button(tr("CAMP_SELECT"),func()->void:sim.select_spawn(i);_event("CAMP_SELECTED_NOTICE"),true,"",line,false).set_meta("guide","camp_select_%d" % i)
        var reason: String=sim.campaign.travel_reason(st,i)
        _inline_button(tr("CAMP_TRAVEL"),func()->void:if sim.campaign.camp_action(st,i,true):world.follow_player();_close(),reason=="",reason,line,false)

func _inline_button(text: String,callback: Callable,enabled: bool,reason: String,parent: Node,primary: bool) -> Button:
    var button:=Button.new()
    button.text=text
    button.custom_minimum_size=Vector2(118,76)
    var lock:=sim.action_lock_reason()
    button.disabled=not enabled or not lock.is_empty()
    button.tooltip_text=tr(lock if not lock.is_empty() else reason) if button.disabled else ""
    if primary and not button.disabled:button.theme_type_variation=&"Primary"
    button.add_theme_font_size_override("font_size",20)
    parent.add_child(button)
    button.pressed.connect(func()->void:
        callback.call()
        AudioService.play_sfx("button")
        if sheet.visible:_refresh_panel())
    return button

## A tapped camp in the world: unlock, select and travel stay separate actions.
func _camp_panel() -> void:
    _set_title(tr("CAMP_NAME") % (selected_camp+1))
    _text(tr("CAMP_HELP"),18,Color(.8,.84,.9))
    _camp_row(selected_camp)

# ---------------------------------------------------------------- stats, settings, history, inventory

## Stats, opened from Settings since Change 8: short sections of aligned name/value rows (effective
## values first, then what boosts them, then time), one value per row with its unit.
func _stats_panel() -> void:
    var s:=sim.stats()
    var defense: float=float(s.defense)
    _stat_section(tr("STATS_SECTION_CHARACTER"),[
        [tr("STATS_LEVEL"),tr("STATS_LEVEL_VALUE") % [sim.state.player_level,int(sim.catalog.progression.max_level)]],
        [tr("STATS_STAGE"),str(sim.campaign.stage().name)],
        [tr("STATS_PRESTIGES"),str(int(sim.state.prestiges))],
        [tr("STATS_CARDS"),"%d / %d" % [sim.state.owned_cards.size(),sim.catalog.campaign.cards.size()]]])
    _stat_section(tr("STATS_SECTION_OFFENSE"),[
        [tr("STAT_DAMAGE"),fmt(s.damage)],
        [tr("STAT_CRIT"),fmt_value(s.crit*100)+"%"],
        [tr("STAT_CRIT_DAMAGE"),"×"+fmt(s.crit_damage)],
        [tr("STATS_ATTACK_SPEED"),tr("STATS_ATTACK_SPEED_VALUE") % [fmt_value(1.0+s.speed),fmt_value(s.speed*100)]],
        [tr("STAT_LIFESTEAL"),fmt_value(s.lifesteal*100)+"%"]])
    _stat_section(tr("STATS_SECTION_DEFENSE"),[
        [tr("STAT_HP"),fmt_count(s.hp)],
        [tr("STAT_DEFENSE"),tr("STATS_DEFENSE_VALUE") % [fmt_value(defense),fmt_value(100.0*defense/(100.0+defense))] if defense>0 else "0"],
        [tr("STAT_REGEN"),fmt_value(s.regen)+" "+tr("HP_PER_SECOND")],
        [tr("STATS_RESPAWN"),tr("SECONDS_VALUE") % fmt_value(sim.player_upgrade_value("respawn"))]])
    var boosts: Array=[
        [tr("STATS_PRESTIGE_HP"),"×"+fmt_value(sim.card("hp"))],
        [tr("STATS_PRESTIGE_DAMAGE"),"×"+fmt_value(sim.card("damage"))],
        [tr("STATS_MOVEMENT"),"+"+fmt_value((sim.campaign.move_speed()/90.0-1.0)*100)+"%"],
        [tr("STATS_STORED_SHARE"),fmt_value(float(sim.catalog.progression.stored_weapon_factor)*100)+"%"]]
    if sim.campaign.bonus("equipped")>0:boosts.append([tr("STATS_EQUIPPED_BONUS"),"+"+fmt(sim.campaign.bonus("equipped")*100)+"%"])
    if sim.state.boost_time>0:boosts.append([tr("STAT_COIN_BONUS"),tr("STATS_TONIC_VALUE") % [fmt(float(sim.state.boost_power)*100),ceili(sim.state.boost_time)]])
    _stat_section(tr("STATS_SECTION_BOOSTS"),boosts)
    # What each source adds before multipliers and caps (playbook 17.2), damage and HP first.
    var sources: Array=[]
    for source in sim.stat_sources():
        var values: Dictionary=sim.stat_sources()[source]
        var parts: Array=[]
        for key in ["damage","hp","defense","crit","crit_damage","speed","lifesteal","regen"]:
            if absf(float(values.get(key,0.0)))>=.005:parts.append(_short_stat(key,float(values[key])))
        if not parts.is_empty():sources.append([tr(source),", ".join(parts)])
    _stat_section(tr("STAT_SOURCES"),sources)
    # Active play only (no pause, background, offline or prestige-choice time); see simulation.step.
    _stat_section(tr("STATS_SECTION_TIME"),[
        [tr("STATS_TIME_TOTAL"),fmt_duration(float(sim.state.get("playtime_total",0.0)))],
        [tr("STATS_TIME_RUN"),fmt_duration(float(sim.state.get("playtime_run",0.0)))]])
    _text(tr("STAT_CAPS_NOTE"),16,Color(.7,.75,.82))

## One stats card: a heading, then name (left, muted) and value (right, bright) per row.
func _stat_section(title: String,entries: Array) -> void:
    if entries.is_empty():return
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    rows.add_child(card)
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",4)
    card.add_child(box)
    var heading:=Label.new()
    heading.text=title
    heading.add_theme_font_size_override("font_size",18)
    heading.add_theme_color_override("font_color",Color(1,.86,.5))
    box.add_child(heading)
    var grid:=GridContainer.new()
    grid.columns=2
    grid.add_theme_constant_override("h_separation",16)
    grid.add_theme_constant_override("v_separation",2)
    box.add_child(grid)
    for entry in entries:
        var name_label:=Label.new()
        name_label.text=str(entry[0])
        name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        name_label.add_theme_font_size_override("font_size",18)
        name_label.add_theme_color_override("font_color",Color(.78,.82,.88))
        grid.add_child(name_label)
        var value:=Label.new()
        value.text=str(entry[1])
        value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
        value.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        value.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        value.add_theme_font_size_override("font_size",19)
        value.add_theme_color_override("font_color",Color.WHITE)
        grid.add_child(value)

## Compact contribution text: "+12.5 dmg", "+3% crit".
func _short_stat(key: String,value: float) -> String:
    if key in ["crit","lifesteal","speed"]:return "+%s%% %s" % [fmt(value*100),tr("STATS_SHORT_"+key.to_upper())]
    if key=="crit_damage":return "+%s%% %s" % [fmt(value*100),tr("STATS_SHORT_"+key.to_upper())]
    return "+%s %s" % [fmt(value),tr("STATS_SHORT_"+key.to_upper())]

## Compact Android-friendly duration: 2h 05m, 4m 09s, 37s.
static func fmt_duration(seconds: float) -> String:
    var total:=int(floorf(maxf(0,seconds)))
    var h:=total/3600;var m:=(total%3600)/60;var sec:=total%60
    if h>0:return "%dh %02dm" % [h,m]
    if m>0:return "%dm %02ds" % [m,sec]
    return "%ds" % sec

func _stat_text(key: String,value: float,bonus: bool=false) -> String:
    if key in ["crit","lifesteal","speed","coin_bonus"]:
        return "%s  %s%%" % [tr("STAT_"+key.to_upper()),fmt(value*100)]
    if key=="crit_damage":
        return ("%s  %s%%" % [tr("STAT_"+key.to_upper()),fmt(value*100)]) if bonus else ("%s  ×%s" % [tr("STAT_"+key.to_upper()),fmt(value)])
    return "%s  %s%s" % [tr("STAT_"+key.to_upper()),fmt(value)," "+tr("HP_PER_SECOND") if key=="regen" else ""]

func _settings_panel() -> void:
    var row:=HFlowContainer.new()
    row.add_theme_constant_override("h_separation",8)
    row.add_theme_constant_override("v_separation",8)
    rows.add_child(row)
    # Stats moved here from the navigation bar (Change 8); Player Upgrades took its place.
    _action(tr("STATS_OPEN"),func()->void:_open("stats"),true,"",row).set_meta("guide","open_stats")
    _action(tr("SOUND_STATUS") % tr("ON" if SettingsState.sfx_enabled else "OFF"),func()->void:SettingsState.sfx_enabled=not SettingsState.sfx_enabled;SettingsState.settings_changed.emit(),true,"",row)
    _action(tr("GUIDE_REVIEW"),func()->void:sim.state.tutorial.mode="pending";_close(),true,"",row)
    _action(tr("LOOT_HISTORY"),func()->void:_open("history"),true,"",row)
    _action(tr("SAVE_NOW"),func()->void:if SaveService.save_now():_event("SAVED"),true,"",row)
    for button in row.get_children():
        button.size_flags_horizontal=0;button.custom_minimum_size=Vector2(300,64)
    _section(tr("LANGUAGE_NOTE"))
    _action(tr("LANG_AUTOMATIC"),func()->void:LocalizationService.select_language("automatic"))
    for locale in LocalizationService.RELEASE_LANGUAGES:
        _action(tr("LANG_"+locale.to_upper()),func()->void:LocalizationService.select_language(locale),locale=="en_US")
    _section(tr("SECTION_DANGER"))
    _action(tr("HARD_RESET"),func()->void:_confirm(tr("RESET_CONFIRM"),func()->void:SaveService.hard_reset();_close()))
    _text(tr("CREDITS"),17,Color(.7,.75,.82))

func _history_panel() -> void:
    for entry in sim.state.history:
        var message:=_history_text(entry)
        if not message.is_empty():_text(message,20)

func _history_text(entry: Dictionary) -> String:
    if entry.key=="HISTORY_CURRENCY":
        return tr("HISTORY_CURRENCY") % fmt(entry.amount) if entry.amount>0 else ""
    return tr("HISTORY_ITEM") % [fmt_count(entry.amount),sim.catalog.display_name(entry.id)]

func _inventory_panel() -> void:
    _pinned_equipment()
    _tabs(["ALL_ITEMS","WEAPONS","OUTFITS","SKILLS"],inventory_filter,func(i: int)->void:inventory_filter=i;slot_signatures.clear();_refresh_slots())
    for id in sim.state.items:
        if sim.quantity(id)>0 and (inventory_filter==0 or sim.catalog.items[id].kind==["","weapon","outfit","skill"][inventory_filter]):
            var b:=_action("%s · ×%s · ^%d" % [sim.catalog.display_name(id),fmt_count(sim.quantity(id)),sim.record(id).merge],func()->void:selected=id;selected_slot=sim.state.supplies.find(id);_open("item"))
            b.icon=icon_cache.get(id);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",36)

## Equipped weapon and outfit, pinned above the list: independent of filter, order and scroll.
## They are views of the equipped ids (the list below still shows each item once).
func _pinned_equipment() -> void:
    var heading:=Label.new()
    heading.text=tr("EQUIPPED_PINNED")
    heading.add_theme_font_size_override("font_size",17)
    heading.add_theme_color_override("font_color",Color(.6,1,.75))
    pinned_rows.add_child(heading)
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",8)
    pinned_rows.add_child(line)
    for kind in ["weapon","outfit"]:
        var id: String=sim.state[kind]
        var button:=Button.new()
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.custom_minimum_size=Vector2(0,64)
        button.alignment=HORIZONTAL_ALIGNMENT_LEFT
        button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
        button.add_theme_font_size_override("font_size",17)
        button.text=(tr("EQUIPPED_WEAPON") if kind=="weapon" else tr("EQUIPPED_OUTFIT"))+"
"+(sim.catalog.display_name(id)+" ^%d" % int(sim.record(id).merge) if id!="" else tr("NOTHING_EQUIPPED_SHORT"))
        button.icon=icon_cache.get(id) if id!="" else null
        button.expand_icon=true
        button.add_theme_constant_override("icon_max_width",40)
        button.add_theme_stylebox_override("normal",_tier_style(id,false))
        button.disabled=id==""
        button.pressed.connect(func()->void:_open_equipped(kind))
        line.add_child(button)

## The explicit claim step for offline earnings. Nothing is paid, and no offline prestige
## opportunity is discovered, until Claim is pressed (campaign.claim_offline).
func _offline_panel() -> void:
    var pending: Dictionary=sim.state.offline_pending
    if pending.is_empty():
        _text(tr("OFFLINE_NOTHING"),18,Color(.75,.8,.87))
        return
    _set_title(tr("OFFLINE_WELCOME"),Color(1,.86,.5))
    _text(tr("OFFLINE_AWAY") % [fmt_duration(float(pending.seconds)),fmt(float(pending.rewarded_hours))],18,Color(.8,.84,.9))
    var reward:=HBoxContainer.new()
    reward.add_theme_constant_override("separation",8)
    rows.add_child(reward)
    for pair in [[COIN,float(pending.coins)],[GEM,float(pending.gems)]]:
        _card_icon(reward,pair[0],Color.WHITE,30)
        _card_line(reward,fmt_currency(pair[1]),22,Color(1,.88,.55))
    for id in pending.items:
        if sim.catalog.items.has(id):_loot_row(id,-1,int(pending.items[id]))
    _pinned(tr("OFFLINE_CLAIM"),func()->void:
        if sim.campaign.claim_offline():
            _close()
            _toast(tr("OFFLINE_CLAIMED")),true,"",true,"claim_offline")

# ---------------------------------------------------------------- missions

func _missions_panel() -> void:
    _section(tr("REGULAR_MISSIONS"))
    for i in range(sim.state.missions.size()):
        var m: Dictionary=sim.state.missions[i]
        var g: int=sim.campaign.group_id(str(m.target))
        var art: Texture2D=icon_cache.get(sim.catalog.groups[g].body) if g>=0 else _art(60)
        var ready: bool=not m.claimed and m.progress>=m.goal
        _task_card(art,tr("GOAL_"+str(m.kind).to_upper())+(" · "+sim.catalog.groups[g].name if g>=0 else ""),"%s / %s" % [fmt_count(m.progress),fmt_count(m.goal)],m.progress,m.goal,m.coins,m.gems,func()->void:sim.campaign.claim_mission(i),ready,"MISSION_NOT_READY",bool(m.claimed))
    _section(tr("MAIN_OBJECTIVES"))
    var shown:=0
    for i in range(16):
        if sim.state.main_claimed.has(i):continue
        if i==15 and not sim.state.final_discovered:continue
        if shown>=3:break
        shown+=1
        var rewards: Array=sim.catalog.campaign.main_rewards[i]
        var done: bool=sim.state.main_ready.has(str(i))
        _task_card(_art(211),tr("MAIN_%d" % i),tr("MISSION_STATE_READY") if done else tr("IN_PROGRESS"),1 if done else 0,1,rewards[0],rewards[1],func()->void:sim.campaign.claim_main(i),done,"MISSION_NOT_READY")
    # Claimed main objectives stay discoverable as a compact history.
    var claimed_main: Array=sim.state.main_claimed.duplicate()
    claimed_main.sort()
    if not claimed_main.is_empty():
        _action(tr("MAIN_COMPLETED_TOGGLE") % [claimed_main.size(),tr("HIDE" if show_completed_main else "SHOW")],func()->void:show_completed_main=not show_completed_main)
        if show_completed_main:
            for i in claimed_main:_text("✓ "+tr("MAIN_%d" % int(i)),17,Color(.5,1,.65))
    if sim.state.final_discovered:
        _text(tr("KEY_PROGRESS") % sim.state.keys.size(),18,Color(1,.86,.5))
        var keys:=HFlowContainer.new();rows.add_child(keys)
        for d in sim.catalog.groups:
            if d.boss and not d.final:_card_icon(keys,icon_cache.get(d.body),Color.WHITE if sim.state.keys.has(d.id) else Color(.3,.3,.35))
    _group_upgrade_card("mission_slots",-1)
    _group_upgrade_card("mission_claim",-1)
    if sim.level("mission_claim")>0:
        _game_action(tr("MISSION_AUTO") % tr("ON" if sim.state.mission_auto else "OFF"),func()->void:sim.state.mission_auto=not sim.state.mission_auto;sim.touch())

## Compact objective card: icon, title, progress bar with value, rewards and a claim button.
## States read at a glance: In progress (muted chip), Ready to claim (primary Claim button) and
## Claimed (dimmed card, green check, no button), so a claimed card never looks like a disabled claim.
func _task_card(art: Texture2D,title: String,value: String,progress: float,goal: float,coins: float,gems: float,claim: Callable,ready: bool,reason: String,claimed:=false) -> void:
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    if claimed:card.modulate=Color(1,1,1,.62)
    rows.add_child(card)
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",12)
    card.add_child(line)
    _card_icon(line,art)
    var text:=VBoxContainer.new()
    text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    text.add_theme_constant_override("separation",3)
    line.add_child(text)
    _card_line(text,("✓ " if claimed else "")+title,20,Color(.5,1,.65) if claimed else Color.WHITE)
    var bar:=ProgressBar.new()
    bar.theme_type_variation=&"XP"
    bar.custom_minimum_size=Vector2(0,16)
    bar.max_value=maxf(goal,1)
    bar.value=minf(progress,goal)
    bar.show_percentage=false
    text.add_child(bar)
    var reward:=HBoxContainer.new()
    reward.add_theme_constant_override("separation",6)
    text.add_child(reward)
    _card_line(reward,value,17,Color(.8,.84,.9))
    for pair in [[COIN,coins],[GEM,gems]]:
        if pair[1]<=0:continue
        _card_icon(reward,pair[0],Color.WHITE,24)
        _card_line(reward,fmt_currency(pair[1]),17,Color(1,.88,.55))
    if claimed:_card_line(text,tr("MISSION_WAIT_REFRESH"),16,Color(.7,.75,.82))
    if ready:
        var button:=_inline_button(tr("CLAIM"),claim,true,reason,line,true)
        button.custom_minimum_size=Vector2(112,76)
        return
    var chip:=Label.new()
    chip.text=tr("MISSION_STATE_CLAIMED") if claimed else tr("IN_PROGRESS")
    chip.custom_minimum_size=Vector2(112,76)
    chip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    chip.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    chip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    chip.add_theme_font_size_override("font_size",17)
    chip.add_theme_color_override("font_color",Color(.5,1,.65) if claimed else Color(.7,.75,.82))
    line.add_child(chip)

# ---------------------------------------------------------------- prestige

func _opportunity(id: String) -> Dictionary:
    for op in sim.catalog.campaign.opportunities:
        if op.id==id:return op
    return {}

func _path_cards(path: String) -> Array:
    var result: Array=[]
    for key in sim.catalog.campaign.cards:
        if sim.catalog.campaign.cards[key].path==path:result.append(key)
    result.sort()
    return result

func _path_art(path: String) -> Texture2D:
    return _art(int(sim.catalog.campaign.paths.get(path,{}).get("icon",211)))

func _card_node(id: String,state: String,compact:=false) -> Button:
    var node: Button=PRESTIGE_CARD.instantiate()
    node.compact=compact
    var d: Dictionary=sim.catalog.campaign.cards[id]
    node.setup(id,d,sim.catalog.campaign.paths.get(d.path,{}),state)
    if compact:node.custom_minimum_size=Vector2(150,190)
    return node

func _prestige_panel() -> void:
    var batch: Dictionary=sim.state.prestige_batch
    if not batch.is_empty():
        _prestige_choice(batch)
        return
    _mark_prestige_seen()
    var gate:=sim.campaign.prestige_gate_reason()
    # Only ready opportunities that can still award a card enter the batch (Change 8 gate).
    var ready:=sim.campaign.awardable_ids()
    _text(tr("PRESTIGE_INTRO"),18,Color(.8,.84,.9))
    if gate!="":
        _text(tr(gate),20,Color(1,.72,.45))
    elif sim.campaign.ready_ids().is_empty():
        _text(tr("NO_READY_PRESTIGE"),18,Color(1,.86,.5))
    elif ready.is_empty():
        _text(tr("NO_CARD_AVAILABLE"),18,Color(1,.86,.5))
    _text(tr("PRESTIGE_READY_COUNT") % [ready.size(),sim.state.owned_cards.size(),sim.catalog.campaign.cards.size()],20,Color(1,.86,.5))
    _pinned(tr("PRESTIGE_BATCH") % ready.size(),func()->void:_confirm(_prestige_summary(ready),func()->void:sim.campaign.begin_prestige()),sim.campaign.prestige_block_reason().is_empty(),sim.campaign.prestige_block_reason(),true,"begin_prestige")
    # Ready first, then in progress, then completed history.
    var order: Array=[]
    for state_rank in [0,1,2]:
        for op in sim.catalog.campaign.opportunities:
            if not sim.state.opportunities.has(op.id):continue
            var done: bool=sim.state.consumed.has(op.id)
            var is_ready: bool=sim.state.opportunities[op.id].ready and not done
            if (state_rank==0 and is_ready) or (state_rank==1 and not is_ready and not done) or (state_rank==2 and done):order.append(op)
    if order.is_empty():_text(tr("PRESTIGE_NONE_DISCOVERED"),18,Color(.75,.8,.87))
    for op in order:_opportunity_card(op)
    _section(tr("OWNED_CARDS"))
    if sim.state.owned_cards.is_empty():_text(tr("NO_CARDS_YET"),17,Color(.75,.8,.87))
    else:
        var grid:=HFlowContainer.new()
        grid.add_theme_constant_override("h_separation",8)
        grid.add_theme_constant_override("v_separation",8)
        rows.add_child(grid)
        for id in sim.state.owned_cards:grid.add_child(_card_node(id,"owned",true))
    _section(tr("COMBOS"))
    for c in sim.catalog.campaign.combos:
        var owned:=0
        for id in c.cards:
            if sim.state.owned_cards.has(id):owned+=1
        if owned==0:continue
        _text("%s  %d/3  ·  %s" % [tr("COMBO_"+str(c.id).to_upper()),owned,c.description],17,Color(.6,1,.75) if owned==3 else Color(.8,.84,.9))

func _opportunity_card(op: Dictionary) -> void:
    var o: Dictionary=sim.state.opportunities[op.id]
    var done: bool=sim.state.consumed.has(op.id)
    var ready: bool=o.ready and not done
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    rows.add_child(card)
    var content:=VBoxContainer.new()
    content.add_theme_constant_override("separation",6)
    card.add_child(content)
    var head:=HBoxContainer.new()
    head.add_theme_constant_override("separation",10)
    content.add_child(head)
    _card_icon(head,_path_art(str(op.path)))
    var text:=VBoxContainer.new()
    text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    head.add_child(text)
    _card_line(text,op.name+"  ·  "+tr("ACHIEVEMENT_DONE" if done else ("PRESTIGE_READY_SHORT" if ready else "IN_PROGRESS")),20,Color(.45,1,.55) if ready else (Color(.7,.75,.82) if done else Color.WHITE))
    _card_line(text,op.description,17,Color(.8,.84,.9))
    if not done and not ready:_card_line(text,sim.campaign.opportunity_progress(op.id),17,Color(1,.86,.5))
    if done:return
    var chips:=HBoxContainer.new()
    chips.add_theme_constant_override("separation",8)
    content.add_child(chips)
    for id in _path_cards(str(op.path)):
        var d: Dictionary=sim.catalog.campaign.cards[id]
        var owned: bool=sim.state.owned_cards.has(id)
        var chip:=Label.new()
        chip.text=("✓ " if owned else "")+d.name+" "+PRESTIGE_CARD_SCRIPT.headline(d)
        chip.add_theme_font_size_override("font_size",17)
        chip.add_theme_color_override("font_color",Color(.55,.58,.62) if owned else Color(Color(str(sim.catalog.campaign.paths.get(op.path,{}).get("color","ffffff"))).lightened(.45)))
        chip.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        chip.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
        chips.add_child(chip)
    var row:=HBoxContainer.new()
    row.add_theme_constant_override("separation",8)
    # A ready opportunity has nothing left to follow (the action layer refuses it too).
    if sim.campaign.can_follow(op.id) or sim.state.follow==op.id:
        var follow:=_inline_button(tr("UNFOLLOW" if sim.state.follow==op.id else "FOLLOW"),func()->void:sim.campaign.toggle_follow(op.id),true,"",row,false)
        follow.custom_minimum_size=Vector2(150,64)
    if op.path in ["offering","collection"] and not ready:
        _inline_button(tr("SUBMIT_CONTRACT"),func()->void:sim.campaign.submit(op.id),true,"",row,true).custom_minimum_size=Vector2(200,64)
    if row.get_child_count()>0:content.add_child(row)
    else:row.free()

func _mark_prestige_seen() -> void:
    var seen: Array=sim.state.tutorial.seen
    var changed:=false
    for id in sim.state.opportunities:
        var key:="op:"+str(id)+(":ready" if sim.state.opportunities[id].ready else "")
        if not seen.has(key):seen.append(key);changed=true
    if changed:SaveService.mark_dirty()

func _prestige_summary(ready: Array) -> String:
    var names: Array=[]
    for id in ready:names.append(_opportunity(id).name)
    return tr("PRESTIGE_CONFIRM_SUMMARY") % [ready.size(),", ".join(names)]

## The batch: one card per ready opportunity, chosen in order. Tap a card to select it, then keep it.
func _prestige_choice(batch: Dictionary) -> void:
    var index: int=batch.choices.size()
    var op: Dictionary=_opportunity(batch.ids[index])
    _set_title(tr("PRESTIGE_CHOOSE_TITLE") % [index+1,batch.ids.size()],Color(1,.86,.5))
    _text(op.name+"  ·  "+op.description,18,Color(.8,.84,.9))
    var offered: Array=sim.campaign.offered_cards()
    if not offered.has(selected_card):selected_card=""
    var row:=HBoxContainer.new()
    row.add_theme_constant_override("separation",10)
    rows.add_child(row)
    for id in offered:
        var node:=_card_node(id,"selected" if id==selected_card else "offered")
        node.set_meta("guide","card")
        node.pressed.connect(func()->void:selected_card=id;AudioService.play_sfx("button");_refresh_panel(true))
        row.add_child(node)
    var earned: Array=[]
    for id in batch.choices:earned.append(sim.catalog.campaign.cards[id].name)
    if not earned.is_empty():_text(tr("PRESTIGE_EARNED_SO_FAR") % ", ".join(earned),17,Color(.6,1,.75))
    _section(tr("PRESTIGE_KEEP_TITLE"))
    _text(tr("PRESTIGE_KEEP"),17,Color(.6,1,.75))
    _section(tr("PRESTIGE_RESET_TITLE"))
    _text(tr("PRESTIGE_RESET"),17,Color(1,.72,.45))
    if batch.choices.is_empty():
        _pinned(tr("CANCEL"),func()->void:sim.campaign.cancel_prestige();selected_card="",true,"",false,"",false)
    var card_name: String=sim.catalog.campaign.cards[selected_card].name if selected_card!="" else ""
    var last: bool=index==batch.ids.size()-1
    _pinned(tr("PRESTIGE_KEEP_CARD") % card_name if selected_card!="" else tr("PRESTIGE_PICK_CARD"),func()->void:
        var chosen:=selected_card
        _confirm(tr("PRESTIGE_CARD_CONFIRM_FINAL" if last else "PRESTIGE_CARD_CONFIRM") % sim.catalog.campaign.cards[chosen].name,func()->void:
            selected_card=""
            sim.prestige(chosen)),selected_card!="","PRESTIGE_PICK_CARD",true,"keep_card",false)

# ---------------------------------------------------------------- HUD helpers

func _refresh_badges() -> void:
    var nav: Node=dock.get_node("Navigation")
    var claimable: bool=not sim.state.main_ready.is_empty()
    for m in sim.state.missions:
        if not m.claimed and m.progress>=m.goal:claimable=true
    nav.get_node("Missions/Badge").visible=claimable
    var ready: bool=not sim.campaign.ready_ids().is_empty() or not sim.state.prestige_batch.is_empty()
    var unseen:=false
    for id in sim.state.opportunities:
        if not sim.state.consumed.has(id) and not sim.state.tutorial.seen.has("op:"+str(id)+(":ready" if sim.state.opportunities[id].ready else "")):unseen=true
    # The button itself names the reset gate while it applies (the panel has the full reason).
    var button: Button=nav.get_node("Prestige")
    var gated: bool=sim.campaign.prestige_gate_reason()!="" and sim.state.prestige_batch.is_empty()
    var label:=tr("NAV_PRESTIGE")+("\n"+tr("NAV_PRESTIGE_LOCKED") if gated else "")
    if button.text!=label:
        button.text=label
        button.add_theme_font_size_override("font_size",14 if gated else 17)
        button.add_theme_constant_override("icon_max_width",24 if gated else 34)
        if gated:button.add_theme_color_override("font_color",Color(1,.84,.55))
        else:button.remove_theme_color_override("font_color")
    var badge: Label=nav.get_node("Prestige/Badge")
    badge.visible=ready or unseen
    badge.text="!" if ready else "✦"
    badge.add_theme_color_override("font_color",Color(.45,1,.55) if ready else Color(1,.84,.34))

func _tier_color(id: String) -> Color:
    if id=="":
        return Color(.23,.26,.30)
    return Color(sim.catalog.progression.tier_colors[clampi(int(sim.catalog.items[id].tier)-1,0,6)])

func _card_line(parent: Control,text: String,font_size: int,color: Color) -> void:
    var label:=Label.new()
    label.text=text
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    parent.add_child(label)

func _card_icon(parent: Node,texture: Texture2D,tint:=Color.WHITE,side:=44) -> void:
    var icon:=TextureRect.new()
    icon.texture=texture
    icon.modulate=tint
    icon.custom_minimum_size=Vector2(side,side)
    icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
    parent.add_child(icon)

func _info_card(heading: String,body: String,texture: Texture2D) -> PanelContainer:
    var card: PanelContainer=INFO_CARD.instantiate()
    rows.add_child(card)
    card.get_node("Content/Header/Title").text=heading
    card.get_node("Content/Header/Icon").texture=texture
    card.get_node("Content/Body").text=body
    card.get_node("Content/Body").visible=body!=""
    return card

func _show_gem_pickup(amount: float) -> void:
    gem_pickup_amount=(gem_pickup_amount if gem_pickup_time>0 else 0)+amount
    gem_pickup_time=4.0
    $Safe/Layout/Map/GemPickup/Amount.text="+"+fmt(gem_pickup_amount)
    $Safe/Layout/Map/GemPickup.show()

## Recent finds, top-left, each on a dark backing so they stay readable on snow.
func _refresh_loot_notifications() -> void:
    var signature:=JSON.stringify(sim.state.history)
    if signature==history_signature:
        return
    history_signature=signature
    var container: VBoxContainer=$Safe/Layout/Map/History
    for child in container.get_children():
        container.remove_child(child)
        child.queue_free()
    var backing: StyleBox=theme.get_stylebox("panel","Backing")
    for entry in sim.state.history:
        if entry.key not in ["HISTORY_ITEM","HISTORY_CURRENCY"] or entry.amount<=0:
            continue
        var row:=Button.new()
        row.custom_minimum_size=Vector2(0,40)
        row.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
        row.alignment=HORIZONTAL_ALIGNMENT_LEFT
        row.add_theme_font_size_override("font_size",20)
        row.add_theme_constant_override("outline_size",5)
        row.add_theme_color_override("font_outline_color",Color(0,0,0,1))
        for state_name in ["normal","hover","pressed","focus"]:
            row.add_theme_stylebox_override(state_name,backing)
        row.icon=GEM if entry.key=="HISTORY_CURRENCY" else icon_cache.get(entry.id)
        row.expand_icon=false
        row.add_theme_constant_override("icon_max_width",30)
        row.add_theme_constant_override("h_separation",8)
        row.text="+"+(fmt(entry.amount) if entry.key=="HISTORY_CURRENCY" else fmt_count(entry.amount))
        row.tooltip_text=_history_text(entry)
        row.pressed.connect(func()->void:_open("history"))
        container.add_child(row)
        if container.get_child_count()==3:
            break
