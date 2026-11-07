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
## Within this many world units of a sighted camp, a View Camp button shows under the camp's name
## (Change 16; the camp panel no longer opens by itself on approach, Change 8).
@export var camp_open_radius:=64.0
## Prestige milestone banner: width cap and gap below the top safe-area edge.
@export var banner_max_width:=640.0
@export var banner_top_gap:=12.0
## Change 12: every sound assignment (music, gameplay and special cues) in one editable resource.
@export var audio_cues: AudioCueSet=preload("res://resources/game/audio_cues.tres")
const INFO_CARD=preload("res://scenes/game/info_card.tscn")
const PRESTIGE_CARD=preload("res://scenes/game/prestige_card.tscn")
const PRESTIGE_CARD_SCRIPT=preload("res://scripts/game/prestige_card.gd")
const ITEM_ART="res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-%d.png"
const ARROW=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-273.png")
const COIN=preload("res://resources/game/coin.tres")
const GEM=preload("res://resources/game/gem.tres")
const SLOT=preload("res://scenes/game/slot.tscn")
const ROW=preload("res://scenes/game/action_row.tscn")
## Change 10: outfit slot look per ^100 merge milestone (inspector-editable resource).
const OUTFIT_SLOT_STYLES: OutfitSlotStyles=preload("res://resources/game/outfit_slot_styles.tres")
const LANGUAGE_DROPDOWN:=preload("res://scripts/game/language_dropdown.gd")
## Change 41: community links, each defined once (Playbook 52).
const EXTERNAL_LINKS=preload("res://resources/game/external_links.tres")
## Values copied from a freshly built description into the live control of the same shape.
const SYNC_PROPERTIES:=["text","disabled","tooltip_text","value","max_value","texture","icon","modulate","self_modulate","visible","theme_type_variation"]
const PANEL_ALIASES:={"travel":"world","map":"world","inventory":"filters"}
## Inventory filter categories (index 0 shows everything); the dock grid and item browsing use them.
const FILTER_KINDS:=["","weapon","outfit","skill"]
const FILTER_TABS:=["ALL_ITEMS","WEAPONS","OUTFITS","SKILLS"]
## Panels a HUD control toggles: a second tap on the control closes its own panel.
const LEVEL_PANEL:="level"
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
## Only the active confirmation may finish its deferred layout. Never resize it per frame.
var confirm_generation:=0
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
## Farming Guide: 0 lists the maps, otherwise the stage whose entry is open.
var guide_stage:=0
## Camp the player currently stands in (-1 outside) and whether entering it still owes the panel.
var camp_inside:=-1
var camp_pending:=false
## Change 16: the camp whose View Camp button is showing (-1 when hidden).
var view_camp:=-1
## Last texts written to the Mastery chip, the Winter I objective and the mission tracker.
var mastery_text:=""
## Camp Teleport picker: the chosen destination as [stage, camp], or empty.
var teleport_target: Array=[]
## Last text written to the "Map Explored" chip above the minimap (written only when it changes).
var explored_text:=""
var gate_text:=""
## Map Mastery: 0 lists the maps, otherwise the stage whose page is open.
var mastery_stage:=0
var travel_stage:=1
## Change 15: panels that belong to a revealed system (campaign.onboarding). Every way into a panel
## goes through _open, so a hidden system cannot be reached from the minimap, the character, an
## enemy, a camp, the follow tracker or a banner either.
const PANEL_FEATURE:={"missions":"missions","enemy":"enemy","world":"world","camp":"world","teleport":"world","farming":"world","upgrades":"upgrades","filters":"upgrades","prestige":"prestige","mastery":"prestige"}
const MASTERY_ART:={"explore":249,"hunt":1,"research":60,"collect":147,"forge":211}

func _ready() -> void:
    sheet.z_index=10
    $Confirm.z_index=20
    $PrestigeConfirm.z_index=20
    $ReviewInvitation.z_index=20
    $Toast.z_index=25
    banner.z_index=15
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
    SettingsState.settings_changed.connect(_place_joystick)
    _place_joystick()
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
    # Change 10: the level / XP bar opens Player Level & Growth (a second tap closes it).
    top.get_node("Meters/XP/Open").pressed.connect(func()->void:_nav(LEVEL_PANEL))
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
    # Change 11: Filters sits next to the gear count and opens the filter panel directly.
    dock.get_node("Inventory/GearColumn/Head/Filters").pressed.connect(func()->void:_nav("filters"))
    var pinned: Node=dock.get_node("Inventory/GearColumn/Head/Equipped")
    for kind in ["Weapon","Outfit"]:
        pinned.get_node(kind).pressed.connect(func()->void:_open_equipped(kind.to_lower()))
    $Safe/Layout/Map/FollowTracker.gui_input.connect(func(event: InputEvent)->void:
        if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
            accept_event();_open("prestige"))
    # Change 16: the followed mission's tracker opens Missions; the Mastery chip opens the current
    # map's Mastery page; View Camp opens the camp the player stands at.
    $Safe/Layout/Map/MissionTracker.gui_input.connect(func(event: InputEvent)->void:
        if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
            accept_event();_open("missions"))
    $Safe/Layout/Map/Mastery.pressed.connect(func()->void:
        mastery_stage=int(sim.state.stage)
        _open("mastery"))
    $Safe/Layout/Map/ViewCamp.pressed.connect(func()->void:
        if view_camp>=0:
            selected_camp=view_camp
            _open("camp"))
    $PrestigeConfirm.confirmed.connect(func()->void:_confirmed(sim.campaign.begin_prestige()))
    $ReviewInvitation.review_pressed.connect(_review_open_store)
    $ReviewInvitation.later_pressed.connect(_review_later)
    $Safe/Layout/Map/ViewCamp.text=tr("VIEW_CAMP")
    $Safe/Layout/Map/Objective/Text.text=tr("OBJECTIVE_WINTER_BOSS")
    var objective_style: StyleBox=$Safe/Layout/Map/Objective.get_theme_stylebox("panel").duplicate()
    objective_style.content_margin_left=10;objective_style.content_margin_right=10
    objective_style.content_margin_top=8;objective_style.content_margin_bottom=8
    $Safe/Layout/Map/Objective.add_theme_stylebox_override("panel",objective_style)
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
        if kind in ["discovered","ready","card","prestiged","prestige_unlocked"]:_open("prestige")
        elif kind in ["mastery_map","mastery_game"]:mastery_stage=0;_open("mastery"))
    sim.event.connect(_event)
    SaveService.save_failed.connect(func(_reason: String)->void:_event("SAVE_ERROR"))
    get_viewport().size_changed.connect(_safe_area)
    # Change 25: a tracker first measured before its text wrapped reported a several-hundred-pixel
    # height for one HUD tick (covering the map); it is laid out again as soon as the wrap settles.
    for tracker in [$Safe/Layout/Map/FollowTracker,$Safe/Layout/Map/MissionTracker]:
        tracker.minimum_size_changed.connect(_layout_trackers,CONNECT_DEFERRED)
    $Safe/Layout/Map.resized.connect(func()->void:if sheet.visible:_layout_sheet())
    _safe_area()
    dock.get_node("Inventory").resized.connect(_layout_inventory)
    AudioService.configure(audio_cues)
    AudioService.play_music()
    sim.notice.connect(_notice)
    for i in range(3):
        $Safe/Layout/Skills.get_child(i).pressed.connect(func()->void:sim.campaign.cast(i))
    _refresh_slots()
    if not sim.state.prestige_batch.is_empty():_open("prestige")
    guide=preload("res://scripts/game/tutorial_guide.gd").new()
    guide.z_index=15
    add_child(guide);guide.setup(self)
    _refresh_reveal()
    # Change 16: no development notice on a profile reset (the internal load result stays for probes).
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
    if $Confirm.visible:_layout_confirm()

func _process(dt: float) -> void:
    # Change 35: the review invitation holds the world while it is open (and only then).
    sim.held=$ReviewInvitation.is_open()
    _offer_review(dt)
    gem_pickup_time=maxf(0,gem_pickup_time-dt)
    $Safe/Layout/Map/GemPickup.visible=gem_pickup_time>0
    world.update_camera()
    _update_skill_buttons()
    _update_supply_cooldowns()
    var keys:=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
    sim.movement=Vector2.ZERO if get_tree().paused or sim.suspended or modal_open() or sheet.visible else (stick_input if stick_input.length()>.1 else keys.limit_length())
    if stick_input.length()>.1 or keys.length()>.1:
        $Safe/Layout/Map/GestureSurface.cancel_gesture()
        world.follow_player()
    _update_toast(dt)
    _layout_banner()
    # The View Camp button follows the camp on screen every frame (camera moves and pans).
    _refresh_view_camp()
    banner.held=sheet.visible or modal_open() or not sim.state.prestige_batch.is_empty() or sim.state.tutorial.mode=="pending"
    if settle_frames>0:
        settle_frames-=1
        _layout_sheet()
        if settle_frames==0:sheet.modulate.a=1.0
    panel_clock+=dt
    # Stats (playtime) and an item panel while a supply timer runs also tick without state revisions.
    var ticking: bool=panel=="stats" or (panel=="item" and (sim.state.boost_time>0 or not sim.state.buffs.is_empty() or sim.state.use_cd>0))
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
    var capped: bool=int(sim.state.player_level)>=sim.max_level()
    top.get_node("Meters/XP").value=100.0 if capped else 100.0*sim.state.xp/sim.xp_required()
    top.get_node("Meters/XP/Text").text=tr("HUD_LEVEL") % [sim.state.player_level,tr("VALUE_MAX") if capped else tr("XP_PROGRESS") % [fmt_count(sim.state.xp),fmt_count(sim.xp_required())]]
    if sim.state.boost_time>0:top.get_node("Meters/XP/Text").text+="  "+tr("BOOST_ACTIVE") % int(ceil(sim.state.boost_time))
    # A quiet hint that the bar opens Player Level & Growth.
    top.get_node("Meters/XP/Text").text+="  ›"
    _refresh_reveal()
    _refresh_combat_achievement()
    _refresh_loot_notifications()
    _refresh_badges()
    _refresh_follow_tracker()
    _refresh_mission_tracker()
    _layout_trackers()
    _refresh_explored()
    _refresh_mastery_chip()
    _refresh_gate()
    _refresh_objective()
    _offer_offline_claim()
    if last_revision!=sim.revision or previous_pause!=get_tree().paused:
        last_revision=sim.revision
        _refresh_slots()
    else:
        # Cheap when nothing changed; follows a resized dock without waiting for a state change.
        _layout_inventory()
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

## A confirmation is in front of the game (the ordinary one, the Prestige confirmation or, since
## Change 35, the review invitation).
func modal_open() -> bool:
    return $Confirm.visible or $PrestigeConfirm.visible or $ReviewInvitation.is_open()

## Change 35: the review invitation (review_invitation.gd owns its state and the world-side rules).
## Once pending on a build with a configured storefront, it waits for a quiet moment: the world safe
## (review.world_block_reason) and nothing on screen asking for attention (_review_ui_block), both
## continuously for ReviewRules.safe_seconds. Any interruption restarts that count; nothing is shown
## or spent while waiting. review_block names the current reason for probes.
var review_safe:=0.0
var review_block:=""
func _offer_review(dt: float) -> void:
    var review=sim.campaign.review
    if $ReviewInvitation.is_open() or not review.wanted():
        review_safe=0.0;review_block="" if $ReviewInvitation.is_open() else ("resolved" if review.resolved() else ("channel" if review.status()=="pending" else "time"))
        return
    review_block=review.world_block_reason()
    if review_block=="":review_block=_review_ui_block()
    if review_block!="":
        review_safe=0.0;return
    review_safe+=dt
    if review_safe>=float(review.rules.safe_seconds):
        review_safe=0.0
        open_review()

## Surfaces that must never be covered by the invitation: any panel or confirmation, a banner on
## screen or queued, the guide's cards and chooser, and the player's own touch on the joystick or map.
func _review_ui_block() -> String:
    if sheet.visible:return "panel"
    if modal_open():return "modal"
    if banner.visible or not banner.current.is_empty() or not banner.queue.is_empty():return "announcement"
    if guide.card.visible or guide.chooser.visible:return "guide"
    if stick_input.length()>.1 or not $Safe/Layout/Map/GestureSurface.pointers.is_empty():return "input"
    return ""

func open_review() -> void:
    var review=sim.campaign.review
    var store: String=review.channel()
    if store=="":return
    $Safe/Layout/Map/GestureSurface.cancel_gesture()
    stick.release();stick_input=Vector2.ZERO
    sim.movement=Vector2.ZERO;sim.held=true
    $ReviewInvitation.open(tr(review.channels.cta(store)),_review_loot())

## The accent row: the player's own equipped weapon and outfit (else the first ones in the catalog)
## around a Coin and a Gem.
func _review_loot() -> Array:
    var gear: Array=[]
    for kind in ["weapon","outfit"]:
        var id: String=str(sim.state[kind])
        if id=="":
            for item in sim.catalog.items:
                if sim.catalog.items[item].kind==kind:id=item;break
        gear.append(icon_cache.get(id))
    return [gear[0],COIN,GEM,gear[1]].filter(func(t):return t!=null)

func _review_open_store() -> void:
    if sim.campaign.review.open_store():
        $ReviewInvitation.close();sim.held=false
        AudioService.play("ui_confirm")
    else:
        $ReviewInvitation.show_error(tr("REVIEW_OPEN_FAILED"))

func _review_later() -> void:
    sim.campaign.review.dismiss()
    $ReviewInvitation.close();sim.held=false
    AudioService.play("ui_click")

## Change 16: walking up to a camp no longer opens its panel. While the living player stands within
## camp_open_radius of a sighted camp (World revealed), a View Camp button sits just under the camp's
## name on screen and opens that camp. Tapping the camp itself still opens it as before. Hidden under
## a panel, a confirmation, a Prestige choice and the guide chooser.
func _refresh_view_camp() -> void:
    var button: Button=$Safe/Layout/Map/ViewCamp
    var here:=_camp_at_player()
    var show: bool=here>=0 and revealed("world") and not sheet.visible and not modal_open() and sim.state.prestige_batch.is_empty() and sim.state.tutorial.mode!="pending"
    var at:=_camp_label_point(here) if show else Vector2.INF
    show=show and at!=Vector2.INF
    view_camp=here if show else -1
    if button.visible!=show:button.visible=show
    if not show:return
    var map: Control=$Safe/Layout/Map
    var pos:=Vector2(at.x-button.size.x*.5,at.y+4)
    pos=pos.clamp(Vector2(8,8),map.size-button.size-Vector2(8,8))
    if not button.position.is_equal_approx(pos):button.position=pos

## The bottom centre of a camp's name label, in Map coordinates (INF when the stage art is missing).
func _camp_label_point(i: int) -> Vector2:
    if world.scenery==null or i<0:return Vector2.INF
    var camp: Node=world.scenery.get_node_or_null("Camps/Camp%d" % i)
    if camp==null:return Vector2.INF
    var rect: Rect2=(camp.get_node("Label") as Control).get_global_rect()
    var screen: Vector2=world.get_canvas_transform()*Vector2(rect.get_center().x,rect.end.y)
    return screen*$Safe/Layout/Map.size/Vector2(world.get_viewport_rect().size)

## Change 16: the followed mission (or main objective) in the bottom-right corner: its name, what to
## do with progress, and "Ready" in green once a Claim waits. A tap opens Missions.
func _refresh_mission_tracker() -> void:
    var tracker: Control=$Safe/Layout/Map/MissionTracker
    var f: Dictionary=sim.campaign.followed_mission()
    var show: bool=not f.is_empty() and revealed("missions") and sim.state.prestige_batch.is_empty()
    if tracker.visible!=show:tracker.visible=show
    if not show:return
    var title:="";var art: Texture2D=_art(211);var ready:=false
    if f.kind=="main":
        title=tr("MAIN_%d" % int(f.index))
        ready=sim.campaign.main_claimable(int(f.index))
    else:
        var m: Dictionary=sim.state.missions[int(f.index)]
        var g:=sim.campaign.group_id(str(m.target))
        title=tr("GOAL_"+str(m.kind).to_upper())+(" · "+sim.catalog.groups[g].name if g>=0 else "")
        art=icon_cache.get(sim.catalog.groups[g].body) if g>=0 else _art(60)
        ready=m.progress>=m.goal
    var name_label: Label=tracker.get_node("Row/Text/Name")
    if name_label.text!=title:name_label.text=title
    var step: Label=tracker.get_node("Row/Text/Step")
    var text: String=sim.campaign.mission_follow_summary()
    if step.text!=text:step.text=text
    var color:=Color(.45,1,.55) if ready else Color(.94,.95,.97)
    if step.get_theme_color("font_color")!=color:step.add_theme_color_override("font_color",color)
    var icon: TextureRect=tracker.get_node("Row/Icon")
    if icon.texture!=art:icon.texture=art
    if tracker.mouse_filter!=Control.MOUSE_FILTER_STOP:tracker.mouse_filter=Control.MOUSE_FILTER_STOP

## Trackers grow upward just above the joystick, with mission above Prestige.
func _layout_trackers() -> void:
    var map: Control=$Safe/Layout/Map
    var joystick: Control=$Safe/Layout/Map/Joystick
    var y: float=joystick.position.y-12
    var width:=minf(360,map.size.x-32)
    for tracker in [$Safe/Layout/Map/FollowTracker,$Safe/Layout/Map/MissionTracker]:
        if not tracker.visible:continue
        tracker.set_anchors_preset(Control.PRESET_TOP_LEFT)
        var wanted:=Vector2(width,tracker.get_combined_minimum_size().y)
        if not tracker.size.is_equal_approx(wanted):tracker.size=wanted
        y-=tracker.size.y
        if not tracker.position.is_equal_approx(Vector2(16,y)):tracker.position=Vector2(16,y)
        y-=10

