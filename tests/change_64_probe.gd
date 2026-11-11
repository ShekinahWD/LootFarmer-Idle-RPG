extends Node
## Change 64 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## - Teleport: a camp's Teleport opens the visual map picker; stage buttons for every reached map; a tap
##   selects (never travels), a drag selects nothing, the current camp and locked camps are refused, a
##   map with one owned camp never auto-travels; Confirm revalidates combat, death, the Prestige lock and
##   pause at the moment of travel; success keeps the respawn camp; Back cancels; the open panel keeps its
##   size while selecting; World travel still works; the Guided camp-travel arrow is on the real marker.
## - Prestige: card grids fit the sheet in equal columns, the selection frame stays inside its card, the
##   path chips wrap untrimmed, and selecting a card never resizes the open panel.
## - Offline: five categories always listed; Locked only for a locked unlock; per-kind totals from the
##   pending record; the persistent explanation and Go to Upgrades (claims once, then Upgrades → Offline);
##   pending survives a reload, claims once, and a later unlock never changes the settled record.
var checks:=0
var failures:=0
var game
var sim
var guide
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")
func fresh(mode:="none") -> void:
    get_tree().paused=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode=mode
    if mode!="guided":sim.campaign.onboarding.reveal_all(true)
    game._close();game.toast_queue.clear();game.get_node("Toast").hide()
    game.get_node("PrestigeConfirm").close();game._cancel_confirm()
    sim.state.player.quiet=1e9
    for e in sim.state.enemies:e.aggro=false
func run() -> void:
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;guide=game.guide
    await frames()
    await teleport_checks()
    await guided_teleport_checks()
    await prestige_checks()
    await offline_checks()
    print("CHANGE_64_CHECKS %d FAILURES %d" % [checks,failures])
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- helpers
func button_meta(root: Node,key: String) -> Button:
    for b in root.find_children("*","Button",true,false):
        if b.get_meta("guide","")==key and not b.is_queued_for_deletion():return b
    return null
func button_text(root: Node,text: String) -> Button:
    for b in root.find_children("*","Button",true,false):
        if b.text==text and not b.is_queued_for_deletion():return b
    return null
func panel_text() -> String:
    var parts: Array=[]
    for l in game.rows.find_children("*","Label",true,false):
        if not l.is_queued_for_deletion():parts.append(l.text)
    return "\n".join(parts)
func teleport_map() -> Control:
    for node in game.rows.get_children():
        if node.has_meta("teleport_map") and not node.is_queued_for_deletion():return node
    return null
func stand_at(camp: int) -> void:
    var a: Array=sim.campaign.stage().spawns[camp]
    sim.state.player.x=a[0];sim.state.player.y=a[1];sim.state.player.quiet=1e9
    game._settle_camp()
func position() -> Vector2:return sim.position_of(sim.state.player)
## A real press/release through the picker's input handler; drag moves the pointer before release.
func tap_map(map: Control,camp: int,drag:=Vector2.ZERO) -> void:
    var at: Vector2=map.camp_point(camp)
    var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=at
    map._gui_input(down)
    if drag!=Vector2.ZERO:
        var move:=InputEventMouseMotion.new();move.position=at+drag
        map._gui_input(move)
    var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=at+drag
    map._gui_input(up)
func open_picker() -> void:
    game.selected_camp=game._camp_at_player();game._open("camp");await frames(2)
    button_meta(game.rows,"camp_teleport").pressed.emit();await frames(6)
func three_maps() -> void:
    sim.state.unlocked_stage=3 # fixture: three reached maps
    sim.state.camps["1"]=[0,1];sim.state.spawns=sim.state.camps["1"];sim.state.camps_known["1"]=[0,1]
    sim.state.camps["2"]=[0];sim.state.camps_known["2"]=[0,1] # one owned, one sighted (locked)
    sim.state.camps["3"]=[0,1,2];sim.state.camps_known["3"]=[0,1,2]

