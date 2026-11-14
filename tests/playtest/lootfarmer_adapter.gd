extends RefCounted
## Player-profile playtesting, LootFarmer-specific part: the game adapter.
## It owns one real LootSimulation and gives a policy
##   - read-only observations (plain values and copies), and
##   - named player actions, each delegating to one public game function a player's tap reaches.
## No action writes a state dictionary to grant an outcome. The only fields written here are the ones the
## game's own input layer writes: sim.movement (the joystick) and sim.clock_override (the test clock seam).
## Every action returns {"ok": bool, "reason": String}; rejections carry the game's own refusal key.
## Policy logic never lives here.
##
## Phase 2 (sessions): leaving the game is the game's own background notice (offline snapshot + durable
## save); returning is, by default, a cold start: a fresh profile object loads the isolated save file through
## SaveService.load_and_apply(), whose restore() settles offline time and boss respawns at the virtual now.
## The adapter checks that the reloaded progression equals what was left, and measures what the game's
## settlement recorded (earned) separately from what the player's Claim paid (claimed). It never computes
## an offline reward itself. The one UI-only toggle it presses (mission auto-claim) writes exactly what the
## Missions panel's toggle writes.

const TAP_REACH:=320.0     # a pickup can be tapped when it is in sight and about on screen
var sim
var rec
var _fail_key:=""
var _error:=""
var _recent_aggro: Array=[]
var _tick:=0
# measured counters (never derived from formulas)
var deaths: Array=[]
var spent:={"coins":{},"gems":{}}
var gained:={"coins":{},"gems":{}}
var start_coins:=0.0
var start_gems:=0.0
var purchases:={}
var counts:={"pickups":0,"merges":0,"evolutions":0,"equips":0,"mission_claims":0,"main_claims":0,"travels":0,"supplies_used":0,"skill_casts":0,"camps_bought":0}
var level_times: Dictionary={}
var stage_unlock_times: Dictionary={}
var stage_enter_times: Dictionary={}
var boss_first_kill_times: Dictionary={}
var boss_found_times: Dictionary={}
var boss_attempts: Array=[]
var prestige_ready_time:=-1.0
var prestige_times: Array=[]
var prestige_diffs: Array=[]
var first_times: Dictionary={}
var fresh_reference: Dictionary={}
var _before_prestige: Dictionary={}
# Phase 2: calendar time, sessions and offline accounting (measured from the game's own records)
const AUTOMATION:=["focus","collect","collect_range","collect_batch","collect_speed","merge_gear","gear_merge_speed","auto_use","use_speed",
    "auto_evolve","auto_buy_slots","skill_auto_slots","mission_claim","merge_all","offline_cap","offline_coins","offline_gems","offline_weapon",
    "offline_outfit","offline_consumable","offline_skill","offline_weapon_rate","offline_outfit_rate","offline_consumable_rate","offline_skill_rate"]
var start_unix:=0.0
var milestones: Dictionary={}          # key -> {"t": active s, "c": calendar s}, first time only
var automation_first: Dictionary={}    # upgrade id -> {"t","c","level"} of its first purchase
var offline:={"settlements":0,"away_seconds":0.0,"rewarded_seconds":0.0,"capped_seconds":0.0,"ineligible_seconds":0.0,
    "earned":{"coins":0.0,"gems":0.0,"items":0},"earned_items":{},
    "claims":0,"claimed":{"coins":0.0,"gems":0.0,"items":0},"claimed_items":{},"items_refused":0,
    "paid_at_prestige":{"coins":0.0,"gems":0.0,"items_dropped":0},"rates_at_leave":[]}
var mission_days: Array=[]             # [{"day","t","c"}] each daily mission refresh observed
var wants: Dictionary={}               # policy saving goals: key -> {"since_t","since_c"}
var waits: Array=[]                    # closed saving goals that lasted long
var _mission_day:=""
var _persist_before:=""

func setup(simulation,recorder,seed_value: int,start: float) -> void:
    sim=simulation;rec=recorder
    sim.clock_override=start
    start_unix=start
    sim.rng.seed=seed_value
    sim.new_profile()
    sim.rng.seed=seed_value
    # The player's real first choice: onboarding mode None (every menu open, no lessons; the early
    # equipment guarantee stays active as for any player). Guided cannot be driven without the UI.
    sim.campaign.onboarding.choose_mode("none")
    fresh_reference=sim.state.duplicate(true)
    start_coins=float(sim.state.coins);start_gems=float(sim.state.gems)
    sim.event.connect(_on_event)
    sim.milestone.connect(_on_milestone)
    sim.boss_defeated.connect(_on_boss_defeated)
    sim.merged.connect(func(_id,_b,_a):counts.merges+=1)
    sim.evolved.connect(_on_evolved)
    sim.supply_used.connect(func(_id):counts.supplies_used+=1)
    stage_enter_times["1"]=0.0
    _mission_day=str(sim.state.mission_day)

func teardown() -> void:
    sim.clock_override=-1.0

# ------------------------------------------------------------------ driver contract
func set_clock(unix: float) -> void:sim.clock_override=unix
func failed() -> String:return _error
func blocked_reason() -> String:return sim.action_lock_reason()

func step(dt: float) -> bool:
    var before: float=float(sim.state.get("playtime_total",0.0))
    sim.step(dt)
    _tick+=1
    if _tick%5==0 and float(sim.state.player.hp)>0:
        var groups: Array=[]
        for e in sim.state.enemies:
            if float(e.hp)>0 and bool(e.aggro) and not groups.has(str(sim.catalog.groups[int(e.group)].id)):groups.append(str(sim.catalog.groups[int(e.group)].id))
        if not groups.is_empty():_recent_aggro=groups
    if _tick%50==0 and str(sim.state.mission_day)!=_mission_day:
        _mission_day=str(sim.state.mission_day)
        mission_days.append({"day":_mission_day,"t":snappedf(rec.active,.1),"c":snappedf(calendar_now(),.1)})
        rec.event("missions_refreshed",{"day":_mission_day})
    return float(sim.state.get("playtime_total",0.0))>before

func goal_reached(goal: String) -> bool:
    return goal=="first-prestige" and int(sim.state.prestiges)>=1 and sim.state.prestige_batch.is_empty()

