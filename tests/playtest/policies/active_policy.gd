extends RefCounted
## Player-profile playtesting: the ACTIVE player policy (Phase 1; the only implemented profile).
## "Plays frequently and prioritises efficient progression." One continuous session, no offline time.
## It sees the game only through the adapter's observations and acts only through its named actions.
## Estimates below choose what to try; every outcome comes from the real simulation.
##
## Decision priorities, in order, every 0.5 s of active time:
##  1. Claims: finished daily missions, ready main objectives, the 30-defeat mission.
##  2. Gear: pick up visible loot (one tap per decision), wear the pair the game's own comparison rates
##     best, merge every spare copy (the game's caps apply), evolve a weapon as soon as the game allows.
##  3. Spending, with a savings goal:
##       Gems  - an equipment/supply slot the moment a pickup is refused for room, Focused Farming (25),
##               Gem Chance level 1, then Auto-Collect for a type it has farmed for five minutes.
##       Coins - while a boss is close to beatable, Health Potions for that attempt come first and other
##               purchases keep that reserve; otherwise the cheapest of: Enemy XP, Loot Chance and Coin
##               Amount for the farmed type, Movement, Map Details 1, a nearer camp.
##  4. Supplies and skills: Coin Tonic while farming; Health Potions from 80% HP down in a boss fight and only
##     below 25% while farming (never the ones saved for a boss); every ready skill.
##  5. Prestige: the first reset as soon as the game allows it (card by a fixed preference list); later
##     resets only with a ready opportunity and at least PRESTIGE_GAP active minutes since the last.
##  6. Where to be: a boss it estimates it can beat (rest to full first, then a committed attempt that ends
##     only in a win, a death or a doomed-fight retreat); else the next map when its weakest type is
##     farmable; else the best experience per second it can sustain; with short exploration bursts while
##     the map still has unexplored ground; rest at a camp when low.
##     It stays out of reach of an aggressive boss it cannot beat yet and walks away if one engages it.
## Movement is steered every game step toward one goal point with a stop radius larger than a step.
##
## Known simplifications (policy, not game): it farms the two-piece loadout even where a one-piece loadout
## would give more experience per second, it never keeps copies for Collection contracts, never drops
## an item to free a slot, farms one spot instead of rotating spots, and does not model boss skills (it only
## asks for a wider margin, +0.25, against a boss that has any).

const VERSION:="active-1"
const DECISION:=.5
const BOSS_MARGIN:=1.25          # estimated survival margin needed to start a boss attempt
const BOSS_MARGIN_PER_LOSS:=.15  # more caution after each lost attempt at the same boss
const FARM_MARGIN:=1.3
const REST_BELOW:=.35
const REST_UNTIL:=.95
const POTION_BELOW:=.25         # farming: emergency only
const POTION_BOSS_BELOW:=.8     # boss fight: as soon as the game allows a potion
const COLLECT_AFTER:=300.0      # Auto-Collect for a type only after farming it this long
const EXPLORE_BURST:=90.0
const EXPLORE_EVERY:=180.0
const LANE:=90.0
const BOSS_AVOID:=280.0         # exploration keeps this far from an aggressive boss it cannot beat
const PRESTIGE_GAP:=1800.0
const CARD_PREFERENCE:=["boss_damage","damage","hp","xp","normal_xp","coins","normal_coins","gear_chance","boss_guard"]
const TYPE_TARGETS:=[["group_xp",8],["loot",6],["coin_amount",4]]

var a                         # the adapter
var now:=0.0                  # active seconds, advanced by decide()
var mode:="idle"
var goal:=Vector2.INF
var stop_radius:=22.0
var hold:=false               # stand still (fighting or resting)
var farm_group:=-1
var farm_variant:=2
var farm_since:=0.0
var boss:=-1                  # committed boss group, or -1
var boss_started:=0.0
var boss_losses: Dictionary={}
var boss_potions:=0
var waypoints: Array=[]
var waypoint_stage:=-1
var explore_until:=0.0
var next_explore:=0.0
var explore_target:=Vector2.INF
var last_pos:=Vector2.INF
var stuck_time:=0.0
var sidestep_until:=0.0
var sidestep_dir:=Vector2.ZERO
var skipped: Dictionary={}
var last_prestige:=-1e9
var reason:=""
var need_gear_slot:=false
var need_supply_slot:=false
var want_potion_slot:=false
var last_mode_note:=""

