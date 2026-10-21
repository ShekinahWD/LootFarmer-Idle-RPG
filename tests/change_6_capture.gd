extends Node
## Change 6 rendered evidence and UI timing. Uses only real gameplay calls to reach each state
## (fixture amounts are stated in each step); captures what the player would actually see.
## godot --path . --resolution 720x1280 tests/change_6_capture.tscn -- --probe --profile=capture-change6 --no-autosave [--out=after] [--shots=all|timing]
var game
var sim
var out:="res://docs/Change_6_Evidence/after/"
var timings: Array=[]
var suffix:=""
func _ready() -> void:call_deferred("run")
func arg(key: String,default: String) -> String:
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--"+key+"="):return a.split("=")[1]
    return default
func capture(name_: String,frames:=12) -> void:
    for i in range(frames):await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out+name_+suffix+".png")
func step_sim(seconds: float) -> void:
    for i in range(int(seconds*10)):sim.step(.1)
func walk_to(point: Vector2) -> void:
    for i in range(400):
        var offset: Vector2=point-sim.position_of(sim.state.player)
        if offset.length()<20:break
        sim.movement=offset.normalized();sim.step(.1)
    sim.movement=Vector2.ZERO
    game.world.follow_player()
func timed_open(label: String,which: String) -> void:
    game._close()
    await get_tree().process_frame
    var start:=Time.get_ticks_usec()
    game._open(which)
    var built:=Time.get_ticks_usec()
    await RenderingServer.frame_post_draw
    timings.append("%s build_ms=%.2f first_frame_ms=%.2f nodes=%d" % [label,(built-start)/1000.0,(Time.get_ticks_usec()-start)/1000.0,game.rows.get_child_count()])
func count_nodes(node: Node) -> int:
    var n:=1
    for c in node.get_children():n+=count_nodes(c)
    return n
func run() -> void:
    out="res://docs/Change_6_Evidence/%s/" % arg("out","after")
    suffix=arg("suffix","")
    DirAccess.make_dir_recursive_absolute(out)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false)
    sim.new_profile();game._close()
    var shots:=arg("shots","all")
    if shots in ["all","shots"]:await shots_run()
    if shots in ["all","timing"]:await timing_run()
    if shots in ["all","seasons"]:await seasons_run()
    get_tree().quit()

