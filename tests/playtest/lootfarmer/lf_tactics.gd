extends RefCounted
## LootFarmer player-profile integration: TACTICS (how an activity is carried out in this game).
## Game-specific and profile-independent: no profile name and no profile constant appears here. Tactic
## parameters are derived from the universal traits in configure() (formulas below), so the same code
## plays every profile. Movement, farming, the boss attempt and the estimates are ported from the Phase 1
## Active policy (active_policy.gd, kept frozen as the `legacy` baseline); differences are listed in
## docs/LootFarmer_Player_Profiles_Framework_Integration.md.
##
## Activities: farm (open-ended), explore (a burst), boss (a committed attempt), rest, wait.
## Reflexes every tick, for every profile, at a profile-dependent cadence: tap visible loot, cast ready
## skills, drink a Health Potion, side-step when stuck, wait out death.
## Every outcome comes from the real simulation through the runtime adapter (lootfarmer_adapter.gd).
##
## Parameters from traits:
##   rest_until        0.95 - 0.25*risk_tolerance        HP a rest stops at
##   boss_rest_until   0.8 + 0.15*preparation            HP rested to before a boss attempt
##   potion_boss_below 0.45 + 0.4*attention              drink in a boss fight below this HP
##   potion_farm_below 0.25                              emergency potion while farming (never the boss reserve)
##   loot_every        4.0 - 3.5*attention   seconds     between loot taps
##   cast_every        attention < 0.3 ? only in boss fights : 8 - 7.5*attention seconds
##   explore_burst     60 + 90*exploration   seconds     one exploration burst
##   use_coin_boost    efficiency >= 0.4                 drinks an owned Coin Tonic while farming

const STEP_DECISION:=.5
const FARM_MARGIN:=1.3
const LANE:=90.0
const BOSS_AVOID:=280.0

var a                         # runtime adapter (lootfarmer_adapter.gd)
var P: Dictionary={}
var now:=0.0
var mode:="idle"
var reason:=""
var goal:=Vector2.INF
var stop_radius:=22.0
var hold:=false
var farm_group:=-1
var farm_variant:=2
var farm_since:=0.0
var boss:=-1
var boss_started:=0.0
var boss_resting:=false
var boss_potions:=0          # Health Potions reserved for the next boss attempt (never drunk while farming)
var explore_until:=0.0
var explore_target:=Vector2.INF
var waypoints: Array=[]
var waypoint_stage:=-1
var skipped: Dictionary={}
var last_pos:=Vector2.INF
var stuck_time:=0.0
var sidestep_until:=0.0
var sidestep_dir:=Vector2.ZERO
var next_loot:=0.0
var next_cast:=0.0
var deaths_seen:=0
var need_gear_slot:=false
var need_supply_slot:=false
var _result: Dictionary={}
var stats:={"explore_bursts":0,"explore_fights":0,"stuck":0,"boss_attempts":0,"rests":0}

func setup(runtime) -> void:a=runtime

func configure(profile: Dictionary) -> void:
    var t: Dictionary=profile.traits
    var att:=float(t.attention)
    P={"rest_until":0.95-0.25*float(t.risk_tolerance),"boss_rest_until":0.8+0.15*float(t.preparation),
        "potion_boss_below":0.45+0.4*att,"potion_farm_below":0.25,"loot_every":4.0-3.5*att,
        "cast_every":-1.0 if att<0.3 else 8.0-7.5*att,"explore_burst":60.0+90.0*float(t.exploration),
        "use_coin_boost":float(t.efficiency)>=0.4}

func describe() -> Dictionary:
    var out: Dictionary={}
    for k in P:out[k]=snappedf(float(P[k]),.001) if not P[k] is bool else P[k]
    return out

func _name(g: int) -> String:return "" if g<0 else str(a.group(g).id)

