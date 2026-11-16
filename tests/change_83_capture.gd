extends Node
## Change 83 rendered desktop evidence (not Android validation). One real-time playback at normal speed, the
## simulation on its own physics clock, from an older save that had already unsealed and defeated the Green Alien:
## the walk up, the danger panel (Set Recommended Volume, Yes), the full 13-key ceremony replay, the fight with the
## recommended-audio chip, Rage Mode (burst, red barrier, warning), the first victory's 10 s celebration (dancers,
## confetti, fireworks), the ending panel, Continue, a later non-blocking victory with the hero walking across the
## floor. Then stills: Missions (Boss Keys quest with missing keys), Map Mastery (Game Completion breakdown) and the
## World map (final-boss marker).
## Stills at fixed moments plus every frame at 10 fps for a playback video (assembled outside Godot with ffmpeg).
## Run windowed (432x960, 540x960; the monitor clamps taller windows):
##   godot --path . --resolution 432x960 res://tests/change_83_capture.tscn -- --probe --profile=probe-c83cap
##       --no-autosave --first-run-complete --shape=432x960
## Output: generated/evidence/change_83/<shape>/ (ignored by Git).
var game
var sim
var shape:="540x960"
var dir:=""
var frame_index:=0
var record:=false
var record_clock:=0.0

func _ready() -> void:call_deferred("run")
func frames(n:=8) -> void:
    for i in range(n):await get_tree().process_frame
func wait(seconds: float) -> void:
    await get_tree().create_timer(seconds).timeout

func save(name_: String) -> void:
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dir+name_+".png"))
    print("SHOT ",dir+name_+".png")
func shot(name_: String) -> void:
    await frames(3)
    save(name_)

func _process(delta: float) -> void:
    # Fixture: the hero survives the whole presentation run (this evidence is not a balance test).
    if sim!=null and not sim.state.is_empty() and float(sim.state.player.hp)>0:sim.state.player.hp=sim.stats().hp
    if not record:return
    record_clock+=delta
    if record_clock>=.1:
        record_clock-=.1
        get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dir+"seq/f%04d.png" % frame_index))
        frame_index+=1

func alien() -> Dictionary:
    for a in sim.state.enemies:
        if bool(sim.catalog.groups[int(a.group)].final) and not sim.is_helper(a):return a
    return {}
func final_g() -> int:
    for g in range(sim.catalog.groups.size()):
        if bool(sim.catalog.groups[g].final):return g
    return -1

func wait_until(cond: Callable,limit:=20.0) -> void:
    var t:=0.0
    while not cond.call() and t<limit:
        await get_tree().process_frame
        t+=get_process_delta_time()

func clear_notices() -> void:
    game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()

