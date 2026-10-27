extends Node
var checks:=0
var failures:=0
var game
var sim
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")
func fresh(mode:="none") -> void:
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode=mode
    sim.campaign.onboarding.reveal_all(true)
    game._close();game.banner.queue.clear();game.banner._finish()
func button(key: String) -> Button:
    for root in [game.rows,game.actions]:
        for node in root.find_children("*","Button",true,false):
            if node.get_meta("guide","")==key:return node
    return null
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    fresh()
    await frames()
    # Item exclusion belongs to the inventory identity, survives JSON, and never blocks manual merge.
    var id: String=sim.catalog.groups[0].loot[0]
    sim.add_item(id,4);sim.state.upgrades["merge_gear:0"]=1
    check(sim.can_auto_merge(id),"Automatic merge originally available")
    game.selected=id;game._open("item")
    check(button("item_auto_merge")!=null,"Item detail exposes exclusion")
    if button("item_auto_merge")!=null:button("item_auto_merge").pressed.emit()
    check(sim.auto_merge_excluded(id) and not sim.can_auto_merge(id),"UI disables automatic merge")
    sim.campaign.merge_cycle("0",10,11,0)
    check(sim.quantity(id)==4 and sim.record(id).merge==0,"Excluded stack untouched by automation")
    check(sim.merge(id) and sim.record(id).merge==1,"Manual merge remains possible")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    check(sim.auto_merge_excluded(id),"Exclusion survives JSON round trip")
    check(SaveService.save_now(),"Exclusion save succeeds")
    SaveService.load_and_apply()
    check(sim.auto_merge_excluded(id),"Exclusion survives actual disk reload")
    sim.set_auto_merge_excluded(id,false);sim.campaign.merge_cycle("0",10,11,0)
    check(sim.record(id).merge==2,"Re-enabling resumes automation")
    sim.set_auto_merge_excluded(id,true)
    check(sim.discard(id) and sim.quantity(id)==0 and sim.auto_merge_excluded(id),"Dropping a stack preserves its exclusion record")
    sim.add_item(id,101);sim.record(id).merge=100
    var successor: String=sim.catalog.items[id].next
    if successor!="":
        check(sim.evolve(id) and sim.auto_merge_excluded(successor),"Manual evolution carries exclusion to successor")
    # Discovered boss surroundings and countdown labels use saved authoritative coordinates.
    fresh()
    var boss: Dictionary={}
    for enemy in sim.state.enemies:
        if sim.catalog.groups[int(enemy.group)].boss:boss=enemy;break
    sim.state.player.x=boss.x;sim.state.player.y=boss.y
    sim.campaign.reveal()
    var rim: Vector2=sim.position_of(boss)+Vector2(sim.campaign.fog_rules.camp_footprint_radius*.7,0)
    check(sim.campaign.boss_found("boss-snowman") and sim.campaign.cell_known(rim),"Boss discovery reveals the surrounding camp-sized footprint")
    game._process(.2);await frames(12)
    var objective: Control=game.get_node("Safe/Layout/Map/Objective")
    var gate: Control=game.get_node("Safe/Layout/Map/Gate")
    check(objective.visible and gate.visible and gate.global_position.y>=objective.get_global_rect().end.y+5,"Boss objective and Next Stage chip never overlap")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    check(sim.campaign.cell_known(rim),"Boss surrounding reveal persists through reload")
    for enemy in sim.state.enemies:
        if sim.catalog.groups[int(enemy.group)].boss:boss=enemy;break
    boss.hp=0;sim._kill(boss);game.world._boss_countdowns()
    check(game.world.boss_labels.has(str(boss.id)),"Defeated boss exposes a countdown at its location")
    if game.world.boss_labels.has(str(boss.id)):
        check(game.world.boss_labels[str(boss.id)].position.distance_to(Vector2(boss.home_x,boss.home_y))<150,"Countdown is anchored to the saved boss home")
    sim.tick_boss_respawns(999999);game.world._boss_countdowns()
    check(game.world.boss_labels.is_empty(),"Expired countdown is removed")
    check(game.banner.boss_warning_seconds>=8,"Boss warning remains visible longer")
    check(tr("CONTENT_GROUPS_BOSS-ELEPHANT").contains("Dinosaur"),"Dinosaur label corrected without changing saved identity")
    # Prestige is a real transaction; XP is retained, mastery and partial use progress both reset.
    fresh()
    sim.state.player_level=12;sim.state.xp=17
    sim.state.supply_uses.potion=103;sim.state.supply_mastery_credit.potion=7
    sim.state.bosses_found.append("boss-snowman")
    sim.state.opportunities.hunter_o1={"ready":true,"baseline":{},"step":0,"count":0}
    check(sim.campaign.begin_prestige(),"Prestige begins")
    var guard:=0
    while not sim.state.prestige_batch.is_empty() and guard<40:
        guard+=1;sim.campaign.choose_card(str(sim.campaign.offered_cards()[0]))
    check(sim.state.prestiges==1 and sim.state.player_level==12 and sim.state.xp==17,"Prestige retains level and earned XP")
    check(sim.supply_mastery("potion")==0 and sim.state.supply_uses.is_empty() and sim.state.supply_mastery_credit.is_empty(),"Prestige clears mastery and partial progress")
    check(sim.stats().hp>sim.catalog.progression.hp_per_level*11,"Level-derived benefits recompute")
    SaveService.load_and_apply()
    check(sim.state.player_level==12 and sim.state.xp==17 and sim.supply_mastery("potion")==0,"Prestige result durable")
    # Slot sizes change content density without changing the surrounding panel.
    fresh();sim.state.upgrades.gear_slots=9
    sim.state.gear.resize(sim.equipment_slot_count());sim.state.gear.fill("")
    game._refresh_slots();await frames()
    var grid: GridContainer=game.dock.get_node("Inventory/GearColumn/GearScroll/Gear")
    var widths: Array=[];var columns: Array=[];var heights: Array=[]
    for zoom in [2,1,0]:
        SettingsState.set_inventory_zoom(zoom);game._layout_inventory();await frames(6)
        widths.append(grid.get_child(0).size.x);columns.append(grid.columns)
        heights.append(game.dock.get_node("Inventory").size.y)
    check(widths[0]>widths[1] and widths[1]>widths[2],"Shared zoom reduces slot contents and size")
    check(columns[0]<=3 and columns[1]>=4 and columns[2]>=6,"Zoom provides large medium and small density %s %s" % [columns,widths])
    check(absf(heights[0]-heights[2])<2,"Zoom preserves inventory panel height")
    check(SaveService.save_now(),"Zoom settings saved")
    SettingsState.inventory_zoom=2;SaveService.load_and_apply()
    check(SettingsState.inventory_zoom==0,"Zoom persists on disk")
    game._open("settings");check(button("inventory_zoom_2")!=null,"Settings exposes slot sizes")
    # Integration controls operate the same APIs as automation.
    fresh();sim.add_item("skill_fire");sim.add_item("skill_heal")
    sim.state.upgrades.skill_slots=1;sim.state.upgrades.skill_auto_slots=1
    sim.campaign.equip_skill("skill_heal",0);sim.campaign.equip_skill("skill_fire",1)
    game.player_tab=0;game._open("upgrades")
    check(button("auto_skill_1")!=null,"Automatic slot selection exposed")
    if button("auto_skill_1")!=null:button("auto_skill_1").pressed.emit()
    check(sim.automatic_skill_assignments()==[1],"Purchased capacity assigns preferred equipped slot")
    var upgrades: Array=[]
    for node in game.rows.find_children("*","Button",true,false):upgrades.append(node.get_meta("upgrade",""))
    check(upgrades.has("critical_chance") and upgrades.has("critical_damage") and upgrades.has("skill_auto_slots"),"Permanent critical and capacity upgrades exposed")
    for e in sim.state.enemies:e.aggro=false;e.x=sim.state.player.x+500;e.y=sim.state.player.y
    sim.state.player.quiet=20
    game._update_skill_buttons()
    check(game.get_node("Safe/Layout/Skills").get_child(1).disabled,"Skill button disabled outside proximity")
    sim.state.player.hp=sim.stats().hp*.9;game._update_skill_buttons()
    check(not game.get_node("Safe/Layout/Skills").get_child(0).disabled,"Heal enabled outside combat with missing HP")
    check(game._upgrade_benefit("boss_gem_chance",-1).contains("5%") and game._upgrade_benefit("boss_gem_chance",-1).contains("10%"),"Boss chance row contains effective totals")
    var mini=game.get_node("Safe/Layout/Map/MiniMap");await frames()
    check(mini.player_dot.size.x>=24 and mini.player_dot.z_index>mini.z_index and mini.player_dot.z_index<game.sheet.z_index,"Player marker doubled with explicit rendering priority")
    sim.state.skills[1]="";game.player_tab=0;game._open("upgrades")
    check(button("auto_skill_1")!=null and not button("auto_skill_1").disabled,"Dormant automatic assignment can be cleared")
    if button("auto_skill_1")!=null:button("auto_skill_1").pressed.emit()
    check(sim.automatic_skill_assignments().is_empty(),"Clearing a dormant slot frees automatic capacity")
    # Travel uses one action gate regardless of the selected presentation.
    fresh();sim.state.unlocked_stage=2;sim.state.camps["2"]=[0,1]
    game._select_travel_stage(2)
    check(game.panel=="travel_map","Multiple owned camps open visual picker")
    var map_found:=false
    for node in game.rows.get_children():
        if node.get_script()==load("res://scripts/game/camp_picker.gd"):map_found=true
    check(map_found,"Destination picker is a real stage map")
    sim.state.player.quiet=0
    check(not game._travel_to(2,0) and int(sim.state.stage)==1,"Travel rejects combat")
    sim.state.player.quiet=20
    for e in sim.state.enemies:e.aggro=false
    sim.state.camps["2"]=[0]
    game._select_travel_stage(2)
    check(int(sim.state.stage)==2,"One owned camp travels directly")
    var picker=load("res://scripts/game/camp_picker.gd").new()
    picker.sim=sim;picker.stage_id=2;picker.size=Vector2(600,420);add_child(picker)
    var chosen: Array=[]
    picker.chosen.connect(func(camp: int)->void:chosen.append(camp))
    var destination: Array=sim.catalog.stages[1].spawns[0]
    var map_rect: Rect2=picker.map_rect()
    var point:=map_rect.position+Vector2(destination[0],destination[1])*map_rect.size.x/float(sim.catalog.stages[1].size[0])
    var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=point;touch.pressed=true
    picker._gui_input(touch)
    check(chosen.is_empty(),"Camp map never travels on touch press")
    var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=point+Vector2(0,80)
    picker._gui_input(drag);touch.pressed=false;picker._gui_input(touch)
    check(chosen.is_empty(),"Dragging from a camp cannot trigger travel")
    touch.pressed=true;picker._gui_input(touch);touch.pressed=false;picker._gui_input(touch)
    check(chosen==[0],"Touch release selects the owned camp")
    chosen.clear();sim.state.player.quiet=0
    touch.pressed=true;picker._gui_input(touch);touch.pressed=false;picker._gui_input(touch)
    check(chosen.is_empty(),"Visual picker enforces combat travel restriction")
    picker.queue_free()
    # Guided progression and its timers survive interruption; None and Basic have no tutorial gate.
    for mode in ["none","basic"]:
        fresh(mode);sim.state.bosses_found.append("boss-snowman")
        check(sim.campaign.prestige_gate_reason()=="",mode+" has no tutorial Prestige restriction")
    fresh("guided")
    var flow=sim.campaign.guided
    check(flow.next_step()=="move" and not flow.feature_allowed("missions"),"Guided begins with movement, no premature missions")
    check(not game.get_node("Safe/Layout/Map/Objective").visible or not sim.campaign.prestige_unlocked(),"No permanent boss objective before discovery")
    for step in ["move","kill","collect"]:flow.mark(step)
    sim.add_item(id,2);sim.equip(id);flow.next_step()
    check(flow.next_step()=="close_equip","Equip requires panel close")
    flow.panel_closed("missions");check(flow.next_step()=="close_equip","Wrong panel cannot finish close step")
    flow.panel_closed("item");sim.merge(id);flow.next_step()
    check(flow.next_step()=="close_merge","Merge requires panel close")
    flow.panel_closed("item");sim.state.playtime_total=59
    check(flow.next_step()=="mission_wait","Missions wait full 60 gameplay seconds")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    check(flow.next_step()=="mission_wait","Delay survives JSON restore")
    sim.state.playtime_total=60
    check(flow.next_step()=="missions" and flow.feature_allowed("missions"),"Missions appear at delay boundary")
    flow.mark("missions");flow.panel_closed("missions");sim.state.playtime_total=119
    check(flow.next_step()=="upgrade_wait","Player Upgrades wait 60 seconds after closing Missions")
    sim.state.playtime_total=120
    check(flow.next_step()=="player_upgrade","Player Upgrades timing boundary")
    sim.state.coins=100000;sim.buy_upgrade("respawn")
    check(flow.next_step()=="close_upgrade","Player Upgrade waits for actual close")
    flow.panel_closed("upgrades");flow.mark("camp")
    check(flow.next_step()=="boss_find","Boss discovery follows camp lesson")
    sim.state.bosses_found.append("boss-snowman")
    check(flow.next_step()=="boss_preparation","Boss explanation required")
    flow.acknowledge("boss_preparation")
    check(sim.state.tutorial.seen.has("boss_preparation"),"Objective enabled only after acknowledgement")
    flow.next_step();sim.state.counters.kill=20
    check(flow.next_step()=="expand_inventory","Additional farming before inventory lesson")
    var gems: float=sim.state.gems;flow.next_step();flow.next_step()
    check(sim.state.gems==gems and gems>=sim.upgrade_cost("gear_slots"),"Controlled inventory grant only once")
    sim.buy_upgrade("gear_slots");flow.next_step();flow.panel_closed("upgrades");sim.purchase_consumable("potion");flow.next_step()
    sim.state.player.hp=sim.stats().hp*.5;sim.use_item("potion")
    check(flow.next_step()=="prestige_intro","Potion lesson precedes Prestige introduction")
    check(sim.campaign.prestige_gate_reason()=="PRESTIGE_TUTORIAL_LOCKED","Guided cannot Prestige early")
    flow.acknowledge("prestige_intro");sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1
    for step in ["world_intro","travel_intro","milestones_intro"]:
        check(flow.next_step()==step,"World lesson "+step);flow.acknowledge(step)
    sim.state.unlocked_stage=2;sim.state.player.quiet=20
    for e in sim.state.enemies:e.aggro=false
    check(game._travel_to(2,0),"Tutorial travels to Winter II through real action")
    check(flow.next_step()=="tutorial_final","Winter II final message")
    flow.acknowledge("tutorial_final");check(not flow.complete(),"Cannot confirm before five visible seconds")
    game.guide.evaluate();game.guide._present()
    check(not game.guide.intro_button.visible,"Final confirmation hidden before five seconds")
    flow.shown(4.9);flow.acknowledge("tutorial_final");check(not flow.complete(),"Final delay inclusive boundary")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    flow.shown(.1);game.guide.evaluate();game.guide._present()
    check(game.guide.intro_button.visible,"Final confirmation becomes visible at five seconds")
    flow.acknowledge("tutorial_final")
    check(flow.complete() and sim.campaign.prestige_gate_reason()=="","Final acknowledgement removes Guided restrictions")
    check(SaveService.save_now(),"Completed tutorial saved")
    SaveService.load_and_apply();check(flow.complete(),"Completed tutorial persists")
    SaveService.hard_reset()
    check(sim.state.player_level==1 and sim.state.tutorial.get("flow",{}).get("done",[]).is_empty(),"Hard Reset clears level and Guided progress")
    check(SettingsState.inventory_zoom==0,"Hard Reset retains the slot-size preference with settings")
    print("CHANGE_20_CHECKS ",checks," FAILURES ",failures)
    get_tree().quit(1 if failures else 0)
