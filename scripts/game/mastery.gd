extends RefCounted
## Change 15 Map Mastery: optional, permanent 100% completion per map and for the whole game.
## Every map has the same five categories, derived from the catalog (MasteryRules holds thresholds
## and rewards):
##   explore  - 100% of the map's reachable cells explored once, and every camp owned once (any run)
##   hunt     - every type of the map at its second kill achievement (lifetime kills)
##   research - Reveal Stats and Reveal Drops bought for every type (kept upgrades)
##   collect  - every weapon, outfit and skill the map's enemies drop obtained once (shared items count
##              on every map that drops them)
##   forge    - every outfit the map drops at ^25 once (boss outfits ^5), and one weapon the map drops
##              evolved once (a shared weapon's evolution counts on every map that drops it)
## Run state (exploration, camps, items, merge levels) resets on Prestige, so the best values are
## copied into state.mastery as they happen and only ever rise; completed categories are latched in
## state.mastery.done. Both are kept by Prestige and cleared by Hard Reset. Nothing here gates the
## campaign. Rewards enter campaign.bonus() once, with the Prestige card bonuses.
var sim
var rules: MasteryRules=preload("res://resources/game/mastery_rules.tres")
const CATEGORIES:=["explore","hunt","research","collect","forge"]
var _content: Dictionary={}
var _reward_key:=-1
var _rewards: Dictionary={}

func _init(owner) -> void:sim=owner

static func initial() -> Dictionary:
    return {"explored":{},"camps":{},"found":{},"merge":{},"evolved":{},"done":[]}

func data() -> Dictionary:
    return sim.state.mastery

# ---------------------------------------------------------------- map content (from the catalog)

## The types, items and evolution candidates of one map, read once from the catalog.
func content(st: int) -> Dictionary:
    if _content.has(st):return _content[st]
    var groups: Array=sim.catalog.stages[st-1].groups
    var items: Array=[];var outfits: Array=[];var weapons: Array=[]
    for g in groups:
        var d: Dictionary=sim.catalog.groups[g]
        for id in d.loot:
            if not items.has(id):items.append(id)
            var kind: String=sim.catalog.items[id].kind
            if kind=="outfit" and not outfits.has(id):outfits.append(id)
            elif kind=="weapon" and not weapons.has(id):weapons.append(id)
        for family in d.skills:
            var skill:="skill_"+str(family)
            if not items.has(skill):items.append(skill)
    var boss_outfits: Dictionary={}
    for g in groups:
        if sim.catalog.groups[g].boss:
            for id in sim.catalog.groups[g].loot:
                if sim.catalog.items[id].kind=="outfit":boss_outfits[id]=true
    _content[st]={"groups":groups,"items":items,"outfits":outfits,"weapons":weapons,"boss_outfits":boss_outfits}
    return _content[st]

func outfit_target(st: int,id: String) -> int:
    return rules.boss_outfit_merge if content(st).boss_outfits.has(id) else rules.normal_outfit_merge

func hunt_target(g: int) -> int:
    var thresholds: Array=sim.achievement_thresholds(g)
    return int(thresholds[clampi(rules.hunt_milestone-1,0,thresholds.size()-1)])

# ---------------------------------------------------------------- permanent records

## An item obtained by any means (drop, offline, evolution, shop): weapons, outfits and skills.
func record_found(id: String) -> void:
    if sim.state.is_empty() or not sim.state.has("mastery") or not sim.catalog.items.has(id):return
    if sim.catalog.items[id].kind=="consumable" or data().found.has(id):return
    data().found[id]=true

func record_evolved(source: String) -> void:
    if sim.catalog.items.has(source) and sim.catalog.items[source].kind=="weapon":data().evolved[source]=true

## Copies the run's best values into the permanent records (they only ever rise).
func refresh_records() -> void:
    var m: Dictionary=data()
    for id in sim.state.items:
        var r: Dictionary=sim.state.items[id]
        if sim.catalog.items[id].kind=="consumable":continue
        if int(r.qty)>0:m.found[id]=true
        if int(r.merge)>int(m.merge.get(id,0)):m.merge[id]=int(r.merge)
    for st in range(1,int(sim.state.unlocked_stage)+1):
        var key:=str(st)
        var pct: int=sim.campaign.explored_percent(st)
        if pct>int(m.explored.get(key,0)):m.explored[key]=pct
        var owned: Array=m.camps.get(key,[])
        for camp in sim.state.camps.get(key,[0]):
            if not owned.has(int(camp)):owned.append(int(camp))
        owned.sort()
        m.camps[key]=owned

# ---------------------------------------------------------------- objectives

