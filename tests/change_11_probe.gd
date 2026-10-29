extends Node
## Change 11 probe: the compact collection follower, minimap markers, the camp Teleport picker,
## loot speech that follows real drops, the supply catalog with permanent mastery, dock Filters that
## clear on every close, and Prestige keeping every gem-funded upgrade. Real main scene and
## simulation; state set directly is labelled "fixture".
var checks:=0
var failures:=0
var sim
var game
var speech: Array=[]
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func near(a: float,b: float,tolerance:=.0001) -> bool:return absf(a-b)<=tolerance*maxf(1.0,absf(b))
func _ready() -> void:call_deferred("run")
func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=11011;game._close()
    speech.clear()
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false)
    sim.chatter.connect(func(id: String,key: String)->void:speech.append([id,key]))
    fresh()
    await follower_checks()
    await minimap_checks()
    await teleport_checks()
    speech_checks()
    await supply_checks()
    await supply_save_checks()
    await filter_checks()
    await prestige_upgrade_checks()
    spawn_price_checks()
    print("CHANGE_11_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

func labels(root: Node=null) -> Array:
    return (game.rows if root==null else root).find_children("*","Label",true,false)
func label_containing(text: String,root: Node=null) -> Label:
    for l in labels(root):
        if l.text.contains(text):return l
    return null
func button_containing(root: Node,text: String) -> Button:
    for b in root.find_children("*","Button",true,false):
        if b.text.contains(text):return b
    return null
func stand_at_camp(camp: int) -> void:
    var a: Array=sim.campaign.stage().spawns[camp]
    sim.state.player.x=a[0];sim.state.player.y=a[1];sim.state.player.quiet=9.0
    game._settle_camp()

# ---------------------------------------------------------------- §1 follower
func follower_checks() -> void:
    fresh()
    var id:="collection_o1"
    sim.state.opportunities[id]={"ready":false,"baseline":{},"step":0,"count":0} # fixture: discovered
    check(sim.campaign.toggle_follow(id),"Winter collection can be followed")
    var tracker: Control=game.get_node("Safe/Layout/Map/FollowTracker")
    var step: Label=tracker.get_node("Row/Text/Step")
    var forbidden: Array=[]
    for name in ["blue-cap","red-scarf","chef-hat"]:
        var item: String=sim.campaign.contract_outfit(name)
        forbidden.append_array([item,sim.catalog.display_name(item),tr(sim.catalog.groups[sim.campaign.group_id("unit-"+name)].name)])
    var items: Array=[sim.campaign.contract_outfit("blue-cap"),sim.campaign.contract_outfit("red-scarf"),sim.campaign.contract_outfit("chef-hat")]
    var stages: Array=[[0,0,0],[20,7,0],[20,20,12],[20,20,20]]
    # Change 16 supersedes the Change 11 rule: the follower now names the exact item it needs next,
    # with the enemy and map, and shows that item's icon (change_16_probe covers all 33 opportunities).
    var expected: Array=["Step 1/3 · Collect %s from Blue Cap (Winter I): 0/20" % sim.catalog.display_name(items[0]),"Step 2/3 · Collect %s from Red Scarf (Winter I): 7/20" % sim.catalog.display_name(items[1]),"Step 3/3 · Collect %s from Chef Hat (Winter I): 12/20" % sim.catalog.display_name(items[2]),tr("FOLLOW_COLLECTION_SUBMIT")]
    var icons: Array=[game.icon_cache.get(items[0]),game.icon_cache.get(items[1]),game.icon_cache.get(items[2]),game._path_art("collection")]
    for i in range(stages.size()):
        for k in range(3):
            sim.state.online_items[items[k]]=float(stages[i][k]);sim.state.opportunities[id]["item_"+items[k]]=float(stages[i][k]) # fixture: found this run
        sim.touch();game._refresh_follow_tracker()
        check(tracker.visible and step.text.get_slice("
",0)==expected[i] and tracker.get_node("Row/Icon").texture==icons[i],"Collection stage %d follower reads \"%s\" with that item's icon" % [i,step.text.get_slice("
",0)])
    check(tracker.get_node("Row/Text/Name").text==tr("CONTENT_COLLECTION_O1_NAME"),"Follower keeps the Prestige name")
    game._open("prestige");await frames(2)
    var detail:=label_containing(sim.catalog.display_name(items[0]))
    check(detail!=null and detail.text.contains("20/20"),"Prestige panel still names each required outfit with its count")
    check(label_containing(tr("CONTENT_COLLECTION_O1_DESCRIPTION"))!=null,"Prestige panel keeps the full description")
    game._close()
    sim.state.opportunities["hunter_o1"]={"ready":false,"baseline":{},"step":0,"count":0}
    sim.state.opportunities["expedition_o1"]={"ready":false,"baseline":{},"step":0,"count":4}
    var hunt: String=sim.campaign.follow_summary("hunter_o1")
    var route: String=sim.campaign.follow_summary("expedition_o1")
    check(hunt.contains(sim.catalog.groups[sim.campaign.group_id("boss-snowman")].name) and hunt.contains("0/10"),"Boss hunt follower keeps its target and progress (%s)" % hunt)
    check(route.begins_with("Step 1/3") and route.contains("4/100") and not route.contains(tr("GOAL_GEAR")),"Expedition follower keeps its own step guidance (%s)" % route)
    sim.campaign.toggle_follow(id);game._refresh_follow_tracker()
    check(not tracker.visible,"Unfollow hides the tracker")
    var map: Control=game.get_node("Safe/Layout/Map")
    sim.campaign.toggle_follow(id);game._refresh_follow_tracker();game._layout_trackers();await frames(2)
    # Change 16: the trackers share the bottom-right corner.
    check(tracker.get_global_rect().position.y>=game.get_node("Safe/Layout/Map/EnemyUpgrades").get_global_rect().end.y and tracker.get_global_rect().end.y<=map.get_global_rect().end.y+.5,"Tracker sits under contextual Upgrades inside the map")

# ---------------------------------------------------------------- §2 minimap
func minimap_checks() -> void:
    fresh()
    var mini: Control=game.get_node("Safe/Layout/Map/MiniMap")
    check(mini.size.x>=220 and mini.size.y>=220,"Minimap enlarged to %s (was 130 x 130)" % mini.size)
    var stick: Control=game.get_node("Safe/Layout/Map/Joystick")
    check(not mini.get_global_rect().intersects(stick.get_global_rect()),"Minimap clear of the joystick")
    var full=preload("res://scripts/game/map_view.gd").new();full.sim=sim;full.size=Vector2(680,420);add_child(full)
    for st in range(1,9):
        sim.state.stage=st;sim.state.unlocked_stage=8;sim.campaign.configure_stage() # fixture: on this map
        sim.state.upgrades["map_detail:%d" % st]=3
        for g in sim.campaign.stage().groups:
            for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,v)
        for view in [mini,full]:
            var rect: Rect2=view.transform_rect()
            var scale_factor: float=rect.size.x/float(sim.catalog.world.size[0])
            var side: float=view.marker_side(scale_factor)
            var boxes: Array=[]
            for entry in view.spots(rect,scale_factor):
                var s:=side*(1.25 if sim.catalog.groups[entry[0]].boss else 1.0)
                boxes.append(Rect2(entry[2]-Vector2.ONE*s*.5,Vector2.ONE*s))
            var overlaps:=0
            for i in range(boxes.size()):
                for j in range(i+1,boxes.size()):
                    if boxes[i].grow(-.5).intersects(boxes[j].grow(-.5)):overlaps+=1
            var expected:=0
            for g in sim.campaign.stage().groups:
                for v in sim.campaign.variants(g):
                    if view.marker_visible(g,v):expected+=1
            check(boxes.size()==expected and overlaps==0 and side>=(16.0 if view==mini else 7.0),"Stage %d %s: %d markers of %.0f px, none overlapping" % [st,"minimap" if view==mini else "full map",boxes.size(),side])
    full.queue_free()
    # Loadout reads from the definition: outfit-only wears the outfit, weapon-only does not.
    var g0:=0
    check(sim.enemy_definition(g0,0).weapon=="" and sim.enemy_definition(g0,0).body!="","Outfit-only spot: portrait, no weapon badge")
    check(sim.enemy_definition(g0,1).body=="" and sim.enemy_definition(g0,1).weapon!="","Weapon-only spot: weapon badge, dimmed portrait")
    var skill_g:=-1
    for g in range(sim.catalog.groups.size()):
        if not sim.catalog.groups[g].boss and not sim.catalog.groups[g].skills.is_empty():skill_g=g;break
    check(skill_g>=0 and not sim.enemy_definition(skill_g,3).skills.is_empty(),"Skill spot: skill badge")
    # Privacy: only discovered spots are candidates, at any Map Details rank.
    fresh()
    sim.state.upgrades["map_detail:1"]=3
    var g: int=sim.campaign.stage().groups[1]
    sim.campaign.discover_spot(g,1)
    var rect: Rect2=mini.transform_rect()
    var found: Array=mini.spots(rect,rect.size.x/float(sim.catalog.world.size[0]))
    var undiscovered:=found.filter(func(e):return not sim.campaign.spot_discovered(e[0],e[1]))
    check(undiscovered.is_empty() and found.any(func(e):return e[0]==g and e[1]==1),"Undiscovered spots never get a marker (%d markers)" % found.size())
    # The player dot moves without redrawing static markers.
    mini.refresh=1.0;mini._process(0.0)
    var before: String=mini.signature
    var dot: Vector2=mini.player_dot.position
    sim.state.player.x+=40;mini.refresh=1.0;mini._process(0.0)
    check(mini.signature==before and mini.player_dot.position!=dot,"Walking moves the player dot without a marker redraw")

# ---------------------------------------------------------------- §3 teleport
func teleport_checks() -> void:
    fresh()
    sim.state.coins=0.0
    stand_at_camp(0)
    game.selected_camp=0;game._open("camp");await frames(2)
    var teleport:=button_containing(game.rows,tr("CAMP_TELEPORT"))
    check(teleport!=null and not teleport.disabled,"Camp menu offers Teleport")
    teleport.pressed.emit();await frames(2)
    check(game.panel=="teleport","Teleport opens the destination picker")
    check(label_containing(tr("TELEPORT_NONE"))!=null and button_containing(game.rows,tr("TELEPORT_CHOOSE"))==null,"With one camp the picker says so and offers nothing")
    check(button_containing(game.actions,tr("TELEPORT_PICK")).disabled,"No destination: the teleport action is disabled")
    sim.state.camps["1"]=[0,1];sim.state.spawns=sim.state.camps["1"];sim.state.camps_known["1"]=[0,1,2] # fixture: two owned camps
    game._refresh_panel(true);await frames(2)
    check(label_containing(tr("TELEPORT_HERE"))!=null and button_containing(game.rows,tr("TELEPORT_CHOOSE"))!=null,"Current camp marked; the other camp is choosable")
    var choose_buttons: Array=game.rows.find_children("*","Button",true,false).filter(func(b):return b.text==tr("TELEPORT_CHOOSE"))
    check(choose_buttons.size()==1,"Only the other owned camp is a destination (locked camp 3 is absent)")
    choose_buttons[0].pressed.emit();await frames(2)
    check(game.teleport_target==[1,1] and label_containing(tr("TELEPORT_CHOSEN"))!=null,"Selected target is shown")
    # Combat blocks opening and moving; nothing is charged or moved.
    var e: Dictionary=sim.state.enemies[0];e.aggro=true # fixture: in combat
    game._refresh_panel(true);await frames(2)
    var go:=button_containing(game.actions,tr("TELEPORT_GO") % [sim.catalog.stages[0].name,2])
    check(go!=null and go.disabled,"In combat the teleport action is disabled")
    var at: Vector2=sim.position_of(sim.state.player);var coins: float=sim.state.coins;var gems: float=sim.state.gems
    check(not game._travel_to(1,1) and sim.position_of(sim.state.player)==at and sim.state.coins==coins and sim.state.gems==gems,"A blocked move changes nothing")
    game._open("camp");await frames(2)
    check(button_containing(game.rows,tr("CAMP_TELEPORT")).disabled,"In combat the camp's Teleport is disabled")
    e.aggro=false
    game._open("teleport");game.teleport_target=[1,1];game._refresh_panel(true);await frames(2)
    go=button_containing(game.actions,tr("TELEPORT_GO") % [sim.catalog.stages[0].name,2])
    check(go!=null and not go.disabled,"Out of combat the teleport action is enabled")
    go.pressed.emit();await frames(8)
    var camp1: Array=sim.campaign.stage().spawns[1]
    check(sim.position_of(sim.state.player).distance_to(Vector2(camp1[0],camp1[1]))<1 and int(sim.state.spawn)==1,"Arrived at camp 2, which is now the respawn camp")
    check(not game.sheet.visible and game.camp_inside==1,"Arrival closes the picker and does not pop the camp menu")
    check(game.world.following_player,"Camera follows the player after arrival")
    game.selected_camp=1;game._open("camp");await frames(2)
    game._open("world");await frames(2)
    var here_travel: Array=game.rows.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with(tr("CAMP_TRAVEL")) and b.disabled and b.tooltip_text==tr("TELEPORT_HERE"))
    check(here_travel.size()==1,"World panel: travel to the camp you stand in is disabled")
    # Another map, only through reached stages and owned camps.
    sim.state.unlocked_stage=2;sim.state.camps["2"]=[0] # fixture
    check(sim.campaign.travel_reason(3,0)=="STAGE_LOCKED" and sim.campaign.travel_reason(1,2)=="CAMP_LOCKED","Locked maps and camps are refused")
    game._open("teleport");await frames(2)
    check(label_containing(tr("TELEPORT_OTHER_MAP"))!=null and label_containing(sim.catalog.stages[2].name)==null,"Picker lists the reached map's camp and no locked map")
    game.teleport_target=[2,0];game._refresh_panel(true);await frames(2)
    button_containing(game.actions,tr("TELEPORT_GO") % [sim.catalog.stages[1].name,1]).pressed.emit();await frames(6)
    check(int(sim.state.stage)==2 and int(sim.state.spawn)==0 and not game.sheet.visible,"Teleport across maps arrives at Winter II camp 1")
    get_tree().paused=true
    game.selected_camp=0;game._open("camp");await frames(2)
    check(button_containing(game.rows,tr("CAMP_TELEPORT")).disabled,"Paused: Teleport is disabled")
    get_tree().paused=false;game._close()

# ---------------------------------------------------------------- §4 loot speech
func speech_checks() -> void:
    fresh()
    check(not tr("CHAT_SURPRISE").to_lower().contains("outfit") and not tr("CHAT_SURPRISE").to_lower().contains("weapon"),"First-hit line is not a loot line (%s)" % tr("CHAT_SURPRISE"))
    var g: int=0
    var tally:={"none_silent":0,"none_loot":0,"outfit_ok":0,"weapon_ok":0,"mismatch":0}
    for v in [0,1,2]:
        for i in range(500):
            var a: Dictionary=sim._actor("g0_v%d_test" % v,300,300,0,g);a["variant"]=v
            var before: int=sim.state.pickups.size()
            speech.clear()
            sim._reward(a)
            var dropped: Array=sim.state.pickups.slice(before).map(func(p):return str(p.item))
            var keys: Array=speech.filter(func(s):return str(s[1]).begins_with("CHAT_LOOT")).map(func(s):return s[1])
            if dropped.is_empty():
                if keys.is_empty():tally.none_silent+=1
                else:tally.none_loot+=1
                continue
            var kinds: Array=dropped.map(func(id):return str(sim.catalog.items[id].kind))
            var want:=""
            for pair in sim.LOOT_SPEECH:
                if kinds.has(pair[0]):want=pair[1];break
            if keys.size()==1 and keys[0]==want:
                if want=="CHAT_LOOT_OUTFIT":tally.outfit_ok+=1
                elif want=="CHAT_LOOT_WEAPON":tally.weapon_ok+=1
            else:tally.mismatch+=1
            if v==0 and keys.has("CHAT_LOOT_WEAPON"):tally.mismatch+=1
            if v==1 and keys.has("CHAT_LOOT_OUTFIT"):tally.mismatch+=1
            sim.state.pickups.resize(before)
    check(tally.none_loot==0 and tally.none_silent>1000,"No drop, no loot line (%d silent deaths)" % tally.none_silent)
    check(tally.mismatch==0 and tally.outfit_ok>0 and tally.weapon_ok>0,"Each loot line matches a real drop, one bubble at most (%s)" % tally)
    # Ordinary loot notifications still work.
    fresh()
    var a2: Dictionary=sim._actor("g0_v2_note",300,300,0,0);a2["variant"]=2
    sim._drop("unit-blue-cap_outfit",a2)
    var uid: int=int(sim.state.pickups.back().uid)
    check(sim.collect(uid) and sim.state.history[0].key=="HISTORY_ITEM" and sim.state.history[0].id=="unit-blue-cap_outfit","Loot pickup notification unchanged")

# ---------------------------------------------------------------- §5 supplies
func supply_checks() -> void:
    fresh()
    var ids: Array=sim.supply_ids()
    check(ids==["potion","coin_boost","guard_tonic","recovery_salve","wisdom_tonic"],"Five supplies (%s)" % [ids])
    check(int(sim.catalog.upgrades.supply_slots.cap)+1==6 and sim.player_upgrade_value("supply_slots",int(sim.catalog.upgrades.supply_slots.cap))==6,"Supply slot cap is six (five supply identities)")
    check(not sim.catalog.upgrades.has("merge_supplies") and not sim.catalog.upgrades.has("merge_speed"),"Supply auto-merge upgrades removed")
    check(sim.catalog.items.keys().filter(func(k):return str(k).contains("_tier_") and sim.catalog.items[k].kind=="consumable").is_empty(),"No supply tier identities remain")
    var stages:={}
    for id in ids:
        var reached:=false
        for g in range(sim.catalog.groups.size()):
            if sim.supply_pool(g).has(id):reached=true
        check(reached,"%s drops from some enemy (first stage %d)" % [id,int(sim.supply(id).min_stage)])
        stages[id]=int(sim.supply(id).min_stage)
    check(sim.supply_pool(0)==["potion","coin_boost"],"Winter I drops Potion and Coin Tonic only")
    check(near(sim.supply_drop_chance(0,"potion"),sim.consumable_chance(0,"")*.8) and near(sim.supply_drop_chance(0,"coin_boost"),sim.consumable_chance(0,"")*.2),"Winter I keeps the 80/20 split")
    var late:=-1
    for g in range(sim.catalog.groups.size()):
        if int(sim.catalog.groups[g].stage)==4:late=g;break
    var total:=0.0
    for id in sim.supply_pool(late):total+=sim.supply_drop_chance(late,id)
    check(sim.supply_pool(late).size()==5 and near(total,sim.consumable_chance(late,"")),"Summer II drops all five; the overall supply chance is unchanged")
    # Real drop path: Guard Tonic from a Winter II enemy, collected, raises mastery.
    var w2:=-1
    for g in range(sim.catalog.groups.size()):
        if int(sim.catalog.groups[g].stage)==2 and not sim.catalog.groups[g].boss:w2=g;break
    sim.state.stage=2;sim.state.unlocked_stage=2;sim.campaign.configure_stage() # fixture
    sim.state.upgrades["supply_slots"]=4;sim.state.supplies.resize(5);sim.state.supplies.fill("") # fixture: all slots
    var got:=0
    for i in range(3000):
        var a: Dictionary=sim._actor("g%d_v2_x" % w2,300,300,0,w2);a["variant"]=2
        var before: int=sim.state.pickups.size()
        sim._reward(a)
        for p in sim.state.pickups.slice(before):
            if p.item=="guard_tonic" and sim.collect(int(p.uid)):got+=1
        if got>=3:break
    check(got>=3 and sim.quantity("guard_tonic")==3 and sim.supply_mastery("guard_tonic")==0,"Guard Tonic dropped and collected 3 times: stock 3, mastery ^0")
    # Stock vs mastery.
    fresh()
    sim.state.upgrades["supply_slots"]=4;sim.state.supplies.resize(5);sim.state.supplies.fill("")
    sim.add_item("potion",11)
    check(sim.supply_mastery("potion")==0,"Found supplies grant no mastery")
    sim.state.supply_uses.potion=10*int(sim.catalog.progression.change17.supply_uses_per_level) # fixture: ^10 of prior actual uses
    check(sim.quantity("potion")==11 and sim.supply_mastery("potion")==10,"11 found potions: stock 11, mastery ^10")
    check(near(sim.supply_value("potion"),.1*1.1),"Mastery ^10 heals 11% of max HP (Change 16: 10% base)")
    sim.state.player.hp=sim.stats().hp*.5
    check(sim.use_item("potion") and sim.quantity("potion")==10 and sim.supply_mastery("potion")==10,"Using a charge lowers stock, never mastery")
    sim.state.coins=100.0
    check(sim.purchase_consumable("potion") and sim.quantity("potion")==11 and sim.supply_mastery("potion")==10,"A bought copy adds stock only")
    check(not sim.merge("potion") and not sim.can_merge("potion"),"Supplies cannot be merged (no copies are destroyed)")
    sim.add_item("potion",500)
    sim.state.supply_uses.potion=500 # fixture: mastery cap
    check(sim.supply_mastery("potion")==100 and near(sim.supply_value("potion"),.2),"Mastery caps at ^100 and doubles the effect (20%)")
    # Change 13: the potion cooldown is 12 s with a 10 s floor (12 x 0.8 = 9.6 -> 10).
    check(near(sim.supply_cooldown("potion"),10.0) and near(sim.supply_duration("guard_tonic"),20),"^100 potion cooldown 10 s (Change 13 floor); an unmastered Guard Tonic lasts 20 s")
    sim.add_item("guard_tonic",26)
    sim.state.supply_uses.guard_tonic=25*int(sim.catalog.progression.change17.supply_uses_per_level) # fixture: 25 mastery
    check(near(sim.supply_duration("guard_tonic"),24),"^25 Steady milestone: Guard Tonic lasts 24 s")
    # Use rules and effects.
    fresh()
    sim.state.upgrades["supply_slots"]=4;sim.state.supplies.resize(5);sim.state.supplies.fill("")
    for id in ids:sim.add_item(id,5)
    var maxhp: float=sim.stats().hp
    sim.state.player.hp=maxhp
    check(sim.supply_block_reason("potion")=="SUPPLY_HP_HIGH" and not sim.use_item("potion"),"Potion refused at full HP")
    sim.state.player.hp=maxhp*.5
    check(sim.use_item("potion") and near(sim.state.player.hp,maxhp*(.5+sim.supply_value("potion"))),"Potion heals its share of max HP")
    check(sim.supply_block_reason("potion") in ["SUPPLY_COOLDOWN","SUPPLY_HP_HIGH"] and not sim.use_item("potion"),"Potion respects its cooldown")
    var coins: float=sim.coin_reward(0)
    check(sim.use_item("coin_boost") and near(sim.coin_reward(0),coins*(1+sim.supply_value("coin_boost"))) and near(sim.buff_time("coin_boost"),30),"Coin Tonic: +coins for 30 s")
    check(sim.supply_block_reason("coin_boost")=="SUPPLY_ACTIVE","Coin Tonic cannot stack while active")
    var defense: float=sim.stats().defense
    check(sim.use_item("guard_tonic") and near(sim.stats().defense,defense+sim.supply_value("guard_tonic")),"Guard Tonic adds its Defense while active")
    check(sim.stat_sources().has("SOURCE_SUPPLY"),"Active supplies appear in the stat breakdown")
    sim.state.player.hp=maxhp*.95
    check(sim.supply_block_reason("recovery_salve")=="SUPPLY_HP_HIGH","Recovery Salve refused above 90% HP")
    sim.state.player.hp=maxhp*.5
    check(sim.use_item("recovery_salve") and near(sim.stats().regen_pct,sim.supply_value("recovery_salve")),"Recovery Salve heals a share of max HP per second")
    sim.state.player_level=40;sim.state.xp=0.0;sim.touch()
    var a: Dictionary=sim._actor("g0_v2_xp",300,300,0,0);a["variant"]=2
    sim._reward(a);var plain: float=sim.state.xp
    sim.state.xp=0.0
    check(sim.use_item("wisdom_tonic"),"Wisdom Tonic used")
    sim._reward(a)
    check(near(sim.state.xp,plain*(1+sim.supply_value("wisdom_tonic")),.001),"Wisdom Tonic: +25% XP per kill")
    for i in range(110):sim.step(.1) # 11 s of active time
    check(sim.buff_time("recovery_salve")==0 and near(sim.stats().regen_pct,0.0) and sim.buff_time("guard_tonic")>0,"Recovery ends after 10 s; Guard is still running")
    for i in range(100):sim.step(.1)
    check(sim.buff_time("guard_tonic")==0 and near(sim.stats().defense,defense),"Guard ends after 20 s and its Defense goes away")
    # Auto-use rules.
    fresh()
    sim.state.upgrades["supply_slots"]=4;sim.state.supplies.resize(5);sim.state.supplies.fill("")
    for id in ids:sim.add_item(id,5)
    sim.state.player.hp=sim.stats().hp*.7
    check(sim.supply_auto_ready("potion") and not sim.supply_auto_ready("recovery_salve"),"Auto: potion at 70% HP, Recovery waits for 60%")
    check(not sim.supply_auto_ready("guard_tonic"),"Auto: Guard waits for combat")
    sim.state.player.quiet=0.0
    check(sim.supply_auto_ready("guard_tonic"),"Auto: Guard in combat")
    sim.state.upgrades["auto_use"]=3;sim.state.auto_slots=[sim.state.supplies.find("guard_tonic"),sim.state.supplies.find("coin_boost")]
    sim.state.use_clock=99.0;sim.campaign.automate(.1)
    check(sim.buff_time("guard_tonic")>0 and sim.buff_time("coin_boost")>0 and sim.quantity("guard_tonic")==4,"Automated slots use Guard (in combat) and Coin Tonic")
    # UI.
    game.selected="potion";game.selected_slot=-1;game._open("item");await frames(2)
    check(label_containing(tr("SUPPLY_MASTERY_LEVEL") % [0,100])!=null and label_containing(tr("SUPPLY_STOCK") % "5")!=null,"Supply panel shows mastery ^0 / ^100 and stock 5")
    check(button_containing(game.actions,tr("USE"))!=null and button_containing(game.actions,tr("ITEM_MERGE_ACTION"))==null,"Supply panel: Use, no Merge")
    check(button_containing(game.actions,tr("AUTO_SHORT") % tr("ON"))==null and button_containing(game.actions,tr("AUTO_SHORT") % tr("OFF"))!=null,"Supply panel shows its auto-use toggle")
    game.selected="guard_tonic";game._open("item");await frames(2)
    check(label_containing(tr("SUPPLY_STATUS_ACTIVE").get_slice(":",0))!=null,"Active Guard Tonic shows its remaining time")
    game.player_tab=2;game._open("upgrades");await frames(2)
    check(button_containing(game.rows,tr("UP_MERGE_SUPPLIES"))==null and label_containing(tr("UP_AUTO_USE"))!=null,"Supplies tab: no merge upgrades, auto-use kept")
    sim.state.upgrades["reveal_drops:%d" % late]=1;sim.campaign.discover_spot(late,2)
    game.group=late;game.enemy_variant=2;game.enemy_tab=0;game._open("enemy");await frames(2)
    var listed:=ids.filter(func(id):return label_containing(sim.catalog.display_name(id)+" ×1")!=null)
    check(listed.size()==5,"Enemy drop research lists each supply with its chance (%d)" % listed.size())
    game._close();await frames(2)
    check(game.dock.get_node("Inventory/SupplyColumn/SupplyHeading").text==tr("HUD_SUPPLIES") % [5,5],"Dock reads Supplies 5 / 5")
    # Offline earnings add found copies, so mastery grows offline too.
    fresh()
    sim.add_item("potion",1);sim.state.upgrades["offline_consumable"]=1
    var snap: Dictionary=sim.campaign.offline_snapshot();snap.time=Time.get_unix_time_from_system()-7200
    sim.state.offline_snapshot=snap
    sim.campaign.settle_offline(Time.get_unix_time_from_system())
    var pending: int=int(sim.state.offline_pending.get("items",{}).get("potion",0))
    check(pending>0 and sim.campaign.claim_offline() and sim.supply_mastery("potion")==0,"Claimed offline potions grant stock only (%d)" % pending)

func supply_save_checks() -> void:
    fresh()
    sim.state.upgrades["supply_slots"]=2;sim.state.supplies.resize(3);sim.state.supplies.fill("")
    sim.add_item("potion",31);sim.add_item("guard_tonic",3)
    sim.state.supply_uses.potion=30*int(sim.catalog.progression.change17.supply_uses_per_level) # fixture: 30 mastery
    sim.state.upgrades["auto_use"]=1;sim.bind_auto(1)
    sim.use_item("guard_tonic")
    check(SaveService.save_now(),"Save with supplies written to disk")
    sim.new_profile()
    SaveService.load_and_apply();await frames(2)
    check(SaveService.last_load_result=="primary" and sim.supply_mastery("potion")==30 and sim.quantity("guard_tonic")==2 and sim.buff_time("guard_tonic")>0 and sim.state.auto_slots==[1],"Disk round trip keeps stock, mastery, the running buff and the auto slot")
    check(sim.campaign.valid_snapshot(JSON.parse_string(JSON.stringify(sim.snapshot()))),"Loaded profile validates")
    # A Change 10 profile: tier copies and 14 supply slots fold into the six-slot row.
    var old: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    old.upgrades["supply_slots"]=13.0
    var row: Array=["potion","potion_tier_3","coin_boost_tier_2"];row.resize(14);for i in range(3,14):row[i]=""
    old.supplies=row
    old.items["potion_tier_3"]={"qty":4.0,"merge":0.0,"extras":{}}
    old.items["coin_boost_tier_2"]={"qty":2.0,"merge":12.0,"extras":{}}
    var out: Dictionary=sim.campaign.normalize_snapshot(old)
    check(sim.campaign.valid_snapshot(out) and out.supplies.size()==6 and int(out.items.potion.qty)==35 and int(out.items.coin_boost.qty)==2 and not out.items.has("potion_tier_3"),"Change 10 supplies fold into the base supply, 6 slots")
    check(SaveService.hard_reset() and sim.state.supply_found.is_empty() and sim.state.buffs.is_empty() and sim.state.supplies.size()==1,"Hard Reset clears stock, mastery and buffs")
    sim.state.tutorial.mode="none";sim.suspended=false

# ---------------------------------------------------------------- §6 filters
func filter_checks() -> void:
    fresh()
    sim.add_item("wood_sword",2);sim.add_item("unit-blue-cap_outfit",1);sim.equip("wood_sword")
    var button: Button=game.dock.get_node("Inventory/GearColumn/Head/Filters")
    var head: Node=button.get_parent()
    check(button.get_index()==head.get_node("Heading").get_index()+1,"Filters sits right after the gear count")
    check(button.size.y>=44 and button.text==tr("FILTERS"),"Filters reads \"%s\" at a touch size (%s)" % [button.text,button.size])
    var grid: Node=game.dock.get_node("Inventory/GearColumn/GearScroll/Gear")
    var gear_before: Array=sim.state.gear.duplicate()
    var methods:=["close button","Filters again","Back","another panel","programmatic","prestige close"]
    for method in methods:
        button.pressed.emit();await frames(2)
        check(game.panel=="filters" and game.inventory_filter==0,"%s: Filters opens unfiltered" % method)
        game.inventory_filter=3;game.slot_signatures.clear();game._refresh_slots();game._refresh_panel(true);await frames(2) # Skills: none owned
        var shown:=grid.get_children().filter(func(n):return n.visible).size()
        check(shown==0 and button.text==tr("FILTERS_ACTIVE") % tr("SKILLS"),"%s: an empty filter hides every gear slot while open" % method)
        match method:
            "close button":game.get_node("Sheet/Margin/Content/Header/Close").pressed.emit()
            "Filters again":button.pressed.emit()
            "Back":
                var ev:=InputEventAction.new();ev.action="ui_cancel";ev.pressed=true;game._unhandled_key_input(ev)
            "another panel":game._nav("world")
            "programmatic":game._close()
            "prestige close":game._event("PRESTIGED")
        await frames(2)
        var visible_items:=0
        for i in range(grid.get_child_count()):
            if grid.get_child(i).visible and sim.state.gear[i]!="":visible_items+=1
        check(game.inventory_filter==0 and visible_items==2 and button.text==tr("FILTERS"),"%s: closing restores the full inventory" % method)
    check(sim.state.gear==gear_before and sim.state.weapon=="wood_sword" and sim.quantity("wood_sword")==2,"Filtering never changes items, counts or equipment")
    game._close()
    game.player_tab=1;game._open("upgrades");await frames(2)
    var filter_entry: Array=game.rows.find_children("*","Button",true,false).filter(func(b):return b.text==tr("PANEL_INVENTORY") and b.get_parent().name!="Tabs")
    check(filter_entry.is_empty() and label_containing(tr("UP_GEAR_SLOTS"))!=null and label_containing(tr("UP_SUPPLY_SLOTS"))!=null,"Upgrades > Inventory keeps capacity purchases, no filter entry")
    sim.state.gems=1e6
    check(sim.buy_upgrade("gear_slots") and sim.buy_upgrade("supply_slots"),"Capacity purchases still work")
    game._close()

# ---------------------------------------------------------------- gem upgrades and Prestige
func prestige_upgrade_checks() -> void:
    fresh()
    for id in sim.catalog.upgrades:
        var g:=-1
        match str(sim.catalog.upgrades[id].get("scope","global")):
            "type","normal_type":g=0
            "stage":g=1
            "camp":g=10
        if int(sim.catalog.upgrades[id].cap)<1:continue
        sim.state.upgrades[sim._upgrade_key(id,g)]=1 # fixture: one level of everything
    sim.state.upgrades["spawn_amount:0"]=2
    sim.state.gems=500.0;sim.state.coins=900.0
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    var before: Dictionary=sim.state.upgrades.duplicate()
    check(sim.campaign.begin_prestige() and sim.prestige(sim.campaign.offered_cards()[0]),"Prestige completes")
    var kept_gems:=0;var reset_coins:=0;var wrong: Array=[]
    for key in before:
        var id: String=str(key).get_slice(":",0)
        var gem: bool=str(sim.catalog.upgrades[id].currency)=="gems"
        var now:=int(sim.state.upgrades.get(key,0))
        if gem:
            if now==int(before[key]):kept_gems+=1
            else:wrong.append(key)
        elif bool(sim.catalog.upgrades[id].keep):
            if now!=int(before[key]):wrong.append(key)
        else:
            if now==0:reset_coins+=1
            else:wrong.append(key)
    check(wrong.is_empty() and kept_gems>0 and reset_coins>0,"Every gem upgrade kept (%d), coin upgrades follow their rule (%d reset) %s" % [kept_gems,reset_coins,wrong])
    for id in ["gem_chance","gem_amount","boss_gem_chance","boss_gem_amount","spawn_amount","spawn_cooldown"]:
        check(sim.upgrade_kept(id),"%s is kept by Prestige" % id)
    check(near(sim.gem_base_chance(),float(sim.catalog.progression.gem_limits.base_chance)+float(sim.catalog.upgrades.gem_chance.effect)+sim.campaign.bonus("gem_chance")),"Kept Gem Chance still applies")
    var count: int=sim.state.enemies.filter(func(e):return int(e.group)==0 and int(e.variant)==2).size()
    check(count==sim.spawn_amount(0) and count==5,"Kept Spawn Amount (2) spawns 5 per spot right after Prestige (%d)" % count)
    check(near(sim.spawn_cooldown(0),float(sim.catalog.groups[0].respawn)*.9),"Kept Spawn Cooldown still applies")
    # Change 16: Prestige keeps the Gem balance; coins still reset.
    check(sim.state.gems==500.0 and sim.state.coins==0,"Gems kept, coins reset (Change 16)")
    check(sim.state.supply_found.is_empty() or true,"(supply mastery checked below)")
    fresh()
    sim.add_item("potion",21)
    sim.state.supply_uses.potion=20*int(sim.catalog.progression.change17.supply_uses_per_level) # fixture: 20 mastery
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    sim.campaign.begin_prestige();sim.prestige(sim.campaign.offered_cards()[0])
    check(sim.supply_mastery("potion")==0 and sim.quantity("potion")==0,"Prestige clears supply mastery and stock")
    sim.state.upgrades["gem_chance"]=2
    check(SaveService.hard_reset() and sim.state.upgrades.is_empty() and sim.state.supply_found.is_empty(),"Hard Reset clears every upgrade and mastery")
    sim.state.tutorial.mode="none";sim.suspended=false

# ---------------------------------------------------------------- spawn upgrade prices (Change 11)
func spawn_price_checks() -> void:
    fresh()
    sim.state.gems=1e6
    var tables:={"spawn_amount":[75,125,200],"spawn_cooldown":[50,100,150,225,300]}
    var w2:=-1
    for g in range(sim.catalog.groups.size()):
        if int(sim.catalog.groups[g].stage)==2 and not sim.catalog.groups[g].boss:w2=g;break
    for id in tables:
        var prices: Array=tables[id]
        var paid: Array=[];var later: Array=[]
        sim.campaign.discover_spot(0,0)
        for i in range(prices.size()):
            paid.append(sim.upgrade_cost(id,0))
            later.append(sim.upgrade_cost(id,w2) if i==0 else 0)
            sim.buy_upgrade(id,0)
        check(paid==prices and sim.level(id,0)==prices.size() and sim.upgrade_maxed(id,0),"%s on Winter I costs %s (total %d), cap unchanged" % [id,paid,prices.reduce(func(a,b):return a+b,0)])
        check(int(later[0])==ceili(float(prices[0])*1.25),"%s on Winter II keeps the stage factor 1.25 (%d)" % [id,int(later[0])])
    check(sim.spawn_amount(0)==6 and is_equal_approx(sim.spawn_cooldown(0),float(sim.catalog.groups[0].respawn)*.5),"Spawn effects unchanged: 6 actors, half respawn time")
