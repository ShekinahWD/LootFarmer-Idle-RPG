class_name LootSimulation
extends Node
## Single authoritative owner for combat, inventory transactions and rewards.
## Presentation never applies damage. Active timers are pausable; boss respawns also settle offline elapsed.
signal combat_group_changed(group: int)
signal gem_pickup(amount: float)
signal boss_respawns_changed
signal skill_automation_changed
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
## Change 12: authoritative transitions that earn a notification sound and nothing else:
## "mission_ready" (a manually claimed mission reaches its goal), "follow_step" (a step of the
## followed Prestige opportunity is completed). Emitted once per transition, never on load.
signal notice(kind: String, id: String)
var catalog := LootCatalog.new()
var campaign = preload("res://scripts/game/campaign.gd").new(self)
## Change 13: summoning and final-boss action rules (inspector-editable resource).
var abilities: EnemyAbilityRules = preload("res://resources/game/enemy_abilities.tres")
## Change 13: summoned helpers use this loadout variant (never an encounter spot, never saved).
const HELPER_VARIANT:=4
## Summoned helpers: (summoner id, helper ids) once they appear, for presentation.
signal summoned(summoner_id: String, helper_ids: Array)
## A summoner began its call (the telegraph before the helpers appear).
signal summon_warning(summoner_id: String)
signal spell_cast(actor_id: String, skill: String, position: Vector2)
## Change 14: a boss's attack wind-up at the aimed point (a warning marker, not the skill's effect).
signal skill_warning(actor_id: String, skill: String, position: Vector2)
## The actor a single-target skill hit, set just before spell_cast (presentation reads it, never saved).
var cast_target: String=""
var rng := RandomNumberGenerator.new()
var state: Dictionary = {}
var locked_target: String=""
var manual_target: String=""
var movement := Vector2.ZERO
var suspended := false
## Change 35: a decision panel in front of the game (the review invitation) holds the world: no step,
## so no combat, movement, timers or playtime while it is open. Session-only, never saved.
var held := false
var revision: int = 0
var _save_clock := 0.0
## Change 24: actors erased from state.enemies in place (see step's roster loop).
var _roster_removals := 0
var _stats: Dictionary = {}
var _stats_revision := -1

func _ready() -> void:
    rng.randomize()
    new_profile()
    SaveService.register_section("lootfarmer", save_snapshot, restore, new_profile)

func touch() -> void:
    revision += 1
    _stats_revision = -1
    SaveService.mark_dirty()
    changed.emit()

## Change 50 (approved progression brief, B1): schema 9 adds the permanent per-item merge memory
## (state.merge_memory) and the list of one-time migrations applied to the profile (state.migrations).
## Schema 8 saves of the released game migrate on load (campaign.migrate_schema9); nothing is reset.
const SCHEMA:=9
const MIGRATABLE_SCHEMAS:=[8,9]

func new_profile() -> void:
    suspended=false
    clear_target()
    state = {"schema":SCHEMA,"merge_memory":{},"migrations":[],"group_kills":[0,0,0,0],"player_level":1,"xp":0.0,"coins":0,"gems":0,"items":{},"gear":["","",""],"supplies":[""],
        "weapon":"","outfit":"","upgrades":{},"auto_slots":[],
        "spawns":[0],"spawn":0,"cards":{},"prestiges":0,"offer":[],"victory":false,
        "focus":-1,"focus_variant":2,"boost_time":0.0,"boost_power":0.0,"use_cd":0.0,"history":[],
        "pickups":[],"next_pickup":0,"clock":0.0,"collect_clock":0.0,"collect_clocks":[0.0,0.0,0.0,0.0],"merge_clock":0.0,
        "use_clock":0.0,"summon_clock":0.0,"next_cat":0,"help":0,"paused":false,
        "playtime_total":0.0,"playtime_run":0.0,"buffs":{},"supply_found":{},"supply_uses":{},"supply_mastery_credit":{},"boss_respawns":{},"boss_saved_at":0.0,"reward_stage":1}
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

## An independent copy of what a save would write (probes and tools).
func snapshot() -> Dictionary:
    return save_snapshot().duplicate(true)

## Change 24: the save provider's snapshot is a shallow view of the live state, serialized at once and
## never kept or mutated, so a save no longer deep-copies the whole profile first. Explored fog masks
## are encoded compactly (campaign.encode_explored).
func save_snapshot() -> Dictionary:
    var result := state.duplicate()
    # Summoned helpers are encounter-transient (Change 13): never saved, so a load starts clean.
    result.enemies=state.enemies.filter(func(e):return not is_helper(e))
    var worlds: Dictionary={}
    for key in state.get("stage_worlds",{}):
        var saved: Dictionary=state.stage_worlds[key].duplicate()
        saved["enemies"]=saved.get("enemies",[]).filter(func(e):return not is_helper(e))
        worlds[key]=saved
    result.stage_worlds=worlds
    result.explored=campaign.encode_explored(state.explored)
    result["boss_saved_at"] = float(state.boss_saved_at) if suspended else Time.get_unix_time_from_system()
    result["reward_stage"] = campaign.reward_stage()
    result["rng_state"] = str(rng.state)
    result["offline_snapshot"] = state.offline_snapshot.duplicate(true) if suspended else campaign.offline_snapshot()
    return result

func restore(data: Dictionary) -> void:
    # Change 50: the game is released, so player saves are a compatibility obligation (Playbook 61.2).
    # A schema 8 save migrates to schema 9 after an untouched copy of the file it came from is kept
    # (SaveService.preserve_copy). A save this build cannot read (an unknown or newer schema, or one that
    # fails validation) is also copied aside before the fresh profile replaces it, so it stays restorable.
    var schema:=int(data.get("schema",0)) if campaign.number(data.get("schema")) else 0
    if not MIGRATABLE_SCHEMAS.has(schema):
        SaveService.preserve_copy("rejected_schema_%d" % schema)
        new_profile()
        SaveService.write_blocked=false
        SaveService.last_load_result="development_reset"
        return
    if schema<SCHEMA:SaveService.preserve_copy("schema%d_backup" % schema)
    data=campaign.normalize_snapshot(data)
    if not _valid_snapshot(data):
        SaveService.preserve_copy("rejected_invalid")
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
    campaign.mastery.reset_cache()
    # Records only rise; latch anything already complete without announcing it again on load.
    campaign.mastery.evaluate(false)
    settle_boss_respawns()
    campaign.settle_offline()
    touch()

