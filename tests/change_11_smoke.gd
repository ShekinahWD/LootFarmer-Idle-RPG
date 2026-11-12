extends Node
## Change 11 build-readiness smoke: every new or changed panel and action runs once on the real main
## scene (supplies, Filters, Teleport picker, collection follower, minimap markers, Prestige keeping
## gem upgrades). Errors surface as SCRIPT ERROR lines; the focused assertions are change_11_probe.
var sim
var game
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
    sim.rng.seed=1111
    sim.state.upgrades["supply_slots"]=4;sim.state.supplies.resize(5);sim.state.supplies.fill("")
    for id in sim.supply_ids():sim.add_item(id,3)
    sim.state.player.hp=sim.stats().hp*.5
    for id in sim.supply_ids():print("SMOKE use ",id," ",sim.use_item(id))
    for i in range(30):sim.step(.1)
    game.selected="guard_tonic";game.selected_slot=-1;game._open("item");await frames(3)
    print("SMOKE supply_panel=",game.panel=="item")
    game._nav("filters");await frames(3)
    game.inventory_filter=2;game._refresh_panel(true);await frames(2)
    game._nav("filters");await frames(2)
    # Change 71: the category is a saved preference, kept when Filters closes.
    print("SMOKE filters_kept=",game.inventory_filter==2 and not game.sheet.visible)
    game.inventory_filter=0
    sim.state.camps["1"]=[0,1];sim.state.spawns=sim.state.camps["1"];sim.state.camps_known["1"]=[0,1]
    game.selected_camp=0;game._open("camp");await frames(3)
    game._open("teleport");await frames(3)
    game.teleport_target=[1,1];game._refresh_panel(true);await frames(3)
    for i in range(80):sim.step(.1)
    var moved: bool=game._travel_to(1,1)
    print("SMOKE teleport=",moved," spawn=",sim.state.spawn)
    sim.state.opportunities["collection_o1"]={"ready":false,"baseline":{},"step":0,"count":0}
    sim.state.follow="collection_o1";await frames(12)
    print("SMOKE follow=",game.get_node("Safe/Layout/Map/FollowTracker/Row/Text/Step").text)
    sim.state.upgrades["map_detail:1"]=3
    for g in sim.campaign.stage().groups:
        for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,v)
    sim.touch();await frames(12)
    game._open("world");await frames(4)
    print("SMOKE world_open=",game.panel=="world")
    game._close()
    sim.state.upgrades["spawn_amount:0"]=2;sim.state.upgrades["gem_chance"]=3;sim.state.upgrades["loot:0"]=4
    sim.state.group_kills[3]=1;sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    print("SMOKE begin=",sim.campaign.begin_prestige())
    var card: String=sim.campaign.offered_cards()[0]
    print("SMOKE prestiged=",sim.prestige(card)," spawn_amount=",sim.level("spawn_amount",0)," gem_chance=",sim.level("gem_chance")," loot=",sim.level("loot",0))
    await frames(4)
    print("SMOKE done")
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(0)
