extends RefCounted
## Campaign rules share the simulation's save state; this object owns no second save.
var sim
var reveal_clock: float=0
var discovery_revision: int=0
var fog_rules=preload("res://resources/game/fog_rules.tres")
var objective_clock: float=0
var offline_receipt: Dictionary={}
## Change 15: first-profile progression (menu reveals, early equipment guarantee) and Map Mastery.
var onboarding
var mastery
var completion
var guided
## Change 35: the one automatic review invitation (state.review) and its storefront routing.
var review
## Change 65: the shared tutorial-card registry (its reading progress is normalized on load).
const HelpCards=preload("res://scripts/game/help_cards.gd")
func _init(owner) -> void:
    sim=owner
    guided=preload("res://scripts/game/guided_progress.gd").new(owner)
    review=preload("res://scripts/game/review_invitation.gd").new(owner)
    onboarding=preload("res://scripts/game/onboarding.gd").new(owner)
    mastery=preload("res://scripts/game/mastery.gd").new(owner)
    # Change 83: Game Completion (Map Mastery, Prestige cards, Player and enemy upgrades).
    completion=preload("res://scripts/game/completion.gd").new(owner)
func stage() -> Dictionary: return sim.catalog.stages[int(sim.state.stage)-1]
func initialize() -> void:
    reveal_clock=0;objective_clock=0;offline_receipt={};camp_supply_waiting=""
    sim.state.merge({"fog_layout_revision":fog_rules.layout_revision,"tutorial":{"mode":"pending","done":[],"seen":onboarding.initial_seen()},"stage":1,"unlocked_stage":1,"stage_worlds":{},"camps":{"1":[0]},"explored":{},"discovered":{},"run_kills":{},"keys":[],"final_discovered":false,"final_complete":false,"final_unsealed":false,"final_warning_ok":false,"final_experience":false,"final_celebrated":false,"final_ending_seen":false,"completion_maxed":[],"skills":["","",""],"skill_auto":[false,false,false],"skill_cooldowns":{},"merge_timers":{},"merge_cursors":{},"opportunities":{},"owned_cards":[],"consumed":[],"prestige_batch":{},"prestige_collapsed":{},"follow":"","counters":{},"online_items":{},"online_coins":0.0,"online_gems":0.0,"offline_total":0.0,"offline_longest":0.0,"offline_income":0.0,"offline_remainders":{},"offline_snapshot":{},"offline_pending":{},"missions":[],"main_claimed":[],"main_ready":{},"mission_day":"","consumable_uses":0,"mission_auto":false,"world_complete":false,"skills_seen":[],"discovered_spots":{},"camps_known":{},"onboarding":onboarding.initial(),"mastery":mastery.initial(),"follow_mastery":"","bosses_found":[],"follow_mission":"","review":review.initial(),"respawns":{},"hunt":hunt_initial(),"camp_supply":{}},true)
    mastery.reset_cache()
    sim.state.group_kills.resize(sim.catalog.groups.size());sim.state.group_kills.fill(0)
    sim.state.collect_clocks.resize(sim.catalog.groups.size());sim.state.collect_clocks.fill(0.0)
    refresh_missions()
## Change 8 solid scenery: the stage scene's Decor carries editor-visible "Block" shapes at tree
## trunks, boulders, lamps, ponds and fenced fields. They are read once per stage per process.
static var _obstacle_cache: Dictionary={}
const STAGE_SCENES=preload("res://scripts/game/stage_scenes.gd")
var obstacle_list: Array=[]
var obstacle_grid: Dictionary={}
const OBSTACLE_CELL:=64.0
## Actors are points with this clearance; tools/compose_stage_art.gd keeps solids far enough apart.
const ACTOR_CLEARANCE:=6.0
## Change 24: build a stage's obstacle grid ahead of travel. True when it was built by this call.
func prepare_obstacles(id: int) -> bool:
    if _obstacle_cache.has(id):return false
    _obstacle_cache[id]=_read_obstacles(id)
    return true
func load_obstacles() -> void:
    var id:=int(sim.state.stage)
    if not _obstacle_cache.has(id):_obstacle_cache[id]=_read_obstacles(id)
    obstacle_list=_obstacle_cache[id].list;obstacle_grid=_obstacle_cache[id].grid
## Change 24: read from the stage PackedScene's SceneState (the shared StageScenes cache) instead of
## instantiating and freeing the whole stage: the same shapes, in the same order, at the same
## positions (each shape's own position plus its Node2D ancestors', the scene root excluded, summed
## from the shape upward as before).
func _read_obstacles(id: int) -> Dictionary:
    var list: Array=[];var grid: Dictionary={}
    var packed: PackedScene=STAGE_SCENES.scene(id)
    if packed==null:return {"list":list,"grid":grid}
    var state: SceneState=packed.get_state()
    var nodes: Dictionary={}
    var shapes: Array=[]
    for i in range(state.get_node_count()):
        var info: Dictionary={"pos":Vector2.ZERO,"node2d":ClassDB.is_parent_class(state.get_node_type(i),&"Node2D"),"shape":null,"parent":str(state.get_node_path(i,true))}
        for j in range(state.get_node_property_count(i)):
            match state.get_node_property_name(i,j):
                &"position":info.pos=state.get_node_property_value(i,j)
                &"shape":info.shape=state.get_node_property_value(i,j)
        var key:=str(state.get_node_path(i))
        nodes[key]=info
        if state.get_node_type(i)==&"CollisionShape2D":shapes.append(info)
    for info in shapes:
        var pos:=Vector2.ZERO
        var n: Dictionary=info
        while true:
            if n.node2d:pos+=n.pos
            if n.parent=="." or not nodes.has(n.parent):break
            n=nodes[n.parent]
        if info.shape is CircleShape2D:list.append({"c":pos,"r":(info.shape as CircleShape2D).radius})
        elif info.shape is RectangleShape2D:
            var size: Vector2=(info.shape as RectangleShape2D).size
            list.append({"rect":Rect2(pos-size*.5,size)})
    for i in range(list.size()):
        var o: Dictionary=list[i]
        var box: Rect2=(Rect2(o.c-Vector2.ONE*o.r,Vector2.ONE*o.r*2) if o.has("c") else o.rect).grow(ACTOR_CLEARANCE+1)
        for y in range(floori(box.position.y/OBSTACLE_CELL),floori(box.end.y/OBSTACLE_CELL)+1):
            for x in range(floori(box.position.x/OBSTACLE_CELL),floori(box.end.x/OBSTACLE_CELL)+1):
                var key:=Vector2i(x,y)
                if not grid.has(key):grid[key]=[]
                grid[key].append(i)
    return {"list":list,"grid":grid}
## Is this point inside a solid (inflated by the actor clearance)? Returns the outward normal or ZERO.
## Rectangles are measured from their nearest point, so their inflated corners are round and an actor
## rounds a corner smoothly instead of flipping between two sides.
func _contact(o: Dictionary,p: Vector2,tolerance:=0.0) -> Vector2:
    var q: Vector2=o.c if o.has("c") else Vector2(clampf(p.x,o.rect.position.x,o.rect.end.x),clampf(p.y,o.rect.position.y,o.rect.end.y))
    var r: float=float(o.r) if o.has("c") else 0.0
    var d: Vector2=p-q
    if d.length()>=r+ACTOR_CLEARANCE+tolerance:return Vector2.ZERO
    if d.length()>.001:return d.normalized()
    if o.has("c"):return Vector2.UP
    # Inside the rectangle itself: leave by the nearest side.
    var rect: Rect2=o.rect
    var sides:=[p.x-rect.position.x,rect.end.x-p.x,p.y-rect.position.y,rect.end.y-p.y]
    var best:=0
    for i in range(4):
        if sides[i]<sides[best]:best=i
    return [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN][best]
func _push_out(o: Dictionary,p: Vector2) -> Vector2:
    var n:=_contact(o,p)
    if n==Vector2.ZERO:return p
    if o.has("c"):return o.c+n*(float(o.r)+ACTOR_CLEARANCE+.01)
    var rect: Rect2=o.rect
    var q:=Vector2(clampf(p.x,rect.position.x,rect.end.x),clampf(p.y,rect.position.y,rect.end.y))
    if rect.has_point(p):q=p+n*minf(minf(p.x-rect.position.x,rect.end.x-p.x),minf(p.y-rect.position.y,rect.end.y-p.y))
    return q+n*(ACTOR_CLEARANCE+.01)
## A movement step that meets a solid slides along it, on the side that still heads for the goal, so
## chasing, returning home and auto-farm walk around trees instead of stopping. Facing a long solid
## (a pond or fenced field) head-on, the slide heads for its nearer end. Solids are convex and always
## separated by a walkable gap (tools/compose_stage_art.gd), so this never traps an actor.
func blocked_step(old: Vector2,next: Vector2,goal: Vector2) -> Vector2:
    if obstacle_list.is_empty():return next
    var ids: Array=obstacle_grid.get(Vector2i(floori(next.x/OBSTACLE_CELL),floori(next.y/OBSTACLE_CELL)),[])
    if ids.is_empty():return next
    var length:=old.distance_to(next)
    var heading:=(goal-old).normalized()
    for i in ids:
        var o: Dictionary=obstacle_list[i]
        if _contact(o,next)==Vector2.ZERO:continue
        # The side the actor is touching now decides the slide (the tentative step can slip past a
        # corner and report the wrong side).
        var n:=_contact(o,old,.5)
        if n==Vector2.ZERO:n=_contact(o,next)
        var t:=Vector2(-n.y,n.x)
        if t.dot(heading)<0:t=-t
        if o.has("rect") and absf(t.dot(heading))<.35:
            var rect: Rect2=o.rect
            var along: float=old.dot(t.abs());var lo: float=rect.position.dot(t.abs());var hi: float=rect.end.dot(t.abs())
            var aim: float=goal.dot(t.abs())
            if aim>lo and aim<hi:t=t.abs()*(-1.0 if along-lo<hi-along else 1.0)
        next=_push_out(o,old+t*length)
    for i in ids:next=_push_out(obstacle_list[i],next)
    return next
func solid_at(p: Vector2) -> bool:
    for i in obstacle_grid.get(Vector2i(floori(p.x/OBSTACLE_CELL),floori(p.y/OBSTACLE_CELL)),[]):
        if _contact(obstacle_list[i],p)!=Vector2.ZERO:return true
    return false
func configure_stage() -> void:
    load_obstacles()
    var d=stage()
    sim.catalog.world.size=d.size
    sim.catalog.world.spawns=d.spawns
    sim.catalog.world.spawn_prices=[0,camp_price(1),camp_price(2)]
    var key=str(sim.state.stage)
    if not sim.state.camps.has(key):sim.state.camps[key]=[0]
    sim.state.spawns=sim.state.camps[key]
    sim.state.spawn=clampi(int(sim.state.spawn),0,d.spawns.size()-1)
    # Change 61: the respawn camp is always an owned camp of this stage (arrival camp as the fallback).
    if not sim.state.spawns.has(int(sim.state.spawn)):sim.state.spawn=0
func camp_price(index: int) -> int:
    if index==0:return 0
    # Change 77: the Camp Survey discount is gone (its card became Camp Supplies), so camps cost the map price.
    return maxi(1,ceili([0,50,150][index]*map_cost_factor(int(sim.state.stage))))
## Change 16: every Coin price tied to a map (enemy, map and camp upgrades, camp unlocks, the Map
## Details floor) grows by progression.map_cost_growth (1.55) per map, slightly faster than the base
## Coin income (1.5 per map), so each new map costs a little more relative to what it pays.
func map_cost_factor(st: int) -> float:
    return pow(float(sim.catalog.progression.get("map_cost_growth",2.0)),st-1)
func variants(g: int) -> Array:
    if sim.catalog.groups[g].boss:return [2]
    return [0,1,2,3] if not sim.catalog.groups[g].skills.is_empty() else [0,1,2]
## Variant spots sit this far from the type center on both axes. tools/layout_campaign_groups.py uses
## the same value to keep every spot outside the auto-acquisition range of every other spot.
const SPOT_OFFSET:=100.0
func spot_offset() -> float:return SPOT_OFFSET
func spot(g: int,v: int) -> Vector2:
    var d: Dictionary=sim.catalog.groups[g]
    var pos=Vector2(d.center[0],d.center[1])
    if not d.boss:pos+=Vector2(-SPOT_OFFSET if v%2==0 else SPOT_OFFSET,-SPOT_OFFSET if v<2 else SPOT_OFFSET)
    return pos
func group_id(id: String) -> int:
    for i in range(sim.catalog.groups.size()):
        if sim.catalog.groups[i].id==id:return i
    return -1
func bonus(key: String) -> float:
    var total=0.0
    for id in sim.state.get("owned_cards",[]):
        var d: Dictionary=sim.catalog.campaign.cards.get(id,{})
        if d.get("effect","")==key:total+=float(d.value)
    for d in sim.catalog.campaign.combos:
        if d.effect==key and combo_owned(d):total+=float(d.value)
    # Old prototype cards remain valid migration bonuses, not new duplicates.
    total+=.05*float(sim.state.get("cards",{}).get(key,0))
    # Change 15: Map Mastery rewards add to the same pool, so every getter applies them exactly once.
    total+=mastery.bonus(key)
    return total
func combo_owned(d: Dictionary) -> bool:
    for id in d.cards:
        if not sim.state.get("owned_cards",[]).has(id):return false
    return true
func move_speed() -> float:return 90*(1+.1*sim.level("movement")+bonus("movement"))
func in_combat() -> bool:
    var p: Dictionary=sim.state.player
    if p.hp<=0:return false
    if p.windup>0 or p.quiet<5:return true
    for e in sim.state.enemies:
        if e.hp>0 and (e.aggro or e.windup>0):return true
    return false
## Out-of-combat recovery as a fraction of max HP per second: slow anywhere, fast beside an
## owned camp of the current stage. In combat it is zero, so Heal and potions keep their roles.
func rest_rate() -> float:
    if in_combat():return 0.0
    var r: Dictionary=sim.catalog.progression.rest
    return float(r.camp) if resting_camp()>=0 else float(r.field)*(1+bonus("field_rest"))
func resting_camp() -> int:
    var p: Vector2=sim.position_of(sim.state.player)
    for camp in sim.state.spawns:
        var a: Array=stage().spawns[int(camp)]
        if p.distance_to(Vector2(a[0],a[1]))<=float(sim.catalog.progression.rest.camp_radius):return int(camp)
    return -1
## Change 80: the stage selector's state for every stage 1-8 in canonical order (current Prestige run only;
## owned camps and lifetime records never count). unlocked: reachable now (st <= unlocked_stage). cleared: the
## gate of a stage before the frontier was defeated in this run (that is what opened the next stage), or the
## final stage's clear (world_complete). next: the one stage after the frontier, still locked (none once all
## eight are open). here: the map the player stands on, independent of the others. gate_done / gate_total:
## this run's gate progress on that stage.
func stage_progress() -> Array:
    var result: Array=[]
    var unlocked:=int(sim.state.unlocked_stage)
    for st in range(1,sim.catalog.stages.size()+1):
        var gates: Array=sim.catalog.stages[st-1].gates
        var done:=0
        for id in gates:
            if int(sim.state.run_kills.get(id,0))>0:done+=1
        var final_stage: bool=gates.is_empty()
        result.append({"stage":st,"unlocked":st<=unlocked,"cleared":(st<unlocked) or (final_stage and st<=unlocked and bool(sim.state.get("world_complete",false))),
            "next":st==unlocked+1,"here":st==int(sim.state.stage),"final":final_stage,"gate_done":done,"gate_total":gates.size()})
    return result
## The next stage to unlock (the frontier + 1), or 0 when every stage is open.
func next_stage_to_unlock() -> int:
    var unlocked:=int(sim.state.unlocked_stage)
    return unlocked+1 if unlocked<sim.catalog.stages.size() else 0
func travel_reason(st: int,camp: int) -> String:
    var lock: String=sim.action_lock_reason()
    if lock!="":return lock
    if sim.state.player.hp<=0:return "CANNOT_USE"
    # Change 82: the sealed Green Alien arena (and its unsealing ceremony) cannot be left by any travel.
    if arena_active() or ceremony_active():return "ARENA_SEALED"
    if celebration_active():return "FINAL_CELEBRATING"
    if in_combat():return "TRAVEL_COMBAT"
    if st<1 or st>int(sim.state.unlocked_stage):return "STAGE_LOCKED"
    if camp<0 or camp>=sim.catalog.stages[st-1].spawns.size():return "CAMP_LOCKED"
    if not sim.state.camps.get(str(st),[0]).has(camp):return "CAMP_LOCKED"
    return ""
## Change 61 (approved separation): Select chooses the respawn camp; Travel / Teleport only moves the
## player. The selected respawn camp is kept per stage (state.respawns, stage key -> camp; kept with
## the camps by Prestige since Change 76): leaving a stage records its choice and arriving restores the destination
## stage's own choice (its arrival camp when none was made or that camp is no longer owned). Travel
## never changes it, so a trip to another camp still respawns the player at the camp they selected.
func camp_action(st: int,camp: int,teleport: bool) -> bool:
    if not sim.action_lock_reason().is_empty():return sim.fail(sim.action_lock_reason())
    if teleport and (arena_active() or ceremony_active()):return sim.fail("ARENA_SEALED")
    if teleport and celebration_active():return sim.fail("FINAL_CELEBRATING")
    if teleport:
        var reason=travel_reason(st,camp)
        if reason!="":return sim.fail(reason)
        var before_camp:=-1
        var before_stage:=int(sim.state.stage)
        var from: Vector2=sim.position_of(sim.state.player)
        if st==before_stage:before_camp=resting_camp()
        if st!=int(sim.state.stage):
            sim.clear_helpers()
            sim.state.stage_worlds[str(sim.state.stage)]={"enemies":sim.state.enemies.duplicate(true),"pickups":sim.state.pickups.duplicate(true)}
            sim.state.respawns[str(sim.state.stage)]=int(sim.state.spawn)
            sim.state.stage=st;sim.state.spawn=int(sim.state.respawns.get(str(st),0))
            configure_stage()
            var saved: Dictionary=sim.state.stage_worlds.get(str(st),{})
            sim.state.enemies=saved.get("enemies",[]).duplicate(true)
            sim.state.pickups=saved.get("pickups",[]).duplicate(true)
            sim._sync_spawn_counts()
            # Change 88: the player left this map, so any Green Alien fight here ended: it waits at full HP.
            fresh_final_hp(sim.state.enemies,false)
        var pos: Array=stage().spawns[camp]
        sim.state.player.x=pos[0];sim.state.player.y=pos[1]
        sim.state.player.windup=0;sim.state.player.target="";sim.state.player.idle=0
        sim.state.focus=-1;sim.focus_walk_time=0.0;sim.end_focus_return();sim.clear_target();reveal()
        if st==before_stage and camp!=before_camp:guided.action("camp_travel",str(camp))
        sim.touch();SaveService.save_now()
        sim.traveled.emit(st!=before_stage,from,sim.position_of(sim.state.player))
        return true
    if st!=int(sim.state.stage) or camp<0 or camp>=stage().spawns.size():return false
    if not sim.state.spawns.has(camp):
        if not camp_known(camp):return sim.fail("CAMP_UNDISCOVERED")
        if not sim.pay("coins",camp_price(camp)):return false
        sim.state.spawns.append(camp)
        sim.state.camps[str(st)]=sim.state.spawns
        progress("camp","",1);reveal()
    else:
        sim.state.spawn=camp;sim.state.respawns[str(st)]=camp
        guided.action("respawn",str(camp))
        sim.respawn_selected.emit(camp)
    sim.touch();SaveService.save_now();return true
# ---------------------------------------------------------------- Camp Supplies (Change 77, Change 80)
# The Regional card regional_c3 (formerly Camp Survey, same id, path and Regional set) has effect camp_supplies.
# Change 80: every owned camp gives a batch of <card value> (3) free random supplies, then rests for <card
# cooldown> (600) seconds before it can give the next batch. Each camp keeps its own record in
# state.camp_supply ("stage:camp" -> {"next": playtime at which a new batch may start, "left": units of the
# current batch still owed}); a missing record means ready with nothing owed.
# - Clock: state.playtime_total (active play, saved, kept by Prestige). It advances while the player farms
#   or travels anywhere in the game and stops while the app is closed, paused, in the background or holding a
#   Prestige choice (sim.step does not run), so no supplies are produced offline and device clock changes or
#   reloads cannot shorten a cooldown.
# - A visit is standing alive inside an owned camp's rest radius on the current, reachable map (resting_camp),
#   checked on the fog tick, so a camp that becomes ready while the player stands in it gives its batch with
#   no need to leave and re-enter. Teleport, respawn or reload during the cooldown give nothing.
# - No backpay: a ready camp holds one batch at most (the next batch starts only when the last one is done).
# - Inventory: one unit at a time from the map's weighted supply pool filtered by what fits now; each unit is
#   granted and counted down in the same step and saved at once. Units that do not fit stay owed ("left"),
#   and the camp's cooldown starts only when the whole batch is delivered.
# - Prestige keeps state.camp_supply (camps and the clock are kept too); Hard Reset clears it.
var camp_supply_waiting: String=""
func camp_supplies_owned() -> bool:return bonus("camp_supplies")>0
func camp_supply_key(st: int,camp: int) -> String:return "%d:%d" % [st,camp]
## Supplies per batch: the owned camp_supplies card value (3).
func camp_supply_batch() -> int:return maxi(0,roundi(bonus("camp_supplies")))
## Seconds of active play between two batches of one camp (the card's "cooldown", 600).
func camp_supply_cooldown() -> float:
    for id in sim.catalog.campaign.cards:
        var d: Dictionary=sim.catalog.campaign.cards[id]
        if str(d.effect)=="camp_supplies":return float(d.get("cooldown",600))
    return 600.0
func camp_supply_now() -> float:return float(sim.state.get("playtime_total",0.0))
func camp_supply_record(st: int,camp: int) -> Dictionary:
    var r=sim.state.get("camp_supply",{}).get(camp_supply_key(st,camp),{})
    return r if r is Dictionary else {}
## Units this camp would give now: the rest of an unfinished batch, a full batch once its cooldown is over, else 0.
func camp_supply_owed(st: int,camp: int) -> int:
    var r:=camp_supply_record(st,camp)
    if int(r.get("left",0))>0:return mini(int(r.left),camp_supply_batch())
    return camp_supply_batch() if camp_supply_now()>=float(r.get("next",0.0)) else 0
## Seconds until this camp can give again (0 when it is ready or owes the rest of a batch).
func camp_supply_wait(st: int,camp: int) -> float:
    var r:=camp_supply_record(st,camp)
    if int(r.get("left",0))>0:return 0.0
    return maxf(0.0,float(r.get("next",0.0))-camp_supply_now())
## Supplies a camp of this map can give: the drop pool of that map (min_stage) that fits the inventory now.
func camp_supply_pool(st: int) -> Array:
    var result: Array=[]
    for id in sim.supply_ids():
        if int(sim.supply(id).get("min_stage",1))<=st and float(sim.supply(id).get("drop_weight",0))>0 and sim.can_add(id):result.append(id)
    return result
## Grants what this camp owes when the player is there; returns the supply ids given this step (in order,
## one entry per unit; empty when nothing was given).
func camp_supply_step() -> Array:
    var given: Array=[]
    if not camp_supplies_owned() or sim.state.player.hp<=0:return given
    var st:=int(sim.state.stage)
    if st<1 or st>int(sim.state.unlocked_stage):return given
    var camp:=resting_camp()
    if camp<0:
        camp_supply_waiting="";return given
    var owed:=camp_supply_owed(st,camp)
    if owed<=0:return given
    var key:=camp_supply_key(st,camp)
    var record:=camp_supply_record(st,camp)
    while owed>0:
        var pool:=camp_supply_pool(st)
        if pool.is_empty():break
        var total:=0.0
        for id in pool:total+=float(sim.supply(id).drop_weight)
        var roll: float=sim.rng.randf()*total
        var pick: String=pool.back()
        for id in pool:
            roll-=float(sim.supply(id).drop_weight)
            if roll<0:pick=id;break
        if not sim.add_item(pick,1):break
        given.append(pick);owed-=1
    if not given.is_empty():
        var all: Dictionary=sim.state.get("camp_supply",{})
        # The whole batch delivered: the camp rests from now on. Otherwise the rest stays owed (no cooldown yet).
        all[key]={"next":camp_supply_now()+camp_supply_cooldown(),"left":0} if owed==0 else {"next":float(record.get("next",0.0)),"left":owed}
        sim.state.camp_supply=all
        sim.touch();SaveService.save_now()
        sim.camp_supply_granted.emit(given.duplicate(),owed)
    if owed>0:
        # Inventory full: what is owed waits for a later check; one notice per camp visit, never repeated.
        if camp_supply_waiting!=key:
            camp_supply_waiting=key;sim.camp_supply_waiting.emit()
    else:camp_supply_waiting=""
    return given
## Saved camp records: "stage:camp" -> {"next": float, "left": int} for valid camps of valid maps. "next" is
## clamped to at most one cooldown after the saved clock (a damaged or edited value never locks a camp for
## longer), "left" to one batch. A record equal to "ready, nothing owed" is dropped.
func normalize_camp_supply(out: Dictionary) -> void:
    var clean: Dictionary={}
    var now: float=float(out.get("playtime_total",0.0)) if number(out.get("playtime_total")) else 0.0
    var cap: int=3
    for id in sim.catalog.campaign.cards:
        if str(sim.catalog.campaign.cards[id].effect)=="camp_supplies":cap=maxi(1,roundi(float(sim.catalog.campaign.cards[id].value)))
    if out.get("camp_supply") is Dictionary:
        for key in out.camp_supply:
            var parts: PackedStringArray=str(key).split(":")
            var r=out.camp_supply[key]
            if parts.size()!=2 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or not r is Dictionary:continue
            var st:=int(parts[0]);var camp:=int(parts[1])
            if st<1 or st>sim.catalog.stages.size() or camp<0 or camp>=sim.catalog.stages[st-1].spawns.size():continue
            var next: float=clampf(float(r.get("next",0.0)) if number(r.get("next")) else 0.0,0.0,now+camp_supply_cooldown())
            var left: int=clampi(int(r.get("left",0)) if number(r.get("left")) else 0,0,cap)
            if left==0 and next<=now:continue
            clean[camp_supply_key(st,camp)]={"next":next,"left":left}
    out["camp_supply"]=clean
## Change 80 (once, state.migrations "camp_supply_cooldowns"): Change 77/79 saves kept state.camp_supplies
## (stage key -> camps that already gave their one supply this Prestige run). That list is retired. A camp in
## it starts a full cooldown from the moment of loading (so updating never pays it again at once); every other
## owned camp had not given its supply this run and is ready for its first batch of 3.
func migrate_camp_supply_cooldowns(out: Dictionary) -> void:
    var migrations: Array=out.get("migrations",[]) if out.get("migrations",[]) is Array else []
    if migrations.has("camp_supply_cooldowns"):
        out.erase("camp_supplies");return
    var now: float=float(out.get("playtime_total",0.0)) if number(out.get("playtime_total")) else 0.0
    var records: Dictionary=out.camp_supply if out.get("camp_supply") is Dictionary else {}
    if out.get("camp_supplies") is Dictionary:
        for key in out.camp_supplies:
            if not str(key).is_valid_int() or int(key)<1 or int(key)>sim.catalog.stages.size() or not out.camp_supplies[key] is Array:continue
            for camp in out.camp_supplies[key]:
                if number(camp) and int(camp)>=0 and int(camp)<sim.catalog.stages[int(key)-1].spawns.size():
                    records[camp_supply_key(int(key),int(camp))]={"next":now+camp_supply_cooldown(),"left":0}
    out.erase("camp_supplies")
    out["camp_supply"]=records
    migrations.append("camp_supply_cooldowns")
    out.migrations=migrations
