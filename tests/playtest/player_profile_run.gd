extends Node
## Player-profile playtest run: one player profile playing the real LootSimulation from a fresh, isolated
## save. Non-gating: never part of tools/run_probes.py. Run it through tools/player_profile_run.py, which adds
## the process watchdog and builds the reports.
##
## Two policy sets (--policy-set, default `framework`):
##   framework  the reusable Player Profiles package (res://addons/player_profiles/): seven universal profiles
##              (active, casual, idle, beginner, collector, speedrunner, completionist) decided by the universal
##              engine, played through the LootFarmer integration (tests/playtest/lootfarmer/). Options are those
##              of addons/player_profiles/core/run_session.gd options_from_args(), plus --override=trait=value,...
##   legacy     the frozen Phase 1/2 policies `active-1`, `casual-1`, `idle-1` (tests/playtest/policies/,
##              tests/playtest/profiles.json) with the Phase 1/2 driver, unchanged: the historical baseline.
##              Their events and digests stay comparable with the Phase 1/2 evidence.
##
##   godot --headless --path . res://tests/playtest/player_profile_run.tscn -- --probe --no-autosave
##         --profile=probe-pp-<id> --player-profile=<id> --seed=1 [--policy-set=framework|legacy]
##         --active-minutes=60                               (active-time horizon)
##       | --until=calendar --calendar-hours=24 [--max-active-minutes=N]   (calendar horizon)
##       | --until=first-prestige --max-active-minutes=240 [--max-calendar-hours=N]
##         [--schedule=default|continuous|calendar|sessions] [--session-minutes=16-24] [--slots=8.5,13@0.5,20]
##         [--jitter-minutes=30] [--min-gap-minutes=30] [--grace-seconds=120] [--return-mode=cold|warm]
##         [--override=attention=0.4,weight.explore=0.9] (framework only)
##         [--max-wall-seconds=600] [--stall-minutes=30] [--trace] --output=<absolute folder under tests/tmp/player_profiles/>
##
## Last line: PLAYTEST_RESULT ok=<true|false> stop=<reason> ... Exit code 0 when the run itself was sound
## (a stall or a spent time budget is a finding and still exits 0), 1 on an action, engine or contract error,
## 2 on bad arguments or an unusable output folder.

const RunSession:=preload("res://addons/player_profiles/core/run_session.gd")
const Integration:=preload("res://tests/playtest/lootfarmer/lf_integration.gd")
const PROFILES_FILE:="res://tests/playtest/profiles.json"
const FINGERPRINT_FILES:=["res://data/game/catalog.json","res://resources/game/enemy_abilities.tres","res://resources/game/fog_rules.tres",
    "res://resources/game/onboarding_rules.tres","res://resources/game/mastery_rules.tres"]
const Driver:=preload("res://tests/playtest/playtest_driver.gd")
const Recorder:=preload("res://tests/playtest/playtest_recorder.gd")
const Adapter:=preload("res://tests/playtest/lootfarmer_adapter.gd")
const Schedule:=preload("res://tests/playtest/session_schedule.gd")

func arg(key: String,default):
    for value in OS.get_cmdline_user_args():
        if value=="--"+key:return "1"
        if value.begins_with("--"+key+"="):return value.split("=",true,1)[1]
    return default

func _ready() -> void:call_deferred("run")

func run() -> void:
    var policy_set:=str(arg("policy-set","framework"))
    if policy_set=="legacy":run_legacy()
    elif policy_set=="framework":run_framework()
    else:fail(2,"--policy-set must be framework or legacy")

## The reusable framework: universal profile + engine, LootFarmer integration.
func run_framework() -> void:
    var o:=RunSession.options_from_args(OS.get_cmdline_user_args())
    if not str(o.until) in ["duration","calendar","first-prestige"]:
        fail(2,"--until must be duration, calendar or first-prestige");return
    var integration=Integration.new()
    var problem: String=integration.prepare(self,o)
    if problem!="":
        fail(2,problem);return
    o["process_extra"]={"save_profile":BootContext.profile_name,"profile_precleaned":integration.precleaned}
    var result:=RunSession.execute(integration,o,self)
    integration.cleanup()
    if str(result.error)!="" and result.summary.is_empty():
        fail(int(result.exit),str(result.error));return
    print(str(result.summary.get("_sentinel","PLAYTEST_RESULT ok=false stop=%s" % str(result.summary.get("stop_reason","?")))))
    get_tree().quit(int(result.exit))

func fail(code: int,text: String) -> void:
    print("PLAYTEST_RESULT ok=false stop=engine_failure detail=",text)
    get_tree().quit(code)