func _valid_snapshot(data: Dictionary) -> bool:
    return campaign.valid_snapshot(data)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED:
        state.boss_saved_at=Time.get_unix_time_from_system()
        state.offline_snapshot=campaign.offline_snapshot()
        suspended = true
        movement = Vector2.ZERO
        SaveService.save_now()
    elif what == NOTIFICATION_APPLICATION_RESUMED:
        settle_boss_respawns()
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
        # Change 50: a new record starts at the item's remembered merge level (0 if never merged), so
        # finding an item again restores its progress. A record exists only for an item obtained this
        # run (add_item); owning no copy grants nothing (stat_sources and normal skip quantity < 1).
        state.items[id] = {"qty":0,"merge":remembered_merge(id),"extras":extras}
    return state.items[id]

## Change 50: the permanent merge level of an item identity (kept by Prestige, cleared by Hard Reset).
## Supplies grow by use (supply mastery), never by merging, so they are never remembered.
func remembered_merge(id: String) -> int:
    if not catalog.items.has(id) or catalog.items[id].kind=="consumable":return 0
    return int(state.get("merge_memory",{}).get(id,0))

## Records a reached merge level (it only ever rises).
func remember_merge(id: String,merge_level: int) -> void:
    if not catalog.items.has(id) or catalog.items[id].kind=="consumable":return
    if merge_level>remembered_merge(id):state.merge_memory[id]=merge_level

func quantity(id: String) -> int:
    return int(state.items.get(id,{}).get("qty",0))

func normal(id: String) -> Dictionary:
    var output: Dictionary = {}
    # Supplies (Change 11): base + gain x permanent mastery. Stock (charges) never changes the effect.
    if catalog.items[id].kind=="consumable":
        for stat in catalog.items[id].normal:
            var pair: Array=catalog.items[id].normal[stat]
            output[stat]=float(pair[0])+float(pair[1])*supply_mastery(id)
        return output
    if catalog.items[id].kind=="skill":
        var value:=skill_base_power(id)
        return {"power":value*stats().hp if catalog.items[id].skill=="heal" else value}
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

## The highest merge level a saved record may hold. Weapons keep the ^100 bound of every earlier build
## even where new merging stops lower (Change 51), so an older weapon above its new cap stays valid and
## keeps its exact level (Change 50 brief: never clamp or reject earned progression).
func merge_validation_cap(id: String) -> int:
    if catalog.items[id].kind=="weapon":return maxi(merge_cap(id),100)
    return merge_cap(id)

func merge_cap(id: String) -> int:
    if catalog.items[id].kind=="consumable":return int(catalog.progression.supply_mastery.cap)
    return int(catalog.progression.merge.copy_cap if copy_growth(id) else catalog.progression.merge.weapon_cap)

## The ^level shown for an item: a supply's permanent mastery, otherwise its record's merge level.
func merge_level(id: String) -> int:
    if catalog.items.has(id) and catalog.items[id].kind=="consumable":return supply_mastery(id)
    return int(state.items.get(id,{}).get("merge",0))

# ---------------------------------------------------------------- supplies (Change 11)
# A supply has stock (items[id].qty) and permanent mastery from successful uses (Change 17).
# Every change17.supply_uses_per_level uses (3 since Change 36) add one capped level; one-time
# supply_mastery_credit preserves older earned levels.
# supply_found is historical only. Prestige clears uses and credit as well as stock/buffs/bindings.
# Coin Tonic keeps boost_time/boost_power; other timed supplies use state.buffs[id] = {time, power}.

func supply(id: String) -> Dictionary:
    return catalog.items[id].get("supply",{}) if catalog.items.has(id) else {}

func supply_ids() -> Array:
    var result: Array=[]
    for id in catalog.items:
        if catalog.items[id].kind=="consumable":result.append(id)
    return result

func supply_mastery(id: String) -> int:
    return clampi(int(state.supply_mastery_credit.get(id,0))+int(state.supply_uses.get(id,0))/int(catalog.progression.change17.supply_uses_per_level),0,int(catalog.progression.supply_mastery.cap))

## Milestone multipliers reached so far: {"duration": x, "cooldown": x} (1.0 before the first).
func supply_milestone(id: String) -> Dictionary:
    var out:={"duration":1.0,"cooldown":1.0}
    for step in catalog.progression.supply_mastery.milestones:
        if supply_mastery(id)<int(step.merge):break
        out.duration=float(step.duration);out.cooldown=float(step.cooldown)
    return out

func next_supply_milestone(id: String) -> Dictionary:
    for step in catalog.progression.supply_mastery.milestones:
        if supply_mastery(id)<int(step.merge):return step
    return {}

func supply_value(id: String) -> float:
    return float(normal(id).get(str(supply(id).stat),0.0))

func supply_duration(id: String) -> float:
    return float(supply(id).get("duration",0))*float(supply_milestone(id).duration)

func supply_cooldown(id: String) -> float:
    return supply_cooldown_with(id,float(supply_milestone(id).cooldown))

## A supply's cooldown under a mastery multiplier, never below its authored floor (Change 13: the
## Health Potion is 12 s, 10 s at the shortest, so mastery cannot undo the slowdown).
func supply_cooldown_with(id: String,multiplier: float) -> float:
    var s:=supply(id)
    var base:=float(s.get("cooldown",0))
    if base<=0:return 0.0
    return maxf(float(s.get("cooldown_floor",0)),base*multiplier)

func buff_time(id: String) -> float:
    if id=="coin_boost":return float(state.boost_time)
    return float(state.get("buffs",{}).get(id,{}).get("time",0.0))

func buff_power(id: String) -> float:
    if id=="coin_boost":return float(state.boost_power)
    return float(state.get("buffs",{}).get(id,{}).get("power",0.0))

## Why this supply cannot be used right now ("" when it can). Healing needs missing HP (and the
## potion its cooldown); a timed supply waits until its own buff has run out.
func supply_block_reason(id: String) -> String:
    var s:=supply(id)
    if s.is_empty() or quantity(id)<1 or state.player.hp<=0:return "CANNOT_USE"
    var maxhp: float=stats().hp
    if str(s.effect) in ["heal","recovery"] and float(state.player.hp)>=maxhp*float(s.use_hp):return "SUPPLY_HP_HIGH"
    if str(s.effect)=="heal" and float(state.use_cd)>0:return "SUPPLY_COOLDOWN"
    if float(s.duration)>0 and buff_time(id)>0:return "SUPPLY_ACTIVE"
    return ""

## Auto-use shares eligibility: Potion at any missing HP, Salve at its threshold, Guard in combat.
func supply_auto_ready(id: String) -> bool:
    if not supply_block_reason(id).is_empty():return false
    var s:=supply(id)
    match str(s.effect):
        "heal","recovery":return float(state.player.hp)<=stats().hp*float(s.auto_hp)
        "guard":return campaign.in_combat()
    return true