func cell_key(pos: Vector2) -> String:
    return "%d,%d" % [floori(pos.x/fog_rules.cell_size),floori(pos.y/fog_rules.cell_size)]
func in_bounds(pos: Vector2) -> bool:
    return Rect2(Vector2.ZERO,Vector2(stage().size[0],stage().size[1])).has_point(pos)
func cell_known(pos: Vector2) -> bool:
    if not in_bounds(pos):return false
    var mask=sim.state.explored.get(str(sim.state.stage))
    if not mask is PackedByteArray:return false
    var i:=floori(pos.y/fog_rules.cell_size)*fog_columns(int(sim.state.stage))+floori(pos.x/fog_rules.cell_size)
    return i<mask.size() and mask[i]!=0
# ---------------------------------------------------------------- explored masks (Change 24)
## Explored fog cells of a stage are one byte per cell, row-major (index y*columns+x, 1 = explored),
## in state.explored[str(stage)]. The save stores each mask deflated and Base64-encoded
## (encode_explored/decode_explored): a few kilobytes instead of one JSON key per cell.
func fog_columns(st: int) -> int:
    return ceili(float(sim.catalog.stages[st-1].size[0])/fog_rules.cell_size)
func fog_rows(st: int) -> int:
    return ceili(float(sim.catalog.stages[st-1].size[1])/fog_rules.cell_size)
func fog_cell_count(st: int) -> int:
    return fog_columns(st)*fog_rows(st)
## The stage's explored mask (a copy-on-write value). A missing or malformed entry reads as an
## unexplored map of the right size.
func explored_mask(st: int) -> PackedByteArray:
    var mask=sim.state.explored.get(str(st))
    if mask is PackedByteArray and mask.size()==fog_cell_count(st):return mask
    var empty:=PackedByteArray();empty.resize(fog_cell_count(st))
    return empty
func explored_count(st: int) -> int:
    return explored_mask(st).count(1)
func cell_explored(st: int,x: int,y: int) -> bool:
    if x<0 or y<0 or x>=fog_columns(st) or y>=fog_rows(st):return false
    return explored_mask(st)[y*fog_columns(st)+x]!=0
## Fixtures and tools: mark the given cells (Vector2i) explored on a stage, or every cell with all.
func explore_cells(st: int,cells: Array,all:=false) -> void:
    var mask:=explored_mask(st)
    if all:mask.fill(1)
    for c in cells:
        var cell: Vector2i=c
        if cell.x>=0 and cell.y>=0 and cell.x<fog_columns(st) and cell.y<fog_rows(st):mask[cell.y*fog_columns(st)+cell.x]=1
    sim.state.explored[str(st)]=mask
    discovery_revision+=1
func encode_explored(explored: Dictionary) -> Dictionary:
    var out: Dictionary={}
    for key in explored:
        if explored[key] is PackedByteArray:out[key]=Marshalls.raw_to_base64(explored[key].compress(FileAccess.COMPRESSION_DEFLATE))
        else:out[key]=explored[key]
    return out
## A saved (Base64 deflate) or in-memory mask of stage st, checked: exactly one 0/1 byte per fog
## cell. Anything else decodes to an empty array, which valid_snapshot rejects.
func decode_explored(st: int,value) -> PackedByteArray:
    if st<1 or st>sim.catalog.stages.size():return PackedByteArray()
    var n:=fog_cell_count(st)
    var mask:=PackedByteArray()
    if value is PackedByteArray:mask=value
    elif value is String and not value.is_empty() and value.length()%4==0:
        var raw:=Marshalls.base64_to_raw(value)
        if not raw.is_empty():mask=raw.decompress(n,FileAccess.COMPRESSION_DEFLATE)
    if mask.size()!=n or mask.count(0)+mask.count(1)!=n:return PackedByteArray()
    return mask
## Sight inputs of one moment, computed once for a loop over many positions (Change 24): the same
## predicate as can_see() without re-deriving the reveal bonuses for every actor, drop or particle.
class Sight extends RefCounted:
    var mask: PackedByteArray
    var columns: int
    var cell: float
    var size: Vector2
    var player: Vector2
    var radius: float
    func known(pos: Vector2) -> bool:
        if pos.x<0 or pos.y<0 or pos.x>=size.x or pos.y>=size.y:return false
        return mask[floori(pos.y/cell)*columns+floori(pos.x/cell)]!=0
    func visible(pos: Vector2) -> bool:
        if radius<0 or pos.x<0 or pos.y<0 or pos.x>=size.x or pos.y>=size.y:return false
        var center:=(Vector2(floorf(pos.x/cell),floorf(pos.y/cell))+Vector2.ONE*.5)*cell
        return center.distance_to(player)<=radius
    func sees(pos: Vector2) -> bool:
        return known(pos) or visible(pos)
func sight() -> Sight:
    var s:=Sight.new()
    var st:=int(sim.state.stage)
    s.mask=explored_mask(st);s.columns=fog_columns(st);s.cell=fog_rules.cell_size
    s.size=Vector2(stage().size[0],stage().size[1])
    s.player=sim.position_of(sim.state.player)
    s.radius=vision_radius() if sim.state.player.hp>0 else -1.0
    return s
func discovered(g: int) -> bool:return sim.state.discovered.has(str(g))
## One encounter spot (type + loadout variant). Only found spots get map markers or auto-farm.
func spot_key(g: int,v: int) -> String:return "%d:%d" % [g,2 if sim.catalog.groups[g].boss else v]
func spot_discovered(g: int,v: int) -> bool:return sim.state.discovered_spots.has(spot_key(g,v))
func discover_spot(g: int,v: int) -> void:
    var key:=spot_key(g,v)
    if not sim.state.discovered_spots.has(key):sim.state.discovered_spots[key]=true;discovery_revision+=1;SaveService.mark_dirty()
    if not discovered(g):sim.state.discovered[str(g)]=true;discovery_revision+=1;SaveService.mark_dirty()
## Permanent reveal (explored cells, saved). Change 8: about a third of Change 7's 144.
func player_radius() -> float:
    return fog_rules.player_radius*(1+.25*sim.level("reveal_radius",int(sim.state.stage))+bonus("reveal"))
## Momentary sight around the living player: terrain and enemies show and can be fought, but nothing
## is remembered and no encounter spot is discovered by sight alone. Never saved.
func vision_radius() -> float:
    return player_radius()*fog_rules.vision_factor
func cell_visible(pos: Vector2) -> bool:
    if sim.state.player.hp<=0 or not in_bounds(pos):return false
    var cell: float=fog_rules.cell_size
    var center:=(Vector2(floorf(pos.x/cell),floorf(pos.y/cell))+Vector2.ONE*.5)*cell
    return center.distance_to(sim.position_of(sim.state.player))<=vision_radius()
## Explored or currently in sight: what the world view may draw and what the player may target.
func can_see(pos: Vector2) -> bool:
    return cell_known(pos) or cell_visible(pos)
## Camps are landmarks: sighted from camp_sight_radius, remembered per stage, and their footprint is
## revealed so the camp itself shows through the fog. Enemy spots never use this rule.
func camp_known(camp: int,st: int=-1) -> bool:
    if st<0:st=int(sim.state.stage)
    return sim.state.camps.get(str(st),[0]).has(camp) or sim.state.camps_known.get(str(st),[]).has(camp)
func sight_camps() -> void:
    if sim.state.player.hp<=0:return
    var key:=str(sim.state.stage)
    var known: Array=sim.state.camps_known.get(key,[])
    for i in range(stage().spawns.size()):
        if camp_known(i):continue
        var a:=Vector2(stage().spawns[i][0],stage().spawns[i][1])
        if a.distance_to(sim.position_of(sim.state.player))<=fog_rules.camp_sight_radius:
            known.append(i);sim.state.camps_known[key]=known
            reveal_circle(a,fog_rules.camp_footprint_radius)
            discovery_revision+=1;SaveService.mark_dirty()
            sim.event.emit("CAMP_SIGHTED")
func reveal_circle(pos: Vector2,radius: float) -> bool:
    var st:=int(sim.state.stage)
    var key:=str(st)
    var mask:=explored_mask(st)
    var columns:=fog_columns(st)
    var cell: float=fog_rules.cell_size
    var changed:=false
    for y in range(maxi(0,floori((pos.y-radius)/cell)),mini(fog_rows(st),ceili((pos.y+radius)/cell))):
        for x in range(maxi(0,floori((pos.x-radius)/cell)),mini(columns,ceili((pos.x+radius)/cell))):
            var i:=y*columns+x
            if mask[i]==0 and (Vector2(x,y)*cell+Vector2.ONE*cell*.5).distance_to(pos)<=radius:
                mask[i]=1;changed=true
    if changed or not sim.state.explored.get(key) is PackedByteArray:sim.state.explored[key]=mask
    if changed:discovery_revision+=1;SaveService.mark_dirty()
    return changed
func reveal_segment(start: Vector2,finish: Vector2) -> void:
    if sim.state.player.hp<=0:return
    var samples:=maxi(1,ceili(start.distance_to(finish)/(fog_rules.cell_size*.5)))
    for i in range(1,samples+1):reveal_circle(start.lerp(finish,float(i)/samples),player_radius())
    identify_sites()
## A spot is discovered when its authored home cell, or one of its living actors, stands on an
## explored cell (Change 8: per spot, not per type; the type is known once any spot is).
func identify_sites() -> void:
    for g in stage().groups:
        for v in variants(g):
            if not spot_discovered(g,v) and cell_known(spot(g,v)):discover_spot(g,v)
    for actor in sim.state.enemies:
        if sim.is_helper(actor):continue
        if float(actor.hp)>0 and not spot_discovered(int(actor.group),int(actor.get("variant",2))) and cell_known(sim.position_of(actor)):
            discover_spot(int(actor.group),int(actor.get("variant",2)))
## Change 16: the first time the living player comes within fog_rules.boss_sight_radius of a living
## boss it can see, that boss is found for good (state.bosses_found: kept by Prestige, cleared by Hard
## Reset). It earns one "!WARNING BOSS FOUND!" milestone and one notice, never again. Finding the
## Snowman opens Prestige (prestige_unlocked); it never defeats the boss or opens the next map.
func sight_bosses() -> void:
    if sim.state.player.hp<=0:return
    var p: Vector2=sim.position_of(sim.state.player)
    for e in sim.state.enemies:
        if float(e.hp)<=0 or sim.is_helper(e):continue
        var d: Dictionary=sim.catalog.groups[int(e.group)]
        if not d.boss or sim.state.bosses_found.has(str(d.id)):continue
        var at: Vector2=sim.position_of(e)
        if at.distance_to(p)>fog_rules.boss_sight_radius or not can_see(at):continue
        sim.state.bosses_found.append(str(d.id))
        reveal_circle(at,fog_rules.camp_footprint_radius)
        SaveService.mark_dirty()
        sim.notice.emit("boss_found",str(d.id))
        sim.milestone.emit("boss_found",str(d.id))
        # Change 61: the campaign's next one-second tick (evaluate) then discovers the Snowman's first
        # Prestige opportunity (hunter_o1) and unlocks the one-time 30-defeat mission, so the boss cue
        # plays first and the discovery announces itself just after (Change 16 sound rule).
        # The Snowman's warning comes first, then the Prestige reveal it causes.
        onboarding.evaluate()
func boss_found(id: String) -> bool:
    return sim.state.get("bosses_found",[]).has(id)
func reveal() -> void:
    if sim.state.player.hp>0:reveal_circle(sim.position_of(sim.state.player),player_radius())
    sight_camps()
    sight_bosses()
    var camp_radius:=camp_reveal_radius()
    for camp in sim.state.spawns:
        var a: Array=stage().spawns[int(camp)]
        reveal_circle(Vector2(a[0],a[1]),camp_radius)
    for g in stage().groups:
        if sim.catalog.groups[g].boss and boss_found(str(sim.catalog.groups[g].id)):
            reveal_circle(spot(g,2),fog_rules.camp_footprint_radius)
    identify_sites()
## Change 81: the reveal radius of every owned camp: the base camp radius plus the one global Camp Reveal Radius
## upgrade (+25% of the base per level, additive) and any camp_reveal bonus, each counted once.
func camp_reveal_radius() -> float:
    return fog_rules.camp_radius*(1+sim.player_upgrade_value("camp_radius")+bonus("camp_reveal"))
func target_allowed(e: Dictionary,view: Sight=null) -> bool:
    var d: Dictionary=sim.catalog.groups[int(e.group)]
    var seen: bool=view.sees(sim.position_of(e)) if view!=null else can_see(sim.position_of(e))
    # Change 82: the Green Alien also stays untargetable until its ceremony completes; a closed arena admits only
    # its own fighters.
    return seen and not final_locked(int(e.group)) and arena_allows(e)
func damage_multiplier(a: Dictionary,b: Dictionary) -> float:
    var n=1.0
    if a.id=="player":
        n+=bonus("boss_damage" if sim.catalog.groups[int(b.group)].boss else "normal_damage")
        # Change 83: the enraged Green Alien's +30% defense (damage taken / 1.3).
        n*=damage_taken_factor(b)
    elif b.id=="player":
        n*=1-bonus("guard")- (bonus("boss_guard") if sim.catalog.groups[int(a.group)].boss else 0.0)
        # Change 54 Crowd Guard: -4% per normal attacker beyond the first, at most -20%.
        if bonus("crowd_guard")>0 and not sim.catalog.groups[int(a.group)].boss:n*=1-minf(CROWD_GUARD_MAX,bonus("crowd_guard")*maxf(0,normal_attackers()-1))
    if float(a.get("focus_time",0))>0:n*=1+float(a.get("focus_power",.15))
    return maxf(.1,n)
# ---------------------------------------------------------------- Change 54 card effects
const CROWD_GUARD_MAX:=.2
const SECOND_WIND_BELOW:=.3
const SECOND_WIND_COOLDOWN:=90.0
const CLEAVE_RADIUS:=32.0
const LAST_STAND_BELOW:=.25
const BOSS_BREAKER_TELEGRAPH:=.3
## Living normal enemies (no summoned helper) currently attacking the player.
func normal_attackers() -> int:
    var n:=0
    for e in sim.state.enemies:
        if float(e.hp)>0 and bool(e.aggro) and not bool(e.get("returning",false)) and not sim.is_helper(e) and not sim.catalog.groups[int(e.group)].boss:n+=1
    return n
## Second Wind: called after the player loses HP to an enemy. Heals once when HP first drops below 30%,
## then waits 90 s of active time (player.second_wind, a run-transient actor timer).
func after_player_hit() -> void:
    var p: Dictionary=sim.state.player
    if bonus("second_wind")<=0 or float(p.hp)<=0 or float(p.get("second_wind",0))>0:return
    var maxhp: float=sim.stats().hp
    if float(p.hp)>=maxhp*SECOND_WIND_BELOW:return
    var gain:=minf(maxhp*bonus("second_wind"),maxhp-float(p.hp))
    p.hp=float(p.hp)+gain;p.second_wind=SECOND_WIND_COOLDOWN
    sim.feedback.emit("player",gain,true)
## Last Stand: extra attack speed below 25% HP.
func last_stand_speed() -> float:
    if bonus("last_stand")<=0 or float(sim.state.player.hp)>=sim.stats().hp*LAST_STAND_BELOW:return 0.0
    return bonus("last_stand")
func telegraph_time(a: Dictionary) -> float:
    var t: float=float(sim.abilities.telegraph)
    if a.id!="player" and sim.catalog.groups[int(a.group)].boss and bonus("boss_breaker")>0:t+=BOSS_BREAKER_TELEGRAPH
    return t
func upgrade_cost(id: String,g: int) -> int:
    var d: Dictionary=sim.catalog.upgrades[id]
    var n: int=sim.level(id,g)
    var st=1
    if d.scope in ["type","normal_type","boss_type"]:st=int(sim.catalog.groups[g].stage)
    elif d.scope=="stage":st=g
    elif d.scope=="camp":st=g/10
    var factor=map_cost_factor(st) if d.currency=="coins" else 1+.25*(st-1)
    # Change 13: a flat price is the same on every map (Auto Evolution: 2,000 gems per type).
    if d.get("flat",false):factor=1.0
    var price=float(d.base)*pow(float(d.growth),n)
    if d.has("prices"):price=float(d.prices[mini(n,d.prices.size()-1)])
    # Linear schedules: every purchase costs `step` more than the one before (slots).
    if d.has("step"):price=float(d.base)+float(d.step)*n
    # Sequence schedules (Map Details): one rising price per purchase on any stage this run, with a
    # per-stage floor so a late stage is never trivially cheap.
    if d.get("sequence",false):
        factor=1.0
        price=maxf(float(d.base)*pow(float(d.growth),sequence_count(id)),float(d.get("floor",0))*map_cost_factor(st))
    price*=cheap_first_factor(id,n)
    # Change 78: a boss type's Auto-Collect and gear Auto-Merge unlocks cost x0.25 (catalog boss_price_factor).
    if d.has("boss_price_factor") and g>=0 and g<sim.catalog.groups.size() and d.scope in ["type","boss_type"] and bool(sim.catalog.groups[g].boss):price*=float(d.boss_price_factor)
    return maxi(1,ceili(price*factor*(1-bonus("coin_discount") if d.currency=="coins" else 1)))
## Change 56 (approved cheap first levels): each enemy type's Coin Amount, Enemy XP and Loot Chance start at
## x0.25 so a newly farmed type is quick to start investing in. Change 71: the discount used to end in one step
## after level 5 (a x5.4 jump: Enemy XP on Winter II went 38 -> 209 Coins). Now the first cheap_first_levels
## purchases keep the full discount and it fades geometrically until cheap_taper_until, where the normal
## price applies, so no purchase costs more than about x1.8 the one before. Later levels are unchanged.
func cheap_first_factor(id: String,n: int) -> float:
    var d: Dictionary=sim.catalog.upgrades[id]
    var economy: Dictionary=sim.catalog.progression.get("economy",{})
    if d.currency!="coins" or not d.scope in ["type","normal_type"] or not economy.get("cheap_first_upgrades",[]).has(id):return 1.0
    var factor:=float(economy.get("cheap_first_factor",1.0))
    var first:=int(economy.get("cheap_first_levels",0))
    var until:=maxi(first,int(economy.get("cheap_taper_until",first)))
    if n<first:return factor
    if n>=until:return 1.0
    return pow(factor,1.0-float(n-first+1)/float(until-first+1))
func sequence_count(id: String) -> int:
    var total:=0
    for key in sim.state.upgrades:
        if str(key).get_slice(":",0)==id:total+=int(sim.state.upgrades[key])
    return total
## Change 14: the type whose Farm button the guide points at right after the profile's first Focused
## Farming purchase (-1 when none). Session only, never saved: "focus_unlocked" in tutorial.seen is
## written at that purchase, so a reload, Prestige or a later purchase never shows it again.
var focus_hint: int=-1
## Change 65: the nearest discovered enemy type of the current map with a found farming spot (-1: none).
func farm_hint_group() -> int:
    var best:=-1
    var best_d:=INF
    var at: Vector2=sim.position_of(sim.state.player)
    for g in stage().groups:
        g=int(g)
        if not discovered(g) or sim.catalog.groups[g].boss:continue
        var found:=false
        for v in variants(g):
            if spot_discovered(g,int(v)):found=true;break
        if not found:continue
        var d: float=at.distance_to(spot(g,2))
        if d<best_d:best_d=d;best=g
    return best
func upgrade_bought(id: String,g: int) -> void:
    if id in ["map_detail","reveal_radius","camp_radius"]:reveal()
    if id=="mission_slots":refresh_missions()
    if id=="focus" and not sim.state.tutorial.seen.has("focus_unlocked"):
        sim.state.tutorial.seen.append("focus_unlocked")
        # The confirmation shows in every mode; the pointer is Guided only (Change 25). Change 65: the
        # purchase is global, so the hint names the nearest enemy type on this map whose farming spot the
        # player has found (the next actionable Farm), or none (the confirmation alone).
        if str(sim.state.tutorial.mode)=="guided":focus_hint=farm_hint_group()
        sim.notice.emit("focus_unlocked",str(g))
    progress("upgrade",id,1)
func equip_skill(id: String,slot: int=-1) -> bool:
    if not sim.action_lock_reason().is_empty() or not sim.catalog.items.has(id) or sim.catalog.items[id].kind!="skill" or sim.quantity(id)<1:return false
    var list: Array=sim.state.skills
    var old_slot=list.find(id)
    if slot<0 and old_slot>=0:list[old_slot]="";sim.touch();return true
    var family: String=sim.catalog.items[id].skill
    var family_slot=-1
    for i in range(list.size()):
        if list[i]!="" and sim.catalog.items[list[i]].skill==family:family_slot=i
    var cap=1+sim.level("skill_slots")
    if slot<0:
        if family_slot>=0:slot=family_slot
        else:
            for i in range(cap):
                if list[i]=="":slot=i;break
    if slot<0 or slot>=cap:return sim.fail("SKILL_SLOTS_FULL")
    if family_slot>=0:list[family_slot]=""
    list[slot]=id;progress("equip",id,1);sim.touch();return true
func cast(slot: int) -> bool:
    if not skill_cast_block_reason(slot).is_empty():return false
    var id: String=sim.state.skills[slot]
    var key: String=sim.catalog.items[id].skill
    if not apply_skill(sim.state.player,key,sim.skill_power(id)):return false
    sim.state.skill_cooldowns[key]=sim.player_upgrade_value("cooldown_"+key)
    progress("cast",key,1);sim.touch();return true
## Read-only availability for manual buttons and automation. Poll while actors move: movement does
## not emit sim.changed every frame. Empty means available; querying never acquires a target.
func skill_cast_block_reason(slot: int) -> String:
    var lock: String=sim.action_lock_reason()
    if not lock.is_empty():return lock
    if slot<0 or slot>=mini(sim.state.skills.size(),1+sim.level("skill_slots")):return "SKILL_SLOT_UNAVAILABLE"
    var id: String=sim.state.skills[slot]
    if id.is_empty() or sim.quantity(id)<1:return "SKILL_EMPTY"
    if sim.state.player.hp<=0:return "PLAYER_DEAD"
    var key: String=sim.catalog.items[id].skill
    if float(sim.state.skill_cooldowns.get(key,0))>0:return "SKILL_COOLDOWN"
    return player_skill_block_reason(key)

func skill_activation_distance() -> float:
    return maxf(0,float(sim.catalog.progression.change17.skill_activation_distance))

## Preserve locked-target priority and farming filters, but only select eligible nearby actors (with a
## Farming Focus, an enemy attacking the player is the fallback, as for auto-attack: sim.auto_target).
## This activation radius does not change Frost/Fire damage areas or enemy skill reach.
func skill_activation_target() -> Dictionary:
    var origin: Vector2=sim.position_of(sim.state.player)
    var radius_sq:=pow(skill_activation_distance(),2)
    var locked: Dictionary=sim._find_actor(sim.locked_target)
    if not locked.is_empty() and locked.id!="player" and locked.hp>0 and target_allowed(locked) and origin.distance_squared_to(sim.position_of(locked))<=radius_sq:return locked
    # Change 41: the same priority as auto-attack (focused type, then an attacker, never a bystander).
    return sim.auto_target(sqrt(radius_sq)+.001,sight())

func player_skill_block_reason(key: String) -> String:
    if not sim.catalog.skills.has(key):return "SKILL_UNKNOWN"
    if sim.state.player.hp<=0:return "PLAYER_DEAD"
    if key=="heal":return "" if sim.state.player.hp<actor_max_hp(sim.state.player) else "HEALTH_FULL"
    if skill_activation_target().is_empty():return "SKILL_TARGET_OUT_OF_RANGE"
    if not in_combat():return "NOT_IN_COMBAT"
    return ""
## Enemy Heal is cast below this share of maximum HP (player Heal needs any missing HP), except the final
## boss, which keeps Heal for its second half and then puts it first (Change 13, heal_threshold).
const HEAL_BELOW_HP:=.8
const SELF_SKILLS:=["heal","focus"]
func heal_threshold(a: Dictionary) -> float:
    if a.id=="player":return 1.0
    if a.id!="player" and bool(sim.catalog.groups[int(a.group)].final):return float(sim.abilities.final_heal_below)
    return HEAL_BELOW_HP
## Skill geometry and side effects, shared by the casts and the skill descriptions (Change 16).
const FROST_RADIUS:=96.0
const FIRE_RADIUS:=64.0
const FROST_SLOW_SECONDS:=3.0
const FOCUS_SECONDS:=5.0
## Reach of an attack skill from its caster to its target (Frost is centred on the caster).
func skill_range(key: String) -> float:
    return FROST_RADIUS if key=="frost" else (80.0 if key=="strike" else 120.0)
func actor_max_hp(a: Dictionary) -> float:
    return sim.stats().hp if a.id=="player" else float(sim.enemy_definition(int(a.group),int(a.get("variant",2))).hp)
## Whether a self-cast skill can do anything now (Change 12). A boss checks this before telegraphing,
## so its Heal effect, sound and number only ever accompany HP actually restored.
func skill_ready(a: Dictionary,key: String) -> bool:
    if a.id=="player":return player_skill_block_reason(key).is_empty()
    if a.hp<=0:return false
    if key=="heal":return a.hp<actor_max_hp(a)*heal_threshold(a)
    if key=="focus":return in_combat()
    return true
func apply_skill(a: Dictionary,key: String,power: float,aim: Vector2=Vector2.INF) -> bool:
    var player: bool=a.id=="player"
    if player and not player_skill_block_reason(key).is_empty():return false
    var target: Dictionary=(skill_activation_target() if key not in SELF_SKILLS else {}) if player else sim.state.player
    var pos: Vector2=sim.position_of(a)
    sim.cast_target=""
    if key=="heal":
        if not skill_ready(a,key):return false
        var maxhp:=actor_max_hp(a)
        var fraction: float=float(sim.abilities.final_heal_fraction) if not player and bool(sim.catalog.groups[int(a.group)].final) else float(sim.catalog.skills.heal.enemy_hp_fraction)
        # Change 83: the enraged Green Alien heals +20% (each Heal, once).
        if not player and enraged(a):fraction*=RAGE_HEAL
        var gain=minf(minf(power,maxhp*float(sim.catalog.skills.heal.player_hp_cap)) if player else maxhp*fraction,maxhp-a.hp)
        # Change 54 Boss Breaker: boss heals restore 25% less.
        if not player and sim.catalog.groups[int(a.group)].boss:gain*=1-bonus("boss_breaker")
        if gain<=0:return false
        a.hp+=gain;sim.feedback.emit(a.id,gain,true)
    elif key=="focus":
        if not in_combat():return false
        apply_timed_status(a,"focus_time",FOCUS_SECONDS);a.focus_power=power
    else:
        if target.is_empty() or target.hp<=0:return false
        if pos.distance_to(sim.position_of(target))>skill_range(key):return false
        var center: Vector2=pos if key=="frost" else (sim.position_of(target) if aim==Vector2.INF else aim)
        var targets: Array=sim.state.enemies if player else [sim.state.player]
        var base: float=sim.stats().damage if player else sim.enemy_definition(a.group,a.variant).damage
        var view:=sight() if player else null
        for b in targets:
            if b.hp<=0 or (player and not target_allowed(b,view)):continue
            var hits: bool=b.id==target.id
            if key in ["fire","frost"]:hits=sim.position_of(b).distance_to(center)<=(FROST_RADIUS if key=="frost" else FIRE_RADIUS)
            if not hits:continue
            var defense: float=sim.stats().defense if not player else sim.enemy_definition(b.group,b.variant).defense
            var multiplier:=effective_skill_multiplier(a,b,key,power)
            var damage=maxf(1,base*multiplier*100/(100+defense))
            if player and key=="fire":damage=minf(damage,base*float(sim.catalog.progression.change17.fire_effective_cap))
            begin_encounter(b if player else a)
            sim.state.player.quiet=0
            b.hp=maxf(0,b.hp-damage);b.quiet=0;b.aggro=true;b.hurt=.16
            if b.id=="player":after_player_hit()
            if key=="frost":apply_timed_status(b,"slow",FROST_SLOW_SECONDS)
            if key=="lightning" and player:
                apply_timed_status(b,"attack_slow",float(sim.catalog.progression.change17.lightning_duration))
                b.attack_rate=float(sim.catalog.progression.change17.lightning_attack_rate)
            sim.feedback.emit(b.id,damage,false)
            if b.hp<=0:sim._kill(b,a)
        # Change 14: an area effect plays at its centre (Fire's aim, Frost around the caster); a
        # single-target strike (Lightning, Strike) plays on the actor it hit, wherever a boss aimed.
        pos=center if key in ["fire","frost"] else sim.position_of(target)
        sim.cast_target=str(target.id)
    sim.spell_cast.emit(a.id,key,pos)
    return true