func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
    dir="res://generated/evidence/change_83/%s/" % shape
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir+"seq"))
    SettingsState.mute_all_sfx()
    SettingsState.set_music_volume(.8);SettingsState.set_sfx_volume(.6)
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(10)
    get_tree().paused=false
    sim.new_profile();sim.suspended=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append_array(["road_ahead","final_intro"])
    game._close();clear_notices()
    sim.state.stage=8;sim.state.unlocked_stage=8;sim.state.spawns=[0,1,2];sim.state.camps["8"]=[0,1,2]
    sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II reached
    sim.state.final_discovered=true;sim.state.keys=[];sim.state.bosses_found.append("boss-green-alien") # fixture: met before
    for d in sim.catalog.groups:
        if d.boss and not d.final:sim.state.keys.append(str(d.id)) # fixture: 13 keys
    # fixture: an older (Change 82) profile that unsealed and beat the Green Alien before this update
    sim.state.final_unsealed=true;sim.state.group_kills[final_g()]=2
    sim.state.upgrades["map_detail:8"]=3 # fixture: Map Details on Spring II (markers drawn)
    sim.campaign.discover_spot(final_g(),2)
    sim.state.player_level=500;sim._stats_revision=-1;sim.state.player.hp=sim.stats().hp # fixture: survives a while
    for id in ["obsidian_sword","boss-red-panda_outfit_t5"]:
        if sim.catalog.items.has(id):sim.add_item(id,1,false,false);sim.equip(id) # fixture: an endgame look
    var outfits: Array=sim.campaign.floor_outfits()
    for i in range(0,outfits.size(),2):sim.record(str(outfits[i])).qty=1 # fixture: 24 outfits owned (stored)
    var a:=alien()
    sim.state.player.x=float(a.home_x)-10;sim.state.player.y=float(a.home_y)+150 # fixture: south of it, out of range
    sim.campaign.reveal();sim.touch()
    game.world.follow_player()
    game.elapsed=1.0
    await frames(30)
    clear_notices()
    sim.state.player.hp=sim.stats().hp
    record=true
    # 1. Walk up: the danger panel.
    game.stick_input=Vector2.UP
    await wait_until(func()->bool:return game.final_dialog.is_open(),10.0)
    game.stick_input=Vector2.ZERO
    await wait(.6)
    save("01_danger_panel")
    audit_panel("01_danger_panel")
    game.final_dialog.button("audio").pressed.emit()
    await wait(.5)
    save("02_danger_audio_on")
    game.final_dialog.button("yes").pressed.emit()
    # 2. The full ceremony (replayed for this older save).
    await wait(1.5);save("03_ceremony_orbit")
    await wait_until(func()->bool:return sim.campaign.arena_active(),10.0)
    await wait(2.4)
    clear_notices()
    save("04_fight_arena_normal_chip")
    audit_chip("04_fight_arena_normal_chip")
    # 3. Rage.
    var boss:=alien()
    boss.cooldown=1.0;boss.hp=float(sim.enemy_definition(final_g()).hp)*.19 # fixture: the fight brought it to 19%
    await wait(.35);save("05_rage_burst")
    await wait(1.2);save("06_rage_red_arena_warning")
    await wait(4.5);save("07_rage_red_arena_after_warning")
    # 4. The first victory: 10 s celebration.
    boss=alien();sim.state.player.hp=sim.stats().hp
    boss.hp=0.0;sim._kill(boss) # fixture: the final blow
    for m in [[1.0,"08_celebration_1s"],[3.0,"09_celebration_3s"],[5.5,"10_celebration_5s_all_dancers"],[8.5,"11_celebration_8s"]]:
        await wait_until(func()->bool:return not sim.campaign.celebration_active() or sim.campaign.celebration_time>=float(m[0]),12.0)
        save(str(m[1]))
    audit_floor("10_celebration")
    await wait_until(func()->bool:return game.final_dialog.is_open(),6.0)
    await wait(.6)
    save("12_ending_panel")
    audit_panel("12_ending_panel")
    game.final_dialog.button("continue").pressed.emit()
    await wait(1.0)
    save("13_after_continue_floor")
    # 5. A later victory: non-blocking floor, the hero walks across it.
    sim.state.boss_respawns.clear();alien().respawn=0.0
    await wait(.5)
    sim.state.player.x=float(alien().home_x)+20;sim.state.player.y=float(alien().home_y)+20
    await wait(1.0)
    boss=alien();boss.hp=0.0;sim._kill(boss) # fixture: beaten again
    await wait(1.0)
    game.stick_input=Vector2.LEFT
    await wait(1.2);save("14_repeat_floor_walking")
    game.stick_input=Vector2.ZERO
    await wait(2.0);save("15_repeat_floor")
    record=false
    # 6. Panels.
    sim.state.keys=sim.state.keys.slice(0,7) # fixture: a profile still hunting keys
    sim.state.group_kills[final_g()]=0;sim.state.final_complete=false
    game._open("missions");await frames(10);game._scroll_to_section(tr("FINAL_KEYS_SECTION"));await frames(6)
    save("16_missions_boss_keys")
    game.get_node("Sheet/Margin/Content/Scroll").scroll_vertical+=420;await frames(4)
    save("17_missions_boss_keys_more")
    game._close()
    game._open("mastery");await frames(10)
    save("18_completion_breakdown")
    game._close()
    sim.state.boss_respawns.clear();alien().respawn=0.0;await wait(.5)
    game._open("world");await frames(12)
    save("19_world_map_marker")
    game._close()
    print("FRAMES ",frame_index)
    SettingsState.set_music_volume(1.0);SettingsState.set_sfx_volume(1.0)
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(0)

func audit_panel(name_: String) -> void:
    var problems: Array=[]
    var card: Control=game.final_dialog.card
    var vp: Rect2=get_viewport().get_visible_rect()
    if not vp.encloses(card.get_global_rect()):problems.append("card outside the screen %s" % [card.get_global_rect()])
    for b in game.final_dialog.buttons.find_children("*","Button",true,false):
        if b.size.y<56:problems.append("short button %s" % b.text)
        if not card.get_global_rect().encloses(b.get_global_rect().grow(-1)):problems.append("button outside card %s" % b.text)
    print("AUDIT %s %s card=%s %s" % [shape,name_,card.get_global_rect(),"ok" if problems.is_empty() else "AUDIT_FAIL "+str(problems)])

func audit_chip(name_: String) -> void:
    var problems: Array=[]
    var chip: Control=game.get_node("Safe/Layout/Map/FinalAudio")
    if not chip.visible:problems.append("chip hidden")
    var r: Rect2=chip.get_global_rect()
    for node in [game.stick,game.get_node("Safe/Layout/Skills")]:
        if node.is_visible_in_tree() and node.get_global_rect().intersects(r):problems.append("chip over %s" % node.name)
    var boss_px: Vector2=game.world.get_canvas_transform()*sim.position_of(alien())
    if r.has_point(boss_px):problems.append("chip over the boss")
    print("AUDIT %s %s chip=%s %s" % [shape,name_,r,"ok" if problems.is_empty() else "AUDIT_FAIL "+str(problems)])

func audit_floor(name_: String) -> void:
    var f=game.world.dance_floor
    var problems: Array=[]
    if f==null:problems.append("no floor")
    else:
        if f.dancers.size()!=sim.campaign.owned_floor_outfits().size():problems.append("dancers %d of %d" % [f.dancers.size(),sim.campaign.owned_floor_outfits().size()])
        var xf: Transform2D=game.world.get_canvas_transform()
        var c: Vector2=xf*f.position
        if not get_viewport().get_visible_rect().has_point(c):problems.append("floor off screen")
    print("AUDIT %s %s dancers=%s %s" % [shape,name_,f.dancers.size() if f!=null else -1,"ok" if problems.is_empty() else "AUDIT_FAIL "+str(problems)])
