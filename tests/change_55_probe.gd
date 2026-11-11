extends "res://tests/change_20_probe.gd"
## Change 55 (approved progression brief, B6): contextual hints M1-M3, O1-O2, E1 and the new panels' layout.
## M1 Map Detail hint: shows inline in World on a map with found enemies and no Map Detail, routes to the Map
## upgrades section, at most 3 panel openings, retired by the first Map Detail purchase, never in Guided.
## M2 next-rank benefit; M3 main objective wording; O1 offline gear hint on the welcome-back panel (claims, then
## opens Upgrades > Offline), retired when both unlocks are owned; O2 unlock benefit; E1 evolution readiness,
## once per profile, on the panel's notice line or a toast (never a modal). Layout at 432x960 and 540x960:
## nothing wider than the screen in World, the item panel with three reroll slots, the Prestige panel and its
## confirmation. Runs with --first-run-complete.
func run() -> void:
    SettingsState.mute_all_sfx()
    get_window().size=Vector2i(540,960)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    await map_hint_checks()
    await offline_hint_checks()
    evolve_hint_checks()
    for size in [Vector2i(432,960),Vector2i(540,960)]:await layout_checks(size)
    print("CHANGE_55_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func panel_text() -> String:
    var t:=""
    for l in game.rows.find_children("*","Label",true,false):t+=str(l.text)+"\n"
    return t

func map_hint_checks() -> void:
    fresh()
    sim.campaign.discover_spot(0,2)
    for i in range(3):
        game._open("world");await frames(2)
        check(panel_text().contains(tr("MAP_MARKERS_HINT")) and button("map_upgrades_jump")!=null,"M1 shows in World (opening %d)" % (i+1))
        if i==0:
            var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
            button("map_upgrades_jump").pressed.emit();await frames(3)
            check(scroll.scroll_vertical>0,"M1 routes to Map upgrades (scrolled %d)" % scroll.scroll_vertical)
        game._close()
    game._open("world");await frames(2)
    check(not panel_text().contains(tr("MAP_MARKERS_HINT")) and panel_text().contains(tr("MAP_LEGEND")),"M1 stops after three openings")
    game._close()
    fresh()
    sim.campaign.discover_spot(0,2)
    sim.state.coins=100000
    check(game._upgrade_benefit("map_detail",1)==tr("MAP_DETAIL_NEXT_1"),"M2: rank 1 names markers")
    check(sim.buy_upgrade("map_detail",1),"Buy Map Detail")
    check(game._upgrade_benefit("map_detail",1)==tr("MAP_DETAIL_NEXT_2"),"M2: rank 2 names enemy names")
    game._open("world");await frames(2)
    check(not panel_text().contains(tr("MAP_MARKERS_HINT")) and game.hint_retired("map_detail"),"M1 retired by the purchase")
    game._close()
    fresh("guided")
    sim.campaign.discover_spot(0,2)
    game._open("world");await frames(2)
    check(not panel_text().contains(tr("MAP_MARKERS_HINT")),"M1 never shows during the Guided tutorial")
    game._close()
    check(tr("MAIN_6").contains("Map upgrades"),"M3: main objective 6 names where to buy Map Detail")

func offline_hint_checks() -> void:
    fresh()
    sim.add_item("wood_sword",1);sim.state.gems=200
    sim.state.offline_pending={"id":"p","seconds":3600.0,"longest":3600.0,"rewarded_hours":1.0,"coins":120.0,"gems":2.0,"items":{}}
    game._open("offline");await frames(2)
    # Change 64: the one-time O1 hint became the receipt's persistent locked-categories line + Go to Upgrades.
    check(panel_text().contains(tr("OFFLINE_LOCKED_EXPLAIN")) and button("offline_upgrades_jump")!=null,"O1 shows on the welcome-back panel")
    check(not game.get_node("Confirm").visible,"…inline, no modal")
    button("offline_upgrades_jump").pressed.emit();await frames(3)
    check(sim.state.offline_pending.is_empty() and game.panel=="upgrades" and game.player_tab==4,"O1 claims first, then opens Upgrades > Offline")
    check(game._upgrade_benefit("offline_weapon",-1)==tr("OFFLINE_GEAR_BENEFIT"),"O2: the unlock says it copies owned gear")
    game._close()
    # Change 61: supplies are an offline unlock too; the hint retires once all three are owned.
    sim.state.upgrades["offline_weapon"]=1;sim.state.upgrades["offline_outfit"]=1;sim.state.upgrades["offline_consumable"]=1
    sim.state.offline_pending={"id":"q","seconds":3600.0,"longest":3600.0,"rewarded_hours":1.0,"coins":120.0,"gems":2.0,"items":{}}
    game._open("offline");await frames(2)
    check(not panel_text().contains(tr("OFFLINE_LOCKED_EXPLAIN")),"O1 gone once all three unlocks are owned")
    game._close()
    fresh()
    sim.add_item("wood_sword",1);sim.state.gems=10
    sim.state.offline_pending={"id":"r","seconds":3600.0,"longest":3600.0,"rewarded_hours":1.0,"coins":120.0,"gems":2.0,"items":{}}
    game._open("offline");await frames(2)
    # Change 61 (approved): affordability no longer suppresses the hint; a player short of Gems still learns it.
    check(panel_text().contains(tr("OFFLINE_LOCKED_EXPLAIN")),"O1 shows even when the player cannot afford an unlock yet")
    game._close()

func evolve_hint_checks() -> void:
    fresh()
    game._toast("");game.toast_queue.clear()
    sim.add_item("wood_sword",21)
    sim.merge("wood_sword",true)
    var expected: String=tr("EVOLVE_READY_HINT") % [sim.catalog.display_name("wood_sword"),10,sim.catalog.display_name("stone_sword")]
    check(game.toast_queue.has(expected) and game.hint_retired("evolve_ready"),"E1: reaching ^20 explains the 10 spares and the next tier (%s)" % str(game.toast_queue))
    game.toast_queue.clear()
    sim.add_item("wood_axe",21);sim.merge("wood_axe",true)
    check(game.toast_queue.is_empty(),"E1 shows once per profile")

func overflow(root: Node,width: float) -> Array:
    var out: Array=[]
    for c in root.find_children("*","Control",true,false):
        if c.is_visible_in_tree() and (c is Label or c is Button) and c.get_global_rect().end.x>width+1.0:out.append("%s %s '%s' (width %.0f)" % [c.name,str(c.get_global_rect()),str(c.text).left(60),width])
    return out

func layout_checks(size: Vector2i) -> void:
    get_window().size=size;await frames(4)
    var width: float=game.get_viewport_rect().size.x
    fresh()
    sim.campaign.discover_spot(0,2)
    game._open("world");await frames(3)
    check(overflow(game,width).is_empty(),"%dx%d World with M1: nothing wider than the screen %s" % [size.x,size.y,str(overflow(game,width).slice(0,3))])
    game._close()
    sim._drop("wood_axe",{"group":sim.campaign.group_id("boss-snowman"),"x":10.0,"y":10.0})
    sim.collect(int(sim.state.pickups.back().uid))
    game.selected="wood_axe";game._open("item");await frames(3)
    check(overflow(game,width).is_empty(),"%dx%d item panel with three reroll slots fits %s" % [size.x,size.y,str(overflow(game,width).slice(0,3))])
    game._close()
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman")
    for op in sim.catalog.campaign.opportunities:sim.state.opportunities[op.id]={"ready":false,"baseline":{},"step":0,"count":0}
    sim.state.opportunities["hunter_o1"].ready=true
    sim.state.unlocked_stage=8
    game._open("prestige");await frames(3)
    check(overflow(game,width).is_empty(),"%dx%d Prestige panel with 48 opportunities fits %s" % [size.x,size.y,str(overflow(game,width).slice(0,3))])
    game._open_prestige_confirm(["hunter_o1"]);await frames(4)
    var plate: Control=game.get_node("PrestigeConfirm/Plate")
    check(plate.get_global_rect().end.x<=width+1 and plate.get_global_rect().end.y<=game.get_viewport_rect().size.y+1,"%dx%d Prestige confirmation fits (%s)" % [size.x,size.y,str(plate.get_global_rect())])
    game.get_node("PrestigeConfirm").close()
    game._close()
    # The card choice of an expanded path (Expedition: eight unowned cards) wraps inside the screen.
    fresh()
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman")
    sim.state.opportunities["expedition_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    check(sim.campaign.begin_prestige() and sim.campaign.offered_cards().size()==8,"Expedition offers its eight cards")
    game._open("prestige");await frames(3)
    check(overflow(game,width).is_empty(),"%dx%d eight-card choice fits %s" % [size.x,size.y,str(overflow(game,width).slice(0,3))])
    game._close()
    sim.campaign.cancel_prestige()