func step(dt: float) -> void:
    arena_notice_clock=maxf(0.0,arena_notice_clock-dt)
    for key in sim.state.skill_cooldowns:sim.state.skill_cooldowns[key]=maxf(0,sim.state.skill_cooldowns[key]-dt)
    sim.state.player.second_wind=maxf(0,float(sim.state.player.get("second_wind",0))-dt)
    for a in [sim.state.player]+sim.state.enemies:
        a.focus_time=maxf(0,float(a.get("focus_time",0))-dt);a.slow=maxf(0,float(a.get("slow",0))-dt)
        if a.id=="player" or a.hp<=0:continue
        var d: Dictionary=sim.enemy_definition(a.group,a.variant)
        if d.final and not sim.state.final_discovered and sim.position_of(a).distance_to(sim.position_of(sim.state.player))<160:
            discover_final()
        # Change 82/83: with all 13 keys, the first approach asks the danger question, then plays the ceremony.
        if d.final:
            _rearm_warning(a)
            final_attempt(a)
        if d.final and final_locked(int(a.group)):
            a.aggro=false;a.windup=0;continue
        # Change 83: Rage Mode (after damage, never on a lethal blow: a dead boss is skipped above).
        if d.final:_rage_check(a)
        # Change 13: summoners (EnemyAbilityRules) call helpers on their own timer; helpers never summon.
        var rule: SummonRule=null if sim.is_helper(a) else sim.abilities.summon_rule(str(d.id))
        if not a.aggro:
            a.telegraph=false
            a.summon_cast=0.0
            if rule!=null:a.summon_cd=rule.first_delay
        a.skill_timer=maxf(0,float(a.get("skill_timer",0))-dt)
        var cds: Dictionary=a.get("skill_cds",{})
        for key in cds:cds[key]=maxf(0,float(cds[key])-dt)
        if not a.aggro:continue
        if rule!=null and _summon_step(a,d,rule,dt):continue
        if d.final:
            _final_turn(a)
            continue
        if d.skills.is_empty() or a.skill_timer>0:continue
        if a.get("telegraph",false):
            # A boss's announced skill resolves at the end of its telegraph. A dodged one (the player
            # left its reach) costs a short pause, never the skill's cooldown.
            var key: String=str(a.get("pending",""))
            a.telegraph=false;a.pending=""
            if key!="" and apply_skill(a,key,float(sim.catalog.skills[key].power),Vector2(a.get("aim_x",sim.state.player.x),a.get("aim_y",sim.state.player.y))):
                a.skill_timer=enemy_skill_cooldown(d,key);a.skill_index=int(a.get("skill_index",0))+1
            else:a.skill_timer=DODGED_SKILL_PAUSE
            continue
        # Change 78: the first eligible skill of the rotation acts as soon as the skill timer is ready.
        # A skill that cannot act now (Heal above its threshold, Focus out of combat, an attack skill
        # out of reach) is passed over without consuming anything and checked again next frame, so
        # it never hands the turn to a normal attack (enemy_skill_first holds those back).
        var index:=enemy_skill_choice(a,d)
        if index<0:continue
        a.skill_index=index
        var key: String=d.skills[index]
        if d.boss:
            _begin_telegraph(a,key)
        elif apply_skill(a,key,float(sim.catalog.skills[key].power)):
            a.skill_timer=enemy_skill_cooldown(d,key);a.skill_index=index+1
    reveal_clock+=dt;objective_clock+=dt
    evolve_clock+=dt
    if reveal_clock>=fog_rules.update_interval:reveal_clock=0;reveal();camp_supply_step()
    if objective_clock>=1:
        objective_clock=0;refresh_missions();evaluate();onboarding.evaluate();mastery.evaluate();completion.evaluate();check_follow_mission();sim.touch()
## Seconds before an enemy of this type casts again after a successful skill: a per-type override in
## EnemyAbilityRules, else the boss standard cooldown (Change 62: 10 s), else the catalog skill's.
## Change 81: the boss keys (13 distinct other bosses defeated after the discovery) open the Green Alien. Until
## then the final boss is sealed: it never fights, aggroes, takes a target or is farmed.
const FINAL_KEYS:=13
func final_sealed(g: int) -> bool:
    return g>=0 and g<sim.catalog.groups.size() and bool(sim.catalog.groups[g].final) and sim.state.keys.size()<FINAL_KEYS
## The one discovery transition (coming near the Green Alien, or tapping it): saved at once, announced once per
## profile (final_discovered is kept by Prestige; the introduction's acknowledgement is tutorial.seen "final_intro").
func discover_final() -> void:
    if bool(sim.state.final_discovered):return
    sim.state.final_discovered=true;sim.touch();SaveService.save_now();sim.event.emit("FINAL_DISCOVERED")
## Change 81: the persistent final-boss objective: "" before the discovery and after the victory, "keys" while
## keys are missing, "ready" with all 13 until the Green Alien is defeated.
func final_objective() -> String:
    if not bool(sim.state.final_discovered) or bool(sim.state.final_complete) or final_defeated():return ""
    return "ready" if sim.state.keys.size()>=FINAL_KEYS else "keys"
func final_defeated() -> bool:
    for g in range(sim.catalog.groups.size()):
        if bool(sim.catalog.groups[g].final):return int(sim.state.group_kills[g])>0
    return false

# ---------------------------------------------------------------- Green Alien ceremony and arena (Change 82)
# Two distinct states. Presentation and encounter rules only: no HP, damage, skill, reward or key value changes.
# - Ceremony (once per profile): state.final_unsealed (saved; kept by Prestige; cleared by Hard Reset). With 13 keys
#   and final_unsealed false the Green Alien stays locked (final_locked: no aggro, target or damage), and the first
#   approach within CEREMONY_RADIUS (or a tap on it) starts the cinematic. ceremony_time is transient: while it runs
#   sim.step freezes the world (no AI, damage, regen or clocks), so cinematic timing cannot cause combat. Only when
#   it reaches CEREMONY_SECONDS is final_unsealed set and saved, and the boss starts its encounter (aggro). A pause or
#   background pauses it; a reload, Hard Reset or Prestige before the end drops it, and the next approach replays it.
#   Keys are never consumed or re-awarded (state.keys stays authoritative).
# - Arena (per attempt, transient, never saved): while the unsealed Green Alien is alive and engaged (aggro, not
#   returning) and the player is alive on its map, a circle of ARENA_RADIUS closes around its home as soon as the
#   player stands inside it. A player engaging from just outside (a ranged skill) gets the circle slid toward them
#   (at most ARENA_MAX_SHIFT) so it closes with them inside, never through them. Inside, the player, the Green Alien and its summoned helpers are kept in
#   by _move (sim); every other enemy is kept out and cannot be targeted across it. Travel, Teleport, map changes,
#   Prestige and Auto Farm on another type are refused (ARENA_SEALED). It opens the moment its condition fails: the
#   boss dies (victory), the player dies (every enemy drops aggro), the boss resets, or the profile is replaced.
#   A reload rebuilds it from the saved actors (the boss's saved aggro), so it can never strand a player.
# Geometry: Spring II (2112 x 2112) puts the Green Alien's home at (1032, 253) in a natural clearing: the nearest
# solid (a tree trunk, r 6) is 142 from it. Radius 118 around home is that clearing with 16+ px to spare, so the
# arena holds no solid scenery, the barrier never crosses a tree and the map edge (y 30) stays outside it. 236
# across holds melee reach (28), the boss's skill ranges (Strike 80, Fire / Focus 120 across it) and its helpers'
# summon ring (40). Shifted or not, the boss stays within 100 + 108 < 220 of home, so its leash never resets a
# fight inside the arena.
const CEREMONY_SECONDS:=5.6
const CEREMONY_UNSEAL_AT:=4.1
## Inside the arena's close margin (118 - 12), so the fight that follows the ceremony is always sealed.
const CEREMONY_RADIUS:=88.0
const ARENA_RADIUS:=118.0
## How far the circle may slide from the boss's home toward a player engaging from outside it.
const ARENA_MAX_SHIFT:=100.0
## Actor centres stay this far inside (members) or outside (others) the barrier line.
const ARENA_CLEARANCE:=10.0
## The player must be this far inside the circle before it closes (never closes through the player).
const ARENA_CLOSE_MARGIN:=12.0
const ARENA_NOTICE_SECONDS:=4.0
var ceremony_time:=-1.0
var ceremony_boss:=""
var arena: Dictionary={}
var arena_notice_clock:=0.0
## Last point where the player pushed against the barrier (world) and the playtime clock at that moment.
var arena_bump: Vector2=Vector2.INF
var arena_bump_clock:=-INF

func final_unsealed() -> bool:return bool(sim.state.get("final_unsealed",false))
## Change 83: the new encounter introduction (danger warning accepted, then the full key ceremony) was completed
## on this profile. Separate from the Change 82 final_unsealed and from any past victory: an older save that had
## unsealed or even defeated the Green Alien still sees the warning and the ceremony once.
func final_experience() -> bool:return bool(sim.state.get("final_experience",false))
func final_warning_ok() -> bool:return bool(sim.state.get("final_warning_ok",false))
## The Green Alien may fight: unsealed and the Change 83 introduction completed.
func final_ready() -> bool:return final_unsealed() and final_experience()
## The Green Alien cannot fight yet: missing keys (sealed), the introduction (warning and ceremony) not completed,
## or the warning or the ceremony on screen now.
func final_locked(g: int) -> bool:
    return g>=0 and g<sim.catalog.groups.size() and bool(sim.catalog.groups[g].final) and (sim.state.keys.size()<FINAL_KEYS or not final_ready() or ceremony_active() or warning_pending!="")
func ceremony_active() -> bool:return ceremony_time>=0.0
func ceremony_progress() -> float:return clampf(ceremony_time/CEREMONY_SECONDS,0.0,1.0) if ceremony_active() else 0.0
## True when this living Green Alien should start its introduction now (13 keys, introduction not completed, player
## alive and close). The introduction is the danger warning (until accepted once) and then the ceremony.
func ceremony_due(a: Dictionary,radius:=CEREMONY_RADIUS) -> bool:
    if ceremony_active() or warning_pending!="" or final_experience() or sim.state.keys.size()<FINAL_KEYS:return false
    if float(a.hp)<=0 or float(sim.state.player.hp)<=0 or not sim.state.get("prestige_batch",{}).is_empty():return false
    return sim.position_of(a).distance_to(sim.position_of(sim.state.player))<=radius and can_see(sim.position_of(a))

# ---------------------------------------------------------------- Change 83: danger warning before the encounter
# The first valid attempt to engage (walking or Auto Farm within CEREMONY_RADIUS, or a tap on it there) asks first,
# before any key visual, arena, combat or music: warning_pending holds the boss id while the panel is open (the UI
# holds the world). "Yes" saves final_warning_ok and starts the full ceremony; "No" closes it with nothing changed,
# and the approach asks again only after the player has walked WARNING_REARM beyond the radius (or taps the boss
# again), never every frame. A warning that was not answered (reload, Prestige, Hard Reset) counts as not accepted.
# Once accepted, an interrupted ceremony replays on the next approach without asking again.
const WARNING_REARM:=60.0
var warning_pending:=""
var warning_armed:=true
## The approach (or a tap) reached a Green Alien whose introduction is due: ask, or play the ceremony once accepted.
## explicit: a tap, which asks again even right after a "No".
func final_attempt(a: Dictionary,explicit:=false) -> bool:
    if not ceremony_due(a):return false
    if final_warning_ok():return begin_ceremony(a)
    if not warning_armed and not explicit:return false
    discover_final()
    reveal()
    warning_pending=str(a.id)
    sim.movement=Vector2.ZERO;sim.clear_target();sim.focus_walk_time=0.0
    sim.state.player.windup=0.0;sim.state.player.target=""
    a.aggro=false;a.windup=0.0;a.telegraph=false
    sim.final_warning.emit("ask")
    return true
## Yes, fight: saved at once (never asked again on this profile), then the full 13-key ceremony.
func accept_final_warning() -> bool:
    if warning_pending=="":return false
    var boss: Dictionary=sim._find_actor(warning_pending)
    warning_pending=""
    sim.state.final_warning_ok=true
    sim.touch();SaveService.save_now()
    sim.final_warning.emit("accepted")
    if boss.is_empty() or float(boss.hp)<=0 or float(sim.state.player.hp)<=0:return false
    return begin_ceremony(boss)
## No, not yet: the encounter is cancelled (arena open, boss disengaged); a Focus on the Green Alien stops so Auto
## Farm does not walk straight back into the question.
func decline_final_warning() -> void:
    if warning_pending=="":return
    var boss: Dictionary=sim._find_actor(warning_pending)
    warning_pending="";warning_armed=false
    if not boss.is_empty():boss.aggro=false;boss.windup=0.0
    if int(sim.state.focus)>=0 and int(sim.state.focus)<sim.catalog.groups.size() and bool(sim.catalog.groups[int(sim.state.focus)].final):sim.stop_focus("")
    sim.touch()
    sim.final_warning.emit("declined")
## Re-arms the warning once the player has walked away from the Green Alien after a "No".
func _rearm_warning(a: Dictionary) -> void:
    if not warning_armed and sim.position_of(a).distance_to(sim.position_of(sim.state.player))>CEREMONY_RADIUS+WARNING_REARM:warning_armed=true

# ---------------------------------------------------------------- Change 83: Green Alien Rage Mode
# The first time the living, fighting Green Alien is at or below RAGE_BELOW of its maximum HP after taking damage
# (checked in step, so a lethal blow never enrages it), it enrages until it is defeated: attacks start 1.5x as often
# (interval / RAGE_ATTACK_SPEED), it takes RAGE_DAMAGE_TAKEN of the damage (every enemy's Defense is 0, so the
# +30% defense is the game's own damage-mitigation multiplier, as Guard is for the player), each Heal restores
# RAGE_HEAL x its amount, and on entry it heals once at once (that Heal also starts the Heal cooldown, so the next
# one follows the normal rules). The latch (actor.rage) is saved with the actor: it survives a reload while the fight
# goes on, and is dropped when this boss dies (the next one is normal) or, since Change 86, when the player's death
# ends the encounter (simulation._kill), so every new fight starts normal and enrages again at RAGE_BELOW.
const RAGE_BELOW:=.2
const RAGE_ATTACK_SPEED:=1.5
const RAGE_DAMAGE_TAKEN:=1.0/1.3
const RAGE_HEAL:=1.2
func enraged(a: Dictionary) -> bool:
    return not a.is_empty() and a.id!="player" and bool(a.get("rage",false)) and float(a.hp)>0
## Attack-rate factor for an enemy's basic attacks (1.5 while enraged).
func attack_speed_factor(a: Dictionary) -> float:
    return RAGE_ATTACK_SPEED if enraged(a) else 1.0
## Damage-taken factor for an actor (the enraged Green Alien's mitigation).
func damage_taken_factor(b: Dictionary) -> float:
    return RAGE_DAMAGE_TAKEN if enraged(b) else 1.0
## Change 86: the Green Alien's id when this killer is that boss or a helper it summoned, else "".
func final_killer(killer: Dictionary) -> String:
    if killer.is_empty() or str(killer.get("id",""))=="player":return ""
    var boss: Dictionary=sim._find_actor(str(killer.get("summoner",""))) if sim.is_helper(killer) else killer
    if boss.is_empty() or not bool(sim.catalog.groups[int(boss.group)].final):return ""
    return str(boss.id)
## Change 88: the Green Alien starts every fresh encounter at 100% of its current maximum HP. Its HP was only ever
## restored on respawn or by the shared out-of-combat regeneration (10%/s after 5 s without a hit), so:
## - after the player's death it walked home with the damage of the lost attempt, and a quick return (a nearby camp,
##   a short respawn) met it part-healed (often near 80%);
## - while locked (warning or ceremony owed) the loop skipped regeneration, and the ceremony's end reset `quiet`, so a
##   stale absolute HP from an older save (a smaller earlier maximum, or damage from before an update) stayed on
##   screen into the new fight.
## This puts an idle Green Alien to full HP. keep_engaged: an actor saved mid-fight (aggro, not returning) keeps its
## damage (a reload during a fight is legitimate); without it every living Green Alien here is idle (a map
## re-entered, an inactive map's world). HP above the current maximum is always capped. Rage and skill state go with
## the encounter.
func fresh_final_hp(actors: Array,keep_engaged: bool) -> void:
    for e in actors:
        if not e is Dictionary or sim.is_helper(e) or float(e.get("hp",0))<=0:continue
        var g:=int(e.get("group",-1))
        if g<0 or g>=sim.catalog.groups.size() or not bool(sim.catalog.groups[g].final):continue
        var maxhp:=actor_max_hp(e)
        if keep_engaged and bool(e.get("aggro",false)) and not bool(e.get("returning",false)):
            e.hp=minf(float(e.hp),maxhp)
            continue
        if float(e.hp)!=maxhp:e.hp=maxhp
        e.erase("rage")
## Change 88: the player's death ended the encounter: the Green Alien (alive) is back to full HP at once (not by
## regeneration), its skills and timers reset with the approved Rage reset (simulation._kill).
func reset_final_after_death() -> void:
    for e in sim.state.enemies:
        if sim.is_helper(e) or float(e.hp)<=0 or not bool(sim.catalog.groups[int(e.group)].final):continue
        e.hp=actor_max_hp(e)
        e.quiet=0.0;e.hurt=0.0
        e.erase("rage")
        reset_enemy_skills(e)

func _rage_check(a: Dictionary) -> void:
    if bool(a.get("rage",false)) or not bool(a.aggro) or float(a.hp)<=0 or sim.is_helper(a):return
    var maxhp:=actor_max_hp(a)
    if float(a.hp)>maxhp*RAGE_BELOW:return
    a.rage=true
    # The one immediate Heal (no telegraph), with the enraged +20%.
    var gain:=minf(maxhp*float(sim.abilities.final_heal_fraction)*RAGE_HEAL*(1.0-bonus("boss_breaker")),maxhp-float(a.hp))
    if gain>0:
        a.hp=float(a.hp)+gain
        sim.feedback.emit(a.id,gain,true)
        sim.spell_cast.emit(a.id,"heal",sim.position_of(a))
    if not a.has("skill_cds"):a.skill_cds={}
    a.skill_cds["heal"]=enemy_skill_cooldown(sim.catalog.groups[int(a.group)],"heal")
    sim.touch()
    sim.final_rage.emit(str(a.id))

# ---------------------------------------------------------------- Change 83: the first victory and the ending
# Four separate saved facts: boss defeated (group_kills), final_celebrated (the first 10 s celebration played to its
# end), final_ending_seen (the ending message acknowledged by a button) and 100% Game Completion (completion.gd).
# A Green Alien victory:
# - nothing celebrated yet: the CELEBRATION_SECONDS celebration plays with the world frozen (like the ceremony;
#   pause and background pause it), then ending_due asks the UI for the ending panel, which holds the world;
# - celebrated but the message never acknowledged (closed app, reload): after ENDING_DELAY of play the panel shows;
# - otherwise: nothing blocks (the dance floor is presentation only).
# The boss respawn clock waits while the celebration runs or the panel is due, so the floor and the message are
# never cut off by its return. A reload drops an unfinished celebration and an unshown panel without saving them;
# the next victory delivers them.
const CELEBRATION_SECONDS:=10.0
const ENDING_DELAY:=3.0
var celebration_time:=-1.0
var ending_due:=false
var ending_wait:=-1.0
func celebration_active() -> bool:return celebration_time>=0.0
## Change 88: the ending panel is on screen now (game_ui keeps this in step with the dialog every frame).
var ending_showing:=false
## Change 88: the living victory spectacle: the forced celebration or the open ending panel. The world stays held
## (no controls, combat, AI or encounter progress) while presentation keeps moving: the hero dances, the floor and
## its effects run, the music plays, the camera frames the floor, and the Green Alien's respawn countdown is
## paused (final_respawn_held) and hidden.
func final_spectacle() -> bool:return celebration_active() or ending_showing
func final_celebrated() -> bool:return bool(sim.state.get("final_celebrated",false))
func final_ending_seen() -> bool:return bool(sim.state.get("final_ending_seen",false))
## The final boss's respawn clock is held (the celebration or the ending message is still owed this victory).
func final_respawn_held() -> bool:return celebration_active() or ending_due or ending_wait>=0.0 or ending_showing
## Called once per Green Alien defeat, after its rewards. Returns "first", "deferred" or "repeat".
func final_victory() -> String:
    if final_ending_seen():
        sim.final_victory.emit("repeat")
        return "repeat"
    if not final_celebrated():
        celebration_time=0.0
        sim.movement=Vector2.ZERO;sim.clear_target();sim.focus_walk_time=0.0
        sim.final_victory.emit("first")
        return "first"
    ending_wait=0.0
    sim.final_victory.emit("deferred")
    return "deferred"
## Advances the first celebration while the world is frozen (sim.step). Returns true while it runs.
func celebration_step(dt: float) -> bool:
    if not celebration_active():return false
    celebration_time+=dt
    if celebration_time<CELEBRATION_SECONDS:return true
    celebration_time=-1.0
    sim.state.final_celebrated=true
    sim.touch();SaveService.save_now()
    ending_due=true
    sim.final_victory.emit("celebrated")
    return false
## The deferred message's short wait (live play, not frozen).
func ending_step(dt: float) -> void:
    if ending_wait<0.0:return
    ending_wait+=dt
    if ending_wait>=ENDING_DELAY:ending_wait=-1.0;ending_due=true
## The ending panel was answered (Continue Playing or Back; since Change 88 the links do not count): never shown
## again on this profile.
func acknowledge_ending() -> void:
    if final_ending_seen() and not ending_due:return
    ending_due=false;ending_wait=-1.0;ending_showing=false
    sim.state.final_ending_seen=true
    sim.touch();SaveService.save_now()
    sim.final_victory.emit("acknowledged")

## Change 83: the outfits the celebration floor can show: every outfit an enemy drops (outfits never evolve), in
## catalog order. Copies, merge levels and retired/legacy ids never add to it.
var _floor_outfits: Array=[]
func floor_outfits() -> Array:
    if _floor_outfits.is_empty():
        for g in sim.catalog.groups:
            for id in g.loot:
                if sim.catalog.items.has(id) and str(sim.catalog.items[id].kind)=="outfit" and not _floor_outfits.has(id):_floor_outfits.append(id)
    return _floor_outfits
## The obtainable outfits this profile owns now (in the inventory or worn), one entry per outfit.
func owned_floor_outfits() -> Array:
    var out: Array=[]
    for id in floor_outfits():
        if str(sim.state.get("outfit",""))==id or float(sim.state.items.get(id,{}).get("qty",0))>0:out.append(id)
    return out
## Where the dance floor stands: the Green Alien's home, or INF when it is not on this map.
func final_home() -> Vector2:
    for e in sim.state.enemies:
        if bool(sim.catalog.groups[int(e.group)].final) and not sim.is_helper(e):return Vector2(float(e.home_x),float(e.home_y))
    return Vector2.INF
## The floor shows on the Green Alien's map from its defeat until it respawns (state-derived: a reload or a return to
## the map shows it again; a respawn removes it).
func floor_visible() -> bool:
    if not final_defeated():return false
    for e in sim.state.enemies:
        if bool(sim.catalog.groups[int(e.group)].final) and not sim.is_helper(e):return float(e.hp)<=0
    return false

func begin_ceremony(a: Dictionary) -> bool:
    if ceremony_active() or final_experience():return false
    discover_final()
    # The world freezes from here: bring the fog and the boss sighting up to date first.
    reveal()
    ceremony_time=0.0;ceremony_boss=str(a.id)
    sim.movement=Vector2.ZERO;sim.clear_target();sim.focus_walk_time=0.0
    sim.state.player.windup=0.0;sim.state.player.target=""
    a.aggro=false;a.windup=0.0;a.telegraph=false
    sim.final_ceremony.emit("start")
    sim.touch()
    return true
## Drops an unfinished ceremony (reload, Hard Reset, Prestige, the boss gone). Nothing was saved, so the next
## approach replays it.
func cancel_ceremony() -> void:
    if not ceremony_active():return
    ceremony_time=-1.0;ceremony_boss=""
    sim.final_ceremony.emit("cancel")
## Advances the cinematic while the world is frozen (sim.step). Returns true while it runs.
func ceremony_step(dt: float) -> bool:
    if not ceremony_active():return false
    var boss: Dictionary=sim._find_actor(ceremony_boss)
    if boss.is_empty() or float(boss.hp)<=0 or float(sim.state.player.hp)<=0:
        cancel_ceremony()
        return false
    var before:=ceremony_time
    ceremony_time+=dt
    if before<CEREMONY_UNSEAL_AT and ceremony_time>=CEREMONY_UNSEAL_AT:sim.final_ceremony.emit("unseal")
    if ceremony_time<CEREMONY_SECONDS:return true
    # Completion: the durable unlock is saved first, then the encounter starts (the arena closes on the next step).
    ceremony_time=-1.0;ceremony_boss=""
    sim.state.final_unsealed=true
    # Change 83: the new introduction is complete only now (warning accepted earlier, ceremony played through).
    sim.state.final_experience=true
    # Change 88: the fight starts at full HP (the boss could not be hit while locked; any shortfall is stale).
    fresh_final_hp([boss],false)
    boss.aggro=true;boss.returning=false;boss.quiet=0.0
    begin_encounter(boss)
    sim.touch();SaveService.save_now()
    sim.final_ceremony.emit("done")
    return false

func arena_active() -> bool:return not arena.is_empty()
func arena_center() -> Vector2:return arena.get("center",Vector2.INF)
func arena_radius() -> float:return float(arena.get("radius",0.0))
## The arena circle for this Green Alien actor: its home (so a chase never moves it), slid toward a player who
## engaged from outside it so the player is inside the close margin; {} while the player is too far for that.
func arena_geometry(a: Dictionary) -> Dictionary:
    var home:=Vector2(float(a.home_x),float(a.home_y))
    var center:=home
    var player: Vector2=sim.position_of(sim.state.player)
    var reach:=ARENA_RADIUS-ARENA_CLOSE_MARGIN-2.0
    if player.distance_to(home)>reach:
        var shift: float=player.distance_to(home)-reach
        if shift>ARENA_MAX_SHIFT:return {}
        center=home+(player-home).normalized()*shift
    if sim.position_of(a).distance_to(center)>ARENA_RADIUS-ARENA_CLEARANCE:return {}
    return {"center":center,"radius":ARENA_RADIUS,"boss":str(a.id)}