## Change 16: a compact Map Mastery summary for the current map above Map Explored ("Mastery 34% ·
## 2/5"); a tap opens that map's Mastery page. It comes with Map Mastery (revealed with Prestige).
func _refresh_mastery_chip() -> void:
    var chip: Button=$Safe/Layout/Map/Mastery
    var show: bool=revealed("prestige") and revealed("world")
    if chip.visible!=show:chip.visible=show
    if not show:return
    var st:=int(sim.state.stage)
    var m=sim.campaign.mastery
    var done:=0
    for category in m.CATEGORIES:
        if m.category_complete(st,category):done+=1
    var text:=tr("MASTERY_CHIP") % [m.map_percent(st),done,m.CATEGORIES.size()]
    if text!=mastery_text:
        mastery_text=text
        chip.text=text
        # Localization Batch 01: "Meisterschaft 34 % · 2/5" steps its font down rather than losing the count.
        var room: float=chip.size.x-chip.get_theme_stylebox("normal").get_minimum_size().x-chip.get_theme_constant("icon_max_width")-chip.get_theme_constant("h_separation")-4
        chip.add_theme_font_size_override("font_size",_fitting_font_size(text,room,17,13))

## Change 16: on Winter I, until the Snowman has been defeated once, a persistent objective sits in
## the map cluster: "KEEP FARMING UNTIL YOU CAN BEAT THE BOSS TO ADVANCE." Under the Next Stage chip
## when that shows, else in the cluster's first free place; it never takes touches.
func _refresh_objective() -> void:
    var node: Control=$Safe/Layout/Map/Objective
    var show: bool=int(sim.state.stage)==1 and sim.campaign.prestige_unlocked() and not sim.campaign.first_boss_defeated() and sim.state.tutorial.mode!="pending" and (sim.state.tutorial.mode!="guided" or sim.state.tutorial.seen.has("boss_preparation"))
    if node.visible!=show:node.visible=show
    var gate: Control=$Safe/Layout/Map/Gate
    var start: float=$Safe/Layout/Map/MiniMap.offset_bottom+8.0
    if show:
        node.offset_top=start
        node.offset_bottom=start+node.get_combined_minimum_size().y
    gate.offset_top=(node.offset_bottom+6.0) if show else start
    gate.offset_bottom=gate.offset_top+gate.get_combined_minimum_size().y

func _open_equipped(kind: String) -> void:
    var id: String=sim.state[kind]
    if id=="":
        _say(tr("NOTHING_EQUIPPED"))
        return
    selected=id
    selected_slot=-1
    _open("item")

## Followed Prestige opportunity above the joystick (Change 21): name, icon and
## what to do next with progress (campaign.follow_summary).
func _refresh_follow_tracker() -> void:
    var tracker: Control=$Safe/Layout/Map/FollowTracker
    var id: String=str(sim.state.follow)
    var o: Dictionary=sim.state.opportunities.get(id,{})
    var ready: bool=not o.is_empty() and bool(o.ready) and not sim.state.consumed.has(id)
    var show: bool=id!="" and not o.is_empty() and not sim.state.consumed.has(id) and sim.state.prestige_batch.is_empty() and revealed("prestige")
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
    # Change 16: the exact item a collection still needs, or the enemy the step names, else path art.
    var focus: Dictionary=sim.campaign.follow_focus(id)
    var art: Texture2D=_path_art(str(op.path))
    if focus.has("item"):art=icon_cache.get(focus.item)
    elif focus.has("group") and int(focus.group)>=0:art=icon_cache.get(sim.catalog.groups[int(focus.group)].body,art)
    if icon.texture!=art:icon.texture=art
    if tracker.mouse_filter!=Control.MOUSE_FILTER_STOP:tracker.mouse_filter=Control.MOUSE_FILTER_STOP

## Map cluster (Change 14: zoom, Map Explored, minimap, Next Stage, top right): the current map's
## permanently explored share, from the same saved cells and fog grid as World and the Regional
## opportunities (campaign.explored_percent). Reading the explored-cell count is O(1); the chip is
## written only when the text changes.
func _refresh_explored() -> void:
    var text: String=tr("MAP_EXPLORED") % sim.campaign.explored_percent(int(sim.state.stage))
    if text!=explored_text:
        explored_text=text
        $Safe/Layout/Map/Explored.text=text

## Change 13: what opens the next map, under the minimap: "Next Stage · Bosses 1/2" from the same
## state as the unlock rule (campaign.gate_status), or "World clear · 4/9" on Spring II. Hidden when
## nothing is pending (an earlier map, or the next map already open). It names no boss, so it spoils
## nothing; discovered required bosses carry the same banner on the map and in the world. Never takes
## touches; written only when the text changes. Change 14: a dark HudChip plate keeps it readable over
## snow, sand, fog and rain.
func _refresh_gate() -> void:
    var status: Dictionary=sim.campaign.gate_status()
    var text:=""
    # Change 15: the chip is the Defeat the Snowman objective, shown once that objective is revealed.
    if not status.is_empty() and revealed("objective"):
        text=tr("GATE_HUD_WORLD" if status.kind=="world" else "GATE_HUD") % [int(status.killed),int(status.total)]
    if text==gate_text:return
    gate_text=text
    var node: Control=$Safe/Layout/Map/Gate
    node.visible=text!=""
    node.get_node("Row/Label").text=text

## Offline earnings are claimed in game: offer the claim once per settlement, when nothing else
## (a panel, a confirmation, the guide chooser or a prestige choice) is in front of the player.
func _offer_offline_claim() -> void:
    var pending_id: String=str(sim.state.offline_pending.get("id",""))
    if pending_id=="" or pending_id==offline_prompted or sheet.visible or $Confirm.visible or $ReviewInvitation.is_open():return
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
            disabled=not sim.campaign.skill_cast_block_reason(i).is_empty()
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

## Coins and Gems held or earned (balances, rewards, rates): the shared currency format, rounded
## down so the screen never shows more than the player has or gets (Change 13, NumberFormat.currency).
func fmt_currency(value: float) -> String:
    return NumberFormat.currency(value)

## A Coin or Gem price, or an amount still needed: the same format, rounded up.
func fmt_cost(value: float) -> String:
    return NumberFormat.currency(value,true)

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
            var shown: bool=type==1 or inventory_filter==0 or (id!="" and sim.catalog.items[id].kind==FILTER_KINDS[inventory_filter])
            var signature:="%s|%d|%d|%s|%s|%s" % [id,sim.quantity(id),sim.merge_level(id),badge,shown,panel=="item" and selected==id]
            if slot_signatures.get(node.get_instance_id(),"")==signature:continue
            slot_signatures[node.get_instance_id()]=signature
            node.get_node("Icon").texture=icon_cache.get(id)
            node.get_node("Count").text=tr("EMPTY_SLOT") if id=="" else "%s · ^%d" % [fmt_count(sim.quantity(id)),sim.merge_level(id)]
            node.get_node("Badge").text=badge
            node.add_theme_stylebox_override("normal",_tier_style(id,panel=="item" and selected==id))
            node.add_theme_stylebox_override("hover",_tier_style(id,true))
            _apply_milestone_frame(node,id)
            var rank:=_milestone_rank(id)
            if rank>0:node.get_node("Count").add_theme_color_override("font_color",OUTFIT_SLOT_STYLES.frame_color(rank))
            else:node.get_node("Count").remove_theme_color_override("font_color")
            node.tooltip_text=sim.catalog.display_name(id) if id!="" else tr("EMPTY_SLOT")
            node.visible=shown
    _layout_inventory()
    var heading:=tr("HUD_GEAR") % [sim.state.gear.size()-sim.state.gear.count(""),sim.state.gear.size()]
    if sim.state.gear.size()>=sim.equipment_slot_max():heading+=" · "+tr("UPGRADE_MAX")
    dock.get_node("Inventory/GearColumn/Head/Heading").text=heading
    # Pinned equipped weapon and outfit: views of the equipped ids, never extra inventory entries.
    for kind in ["weapon","outfit"]:
        var button: Button=dock.get_node("Inventory/GearColumn/Head/Equipped/"+kind.capitalize())
        var id: String=sim.state[kind]
        # Change 24: rewritten only when what it shows changes (not on every kill).
        var shown:="%s|%s|%d|%s" % [id,panel=="item" and selected==id and id!="",_milestone_rank(id),TranslationServer.get_locale()]
        if button.get_meta("slot_signature","")==shown:continue
        button.set_meta("slot_signature",shown)
        button.icon=icon_cache.get(id) if id!="" else null
        button.text="" if id!="" else "—"
        button.tooltip_text=(tr("EQUIPPED_WEAPON" if kind=="weapon" else "EQUIPPED_OUTFIT")+": "+(sim.catalog.display_name(id) if id!="" else tr("NOTHING_EQUIPPED_SHORT")))
        button.add_theme_stylebox_override("normal",_tier_style(id,panel=="item" and selected==id and id!=""))
        _apply_milestone_frame(button,id)
    dock.get_node("Inventory/SupplyColumn/SupplyHeading").text=tr("HUD_SUPPLIES") % [sim.state.supplies.size()-sim.state.supplies.count(""),sim.state.supplies.size()]
    _sync_filter_button()

## The dock's Filters shortcut shows whether the panel is open and which category it shows.
func _sync_filter_button() -> void:
    var button: Button=dock.get_node("Inventory/GearColumn/Head/Filters")
    var open: bool=sheet.visible and panel=="filters"
    var text:=tr("FILTERS_ACTIVE") % tr(FILTER_TABS[inventory_filter]) if open and inventory_filter>0 else tr("FILTERS")
    if button.text!=text:button.text=text
    var variation:=&"Primary" if open else &""
    if button.theme_type_variation!=variation:button.theme_type_variation=variation

## Change 11: filters last only while the Filters panel is open. Every close path (X, Back, the
## shortcut again, opening another panel, programmatic closes) ends here, so the dock always
## returns to the full inventory. Nothing else changes: items, counts, slots and equipment stay.
func _clear_filters() -> void:
    if inventory_filter==0:return
    inventory_filter=0
    slot_signatures.clear()
    _refresh_slots()

## One cached style per tier color, outfit milestone rank and highlight state; slots never duplicate
## styles per refresh. A milestone lifts the tier colour slightly (its hue stays the tier's).
func _tier_style(id: String,highlight: bool) -> StyleBoxTexture:
    var rank:=_milestone_rank(id)
    var key:="%s:%d:%s" % [_tier_color(id).to_html(),rank,highlight]
    if not tier_styles.has(key):
        var style: StyleBoxTexture=theme.get_stylebox("normal","Slot").duplicate()
        var base:=_tier_color(id).lightened(OUTFIT_SLOT_STYLES.lift(rank))
        style.modulate_color=base.lightened(.22) if highlight else base
        tier_styles[key]=style
    return tier_styles[key]

## Change 10: an outfit's ^100 milestone rank (0-5) decides its slot treatment; other items are 0.
func _milestone_rank(id: String) -> int:
    if id=="" or not sim.catalog.items.has(id) or str(sim.catalog.items[id].kind)!="outfit":return 0
    return OUTFIT_SLOT_STYLES.rank(int(sim.state.items.get(id,{}).get("merge",0)))

## Shows the milestone frame over any slot-like control (a Button or Panel child named MilestoneFrame;
## created on first need, hidden at rank 0). The equipped/selected states stay on the background.
func _apply_milestone_frame(node: Control,id: String) -> void:
    var rank:=_milestone_rank(id)
    var frame: NinePatchRect=node.get_node_or_null("MilestoneFrame")
    if frame==null:
        if rank==0:return
        frame=NinePatchRect.new()
        frame.name="MilestoneFrame"
        node.add_child(frame)
    OUTFIT_SLOT_STYLES.apply(frame,rank)

## Change 41: the joystick follows Settings → Joystick position at once (Left / Center / Right).
func _place_joystick() -> void:
    if stick.slot!=SettingsState.joystick_position or stick.anchor_left!=[0.0,.5,1.0][stick.slot]:
        stick.place(SettingsState.joystick_position)

## Change 41: Left / Center / Right, highlighted like the slot sizes; applied and saved at once.
func _joystick_controls() -> void:
    _section(tr("JOYSTICK_POSITION"))
    var row:=HBoxContainer.new()
    rows.add_child(row)
    for i in range(3):
        var button:=_action(tr(["JOYSTICK_LEFT","JOYSTICK_CENTER","JOYSTICK_RIGHT"][i]),func()->void:SettingsState.set_joystick_position(i);panel_revision=-1,true,"",row)
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.theme_type_variation=&"Primary" if i==SettingsState.joystick_position else &""
        button.set_meta("guide","joystick_%s" % stick.POSITIONS[i])

func _inventory_zoom_controls() -> void:
    _section(tr("INVENTORY_ZOOM"))
    var row:=HBoxContainer.new()
    rows.add_child(row)
    for i in range(3):
        var button:=_action(tr(["SLOT_SMALL","SLOT_MEDIUM","SLOT_LARGE"][i]),func()->void:SettingsState.set_inventory_zoom(i);_layout_inventory();panel_revision=-1,true,"",row)
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.theme_type_variation=&"Primary" if i==SettingsState.inventory_zoom else &""
        button.set_meta("guide","inventory_zoom_%d" % i)

## Change 24 (PERF-04): the slot sizes, offsets and font overrides depend only on the column widths,
## the zoom, the slot counts, the heading height and the grid gap. They are rewritten when one of
## those changes, not on every inventory refresh (each override write re-themes a slot).
var inventory_layout_key:=""
func _layout_inventory() -> void:
    var inventory: Control=dock.get_node("Inventory")
    var gear_width: float=inventory.get_node("GearColumn/GearScroll").size.x
    var supply_width: float=inventory.get_node("SupplyColumn/SupplyScroll").size.x
    if gear_width<48 or supply_width<48:return # wait for the containers to receive their first layout
    var head: Control=inventory.get_node("GearColumn/Head")
    var gap: int=inventory.get_node("GearColumn/GearScroll/Gear").get_theme_constant("h_separation")
    var key:="%s|%s|%d|%d|%d|%s|%d" % [gear_width,supply_width,SettingsState.inventory_zoom,inventory.get_node("GearColumn/GearScroll/Gear").get_child_count(),inventory.get_node("SupplyColumn/SupplyScroll/Supplies").get_child_count(),head.get_combined_minimum_size().y,gap]
    if key==inventory_layout_key:return
    inventory_layout_key=key
    inventory.get_node("SupplyColumn/SupplyHeading").custom_minimum_size.y=head.get_combined_minimum_size().y
    var large:=maxf(48,floorf((gear_width-12-2*gap)/3.0))
    var desired: int=[6,4,3][SettingsState.inventory_zoom]
    var gear_side:=maxf(48,floorf((gear_width-18-(desired-1)*gap)/desired))
    for path in ["GearColumn/GearScroll/Gear","SupplyColumn/SupplyScroll/Supplies"]:
        var grid: GridContainer=inventory.get_node(path)
        var width: float=gear_width if path.begins_with("Gear") else supply_width
        var side: float=gear_side
        if path.begins_with("Supply"):
            var columns: int=[3,2,1][SettingsState.inventory_zoom]
            side=floorf((width-18-(columns-1)*gap)/columns)
            grid.columns=columns
        else:
            grid.columns=maxi(1,floori((width-18+gap)/(side+gap)))
        for slot in grid.get_children():
            slot.custom_minimum_size=Vector2(side,side)
            var ratio:=side/100.0
            var icon: Control=slot.get_node("Icon")
            icon.offset_left=20*ratio;icon.offset_top=24*ratio;icon.offset_right=-20*ratio;icon.offset_bottom=-32*ratio
            for pair in [["Count",17],["Badge",15],["Cooldown",26]]:
                slot.get_node(pair[0]).add_theme_font_size_override("font_size",maxi(10,roundi(pair[1]*ratio)))
            var count: Control=slot.get_node("Count")
            count.offset_top=-28*ratio;count.offset_bottom=-4*ratio
            slot.get_node("Badge").offset_bottom=24*ratio
    # Zoom changes the grid density, never the enclosing dock or its scrolling viewport.
    for path in ["GearColumn/GearScroll","SupplyColumn/SupplyScroll"]:
        inventory.get_node(path).custom_minimum_size.y=maxf(large+12,supply_width-18)

func _update_supply_cooldowns() -> void:
    var slots=dock.get_node("Inventory/SupplyColumn/SupplyScroll/Supplies")
    for i in range(mini(slots.get_child_count(),sim.state.supplies.size())):
        var node=slots.get_child(i)
        var id: String=sim.state.supplies[i]
        var cooling: bool=id!="" and str(sim.supply(id).get("effect",""))=="heal" and sim.state.use_cd>0
        # A running buff shows its remaining time on its own slot (gold, icon not dimmed).
        var left: float=sim.buff_time(id) if id!="" else 0.0
        var boosting: bool=left>0
        var text:=tr("SECONDS_VALUE") % fmt(sim.state.use_cd) if cooling else (tr("SECONDS_VALUE") % str(ceili(left)) if boosting else "")
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
    if sim.use_item(sim.state.supplies[index]):SaveService.mark_committed()
    _refresh_slots()

func _select_slot(type: int,index: int) -> void:
    selected_slot=index if type==1 else -1
    selected=sim.state.supplies[index] if type==1 else sim.state.gear[index]
    _open("item")

## A navigation button toggles its own panel: tapping the open one closes it, another switches.
func _nav(which: String) -> void:
    if sheet.visible and panel==PANEL_ALIASES.get(which,which):
        _close()
        AudioService.play("ui_click")
        return
    # Change 10: Prestige always opens; only the reset action inside the panel is gated.
    _open(which)

func revealed(feature: String) -> bool:
    return sim.campaign.onboarding.revealed(feature)

func panel_allowed(which: String) -> bool:
    which=PANEL_ALIASES.get(which,which)
    # A Prestige choice in progress always owns its panel.
    if which=="prestige" and not sim.state.prestige_batch.is_empty():return true
    return not PANEL_FEATURE.has(which) or revealed(PANEL_FEATURE[which])

## A revealed menu not opened yet carries the gold ✦ on its button (every mode: a status, not a hint).
func unopened(feature: String) -> bool:
    return revealed(feature) and not sim.state.tutorial.seen.has("opened:"+feature)

