class_name LootSimulation
extends Node
## Single authoritative owner for combat, inventory transactions and rewards.
## Presentation never applies damage. All timers use simulated, pausable time.
signal combat_group_changed(group: int)
signal gem_pickup(amount: float)
signal changed
signal feedback(actor_id: String, amount: float, healing: bool)
signal event(key: String)
signal chatter(actor_id: String, key: String)
## Major milestones for presentation (discovered/ready opportunity, card, prestiged, stage).
signal milestone(kind: String, id: String)
## The player came back to life at the active camp (presentation recenters the camera).
signal revived
## First copy of a skill family ever obtained: its Player Upgrades become visible (Change 8).
signal skill_discovered(family: String)
var catalog := LootCatalog.new()
var campaign = preload("res://scripts/game/campaign.gd").new(self)
signal spell_cast(actor_id: String, skill: String, position: Vector2)
var rng := RandomNumberGenerator.new()
var state: Dictionary = {}
var locked_target: String=""
var manual_target: String=""
var movement := Vector2.ZERO
var suspended := false
var revision: int = 0
var _save_clock := 0.0
var _stats: Dictionary = {}
var _stats_revision := -1

func _ready() -> void:
    rng.randomize()
    new_profile()
    SaveService.register_section("lootfarmer", snapshot, restore, new_profile)

func touch() -> void:
    revision += 1
    _stats_revision = -1
    SaveService.mark_dirty()
    changed.emit()

func new_profile() -> void:
    suspended=false
    clear_target()
    state = {"schema":7,"group_kills":[0,0,0,0],"player_level":1,"xp":0.0,"coins":0,"gems":0,"items":{},"gear":["","",""],"supplies":[""],
        "weapon":"","outfit":"","upgrades":{},"auto_slots":[],
        "spawns":[0],"spawn":0,"cards":{},"prestiges":0,"offer":[],"victory":false,
        "focus":-1,"focus_variant":2,"boost_time":0.0,"boost_power":0.0,"use_cd":0.0,"history":[],
        "pickups":[],"next_pickup":0,"clock":0.0,"collect_clock":0.0,"collect_clocks":[0.0,0.0,0.0,0.0],"merge_clock":0.0,
        "use_clock":0.0,"summon_clock":0.0,"next_cat":0,"help":0,"paused":false,
        "playtime_total":0.0,"playtime_run":0.0}
    campaign.initialize()
    _reset_world()
    campaign.reveal()
    movement = Vector2.ZERO
    milestone.emit("reset","")
    touch()

func _actor(id: String, x: float, y: float, hp: float, group: int) -> Dictionary:
    return {"id":id,"x":x,"y":y,"home_x":x,"home_y":y,"hp":hp,"group":group,
        "respawn":0.0,"dead_age":0.0,"cooldown":0.0,"windup":0.0,"target":"",
        "attack_age":9.0,"hurt":0.0,"quiet":0.0,"aggro":false,"returning":false,"moving":false,"facing":1.0}

func _reset_world() -> void:
    campaign.configure_stage()
    var point: Array=catalog.world.spawns[int(state.spawn)]
    state.player = _actor("player",point[0],point[1],100,-1)
    state.player["idle"] = 0.0
    state.player.quiet=5.0
    state.enemies = []
    _sync_spawn_counts()
    _stats_revision = -1
    state.player.hp = stats().hp

func spawn_amount(group: int,extra: int=0) -> int:
    return 1 if catalog.groups[group].boss else mini(6,3+level("spawn_amount",group)+extra)

func spawn_cooldown(group: int,extra: int=0) -> float:
    var base: float=catalog.groups[group].respawn
    return base if catalog.groups[group].boss else base*(1.0-.1*(level("spawn_cooldown",group)+extra))

## Authored home of a spawned actor; saved actors are re-homed here so layout changes load cleanly.
func spawn_home(tier: int,kind: int,i: int) -> Vector2:
    return campaign.spot(tier,kind)+Vector2((i%3-1)*24,(i/3)*26)

func _rehome(actors: Array) -> void:
    for a in actors:
        var bits: PackedStringArray=str(a.id).trim_prefix("g").split("_")
        if bits.size()!=3:continue
        var home:=spawn_home(int(a.group),int(a.get("variant",2)),int(bits[2]))
        if Vector2(a.home_x,a.home_y).distance_to(home)>1:
            a.home_x=home.x;a.home_y=home.y;a.x=home.x;a.y=home.y;a.aggro=false;a.returning=false

func _sync_spawn_counts() -> void:
    for tier in campaign.stage().groups:
        for kind in campaign.variants(tier):
            for i in range(spawn_amount(tier)):
                var id:="g%d_v%d_%d" % [tier,kind,i]
                if not _find_actor(id).is_empty():continue
                var pos: Vector2=spawn_home(tier,kind,i)
                var a:=_actor(id,pos.x,pos.y,1,tier)
                a["variant"]=kind
                a.hp=enemy_definition(tier,kind).hp
                state.enemies.append(a)

func snapshot() -> Dictionary:
    var result := state.duplicate(true)
    result["rng_state"] = str(rng.state)
    result["offline_snapshot"] = state.offline_snapshot.duplicate(true) if suspended else campaign.offline_snapshot()
    return result