## The living, engaged, unsealed Green Alien on the current map, or {}.
func engaged_final() -> Dictionary:
    if not final_ready() or ceremony_active() or float(sim.state.player.hp)<=0:return {}
    for e in sim.state.enemies:
        if bool(sim.catalog.groups[int(e.group)].final) and not sim.is_helper(e) and float(e.hp)>0 and bool(e.aggro) and not bool(e.get("returning",false)):
            return e
    return {}
## Opens or closes the arena from the encounter state (called every simulation step and after a kill).
func update_arena() -> void:
    var boss:=engaged_final()
    if arena_active():
        if boss.is_empty() or str(boss.id)!=str(arena.boss):
            var fallen: Dictionary=sim._find_actor(str(arena.boss))
            var reason:="death" if float(sim.state.player.hp)<=0 else ("victory" if fallen.is_empty() or float(fallen.hp)<=0 else "reset")
            open_arena(reason)
        return
    if boss.is_empty():return
    var g:=arena_geometry(boss)
    if g.is_empty() or sim.position_of(sim.state.player).distance_to(g.center)>float(g.radius)-ARENA_CLOSE_MARGIN:return
    arena=g
    arena_notice_clock=0.0
    sim.arena_changed.emit(true,"close")
func open_arena(reason: String) -> void:
    if not arena_active():return
    var was: Dictionary=arena
    arena={}
    arena_bump=Vector2.INF
    sim.arena_changed.emit(false,reason)
    if was.has("center"):sim.touch()
## True for actors fenced inside the closed arena: the player, the Green Alien and its helpers.
func arena_member(a: Dictionary) -> bool:
    if a.id=="player" or str(a.id)==str(arena.get("boss","")):return true
    return sim.is_helper(a) and str(a.get("summoner",""))==str(arena.get("boss",""))
## Keeps a movement step on its side of the barrier. A member stops at the line; any other actor is held outside.
## A corrected point inside solid scenery keeps the actor where it was (never pushed into a tree).
func arena_clamp(a: Dictionary,old: Vector2,next: Vector2) -> Vector2:
    if not arena_active():return next
    var c: Vector2=arena.center
    var r: float=arena.radius
    var offset:=next-c
    if arena_member(a):
        var limit:=r-ARENA_CLEARANCE
        if offset.length()<=limit:return next
        var held_at:=c+offset.normalized()*limit
        if a.id=="player":_arena_pushed(c+offset.normalized()*r)
        return old if solid_at(held_at) and old.distance_to(c)<=limit+.01 else held_at
    var outside:=r+ARENA_CLEARANCE
    if offset.length()>=outside:return next
    var dir:=offset.normalized() if offset.length()>.01 else (old-c).normalized()
    if dir==Vector2.ZERO:dir=Vector2.DOWN
    var pushed:=c+dir*outside
    return old if solid_at(pushed) and old.distance_to(c)>=outside-.01 else pushed
## A press against the barrier: a ripple there (presentation) and, at most every ARENA_NOTICE_SECONDS, one notice.
func _arena_pushed(at: Vector2) -> void:
    arena_bump=at
    arena_bump_clock=float(sim.state.get("playtime_total",0.0))
    if sim.movement.length()<=.1:return
    if arena_notice_clock>0:return
    arena_notice_clock=ARENA_NOTICE_SECONDS
    sim.event.emit("ARENA_SEALED")
## Whether an enemy may be targeted from the player's side of a closed arena (members only while it is closed).
func arena_allows(e: Dictionary) -> bool:
    return not arena_active() or arena_member(e)
## Drops every transient encounter state (new profile, Prestige, reload). The saved unlock is untouched.
func reset_final_encounter() -> void:
    cancel_ceremony()
    open_arena("reset")
    arena_notice_clock=0.0
    # Change 83: an unanswered warning is not accepted; an unfinished celebration or unshown ending is owed again.
    warning_pending="";warning_armed=true
    celebration_time=-1.0;ending_due=false;ending_wait=-1.0;ending_showing=false
func enemy_skill_cooldown(d: Dictionary,key: String) -> float:
    return sim.abilities.skill_cooldown(str(d.id),key,float(sim.catalog.skills[key].cooldown),bool(d.get("boss",false)))
## Change 78: pause after a boss's telegraphed skill misses its resolution (the player left its reach).
const DODGED_SKILL_PAUSE:=.5
## Whether an enemy's skill can act on the player right now: its own condition (skill_ready) and, for an
## attack skill, the player alive and within the skill's reach.
func enemy_skill_eligible(a: Dictionary,key: String) -> bool:
    if not sim.catalog.skills.has(key) or not skill_ready(a,key):return false
    if key in SELF_SKILLS:return true
    var p: Dictionary=sim.state.player
    return p.hp>0 and sim.position_of(a).distance_to(sim.position_of(p))<=skill_range(key)
## Change 78: index in the type's skill list of the first eligible skill, scanning the rotation from
## skill_index, or -1 when none can act now.
func enemy_skill_choice(a: Dictionary,d: Dictionary) -> int:
    var n: int=d.skills.size()
    var start:=int(a.get("skill_index",0))
    for i in range(n):
        var index:=(start+i)%n
        if enemy_skill_eligible(a,str(d.skills[index])):return index
    return -1
## Change 78: skills come before normal attacks. True while this enemy's skill is telegraphed or ready to
## act on its next turn; the normal attack loop starts no attack then (one already swinging lands).
func enemy_skill_first(a: Dictionary) -> bool:
    if a.get("telegraph",false):return true
    if a.hp<=0 or not a.aggro or float(a.get("skill_timer",0))>0:return false
    var d: Dictionary=sim.enemy_definition(int(a.group),int(a.get("variant",2)))
    if d.final or d.skills.is_empty():return false
    return enemy_skill_choice(a,d)>=0
## Change 78: an enemy comes back from death (or is created) with a fresh skill turn: no leftover
## cooldown, telegraph or rotation position from its previous life, so its first eligible skill comes
## first again. Before this, the timer only ran while alive and survived death.
func reset_enemy_skills(a: Dictionary) -> void:
    a.skill_timer=0.0;a.skill_index=0;a.skill_cds={}
    a.telegraph=false;a.pending="";a.summon_cast=0.0
## A boss announces a skill for the telegraph time before it resolves. Self effects play once, on
## success (apply_skill); attacks show their aim as a warning.
func _begin_telegraph(a: Dictionary,key: String) -> void:
    a.telegraph=true;a.skill_timer=telegraph_time(a);a.pending=key
    var aim: Vector2=sim.position_of(a) if key in ["heal","focus","frost"] else sim.position_of(sim.state.player)
    a.aim_x=aim.x;a.aim_y=aim.y
    # Change 14: the wind-up is a warning marker; the skill's own effect and sound play once, on the hit.
    if not key in SELF_SKILLS:sim.skill_warning.emit(a.id,key,aim)

## Change 13 summoning. Returns true while the summoner is busy with it this frame (telegraph or the
## call itself), so no skill starts on top of it. A call waits while max_alive helpers live and, for
## the final boss, while Heal has priority. Helpers are created once, at the end of the telegraph.
func _summon_step(a: Dictionary,d: Dictionary,rule: SummonRule,dt: float) -> bool:
    if float(a.get("summon_cast",0))>0:
        a.summon_cast=maxf(0,float(a.summon_cast)-dt)
        if a.summon_cast>0:return true
        var g:=group_id(rule.helper_id)
        var room: int=rule.max_alive-int(sim.helpers_of(str(a.id)).size())
        if g>=0 and room>0:sim.spawn_helpers(a,rule,g,mini(rule.per_cast,room))
        a.summon_cd=rule.cooldown
        a.skill_timer=maxf(float(a.get("skill_timer",0)),1.0)
        return true
    a.summon_cd=maxf(0,float(a.get("summon_cd",rule.first_delay))-dt)
    if a.summon_cd>0 or a.get("telegraph",false):return false
    if sim.helpers_of(str(a.id)).size()>=rule.max_alive:
        a.summon_cd=rule.cooldown
        return false
    if d.final and heal_first(a):return false
    a.summon_cast=telegraph_time(a)
    sim.summon_warning.emit(str(a.id))
    return true

## Final boss (Change 13): Heal first below final_heal_below while it is off cooldown; otherwise a
## random ready skill from the attack pool or Focus. Each skill keeps its own cooldown and the boss
## waits final_action_gap between actions; nothing ready (or in reach) means a short wait, never a
## stall or a cast without effect.
func heal_first(a: Dictionary) -> bool:
    return float(a.get("skill_cds",{}).get("heal",0))<=0 and skill_ready(a,"heal")

## The final boss's non-Heal choices (final_choice): the attack pool, then Focus, existing skills only.
func final_skill_pool() -> Array:
    return (Array(sim.abilities.final_attack_pool)+["focus"]).filter(func(key):return sim.catalog.skills.has(key))

## Changes 84-85: every skill an enemy can actually use, in the order its icons show. d is its definition
## (sim.enemy_definition: the variant's own list, empty for helpers). A normal enemy or boss casts exactly its
## definition's skill list (the Change 78 rotation). The final boss does not use that list: its Change 13 kit
## casts Heal (final_choice, and Rage's immediate Heal) and draws from final_skill_pool, so it shows its list's
## skills first, then the rest of the kit (Heal, then the pool). Display only: skill drops, mastery, the map icon
## and every cast rule keep reading the catalog list or the kit itself.
func shown_skills(d: Dictionary) -> Array:
    var own: Array=Array(d.get("skills",[]))
    if not bool(d.get("final",false)):return own.duplicate()
    var kit: Array=(["heal"] if sim.catalog.skills.has("heal") else [])+final_skill_pool()
    var out: Array=own.filter(func(key):return kit.has(key))
    for key in kit:
        if not out.has(key):out.append(key)
    return out

func final_choice(a: Dictionary) -> String:
    if heal_first(a):return "heal"
    var options: Array=[]
    var cds: Dictionary=a.get("skill_cds",{})
    for key in final_skill_pool():
        if float(cds.get(key,0))>0 or not skill_ready(a,key):continue
        if not key in SELF_SKILLS and sim.position_of(a).distance_to(sim.position_of(sim.state.player))>skill_range(key):continue
        options.append(key)
    if options.is_empty():return ""
    return options[sim.rng.randi_range(0,options.size()-1)]

func _final_turn(a: Dictionary) -> void:
    if not a.has("skill_cds"):a.skill_cds={}
    if a.get("telegraph",false):
        if a.skill_timer>0:return
        a.telegraph=false
        var key: String=str(a.get("pending",""))
        if key!="" and apply_skill(a,key,float(sim.catalog.skills[key].power),Vector2(a.get("aim_x",sim.state.player.x),a.get("aim_y",sim.state.player.y))):
            a.skill_cds[key]=enemy_skill_cooldown(sim.catalog.groups[int(a.group)],key)
            a.skill_timer=float(sim.abilities.final_action_gap)
        else:a.skill_timer=.5
        a.pending=""
        return
    if a.skill_timer>0:return
    var key:=final_choice(a)
    if key=="":
        a.skill_timer=.5
        return
    _begin_telegraph(a,key)

## Change 13 Auto Evolution: once a second, each owned weapon whose exact identity is dropped by a
## type with Auto Evolution bought evolves once if the manual rules allow it (same function, same
## cost and result). The successor is judged by its own droppers, so tiers never chain by inheritance.
var evolve_clock: float=0
func auto_evolve() -> void:
    if evolve_clock<1.0:return
    evolve_clock=0
    var ids: Array=sim.state.items.keys();ids.sort()
    for id in ids:
        if not sim.auto_merge_excluded(id) and sim.evolve_group(id)>=0 and sim.evolve_block_reason(id)=="":sim.evolve(id)

func automate(dt: float) -> void:
    for g in stage().groups:
        if sim.level("collect",g)>0:
            sim.state.collect_clocks[g]+=dt
            if sim.state.collect_clocks[g]>=sim.group_upgrade_value("collect_speed",g):
                sim.state.collect_clocks[g]=0
                var n=0
                for drop in sim.state.pickups.duplicate():
                    if int(drop.group)==g and sim.position_of(sim.state.player).distance_to(Vector2(drop.x,drop.y))<=sim.group_upgrade_value("collect_range",g) and sim.can_add(drop.item):
                        if sim.collect(int(drop.uid)):n+=1
                        if n>=sim.group_upgrade_value("collect_batch",g):break
    for g in range(sim.catalog.groups.size()):
        if sim.level("merge_gear",g)>0:merge_cycle(str(g),10-sim.level("gear_merge_speed",g),dt,g)
    auto_evolve()
    sim.state.use_clock+=dt
    if sim.state.use_clock>=sim.player_upgrade_value("use_speed"):
        sim.state.use_clock=0
        # Each automated slot uses its supply when that supply's own auto condition holds.
        for slot in sim.state.auto_slots.slice(0,sim.level("auto_use")):
            if int(slot)>=0 and int(slot)<sim.state.supplies.size():
                var id: String=sim.state.supplies[int(slot)]
                if id!="" and sim.supply_auto_ready(id):sim.use_item(id)
    # Change 76: Auto Buy Supplies restocks after the uses above (a use that empties a stack buys at once).
    sim.auto_buy_step()
    # Change 79: during the post-respawn return to the farming spot only Heal is cast automatically (it
    # targets nobody and never stops the walk); attack and Focus skills wait for the arrival.
    var returning: bool=sim.focus_returning()
    for i in sim.automatic_skill_assignments():
        var skill_id: String=str(sim.state.skills[int(i)]) if int(i)<sim.state.skills.size() else ""
        if returning and str(sim.catalog.items.get(skill_id,{}).get("skill",""))!="heal":continue
        cast(int(i))
    if sim.state.mission_auto and sim.level("mission_claim")>0:
        for i in range(sim.state.missions.size()):
            if sim.state.missions[i].progress>=sim.state.missions[i].goal and not sim.state.missions[i].claimed:claim_mission(i)
func merge_cycle(key: String,interval: float,dt: float,g: int) -> void:
    sim.state.merge_timers[key]=float(sim.state.merge_timers.get(key,0))+dt
    if sim.state.merge_timers[key]<interval:return
    sim.state.merge_timers[key]=0
    var ids: Array=sim.state.items.keys();ids.sort()
    var start=int(sim.state.merge_cursors.get(key,0))
    for offset in range(ids.size()):
        var i: int=(start+offset)%ids.size();var id: String=ids[i]
        var eligible: bool=sim.gear_group(id)==g and sim.can_auto_merge(id)
        if eligible and sim.quantity(id)>1 and sim.record(id).merge<sim.merge_cap(id):
            sim.merge(id);sim.state.merge_cursors[key]=(i+1)%ids.size();break
func begin_encounter(a: Dictionary) -> void:
    if a.id!="player" and not a.has("encounter_uses"):a.encounter_uses=sim.state.consumable_uses
func killed(a: Dictionary) -> void:
    var d: Dictionary=sim.catalog.groups[int(a.group)]
    discover_spot(int(a.group),int(a.get("variant",2)))
    sim.state.run_kills[d.id]=int(sim.state.run_kills.get(d.id,0))+1
    var prior: Array=sim.state.opportunities.keys()
    hunt_kill()
    progress("kill" if not d.boss else "boss_kill",d.id,1)
    if d.boss:
        progress("boss",d.id,1)
        # Change 81: the key is credited here (and saved below with the boss kill); key_earned is presentation only.
        if sim.state.final_discovered and not d.final and not sim.state.keys.has(d.id):
            sim.state.keys.append(d.id)
            sim.key_earned.emit(int(a.group),Vector2(float(a.get("x",sim.state.player.x)),float(a.get("y",sim.state.player.y))),sim.state.keys.size())
        if int(a.get("encounter_uses",-1))==int(sim.state.consumable_uses):
            for op in sim.catalog.campaign.opportunities:
                if op.path=="challenge" and prior.has(op.id) and boss_goal("challenge",int(op.id.right(1)))==d.id:progress("restricted",d.id,1)
        for op in sim.catalog.campaign.opportunities:
            if op.path=="trophy" and prior.has(op.id):
                var o: Dictionary=sim.state.opportunities[op.id]
                o["trophy_"+d.id]=true
    var complete=true
    for id in stage().gates:
        if int(sim.state.run_kills.get(id,0))==0:complete=false
    if complete and not stage().gates.is_empty() and int(sim.state.unlocked_stage)==int(sim.state.stage):
        sim.state.unlocked_stage=mini(8,int(sim.state.stage)+1);sim.event.emit("STAGE_UNLOCKED");sim.milestone.emit("stage",str(sim.state.unlocked_stage))
    if int(sim.state.stage)==8:
        complete=true
        for g in stage().groups:
            if int(sim.state.run_kills.get(sim.catalog.groups[g].id,0))==0:complete=false
        if complete and not sim.state.world_complete:
            sim.state.world_complete=true;sim.event.emit("WORLD_COMPLETE")
    evaluate()
    # Change 15: the Snowman's defeat reveals Prestige and every remaining menu (after the new map's
    # banner, so the two milestones read in order).
    onboarding.evaluate()
    a.erase("encounter_uses")
    if d.boss:SaveService.save_now()
func progress(kind: String,id: String,amount: float) -> void:
    guided.action(kind,id)
    var prior: Array=sim.state.opportunities.keys()
    sim.state.counters[kind]=float(sim.state.counters.get(kind,0))+amount
    sim.state.counters[kind+":"+id]=float(sim.state.counters.get(kind+":"+id,0))+amount
    if kind=="coins":sim.state.online_coins+=amount
    if kind=="evolve":mastery.record_evolved(id)
    if kind=="collect":sim.state.online_items[id]=float(sim.state.online_items.get(id,0))+amount
    for m in sim.state.missions:
        if not m.claimed and m.kind==kind and (m.target=="" or m.target==id):
            var was_ready: bool=m.progress>=m.goal
            m.progress=minf(m.goal,m.progress+amount)
            # Change 12: a mission the player claims by hand announces itself once; purchased
            # auto-claim processes repeated missions silently.
            if not was_ready and m.progress>=m.goal and not missions_auto_claimed():sim.notice.emit("mission_ready",str(m.kind))
    for op in sim.catalog.campaign.opportunities:
        if not sim.state.opportunities.has(op.id):continue
        var o: Dictionary=sim.state.opportunities[op.id]
        if o.ready or sim.state.consumed.has(op.id):continue
        if op.path in ["expedition","specialist"]:
            var chain=chain_for(op.id)
            var index=int(o.get("step",0))
            if index<chain.size():
                var q: Array=chain[index]
                if kind==q[0] and (q[1]=="" or id==q[1]):
                    o.count=float(o.get("count",0))+amount
                    if o.count>=q[2]:o.step=index+1;o.count=0
        if kind=="gear":o["item_"+id]=float(o.get("item_"+id,0))+amount
        if kind=="merge":
            o["merge_"+id]=maxi(int(o.get("merge_"+id,0)),int(sim.record(id).merge))
    evaluate()
    for op in sim.catalog.campaign.opportunities:
        if prior.has(op.id) or not sim.state.opportunities.has(op.id):continue
        var o: Dictionary=sim.state.opportunities[op.id]
        o.baseline[kind]=float(o.baseline.get(kind,0))-amount
        o.baseline[kind+":"+id]=float(o.baseline.get(kind+":"+id,0))-amount
        if kind=="gear":o["item_"+id]=amount
        if kind=="merge":o["merge_"+id]=int(sim.record(id).merge)
        if op.path in ["expedition","specialist"]:
            var q: Array=chain_for(op.id)[0]
            if q[0]==kind and (q[1]=="" or q[1]==id):o.count=amount
    evaluate()
    # Change 15: the demonstrated actions that reveal the next menu take effect at once.
    if kind in ["merge","upgrade","camp","mission","supply_buy","gear"]:onboarding.evaluate()
func counter(key: String) -> float:return float(sim.state.counters.get(key,0))
func missions_auto_claimed() -> bool:return bool(sim.state.mission_auto) and sim.level("mission_claim")>0
func refresh_missions() -> void:
    var day=sim.today()
    for i in range(sim.state.missions.size()):
        if sim.state.missions[i].kind=="waiting" or (sim.state.missions[i].claimed and sim.state.missions[i].day!=day):
            sim.state.missions[i]=new_mission(i,day)
            price_mission(sim.state.missions[i])
    while sim.state.missions.size()<3+sim.level("mission_slots"):
        var mission: Dictionary=new_mission(sim.state.missions.size(),day)
        price_mission(mission)
        sim.state.missions.append(mission)
    # Preserve active mission rewards and progress through Prestige. New missions use the new
    # run's current reward stage, while old saves without pricing are initialized once.
    for m in sim.state.missions:
        if not m.claimed and not m.has("reward_stage"):price_mission(m)
    sim.state.mission_day=day
func new_mission(index: int,day: String) -> Dictionary:
    var candidates: Array=[]
    var st=1
    for d in sim.catalog.groups:
        if d.stage<=sim.state.unlocked_stage and sim.state.run_kills.get(d.id,0)>0:st=maxi(st,int(d.stage))
    for g in range(sim.catalog.groups.size()):
        var d: Dictionary=sim.catalog.groups[g]
        if d.stage>st:continue
        if sim.state.run_kills.get(d.id,0)>0:st=maxi(st,int(d.stage))
        if not d.boss:candidates.append({"kind":"kill","target":d.id,"goal":120.0,"coins":150.0*d.stage,"gems":0.0})
        elif sim.state.run_kills.get(d.id,0)>0 and (not d.final or sim.state.keys.size()==13):candidates.append({"kind":"boss","target":d.id,"goal":5.0,"coins":200.0*d.stage,"gems":5.0})
    if sim.state.gear.has(""):candidates.append({"kind":"gear","target":"","goal":12.0,"coins":120.0*st,"gems":3.0})
    for id in sim.state.items:
        if sim.can_merge(id):
            candidates.append({"kind":"merge","target":"","goal":20.0,"coins":100.0*st,"gems":3.0});break
    candidates.append({"kind":"coins","target":"","goal":300.0*st,"coins":0.0,"gems":5.0})
    if sim.state.skills.any(func(id):return id!=""):candidates.append({"kind":"cast","target":"","goal":40.0,"coins":100.0*st,"gems":3.0})
    var options: Array=[]
    for candidate in candidates:
        var duplicate=false
        for m in sim.state.missions:
            if not m.claimed and m.kind==candidate.kind and m.target==candidate.target:duplicate=true
        if not duplicate:options.append(candidate)
    # More purchased slots can wait for new eligible objectives rather than duplicate one.
    if options.is_empty():return {"kind":"waiting","target":"","goal":1.0,"progress":0.0,"coins":0.0,"gems":0.0,"day":day,"claimed":false}
    var result: Dictionary=options[(index+absi(day.hash()))%options.size()].duplicate(true)
    result.merge({"progress":0.0,"day":day,"claimed":false})
    result["base_gems"]=result.gems
    price_mission(result)
    return result
## Change 14: one eligibility rule for the Missions badge and the Claim buttons. A regular mission is
## claimable when it is complete, unclaimed and not handled by purchased auto-claim (which claims it on
## the next tick); a main objective when it is ready, unclaimed and listed (main_shown).
func mission_claimable(i: int) -> bool:
    if i<0 or i>=sim.state.missions.size():return false
    var m: Dictionary=sim.state.missions[i]
    return str(m.kind)!="waiting" and not m.claimed and m.progress>=m.goal and not missions_auto_claimed()
func main_claimable(i: int) -> bool:
    return sim.state.main_ready.has(str(i)) and not sim.state.main_claimed.has(i) and (i!=15 or sim.state.final_discovered)
## The main objectives the Missions panel lists: three at most, ready ones first (in order), then the
## next unfinished ones. Before Change 14 the first three unclaimed were listed whatever their state, so
## a later objective could be ready (badge on) with no Claim button anywhere.
func main_shown() -> Array:
    var ready: Array=[];var waiting: Array=[]
    for i in range(16):
        if sim.state.main_claimed.has(i) or (i==15 and not sim.state.final_discovered):continue
        if main_claimable(i):ready.append(i)
        else:waiting.append(i)
    return (ready+waiting).slice(0,3)
func has_claimable() -> bool:
    if hunt_claimable():return true
    for i in range(sim.state.missions.size()):
        if mission_claimable(i):return true
    for i in main_shown():
        if main_claimable(i):return true
    return false
# ---------------------------------------------------------------- followed mission (Change 16)
## One regular mission or main objective can be followed (state.follow_mission), next to the followed
## Prestige opportunity; each has its own tracker and its own Follow / Unfollow. A daily mission is
## identified by its slot and its assignment ("daily:<slot>:<kind>:<target>:<day>"), so a refresh that
## replaces it ends the follow; "main:<index>" names a main objective. A claim ends the follow.
func mission_follow_key(kind: String,i: int) -> String:
    if kind=="hunt":return HUNT_ID
    if kind=="main":return "main:%d" % i
    if i<0 or i>=sim.state.missions.size():return ""
    var m: Dictionary=sim.state.missions[i]
    return "daily:%d:%s:%s:%s" % [i,m.kind,m.target,m.day]
func can_follow_mission(kind: String,i: int) -> bool:
    if kind=="hunt":return hunt_open()
    if kind=="main":return i>=0 and i<16 and not sim.state.main_claimed.has(i) and (i!=15 or sim.state.final_discovered)
    if i<0 or i>=sim.state.missions.size():return false
    var m: Dictionary=sim.state.missions[i]
    return str(m.kind)!="waiting" and not m.claimed
func mission_followed(kind: String,i: int) -> bool:
    var key:=mission_follow_key(kind,i)
    return key!="" and str(sim.state.get("follow_mission",""))==key
func toggle_follow_mission(kind: String,i: int) -> bool:
    if mission_followed(kind,i):sim.state.follow_mission="";sim.touch();return true
    if not sim.action_lock_reason().is_empty():return sim.fail(sim.action_lock_reason())
    if not can_follow_mission(kind,i):return sim.fail("FOLLOW_UNAVAILABLE")
    sim.state.follow_mission=mission_follow_key(kind,i);sim.touch();return true
## The followed mission as {kind, index} while it still exists and is unclaimed, else {}.
func followed_mission() -> Dictionary:
    var key: String=str(sim.state.get("follow_mission",""))
    if key=="":return {}
    if key==HUNT_ID:return {"kind":"hunt","index":0} if hunt_open() else {}
    var bits:=key.split(":")
    var kind: String=bits[0]
    var i:=int(bits[1]) if bits.size()>1 else -1
    if kind!="main" and kind!="daily":return {}
    if mission_follow_key(kind,i)!=key or not can_follow_mission(kind,i):return {}
    return {"kind":kind,"index":i}
## Ends a follow whose mission was claimed or replaced (called after claims, refreshes and the tick).
func check_follow_mission() -> void:
    if str(sim.state.get("follow_mission",""))!="" and followed_mission().is_empty():
        sim.state.follow_mission=""
        sim.touch()
## Main objectives as progress the tracker can show: [current, goal] (a done/not-done goal is 0/1).
func main_progress(i: int) -> Array:
    match i:
        0:return [mini(int(counter("kill")),5),5]
        10:return [mini(skill_count(),4),4]
        12:return [mini(skill_count(),6),6]
    return [1 if sim.state.main_ready.has(str(i)) else 0,1]
