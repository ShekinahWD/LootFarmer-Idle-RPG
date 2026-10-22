extends Node
## Change 14 UI capture (rendered, not headless): the top-right map cluster and the joystick on the
## Winter, Summer II (rain), Autumn and Spring maps, Lightning on a normal enemy and a boss, a boss's
## Lightning on the player, Strike and Fire, the enemy Upgrades tab with Research, the Focused Farming
## hint in the panel and on the HUD, and the Missions panel with a ready objective first. Writes PNGs
## to docs/Change_14_Evidence/ui/. Desktop evidence only, not proof of phone layout, colour or speed.
var sim
var game
const OUT="res://docs/Change_14_Evidence/ui/"
func _ready() -> void:call_deferred("run")
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func shot(name: String,settle:=10) -> void:
    # Milestone banners and toasts from the fixtures are not part of what is being shown.
    game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()
    await frames(settle)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func actor(id: String) -> Dictionary:
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id==id and not sim.is_helper(e):return e
    return {}
func stage(n: int) -> void:
    sim.state.stage=n;sim.state.unlocked_stage=n;sim._reset_world()
func hud_on(n: int,near_id: String) -> void:
    sim.suspended=false
    stage(n)
    var e:=actor(near_id)
    sim.state.player.x=e.x+70;sim.state.player.y=e.y+40
    sim.campaign.reveal_circle(sim.position_of(sim.state.player),220.0)
    sim.state.upgrades["map_detail:%d" % n]=2
    for i in range(6):sim.step(.1)
    sim.suspended=true
    game.world.follow_player()
func cast_at(caster: Dictionary,key: String,target: Dictionary) -> void:
    if caster.id=="player":sim.locked_target=target.id
    sim.campaign.apply_skill(caster,key,0.0001 if caster.id=="player" else float(sim.catalog.skills[key].power))
func run() -> void:
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
    sim.state.coins=12345.6;sim.state.gems=1999.0
    SettingsState.set_camera_zoom(2.0)
    # §1 §2 §7: the map cluster and the joystick on light and dark maps.
    hud_on(1,"unit-blue-cap")
    await shot("01_winter_cluster_joystick")
    hud_on(4,"boss-elephant")
    await shot("02_summer2_rain_cluster_joystick")
    hud_on(5,"boss-squirrel")
    await shot("03_autumn_cluster_joystick")
    hud_on(7,"boss-bee")
    await shot("04_spring_cluster_joystick")
    # §5: Lightning on a Yellow Cap and on the 2× Gray Cat; the cat's Lightning on the player.
    hud_on(3,"unit-yellow-cap")
    SettingsState.set_camera_zoom(2.5)
    var cap:=actor("unit-yellow-cap")
    cap.x=sim.state.player.x-40;cap.y=sim.state.player.y+34;cap.hp=1e6
    sim.state.discovered[str(cap.group)]=true
    game.world._process(0)
    cast_at(sim.state.player,"lightning",cap)
    await shot("05_player_lightning_on_enemy",8)
    await frames(30)
    var cat:=actor("boss-gray-cat")
    SettingsState.set_camera_zoom(2.0)
    sim.state.player.x=cat.x+50;sim.state.player.y=cat.y-40;cat.hp=1e7
    sim.campaign.reveal_circle(sim.position_of(sim.state.player),220.0)
    sim.state.discovered[str(cat.group)]=true
    game.world.follow_player();game.world._process(0);await frames(2)
    cast_at(sim.state.player,"lightning",cat)
    await shot("06_player_lightning_on_boss",8)
    await frames(30)
    sim.state.player.hp=1e9
    cast_at(cat,"lightning",sim.state.player)
    await shot("07_boss_lightning_on_player",8)
    await frames(30)
    cast_at(sim.state.player,"strike",cat)
    await shot("08_player_strike_on_boss",6)
    await frames(30)
    cast_at(sim.state.player,"fire",cat)
    await shot("09_player_fire_on_boss",10)
    await frames(30)
    sim.skill_warning.emit(cat.id,"fire",sim.position_of(sim.state.player))
    await shot("10_boss_windup_marker",6)
    SettingsState.set_camera_zoom(2.0)
    # §6: research on the Upgrades tab.
    sim.suspended=false;stage(1)
    var g: int=sim.campaign.stage().groups[0]
    sim.campaign.discover_spot(g,2);sim.state.upgrades["reveal_stats:%d" % g]=1
    game.group=g;game.enemy_variant=2;game.enemy_tab=1;game._open("enemy")
    await frames(6)
    for s in game.sheet.find_children("*","ScrollContainer",true,false):s.scroll_vertical=100000
    await shot("11_enemy_upgrades_research")
    game._close()
    # §8: the Focused Farming hint right after the first purchase, in the panel then on the HUD.
    sim.state.tutorial.mode="basic";sim.state.tutorial.seen.append_array(["overview","aggression","skills","groups","prestige","rest"])
    sim.state.gems=500.0
    game.group=g;game.enemy_tab=1;game._open("enemy");await frames(6)
    sim.buy_upgrade("focus",g);game._refresh_panel()
    await shot("12_focus_hint_panel",20)
    game._close()
    await shot("13_focus_hint_hud",20)
    sim.campaign.focus_hint=-1;sim.state.tutorial.mode="none"
    # §3: a ready main objective is listed first, so its Claim button is there when the badge shows.
    sim.campaign.refresh_missions();sim.state.main_ready["8"]=true
    game._refresh_badges()
    game._open("missions");await frames(4)
    for s in game.sheet.find_children("*","ScrollContainer",true,false):s.scroll_vertical=100000
    await shot("14_missions_ready_objective_first")
    game._close()
    get_tree().quit()
