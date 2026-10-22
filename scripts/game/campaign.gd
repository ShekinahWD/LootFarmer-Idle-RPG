extends RefCounted
## Campaign rules share the simulation's save state; this object owns no second save.
var sim
var reveal_clock: float=0
var discovery_revision: int=0
var fog_rules=preload("res://resources/game/fog_rules.tres")
var objective_clock: float=0
var offline_receipt: Dictionary={}
func _init(owner) -> void: sim=owner
func stage() -> Dictionary: return sim.catalog.stages[int(sim.state.stage)-1]
func initialize() -> void:
    reveal_clock=0;objective_clock=0;offline_receipt={}
    sim.state.merge({"fog_layout_revision":fog_rules.layout_revision,"tutorial":{"mode":"pending","done":[],"seen":[]},"stage":1,"unlocked_stage":1,"stage_worlds":{},"camps":{"1":[0]},"explored":{},"discovered":{},"run_kills":{},"keys":[],"final_discovered":false,"final_complete":false,"skills":["","",""],"skill_auto":[false,false,false],"skill_cooldowns":{},"merge_timers":{},"merge_cursors":{},"opportunities":{},"owned_cards":[],"consumed":[],"prestige_batch":{},"follow":"","counters":{},"online_items":{},"online_coins":0.0,"online_gems":0.0,"offline_total":0.0,"offline_longest":0.0,"offline_income":0.0,"offline_remainders":{},"offline_snapshot":{},"offline_pending":{},"missions":[],"main_claimed":[],"main_ready":{},"mission_day":"","consumable_uses":0,"mission_auto":false,"world_complete":false,"skills_seen":[],"discovered_spots":{},"camps_known":{}},true)
    sim.state.group_kills.resize(sim.catalog.groups.size());sim.state.group_kills.fill(0)
    sim.state.collect_clocks.resize(sim.catalog.groups.size());sim.state.collect_clocks.fill(0.0)
    refresh_missions()
## Change 8 solid scenery: the stage scene's Decor carries editor-visible "Block" shapes at tree
## trunks, boulders, lamps, ponds and fenced fields. They are read once per stage per process.
static var _obstacle_cache: Dictionary={}
var obstacle_list: Array=[]
var obstacle_grid: Dictionary={}
const OBSTACLE_CELL:=64.0
## Actors are points with this clearance; tools/compose_stage_art.gd keeps solids far enough apart.
const ACTOR_CLEARANCE:=6.0
func load_obstacles() -> void:
    var id:=int(sim.state.stage)
    if not _obstacle_cache.has(id):_obstacle_cache[id]=_read_obstacles(id)
    obstacle_list=_obstacle_cache[id].list;obstacle_grid=_obstacle_cache[id].grid
func _read_obstacles(id: int) -> Dictionary:
    var list: Array=[];var grid: Dictionary={}
    var path:="res://scenes/game/stages/stage_%d.tscn" % id
    if not ResourceLoader.exists(path):return {"list":list,"grid":grid}
    var scene: Node=load(path).instantiate()
    for node in scene.find_children("*","CollisionShape2D",true,false):
        var shape: CollisionShape2D=node
        var pos:=Vector2.ZERO;var n: Node=shape
        while n!=null and n!=scene:
            if n is Node2D:pos+=(n as Node2D).position
            n=n.get_parent()
        if shape.shape is CircleShape2D:list.append({"c":pos,"r":(shape.shape as CircleShape2D).radius})
        elif shape.shape is RectangleShape2D:
            var size: Vector2=(shape.shape as RectangleShape2D).size
            list.append({"rect":Rect2(pos-size*.5,size)})
    scene.free()
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
func camp_price(index: int) -> int:
    if index==0:return 0
    return maxi(1,ceili([0,50,150][index]*pow(2,int(sim.state.stage)-1)*(1-bonus("camp_discount"))))
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
    return float(r.camp) if resting_camp()>=0 else float(r.field)
func resting_camp() -> int:
    var p: Vector2=sim.position_of(sim.state.player)
    for camp in sim.state.spawns:
        var a: Array=stage().spawns[int(camp)]
        if p.distance_to(Vector2(a[0],a[1]))<=float(sim.catalog.progression.rest.camp_radius):return int(camp)
    return -1
func travel_reason(st: int,camp: int) -> String:
    var lock: String=sim.action_lock_reason()
    if lock!="":return lock
    if sim.state.player.hp<=0:return "CANNOT_USE"
    if in_combat():return "TRAVEL_COMBAT"
    if st<1 or st>int(sim.state.unlocked_stage):return "STAGE_LOCKED"
    if camp<0 or camp>=sim.catalog.stages[st-1].spawns.size():return "CAMP_LOCKED"
    if not sim.state.camps.get(str(st),[0]).has(camp):return "CAMP_LOCKED"
    return ""