## One readable line for the followed mission: what to do, where, and how far along (Change 16).
func mission_follow_summary() -> String:
    var f:=followed_mission()
    if f.is_empty():return ""
    if f.kind=="hunt":
        if hunt_ready():return sim.tr("MISSION_FOLLOW_READY")
        return "%s: %d/%d" % [sim.tr("HUNT_MISSION_HINT"),int(hunt_progress()),HUNT_GOAL]
    if f.kind=="main":
        var i: int=f.index
        if main_claimable(i):return sim.tr("MISSION_FOLLOW_READY")
        var p:=main_progress(i)
        var hint: String=sim.tr("MAIN_HINT_%d" % i)
        return hint if int(p[1])<=1 else "%s: %d/%d" % [hint,int(p[0]),int(p[1])]
    var m: Dictionary=sim.state.missions[f.index]
    if m.progress>=m.goal:return sim.tr("MISSION_FOLLOW_READY")
    var g:=group_id(str(m.target))
    var where: String=sim.catalog.stages[int(sim.catalog.groups[g].stage)-1].name if g>=0 else ""
    var amount: String=("%s / %s" % [NumberFormat.currency(m.progress),NumberFormat.currency(m.goal,true)]) if str(m.kind)=="coins" else ("%s / %s" % [NumberFormat.count(floorf(m.progress)),NumberFormat.count(m.goal)])
    var what: String=sim.tr("MISSION_DO_"+str(m.kind).to_upper())
    if g>=0:what=what % [str(sim.catalog.groups[g].name),where]
    return "%s: %s" % [what,amount]
func claim_mission(i: int) -> bool:
    if not sim.action_lock_reason().is_empty() or i<0 or i>=sim.state.missions.size():return false
    var m: Dictionary=sim.state.missions[i]
    if m.claimed or m.progress<m.goal:return false
    var before: Dictionary=sim.state.duplicate(true)
    # The reward recorded for the daily mission remains stable across Prestige.
    if not m.has("reward_stage"):price_mission(m)
    m.claimed=true;sim.state.coins+=m.coins;sim.state.gems+=m.gems
    progress("mission","",1);refresh_missions();check_follow_mission();sim.touch()
    if not SaveService.save_now():sim.state=before;sim.touch();return false
    return true
# ---------------------------------------------------------------- one-time 30-defeat mission (Change 61)
## A stable one-time mission (state.hunt, kept by Prestige, cleared by Hard Reset), in every mode: it
## unlocks the moment the Snowman is first found (prestige_unlocked) and counts HUNT_GOAL real defeats of
## any enemy or boss from then on (hunt_kill, from killed(): summoned helpers never get there and offline
## time defeats nothing). It is not a daily slot: no refresh replaces it and Auto Claim never takes it;
## the player follows it like any mission and claims it by hand, once. Reward: the established
## main-objective scale (catalog main_rewards[HUNT_REWARD_INDEX], the "unlock a camp" objective's).
const HUNT_ID:="hunt"
const HUNT_GOAL:=30
const HUNT_REWARD_INDEX:=3
func hunt_initial() -> Dictionary:return {"unlocked":false,"progress":0.0,"claimed":false}
func hunt_state() -> Dictionary:return sim.state.get("hunt",hunt_initial())
func hunt_progress() -> float:return float(hunt_state().progress)
func hunt_ready() -> bool:return bool(hunt_state().unlocked) and hunt_progress()>=HUNT_GOAL
## Unlocked and not claimed yet: shown in Missions, followable.
func hunt_open() -> bool:return bool(hunt_state().unlocked) and not bool(hunt_state().claimed)
func hunt_claimable() -> bool:return hunt_open() and hunt_ready()
func hunt_rewards() -> Array:return sim.catalog.campaign.main_rewards[HUNT_REWARD_INDEX]
func unlock_hunt() -> void:
    var h: Dictionary=sim.state.get("hunt",{})
    if h.is_empty() or bool(h.unlocked) or not prestige_unlocked():return
    h.unlocked=true;h.progress=0.0
    sim.touch();SaveService.mark_committed()
func hunt_kill() -> void:
    var h: Dictionary=sim.state.get("hunt",{})
    if h.is_empty() or not bool(h.unlocked) or bool(h.claimed) or float(h.progress)>=HUNT_GOAL:return
    h.progress=minf(HUNT_GOAL,float(h.progress)+1.0)
    if float(h.progress)>=HUNT_GOAL:sim.notice.emit("mission_ready","hunt")
func claim_hunt() -> bool:
    if not sim.action_lock_reason().is_empty() or not hunt_claimable():return false
    var before: Dictionary=sim.state.duplicate(true)
    var rewards:=hunt_rewards()
    sim.state.hunt.claimed=true;sim.state.coins+=rewards[0];sim.state.gems+=rewards[1]
    guided.action("hunt_claim","")
    check_follow_mission();sim.touch()
    if not SaveService.save_now():sim.state=before;sim.touch();return false
    return true
## Change 54 (approved Design A): the per-path requirement tables, indexed by the opportunity number - 1.
## Opportunities 1-3 are unchanged; 4-8 are the expansion (audit §7.3). Enemy and boss ids are real content.
const EXPEDITION_TYPES:=[["blue-cap","red-scarf","chef-hat"],["straw-hat","sunglasses","yellow-cap"],["bunny-ears","cat-ears","elf-ears"],
    ["wolf-hood","calico-cat-hood","golden-crown","reindeer-antlers","santa-hat","space-helmet"],
    ["cowboy-bandana","duck-swim-ring","rainbow-clown","red-cap-swimmer","snorkeler","straw-hat-swimmer"],
    ["black-cap","mushroom-cap","pumpkin-head"],["horned-hood","orange-screen-helmet","television-head","top-hat"],
    ["flower-crown","green-cap","pink-cap","pink-flower-hood","plain","sprout"]]
const EXPEDITION_KILLS:=[100,150,200,50,60,120,100,60]
const COLLECTION_TYPES:=[["blue-cap","red-scarf","chef-hat"],["straw-hat","sunglasses","yellow-cap"],["bunny-ears","cat-ears","elf-ears"],
    ["santa-hat","reindeer-antlers","space-helmet"],["snorkeler","red-cap-swimmer","straw-hat-swimmer"],
    ["black-cap","mushroom-cap","pumpkin-head"],["television-head","top-hat","orange-screen-helmet"],["pink-cap","plain","sprout"]]
const COLLECTION_GOALS:=[20,30,40,15,25,30,30,40]
## Map access that discovers Collection 2-8 (Collection 1 is discovered by gear families).
const COLLECTION_DISCOVER_STAGE:=[0,3,7,2,4,5,6,8]
const HUNTER_BOSSES:=[["boss-snowman"],["boss-gray-cat"],["boss-grim-reaper"],["boss-bee","boss-orange-tabby-cat"]]
## Boss Hunter kill targets per boss after discovery (Change 6: 10 / 20 / 30; Change 54: IV 10 each).
## Change 61 (approved first-boss flow): Hunter I is discovered by finding the Snowman and is ready on its
## first defeat (1). Hunter II-IV keep their discovery (a first defeat) and their counts.
const HUNTER_KILLS:=[1,20,30,10]
const CHALLENGE_BOSSES:=["boss-cyan-robot","boss-teal-dinosaur","boss-grim-reaper","boss-red-panda"]
const TROPHY_BOSSES:=[["snowman","cyan-robot"],["gray-cat","elephant","teal-dinosaur"],["squirrel","red-fox","black-cat","grim-reaper"],["bee","orange-tabby-cat","red-panda","sunflower"]]
const REGIONAL_STAGES:=[[1,2],[3,4],[7,8],[5,6]]
const REGIONAL_DISCOVER_STAGE:=[2,4,8,6]
func regional_stages(n: int) -> Array:return REGIONAL_STAGES[n-1]
func hunter_bosses(n: int) -> Array:return HUNTER_BOSSES[n-1]
## Kills of `boss` since this Hunter opportunity was discovered.
func hunter_count(o: Dictionary,boss: String) -> int:
    var k:="boss:"+boss
    return int(counter(k)-float(o.get("baseline",{}).get(k,0)))
func hunter_done(o: Dictionary,n: int) -> bool:
    for boss in hunter_bosses(n):
        if hunter_count(o,boss)<hunter_goal(n):return false
    return true
func chain_for(id: String) -> Array:
    var n=int(id.right(1))
    if id.begins_with("expedition"):
        var chain: Array=[]
        for name in EXPEDITION_TYPES[n-1]:chain.append(["kill","unit-"+name,EXPEDITION_KILLS[n-1]])
        return chain
    return [["kill","",100],["gear","",10],["merge","",10]] if n==1 else ([["kill","",250],["boss","",3],["merge","",25],["cast","",30]] if n==2 else [["kill","",500],["boss","",10],["merge","",50],["mission","",3]])
func online_gear_families() -> int:
    var families={}
    for id in sim.state.online_items:
        if sim.state.online_items[id]>0 and sim.catalog.items[id].kind in ["weapon","outfit"]:families[sim.catalog.items[id].family]=true
    return families.size()
func evolved_families() -> int:
    var families={}
    for key in sim.state.counters:
        if key.begins_with("evolve:") and sim.catalog.items.has(key.trim_prefix("evolve:")):
            var d: Dictionary=sim.catalog.items[key.trim_prefix("evolve:")]
            if d.kind in ["weapon","outfit"]:families[d.family]=true
    return families.size()
func discoverable(op: Dictionary) -> bool:
    var n=int(op.id.right(1));var path: String=op.path
    match path:
        "offline":return sim.state.offline_total>0
        "hunter","challenge":
            if path=="hunter" and n==1 and prestige_unlocked():return true
            return counter("boss:"+boss_goal(path,n))>=1
        "expedition":return counter("kill:"+str(chain_for(op.id)[0][1]))>=10
        "regional":return sim.state.unlocked_stage>=REGIONAL_DISCOVER_STAGE[n-1]
        "offering":return counter("coins")>=1000 if n==1 else sim.state.unlocked_stage>=(5 if n==2 else 8)
        "specialist":return counter("mission")>=(1 if n==1 else 5) if n<3 else sim.state.unlocked_stage>=6
        "trophy":return counter("boss:boss-"+str(TROPHY_BOSSES[n-1][0]))>0
        "collection":return online_gear_families()>=3 if n==1 else sim.state.unlocked_stage>=COLLECTION_DISCOVER_STAGE[n-1]
        "masterwork":
            if n==4:
                for id in sim.state.items:
                    if sim.quantity(id)>0 and _obsidian_weapon(id):return true
            elif n==1:
                for r in sim.state.items.values():
                    if r.merge>=10:return true
            elif n==2:return counter("evolve")>0
            elif n==3:
                for id in sim.state.items:
                    if sim.quantity(id)>0 and sim.catalog.items[id].tier>=3:return true
        "arsenal":return sim.state.weapon!="" and sim.state.outfit!="" if n==1 else (online_gear_families()>=4 if n==2 else evolved_families()>=2)
    return false
## The (first) boss a Hunter or Challenge opportunity names.
func boss_goal(path: String,n: int) -> String:
    return str(HUNTER_BOSSES[n-1][0]) if path=="hunter" else str(CHALLENGE_BOSSES[n-1])
func hunter_goal(n: int) -> int:return HUNTER_KILLS[n-1]
func _obsidian_weapon(id: String) -> bool:
    var d: Dictionary=sim.catalog.items.get(id,{})
    return str(d.get("kind",""))=="weapon" and str(d.get("next","x"))=="" and int(d.get("tier",0))==7 and not sim.is_legacy(id)
func evaluate() -> void:
    unlock_hunt()
    for op in sim.catalog.campaign.opportunities:
        if sim.state.consumed.has(op.id):continue
        if not sim.state.opportunities.has(op.id):
            if not discoverable(op):continue
            sim.state.opportunities[op.id]={"ready":false,"baseline":sim.state.counters.duplicate(true),"step":0,"count":0}
            sim.event.emit("PRESTIGE_DISCOVERED");sim.milestone.emit("discovered",op.id)
        var o: Dictionary=sim.state.opportunities[op.id]
        if o.ready:continue
        var n=int(op.id.right(1));var ready=false
        match op.path:
            "hunter":ready=hunter_done(o,n)
            "challenge":
                var k: String="restricted:"+boss_goal(op.path,n)
                ready=counter(k)-float(o.baseline.get(k,0))>=1
            "expedition","specialist":ready=int(o.get("step",0))>=chain_for(op.id).size()
            "offline":ready=sim.state.offline_total>=72*3600 if n==1 else (sim.state.offline_longest>=24*3600 if n==2 else sim.state.offline_income>=10000)
            "masterwork":ready=masterwork_best(o,n)>=MASTERWORK_MERGE
            "arsenal":
                var counts:=arsenal_counts(o,n)
                ready=counts[0]>=arsenal_need(n) and counts[1]>=arsenal_need(n)
            "regional":
                ready=true
                for st in regional_stages(n):
                    var d: Dictionary=sim.catalog.stages[st-1]
                    if explored_fraction(st)<.9 or sim.state.camps.get(str(st),[]).size()!=d.spawns.size():ready=false
                    for g in d.groups:
                        if sim.catalog.groups[g].boss and sim.state.run_kills.get(sim.catalog.groups[g].id,0)==0:ready=false
            "collection","offering":ready=bool(o.get("submitted",false))
            "trophy":
                ready=true
                for boss in trophy_bosses(n):
                    if not o.get("trophy_boss-"+boss,false):ready=false
        if ready:
            o.ready=true
            if sim.state.follow==op.id:
                sim.notice.emit("follow_step",op.id)
                sim.state.follow="";follow_tracked=""
            sim.event.emit("PRESTIGE_READY");sim.milestone.emit("ready",op.id)
    evaluate_main()
    check_follow_step()

## Steps of the followed opportunity completed so far (Change 12). A rise is one completed step and
## earns one notice; the first reading after load or a new follow only sets the baseline, and the
## count never re-announces a step that was lost and found again.
func follow_steps_done(id: String) -> int:
    var o: Dictionary=sim.state.opportunities.get(id,{})
    if o.is_empty():return 0
    var n=int(id.right(1));var path=id.split("_o")[0]
    match path:
        "expedition","specialist":return int(o.get("step",0))
        "collection":
            var done:=0
            for c in collection_counts(id):
                if c>=collection_required(n):done+=1
            return done
        "trophy":
            var got:=0
            for boss in trophy_bosses(n):
                if o.get("trophy_boss-"+boss,false):got+=1
            return got
    return 0
var follow_tracked:=""
var follow_steps:=0
func check_follow_step() -> void:
    var id: String=str(sim.state.get("follow",""))
    if id=="" or not sim.state.opportunities.has(id):
        follow_tracked="";return
    var done:=follow_steps_done(id)
    if id!=follow_tracked:
        follow_tracked=id;follow_steps=done;return
    if done>follow_steps:sim.notice.emit("follow_step",id)
    follow_steps=maxi(follow_steps,done)
func submit(id: String) -> bool:
    if not sim.action_lock_reason().is_empty() or not sim.state.opportunities.has(id):return false
    var n=int(id.right(1));var o: Dictionary=sim.state.opportunities[id]
    if o.ready:return false
    var before: Dictionary=sim.state.duplicate(true)
    if id.begins_with("offering"):
        var coins: int=[2000,20000,100000][n-1];var gems: int=[30,100,300][n-1]
        if sim.state.online_coins<coins or sim.state.online_gems<gems or sim.state.coins<coins or sim.state.gems<gems:return sim.fail("OFFERING_NEEDS")
        sim.state.coins-=coins;sim.state.gems-=gems;sim.state.online_coins-=coins;sim.state.online_gems-=gems
    elif id.begins_with("collection"):
        # Change 41: the same per-outfit counts the panel, tracker and follower show, toward the same
        # collection_required; Submit hands in collection_goal copies of each and keeps one.
        if not collection_complete(id):return sim.fail("CONTRACT_NEEDS")
        for name in collection_names(n):
            sim._remove(contract_outfit(name),collection_goal(n))
    else:return false
    o.submitted=true;evaluate();sim.touch()
    if not SaveService.save_now():sim.state=before;sim.touch();return false
    return true
## Follow marks one opportunity the player is working toward. A ready or redeemed opportunity has
## nothing left to work toward, so it cannot be followed; unfollowing is always allowed.
func can_follow(id: String) -> bool:
    return sim.state.opportunities.has(id) and not sim.state.consumed.has(id) and not bool(sim.state.opportunities[id].ready)
func toggle_follow(id: String) -> bool:
    if sim.state.follow==id:sim.state.follow="";sim.touch();return true
    if not sim.action_lock_reason().is_empty():return sim.fail(sim.action_lock_reason())
    if not can_follow(id):return sim.fail("FOLLOW_UNAVAILABLE")
    sim.state.follow=id;sim.touch();return true
## The outfit a normal type drops (its stage tier since Change 7), used by collection contracts.
func contract_outfit(name: String) -> String:
    var g:=group_id("unit-"+name)
    for id in sim.catalog.groups[g].loot:
        if sim.catalog.items[id].kind=="outfit":return id
    return "unit-"+name+"_outfit"
func ready_ids() -> Array:
    var ids: Array=[]
    for id in sim.state.opportunities:
        if sim.state.opportunities[id].ready and not sim.state.consumed.has(id):ids.append(id)
    ids.sort();return ids
## Change 10 Farming Guide: a map's entry opens once its Map Details is fully bought and every enemy
## type on it has both Reveal Stats and Reveal Drops (bosses included). Map Details is per run and
## the reveals are permanent, so an entry is per run like the map. Opening it reveals nothing: names,
## loadouts and locations still come only from discovered types and spots (discovered_spots).
func farming_guide_status(st: int) -> Dictionary:
    var cap:=int(sim.catalog.upgrades.map_detail.cap)
    var detail: int=sim.level("map_detail",st)
    var types: int=sim.catalog.stages[st-1].groups.size()
    var researched:=0
    for g in sim.catalog.stages[st-1].groups:
        if sim.level("reveal_stats",g)>0 and sim.level("reveal_drops",g)>0:researched+=1
    var reached: bool=st<=int(sim.state.unlocked_stage)
    return {"reached":reached,"map_detail":detail,"map_detail_cap":cap,"researched":researched,"types":types,"open":reached and detail>=cap and researched==types}
## Where a spot lies from the nearest camp the player knows on its stage: [camp, compass key,
## distance]. Callers show it only for a discovered spot; it never decides visibility.
func spot_bearing(g: int,v: int) -> Array:
    var st:=int(sim.catalog.groups[g].stage)
    var spawns: Array=sim.catalog.stages[st-1].spawns
    var at:=spot(g,v)
    var best:=0;var distance:=INF
    for i in range(spawns.size()):
        if not camp_known(i,st):continue
        var d:=at.distance_to(Vector2(spawns[i][0],spawns[i][1]))
        if d<distance:distance=d;best=i
    if distance==INF:distance=at.distance_to(Vector2(spawns[0][0],spawns[0][1]))
    var delta:=at-Vector2(spawns[best][0],spawns[best][1])
    var compass: String="HERE" if delta.length()<80 else ["E","SE","S","SW","W","NW","N","NE"][posmod(roundi(delta.angle()/(PI/4)),8)]
    return [best,compass,distance]
## The Prestige reset (Change 8, corrected) needs the first boss (Winter I Snowman) defeated once ever
## (lifetime group_kills, kept by prestige) and one ready opportunity that can still award a card; the
## card is chosen during the reset, so owning a card beforehand is never required. Change 10: the
## Prestige panel itself always opens; only this reset action is gated.
func prestige_unlock_group() -> int:
    var id: String=sim.catalog.progression.get("prestige_unlock_boss","boss-snowman")
    for g in sim.catalog.groups.size():
        if sim.catalog.groups[g].id==id:return g
    return -1
## Change 16: Prestige opens when the first boss (the Winter I Snowman) is found, no longer when it
## is defeated. bosses_found and group_kills are both kept by Prestige, so it never relocks; a
## defeat also counts (a boss can only be defeated after it was in reach).
func prestige_unlocked() -> bool:
    var g:=prestige_unlock_group()
    return g>=0 and (boss_found(str(sim.catalog.groups[g].id)) or int(sim.state.group_kills[g])>0)
## The first boss has been defeated at least once ever (lifetime kills, kept by Prestige).
func first_boss_defeated() -> bool:
    var g:=prestige_unlock_group()
    return g>=0 and int(sim.state.group_kills[g])>0
## Change 61 correction (approved, every mode): finding the Snowman opens the Prestige menu and reveals
## hunter_o1 (prestige_unlocked); the reset itself needs the Snowman defeated once (first_boss_defeated,
## lifetime kills kept by Prestige, so an existing save that already beat it keeps its reset). Guided
## also holds the reset until its optional-Prestige lesson in Winter II.
func prestige_gate_reason() -> String:
    if guided.active() and not guided.prestige_allowed():return "PRESTIGE_TUTORIAL_LOCKED"
    if not first_boss_defeated():return "PRESTIGE_LOCKED_BOSS_DEFEAT"
    return ""
## Ready opportunities that can still award a card, in batch order: each path offers its cards that
## are not owned yet, and every opportunity of the batch takes one of them.
func awardable_ids() -> Array:
    var left: Dictionary={}
    var result: Array=[]
    for id in ready_ids():
        var path: String=id.rsplit("_",true,1)[0]
        if not left.has(path):
            left[path]=0
            for key in sim.catalog.campaign.cards:
                if sim.catalog.campaign.cards[key].path==path and not sim.state.owned_cards.has(key):left[path]+=1
        if int(left[path])>0:
            left[path]-=1;result.append(id)
    return result
func prestige_block_reason() -> String:
    var lock: String=sim.action_lock_reason()
    if lock!="":return lock
    if arena_active() or ceremony_active():return "ARENA_SEALED"
    if celebration_active():return "FINAL_CELEBRATING"
    var gate:=prestige_gate_reason()
    if gate!="":return gate
    if ready_ids().is_empty():return "NO_READY_PRESTIGE"
    if awardable_ids().is_empty():return "NO_CARD_AVAILABLE"
    return ""
func begin_prestige() -> bool:
    if not prestige_block_reason().is_empty():return sim.fail(prestige_block_reason())
    var before: Dictionary=sim.state.duplicate(true)
    sim.state.prestige_batch={"ids":awardable_ids(),"choices":[],"transaction":str(sim.now_unix())+"-"+str(sim.rng.randi())}
    # Change 61: an optional Prestige taken at the Guided Prestige lesson completes that lesson before
    # the reset (the tutorial record is kept), so The Road Ahead follows on the new run's first map.
    guided.prestige_started()
    sim.clear_target();sim.movement=Vector2.ZERO;sim.touch()
    if not SaveService.save_now():sim.state=before;sim.touch();return false
    return true
func offered_cards() -> Array:
    var batch: Dictionary=sim.state.prestige_batch
    if batch.is_empty():return []
    var id: String=batch.ids[batch.choices.size()];var path=id.rsplit("_",true,1)[0];var result: Array=[]
    for key in sim.catalog.campaign.cards:
        if sim.catalog.campaign.cards[key].path==path and not sim.state.owned_cards.has(key) and not batch.choices.has(key):result.append(key)
    return result
func choose_card(id: String) -> bool:
    if sim.suspended or get_tree_paused() or not offered_cards().has(id):return false
    var before: Dictionary=sim.state.duplicate(true)
    sim.state.prestige_batch.choices.append(id)
    var granted: Array=sim.state.prestige_batch.choices.duplicate()
    var final: bool=granted.size()==sim.state.prestige_batch.ids.size()
    if final:
        # Change 50: settle what the ending run already earned, inside this same transaction (one
        # write; a failed write restores `before`): finished missions and pending offline Coins and
        # Gems are paid once, and the run's merge levels are folded into the permanent memory.
        settle_run_for_prestige()
        var keep: Dictionary={}
        # Change 16: Prestige also keeps the Gem balance, every explored map area (fog cells, sighted
        # camps and found encounter spots) and the bosses found.
        # Change 35: the review invitation record is per profile, so Prestige keeps it too.
        # Change 50 (approved rules): also the Coin balance, every purchased upgrade, the per-item merge
        # memory and earned-but-unclaimed main objectives. Items, loadout, rolled attributes, map access,
        # owned camps and transient run state reset; daily missions and Supply Mastery persist.
        # Change 76: owned camps are permanent progression too (with each map's chosen respawn camp), and so
        # are the Auto Buy Supplies selections. Map access still resets: a map's camps are usable again as
        # soon as that map is reached again.
        # New daily missions are repriced from current-run map access (reward_stage) on real day reset.
        for key in ["owned_cards","consumed","opportunities","prestige_collapsed","keys","final_discovered","final_complete","final_unsealed","final_warning_ok","final_experience","final_celebrated","final_ending_seen","completion_maxed","main_claimed","main_ready","offline_total","offline_longest","offline_income","cards","group_kills","skill_auto","tutorial","playtime_total","skills_seen","supply_found","supply_uses","supply_mastery_credit","missions","mission_day","mission_auto","follow_mission","follow_mastery","player_level","xp","onboarding","mastery","gems","coins","merge_memory","migrations","explored","camps_known","discovered","discovered_spots","bosses_found","review","hunt","camps","respawns","auto_buy","camp_supply"]:keep[key]=sim.state[key].duplicate(true) if sim.state[key] is Dictionary or sim.state[key] is Array else sim.state[key]
        keep.owned_cards.append_array(sim.state.prestige_batch.choices);keep.consumed.append_array(sim.state.prestige_batch.ids)
        for op in keep.opportunities:
            if not op.begins_with("offline") and not keep.consumed.has(op):keep.opportunities[op]={"ready":false,"baseline":{},"step":0,"count":0}
        var upgrades: Dictionary={}
        for key in sim.state.upgrades:
            if sim.upgrade_kept(key.split(":")[0]):upgrades[key]=sim.state.upgrades[key]
        var runs: int=sim.state.prestiges+1;var gear: int=sim.state.gear.size();var supplies: int=sim.state.supplies.size()
        sim.new_profile();sim.state.merge(keep,true);sim.state.upgrades=upgrades;sim.state.prestiges=runs
        # The kept camps replace the fresh profile's: state.spawns must be the kept array of this map (a later
        # camp purchase writes state.spawns back into state.camps), and the map's chosen respawn camp returns.
        sim.state.spawn=int(sim.state.respawns.get(str(sim.state.stage),0));configure_stage()
        sim.state.gear.resize(gear);sim.state.gear.fill("");sim.state.supplies.resize(supplies);sim.state.supplies.fill("")
        # Kept spawn upgrades (gems) apply to the fresh world at once, not after the next purchase.
        sim._sync_spawn_counts()
        # The kept exploration is drawn and its spots are known again at once.
        discovery_revision+=1;reveal()
        # The saved daily assignments, progress, rewards and claims survive this reset unchanged.
        # The normal calendar-day refresh still occurs on the next campaign tick.
        check_follow_mission();sim.touch();sim.state.player.hp=sim.stats().hp
    sim.touch()
    if not SaveService.save_now():sim.state=before;sim.touch();return false
    # Presentation follows the durable commit; a failed write never celebrates.
    sim.milestone.emit("card",id)
    if final:sim.event.emit("PRESTIGED");sim.milestone.emit("prestiged",",".join(granted))
    return true
## Change 50: the ending run's earned rewards, applied in memory by the final card choice before the
## reset (never on their own): daily mission assignments, progress and unclaimed rewards remain in
## the profile; pending offline Coins and Gems are paid once with their offline counters (the
## pending item copies would join an inventory that is about to reset, so they end with it); the run's
## merge levels join the merge memory. Main objectives are not claimed: they stay claimable.
func settle_run_for_prestige() -> void:
    # Regular daily missions remain claimable after Prestige; only explicit claims pay them.
    var pending: Dictionary=sim.state.get("offline_pending",{})
    if not pending.is_empty():
        sim.state.coins+=float(pending.coins);sim.state.gems+=float(pending.gems);sim.state.offline_income+=float(pending.coins)
        sim.state.offline_total+=float(pending.seconds);sim.state.offline_longest=maxf(sim.state.offline_longest,float(pending.longest))
        sim.state.offline_pending={}
    for id in sim.state.items:sim.remember_merge(id,int(sim.state.items[id].merge))
