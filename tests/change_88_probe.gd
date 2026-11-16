extends Node
## Change 88 focused checks (real main scene and simulation; state set directly is labelled "fixture"). No combat
## ladders, balance sweeps or player profiles.
## 1. Green Alien HP: every fresh encounter starts at 100% of the current maximum (fresh spawn, right after the
##    player's death, the next approach, after the ceremony and arena closing, an idle older save) while a save made
##    mid-fight keeps its real damage; no hit lands during the locked ceremony; the HP bar shows the true HP.
##    Each scenario prints "HP_PCT <scenario> <percent>" so the same probe run on an older build shows the before.
## 2. Living victory spectacle: during the 10 s celebration and the ending panel the hero dances (not a frozen
##    swing), the floor and its effects keep running, the main music plays (never held), nothing dims the map,
##    the panel sits over the inventory with the floor above it, the camera frames floor + hero, the Green Alien's
##    respawn countdown is paused and hidden, controls are held; review/Discord keep the panel; Continue restores
##    the camera state, control, the countdown (from the remaining time) and the hero's own animation; an
##    unacknowledged ending stays owed after a reload; later victories stay non-blocking.
## Windowed (--shape=432x960 or 540x960) it also saves stills and a normal-speed playback sequence to
## generated/evidence/change_88/<shape>/ (ignored by Git).
## Run: Godot --headless --path . res://tests/change_88_probe.tscn -- --probe --profile=probe-c88 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim
var windowed:=false
var shape:="540x960"
var dir:=""
var victories: Array=[]
var record:=false
var record_clock:=0.0
var frame_index:=0
var keep_hero:=false

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func _process(delta: float) -> void:
    # Fixture (capture only): the hero survives the real-time run (this evidence is not a balance test).
    if keep_hero and sim!=null and not sim.state.is_empty() and float(sim.state.player.hp)>0:sim.state.player.hp=sim.stats().hp
    if not record:return
    record_clock+=delta
    if record_clock>=.1:
        record_clock-=.1
        get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dir+"seq/f%04d.png" % frame_index))
        frame_index+=1

func run() -> void:
    get_tree().create_timer(400.0,true,false,true).timeout.connect(func():push_error("CHANGE_88 watchdog");get_tree().quit(2))
    windowed=DisplayServer.get_name()!="headless"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
    dir="res://generated/evidence/change_88/%s/" % shape
    if windowed:DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir+"seq"))
    TranslationServer.set_locale("en")
    var dims:=shape.split("x")
    get_window().size=Vector2i(int(dims[0]),int(dims[1]))
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.final_victory.connect(func(kind: String)->void:victories.append(kind))
    await frames(6)
    await hp_checks()
    await spectacle_checks()
    if windowed:await playback()
    print("CHANGE_88_CHECKS %d FAILURES %d" % [checks,failures])
    SettingsState.restore_recommended()
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- fixtures (as in the Change 83-86 probes)
func fresh() -> void:
    get_tree().paused=false
    if game.final_dialog.is_open():game.final_dialog.close()
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    sim.state.tutorial.seen.append("final_intro")
    clear_notices()
    SettingsState.restore_recommended()
    victories.clear()
func clear_notices() -> void:
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_important.clear();game.get_node("Toast").hide();game.toast_time=0.0
func spring_two() -> void:
    sim.state.stage=8;sim.state.unlocked_stage=8;sim.state.spawns=[0,1,2];sim.state.camps["8"]=[0,1,2]
    sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II reached, its camps owned
func alien() -> Dictionary:
    for a in sim.state.enemies:
        if bool(sim.catalog.groups[int(a.group)].final) and not sim.is_helper(a):return a
    return {}
func final_g() -> int:
    for g in range(sim.catalog.groups.size()):
        if bool(sim.catalog.groups[g].final):return g
    return -1
func keys() -> void:
    sim.state.final_discovered=true
    sim.state.keys=[]
    for d in sim.catalog.groups:
        if d.boss and not d.final:sim.state.keys.append(str(d.id))
    if not sim.state.bosses_found.has("boss-green-alien"):sim.state.bosses_found.append("boss-green-alien")
func introduced() -> void:
    keys()
    sim.state.final_unsealed=true;sim.state.final_warning_ok=true;sim.state.final_experience=true
