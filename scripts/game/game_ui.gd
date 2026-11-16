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
const SORT_TABS:=["SORT_DEFAULT","SORT_TIER","SORT_EVOLUTION","SORT_QUANTITY"]
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
## Change 69: the real time (msec) the map's Auto Farm button last changed its group or spot: a tap right
## after it switched is ignored, so a thumb aimed at one group's button never toggles the next group's.
var quick_changed_msec: int=-100000
const QUICK_SETTLE_MSEC:=400
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
## Change 76: queued toast texts that are important (IMPORTANT_EVENTS): longer and never shortened.
var toast_important: Dictionary={}
## Change 63 (Playbook 18.8 arbitration): blocking modals first, the active Guided instruction next,
## ordinary notices after. The guide is never hidden or covered by a notice: toasts and banners move
## to free space beside it and wait in their queues (never dropped) only while there is none.
## sheet_reserved is the room kept above an open panel for the guide's caption. It is decided while the
## panel opens and kept until it closes (or another panel replaces it), so a lesson finishing inside the
## panel never resizes it under the player's finger.
var sheet_reserved:=0.0
var reserve_panel:=""
## Frames after a panel opens (or replaces another) in which the reserve is still measured, so the
## guide has evaluated the new panel before the size is kept.
const RESERVE_MEASURE_FRAMES:=3
var reserve_frames:=0
## A toast hidden before its time was up (a panel opened, or the guide left no room) resumes with
## the seconds it still had: {"text": String, "time": float}.
var toast_resume: Dictionary={}
## The banner / toast text last placed, so a placement is kept while it stays clear of the guide.
var banner_placed_for:=""
var toast_placed_for:=""
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
## Change 71: the main inventory's category and order live in SettingsState (saved, kept by close, travel,
## Prestige and relaunch). These properties keep the old names for the UI and the probes.
var inventory_filter: int:
    get:return SettingsState.inventory_filter
    set(value):SettingsState.set_inventory_view(value,SettingsState.inventory_sort)
var inventory_sort: int:
    get:return SettingsState.inventory_sort
    set(value):SettingsState.set_inventory_view(SettingsState.inventory_filter,value)
## Change 71: the dock gear grid's view: gear_view[p] is the backing index (sim.state.gear) shown by the slot
## node at position p. Sorting and filtering reorder this map only; owned items never move.
var gear_view: Array[int]=[]
var gear_view_key:=""
var slot_signatures: Dictionary={}
var tier_styles: Dictionary={}
var arrow_art: Texture2D
## Change 60: floating effective-stat deltas over the player (scripts/game/stat_feedback.gd).
var stat_feedback: Control
## Change 67: merge feedback (card burst, Merge All flash, dock glints) and the manual evolution panel.
## Both only present results the simulation has already committed.
var merge_fx: Control
## Change 81: the boss-key pickup over the map (scripts/game/key_fx.gd) and the Boss Keys chip's last text.
var key_fx: Control
var final_text:=""
## Change 83: the danger warning and the ending panel (final_dialog.gd), and the Green Alien's music, laughter and
## temporary recommended mix (final_audio.gd).
var final_dialog: Control
var final_audio: Node
var evolution_show: Control
## While a manual merge or evolution runs, the simulation's merged / evolved signals are collected
## here instead of being shown as automatic ones.
var fx_manual:=false
var fx_merges: Array=[]
var fx_evolutions: Array=[]
## Dock glints waiting for the slots to be laid out this frame: [id, strong, delay].
var pending_glints: Array=[]
## Merge All glints on at most this many slots (the pool bounds it as well).
const MERGE_ALL_GLINTS:=8
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
## Change 64: the map shown in the visual Teleport picker (0: the destination's or the player's map) and
## the picker's last fitted height (a rebuilt picker starts at it, so a tap never resizes the panel).
var teleport_stage:=0
var teleport_map_height:=0.0
const camp_picker=preload("res://scripts/game/camp_picker.gd")
## Last text written to the "Map Explored" chip above the minimap (written only when it changes).
var explored_text:=""
var gate_text:=""
## Map Mastery: 0 lists the maps, otherwise the stage whose page is open.
var mastery_stage:=0
var mastery_tracker: Control
## Change 74: the Change 72 fight form (pills and chips shortened while fighting) is gone: the followed objectives
## and the status chips always keep their full, descriptive form, and a fight never changes them.
## The zoom slider shows for this long after the zoom button is tapped or the slider is moved.
var zoom_open_time:=0.0
const ZOOM_OPEN_SECONDS:=4.0
## A recent-find row stays this long (simulation seconds), fading over the last LOOT_FADE.
const LOOT_SECONDS:=8.0
const LOOT_FADE:=1.0
var travel_stage:=1
## Change 15: panels that belong to a revealed system (campaign.onboarding). Every way into a panel
## goes through _open, so a hidden system cannot be reached from the minimap, the character, an
## enemy, a camp, the follow tracker or a banner either.
const PANEL_FEATURE:={"missions":"missions","enemy":"enemy","world":"world","camp":"world","teleport":"world","farming":"world","upgrades":"upgrades","filters":"upgrades","prestige":"prestige","mastery":"prestige"}
const MASTERY_ART:={"explore":249,"hunt":1,"research":60,"collect":147,"forge":211}

func _ready() -> void:
    # Change 78: MSDF text draws with linear filtering under the pixel-art UI (TextFilter).
    TextFilter.install(self,theme)
    sheet.z_index=10
    $Confirm.z_index=20
    $PrestigeConfirm.z_index=20
    $ReviewInvitation.z_index=20
    $Toast.z_index=25
    banner.z_index=15
    world.setup(sim)
    stat_feedback=preload("res://scripts/game/stat_feedback.gd").new()
    stat_feedback.name="StatFeedback"
    $Safe/Layout/Map.add_child(stat_feedback)
    stat_feedback.setup(self)
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
    # Change 71: the tracker stack follows a joystick move at once (not on the next HUD tick).
    SettingsState.settings_changed.connect(_layout_trackers,CONNECT_DEFERRED)
    _place_joystick()
    for id in sim.catalog.items:
        icon_cache[id]=sim.catalog.icon(id)
    arrow_art=cropped(ARROW)
    # Shape the panel type scale once at load: the first panel open otherwise pays the per-size
    # glyph cache (measured ~25 ms on the first Upgrades open).
    var font: Font=get_theme_default_font()
    var sample:="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;%+−→▲▼↑↓✓·/()^"
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
    $Safe/Layout/Map/QuickFarm.pressed.connect(_quick_farm_pressed)
    banner.opened.connect(func(kind: String)->void:
        if kind in ["discovered","ready","card","prestiged","prestige_unlocked"]:_open("prestige")
        elif kind in ["mastery_map","mastery_game"]:mastery_stage=0;_open("mastery"))
    sim.event.connect(_event)
    sim.auto_bought.connect(func(id: String,amount: int)->void:_say(tr("AUTO_BUY_DONE") % [amount,sim.catalog.display_name(id)]))
    # Change 77: Camp Supplies uses the toast lane (never a blocking panel).
    # Change 80: one notice per grant with the number actually given (1 names the supply; each unit is also in
    # the recent-finds feed through add_item).
    sim.camp_supply_granted.connect(func(ids: Array,_owed: int)->void:
        _say(tr("CAMP_SUPPLY_RECEIVED") % sim.catalog.display_name(str(ids[0])) if ids.size()==1 else tr("CAMP_SUPPLY_BATCH") % ids.size()))
    sim.camp_supply_waiting.connect(func()->void:_say(tr("CAMP_SUPPLY_WAITING")))
    SaveService.save_failed.connect(func(_reason: String)->void:_event("SAVE_ERROR"))
    get_viewport().size_changed.connect(_safe_area)
    # Change 25: a tracker first measured before its text wrapped reported a several-hundred-pixel
    # height for one HUD tick (covering the map); it is laid out again as soon as the wrap settles.
    # Reuse the established mission tracker style/size, without introducing a floating panel.
    mastery_tracker=$Safe/Layout/Map/MissionTracker.duplicate(0)
    mastery_tracker.name="MasteryTracker"
    mastery_tracker.hide()
    $Safe/Layout/Map.add_child(mastery_tracker)
    mastery_tracker.gui_input.connect(func(event: InputEvent)->void:
        if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
            var followed: Dictionary=sim.campaign.mastery.followed()
            if not followed.is_empty():
                mastery_stage=int(followed.stage);_open("mastery")
                accept_event())
    for tracker in [$Safe/Layout/Map/FollowTracker,$Safe/Layout/Map/MissionTracker,mastery_tracker]:
        tracker.minimum_size_changed.connect(_layout_trackers,CONNECT_DEFERRED)
    _build_hud_rails()
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
    # Change 67: merge feedback above the panel (never takes input) and the evolution panel above all
    # panels and the guide (it holds the world while open, like the card viewer).
    merge_fx=preload("res://scripts/game/merge_fx.gd").new()
    merge_fx.z_index=12
    add_child(merge_fx)
    evolution_show=preload("res://scripts/game/evolution_show.gd").new()
    evolution_show.z_index=19
    add_child(evolution_show)
    sim.merged.connect(_on_merged)
    sim.evolved.connect(_on_evolved)
    # Change 67 follow-up: the map-travel iris and the boss-defeated title over the map.
    _build_moment_overlays()
    sim.traveled.connect(func(map_changed: bool,_from: Vector2,_to: Vector2)->void:if map_changed:_open_iris())
    sim.boss_defeated.connect(_boss_title)
    # Change 81: a credited boss key flies from the fallen boss to the Boss Keys chip (presentation only).
    key_fx=preload("res://scripts/game/key_fx.gd").new()
    key_fx.name="KeyFx"
    $Safe/Layout/Map.add_child(key_fx)
    key_fx.project=func(at: Vector2)->Vector2:return (world.get_canvas_transform()*at)*$Safe/Layout/Map.size/Vector2(world.get_viewport_rect().size)
    key_fx.destination=_final_chip_target
    key_fx.avoid=_key_fx_avoid
    key_fx.bounds=_key_fx_bounds
    key_fx.arrived.connect(_key_arrived)
    sim.key_earned.connect(_key_earned)
    # Change 82: the Green Alien unsealing ceremony's message and the arena notices.
    sim.final_ceremony.connect(_final_ceremony)
    sim.arena_changed.connect(_arena_changed)
    sim.traveled.connect(func(map_changed: bool,_from: Vector2,_to: Vector2)->void:if map_changed:key_fx.send_all())
    # Change 83: the danger warning, Rage Mode, the victory celebration and ending, the recommended mix.
    final_dialog=preload("res://scripts/game/final_dialog.gd").new()
    final_dialog.name="FinalDialog"
    add_child(final_dialog)
    final_dialog.answered.connect(_final_answered)
    final_audio=preload("res://scripts/game/final_audio.gd").new()
    final_audio.name="FinalAudio"
    add_child(final_audio)
    final_audio.setup(sim)
    sim.final_warning.connect(_final_warning)
    sim.final_rage.connect(_final_rage)
    sim.final_victory.connect(_final_victory)
    _build_final_audio_chip()
    # Change 65: the one tutorial-card viewer (Basic opening and Help), above the panel and the guide.
    help_viewer=preload("res://scripts/game/help_viewer.gd").new()
    help_viewer.z_index=18
    add_child(help_viewer);help_viewer.setup(self)
    help_viewer.finished.connect(_help_finished)
    help_viewer.topics_requested.connect(func(category: String)->void:
        help_page=category if category!="" else "topics"
        if sheet.visible and panel=="help":_refresh_panel(true)
        else:_open("help"))
    _refresh_reveal()
    # Change 16: no development notice on a profile reset (the internal load result stays for probes).
    if SaveService.write_blocked:
        _event("SAVE_INCOMPATIBLE")

func _sync_zoom() -> void:
    $Safe/Layout/Map/Zoom/Slider.set_value_no_signal(SettingsState.camera_zoom)
    $Safe/Layout/Map/Zoom/Value.text="%.2f×" % SettingsState.camera_zoom
    var button: Button=$Safe/Layout/Map.get_node_or_null("ZoomButton")
    if button!=null:button.text="%.1f×" % SettingsState.camera_zoom

## Change 72: the parts of the edge-rail HUD that are built once: the one-line objective pills (the tracker
## nodes keep their names; the step sentence stays in the hidden Step label and in the panels), the icons of
## the three enemy controls, the zoom button with its slider popover, and the tappable Next Stage chip.
func _build_hud_rails() -> void:
    var map: Control=$Safe/Layout/Map
    for tracker in [map.get_node("FollowTracker"),map.get_node("MissionTracker"),mastery_tracker]:
        tracker.get_node("Row/Text/Step").hide()
        tracker.get_node("Row/Icon").custom_minimum_size=Vector2(28,28)
        tracker.get_node("Row").add_theme_constant_override("separation",6)
        var text: BoxContainer=tracker.get_node("Row/Text")
        text.alignment=BoxContainer.ALIGNMENT_CENTER
        var title: Label=tracker.get_node("Row/Text/Name")
        # Change 74: no text is cut: a title longer than the rail wraps onto a second line (the pill grows).
        title.clip_text=false
        title.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING
        title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        title.add_theme_font_size_override("font_size",16)
        var progress:=Label.new()
        progress.name="Progress"
        progress.mouse_filter=Control.MOUSE_FILTER_IGNORE
        progress.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
        progress.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
        progress.size_flags_horizontal=Control.SIZE_SHRINK_END
        progress.add_theme_font_size_override("font_size",17)
        progress.add_theme_color_override("font_outline_color",Color.BLACK)
        progress.add_theme_constant_override("outline_size",4)
        tracker.get_node("Row").add_child(progress)
    for pair in [["Achievement",_art(211)],["EnemyUpgrades",dock.get_node("Navigation/Upgrades").icon],["QuickFarm",_art(266)]]:
        var b: Button=map.get_node(pair[0])
        b.icon=pair[1]
        b.expand_icon=true
        # Change 74: the three controls are 30% larger (tile, icon and count text).
        b.add_theme_constant_override("icon_max_width",TILE_ICON)
        b.add_theme_font_size_override("font_size",TILE_FONT)
        b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
        b.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP
        b.autowrap_mode=TextServer.AUTOWRAP_OFF
        b.clip_text=true
    # Change 74: the enemy name is a third larger; a long translated name ends in an ellipsis inside its rail
    # rather than running under the zoom button (the width is set by _layout_hud).
    var enemy_name: Label=map.get_node("EnemySection")
    enemy_name.add_theme_font_size_override("font_size",ENEMY_NAME_FONT)
    enemy_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
    enemy_name.clip_text=true
    enemy_name.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    var upgrades: Button=map.get_node("EnemyUpgrades")
    upgrades.text=""
    upgrades.vertical_icon_alignment=VERTICAL_ALIGNMENT_CENTER
    upgrades.tooltip_text=tr("TAB_UPGRADES")
    var plate:=PanelContainer.new()
    plate.name="ZoomPlate"
    plate.theme_type_variation=&"Backing"
    plate.hide()
    map.add_child(plate)
    var zoom: Control=map.get_node("Zoom")
    zoom.hide()
    map.move_child(zoom,-1)
    _style_zoom_slider(zoom)
    var button:=Button.new()
    button.name="ZoomButton"
    button.focus_mode=Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size",16)
    button.tooltip_text=tr("CAMERA_ZOOM")
    button.set_meta("guide","zoom_button")
    map.add_child(button)
    map.move_child(button,plate.get_index())
    button.pressed.connect(_toggle_zoom)
    zoom.get_node("Slider").value_changed.connect(func(_value: float)->void:zoom_open_time=ZOOM_OPEN_SECONDS)
    zoom.get_node("Slider").drag_started.connect(func()->void:zoom_open_time=ZOOM_OPEN_SECONDS)
    var gate: Control=map.get_node("Gate")
    # Change 75: two lines (see _refresh_gate); Row/Label keeps the whole sentence for the tooltip and checks.
    gate.get_node("Row/Label").hide()
    var lines:=VBoxContainer.new()
    lines.name="Lines"
    lines.mouse_filter=Control.MOUSE_FILTER_IGNORE
    lines.alignment=BoxContainer.ALIGNMENT_CENTER
    lines.add_theme_constant_override("separation",-2)
    for pair in [["Caption",GATE_CAPTION_FONT,Color(.82,.86,.92)],["Value",CHIP_FONT,Color(1,.86,.5)]]:
        var label:=Label.new()
        label.name=pair[0]
        label.mouse_filter=Control.MOUSE_FILTER_IGNORE
        label.add_theme_font_size_override("font_size",pair[1])
        label.add_theme_color_override("font_color",pair[2])
        label.add_theme_color_override("font_outline_color",Color.BLACK)
        label.add_theme_constant_override("outline_size",4)
        lines.add_child(label)
    gate.get_node("Row").add_child(lines)
    gate.get_node("Row").alignment=BoxContainer.ALIGNMENT_BEGIN
    gate.mouse_filter=Control.MOUSE_FILTER_STOP
    gate.gui_input.connect(func(event: InputEvent)->void:
        if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
            accept_event();_open("world"))
    _build_final_chip()
    _sync_zoom()

## Change 81: the persistent final-boss objective, a chip under Next Stage in the same right rail, in the Gate
## chip's two-line form: "Final Boss" over "Boss Keys 4/13", then "Green Alien" over "Ready to Challenge" (gold).
## Shown on every map from the Green Alien's discovery until its defeat; a tap opens the Boss Keys section of
## Missions (the quest's explanation and the keys collected). The boss-key pickup flies to it.
func _build_final_chip() -> void:
    var map: Control=$Safe/Layout/Map
    var chip:=PanelContainer.new()
    chip.name="FinalKeys"
    chip.theme_type_variation=&"HudChip"
    chip.visible=false
    chip.mouse_filter=Control.MOUSE_FILTER_STOP
    chip.pivot_offset=Vector2(MINIMAP_SIDE*.5,STATUS_HEIGHTS.FinalKeys*.5)
    var row:=HBoxContainer.new()
    row.name="Row"
    row.mouse_filter=Control.MOUSE_FILTER_IGNORE
    row.add_theme_constant_override("separation",6)
    chip.add_child(row)
    var icon:=TextureRect.new()
    icon.name="Icon"
    icon.texture=preload("res://assets/ui/Key - Gold.png")
    icon.custom_minimum_size=Vector2(30,30)
    icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
    icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
    row.add_child(icon)
    var lines:=VBoxContainer.new()
    lines.name="Lines"
    lines.mouse_filter=Control.MOUSE_FILTER_IGNORE
    lines.alignment=BoxContainer.ALIGNMENT_CENTER
    lines.add_theme_constant_override("separation",-2)
    for pair in [["Caption",GATE_CAPTION_FONT,Color(.82,.86,.92)],["Value",CHIP_FONT,Color(1,.86,.5)]]:
        var label:=Label.new()
        label.name=pair[0]
        label.mouse_filter=Control.MOUSE_FILTER_IGNORE
        label.add_theme_font_size_override("font_size",pair[1])
        label.add_theme_color_override("font_color",pair[2])
        label.add_theme_color_override("font_outline_color",Color.BLACK)
        label.add_theme_constant_override("outline_size",4)
        lines.add_child(label)
    row.add_child(lines)
    map.add_child(chip)
    map.move_child(chip,map.get_node("Gate").get_index()+1)
    chip.gui_input.connect(func(event: InputEvent)->void:
        if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
            accept_event();_open_final_keys())

func _open_final_keys() -> void:
    _open("missions")
    _scroll_to_section(tr("FINAL_KEYS_SECTION"))

## Change 75: the zoom slider in the HUD's look: a dark rounded track with a lighter filled part, a round grabber
## in the plates' pale teal (the engine's white square looked foreign), the value in the chip font.
func _style_zoom_slider(zoom: Control) -> void:
    var slider: HSlider=zoom.get_node("Slider")
    slider.custom_minimum_size=Vector2(0,36)
    var track:=StyleBoxFlat.new()
    track.bg_color=Color(.08,.12,.16,.95)
    track.border_color=Color(.30,.40,.44)
    track.set_border_width_all(1)
    track.set_corner_radius_all(5)
    track.content_margin_top=5;track.content_margin_bottom=5
    var fill:=track.duplicate()
    fill.bg_color=Color(.40,.66,.70)
    fill.border_color=Color(.40,.66,.70)
    slider.add_theme_stylebox_override("slider",track)
    slider.add_theme_stylebox_override("grabber_area",fill)
    slider.add_theme_stylebox_override("grabber_area_highlight",fill)
    var knob: Texture2D=_round_knob(26,Color(.86,.93,.92),Color(.10,.16,.20))
    var hot: Texture2D=_round_knob(26,Color(1,1,1),Color(.10,.16,.20))
    slider.add_theme_icon_override("grabber",knob)
    slider.add_theme_icon_override("grabber_highlight",hot)
    var value: Label=zoom.get_node("Value")
    value.custom_minimum_size=Vector2(56,0)
    value.add_theme_font_size_override("font_size",CHIP_FONT)
    value.add_theme_constant_override("outline_size",4)

## A filled circle with an outline, drawn once (no new asset).
func _round_knob(side: int,fill: Color,edge: Color) -> Texture2D:
    var image:=Image.create(side,side,false,Image.FORMAT_RGBA8)
    var c:=Vector2(side,side)*.5
    for y in range(side):
        for x in range(side):
            var d:=Vector2(x+.5,y+.5).distance_to(c)
            var r:=side*.5-.5
            if d<=r-2.0:image.set_pixel(x,y,fill)
            elif d<=r:image.set_pixel(x,y,edge)
            elif d<=r+.8:image.set_pixel(x,y,Color(edge,clampf(r+.8-d,0,1)))
            else:image.set_pixel(x,y,Color(0,0,0,0))
    return ImageTexture.create_from_image(image)

## The zoom button opens the slider under the minimap for a few seconds (a second tap closes it). Pinch
## zooms as before and updates the button's value.
func _toggle_zoom() -> void:
    AudioService.play("ui_click")
    zoom_open_time=0.0 if $Safe/Layout/Map/Zoom.visible else ZOOM_OPEN_SECONDS
    _update_zoom_popover(0.0)
func _update_zoom_popover(dt: float) -> void:
    var zoom: Control=$Safe/Layout/Map/Zoom
    zoom_open_time=maxf(0.0,zoom_open_time-dt)
    var show: bool=zoom_open_time>0 and not sheet.visible
    if not show:zoom_open_time=0.0
    if zoom.visible==show:return
    zoom.visible=show
    $Safe/Layout/Map/ZoomPlate.visible=show
    _layout_hud()

func _safe_area() -> void:
    var i:=LayoutService.get_safe_area_insets_canvas()
    $Safe.add_theme_constant_override("margin_left",int(i.x))
    $Safe.add_theme_constant_override("margin_top",int(i.y))
    $Safe.add_theme_constant_override("margin_right",int(i.z))
    $Safe.add_theme_constant_override("margin_bottom",int(i.w))
    if $Confirm.visible:_layout_confirm()

func _process(dt: float) -> void:
    # Change 35: the review invitation holds the world while it is open (and only then).
    sim.held=$ReviewInvitation.is_open() or (help_viewer!=null and help_viewer.visible) or (evolution_show!=null and evolution_show.visible) or (final_dialog!=null and final_dialog.is_open())
    _update_final(dt)
    _offer_review(dt)
    gem_pickup_time=maxf(0,gem_pickup_time-dt)
    # Change 72: Gems found show as rows of the one recent-finds feed; the separate counter stays hidden.
    $Safe/Layout/Map/GemPickup.visible=false
    _update_zoom_popover(dt)
    world.update_camera()
    _update_skill_buttons()
    _update_supply_cooldowns()
    var keys:=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
    sim.movement=Vector2.ZERO if get_tree().paused or sim.suspended or modal_open() or sheet.visible else (stick_input if stick_input.length()>.1 else keys.limit_length())
    if stick_input.length()>.1 or keys.length()>.1:
        $Safe/Layout/Map/GestureSurface.cancel_gesture()
        world.follow_player()
    # Change 63: the guide's caption room above a panel of the current lesson, fixed per opening.
    _update_sheet_reserve()
    _update_iris(dt)
    _update_focus_countdown()
    _update_toast(dt)
    _layout_banner()
    # The View Camp button follows the camp on screen every frame (camera moves and pans).
    _refresh_view_camp()
    banner.held=sheet.visible or modal_open() or not sim.state.prestige_batch.is_empty() or sim.state.tutorial.mode=="pending" or (banner.pending()>0 and _banner_slot()==Vector2.INF)
    # Change 59: the loot reminder hand stands down under the same surfaces and the guide's card/chooser.
    world.update_reminder(banner.held or guide.card.visible or guide.chooser.visible)
    # Change 60: stat popups wait (and freeze) while the game is paused or something covers the map
    # (as the Change 59 hand, also under the guide's card and chooser).
    stat_feedback.update(dt,get_tree().paused or sim.suspended or sim.held or sheet.visible or modal_open() or not sim.state.prestige_batch.is_empty() or guide.card.visible or guide.chooser.visible)
    if settle_frames>0:
        settle_frames-=1
        _layout_sheet()
        if settle_frames==0:sheet.modulate.a=1.0
    panel_clock+=dt
    # Stats (playtime) and an item panel while a supply timer runs also tick without state revisions.
    var ticking: bool=panel=="stats" or (panel=="item" and (sim.state.boost_time>0 or not sim.state.buffs.is_empty() or sim.state.use_cd>0))
    # Change 74: a refresh waits while a finger drag or its fling is scrolling the sheet; it runs as soon as the
    # list comes to rest, so no control is replaced under the finger and no offset is restored mid-gesture.
    if sheet.visible and (panel_revision!=sim.revision or previous_pause!=get_tree().paused or (ticking and panel_clock>=1.0)) and panel_clock>=refresh_interval and not $Sheet/Margin/Content/Scroll.gesturing:
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
    _fade_loot()
    _refresh_badges()
    _refresh_follow_tracker()
    _refresh_mission_tracker()
    _refresh_mastery_tracker()
    _layout_trackers()
    _refresh_explored()
    _refresh_mastery_chip()
    _refresh_gate()
    _refresh_final_chip()
    _final_intro_check()
    _layout_hud()
    _offer_offline_claim()
    if last_revision!=sim.revision or previous_pause!=get_tree().paused:
        last_revision=sim.revision
        _refresh_slots()
    else:
        # Cheap when nothing changed; follows a resized dock without waiting for a state change.
        _layout_inventory()
    previous_pause=get_tree().paused
    _flush_glints()