## The frozen Phase 1/2 baseline (unchanged code path).
func run_legacy() -> void:
    var profile:=str(arg("player-profile","active"))
    var output:=str(arg("output",""))
    var registry=JSON.parse_string(FileAccess.get_file_as_string(PROFILES_FILE))
    if not registry is Dictionary or not registry.has(profile) or profile.begins_with("_"):
        fail(2,"unknown player profile "+profile);return
    var entry: Dictionary=registry[profile]
    if output=="":
        fail(2,"--output is required");return
    if not BootContext.profile_name.begins_with("probe-pp-"):
        fail(2,"run with --profile=probe-pp-<id> (an isolated save namespace)");return
    var recorder=Recorder.new()
    if not recorder.open(output,str(arg("trace",""))!=""):
        fail(2,"cannot write to "+output);return
    # Isolation: this namespace must start empty. A leftover from an interrupted run is removed and the
    # save service reloads (now "new") before the simulation exists.
    var precleaned:=false
    if SaveService.last_load_result!="new":
        precleaned=true
        _wipe_profile()
        SaveService.load_and_apply()
    SaveService.write_blocked=false
    get_tree().paused=false
    var seed_value:=int(arg("seed",1))
    var sim=load("res://scripts/game/simulation.gd").new()
    add_child(sim);sim.set_physics_process(false)
    var adapter=Adapter.new()
    var driver=Driver.new()
    adapter.setup(sim,recorder,seed_value,driver.start_unix)
    var policy=load(str(entry.policy)).new()
    policy.setup(adapter)
    var version:=str(policy.policy_version()) if policy.has_method("policy_version") else str(policy.VERSION)
    driver.adapter=adapter;driver.policy=policy;driver.recorder=recorder
    driver.until=str(arg("until","duration"))
    if not driver.until in ["duration","calendar","first-prestige"]:
        fail(2,"--until must be duration, calendar or first-prestige");return
    driver.decision_interval=float(policy.DECISION)
    if driver.until=="duration":driver.active_limit=float(arg("active-minutes",60))*60.0
    elif driver.until=="calendar":
        driver.calendar_limit=float(arg("calendar-hours",24))*3600.0
        driver.active_limit=float(arg("max-active-minutes",-1))*60.0 if float(arg("max-active-minutes",-1))>0 else INF
    else:
        driver.active_limit=float(arg("max-active-minutes",240))*60.0
        driver.calendar_limit=float(arg("max-calendar-hours",0))*3600.0
    driver.max_wall_seconds=float(arg("max-wall-seconds",600))
    var schedule_config:=_schedule_config(entry,driver.until)
    if schedule_config.is_empty():
        fail(2,"bad schedule options");return
    var schedule=Schedule.new()
    schedule.setup(schedule_config,seed_value,profile)
    driver.schedule=schedule
    driver.stall_seconds=float(arg("stall-minutes",30 if schedule.continuous() else 0))*60.0
    var fingerprint:=_fingerprint()
    var policy_hash:=_policy_hash(entry)
    recorder.event("run_config",{"profile":profile,"policy_version":version,"policy_sha256":policy_hash,"seed":seed_value,
        "content_fingerprint":fingerprint,"onboarding_mode":"none","evidence_class":"natural fresh-save playthrough"})
    var stop: String=driver.run()
    var state_digest: String=adapter.state_digest()
    var events_digest: String=recorder.digest()
    var summary: Dictionary={"schema":2,"policy_set":"legacy","profile":profile,"policy_version":version,"policy_sha256":policy_hash,"seed":seed_value,
        "content_fingerprint":fingerprint,"evidence_class":"natural fresh-save playthrough","onboarding_mode":"none",
        "until":driver.until,"stop_reason":stop,"ok":driver.ok(),
        "active_seconds":snappedf(driver.active,.1),"offline_seconds":snappedf(driver.offline,.1),"calendar_seconds":snappedf(driver.active+driver.offline,.1),
        "virtual_start_unix":driver.start_unix,"steps":driver.steps,
        "horizon":{"until":driver.until,"active_limit_s":driver.active_limit if is_finite(driver.active_limit) else null,"calendar_limit_s":driver.calendar_limit if driver.calendar_limit>0 else null},
        "schedule":schedule.describe(),"sessions":driver.sessions,"session_count":driver.sessions.size() if not schedule.continuous() else 1,
        "away_at_stop_s":snappedf(driver.away_at_stop,.1),"progress_gaps":driver.gaps,"gap_report_s":driver.gap_report,
        "longest_stall":{"seconds":snappedf(float(driver.longest_stall.seconds),.1),"from_s":snappedf(float(driver.longest_stall.from),.1),"to_s":snappedf(float(driver.longest_stall.to),.1)},
        "open_stall_seconds":snappedf(driver.stall_open,.1),
        "events":recorder.count,"events_sha256":events_digest,"state_sha256":state_digest,
        "game":adapter.summary(),
        # Volatile process facts: excluded from every determinism comparison.
        "process":{"wall_seconds":snappedf(driver.wall_seconds,.01),"speed_x":snappedf(driver.active/maxf(.001,driver.wall_seconds),.1),"save_profile":BootContext.profile_name,
            "profile_precleaned":precleaned,"godot":Engine.get_version_info().string}}
    var file:=FileAccess.open(output.path_join("summary.json"),FileAccess.WRITE)
    if file==null:
        fail(2,"cannot write summary.json");return
    file.store_string(JSON.stringify(summary,"  ",false));file.close()
    adapter.teardown()
    _wipe_profile()
    print("PLAYTEST_RESULT ok=%s stop=%s profile=%s seed=%d active_min=%.1f calendar_h=%.2f sessions=%d wall_s=%.1f level=%d stage=%d prestiges=%d deaths=%d events_sha=%s state_sha=%s" % [
        "true" if driver.ok() else "false",stop,profile,seed_value,driver.active/60.0,driver.calendar()/3600.0,int(summary.session_count),driver.wall_seconds,adapter.level(),adapter.stage(),adapter.prestiges(),adapter.deaths.size(),
        events_digest.substr(0,16),state_digest.substr(0,16)])
    get_tree().quit(0 if driver.ok() else 1)