func restore(data: Dictionary) -> void:
    # Development profiles may reset. Current snapshots still validate before use.
    if int(data.get("schema",0))!=7:
        new_profile()
        SaveService.write_blocked=false
        SaveService.last_load_result="development_reset"
        return
    data=campaign.normalize_snapshot(data)
    if not _valid_snapshot(data):
        new_profile()
        SaveService.write_blocked=false
        SaveService.last_load_result="invalid_profile_reset"
        return
    clear_target()
    state = data.duplicate(true)
    campaign.configure_stage()
    rng.state = int(state.get("rng_state",str(rng.state)))
    _rehome(state.enemies)
    for world_state in state.stage_worlds.values():_rehome(world_state.enemies)
    _sync_spawn_counts()
    movement = Vector2.ZERO
    for a in [state.player] + state.enemies:
        a.windup = 0.0
        a.target = ""
        a.attack_age = 9.0
        a["returning"] = bool(a.get("returning",false))
        a.moving = false
    state.player.idle = 0.0
    state.paused = false # Pause is session-owned.
    campaign.reveal()
    campaign.settle_offline()
    touch()

func _valid_snapshot(data: Dictionary) -> bool:
    return campaign.valid_snapshot(data)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED:
        state.offline_snapshot=campaign.offline_snapshot()
        suspended = true
        movement = Vector2.ZERO
        SaveService.save_now()
    elif what == NOTIFICATION_APPLICATION_RESUMED:
        campaign.settle_offline()
        suspended = false
        movement = Vector2.ZERO

func _physics_process(delta: float) -> void:
    if not suspended:
        step(minf(delta,.1))

func level(id: String, group: int = -1) -> int:
    return int(state.upgrades.get(_upgrade_key(id,group),0))

func _upgrade_key(id: String, group: int) -> String:
    return id if group < 0 else "%s:%d" % [id,group]

func card(id: String) -> float:
    return 1.0+campaign.bonus(id)

func record(id: String) -> Dictionary:
    if not state.items.has(id):
        var extras: Dictionary = {}
        var pool: Array = catalog.items[id].extras.keys()
        for i in range(mini(1,pool.size())):
            var at := rng.randi_range(0,pool.size()-1)
            var key: String = pool.pop_at(at)
            var span: Array = catalog.items[id].extras[key]
            extras[key] = rng.randf_range(span[0],span[1])
        state.items[id] = {"qty":0,"merge":0,"extras":extras}
    return state.items[id]

func quantity(id: String) -> int:
    return int(state.items.get(id,{}).get("qty",0))

func normal(id: String) -> Dictionary:
    var output: Dictionary = {}
    var merge_level := int(state.items.get(id,{}).get("merge",0))
    var levels:=merge_levels(id,merge_level)
    var stock:=1.0+float(catalog.progression.merge.stock_bonus_per_copy)*maxi(0,quantity(id)-1) if merge_level>=merge_cap(id) else 1.0
    for stat in catalog.items[id].normal:
        var pair: Array = catalog.items[id].normal[stat]
        output[stat] = (float(pair[0]) + merge_gain(id,stat) * levels) * stock
    return output

## Outfits and skills grow from copies of themselves (no evolution, Change 8); weapons and supplies
## keep ^100 and evolve. Caps and the curve live in catalog.progression.merge.
func copy_growth(id: String) -> bool:
    return str(catalog.items[id].kind) in ["outfit","skill"]

func merge_cap(id: String) -> int:
    return int(catalog.progression.merge.copy_cap if copy_growth(id) else catalog.progression.merge.weapon_cap)

## Effective merge levels. Weapons stay linear to ^100. Outfits (Change 9): linear to linear_levels,
## then outfit_tail_rate levels per copy, so with a 2%-of-base merge gain the core stat is
## base x (1 + 0.02 min(m,100) + 0.01 max(0,m-100)): 3x at ^100, 7x at ^500. Skills keep the Change 8
## logarithmic tail.
func merge_levels(id: String,merge_level: int) -> float:
    var m: Dictionary=catalog.progression.merge
    var linear: float=float(m.linear_levels)
    merge_level=clampi(merge_level,0,merge_cap(id))
    if not copy_growth(id) or merge_level<=linear:return float(merge_level)
    if str(catalog.items[id].kind)=="outfit":return linear+float(m.outfit_tail_rate)*(merge_level-linear)
    return linear+float(m.tail_scale)*log(1.0+(merge_level-linear)/float(m.tail_scale))

## Outfit milestone effects (Change 9, catalog.progression.outfit_milestones): Guard (Defense), Recovery
## (fraction of max HP per second) and a share of the outfit's own core HP. Later steps replace the
## Guard/Recovery values. stat_sources() applies them for the equipped outfit only.
func outfit_milestones(id: String) -> Dictionary:
    var out:={"defense":0.0,"regen_pct":0.0,"hp":0.0}
    if not catalog.items.has(id) or str(catalog.items[id].kind)!="outfit":return out
    var merge_level:=int(state.items.get(id,{}).get("merge",0))
    var tier:=float(catalog.items[id].tier)
    var share:=0.0
    for step in catalog.progression.outfit_milestones:
        if merge_level<int(step.merge):break
        if step.has("defense_per_tier"):out.defense=float(step.defense_per_tier)*tier
        if step.has("regen_pct_per_tier"):out.regen_pct=float(step.regen_pct_per_tier)*tier
        if step.has("hp_share"):share=float(step.hp_share)
    # A share of the core HP (base + merges), never of the spare-copy stock bonus or random extras.
    if share>0:
        var pair: Array=catalog.items[id].normal.get("hp",[0.0,0.0])
        out.hp=share*(float(pair[0])+merge_gain(id,"hp")*merge_levels(id,merge_level))
    return out

## Next milestone this outfit can reach, or {} at the end of the track.
func next_outfit_milestone(id: String) -> Dictionary:
    var merge_level:=int(state.items.get(id,{}).get("merge",0))
    for step in catalog.progression.outfit_milestones:
        if merge_level<int(step.merge):return step
    return {}

## Share of an owned but unequipped item's stats that still counts (Change 9: outfits 15%, weapons 30%).
func stored_factor(id: String) -> float:
    match str(catalog.items[id].kind):
        "weapon":return float(catalog.progression.stored_weapon_factor)
        "outfit":return float(catalog.progression.stored_outfit_factor)
    return 0.0