## Change 63: the reserve is measured while the panel settles (the guide already knows its lesson then)
## and kept for that opening; it is released when the panel closes or another panel replaces it.
func _update_sheet_reserve() -> void:
    if not sheet.visible:
        reserve_panel="";sheet_reserved=0.0;reserve_frames=0;return
    if reserve_panel!=panel:reserve_panel=panel;reserve_frames=RESERVE_MEASURE_FRAMES
    elif sheet.modulate.a>=1.0 and reserve_frames<=0:return
    reserve_frames-=1
    var reserve: float=guide.sheet_reserve()
    if reserve!=sheet_reserved:
        sheet_reserved=reserve
        _layout_sheet()
## What a banner must keep clear of: the guide's caption, arrow and target frame. Change 72: the followed
## objectives now sit in the left rail at the top, which the banner passes over briefly like the rest of the
## two rails (were they blockers, the banner would be pushed down onto the player).
func _notice_blockers() -> Array:
    return guide.occupied_rects()

## Change 71: a toast also keeps clear of the HUD's two control columns (the left enemy controls and the
## top-right map stack). A banner does not use these: it is the top-of-screen milestone message and may pass
## over them briefly, as before.
func _toast_blockers(over_stick:=false) -> Array:
    var blocked: Array=_notice_blockers()
    var map: Control=$Safe/Layout/Map
    for tracker in [$Safe/Layout/Map/FollowTracker,$Safe/Layout/Map/MissionTracker,mastery_tracker]:
        if tracker!=null and tracker.visible:blocked.append(tracker.get_global_rect().grow(4))
    for path in ["EnemySection","Achievement","EnemyUpgrades","QuickFarm","MiniMap","ZoomButton","ZoomPlate","Mastery","Gate","ViewCamp"]:
        var node: Control=map.get_node(path)
        if node.visible:blocked.append(node.get_global_rect().grow(4))
    for row in map.get_node("History").get_children():
        if row.visible:blocked.append(row.get_global_rect().grow(4))
    # Change 74: toasts may use the bottom of the map, beside the joystick, never over it.
    if stick.visible and not over_stick:blocked.append(stick.get_global_rect().grow(4))
    return blocked

## Whether a placed toast is the one allowed over the joystick (bottom of the map, across the stick).
func _toast_over_stick(rect: Rect2) -> bool:
    return stick.visible and rect.intersects(stick.get_global_rect()) and rect.end.y>=$Safe/Layout/Map.get_global_rect().end.y-HUD_MARGIN-1
func _toast_overlaps(rect: Rect2,over_stick:=false) -> bool:
    if over_stick:return _toast_blockers(true).any(func(r):return r.intersects(rect))
    for r in _toast_blockers(_toast_over_stick(rect)):
        if r.intersects(rect):return true
    return false

func _notice_overlaps(rect: Rect2) -> bool:
    for r in _notice_blockers():
        if r.intersects(rect):return true
    return false

## Change 63: where the banner goes. Its usual place is the top of the safe area; when that would cover
## the guide's caption, arrow or target frame it moves down below what it would cover, staying over the
## map. Vector2.INF: no free place now, so the banner waits in its queue (held, nothing dropped).
func _banner_slot() -> Vector2:
    var rect:=_banner_rect()
    var blocked: Array=_notice_blockers()
    var map: Rect2=$Safe/Layout/Map.get_global_rect()
    for i in range(blocked.size()+1):
        var hit:=Rect2()
        for r in blocked:
            if r.intersects(rect) and (hit.size==Vector2.ZERO or r.end.y>hit.end.y):hit=r
        if hit.size==Vector2.ZERO:return rect.position
        rect.position.y=hit.end.y+8
        if rect.end.y>map.end.y-8:return Vector2.INF
    return Vector2.INF
func _banner_rect() -> Rect2:
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var available:=size.x-insets.x-insets.z-24
    var width:=minf(banner_max_width,available)
    var height:=maxf(maxf(banner.size.y,banner.get_node("Plate").get_combined_minimum_size().y),96)
    return Rect2(Vector2(insets.x+12+(available-width)*.5,insets.y+banner_top_gap),Vector2(width,height))

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
    # Change 63: never over the guide; _banner_slot moves it to free space (it is held when none). A
    # placed banner keeps its place while that stays clear, so it never wobbles with the bobbing arrow.
    var key:=str(banner.current.get("title",""))+"|"+str(banner.current.get("subtitle",""))
    if key==banner_placed_for and is_equal_approx(banner.position.x,at.x) and not _notice_overlaps(Rect2(banner.position,wanted)):return
    banner_placed_for=key
    var slot:=_banner_slot()
    if slot!=Vector2.INF:at=slot
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
    return $Confirm.visible or $PrestigeConfirm.visible or $ReviewInvitation.is_open() or (help_viewer!=null and help_viewer.visible) or (evolution_show!=null and evolution_show.visible) or (final_dialog!=null and final_dialog.is_open())

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
    # Change 79: a followed-objective pill may now be several lines tall, so the button never covers a pill or a
    # HUD rail control: it keeps its place under the camp name when that is free, else the first free place of
    # right of the pills (same height) and below them (same column), else below the pills.
    var blockers: Array=[]
    var pills: Rect2=Rect2()
    for tracker in [map.get_node("FollowTracker"),map.get_node("MissionTracker"),mastery_tracker]:
        if tracker==null or not tracker.visible:continue
        var r: Rect2=Rect2(tracker.position,tracker.size).grow(4)
        blockers.append(r)
        pills=r if pills.size==Vector2.ZERO else pills.merge(r)
    if not blockers.is_empty():
        for path in VIEW_CAMP_AVOID:
            var node: Control=map.get_node(path)
            if node.visible:blockers.append(Rect2(node.position,node.size).grow(4))
        var low:=map.size-button.size-Vector2(8,8)
        var free:=func(at: Vector2)->bool:
            var rect:=Rect2(at,button.size)
            return blockers.all(func(r: Rect2)->bool:return not rect.intersects(r))
        if not free.call(pos):
            var options: Array=[Vector2(pills.end.x,pos.y).clamp(Vector2(8,8),low),Vector2(pos.x,pills.end.y).clamp(Vector2(8,8),low)]
            var chosen: Vector2=options[1]
            for option in options:
                if free.call(option):chosen=option;break
            pos=chosen
    if not button.position.is_equal_approx(pos):button.position=pos

## Change 79: HUD rail controls View Camp keeps clear of once a followed-objective pill shows.
const VIEW_CAMP_AVOID:=["EnemySection","Achievement","EnemyUpgrades","QuickFarm","MiniMap","ZoomButton","ZoomPlate","Explored","Mastery","Gate","FinalKeys","FinalAudio"]

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
    if f.kind=="hunt":
        title=tr("HUNT_MISSION_TITLE");art=_art(1)
        ready=sim.campaign.hunt_ready()
    elif f.kind=="main":
        title=tr("MAIN_%d" % int(f.index))
        ready=sim.campaign.main_claimable(int(f.index))
    else:
        var m: Dictionary=sim.state.missions[int(f.index)]
        var g:=sim.campaign.group_id(str(m.target))
        # Change 79: the pill says what to do ("Defeat Teal Dinosaur (Summer II)", "Merge items"), never only a
        # name or a category (campaign.mission_action, the mission's own localized instruction).
        title=sim.campaign.mission_action(int(f.index))
        art=icon_cache.get(sim.catalog.groups[g].body) if g>=0 else _art(60)
        ready=m.progress>=m.goal
    var name_label: Label=tracker.get_node("Row/Text/Name")
    if name_label.text!=title:name_label.text=title
    var step: Label=tracker.get_node("Row/Text/Step")
    var text: String=sim.campaign.mission_follow_summary()
    if step.text!=text:step.text=text
    var color:=Color(.45,1,.55) if ready else Color(.94,.95,.97)
    if step.get_theme_color("font_color")!=color:step.add_theme_color_override("font_color",color)
    var amount:=""
    if f.kind=="hunt":amount="%d/%d" % [int(sim.campaign.hunt_progress()),sim.campaign.HUNT_GOAL]
    elif f.kind=="main":
        var p: Array=sim.campaign.main_progress(int(f.index))
        amount="%d/%d" % [int(p[0]),int(p[1])]
    else:
        var m: Dictionary=sim.state.missions[int(f.index)]
        amount=(fmt_currency(m.progress)+"/"+fmt_currency(m.goal)) if str(m.kind)=="coins" else (fmt_count(floorf(m.progress))+"/"+fmt_count(m.goal))
    _set_pill(tracker,amount,ready,text)
    var icon: TextureRect=tracker.get_node("Row/Icon")
    if icon.texture!=art:icon.texture=art
    if tracker.mouse_filter!=Control.MOUSE_FILTER_STOP:tracker.mouse_filter=Control.MOUSE_FILTER_STOP

## Change 72: a pill's right-hand value: the current requirement's progress, or Claim in green once it is ready
## (the same predicate as the panel's Claim button). The full step sentence is the pill's tooltip.
func _set_pill(tracker: Control,amount: String,ready: bool,sentence: String) -> void:
    var label: Label=tracker.get_node("Row/Progress")
    var text: String=tr("CLAIM") if ready else amount
    if label.text!=text:label.text=text
    var color:=Color(.45,1,.55) if ready else Color(.94,.95,.97)
    if label.get_theme_color("font_color")!=color:label.add_theme_color_override("font_color",color)
    if tracker.tooltip_text!=sentence:tracker.tooltip_text=sentence

## Change 72: the followed objectives are one-line pills in the left rail, under the enemy controls, from the
## top: Map Mastery, the mission, the Prestige opportunity. The rail's slots are fixed (the pills start at the
## same height whether or not the enemy controls show) and no longer depend on the joystick.
## Change 74: always the full form (icon, the objective's own name, progress); a fight changes nothing. A pill is
## as wide as its text needs, between the Achievements tile's width and the enemy controls' row (a longer name
## wraps onto a second line and the pill grows; nothing is cut), so a short objective leaves the map open.
const PILL_HEIGHT:=40.0
const PILL_GAP:=4.0
func _layout_trackers() -> void:
    var map: Control=$Safe/Layout/Map
    var y: float=HUD_MARGIN+ENEMY_LABEL_HEIGHT+TILE_HEIGHT+HUD_GAP
    var most: float=minf(LEFT_COLUMN_WIDTH,map.size.x-HUD_MARGIN*2)
    for tracker in [mastery_tracker,$Safe/Layout/Map/MissionTracker,$Safe/Layout/Map/FollowTracker]:
        if tracker==null or not tracker.visible:continue
        var title: Label=tracker.get_node("Row/Text/Name")
        var text_width: float=title.get_theme_font("font").get_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,title.get_theme_font_size("font_size")).x
        # The pill's own minimum without the title (a wrapping label asks for no width).
        var chrome: float=tracker.get_combined_minimum_size().x-title.get_combined_minimum_size().x
        var width: float=clampf(ceilf(chrome+text_width+4),minf(ACHIEVEMENT_WIDTH,most),most)
        # The wrapped title's height at the width it gets (measured, not read back a frame late).
        var room: float=maxf(1.0,width-chrome-4)
        var lines: float=title.get_theme_font("font").get_multiline_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,room,title.get_theme_font_size("font_size")).y
        # The rest of the pill's height without the title, whose own minimum reflects last frame's width.
        var chrome_height: float=tracker.get_combined_minimum_size().y-title.get_combined_minimum_size().y
        var height: float=maxf(PILL_HEIGHT,chrome_height+lines+2)
        _place(tracker,Rect2(HUD_MARGIN,y,width,height))
        y+=height+PILL_GAP

## Probe accessor: the vertical space between the left controls and the highest visible tracker (negative =
## overlap; INF when no tracker shows).
func tracker_clearance() -> float:
    var top:=INF
    for tracker in [$Safe/Layout/Map/FollowTracker,$Safe/Layout/Map/MissionTracker,mastery_tracker]:
        if tracker!=null and tracker.visible:top=minf(top,tracker.position.y)
    return top-left_column_bottom() if top!=INF else INF

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

## Change 72 (HUD declutter, Layout B): everything persistent sits in two rails along the top of the map, so
## the middle and lower map hold only the world and the joystick.
## Left rail: the enemy name, one row of its three controls (Achievements with its count, Upgrades, Auto Farm),
## then the followed objectives as one-line pills (_layout_trackers).
## Right rail: MINIMAP with the zoom button beside its upper part, Map Explored under it, then the Mastery and
## Next Stage chips (at least the minimap's width, growing leftward for a longer text, never shrinking the
## font) and the recent-finds feed, right-aligned. The zoom slider opens over the chips while it is used.
## Toasts use the free lane nearest the top (_toast_slot). Positions are written only when they change.
## Change 74: minimap 168 -> 220, enemy controls 58x62 -> 76x81 (Achievements 124 -> 162 wide), enemy name
## 18 -> 24 px, all at least 30% larger; Map Explored moved off the minimap to a caption under it. On the
## 720-wide portrait canvas the rails still leave the middle of the map clear (left rail ends at 338, the zoom
## button starts at 412).
const HUD_MARGIN:=12.0
const HUD_GAP:=8.0
const ENEMY_LABEL_HEIGHT:=34.0
const ENEMY_NAME_FONT:=24
const TILE_HEIGHT:=81.0
const TILE_SIDE:=76.0
const ACHIEVEMENT_WIDTH:=162.0
const TILE_GAP:=6.0
const TILE_ICON:=37
const TILE_FONT:=21
const ZOOM_BUTTON:=Vector2(68,48)
const CHIP_FONT:=17
const CAPTION_GAP:=4.0
## Change 75: the open zoom slider's plate: the Mastery chip's height plus the gap under it.
const ZOOM_PLATE_HEIGHT:=48.0
func _layout_hud() -> void:
    var map: Control=$Safe/Layout/Map
    var right: float=map.size.x-HUD_MARGIN
    var x: float=right-MINIMAP_SIDE
    var y: float=HUD_MARGIN
    _place(map.get_node("MiniMap"),Rect2(x,y,MINIMAP_SIDE,MINIMAP_SIDE))
    # The zoom button sits beside the minimap's upper part, just under the enemy name's row (Change 74: the top
    # band stays clear of the fight around the player more often than the minimap's lower edge, which the larger
    # map moved down, and the name keeps the whole width up to the minimap).
    var zoom_rect:=Rect2(x-HUD_GAP-ZOOM_BUTTON.x,HUD_MARGIN+ENEMY_LABEL_HEIGHT,ZOOM_BUTTON.x,ZOOM_BUTTON.y)
    _place(map.get_node("ZoomButton"),zoom_rect)
    # Map Explored is the minimap's caption, under it (Change 74: no longer over the map's lower edge): right-
    # aligned with the map, at least its width, growing leftward for a longer catalog text, never shrinking its
    # font (Playbook 143.6).
    y+=MINIMAP_SIDE+CAPTION_GAP
    var caption: float=maxf(MINIMAP_SIDE,map.get_node("Explored").get_combined_minimum_size().x)
    _place(map.get_node("Explored"),Rect2(right-caption,y,caption,STATUS_HEIGHTS.Explored))
    y+=STATUS_HEIGHTS.Explored+HUD_GAP-2
    var chips_top: float=y
    for path in ["Mastery","Gate","FinalKeys","FinalAudio"]:
        var node: Control=map.get_node(path)
        if not node.visible:continue
        var least: float=_chip_width(node) if node is Button else node.get_combined_minimum_size().x
        var size:=Vector2(clampf(least,MINIMAP_SIDE,map.size.x*.6),maxf(STATUS_HEIGHTS[path],node.get_combined_minimum_size().y))
        _place(node,Rect2(right-size.x,y,size.x,size.y))
        y+=size.y+PILL_GAP
        # Change 75: the open zoom slider takes the place of the chip it covers (the first one) for its few
        # seconds; the chip returns untouched.
        var alpha: float=0.0 if map.get_node("Zoom").visible and Rect2(right-MINIMAP_SIDE,chips_top,MINIMAP_SIDE,ZOOM_PLATE_HEIGHT).intersects(Rect2(right-size.x,y-size.y-PILL_GAP,size.x,size.y)) else 1.0
        if node.modulate.a!=alpha:node.modulate.a=alpha
    _place(map.get_node("History"),Rect2(right-HISTORY_WIDTH,y+2,HISTORY_WIDTH,136))
    var zoom: Control=map.get_node("Zoom")
    if zoom.visible:
        # Change 75: one slider row at the minimap's width (it used to stretch over both chips, 296 x 86).
        var plate:=Rect2(right-MINIMAP_SIDE,chips_top,MINIMAP_SIDE,ZOOM_PLATE_HEIGHT)
        _place(map.get_node("ZoomPlate"),plate)
        _place(zoom,plate.grow_individual(-10,0,-6,0))
    x=HUD_MARGIN
    # The name is as wide as its text, up to the minimap (the longest name in the 20 languages fits at 24 px;
    # a longer one would end in an ellipsis there).
    var enemy_name: Label=map.get_node("EnemySection")
    var name_room: float=maxf(LEFT_COLUMN_WIDTH,map.get_node("MiniMap").position.x-HUD_GAP-x)-2
    var name_width: float=ceilf(enemy_name.get_theme_font("font").get_string_size(enemy_name.text,HORIZONTAL_ALIGNMENT_LEFT,-1,ENEMY_NAME_FONT).x+enemy_name.get_theme_constant("outline_size")+4)
    _place(enemy_name,Rect2(x+2,HUD_MARGIN-4,clampf(name_width,1,name_room),ENEMY_LABEL_HEIGHT))
    y=HUD_MARGIN+ENEMY_LABEL_HEIGHT
    # Fixed slots (Playbook 19.1): each control keeps its place whether or not it shows right now.
    _place(map.get_node("Achievement"),Rect2(x,y,ACHIEVEMENT_WIDTH,TILE_HEIGHT))
    _place(map.get_node("EnemyUpgrades"),Rect2(x+ACHIEVEMENT_WIDTH+TILE_GAP,y,TILE_SIDE,TILE_HEIGHT))
    _place(map.get_node("QuickFarm"),Rect2(x+ACHIEVEMENT_WIDTH+TILE_GAP*2+TILE_SIDE,y,TILE_SIDE,TILE_HEIGHT))

## The width a chip button needs for its whole text at the chip font (its own minimum is 0: it trims).
func _chip_width(chip: Button) -> float:
    var font: Font=chip.get_theme_font("font")
    var style: StyleBox=chip.get_theme_stylebox("normal")
    var widest:=0.0
    for line in chip.text.split("\n"):widest=maxf(widest,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,CHIP_FONT).x)
    return ceilf(widest+style.get_minimum_size().x+chip.get_theme_constant("icon_max_width")+chip.get_theme_constant("h_separation")+8)

const MINIMAP_SIDE:=220.0
const STATUS_HEIGHTS:={"Mastery":44.0,"Explored":30.0,"Gate":52.0,"FinalKeys":52.0,"FinalAudio":48.0}
const GATE_CAPTION_FONT:=14
## The left rail's width (the three enemy controls in a row, and an objective pill): 162+6+76+6+76.
const LEFT_COLUMN_WIDTH:=ACHIEVEMENT_WIDTH+(TILE_GAP+TILE_SIDE)*2
## The recent-finds feed (right-aligned rows) keeps its Change 72 width.
const HISTORY_WIDTH:=252.0
func _place(node: Control,rect: Rect2,set_size:=true) -> void:
    if node.anchor_left!=0 or node.anchor_right!=0 or node.anchor_top!=0 or node.anchor_bottom!=0:
        node.set_anchors_preset(Control.PRESET_TOP_LEFT)
    if not node.position.is_equal_approx(rect.position):node.position=rect.position
    if set_size and not node.size.is_equal_approx(rect.size):node.size=rect.size

## The bottom of the left control column (map coordinates), for the trackers and probes.
func left_column_bottom() -> float:
    var bottom: float=HUD_MARGIN
    for path in ["EnemySection","Achievement","EnemyUpgrades","QuickFarm"]:
        var node: Control=$Safe/Layout/Map.get_node(path)
        if node.visible:bottom=maxf(bottom,node.position.y+node.size.y)
    return bottom

## The bottom of the top-right stack (map coordinates).
func map_stack_bottom() -> float:
    var bottom: float=HUD_MARGIN
    for path in ["MiniMap","Zoom","Mastery","Explored","Gate","FinalKeys","FinalAudio"]:
        var node: Control=$Safe/Layout/Map.get_node(path)
        if node.visible:bottom=maxf(bottom,node.position.y+node.size.y)
    return bottom

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
    # Change 74: the pill names what is being tracked now ("Space Helmet Outfit"), not the opportunity.
    # Change 79: with the action that is required ("Collect Space Helmet Outfit", "Defeat Teal Dinosaur"),
    # campaign.follow_action; only a ready opportunity keeps its own name (its pill says Claim).
    var action: String=sim.campaign.follow_action(id)
    var title: String=action if action!="" else str(op.name)
    if name_label.text!=title:name_label.text=title
    # Change 71: the compact tracker shows the current requirement and its progress only; the Prestige panel
    # keeps the full summary with the following step.
    var text: String=sim.campaign.follow_summary(id,true)
    if step.text!=text:step.text=text
    var color:=Color(.45,1,.55) if ready else Color(.94,.95,.97)
    if step.get_theme_color("font_color")!=color:step.add_theme_color_override("font_color",color)
    _set_pill(tracker,sim.campaign.follow_progress(id),ready,text)
    var icon: TextureRect=tracker.get_node("Row/Icon")
    # Change 16: the exact item a collection still needs, or the enemy the step names, else path art.
    var focus: Dictionary=sim.campaign.follow_focus(id)
    var art: Texture2D=_path_art(str(op.path))
    if focus.has("item"):art=icon_cache.get(focus.item)
    elif focus.has("group") and int(focus.group)>=0:art=icon_cache.get(sim.catalog.groups[int(focus.group)].body,art)
    if icon.texture!=art:icon.texture=art
    if tracker.mouse_filter!=Control.MOUSE_FILTER_STOP:tracker.mouse_filter=Control.MOUSE_FILTER_STOP

## One objective (Explore/Hunt/Research/Collect/Forge) can be followed from a reached map.
func _refresh_mastery_tracker() -> void:
    if mastery_tracker==null:return
    var f: Dictionary=sim.campaign.mastery.followed()
    var show: bool=not f.is_empty() and revealed("prestige") and sim.state.prestige_batch.is_empty()
    mastery_tracker.visible=show
    if not show:return
    var st:=int(f.stage);var category: String=f.category
    var objective: Dictionary=sim.campaign.mastery.objective(st,category)
    var label: Label=mastery_tracker.get_node("Row/Text/Name")
    # Change 74: the pill names the enemy or item the current requirement is about. Change 79: as an action
    # ("Defeat Teal Dinosaur", "Find Snorkeler Outfit", "Unlock Camp 2"), never a bare name or the category.
    var title:=str(sim.catalog.stages[st-1].name)+" · "+tr("MASTERY_"+category.to_upper())
    for part in objective.parts:
        if int(part[2])<int(part[3]):
            var action: String=_mastery_action(st,part)
            if action!="":title=action
            break
    if label.text!=title:label.text=title
    var step: Label=mastery_tracker.get_node("Row/Text/Step")
    # Change 71: like the other trackers, the current requirement with its progress, then the category's count.
    var summary:=""
    for part in objective.parts:
        if int(part[2])<int(part[3]):
            summary=_mastery_missing(st,part)+"  ·  "
            break
    summary+=tr("MASTERY_FOLLOW_PROGRESS") % [int(objective.done),int(objective.total)]
    if step.text!=summary:step.text=summary
    # Change 72: the pill shows the current requirement's own count (a percentage for exploration), else
    # the category's count.
    var amount:="%d/%d" % [int(objective.done),int(objective.total)]
    for part in objective.parts:
        if int(part[2])>=int(part[3]):continue
        if str(part[0])=="explored":amount="%d%%" % int(part[2])
        elif int(part[3])>1:amount=fmt_count(part[2])+"/"+fmt_count(part[3])
        break
    _set_pill(mastery_tracker,amount,false,summary)
    var icon: TextureRect=mastery_tracker.get_node("Row/Icon")
    var art: Texture2D=_art(MASTERY_ART[category])
    if icon.texture!=art:icon.texture=art
    mastery_tracker.mouse_filter=Control.MOUSE_FILTER_STOP

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
    # Change 75: shown on two lines, the place as a small caption over the count ("Next Stage" / "Bosses 0/1"),
    # so the chip keeps the minimap's width. Split at the catalog's own separator (" · " or ": "); a text
    # without one stays on one line.
    var lines: Array=gate_lines(text)
    node.get_node("Row/Lines/Caption").text=lines[0]
    node.get_node("Row/Lines/Caption").visible=lines[0]!=""
    node.get_node("Row/Lines/Value").text=lines[1]

