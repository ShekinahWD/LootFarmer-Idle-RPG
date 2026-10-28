extends SceneTree
## Change 24 (TEST-04): non-gating desktop performance benchmark. It promotes the 2026-10-28 audit
## harness (Playbook 48.1): the real main scene, an isolated probe profile, scenario fixtures built
## in code (no prepared save), V-Sync off, one run per scenario. It reports frame-interval
## percentiles, stalls, save time and size, inventory refresh cost, simulation step cost, node and
## object counts and static memory. It asserts nothing and is not part of tools/run_probes.py.
## Desktop numbers rank hotspots; they are not Android measurements.
## Run: python tools/run_benchmark.py   (windowed 540x960; writes tests/tmp/benchmark/)
var game
var sim
var out: Array=[]
var report_path:="res://tests/tmp/benchmark/report.txt"
var progress_at:=0

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):report_path=argument.trim_prefix("--out=")
	run()

## Watchdog: a script error stops the coroutine silently (Playbook 127.5); quit if no progress for 30 s.
func _process(_dt: float) -> bool:
	if progress_at==0:progress_at=Time.get_ticks_msec()
	if Time.get_ticks_msec()-progress_at>30000:
		emit("BENCHMARK_ERROR watchdog: no progress for 30 s");_write();quit(2)
	return false

func tick() -> void:
	progress_at=Time.get_ticks_msec()

func emit(line: String) -> void:
	print(line);out.append(line)

func frames(n: int) -> void:
	for i in range(n):
		await process_frame
		tick()

func pct(sorted: Array,p: float) -> float:
	if sorted.is_empty():return 0.0
	return float(sorted[mini(sorted.size()-1,int(floor(p*(sorted.size()-1))))])

func measure(label: String,count: int,each: Callable=Callable()) -> void:
	var dts: Array=[];var draws: Array=[]
	var last:=Time.get_ticks_usec()
	for i in range(count):
		if each.is_valid():each.call(i)
		await process_frame
		tick()
		var now:=Time.get_ticks_usec()
		dts.append((now-last)/1000.0);last=now
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var s:=dts.duplicate();s.sort()
	var mean:=0.0
	for v in dts:mean+=v
	mean/=dts.size()
	var dmean:=0.0
	for v in draws:dmean+=v
	dmean/=draws.size()
	var over50:=dts.filter(func(v):return v>50.0).size()
	emit("PERF %-34s frames=%d frame_ms mean=%.2f p50=%.2f p95=%.2f p99=%.2f max=%.2f over50ms=%d | draw_calls mean=%.0f max=%.0f | nodes=%d objects=%d static_mb=%.1f enemies=%d" % [label,count,mean,pct(s,.5),pct(s,.95),pct(s,.99),s.back(),over50,dmean,draws.max(),Performance.get_monitor(Performance.OBJECT_NODE_COUNT),Performance.get_monitor(Performance.OBJECT_COUNT),Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,sim.state.enemies.size()])

## The audit's late-game fixture: 70 gear identities, 6 supplies, level 240, Emerald Sword, three
## skills on automatic, everything revealed, Guided not chosen.
func setup_profile(full_inventory: bool) -> void:
	sim.new_profile();sim.suspended=false
	game.guide.choose("none")
	sim.state.tutorial.mode="none";sim.state.tutorial.seen.append("road_ahead")
	sim.campaign.onboarding.reveal_all(true)
	sim.state.coins=1e9;sim.state.gems=1e7
	if full_inventory:
		sim.state.upgrades.gear_slots=67
		sim.state.gear.resize(sim.equipment_slot_count());sim.state.gear.fill("")
		var added:=0
		for id in sim.catalog.items:
			var kind:=str(sim.catalog.items[id].kind)
			if kind in ["weapon","outfit","skill"] and not sim.catalog.items[id].get("legacy",false) and added<sim.state.gear.size():
				if sim.add_item(id,40,false,false):added+=1
		sim.state.upgrades.supply_slots=5;sim.state.supplies.resize(6);sim.state.supplies.fill("")
		for id in sim.supply_ids():sim.add_item(id,20,false,false)
		sim.state.player_level=240
		sim.equip("emerald_sword")
		sim.state.upgrades.skill_slots=2;sim.state.upgrades.skill_auto_slots=3
		var i:=0
		for skill in ["skill_lightning","skill_fire","skill_heal"]:
			if sim.state.items.has(skill):sim.campaign.equip_skill(skill,i);i+=1
		sim.assign_automatic_skills([0,1,2])
	sim.touch()

