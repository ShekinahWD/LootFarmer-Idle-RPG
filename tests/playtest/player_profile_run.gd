extends Node
## Player-profile playtest run (Phase 1): one policy playing the real LootSimulation from a fresh,
## isolated profile. Non-gating: never part of tools/run_probes.py. Run it through
## tools/player_profile_run.py, which adds the process watchdog and builds the reports.
##
##   godot --headless --path . res://tests/playtest/player_profile_run.tscn -- --probe --no-autosave
##         --profile=probe-pp-<id> --player-profile=active --seed=1 --active-minutes=60
##         [--until=first-prestige --max-active-minutes=240] [--max-wall-seconds=600] [--stall-minutes=30]
##         [--trace] --output=<absolute folder under tests/tmp/player_profiles/>
##
## Last line: PLAYTEST_RESULT ok=<true|false> stop=<reason> ... Exit code 0 when the run itself was sound
## (a stall or a spent time budget is a finding and still exits 0), 1 on an action or engine error,
## 2 on bad arguments or an unusable output folder.
## Add a profile by adding its policy script to PROFILES; the driver and the adapter do not change.

const PROFILES:={"active":"res://tests/playtest/policies/active_policy.gd"}
const FINGERPRINT_FILES:=["res://data/game/catalog.json","res://resources/game/enemy_abilities.tres","res://resources/game/fog_rules.tres",
    "res://resources/game/onboarding_rules.tres","res://resources/game/mastery_rules.tres"]
const Driver:=preload("res://tests/playtest/playtest_driver.gd")
const Recorder:=preload("res://tests/playtest/playtest_recorder.gd")
const Adapter:=preload("res://tests/playtest/lootfarmer_adapter.gd")

func arg(key: String,default):
    for value in OS.get_cmdline_user_args():
        if value=="--"+key:return "1"
        if value.begins_with("--"+key+"="):return value.split("=",true,1)[1]
    return default

func _ready() -> void:call_deferred("run")

func fail(code: int,text: String) -> void:
    print("PLAYTEST_RESULT ok=false stop=engine_failure detail=",text)
    get_tree().quit(code)

func run() -> void:
    var profile:=str(arg("player-profile","active"))
    var output:=str(arg("output",""))
    if not PROFILES.has(profile):
        fail(2,"unknown player profile "+profile);return
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
    var policy=load(PROFILES[profile]).new()
    policy.setup(adapter)
    driver.adapter=adapter;driver.policy=policy;driver.recorder=recorder
    driver.until=str(arg("until","duration"))
    driver.decision_interval=float(policy.DECISION)
    if driver.until=="duration":driver.active_limit=float(arg("active-minutes",60))*60.0
    else:driver.active_limit=float(arg("max-active-minutes",240))*60.0
    driver.max_wall_seconds=float(arg("max-wall-seconds",600))
    driver.stall_seconds=float(arg("stall-minutes",30))*60.0
    var fingerprint:=_fingerprint()
    var policy_hash:=FileAccess.get_sha256(PROFILES[profile])
    recorder.event("run_config",{"profile":profile,"policy_version":str(policy.VERSION),"policy_sha256":policy_hash,"seed":seed_value,
        "content_fingerprint":fingerprint,"onboarding_mode":"none","evidence_class":"natural fresh-save playthrough"})
    var stop: String=driver.run()
    var state_digest: String=adapter.state_digest()
    var events_digest: String=recorder.digest()
    var summary: Dictionary={"schema":1,"profile":profile,"policy_version":str(policy.VERSION),"policy_sha256":policy_hash,"seed":seed_value,
        "content_fingerprint":fingerprint,"evidence_class":"natural fresh-save playthrough","onboarding_mode":"none",
        "until":driver.until,"stop_reason":stop,"ok":driver.ok(),
        "active_seconds":snappedf(driver.active,.1),"offline_seconds":snappedf(driver.offline,.1),"calendar_seconds":snappedf(driver.active+driver.offline,.1),
        "virtual_start_unix":driver.start_unix,"steps":driver.steps,
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
    print("PLAYTEST_RESULT ok=%s stop=%s profile=%s seed=%d active_min=%.1f wall_s=%.1f level=%d stage=%d prestiges=%d deaths=%d events_sha=%s state_sha=%s" % [
        "true" if driver.ok() else "false",stop,profile,seed_value,driver.active/60.0,driver.wall_seconds,adapter.level(),adapter.stage(),adapter.prestiges(),adapter.deaths.size(),
        events_digest.substr(0,16),state_digest.substr(0,16)])
    get_tree().quit(0 if driver.ok() else 1)

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