## Which supplies an enemy of this type can drop: those whose first stage is reached by its map.
func supply_pool(group: int) -> Array:
    var result: Array=[]
    for id in supply_ids():
        if int(supply(id).get("min_stage",1))<=int(catalog.groups[group].stage):result.append(id)
    return result

## Chance that one kill of this type drops this supply (the supply roll times its weight share).
func supply_drop_chance(group: int,id: String) -> float:
    var pool:=supply_pool(group)
    if not pool.has(id):return 0.0
    var total:=0.0
    for other in pool:total+=float(supply(other).drop_weight)
    return consumable_chance(group,id)*float(supply(id).drop_weight)/total

func _roll_supply(group: int) -> String:
    var pool:=supply_pool(group)
    var total:=0.0
    for id in pool:total+=float(supply(id).drop_weight)
    var roll:=rng.randf()*total
    for id in pool:
        roll-=float(supply(id).drop_weight)
        if roll<0:return id
    return pool.back()

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
    if catalog.items[id].kind=="skill" and stat=="power":
        return (skill_base_power(id,m+1)-skill_base_power(id,m))*(stats().hp if catalog.items[id].skill=="heal" else 1.0)
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

## Change 10 transparency: how one effective stat is built. The parts are stat_sources() (exactly
## what stats() adds), the multiplier is the same prestige card factor, and the total is stats()
## itself, so the Stats and Level panels never recompute a formula. HP and damage have no caps.
func stat_breakdown(key: String) -> Dictionary:
    var parts: Array=[]
    var subtotal:=0.0
    var sources:=stat_sources()
    for source in sources:
        var value:=float(sources[source].get(key,0.0))
        subtotal+=value
        if value!=0.0:parts.append([source,value])
    var multiplier:=card(key) if key in ["hp","damage"] else 1.0
    return {"parts":parts,"subtotal":subtotal,"multiplier":multiplier,"total":float(stats()[key])}

## Effective stats at another player level, everything else unchanged: the combat getter itself.
func stats_at_level(player_level: int) -> Dictionary:
    var saved:=int(state.player_level)
    state.player_level=clampi(player_level,1,max_level());_stats_revision=-1
    var result: Dictionary=stats().duplicate()
    state.player_level=saved;_stats_revision=-1
    return result

func max_level() -> int:
    return int(catalog.progression.max_level)

## Equipment slots owned now: 3 + purchased (Change 10 caps it at 70). Supplies are a separate pool.
func equipment_slot_count() -> int:
    return int(player_upgrade_value("gear_slots"))

func equipment_slot_max() -> int:
    return int(player_upgrade_value("gear_slots",int(catalog.upgrades.gear_slots.cap)-level("gear_slots")))

func xp_required(player_level: int = -1) -> float:
    var current:=int(state.player_level) if player_level<0 else player_level
    return ceil(float(catalog.progression.xp_base)*pow(current,float(catalog.progression.xp_growth)))

func gain_xp(amount: float) -> void:
    if state.player_level>=max_level():
        return
    state.xp+=maxf(0,amount)
    var old_hp:=float(stats().hp)
    var gained:=false
    while state.player_level<max_level() and state.xp>=xp_required():
        state.xp-=xp_required()
        state.player_level+=1
        gained=true
    if state.player_level==max_level():
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
    # Change 13 helpers: the copied type's own art and attack, scaled by its summon rule, with no
    # loot, skills, coins or XP (a helper's death is never rewarded; see _kill).
    if variant==HELPER_VARIANT:
        var rule: SummonRule=abilities.helper_rule(str(def.id))
        def.hp*=rule.hp_scale if rule else .5
        def.damage*=rule.damage_scale if rule else .4
        def.loot=[];def.skills=[];def.coins=0.0;def.xp=0.0;def.gear_chance=0.0
        return def
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

## found: copies new to the profile (drops, offline earnings), recorded historically; purchases,
## evolutions and a dropped stack picked up again are not. announce: list it in the recent finds.
func add_item(id: String, amount: int = 1, found: bool = true, announce: bool = true) -> bool:
    if not catalog.items.has(id) or amount < 1:
        return false
    if not can_add(id):
        return false
    var r := record(id)
    if int(r.qty)==0:
        var list := slots(id)
        list[list.find("")] = id
    r.qty += amount
    # Found copies remain a historical counter; only successful use grants mastery (Change 17).
    if catalog.items[id].kind=="consumable" and found:
        state.supply_found[id]=int(state.supply_found.get(id,0))+amount
    if announce:history("HISTORY_ITEM",id,amount,0)
    if catalog.items[id].kind=="skill":discover_skill(str(catalog.items[id].skill))
    campaign.mastery.record_found(id)
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

## Gear or a skill with a spare copy and room to grow (supplies grow by themselves, never by merging).
func can_merge(id: String) -> bool:
    return catalog.items.has(id) and catalog.items[id].kind!="consumable" and quantity(id)>1 and int(record(id).merge)<merge_cap(id)

func merge(id: String, all: bool = false) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    if catalog.items[id].kind=="consumable":
        return fail("SUPPLY_NO_MERGE")
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
    remember_merge(id,int(r.merge))
    campaign.progress("merge",id,count)
    touch()
    return true

## Merge All (Change 12, a one-time 5,000-Gem unlock): one deliberate action that performs every
## merge an ordinary Merge (all copies) would, item by item, under the same rules: gear and skills only
## (supplies grow by themselves), one copy always kept, never past the item's cap, and never an
## evolution (that stays a separate action). Returns {items, copies}; nothing changes when both are 0.
func merge_all() -> Dictionary:
    var result:={"items":0,"copies":0}
    if level("merge_all")<1:
        fail("MERGE_ALL_LOCKED");return result
    if not action_lock_reason().is_empty():
        fail(action_lock_reason());return result
    var ids: Array=state.items.keys();ids.sort()
    for id in ids:
        if not can_merge(id):continue
        var before:=int(record(id).merge)
        if merge(id,true):
            result.items+=1
            result.copies+=int(record(id).merge)-before
    return result

## Copies Merge All would merge now (0 = nothing to merge).
func merge_all_copies() -> int:
    var total:=0
    for id in state.items:
        if can_merge(id):total+=mini(quantity(id)-1,merge_cap(id)-int(record(id).merge))
    return total

## Why evolve(id) would refuse now ("" when it would succeed). Manual and Auto Evolution share it.
func evolve_block_reason(id: String) -> String:
    var lock:=action_lock_reason()
    if not lock.is_empty():return lock
    if not catalog.items.has(id):return "EVOLUTION_NEEDS"
    var target: String = catalog.items[id].next
    if target=="" or int(state.items.get(id,{}).get("merge",0))<int(catalog.progression.evolution.required_merge) or quantity(id)<int(catalog.progression.evolution.spare_cost)+1:
        return "EVOLUTION_NEEDS"
    if not can_add(target):
        return "INVENTORY_FULL"
    return ""

