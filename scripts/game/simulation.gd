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
var catalog := LootCatalog.new()
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
    clear_target()
    state = {"schema":5,"group_kills":[0,0,0,0],"player_level":1,"xp":0.0,"coins":0,"gems":0,"items":{},"gear":["","",""],"supplies":[""],
        "weapon":"","outfit":"","upgrades":{},"sell_list":[],"auto_slots":[],
        "spawns":[0],"spawn":0,"cards":{},"prestiges":0,"offer":[],"victory":false,
        "focus":-1,"focus_variant":2,"boost_time":0.0,"boost_power":0.0,"use_cd":0.0,"history":[],
        "pickups":[],"next_pickup":0,"clock":0.0,"collect_clock":0.0,"collect_clocks":[0.0,0.0,0.0,0.0],"merge_clock":0.0,
        "use_clock":0.0,"summon_clock":0.0,"next_cat":0,"help":0,"paused":false}
    _reset_world()
    movement = Vector2.ZERO
    touch()

func _actor(id: String, x: float, y: float, hp: float, group: int) -> Dictionary:
    return {"id":id,"x":x,"y":y,"home_x":x,"home_y":y,"hp":hp,"group":group,
        "respawn":0.0,"dead_age":0.0,"cooldown":0.0,"windup":0.0,"target":"",
        "attack_age":9.0,"hurt":0.0,"quiet":0.0,"aggro":false,"returning":false,"moving":false,"facing":1.0}

func _reset_world() -> void:
    state.player = _actor("player",180,1390,100,-1)
    state.player["idle"] = 0.0
    state.enemies = []
    _sync_spawn_counts()
    _stats_revision = -1
    state.player.hp = stats().hp

func spawn_amount(group: int,extra: int=0) -> int:
    if group==3:return 1
    return mini(6,int(catalog.groups[group].count)+level("spawn_amount",group)+extra)

func spawn_cooldown(group: int,extra: int=0) -> float:
    var base:=float(catalog.groups[group].respawn)
    return base if group==3 else base*(1.0-float(catalog.upgrades.spawn_cooldown.effect)*(level("spawn_cooldown",group)+extra))

func _sync_spawn_counts() -> void:
    for tier in range(catalog.groups.size()):
        for variant in range(1 if tier==3 else 3):
            var kind:=2 if tier==3 else variant
            for i in range(spawn_amount(tier)):
                var id:="g%d_v%d_%d" % [tier,kind,i]
                if not _find_actor(id).is_empty():continue
                var x:=540.0 if tier==3 else 180.0+variant*360.0
                var a:=_actor(id,x+(i%3-1)*34,float(catalog.groups[tier].center[1])+(18 if i%2 else -18)+floori(i/3.0)*40,1,tier)
                a["variant"]=kind
                a.hp=enemy_definition(tier,kind).hp
                state.enemies.append(a)

func snapshot() -> Dictionary:
    var result := state.duplicate(true)
    result["rng_state"] = str(rng.state)
    return result

