extends "../../core/adapter_base.gd"
## Farmstead's adapter: maps the fixture game's legitimate actions onto the generic intents. It is written
## exactly as a new game's adapter would be, using only the package's public contract.
##   claim_rewards     collect the yard, claim offline production
##   progress_main     upgrade the Town Hall (milestone, advances)
##   attempt_challenge hold a festival (risky; confidence = the shown forecast)
##   strengthen        decorations, storehouse
##   improve_economy   sawmill, market, chop wood by hand
##   invest_automation Foreman, Ledger (variant "full" only; "plain" declares it unsupported)
##   explore           survey the next plot
##   collect           excavate a plot that shows relic signs
##   complete_optional deliver the open wood contract
##   wait              tend the farm
##   recover           UNSUPPORTED (no health or danger in this game)

const Sim:=preload("farmstead_sim.gd")
const ADAPTER_VERSION:="farmstead-adapter-1"
const STRATEGY_VERSION:="farmstead-strategy-1"

var sim
var variant:="full"
var rec
var seed_value:=1
var start_unix:=0.0
var unix:=0.0
var active:=0.0
var _result:=""
var _saved:=""
var _persist_before:=""
var _error:=""
var start_res:={"wood":0.0,"gold":0.0}
var spent:={"wood":0.0,"gold":0.0}
var offline_paid_s:=0.0
var offline_claimed:={"wood":0.0,"gold":0.0}
var milestones: Array=[]
var _marked: Dictionary={}
var counts: Dictionary={}

func setup(context: Dictionary,game_variant: String) -> void:
	variant=game_variant;rec=context.recorder;seed_value=int(context.seed);start_unix=float(context.start_unix);unix=start_unix
	sim=Sim.new();sim.setup(seed_value,variant)
	start_res={"wood":float(sim.s.wood),"gold":float(sim.s.gold)}

# ---------------------------------------------------------------- identity
func integration_info() -> Dictionary:
	return {"game":"farmstead-fixture-"+variant,"adapter_version":ADAPTER_VERSION,"strategy_version":STRATEGY_VERSION,"contract":Framework.CONTRACT_VERSION}

func capabilities() -> Dictionary:
	var full:=variant=="full"
	var intents: Dictionary={}
	for i in Framework.INTENTS:intents[i]={"supported":true,"note":""}
	intents.recover={"supported":false,"note":"no health, damage or danger exists in this game"}
	if not full:intents.invest_automation={"supported":false,"note":"the plain variant has no automation or offline systems"}
	return {"intents":intents,"features":{"sessions":true,"offline":full,"automation":full,"persistence":true}}

func tick_seconds() -> float:return 1.0
func step_seconds() -> float:return 0.5

# ---------------------------------------------------------------- policy-facing
func observe() -> Dictionary:
	var s: Dictionary=sim.s
	var acc:=float(sim.accessible_plots())
	var known_sites:=0
	for p in s.surveyed:
		if s.relic_plots.has(p):known_sites+=1
	return {"progress":float(_progress()),"health":-1.0,"area_completion":float(s.surveyed.size())/maxf(1.0,acc),
		"collection_completion":1.0 if known_sites==0 else float(s.relics.size())/float(known_sites),
		"resources":{"wood":floorf(float(s.wood)),"gold":floorf(float(s.gold))},"urgent":[]}

func _progress() -> int:
	var s: Dictionary=sim.s
	return int(s.hall)*100000+int(s.stars)*10000+s.relics.size()*1000+s.surveyed.size()*10+int(s.sawmill)+int(s.market)+int(s.storehouse)+int(s.decor)+int(s.foreman)+int(s.ledger)+int(s.contracts_done)

func _buy_option(what: String,intent: String,benefit: float,extra: Dictionary={}) -> Dictionary:
	var cost: Dictionary=sim.price(what)
	var block: String=sim.block_reason(what)
	var o:={"id":"buy:"+what,"intent":intent,"kind":"instant","label":"buy "+what,"feature":"build","family":"buy:"+what,"benefit":benefit,"cost":cost}
	if cost.is_empty():return {}
	if block.begins_with("NOT_ENOUGH_"):
		o.affordable=false
		var short:=0.0
		for k in cost:short=maxf(short,1.0-float(sim.s[k])/maxf(1.0,float(cost[k])))
		o.shortfall=clampf(short,0.0,1.0)
	elif block!="":
		o.eligible=false;o.block=block
	for k in extra:o[k]=extra[k]
	return o