## Stat gained by the next single merge (shrinks past the linear part for outfits and skills).
func next_merge_gain(id: String,stat: String) -> float:
    var m:=int(record(id).merge)
    return merge_gain(id,stat)*(merge_levels(id,m+1)-merge_levels(id,m))

func stats() -> Dictionary:
    if _stats_revision == revision and not _stats.is_empty():
        return _stats
    var s := {"hp":0.0,"damage":0.0,"defense":0.0,"crit":0.0,"crit_damage":0.0,"lifesteal":0.0,"regen":0.0,"regen_pct":0.0,"speed":0.0}
    for bucket in stat_sources().values():
        for key in bucket:s[key]=float(s.get(key,0))+float(bucket[key])
    s.hp *= card("hp")
    s.damage *= card("damage")
    s.crit += campaign.bonus("crit")
    s.crit_damage += campaign.bonus("crit_damage")
    s.lifesteal += campaign.bonus("lifesteal")
    s.crit = minf(.75,s.crit)
    s.crit_damage = minf(4,s.crit_damage)
    s.lifesteal = minf(.15,s.lifesteal)
    s.speed = minf(2,s.speed)
    _stats = s
    _stats_revision = revision
    return s

## Effective stats if this weapon/outfit pair were equipped. Exact: uses the same getter.
func stats_with(weapon: String, outfit: String) -> Dictionary:
    var saved: Array=[state.weapon,state.outfit]
    state.weapon=weapon;state.outfit=outfit;_stats_revision=-1
    var result: Dictionary=stats().duplicate()
    state.weapon=saved[0];state.outfit=saved[1];_stats_revision=-1
    return result

func xp_required(player_level: int = -1) -> float:
    var current:=int(state.player_level) if player_level<0 else player_level
    return ceil(float(catalog.progression.xp_base)*pow(current,float(catalog.progression.xp_growth)))

func gain_xp(amount: float) -> void:
    if state.player_level>=1000:
        return
    state.xp+=maxf(0,amount)
    var old_hp:=float(stats().hp)
    var gained:=false
    while state.player_level<1000 and state.xp>=xp_required():
        state.xp-=xp_required()
        state.player_level+=1
        gained=true
    if state.player_level==1000:
        state.xp=0.0
    touch()
    if gained:
        if state.player.hp>0:
            var heal:=float(stats().hp)-old_hp
            state.player.hp+=heal
            feedback.emit("player",heal,true)
        event.emit("PLAYER_LEVEL_UP")

## Definitions are immutable catalog data; build each (group, variant) once. Callers must not mutate.
var _definitions: Dictionary={}
func enemy_definition(group: int,variant: int=2) -> Dictionary:
    var key:=group*8+variant
    if not _definitions.has(key):
        _definitions[key]=_build_definition(group,variant)
        _definitions[key].make_read_only()
    return _definitions[key]

func _build_definition(group: int,variant: int) -> Dictionary:
    var def: Dictionary=catalog.groups[group].duplicate(true)
    if not def.boss:
        def.hp*=1.25 if variant==0 else (.75 if variant==1 else (1.35 if variant==3 else 1.0))
        def.damage*=.75 if variant==0 else (1.25 if variant==1 else (1.35 if variant==3 else 1.0))
        # Loot is [shared weapon, stage-tier outfit]; one-piece variants drop only what they wear.
        if variant==0:
            def.weapon=""
            def.loot=def.loot.filter(func(id):return catalog.items[id].kind=="outfit")
        elif variant==1:
            def.body=""
            def.loot=def.loot.filter(func(id):return catalog.items[id].kind=="weapon")
        if variant!=3:def.skills=[]
    return def

func slots(id: String) -> Array:
    return state.supplies if catalog.items[id].kind == "consumable" else state.gear

func equipped(id: String) -> bool:
    return state.weapon == id or state.outfit == id or state.get("skills",[]).has(id)

func can_add(id: String) -> bool:
    return quantity(id)>0 or slots(id).has("")

func add_item(id: String, amount: int = 1, _legacy_reward_flag: bool = true) -> bool:
    if not catalog.items.has(id) or amount < 1:
        return false
    if not can_add(id):
        return false
    var r := record(id)
    if int(r.qty)==0:
        var list := slots(id)
        list[list.find("")] = id
    r.qty += amount
    history("HISTORY_ITEM",id,amount,0)
    if catalog.items[id].kind=="skill":discover_skill(str(catalog.items[id].skill))
    touch()
    return true

## Skill upgrades stay hidden until a copy of that skill is obtained once (any run: the record is
## kept by prestige, cleared by Hard Reset). Only the first copy notifies.
func discover_skill(family: String,silent:=false) -> void:
    if family=="" or state.skills_seen.has(family):return
    state.skills_seen.append(family)
    if not silent:skill_discovered.emit(family)

func skill_seen(family: String) -> bool:
    return state.skills_seen.has(family)

func _remove(id: String, amount: int) -> void:
    var r := record(id)
    r.qty -= amount
    state.online_items[id]=maxf(0,float(state.online_items.get(id,0))-amount)
    for op in state.opportunities.values():
        if op.has("item_"+id):op["item_"+id]=maxf(0,float(op["item_"+id])-amount)
    if int(r.qty)==0:
        var list := slots(id)
        var index := list.find(id)
        if index >= 0:
            list[index] = ""