## Change 75: the Next Stage text as [caption, main line] (caption "" when the text has no separator).
static func gate_lines(text: String) -> Array:
    for separator in [" · ",": "]:
        var at: int=text.find(separator)
        if at>0:
            # On its own line the count starts with a capital ("Verder: bazen 0/1" -> "Verder" / "Bazen 0/1").
            var rest: String=text.substr(at+separator.length())
            return [text.substr(0,at),rest.left(1).to_upper()+rest.substr(1)]
    return ["",text]

## Change 81: the Boss Keys chip from campaign.final_objective(). The count is the credited keys minus those still
## flying to it (each pickup adds its key when it lands), so the chip never runs ahead of the animation; on a load
## nothing is in flight and it shows the saved count. Written only when the text changes.
func _refresh_final_chip() -> void:
    var node: Control=$Safe/Layout/Map/FinalKeys
    var objective: String=sim.campaign.final_objective()
    var shown:=maxi(0,sim.state.keys.size()-(key_fx.in_flight() if key_fx!=null else 0))
    var text:=""
    if objective!="":
        text=tr("FINAL_HUD_READY") if objective=="ready" and shown>=sim.campaign.FINAL_KEYS else tr("FINAL_HUD_KEYS") % [shown,sim.campaign.FINAL_KEYS]
    if node.visible!=(text!=""):node.visible=text!=""
    if text==final_text:return
    final_text=text
    node.tooltip_text=tr("FINAL_HUD_TOOLTIP")
    var lines: Array=gate_lines(text)
    node.get_node("Row/Lines/Caption").text=lines[0]
    node.get_node("Row/Lines/Caption").visible=lines[0]!=""
    node.get_node("Row/Lines/Value").text=lines[1]
    var ready: bool=objective=="ready" and shown>=sim.campaign.FINAL_KEYS
    node.get_node("Row/Lines/Value").add_theme_color_override("font_color",Color(.55,1,.6) if ready else Color(1,.86,.5))

## Where a flying key lands (map coordinates), or an empty Rect2 when the chip cannot take it now: hidden, or
## covered by a panel, a dialog or the Prestige choice (the key then fades where it is).
func _final_chip_target() -> Rect2:
    var node: Control=$Safe/Layout/Map/FinalKeys
    if not node.visible or sheet.visible or modal_open() or not sim.state.prestige_batch.is_empty():return Rect2()
    return Rect2(node.position,node.size)

## Where a floating key's centre may be (map coordinates): below both HUD rails and the followed pills, inside the
## map's middle columns, above the joystick's band.
func _key_fx_bounds() -> Rect2:
    var map: Control=$Safe/Layout/Map
    var top: float=maxf(map_stack_bottom(),left_column_bottom())
    for tracker in [$Safe/Layout/Map/FollowTracker,$Safe/Layout/Map/MissionTracker,mastery_tracker]:
        if tracker!=null and tracker.visible:top=maxf(top,tracker.position.y+tracker.size.y)
    top+=70.0
    var bottom: float=map.size.y-150.0
    if stick!=null and stick.is_visible_in_tree():bottom=minf(bottom,stick.get_global_rect().position.y-map.global_position.y-70.0)
    var left: float=map.size.x*.2
    return Rect2(left,top,maxf(1.0,map.size.x*.6),maxf(1.0,bottom-top))

## Places a floating key must not take touches from: the joystick and the skill/supply buttons over the map.
func _key_fx_avoid() -> Array:
    var map: Control=$Safe/Layout/Map
    var out: Array=[]
    for node in [stick,$Safe/Layout/Skills]:
        if node!=null and node.is_visible_in_tree():
            var r: Rect2=node.get_global_rect()
            out.append(Rect2(r.position-map.global_position,r.size).grow(12))
    return out

## sim.key_earned: the key is already credited and saved. The pickup plays over the fallen boss; the 13th key is
## also announced as an important notice when it lands.
func _key_earned(group: int,at: Vector2,total: int) -> void:
    if sim.catalog.groups[group].stage!=int(sim.state.stage):at=sim.position_of(sim.state.player)
    key_fx.play(at,total,tr("KEY_FX_LABEL") % [total,sim.campaign.FINAL_KEYS])
    AudioService.play("feature_unlocked")

func _key_arrived(total: int) -> void:
    final_text=""
    _refresh_final_chip()
    var chip: Control=$Safe/Layout/Map/FinalKeys
    if chip.visible:
        chip.pivot_offset=chip.size*.5
        var t:=create_tween()
        t.tween_property(chip,"scale",Vector2.ONE*1.18,.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        t.tween_property(chip,"scale",Vector2.ONE,.22)
    if total>=sim.campaign.FINAL_KEYS:
        AudioService.play("prestige_ready")
        _say(tr("FINAL_READY_NOTICE"),true)
    else:AudioService.play("prestige_step")

## Change 82: the ceremony takes the stick (the world is frozen) and, when the seal breaks, a gold banner with the
## Green Alien acknowledges the player's worth. The fight and the arena start when the ceremony ends.
var unseal_shown_at:=-INF
func _final_ceremony(phase: String) -> void:
    match phase:
        "start":
            stick.release();stick_input=Vector2.ZERO
            world.follow_player()
        "unseal":
            var g:=-1
            for i in range(sim.catalog.groups.size()):
                if bool(sim.catalog.groups[i].final):g=i
            banner.push_front("final_unsealed",tr("FINAL_UNSEAL_TITLE"),tr("FINAL_UNSEAL_BODY"),icon_cache.get(sim.catalog.groups[g].body) if g>=0 else null)
            unseal_shown_at=Time.get_ticks_msec()/1000.0
            _refresh_final_chip()

## Change 82: one short notice when the barrier closes (not right after the ceremony's own banner).
func _arena_changed(active: bool,_reason: String) -> void:
    if active and Time.get_ticks_msec()/1000.0-unseal_shown_at>6.0:_say(tr("ARENA_CLOSED"))

# ---------------------------------------------------------------- Change 83: Green Alien finale
func _final_group() -> int:
    for i in range(sim.catalog.groups.size()):
        if bool(sim.catalog.groups[i].final):return i
    return -1

func _final_art() -> Texture2D:
    var g:=_final_group()
    return icon_cache.get(sim.catalog.groups[g].body) if g>=0 else null

## The danger question opens over everything (a panel closes first; the stick lets go).
func _final_warning(phase: String) -> void:
    if phase!="ask":return
    stick.release();stick_input=Vector2.ZERO
    if sheet.visible:_close()
    if $Confirm.visible:_cancel_confirm()
    world.follow_player()
    final_dialog.open_warning(_final_art())
    AudioService.play("boss_found")

func _final_answered(kind: String,choice: String) -> void:
    match kind:
        "warning":
            if choice=="yes":
                AudioService.play("ui_confirm")
                sim.campaign.accept_final_warning()
            else:
                AudioService.play("ui_click")
                sim.campaign.decline_final_warning()
        "ending":
            # Any answer acknowledges the message once; the links open after (they never block play).
            sim.campaign.acknowledge_ending()
            match choice:
                "review":
                    if not sim.campaign.review.open_store():_say(tr("REVIEW_OPEN_FAILED"))
                "discord":_open_discord()
                _:AudioService.play("ui_confirm")

## Rage Mode: a red warning over the map for about 5 s (non-blocking: never a modal, never a pause); the aura and
## the red wall stay after it.
func _final_rage(_id: String) -> void:
    banner.push_warning("final_rage",tr("FINAL_RAGE_TITLE"),tr("FINAL_RAGE_BODY"),_final_art(),RAGE_BANNER_SECONDS)
const RAGE_BANNER_SECONDS:=5.0

## A Green Alien victory. "first": the 10 s celebration (world frozen, camera on the floor); the ending panel follows
## once campaign.ending_due. Later victories: nothing modal (unless the message is still owed).
func _final_victory(kind: String) -> void:
    match kind:
        "first":
            stick.release();stick_input=Vector2.ZERO
            if sheet.visible:_close()
            if $Confirm.visible:_cancel_confirm()
            world.follow_player()
            # The celebration has its own banner: the generic boss title (it would sit on the floor's caption) goes.
            if boss_title_tween!=null and boss_title_tween.is_valid():boss_title_tween.kill()
            boss_title.visible=false
            banner.push_front("final_victory",tr("FINAL_VICTORY_TITLE"),tr("FINAL_VICTORY_BODY"),_final_art())
            AudioService.play("game_complete")
        "repeat":_say(tr("FLOOR_REPEAT_NOTICE"))

## Every frame: the owed ending panel (when nothing else holds the screen) and the recommended-audio chip.
func _update_final(_dt: float) -> void:
    if final_dialog==null:return
    var c=sim.campaign
    if c.ending_due and not final_dialog.is_open() and not modal_open() and sim.state.prestige_batch.is_empty() and not get_tree().paused and not sim.suspended and sim.state.tutorial.mode!="pending":
        if sheet.visible:_close()
        stick.release();stick_input=Vector2.ZERO
        final_dialog.open_ending(_hero_art())
        AudioService.play("mastery_map")
    _refresh_final_audio_chip()

func _hero_art() -> Texture2D:
    var outfit: String=str(sim.state.get("outfit",""))
    return icon_cache.get(outfit) if outfit!="" and icon_cache.has(outfit) else _final_art()

## A small chip under Boss Keys whenever the player is at the living Green Alien (or fighting it): one tap sets the
## recommended mix (Music 40% / Sound Effects 100%) for this encounter, a second tap puts the player's own back.
func _build_final_audio_chip() -> void:
    var map: Control=$Safe/Layout/Map
    var chip:=Button.new()
    chip.name="FinalAudio"
    chip.theme_type_variation=&"HudChipButton"
    chip.visible=false
    chip.focus_mode=Control.FOCUS_NONE
    chip.add_theme_font_size_override("font_size",CHIP_FONT)
    chip.clip_text=false
    chip.pressed.connect(func()->void:
        if SettingsState.recommended_active():SettingsState.restore_recommended()
        else:SettingsState.apply_recommended()
        AudioService.play("ui_confirm")
        _refresh_final_audio_chip(true))
    map.add_child(chip)
    map.move_child(chip,map.get_node("FinalKeys").get_index()+1)

var final_audio_text:=""
func _refresh_final_audio_chip(force:=false) -> void:
    var chip: Button=$Safe/Layout/Map/FinalAudio
    var c=sim.campaign
    var show: bool=final_audio!=null and not final_dialog.is_open() and not c.celebration_active() and not c.ceremony_active() and (final_audio.near_living_boss() or not c.engaged_final().is_empty())
    if chip.visible!=show:chip.visible=show
    if not show:return
    var text:=tr("FINAL_AUDIO_ON") if SettingsState.recommended_active() else tr("FINAL_AUDIO_CHIP")
    if text==final_audio_text and not force:return
    final_audio_text=text
    chip.text=text
    chip.tooltip_text=tr("FINAL_AUDIO_TOOLTIP")
    chip.add_theme_color_override("font_color",Color(.55,1,.6) if SettingsState.recommended_active() else Color(1,.86,.5))

## Change 81: the Green Alien's introduction, once per profile, the first time it is met (state.tutorial.seen
## "final_intro", kept by Prestige). A red banner (the boss-warning form) over the map, never a modal; it waits
## while a panel or dialog is open. Reopened at any time from the Boss Keys chip (Missions).
func _final_intro_check() -> void:
    if not bool(sim.state.final_discovered) or sim.state.tutorial.seen.has("final_intro") or sim.state.tutorial.mode=="pending":return
    sim.state.tutorial.seen.append("final_intro")
    sim.touch()
    var g:=-1
    for i in range(sim.catalog.groups.size()):
        if bool(sim.catalog.groups[i].final):g=i
    banner.push_warning("final_intro",tr("FINAL_INTRO_TITLE"),tr("FINAL_INTRO_BODY") % [sim.campaign.FINAL_KEYS,sim.campaign.FINAL_KEYS],icon_cache.get(sim.catalog.groups[g].body) if g>=0 else null)
    AudioService.play("boss_found")

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
            slot.quick_tap.connect(func()->void:_activate_view_slot(type,index))
            slot.held.connect(func()->void:_select_view_slot(type,index))
        while container.get_child_count()>list.size():
            var child=container.get_child(container.get_child_count()-1)
            container.remove_child(child)
            child.queue_free()
        if type==0:_update_gear_view()
        for p in range(list.size()):
            var node: Button=container.get_child(p)
            var i: int=p if type==1 else (gear_view[p] if p<gear_view.size() else -1)
            var id: String=list[i] if i>=0 else ""
            var badge:=tr("EQUIPPED") if id!="" and sim.equipped(id) else (tr("AUTO") if type==1 and sim.state.auto_slots.has(i) else "")
            var shown: bool=type==1 or i>=0
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
    # Change 71: a saved category or order stays visible on the dock (fixed button size: long names trim).
    var active: bool=inventory_filter>0 or inventory_sort>0
    var text:=tr("FILTERS")
    if inventory_filter>0:text=tr(FILTER_TABS[inventory_filter])+(" ↓" if inventory_sort>0 else "")
    elif inventory_sort>0:text=tr(SORT_TABS[inventory_sort])
    if button.text!=text:button.text=text
    var tip:=tr("FILTERS_TOOLTIP")
    if active:tip+="\n"+tr("INVENTORY_VIEW_NOW") % [tr(FILTER_TABS[inventory_filter]),tr(SORT_TABS[inventory_sort])]
    if button.tooltip_text!=tip:button.tooltip_text=tip
    # Only a saved view's longer name is fitted to the button (font first, then an ellipsis); the plain
    # "Filters" label keeps the button's own sizing, as before Change 71.
    var overrun:=TextServer.OVERRUN_TRIM_ELLIPSIS if active else TextServer.OVERRUN_NO_TRIMMING
    if button.text_overrun_behavior!=overrun:
        button.text_overrun_behavior=overrun
        button.clip_text=active
    var font_size:=_fitting_font_size(text,button.custom_minimum_size.x-button.get_theme_stylebox("normal").get_minimum_size().x-4,17,13) if active else 17
    if button.get_theme_font_size("font_size")!=font_size:button.add_theme_font_size_override("font_size",font_size)
    var variation:=&"Primary" if open else (&"ToggleOn" if active else &"")
    if button.theme_type_variation!=variation:button.theme_type_variation=variation

## Change 71 (replaces Change 11's reset on close): the category and order are a saved preference of the
## main inventory, so closing Filters keeps them. Every close path still ends here and re-renders the dock.
func _clear_filters() -> void:
    _refresh_slots()

## Change 71: one setter for both choices (the Filters panel's tabs call it); the dock re-renders at once.
func _set_inventory_view(filter: int,sort: int) -> void:
    SettingsState.set_inventory_view(filter,sort)
    slot_signatures.clear()
    _refresh_slots()
    if sheet.visible:_refresh_panel()

## The backing gear indices in display order (see gear_view). Default + All is the slot order itself, empty
## slots included. A category shows only its items, a sort ranks them (ties by slot order, so the order is
## stable); either way the empty slots follow the items, so capacity and the empty-slot actions stay visible. Rebuilt only when what it depends on changes.
func _update_gear_view() -> void:
    var key:="%d|%d|%d|" % [inventory_filter,inventory_sort,sim.state.gear.size()]
    if inventory_filter>0 or inventory_sort>0:
        for id in sim.state.gear:
            key+=("%s:%d:%d:%s," % [id,sim.quantity(id),sim.merge_level(id),sim.evolve_block_reason(id).is_empty()]) if id!="" else ","
    if key==gear_view_key:return
    gear_view_key=key
    gear_view=_gear_order()

func _gear_order() -> Array[int]:
    var all: Array[int]=[]
    for i in range(sim.state.gear.size()):all.append(i)
    if inventory_sort==0 and inventory_filter==0:return all
    var items: Array[int]=[]
    var empty: Array[int]=[]
    for i in all:
        var id: String=sim.state.gear[i]
        if id=="":
            empty.append(i)
            continue
        if inventory_filter>0 and str(sim.catalog.items[id].kind)!=FILTER_KINDS[inventory_filter]:continue
        items.append(i)
    if inventory_sort>0:
        var keys: Dictionary={}
        for i in items:keys[i]=_inventory_sort_key(str(sim.state.gear[i]))
        items.sort_custom(func(a: int,b: int)->bool:
            var ka: Array=keys[a]
            var kb: Array=keys[b]
            for k in range(ka.size()):
                if ka[k]!=kb[k]:return ka[k]>kb[k]
            return a<b)
    return items+empty

## Descending sort key per item (compared element by element; the slot index breaks ties). Tier: tier, then
## merge level, then copies. Evolution: ready to evolve now, then merge progress toward the evolution
## requirement, then spare copies toward its cost; items that can never evolve come last. Quantity: copies,
## then tier.
func _inventory_sort_key(id: String) -> Array:
    var d: Dictionary=sim.catalog.items[id]
    var qty: float=float(sim.quantity(id))
    match inventory_sort:
        1:return [int(d.get("tier",0)),sim.merge_level(id),qty]
        2:
            if str(d.get("next",""))=="":return [-1,0.0,0.0]
            var required:=maxi(1,int(sim.catalog.progression.evolution.required_merge))
            var ready: int=1 if sim.evolve_block_reason(id).is_empty() else 0
            var spare:=minf(1.0,maxf(0.0,qty-1.0)/maxf(1.0,float(sim.evolution_spare_cost(id))))
            return [ready,minf(1.0,float(sim.merge_level(id))/required),spare]
        3:return [qty,int(d.get("tier",0))]
    return [0]

## The dock slot node that shows backing gear index i (null when the view hides it).
func gear_slot_node(i: int) -> Control:
    var grid: Node=dock.get_node("Inventory/GearColumn/GearScroll/Gear")
    _update_gear_view()
    var p: int=gear_view.find(i)
    if i<0 or p<0 or p>=grid.get_child_count():return null
    var node: Control=grid.get_child(p)
    return node if node.visible else null

## Slot taps arrive with the slot's position in the grid; the view says which backing slot that is now.
func _activate_view_slot(type: int,p: int) -> void:
    var i: int=p if type==1 else (gear_view[p] if p<gear_view.size() else -1)
    if i<0:return
    _activate_slot(type,i)

func _select_view_slot(type: int,p: int) -> void:
    var i: int=p if type==1 else (gear_view[p] if p<gear_view.size() else -1)
    if i<0:return
    _select_slot(type,i)

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

## Change 10: an outfit's ^100 milestone rank (0-5) decides its slot treatment; other items are 0. Change 81: the
## Obsidian weapons (^100-^500 milestones) use the same frames.
func _milestone_rank(id: String) -> int:
    if id=="" or not sim.catalog.items.has(id) or (str(sim.catalog.items[id].kind)!="outfit" and not sim.final_weapon(id)):return 0
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
    _hints_this_opening.clear()
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
    # Change 76: an Auto Buy chooser is a choice in progress, not a setting; it closes with the panel.
    auto_buy_edit=-1
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
## Change 76: notices the player must be able to read in full, whatever else is queued (a boss weapon's bonus
## attributes). They use toast_reading_time's important timing.
const IMPORTANT_EVENTS:=["ITEM_ENHANCED"]
func _event(key: String) -> void:
    if key in ["PRESTIGE_DISCOVERED","PRESTIGE_READY","STAGE_UNLOCKED"]:return
    # Change 67: an evolution is announced by _manual_evolve or _on_evolved (which knows whether it was automatic).
    if key=="EVOLVED":return
    # Change 81: the Green Alien's introduction is its own banner (_final_intro_check), not a short toast.
    if key=="FINAL_DISCOVERED":return
    var text:=tr(key)
    if key=="FINAL_SEALED":text=tr("FINAL_SEALED") % [sim.state.keys.size(),sim.campaign.FINAL_KEYS]
    if key=="AUTO_SKILL_NEEDS_SLOT":text=tr("AUTO_SKILL_NEEDS_SLOT") % sim.auto_skill_required_slot()
    if key=="PLAYER_LEVEL_UP":text=tr("LEVEL_UP_NOTICE") % sim.state.player_level
    if key=="PRESTIGED":
        _close()
        _recenter_on_player()
        return
    _say(text,key in IMPORTANT_EVENTS)

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
        "game_complete_100":AudioService.play("game_complete")
        # Change 16: the first sight of a boss plays the notification (mission-ready) sound, once.
        "boss_found":AudioService.play("boss_found")
        # Change 14: the first Focused Farming purchase confirms itself on the panel's notice line
        # (or as a toast); the guide then points at the Farm button once.
        "focus_unlocked":_say(tr("FOCUS_UNLOCKED"))
        # Change 55 E1: the first evolvable weapon at its cap explains the 10 spares, once per profile.
        "evolve_ready":
            if sim.catalog.items.has(_id) and not hint_retired("evolve_ready") and not sim.campaign.guided.active() and sim.state.prestige_batch.is_empty():
                retire_hint("evolve_ready")
                _say(tr("EVOLVE_READY_HINT") % [sim.catalog.display_name(_id),sim.evolution_spare_cost(_id),sim.catalog.display_name(str(sim.catalog.items[_id].next))])

# ---------------------------------------------------------------- contextual hints (Change 55)
## Approved hints M1 (Map Detail), O1 (offline gear) and E1 (evolution): state-driven, inline in the panel
## they explain (never a modal, never over a card choice or Prestige, never pausing), only once the Guided
## tutorial is over, at most HINT_SHOWS panel openings each, retired for good by the demonstrated action.
## Records live in state.tutorial.seen ("hint_<id>" once per opening that showed it, "hint_<id>_done").
const HINT_SHOWS:=3
var _hints_this_opening: Dictionary={}
func hint_retired(id: String) -> bool:
    var seen: Array=sim.state.tutorial.seen
    return seen.has("hint_"+id+"_done") or seen.count("hint_"+id)>=HINT_SHOWS
func retire_hint(id: String) -> void:
    if not sim.state.tutorial.seen.has("hint_"+id+"_done"):sim.state.tutorial.seen.append("hint_"+id+"_done");SaveService.mark_dirty()
## True when the hint may show in the panel now; counts one show per panel opening.
func hint_allowed(id: String) -> bool:
    if hint_retired(id) or sim.campaign.guided.active() or not sim.state.prestige_batch.is_empty():return false
    if not _hints_this_opening.has(id):
        _hints_this_opening[id]=true
        sim.state.tutorial.seen.append("hint_"+id);SaveService.mark_dirty()
    return true
## M1: a map with found enemies but no Map Detail rank yet, until any Map Detail is bought.
func map_detail_hint_due() -> bool:
    var st:=int(sim.state.stage)
    if sim.level("map_detail",st)>0 or sim.campaign.sequence_count("map_detail")>0:
        retire_hint("map_detail")
        return false
    return sim.campaign.stage().groups.any(func(g):return sim.campaign.discovered(g))
## O1: an offline item unlock (weapons, outfits or supplies) is missing and the player owns an item of
## that kind it could copy. Change 61: affordability no longer decides it (a player short of Gems still
## learns the feature exists); it retires once all three are unlocked or after its HINT_SHOWS openings.
const OFFLINE_ITEM_UNLOCKS:={"offline_weapon":"weapon","offline_outfit":"outfit","offline_consumable":"consumable"}
func offline_gear_hint_due() -> bool:
    var missing: Array=OFFLINE_ITEM_UNLOCKS.keys().filter(func(u):return sim.level(u)==0)
    if missing.is_empty():
        retire_hint("offline_gear")
        return false
    var kinds: Array=missing.map(func(u):return OFFLINE_ITEM_UNLOCKS[u])
    for id in sim.state.items:
        if sim.quantity(id)>0 and sim.catalog.items[id].kind in kinds and not sim.is_legacy(id):return true
    return false
## Scrolls the open panel so a section heading is at the top (M1 route).
func _scroll_to_section(title: String) -> void:
    await get_tree().process_frame
    var scroll: ScrollContainer=$Sheet/Margin/Content/Scroll
    for l in rows.find_children("*","Label",true,false):
        if str(l.text)==title:
            scroll.scroll_vertical=int(l.get_global_rect().position.y-scroll.get_global_rect().position.y+scroll.scroll_vertical)
            return

## A deliberate manual action that succeeded gets the shared confirm (it replaces the click).
func _confirmed(ok: bool) -> bool:
    if ok:AudioService.play("ui_confirm")
    return ok

## Short text on the open panel's notice line, otherwise as a toast.
func _say(text: String,important:=false) -> void:
    if sheet.visible:notice.text=text
    else:_toast(text,important)

func _toast(text: String,important:=false) -> void:
    # Change 63: a message already waiting or on screen is not queued twice; nothing else is dropped.
    if text.is_empty() or toast_queue.has(text) or ($Toast.visible and $Toast/Text.text==text):return
    toast_queue.append(text)
    if important:toast_important[text]=true

func _update_toast(dt: float) -> void:
    if sheet.visible:
        # Change 63: a toast on screen when a panel opens waits with the time it had left.
        _suspend_toast()
        return
    toast_time=maxf(0,toast_time-dt)
    if toast_time<=0:
        if toast_queue.is_empty():
            $Toast.hide()
            return
        $Toast/Text.text=toast_queue.pop_front()
        toast_time=toast_reading_time($Toast/Text.text,not toast_queue.is_empty(),toast_important.has($Toast/Text.text))
        toast_important.erase($Toast/Text.text)
        if not toast_resume.is_empty() and str(toast_resume.text)==$Toast/Text.text:toast_time=maxf(float(toast_resume.time),.8)
        toast_resume={}
        # Change 72: a toast that appears is placed afresh (the same text shown earlier may have sat lower,
        # under a banner that is gone now).
        toast_placed_for=""
        $Toast.show()
    # Change 72: the lane between the HUD rails at the top of the map (under a banner while one shows), never
    # the middle of the map. A placement is kept while it stays clear.
    var map: Control=$Safe/Layout/Map
    var placed_text: String=$Toast/Text.text
    var now:=Rect2($Toast.position,$Toast.size)
    if toast_placed_for==placed_text and $Toast.visible and map.get_global_rect().encloses(now) and not _toast_overlaps(now) and not (banner.visible and now.intersects(banner.get_global_rect())):return
    # Change 74: the first lane (in order of preference) with a clear slot is used.
    for lane in _toast_lanes():
        var at:=_toast_slot(lane)
        if at!=Vector2.INF:
            toast_placed_for=placed_text
            $Toast.position=at
            return
    toast_placed_for=""
    _suspend_toast()

## Change 74: how long a toast stays: long enough to read its text (about 14 characters a second after a
## 1.6 s glance), never under toast_seconds, at most TOAST_MAX_SECONDS. With more toasts waiting it is cut to
## three quarters, but never under toast_busy_seconds: a boss weapon's "two bonus attributes added" used to
## leave after 1.4 s when it arrived with other news.
## Change 76: an important toast (IMPORTANT_EVENTS) stays at least IMPORTANT_TOAST_SECONDS (its reading time when
## longer, up to IMPORTANT_TOAST_MAX_SECONDS) and is never cut when others wait: they follow it in the queue.
## A boss weapon's notice used to show for 3.3-4.4 s; it is a once-per-run explanation worth a calm read.
const TOAST_MAX_SECONDS:=6.0
const IMPORTANT_TOAST_SECONDS:=8.0
const IMPORTANT_TOAST_MAX_SECONDS:=12.0
func toast_reading_time(text: String,busy: bool,important:=false) -> float:
    if important:return clampf(1.6+text.length()/10.0,IMPORTANT_TOAST_SECONDS,IMPORTANT_TOAST_MAX_SECONDS)
    var reading: float=clampf(1.6+text.length()/14.0,toast_seconds,TOAST_MAX_SECONDS)
    return maxf(toast_busy_seconds,reading*.75) if busy else reading

## Change 74: the places a toast may use, best first, as {x, width, from: "top"|"bottom", limit: share of the map
## height it may not cross}. The first with a clear slot wins:
## - The lane between the rails at the top of the map, when it is wide enough to read (a tablet's wider
##   canvas): the whole lane centred, then its left part short of the zoom button.
## - The bottom of the map on the joystick's free side, rising from the bottom edge: it never reaches the fight
##   around the player. With the enlarged rails (Change 74) the top lane of the 720-wide portrait canvas is about
##   130 wide, so this is where phones show toasts.
## - Over the joystick, at the bottom of the map (developer's choice for when the top is not viable): the
##   toast passes over the stick for its few seconds rather than wait or reach the fight.
## - The left rail under the enemy controls and the followed objectives (when the lower map has no room).
const TOAST_MIN_WIDTH:=240.0
const TOAST_WIDTH:=300.0
const TOAST_LANE_FLOOR:=.42
const TOAST_BOTTOM_CEILING:=.62
const TOAST_RAIL_FLOOR:=.5
func _toast_lanes() -> Array:
    var map: Control=$Safe/Layout/Map
    var area: Rect2=map.get_global_rect()
    var lanes: Array=[]
    var left: float=HUD_MARGIN+LEFT_COLUMN_WIDTH+10
    var lane: float=map.size.x-left-HUD_MARGIN-MINIMAP_SIDE-10
    if lane>=TOAST_MIN_WIDTH:
        var whole: float=minf(560,lane)
        lanes.append({"x":area.position.x+left+(lane-whole)*.5,"width":whole,"from":"top","limit":TOAST_LANE_FLOOR})
        var narrow: float=lane-ZOOM_BUTTON.x-HUD_GAP
        if narrow>=TOAST_MIN_WIDTH:lanes.append({"x":area.position.x+left,"width":narrow,"from":"top","limit":TOAST_LANE_FLOOR})
    # The joystick's free side: the wider of the spaces left and right of it.
    var stick_rect: Rect2=stick.get_global_rect() if stick.visible else Rect2(area.get_center(),Vector2.ZERO)
    var room_left: float=stick_rect.position.x-10-(area.position.x+HUD_MARGIN)
    var room_right: float=area.end.x-HUD_MARGIN-(stick_rect.end.x+10)
    var room: float=maxf(room_left,room_right)
    if room>=TOAST_MIN_WIDTH:
        var width: float=minf(TOAST_WIDTH,room)
        var x: float=area.position.x+HUD_MARGIN if room_left>=room_right else area.end.x-HUD_MARGIN-width
        lanes.append({"x":x,"width":width,"from":"bottom","limit":TOAST_BOTTOM_CEILING})
    var over: float=minf(TOAST_WIDTH,map.size.x-HUD_MARGIN*2)
    lanes.append({"x":clampf(stick_rect.get_center().x-over*.5,area.position.x+HUD_MARGIN,area.end.x-HUD_MARGIN-over),"width":over,"from":"bottom","limit":TOAST_BOTTOM_CEILING,"over_stick":true})
    lanes.append({"x":area.position.x+HUD_MARGIN,"width":minf(HISTORY_WIDTH,map.size.x-HUD_MARGIN*2),"from":"top","limit":TOAST_RAIL_FLOOR})
    return lanes

## The toast's top-left in this lane (sized to its text), or INF when no clear place exists in it. A top lane
## moves down past what it meets and may not end below its limit; a bottom lane moves up and may not start
## above it.
func _toast_slot(lane: Dictionary) -> Vector2:
    var map: Control=$Safe/Layout/Map
    var x: float=lane.x;var width: float=lane.width
    if $Toast/Text.custom_minimum_size.x!=width-28:$Toast/Text.custom_minimum_size.x=width-28
    var label: Label=$Toast/Text
    var text_h: float=label.get_theme_font("font").get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_CENTER,width-28,label.get_theme_font_size("font_size")).y
    var wanted:=Vector2(width,ceilf(text_h+$Toast.get_theme_stylebox("panel").get_minimum_size().y))
    if not $Toast.size.is_equal_approx(wanted):$Toast.size=wanted
    var top: bool=lane.from=="top"
    var y: float=map.global_position.y+HUD_MARGIN if top else map.global_position.y+map.size.y-HUD_MARGIN-wanted.y
    if top and banner.visible:y=maxf(y,banner.get_global_rect().end.y+8)
    var blocked: Array=_toast_blockers(bool(lane.get("over_stick",false)))
    if banner.visible:blocked.append(banner.get_global_rect())
    for i in range(blocked.size()+1):
        var hit:=Rect2()
        for r in blocked:
            if not r.intersects(Rect2(x,y,width,wanted.y)):continue
            if hit.size==Vector2.ZERO or (r.end.y>hit.end.y if top else r.position.y<hit.position.y):hit=r
        if hit.size==Vector2.ZERO:break
        y=hit.end.y+8 if top else hit.position.y-8-wanted.y
    var limit: float=map.global_position.y+map.size.y*float(lane.limit)
    # Never into the fight: the toast waits in its queue instead (nothing is dropped).
    if (y+wanted.y>limit if top else y<limit) or y<map.global_position.y or _toast_overlaps(Rect2(x,y,width,wanted.y),bool(lane.get("over_stick",false))):return Vector2.INF
    return Vector2(x,y)

