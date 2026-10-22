extends Node
## Change 11 UI capture (rendered, not headless): HUD with the larger minimap and the Filters
## shortcut, the collection follower, Filters open, a supply panel, the Teleport picker and the
## World map on Summer II. Writes PNGs to docs/Change_11_Evidence/ui/.
var sim
var game
const OUT="res://docs/Change_11_Evidence/ui/"
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name: String) -> void:
    await frames(10)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
    sim.state.gems=1e6
    for i in range(6):sim.buy_upgrade("gear_slots")
    for i in range(4):sim.buy_upgrade("supply_slots")
    sim.state.gems=40
    sim.add_item("unit-blue-cap_outfit",3);sim.add_item("wood_sword",4);sim.add_item("unit-red-scarf_outfit",2)
    sim.equip("unit-blue-cap_outfit");sim.equip("wood_sword")
    sim.add_item("potion",31);sim.add_item("coin_boost",6);sim.add_item("guard_tonic",27);sim.add_item("recovery_salve",2);sim.add_item("wisdom_tonic",1)
    sim.state.upgrades["map_detail:1"]=3
    for g in sim.campaign.stage().groups:
        for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,v)
    sim.state.opportunities["collection_o1"]={"ready":false,"baseline":{},"step":0,"count":0}
    var item: String=sim.campaign.contract_outfit("blue-cap")
    sim.state.online_items[item]=20.0;sim.state.opportunities.collection_o1["item_"+item]=20.0
    item=sim.campaign.contract_outfit("red-scarf")
    sim.state.online_items[item]=7.0;sim.state.opportunities.collection_o1["item_"+item]=7.0
    sim.campaign.toggle_follow("collection_o1")
    sim.state.player.hp=sim.stats().hp*.6;sim.use_item("guard_tonic")
    for i in range(30):sim.step(.1)
    sim.touch()
    await shot("01_hud_minimap_filters_follower")
    game._nav("filters");game.inventory_filter=2;game.slot_signatures.clear();game._refresh_slots();game._refresh_panel(true)
    await shot("02_filters_open_outfits")
    game._close()
    await shot("03_after_close_all_items")
    game.selected="guard_tonic";game.selected_slot=-1;game._open("item")
    await shot("04_supply_panel")
    sim.state.camps["1"]=[0,1];sim.state.spawns=sim.state.camps["1"];sim.state.camps_known["1"]=[0,1];sim.state.unlocked_stage=2;sim.state.camps["2"]=[0]
    var a: Array=sim.campaign.stage().spawns[0];sim.state.player.x=a[0];sim.state.player.y=a[1]
    game._settle_camp();game.selected_camp=0;game._open("camp")
    await shot("05_camp_menu_teleport")
    game._open("teleport");game.teleport_target=[2,0];game._refresh_panel(true)
    await shot("06_teleport_picker")
    game._close()
    sim.state.unlocked_stage=4;sim.state.camps["4"]=[0];sim.campaign.camp_action(4,0,true);game._settle_camp()
    sim.state.upgrades["map_detail:4"]=3
    for g in sim.campaign.stage().groups:
        for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,v)
    sim.touch()
    await shot("07_summer2_minimap")
    game._open("world")
    await shot("08_summer2_world_map")
    get_tree().quit(0)
