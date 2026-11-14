extends Node
## Player Profiles package self-test: the cross-game acceptance test. Runs the UNCHANGED core package and
## the seven UNCHANGED universal presets against Farmstead, a non-combat production/building fixture, in
## two capability models ("full": automation + offline; "plain": neither). It needs nothing outside
## res://addons/player_profiles/, so it also runs in an empty Godot project (tools/player_profiles.py selftest).
## A fixture proves interface flexibility, not the integration of any real shipped game.
##   godot --headless --path <project> res://addons/player_profiles/tests/selftest.tscn [-- --output=<abs folder>] [-- --keep]
## Last line: PLAYER_PROFILES_SELFTEST PASS|FAIL checks=N failures=M ; exit 0 on pass.

const Framework:=preload("../core/framework.gd")
const Library:=preload("../core/profile_library.gd")
const RunSession:=preload("../core/run_session.gd")
const DecisionEngine:=preload("../core/decision_engine.gd")
const Recorder:=preload("../core/recorder.gd")
const Check:=preload("../core/contract_check.gd")
const Integration:=preload("fixture/farmstead_integration.gd")
const FarmAdapter:=preload("fixture/farmstead_adapter.gd")
const Broken:=preload("fixture/broken_adapter.gd")
const Spy:=preload("fixture/spy_adapter.gd")
const PROFILES:=["active","casual","idle","beginner","collector","speedrunner","completionist"]

var checks:=0
var failures:=0
var base:=""

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		print("PLAYER_PROFILES_SELFTEST FAIL: ",label)

func _ready() -> void:call_deferred("run")

func run() -> void:
	var started:=Time.get_ticks_msec()
	get_tree().create_timer(300.0,true,false,true).timeout.connect(func():print("PLAYER_PROFILES_SELFTEST watchdog");get_tree().quit(2))
	var o:=RunSession.options_from_args(OS.get_cmdline_user_args())
	base=str(o.raw.get("output",ProjectSettings.globalize_path("user://player_profiles_selftest")))
	DirAccess.make_dir_recursive_absolute(base)
	section_library()
	section_contract()
	var equal:=section_equal_exposure()
	section_differences(equal)
	section_same_state()
	section_determinism()
	section_sessions()
	section_failures_and_commitments(equal)
	if not o.raw.has("keep"):_remove(base)
	print("PLAYER_PROFILES_SELFTEST %s checks=%d failures=%d seconds=%.1f" % ["PASS" if failures==0 else "FAIL",checks,failures,(Time.get_ticks_msec()-started)/1000.0])
	get_tree().quit(1 if failures else 0)

func play(profile: String,variant: String,seed_value: int,extra: Dictionary,tag: String) -> Dictionary:
	var integration=Integration.new()
	var o:=RunSession.options_from_args(PackedStringArray([]))
	o.profile=profile;o.seed=seed_value;o.output=base.path_join(tag)
	for k in extra:o[k]=extra[k]
	DirAccess.make_dir_recursive_absolute(str(o.output))
	check(integration.prepare(self,{"raw":{"variant":variant}})=="","fixture integration prepares "+variant)
	var r:=RunSession.execute(integration,o,self)
	integration.cleanup()
	check(str(r.error)=="" and int(r.exit)==0,"%s/%s/%d runs cleanly (%s)" % [profile,variant,seed_value,str(r.error)])
	var s: Dictionary=r.summary
	s["_folder"]=str(o.output)
	return s

func events(summary: Dictionary) -> Array:
	var out: Array=[]
	for line in FileAccess.get_file_as_string(str(summary._folder).path_join("events.jsonl")).split("\n",false):out.append(JSON.parse_string(line))
	return out

