extends RefCounted
## The universal decision engine: one implementation for all seven profiles and every game.
## It sees the game only through adapter.observe() and adapter.options() (player-observable values) and acts
## only through adapter.begin()/advance()/cancel(). It never reads privileged telemetry.
##
## Each engine tick (adapter.tick_seconds() of active time):
##   1. adapter.advance(): the committed activity and the player's reflexes run one tick.
##   2. An urgent option at or above the profile's reaction threshold interrupts at once; otherwise a
##      deliberation happens every `deliberation_s` (attention), or soon after the activity ended.
## A deliberation:
##   a. gathers options, validates them against the contract, classifies refusals
##      (ineligible / cooldown / not_ready / unaffordable) and scores the rest;
##   b. performs up to `instant_budget` quick actions (purchases, claims, toggles), best score first, with a
##      savings rule per resource (a saver keeps its resource for its top unaffordable goal);
##   c. keeps, or switches, the ongoing activity with a commitment hold, hysteresis and a switch limit.
## Score (higher is better), every term documented in README.md:
##   s = W[intent] * (0.25 + lerp(0.5, benefit, efficiency))
##     + novelty*(0.6*collection_drive + 0.3*exploration) + milestone*0.5*urgency + bottleneck*(0.3+0.3*urgency)
##   s *= optional ? 0.3+0.7*side_goal_preference : 1
##   s *= advances ? hold_back : 1          hold_back = (1-0.85*completion*(1-area_completion)) * (1-0.6*collection*(1-collection_completion)),
##                                          lifted after `patience_s` without progress (no unreachable-target loops)
##   s *= 1 - 0.8*risk*(1-risk_tolerance)
##   s *= 1 - unfamiliar_penalty*(1-familiarity[feature])
##   s *= 1 - satiation*share[intent]        activities only: share = exponential moving share of the recent
##                                          active time (window satiation_window_s) spent on that intent, so
##                                          a player tires of repeating one thing and no single plan starves the rest
##   s += 2*urgency
##   s *= 1 + noise*U(-1,1)                 seeded; zero noise for a perfectly efficient player
## Ties: score, then Framework.INTENTS order, then option id. Every random draw uses the engine's own stream.

const Framework:=preload("framework.gd")
const Check:=preload("contract_check.gd")
const MAX_HOLD_S:=900.0

var profile: Dictionary={}
var T: Dictionary={}
var D: Dictionary={}
var W: Dictionary={}
var adapter
var rec
var caps: Dictionary={}
var rng:=RandomNumberGenerator.new()
var now:=0.0
var tick_s:=0.5
var next_deliberation:=0.0
var idle_check:=0.0
var current: Dictionary={}
var current_score:=0.0
var commit_until:=0.0
var switch_times: Array=[]
var cooldown_until: Dictionary={}
var failures: Dictionary={}
var caution: Dictionary={}
var familiarity: Dictionary={}
var experience:=0
var saving: Dictionary={}           # resource -> option id it is saving for
var last_progress:=-INF
var last_progress_t:=0.0
var _obs: Dictionary={}
var share: Dictionary={}            # intent -> exponential moving share of recent active time
var unsupported: Array=[]
var stats: Dictionary={"deliberations":0,"decisions":0,"instants":0,"activities_started":0,"by_intent":{},"by_status":{},
	"refusals":{},"mistakes":0,"switches":0,"holds":0,"urgent_interrupts":0,"save_for_goal":0,"invalid_options":0,
	"activity_seconds":{},"session_reviews":0,"plans_before_leave":0}

func setup(resolved: Dictionary,game_adapter,recorder,seed_value: int) -> void:
	profile=resolved;T=resolved.traits;D=resolved.derived;W=resolved.intent_weights
	adapter=game_adapter;rec=recorder
	rng.seed=hash("%d|%s|decisions" % [seed_value,str(resolved.id)])
	tick_s=float(adapter.tick_seconds())
	caps=adapter.capabilities()
	for i in Framework.INTENTS:
		if not bool(caps.intents.get(i,{}).get("supported",false)):unsupported.append(i)
	rec.event("capabilities",{"unsupported_intents":unsupported,"features":caps.get("features",{})})