func history(key: String, id: String, amount: float, coins: float) -> void:
    if key=="HISTORY_CURRENCY" and amount>0:
        gem_pickup.emit(amount)
    var list: Array = state.history
    if not list.is_empty() and list[0].key==key and list[0].id==id and float(state.clock)-float(list[0].time)<1.0:
        list[0].amount += amount
        list[0].coins += coins
        return
    list.push_front({"key":key,"id":id,"amount":amount,"coins":coins,"time":state.clock})
    if list.size()>10:
        list.pop_back()

func merge(id: String, all: bool = false) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if quantity(id)<2:
        return fail("NEED_DUPLICATES")
    var r := record(id)
    var count := mini(int(r.qty)-1,merge_cap(id)-int(r.merge))
    if not all:
        count = mini(1,count)
    if count<1:
        return fail("MERGE_MAX")
    _remove(id,count)
    r.merge += count
    campaign.progress("merge",id,count)
    touch()
    return true

func evolve(id: String) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    var target: String = catalog.items[id].next
    if target=="" or int(record(id).merge)<int(catalog.progression.evolution.required_merge) or quantity(id)<int(catalog.progression.evolution.spare_cost)+1:
        return fail("EVOLUTION_NEEDS")
    if not can_add(target):
        return fail("INVENTORY_FULL")
    # Every validation precedes both mutations; output is committed with its cost.
    _remove(id,int(catalog.progression.evolution.spare_cost))
    add_item(target,1,false)
    touch()
    campaign.progress("evolve",id,1)
    event.emit("EVOLVED")
    return true

func equip(id: String) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if quantity(id)<1 or catalog.items[id].kind=="consumable":
        return false
    var kind: String = catalog.items[id].kind
    if kind=="skill":return campaign.equip_skill(id)
    state[kind] = "" if state[kind]==id else id
    campaign.progress("equip",id,1)

    touch()
    state.player.hp = minf(state.player.hp,stats().hp)
    return true


func reroll(id: String) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    var cost: int = ceili(float(catalog.items[id].get("reroll",0))*(1-campaign.bonus("reroll_discount")))
    if quantity(id)<1 or cost==0 or catalog.items[id].extras.is_empty():
        return false
    if not pay("gems",cost):
        return false
    var r := record(id)
    var old_qty: int = r.qty
    var old_merge: int = r.merge
    state.items.erase(id)
    r = record(id)
    r.qty = old_qty
    r.merge = old_merge
    touch()
    return true

func bind_auto(slot: int) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if state.auto_slots.has(slot):
        state.auto_slots.erase(slot)
    else:
        if state.auto_slots.size()>=level("auto_use"):
            return fail("AUTO_SLOTS_FULL")
        state.auto_slots.append(slot)
    touch()
    return true

func use_item(id: String) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if quantity(id)<1 or state.player.hp<=0:
        return fail("CANNOT_USE")
    if catalog.art_id(id)=="potion":
        if state.player.hp>stats().hp*.8 or state.use_cd>0:
            return fail("POTION_CONDITION")
        var gain := minf(normal(id).heal,stats().hp-state.player.hp)
        state.player.hp += gain
        state.use_cd=float(catalog.progression.potion_cooldown)
        feedback.emit("player",gain,true)
    elif catalog.art_id(id)=="coin_boost":
        state.boost_time = coin_boost_duration()
        state.boost_power = maxf(state.boost_power,normal(id).coin_bonus)
    else:
        return false
    state["consumable_uses"]=int(state.get("consumable_uses",0))+1
    _remove(id,1)
    touch()
    return true

## Real Coin Tonic duration in seconds (authored in catalog.progression; a new tonic refreshes it).
func coin_boost_duration() -> float:
    return float(catalog.progression.get("coin_boost_duration",30.0))

func purchase_consumable(id: String) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if id not in ["potion","coin_boost"]:
        return fail("CANNOT_USE")
    var cost := 10 if id=="potion" else 30
    if not can_add(id):
        return fail("INVENTORY_FULL")
    if not pay("coins",cost):
        return false
    add_item(id,1,false)
    return true

func upgrade_cost(id: String, group: int = -1) -> int:
    return campaign.upgrade_cost(id,group)

func upgrade_maxed(id: String, group: int = -1) -> bool:
    if level(id,group)>=int(catalog.upgrades[id].cap):
        return true
    if id=="gem_chance":
        return gem_base_chance()>=float(catalog.progression.gem_limits.normal_cap)
    if id=="boss_gem_chance":return gem_base_chance()+level(id)*.05>=.6
    return false

func buy_upgrade(id: String, group: int = -1) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if not catalog.upgrades.has(id):return false
    var def: Dictionary = catalog.upgrades[id]
    if not _upgrade_scope_valid(id,group):return false
    var reason:=upgrade_block_reason(id,group)
    if not reason.is_empty():
        return fail(reason)
    if not pay(def.currency,upgrade_cost(id,group)):
        return false
    var key := _upgrade_key(id,group)
    state.upgrades[key] = level(id,group)+1
    if id=="spawn_amount":_sync_spawn_counts()
    if id=="gear_slots":
        state.gear.append("")
    if id=="supply_slots":
        state.supplies.append("")
    campaign.upgrade_bought(id,group)
    touch()
    return true

func pay(currency: String, cost: int) -> bool:
    if cost<0 or state[currency]<cost:
        return fail("NOT_ENOUGH_"+currency.to_upper())
    state[currency] -= cost
    state["online_"+currency]=maxf(0,float(state.get("online_"+currency,0))-cost)
    return true

func select_spawn(index: int) -> bool:
    return campaign.camp_action(int(state.stage),index,false)

func focus(group: int,variant: int=2) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if group<0 or group>=catalog.groups.size() or not campaign.stage().groups.has(group) or not campaign.discovered(group) or not campaign.variants(group).has(variant):
        return false
    if catalog.groups[group].boss:variant=2
    # Auto-farm never walks to a spot the player has not found (no hidden coordinates).
    if not campaign.spot_discovered(group,variant):
        return fail("SPOT_UNDISCOVERED")
    if level("focus",group)==0:
        return fail("AUTOMATION_LOCKED")
    clear_target()
    var same:=int(state.focus)==group and int(state.focus_variant)==variant
    state.focus = -1 if same else group
    state.focus_variant=variant
    touch()
    return true

