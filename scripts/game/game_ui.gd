extends Control
@export var sheet_inset:=Vector2(18,8)
const SLOT=preload("res://scenes/game/slot.tscn")
const ROW=preload("res://scenes/game/action_row.tscn")
@onready var sim: LootSimulation=$Simulation
@onready var world=$Safe/Layout/Map/ViewportContainer/Viewport/World
@onready var top=$Safe/Layout/Top/Content
@onready var dock=$Safe/Layout/Dock/Content
@onready var sheet=$Sheet
@onready var rows=$Sheet/Margin/Content/Scroll/Rows
@onready var notice=$Sheet/Margin/Content/Notice
@onready var stick=$Safe/Layout/Map/Joystick
var combat_group: int=-1
var history_signature: String=""
var gem_pickup_time:=0.0
var gem_pickup_amount:=0.0
var panel: String=""
var player_tab:=0
var enemy_tab:=0
var enemy_variant:=2
var boss_panel_delay:=-1.0
var selected_camp:=0
var selected: String=""
var selected_slot: int=-1
var group: int=0
var elapsed:=0.0
var last_revision: int=-1
var toast_time:=0.0
var confirm_action: Callable
var icon_cache: Dictionary={}
var stick_input:=Vector2.ZERO
var slot_nodes: Array=[]
var action_buttons: Array=[]
var panel_generation:=0
var panel_context:=""
var previous_pause:=false

func _ready() -> void:
    world.setup(sim)
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
        if sim.state.spawns.has(index):
            sim.select_spawn(index)
            _event("CAMP_SELECTED_NOTICE")
        else:
            _open("camp"))
    $Safe/Layout/Map/GestureSurface.world=world
    $Safe/Layout/Map/Zoom/Slider.value_changed.connect(SettingsState.set_camera_zoom)
    SettingsState.settings_changed.connect(_sync_zoom)
    _sync_zoom()
    for id in sim.catalog.items:
        icon_cache[id]=sim.catalog.icon(id)
    stick.direction_changed.connect(func(value: Vector2)->void:
        stick_input=value
        if value.length()>.1:
            $Safe/Layout/Map/GestureSurface.cancel_gesture()
            world.follow_player())
    top.get_node("Bar/Pause").pressed.connect(_pause)
    $Sheet/Margin/Content/Header/Close.pressed.connect(_close)
    sim.gem_pickup.connect(_show_gem_pickup)
    sim.combat_group_changed.connect(func(g: int)->void:combat_group=g)
    dock.get_node("Navigation/Travel").pressed.connect(func()->void:_open("travel"))
    dock.get_node("Navigation/Stats").pressed.connect(func()->void:_open("stats"))
    dock.get_node("Navigation/Settings").pressed.connect(func()->void:_open("settings"))
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
    sim.event.connect(_event)
    SaveService.save_failed.connect(func(_reason: String)->void:_event("SAVE_ERROR"))
    get_viewport().size_changed.connect(_safe_area)
    $Safe/Layout/Map.resized.connect(_layout_sheet)
    call_deferred("_layout_sheet")
    _safe_area()
    dock.get_node("Inventory").resized.connect(_layout_inventory)
    AudioService.register_sfx("button",preload("res://assets/Audio/button.wav"))
    AudioService.register_sfx("prestige",preload("res://assets/Audio/prestige.wav"))
    _refresh_slots()
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
    _update_supply_cooldowns()
    if boss_panel_delay>=0 and not get_tree().paused:
        boss_panel_delay-=dt
        if boss_panel_delay<0 and sim.state.victory:
            _open("prestige")
    var keys:=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
    sim.movement=Vector2.ZERO if get_tree().paused or sim.suspended or $Confirm.visible else (stick_input if stick_input.length()>.1 else keys.limit_length())
    if stick_input.length()>.1 or keys.length()>.1:
        $Safe/Layout/Map/GestureSurface.cancel_gesture()
        world.follow_player()
    toast_time=maxf(0,toast_time-dt)
    $Toast.visible=toast_time>0
    elapsed+=dt
    if elapsed<.15:
        return
    elapsed=0.0
    var p: Dictionary=sim.state.player
    var s:=sim.stats()
    top.get_node("Bar/Coins").text=fmt(sim.state.coins)
    top.get_node("Bar/Gems").text=fmt(sim.state.gems)
    $Safe/Layout/Map/Zoom/Value.text="%.2f×" % SettingsState.camera_zoom

    top.get_node("Bar/Pause").text=tr("RESUME" if get_tree().paused else "PAUSE")
    top.get_node("Meters/HP").value=100*p.hp/s.hp
    top.get_node("Status").text=(tr("RESPAWNING") % snappedf(p.respawn,.1)) if p.hp<=0 else tr("PLAYER_STATUS") % [fmt(p.hp),fmt(s.hp),tr("GROUP_%d" % sim.nearest_group())]
    if sim.state.boost_time>0:
        top.get_node("Status").text+="  "+tr("BOOST_ACTIVE") % int(ceil(sim.state.boost_time))
    top.get_node("Meters/HP/Text").text=tr("HUD_HP") % [fmt(p.hp),fmt(s.hp)]
    if p.hp<=0:
        top.get_node("Meters/HP/Text").text=tr("HUD_REVIVE") % p.respawn
    top.get_node("Meters/XP").value=100.0 if sim.state.player_level==1000 else 100.0*sim.state.xp/sim.xp_required()
    top.get_node("Meters/XP/Text").text=tr("HUD_LEVEL") % [sim.state.player_level,tr("VALUE_MAX") if sim.state.player_level==1000 else tr("XP_PROGRESS") % [fmt(sim.state.xp),fmt(sim.xp_required())]]
    top.get_node("Meters/XP").tooltip_text=tr("XP_PROGRESS") % [fmt(sim.state.xp),fmt(sim.xp_required())]
    _refresh_combat_achievement()
    _help()
    _refresh_loot_notifications()
    if last_revision!=sim.revision or previous_pause!=get_tree().paused:
        previous_pause=get_tree().paused
        last_revision=sim.revision
        _refresh_slots()
        if sheet.visible:
            _refresh_panel()