# ---------------------------------------------------------------- A. presets, overrides, schema
func section_library() -> void:
	var lib=Library.new()
	check(lib.errors.is_empty(),"profiles.json validates: "+"; ".join(lib.errors))
	check(lib.ids()==PROFILES,"exactly the seven universal presets, in order")
	var vectors: Dictionary={}
	var hashes: Dictionary={}
	for id in PROFILES:
		var p: Dictionary=lib.resolve(id)
		check(not p.has("error"),id+" resolves")
		var v:=JSON.stringify(p.traits,"",true)
		check(not vectors.has(v),id+" has its own trait vector")
		vectors[v]=id;hashes[p.hash]=id
		check(p.intent_weights.size()==Framework.INTENTS.size(),id+" has a weight for every intent")
		check(float(p.derived.deliberation_s)>=2.0 and float(p.derived.deliberation_s)<=90.0,id+" deliberation interval within 2..90 s")
	check(hashes.size()==7,"seven distinct profile hashes")
	var a: Dictionary=lib.resolve("active")
	var b: Dictionary=lib.resolve("active",{"traits":{"attention":0.2}})
	check(b.hash!=a.hash and float(b.derived.deliberation_s)>float(a.derived.deliberation_s),"a trait override changes the derived cadence and the profile hash")
	check(lib.resolve("active",{"traits":{"attentionn":0.2}}).has("error"),"an unknown trait override is refused")
	check(lib.resolve("beginner",{"traits":{"mistake_rate":0.5}}).has("error"),"mistake_rate stays bounded below 0.3")
	check(lib.resolve("active",{"intent_weights":{"explore":2.0}}).intent_weights.explore==2.0,"intent weights can be overridden per run")
	var c: Dictionary=lib.resolve("active",{},4.0)
	check(absf(float(c.derived.deliberation_s)-4.0*float(a.derived.deliberation_s))<1e-6,"time_scale rescales cadence without changing traits")
	check(lib.resolve("active").hash==a.hash,"resolving twice gives the same hash")
	var text:=FileAccess.get_file_as_string((Library as Script).resource_path.get_base_dir().path_join("profiles.json")).to_lower()
	for word in ["boss","prestige","weapon","gem","enemy","loot","res://","/root/"]:
		check(not text.contains(word),"profiles.json mentions no game mechanic or path: "+word)

# ---------------------------------------------------------------- B. contract validation and invalid actions
func section_contract() -> void:
	var rec=Recorder.new()
	check(rec.open(base.path_join("contract"),false),"recorder opens")
	var good=FarmAdapter.new();good.setup({"recorder":rec,"seed":1,"start_unix":0.0},"plain")
	check(Check.check_adapter(good).is_empty(),"the plain Farmstead adapter satisfies the contract")
	var bad=Broken.new();bad.setup({"recorder":rec,"seed":1,"start_unix":0.0},"plain");bad.hide_intent=true
	check(not Check.check_adapter(bad).is_empty(),"an adapter that omits an intent declaration is refused")
	bad.hide_intent=false
	var caps: Dictionary=bad.capabilities()
	var problems:=0
	for opt in bad.options():
		if Check.check_option(opt,caps)!="":problems+=1
	check(problems==5,"the five malformed options are each detected (%d)" % problems)
	var r: Dictionary=good.begin({"id":"buy:castle","intent":"strengthen","kind":"instant"})
	check(str(r.status)=="rejected","an action the game does not have is rejected by the game")
	r=good.begin({"id":"buy:hall","intent":"progress_main","kind":"instant"})
	check(str(r.status)=="rejected" and str(r.reason).begins_with("NOT_ENOUGH"),"an unaffordable action is refused with the game's own reason (%s)" % str(r.reason))
	# The engine keeps playing with a broken adapter and counts every bad option.
	var lib=Library.new()
	var engine=DecisionEngine.new()
	engine.setup(lib.resolve("active"),bad,rec,1)
	for i in range(20):
		bad.step(0.5);engine.tick(float(i))
	check(int(engine.stats.invalid_options)>=5,"the engine rejects invalid options instead of executing them")
	check(int(engine.stats.decisions)>0,"and still decides among the valid ones")
	# Policy observations only: the engine never reads privileged telemetry.
	var spy=Spy.new();spy.setup({"recorder":rec,"seed":2,"start_unix":0.0},"full")
	var e2=DecisionEngine.new()
	e2.setup(lib.resolve("speedrunner"),spy,rec,2)
	for i in range(600):
		spy.step(0.5);e2.tick(float(i)*0.5)
	check(spy.telemetry_calls==0 and int(e2.stats.decisions)>10,"the engine decides from observe()/options() alone (telemetry calls: %d)" % spy.telemetry_calls)
	var src:=FileAccess.get_file_as_string((DecisionEngine as Script).resource_path)
	for m in ["game_summary","progress_signature","state_digest","generic_metrics","adapter.trace_sample"]:
		check(not src.contains(m),"decision_engine.gd never references "+m)

# ---------------------------------------------------------------- C. equal exposure: all seven, both capability models
func section_equal_exposure() -> Dictionary:
	var out: Dictionary={}
	for variant in ["full","plain"]:
		for p in PROFILES:
			out["%s|%s" % [variant,p]]=play(p,variant,1,{"schedule":"continuous","active_minutes":40.0},"eq_%s_%s" % [variant,p])
	return out

func ms(summary: Dictionary,key: String) -> float:
	for m in summary.generic.milestones:
		if str(m.key)==key:return float(m.t)
	return INF

