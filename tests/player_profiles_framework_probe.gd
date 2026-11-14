extends Node
## LootFarmer x Player Profiles framework probe (fast, deterministic; part of tools/run_probes.py).
## Guards the LootFarmer integration of the reusable package (res://addons/player_profiles/):
##   A. the LootFarmer adapter satisfies player-profiles.contract/1 and every option it offers is valid;
##   B. all seven universal profiles play the real LootSimulation for 3 active minutes without errors;
##   C. the same seed replays to the same event log and state digest; another seed differs;
##   D. from one identical game state the profiles rank options differently;
##   E. sessions: cold returns reload the progression, offline time is settled by the game and claimed
##      through the engine's own claim decision; warm returns too;
##   F. the clock seam is off again after teardown (production default).
## The package's own cross-game acceptance test is player_profiles_selftest (Farmstead fixture).
## Usage: godot --headless --path . res://tests/player_profiles_framework_probe.tscn -- --probe --profile=probe-x --no-autosave

const Framework:=preload("res://addons/player_profiles/core/framework.gd")
const Library:=preload("res://addons/player_profiles/core/profile_library.gd")
const DecisionEngine:=preload("res://addons/player_profiles/core/decision_engine.gd")
const Driver:=preload("res://addons/player_profiles/core/driver.gd")
const Recorder:=preload("res://addons/player_profiles/core/recorder.gd")
const Schedule:=preload("res://addons/player_profiles/core/session_schedule.gd")
const Check:=preload("res://addons/player_profiles/core/contract_check.gd")
const Runtime:=preload("res://tests/playtest/lootfarmer_adapter.gd")
const LFAdapter:=preload("res://tests/playtest/lootfarmer/lf_adapter.gd")
const PROFILES:=["active","casual","idle","beginner","collector","speedrunner","completionist"]

var checks:=0
var failures:=0
var lib

func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        print("PLAYER_PROFILES_FRAMEWORK_PROBE FAIL: ",label)

func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(400.0,true,false,true).timeout.connect(func():print("PLAYER_PROFILES_FRAMEWORK_PROBE watchdog");get_tree().quit(2))
    lib=Library.new()
    check(lib.errors.is_empty(),"the universal presets validate")
    section_contract()
    section_profiles()
    section_determinism()
    section_same_state()
    section_sessions()
    print("PLAYER_PROFILES_FRAMEWORK_PROBE checks=%d failures=%d" % [checks,failures])
    if failures==0:print("PLAYER_PROFILES_FRAMEWORK_PROBE PASS")
    get_tree().quit(1 if failures else 0)

func folder(tag: String) -> String:
    var f:=ProjectSettings.globalize_path("res://tests/tmp/player_profiles/_framework_probe/"+tag)
    DirAccess.make_dir_recursive_absolute(f)
    var marker:=FileAccess.open(ProjectSettings.globalize_path("res://tests/tmp/player_profiles/.gdignore"),FileAccess.WRITE)
    if marker!=null:marker.close()
    return f

## A LootFarmer adapter on a fresh simulation (the same construction as lf_integration.gd).
func make(seed_value: int,tag: String,start: float=1767600000.0) -> Dictionary:
    var sim=load("res://scripts/game/simulation.gd").new()
    add_child(sim);sim.set_physics_process(false)
    SaveService.write_blocked=false
    get_tree().paused=false
    var rec=Recorder.new()
    rec.open(folder(tag),false)
    var rt=Runtime.new()
    rt.setup(sim,rec,seed_value,start)
    var ad=LFAdapter.new()
    ad.setup(rt)
    return {"sim":sim,"rec":rec,"rt":rt,"adapter":ad}

func play(profile: String,seed_value: int,tag: String,minutes: float,schedule_cfg: Dictionary={},calendar_h: float=0.0) -> Dictionary:
    var m:=make(seed_value,tag)
    var p: Dictionary=lib.resolve(profile)
    m.adapter.configure(p)
    var engine=DecisionEngine.new()
    engine.setup(p,m.adapter,m.rec,seed_value)
    var driver=Driver.new()
    driver.adapter=m.adapter;driver.engine=engine;driver.recorder=m.rec
    var schedule=Schedule.new()
    schedule.setup(schedule_cfg if not schedule_cfg.is_empty() else {"mode":"continuous"},seed_value,profile)
    driver.schedule=schedule
    if calendar_h>0.0:
        driver.until="calendar";driver.calendar_limit=calendar_h*3600.0;driver.active_limit=INF;driver.stall_seconds=0.0
    else:
        driver.active_limit=minutes*60.0
    driver.max_wall_seconds=120.0
    var stop: String=driver.run()
    m["stop"]=stop;m["driver"]=driver;m["engine"]=engine
    m["events"]=m.rec.digest();m["state"]=m.adapter.state_digest()
    m["folder"]=folder(tag)
    return m

func done(m: Dictionary) -> void:
    m.adapter.teardown()
    check(m.sim.clock_override<0,"teardown clears the clock seam")
    m.sim.queue_free()

func events(path: String) -> Array:
    var out: Array=[]
    for line in FileAccess.get_file_as_string(path.path_join("events.jsonl")).split("\n",false):out.append(JSON.parse_string(line))
    return out

