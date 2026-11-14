extends "res://tests/playtest/policies/active_policy.gd"
## Player-profile playtesting (Phase 2): the shared policy family for session players (Casual, Idle).
## It reuses the Active policy's movement, combat, boss-attempt commitment, exploration and estimates
## unchanged (active_policy.gd is frozen as `active-1`), and replaces only the layers where a less
## attentive player differs. Everything is a parameter in `P`, set by the subclass, so profiles can be
## varied without rewriting decision code:
##
##   version             policy version string
##   manage_every        active seconds between management passes. A pass reviews gear (merge, evolve,
##                       wear the best pair), claims missions, spends, sets up automation and picks a farm.
##                       The Active policy does all of this every 0.5 s.
##   loot_every          seconds between taps on visible loot (Active: every decision)
##   cast_every          seconds between manual casts of ready skills; -1 = only during a boss attempt
##   use_coin_boost      drinks a Coin Tonic it owns while farming
##   rest_below / rest_until    walks to a camp below this HP and rests to that HP; rest_below 0 = never
##   rest_check          "always" (notices low HP at once, between fights, like Active) or "glance" (only
##                       notices it at a management pass, and then leaves even in the middle of a fight)
##   boss_rest_until     HP it rests to before a boss attempt
##   potion_boss_below / potion_farm_below   drinks a Health Potion below these HP fractions
##   boss_extra_margin   added to the Active margin (1.25, +0.15 per loss, +0.25 vs a boss with skills)
##   boss_attempts_per_session, boss_retry_same_session   how often it tries a boss
##   explore_burst / explore_every   exploration bursts (Active: 90 s every 180 s)
##   follow_missions     farms the target of an open daily "defeat" mission when it can
##   prestige_at         "session_start": only reads the Prestige panel in the first pass of a session
##   prestige_gap_h      calendar hours between two Prestiges
##   cards               card effect preference
##   spend_save          stops at the first unaffordable wish of a currency (a savings goal) instead of
##                       buying whatever cheaper item comes later in the list
##   max_buys            purchases per currency per pass
##   gem_wishes() / coin_wishes()   ordered wish lists [{id, group, to, save}] (subclass); "save": false marks a
##                       surplus entry bought only when affordable, never saved for
##   death_avoid         after this many deaths while farming one type within 15 active minutes, the player
##                       stops choosing that type until it has gained 3 levels (it noticed; 0 = never learns)
## Session hooks (driver): session_start() claims offline earnings and opens a management pass;
## session_end() runs a final pass when `manage_on_leave` is set.
## Every outcome still comes from the real simulation; the lists only decide what to try.

var P: Dictionary={}
var next_manage:=0.0
var next_loot:=0.0
var next_cast:=0.0
var next_farm_pick:=0.0
var prestige_window:=true
var session_n:=0
var attempts_this_session:=0
var lost_this_session:=false
var last_prestige_c:=-1e12
var prestige_noted:=-1
var deaths_seen:=0
var farm_deaths: Dictionary={}   # group -> [active times of deaths while farming it]
var avoid: Dictionary={}         # group -> level the player waits for before farming it again
var _passes:=0
var glance:=false

func policy_version() -> String:return str(P.version)

func trace_sample() -> Dictionary:
    var sample: Dictionary=super.trace_sample()
    sample["session"]=session_n
    return sample

# ------------------------------------------------------------------ sessions
func session_start() -> void:
    session_n+=1
    attempts_this_session=0;lost_this_session=false
    prestige_window=true
    # The offline receipt is the first thing on screen after a return.
    if not a.offline_pending().is_empty():a.claim_offline()
    next_manage=now;next_loot=now;next_farm_pick=now
    last_pos=Vector2.INF;stuck_time=0.0

func session_end() -> void:
    if bool(P.get("manage_on_leave",false)) and a.alive() and not a.prestige_batch_open():_manage()