func fmt(value: float) -> String:
    return NumberFormat.number(value,2)

func fmt_count(value: float) -> String:
    return NumberFormat.number(value,2) if absf(value)>=1000 else NumberFormat.count(value)

func _help() -> void:
    var step:=int(sim.state.help)
    if step==0 and sim.state.player.y<1320:
        step=1
    if step==1 and not sim.state.pickups.is_empty():
        step=2
    if step==2 and not sim.state.items.is_empty():
        step=3
    if step==3 and (sim.state.weapon!="" or sim.state.outfit!=""):
        step=4
    if step==4:
        for item in sim.state.items.values():
            if int(item.merge)>0:
                step=5
    if step==5:
        for g in range(4):
            if sim.level("collect",g)>0:step=6
    if step!=int(sim.state.help):
        sim.state.help=step
        SaveService.mark_dirty()
    var key: String="HELP_%d" % mini(step,7)
    if sim.state.victory:
        key="HELP_VICTORY"
    if get_tree().paused:
        key="HELP_PAUSED"
    $Safe/Layout/Map/Hint.text=tr(key)
    $Safe/Layout/Map/Hint.visible=step<6 or get_tree().paused

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
            node.get_node("Icon").texture=icon_cache.get(id)
            node.get_node("Count").text=tr("EMPTY_SLOT") if id=="" else "%s · ^%d" % [fmt_count(sim.quantity(id)),sim.record(id).merge]
            node.get_node("Badge").text=tr("EQUIPPED") if id!="" and sim.equipped(id) else (tr("AUTO") if type==1 and sim.state.auto_slots.has(i) else "")
            var style: StyleBoxTexture=theme.get_stylebox("normal","Slot").duplicate()
            style.modulate_color=_tier_color(id)
            node.add_theme_stylebox_override("normal",style)
            var hover: StyleBoxTexture=style.duplicate()
            hover.modulate_color=style.modulate_color.lightened(.15)
            node.add_theme_stylebox_override("hover",hover)
            node.tooltip_text=sim.catalog.display_name(id) if id!="" else tr("EMPTY_SLOT")
    _layout_inventory()
    dock.get_node("Inventory/GearColumn/Heading").text=tr("HUD_GEAR") % [sim.state.gear.size()-sim.state.gear.count(""),sim.state.gear.size()]
    dock.get_node("Inventory/SupplyColumn/SupplyHeading").text=tr("HUD_SUPPLIES") % [sim.state.supplies.size()-sim.state.supplies.count(""),sim.state.supplies.size()]

func _layout_inventory() -> void:
    var inventory: Control=dock.get_node("Inventory")
    var gear_width: float=inventory.get_node("GearColumn/GearScroll").size.x
    var supply_width: float=inventory.get_node("SupplyColumn/SupplyScroll").size.x
    var side:=floorf(minf((gear_width-36.0)/3.0,supply_width-20.0))
    side=clampf(side,88,156)
    for path in ["GearColumn/GearScroll/Gear","SupplyColumn/SupplyScroll/Supplies"]:
        for slot in inventory.get_node(path).get_children():
            slot.custom_minimum_size=Vector2(side,side)
    var height:=clampf(size.y*.21,220,320)
    for path in ["GearColumn/GearScroll","SupplyColumn/SupplyScroll"]:
        inventory.get_node(path).custom_minimum_size.y=height

func _update_supply_cooldowns() -> void:
    var slots=dock.get_node("Inventory/SupplyColumn/SupplyScroll/Supplies")
    for i in range(mini(slots.get_child_count(),sim.state.supplies.size())):
        var node=slots.get_child(i)
        var cooling: bool=sim.catalog.art_id(sim.state.supplies[i])=="potion" and sim.state.use_cd>0
        node.get_node("Cooldown").text=tr("SECONDS_VALUE") % fmt(sim.state.use_cd) if cooling else ""
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

func _open(which: String) -> void:
    $Safe/Layout/Map/GestureSurface.cancel_gesture()
    panel=which
    notice.text=""
    sheet.show()
    stick.release()
    $Sheet/Margin/Content/Scroll.scroll_vertical=0
    _refresh_panel()
    AudioService.play_sfx("button")

func _close() -> void:
    sheet.hide()
    panel=""
    notice.text=""

func _pause() -> void:
    $Safe/Layout/Map/GestureSurface.cancel_gesture()
    get_tree().paused=not get_tree().paused
    stick.release()
    SaveService.save_now()

