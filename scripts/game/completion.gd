extends RefCounted
## Change 83: Game Completion, the long-term gamewide goal. 100% needs all four categories, each weighing 25%:
##   mastery - every Map Mastery objective (8 maps x 5 categories, mastery.gd; its own partial progress)
##   cards   - every Prestige card in the catalog owned (campaign.cards; state.owned_cards)
##   player  - every Player upgrade at its cap: the global upgrades of Upgrades (Player, Inventory, Supplies, Gems,
##             Offline), Skill cooldowns, Missions and Camp Reveal Radius, and the map upgrades of all eight maps
##             (Map Details, Reveal Radius)
##   enemy   - every enemy upgrade at its cap, for every enemy type on every map (Rewards, Automation, Research of
##             the Enemy panel, with the same per-type availability rules)
## Excluded from the denominators: upgrades with no ranks (coin_chance, cap 0) and the retired skill_auto_0/1/2
## (replaced by skill_auto_slots). Inside a category each track counts equally: its earned ranks / its cap (a
## partly upgraded track is partial, never complete). A track that has reached its cap once is latched in
## state.completion_maxed (kept by Prestige, cleared by Hard Reset), like Map Mastery's latched objectives, so the
## Coin upgrades a Prestige resets do not take completion back. A save without the field starts from its current
## ranks: nothing is assumed complete. Exactly 100 only when every category is complete; otherwise at most 99.
## Main adventure completed (the Green Alien defeated) and outfit collection are separate and not counted here.
var sim
const CATEGORIES:=["mastery","cards","player","enemy"]
const LEGACY:=["skill_auto_0","skill_auto_1","skill_auto_2"]
const COMPLETE_MARK:="@game"
var _tracks: Array=[]
var _summary: Dictionary={}
var _summary_frame:=-1

func _init(owner) -> void:sim=owner

## Every counted upgrade track as [category, upgrade id, group or stage (-1 global)]. Fixed by the catalog.
func tracks() -> Array:
    if not _tracks.is_empty():return _tracks
    var ups: Dictionary=sim.catalog.upgrades
    for id in ups:
        var d: Dictionary=ups[id]
        if int(d.get("cap",0))<=0 or LEGACY.has(id):continue
        match str(d.get("scope","global")):
            "global":_tracks.append(["player",id,-1])
            "stage":
                for st in range(1,sim.catalog.stages.size()+1):_tracks.append(["player",id,st])
    for g in range(sim.catalog.groups.size()):
        for id in enemy_upgrades(g):_tracks.append(["enemy",id,g])
    return _tracks

## The enemy upgrades a type offers (the Enemy panel's Rewards, Automation and Research lists).
func enemy_upgrades(g: int) -> Array:
    var d: Dictionary=sim.catalog.groups[g]
    var out: Array=["loot","coin_amount","group_xp","supply_drop"]
    if not d.skills.is_empty():out.append("skill_drop")
    out.append_array(["boss_spawn_cooldown","boss_item_rolls"] if d.boss else ["spawn_amount","spawn_cooldown"])
    out.append_array(["collect","collect_range","collect_batch","collect_speed","merge_gear","gear_merge_speed"])
    if not d.boss and not sim.evolvable_drops(g).is_empty():out.append("auto_evolve")
    out.append_array(["reveal_stats","reveal_drops"])
    return out.filter(func(id):return sim.catalog.upgrades.has(id) and int(sim.catalog.upgrades[id].get("cap",0))>0)

static func track_key(id: String,g: int) -> String:
    return id if g<0 else "%s:%d" % [id,g]

func _latched() -> Array:
    var v=sim.state.get("completion_maxed",[])
    return v if v is Array else []

## Earned share of one track (0..1): latched or at its cap = 1.
func track_fraction(id: String,g: int) -> float:
    if _latched().has(track_key(id,g)) or sim.upgrade_maxed(id,g):return 1.0
    return clampf(float(sim.level(id,g))/maxf(1.0,float(sim.catalog.upgrades[id].cap)),0.0,.999)

## {category: {done, total, fraction, complete}} plus "percent" and "complete". Cached per frame for the UI.
func summary() -> Dictionary:
    var frame:=Engine.get_process_frames()
    if frame==_summary_frame and not _summary.is_empty():return _summary
    var out: Dictionary={}
    # Map Mastery: completed objectives / every objective; its progress keeps mastery.gd's own partial values.
    var m=sim.campaign.mastery
    var done:=0
    var total: int=sim.catalog.stages.size()*m.CATEGORIES.size()
    for st in range(1,sim.catalog.stages.size()+1):
        for category in m.CATEGORIES:
            if m.category_complete(st,category):done+=1
    out.mastery=_entry(done,total,m.game_fraction())
    # Prestige cards: owned / every card in the catalog.
    var cards: Dictionary=sim.catalog.campaign.cards
    var owned:=0
    for id in cards:
        if sim.state.get("owned_cards",[]).has(id):owned+=1
    out.cards=_entry(owned,cards.size(),float(owned)/maxf(1.0,cards.size()))
    # Upgrades: maxed tracks / tracks, progress the mean track share.
    for category in ["player","enemy"]:
        var n:=0;var maxed:=0;var sum:=0.0
        for t in tracks():
            if t[0]!=category:continue
            var f:=track_fraction(t[1],t[2])
            n+=1;sum+=f
            if f>=1.0:maxed+=1
        out[category]=_entry(maxed,n,sum/maxf(1.0,n))
    var all:=true
    var overall:=0.0
    for category in CATEGORIES:
        overall+=float(out[category].fraction)/CATEGORIES.size()
        if not out[category].complete:all=false
    out.complete=all
    out.fraction=1.0 if all else minf(overall,.999)
    out.percent=100 if all else mini(99,floori(overall*100.0+.000001))
    _summary=out;_summary_frame=frame
    return out

func _entry(done: int,total: int,fraction: float) -> Dictionary:
    var complete: bool=total>0 and done>=total
    return {"done":done,"total":total,"complete":complete,"fraction":1.0 if complete else clampf(fraction,0.0,.999),
        "percent":100 if complete else mini(99,floori(clampf(fraction,0.0,1.0)*100.0+.000001))}

func percent() -> int:return int(summary().percent)
func complete() -> bool:return bool(summary().complete)

## Latches newly maxed tracks and announces 100% once (never on load: restore passes announce false).
func evaluate(announce:=true) -> void:
    if sim.state.is_empty() or not sim.state.has("completion_maxed"):return
    var latched: Array=_latched()
    var changed:=false
    for t in tracks():
        var key:=track_key(t[1],t[2])
        if not latched.has(key) and sim.upgrade_maxed(t[1],t[2]):latched.append(key);changed=true
    if changed:sim.state.completion_maxed=latched;_summary_frame=-1;sim.touch()
    if not latched.has(COMPLETE_MARK) and summary().complete:
        latched.append(COMPLETE_MARK);sim.state.completion_maxed=latched;sim.touch()
        if announce:
            sim.notice.emit("game_complete_100","")
            sim.milestone.emit("game_complete_100","")