func restore(data: Dictionary) -> void:
    data=data.duplicate(true)
    var legacy:=int(data.get("schema",0))==1
    if legacy:
        data.schema=2
        data["player_level"]=1
        data["xp"]=0.0
    if int(data.get("schema",0))==2:
        data.schema=3
        data["group_kills"]=[0,0,0,0]
        # Preserve the already purchased global unlock for this run.
        if data.get("upgrades",{}) is Dictionary and data.upgrades.has("focus"):
            for g in range(4):
                data.upgrades["focus:%d" % g]=data.upgrades.focus
            data.upgrades.erase("focus")
    if data.get("upgrades",{}) is Dictionary and data.upgrades.has("merge_gear"):
        for g in range(4):
            data.upgrades["merge_gear:%d" % g]=maxi(int(data.upgrades.get("merge_gear:%d" % g,0)),int(data.upgrades.merge_gear))
        data.upgrades.erase("merge_gear")
    if int(data.get("schema",0))==3:
        if not data.get("upgrades",null) is Dictionary or not typeof(data.get("gems",null)) in [TYPE_INT,TYPE_FLOAT]:
            SaveService.write_blocked=true
            event.emit("SAVE_INCOMPATIBLE")
            return
        data.schema=4
        data["focus_variant"]=2
        # Refund old type-specific purchases exactly; the global upgrades start
        # unpurchased. Schema 4 makes this migration one-shot after saving.
        for g in range(4):
            for id in ["gem_chance","gem_amount"]:
                var key: String="%s:%d" % [id,g]
                var count: float=float(data.upgrades.get(key,0))
                if not is_finite(count) or count<0 or count!=floor(count) or count>(34 if id=="gem_chance" else 10):
                    SaveService.write_blocked=true
                    event.emit("SAVE_INCOMPATIBLE")
                    return
                for n in range(int(count)):
                    data.gems+=ceil((5.0 if id=="gem_chance" else 30.0)*(g+1)*pow(1.4 if id=="gem_chance" else 1.5,n))
                data.upgrades.erase(key)
    if int(data.get("schema",0))==4:
        if not data.get("upgrades",null) is Dictionary or not typeof(data.get("gems",null)) in [TYPE_INT,TYPE_FLOAT]:
            SaveService.write_blocked=true
            event.emit("SAVE_INCOMPATIBLE")
            return
        # Reprice old global gems without discarding their investment.
        for id in ["gem_chance","gem_amount"]:
            var count: float=float(data.upgrades.get(id,0))
            if not is_finite(count) or count<0 or count!=floor(count) or count>(20 if id=="gem_chance" else 10):
                SaveService.write_blocked=true
                event.emit("SAVE_INCOMPATIBLE")
                return
            for n in range(int(count)):
                data.gems+=ceil((50.0 if id=="gem_chance" else 100.0)*pow(1.8,n))
            data.upgrades.erase(id)
        for id in ["collect","collect_range","collect_batch","collect_speed"]:
            if data.upgrades.has(id):
                for g in range(4):data.upgrades["%s:%d" % [id,g]]=data.upgrades[id]
                data.upgrades.erase(id)
        data["collect_clocks"]=[0.0,0.0,0.0,0.0]
        if data.get("pickups",null) is Array:
            for drop in data.pickups:
                if drop is Dictionary and drop.has("y"):
                    drop["group"]=gear_group(str(drop.get("item","")))
                    if int(drop.group)<0:drop.group=_nearest_drop_group(float(drop.y))
        data.schema=5
    if not _valid_snapshot(data):
        SaveService.write_blocked = true
        event.emit("SAVE_INCOMPATIBLE")
        return
    clear_target()
    state = data.duplicate(true)
    rng.state = int(state.get("rng_state",str(rng.state)))
    if legacy:
        _reset_world()
    _sync_spawn_counts()
    movement = Vector2.ZERO
    for a in [state.player] + state.enemies:
        a.windup = 0.0
        a.target = ""
        a.attack_age = 9.0
        a["returning"] = bool(a.get("returning",false))
        a.moving = false
    state.player.idle = 0.0
    state.paused = false # Legacy field; pause is session-owned.
    touch()

