extends Node
## Change 6 baseline evidence: rendered states and UI timing on the pre-change code.
## Uses only APIs that existed before Change 6 so it can run on the baseline.
var game
var sim
var out := "res://docs/Change_6_Evidence/before/"
var timings: Array = []
func _ready() -> void:call_deferred("run")
func capture(name_: String) -> void:
    for i in range(10):await get_tree().process_frame
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(out+name_+".png")
func timed_open(label: String, which: String) -> void:
    game._close()
    await get_tree().process_frame
    var start := Time.get_ticks_usec()
    game._open(which)
    var built := Time.get_ticks_usec()
    await RenderingServer.frame_post_draw
    timings.append("%s build_ms=%.2f first_frame_ms=%.2f nodes=%d" % [label,(built-start)/1000.0,(Time.get_ticks_usec()-start)/1000.0,game.rows.get_child_count()])
func run() -> void:
    DirAccess.make_dir_recursive_absolute(out)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false)
    sim.new_profile();game._close()
    game.guide.choose("guided")
    await capture("01_first_lesson")
    # Representative early-run state: some gear, coins, discovered camp.
    sim.add_item("unit-blue-cap_weapon",4);sim.add_item("unit-blue-cap_outfit",2);sim.add_item("potion",3)
    sim.state.coins=120;sim.state.gems=12
    sim.state.tutorial.done=["move","kill","collect","equip","merge","upgrade"]
    sim.campaign.reveal_circle(Vector2(115,528),120);sim.campaign.identify_sites();sim.touch()
    await capture("02_camp_lesson_hud")
    game._open("travel");await capture("03_world_panel_camp_lesson")
    game.selected="unit-blue-cap_weapon";game.selected_slot=-1;game._open("item");await capture("04_item_details")
    game._open("upgrades");await capture("05_upgrades")
    game._close()
    game._event("PRESTIGE_DISCOVERED");await capture("06_toast_on_winter")
    # Prestige choice presentation as shipped.
    sim.state.opportunities["challenge_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    sim.campaign.begin_prestige();game._open("prestige");await capture("07_prestige_choice")
    sim.state.prestige_batch={};sim.touch();game._close()
    # Opening geometry: arrival camp vs first boss.
    sim.campaign.reveal_circle(Vector2(480,700),520);sim.campaign.identify_sites()
    SettingsState.camera_zoom=1.0;game.world.follow_player();sim.touch()
    await capture("08_opening_layout")
    SettingsState.camera_zoom=2.0
    # Timing: cold/warm opening and refresh while open.
    for i in range(30):sim.add_item("unit-red-scarf_weapon",1)
    await timed_open("upgrades_cold","upgrades")
    for i in range(5):await timed_open("upgrades_warm_%d" % i,"upgrades")
    var refresh: Array=[]
    for i in range(20):
        sim.touch();var t:=Time.get_ticks_usec();game._refresh_panel();refresh.append((Time.get_ticks_usec()-t)/1000.0)
    refresh.sort();timings.append("upgrades_refresh median_ms=%.2f p95_ms=%.2f" % [refresh[10],refresh[18]])
    game.group=0;game.enemy_tab=1;sim.state.discovered["0"]=true
    await timed_open("enemy_upgrades","enemy")
    await timed_open("travel","travel")
    await timed_open("item","item")
    var f:=FileAccess.open(out+"timings.txt",FileAccess.WRITE);f.store_string("\n".join(timings)+"\n")
    print("\n".join(timings))
    get_tree().quit()