func evolve(id: String) -> bool:
    var reason:=evolve_block_reason(id)
    if not reason.is_empty():
        return fail(reason)
    var target: String = catalog.items[id].next
    # Every validation precedes both mutations; output is committed with its cost.
    _remove(id,int(catalog.progression.evolution.spare_cost))
    add_item(target,1,false)
    if auto_merge_excluded(id):record(target).auto_merge_excluded=true
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
    if slot<0 or slot>=state.supplies.size():return false
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
    var reason:=supply_block_reason(id)
    if not reason.is_empty():
        return fail(reason)
    var value:=supply_value(id)
    match str(supply(id).effect):
        "heal":
            var gain := minf(stats().hp*value,stats().hp-state.player.hp)
            state.player.hp += gain
            state.use_cd=supply_cooldown(id)
            feedback.emit("player",gain,true)
        "coins":
            state.boost_time=supply_duration(id)
            state.boost_power=value
        _:
            state.buffs[id]={"time":supply_duration(id),"power":value}
    state["consumable_uses"]=int(state.get("consumable_uses",0))+1
    _remove(id,1)
    state.supply_uses[id]=mini(int(catalog.progression.supply_mastery.cap)*int(catalog.progression.change17.supply_uses_per_level),int(state.supply_uses.get(id,0))+1)
    touch()
    return true

## Real Coin Tonic duration in seconds at its current mastery.
func coin_boost_duration() -> float:
    return supply_duration("coin_boost")

## Shop: all five authored supplies have Coin prices. Bought copies add stock only.
func purchase_consumable(id: String) -> bool:
    if not action_lock_reason().is_empty():
        return fail(action_lock_reason())
    var cost:=int(supply(id).get("price",0))
    if cost<=0:
        return fail("CANNOT_USE")
    if not can_add(id):
        return fail("INVENTORY_FULL")
    if not pay("coins",cost):
        return false
    add_item(id,1,false)
    # Change 15: a shop purchase is one of the demonstrated actions of the reveal table.
    campaign.progress("supply_buy",id,1)
    return true

func upgrade_cost(id: String, group: int = -1) -> int:
    return campaign.upgrade_cost("skill_auto_slots" if id.begins_with("skill_auto_") else id,group)

func upgrade_maxed(id: String, group: int = -1) -> bool:
    if level(id,group)>=int(catalog.upgrades[id].cap):
        return true
    return false

func buy_upgrade(id: String, group: int = -1) -> bool:
    if id.begins_with("skill_auto_"):id="skill_auto_slots"
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
    if id=="skill_auto_slots":skill_automation_changed.emit()
    campaign.upgrade_bought(id,group)
    touch()
    return true

## Change 50 (approved Prestige rule): Prestige keeps every purchased upgrade at its level, whether it
## was bought with Coins or Gems and whatever its scope. A camp-scoped upgrade (camp reveal radius) stays
## bought but only acts while its camp is owned again (campaign.reveal reads state.spawns). The catalog's
## old per-upgrade `keep` flag is no longer read. Hard Reset clears all of them.
func upgrade_kept(id: String) -> bool:
    return catalog.upgrades.has(id)

func pay(currency: String, cost: int) -> bool:
    if cost<0 or state[currency]<cost:
        return fail("NOT_ENOUGH_"+currency.to_upper())
    state[currency] -= cost
    state["online_"+currency]=maxf(0,float(state.get("online_"+currency,0))-cost)
    # Change 24: a purchase is a committed action, saved within SaveService.COMMITTED_SAVE_DELAY.
    SaveService.mark_committed()
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
            # Change 16: a stack the player dropped comes back as it left: same copies, no recent-find
            # line, no supply mastery and no mission, Prestige or Mastery progress; only the online
            # credit it took with it returns (never more), so dropping and picking up earns nothing.
            if pickup.has("dropped"):
                if not add_item(pickup.item,int(pickup.get("qty",1)),false,false):return fail("INVENTORY_FULL")
                _restore_credit(str(pickup.item),pickup.dropped)
                state.pickups.erase(pickup)
                touch()
                return true
            if add_item(pickup.item):
                campaign.progress("collect",pickup.item,1)
                if catalog.items[pickup.item].kind in ["weapon","outfit"]:campaign.progress("gear",pickup.item,1)
                state.pickups.erase(pickup)
                return true
            return fail("INVENTORY_FULL")
    return false

## Change 16 Drop All: why this whole stack cannot be dropped now ("" when it can). Equipped gear and
## skills are unequipped first, so the worn loadout never changes by accident.
func discard_block_reason(id: String) -> String:
    var lock:=action_lock_reason()
    if not lock.is_empty():return lock
    if not catalog.items.has(id) or quantity(id)<1 or float(state.player.hp)<=0:return "CANNOT_USE"
    if equipped(id):return "DROP_EQUIPPED"
    return ""

## Drops every copy of an item at the player's feet as one ground stack and frees its slot at once.
## The record (merge level, extras) stays, as when a stack runs out, so picking it up restores it. The
## stack expires like other loot and belongs to no enemy type (group -1), so no Auto-Collect takes it
## back; it can only be tapped. The run's online credit for the item leaves with it (pickup.dropped).
func discard(id: String) -> bool:
    var reason:=discard_block_reason(id)
    if not reason.is_empty():return fail(reason)
    var amount:=quantity(id)
    var credit:={"online":minf(float(state.online_items.get(id,0)),amount),"ops":{}}
    for op_id in state.opportunities:
        var o: Dictionary=state.opportunities[op_id]
        if o.has("item_"+id):credit.ops[op_id]=minf(float(o["item_"+id]),amount)
    _remove(id,amount)
    state.next_pickup+=1
    var at:=(position_of(state.player)+Vector2(18.0*float(state.player.facing),6.0)).clamp(Vector2(14,30),Vector2(catalog.world.size[0]-14,catalog.world.size[1]-14))
    state.pickups.append({"uid":state.next_pickup,"item":id,"qty":amount,"x":at.x,"y":at.y,"ttl":300.0,"group":-1,"dropped":credit})
    touch()
    return true

