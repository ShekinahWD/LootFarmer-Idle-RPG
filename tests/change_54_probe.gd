extends "res://tests/change_20_probe.gd"
## Change 54 (approved progression brief, B5 / Design A): 48 opportunities and 48 cards on the 11 paths.
## - Catalog: 15 new opportunities and cards, every path has as many cards as opportunities, stage grouping
##   from requirement data (Trophy II on Summer I-II, Trophy III on Autumn I-II), per-map counts printed.
## - Every new opportunity is discovered and completed through the game's own counters.
## - Original Sets: the original three cards of a path activate its Set, in any order, with or without new
##   cards; new cards never complete a Set; no all-cards Set exists; old owned cards stay valid.
## - A 48-card walk: one batch of 48 ready opportunities awards every card once, never a dead offer.
## - Each new card effect does what its text says. Runs with --first-run-complete.
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    catalog_checks()
    reachability_checks()
    set_checks()
    walk_checks()
    effect_checks()
    await ui_checks()
    print("CHANGE_54_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func near(a: float,b: float) -> bool:return absf(a-b)<=1e-6*maxf(1.0,absf(b))
func gi(id: String) -> int:return sim.campaign.group_id(id)
func grant(cards: Array) -> void:
    sim.state.owned_cards=cards.duplicate();sim.touch()

func catalog_checks() -> void:
    var ops: Array=sim.catalog.campaign.opportunities
    check(ops.size()==48 and sim.catalog.campaign.cards.size()==48,"48 opportunities and 48 cards (%d, %d)" % [ops.size(),sim.catalog.campaign.cards.size()])
    var per_path_ops: Dictionary={};var per_path_cards: Dictionary={}
    for op in ops:per_path_ops[op.path]=int(per_path_ops.get(op.path,0))+1
    for id in sim.catalog.campaign.cards:per_path_cards[sim.catalog.campaign.cards[id].path]=int(per_path_cards.get(sim.catalog.campaign.cards[id].path,0))+1
    check(per_path_ops==per_path_cards and per_path_ops.size()==11,"Each of the 11 paths has as many cards as opportunities %s" % str(per_path_ops))
    var counts: Array=[0,0,0,0,0,0,0,0]
    for op in ops:
        check(op.has("stages") and not (op.stages as Array).is_empty(),"%s has stage data" % op.id)
        for st in op.stages:
            if int(st)>0:counts[int(st)-1]+=1
    print("CHANGE_54 stage appearances Winter I..Spring II: ",counts)
    for st in range(8):check(counts[st]>=4,"Stage %d has at least 4 stage-specific opportunities (%d)" % [st+1,counts[st]])
    var trophy: Dictionary={}
    for op in ops:
        if op.path=="trophy":trophy[op.id]=(op.stages as Array).map(func(s):return int(s))
    check(trophy=={"trophy_o1":[1,2],"trophy_o2":[3,4],"trophy_o3":[5,6],"trophy_o4":[7,8]},"Trophy grouping follows where its bosses live %s" % str(trophy))
    for c in sim.catalog.campaign.combos:
        check((c.cards as Array).size()==3 and (c.cards as Array).all(func(id):return str(id).ends_with("_c1") or str(id).ends_with("_c2") or str(id).ends_with("_c3")),"Set %s is still its original three cards" % c.id)
    check(sim.catalog.campaign.combos.size()==17,"No new Set was added (17)")
    for op in ops:
        for key in ["name","description"]:check(tr(str(op[key+"_key"]))!=str(op[key+"_key"]),"%s %s translated in English" % [op.id,key])
    for id in sim.catalog.campaign.cards:
        var d: Dictionary=sim.catalog.campaign.cards[id]
        check(tr(str(d.name_key))!=str(d.name_key) and tr(str(d.description_key))!=str(d.description_key),"%s has English text" % id)

func ready(id: String) -> bool:
    sim.campaign.evaluate()
    return sim.state.opportunities.has(id) and bool(sim.state.opportunities[id].ready)
func found(id: String) -> bool:
    sim.campaign.evaluate()
    return sim.state.opportunities.has(id)

func reachability_checks() -> void:
    # Expeditions IV-VIII: discovered after 10 kills of the first type, completed type by type.
    for n in range(4,9):
        fresh()
        var id:="expedition_o%d" % n
        var chain: Array=sim.campaign.chain_for(id)
        sim.campaign.progress("kill",str(chain[0][1]),10)
        check(found(id),"%s discovered by 10 %s" % [id,chain[0][1]])
        for q in chain:sim.campaign.progress("kill",str(q[1]),float(q[2]))
        check(ready(id),"%s completed by its chain (%d steps)" % [id,chain.size()])
        var g: int=gi(str(chain[0][1]))
        check(g>=0 and (sim.catalog.campaign.opportunities.filter(func(o):return o.id==id)[0].stages as Array).map(func(s):return int(s)).has(int(sim.catalog.groups[g].stage)),"%s is grouped on the map of its enemies" % id)
    # Collections IV-VIII: discovered by map access, completed by picking up and submitting real outfits.
    for n in range(4,9):
        fresh()
        var id:="collection_o%d" % n
        sim.state.unlocked_stage=sim.campaign.COLLECTION_DISCOVER_STAGE[n-1]
        check(found(id),"%s discovered at stage %d" % [id,sim.state.unlocked_stage])
        var need=sim.campaign.collection_required(n)
        for name in sim.campaign.collection_names(n):
            var item: String=sim.campaign.contract_outfit(name)
            sim.add_item(item,need)
            sim.campaign.progress("collect",item,need);sim.campaign.progress("gear",item,need)
        check(sim.campaign.collection_complete(id) and sim.campaign.submit(id) and ready(id),"%s completes on submit" % id)
        for name in sim.campaign.collection_names(n):check(sim.quantity(sim.campaign.contract_outfit(name))==1,"%s keeps one %s" % [id,name])
    fresh()
    sim.campaign.progress("boss","boss-bee",1)
    check(found("hunter_o4"),"Hunter IV discovered by the Bee")
    sim.campaign.progress("boss","boss-bee",10)
    check(not ready("hunter_o4"),"Hunter IV needs the Orange Tabby Cat too")
    sim.campaign.progress("boss","boss-orange-tabby-cat",10)
    check(ready("hunter_o4"),"Hunter IV: Bee and Orange Tabby Cat 10 times each")
    fresh()
    sim.campaign.progress("boss","boss-red-panda",1)
    check(found("challenge_o4"),"Challenge IV discovered by the Red Panda")
    sim.campaign.progress("restricted","boss-red-panda",1)
    check(ready("challenge_o4"),"Challenge IV: the Red Panda without a supply")
    fresh()
    sim.campaign.progress("boss","boss-bee",1)
    check(found("trophy_o4"),"Trophy IV discovered by the Bee")
    for b in ["bee","orange-tabby-cat","red-panda"]:sim.state.opportunities.trophy_o4["trophy_boss-"+b]=true
    check(not ready("trophy_o4"),"Trophy IV needs the Sunflower too")
    sim.state.opportunities.trophy_o4["trophy_boss-sunflower"]=true
    check(ready("trophy_o4"),"Trophy IV: all four Spring bosses")
    fresh()
    sim.state.unlocked_stage=6
    check(found("regional_o4"),"Regional IV discovered on reaching Autumn II")
    for st in [5,6]:
        sim.campaign.explore_cells(st,[],true)
        var camps: Array=[];for i in range(sim.catalog.stages[st-1].spawns.size()):camps.append(i)
        sim.state.camps[str(st)]=camps
        for g in sim.catalog.stages[st-1].groups:
            if sim.catalog.groups[g].boss:sim.state.run_kills[sim.catalog.groups[g].id]=1
    check(ready("regional_o4"),"Regional IV: Autumn I and II explored, camps, four bosses")
    fresh()
    sim.add_item("obsidian_sword",1)
    check(found("masterwork_o4"),"Masterwork IV discovered by owning an Obsidian weapon")
    sim.add_item("obsidian_sword",100);sim.merge("obsidian_sword",true)
    check(int(sim.record("obsidian_sword").merge)==100 and ready("masterwork_o4"),"Masterwork IV: Obsidian weapon at ^100")

func set_checks() -> void:
    fresh()
    var hunter: Dictionary=sim.catalog.campaign.combos.filter(func(c):return c.id=="hunter_set")[0]
    var base=sim.campaign.bonus(str(hunter.effect))
    grant(["hunter_c3","hunter_c4","hunter_c1"])
    check(near(sim.campaign.bonus(str(hunter.effect)),base),"Two original cards + a new card do not activate the Set")
    grant(["hunter_c3","hunter_c4","hunter_c1","hunter_c2"])
    check(near(sim.campaign.bonus(str(hunter.effect)),base+float(hunter.value)),"The original three (any order) activate the Set with a new card owned")
    grant(["hunter_c2","hunter_c1","hunter_c3"])
    check(near(sim.campaign.bonus(str(hunter.effect)),base+float(hunter.value)),"The original three alone still activate it, as before")
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    var old: Array=[]
    for id in sim.catalog.campaign.cards:
        if str(id).right(1) in ["1","2","3"]:old.append(id)
    snap.owned_cards=old;snap.consumed=sim.catalog.campaign.opportunities.filter(func(o):return str(o.id).right(1) in ["1","2","3"]).map(func(o):return o.id)
    check(old.size()==33 and sim.campaign.valid_snapshot(sim.campaign.normalize_snapshot(snap)),"A save owning all 33 original cards and their 33 consumed opportunities stays valid")
    sim.restore(snap)
    check(sim.state.owned_cards.size()==33,"…and loads with every card")
    for c in sim.catalog.campaign.combos:check(sim.campaign.combo_owned(c),"Old Set %s still active" % c.id)
    # The new opportunities of a completed path still offer that path's new cards.
    sim.state.opportunities["hunter_o4"]={"ready":true,"baseline":{},"step":0,"count":0}
    check(sim.campaign.awardable_ids()==["hunter_o4"],"Hunter IV can award (Hunter's new card)")

func walk_checks() -> void:
    fresh()
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman")
    for op in sim.catalog.campaign.opportunities:sim.state.opportunities[op.id]={"ready":true,"baseline":{},"step":0,"count":0}
    check(sim.campaign.awardable_ids().size()==48,"All 48 ready opportunities can award a card")
    check(sim.campaign.begin_prestige(),"One batch of 48")
    var guard:=0;var dead:=0
    while not sim.state.prestige_batch.is_empty() and guard<60:
        guard+=1
        var offered: Array=sim.campaign.offered_cards()
        var path: String=str(sim.state.prestige_batch.ids[sim.state.prestige_batch.choices.size()]).rsplit("_",true,1)[0]
        if offered.is_empty():dead+=1;break
        check(offered.all(func(c):return sim.catalog.campaign.cards[c].path==path),"Offers stay on the opportunity's own path (%s)" % path)
        sim.campaign.choose_card(str(offered[0]))
    check(dead==0 and sim.state.owned_cards.size()==48 and sim.state.consumed.size()==48,"48 cards awarded once each, no dead offer (%d owned)" % sim.state.owned_cards.size())
    var unique: Dictionary={}
    for id in sim.state.owned_cards:unique[id]=true
    check(unique.size()==48,"No card awarded twice")

func effect_checks() -> void:
    # Crowd Guard: -4% per normal attacker beyond the first, at most -20%.
    fresh()
    var blue: int=gi("unit-blue-cap")
    var attackers: Array=sim.state.enemies.filter(func(e):return int(e.group)==blue)
    var hit: Dictionary=attackers[0]
    for e in attackers:e.aggro=true
    var n_att=sim.campaign.normal_attackers()
    var plain=sim.campaign.damage_multiplier(hit,sim.state.player)
    grant(["expedition_c4"])
    check(near(sim.campaign.damage_multiplier(hit,sim.state.player),plain*(1-minf(.2,.04*(n_att-1)))),"Crowd Guard with %d attackers" % n_att)
    for e in attackers:e.aggro=false
    # Second Wind.
    fresh();grant(["expedition_c5"])
    var maxhp: float=sim.stats().hp
    sim.state.player.hp=maxhp*.2;sim.campaign.after_player_hit()
    check(near(float(sim.state.player.hp),maxhp*.45) and float(sim.state.player.second_wind)==90.0,"Second Wind heals 25% once below 30%")
    sim.state.player.hp=maxhp*.2;sim.campaign.after_player_hit()
    check(near(float(sim.state.player.hp),maxhp*.2),"…then waits 90 s")
    # Field Rest.
    fresh()
    var field: float=float(sim.catalog.progression.rest.field)
    sim.state.player.x=1200.0;sim.state.player.y=400.0
    var before=sim.campaign.rest_rate()
    grant(["expedition_c8"])
    check(sim.campaign.resting_camp()<0 and near(before,field) and near(sim.campaign.rest_rate(),field*3),"Field Rest triples recovery away from camps")
    # Thrifty Evolution, Steady Supplies, Precise Reroll, Obsidian Temper, Veteran Traveler, Last Stand.
    fresh()
    var cd_plain=sim.supply_cooldown("guard_tonic")
    var cost_plain=sim.reroll_cost("wood_sword")
    var gain_plain=sim.merge_gain("obsidian_sword","damage")
    var iron_gain=sim.merge_gain("iron_sword","damage")
    sim.state.unlocked_stage=3
    var xp_plain=sim.group_xp(blue)
    grant(["collection_c5","collection_c6","collection_c7","masterwork_c4","regional_c4","challenge_c4"])
    check(sim.evolution_spare_cost()==8,"Thrifty Evolution: 8 spares")
    check(cd_plain<=0 or near(sim.supply_cooldown("guard_tonic"),maxf(float(sim.supply("guard_tonic").get("cooldown_floor",0)),cd_plain*.85)),"Steady Supplies: cooldown x0.85")
    check(sim.reroll_cost("wood_sword")<=ceili(float(cost_plain)*.75),"Precise Reroll: 25% cheaper")
    check(near(sim.merge_gain("obsidian_sword","damage"),gain_plain*1.15) and near(sim.merge_gain("iron_sword","damage"),iron_gain),"Obsidian Temper: Obsidian merge gain x1.15 only")
    check(near(sim.group_xp(blue),xp_plain*(1+.25/(1.0))) or sim.group_xp(blue)>xp_plain,"Veteran Traveler: more XP from Winter I normals at Summer I")
    sim.state.unlocked_stage=1
    check(near(sim.group_xp(blue),xp_plain),"…but not on the furthest unlocked map")
    sim.state.player.hp=sim.stats().hp*.2
    check(near(sim.campaign.last_stand_speed(),.2),"Last Stand below 25% HP")
    sim.state.player.hp=sim.stats().hp
    check(sim.campaign.last_stand_speed()==0.0,"…not above")
    # Precise Reroll never returns the same stat.
    sim.add_item("wood_sword",1);sim.state.gems=100000
    var same:=0
    for i in range(20):
        var was: String=str(sim.state.items.wood_sword.extras.keys()[0])
        sim.reroll_stats("wood_sword") # Change 79: one regular slot, no locks
        if str(sim.state.items.wood_sword.extras.keys()[0])==was:same+=1
    check(same==0,"Precise Reroll: 20 rerolls, never the same stat")
    # Treasure Sense: boss attributes in the upper half.
    fresh();grant(["collection_c8"])
    sim._drop("wood_axe",{"group":gi("boss-snowman"),"x":10.0,"y":10.0})
    sim.collect(int(sim.state.pickups.back().uid))
    var upper:=true
    for e in sim.boss_extras("wood_axe"):
        var span: Array=sim.catalog.items.wood_axe.extras[str(e.stat)]
        upper=upper and float(e.value)>=(float(span[0])+float(span[1]))*.5-1e-9
    check(upper and sim.boss_extras("wood_axe").size()==2,"Treasure Sense: boss attributes roll in the upper half")
    # Boss Breaker: telegraph +0.3 s, boss heals -25%.
    fresh()
    var snow: int=gi("boss-snowman")
    var boss: Dictionary=sim.state.enemies.filter(func(e):return int(e.group)==snow)[0]
    var t_plain=sim.campaign.telegraph_time(boss)
    grant(["hunter_c4"])
    check(near(sim.campaign.telegraph_time(boss),t_plain+.3) and near(sim.campaign.telegraph_time(hit),t_plain),"Boss Breaker: boss telegraphs +0.3 s only")
    var robot: int=gi("boss-cyan-robot")
    sim.state.unlocked_stage=2;sim.state.camps["2"]=[0];sim.campaign.camp_action(2,0,true)
    var rb: Dictionary=sim.state.enemies.filter(func(e):return int(e.group)==robot)[0]
    var rmax: float=float(sim.enemy_definition(robot).hp)
    rb.hp=rmax*.2
    sim.campaign.apply_skill(rb,"heal",0.0)
    var healed: float=float(rb.hp)-rmax*.2
    grant([])
    rb.hp=rmax*.2
    sim.campaign.apply_skill(rb,"heal",0.0)
    var healed_plain: float=float(rb.hp)-rmax*.2
    check(healed_plain>0 and near(healed,healed_plain*.75),"Boss Breaker: boss heal x0.75 (%.0f vs %.0f)" % [healed,healed_plain])
    # Cleave: a basic hit also hits a neighbour within 32 units for 30%.
    fresh();grant(["expedition_c6"])
    var spot: Array=sim.state.enemies.filter(func(e):return int(e.group)==blue and int(e.variant)==2)
    var a: Dictionary=spot[0];var b: Dictionary=spot[1]
    b.x=float(a.x)+20;b.y=float(a.y)
    var hp_b: float=float(b.hp)
    sim.state.player.x=float(a.x)-10;sim.state.player.y=float(a.y)
    sim.state.player.target=a.id;sim.state.player.windup=.001
    sim._resolve_attack(sim.state.player,.1)
    check(float(b.hp)<hp_b,"Cleave: the neighbour takes damage too")
    # Broken Rally: a Summer II neighbour called into the fight waits 0.5 s.
    fresh();grant(["expedition_c7"])
    var cow: int=gi("unit-cowboy-bandana")
    sim.state.unlocked_stage=4;sim.state.camps["4"]=[0];sim.campaign.camp_action(4,0,true)
    var cs: Array=sim.state.enemies.filter(func(e):return int(e.group)==cow and int(e.variant)==2)
    for e in cs:e.aggro=false;e.cooldown=0.0
    sim.state.player.x=float(cs[0].x)+10;sim.state.player.y=float(cs[0].y)
    sim.state.player.target=cs[0].id;sim.state.player.windup=.001
    sim._resolve_attack(sim.state.player,.1)
    check(cs.slice(1).any(func(e):return e.aggro and float(e.cooldown)>=.5),"Broken Rally: pulled enemies start 0.5 s later")
    # Twin Find and Champion's Spoils: deterministic rolls through the loot path.
    fresh();grant(["collection_c4"])
    sim.state.upgrades["loot:%d" % blue]=0
    var twins:=0;var drops:=0
    for i in range(400):
        sim.state.pickups=[]
        sim._reward({"id":"g%d_v2_0" % blue,"group":blue,"variant":2,"x":10.0,"y":10.0})
        for p in sim.state.pickups:
            if sim.catalog.items[p.item].kind in ["weapon","outfit"]:
                drops+=1
                if int(p.get("qty",1))==2:twins+=1
    check(drops>0 and twins>0 and twins<drops,"Twin Find: some normal gear drops are two copies (%d of %d)" % [twins,drops])
    sim.state.pickups=[{"uid":999,"item":"wood_sword","qty":2,"x":0.0,"y":0.0,"ttl":100.0,"group":blue}]
    var q0=sim.quantity("wood_sword")
    check(sim.collect(999) and sim.quantity("wood_sword")==q0+2,"A two-copy pile adds both copies")
    fresh();grant(["trophy_c4"])
    var bd: Dictionary=sim.enemy_definition(snow)
    var first:=0;var later:=0
    for i in range(200):
        sim.state.pickups=[];sim.state.run_kills.erase("boss-snowman")
        sim._reward({"id":"g%d_v2_0" % snow,"group":snow,"variant":2,"x":10.0,"y":10.0})
        first+=sim.state.pickups.filter(func(p):return bd.loot.has(p.item)).size()
        sim.state.pickups=[];sim.state.run_kills["boss-snowman"]=1
        sim._reward({"id":"g%d_v2_0" % snow,"group":snow,"variant":2,"x":10.0,"y":10.0})
        later+=sim.state.pickups.filter(func(p):return bd.loot.has(p.item)).size()
    check(first>later*1.5,"Champion's Spoils: a first defeat this run rolls the loot twice (%d vs %d)" % [first,later])

func ui_checks() -> void:
    fresh()
    for op in sim.catalog.campaign.opportunities:sim.state.opportunities[op.id]={"ready":false,"baseline":{},"step":0,"count":0}
    sim.state.unlocked_stage=8
    game._open("prestige");await frames(2)
    var text:=""
    for l in game.rows.find_children("*","Label",true,false):text+=str(l.text)+"\n"
    for st in range(1,9):check(text.contains(str(sim.catalog.stages[st-1].name)),"Prestige panel lists %s" % sim.catalog.stages[st-1].name)
    game._close()
