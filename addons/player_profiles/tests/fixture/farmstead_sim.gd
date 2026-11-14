extends RefCounted
## Farmstead: a deliberately tiny, NON-combat test game for the Player Profiles package's cross-game
## acceptance test. Production, building and town progression; no enemies, health, loot drops or resets.
## It is an interface-flexibility fixture, not a shipped game: passing it does not prove any real game's
## integration.
##
## Mechanics (all authoritative here; the adapter only calls these functions):
##  - Production: the sawmill makes wood and the market makes gold into the YARD (capped by the storehouse).
##    Yard goods must be collected by hand, unless the Foreman (automation) is owned.
##  - Town Hall levels 1..6 are the main milestones; levels 3, 5 and 6 also need festival stars.
##  - Festival: a 60 s risky event. Success chance = 0.25 + 0.15 * decorations (shown as a forecast). Success
##    gives a star and gold; failure loses the entry fee.
##  - Survey plots (exploration): each hall level makes 4 more plots accessible. A surveyed plot may show
##    relic signs; excavating such a plot (collection) finds its relic with a 70% chance per attempt.
##  - Contracts (optional): every 180 active seconds a wood-delivery contract for gold; it expires after 600 s.
##  - Chop wood by hand (manual income); chopping and tending are open-ended until the player switches.
##  - Variant "full": Foreman (auto-collect) and Ledger (offline production at 50% for up to 4 h, paid on claim).
##    Variant "plain": neither exists; closing the game pays nothing.

const VERSION:="farmstead-1"
const PLOTS:=24
const RELIC_PLOTS:=8

var variant:="full"
var rng:=RandomNumberGenerator.new()
var s: Dictionary={}
var last_refusal:=""

func setup(seed_value: int,game_variant: String) -> void:
	variant=game_variant
	rng.seed=hash("farmstead|%d" % seed_value)
	var relics: Array=[]
	var order: Array=range(PLOTS)
	for i in range(PLOTS-1,0,-1):
		var j:=rng.randi_range(0,i)
		var tmp=order[i];order[i]=order[j];order[j]=tmp
	for i in range(RELIC_PLOTS):relics.append(int(order[i]))
	relics.sort()
	s={"t":0.0,"wood":20.0,"gold":20.0,"yard_wood":0.0,"yard_gold":0.0,"hall":1,"stars":0,"sawmill":1,"market":1,"storehouse":0,
		"decor":0,"foreman":0,"ledger":0,"surveyed":[],"relic_plots":relics,"relics":[],"contract":{},"next_contract":120.0,
		"contracts_done":0,"contracts_missed":0,"festivals_won":0,"festivals_lost":0,"activity":"","activity_left":0.0,"activity_plot":-1,
		"offline_pending":{},"left_at":-1.0,"rng_state":str(rng.state)}

# ---------------------------------------------------------------- rules
func cap() -> float:return 100.0*(1+int(s.storehouse))
func wood_rate() -> float:return 0.5*int(s.sawmill)
func gold_rate() -> float:return 0.3*int(s.market)
func accessible_plots() -> int:return mini(PLOTS,4*int(s.hall))
func stars_needed(level: int) -> int:return {3:1,5:2,6:3}.get(level,0)
func festival_chance() -> float:return minf(0.95,0.25+0.15*int(s.decor))
func festival_fee() -> float:return 30.0*int(s.hall)
func automation_exists() -> bool:return variant=="full"

## Prices: {resource: amount}. Empty when the thing cannot be bought any more.
func price(what: String) -> Dictionary:
	match what:
		"sawmill":return {"gold":roundf(20.0*pow(1.6,int(s.sawmill)))}
		"market":return {"wood":roundf(25.0*pow(1.6,int(s.market)))}
		"storehouse":return {"gold":roundf(30.0*pow(1.8,int(s.storehouse)))}
		"decor":return {} if int(s.decor)>=5 else {"gold":roundf(40.0*pow(1.7,int(s.decor)))}
		"hall":return {} if int(s.hall)>=6 else {"gold":roundf(50.0*pow(2.2,int(s.hall)-1)),"wood":roundf(60.0*pow(2.2,int(s.hall)-1))}
		"foreman":return {} if not automation_exists() or int(s.foreman)>0 else {"gold":150.0}
		"ledger":return {} if not automation_exists() or int(s.ledger)>0 else {"gold":120.0,"wood":120.0}
	return {}

func can_pay(cost: Dictionary) -> bool:
	for k in cost:
		if float(s[k])<float(cost[k]):return false
	return true

func block_reason(what: String) -> String:
	var cost:=price(what)
	if cost.is_empty():return "MAXED" if what!="foreman" and what!="ledger" else ("NOT_IN_GAME" if not automation_exists() else "OWNED")
	if what=="hall" and int(s.stars)<stars_needed(int(s.hall)+1):return "NEEDS_STAR"
	if s.activity=="festival" and what=="hall":return "BUSY"
	for k in cost:
		if float(s[k])<float(cost[k]):return "NOT_ENOUGH_"+str(k).to_upper()
	return ""

# ---------------------------------------------------------------- player actions (each returns true or sets last_refusal)
func _refuse(key: String) -> bool:
	last_refusal=key;return false

func buy(what: String) -> bool:
	var block:=block_reason(what)
	if block!="":return _refuse(block)
	var cost:=price(what)
	for k in cost:s[k]=float(s[k])-float(cost[k])
	s[what]=int(s[what])+1
	return true

func collect_yard() -> bool:
	if float(s.yard_wood)+float(s.yard_gold)<=0.0:return _refuse("YARD_EMPTY")
	s.wood=float(s.wood)+float(s.yard_wood);s.gold=float(s.gold)+float(s.yard_gold)
	s.yard_wood=0.0;s.yard_gold=0.0
	return true