## Change 63: hides the toast on screen and puts it back at the front of its queue with its remaining
## seconds, so it returns (once, with that time) as soon as there is room.
func _suspend_toast() -> void:
    if not $Toast.visible:return
    var text: String=$Toast/Text.text
    $Toast.hide()
    if toast_time>0 and not toast_queue.has(text):
        toast_queue.push_front(text);toast_resume={"text":text,"time":toast_time}
    toast_time=0.0

func _milestone(kind: String,id: String) -> void:
    var cards: Array=[]
    match kind:
        "reset":
            banner.queue.clear();banner._finish();toast_queue.clear();toast_important.clear();auto_buy_edit=-1
            if key_fx!=null:key_fx.clear()
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
            # Change 71: the Prestige is committed and saved; the choice panel closes so the world celebration
            # (world.prestige_fx, centred on the hero) and this banner are seen instead of playing under it.
            if sheet.visible and panel=="prestige":_close()
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
            # Change 83: every map mastered is one of Game Completion's four parts (no longer "100% complete").
            banner.push(kind,tr("MILESTONE_ALL_MAPS_MASTERED"),tr("MASTER_FARMER_TITLE")+" · "+mastery_reward_text(sim.campaign.mastery.rules.completion_reward))
        "game_complete_100":
            banner.push(kind,tr("MILESTONE_GAME_COMPLETE_100"),tr("MILESTONE_GAME_COMPLETE_100_DETAIL"))
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
    # Change 83: the Green Alien panels answer Back with their safe choice (No, Not Yet / Continue Playing).
    if final_dialog!=null and final_dialog.is_open():
        final_dialog.back();return
    # Change 67: the evolution panel skips to its result first, then closes.
    if evolution_show.visible:
        evolution_show.back();return
    if $ReviewInvitation.is_open():
        _review_later();return
    if $PrestigeConfirm.visible:$PrestigeConfirm.close()
    elif $Confirm.visible:_cancel_confirm()
    # Change 65: the card viewer goes back to its topics (Help) or skips the overview (Basic).
    elif help_viewer!=null and help_viewer.visible:help_viewer.back()
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
    return "%s:%s:%d:%d:%d:%d:%d:%s:%d:%d:%s:%d:%s:%d:%d" % [panel,selected,selected_slot,group,player_tab,enemy_tab,enemy_variant,selected_card,inventory_filter,sim.state.prestige_batch.get("choices",[]).size(),show_completed_main,guide_stage,str(teleport_target)+":"+str(travel_stage)+":"+str(teleport_stage),sim.campaign.focus_hint,mastery_stage]+":"+help_page+":"+str(inventory_sort)

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
    # Change 61: the Guided lessons that ask the player to look at a screen (Stats, Upgrades -> Offline,
    # World, Prestige) are finished by that screen being shown, never by an acknowledgement.
    # Change 66: for Map Mastery the tab is the map page shown (0: the all-maps overview).
    sim.campaign.guided.panel_opened(panel,player_tab if panel=="upgrades" else (mastery_stage if panel=="mastery" else -1))
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
    var available:=map.size.y-sheet_inset.y*2-sheet_reserved
    sheet.set_anchors_preset(Control.PRESET_TOP_LEFT)
    if sheet.size.x!=width:sheet.size.x=width
    var chrome: float=sheet.get_combined_minimum_size().y
    var content: float=rows.get_combined_minimum_size().y
    if panel=="teleport":content=_fit_teleport_map(available-chrome-4,content)
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
        # Change 74: a control that grows its own minimum (a Prestige card fitting its text) is compared by the
        # size it was designed at; its description never ran _ready, so it carries the designed size itself.
        var live_min: Vector2=live.get_meta("designed_minimum",live.custom_minimum_size)
        if live_min!=incoming.get_meta("designed_minimum",incoming.custom_minimum_size) or live.theme_type_variation!=incoming.theme_type_variation and not (live is Button):return false
        # Only explicit overrides: off-tree descriptions cannot resolve theme defaults.
        if (live is Label or live is Button) and (live.has_theme_font_size_override("font_size")!=incoming.has_theme_font_size_override("font_size") or (incoming.has_theme_font_size_override("font_size") and live.get_theme_font_size("font_size")!=incoming.get_theme_font_size("font_size"))):return false
    return true

func _restore_panel_scroll(offset: int,generation: int) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    # Change 74: a gesture that began after the rebuild owns the offset.
    if $Sheet/Margin/Content/Scroll.gesturing:return
    if generation==panel_generation and is_instance_valid(rows):
        $Sheet/Margin/Content/Scroll.scroll_vertical=offset

# ---------------------------------------------------------------- item details

## Items in the inventory's stable display order for the current category (gear grid respects
## the dock filter; supplies are their own list).
func _browse_list() -> Array:
    var supplies: bool=selected_slot>=0 or (sim.catalog.items.has(selected) and sim.catalog.items[selected].kind=="consumable")
    var result: Array=[]
    # Change 71: gear browses in the dock's displayed order (category and sort applied).
    var order: Array=sim.state.supplies
    if not supplies:
        _update_gear_view()
        order=[]
        for i in gear_view:order.append(sim.state.gear[i])
    for id in order:
        if id=="" or result.has(id):continue
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
            _supply_shop()
            var row:=HFlowContainer.new();rows.add_child(row)
            _toggle_style(_game_action(tr("AUTO_SLOT_STATUS") % tr("ON" if sim.state.auto_slots.has(selected_slot) else "OFF"),func()->void:sim.bind_auto(selected_slot),true,"",row),sim.state.auto_slots.has(selected_slot))
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
        # Change 78: the next merge's gain sits in green beside each stat it raises ("Damage 22.39 +0.44"),
        # from the simulation's own formula; nothing at the merge cap.
        var preview: Dictionary=sim.merge_preview(id)
        for key in sim.normal(id):
            var gain: float=float(preview.get(key,0.0))
            _stat_line(details,_stat_text(key,sim.normal(id)[key],true),deltas.get(key,0.0),key,22,Color.WHITE,_merge_gain_text(key,gain))
            shown[key]=true
    # Change 79: an item whose attributes can be rerolled shows a Lock toggle on each attribute row.
    var lockable: bool=not def.extras.is_empty() and r.qty>0 and def.kind!="skill"
    var base_index:=0
    for key in r.extras:
        var line:=_stat_line(details,"+ "+_stat_text(key,r.extras[key],true),0.0 if shown.has(key) else deltas.get(key,0.0),key,19,Color(.75,.8,.87))
        if lockable:_reroll_lock_toggle(line,id,"base:%d" % base_index)
        base_index+=1
        shown[key]=true
    # Change 52: boss bonus attributes in gold under one "★ Boss bonus" heading (Change 55: a heading line
    # instead of a prefix on each line, so the card keeps its phone width at 432 px).
    if not sim.boss_extras(id).is_empty():_card_line(details,"★ "+tr("ITEM_BOSS_BONUS"),17,Color(1,.84,.45))
    var boss_index:=0
    for e in sim.boss_extras(id):
        var line:=_stat_line(details,"+ "+_stat_text(str(e.stat),float(e.value),true),0.0 if shown.has(str(e.stat)) else deltas.get(str(e.stat),0.0),str(e.stat),19,Color(1,.84,.45))
        if lockable:_reroll_lock_toggle(line,id,"boss:%d" % boss_index)
        boss_index+=1
        shown[str(e.stat)]=true
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
        # Change 78: gear shows its next-merge gains beside its stats (above); a skill has no stat rows,
        # so it keeps the one-line summary.
        if def.kind=="skill":
            var gains: Array[String]=[]
            for stat in def.normal:
                var gain: float=sim.next_merge_gain(id,stat)
                if gain>0:gains.append(_skill_amount(str(def.skill),gain))
            _card_line(details,tr("NEXT_MERGE_GAIN")+" "+", ".join(gains),17,Color(.5,1,.65))
    else:
        _card_line(details,tr("STOCK_BONUS") % fmt(maxi(0,int(r.qty)-1)*float(sim.catalog.progression.merge.stock_bonus_per_copy)*100),17,Color(.5,1,.65))
    if def.kind=="outfit":_outfit_milestone_lines(details,id)
    elif sim.final_weapon(id):_weapon_milestone_lines(details,id)
    # Change 13: every skill shows its effective cooldown from the same getter the cast uses (Change 16:
    # it is part of skill_description, with targets and range).
    if def.get("skill","")=="heal":_text(tr("HEAL_ROLE_SHORT"),17,Color(.8,.84,.9))
    # Secondary actions: a wrapping row, sized for their widest label.
    var more:=HFlowContainer.new()
    more.add_theme_constant_override("h_separation",8)
    more.add_theme_constant_override("v_separation",8)
    var amount:=mini(int(r.qty)-1,cap-int(r.merge))
    if r.merge<cap and amount>1:_game_action(tr("MERGE_ALL") % amount,func()->void:if selected==id:_manual_merge(id,true),true,"",more)
    if def.next!="" and r.merge>=cap:
        var evolve_block:=sim.evolve_block_reason(id)
        # Change 58 (localization): a blocked Evolve carries its reason as a second line. Inside the flow row a
        # button keeps its unwrapped width, so a long translated reason widened the sheet past the screen; blocked,
        # it is a full-width row that wraps (as other panel rows do).
        _game_action(tr("EVOLVE") % sim.catalog.display_name(def.next),func()->void:if selected==id:_manual_evolve(id),evolve_block.is_empty(),evolve_block,more if evolve_block.is_empty() else null)
        if sim.evolution_bulk_count(id)>1:
            _game_action(tr("EVOLVE_ALL_COPIES") % [sim.evolution_bulk_count(id),sim.catalog.display_name(def.next)],func()->void:if selected==id:_manual_evolve_all(id),evolve_block.is_empty(),evolve_block,more if evolve_block.is_empty() else null)
    if def.kind=="skill":
        for i in range(1+sim.level("skill_slots")):
            _game_action(tr("EQUIP_SKILL_SLOT") % (i+1),func()->void:if selected==id:sim.campaign.equip_skill(id,i),true,"",more)
    if lockable:
        # Change 79: one Reroll Stats per item rerolls every unlocked attribute together; its label carries the
        # exact price for the current locks (sim.reroll_total_cost, the amount the reroll charges). Blocked (all
        # locked, too few Gems) it is a full-width row with its reason, as Evolve is.
        var total:=sim.reroll_total_cost(id)
        var block:=sim.reroll_block_reason(id)
        var unlocked:=sim.reroll_slot_keys(id).size()-sim.reroll_locks(id).size()
        var reroll_button:=_game_action(tr("REROLL_STATS") % fmt_cost(total),func()->void:
            _confirm(tr("REROLL_STATS_CONFIRM") % [unlocked,fmt_cost(total)],func()->void:
                if selected==id and _confirmed(sim.reroll_stats(id)):_say(tr("REROLL_STATS_DONE") % unlocked)
                _refresh_panel(),tr("REROLL_STATS_ACTION")),block.is_empty(),block,more if block.is_empty() else null)
        reroll_button.name="RerollStats"
    if sim.gear_group(id)>=0:_toggle_style(_game_action(tr("ITEM_AUTO_MERGE") % tr("OFF" if sim.auto_merge_excluded(id) else "ON"),func()->void:sim.set_auto_merge_excluded(id,not sim.auto_merge_excluded(id)),true,"",more),not sim.auto_merge_excluded(id)).set_meta("guide","item_auto_merge")
    _drop_action(id,more)
    for button in more.get_children():
        button.size_flags_horizontal=0
        button.custom_minimum_size=Vector2(0,64)
        button.add_theme_font_size_override("font_size",18)
    if more.get_child_count()>0:rows.add_child(more)
    else:more.free()
    # Change 79: how locks work and what they cost, in the panel (a tooltip is not reachable on a phone).
    if lockable:_text(tr("REROLL_LOCK_RULE"),16,Color(.7,.75,.82)).name="RerollRule"
    if def.kind=="outfit":
        _text(tr("OUTFIT_GROWTH_EXPLAIN") % [cap,fmt_value(float(sim.catalog.progression.stored_outfit_factor)*100)],17,Color(.8,.84,.9))
    elif sim.copy_growth(id):
        _text(tr("COPY_GROWTH_EXPLAIN") % cap,17,Color(.8,.84,.9))
    elif sim.is_legacy(id):
        _text(tr("LEGACY_ITEM_EXPLAIN"),17,Color(1,.86,.5))
    elif def.next!="" and r.merge>=cap:
        _text(tr("EVOLUTION_RULE") % [int(sim.catalog.progression.evolution.required_merge),sim.evolution_spare_cost(id),sim.evolution_spare_cost(id)+1],17,Color(.8,.84,.9))
    elif def.next=="":
        # Change 81: the final tier merges to its own cap (^500), with milestones every ^100.
        _text(tr("MAX_ITEM_TIER_CAP") % cap,17,Color(.8,.84,.9))
    # Change 52: what boss copies add to this weapon (or have added this run). Change 78: boss outfits too.
    if (def.kind=="weapon" and not sim.is_legacy(id)) or sim.campaign.boss_only_outfit(id):
        var enhanced: bool=not sim.boss_extras(id).is_empty()
        _text(tr("ITEM_BOSS_BONUS_EXPLAIN" if enhanced else "ITEM_BOSS_BONUS_HINT"),16,Color(1,.84,.45) if enhanced else Color(.7,.75,.82))
    # Pinned: previous, primary, merge, next. Positions never change while browsing.
    var index:=list.find(id)
    _arrow_button(-1,index>0,func()->void:_browse(-1))
    _pinned(tr("UNEQUIP" if sim.equipped(id) else "EQUIP"),func()->void:if selected==id:sim.equip(id),true,"",not sim.equipped(id),"equip")
    _pinned(tr("ITEM_MERGE_ACTION"),func()->void:if selected==id:_manual_merge(id),r.qty>1 and r.merge<cap,"NEED_DUPLICATES" if r.qty<2 else "MERGE_AT_CAP",false,"merge")
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
        # Change 71: the shop's saved quantity applies here too (one atomic purchase of that many).
        var amount: int=SettingsState.supply_buy_amount
        var block:=sim.consumable_purchase_block(id,amount)
        _game_action(tr("SHOP_BUY_ITEM") % [amount,fmt_cost(sim.consumable_total(id,amount))],func()->void:if selected==id:_confirmed(sim.purchase_consumables(id,SettingsState.supply_buy_amount)),block.is_empty(),block,more).set_meta("guide","buy_supply_detail")
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
    _toggle_style(_pinned(tr("AUTO_SHORT") % tr("ON" if sim.state.auto_slots.has(slot) else "OFF"),func()->void:if selected==id:sim.bind_auto(sim.state.supplies.find(id)),slot>=0,"CANNOT_USE",false,"auto"),sim.state.auto_slots.has(slot))
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

## Change 81: the Obsidian weapon track, in the outfit form: what is active (only while this weapon is equipped)
## and the next step. Values come from sim.weapon_milestones() / the catalog track.
func _weapon_milestone_lines(box: VBoxContainer,id: String) -> void:
    var parts:=_weapon_milestone_parts(sim.weapon_milestones(id))
    var equipped_now: bool=sim.state.weapon==id
    var tone:=Color(.5,1,.65) if equipped_now and not parts.is_empty() else Color(.75,.8,.87)
    _card_line(box,(tr("MILESTONES_ACTIVE_WEAPON") % ", ".join(parts)) if not parts.is_empty() else tr("MILESTONES_NONE"),17,tone)
    var step:=sim.next_weapon_milestone(id)
    if step.is_empty():
        _card_line(box,tr("MILESTONES_COMPLETE"),17,Color(1,.86,.5))
    else:
        _card_line(box,tr("MILESTONE_NEXT") % [int(step.merge),", ".join(_weapon_milestone_parts(sim.weapon_milestones(id,int(step.merge))))],17,Color(1,.86,.5))

func _weapon_milestone_parts(values: Dictionary) -> Array[String]:
    var parts: Array[String]=[]
    if float(values.crit)>0:parts.append(tr("MILESTONE_WEAPON_CRIT") % fmt_value(float(values.crit)*100))
    if float(values.crit_damage)>0:parts.append(tr("MILESTONE_WEAPON_CRIT_DAMAGE") % fmt_value(float(values.crit_damage)*100))
    if float(values.lifesteal)>0:parts.append(tr("MILESTONE_WEAPON_LIFESTEAL") % fmt_value(float(values.lifesteal)*100))
    if float(values.damage)>0:parts.append(tr("MILESTONE_WEAPON_DAMAGE") % fmt(float(values.damage)))
    return parts

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
    var merge_text:=(tr("ITEM_TIER_MERGE_CAP") % [int(sim.catalog.items[id].tier),int(sim.record(id).merge),sim.merge_cap(id)]) if sim.shows_merge_cap(id) else (tr("ITEM_TIER_MERGE") % [int(sim.catalog.items[id].tier),int(sim.record(id).merge)])
    if sim.catalog.items[id].kind=="consumable":merge_text=tr("SUPPLY_MASTERY_LEVEL") % [sim.supply_mastery(id),sim.merge_cap(id)]
    _card_line(details,merge_text,17,Color(.75,.8,.87))
    return details

## Change 78: green colour of a next-merge gain beside its stat.
const MERGE_GAIN_COLOR:=Color(.45,1,.55)
func _stat_line(parent: Control,text: String,delta: float,key: String,font_size: int,color:=Color.WHITE,gain:="") -> HBoxContainer:
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",10)
    parent.add_child(line)
    var label: Control
    if gain=="":
        label=Label.new()
        label.text=text
        label.add_theme_font_size_override("font_size",font_size)
        label.add_theme_color_override("font_color",color)
        # Change 55: a long stat name wraps instead of widening the sheet past a 432/540 px phone screen.
        label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    else:
        # Change 78: the stat and its next-merge gain in one wrapping line, the gain in green.
        var rich:=RichTextLabel.new()
        rich.bbcode_enabled=true
        rich.fit_content=true
        rich.scroll_active=false
        rich.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        rich.mouse_filter=Control.MOUSE_FILTER_IGNORE
        rich.add_theme_font_size_override("normal_font_size",font_size)
        rich.add_theme_color_override("default_color",color)
        rich.add_theme_color_override("font_outline_color",get_theme_color("font_outline_color","Label"))
        rich.add_theme_constant_override("outline_size",get_theme_constant("outline_size","Label"))
        rich.text="%s  [color=#%s]%s[/color]" % [text.replace("[","[lb]"),MERGE_GAIN_COLOR.to_html(false),gain.replace("[","[lb]")]
        rich.name="MergeGain"
        label=rich
    label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    line.add_child(label)
    if absf(delta)>=.005:
        var change:=Label.new()
        change.text=("▲ " if delta>0 else "▼ ")+_signed_stat(key,delta)
        change.add_theme_font_size_override("font_size",font_size-3)
        change.add_theme_color_override("font_color",Color(.45,1,.55) if delta>0 else Color(1,.5,.45))
        change.add_theme_constant_override("outline_size",3)
        # Change 58 (localization): the delta repeats the stat name, so it shares the row and wraps too. Unwrapped,
        # "▲ +2.57% Bonificación de velocidad de ataque" squeezed the name beside it to one word per line (and
        # split "Bonificació|n") on a boss-enhanced weapon at 432x960.
        change.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        change.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
        change.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        change.size_flags_stretch_ratio=0.8
        line.add_child(change)
    return line