func get_tree_paused() -> bool:return sim.get_tree().paused
func cancel_prestige() -> bool:
    if sim.state.prestige_batch.is_empty() or not sim.state.prestige_batch.choices.is_empty():return false
    sim.state.prestige_batch={};sim.touch();return SaveService.save_now()
func evaluate_main() -> void:
    var goals: Array=[counter("kill")>=5,counter("equip")>=1,counter("merge")>=1,counter("camp")>=1,sim.state.unlocked_stage>=2,sim.state.skills.any(func(id):return id.begins_with("skill_heal")),counter("upgrade:map_detail")>0,sim.quantity("skill_frost")>0,sim.state.unlocked_stage>=3,counter("evolve")>0,skill_count()>=4,sim.state.unlocked_stage>=5,skill_count()>=6,sim.state.unlocked_stage>=7,sim.state.prestiges>0,sim.state.world_complete]
    for i in range(goals.size()):
        if goals[i] and not sim.state.main_claimed.has(i) and not sim.state.main_ready.has(str(i)):
            sim.state.main_ready[str(i)]=true
            # Change 15: a main objective waiting for its Claim earns the notification sound once.
            if i!=15 or sim.state.final_discovered:sim.notice.emit("main_ready",str(i))
func skill_count() -> int:
    var n=0
    for family in sim.catalog.skills:
        for id in sim.state.items:
            if sim.quantity(id)>0 and sim.catalog.items[id].get("skill","")==family:n+=1;break
    return n
func claim_main(i: int) -> bool:
    if not sim.action_lock_reason().is_empty() or not sim.state.main_ready.has(str(i)) or sim.state.main_claimed.has(i):return false
    var rewards: Array=sim.catalog.campaign.main_rewards
    var before: Dictionary=sim.state.duplicate(true)
    sim.state.coins+=rewards[i][0];sim.state.gems+=rewards[i][1];sim.state.main_claimed.append(i);sim.state.main_ready.erase(str(i))
    if i==15:sim.state.final_complete=true
    onboarding.evaluate()
    check_follow_mission()
    sim.touch()
    if not SaveService.save_now():sim.state=before;sim.touch();return false
    return true
## Change 79: skills join the offline item kinds (offline_skill unlock + offline_skill_rate). As for gear and
## supplies, only identities with stock at departure are eligible: offline time never discovers a skill and
## never changes what a skill does. An older snapshot without a "skill" entry simply grants none.
func offline_snapshot() -> Dictionary:
    var eligible: Dictionary={"weapon":[],"outfit":[],"consumable":[],"skill":[]}
    for id in sim.state.items:
        var kind: String=sim.catalog.items[id].kind
        if eligible.has(kind) and sim.quantity(id)>0 and not sim.is_legacy(id):eligible[kind].append(id)
    return {"time":maxf(sim.now_unix(),float(sim.state.get("offline_snapshot",{}).get("time",0))),"cap":[5,8,12,18,24,36,48][sim.level("offline_cap")]*3600,"coins":(120+60*sim.level("offline_coins"))*(1+bonus("offline_coins")),"gems":(2+.5*sim.level("offline_gems"))*(1+bonus("offline_gems")),"eligible":eligible,"rates":{"weapon":(1+.5*sim.level("offline_weapon_rate"))*sim.level("offline_weapon"),"outfit":(1+.5*sim.level("offline_outfit_rate"))*sim.level("offline_outfit"),"consumable":(2+sim.level("offline_consumable_rate"))*sim.level("offline_consumable"),"skill":(.5+.25*sim.level("offline_skill_rate"))*sim.level("offline_skill")},"items_bonus":1+bonus("offline_items"),"eligible_time":sim.state.prestige_batch.is_empty()}
## Background settlement only records what was earned: rewards wait in offline_pending (saved, merged
## across several absences, each interval capped as before) until the player claims them in game.
## Only the claim pays out and advances the offline counters that discover offline opportunities.
func settle_offline(now: float=-1) -> void:
    var snap: Dictionary=sim.state.get("offline_snapshot",{})
    if snap.is_empty():return
    if now<0:now=sim.now_unix()
    var elapsed=maxf(0,now-float(snap.time))
    if elapsed<2:return
    var before: Dictionary=sim.state.duplicate(true)
    var rng_before: int=sim.rng.state
    sim.state.offline_snapshot.time=maxf(now,float(snap.time))
    sim.state.offline_snapshot["settlement_id"]=str(int(now))
    if not snap.get("eligible_time",true):sim.touch();SaveService.save_now();return
    var hours=minf(elapsed,float(snap.cap))/3600.0
    var items: Dictionary={}
    for kind in snap.eligible:
        var ids: Array=snap.eligible[kind]
        if ids.is_empty():continue
        var credit=hours*float(snap.rates[kind])*float(snap.items_bonus)+float(sim.state.offline_remainders.get(kind,0))
        sim.state.offline_remainders[kind]=credit-floor(credit)
        for i in range(int(credit)):
            var id: String=ids[sim.rng.randi_range(0,ids.size()-1)]
            items[id]=int(items.get(id,0))+1
    var pending: Dictionary=sim.state.offline_pending
    if pending.is_empty():pending={"id":"","seconds":0.0,"longest":0.0,"rewarded_hours":0.0,"coins":0.0,"gems":0.0,"items":{}}
    pending.id=str(int(now))+"-"+str(sim.rng.randi())
    pending.seconds=float(pending.seconds)+elapsed
    pending.longest=maxf(float(pending.longest),elapsed)
    pending.rewarded_hours=float(pending.rewarded_hours)+hours
    pending.coins=float(pending.coins)+hours*float(snap.coins)
    pending.gems=float(pending.gems)+hours*float(snap.gems)
    for id in items:pending.items[id]=int(pending.items.get(id,0))+int(items[id])
    sim.state.offline_pending=pending
    sim.touch()
    if not SaveService.save_now():sim.state=before;sim.rng.state=rng_before;sim.touch()
## Pays the pending offline earnings once. The pending record is cleared in the same durable write,
## so a reload can never claim the same interval twice.
func claim_offline() -> bool:
    var pending: Dictionary=sim.state.get("offline_pending",{})
    if pending.is_empty():return false
    if not sim.action_lock_reason().is_empty():return sim.fail(sim.action_lock_reason())
    var before: Dictionary=sim.state.duplicate(true)
    sim.state.coins+=float(pending.coins);sim.state.gems+=float(pending.gems);sim.state.offline_income+=float(pending.coins)
    sim.state.offline_total+=float(pending.seconds);sim.state.offline_longest=maxf(sim.state.offline_longest,float(pending.longest))
    var granted: Dictionary={}
    for id in pending.items:
        if sim.catalog.items.has(id) and sim.add_item(id,int(pending.items[id])):granted[id]=int(pending.items[id])
    sim.state.offline_pending={}
    var receipt: Dictionary=pending.duplicate(true);receipt.items=granted
    evaluate();sim.touch()
    if not SaveService.save_now():sim.state=before;sim.touch();return false
    offline_receipt=receipt
    sim.event.emit("OFFLINE_CLAIMED")
    return true
## Previous builds earned one Supply Mastery level per three successful uses. A profile's
## permanent ranks and remaining partial uses must not decrease when the requirement rises to five.
## The previous Auto Evolution unlock also accepted bosses. Only bosses lose that upgrade.
## Refund each legacy boss purchase once while keeping normal-enemy Auto Evolution untouched.
## Change 76: owned camps became permanent. A profile that already prestiged lost its camps then; Map
## Mastery's lifetime record (mastery.camps, every camp ever owned, kept by Prestige) gives them back once.
func migrate_camps_permanent(out: Dictionary) -> void:
    var migrations: Array=out.get("migrations",[]) if out.get("migrations",[]) is Array else []
    if migrations.has("camps_permanent"):return
    var record=out.get("mastery",{}).get("camps",{}) if out.get("mastery") is Dictionary else {}
    if out.get("camps") is Dictionary and record is Dictionary:
        for key in record:
            if not str(key).is_valid_int() or int(key)<1 or int(key)>sim.catalog.stages.size() or not record[key] is Array:continue
            var owned: Array=[]
            if out.camps.get(str(key)) is Array:
                for camp in out.camps[str(key)]:
                    if number(camp):owned.append(int(camp))
            if not owned.has(0):owned.push_front(0)
            for camp in record[key]:
                if number(camp) and int(camp)>=0 and int(camp)<sim.catalog.stages[int(key)-1].spawns.size() and not owned.has(int(camp)):owned.append(int(camp))
            out.camps[str(key)]=owned
    migrations.append("camps_permanent")
    out.migrations=migrations

## Change 78 (once, state.migrations "boss_outfit_extras"): boss gear drops now include outfits. Every owned
## outfit that only bosses drop came from a boss (offline grants add copies of owned items only), so one with
## no boss attributes receives its two now, exactly as a boss copy collected under the new rule would (same
## pool, ranges and Treasure Sense). A boss's outfit still on the ground (any map) is marked to enhance when
## collected. Runs on the live state after validation, before anything else reads the inventory.
func migrate_boss_outfit_extras() -> void:
    var state: Dictionary=sim.state
    if not state.get("migrations") is Array or state.migrations.has("boss_outfit_extras"):return
    var ids: Array=state.items.keys();ids.sort()
    for id in ids:
        if boss_only_outfit(str(id)) and sim.quantity(str(id))>0:sim.enhance(str(id))
    var drops: Array=[state.pickups]
    for key in state.stage_worlds:drops.append(state.stage_worlds[key].get("pickups",[]))
    for list in drops:
        for p in list:
            if p.has("dropped") or not sim.catalog.items.has(str(p.item)) or str(sim.catalog.items[str(p.item)].kind)!="outfit":continue
            var g:=int(p.group)
            if g>=0 and g<sim.catalog.groups.size() and bool(sim.catalog.groups[g].boss):p.enhanced=true
    state.migrations.append("boss_outfit_extras")

## An outfit no ordinary enemy drops (each boss's own outfit).
func boss_only_outfit(id: String) -> bool:
    if not sim.catalog.items.has(id) or str(sim.catalog.items[id].kind)!="outfit":return false
    var groups: Array=sim.droppers(id)
    return not groups.is_empty() and groups.all(func(g):return bool(sim.catalog.groups[int(g)].boss))

## Change 76: Auto Buy selections from a save: AUTO_BUY_SLOTS entries, each a shop supply or "", never one
## supply twice (the later duplicate is cleared).
func normalize_auto_buy(out: Dictionary) -> void:
    var raw: Array=out.get("auto_buy") if out.get("auto_buy") is Array else []
    var picks: Array=[]
    for i in range(sim.AUTO_BUY_SLOTS):
        var id: String=str(raw[i]) if i<raw.size() and raw[i] is String else ""
        if id!="" and (not sim.auto_buy_eligible(id) or picks.has(id)):id=""
        picks.append(id)
    out.auto_buy=picks

func migrate_boss_auto_evolve(out: Dictionary) -> void:
    var migrations: Array=out.get("migrations",[]) if out.get("migrations",[]) is Array else []
    if migrations.has("boss_auto_evolve_refunded"):return
    if out.get("upgrades") is Dictionary:
        for key in out.upgrades.keys():
            var name: String=str(key)
            if not name.begins_with("auto_evolve:"):continue
            var part: String=name.trim_prefix("auto_evolve:")
            if not part.is_valid_int():continue
            var g:=int(part)
            if g<0 or g>=sim.catalog.groups.size() or not sim.catalog.groups[g].boss:continue
            if number(out.upgrades[key]) and int(out.upgrades[key])>0:
                out["gems"]=maxf(0,float(out.get("gems",0)))+int(sim.catalog.upgrades.auto_evolve.base)
            out.upgrades.erase(key)
    migrations.append("boss_auto_evolve_refunded")
    out.migrations=migrations

func migrate_supply_uses5(out: Dictionary) -> void:
    var migrations: Array=out.get("migrations",[]) if out.get("migrations",[]) is Array else []
    if migrations.has("supply_uses_5"):return
    if out.get("supply_uses") is Dictionary:
        for id in out.supply_uses:
            var uses=out.supply_uses[id]
            if number(uses) and float(uses)>=0:
                var old:=int(uses)
                out.supply_uses[id]=int(old/3)*5+old%3
    migrations.append("supply_uses_5")
    out.migrations=migrations

func normalize_snapshot(data: Dictionary) -> Dictionary:
    var out: Dictionary=data.duplicate(true)
    migrate_schema9(out)
    migrate_supply_uses5(out)
    migrate_boss_auto_evolve(out)
    migrate_camps_permanent(out)
    migrate_camp_supply_cooldowns(out)
    normalize_change17(out)
    guided.normalize(out)
    review.normalize(out)
    # Change 8 fields are derived for older current-schema saves, never copied from the live state.
    var change8: Array=[]
    for key in ["skills_seen","discovered_spots","camps_known"]:
        if not out.has(key):change8.append(key);out[key]=[] if key=="skills_seen" else {}
    # Change 16 (same schema 8): a boss already defeated counts as found, so an existing save never
    # replays the warning for it and keeps its Prestige unlock. follow_mission defaults to "".
    if not out.has("bosses_found"):
        var found: Array=[]
        if out.get("group_kills") is Array:
            for g in range(mini(out.group_kills.size(),sim.catalog.groups.size())):
                if sim.catalog.groups[g].boss and number(out.group_kills[g]) and float(out.group_kills[g])>0:found.append(str(sim.catalog.groups[g].id))
        out["bosses_found"]=found
    normalize_change61(out)
    # Change 82: the unsealing ceremony state is never copied from the live profile (an older save has not seen it).
    if not out.has("final_unsealed") or typeof(out.final_unsealed)!=TYPE_BOOL:out["final_unsealed"]=false
    # Change 83: the new introduction, the first celebration and the ending message are not implied by an older
    # unseal or victory; Game Completion's latched maxed upgrades start from what the save holds now.
    for key in ["final_warning_ok","final_experience","final_celebrated","final_ending_seen"]:
        if not out.has(key) or typeof(out[key])!=TYPE_BOOL:out[key]=false
    if not out.has("completion_maxed") or not out.completion_maxed is Array:out["completion_maxed"]=[]
    for key in sim.state:
        if not out.has(key):out[key]=sim.state[key].duplicate(true) if sim.state[key] is Dictionary or sim.state[key] is Array else sim.state[key]
    # Older schema-8 profiles have no expansion preferences. Ignore malformed/unknown keys.
    if not out.prestige_collapsed is Dictionary:out.prestige_collapsed={}
    for key in out.prestige_collapsed.keys():
        if not str(key).is_valid_int() or int(key)<0 or int(key)>sim.catalog.stages.size() or not out.prestige_collapsed[key] is bool:
            out.prestige_collapsed.erase(key)
    normalize_merge_memory(out)
    normalize_auto_buy(out)
    normalize_camp_supply(out)
    for field in ["schema","stage","unlocked_stage","spawn","player_level","prestiges","focus","focus_variant","next_pickup","next_cat","help","consumable_uses","fog_layout_revision"]:
        if number(out.get(field)):out[field]=int(out[field])
    # JSON decodes numbers as floats; Array.has uses strict Variant types.
    for field in ["spawns","auto_slots","main_claimed","group_kills"]:
        if out.get(field) is Array:
            for i in range(out[field].size()):
                if number(out[field][i]):out[field][i]=int(out[field][i])
    for field in ["camps","camps_known"]:
        if out.get(field) is Dictionary:
            for key in out[field]:
                if out[field][key] is Array:
                    for i in range(out[field][key].size()):
                        if number(out[field][key][i]):out[field][key][i]=int(out[field][key][i])
    var worlds: Array=[out]
    if out.get("stage_worlds") is Dictionary:worlds.append_array(out.stage_worlds.values())
    for world in worlds:
        if world is Dictionary and world.get("enemies") is Array:
            for actor in world.enemies:
                if actor is Dictionary:
                    for field in ["group","variant"]:
                        if number(actor.get(field)):actor[field]=int(actor[field])
    migrate_focus_global(out)
    migrate_camp_radius_global(out)
    migrate_final_intro(out)
    clamp_player_level(out)
    HelpCards.normalize(out)
    if out.get("upgrades") is Dictionary:
        for key in out.upgrades.keys():
            var parts: PackedStringArray=str(key).split(":")
            var g:=int(parts[1]) if parts.size()==2 else -1
            if not sim._upgrade_scope_valid(parts[0],g) or not number(out.upgrades[key]):out.upgrades.erase(key)
            else:out.upgrades[key]=clampi(int(out.upgrades[key]),0,int(sim.catalog.upgrades[parts[0]].cap))
    remap_legacy_items(out)
    clamp_equipment_slots(out)
    clamp_supplies(out)
    if out.get("items") is Dictionary:
        for id in out.items.keys():
            if not sim.catalog.items.has(id):out.items.erase(id)
        for field in ["gear","supplies","skills"]:
            if out.get(field) is Array:
                for i in range(out[field].size()):
                    if not out.items.has(out[field][i]):out[field][i]=""
        for field in ["weapon","outfit"]:
            if not out.items.has(out.get(field,"")):out[field]=""
    if int(out.get("fog_layout_revision",0))!=fog_rules.layout_revision:
        out.explored={};out.discovered={};out.fog_layout_revision=fog_rules.layout_revision
    # Change 24: saved masks decode to their in-memory bytes; a malformed one stays as it is, so
    # valid_snapshot rejects the profile.
    if out.get("explored") is Dictionary:
        for key in out.explored.keys():
            var mask:=decode_explored(int(key) if str(key).is_valid_int() else -1,out.explored[key])
            if not mask.is_empty():out.explored[key]=mask
    migrate_change8(out,change8)
    normalize_skill_assignments(out)
    migrate_legacy_weapons(out)
    return out
## Change 65 (same schema 9): Focused Farming moved from one purchase per enemy type ("focus:<g>") to one
## global Player upgrade ("focus"). A profile that owned it for at least one type owns the global rank
## (never charged again, no Gem refund); one that owned none stays at 0. The legacy per-type records are
## removed here, so no lookup can charge or unlock twice, and repeated loads are a no-op (an existing
## "focus" record is kept). Such a profile never replays the first-purchase Farm hint ("focus_unlocked").
## focus/focus_variant (the current farming choice) are not touched. legacy_focus_records reports how
## many per-type records the last migrated snapshot held (for probes and the implementation report).
var legacy_focus_records:=0
func migrate_focus_global(out: Dictionary) -> void:
    legacy_focus_records=0
    if not out.get("upgrades") is Dictionary:return
    var owned:=false
    for key in out.upgrades.keys():
        var parts: PackedStringArray=str(key).split(":")
        if parts.size()!=2 or parts[0]!="focus":continue
        if number(out.upgrades[key]) and int(out.upgrades[key])>0:owned=true;legacy_focus_records+=1
        out.upgrades.erase(key)
    if not owned:return
    out.upgrades["focus"]=1
    if out.get("tutorial") is Dictionary and out.tutorial.get("seen") is Array and not out.tutorial.seen.has("focus_unlocked"):
        out.tutorial.seen.append("focus_unlocked")
    if out.get("migrations") is Array and not out.migrations.has("focus_global"):out.migrations.append("focus_global")
## Change 81 (once, state.migrations "camp_radius_global"): Camp Reveal Radius was bought per camp
## ("camp_radius:<stage*10+camp>", Coins, up to 4 levels of +25%); it is now one global Gem upgrade of 3 levels for
## every camp. The profile keeps its best camp: global level = the highest per-camp level it owned, at most 3 (never
## charged again; no Coin or Gem refund, and every other owned camp gains that level for free). An existing global
## record is kept if higher. The per-camp records are removed, so nothing can be bought twice; later loads are a no-op.
## legacy_camp_radius reports the last migrated snapshot: {records, best, level}.
var legacy_camp_radius: Dictionary={}
func migrate_camp_radius_global(out: Dictionary) -> void:
    legacy_camp_radius={}
    var migrations: Array=out.get("migrations",[]) if out.get("migrations",[]) is Array else []
    if migrations.has("camp_radius_global") or not out.get("upgrades") is Dictionary:return
    var best:=0;var records:=0
    for key in out.upgrades.keys():
        var parts: PackedStringArray=str(key).split(":")
        if parts.size()!=2 or parts[0]!="camp_radius":continue
        records+=1
        if number(out.upgrades[key]):best=maxi(best,int(out.upgrades[key]))
        out.upgrades.erase(key)
    var cap:=int(sim.catalog.upgrades.camp_radius.cap)
    var level:=clampi(maxi(best,int(out.upgrades.get("camp_radius",0)) if number(out.upgrades.get("camp_radius",0)) else 0),0,cap)
    if level>0:out.upgrades["camp_radius"]=level
    legacy_camp_radius={"records":records,"best":best,"level":level}
    migrations.append("camp_radius_global")
    out.migrations=migrations
## Change 81 (once, "final_intro_seen"): a profile that met the Green Alien before this build already had the old
## discovery message, so the new introduction is acknowledged for it (it never pops up on load); its tracker shows.
func migrate_final_intro(out: Dictionary) -> void:
    var migrations: Array=out.get("migrations",[]) if out.get("migrations",[]) is Array else []
    if migrations.has("final_intro_seen"):return
    if bool(out.get("final_discovered",false)) and out.get("tutorial") is Dictionary and out.tutorial.get("seen") is Array and not out.tutorial.seen.has("final_intro"):
        out.tutorial.seen.append("final_intro")
    migrations.append("final_intro_seen")
    out.migrations=migrations
## Change 81: the level cap fell from 1000 to 500. A profile above it is set to the cap (its stats follow from the
## level, so they are those of level 500); XP beyond the cap is not kept (at the cap XP stays 0, as before).
var clamped_player_level:=-1
func clamp_player_level(out: Dictionary) -> void:
    clamped_player_level=-1
    if not number(out.get("player_level")):return
    if int(out.player_level)>sim.max_level():
        clamped_player_level=int(out.player_level)
        out.player_level=sim.max_level();out.xp=0.0
## Change 61 (same schema 9): the per-stage respawn choice and the one-time 30-defeat mission. A save from
## before has neither: respawns starts empty (the current stage keeps its "spawn"), the mission starts
## locked and unlocks on the next tick if the Snowman was already found (counting defeats from then on).
## Malformed values are repaired here, so a valid save is never rejected for them.
func normalize_change61(out: Dictionary) -> void:
    var respawns: Dictionary={}
    if out.get("respawns") is Dictionary:
        for key in out.respawns:
            if str(key).is_valid_int() and int(key) in range(1,sim.catalog.stages.size()+1) and number(out.respawns[key]):
                var camp:=int(out.respawns[key])
                if camp in range(sim.catalog.stages[int(key)-1].spawns.size()):respawns[str(int(key))]=camp
    out["respawns"]=respawns
    var h: Dictionary=hunt_initial()
    if out.get("hunt") is Dictionary:
        h.unlocked=out.hunt.get("unlocked",false)==true
        h.claimed=out.hunt.get("claimed",false)==true and h.unlocked
        h.progress=clampf(float(out.hunt.progress),0.0,HUNT_GOAL) if number(out.hunt.get("progress")) and h.unlocked else 0.0
    out["hunt"]=h
## Change 51 (once, state.migrations "legacy_weapons_h24"): every owned weapon of the previous stat table
## whose new stats are lower (tiers 2-7) becomes its "<id>_legacy" copy: the same quantity, merge level,
## rolled attributes, equip slot and Auto-Merge choice, the old stats, no evolution. It leaves with the
## inventory at the next Prestige. The canonical id's merge memory keeps the copy's level, so finding that
## weapon again gives the new stats at the original merge level. A spent stack's record (no copy) stays
## canonical. Offline snapshots stop offering converted ids (offline grants copy owned canonical gear only).
func migrate_legacy_weapons(out: Dictionary) -> void:
    if not out.get("migrations") is Array or out.migrations.has("legacy_weapons_h24"):return
    out.migrations.append("legacy_weapons_h24")
    if not out.get("items") is Dictionary:return
    if not out.get("merge_memory") is Dictionary:out.merge_memory={}
    var moved: Dictionary={}
    for id in out.items.keys():
        var r=out.items[id]
        var legacy_id: String=str(id)+"_legacy"
        if not sim.catalog.items.has(legacy_id) or not r is Dictionary or not number(r.get("qty")) or int(r.qty)<1:continue
        var level:=int(r.get("merge",0)) if number(r.get("merge")) else 0
        out.merge_memory[id]=maxi(int(out.merge_memory.get(id,0)),mini(level,sim.merge_validation_cap(id)))
        out.items.erase(id);out.items[legacy_id]=r
        moved[id]=legacy_id
    if moved.is_empty():return
    for field in ["weapon","outfit"]:
        if moved.has(str(out.get(field,""))):out[field]=moved[out[field]]
    if out.get("gear") is Array:
        for i in range(out.gear.size()):
            if moved.has(str(out.gear[i])):out.gear[i]=moved[out.gear[i]]
    var snap=out.get("offline_snapshot",{})
    if snap is Dictionary and snap.get("eligible") is Dictionary and snap.eligible.get("weapon") is Array:
        snap.eligible.weapon=snap.eligible.weapon.filter(func(i):return not moved.has(str(i)))
## Change 50 (schema 9): a schema 8 save gains the permanent merge memory. Each item identity remembers
## the highest valid merge level seen in its current record and in Map Mastery's best-merge record
## (mastery.merge, kept by every earlier Prestige), so levels lost to older Prestiges are restored. No
## copy is added: an item the player does not own still grants nothing. Records the player holds now
## (owned, or a spent stack's record) rise to their remembered level. Runs once (state.migrations).
func migrate_schema9(out: Dictionary) -> void:
    if not number(out.get("schema")) or int(out.schema)!=8:return
    var memory: Dictionary={}
    var sources: Array=[]
    if out.get("items") is Dictionary:
        for id in out.items:
            if out.items[id] is Dictionary:sources.append([id,out.items[id].get("merge")])
    if out.get("mastery") is Dictionary and out.mastery.get("merge") is Dictionary:
        for id in out.mastery.merge:sources.append([id,out.mastery.merge[id]])
    var legacy: Dictionary=sim.catalog.legacy_items
    for pair in sources:
        var id: String=str(legacy.get(pair[0],pair[0]))
        if not sim.catalog.items.has(id) or sim.catalog.items[id].kind=="consumable" or bool(sim.catalog.items[id].get("legacy",false)):continue
        if not number(pair[1]) or float(pair[1])<=0:continue
        var level:=mini(int(pair[1]),sim.merge_validation_cap(id))
        memory[id]=maxi(int(memory.get(id,0)),level)
    if out.get("items") is Dictionary:
        for id in out.items:
            var r=out.items[id]
            if r is Dictionary and memory.has(id) and number(r.get("merge")) and int(r.merge)<int(memory[id]):r.merge=memory[id]
    out.merge_memory=memory
    out.migrations=["schema9_merge_memory"]
    out.schema=9
## Current-schema bounds for the merge memory: known, non-supply, non-legacy ids with whole levels
## inside the validation cap; anything else is dropped (never the profile).
func normalize_merge_memory(out: Dictionary) -> void:
    if not out.get("merge_memory") is Dictionary:out.merge_memory={}
    for id in out.merge_memory.keys():
        var v=out.merge_memory[id]
        if not sim.catalog.items.has(id) or sim.catalog.items[id].kind=="consumable" or bool(sim.catalog.items[id].get("legacy",false)) or not number(v) or float(v)<=0:
            out.merge_memory.erase(id)
        else:out.merge_memory[id]=mini(int(v),sim.merge_validation_cap(id))
    if not out.get("migrations") is Array:out.migrations=[]
    out.migrations=out.migrations.filter(func(m):return m is String)