func setup(adapter) -> void:
    a=adapter

func trace_sample() -> Dictionary:
    var sample: Dictionary={"mode":mode,"why":reason,"farm":_name(farm_group),"farm_variant":farm_variant,"boss":_name(boss),"hold":hold}
    if goal!=Vector2.INF:sample["goal_x"]=snappedf(goal.x,1);sample["goal_y"]=snappedf(goal.y,1)
    var gate:=_gate_boss()
    if gate>=0:sample["boss_margin"]=snappedf(_boss_margin(gate,a.quantity("potion")),.01);sample["boss_need"]=snappedf(_boss_need(gate),.01)
    return sample

func _name(g: int) -> String:return "" if g<0 else str(a.group(g).id)

# ------------------------------------------------------------------ steering (every game step)
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

# ------------------------------------------------------------------ decisions
func decide() -> void:
    now+=DECISION
    if a.prestige_batch_open():
        _finish_prestige();return
    if not a.alive():
        if boss>=0:_end_boss("death")
        hold=true;mode="dead";reason="waiting to respawn";last_pos=Vector2.INF
        return
    _claims()
    _loot()
    _gear()
    _spend()
    _supplies_and_skills()
    _respawn_choice()
    if _prestige():return
    _choose()
    _watch_stuck()
    if mode!=last_mode_note:
        last_mode_note=mode
        a.note("mode",{"mode":mode,"why":reason,"level":a.level(),"hp":snappedf(a.hp_frac(),.01)})

func _claims() -> void:
    for i in a.missions_claimable():a.claim_mission(i)
    for i in a.main_ready():a.claim_main(i)
    if a.hunt_claimable():a.claim_hunt()

func _loot() -> void:
    need_gear_slot=false;need_supply_slot=false
    var tapped:=false
    for drop in a.pickups():
        if not bool(drop.can_add):
            if str(drop.kind)=="consumable":need_supply_slot=true
            else:need_gear_slot=true
            continue
        if not tapped:
            tapped=true
            a.collect(int(drop.uid))

func _gear() -> void:
    var list: Array=a.items()
    for item in list:
        if bool(item.can_merge):a.merge_copies(str(item.id))
    for item in a.items():
        if bool(item.can_evolve):a.evolve(str(item.id))
    # The pair the game's own comparison (stats_with) rates best. Never change gear mid-fight with a boss.
    if boss>=0 and mode=="boss":return
    var weapons: Array=[""]
    var outfits: Array=[""]
    for item in a.items():
        if str(item.kind)=="weapon":weapons.append(str(item.id))
        elif str(item.kind)=="outfit":outfits.append(str(item.id))
    var best_w: String=a.weapon()
    var best_o: String=a.outfit()
    var best: float=_power(a.stats_with(best_w,best_o))
    for w in weapons:
        for o in outfits:
            var score:=_power(a.stats_with(w,o))
            if score>best*1.0001:best=score;best_w=w;best_o=o
    if best_w!=a.weapon() and best_w!="":a.equip(best_w)
    if best_o!=a.outfit() and best_o!="":a.equip(best_o)
    var equipped: Array=a.skills()
    var free: int=0
    for i in range(a.skill_slots()):
        if str(equipped[i])=="":free+=1
    if free>0:
        for item in a.items():
            if free>0 and str(item.kind)=="skill" and not equipped.has(str(item.id)):
                if a.equip_skill(str(item.id)).ok:free-=1