func camp_action(st: int,camp: int,teleport: bool) -> bool:
    if not sim.action_lock_reason().is_empty():return sim.fail(sim.action_lock_reason())
    if teleport:
        var reason=travel_reason(st,camp)
        if reason!="":return sim.fail(reason)
        if st!=int(sim.state.stage):
            sim.state.stage_worlds[str(sim.state.stage)]={"enemies":sim.state.enemies.duplicate(true),"pickups":sim.state.pickups.duplicate(true)}
            sim.state.stage=st;sim.state.spawn=camp
            configure_stage()
            var saved: Dictionary=sim.state.stage_worlds.get(str(st),{})
            sim.state.enemies=saved.get("enemies",[]).duplicate(true)
            sim.state.pickups=saved.get("pickups",[]).duplicate(true)
            sim._sync_spawn_counts()
        sim.state.spawn=camp
        var pos: Array=stage().spawns[camp]
        sim.state.player.x=pos[0];sim.state.player.y=pos[1]
        sim.state.player.windup=0;sim.state.player.target="";sim.state.player.idle=0
        sim.state.focus=-1;sim.clear_target();reveal()
        sim.touch();SaveService.save_now();return true
    if st!=int(sim.state.stage) or camp<0 or camp>=stage().spawns.size():return false
    if not sim.state.spawns.has(camp):
        if not camp_known(camp):return sim.fail("CAMP_UNDISCOVERED")
        if not sim.pay("coins",camp_price(camp)):return false
        sim.state.spawns.append(camp)
        sim.state.camps[str(st)]=sim.state.spawns
        progress("camp","",1);reveal()
    else:sim.state.spawn=camp
    sim.touch();SaveService.save_now();return true
func cell_key(pos: Vector2) -> String:
    return "%d,%d" % [floori(pos.x/fog_rules.cell_size),floori(pos.y/fog_rules.cell_size)]
func in_bounds(pos: Vector2) -> bool:
    return Rect2(Vector2.ZERO,Vector2(stage().size[0],stage().size[1])).has_point(pos)
func cell_known(pos: Vector2) -> bool:
    return in_bounds(pos) and sim.state.explored.get(str(sim.state.stage),{}).has(cell_key(pos))
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
    var mask: Dictionary=sim.state.explored.get(str(sim.state.stage),{})
    var cell: float=fog_rules.cell_size
    var changed:=false
    for y in range(maxi(0,floori((pos.y-radius)/cell)),mini(ceili(stage().size[1]/cell),ceili((pos.y+radius)/cell))):
        for x in range(maxi(0,floori((pos.x-radius)/cell)),mini(ceili(stage().size[0]/cell),ceili((pos.x+radius)/cell))):
            var key:="%d,%d" % [x,y]
            if not mask.has(key) and (Vector2(x,y)*cell+Vector2.ONE*cell*.5).distance_to(pos)<=radius:
                mask[key]=true;changed=true
    sim.state.explored[str(sim.state.stage)]=mask
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
        if float(actor.hp)>0 and not spot_discovered(int(actor.group),int(actor.get("variant",2))) and cell_known(sim.position_of(actor)):
            discover_spot(int(actor.group),int(actor.get("variant",2)))
func reveal() -> void:
    if sim.state.player.hp>0:reveal_circle(sim.position_of(sim.state.player),player_radius())
    sight_camps()
    for camp in sim.state.spawns:
        var a: Array=stage().spawns[int(camp)]
        reveal_circle(Vector2(a[0],a[1]),fog_rules.camp_radius*(1+.25*sim.level("camp_radius",int(sim.state.stage)*10+int(camp))+bonus("camp_reveal")))
    identify_sites()
func target_allowed(e: Dictionary) -> bool:
    var d: Dictionary=sim.catalog.groups[int(e.group)]
    return can_see(sim.position_of(e)) and (not d.final or sim.state.keys.size()==13)
func damage_multiplier(a: Dictionary,b: Dictionary) -> float:
    var n=1.0
    if a.id=="player":n+=bonus("boss_damage" if sim.catalog.groups[int(b.group)].boss else "normal_damage")
    elif b.id=="player":n*=1-bonus("guard")- (bonus("boss_guard") if sim.catalog.groups[int(a.group)].boss else 0.0)
    if float(a.get("focus_time",0))>0:n*=1+float(a.get("focus_power",.15))
    return maxf(.1,n)
func upgrade_cost(id: String,g: int) -> int:
    var d: Dictionary=sim.catalog.upgrades[id]
    var n: int=sim.level(id,g)
    var st=1
    if d.scope in ["type","normal_type"]:st=int(sim.catalog.groups[g].stage)
    elif d.scope=="stage":st=g
    elif d.scope=="camp":st=g/10
    var factor=pow(2,st-1) if d.currency=="coins" else 1+.25*(st-1)
    var price=float(d.base)*pow(float(d.growth),n)
    if d.has("prices"):price=float(d.prices[mini(n,d.prices.size()-1)])
    # Linear schedules: every purchase costs `step` more than the one before (slots).
    if d.has("step"):price=float(d.base)+float(d.step)*n
    # Sequence schedules (Map Details): one rising price per purchase on any stage this run, with a
    # per-stage floor so a late stage is never trivially cheap.
    if d.get("sequence",false):
        factor=1.0
        price=maxf(float(d.base)*pow(float(d.growth),sequence_count(id)),float(d.get("floor",0))*pow(2,st-1))
    return maxi(1,ceili(price*factor*(1-bonus("coin_discount") if d.currency=="coins" else 1)))