## Meaningful progression: level, map access, gear growth, purchases, bosses, Prestige and its opportunities.
func progress_signature() -> String:
    var merges:=0
    for id in sim.state.items:merges+=int(sim.state.items[id].merge)+(1 if int(sim.state.items[id].qty)>0 else 0)
    var bosses:=0
    for g in range(sim.catalog.groups.size()):
        if sim.catalog.groups[g].boss:bosses+=int(sim.state.group_kills[g])
    var ready:=0
    for id in sim.state.opportunities:
        if bool(sim.state.opportunities[id].ready):ready+=1
    var levels:=0
    for key in sim.state.upgrades:levels+=int(sim.state.upgrades[key])
    return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%s|%s" % [int(sim.state.player_level),int(sim.state.stage),int(sim.state.unlocked_stage),merges,levels,bosses,
        int(sim.state.prestiges),sim.state.owned_cards.size(),sim.state.opportunities.size(),ready,str(sim.state.weapon),str(sim.state.outfit)]

func trace_sample() -> Dictionary:
    var p: Vector2=pos()
    var aggro:=0
    var nearest:=INF
    for e in sim.state.enemies:
        if float(e.hp)<=0:continue
        if bool(e.aggro):aggro+=1
        nearest=minf(nearest,sim.position_of(e).distance_to(p))
    return {"stage":stage(),"level":level(),"hp":snappedf(hp(),.1),"max_hp":snappedf(max_hp(),.1),"damage":snappedf(float(sim.stats().damage),.01),
        "x":snappedf(p.x,1),"y":snappedf(p.y,1),"target":str(sim.locked_target),"aggro":aggro,"nearest":-1.0 if nearest==INF else snappedf(nearest,1),
        "focus":int(sim.state.focus),"coins":floorf(coins()),"gems":floorf(gems()),"in_combat":in_combat(),"moving":sim.movement!=Vector2.ZERO}

## SHA-256 of the whole save snapshot with sorted keys: the final game-state digest.
func state_digest() -> String:
    var text:=JSON.stringify(sim.save_snapshot(),"",true)
    return text.sha256_text()

# ------------------------------------------------------------------ signals -> evidence
func _on_event(key: String) -> void:
    _fail_key=key
    match key:
        "PLAYER_DIED":
            var p: Vector2=pos()
            var row: Dictionary={"t":snappedf(rec.active,.1),"stage":stage(),"level":level(),"x":snappedf(p.x,1),"y":snappedf(p.y,1),"attackers":_recent_aggro.duplicate()}
            row["c"]=snappedf(calendar_now(),.1)
            deaths.append(row);rec.event("death",row);_recent_aggro=[]
        "PLAYER_LEVEL_UP":
            level_times[str(level())]=snappedf(rec.active,.1)
            mark("level:%d" % level())
            rec.event("level_up",{"level":level()})
        "STAGE_UNLOCKED":
            var key2:=str(int(sim.state.unlocked_stage))
            if not stage_unlock_times.has(key2):stage_unlock_times[key2]=snappedf(rec.active,.1)
            mark("stage_unlocked:"+key2)
            rec.event("stage_unlocked",{"stage":int(sim.state.unlocked_stage),"prestiges":int(sim.state.prestiges)})
        "WORLD_COMPLETE":rec.event("world_complete",{})

func _on_milestone(kind: String,id: String) -> void:
    match kind:
        "discovered":rec.event("opportunity_discovered",{"id":id})
        "ready":
            if prestige_ready_time<0:prestige_ready_time=snappedf(rec.active,.1)
            mark("prestige_ready")
            rec.event("opportunity_ready",{"id":id})
        "boss_found":
            if not boss_found_times.has(id):boss_found_times[id]=snappedf(rec.active,.1)
            mark("boss_found:"+id)
            rec.event("boss_found",{"id":id})
        "card":rec.event("card_awarded",{"id":id})
        "prestiged":rec.event("prestige_completed",{"cards":id,"prestiges":int(sim.state.prestiges)})

func _on_boss_defeated(_actor: String,group: int,_at: Vector2) -> void:
    var id:=str(sim.catalog.groups[group].id)
    if not boss_first_kill_times.has(id):boss_first_kill_times[id]=snappedf(rec.active,.1)
    mark("boss_defeated:"+id)
    rec.event("boss_defeated",{"id":id,"level":level(),"hp_left":snappedf(hp_frac(),.01),"lifetime_defeats_before":int(sim.state.group_kills[group])})

func _on_evolved(source: String,target: String) -> void:
    counts.evolutions+=1
    rec.event("evolved",{"from":source,"to":target})

func first(key: String) -> void:
    if not first_times.has(key):
        first_times[key]=snappedf(rec.active,.1)
        mark("first:"+key)
        rec.event("first",{"what":key})

# ------------------------------------------------------------------ action plumbing
## Runs one game call, measures the currency it moved and reports the game's refusal key.
func _act(action: String,subject: String,category: String,call: Callable,log_success: bool=true,data: Dictionary={}) -> Dictionary:
    _fail_key=""
    var c0: float=float(sim.state.coins)
    var g0: float=float(sim.state.gems)
    var ok: bool=bool(call.call())
    var c1: float=float(sim.state.coins)
    var g1: float=float(sim.state.gems)
    _account("coins",category,c1-c0);_account("gems",category,g1-g0)
    if ok:
        if log_success:
            var row: Dictionary={"action":action,"subject":subject}
            if c1!=c0:row["coins"]=snappedf(c1-c0,.01)
            if g1!=g0:row["gems"]=snappedf(g1-g0,.01)
            for k in data:row[k]=data[k]
            rec.event("action",row)
        return {"ok":true,"reason":""}
    var reason:=_fail_key if _fail_key!="" else "refused"
    rec.failure(action,reason,subject,data)
    return {"ok":false,"reason":reason}

func _account(currency: String,category: String,delta: float) -> void:
    if delta<0:spent[currency][category]=float(spent[currency].get(category,0.0))-delta
    elif delta>0:gained[currency][category]=float(gained[currency].get(category,0.0))+delta

# ------------------------------------------------------------------ named player actions
## The joystick. Zero releases it.
func move(direction: Vector2) -> void:
    sim.movement=direction.normalized() if direction.length()>0.001 else Vector2.ZERO