func _restore_credit(id: String,credit: Dictionary) -> void:
    if float(credit.get("online",0))>0:state.online_items[id]=float(state.online_items.get(id,0))+float(credit.online)
    for op_id in credit.get("ops",{}):
        if state.opportunities.has(op_id):
            var o: Dictionary=state.opportunities[op_id]
            o["item_"+id]=float(o.get("item_"+id,0))+float(credit.ops[op_id])

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
    a.cooldown = maxf(0,a.cooldown-dt*attack_rate(a,dt))
    a.hurt = maxf(0,a.hurt-dt)
    a.quiet += dt
    if a.hp<=0:
        a.dead_age += dt
        if not state.boss_respawns.has(str(a.id)):a.respawn=maxf(0,a.respawn-dt)

func _resolve_attack(a: Dictionary, dt: float) -> void:
    if a.hp<=0 or a.windup<=0:
        return
    a.windup -= dt*attack_rate(a,dt)
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
                if int(other.group)==int(target.group) and other.get("variant",2)==target.get("variant",2) and not is_helper(other) and other.hp>0 and not other.returning and position_of(other).distance_to(position_of(target))<=float(target_def.assist_radius):
                    other.aggro=true
    if target.hp<=0:
        _kill(target)

func _kill(a: Dictionary) -> void:
    if a.id==locked_target or a.id=="player":clear_target()
    a.windup=0.0
    a.telegraph=false
    a.target=""
    a.dead_age=0.0
    a.aggro=false
    a.moving=false
    # A summoned helper never pays: no XP, coins, gems, loot, kill count, mission, achievement,
    # discovery or Prestige progress (Change 13). It is removed after its death animation.
    if is_helper(a):
        a.respawn=INF
        touch()
        return
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
        if catalog.groups[int(a.group)].boss:
            state.boss_respawns[str(a.id)]={"group":int(a.group),"stage":int(catalog.groups[int(a.group)].stage),"remaining":a.respawn,"x":a.home_x,"y":a.home_y}
            boss_respawns_changed.emit()
        state.group_kills[int(a.group)]+=1
        _reward(a)
        campaign.killed(a)
    touch()

func gear_chance(group: int) -> float:
    return group_upgrade_value("loot",group)

## The one Gem drop probability (Change 12): base 5% + Gem Chance levels + Gem Wisdom + this type's
## kill achievements, plus Boss Gem Chance on bosses. Only the probability range clamps it; there is
## no game-specific ceiling, so every earned bonus counts.
func gem_chance(group: int) -> float:
    var base:=boss_gem_chance() if catalog.groups[group].boss else gem_base_chance()
    return clampf(base+achievement_gems(group),0.0,1.0)

func coin_reward(group: int) -> float:
    return group_upgrade_value("coin_amount",group)

func _reward(a: Dictionary) -> void:
    var group:=int(a.group)
    var def:=enemy_definition(group,int(a.get("variant",2)))
    gain_xp(group_xp(group,int(a.get("variant",2)))*(1.0+buff_power("wisdom_tonic")))
    var coins:=coin_reward(group)
    state.coins+=coins
    campaign.progress("coins","",coins)
    if rng.randf()<gem_chance(group):
        var gems:=gem_amount(0,group)
        state.gems+=gems
        state.online_gems+=gems
        history("HISTORY_CURRENCY","",gems,0)
    var dropped: Array=[]
    for id in def.loot:
        if rng.randf()<gear_chance(group):dropped.append(_drop(id,a))
    if rng.randf()<consumable_chance(group,"supply"):dropped.append(_drop(_roll_supply(group),a))
    if not def.skills.is_empty() and rng.randf()<(.1 if def.boss else .05)+.01*level("skill_drop",group):
        dropped.append(_drop("skill_"+str(def.skills[rng.randi_range(0,def.skills.size()-1)]),a))
    # Change 15: the profile's first weapon or outfit and a matching copy, if no natural drop came.
    campaign.onboarding.loot_kill(a,def,dropped)
    # Change 27: a listed boss's first lifetime defeat always drops its own weapon (hidden).
    campaign.onboarding.boss_first_kill(a,def,dropped)
    _loot_speech(a,dropped)

## Change 11: a defeated enemy's loot line follows what it actually dropped, after every roll: one
## bubble at most, for the most personal item (outfit, then weapon, skill, supply); none without a drop.
const LOOT_SPEECH:=[["outfit","CHAT_LOOT_OUTFIT"],["weapon","CHAT_LOOT_WEAPON"],["skill","CHAT_LOOT_SKILL"],["consumable","CHAT_LOOT_SUPPLY"]]
func _loot_speech(a: Dictionary,dropped: Array) -> void:
    if str(a.get("id",""))=="":return
    for pair in LOOT_SPEECH:
        for id in dropped:
            if str(catalog.items[id].kind)==pair[0]:
                chatter.emit(str(a.id),pair[1])
                return

func _drop(id: String,a: Dictionary) -> String:
    state.next_pickup+=1
    state.pickups.append({"uid":state.next_pickup,"item":id,"x":a.x+rng.randf_range(-10,10),"y":a.y+rng.randf_range(-8,8),"ttl":300.0,"group":int(a.group)})
    return id

func step(dt: float) -> void:
    if state.is_empty() or get_tree().paused or suspended or held or not state.get("prestige_batch",{}).is_empty():
        return
    dt=minf(maxf(dt,0),.1)
    state.clock+=dt
    # Active play only: step never runs while paused, suspended (background, guide chooser), held
    # (the review invitation, Change 35) or during a prestige choice, and offline settlement never advances these clocks.
    state.playtime_total=float(state.get("playtime_total",0.0))+dt
    state.playtime_run=float(state.get("playtime_run",0.0))+dt
    tick_boss_respawns(dt)
    campaign.step(dt)
    state.use_cd=maxf(0,state.use_cd-dt)
    state.boost_time=maxf(0,state.boost_time-dt)
    if state.boost_time==0:
        state.boost_power=0.0
    # Ground loot lasts 300 s of active time (it fades for the last 30 s); inactive stage worlds keep
    # their pickups frozen. Restored in Change 11: the expiry had been dropped, so loot that could not
    # be collected (a full inventory) piled up without bound in the save and the world view.
    for pickup in state.pickups:
        pickup.ttl=float(pickup.ttl)-dt
    if state.pickups.any(func(v):return float(v.ttl)<=0):
        state.pickups=state.pickups.filter(func(v):return float(v.ttl)>0)
    # Supply buffs run on active time only; an expiry changes combat stats, so it touches.
    for id in state.buffs.keys():
        state.buffs[id].time=float(state.buffs[id].time)-dt
        if float(state.buffs[id].time)<=0:
            state.buffs.erase(id)
            touch()
    var p: Dictionary=state.player
    _actor_timers(p,dt)
    for e in state.enemies:
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
    # Iterate a stable copy. Change 24: membership is re-checked (a linear scan per actor) only once
    # the roster really lost an actor or was replaced during this loop, never on ordinary ticks.
    var roster: Array=state.enemies
    var removals:=_roster_removals
    for e in roster.duplicate():
        if (removals!=_roster_removals or not is_same(roster,state.enemies)) and not state.enemies.has(e):
            continue
        var group:=int(e.group)
        var maxhp:=float(enemy_definition(group,int(e.get("variant",2))).hp)
        if is_helper(e):
            if e.hp<=0:
                if float(e.dead_age)>=1.0:state.enemies.erase(e);_roster_removals+=1
                continue
            if not helper_bound(e):
                dissolve_helper(e)
                continue
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
    p.attack_slow=maxf(0,float(p.get("attack_slow",0))-dt)
    for a in state.enemies:
        a.attack_slow=maxf(0,float(a.get("attack_slow",0))-dt)
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
    if suspended or held or get_tree().paused or state.player.hp<=0 or enemy.is_empty() or enemy.hp<=0 or id=="player" or not campaign.target_allowed(enemy):
        return false
    locked_target=id
    manual_target=id
    state.focus=-1
    state.player.windup=0.0
    state.player.target=""
    state.player.attack_age=9.0
    state.player.idle=1.0
    # Change 35: the Guided targeting lesson completes on this successful manual selection only (the
    # map gesture's release on an enemy is its one caller); automatic acquisition never comes here.
    campaign.guided.action("target",id)
    touch()
    return true