func _power(s: Dictionary) -> float:
    return float(s.damage)*(1.0+float(s.crit)*(float(s.crit_damage)-1.0))*(1.0+float(s.speed))*float(s.hp)*(1.0+float(s.defense)/100.0)

func _spend() -> void:
    # Gems.
    if need_gear_slot and a.upgrade("gear_slots").block=="":a.buy_upgrade("gear_slots")
    elif (need_supply_slot or want_potion_slot) and a.upgrade("supply_slots").block=="":a.buy_upgrade("supply_slots")
    elif not a.focus_owned():
        if a.upgrade("focus").block=="":a.buy_upgrade("focus")
    elif int(a.upgrade("gem_chance").level)<1:
        if a.upgrade("gem_chance").block=="":a.buy_upgrade("gem_chance")
    elif farm_group>=0 and now-farm_since>=COLLECT_AFTER and int(a.upgrade("collect",farm_group).level)<1 and a.gems()>=float(a.upgrade("collect",farm_group).cost)+float(a.upgrade("gear_slots").cost):
        if a.upgrade("collect",farm_group).block=="":a.buy_upgrade("collect",farm_group)
    # Coins: the boss reserve first.
    var reserve:=_boss_reserve()
    if want_potion_slot and a.upgrade("supply_slots").block=="":a.buy_upgrade("supply_slots")
    if boss_potions>0 and a.quantity("potion")<boss_potions and not a.in_combat():
        if a.coins()>=float(a.supply_price("potion")) and (a.quantity("potion")>0 or a.supply_free()>0):a.buy_supply("potion")
        return
    var wanted: Array=[]
    if farm_group>=0:
        for pair in TYPE_TARGETS:wanted.append([str(pair[0]),farm_group,int(pair[1])])
    wanted.append(["movement",-1,2])
    wanted.append(["map_detail",a.stage(),1])
    var pick: Array=[]
    var price:=INF
    for w in wanted:
        var u: Dictionary=a.upgrade(str(w[0]),int(w[1]))
        if int(u.level)>=int(w[2]) or not (str(u.block) in ["","NOT_ENOUGH_COINS"]):continue
        if float(u.cost)<price:price=float(u.cost);pick=w
    for camp in a.camps():
        if bool(camp.owned) or not bool(camp.known) or not _camp_useful(camp):continue
        if float(camp.price)<price:price=float(camp.price);pick=["camp",int(camp.index),0]
    if pick.is_empty() or a.coins()-price<reserve:return
    if str(pick[0])=="camp":a.buy_camp(int(pick[1]))
    else:a.buy_upgrade(str(pick[0]),int(pick[1]))

## Coins held back for Health Potions when the map's gate boss is nearly beatable: enough potions to
## lift the estimate over the needed margin, at most what the fight's length lets the player drink.
func _boss_reserve() -> float:
    boss_potions=0;want_potion_slot=false
    var gate:=_gate_boss()
    if gate<0 or a.supply_price("potion")<=0:return 0.0
    var need:=_boss_need(gate)
    if _boss_margin(gate,0)>=need or _boss_margin(gate,0)<.55:return 0.0
    for n in range(1,9):
        if _boss_margin(gate,n)>=need:
            boss_potions=n
            # Potions need a supply slot of their own when another supply holds the only one.
            want_potion_slot=not (a.quantity("potion")>0 or a.supply_free()>0)
            return maxf(0.0,float(n-a.quantity("potion"))*float(a.supply_price("potion")))
    return 0.0

func _camp_useful(camp: Dictionary) -> bool:
    # A camp is worth buying when it is closer than every owned camp to where this player works.
    var work:=Vector2.INF
    var gate:=_gate_boss()
    if gate>=0 and a.group_discovered(gate):work=a.spot(gate,2)
    elif farm_group>=0:work=a.spot(farm_group,farm_variant)
    if work==Vector2.INF:return false
    var mine:=INF
    for c in a.camps():
        if bool(c.owned):mine=minf(mine,Vector2(c.pos).distance_to(work))
    return Vector2(camp.pos).distance_to(work)<mine-120.0