func sequence_count(id: String) -> int:
    var total:=0
    for key in sim.state.upgrades:
        if str(key).get_slice(":",0)==id:total+=int(sim.state.upgrades[key])
    return total
func upgrade_bought(id: String,g: int) -> void:
    if id in ["map_detail","reveal_radius","camp_radius"]:reveal()
    if id=="mission_slots":refresh_missions()
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
    if not sim.action_lock_reason().is_empty() or slot<0 or slot>=1+sim.level("skill_slots"):return false
    var id: String=sim.state.skills[slot]
    if id=="" or sim.quantity(id)<1 or sim.state.player.hp<=0:return false
    var key: String=sim.catalog.items[id].skill
    if float(sim.state.skill_cooldowns.get(key,0))>0:return false
    if not apply_skill(sim.state.player,key,float(sim.normal(id).power)*(1+bonus("skill"))):return false
    sim.state.skill_cooldowns[key]=maxf(2,sim.catalog.skills[key].cooldown*(1-.05*sim.level("cooldown_"+key)))
    progress("cast",key,1);sim.touch();return true
func apply_skill(a: Dictionary,key: String,power: float,aim: Vector2=Vector2.INF) -> bool:
    var player: bool=a.id=="player"
    var target: Dictionary=sim._combat_target() if player else sim.state.player
    var pos: Vector2=sim.position_of(a)
    if key=="heal":
        var maxhp: float=sim.stats().hp if player else sim.enemy_definition(a.group,a.variant).hp
        if a.hp>=maxhp*.8:return false
        var gain=minf(minf(power,maxhp*float(sim.catalog.skills.heal.player_hp_cap)) if player else maxhp*float(sim.catalog.skills.heal.enemy_hp_fraction),maxhp-a.hp)
        a.hp+=gain;sim.feedback.emit(a.id,gain,true)
    elif key=="focus":
        if not in_combat():return false
        a.focus_time=5.0;a.focus_power=power
    else:
        if target.is_empty() or target.hp<=0:return false
        var range_limit=96.0 if key=="frost" else (80.0 if key=="strike" else 120.0)
        if pos.distance_to(sim.position_of(target))>range_limit:return false
        var center: Vector2=pos if key=="frost" else (sim.position_of(target) if aim==Vector2.INF else aim)
        var targets: Array=sim.state.enemies if player else [sim.state.player]
        var base: float=sim.stats().damage if player else sim.enemy_definition(a.group,a.variant).damage
        for b in targets:
            if b.hp<=0 or (player and not target_allowed(b)):continue
            var hits: bool=b.id==target.id
            if key in ["fire","frost"]:hits=sim.position_of(b).distance_to(center)<=(96 if key=="frost" else 64)
            if not hits:continue
            var defense: float=sim.stats().defense if not player else sim.enemy_definition(b.group,b.variant).defense
            var damage=maxf(1,base*power*damage_multiplier(a,b)*100/(100+defense))
            begin_encounter(b if player else a)
            sim.state.player.quiet=0
            b.hp=maxf(0,b.hp-damage);b.quiet=0;b.aggro=true;b.hurt=.16
            if key=="frost":b.slow=3.0
            sim.feedback.emit(b.id,damage,false)
            if b.hp<=0:sim._kill(b)
        pos=center
    sim.spell_cast.emit(a.id,key,pos)
    return true