func stop() -> void:sim.movement=Vector2.ZERO

## The drag-to-target gesture on a visible enemy.
func select_target(actor_id: String) -> Dictionary:
    return _act("select_target",actor_id,"none",func():return sim.select_target(actor_id),false)

## A tap on a visible ground pickup.
func collect(uid: int) -> Dictionary:
    var item:=""
    for drop in sim.state.pickups:
        if int(drop.uid)==uid:
            item=str(drop.item)
            var at:=Vector2(drop.x,drop.y)
            if not sim.campaign.can_see(at) or at.distance_to(pos())>TAP_REACH:
                rec.failure("collect","OUT_OF_SIGHT",item);return {"ok":false,"reason":"OUT_OF_SIGHT"}
    if item=="":return {"ok":false,"reason":"GONE"}
    var result:=_act("collect",item,"none",func():return sim.collect(uid),true)
    if result.ok:
        counts.pickups+=1
        if str(sim.catalog.items[item].kind) in ["weapon","outfit"]:first("gear_pickup")
    return result

func equip(id: String) -> Dictionary:
    var result:=_act("equip",id,"none",func():return sim.equip(id) and (str(sim.state.weapon)==id or str(sim.state.outfit)==id),true,{"merge":merge_of(id)})
    if result.ok:counts.equips+=1;first("equip")
    return result

func equip_skill(id: String,slot: int=-1) -> Dictionary:
    return _act("equip_skill",id,"none",func():return sim.campaign.equip_skill(id,slot))

func merge_copies(id: String) -> Dictionary:
    var before:=merge_of(id)
    var result:=_act("merge",id,"none",func():return sim.merge(id,true),false)
    if result.ok:
        rec.event("action",{"action":"merge","subject":id,"from":before,"to":merge_of(id)});first("merge")
    return result

func evolve(id: String) -> Dictionary:
    return _act("evolve",id,"none",func():return sim.evolve(id),false)

func buy_upgrade(id: String,group: int=-1) -> Dictionary:
    var cost: int=int(sim.upgrade_cost(id,group))
    var currency:=str(sim.catalog.upgrades[id].currency)
    var subject:=id if group<0 else "%s:%s" % [id,_scope_name(id,group)]
    var result:=_act("buy_upgrade",subject,"upgrade:"+id,func():return sim.buy_upgrade(id,group),true,{"level":int(sim.level(id,group))+1,"price":cost,"currency":currency})
    if result.ok:
        purchases[subject]=int(purchases.get(subject,0))+1
        first("upgrade")
        if AUTOMATION.has(id) and not automation_first.has(id):
            automation_first[id]={"t":snappedf(rec.active,.1),"c":snappedf(calendar_now(),.1),"level":int(sim.level(id,group))}
    return result

func _scope_name(id: String,group: int) -> String:
    var scope:=str(sim.catalog.upgrades[id].get("scope","global"))
    if scope in ["type","normal_type"] and group>=0 and group<sim.catalog.groups.size():return str(sim.catalog.groups[group].id)
    return str(group)

func buy_camp(index: int) -> Dictionary:
    if sim.state.spawns.has(index):return {"ok":false,"reason":"OWNED"}
    var result:=_act("buy_camp","%d:%d" % [stage(),index],"camp",func():return sim.select_spawn(index) and sim.state.spawns.has(index))
    if result.ok:counts.camps_bought+=1;first("camp")
    return result

func select_respawn(index: int) -> Dictionary:
    if not sim.state.spawns.has(index):return {"ok":false,"reason":"CAMP_LOCKED"}
    return _act("select_respawn","%d:%d" % [stage(),index],"none",func():return sim.select_spawn(index))

## World -> Travel / Teleport to an owned camp of an unlocked map.
func travel(to_stage: int,camp: int) -> Dictionary:
    var from:=stage()
    var result:=_act("travel","%d:%d" % [to_stage,camp],"none",func():return sim.campaign.camp_action(to_stage,camp,true),true,{"from_stage":from})
    if result.ok:
        counts.travels+=1
        if not stage_enter_times.has(str(to_stage)):stage_enter_times[str(to_stage)]=snappedf(rec.active,.1)
    return result

func buy_supply(id: String) -> Dictionary:
    return _act("buy_supply",id,"supply:"+id,func():return sim.purchase_consumable(id))

func use_supply(id: String) -> Dictionary:
    return _act("use_supply",id,"none",func():return sim.use_item(id),true,{"hp":snappedf(hp_frac(),.01)})

func cast(slot: int) -> Dictionary:
    var result:=_act("cast",str(slot),"none",func():return sim.campaign.cast(slot),false)
    if result.ok:counts.skill_casts+=1
    return result

## Farm / Stop on an enemy panel (or the quick Auto Farm button): the game's one toggle.
func focus(group: int,variant: int) -> Dictionary:
    return _act("focus","%s:%d" % [str(sim.catalog.groups[group].id),variant],"none",func():return sim.focus(group,variant),true,{"on":not sim.focus_active(group,variant)})

func claim_mission(i: int) -> Dictionary:
    var kind:=str(sim.state.missions[i].kind) if i<sim.state.missions.size() else ""
    var result:=_act("claim_mission",kind,"mission",func():return sim.campaign.claim_mission(i))
    if result.ok:counts.mission_claims+=1
    return result

func claim_main(i: int) -> Dictionary:
    var result:=_act("claim_main",str(i),"main_objective",func():return sim.campaign.claim_main(i))
    if result.ok:counts.main_claims+=1
    return result

func claim_hunt() -> Dictionary:
    return _act("claim_hunt","hunt","mission",func():return sim.campaign.claim_hunt())

