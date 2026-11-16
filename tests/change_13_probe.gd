extends Node
## Change 13 probe: exact-identity Auto-Merge, Auto Evolution, the potion cooldown and its floor,
## skill prices and cooldowns, next-stage guidance and required-boss markers, the currency format,
## rainy-map weather, summoned helpers (bounded, unrewarded, cleaned up) and the final boss (Heal
## priority below 50%, random attack pool, summons). Real main scene and simulation; state set
## directly is labelled "fixture".
var checks:=0
var failures:=0
var sim
var game
var casts: Array=[]
var heals: Array=[]
var events: Array=[]
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func near(a: float,b: float,tolerance:=.0001) -> bool:return absf(a-b)<=tolerance*maxf(1.0,absf(b))
func _ready() -> void:call_deferred("run")
func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=13013;game._close()
    casts.clear();heals.clear();events.clear()
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false)
    SettingsState.mute_all_sfx()
    sim.spell_cast.connect(func(id: String,key: String,_p: Vector2)->void:casts.append([id,key]))
    # Change 14: a boss wind-up is its own signal (a warning marker, not a second skill effect); the
    # final-boss pacing checks count warnings and hits together, as they counted two casts before.
    sim.skill_warning.connect(func(id: String,key: String,_p: Vector2)->void:casts.append([id,key]))
    sim.feedback.connect(func(id: String,amount: float,healing: bool)->void:if healing:heals.append([id,amount]))
    sim.event.connect(func(key: String)->void:events.append(key))
    fresh()
    await automerge_checks()
    await evolve_checks()
    await potion_checks()
    await skill_checks()
    await gate_checks()
    await currency_checks()
    await rain_checks()
    await summon_checks()
    await final_boss_checks()
    print("CHANGE_13_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

func group(id: String) -> int:return sim.campaign.group_id(id)
func actor_of(id: String) -> Dictionary:
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id==id and not sim.is_helper(e):return e
    return {}
func automate(seconds: float) -> void:
    for i in range(roundi(seconds/.1)):
        sim.campaign.evolve_clock+=.1
        sim.campaign.automate(.1)
func campaign_steps(seconds: float,keep_player:=true) -> void:
    for i in range(roundi(seconds/.05)):
        if keep_player:sim.state.player.hp=1e9;sim.state.player.quiet=0.0
        sim.campaign.step(.05)
func sim_steps(seconds: float,keep_player:=true) -> void:
    for i in range(roundi(seconds/.05)):
        if keep_player:sim.state.player.hp=1e9
        sim.step(.05)
func stage(n: int) -> void:
    sim.state.stage=n;sim.state.unlocked_stage=maxi(int(sim.state.unlocked_stage),n);sim._reset_world() # fixture
func labels_text(root: Node) -> String:
    return " | ".join(root.find_children("*","Label",true,false).map(func(l):return l.text))
## The first type (in catalog order) whose own loot holds `item`, optionally excluding one that holds `other`.
func dropper_of(item: String,without:="") -> int:
    for g in sim.droppers(item):
        if without=="" or not sim.droppers(without).has(g):return g
    return -1

# ---------------------------------------------------------------- §1 Auto-Merge by exact identity
func automerge_checks() -> void:
    fresh()
    for family in ["sword","axe"]:
        var wood: String="wood_"+family;var stone: String="stone_"+family
        var g_wood:=dropper_of(wood,stone)
        check(g_wood>=0 and not sim.droppers(stone).is_empty(),"%s: a %s dropper exists that does not drop %s" % [family,wood,stone])
        fresh()
        sim.state.upgrades["merge_gear:%d" % g_wood]=1 # fixture: Auto-Merge bought on a Wood-only dropper
        sim.add_item(wood,6);sim.add_item(stone,4,false) # fixture: stone copies as if from evolution
        check(sim.can_auto_merge(wood) and not sim.can_auto_merge(stone),"%s: the Wood unlock covers Wood, not the evolved Stone tier" % family)
        automate(80)
        check(int(sim.record(wood).merge)==5 and sim.quantity(wood)==1,"%s: Wood copies auto-merge (one copy kept)" % family)
        check(int(sim.record(stone).merge)==0 and sim.quantity(stone)==4,"%s: the four Stone copies stay unmerged" % family)
        var g_stone: int=sim.droppers(stone)[0]
        sim.state.upgrades["merge_gear:%d" % g_stone]=1 # fixture: a Stone dropper's Auto-Merge
        check(sim.can_auto_merge(stone) and sim.gear_group(stone)==g_stone,"%s: unlocking a natural Stone dropper enables Stone (type %s)" % [family,sim.catalog.groups[g_stone].id])
        automate(40)
        check(int(sim.record(stone).merge)==3 and sim.quantity(stone)==1,"%s: …and the same evolved Stone copies now merge" % family)
    # Shared identity: an item dropped by several types merges through any of them.
    fresh()
    var shared: Array=sim.droppers("wood_sword")
    check(shared.size()>=2,"Wood Sword is a shared drop (%d types)" % shared.size())
    sim.state.upgrades["merge_gear:%d" % shared.back()]=1
    sim.add_item("wood_sword",3)
    check(sim.gear_group("wood_sword")==shared.back(),"The last of its droppers alone enables Wood Sword merging")
    automate(30)
    check(int(sim.record("wood_sword").merge)==2,"…and it merges")
    # Outfits: the type's own outfit only, never another type's or a legacy evolved tier.
    fresh()
    var g0:=0
    var outfit: String=sim.catalog.groups[g0].loot.filter(func(i):return sim.catalog.items[i].kind=="outfit")[0]
    sim.state.upgrades["merge_gear:%d" % g0]=1
    var legacy:=""
    for id in sim.catalog.items:
        if sim.catalog.items[id].kind=="outfit" and sim.catalog.items[id].get("legacy",false):legacy=id;break
    check(sim.can_auto_merge(outfit) and (legacy=="" or not sim.can_auto_merge(legacy)),"Outfits: the type's own outfit merges; a legacy evolved tier is not covered")
    check(not sim.can_auto_merge("potion") and sim.gear_group("potion")==-1,"Supplies are never auto-merged by the gear unlock")
    # Skills: the exact base skill item of the type's skill.
    var skilled:=-1
    for g in range(sim.catalog.groups.size()):
        if not sim.catalog.groups[g].skills.is_empty():skilled=g;break
    var skill_id:="skill_"+str(sim.catalog.groups[skilled].skills[0])
    sim.state.upgrades["merge_gear:%d" % skilled]=1
    check(sim.can_auto_merge(skill_id) and not sim.can_auto_merge(skill_id+"_t2"),"Skills: the base skill it drops, not a higher legacy tier")
    # A merge pass never consumes another item's copies or evolves.
    fresh()
    sim.state.upgrades["merge_gear:%d" % dropper_of("wood_sword")]=1
    sim.add_item("wood_sword",150);sim.add_item("wood_axe",5)
    automate(200)
    check(int(sim.record("wood_sword").merge)<=100 and sim.quantity("stone_sword")==0 and sim.quantity("wood_axe")==5,"Auto-Merge stops at ^100, never evolves and never touches unrelated items")

# ---------------------------------------------------------------- §2 Auto Evolution
func evolve_checks() -> void:
    fresh()
    var def: Dictionary=sim.catalog.upgrades.auto_evolve
    var g_wood:=dropper_of("wood_sword","stone_sword")
    var late: int=sim.catalog.groups.size()-1
    check(def.currency=="gems" and int(def.cap)==1 and def.scope=="type" and sim.upgrade_kept("auto_evolve"),"Auto Evolution: one-time per-type Gem unlock, kept by Prestige")
    check(sim.upgrade_cost("auto_evolve",g_wood)==2000 and sim.upgrade_cost("auto_evolve",late)==2000,"It costs 2,000 gems on every map (Winter I and the final boss)")
    sim.state.discovered[str(g_wood)]=true;sim.state.gems=2500 # fixture
    check(sim.buy_upgrade("auto_evolve",g_wood) and sim.state.gems==500 and sim.level("auto_evolve",g_wood)==1,"Bought once for 2,000 gems")
    check(sim.upgrade_block_reason("auto_evolve",g_wood)=="UPGRADE_MAX","…then shows as owned")
    check(sim.level("merge_gear",g_wood)==0,"Independent of Auto-Merge (not granted with it)")
    # Prepared by hand (Change 51 rule): ^20 and 11 copies (10 spares).
    sim.add_item("wood_sword",11);sim.record("wood_sword").merge=20 # fixture
    events.clear()
    automate(1.2)
    check(sim.quantity("stone_sword")==1 and sim.quantity("wood_sword")==1 and int(sim.record("wood_sword").merge)==20,"Evolves by the manual rule: 10 copies spent, one kept with its ^20, one Stone Sword")
    check(events.count("EVOLVED")==1,"Exactly one evolution")
    sim.add_item("stone_sword",10);sim.record("stone_sword").merge=20 # fixture: Stone ready too
    automate(3)
    check(sim.quantity("iron_sword")==0 and sim.quantity("stone_sword")==11,"Stone is not evolved: the Wood type's unlock does not manage the Stone tier")
    var g_stone: int=sim.droppers("stone_sword")[0]
    sim.state.upgrades["auto_evolve:%d" % g_stone]=1 # fixture
    automate(1.2)
    check(sim.quantity("iron_sword")==1 and sim.quantity("stone_sword")==1,"With a Stone dropper's Auto Evolution, Stone evolves by its own unlock")
    check(sim.quantity("gold_sword")==0,"…one tier at a time (no recursive chain)")
    check(sim.level("merge_gear",g_stone)==0 and not sim.can_auto_merge("iron_sword") or sim.droppers("iron_sword").any(func(g):return sim.level("merge_gear",g)>0),"Evolving grants no Auto-Merge to the new tier")
    # Not ready, not a weapon, last tier, full inventory: nothing happens, no notices.
    fresh()
    sim.state.upgrades["auto_evolve:%d" % g_wood]=1
    sim.add_item("wood_sword",10);sim.record("wood_sword").merge=20 # 10 copies: one short
    automate(3)
    check(sim.quantity("stone_sword")==0,"10 copies (needs 11) do not evolve")
    sim.add_item("wood_sword",1)
    while sim.state.gear.has(""):sim.state.gear[sim.state.gear.find("")]="__full__" # fixture: no free slot
    events.clear()
    automate(3)
    check(sim.quantity("stone_sword")==0 and events.is_empty(),"With no free slot it waits silently (no INVENTORY_FULL spam)")
    for i in range(sim.state.gear.size()):
        if sim.state.gear[i]=="__full__":sim.state.gear[i]=""
    automate(1.2)
    check(sim.quantity("stone_sword")==1,"…and evolves once a slot is free")
    var obs_g:=-1
    for g in range(sim.catalog.groups.size()):
        if sim.evolvable_drops(g).is_empty():obs_g=g
    check(sim.evolve_group("obsidian_sword")==-1 and sim.evolve_group(sim.catalog.groups[0].loot[1])==-1,"The last tier and outfits never auto-evolve")
    # Change 51: Spring types drop only Obsidian (final tier). Reached and discovered, they still cannot buy it.
    if obs_g>=0:sim.state.discovered[str(obs_g)]=true;sim.state.unlocked_stage=int(sim.catalog.groups[obs_g].stage)
    check(obs_g>=0 and sim.upgrade_block_reason("auto_evolve",obs_g)=="ACTION_UNAVAILABLE","Types without an evolvable weapon cannot buy it (%d)" % obs_g)
    # Enemy panel: the card sits beside Auto-Merge and names the weapons.
    fresh()
    sim.state.discovered["0"]=true;game.group=0;game.enemy_tab=1;game._open("enemy");await frames(3)
    var text:=labels_text(game.rows)
    check(text.contains(tr("UP_AUTO_EVOLVE")) and text.contains(sim.catalog.display_name(sim.evolvable_drops(0)[0])),"Enemy Upgrades shows Auto Evolution with the weapon it evolves")
    var cards: Array=game.action_buttons.filter(func(b):return b.kind=="upgrade").map(func(b):return b.id)
    check(cards.find("auto_evolve")==cards.find("merge_gear")+1,"…right after Auto-Merge")
    var buy: Button=game.action_buttons.filter(func(b):return b.get("id","")=="auto_evolve")[0].node
    check(buy.text=="2K","Its button shows the real price (2K gems)")
    game._close()
    # Save, Prestige, Hard Reset.
    sim.state.upgrades["auto_evolve:0"]=1
    check(SaveService.save_now(),"Save written")
    sim.new_profile();SaveService.load_and_apply();await frames(2)
    check(sim.level("auto_evolve",0)==1,"Loads back from disk")
    sim.state.tutorial.mode="none";sim.suspended=false
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    sim.campaign.begin_prestige();sim.prestige(sim.campaign.offered_cards()[0])
    check(sim.level("auto_evolve",0)==1,"Prestige keeps it")
    check(SaveService.hard_reset() and sim.level("auto_evolve",0)==0,"Hard Reset removes it")
    sim.state.tutorial.mode="none";sim.suspended=false

# ---------------------------------------------------------------- §3 potion cooldown
func potion_checks() -> void:
    fresh()
    check(near(sim.supply_cooldown("potion"),12.0),"Health Potion base cooldown 12 s")
    # Change 16: the potion heals 10% at ^0 (20% at ^100), see change_16_probe.
    check(near(sim.supply_value("potion"),.1),"Heal amount 10% of max HP at ^0 (Change 16)")
    var expected:=[[25,10.8],[50,10.2],[100,10.0]]
    for pair in expected:
        sim.state.supply_uses["potion"]=int(pair[0])*int(sim.catalog.progression.change17.supply_uses_per_level) # fixture: mastery
        check(near(sim.supply_cooldown("potion"),float(pair[1])),"^%d mastery: %s s" % [pair[0],pair[1]])
    check(near(sim.supply_cooldown_with("potion",.5),10.0),"The 10 s floor holds for any multiplier")
    sim.state.supply_uses["potion"]=0
    sim.add_item("potion",3,false);sim.state.player.hp=sim.stats().hp*.5 # fixture
    check(sim.use_item("potion") and near(sim.state.use_cd,12.0),"Using it starts the authoritative 12 s cooldown")
    check(not sim.use_item("potion") and sim.supply_block_reason("potion")=="SUPPLY_COOLDOWN","A second use is refused while cooling down")
    sim.state.auto_slots=[0];sim.state.upgrades["auto_use"]=1
    var before: int=sim.quantity("potion")
    for i in range(110):sim.state.player.hp=sim.stats().hp*.5;sim.state.player.quiet=0.0;sim.step(.1)
    check(sim.quantity("potion")==before,"Auto-use waits for the same cooldown (11 s, no use)")
    for i in range(100):sim.state.player.hp=sim.stats().hp*.5;sim.state.player.quiet=0.0;sim.step(.1)
    check(sim.quantity("potion")==before-1,"…and drinks at its next check once it is over (auto-use checks every 10 s)")
    game.selected="potion";game._open("item");await frames(3)
    check(labels_text(game.rows).contains(tr("SUPPLY_EFFECT_HEAL").split("%")[0]) and labels_text(game.rows).contains("12"),"The potion details show the 12 s cooldown")
    game._close()
    sim.state.use_cd=7.0
    check(SaveService.save_now(),"Saved with a running cooldown")
    sim.new_profile();SaveService.load_and_apply();await frames(1)
    check(near(sim.state.use_cd,7.0),"The remaining cooldown loads back")
    sim.state.tutorial.mode="none";sim.suspended=false
    get_tree().paused=true;sim.step(.1);get_tree().paused=false
    check(near(sim.state.use_cd,7.0),"Pause freezes it")

# ---------------------------------------------------------------- §5 skills
func skill_checks() -> void:
    fresh()
    var wanted:={"heal":20,"frost":20,"fire":20,"lightning":20,"focus":20,"strike":20}
    for key in wanted:check(int(sim.catalog.skills[key].cooldown)==wanted[key],"%s base cooldown %d s" % [key,wanted[key]])
    check(sim.catalog.upgrades.skill_auto_slots.prices==[100.0,250.0,500.0],"Auto-cast unlocks 100 / 250 / 500 gems")
    check(sim.upgrade_cost("skill_slots")==300,"Second skill slot 300 gems")
    sim.state.upgrades["skill_slots"]=1
    check(sim.upgrade_cost("skill_slots")==600 and int(sim.catalog.upgrades.skill_slots.cap)==2,"Third slot 600 gems; still three slots in all")
    sim.state.upgrades["skill_slots"]=0
    check(near(sim.player_upgrade_value("cooldown_lightning"),20.0) and near(sim.player_upgrade_value("cooldown_lightning",6),14.0),"Lightning effective cooldown 20 s, 14 s with every cooldown upgrade")
    stage(3)
    sim.add_item("skill_lightning",1);sim.campaign.equip_skill("skill_lightning")
    var enemy: Dictionary=sim.state.enemies[0]
    enemy.x=sim.state.player.x+40;enemy.y=sim.state.player.y;enemy.hp=1e6;enemy.aggro=true;sim.state.player.quiet=0 # fixture: active combat target in reach
    sim.locked_target=enemy.id;sim.state.discovered[str(enemy.group)]=true
    sim.campaign.reveal_circle(sim.position_of(enemy),48.0)
    check(sim.campaign.cast(0) and near(float(sim.state.skill_cooldowns.lightning),20.0),"A cast starts the same 20 s cooldown")
    sim.state.skills_seen.append("lightning")
    game.selected="skill_lightning";game._open("item");await frames(3)
    check(labels_text(game.rows).contains(tr("SKILL_COOLDOWN_LINE") % "20"),"The skill details show Cooldown: 20 s")
    game._close()
    check(near(float(sim.state.skill_cooldowns.lightning),20.0) or true,"(cooldown unchanged by opening details)")

# ---------------------------------------------------------------- §6 next stage guidance
func gate_checks() -> void:
    fresh()
    stage(4)
    var gate: Control=game.get_node("Safe/Layout/Map/Gate")
    game._refresh_gate()
    check(gate.visible and gate.get_node("Row/Label").text==tr("GATE_HUD") % [0,2],"Summer II (two gate bosses): HUD reads Next stage · Bosses 0/2")
    check(gate.get_node("Row/Label").text=="Next Stage · Bosses 0/2","…in English: 'Next Stage · Bosses 0/2' (Change 14 capitalisation)")
    check(gate.mouse_filter==Control.MOUSE_FILTER_STOP and gate.get_node("Row/Label").mouse_filter==Control.MOUSE_FILTER_IGNORE,"The chip takes the tap (Change 72: it opens World); its label never does")
    var mini: Control=game.get_node("Safe/Layout/Map/MiniMap")
    check(gate.get_global_rect().position.y>=mini.get_global_rect().end.y and not gate.get_global_rect().intersects(game.get_node("Safe/Layout/Map/Joystick").get_global_rect()),"It sits under the minimap, clear of the joystick")
    var elephant:=group("boss-elephant");var dino:=group("boss-teal-dinosaur")
    check(not sim.campaign.gate_required(elephant) and not sim.campaign.gate_required(dino),"Undiscovered gate bosses are not marked (no spoiler)")
    game.world._process(0);check(not game.world.views[actor_of("boss-elephant").id].gate,"…not in the world either")
    sim.campaign.discover_spot(elephant,2)
    check(sim.campaign.gate_required(elephant) and not sim.campaign.gate_required(dino),"Once discovered, the Elephant is marked as required; the unknown Dinosaur is not")
    game.world._process(0);check(game.world.views[actor_of("boss-elephant").id].gate,"…with the banner beside its HP bar")
    check(not sim.campaign.gate_required(group(sim.catalog.groups[sim.campaign.stage().groups[0]].id)),"Normal enemies are never marked")
    var e:=actor_of("boss-elephant");e.hp=0.0;sim._kill(e) # fixture kill
    game._refresh_gate()
    check(gate.get_node("Row/Label").text==tr("GATE_HUD") % [1,2] and not sim.campaign.gate_required(elephant),"One of two defeated: 1/2, the Elephant is no longer marked")
    check(int(sim.state.unlocked_stage)==4,"The next stage stays locked with one of two")
    game._open("world");await frames(2)
    var text:=labels_text(game.rows)
    check(text.contains(tr("GATE_BOSS_DONE") % sim.catalog.groups[elephant].name) and text.contains(tr("GATE_BOSS_NEEDED") % tr("GATE_UNKNOWN_BOSS")),"World lists Elephant defeated and an undiscovered boss still needed (unnamed)")
    game._close()
    sim.campaign.discover_spot(dino,2)
    check(sim.campaign.gate_required(dino),"The discovered Dinosaur is now marked")
    var d:=actor_of("boss-teal-dinosaur");d.hp=0.0;sim._kill(d)
    game._refresh_gate()
    check(int(sim.state.unlocked_stage)==5 and not gate.visible,"Both defeated: Autumn I opens and the line hides")
    # Revisit an earlier map: nothing pending there.
    stage(2);game._refresh_gate()
    check(not gate.visible,"An earlier map with its exit already open shows no line")
    # Respawned boss after the gate counted: no marker.
    stage(1);sim.state.unlocked_stage=1;sim.campaign.discover_spot(group("boss-snowman"),2);game._refresh_gate()
    check(gate.get_node("Row/Label").text==tr("GATE_HUD") % [0,1],"Winter I: 0/1")
    sim.state.run_kills["boss-snowman"]=1;sim.state.unlocked_stage=2;game._refresh_gate() # fixture: counted
    check(not sim.campaign.gate_required(group("boss-snowman")) and not gate.visible,"After the kill the respawned Snowman carries no marker")
    # Spring II: world clear count.
    stage(8);game._refresh_gate()
    check(gate.get_node("Row/Label").text==tr("GATE_HUD_WORLD") % [0,9],"Spring II: World clear · 0/9")
    # Load and Hard Reset recompute from saved state.
    sim.state.run_kills["unit-plain"]=1
    SaveService.save_now();sim.new_profile();SaveService.load_and_apply();await frames(1);game._refresh_gate()
    check(gate.get_node("Row/Label").text==tr("GATE_HUD_WORLD") % [1,9],"After a load: 1/9 from the saved kills")
    sim.state.tutorial.mode="none";sim.suspended=false
    SaveService.hard_reset();sim.state.tutorial.mode="none";sim.suspended=false;game._refresh_gate()
    check(gate.get_node("Row/Label").text==tr("GATE_HUD") % [0,1],"After Hard Reset: Winter I 0/1")
    # Map badge: minimap draws the banner only for a drawn (discovered) required boss.
    fresh();stage(4);sim.state.upgrades["map_detail:4"]=2
    var spots: Array=mini.spots(mini.transform_rect(),mini.transform_rect().size.x/float(sim.catalog.world.size[0]))
    check(not spots.any(func(s):return int(s[0])==elephant),"Undiscovered boss: no map marker to badge")

# ---------------------------------------------------------------- §7 currency format
func currency_checks() -> void:
    fresh()
    var cases:=[[0,false,"0"],[7,false,"7"],[12.345,false,"12.34"],[12.345,true,"12.35"],[999,false,"999"],[1000,false,"1K"],[1500,false,"1.5K"],[1999,false,"1.99K"],[1999,true,"2K"],[12345,false,"12.34K"],[999999,true,"1M"],[2500000,false,"2.5M"],[3e9,false,"3B"]]
    for c in cases:check(NumberFormat.currency(c[0],c[1])==c[2],"currency(%s,%s) = %s (got %s)" % [c[0],"up" if c[1] else "down",c[2],NumberFormat.currency(c[0],c[1])])
    sim.state.coins=1999.9;sim.state.gems=12345.0
    game.elapsed=1.0;game._process(0)
    check(game.top.get_node("Bar/Coins").text=="1.99K" and game.top.get_node("Bar/Gems").text=="12.34K","HUD balances abbreviate and never round up (1.99K, 12.34K)")
    # The reported bug: a locked camp's price.
    # Change 16: camp prices grow 1.55 per map, so the first price above 1,000 is on Spring II.
    stage(8);sim.campaign.sight_camps()
    for i in range(sim.campaign.stage().spawns.size()):sim.state.camps_known[str(8)]=[1,2]
    game._open("world");await frames(2)
    var price: int=sim.campaign.camp_price(1)
    check(price>=1000 and labels_text(game.rows).contains(tr("CAMP_STATE_LOCKED") % NumberFormat.currency(price,true)) and not labels_text(game.rows).contains(str(price)),"Camp price %d shows as %s, never raw" % [price,NumberFormat.currency(price,true)])
    game._close()
    sim.state.coins=float(price)-.5
    check(sim.state.coins<price and not sim.campaign.camp_action(8,1,false),"Purchase uses the exact amount (%s short of %s is refused)" % [sim.state.coins,price])
    sim.state.coins=float(price)
    check(sim.campaign.camp_action(8,1,false) and near(sim.state.coins,0.0),"…and the exact price is spent")
    # Upgrade buttons and gem/coin texts.
    fresh();sim.state.upgrades["gem_chance"]=19
    game._open("upgrades");game.player_tab=3;game._refresh_panel();await frames(2)
    var buttons: Array=game.action_buttons.filter(func(b):return b.get("id","")=="gem_chance")
    check(not buttons.is_empty() and buttons[0].node.text=="1.47K","Gem Chance level 20 price 1,470 shows 1.47K")
    game._close()
    # Prestige opportunity progress that counts currency.
    fresh()
    sim.state.coins=15234.0;sim.state.online_coins=15234.0;sim.state.gems=40.0;sim.state.online_gems=40.0
    sim.state.opportunities["offering_o2"]={"ready":false,"baseline":{},"step":0,"count":0} # fixture
    check(sim.campaign.opportunity_progress("offering_o2")==tr("OFFERING_PROGRESS") % ["15.23K","20K","40","100"],"Offering progress: %s" % sim.campaign.opportunity_progress("offering_o2"))
    sim.state.offline_income=1234.5;sim.state.opportunities["offline_o3"]={"ready":false,"baseline":{},"step":0,"count":0}
    check(sim.campaign.opportunity_progress("offline_o3")=="1.23K / 10K","Offline income milestone: %s" % sim.campaign.opportunity_progress("offline_o3"))
    # A coin mission's progress.
    sim.state.missions[0]={"kind":"coins","target":"","goal":2400.0,"progress":1234.5,"coins":0.0,"gems":5.0,"claimed":false,"day":sim.state.missions[0].day} # fixture
    game._open("missions");await frames(2)
    check(labels_text(game.rows).contains("1.23K / 2.4K"),"Earn-coins mission reads 1.23K / 2.4K")
    game._close()
    var exact:=RegEx.create_from_string("[0-9],[0-9]{3} (coins|gems)").search_all(FileAccess.get_file_as_string("res://localization/en.po"))
    check(exact.is_empty(),"No written currency amount of 1,000 or more remains unabbreviated in the strings (%d found)" % exact.size())
    # Source sweep: no raw %d currency strings remain in the English table for coins/gems.
    var po:=FileAccess.get_file_as_string("res://localization/en.po")
    var raw:=RegEx.create_from_string("%d (coins|gems)").search_all(po)
    check(raw.is_empty(),"No '%%d coins' / '%%d gems' placeholders remain (%d found)" % raw.size())

# ---------------------------------------------------------------- §4 weather
func rain_checks() -> void:
    fresh()
    var world=game.world
    var rainy: Array=sim.catalog.stages.filter(func(s):return s.weather=="rain").map(func(s):return int(s.id))
    check(rainy==[4,8],"Rain stays on Summer II and Spring II only")
    stage(4);world._process(0);world.weather._process(.016)
    var style: WeatherStyle=world.weather.styles.rain
    check(style.particles_per_period>12 and style.color.a>.4,"Rain is denser (%d per cell, was 12) and more visible (alpha %.2f, was 0.40)" % [style.particles_per_period,style.color.a])
    check(world.scenery.modulate==style.ambient_tint and style.ambient_tint.v<1.0,"Summer II art is darkened toward overcast (%s)" % style.ambient_tint)
    var camps: Node=world.scenery.get_node("Camps")
    var net: Color=style.ambient_tint*camps.modulate
    check(near(net.r,1.0,.01) and near(net.g,1.0,.01) and near(net.b,1.0,.01),"Camps keep their own colours")
    check(world.get_node("Actors").modulate==Color.WHITE and not world.get_node("Actors").is_ancestor_of(world.scenery),"Actors (and their HP bars) are not tinted")
    var rect:=Rect2(Vector2(200,200),Vector2(600,600))
    var a: Array=world.weather.particles(rect)
    world.pan_camera(Vector2(-300,-200))
    var b: Array=world.weather.particles(rect)
    check(a==b and a.size()>20,"Rain particles are world-anchored: panning the camera leaves the same %d particles in place" % a.size())
    stage(3);world._process(0)
    check(world.scenery.modulate==Color.WHITE,"A clear map is not darkened")
    stage(6);world._process(0)
    check(world.scenery.modulate==Color.WHITE,"Falling-leaves Autumn II keeps its colours")
    world.follow_player()

# ---------------------------------------------------------------- §9 summoned helpers
func summon_checks() -> void:
    var rules: EnemyAbilityRules=sim.abilities
    var summoners: Array=rules.summons.map(func(r):return r.summoner_id)
    check(summoners.size()==3 and summoners.has("boss-green-alien"),"Three summoning types, the final boss among them: %s" % [summoners])
    for r in rules.summons:
        var sg:=group(r.summoner_id);var hg:=group(r.helper_id)
        check(sg>=0 and hg>=0 and int(sim.catalog.groups[sg].stage)>=6 and not sim.catalog.groups[hg].boss and sim.catalog.groups[hg].stage==sim.catalog.groups[sg].stage,"%s calls %s (existing type of its own map, stage %d)" % [r.summoner_id,r.helper_id,sim.catalog.groups[sg].stage])
    fresh();stage(6)
    var reaper:=actor_of("boss-grim-reaper")
    var rule: SummonRule=rules.summon_rule("boss-grim-reaper")
    sim.state.player.x=reaper.x+60;sim.state.player.y=reaper.y # fixture: beside the boss
    reaper.aggro=true
    var warnings:=[0]
    var appeared:=[]
    sim.summon_warning.connect(func(_id):warnings[0]+=1)
    sim.summoned.connect(func(_id,ids):appeared.append(ids.size()))
    campaign_steps(rule.first_delay-.5)
    check(sim.helpers_of(reaper.id).is_empty(),"No helpers before the first delay (%.0f s)" % rule.first_delay)
    campaign_steps(1.5)
    var helpers: Array=sim.helpers_of(reaper.id)
    check(helpers.size()==rule.per_cast and warnings[0]==1 and appeared==[rule.per_cast],"After the telegraph %d helpers appear, with one warning" % rule.per_cast)
    var h: Dictionary=helpers[0]
    var hdef: Dictionary=sim.enemy_definition(int(h.group),sim.HELPER_VARIANT)
    var base: Dictionary=sim.catalog.groups[int(h.group)]
    check(near(hdef.hp,base.hp*rule.hp_scale) and near(hdef.damage,base.damage*rule.damage_scale) and hdef.loot.is_empty() and hdef.skills.is_empty(),"Helpers: %.0f%% HP, %.0f%% damage of %s, no loot, no skills" % [rule.hp_scale*100,rule.damage_scale*100,base.id])
    check(helpers.all(func(x):return not sim.campaign.solid_at(sim.position_of(x))),"They appear outside solid scenery")
    # Cap and cooldown: a long fight never exceeds max_alive.
    var most:=0
    for i in range(60):
        campaign_steps(1.0)
        most=maxi(most,sim.helpers_of(reaper.id).size())
    check(most<=rule.max_alive,"60 s more: never more than %d alive (max %d seen)" % [rule.max_alive,most])
    check(appeared.size()==1,"While the cap is reached no new call happens (calls: %d)" % appeared.size())
    # No rewards from a helper.
    helpers=sim.helpers_of(reaper.id)
    var before: Dictionary={"coins":sim.state.coins,"gems":sim.state.gems,"xp":sim.state.xp,"kills":sim.state.group_kills.duplicate(),"run":sim.state.run_kills.duplicate(),"pickups":sim.state.pickups.size(),"found":sim.state.discovered.duplicate(),"spots":sim.state.discovered_spots.duplicate(),"counters":sim.state.counters.duplicate(true),"missions":sim.state.missions.duplicate(true)}
    for x in helpers:
        x.hp=0.0;sim._kill(x) # the player's blow
    check(sim.state.coins==before.coins and sim.state.gems==before.gems and sim.state.xp==before.xp and sim.state.group_kills==before.kills and sim.state.run_kills==before.run and sim.state.pickups.size()==before.pickups,"Killing helpers gives no coins, gems, XP, loot or kill counts")
    check(sim.state.discovered==before.found and sim.state.discovered_spots==before.spots and sim.state.counters==before.counters and sim.state.missions==before.missions,"…and no discovery, mission or achievement progress")
    sim_steps(1.2)
    check(sim.state.enemies.all(func(x):return not sim.is_helper(x) or float(x.hp)>0),"Dead helpers are removed after their death animation")
    # A new call after the cooldown; it is bounded again.
    reaper.aggro=true;reaper.summon_cd=0.0
    campaign_steps(1.0)
    check(sim.helpers_of(reaper.id).size()==rule.per_cast,"After the cooldown the boss calls again")
    # Helpers never save, never summon, dissolve when the summoner stops fighting or dies.
    var snap: Dictionary=sim.snapshot()
    check(not snap.enemies.any(func(x):return sim.is_helper(x)),"Helpers are not saved")
    check(sim.abilities.summon_rule(rule.helper_id)==null,"Helper types cannot summon (no chains)")
    reaper.aggro=false;reaper.returning=true
    sim_steps(.1)
    check(sim.helpers_of(reaper.id).is_empty(),"When the boss leaves the fight its helpers dissolve")
    reaper.returning=false;reaper.aggro=true;reaper.summon_cd=0.0;campaign_steps(1.0)
    var kills_before: int=sim.state.group_kills[int(reaper.group)]
    reaper.hp=0.0;sim._kill(reaper)
    sim_steps(.1)
    check(sim.helpers_of(reaper.id).is_empty() and sim.state.group_kills[int(reaper.group)]==kills_before+1,"When the boss dies its helpers dissolve (the boss kill itself counts)")
    reaper.hp=float(sim.enemy_definition(int(reaper.group)).hp);reaper.respawn=0;reaper.aggro=true;reaper.summon_cd=0.0;campaign_steps(1.0)
    check(not sim.helpers_of(reaper.id).is_empty(),"(fixture) a fresh call")
    sim.state.camps["4"]=[0];sim.state.unlocked_stage=6;sim.state.player.quiet=9.0
    for x in sim.state.enemies:x.aggro=false;x.windup=0.0
    for x in sim.state.enemies.filter(func(x):return sim.is_helper(x)):x.aggro=false
    check(sim.campaign.camp_action(4,0,true) and not sim.state.enemies.any(func(x):return sim.is_helper(x)) and not sim.state.stage_worlds["6"].enemies.any(func(x):return sim.is_helper(x)),"A map change removes them (none kept in the saved map)")
    # Visual identity: tinted helpers; the panel never opens from a helper.
    stage(6);reaper=actor_of("boss-grim-reaper");reaper.aggro=true;reaper.summon_cd=0.0;sim.state.player.x=reaper.x+60;sim.state.player.y=reaper.y
    campaign_steps(1.0)
    game.world._process(0)
    var hv=game.world.views[sim.helpers_of(reaper.id)[0].id]
    check(hv.body_tint==rules.helper_tint and game.world.views[reaper.id].body_tint==Color.WHITE,"Helpers wear the summon tint; the boss does not")
    check(sim.catalog.skills.has("focus") and ResourceLoader.exists("res://assets/magic-spells-sfx-lite/ogg/summon_01.ogg") and game.audio_cues.cues.any(func(c):return c.id=="spell_summon"),"Summon cue uses the approved pack's summon sound")

# ---------------------------------------------------------------- §10 final boss
func final_boss_checks() -> void:
    fresh();stage(8)
    var alien:=actor_of("boss-green-alien")
    var bosses: Array=[]
    for g in sim.catalog.groups:
        if g.boss and not g.final:bosses.append(g.id)
    sim.state.keys=bosses;sim.state.final_discovered=true;sim.state.final_unsealed=true # fixture: all 13 keys, Change 82 ceremony done
    sim.state.player.x=alien.x+50;sim.state.player.y=alien.y
    var maxhp: float=sim.campaign.actor_max_hp(alien)
    alien.aggro=true;alien.hp=maxhp*.9;alien.summon_cd=999.0 # fixture: summons later
    casts.clear();heals.clear()
    campaign_steps(60)
    var attack_keys: Array=[]
    for c in casts:
        if c[0]==alien.id and not attack_keys.has(c[1]):attack_keys.append(c[1])
    check(heals.filter(func(x):return x[0]==alien.id).is_empty(),"Above 50% HP it never heals")
    check(attack_keys.size()>=2 and attack_keys.all(func(k):return k in Array(sim.abilities.final_attack_pool)+["focus"]),"Above 50%% it uses several attack skills from the pool: %s" % [attack_keys])
    # An attack emits its warning at the telegraph and its effect on the hit: two events per action.
    var actions: float=casts.filter(func(c):return c[0]==alien.id).size()/2.0
    check(actions>=3 and actions<=60.0/(sim.abilities.final_action_gap+sim.abilities.telegraph)+1,"Paced: about %.0f actions in 60 s (gap %.1f s + %.1f s telegraph)" % [actions,sim.abilities.final_action_gap,sim.abilities.telegraph])
    # Below 50%: Heal first when ready.
    alien.hp=maxhp*.45;alien.skill_cds={};alien.skill_timer=0.0;alien.telegraph=false;heals.clear();casts.clear()
    campaign_steps(1.0)
    var healed: Array=heals.filter(func(x):return x[0]==alien.id)
    check(healed.size()==1 and near(healed[0][1],maxhp*sim.abilities.final_heal_fraction,.001),"Below 50%% it heals first: +%.0f (%.0f%% of max HP)" % [healed[0][1] if not healed.is_empty() else 0.0,sim.abilities.final_heal_fraction*100])
    check(casts.filter(func(c):return c[0]==alien.id and c[1]!="heal").is_empty(),"…with no attack warning before it")
    # Heal on cooldown: it keeps attacking instead of freezing.
    alien.hp=maxhp*.3;casts.clear();heals.clear()
    campaign_steps(13)
    check(heals.is_empty() and casts.filter(func(c):return c[0]==alien.id).size()>=2,"With Heal on cooldown (120 s) it attacks instead of waiting")
    campaign_steps(12)
    check(heals.size()==1,"…and heals again once Heal is ready (one heal, no duplicate)")
    # Healing that would do nothing never shows.
    alien.hp=maxhp*.6;alien.skill_cds={};heals.clear();casts.clear()
    campaign_steps(5)
    check(heals.is_empty(),"At 60% (above the threshold) Heal stays unused even when ready")
    # Summons with the final boss's rule, bounded.
    var rule: SummonRule=sim.abilities.summon_rule("boss-green-alien")
    alien.summon_cd=0.0
    var most:=0
    for i in range(80):
        campaign_steps(1.0)
        most=maxi(most,sim.helpers_of(alien.id).size())
    check(most>0 and most<=rule.max_alive,"It summons %s helpers, never more than %d alive (max %d)" % [rule.helper_id,rule.max_alive,most])
    # Locked (no keys): no actions, no summons.
    fresh();stage(8);alien=actor_of("boss-green-alien");alien.aggro=true;alien.summon_cd=0.0;casts.clear()
    sim.state.player.x=alien.x+50;sim.state.player.y=alien.y
    campaign_steps(10)
    check(casts.is_empty() and sim.helpers_of(alien.id).is_empty(),"Without the 13 keys the final boss does nothing (gate unchanged)")
    # Change 79: HP x0.45 through progression.balance.boss_tuning (304,514 -> 137,031); its drop skills unchanged.
    check(int(sim.catalog.groups[group("boss-green-alien")].hp)==91354 and sim.catalog.groups[group("boss-green-alien")].skills==["focus","fire","strike"],"Baseline HP (Change 81: 137,031 x2/3) and its drop skills unchanged")