func step(dt: float) -> void:
    for key in sim.state.skill_cooldowns:sim.state.skill_cooldowns[key]=maxf(0,sim.state.skill_cooldowns[key]-dt)
    for a in [sim.state.player]+sim.state.enemies:
        a.focus_time=maxf(0,float(a.get("focus_time",0))-dt);a.slow=maxf(0,float(a.get("slow",0))-dt)
        if a.id=="player" or a.hp<=0:continue
        var d: Dictionary=sim.enemy_definition(a.group,a.variant)
        if d.final and not sim.state.final_discovered and sim.position_of(a).distance_to(sim.position_of(sim.state.player))<160:
            sim.state.final_discovered=true;sim.touch();SaveService.save_now();sim.event.emit("FINAL_DISCOVERED")
        if d.final and sim.state.keys.size()<13:
            a.aggro=false;a.windup=0;continue
        if not a.aggro:a.telegraph=false
        a.skill_timer=maxf(0,float(a.get("skill_timer",0))-dt)
        if a.aggro and not d.skills.is_empty() and a.skill_timer<=0:
            var index=int(a.get("skill_index",0))%d.skills.size()
            var key: String=d.skills[index]
            if d.boss and not a.get("telegraph",false):
                a.telegraph=true;a.skill_timer=.6
                var aim: Vector2=sim.position_of(a) if key in ["heal","focus","frost"] else sim.position_of(sim.state.player)
                a.aim_x=aim.x;a.aim_y=aim.y
                sim.spell_cast.emit(a.id,key,aim)
            else:
                if apply_skill(a,key,float(sim.catalog.skills[key].power),Vector2(a.get("aim_x",sim.state.player.x),a.get("aim_y",sim.state.player.y)) if d.boss else Vector2.INF):
                    a.skill_timer=sim.catalog.skills[key].cooldown;a.skill_index=index+1
                else:a.skill_timer=1.0
                a.telegraph=false
    reveal_clock+=dt;objective_clock+=dt
    if reveal_clock>=fog_rules.update_interval:reveal_clock=0;reveal()
    if objective_clock>=1:
        objective_clock=0;refresh_missions();evaluate();sim.touch()
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
    sim.state.use_clock+=dt
    if sim.state.use_clock>=sim.player_upgrade_value("use_speed"):
        sim.state.use_clock=0
        # Each automated slot uses its supply when that supply's own auto condition holds.
        for slot in sim.state.auto_slots:
            if int(slot)<sim.state.supplies.size():
                var id: String=sim.state.supplies[int(slot)]
                if id!="" and sim.supply_auto_ready(id):sim.use_item(id)
    for i in range(1+sim.level("skill_slots")):
        if sim.state.skill_auto[i] and sim.level("skill_auto_"+str(i))>0:cast(i)
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
        var eligible: bool=sim.gear_group(id)==g and sim.catalog.items[id].kind!="consumable"
        if eligible and sim.quantity(id)>1 and sim.record(id).merge<sim.merge_cap(id):
            sim.merge(id);sim.state.merge_cursors[key]=(i+1)%ids.size();break
func begin_encounter(a: Dictionary) -> void:
    if a.id!="player" and not a.has("encounter_uses"):a.encounter_uses=sim.state.consumable_uses
func killed(a: Dictionary) -> void:
    var d: Dictionary=sim.catalog.groups[int(a.group)]
    discover_spot(int(a.group),int(a.get("variant",2)))
    sim.state.run_kills[d.id]=int(sim.state.run_kills.get(d.id,0))+1
    var prior: Array=sim.state.opportunities.keys()
    progress("kill" if not d.boss else "boss_kill",d.id,1)
    if d.boss:
        progress("boss",d.id,1)
        if sim.state.final_discovered and not d.final and not sim.state.keys.has(d.id):sim.state.keys.append(d.id)
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
    a.erase("encounter_uses")
    if d.boss:SaveService.save_now()
func progress(kind: String,id: String,amount: float) -> void:
    var prior: Array=sim.state.opportunities.keys()
    sim.state.counters[kind]=float(sim.state.counters.get(kind,0))+amount
    sim.state.counters[kind+":"+id]=float(sim.state.counters.get(kind+":"+id,0))+amount
    if kind=="coins":sim.state.online_coins+=amount
    if kind=="collect":sim.state.online_items[id]=float(sim.state.online_items.get(id,0))+amount
    for m in sim.state.missions:
        if not m.claimed and m.kind==kind and (m.target=="" or m.target==id):m.progress=minf(m.goal,m.progress+amount)
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
func counter(key: String) -> float:return float(sim.state.counters.get(key,0))
func refresh_missions() -> void:
    var day=Time.get_date_string_from_system()
    for i in range(sim.state.missions.size()):
        if sim.state.missions[i].kind=="waiting" or (sim.state.missions[i].claimed and sim.state.missions[i].day!=day):sim.state.missions[i]=new_mission(i,day)
    while sim.state.missions.size()<3+sim.level("mission_slots"):sim.state.missions.append(new_mission(sim.state.missions.size(),day))
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
    result.coins*=1+bonus("mission_coins");result.gems*=1+bonus("mission_gems")
    return result
func claim_mission(i: int) -> bool:
    if not sim.action_lock_reason().is_empty() or i<0 or i>=sim.state.missions.size():return false
    var m: Dictionary=sim.state.missions[i]
    if m.claimed or m.progress<m.goal:return false
    var before: Dictionary=sim.state.duplicate(true)
    m.claimed=true;sim.state.coins+=m.coins;sim.state.gems+=m.gems
    progress("mission","",1);refresh_missions();sim.touch()
    if not SaveService.save_now():sim.state=before;sim.touch();return false
    return true