## Change 79: the Lock / Locked toggle at the end of one attribute row of the item panel (key "base:<i>" or
## "boss:<i>", sim.set_reroll_lock). Locked is the ON style. Tapping it changes nothing but the lock and the
## Reroll Stats price, so it is never blocked by the gameplay lock.
const REROLL_LOCK_SIZE:=Vector2(108,52)
func _reroll_lock_toggle(line: HBoxContainer,id: String,key: String) -> Button:
    var locked:=sim.reroll_locked(id,key)
    var button:=Button.new()
    button.name="RerollLock"
    button.set_meta("reroll_lock",key)
    button.text=tr("REROLL_LOCKED" if locked else "REROLL_LOCK")
    button.custom_minimum_size=REROLL_LOCK_SIZE
    button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
    button.add_theme_font_size_override("font_size",17)
    button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
    button.tooltip_text=tr("REROLL_LOCK_RULE")
    _toggle_style(button,locked)
    line.add_child(button)
    # The toggle takes row width: the stat and delta labels ("+ Angriffstempo-Bonus 2.30%", "▲ +3.95% Angriffstempo-
    # Bonus") keep at least their longest word, so a long translated stat name wraps between words, never inside one.
    for child in line.get_children():
        if child is Label:
            var font: Font=child.get_theme_font("font")
            var size: int=child.get_theme_font_size("font_size")
            var widest:=0.0
            for word in str(child.text).split(" ",false):widest=maxf(widest,font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)
            child.custom_minimum_size.x=ceilf(widest)+16
    button.pressed.connect(func()->void:
        if sim.set_reroll_lock(id,key,not sim.reroll_locked(id,key)):
            SaveService.mark_committed()
            AudioService.play("ui_click")
        if sheet.visible:_refresh_panel())
    return button

## Smallest change worth showing; Recovery is a fraction of max HP per second (0.0025 = 0.25%).
func _meaningful(key: String,value: float) -> bool:
    return absf(value)>=(.00001 if key=="regen_pct" else .005)

## Change 78: a next-merge gain in the unit of its stat line ("+0.44", "+1.5%"), without the stat name.
## Empty when the gain is nothing or rounds to zero.
func _merge_gain_text(key: String,value: float) -> String:
    if value<=0:return ""
    var percent: bool=key in ["regen_pct","crit","lifesteal","speed","coin_bonus","crit_damage"]
    var amount:=value*100 if percent else value
    if amount<.005:return ""
    return "+"+(fmt_value(amount) if key=="regen_pct" else fmt(amount))+("%" if percent else "")

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
    # Change 71: on a panel's first build the scroll is not laid out yet; the sheet's width (map width less
    # its insets, margins and scroll bar) is the width it will have.
    var width: float=maxf($Sheet/Margin/Content/Scroll.size.x-24,$Safe/Layout/Map.size.x-sheet_inset.x*2-72)
    var room: float=(maxf(320.0,width)-6.0*(keys.size()-1))/keys.size()-get_theme_stylebox("normal","Button").get_minimum_size().x-4
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
    # Change 65: the one global Focused Farming unlock sits with the Player upgrades.
    # Change 81: Camp Reveal Radius is one permanent Gem upgrade for every camp (it was bought per camp in World).
    var sections: Array=[["respawn","movement","focus","camp_radius","skill_slots","skill_auto_slots","critical_chance","critical_damage"],["gear_slots","supply_slots","merge_all"],["auto_use","use_speed"],["gem_chance","gem_amount","boss_gem_chance","boss_gem_amount"],["offline_cap","offline_coins","offline_gems","offline_weapon","offline_outfit","offline_consumable","offline_skill","offline_weapon_rate","offline_outfit_rate","offline_consumable_rate","offline_skill_rate"]]
    if player_tab==0:_text(tr("UPGRADES_PLAYER_HINT"),17,Color(.75,.8,.87))
    if player_tab==4:
        if not sim.state.offline_pending.is_empty():
            _text(tr("OFFLINE_PENDING_NOTE"),18,Color(1,.86,.5))
            _action(tr("OFFLINE_CLAIM"),func()->void:_open("offline"))
        else:
            var r: Dictionary=sim.campaign.offline_receipt
            if not r.is_empty():
                _text(tr("OFFLINE_CLAIMED_RECEIPT") % [fmt(r.rewarded_hours),fmt_currency(r.coins),fmt_currency(r.gems)])
                # Change 64: the same five categories as the welcome-back receipt (this claim's snapshot).
                _offline_categories(r,false)
                for id in r.items:_text(sim.catalog.display_name(id)+" ×"+fmt(r.items[id]),18)
        var snap: Dictionary=sim.campaign.offline_snapshot()
        _text(tr("OFFLINE_RATES") % [fmt_currency(snap.coins),fmt_currency(snap.gems),fmt(snap.cap/3600)],18,Color(.8,.84,.9))
        # Change 61: what the item unlocks below do, in every mode (no purchase is ever required).
        _text(tr("OFFLINE_TAB_EXPLAIN_V79"),17,Color(.75,.8,.87))
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
            _toggle_style(_game_action(label,func()->void:
                var picks: Array=sim.automatic_skill_assignments()
                if picks.has(i):picks.erase(i)
                else:picks.append(i)
                sim.assign_automatic_skills(picks),available,"AUTO_SKILL_CAPACITY_FULL"),assigned).set_meta("guide","auto_skill_%d" % i)
        # A skill's own upgrades stay hidden until that skill has been obtained once.
        for key in sim.catalog.skills:
            if sim.skill_seen(key):_group_upgrade_card("cooldown_"+key,-1)
    # Inventory filtering moved to the dock's Filters shortcut (Change 11); this tab keeps capacity.
    if player_tab==1:_text(tr("SUPPLY_CAPACITY_NOTE") % sim.supply_ids().size(),17,Color(.75,.8,.87))
    if player_tab==2:
        _text(tr("SUPPLY_MASTERY_EXPLAIN") % int(sim.catalog.progression.supply_mastery.cap),17,Color(.75,.8,.87))
        _auto_buy_section()
        _supply_shop()

## Change 71: the Supplies shop. One purchase quantity shared by every supply (x1, x5, x10, x25 or Custom),
## saved in SettingsState and kept until the player changes it; then one card per priced supply: icon, name,
## unit price, owned count, the quantity and its total, and one Buy button for exactly that many (an atomic
## sim.purchase_consumables). The quantity is never lowered to fit the wallet: the card says why it cannot
## be bought instead. Bought copies add stock only (Supply Mastery grows by use).
const SUPPLY_PRESETS:=[1,5,10,25]
var supply_custom:=false
func _supply_shop() -> void:
    var amount: int=SettingsState.supply_buy_amount
    var custom: bool=supply_custom or not SUPPLY_PRESETS.has(amount)
    _section(tr("SHOP_QUANTITY"))
    var presets:=HBoxContainer.new()
    presets.add_theme_constant_override("separation",6)
    rows.add_child(presets)
    for n in SUPPLY_PRESETS:
        var b:=_shop_chip("×%d" % n,func()->void:supply_custom=false;SettingsState.set_supply_buy_amount(n),presets)
        b.theme_type_variation=&"Primary" if n==amount and not custom else &""
        b.set_meta("guide","supply_qty_%d" % n)
    var c:=_shop_chip(tr("SHOP_CUSTOM"),func()->void:supply_custom=true,presets)
    c.theme_type_variation=&"Primary" if custom else &""
    c.set_meta("guide","supply_qty_custom")
    if custom:
        var stepper:=HBoxContainer.new()
        stepper.add_theme_constant_override("separation",6)
        stepper.alignment=BoxContainer.ALIGNMENT_CENTER
        rows.add_child(stepper)
        for step in [-10,-1]:
            _shop_chip("%+d" % step,func()->void:SettingsState.set_supply_buy_amount(SettingsState.supply_buy_amount+step),stepper).disabled=amount<=1
        var value:=Label.new()
        value.text="×%d" % amount
        value.custom_minimum_size=Vector2(96,0)
        value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
        value.add_theme_font_size_override("font_size",24)
        value.add_theme_color_override("font_color",Color(1,.88,.55))
        stepper.add_child(value)
        for step in [1,10]:
            _shop_chip("%+d" % step,func()->void:SettingsState.set_supply_buy_amount(SettingsState.supply_buy_amount+step),stepper).disabled=amount>=SettingsState.SUPPLY_BUY_MAX
    for id in sim.supply_ids():
        if int(sim.supply(id).get("price",0))>0:_supply_shop_card(id,amount)

## Change 76: Auto Buy Supplies, above the shop. One card per slot (AUTO_BUY_SLOTS): an unlocked slot shows its
## supply (or Off) and what it is doing (restocking rule with the owned count, or what the purchase waits for)
## with a Change button; a locked slot shows its Gem price, and the next one unlocks from its own button (the
## same sim.buy_upgrade as any upgrade card). Change opens a chooser under that slot: every shop supply, the
## one in this slot highlighted, those in other slots disabled with their slot number, and Off.
var auto_buy_edit:=-1
func _auto_buy_section() -> void:
    _section(tr("AUTO_BUY_TITLE"))
    _text(tr("AUTO_BUY_EXPLAIN") % [sim.AUTO_BUY_BELOW,sim.AUTO_BUY_AMOUNT],17,Color(.75,.8,.87))
    var capacity:=sim.auto_buy_capacity()
    if auto_buy_edit>=capacity:auto_buy_edit=-1
    var picks:=sim.auto_buy_selection()
    var prices: Array=sim.catalog.upgrades.auto_buy_slots.get("prices",[])
    for i in range(sim.AUTO_BUY_SLOTS):
        var unlocked: bool=i<capacity
        var id: String=picks[i] if unlocked else ""
        var card:=PanelContainer.new()
        card.theme_type_variation=&"Card"
        card.set_meta("guide","auto_buy_slot_%d" % i)
        rows.add_child(card)
        var line:=HBoxContainer.new()
        line.add_theme_constant_override("separation",12)
        card.add_child(line)
        if not unlocked:_card_icon(line,GEM,Color(1,1,1,.55),52)
        elif id!="":_card_icon(line,icon_cache.get(id),Color.WHITE,52)
        else:_card_icon(line,icon_cache.get("potion"),Color(1,1,1,.35),52)
        var text:=VBoxContainer.new()
        text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        text.add_theme_constant_override("separation",2)
        line.add_child(text)
        var button:=Button.new()
        button.custom_minimum_size=Vector2(128,76)
        button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
        button.add_theme_font_size_override("font_size",20)
        button.focus_mode=Control.FOCUS_NONE
        if unlocked:
            var name: String=sim.catalog.display_name(id) if id!="" else tr("OFF")
            _card_line(text,tr("AUTO_BUY_SLOT") % [i+1,name],20,Color.WHITE if id!="" else Color(.75,.8,.87))
            var status:=tr("AUTO_BUY_EMPTY")
            var color:=Color(.7,.75,.82)
            if id!="":
                var wait:=sim.auto_buy_wait_reason(id)
                status=tr("AUTO_BUY_WAITING") % tr(wait) if not wait.is_empty() else tr("AUTO_BUY_RULE") % [sim.AUTO_BUY_AMOUNT,sim.AUTO_BUY_BELOW,fmt_count(sim.quantity(id))]
                color=Color(1,.72,.45) if not wait.is_empty() else Color(.6,1,.75)
            _card_line(text,status,17,color)
            button.text=tr("AUTO_BUY_CHANGE")
            button.theme_type_variation=&"Primary" if auto_buy_edit==i else &""
            button.set_meta("guide","auto_buy_change_%d" % i)
            button.pressed.connect(func()->void:
                auto_buy_edit=-1 if auto_buy_edit==i else i
                AudioService.play("ui_click")
                if sheet.visible:_refresh_panel())
        else:
            var price: int=int(prices[mini(i,prices.size()-1)]) if not prices.is_empty() else sim.upgrade_cost("auto_buy_slots")
            _card_line(text,tr("AUTO_BUY_SLOT") % [i+1,tr("AUTO_BUY_LOCKED")],20,Color(.75,.8,.87))
            var next: bool=i==capacity
            var reason:=sim.upgrade_block_reason("auto_buy_slots") if next else "AUTO_BUY_UNLOCK_ORDER"
            _card_line(text,tr("AUTO_BUY_UNLOCK_PRICE") % fmt_cost(price)+("" if reason.is_empty() else "  ·  "+tr(reason)),17,Color(1,.72,.45) if not reason.is_empty() else Color(.7,.75,.82))
            button.text=fmt_cost(price)
            button.icon=GEM
            button.expand_icon=true
            button.add_theme_constant_override("icon_max_width",26)
            button.disabled=not reason.is_empty()
            button.theme_type_variation=&"Primary" if reason.is_empty() else &""
            button.tooltip_text=tr(reason) if not reason.is_empty() else tr("UP_AUTO_BUY_SLOTS")
            button.set_meta("guide","auto_buy_unlock_%d" % i)
            button.pressed.connect(func()->void:
                if _confirmed(sim.buy_upgrade("auto_buy_slots")):auto_buy_edit=i
                else:AudioService.play("ui_click")
                if sheet.visible:_refresh_panel())
        line.add_child(button)
        if unlocked and auto_buy_edit==i:_auto_buy_chooser(i,picks)

## The supplies slot `slot` may hold, two per row: finger-sized chips with the supply's icon.
func _auto_buy_chooser(slot: int,picks: Array) -> void:
    _text(tr("AUTO_BUY_CHOOSE") % (slot+1),17,Color(1,.86,.5))
    var grid:=GridContainer.new()
    grid.columns=2
    grid.add_theme_constant_override("h_separation",8)
    grid.add_theme_constant_override("v_separation",8)
    rows.add_child(grid)
    var options: Array=sim.supply_ids().filter(func(v):return sim.auto_buy_eligible(str(v)))
    options.append("")
    for id in options:
        var other:=picks.find(id) if id!="" else -1
        var b:=Button.new()
        b.text=(sim.catalog.display_name(id) if id!="" else tr("OFF"))+("\n"+tr("AUTO_BUY_IN_SLOT") % (other+1) if other>=0 and other!=slot else "")
        b.icon=icon_cache.get(id) if id!="" else null
        b.expand_icon=true
        b.add_theme_constant_override("icon_max_width",36)
        b.alignment=HORIZONTAL_ALIGNMENT_LEFT
        b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        b.custom_minimum_size=Vector2(0,64)
        b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        b.add_theme_font_size_override("font_size",18)
        b.focus_mode=Control.FOCUS_NONE
        var reason:=sim.auto_buy_block(slot,id)
        b.disabled=not reason.is_empty()
        b.tooltip_text=tr(reason) if not reason.is_empty() else ""
        b.theme_type_variation=&"Primary" if picks[slot]==id else &""
        b.set_meta("guide","auto_buy_pick_"+(id if id!="" else "off"))
        b.pressed.connect(func()->void:
            if _confirmed(sim.set_auto_buy(slot,id)):auto_buy_edit=-1
            else:AudioService.play("ui_click")
            if sheet.visible:_refresh_panel())
        grid.add_child(b)

## A quantity chip: the normal game button at a compact, still finger-sized height.
func _shop_chip(text: String,callback: Callable,parent: Node) -> Button:
    var b:=Button.new()
    b.text=text
    b.custom_minimum_size=Vector2(0,56)
    b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size",19)
    b.focus_mode=Control.FOCUS_NONE
    parent.add_child(b)
    b.pressed.connect(func()->void:
        callback.call()
        AudioService.play("ui_click")
        if sheet.visible:_refresh_panel())
    return b

func _supply_shop_card(id: String,amount: int) -> void:
    var unit:=int(sim.supply(id).get("price",0))
    var total:=sim.consumable_total(id,amount)
    var reason:=sim.consumable_purchase_block(id,amount)
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    rows.add_child(card)
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",12)
    card.add_child(line)
    _card_icon(line,icon_cache.get(id),Color.WHITE,52)
    var text:=VBoxContainer.new()
    text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    text.add_theme_constant_override("separation",2)
    line.add_child(text)
    # Change 76: a supply Auto Buy restocks says so on its card.
    _card_line(text,sim.catalog.display_name(id)+("  ·  "+tr("AUTO_BUY_BADGE") if sim.auto_buy_ids().has(id) else ""),20,Color.WHITE)
    _card_line(text,tr("SHOP_UNIT_OWNED") % [fmt_cost(unit),fmt_count(sim.quantity(id))],17,Color(.8,.84,.9))
    # Fixed rows (Playbook 128.3): the total line always, and a reserved reason line (blank while buyable).
    _card_line(text,tr("SHOP_TOTAL") % [amount,fmt_cost(total)],17,Color(1,.88,.55))
    _card_line(text,tr(reason) if not reason.is_empty() else " ",17,Color(1,.72,.45))
    var buy:=Button.new()
    buy.custom_minimum_size=Vector2(128,76)
    buy.size_flags_vertical=Control.SIZE_SHRINK_CENTER
    buy.text=tr("SHOP_BUY_N") % amount
    buy.disabled=not reason.is_empty()
    buy.theme_type_variation=&"Primary" if reason.is_empty() else &""
    buy.tooltip_text=tr(reason) if not reason.is_empty() else tr("SHOP_TOTAL") % [amount,fmt_cost(total)]
    buy.add_theme_font_size_override("font_size",20)
    buy.set_meta("guide","buy_supply_"+id)
    buy.pressed.connect(func()->void:
        _confirmed(sim.purchase_consumables(id,SettingsState.supply_buy_amount))
        SaveService.mark_committed()
        if sheet.visible:_refresh_panel())
    line.add_child(buy)

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
    # Change 81: the Auto Skill prerequisite names the manual slot it waits for.
    var reason_text: String=(tr(reason) % sim.auto_skill_required_slot()) if reason=="AUTO_SKILL_NEEDS_SLOT" else tr(reason)
    var status:=Label.new()
    status.name="BlockReason"
    status.text=(tr("UPGRADE_LEVEL") % [current,mini(int(def.cap),ceili((float(sim.catalog.groups[g].respawn)-15.0)/5.0)) if id=="boss_spawn_cooldown" and g>=0 else def.cap])+("" if reason.is_empty() or reason=="UPGRADE_MAX" else "  ·  "+reason_text)
    status.tooltip_text=reason_text if not reason.is_empty() else ""
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
    buy.tooltip_text=reason_text if not reason.is_empty() else tr("UP_"+id.to_upper())
    buy.set_meta("upgrade",id)
    buy.set_meta("guide","buy_"+id if id in ["loot","gear_slots","supply_slots","map_detail","focus"] else "buy_upgrade")
    buy.pressed.connect(func()->void:
        if not _confirmed(sim.buy_upgrade(id,g)):AudioService.play("ui_click"))
    line.add_child(buy)
    action_buttons.append({"node":buy,"kind":"upgrade","id":id,"group":g})

func _upgrade_icon(id: String,g: int) -> Texture2D:
    var def: Dictionary=sim.catalog.upgrades[id]
    var icon: Texture2D=icon_cache.get(sim.catalog.groups[g].body) if g>=0 and def.scope in ["type","normal_type","boss_type"] else _art(147)
    if id.begins_with("cooldown_"):icon=icon_cache.get("skill_"+id.trim_prefix("cooldown_"))
    elif id in ["auto_use","use_speed","supply_slots","supply_drop","auto_buy_slots"]:icon=icon_cache.get("potion")
    elif id in ["map_detail","camp_radius","reveal_radius"]:icon=_art(249)
    elif id=="merge_all":icon=_art(147)
    elif id.begins_with("offline_"):icon=_art(171)
    if id=="coin_amount":icon=COIN
    elif id in ["gem_chance","gem_amount","boss_gem_chance","boss_gem_amount"]:icon=GEM
    elif id in ["loot","merge_gear","auto_evolve","boss_item_rolls"] and g>=0:icon=icon_cache.get(sim.catalog.groups[g].weapon)
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
    if id=="auto_buy_slots":
        var n:=sim.auto_buy_capacity()
        return tr("UPGRADE_TRANSITION") % [str(n),str(n+1)] if next>0 else tr("UPGRADE_MAXED_VALUE") % str(n)
    if id=="merge_all":return tr("MERGE_ALL_UNLOCKED") if sim.level(id)>0 else tr("MERGE_ALL_BENEFIT")
    # Change 66: the unlock's description says what it does, including the return after a respawn.
    if id=="focus":return tr("FOCUS_GLOBAL_OWNED") if sim.focus_owned() else tr("FOCUS_GLOBAL_BENEFIT")
    # Change 13: each per-type unlock names the exact items it covers (what this type drops; never
    # the tiers evolved from them, which follow their own droppers).
    if id=="merge_gear" and g>=0:
        var drops: Array=sim.catalog.groups[g].loot.duplicate()
        for skill in sim.catalog.groups[g].skills:drops.append("skill_"+str(skill))
        return tr("AUTO_MERGE_ON" if sim.level(id,g)>0 else "AUTO_MERGE_BENEFIT") % _item_names(drops)
    if id=="auto_evolve" and g>=0:
        return tr("AUTO_EVOLVE_ON" if sim.level(id,g)>0 else "AUTO_EVOLVE_BENEFIT") % _item_names(sim.evolvable_drops(g))
    if id=="boss_item_rolls":return tr("BOSS_ITEM_ROLLS_BENEFIT") % [1+sim.level(id,g),mini(5,2+sim.level(id,g))] if next>0 else tr("BOSS_ITEM_ROLLS_MAX") % 5
    # Change 55 M2: Map Detail names its next rank's real benefit (1 markers, 2 names, 3 loadouts).
    if id=="map_detail" and g>=0:
        if next==0:return tr("UPGRADE_MAXED_VALUE") % str(sim.level(id,g))
        return tr("MAP_DETAIL_NEXT_%d" % (sim.level(id,g)+1))
    # Change 55 O2: offline gear copies only gear already owned.
    if id in ["offline_weapon","offline_outfit"]:
        return tr("OFFLINE_GEAR_BENEFIT") if sim.level(id)==0 else tr("UPGRADE_TRANSITION") % [tr("ON"),tr("ON")]
    # Change 79: copies of skills already owned, at half the gear rate.
    if id=="offline_skill":
        return tr("OFFLINE_SKILL_BENEFIT") if sim.level(id)==0 else tr("UPGRADE_TRANSITION") % [tr("ON"),tr("ON")]
    if int(sim.catalog.upgrades[id].cap)==1:
        return tr("UPGRADE_TRANSITION") % [tr("ON" if sim.level(id,g)>0 else "OFF"),tr("ON")]
    if id in ["critical_chance","critical_damage"]:return _critical_benefit(id,next)
    var current:=sim.group_upgrade_value(id,g,enemy_variant) if g>=0 else sim.player_upgrade_value(id)
    var future:=sim.group_upgrade_value(id,g,enemy_variant,next) if g>=0 else sim.player_upgrade_value(id,next)
    var percent:=id in ["loot","supply_drop","skill_drop","gem_chance","boss_gem_chance","movement","reveal_radius","camp_radius"]
    var left:=fmt_value(current*100)+"%" if percent else fmt_value(current)
    var right:=fmt_value(future*100)+"%" if percent else fmt_value(future)
    # Change 13: coin and gem amounts use the shared currency format.
    if id in CURRENCY_UPGRADES:
        left=fmt_currency(current);right=fmt_currency(future)
    var value:=tr("UPGRADE_TRANSITION") % [left,right] if next>0 else tr("UPGRADE_MAXED_VALUE") % left
    if id=="boss_gem_amount":value=tr("BOSS_GEMS_PER_DROP") % value
    if id in ["respawn","collect_speed","gear_merge_speed","use_speed","spawn_cooldown","boss_spawn_cooldown"]:value=tr("SECONDS_VALUE") % value
    if id=="supply_drop":value=tr("POTION_CHANCE_VALUE") % value
    return value