func _supplies_and_skills() -> void:
    # Health Potions: early and often in a boss fight (each one is 12 s apart); while farming only as an
    # emergency, and never the ones being saved for a boss.
    var drink_below: float=POTION_BOSS_BELOW if mode=="boss" else (0.0 if boss_potions>0 else POTION_BELOW)
    if a.in_combat() and a.hp_frac()<drink_below and a.quantity("potion")>0 and a.supply_block("potion")=="":a.use_supply("potion")
    if mode=="farm" and a.quantity("coin_boost")>0 and not a.coin_boost_running() and a.supply_block("coin_boost")=="" and a.in_combat():a.use_supply("coin_boost")
    var equipped: Array=a.skills()
    for i in range(a.skill_slots()):
        if str(equipped[i])!="" and a.cast_block(i)=="":a.cast(i)

# ------------------------------------------------------------------ Prestige
func _prestige() -> bool:
    if boss>=0 or a.in_combat() or a.prestige_block()!="":return false
    if a.prestiges()>0 and now-last_prestige<PRESTIGE_GAP:return false
    # Settle what a player would settle first; claims already ran this decision.
    a.note("prestige_decision",{"awardable":a.awardable(),"level":a.level(),"prestiges":a.prestiges()})
    if not a.begin_prestige().ok:return false
    _finish_prestige()
    return true

func _finish_prestige() -> void:
    var guard:=0
    while a.prestige_batch_open() and guard<60:
        guard+=1
        var offered: Array=a.offered_cards()
        if offered.is_empty():break
        var pick: String=str(offered[0].id)
        var rank:=CARD_PREFERENCE.size()
        for card in offered:
            var at:=CARD_PREFERENCE.find(str(card.effect))
            if at>=0 and at<rank:rank=at;pick=str(card.id)
        if not a.choose_card(pick).ok:break
    if not a.prestige_batch_open():
        last_prestige=now
        mode="idle";goal=Vector2.INF;hold=false;farm_group=-1;boss=-1;waypoint_stage=-1;last_pos=Vector2.INF
        next_explore=now

# ------------------------------------------------------------------ estimates (choices only)
func _dps(g: int,is_boss: bool) -> float:
    var s: Dictionary=a.stats()
    var dps: float=float(s.damage)*(1.0+float(s.crit)*(float(s.crit_damage)-1.0))*(1.0+float(s.speed))*(1.0+a.achievement_damage(g))
    if is_boss:dps*=1.0+a.bonus("boss_damage")
    return dps

## Survival margin of fighting `count` enemies of a spot one after another from current HP (>1 survives).
func _farm_margin(g: int,v: int,count: int) -> float:
    var d: Dictionary=a.enemy(g,v)
    var dps:=_dps(g,false)*100.0/(100.0+float(d.defense))
    var seconds:=float(d.hp)/maxf(.01,dps)*count
    var taken:=float(d.damage)/float(d.interval)*100.0/(100.0+float(a.stats().defense))
    if str(a.group(g).aggro_mode)=="group":taken*=3.0
    return a.max_hp()/maxf(.01,taken*seconds)

func _xp_rate(g: int,v: int) -> float:
    var d: Dictionary=a.enemy(g,v)
    var dps:=_dps(g,false)*100.0/(100.0+float(d.defense))
    return float(d.xp)/(float(d.hp)/maxf(.01,dps)+1.5)

## Survival margin against a boss from full HP with `potions` Health Potions available.
func _boss_margin(g: int,potions: int) -> float:
    var d: Dictionary=a.enemy(g,2)
    var dps:=_dps(g,true)*100.0/(100.0+float(d.defense))
    var seconds:=float(d.hp)/maxf(.01,dps)
    var taken: float=float(d.damage)/float(d.interval)*100.0/(100.0+float(a.stats().defense))*(1.0-a.bonus("boss_guard"))
    var drinkable:=mini(potions,int(seconds/maxf(1.0,a.supply_cooldown("potion")))+1)
    var pool: float=a.max_hp()*(1.0+drinkable*a.supply_heal_fraction("potion"))
    return pool/maxf(.01,taken*seconds)

