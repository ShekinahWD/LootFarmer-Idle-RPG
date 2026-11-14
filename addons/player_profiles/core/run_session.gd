extends RefCounted
## Player Profiles framework: one complete run, game-independent.
## resolve profile -> create the game's adapter through its integration -> contract check -> engine + schedule +
## driver -> summary.json (player-profiles.summary/1). Used by the generic runner scene, by a game's own
## runner scene and by probes.
##
## INTEGRATION object (one per game; see INTEGRATION_FOR_CLAUDE.md):
##   info() -> {game, integration_version}
##   prepare(host: Node, options: Dictionary) -> String        isolation (test save namespace, autosave off); "" = ok
##   create_adapter(context: {seed, start_unix, recorder, host}) -> adapter (core/adapter_base.gd contract)
##   fingerprint() -> String                                    content/data fingerprint of the game build
##   cleanup() -> void                                          remove isolated saves, restore global state
##   optional sentinel_extra(adapter) -> String                 extra key=value pairs for the result line
##
## OPTIONS (Dictionary; options_from_args() builds it from the command line):
##   profile, overrides{traits,derived,intent_weights,sessions}, seed, until ("duration"|"calendar"|goal),
##   active_minutes, calendar_hours, max_active_minutes (<=0 none), max_calendar_hours, schedule
##   ("default"|"continuous"|"sessions"), schedule_overrides{}, max_wall_seconds, stall_minutes (-1 = default),
##   trace (bool), output (absolute folder), process_extra{} (volatile facts merged into summary.process)

const Framework:=preload("framework.gd")
const Library:=preload("profile_library.gd")
const DecisionEngine:=preload("decision_engine.gd")
const Driver:=preload("driver.gd")
const Recorder:=preload("recorder.gd")
const Schedule:=preload("session_schedule.gd")
const Check:=preload("contract_check.gd")

## Parses `--key=value` user arguments. Recognized keys are listed in README.md (Runner arguments).
static func options_from_args(args: PackedStringArray) -> Dictionary:
	var raw: Dictionary={}
	for value in args:
		if not value.begins_with("--"):continue
		var kv:=value.substr(2).split("=",true,1)
		raw[kv[0]]=kv[1] if kv.size()>1 else "1"
	var o:={"profile":str(raw.get("player-profile","active")),"seed":int(raw.get("seed","1")),"until":str(raw.get("until","duration")),
		"active_minutes":float(raw.get("active-minutes","60")),"calendar_hours":float(raw.get("calendar-hours","24")),
		"max_active_minutes":float(raw.get("max-active-minutes","-1")),"max_calendar_hours":float(raw.get("max-calendar-hours","0")),
		"schedule":str(raw.get("schedule","default")),"max_wall_seconds":float(raw.get("max-wall-seconds","600")),
		"stall_minutes":float(raw.get("stall-minutes","-1")),"trace":raw.has("trace"),"output":str(raw.get("output","")),
		"overrides":Library.parse_overrides(str(raw.get("override",""))),"schedule_overrides":{},"raw":raw}
	if raw.has("session-minutes"):
		var parts:=str(raw["session-minutes"]).split("-")
		o.schedule_overrides["session_minutes"]=[float(parts[0]),float(parts[parts.size()-1])]
	if raw.has("slots"):
		var list: Array=[]
		for item in str(raw.slots).split(","):
			var bits:=item.split("@")
			list.append({"hour":float(bits[0]),"chance":float(bits[1]) if bits.size()>1 else 1.0})
		o.schedule_overrides["slots"]=list
	for pair in [["jitter-minutes","jitter_minutes"],["min-gap-minutes","min_gap_minutes"],["grace-seconds","end_grace_seconds"]]:
		if raw.has(pair[0]):o.schedule_overrides[pair[1]]=float(raw[pair[0]])
	if raw.has("return-mode"):o.schedule_overrides["return_mode"]=str(raw["return-mode"])
	return o