## The Claim button of the offline receipt. Measures what the claim paid and which item copies the game
## granted (campaign.offline_receipt); copies the inventory could not take are counted as refused.
func claim_offline() -> Dictionary:
    var pending: Dictionary=offline_pending()
    if pending.is_empty():return {"ok":false,"reason":"NOTHING_PENDING"}
    var result:=_act("claim_offline","offline","offline",func():return sim.campaign.claim_offline(),true,
        {"away_s":snappedf(float(pending.seconds),.1),"rewarded_h":snappedf(float(pending.rewarded_hours),.001),"items":_count(pending.items)})
    if result.ok:
        var receipt: Dictionary=sim.campaign.offline_receipt
        offline.claims+=1
        offline.claimed.coins+=float(pending.coins);offline.claimed.gems+=float(pending.gems)
        var granted:=0
        for id in receipt.get("items",{}):
            granted+=int(receipt.items[id]);offline.claimed_items[id]=int(offline.claimed_items.get(id,0))+int(receipt.items[id])
        offline.claimed.items+=granted
        offline.items_refused+=_count(pending.items)-granted
        if not sim.state.offline_pending.is_empty():_error="offline claim left a pending record"
        mark("first:offline_claim")
    return result

## The whole Prestige transaction is two real calls: begin_prestige, then one choose_card per opportunity.
func begin_prestige() -> Dictionary:
    _before_prestige=sim.state.duplicate(true)
    var ids: Array=sim.campaign.awardable_ids()
    var result:=_act("begin_prestige",",".join(ids),"prestige_settlement",func():return sim.campaign.begin_prestige(),true,{"level":level(),"coins":floorf(coins()),"gems":floorf(gems())})
    if not result.ok:_before_prestige={}
    return result

func choose_card(id: String) -> Dictionary:
    var pending: Dictionary=offline_pending()
    var result:=_act("choose_card",id,"prestige_settlement",func():return sim.campaign.choose_card(id))
    if result.ok and sim.state.prestige_batch.is_empty() and not pending.is_empty() and sim.state.offline_pending.is_empty():
        # The game pays unclaimed offline Coins and Gems inside the Prestige transaction; their item copies end with the run.
        offline.paid_at_prestige.coins+=float(pending.coins);offline.paid_at_prestige.gems+=float(pending.gems)
        offline.paid_at_prestige.items_dropped+=_count(pending.items)
        rec.event("offline_paid_by_prestige",{"coins":snappedf(float(pending.coins),.01),"gems":snappedf(float(pending.gems),.01),"items_dropped":_count(pending.items)})
    if result.ok and sim.state.prestige_batch.is_empty() and not _before_prestige.is_empty():
        prestige_times.append(snappedf(rec.active,.1))
        prestige_diffs.append(_field_diff(_before_prestige,sim.state))
        _before_prestige={}
        stage_enter_times["1@p%d" % int(sim.state.prestiges)]=snappedf(rec.active,.1)
        mark("prestige:%d" % int(sim.state.prestiges))
    return result

## The canonical field diff (tests/prestige_field_diff.gd): each top-level state field is KEPT (unchanged),
## RESET (equals a fresh profile) or OTHER (changed to something else), around the real transaction.
func _field_diff(before: Dictionary,after: Dictionary) -> Dictionary:
    var rows: Dictionary={}
    var keys: Array=before.keys();keys.sort()
    for k in keys:
        var b=before[k]
        var a=after.get(k,"<missing>")
        var f=fresh_reference.get(k,"<none>")
        var cls:="KEPT" if var_to_str(a)==var_to_str(b) else ("RESET" if var_to_str(a)==var_to_str(f) else "OTHER")
        rows[str(k)]=cls
    var facts: Dictionary={"level_before":int(before.player_level),"level_after":int(after.player_level),"coins_before":float(before.coins),"coins_after":float(after.coins),
        "gems_before":float(before.gems),"gems_after":float(after.gems),"prestiges_before":int(before.prestiges),"prestiges_after":int(after.prestiges),
        "cards_before":before.owned_cards.size(),"cards_after":after.owned_cards.size(),"items_after":after.items.size(),"stage_after":int(after.stage),
        "unlocked_stage_before":int(before.unlocked_stage),"unlocked_stage_after":int(after.unlocked_stage),
        "upgrades_equal":var_to_str(before.upgrades)==var_to_str(after.upgrades),"group_kills_equal":var_to_str(before.group_kills)==var_to_str(after.group_kills),
        "consumed_after":after.consumed.duplicate(),"cards_owned_after":after.owned_cards.duplicate()}
    return {"fields":rows,"facts":facts}

## Merge All (the 500-Gem unlock): one tap performing every ordinary merge.
func merge_all() -> Dictionary:
    return _act("merge_all","all","none",func():return int(sim.merge_all().items)>0)

## A supply slot's Auto Use toggle (needs Auto Use levels).
func bind_auto(slot: int) -> Dictionary:
    return _act("auto_use_toggle",str(slot),"none",func():return sim.bind_auto(slot))
func auto_slots() -> Array:return sim.state.auto_slots.duplicate()
func supply_slot_of(id: String) -> int:return sim.state.supplies.find(id)
func auto_use_levels() -> int:return int(sim.level("auto_use"))

## Auto Buy Supplies: choose the supply a slot restocks.
func set_auto_buy(slot: int,id: String) -> Dictionary:
    return _act("auto_buy_select","%d:%s" % [slot,id],"none",func():return sim.set_auto_buy(slot,id))
func auto_buy_capacity() -> int:return sim.auto_buy_capacity()
func auto_buy_selection() -> Array:return sim.auto_buy_selection()

## Automatic skill casting: which equipped skill slots cast by themselves.
func assign_automatic_skills(slots_: Array) -> Dictionary:
    return _act("auto_skills",str(slots_),"none",func():return sim.assign_automatic_skills(slots_))
func automatic_skill_capacity() -> int:return sim.automatic_skill_capacity()
func automatic_skill_slots() -> Array:return sim.automatic_skill_assignments()

## The Missions panel's "Automatic Claiming" toggle. The game has no simulation function for it: the panel
## writes the flag (and the seen-hint) itself; this does exactly the same and nothing more.
func set_mission_auto(on: bool) -> Dictionary:
    if sim.level("mission_claim")<=0:
        rec.failure("mission_auto","MISSION_AUTO_LOCKED","");return {"ok":false,"reason":"MISSION_AUTO_LOCKED"}
    if bool(sim.state.mission_auto)==on:return {"ok":true,"reason":""}
    sim.state.mission_auto=on
    if on and not sim.state.tutorial.seen.has("mission_auto_enabled"):sim.state.tutorial.seen.append("mission_auto_enabled")
    sim.touch()
    rec.event("action",{"action":"mission_auto","subject":"on" if on else "off"})
    return {"ok":true,"reason":""}
