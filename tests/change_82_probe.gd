extends Node
## Change 82 focused checks (real main scene and simulation; state set directly is labelled "fixture"). Presentation
## and encounter rules only; no balance values are read or changed here.
## 1. Fewer than 13 keys: the Green Alien stays sealed; no ceremony, no arena.
## 2. 13 keys, first approach: the ceremony runs once (world frozen, boss untargetable, no travel), saves the unlock
##    only when it completes, never touches the keys, then the encounter starts and the arena closes.
## 3. Once-only: repeat approach, death, Prestige and save/load never replay it; an interrupted ceremony replays;
##    Hard Reset clears it; an old save with 13 keys and no record gets it.
## 4. Arena: joystick / Auto Farm / chase cannot cross it, the boss and helpers stay in, others stay out and cannot be
##    targeted across it; Teleport, travel, Prestige and Auto Farm elsewhere are refused; combat inside works.
## 5. Death and victory open it at once; re-engagement recloses it without the ceremony.
## 6. Pause, save/reload, Hard Reset: no stale barrier, never outside the circle.
## 7. The ceremony and barrier views follow the simulation.
## Run: Godot --headless --path . res://tests/change_82_probe.tscn -- --probe --profile=probe-c82 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim
var phases: Array=[]
var arena_events: Array=[]
var events: Array=[]

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(600.0,true,false,true).timeout.connect(func():push_error("CHANGE_82 watchdog");get_tree().quit(2))
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(540,960)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.final_ceremony.connect(func(p: String)->void:phases.append(p))
    sim.arena_changed.connect(func(active: bool,reason: String)->void:arena_events.append([active,reason]))
    sim.event.connect(func(k: String)->void:events.append(k))
    await frames(6)
    await sealed_checks()
    await ceremony_checks()
    await once_only_checks()
    await arena_checks()
    await shift_checks()
    await death_victory_checks()
    await persistence_checks()
    await view_checks()
    print("CHANGE_82_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func fresh() -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    sim.state.tutorial.seen.append("final_intro")
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_important.clear();game.get_node("Toast").hide();game.toast_time=0.0
    game.key_fx.clear()
    phases.clear();arena_events.clear();events.clear()

func gi(id: String) -> int:
    for g in range(sim.catalog.groups.size()):
        if sim.catalog.groups[g].id==id:return g
    return -1
func spring_two() -> void:
    sim.state.stage=8;sim.state.unlocked_stage=8;sim.state.spawns=[0,1,2];sim.state.camps["8"]=[0,1,2]
    sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II reached, its camps owned
func alien() -> Dictionary:
    for a in sim.state.enemies:
        if bool(sim.catalog.groups[int(a.group)].final) and not sim.is_helper(a):return a
    return {}
func all_keys() -> void:
    sim.state.final_discovered=true
    sim.state.keys=[]
    for d in sim.catalog.groups:
        if d.boss and not d.final:sim.state.keys.append(str(d.id)) # fixture: 13 keys earned
    sim.state.final_warning_ok=true # fixture: the Change 83 danger warning accepted earlier (this probe tests the ceremony)
## Strong enough to stand in the fight for the few seconds these checks need (fixture; no balance read).
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
func run_ceremony() -> void:
    var guard:=0
    while sim.campaign.ceremony_active() and guard<400:
        sim.step(.05);guard+=1
func inside(a: Dictionary) -> float:
    return sim.position_of(a).distance_to(sim.campaign.arena_center())
func calm_boss() -> void:
    var a:=alien();a.cooldown=99.0;a.skill_timer=99.0;a.summon_cd=99.0 # fixture: the boss holds its attacks

# ================================================================ 1. Sealed
func sealed_checks() -> void:
    print("-- Fewer than 13 keys")
    fresh();spring_two();sturdy()
    sim.state.final_discovered=true;sim.state.keys=["boss-snowman"]
    place(Vector2(60,0))
    steps(1.0)
    var a:=alien()
    check(not sim.campaign.ceremony_active() and phases.is_empty(),"Close by with 1 key: no ceremony")
    check(not bool(a.aggro) and not sim.campaign.arena_active(),"…no fight and no arena")
    check(not sim.select_target(str(a.id)) and events.has("FINAL_SEALED") and not sim.campaign.ceremony_active(),"A tap still explains the seal")
    sim.state.keys.append_array(["boss-gray-cat"])
    check(sim.campaign.final_sealed(int(a.group)) and sim.campaign.final_locked(int(a.group)),"12 or fewer: sealed and locked")

# ================================================================ 2. Ceremony
func ceremony_checks() -> void:
    print("-- 13 keys: the ceremony")
    fresh();spring_two();sturdy();all_keys()
    var a:=alien()
    check(not sim.campaign.final_sealed(int(a.group)) and sim.campaign.final_locked(int(a.group)),"13 keys: no longer sealed, still locked until the ceremony")
    check(not sim.campaign.target_allowed(a),"…and not targetable yet")
    # Reaching 13 elsewhere never plays it.
    sim.state.stage=1;sim.campaign.configure_stage();sim._reset_world() # fixture: on Winter I
    steps(.5)
    check(not sim.campaign.ceremony_active() and phases.is_empty(),"13 keys on another map: nothing plays")
    spring_two();a=alien()
    place(Vector2(200,0));steps(.3)
    check(not sim.campaign.ceremony_active(),"Out of range (200): not yet")
    place(Vector2(130,0));sim.campaign.reveal_circle(sim.position_of(a),40.0);events.clear() # fixture: its ground explored on an earlier visit
    check(sim.campaign.can_see(sim.position_of(a)) and not sim.select_target(str(a.id)) and not sim.campaign.ceremony_active() and events.has("FINAL_READY_NOTICE"),"A tap from 130 (in sight) says it is ready; walking up starts it %s %s %s" % [sim.campaign.can_see(sim.position_of(a)),events,sim.campaign.vision_radius()])
    place(Vector2(80,0));sim.step(.05)
    check(sim.campaign.ceremony_active() and phases==["start"] and sim.campaign.ceremony_boss==str(a.id),"First approach (80): the ceremony starts")
    check(not bool(sim.state.get("final_unsealed",false)),"…the unlock is not saved yet")
    var hp: float=sim.state.player.hp;var clock: float=sim.state.clock;var pos: Vector2=sim.position_of(sim.state.player)
    sim.movement=Vector2.RIGHT
    steps(1.0)
    check(sim.position_of(sim.state.player)==pos and sim.state.clock==clock and sim.state.player.hp==hp,"World frozen: no walking, clock or damage")
    check(not bool(a.aggro) and not sim.select_target(str(a.id)) and sim.locked_target=="","Boss: no aggro, no target")
    check(not sim.campaign.camp_action(8,0,true) and events.has("ARENA_SEALED"),"No Teleport out of the ceremony")
    check(sim.campaign.prestige_block_reason()=="ARENA_SEALED","No Prestige during it")
    await frames(2)
    check(game.world.ceremony_fx.visible,"The key ceremony is drawn")
    sim.movement=Vector2.ZERO
    var keys_before: Array=sim.state.keys.duplicate()
    run_ceremony()
    check(phases==["start","unseal","done"],"Phases: start, unseal, done (%s)" % [phases])
    check(bool(sim.state.final_unsealed) and sim.state.keys==keys_before,"Unlock saved; 13 keys untouched")
    check(not game.banner.queue.is_empty() or not game.banner.current.is_empty(),"The worthiness banner is shown")
    var entry: Dictionary={}
    for e in [game.banner.current]+game.banner.queue:
        if str(e.get("kind",""))=="final_unsealed":entry=e
    check(str(entry.get("title",""))=="YOU HAVE PROVEN YOUR WORTH!" and str(entry.get("subtitle",""))=="The Green Alien accepts your challenge. Defeat it!" and entry.get("art")!=null,"…its text and boss art")
    check(bool(a.aggro) and not sim.campaign.final_locked(int(a.group)),"The encounter starts after the ceremony")
    sim.step(.05)
    check(sim.campaign.arena_active() and arena_events.back()==[true,"close"],"…and the arena closes")
    check(inside(sim.state.player)<=sim.campaign.arena_radius()-sim.campaign.ARENA_CLOSE_MARGIN and inside(a)<sim.campaign.arena_radius(),"Player and boss inside when it closes")
    # The unlock is on disk.
    check(SaveService.save_now(),"Disk save")
    sim.state.final_unsealed=false # fixture: in-memory loss
    SaveService.load_and_apply();await frames(2)
    check(bool(sim.state.final_unsealed),"The unlock is in the save")
    check(not sim.campaign.ceremony_active() and not sim.snapshot().has("arena"),"No ceremony or barrier in the save")

# ================================================================ 3. Once only
func once_only_checks() -> void:
    print("-- Once only, interruptions")
    fresh();spring_two();sturdy();all_keys()
    place(Vector2(80,0));sim.step(.05)
    check(sim.campaign.ceremony_active(),"Ceremony running")
    steps(2.0)
    # An app restart mid-way: the save never had the unlock.
    var snap: Dictionary=sim.snapshot()
    sim.restore(snap)
    check(not sim.campaign.ceremony_active() and not bool(sim.state.final_unsealed) and phases.back()=="cancel","Interrupted by a reload: dropped, nothing saved")
    phases.clear()
    sim.set_physics_process(false)
    place(Vector2(80,0));sim.step(.05)
    check(sim.campaign.ceremony_active() and phases==["start"],"The next approach replays it")
    run_ceremony()
    check(bool(sim.state.final_unsealed),"…and completes")
    # Death, then re-engagement: no replay.
    sim.step(.05)
    die()
    phases.clear()
    steps(.2)
    var p: Dictionary=sim.state.player
    p.respawn=0.0;steps(.1);sturdy()
    place(Vector2(30,0));steps(.3)
    check(phases.is_empty() and not sim.campaign.ceremony_active(),"After a death the next attempt starts with no ceremony")
    check(bool(alien().aggro),"…the fight starts normally")
    # Prestige keeps it, Hard Reset clears it.
    die();steps(.1)
    check(do_prestige(),"Prestige (%s)" % sim.campaign.prestige_block_reason())
    check(bool(sim.state.final_unsealed) and sim.state.keys.size()==13,"Prestige keeps the unlock and the keys")
    spring_two();sturdy();phases.clear()
    place(Vector2(30,0));steps(.3)
    check(phases.is_empty() and bool(alien().aggro),"After Prestige: no ceremony, the fight starts")
    die();steps(.1)
    check(SaveService.hard_reset(),"Hard Reset")
    sim.set_physics_process(false)
    check(not bool(sim.state.final_unsealed) and not sim.campaign.arena_active() and not sim.campaign.ceremony_active(),"Hard Reset clears the unlock and any encounter state")
    # An older save: 13 keys, no record at all.
    fresh()
    var old: Dictionary=sim.snapshot()
    old.erase("final_unsealed");old.final_discovered=true;old.keys=[]
    for d in sim.catalog.groups:
        if d.boss and not d.final:old.keys.append(str(d.id))
    sim.state.final_unsealed=true # fixture: the live profile must not leak into the loaded one
    sim.restore(old);sim.set_physics_process(false)
    check(not bool(sim.state.final_unsealed) and sim.state.keys.size()==13,"An older save with 13 keys has no unlock (it will see the ceremony)")

func do_prestige() -> bool:
    var g: int=sim.campaign.prestige_unlock_group()
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman") # fixture: found
    if int(sim.state.group_kills[g])<1:sim.state.group_kills[g]=1 # fixture: defeated once
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    sim.state.consumed.erase("hunter_o1")
    if not sim.campaign.begin_prestige():return false
    var guard:=0
    while not sim.state.prestige_batch.is_empty() and guard<40:
        guard+=1
        if not sim.campaign.choose_card(str(sim.campaign.offered_cards()[0])):return false
    return sim.state.prestige_batch.is_empty()

## A fresh Spring II with the ceremony already done and the fight on (fixture).
func engaged() -> Dictionary:
    fresh();spring_two();sturdy();all_keys()
    sim.state.final_unsealed=true;sim.state.final_experience=true # fixture: ceremony (and Change 83 introduction) completed earlier
    place(Vector2(30,0));steps(.1)
    return alien()

# ================================================================ 4. Arena
func arena_checks() -> void:
    print("-- Arena")
    var a:=engaged()
    check(sim.campaign.arena_active() and phases.is_empty(),"Engaging closes the arena (no ceremony)")
    var c: Vector2=sim.campaign.arena_center();var r: float=sim.campaign.arena_radius()
    check(c.distance_to(Vector2(a.home_x,a.home_y))<.01 and r==118.0,"Circle: the boss's home, radius 118")
    var solids:=0
    for o in sim.campaign.obstacle_list:
        var oc: Vector2=o.c if o.has("c") else o.rect.get_center()
        if oc.distance_to(c)<r+float(o.get("r",20.0))+6:solids+=1
    check(solids==0,"No solid scenery inside or on the barrier (the clearing)")
    check(r+c.distance_to(Vector2(a.home_x,a.home_y))<float(sim.catalog.world.leash),"The boss can never be leashed from inside it")
    calm_boss()
    # Joystick: walk straight out in four directions.
    var p: Dictionary=sim.state.player
    var worst:=0.0
    var notices:=-1
    for dir in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP,Vector2(1,1)]:
        sim.state.player.x=c.x;sim.state.player.y=c.y
        sim.movement=dir
        events.clear()
        for i in range(120):
            calm_boss();sim.step(.05)
            worst=maxf(worst,inside(p))
        if notices<0:notices=events.count("ARENA_SEALED")
    sim.movement=Vector2.ZERO
    check(sim.campaign.arena_active() and worst<=r-sim.campaign.ARENA_CLEARANCE+.01,"Joystick: never past the barrier (max %.1f of %.0f)" % [worst,r])
    check(notices>=1 and notices<=2,"Pressing against it for ~4 s: one notice per 4 s, no spam (%d)" % notices)
    # Auto Farm: another type refused; a focus already set elsewhere cannot pull the hero out.
    var other:=gi("boss-sunflower")
    sim.state.upgrades["focus"]=1;sim.campaign.discover_spot(other,2);sim.state.discovered[str(other)]=true # fixture: Focus owned, spot known
    events.clear()
    check(not sim.focus(other) and events.has("ARENA_SEALED"),"Auto Farm on another type is refused")
    sim.state.focus=other # fixture: a Focus chosen before the fight
    worst=0.0
    for i in range(200):
        sim._move(p,sim.farming_position(),sim.campaign.move_speed(),.05)
        worst=maxf(worst,inside(p))
    check(worst<=r-sim.campaign.ARENA_CLEARANCE+.01,"Auto Farm walk toward the old spot stops at the barrier")
    sim.state.focus=-1
    # The boss chasing out, a helper, and an outsider.
    worst=0.0
    for i in range(200):
        sim._move(a,c+Vector2(0,600),62,.05);worst=maxf(worst,inside(a))
    check(worst<=r-sim.campaign.ARENA_CLEARANCE+.01,"The boss cannot leave")
    a.x=a.home_x;a.y=a.home_y
    var rule=sim.abilities.summon_rule(str(sim.enemy_definition(int(a.group),2).id))
    var helpers: Array=sim.spawn_helpers(a,rule,gi("unit-green-cap") if gi("unit-green-cap")>=0 else int(a.group),1) if rule!=null else []
    if not helpers.is_empty():
        var h: Dictionary=sim._find_actor(str(helpers[0]))
        worst=0.0
        for i in range(200):
            sim._move(h,c+Vector2(-600,0),62,.05);worst=maxf(worst,inside(h))
        check(worst<=r-sim.campaign.ARENA_CLEARANCE+.01 and sim.campaign.arena_member(h),"Its helper stays inside")
    var outsider: Dictionary={}
    for e in sim.state.enemies:
        if not bool(sim.catalog.groups[int(e.group)].final) and not sim.is_helper(e) and float(e.hp)>0:outsider=e;break
    var ox: float=outsider.x;var oy: float=outsider.y
    outsider.x=c.x+r+40;outsider.y=c.y # fixture: an ordinary enemy near the barrier
    var least:=INF
    for i in range(100):
        sim._move(outsider,c,60,.05);least=minf(least,inside(outsider))
    check(least>=r+sim.campaign.ARENA_CLEARANCE-.01,"An ordinary enemy cannot come in (min %.1f)" % least)
    outsider.x=c.x+r-20 # fixture: one standing just inside the line when it closed
    check(not sim.campaign.target_allowed(outsider),"…and is not a target while the arena is closed")
    outsider.x=ox;outsider.y=oy
    # Travel, Teleport, Prestige.
    events.clear()
    check(sim.campaign.travel_reason(8,0)=="ARENA_SEALED" and not sim.campaign.camp_action(8,0,true) and events.has("ARENA_SEALED"),"Teleport to a camp refused")
    check(sim.campaign.travel_reason(1,0)=="ARENA_SEALED" and not sim.campaign.camp_action(1,0,true) and int(sim.state.stage)==8,"Map travel refused")
    check(sim.campaign.prestige_block_reason()=="ARENA_SEALED" and not sim.campaign.begin_prestige(),"Prestige refused")
    check(sim.campaign.arena_active() and int(sim.state.stage)==8 and inside(p)<r,"Still sealed in")
    # Combat inside works.
    sim.state.player.x=a.x+20;sim.state.player.y=a.y
    var hp: float=a.hp
    check(sim.select_target(str(a.id)),"The Green Alien can be targeted")
    steps(2.0)
    check(float(a.hp)<hp,"Hits land inside the arena (%.0f -> %.0f)" % [hp,float(a.hp)])
    # Pause holds everything.
    get_tree().paused=true
    var before: Vector2=sim.position_of(p)
    sim.movement=Vector2.RIGHT;steps(.5);sim.movement=Vector2.ZERO
    check(sim.campaign.arena_active() and sim.position_of(p)==before,"Paused: frozen, still sealed")
    get_tree().paused=false