func section_differences(eq: Dictionary) -> void:
	var lines: Array=[]
	for variant in ["full","plain"]:
		var rows: Dictionary={}
		for p in PROFILES:rows[p]=eq["%s|%s" % [variant,p]]
		for p in PROFILES:
			var s: Dictionary=rows[p]
			check(str(s.stop_reason)=="duration_reached" and absf(float(s.active_seconds)-2400.0)<1.0,"%s/%s plays exactly 40 active minutes" % [variant,p])
			check(int(s.decisions.decisions)>0 and not s.decisions.by_intent.is_empty(),"%s/%s makes decisions" % [variant,p])
			for key in ["schema","framework","profile_sha256","integration","decisions","generic","events_sha256","state_sha256","active_seconds","offline_seconds","calendar_seconds"]:
				check(s.has(key),"%s/%s summary has %s" % [variant,p,key])
			var g: Dictionary=s.game
			lines.append("%s %-13s hall %d stars %d relics %d contracts %d decisions/h %s mistakes %d by_intent %s" % [variant,p,int(g.hall),int(g.stars),int(g.relics),int(g.contracts_done),
				str(s.generic.decisions_per_active_hour),int(s.decisions.mistakes),JSON.stringify(s.decisions.by_intent)])
		var by:=func(p,k):return int(rows[p].game[k])
		var relics_max:=0
		for p in PROFILES:
			if p!="collector":relics_max=maxi(relics_max,by.call(p,"relics"))
		check(by.call("collector","relics")>=relics_max,variant+": Collector finds at least as many relics as any other profile")
		check(by.call("speedrunner","relics")<=by.call("collector","relics")-3,variant+": Speedrunner skips most collection")
		check(int(rows.speedrunner.decisions.by_intent.get("complete_optional",0))==0,variant+": Speedrunner never takes optional contracts")
		check(by.call("completionist","contracts_done")>by.call("speedrunner","contracts_done") and by.call("completionist","contracts_done")>=by.call("collector","contracts_done"),variant+": Completionist completes optional contracts")
		check(ms(rows.speedrunner,"hall:4")<=ms(rows.completionist,"hall:4"),variant+": Speedrunner reaches Town Hall 4 no later than Completionist")
		check(float(rows.casual.generic.deliberations_per_active_hour)<float(rows.active.generic.deliberations_per_active_hour),variant+": Casual deliberates less often than Active")
		var lowest:=true
		for p in PROFILES:
			if p!="idle" and float(rows[p].generic.deliberations_per_active_hour)<=float(rows.idle.generic.deliberations_per_active_hour):lowest=false
		check(lowest,variant+": Idle deliberates least often")
		check(float(rows.beginner.decisions.mistake_rate_end)<float(rows.beginner.profile_definition.traits.mistake_rate),variant+": Beginner's mistake rate falls as it gains experience")
		var surveyed_max:=0
		for p in PROFILES:surveyed_max=maxi(surveyed_max,by.call(p,"surveyed"))
		check(by.call("speedrunner","surveyed")<surveyed_max,variant+": Speedrunner explores less than the most exploring profile")
		if variant=="plain":
			for p in PROFILES:
				check(str(rows[p].generic.automation_owned)=="unsupported","plain/%s reports automation as unsupported, not 0" % p)
				check(int(rows[p].decisions.by_intent.get("invest_automation",0))==0,"plain/%s never invents automation decisions" % p)
				check(rows[p].decisions.unsupported_intents.has("invest_automation") and rows[p].decisions.unsupported_intents.has("recover"),"plain/%s lists its unsupported intents" % p)
		else:
			check(ms(rows.idle,"automation:foreman")<=ms(rows.active,"automation:foreman") and ms(rows.idle,"automation:foreman")<ms(rows.speedrunner,"automation:foreman"),"full: Idle buys automation earlier than Active and Speedrunner")
			for p in PROFILES:check(rows[p].decisions.unsupported_intents==["recover"],"full/%s: only recover is unsupported" % p)
	var mistakes:=int(eq["full|beginner"].decisions.mistakes)+int(eq["plain|beginner"].decisions.mistakes)
	check(mistakes>0,"Beginner makes bounded, recorded mistakes")
	var others:=0
	for p in ["active","speedrunner","completionist"]:others+=int(eq["full|"+p].decisions.mistakes)
	check(mistakes>others,"Beginner makes more mistakes than experienced profiles")
	for l in lines:print("  ",l)

# ---------------------------------------------------------------- D. same game state, different choices
func section_same_state() -> void:
	var lib=Library.new()
	var tops: Dictionary={}
	var rows: Array=[]
	for p in PROFILES:
		var rec=Recorder.new();rec.open(base.path_join("same_"+p),false)
		var ad=FarmAdapter.new();ad.setup({"recorder":rec,"seed":5,"start_unix":0.0},"full")
		ad.sim.s.wood=400.0;ad.sim.s.gold=400.0
		for i in range(6):ad.sim.s.surveyed.append(i)                 # the same, partly explored town for everyone
		ad.sim.s.contract={"wood":40.0,"gold":50.0,"expires":9999.0}
		var engine=DecisionEngine.new()
		engine.setup(lib.resolve(p),ad,rec,5)
		var ranked: Array=engine.preview()
		var act:="";var inst:=""
		for c in ranked:
			if c.refusal!="":continue
			if c.kind=="activity" and act=="":act=c.id
			if c.kind=="instant" and inst=="":inst=c.id
		tops[act+"|"+inst]=true
		rows.append("%-13s first quick action %-18s first activity %s" % [p,inst,act])
	for r in rows:print("  same state: ",r)
	check(tops.size()>=3,"from one identical game state the seven profiles make at least three different first choices (%d)" % tops.size())