func mission_auto() -> bool:return bool(sim.state.mission_auto)

# ------------------------------------------------------------------ sessions (Phase 2)
func calendar_now() -> float:return float(rec.virtual_unix)-start_unix
func mark(key: String) -> void:
    if not milestones.has(key):milestones[key]={"t":snappedf(rec.active,.1),"c":snappedf(calendar_now(),.1)}

## A player closes the game only between fights with a boss and outside a Prestige choice.
func session_can_end() -> bool:
    return not boss_aggro() and not prestige_batch_open()

## The player leaves: release the stick and let the game background itself (its own offline snapshot and
## durable save). The progression left behind is remembered to verify the next load.
func leave_session(n: int) -> void:
    stop()
    var snap: Dictionary=sim.campaign.offline_snapshot()
    offline.rates_at_leave.append({"session":n,"cap_h":snappedf(float(snap.cap)/3600.0,.01),"coins_h":snappedf(float(snap.coins),.01),"gems_h":snappedf(float(snap.gems),.01),
        "item_rates_h":snap.rates.duplicate(),"eligible":{"weapon":snap.eligible.weapon.size(),"outfit":snap.eligible.outfit.size(),"consumable":snap.eligible.consumable.size(),"skill":snap.eligible.skill.size()}})
    sim.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
    _persist_before=_persistence_view()
    rec.event("left_game",{"session":n,"level":level(),"stage":stage(),"coins":floorf(coins()),"gems":floorf(gems()),
        "offline_cap_h":snappedf(float(snap.cap)/3600.0,.01),"offline_coins_h":snappedf(float(snap.coins),.01),"offline_gems_h":snappedf(float(snap.gems),.01)})

## The player opens the game again `away` seconds later. Cold: a new profile object loads the save file
## (restore settles offline time and boss respawns). Warm: the game's resume notice settles them. Returns ""
## or why persistence failed. The game's settlement is measured as the change of the pending record.
func return_session(n: int,away: float,mode: String) -> String:
    var pending_before: Dictionary=offline_pending()
    var snap: Dictionary=sim.state.offline_snapshot.duplicate(true)
    if mode=="cold":
        sim.new_profile()
        SaveService.load_and_apply()
        if SaveService.last_load_result!="primary":return "persistence: the save did not load (%s)" % SaveService.last_load_result
    else:
        sim.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
    if sim.suspended:return "persistence: the game is still suspended after the return"
    var after:=_persistence_view()
    if after!=_persist_before:
        var was: Dictionary=JSON.parse_string(_persist_before)
        var now_view: Dictionary=JSON.parse_string(after)
        var fields: Array=[]
        for k in was:
            if not _same(was[k],now_view.get(k)):fields.append("%s: %s -> %s" % [k,JSON.stringify(was[k]).left(160),JSON.stringify(now_view.get(k)).left(160)])
        # The view rounds numbers to 0.001 and a JSON round trip can move a value across that rounding boundary,
        # so numbers may differ by one rounding unit (0.0011); everything else must be equal.
        if not fields.is_empty():return "persistence: the reloaded progression differs from what was left (%s)" % "; ".join(fields)
    var pending: Dictionary=offline_pending()
    var seconds:=float(pending.get("seconds",0.0))-float(pending_before.get("seconds",0.0))
    var hours:=float(pending.get("rewarded_hours",0.0))-float(pending_before.get("rewarded_hours",0.0))
    var row: Dictionary={"session":n,"away_s":snappedf(away,.1),"settled_s":snappedf(seconds,.1),"rewarded_h":snappedf(hours,.001),
        "cap_h":snappedf(float(snap.get("cap",0.0))/3600.0,.01),"coins":0.0,"gems":0.0,"items":0}
    offline.away_seconds+=away
    if not bool(snap.get("eligible_time",true)):
        offline.ineligible_seconds+=away;row["ineligible"]=true
    elif seconds>0.0:
        offline.settlements+=1
        offline.rewarded_seconds+=hours*3600.0
        offline.capped_seconds+=maxf(0.0,seconds-hours*3600.0)
        var c:=float(pending.get("coins",0.0))-float(pending_before.get("coins",0.0))
        var g:=float(pending.get("gems",0.0))-float(pending_before.get("gems",0.0))
        offline.earned.coins+=c;offline.earned.gems+=g
        var items: Dictionary=pending.get("items",{})
        var before_items: Dictionary=pending_before.get("items",{})
        var n_items:=0
        for id in items:
            var d:=int(items[id])-int(before_items.get(id,0))
            if d>0:n_items+=d;offline.earned_items[id]=int(offline.earned_items.get(id,0))+d
        offline.earned.items+=n_items
        row.coins=snappedf(c,.01);row.gems=snappedf(g,.01);row.items=n_items
    rec.event("offline_settled",row)
    return ""

## What any player does on return when the profile has no own routine: tap Claim on the offline receipt.
func default_return() -> void:
    if not offline_pending().is_empty():claim_offline()

## Progression that must survive closing and reopening the game (offline settlement fields excluded).
func _persistence_view() -> String:
    var s: Dictionary=sim.state
    var items: Dictionary={}
    for id in s.items:items[id]=[int(s.items[id].qty),int(s.items[id].merge)]
    var upgrades: Dictionary={}
    for key in s.upgrades:upgrades[key]=int(s.upgrades[key])
    var mission_rows: Array=[]
    for m in s.missions:mission_rows.append([str(m.kind),str(m.target),snappedf(float(m.progress),.001),bool(m.claimed),str(m.day)])
    var view: Dictionary={"level":int(s.player_level),"xp":snappedf(float(s.xp),.001),"coins":snappedf(float(s.coins),.001),"gems":snappedf(float(s.gems),.001),
        "items":items,"upgrades":upgrades,"prestiges":int(s.prestiges),"stage":int(s.stage),"unlocked":int(s.unlocked_stage),"cards":s.owned_cards.duplicate(),
        "weapon":str(s.weapon),"outfit":str(s.outfit),"missions":mission_rows,"camps":JSON.stringify(s.camps,"",true),"kills":JSON.stringify(s.group_kills),
        "focus":[int(s.focus),int(s.focus_variant)],"skills":s.skills.duplicate(),"opportunities":_opportunity_view(s.opportunities)}
    return JSON.stringify(view,"",true)