func shift_checks() -> void:
    print("-- Engaging from just outside")
    var a:=engaged()
    die();steps(.1);sim.state.player.respawn=0.0;steps(.1);sturdy()
    var home:=Vector2(a.home_x,a.home_y)
    a.x=home.x;a.y=home.y;a.returning=false
    place(Vector2(0,150));a.aggro=true # fixture: hit from 150 (a ranged skill), the boss engaged
    steps(.05)
    check(sim.campaign.arena_active(),"The circle slides toward the player and closes")
    var c: Vector2=sim.campaign.arena_center()
    check(inside(sim.state.player)<=118-12+.01 and inside(a)<118 and c.distance_to(home)<=100.01,"…with both inside, at most 100 from home")
    die();steps(.1);sim.state.player.respawn=0.0;steps(.1);sturdy()
    a.x=home.x;a.y=home.y;a.returning=false
    place(Vector2(0,260));a.aggro=true # fixture: engaged from 260
    steps(.05)
    check(not sim.campaign.arena_active(),"From 260 it waits (never closes through or around a far player)")

# ================================================================ 5. Death and victory
func death_victory_checks() -> void:
    print("-- Death and victory")
    var a:=engaged()
    check(sim.campaign.arena_active(),"Sealed")
    arena_events.clear()
    die()
    check(not sim.campaign.arena_active() and arena_events==[[false,"death"]],"Death opens it at once %s" % [arena_events])
    var p: Dictionary=sim.state.player
    steps(.2)
    p.respawn=0.0;steps(.1);sturdy()
    check(not sim.campaign.arena_active() and float(p.hp)>0,"Respawned at camp, barrier gone")
    var can: String=sim.campaign.travel_reason(8,1)
    check(can!="ARENA_SEALED","Travel is allowed again (%s)" % can)
    place(Vector2(30,0));steps(.3)
    check(sim.campaign.arena_active() and arena_events.back()==[true,"close"] and phases.is_empty(),"Re-engagement recloses it; no ceremony")
    arena_events.clear()
    var kills: int=int(sim.state.group_kills[int(a.group)])
    a.hp=0.0;sim._kill(a)
    check(not sim.campaign.arena_active() and arena_events==[[false,"victory"]],"Victory opens it at once")
    check(int(sim.state.group_kills[int(a.group)])==kills+1 and sim.state.boss_respawns.has(str(a.id)),"…and the normal win flow ran (kill counted, respawn timer)")
    check(sim.campaign.travel_reason(8,1)!="ARENA_SEALED","Free to leave after the win")