func sturdy() -> void:
    sim.state.player_level=500;sim._stats_revision=-1;sim.state.player.hp=sim.stats().hp
func place(offset: Vector2) -> void:
    var a:=alien()
    sim.state.player.x=float(a.home_x)+offset.x;sim.state.player.y=float(a.home_y)+offset.y
    sim.campaign.reveal()
func steps(seconds: float,dt:=.05) -> void:
    var t:=0.0
    while t<seconds-1e-6:
        sim.step(dt);t+=dt
func calm_boss() -> void:
    var a:=alien();a.cooldown=99.0;a.skill_timer=99.0;a.summon_cd=99.0 # fixture: the boss holds its attacks
func hold_hero() -> void:
    sim.state.player.cooldown=99.0;sim.state.player.target="";sim.clear_target() # fixture: the hero holds its attacks
func engaged() -> Dictionary:
    fresh();spring_two();sturdy();introduced()
    place(Vector2(30,0));steps(.1)
    return alien()
func maxhp() -> float:return float(sim.enemy_definition(final_g()).hp)
func pct(a: Dictionary=alien()) -> float:return 100.0*float(a.hp)/maxhp()
func report(scenario: String,value: float) -> void:
    print("HP_PCT %s %.1f" % [scenario,value])
func real_wait(seconds: float) -> void:
    var t0:=Time.get_ticks_msec()
    while Time.get_ticks_msec()-t0<seconds*1000.0:await get_tree().process_frame
func defeat() -> void:
    var a:=alien()
    a.hp=0.0;sim._kill(a)
func boss_kills_player(attacker: Dictionary) -> void:
    var p: Dictionary=sim.state.player
    p.hp=1.0;p.x=float(attacker.x)+10;p.y=float(attacker.y)
    attacker.target="player";attacker.windup=.0001
    sim._resolve_attack(attacker,.05)

