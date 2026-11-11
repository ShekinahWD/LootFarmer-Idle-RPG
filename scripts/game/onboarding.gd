extends RefCounted
## Change 25: one authority for what the HUD and the panel opener may show (revealed()):
## - Guided: the action-based staged reveal of guided_progress.gd (feature_allowed), unchanged.
## - Basic and None: every ordinary menu is open from the moment the mode is chosen (choose_mode).
##   Opening a menu never grants content: stages, camps, purchases, undiscovered enemies, Prestige
##   resets and Map Mastery rewards keep their normal game rules, and each panel shows its locked state.
## - Before a mode is chosen (the chooser) nothing is shown, except in probe fixtures
##   (--first-run-complete), whose fresh profiles start with every menu recorded as revealed.
## state.onboarding.reveal records the menus opened for the profile (saved, kept by Prestige, cleared
## by Hard Reset); the simulation never refuses an action because of it.
## The early equipment guarantee (Change 15, every mode): the first weapon or outfit within
## OnboardingRules.first_item_kills eligible kills, then a copy that can be merged with it within
## copy_kills more. Natural drops count first; it only adds a drop when nothing suitable came.
## Change 27: the first lifetime defeat of a listed boss (the Snowman) drops the weapon it carries
## (boss_first_kill). Hidden: no copy, banner or effect beyond the ordinary ground drop.
## The guide (tutorial_guide.gd) decides how much each mode explains; this file decides what exists.
var sim
var rules: OnboardingRules=preload("res://resources/game/onboarding_rules.tres")
## The menu systems. "objective" is the Defeat the Snowman objective (the Next Stage chip); "prestige"
## is Prestige, its tracker and banners, and Map Mastery.
const FEATURES:=["missions","enemy","world","upgrades","objective","prestige"]
## tutorial.seen key latched when finding the Snowman has announced the Prestige reset (Basic/None).
const PRESTIGE_ANNOUNCED:="announced:prestige"
## Loot guarantee states (state.onboarding.loot_phase): no equipment yet, one item without a match,
## a matching pair dropped and waiting on the ground, done (a pair owned or merged; never again).
const LOOT_NONE:=0
const LOOT_ONE:=1
const LOOT_PAIR_ON_GROUND:=2
const LOOT_DONE:=3

func _init(owner) -> void:sim=owner

## Fresh profile defaults. Probes of ordinary play start with every menu recorded as revealed
## (--first-run-complete); the onboarding probes run without it.
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
    match str(sim.state.tutorial.mode):
        "guided":return sim.campaign.guided.feature_allowed(feature)
        "basic","none":return true
    return sim.state.get("onboarding",{}).get("reveal",[]).has(feature)

func all_revealed() -> bool:
    for feature in FEATURES:
        if not revealed(feature):return false
    return true

## The chooser's answer (tutorial_guide.choose). Basic and None open every menu at once, silently
## (no ✦, no unlock sound) and start with Large inventory slots; Guided keeps its staged reveal and
## the player's current slot size. Called only on the first choice of a profile (also after Hard
## Reset, which presents the chooser again), never on load or Prestige, so a later size change stays.
func choose_mode(mode: String) -> void:
    sim.state.tutorial.mode=mode
    if mode in ["basic","none"]:
        reveal_all(true)
        for feature in FEATURES:
            if not sim.state.tutorial.seen.has("opened:"+feature):sim.state.tutorial.seen.append("opened:"+feature)
        SettingsState.set_inventory_zoom(2)
    sim.touch()

## Called on the campaign's one-second tick, after each kill and after purchases.
func evaluate() -> void:
    if sim.state.is_empty():return
    # The guarantee ends the moment a pair is owned (picked up or merged), not at the next kill.
    var o: Dictionary=sim.state.onboarding
    if int(o.loot_phase)<LOOT_DONE and loot_state()==LOOT_DONE:
        o.loot_phase=LOOT_DONE;o.loot_kills=0;sim.touch()
    match str(sim.state.tutorial.mode):
        "guided":sim.campaign.guided.next_step()
        "basic","none":_announce_prestige()

## Basic/None: the Prestige menu was open all along; finding the Snowman (a lifetime record, so a
## Prestige never repeats it) reveals its first opportunity, announced once with one banner. The reset
## itself needs the Snowman defeated once (campaign.prestige_gate_reason, Change 61 correction).
func _announce_prestige() -> void:
    var seen: Array=sim.state.tutorial.seen
    if seen.has(PRESTIGE_ANNOUNCED) or not sim.campaign.prestige_unlocked():return
    seen.append(PRESTIGE_ANNOUNCED)
    sim.touch()
    SaveService.mark_committed()
    sim.notice.emit("feature_unlocked","prestige")
    var found:=0
    for id in sim.state.opportunities:
        if not sim.state.consumed.has(id):found+=1
    sim.milestone.emit("prestige_unlocked",str(found))

## Something bought from Player Upgrades: a global upgrade or a supply from the shop.
func player_purchase() -> bool:
    if sim.campaign.counter("supply_buy")>=1:return true
    for key in sim.state.upgrades:
        if not ":" in str(key) and int(sim.state.upgrades[key])>0:return true
    return false

## Records every menu as revealed, silently: the end of Guided, a Basic/None choice, probe fixtures.
func reveal_all(_silent:=true) -> void:
    var reveal: Array=sim.state.onboarding.reveal
    if reveal.size()==FEATURES.size():return
    for feature in FEATURES:
        if not reveal.has(feature):reveal.append(feature)
    sim.touch()
    SaveService.mark_dirty()

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

## Change 27: called for every rewarded kill after its natural rolls. The lifetime kill count
## (state.group_kills: only real defeats raise it, Prestige keeps it, Hard Reset zeroes it) is already
## 1 for the first defeat, so no extra saved marker is needed and a reload can never grant it again.
## The weapon is the boss's own catalog weapon; a natural drop of it on this kill satisfies the rule.
func boss_first_kill(a: Dictionary,def: Dictionary,dropped: Array) -> Array:
    if not def.boss or not rules.first_kill_weapon_bosses.has(str(def.id)):return []
    if int(sim.state.group_kills[int(a.group)])!=1:return []
    var weapon:=str(def.get("weapon",""))
    if weapon=="" or not sim.catalog.items.has(weapon) or dropped.has(weapon):return []
    dropped.append(sim._drop(weapon,a))
    return [weapon]

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
        if str(d.item)==id:n+=int(d.get("qty",1))
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