func fail(key: String) -> bool:
    event.emit(key)
    return false

func collect(uid: int) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    for pickup in state.pickups:
        if int(pickup.uid)==uid:
            if add_item(pickup.item):
                campaign.progress("collect",pickup.item,1)
                if catalog.items[pickup.item].kind in ["weapon","outfit"]:campaign.progress("gear",pickup.item,1)
                state.pickups.erase(pickup)
                return true
            return fail("INVENTORY_FULL")
    return false

func prestige(card_id: String) -> bool:
    return campaign.choose_card(card_id)

func position_of(a: Dictionary) -> Vector2:
    return Vector2(a.x,a.y)

func nearest_group() -> int:
    var result: int=campaign.stage().groups[0]
    var distance:=INF
    for g in campaign.stage().groups:
        var pos:=Vector2(catalog.groups[g].center[0],catalog.groups[g].center[1])
        if campaign.discovered(g) and position_of(state.player).distance_to(pos)<distance:
            result=g
            distance=position_of(state.player).distance_to(pos)
            distance=position_of(state.player).distance_to(pos)
    return result

func _move(a: Dictionary, destination: Vector2, speed: float, delta: float) -> void:
    var old := position_of(a)
    var next := campaign.blocked_step(old,old.move_toward(destination,speed*delta),destination)
    a.x = clampf(next.x,14,catalog.world.size[0]-14)
    a.y = clampf(next.y,30,catalog.world.size[1]-14)
    a.moving = old.distance_to(position_of(a))>.01
    if a.id=="player" and a.moving:
        campaign.reveal_segment(old,position_of(a))
    if absf(next.x-old.x)>.01:
        a.facing = signf(next.x-old.x)

func _find_actor(id: String) -> Dictionary:
    if id=="player":
        return state.player
    for a in state.enemies:
        if a.id==id:
            return a
    return {}

func _start_attack(a: Dictionary, target: Dictionary, interval: float) -> void:
    if a.id=="player" and int(target.group) in range(catalog.groups.size()):
        combat_group_changed.emit(int(target.group))
    campaign.begin_encounter(target if a.id=="player" else a)
    a.target=target.id
    a.windup = minf(.22,interval*.4)
    a.attack_contact = a.windup
    a.attack_duration = minf(interval,a.attack_contact*2.5)
    a.cooldown = interval
    a.attack_age = 0.0
    var dx := float(target.x)-float(a.x)
    if absf(dx)>.01:
        a.facing=signf(dx)

func _actor_timers(a: Dictionary, dt: float) -> void:
    a.moving=false
    a.attack_age += dt
    a.cooldown = maxf(0,a.cooldown-dt)
    a.hurt = maxf(0,a.hurt-dt)
    a.quiet += dt
    if a.hp<=0:
        a.dead_age += dt
        a.respawn=maxf(0,a.respawn-dt)

func _resolve_attack(a: Dictionary, dt: float) -> void:
    if a.hp<=0 or a.windup<=0:
        return
    a.windup -= dt
    if a.windup>0:
        return
    # Clear target before contact so every scheduled action resolves once.
    var target := _find_actor(a.target)
    a.target=""
    if target.is_empty() or target.hp<=0 or position_of(a).distance_to(position_of(target))>float(catalog.world.reach)+8:
        return
    var is_player: bool = a.id=="player"
    var damage: float = stats().damage if is_player else float(enemy_definition(a.group,int(a.get("variant",2))).damage)
    var critical: bool=is_player and rng.randf()<stats().crit
    if is_player and int(target.group) in range(catalog.groups.size()):
        damage *= 1.0+achievement_damage(int(target.group))
    if critical:
        damage *= stats().crit_damage
    target["critical_hit"]=critical
    var defense: float = stats().defense if target.id=="player" else float(enemy_definition(target.group,int(target.get("variant",2))).defense)
    damage*=campaign.damage_multiplier(a,target)
    damage=maxf(1,damage*100.0/(100.0+defense))
    var actual := minf(damage,target.hp)
    target.hp=maxf(0,target.hp-damage)
    target.hurt=.16
    if is_player and not target.aggro:
        chatter.emit(target.id,"CHAT_SURPRISE")
    target.quiet=0.0
    target.aggro=not bool(target.get("returning",false))
    feedback.emit(target.id,actual,false)
    if is_player:
        a.hp=minf(stats().hp,a.hp+actual*stats().lifesteal)
        var target_def: Dictionary=catalog.groups[int(target.group)]
        if target_def.aggro_mode=="group":
            for other in state.enemies:
                if int(other.group)==int(target.group) and other.get("variant",2)==target.get("variant",2) and other.hp>0 and not other.returning and position_of(other).distance_to(position_of(target))<=float(target_def.assist_radius):
                    other.aggro=true
    if target.hp<=0:
        _kill(target)

func _kill(a: Dictionary) -> void:
    if a.id==locked_target or a.id=="player":clear_target()
    a.windup=0.0
    a.target=""
    a.dead_age=0.0
    a.aggro=false
    a.moving=false
    if a.id=="player":
        a.respawn=player_upgrade_value("respawn")
        for e in state.enemies:
            e.aggro=false
            e.erase("encounter_uses")
            e.windup=0.0
            e.returning=true
        event.emit("PLAYER_DIED")
    else:
        a.respawn=spawn_cooldown(int(a.group))
        state.group_kills[int(a.group)]+=1
        _reward(a)
        campaign.killed(a)
    touch()