# ---------------------------------------------------------------- teleport
func teleport_checks() -> void:
    print("-- Teleport")
    fresh();three_maps();stand_at(0)
    var spawn:=int(sim.state.spawn)
    await open_picker()
    var map:=teleport_map()
    check(game.panel=="teleport" and map!=null and map.select_mode,"Camp Teleport opens the visual map picker")
    var stage_buttons: Array=[]
    for st in range(1,4):
        if button_meta(game.rows,"teleport_stage_%d" % st)!=null:stage_buttons.append(st)
    check(stage_buttons==[1,2,3] and button_meta(game.rows,"teleport_stage_4")==null,"A stage button for every reached map, none for locked maps")
    check(button_meta(game.rows,"teleport_stage_1").theme_type_variation==&"Primary","The displayed map is highlighted")
    check(map.stage_id==1 and map.here==0 and map.selected==-1,"Opens on the player's map with the current camp marked")
    check(map.size.x>=game._rows_width()-2 and map.size.y>=300,"The map takes the sheet's full width (%s)" % str(map.size))
    var sheet_before: Rect2=game.sheet.get_global_rect()
    # A drag that starts on a camp selects nothing; tapping the current camp is refused.
    tap_map(map,1,Vector2(0,40));await frames(2)
    check(game.teleport_target.is_empty(),"A drag across a camp selects nothing")
    tap_map(map,0);await frames(2)
    check(game.teleport_target.is_empty() and game.notice.text==tr("TELEPORT_HERE"),"The current camp is not a destination")
    tap_map(teleport_map(),1);await frames(8)
    check(game.teleport_target==[1,1] and game.panel=="teleport" and position().distance_to(Vector2(sim.campaign.stage().spawns[0][0],sim.campaign.stage().spawns[0][1]))<1,"A tap selects camp 2 without travelling")
    check(teleport_map().selected==1 and panel_text().contains(tr("TELEPORT_SELECTED") % [sim.catalog.stages[0].name,2]),"The selection is marked on the map and named")
    check(game.sheet.get_global_rect().is_equal_approx(sheet_before),"Selecting keeps the open panel's size and place (%s / %s)" % [sheet_before,game.sheet.get_global_rect()])
    var go:=button_meta(game.actions,"teleport_go")
    check(go!=null and not go.disabled and go.text==tr("TELEPORT_CONFIRM"),"Confirm Teleport is enabled")
    # A map with a single owned camp: switching to it never travels.
    button_meta(game.rows,"teleport_stage_2").pressed.emit();await frames(6)
    check(int(sim.state.stage)==1 and game.panel=="teleport" and teleport_map().stage_id==2 and game.teleport_target==[1,1],"Switching to a one-camp map shows it; no auto-teleport")
    tap_map(teleport_map(),1);await frames(2)
    check(game.teleport_target==[1,1] and game.notice.text==tr("TELEPORT_CAMP_LOCKED"),"A sighted locked camp is refused")
    tap_map(teleport_map(),0);await frames(4)
    check(game.teleport_target==[2,0],"Selecting Winter II camp 1")
    # Revalidation at Confirm: combat, death, the Prestige lock and pause each block the move.
    var at:=position()
    var e: Dictionary=sim.state.enemies[0];e.aggro=true # fixture: combat starts while choosing
    game._refresh_panel(true);await frames(2)
    go=button_meta(game.actions,"teleport_go")
    check(go.disabled and panel_text().contains(tr("TRAVEL_COMBAT")),"In combat Confirm is disabled and says why")
    go.pressed.emit();await frames(2)
    check(int(sim.state.stage)==1 and position()==at,"Confirm pressed in combat: no move (camp_action re-checks)")
    e.aggro=false
    sim.state.player.hp=0.0 # fixture: dead
    check(not game._travel_to(2,0) and int(sim.state.stage)==1,"Dead: travel refused")
    sim.state.player.hp=sim.stats().hp
    sim.state.prestige_batch={"ids":["x"],"choices":[],"transaction":"t"} # fixture: Prestige transaction open
    check(not game._travel_to(2,0) and int(sim.state.stage)==1,"Prestige transaction: travel refused")
    sim.state.prestige_batch={}
    get_tree().paused=true
    check(not game._travel_to(2,0) and int(sim.state.stage)==1,"Paused: travel refused")
    get_tree().paused=false
    # Success through the button.
    game._refresh_panel(true);await frames(2)
    button_meta(game.actions,"teleport_go").pressed.emit();await frames(8)
    var arrival: Array=sim.catalog.stages[1].spawns[0]
    check(int(sim.state.stage)==2 and position().distance_to(Vector2(arrival[0],arrival[1]))<1,"Confirm Teleport arrives at Winter II camp 1")
    check(not game.sheet.visible and game.world.following_player and game.teleport_target.is_empty() and game.teleport_stage==0,"Arrival closes the picker, the camera follows, the selection clears")
    check(int(sim.state.respawns.get("1",-1))==spawn,"The respawn camp chosen on Winter I is unchanged")
    # Back cancels without moving.
    stand_at(0)
    await open_picker()
    tap_map(teleport_map(),0) # current camp: refused
    button_meta(game.rows,"teleport_stage_3").pressed.emit();await frames(4)
    tap_map(teleport_map(),2);await frames(4)
    at=position()
    button_meta(game.actions,"teleport_back").pressed.emit();await frames(4)
    check(game.panel=="camp" and position()==at and int(sim.state.stage)==2 and game.teleport_target.is_empty(),"Back returns to the camp without moving")
    game._close()
    # World travel still works: a one-camp map travels directly (unchanged World rule), a multi-camp map opens the map.
    game._open("world");await frames(3)
    button_meta(game.rows,"travel_stage_3").pressed.emit();await frames(4)
    check(game.panel=="travel_map","World → a map with several camps opens its travel map")
    var travel: Control=null
    for node in game.rows.get_children():
        if node.get_script()==preload("res://scripts/game/camp_picker.gd") and not node.is_queued_for_deletion():travel=node
    check(travel!=null and not travel.select_mode,"…the travel-mode picker")
    tap_map(travel,2);await frames(8)
    var c3: Array=sim.catalog.stages[2].spawns[2]
    check(int(sim.state.stage)==3 and position().distance_to(Vector2(c3[0],c3[1]))<1 and not game.sheet.visible,"World map travel still moves on tap")

