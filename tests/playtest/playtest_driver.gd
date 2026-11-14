extends RefCounted
## Player-profile playtesting, reusable part: the driver.
## Game-agnostic: it owns the step loop, the simulated active/offline/calendar clocks, decision
## scheduling, sessions (Phase 2), stop conditions, stall detection and the wall-time budget. Everything
## about the game comes through an adapter; every decision through a policy.
##
## Adapter contract (see lootfarmer_adapter.gd):
##   set_clock(unix: float)            the virtual calendar time for the next step
##   step(dt: float) -> bool           one real game step of at most 0.1 s; false when the game did not advance
##   goal_reached(goal: String) -> bool
##   progress_signature() -> String    changes whenever meaningful progression happened
##   trace_sample() -> Dictionary      a cheap diagnosis snapshot
##   failed() -> String                "" or the reason an action error must stop the run
##   Sessions only (Phase 2):
##   session_can_end() -> bool         nothing is in progress that a player would finish before closing the game
##   leave_session(n: int)             the player closes the game (the game's own background/save path)
##   return_session(n, away_s, mode) -> String   the player opens it again; "" or a persistence failure
##   default_return()                  what any player does on return when the policy has no session_start()
## Policy contract (see policies/active_policy.gd):
##   decide()                          called every decision_interval of active time
##   steer()                           called before every game step (movement only)
##   trace_sample() -> Dictionary
##   optional session_start() / session_end()   called right after a return / right before leaving
##
## Continuous mode (no schedule) is exactly the Phase 1 loop: same calls in the same order, same events.
## A run never loops unbounded: active time, calendar time, wall time and step count are all capped.

const STEP:=.1
## Stop classes. `ok` says whether the run itself was sound (a stall or a spent budget is a finding, not a tool failure).
const STOPS:={"duration_reached":true,"first_prestige_completed":true,"goal_reached":true,"stalled":true,
    "calendar_reached":true,"time_budget_exceeded":true,"wall_timeout":false,"action_error":false,"engine_failure":false}

var adapter
var policy
var recorder
var schedule                      # session_schedule.gd, or null for one continuous session
var start_unix:=1767600000.0      # 2026-01-05T08:00:00Z: a fixed virtual session start
var decision_interval:=.5
var until:="duration"             # "duration" (active time), "calendar" (calendar time) or a goal name
var active_limit:=3600.0          # --active-minutes (duration) or --max-active-minutes (goal/calendar runs)
var calendar_limit:=0.0           # --calendar-hours (calendar) or --max-calendar-hours (goal runs); 0 = none
var max_wall_seconds:=600.0
var stall_seconds:=1800.0         # 0 = record stalls only, never stop on one
var trace_interval:=30.0
var gap_report:=600.0             # progress gaps at least this long (active seconds) are listed in the summary

var active:=0.0                   # simulated active seconds (the game stepped)
var offline:=0.0                  # simulated offline seconds (the game was closed)
var steps:=0
var stop_reason:=""
var longest_stall:={"seconds":0.0,"from":0.0,"to":0.0}
var stall_open:=0.0               # seconds since the last progression change when the run stopped
var wall_seconds:=0.0
var gaps: Array=[]                # [{from_t, to_t, from_c, to_c}] progress gaps >= gap_report
var sessions: Array=[]            # [{n, start_c, end_c, active_s, planned_s, away_before_s}]
var away_at_stop:=0.0             # offline seconds of an absence the horizon cut short (not yet returned)
var _session_active:=0.0
var _session_quota:=INF
var _last_progress_c:=0.0

func virtual_now() -> float:return start_unix+active+offline
func calendar() -> float:return active+offline
func scheduled() -> bool:return schedule!=null and not schedule.continuous()