func _valid_snapshot(data: Dictionary) -> bool:
    if int(data.get("schema",0))!=5:
        return false
    for key in state.keys():
        if not data.has(key):
            return false
        var expected: int=typeof(state[key])
        var actual: int=typeof(data[key])
        if expected in [TYPE_INT,TYPE_FLOAT]:
            if not actual in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(data[key])):
                return false
        elif actual!=expected:
            return false
    if data.focus_variant!=int(data.focus_variant) or int(data.focus_variant) not in [0,1,2] or data.focus!=int(data.focus) or int(data.focus) not in [-1,0,1,2,3]:
        return false
    if data.collect_clocks.size()!=4:return false
    for clock in data.collect_clocks:
        if not typeof(clock) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(clock)) or clock<0:return false
    if data.group_kills.size()!=4:
        return false
    for kills in data.group_kills:
        if not typeof(kills) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(kills)) or kills<0 or kills!=floor(kills):
            return false
    if data.coins<0 or data.gems<0 or data.gear.size()<3 or data.gear.size()>12 or data.supplies.size()<1 or data.supplies.size()>6:
        return false
    if data.player_level<1 or data.player_level>1000 or data.player_level!=int(data.player_level) or data.xp<0:
        return false
    if data.xp >= xp_required(int(data.player_level)) or (data.player_level==1000 and data.xp!=0):
        return false
    var found: Dictionary={}
    for list in [data.gear,data.supplies]:
        for id in list:
            if not id is String:
                return false
            if id=="":
                continue
            if found.has(id) or not catalog.items.has(id) or not data.items.has(id):
                return false
            found[id]=true
    for id in data.items:
        if not catalog.items.has(id) or not data.items[id] is Dictionary:
            return false
        var r: Dictionary=data.items[id]
        if not r.has_all(["qty","merge","extras"]) or not r.extras is Dictionary:
            return false
        if not typeof(r.qty) in [TYPE_INT,TYPE_FLOAT] or not typeof(r.merge) in [TYPE_INT,TYPE_FLOAT]:
            return false
        if r.qty<0 or r.merge<0 or r.merge>100 or (r.qty>0 and not found.has(id)):
            return false
        for stat in r.extras:
            if not catalog.items[id].extras.has(stat) or not typeof(r.extras[stat]) in [TYPE_INT,TYPE_FLOAT]:
                return false
    for id in [data.weapon,data.outfit]:
        if id!="" and (not found.has(id) or data.items[id].qty<1):
            return false
    var actor_fields: Array=_actor("",0,0,0,0).keys()
    for a in [data.player]+data.enemies:
        if not a is Dictionary or not a.has_all(actor_fields):
            return false
        for field in ["x","y","hp","respawn","group","quiet","windup","dead_age"]:
            if not typeof(a[field]) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(a[field])):
                return false
        if a.group < -1 or a.group>4:
            return false
    if not data.player.has("idle") or data.spawn<0 or data.spawn>=catalog.world.spawns.size():
        return false
    for key in data.upgrades:
        var parts: PackedStringArray=str(key).split(":")
        if not catalog.upgrades.has(parts[0]) or not typeof(data.upgrades[key]) in [TYPE_INT,TYPE_FLOAT]:
            return false
        if parts.size()>2:return false
        var group: int=int(parts[1]) if parts.size()==2 else -1
        if parts.size()==2 and (not parts[1].is_valid_int() or group<0):return false
        if not _upgrade_scope_valid(parts[0],group):return false
        if data.upgrades[key]!=floor(data.upgrades[key]) or data.upgrades[key]<0 or data.upgrades[key]>catalog.upgrades[parts[0]].cap:
            return false
    for drop in data.pickups:
        if not drop is Dictionary or not drop.has_all(["uid","item","x","y","ttl"]) or not catalog.items.has(drop.item) or not drop.has("group") or not typeof(drop.group) in [TYPE_INT,TYPE_FLOAT] or drop.group!=int(drop.group) or int(drop.group) not in range(4):
            return false
    return true

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED:
        suspended = true
        movement = Vector2.ZERO
        SaveService.save_now()
    elif what == NOTIFICATION_APPLICATION_RESUMED:
        suspended = false
        movement = Vector2.ZERO

func _physics_process(delta: float) -> void:
    if not suspended:
        step(delta)

func level(id: String, group: int = -1) -> int:
    return int(state.upgrades.get(_upgrade_key(id,group),0))

func _upgrade_key(id: String, group: int) -> String:
    return id if group < 0 else "%s:%d" % [id,group]

func card(id: String) -> float:
    return 1.0 + .05 * float(state.cards.get(id,0))

func record(id: String) -> Dictionary:
    if not state.items.has(id):
        var extras: Dictionary = {}
        var pool: Array = catalog.items[id].extras.keys()
        for i in range(mini(2,pool.size())):
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
    for stat in catalog.items[id].normal:
        var pair: Array = catalog.items[id].normal[stat]
        output[stat] = float(pair[0]) + merge_gain(id,stat) * merge_level
    return output

func stats() -> Dictionary:
    if _stats_revision == revision and not _stats.is_empty():
        return _stats
    var s := {"hp":0.0,"damage":0.0,"defense":0.0,"crit":0.0,"crit_damage":0.0,"lifesteal":0.0,"regen":0.0,"speed":0.0}
    for bucket in stat_sources().values():
        for key in bucket:s[key]=float(s.get(key,0))+float(bucket[key])
    s.hp *= card("hp")
    s.damage *= card("damage")
    s.crit = minf(.75,s.crit)
    s.crit_damage = minf(4,s.crit_damage)
    s.lifesteal = minf(.15,s.lifesteal)
    s.speed = minf(2,s.speed)
    _stats = s
    _stats_revision = revision
    return s

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

func enemy_definition(group: int,variant: int=2) -> Dictionary:
    if group==4:
        return {"hp":25.0,"damage":3.0,"defense":0.0,"body":"cat","weapon":"","loot":[],"xp":0}
    var def: Dictionary=catalog.groups[group].duplicate(true)
    if group<3:
        def.hp*=1.5 if variant!=1 else .75
        def.damage*=1.5 if variant!=0 else .65
        if variant==0:
            def.weapon=""
            def.loot=[def.body]
        elif variant==1:
            def.body=""
            def.loot=[def.weapon]
        def.xp=int(def.xp*(1.5 if variant==2 else 1.0))
    return def