func _event(key: String) -> void:
    notice.text=tr(key)
    $Toast.text=tr(key)
    toast_time=4.0
    if key=="BOSS_DEFEATED":
        boss_panel_delay=1.0
        AudioService.play_sfx("prestige")
    if key=="PLAYER_LEVEL_UP":
        $Toast.text=tr("LEVEL_UP_NOTICE") % sim.state.player_level
    if key=="PRESTIGED":
        _close()
        AudioService.play_sfx("prestige")

func _text(value: String) -> void:
    var label:=Label.new()
    label.text=value
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size",20)
    rows.add_child(label)

func _action(text: String,callback: Callable,enabled: bool=true,reason: String="ACTION_UNAVAILABLE") -> Button:
    var button: Button=ROW.instantiate()
    button.text=text
    button.disabled=not enabled
    button.tooltip_text=tr(reason) if not enabled else ""
    if not enabled:button.text+="\n"+tr(reason)
    rows.add_child(button)
    button.pressed.connect(func()->void:
        callback.call()
        AudioService.play_sfx("button")
        if sheet.visible:
            _refresh_panel())
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

func _layout_confirm() -> void:
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var available:=size-Vector2(insets.x+insets.z,insets.y+insets.w)-Vector2(40,40)
    var box: Control=$Confirm/Panel
    box.size=Vector2(minf(560,available.x),minf(360,available.y))
    box.position=Vector2(insets.x+20,insets.y+20)+(available-box.size)*.5

func _unhandled_key_input(event: InputEvent) -> void:
    if $Confirm.visible and event.is_action_pressed("ui_cancel"):
        _cancel_confirm()
        get_viewport().set_input_as_handled()

func _refresh_panel() -> void:
    panel_generation+=1
    var generation:=panel_generation
    var scroll: int=$Sheet/Margin/Content/Scroll.scroll_vertical
    var live_rows: VBoxContainer=rows
    var draft:=VBoxContainer.new()
    rows=draft
    action_buttons.clear()
    $Sheet/Margin/Content/Header/Title.text=tr("PANEL_"+panel.to_upper())
    match panel:
        "item":_item_panel()
        "upgrades":_upgrades_panel()
        "enemy":_enemy_panel()
        "camp":_camp_panel()
        "travel":_travel_panel()
        "stats":_stats_panel()
        "settings":_settings_panel()
        "history":
            for entry in sim.state.history:
                var message:=_history_text(entry)
                if not message.is_empty():
                    _text(message)
        "prestige":_prestige_panel()
    var context:="%s:%s:%d:%d:%d:%d" % [panel,selected,group,player_tab,enemy_tab,enemy_variant]
    var mapping: Dictionary={}
    var structural:=_sync_panel_children(live_rows,draft,mapping,context!=panel_context)
    for info in action_buttons:
        info.node=mapping.get(info.node,info.node)
    rows=live_rows
    draft.free()
    panel_context=context
    if get_tree().paused:
        $Sheet/Margin/Content/Header/Title.text+=" · "+tr("PAUSE")
    if structural:
        _restore_panel_scroll(scroll,generation)