# ---------------------------------------------------------------- tick
func tick(t: float) -> void:
	now=t
	_obs=adapter.observe()
	var p:=float(_obs.get("progress",0.0))
	if p!=last_progress:last_progress=p;last_progress_t=now
	var key:=str(current.get("intent","none"))
	stats.activity_seconds[key]=float(stats.activity_seconds.get(key,0.0))+tick_s
	var keep:=exp(-tick_s/maxf(1.0,float(D.satiation_window_s)))
	for i in share.keys():share[i]=float(share[i])*keep
	if key!="none":share[key]=float(share.get(key,0.0))+(1.0-keep)
	var st: Dictionary=adapter.advance(now)
	var status:=str(st.get("status","idle"))
	if not current.is_empty() and status in ["done","failed"]:
		_activity_ended(status,str(st.get("reason","")))
	var urgent:=false
	for o in _obs.get("urgent",[]):
		if float(o.get("urgency",0.0))>=float(D.urgent_reaction) and str(o.get("id",""))!=str(current.get("id","")):urgent=true
	if urgent:
		stats.urgent_interrupts+=1
		deliberate("urgent")
	elif now>=next_deliberation or (current.is_empty() and now>=idle_check):
		deliberate("scheduled" if not current.is_empty() else "idle")

func on_session_start() -> void:
	stats.session_reviews+=1
	current={};commit_until=0.0
	_obs=adapter.observe()
	deliberate("session_start")

func on_session_end() -> void:
	if bool(D.plan_before_leave):
		stats.plans_before_leave+=1
		deliberate("before_leave",true)
	adapter.cancel()
	current={}

# ---------------------------------------------------------------- deliberation
func deliberate(reason: String,instants_only: bool=false) -> void:
	stats.deliberations+=1
	next_deliberation=now+float(D.deliberation_s)
	idle_check=now+maxf(tick_s,0.3*float(D.deliberation_s))
	var cands:=_collect()
	var budget:=int(D.instant_budget)
	var used: Dictionary={}
	for n in range(budget):
		var choice:=_choose_instant(cands,used)
		if choice.is_empty():break
		used[str(choice.id)]=true
		var r: Dictionary=adapter.begin(choice)
		stats.instants+=1
		_record(choice,str(r.get("status","rejected")),str(r.get("reason","")),reason,cands)
		if n<budget-1:cands=_collect()
	if instants_only:return
	_choose_activity(cands,reason)

func _collect() -> Array:
	var out: Array=[]
	for o in adapter.options():
		var problem:=Check.check_option(o,caps)
		if problem!="":
			stats.invalid_options+=1
			rec.failure("option","invalid",str(o.get("id","?")) if o is Dictionary else "?",{"problem":problem})
			continue
		var c:=_normalize(o)
		c.refusal=_refusal(c)
		if c.refusal=="" and c.feature!="":
			# Seeing an option available is exposure too: familiarity grows slowly even before the first use.
			familiarity[c.feature]=minf(1.0,float(familiarity.get(c.feature,0.0))+0.01*float(T.learning_rate))
		c.score=_score(c)
		out.append(c)
	out.sort_custom(_better)
	return out