func slots(id: String) -> Array:
    return state.supplies if catalog.items[id].kind == "consumable" else state.gear

func equipped(id: String) -> bool:
    return state.weapon == id or state.outfit == id

func can_add(id: String) -> bool:
    return quantity(id)>0 or slots(id).has("")

func add_item(id: String, amount: int = 1, allow_sell: bool = true) -> bool:
    if not catalog.items.has(id) or amount < 1:
        return false
    if allow_sell and state.sell_list.has(id) and not equipped(id):
        var earned: int = int(catalog.items[id].sell) * amount
        state.coins += earned
        history("HISTORY_SOLD",id,amount,earned)
        touch()
        return true
    if not can_add(id):
        return false
    var r := record(id)
    if int(r.qty)==0:
        var list := slots(id)
        list[list.find("")] = id
    r.qty += amount
    history("HISTORY_ITEM",id,amount,0)
    touch()
    return true

func _remove(id: String, amount: int) -> void:
    var r := record(id)
    r.qty -= amount
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
    var count := mini(int(r.qty)-1,100-int(r.merge))
    if not all:
        count = mini(1,count)
    if count<1:
        return fail("MERGE_MAX")
    _remove(id,count)
    r.merge += count
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
    # Every validation precedes both mutations; output never routes through auto-sell.
    _remove(id,int(catalog.progression.evolution.spare_cost))
    add_item(target,1,false)
    touch()
    event.emit("EVOLVED")
    return true

func equip(id: String) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if quantity(id)<1 or catalog.items[id].kind=="consumable":
        return false
    var kind: String = catalog.items[id].kind
    state[kind] = "" if state[kind]==id else id
    state.sell_list.erase(id)
    touch()
    state.player.hp = minf(state.player.hp,stats().hp)
    return true

func sell(id: String, all: bool = false) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    var count := quantity(id) - (1 if equipped(id) else 0)
    if count<1:
        return fail("EQUIPPED_PROTECTED")
    if not all:
        count=1
    _remove(id,count)
    var earned: int = count * int(catalog.items[id].sell)
    state.coins += earned
    history("HISTORY_SOLD",id,count,earned)
    touch()
    return true

func reroll(id: String) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    var cost: int = int(catalog.items[id].get("reroll",0))
    if quantity(id)<1 or cost==0:
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

func toggle_sell(id: String) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if state.sell_list.has(id):
        state.sell_list.erase(id)
    else:
        if level("sell")==0:
            return fail("AUTOMATION_LOCKED")
        if equipped(id):
            return fail("UNEQUIP_FIRST")
        if state.sell_list.size()>=player_upgrade_value("sell_capacity"):
            return fail("SELL_LIST_FULL")
        state.sell_list.append(id)
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
        if state.player.hp>=stats().hp*.8 or state.use_cd>0:
            return fail("POTION_CONDITION")
        var gain := minf(normal(id).heal,stats().hp-state.player.hp)
        state.player.hp += gain
        state.use_cd=2.0
        feedback.emit("player",gain,true)
    elif catalog.art_id(id)=="coin_boost":
        state.boost_time += 30.0
        state.boost_power = maxf(state.boost_power,normal(id).coin_bonus)
    else:
        return false
    _remove(id,1)
    touch()
    return true

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
    var d: Dictionary = catalog.upgrades[id]
    var group_factor: int=int(catalog.progression.group_cost_multipliers[group]) if group in range(4) else 1
    var growth:=float(d.growth)
    if id=="coin_amount" and group in range(4):
        group_factor=int(catalog.progression.coin_upgrade_cost_multipliers[group])
        growth=float(catalog.progression.coin_upgrade_cost_growth[group])
    if d.has("prices"):
        var price_factor:=1 if d.get("scope","")=="boss" else group_factor
        return int(ceil(float(d.prices[mini(level(id,group),d.prices.size()-1)])*price_factor))
    return int(ceil(float(d.base)*group_factor*pow(growth,level(id,group))))

func upgrade_maxed(id: String, group: int = -1) -> bool:
    if level(id,group)>=int(catalog.upgrades[id].cap):
        return true
    if id=="gem_chance":
        return gem_base_chance()>=float(catalog.progression.gem_limits.normal_cap)
    if id=="boss_gem_chance":return gem_chance(3)>=float(catalog.progression.gem_limits.boss_cap)
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
    touch()
    return true

