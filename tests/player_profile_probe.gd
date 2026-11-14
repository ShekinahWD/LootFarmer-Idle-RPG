extends Node
## Player-profile playtesting infrastructure probe (Phases 1 and 2). Fast and deterministic, part of the
## maintained suite (tools/run_probes.py). It guards the invariants the long, non-gating playthrough audits rely on:
##   A. the clock seam is off by default and production calls read the system clock;
##   B. with the seam, a simulated day boundary refreshes the daily missions;
##   C. a simulated offline interval is settled and can be claimed exactly once;
##   D. boss-respawn settlement and the Prestige transaction id follow the seam;
##   E. the same seed gives the same normalized event log and final state digest, twice, from fresh profiles;
##   F. a save snapshot survives a JSON round trip and restore with its progression intact.
##   G. (Phase 2) the session schedule is deterministic per seed and profile and independent of the game RNG;
##   H. (Phase 2) a real Casual playthrough over a calendar day: sessions start and end as scheduled, offline
##      time advances only the calendar, each return cold-loads the isolated save with the progression intact,
##      the game settles the absence (capped at the purchased cap) and the claim pays it exactly once, the
##      daily missions roll over at midnight, and the same seed gives the same events and state twice;
##   I. (Phase 2) a warm return (resume notice) settles and claims the same way;
##   J. (Phase 2) a continuous Active run has no sessions and no offline time (the Phase 1 behaviour).
## Sections G-J use no fixtures: every value comes from the real game.
## Sections B, C and D seed a few labelled fixture values (marked "fixture"): they test the engine seam in
## isolation and are never playthrough evidence. Section E is a real, short, natural playthrough.
## Usage: godot --headless --path . res://tests/player_profile_probe.tscn -- --probe --profile=probe-x --no-autosave
const Driver:=preload("res://tests/playtest/playtest_driver.gd")
const Recorder:=preload("res://tests/playtest/playtest_recorder.gd")
const Adapter:=preload("res://tests/playtest/lootfarmer_adapter.gd")
const Policy:=preload("res://tests/playtest/policies/active_policy.gd")
const CasualPolicy:=preload("res://tests/playtest/policies/casual_policy.gd")
const Schedule:=preload("res://tests/playtest/session_schedule.gd")
const DAY:=1767600000.0   # 2026-01-05T08:00:00Z

var checks:=0
var failures:=0

func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("PLAYER_PROFILE_PROBE FAIL: ",label)

func _ready() -> void:call_deferred("run")

func fresh_sim():
    var sim=load("res://scripts/game/simulation.gd").new()
    add_child(sim);sim.set_physics_process(false)
    SaveService.write_blocked=false
    get_tree().paused=false
    return sim

func advance(sim,seconds: float) -> void:
    var steps:=int(round(seconds/.1))
    for i in range(steps):sim.step(.1)

func run() -> void:
    get_tree().create_timer(240.0,true,false,true).timeout.connect(func():print("PLAYER_PROFILE_PROBE watchdog");get_tree().quit(2))
    section_default()
    section_missions()
    section_offline()
    section_respawn_and_prestige_id()
    section_determinism()
    section_schedule()
    section_sessions()
    print("PLAYER_PROFILE_PROBE checks=%d failures=%d" % [checks,failures])
    if failures==0:print("PLAYER_PROFILE_PROBE PASS")
    get_tree().quit(1 if failures else 0)

# A. Production default.
func section_default() -> void:
    var sim=fresh_sim()
    check(sim.clock_override<0,"clock seam is off on a new simulation")
    sim.new_profile()   # a fresh profile, whatever an earlier run of this probe left in its own save namespace
    check(absf(sim.now_unix()-Time.get_unix_time_from_system())<2.0,"now_unix() reads the system clock by default")
    check(sim.today()==Time.get_date_string_from_system(),"today() reads the device date by default")
    check(str(sim.state.mission_day)==Time.get_date_string_from_system(),"a production profile's mission day is the device date")
    check(not sim.save_snapshot().has("clock_override"),"the seam is never written to a save")
    check(absf(float(sim.save_snapshot().boss_saved_at)-Time.get_unix_time_from_system())<2.0,"a production snapshot stamps the system time")
    sim.clock_override=DAY
    check(sim.now_unix()==DAY and sim.today()=="2026-01-05","the seam supplies the virtual time and its UTC date")
    sim.clock_override=-1.0
    check(absf(sim.now_unix()-Time.get_unix_time_from_system())<2.0,"clearing the seam restores the system clock")
    sim.queue_free()