# ------------------------------------------------------------------ decisions
func decide() -> void:
    now+=DECISION
    if a.prestige_batch_open():
        _finish_prestige();return
    if a.deaths.size()>deaths_seen:
        deaths_seen=a.deaths.size()
        _remember_death()
    if not a.alive():
        if boss>=0:_end_boss("death")
        hold=true;mode="dead";reason="waiting to respawn";last_pos=Vector2.INF
        return
    if now>=next_loot:
        next_loot=now+float(P.loot_every)
        _loot()
    var managed:=false
    if now>=next_manage:
        next_manage=now+float(P.manage_every)
        _manage();managed=true
    glance=managed
    _supplies_and_skills()
    # The Prestige panel is read in the first quiet moment of a session ("session_start") or at every pass.
    if (prestige_window or (managed and str(P.prestige_at)!="session_start")) and _prestige():return
    _choose()
    _watch_stuck()
    if mode!=last_mode_note:
        last_mode_note=mode
        a.note("mode",{"mode":mode,"why":reason,"level":a.level(),"hp":snappedf(a.hp_frac(),.01)})

## One management pass: what a player does when they open the inventory, the shop and the missions.
func _manage() -> void:
    _passes+=1
    _claims()
    _gear()
    if a.upgrade("merge_all").level>0 and _mergeable():a.merge_all()
    _spend()
    _configure_automation()
    if a.in_combat()==false:_respawn_choice()

func _mergeable() -> bool:
    for item in a.items():
        if bool(item.can_merge):return true
    return false

# ------------------------------------------------------------------ spending
func gem_wishes() -> Array:return []
func coin_wishes() -> Array:return []

func _spend() -> void:
    if need_gear_slot and a.upgrade("gear_slots").block=="":a.buy_upgrade("gear_slots")
    if (need_supply_slot or want_potion_slot) and a.upgrade("supply_slots").block=="":a.buy_upgrade("supply_slots")
    var reserve:=_boss_reserve()
    var guard:=0
    while boss_potions>0 and a.quantity("potion")<boss_potions and not a.in_combat() and guard<10:
        guard+=1
        if a.coins()<float(a.supply_price("potion")) or not (a.quantity("potion")>0 or a.supply_free()>0):break
        if not a.buy_supply("potion").ok:break
    _buy_list(gem_wishes(),"gems",0.0)
    _buy_list(coin_wishes(),"coins",reserve)

## Works down an ordered wish list. Entries already at their level, or blocked for a reason other than
## money, are passed over. With spend_save the first unaffordable wish becomes a savings goal and stops
## the list for this currency; without it the player simply buys what it can afford further down.
func _buy_list(wishes: Array,currency: String,reserve: float) -> void:
    var bought:=0
    for w in wishes:
        if bought>=int(P.max_buys):return
        var id:=str(w.id)
        if id=="camp":
            var camp: Dictionary=w.camp
            var price:=float(camp.price)
            if a.coins()-price>=reserve:
                if a.buy_camp(int(camp.index)).ok:bought+=1
            continue
        var g:=int(w.get("group",-1))
        var u: Dictionary=a.upgrade(id,g)
        if str(u.currency)!=currency or int(u.level)>=int(w.to):continue
        var key:="%s:%d:%d" % [id,g,int(u.level)+1]
        var block:=str(u.block)
        var short: bool=block in ["NOT_ENOUGH_COINS","NOT_ENOUGH_GEMS"] or (block=="" and currency=="coins" and a.coins()-float(u.cost)<reserve)
        if block=="" and not short:
            if a.buy_upgrade(id,g).ok:
                a.want_close(key);bought+=1
            continue
        if short and bool(P.spend_save) and bool(w.get("save",true)):
            a.want_open(key);return

## Automation the player owns is switched on as a player would after buying it.
func _configure_automation() -> void:
    if a.upgrade("mission_claim").level>0 and not a.mission_auto():a.set_mission_auto(true)
    if a.auto_use_levels()>0:
        var slot: int=a.supply_slot_of("potion")
        if slot>=0 and not a.auto_slots().has(slot) and a.auto_slots().size()<a.auto_use_levels():a.bind_auto(slot)
    if a.auto_buy_capacity()>0 and not a.auto_buy_selection().has("potion"):
        var free: int=a.auto_buy_selection().find("")
        if free>=0 and free<a.auto_buy_capacity():a.set_auto_buy(free,"potion")
    var capacity: int=a.automatic_skill_capacity()
    if capacity>0:
        var wanted: Array=[]
        var equipped: Array=a.skills()
        for i in range(a.skill_slots()):
            if str(equipped[i])!="" and wanted.size()<capacity:wanted.append(i)
        if not wanted.is_empty() and wanted!=a.automatic_skill_slots():a.assign_automatic_skills(wanted)

