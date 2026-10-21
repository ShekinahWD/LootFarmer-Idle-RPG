extends Node
var game
var sim
func _ready() -> void:call_deferred("run")
func capture(name_: String) -> void:
    for i in range(12):await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png("res://docs/Change_5_Evidence/"+name_+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute("res://docs/Change_5_Evidence")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false)
    sim.new_profile();game._close()
    await capture("onboarding")
    game.guide.choose("guided")
    await capture("first_lesson")
    game.guide.choose("none")
    sim.add_item("unit-blue-cap_weapon",3);sim.equip("unit-blue-cap_weapon");sim.add_item("potion",3);sim.state.missions[0].progress=sim.state.missions[0].goal*.4;sim.state.coins=100;sim.state.gems=50;sim.state.discovered['0']=true;sim.touch()
    game._open("missions");await capture("missions")
    game.group=0;game.enemy_tab=1;game._open("enemy");await capture("enemy_upgrades")
    game.enemy_tab=2;game._open("enemy");await capture("achievements")
    game._close()
    var boss=sim.state.enemies.filter(func(a):return sim.catalog.groups[a.group].boss)[0]
    sim.state.player.x=boss.x;sim.state.player.y=boss.y+45;sim.campaign.reveal();sim.touch();game.world.follow_player()
    await capture("boss_arena")
    game._open("map");await capture("map")
    game.selected="potion";game._open("item");await capture("potion")
    get_tree().quit()