# ================================================================ 1. Green Alien HP
func hp_checks() -> void:
    print("-- Green Alien HP")
    # Fresh spawn.
    fresh();spring_two();introduced()
    report("fresh_spawn",pct())
    check(is_equal_approx(pct(),100.0),"Fresh spawn: 100%")
    # Player death mid-fight: the boss at 40% (fixture: the fight's damage) kills the hero.
    var a:=engaged();calm_boss()
    a.hp=maxhp()*.4;a.cooldown=0.0
    boss_kills_player(a)
    report("right_after_player_death",pct())
    check(float(sim.state.player.hp)<=0 and is_equal_approx(pct(),100.0),"Right after the player's death: 100% at once (no regeneration wait)")
    check(not a.has("rage") and str(a.get("pending",""))=="" and not bool(a.get("telegraph",false)),"…encounter state reset with Rage (skills, telegraph)")
    # Next approach: the hero respawns, then (fixture) returns at once from a nearby camp.
    var t:=0.0
    while float(sim.state.player.hp)<=0 and t<30.0:steps(.05);t+=.05
    hold_hero();calm_boss()
    place(Vector2(30,0))
    var at_aggro:=-1.0
    for i in range(40):
        steps(.05)
        if bool(alien().aggro) and at_aggro<0:at_aggro=pct()
    report("next_approach",at_aggro)
    check(is_equal_approx(at_aggro,100.0),"Next approach after respawn: the fight starts at 100%")
    # Ceremony and arena: an older save with a stale absolute HP (fixture: 80% of today's maximum) that still owes
    # the Change 83 ceremony; no damage while it is locked.
    fresh();spring_two();sturdy();keys()
    sim.state.final_unsealed=true;sim.state.final_warning_ok=true # fixture: warning accepted, ceremony not replayed
    alien().hp=maxhp()*.8
    report("stale_before_ceremony",pct())
    place(Vector2(30,0));hold_hero();calm_boss()
    steps(.1)
    check(sim.campaign.ceremony_active(),"Approach starts the ceremony")
    var lowest:=INF
    var guard:=0
    while sim.campaign.ceremony_active() and guard<400:
        sim.state.player.cooldown=0.0 # the hero would swing at once if the world allowed it
        steps(.05);guard+=1;lowest=minf(lowest,pct())
    report("during_ceremony_min",lowest)
    check(lowest>=99.999,"No hit and no stale HP during the locked ceremony (lowest %.1f%%)" % lowest)
    hold_hero()
    var t2:=0.0
    while not sim.campaign.arena_active() and t2<2.0:steps(.05);t2+=.05
    report("after_ceremony_arena",pct())
    check(sim.campaign.arena_active() and is_equal_approx(pct(),100.0),"Arena closed after the ceremony: 100% before the first hit")
    # Save/load: an idle Green Alien with an older absolute HP versus a save made mid-fight.
    fresh();spring_two();introduced()
    alien().hp=maxhp()*.8;alien().aggro=false # fixture: an older save, boss idle at an old absolute HP
    var snap: Dictionary=sim.snapshot()
    sim.restore(snap);sim.set_physics_process(false);await frames(2)
    report("load_idle_old_save",pct())
    check(is_equal_approx(pct(),100.0),"Load: an idle Green Alien with an older absolute HP is whole")
    fresh();spring_two();introduced()
    alien().hp=maxhp()*1.3 # fixture: an absolute HP above today's maximum
    sim.restore(sim.snapshot());sim.set_physics_process(false)
    check(is_equal_approx(pct(),100.0),"Load: HP above the current maximum is capped")
    a=engaged();calm_boss();hold_hero()
    a.hp=maxhp()*.55;a.quiet=0.0 # fixture: the fight's real damage
    sim.restore(sim.snapshot());sim.set_physics_process(false);await frames(2)
    report("load_active_fight",pct())
    check(is_equal_approx(pct(),55.0),"Load mid-fight: the real damage is kept (55%)")
    # Other map: the fight ended when the player left; a return finds it whole.
    fresh();spring_two();introduced()
    sim.state.camps["7"]=[0] # fixture: a Spring I camp owned
    a=alien();a.hp=maxhp()*.5;a.returning=true # fixture: hurt, walking home after the player broke off
    check(sim.campaign.camp_action(7,0,true) and sim.campaign.camp_action(8,0,true),"Teleport away and back")
    report("map_return",pct())
    check(is_equal_approx(pct(),100.0),"Leaving the map and returning: 100%")
    # HP bar: the bar follows the true HP and the boss's current maximum.
    a=engaged();calm_boss();hold_hero()
    a.hp=maxhp()*.8;await frames(3)
    var view=game.world.views.get(str(a.id))
    check(view!=null and is_equal_approx(view.max_hp,maxhp()) and is_equal_approx(view._hp.value,80.0) and view._hp.visible,"HP bar: max = current maximum, shows 80% when it is 80%")
    a.hp=maxhp();await frames(2)
    check(view!=null and not view._hp.visible,"HP bar hidden at 100% (no stale bar)")

# ================================================================ 2. Living victory spectacle
func map_rect() -> Rect2:return game.get_node("Safe/Layout/Map").get_global_rect()
## The floor's centre on screen (the world draws in the map's SubViewport).
func floor_screen() -> Vector2:
    var floor_=game.world.dance_floor
    var vp: Viewport=floor_.get_viewport()
    var at: Vector2=floor_.get_global_transform_with_canvas().origin
    var container: Control=vp.get_parent() as Control
    var r: Rect2=container.get_global_rect()
    return r.position+at*r.size/Vector2(vp.size)
func body_frame() -> Rect2:return game.world.views["player"]._body.region_rect