## One category of one map: {done, total, fraction, complete, parts}. parts lists every requirement
## as [kind, id, current, target] so the panel can show what remains.
func objective(st: int,category: String) -> Dictionary:
    var m: Dictionary=data()
    var c: Dictionary=content(st)
    var parts: Array=[]
    match category:
        "explore":
            var camps: int=sim.catalog.stages[st-1].spawns.size()
            parts.append(["explored","",mini(100,int(m.explored.get(str(st),0))),100])
            for i in range(camps):parts.append(["camp",str(i),1 if m.camps.get(str(st),[]).has(i) else 0,1])
        "hunt":
            for g in c.groups:parts.append(["kills",str(g),mini(int(sim.state.group_kills[g]),hunt_target(g)),hunt_target(g)])
        "research":
            for g in c.groups:
                parts.append(["stats",str(g),mini(1,sim.level("reveal_stats",g)),1])
                parts.append(["drops",str(g),mini(1,sim.level("reveal_drops",g)),1])
        "collect":
            for id in c.items:parts.append(["item",id,1 if m.found.has(id) else 0,1])
        "forge":
            for id in c.outfits:parts.append(["merge",id,mini(int(m.merge.get(id,0)),outfit_target(st,id)),outfit_target(st,id)])
            # Change 51: a map whose weapons are all final tier (Spring I and II: Obsidian) cannot ask for
            # an evolution; it asks for one of its weapons at the evolution requirement (^20) instead.
            if c.weapons.any(func(id):return str(sim.catalog.items[id].next)!=""):
                var evolved:=0
                for id in c.weapons:
                    if m.evolved.has(id):evolved=1
                parts.append(["evolve","",evolved,1])
            else:
                var need:=int(sim.catalog.progression.evolution.required_merge)
                var best:=0
                for id in c.weapons:best=maxi(best,int(m.merge.get(id,0)))
                parts.append(["weapon_merge","",mini(best,need),need])
    var done:=0;var fraction:=0.0
    for p in parts:
        if int(p[2])>=int(p[3]):done+=1
    if category=="explore":
        # Half the category is the explored share, half the camps.
        var camp_parts: int=parts.size()-1
        var camps_done:=done-(1 if int(parts[0][2])>=100 else 0)
        fraction=.5*float(parts[0][2])/100.0+.5*(float(camps_done)/maxf(1,camp_parts))
    else:fraction=float(done)/maxf(1,parts.size())
    var complete:=done==parts.size()
    return {"done":done,"total":parts.size(),"fraction":1.0 if complete else minf(fraction,.999),"complete":complete or data().done.has("%d:%s" % [st,category]),"parts":parts}

func category_complete(st: int,category: String) -> bool:
    return data().done.has("%d:%s" % [st,category])

func map_complete(st: int) -> bool:
    return data().done.has("map:%d" % st)

func game_complete() -> bool:
    return data().done.has("game")

## Whole percent of a map, rounded down; exactly 100 only when every category is complete.
func map_fraction(st: int) -> float:
    if map_complete(st):return 1.0
    var total:=0.0
    for category in CATEGORIES:
        total+=1.0 if category_complete(st,category) else float(objective(st,category).fraction)
    return minf(total/CATEGORIES.size(),.999)

func map_percent(st: int) -> int:
    return 100 if map_complete(st) else mini(99,floori(map_fraction(st)*100.0+.000001))

func game_fraction() -> float:
    if game_complete():return 1.0
    var total:=0.0
    for st in range(1,sim.catalog.stages.size()+1):total+=map_fraction(st)
    return minf(total/sim.catalog.stages.size(),.999)

func game_percent() -> int:
    return 100 if game_complete() else mini(99,floori(game_fraction()*100.0+.000001))

## Latches newly completed categories, maps and the whole game, and announces each once (never on
## load: restore calls this with announce false, and a latched entry is never announced again).
func evaluate(announce:=true) -> void:
    if sim.state.is_empty() or not sim.state.has("mastery"):return
    refresh_records()
    var done: Array=data().done
    var changed:=false
    for st in range(1,sim.catalog.stages.size()+1):
        var all:=true
        for category in CATEGORIES:
            var key:="%d:%s" % [st,category]
            if not done.has(key):
                if objective(st,category).complete:
                    done.append(key);changed=true
                    if announce:sim.notice.emit("mastery_objective",key)
                else:all=false
        if all and not done.has("map:%d" % st):
            done.append("map:%d" % st);changed=true
            if announce:
                sim.notice.emit("mastery_map",str(st))
                sim.milestone.emit("mastery_map",str(st))
    var maps:=0
    for st in range(1,sim.catalog.stages.size()+1):
        if done.has("map:%d" % st):maps+=1
    if maps==sim.catalog.stages.size() and not done.has("game"):
        done.append("game");changed=true
        if announce:
            sim.notice.emit("game_complete","")
            sim.milestone.emit("mastery_game","")
    if changed:
        _reward_key=-1
        sim.touch()

# ---------------------------------------------------------------- rewards

## Permanent reward totals by bonus key, from the mastered maps and the completion reward.
func rewards() -> Dictionary:
    if sim.state.is_empty() or not sim.state.has("mastery"):return {}
    var done: Array=data().done
    if _reward_key==done.size():return _rewards
    var totals: Dictionary={}
    for st in range(1,mini(sim.catalog.stages.size(),rules.map_rewards.size())+1):
        if done.has("map:%d" % st):
            for key in rules.map_rewards[st-1]:totals[key]=float(totals.get(key,0.0))+float(rules.map_rewards[st-1][key])
    if done.has("game"):
        for key in rules.completion_reward:totals[key]=float(totals.get(key,0.0))+float(rules.completion_reward[key])
    _rewards=totals;_reward_key=done.size()
    return totals

func bonus(key: String) -> float:
    return float(rewards().get(key,0.0))

## Forget cached reward totals (a new or restored profile).
func reset_cache() -> void:
    _reward_key=-1;_rewards={}