func pay(currency: String, cost: int) -> bool:
    if cost<0 or state[currency]<cost:
        return fail("NOT_ENOUGH_"+currency.to_upper())
    state[currency] -= cost
    return true

func select_spawn(index: int) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if not state.spawns.has(index):
        if not pay("coins",int(catalog.world.spawn_prices[index])):
            return false
        state.spawns.append(index)
        touch()
        event.emit("SPAWN_BOUGHT")
        return true
    state.spawn = index
    touch()
    return true

func focus(group: int,variant: int=2) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if group<0 or group>=catalog.groups.size() or variant not in [0,1,2]:
        return false
    if group==3:variant=2
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
                state.pickups.erase(pickup)
                return true
            return fail("INVENTORY_FULL")
    return false

func prestige(card_id: String) -> bool:
    if not state.victory or not state.offer.has(card_id):
        return false
    var before := snapshot()
    var kept: Dictionary = {}
    for key in state.upgrades:
        if bool(catalog.upgrades[str(key).split(":")[0]].keep):
            kept[key] = state.upgrades[key]
    var permanent_kills: Array=state.group_kills.duplicate()
    var cards: Dictionary = state.cards.duplicate(true)
    cards[card_id] = int(cards.get(card_id,0))+1
    var runs := int(state.prestiges)+1
    var gear_size: int = state.gear.size()
    var supply_size: int = state.supplies.size()
    new_profile()
    state.group_kills=permanent_kills
    state.cards = cards
    state.prestiges = runs
    state.upgrades = kept
    state.gear.resize(gear_size)
    state.gear.fill("")
    state.supplies.resize(supply_size)
    state.supplies.fill("")
    state.help = 7
    touch()
    state.player.hp = stats().hp
    state.paused = false
    get_tree().paused = false
    if not SaveService.save_now():
        restore(before)
        return false
    event.emit("PRESTIGED")
    return true

func position_of(a: Dictionary) -> Vector2:
    return Vector2(a.x,a.y)

func nearest_group() -> int:
    var best := INF
    var index := 0
    for i in range(catalog.groups.size()):
        var g: Dictionary = catalog.groups[i]
        var dist := position_of(state.player).distance_to(Vector2(g.center[0],g.center[1]))
        if dist<best:
            best=dist
            index=i
    return index

func _move(a: Dictionary, destination: Vector2, speed: float, delta: float) -> void:
    var old := position_of(a)
    var next := old.move_toward(destination,speed*delta)
    a.x = clampf(next.x,14,1066)
    a.y = clampf(next.y,30,1475)
    a.moving = old.distance_to(position_of(a))>.01
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
    if a.id=="player" and int(target.group) in range(4):
        combat_group_changed.emit(int(target.group))
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
    var damage: float = stats().damage if is_player else (3.0 if int(a.group)==4 else float(enemy_definition(a.group,int(a.get("variant",2))).damage))
    var critical: bool=is_player and rng.randf()<stats().crit
    if is_player and int(target.group) in range(4):
        damage *= 1.0+achievement_damage(int(target.group))
    if critical:
        damage *= stats().crit_damage
    target["critical_hit"]=critical
    var defense: float = stats().defense if target.id=="player" else (0.0 if int(target.group)==4 else float(enemy_definition(target.group,int(target.get("variant",2))).defense))
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
        if int(target.group)==2:
            for other in state.enemies:
                if int(other.group)==2 and other.get("variant",2)==target.get("variant",2) and other.hp>0 and not other.returning:
                    other.aggro=true
    if target.hp<=0:
        _kill(target)

func _kill(a: Dictionary) -> void:
    if a.id==locked_target or a.id=="player":
        clear_target()
    a.windup=0.0
    a.target=""
    a.dead_age=0.0
    a.aggro=false
    a.moving=false
    if a.id=="player":
        a.respawn=player_upgrade_value("respawn")
        for e in state.enemies:
            e.aggro=false
            e.windup=0.0
        _reset_boss()
        event.emit("PLAYER_DIED")
    else:
        var group := int(a.group)
        a.respawn = 999999.0 if group==4 else spawn_cooldown(group)
        if group in range(4):
            state.group_kills[group]+=1
        _reward(a)
        if group==3:
            _clear_cats()
            if not state.victory:
                state.victory=true
                var pool: Array = []
                for candidate in catalog.cards:
                    if candidate=="loot" and .08*card("loot")>=.5:
                        continue
                    if candidate=="gems" and .08*card("gems")>=.2:
                        continue
                    pool.append(candidate)
                state.offer=[]
                for i in range(3):
                    state.offer.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
                touch()
                SaveService.save_now()
                event.emit("BOSS_DEFEATED")
    touch()