# B. A simulated day boundary refreshes the daily missions.
func section_missions() -> void:
    var sim=fresh_sim()
    sim.clock_override=DAY+15.0*3600+3540.0   # 2026-01-05T23:59:00Z
    sim.rng.seed=7;sim.new_profile();sim.campaign.onboarding.choose_mode("none")
    check(str(sim.state.mission_day)=="2026-01-05","missions are assigned for the virtual day")
    var m: Dictionary=sim.state.missions[0]
    m.progress=float(m.goal)   # fixture: a finished mission, to exercise the claim and the refresh
    check(sim.campaign.claim_mission(0),"the finished mission is claimed")
    advance(sim,2.0)
    check(bool(sim.state.missions[0].claimed) and str(sim.state.missions[0].day)=="2026-01-05","a claimed mission waits for the next day")
    sim.clock_override+=120.0                  # 2026-01-06T00:01:00Z
    advance(sim,2.0)
    check(str(sim.state.mission_day)=="2026-01-06","the day boundary is seen on the next objective tick")
    check(not bool(sim.state.missions[0].claimed) and str(sim.state.missions[0].day)=="2026-01-06","the claimed slot received a new mission")
    check(float(sim.state.playtime_total)<5.0,"the day change advanced no active-time clock")
    sim.clock_override=-1.0;sim.queue_free()

# C. Offline: one interval, settled once, claimable exactly once.
func section_offline() -> void:
    var sim=fresh_sim()
    sim.clock_override=DAY
    sim.rng.seed=7;sim.new_profile();sim.campaign.onboarding.choose_mode("none")
    advance(sim,1.0)
    var coins0: float=float(sim.state.coins)
    sim.notification(NOTIFICATION_APPLICATION_PAUSED)      # the app goes to the background
    check(sim.suspended and float(sim.state.offline_snapshot.time)==DAY,"backgrounding stamps the offline snapshot with the virtual time")
    sim.clock_override=DAY+3.0*3600                        # three hours later
    sim.notification(NOTIFICATION_APPLICATION_RESUMED)
    var pending: Dictionary=sim.state.offline_pending
    check(not pending.is_empty() and absf(float(pending.seconds)-10800.0)<.01,"three offline hours are pending")
    var rate: float=float(sim.player_upgrade_value("offline_coins"))
    check(absf(float(pending.coins)-3.0*rate)<.01,"pending Coins are the game's own hourly rate times three hours")
    check(float(sim.state.coins)==coins0,"nothing is paid before the claim")
    sim.campaign.settle_offline()
    check(absf(float(sim.state.offline_pending.seconds)-10800.0)<.01,"settling again at the same instant adds nothing")
    check(sim.campaign.claim_offline(),"the pending earnings are claimed")
    check(absf(float(sim.state.coins)-coins0-3.0*rate)<.01 and sim.state.offline_pending.is_empty(),"the claim pays once and clears the pending record")
    check(not sim.campaign.claim_offline() and absf(float(sim.state.coins)-coins0-3.0*rate)<.01,"a second claim pays nothing")
    check(absf(float(sim.state.offline_total)-10800.0)<.01,"the offline counter advanced by the interval")
    check(float(sim.state.playtime_total)<2.0,"offline time advanced no active-time clock")
    sim.clock_override=-1.0;sim.queue_free()

# D. Boss-respawn settlement and the Prestige transaction id.
func section_respawn_and_prestige_id() -> void:
    var sim=fresh_sim()
    sim.clock_override=DAY
    sim.rng.seed=7;sim.new_profile();sim.campaign.onboarding.choose_mode("none")
    sim.state.boss_respawns["g3_v2_0"]={"group":3,"stage":1,"remaining":60.0,"x":0.0,"y":0.0}   # fixture: a boss respawning
    sim.state.boss_saved_at=DAY
    sim.clock_override=DAY+25.0
    sim.settle_boss_respawns()
    check(absf(float(sim.state.boss_respawns["g3_v2_0"].remaining)-35.0)<.01,"boss respawn settlement uses the virtual elapsed time")
    var snowman:=-1
    for g in range(sim.catalog.groups.size()):
        if str(sim.catalog.groups[g].id)=="boss-snowman":snowman=g
    sim.state.group_kills[snowman]=1                                                             # fixture: first boss defeated
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}         # fixture: a ready opportunity
    check(sim.campaign.begin_prestige(),"the Prestige transaction begins")
    check(str(sim.state.prestige_batch.transaction).begins_with(str(DAY+25.0)+"-"),"the transaction id carries the virtual time")
    check(sim.campaign.cancel_prestige(),"the unchosen batch is cancelled")
    sim.clock_override=-1.0;sim.queue_free()