## Change 10 bound: the equipment row has exactly 3 + purchased slots (at most 70). Surplus empty
## slots go first (from the end); items still beyond the bound are dropped with their record.
func clamp_equipment_slots(out: Dictionary) -> void:
    if not out.get("gear") is Array:return
    var bought: int=int(out.upgrades.get("gear_slots",0)) if out.get("upgrades") is Dictionary else 0
    var size: int=3+bought*int(sim.catalog.upgrades.gear_slots.effect)
    var gear: Array=out.gear
    var i: int=gear.size()-1
    while gear.size()>size and i>=0:
        if not gear[i] is String or gear[i]=="":gear.remove_at(i)
        i-=1
    while gear.size()>size:
        var id=gear.pop_back()
        if id is String and out.get("items") is Dictionary:out.items.erase(id)
    while gear.size()<size:gear.append("")
## Change 11 bound: the supply row has exactly 1 + purchased slots (one per supply identity), automated
## slots point inside it, mastery counts and buffs name real supplies. Saves made before Change 11
## keep their stock (tier copies fold into the base supply) and start mastery at zero.
func clamp_supplies(out: Dictionary) -> void:
    var bought: int=int(out.upgrades.get("supply_slots",0)) if out.get("upgrades") is Dictionary else 0
    var size: int=1+bought*int(sim.catalog.upgrades.supply_slots.effect)
    if out.get("supplies") is Array:
        var list: Array=out.supplies
        var kept: Array=[]
        for id in list:
            if id is String and id!="" and sim.catalog.items.has(id) and sim.catalog.items[id].kind=="consumable" and not kept.has(id):kept.append(id)
        while kept.size()>size:
            var id=kept.pop_back()
            if out.get("items") is Dictionary:out.items.erase(id)
        # Keep each supply where it was when it still fits, so automated slots stay bound to it.
        var row: Array=[];row.resize(size);row.fill("")
        for id in kept:
            var at: int=list.find(id)
            if at>=0 and at<size and row[at]=="":row[at]=id
        for id in kept:
            if not row.has(id):row[row.find("")]=id
        out.supplies=row
    if out.get("auto_slots") is Array:
        var slots: Array=[]
        for slot in out.auto_slots:
            if number(slot) and int(slot)>=0 and int(slot)<size and not slots.has(int(slot)):slots.append(int(slot))
        out.auto_slots=slots.slice(0,int(out.upgrades.get("auto_use",0)))
    for field in ["supply_found","buffs"]:
        if not out.get(field) is Dictionary:out[field]={}
        for id in out[field].keys():
            if not sim.catalog.items.has(id) or sim.catalog.items[id].kind!="consumable":out[field].erase(id)
    for id in out.supply_found.keys():
        out.supply_found[id]=maxi(0,int(out.supply_found[id])) if number(out.supply_found[id]) else 0
    for id in out.buffs.keys():
        var b=out.buffs[id]
        if id=="coin_boost" or not b is Dictionary or not number(b.get("time")) or not number(b.get("power")) or float(b.time)<=0:out.buffs.erase(id)
## Older saves: skills already owned (or upgraded) count as seen, without a notice; spots of known
## types whose home cell was explored become found spots; explored or owned camps are sighted.
## Explored cells are kept as they are (no new reveal, no reset).
func migrate_change8(out: Dictionary,missing: Array) -> void:
    if missing.has("skills_seen") and out.get("items") is Dictionary:
        for id in out.items:
            var family: String=str(sim.catalog.items[id].get("skill",""))
            if family!="" and not out.skills_seen.has(family):out.skills_seen.append(family)
        if out.get("upgrades") is Dictionary:
            for key in out.upgrades:
                var family: String=str(key).trim_prefix("cooldown_")
                if str(key).begins_with("cooldown_") and int(out.upgrades[key])>0 and not out.skills_seen.has(family):out.skills_seen.append(family)
    var explored: Dictionary=out.get("explored",{}) if out.get("explored") is Dictionary else {}
    var cell: float=fog_rules.cell_size
    if missing.has("discovered_spots") and out.get("discovered") is Dictionary:
        for key in out.discovered:
            var g:=int(key)
            if g<0 or g>=sim.catalog.groups.size():continue
            var st:=int(sim.catalog.groups[g].stage)
            var cells:=decode_explored(st,explored.get(str(st)))
            if cells.is_empty():continue
            for v in variants(g):
                var at:=spot(g,v)
                if cells[floori(at.y/cell)*fog_columns(st)+floori(at.x/cell)]!=0:out.discovered_spots[spot_key(g,v)]=true
    if missing.has("camps_known"):
        for st in range(1,9):
            var cells:=decode_explored(st,explored.get(str(st)))
            if cells.is_empty():continue
            var known: Array=[]
            for i in range(sim.catalog.stages[st-1].spawns.size()):
                var a: Array=sim.catalog.stages[st-1].spawns[i]
                if cells[floori(float(a[1])/cell)*fog_columns(st)+floori(float(a[0])/cell)]!=0:known.append(i)
            if not known.is_empty():out.camps_known[str(st)]=known
## Change 7 replaced per-enemy weapons with shared families: a small deterministic map
## (catalog.legacy_items) moves current-schema saves onto the new ids. Stacks join (quantities add,
## the best merge level stays) and every reference follows; unknown ids are dropped as before.
func remap_legacy_items(out: Dictionary) -> void:
    var legacy: Dictionary=sim.catalog.legacy_items
    if out.get("items") is Dictionary:
        for id in out.items.keys():
            if not legacy.has(id) or not out.items[id] is Dictionary:continue
            var r: Dictionary=out.items[id];out.items.erase(id)
            var target: String=legacy[id]
            if out.items.get(target) is Dictionary:
                var t: Dictionary=out.items[target]
                t.qty=float(t.get("qty",0))+float(r.get("qty",0));t.merge=maxf(float(t.get("merge",0)),float(r.get("merge",0)))
            else:out.items[target]=r
    for field in ["gear","supplies","skills"]:
        if out.get(field) is Array:
            var seen: Dictionary={}
            for i in range(out[field].size()):
                var id=_legacy_id(out[field][i],legacy)
                if id is String and id!="" and seen.has(id):id=""
                if id is String and id!="":seen[id]=true
                out[field][i]=id
    for field in ["weapon","outfit"]:out[field]=_legacy_id(out.get(field,""),legacy)
    var drops: Array=[out.get("pickups",[])]
    if out.get("stage_worlds") is Dictionary:
        for w in out.stage_worlds.values():
            if w is Dictionary:drops.append(w.get("pickups",[]))
    for list in drops:
        if list is Array:
            for d in list:
                if d is Dictionary:d.item=_legacy_id(d.get("item",""),legacy)
    if out.get("history") is Array:
        var kept: Array=[]
        for e in out.history:
            if not e is Dictionary:continue
            e.id=_legacy_id(str(e.get("id","")),legacy)
            if e.id=="" or sim.catalog.items.has(e.id):kept.append(e)
        out.history=kept
    for field in ["online_items","counters"]:
        if out.get(field) is Dictionary:out[field]=_remap_keys(out[field],legacy,false)
    if out.get("opportunities") is Dictionary:
        for id in out.opportunities:
            if out.opportunities[id] is Dictionary:out.opportunities[id]=_remap_keys(out.opportunities[id],legacy,true)
    var snap=out.get("offline_snapshot",{})
    if snap is Dictionary and snap.get("eligible") is Dictionary:
        for kind in snap.eligible:
            if snap.eligible[kind] is Array:
                var ids: Array=[]
                for id in snap.eligible[kind]:
                    var mapped=_legacy_id(id,legacy)
                    if not ids.has(mapped):ids.append(mapped)
                snap.eligible[kind]=ids
    var pending=out.get("offline_pending",{})
    if pending is Dictionary and pending.get("items") is Dictionary:pending.items=_remap_keys(pending.items,legacy,false)
func _legacy_id(id,legacy: Dictionary):
    return legacy.get(id,id) if id is String else id
## Re-keys "<id>", "<kind>:<id>" and "<prefix>_<id>" entries; numeric values join (merge keys keep the max).
func _remap_keys(source: Dictionary,legacy: Dictionary,prefixed: bool) -> Dictionary:
    var result: Dictionary={}
    for key in source:
        var k: String=str(key);var value=source[key]
        var renamed:=k
        if legacy.has(k):renamed=legacy[k]
        elif ":" in k and legacy.has(k.get_slice(":",1)):renamed=k.get_slice(":",0)+":"+legacy[k.get_slice(":",1)]
        elif prefixed:
            for prefix in ["item_","merge_"]:
                if k.begins_with(prefix) and legacy.has(k.trim_prefix(prefix)):renamed=prefix+legacy[k.trim_prefix(prefix)]
        if result.has(renamed) and number(result[renamed]) and number(value):
            result[renamed]=maxf(result[renamed],value) if renamed.begins_with("merge_") else result[renamed]+value
        else:result[renamed]=value
    return result
func valid_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema",0))!=sim.SCHEMA or not finite_tree(data):return false
    for key in sim.state:
        if not data.has(key):return false
        var a: int=typeof(sim.state[key]);var b: int=typeof(data[key])
        if a in [TYPE_INT,TYPE_FLOAT]:
            if b not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(data[key])):return false
        elif a!=b:return false
    if not data.tutorial.has_all(["mode","done","seen"]) or data.tutorial.mode not in ["pending","guided","basic","none"] or not data.tutorial.done is Array or not data.tutorial.seen is Array:return false
    if not onboarding_valid(data.onboarding) or not mastery_valid(data.mastery):return false
    if not str(data.review.get("status","")) in review.STATUSES:return false
    for id in data.bosses_found:
        var g=group_id(str(id))
        if g<0 or not sim.catalog.groups[g].boss or data.bosses_found.count(id)!=1:return false
    if data.stage<1 or data.stage>8 or data.unlocked_stage<data.stage or data.unlocked_stage>8:return false
    if data.coins<0 or data.gems<0 or data.group_kills.size()!=48 or data.collect_clocks.size()!=48:return false
    if data.skills.size()!=3 or data.skill_auto.size()!=3:return false
    if data.gear.size()!=3+int(data.upgrades.get("gear_slots",0))*int(sim.catalog.upgrades.gear_slots.effect) or data.supplies.size()!=1+int(data.upgrades.get("supply_slots",0))*int(sim.catalog.upgrades.supply_slots.effect):return false
    for id in data.supplies:
        if id!="" and sim.catalog.items[id].kind!="consumable":return false
    for id in data.gear:
        if id!="" and sim.catalog.items[id].kind=="consumable":return false
    for id in data.supply_found:
        if not sim.catalog.items.has(id) or sim.catalog.items[id].kind!="consumable" or not number(data.supply_found[id]) or data.supply_found[id]<0:return false
    for id in data.items:
        if not sim.catalog.items.has(id) or not data.items[id] is Dictionary:return false
        var r: Dictionary=data.items[id]
        if r.has("boss_extras") and not boss_extras_valid(id,r.boss_extras):return false
        if not r.has_all(["qty","merge","extras"]) or r.qty<0 or r.qty!=floor(r.qty) or r.merge<0 or r.merge>sim.merge_validation_cap(id):return false
    for id in data.merge_memory:
        if not sim.catalog.items.has(id) or not number(data.merge_memory[id]) or data.merge_memory[id]<0 or data.merge_memory[id]>sim.merge_validation_cap(id):return false
    for id in data.gear+data.supplies:
        if id!="" and (not data.items.has(id) or data.items[id].qty<=0):return false
    for key in data.upgrades:
        var parts: PackedStringArray=key.split(":");var g: int=int(parts[1]) if parts.size()==2 else -1
        if not sim._upgrade_scope_valid(parts[0],g) or data.upgrades[key]<0 or data.upgrades[key]>sim.catalog.upgrades[parts[0]].cap:return false
    var opportunity_ids: Array=[]
    for op in sim.catalog.campaign.opportunities:opportunity_ids.append(op.id)
    for id in data.opportunities:
        if not opportunity_ids.has(id) or not data.opportunities[id] is Dictionary or not data.opportunities[id].get("baseline",null) is Dictionary or not data.opportunities[id].get("ready",null) is bool:return false
    for id in data.consumed:
        if not opportunity_ids.has(id) or data.consumed.count(id)!=1:return false
    for id in data.owned_cards:
        if not sim.catalog.campaign.cards.has(id) or data.owned_cards.count(id)!=1:return false
    for key in ["player","enemies","items","stage_worlds","prestige_batch","explored","camps","offline_snapshot","missions"]:
        if not data.has(key):return false
    if not actor_valid(data.player,true):return false
    for actor in data.enemies:
        if not actor_valid(actor,false) or sim.catalog.groups[int(actor.group)].stage!=data.stage:return false
    for key in data.stage_worlds:
        if not str(key).is_valid_int() or int(key) not in range(1,9):return false
        var w=data.stage_worlds[key]
        if not w is Dictionary or not w.get("enemies",null) is Array or not w.get("pickups",null) is Array:return false
        for actor in w.enemies:
            if not actor_valid(actor,false) or sim.catalog.groups[int(actor.group)].stage!=int(key):return false
        if not drops_valid(w.pickups):return false
    if not drops_valid(data.pickups):return false
    for id in data.keys:
        var g=group_id(str(id))
        if g<0 or not sim.catalog.groups[g].boss or sim.catalog.groups[g].final or data.keys.count(id)!=1:return false
    for id in data.skills:
        if id!="" and (not sim.catalog.items.has(id) or sim.catalog.items[id].kind!="skill" or data.items.get(id,{}).get("qty",0)<1):return false
    for key in data.explored:
        if not str(key).is_valid_int() or int(key) not in range(1,9) or decode_explored(int(key),data.explored[key]).is_empty():return false
    for key in data.camps:
        if int(key) not in range(1,9) or not data.camps[key] is Array:return false
        for camp in data.camps[key]:
            if not number(camp) or int(camp) not in range(sim.catalog.stages[int(key)-1].spawns.size()):return false
    if int(data.spawn) not in range(sim.catalog.stages[int(data.stage)-1].spawns.size()):return false
    for m in data.missions:
        if not m is Dictionary or not m.has_all(["kind","target","goal","progress","coins","gems","claimed","day"]):return false
        for key in ["goal","progress","coins","gems"]:
            if not number(m[key]) or m[key]<0:return false
    var snap: Dictionary=data.offline_snapshot
    if not snap.is_empty():
        if not snap.has_all(["time","cap","coins","gems","eligible","rates","items_bonus"]):return false
        for key in ["time","cap","coins","gems","items_bonus"]:
            if not number(snap[key]) or snap[key]<0:return false
        if not snap.eligible is Dictionary or not snap.rates is Dictionary:return false
        for kind in ["weapon","outfit","consumable"]:
            if not snap.eligible.get(kind,null) is Array or not number(snap.rates.get(kind,null)):return false
            for id in snap.eligible[kind]:
                if not sim.catalog.items.has(id) or sim.catalog.items[id].kind!=kind:return false
    var pending: Dictionary=data.offline_pending
    if not pending.is_empty():
        if not pending.has_all(["id","seconds","longest","rewarded_hours","coins","gems","items"]) or not pending.items is Dictionary:return false
        for key in ["seconds","longest","rewarded_hours","coins","gems"]:
            if not number(pending[key]) or pending[key]<0:return false
        for id in pending.items:
            if not sim.catalog.items.has(id) or not number(pending.items[id]) or pending.items[id]<0:return false
    var batch: Dictionary=data.prestige_batch
    if not batch.is_empty():
        if not batch.get("ids",null) is Array or not batch.get("choices",null) is Array or batch.ids.is_empty() or batch.choices.size()>=batch.ids.size():return false
        for i in range(batch.ids.size()):
            var opid=batch.ids[i]
            if not data.opportunities.has(opid) or not data.opportunities[opid].get("ready",false) or data.consumed.has(opid):return false
            if i<batch.choices.size():
                var id=batch.choices[i]
                if not sim.catalog.campaign.cards.has(id) or data.owned_cards.has(id) or batch.choices.count(id)!=1 or not str(id).begins_with(str(opid).split("_o")[0]+"_c"):return false
    return true
## Change 15 profile records (schema 8).
func onboarding_valid(o) -> bool:
    if not o is Dictionary or not o.get("reveal",null) is Array or not number(o.get("loot_phase",null)) or not number(o.get("loot_kills",null)):return false
    for f in o.reveal:
        if not onboarding.FEATURES.has(f) or o.reveal.count(f)!=1:return false
    return int(o.loot_phase) in range(4) and o.loot_kills>=0
func mastery_valid(m) -> bool:
    if not m is Dictionary:return false
    for key in ["explored","camps","found","merge","evolved"]:
        if not m.get(key,null) is Dictionary:return false
    if not m.get("done",null) is Array:return false
    for id in m.found.keys()+m.merge.keys()+m.evolved.keys():
        if not sim.catalog.items.has(id):return false
    for key in m.explored.keys()+m.camps.keys():
        if not str(key).is_valid_int() or int(key) not in range(1,9):return false
    for key in m.explored:
        if not number(m.explored[key]) or m.explored[key]<0 or m.explored[key]>100:return false
    for key in m.merge:
        if not number(m.merge[key]) or m.merge[key]<0:return false
    for key in m.camps:
        if not m.camps[key] is Array:return false
        for camp in m.camps[key]:
            if not number(camp) or int(camp) not in range(sim.catalog.stages[int(key)-1].spawns.size()):return false
    return true
func number(value) -> bool:return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))
func finite_tree(value) -> bool:
    if value is Dictionary:
        for child in value.values():
            if not finite_tree(child):return false
    elif value is Array:
        for child in value:
            if not finite_tree(child):return false
    elif typeof(value)==TYPE_FLOAT:return is_finite(value)
    return true
func actor_valid(a,player: bool) -> bool:
    if not a is Dictionary or not a.has_all(["id","x","y","home_x","home_y","hp","group","respawn","dead_age","cooldown","windup","target","attack_age","hurt","quiet","aggro","returning","moving","facing"]):return false
    for key in ["x","y","hp","group","respawn","dead_age","cooldown","windup","attack_age","hurt","quiet","facing"]:
        if not number(a[key]):return false
    if player:return a.id=="player" and a.has("idle")
    return int(a.group) in range(sim.catalog.groups.size()) and int(a.get("variant",-1)) in variants(int(a.group))
## Change 52: at most two boss slots, each a stat of the item's pool held by no other slot.
func boss_extras_valid(id: String,slots) -> bool:
    if not slots is Array or slots.size()>sim.BOSS_EXTRA_SLOTS:return false
    var seen: Array=[]
    for e in slots:
        if not e is Dictionary or not sim.catalog.items[id].extras.has(str(e.get("stat",""))) or not number(e.get("value")) or seen.has(str(e.stat)):return false
        seen.append(str(e.stat))
    return true
func drops_valid(drops) -> bool:
    if not drops is Array:return false
    for d in drops:
        if not d is Dictionary or not d.has_all(["uid","item","x","y","ttl","group"]):return false
        # Change 16: a stack the player dropped has no source enemy (group -1), a quantity and the
        # online credit it carries back (simulation.discard).
        var dropped: bool=d.has("dropped")
        if dropped and (not d.dropped is Dictionary or not number(d.dropped.get("online")) or not d.dropped.get("ops") is Dictionary):return false
        if not sim.catalog.items.has(d.item) or not number(d.group) or int(d.group) not in (range(-1,0) if dropped else range(sim.catalog.groups.size())):return false
        if d.has("qty") and (not number(d.qty) or int(d.qty)<1):return false
        if d.has("enhanced") and not d.enhanced is bool:return false
        for key in ["uid","x","y","ttl"]:
            if not number(d[key]):return false
    return true

func opportunity_progress(id: String) -> String:
    var o: Dictionary=sim.state.opportunities.get(id,{})
    if o.is_empty():return ""
    if o.ready:return sim.tr("PRESTIGE_READY")
    var n=int(id.right(1));var path=id.split("_o")[0]
    if path in ["expedition","specialist"]:
        var chain=chain_for(id);var index=int(o.get("step",0))
        if index<chain.size():
            var q: Array=chain[index]
            # Localization Batch 01: one whole goal phrase with the translated enemy name (it was the
            # goal word plus a name made from the id, which no other language can reorder).
            var g:=group_id(str(q[1]))
            var goal: String=sim.tr("CHAIN_GOAL_KILL_TARGET") % str(sim.catalog.groups[g].name) if g>=0 else sim.tr("GOAL_"+str(q[0]).to_upper())
            return sim.tr("CHAIN_PROGRESS") % [index+1,chain.size(),goal,int(o.get("count",0)),int(q[2])]
    if path=="hunter":
        var got:=0
        for boss in hunter_bosses(n):got+=mini(hunter_count(o,boss),hunter_goal(n))
        return "%d / %d" % [got,hunter_goal(n)*hunter_bosses(n).size()]
    if path=="offline":
        var value=sim.state.offline_total/3600 if n==1 else (sim.state.offline_longest/3600 if n==2 else sim.state.offline_income)
        # Change 13: the offline-income milestone counts coins, so it uses the currency format.
        if n==3:return "%s / %s" % [NumberFormat.currency(value),NumberFormat.currency(10000,true)]
        return "%.1f / %d" % [value,[72,24,10000][n-1]]
    if path=="offering":return sim.tr("OFFERING_PROGRESS") % [NumberFormat.currency(minf(sim.state.online_coins,sim.state.coins)),NumberFormat.currency([2000,20000,100000][n-1],true),NumberFormat.currency(minf(sim.state.online_gems,sim.state.gems)),NumberFormat.currency([30,100,300][n-1],true)]
    if path=="masterwork":return sim.tr("PROGRESS_MERGE") % masterwork_best(o,n)
    if path=="arsenal":
        var counts:=arsenal_counts(o,n);var need:=arsenal_need(n)
        return sim.tr("PROGRESS_ARSENAL_SPLIT") % [mini(counts[0],need),need,mini(counts[1],need),need]
    if path=="trophy":
        var bosses:=trophy_bosses(n)
        var got:=0
        for boss in bosses:
            if o.get("trophy_boss-"+boss,false):got+=1
        return sim.tr("PROGRESS_TROPHY") % [got,bosses.size()]
    if path=="collection":
        var names:=collection_names(n)
        # The full panel is the detailed reference: each required outfit by name with its count.
        var parts: Array=[]
        var counts:=collection_counts(id)
        for i in range(names.size()):
            parts.append("%s %d/%d" % [sim.catalog.display_name(contract_outfit(names[i])),counts[i],collection_required(n)])
        return sim.tr("PROGRESS_COLLECTION") % " · ".join(parts)
    if path=="challenge":return sim.tr("PROGRESS_CHALLENGE")
    if path=="regional":return _regional_progress(n)
    return sim.tr("IN_PROGRESS")

## Change 16: the followed opportunity in plain words, for the HUD tracker and the Prestige panel.
## Line 1 says what to do now, with the enemy, item or map and the current / required progress;
## line 2 ("Next: …" or "Then …") says what follows when there is a next requirement. Collection
## contracts name the exact item (the tracker also shows its icon, follow_focus). Supersedes the
## Change 11 rule that hid the required outfits.
## compact (Change 71, the HUD tracker): only the current actionable step and its progress, no "Next:" line.
func follow_summary(id: String,compact:=false) -> String:
    var o: Dictionary=sim.state.opportunities.get(id,{})
    if o.is_empty():return ""
    if o.ready:return sim.tr("FOLLOW_READY")
    var n=int(id.right(1));var path=id.split("_o")[0]
    match path:
        "expedition","specialist":
            var chain=chain_for(id);var index=int(o.get("step",0))
            if index>=chain.size():return sim.tr("FOLLOW_READY")
            var line: String=sim.tr("FOLLOW_STEP") % [index+1,chain.size(),_chain_goal(chain[index]),int(o.get("count",0)),int(chain[index][2])]
            if index+1<chain.size() and not compact:line+="\n"+sim.tr("FOLLOW_NEXT") % (_chain_goal(chain[index+1])+" ×%d" % int(chain[index+1][2]))
            return line
        "collection":
            var goal:=collection_required(n)
            var counts:=collection_counts(id)
            var names:=collection_names(n)
            var open: Array=[]
            for i in range(counts.size()):
                if counts[i]<goal:open.append(i)
            if open.is_empty():return sim.tr("FOLLOW_COLLECTION_SUBMIT")
            var item: String=contract_outfit(names[open[0]])
            var g:=group_id("unit-"+names[open[0]])
            var line: String=sim.tr("FOLLOW_COLLECT") % [counts.size()-open.size()+1,counts.size(),sim.catalog.display_name(item),_group_place(g),counts[open[0]],goal]
            if open.size()>1 and not compact:line+="\n"+sim.tr("FOLLOW_NEXT") % sim.catalog.display_name(contract_outfit(names[open[1]]))
            return line
        "hunter":
            # The first boss still short of its count (Hunter IV names two).
            for boss in hunter_bosses(n):
                if hunter_count(o,boss)<hunter_goal(n) or boss==hunter_bosses(n).back():
                    return sim.tr("FOLLOW_HUNT") % [_group_place(group_id(boss)),mini(hunter_count(o,boss),hunter_goal(n)),hunter_goal(n)]
        "challenge":
            return sim.tr("FOLLOW_CHALLENGE") % _group_place(group_id(boss_goal(path,n)))
        "trophy":
            var bosses:=trophy_bosses(n)
            var open: Array=[]
            for boss in bosses:
                if not o.get("trophy_boss-"+boss,false):open.append(boss)
            var line: String=sim.tr("FOLLOW_TROPHY") % [_group_place(group_id("boss-"+str(open[0]))),bosses.size()-open.size(),bosses.size()]
            if open.size()>1 and not compact:line+="\n"+sim.tr("FOLLOW_NEXT") % _group_place(group_id("boss-"+str(open[1])))
            return line
        "masterwork":
            var best:=masterwork_best(o,n)
            if n==4:return sim.tr("FOLLOW_MASTERWORK_OBSIDIAN") % best
            return sim.tr("FOLLOW_MASTERWORK_ANY_GEAR" if n==1 else "FOLLOW_MASTERWORK_TIER_GEAR") % ([best] if n==1 else [n,best])
        "arsenal":
            var counts:=arsenal_counts(o,n);var need:=arsenal_need(n)
            var key:="FOLLOW_ARSENAL_SPLIT_T2" if n==3 else "FOLLOW_ARSENAL_SPLIT"
            return sim.tr(key) % [mini(counts[0],need),need,mini(counts[1],need),need]
        "regional":return _regional_follow(n)
        "offering":
            var coins: int=[2000,20000,100000][n-1];var gems: int=[30,100,300][n-1]
            var have_coins:=minf(sim.state.online_coins,sim.state.coins);var have_gems:=minf(sim.state.online_gems,sim.state.gems)
            var line: String=sim.tr("FOLLOW_OFFERING") % [NumberFormat.currency(have_coins),NumberFormat.currency(coins,true),NumberFormat.currency(have_gems),NumberFormat.currency(gems,true)]
            if have_coins>=coins and have_gems>=gems:line+="\n"+sim.tr("FOLLOW_SUBMIT")
            return line
        "offline":
            if n==3:return sim.tr("FOLLOW_OFFLINE_INCOME") % [NumberFormat.currency(sim.state.offline_income),NumberFormat.currency(10000,true)]
            return sim.tr("FOLLOW_OFFLINE_TOTAL" if n==1 else "FOLLOW_OFFLINE_LONGEST") % (sim.state.offline_total/3600.0 if n==1 else sim.state.offline_longest/3600.0)
    return opportunity_progress(id)