func _same(x,y) -> bool:
    if (x is float or x is int) and (y is float or y is int):
        return absf(float(x)-float(y))<=1e-9*maxf(1.0,maxf(absf(float(x)),absf(float(y))))+.0011
    if x is Array and y is Array:
        if x.size()!=y.size():return false
        for i in range(x.size()):
            if not _same(x[i],y[i]):return false
        return true
    if x is Dictionary and y is Dictionary:
        if x.size()!=y.size():return false
        for k in x:
            if not y.has(k) or not _same(x[k],y[k]):return false
        return true
    return JSON.stringify(x)==JSON.stringify(y)

func _opportunity_view(ops: Dictionary) -> Array:
    var ids: Array=ops.keys();ids.sort()
    var out: Array=[]
    for id in ids:out.append("%s=%s" % [id,str(bool(ops[id].get("ready",false)))])
    return out

func _count(d: Dictionary) -> int:
    var n:=0
    for k in d:n+=int(d[k])
    return n

## Policy saving goals: a policy opens one when its top wish is unaffordable and closes it when bought.
## Long waits are evidence (an upgrade that stays out of reach, automation that arrives late).
## A goal the policy stops asking for (its farm changed, a cheaper list item came first) lapses after 600 active
## seconds without a renewal and is dropped without a wait record; asking again later starts a new goal.
func want_open(key: String) -> void:
    if wants.has(key) and rec.active-float(wants[key].seen_t)>600.0:wants.erase(key)
    if not wants.has(key):wants[key]={"since_t":snappedf(rec.active,.1),"since_c":snappedf(calendar_now(),.1),"seen_t":rec.active}
    wants[key].seen_t=rec.active
func want_close(key: String) -> void:
    if not wants.has(key):return
    var w: Dictionary=wants[key];wants.erase(key)
    if rec.active-float(w.seen_t)>600.0:return
    var row: Dictionary={"want":key,"waited_active_s":snappedf(rec.active-float(w.since_t),.1),"waited_calendar_s":snappedf(calendar_now()-float(w.since_c),.1)}
    if float(row.waited_active_s)>=600.0 or float(row.waited_calendar_s)>=6.0*3600.0:
        waits.append(row);rec.event("purchase_wait",row)

## Policy notes that are evidence (boss attempts, decisions with a reason).
func note(kind: String,data: Dictionary={}) -> void:rec.event(kind,data)
func boss_attempt(row: Dictionary) -> void:boss_attempts.append(row)

# ------------------------------------------------------------------ observations (read-only)
func alive() -> bool:return float(sim.state.player.hp)>0
func hp() -> float:return float(sim.state.player.hp)
func max_hp() -> float:return float(sim.stats().hp)
func hp_frac() -> float:return clampf(hp()/maxf(1.0,max_hp()),0.0,1.0)
func pos() -> Vector2:return sim.position_of(sim.state.player)
func level() -> int:return int(sim.state.player_level)
func coins() -> float:return float(sim.state.coins)
func gems() -> float:return float(sim.state.gems)
func stage() -> int:return int(sim.state.stage)
func unlocked_stage() -> int:return int(sim.state.unlocked_stage)
func prestiges() -> int:return int(sim.state.prestiges)
func in_combat() -> bool:return sim.campaign.in_combat()
func locked_target() -> String:return str(sim.locked_target)
func stats() -> Dictionary:return sim.stats().duplicate()
func move_speed() -> float:return float(sim.campaign.move_speed())
func bonus(key: String) -> float:return float(sim.campaign.bonus(key))
func action_locked() -> String:return sim.action_lock_reason()

func stage_size(st: int=-1) -> Vector2:
    var d: Dictionary=sim.catalog.stages[(stage() if st<0 else st)-1]
    return Vector2(d.size[0],d.size[1])
func stage_groups(st: int=-1) -> Array:return sim.catalog.stages[(stage() if st<0 else st)-1].groups.duplicate()
func stage_gates(st: int=-1) -> Array:return sim.catalog.stages[(stage() if st<0 else st)-1].gates.duplicate()
func group(g: int) -> Dictionary:
    var d: Dictionary=sim.catalog.groups[g]
    return {"id":str(d.id),"boss":bool(d.boss),"final":bool(d.final),"level":int(d.level),"stage":int(d.stage),"aggro_mode":str(d.aggro_mode),"skills":d.skills.size()}
func variants(g: int) -> Array:return sim.campaign.variants(g)
func spot(g: int,v: int) -> Vector2:return sim.campaign.spot(g,v)
func spot_discovered(g: int,v: int) -> bool:return sim.campaign.spot_discovered(g,v)
func group_discovered(g: int) -> bool:return sim.campaign.discovered(g)
func enemy(g: int,v: int) -> Dictionary:
    var d: Dictionary=sim.enemy_definition(g,v)
    return {"hp":float(d.hp),"damage":float(d.damage),"interval":float(d.interval),"defense":float(d.defense),"xp":float(sim.group_xp(g,v)),"coins":float(sim.coin_reward(g)),"skills":d.skills.size(),"loot":d.loot.duplicate()}
## True when this type's skill loadout carries a skill the player owns no copy of.
func missing_skill(g: int) -> bool:
    for family in sim.catalog.groups[g].skills:
        if sim.quantity("skill_"+str(family))<1:return true
    return false
func achievement_damage(g: int) -> float:return float(sim.achievement_damage(g))
func run_kills(group_id: String) -> int:return int(sim.state.run_kills.get(group_id,0))
func lifetime_kills(g: int) -> int:return int(sim.state.group_kills[g])
func boss_found(group_id: String) -> bool:return sim.campaign.boss_found(group_id)
func cell_known(at: Vector2) -> bool:return sim.campaign.cell_known(at)
func in_bounds(at: Vector2) -> bool:return sim.campaign.in_bounds(at)
func solid_at(at: Vector2) -> bool:return sim.campaign.solid_at(at)
func explored_percent() -> int:return int(sim.campaign.explored_percent(stage()))