func _open(which: String) -> void:
    which=PANEL_ALIASES.get(which,which)
    if not panel_allowed(which):return
    var feature: String=PANEL_FEATURE.get(which,"")
    if feature!="" and not sim.state.tutorial.seen.has("opened:"+feature):
        sim.state.tutorial.seen.append("opened:"+feature);SaveService.mark_dirty()
    if panel=="filters" and which!="filters":_clear_filters()
    $Safe/Layout/Map/GestureSurface.cancel_gesture()
    var reopening: bool=sheet.visible and panel==which
    panel=which
    notice.text=""
    stick.release()
    if not reopening:
        $Sheet/Margin/Content/Scroll.scroll_vertical=0
        # Change 24: reopening the panel closed last reconciles its retained controls (same context:
        # only changed values are written) instead of building, adding and laying out every row.
        if not sheet.visible and which==retained_panel:panel_context=retained_context
        sheet.modulate.a=0.0 if not sheet.visible else 1.0
    retained_panel=""
    _set_panel_processing(true)
    sheet.show()
    _refresh_panel(true)
    _sync_filter_button()
    AudioService.play("ui_click")

## Change 24 (PERF-05): the last closed panel's controls stay hidden inside the sheet, with their
## processing paused, until the same panel reopens (reconciled) or another opens (replaced, as
## before). At most one panel is retained, so the node count stays bounded.
var retained_panel:=""
var retained_context:=""
func _set_panel_processing(on: bool) -> void:
    for root in [rows,actions,pinned_rows]:
        root.process_mode=Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED

func _close() -> void:
    sim.campaign.guided.panel_closed(panel)
    sheet.hide()
    _clear_filters()
    if panel!="":
        retained_panel=panel
        retained_context=panel_context
    _set_panel_processing(false)
    panel=""
    panel_context=""
    selected_card=""
    notice.text=""
    _refresh_slots()

func _pause() -> void:
    $Safe/Layout/Map/GestureSurface.cancel_gesture()
    get_tree().paused=not get_tree().paused
    AudioService.refresh_music()
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
        _recenter_on_player()
        return
    _say(text)

## Change 12: after a Prestige the camera centres on the newly spawned player and follows it again,
## whatever the camera was doing (a drag in progress, a pan far away). Zoom is kept. The new profile
## (and the player's new position) is committed before PRESTIGED is emitted, so nothing older can
## move the camera back on a later frame.
func _recenter_on_player() -> void:
    $Safe/Layout/Map/GestureSurface.cancel_gesture()
    stick.release()
    stick_input=Vector2.ZERO
    world.follow_player()

## Notification sounds for authoritative transitions (sim.notice): one cue per transition; the
## audio service merges it with anything else requested in the same frame.
func _notice(kind: String,_id: String) -> void:
    match kind:
        # Change 15: one notification sound (mission_ready) for every progression notice; a system
        # that is not revealed yet stays silent (it announces itself when it appears).
        "mission_ready":if revealed("missions"):AudioService.play("mission_ready")
        "main_ready":if revealed("missions"):AudioService.play("main_ready")
        "follow_step":AudioService.play("prestige_step")
        "feature_unlocked":AudioService.play("feature_unlocked")
        "mastery_objective":
            if revealed("prestige"):
                var bits: PackedStringArray=_id.split(":")
                AudioService.play("mastery_objective")
                _say(tr("MASTERY_OBJECTIVE_DONE") % [sim.catalog.stages[int(bits[0])-1].name,tr("MASTERY_"+bits[1].to_upper())])
        "mastery_map":if revealed("prestige"):AudioService.play("mastery_map")
        "game_complete":AudioService.play("game_complete")
        # Change 16: the first sight of a boss plays the notification (mission-ready) sound, once.
        "boss_found":AudioService.play("boss_found")
        # Change 14: the first Focused Farming purchase confirms itself on the panel's notice line
        # (or as a toast); the guide then points at the Farm button once.
        "focus_unlocked":_say(tr("FOCUS_UNLOCKED"))

## A deliberate manual action that succeeded gets the shared confirm (it replaces the click).
func _confirmed(ok: bool) -> bool:
    if ok:AudioService.play("ui_confirm")
    return ok

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
            # Change 15: Prestige is introduced after the Snowman; earlier finds wait for its reveal.
            if not revealed("prestige"):return
            var op: Dictionary=_opportunity(id)
            for card_id in _path_cards(str(op.path)):
                var d: Dictionary=sim.catalog.campaign.cards[card_id]
                cards.append({"icon":_path_art(str(op.path)),"text":PRESTIGE_CARD_SCRIPT.headline(d)})
            banner.push(kind,tr("MILESTONE_DISCOVERED" if kind=="discovered" else "MILESTONE_READY"),op.name,cards)
            AudioService.play("prestige_discovered" if kind=="discovered" else "prestige_ready")
        "card":
            var d: Dictionary=sim.catalog.campaign.cards[id]
            banner.push(kind,tr("MILESTONE_CARD") % d.name,d.description,[{"icon":_path_art(str(d.path)),"text":PRESTIGE_CARD_SCRIPT.headline(d)}])
        "prestiged":
            banner.push(kind,tr("MILESTONE_PRESTIGED"),tr("MILESTONE_PRESTIGED_DETAIL") % id.split(",").size())
            AudioService.play("prestiged")
        "stage":
            banner.push(kind,tr("MILESTONE_STAGE"),sim.catalog.stages[int(id)-1].name)
            AudioService.play("stage_unlocked")
        # Change 15 milestones (the notice that comes with each plays the sound).
        "prestige_unlocked":
            banner.push(kind,tr("MILESTONE_PRESTIGE_UNLOCKED"),tr("MILESTONE_PRESTIGE_UNLOCKED_DETAIL") % int(id) if int(id)>0 else tr("MILESTONE_PRESTIGE_UNLOCKED_NONE"))
        "mastery_map":
            if revealed("prestige"):
                var st:=int(id)
                banner.push(kind,tr("MILESTONE_MASTERY_MAP") % sim.catalog.stages[st-1].name,mastery_reward_text(sim.campaign.mastery.rules.map_rewards[st-1]))
        "mastery_game":
            banner.push(kind,tr("MILESTONE_MASTERY_GAME"),tr("MASTER_FARMER_TITLE")+" · "+mastery_reward_text(sim.campaign.mastery.rules.completion_reward))
        # Change 16: a boss seen for the first time: a red warning ahead of any queued banner.
        "boss_found":
            var g: int=sim.campaign.group_id(id)
            if g>=0:
                var d: Dictionary=sim.catalog.groups[g]
                banner.push_warning(kind,tr("BOSS_FOUND_WARNING"),tr("BOSS_FOUND_DETAIL") % [d.name,sim.catalog.stages[int(d.stage)-1].name],icon_cache.get(d.body))

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
        # Change 24: a panel action is a committed player action (coalesced save within 1 s).
        SaveService.mark_committed()
        AudioService.play("ui_click")
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
        SaveService.mark_committed()
        AudioService.play("ui_click")
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
        AudioService.play("ui_click"))
    return button

## Change 16: a destructive action can name its button and show it red (theme type "Danger").
func _confirm(text: String,callback: Callable,action_text:="",danger:=false,title:="") -> void:
    confirm_action=callback
    $Confirm/Panel/Margin/Content/Scroll/Text.text=text
    $Confirm/Panel/Margin/Content/Title.text=title if title!="" else tr("CONFIRM")
    $Confirm/Panel/Margin/Content/Actions/Confirm.text=action_text if action_text!="" else tr("CONFIRM")
    $Confirm/Panel/Margin/Content/Actions/Confirm.theme_type_variation=&"Danger" if danger else &""
    $Confirm/Panel/Margin/Content/Actions/Cancel.text=tr("CANCEL")
    $Confirm/Panel/Margin/Content/Scroll.scroll_vertical=0
    confirm_generation+=1
    var generation:=confirm_generation
    # Measure after entering the tree and again after Godot resolves wrapping. Keep the modal
    # invisible for these two frames so its first visible frame has a settled, stable size.
    $Confirm.modulate.a=0.0
    $Confirm.show()
    _layout_confirm()
    _settle_confirm(generation)
    $Confirm/Panel/Margin/Content/Actions/Cancel.grab_focus()

func _settle_confirm(generation: int) -> void:
    await get_tree().process_frame
    if generation!=confirm_generation or not $Confirm.visible:return
    _layout_confirm()
    await get_tree().process_frame
    if generation!=confirm_generation or not $Confirm.visible:return
    _layout_confirm()
    $Confirm.modulate.a=1.0

func _cancel_confirm() -> void:
    confirm_generation+=1
    $Confirm.hide()
    confirm_action=Callable()

## Fit once on open (after text wraps) and on actual safe-area changes, never in _process.
## Measure the title, actions and message only once; the previous implementation added the
## message height to the panel minimum, which could count it twice and cause oscillation.
func _layout_confirm() -> void:
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var available:=size-Vector2(insets.x+insets.z,insets.y+insets.w)-Vector2(40,40)
    if available.x<=0 or available.y<=0:return
    var box: Control=$Confirm/Panel
    var width:=minf(600.0,available.x)
    var text: Label=$Confirm/Panel/Margin/Content/Scroll/Text
    # Both the MarginContainer and the message require space at the final width.
    var text_width:=maxf(0.0,width-72.0)
    if not is_equal_approx(text.custom_minimum_size.x,text_width):text.custom_minimum_size.x=text_width
    var heading: Control=$Confirm/Panel/Margin/Content/Title
    var actions_row: Control=$Confirm/Panel/Margin/Content/Actions
    var style: StyleBox=box.get_theme_stylebox("panel")
    var chrome:=36.0+24.0+heading.get_combined_minimum_size().y+actions_row.get_combined_minimum_size().y+style.get_margin(SIDE_TOP)+style.get_margin(SIDE_BOTTOM)
    var message_height:=maxf(text.get_combined_minimum_size().y,float(text.get_line_count())*text.get_line_height())
    var wanted:=maxf(220.0,chrome+message_height)
    var height:=minf(available.y,wanted)
    var target:=Vector2(width,height)
    if not box.size.is_equal_approx(target):box.size=target
    var at:=Vector2(centered_x(box.size.x,insets),insets.y+20.0+(available.y-box.size.y)*0.5)
    if not box.position.is_equal_approx(at):box.position=at

## Left edge that centres a box of this width on the usable (safe-area) width of the screen.
func centered_x(width: float,insets: Vector4) -> float:
    return insets.x+(size.x-insets.x-insets.z-width)*.5

## Change 25 (REL-03): Android system Back (NOTIFICATION_WM_GO_BACK_REQUEST; project setting
## application/config/quit_on_go_back is off, so Back never quits silently) and Escape (ui_cancel)
## share one handler, in priority: the Prestige confirmation, the confirmation, the open panel, then
## on the bare HUD an exit confirmation (progress is saved first; Exit saves again and quits). The
## guide chooser is a decision and swallows Back. Change 35: Back on the review invitation is Maybe
## Later (dismissed, never shown automatically again). Each press is handled once, even when the key
## event and the notification arrive in the same frame.
var back_frame:=-1
func back() -> void:
    var frame:=Engine.get_process_frames()
    if frame==back_frame:return
    back_frame=frame
    if sim.state.tutorial.mode=="pending":return
    $Safe/Layout/Map/GestureSurface.cancel_gesture()
    stick.release()
    # Change 40: an open dropdown menu closes first; the Escape that just closed one does nothing more.
    for dropdown in get_tree().get_nodes_in_group(LANGUAGE_DROPDOWN.GROUP):
        if dropdown.is_menu_open():
            dropdown.close_menu();return
        if dropdown.closed_frame>=frame-1:return
    if $ReviewInvitation.is_open():
        _review_later();return
    if $PrestigeConfirm.visible:$PrestigeConfirm.close()
    elif $Confirm.visible:_cancel_confirm()
    elif sheet.visible:_close()
    else:
        SaveService.save_now()
        _confirm(tr("EXIT_CONFIRM"),_quit,tr("EXIT_ACTION"),false,tr("EXIT_TITLE"))
        return
    AudioService.play("ui_click")

func _quit() -> void:
    SaveService.save_now()
    get_tree().quit()

func _notification(what: int) -> void:
    if what==NOTIFICATION_WM_GO_BACK_REQUEST:back()
    elif what==NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and sim!=null:_language_changed()

## Localization Batch 01: a language switch redraws everything built in code. Catalog names are
## re-translated from their keys, the open panel is rebuilt in place, the retained panel is dropped
## (its rows hold the old language) and the HUD redraws on the next tick.
func _language_changed() -> void:
    sim.catalog.relocalize()
    retained_panel=""
    elapsed=1.0
    slot_signatures.clear()
    $Safe/Layout/Map/ViewCamp.text=tr("VIEW_CAMP")
    if sheet.visible:_refresh_panel(true)
    _refresh_slots()

func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        back()
        get_viewport().set_input_as_handled()

func _panel_context() -> String:
    return "%s:%s:%d:%d:%d:%d:%d:%s:%d:%d:%s:%d:%s:%d:%d" % [panel,selected,selected_slot,group,player_tab,enemy_tab,enemy_variant,selected_card,inventory_filter,sim.state.prestige_batch.get("choices",[]).size(),show_completed_main,guide_stage,str(teleport_target)+":"+str(travel_stage),sim.campaign.focus_hint,mastery_stage]

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
        "filters":_inventory_panel()
        "teleport":_teleport_panel()
        "offline":_offline_panel()
        "level":_level_panel()
        "farming":_farming_panel()
        "mastery":_mastery_panel()
        "travel_map":_travel_map_panel()
        "help":_help_panel()
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
    # A full replacement clears the old controls first, so incoming ones keep their names (a sibling
    # still present with the same name would make Godot rename the newcomer).
    if replace_all and live.get_child_count()>0:
        for old in live.get_children():
            live.remove_child(old)
            old.queue_free()
        changed=true
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
            # A control that builds its own children (the World map's player dot) is reconciled by its
            # properties only: its off-tree description never ran _ready, so it has none to compare.
            if not existing.has_meta("own_children"):changed=_sync_panel_children(existing,incoming,mapping) or changed
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
        if not supplies and inventory_filter>0 and sim.catalog.items[id].kind!=FILTER_KINDS[inventory_filter]:continue
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
            _buy_supply_actions(row)
            _game_action(tr("AUTO_SLOT_STATUS") % tr("ON" if sim.state.auto_slots.has(selected_slot) else "OFF"),func()->void:sim.bind_auto(selected_slot),true,"",row)
        return
    var id:=selected
    var def: Dictionary=sim.catalog.items[id]
    var r:=sim.record(id)
    var list:=_browse_list()
    if def.kind=="consumable":
        _supply_panel(id,list)
        return
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
    # Change 16: a skill says what it does with today's numbers instead of a bare "Power" value.
    if def.kind=="skill":
        for line in skill_description(id):_card_line(details,line,19,Color.WHITE)
        shown["power"]=true
    else:
        for key in sim.normal(id):
            _stat_line(details,_stat_text(key,sim.normal(id)[key],true),deltas.get(key,0.0),key,22)
            shown[key]=true
    for key in r.extras:
        _stat_line(details,"+ "+_stat_text(key,r.extras[key],true),0.0 if shown.has(key) else deltas.get(key,0.0),key,19,Color(.75,.8,.87))
        shown[key]=true
    # Stats only the equipped item gives: shown as what equipping this one would lose.
    for key in ["damage","hp","defense","crit","crit_damage","speed","lifesteal","regen","regen_pct"]:
        if not shown.has(key) and _meaningful(key,deltas.get(key,0.0)):
            _stat_line(details,tr("STAT_"+key.to_upper())+"  —",deltas[key],key,19,Color(.7,.75,.82))
    if comparing:
        var effect:=[]
        var gains:=0;var losses:=0
        for key in ["damage","hp","crit","speed","defense","lifesteal","regen","regen_pct"]:
            var delta: float=deltas.get(key,0.0)
            if _meaningful(key,delta):
                effect.append(_signed_stat(key,delta))
                if delta>0:gains+=1
                else:losses+=1
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
            if gain>0:gains.append(_skill_amount(str(def.skill),gain) if def.kind=="skill" else _stat_text(stat,gain,true))
        _card_line(details,tr("NEXT_MERGE_GAIN")+" "+", ".join(gains),17,Color(.5,1,.65))
    else:
        _card_line(details,tr("STOCK_BONUS") % fmt(maxi(0,int(r.qty)-1)*float(sim.catalog.progression.merge.stock_bonus_per_copy)*100),17,Color(.5,1,.65))
    if def.kind=="outfit":_outfit_milestone_lines(details,id)
    # Change 13: every skill shows its effective cooldown from the same getter the cast uses (Change 16:
    # it is part of skill_description, with targets and range).
    if def.get("skill","")=="heal":_text(tr("HEAL_ROLE_SHORT"),17,Color(.8,.84,.9))
    # Secondary actions: a wrapping row, sized for their widest label.
    var more:=HFlowContainer.new()
    more.add_theme_constant_override("h_separation",8)
    more.add_theme_constant_override("v_separation",8)
    var amount:=mini(int(r.qty)-1,cap-int(r.merge))
    if r.merge<cap and amount>1:_game_action(tr("MERGE_ALL") % amount,func()->void:if selected==id:_confirmed(sim.merge(id,true)),true,"",more)
    if def.next!="" and r.merge>=cap:
        _game_action(tr("EVOLVE") % sim.catalog.display_name(def.next),func()->void:if selected==id:_confirmed(sim.evolve(id)),r.qty>=101,"EVOLUTION_NEEDS",more)
    if def.kind=="skill":
        for i in range(1+sim.level("skill_slots")):
            _game_action(tr("EQUIP_SKILL_SLOT") % (i+1),func()->void:if selected==id:sim.campaign.equip_skill(id,i),true,"",more)
    if not def.extras.is_empty():
        var cost:=ceili(float(def.reroll)*(1-sim.campaign.bonus("reroll_discount")))
        _game_action(tr("REROLL") % fmt_cost(cost),func()->void:_confirm(tr("REROLL_CONFIRM") % fmt_cost(cost),func()->void:if selected==id:sim.reroll(id)),true,"",more)
    if sim.gear_group(id)>=0:_game_action(tr("ITEM_AUTO_MERGE") % tr("OFF" if sim.auto_merge_excluded(id) else "ON"),func()->void:sim.set_auto_merge_excluded(id,not sim.auto_merge_excluded(id)),true,"",more).set_meta("guide","item_auto_merge")
    _drop_action(id,more)
    for button in more.get_children():
        button.size_flags_horizontal=0
        button.custom_minimum_size=Vector2(0,64)
        button.add_theme_font_size_override("font_size",18)
    if more.get_child_count()>0:rows.add_child(more)
    else:more.free()
    if def.kind=="outfit":
        _text(tr("OUTFIT_GROWTH_EXPLAIN") % [cap,fmt_value(float(sim.catalog.progression.stored_outfit_factor)*100)],17,Color(.8,.84,.9))
    elif sim.copy_growth(id):
        _text(tr("COPY_GROWTH_EXPLAIN") % cap,17,Color(.8,.84,.9))
    elif def.next!="" and r.merge>=cap:
        _text(tr("EVOLUTION_EXPLAIN"),17,Color(.8,.84,.9))
    elif def.next=="":
        _text(tr("MAX_ITEM_TIER"),17,Color(.8,.84,.9))
    # Pinned: previous, primary, merge, next. Positions never change while browsing.
    var index:=list.find(id)
    _arrow_button(-1,index>0,func()->void:_browse(-1))
    _pinned(tr("UNEQUIP" if sim.equipped(id) else "EQUIP"),func()->void:if selected==id:sim.equip(id),true,"",not sim.equipped(id),"equip")
    _pinned(tr("ITEM_MERGE_ACTION"),func()->void:if selected==id:_confirmed(sim.merge(id)),r.qty>1 and r.merge<cap,"NEED_DUPLICATES" if r.qty<2 else "MERGE_MAX",false,"merge")
    _arrow_button(1,index>=0 and index<list.size()-1,func()->void:_browse(1))