func chain_for(id: String) -> Array:
    var n=int(id.right(1))
    if id.begins_with("expedition"):
        var names: Array=[['blue-cap','red-scarf','chef-hat'],['straw-hat','sunglasses','yellow-cap'],['bunny-ears','cat-ears','elf-ears']][n-1]
        return [["kill","unit-"+names[0],50+50*n],["kill","unit-"+names[1],50+50*n],["kill","unit-"+names[2],50+50*n]]
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
        "hunter","challenge":return counter("boss:"+boss_goal(path,n))>=1
        "expedition":return counter("kill:"+str(chain_for(op.id)[0][1]))>=10
        "regional":return sim.state.unlocked_stage>=[2,4,8][n-1]
        "offering":return counter("coins")>=1000 if n==1 else sim.state.unlocked_stage>=(5 if n==2 else 8)
        "specialist":return counter("mission")>=(1 if n==1 else 5) if n<3 else sim.state.unlocked_stage>=6
        "trophy":return counter("boss:"+[['boss-snowman'],['boss-gray-cat'],['boss-squirrel']][n-1][0])>0
        "collection":return online_gear_families()>=3 if n==1 else sim.state.unlocked_stage>=(3 if n==2 else 7)
        "masterwork":
            if n==1:
                for r in sim.state.items.values():
                    if r.merge>=10:return true
            elif n==2:return counter("evolve")>0
            else:
                for id in sim.state.items:
                    if sim.quantity(id)>0 and sim.catalog.items[id].tier>=3:return true
        "arsenal":return sim.state.weapon!="" and sim.state.outfit!="" if n==1 else (online_gear_families()>=4 if n==2 else evolved_families()>=2)
    return false
func boss_goal(path: String,n: int) -> String:
    return ["boss-snowman","boss-gray-cat","boss-grim-reaper"][n-1] if path=="hunter" else ["boss-cyan-robot","boss-teal-dinosaur","boss-grim-reaper"][n-1]
## Boss Hunter kill targets after discovery (Change 6: 10 / 20 / 30, was 30 / 40 / 50).
func hunter_goal(n: int) -> int:return 10*n
func evaluate() -> void:
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
            "hunter","challenge":
                var k: String=("boss:" if op.path=="hunter" else "restricted:")+boss_goal(op.path,n)
                ready=counter(k)-float(o.baseline.get(k,0))>=(hunter_goal(n) if op.path=="hunter" else 1)
            "expedition","specialist":ready=int(o.get("step",0))>=chain_for(op.id).size()
            "offline":ready=sim.state.offline_total>=72*3600 if n==1 else (sim.state.offline_longest>=24*3600 if n==2 else sim.state.offline_income>=10000)
            "masterwork":
                for key in o:
                    if key.begins_with("merge_") and int(o[key])>=100 and int(sim.catalog.items[key.trim_prefix("merge_")].tier)>=n:ready=true
            "arsenal":
                var weapons: Dictionary={};var outfits: Dictionary={}
                for key in o:
                    if key.begins_with("merge_") and int(o[key])>=50:
                        var item: Dictionary=sim.catalog.items[key.trim_prefix("merge_")]
                        # Weapons are shared families since Change 7: distinct weapons count by item.
                        if int(item.tier)>=(2 if n==3 else 1):
                            if item.kind=="weapon":weapons[key]=true
                            elif item.kind=="outfit":outfits[item.family]=true
                ready=weapons.size()>=(1 if n==1 else 3) and outfits.size()>=(1 if n==1 else 3)
            "regional":
                ready=true
                for st in ([1,2] if n==1 else ([3,4] if n==2 else [7,8])):
                    var d: Dictionary=sim.catalog.stages[st-1]
                    var area: float=ceil(d.size[0]/fog_rules.cell_size)*ceil(d.size[1]/fog_rules.cell_size)
                    if sim.state.explored.get(str(st),{}).size()<area*.9 or sim.state.camps.get(str(st),[]).size()!=d.spawns.size():ready=false
                    for g in d.groups:
                        if sim.catalog.groups[g].boss and sim.state.run_kills.get(sim.catalog.groups[g].id,0)==0:ready=false
            "collection","offering":ready=bool(o.get("submitted",false))
            "trophy":
                ready=true
                var bosses: Array=[["snowman","cyan-robot"],["gray-cat","elephant","teal-dinosaur"],["squirrel","red-fox","black-cat","grim-reaper"]][n-1]
                for boss in bosses:
                    if not o.get("trophy_boss-"+boss,false):ready=false
        if ready:
            o.ready=true
            if sim.state.follow==op.id:sim.state.follow=""
            sim.event.emit("PRESTIGE_READY");sim.milestone.emit("ready",op.id)
    evaluate_main()
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
        var names: Array=[['blue-cap','red-scarf','chef-hat'],['straw-hat','sunglasses','yellow-cap'],['bunny-ears','cat-ears','elf-ears']][n-1]
        var count=10+10*n
        for name in names:
            var item: String=contract_outfit(name)
            if sim.quantity(item)<count+1 or minf(float(sim.state.online_items.get(item,0)),float(o.get("item_"+item,0)))<count:return sim.fail("CONTRACT_NEEDS")
        for name in names:
            var item: String=contract_outfit(name);sim._remove(item,count)
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
func prestige_unlocked() -> bool:
    var g:=prestige_unlock_group()
    return g>=0 and int(sim.state.group_kills[g])>0