func _clear_cats() -> void:
    for e in state.enemies:
        if int(e.group)==4 and e.hp>0:
            e.hp=0
            e.dead_age=0.0
            e.windup=0.0
            e.target=""
            e.moving=false
    state.summon_clock=0.0

func _reset_boss() -> void:
    _clear_cats()
    for e in state.enemies:
        if int(e.group)==3 and e.hp>0:
            e.hp=catalog.groups[3].hp
            e.x=e.home_x
            e.y=e.home_y
            e.aggro=false
            e.windup=0.0

func gear_chance(group: int) -> float:
    return group_upgrade_value("loot",group)

func gem_chance(group: int) -> float:
    var limits: Dictionary=catalog.progression.gem_limits
    var base:=gem_base_chance()+achievement_gems(group)
    if group==3:
        return minf(float(limits.boss_cap),base+level("boss_gem_chance",3)*float(catalog.upgrades.boss_gem_chance.effect))
    return minf(float(limits.normal_cap),base)

func coin_reward(group: int) -> float:
    return group_upgrade_value("coin_amount",group)

func _reward(a: Dictionary) -> void:
    var group := int(a.group)
    if group==4:
        return
    var def:=enemy_definition(group,int(a.get("variant",2)))
    gain_xp(group_xp(group,int(a.get("variant",2))))
    var coins := coin_reward(group)
    state.coins += coins
    var gem_probability := gem_chance(group)
    var gems := 0.0
    if rng.randf()<gem_probability:
        gems=gem_amount(0,group)
        state.gems+=gems
    if gems>0:
        history("HISTORY_CURRENCY","",gems,0)
    if rng.randf()<gear_chance(group):
        var loot: Array=def.loot
        _drop(loot[rng.randi_range(0,loot.size()-1)],a)
        chatter.emit(a.id,"CHAT_LOOT")
    if rng.randf()<consumable_chance(group,"potion"):
        _drop("potion",a)
    if group>0 and rng.randf()<consumable_chance(group,"coin_boost"):
        _drop("coin_boost",a)

func _drop(id: String,a: Dictionary) -> void:
    state.next_pickup+=1
    state.pickups.append({"uid":state.next_pickup,"item":id,"x":a.x+rng.randf_range(-10,10),"y":a.y+rng.randf_range(-8,8),"ttl":300.0,"group":int(a.group) if int(a.group) in range(4) else _nearest_drop_group(float(a.y))})

func step(dt: float) -> void:
    if state.is_empty() or get_tree().paused or suspended:
        return
    state.clock+=dt
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
            touch()
    else:
        p.hp=minf(stats().hp,p.hp+stats().regen*dt)
        if movement.length()>.1:
            clear_target()
            if int(state.focus)>=0:
                state.focus=-1
                touch()
            p.idle=0.0
            p.windup=0.0
            p.target=""
            p.attack_age=9.0
            _move(p,position_of(p)+movement.normalized()*100,90.0,dt)
        else:
            p.idle+=dt
            _resolve_attack(p,dt)
            if p.idle>=0.5 and p.windup<=0:
                var target:=_combat_target()
                var distance:=INF if target.is_empty() else position_of(p).distance_to(position_of(target))
                if not target.is_empty():
                    if distance>float(catalog.world.reach):
                        _move(p,position_of(target),90,dt)
                    elif p.cooldown<=0:
                        _start_attack(p,target,1.0/(1.0+stats().speed))
                elif int(state.focus)>=0:
                    _move(p,farming_position(),90,dt)
    for e in state.enemies.duplicate():
        if not state.enemies.has(e):
            continue
        var group:=int(e.group)
        var maxhp:=float(enemy_definition(group,int(e.get("variant",2))).hp)
        if e.hp<=0:
            if e.respawn<=0 and group!=4:
                e.hp=maxhp
                e.x=e.home_x
                e.y=e.home_y
                e.quiet=0.0
                e.returning=false
                e.attack_age=9.0
            continue
        if e.quiet>=5:
            e.hp=minf(maxhp,e.hp+maxhp*.1*dt)
        var home:=Vector2(e.home_x,e.home_y)
        var center: Vector2 = home
        if position_of(e).distance_to(center)>float(catalog.world.leash) or p.hp<=0:
            e.aggro=false
            e.returning=true
            e.windup=0.0
            if group==3:
                _reset_boss()
        if e.returning and position_of(e).distance_to(home)<2:
            e.returning=false
        if not e.returning and not e.aggro and group>=1 and p.hp>0 and position_of(e).distance_to(position_of(p))<58:
            e.aggro=true
        if e.aggro and p.hp>0:
            _resolve_attack(e,dt)
            if e.windup<=0:
                if position_of(e).distance_to(position_of(p))>float(catalog.world.reach):
                    _move(e,position_of(p),62 if group!=4 else 100,dt)
                elif e.cooldown<=0:
                    _start_attack(e,p,2.0 if group==4 else float(catalog.groups[group].interval))
            if group==3:
                state.summon_clock+=dt
                if state.summon_clock>=12:
                    state.summon_clock=0.0
                    var count:=0
                    for cat in state.enemies:
                        if int(cat.group)==4 and cat.hp>0:
                            count+=1
                    for i in range(mini(2,4-count)):
                        state.next_cat+=1
                        var cat:=_actor("cat%d" % state.next_cat,e.x+20*i,e.y+30,25,4)
                        cat.aggro=true
                        state.enemies.append(cat)
        elif position_of(e).distance_to(home)>1:
            _move(e,home,60,dt)
    state.enemies=state.enemies.filter(func(e: Dictionary)->bool: return not (int(e.group)==4 and e.hp<=0 and e.dead_age>1))
    for pickup in state.pickups:
        pickup.ttl-=dt
    state.pickups=state.pickups.filter(func(v: Dictionary)->bool:return v.ttl>0)
    if p.hp>0:
        _automate(dt)
    _save_clock+=dt
    if _save_clock>=2:
        _save_clock=0.0
        SaveService.mark_dirty()