func _item_panel() -> void:
    if selected=="" or sim.quantity(selected)==0:
        _text(tr("EMPTY_SLOT_HELP"))
        if selected_slot>=0:
            _game_action(tr("AUTO_SLOT_TOGGLE"),func()->void:sim.bind_auto(selected_slot))
            _game_action(tr("BUY_POTION"),func()->void:sim.purchase_consumable("potion"))
            _game_action(tr("BUY_BOOST"),func()->void:sim.purchase_consumable("coin_boost"))
        return
    var id:=selected
    var def: Dictionary=sim.catalog.items[id]
    var r:=sim.record(id)
    $Sheet/Margin/Content/Header/Title.text=tr("ITEM_DETAILS")
    var card:=HBoxContainer.new()
    card.add_theme_constant_override("separation",20)
    rows.add_child(card)
    var tile:=VBoxContainer.new()
    tile.custom_minimum_size.x=116
    card.add_child(tile)
    var frame:=PanelContainer.new()
    var style: StyleBoxTexture=theme.get_stylebox("normal","Slot").duplicate()
    style.modulate_color=_tier_color(id)
    frame.add_theme_stylebox_override("panel",style)
    tile.add_child(frame)
    var icon:=TextureRect.new()
    icon.texture=icon_cache[id]
    icon.custom_minimum_size=Vector2(92,92)
    icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    frame.add_child(icon)
    var merge_label:=Label.new()
    merge_label.text=tr("ITEM_TIER_MERGE") % [int(def.tier),r.merge]
    merge_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    merge_label.add_theme_font_size_override("font_size",16)
    tile.add_child(merge_label)
    var details:=VBoxContainer.new()
    details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation",8)
    card.add_child(details)
    _card_line(details,sim.catalog.display_name(id),24,_tier_color(id).lightened(.5))
    for key in sim.normal(id):
        _card_line(details,_stat_text(key,sim.normal(id)[key],true),24,Color.WHITE)
    for key in r.extras:
        _card_line(details,"+ "+_stat_text(key,r.extras[key],true),20,Color(.73,.78,.84))
    _text(tr("ITEM_OWNED") % fmt_count(r.qty))
    if sim.equipped(id):
        _text(tr("ITEM_EQUIPPED_CONTRIBUTION"))
    elif def.kind=="weapon":
        _text(tr("ITEM_STORED_CONTRIBUTION"))
    var actions:=HBoxContainer.new()
    actions.add_theme_constant_override("separation",10)
    rows.add_child(actions)
    var equip_button: Button
    if def.kind!="consumable":
        equip_button=_game_action(tr("UNEQUIP" if sim.equipped(id) else "EQUIP"),func()->void:sim.equip(id))
    else:
        equip_button=_game_action(tr("USE"),func()->void:sim.use_item(id))
    if r.merge<100:
        var gains: Array[String]=[]
        for stat in def.normal:
            var gain: float=sim.merge_gain(id,stat)
            if gain>0:
                gains.append(_stat_text(stat,gain,true))
        _card_line(details,tr("NEXT_MERGE_GAIN")+" " + ", ".join(gains),18,Color(.5,1,.65))
    var merge_button:=_game_action(tr("ITEM_MERGE_ACTION"),func()->void:sim.merge(id),r.qty>1 and r.merge<100,"NEED_DUPLICATES" if r.qty<2 else "MERGE_MAX")
    var sell_button:=_game_action(tr("ITEM_SELL_ACTION") % def.sell,func()->void:sim.sell(id),r.qty>(1 if sim.equipped(id) else 0),"EQUIPPED_PROTECTED")
    for button in [equip_button,merge_button,sell_button]:
        button.reparent(actions)
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.custom_minimum_size.x=0
        button.add_theme_font_size_override("font_size",20)
    if def.next!="" and r.merge>=100:
        _text(tr("EVOLUTION_EXPLAIN"))
        _game_action(tr("EVOLVE") % sim.catalog.display_name(def.next),func()->void:sim.evolve(id),r.qty>=101,"EVOLUTION_NEEDS")
    if def.next=="":_text(tr("MAX_ITEM_TIER"))
    var amount:=mini(int(r.qty)-1,100-int(r.merge))
    _game_action(tr("MERGE_ALL") % maxi(0,amount),func()->void:sim.merge(id,true),amount>0,"NEED_DUPLICATES")
    if def.kind=="consumable":
        _game_action(tr("AUTO_SLOT_STATUS") % tr("ON" if sim.state.auto_slots.has(selected_slot) else "OFF"),func()->void:sim.bind_auto(selected_slot))
    if def.kind!="consumable":
        _game_action(tr("REROLL") % def.reroll,func()->void:_confirm(tr("REROLL_CONFIRM") % def.reroll,func()->void:sim.reroll(id)))
    var spare:=int(r.qty)-(1 if sim.equipped(id) else 0)
    _game_action(tr("SELL_ALL") % [spare,spare*int(def.sell)],func()->void:_confirm(tr("SELL_CONFIRM") % [spare,sim.catalog.display_name(id),spare*int(def.sell)],func()->void:sim.sell(id,true)),spare>0,"EQUIPPED_PROTECTED")
    _game_action(tr("AUTO_SELL_STATUS") % tr("ON" if sim.state.sell_list.has(id) else "OFF"),func()->void:sim.toggle_sell(id))

func _tabs(keys: Array,active: int,callback: Callable) -> void:
    var bar:=HBoxContainer.new()
    bar.name="Tabs"
    rows.add_child(bar)
    for i in range(keys.size()):
        var button:=Button.new()
        button.text=tr(keys[i])
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.custom_minimum_size.y=48
        button.add_theme_font_size_override("font_size",18)
        button.disabled=i==active
        bar.add_child(button)
        button.pressed.connect(func()->void:
            callback.call(i)
            $Sheet/Margin/Content/Scroll.scroll_vertical=0
            _refresh_panel())

func _portrait(body: String) -> void:
    var texture: Texture2D
    if body in sim.catalog.items:
        texture=icon_cache[body]
    else:
        var atlas:=AtlasTexture.new()
        atlas.atlas=load("res://assets/PixelPlains/Characters 24x24/"+("Autumn 4 v2.png" if body=="death" else ("Gato 4 v2.png" if body=="cat" else "Basic character v2.png")))
        atlas.region=Rect2(0,0,24,24)
        texture=atlas
    var portrait:=TextureRect.new()
    portrait.texture=texture
    portrait.custom_minimum_size=Vector2(0,72)
    portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    rows.add_child(portrait)

func _upgrades_panel() -> void:
    _portrait(sim.catalog.art_id(sim.state.outfit))
    _tabs(["TAB_PLAYER","TAB_INVENTORY","TAB_SUPPLIES","TAB_UPGRADES"],player_tab,func(i: int)->void:player_tab=i)
    var sections: Array=[
        ["respawn"],
        ["gear_slots","supply_slots","merge_speed","sell","sell_capacity"],
        ["merge_supplies","auto_use","use_speed"],["gem_chance","gem_amount"]]
    if player_tab==3:_text(tr("GLOBAL_GEMS_HELP"))
    for id in sections[player_tab]:
        _upgrade_row(id)
    if player_tab==1:
        _text(tr("SELL_LIST_EXPLAIN") % [sim.state.sell_list.size(),(1+sim.level("sell_capacity")) if sim.level("sell")>0 else 0])
        for id in sim.state.items.keys():
            _game_action(tr("SELL_RULE") % [sim.catalog.display_name(id),tr("ON" if sim.state.sell_list.has(id) else "OFF")],func()->void:sim.toggle_sell(id))
    if player_tab==2:
        _game_action(tr("BUY_POTION"),func()->void:sim.purchase_consumable("potion"))
        _game_action(tr("BUY_BOOST"),func()->void:sim.purchase_consumable("coin_boost"))