## Change 68: the critical upgrades show the player's real effective stat now -> after the next level,
## both read from sim.stats() (equipped and stored gear, Prestige, every source; chance stops at 100%),
## so the row never offers a gain combat would suppress. Critical Damage is the whole hit: 110% = x1.10.
func _critical_benefit(id: String,next: int) -> String:
    var key:="crit" if id=="critical_chance" else "crit_damage"
    var now:=float(sim.stats()[key])
    var left:=fmt_value(now*100)+"%"
    var after:=now if next==0 else float(sim.stats_with_upgrade(id,next)[key])
    var gain:=after>now+.00001
    var value:=tr("UPGRADE_TRANSITION") % [left,fmt_value(after*100)+"%"] if gain else left
    if id=="critical_damage":value=tr("CRIT_HIT_DAMAGE_VALUE") % value
    if next==0:return tr("UPGRADE_MAXED_VALUE") % value
    return value if gain else tr("CRIT_UPGRADE_CAPPED") % value

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
    if sim.focus_owned():
        # Change 14: right after the first Focused Farming purchase, one line above the button says
        # what it does (above it, because the guide's arrow points at the button from below here).
        if sim.campaign.focus_hint==group and int(sim.state.focus)<0:_text(tr("FOCUS_HINT_PANEL_WALK"),17,Color(1,.86,.5))
        # Change 69: the same action and state as the map's Auto Farm button (sim.focus / sim.focus_active).
        var farming: bool=sim.focus_active(group,enemy_variant)
        _toggle_style(_game_action(tr("FOCUS_GROUP") % [d.name,tr("ON" if farming else "OFF")],func()->void:sim.focus(group,enemy_variant),sim.campaign.spot_discovered(group,enemy_variant),"SPOT_UNDISCOVERED"),farming,not sim.campaign.spot_discovered(group,enemy_variant)).set_meta("guide","focus_toggle")
    else:
        # Change 65: Focused Farming is one global Player upgrade. Before it is owned, the Farm action is
        # shown locked with its reason and a way to the Player upgrade (never a purchase here).
        _toggle_style(_game_action(tr("FOCUS_GROUP") % [d.name,tr("OFF")],func()->void:pass,false,"FOCUS_LOCKED_GLOBAL"),false,true).set_meta("guide","focus_locked")
        if revealed("upgrades"):
            _action(tr("FOCUS_OPEN_PLAYER_UPGRADES"),func()->void:
                player_tab=0
                _open("upgrades"),true,"").set_meta("guide","focus_open_upgrades")
    if enemy_tab==1:
        _section(tr("SECTION_REWARDS"))
        for id in ["loot","coin_amount","group_xp","supply_drop"]:_group_upgrade_card(id,group)
        if not d.skills.is_empty():_group_upgrade_card("skill_drop",group)
        if d.boss:
            _group_upgrade_card("boss_spawn_cooldown",group);_group_upgrade_card("boss_item_rolls",group)
        else:
            _group_upgrade_card("spawn_amount",group);_group_upgrade_card("spawn_cooldown",group)
        # Automation refinements appear once their automation is unlocked.
        _section(tr("SECTION_AUTOMATION"))
        # Change 13: Auto Evolution sits beside Auto-Merge, on types that drop an evolvable weapon.
        # Change 65: Focused Farming left this list (one global Player upgrade); automation stays per type.
        for pair in [["collect",""],["collect_range","collect"],["collect_batch","collect"],["collect_speed","collect"],["merge_gear",""],["auto_evolve",""],["gear_merge_speed","merge_gear"]]:
            if pair[0]=="auto_evolve" and (d.boss or sim.evolvable_drops(group).is_empty()):continue
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
    # Change 66: kill milestones reward damage against this enemy type only (no Gem Chance).
    _text(tr("ACHIEVEMENT_DAMAGE_BONUS") % [sim.catalog.groups[group].name,sim.achievement_damage(group)*100],20,Color(.6,1,.75))
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
    _text(tr("ACHIEVEMENT_DAMAGE_REWARD") % (sim.catalog.progression.achievements.damage_per_milestone*100)+"  ·  "+tr("ACHIEVEMENT_PERMANENT"),17,Color(.75,.8,.87))

func _refresh_combat_achievement() -> void:
    var target: Dictionary=sim._find_actor(sim.locked_target)
    if not target.is_empty() and int(target.group) in range(sim.catalog.groups.size()):
        combat_group=int(target.group)
    # Change 69: walking by hand no longer ends Focused Farming at once, so while the player walks the
    # controls follow the group they approach (as before Change 69, when walking cleared the focus).
    elif int(sim.state.focus) in range(sim.catalog.groups.size()) and sim.movement.length()<=.1:
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
    # Change 72: the tile shows the star and the count; the name is in its tooltip and in the panel it opens.
    var text:=progress.replace(" ","")
    if button.text!=text:
        button.text=text
        button.add_theme_font_size_override("font_size",_fitting_font_size(text,ACHIEVEMENT_WIDTH-18,TILE_FONT,16))
    var tip:=tr("TAB_ACHIEVEMENTS")+"\n"+progress
    if button.tooltip_text!=tip:button.tooltip_text=tip
    button.set_meta("group",g)
    _refresh_quick_farm(known)

## Change 69: the spot of group g the map's Auto Farm button acts on: the selected target's spot when g is
## focused, else the discovered spot nearest the player (-1 when none is discovered).
func _quick_spot(g: int) -> int:
    if int(sim.state.focus)==g:return int(sim.state.focus_variant)
    var best:=-1
    var distance:=INF
    var at: Vector2=sim.position_of(sim.state.player)
    for v in sim.campaign.variants(g):
        if not sim.campaign.spot_discovered(g,v):continue
        var d:=at.distance_to(sim.campaign.spot(g,v))
        if d<distance:
            best=v;distance=d
    return best

## Change 69: the third contextual control, below Achievements and Upgrades: one Auto Farm button showing
## the live state of THIS group's spot (ON green when it is the selected Focused Farming target, OFF red
## otherwise, Locked grey before the global 25-Gem purchase). It appears with the Upgrades route.
func _refresh_quick_farm(known: bool) -> void:
    var quick: Button=$Safe/Layout/Map/QuickFarm
    var g:=combat_group
    quick.visible=known and revealed("upgrades")
    if not quick.visible:return
    var v:=_quick_spot(g)
    if g!=int(quick.get_meta("group",-1)) or v!=int(quick.get_meta("variant",-99)):
        quick_changed_msec=Time.get_ticks_msec()
    quick.set_meta("group",g);quick.set_meta("variant",v)
    var text: String
    var reason:=""
    if not sim.focus_owned():
        text=tr("AUTO_FARM_LOCKED");reason="FOCUS_LOCKED_GLOBAL"
        _toggle_style(quick,false,true)
        quick.set_meta("guide","quick_focus_locked")
    else:
        var on: bool=v>=0 and sim.focus_active(g,v)
        text=tr("AUTO_FARM_STATE") % tr("STATE_ON_CAPS" if on else "STATE_OFF_CAPS")
        if v<0:reason="SPOT_UNDISCOVERED"
        elif not sim.action_lock_reason().is_empty():reason=sim.action_lock_reason()
        _toggle_style(quick,on,v<0)
        quick.set_meta("guide","quick_focus_toggle")
    quick.set_meta("reason",reason)
    # Change 72: the tile shows the Auto Farm icon in the toggle's colour with ON / OFF under it (nothing
    # while locked: the grey tile says so, and a tap explains); the full state is the tooltip and state_text.
    quick.set_meta("state_text",text)
    var caption: String="" if not sim.focus_owned() else tr("STATE_ON_CAPS" if sim.focus_active(g,v) and v>=0 else "STATE_OFF_CAPS")
    if quick.text!=caption or quick.get_meta("fitted","")!=caption:
        quick.text=caption
        quick.set_meta("fitted",caption)
        quick.vertical_icon_alignment=VERTICAL_ALIGNMENT_CENTER if caption=="" else VERTICAL_ALIGNMENT_TOP
        quick.add_theme_font_size_override("font_size",_fitting_font_size(caption,TILE_SIDE-14,TILE_FONT,16))
    var tip: String=tr(sim.catalog.groups[g].name)+" · "+text+("\n"+tr(reason) if reason!="" else "")
    if quick.tooltip_text!=tip:quick.tooltip_text=tip

## Change 69: the map's Auto Farm button and the enemy panel's Farm button both call sim.focus(group,
## variant) (start, switch or stop at once). Locked, it explains why and opens Player Upgrades (the same
## route as the panel's locked Farm action); it never buys anything.
func _quick_farm_pressed() -> void:
    var quick: Button=$Safe/Layout/Map/QuickFarm
    if Time.get_ticks_msec()-quick_changed_msec<QUICK_SETTLE_MSEC:return
    var g:=int(quick.get_meta("group",-1))
    var v:=int(quick.get_meta("variant",-1))
    AudioService.play("ui_click")
    if not sim.focus_owned():
        _say(tr("FOCUS_LOCKED_GLOBAL"))
        if revealed("upgrades"):
            player_tab=0
            _open("upgrades")
        return
    if g<0 or g>=sim.catalog.groups.size():return
    if v<0:
        _say(tr("SPOT_UNDISCOVERED"));return
    if sim.focus(g,v):SaveService.mark_committed()
    _refresh_combat_achievement()

## Change 69: one look for every player-operable binary ON/OFF button: green ToggleOn, red ToggleOff, or
## the grey ToggleLocked when it is unavailable for another reason (the label still states ON/OFF or why).
## A disabled button keeps its state label and uses the theme's shared disabled look.
func _toggle_style(button: Button,on: bool,locked:=false) -> Button:
    var variation: StringName=&"ToggleLocked" if locked else (&"ToggleOn" if on else &"ToggleOff")
    if button.theme_type_variation!=variation:button.theme_type_variation=variation
    return button

## Change 69: "Turning off Auto Farming in 5..." while one continuous manual walk runs under a Focused
## Farming target, in the band right above the joystick (the toast moves above it), clear of the guide.
func _update_focus_countdown() -> void:
    var box: PanelContainer=$FocusCountdown
    var left:=sim.focus_walk_remaining()
    if left<=0 or sheet.visible or modal_open() or get_tree().paused:
        if box.visible:box.hide()
        return
    var text:=tr("FOCUS_WALK_COUNTDOWN") % left
    if $FocusCountdown/Text.text!=text:$FocusCountdown/Text.text=text
    var map: Control=$Safe/Layout/Map
    var width:=minf(560,map.size.x-48)
    if $FocusCountdown/Text.custom_minimum_size.x!=width-28:$FocusCountdown/Text.custom_minimum_size.x=width-28
    # Measured from the font: a hidden container never lays out its label, so its minimum size is stale.
    var label: Label=$FocusCountdown/Text
    var font_size: int=label.get_theme_font_size("font_size")
    var text_height: float=label.get_theme_font("font").get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,width-28,font_size).y
    var wanted:=Vector2(width,ceilf(text_height+box.get_theme_stylebox("panel").get_minimum_size().y))
    if not box.size.is_equal_approx(wanted):box.size=wanted
    var x: float=map.global_position.x+(map.size.x-width)*.5
    var y: float=map.global_position.y+map.size.y-212-wanted.y
    var blocked: Array=guide.occupied_rects()
    for i in range(blocked.size()+1):
        var hit:=Rect2()
        for r in blocked:
            if r.intersects(Rect2(x,y,width,wanted.y)) and (hit.size==Vector2.ZERO or r.position.y<hit.position.y):hit=r
        if hit.size==Vector2.ZERO:break
        y=hit.position.y-8-wanted.y
    # With no free place left in the map (the guide covers it) the warning waits; the timer still runs.
    if y<map.global_position.y+8:
        if box.visible:box.hide()
        return
    box.position=Vector2(x,y)
    if not box.visible:box.show()

func _open_combat_achievements() -> void:
    group=int($Safe/Layout/Map/Achievement.get_meta("group",0))
    enemy_tab=2
    _open("enemy")

# ---------------------------------------------------------------- world, camps and travel

func _camp_status(st: int,i: int) -> String:
    var owned: bool=sim.state.camps.get(str(st),[0]).has(i)
    var line: String=tr("CAMP_STATE_SELECTED") if st==int(sim.state.stage) and int(sim.state.spawn)==i else (tr("CAMP_STATE_OWNED") if owned else tr("CAMP_STATE_LOCKED") % fmt_cost(sim.campaign.camp_price(i)))
    # Change 80: an owned camp says when its Camp Supplies are next ready (only with the card).
    if owned and sim.campaign.camp_supplies_owned():line+="
"+_camp_supply_status(st,i)
    return line

## Change 80: "Camp Supplies: ready (3)" or "Camp Supplies: next in 7m 12s" for one owned camp.
func _camp_supply_status(st: int,i: int) -> String:
    var wait: float=sim.campaign.camp_supply_wait(st,i)
    if wait>0:return tr("CAMP_SUPPLY_STATUS_WAIT") % fmt_duration(ceilf(wait))
    return tr("CAMP_SUPPLY_STATUS_READY") % sim.campaign.camp_supply_owed(st,i)

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
    # Change 61: any drawn marker reports its tap (the Guided enemy-marker lesson). With Map Details
    # rank 1 a marker only says that enemies were found there (rank 2 opens the enemy, as before).
    map.marker_tapped.connect(func(g: int,_v: int)->void:
        sim.campaign.guided.action("pin",str(g))
        if sim.level("map_detail",int(sim.state.stage))<2:_say(tr("MAP_MARKER_RANK1")))
    map.set_meta("guide_map",true)
    rows.add_child(map)
    if sim.level("map_detail",int(sim.state.stage))>=2:
        var known:=HFlowContainer.new()
        known.add_theme_constant_override("h_separation",8)
        rows.add_child(known)
        for g in stage.groups:
            if sim.campaign.discovered(g):
                var b:=_action(sim.catalog.groups[g].name,func()->void:group=g;enemy_variant=2;enemy_tab=0;_open("enemy"),true,"",known)
                b.size_flags_horizontal=0;b.custom_minimum_size=Vector2(0,56);b.add_theme_font_size_override("font_size",17)
                # Change 83: the final boss keeps its identity here too (its portrait, the map marker's green).
                if bool(sim.catalog.groups[g].final):
                    b.icon=_final_art();b.add_theme_constant_override("icon_max_width",30)
                    b.add_theme_color_override("font_color",Color(.55,1,.6))
    elif map_detail_hint_due() and hint_allowed("map_detail"):
        _text(tr("MAP_MARKERS_HINT"),17,Color(1,.86,.5))
        _action(tr("SECTION_MAP_UPGRADES"),func()->void:_scroll_to_section(tr("SECTION_MAP_UPGRADES"))).set_meta("guide","map_upgrades_jump")
    else:_text(tr("MAP_LEGEND"),17,Color(.7,.75,.82))
    # Change 10: the map-by-map Farming Guide (opens per map once its research is complete).
    _action(tr("FARMING_GUIDE_OPEN"),func()->void:guide_stage=0;_open("farming")).set_meta("guide","farming_guide")
    # Change 15: Map Mastery (revealed with Prestige, after the Snowman).
    if revealed("prestige"):
        # Change 83: Map Mastery and the four-part Game Completion are different numbers; the row names both.
        _action(tr("MASTERY_OPEN_V83") % [sim.campaign.mastery.game_percent(),sim.campaign.completion.percent()],func()->void:mastery_stage=0;_open("mastery")).set_meta("guide","mastery")
    _stage_progression()
    _section(tr("SECTION_MAP_UPGRADES"))
    for id in ["map_detail","reveal_radius"]:_group_upgrade_card(id,int(sim.state.stage))
    # Change 81: the camps share one global Camp Reveal Radius (Upgrades > Player); no per-camp purchase here.
    _text(tr("CAMP_RADIUS_GLOBAL_NOTE") % fmt_value(sim.player_upgrade_value("camp_radius")*100),17,Color(.75,.8,.87))

## Change 80: the stage selector. Every stage 01-08 in canonical order, one compact card each, grouped under its
## season, with this run's state from campaign.stage_progress(): a status line (gate cleared / unlocked with its
## gate progress / locked, NEXT saying what opens it), a HERE badge and ring on the map the player stands on and
## a NEXT badge and gold ring on the next stage to unlock (from the frontier, never from the current map). An
## unlocked map other than the current one travels exactly as before (_select_travel_stage; guide key
## travel_stage_N); the current map and locked maps cannot be chosen. Built with the panel (at most once a
## second, never while the sheet scrolls), never per frame.
const SEASON_KEYS:=["SEASON_WINTER","SEASON_SUMMER","SEASON_AUTUMN","SEASON_SPRING"]
const SEASON_COLORS:=[Color(.62,.84,1),Color(1,.84,.38),Color(1,.6,.32),Color(.6,.92,.5)]
const STAGE_NEXT_RING:=Color(1,.82,.3)
const GAME_THEME:=preload("res://resources/game/theme.tres")
func _stage_progression() -> void:
    _section(tr("SECTION_TRAVEL"))
    var states: Array=sim.campaign.stage_progress()
    var next:=sim.campaign.next_stage_to_unlock()
    var summary: String=tr("STAGE_PROGRESS_SUMMARY") % [int(sim.state.unlocked_stage),states.size()]
    summary+="\n"+(tr("STAGE_PROGRESS_NEXT") % sim.catalog.stages[next-1].name if next>0 else tr("STAGE_PROGRESS_ALL"))
    _text(summary,17,Color(.8,.84,.9)).set_meta("stage_summary",true)
    var list:=VBoxContainer.new()
    list.add_theme_constant_override("separation",6)
    list.set_meta("stage_list",true)
    rows.add_child(list)
    for s in states:
        var season: int=(int(s.stage)-1)/2
        if (int(s.stage)-1)%2==0:
            var head:=Label.new()
            head.text=tr(SEASON_KEYS[mini(season,3)])
            head.add_theme_font_size_override("font_size",17)
            head.add_theme_color_override("font_color",SEASON_COLORS[mini(season,3)])
            head.set_meta("season_header",season)
            list.add_child(head)
        list.add_child(_stage_row(s,SEASON_COLORS[mini(season,3)]))

func _stage_status(s: Dictionary) -> String:
    var st: int=int(s.stage)
    if bool(s.cleared):return tr("STAGE_STATUS_FINAL_CLEARED" if bool(s.final) else "STAGE_STATUS_CLEARED")
    if bool(s.unlocked):return tr("STAGE_STATUS_FINAL_OPEN") if bool(s.final) else tr("STAGE_STATUS_OPEN") % [int(s.gate_done),int(s.gate_total)]
    if bool(s.next):return tr("STAGE_STATUS_NEXT") % sim.catalog.stages[st-2].name
    return tr("STAGE_STATUS_LOCKED")

func _stage_badge(parent: Node,text: String,color: Color) -> void:
    var chip:=PanelContainer.new()
    var box:=StyleBoxFlat.new()
    box.bg_color=Color(color.r,color.g,color.b,.22);box.border_color=color
    box.set_border_width_all(2);box.set_corner_radius_all(8)
    box.content_margin_left=8;box.content_margin_right=8;box.content_margin_top=2;box.content_margin_bottom=2
    chip.add_theme_stylebox_override("panel",box)
    chip.mouse_filter=Control.MOUSE_FILTER_IGNORE
    chip.size_flags_vertical=Control.SIZE_SHRINK_CENTER
    var label:=Label.new()
    label.text=text
    label.add_theme_font_size_override("font_size",15)
    label.add_theme_color_override("font_color",color)
    chip.add_child(label)
    parent.add_child(chip)

## One stage card: number, name, status line, badges, followed-objective icons, and a travel chevron when it can
## be chosen. The card sizes to its wrapped text; a flat full-card button on top takes the tap.
func _stage_row(s: Dictionary,season_color: Color) -> Control:
    var st: int=int(s.stage)
    var here: bool=bool(s.here)
    var can_travel: bool=bool(s.unlocked) and not here
    var card:=PanelContainer.new()
    # The panel refresh reuses a live control of the same shape and copies only a few properties (never a
    # stylebox override), so the card's look is keyed by its theme_type_variation, which _same_shape compares:
    # a stage whose state changes gets a new card. These variation names are not theme types; the override
    # below draws the card.
    var look: String="here" if here else ("next" if bool(s.next) else ("open" if bool(s.unlocked) else "locked"))
    card.theme_type_variation=StringName("StageCard_"+look)
    card.set_meta("stage_row",st)
    card.set_meta("stage_state",s)
    # Compact cards (8 px above and below instead of the Card's 14); the current map and the next stage get a
    # coloured ring (cyan HERE, gold NEXT).
    var box: StyleBox
    if here or bool(s.next):
        var flat:=StyleBoxFlat.new()
        flat.bg_color=Color(.2,.29,.34) if here else Color(.24,.24,.2)
        flat.border_color=camp_picker.HERE_RING if here else STAGE_NEXT_RING
        flat.set_border_width_all(3);flat.set_corner_radius_all(8)
        box=flat
    else:box=GAME_THEME.get_stylebox("panel","Card").duplicate()
    box.content_margin_left=12;box.content_margin_right=12;box.content_margin_top=8;box.content_margin_bottom=8
    card.add_theme_stylebox_override("panel",box)
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",10)
    line.mouse_filter=Control.MOUSE_FILTER_IGNORE
    line.custom_minimum_size.y=52
    card.add_child(line)
    var number:=Label.new()
    number.text="%02d" % st
    number.custom_minimum_size.x=34
    number.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    number.add_theme_font_size_override("font_size",22)
    number.add_theme_color_override("font_color",season_color if bool(s.unlocked) or bool(s.next) else Color(.55,.58,.64))
    line.add_child(number)
    var text:=VBoxContainer.new()
    text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    text.alignment=BoxContainer.ALIGNMENT_CENTER
    text.mouse_filter=Control.MOUSE_FILTER_IGNORE
    text.add_theme_constant_override("separation",0)
    line.add_child(text)
    var name_row:=HFlowContainer.new()
    name_row.add_theme_constant_override("h_separation",8)
    name_row.add_theme_constant_override("v_separation",4)
    name_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
    text.add_child(name_row)
    var title:=Label.new()
    title.text=sim.catalog.stages[st-1].name
    title.add_theme_font_size_override("font_size",20)
    title.add_theme_color_override("font_color",Color.WHITE if bool(s.unlocked) else Color(.7,.72,.78))
    name_row.add_child(title)
    if here:_stage_badge(name_row,tr("STAGE_BADGE_HERE"),camp_picker.HERE_RING)
    if bool(s.next):_stage_badge(name_row,tr("STAGE_BADGE_NEXT"),STAGE_NEXT_RING)
    var status:=Label.new()
    status.text=_stage_status(s)
    status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    status.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    status.add_theme_font_size_override("font_size",16)
    status.add_theme_color_override("font_color",Color(.6,1,.75) if bool(s.cleared) else (Color(.94,.95,.97) if bool(s.unlocked) else (STAGE_NEXT_RING if bool(s.next) else Color(.62,.65,.72))))
    status.set_meta("stage_status",true)
    text.add_child(status)
    var marks: Array=sim.campaign.follow_stages().get(st,[]) if bool(s.unlocked) else []
    for kind in ["mastery","mission","prestige"]:
        if not kind in marks:continue
        var icon:=TextureRect.new()
        icon.texture=_follow_kind_icon(kind)
        icon.custom_minimum_size=Vector2(28,28)
        icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
        icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
        line.add_child(icon)
    card.set_meta("follow_marks",marks)
    if can_travel:
        var chevron:=Label.new()
        chevron.text="›"
        chevron.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
        chevron.add_theme_font_size_override("font_size",30)
        chevron.add_theme_color_override("font_color",Color(1,.86,.5))
        line.add_child(chevron)
    if not bool(s.unlocked):card.modulate=Color(1,1,1,.8)
    # The tap target covers the whole card (at least 56 px tall). Locked maps and the current map stay disabled.
    var tap:=Button.new()
    tap.flat=true
    tap.focus_mode=Control.FOCUS_NONE
    tap.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    var clear:=StyleBoxEmpty.new()
    for style in ["normal","disabled","focus"]:tap.add_theme_stylebox_override(style,clear)
    var glow:=StyleBoxFlat.new()
    glow.bg_color=Color(1,1,1,.08);glow.set_corner_radius_all(10)
    for style in ["hover","pressed","hover_pressed"]:tap.add_theme_stylebox_override(style,glow)
    tap.disabled=not can_travel
    tap.tooltip_text=tr("TELEPORT_STAGE_HERE") if here else ("" if can_travel else tr("STAGE_LOCKED"))
    if can_travel:
        tap.set_meta("guide","travel_stage_%d" % st)
        tap.pressed.connect(func()->void:_select_travel_stage(st))
    else:tap.set_meta("guide","stage_row_%d" % st)
    card.add_child(tap)
    return card

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
    var map=camp_picker.new()
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
    teleport_target=[];teleport_stage=0
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