func _boss_need(g: int) -> float:
    var need:=BOSS_MARGIN+BOSS_MARGIN_PER_LOSS*int(boss_losses.get(g,0))
    if int(a.group(g).skills)>0:need+=.25
    return need

## The map's next gate boss still to defeat this run (-1 when none or when the map is already passed).
func _gate_boss() -> int:
    if a.unlocked_stage()>a.stage():return -1
    for g in a.stage_groups():
        var d: Dictionary=a.group(g)
        if bool(d.boss) and not bool(d.final) and a.stage_gates().has(str(d.id)) and a.run_kills(str(d.id))==0:return g
    return -1

# ------------------------------------------------------------------ where to be
func _choose() -> void:
    # A committed boss attempt: win, death (handled in decide) or a doomed-fight retreat.
    if boss>=0:
        _boss_step();return
    # An aggressive boss this player did not choose to fight: leave its reach, as a player who read the
    # boss warning would, instead of standing in a fight the estimate says is lost.
    if a.boss_aggro():
        _rest("leaving a boss it did not choose to fight");return
    if mode=="rest":
        if a.hp_frac()<REST_UNTIL:
            _rest("recovering to %d%%" % int(REST_UNTIL*100));return
    elif a.hp_frac()<REST_BELOW and a.aggro_count()==0:
        _rest("HP below %d%%" % int(REST_BELOW*100));return
    # Next map as soon as its weakest type is farmable.
    if a.unlocked_stage()>a.stage() and not a.in_combat():
        var next_stage: int=a.stage()+1
        var weakest: int=int(a.stage_groups(next_stage)[0])
        if _farm_margin(weakest,2,3)>=FARM_MARGIN and a.travel_block(next_stage,0)=="":
            if a.travel(next_stage,0).ok:
                farm_group=-1;waypoint_stage=-1;mode="idle";goal=Vector2.INF;hold=false;next_explore=now;last_pos=Vector2.INF
                return
    # The gate boss when the estimate says so.
    var gate:=_gate_boss()
    if gate>=0 and a.group_discovered(gate):
        var stock: int=a.quantity("potion")
        if _boss_margin(gate,stock)>=_boss_need(gate) and (boss_potions==0 or stock>=boss_potions):
            if a.hp_frac()<REST_UNTIL:
                _rest("resting before the boss");return
            if a.aggro_count()==0:
                boss=gate;boss_started=now
                a.note("boss_attempt_started",{"boss":_name(gate),"level":a.level(),"margin":snappedf(_boss_margin(gate,stock),.01),"needed":snappedf(_boss_need(gate),.01),"potions":stock,
                    "damage":snappedf(float(a.stats().damage),.01),"max_hp":snappedf(a.max_hp(),.1)})
                _boss_step();return
    _pick_farm()
    # Exploration bursts while the map has unexplored ground; all the time when nothing is farmable yet.
    _plan_waypoints()
    var unexplored:=_next_waypoint()
    if unexplored!=Vector2.INF and a.aggro_count()==0:
        if farm_group<0:
            _explore(unexplored,"nothing farmable known");return
        if mode=="explore" and now<explore_until:
            _explore(unexplored,"exploration burst");return
        if mode!="explore" and now>=next_explore and a.hp_frac()>=.7:
            explore_until=now+EXPLORE_BURST;next_explore=now+EXPLORE_BURST+EXPLORE_EVERY
            _explore(unexplored,"exploration burst");return
    if farm_group<0:
        mode="idle";reason="nothing to do";goal=Vector2.INF;hold=true;return
    _farm()