func _enemy_panel() -> void:
    if group==3:enemy_variant=2
    var cat:=group==4
    var body: String=sim.enemy_definition(group,enemy_variant).body
    $Sheet/Margin/Content/Header/Title.text=tr("ENEMY_CAT" if cat else "GROUP_%d" % group)
    _portrait(body)
    if not cat and sim.enemy_definition(group,enemy_variant).weapon!="":
        _loot_row(sim.enemy_definition(group,enemy_variant).weapon,-1)
    if cat:
        _text(tr("CAT_DETAILS"))
        return
    if group<3:
        _tabs(["VARIANT_OUTFIT","VARIANT_WEAPON","VARIANT_BOTH"],enemy_variant,func(i: int)->void:enemy_variant=i)
    _tabs(["TAB_OVERVIEW","TAB_UPGRADES","TAB_ACHIEVEMENTS"],enemy_tab,func(i: int)->void:enemy_tab=i)
    if enemy_tab==2:
        _group_achievements_panel()
        return
    if sim.level("focus",group)>0:
        _text(tr("FARM_SELECTED_VARIANT") % tr(["VARIANT_OUTFIT","VARIANT_WEAPON","VARIANT_BOTH"][enemy_variant]))
        _game_action(tr("FOCUS_GROUP") % [tr("GROUP_%d" % group),tr("ON" if int(sim.state.focus)==group and int(sim.state.focus_variant)==enemy_variant else "OFF")],func()->void:sim.focus(group,enemy_variant))
    if enemy_tab==1:
        _text(tr("GROUP_UPGRADES_RESET"))
        var upgrades: Array=["focus","merge_gear","collect","collect_range","collect_batch","collect_speed","loot","supply_drop","group_xp","coin_amount"]
        upgrades.append_array(["spawn_amount","spawn_cooldown"] if group<3 else ["boss_gem_chance","boss_gem_amount"])
        for id in upgrades:
            _upgrade_row(id,group)
        return
    var def: Dictionary=sim.enemy_definition(group,enemy_variant)
    _text(tr("GROUP_XP_VALUE") % fmt(sim.group_xp(group,enemy_variant)))
    _text(tr("ENEMY_STATS_HEADING"))
    if sim.level("reveal_stats",group)==0:
        _text(tr("UNKNOWN_STATS"))
        _upgrade_row("reveal_stats",group)
    else:
        _text(tr("ENEMY_STATS_VALUES") % [fmt(def.hp),fmt(def.damage),fmt(def.interval),fmt(def.defense)])
    _text(tr("ENEMY_DROPS_HEADING"))
    if sim.level("reveal_drops",group)==0:
        _text(tr("UNKNOWN_DROPS"))
        _upgrade_row("reveal_drops",group)
    else:
        _text(tr("DROP_COINS") % fmt(sim.coin_reward(group)))
        _text(tr("DROP_GEMS") % [fmt(sim.gem_chance(group)*100),fmt(sim.gem_amount(0,group))])
        for id in def.loot:
            _loot_row(id,sim.gear_chance(group)*100.0/def.loot.size())
        _loot_row("potion",sim.consumable_chance(group,"potion")*100)
        if group>0:
            _loot_row("coin_boost",sim.consumable_chance(group,"coin_boost")*100)
        _text(tr("DROP_ROLL_HELP"))

func _loot_row(id: String,chance: float) -> void:
    var row:=HBoxContainer.new()
    var icon:=TextureRect.new()
    icon.texture=icon_cache[id]
    icon.custom_minimum_size=Vector2(34,34)
    icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    row.add_child(icon)
    var label:=Label.new()
    label.text=sim.catalog.display_name(id) if chance<0 else tr("DROP_ITEM") % [sim.catalog.display_name(id),fmt(chance)]
    label.add_theme_font_size_override("font_size",18)
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    row.add_child(label)
    rows.add_child(row)

func _camp_panel() -> void:
    $Sheet/Margin/Content/Header/Title.text=tr("CAMP_NAME") % (selected_camp+1)
    _text(tr("CAMP_HELP"))
    if sim.state.spawns.has(selected_camp):
        _game_action(tr("SPAWN_SELECT") % (selected_camp+1),func()->void:sim.select_spawn(selected_camp))
    else:
        _action(tr("SPAWN_BUY") % [selected_camp+1,sim.catalog.world.spawn_prices[selected_camp]],func()->void:
            if sim.select_spawn(selected_camp):
                sim.select_spawn(selected_camp)
                _event("CAMP_SELECTED_NOTICE"))

func _upgrade_row(id: String,g: int=-1) -> void:
    if g>=0:
        _group_upgrade_card(id,g)
        return
    _group_upgrade_card(id,g)

