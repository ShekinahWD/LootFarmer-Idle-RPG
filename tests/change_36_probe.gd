extends "res://tests/change_20_probe.gd"
## New Supply Mastery rule: 5 successful uses per level; the prior 3-use save format migrates
## without losing earned ranks or partial progress. Prestige preserves mastery and use counts.
## Cap ^100, milestones ^25/^50/^100, stock separate from mastery, purchases/drops/blocked
## uses grant nothing, automatic use counts, legacy one-time credit and save normalization.
## Runs with --first-run-complete.
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    rule_checks()
    use_checks()
    cap_and_milestone_checks()
    auto_and_blocked_checks()
    await ui_checks()
    save_checks()
    prestige_checks()
    print("CHANGE_36_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func near(a: float,b: float) -> bool:return absf(a-b)<.0001*maxf(1,absf(b))
func per() -> int:
    return int(sim.catalog.progression.change17.supply_uses_per_level)

## Every supply type, with every slot open so each can be used; stock only, no mastery yet.
func stocked() -> void:
    fresh();sim.state.coins=100000
    sim.state.upgrades["supply_slots"]=4;sim.state.supplies.resize(5);sim.state.supplies.fill("")
    for id in sim.supply_ids():check(sim.add_item(id,20) and sim.quantity(id)==20,"Stocked "+id)

## One successful use from a state where the supply is allowed (half health, no cooldown, no buff).
func use_once(id: String) -> bool:
    sim.state.player.hp=sim.stats().hp*.5;sim.state.use_cd=0;sim.state.boost_time=0;sim.state.buffs={}
    return sim.use_item(id)

func rule_checks() -> void:
    check(per()==5,"Catalog rule: 5 successful uses per mastery level")
    check(int(sim.catalog.progression.supply_mastery.cap)==100,"Mastery cap unchanged at ^100")
    var steps: Array=sim.catalog.progression.supply_mastery.milestones.map(func(m)->int:return int(m.merge))
    check(steps==[25,50,100],"Milestones unchanged at ^25/^50/^100")

## Uses 0..6 for every supply type: level one on the fifth use.
func use_checks() -> void:
    stocked()
    check(sim.supply_ids().size()==5,"Five supply types")
    for id in sim.supply_ids():
        check(sim.supply_mastery(id)==0 and int(sim.state.supply_uses.get(id,0))==0,"Use 0: ^0 "+id)
        var stock: int=sim.quantity(id)
        for n in range(1,7):
            check(use_once(id),"Successful use %d %s" % [n,id])
            check(int(sim.state.supply_uses[id])==n,"Use counter %d %s" % [n,id])
            check(sim.supply_mastery(id)==int(n/5),"Use %d gives ^%d %s" % [n,int(n/5),id])
        check(sim.quantity(id)==stock-6,"Six uses spent six charges "+id)
    # The new rule waits until use five.
    stocked()
    for n in range(1,6):
        use_once("potion")
        if n==3:check(sim.supply_mastery("potion")==0,"Third use is partial progress")
        if n==4:check(sim.supply_mastery("potion")==0,"Fourth use is partial progress (4/5)")
        if n==5:check(sim.supply_mastery("potion")==1,"Fifth use earns the level")
    # Repeated uses: 30 uses = ^6; types never share a counter.
    stocked();sim.add_item("guard_tonic",40)
    for n in range(30):use_once("guard_tonic")
    check(sim.supply_mastery("guard_tonic")==6 and sim.supply_mastery("potion")==0,"30 Guard Tonic uses = ^6, potion untouched")
    var mastered: float=sim.supply_value("guard_tonic")
    sim.state.supply_uses.guard_tonic=0
    check(mastered>sim.supply_value("guard_tonic"),"^6 Guard Tonic is stronger than ^0")
    # Buying and collecting add stock only.
    stocked()
    check(sim.purchase_consumable("potion") and sim.supply_mastery("potion")==0 and int(sim.state.supply_uses.get("potion",0))==0,"A bought copy adds no use and no mastery")
    sim.add_item("potion",50)
    check(sim.supply_mastery("potion")==0,"Collected copies add no mastery")

func cap_and_milestone_checks() -> void:
    stocked()
    sim.state.supply_uses.potion=25*per()-1 # fixture: one use short of ^25
    check(sim.supply_mastery("potion")==24 and near(float(sim.supply_milestone("potion").cooldown),1.0),"124 uses: ^24, no milestone yet")
    use_once("potion")
    check(sim.supply_mastery("potion")==25 and near(float(sim.supply_milestone("potion").cooldown),.9),"125th use reaches ^25 Steady")
    sim.state.supply_uses.potion=50*per() # fixture: ^50
    check(sim.supply_mastery("potion")==50 and near(sim.supply_value("potion"),.15),"250 uses: ^50 heals 15%")
    sim.state.supply_uses.potion=100*per()-1 # fixture: one use short of the cap
    check(sim.supply_mastery("potion")==99,"499 uses: ^99")
    use_once("potion")
    check(sim.supply_mastery("potion")==100 and near(sim.supply_value("potion"),.2) and near(sim.supply_cooldown("potion"),10),"500th use: ^100 cap, 20% heal, 10 s cooldown floor")
    use_once("potion")
    check(int(sim.state.supply_uses.potion)==500 and sim.supply_mastery("potion")==100,"Counter stops at cap x 5; mastery stays ^100")
    sim.state.supply_mastery_credit.potion=99;sim.state.supply_uses.potion=6
    check(sim.supply_mastery("potion")==100,"Credit plus uses never exceeds the cap")

func auto_and_blocked_checks() -> void:
    stocked()
    sim.state.player.hp=sim.stats().hp;sim.state.use_cd=0
    check(not sim.use_item("potion") and int(sim.state.supply_uses.get("potion",0))==0,"Blocked use at full health: no use counted")
    sim.state.player.hp=sim.stats().hp*.5
    check(use_once("potion"),"First use")
    check(not sim.use_item("potion") and int(sim.state.supply_uses.potion)==1,"Blocked use on cooldown: no use counted")
    sim.state.gems=10000;sim.buy_upgrade("auto_use")
    check(sim.bind_auto(sim.state.supplies.find("potion")),"Potion bound to auto-use")
    for n in range(2):
        sim.state.player.hp=sim.stats().hp*.5;sim.state.use_cd=0
        sim.state.use_clock=99.0;sim.campaign.automate(.1)
    check(int(sim.state.supply_uses.potion)==3 and sim.supply_mastery("potion")==0,"Two automatic uses bring the counter to three")
    for n in range(2):
        sim.state.player.hp=sim.stats().hp*.5;sim.state.use_cd=0
        sim.state.use_clock=99.0;sim.campaign.automate(.1)
    check(int(sim.state.supply_uses.potion)==5 and sim.supply_mastery("potion")==1,"Four automatic uses complete the fifth successful use")

func label_containing(text: String) -> Label:
    for node in game.find_children("*","Label",true,false):
        if node.is_visible_in_tree() and node.text.contains(text):return node
    return null

func ui_checks() -> void:
    stocked()
    use_once("potion");use_once("potion")
    game.selected="potion";game.selected_slot=-1;game._open("item");await frames(2)
    check(label_containing(tr("SUPPLY_NEXT_USES").get_slice("%",0)+"2 / 5")!=null,"Supply panel: next level at 2 / 3 uses")
    for n in range(3):use_once("potion")
    game._open("item");await frames(2)
    check(label_containing(tr("SUPPLY_NEXT_USES").get_slice("%",0)+"0 / 5")!=null,"Supply panel: remainder resets to 0 / 3 at ^1")
    check(tr("SUPPLY_MASTERY_EXPLAIN").contains("Every %d uses" % per()),"English explanation states 5 uses")
    check(tr("SUPPLY_NO_MERGE").contains("Every five uses"),"English merge refusal states five uses")
    for key in ["SUPPLY_MASTERY_EXPLAIN","SUPPLY_NO_MERGE"]:
        check(not tr(key).contains("Every three uses") and not tr(key).to_lower().contains("prestige resets"),"No stale three-use/Prestige-reset copy in "+key)
    game._close()

func save_checks() -> void:
    # An existing save keeps its actual use count; mastery is derived with the new divisor.
    stocked()
    var old: Dictionary=sim.snapshot()
    old.supply_uses={"potion":4,"guard_tonic":11};old.supply_mastery_credit={"potion":25}
    old.migrations.erase("supply_uses_5") # fixture: actual pre-upgrade saved profile
    sim.restore(JSON.parse_string(JSON.stringify(old)))
    check(int(sim.state.supply_uses.potion)==6 and sim.supply_mastery("potion")==26,"Old save: four uses become six, rank 26 kept")
    check(int(sim.state.supply_uses.guard_tonic)==17 and sim.supply_mastery("guard_tonic")==3,"Old save: 11 uses migrate to 17, rank 3 + remainder 2 kept")
    for n in range(3):use_once("guard_tonic")
    check(sim.supply_mastery("guard_tonic")==4,"Remainder carried: three more uses complete ^4")
    # Legacy acquisition-based saves migrate to one-time credit exactly once.
    var legacy: Dictionary=sim.snapshot()
    legacy.erase("supply_uses");legacy.erase("supply_mastery_credit");legacy.supply_found={"potion":31}
    sim.restore(JSON.parse_string(JSON.stringify(legacy)))
    check(sim.supply_mastery("potion")==30 and sim.state.supply_uses.is_empty(),"Legacy copies migrate to ^30 credit, no uses invented")
    var again: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()));sim.restore(again)
    check(sim.supply_mastery("potion")==30,"Migration is not re-credited on reload")
    # Saves beyond the counter ceiling: mastery stays ^100, the counter is clamped to 500.
    var full: Dictionary=sim.snapshot();full.supply_uses={"potion":900};full.supply_mastery_credit={}
    sim.restore(JSON.parse_string(JSON.stringify(full)))
    check(int(sim.state.supply_uses.potion)==500 and sim.supply_mastery("potion")==100,"900 recorded uses clamp to the 500-use ceiling at ^100")
    # Real disk round trip.
    sim.state.supply_uses={"potion":7};sim.state.supply_mastery_credit={}
    check(SaveService.save_now(),"Disk save")
    sim.state.supply_uses={};SaveService.load_and_apply()
    check(int(sim.state.supply_uses.get("potion",0))==7 and sim.supply_mastery("potion")==1,"Disk reload: 7 uses = ^1")

func prestige_checks() -> void:
    fresh()
    sim.state.supply_uses.potion=8;sim.state.supply_mastery_credit.potion=3
    check(sim.supply_mastery("potion")==4,"Before Prestige: credit 3 + 8 uses = ^4")
    sim.state.bosses_found.append("boss-snowman")
    # Change 71: since Change 61 the reset also needs the Snowman defeated once (this fixture predated it).
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1 # fixture: defeated once
    sim.state.opportunities.hunter_o1={"ready":true,"baseline":{},"step":0,"count":0}
    check(sim.campaign.begin_prestige(),"Prestige begins")
    var guard:=0
    while not sim.state.prestige_batch.is_empty() and guard<40:
        guard+=1;sim.campaign.choose_card(str(sim.campaign.offered_cards()[0]))
    check(sim.state.prestiges==1 and sim.supply_mastery("potion")==4 and int(sim.state.supply_uses.potion)==8,"Prestige keeps mastery and use progress")
