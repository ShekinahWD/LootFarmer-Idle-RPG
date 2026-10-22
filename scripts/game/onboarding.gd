extends RefCounted
## Change 15 first-profile progression (Playbook 18.10), the same in every onboarding mode:
## - One reveal table: the features listed in FEATURES appear one after another, each when its
##   demonstrated action has happened (or a player-level backstop is reached), never on a timer.
##   Defeating the Snowman reveals everything left. Reveals are latched in state.onboarding.reveal
##   (saved, kept by Prestige, cleared by Hard Reset). The HUD and the panel opener ask revealed();
##   the simulation never refuses an action because of it.
## - The early equipment guarantee: the first weapon or outfit within OnboardingRules.first_item_kills
##   eligible kills, then a copy that can be merged with it within copy_kills more. Natural drops count
##   first; the guarantee only adds a drop when nothing suitable came, and never changes drop chances.
## The guide (tutorial_guide.gd) decides how much each mode explains; this file decides what exists.
var sim
var rules: OnboardingRules=preload("res://resources/game/onboarding_rules.tres")
## Reveal order. "objective" is the Defeat the Snowman objective (the Next Stage chip); "prestige"
## is Prestige, its tracker and banners, Map Mastery and anything still hidden.
const FEATURES:=["missions","enemy","world","upgrades","objective","prestige"]
## Loot guarantee states (state.onboarding.loot_phase): no equipment yet, one item without a match,
## a matching pair dropped and waiting on the ground, done (a pair owned or merged; never again).
const LOOT_NONE:=0
const LOOT_ONE:=1
const LOOT_PAIR_ON_GROUND:=2
const LOOT_DONE:=3

func _init(owner) -> void:sim=owner

## Fresh profile defaults. Probes of ordinary play start with the progression complete
## (--first-run-complete, Playbook 18.10); the onboarding probes run without it.
func initial() -> Dictionary:
    if BootContext.first_run_complete:
        return {"reveal":FEATURES.duplicate(),"loot_phase":LOOT_DONE,"loot_kills":0}
    return {"reveal":[],"loot_phase":LOOT_NONE,"loot_kills":0}

## With the progression complete (probe fixtures) every menu also counts as opened (no ✦).
func initial_seen() -> Array:
    var seen: Array=[]
    if BootContext.first_run_complete:
        for feature in FEATURES:seen.append("opened:"+feature)
    return seen

func revealed(feature: String) -> bool:
    return sim.state.get("onboarding",{}).get("reveal",[]).has(feature)

func all_revealed() -> bool:
    return sim.state.onboarding.reveal.size()==FEATURES.size()

# ---------------------------------------------------------------- reveal table

## Latch every feature whose turn has come. Called on the campaign's one-second tick, after each kill
## and after purchases; cheap when everything is revealed.
func evaluate() -> void:
    if sim.state.is_empty() or all_revealed():return
    # The Snowman (a lifetime kill, so a Prestige never relocks it) opens everything at once.
    if sim.campaign.prestige_unlocked():
        reveal_all(false)
        return
    # A full equipment row needs Player Upgrades (more slots) at once, whatever came before.
    var full: bool=not sim.state.gear.has("")
    for feature in FEATURES:
        if feature=="prestige" or revealed(feature):continue
        if not (_trigger(feature) or (full and FEATURES.find(feature)<=FEATURES.find("upgrades"))):break
        _reveal(feature,true)

func _trigger(feature: String) -> bool:
    var level:=int(sim.state.player_level)
    match feature:
        "missions":return sim.campaign.counter("merge")>=1 or level>=rules.missions_level
        "enemy":return not sim.state.main_claimed.is_empty() or sim.campaign.counter("mission")>=1 or level>=rules.enemy_level
        "world":return sim.campaign.counter("upgrade")>=1 or level>=rules.world_level
        "upgrades":return sim.campaign.counter("camp")>=1 or level>=rules.upgrades_level
        "objective":return player_purchase() or level>=rules.objective_level
    return false

## Something bought from Player Upgrades: a global upgrade or a supply from the shop.
func player_purchase() -> bool:
    if sim.campaign.counter("supply_buy")>=1:return true
    for key in sim.state.upgrades:
        if not ":" in str(key) and int(sim.state.upgrades[key])>0:return true
    return false