# ---------------------------------------------------------------- activity control
## Starts an activity. kind: farm (g, v), explore, boss (g), rest, wait.
func start(kind: String,g: int=-1,v: int=2) -> bool:
    _result={}
    match kind:
        "farm":
            if g!=farm_group:farm_since=now
            farm_group=g;farm_variant=v;mode="farm";reason="farming"
            _respawn_choice(a.spot(g,v))
        "explore":
            mode="explore";reason="exploration burst";explore_until=now+float(P.explore_burst);stats.explore_bursts+=1
            _stop_focus()
            if _next_waypoint()==Vector2.INF:return false
        "boss":
            boss=g;boss_started=now;boss_resting=a.hp_frac()<float(P.boss_rest_until);mode="boss";reason="committed attempt"
            stats.boss_attempts+=1
            _stop_focus()
            _respawn_choice(a.spot(g,2))
            a.note("boss_attempt_started",{"boss":_name(g),"level":a.level(),"margin":snappedf(boss_margin(g,a.quantity("potion")),.01),"potions":a.quantity("potion"),
                "damage":snappedf(float(a.stats().damage),.01),"max_hp":snappedf(a.max_hp(),.1)})
        "rest":
            mode="rest";reason="resting";stats.rests+=1;_stop_focus()
        "wait":
            mode="wait";reason="waiting";_stop_focus();goal=Vector2.INF;hold=true
        _:return false
    last_pos=Vector2.INF
    return true

## Stops the current activity (the engine switches plans). A committed boss attempt that is already in
## the fight counts as abandoned (a retreat).
func cancel() -> void:
    if mode=="boss" and boss>=0:_end_boss("retreat")
    if mode=="farm":_stop_focus()
    mode="idle";goal=Vector2.INF;hold=false;_result={}

## After a cold reload, a map change or a Prestige: positions and plans are stale.
func reset() -> void:
    if boss>=0:_end_boss("interrupted")
    mode="idle";goal=Vector2.INF;hold=false;farm_group=-1;boss=-1;waypoint_stage=-1;last_pos=Vector2.INF;_result={}
    deaths_seen=a.deaths.size()

# ---------------------------------------------------------------- every tick
func tick(t: float) -> Dictionary:
    now=t
    _result={}
    var died: bool=a.deaths.size()>deaths_seen
    deaths_seen=a.deaths.size()
    if not a.alive():
        hold=true;goal=Vector2.INF;last_pos=Vector2.INF
        if mode=="boss" and boss>=0:_end_boss("death");return {"status":"failed","reason":"DIED"}
        if died and mode in ["farm","explore"]:
            var was:=mode
            mode="idle"
            return {"status":"failed","reason":"DIED_WHILE_"+was.to_upper()}
        return {"status":"running" if mode!="idle" else "idle","reason":"dead"}
    _reflexes()
    match mode:
        "farm":_farm()
        "explore":_explore()
        "boss":_boss_step()
        "rest":_rest()
        "wait":hold=true;goal=Vector2.INF
    _watch_stuck()
    if not _result.is_empty():
        var r:=_result
        _result={}
        return r
    return {"status":"running" if mode!="idle" else "idle","reason":""}

func _finish(status: String,why: String) -> void:
    _result={"status":status,"reason":why}
    mode="idle";hold=false;goal=Vector2.INF

# ---------------------------------------------------------------- steering (every simulation step)
func steer() -> void:
    if not a.alive() or hold or goal==Vector2.INF:
        a.stop();return
    var p: Vector2=a.pos()
    if now<sidestep_until:
        a.move(sidestep_dir);return
    var offset: Vector2=goal-p
    if offset.length()<=stop_radius:
        a.stop();return
    a.move(offset)