func _travel_panel() -> void:
    _text(tr("TRAVEL_HELP"))
    _action(tr("OPEN_PLAYER"),func()->void:_open("upgrades"))
    for i in range(4):
        _action(tr("OPEN_GROUP") % tr("GROUP_%d" % i),func()->void:group=i;enemy_variant=2;enemy_tab=0;_open("enemy"))
    for i in range(3):
        var owned: bool=sim.state.spawns.has(i)
        var text: String=(tr("SPAWN_SELECT") % (i+1)) if owned else tr("SPAWN_BUY") % [i+1,sim.catalog.world.spawn_prices[i]]
        if int(sim.state.spawn)==i:
            text+=" · "+tr("SELECTED")
        _game_action(text,func()->void:sim.select_spawn(i))
    _text(tr("FOCUS_HELP"))
    for i in range(4):
        _text(tr("GROUP_%d" % i))
        for v in ([2] if i==3 else [0,1,2]):
            var active: bool=int(sim.state.focus)==i and int(sim.state.focus_variant)==v
            _game_action(tr("FARM_VARIANT") % [tr(["VARIANT_OUTFIT","VARIANT_WEAPON","VARIANT_BOTH"][v]),tr("ON" if active else "OFF")],func()->void:sim.focus(i,v),sim.level("focus",i)>0,"AUTOMATION_LOCKED")
    if sim.state.victory:
        _action(tr("PRESTIGE_READY"),func()->void:_open("prestige"))

func _stats_panel() -> void:
    _text(tr("PLAYER_LEVEL_CAP") % sim.state.player_level)
    for key in sim.stats():
        _text(_stat_text(key,sim.stats()[key]))
    _text(tr("STAT_SOURCES"))
    for source in sim.stat_sources():
        _text(tr(source))
        for key in sim.stat_sources()[source]:
            _text(_stat_text(key,sim.stat_sources()[source][key],true))
    _text(tr("PERMANENT_MULTIPLIERS") % [fmt(sim.card("hp")),fmt(sim.card("damage"))])
    _text(tr("STAT_CAPS_NOTE"))
    _text(tr("PRESTIGE_COUNT") % sim.state.prestiges)
    for key in sim.state.cards:
        _text(tr("CARD_"+key.to_upper())+" ×%d" % sim.state.cards[key])
    _text(tr("NO_OFFLINE"))

func _stat_text(key: String,value: float,bonus: bool=false) -> String:
    if key in ["crit","lifesteal","speed","coin_bonus"]:
        return "%s  %s%%" % [tr("STAT_"+key.to_upper()),fmt(value*100)]
    if key=="crit_damage":
        return ("%s  %s%%" % [tr("STAT_"+key.to_upper()),fmt(value*100)]) if bonus else ("%s  ×%s" % [tr("STAT_"+key.to_upper()),fmt(value)])
    return "%s  %s%s" % [tr("STAT_"+key.to_upper()),fmt(value)," "+tr("HP_PER_SECOND") if key=="regen" else ""]

func _settings_panel() -> void:
    _action(tr("LOOT_HISTORY"),func()->void:_open("history"))
    _action(tr("SAVE_NOW"),func()->void:if SaveService.save_now():_event("SAVED"))
    _action(tr("SOUND_STATUS") % tr("ON" if SettingsState.sfx_enabled else "OFF"),func()->void:SettingsState.sfx_enabled=not SettingsState.sfx_enabled;SettingsState.settings_changed.emit())
    _action(tr("HARD_RESET"),func()->void:_confirm(tr("RESET_CONFIRM"),func()->void:SaveService.hard_reset();_close()))
    _text(tr("LANGUAGE_NOTE"))
    _action(tr("LANG_AUTOMATIC"),func()->void:LocalizationService.select_language("automatic"))
    for locale in LocalizationService.RELEASE_LANGUAGES:
        _action(tr("LANG_"+locale.to_upper()),func()->void:LocalizationService.select_language(locale),locale=="en_US")
    _text(tr("CREDITS"))

func _prestige_panel() -> void:
    _text(tr("PRESTIGE_EXPLAIN"))
    for id in sim.state.offer:
        _action(tr("CARD_"+str(id).to_upper()),func()->void:_confirm(tr("PRESTIGE_CONFIRM"),func()->void:sim.prestige(id)))

func _history_text(entry: Dictionary) -> String:
    if entry.key=="HISTORY_CURRENCY":
        return tr("HISTORY_CURRENCY") % fmt(entry.amount) if entry.amount>0 else ""
    if entry.key=="HISTORY_SOLD":
        return tr("HISTORY_SOLD") % [fmt_count(entry.amount),sim.catalog.display_name(entry.id)]
    return tr("HISTORY_ITEM") % [fmt_count(entry.amount),sim.catalog.display_name(entry.id)]

func _layout_sheet() -> void:
    var map: Control=$Safe/Layout/Map
    sheet.set_anchors_preset(Control.PRESET_TOP_LEFT)
    sheet.position=map.global_position+sheet_inset
    sheet.size=map.size-sheet_inset*2.0

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

func _show_gem_pickup(amount: float) -> void:
    gem_pickup_amount=(gem_pickup_amount if gem_pickup_time>0 else 0)+amount
    gem_pickup_time=4.0
    $Safe/Layout/Map/GemPickup/Amount.text="+"+fmt(gem_pickup_amount)
    $Safe/Layout/Map/GemPickup.show()