func _automate(dt: float) -> void:
    state.merge_clock+=dt
    state.use_clock+=dt
    for g in range(4):
        if level("collect",g)==0:continue
        state.collect_clocks[g]+=dt
        if state.collect_clocks[g]<group_upgrade_value("collect_speed",g):continue
        state.collect_clocks[g]=0.0
        var count:=0
        var radius:=group_upgrade_value("collect_range",g)
        for drop in state.pickups.duplicate():
            if int(drop.group)!=g:continue
            if position_of(state.player).distance_to(Vector2(drop.x,drop.y))<=radius:
                if can_add(drop.item) or state.sell_list.has(drop.item):
                    if collect(int(drop.uid)):count+=1
                    if count>=group_upgrade_value("collect_batch",g):break
    if state.merge_clock>=player_upgrade_value("merge_speed"):
        state.merge_clock=0.0
        for id in state.items.keys():
            if quantity(id)>1 and int(record(id).merge)<100:
                if can_auto_merge(id):
                    merge(id)
    if state.use_clock>=player_upgrade_value("use_speed"):
        state.use_clock=0.0
        for slot in state.auto_slots:
            if int(slot)<state.supplies.size():
                var id: String=state.supplies[int(slot)]
                if catalog.art_id(id)=="potion" and state.player.hp<stats().hp*.8 and state.use_cd<=0:
                    use_item(id)
                elif catalog.art_id(id)=="coin_boost":
                    use_item(id)

func clear_target() -> void:
    locked_target=""
    manual_target=""

func select_target(id: String) -> bool:
    var enemy:=_find_actor(id)
    if suspended or get_tree().paused or state.player.hp<=0 or enemy.is_empty() or enemy.hp<=0 or id=="player":
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
    if not target.is_empty() and target.hp>0:
        return target
    clear_target()
    target={}
    var distance: float=catalog.world.acquisition
    for enemy in state.enemies:
        if enemy.hp<=0 or (int(state.focus)>=0 and (int(enemy.group)!=int(state.focus) or int(enemy.get("variant",2))!=int(state.focus_variant))):
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
    return catalog.progression.achievements.boss_kills if group==3 else catalog.progression.achievements.kills

func achievement_level(group: int) -> int:
    if group not in range(4):
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

func consumable_chance(group: int,id: String) -> float:
    if id=="coin_boost" and group==0:
        return 0.0
    var base:=.1 if id=="potion" else .025
    return base+group_upgrade_value("supply_drop",group)-.1

func group_xp(group: int,variant: int=2) -> float:
    return group_upgrade_value("group_xp",group,variant)

func merge_gain(id: String,stat: String) -> float:
    var definition: Dictionary=catalog.items[id]
    var gain: float=float(definition.get("merge_gain",{}).get(stat,float(definition.normal[stat][1])*3.0))
    return gain*card("merge")