# ---------------------------------------------------------------- reflexes
func _reflexes() -> void:
    if now>=next_loot:
        next_loot=now+float(P.loot_every)
        need_gear_slot=false;need_supply_slot=false
        var tapped:=false
        for drop in a.pickups():
            if not bool(drop.can_add):
                if str(drop.kind)=="consumable":need_supply_slot=true
                else:need_gear_slot=true
                continue
            if not tapped:
                tapped=true;a.collect(int(drop.uid))
    var drink_below: float=float(P.potion_boss_below) if mode=="boss" else (0.0 if boss_potions>0 else float(P.potion_farm_below))
    if a.in_combat() and a.hp_frac()<drink_below and a.quantity("potion")>0 and a.supply_block("potion")=="":a.use_supply("potion")
    if bool(P.use_coin_boost) and mode=="farm" and a.quantity("coin_boost")>0 and not a.coin_boost_running() and a.supply_block("coin_boost")=="" and a.in_combat():a.use_supply("coin_boost")
    var manual:=mode=="boss" or (float(P.cast_every)>=0.0 and now>=next_cast)
    if manual:
        if mode!="boss":next_cast=now+float(P.cast_every)
        var automatic: Array=a.automatic_skill_slots()
        var equipped: Array=a.skills()
        for i in range(a.skill_slots()):
            if str(equipped[i])!="" and not automatic.has(i) and a.cast_block(i)=="":a.cast(i)

# ---------------------------------------------------------------- estimates (choices only; outcomes come from the game)
func dps(g: int,is_boss: bool) -> float:
    var s: Dictionary=a.stats()
    var d: float=float(s.damage)*(1.0+float(s.crit)*(float(s.crit_damage)-1.0))*(1.0+float(s.speed))*(1.0+a.achievement_damage(g))
    if is_boss:d*=1.0+a.bonus("boss_damage")
    return d

## Survival margin of fighting `count` enemies of a spot one after another from full HP (>1 survives).
func farm_margin(g: int,v: int,count: int) -> float:
    var d: Dictionary=a.enemy(g,v)
    var hit:=dps(g,false)*100.0/(100.0+float(d.defense))
    var seconds:=float(d.hp)/maxf(.01,hit)*count
    var taken:=float(d.damage)/float(d.interval)*100.0/(100.0+float(a.stats().defense))
    if str(a.group(g).aggro_mode)=="group":taken*=3.0
    return a.max_hp()/maxf(.01,taken*seconds)

## Experience per second while fighting, weighted by how long the player can keep fighting before it must
## rest: margin/(margin+1) of the time (a type that forces a rest every few kills is worth less than its raw
## rate). Phase 1 used the raw rate.
func xp_rate(g: int,v: int) -> float:
    var d: Dictionary=a.enemy(g,v)
    var hit:=dps(g,false)*100.0/(100.0+float(d.defense))
    var m:=farm_margin(g,v,4)
    return float(d.xp)/(float(d.hp)/maxf(.01,hit)+1.5)*m/(m+1.0)

## Survival margin against a boss from full HP with `potions` Health Potions.
func boss_margin(g: int,potions: int) -> float:
    var d: Dictionary=a.enemy(g,2)
    var hit:=dps(g,true)*100.0/(100.0+float(d.defense))
    var seconds:=float(d.hp)/maxf(.01,hit)
    var taken: float=float(d.damage)/float(d.interval)*100.0/(100.0+float(a.stats().defense))*(1.0-a.bonus("boss_guard"))
    var drinkable:=mini(potions,int(seconds/maxf(1.0,a.supply_cooldown("potion")))+1)
    var pool: float=a.max_hp()*(1.0+drinkable*a.supply_heal_fraction("potion"))
    return pool/maxf(.01,taken*seconds)

## The boss estimate as a success confidence 0..1: margin 1.25 -> 0.5, 1.75 -> 1.0; a boss with skills
## costs 0.25 margin (the Phase 1 rule), since this estimate does not model skills.
func boss_confidence(g: int,potions: int) -> float:
    var m:=boss_margin(g,potions)
    if int(a.group(g).skills)>0:m-=0.25
    return clampf((m-0.75)/1.0,0.0,1.0)

## The map's next gate boss still to defeat this run (-1 when none or when the map is already passed).
func gate_boss() -> int:
    if a.unlocked_stage()>a.stage():return -1
    for g in a.stage_groups():
        var d: Dictionary=a.group(g)
        if bool(d.boss) and not bool(d.final) and a.stage_gates().has(str(d.id)) and a.run_kills(str(d.id))==0:return g
    return -1

