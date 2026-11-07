extends "res://tests/change_20_probe.gd"
## Change 52 (approved progression brief, B3): boss-enhanced weapons.
## The first boss-origin copy of a weapon id this run adds exactly two bonus attributes (item pool, normal
## ranges, no stat duplicated across the three slots), whether the id was already owned or not; later
## boss copies are ordinary copies; one stack, one merge level; merging never changes attributes; each
## slot rerolls alone; the boss origin survives pickups and save/load; offline/evolution copies are never
## enhanced; Prestige removes the attributes with the inventory. Runs with --first-run-complete.
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    drop_checks()
    reroll_checks()
    persistence_checks()
    prestige_checks()
    await ui_checks()
    print("CHANGE_52_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func gi(id: String) -> int:return sim.campaign.group_id(id)
func boss_drop(item: String,boss:="boss-snowman") -> int:
    sim._drop(item,{"group":gi(boss),"x":200.0,"y":200.0})
    return int(sim.state.pickups.back().uid)
func stats_of(id: String) -> Array:
    var out: Array=sim.state.items[id].extras.keys()
    for e in sim.boss_extras(id):out.append(str(e.stat))
    return out
func unique(a: Array) -> bool:
    var seen: Dictionary={}
    for x in a:
        if seen.has(x):return false
        seen[x]=true
    return true

func drop_checks() -> void:
    fresh()
    var uid:=boss_drop("wood_axe")
    check(bool(sim.state.pickups.back().get("enhanced",false)),"A boss's weapon drop is marked enhanced")
    sim._drop("unit-blue-cap_outfit",{"group":gi("boss-snowman"),"x":0.0,"y":0.0})
    check(not sim.state.pickups.back().has("enhanced"),"Boss outfits are not enhanced (weapons only)")
    sim.state.pickups.pop_back()
    check(sim.collect(uid),"Collect the boss Wood Axe")
    check(sim.boss_extras("wood_axe").size()==2 and sim.state.items.wood_axe.extras.size()==1,"First boss copy: one base attribute + two boss attributes")
    check(unique(stats_of("wood_axe")),"No stat appears in two slots %s" % str(stats_of("wood_axe")))
    for e in sim.boss_extras("wood_axe"):
        var span: Array=sim.catalog.items.wood_axe.extras[str(e.stat)]
        check(float(e.value)>=float(span[0]) and float(e.value)<=float(span[1]),"%s within its normal range" % e.stat)
    var before: String=JSON.stringify(sim.state.items.wood_axe)
    check(sim.collect(boss_drop("wood_axe")) and sim.quantity("wood_axe")==2,"A second boss copy joins the same stack")
    var after: Dictionary=sim.state.items.wood_axe.duplicate(true);after.qty=1
    check(JSON.stringify(after)==before,"…and changes no attribute (an ordinary copy)")
    check(sim.merge("wood_axe") and JSON.stringify(sim.state.items.wood_axe.extras)==JSON.stringify(JSON.parse_string(before).extras) and sim.boss_extras("wood_axe").size()==2,"Merging keeps every attribute")
    # Owned normal copy first, then the first boss copy enhances it once.
    sim.add_item("wood_sword",2)
    check(sim.boss_extras("wood_sword").is_empty(),"A normal copy has no boss attributes")
    check(sim.collect(boss_drop("wood_sword")) and sim.boss_extras("wood_sword").size()==2 and sim.quantity("wood_sword")==3,"The first boss copy enhances the owned stack once")
    # Equipped attributes count in the stats.
    sim.equip("wood_axe")
    var total: Dictionary=sim.bonus_attributes("wood_axe")
    var src: Dictionary=sim.stat_sources()["SOURCE_EQUIPPED"]
    var ok:=true
    for k in total:ok=ok and absf(float(src.get(k,0))-float(total[k]))<1e-6
    check(ok,"Equipped: base and boss attributes count in full")
    # Offline grants and evolutions never enhance.
    sim.add_item("stone_axe",1)
    check(sim.boss_extras("stone_axe").is_empty(),"A copy added directly (offline grant, evolution) is not enhanced")

func reroll_checks() -> void:
    sim.state.gems=100000
    var slots=sim.reroll_slots("wood_axe")
    check(slots.size()==3,"Three reroll slots")
    for n in range(30):
        var slot:=n%3
        var keep: Array=[]
        var all:=stats_of("wood_axe")
        var b: Array=sim.boss_extras("wood_axe").duplicate(true)
        var base: Dictionary=sim.state.items.wood_axe.extras.duplicate()
        check(sim.reroll("wood_axe",slot),"Reroll slot %d" % slot)
        check(unique(stats_of("wood_axe")) and stats_of("wood_axe").size()==3,"Still three distinct stats")
        if slot>0:
            check(JSON.stringify(sim.state.items.wood_axe.extras)==JSON.stringify(base) and JSON.stringify(sim.boss_extras("wood_axe")[2-slot])==JSON.stringify(b[2-slot]),"Only boss slot %d changed" % slot)
        else:
            check(JSON.stringify(sim.boss_extras("wood_axe"))==JSON.stringify(b),"Base reroll leaves both boss slots")
    var gems: float=sim.state.gems
    check(sim.reroll("wood_axe",1) and is_equal_approx(gems-float(sim.state.gems),float(sim.reroll_cost("wood_axe"))),"A slot costs the item's reroll price")
    check(not sim.reroll("wood_axe",3),"No fourth slot")
    check(int(sim.state.items.wood_axe.qty)==1 and int(sim.state.items.wood_axe.merge)==1,"Rerolls never touch quantity or merge level")

func persistence_checks() -> void:
    fresh()
    boss_drop("iron_axe","boss-gray-cat")
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    check(sim.campaign.valid_snapshot(sim.campaign.normalize_snapshot(snap)),"An enhanced pickup validates")
    sim.restore(snap)
    var uid: int=int(sim.state.pickups.back().uid)
    check(bool(sim.state.pickups.back().get("enhanced",false)),"The boss origin survives a reload")
    check(sim.collect(uid) and sim.boss_extras("iron_axe").size()==2,"Collected after the reload, it enhances")
    var saved: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    sim.restore(saved)
    check(sim.boss_extras("iron_axe").size()==2,"Boss attributes survive save/load")
    var bad: Dictionary=saved.duplicate(true)
    bad.items.iron_axe.boss_extras=[{"stat":"crit","value":.02},{"stat":"crit","value":.02}]
    check(not sim.campaign.valid_snapshot(sim.campaign.normalize_snapshot(bad)),"A duplicated boss stat is rejected by validation")

func prestige_checks() -> void:
    fresh()
    sim.collect(boss_drop("wood_axe"))
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman")
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    check(sim.campaign.begin_prestige() and sim.campaign.choose_card(str(sim.campaign.offered_cards()[0])),"Prestige")
    check(not sim.state.items.has("wood_axe"),"The enhanced record leaves with the inventory")
    sim.add_item("wood_axe")
    check(sim.boss_extras("wood_axe").is_empty(),"Found again normally: no boss attributes leak into the new run")
    check(sim.collect(boss_drop("wood_axe")) and sim.boss_extras("wood_axe").size()==2,"A new run's first boss copy enhances again")

func ui_checks() -> void:
    game.selected="wood_axe";game._open("item")
    await frames(2)
    var rerolls:=0
    for b in game.rows.find_children("*","Button",true,false):
        if str(b.text).begins_with(tr("REROLL_ATTRIBUTE").get_slice("%",0)):rerolls+=1
    check(rerolls==3,"The item panel offers one Reroll per slot (%d)" % rerolls)
    var gold:=0
    for l in game.rows.find_children("*","Label",true,false):
        if str(l.text).contains(tr("ITEM_BOSS_BONUS")):gold+=1
    check(gold>=2,"Boss attributes are listed (%d)" % gold)
    game._close()