## Living actors of one spot the player can see: [{id, hp, pos}].
func actors(g: int,v: int=-1) -> Array:
    var result: Array=[]
    for e in sim.state.enemies:
        if int(e.group)!=g or float(e.hp)<=0 or sim.is_helper(e):continue
        if v>=0 and int(e.get("variant",2))!=v:continue
        if not sim.campaign.target_allowed(e):continue
        result.append({"id":str(e.id),"hp":float(e.hp),"pos":sim.position_of(e),"aggro":bool(e.aggro)})
    return result
func aggro_count() -> int:
    var n:=0
    for e in sim.state.enemies:
        if float(e.hp)>0 and bool(e.aggro) and not bool(e.get("returning",false)):n+=1
    return n
## True while a boss is engaged with the player.
func boss_aggro() -> bool:
    for e in sim.state.enemies:
        if float(e.hp)>0 and bool(e.aggro) and not bool(e.get("returning",false)) and bool(sim.catalog.groups[int(e.group)].boss):return true
    return false
func target_group() -> int:
    for e in sim.state.enemies:
        if str(e.id)==str(sim.locked_target) and float(e.hp)>0:return int(e.group)
    return -1

func camps() -> Array:
    var result: Array=[]
    var list: Array=sim.campaign.stage().spawns
    for i in range(list.size()):
        result.append({"index":i,"pos":Vector2(list[i][0],list[i][1]),"owned":sim.state.spawns.has(i),"known":sim.campaign.camp_known(i),"price":int(sim.campaign.camp_price(i))})
    return result
func respawn_camp() -> int:return int(sim.state.spawn)
func travel_block(to_stage: int,camp: int) -> String:return sim.campaign.travel_reason(to_stage,camp)
func arrival_camp(st: int) -> Vector2:
    var a: Array=sim.catalog.stages[st-1].spawns[0]
    return Vector2(a[0],a[1])

func pickups() -> Array:
    var result: Array=[]
    var p:=pos()
    for drop in sim.state.pickups:
        var at:=Vector2(drop.x,drop.y)
        if drop.has("dropped") or at.distance_to(p)>TAP_REACH or not sim.campaign.can_see(at):continue
        result.append({"uid":int(drop.uid),"item":str(drop.item),"kind":str(sim.catalog.items[drop.item].kind),"can_add":sim.can_add(str(drop.item))})
    return result

func items() -> Array:
    var result: Array=[]
    var ids: Array=sim.state.items.keys();ids.sort()
    for id in ids:
        if sim.quantity(id)<1:continue
        var d: Dictionary=sim.catalog.items[id]
        result.append({"id":str(id),"kind":str(d.kind),"tier":int(d.get("tier",1)),"qty":sim.quantity(id),"merge":int(sim.record(id).merge),"cap":int(sim.merge_cap(id)),
            "can_merge":sim.can_merge(id),"can_evolve":str(d.kind)=="weapon" and sim.evolve_block_reason(id)=="","skill":str(d.get("skill",""))})
    return result
func quantity(id: String) -> int:return sim.quantity(id)
func merge_of(id: String) -> int:return int(sim.state.items.get(id,{}).get("merge",0))
func weapon() -> String:return str(sim.state.weapon)
func outfit() -> String:return str(sim.state.outfit)
func gear_free() -> int:return sim.state.gear.count("")
func supply_free() -> int:return sim.state.supplies.count("")
## The game's own effective stats with another weapon/outfit pair (the item panel's comparison).
func stats_with(weapon_id: String,outfit_id: String) -> Dictionary:return sim.stats_with(weapon_id,outfit_id)

func upgrade(id: String,g: int=-1) -> Dictionary:
    return {"level":int(sim.level(id,g)),"cap":int(sim.catalog.upgrades[id].cap),"cost":int(sim.upgrade_cost(id,g)),"currency":str(sim.catalog.upgrades[id].currency),"block":str(sim.upgrade_block_reason(id,g))}
func focus_owned() -> bool:return sim.focus_owned()
func focus_active(g: int,v: int) -> bool:return sim.focus_active(g,v)
func focus_group() -> int:return int(sim.state.focus)
func focus_variant() -> int:return int(sim.state.focus_variant)

func supply_price(id: String) -> int:return int(sim.supply(id).get("price",0))
func supply_block(id: String) -> String:return sim.supply_block_reason(id)
func supply_heal_fraction(id: String) -> float:return float(sim.supply_value(id))
func supply_cooldown(id: String) -> float:return float(sim.supply_cooldown(id))
func coin_boost_running() -> bool:return float(sim.state.boost_time)>0

func skills() -> Array:return sim.state.skills.duplicate()
func skill_slots() -> int:return 1+int(sim.level("skill_slots"))
func cast_block(slot: int) -> String:return sim.campaign.skill_cast_block_reason(slot)

func missions_claimable() -> Array:
    var result: Array=[]
    for i in range(sim.state.missions.size()):
        var m: Dictionary=sim.state.missions[i]
        if str(m.kind)!="waiting" and not bool(m.claimed) and float(m.progress)>=float(m.goal):result.append(i)
    return result
func main_ready() -> Array:
    var result: Array=[]
    for key in sim.state.main_ready:
        if not sim.state.main_claimed.has(int(key)):result.append(int(key))
    result.sort()
    return result
func hunt_claimable() -> bool:return sim.campaign.hunt_claimable()
## The daily missions as the Missions panel shows them.
func missions() -> Array:
    var result: Array=[]
    for m in sim.state.missions:result.append({"kind":str(m.kind),"target":str(m.target),"progress":float(m.progress),"goal":float(m.goal),"claimed":bool(m.claimed)})
    return result
func group_index(group_id: String) -> int:
    for g in range(sim.catalog.groups.size()):
        if str(sim.catalog.groups[g].id)==group_id:return g
    return -1
## The pending offline receipt (a copy), {} when there is none.
func offline_pending() -> Dictionary:return sim.state.get("offline_pending",{}).duplicate(true)
## The Offline tab's figures: hourly Coins and Gems, item rates and the cap in hours.
func offline_rates() -> Dictionary:
    var snap: Dictionary=sim.campaign.offline_snapshot()
    return {"cap_h":float(snap.cap)/3600.0,"coins_h":float(snap.coins),"gems_h":float(snap.gems),"rates":snap.rates.duplicate()}