## Supply details (Change 11): what it does now, whether it can be used, stock (charges spent by use)
## and use-based mastery (change17.supply_uses_per_level actual uses per level, reset by Prestige), with the
## next mastery gain and milestone. Pinned: previous, Use, the slot's auto-use toggle, next.
func _supply_panel(id: String,list: Array) -> void:
    var s:=sim.supply(id)
    var slot: int=sim.state.supplies.find(id)
    selected_slot=slot
    _set_title(sim.catalog.display_name(id),Color(.72,.9,1))
    var details:=_item_summary_card(id,tr("COMPARE_ITEM"),Color(.6,1,.75),list.find(id),list.size())
    _card_line(details,_supply_effect_text(id),19,Color.WHITE)
    var reason:=sim.supply_block_reason(id)
    var status:=""
    var tone:=Color(.5,1,.65)
    if sim.buff_time(id)>0:
        status=tr("SUPPLY_STATUS_ACTIVE") % [_supply_amount(id,sim.buff_power(id)),ceili(sim.buff_time(id))];tone=Color(1,.84,.34)
    elif str(s.effect)=="heal" and float(sim.state.use_cd)>0:
        status=tr("SUPPLY_STATUS_COOLDOWN") % fmt(sim.state.use_cd);tone=Color(1,.72,.45)
    elif reason.is_empty():status=tr("SUPPLY_STATUS_READY")
    else:
        status=tr(reason);tone=Color(1,.72,.45)
    _card_line(details,status,18,tone)
    var auto_rule:=tr("SUPPLY_AUTO_RULE_"+str(s.effect).to_upper())
    if str(s.effect)=="heal":auto_rule=tr("SUPPLY_HEAL_AUTO_CURRENT")
    elif str(s.effect)=="recovery":auto_rule=auto_rule % fmt_value(float(s.auto_hp)*100)
    _card_line(details,auto_rule,16,Color(.75,.8,.87))
    _card_line(details,tr("SUPPLY_STOCK") % fmt_count(sim.quantity(id)),17,Color(.8,.84,.9))
    var mastery:=sim.supply_mastery(id)
    var cap:=sim.merge_cap(id)
    var gain: float=float(sim.catalog.items[id].normal[str(s.stat)][1])
    if mastery<cap:
        var next_gain:=_supply_amount(id,gain)
        _card_line(details,tr("SUPPLY_NEXT_USES") % [int(sim.state.supply_uses.get(id,0))%int(sim.catalog.progression.change17.supply_uses_per_level),int(sim.catalog.progression.change17.supply_uses_per_level),next_gain],17,Color(.5,1,.65))
    var reached:=sim.supply_milestone(id)
    if float(reached.duration)>1.0:
        var active_key:="SUPPLY_MILESTONE_COOLDOWN" if str(s.effect)=="heal" else "SUPPLY_MILESTONE_DURATION"
        _card_line(details,tr("SUPPLY_MILESTONES_ACTIVE") % (tr(active_key) % _milestone_factor(id,reached)),17,Color(.5,1,.65))
    var step:=sim.next_supply_milestone(id)
    if step.is_empty():_card_line(details,tr("MILESTONES_COMPLETE"),17,Color(1,.86,.5))
    else:
        var key:="SUPPLY_MILESTONE_COOLDOWN" if str(s.effect)=="heal" else "SUPPLY_MILESTONE_DURATION"
        _card_line(details,tr("MILESTONE_NEXT") % [int(step.merge),tr(key) % _milestone_factor(id,step)],17,Color(1,.86,.5))
    var more:=HFlowContainer.new()
    more.add_theme_constant_override("h_separation",8)
    more.add_theme_constant_override("v_separation",8)
    rows.add_child(more)
    if int(s.get("price",0))>0:
        _game_action(tr("BUY_SUPPLY") % [sim.catalog.display_name(id),fmt_cost(int(s.price))],func()->void:if selected==id:_confirmed(sim.purchase_consumable(id)),true,"",more)
    _drop_action(id,more)
    for button in more.get_children():
        button.size_flags_horizontal=0
        button.custom_minimum_size=Vector2(0,64)
        button.add_theme_font_size_override("font_size",18)
    if more.get_child_count()==0:
        rows.remove_child(more);more.free()
    _text(tr("SUPPLY_MASTERY_EXPLAIN") % cap,17,Color(.8,.84,.9))
    var index:=list.find(id)
    _arrow_button(-1,index>0,func()->void:_browse(-1))
    _pinned(tr("USE"),func()->void:if selected==id:sim.use_item(id),reason.is_empty(),reason,true,"use")
    _pinned(tr("AUTO_SHORT") % tr("ON" if sim.state.auto_slots.has(slot) else "OFF"),func()->void:if selected==id:sim.bind_auto(sim.state.supplies.find(id)),slot>=0,"CANNOT_USE",false,"auto")
    _arrow_button(1,index>=0 and index<list.size()-1,func()->void:_browse(1))

## Change 16 Drop All: discards the whole selected stack to free its inventory slot. The action shows
## red; the confirmation names the item, its ^level and quantity and its button reads "Drop All" in
## red. Equipped items say to unequip them first (sim.discard_block_reason).
func _drop_action(id: String,parent: Node) -> void:
    var reason:=sim.discard_block_reason(id)
    var button:=_game_action(tr("DROP_ALL"),func()->void:if selected==id:_confirm_drop(id),reason.is_empty(),reason,parent)
    button.theme_type_variation=&"Danger" if reason.is_empty() else &""
    button.set_meta("guide","drop_all")

func _confirm_drop(id: String) -> void:
    var level:=tr("DROP_ALL_MASTERY") % sim.merge_level(id) if sim.catalog.items[id].kind=="consumable" else "^%d" % sim.merge_level(id)
    var text:=tr("DROP_ALL_CONFIRM") % [sim.catalog.display_name(id),level,fmt_count(sim.quantity(id))]
    _confirm(text,func()->void:
        var count:=sim.quantity(id)
        if _confirmed(sim.discard(id)):_say(tr("DROPPED_NOTICE") % [fmt_count(count),sim.catalog.display_name(id)])
        _refresh_slots(),tr("DROP_ALL"),true,tr("DROP_ALL_TITLE"))

## Change 16: what a skill does, from the getters its cast uses, so merges, evolutions, cards and the
## cooldown upgrade always show: the effect with today's numbers, then targets, range and cooldown.
func skill_description(id: String) -> Array:
    var key: String=str(sim.catalog.items[id].skill)
    var power: float=sim.skill_power(id)
    var damage: float=float(sim.stats().damage)
    var lines: Array=[]
    match key:
        "heal":
            lines.append(tr("SKILL_HEAL_CURRENT") % [fmt_value(power),fmt_value(sim.skill_base_power(id)*100)])
        "focus":lines.append(tr("SKILL_DESC_FOCUS") % [fmt_value(power*100),fmt_value(damage*power)])
        "frost":lines.append(tr("SKILL_DESC_FROST") % [fmt_value(power),fmt_value(damage*power),fmt_value(sim.campaign.skill_range("frost"))])
        "fire":lines.append(tr("SKILL_DESC_FIRE") % [fmt_value(power),fmt_value(damage*power),fmt_value(sim.campaign.FIRE_RADIUS)])
        _:lines.append(tr("SKILL_DESC_"+key.to_upper()) % [fmt_value(power),fmt_value(damage*power)])
    var targets:="SKILL_TARGET_SELF" if key in ["heal","focus"] else ("SKILL_TARGET_AREA" if key in ["frost","fire"] else "SKILL_TARGET_ONE")
    var reach:=tr("SKILL_RANGE_SELF") if key in ["heal","focus"] else tr("SKILL_RANGE") % fmt_value(sim.campaign.skill_range(key))
    lines.append(tr("SKILL_DESC_STATS") % [tr(targets),reach,fmt_value(sim.player_upgrade_value("cooldown_"+key))])
    if key!="heal":lines.append(tr("SKILL_ACTIVATION_LIMIT") % fmt_value(sim.campaign.skill_activation_distance()))
    if key=="lightning":lines.append(tr("LIGHTNING_SLOW_DESCRIPTION") % [fmt_value((1.0-float(sim.catalog.progression.change17.lightning_attack_rate))*100),fmt_value(sim.catalog.progression.change17.lightning_duration),fmt_value(float(sim.catalog.progression.change17.lightning_duration)*float(sim.catalog.progression.change17.boss_status_duration))])
    if key=="frost":lines.append(tr("BOSS_STATUS_DESCRIPTION"))
    return lines

## A skill's strength in its own unit: HP for Heal, a damage share for Focus, × attack for attacks.
func _skill_amount(key: String,value: float) -> String:
    match key:
        "heal":return tr("SKILL_AMOUNT_HP") % fmt_value(value)
        "focus":return tr("SKILL_AMOUNT_FOCUS") % fmt_value(value*100)
    return tr("SKILL_AMOUNT_MULTIPLIER") % fmt_value(value)

## A supply's amount in its own unit: % of max HP, % coins or XP, flat Defense, % max HP per second.
func _supply_amount(id: String,value: float) -> String:
    match str(sim.supply(id).get("stat","")):
        "heal_pct":return tr("SUPPLY_AMOUNT_HEAL") % fmt_value(value*100)
        "coin_bonus":return tr("SUPPLY_AMOUNT_COINS") % fmt_value(value*100)
        "xp_bonus":return tr("SUPPLY_AMOUNT_XP") % fmt_value(value*100)
        "defense":return tr("SUPPLY_AMOUNT_DEFENSE") % fmt_value(value)
        "regen_pct":return tr("SUPPLY_AMOUNT_REGEN") % fmt_value(value*100)
    return fmt_value(value)

## Effect, amount now, duration or cooldown and use condition, from the simulation's own getters.
func _supply_effect_text(id: String) -> String:
    var s:=sim.supply(id)
    var value:=sim.supply_value(id)
    var duration:=fmt_value(sim.supply_duration(id))
    match str(s.effect):
        "heal":return tr("SUPPLY_EFFECT_HEAL") % [fmt_value(value*100),fmt_count(sim.stats().hp*value),fmt_value(sim.supply_cooldown(id)),fmt_value(float(s.use_hp)*100)]
        "coins":return tr("SUPPLY_EFFECT_COINS") % [fmt_value(value*100),duration]
        "guard":return tr("SUPPLY_EFFECT_GUARD") % [fmt_value(value),fmt_value(100.0*value/(100.0+value)),duration]
        "recovery":return tr("SUPPLY_EFFECT_RECOVERY") % [fmt_value(value*100),duration,fmt_value(value*sim.supply_duration(id)*100),fmt_value(float(s.use_hp)*100)]
        "xp":return tr("SUPPLY_EFFECT_XP") % [fmt_value(value*100),duration]
    return ""

## A milestone's multiplier as a readable change: "×1.4" duration or a cooldown in seconds.
func _milestone_factor(id: String,step: Dictionary) -> String:
    if str(sim.supply(id).effect)=="heal":return fmt_value(sim.supply_cooldown_with(id,float(step.cooldown)))
    return "×"+fmt_value(float(step.duration))

## Outfit milestone track (Change 9): what this outfit's merges have unlocked and the next step. The
## effects apply only while this outfit is worn; values come from sim.outfit_milestones().
func _outfit_milestone_lines(box: VBoxContainer,id: String) -> void:
    var active:=sim.outfit_milestones(id)
    var parts: Array[String]=[]
    if float(active.defense)>0:parts.append(tr("MILESTONE_GUARD") % fmt_value(active.defense))
    if float(active.hp)>0:parts.append(tr("MILESTONE_HP_ACTIVE") % fmt(active.hp))
    if float(active.regen_pct)>0:parts.append(tr("MILESTONE_RECOVERY") % fmt_value(float(active.regen_pct)*100))
    var worn: bool=sim.state.outfit==id
    var tone:=Color(.5,1,.65) if worn and not parts.is_empty() else Color(.75,.8,.87)
    _card_line(box,(tr("MILESTONES_ACTIVE") % ", ".join(parts)) if not parts.is_empty() else tr("MILESTONES_NONE"),17,tone)
    var step:=sim.next_outfit_milestone(id)
    if step.is_empty():
        _card_line(box,tr("MILESTONES_COMPLETE"),17,Color(1,.86,.5))
    else:
        _card_line(box,tr("MILESTONE_NEXT") % [int(step.merge),_milestone_step_text(step,float(sim.catalog.items[id].tier))],17,Color(1,.86,.5))

func _milestone_step_text(step: Dictionary,tier: float) -> String:
    var parts: Array[String]=[]
    if step.has("defense_per_tier"):parts.append(tr("MILESTONE_GUARD") % fmt_value(float(step.defense_per_tier)*tier))
    if step.has("hp_share"):parts.append(tr("MILESTONE_HP_STEP") % fmt_value(float(step.hp_share)*100))
    if step.has("regen_pct_per_tier"):parts.append(tr("MILESTONE_RECOVERY") % fmt_value(float(step.regen_pct_per_tier)*tier*100))
    return ", ".join(parts)

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
    # The same slot look as the inventory (tier colour plus the outfit milestone frame).
    var frame:=Panel.new()
    frame.custom_minimum_size=Vector2(96,96)
    frame.add_theme_stylebox_override("panel",_tier_style(id,false))
    frame.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
    line.add_child(frame)
    var icon:=TextureRect.new()
    icon.texture=icon_cache.get(id) if id!="" else null
    icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    icon.offset_left=12;icon.offset_top=12;icon.offset_right=-12;icon.offset_bottom=-12
    icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
    frame.add_child(icon)
    _apply_milestone_frame(frame,id)
    var details:=VBoxContainer.new()
    details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation",3)
    line.add_child(details)
    if id=="":
        _card_line(details,tr("NOTHING_EQUIPPED"),18,Color(.7,.75,.82))
        return details
    _card_line(details,sim.catalog.display_name(id),21,_tier_color(id).lightened(.55))
    var merge_text:=(tr("ITEM_TIER_MERGE_CAP") % [int(sim.catalog.items[id].tier),int(sim.record(id).merge),sim.merge_cap(id)]) if sim.copy_growth(id) else (tr("ITEM_TIER_MERGE") % [int(sim.catalog.items[id].tier),int(sim.record(id).merge)])
    if sim.catalog.items[id].kind=="consumable":merge_text=tr("SUPPLY_MASTERY_LEVEL") % [sim.supply_mastery(id),sim.merge_cap(id)]
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

## Smallest change worth showing; Recovery is a fraction of max HP per second (0.0025 = 0.25%).
func _meaningful(key: String,value: float) -> bool:
    return absf(value)>=(.00001 if key=="regen_pct" else .005)

func _signed_stat(key: String,value: float) -> String:
    var sign:="+" if value>=0 else "−"
    if key=="regen_pct":return sign+fmt_value(absf(value)*100)+"% "+tr("STAT_REGEN_PCT")
    if key in ["crit","lifesteal","speed","coin_bonus"]:return sign+fmt(absf(value)*100)+"% "+tr("STAT_"+key.to_upper())
    return sign+fmt(absf(value))+" "+tr("STAT_"+key.to_upper())

func _tabs(keys: Array,active: int,callback: Callable) -> void:
    var bar:=HBoxContainer.new()
    bar.name="Tabs"
    bar.add_theme_constant_override("separation",6)
    rows.add_child(bar)
    # Localization Batch 01: a label longer than its equal share of the row ("Consommables", "Sin conexión")
    # steps its font down instead of being cut; the ellipsis remains only as a last resort.
    var room: float=(maxf(320.0,$Sheet/Margin/Content/Scroll.size.x-24)-6.0*(keys.size()-1))/keys.size()-get_theme_stylebox("normal","Button").get_minimum_size().x-4
    for i in range(keys.size()):
        var button:=Button.new()
        button.text=tr(keys[i])
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.custom_minimum_size.y=56
        button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
        button.add_theme_font_size_override("font_size",_fitting_font_size(button.text,room,18,13))
        if i==active:button.theme_type_variation=&"Primary"
        button.set_meta("guide","tab_"+str(keys[i]).to_lower())
        bar.add_child(button)
        button.pressed.connect(func()->void:
            callback.call(i)
            $Sheet/Margin/Content/Scroll.scroll_vertical=0
            _refresh_panel(true))