# E/F. A real short playthrough, twice from fresh profiles, and a snapshot round trip.
func play(seed_value: int,tag: String) -> Dictionary:
    var sim=fresh_sim()
    var recorder=Recorder.new()
    var folder:=ProjectSettings.globalize_path("res://tests/tmp/player_profiles/_probe/"+tag)
    DirAccess.make_dir_recursive_absolute(folder)
    var marker:=FileAccess.open(ProjectSettings.globalize_path("res://tests/tmp/player_profiles/.gdignore"),FileAccess.WRITE)
    if marker!=null:marker.close()
    check(recorder.open(folder,false),"the recorder opens its scratch folder")
    var adapter=Adapter.new()
    var driver=Driver.new()
    adapter.setup(sim,recorder,seed_value,driver.start_unix)
    var policy=Policy.new()
    policy.setup(adapter)
    driver.adapter=adapter;driver.policy=policy;driver.recorder=recorder
    driver.active_limit=240.0;driver.max_wall_seconds=60.0
    var stop: String=driver.run()
    var result: Dictionary={"stop":stop,"events":recorder.digest(),"state":adapter.state_digest(),"kills":int(adapter.summary().kills_total),
        "active":driver.active,"steps":driver.steps,"count":recorder.count,"sim":sim,"adapter":adapter}
    return result

## Item quantities and merge levels, or upgrade levels, as one comparable line (JSON turns ints into floats).
func numbers(source: Dictionary) -> String:
    var parts: Array=[]
    var keys: Array=source.keys();keys.sort()
    for key in keys:
        var value=source[key]
        if value is Dictionary:parts.append("%s=%d^%d" % [key,int(value.get("qty",0)),int(value.get("merge",0))])
        else:parts.append("%s=%d" % [key,int(value)])
    return ",".join(parts)

func section_determinism() -> void:
    var first:=play(1,"a")
    check(str(first.stop)=="duration_reached","the short playthrough ends by duration")
    check(absf(float(first.active)-240.0)<.01 and int(first.steps)==2400,"240 active seconds are 2,400 real 0.1 s steps")
    check(int(first.kills)>0,"the policy defeats enemies through real combat")
    check(int(first.adapter.counts.pickups)>0 and first.adapter.first_times.has("equip"),"it picks up and equips real loot")
    check(int(first.adapter.summary().upgrades_bought)>0,"it buys upgrades through the purchase function")
    var sim=first.sim
    # F. Snapshot round trip (no checkpoint-resume feature exists yet; this only guards the save contract).
    var saved: Dictionary=JSON.parse_string(JSON.stringify(sim.save_snapshot()))
    var before: Dictionary={"level":int(sim.state.player_level),"xp":float(sim.state.xp),"coins":float(sim.state.coins),"gems":float(sim.state.gems),
        "items":numbers(sim.state.items),"upgrades":numbers(sim.state.upgrades),"rng":sim.rng.state}
    sim.restore(saved)
    check(int(sim.state.player_level)==int(before.level) and absf(float(sim.state.xp)-float(before.xp))<.001,"restore keeps level and experience")
    check(absf(float(sim.state.coins)-float(before.coins))<.001 and absf(float(sim.state.gems)-float(before.gems))<.001,"restore keeps currencies")
    check(numbers(sim.state.items)==str(before.items) and str(before.items)!="","restore keeps items, quantities and merge levels")
    check(numbers(sim.state.upgrades)==str(before.upgrades) and str(before.upgrades)!="","restore keeps upgrades")
    check(sim.rng.state==before.rng,"restore keeps the random stream")
    first.adapter.teardown()
    check(sim.clock_override<0,"teardown clears the clock seam")
    sim.queue_free()
    var second:=play(1,"b")
    check(str(second.events)==str(first.events) and int(second.count)==int(first.count),"same seed: identical normalized event log")
    check(str(second.state)==str(first.state),"same seed: identical final state digest")
    second.adapter.teardown();second.sim.queue_free()
    var other:=play(2,"c")
    check(str(other.state)!=str(first.state),"another seed gives another playthrough")
    other.adapter.teardown();other.sim.queue_free()

