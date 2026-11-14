extends RefCounted
## Validates an adapter against player-profiles.contract/1 before a run, and validates every option the
## engine receives. Game-independent. Returns lists of human-readable problems (empty = valid).

const Framework:=preload("framework.gd")
const REQUIRED:=["integration_info","capabilities","configure","observe","options","begin","advance","cancel","steer",
	"set_clock","step","failed","session_can_end","leave_session","return_session","progress_signature","game_summary",
	"generic_metrics","state_digest","step_seconds","tick_seconds","time_scale","teardown","trace_sample","blocked_reason","goal_reached"]
const KINDS:=["instant","activity"]

static func check_adapter(adapter) -> Array:
	var out: Array=[]
	if adapter==null:return ["adapter is null"]
	for m in REQUIRED:
		if not adapter.has_method(m):out.append("adapter lacks "+m+"()")
	if not out.is_empty():return out
	var info: Dictionary=adapter.integration_info()
	for k in ["game","adapter_version","strategy_version"]:
		if str(info.get(k,""))=="":out.append("integration_info() lacks "+k)
	var caps: Dictionary=adapter.capabilities()
	var intents: Dictionary=caps.get("intents",{})
	for i in Framework.INTENTS:
		if not intents.has(i):out.append("capabilities() does not declare intent "+i+" (declare it unsupported instead)")
		elif not intents[i].has("supported"):out.append("capability "+i+" lacks 'supported'")
	for i in intents:
		if not Framework.INTENTS.has(i):out.append("capabilities() declares unknown intent "+str(i))
	for f in ["sessions","offline","automation","persistence"]:
		if not caps.get("features",{}).has(f):out.append("capabilities().features lacks "+f)
	if adapter.step_seconds()<=0.0 or adapter.tick_seconds()<adapter.step_seconds():out.append("tick_seconds must be >= step_seconds > 0")
	var obs: Dictionary=adapter.observe()
	for k in ["progress","health","area_completion","collection_completion","resources","urgent"]:
		if not obs.has(k):out.append("observe() lacks "+k)
	return out

## Problems with one option, given the adapter's declared capabilities ("" when valid).
static func check_option(o,caps: Dictionary) -> String:
	if not o is Dictionary:return "option is not a Dictionary"
	if str(o.get("id",""))=="":return "option without id"
	var intent:=str(o.get("intent",""))
	if not Framework.INTENTS.has(intent):return "option %s has unknown intent '%s'" % [o.id,intent]
	if not bool(caps.get("intents",{}).get(intent,{}).get("supported",false)):return "option %s uses intent %s that the adapter declared unsupported" % [o.id,intent]
	if not str(o.get("kind","")) in KINDS:return "option %s kind must be instant or activity" % o.id
	for k in ["benefit","risk","urgency","novelty","shortfall"]:
		if o.has(k) and (float(o[k])<0.0 or float(o[k])>1.0):return "option %s %s outside 0..1" % [o.id,k]
	if o.has("confidence") and float(o.confidence)>1.0:return "option %s confidence above 1" % o.id
	if not bool(o.get("eligible",true)) and str(o.get("block",""))=="":return "ineligible option %s gives no block reason" % o.id
	return ""
