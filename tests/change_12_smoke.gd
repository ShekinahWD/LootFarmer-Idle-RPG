extends Node
## Change 12 build-readiness smoke: every new or changed panel and action runs once on the real main
## scene (Settings audio controls, the explored label, Merge All, the Cyan Robot heal, the stone-axe
## swing, Prestige recentring, gem chance). Errors surface as SCRIPT ERROR lines; the focused
## assertions are in change_12_probe.
var sim
var game
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
    sim.rng.seed=1212
    await frames(4)
    print("SMOKE explored=",game.get_node("Safe/Layout/Map/Explored").text)
    game._nav("settings");await frames(3)
    print("SMOKE settings=",game.panel=="settings")
    game._close()
    sim.state.gems=6000
    print("SMOKE buy_merge_all=",sim.buy_upgrade("merge_all"))
    sim.add_item("wood_sword",5);sim.add_item("blue-cap_outfit",4) if sim.catalog.items.has("blue-cap_outfit") else null
    game._nav("filters");await frames(3)
    print("SMOKE merge_all=",sim.merge_all()," idle=",sim.merge_all_copies())
    game._refresh_panel(true);await frames(2);game._close()
    var robot:=-1
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id=="boss-cyan-robot":robot=sim.state.enemies.find(e)
    if robot<0:
        sim.campaign.travel_reason(2,0)
    var boss: Dictionary={"id":"probe_robot","hp":10.0,"group":sim.campaign.group_id("boss-cyan-robot"),"variant":2}
    print("SMOKE heal_ready=",sim.campaign.skill_ready(boss,"heal"))
    sim.state.weapon="";sim.add_item("stone_axe",1);sim.equip("stone_axe");await frames(3)
    print("SMOKE tint=",game.world.views["player"].attack_tint)
    game.world.pan_camera(Vector2(400,400))
    sim.state.upgrades["gem_chance"]=20;sim.state.group_kills[3]=1
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    print("SMOKE begin=",sim.campaign.begin_prestige())
    var card: String=sim.campaign.offered_cards()[0]
    print("SMOKE prestiged=",sim.prestige(card)," following=",game.world.following_player," merge_all=",sim.level("merge_all")," gem_chance=",sim.gem_base_chance())
    await frames(4)
    print("SMOKE done")
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(0)