# ---------------------------------------------------------------- E. deterministic replay
func section_determinism() -> void:
	for p in ["beginner","casual"]:
		var x:=play(p,"full",3,{"until":"calendar","calendar_hours":24.0},"det_%s_a" % p)
		var y:=play(p,"full",3,{"until":"calendar","calendar_hours":24.0},"det_%s_b" % p)
		var z:=play(p,"full",4,{"until":"calendar","calendar_hours":24.0},"det_%s_c" % p)
		check(x.events_sha256==y.events_sha256 and int(x.events)==int(y.events),p+": same seed and config replay to an identical event log")
		check(x.state_sha256==y.state_sha256,p+": same seed and config replay to an identical final state")
		check(x.events_sha256!=z.events_sha256,p+": another seed gives another run")

# ---------------------------------------------------------------- F. sessions, offline, persistence
func section_sessions() -> void:
	for variant in ["full","plain"]:
		for p in ["idle","casual","active"]:
			var s:=play(p,variant,2,{"until":"calendar","calendar_hours":48.0},"cal_%s_%s" % [variant,p])
			var ev:=events(s)
			check(str(s.stop_reason)=="calendar_reached","%s/%s reaches the 48 h calendar horizon" % [variant,p])
			check(absf(float(s.calendar_seconds)-float(s.active_seconds)-float(s.offline_seconds))<1.0,"%s/%s calendar = active + offline" % [variant,p])
			check(int(s.session_count)>=3 and float(s.offline_seconds)>float(s.active_seconds),"%s/%s plays several sessions with offline time between them" % [variant,p])
			check(ev.filter(func(e):return str(e.type)=="action_error").is_empty(),"%s/%s: every cold return reloads the progression intact" % [variant,p])
			var claims:=ev.filter(func(e):return str(e.type)=="decision" and str(e.get("option",""))=="claim_offline" and str(e.status)=="done").size()
			if variant=="plain":
				check(float(s.game.offline_paid_s)==0.0 and claims==0,"plain/%s: closing the game pays nothing and nothing is claimed" % p)
			elif p=="idle":
				check(int(s.game.ledger)==1 and float(s.game.offline_paid_s)>0.0 and claims>0,"full/idle owns the Ledger and claims offline production it earned")
		var idle_s: Dictionary=play("idle",variant,2,{"until":"calendar","calendar_hours":48.0,"schedule_overrides":{"return_mode":"warm"}},"warm_"+variant)
		check(str(idle_s.stop_reason)=="calendar_reached","%s: warm returns work too" % variant)

# ---------------------------------------------------------------- G. setbacks, cooldowns, commitments
func section_failures_and_commitments(eq: Dictionary) -> void:
	var cooldown_ok:=true
	var any_failure:=false
	var switches_ok:=true
	for key in eq:
		var s: Dictionary=eq[key]
		var d: Dictionary=s.profile_definition.derived
		var ev:=events(s)
		var failed_at: Dictionary={}
		for e in ev:
			if str(e.type)=="outcome" and str(e.status)=="failed":
				any_failure=true
				var fam:=str(e.option).split(":")[0]
				failed_at[fam]=float(e.t)
			if str(e.type)=="decision" and str(e.get("decision",""))=="activity" and str(e.status)=="started":
				var fam2:=str(e.option).split(":")[0]
				if failed_at.has(fam2) and float(e.t)<float(failed_at[fam2])+float(d.base_cooldown_s)-0.01:cooldown_ok=false
		var limit:=int(d.max_switches_10min)*(int(float(s.active_seconds)/600.0)+1)
		if int(s.decisions.switches)>limit:switches_ok=false
	check(any_failure,"some risky attempts fail through the game's own rules")
	check(cooldown_ok,"after a failure the same family is not retried before its cooldown")
	check(switches_ok,"activity switches stay within each profile's re-evaluation limit")
	var held:=0
	for key in eq:held+=int(eq[key].decisions.holds)
	check(held>0,"commitments hold activities against marginally better options")

func _remove(path: String) -> void:
	var dir:=DirAccess.open(path)
	if dir==null:return
	for f in dir.get_files():dir.remove(f)
	for d in dir.get_directories():_remove(path.path_join(d))
	DirAccess.remove_absolute(path)