func _normalize(o: Dictionary) -> Dictionary:
	var c:={"id":str(o.id),"intent":str(o.intent),"kind":str(o.kind),"label":str(o.get("label",o.id)),"feature":str(o.get("feature","")),
		"family":str(o.get("family",o.id)),"eligible":bool(o.get("eligible",true)),"block":str(o.get("block","")),"cost":o.get("cost",{}),
		"affordable":bool(o.get("affordable",true)),"shortfall":float(o.get("shortfall",0.0)),"benefit":clampf(float(o.get("benefit",0.5)),0.0,1.0),
		"confidence":float(o.get("confidence",-1.0)),"risk":float(o.get("risk",0.0)),"urgency":float(o.get("urgency",0.0)),
		"novelty":float(o.get("novelty",0.0)),"milestone":bool(o.get("milestone",false)),"advances":bool(o.get("advances",false)),
		"optional":bool(o.get("optional",false)),"bottleneck":bool(o.get("bottleneck",false)),"commitment_s":float(o.get("commitment_s",0.0)),
		"payload":o.get("payload",null)}
	c["resource"]=str(c.cost.keys()[0]) if c.cost is Dictionary and not c.cost.is_empty() else ""
	return c

func required_confidence(family: String) -> float:
	return minf(0.97,float(D.required_confidence)+float(caution.get(family,0.0)))

func _refusal(c: Dictionary) -> String:
	if not c.eligible:return "ineligible"
	if float(cooldown_until.get(c.family,-1.0))>now:return "cooldown"
	if c.confidence>=0.0 and c.confidence<required_confidence(c.family):return "not_ready"
	if not c.affordable:return "unaffordable"
	return ""

func hold_back() -> float:
	if now-last_progress_t>=float(D.patience_s):return 1.0
	var h:=1.0
	var ac:=float(_obs.get("area_completion",-1.0))
	if ac>=0.0:h*=1.0-0.85*float(T.completion_drive)*(1.0-clampf(ac,0.0,1.0))
	var cc:=float(_obs.get("collection_completion",-1.0))
	if cc>=0.0:h*=1.0-0.6*float(T.collection_drive)*(1.0-clampf(cc,0.0,1.0))
	return h

func _score(c: Dictionary) -> float:
	var s:=float(W.get(c.intent,0.0))*(0.25+lerpf(0.5,c.benefit,float(T.efficiency)))
	s+=c.novelty*(0.6*float(T.collection_drive)+0.3*float(T.exploration))
	if c.milestone:s+=0.5*float(T.main_goal_urgency)
	if c.bottleneck:s+=0.3+0.3*float(T.main_goal_urgency)
	if c.optional:s*=0.3+0.7*float(T.side_goal_preference)
	if c.advances:s*=hold_back()
	s*=1.0-0.8*clampf(c.risk,0.0,1.0)*(1.0-float(T.risk_tolerance))
	if c.feature!="":s*=1.0-float(D.unfamiliar_penalty)*(1.0-float(familiarity.get(c.feature,0.0)))
	if c.kind=="activity":s*=1.0-float(D.satiation)*float(share.get(c.intent,0.0))
	s+=2.0*clampf(c.urgency,0.0,1.0)
	if float(D.noise)>0.0:s*=1.0+float(D.noise)*rng.randf_range(-1.0,1.0)
	return maxf(0.0,s)

func _better(x: Dictionary,y: Dictionary) -> bool:
	if absf(float(x.score)-float(y.score))>1e-9:return float(x.score)>float(y.score)
	var ix:=Framework.intent_index(str(x.intent))
	var iy:=Framework.intent_index(str(y.intent))
	if ix!=iy:return ix<iy
	return str(x.id)<str(y.id)

func mistake_rate() -> float:
	return float(T.mistake_rate)*exp(-float(experience)/maxf(0.1,float(D.mistake_decay)))

## A bounded, explainable mistake: with the current mistake rate, the plausible runner-up (scoring at least
## half the best) is chosen instead of the best. Never an ineligible, unaffordable or unready option.
func _maybe_mistake(valid: Array) -> Dictionary:
	if valid.is_empty():return {}
	var best: Dictionary=valid[0]
	if valid.size()>1 and float(valid[1].score)>=0.5*float(best.score) and float(best.urgency)<0.5:
		if rng.randf()<mistake_rate():
			var pick: Dictionary=valid[1].duplicate()
			pick["mistake"]=true;pick["instead_of"]=str(best.id)
			stats.mistakes+=1
			return pick
	return best

