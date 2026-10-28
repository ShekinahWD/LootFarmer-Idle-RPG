extends "res://tests/change_20_probe.gd"
## Targeted Change 22 acceptance: modal stability, real-time waits, post-purchase guidance,
## stage collapse defaults, manual overrides and save compatibility.
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    fresh("none");sim.state.tutorial.seen.append("road_ahead");await frames(8)

    # Confirmation initially settles, then remains stable across many rendered frames.
    game._confirm("Drop every copy of this equipment stack? This action cannot be undone.\nThe gear will be permanently removed from your inventory.",func()->void:pass,"Drop All",true)
    await frames(6)
    check(game.get_node("Confirm").visible,"Drop All confirmation opened")
    var modal: Control=game.get_node("Confirm/Panel")
    var initial_size: Vector2=modal.size
    var initial_pos: Vector2=modal.position
    check(initial_size.x>100 and initial_size.y>100,"Confirmation fits a visible size")
    for i in range(18):
        await frames(1)
        check(modal.size.is_equal_approx(initial_size) and modal.position.is_equal_approx(initial_pos),"Dialog does not reflow on frame %d" % i)
    game._cancel_confirm()
    check(not game.get_node("Confirm").visible,"Cancel closes Drop All confirmation")
    game._confirm("Another shorter confirmation",func()->void:pass)
    await frames(5)
    check(game.get_node("Confirm").modulate.a==1.0,"Latest confirmation becomes visible after settling")
    game._cancel_confirm()

    # Real-frame wait accumulates 15 seconds independent of capped simulation playtime.
    fresh("guided");var flow=sim.campaign.guided
    for step in flow.STEPS:
        if step=="mission_wait":break
        flow.mark(step)
    var physics_time: float=float(sim.state.playtime_total)
    flow.advance_waits(14.9)
    check(flow.next_step()=="mission_wait","Missions still waits after 14.9 real seconds")
    flow.advance_waits(.2)
    check(flow.next_step()=="missions","Missions unlock after 15.1 real seconds")
    check(is_equal_approx(float(sim.state.playtime_total),physics_time),"Tutorial wait does not need physics playtime increments")
    flow.mark("missions");flow.mark("close_missions")
    flow.advance_waits(7.0)
    var serialized: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    sim.restore(serialized)
    check(is_equal_approx(float(sim.campaign.guided.data().wait_seconds.get("upgrade_wait",0.0)),7.0),"Partial wait survives profile reload")
    sim.campaign.guided.advance_waits(8.1)
    check(sim.campaign.guided.next_step()=="player_upgrade","Player Upgrades becomes available after accumulated 15 seconds")

    # Purchase leaves automation OFF and teaches the player to turn it ON, never Main Objectives.
    fresh("none");sim.state.tutorial.seen.append("road_ahead")
    sim.state.gems=1000
    check(sim.buy_upgrade("mission_claim"),"Auto Claim upgrade can be purchased")
    check(not sim.state.mission_auto,"Buying Auto Claim never silently enables it")
    game._open("missions");await frames(8)
    var toggle: Button=button("mission_auto_toggle")
    check(toggle!=null and toggle.text.contains("OFF"),"OFF toggle is clearly exposed in Missions")
    check(game.guide._mission_auto_hint(),"Guide discovers purchased but disabled automation")
    game.guide.evaluate()
    check(game.guide.target==toggle,"Guidance targets actual ON/OFF toggle")
    if toggle!=null:toggle.pressed.emit()
    check(sim.state.mission_auto and sim.state.tutorial.seen.has("mission_auto_enabled"),"Enabling Auto Claim saves tutorial acknowledgement")
    check(not game.guide._mission_auto_hint(),"Guidance stops after enabling Auto Claim")
    game._close()

    # Stage heading defaults open while incomplete; becomes collapsed after all its objectives
    # are consumed. A manual expansion survives a JSON save/load and a panel reopen.
    fresh("none");sim.state.tutorial.seen.append("road_ahead")
    game._open("prestige");await frames(8)
    var header: Button=null
    for candidate in game.rows.find_children("*","Button",true,false):
        if candidate.get_meta("prestige_stage",-1)==1:header=candidate;break
    check(header!=null and header.text.begins_with("▼"),"Incomplete Winter I section expands by default")
    for op in sim.catalog.campaign.opportunities:
        if game.prestige_stages(op).has(1):
            sim.state.consumed.append(op.id)
            sim.state.opportunities[op.id]={"ready":true,"baseline":{},"step":0,"count":0}
    sim.touch();game._refresh_panel(true);await frames(8)
    header=null
    for candidate in game.rows.find_children("*","Button",true,false):
        if candidate.get_meta("prestige_stage",-1)==1:header=candidate;break
    check(header!=null and header.text.begins_with("▶") and header.text.contains("✓"),"All-complete stage is collapsed by default")
    if header!=null:header.pressed.emit()
    check(sim.state.prestige_collapsed.get("1",true)==false,"Tapping the heading manually expands a completed stage")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    game._close();game._open("prestige");await frames(8)
    header=null
    for candidate in game.rows.find_children("*","Button",true,false):
        if candidate.get_meta("prestige_stage",-1)==1:header=candidate;break
    check(header!=null and header.text.begins_with("▼"),"Manual expansion survives save/load and reopening")
    print("CHANGE_22_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)