# G. The schedule alone: deterministic per seed and profile, its own random stream, slots and lengths honoured.
func section_schedule() -> void:
    var config:={"mode":"sessions","session_minutes":[16,24],"slots":[{"hour":8.5,"chance":1.0},{"hour":13.0,"chance":.5},{"hour":20.0,"chance":1.0}],
        "jitter_minutes":30,"min_gap_minutes":30}
    var lists: Array=[]
    for i in range(3):
        var sch=Schedule.new()
        sch.setup(config,1 if i<2 else 2,"casual")
        var list: Array=[snappedf(sch.first_length(),.01)]
        var at:=0.0
        for n in range(12):
            var next: Dictionary=sch.next_after(at)
            list.append([snappedf(float(next.start_c),.01),snappedf(float(next.active_s),.01)])
            at=float(next.start_c)+float(next.active_s)
        lists.append(list)
    check(var_to_str(lists[0])==var_to_str(lists[1]),"same seed and profile: the same sessions")
    check(var_to_str(lists[0])!=var_to_str(lists[2]),"another seed: other sessions")
    var ok_lengths:=true
    var ok_order:=true
    var prev:=0.0
    for item in lists[0].slice(1):
        if float(item[1])<16*60-.01 or float(item[1])>24*60+.01:ok_lengths=false
        if float(item[0])<prev+30*60-.01:ok_order=false
        prev=float(item[0])+float(item[1])
    check(ok_lengths,"session lengths stay inside session_minutes")
    check(ok_order,"sessions never overlap and keep min_gap_minutes")
    var days:=int(float(lists[0][-1][0])/86400.0)+1
    check(lists[0].size()-1>=2*days-1 and lists[0].size()-1<=3*days+1,"two or three sessions a day")
    var rng_probe:=RandomNumberGenerator.new();rng_probe.seed=99
    var before:=rng_probe.state
    var sch2=Schedule.new();sch2.setup(config,99,"casual");sch2.next_after(0.0)
    check(rng_probe.state==before,"the schedule never draws from another random stream")

## One short scheduled Casual playthrough: 1-minute sessions at 08:00, ~08:12 and 20:00 each day, for 26
## calendar hours (crossing midnight, one absence longer than the 5-hour cap).
func play_sessions(seed_value: int,tag: String,return_mode: String) -> Dictionary:
    var sim=fresh_sim()
    var recorder=Recorder.new()
    var folder:=ProjectSettings.globalize_path("res://tests/tmp/player_profiles/_probe/"+tag)
    DirAccess.make_dir_recursive_absolute(folder)
    check(recorder.open(folder,false),"the recorder opens its scratch folder ("+tag+")")
    var adapter=Adapter.new()
    var driver=Driver.new()
    adapter.setup(sim,recorder,seed_value,driver.start_unix)
    var policy=CasualPolicy.new()
    policy.setup(adapter)
    var schedule=Schedule.new()
    schedule.setup({"mode":"sessions","session_minutes":[1,1],"slots":[{"hour":8.2,"chance":1.0},{"hour":20.0,"chance":1.0}],
        "jitter_minutes":0,"min_gap_minutes":0,"end_grace_seconds":60,"return_mode":return_mode},seed_value,"casual")
    driver.adapter=adapter;driver.policy=policy;driver.recorder=recorder;driver.schedule=schedule
    driver.until="calendar";driver.calendar_limit=26.0*3600;driver.active_limit=INF;driver.stall_seconds=0.0;driver.max_wall_seconds=60.0
    var stop: String=driver.run()
    return {"stop":stop,"driver":driver,"adapter":adapter,"sim":sim,"events":recorder.digest(),"state":adapter.state_digest(),"folder":folder}

func read_events(folder: String) -> Array:
    var out: Array=[]
    for line in FileAccess.get_file_as_string(folder.path_join("events.jsonl")).split("\n",false):out.append(JSON.parse_string(line))
    return out