func _refresh_loot_notifications() -> void:
    var signature:=JSON.stringify(sim.state.history)
    if signature==history_signature:
        return
    history_signature=signature
    var container: VBoxContainer=$Safe/Layout/Map/History
    for child in container.get_children():
        container.remove_child(child)
        child.queue_free()
    for entry in sim.state.history:
        if entry.key not in ["HISTORY_ITEM","HISTORY_CURRENCY"] or entry.amount<=0:
            continue
        var row:=Button.new()
        row.custom_minimum_size=Vector2(230,40)
        row.alignment=HORIZONTAL_ALIGNMENT_LEFT
        row.add_theme_font_size_override("font_size",20)
        row.add_theme_constant_override("outline_size",4)
        row.add_theme_color_override("font_outline_color",Color(0,0,0,.9))
        for state_name in ["normal","hover","pressed","focus"]:
            row.add_theme_stylebox_override(state_name,StyleBoxEmpty.new())
        row.icon=preload("res://resources/game/gem.tres") if entry.key=="HISTORY_CURRENCY" else icon_cache.get(entry.id)
        row.expand_icon=true
        row.add_theme_constant_override("icon_max_width",38 if entry.key=="HISTORY_CURRENCY" else 28)
        row.add_theme_constant_override("h_separation",10)
        row.text="+"+(fmt(entry.amount) if entry.key=="HISTORY_CURRENCY" else fmt_count(entry.amount))
        row.tooltip_text=_history_text(entry)
        row.pressed.connect(func()->void:_open("history"))
        container.add_child(row)
        if container.get_child_count()==3:
            break

func _group_achievements_panel() -> void:
    _text(tr("KILL_ACHIEVEMENTS"))
    _text(tr("ACHIEVEMENT_BONUS") % [sim.achievement_damage(group)*100,sim.achievement_gems(group)*100])
    var kills: int=sim.state.group_kills[group]
    for threshold in sim.achievement_thresholds(group):
        var card:=PanelContainer.new()
        rows.add_child(card)
        var content:=VBoxContainer.new()
        content.add_theme_constant_override("separation",8)
        card.add_child(content)
        var line:=HBoxContainer.new()
        content.add_child(line)
        _card_icon(line,icon_cache.get(sim.catalog.groups[group].body))
        var progress:=VBoxContainer.new()
        progress.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        line.add_child(progress)
        _progress_meter(progress,kills,threshold)
        _card_line(progress,"%s / %s" % [fmt_count(mini(kills,threshold)),fmt_count(threshold)],20,Color.WHITE)
        _card_line(content,tr("ACHIEVEMENT_DONE") if kills>=threshold else " ",18,Color(.5,1,.65))
        _card_line(content,tr("ACHIEVEMENT_REWARD_SHORT") % [sim.catalog.progression.achievements.damage_per_milestone*100,sim.catalog.progression.achievements.gems_per_milestone*100],18,Color(.8,.86,.92))
    _text(tr("ACHIEVEMENT_PERMANENT"))

func _refresh_combat_achievement() -> void:
    var target: Dictionary=sim._find_actor(sim.locked_target)
    if not target.is_empty() and int(target.group) in range(4):
        combat_group=int(target.group)
    elif int(sim.state.focus) in range(4):
        combat_group=int(sim.state.focus)
    elif combat_group<0 or sim.movement.length()>.1:
        combat_group=sim.nearest_group()
    # Keep this section available between kills, including one-hit kills.
    var g:=combat_group
    var button: Button=$Safe/Layout/Map/Achievement
    button.show()
    $Safe/Layout/Map/EnemyUpgrades.show()
    $Safe/Layout/Map/EnemySection.text=tr("GROUP_%d" % g)
    var milestones: Array=sim.achievement_thresholds(g)
    var tier:=sim.achievement_level(g)
    var progress:=tr("ACHIEVEMENT_DONE") if tier==milestones.size() else "%s / %s" % [fmt_count(sim.state.group_kills[g]),fmt_count(milestones[tier])]
    button.text=tr("TAB_ACHIEVEMENTS")+"\n"+progress
    button.set_meta("group",g)

func _progress_meter(parent: Node,value: float,maximum: float) -> void:
    var bar:=ProgressBar.new()
    bar.theme_type_variation=&"XP"
    bar.custom_minimum_size=Vector2(0,18)
    bar.max_value=maximum
    bar.value=minf(value,maximum)
    bar.show_percentage=false
    parent.add_child(bar)

func _card_icon(parent: Node,texture: Texture2D) -> void:
    var icon:=TextureRect.new()
    icon.texture=texture
    icon.custom_minimum_size=Vector2(44,44)
    icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    parent.add_child(icon)