func guided_teleport_checks() -> void:
    print("-- Guided camp travel")
    fresh("guided")
    var flow=sim.campaign.guided
    flow.data().done=flow.STEPS.slice(0,flow.STEPS.find("camp_travel"))
    sim.campaign.onboarding.reveal_all(true) # fixture: World is revealed by this point of the tutorial
    sim.state.camps["1"]=[0,1];sim.state.spawns=sim.state.camps["1"];sim.state.camps_known["1"]=[0,1] # fixture
    stand_at(0);await frames(4)
    check(flow.next_step()=="camp_travel","camp_travel is the next lesson")
    await open_picker();await frames(10)
    var map:=teleport_map()
    var marker:=Rect2(map.global_position+map.camp_point(1)-Vector2.ONE*24,Vector2.ONE*48)
    check(guide.target==map and guide.screen_target.is_equal_approx(marker) and guide.pointer.visible,"The arrow is on camp 2's marker on the map")
    tap_map(map,1);await frames(10)
    check(guide.target==button_meta(game.actions,"teleport_go") and guide.pointer.visible,"After selecting, the arrow is on Confirm Teleport")
    button_meta(game.actions,"teleport_go").pressed.emit();await frames(4)
    check(flow.data().done.has("camp_travel"),"Teleporting finishes the lesson")