## Change 64: a camp's Teleport opens a large visual map (camp_picker.gd in select mode) instead of a
## list of camp names. A row of stage buttons switches between every reached map (the displayed one is
## highlighted; the player's own map is labelled). Tapping an owned camp only selects it; Confirm
## Teleport performs the move through _travel_to (campaign.camp_action re-checks combat, death, locks,
## stage and ownership at that moment). The camp the player stands in is marked and never a target.
## Travel never changes the chosen respawn camp (Change 61). Back returns to the camp without moving.
func _teleport_panel() -> void:
    _set_title(tr("TELEPORT_TITLE"))
    var here:=_camp_at_player()
    var unlocked:=int(sim.state.unlocked_stage)
    if teleport_stage<1 or teleport_stage>unlocked:
        teleport_stage=int(teleport_target[0]) if teleport_target.size()==2 else int(sim.state.stage)
    teleport_stage=clampi(teleport_stage,1,unlocked)
    var shown:=teleport_stage
    var valid: bool=teleport_target.size()==2 and not (int(teleport_target[0])==int(sim.state.stage) and int(teleport_target[1])==here)
    if unlocked>1:
        var stages:=HFlowContainer.new()
        stages.add_theme_constant_override("h_separation",8)
        stages.add_theme_constant_override("v_separation",8)
        rows.add_child(stages)
        for st in range(1,unlocked+1):
            # Change 74: with the followed objectives' icons, like World's Travel list.
            var button:=_map_button(st,null,Callable())
            if st==shown:button.theme_type_variation=&"Primary"
            elif st==int(sim.state.stage):button.add_theme_color_override("font_color",camp_picker.HERE_RING)
            button.tooltip_text=tr("TELEPORT_STAGE_HERE") if st==int(sim.state.stage) else ""
            button.set_meta("guide","teleport_stage_%d" % st)
            stages.add_child(button)
            button.pressed.connect(func()->void:
                teleport_stage=st
                AudioService.play("ui_click")
                _refresh_panel(true))
    var map=camp_picker.new()
    map.sim=sim;map.stage_id=shown;map.select_mode=true
    map.here=here if shown==int(sim.state.stage) else -1
    map.selected=int(teleport_target[1]) if teleport_target.size()==2 and int(teleport_target[0])==shown else -1
    # Square like the maps; _layout_sheet fits it to the sheet (teleport_map_height keeps the last fit).
    map.custom_minimum_size=Vector2(0,maxf(teleport_map_height,300.0))
    map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    map.set_meta("teleport_map",true)
    # A Guided arrow on it targets a camp marker (screen_target), like the World map's enemy markers.
    map.set_meta("guide_map",true)
    map.chosen.connect(func(camp: int)->void:
        teleport_target=[shown,camp]
        notice.text=""
        AudioService.play("ui_click")
        _refresh_panel(true))
    map.refused.connect(func(reason: String)->void:_say(tr(reason)))
    rows.add_child(map)
    # One status block of fixed height (destination or how to choose, then why travel is blocked), so a
    # selection or a combat change never resizes the open panel.
    var lines: Array=[]
    var choices:=0
    for st in range(1,unlocked+1):
        for camp in sim.state.camps.get(str(st),[0]):
            if not (st==int(sim.state.stage) and int(camp)==here):choices+=1
    if valid:lines.append(tr("TELEPORT_SELECTED") % [sim.catalog.stages[int(teleport_target[0])-1].name,int(teleport_target[1])+1])
    elif choices==0:lines.append(tr("TELEPORT_NONE"))
    else:
        var on_map:=0
        for camp in sim.state.camps.get(str(shown),[0]):
            if not (shown==int(sim.state.stage) and int(camp)==here):on_map+=1
        lines.append(tr("TELEPORT_MAP_HELP") if on_map>0 else tr("TELEPORT_STAGE_NONE"))
    var reason:=_teleport_reason()
    if reason!="":lines.append(tr(reason))
    var status:=_text("
".join(lines),18,Color(1,.86,.5) if valid else Color(.8,.84,.9))
    status.custom_minimum_size.y=78
    status.set_meta("guide_row","teleport_status")
    var block:=sim.campaign.travel_reason(int(teleport_target[0]),int(teleport_target[1])) if valid else "TELEPORT_PICK"
    _pinned(tr("TELEPORT_BACK"),func()->void:teleport_target=[];teleport_stage=0;_open("camp"),true,"",false,"teleport_back",false)
    var go:=_pinned(tr("TELEPORT_CONFIRM") if valid else tr("TELEPORT_PICK"),func()->void:
        if teleport_target.size()==2:_travel_to(int(teleport_target[0]),int(teleport_target[1])),block=="",block,true,"teleport_go")
    go.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    go.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING

## Change 74: one map as a button: its name, then the icons of the followed objectives that can progress on it
## (campaign.follow_stages: Map Mastery, the mission, the Prestige opportunity), so a player following
## something sees where to go. The icons are the dock's Missions and Prestige icons and the Mastery category art.
func _map_button(st: int,parent: Node,callback: Callable) -> Button:
    var button:=Button.new()
    button.text=sim.catalog.stages[st-1].name
    button.focus_mode=Control.FOCUS_NONE
    button.alignment=HORIZONTAL_ALIGNMENT_LEFT
    button.add_theme_font_size_override("font_size",18)
    var marks: Array=sim.campaign.follow_stages().get(st,[])
    var icons:=HBoxContainer.new()
    icons.mouse_filter=Control.MOUSE_FILTER_IGNORE
    icons.add_theme_constant_override("separation",2)
    icons.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
    icons.grow_horizontal=Control.GROW_DIRECTION_BEGIN
    icons.offset_right=-8
    for kind in ["mastery","mission","prestige"]:
        if not kind in marks:continue
        var icon:=TextureRect.new()
        icon.texture=_follow_kind_icon(kind)
        icon.custom_minimum_size=Vector2(28,28)
        icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
        icon.tooltip_text=tr({"mastery":"PANEL_MASTERY","mission":"PANEL_MISSIONS","prestige":"PANEL_PRESTIGE"}[kind])
        icons.add_child(icon)
    button.add_child(icons)
    var text_width: float=button.get_theme_default_font().get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
    button.custom_minimum_size=Vector2(ceilf(text_width+28+30*marks.size()),60)
    button.set_meta("follow_marks",marks)
    if parent!=null:parent.add_child(button)
    if callback.is_valid():button.pressed.connect(callback)
    return button

func _follow_kind_icon(kind: String) -> Texture2D:
    match kind:
        "mission":return dock.get_node("Navigation/Missions").icon
        "prestige":return dock.get_node("Navigation/Prestige").icon
    var category: String=str(sim.campaign.mastery.followed().get("category","explore"))
    if not MASTERY_ART.has(category):category="explore"
    return _art(MASTERY_ART[category])

## Change 64: the Teleport map takes the sheet's free height, up to a square of the sheet's width (the
## stages are square). Returns the rows' content height with the fitted map. Converges in one pass: the
## other rows do not depend on the map's height.
func _fit_teleport_map(room: float,content: float) -> float:
    for node in rows.get_children():
        if not node.has_meta("teleport_map") or node.is_queued_for_deletion():continue
        var other: float=content-float(node.custom_minimum_size.y)
        var want:=floorf(clampf(room-other,300.0,maxf(300.0,rows.size.x)))
        if absf(want-node.custom_minimum_size.y)>=1.0:node.custom_minimum_size.y=want
        teleport_map_height=want
        return other+want
    return content

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
            _inline_button(tr("CAMP_TELEPORT"),func()->void:teleport_target=[];teleport_stage=0;_open("teleport"),lock=="",lock,line,false).set_meta("guide","camp_teleport")
        else:
            var reason: String=sim.campaign.travel_reason(st,i)
            if i==_camp_at_player():reason="TELEPORT_HERE"
            _inline_button(tr("CAMP_TRAVEL"),func()->void:_travel_to(st,i),reason=="",reason,line,false).set_meta("guide","camp_travel_%d" % i)

## Change 71: the one Follow / Unfollow control of Map Mastery, Missions and Prestige: the normal game button
## at one compact size (never a card-wide bar), red Follow when not followed and green Unfollow when followed
## (the ON/OFF toggle theme, Change 69), the same in every panel and language. A wider translation grows the
## button, never wraps it. Eligibility, the saved choice and the action lock stay with each system.
const FOLLOW_BUTTON_SIZE:=Vector2(132,56)
func _follow_button(parent: Node,following: bool,callback: Callable,guide_key: String) -> Button:
    var button:=_inline_button(tr("UNFOLLOW" if following else "FOLLOW"),callback,true,"",parent,false)
    button.custom_minimum_size=FOLLOW_BUTTON_SIZE
    button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
    button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
    button.add_theme_font_size_override("font_size",18)
    button.autowrap_mode=TextServer.AUTOWRAP_OFF
    _toggle_style(button,following,button.disabled)
    button.set_meta("guide",guide_key)
    button.set_meta("follow_button",true)
    return button

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
    # Change 81: the radius this camp reveals now (the global upgrade applies to every owned camp).
    if sim.state.spawns.has(selected_camp):
        _text(tr("CAMP_REVEAL_RADIUS") % [fmt_count(sim.campaign.camp_reveal_radius()),fmt_value(sim.player_upgrade_value("camp_radius")*100)],17,Color(.75,.8,.87))

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
        [tr("STAT_CRIT_DAMAGE"),fmt_value(s.crit_damage*100)+"% (×"+fmt(s.crit_damage)+")"],
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
        [tr("STATS_STORED_SHARE"),tr("STATS_STORED_SHARE_VALUE") % [fmt_value(float(sim.catalog.progression.stored_weapon_factor)*100),fmt_value(float(sim.catalog.progression.stored_outfit_factor)*100)],"stored_share"]]
    if sim.campaign.bonus("equipped")>0:boosts.append([tr("STATS_EQUIPPED_BONUS"),"+"+fmt(sim.campaign.bonus("equipped")*100)+"%"])
    var mastery: Dictionary=sim.campaign.mastery.rewards()
    if not mastery.is_empty():boosts.append([tr("STATS_MASTERY"),mastery_reward_text(mastery)])
    for id in sim.supply_ids():
        if sim.buff_time(id)>0:boosts.append([sim.catalog.display_name(id),tr("STATS_SUPPLY_VALUE") % [_supply_amount(id,sim.buff_power(id)),ceili(sim.buff_time(id))]])
    _stat_section(tr("STATS_SECTION_BOOSTS"),boosts)
    # Change 61: what the stored share means, always here (the Guided gear lesson points at it). The
    # HP and Damage breakdowns below list the stored gear's actual contribution (sim.stat_breakdown).
    _text(tr("STATS_STORED_EXPLAIN") % [fmt_value(float(sim.catalog.progression.stored_weapon_factor)*100),fmt_value(float(sim.catalog.progression.stored_outfit_factor)*100)],16,Color(.8,.84,.9))
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
    _text(tr("STAT_CAPS_NOTE_NO_CRIT"),16,Color(.7,.75,.82))

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
        if entry.size()>2:name_label.set_meta("guide_row",str(entry[2]))
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
    # Change 65: Help & Tutorials, the 14-card library (choose a topic or read all), in every mode.
    _section(tr("SECTION_HELP_TUTORIALS"))
    _action(tr("HELP"),func()->void:
        help_page="home"
        _open("help"),true,"").set_meta("guide","help")
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
    # Change 69: a mute is a binary setting like any other: green when the mute is ON, red when OFF.
    _toggle_style(_action(tr("MUTE_GAMEPLAY_STATUS") % tr("ON" if SettingsState.mute_gameplay else "OFF"),func()->void:SettingsState.set_mute_gameplay(not SettingsState.mute_gameplay),true,"",mutes),SettingsState.mute_gameplay).set_meta("setting","mute_gameplay")
    _toggle_style(_action(tr("MUTE_SPECIAL_STATUS") % tr("ON" if SettingsState.mute_special else "OFF"),func()->void:SettingsState.set_mute_special(not SettingsState.mute_special),true,"",mutes),SettingsState.mute_special).set_meta("setting","mute_special")
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

## Change 65: Settings → Help & Tutorials. One library of tutorial cards (help_cards.gd), the same cards,
## texts and animations the Basic opening shows. The landing offers Read All Tutorials (all cards in order,
## or Continue where you left off) and Choose a Topic (categories, then their cards with Viewed / New).
## A card opens in help_viewer.gd. Reading changes no gameplay, discovery, menu reveal or Guided lesson,
## in any mode; a card about a system not reached yet explains it without unlocking it.
const HelpCards=preload("res://scripts/game/help_cards.gd")
var help_viewer
## "home", "topics" or a category id (help_cards.CATEGORIES).
var help_page:="home"
func _help_panel() -> void:
    var t: Dictionary=sim.state.tutorial
    var all: Array=HelpCards.ids()
    if help_page=="home":
        _set_title(tr("SECTION_HELP_TUTORIALS"))
        _text(tr("HELP_LANDING_INTRO"),17,Color(.8,.84,.9))
        _text(tr("HELP_PROGRESS") % [HelpCards.viewed_count(t),all.size()],18,Color(1,.86,.5))
        var last: String=str(HelpCards.progress(t).last)
        if last!="" and all.find(last)>0:
            _action(tr("HELP_CONTINUE") % tr(HelpCards.title_key(last)),func()->void:help_viewer.open_help("help_all",all.find(last)),true,"").set_meta("guide","help_continue")
        _action(tr("HELP_READ_ALL") % all.size(),func()->void:help_viewer.open_help("help_all",0),true,"").set_meta("guide","help_read_all")
        _action(tr("HELP_CHOOSE_TOPIC"),func()->void:help_page="topics",true,"").set_meta("guide","help_topics")
        _pinned(tr("HELP_BACK"),func()->void:_open("settings"),true,"",false,"help_back",false)
        return
    if help_page=="topics":
        _set_title(tr("HELP_CHOOSE_TOPIC"))
        for category in HelpCards.CATEGORIES:
            var ids: Array=HelpCards.in_category(category)
            _action(tr("HELP_TOPIC_ROW") % [tr(HelpCards.category_key(category)),HelpCards.viewed_count(t,ids),ids.size()],func()->void:help_page=category,true,"").set_meta("guide","help_cat_"+category)
        _pinned(tr("HELP_BACK_HOME"),func()->void:help_page="home",true,"",false,"help_home",false)
        return
    _set_title(tr(HelpCards.category_key(help_page)))
    for id in HelpCards.in_category(help_page):
        var seen: bool=HelpCards.viewed(t,id)
        var row:=_action(("✓ " if seen else "● ")+tr(HelpCards.title_key(id))+"  ·  "+tr("HELP_VIEWED" if seen else "HELP_NOT_VIEWED"),func()->void:help_viewer.open_help("help_topic",all.find(id)),true,"")
        row.set_meta("guide","help_card_"+id)
    _pinned(tr("HELP_BACK_TO_TOPICS"),func()->void:help_page="topics",true,"",false,"help_topics_back",false)

## The viewer closed: Close in Help also closes the Help panel; the Basic opening returns to the game.
func _help_finished(ctx: String) -> void:
    if ctx!="basic" and sheet.visible and panel=="help":_close()

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
    # Change 71: both rows organise the main gear inventory (the dock grid) and are saved; the list below shows
    # exactly what the dock shows, in the same order. All and Default are the first tab of each row.
    _section(tr("FILTER_ITEMS"))
    _tabs(FILTER_TABS,inventory_filter,func(i: int)->void:_set_inventory_view(i,inventory_sort))
    _section(tr("SORT_ITEMS"))
    _tabs(SORT_TABS,inventory_sort,func(i: int)->void:_set_inventory_view(inventory_filter,i))
    _text(tr("FILTERS_HINT_V71"),16,Color(.7,.75,.82))
    _merge_all_action()
    _update_gear_view()
    var listed: Array=[]
    for i in gear_view:
        var id: String=sim.state.gear[i]
        if id=="" or listed.has(id) or sim.quantity(id)<=0:continue
        listed.append(id)
        _inventory_row(id,-1)
    # Supplies are their own column on the dock; the unfiltered list ends with them.
    if inventory_filter==0:
        for i in range(sim.state.supplies.size()):
            var id: String=sim.state.supplies[i]
            if id=="" or sim.quantity(id)<=0:continue
            _inventory_row(id,i)

func _inventory_row(id: String,supply_slot: int) -> void:
    var b:=_action("%s · ×%s · ^%d" % [sim.catalog.display_name(id),fmt_count(sim.quantity(id)),sim.merge_level(id)],func()->void:selected=id;selected_slot=supply_slot;_open("item"))
    b.icon=icon_cache.get(id);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",36)

## Merge All (Change 12): once unlocked for 500 Gems, it is free to use. It reports one
## aggregate result (one notice, one confirm) and is disabled with "Nothing to merge" when idle.
func _merge_all_action() -> void:
    if sim.level("merge_all")<1:
        _text(tr("MERGE_ALL_LOCKED_HINT"),16,Color(.7,.75,.82))
        return
    var copies:=sim.merge_all_copies()
    var lock:=sim.action_lock_reason()
    var b:=_action(tr("MERGE_ALL_BUTTON") % copies if copies>0 else tr("MERGE_ALL_BUTTON_IDLE"),func()->void:
        var button:=_guide_button("merge_all")
        var rect:=button.get_global_rect() if button!=null else Rect2()
        fx_manual=true;fx_merges.clear()
        var result: Dictionary=sim.merge_all()
        fx_manual=false
        if int(result.copies)>0:
            # Change 67: one aggregate flash on the button and a short glint on the merged slots.
            AudioService.play("item_merge")
            _say(tr("MERGE_ALL_DONE") % [int(result.copies),int(result.items)])
            if button!=null:merge_fx.play_button(rect,Color(.55,1,.6))
            for i in range(mini(fx_merges.size(),MERGE_ALL_GLINTS)):pending_glints.append([fx_merges[i][0],false,i*.06])
        fx_merges.clear()
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
## Change 64: the welcome-back receipt always lists Coins, Gems, Weapons, Outfits and Supplies (Change 79: and Skills) (0 when
## nothing was earned), each item category totalled by catalog kind from the pending record itself, and
## marks a category Locked only while its offline unlock (OFFLINE_ITEM_UNLOCKS) is not owned. While any
## is locked a persistent line explains the unlocks (future time away only) with Go to Upgrades. That
## button keeps the established order: it claims this receipt first, as its line says, then opens
## Upgrades → Offline. The individual items follow the totals, as before.
func _offline_panel() -> void:
    var pending: Dictionary=sim.state.offline_pending
    if pending.is_empty():
        _text(tr("OFFLINE_NOTHING"),18,Color(.75,.8,.87))
        return
    _set_title(tr("OFFLINE_WELCOME"),Color(1,.86,.5))
    _text(tr("OFFLINE_AWAY") % [fmt_duration(float(pending.seconds)),fmt(float(pending.rewarded_hours))],18,Color(.8,.84,.9))
    _offline_categories(pending,true)
    for id in pending.items:
        if sim.catalog.items.has(id):_loot_row(id,-1,int(pending.items[id]))
    if not offline_locked_kinds().is_empty():
        _text(tr("OFFLINE_LOCKED_EXPLAIN_V79"),17,Color(1,.86,.5)).set_meta("guide_row","offline_locked_explain")
        _game_action(tr("OFFLINE_GO_UPGRADES"),func()->void:
            if sim.campaign.claim_offline():
                player_tab=4;_open("upgrades")).set_meta("guide","offline_upgrades_jump")
    _pinned(tr("OFFLINE_CLAIM"),func()->void:
        if sim.campaign.claim_offline():
            _close()
            _toast(tr("OFFLINE_CLAIMED")),true,"",true,"claim_offline")

## Item kinds whose offline unlock is not owned yet (weapon / outfit / consumable / skill), from upgrade levels.
## Change 79: skills have their own unlock; the O1 hint (OFFLINE_ITEM_UNLOCKS) keeps its three gear kinds.
const OFFLINE_KIND_UNLOCKS:={"offline_weapon":"weapon","offline_outfit":"outfit","offline_consumable":"consumable","offline_skill":"skill"}
func offline_locked_kinds() -> Array:
    var out: Array=[]
    for id in OFFLINE_KIND_UNLOCKS:
        if sim.level(id)==0:out.append(OFFLINE_KIND_UNLOCKS[id])
    return out

## Per-category totals of an offline record (pending or claimed receipt): currencies and item copies by
## catalog kind. Unknown ids (a removed item) are not counted, as the claim never grants them.
func offline_totals(record: Dictionary) -> Dictionary:
    var totals:={"coins":float(record.get("coins",0.0)),"gems":float(record.get("gems",0.0)),"weapon":0,"outfit":0,"consumable":0,"skill":0}
    var items: Dictionary=record.get("items",{})
    for id in items:
        if not sim.catalog.items.has(id):continue
        var kind: String=str(sim.catalog.items[id].kind)
        if totals.has(kind) and kind not in ["coins","gems"]:totals[kind]=int(totals[kind])+int(items[id])
    return totals

const OFFLINE_CATEGORY_ROWS:=[["coins","OFFLINE_CAT_COINS"],["gems","OFFLINE_CAT_GEMS"],["weapon","WEAPONS"],["outfit","OUTFITS"],["consumable","CONSUMABLES"],["skill","SKILLS"]]
func _offline_categories(record: Dictionary,show_locks: bool) -> void:
    var totals:=offline_totals(record)
    var locked:=offline_locked_kinds() if show_locks else []
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    card.set_meta("guide_row","offline_categories")
    rows.add_child(card)
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",4)
    card.add_child(box)
    for pair in OFFLINE_CATEGORY_ROWS:
        var kind: String=pair[0]
        var line:=HBoxContainer.new()
        line.add_theme_constant_override("separation",10)
        line.set_meta("offline_category",kind)
        box.add_child(line)
        _card_icon(line,_offline_category_icon(kind),Color.WHITE if kind not in locked else Color(.55,.55,.55),30)
        var name_label:=Label.new()
        name_label.text=tr(pair[1])
        name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        name_label.add_theme_font_size_override("font_size",20)
        line.add_child(name_label)
        var value:=Label.new()
        value.text=fmt_currency(totals[kind]) if kind in ["coins","gems"] else fmt_count(totals[kind])
        value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
        value.add_theme_font_size_override("font_size",22)
        value.add_theme_color_override("font_color",Color(1,.88,.55) if float(totals[kind])>0 else Color(.8,.84,.9))
        line.add_child(value)
        if show_locks:
            # Same width on every row, so the numbers line up whether or not a category is locked.
            var state:=Label.new()
            state.text=tr("OFFLINE_CAT_LOCKED") if kind in locked else ""
            state.custom_minimum_size.x=96
            state.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
            state.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
            state.add_theme_font_size_override("font_size",17)
            state.add_theme_color_override("font_color",Color(1,.72,.45))
            line.add_child(state)

func _offline_category_icon(kind: String) -> Texture2D:
    match kind:
        "coins":return COIN
        "gems":return GEM
        "consumable":return icon_cache.get("potion",_art(171))
    for id in sim.catalog.items:
        if str(sim.catalog.items[id].kind)==kind and icon_cache.has(id):return icon_cache[id]
    return _art(171)

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
    var lines: Array=[[tr("STATS_COMPLETION"),"%d%%" % sim.campaign.completion.percent()],[tr("COMPLETION_MAP_MASTERY"),"%d%%" % sim.campaign.mastery.game_percent()]]
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
    _completion_card()
    _text(tr("MASTERY_INTRO_V83"),17,Color(.8,.84,.9))
    var total:=PanelContainer.new()
    total.theme_type_variation=&"Card"
    rows.add_child(total)
    var box:=VBoxContainer.new()
    box.add_theme_constant_override("separation",4)
    total.add_child(box)
    _card_line(box,tr("MASTERY_ALL_MAPS") % m.game_percent(),22,Color(1,.86,.5))
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

## Change 83: Game Completion with its four equal parts (completion.gd): overall percent and bar, then each part's
## achieved / total, percent and bar. Main adventure (the Green Alien) and outfits are separate goals, said below.
func _completion_card() -> void:
    var c: Dictionary=sim.campaign.completion.summary()
    var card:=PanelContainer.new();card.theme_type_variation=&"Card";rows.add_child(card)
    var box:=VBoxContainer.new();box.add_theme_constant_override("separation",4);card.add_child(box)
    _card_line(box,("✓ " if c.complete else "")+tr("COMPLETION_TITLE") % int(c.percent),24,Color(.5,1,.65) if c.complete else Color(1,.86,.5))
    _mastery_bar(box,float(c.fraction))
    _card_line(box,tr("COMPLETION_RULE"),16,Color(.8,.84,.9))
    for pair in [["mastery","COMPLETION_PART_MASTERY"],["cards","COMPLETION_PART_CARDS"],["player","COMPLETION_PART_PLAYER"],["enemy","COMPLETION_PART_ENEMY"]]:
        var e: Dictionary=c[pair[0]]
        _card_line(box,("✓ " if e.complete else "")+tr(pair[1]) % [int(e.done),int(e.total),int(e.percent)],18,Color(.5,1,.65) if e.complete else Color.WHITE)
        _mastery_bar(box,float(e.fraction))
    _card_line(box,tr("COMPLETION_SEPARATE") % [sim.campaign.owned_floor_outfits().size(),sim.campaign.floor_outfits().size()],16,Color(.75,.8,.87))

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
        var followed: bool=str(sim.state.get("follow_mastery",""))=="%d:%s" % [st,category]
        _follow_button(text,followed,func()->void:sim.campaign.mastery.toggle_follow(st,category),"follow_mastery" if not followed else "unfollow_mastery")
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
## Change 74: the enemy or item a Mastery requirement names (unknown ones stay unnamed), else "".
func _mastery_target(part: Array) -> String:
    match str(part[0]):
        "kills","stats","drops":
            var g:=int(part[1])
            return str(sim.catalog.groups[g].name) if _type_known(g) else tr("MASTERY_UNKNOWN_ENEMY")
        "item","merge":return sim.catalog.display_name(part[1]) if _item_known(part[1]) else tr("MASTERY_UNKNOWN_ITEM")
        "camp":return tr("CAMP_NAME") % (int(part[1])+1)
    return ""

## Change 79: the HUD pill's instruction for one unfinished Map Mastery requirement, action and target in one
## localized phrase; the pill's progress label carries the count, so no number repeats here.
func _mastery_action(st: int,part: Array) -> String:
    var kind: String=part[0]
    match kind:
        "explored":return tr("TRACK_EXPLORE_MAP") % str(sim.catalog.stages[st-1].name)
        "camp":return tr("TRACK_UNLOCK_CAMP") % (int(part[1])+1)
        "kills":return tr("FOLLOW_GOAL_KILL_TARGET") % _mastery_target(part)
        "stats","drops":return tr("MASTERY_NEED_"+kind.to_upper()) % _mastery_target(part)
        "item":return tr("TRACK_FIND_ITEM") % _mastery_target(part)
        "merge":return tr("TRACK_MERGE_ITEM") % [_mastery_target(part),int(part[3])]
        "evolve","weapon_merge":return _mastery_missing(st,part)
    return ""

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
        "evolve","weapon_merge":
            var names: Array=[]
            for id in sim.campaign.mastery.content(st).weapons:names.append(sim.catalog.display_name(id) if _item_known(id) else "?")
            if kind=="weapon_merge":return tr("MASTERY_NEED_WEAPON_MERGE") % [", ".join(names),int(part[3])]
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
    # Change 83: the Boss Keys quest leads the main objectives on every map (from the discovery to the victory).
    if sim.state.final_discovered:_final_quest_card()
    # Change 61: the one-time 30-defeat mission, from the Snowman's discovery until it is claimed. It is
    # listed above (not inside) the three main objectives, so their display limit never hides it.
    if sim.campaign.hunt_open():
        var hunt_rewards: Array=sim.campaign.hunt_rewards()
        var hunt_ready: bool=sim.campaign.hunt_ready()
        var hunt_value:=tr("MISSION_STATE_READY") if hunt_ready else "%s: %d/%d" % [tr("HUNT_MISSION_HINT"),int(sim.campaign.hunt_progress()),sim.campaign.HUNT_GOAL]
        _task_card(_art(1),tr("HUNT_MISSION_TITLE"),hunt_value,sim.campaign.hunt_progress(),float(sim.campaign.HUNT_GOAL),hunt_rewards[0],hunt_rewards[1],func()->void:_confirmed(sim.campaign.claim_hunt()),hunt_ready,"MISSION_NOT_READY",false,["hunt",0])
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
        _toggle_style(toggle,bool(sim.state.mission_auto)).set_meta("guide","mission_auto_toggle")

## Change 83: the Boss Keys quest (Missions → Main Objectives, opened by the Boss Keys chip): the count X/13 and every
## key the Green Alien needs, grouped by stage in catalog order: a check for a key held, "Defeat <boss> — <stage>"
## for one missing. At 13/13 it says to return to the Green Alien; after the victory it shows as completed. Only
## after the discovery (the caller checks), so nothing is spoiled; names wrap at portrait widths.
func _final_quest_card() -> void:
    _section(tr("FINAL_KEYS_SECTION"))
    var g:=_final_group()
    var objective: String=sim.campaign.final_objective()
    var card:=PanelContainer.new();card.theme_type_variation=&"Card";rows.add_child(card)
    var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6);card.add_child(box)
    var head:=HBoxContainer.new();head.add_theme_constant_override("separation",10);box.add_child(head)
    _card_icon(head,_final_art(),Color.WHITE,52)
    var lines:=VBoxContainer.new();lines.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(lines)
    var stage_name: String=str(sim.catalog.stages[int(sim.catalog.groups[g].stage)-1].name) if g>=0 else ""
    var boss_name: String=str(sim.catalog.groups[g].name) if g>=0 else ""
    _card_line(lines,tr("FINAL_QUEST_TITLE") % boss_name,20,Color.WHITE)
    var held: int=sim.state.keys.size()
    if objective=="":
        _card_line(lines,"✓ "+tr("FINAL_QUEST_DONE") % boss_name,18,Color(.5,1,.65))
        return
    if objective=="ready":_card_line(lines,tr("FINAL_QUEST_RETURN") % [boss_name,stage_name],18,Color(.55,1,.6))
    else:_card_line(lines,tr("KEY_PROGRESS") % held,18,Color(1,.86,.5))
    _mastery_bar(box,float(held)/float(sim.campaign.FINAL_KEYS))
    _card_line(box,tr("FINAL_INTRO_BODY") % [sim.campaign.FINAL_KEYS,sim.campaign.FINAL_KEYS],16,Color(.8,.84,.9))
    for st in range(1,sim.catalog.stages.size()+1):
        var bosses: Array=[]
        for d in sim.catalog.groups:
            if d.boss and not d.final and int(d.stage)==st:bosses.append(d)
        if bosses.is_empty():continue
        _card_line(box,str(sim.catalog.stages[st-1].name),17,Color(.75,.82,.95))
        for d in bosses:
            var have: bool=sim.state.keys.has(d.id)
            var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);box.add_child(row)
            _card_icon(row,icon_cache.get(d.body),Color.WHITE if have else Color(.55,.55,.6),34)
            var mark:=TextureRect.new();mark.texture=preload("res://assets/ui/Key - Gold.png");mark.custom_minimum_size=Vector2(22,22)
            mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.modulate=Color.WHITE if have else Color(.25,.25,.28,.8)
            row.add_child(mark)
            var label: String=("✓ "+tr("FINAL_KEY_HELD") % d.name) if have else tr("FINAL_KEY_MISSING") % [d.name,str(sim.catalog.stages[st-1].name)]
            _card_line(row,label,17,Color(.5,1,.65) if have else Color(1,.86,.5))

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
        _follow_button(text,following,func()->void:sim.campaign.toggle_follow_mission(follow[0],follow[1]),"follow_hunt" if follow[0]=="hunt" else "follow_mission")
    if ready:
        var button:=_inline_button(tr("CLAIM"),claim,true,reason,line,true)
        button.custom_minimum_size=Vector2(112,64)
        button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
        button.set_meta("guide","claim_hunt" if not follow.is_empty() and follow[0]=="hunt" else "claim")
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