## Runs one profile. Returns {"summary": Dictionary, "error": String, "exit": int, "adapter": adapter}.
## exit: 0 sound run (a stall or a spent budget is a finding), 1 action/engine/contract error, 2 bad options.
static func execute(integration,o: Dictionary,host: Node=null) -> Dictionary:
	var lib=Library.new()
	if not lib.errors.is_empty():return {"error":"; ".join(lib.errors),"exit":2,"summary":{}}
	if not lib.has(str(o.profile)):return {"error":"unknown player profile "+str(o.profile),"exit":2,"summary":{}}
	if str(o.get("output",""))=="":return {"error":"--output is required","exit":2,"summary":{}}
	if not str(o.until) in ["duration","calendar"] and str(o.until)=="":return {"error":"bad --until","exit":2,"summary":{}}
	var recorder=Recorder.new()
	if not recorder.open(str(o.output),bool(o.get("trace",false))):return {"error":"cannot write to "+str(o.output),"exit":2,"summary":{}}
	var driver=Driver.new()
	var seed_value:=int(o.get("seed",1))
	var adapter=integration.create_adapter({"seed":seed_value,"start_unix":driver.start_unix,"recorder":recorder,"host":host})
	var problems:=Check.check_adapter(adapter)
	var info: Dictionary=integration.info()
	if not problems.is_empty():
		recorder.event("contract_error",{"problems":problems});recorder.flush()
		var bad:={"schema":Framework.SUMMARY_SCHEMA,"profile":o.profile,"seed":seed_value,"stop_reason":"contract_error","ok":false,"contract_problems":problems}
		_write(str(o.output),bad)
		return {"error":"adapter contract: "+"; ".join(problems),"exit":1,"summary":bad,"adapter":adapter}
	var profile: Dictionary=lib.resolve(str(o.profile),o.get("overrides",{}),float(adapter.time_scale()))
	if profile.has("error"):return {"error":str(profile.error),"exit":2,"summary":{},"adapter":adapter}
	var caps: Dictionary=adapter.capabilities()
	var a_info: Dictionary=adapter.integration_info()
	adapter.configure(profile)
	var engine=DecisionEngine.new()
	engine.setup(profile,adapter,recorder,seed_value)
	driver.adapter=adapter;driver.engine=engine;driver.recorder=recorder
	driver.until=str(o.until)
	if driver.until=="duration":driver.active_limit=float(o.active_minutes)*60.0
	elif driver.until=="calendar":
		driver.calendar_limit=float(o.calendar_hours)*3600.0
		driver.active_limit=float(o.max_active_minutes)*60.0 if float(o.max_active_minutes)>0 else INF
	else:
		driver.active_limit=(float(o.max_active_minutes) if float(o.max_active_minutes)>0 else 240.0)*60.0
		driver.calendar_limit=float(o.get("max_calendar_hours",0.0))*3600.0
	driver.max_wall_seconds=float(o.get("max_wall_seconds",600.0))
	var schedule_note:=""
	var config:=schedule_config(profile,str(o.get("schedule","default")),driver.until,o.get("schedule_overrides",{}))
	if config.is_empty():return {"error":"bad schedule options","exit":2,"summary":{},"adapter":adapter}
	if str(config.mode)=="sessions" and not bool(caps.features.get("sessions",false)):
		schedule_note="the game declares no session support: played as one continuous session"
		config={"mode":"continuous"}
	var schedule=Schedule.new()
	schedule.setup(config,seed_value,str(profile.id))
	driver.schedule=schedule
	var stall:=float(o.get("stall_minutes",-1.0))
	driver.stall_seconds=(stall if stall>=0.0 else (30.0 if schedule.continuous() else 0.0))*60.0
	var fingerprint: String=integration.fingerprint()
	var policy_version:="%s-v%s@pp%s+%s" % [profile.id,profile.version,Framework.FRAMEWORK_VERSION,str(a_info.strategy_version)]
	recorder.event("run_config",{"profile":profile.id,"profile_version":profile.version,"profile_sha256":profile.hash,"policy_version":policy_version,
		"framework":Framework.FRAMEWORK_VERSION,"contract":Framework.CONTRACT_VERSION,"game":str(a_info.game),"adapter_version":str(a_info.adapter_version),
		"strategy_version":str(a_info.strategy_version),"seed":seed_value,"content_fingerprint":fingerprint,"schedule_note":schedule_note})
	var stop: String=driver.run()
	var state_digest: String=adapter.state_digest()
	var events_digest: String=recorder.digest()
	var decisions: Dictionary=engine.summary()
	var generic: Dictionary=adapter.generic_metrics()
	var active_h: float=driver.active/3600.0
	generic["decisions_per_active_hour"]=snappedf(float(decisions.decisions)/active_h,.1) if active_h>0 else null
	generic["deliberations_per_active_hour"]=snappedf(float(decisions.deliberations)/active_h,.1) if active_h>0 else null
	generic["sessions"]=driver.sessions.size() if not schedule.continuous() else 1
	var summary: Dictionary={"schema":Framework.SUMMARY_SCHEMA,"summary_compat":3,
		"framework":{"version":Framework.FRAMEWORK_VERSION,"contract":Framework.CONTRACT_VERSION,"profile_schema":Framework.PROFILE_SCHEMA},
		"policy_set":"framework","profile":profile.id,"profile_version":profile.version,"profile_sha256":profile.hash,"policy_version":policy_version,
		"policy_sha256":profile.hash,"profile_definition":{"summary":profile.summary,"constraint":profile.constraint,"traits":profile.traits,
			"derived":profile.derived,"intent_weights":profile.intent_weights,"overrides":profile.overrides,"time_scale":profile.time_scale},
		"integration":{"game":str(a_info.game),"adapter_version":str(a_info.adapter_version),"strategy_version":str(a_info.strategy_version),
			"integration_version":str(info.get("integration_version","")),"capabilities":caps},
		"seed":seed_value,"content_fingerprint":fingerprint,"evidence_class":"natural fresh-save playthrough","until":driver.until,
		"stop_reason":stop,"ok":driver.ok(),
		"active_seconds":snappedf(driver.active,.1),"offline_seconds":snappedf(driver.offline,.1),"calendar_seconds":snappedf(driver.active+driver.offline,.1),
		"virtual_start_unix":driver.start_unix,"steps":driver.steps,
		"horizon":{"until":driver.until,"active_limit_s":driver.active_limit if is_finite(driver.active_limit) else null,"calendar_limit_s":driver.calendar_limit if driver.calendar_limit>0 else null},
		"schedule":schedule.describe(),"schedule_note":schedule_note,"sessions":driver.sessions,"session_count":generic.sessions,
		"away_at_stop_s":snappedf(driver.away_at_stop,.1),"progress_gaps":driver.gaps,"gap_report_s":driver.gap_report,
		"longest_stall":{"seconds":snappedf(float(driver.longest_stall.seconds),.1),"from_s":snappedf(float(driver.longest_stall.from),.1),"to_s":snappedf(float(driver.longest_stall.to),.1)},
		"open_stall_seconds":snappedf(driver.stall_open,.1),
		"decisions":decisions,"generic":generic,
		"events":recorder.count,"events_sha256":events_digest,"state_sha256":state_digest,
		"game":adapter.game_summary(),
		# Volatile process facts: excluded from every determinism comparison.
		"process":{"wall_seconds":snappedf(driver.wall_seconds,.01),"speed_x":snappedf(driver.active/maxf(.001,driver.wall_seconds),.1),
			"godot":Engine.get_version_info().string}}
	summary.process.merge(o.get("process_extra",{}))
	if not _write(str(o.output),summary):return {"error":"cannot write summary.json","exit":2,"summary":summary,"adapter":adapter}
	var extra:=""
	if integration.has_method("sentinel_extra"):extra=" "+str(integration.sentinel_extra(adapter))
	summary["_sentinel"]="PLAYTEST_RESULT ok=%s stop=%s profile=%s seed=%d active_min=%.1f calendar_h=%.2f sessions=%d wall_s=%.1f decisions=%d mistakes=%d%s events_sha=%s state_sha=%s" % [
		"true" if driver.ok() else "false",stop,profile.id,seed_value,driver.active/60.0,driver.calendar()/3600.0,int(generic.sessions),driver.wall_seconds,
		int(decisions.decisions),int(decisions.mistakes),extra,events_digest.substr(0,16),state_digest.substr(0,16)]
	return {"summary":summary,"error":"","exit":0 if driver.ok() else 1,"adapter":adapter,"driver":driver,"engine":engine}

