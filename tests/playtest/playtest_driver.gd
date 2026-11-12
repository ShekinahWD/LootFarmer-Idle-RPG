extends RefCounted
## Player-profile playtesting, reusable part: the driver.
## Game-agnostic: it owns the step loop, the simulated active/offline/calendar clocks, decision
## scheduling, stop conditions, stall detection and the wall-time budget. Everything about the game
## comes through an adapter; every decision through a policy.
##
## Adapter contract (see lootfarmer_adapter.gd):
##   set_clock(unix: float)            the virtual calendar time for the next step
##   step(dt: float) -> bool           one real game step of at most 0.1 s; false when the game did not advance
##   goal_reached(goal: String) -> bool
##   progress_signature() -> String    changes whenever meaningful progression happened
##   trace_sample() -> Dictionary      a cheap diagnosis snapshot
##   failed() -> String                "" or the reason an action error must stop the run
## Policy contract (see policies/active_policy.gd):
##   decide()                          called every decision_interval of active time
##   steer()                           called before every game step (movement only)
##   trace_sample() -> Dictionary
##
## A run never loops unbounded: active time, wall time and step count are all capped.

const STEP:=.1
## Stop classes. `ok` says whether the run itself was sound (a stall or a spent budget is a finding, not a tool failure).
const STOPS:={"duration_reached":true,"first_prestige_completed":true,"goal_reached":true,"stalled":true,
    "time_budget_exceeded":true,"wall_timeout":false,"action_error":false,"engine_failure":false}

var adapter
var policy
var recorder
var start_unix:=1767600000.0      # 2026-01-05T08:00:00Z: a fixed virtual session start
var decision_interval:=.5
var until:="duration"             # "duration" or a goal name the adapter understands
var active_limit:=3600.0          # --active-minutes (duration) or --max-active-minutes (goal runs)
var max_wall_seconds:=600.0
var stall_seconds:=1800.0
var trace_interval:=30.0

var active:=0.0                   # simulated active seconds (the game stepped)
var offline:=0.0                  # simulated offline seconds (none in a continuous-play profile)
var steps:=0
var stop_reason:=""
var longest_stall:={"seconds":0.0,"from":0.0,"to":0.0}
var stall_open:=0.0               # seconds since the last progression change when the run stopped
var wall_seconds:=0.0

func virtual_now() -> float:return start_unix+active+offline

func run() -> String:
    var started:=Time.get_ticks_msec()
    var think:=decision_interval
    var next_trace:=0.0
    var blocked:=0
    var signature: String=adapter.progress_signature()
    var last_progress:=0.0
    var max_steps:=int(ceil(active_limit/STEP))+10
    recorder.event("run_started",{"until":until,"active_limit_s":active_limit,"stall_limit_s":stall_seconds})
    while stop_reason=="":
        recorder.active=active;recorder.virtual_unix=virtual_now()
        adapter.set_clock(virtual_now())
        if think>=decision_interval-1e-6:
            think=0.0
            policy.decide()
            var error: String=adapter.failed()
            if error!="":
                recorder.event("action_error",{"reason":error});stop_reason="action_error";break
            if until!="duration" and adapter.goal_reached(until):
                stop_reason="first_prestige_completed" if until=="first-prestige" else "goal_reached";break
        policy.steer()
        if adapter.step(STEP):
            active+=STEP;think+=STEP;steps+=1;blocked=0
        else:
            # The game refused to advance (paused, suspended, an unfinished Prestige choice). A policy must
            # resolve that inside decide(); a hundred refused steps in a row is a harness or engine fault.
            blocked+=1;think=decision_interval
            if blocked>100:
                recorder.event("engine_blocked",{"detail":adapter.blocked_reason()});stop_reason="engine_failure";break
        if steps%10==0:
            var now_signature: String=adapter.progress_signature()
            if now_signature!=signature:
                _close_stall(last_progress,active)
                signature=now_signature;last_progress=active
            elif active-last_progress>=stall_seconds:
                _close_stall(last_progress,active)
                recorder.event("stalled",{"since_t":snappedf(last_progress,.1),"minutes":snappedf((active-last_progress)/60.0,.1)})
                stop_reason="stalled";break
        if active>=next_trace:
            next_trace=active+trace_interval
            var sample: Dictionary=adapter.trace_sample()
            sample.merge(policy.trace_sample())
            recorder.trace(sample)
        if active>=active_limit-1e-6 or steps>=max_steps:
            stop_reason="duration_reached" if until=="duration" else "time_budget_exceeded";break
        if steps%200==0 and (Time.get_ticks_msec()-started)/1000.0>max_wall_seconds:
            stop_reason="wall_timeout";break
    _close_stall(last_progress,active)
    stall_open=active-last_progress
    wall_seconds=(Time.get_ticks_msec()-started)/1000.0
    recorder.active=active;recorder.virtual_unix=virtual_now()
    recorder.event("run_stopped",{"stop_reason":stop_reason,"active_s":snappedf(active,.1),"steps":steps})
    if stop_reason in ["stalled","time_budget_exceeded","wall_timeout","action_error","engine_failure"]:recorder.dump_ring()
    recorder.flush()
    return stop_reason

func _close_stall(from: float,to: float) -> void:
    if to-from>float(longest_stall.seconds):longest_stall={"seconds":to-from,"from":from,"to":to}

func ok() -> bool:return bool(STOPS.get(stop_reason,false))
