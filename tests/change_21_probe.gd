extends "res://tests/change_20_probe.gd"
## Correction regressions through actual purchase, panel and input paths.
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    fresh();await frames()
    var id: String=sim.catalog.groups[0].loot[0]
    sim.add_item(id,3);game.selected=id;game._open("item")
    check(button("item_auto_merge")==null,"Unpurchased auto merge toggle hidden")
    sim.state.upgrades["merge_gear:0"]=1;game._refresh_panel(true)
    check(button("item_auto_merge")!=null,"Purchased auto merge toggle shown")
    button("item_auto_merge").pressed.emit();game._refresh_panel(true)
    check(button("item_auto_merge")!=null and sim.auto_merge_excluded(id),"Excluded item still exposes re-enable control")
    button("item_auto_merge").pressed.emit()
    check(not sim.auto_merge_excluded(id),"Re-enable works")
    game._close();sim.state.gems=1000
    for i in range(5):check(sim.buy_upgrade("supply_slots"),"Supply expansion purchase %d" % i)
    check(sim.state.supplies.size()==6 and sim.level("supply_slots")==5,"Six total supplies slots")
    check(not sim.buy_upgrade("supply_slots"),"Seventh slot is blocked")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    check(sim.state.supplies.size()==6,"Six slots survive restore")
    game._refresh_slots();await frames(8)
    var inv: Control=game.dock.get_node("Inventory")
    var grid: GridContainer=inv.get_node("SupplyColumn/SupplyScroll/Supplies")
    var heights: Array=[]
    for zoom in [0,1,2]:
        SettingsState.set_inventory_zoom(zoom);game._layout_inventory();await frames(10)
        var columns: int=[3,2,1][zoom]
        check(grid.columns==columns,"Supply columns at zoom %d" % zoom)
        check(absf(inv.get_node("GearColumn/GearScroll").global_position.y-inv.get_node("SupplyColumn/SupplyScroll").global_position.y)<1,"Aligned slot rows")
        var h: Control=inv.get_node("SupplyColumn/SupplyHeading")
        var gh: Control=inv.get_node("GearColumn/Head/Heading")
        check(absf(h.get_global_rect().get_center().y-gh.get_global_rect().get_center().y)<1,"Aligned heading baselines")
        heights.append(inv.size.y)
        var count: int=[6,4,1][zoom]
        var viewport: Control=inv.get_node("SupplyColumn/SupplyScroll")
        for index in range(count):
            var slot: Control=grid.get_child(index)
            check(slot.get_global_rect().end.y<=viewport.get_global_rect().end.y+1,"Visible supply slot %d zoom %d" % [index,zoom])
        if columns>1:check(grid.get_child(1).position.y==grid.get_child(0).position.y,"Supply slots side by side")
    check(absf(heights.max()-heights.min())<2,"Stable panel height across sizes")
    sim.state.counters.kill=5;sim.campaign.evaluate_main();game._open("missions");await frames(10)
    var claim:=button("claim")
    check(claim!=null,"Ready mission has Claim")
    if claim!=null:
        check(claim.size.y<=76,"Claim fixed compact height")
        check(claim.size_flags_vertical==Control.SIZE_SHRINK_CENTER,"Claim vertically centered")
    for panel in ["missions","mastery","filters","prestige","upgrades"]:
        game._close();game._open(panel);await frames(8)
        var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
        var bar:=scroll.get_v_scroll_bar()
        check(bar.get_theme_stylebox("grabber").get_minimum_size().x>=14,"Visible-width scrollbar: "+panel)
        if scroll.get_node("Rows").size.y>scroll.size.y:
            check(bar.visible,"Overflow scrollbar shown: "+panel)
            scroll.scroll_vertical=100000;await frames(4)
            check(scroll.scroll_vertical>0,"Can scroll: "+panel)
    game._close()
    # The Road Ahead is a one-time goal announcement for every onboarding mode.
    fresh("none");game.guide.evaluate();game.guide._present()
    check(game.guide.intro_id=="road_ahead" and game.guide.final_backdrop.visible,"None shows centered game goals, without a tutorial")
    check(not game.guide.intro_button.visible,"None goal acknowledgement waits five visible seconds")
    game.guide.intro_button.pressed.emit()
    check(not sim.state.tutorial.seen.has("road_ahead"),"Cannot dismiss goal announcement early")
    game.guide._process(5.0);game.guide.evaluate();game.guide._present()
    check(game.guide.intro_button.visible,"None can acknowledge goals after five seconds")
    game.guide.intro_button.pressed.emit()
    check(sim.state.tutorial.seen.has("road_ahead"),"None goal acknowledgement stored")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    game.guide.evaluate()
    check(game.guide.intro_id=="","None goal announcement does not repeat on restored save")
    fresh("basic");game.guide.evaluate()
    check(game.guide.intro_id!="road_ahead","Basic does not show final goals before its overview cards")
    sim.state.tutorial.seen.append_array(game.guide.BASIC_DECK) # fixture: Change 25 overview read
    game.guide._process(1.0)
    check(game.guide.intro_id=="road_ahead" and game.guide.final_backdrop.visible,"Basic ends with shared goals announcement")
    game.guide._process(60.0);game.guide.evaluate();game.guide._present()
    check(not sim.state.tutorial.seen.has("road_ahead"),"Basic goal announcement never auto-dismisses")
    check(game.guide.intro_button.visible,"Basic goal acknowledgement unlocks after delay")
    game.guide.intro_button.pressed.emit();game.guide.evaluate()
    check(sim.state.tutorial.seen.has("road_ahead") and game.guide.intro_id!="road_ahead","Basic completion is one-time")
    check(tr("GUIDE_TUTORIAL_FINAL")=="THE ROAD AHEAD","All modes use general title")
    for op in sim.catalog.campaign.opportunities:
        var stages: Array=game.prestige_stages(op)
        check(not stages.is_empty(),"Every opportunity grouped: "+str(op.id))
        # Change 54: Masterwork IV (Obsidian, Spring I-II) is grouped on the maps that drop Obsidian.
        if op.path in ["offline","masterwork","arsenal","offering","specialist"] and op.id!="masterwork_o4":check(stages==[0],"Global objective in General")
    # Expanded map camps work even with zero Map Details; touch drag never travels.
    fresh();sim.state.player.quiet=20
    for e in sim.state.enemies:e.aggro=false
    game._open("world");await frames(8)
    var map
    for node in game.rows.get_children():
        if node.get_script()==load("res://scripts/game/map_view.gd"):map=node
    check(map!=null,"World panel retains expanded map")
    var chosen: Array=[]
    map.camp_selected.connect(func(camp: int)->void:chosen.append(camp))
    var at: Array=sim.campaign.stage().spawns[0]
    var rect: Rect2=map.transform_rect()
    var point: Vector2=rect.position+Vector2(at[0],at[1])*rect.size.x/float(sim.catalog.world.size[0])
    var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=point;touch.pressed=true
    map._gui_input(touch);check(chosen.is_empty(),"No travel on press")
    var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=point+Vector2(0,80)
    map._gui_input(drag);touch.pressed=false;map._gui_input(touch)
    check(chosen.is_empty(),"No travel after drag")
    sim.state.player.quiet=0;touch.pressed=true;map._gui_input(touch);touch.pressed=false;map._gui_input(touch)
    check(chosen.is_empty(),"Expanded map combat gate")
    sim.state.player.quiet=20;touch.pressed=true;map._gui_input(touch);touch.pressed=false;map._gui_input(touch)
    check(chosen==[0],"Expanded map travel without Map Details upgrade")
    # Inventory expansion must stop at a real Close arrow.
    fresh("guided")
    var flow=sim.campaign.guided
    for step in flow.STEPS:
        if step=="expand_inventory":break
        flow.mark(step)
    sim.state.gems=100;game.player_tab=1;game._open("upgrades")
    sim.buy_upgrade("gear_slots");await frames(8);game.guide.evaluate()
    check(flow.next_step()=="close_inventory","Expansion waits for close")
    check(game.guide.target==game.get_node("Sheet/Margin/Content/Header/Close"),"Expansion arrow targets Close")
    flow.panel_closed("item");check(flow.next_step()=="close_inventory","Wrong panel cannot close inventory lesson")
    game._close();check(flow.next_step()=="potion_buy","Closing advances to potion lesson")
    print("CHANGE_21_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)