func prestige_gate_reason() -> String:
    if not prestige_unlocked():return "PRESTIGE_LOCKED_FIRST_BOSS"
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
    var gate:=prestige_gate_reason()
    if gate!="":return gate
    if ready_ids().is_empty():return "NO_READY_PRESTIGE"
    if awardable_ids().is_empty():return "NO_CARD_AVAILABLE"
    return ""
func begin_prestige() -> bool:
    if not prestige_block_reason().is_empty():return sim.fail(prestige_block_reason())
    var before: Dictionary=sim.state.duplicate(true)
    sim.state.prestige_batch={"ids":awardable_ids(),"choices":[],"transaction":str(Time.get_unix_time_from_system())+"-"+str(sim.rng.randi())}
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
        var keep: Dictionary={}
        for key in ["owned_cards","consumed","opportunities","keys","final_discovered","final_complete","main_claimed","offline_total","offline_longest","offline_income","cards","group_kills","skill_auto","tutorial","playtime_total","offline_pending","skills_seen","supply_found"]:keep[key]=sim.state[key].duplicate(true) if sim.state[key] is Dictionary or sim.state[key] is Array else sim.state[key]
        keep.owned_cards.append_array(sim.state.prestige_batch.choices);keep.consumed.append_array(sim.state.prestige_batch.ids)
        for op in keep.opportunities:
            if not op.begins_with("offline") and not keep.consumed.has(op):keep.opportunities[op]={"ready":false,"baseline":{},"step":0,"count":0}
        var upgrades: Dictionary={}
        for key in sim.state.upgrades:
            if sim.upgrade_kept(key.split(":")[0]):upgrades[key]=sim.state.upgrades[key]
        var runs: int=sim.state.prestiges+1;var gear: int=sim.state.gear.size();var supplies: int=sim.state.supplies.size()
        sim.new_profile();sim.state.merge(keep,true);sim.state.upgrades=upgrades;sim.state.prestiges=runs
        sim.state.gear.resize(gear);sim.state.gear.fill("");sim.state.supplies.resize(supplies);sim.state.supplies.fill("")
        # Kept spawn upgrades (gems) apply to the fresh world at once, not after the next purchase.
        sim._sync_spawn_counts()
        sim.state.missions=[];refresh_missions();sim.touch();sim.state.player.hp=sim.stats().hp
    sim.touch()
    if not SaveService.save_now():sim.state=before;sim.touch();return false
    # Presentation follows the durable commit; a failed write never celebrates.
    sim.milestone.emit("card",id)
    if final:sim.event.emit("PRESTIGED");sim.milestone.emit("prestiged",",".join(granted))
    return true
func get_tree_paused() -> bool:return sim.get_tree().paused
func cancel_prestige() -> bool:
    if sim.state.prestige_batch.is_empty() or not sim.state.prestige_batch.choices.is_empty():return false
    sim.state.prestige_batch={};sim.touch();return SaveService.save_now()
func evaluate_main() -> void:
    var goals: Array=[counter("kill")>=5,counter("equip")>=1,counter("merge")>=1,counter("camp")>=1,sim.state.unlocked_stage>=2,sim.state.skills.any(func(id):return id.begins_with("skill_heal")),counter("upgrade:map_detail")>0,sim.quantity("skill_frost")>0,sim.state.unlocked_stage>=3,counter("evolve")>0,skill_count()>=4,sim.state.unlocked_stage>=5,skill_count()>=6,sim.state.unlocked_stage>=7,sim.state.prestiges>0,sim.state.world_complete]
    for i in range(goals.size()):
        if goals[i] and not sim.state.main_claimed.has(i):sim.state.main_ready[str(i)]=true
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
    sim.touch()
    if not SaveService.save_now():sim.state=before;sim.touch();return false
    return true
func offline_snapshot() -> Dictionary:
    var eligible: Dictionary={"weapon":[],"outfit":[],"consumable":[]}
    for id in sim.state.items:
        var kind: String=sim.catalog.items[id].kind
        if eligible.has(kind) and sim.quantity(id)>0:eligible[kind].append(id)
    return {"time":maxf(Time.get_unix_time_from_system(),float(sim.state.get("offline_snapshot",{}).get("time",0))),"cap":[5,8,12,18,24,36,48][sim.level("offline_cap")]*3600,"coins":(120+60*sim.level("offline_coins"))*(1+bonus("offline_coins")),"gems":(2+.5*sim.level("offline_gems"))*(1+bonus("offline_gems")),"eligible":eligible,"rates":{"weapon":(1+.5*sim.level("offline_weapon_rate"))*sim.level("offline_weapon"),"outfit":(1+.5*sim.level("offline_outfit_rate"))*sim.level("offline_outfit"),"consumable":(2+sim.level("offline_consumable_rate"))*sim.level("offline_consumable")},"items_bonus":1+bonus("offline_items"),"eligible_time":sim.state.prestige_batch.is_empty()}