## The schedule: the profile's default (Active uses its calendar schedule for a calendar horizon), or
## continuous/calendar by name, with any field overridden from the command line. {} on a bad option.
func _schedule_config(entry: Dictionary,until: String) -> Dictionary:
    var which:=str(arg("schedule","default"))
    var config: Dictionary
    match which:
        "default":
            config=entry.get("schedule",{"mode":"continuous"})
            if until=="calendar" and str(config.get("mode","continuous"))=="continuous" and entry.has("calendar_schedule"):config=entry.calendar_schedule
        "continuous":config={"mode":"continuous"}
        "calendar":config=entry.get("calendar_schedule",{})
        _:return {}
    config=config.duplicate(true)
    if config.is_empty():return {}
    var minutes=arg("session-minutes",null)
    if minutes!=null:
        var parts:=str(minutes).split("-")
        config["session_minutes"]=[float(parts[0]),float(parts[parts.size()-1])]
    var slots=arg("slots",null)
    if slots!=null:
        var list: Array=[]
        for item in str(slots).split(","):
            var bits:=item.split("@")
            list.append({"hour":float(bits[0]),"chance":float(bits[1]) if bits.size()>1 else 1.0})
        config["slots"]=list
    for pair in [["jitter-minutes","jitter_minutes"],["min-gap-minutes","min_gap_minutes"],["grace-seconds","end_grace_seconds"]]:
        if arg(pair[0],null)!=null:config[pair[1]]=float(arg(pair[0],0))
    if arg("return-mode",null)!=null:
        if not str(arg("return-mode","")) in ["cold","warm"]:return {}
        config["return_mode"]=str(arg("return-mode",""))
    if str(config.get("mode","continuous"))=="sessions" and (config.get("slots",[]).is_empty() or not config.has("session_minutes")):return {}
    return config

## One identity for every script the profile's decisions come from (a subclass and the policies it extends).
func _policy_hash(entry: Dictionary) -> String:
    var files: Array=entry.get("hash_files",[entry.policy])
    if files.size()==1:return FileAccess.get_sha256(str(files[0]))
    var context:=HashingContext.new()
    context.start(HashingContext.HASH_SHA256)
    for path in files:context.update(FileAccess.get_sha256(str(path)).to_utf8_buffer())
    return context.finish().hex_encode()

func _fingerprint() -> String:
    var context:=HashingContext.new()
    context.start(HashingContext.HASH_SHA256)
    for path in FINGERPRINT_FILES:context.update(FileAccess.get_sha256(path).to_utf8_buffer())
    return context.finish().hex_encode()

## Removes this run's isolated save files. Only ever touches user://profiles/probe-pp-*.
func _wipe_profile() -> void:
    if not BootContext.profile_name.begins_with("probe-pp-"):return
    SaveService.write_blocked=true
    var directory:=BootContext.save_directory()
    var dir:=DirAccess.open(directory)
    if dir==null:return
    for name in dir.get_files():dir.remove(name)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