func spectacle_checks() -> void:
    print("-- Living victory spectacle")
    var a:=engaged();calm_boss();hold_hero()
    var outfits: Array=sim.campaign.floor_outfits()
    for i in range(0,outfits.size(),2):sim.record(str(outfits[i])).qty=1 # fixture: 24 outfits owned
    SettingsState.set_music_volume(.8)
    # Camera state the player had before (a pan away from the hero).
    game.world.following_player=false
    var cam_before: Vector2=sim.position_of(sim.state.player)+Vector2(40,-25)
    game.world.camera_position=cam_before
    var zoom_before: float=SettingsState.camera_zoom
    # The hero mid-swing at the killing blow.
    sim.state.player.attack_age=.05
    defeat();await frames(2)
    check(victories==["first"] and sim.campaign.celebration_active(),"First victory: the celebration starts")
    var id: String=str(a.id)
    var respawn: float=float(sim.state.boss_respawns[id].remaining)
    await real_wait(1.0)
    var hero=game.world.views["player"]
    check(hero.dancing and not hero._attack.visible,"Celebration: the hero dances (no frozen swing)")
    var frames_seen: Dictionary={}
    var pos_seen: Dictionary={}
    for i in range(30):
        await get_tree().process_frame
        frames_seen[body_frame()]=true;pos_seen[snappedf(hero._visual.position.y,.5)]=true
    check(frames_seen.size()>=3 and pos_seen.size()>=2,"…its frames and hop change every frame (%d frames, %d heights)" % [frames_seen.size(),pos_seen.size()])
    var floor_=game.world.dance_floor
    var t0: float=floor_.time
    await real_wait(.5)
    check(floor_.time>t0+.3 and floor_.confetti.emitting,"…the floor, dancers and confetti run")
    check(AudioService.boss_music()==null and not bool(AudioService.music_state().held),"…main music, not held")
    check(game.world.boss_labels.is_empty(),"…the Green Alien countdown is hidden")
    check(not sim.campaign.arena_active(),"…the arena is open")
    var corpse=game.world.views.get(id)
    check(corpse==null or not corpse.visible,"…the Green Alien's fall finishes and fades (no frozen corpse on the floor)")
    # The forced celebration's remaining seconds (stepped; presentation still on real frames).
    steps(10.2);await frames(4)
    check(game.final_dialog.is_open() and game.final_dialog.kind=="ending" and sim.campaign.ending_showing,"At 10 s: the ending panel")
    await real_wait(.8)
    check(game.final_dialog.dim.color.a<=0.0,"Ending panel: nothing dims or blurs the map")
    var card: Rect2=game.final_dialog.card.get_global_rect()
    var map: Rect2=map_rect()
    var vh: float=get_viewport().get_visible_rect().size.y
    check(card.get_center().y>map.end.y-card.size.y*.25 and card.end.y<=vh+.5,"…the card sits over the inventory / lower HUD (card %s, map bottom %.0f)" % [card,map.end.y])
    var fs:=floor_screen()
    check(fs.y<card.position.y-40.0 and fs.y>map.position.y and fs.x>map.position.x and fs.x<map.end.x,"…the dance floor centre is on screen above the card (%s)" % fs)
    check(game.world.cine_weight>=1.0 and game.world.spectacle_bottom<1.0,"…the camera frames the floor above the card")
    check(hero.dancing and game.world.dance_floor!=null,"…the hero keeps dancing")
    t0=floor_.time
    var f0:=body_frame()
    var changed:=false
    for i in range(20):
        await get_tree().process_frame
        if body_frame()!=f0:changed=true
    check(floor_.time>t0 and changed,"…dancers, effects and hero animate while the panel is open")
    check(AudioService.boss_music()==null and not bool(AudioService.music_state().held),"…the main music keeps playing")
    # Controls and encounter progression are held; the countdown is paused and hidden.
    var p0: Vector2=sim.position_of(sim.state.player)
    sim.movement=Vector2.RIGHT;steps(1.0);sim.movement=Vector2.ZERO
    check(sim.held and sim.position_of(sim.state.player)==p0,"…controls held")
    await real_wait(1.0)
    game.world._boss_countdowns()
    check(float(sim.state.boss_respawns[id].remaining)==respawn and game.world.boss_labels.is_empty(),"…countdown paused at %.1f s and hidden" % respawn)
    game.world.pan_camera(Vector2(80,0))
    check(game.world.camera_position==cam_before,"…a drag does not move the camera the player gets back")
    # Pause during the panel: the panel stays; unpause continues.
    get_tree().paused=true;await frames(3)
    check(game.final_dialog.is_open(),"Pause: the panel stays")
    get_tree().paused=false;await frames(3)
    # Links keep the panel and do not acknowledge.
    var links=load("res://resources/game/external_links.tres")
    var opened: Array=[]
    links.opener=func(url: String)->int:opened.append(url);return OK
    links.reset_guard()
    game.final_dialog.button("discord").pressed.emit();await frames(2)
    check(opened.size()==1 and game.final_dialog.is_open() and not bool(sim.state.final_ending_seen),"Discord: opens, the panel stays, not acknowledged")
    links.opener=func(url: String)->int:return OS.shell_open(url)
    if windowed:await shot("05_ending_after_link")
    # Continue Playing.
    game.final_dialog.button("continue").pressed.emit();await frames(2)
    check(bool(sim.state.final_ending_seen) and not game.final_dialog.is_open() and not sim.campaign.final_spectacle(),"Continue: acknowledged, panel closed")
    await real_wait(.8)
    check(game.world.cine_weight<=0.0 and not game.world.following_player and game.world.camera_position==cam_before and is_equal_approx(SettingsState.camera_zoom,zoom_before),"…camera back to the player's own pan and zoom")
    check(not hero.dancing,"…the hero's own animation again")
    steps(2.0)
    check(float(sim.state.boss_respawns[id].remaining)<respawn and float(sim.state.boss_respawns[id].remaining)>respawn-2.5,"…the countdown resumes from the remaining time")
    game.world._boss_countdowns()
    check(not game.world.boss_labels.is_empty(),"…and shows again")
    var p1: Vector2=sim.position_of(sim.state.player)
    sim.movement=Vector2.RIGHT;steps(.5);sim.movement=Vector2.ZERO
    check(sim.position_of(sim.state.player)!=p1 and game.world.dance_floor!=null,"…control back; the floor stays until the respawn")
    game.world.pan_camera(Vector2(60,0))
    check(game.world.camera_position!=cam_before,"…manual camera control works again")
    # Later victory: non-blocking.
    sim.state.boss_respawns.clear();alien().respawn=0.0;steps(.1);await frames(3)
    victories.clear();place(Vector2(30,0));steps(.2);calm_boss()
    defeat();await frames(3)
    check(victories==["repeat"] and not sim.campaign.final_spectacle() and not game.final_dialog.is_open(),"Later victory: no cinematic, no panel")
    # An ending never acknowledged (reload while the panel was open) stays owed.
    a=engaged();calm_boss();hold_hero()
    sim.state.final_celebrated=true # fixture: the celebration played before
    defeat();steps(3.2);await frames(4)
    check(game.final_dialog.is_open(),"Owed ending: the panel shows again")
    var snap: Dictionary=sim.snapshot()
    game.final_dialog.close()
    sim.restore(snap);sim.set_physics_process(false);await frames(3)
    check(not bool(sim.state.final_ending_seen) and not sim.campaign.final_spectacle(),"Reload with the panel open: still owed, nothing stuck")