func skills_seen() -> bool:return not sim.state.skills_seen.is_empty()

func prestige_block() -> String:return sim.campaign.prestige_block_reason()
func prestige_batch_open() -> bool:return not sim.state.prestige_batch.is_empty()
func awardable() -> Array:return sim.campaign.awardable_ids()
func offered_cards() -> Array:
    var result: Array=[]
    for id in sim.campaign.offered_cards():
        var d: Dictionary=sim.catalog.campaign.cards[id]
        result.append({"id":str(id),"effect":str(d.effect),"value":float(d.value)})
    return result
func opportunities() -> Dictionary:
    var result: Dictionary={}
    for id in sim.state.opportunities:result[str(id)]=bool(sim.state.opportunities[id].ready)
    return result

# ------------------------------------------------------------------ summary (measured values only)
func summary() -> Dictionary:
    var kills: Dictionary={}
    var total_kills:=0
    for g in range(sim.catalog.groups.size()):
        if int(sim.state.group_kills[g])>0:kills[str(sim.catalog.groups[g].id)]=int(sim.state.group_kills[g]);total_kills+=int(sim.state.group_kills[g])
    var spent_coins:=_sum(spent.coins);var spent_gems:=_sum(spent.gems)
    var earned_coins:=float(sim.state.coins)-start_coins+spent_coins
    var earned_gems:=float(sim.state.gems)-start_gems+spent_gems
    var gear: Dictionary={"weapon":_gear(str(sim.state.weapon)),"outfit":_gear(str(sim.state.outfit)),"identities_owned":0,"merge_levels_total":0}
    for id in sim.state.items:
        if sim.quantity(id)>0 and str(sim.catalog.items[id].kind)!="consumable":
            gear.identities_owned+=1;gear.merge_levels_total+=int(sim.state.items[id].merge)
    var upgrades_total:=0
    for key in purchases:upgrades_total+=int(purchases[key])
    var s: Dictionary=sim.stats()
    return {"stage":stage(),"highest_stage_unlocked":unlocked_stage(),"player_level":level(),"prestiges":prestiges(),"cards":sim.state.owned_cards.duplicate(),
        "stats":{"hp":snappedf(float(s.hp),.1),"damage":snappedf(float(s.damage),.01),"defense":snappedf(float(s.defense),.01),"crit":snappedf(float(s.crit),.001)},
        "equipment":gear,"deaths":deaths.size(),"death_log":deaths,"kills_total":total_kills,"kills_by_type_lifetime":kills,
        "boss_attempts":boss_attempts,"boss_first_kill_times_s":boss_first_kill_times,"boss_found_times_s":boss_found_times,
        "stage_unlock_times_s":stage_unlock_times,"stage_enter_times_s":stage_enter_times,"level_times_s":level_times,"first_times_s":first_times,
        "first_prestige_ready_time_s":prestige_ready_time if prestige_ready_time>=0 else null,
        "first_prestige_completed_time_s":prestige_times[0] if not prestige_times.is_empty() else null,"prestige_times_s":prestige_times,
        "upgrades_bought":upgrades_total,"purchases":purchases,"counts":counts,
        "currency":{"coins":{"earned_total":snappedf(earned_coins,.01),"spent_total":snappedf(spent_coins,.01),"spent_by_category":_rounded(spent.coins),
                "earned_by_action":_rounded(gained.coins),"earned_from_kills":snappedf(earned_coins-_sum(gained.coins),.01),"balance":snappedf(float(sim.state.coins),.01)},
            "gems":{"earned_total":snappedf(earned_gems,.01),"spent_total":snappedf(spent_gems,.01),"spent_by_category":_rounded(spent.gems),
                "earned_by_action":_rounded(gained.gems),"earned_from_kills":snappedf(earned_gems-_sum(gained.gems),.01),"balance":snappedf(float(sim.state.gems),.01)}},
        "opportunities":opportunities(),"explored_percent_current_map":explored_percent(),
        "offline":offline,"offline_claims":offline.claims,"offline_pending_at_end":_offline_brief(offline_pending()),
        "automation_upgrades":_automation_levels(),"automation_first_purchase":automation_first,
        "milestones":milestones,"mission_days":mission_days,"purchase_waits":waits,"open_wants":_open_wants(),
        "rejections":rec.failure_counts(),"prestige_field_diffs":prestige_diffs}

func _offline_brief(p: Dictionary) -> Dictionary:
    if p.is_empty():return {}
    return {"seconds":snappedf(float(p.seconds),.1),"rewarded_hours":snappedf(float(p.rewarded_hours),.001),"coins":snappedf(float(p.coins),.01),"gems":snappedf(float(p.gems),.01),"items":_count(p.items)}
func _automation_levels() -> Dictionary:
    var out: Dictionary={}
    var keys: Array=sim.state.upgrades.keys();keys.sort()
    for key in keys:
        if AUTOMATION.has(str(key).split(":")[0]) and int(sim.state.upgrades[key])>0:out[str(key)]=int(sim.state.upgrades[key])
    return out
func _open_wants() -> Array:
    var out: Array=[]
    var keys: Array=wants.keys();keys.sort()
    for k in keys:
        if rec.active-float(wants[k].seen_t)>600.0:continue
        out.append({"want":k,"since_t":wants[k].since_t,"since_c":wants[k].since_c,"open_active_s":snappedf(rec.active-float(wants[k].since_t),.1),"open_calendar_s":snappedf(calendar_now()-float(wants[k].since_c),.1)})
    return out

func _gear(id: String) -> Dictionary:
    if id=="":return {"id":"","tier":0,"merge":0}
    return {"id":id,"tier":int(sim.catalog.items[id].get("tier",1)),"merge":merge_of(id)}
func _sum(d: Dictionary) -> float:
    var total:=0.0
    for k in d:total+=float(d[k])
    return total
func _rounded(d: Dictionary) -> Dictionary:
    var out: Dictionary={}
    var keys: Array=d.keys();keys.sort()
    for k in keys:out[k]=snappedf(float(d[k]),.01)
    return out