## Change 64: Prestige cards in equal columns that fit the sheet's content width (as many cards of at
## least min_width as fit), so every card, its selection frame and its text stay inside the sheet.
func _card_grid(min_width: float,gap: int) -> GridContainer:
    var grid:=GridContainer.new()
    grid.add_theme_constant_override("h_separation",gap)
    grid.add_theme_constant_override("v_separation",gap)
    grid.columns=maxi(1,int(floor((_rows_width()+gap)/(min_width+gap))))
    rows.add_child(grid)
    return grid

## Width of the panel rows: the sheet's width (set by _layout_sheet from the map area) less its frame,
## margins and the scroll bar. Computed, not read from the rows, so a panel built off-tree gets it too.
func _rows_width() -> float:
    var width: float=$Safe/Layout/Map.size.x-sheet_inset.x*2
    width-=sheet.get_theme_stylebox("panel").get_minimum_size().x
    var margin: MarginContainer=$Sheet/Margin
    width-=margin.get_theme_constant("margin_left")+margin.get_theme_constant("margin_right")
    var scroll: ScrollContainer=$Sheet/Margin/Content/Scroll
    return width-scroll.get_v_scroll_bar().get_combined_minimum_size().x

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
        var grid:=_card_grid(150.0,8)
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
## Change 54: the maps where the requirement is performed are catalog data (opportunity "stages", written by
## tools/change54_catalog.py), which also fixes Trophy II/III appearing under the wrong maps.
func prestige_stages(op: Dictionary) -> Array:
    var out: Array=[]
    for st in op.get("stages",[0]):out.append(int(st))
    return out

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
    header.set_meta("guide","prestige_stage_%d" % st)
    if collapsed:return
    for op in order:
        if prestige_stages(op).has(st):_opportunity_card(op)

func _opportunity_card(op: Dictionary) -> void:
    var o: Dictionary=sim.state.opportunities[op.id]
    var done: bool=sim.state.consumed.has(op.id)
    var ready: bool=o.ready and not done
    var card:=PanelContainer.new()
    card.theme_type_variation=&"Card"
    # Change 61: the Guided Prestige lessons point at a specific opportunity (hunter_o1).
    card.set_meta("guide_row","opportunity_"+str(op.id))
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
    # Change 64: the path's cards wrap onto as many lines as they need. They used to share one row with an
    # ellipsis each, so a path with 4-8 cards showed only fragments ("Caref", "Gear Fo") at 432x960.
    var chips:=HFlowContainer.new()
    chips.add_theme_constant_override("h_separation",14)
    chips.add_theme_constant_override("v_separation",2)
    content.add_child(chips)
    for id in _path_cards(str(op.path)):
        var d: Dictionary=sim.catalog.campaign.cards[id]
        var owned: bool=sim.state.owned_cards.has(id)
        var chip:=Label.new()
        chip.text=("✓ " if owned else "")+d.name+" "+PRESTIGE_CARD_SCRIPT.headline(d)
        chip.add_theme_font_size_override("font_size",17)
        chip.add_theme_color_override("font_color",Color(.55,.58,.62) if owned else Color(Color(str(sim.catalog.campaign.paths.get(op.path,{}).get("color","ffffff"))).lightened(.45)))
        chips.add_child(chip)
    var row:=HBoxContainer.new()
    row.add_theme_constant_override("separation",8)
    # A ready opportunity has nothing left to follow (the action layer refuses it too).
    if sim.campaign.can_follow(op.id) or sim.state.follow==op.id:
        var follow:=_follow_button(row,sim.state.follow==op.id,func()->void:sim.campaign.toggle_follow(op.id),"follow" if sim.state.follow!=op.id else "unfollow")
        follow.set_meta("guide_alt","follow_"+str(op.id) if sim.state.follow!=op.id else "")
    if op.path in ["offering","collection"] and not ready:
        var submit:=_inline_button(tr("SUBMIT_CONTRACT"),func()->void:sim.campaign.submit(op.id),true,"",row,true)
        submit.custom_minimum_size=Vector2(200,64)
        # Change 58 (localization): the label wraps in the space beside Follow; unwrapped, German "Geforderte
        # Gegenstände oder Währung abgeben" widened the Prestige sheet past a 432-wide screen.
        submit.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        submit.size_flags_horizontal=Control.SIZE_EXPAND_FILL
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
    var boss_done: bool=sim.campaign.first_boss_defeated()
    _card_line(box,("✓ " if boss_done else "✗ ")+tr("PRESTIGE_REQ_BOSS_DEFEAT"),18,Color(.5,1,.65) if boss_done else Color(1,.72,.45))
    var any_ready: bool=not sim.campaign.ready_ids().is_empty()
    var ready_text:=tr("PRESTIGE_REQ_READY")
    if any_ready and ready.is_empty():ready_text+="\n"+tr("NO_CARD_AVAILABLE")
    _card_line(box,("✓ " if not ready.is_empty() else "✗ ")+ready_text,18,Color(.5,1,.65) if not ready.is_empty() else Color(1,.72,.45))

## Short reason shown on the locked reset button itself.
func _prestige_block_short(reason: String) -> String:
    match reason:
        "PRESTIGE_LOCKED_BOSS_DEFEAT":return "PRESTIGE_NEEDS_BOSS_DEFEAT"
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
    var keep: Array=[tr("KEEP_LINE_CARDS") % sim.state.owned_cards.size(),tr("KEEP_LINE_COINS") % fmt_currency(sim.state.coins),tr("KEEP_LINE_GEMS") % fmt_currency(sim.state.gems),tr("KEEP_LINE_ALL_UPGRADES"),tr("KEEP_LINE_MERGES"),tr("KEEP_LINE_MAP"),tr("KEEP_LINE_PROGRESS"),tr("KEEP_LINE_MAIN_OBJECTIVES"),tr("KEEP_LINE_SETTINGS"),tr("KEEP_LINE_LEVEL") % int(sim.state.player_level),tr("KEEP_LINE_SUPPLY_MASTERY")]
    var reset: Array=[tr("RESET_LINE_CARRIED_ITEMS"),tr("RESET_LINE_MAPS"),tr("RESET_LINE_RUN_PROGRESS")]
    $PrestigeConfirm.open(tr("PRESTIGE_CONFIRM_SUBTITLE") % ready.size(),rows_,keep,reset)

## The batch: one card per ready opportunity, chosen in order. Tap a card to select it, then keep it.
func _prestige_choice(batch: Dictionary) -> void:
    var index: int=batch.choices.size()
    var op: Dictionary=_opportunity(batch.ids[index])
    _set_title(tr("PRESTIGE_CHOOSE_TITLE") % [index+1,batch.ids.size()],Color(1,.86,.5))
    _text(op.name+"  ·  "+op.description,18,Color(.8,.84,.9))
    var offered: Array=sim.campaign.offered_cards()
    if not offered.has(selected_card):selected_card=""
    # Change 54: an expanded path can offer up to eight cards, so the row wraps on a phone.
    # Change 64: in equal columns (a flow stretched the last card of a row across the whole sheet).
    var row:=_card_grid(200.0,10)
    for id in offered:
        var node:=_card_node(id,"selected" if id==selected_card else "offered")
        node.set_meta("guide","card")
        node.pressed.connect(func()->void:selected_card=id;AudioService.play("ui_click");_refresh_panel(true))
        row.add_child(node)
    var earned: Array=[]
    for id in batch.choices:earned.append(sim.catalog.campaign.cards[id].name)
    if not earned.is_empty():_text(tr("PRESTIGE_EARNED_SO_FAR") % ", ".join(earned),17,Color(.6,1,.75))
    _section(tr("PRESTIGE_KEEP_TITLE"))
    _text(tr("PRESTIGE_KEEP_ALL")+"\n"+tr("KEEP_LINE_SUPPLY_MASTERY"),17,Color(.6,1,.75))
    _section(tr("PRESTIGE_RESET_TITLE"))
    _text(tr("PRESTIGE_RESET_RUN"),17,Color(1,.72,.45))
    if batch.choices.is_empty():
        _pinned(tr("CANCEL"),func()->void:sim.campaign.cancel_prestige();selected_card="",true,"",false,"",false)
    var card_name: String=sim.catalog.campaign.cards[selected_card].name if selected_card!="" else ""
    var last: bool=index==batch.ids.size()-1
    var keep:=_pinned(tr("PRESTIGE_KEEP_CARD") % card_name if selected_card!="" else tr("PRESTIGE_PICK_CARD"),func()->void:
        var chosen:=selected_card
        _confirm(tr("PRESTIGE_CARD_CONFIRM_FINAL" if last else "PRESTIGE_CARD_CONFIRM") % sim.catalog.campaign.cards[chosen].name,func()->void:
            selected_card=""
            _confirmed(sim.prestige(chosen))),selected_card!="","PRESTIGE_PICK_CARD",true,"keep_card",false)
    # Change 58 (localization): the only instruction on this screen, and "Keep <card name>", may take two lines
    # inside the bar's 76-unit height ("Tippe auf eine Karte, um sie zu wählen" was cut to "um si…").
    keep.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

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

# ---------------------------------------------------------------- travel iris and boss title (Change 67)
## Arriving on another map: the map opens from the hero like an iris (dark violet, 0.7 s, real time),
## so the new map is clearly a different place. The Teleport has already happened; this only reveals it.
## A boss defeat: "Boss defeated!" and the boss's name punch in over the map, then fade (2.4 s). Both
## sit over the map only (under the HUD chips, the panel and the guide) and never take input.
var iris: ColorRect
var iris_age:=INF
const IRIS_TIME:=.85
var boss_title: VBoxContainer
const BOSS_TITLE_HEIGHT:=120.0
var boss_title_tween: Tween

func _build_moment_overlays() -> void:
    var map: Control=$Safe/Layout/Map
    iris=ColorRect.new()
    iris.name="TravelIris"
    iris.mouse_filter=Control.MOUSE_FILTER_IGNORE
    iris.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shader:=Shader.new()
    shader.code="shader_type canvas_item;\nuniform vec2 center = vec2(0.5);\nuniform float radius = 0.0;\nuniform vec2 size = vec2(1.0);\nuniform vec4 tint : source_color = vec4(0.08, 0.03, 0.14, 1.0);\nuniform vec4 rim : source_color = vec4(0.75, 0.5, 1.0, 1.0);\nvoid fragment() {\n\tfloat d = distance(UV * size, center * size);\n\tfloat edge = smoothstep(radius - 3.0, radius + 3.0, d);\n\tfloat glow = exp(-abs(d - radius) / 6.0) * step(0.5, radius);\n\tCOLOR = vec4(mix(rim.rgb, tint.rgb, edge * (1.0 - glow * 0.8)), max(edge * tint.a, glow * 0.9));\n}\n"
    var mat:=ShaderMaterial.new()
    mat.shader=shader
    iris.material=mat
    iris.visible=false
    map.add_child(iris)
    map.move_child(iris,map.get_node("ViewportContainer").get_index()+1)
    boss_title=VBoxContainer.new()
    boss_title.name="BossTitle"
    boss_title.mouse_filter=Control.MOUSE_FILTER_IGNORE
    boss_title.alignment=BoxContainer.ALIGNMENT_BEGIN
    for i in range(2):
        var l:=Label.new()
        l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        # One line each: a wrapping label reports a page-tall minimum until laid out, which pushed the
        # title off the map. A long translated name is trimmed with an ellipsis instead.
        l.autowrap_mode=TextServer.AUTOWRAP_OFF
        l.clip_text=true
        l.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
        l.add_theme_font_size_override("font_size",42 if i==0 else 26)
        l.add_theme_color_override("font_color",Color(1,.84,.3) if i==0 else Color(1,.95,.85))
        l.add_theme_color_override("font_outline_color",Color(.32,.12,.02) if i==0 else Color(.05,.04,.06))
        l.add_theme_constant_override("outline_size",12 if i==0 else 8)
        l.mouse_filter=Control.MOUSE_FILTER_IGNORE
        boss_title.add_child(l)
    boss_title.visible=false
    # Above every map chip (the minimap, trackers), still under the panel, banners and guide.
    map.add_child(boss_title)

func _open_iris() -> void:
    iris_age=0.0
    iris.visible=true
    _update_iris(0.0)

func _update_iris(dt: float) -> void:
    if iris_age==INF:return
    iris_age+=dt/maxf(Engine.time_scale,.01)
    var u:=clampf(iris_age/IRIS_TIME,0,1)
    var size: Vector2=iris.size
    var screen: Vector2=world.player_screen_position()
    var container: Control=$Safe/Layout/Map/ViewportContainer
    var local: Vector2=iris.get_global_transform().affine_inverse()*(container.get_global_transform()*screen)
    var mat: ShaderMaterial=iris.material
    mat.set_shader_parameter("size",size)
    mat.set_shader_parameter("center",local/size)
    # Eased open from a closed point to past the farthest corner.
    var far: float=maxf(maxf(local.length(),(size-local).length()),maxf(Vector2(local.x,size.y-local.y).length(),Vector2(size.x-local.x,local.y).length()))
    # Opens slowly from the hero first (the new map is a reveal), then sweeps out to the corners.
    mat.set_shader_parameter("radius",far*u*u*(3.0-2.0*u)*1.05)
    if u>=1:
        iris_age=INF
        iris.visible=false

func _boss_title(id: String,group: int,_at: Vector2) -> void:
    if not (world.views.has(id) and world.views[id].disclosed and world.views[id].visible):return
    var map: Control=$Safe/Layout/Map
    boss_title.get_child(0).text=tr("BOSS_DEFEATED_TITLE")
    boss_title.get_child(1).text=sim.catalog.groups[group].name
    boss_title.size=Vector2(map.size.x-48,BOSS_TITLE_HEIGHT)
    # Under the hero (centred on the map) and below the toast band: above it are the stat popups and banners.
    boss_title.position=Vector2(24,minf(map.size.y*.71,map.size.y-BOSS_TITLE_HEIGHT-8))
    boss_title.pivot_offset=boss_title.size*.5
    boss_title.scale=Vector2.ONE*1.8
    boss_title.modulate=Color(1,1,1,0)
    boss_title.visible=true
    if boss_title_tween!=null and boss_title_tween.is_valid():boss_title_tween.kill()
    var t:=create_tween().set_ignore_time_scale(true)
    boss_title_tween=t
    t.set_parallel(true)
    t.tween_property(boss_title,"scale",Vector2.ONE,.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    t.tween_property(boss_title,"modulate:a",1.0,.12)
    t.chain().tween_interval(1.6)
    t.chain().tween_property(boss_title,"modulate:a",0.0,.5)
    t.chain().tween_callback(func()->void:boss_title.visible=false)

# ---------------------------------------------------------------- merge and evolution feedback (Change 67)
## A manual merge from the item card. The simulation performs it (same rules as before); the burst
## plays only when it reports a merge, from the levels it reports.
func _manual_merge(id: String,all:=false) -> bool:
    var frame:=_item_icon_frame(id)
    var rect:=frame.get_global_rect() if frame!=null else Rect2()
    fx_manual=true;fx_merges.clear()
    var ok:=sim.merge(id,all)
    fx_manual=false
    var done: Array=fx_merges.duplicate()
    fx_merges.clear()
    if not ok or done.is_empty():return false
    AudioService.play("item_merge")
    if frame!=null:merge_fx.play_item(rect,icon_cache.get(id),_tier_color(id),int(done[-1][1]),int(done[-1][2]))
    return true

## A manual weapon evolution. Everything the panel shows is read before the transaction; the panel
## opens only when the simulation reports the evolution, and never performs it.
func _manual_evolve(id: String) -> bool:
    if not sim.catalog.items.has(id):return false
    var target: String=str(sim.catalog.items[id].next)
    if target=="" or not sim.catalog.items.has(target):return false
    var snapshot:={"source":id,"target":target,
        "source_name":sim.catalog.display_name(id),"target_name":sim.catalog.display_name(target),
        "source_tier":int(sim.catalog.items[id].tier),"target_tier":int(sim.catalog.items[target].tier),
        "source_merge":int(sim.record(id).merge),
        "source_color":_tier_color(id),"target_color":_tier_color(target),
        "source_icon":icon_cache.get(id),"target_icon":icon_cache.get(target)}
    fx_manual=true;fx_evolutions.clear()
    var ok:=sim.evolve(id)
    fx_manual=false
    var done: Array=fx_evolutions.duplicate()
    fx_evolutions.clear()
    if not ok or done.is_empty():return false
    _say(tr("EVOLVED"))
    evolution_show.present(snapshot)
    return true

## Bulk evolve keeps each real transaction and its mission/mastery credit; UI condenses effects.
func _manual_evolve_all(id: String) -> bool:
    if not sim.catalog.items.has(id):return false
    var target: String=str(sim.catalog.items[id].next)
    fx_manual=true;fx_evolutions.clear()
    var amount:=sim.evolve_all(id)
    fx_manual=false;fx_evolutions.clear()
    if amount<=0:return false
    AudioService.play("item_merge")
    _say(tr("EVOLVE_ALL_DONE") % [amount,sim.catalog.display_name(target)])
    pending_glints.append([target,true,0.0])
    return true

func _on_merged(id: String,before: int,after: int) -> void:
    # Change 81: an Obsidian weapon merge that crosses a milestone names it (manual, Merge All or Auto-Merge).
    for step in sim.weapon_milestone_track(id):
        if before<int(step.merge) and after>=int(step.merge):
            _say(tr("WEAPON_MILESTONE_REACHED") % [sim.catalog.display_name(id),int(step.merge),", ".join(_weapon_milestone_parts(sim.weapon_milestones(id,int(step.merge))))],true)
    if fx_manual:
        fx_merges.append([id,before,after])
        return
    # Auto-Merge: a silent glint on the slot, once per item per frame.
    if not pending_glints.any(func(g):return g[0]==id):pending_glints.append([id,false,0.0])

func _on_evolved(source: String,target: String) -> void:
    if fx_manual:
        fx_evolutions.append([source,target])
        return
    # Auto Evolution: a named notice, a quiet chime and a gold glint on the new weapon; never a panel.
    AudioService.play("evolve_auto")
    _say(tr("AUTO_EVOLVED_NOTICE") % [sim.catalog.display_name(source),sim.catalog.display_name(target)])
    pending_glints=pending_glints.filter(func(g):return g[0]!=target)
    pending_glints.append([target,true,0.0])

## Plays the queued dock glints once the slots show this frame's state. A slot that is hidden by a
## filter, scrolled out of view or covered by a full-screen panel gets none; nothing is kept for later.
func _flush_glints() -> void:
    if pending_glints.is_empty():return
    var queued:=pending_glints
    pending_glints=[]
    if evolution_show.visible or (help_viewer!=null and help_viewer.visible):return
    var grid: Control=dock.get_node("Inventory/GearColumn/GearScroll/Gear")
    var view: Rect2=dock.get_node("Inventory/GearColumn/GearScroll").get_global_rect()
    for g in queued:
        var slot: Control=gear_slot_node(sim.state.gear.find(str(g[0])))
        if slot==null or not slot.is_visible_in_tree():continue
        var rect:=slot.get_global_rect()
        if not view.intersects(rect):continue
        merge_fx.glint(rect,_tier_color(str(g[0])),bool(g[1]),float(g[2]))

## The selected item's icon frame on the open item card (the last card showing this item's icon).
func _item_icon_frame(id: String) -> Control:
    if not sheet.visible or panel!="item":return null
    var found: Control=null
    for frame in rows.find_children("*","Panel",true,false):
        if frame.get_child_count()>0 and frame.get_child(0) is TextureRect and frame.get_child(0).texture==icon_cache.get(id) and frame.is_visible_in_tree():found=frame
    return found

## A panel button by its guide key (rows first, then the pinned actions).
func _guide_button(key: String) -> Control:
    for node in rows.find_children("*","Button",true,false)+actions.find_children("*","Button",true,false):
        if node.get_meta("guide","")==key:return node
    return null

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

## Recent finds, top-left, each on a dark backing so they stay readable on snow.
## Change 72: a recent find leaves the feed LOOT_SECONDS after it happened (simulation clock), fading out.
func _fade_loot() -> void:
    var now: float=float(sim.state.clock)
    for row in $Safe/Layout/Map/History.get_children():
        var alpha: float=clampf((LOOT_SECONDS-(now-float(row.get_meta("time",now))))/LOOT_FADE,0.0,1.0)
        if row.visible!=(alpha>0):row.visible=alpha>0
        if not is_equal_approx(row.modulate.a,alpha):row.modulate.a=alpha

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
        row.size_flags_horizontal=Control.SIZE_SHRINK_END
        row.alignment=HORIZONTAL_ALIGNMENT_LEFT
        row.set_meta("time",float(entry.get("time",0.0)))
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
