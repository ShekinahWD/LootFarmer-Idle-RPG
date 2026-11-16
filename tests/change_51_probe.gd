extends "res://tests/change_20_probe.gd"
## Change 51 (approved progression brief, B2): the H24 weapon ladder and 31-copy evolution.
## Catalog: sword bases 4 x1.9 per tier to Emerald, Obsidian = Emerald x2.4; axe 0.8x damage + 3x HP;
## 2%-of-base merge gain; one weapon tier per stage (bosses the same tier, final boss Obsidian Sword);
## Snowman first kill = Wood Axe. Rules: evolvable weapons merge to ^20, Obsidian to ^100; evolution
## spends 10 spares (31 copies in all), keeps the source's ^20 and last copy, adds one target copy at its
## own remembered level; Merge All / Auto-Merge leave the spares; Auto Evolution fires; repeat evolutions
## cost 10 each. Saves: owned old-stat weapons become legacy copies with their exact power until the next
## Prestige; the canonical id remembers their level; over-cap levels stay valid and keep their effect.
## Arsenal/Masterwork thresholds reachable; Spring Map Mastery forge asks for ^20 instead of an evolution.
## Runs with --first-run-complete.
const H24:=[4.0,7.6,14.44,27.436,52.1284,99.04396,237.705504]
const TIERS:=["wood","stone","iron","gold","diamond","emerald","obsidian"]
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    catalog_checks()
    evolution_checks()
    auto_checks()
    legacy_checks()
    opportunity_checks()
    print("CHANGE_51_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func near(a: float,b: float) -> bool:return absf(a-b)<=.0001*maxf(1.0,absf(b))
func g(id: String) -> int:return sim.campaign.group_id(id)

func catalog_checks() -> void:
    for t in range(7):
        var sw: Dictionary=sim.catalog.items[TIERS[t]+"_sword"];var ax: Dictionary=sim.catalog.items[TIERS[t]+"_axe"]
        var b: float=H24[t]
        check(near(float(sw.normal.damage[0]),b) and near(float(sw.merge_gain.damage),b*.02),"%s sword base %.3f, gain 2%%" % [TIERS[t],float(sw.normal.damage[0])])
        check(near(float(ax.normal.damage[0]),b*.8) and near(float(ax.normal.hp[0]),b*3.0) and near(float(ax.merge_gain.hp),b*3.0*.02),"%s axe 0.8x damage, 3x HP" % TIERS[t])
        check(sim.merge_cap(TIERS[t]+"_sword")==(500 if t==6 else 20),"%s merge cap (Obsidian ^500 since Change 81)" % TIERS[t])
    check(int(sim.catalog.progression.evolution.required_merge)==20 and sim.evolution_spare_cost()==10 and not sim.catalog.progression.evolution.has("base_multiplier"),"Evolution: ^20 + 10 spares, base multiplier retired")
    for d in sim.catalog.groups:
        for id in d.loot:
            var it: Dictionary=sim.catalog.items[id]
            if it.kind!="weapon":continue
            check(int(it.tier)==mini(int(d.stage),7) and not bool(it.get("legacy",false)),"%s (stage %d) drops tier %d %s" % [d.id,int(d.stage),int(it.tier),id])
            check(str(d.weapon)==id,"%s carries the weapon it drops" % d.id)
    check(sim.catalog.groups[g("boss-green-alien")].loot.has("obsidian_sword"),"The final boss drops an Obsidian Sword")
    check(str(sim.catalog.groups[g("boss-snowman")].weapon)=="wood_axe","The Snowman carries (and guarantees) the Wood Axe")
    fresh()
    var snow:=g("boss-snowman")
    sim.state.group_kills[snow]=1
    var dropped: Array=[]
    var a:={"id":"g%d_v2_0" % snow,"group":snow,"x":100.0,"y":100.0}
    check(sim.campaign.onboarding.boss_first_kill(a,sim.enemy_definition(snow),dropped)==["wood_axe"],"The Snowman's first defeat drops a Wood Axe")
    # Old stats are kept only on legacy copies, never dropped.
    for t in range(1,7):
        for fam in ["sword","axe"]:
            var lid: String=TIERS[t]+"_"+fam+"_legacy"
            check(sim.catalog.items.has(lid) and sim.is_legacy(lid) and str(sim.catalog.items[lid].next)=="" and sim.droppers(lid).is_empty(),"%s exists, never drops, never evolves" % lid)

func evolution_checks() -> void:
    fresh()
    sim.state.merge_memory["stone_sword"]=7
    check(sim.add_item("wood_sword",31),"31 Wood Swords")
    check(sim.merge("wood_sword",true) and int(sim.record("wood_sword").merge)==20 and sim.quantity("wood_sword")==11,"Merge (all copies) stops at ^20 with 11 copies left")
    check(not sim.can_merge("wood_sword") and not sim.merge("wood_sword"),"No merge past ^20")
    sim.state.upgrades["merge_all"]=1
    check(sim.merge_all().copies==0 and sim.quantity("wood_sword")==11,"Merge All leaves the 10 spares")
    check(sim.evolve_block_reason("wood_sword")=="","Evolution is available at ^20 with 10 spares")
    check(sim.evolve("wood_sword"),"Evolve")
    check(sim.quantity("wood_sword")==1 and int(sim.record("wood_sword").merge)==20,"The source keeps ^20 and one copy")
    check(sim.quantity("stone_sword")==1 and int(sim.record("stone_sword").merge)==7,"Exactly one Stone Sword, at its own remembered ^7 (never the source's ^20)")
    check(sim.evolve_block_reason("wood_sword")=="EVOLUTION_NEEDS_COPIES","A repeat evolution needs 10 more spares")
    sim.add_item("wood_sword",9)
    check(sim.evolve_block_reason("wood_sword")=="EVOLUTION_NEEDS_COPIES","9 spares are not enough")
    sim.add_item("wood_sword",1)
    check(sim.evolve("wood_sword") and sim.quantity("stone_sword")==2 and int(sim.record("stone_sword").merge)==7 and sim.quantity("wood_sword")==1,"The repeat evolution adds one copy to the existing stack without touching its level")

func auto_checks() -> void:
    fresh()
    var blue:=g("unit-blue-cap")
    sim.state.upgrades["merge_gear:%d" % blue]=1
    sim.state.upgrades["auto_evolve:%d" % blue]=1
    sim.add_item("wood_sword",31)
    for i in range(40):sim.campaign.merge_cycle(str(blue),0.0,1.0,blue)
    check(int(sim.record("wood_sword").merge)==20 and sim.quantity("wood_sword")==11,"Auto-Merge stops at ^20 and keeps the spares")
    sim.campaign.evolve_clock=1.0;sim.campaign.auto_evolve()
    check(sim.quantity("stone_sword")==1 and sim.quantity("wood_sword")==1,"Auto Evolution fires once")
    sim.campaign.evolve_clock=1.0;sim.campaign.auto_evolve()
    check(sim.quantity("stone_sword")==1,"No loop: nothing more to evolve")

## A current-schema save from before this change: owned Iron Sword ^100 equipped, a Gold Axe ^30 stored,
## a Wood Sword (tier 1, unchanged) and a spent Diamond Sword record.
func legacy_checks() -> void:
    fresh()
    sim.add_item("iron_sword",2);sim.record("iron_sword").merge=100;sim.equip("iron_sword")
    sim.add_item("gold_axe",1);sim.record("gold_axe").merge=30
    sim.add_item("wood_sword",3);sim.record("wood_sword").merge=5
    sim.state.items["diamond_sword"]={"qty":0,"merge":40,"extras":{}}
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    snap.migrations=["schema9_merge_memory"]
    sim.restore(snap)
    check(not sim.state.items.has("iron_sword") and sim.quantity("iron_sword_legacy")==2 and int(sim.record("iron_sword_legacy").merge)==100,"The owned Iron Sword ^100 becomes its legacy copy")
    check(sim.state.weapon=="iron_sword_legacy" and sim.state.gear.has("iron_sword_legacy"),"…still equipped, same slot")
    # Old power at ^100, with the unchanged at-cap stock bonus (+0.05% per spare copy).
    check(near(float(sim.normal("iron_sword_legacy").damage),(26.01+.5202*100)*1.0005),"…with exactly its old power %.2f" % float(sim.normal("iron_sword_legacy").damage))
    check(sim.quantity("gold_axe_legacy")==1 and sim.quantity("wood_sword")==3 and not sim.state.items.has("wood_sword_legacy"),"Gold Axe converts; tier 1 Wood Sword (unchanged stats) stays")
    check(sim.state.items.has("diamond_sword") and not sim.state.items.has("diamond_sword_legacy"),"A spent record (no copy) stays canonical")
    check(int(sim.state.merge_memory.get("iron_sword",0))==100 and int(sim.state.merge_memory.get("gold_axe",0))>=30,"The canonical ids remember the legacy copies' levels")
    check(sim.state.migrations.has("legacy_weapons_h24"),"Migration recorded")
    var again: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    sim.restore(again)
    check(sim.quantity("iron_sword_legacy")==2 and not sim.state.items.has("iron_sword_legacy_legacy"),"Loading again converts nothing twice")
    check(not sim.can_merge("iron_sword_legacy"),"A legacy copy above its cap cannot merge further")
    check(not sim.campaign.offline_snapshot().eligible.weapon.has("iron_sword_legacy"),"Offline gear never copies legacy weapons")
    check(sim.catalog.display_name("iron_sword_legacy").contains(sim.catalog.display_name("iron_sword")),"Legacy name shows the weapon (%s)" % sim.catalog.display_name("iron_sword_legacy"))
    # Over-cap canonical level: valid, full effect, no further merge.
    fresh()
    sim.add_item("stone_sword",3);sim.record("stone_sword").merge=60
    var v: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    check(sim.campaign.valid_snapshot(sim.campaign.normalize_snapshot(v)),"A Stone Sword ^60 save is valid")
    check(near(float(sim.normal("stone_sword").damage),(7.6+.152*60)*1.001) and not sim.can_merge("stone_sword"),"^60 keeps its full effect (plus the at-cap stock bonus) and cannot merge further")
    # After a Prestige the legacy copy leaves; finding the weapon again: new stats, remembered level.
    fresh()
    sim.add_item("iron_sword_legacy",1);sim.record("iron_sword_legacy").merge=100
    sim.state.merge_memory["iron_sword"]=100
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman")
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    check(sim.campaign.begin_prestige() and sim.campaign.choose_card(str(sim.campaign.offered_cards()[0])),"Prestige")
    check(sim.quantity("iron_sword_legacy")==0 and not sim.state.merge_memory.has("iron_sword_legacy"),"The legacy copy leaves with the inventory and is never remembered")
    check(sim.add_item("iron_sword") and int(sim.record("iron_sword").merge)==100 and near(float(sim.normal("iron_sword").damage),14.44*3.0),"A new Iron Sword: new stats at the remembered ^100")

func opportunity_checks() -> void:
    fresh()
    sim.state.opportunities["arsenal_o1"]={"ready":false,"baseline":{},"step":0,"count":0,"merge_wood_sword":20,"merge_unit-blue-cap_outfit":50}
    sim.state.opportunities["masterwork_o1"]={"ready":false,"baseline":{},"step":0,"count":0,"merge_wood_sword":100}
    sim.campaign.evaluate()
    check(sim.state.opportunities.arsenal_o1.ready,"Arsenal I: a weapon at ^20 and an outfit at ^50")
    check(not sim.state.opportunities.masterwork_o1.ready,"Masterwork I ignores evolvable weapons")
    sim.state.opportunities.masterwork_o1["merge_obsidian_sword"]=100
    sim.campaign.evaluate()
    check(sim.state.opportunities.masterwork_o1.ready,"Masterwork I: an Obsidian weapon at ^100")
    sim.state.opportunities["arsenal_o3"]={"ready":false,"baseline":{},"step":0,"count":0,"merge_stone_sword":20,"merge_stone_axe":20,"merge_iron_axe":20,"merge_unit-straw-hat_outfit_t2":50,"merge_unit-sunglasses_outfit_t2":50,"merge_unit-yellow-cap_outfit_t2":50}
    sim.campaign.evaluate()
    check(sim.state.opportunities.arsenal_o3.ready,"Arsenal III: three tier 2+ weapons at ^20 and three tier 2+ outfits at ^50")
    for st in [7,8]:
        var parts: Array=sim.campaign.mastery.objective(st,"forge").parts
        check(str(parts.back()[0])=="weapon_merge" and int(parts.back()[3])==20,"Spring map %d forge asks for an Obsidian weapon at ^20" % st)
    check(str(sim.campaign.mastery.objective(3,"forge").parts.back()[0])=="evolve","Earlier maps still ask for an evolution")