## Localization Batch 01: the largest font size from max_size down to min_size at which text fits room.
func _fitting_font_size(text: String,room: float,max_size: int,min_size: int) -> int:
    var font: Font=get_theme_default_font()
    var font_size:=max_size
    while font_size>min_size and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>room:font_size-=1
    return font_size

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
    var sections: Array=[["respawn","movement","skill_slots","skill_auto_slots","critical_chance","critical_damage"],["gear_slots","supply_slots","merge_all"],["auto_use","use_speed"],["gem_chance","gem_amount","boss_gem_chance","boss_gem_amount"],["offline_cap","offline_coins","offline_gems","offline_weapon","offline_outfit","offline_consumable","offline_weapon_rate","offline_outfit_rate","offline_consumable_rate"]]
    if player_tab==0:_text(tr("UPGRADES_PLAYER_HINT"),17,Color(.75,.8,.87))
    if player_tab==4:
        if not sim.state.offline_pending.is_empty():
            _text(tr("OFFLINE_PENDING_NOTE"),18,Color(1,.86,.5))
            _action(tr("OFFLINE_CLAIM"),func()->void:_open("offline"))
        else:
            var r: Dictionary=sim.campaign.offline_receipt
            if not r.is_empty():
                _text(tr("OFFLINE_CLAIMED_RECEIPT") % [fmt(r.rewarded_hours),fmt_currency(r.coins),fmt_currency(r.gems)])
                for id in r.items:_text(sim.catalog.display_name(id)+" ×"+fmt(r.items[id]),18)
        var snap: Dictionary=sim.campaign.offline_snapshot()
        _text(tr("OFFLINE_RATES") % [fmt_currency(snap.coins),fmt_currency(snap.gems),fmt(snap.cap/3600)],18,Color(.8,.84,.9))
    for id in sections[player_tab]:
        # Skill slots and auto-cast appear with the first skill found (Change 8).
        if id.begins_with("skill_") and sim.state.skills_seen.is_empty():continue
        _group_upgrade_card(id,-1)
    if player_tab==0:
        _text(tr("AUTO_SKILL_CAPACITY") % [sim.automatic_skill_assignments().size(),sim.automatic_skill_capacity()],18)
        for i in range(1+sim.level("skill_slots")):
            var assigned: bool=sim.automatic_skill_assignments().has(i)
            var available: bool=assigned or (sim.state.skills[i]!="" and sim.automatic_skill_assignments().size()<sim.automatic_skill_capacity())
            var label: String=tr("SKILL_AUTO_TOGGLE") % [i+1,tr("ON" if assigned else "OFF")]
            if sim.state.skills[i]!="":label+=" · "+sim.catalog.display_name(sim.state.skills[i])
            _game_action(label,func()->void:
                var picks: Array=sim.automatic_skill_assignments()
                if picks.has(i):picks.erase(i)
                else:picks.append(i)
                sim.assign_automatic_skills(picks),available,"AUTO_SKILL_CAPACITY_FULL").set_meta("guide","auto_skill_%d" % i)
        # A skill's own upgrades stay hidden until that skill has been obtained once.
        for key in sim.catalog.skills:
            if sim.skill_seen(key):_group_upgrade_card("cooldown_"+key,-1)
    # Inventory filtering moved to the dock's Filters shortcut (Change 11); this tab keeps capacity.
    if player_tab==1:_text(tr("SUPPLY_CAPACITY_NOTE") % sim.supply_ids().size(),17,Color(.75,.8,.87))
    if player_tab==2:
        _text(tr("SUPPLY_MASTERY_EXPLAIN") % int(sim.catalog.progression.supply_mastery.cap),17,Color(.75,.8,.87))
        var row:=HFlowContainer.new();rows.add_child(row)
        _buy_supply_actions(row)

## Shop buttons for all five priced supplies. Bought copies add stock only.
func _buy_supply_actions(row: Node) -> void:
    for id in sim.supply_ids():
        var price:=int(sim.supply(id).get("price",0))
        if price>0:_game_action(tr("BUY_SUPPLY") % [sim.catalog.display_name(id),fmt_cost(price)],func()->void:_confirmed(sim.purchase_consumable(id)),true,"",row).set_meta("guide","buy_supply_"+id)

## Compact upgrade card: icon, name, computed benefit, a status line and the buy button.
## The status line is always present; it wraps rather than cutting off the reason (Localization Batch 01:
## a longer language would otherwise hide why the upgrade cannot be bought).
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
    status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    status.add_theme_font_size_override("font_size",17)
    status.add_theme_color_override("font_color",Color(1,.72,.45) if not reason.is_empty() and reason!="UPGRADE_MAX" else Color(.7,.75,.82))
    text.add_child(status)
    var buy:=Button.new()
    buy.custom_minimum_size=Vector2(128,76)
    buy.text=tr("UPGRADE_MAX") if maxed else fmt_cost(sim.upgrade_cost(id,g))
    buy.icon=null if maxed else (COIN if def.currency=="coins" else GEM)
    buy.expand_icon=true
    buy.add_theme_constant_override("icon_max_width",26)
    buy.disabled=not reason.is_empty()
    buy.theme_type_variation=&"Primary" if reason.is_empty() else &""
    buy.tooltip_text=tr(reason) if not reason.is_empty() else tr("UP_"+id.to_upper())
    buy.set_meta("upgrade",id)
    buy.set_meta("guide","buy_"+id if id in ["loot","gear_slots","supply_slots"] else "buy_upgrade")
    buy.pressed.connect(func()->void:
        if not _confirmed(sim.buy_upgrade(id,g)):AudioService.play("ui_click"))
    line.add_child(buy)
    action_buttons.append({"node":buy,"kind":"upgrade","id":id,"group":g})

func _upgrade_icon(id: String,g: int) -> Texture2D:
    var def: Dictionary=sim.catalog.upgrades[id]
    var icon: Texture2D=icon_cache.get(sim.catalog.groups[g].body) if g>=0 and def.scope in ["type","normal_type"] else _art(147)
    if id.begins_with("cooldown_"):icon=icon_cache.get("skill_"+id.trim_prefix("cooldown_"))
    elif id in ["auto_use","use_speed","supply_slots","supply_drop"]:icon=icon_cache.get("potion")
    elif id in ["map_detail","camp_radius","reveal_radius"]:icon=_art(249)
    elif id=="merge_all":icon=_art(147)
    elif id.begins_with("offline_"):icon=_art(171)
    if id=="coin_amount":icon=COIN
    elif id in ["gem_chance","gem_amount","boss_gem_chance","boss_gem_amount"]:icon=GEM
    elif id in ["loot","merge_gear","auto_evolve"] and g>=0:icon=icon_cache.get(sim.catalog.groups[g].weapon)
    return icon

func _upgrade_row(id: String,g: int=-1) -> void:
    _group_upgrade_card(id,g)

## Upgrades whose value is an amount of Coins or Gems (per kill, per drop or per hour).
const CURRENCY_UPGRADES:=["coin_amount","gem_amount","boss_gem_amount","offline_coins","offline_gems"]
func _upgrade_benefit(id: String,g: int) -> String:
    var next:=0 if sim.upgrade_maxed(id,g) else 1
    # Change 10: equipment slots read as "slots now -> next of 70", and "70 / 70 · maxed" at the cap.
    if id=="gear_slots":
        if next==0:return tr("EQUIPMENT_SLOTS_MAXED") % [sim.equipment_slot_count(),sim.equipment_slot_max()]
        return tr("EQUIPMENT_SLOTS_NEXT") % [sim.equipment_slot_count(),int(sim.player_upgrade_value(id,1)),sim.equipment_slot_max()]
    if id=="merge_all":return tr("MERGE_ALL_UNLOCKED") if sim.level(id)>0 else tr("MERGE_ALL_BENEFIT")
    # Change 13: each per-type unlock names the exact items it covers (what this type drops; never
    # the tiers evolved from them, which follow their own droppers).
    if id=="merge_gear" and g>=0:
        var drops: Array=sim.catalog.groups[g].loot.duplicate()
        for skill in sim.catalog.groups[g].skills:drops.append("skill_"+str(skill))
        return tr("AUTO_MERGE_ON" if sim.level(id,g)>0 else "AUTO_MERGE_BENEFIT") % _item_names(drops)
    if id=="auto_evolve" and g>=0:
        return tr("AUTO_EVOLVE_ON" if sim.level(id,g)>0 else "AUTO_EVOLVE_BENEFIT") % _item_names(sim.evolvable_drops(g))
    if int(sim.catalog.upgrades[id].cap)==1:
        return tr("UPGRADE_TRANSITION") % [tr("ON" if sim.level(id,g)>0 else "OFF"),tr("ON")]
    var current:=sim.group_upgrade_value(id,g,enemy_variant) if g>=0 else sim.player_upgrade_value(id)
    var future:=sim.group_upgrade_value(id,g,enemy_variant,next) if g>=0 else sim.player_upgrade_value(id,next)
    var percent:=id in ["loot","supply_drop","skill_drop","gem_chance","boss_gem_chance","movement","reveal_radius","camp_radius","critical_chance","critical_damage"]
    var left:=fmt_value(current*100)+"%" if percent else fmt_value(current)
    var right:=fmt_value(future*100)+"%" if percent else fmt_value(future)
    # Change 13: coin and gem amounts use the shared currency format.
    if id in CURRENCY_UPGRADES:
        left=fmt_currency(current);right=fmt_currency(future)
    var value:=tr("UPGRADE_TRANSITION") % [left,right] if next>0 else tr("UPGRADE_MAXED_VALUE") % left
    if id=="boss_gem_amount":value=tr("BOSS_GEMS_PER_DROP") % value
    if id in ["respawn","collect_speed","gear_merge_speed","use_speed","spawn_cooldown"]:value=tr("SECONDS_VALUE") % value
    if id=="supply_drop":value=tr("POTION_CHANCE_VALUE") % value
    return value

func _item_names(ids: Array) -> String:
    return ", ".join(ids.map(func(id):return sim.catalog.display_name(str(id))))

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
    if sim.level("focus",group)>0:
        # Change 14: right after the first Focused Farming purchase, one line above the button says
        # what it does (above it, because the guide's arrow points at the button from below here).
        if sim.campaign.focus_hint==group and int(sim.state.focus)<0:_text(tr("FOCUS_HINT_PANEL"),17,Color(1,.86,.5))
        _game_action(tr("FOCUS_GROUP") % [d.name,tr("ON" if sim.state.focus==group and sim.state.focus_variant==enemy_variant else "OFF")],func()->void:sim.focus(group,enemy_variant),sim.campaign.spot_discovered(group,enemy_variant),"SPOT_UNDISCOVERED").set_meta("guide","focus_toggle")
    if enemy_tab==1:
        _section(tr("SECTION_REWARDS"))
        for id in ["loot","coin_amount","group_xp","supply_drop"]:_group_upgrade_card(id,group)
        if not d.skills.is_empty():_group_upgrade_card("skill_drop",group)
        if not d.boss:
            _group_upgrade_card("spawn_amount",group);_group_upgrade_card("spawn_cooldown",group)
        # Automation refinements appear once their automation is unlocked.
        _section(tr("SECTION_AUTOMATION"))
        # Change 13: Auto Evolution sits beside Auto-Merge, on types that drop an evolvable weapon.
        for pair in [["focus",""],["collect",""],["collect_range","collect"],["collect_batch","collect"],["collect_speed","collect"],["merge_gear",""],["auto_evolve",""],["gear_merge_speed","merge_gear"]]:
            if pair[0]=="auto_evolve" and sim.evolvable_drops(group).is_empty():continue
            if pair[1]=="" or sim.level(pair[1],group)>0:_group_upgrade_card(pair[0],group)
        # Change 14: the same two research upgrades as Overview (same card, same purchase, same
        # state), listed with this type's other upgrades; owned ones read Max here.
        _section(tr("SECTION_RESEARCH"))
        for id in ["reveal_stats","reveal_drops"]:_group_upgrade_card(id,group)
        return
    var def: Dictionary=sim.enemy_definition(group,enemy_variant)
    if sim.level("reveal_stats",group)==0:_group_upgrade_card("reveal_stats",group)
    else:_text(tr("ENEMY_STATS_VALUES") % [fmt(def.hp),fmt(def.damage),fmt(def.interval),fmt(def.defense)],20)
    if sim.level("reveal_drops",group)==0:_group_upgrade_card("reveal_drops",group)
    else:
        _text(tr("DROP_COINS") % fmt_currency(sim.coin_reward(group))+"  ·  "+tr("DROP_GEMS") % [fmt(sim.gem_chance(group)*100),fmt_currency(sim.gem_amount(0,group))],18)
        for id in def.loot:_loot_row(id,sim.gear_chance(group)*100)
        for skill in def.skills:_loot_row("skill_"+skill,sim.group_upgrade_value("skill_drop",group)*100/def.skills.size())
        # Supplies this type can drop (later supplies join on later maps), each with its own chance.
        for id in sim.supply_pool(group):_loot_row(id,sim.supply_drop_chance(group,id)*100)

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
    # Change 15: the enemy chips belong to the revealed enemy system.
    var known: bool=sim.campaign.discovered(g) and revealed("enemy")
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
    return tr("CAMP_STATE_LOCKED") % fmt_cost(sim.campaign.camp_price(i))

## Camps of the current stage first (where the camp lesson points), then the map, then travel.
func _world_panel() -> void:
    var stage: Dictionary=sim.campaign.stage()
    _set_title(stage.name)
    var gates: Array=stage.gates
    var count:=0
    for id in gates:
        if sim.state.run_kills.get(id,0)>0:count+=1
    if int(sim.state.stage)<8:
        _text(tr("GATE_PROGRESS") % [count,gates.size()],18,Color(1,.86,.5))
        # Change 13: each gate boss on its own line, so a two-boss gate with one already defeated
        # reads at a glance. An undiscovered boss is never named.
        if int(sim.state.unlocked_stage)>int(sim.state.stage):_text(tr("GATE_ALREADY_OPEN"),17,Color(.6,1,.75))
        else:
            for id in gates:
                var g: int=sim.campaign.group_id(str(id))
                var done: bool=int(sim.state.run_kills.get(id,0))>0
                var label: String=sim.catalog.groups[g].name if g>=0 and sim.campaign.discovered(g) else tr("GATE_UNKNOWN_BOSS")
                _text(tr("GATE_BOSS_DONE" if done else "GATE_BOSS_NEEDED") % label,17,Color(.6,1,.75) if done else Color(1,.86,.5))
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
    map.camp_selected.connect(func(camp: int)->void:_travel_to(int(sim.state.stage),camp))
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
    # Change 10: the map-by-map Farming Guide (opens per map once its research is complete).
    _action(tr("FARMING_GUIDE_OPEN"),func()->void:guide_stage=0;_open("farming")).set_meta("guide","farming_guide")
    # Change 15: Map Mastery (revealed with Prestige, after the Snowman).
    if revealed("prestige"):
        _action(tr("MASTERY_OPEN") % sim.campaign.mastery.game_percent(),func()->void:mastery_stage=0;_open("mastery")).set_meta("guide","mastery")
    if int(sim.state.unlocked_stage)>1:
        _section(tr("SECTION_TRAVEL"))
        for st in range(1,int(sim.state.unlocked_stage)+1):
            if st==int(sim.state.stage):continue
            var d: Dictionary=sim.catalog.stages[st-1]
            _action(d.name,func()->void:_select_travel_stage(st),true,"",rows).set_meta("guide","travel_stage_%d" % st)
    _section(tr("SECTION_MAP_UPGRADES"))
    for id in ["map_detail","reveal_radius"]:_group_upgrade_card(id,int(sim.state.stage))
    for i in sim.state.spawns:_group_upgrade_card("camp_radius",int(sim.state.stage)*10+int(i))

## Moves to an owned camp by the shared travel rules (campaign.camp_action re-checks combat, stage and
## ownership at the moment of the move), then closes the panel. Arrival counts as already inside the
## camp, so it never pops the camp panel (Change 10 rule).
func _select_travel_stage(st: int) -> void:
    var owned: Array=sim.state.camps.get(str(st),[0])
    if owned.size()==1:
        _travel_to(st,int(owned[0]))
    else:
        travel_stage=st
        _open("travel_map")

func _travel_map_panel() -> void:
    _set_title(sim.catalog.stages[travel_stage-1].name)
    _text(tr("TRAVEL_MAP_HELP"),18)
    var map=preload("res://scripts/game/camp_picker.gd").new()
    map.sim=sim;map.stage_id=travel_stage
    map.custom_minimum_size=Vector2(0,420)
    map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    map.chosen.connect(func(camp: int)->void:_travel_to(travel_stage,camp))
    rows.add_child(map)
    var reason:=_teleport_reason()
    if reason!="":_text(tr(reason),18)
    _pinned(tr("TELEPORT_BACK"),func()->void:_open("world"),true,"",false,"",false)

func _travel_to(st: int,camp: int) -> bool:
    if not sim.campaign.camp_action(st,camp,true):return false
    teleport_target=[]
    world.follow_player()
    _close()
    _settle_camp()
    return true

## Why the Teleport picker cannot travel now ("" when it can): game locks, death and combat.
func _teleport_reason() -> String:
    var lock:=sim.action_lock_reason()
    if lock!="":return lock
    if sim.state.player.hp<=0:return "CANNOT_USE"
    if sim.campaign.in_combat():return "TRAVEL_COMBAT"
    return ""

## Change 11 destination picker, opened by a camp's Teleport: every owned camp on every reached map,
## the camp the player stands in marked and not selectable, one chosen target, Back to cancel.
func _teleport_panel() -> void:
    _set_title(tr("TELEPORT_TITLE"))
    _text(tr("TELEPORT_HELP"),17,Color(.8,.84,.9))
    var here:=_camp_at_player()
    var reason:=_teleport_reason()
    if reason!="":_text(tr(reason),18,Color(1,.72,.45))
    var choices:=0
    for st in range(1,int(sim.state.unlocked_stage)+1):
        var owned: Array=sim.state.camps.get(str(st),[0]).duplicate()
        owned.sort()
        for camp in owned:
            var current: bool=st==int(sim.state.stage) and int(camp)==here
            var chosen: bool=teleport_target==[st,int(camp)]
            if not current:choices+=1
            _teleport_row(st,int(camp),current,chosen)
    if choices==0:_text(tr("TELEPORT_NONE"),17,Color(.7,.75,.82))
    var valid: bool=teleport_target.size()==2 and not (int(teleport_target[0])==int(sim.state.stage) and int(teleport_target[1])==here)
    var block:=sim.campaign.travel_reason(int(teleport_target[0]),int(teleport_target[1])) if valid else "TELEPORT_PICK"
    _pinned(tr("TELEPORT_BACK"),func()->void:teleport_target=[];_open("camp"),true,"",false,"teleport_back",false)
    var label:=tr("TELEPORT_GO") % [sim.catalog.stages[int(teleport_target[0])-1].name,int(teleport_target[1])+1] if valid else tr("TELEPORT_PICK")
    _pinned(label,func()->void:
        if teleport_target.size()==2:_travel_to(int(teleport_target[0]),int(teleport_target[1])),block=="",block,true,"teleport_go")