func options() -> Array:
	var s: Dictionary=sim.s
	var out: Array=[]
	var star_needed: bool=int(s.stars)<sim.stars_needed(int(s.hall)+1) and int(s.hall)<6
	var yard_fill: float=maxf(float(s.yard_wood),float(s.yard_gold))/float(sim.cap())
	# claims
	if int(s.foreman)==0 and float(s.yard_wood)+float(s.yard_gold)>=1.0:
		out.append({"id":"collect_yard","intent":"claim_rewards","kind":"instant","feature":"yard","benefit":clampf(yard_fill,0.1,1.0)})
	if not s.offline_pending.is_empty():
		out.append({"id":"claim_offline","intent":"claim_rewards","kind":"instant","feature":"offline","benefit":1.0})
	# Income is the bottleneck when, at the rates shown on screen, the next Town Hall level is over five
	# minutes away in that resource (a player can read the price and the production rate).
	var hall_cost: Dictionary=sim.price("hall")
	var slow:={"wood":false,"gold":false}
	for k in hall_cost:
		var rate: float=float(sim.wood_rate()) if k=="wood" else float(sim.gold_rate())
		slow[k]=(float(hall_cost[k])-float(s[k]))/maxf(0.01,rate)>300.0
	# main progression and preparation
	for o in [_buy_option("hall","progress_main",0.9,{"milestone":true,"advances":true,"feature":"town"}),
			_buy_option("decor","strengthen",0.6 if star_needed else 0.15,{"bottleneck":star_needed and sim.festival_chance()<0.6}),
			_buy_option("storehouse","strengthen",0.7 if yard_fill>=0.9 and int(s.foreman)==0 else 0.2),
			_buy_option("sawmill","improve_economy",0.55,{"bottleneck":slow.wood}),
			_buy_option("market","improve_economy",0.55,{"bottleneck":slow.gold}),
			_buy_option("foreman","invest_automation",0.7,{"feature":"automation"}),
			_buy_option("ledger","invest_automation",0.6,{"feature":"automation"})]:
		if not o.is_empty():out.append(o)
	if not s.contract.is_empty():
		var c: Dictionary=s.contract
		out.append({"id":"deliver_contract","intent":"complete_optional","kind":"instant","feature":"contracts","optional":true,"benefit":0.6,
			"cost":{"wood":float(c.wood)},"affordable":float(s.wood)>=float(c.wood),"shortfall":clampf(1.0-float(s.wood)/float(c.wood),0.0,1.0)})
	# activities (a running one stays offered and eligible). Chopping, tending, surveying and digging can be
	# stopped at any time; only a paid festival holds the player until it ends.
	var running: String=str(s.activity)
	var free:=running!="festival"
	out.append({"id":"chop","intent":"improve_economy","kind":"activity","feature":"chop","benefit":0.35,"commitment_s":30.0,
		"eligible":free,"block":"BUSY"})
	var plot: int=sim.next_unsurveyed()
	if plot>=0 or running=="survey":
		out.append({"id":"survey","intent":"explore","kind":"activity","feature":"survey","novelty":0.4,"commitment_s":30.0,
			"benefit":1.0-float(s.surveyed.size())/maxf(1.0,float(sim.accessible_plots())),"eligible":free,"block":"BUSY"})
	for p in sim.excavatable():
		var id:="excavate:%d" % int(p)
		out.append({"id":id,"intent":"collect","kind":"activity","feature":"excavate","family":"excavate","novelty":1.0,"benefit":0.5,"commitment_s":40.0,
			"eligible":free,"block":"BUSY"})
	if int(s.hall)<6 or running=="festival":
		var fee: float=sim.festival_fee()
		var o:={"id":"festival","intent":"attempt_challenge","kind":"activity","feature":"festival","family":"festival","confidence":sim.festival_chance(),
			"risk":0.5,"benefit":0.8 if star_needed else 0.3,"milestone":star_needed,"bottleneck":star_needed,"commitment_s":60.0,
			"eligible":true,"block":""}
		if running!="festival":
			o.cost={"gold":fee};o.affordable=float(s.gold)>=fee;o.shortfall=clampf(1.0-float(s.gold)/fee,0.0,1.0)
		out.append(o)
	out.append({"id":"tend","intent":"wait","kind":"activity","feature":"","benefit":0.05,"commitment_s":30.0,"eligible":free,"block":"BUSY"})
	return out

func begin(o: Dictionary) -> Dictionary:
	var id:=str(o.id)
	var ok:=false
	var kind:="instant"
	var before:={"wood":float(sim.s.wood),"gold":float(sim.s.gold)}
	if id.begins_with("buy:"):ok=sim.buy(id.trim_prefix("buy:"))
	elif id=="collect_yard":ok=sim.collect_yard()
	elif id=="claim_offline":
		var pend: Dictionary=sim.s.offline_pending.duplicate()
		ok=sim.claim_offline()
		if ok:offline_claimed.wood+=float(pend.wood);offline_claimed.gold+=float(pend.gold)
	elif id=="deliver_contract":ok=sim.deliver_contract()
	else:
		kind="activity"
		var parts:=id.split(":")
		if str(sim.s.activity)==parts[0] and (parts.size()==1 or int(sim.s.activity_plot)==int(parts[1])):return {"status":"started","reason":"already running"}
		if str(sim.s.activity)!="":sim.stop_activity()
		ok=sim.start(parts[0],int(parts[1]) if parts.size()>1 else -1)
	for k in ["wood","gold"]:
		var d:=float(sim.s[k])-float(before[k])
		if d<0 and id!="deliver_contract":spent[k]+=-d
	counts[id.split(":")[0]]=int(counts.get(id.split(":")[0],0))+(1 if ok else 0)
	if not ok:return {"status":"rejected","reason":sim.last_refusal}
	_mark_all()
	return {"status":"done" if kind=="instant" else "started","reason":""}

