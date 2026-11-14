extends RefCounted
## Loads the seven universal presets (profiles.json), applies per-run overrides and derives the decision
## engine's working values from the traits. Game-independent.
##
## A resolved profile is a plain Dictionary:
##   id, version, summary, constraint, traits{16 normalized traits}, derived{engine values}, intent_weights{intent: w},
##   sessions{schedule config}, default_schedule, overrides{what the run changed}, hash (sha256 of all of the above
##   plus the framework version: the run identity of the behaviour, independent of any game).
##
## Derived values (all formulas here; seconds are ACTIVE seconds and are multiplied by the integration's
## time_scale so a game with very short rounds can rescale cadence without changing profile identity):
##   deliberation_s     = 90 * (2/90)^attention                  attention 1 -> 2 s, 0.5 -> 13 s, 0 -> 90 s
##   urgent_reaction    = 0.95 - 0.5*attention                   urgency that interrupts between deliberations
##   instant_budget     = max(2, 1 + round(4*attention*(0.5+0.5*efficiency)))   quick actions per deliberation
##   hold_factor        = 1.5 - revisit_tendency                 x an activity's expected commitment = minimum hold
##   hysteresis         = 0.1 + 0.4*(1-revisit_tendency)         a new activity must score this much better to switch
##   max_switches_10min = 3 + round(9*revisit_tendency)          re-evaluation limit (anti-thrashing)
##   required_confidence= 0.35 + 0.6*preparation                 minimum success estimate for a risky option
##   caution_step       = 0.02 + 0.08*(1-setback_tolerance)      added to that minimum per failure of the same family
##   base_cooldown_s    = 60 * (1 + 2*(1-setback_tolerance))     wait before retrying a failed family (x failures)
##   noise              = 0.3*(1-efficiency)                     +/- relative score noise (seeded)
##   min_purchase_score = 0.12 + 0.3*(1-spending)                options scoring below this are not worth paying for
##   save_for_goals     = spending < 0.5                         keeps resources for its top unaffordable goal
##   patience_s         = 600 + 2400*completion_drive            no-progress time after which completion hold-back lifts
##   familiarity_gain   = 0.15 + 0.5*learning_rate               per successful use of a feature
##   unfamiliar_penalty = 0.6*(1-mastery)                        score penalty on a never-used feature
##   mistake_decay      = 15/(0.1+learning_rate)                 successful outcomes for the mistake rate to fall by e
##   plan_before_leave  = automation_preference >= 0.6           a last quick-action pass before closing the game
##   satiation          = 0.3 + 0.4*revisit_tendency              how much repeating one intent lowers its activities' score
##   satiation_window_s = 600                                     time constant of the recent-time share
## Intent weights:
##   recover 1, claim_rewards 1, wait 0.05,
##   progress_main 0.3+0.7*urgency, attempt_challenge 0.25+0.45*urgency+0.3*risk_tolerance,
##   strengthen 0.35+0.35*preparation+0.3*efficiency, improve_economy 0.25+0.5*efficiency+0.25*(1-urgency),
##   invest_automation 0.1+0.9*automation_preference, explore 0.1+0.9*exploration,
##   complete_optional 0.05+0.95*side_goal_preference, collect 0.05+0.95*collection_drive.

const Framework:=preload("framework.gd")
const TRAITS:=["attention","efficiency","exploration","main_goal_urgency","risk_tolerance","spending","preparation",
	"side_goal_preference","collection_drive","completion_drive","automation_preference","setback_tolerance",
	"revisit_tendency","mastery","learning_rate","mistake_rate"]
const PROFILE_IDS:=["active","casual","idle","beginner","collector","speedrunner","completionist"]

var data: Dictionary={}
var errors: Array=[]

func _init() -> void:
	var path:=(get_script() as Script).resource_path.get_base_dir().path_join("profiles.json")
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		errors.append("profiles.json does not parse");return
	data=parsed
	errors=validate()

func ids() -> Array:return PROFILE_IDS.duplicate()
func has(id: String) -> bool:return data.get("profiles",{}).has(id)

## Structural check of the preset file: every preset has every trait in 0..1, a session pattern, and the
## mistake rate stays bounded (< 0.3) so imperfection never becomes sabotage.
func validate() -> Array:
	var out: Array=[]
	if str(data.get("schema",""))!=Framework.PROFILE_SCHEMA:out.append("profiles.json schema is not "+Framework.PROFILE_SCHEMA)
	var profiles: Dictionary=data.get("profiles",{})
	for id in PROFILE_IDS:
		if not profiles.has(id):out.append("missing preset "+id);continue
		var p: Dictionary=profiles[id]
		for t in TRAITS:
			if not p.get("traits",{}).has(t):out.append("%s: missing trait %s" % [id,t])
			elif float(p.traits[t])<0.0 or float(p.traits[t])>1.0:out.append("%s: trait %s outside 0..1" % [id,t])
		if float(p.get("traits",{}).get("mistake_rate",0.0))>=0.3:out.append(id+": mistake_rate must stay below 0.3")
		if not p.has("sessions") or str(p.sessions.get("mode",""))!="sessions":out.append(id+": needs a sessions pattern")
		if not str(p.get("default_schedule","")) in ["continuous","sessions"]:out.append(id+": default_schedule must be continuous or sessions")
	for t in TRAITS:
		if not data.get("parameters",{}).has(t):out.append("parameter %s is undocumented" % t)
	return out

