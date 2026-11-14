extends RefCounted
## Player Profiles framework: the driver. Game-independent.
## Owns the step loop, the separate active / offline / calendar clocks, engine-tick cadence, sessions
## (leave -> virtual time passes -> return), stop conditions, stall detection and the wall-time budget.
## The game comes only through the adapter (core/adapter_base.gd); every decision through the engine.
## A run never loops unbounded: active time, calendar time, wall time and step count are all capped.

const Framework:=preload("framework.gd")

var adapter
var engine
var recorder
var schedule                      # session_schedule.gd; continuous() = one session, no offline time
var start_unix:=1767600000.0      # a fixed virtual start (2026-01-05T08:00:00Z): calendar math never reads the host clock
var until:="duration"             # "duration" (active time), "calendar" (calendar time) or a game goal name
var active_limit:=3600.0
var calendar_limit:=0.0           # 0 = none
var max_wall_seconds:=600.0
var stall_seconds:=1800.0         # 0 = record stalls only
var trace_interval:=30.0
var gap_report:=600.0

var active:=0.0
var offline:=0.0
var steps:=0
var stop_reason:=""
var longest_stall:={"seconds":0.0,"from":0.0,"to":0.0}
var stall_open:=0.0
var wall_seconds:=0.0
var gaps: Array=[]
var sessions: Array=[]
var away_at_stop:=0.0
var _session_active:=0.0
var _session_quota:=INF
var _last_progress_c:=0.0

func virtual_now() -> float:return start_unix+active+offline
func calendar() -> float:return active+offline
func scheduled() -> bool:return schedule!=null and not schedule.continuous()
func ok() -> bool:return bool(Framework.STOPS.get(stop_reason,false))

func run() -> String:
	var started:=Time.get_ticks_msec()
	var step:=float(adapter.step_seconds())
	var tick:=float(adapter.tick_seconds())
	var think:=tick
	var next_trace:=0.0
	var blocked:=0
	var signature: String=adapter.progress_signature()
	var last_progress:=0.0
	var max_steps:=int(ceil(active_limit/step))+10 if is_finite(active_limit) else 2147483647
	var check_every:=maxi(1,int(round(1.0/step)))
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
			think=tick
			continue
		if think>=tick-1e-6:
			think=0.0
			engine.tick(active)
			var error: String=adapter.failed()
			if error!="":
				recorder.event("action_error",{"reason":error});stop_reason="action_error";break
			if until not in ["duration","calendar"] and adapter.goal_reached(until):
				stop_reason="goal_reached";break
		adapter.steer()
		if adapter.step(step):
			active+=step;think+=step;steps+=1;blocked=0;_session_active+=step
		else:
			blocked+=1;think=tick
			if blocked>100:
				recorder.event("engine_blocked",{"detail":adapter.blocked_reason()});stop_reason="engine_failure";break
		if steps%check_every==0:
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
			sample.merge(engine.trace_sample())
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

## The player closes the game, virtual calendar time passes, and the player opens it again (or the horizon
## is reached while away). False when the run must stop.
func _leave_and_return() -> bool:
	engine.on_session_end()
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
	engine.on_session_start()
	var error: String=adapter.failed()
	if error!="":
		recorder.event("action_error",{"reason":error});stop_reason="action_error";return false
	return true

func _close_stall(from: float,to: float) -> void:
	if to-from>float(longest_stall.seconds):longest_stall={"seconds":to-from,"from":from,"to":to}
	if to-from>=gap_report and (gaps.is_empty() or float(gaps[-1].from_t)!=snappedf(from,.1)):
		gaps.append({"from_t":snappedf(from,.1),"to_t":snappedf(to,.1),"from_c":snappedf(_last_progress_c,.1),"to_c":snappedf(calendar(),.1)})