# ---------------------------------------------------------------- prestige
func prestige_checks() -> void:
    print("-- Prestige layout")
    fresh()
    sim.state.unlocked_stage=8 # fixture
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1 # fixture: Snowman defeated
    for op in sim.catalog.campaign.opportunities:sim.state.opportunities[op.id]={"ready":true,"baseline":{},"step":0,"count":0} # fixture
    for st in range(0,9):sim.state.prestige_collapsed[str(st)]=false
    sim.touch()
    game._open("prestige");await frames(6)
    var scroll: Control=game.get_node("Sheet/Margin/Content/Scroll")
    var limit: Rect2=scroll.get_global_rect()
    var bad: Array=[]
    for node in game.rows.find_children("*","Control",true,false):
        if node.is_visible_in_tree() and node.size.x>0:
            var r: Rect2=node.get_global_rect()
            if r.position.x<limit.position.x-.5 or r.end.x>limit.end.x+.5:bad.append(str(node.name))
    check(bad.is_empty(),"Every Prestige row stays inside the sheet's width %s" % str(bad.slice(0,5)))
    var chips: Array=game.rows.find_children("*","HFlowContainer",true,false)
    var trimmed:=false
    for flow in chips:
        for label in flow.get_children():
            if label is Label and label.text_overrun_behavior!=TextServer.OVERRUN_NO_TRIMMING:trimmed=true
    check(not chips.is_empty() and not trimmed,"Path card chips wrap at full length")
    var ids: Array=sim.campaign.awardable_ids()
    ids.erase("expedition_o1");ids.push_front("expedition_o1")
    sim.state.prestige_batch={"ids":ids,"choices":[],"transaction":"probe"} # fixture: the largest offer (Expedition) first
    game.selected_card="";game._open("prestige");await frames(8)
    var grid: GridContainer=null
    for node in game.rows.get_children():
        if node is GridContainer:grid=node
    check(sim.campaign.offered_cards().size()==8 and grid!=null and grid.get_child_count()==8,"The catalog maximum offer: eight Expedition cards")
    check(grid!=null and grid.columns>=1 and grid.get_global_rect().end.x<=limit.end.x+.5,"Offered cards in %d equal column(s) inside the sheet" % (grid.columns if grid else 0))
    var before: Rect2=game.sheet.get_global_rect()
    var card: Button=grid.get_child(grid.get_child_count()-1)
    card.pressed.emit();await frames(8)
    grid=null
    for node in game.rows.get_children():
        if node is GridContainer:grid=node
    var picked: Button=grid.get_child(grid.get_child_count()-1)
    var frame: Control=picked.get_node("Selected")
    check(frame.visible and picked.get_global_rect().encloses(frame.get_global_rect()),"The selection frame stays inside the selected card")
    check(game.sheet.get_global_rect().is_equal_approx(before),"Selecting a card keeps the open panel's size")
    check(button_meta(game.actions,"keep_card")!=null and not button_meta(game.actions,"keep_card").disabled,"Keep Card stays reachable")
    sim.state.prestige_batch={};game.selected_card="";game._close()

# ---------------------------------------------------------------- offline
func pending(id: String,items: Dictionary) -> void:
    sim.state.offline_pending={"id":id,"seconds":7200.0,"longest":7200.0,"rewarded_hours":2.0,"coins":240.0,"gems":4.0,"items":items} # fixture
func category(kind: String) -> Array:
    for line in game.rows.find_children("*","HBoxContainer",true,false):
        if line.get_meta("offline_category","")==kind and not line.is_queued_for_deletion():
            var labels: Array=line.get_children().filter(func(n):return n is Label)
            return labels.map(func(l):return l.text)
    return []