func _teleport_row(st: int,camp: int,current: bool,chosen: bool) -> void:
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    rows.add_child(card)
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",10)
    card.add_child(line)
    _card_icon(line,_art(249),Color(1,.86,.5) if chosen else (Color(.55,.55,.55) if current else Color.WHITE))
    var text:=VBoxContainer.new()
    text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    line.add_child(text)
    _card_line(text,tr("TELEPORT_DESTINATION") % [sim.catalog.stages[st-1].name,camp+1],20,Color(1,.86,.5) if chosen else Color.WHITE)
    var status:="TELEPORT_HERE" if current else ("TELEPORT_CHOSEN" if chosen else ("TELEPORT_THIS_MAP" if st==int(sim.state.stage) else "TELEPORT_OTHER_MAP"))
    _card_line(text,tr(status),17,Color(.7,.75,.82) if current else (Color(1,.86,.5) if chosen else Color(.6,1,.75)))
    if current:return
    var pick:=_inline_button(tr("TELEPORT_CHOOSE") if not chosen else "✓",func()->void:teleport_target=[st,camp],true,"",line,chosen)
    pick.set_meta("guide","teleport_%d_%d" % [st,camp])

func _camp_row(i: int,picker:=false) -> void:
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
        if picker:
            # Change 11: a camp's Teleport opens the destination picker (it used to travel to itself).
            var lock:=_teleport_reason()
            _inline_button(tr("CAMP_TELEPORT"),func()->void:teleport_target=[];_open("teleport"),lock=="",lock,line,false).set_meta("guide","camp_teleport")
        else:
            var reason: String=sim.campaign.travel_reason(st,i)
            if i==_camp_at_player():reason="TELEPORT_HERE"
            _inline_button(tr("CAMP_TRAVEL"),func()->void:_travel_to(st,i),reason=="",reason,line,false)

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
        SaveService.mark_committed()
        AudioService.play("ui_click")
        if sheet.visible:_refresh_panel())
    return button

## A tapped camp in the world: unlock, select and travel stay separate actions.
func _camp_panel() -> void:
    _set_title(tr("CAMP_NAME") % (selected_camp+1))
    _text(tr("CAMP_HELP"),18,Color(.8,.84,.9))
    _camp_row(selected_camp,true)

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
        [tr("STATS_CARDS"),"%d / %d" % [sim.state.owned_cards.size(),sim.catalog.campaign.cards.size()]]]+_mastery_stats())
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
        [tr("STAT_REGEN_PCT"),tr("STATS_RECOVERY_VALUE") % [fmt_value(float(s.regen_pct)*100),fmt_value(float(s.regen_pct)*float(s.hp))]],
        [tr("STATS_RESPAWN"),tr("SECONDS_VALUE") % fmt_value(sim.player_upgrade_value("respawn"))]])
    var boosts: Array=[
        [tr("STATS_PRESTIGE_HP"),"×"+fmt_value(sim.card("hp"))],
        [tr("STATS_PRESTIGE_DAMAGE"),"×"+fmt_value(sim.card("damage"))],
        [tr("STATS_MOVEMENT"),"+"+fmt_value((sim.campaign.move_speed()/90.0-1.0)*100)+"%"],
        [tr("STATS_STORED_SHARE"),tr("STATS_STORED_SHARE_VALUE") % [fmt_value(float(sim.catalog.progression.stored_weapon_factor)*100),fmt_value(float(sim.catalog.progression.stored_outfit_factor)*100)]]]
    if sim.campaign.bonus("equipped")>0:boosts.append([tr("STATS_EQUIPPED_BONUS"),"+"+fmt(sim.campaign.bonus("equipped")*100)+"%"])
    var mastery: Dictionary=sim.campaign.mastery.rewards()
    if not mastery.is_empty():boosts.append([tr("STATS_MASTERY"),mastery_reward_text(mastery)])
    for id in sim.supply_ids():
        if sim.buff_time(id)>0:boosts.append([sim.catalog.display_name(id),tr("STATS_SUPPLY_VALUE") % [_supply_amount(id,sim.buff_power(id)),ceili(sim.buff_time(id))]])
    _stat_section(tr("STATS_SECTION_BOOSTS"),boosts)
    # Change 10: HP and damage built up source by source (playbook 17.2), from the same parts and
    # multiplier stats() uses; the other stats list what each source adds before caps.
    _breakdown_section("hp")
    _breakdown_section("damage")
    var sources: Array=[]
    for source in sim.stat_sources():
        var values: Dictionary=sim.stat_sources()[source]
        var parts: Array=[]
        for key in ["defense","crit","crit_damage","speed","lifesteal","regen","regen_pct"]:
            if _meaningful(key,float(values.get(key,0.0))):parts.append(_short_stat(key,float(values[key])))
        if not parts.is_empty():sources.append([_source_label(source,""),", ".join(parts)])
    _stat_section(tr("STAT_SOURCES_OTHER"),sources)
    # Active play only (no pause, background, offline or prestige-choice time); see simulation.step.
    _stat_section(tr("STATS_SECTION_TIME"),[
        [tr("STATS_TIME_TOTAL"),fmt_duration(float(sim.state.get("playtime_total",0.0)))],
        [tr("STATS_TIME_RUN"),fmt_duration(float(sim.state.get("playtime_run",0.0)))]])
    _text(tr("STAT_CAPS_NOTE"),16,Color(.7,.75,.82))

## Where effective HP or damage comes from: each additive source, the prestige multiplier and the
## total combat uses (sim.stat_breakdown). Damage adds the per-hit modifiers that are not in it.
func _breakdown_section(key: String) -> void:
    var b: Dictionary=sim.stat_breakdown(key)
    var entries: Array=[]
    for part in b.parts:entries.append([_source_label(str(part[0]),key),"+"+fmt_value(float(part[1]))])
    if not is_equal_approx(float(b.multiplier),1.0):
        entries.append([tr("BREAKDOWN_SUBTOTAL"),fmt_value(float(b.subtotal))])
        entries.append([tr("BREAKDOWN_PRESTIGE"),"×%s  (+%s)" % [fmt_value(float(b.multiplier)),fmt_value(float(b.total)-float(b.subtotal))]])
    entries.append([tr("BREAKDOWN_TOTAL"),fmt_value(float(b.total))])
    _stat_section(tr("BREAKDOWN_HP" if key=="hp" else "BREAKDOWN_DAMAGE"),entries)
    var extra: Array=_per_hit_modifiers() if key=="damage" else _damage_taken_modifiers()
    if not extra.is_empty():_stat_section(tr("BREAKDOWN_PER_HIT" if key=="damage" else "BREAKDOWN_TAKEN"),extra)

## Source names with what they mean for HP / damage (levels count and per-level value, stored shares).
func _source_label(source: String,key: String) -> String:
    match source:
        "SOURCE_LEVEL":
            var per:=float(sim.catalog.progression.hp_per_level if key=="hp" else sim.catalog.progression.damage_per_level)
            if key in ["hp","damage"]:return tr("SOURCE_LEVEL_DETAIL") % [int(sim.state.player_level)-1,fmt_value(per)]
        "SOURCE_STORED":
            return tr("SOURCE_STORED_DETAIL") % [fmt_value(float(sim.catalog.progression.stored_outfit_factor)*100),fmt_value(float(sim.catalog.progression.stored_weapon_factor)*100)]
        "SOURCE_EQUIPPED":
            if sim.campaign.bonus("equipped")>0:return tr("SOURCE_EQUIPPED_DETAIL") % fmt_value(sim.campaign.bonus("equipped")*100)
    return tr(source)

## Damage modifiers applied per hit (not in the Damage total): kill milestones of the current enemy
## type, prestige bonuses against normal enemies or bosses and an active Focus.
func _per_hit_modifiers() -> Array:
    var result: Array=[]
    var g:=combat_group
    if g in range(sim.catalog.groups.size()) and sim.campaign.discovered(g) and sim.achievement_damage(g)>0:
        result.append([tr("PER_HIT_MILESTONES") % sim.catalog.groups[g].name,"+"+fmt_value(sim.achievement_damage(g)*100)+"%"])
    for pair in [["normal_damage","PER_HIT_NORMAL"],["boss_damage","PER_HIT_BOSS"]]:
        if sim.campaign.bonus(pair[0])>0:result.append([tr(pair[1]),"+"+fmt_value(sim.campaign.bonus(pair[0])*100)+"%"])
    if float(sim.state.player.get("focus_time",0))>0:
        result.append([tr("PER_HIT_FOCUS") % ceili(float(sim.state.player.focus_time)),"+"+fmt_value(float(sim.state.player.get("focus_power",.15))*100)+"%"])
    return result

## Prestige guard cards: damage taken from every enemy / from bosses (they reduce hits, not HP).
func _damage_taken_modifiers() -> Array:
    var result: Array=[]
    for pair in [["guard","TAKEN_GUARD"],["boss_guard","TAKEN_BOSS_GUARD"]]:
        if sim.campaign.bonus(pair[0])>0:result.append([tr(pair[1]),"−"+fmt_value(sim.campaign.bonus(pair[0])*100)+"%"])
    return result

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
    if key=="regen_pct":return "+%s%% %s" % [fmt_value(value*100),tr("STATS_SHORT_REGEN_PCT")]
    if key in ["crit","lifesteal","speed"]:return "+%s%% %s" % [fmt(value*100),tr("STATS_SHORT_"+key.to_upper())]
    if key=="crit_damage":return "+%s%% %s" % [fmt(value*100),tr("STATS_SHORT_"+key.to_upper())]
    return "+%s %s" % [fmt(value),tr("STATS_SHORT_"+key.to_upper())]

## Compact Android-friendly duration: 2h 05m, 4m 09s, 37s.
static func fmt_duration(seconds: float) -> String:
    var total:=int(floorf(maxf(0,seconds)))
    var h:=total/3600;var m:=(total%3600)/60;var sec:=total%60
    if h>0:return TranslationServer.translate("DURATION_HOURS_MINUTES") % [h,m]
    if m>0:return TranslationServer.translate("DURATION_MINUTES_SECONDS") % [m,sec]
    return TranslationServer.translate("DURATION_SECONDS") % sec

func _stat_text(key: String,value: float,bonus: bool=false) -> String:
    if key=="regen_pct":return "%s  %s%% %s" % [tr("STAT_REGEN_PCT"),fmt_value(value*100),tr("MAX_HP_PER_SECOND")]
    if key in ["crit","lifesteal","speed","coin_bonus"]:
        return "%s  %s%%" % [tr("STAT_"+key.to_upper()),fmt(value*100)]
    if key=="crit_damage":
        return ("%s  %s%%" % [tr("STAT_"+key.to_upper()),fmt(value*100)]) if bonus else ("%s  ×%s" % [tr("STAT_"+key.to_upper()),fmt(value)])
    return "%s  %s%s" % [tr("STAT_"+key.to_upper()),fmt(value)," "+tr("HP_PER_SECOND") if key=="regen" else ""]

func _settings_panel() -> void:
    _inventory_zoom_controls()
    _joystick_controls()
    var row:=HFlowContainer.new()
    row.add_theme_constant_override("h_separation",8)
    row.add_theme_constant_override("v_separation",8)
    rows.add_child(row)
    # Stats moved here from the navigation bar (Change 8); Player Upgrades took its place.
    _action(tr("STATS_OPEN"),func()->void:_open("stats"),true,"",row).set_meta("guide","open_stats")
    _action(tr("LOOT_HISTORY"),func()->void:_open("history"),true,"",row)
    _action(tr("SAVE_NOW"),func()->void:if SaveService.save_now():_event("SAVED"),true,"",row)
    # Change 41: one Discord button beside them (no section of its own); the invite lives in
    # resources/game/external_links.tres. A failed launch says so and changes nothing else.
    _action(tr("DISCORD"),_open_discord,true,"",row).set_meta("guide","discord")
    for button in row.get_children():
        button.size_flags_horizontal=0;button.custom_minimum_size=Vector2(300,64)
    # Change 16: Help opens the Basic tutorial as a page to read (it changes no progress, discovery or
    # revealed menu). "Choose guidance again" and "Show all menus now" are gone from the player's
    # Settings; onboarding.reveal_all stays for probes.
    _section(tr("SECTION_TUTORIAL"))
    _action(tr("HELP"),func()->void:_open("help"),true,"").set_meta("guide","help")
    # Change 35: a permanent, unprompted review action for the build's storefront (absent when the
    # build declares none). Opening it also settles the automatic invitation.
    var store: String=sim.campaign.review.channel()
    if store!="":
        _section(tr("SECTION_FEEDBACK"))
        _action(tr(sim.campaign.review.channels.cta(store)),func()->void:
            if not sim.campaign.review.open_store():_say(tr("REVIEW_OPEN_FAILED")),true,"").set_meta("guide","review_store")
    # Change 12: music and sound-effect volumes (0 = silent) and two independent mutes.
    _section(tr("SECTION_AUDIO"))
    _volume_row("MUSIC_VOLUME",SettingsState.music_volume,SettingsState.set_music_volume)
    _volume_row("SFX_VOLUME",SettingsState.sfx_volume,SettingsState.set_sfx_volume)
    var mutes:=HFlowContainer.new()
    mutes.add_theme_constant_override("h_separation",8)
    mutes.add_theme_constant_override("v_separation",8)
    rows.add_child(mutes)
    _action(tr("MUTE_GAMEPLAY_STATUS") % tr("ON" if SettingsState.mute_gameplay else "OFF"),func()->void:SettingsState.set_mute_gameplay(not SettingsState.mute_gameplay),true,"",mutes).set_meta("setting","mute_gameplay")
    _action(tr("MUTE_SPECIAL_STATUS") % tr("ON" if SettingsState.mute_special else "OFF"),func()->void:SettingsState.set_mute_special(not SettingsState.mute_special),true,"",mutes).set_meta("setting","mute_special")
    for button in mutes.get_children():
        button.size_flags_horizontal=0;button.custom_minimum_size=Vector2(300,64)
    _text(tr("AUDIO_HINT"),16,Color(.7,.75,.82))
    # Change 40 (Playbook 129.1, 132.2): one dropdown of the languages this build offers (Automatic first, then
    # each language in its own name); languages not enabled yet are not listed. It keeps its own items.
    _section(tr("SECTION_LANGUAGE"))
    rows.add_child(LANGUAGE_DROPDOWN.new())
    _section(tr("SECTION_DANGER"))
    _action(tr("HARD_RESET"),func()->void:_confirm(tr("RESET_CONFIRM"),func()->void:SaveService.hard_reset();_close()))
    _text(tr("CREDITS"),17,Color(.7,.75,.82))

func _open_discord() -> void:
    if not EXTERNAL_LINKS.open(EXTERNAL_LINKS.discord_url) and not EXTERNAL_LINKS.failure_was_repeat:
        _say(tr("LINK_OPEN_FAILED"))

## One volume control: "Music 80%" and a 0-100 slider. The label follows the slider directly;
## settings_changed persists it.
func _volume_row(key: String,value: float,setter: Callable) -> void:
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",12)
    rows.add_child(line)
    var label:=_text(tr(key) % roundi(value*100),18)
    label.custom_minimum_size=Vector2(220,0)
    label.size_flags_horizontal=Control.SIZE_FILL
    label.autowrap_mode=TextServer.AUTOWRAP_OFF
    rows.remove_child(label)
    line.add_child(label)
    var slider:=HSlider.new()
    slider.min_value=0;slider.max_value=100;slider.step=1
    slider.value=roundf(value*100)
    slider.custom_minimum_size=Vector2(0,56)
    slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    slider.scrollable=false
    slider.set_meta("setting",key)
    slider.value_changed.connect(func(v: float)->void:
        label.text=tr(key) % roundi(v)
        setter.call(v/100.0))
    line.add_child(slider)

## Help (Settings → Tutorial and help): the Basic overview deck (tutorial_guide.BASIC_DECK) as one
## page to read, so Basic and Help never describe the game differently (Change 25). Reading it changes
## nothing: no progress, discovery or menu reveal, and the guidance mode stays as chosen. In Guided, a
## card about a system its staged reveal has not opened yet is left out (no spoilers).
const HELP_ART:={"overview":60,"basic_target":1,"basic_gear":211,"basic_growth":147,"basic_world":249,"basic_prestige":212}
func _help_panel() -> void:
    _text(tr("HELP_INTRO"),17,Color(.8,.84,.9))
    for card in guide.BASIC_DECK:
        if guide.DECK_FEATURE.has(card) and not revealed(guide.DECK_FEATURE[card]):continue
        _info_card(tr("GUIDE_"+card.to_upper()),tr("GUIDE_"+card.to_upper()+"_DETAIL"),_art(int(HELP_ART.get(card,60))))
    _pinned(tr("HELP_BACK"),func()->void:_open("settings"),true,"",false,"help_back",false)

func _history_panel() -> void:
    for entry in sim.state.history:
        var message:=_history_text(entry)
        if not message.is_empty():_text(message,20)

func _history_text(entry: Dictionary) -> String:
    if entry.key=="HISTORY_CURRENCY":
        return tr("HISTORY_CURRENCY") % fmt_currency(entry.amount) if entry.amount>0 else ""
    return tr("HISTORY_ITEM") % [fmt_count(entry.amount),sim.catalog.display_name(entry.id)]

## Filters (Change 11, opened from the dock): the chosen category filters the gear grid and this list
## while the panel is open; closing it in any way shows every item again (_clear_filters).
func _inventory_panel() -> void:
    _inventory_zoom_controls()
    _set_title(tr("PANEL_FILTERS"))
    _pinned_equipment()
    _tabs(FILTER_TABS,inventory_filter,func(i: int)->void:inventory_filter=i;slot_signatures.clear();_refresh_slots())
    _text(tr("FILTERS_HINT"),16,Color(.7,.75,.82))
    _merge_all_action()
    for id in sim.state.items:
        if sim.quantity(id)>0 and (inventory_filter==0 or sim.catalog.items[id].kind==FILTER_KINDS[inventory_filter]):
            var b:=_action("%s · ×%s · ^%d" % [sim.catalog.display_name(id),fmt_count(sim.quantity(id)),sim.merge_level(id)],func()->void:selected=id;selected_slot=sim.state.supplies.find(id);_open("item"))
            b.icon=icon_cache.get(id);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",36)