func _reveal(feature: String,announce: bool) -> void:
    sim.state.onboarding.reveal.append(feature)
    sim.touch()
    if announce:sim.notice.emit("feature_unlocked",feature)

## Everything at once: the Snowman's defeat (announced with one Prestige banner) or Settings → Show
## all menus now (silent: the player asked for it).
func reveal_all(silent: bool) -> void:
    if all_revealed():return
    var had_prestige:=revealed("prestige")
    for feature in FEATURES:
        if not revealed(feature):sim.state.onboarding.reveal.append(feature)
    sim.touch()
    SaveService.mark_dirty()
    if silent or had_prestige:return
    sim.notice.emit("feature_unlocked","prestige")
    var found:=0
    for id in sim.state.opportunities:
        if not sim.state.consumed.has(id):found+=1
    sim.milestone.emit("prestige_unlocked",str(found))

# ---------------------------------------------------------------- early equipment guarantee

## Called for every rewarded normal kill after its natural rolls (simulation._reward). Returns the
## items it added to the ground, so the defeated enemy's loot line stays truthful.
func loot_kill(a: Dictionary,def: Dictionary,dropped: Array) -> Array:
    var o: Dictionary=sim.state.onboarding
    if int(o.loot_phase)>=LOOT_DONE or def.boss or def.loot.is_empty():return []
    var now:=loot_state()
    var stored:=int(o.loot_phase)
    if now==LOOT_DONE:
        o.loot_phase=LOOT_DONE;o.loot_kills=0;sim.touch()
        return []
    if now!=stored:
        o.loot_phase=now
        if now>stored:
            # A natural drop advanced the guarantee: this kill starts the next count.
            o.loot_kills=0
            return []
        # Loot the guarantee counted on expired on the ground: replace it on this kill.
        o.loot_kills=_needed(now)-1
    if now==LOOT_PAIR_ON_GROUND:return []
    o.loot_kills=int(o.loot_kills)+1
    if int(o.loot_kills)<_needed(now):return []
    var forced: Array=[]
    if now==LOOT_NONE:
        forced=[_preferred(def.loot)]
    else:
        var copy:=""
        for id in def.loot:
            if _owned_or_ground(id)>0:copy=id;break
        if copy!="":forced=[copy]
        elif sim.state.gear.has(""):
            # This enemy carries nothing the player has: two copies of its own item make the pair,
            # so the guarantee never depends on which Winter I enemy is farmed.
            var own:=_preferred(def.loot)
            forced=[own,own]
        else:
            # No free slot for a new identity: a copy of an owned item stacks without one.
            for id in sim.state.gear:
                if id!="" and sim.catalog.items[id].kind in ["weapon","outfit"]:forced=[id];break
    for id in forced:
        if id!="":dropped.append(sim._drop(id,a))
    o.loot_kills=0
    o.loot_phase=loot_state()
    sim.touch()
    return forced

func _needed(phase: int) -> int:
    return rules.first_item_kills if phase==LOOT_NONE else rules.copy_kills

## Weapon first: the Wood Sword is shared by two Winter I types, so its copy comes from more spots.
func _preferred(loot: Array) -> String:
    for id in loot:
        if sim.catalog.items[id].kind=="weapon":return id
    return str(loot[0]) if not loot.is_empty() else ""

func _ground(id: String) -> int:
    var n:=0
    for d in sim.state.pickups:
        if str(d.item)==id:n+=1
    return n

func _owned_or_ground(id: String) -> int:
    return sim.quantity(id)+_ground(id)

## Where the guarantee stands, from the real inventory and the ground (drops can expire).
func loot_state() -> int:
    var any:=false
    var pair_on_ground:=false
    var ids: Dictionary={}
    for id in sim.state.items:ids[id]=true
    for d in sim.state.pickups:ids[str(d.item)]=true
    for id in ids:
        if not sim.catalog.items.has(id) or sim.catalog.items[id].kind not in ["weapon","outfit"]:continue
        var owned: int=sim.quantity(id)
        # Read the record without creating one (record() would roll extras and move the RNG).
        if owned>=2 or (owned>=1 and int(sim.state.items.get(id,{}).get("merge",0))>0):return LOOT_DONE
        var total: int=owned+_ground(id)
        if total>=1:any=true
        if total>=2:pair_on_ground=true
    if pair_on_ground:return LOOT_PAIR_ON_GROUND
    return LOOT_ONE if any else LOOT_NONE