# ================================================================ 6. Persistence and resets
func persistence_checks() -> void:
    print("-- Save / reload")
    var a:=engaged()
    check(sim.campaign.arena_active(),"Sealed")
    check(SaveService.save_now(),"Save mid-fight")
    SaveService.load_and_apply();await frames(2)
    sim.set_physics_process(false)
    check(not sim.campaign.arena_active(),"Reload drops the barrier at once")
    a=alien()
    steps(.1)
    check(bool(sim.state.get("final_unsealed",false)),"The unlock survives")
    var p: Dictionary=sim.state.player
    check(int(sim.state.group_kills[int(a.group)])==0 and sim.state.keys.size()==13,"Reload never marks it defeated or spends keys")
    if sim.campaign.arena_active():
        check(inside(p)<sim.campaign.arena_radius(),"Rebuilt around a player who is inside it")
    else:
        check(true,"Rebuilt only on re-engagement")
    sim.state.player.x=float(a.home_x)+400 # fixture: a saved position far from the fight
    sim.campaign.reset_final_encounter()
    a.aggro=true
    steps(.1)
    check(not sim.campaign.arena_active(),"Never closes around a player who is outside it")
    print("-- Hard Reset while sealed")
    a=engaged()
    check(sim.campaign.arena_active(),"Sealed")
    check(SaveService.hard_reset(),"Hard Reset")
    sim.set_physics_process(false)
    check(not sim.campaign.arena_active() and int(sim.state.stage)==1,"Hard Reset: no barrier, fresh map")

# ================================================================ 7. Views
func view_checks() -> void:
    print("-- Views")
    var a:=engaged()
    await frames(3)
    var fx=game.world.arena_fx
    check(fx.visible and fx.phase in ["closing","closed"],"The barrier is drawn while sealed")
    die()
    await frames(2)
    check(fx.phase=="opening","It opens on defeat")
    for i in range(60):fx._process(.05)
    check(not fx.visible and fx.phase=="","…and is gone afterwards")
    fresh();spring_two();sturdy();all_keys()
    place(Vector2(80,0));sim.step(.05)
    await frames(2)
    check(game.world.ceremony_fx.visible,"The ceremony view runs with the ceremony")
    sim.restore(sim.snapshot());sim.set_physics_process(false)
    await frames(2)
    check(not game.world.ceremony_fx.visible,"…and disappears when it is dropped")

## The player falls in the fight (fixture: HP to zero, then the simulation's own defeat).
func die() -> void:
    sim.state.player.hp=0.0
    sim._kill(sim.state.player)
