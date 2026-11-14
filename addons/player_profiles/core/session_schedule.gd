extends RefCounted
## Player Profiles framework: the session schedule (extracted unchanged from the first integration).
## Game-independent. Decides when a simulated player opens the game and for how much active time, on a
## virtual calendar. It owns its own random stream (seeded from the run seed and the profile name), so the
## schedule never draws from the game's random numbers and the same seed and config give the same days.
##
## Config (a Dictionary, normally a preset's `sessions` block in core/profiles.json; every field can be overridden):
##   mode              "continuous" (one session, the Phase 1 behaviour) or "sessions"
##   session_minutes   [min, max]   active minutes of one session, uniform in the range
##   slots             [{"hour": 8.5, "chance": 1.0}, ...]   local hours (virtual UTC) a session may start;
##                                  `chance` is the probability that this slot is played on a given day
##   jitter_minutes    each start moves by up to this many minutes either way
##   min_gap_minutes   a slot closer than this to the end of the previous session is skipped
##   end_grace_seconds active seconds a session may run past its length to finish a fight or a transaction
##   first_session     "now": the first session starts at calendar 0 (installing the game), whatever the slots
##   return_mode       "cold" (the app was closed: the next session loads the save file) or "warm" (resumed)
## Session 1 starts at calendar second 0. The virtual day starts at `day_zero_offset` seconds before the
## run's start time (the run starts at 08:00, so the day began 8 hours earlier).

var config: Dictionary={}
var mode:="continuous"
var rng:=RandomNumberGenerator.new()
var day_zero_offset:=8.0*3600.0
var _planned: Array=[]     # [{start_c, active_s}] in order, generated a day at a time
var _planned_day:=-1

func setup(cfg: Dictionary,seed_value: int,salt: String) -> void:
	config=cfg.duplicate(true)
	mode=str(config.get("mode","continuous"))
	rng.seed=hash("%d|%s|schedule" % [seed_value,salt])

func continuous() -> bool:return mode!="sessions"
func grace() -> float:return float(config.get("end_grace_seconds",120.0))
func return_mode() -> String:return str(config.get("return_mode","cold"))

## Active seconds the first session lasts (calendar 0).
func first_length() -> float:return _length()

## The next session that starts at or after calendar second `after` (the end of the previous one):
## {start_c, active_s}. Days are generated lazily and in order, so the draw sequence is fixed.
func next_after(after: float) -> Dictionary:
	var gap:=maxf(0.0,float(config.get("min_gap_minutes",30.0))*60.0)
	if config.get("slots",[]).is_empty():return {}
	for guard in range(100000):
		var days:=0
		while _planned.is_empty() and days<400:
			_plan_day(_planned_day+1);days+=1
		if _planned.is_empty():return {}
		var s: Dictionary=_planned.pop_front()
		if float(s.start_c)>=after+gap:return s
	return {}

## Plans one virtual day (day 0 is the run's first day). Every slot draws its chance, jitter and length
## whether or not it is used, so one skipped slot never shifts the draws of the next ones.
func _plan_day(day: int) -> void:
	_planned_day=day
	var slots: Array=config.get("slots",[])
	var jitter:=float(config.get("jitter_minutes",0.0))*60.0
	for slot in slots:
		var roll:=rng.randf()
		var shift:=rng.randf_range(-jitter,jitter)
		var length:=_length()
		if roll>=float(slot.get("chance",1.0)):continue
		var start:=day*86400.0+float(slot.hour)*3600.0+shift-day_zero_offset
		if start<=0.0:continue
		_planned.append({"start_c":start,"active_s":length})
	_planned.sort_custom(func(x,y):return float(x.start_c)<float(y.start_c))

func _length() -> float:
	var span: Array=config.get("session_minutes",[20,20])
	return rng.randf_range(float(span[0]),float(span[span.size()-1]))*60.0

## Plain description for the event log and the summary.
func describe() -> Dictionary:
	var out:=config.duplicate(true)
	out["mode"]=mode
	return out