func gear_chance(group: int) -> float:
    return group_upgrade_value("loot",group)

func gem_chance(group: int) -> float:
    return minf(.6 if catalog.groups[group].boss else .2,gem_base_chance()+achievement_gems(group)+(level("boss_gem_chance")*.05 if catalog.groups[group].boss else 0.0))

func coin_reward(group: int) -> float:
    return group_upgrade_value("coin_amount",group)

func _reward(a: Dictionary) -> void:
    var group:=int(a.group)
    var def:=enemy_definition(group,int(a.get("variant",2)))
    gain_xp(group_xp(group,int(a.get("variant",2))))
    var coins:=coin_reward(group)
    state.coins+=coins
    campaign.progress("coins","",coins)
    if rng.randf()<gem_chance(group):
        var gems:=gem_amount(0,group)
        state.gems+=gems
        state.online_gems+=gems
        history("HISTORY_CURRENCY","",gems,0)
    for id in def.loot:
        if rng.randf()<gear_chance(group):_drop(id,a)
    if rng.randf()<consumable_chance(group,"potion"):_drop("potion" if rng.randf()<.8 else "coin_boost",a)
    if not def.skills.is_empty() and rng.randf()<(.1 if def.boss else .05)+.01*level("skill_drop",group):
        _drop("skill_"+str(def.skills[rng.randi_range(0,def.skills.size()-1)]),a)

func _drop(id: String,a: Dictionary) -> void:
    state.next_pickup+=1
    state.pickups.append({"uid":state.next_pickup,"item":id,"x":a.x+rng.randf_range(-10,10),"y":a.y+rng.randf_range(-8,8),"ttl":300.0,"group":int(a.group)})

func step(dt: float) -> void:
    if state.is_empty() or get_tree().paused or suspended or not state.get("prestige_batch",{}).is_empty():
        return
    dt=minf(maxf(dt,0),.1)
    state.clock+=dt
    # Active play only: step never runs while paused, suspended (background, guide chooser) or
    # during a prestige choice, and offline settlement never advances these clocks.
    state.playtime_total=float(state.get("playtime_total",0.0))+dt
    state.playtime_run=float(state.get("playtime_run",0.0))+dt
    campaign.step(dt)
    state.use_cd=maxf(0,state.use_cd-dt)
    state.boost_time=maxf(0,state.boost_time-dt)
    if state.boost_time==0:
        state.boost_power=0.0
    var p: Dictionary=state.player
    _actor_timers(p,dt)
    for e in state.enemies.duplicate():
        _actor_timers(e,dt)
    if p.hp<=0:
        if p.respawn<=0:
            var point: Array=catalog.world.spawns[state.spawn]
            p.x=point[0]
            p.y=point[1]
            p.hp=stats().hp
            p.idle=0.0
            p.attack_age=9.0
            campaign.reveal()
            touch()
            revived.emit()
    else:
        # Recovery (regen_pct, equipped outfit milestone) heals like regen: alive, unpaused, online only.
        p.hp=minf(stats().hp,p.hp+(stats().regen+stats().hp*(campaign.rest_rate()+stats().regen_pct))*dt)
        if movement.length()>.1:
            clear_target()
            if int(state.focus)>=0:
                state.focus=-1
                touch()
            p.idle=0.0
            p.windup=0.0
            p.target=""
            p.attack_age=9.0
            _move(p,position_of(p)+movement.normalized()*100,campaign.move_speed(),dt)
        else:
            p.idle+=dt
            _resolve_attack(p,dt)
            if p.idle>=0.5 and p.windup<=0:
                var target:=_combat_target()
                var distance:=INF if target.is_empty() else position_of(p).distance_to(position_of(target))
                if not target.is_empty():
                    if distance>float(catalog.world.reach):
                        _move(p,position_of(target),campaign.move_speed(),dt)
                    elif p.cooldown<=0:
                        _start_attack(p,target,1.0/(1.0+stats().speed))
                elif int(state.focus)>=0:
                    _move(p,farming_position(),campaign.move_speed(),dt)
    for e in state.enemies.duplicate():
        if not state.enemies.has(e):
            continue
        var group:=int(e.group)
        var maxhp:=float(enemy_definition(group,int(e.get("variant",2))).hp)
        if e.hp<=0:
            if e.respawn<=0:
                e.hp=maxhp
                e.x=e.home_x
                e.y=e.home_y
                e.quiet=0.0
                e.erase("encounter_uses")
                e.returning=false
                e.attack_age=9.0
            continue
        if catalog.groups[group].final and state.keys.size()<13:
            e.aggro=false;e.windup=0
            continue
        if e.quiet>=5:
            e.hp=minf(maxhp,e.hp+maxhp*.1*dt)
        var home:=Vector2(e.home_x,e.home_y)
        var center: Vector2 = home
        if position_of(e).distance_to(center)>float(catalog.world.leash) or p.hp<=0:
            e.aggro=false
            e.erase("encounter_uses")
            e.returning=true
            e.windup=0.0

        if e.returning and position_of(e).distance_to(home)<2:
            e.returning=false
        if not e.returning and not e.aggro and catalog.groups[group].aggro_mode!="passive" and p.hp>0 and position_of(e).distance_to(position_of(p))<float(catalog.groups[group].aggro_radius):
            e.aggro=true
        if e.aggro and p.hp>0:
            campaign.begin_encounter(e)
            _resolve_attack(e,dt)
            if e.windup<=0:
                if position_of(e).distance_to(position_of(p))>float(catalog.world.reach):
                    _move(e,position_of(p),62*(.75 if float(e.get("slow",0))>0 else 1.0),dt)
                elif e.cooldown<=0:
                    _start_attack(e,p,float(catalog.groups[group].interval))
        elif position_of(e).distance_to(home)>1:
            _move(e,home,60,dt)
    if p.hp>0:
        _automate(dt)
    _save_clock+=dt
    if _save_clock>=2:
        _save_clock=0.0
        SaveService.mark_dirty()

