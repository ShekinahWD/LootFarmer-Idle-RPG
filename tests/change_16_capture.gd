extends Node
## Change 16 UI capture (rendered, not headless): the Guided opening arrow and the Winter I objective,
## the boss warning, a boss's red name with its skill icon and banner, both trackers with the Map
## Mastery chip, View Camp under a camp's name, a skill's description with Drop All, the red Drop All
## confirmation, the Prestige confirmation screen, Missions with Follow, the collection follower with
## its item, and Settings → Help. Writes PNGs to docs/Change_16_Evidence/ui/. Desktop evidence only,
## not proof of phone layout, colour or speed. Run with --first-run-complete at 540x960.
var sim
var game
const OUT="res://docs/Change_16_Evidence/ui/"
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name: String,settle:=10,keep_banner:=false) -> void:
    if not keep_banner:game.banner.queue.clear();game.banner._finish()
    game.toast_queue.clear();game.get_node("Toast").hide()
    await frames(settle)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func fresh(mode:="none") -> void:
    sim.new_profile();sim.state.tutorial.mode=mode;sim.suspended=false
    sim.state.tutorial.seen.append_array(["overview","aggression","skills","groups","prestige","rest","camp_done"])
    game._close();game.banner.queue.clear();game.banner._finish()
func run() -> void:
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    # The world holds still for the shots (no wandering, chasing or auto-attacks between frames).
    sim.set_physics_process(false)
    SettingsState.set_camera_zoom(2.0)
    # 01 Guided opening: "Follow the path to your left." with its arrow, and the Winter I objective.
    fresh("guided")
    sim.state.tutorial.done.clear()
    await shot("01_guided_path_and_objective",16)
    # 02 The first sight of the Snowman: the red warning.
    fresh()
    var snow: Dictionary={}
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id=="boss-snowman":snow=e
    sim.state.player.x=float(snow.x)-45;sim.state.player.y=float(snow.y)+35
    sim.campaign.reveal_circle(Vector2(snow.x,snow.y),110.0)
    snow.hp=float(sim.enemy_definition(int(snow.group),2).hp)*.7
    game.world.follow_player();game.world.following_player=false
    game.world.camera_position=Vector2(float(snow.x)+35,float(snow.y)-5)
    sim.campaign.reveal()
    await shot("02_boss_found_warning",8,true)
    # 03 A boss with a skill and the World banner: name, skill icon, banner, HP bar.
    sim.state.stage=2;sim.state.unlocked_stage=2;sim._reset_world();await frames(3)
    var robot: Dictionary={}
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id=="boss-cyan-robot":robot=e
    sim.campaign.discover_spot(sim.campaign.group_id("boss-cyan-robot"),2)
    sim.state.player.x=float(robot.x)-25;sim.state.player.y=float(robot.y)+30
    sim.campaign.reveal_circle(Vector2(robot.x,robot.y),110.0)
    robot.hp=float(sim.enemy_definition(int(robot.group),2).hp)*.6
    SettingsState.set_camera_zoom(3.0);game.world.follow_player();game.world.following_player=false
    game.world.camera_position=Vector2(float(robot.x)+25,float(robot.y)-32)
    await shot("03_boss_name_skill_banner",12)
    SettingsState.set_camera_zoom(2.0)
    # 04 Both trackers bottom-right, the Mastery chip above Map Explored.
    fresh()
    for i in range(sim.state.missions.size()):
        if str(sim.state.missions[i].kind)=="kill":sim.campaign.toggle_follow_mission("daily",i);break
    for op in sim.catalog.campaign.opportunities:
        if op.id=="collection_o1":sim.state.opportunities[op.id]={"ready":false,"baseline":{},"step":0,"count":0}
    game.world.follow_player()
    var item: String=sim.campaign.contract_outfit("blue-cap")
    sim.state.online_items[item]=7.0;sim.state.opportunities.collection_o1["item_"+item]=7.0
    sim.campaign.toggle_follow("collection_o1")
    sim.state.mastery.explored["1"]=40
    sim.campaign.reveal_circle(sim.position_of(sim.state.player),220.0)
    game.world.follow_player()
    await shot("04_trackers_and_mastery_chip",16)
    # 05 View Camp under the camp's name (no pop-up on arrival).
    var camp: Array=sim.campaign.stage().spawns[1]
    sim.state.camps_known["1"]=[1]
    sim.state.player.x=float(camp[0])+18;sim.state.player.y=float(camp[1])+10
    sim.campaign.reveal_circle(Vector2(camp[0],camp[1]),160.0)
    game.world.follow_player()
    await shot("05_view_camp",14)
    # 06 A skill's description and Drop All.
    fresh()
    sim.add_item("skill_lightning",4);sim.merge("skill_lightning")
    sim.state.player_level=12;sim.touch()
    game.selected="skill_lightning";game.selected_slot=-1;game._open("item")
    await shot("06_skill_description_drop_all")
    # 07 The Drop All confirmation.
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("guide","")=="drop_all":b.pressed.emit()
    await shot("07_drop_all_confirm")
    game._cancel_confirm();game._close()
    # 08 The Prestige confirmation screen.
    sim.state.bosses_found.append("boss-snowman")
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    sim.state.opportunities["expedition_o1"]={"ready":true,"baseline":{},"step":3,"count":0}
    sim.state.gems=245;sim.state.coins=3480;sim.state.player_level=18
    game._open("prestige");await frames(4)
    game._open_prestige_confirm(sim.campaign.awardable_ids())
    await shot("08_prestige_confirmation",14)
    game.get_node("PrestigeConfirm").close();game._close()
    # 09 Missions with Follow; 10 Settings with Help; 11 Help.
    fresh()
    game._open("missions")
    await shot("09_missions_follow")
    game._close()
    game._open("settings")
    await shot("10_settings_help")
    game._open("help")
    await shot("11_help_basic_tutorial")
    game._close()
    print("CHANGE_16_CAPTURE done")
    get_tree().quit()