## A map at maximum spawn upgrades, fully explored on request, focus-farming its strongest normal type.
func go(st: int,explored: bool,spawn_max: bool) -> void:
	sim.state.unlocked_stage=8;sim.state.stage=st;sim.state.spawn=0
	if spawn_max:
		for g in sim.campaign.stage().groups:
			if not sim.catalog.groups[g].boss:
				sim.state.upgrades["spawn_amount:%d" % g]=3;sim.state.upgrades["spawn_cooldown:%d" % g]=5
	sim._reset_world()
	if explored:sim.campaign.explore_cells(st,[],true)
	sim.campaign.reveal()
	var best:=-1
	for g in sim.campaign.stage().groups:
		if not sim.catalog.groups[g].boss:best=g
	if explored and best>=0:
		sim.state.focus=best;sim.state.focus_variant=2
	sim.touch()
	game.world.follow_player()

func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	root.get_node("SettingsState").mute_all_sfx()
	var info:=Engine.get_version_info()
	emit("ENV godot=%s renderer=%s adapter=%s window=%s physics_hz=%d os=%s cpu=%s cores=%d build=%s" % [info.string,RenderingServer.get_current_rendering_method(),RenderingServer.get_video_adapter_name(),DisplayServer.window_get_size(),Engine.physics_ticks_per_second,OS.get_name(),OS.get_processor_name(),OS.get_processor_count(),"debug" if OS.is_debug_build() else "release"])
	emit("BUILD version=%s" % ProjectSettings.get_setting("application/config/version"))
	var t0:=Time.get_ticks_usec()
	var scene=load("res://scenes/game/main.tscn")
	var t1:=Time.get_ticks_usec()
	game=scene.instantiate();root.add_child(game)
	var t2:=Time.get_ticks_usec()
	await frames(2)
	var t3:=Time.get_ticks_usec()
	sim=game.sim
	if sim==null:
		emit("BENCHMARK_ERROR sim not ready");_write();quit(1);return
	emit("STARTUP load_ms=%.1f instantiate_ready_ms=%.1f first_2_frames_ms=%.1f static_mb=%.1f" % [(t1-t0)/1000.0,(t2-t1)/1000.0,(t3-t2)/1000.0,Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0])
	# 1. Baselines
	setup_profile(false);go(1,false,false);await frames(120)
	await measure("winter1_fresh_idle",600)
	setup_profile(true);go(1,true,true);await frames(180)
	await measure("winter1_full_inventory_farming",900)
	# 2. Rain stress
	go(4,true,true);await frames(180)
	await measure("summer2_rain_full_farming",900)
	go(8,true,true);await frames(180)
	await measure("spring2_rain_full_farming",900)
	# 3. Spring II with fog: walking into unexplored ground (reveal, fog and minimap updates)
	sim.state.explored.erase("8");sim.campaign.discovery_revision+=1;sim.state.focus=-1
	sim.state.player.x=200;sim.state.player.y=1056;game.world.follow_player();await frames(60)
	await measure("spring2_rain_unexplored_walk_east",600,func(i: int)->void:game.stick_input=Vector2(1,0) if (i/150)%2==0 else Vector2(0,1 if (i/300)%2==0 else -1))
	game.stick_input=Vector2.ZERO
	# 4. Spring II, standing in fog (no reveal) for comparison
	await frames(60)
	await measure("spring2_rain_standing_in_fog",600)
	# 5. Repeated panel open/close
	go(8,true,true);await frames(120)
	var nodes_before:=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var objects_before:=Performance.get_monitor(Performance.OBJECT_COUNT)
	var pages:=["upgrades","prestige","missions","filters","mastery","world","settings","stats"]
	await measure("spring2_panel_open_close_every_15f",960,func(i: int)->void:
		if i%15==0:
			var page: String=pages[(i/15)%pages.size()]
			if i%30==0:game._open(page)
			else:game._close())
	game._close();await frames(120)
	emit("LEAK_CHECK panels nodes_before=%d nodes_after=%d objects_before=%d objects_after=%d (one closed panel is retained by design)" % [nodes_before,Performance.get_monitor(Performance.OBJECT_NODE_COUNT),objects_before,Performance.get_monitor(Performance.OBJECT_COUNT)])
	# 5b. Reopening the same panel (the common pattern the retained controls serve)
	await measure("spring2_same_panel_reopen_every_15f",480,func(i: int)->void:
		if i%15==0:
			if i%30==0:game._open("upgrades")
			else:game._close())
	game._close()
	# 6. Panels held open while farming
	game.player_tab=0;game._open("upgrades");await frames(60)
	await measure("spring2_upgrades_panel_open_farming",600)
	game._close()
	game._open("prestige");await frames(60)
	await measure("spring2_prestige_panel_open_farming",600)
	game._close()
	# 7. Stage switching worst frames
	nodes_before=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var memory_before:=Performance.get_monitor(Performance.MEMORY_STATIC)
	await measure("stage_switch_every_40f",320,func(i: int)->void:
		if i%40==0:go(1+(i/40)%8,true,false))
	await frames(120)
	emit("LEAK_CHECK stage_switch nodes_before=%d nodes_after=%d static_mb_before=%.1f static_mb_after=%.1f" % [nodes_before,Performance.get_monitor(Performance.OBJECT_NODE_COUNT),memory_before/1048576.0,Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0])
	# 7b. Individual switch stalls: the state change plus the frame that applies it, every map once
	var stalls: Array=[]
	for st in [2,3,4,5,6,7,8,1]:
		var a:=Time.get_ticks_usec()
		go(st,true,false)
		await process_frame;tick()
		stalls.append("%d:%.1f" % [st,(Time.get_ticks_usec()-a)/1000.0])
		await frames(30)
	emit("STAGE_SWITCH frame_ms %s" % " ".join(stalls))
	# 8. Save micro-benchmark with the late-game state (all eight maps explored)
	go(8,true,true)
	for st in range(1,9):sim.campaign.explore_cells(st,[],true)
	await frames(60)
	var save=root.get_node("SaveService")
	var times: Array=[];var stringify: Array=[]
	for i in range(11):
		var a:=Time.get_ticks_usec();save.save_now();times.append((Time.get_ticks_usec()-a)/1000.0)
		var b:=Time.get_ticks_usec();JSON.stringify(sim.save_snapshot());stringify.append((Time.get_ticks_usec()-b)/1000.0)
	times.sort();stringify.sort()
	var size:=FileAccess.get_file_as_bytes(save.save_path()).size()
	var cells:=0
	for st in range(1,9):cells+=sim.campaign.explored_count(st)
	emit("SAVE save_now_ms p50=%.2f max=%.2f | save_snapshot_stringify_ms p50=%.2f | file_bytes=%d explored_cells_total=%d" % [times[5],times.back(),stringify[5],size,cells])
	# 9. HUD inventory refresh cost (70 slots): forced full layout vs unchanged state
	var r: Array=[]
	for i in range(30):
		game.slot_signatures.clear();game.inventory_layout_key=""
		var a:=Time.get_ticks_usec();game._refresh_slots();r.append((Time.get_ticks_usec()-a)/1000.0)
	var r2: Array=[]
	for i in range(30):
		sim.touch()
		var a:=Time.get_ticks_usec();game._refresh_slots();r2.append((Time.get_ticks_usec()-a)/1000.0)
	r.sort();r2.sort()
	emit("HUD _refresh_slots_ms forced_full p50=%.2f max=%.2f | unchanged_signatures p50=%.2f max=%.2f | gear_slots=%d" % [r[15],r.back(),r2[15],r2.back(),sim.state.gear.size()])
	# 10. Simulation-only step cost on Spring II (no rendering)
	var steps: Array=[]
	for i in range(300):
		var a:=Time.get_ticks_usec();sim.step(1.0/60.0);steps.append((Time.get_ticks_usec()-a)/1000.0)
	steps.sort()
	emit("SIM step_ms spring2 p50=%.3f p95=%.3f max=%.3f enemies=%d" % [steps[150],steps[285],steps.back(),sim.state.enemies.size()])
	emit("BENCHMARK done")
	_write()
	quit()

func _write() -> void:
	var path:=report_path if report_path.is_absolute_path() or report_path.begins_with("res://") or report_path.begins_with("user://") else ProjectSettings.globalize_path("res://").path_join(report_path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file:file.store_string("\n".join(out)+"\n")
