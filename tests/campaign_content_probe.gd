extends Node
var checks=0
var failures=0
var sim
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func _ready() -> void:call_deferred("run")
func fresh() -> void:sim.new_profile();sim.rng.seed=456;SaveService.write_blocked=false
func run() -> void:
    sim=LootSimulation.new();add_child(sim);sim.set_physics_process(false)
    check(sim.catalog.campaign.cards.size()==33 and sim.catalog.campaign.opportunities.size()==33 and sim.catalog.campaign.combos.size()==17,"Complete unique prestige catalog")
    for op in sim.catalog.campaign.opportunities:
        fresh()
        sim.state.opportunities[op.id]={"ready":false,"baseline":{},"step":0,"count":0}
        var n=int(op.id.right(1));var o=sim.state.opportunities[op.id]
        match op.path:
            "hunter":sim.campaign.progress("boss",sim.campaign.boss_goal(op.path,n),20+10*n)
            "challenge":sim.campaign.progress("restricted",sim.campaign.boss_goal(op.path,n),1)
            "expedition","specialist":
                for q in sim.campaign.chain_for(op.id):
                    if q[0]=="merge":
                        sim.add_item("wood_sword",int(q[2])+1)
                        for i in range(q[2]):sim.merge("wood_sword")
                    else:sim.campaign.progress(q[0],q[1],q[2])
            "offline":sim.state.offline_total=72*3600;sim.state.offline_longest=24*3600;sim.state.offline_income=10000
            "masterwork":
                var id=["wood_sword","stone_sword","iron_sword"][n-1]
                sim.add_item(id,101);sim.merge(id,true)
            "arsenal":
                sim.state.gear.resize(30);sim.state.gear.fill("")
                # Change 7: weapons are shared families, so distinct weapons are distinct items.
                var weapons=["stone_sword","stone_axe","iron_sword"] if n==3 else ["wood_sword","wood_axe","stone_sword"]
                for id in weapons:sim.add_item(id,51);sim.merge(id,true)
                for family in ["unit-blue-cap","unit-red-scarf","unit-chef-hat"]:
                    var id=family+"_outfit"+("_t2" if n==3 else "")
                    sim.add_item(id,51);sim.merge(id,true)
            "regional":
                for st in ([1,2] if n==1 else ([3,4] if n==2 else [7,8])):
                    sim.state.stage=st;sim.campaign.configure_stage()
                    sim.state.camps[str(st)]=range(sim.campaign.stage().spawns.size())
                    sim.campaign.reveal_circle(Vector2.ZERO,5000)
                    for g in sim.campaign.stage().groups:sim.state.run_kills[sim.catalog.groups[g].id]=1
            "collection":
                sim.state.gear.resize(20);sim.state.gear.fill("")
                var names=[['blue-cap','red-scarf','chef-hat'],['straw-hat','sunglasses','yellow-cap'],['bunny-ears','cat-ears','elf-ears']][n-1]
                for name in names:
                    var id=sim.campaign.contract_outfit(name);sim.add_item(id,11+10*n)
                    sim.campaign.progress("collect",id,11+10*n);sim.campaign.progress("gear",id,11+10*n)
                check(sim.campaign.submit(op.id),"Collection transaction: "+op.id)
            "offering":
                sim.state.coins=1000000;sim.state.online_coins=1000000;sim.state.gems=1000;sim.state.online_gems=1000
                check(sim.campaign.submit(op.id),"Offering transaction: "+op.id)
            "trophy":
                for g in range(48):
                    if sim.catalog.groups[g].boss:sim.campaign.killed({"group":g,"encounter_uses":0})
        sim.campaign.evaluate()
        check(sim.state.opportunities[op.id].ready,"Opportunity reachable: "+op.id)
    fresh()
    for id in sim.catalog.campaign.cards:sim.state.owned_cards.append(id)
    for combo in sim.catalog.campaign.combos:check(sim.campaign.combo_owned(combo),"Combo resolves: "+combo.id)
    var before=sim.campaign.bonus("boss_damage");sim.campaign.evaluate();sim.campaign.evaluate()
    check(is_equal_approx(before,sim.campaign.bonus("boss_damage")),"Combo effects do not accumulate on reevaluation")
    fresh()
    # Challenge discovery is not a retroactive restricted kill; next clean encounter qualifies.
    # Change 6: the winter challenge is the Winter II gate boss (Cyan Robot).
    sim.state.stage=2;sim.state.unlocked_stage=2;sim._reset_world()
    var boss=sim.state.enemies.filter(func(a):return sim.catalog.groups[a.group].id=="boss-cyan-robot")[0]
    sim.campaign.begin_encounter(boss);sim.campaign.killed(boss)
    check(not sim.state.opportunities.challenge_o1.ready,"Discovery boss does not retroactively prove challenge")
    sim.campaign.begin_encounter(boss);sim.state.consumable_uses+=1;sim.campaign.killed(boss)
    check(not sim.state.opportunities.challenge_o1.ready,"Consumable invalidates current encounter")
    sim.campaign.begin_encounter(boss);sim.campaign.killed(boss)
    check(sim.state.opportunities.challenge_o1.ready,"Next clean encounter qualifies")
    # Each designated double gate must be completed in its own run.
    for st in [4,6,7]:
        fresh();sim.state.stage=st;sim.state.unlocked_stage=st;sim._reset_world()
        var gates=sim.campaign.stage().gates
        sim.campaign.killed({"group":sim.campaign.group_id(gates[0]),"encounter_uses":0})
        check(sim.state.unlocked_stage==st,"First boss does not unlock double gate")
        sim.campaign.killed({"group":sim.campaign.group_id(gates[1]),"encounter_uses":0})
        check(sim.state.unlocked_stage==st+1,"Both bosses unlock double gate")
    # Full output inventory: evolution must leave source and merge untouched.
    fresh();sim.add_item("wood_sword",201);sim.merge("wood_sword",true);sim.add_item("unit-blue-cap_outfit");sim.add_item("iron_sword")
    check(not sim.evolve("wood_sword") and sim.quantity("wood_sword")==101,"Evolution full-storage rollback")
    # Development-save reset policy replaces legacy migration/refunds.
    fresh();sim.add_item("wood_sword",4)
    var legacy=sim.snapshot();legacy.schema=5
    sim.restore(legacy)
    check(sim.state.schema==8 and sim.quantity("wood_sword")==0,"Old development saves reset explicitly")
    check(not SaveService.write_blocked and SaveService.save_now(),"Reset profile can save")
    var roundtrip=JSON.parse_string(JSON.stringify(sim.snapshot()));sim.restore(roundtrip)
    check(sim.state.schema==8 and not SaveService.write_blocked,"Current profile survives JSON round trip")
    # Change 9: realistic ceiling fixture. The old one equipped a legacy tier-7 outfit it never owned
    # (the equip failed silently, so no outfit was worn) and obsidian weapons no enemy drops. Every item
    # here must be dropped by an enemy (or be at most the best dropped weapon tier) and every equip must
    # succeed before damage and survival are computed. Full duels: tests/change_9_balance.
    fresh();sim.state.gear.resize(40);sim.state.gear.fill("");sim.state.player_level=240
    var best_drop:=0
    for d in sim.catalog.groups:best_drop=maxi(best_drop,int(sim.catalog.items[d.weapon].tier))
    var loadout:=[["emerald_sword",50],["boss-sunflower_outfit_t5",300],["diamond_sword",100],["diamond_axe",100],["gold_sword",100],["gold_axe",100]]
    for pair in loadout:
        var id: String=pair[0];var e: Dictionary=sim.catalog.items.get(id,{})
        var natural: bool=not e.is_empty() and not e.get("legacy",false) and (int(e.tier)<=best_drop if e.kind=="weapon" else sim.catalog.groups.any(func(d):return d.loot.has(id)))
        check(natural and sim.add_item(id,1),"Ceiling item exists and is obtainable: "+id)
        sim.record(id).merge=pair[1];sim.touch() # labelled: merge level
    check(sim.equip("emerald_sword") and sim.state.weapon=="emerald_sword","Ceiling weapon equip succeeds")
    check(sim.equip("boss-sunflower_outfit_t5") and sim.state.outfit=="boss-sunflower_outfit_t5","Ceiling outfit equip succeeds")
    var final=sim.catalog.groups[-1];var stats=sim.stats()
    var attack_dps=stats.damage*(1+stats.speed)*(1+stats.crit*(stats.crit_damage-1))
    var kill_seconds=final.hp/attack_dps
    var incoming_dps=final.damage/2.0*100/(100+stats.defense)-stats.hp*stats.regen_pct
    print("BALANCE_CEILING final_hp=",final.hp," final_damage=",final.damage," player_hp=",stats.hp," player_damage=",stats.damage," defense=",stats.defense," basic_TTK=",kill_seconds," basic_survival=",stats.hp/incoming_dps)
    check(kill_seconds<600,"Final boss basic-attack TTK is finite with realistic gear (skills and cards not counted)")
    # All successor definitions, including migrated legacy identities, obey intrinsic ratio.
    for id in sim.catalog.items:
        var d=sim.catalog.items[id]
        if d.next=="":continue
        for stat in d.normal:
            check(is_equal_approx(float(sim.catalog.items[d.next].normal[stat][0]),.85*(float(d.normal[stat][0])+100*float(d.merge_gain[stat]))),"85% catalog transition: "+id)
    sim.queue_free();await get_tree().process_frame
    print("CONTENT_PROBE checks=",checks," failures=",failures)
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(0 if failures==0 else 1)