## The schedule a run uses: "default" = sessions for a calendar horizon, else the preset's default_schedule;
## "continuous" or "sessions" by name; then per-run overrides. {} on a bad option.
static func schedule_config(profile: Dictionary,which: String,until: String,overrides: Dictionary) -> Dictionary:
	var config: Dictionary
	match which:
		"default":config={"mode":"continuous"} if (until!="calendar" and str(profile.default_schedule)=="continuous") else profile.sessions.duplicate(true)
		"continuous":config={"mode":"continuous"}
		"sessions","calendar":config=profile.sessions.duplicate(true)
		_:return {}
	if str(config.mode)=="continuous" and not overrides.is_empty() and which=="default":config=profile.sessions.duplicate(true)
	for k in overrides:config[k]=overrides[k]
	if config.has("return_mode") and not str(config.return_mode) in ["cold","warm"]:return {}
	if str(config.get("mode","continuous"))=="sessions" and (config.get("slots",[]).is_empty() or not config.has("session_minutes")):return {}
	return config

static func _write(folder: String,summary: Dictionary) -> bool:
	var file:=FileAccess.open(folder.path_join("summary.json"),FileAccess.WRITE)
	if file==null:return false
	var copy:=summary.duplicate()
	copy.erase("_sentinel")
	file.store_string(JSON.stringify(copy,"  ",false));file.close()
	return true