## Change 41: automatic target priority, shared by auto-attack (_combat_target) and skill activation
## (campaign.skill_activation_target). Without a Farming Focus: the nearest visible enemy within radius.
## With a Focus: 1) the nearest eligible enemy of the focused type and loadout; 2) only when none is
## eligible, the nearest enemy actively attacking the player (threatens_player); 3) nothing, so the
## caller walks back to or waits at the farming spot. Enemies that are merely nearby or passive are never
## chosen under a Focus, so the hero defends itself without chasing strangers across the map. Ties keep
## the roster order (deterministic).
func auto_target(radius: float,view=null) -> Dictionary:
    if view==null:view=campaign.sight()
    var origin:=position_of(state.player)
    var target: Dictionary={}
    var threat: Dictionary={}
    var best:=radius
    var best_threat:=radius
    for enemy in state.enemies:
        if enemy.hp<=0 or not campaign.target_allowed(enemy,view):
            continue
        var d:=origin.distance_to(position_of(enemy))
        if focus_match(enemy):
            if d<best:best=d;target=enemy
        elif threatens_player(enemy) and d<best_threat:
            best_threat=d;threat=enemy
    return target if not target.is_empty() else threat

## True without a Focus, else only for the focused type and loadout.
func focus_match(enemy: Dictionary) -> bool:
    return int(state.focus)<0 or (int(enemy.group)==int(state.focus) and int(enemy.get("variant",2))==int(state.focus_variant))

## An enemy engaged with the living player: alive, aggro and not leashing home (it is chasing or hitting
## the player; aggro only ever targets the player). Seeing or standing near the player is not enough.
func threatens_player(enemy: Dictionary) -> bool:
    return float(state.player.hp)>0 and float(enemy.hp)>0 and bool(enemy.get("aggro",false)) and not bool(enemy.get("returning",false))

func _combat_target() -> Dictionary:
    var target:=_find_actor(locked_target)
    if not target.is_empty() and target.hp>0 and campaign.target_allowed(target) and _keeps_lock(target):
        return target
    clear_target()
    target=auto_target(float(catalog.world.acquisition))
    if not target.is_empty():
        locked_target=target.id
        return target
    return {}

## A lock survives while it is the player's own choice, the focused type, or (under a Focus) a defensive
## lock on an attacker that still attacks while no focused enemy is eligible: the focus regains priority
## as soon as one is (Change 41).
func _keeps_lock(target: Dictionary) -> bool:
    if manual_target==str(target.id) or focus_match(target):return true
    if not threatens_player(target):return false
    var preferred:=auto_target(float(catalog.world.acquisition))
    return preferred.is_empty() or not focus_match(preferred)

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

## Chance that a kill rolls a supply at all; _roll_supply then picks which one (supply_drop_chance).
func consumable_chance(group: int,_id: String) -> float:
    return (.15 if catalog.groups[group].boss else .05)+minf(.15,.01*level("supply_drop",group))+campaign.bonus("supply_chance")

func group_xp(group: int,variant: int=2) -> float:
    return group_upgrade_value("group_xp",group,variant)

func merge_gain(id: String,stat: String) -> float:
    var definition: Dictionary=catalog.items[id]
    var gain: float=float(definition.get("merge_gain",{}).get(stat,float(definition.normal[stat][1])*3.0))
    return gain*card("merge")

## Change 13: the enemy types that actually drop this exact item (their loot weapon and outfit, and
## the base skill item of each of their skills). An evolved successor is not a drop of its source's
## droppers: a Stone Sword is dropped only by the types whose own loot holds the Stone Sword.
var _drop_index: Dictionary={}
func droppers(id: String) -> Array:
    if _drop_index.is_empty():
        for g in range(catalog.groups.size()):
            var ids: Array=catalog.groups[g].loot.duplicate()
            for skill in catalog.groups[g].skills:ids.append("skill_"+str(skill))
            for item in ids:
                if not _drop_index.has(item):_drop_index[item]=[]
                if not _drop_index[item].has(g):_drop_index[item].append(g)
    return _drop_index.get(id,[])

## The enemy type whose Auto-Merge merges this item: the first type that drops this exact item and
## has Auto-Merge bought, or -1. Shared drops work through any of their droppers; supplies never.
func gear_group(id: String) -> int:
    if not catalog.items.has(id) or catalog.items[id].kind=="consumable":return -1
    for g in droppers(id):
        if level("merge_gear",g)>0:return g
    return -1

func can_auto_merge(id: String) -> bool:
    return gear_group(id)>=0 and not auto_merge_excluded(id)

func auto_merge_excluded(id: String) -> bool:
    return bool(state.items.get(id,{}).get("auto_merge_excluded",false))

func set_auto_merge_excluded(id: String,excluded: bool) -> bool:
    if not action_lock_reason().is_empty() or not catalog.items.has(id) or catalog.items[id].kind=="consumable" or quantity(id)<1:return false
    record(id).auto_merge_excluded=excluded
    touch()
    return true

## Change 13 Auto Evolution: the type whose unlock evolves this weapon (the first type that drops this
## exact weapon with Auto Evolution bought), or -1. Outfits, skills, supplies and the last tier never.
func evolve_group(id: String) -> int:
    if not catalog.items.has(id) or catalog.items[id].kind!="weapon" or str(catalog.items[id].next)=="":return -1
    for g in droppers(id):
        if level("auto_evolve",g)>0:return g
    return -1