## Merge All (Change 12): shown once the 5,000-Gem unlock is owned; free to use. It reports one
## aggregate result (one notice, one confirm) and is disabled with "Nothing to merge" when idle.
func _merge_all_action() -> void:
    if sim.level("merge_all")<1:
        _text(tr("MERGE_ALL_LOCKED_HINT"),16,Color(.7,.75,.82))
        return
    var copies:=sim.merge_all_copies()
    var lock:=sim.action_lock_reason()
    var b:=_action(tr("MERGE_ALL_BUTTON") % copies if copies>0 else tr("MERGE_ALL_BUTTON_IDLE"),func()->void:
        var result: Dictionary=sim.merge_all()
        if int(result.copies)>0:
            AudioService.play("ui_confirm")
            _say(tr("MERGE_ALL_DONE") % [int(result.copies),int(result.items)])
        _refresh_slots(),copies>0 and lock.is_empty(),lock if not lock.is_empty() else "NOTHING_TO_MERGE")
    if not b.disabled:b.theme_type_variation=&"Primary"
    b.set_meta("guide","merge_all")

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
        _apply_milestone_frame(button,id)
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

# ---------------------------------------------------------------- player level & growth (Change 10)

## Opened by tapping the level / XP bar: level, XP to the next level, what one level gives (the
## catalog's per-level values) and what the next level changes in effective HP and damage, read from
## the combat stat getter at both levels. The HP / damage breakdown follows; full Stats is one tap.
func _level_panel() -> void:
    var level:=int(sim.state.player_level)
    var capped: bool=level>=sim.max_level()
    var s:=sim.stats()
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    rows.add_child(card)
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",4)
    card.add_child(box)
    _card_line(box,tr("LEVEL_PANEL_LEVEL") % [level,sim.max_level()],22,Color.WHITE)
    var bar:=ProgressBar.new()
    bar.theme_type_variation=&"XP"
    bar.custom_minimum_size=Vector2(0,18)
    bar.show_percentage=false
    bar.max_value=1.0 if capped else sim.xp_required()
    bar.value=bar.max_value if capped else float(sim.state.xp)
    box.add_child(bar)
    if capped:_card_line(box,tr("LEVEL_PANEL_CAPPED"),18,Color(1,.86,.5))
    else:_card_line(box,tr("LEVEL_PANEL_XP") % [fmt_count(sim.state.xp),fmt_count(sim.xp_required()),fmt_count(sim.xp_required()-float(sim.state.xp)),level+1],18,Color(.8,.84,.9))
    var per_hp:=float(sim.catalog.progression.hp_per_level)
    var per_damage:=float(sim.catalog.progression.damage_per_level)
    var growth: Array=[[tr("LEVEL_PANEL_PER_LEVEL"),tr("LEVEL_PANEL_GAIN") % [fmt_value(per_hp),fmt_value(per_damage)]],
        [tr("LEVEL_PANEL_FROM_LEVELS") % (level-1),tr("LEVEL_PANEL_GAIN") % [fmt_value(per_hp*(level-1)),fmt_value(per_damage*(level-1))]]]
    if not capped:
        var next:=sim.stats_at_level(level+1)
        growth.append([tr("LEVEL_PANEL_NEXT_HP") % (level+1),tr("LEVEL_PANEL_NEXT_VALUE") % [fmt_value(s.hp),fmt_value(next.hp),fmt_value(float(next.hp)-float(s.hp))]])
        growth.append([tr("LEVEL_PANEL_NEXT_DAMAGE") % (level+1),tr("LEVEL_PANEL_NEXT_VALUE") % [fmt_value(s.damage),fmt_value(next.damage),fmt_value(float(next.damage)-float(s.damage))]])
    _stat_section(tr("LEVEL_PANEL_GROWTH"),growth)
    if sim.card("hp")>1.0 or sim.card("damage")>1.0:
        _text(tr("LEVEL_PANEL_PRESTIGE_NOTE") % [fmt_value(sim.card("hp")),fmt_value(sim.card("damage"))],16,Color(.7,.75,.82))
    _breakdown_section("hp")
    _breakdown_section("damage")
    _pinned(tr("STATS_OPEN"),func()->void:_open("stats"),true,"",false,"open_stats",false)

# ---------------------------------------------------------------- farming guide (Change 10)

## Map-by-map farming reference, reached from World. A map's entry opens once its Map Details is
## fully bought and every enemy type there has Reveal Stats and Reveal Drops. It shows only what the
## existing discovery rules already allow: undiscovered types and spots stay placeholders with no
## name, loadout or location. It draws no markers, reveals no fog and never travels.
func _farming_panel() -> void:
    if guide_stage>0 and bool(sim.campaign.farming_guide_status(guide_stage).open):
        _farming_map(guide_stage)
        return
    guide_stage=0
    _text(tr("FARMING_GUIDE_INTRO"),17,Color(.8,.84,.9))
    var unreached:=0
    for st in range(1,sim.catalog.stages.size()+1):
        var status: Dictionary=sim.campaign.farming_guide_status(st)
        if not status.reached:
            unreached+=1
            continue
        var card:=PanelContainer.new()
        card.theme_type_variation=&"Card"
        rows.add_child(card)
        var line:=HBoxContainer.new()
        line.add_theme_constant_override("separation",10)
        card.add_child(line)
        _card_icon(line,_art(249),Color.WHITE if status.open else Color(.55,.55,.55))
        var text:=VBoxContainer.new()
        text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        line.add_child(text)
        _card_line(text,str(sim.catalog.stages[st-1].name)+("  ·  "+tr("FARMING_YOU_ARE_HERE") if st==int(sim.state.stage) else ""),20,Color.WHITE)
        if status.open:
            _card_line(text,tr("FARMING_READY"),17,Color(.6,1,.75))
            var open:=_action(tr("FARMING_OPEN_MAP"),func()->void:
                guide_stage=st
                $Sheet/Margin/Content/Scroll.scroll_vertical=0,true,"",line)
            open.size_flags_horizontal=0
            open.custom_minimum_size=Vector2(120,64)
            open.set_meta("guide","farming_map_%d" % st)
        else:
            var missing: Array=[]
            if int(status.map_detail)<int(status.map_detail_cap):missing.append(tr("FARMING_NEED_DETAIL") % [int(status.map_detail),int(status.map_detail_cap)])
            if int(status.researched)<int(status.types):missing.append(tr("FARMING_NEED_RESEARCH") % [int(status.researched),int(status.types)])
            _card_line(text,tr("FARMING_LOCKED") % " · ".join(missing),17,Color(1,.72,.45))
    if unreached>0:_text(tr("FARMING_GUIDE_UNREACHED") % unreached,17,Color(.7,.75,.82))

# ---------------------------------------------------------------- Map Mastery (Change 15)

## Game completion and the title in Stats, once Map Mastery is revealed.
func _mastery_stats() -> Array:
    if not revealed("prestige"):return []
    var lines: Array=[[tr("STATS_COMPLETION"),"%d%%" % sim.campaign.mastery.game_percent()]]
    if sim.campaign.mastery.game_complete():lines.append([tr("STATS_TITLE"),tr("MASTER_FARMER_TITLE")])
    return lines

## One reward as a short line: "+10% coins · +1 pt Loot Chance".
func mastery_reward_text(reward: Dictionary) -> String:
    var parts: Array=[]
    for key in ["hp","damage","coins","xp","gear_chance","gem_chance"]:
        if not reward.has(key):continue
        var value: float=float(reward[key])*100
        parts.append(tr("MASTERY_REWARD_"+key.to_upper()) % fmt_value(value))
    return " · ".join(parts)

## A type the player has met: found this run, or defeated in any run. Others stay unnamed.
func _type_known(g: int) -> bool:
    return sim.campaign.discovered(g) or int(sim.state.group_kills[g])>0

func _item_known(id: String) -> bool:
    if sim.state.mastery.found.has(id):return true
    for g in range(sim.catalog.groups.size()):
        if not _type_known(g):continue
        var d: Dictionary=sim.catalog.groups[g]
        if d.loot.has(id) or (id.begins_with("skill_") and d.skills.has(id.trim_prefix("skill_"))):return true
    return false

func _mastery_panel() -> void:
    var m=sim.campaign.mastery
    if mastery_stage>0 and mastery_stage<=int(sim.state.unlocked_stage):
        _mastery_map(mastery_stage)
        return
    mastery_stage=0
    _text(tr("MASTERY_INTRO"),17,Color(.8,.84,.9))
    var total:=PanelContainer.new()
    total.theme_type_variation=&"Card"
    rows.add_child(total)
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",4)
    total.add_child(box)
    _card_line(box,tr("MASTERY_GAME") % m.game_percent(),22,Color(1,.86,.5))
    _mastery_bar(box,m.game_fraction())
    _card_line(box,(tr("MASTERY_GAME_REWARD_EARNED") if m.game_complete() else tr("MASTERY_GAME_REWARD")) % [tr("MASTER_FARMER_TITLE"),mastery_reward_text(m.rules.completion_reward)],17,Color(.6,1,.75) if m.game_complete() else Color(.8,.84,.9))
    for st in range(1,sim.catalog.stages.size()+1):
        var reached: bool=st<=int(sim.state.unlocked_stage)
        var card:=PanelContainer.new()
        card.theme_type_variation=&"Card"
        rows.add_child(card)
        var line:=HBoxContainer.new()
        line.add_theme_constant_override("separation",10)
        card.add_child(line)
        _card_icon(line,_art(249),Color.WHITE if reached else Color(.45,.45,.5))
        var text:=VBoxContainer.new()
        text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        text.add_theme_constant_override("separation",2)
        line.add_child(text)
        var done: bool=m.map_complete(st)
        _card_line(text,("✓ " if done else "")+str(sim.catalog.stages[st-1].name)+"  ·  %d%%" % m.map_percent(st),20,Color(.5,1,.65) if done else Color.WHITE)
        if reached:_mastery_bar(text,m.map_fraction(st))
        _card_line(text,(tr("MASTERY_REWARD_EARNED") if done else tr("MASTERY_REWARD")) % mastery_reward_text(m.rules.map_rewards[st-1]),17,Color(.6,1,.75) if done else Color(.8,.84,.9))
        if reached:
            var open:=_action(tr("MASTERY_DETAILS"),func()->void:
                mastery_stage=st
                $Sheet/Margin/Content/Scroll.scroll_vertical=0,true,"",line)
            open.size_flags_horizontal=0
            open.custom_minimum_size=Vector2(120,64)
            open.set_meta("guide","mastery_map_%d" % st)
        else:_card_line(text,tr("MASTERY_NOT_REACHED"),17,Color(.7,.75,.82))

func _mastery_bar(parent: Control,fraction: float) -> void:
    var bar:=ProgressBar.new()
    bar.theme_type_variation=&"XP"
    bar.custom_minimum_size=Vector2(0,14)
    bar.max_value=1000
    bar.value=roundf(clampf(fraction,0,1)*1000)
    bar.show_percentage=false
    parent.add_child(bar)

## One map: its five categories with progress and exactly what remains (unmet types stay unnamed).
func _mastery_map(st: int) -> void:
    var m=sim.campaign.mastery
    _set_title(tr("MASTERY_MAP_TITLE") % sim.catalog.stages[st-1].name)
    _action(tr("MASTERY_BACK"),func()->void:mastery_stage=0;$Sheet/Margin/Content/Scroll.scroll_vertical=0).set_meta("guide","mastery_back")
    var done: bool=m.map_complete(st)
    _text("%d%%  ·  " % m.map_percent(st)+((tr("MASTERY_REWARD_EARNED") if done else tr("MASTERY_REWARD")) % mastery_reward_text(m.rules.map_rewards[st-1])),18,Color(.6,1,.75) if done else Color(1,.86,.5))
    for category in m.CATEGORIES:
        var o: Dictionary=m.objective(st,category)
        var complete: bool=bool(o.complete)
        var card:=PanelContainer.new()
        card.theme_type_variation=&"Card"
        rows.add_child(card)
        var line:=HBoxContainer.new()
        line.add_theme_constant_override("separation",10)
        card.add_child(line)
        _card_icon(line,_art(MASTERY_ART[category]),Color.WHITE if complete else Color(.75,.75,.8))
        var text:=VBoxContainer.new()
        text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        text.add_theme_constant_override("separation",2)
        line.add_child(text)
        _card_line(text,("✓ " if complete else "")+tr("MASTERY_"+category.to_upper())+"  ·  %d / %d" % [int(o.done),int(o.total)],20,Color(.5,1,.65) if complete else Color.WHITE)
        _card_line(text,tr("MASTERY_"+category.to_upper()+"_RULE") % _mastery_rule_values(category),16,Color(.75,.8,.87))
        if complete:continue
        _mastery_bar(text,float(o.fraction))
        var missing: Array=[]
        for part in o.parts:
            if int(part[2])<int(part[3]):missing.append(_mastery_missing(st,part))
        var shown: Array=missing.slice(0,6)
        if missing.size()>6:shown.append(tr("MASTERY_MORE") % (missing.size()-6))
        _card_line(text,"\n".join(shown),17,Color(1,.86,.5))

func _mastery_rule_values(category: String) -> Array:
    var r=sim.campaign.mastery.rules
    match category:
        "hunt":return [int(sim.catalog.progression.achievements.kills[r.hunt_milestone-1]),int(sim.catalog.progression.achievements.boss_kills[r.hunt_milestone-1])]
        "forge":return [r.normal_outfit_merge,r.boss_outfit_merge]
    return []

## What one unmet requirement still needs, without naming anything the player has not met.
func _mastery_missing(st: int,part: Array) -> String:
    var kind: String=part[0]
    match kind:
        "explored":return tr("MASTERY_NEED_EXPLORED") % int(part[2])
        "camp":return tr("MASTERY_NEED_CAMP") % (int(part[1])+1)
        "kills":
            var g:=int(part[1])
            return tr("MASTERY_NEED_KILLS") % [sim.catalog.groups[g].name if _type_known(g) else tr("MASTERY_UNKNOWN_ENEMY"),fmt_count(part[2]),fmt_count(part[3])]
        "stats","drops":
            var g:=int(part[1])
            return tr("MASTERY_NEED_"+kind.to_upper()) % (sim.catalog.groups[g].name if _type_known(g) else tr("MASTERY_UNKNOWN_ENEMY"))
        "item":return tr("MASTERY_NEED_ITEM") % (sim.catalog.display_name(part[1]) if _item_known(part[1]) else tr("MASTERY_UNKNOWN_ITEM"))
        "merge":return tr("MASTERY_NEED_MERGE") % [sim.catalog.display_name(part[1]) if _item_known(part[1]) else tr("MASTERY_UNKNOWN_ITEM"),int(part[2]),int(part[3])]
        "evolve":
            var names: Array=[]
            for id in sim.campaign.mastery.content(st).weapons:names.append(sim.catalog.display_name(id) if _item_known(id) else "?")
            return tr("MASTERY_NEED_EVOLVE") % ", ".join(names)
    return ""

func _farming_map(st: int) -> void:
    var stage: Dictionary=sim.catalog.stages[st-1]
    _set_title(tr("FARMING_MAP_TITLE") % stage.name)
    _text(tr("FARMING_MAP_HINT"),16,Color(.7,.75,.82))
    for g in stage.groups:_farming_type(int(g))
    _pinned(tr("FARMING_BACK"),func()->void:
        guide_stage=0
        $Sheet/Margin/Content/Scroll.scroll_vertical=0,true,"",false,"farming_back",false)

## One enemy type: identity and rewards once, then one compact entry per spot. An undiscovered type
## or spot is a placeholder only.
func _farming_type(g: int) -> void:
    var d: Dictionary=sim.catalog.groups[g]
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    rows.add_child(card)
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",4)
    card.add_child(box)
    if not sim.campaign.discovered(g):
        _card_line(box,"? "+tr("FARMING_UNKNOWN_TYPE"),18,Color(.7,.75,.82))
        return
    var head:=HBoxContainer.new()
    head.add_theme_constant_override("separation",10)
    box.add_child(head)
    _card_icon(head,_portrait_texture(d.body))
    var text:=VBoxContainer.new()
    text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    head.add_child(text)
    _card_line(text,"%s  ·  %s%s" % [d.name,tr("ENEMY_LEVEL") % d.level,"  ·  "+tr("BOSS_LABEL") if d.boss else ""],19,Color(1,.86,.5) if d.boss else Color.WHITE)
    _card_line(text,tr("FARMING_REWARDS") % [fmt_currency(sim.coin_reward(g)),fmt_value(sim.gem_chance(g)*100),fmt_currency(sim.gem_amount(0,g)),fmt_value(sim.group_xp(g))],16,Color(1,.88,.55))
    var supplies: Array=[]
    for id in sim.supply_pool(g):supplies.append(tr("DROP_ITEM") % [sim.catalog.display_name(id),fmt_value(sim.supply_drop_chance(g,id)*100)])
    _card_line(text,tr("FARMING_SUPPLIES") % ", ".join(supplies),16,Color(.8,.84,.9))
    for v in sim.campaign.variants(g):_farming_spot(box,g,int(v))

