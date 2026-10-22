extends Node
## Change 13 UI capture (rendered, not headless): the rainy overcast map with the next-stage line and
## a discovered required boss, the same view without the tint, World gate lines, a locked camp price,
## the Auto Evolution card, summoned helpers and the final boss fight. Writes PNGs to
## docs/Change_13_Evidence/ui/. Desktop evidence only, not proof of phone layout, colour or speed.
var sim
var game
const OUT="res://docs/Change_13_Evidence/ui/"
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name: String) -> void:
    await frames(10)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func boss(id: String) -> Dictionary:
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id==id and not sim.is_helper(e):return e
    return {}
func stage(n: int) -> void:
    sim.state.stage=n;sim.state.unlocked_stage=n;sim._reset_world()
func run() -> void:
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
    # Summer II, discovered Elephant (a required gate boss), Map Details 2.
    stage(4)
    var elephant:=boss("boss-elephant")
    sim.state.upgrades["map_detail:4"]=2
    sim.state.player.x=elephant.x+36;sim.state.player.y=elephant.y+14
    sim.campaign.reveal_circle(sim.position_of(sim.state.player),260.0)
    sim.campaign.discover_spot(int(elephant.group),2)
    sim.state.coins=12345.6;sim.state.gems=1999.0
    SettingsState.set_camera_zoom(2.0)
    for i in range(10):sim.step(.1)
    sim.suspended=true
    game.world.follow_player()
    await shot("01_summer2_rain_overcast_gate")
    var tint: Color=game.world.scenery.modulate
    game.world.scenery.modulate=Color.WHITE;game.world.scenery.get_node("Camps").modulate=Color.WHITE
    await shot("02_summer2_without_tint_for_comparison")
    game.world.scenery.modulate=tint
    SettingsState.set_camera_zoom(3.0)
    await shot("03_required_boss_banner")
    sim.suspended=false
    # World panel: one of two gate bosses defeated.
    elephant.hp=0.0;sim._kill(elephant)
    game._open("world")
    await shot("04_world_gate_lines")
    game._close()
    # Locked camp price (Autumn II camps cost thousands of coins).
    stage(6);sim.state.camps_known["6"]=[1,2];sim.state.coins=3000
    game._open("world")
    await shot("05_world_camp_price")
    game._close()
    # Enemy upgrades: Auto Evolution beside Auto-Merge.
    stage(1);sim.state.discovered["0"]=true;sim.state.upgrades["merge_gear:0"]=1;sim.state.gems=2500
    game.group=0;game.enemy_tab=1;game._open("enemy")
    await frames(4)
    for s in game.sheet.find_children("*","ScrollContainer",true,false):s.scroll_vertical=100000
    await shot("06_enemy_auto_evolution")
    game._close()
    # Grim Reaper with its helpers.
    stage(6)
    var reaper:=boss("boss-grim-reaper")
    sim.state.player.x=reaper.x+34;sim.state.player.y=reaper.y+10
    sim.campaign.reveal_circle(sim.position_of(sim.state.player),220.0)
    reaper.aggro=true;reaper.summon_cd=0.0
    for i in range(12):sim.state.player.hp=1e9;sim.campaign.step(.1)
    SettingsState.set_camera_zoom(2.0)
    sim.suspended=true;game.world.follow_player()
    await shot("07_grim_reaper_helpers")
    sim.suspended=false
    # Final boss fight (keys fixture), Spring II rain.
    stage(8)
    var alien:=boss("boss-green-alien")
    sim.state.keys=[];for i in range(13):sim.state.keys.append("key%d" % i)
    sim.state.final_discovered=true
    sim.state.player.x=alien.x+40;sim.state.player.y=alien.y+14
    sim.campaign.reveal_circle(sim.position_of(sim.state.player),220.0)
    alien.aggro=true;alien.summon_cd=0.0;alien.hp=float(sim.enemy_definition(int(alien.group)).hp)*.45
    for i in range(20):sim.state.player.hp=1e9;sim.campaign.step(.1)
    sim.suspended=true;game.world.follow_player()
    await shot("08_final_boss_heal_and_helpers")
    print("CAPTURE done")
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(0)
