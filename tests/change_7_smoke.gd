extends Node
## Change 7 build-readiness smoke: real main scene; every panel opens, the simulation steps, the
## offline claim and the legacy weapon map run. Errors surface as SCRIPT ERROR lines.
var sim
var game
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="guided";sim.suspended=false
    sim.add_item("potion",2);sim.add_item("wood_sword",3);sim.add_item("unit-blue-cap_outfit",2);sim.add_item("coin_boost",1)
    sim.use_item("coin_boost")
    for i in range(300):sim.step(.1)
    for p in ["world","missions","prestige","stats","settings","upgrades","history","inventory","offline"]:
        game._open(p);await frames(3)
    game.selected="wood_sword";game.selected_slot=-1;game._open("item");await frames(3)
    game.selected="coin_boost";game.selected_slot=sim.state.supplies.find("coin_boost");game._open("item");await frames(3)
    game._nav("stats");await frames(2);game._nav("stats");await frames(2)
    print("SMOKE nav_closed=",not game.sheet.visible)
    sim.state.offline_snapshot=sim.campaign.offline_snapshot();sim.state.offline_snapshot.time-=7200
    sim.campaign.settle_offline();await frames(10)
    print("SMOKE pending=",not sim.state.offline_pending.is_empty()," panel=",game.panel)
    print("SMOKE claimed=",sim.campaign.claim_offline()," pending_after=",sim.state.offline_pending.size())
    var snap: Dictionary=sim.snapshot()
    snap.items["unit-red-scarf_weapon_t2"]={"qty":4,"merge":7,"extras":{}};snap.weapon="unit-red-scarf_weapon_t2"
    snap.history.push_front({"key":"HISTORY_ITEM","id":"unit-chef-hat_weapon","amount":1,"coins":0,"time":0})
    sim.restore(JSON.parse_string(JSON.stringify(snap)))
    print("SMOKE legacy weapon=",sim.state.weapon," qty=",sim.quantity("stone_sword")," load=",SaveService.last_load_result)
    for i in range(100):sim.step(.1)
    await frames(10)
    print("SMOKE done")
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(0)
