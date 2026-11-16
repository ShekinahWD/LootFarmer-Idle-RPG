extends Node
## Change 87 focused checks: boss first-kill equipment guarantee and Champion's Spoils x3 (real main scene and
## simulation; state set directly is labelled "fixture"). Boss defeats go through sim._reward + campaign.killed,
## the same pair _kill runs. No combat ladders, balance sweeps or player profiles.
## 1. Every boss drops equipment from its own pool on its first defeat this run (with and without Spoils).
## 2. Natural multi-item drops stay possible on that defeat.
## 3. Champion's Spoils: 3 copies of each equipment drop (6 for two different items); never other loot.
## 4. Bosses are independent; 5. later defeats are normal (no guarantee, no copies).
## 6. Prestige resets eligibility and keeps the card; 7. save/load neither duplicates nor wrongly consumes.
## Plus: boss attributes added once for the 3-copy pile, Auto-Collect takes the whole pile, card text/headline.
## Run: Godot --headless --path . res://tests/change_87_probe.tscn -- --probe --profile=probe-c87 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(300.0,true,false,true).timeout.connect(func():push_error("CHANGE_87 watchdog");get_tree().quit(2))
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(540,960)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    card_checks()
    guarantee_checks()
    spoils_checks()
    independence_checks()
    compatibility_checks()
    prestige_checks()
    await save_checks()
    print("CHANGE_87_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 or checks==0 else 0)

func fresh(cards: Array=[]) -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    sim.state.owned_cards=cards.duplicate();sim.touch()

func bosses() -> Array:
    var out: Array=[]
    for g in sim.catalog.groups.size():
        if bool(sim.catalog.groups[g].boss):out.append(g)
    return out
func pool(g: int) -> Array:
    return (sim.catalog.groups[g].loot as Array).filter(func(id):return str(sim.catalog.items[id].kind) in ["weapon","outfit"])
## One rewarded boss defeat (what _kill does after its bookkeeping); returns this defeat's pickups.
func defeat(g: int) -> Array:
    var start: int=sim.state.pickups.size()
    var a:={"id":"g%d_v2_0" % g,"group":g,"variant":2,"x":200.0,"y":200.0}
    sim._reward(a);sim.campaign.killed(a)
    return sim.state.pickups.slice(start)
func gear_of(drops: Array,g: int) -> Array:
    return drops.filter(func(p):return pool(g).has(str(p.item)))
func copies(drops: Array) -> int:
    var n:=0
    for p in drops:n+=int(p.get("qty",1))
    return n
## Fixture: natural boss gear chance forced to `chance` for this group (0 = only the guarantee can drop gear).
func force_chance(g: int,chance: float) -> void:
    sim.state.upgrades["loot:%d" % g]=0
    sim.catalog.groups[g].gear_chance=chance

# ---------------------------------------------------------------- card
func card_checks() -> void:
    print("-- Card")
    var d: Dictionary=sim.catalog.campaign.cards.trophy_c4
    check(str(d.effect)=="champions_spoils" and is_equal_approx(float(d.value),3.0),"Champion's Spoils value is 3 copies")
    check(load("res://scripts/game/prestige_card.gd").headline(d)=="×3","Card headline reads ×3")
    var text: String=tr(str(d.description_key))
    check(text.contains("3 copies") and not text.contains("twice"),"English description names 3 copies (%s)" % text)
    fresh();check(sim.spoils_copies()==1,"No card: 1 copy")
    fresh(["trophy_c4"]);check(sim.spoils_copies()==3,"Card owned: 3 copies")

# ---------------------------------------------------------------- 1, 2, 5: guarantee
func guarantee_checks() -> void:
    print("-- First-kill guarantee")
    var saved: Dictionary={}
    for g in bosses():saved[g]=float(sim.catalog.groups[g].gear_chance)
    for cards in [[],["trophy_c4"]]:
        fresh(cards)
        for g in bosses():
            force_chance(g,0.0) # fixture: no natural gear, so only the guarantee can supply it
            var drops:=defeat(g)
            var gear:=gear_of(drops,g)
            check(gear.size()==1 and drops.all(func(p):return str(sim.catalog.items[p.item].kind)!="weapon" or pool(g).has(str(p.item)) or str(p.item)==str(sim.catalog.groups[g].get("weapon",""))),"%s first defeat (cards %s): exactly one guaranteed item from its pool (%s)" % [sim.catalog.groups[g].id,cards,gear.map(func(p):return p.item)])
            check(copies(gear)==(3 if cards.size()>0 else 1),"…as %d copies" % (3 if cards.size()>0 else 1))
            var again:=gear_of(defeat(g),g)
            check(again.is_empty(),"%s second defeat: no guarantee, no gear at 0%% chance" % sim.catalog.groups[g].id)
    # Natural drops: at 100% both pool items drop (multi-item) and no extra guaranteed item is added.
    fresh()
    var snow: int=sim.campaign.group_id("boss-snowman")
    force_chance(snow,1.0)
    var drops:=gear_of(defeat(snow),snow)
    check(drops.size()==pool(snow).size() and copies(drops)==pool(snow).size(),"Natural roll at 100%%: both different items drop, no extra guarantee (%s)" % [drops.map(func(p):return p.item)])
    # Later defeats: normal probability (statistical, 50% fixture chance).
    fresh()
    force_chance(snow,.5)
    defeat(snow)
    var total:=0;var hits:=0
    for i in range(400):
        var gear:=gear_of(defeat(snow),snow);total+=pool(snow).size();hits+=gear.size()
        if copies(gear)!=gear.size():hits=-99999
    check(hits>int(total*.4) and hits<int(total*.6),"Later defeats roll the normal chance, single copies (%d of %d at 50%%)" % [hits,total])
    for g in saved:sim.catalog.groups[g].gear_chance=saved[g]

# ---------------------------------------------------------------- 3: Spoils copies
func spoils_checks() -> void:
    print("-- Champion's Spoils x3")
    var snow: int=sim.campaign.group_id("boss-snowman")
    var keep: float=float(sim.catalog.groups[snow].gear_chance)
    fresh(["trophy_c4"])
    force_chance(snow,1.0)
    var drops:=defeat(snow)
    var gear:=gear_of(drops,snow)
    check(gear.size()==2 and gear.all(func(p):return int(p.qty)==3) and copies(gear)==6,"Two different items drop: 3 copies of each, 6 total (%s)" % [gear.map(func(p):return "%s x%d" % [p.item,p.qty])])
    check(drops.filter(func(p):return not pool(snow).has(str(p.item))).all(func(p):return int(p.get("qty",1))==1),"Supplies and skills from the same defeat stay single")
    var later:=gear_of(defeat(snow),snow)
    check(later.size()==2 and copies(later)==2,"The bonus is consumed: the second defeat drops single copies")
    sim.catalog.groups[snow].gear_chance=keep
    # Probabilities unchanged by the card: the natural roll count matches with and without it.
    var with_card:=natural_rate(["trophy_c4"],snow);var without:=natural_rate([],snow)
    check(absi(with_card-without)<=40,"First-defeat natural drop counts match with and without the card (%d vs %d of 400)" % [with_card,without])

## How many of 400 first defeats (fresh run each, fixed seed) dropped 2 natural items at 50%.
func natural_rate(cards: Array,g: int) -> int:
    var keep: float=float(sim.catalog.groups[g].gear_chance)
    var n:=0
    sim.rng.seed=87
    for i in range(400):
        sim.state.owned_cards=cards.duplicate();sim.state.run_kills.erase(str(sim.catalog.groups[g].id))
        sim.state.pickups=[];force_chance(g,.5)
        if gear_of(defeat(g),g).size()==2:n+=1
    sim.catalog.groups[g].gear_chance=keep
    return n

# ---------------------------------------------------------------- 4: independence
func independence_checks() -> void:
    print("-- Independent bosses")
    fresh(["trophy_c4"])
    var snow: int=sim.campaign.group_id("boss-snowman");var robot: int=sim.campaign.group_id("boss-cyan-robot")
    var saved:=[float(sim.catalog.groups[snow].gear_chance),float(sim.catalog.groups[robot].gear_chance)]
    force_chance(snow,0.0);force_chance(robot,0.0)
    check(copies(gear_of(defeat(snow),snow))==3,"Snowman first defeat: 3 copies")
    check(gear_of(defeat(snow),snow).is_empty(),"Snowman second defeat: nothing extra")
    check(copies(gear_of(defeat(robot),robot))==3,"Cyan Robot still eligible after the Snowman: 3 copies")
    sim.catalog.groups[snow].gear_chance=saved[0];sim.catalog.groups[robot].gear_chance=saved[1]

# ---------------------------------------------------------------- compatibility
func compatibility_checks() -> void:
    print("-- Stacks, boss attributes, Auto-Collect")
    fresh(["trophy_c4"])
    var snow: int=sim.campaign.group_id("boss-snowman")
    var keep: float=float(sim.catalog.groups[snow].gear_chance)
    force_chance(snow,0.0)
    var gear:=gear_of(defeat(snow),snow)
    var p: Dictionary=gear[0];var id:=str(p.item)
    check(bool(p.get("enhanced",false)),"The 3-copy boss pile keeps its boss-origin mark")
    check(sim.collect(int(p.uid)) and sim.quantity(id)==3,"Collecting the pile adds all 3 copies to one stack")
    check(sim.boss_extras(id).size()==2,"Boss bonus attributes added once (2 slots, %d)" % sim.boss_extras(id).size())
    var extras: Array=sim.boss_extras(id).duplicate(true)
    sim.state.pickups.append({"uid":9001,"item":id,"qty":3,"x":200.0,"y":200.0,"ttl":300.0,"group":snow,"enhanced":true}) # fixture: a second boss pile of the same id
    check(sim.collect(9001) and sim.quantity(id)==6 and sim.boss_extras(id)==extras,"A later enhanced pile adds copies without re-rolling or duplicating attributes")
    check(sim.merge(id) or sim.record(id).merge>0,"The extra copies merge normally")
    # Auto-Collect path (campaign.gd uses sim.collect per drop): the whole pile arrives.
    sim.state.pickups=[];sim.state.run_kills.clear()
    var pile:=gear_of(defeat(snow),snow)
    var before: int=sim.quantity(str(pile[0].item))
    check(sim.collect(int(pile[0].uid)) and sim.quantity(str(pile[0].item))==before+3,"Any collection path that uses collect takes the 3 copies")
    sim.catalog.groups[snow].gear_chance=keep

# ---------------------------------------------------------------- 6: Prestige
func do_prestige() -> bool:
    var g: int=sim.campaign.prestige_unlock_group()
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman") # fixture: found
    if int(sim.state.group_kills[g])<1:sim.state.group_kills[g]=1 # fixture: defeated once
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    sim.state.consumed.erase("hunter_o1")
    if not sim.campaign.begin_prestige():return false
    var guard:=0
    while not sim.state.prestige_batch.is_empty() and guard<40:
        guard+=1
        if not sim.campaign.choose_card(str(sim.campaign.offered_cards()[0])):return false
    return sim.state.prestige_batch.is_empty()

func prestige_checks() -> void:
    print("-- Prestige reset")
    fresh(["trophy_c4"])
    var snow: int=sim.campaign.group_id("boss-snowman")
    var keep: float=float(sim.catalog.groups[snow].gear_chance)
    force_chance(snow,0.0)
    defeat(snow)
    check(gear_of(defeat(snow),snow).is_empty(),"Before Prestige: Snowman bonus consumed")
    check(do_prestige(),"Prestige completes")
    check(sim.state.owned_cards.has("trophy_c4"),"Prestige keeps Champion's Spoils")
    force_chance(snow,0.0)
    check(sim.state.run_kills.is_empty(),"Prestige clears the run's boss defeats (eligibility)")
    var after:=defeat(snow)
    # The Prestige fixture marks the Snowman's lifetime kills as 1, so its Change 27 first-lifetime weapon also
    # drops here: it is equipment from this defeat, so it gets 3 copies as well.
    var piles:=gear_of(after,snow)
    check(not piles.is_empty() and piles.all(func(p):return int(p.qty)==3),"After Prestige: guarantee and x3 available again (%s)" % [after.map(func(p):return "%s x%d" % [p.item,int(p.get("qty",1))])])
    # The fixture's other Prestige card may add gear chance, so the next defeat can drop naturally: single copies.
    check(gear_of(defeat(snow),snow).all(func(p):return int(p.get("qty",1))==1),"…and consumed again by that defeat (single copies next)")
    sim.catalog.groups[snow].gear_chance=keep

# ---------------------------------------------------------------- 7: save/load
func save_checks() -> void:
    print("-- Save and load")
    fresh(["trophy_c4"])
    var snow: int=sim.campaign.group_id("boss-snowman");var robot: int=sim.campaign.group_id("boss-cyan-robot")
    var saved:=[float(sim.catalog.groups[snow].gear_chance),float(sim.catalog.groups[robot].gear_chance)]
    force_chance(snow,0.0);force_chance(robot,0.0)
    var pile:=gear_of(defeat(snow),snow)
    check(SaveService.save_now(),"Disk save after the Snowman's first defeat")
    sim.state.run_kills.clear();sim.state.pickups=[] # fixture: in-memory changes the reload must undo
    SaveService.load_and_apply();await frames(2)
    var ground: Array=sim.state.pickups.filter(func(p):return int(p.uid)==int(pile[0].uid))
    check(ground.size()==1 and int(ground[0].qty)==3,"Reload keeps the one 3-copy pile (not duplicated)")
    force_chance(snow,0.0);force_chance(robot,0.0)
    check(gear_of(defeat(snow),snow).is_empty(),"Reload keeps the Snowman bonus consumed")
    check(copies(gear_of(defeat(robot),robot))==3,"Reload keeps the Cyan Robot eligible (not consumed)")
    sim.catalog.groups[snow].gear_chance=saved[0];sim.catalog.groups[robot].gear_chance=saved[1]