# ------------------------------------------------------------------ supplies and skills
func _supplies_and_skills() -> void:
    var drink_below: float=float(P.potion_boss_below) if mode=="boss" else (0.0 if boss_potions>0 else float(P.potion_farm_below))
    if a.in_combat() and a.hp_frac()<drink_below and a.quantity("potion")>0 and a.supply_block("potion")=="":a.use_supply("potion")
    if bool(P.use_coin_boost) and mode=="farm" and a.quantity("coin_boost")>0 and not a.coin_boost_running() and a.supply_block("coin_boost")=="" and a.in_combat():a.use_supply("coin_boost")
    var manual:=mode=="boss" or (float(P.cast_every)>=0.0 and now>=next_cast)
    if not manual:return
    if mode!="boss":next_cast=now+float(P.cast_every)
    var automatic: Array=a.automatic_skill_slots()
    var equipped: Array=a.skills()
    for i in range(a.skill_slots()):
        if str(equipped[i])!="" and not automatic.has(i) and a.cast_block(i)=="":a.cast(i)

# ------------------------------------------------------------------ bosses
func _boss_need(g: int) -> float:
    return super._boss_need(g)+float(P.boss_extra_margin)

func _end_boss(outcome: String) -> void:
    if outcome!="win":lost_this_session=true
    super._end_boss(outcome)

# ------------------------------------------------------------------ Prestige
func _prestige() -> bool:
    if str(P.prestige_at)=="session_start" and not prestige_window:return false
    var why:=""
    if boss>=0:why="boss attempt in progress"
    elif a.in_combat():why="in combat"
    elif a.prestige_block()!="":why=a.prestige_block()
    elif a.prestiges()>0 and a.calendar_now()-last_prestige_c<float(P.prestige_gap_h)*3600.0:why="calendar gap"
    # A fight in progress postpones the look at the Prestige panel; anything else closes this session's window.
    if why not in ["in combat","boss attempt in progress"]:prestige_window=false
    if why!="":
        # Evidence for "Prestige ready but not taken": once per session, only when something is ready.
        if prestige_noted!=session_n and why!="NO_READY_PRESTIGE":
            prestige_noted=session_n
            a.note("prestige_skipped",{"reason":why,"session":session_n,"ready":a.opportunities().values().count(true)})
        return false
    a.note("prestige_decision",{"awardable":a.awardable(),"level":a.level(),"prestiges":a.prestiges(),"session":session_n})
    if not a.begin_prestige().ok:return false
    _finish_prestige()
    return true

func _finish_prestige() -> void:
    var guard:=0
    var preference: Array=P.cards
    while a.prestige_batch_open() and guard<60:
        guard+=1
        var offered: Array=a.offered_cards()
        if offered.is_empty():break
        var pick: String=str(offered[0].id)
        var rank:=preference.size()
        for card in offered:
            var at:=preference.find(str(card.effect))
            if at>=0 and at<rank:rank=at;pick=str(card.id)
        if not a.choose_card(pick).ok:break
    if not a.prestige_batch_open():
        last_prestige=now;last_prestige_c=a.calendar_now()
        mode="idle";goal=Vector2.INF;hold=false;farm_group=-1;boss=-1;waypoint_stage=-1;last_pos=Vector2.INF
        next_explore=now;next_farm_pick=now