## Weapons this type drops that can still evolve (Auto Evolution applies to the type only if any).
func evolvable_drops(g: int) -> Array:
    return catalog.groups[g].loot.filter(func(id):return catalog.items[id].kind=="weapon" and str(catalog.items[id].next)!="")

# ---------------------------------------------------------------- summoned helpers (Change 13)

func is_helper(a: Dictionary) -> bool:
    return int(a.get("variant",2))==HELPER_VARIANT

## A helper stays only while its summoner is alive and still fighting the living player, and while it
## stays on its leash; otherwise it dissolves (no reward).
func helper_bound(e: Dictionary) -> bool:
    var owner:=_find_actor(str(e.get("summoner","")))
    if owner.is_empty() or float(owner.hp)<=0 or not bool(owner.aggro) or bool(owner.get("returning",false)):return false
    if float(state.player.hp)<=0 or bool(e.get("returning",false)):return false
    return position_of(e).distance_to(Vector2(e.home_x,e.home_y))<=float(catalog.world.leash)

func dissolve_helper(e: Dictionary) -> void:
    e.hp=0.0
    _kill(e)

func helpers_of(summoner_id: String) -> Array:
    return state.enemies.filter(func(e):return is_helper(e) and float(e.hp)>0 and str(e.get("summoner",""))==summoner_id)

var _helper_serial:=0
## Creates up to `count` helpers of `group` around the summoner (never inside solid scenery).
func spawn_helpers(summoner: Dictionary,rule: SummonRule,group: int,count: int) -> Array:
    var ids: Array=[]
    var center:=position_of(summoner)
    for i in range(count):
        var pos:=center
        for attempt in range(8):
            var p:=center+Vector2(rule.spawn_radius,0).rotated(TAU*(float(i)/count+attempt*.125)+.4)
            p=p.clamp(Vector2(14,30),Vector2(catalog.world.size[0]-14,catalog.world.size[1]-14))
            if not campaign.solid_at(p):
                pos=p
                break
        _helper_serial+=1
        var id:="h%d_%s" % [_helper_serial,summoner.id]
        var a:=_actor(id,pos.x,pos.y,1,group)
        a["variant"]=HELPER_VARIANT
        a["summoner"]=str(summoner.id)
        a.hp=enemy_definition(group,HELPER_VARIANT).hp
        a.aggro=true
        a.quiet=0.0
        a.facing=signf(state.player.x-pos.x) if absf(state.player.x-pos.x)>.01 else 1.0
        state.enemies.append(a)
        ids.append(id)
    if not ids.is_empty():
        touch()
        summoned.emit(str(summoner.id),ids)
    return ids

## Removes every helper at once (map change). Nothing is rewarded.
func clear_helpers() -> void:
    state.enemies=state.enemies.filter(func(e):return not is_helper(e))

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
    if id=="use_speed" and level("auto_use")==0:return "AUTOMATION_LOCKED"
    if id.begins_with("offline_") and id.ends_with("_rate") and level(id.trim_suffix("_rate"))==0:return "AUTOMATION_LOCKED"
    if id.begins_with("skill_auto_"):
        if state.skills_seen.is_empty():return "UNDISCOVERED"
        if automatic_skill_capacity()>=3:return "UPGRADE_MAX"
        if state.gems<upgrade_cost("skill_auto_slots"):return "NOT_ENOUGH_GEMS"
        return ""
    if id=="skill_drop" and catalog.groups[g].skills.is_empty():return "ACTION_UNAVAILABLE"
    if id=="auto_evolve" and evolvable_drops(g).is_empty():return "ACTION_UNAVAILABLE"
    if id.begins_with("cooldown_") and not skill_seen(id.trim_prefix("cooldown_")):return "UNDISCOVERED"
    if (id=="skill_slots" or id.begins_with("skill_auto_")) and state.skills_seen.is_empty():return "UNDISCOVERED"
    if upgrade_maxed(id,g):return "UPGRADE_MAX"
    var currency: String=catalog.upgrades[id].currency
    if state[currency]<upgrade_cost(id,g):return "NOT_ENOUGH_"+currency.to_upper()
    return ""

func stat_sources() -> Dictionary:
    var result: Dictionary={}
    result["SOURCE_BASE"]={"hp":100.0,"damage":5.0,"crit":.05,"crit_damage":1.5}
    result["SOURCE_UPGRADES"]={"crit":player_upgrade_value("critical_chance"),"crit_damage":player_upgrade_value("critical_damage")}
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
    # Active supply buffs (Change 11): Guard Tonic Defense and Recovery Salve healing over time.
    var active: Dictionary={}
    for id in state.buffs:
        var stat: String=str(supply(id).get("stat",""))
        if stat in ["defense","regen_pct"]:active[stat]=float(active.get(stat,0.0))+buff_power(id)
    if not active.is_empty():result["SOURCE_SUPPLY"]=active
    return result

func group_upgrade_value(id: String,g: int,variant: int=2,extra: int=0) -> float:
    var n:=level(id,g)+extra
    match id:
        "reveal_radius","camp_radius":return n*.25
        # 5% per carried item (bosses 30%), +0.5 points per Loot Chance level (catalog effect/cap).
        "loot":return float(catalog.groups[g].gear_chance)+float(catalog.upgrades.loot.effect)*mini(n,int(catalog.upgrades.loot.cap))+campaign.bonus("gear_chance")
        "supply_drop":return (.15 if catalog.groups[g].boss else .05)+minf(.15,.01*n)
        "skill_drop":return (.1 if catalog.groups[g].boss else .05)+minf(.15,.01*n)
        "group_xp":return float(enemy_definition(g,variant).xp)*(1.0+n*.1)*(1+campaign.bonus("boss_xp" if catalog.groups[g].boss else "normal_xp")+campaign.bonus("xp"))
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
        "boss_gem_chance":return boss_gem_chance(extra)
        "gem_amount":return gem_amount(extra)
        "boss_gem_amount":return boss_gem_amount(extra)
        "skill_slots":return 1+n
        "mission_slots":return 3+n
        "offline_cap":return [5,8,12,18,24,36,48][mini(n,6)]
        "offline_coins":return (120+60*n)*(1+campaign.bonus("offline_coins"))
        "offline_gems":return (2+.5*n)*(1+campaign.bonus("offline_gems"))
        "offline_weapon_rate","offline_outfit_rate":return (1+.5*n)*(1+campaign.bonus("offline_items"))
        "offline_consumable_rate":return (2+n)*(1+campaign.bonus("offline_items"))
        "gear_slots":return 3+n*effect
        "supply_slots":return 1+n*effect
        "respawn":return maxf(2,10-n*effect-campaign.bonus("respawn"))
        "use_speed":return maxf(float(catalog.progression.change17.auto_supply_min_interval),float(catalog.progression.change17.auto_supply_base_interval)-n*effect)
    if id.begins_with("cooldown_"):return maxf(2,float(catalog.skills[id.trim_prefix("cooldown_")].cooldown)*(1-.05*n))
    return n*effect