func shots_run() -> void:
    await capture("00_chooser")
    game.guide.choose("guided")
    await capture("01_lesson_move")
    # Walk toward the nearest (weakest) enemy spot: the kill lesson points at the enemy.
    walk_to(sim.campaign.spot(0,2)+Vector2(0,60))
    await capture("02_lesson_kill")
    # Real fights until a drop exists (bounded), then the collect lesson points at it.
    for i in range(1200):
        sim.step(.1)
        if not sim.state.pickups.is_empty():break
    game.world.follow_player()
    await capture("03_lesson_collect")
    for drop in sim.state.pickups.duplicate():sim.collect(int(drop.uid))
    if sim.state.items.is_empty():sim.add_item("unit-blue-cap_weapon",1)
    await capture("04_lesson_equip_slot")
    var item: String=sim.state.gear[0]
    game.selected=item;game.selected_slot=-1;game._open("item")
    await capture("05_lesson_equip_button")
    sim.equip(item);game._close()
    # Fixture: one duplicate of a second family so the merge lesson and browsing have content.
    sim.add_item("unit-blue-cap_outfit",3);sim.add_item("unit-red-scarf_weapon",2);sim.add_item("potion",4)
    await capture("06_lesson_merge_slot")
    game.selected="unit-red-scarf_weapon";game._open("item")
    await capture("07_item_compare_arrows")
    game._browse(1)
    await capture("08_item_next")
    sim.merge("unit-blue-cap_outfit",true);game._close()
    # Upgrade lesson: earn the price in play (coins fixture tops up only the shortfall).
    sim.state.coins=maxf(sim.state.coins,sim.upgrade_cost("loot",0)+5);sim.touch()
    await capture("09_lesson_upgrade_hud")
    game.group=0;game.enemy_tab=0;game._open("enemy")
    await capture("10_lesson_upgrade_tab")
    game.enemy_tab=1;game._open("enemy")
    await capture("11_lesson_upgrade_buy")
    sim.buy_upgrade("loot",0);game._close()
    await capture("12_lesson_camp_explore")
    # Reveal the second camp by walking there (real discovery), then afford it.
    var camp: Array=sim.campaign.stage().spawns[1]
    walk_to(Vector2(camp[0],camp[1])+Vector2(120,0))
    sim.state.coins=maxf(sim.state.coins,float(sim.campaign.camp_price(1)));sim.touch()
    walk_to(Vector2(sim.campaign.stage().spawns[0][0],sim.campaign.stage().spawns[0][1])+Vector2(0,-40))
    await capture("13_lesson_camp_world_button")
    game._open("world")
    await capture("14_world_panel_camp_unlock",16)
    sim.select_spawn(1)
    await capture("15_world_after_unlock")
    game._close()
    await capture("16_camp_done_intro")
    # Winter contrast: toast and celebration over bright snow.
    sim.state.tutorial.seen.append("camp_done")
    game._event("CAMP_SELECTED_NOTICE")
    await capture("17_toast_on_snow",8)
    sim.add_item("unit-blue-cap_weapon",60);for i in range(55):sim.merge("unit-blue-cap_weapon")
    for i in range(40):sim.campaign.progress("kill","",1)
    sim.campaign.evaluate()
    await capture("18_milestone_banner",6)
    await capture("18b_milestone_banner_late",30)
    game._open("prestige")
    await capture("19_prestige_overview",16)
    # Prestige choice presentation: a fixture batch (gate and readiness set directly here, labelled).
    sim.state.unlocked_stage=3
    for id in ["arsenal_o1","challenge_o1"]:sim.state.opportunities[id]={"ready":true,"baseline":{},"step":0,"count":0}
    sim.campaign.begin_prestige();game._open("prestige")
    await capture("20_prestige_cards",16)
    game.selected_card=sim.campaign.offered_cards()[1];game._refresh_panel(true)
    await capture("21_prestige_card_selected",16)
    sim.state.prestige_batch={};sim.state.unlocked_stage=1;sim.touch();game._close()
    game._open("missions");await capture("22_missions",16)
    game.player_tab=0;game._open("upgrades");await capture("23_upgrades_player",16)
    game.group=0;game.enemy_tab=1;game._open("enemy");await capture("24_enemy_upgrades",16)
    game._open("settings");await capture("25_settings",16)
    game._close()
    # Encounter layout: arrival area at the widest zoom, then the first boss arena.
    sim.new_profile();sim.state.tutorial.mode="none";game._close()
    SettingsState.camera_zoom=1.0;game.world.follow_player()
    await capture("26_opening_layout_wide")
    var boss: Dictionary=sim.state.enemies.filter(func(a):return sim.catalog.groups[a.group].boss)[0]
    sim.campaign.reveal_circle(sim.position_of(boss)+Vector2(0,120),220)
    sim.state.player.x=boss.x;sim.state.player.y=boss.y+130;sim.touch();game.world.follow_player()
    await capture("27_boss_arena_wide")
    SettingsState.camera_zoom=2.0
    # Late-run density: full inventory, large numbers, long upgrade list.
    sim.state.coins=123456789;sim.state.gems=98765;sim.state.player_level=240
    for i in range(6):sim.state.gear.append("")   # fixture: purchased capacity
    for id in ["unit-blue-cap_weapon_t2","unit-wolf-hood_weapon","unit-santa-hat_outfit","unit-space-helmet_weapon","skill_heal"]:sim.add_item(id,250)
    game._open("upgrades");await capture("28_upgrades_large_numbers",16)
    game.selected="unit-blue-cap_weapon_t2";game._open("item");await capture("29_item_high_tier",16)
    game._close()