func section_sessions() -> void:
    check(BootContext.profile_name.begins_with("probe") and BootContext.save_directory().contains(BootContext.profile_name),"runs save only inside the isolated probe profile")
    var first:=play_sessions(3,"s1","cold")
    var d=first.driver
    var adapter=first.adapter
    check(str(first.stop)=="calendar_reached","the calendar horizon ends the run")
    check(absf(d.calendar()-26.0*3600)<.2,"the run stops at 26 calendar hours")
    check(absf(d.calendar()-(d.active+d.offline))<.01,"calendar time is active plus offline time")
    check(d.sessions.size()==4,"four sessions in 26 hours (08:00, 08:12, 20:00, next day 08:12)")
    var lengths_ok:=true
    for s in d.sessions:
        if float(s.active_s)<60.0-.01 or float(s.active_s)>60.0+60.0+.01:lengths_ok=false
    check(lengths_ok,"each session plays its minute (plus at most the end grace)")
    check(d.active<6.0*60.0 and d.offline>25.0*3600,"almost all of the day is offline time")
    var events:=read_events(str(first.folder))
    var settled: Array=events.filter(func(e):return str(e.type)=="offline_settled")
    var claims: Array=events.filter(func(e):return str(e.type)=="action" and str(e.action)=="claim_offline")
    var errors: Array=events.filter(func(e):return str(e.type)=="action_error")
    check(errors.is_empty(),"no persistence or action error across three cold returns")
    check(settled.size()==3 and claims.size()==3 and int(adapter.offline.claims)==3,"every return is settled once and claimed once")
    var away_sum:=0.0
    var cap_ok:=true
    var long_seen:=false
    for e in settled:
        away_sum+=float(e.away_s)
        if absf(float(e.settled_s)-float(e.away_s))>2.0:cap_ok=false
        var paid_h:=minf(float(e.away_s),float(e.cap_h)*3600.0)/3600.0
        if absf(float(e.rewarded_h)-paid_h)>.002:cap_ok=false
        if float(e.away_s)>float(e.cap_h)*3600.0:long_seen=true
    check(absf(away_sum+d.away_at_stop-d.offline)<1.0 and d.away_at_stop>0.0,"the settled absences plus the absence cut by the horizon add up to the offline time")
    check(cap_ok,"each absence is settled in full and paid up to the purchased cap")
    check(long_seen and float(adapter.offline.capped_seconds)>0.0,"an absence longer than the cap pays only the cap")
    check(absf(float(adapter.offline.claimed.coins)-float(adapter.offline.earned.coins))<.01,"claimed Coins equal what the game settled")
    check(first.sim.state.offline_pending.is_empty(),"nothing stays pending after the last claim")
    var coins: float=float(first.sim.state.coins)
    check(not adapter.claim_offline().ok and float(first.sim.state.coins)==coins,"a second claim pays nothing")
    check(adapter.mission_days.size()>=1 and str(adapter.mission_days[0].day)=="2026-01-06","the daily missions roll over at the virtual midnight")
    check(absf(float(first.sim.state.offline_total)-away_sum)<1.0,"the game's own offline counter advanced by exactly the claimed time")
    check(int(first.sim.state.player_level)>1 and int(adapter.summary().kills_total)>0,"progress made in early sessions persists to the end")
    adapter.teardown();first.sim.queue_free()
    var again:=play_sessions(3,"s2","cold")
    check(str(again.events)==str(first.events),"same seed and schedule: identical event log")
    check(str(again.state)==str(first.state),"same seed and schedule: identical final state")
    again.adapter.teardown();again.sim.queue_free()
    var warm:=play_sessions(3,"s3","warm")
    var warm_events:=read_events(str(warm.folder))
    check(str(warm.stop)=="calendar_reached" and warm_events.filter(func(e):return str(e.type)=="action_error").is_empty(),"warm returns run without errors")
    check(int(warm.adapter.offline.claims)==3 and warm.sim.state.offline_pending.is_empty(),"warm returns are settled and claimed once each")
    warm.adapter.teardown();warm.sim.queue_free()
    # J. Continuous Active: no sessions, no offline time, no session events.
    var cont:=play(1,"d")
    var cont_events:=read_events(ProjectSettings.globalize_path("res://tests/tmp/player_profiles/_probe/d"))
    check(float(cont.adapter.offline.away_seconds)==0.0 and cont_events.filter(func(e):return str(e.type) in ["session_started","offline_settled","schedule"]).is_empty(),
        "a continuous Active run has no sessions and no offline time")
    cont.adapter.teardown();cont.sim.queue_free()