## Change 72: the followed opportunity's current requirement as a short count for the HUD pill ("3/100"), from
## the same state as follow_summary; "" where the requirement has no single count (the pill shows its title).
func follow_progress(id: String) -> String:
    var o: Dictionary=sim.state.opportunities.get(id,{})
    if o.is_empty() or o.ready:return ""
    var n=int(id.right(1));var path=id.split("_o")[0]
    match path:
        "expedition","specialist":
            var chain=chain_for(id);var index=int(o.get("step",0))
            if index<chain.size():return "%d/%d" % [int(o.get("count",0)),int(chain[index][2])]
        "collection":
            var goal:=collection_required(n)
            for count in collection_counts(id):
                if count<goal:return "%d/%d" % [count,goal]
        "hunter":
            for boss in hunter_bosses(n):
                if hunter_count(o,boss)<hunter_goal(n) or boss==hunter_bosses(n).back():
                    return "%d/%d" % [mini(hunter_count(o,boss),hunter_goal(n)),hunter_goal(n)]
        "trophy":
            var bosses:=trophy_bosses(n)
            var done:=0
            for boss in bosses:
                if o.get("trophy_boss-"+boss,false):done+=1
            return "%d/%d" % [done,bosses.size()]
        "arsenal":
            var counts:=arsenal_counts(o,n);var need:=arsenal_need(n)
            return "%d/%d" % [mini(counts[0],need)+mini(counts[1],need),need*2]
    return ""

## Change 79: the followed opportunity's current requirement as an instruction for the HUD pill's title: the action
## and its target ("Defeat Teal Dinosaur", "Collect Space Helmet Outfit"), or, for a requirement without one
## target, the compact step sentence itself (it carries its own counts). "" for a ready opportunity (the pill keeps
## the opportunity's name and shows Claim). The count beside it is follow_progress.
func follow_action(id: String) -> String:
    var o: Dictionary=sim.state.opportunities.get(id,{})
    if o.is_empty() or o.ready:return ""
    var n=int(id.right(1));var path=id.split("_o")[0]
    match path:
        "collection":
            var target:=follow_target(id)
            if target!="":return sim.tr("TRACK_COLLECT_ITEM") % target
        "expedition","specialist":
            var chain=chain_for(id);var index=int(o.get("step",0))
            if index<chain.size():
                var g:=group_id(str(chain[index][1]))
                if g>=0:return sim.tr("FOLLOW_GOAL_KILL_TARGET") % str(sim.catalog.groups[g].name)
                return sim.tr("FOLLOW_GOAL_"+str(chain[index][0]).to_upper())
        "hunter","trophy":
            var focus:=follow_focus(id)
            if focus.has("group") and int(focus.group)>=0:return sim.tr("FOLLOW_GOAL_KILL_TARGET") % str(sim.catalog.groups[int(focus.group)].name)
    return follow_summary(id,true).get_slice("\n",0)

## Change 79: a daily mission's instruction for the HUD pill, from its own localized goal ("Defeat %s (%s)" with the
## enemy and its map, "Merge items", ...); the hunt and the main objectives already read as instructions.
func mission_action(i: int) -> String:
    var m: Dictionary=sim.state.missions[i]
    var what: String=sim.tr("MISSION_DO_"+str(m.kind).to_upper())
    var g:=group_id(str(m.target))
    if g>=0:what=what % [str(sim.catalog.groups[g].name),str(sim.catalog.stages[int(sim.catalog.groups[g].stage)-1].name)]
    return what

## Change 74: the name of what the followed opportunity's current requirement is about, for the HUD pill's title
## (the opportunity's own name stays in the Prestige panel): the outfit a collection still needs ("Space Helmet
## Outfit"), the enemy or boss a hunt step names ("Space Helmet"), the map or boss a Regional step names. "" when
## the requirement names no single thing (Masterwork, Arsenal, Offering, Offline, a ready opportunity): the
## pill then keeps the opportunity's name. Same state as follow_summary and follow_focus; names already
## translated in the catalog.
func follow_target(id: String) -> String:
    var o: Dictionary=sim.state.opportunities.get(id,{})
    if o.is_empty() or o.ready:return ""
    var n=int(id.right(1));var path=id.split("_o")[0]
    if path=="collection":
        var focus:=follow_focus(id)
        return sim.catalog.display_name(str(focus.item)) if focus.has("item") else ""
    if path=="specialist":
        var chain=chain_for(id);var index=int(o.get("step",0))
        if index<chain.size():
            var g:=group_id(str(chain[index][1]))
            return str(sim.catalog.groups[g].name) if g>=0 else ""
        return ""
    if path=="regional":
        var stages:=regional_stages(n)
        for st in stages:
            if explored_fraction(st)<.9:return str(sim.catalog.stages[st-1].name)
        for st in stages:
            for g in sim.catalog.stages[st-1].groups:
                if sim.catalog.groups[g].boss and int(sim.state.run_kills.get(sim.catalog.groups[g].id,0))==0:return str(sim.catalog.groups[g].name)
        return str(sim.catalog.stages[stages[0]-1].name) if not stages.is_empty() else ""
    var focus:=follow_focus(id)
    if focus.has("group") and int(focus.group)>=0:return str(sim.catalog.groups[int(focus.group)].name)
    return ""

## Change 74: the maps where each followed objective can progress now, as {stage: ["mastery","mission",
## "prestige"]}, for the map buttons (World Travel, Teleport). Map Mastery is per map; a daily mission about one
## enemy belongs to that enemy's map (other missions progress anywhere and mark no map); a Prestige opportunity
## marks the map of what its current requirement names (follow_focus: the enemy that drops the outfit, the
## enemy or boss of the step), else the maps its catalog entry lists (Change 54 "stages"), Regional its own maps.
func follow_stages() -> Dictionary:
    var out: Dictionary={}
    var mark:=func(st: int,kind: String)->void:
        if st<1 or st>sim.catalog.stages.size():return
        if not out.has(st):out[st]=[]
        if not kind in out[st]:out[st].append(kind)
    var m: Dictionary=mastery.followed()
    if not m.is_empty():mark.call(int(m.stage),"mastery")
    var f:=followed_mission()
    if not f.is_empty() and str(f.kind)=="daily":
        var g:=group_id(str(sim.state.missions[int(f.index)].target))
        if g>=0:mark.call(int(sim.catalog.groups[g].stage),"mission")
    var id: String=str(sim.state.follow)
    var o: Dictionary=sim.state.opportunities.get(id,{})
    if id!="" and not o.is_empty() and not bool(o.ready) and not sim.state.consumed.has(id):
        var focus:=follow_focus(id)
        var g:=-1
        if focus.has("group"):g=int(focus.group)
        elif focus.has("item"):
            for i in range(sim.catalog.groups.size()):
                if sim.catalog.groups[i].loot.has(str(focus.item)):g=i;break
        var path: String=id.split("_o")[0]
        if g>=0:mark.call(int(sim.catalog.groups[g].stage),"prestige")
        elif path=="regional":
            for st in regional_stages(int(id.right(1))):mark.call(int(st),"prestige")
        else:
            for op in sim.catalog.campaign.opportunities:
                if str(op.id)==id:
                    for st in op.get("stages",[]):mark.call(int(st),"prestige")
    return out

## What the follower shows beside its text: the exact item a collection still needs, else the enemy
## the current step names ({"item": id} or {"group": index}); {} means the path's own art.
func follow_focus(id: String) -> Dictionary:
    var o: Dictionary=sim.state.opportunities.get(id,{})
    if o.is_empty() or o.ready:return {}
    var n=int(id.right(1));var path=id.split("_o")[0]
    match path:
        "collection":
            var counts:=collection_counts(id)
            var names:=collection_names(n)
            for i in range(counts.size()):
                if counts[i]<collection_required(n):return {"item":contract_outfit(names[i])}
        "expedition":
            var chain=chain_for(id);var index=int(o.get("step",0))
            if index<chain.size():return {"group":group_id(str(chain[index][1]))}
        "hunter":
            for boss in hunter_bosses(n):
                if hunter_count(o,boss)<hunter_goal(n):return {"group":group_id(boss)}
            return {"group":group_id(boss_goal(path,n))}
        "challenge":return {"group":group_id(boss_goal(path,n))}
        "trophy":
            for boss in trophy_bosses(n):
                if not o.get("trophy_boss-"+boss,false):return {"group":group_id("boss-"+str(boss))}
    return {}

## Change 51 (approved brief §3, audit §7.3): Masterwork and Arsenal thresholds that evolvable weapons can
## still reach once they stop merging at ^20. Masterwork I-III: an outfit, skill or final-tier (Obsidian)
## weapon of tier n or higher merged to ^100 after discovery. Arsenal: weapons count at ^20 (their
## evolution point), outfits at ^50; Arsenal III wants tier 2+ for both. Legacy-stat copies never count.
const MASTERWORK_MERGE:=100
const ARSENAL_WEAPON_MERGE:=20
const ARSENAL_OUTFIT_MERGE:=50
func masterwork_best(o: Dictionary,n: int) -> int:
    var best:=0
    for key in o:
        if not str(key).begins_with("merge_"):continue
        var id: String=str(key).trim_prefix("merge_")
        # Legacy-stat weapons (Change 51) never count; older outfit tiers flagged legacy still do, as before.
        if not sim.catalog.items.has(id) or (sim.is_legacy(id) and str(sim.catalog.items[id].kind)=="weapon"):continue
        # Change 54: Masterwork IV counts Obsidian weapons only.
        if n==4:
            if _obsidian_weapon(id):best=maxi(best,int(o[key]))
            continue
        var item: Dictionary=sim.catalog.items[id]
        if item.kind=="weapon" and str(item.next)!="":continue
        if int(item.tier)>=n:best=maxi(best,int(o[key]))
    return best
func arsenal_need(n: int) -> int:return 1 if n==1 else 3
## [distinct weapons at ^20, distinct outfit families at ^50] merged since discovery.
func arsenal_counts(o: Dictionary,n: int) -> Array:
    var weapons: Dictionary={};var outfits: Dictionary={}
    for key in o:
        if not str(key).begins_with("merge_"):continue
        var id: String=str(key).trim_prefix("merge_")
        # Legacy-stat weapons (Change 51) never count; older outfit tiers flagged legacy still do, as before.
        if not sim.catalog.items.has(id) or (sim.is_legacy(id) and str(sim.catalog.items[id].kind)=="weapon"):continue
        var item: Dictionary=sim.catalog.items[id]
        if int(item.tier)<(2 if n==3 else 1):continue
        # Weapons are shared families since Change 7: distinct weapons count by item.
        if item.kind=="weapon" and int(o[key])>=ARSENAL_WEAPON_MERGE:weapons[id]=true
        elif item.kind=="outfit" and int(o[key])>=ARSENAL_OUTFIT_MERGE:outfits[item.family]=true
    return [weapons.size(),outfits.size()]

## "Blue Cap (Winter I)": an enemy with the map it lives on.
func _group_place(g: int) -> String:
    if g<0:return ""
    var d: Dictionary=sim.catalog.groups[g]
    return sim.tr("NAME_ON_MAP") % [str(d.name),str(sim.catalog.stages[int(d.stage)-1].name)]

## One step of an Expedition or Specialist chain as an instruction ("Defeat Blue Cap (Winter I)").
func _chain_goal(q: Array) -> String:
    var g:=group_id(str(q[1]))
    if g>=0:return sim.tr("FOLLOW_GOAL_KILL_TARGET") % _group_place(g)
    return sim.tr("FOLLOW_GOAL_"+str(q[0]).to_upper())

func collection_names(n: int) -> Array:
    return COLLECTION_TYPES[n-1]

func trophy_bosses(n: int) -> Array:
    return TROPHY_BOSSES[n-1]

## Regional mastery, first unmet requirement first: explore a map to 90%, defeat a boss, unlock camps.
func _regional_follow(n: int) -> String:
    var stages:=regional_stages(n)
    var todo: Array=[]
    for st in stages:
        if explored_fraction(st)<.9:todo.append(sim.tr("FOLLOW_REGIONAL_EXPLORE") % [sim.catalog.stages[st-1].name,explored_percent(st)])
    for st in stages:
        for g in sim.catalog.stages[st-1].groups:
            if sim.catalog.groups[g].boss and int(sim.state.run_kills.get(sim.catalog.groups[g].id,0))==0:todo.append(sim.tr("FOLLOW_REGIONAL_BOSS") % _group_place(g))
    for st in stages:
        var d: Dictionary=sim.catalog.stages[st-1]
        var owned: int=sim.state.camps.get(str(st),[]).size()
        if owned<d.spawns.size():todo.append(sim.tr("FOLLOW_REGIONAL_CAMPS") % [d.name,owned,d.spawns.size()])
    if todo.is_empty():return sim.tr("FOLLOW_READY")
    var line: String=todo[0]
    if todo.size()>1:line+="\n"+sim.tr("FOLLOW_THEN_MORE") % [todo[1],todo.size()-1]
    return line

## Change 41: a Collection contract hands in collection_goal(n) copies of each outfit (20 / 30 / 40) and
## the player keeps one, so it asks for collection_required(n) (21 / 31 / 41) from the start. Before, the
## panel and tracker counted to 20 while Submit also wanted a 21st copy, and players met that only when
## submitting. The retained copy is intentional (as for merges): equipping or wearing the outfit never
## leaves the player without it.
func collection_goal(n: int) -> int:return COLLECTION_GOALS[n-1]
func collection_required(n: int) -> int:return collection_goal(n)+1

## Progress per required outfit toward collection_required(n): copies picked up online this run since the
## contract was discovered (spent copies lower it, up to the hand-in amount), plus the one copy kept when
## the inventory holds one more than those, whatever its origin (an older, equipped or offline copy). It
## reaches the requirement exactly when Submit can hand in collection_goal(n) and keep one, so the panel,
## the tracker, the follow notices, the readiness and Submit all read this one count.
func collection_counts(id: String) -> Array:
    var o: Dictionary=sim.state.opportunities.get(id,{})
    var n=int(id.right(1))
    var result: Array=[]
    for name in collection_names(n):
        var item: String=contract_outfit(name)
        var credited:=mini(collection_goal(n),int(minf(float(sim.state.online_items.get(item,0)),float(o.get("item_"+item,0)))))
        result.append(credited+(1 if sim.quantity(item)>credited else 0))
    return result

## Every required outfit at collection_required: what Submit accepts.
func collection_complete(id: String) -> bool:
    var n=int(id.right(1))
    return collection_counts(id).all(func(c):return c>=collection_required(n))

## Discoverable cells of a map: its full fog grid (the authored map size in fog cells).
## Change 15: only reachable cells count (fog_rules.unreachable_cells lists the few inside large solid
## scenery), so every map can reach 100%.
func explore_area(st: int) -> int:
    var d: Dictionary=sim.catalog.stages[st-1]
    return int(ceil(d.size[0]/fog_rules.cell_size)*ceil(d.size[1]/fog_rules.cell_size))-unreachable_cells(st).size()
func unreachable_cells(st: int) -> Array:
    return fog_rules.unreachable_cells.get(st,[])
## Permanently explored share of a map, 0..1, from the saved explored cells only (never momentary
## sight or camera panning). The HUD, World, Map Mastery and the Regional opportunities all read this.
func explored_fraction(st: int) -> float:
    var area:=explore_area(st)
    if area<=0:return 0.0
    var mask:=explored_mask(st)
    var count:=mask.count(1)
    for i in unreachable_indices(st):
        if mask[i]!=0:count-=1
    return clampf(float(count)/area,0.0,1.0)
## fog_rules.unreachable_cells of a stage as mask indices (parsed once per stage).
var _unreachable_indices: Dictionary={}
func unreachable_indices(st: int) -> PackedInt32Array:
    if not _unreachable_indices.has(st):
        var out:=PackedInt32Array()
        for key in unreachable_cells(st):
            var bits: PackedStringArray=str(key).split(",")
            if bits.size()==2 and int(bits[0])<fog_columns(st) and int(bits[1])<fog_rows(st):out.append(int(bits[1])*fog_columns(st)+int(bits[0]))
        _unreachable_indices[st]=out
    return _unreachable_indices[st]
## Fog cells of a stage that no walking player can reveal: a flood fill of walkable points (8-unit
## lattice, the movement bounds and the solid scenery with the actor clearance) from the arrival camp,
## then every cell whose centre is farther than the base reveal radius from all of them. Slow (up to
## half a second on Spring II): only tools/fog_reachability.gd and change_15_probe call it, and the
## result is stored in fog_rules.unreachable_cells.
func compute_unreachable_cells(d: Dictionary,st: int) -> Array:
    if not _obstacle_cache.has(st):_obstacle_cache[st]=_read_obstacles(st)
    var saved: Array=[obstacle_list,obstacle_grid]
    obstacle_list=_obstacle_cache[st].list;obstacle_grid=_obstacle_cache[st].grid
    var step:=8.0
    var w:=float(d.size[0]);var h:=float(d.size[1])
    var start:=Vector2i(roundi(float(d.spawns[0][0])/step),roundi(float(d.spawns[0][1])/step))
    var seen: Dictionary={start:true}
    var queue: Array=[start]
    var i:=0
    while i<queue.size():
        var n: Vector2i=queue[i];i+=1
        for offset in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
            var m: Vector2i=n+offset
            if seen.has(m):continue
            var p:=Vector2(m)*step
            if p.x<14 or p.y<30 or p.x>w-14 or p.y>h-14 or solid_at(p):continue
            seen[m]=true;queue.append(m)
    obstacle_list=saved[0];obstacle_grid=saved[1]
    var cell: float=fog_rules.cell_size
    var radius: float=fog_rules.player_radius
    var result: Array=[]
    for y in range(ceili(h/cell)):
        for x in range(ceili(w/cell)):
            var center:=Vector2(x+.5,y+.5)*cell
            var ok:=false
            for yy in range(floori((center.y-radius)/step),ceili((center.y+radius)/step)+1):
                for xx in range(floori((center.x-radius)/step),ceili((center.x+radius)/step)+1):
                    if seen.has(Vector2i(xx,yy)) and (Vector2(xx,yy)*step).distance_to(center)<=radius:ok=true;break
                if ok:break
            if not ok:result.append("%d,%d" % [x,y])
    return result
## Whole percent, rounded down, so 100% means every cell is explored.
func explored_percent(st: int) -> int:
    return mini(100,floori(explored_fraction(st)*100.0+.000001))
# ---------------------------------------------------------------- next-stage guidance (Change 13)
## What still opens the next map, from the authoritative unlock rule (killed(): every gate boss of
## the current map killed at least once this run, while this map is the frontier). Stages 1-7 count
## their gate bosses; Spring II counts every type for the world clear. Empty when nothing is pending.
func gate_status() -> Dictionary:
    var st:=int(sim.state.stage)
    if st<8:
        if int(sim.state.unlocked_stage)!=st or stage().gates.is_empty():return {}
        var killed:=0
        for id in stage().gates:
            if int(sim.state.run_kills.get(id,0))>0:killed+=1
        return {"kind":"stage","killed":killed,"total":stage().gates.size()}
    if bool(sim.state.world_complete):return {}
    var done:=0
    for g in stage().groups:
        if int(sim.state.run_kills.get(sim.catalog.groups[g].id,0))>0:done+=1
    return {"kind":"world","killed":done,"total":stage().groups.size()}

## A boss the player still has to defeat for gate_status(), shown only once its type is discovered
## (the marker never reveals an unknown boss, its identity or its place).
func gate_required(g: int) -> bool:
    if g<0 or g>=sim.catalog.groups.size() or not sim.catalog.groups[g].boss or not discovered(g):return false
    if not stage().groups.has(g) or gate_status().is_empty():return false
    var id: String=sim.catalog.groups[g].id
    if int(sim.state.stage)<8 and not stage().gates.has(id):return false
    return int(sim.state.run_kills.get(id,0))==0

func _regional_progress(n: int) -> String:
    var explored: Array=[];var bosses:=0;var killed:=0;var camps:=0;var owned:=0
    for st in regional_stages(n):
        var d: Dictionary=sim.catalog.stages[st-1]
        explored.append("%d%%" % explored_percent(st))
        camps+=d.spawns.size();owned+=sim.state.camps.get(str(st),[]).size()
        for g in d.groups:
            if sim.catalog.groups[g].boss:
                bosses+=1
                if sim.state.run_kills.get(sim.catalog.groups[g].id,0)>0:killed+=1
    return sim.tr("PROGRESS_REGIONAL") % [" + ".join(explored),killed,bosses,owned,camps]

# ---------------------------------------------------------------- Change 17 combat and reward contracts
## Every timed status (including future effects) passes through this one duration rule.
func status_duration(a: Dictionary,seconds: float) -> float:
    return seconds*float(sim.catalog.progression.change17.boss_status_duration) if a.id!="player" and sim.catalog.groups[int(a.group)].boss else seconds
func apply_timed_status(a: Dictionary,key: String,seconds: float) -> void:
    a[key]=status_duration(a,seconds)

func effective_skill_multiplier(a: Dictionary,b: Dictionary,key: String,power: float) -> float:
    var value:=power*damage_multiplier(a,b)
    if a.id=="player" and key=="fire":value=minf(value,float(sim.catalog.progression.change17.fire_effective_cap))
    return value

## Change 50: missions are priced from the current run's map access (highest unlocked stage), so a new
## run's Winter I missions pay Winter I rewards even with every map reached before (Coins are kept by
## Prestige since Change 50). Travel never lowers it within a run. The saved field mirrors this value.
func reward_stage() -> int:
    return clampi(int(sim.state.unlocked_stage),1,sim.catalog.stages.size())

## Mean current normal-enemy kill payout at the highest unlocked stage. Includes Coin Amount,
## normal/coin Prestige and active Coin Tonic exactly as killing those enemies would.
func mission_coin_income() -> float:
    var total:=0.0
    var count:=0
    for g in range(sim.catalog.groups.size()):
        var d: Dictionary=sim.catalog.groups[g]
        if int(d.stage)==reward_stage() and not d.boss:total+=sim.coin_reward(g);count+=1
    return total/maxi(1,count)

func mission_rewards(m: Dictionary) -> Dictionary:
    if str(m.kind)=="waiting":return {"coins":0.0,"gems":0.0,"stage":reward_stage()}
    var rules: Dictionary=sim.catalog.progression.change17
    var kills:=float(rules.mission_boss_kills if m.kind=="boss" else rules.mission_regular_kills)
    var base_gems:=float(m.get("base_gems",0 if m.kind=="kill" else (5 if m.kind in ["boss","coins"] else 3)))
    return {"coins":mission_coin_income()*kills*(1+bonus("mission_coins")),
        "gems":base_gems*float(rules.mission_gem_multipliers[reward_stage()-1])*(1+bonus("mission_gems")),"stage":reward_stage()}

## Compatibility fields read by existing mission UI; always recompute from base, never multiply totals.
func price_mission(m: Dictionary) -> void:
    if not m.has("base_gems"):m.base_gems=0 if m.kind=="kill" else (5 if m.kind in ["boss","coins"] else 3)
    var reward:=mission_rewards(m)
    m.coins=reward.coins;m.gems=reward.gems;m.reward_stage=reward.stage

func normalize_change17(out: Dictionary) -> void:
    var rules: Dictionary=sim.catalog.progression.change17
    if not out.get("supply_uses") is Dictionary:out.supply_uses={}
    if not out.has("supply_mastery_credit"):
        out.supply_mastery_credit={}
        if out.get("supply_found") is Dictionary:
            for id in out.supply_found:
                if number(out.supply_found[id]):out.supply_mastery_credit[id]=clampi(int(out.supply_found[id])-1,0,int(sim.catalog.progression.supply_mastery.cap))
    if not out.supply_mastery_credit is Dictionary:out.supply_mastery_credit={}
    for field in ["supply_uses","supply_mastery_credit"]:
        for id in out[field].keys():
            if not sim.catalog.items.has(id) or sim.catalog.items[id].kind!="consumable" or not number(out[field][id]):out[field].erase(id)
            else:out[field][id]=clampi(int(out[field][id]),0,int(sim.catalog.progression.supply_mastery.cap)*(int(rules.supply_uses_per_level) if field=="supply_uses" else 1))
    if not out.has("reward_stage"):
        out.reward_stage=int(out.get("unlocked_stage",1))
        # Previously visited worlds are evidence of prior unlocks even after an older Prestige.
        for field in ["explored","stage_worlds","camps"]:
            if out.get(field) is Dictionary:
                for key in out[field]:
                    if str(key).is_valid_int():out.reward_stage=maxi(out.reward_stage,int(key))
    out.reward_stage=clampi(int(out.reward_stage) if number(out.reward_stage) else 1,1,8)
    if out.get("upgrades") is Dictionary:
        var n:=int(out.upgrades.get("skill_auto_slots",0)) if number(out.upgrades.get("skill_auto_slots",0)) else 0
        for i in range(3):
            var key:="skill_auto_"+str(i)
            if number(out.upgrades.get(key,0)):n+=clampi(int(out.upgrades.get(key,0)),0,1)
            out.upgrades.erase(key)
        if n>0:out.upgrades.skill_auto_slots=clampi(n,0,3)
    if not out.has("boss_respawns"):
        out.boss_respawns={}
        var worlds: Array=[out]
        if out.get("stage_worlds") is Dictionary:
            for key in out.stage_worlds:
                if int(key)!=int(out.get("stage",1)):worlds.append(out.stage_worlds[key])
        for world in worlds:
            if not world is Dictionary or not world.get("enemies") is Array:continue
            for a in world.enemies:
                if not a is Dictionary or not number(a.get("group")):continue
                var g:=int(a.group)
                if g>=0 and g<sim.catalog.groups.size() and sim.catalog.groups[g].boss and number(a.get("hp")) and a.hp<=0 and number(a.get("respawn")) and a.respawn>0:
                    out.boss_respawns[str(a.id)]={"group":g,"stage":int(sim.catalog.groups[g].stage),"remaining":a.respawn,"x":a.home_x,"y":a.home_y}
    if not out.get("boss_respawns") is Dictionary:out.boss_respawns={}
    for id in out.boss_respawns.keys():
        var e=out.boss_respawns[id]
        if not e is Dictionary or not e.has_all(["group","stage","remaining","x","y"]) or not number(e.group) or not number(e.remaining) or not number(e.x) or not number(e.y):out.boss_respawns.erase(id);continue
        var g:=int(e.group)
        if g<0 or g>=sim.catalog.groups.size() or not sim.catalog.groups[g].boss or str(id)!="g%d_v2_0" % g:out.boss_respawns.erase(id);continue
        e.group=g;e.stage=int(sim.catalog.groups[g].stage);e.remaining=clampf(float(e.remaining),0,sim.spawn_cooldown(g))
        var home: Vector2=sim.spawn_home(g,2,0);e.x=home.x;e.y=home.y
    if not number(out.get("boss_saved_at")):out.boss_saved_at=sim.now_unix()

func normalize_skill_assignments(out: Dictionary) -> void:
    if not out.get("upgrades") is Dictionary:return
    var capacity:=clampi(int(out.upgrades.get("skill_auto_slots",0)),0,3)
    var slots:=mini(3,1+int(out.upgrades.get("skill_slots",0)))
    var old: Array=out.skill_auto if out.get("skill_auto") is Array else []
    var selected: Array=[false,false,false]
    for i in range(mini(slots,old.size())):
        if old[i] is bool and old[i] and capacity>0:selected[i]=true;capacity-=1
    out.skill_auto=selected