func _choose_instant(cands: Array,used: Dictionary) -> Dictionary:
	var blocked_resources: Dictionary={}
	var valid: Array=[]
	for c in cands:
		if c.kind!="instant" or used.has(c.id):continue
		if c.refusal=="unaffordable":
			var res: String=c.resource
			if res!="" and bool(D.save_for_goals) and not blocked_resources.has(res) and float(c.score)>=float(D.min_purchase_score) and c.shortfall<=0.9:
				blocked_resources[res]=c
				if str(saving.get(res,""))!=c.id:
					saving[res]=c.id;stats.save_for_goal+=1
					rec.event("decision",{"decision":"save_for_goal","intent":c.intent,"option":c.id,"resource":res,"shortfall":snappedf(c.shortfall,.01),"score":snappedf(c.score,.001)})
			continue
		if c.refusal!="":continue
		if c.resource!="":
			if blocked_resources.has(c.resource) and not c.bottleneck:continue
			if float(c.score)<float(D.min_purchase_score) and not c.bottleneck:continue
		elif float(c.score)<0.05:continue
		valid.append(c)
	for res in saving.keys():
		if not blocked_resources.has(res):saving.erase(res)
	return _maybe_mistake(valid)

func _choose_activity(cands: Array,reason: String) -> void:
	var acts: Array=cands.filter(func(c):return c.kind=="activity" and c.refusal=="")
	if acts.is_empty():
		if not current.is_empty():
			_note_refused(cands,{})
			adapter.cancel();current={}
		return
	var pick:=_maybe_mistake(acts)
	if current.is_empty():
		_start(pick,reason,cands);return
	var cur: Dictionary={}
	for c in acts:
		if c.id==current.id:cur=c;break
	if cur.is_empty():
		_start(pick,"current activity no longer available",cands);return
	current_score=float(cur.score)
	if pick.id==current.id:return
	if float(pick.urgency)>=float(D.urgent_reaction):
		_start(pick,"urgent",cands);return
	if now<commit_until:
		stats.holds+=1;return
	if float(pick.score)>float(cur.score)*(1.0+float(D.hysteresis)) and _switch_allowed():
		# Only abandoning a running plan counts against the re-evaluation limit; starting a new activity
		# after the previous one finished does not.
		stats.switches+=1
		switch_times.append(now)
		_start(pick,"better option",cands)

func _switch_allowed() -> bool:
	var window:=600.0*float(profile.get("time_scale",1.0))
	switch_times=switch_times.filter(func(x):return now-float(x)<window)
	return switch_times.size()<int(D.max_switches_10min)

func _start(o: Dictionary,reason: String,cands: Array) -> void:
	if not current.is_empty() and current.id!=o.id:adapter.cancel()
	var r: Dictionary=adapter.begin(o)
	var status:=str(r.get("status","rejected"))
	stats.activities_started+=1
	if status in ["started","done"]:
		current=o if status=="started" else {}
		current_score=float(o.score)
		var hold:=minf(MAX_HOLD_S*float(profile.get("time_scale",1.0)),maxf(tick_s,float(o.commitment_s)*float(D.hold_factor)))
		commit_until=now+hold
	else:
		current={}
	_record(o,status,str(r.get("reason","")),reason,cands)

func _activity_ended(status: String,why: String) -> void:
	var o:=current
	current={}
	idle_check=minf(idle_check,now+maxf(tick_s,0.3*float(D.deliberation_s)))
	if status=="done":
		experience+=1
		familiarity[o.feature]=minf(1.0,float(familiarity.get(o.feature,0.0))+float(D.familiarity_gain))
	else:
		_failure(o,true)
	stats.by_status["activity_"+status]=int(stats.by_status.get("activity_"+status,0))+1
	rec.event("outcome",{"option":o.id,"intent":o.intent,"status":status,"reason":why})