func gear_group(id: String) -> int:
    for g in range(catalog.groups.size()):
        if catalog.groups[g].loot.has(catalog.art_id(id)):
            return g
    return -1

func can_auto_merge(id: String) -> bool:
    if catalog.items[id].kind=="consumable":
        return level("merge_supplies")>0
    var g:=gear_group(id)
    return g>=0 and level("merge_gear",g)>0

func _nearest_drop_group(y: float) -> int:
    var nearest:=0
    for g in range(1,4):
        if absf(y-float(catalog.groups[g].center[1]))<absf(y-float(catalog.groups[nearest].center[1])):nearest=g
    return nearest

func _upgrade_scope_valid(id: String,g: int) -> bool:
    match str(catalog.upgrades[id].get("scope","global")):
        "type":return g in range(4)
        "normal_type":return g in range(3)
        "boss":return g==3
    return g==-1

func action_lock_reason() -> String:
    return "ACTION_PAUSED" if get_tree().paused else ("ACTION_SUSPENDED" if suspended else "")

func upgrade_block_reason(id: String,g: int=-1) -> String:
    var reason:=action_lock_reason()
    if not reason.is_empty():return reason
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
        if quantity(id)<1:continue
        var weight:=1.0 if equipped(id) else (float(catalog.progression.stored_weapon_factor) if catalog.items[id].kind=="weapon" else 0.0)
        if weight==0:continue
        var bucket: Dictionary=result["SOURCE_EQUIPPED" if equipped(id) else "SOURCE_STORED"]
        for values in [normal(id),state.items[id].extras]:
            for key in values:bucket[key]=float(bucket.get(key,0))+float(values[key])*weight
    return result

func group_upgrade_value(id: String,g: int,variant: int=2,extra: int=0) -> float:
    var n:=level(id,g)+extra
    match id:
        "loot":return minf(.5,float(catalog.groups[g].gear_chance)*card("loot"))+minf(.15,float(catalog.upgrades.loot.effect)*n)
        "supply_drop":return .1+minf(.15,float(catalog.upgrades.supply_drop.effect)*n)
        "group_xp":return float(enemy_definition(g,variant).xp)*(1.0+n*float(catalog.upgrades.group_xp.effect))
        "coin_amount":return (float(catalog.groups[g].coins)+float(catalog.progression.coin_upgrade_gain[g])*n)*card("coins")*(1.0+float(state.boost_power))
        "boss_gem_chance":return minf(float(catalog.progression.gem_limits.boss_cap),gem_base_chance()+achievement_gems(g)+n*float(catalog.upgrades[id].effect))
        "boss_gem_amount":return gem_amount()+n*float(catalog.upgrades[id].effect)
        "spawn_amount":return spawn_amount(g,extra)
        "spawn_cooldown":return spawn_cooldown(g,extra)
        "collect_range":return float(catalog.progression.collection.base_range)+n*float(catalog.upgrades[id].effect)
        "collect_batch":return float(catalog.progression.collection.base_batch)+n*float(catalog.upgrades[id].effect)
        "collect_speed":return float(catalog.progression.collection.base_interval)-n*float(catalog.upgrades[id].effect)
    return float(n)

func player_upgrade_value(id: String,extra: int=0) -> float:
    var n:=level(id)+extra
    var effect:=float(catalog.upgrades[id].effect)
    match id:
        "gem_chance":return gem_base_chance(extra)
        "gem_amount":return gem_amount(extra)
        "gear_slots":return 3+n*effect
        "supply_slots":return 1+n*effect
        "sell_capacity":return 1+n*effect
        "merge_speed":return 5-n*effect
        "respawn","use_speed":return 10-n*effect
    return n*effect

func farming_position() -> Vector2:
    var g:=int(state.focus)
    if g<0:return position_of(state.player)
    return Vector2(540 if g==3 else 180+360*int(state.focus_variant),float(catalog.groups[g].center[1]))

func gem_base_chance(extra: int=0) -> float:
    return minf(float(catalog.progression.gem_limits.normal_cap),float(catalog.progression.gem_limits.base_chance)*card("gems")+float(catalog.upgrades.gem_chance.effect)*(level("gem_chance")+extra))

func gem_amount(extra: int=0,group: int=-1) -> float:
    return 1.0+float(catalog.upgrades.gem_amount.effect)*(level("gem_amount")+extra)+(level("boss_gem_amount",3)*float(catalog.upgrades.boss_gem_amount.effect) if group==3 else 0.0)
