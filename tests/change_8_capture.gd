extends Node
## Change 8 UI capture (rendered, not headless): HUD with HP text and follow tracker, the equipment
## comparison, Stats and the Inventory panel. Writes PNGs to docs/Change_8_Evidence/ui/.
var sim
var game
const OUT="res://docs/Change_8_Evidence/ui/"
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name: String) -> void:
    await frames(8)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
    sim.add_item("wood_sword",3);sim.add_item("stone_axe",2);sim.add_item("unit-blue-cap_outfit",40);sim.add_item("potion",2)
    sim.merge("unit-blue-cap_outfit",true)
    sim.equip("wood_sword");sim.equip("unit-blue-cap_outfit")
    sim.state.group_kills[0]=5
    sim.state.opportunities["expedition_o1"]={"ready":false,"baseline":{},"step":1,"count":12}
    sim.state.follow="expedition_o1"
    for i in range(40):sim.step(.1)
    for e in sim.state.enemies:
        if sim.position_of(e).distance_to(sim.position_of(sim.state.player))<400:e.hp=float(sim.enemy_definition(int(e.group),int(e.variant)).hp)*.6
    sim.state.player.hp=sim.stats().hp*.7
    sim.touch()
    await shot("01_hud")
    game.selected="stone_axe";game.selected_slot=-1;game._open("item")
    await shot("02_compare")
    game._open("stats")
    await shot("03_stats")
    game._open("inventory")
    await shot("04_inventory")
    game._open("upgrades")
    await shot("05_upgrades")
    game._close()
    sim.milestone.emit("discovered","hunter_o1")
    await frames(20)
    await shot("06_banner")
    get_tree().quit(0)