func _failure(o: Dictionary,game_failure: bool) -> void:
	var fam: String=o.family
	failures[fam]=int(failures.get(fam,0))+1
	var base:=float(D.base_cooldown_s)
	if game_failure:
		caution[fam]=float(caution.get(fam,0.0))+float(D.caution_step)
		cooldown_until[fam]=now+base*int(failures[fam])
	else:
		cooldown_until[fam]=now+base*0.25

## Logs one decision with its outcome. Refused options that outranked the choice are recorded too
## (collapsed by the recorder), so "unaffordable / not ready / cooldown / blocked" is visible evidence.
func _record(o: Dictionary,status: String,why: String,trigger: String,cands: Array) -> void:
	stats.decisions+=1
	stats.by_intent[o.intent]=int(stats.by_intent.get(o.intent,0))+1
	stats.by_status[status]=int(stats.by_status.get(status,0))+1
	if status in ["done","started"]:
		if o.kind=="instant":
			experience+=1
			familiarity[o.feature]=minf(1.0,float(familiarity.get(o.feature,0.0))+float(D.familiarity_gain))
	else:
		_failure(o,status=="failed")
	var row:={"decision":o.kind,"intent":o.intent,"option":o.id,"status":status,"score":snappedf(float(o.score),.001),"trigger":trigger}
	if why!="":row["reason"]=why
	if bool(o.get("mistake",false)):row["mistake"]=true;row["instead_of"]=str(o.instead_of)
	var second:=""
	for c in cands:
		if c.refusal=="" and c.id!=o.id and c.kind==o.kind:second=c.id;break
	if second!="":row["runner_up"]=second
	rec.event("decision",row)
	_note_refused(cands,o)

func _note_refused(cands: Array,chosen: Dictionary) -> void:
	var bar:=float(chosen.get("score",0.0))
	for c in cands:
		if float(c.score)<bar:break
		if c.refusal=="" or c.id==str(chosen.get("id","")):continue
		var key:=str(c.intent)+"|"+str(c.refusal)
		stats.refusals[key]=int(stats.refusals.get(key,0))+1
		rec.failure("option_"+str(c.refusal),c.block if c.block!="" else str(c.refusal),c.id,{"intent":c.intent},300.0)

## Ranks the options of the current game state as this profile would, without acting (reports and
## same-state profile comparisons). Uses a copy of the random stream so a run is never perturbed.
func preview() -> Array:
	var saved_state:=rng.state
	var saved_fam:=familiarity.duplicate()
	_obs=adapter.observe()
	var out: Array=[]
	for c in _collect():
		out.append({"id":c.id,"intent":c.intent,"kind":c.kind,"score":snappedf(float(c.score),.001),"refusal":c.refusal})
	rng.state=saved_state;familiarity=saved_fam
	return out

# ---------------------------------------------------------------- evidence
func summary() -> Dictionary:
	var fam: Dictionary={}
	var keys: Array=familiarity.keys();keys.sort()
	for k in keys:fam[k]=snappedf(float(familiarity[k]),.01)
	var cau: Dictionary={}
	keys=caution.keys();keys.sort()
	for k in keys:cau[k]=snappedf(float(caution[k]),.001)
	var secs: Dictionary={}
	keys=stats.activity_seconds.keys();keys.sort()
	for k in keys:secs[k]=snappedf(float(stats.activity_seconds[k]),.1)
	var out:=stats.duplicate(true)
	out.activity_seconds=secs
	out["unsupported_intents"]=unsupported
	out["experience"]=experience
	out["mistake_rate_end"]=snappedf(mistake_rate(),.0001)
	out["familiarity"]=fam
	var sh: Dictionary={}
	keys=share.keys();keys.sort()
	for k in keys:sh[k]=snappedf(float(share[k]),.001)
	out["recent_share_end"]=sh
	out["caution"]=cau
	out["failures"]=failures.duplicate()
	return out

func trace_sample() -> Dictionary:
	return {"engine_activity":str(current.get("id","")),"engine_intent":str(current.get("intent","")),"engine_score":snappedf(current_score,.001)}