# ================================================================ windowed evidence
func save_png(name_: String) -> void:
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dir+name_+".png"))
    print("SHOT ",dir+name_+".png")
func shot(name_: String) -> void:
    await frames(3)
    save_png(name_)

## Normal-speed playback: the simulation on its own clock, a 10 fps frame sequence of the killing blow, the 10 s
## celebration, the ending panel, Continue and play again.
func playback() -> void:
    print("-- Playback (%s)" % shape)
    var a:=engaged()
    var outfits: Array=sim.campaign.floor_outfits()
    for i in range(0,outfits.size(),2):sim.record(str(outfits[i])).qty=1 # fixture: 24 outfits owned
    SettingsState.set_music_volume(.8)
    sim.campaign.explore_cells(8,[],true);sim.campaign.reveal() # fixture: Spring II explored (an endgame profile)
    game.world.follow_player()
    await frames(10)
    clear_notices();game.stat_feedback.clear() # fixture: no level-500 stat popups in the shot
    keep_hero=true
    calm_boss();a.hp=maxhp()*.02
    sim.set_physics_process(true)
    record=true
    await real_wait(.6)
    defeat()
    await real_wait(1.2);save_png("01_celebration_1s")
    await real_wait(4.0);save_png("02_celebration_5s")
    await real_wait(5.5)
    await real_wait(.8);save_png("03_ending_panel")
    await real_wait(2.0);save_png("04_ending_panel_later")
    game.final_dialog.button("continue").pressed.emit()
    await real_wait(1.2);save_png("06_after_continue")
    game.stick_input=Vector2.RIGHT
    await real_wait(1.0)
    game.stick_input=Vector2.ZERO
    await real_wait(.6);save_png("07_play_again")
    record=false;keep_hero=false
    sim.set_physics_process(false)