# ------------------------------------------------------------------ where to be
func _choose() -> void:
    if boss>=0:
        _boss_step();return
    if a.boss_aggro():
        _rest("leaving a boss it did not choose to fight");return
    if mode=="rest":
        if a.hp_frac()<float(P.rest_until):
            _rest("recovering");return
    elif float(P.rest_below)>0.0 and a.hp_frac()<float(P.rest_below) and (glance if str(P.get("rest_check","always"))=="glance" else a.aggro_count()==0):
        _rest("HP below %d%%" % int(float(P.rest_below)*100));return
    if a.unlocked_stage()>a.stage() and not a.in_combat():
        var next_stage: int=a.stage()+1
        var weakest: int=int(a.stage_groups(next_stage)[0])
        if _farm_margin(weakest,2,3)>=FARM_MARGIN and a.travel_block(next_stage,0)=="":
            if a.travel(next_stage,0).ok:
                farm_group=-1;waypoint_stage=-1;mode="idle";goal=Vector2.INF;hold=false;next_explore=now;last_pos=Vector2.INF;next_farm_pick=now
                return
    var gate:=_gate_boss()
    var may_try:=attempts_this_session<int(P.boss_attempts_per_session) and (bool(P.boss_retry_same_session) or not lost_this_session)
    if gate>=0 and may_try and a.group_discovered(gate):
        var stock: int=a.quantity("potion")
        if _boss_margin(gate,stock)>=_boss_need(gate) and (boss_potions==0 or stock>=boss_potions):
            if a.hp_frac()<float(P.boss_rest_until):
                _rest("resting before the boss");return
            if a.aggro_count()==0:
                boss=gate;boss_started=now;attempts_this_session+=1
                a.note("boss_attempt_started",{"boss":_name(gate),"level":a.level(),"margin":snappedf(_boss_margin(gate,stock),.01),"needed":snappedf(_boss_need(gate),.01),"potions":stock,
                    "damage":snappedf(float(a.stats().damage),.01),"max_hp":snappedf(a.max_hp(),.1),"session":session_n})
                _boss_step();return
    if farm_group<0 or now>=next_farm_pick:
        next_farm_pick=now+float(P.manage_every)
        _pick_farm()
    _plan_waypoints()
    var unexplored:=_next_waypoint()
    if unexplored!=Vector2.INF and a.aggro_count()==0:
        if farm_group<0:
            _explore(unexplored,"nothing farmable known");return
        if mode=="explore" and now<explore_until:
            _explore(unexplored,"exploration burst");return
        if mode!="explore" and now>=next_explore and a.hp_frac()>=.7:
            explore_until=now+float(P.explore_burst);next_explore=now+float(P.explore_burst)+float(P.explore_every)
            _explore(unexplored,"exploration burst");return
    if farm_group<0:
        mode="idle";reason="nothing to do";goal=Vector2.INF;hold=true;return
    _farm()

## A death while farming (not in a boss attempt). Repeated deaths on one type make the player avoid it.
func _remember_death() -> void:
    if int(P.get("death_avoid",0))<=0 or boss>=0 or farm_group<0 or mode=="boss":return
    var list: Array=farm_deaths.get(farm_group,[])
    list=list.filter(func(t):return now-float(t)<=900.0)
    list.append(now)
    farm_deaths[farm_group]=list
    if list.size()>=int(P.death_avoid):
        avoid[farm_group]=a.level()+3
        a.note("farm_avoided",{"enemy":_name(farm_group),"deaths":list.size(),"until_level":a.level()+3})
        farm_deaths.erase(farm_group)
        _stop_focus()
        farm_group=-1;next_farm_pick=now

func _avoided(g: int) -> bool:
    return avoid.has(g) and a.level()<int(avoid[g])

## Farms an open daily "defeat" mission's type when it can (follow_missions), else the Active choice
## (best sustainable experience per second on the two-piece loadout), skipping types it learned to avoid.
func _pick_farm() -> void:
    if bool(P.follow_missions):
        var choice:=_mission_farm()
        if not choice.is_empty():
            var g:=int(choice[0]);var v:=int(choice[1])
            if g!=farm_group or v!=farm_variant:
                if g!=farm_group:farm_since=now
                farm_group=g;farm_variant=v
                a.note("farm_target",{"enemy":_name(g),"variant":v,"xp_rate":snappedf(_xp_rate(g,v),.01),"level":a.level(),"why":"daily mission"})
            return
    var best:=-1
    var best_v:=2
    var rate:=-1.0
    for g in a.stage_groups():
        var d: Dictionary=a.group(g)
        if bool(d.boss) or _avoided(g):continue
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

func _mission_farm() -> Array:
    for m in a.missions():
        if str(m.kind)!="kill" or bool(m.claimed) or float(m.progress)>=float(m.goal):continue
        var g: int=a.group_index(str(m.target))
        if g<0 or not a.stage_groups().has(g) or bool(a.group(g).boss) or not a.group_discovered(g) or _avoided(g):continue
        for v in [2,1,0]:
            if a.variants(g).has(v) and a.spot_discovered(g,v) and _farm_margin(g,v,4)>=FARM_MARGIN:return [g,v]
    return []

## Camps the Active rule would buy (closer to where this player works), as wish entries.
func _camp_wishes() -> Array:
    var out: Array=[]
    for camp in a.camps():
        if bool(camp.owned) or not bool(camp.known) or not _camp_useful(camp):continue
        out.append({"id":"camp","camp":camp})
    return out