## Parses "trait=value,trait=value" (CLI) into an overrides dictionary. Unknown keys are reported in errors.
static func parse_overrides(text: String) -> Dictionary:
	var out: Dictionary={"traits":{},"derived":{},"intent_weights":{}}
	for part in text.split(",",false):
		var kv:=part.split("=",true,1)
		if kv.size()!=2:continue
		var key:=kv[0].strip_edges()
		var value:=float(kv[1])
		if key.begins_with("weight."):out.intent_weights[key.trim_prefix("weight.")]=value
		elif key.begins_with("derived."):out.derived[key.trim_prefix("derived.")]=value
		else:out.traits[key]=value
	return out

## A resolved profile, or {"error": "..."}. `overrides` = {traits{}, derived{}, intent_weights{}, sessions{}}.
## time_scale (from the integration) multiplies every derived duration.
func resolve(id: String,overrides: Dictionary={},time_scale: float=1.0) -> Dictionary:
	if not errors.is_empty():return {"error":"; ".join(errors)}
	if not has(id):return {"error":"unknown player profile '%s' (known: %s)" % [id,", ".join(PROFILE_IDS)]}
	var p: Dictionary=data.profiles[id].duplicate(true)
	var traits: Dictionary=p.traits.duplicate()
	for t in overrides.get("traits",{}):
		if not TRAITS.has(t):return {"error":"unknown trait override '%s'" % t}
		traits[t]=clampf(float(overrides.traits[t]),0.0,1.0)
	if float(traits.mistake_rate)>=0.3:return {"error":"mistake_rate override must stay below 0.3"}
	var derived:=derive(traits,time_scale)
	for k in overrides.get("derived",{}):
		if not derived.has(k):return {"error":"unknown derived override '%s'" % k}
		derived[k]=overrides.derived[k]
	var weights:=intent_weights(traits)
	for k in overrides.get("intent_weights",{}):
		if not weights.has(k):return {"error":"unknown intent weight override '%s'" % k}
		weights[k]=maxf(0.0,float(overrides.intent_weights[k]))
	var sessions: Dictionary=p.sessions.duplicate(true)
	for k in overrides.get("sessions",{}):sessions[k]=overrides.sessions[k]
	var resolved:={"id":id,"version":str(p.get("version","1")),"summary":str(p.get("summary","")),"constraint":str(p.get("constraint","")),
		"traits":traits,"derived":derived,"intent_weights":weights,"sessions":sessions,"default_schedule":str(p.default_schedule),
		"time_scale":time_scale,"overrides":overrides.duplicate(true)}
	resolved["hash"]=JSON.stringify([Framework.FRAMEWORK_VERSION,resolved],"",true).sha256_text()
	return resolved

static func derive(t: Dictionary,time_scale: float=1.0) -> Dictionary:
	var att:=float(t.attention)
	return {
		"deliberation_s":90.0*pow(2.0/90.0,att)*time_scale,
		"urgent_reaction":0.95-0.5*att,
		"instant_budget":maxi(2,1+int(round(4.0*att*(0.5+0.5*float(t.efficiency))))),
		"hold_factor":1.5-float(t.revisit_tendency),
		"hysteresis":0.1+0.4*(1.0-float(t.revisit_tendency)),
		"max_switches_10min":3+int(round(9.0*float(t.revisit_tendency))),
		"required_confidence":0.35+0.6*float(t.preparation),
		"caution_step":0.02+0.08*(1.0-float(t.setback_tolerance)),
		"base_cooldown_s":60.0*(1.0+2.0*(1.0-float(t.setback_tolerance)))*time_scale,
		"noise":0.3*(1.0-float(t.efficiency)),
		"min_purchase_score":0.12+0.3*(1.0-float(t.spending)),
		"save_for_goals":float(t.spending)<0.5,
		"patience_s":(600.0+2400.0*float(t.completion_drive))*time_scale,
		"familiarity_gain":0.15+0.5*float(t.learning_rate),
		"unfamiliar_penalty":0.6*(1.0-float(t.mastery)),
		"mistake_decay":15.0/(0.1+float(t.learning_rate)),
		"plan_before_leave":float(t.automation_preference)>=0.6,
		"satiation":0.3+0.4*float(t.revisit_tendency),
		"satiation_window_s":600.0*time_scale,
	}

static func intent_weights(t: Dictionary) -> Dictionary:
	var urg:=float(t.main_goal_urgency)
	return {
		"recover":1.0,"claim_rewards":1.0,"wait":0.05,
		"progress_main":0.3+0.7*urg,
		"attempt_challenge":0.25+0.45*urg+0.3*float(t.risk_tolerance),
		"strengthen":0.35+0.35*float(t.preparation)+0.3*float(t.efficiency),
		"improve_economy":0.25+0.5*float(t.efficiency)+0.25*(1.0-urg),
		"invest_automation":0.1+0.9*float(t.automation_preference),
		"explore":0.1+0.9*float(t.exploration),
		"complete_optional":0.05+0.95*float(t.side_goal_preference),
		"collect":0.05+0.95*float(t.collection_drive),
	}