func offline_checks() -> void:
    print("-- Offline rewards")
    fresh()
    pending("a",{})
    game._open("offline");await frames(3)
    for kind in ["weapon","outfit","consumable"]:
        var row:=category(kind)
        check(row.size()==3 and row[1]=="0" and row[2]==tr("OFFLINE_CAT_LOCKED"),"Fresh: %s reads 0 · Locked (%s)" % [kind,str(row)])
    check(category("coins").size()==3 and category("coins")[2]=="" and category("gems")[1]==game.fmt_currency(4.0),"Coins and Gems are listed with their amounts")
    check(panel_text().contains(tr("OFFLINE_LOCKED_EXPLAIN")) and button_meta(game.rows,"offline_upgrades_jump")!=null and button_meta(game.rows,"offline_upgrades_jump").text==tr("OFFLINE_GO_UPGRADES"),"The locked explanation and Go to Upgrades are shown")
    game._close();game._open("offline");await frames(3)
    check(panel_text().contains(tr("OFFLINE_LOCKED_EXPLAIN")),"…and stay on every opening while locked (not a one-time hint)")
    game._close()
    # Partly unlocked: an unlocked category with nothing earned reads 0, not Locked.
    fresh()
    sim.state.upgrades["offline_weapon"]=1 # fixture
    pending("b",{})
    game._open("offline");await frames(3)
    check(category("weapon")[1]=="0" and category("weapon")[2]=="","Unlocked Weapons with nothing earned: 0, not Locked")
    check(category("outfit")[2]==tr("OFFLINE_CAT_LOCKED") and category("consumable")[2]==tr("OFFLINE_CAT_LOCKED"),"Outfits and Supplies still Locked")
    game._close()
    # Fully unlocked with items: per-kind totals plus the item rows; no explanation.
    fresh()
    for u in ["offline_weapon","offline_outfit","offline_consumable"]:sim.state.upgrades[u]=1 # fixture
    var weapons: Array=[];var outfit:=""
    for id in sim.catalog.items:
        var kind: String=sim.catalog.items[id].kind
        if kind=="weapon" and weapons.size()<2:weapons.append(id)
        if kind=="outfit" and outfit=="":outfit=id
    pending("c",{weapons[0]:2,weapons[1]:1,outfit:4,"potion":3,"removed_item":9})
    game._open("offline");await frames(3)
    check(category("weapon")[1]=="3" and category("outfit")[1]=="4" and category("consumable")[1]=="3","Totals by catalog kind (weapons 2+1, outfits 4, supplies 3; unknown ids not counted)")
    check(panel_text().contains(sim.catalog.display_name(weapons[0])+" ×2") and panel_text().contains(sim.catalog.display_name("potion")+" ×3"),"Individual items are still listed")
    check(not panel_text().contains(tr("OFFLINE_LOCKED_EXPLAIN")) and button_meta(game.rows,"offline_upgrades_jump")==null,"All unlocked: no explanation, no Go to Upgrades")
    game._close()
    # Go to Upgrades: claims once, then opens Upgrades → Offline.
    fresh()
    sim.add_item("wood_sword",1)
    pending("d",{})
    var coins: float=sim.state.coins;var gems: float=sim.state.gems
    game._open("offline");await frames(3)
    button_meta(game.rows,"offline_upgrades_jump").pressed.emit();await frames(4)
    check(sim.state.offline_pending.is_empty() and is_equal_approx(sim.state.coins,coins+240.0) and is_equal_approx(sim.state.gems,gems+4.0),"Go to Upgrades claims the receipt once")
    check(game.panel=="upgrades" and game.player_tab==4,"…and opens Upgrades → Offline")
    check(category("weapon").size()==2 and category("weapon")[1]=="0","The Offline tab's last-claim receipt uses the same categories")
    check(not sim.campaign.claim_offline() and is_equal_approx(sim.state.coins,coins+240.0),"A second claim pays nothing")
    game._close()
    # A settled record never changes when an unlock is bought later; it survives a reload; one claim.
    fresh()
    pending("e",{})
    var settled: Dictionary=sim.state.offline_pending.duplicate(true)
    sim.state.upgrades["offline_weapon"]=1 # fixture: unlocked after the record was settled
    game._open("offline");await frames(3)
    check(sim.state.offline_pending==settled and category("weapon")[1]=="0" and category("weapon")[2]=="","Unlocking later: the settled record is unchanged (0 weapons, no retroactive reward)")
    game._close()
    check(SaveService.save_now(),"Saved with rewards pending")
    SaveService.load_and_apply();sim.suspended=false;await frames(2)
    check(sim.state.offline_pending==settled,"Pending rewards survive a reload unchanged")
    coins=sim.state.coins
    check(sim.campaign.claim_offline() and is_equal_approx(sim.state.coins,coins+240.0),"Claimed once after reload")
    check(SaveService.save_now(),"Saved after the claim")
    SaveService.load_and_apply();sim.suspended=false
    check(sim.state.offline_pending.is_empty() and not sim.campaign.claim_offline() and is_equal_approx(sim.state.coins,coins+240.0),"After reload nothing can be claimed twice")
    game._close()