func _automate(dt: float) -> void:
    campaign.automate(dt)

func clear_target() -> void:
    locked_target=""
    manual_target=""

func select_target(id: String) -> bool:
    var enemy:=_find_actor(id)
    if suspended or get_tree().paused or state.player.hp<=0 or enemy.is_empty() or enemy.hp<=0 or id=="player" or not campaign.target_allowed(enemy):
        return false
    locked_target=id
    manual_target=id
    state.focus=-1
    state.player.windup=0.0
    state.player.target=""
    state.player.attack_age=9.0
    state.player.idle=1.0
    touch()
    return true

func _combat_target() -> Dictionary:
    var target:=_find_actor(locked_target)
    if not target.is_empty() and target.hp>0 and campaign.target_allowed(target):
        return target
    clear_target()
    target={}
    var distance: float=catalog.world.acquisition
    for enemy in state.enemies:
        if enemy.hp<=0 or not campaign.target_allowed(enemy) or (int(state.focus)>=0 and (int(enemy.group)!=int(state.focus) or int(enemy.get("variant",2))!=int(state.focus_variant))):
            continue
        var d:=position_of(state.player).distance_to(position_of(enemy))
        if d<distance:
            distance=d
            target=enemy
    if not target.is_empty() and target.hp>0:
        locked_target=target.id
        return target
    return {}

func achievement_thresholds(group: int) -> Array:
    return catalog.progression.achievements.boss_kills if catalog.groups[group].boss else catalog.progression.achievements.kills

func achievement_level(group: int) -> int:
    if group not in range(catalog.groups.size()):
        return 0
    var result:=0
    for threshold in achievement_thresholds(group):
        if state.group_kills[group]>=threshold:
            result+=1
    return result

func achievement_damage(group: int) -> float:
    return achievement_level(group)*float(catalog.progression.achievements.damage_per_milestone)

func achievement_gems(group: int) -> float:
    return achievement_level(group)*float(catalog.progression.achievements.gems_per_milestone)

func consumable_chance(group: int,_id: String) -> float:
    return (.15 if catalog.groups[group].boss else .05)+minf(.15,.01*level("supply_drop",group))+campaign.bonus("supply_chance")

func group_xp(group: int,variant: int=2) -> float:
    return group_upgrade_value("group_xp",group,variant)

func merge_gain(id: String,stat: String) -> float:
    var definition: Dictionary=catalog.items[id]
    var gain: float=float(definition.get("merge_gain",{}).get(stat,float(definition.normal[stat][1])*3.0))
    return gain*card("merge")

## The enemy type whose automation merges this item: any type that drops its family (shared
## weapons and every tier of an outfit), preferring one with Auto Merge bought.
func gear_group(id: String) -> int:
    var family: String=str(catalog.items[id].get("family",id))
    var skill: String=str(catalog.items[id].get("skill",""))
    var first:=-1
    for g in range(catalog.groups.size()):
        var drops: bool=catalog.groups[g].skills.has(skill) if skill!="" else catalog.groups[g].loot.any(func(l):return str(catalog.items[l].family)==family)
        if not drops:continue
        if level("merge_gear",g)>0:return g
        if first<0:first=g
    return first

func can_auto_merge(id: String) -> bool:
    if catalog.items[id].kind=="consumable":
        return level("merge_supplies")>0
    var g:=gear_group(id)
    return g>=0 and level("merge_gear",g)>0

func _nearest_drop_group(y: float) -> int:
    return nearest_group()

func _upgrade_scope_valid(id: String,g: int) -> bool:
    if not catalog.upgrades.has(id):return false
    match str(catalog.upgrades[id].get("scope","global")):
        "type":return g in range(catalog.groups.size())
        "normal_type":return g in range(catalog.groups.size()) and not catalog.groups[g].boss
        "stage":return g>=1 and g<=8
        "camp":return g>=10 and g<83 and g%10<catalog.stages[g/10-1].spawns.size()
    return g==-1

func action_lock_reason() -> String:
    return "ACTION_PAUSED" if get_tree().paused else ("ACTION_SUSPENDED" if suspended else ("PRESTIGE_IN_PROGRESS" if not state.get("prestige_batch",{}).is_empty() else ""))

func upgrade_block_reason(id: String,g: int=-1) -> String:
    var reason:=action_lock_reason()
    if not reason.is_empty():return reason
    if not _upgrade_scope_valid(id,g):return "ACTION_UNAVAILABLE"
    var scope: String=catalog.upgrades[id].scope
    if scope in ["type","normal_type"] and (catalog.groups[g].stage>state.unlocked_stage or not campaign.discovered(g)):return "UNDISCOVERED"
    if scope=="stage" and g>state.unlocked_stage:return "STAGE_LOCKED"
    if scope=="camp" and not state.camps.get(str(g/10),[]).has(g%10):return "CAMP_LOCKED"
    if id in ["collect_range","collect_batch","collect_speed"] and level("collect",g)==0:return "AUTOMATION_LOCKED"
    if id=="gear_merge_speed" and level("merge_gear",g)==0:return "AUTOMATION_LOCKED"
    if id=="merge_speed" and level("merge_supplies")==0:return "AUTOMATION_LOCKED"
    if id=="use_speed" and level("auto_use")==0:return "AUTOMATION_LOCKED"
    if id.begins_with("offline_") and id.ends_with("_rate") and level(id.trim_suffix("_rate"))==0:return "AUTOMATION_LOCKED"
    if id.begins_with("skill_auto_") and int(id.right(1))>=1+level("skill_slots"):return "SKILL_SLOTS_FULL"
    if id=="skill_drop" and catalog.groups[g].skills.is_empty():return "ACTION_UNAVAILABLE"
    if id.begins_with("cooldown_") and not skill_seen(id.trim_prefix("cooldown_")):return "UNDISCOVERED"
    if (id=="skill_slots" or id.begins_with("skill_auto_")) and state.skills_seen.is_empty():return "UNDISCOVERED"
    if upgrade_maxed(id,g):return "UPGRADE_MAX"
    var currency: String=catalog.upgrades[id].currency
    if state[currency]<upgrade_cost(id,g):return "NOT_ENOUGH_"+currency.to_upper()
    return ""