func _group_upgrade_card(id: String,g: int) -> void:
    var def: Dictionary=sim.catalog.upgrades[id]
    var current:=sim.level(id,g)
    var maxed:=sim.upgrade_maxed(id,g)
    var card:=PanelContainer.new()
    rows.add_child(card)
    var content:=VBoxContainer.new()
    content.add_theme_constant_override("separation",8)
    card.add_child(content)
    _card_line(content,tr("UP_"+id.to_upper()),20,Color.WHITE)
    var line:=HBoxContainer.new()
    line.add_theme_constant_override("separation",12)
    content.add_child(line)
    var icon: Texture2D=icon_cache.get(sim.catalog.groups[g].body) if g>=0 else icon_cache.get("potion")
    if id in ["coin_amount"]:icon=preload("res://resources/game/coin.tres")
    elif id in ["gem_chance","gem_amount","boss_gem_chance","boss_gem_amount"]:icon=preload("res://resources/game/gem.tres")
    elif id=="supply_drop":icon=icon_cache.get("potion")
    elif id in ["loot","merge_gear"] and g>=0:icon=icon_cache.get(sim.catalog.groups[g].weapon)
    _card_icon(line,icon)
    var progress:=VBoxContainer.new()
    progress.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    line.add_child(progress)
    _progress_meter(progress,current,def.cap)
    _card_line(progress,"%d / %d" % [current,def.cap],18,Color.WHITE)
    var buy:=Button.new()
    buy.custom_minimum_size=Vector2(140,76)
    buy.text=tr("UPGRADE_MAX") if maxed else fmt(sim.upgrade_cost(id,g))
    buy.icon=preload("res://resources/game/coin.tres") if def.currency=="coins" else preload("res://resources/game/gem.tres")
    buy.expand_icon=true
    buy.add_theme_constant_override("icon_max_width",26)
    var reason:=sim.upgrade_block_reason(id,g)
    buy.disabled=not reason.is_empty()
    buy.tooltip_text=tr(reason) if not reason.is_empty() else tr("UP_"+id.to_upper())
    buy.set_meta("upgrade",id)
    buy.pressed.connect(func()->void:sim.buy_upgrade(id,g))
    line.add_child(buy)
    action_buttons.append({"node":buy,"kind":"upgrade","id":id,"group":g})
    _card_line(content,_upgrade_benefit(id,g),20,Color(.65,1,.8))
    var status:=Label.new()
    status.name="BlockReason"
    status.custom_minimum_size.y=30
    status.text=tr(reason) if not reason.is_empty() else " "
    status.tooltip_text=status.text
    status.add_theme_font_size_override("font_size",18)
    content.add_child(status)

func _open_combat_achievements() -> void:
    group=int($Safe/Layout/Map/Achievement.get_meta("group",0))
    enemy_tab=2
    _open("enemy")

func _upgrade_benefit(id: String,g: int) -> String:
    var next:=0 if sim.upgrade_maxed(id,g) else 1
    if int(sim.catalog.upgrades[id].cap)==1:
        return tr("UPGRADE_TRANSITION") % [tr("ON" if sim.level(id,g)>0 else "OFF"),tr("ON")]
    var current:=sim.group_upgrade_value(id,g,enemy_variant) if g>=0 else sim.player_upgrade_value(id)
    var future:=sim.group_upgrade_value(id,g,enemy_variant,next) if g>=0 else sim.player_upgrade_value(id,next)
    var percent:=id in ["loot","supply_drop","gem_chance","boss_gem_chance"]
    var left:=fmt(current*100)+"%" if percent else fmt(current)
    var right:=fmt(future*100)+"%" if percent else fmt(future)
    var value:=tr("UPGRADE_TRANSITION") % [left,right]
    if id in ["respawn","collect_speed","merge_speed","use_speed","spawn_cooldown"]:value=tr("SECONDS_VALUE") % value
    if id=="supply_drop":
        value=tr("POTION_CHANCE_VALUE") % value
        if g>0:
            value+="\n"+tr("TONIC_CHANCE_VALUE") % (tr("UPGRADE_TRANSITION") % [fmt(sim.consumable_chance(g,"coin_boost")*100)+"%",fmt((sim.consumable_chance(g,"coin_boost")+future-current)*100)+"%"])
    return value

func _sync_panel_children(live: Node,draft: Node,mapping: Dictionary,replace_all:=false) -> bool:
    # Build descriptions off-tree; reconcile them into live controls. No existing
    # button is removed on a value change, so an in-progress touch remains valid.
    var changed:=false
    var desired:=draft.get_children()
    for i in range(desired.size()):
        var incoming: Node=desired[i]
        if i>=live.get_child_count() or replace_all or live.get_child(i).get_class()!=incoming.get_class():
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
            for property in incoming.get_property_list():
                var key: String=property.name
                if key in ["text","disabled","tooltip_text","value","max_value","texture","icon","modulate"] or key.begins_with("theme_override"):
                    existing.set(key,incoming.get(key))
            for signal_name in ["pressed"]:
                if incoming.has_signal(signal_name):
                    for connection in existing.get_signal_connection_list(signal_name):
                        existing.disconnect(signal_name,connection.callable)
                    for connection in incoming.get_signal_connection_list(signal_name):
                        existing.connect(signal_name,connection.callable)
            changed=_sync_panel_children(existing,incoming,mapping) or changed
    while live.get_child_count()>desired.size():
        var old:=live.get_child(live.get_child_count()-1)
        live.remove_child(old)
        old.queue_free()
        changed=true
    return changed

func _restore_panel_scroll(offset: int,generation: int) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if generation==panel_generation and is_instance_valid(rows):
        $Sheet/Margin/Content/Scroll.scroll_vertical=offset

func _game_action(text: String,callback: Callable,enabled: bool=true,reason: String="ACTION_UNAVAILABLE") -> Button:
    var lock:=sim.action_lock_reason()
    return _action(text,callback,enabled and lock.is_empty(),lock if not lock.is_empty() else reason)