func deliver_contract() -> bool:
	if s.contract.is_empty():return _refuse("NO_CONTRACT")
	if float(s.wood)<float(s.contract.wood):return _refuse("NOT_ENOUGH_WOOD")
	s.wood=float(s.wood)-float(s.contract.wood);s.gold=float(s.gold)+float(s.contract.gold)
	s.contract={};s.contracts_done=int(s.contracts_done)+1
	return true

func claim_offline() -> bool:
	if s.offline_pending.is_empty():return _refuse("NOTHING_PENDING")
	s.wood=float(s.wood)+float(s.offline_pending.wood);s.gold=float(s.gold)+float(s.offline_pending.gold)
	s.offline_pending={}
	return true

## Starts an activity: "chop", "survey", "excavate" (plot), "festival", "tend".
func start(kind: String,plot: int=-1) -> bool:
	if s.activity!="":return _refuse("BUSY")
	match kind:
		"chop","tend":s.activity_left=1e12   # open-ended: runs until the player does something else
		"survey":
			if next_unsurveyed()<0:return _refuse("NOTHING_TO_SURVEY")
			s.activity_left=30.0;plot=next_unsurveyed()
		"excavate":
			if not excavatable().has(plot):return _refuse("NO_SIGNS_HERE")
			s.activity_left=40.0
		"festival":
			if float(s.gold)<festival_fee():return _refuse("NOT_ENOUGH_GOLD")
			s.gold=float(s.gold)-festival_fee();s.activity_left=60.0
		_:return _refuse("UNKNOWN_ACTIVITY")
	s.activity=kind;s.activity_plot=plot
	return true

func stop_activity() -> void:
	if s.activity=="festival":return   # a paid festival runs to its end
	s.activity="";s.activity_left=0.0;s.activity_plot=-1

func next_unsurveyed() -> int:
	for p in range(accessible_plots()):
		if not s.surveyed.has(p):return p
	return -1

## Surveyed plots that show relic signs and whose relic is not found yet.
func excavatable() -> Array:
	var out: Array=[]
	for p in s.surveyed:
		if s.relic_plots.has(p) and not s.relics.has(p):out.append(p)
	return out

# ---------------------------------------------------------------- time
## One step. Returns the finished activity's result ("" while running): "done", "won", "lost", "found", "nothing".
func step(dt: float) -> String:
	s.t=float(s.t)+dt
	s.yard_wood=minf(cap(),float(s.yard_wood)+wood_rate()*dt)
	s.yard_gold=minf(cap(),float(s.yard_gold)+gold_rate()*dt)
	if int(s.foreman)>0:collect_yard()
	if s.contract.is_empty() and float(s.t)>=float(s.next_contract):
		s.contract={"wood":40.0*int(s.hall),"gold":50.0*int(s.hall),"expires":float(s.t)+600.0}
		s.next_contract=float(s.t)+180.0
	elif not s.contract.is_empty() and float(s.t)>=float(s.contract.expires):
		s.contract={};s.contracts_missed=int(s.contracts_missed)+1
	if s.activity=="":return ""
	if s.activity=="chop":s.wood=float(s.wood)+1.5*dt
	s.activity_left=float(s.activity_left)-dt
	if float(s.activity_left)>1e-6:return ""
	var kind:=str(s.activity)
	var plot:=int(s.activity_plot)
	s.activity="";s.activity_left=0.0;s.activity_plot=-1
	match kind:
		"survey":
			if not s.surveyed.has(plot):s.surveyed.append(plot)
			return "done"
		"excavate":
			if rng.randf()<0.7:
				s.relics.append(plot);s.relics.sort();return "found"
			return "nothing"
		"festival":
			if rng.randf()<festival_chance():
				s.stars=int(s.stars)+1;s.festivals_won=int(s.festivals_won)+1;s.gold=float(s.gold)+60.0*int(s.hall);return "won"
			s.festivals_lost=int(s.festivals_lost)+1;return "lost"
	return "done"

## The game is closed at virtual second `unix`.
func leave(unix: float) -> void:
	stop_activity()
	s.left_at=unix
	s.rng_state=str(rng.state)

## The game is opened again at `unix`: offline production exists only with the Ledger (50%, at most 4 h).
func come_back(unix: float) -> Dictionary:
	var away:=maxf(0.0,unix-float(s.left_at))
	var paid:=0.0
	if int(s.ledger)>0 and away>0.0:
		paid=minf(away,4.0*3600.0)
		var pend: Dictionary=s.offline_pending if not s.offline_pending.is_empty() else {"wood":0.0,"gold":0.0,"seconds":0.0}
		pend.wood=float(pend.wood)+wood_rate()*0.5*paid;pend.gold=float(pend.gold)+gold_rate()*0.5*paid;pend.seconds=float(pend.seconds)+paid
		s.offline_pending=pend
	s.left_at=-1.0
	return {"away":away,"paid":paid}

# ---------------------------------------------------------------- persistence
func save_text() -> String:
	s.rng_state=str(rng.state)
	return JSON.stringify(s,"",true)

func load_text(text: String) -> bool:
	var parsed=JSON.parse_string(text)
	if not parsed is Dictionary:return false
	s=parsed
	for k in ["hall","stars","sawmill","market","storehouse","decor","foreman","ledger","contracts_done","contracts_missed","festivals_won","festivals_lost","activity_plot"]:s[k]=int(s[k])
	for k in ["surveyed","relic_plots","relics"]:
		var ints: Array=[]
		for v in s[k]:ints.append(int(v))
		s[k]=ints
	rng.state=int(str(s.rng_state))
	return true