func _pick_farm() -> void:
    # The type with the best sustainable experience per second, judged on the loadout this player farms:
    # the one that drops both weapon and outfit (gear is progression too), or the skill loadout while a
    # skill it carries is still missing. A one-piece loadout is only a fallback when nothing else is found.
    var best:=-1
    var best_v:=2
    var rate:=-1.0
    for g in a.stage_groups():
        var d: Dictionary=a.group(g)
        if bool(d.boss):continue
        var choice:=-1
        for v in [3,2,1,0]:
            if not a.variants(g).has(v) or not a.spot_discovered(g,v) or _farm_margin(g,v,4)<FARM_MARGIN:continue
            if v==3 and not a.missing_skill(g):continue
            choice=v;break
        if choice<0:continue
        var r:=_xp_rate(g,choice)
        if r>rate:rate=r;best=g;best_v=choice
    if best!=farm_group or best_v!=farm_variant:
        if best!=farm_group:farm_since=now
        farm_group=best;farm_variant=best_v
        if best>=0:a.note("farm_target",{"enemy":_name(best),"variant":best_v,"xp_rate":snappedf(rate,.01),"level":a.level()})

func _farm() -> void:
    mode="farm";reason="best sustainable experience"
    var spot: Vector2=a.spot(farm_group,farm_variant)
    if a.focus_owned():
        # Focused Farming walks, targets and returns by itself; walking by hand would cancel it.
        if not a.focus_active(farm_group,farm_variant):
            if a.focus(farm_group,farm_variant).ok:
                goal=Vector2.INF;hold=true;return
        else:
            goal=Vector2.INF;hold=true;return
    goal=spot;stop_radius=30.0
    var d: float=a.pos().distance_to(spot)
    # Stand and let auto-attack work once at the spot; walking would drop the target.
    hold=d<=40.0 or (a.locked_target()!="" and a.target_group()==farm_group and d<=140.0) or (a.aggro_count()>0 and d<=140.0)

func _rest(why: String) -> void:
    _stop_focus()
    mode="rest";reason=why
    var best:=Vector2.INF
    for camp in a.camps():
        if bool(camp.owned) and (best==Vector2.INF or Vector2(camp.pos).distance_to(a.pos())<best.distance_to(a.pos())):best=Vector2(camp.pos)
    goal=best;stop_radius=40.0
    hold=a.pos().distance_to(best)<=60.0

## Farm / Stop is one toggle: tapping the active target turns Focused Farming off.
func _stop_focus() -> void:
    if a.focus_group()>=0:a.focus(a.focus_group(),a.focus_variant())

## Respawn at the owned camp nearest to where this player works (the boss once it is nearly beatable).
func _respawn_choice() -> void:
    if a.in_combat():return
    var work:=Vector2.INF
    var gate:=_gate_boss()
    if gate>=0 and a.group_discovered(gate) and _boss_margin(gate,a.quantity("potion"))>=.55:work=a.spot(gate,2)
    elif farm_group>=0:work=a.spot(farm_group,farm_variant)
    if work==Vector2.INF:return
    var best:=-1
    var best_d:=INF
    for camp in a.camps():
        if bool(camp.owned) and Vector2(camp.pos).distance_to(work)<best_d:best_d=Vector2(camp.pos).distance_to(work);best=int(camp.index)
    if best>=0 and best!=a.respawn_camp():a.select_respawn(best)

func _explore(target: Vector2,why: String) -> void:
    _stop_focus()
    mode="explore";reason=why;goal=target;stop_radius=24.0;hold=false;explore_target=target