func stat_sources() -> Dictionary:
    var result: Dictionary={}
    result["SOURCE_BASE"]={"hp":100.0,"damage":5.0,"crit":.05,"crit_damage":1.5}
    result["SOURCE_LEVEL"]={"hp":(state.player_level-1)*catalog.progression.hp_per_level,"damage":(state.player_level-1)*catalog.progression.damage_per_level}
    result["SOURCE_EQUIPPED"]={}
    result["SOURCE_STORED"]={}
    for id in state.items:
        if quantity(id)<1 or catalog.items[id].kind not in ["weapon","outfit"]:continue
        # The equipped item counts once at full value; owned copies of it add nothing more.
        var weight:=1.0 if equipped(id) else stored_factor(id)
        if weight==0:continue
        var bucket: Dictionary=result["SOURCE_EQUIPPED" if equipped(id) else "SOURCE_STORED"]
        for intrinsic in [true,false]:
            var values: Dictionary=normal(id) if intrinsic else state.items[id].extras
            for key in values:bucket[key]=float(bucket.get(key,0))+float(values[key])*weight*(1.0+campaign.bonus("equipped") if intrinsic and equipped(id) else 1.0)
    # Milestones of the equipped outfit only; stored outfits never add Guard, Recovery or milestone HP.
    if state.outfit!="" and quantity(state.outfit)>0:
        var milestone:=outfit_milestones(state.outfit)
        if milestone.values().any(func(v):return float(v)>0):result["SOURCE_MILESTONE"]=milestone
    return result

func group_upgrade_value(id: String,g: int,variant: int=2,extra: int=0) -> float:
    var n:=level(id,g)+extra
    match id:
        "reveal_radius","camp_radius":return n*.25
        # 5% per carried item (bosses 30%), +0.5 points per Loot Chance level (catalog effect/cap).
        "loot":return float(catalog.groups[g].gear_chance)+float(catalog.upgrades.loot.effect)*mini(n,int(catalog.upgrades.loot.cap))+campaign.bonus("gear_chance")
        "supply_drop":return (.15 if catalog.groups[g].boss else .05)+minf(.15,.01*n)
        "skill_drop":return (.1 if catalog.groups[g].boss else .05)+minf(.15,.01*n)
        "group_xp":return float(enemy_definition(g,variant).xp)*(1.0+n*.1)*(1+campaign.bonus("boss_xp" if catalog.groups[g].boss else "normal_xp"))
        "coin_amount":return float(catalog.groups[g].coins)*(1.0+.5*n)*card("coins")*(1.0+float(state.boost_power))*(1+campaign.bonus("boss_coins" if catalog.groups[g].boss else "normal_coins"))
        "spawn_amount":return spawn_amount(g,extra)
        "spawn_cooldown":return spawn_cooldown(g,extra)
        "collect_range":return (100+n*50)*(1+campaign.bonus("collection_radius"))
        "collect_batch":return 1+n
        "collect_speed","gear_merge_speed":return 10-n
    return float(n)

func player_upgrade_value(id: String,extra: int=0) -> float:
    var n:=level(id)+extra
    var effect:=float(catalog.upgrades[id].effect)
    match id:
        "gem_chance":return gem_base_chance(extra)
        "gem_amount":return gem_amount(extra)
        "skill_slots":return 1+n
        "mission_slots":return 3+n
        "offline_cap":return [5,8,12,18,24,36,48][mini(n,6)]
        "offline_coins":return (120+60*n)*(1+campaign.bonus("offline_coins"))
        "offline_gems":return (2+.5*n)*(1+campaign.bonus("offline_gems"))
        "offline_weapon_rate","offline_outfit_rate":return (1+.5*n)*(1+campaign.bonus("offline_items"))
        "offline_consumable_rate":return (2+n)*(1+campaign.bonus("offline_items"))
        "gear_slots":return 3+n*effect
        "supply_slots":return 1+n*effect
        "merge_speed":return 10-n*effect
        "respawn":return maxf(2,10-n*effect-campaign.bonus("respawn"))
        "use_speed":return 10-n*effect
    if id.begins_with("cooldown_"):return maxf(2,float(catalog.skills[id.trim_prefix("cooldown_")].cooldown)*(1-.05*n))
    return n*effect

func farming_position() -> Vector2:
    return campaign.spot(int(state.focus),int(state.focus_variant)) if int(state.focus)>=0 else position_of(state.player)

func gem_base_chance(extra: int=0) -> float:
    return minf(float(catalog.progression.gem_limits.normal_cap),float(catalog.progression.gem_limits.base_chance)+campaign.bonus("gem_chance")+float(catalog.upgrades.gem_chance.effect)*(level("gem_chance")+extra))

func gem_amount(extra: int=0,group: int=-1) -> float:
    var boss: bool=group>=0 and catalog.groups[group].boss
    return (1.0+.5*(level("gem_amount")+extra)+(level("boss_gem_amount") if boss else 0))*(1+campaign.bonus("boss_gems") if boss else 1)
