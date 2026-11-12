extends RefCounted
## Player-profile playtesting, LootFarmer-specific part: the game adapter.
## It owns one real LootSimulation and gives a policy
##   - read-only observations (plain values and copies), and
##   - named player actions, each delegating to one public game function a player's tap reaches.
## No action writes a state dictionary to grant an outcome. The only fields written here are the ones the
## game's own input layer writes: sim.movement (the joystick) and sim.clock_override (the test clock seam).
## Every action returns {"ok": bool, "reason": String}; rejections carry the game's own refusal key.
## Policy logic never lives here.

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

func setup(simulation,recorder,seed_value: int,start_unix: float) -> void:
    sim=simulation;rec=recorder
    sim.clock_override=start_unix
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
            deaths.append(row);rec.event("death",row);_recent_aggro=[]
        "PLAYER_LEVEL_UP":
            level_times[str(level())]=snappedf(rec.active,.1)
            rec.event("level_up",{"level":level()})
        "STAGE_UNLOCKED":
            var key2:=str(int(sim.state.unlocked_stage))
            if not stage_unlock_times.has(key2):stage_unlock_times[key2]=snappedf(rec.active,.1)
            rec.event("stage_unlocked",{"stage":int(sim.state.unlocked_stage),"prestiges":int(sim.state.prestiges)})
        "WORLD_COMPLETE":rec.event("world_complete",{})

func _on_milestone(kind: String,id: String) -> void:
    match kind:
        "discovered":rec.event("opportunity_discovered",{"id":id})
        "ready":
            if prestige_ready_time<0:prestige_ready_time=snappedf(rec.active,.1)
            rec.event("opportunity_ready",{"id":id})
        "boss_found":
            if not boss_found_times.has(id):boss_found_times[id]=snappedf(rec.active,.1)
            rec.event("boss_found",{"id":id})
        "card":rec.event("card_awarded",{"id":id})
        "prestiged":rec.event("prestige_completed",{"cards":id,"prestiges":int(sim.state.prestiges)})

func _on_boss_defeated(_actor: String,group: int,_at: Vector2) -> void:
    var id:=str(sim.catalog.groups[group].id)
    if not boss_first_kill_times.has(id):boss_first_kill_times[id]=snappedf(rec.active,.1)
    rec.event("boss_defeated",{"id":id,"level":level(),"hp_left":snappedf(hp_frac(),.01),"lifetime_defeats_before":int(sim.state.group_kills[group])})

func _on_evolved(source: String,target: String) -> void:
    counts.evolutions+=1
    rec.event("evolved",{"from":source,"to":target})

func first(key: String) -> void:
    if not first_times.has(key):
        first_times[key]=snappedf(rec.active,.1)
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

func claim_offline() -> Dictionary:
    return _act("claim_offline","offline","offline",func():return sim.campaign.claim_offline())

## The whole Prestige transaction is two real calls: begin_prestige, then one choose_card per opportunity.
func begin_prestige() -> Dictionary:
    _before_prestige=sim.state.duplicate(true)
    var ids: Array=sim.campaign.awardable_ids()
    var result:=_act("begin_prestige",",".join(ids),"prestige_settlement",func():return sim.campaign.begin_prestige(),true,{"level":level(),"coins":floorf(coins()),"gems":floorf(gems())})
    if not result.ok:_before_prestige={}
    return result

func choose_card(id: String) -> Dictionary:
    var result:=_act("choose_card",id,"prestige_settlement",func():return sim.campaign.choose_card(id))
    if result.ok and sim.state.prestige_batch.is_empty() and not _before_prestige.is_empty():
        prestige_times.append(snappedf(rec.active,.1))
        prestige_diffs.append(_field_diff(_before_prestige,sim.state))
        _before_prestige={}
        stage_enter_times["1@p%d" % int(sim.state.prestiges)]=snappedf(rec.active,.1)
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
        "offline_claims":"not_measured","prestige_field_diffs":prestige_diffs}

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