func _boss_step() -> void:
    mode="boss";reason="committed attempt"
    var id:=_name(boss)
    if a.run_kills(id)>0:
        _end_boss("win");return
    var arena: Vector2=a.spot(boss,2)
    var seen: Array=a.actors(boss)
    _stop_focus()
    if seen.is_empty():
        # Walk to the arena; if the boss is not there (respawning), wait at the edge.
        goal=arena;stop_radius=70.0;hold=a.pos().distance_to(arena)<=80.0
        return
    var target: Dictionary=seen[0]
    # Doomed-fight retreat: far behind on the damage race with little HP left.
    var d: Dictionary=a.enemy(boss,2)
    var dps:=_dps(boss,true)
    var boss_seconds:=float(target.hp)/maxf(.01,dps)
    var taken:=float(d.damage)/float(d.interval)*100.0/(100.0+float(a.stats().defense))
    var my_seconds: float=a.hp()/maxf(.01,taken)
    if bool(target.aggro) and a.hp_frac()<.3 and a.quantity("potion")==0 and my_seconds<boss_seconds*.5 and float(target.hp)>float(d.hp)*.6:
        _end_boss("retreat");_rest("retreating from a lost boss fight");return
    if a.locked_target()!=str(target.id):
        if Vector2(target.pos).distance_to(a.pos())<=200.0:
            a.select_target(str(target.id))
            hold=true;goal=Vector2.INF;return
        goal=Vector2(target.pos);stop_radius=120.0;hold=false
        return
    hold=true;goal=Vector2.INF

func _end_boss(outcome: String) -> void:
    var row: Dictionary={"boss":_name(boss),"outcome":outcome,"started_t":snappedf(boss_started,.1),"seconds":snappedf(now-boss_started,.1),"level":a.level()}
    a.note("boss_attempt_ended",row);a.boss_attempt(row)
    if outcome!="win":boss_losses[boss]=int(boss_losses.get(boss,0))+1
    boss=-1;mode="idle";reason="boss attempt ended";hold=false;goal=Vector2.INF

# ------------------------------------------------------------------ exploration
func _plan_waypoints() -> void:
    if waypoint_stage==a.stage():return
    waypoint_stage=a.stage();waypoints.clear();skipped.clear()
    var size: Vector2=a.stage_size()
    var columns:=int(ceil(size.x/LANE))
    var rows:=int(ceil(size.y/LANE))
    for y in range(rows):
        for x in range(columns):
            var w:=Vector2(minf(size.x-20.0,(x+.5)*LANE),minf(size.y-20.0,(y+.5)*LANE))
            if not a.solid_at(w):waypoints.append(w)

func _next_waypoint() -> Vector2:
    var p: Vector2=a.pos()
    var best:=Vector2.INF
    var best_d:=INF
    var kept: Array=[]
    var avoid: Array=_boss_arenas_to_avoid()
    for w in waypoints:
        if a.cell_known(w) or skipped.has(w):continue
        kept.append(w)
        var near_boss:=false
        for arena in avoid:
            if Vector2(w).distance_to(arena)<BOSS_AVOID:near_boss=true
        if near_boss:continue
        var d: float=Vector2(w).distance_to(p)
        # Keep heading for the current target while it is still unexplored (no dithering between two).
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
        if _boss_margin(g,a.quantity("potion"))<_boss_need(g):result.append(a.spot(g,2))
    return result

func _watch_stuck() -> void:
    var p: Vector2=a.pos()
    if hold or goal==Vector2.INF or last_pos==Vector2.INF or now<sidestep_until:
        last_pos=p;stuck_time=0.0;return
    if p.distance_to(last_pos)<a.move_speed()*DECISION*.25:stuck_time+=DECISION
    else:stuck_time=0.0
    last_pos=p
    if stuck_time>=2.0:
        stuck_time=0.0
        var forward: Vector2=(goal-p).normalized()
        var side:=Vector2(-forward.y,forward.x)
        if int(now)%2==0:side=-side
        sidestep_dir=(side+forward*.2).normalized();sidestep_until=now+1.5
        if mode=="explore":
            skipped[explore_target]=int(skipped.get(explore_target,0))+1
            a.note("stuck",{"mode":mode,"x":snappedf(p.x,1),"y":snappedf(p.y,1),"skipped_waypoint":true})
        else:a.note("stuck",{"mode":mode,"x":snappedf(p.x,1),"y":snappedf(p.y,1)})