func camp_useful(camp: Dictionary,work: Vector2) -> bool:
    if work==Vector2.INF:return false
    var mine:=INF
    for c in a.camps():
        if bool(c.owned):mine=minf(mine,Vector2(c.pos).distance_to(work))
    return Vector2(camp.pos).distance_to(work)<mine-120.0

# ---------------------------------------------------------------- farm
func _farm() -> void:
    var spot: Vector2=a.spot(farm_group,farm_variant)
    if a.focus_owned():
        # Focused Farming walks, targets and returns by itself; walking by hand would cancel it.
        if not a.focus_active(farm_group,farm_variant):
            if a.in_combat() and a.aggro_count()>0:
                hold=true;goal=Vector2.INF;return
            if a.focus(farm_group,farm_variant).ok:
                goal=Vector2.INF;hold=true;return
        else:
            goal=Vector2.INF;hold=true;return
    goal=spot;stop_radius=30.0
    var d: float=a.pos().distance_to(spot)
    hold=d<=40.0 or (a.locked_target()!="" and a.target_group()==farm_group and d<=140.0) or (a.aggro_count()>0 and d<=140.0)

func _stop_focus() -> void:
    if a.focus_group()>=0:a.focus(a.focus_group(),a.focus_variant())

func _respawn_choice(work: Vector2) -> void:
    if a.in_combat() or work==Vector2.INF:return
    var best:=-1
    var best_d:=INF
    for camp in a.camps():
        if bool(camp.owned) and Vector2(camp.pos).distance_to(work)<best_d:best_d=Vector2(camp.pos).distance_to(work);best=int(camp.index)
    if best>=0 and best!=a.respawn_camp():a.select_respawn(best)

# ---------------------------------------------------------------- rest
func _rest() -> void:
    if a.hp_frac()>=float(P.rest_until) and not a.boss_aggro():
        _finish("done","rested");return
    var best:=Vector2.INF
    for camp in a.camps():
        if bool(camp.owned) and (best==Vector2.INF or Vector2(camp.pos).distance_to(a.pos())<best.distance_to(a.pos())):best=Vector2(camp.pos)
    goal=best;stop_radius=40.0
    hold=best!=Vector2.INF and a.pos().distance_to(best)<=60.0

# ---------------------------------------------------------------- explore (fights back instead of abandoning the burst)
func _explore() -> void:
    if now>=explore_until:
        _finish("done","burst over");return
    if a.boss_aggro():
        _finish("failed","BOSS_ENGAGED");return
    if a.aggro_count()>0:
        # Phase 1 ended a burst on any aggro (finding P1). A player fights the ambush off and goes on.
        if goal!=Vector2.INF:stats.explore_fights+=1
        hold=true;goal=Vector2.INF;return
    var target:=_next_waypoint()
    if target==Vector2.INF:
        _finish("done","map explored");return
    goal=target;stop_radius=24.0;hold=false;explore_target=target

func _plan_waypoints() -> void:
    if waypoint_stage==a.stage():return
    waypoint_stage=a.stage();waypoints.clear();skipped.clear()
    var size: Vector2=a.stage_size()
    for y in range(int(ceil(size.y/LANE))):
        for x in range(int(ceil(size.x/LANE))):
            var w:=Vector2(minf(size.x-20.0,(x+.5)*LANE),minf(size.y-20.0,(y+.5)*LANE))
            if not a.solid_at(w):waypoints.append(w)

func unexplored_left() -> bool:
    _plan_waypoints()
    return _next_waypoint()!=Vector2.INF

func _next_waypoint() -> Vector2:
    _plan_waypoints()
    var p: Vector2=a.pos()
    var best:=Vector2.INF
    var best_d:=INF
    var kept: Array=[]
    var avoid: Array=_boss_arenas_to_avoid()
    for w in waypoints:
        if a.cell_known(w) or int(skipped.get(w,0))>=2:continue
        kept.append(w)
        var near_boss:=false
        for arena in avoid:
            if Vector2(w).distance_to(arena)<BOSS_AVOID:near_boss=true
        if near_boss:continue
        var d: float=Vector2(w).distance_to(p)
        if w==explore_target:d-=LANE
        if d<best_d:best_d=d;best=w
    waypoints=kept
    return best