func timing_run() -> void:
    sim.new_profile();sim.state.tutorial.mode="none";game._close()
    sim.add_item("unit-blue-cap_weapon",4);sim.add_item("unit-blue-cap_outfit",2);sim.add_item("potion",3)
    for i in range(30):sim.add_item("unit-red-scarf_weapon",1)
    sim.state.coins=120;sim.state.gems=12;sim.state.discovered["0"]=true;sim.touch()
    for i in range(10):await get_tree().process_frame   # world and stage scene settle first
    await timed_open("upgrades_cold","upgrades")
    for i in range(5):await timed_open("upgrades_warm_%d" % i,"upgrades")
    var refresh: Array=[]
    for i in range(40):
        sim.touch();var t:=Time.get_ticks_usec();game._refresh_panel();refresh.append((Time.get_ticks_usec()-t)/1000.0)
    refresh.sort();timings.append("upgrades_refresh median_ms=%.2f p95_ms=%.2f max_ms=%.2f" % [refresh[20],refresh[37],refresh[39]])
    var buys: Array=[]
    sim.state.coins=1e9;sim.touch()
    for i in range(20):
        var t:=Time.get_ticks_usec();sim.buy_upgrade("movement");game._refresh_panel();buys.append((Time.get_ticks_usec()-t)/1000.0)
    buys.sort();timings.append("upgrades_buy_refresh median_ms=%.2f p95_ms=%.2f" % [buys[10],buys[18]])
    game.group=0;game.enemy_tab=1
    await timed_open("enemy_upgrades_cold","enemy")
    await timed_open("enemy_upgrades_warm","enemy")
    await timed_open("world","world")
    game.selected="unit-blue-cap_weapon";await timed_open("item","item")
    var browse: Array=[]
    for i in range(20):
        var t:=Time.get_ticks_usec();game._browse(1 if i%2==0 else -1);browse.append((Time.get_ticks_usec()-t)/1000.0)
    browse.sort();timings.append("item_browse median_ms=%.2f p95_ms=%.2f" % [browse[10],browse[18]])
    await timed_open("prestige","prestige")
    # Leak check: repeated open/close must not grow the tree.
    game._close();for i in range(3):await get_tree().process_frame
    var before:=count_nodes(game)
    for i in range(30):
        game._open(["upgrades","world","missions","prestige","item","settings"][i%6]);await get_tree().process_frame
        game._close();await get_tree().process_frame
    for i in range(5):await get_tree().process_frame
    timings.append("open_close_x30 nodes_before=%d nodes_after=%d" % [before,count_nodes(game)])
    # Gameplay frame cost: dense stage-1 world with the real step at 60 Hz.
    sim.new_profile();sim.state.tutorial.mode="none";game._close()
    var frames: Array=[]
    for i in range(240):
        var t:=Time.get_ticks_usec();sim.step(1.0/60.0);await get_tree().process_frame;frames.append((Time.get_ticks_usec()-t)/1000.0)
    frames.sort();timings.append("gameplay_frame median_ms=%.2f p95_ms=%.2f (includes engine frame)" % [frames[120],frames[228]])
    var steps: Array=[]
    for i in range(600):
        var t:=Time.get_ticks_usec();sim.step(1.0/60.0);steps.append((Time.get_ticks_usec()-t)/1000.0)
    steps.sort();timings.append("sim_step median_ms=%.3f p95_ms=%.3f" % [steps[300],steps[570]])
    var f:=FileAccess.open(out+"timings"+suffix+".txt",FileAccess.WRITE);f.store_string("\n".join(timings)+"\n")
    print("\n".join(timings))

## Notification, banner and combat-number contrast on each season's terrain (fixture: stages unlocked).
func seasons_run() -> void:
    for st in [1,3,5,7]:
        sim.new_profile();sim.state.tutorial.mode="none";game._close()
        sim.state.unlocked_stage=st;sim.touch();sim.campaign.camp_action(st,0,true);game.world.follow_player()
        sim.campaign.reveal_circle(sim.position_of(sim.state.player),400)
        var g: int=sim.campaign.stage().groups[0]
        walk_to(sim.campaign.spot(g,2)+Vector2(0,40))
        for i in range(60):sim.step(.1)
        game._toast(tr("CAMP_SELECTED_NOTICE"))
        game._milestone("stage",str(mini(8,st+1)))
        await capture("30_contrast_stage_%d" % st,10)