## Background settlement only records what was earned: rewards wait in offline_pending (saved, merged
## across several absences, each interval capped as before) until the player claims them in game.
## Only the claim pays out and advances the offline counters that discover offline opportunities.
func settle_offline(now: float=-1) -> void:
    var snap: Dictionary=sim.state.get("offline_snapshot",{})
    if snap.is_empty():return
    if now<0:now=Time.get_unix_time_from_system()
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
func normalize_snapshot(data: Dictionary) -> Dictionary:
    var out: Dictionary=data.duplicate(true)
    # Change 8 fields are derived for older current-schema saves, never copied from the live state.
    var change8: Array=[]
    for key in ["skills_seen","discovered_spots","camps_known"]:
        if not out.has(key):change8.append(key);out[key]=[] if key=="skills_seen" else {}
    for key in sim.state:
        if not out.has(key):out[key]=sim.state[key].duplicate(true) if sim.state[key] is Dictionary or sim.state[key] is Array else sim.state[key]
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
    migrate_change8(out,change8)
    return out
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
        out.auto_slots=slots
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
    if missing.has("discovered_spots") and out.get("discovered") is Dictionary:
        for key in out.discovered:
            var g:=int(key)
            if g<0 or g>=sim.catalog.groups.size():continue
            var cells: Dictionary=explored.get(str(int(sim.catalog.groups[g].stage)),{})
            for v in variants(g):
                if cells.has(cell_key(spot(g,v))):out.discovered_spots[spot_key(g,v)]=true
    if missing.has("camps_known"):
        for st in range(1,9):
            var cells: Dictionary=explored.get(str(st),{})
            var known: Array=[]
            for i in range(sim.catalog.stages[st-1].spawns.size()):
                var a: Array=sim.catalog.stages[st-1].spawns[i]
                if cells.has(cell_key(Vector2(a[0],a[1]))):known.append(i)
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
    if int(data.get("schema",0))!=7 or not finite_tree(data):return false
    for key in sim.state:
        if not data.has(key):return false
        var a: int=typeof(sim.state[key]);var b: int=typeof(data[key])
        if a in [TYPE_INT,TYPE_FLOAT]:
            if b not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(data[key])):return false
        elif a!=b:return false
    if not data.tutorial.has_all(["mode","done","seen"]) or data.tutorial.mode not in ["pending","guided","basic","none"] or not data.tutorial.done is Array or not data.tutorial.seen is Array:return false
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
        if not r.has_all(["qty","merge","extras"]) or r.qty<0 or r.qty!=floor(r.qty) or r.merge<0 or r.merge>sim.merge_cap(id):return false
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
        if int(key) not in range(1,9) or not data.explored[key] is Dictionary:return false
        for cell in data.explored[key]:
            var bits=str(cell).split(",")
            if bits.size()!=2 or not bits[0].is_valid_int() or not bits[1].is_valid_int():return false
            var bounds: Array=sim.catalog.stages[int(key)-1].size
            if int(bits[0])<0 or int(bits[1])<0 or int(bits[0])>=ceili(bounds[0]/fog_rules.cell_size) or int(bits[1])>=ceili(bounds[1]/fog_rules.cell_size):return false
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
func drops_valid(drops) -> bool:
    if not drops is Array:return false
    for d in drops:
        if not d is Dictionary or not d.has_all(["uid","item","x","y","ttl","group"]):return false
        if not sim.catalog.items.has(d.item) or not number(d.group) or int(d.group) not in range(sim.catalog.groups.size()):return false
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
            return sim.tr("CHAIN_PROGRESS") % [index+1,chain.size(),sim.tr("GOAL_"+str(q[0]).to_upper()),str(q[1]).trim_prefix("unit-").capitalize(),int(o.get("count",0)),int(q[2])]
    if path=="hunter":
        var k="boss:"+boss_goal(path,n)
        return "%d / %d" % [counter(k)-float(o.baseline.get(k,0)),hunter_goal(n)]
    if path=="offline":
        var value=sim.state.offline_total/3600 if n==1 else (sim.state.offline_longest/3600 if n==2 else sim.state.offline_income)
        return "%.1f / %d" % [value,[72,24,10000][n-1]]
    if path=="offering":return "%d / %d coins · %d / %d gems" % [mini(sim.state.online_coins,sim.state.coins),[2000,20000,100000][n-1],mini(sim.state.online_gems,sim.state.gems),[30,100,300][n-1]]
    if path=="masterwork":
        var best:=0
        for key in o:
            if key.begins_with("merge_") and int(sim.catalog.items[key.trim_prefix("merge_")].tier)>=n:best=maxi(best,int(o[key]))
        return sim.tr("PROGRESS_MERGE") % best
    if path=="arsenal":
        var weapons: Dictionary={};var outfits: Dictionary={}
        for key in o:
            if key.begins_with("merge_") and int(o[key])>=50:
                var item: Dictionary=sim.catalog.items[key.trim_prefix("merge_")]
                if int(item.tier)>=(2 if n==3 else 1):
                    if item.kind=="weapon":weapons[key]=true
                    else:outfits[item.family]=true
        var need:=1 if n==1 else 3
        return sim.tr("PROGRESS_ARSENAL") % [mini(weapons.size(),need),need,mini(outfits.size(),need),need]
    if path=="trophy":
        var bosses: Array=[["snowman","cyan-robot"],["gray-cat","elephant","teal-dinosaur"],["squirrel","red-fox","black-cat","grim-reaper"]][n-1]
        var got:=0
        for boss in bosses:
            if o.get("trophy_boss-"+boss,false):got+=1
        return sim.tr("PROGRESS_TROPHY") % [got,bosses.size()]
    if path=="collection":
        var names: Array=[['blue-cap','red-scarf','chef-hat'],['straw-hat','sunglasses','yellow-cap'],['bunny-ears','cat-ears','elf-ears']][n-1]
        # The full panel is the detailed reference: each required outfit by name with its count.
        var parts: Array=[]
        var counts:=collection_counts(id)
        for i in range(names.size()):
            parts.append("%s %d/%d" % [sim.catalog.display_name(contract_outfit(names[i])),counts[i],10+10*n])
        return sim.tr("PROGRESS_COLLECTION") % " · ".join(parts)
    if path=="challenge":return sim.tr("PROGRESS_CHALLENGE")
    if path=="regional":return _regional_progress(n)
    return sim.tr("IN_PROGRESS")

