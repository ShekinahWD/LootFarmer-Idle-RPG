extends Node
## Change 80 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## 1. Spring I / Spring II base kill XP (exact table), stages 1-6 and the Spring I bosses unchanged, the XP
##    requirement ceil(12 x level^1.35) unchanged, multipliers unchanged, a real kill grants group_xp, and a
##    Spring II boss kill never jumps many levels at Spring II levels.
## 2. Critical Damage: base 110%, +5 points per upgrade level (flat), Hard Hit (challenge_c3) +40 points; the
##    level 0/1/5/10/20 table with and without the card, equipment extras on top, real critical hits, prices
##    unchanged, persistence through save/reload and Prestige.
## 3. Camp Supplies (regional_c3): 3 random supplies per owned camp, then a 10-minute active-play cooldown per
##    camp; no backpay, independent camps, partial batches with a full inventory, save/reload, Prestige keeps
##    the cooldowns, Hard Reset clears them, Change 77/79 saves migrate. Supersedes change_77_probe (whose
##    once-per-run rule this change replaces); every still-valid check of it is ported here.
## 4. Stage selector: campaign.stage_progress()/next_stage_to_unlock() and the World panel's 01-08 list.
## Run: Godot --headless --path . res://tests/change_80_probe.tscn -- --probe --profile=probe-c80 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim
var granted: Array=[]
var owed_reports: Array=[]
var waits:=0

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func near(a: float,b: float,eps:=1e-6) -> bool:return absf(a-b)<=eps
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(900.0,true,false,true).timeout.connect(func():push_error("CHANGE_80 watchdog");get_tree().quit(2))
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(720,1280)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.camp_supply_granted.connect(func(ids: Array,owed: int)->void:granted.append_array(ids);owed_reports.append(owed))
    sim.camp_supply_waiting.connect(func()->void:waits+=1)
    await frames(6)
    xp_checks()
    await crit_checks()
    camp_card_checks()
    camp_visit_checks()
    camp_cooldown_checks()
    camp_real_step_checks()
    camp_inventory_checks()
    await camp_persistence_checks()
    camp_prestige_checks()
    await camp_hard_reset_checks()
    await camp_migration_checks()
    camp_normalize_checks()
    await camp_ui_checks()
    stage_state_checks()
    await stage_ui_checks()
    print("CHANGE_80_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func fresh(card:=true) -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_important.clear();game.get_node("Toast").hide();game.toast_time=0.0
    if card:sim.state.owned_cards.append("regional_c3") # fixture: card owned
    granted.clear();owed_reports.clear();waits=0

func gi(id: String) -> int:
    for g in range(sim.catalog.groups.size()):
        if sim.catalog.groups[g].id==id:return g
    return -1

# ================================================================ 1. XP
const XP_AFTER:={"unit-bunny-ears":500,"unit-cat-ears":650,"unit-elf-ears":850,"unit-flower-crown":1050,"unit-green-cap":1250,"unit-pink-cap":1500,
    "unit-pink-flower-hood":1800,"unit-plain":2150,"unit-sprout":2550,"boss-bee":20000,"boss-orange-tabby-cat":23750,"boss-red-panda":30000,"boss-sunflower":35000,"boss-green-alien":45000}
## Stages 1-6 as shipped before Change 80 (must not move).
const XP_EARLY:={"unit-blue-cap":3,"unit-red-scarf":4,"unit-chef-hat":4,"boss-snowman":40,"unit-wolf-hood":4,"unit-calico-cat-hood":5,"unit-golden-crown":5,
    "unit-reindeer-antlers":5,"unit-santa-hat":5,"unit-space-helmet":6,"boss-cyan-robot":60,"unit-straw-hat":7,"unit-sunglasses":8,"unit-yellow-cap":9,"boss-gray-cat":100,
    "unit-cowboy-bandana":11,"unit-duck-swim-ring":12,"unit-rainbow-clown":14,"unit-red-cap-swimmer":15,"unit-snorkeler":16,"unit-straw-hat-swimmer":18,"boss-elephant":230,
    "boss-teal-dinosaur":280,"unit-black-cap":28,"unit-mushroom-cap":35,"unit-pumpkin-head":46,"boss-squirrel":650,"boss-red-fox":770,"unit-horned-hood":77,
    "unit-orange-screen-helmet":101,"unit-television-head":137,"unit-top-hat":180,"boss-black-cat":3020,"boss-grim-reaper":3580}

func xp_checks() -> void:
    print("-- 1. Spring XP")
    fresh(false)
    var exact:=true;var bad: Array=[]
    for id in XP_AFTER:
        var g:=gi(id)
        if g<0 or not near(float(sim.catalog.groups[g].xp),float(XP_AFTER[id])):exact=false;bad.append(id)
    check(exact,"Spring I / Spring II base XP match the approved table (%s)" % [bad])
    var early:=true
    for id in XP_EARLY:early=early and gi(id)>=0 and near(float(sim.catalog.groups[gi(id)].xp),float(XP_EARLY[id]))
    check(early,"Every stage 1-6 enemy and boss keeps its XP")
    var listed:=0
    for g in sim.catalog.groups:
        if int(g.stage)>=7:listed+=1
    check(listed==XP_AFTER.size(),"The table covers every Spring I / II type (%d)" % listed)
    var normals: Array=["unit-bunny-ears","unit-cat-ears","unit-elf-ears","unit-flower-crown","unit-green-cap","unit-pink-cap","unit-pink-flower-hood","unit-plain","unit-sprout"]
    var smooth:=true
    for i in range(1,normals.size()):
        var r: float=float(XP_AFTER[normals[i]])/float(XP_AFTER[normals[i-1]])
        smooth=smooth and r>1.0 and r<=1.35
    check(smooth,"Normal XP rises at every step by at most 35% (old Spring II steps were x1.41 and x2.81)")
    # Change 81 lowered the cap to 500 (change_81_probe); the requirement formula is unchanged.
    check(int(sim.catalog.progression.max_level)==500 and near(float(sim.catalog.progression.xp_base),12.0) and near(float(sim.catalog.progression.xp_growth),1.35),"XP requirement data unchanged (12 x level^1.35, cap 500 since Change 81)")
    var formula:=true
    for l in [1,2,10,63,137,190,235,500]:formula=formula and near(sim.xp_required(l),ceilf(12.0*pow(l,1.35)))
    check(formula,"xp_required(level) == ceil(12 x level^1.35) at 1, 2, 10, 63, 137, 190, 235, 500")
    # Multipliers keep working on the new base values.
    var bunny:=gi("unit-bunny-ears")
    check(near(sim.group_xp(bunny),500.0),"No upgrades: a Bunny Ears kill is worth 500 XP")
    sim.state.upgrades["group_xp:%d" % bunny]=3 # fixture: 3 XP upgrade levels on the type
    check(near(sim.group_xp(bunny),650.0,1e-3),"3 XP upgrade levels: 500 x 1.3 = 650")
    sim.state.upgrades.erase("group_xp:%d" % bunny)
    check(near(sim.group_xp(bunny,0),500.0) and near(sim.group_xp(bunny,1),500.0) and near(sim.group_xp(bunny,3),500.0),"Every variant uses the type's base XP")
    # A real kill pays group_xp.
    sim.state.unlocked_stage=8;sim.state.stage=8;sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II reached
    sim.state.player_level=1;sim.state.xp=0.0
    var sprout:=gi("unit-sprout")
    var enemy: Dictionary={}
    for e in sim.state.enemies:
        if int(e.group)==sprout and int(e.get("variant",2))==2:enemy=e;break
    check(not enemy.is_empty(),"fixture: a Sprout is on the Spring II map")
    if not enemy.is_empty():
        var before: float=xp_total()
        sim._kill(enemy)
        check(near(xp_total()-before,2550.0,1e-3),"A real Sprout kill grants exactly 2,550 XP (%.0f)" % (xp_total()-before))
    # Boss level jump at Spring II levels (one kill, no XP multipliers).
    var jumps: Array=[]
    for pair in [["boss-red-panda",160],["boss-sunflower",170],["boss-green-alien",180],["boss-green-alien",150]]:
        sim.state.player_level=int(pair[1]);sim.state.xp=0.0
        sim.gain_xp(sim.group_xp(gi(pair[0])))
        jumps.append(int(sim.state.player_level)-int(pair[1]))
    # L150 is below a normal Spring II level (fixtures arrive at L192 under the old XP); the final boss there is 4.
    check(jumps.slice(0,3).all(func(j):return j<=3) and int(jumps[3])<=4,"One Spring II boss kill: Red Panda @160 +%d, Sunflower @170 +%d, Green Alien @180 +%d, @150 +%d levels (old: dozens)" % jumps)

func xp_total() -> float:
    var total:=float(sim.state.xp)
    for l in range(1,int(sim.state.player_level)):total+=sim.xp_required(l)
    return total

# ================================================================ 2. Critical Damage
func crit_checks() -> void:
    print("-- 2. Critical Damage")
    fresh(false)
    var up: Dictionary=sim.catalog.upgrades.critical_damage
    check(near(float(up.effect),.05) and int(up.cap)==20 and str(up.currency)=="gems" and int(up.base)==15 and near(float(up.growth),1.25) and bool(up.keep),"Upgrade: +0.05 per level, cap 20, 15 Gems x1.25, kept by Prestige")
    var card: Dictionary=sim.catalog.campaign.cards.challenge_c3
    check(str(card.effect)=="crit_damage" and near(float(card.value),.40) and str(card.path)=="challenge","Hard Hit (challenge_c3): crit_damage +0.40, still on the Challenge path")
    check(sim.upgrade_cost("critical_damage")==15,"Level 1 still costs 15 Gems")
    var expected:={0:[1.10,1.50],1:[1.15,1.55],5:[1.35,1.75],10:[1.60,2.00],15:[1.85,2.25],20:[2.10,2.50]}
    var table:=true;var seen: Array=[]
    for n in expected:
        sim.state.upgrades["critical_damage"]=n # fixture: purchased levels
        sim.state.owned_cards.erase("challenge_c3");sim.touch()
        var plain: float=sim.stats().crit_damage
        sim.state.owned_cards.append("challenge_c3");sim.touch()
        var with_card: float=sim.stats().crit_damage
        seen.append("L%d %.2f/%.2f" % [n,plain,with_card])
        table=table and near(plain,expected[n][0]) and near(with_card,expected[n][1])
    check(table,"110%% + 5 points per level, +40 with the card: %s" % [seen])
    sim.state.owned_cards.erase("challenge_c3")
    sim.state.upgrades["critical_damage"]=10;sim.touch()
    check(near(sim.player_upgrade_value("critical_damage"),.5) and near(sim.stat_sources().SOURCE_UPGRADES.crit_damage,.5),"Upgrade source shows +0.50 at level 10 (flat, not compounded: 1.05^10 would be 1.63)")
    var preview: Dictionary=sim.stats_with_upgrade("critical_damage",1)
    check(near(float(preview.crit_damage),1.65),"Next-level preview: 160%% -> 165%% (%.2f)" % float(preview.crit_damage))
    var text: String=game._critical_benefit("critical_damage",true)
    check(text.contains("165"),"Upgrade row shows the next value 165%%: %s" % text)
    check(tr("CONTENT_CHALLENGE_C3_DESCRIPTION")=="Critical hits deal +40% more damage" and game.PRESTIGE_CARD_SCRIPT.headline(card)=="+40%","Card description and headline say +40%")
    # Equipment extras add on top (additive points, like before).
    sim.state.upgrades["critical_damage"]=0;sim.touch()
    var base: float=sim.stats().crit_damage
    check(sim.add_item("obsidian_sword",1,false,false) and sim.equip("obsidian_sword"),"fixture: a weapon equipped")
    sim.record("obsidian_sword").extras={"crit_damage":.10} # fixture: rolled +10 crit damage extra
    sim.touch()
    check(near(sim.stats().crit_damage-base,.10,1e-4),"A +10 point weapon extra adds 0.10 on top (%.3f -> %.3f)" % [base,sim.stats().crit_damage])
    sim.record("obsidian_sword").extras={};sim.touch()
    # Real critical hits: damage with the card / without, both at 100% chance.
    var ratio:=crit_hit_ratio()
    check(near(ratio,1.75/1.35,1e-3),"Real critical hit at level 5: with the card 175%% / without 135%% (ratio %.4f)" % ratio)
    # Persistence: levels and card survive save/reload and Prestige, and the new effect applies to them.
    fresh(false)
    sim.state.upgrades["critical_damage"]=20;sim.state.owned_cards.append("challenge_c3");sim.touch() # fixture: an existing player's purchases
    check(SaveService.save_now(),"Disk save")
    sim.state.upgrades={};sim.state.owned_cards=[] # fixture: in-memory change the reload must undo
    SaveService.load_and_apply();await frames(2)
    check(sim.level("critical_damage")==20 and sim.state.owned_cards.has("challenge_c3") and near(sim.stats().crit_damage,2.5),"Reload keeps level 20 and the card: 250%% (%.2f)" % sim.stats().crit_damage)
    check(do_prestige(),"Prestige completes")
    check(sim.level("critical_damage")==20 and sim.state.owned_cards.has("challenge_c3") and near(sim.stats().crit_damage,2.5),"After Prestige: level 20 and the card kept, 250%")

func crit_hit_ratio() -> float:
    var hits: Array=[]
    for owned in [true,false]:
        fresh(false)
        sim.state.unlocked_stage=8;sim.state.stage=8;sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II
        sim.state.upgrades["critical_damage"]=5;sim.state.upgrades["critical_chance"]=95 # fixture: 5 levels, 100% chance
        if owned:sim.state.owned_cards.append("challenge_c3")
        sim.state.player_level=300;sim.touch() # fixture: strong enough that the 1-damage floor never applies
        var target: Dictionary={}
        for e in sim.state.enemies:
            if not sim.catalog.groups[int(e.group)].boss:target=e;break
        target.hp=1e12
        var p: Dictionary=sim.state.player
        p.x=float(target.x)-20;p.y=float(target.y);p.target=str(target.id);p.windup=1e-6
        sim._resolve_attack(p,.1)
        hits.append(1e12-float(target.hp))
        if not bool(target.get("critical_hit",false)):return -1.0
    return hits[0]/maxf(1e-9,hits[1])

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

# ================================================================ 3. Camp Supplies
func at_camp(camp: int) -> void:
    var a: Array=sim.campaign.stage().spawns[camp]
    sim.state.player.x=a[0];sim.state.player.y=a[1] # fixture: standing at the camp
func away() -> void:
    sim.state.player.x=float(sim.campaign.stage().size[0])*.5;sim.state.player.y=40.0 # fixture: far from every camp
func supplies_total() -> int:
    var n:=0
    for id in sim.supply_ids():n+=sim.quantity(id)
    return n
func wait_active(seconds: float) -> void:
    sim.state.playtime_total=float(sim.state.playtime_total)+seconds # fixture: active play elsewhere
func give_slots(n: int) -> void:
    for i in range(n-sim.state.supplies.size()):sim.state.supplies.append("") # fixture: bought supply slots

func camp_card_checks() -> void:
    print("-- 3. Camp Supplies: the card")
    fresh()
    var d: Dictionary=sim.catalog.campaign.cards.get("regional_c3",{})
    var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/game/catalog.json")).campaign.cards.get("regional_c3",{})
    check(str(raw.get("path",""))=="regional" and str(raw.get("name",""))=="CONTENT_REGIONAL_C3_NAME" and str(raw.get("description",""))=="CONTENT_REGIONAL_C3_DESCRIPTION","regional_c3 keeps its id, path and string keys")
    check(str(d.effect)=="camp_supplies" and int(d.value)==3 and near(float(d.cooldown),600.0),"camp_supplies: 3 per batch, 600 s per camp")
    check(sim.campaign.camp_supply_batch()==3 and near(sim.campaign.camp_supply_cooldown(),600.0),"Rules read the card: batch 3, cooldown 600 s")
    var set_: Dictionary={}
    for c in sim.catalog.campaign.combos:
        if str(c.id)=="regional_set":set_=c
    check(set_.get("cards",[])==["regional_c1","regional_c2","regional_c3"],"The Regional set still needs regional_c3")
    check(tr("CONTENT_REGIONAL_C3_NAME")=="Camp Supplies","Name: Camp Supplies")
    var line: String=tr("CONTENT_REGIONAL_C3_DESCRIPTION")
    check(line.contains("3") and line.contains("10 minutes") and line.contains("each owned camp") and not line.contains("Prestige"),"Description: %s" % line)
    check(game.PRESTIGE_CARD_SCRIPT.headline(d)=="+3","Headline: %s" % game.PRESTIGE_CARD_SCRIPT.headline(d))

func camp_visit_checks() -> void:
    print("-- Camp Supplies: visits")
    fresh(false)
    give_slots(3)
    at_camp(0)
    check(sim.campaign.camp_supply_step().is_empty() and supplies_total()==0 and sim.state.camp_supply.is_empty(),"Without the card a camp gives nothing and records nothing")
    fresh()
    give_slots(3)
    away()
    check(sim.campaign.camp_supply_step().is_empty() and supplies_total()==0,"Away from every camp: nothing")
    at_camp(0)
    var coins: float=sim.state.coins;var gems: float=sim.state.gems
    var ids: Array=sim.campaign.camp_supply_step()
    var pool_ok:=ids.all(func(id):return id in ["potion","coin_boost"])
    check(ids.size()==3 and supplies_total()==3 and pool_ok,"First visit to Winter I camp 0: 3 random Winter I supplies (%s)" % [ids])
    check(near(sim.state.coins,coins) and near(sim.state.gems,gems),"Free: no Coins or Gems spent")
    var r: Dictionary=sim.state.camp_supply.get("1:0",{})
    check(int(r.get("left",-1))==0 and near(float(r.get("next",0)),float(sim.state.playtime_total)+600.0),"Camp 0 now rests for 600 s of play: %s" % [r])
    check(granted==ids and owed_reports==[0],"One grant notice with the 3 ids, nothing owed")
    for i in range(5):sim.campaign.camp_supply_step()
    away();sim.campaign.camp_supply_step();at_camp(0);sim.campaign.camp_supply_step()
    check(supplies_total()==3 and granted.size()==3,"Staying, leaving and returning during the cooldown give nothing more")
    # An unowned camp is not a visit; a newly bought camp is ready at once.
    sim.state.coins=1e6
    at_camp(1)
    check(sim.campaign.camp_supply_step().is_empty(),"Standing at a camp not owned gives nothing")
    sim.state.camps_known["1"]=[1] # fixture: camp 1 sighted
    check(sim.select_spawn(1),"Winter I camp 1 bought the normal way")
    check(sim.campaign.camp_supply_step().size()==3 and supplies_total()==6,"A different camp gives its own batch")
    # Teleport loops never pay twice.
    check(sim.campaign.camp_action(1,0,true),"Teleport to camp 0")
    sim.campaign.camp_supply_step()
    check(sim.campaign.camp_action(1,1,true),"Teleport to camp 1")
    sim.campaign.camp_supply_step()
    check(supplies_total()==6,"Teleporting between resting camps gives nothing")
    # Death and respawn.
    wait_active(600.0)
    sim.state.player.hp=0.0
    check(sim.campaign.camp_supply_step().is_empty(),"A defeated player is not visiting (even with the camp ready)")
    sim.state.player.hp=sim.stats().hp
    check(sim.campaign.camp_supply_step().size()==3,"Alive again at the ready camp: the batch is given")
    # Another map: its own pool and its own cooldowns.
    sim.state.unlocked_stage=2;sim.state.camps["2"]=[0,1,2] # fixture: Winter II reached, camps owned
    check(sim.campaign.camp_action(2,2,true),"Teleport to Winter II camp 2")
    var w2: Array=sim.campaign.camp_supply_step()
    check(w2.size()==3 and w2.all(func(id):return id in ["potion","coin_boost","guard_tonic"]),"Winter II camp 2 gives 3 from the Winter II pool (%s)" % [w2])
    check(sim.state.camp_supply.has("2:2") and sim.state.camp_supply.has("1:0") and sim.state.camp_supply.has("1:1"),"Per-map, per-camp records: %s" % [sim.state.camp_supply.keys()])
    sim.state.unlocked_stage=1 # fixture: inconsistent reach
    at_camp(0)
    check(sim.campaign.camp_supply_step().is_empty(),"A map beyond this run's reach never rewards")
    sim.state.unlocked_stage=2
    sim.state.prestige_batch={"ids":["x"],"choices":[]} # fixture: a Prestige choice is open
    for i in range(10):sim.step(.05)
    check(sim.state.camp_supply.has("2:2") and int(sim.state.camp_supply["2:2"].left)==0,"Nothing happens while a Prestige choice is open")
    sim.state.prestige_batch={}

func camp_cooldown_checks() -> void:
    print("-- Camp Supplies: cooldowns")
    fresh()
    give_slots(5)
    sim.state.camps["1"].append(1) # fixture: camp 1 owned (state.spawns is this live array)
    at_camp(0);check(sim.campaign.camp_supply_step().size()==3,"Camp 0 batch at t=0")
    wait_active(240.0)
    at_camp(1);check(sim.campaign.camp_supply_step().size()==3,"Camp 1 batch at t=240 (independent of camp 0)")
    check(near(sim.campaign.camp_supply_wait(1,0),360.0) and near(sim.campaign.camp_supply_wait(1,1),600.0),"Waits: camp 0 360 s, camp 1 600 s")
    wait_active(359.0);at_camp(0)
    check(sim.campaign.camp_supply_step().is_empty(),"Camp 0 one second early: nothing")
    wait_active(1.0)
    check(sim.campaign.camp_supply_step().size()==3,"Camp 0 at exactly 600 s: the next batch, without leaving the camp")
    at_camp(1)
    check(sim.campaign.camp_supply_step().is_empty() and near(sim.campaign.camp_supply_wait(1,1),240.0),"Camp 1 still rests 240 s")
    # No backpay: a long absence still gives one batch.
    clear_supplies()
    wait_active(6.0*3600.0)
    at_camp(1)
    var after_long: Array=sim.campaign.camp_supply_step()
    check(after_long.size()==3,"After 6 hours of play away: exactly one batch of 3 (no banked batches)")
    check(sim.campaign.camp_supply_step().is_empty() and near(sim.campaign.camp_supply_wait(1,1),600.0),"…and a fresh 600 s cooldown from the claim")
    # Pause: the clock is active play, so a paused game never advances it.
    var t0: float=float(sim.state.playtime_total)
    get_tree().paused=true
    for i in range(20):sim.step(.1)
    check(near(float(sim.state.playtime_total),t0),"Paused: the cooldown clock does not move")
    get_tree().paused=false
    sim.suspended=true
    for i in range(20):sim.step(.1)
    check(near(float(sim.state.playtime_total),t0),"In the background (suspended): the clock does not move")
    sim.suspended=false
    # Wall-clock changes do not matter.
    sim.clock_override=sim.now_unix()+86400.0*30 # fixture: device clock moved a month ahead
    at_camp(1)
    check(sim.campaign.camp_supply_step().is_empty(),"Moving the device clock ahead does not finish a cooldown")
    sim.clock_override=-1.0

func clear_supplies() -> void:
    for id in sim.supply_ids():
        var q: int=sim.quantity(id)
        if q>0:sim._remove(id,q) # fixture: supplies used up

func camp_real_step_checks() -> void:
    print("-- Camp Supplies: the real simulation step")
    fresh()
    give_slots(3)
    at_camp(0)
    for i in range(20):sim.step(.05)
    check(supplies_total()==3 and sim.state.camp_supply.has("1:0"),"One second of play at the camp gives the batch of 3")
    for i in range(60):sim.step(.05)
    check(supplies_total()==3,"Three more seconds give nothing more")
    check(game.toast_queue.has(tr("CAMP_SUPPLY_BATCH") % 3),"The toast lane says: %s" % [game.toast_queue])
    # Real time passing away from camp (active play), then back: the next batch arrives.
    clear_supplies()
    away()
    var start: float=float(sim.state.playtime_total)
    while float(sim.state.playtime_total)-start<600.5:sim.step(.1)
    sim.state.player.hp=sim.stats().hp
    at_camp(0)
    for i in range(20):sim.step(.05)
    check(supplies_total()==3,"After 600 s of real simulated play elsewhere the camp gives another 3 (%d)" % supplies_total())

func camp_inventory_checks() -> void:
    print("-- Camp Supplies: inventory space")
    fresh()
    check(sim.state.supplies.size()==1,"fixture: the starting inventory has 1 supply slot")
    sim.add_item("guard_tonic",1,false,false) # fixture: the only slot holds a Winter II supply
    at_camp(0)
    check(sim.campaign.camp_supply_pool(1).is_empty(),"No Winter I supply fits")
    check(sim.campaign.camp_supply_step().is_empty() and not sim.state.camp_supply.has("1:0") and sim.quantity("guard_tonic")==1,"Full: nothing given, nothing lost, no cooldown started")
    check(waits==1 and game.toast_queue.has(tr("CAMP_SUPPLY_WAITING")),"One waiting notice")
    for i in range(5):sim.campaign.camp_supply_step()
    check(waits==1,"…not repeated while the player stays")
    sim._remove("guard_tonic",1) # fixture: the player frees the slot
    var got: Array=sim.campaign.camp_supply_step()
    # One free slot: every unit of a stack fits once the slot holds that supply, so all 3 can arrive as one type.
    check(got.size()==3 and supplies_total()==3,"Once a slot is free the same visit gives the batch (%s)" % [got])
    # Partial batches. Supply stacks have no size limit, so once one unit of a supply fits, the rest of the batch
    # fits too: in play a batch is all-or-nothing. The owed-units path (a batch interrupted by a full inventory,
    # or by a future stack limit) is checked from a saved record of 1 of 3 delivered.
    fresh()
    sim.add_item("guard_tonic",1,false,false) # fixture: the only slot holds a non-pool supply
    sim.state.camp_supply["1:0"]={"next":0.0,"left":2} # fixture: 1 of 3 delivered, 2 owed
    at_camp(0)
    check(sim.campaign.camp_supply_owed(1,0)==2 and near(sim.campaign.camp_supply_wait(1,0),0.0),"2 units owed, no cooldown yet")
    check(sim.campaign.camp_supply_step().is_empty() and int(sim.state.camp_supply["1:0"].left)==2 and waits==1,"Still full: nothing given, nothing lost, still 2 owed, one notice")
    sim._remove("guard_tonic",1) # fixture: slot freed
    var rest: Array=sim.campaign.camp_supply_step()
    check(rest.size()==2 and supplies_total()==2 and owed_reports.back()==0,"Space again: exactly the 2 owed units, never a full new batch (%s)" % [rest])
    check(int(sim.state.camp_supply["1:0"].left)==0 and near(sim.campaign.camp_supply_wait(1,0),600.0),"The cooldown starts only when the batch is complete")
    check(sim.campaign.camp_supply_step().is_empty(),"…and nothing more")
    check(game.toast_queue.has(tr("CAMP_SUPPLY_BATCH") % 2),"The notice reports the 2 actually given")
    fresh()
    sim.state.camp_supply["1:0"]={"next":0.0,"left":1} # fixture: 2 of 3 delivered, 1 owed
    at_camp(0)
    var one: Array=sim.campaign.camp_supply_step()
    check(one.size()==1 and game.toast_queue.has(tr("CAMP_SUPPLY_RECEIVED") % sim.catalog.display_name(str(one[0]))),"One unit names its supply: %s" % [game.toast_queue])

func camp_persistence_checks() -> void:
    print("-- Camp Supplies: save and reload")
    fresh()
    give_slots(5)
    sim.state.camps["1"].append(1) # fixture: camp 1 owned
    at_camp(0);sim.campaign.camp_supply_step()
    wait_active(100.0)
    var total:=supplies_total()
    var record: Dictionary=sim.state.camp_supply.duplicate(true)
    check(SaveService.save_now(),"Disk save")
    sim.state.camp_supply={};sim.state.items={} # fixture: in-memory change the reload must undo
    SaveService.load_and_apply();await frames(2)
    check(sim.state.camp_supply==record and supplies_total()==total,"Reload restores the cooldown record and the supplies (no loss, no duplicate)")
    check(near(sim.campaign.camp_supply_wait(1,0),500.0,.5),"Camp 0 still has 500 s to go after reload (%.1f)" % sim.campaign.camp_supply_wait(1,0))
    at_camp(0)
    check(sim.campaign.camp_supply_step().is_empty(),"Reopening at a resting camp gives nothing")
    at_camp(1)
    check(sim.campaign.camp_supply_step().size()==3,"A ready camp still gives its batch after reload")
    var snap: Dictionary=sim.save_snapshot()
    check(snap.camp_supply.has("1:0") and snap.camp_supply.has("1:1") and not snap.has("camp_supplies"),"The save carries both records and no retired camp_supplies list")
    # A partial batch survives a reload exactly.
    sim.state.camp_supply["1:1"]={"next":float(sim.state.playtime_total)+600.0,"left":2} # fixture: 1 of 3 delivered before the app closed
    check(SaveService.save_now(),"Disk save with a partial batch")
    SaveService.load_and_apply();await frames(2)
    check(sim.campaign.camp_supply_owed(1,1)==2,"After reload camp 1 still owes exactly 2")
    clear_supplies()
    at_camp(1)
    check(sim.campaign.camp_supply_step().size()==2 and sim.campaign.camp_supply_owed(1,1)==0,"…and gives exactly 2, then rests")

func camp_prestige_checks() -> void:
    print("-- Camp Supplies: Prestige")
    fresh()
    give_slots(3)
    sim.state.coins=1e7
    sim.state.camps["1"].append(1);sim.state.unlocked_stage=2;sim.state.camps["2"]=[0,2] # fixture: camps owned
    at_camp(0);sim.campaign.camp_supply_step()
    sim.campaign.camp_action(2,2,true);clear_supplies();sim.campaign.camp_supply_step()
    var waits_before:=[sim.campaign.camp_supply_wait(1,0),sim.campaign.camp_supply_wait(2,2)]
    check(waits_before[0]>0 and waits_before[1]>0,"Winter I camp 0 and Winter II camp 2 resting")
    sim.campaign.camp_action(1,0,true)
    check(do_prestige(),"Prestige completes")
    check(sim.state.camp_supply.has("1:0") and sim.state.camp_supply.has("2:2"),"Prestige keeps every camp's cooldown")
    check(near(sim.campaign.camp_supply_wait(1,0),waits_before[0],.5) and near(sim.campaign.camp_supply_wait(2,2),waits_before[1],.5),"…unchanged (the active-play clock is kept)")
    check(sim.state.camps.get("1",[])==[0,1] and sim.state.camps.get("2",[])==[0,2] and int(sim.state.unlocked_stage)==1,"Camps kept, map access back to Winter I")
    sim.state.player.hp=sim.stats().hp
    give_slots(3)
    at_camp(0)
    check(sim.campaign.camp_supply_step().is_empty(),"Prestige does not make a resting camp ready")
    check(sim.campaign.camp_action(1,1,true) and sim.campaign.camp_supply_step().size()==3,"A ready kept camp gives its batch in the new run")
    check(sim.campaign.travel_reason(2,2)=="STAGE_LOCKED","Winter II's camps wait until the map is reached again")
    wait_active(600.0)
    sim.state.stage=2 # fixture: standing on Winter II without having reached it this run
    check(sim.campaign.camp_supply_step().is_empty(),"A late-map camp never gives before its map is reached again")
    sim.state.stage=1

func camp_hard_reset_checks() -> void:
    print("-- Camp Supplies: Hard Reset")
    fresh()
    give_slots(3)
    at_camp(0);sim.campaign.camp_supply_step()
    check(SaveService.hard_reset(),"Hard Reset")
    await frames(2)
    check(sim.state.camp_supply.is_empty() and not sim.state.owned_cards.has("regional_c3") and sim.state.camps=={"1":[0]},"Hard Reset clears every cooldown, the card and the camps")
    at_camp(0)
    check(sim.campaign.camp_supply_step().is_empty() and supplies_total()==0,"…so nothing is given afterwards")

func camp_migration_checks() -> void:
    print("-- Camp Supplies: Change 77/79 saves")
    # A Change 79 save: camp 0 already gave its one supply this run, camp 1 (owned) had not.
    fresh()
    sim.state.camps["1"].append(1)
    sim.state.playtime_total=5000.0
    var snap: Dictionary=sim.snapshot()
    snap.migrations=Array(snap.migrations).filter(func(m):return m!="camp_supply_cooldowns")
    snap.erase("camp_supply")
    snap["camp_supplies"]={"1":[0],"2":[1,99]} # fixture: the Change 77 record (99 is not a camp)
    var out: Dictionary=sim.campaign.normalize_snapshot(snap)
    check(not out.has("camp_supplies") and Array(out.migrations).has("camp_supply_cooldowns"),"The old list is retired and the migration recorded")
    check(out.camp_supply.keys().size()==2 and near(float(out.camp_supply["1:0"].next),5600.0) and near(float(out.camp_supply["2:1"].next),5600.0),"Camps that already gave this run start a full 600 s cooldown at load: %s" % [out.camp_supply])
    check(sim.campaign.valid_snapshot(out),"The migrated save is valid")
    var again: Dictionary=sim.campaign.normalize_snapshot(out)
    check(again.camp_supply==out.camp_supply,"Migrating twice changes nothing")
    sim.restore(snap);await frames(2)
    give_slots(3)
    sim.state.player.hp=sim.stats().hp
    at_camp(0)
    check(sim.campaign.camp_supply_step().is_empty(),"Camp 0 (rewarded before the update) gives nothing right after the update")
    at_camp(1)
    check(sim.campaign.camp_supply_step().size()==3,"Camp 1 (not rewarded this run) gives its first batch of 3")
    check(sim.state.owned_cards.has("regional_c3") and sim.state.camps["1"]==[0,1],"Card and camps kept")
    # A released schema 8 save owning the card (Camp Survey era, no record at all).
    fresh(false)
    var file:=FileAccess.open("res://tests/fixtures/old_saves/schema8_late.json",FileAccess.READ)
    var data: Dictionary=JSON.parse_string(file.get_as_text()).sections.lootfarmer
    check(data.owned_cards.has("regional_c3") and not data.has("camp_supplies"),"fixture: the old save owns regional_c3")
    sim.restore(data);await frames(2)
    check(sim.state.owned_cards.has("regional_c3") and sim.state.camp_supply=={} and Array(sim.state.migrations).has("camp_supply_cooldowns"),"Loaded: card owned, every camp ready, migration recorded")
    sim.state.player.hp=sim.stats().hp;at_camp(0)
    var before:=supplies_total()
    var got: Array=sim.campaign.camp_supply_step()
    check(got.size()>=1 and supplies_total()==before+got.size(),"Standing at its camp gives this owner supplies (%d)" % got.size())

func camp_normalize_checks() -> void:
    print("-- Camp Supplies: damaged saves")
    fresh()
    sim.state.playtime_total=1000.0
    var snap: Dictionary=sim.snapshot()
    snap.camp_supply={"1:0":{"next":1300.0,"left":0},"1:1":{"next":"x","left":2.0},"1:0:0":{},"9:0":{"next":1100.0},"1:77":{"next":1100.0},"2:1":{"next":1e9,"left":0},"3:0":{"next":10.0,"left":0},"4:0":{"next":0,"left":9},"y":"bad"}
    var out: Dictionary=sim.campaign.normalize_snapshot(snap)
    check(out.camp_supply.keys().size()==4,"Invalid keys, maps and camps dropped; an expired idle record dropped (%s)" % [out.camp_supply])
    check(near(float(out.camp_supply["1:0"].next),1300.0) and int(out.camp_supply["1:1"].left)==2 and near(float(out.camp_supply["2:1"].next),1600.0) and int(out.camp_supply["4:0"].left)==3,"next clamped to one cooldown ahead, left to one batch")
    snap.camp_supply="bad"
    out=sim.campaign.normalize_snapshot(snap)
    check(out.camp_supply=={} and sim.campaign.valid_snapshot(out),"A non-dictionary record becomes empty and the save stays valid")

func texts(node: Node,out: Array) -> Array:
    if (node is Label or node is Button or node is RichTextLabel) and node.is_visible_in_tree():out.append(str(node.text))
    for c in node.get_children():texts(c,out)
    return out

func camp_ui_checks() -> void:
    print("-- Camp Supplies: UI")
    fresh()
    give_slots(3)
    at_camp(0);sim.campaign.camp_supply_step()
    check(not game.sheet.visible and game.banner.queue.is_empty(),"The reward opens no panel or banner")
    for i in range(3):game._update_toast(.1)
    check(game.get_node("Toast").visible and str(game.get_node("Toast/Text").text)=="Camp Supplies: +3 supplies","Toast: %s" % game.get_node("Toast/Text").text)
    var rect: Rect2=game.get_node("Toast").get_global_rect()
    check(rect.size.x<=get_window().size.x and rect.position.x>=0,"The toast fits the screen width")
    var history: Array=sim.state.history
    check(not history.is_empty() and str(history[0].key)=="HISTORY_ITEM","Each unit also appears in the recent-finds feed")
    game._open("camp");await frames(4)
    var all:=" | ".join(texts(game,[]))
    check(all.contains("Camp Supplies: next in"),"The camp panel shows the camp's cooldown")
    game._close()
    fresh(false)
    game._open("camp");await frames(4)
    check(not " | ".join(texts(game,[])).contains("Camp Supplies:"),"Without the card the camp panel shows no Camp Supplies line")
    game._close()
    fresh()
    game._open("prestige");await frames(4)
    all=" | ".join(texts(game,[]))
    check(not all.contains("Camp Survey") and all.contains("Camp Supplies"),"The owned card is listed as Camp Supplies")
    game._close()

# ================================================================ 4. Stage selector
func state_of(st: int) -> Dictionary:return sim.campaign.stage_progress()[st-1]

func stage_state_checks() -> void:
    print("-- 4. Stage selector states")
    fresh(false)
    var s: Array=sim.campaign.stage_progress()
    check(s.size()==8 and s.map(func(x):return int(x.stage))==[1,2,3,4,5,6,7,8],"Eight stages in canonical order")
    check(state_of(1).here and state_of(1).unlocked and not state_of(1).cleared,"Fresh save: Winter I is here, unlocked, not cleared")
    check(state_of(2).next and not state_of(2).unlocked and sim.campaign.next_stage_to_unlock()==2,"Fresh save: Winter II is NEXT and still locked")
    check(sim.campaign.travel_reason(2,0)=="STAGE_LOCKED","…and travel there is refused")
    check(s.filter(func(x):return x.next).size()==1,"Exactly one NEXT")
    # Stage 5 unlocked, standing on stage 1.
    sim.state.unlocked_stage=5;sim.state.stage=1 # fixture: Autumn I reached this run, back in Winter I
    check(state_of(1).here and not state_of(5).here,"Current location: Winter I")
    check(state_of(6).next and sim.campaign.next_stage_to_unlock()==6 and not state_of(2).next,"Next to unlock is Autumn II, not Winter II")
    check(state_of(1).cleared and state_of(4).cleared and state_of(5).unlocked and not state_of(5).cleared,"Stages 1-4 cleared, Autumn I unlocked (its gate still open)")
    check(not state_of(6).unlocked and not state_of(7).unlocked and not state_of(7).next,"Autumn II and later locked; only Autumn II is NEXT")
    # Visiting is not completing.
    sim.state.unlocked_stage=2;sim.state.stage=2
    check(state_of(2).here and not state_of(2).cleared,"Standing on a stage never marks it cleared")
    # All eight unlocked.
    sim.state.unlocked_stage=8;sim.state.stage=8
    s=sim.campaign.stage_progress()
    check(sim.campaign.next_stage_to_unlock()==0 and s.filter(func(x):return x.next).is_empty() and s.all(func(x):return x.unlocked),"Stage 8 unlocked: no NEXT, all eight open")
    check(not state_of(8).cleared,"Spring II is unlocked but not cleared before the final clear")
    sim.state.world_complete=true # fixture: final stage cleared this run
    check(state_of(8).cleared,"…and cleared once world_complete")
    # Prestige: statuses follow current-run access, not kept camps.
    sim.state.camps["5"]=[0,1];sim.state.world_complete=false
    sim.state.stage=1;sim.campaign.configure_stage()
    check(do_prestige(),"Prestige completes")
    check(int(sim.state.unlocked_stage)==1 and sim.state.camps.has("5"),"After Prestige: access back to Winter I, Autumn I camps kept")
    check(state_of(2).next and not state_of(5).unlocked and not state_of(1).cleared,"Statuses reflect the new run (Winter II NEXT, Autumn I locked, Winter I not cleared)")

func stage_rows() -> Array:
    var list: Array=game.rows.find_children("*","PanelContainer",true,false).filter(func(n):return n.has_meta("stage_row"))
    return list

func tap_of(card: Control) -> Button:
    for c in card.get_children():
        if c is Button:return c
    return null

func stage_ui_checks() -> void:
    print("-- 4. Stage selector UI")
    fresh(false)
    game._open("world");await frames(8)
    var rows: Array=stage_rows()
    check(rows.size()==8 and rows.map(func(r):return int(r.get_meta("stage_row")))==[1,2,3,4,5,6,7,8],"Fresh save: the World panel lists 01-08 in order")
    check(game.rows.find_children("*","Label",true,false).filter(func(l):return l.has_meta("season_header")).map(func(l):return l.text)==["Winter","Summer","Autumn","Spring"],"Season headers Winter / Summer / Autumn / Spring")
    var all:=" | ".join(texts(game.rows,[]))
    check(all.contains("Next to unlock: "+tr(sim.catalog.stages[1].name)) and all.contains("HERE") and all.contains("NEXT"),"Summary names Winter II as next; HERE and NEXT badges shown")
    var t2: Button=tap_of(rows[1])
    check(t2!=null and t2.disabled and not t2.has_meta("guide") or (t2!=null and t2.disabled and str(t2.get_meta("guide",""))=="stage_row_2"),"Winter II row is not a travel button while locked")
    check(game.rows.find_children("*","Button",true,false).filter(func(b):return str(b.get_meta("guide",""))=="travel_stage_2").is_empty(),"No travel_stage_2 control on a fresh save (Change 25 rule)")
    check(tap_of(rows[0]).disabled,"The current map's row does not travel")
    game._close()
    sim.state.unlocked_stage=5;sim.state.stage=1;sim.touch() # fixture: Autumn I reached, back on Winter I
    game._open("world");await frames(8)
    rows=stage_rows()
    all=" | ".join(texts(game.rows,[]))
    check(all.contains("Next to unlock: "+tr(sim.catalog.stages[5].name)),"Summary: next to unlock is Autumn II")
    var s6: Dictionary=rows[5].get_meta("stage_state")
    check(bool(s6.next) and not bool(rows[1].get_meta("stage_state").next),"The NEXT state is on Autumn II, not Winter II")
    # The panel refresh reuses same-shape controls: the rings must follow the new states (no stale NEXT ring).
    var ring_ok:=true;var rings: Array=[]
    for r in rows:
        var sb: StyleBox=r.get_theme_stylebox("panel")
        var gold: bool=sb is StyleBoxFlat and sb.border_color.is_equal_approx(game.STAGE_NEXT_RING)
        var cyan: bool=sb is StyleBoxFlat and sb.border_color.is_equal_approx(game.camp_picker.HERE_RING)
        if gold:rings.append("gold %d" % int(r.get_meta("stage_row")))
        if cyan:rings.append("cyan %d" % int(r.get_meta("stage_row")))
        ring_ok=ring_ok and gold==bool(r.get_meta("stage_state").next) and cyan==bool(r.get_meta("stage_state").here)
    check(ring_ok and rings==["cyan 1","gold 6"],"After the refresh the rings follow the states: %s" % [rings])
    var travel: Array=game.rows.find_children("*","Button",true,false).filter(func(b):return str(b.get_meta("guide","")).begins_with("travel_stage_")).map(func(b):return str(b.get_meta("guide")))
    check(travel==["travel_stage_2","travel_stage_3","travel_stage_4","travel_stage_5"],"Unlocked maps other than the current one travel: %s" % [travel])
    var ok:=true
    for r in rows:ok=ok and r.get_global_rect().size.y>=56
    check(ok,"Every stage card is at least 56 px tall")
    # A tap still uses the existing travel flow.
    sim.state.camps["3"]=[0] # fixture: one camp on Summer I
    tap_of(rows[2]).pressed.emit();await frames(4)
    check(int(sim.state.stage)==3,"Tapping Summer I travels there (stage %d)" % int(sim.state.stage))
    game._close()
    sim.state.unlocked_stage=8;sim.touch()
    game._open("world");await frames(8)
    all=" | ".join(texts(game.rows,[]))
    check(all.contains(tr("STAGE_PROGRESS_ALL")) and not all.contains("NEXT"),"All eight open: 'All stages unlocked', no NEXT badge, no ninth stage")
    check(stage_rows().size()==8,"Still exactly eight rows")
    game._close()
