extends Node
## Change 10 build-readiness smoke: the new and changed panels open on the real main scene with
## fresh and researched profiles. Errors surface as SCRIPT ERROR lines.
var sim
var game
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="guided";sim.suspended=false
    sim.add_item("unit-blue-cap_outfit",3);sim.record("unit-blue-cap_outfit").merge=250;sim.equip("unit-blue-cap_outfit")
    sim.add_item("wood_sword",2)
    for i in range(50):sim.step(.1)
    game._nav("prestige");await frames(3)
    print("SMOKE prestige_open=",game.sheet.visible and game.panel=="prestige")
    game.top.get_node("Meters/XP/Open").pressed.emit();await frames(3)
    print("SMOKE level_open=",game.panel=="level")
    game.top.get_node("Meters/XP/Open").pressed.emit();await frames(3)
    print("SMOKE level_toggle_closed=",not game.sheet.visible)
    game._open("farming");await frames(3)
    for g in sim.campaign.stage().groups:
        sim.state.upgrades["reveal_stats:%d" % g]=1;sim.state.upgrades["reveal_drops:%d" % g]=1
    sim.state.upgrades["map_detail:1"]=3;sim.touch()
    game.guide_stage=1;game._refresh_panel(true);await frames(3)
    print("SMOKE farming_map=",game.panel_context.ends_with(":1"))
    game._open("stats");await frames(3)
    game.player_tab=1;game._open("upgrades");await frames(3)
    sim.state.upgrades["gear_slots"]=67;game._refresh_panel(true);await frames(3)
    game._open("inventory");await frames(3)
    game.selected="unit-blue-cap_outfit";game._open("item");await frames(3)
    game._confirm(tr("RESET_CONFIRM"),func()->void:pass);await frames(3)
    print("SMOKE confirm_x=",$"..".get_viewport().get_visible_rect().size.x," box=",game.get_node("Confirm/Panel").get_rect())
    game._cancel_confirm()
    print("SMOKE done")
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(0)