func run() -> String:
    var started:=Time.get_ticks_msec()
    var think:=decision_interval
    var next_trace:=0.0
    var blocked:=0
    var signature: String=adapter.progress_signature()
    var last_progress:=0.0
    var max_steps:=int(ceil(active_limit/STEP))+10 if is_finite(active_limit) else 2147483647
    recorder.event("run_started",{"until":until,"active_limit_s":active_limit if is_finite(active_limit) else -1.0,"stall_limit_s":stall_seconds})
    if scheduled():
        recorder.virtual_unix=virtual_now()
        _session_quota=schedule.first_length()
        recorder.event("schedule",{"config":schedule.describe(),"calendar_limit_s":calendar_limit})
        sessions.append({"n":0,"start_c":0.0,"end_c":-1.0,"active_s":0.0,"planned_s":snappedf(_session_quota,.1),"away_before_s":0.0})
        recorder.event("session_started",{"session":0,"planned_active_s":snappedf(_session_quota,.1),"away_s":0.0})
    while stop_reason=="":
        recorder.active=active;recorder.virtual_unix=virtual_now()
        adapter.set_clock(virtual_now())
        if scheduled() and _session_active>=_session_quota-1e-6 and (adapter.session_can_end() or _session_active>=_session_quota+schedule.grace()):
            if not _leave_and_return():break
            think=decision_interval
            continue
        if think>=decision_interval-1e-6:
            think=0.0
            policy.decide()
            var error: String=adapter.failed()
            if error!="":
                recorder.event("action_error",{"reason":error});stop_reason="action_error";break
            if until not in ["duration","calendar"] and adapter.goal_reached(until):
                stop_reason="first_prestige_completed" if until=="first-prestige" else "goal_reached";break
        policy.steer()
        if adapter.step(STEP):
            active+=STEP;think+=STEP;steps+=1;blocked=0;_session_active+=STEP
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
                signature=now_signature;last_progress=active;_last_progress_c=calendar()
            elif stall_seconds>0.0 and active-last_progress>=stall_seconds:
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
        if calendar_limit>0.0 and calendar()>=calendar_limit-1e-6:
            stop_reason="calendar_reached" if until=="calendar" else "time_budget_exceeded";break
        if steps%200==0 and (Time.get_ticks_msec()-started)/1000.0>max_wall_seconds:
            stop_reason="wall_timeout";break
    _close_stall(last_progress,active)
    stall_open=active-last_progress
    wall_seconds=(Time.get_ticks_msec()-started)/1000.0
    recorder.active=active;recorder.virtual_unix=virtual_now()
    if scheduled() and not sessions.is_empty() and float(sessions[-1].end_c)<0.0:
        sessions[-1].end_c=snappedf(calendar(),.1);sessions[-1].active_s=snappedf(_session_active,.1)
    recorder.event("run_stopped",{"stop_reason":stop_reason,"active_s":snappedf(active,.1),"steps":steps})
    if stop_reason in ["stalled","time_budget_exceeded","wall_timeout","action_error","engine_failure"]:recorder.dump_ring()
    recorder.flush()
    return stop_reason

## The player closes the game, the virtual calendar runs while it is closed, and the player opens it again
## (or the horizon is reached while away). False when the run must stop.
func _leave_and_return() -> bool:
    if policy.has_method("session_end"):policy.session_end()
    var ended:=calendar()
    sessions[-1].end_c=snappedf(ended,.1);sessions[-1].active_s=snappedf(_session_active,.1)
    recorder.event("session_ended",{"session":int(sessions[-1].n),"active_s":snappedf(_session_active,.1)})
    adapter.leave_session(int(sessions[-1].n))
    var next: Dictionary=schedule.next_after(ended)
    var horizon:=calendar_limit>0.0 and (next.is_empty() or float(next.start_c)>=calendar_limit)
    if next.is_empty() and not horizon:
        recorder.event("action_error",{"reason":"schedule has no next session"});stop_reason="action_error";return false
    var arrive: float=calendar_limit if horizon else float(next.start_c)
    var away:=maxf(0.0,arrive-ended)
    offline+=away
    recorder.active=active;recorder.virtual_unix=virtual_now()
    adapter.set_clock(virtual_now())
    if horizon:
        away_at_stop=away
        recorder.event("away_at_horizon",{"away_s":snappedf(away,.1)})
        stop_reason="calendar_reached" if until=="calendar" else "time_budget_exceeded"
        return false
    var n:=int(sessions[-1].n)+1
    _session_active=0.0;_session_quota=float(next.active_s)
    var problem: String=adapter.return_session(n,away,schedule.return_mode())
    sessions.append({"n":n,"start_c":snappedf(calendar(),.1),"end_c":-1.0,"active_s":0.0,"planned_s":snappedf(_session_quota,.1),"away_before_s":snappedf(away,.1)})
    recorder.event("session_started",{"session":n,"planned_active_s":snappedf(_session_quota,.1),"away_s":snappedf(away,.1)})
    if problem!="":
        recorder.event("action_error",{"reason":problem});stop_reason="action_error";return false
    if policy.has_method("session_start"):policy.session_start()
    else:adapter.default_return()
    var error: String=adapter.failed()
    if error!="":
        recorder.event("action_error",{"reason":error});stop_reason="action_error";return false
    return true

func _close_stall(from: float,to: float) -> void:
    if to-from>float(longest_stall.seconds):longest_stall={"seconds":to-from,"from":from,"to":to}
    if to-from>=gap_report and (gaps.is_empty() or float(gaps[-1].from_t)!=snappedf(from,.1)):
        gaps.append({"from_t":snappedf(from,.1),"to_t":snappedf(to,.1),"from_c":snappedf(_last_progress_c,.1),"to_c":snappedf(calendar(),.1)})

func ok() -> bool:return bool(STOPS.get(stop_reason,false))