## One short line for the followed-opportunity HUD: the current step and its next objective with
## numeric progress ("Step 2/3 — Hunt Wolf Hood: 12/100"); details stay in the Prestige panel.
func follow_summary(id: String) -> String:
    var o: Dictionary=sim.state.opportunities.get(id,{})
    if o.is_empty():return ""
    if o.ready:return sim.tr("FOLLOW_READY")
    var n=int(id.right(1));var path=id.split("_o")[0]
    if path in ["expedition","specialist"]:
        var chain=chain_for(id);var index=int(o.get("step",0))
        if index>=chain.size():return sim.tr("FOLLOW_READY")
        var q: Array=chain[index]
        var g:=group_id(str(q[1]))
        var target: String=(" "+str(sim.catalog.groups[g].name)) if g>=0 else ""
        return sim.tr("FOLLOW_STEP") % [index+1,chain.size(),sim.tr("GOAL_"+str(q[0]).to_upper())+target,int(o.get("count",0)),int(q[2])]
    # Change 11: a collection's follower never names, shows or describes the items it needs (the
    # Prestige panel does). Step = outfits completed + 1; progress is the closest unfinished one.
    if path=="collection":
        var goal: int=10+10*n
        var counts:=collection_counts(id)
        var done:=0;var best:=0
        for c in counts:
            if c>=goal:done+=1
            else:best=maxi(best,c)
        if done>=counts.size():return sim.tr("FOLLOW_COLLECTION_SUBMIT")
        return sim.tr("FOLLOW_COLLECT") % [done+1,counts.size(),best,goal]
    if path in ["hunter","challenge"]:
        var g:=group_id(boss_goal(path,n))
        var boss: String=str(sim.catalog.groups[g].name)
        if path=="challenge":return sim.tr("FOLLOW_CHALLENGE") % boss
        var k="boss:"+boss_goal(path,n)
        return sim.tr("FOLLOW_HUNT") % [boss,int(counter(k)-float(o.baseline.get(k,0))),hunter_goal(n)]
    return opportunity_progress(id)

## Copies of each required outfit found this run since the contract was discovered, capped at its goal.
func collection_counts(id: String) -> Array:
    var o: Dictionary=sim.state.opportunities.get(id,{})
    var n=int(id.right(1))
    var names: Array=[['blue-cap','red-scarf','chef-hat'],['straw-hat','sunglasses','yellow-cap'],['bunny-ears','cat-ears','elf-ears']][n-1]
    var result: Array=[]
    for name in names:
        var item: String=contract_outfit(name)
        result.append(mini(10+10*n,int(minf(float(sim.state.online_items.get(item,0)),float(o.get("item_"+item,0))))))
    return result

func _regional_progress(n: int) -> String:
    var explored: Array=[];var bosses:=0;var killed:=0;var camps:=0;var owned:=0
    for st in ([1,2] if n==1 else ([3,4] if n==2 else [7,8])):
        var d: Dictionary=sim.catalog.stages[st-1]
        var area: float=ceil(d.size[0]/fog_rules.cell_size)*ceil(d.size[1]/fog_rules.cell_size)
        explored.append("%d%%" % mini(100,int(100.0*sim.state.explored.get(str(st),{}).size()/area)))
        camps+=d.spawns.size();owned+=sim.state.camps.get(str(st),[]).size()
        for g in d.groups:
            if sim.catalog.groups[g].boss:
                bosses+=1
                if sim.state.run_kills.get(sim.catalog.groups[g].id,0)>0:killed+=1
    return sim.tr("PROGRESS_REGIONAL") % [" + ".join(explored),killed,bosses,owned,camps]