## Arenas of found bosses that attack on sight and that this player cannot beat yet: exploration stays out.
func _boss_arenas_to_avoid() -> Array:
    var result: Array=[]
    for g in a.stage_groups():
        var d: Dictionary=a.group(g)
        if not bool(d.boss) or str(d.aggro_mode)=="passive" or not a.boss_found(str(d.id)):continue
        if boss_margin(g,a.quantity("potion"))<1.25:result.append(a.spot(g,2))
    return result

# ---------------------------------------------------------------- boss attempt
func _boss_step() -> void:
    var id:=_name(boss)
    if a.run_kills(id)>0:
        _end_boss("win");_finish("done","boss defeated");return
    if boss_resting:
        if a.hp_frac()<float(P.boss_rest_until) and not a.boss_aggro():
            var best:=Vector2.INF
            for camp in a.camps():
                if bool(camp.owned) and (best==Vector2.INF or Vector2(camp.pos).distance_to(a.pos())<best.distance_to(a.pos())):best=Vector2(camp.pos)
            goal=best;stop_radius=40.0;hold=best!=Vector2.INF and a.pos().distance_to(best)<=60.0
            reason="resting before the boss";return
        boss_resting=false;reason="committed attempt"
    var arena: Vector2=a.spot(boss,2)
    var seen: Array=a.actors(boss)
    if seen.is_empty():
        goal=arena;stop_radius=70.0;hold=a.pos().distance_to(arena)<=80.0
        return
    var target: Dictionary=seen[0]
    var d: Dictionary=a.enemy(boss,2)
    var boss_seconds:=float(target.hp)/maxf(.01,dps(boss,true))
    var taken:=float(d.damage)/float(d.interval)*100.0/(100.0+float(a.stats().defense))
    var my_seconds: float=a.hp()/maxf(.01,taken)
    if bool(target.aggro) and a.hp_frac()<.3 and a.quantity("potion")==0 and my_seconds<boss_seconds*.5 and float(target.hp)>float(d.hp)*.6:
        _end_boss("retreat");mode="rest";_result={"status":"failed","reason":"RETREATED"};return
    if a.locked_target()!=str(target.id):
        if Vector2(target.pos).distance_to(a.pos())<=200.0:
            a.select_target(str(target.id))
            hold=true;goal=Vector2.INF;return
        goal=Vector2(target.pos);stop_radius=120.0;hold=false
        return
    hold=true;goal=Vector2.INF

func _end_boss(outcome: String) -> void:
    if boss<0:return
    var row: Dictionary={"boss":_name(boss),"outcome":outcome,"started_t":snappedf(boss_started,.1),"seconds":snappedf(now-boss_started,.1),"level":a.level()}
    a.note("boss_attempt_ended",row);a.boss_attempt(row)
    boss=-1

# ---------------------------------------------------------------- stuck
func _watch_stuck() -> void:
    var p: Vector2=a.pos()
    if hold or goal==Vector2.INF or last_pos==Vector2.INF or now<sidestep_until:
        last_pos=p;stuck_time=0.0;return
    if p.distance_to(last_pos)<a.move_speed()*STEP_DECISION*.25:stuck_time+=STEP_DECISION
    else:stuck_time=0.0
    last_pos=p
    if stuck_time>=2.0:
        stuck_time=0.0;stats.stuck+=1
        var forward: Vector2=(goal-p).normalized()
        var side:=Vector2(-forward.y,forward.x)
        if int(now)%2==0:side=-side
        sidestep_dir=(side+forward*.2).normalized();sidestep_until=now+1.5
        if mode=="explore":skipped[explore_target]=int(skipped.get(explore_target,0))+1
        a.note("stuck",{"mode":mode,"x":snappedf(p.x,1),"y":snappedf(p.y,1)})