func advance(_now: float) -> Dictionary:
	var r:=_result
	_result=""
	_mark_all()
	match r:
		"done","found","won":return {"status":"done","reason":r}
		"lost":return {"status":"failed","reason":"FESTIVAL_LOST"}
		"nothing":return {"status":"failed","reason":"NOTHING_FOUND"}
	return {"status":"running" if str(sim.s.activity)!="" else "idle","reason":""}

func cancel() -> void:sim.stop_activity()

# ---------------------------------------------------------------- simulation and sessions
func set_clock(u: float) -> void:unix=u
func step(dt: float) -> bool:
	var r: String=sim.step(dt)
	if r!="":_result=r
	active+=dt
	return true
func failed() -> String:return _error
func goal_reached(goal: String) -> bool:return goal=="town-complete" and int(sim.s.hall)>=6
func session_can_end() -> bool:return str(sim.s.activity)!="festival"
func leave_session(_n: int) -> void:
	sim.leave(unix)
	_saved=sim.save_text()
	_persist_before=_view()
func return_session(_n: int,away_s: float,mode: String) -> String:
	if mode=="cold":
		sim=Sim.new();sim.variant=variant
		if not sim.load_text(_saved):return "persistence: the save did not load"
	if _view()!=_persist_before:return "persistence: the reloaded progression differs from what was left"
	var r: Dictionary=sim.come_back(unix)
	if absf(float(r.away)-away_s)>1.0:return "clock: the game measured %.1f s away, the driver %.1f s" % [float(r.away),away_s]
	offline_paid_s+=float(r.paid)
	rec.event("offline_settled",{"away_s":snappedf(away_s,.1),"paid_s":snappedf(float(r.paid),.1)})
	return ""

func _view() -> String:
	var s: Dictionary=sim.s
	return JSON.stringify([int(s.hall),int(s.stars),s.relics,s.surveyed,int(s.sawmill),int(s.market),int(s.storehouse),int(s.decor),int(s.foreman),int(s.ledger),
		snappedf(float(s.wood),.01),snappedf(float(s.gold),.01),int(s.contracts_done)])

# ---------------------------------------------------------------- telemetry
func _mark(key: String) -> void:
	if _marked.has(key):return
	_marked[key]=true
	milestones.append({"key":key,"t":snappedf(active,.1),"c":snappedf(unix-start_unix,.1)})
	rec.event("milestone",{"key":key})

func _mark_all() -> void:
	var s: Dictionary=sim.s
	for h in range(2,int(s.hall)+1):_mark("hall:%d" % h)
	for n in range(1,int(s.stars)+1):_mark("star:%d" % n)
	if not s.relics.is_empty():_mark("first_relic")
	if s.relics.size()>=Sim.RELIC_PLOTS:_mark("all_relics")
	if int(s.foreman)>0:_mark("automation:foreman")
	if int(s.ledger)>0:_mark("automation:ledger")

func progress_signature() -> String:return str(_progress())
func trace_sample() -> Dictionary:
	return {"hall":int(sim.s.hall),"wood":floorf(float(sim.s.wood)),"gold":floorf(float(sim.s.gold)),"activity":str(sim.s.activity)}
func state_digest() -> String:return sim.save_text().sha256_text()

func game_summary() -> Dictionary:
	var s: Dictionary=sim.s
	return {"variant":variant,"hall":int(s.hall),"stars":int(s.stars),"relics":s.relics.size(),"relic_sites":Sim.RELIC_PLOTS,"surveyed":s.surveyed.size(),
		"sawmill":int(s.sawmill),"market":int(s.market),"storehouse":int(s.storehouse),"decor":int(s.decor),"foreman":int(s.foreman),"ledger":int(s.ledger),
		"contracts_done":int(s.contracts_done),"contracts_missed":int(s.contracts_missed),"festivals_won":int(s.festivals_won),"festivals_lost":int(s.festivals_lost),
		"offline_paid_s":snappedf(offline_paid_s,.1),"offline_claimed":{"wood":snappedf(offline_claimed.wood,.01),"gold":snappedf(offline_claimed.gold,.01)},
		"actions":counts}

func generic_metrics() -> Dictionary:
	var econ: Dictionary={}
	for k in ["wood","gold"]:
		econ[k]={"earned":snappedf(float(sim.s[k])-float(start_res[k])+float(spent[k]),.01),"spent":snappedf(float(spent[k]),.01)}
	return {"milestones":milestones,"economy":econ,
		"automation_owned":int(sim.s.foreman)+int(sim.s.ledger) if variant=="full" else "unsupported",
		"main_milestone_level":int(sim.s.hall)}