func farming_position() -> Vector2:
    return campaign.spot(int(state.focus),int(state.focus_variant)) if int(state.focus)>=0 else position_of(state.player)

## Base 5% + Gem Chance upgrade levels (+0.5 points each) + Gem Wisdom, before per-type bonuses.
func gem_base_chance(extra: int=0) -> float:
    return clampf(float(catalog.progression.gem_limits.base_chance)+campaign.bonus("gem_chance")+float(catalog.upgrades.gem_chance.effect)*(level("gem_chance")+extra),0.0,1.0)

## Total shared boss probability, including the existing base exactly once. Upgrade previews use
## extra=1. For a specific boss, gem_chance(group) additionally includes that type's achievements.
func boss_gem_chance(extra: int=0) -> float:
    return clampf(gem_base_chance()+float(catalog.upgrades.boss_gem_chance.effect)*(level("boss_gem_chance")+extra),0.0,1.0)

## Gems paid by one successful Gem roll; the chance is gem_chance(). The single authoritative payout:
## _reward() grants it and every display reads it. Change 10: a boss pays boss_amount_multiplier (3)
## times the normal amount under the same Gem Amount upgrades, then adds its boss-only Boss Gem Amount
## levels (never tripled), and the boss Gem card scales the boss total.
func gem_amount(extra: int=0,group: int=-1) -> float:
    var normal_amount:=1.0+float(catalog.upgrades.gem_amount.effect)*(level("gem_amount")+extra)
    if group<0 or not catalog.groups[group].boss:return normal_amount
    return _boss_payout(normal_amount,0)

## Boss payout per successful roll with `extra` more Boss Gem Amount levels (same for every boss).
func boss_gem_amount(extra: int=0) -> float:
    return _boss_payout(gem_amount(),extra)

func _boss_payout(normal_amount: float,extra: int) -> float:
    var tripled:=float(catalog.progression.gem_limits.boss_amount_multiplier)*normal_amount
    return (tripled+float(catalog.upgrades.boss_gem_amount.effect)*(level("boss_gem_amount")+extra))*(1+campaign.bonus("boss_gems"))

# ---------------------------------------------------------------- Change 17 systems API
## Skill power is a family curve, independent of legacy tier and spare-copy stock. Merge Wisdom
## accelerates progress along the existing merge curve; every family stops at its authored endpoint.
func skill_base_power(id: String, at_merge: int=-1) -> float:
    var key: String=catalog.items[id].skill
    var pair: Array=catalog.progression.change17.skill_curve[key]
    var m:=int(state.items.get(id,{}).get("merge",0)) if at_merge<0 else at_merge
    var end:=int(catalog.progression.change17.skill_curve_end)
    var progress:=clampf(merge_levels(id,m)*card("merge")/merge_levels(id,end),0.0,1.0)
    return lerpf(float(pair[0]),float(pair[1]),progress)

func skill_power(id: String) -> float:
    var key: String=catalog.items[id].skill
    var power:=skill_base_power(id)*(1+campaign.bonus("skill"))
    if key=="fire":power=minf(power,float(catalog.progression.change17.fire_effective_cap))
    if key=="heal":power=minf(power,float(catalog.skills.heal.player_hp_cap))*stats().hp
    return power

func automatic_skill_capacity() -> int:
    # Legacy keys are tolerated in in-memory fixtures; normalization folds them once on load.
    var n:=level("skill_auto_slots")
    for i in range(3):n+=level("skill_auto_"+str(i))
    return mini(3,n)

func automatic_skill_assignments() -> Array:
    var selected: Array=[]
    for i in range(mini(3,1+level("skill_slots"))):
        if state.skill_auto[i] and selected.size()<automatic_skill_capacity():selected.append(i)
    return selected

## Atomic replacement; zero-based equipped slot indices, unique, inside owned capacity.
func assign_automatic_skills(slots_: Array) -> bool:
    if not action_lock_reason().is_empty() or slots_.size()>automatic_skill_capacity():return false
    var selected: Array=[]
    for value in slots_:
        if not (value is int or value is float) or not is_finite(float(value)) or float(value)!=floorf(float(value)):return false
        var slot:=int(value)
        if slot<0 or slot>=1+level("skill_slots") or selected.has(slot) or state.skills[slot]=="":return false
        selected.append(slot)
    state.skill_auto=[selected.has(0),selected.has(1),selected.has(2)]
    touch();skill_automation_changed.emit()
    return true

## A partially expiring slow only affects its part of this step. Called before status timers tick.
func attack_rate(a: Dictionary,dt: float) -> float:
    var left:=float(a.get("attack_slow",0))
    if left<=0 or dt<=0:return 1.0
    return 1.0-(1.0-float(a.get("attack_rate",1.0)))*minf(left,dt)/dt

## Read-only copies for countdown presentation; coordinates are authored spawn homes, not corpses.
func boss_respawn_countdowns(stage_id: int=-1) -> Array:
    var result: Array=[]
    for id in state.boss_respawns:
        var entry: Dictionary=state.boss_respawns[id]
        if stage_id<0 or int(entry.stage)==stage_id:
            var row:=entry.duplicate(true);row["actor_id"]=id
            row["position"]=Vector2(row.x,row.y);result.append(row)
    return result

## Active pausable seconds on every map. Offline time is settled once at restore/resume.
func tick_boss_respawns(seconds: float) -> void:
    for id in state.boss_respawns.keys():
        var entry: Dictionary=state.boss_respawns[id]
        entry.remaining=maxf(0,float(entry.remaining)-maxf(0,seconds))
        var actors: Array=state.enemies if int(entry.stage)==int(state.stage) else state.stage_worlds.get(str(entry.stage),{}).get("enemies",[])
        for a in actors:
            if a.id==id and a.hp<=0:a.respawn=entry.remaining
        if entry.remaining<=0:
            state.boss_respawns.erase(id);boss_respawns_changed.emit()

func settle_boss_respawns(now: float=-1) -> void:
    if now<0:now=Time.get_unix_time_from_system()
    var saved:=float(state.boss_saved_at)
    if saved>0:tick_boss_respawns(maxf(0,now-saved))
    state.boss_saved_at=now