func _farming_spot(box: VBoxContainer,g: int,v: int) -> void:
    if not sim.campaign.spot_discovered(g,v):
        _card_line(box,"· "+tr("FARMING_UNDISCOVERED_SPOT"),16,Color(.62,.66,.72))
        return
    var d: Dictionary=sim.catalog.groups[g]
    var def: Dictionary=sim.enemy_definition(g,v)
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",6)
    box.add_child(line)
    var kind_label:=Label.new()
    kind_label.text=tr("BOSS_LABEL") if d.boss else tr(["VARIANT_OUTFIT","VARIANT_WEAPON","VARIANT_BOTH","VARIANT_SKILL"][v])
    kind_label.custom_minimum_size.x=86
    kind_label.add_theme_font_size_override("font_size",17)
    kind_label.add_theme_color_override("font_color",Color(.6,1,.75))
    line.add_child(kind_label)
    var drops: Array=[]
    for id in def.loot:
        _card_icon(line,icon_cache.get(id),Color.WHITE,30)
        drops.append(tr("DROP_ITEM") % [sim.catalog.display_name(id),fmt_value(sim.gear_chance(g)*100)])
    for skill in def.skills:
        _card_icon(line,icon_cache.get("skill_"+str(skill)),Color.WHITE,30)
        drops.append(tr("DROP_ITEM") % [sim.catalog.display_name("skill_"+str(skill)),fmt_value(sim.group_upgrade_value("skill_drop",g)*100/def.skills.size())])
    var spacer:=Control.new()
    spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    line.add_child(spacer)
    var details:=_action(tr("FARMING_DETAILS"),func()->void:group=g;enemy_variant=v;enemy_tab=0;_open("enemy"),true,"",line)
    details.size_flags_horizontal=0
    details.custom_minimum_size=Vector2(112,56)
    details.add_theme_font_size_override("font_size",16)
    var bearing: Array=sim.campaign.spot_bearing(g,v)
    var where:=tr("FARMING_AT_CAMP") % (int(bearing[0])+1) if bearing[1]=="HERE" else tr("FARMING_LOCATION") % [tr("COMPASS_"+str(bearing[1])),int(bearing[0])+1,tr("DISTANCE_NEAR" if float(bearing[2])<=320 else ("DISTANCE_MID" if float(bearing[2])<=720 else "DISTANCE_FAR"))]
    _card_line(box,where,16,Color(.72,.9,1))
    if not drops.is_empty():_card_line(box,", ".join(drops),15,Color(.8,.84,.9))

# ---------------------------------------------------------------- missions

func _missions_panel() -> void:
    _section(tr("REGULAR_MISSIONS"))
    for i in range(sim.state.missions.size()):
        var m: Dictionary=sim.state.missions[i]
        sim.campaign.price_mission(m)
        var g: int=sim.campaign.group_id(str(m.target))
        var art: Texture2D=icon_cache.get(sim.catalog.groups[g].body) if g>=0 else _art(60)
        var ready: bool=not m.claimed and m.progress>=m.goal
        _task_card(art,tr("GOAL_"+str(m.kind).to_upper())+(" · "+sim.catalog.groups[g].name if g>=0 else ""),("%s / %s" % [fmt_currency(m.progress),fmt_cost(m.goal)] if str(m.kind)=="coins" else "%s / %s" % [fmt_count(m.progress),fmt_count(m.goal)]),m.progress,m.goal,m.coins,m.gems,func()->void:_confirmed(sim.campaign.claim_mission(i)),ready,"MISSION_NOT_READY",bool(m.claimed),["daily",i])
    _section(tr("MAIN_OBJECTIVES"))
    for i in sim.campaign.main_shown():
        var rewards: Array=sim.catalog.campaign.main_rewards[i]
        var done: bool=sim.state.main_ready.has(str(i))
        var p: Array=sim.campaign.main_progress(i)
        var value:=tr("MISSION_STATE_READY") if done else (tr("MAIN_HINT_%d" % i)+(": %d/%d" % [int(p[0]),int(p[1])] if int(p[1])>1 else ""))
        _task_card(_art(211),tr("MAIN_%d" % i),value,1.0 if done else float(p[0]),1.0 if done else float(p[1]),rewards[0],rewards[1],func()->void:_confirmed(sim.campaign.claim_main(i)),done,"MISSION_NOT_READY",false,["main",i])
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
    if sim.level("mission_claim")<=0:
        _text(tr("MISSION_AUTO_PURCHASE_HINT"),17,Color(.8,.84,.9))
    else:
        if not sim.state.mission_auto and not sim.state.tutorial.seen.has("mission_auto_enabled"):
            _text(tr("MISSION_AUTO_TOGGLE_HINT"),18,Color(1,.86,.5))
        # Change 24 (UI-04): the approved copy shows the state in capitals: "Automatic Claiming: OFF".
        var toggle:=_game_action(tr("MISSION_AUTO") % tr("STATE_ON_CAPS" if sim.state.mission_auto else "STATE_OFF_CAPS"),func()->void:
            sim.state.mission_auto=not sim.state.mission_auto
            if sim.state.mission_auto and not sim.state.tutorial.seen.has("mission_auto_enabled"):
                sim.state.tutorial.seen.append("mission_auto_enabled")
            sim.touch())
        toggle.set_meta("guide","mission_auto_toggle")

## Compact objective card: icon, title, progress bar with value, rewards and a claim button.
## States read at a glance: In progress (muted chip), Ready to claim (primary Claim button) and
## Claimed (dimmed card, green check, no button), so a claimed card never looks like a disabled claim.
func _task_card(art: Texture2D,title: String,value: String,progress: float,goal: float,coins: float,gems: float,claim: Callable,ready: bool,reason: String,claimed:=false,follow: Array=[]) -> void:
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
    _card_line(text,value,17,Color(.8,.84,.9))
    for pair in [[COIN,coins],[GEM,gems]]:
        if pair[1]<=0:continue
        _card_icon(reward,pair[0],Color.WHITE,24)
        _card_line(reward,fmt_currency(pair[1]),17,Color(1,.88,.55))
    if claimed:_card_line(text,tr("MISSION_WAIT_REFRESH"),16,Color(.7,.75,.82))
    # Change 16: Follow pins this mission to the bottom-right tracker (one at a time, independent of
    # the followed Prestige opportunity); Unfollow removes it.
    if not follow.is_empty() and (sim.campaign.can_follow_mission(follow[0],follow[1]) or sim.campaign.mission_followed(follow[0],follow[1])):
        var following: bool=sim.campaign.mission_followed(follow[0],follow[1])
        var pin:=_inline_button(tr("UNFOLLOW" if following else "FOLLOW"),func()->void:sim.campaign.toggle_follow_mission(follow[0],follow[1]),true,"",text,false)
        pin.custom_minimum_size=Vector2(132,52)
        pin.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
        pin.add_theme_font_size_override("font_size",17)
        pin.set_meta("guide","follow_mission")
    if ready:
        var button:=_inline_button(tr("CLAIM"),claim,true,reason,line,true)
        button.custom_minimum_size=Vector2(112,64)
        button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
        button.set_meta("guide","claim")
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
    # Only ready opportunities that can still award a card enter the batch (Change 8 gate).
    var ready:=sim.campaign.awardable_ids()
    _text(tr("PRESTIGE_INTRO"),18,Color(.8,.84,.9))
    # Change 10: the panel always opens; only the reset below is gated. Both conditions are listed
    # with their state, so a locked action always says what is still missing.
    _prestige_requirements(ready)
    _text(tr("PRESTIGE_READY_COUNT") % [ready.size(),sim.state.owned_cards.size(),sim.catalog.campaign.cards.size()],20,Color(1,.86,.5))
    var block:=sim.campaign.prestige_block_reason()
    var label:=tr("PRESTIGE_BATCH") % ready.size() if block.is_empty() else tr("PRESTIGE_ACTION_LOCKED") % tr(_prestige_block_short(block))
    _pinned(label,func()->void:_open_prestige_confirm(ready),block.is_empty(),block,true,"begin_prestige")
    # Ready first, then in progress, then completed history.
    var order: Array=[]
    for state_rank in [0,1,2]:
        for op in sim.catalog.campaign.opportunities:
            if not sim.state.opportunities.has(op.id):continue
            var done: bool=sim.state.consumed.has(op.id)
            var is_ready: bool=sim.state.opportunities[op.id].ready and not done
            if (state_rank==0 and is_ready) or (state_rank==1 and not is_ready and not done) or (state_rank==2 and done):order.append(op)
    if order.is_empty():_text(tr("PRESTIGE_NONE_DISCOVERED"),18,Color(.75,.8,.87))
    for st in range(1,int(sim.state.unlocked_stage)+1):
        _prestige_stage_section(st,order)
    _prestige_stage_section(0,order)
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

## Objectives spanning several maps appear under each relevant unlocked map.
## Counters describe consumed / authored opportunities, not the shared reward-card pool.
func prestige_stages(op: Dictionary) -> Array:
    var n:=int(str(op.id).right(1))-1
    match str(op.path):
        "hunter","challenge":
            var boss: String=sim.campaign.boss_goal(str(op.path),n+1)
            for st in sim.catalog.stages:
                for g in st.groups:
                    if str(sim.catalog.groups[g].id)==boss:return [int(st.id)]
        "expedition","collection":return [[1],[3],[7]][n]
        "regional":return [[1,2],[3,4],[7,8]][n]
        "trophy":return [[1,2],[3,4,5],[6,7,8]][n]
    return [0]

## Stage headings are touch-sized controls. Unchanged stages default open while a stage whose
## every objective has been consumed defaults closed; a manual choice overrides that default.
## Save the override rather than the computed default, so finishing a stage collapses it once.
func _prestige_stage_section(st: int,order: Array) -> void:
    var total:=0
    var completed:=0
    for op in sim.catalog.campaign.opportunities:
        if not prestige_stages(op).has(st):continue
        total+=1
        if sim.state.consumed.has(op.id):completed+=1
    if total==0:return
    var key:=str(st)
    var choices: Dictionary=sim.state.prestige_collapsed
    var collapsed: bool=bool(choices.get(key,completed==total))
    var title: String=tr("PRESTIGE_GENERAL") if st==0 else sim.catalog.stages[st-1].name
    var arrow: String="▶" if collapsed else "▼"
    var caption: String="%s  %s  %d/%d" % [arrow,title,completed,total]
    if completed==total:caption+="  ✓"
    var header:=_action(caption,func()->void:
        sim.state.prestige_collapsed[key]=not collapsed
        sim.touch())
    header.theme_type_variation=&"Primary" if collapsed and completed<total else &""
    header.tooltip_text=tr("PRESTIGE_STAGE_EXPAND" if collapsed else "PRESTIGE_STAGE_COLLAPSE")
    header.set_meta("prestige_stage",st)
    if collapsed:return
    for op in order:
        if prestige_stages(op).has(st):_opportunity_card(op)

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
    # Change 16: the same actionable line as the tracker (what to do, where, progress, what is next);
    # a collection also lists every outfit with its count.
    if not done and not ready:
        _card_line(text,sim.campaign.follow_summary(op.id),17,Color(1,.86,.5))
        if str(op.path)=="collection":_card_line(text,sim.campaign.opportunity_progress(op.id),16,Color(.8,.84,.9))
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
        if sim.state.follow!=op.id:follow.set_meta("guide","follow")
    if op.path in ["offering","collection"] and not ready:
        _inline_button(tr("SUBMIT_CONTRACT"),func()->void:sim.campaign.submit(op.id),true,"",row,true).custom_minimum_size=Vector2(200,64)
    if row.get_child_count()>0:content.add_child(row)
    else:row.free()

## The two reset conditions as a checklist: the first-boss defeat and one ready opportunity that can
## still award a card (a card is chosen during the reset, so owning one is never required).
func _prestige_requirements(ready: Array) -> void:
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    rows.add_child(card)
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",4)
    card.add_child(box)
    _card_line(box,tr("PRESTIGE_REQUIREMENTS"),18,Color(1,.86,.5))
    var boss_done: bool=sim.campaign.prestige_unlocked()
    _card_line(box,("✓ " if boss_done else "✗ ")+tr("PRESTIGE_REQ_BOSS"),18,Color(.5,1,.65) if boss_done else Color(1,.72,.45))
    var any_ready: bool=not sim.campaign.ready_ids().is_empty()
    var ready_text:=tr("PRESTIGE_REQ_READY")
    if any_ready and ready.is_empty():ready_text+="\n"+tr("NO_CARD_AVAILABLE")
    _card_line(box,("✓ " if not ready.is_empty() else "✗ ")+ready_text,18,Color(.5,1,.65) if not ready.is_empty() else Color(1,.72,.45))

## Short reason shown on the locked reset button itself.
func _prestige_block_short(reason: String) -> String:
    match reason:
        "PRESTIGE_LOCKED_FIRST_BOSS":return "PRESTIGE_NEEDS_BOSS"
        "NO_READY_PRESTIGE":return "PRESTIGE_NEEDS_READY"
        "NO_CARD_AVAILABLE":return "PRESTIGE_NEEDS_CARD"
    return reason

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

## Change 16: the Prestige confirmation is a milestone screen (scenes/game/prestige_confirm.tscn):
## the opportunities redeemed (path art and the cards still on offer), then what stays permanently
## and what this run resets, from the actual rules (campaign.choose_card's keep list).
func _open_prestige_confirm(ready: Array) -> void:
    var rows_: Array=[]
    for id in ready:
        var op: Dictionary=_opportunity(id)
        rows_.append({"icon":_path_art(str(op.path)),"text":str(op.name)+"  ·  "+tr("PRESTIGE_CONFIRM_CHOOSE_CARD")})
    # Change 50: the approved Prestige rules (Coins, every upgrade and every merge level are kept).
    var keep: Array=[tr("KEEP_LINE_CARDS") % sim.state.owned_cards.size(),tr("KEEP_LINE_COINS") % fmt_currency(sim.state.coins),tr("KEEP_LINE_GEMS") % fmt_currency(sim.state.gems),tr("KEEP_LINE_ALL_UPGRADES"),tr("KEEP_LINE_MERGES"),tr("KEEP_LINE_MAP"),tr("KEEP_LINE_PROGRESS"),tr("KEEP_LINE_MAIN_OBJECTIVES"),tr("KEEP_LINE_SETTINGS"),tr("KEEP_LINE_LEVEL") % int(sim.state.player_level)]
    var reset: Array=[tr("RESET_LINE_CARRIED_ITEMS"),tr("RESET_LINE_SUPPLY_MASTERY"),tr("RESET_LINE_MAPS"),tr("RESET_LINE_RUN_PROGRESS")]
    $PrestigeConfirm.open(tr("PRESTIGE_CONFIRM_SUBTITLE") % ready.size(),rows_,keep,reset)

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
        node.pressed.connect(func()->void:selected_card=id;AudioService.play("ui_click");_refresh_panel(true))
        row.add_child(node)
    var earned: Array=[]
    for id in batch.choices:earned.append(sim.catalog.campaign.cards[id].name)
    if not earned.is_empty():_text(tr("PRESTIGE_EARNED_SO_FAR") % ", ".join(earned),17,Color(.6,1,.75))
    _section(tr("PRESTIGE_KEEP_TITLE"))
    _text(tr("PRESTIGE_KEEP_ALL"),17,Color(.6,1,.75))
    _section(tr("PRESTIGE_RESET_TITLE"))
    _text(tr("PRESTIGE_RESET_RUN"),17,Color(1,.72,.45))
    if batch.choices.is_empty():
        _pinned(tr("CANCEL"),func()->void:sim.campaign.cancel_prestige();selected_card="",true,"",false,"",false)
    var card_name: String=sim.catalog.campaign.cards[selected_card].name if selected_card!="" else ""
    var last: bool=index==batch.ids.size()-1
    _pinned(tr("PRESTIGE_KEEP_CARD") % card_name if selected_card!="" else tr("PRESTIGE_PICK_CARD"),func()->void:
        var chosen:=selected_card
        _confirm(tr("PRESTIGE_CARD_CONFIRM_FINAL" if last else "PRESTIGE_CARD_CONFIRM") % sim.catalog.campaign.cards[chosen].name,func()->void:
            selected_card=""
            _confirmed(sim.prestige(chosen))),selected_card!="","PRESTIGE_PICK_CARD",true,"keep_card",false)

# ---------------------------------------------------------------- HUD helpers

## Change 15: only revealed systems show on the HUD. A navigation button keeps its place but stays
## invisible and untouchable until its system is revealed, so Settings never moves and each new
## button appears where it will stay. The minimap and its Map Explored chip come with World, Filters
## with Player Upgrades.
func _refresh_reveal() -> void:
    var nav: Node=dock.get_node("Navigation")
    for pair in [["World","world"],["Missions","missions"],["Prestige","prestige"],["Upgrades","upgrades"]]:
        var button: Button=nav.get_node(pair[0])
        var show: bool=revealed(pair[1])
        if button.disabled==show:
            button.disabled=not show
            button.modulate.a=1.0 if show else 0.0
            button.mouse_filter=Control.MOUSE_FILTER_STOP if show else Control.MOUSE_FILTER_IGNORE
            button.focus_mode=Control.FOCUS_ALL if show else Control.FOCUS_NONE
    var map_on: bool=revealed("world")
    for path in ["MiniMap","Explored"]:
        var node: Control=get_node("Safe/Layout/Map/"+path)
        if node.visible!=map_on:node.visible=map_on
    var filters: Control=dock.get_node("Inventory/GearColumn/Head/Filters")
    if filters.visible!=revealed("upgrades"):filters.visible=revealed("upgrades")

func _set_badge(badge: Label,show: bool,text: String,color: Color) -> void:
    if badge.visible!=show:badge.visible=show
    if not show:return
    if badge.text!=text:badge.text=text
    badge.add_theme_color_override("font_color",color)

func _refresh_badges() -> void:
    var nav: Node=dock.get_node("Navigation")
    # Change 14: the same eligibility as the Claim buttons the panel shows (campaign.has_claimable).
    # Change 15: a newly revealed menu shows a gold ✦ until it is opened once.
    var claim: bool=revealed("missions") and sim.campaign.has_claimable()
    _set_badge(nav.get_node("Missions/Badge"),claim or unopened("missions"),"!" if claim else "✦",Color(.45,1,.55) if claim else Color(1,.84,.34))
    for pair in [["World","world"],["Upgrades","upgrades"]]:
        _set_badge(nav.get_node(pair[0]+"/Badge"),unopened(pair[1]),"✦",Color(1,.84,.34))
    var ready: bool=not sim.campaign.ready_ids().is_empty() or not sim.state.prestige_batch.is_empty()
    var unseen:=false
    for id in sim.state.opportunities:
        if not sim.state.consumed.has(id) and not sim.state.tutorial.seen.has("op:"+str(id)+(":ready" if sim.state.opportunities[id].ready else "")):unseen=true
    # Change 10: the Prestige button is plain navigation in every state; the reset gate is shown
    # inside the panel, on its action.
    if unopened("prestige"):unseen=true
    var badge: Label=nav.get_node("Prestige/Badge")
    badge.visible=(ready or unseen) and revealed("prestige")
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
        row.text="+"+(fmt_currency(entry.amount) if entry.key=="HISTORY_CURRENCY" else fmt_count(entry.amount))
        row.tooltip_text=_history_text(entry)
        row.pressed.connect(func()->void:_open("history"))
        container.add_child(row)
        if container.get_child_count()==3:
            break