# A. Contract.
func section_contract() -> void:
    var m:=make(1,"contract")
    check(Check.check_adapter(m.adapter).is_empty(),"the LootFarmer adapter satisfies the contract: "+"; ".join(Check.check_adapter(m.adapter)))
    var caps: Dictionary=m.adapter.capabilities()
    var supported:=0
    for i in Framework.INTENTS:
        if bool(caps.intents[i].supported):supported+=1
    check(supported==Framework.INTENTS.size(),"LootFarmer supports all eleven generic intents")
    m.adapter.configure(lib.resolve("active"))
    var bad:=0
    var intents: Dictionary={}
    for o in m.adapter.options():
        if Check.check_option(o,caps)!="":bad+=1
        intents[str(o.intent)]=true
    check(bad==0,"every option offered on a new profile is valid")
    check(intents.has("explore") and intents.has("wait"),"a new profile can explore and wait")
    var obs: Dictionary=m.adapter.observe()
    check(float(obs.health)>0.0 and float(obs.area_completion)>=0.0 and float(obs.collection_completion)>=0.0,"observation values are measured, not unsupported")
    var r: Dictionary=m.adapter.begin({"id":"up:focus:-1","intent":"invest_automation","kind":"instant"})
    check(str(r.status)=="rejected" and str(r.reason)=="NOT_ENOUGH_GEMS","an unaffordable purchase is refused with the game's own reason (%s)" % str(r.reason))
    r=m.adapter.begin({"id":"teleport","intent":"wait","kind":"instant"})
    check(str(r.status)=="rejected","an action the game does not have is rejected")
    done(m)

# B. Seven profiles on the real simulation.
func section_profiles() -> void:
    var by: Dictionary={}
    for p in PROFILES:
        var m:=play(p,1,"p_"+p,3.0)
        check(str(m.stop)=="duration_reached","%s plays 3 active minutes (%s)" % [p,str(m.stop)])
        var s: Dictionary=m.engine.summary()
        check(int(s.decisions)>0 and int(s.invalid_options)==0,"%s decides with only valid options" % p)
        check(int(m.rt.summary().kills_total)>0,"%s defeats enemies through real combat" % p)
        check(events(str(m.folder)).filter(func(e):return str(e.type)=="action_error").is_empty(),"%s has no action error" % p)
        by[p]=s
        done(m)
    check(float(by.casual.deliberations)<float(by.active.deliberations) and float(by.idle.deliberations)<float(by.casual.deliberations),"attention orders deliberations: Active > Casual > Idle")

# C. Determinism.
func section_determinism() -> void:
    var a:=play("beginner",4,"det_a",3.0)
    var b:=play("beginner",4,"det_b",3.0)
    var c:=play("beginner",5,"det_c",3.0)
    check(str(a.events)==str(b.events) and str(a.state)==str(b.state),"same seed: identical event log and final state")
    check(str(a.state)!=str(c.state),"another seed gives another playthrough")
    for m in [a,b,c]:done(m)

# D. One game state, seven rankings.
func section_same_state() -> void:
    var m:=play("active",7,"same",4.0)
    var rankings: Dictionary={}
    for p in PROFILES:
        var e=DecisionEngine.new()
        var prof: Dictionary=lib.resolve(p)
        e.setup(prof,m.adapter,m.rec,7)
        var top: Array=[]
        for c in e.preview():
            if c.refusal=="" and top.size()<5:top.append(c.id)
        rankings[",".join(top)]=p
    check(rankings.size()>=4,"from one LootFarmer state the seven profiles rank their top options at least four different ways (%d)" % rankings.size())
    done(m)

# E. Sessions with cold and warm returns.
func section_sessions() -> void:
    for mode in ["cold","warm"]:
        var cfg:={"mode":"sessions","session_minutes":[1,1],"slots":[{"hour":8.2,"chance":1.0},{"hour":20.0,"chance":1.0}],
            "jitter_minutes":0,"min_gap_minutes":0,"end_grace_seconds":60,"return_mode":mode}
        var m:=play("casual",3,"sess_"+mode,0.0,cfg,26.0)
        var d=m.driver
        var ev:=events(str(m.folder))
        check(str(m.stop)=="calendar_reached","%s: the calendar horizon ends the run" % mode)
        check(absf(d.calendar()-(d.active+d.offline))<.01 and d.sessions.size()==4,"%s: four sessions; calendar = active + offline" % mode)
        check(ev.filter(func(e):return str(e.type)=="action_error").is_empty(),"%s: every return reloads the progression intact" % mode)
        var settled:=ev.filter(func(e):return str(e.type)=="offline_settled").size()
        var claims:=ev.filter(func(e):return str(e.type)=="decision" and str(e.get("option",""))=="claim_offline" and str(e.status)=="done").size()
        check(settled==3 and claims==3 and int(m.rt.offline.claims)==3,"%s: each absence is settled by the game and claimed once through the engine (%d/%d)" % [mode,settled,claims])
        check(m.sim.state.offline_pending.is_empty(),"%s: nothing stays pending" % mode)
        done(m)
