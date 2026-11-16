extends Node
## Change 8 behaviour probe. Real main scene and simulation; one named case per changed contract.
## State set directly is labelled. The first four cases were the Phase A build-safety checks; the rest cover the remaining
## Change 8 acceptance list (section 9 of the brief).
var checks:=0
var failures:=0
var sim
var game
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func _ready() -> void:call_deferred("run")
func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=88123;game._close()
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false);fresh()
    prestige_gate_checks()
    merge_cap_checks()
    await save_migration_checks()
    fog_checks()
    await camp_entry_checks()
    await nav_checks()
    await pinned_checks()
    await compare_checks()
    await hp_text_checks()
    skill_checks()
    loot_checks()
    price_checks()
    await follow_checks()
    discovery_checks()
    await banner_checks()
    print("CHANGE_8_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

## 4.1 Prestige opens with the first boss (Snowman) defeated; a reset needs a ready opportunity with
## a card left; the card is chosen inside the reset.
func prestige_gate_checks() -> void:
    fresh()
    check(sim.campaign.prestige_block_reason()=="PRESTIGE_LOCKED_BOSS_DEFEAT","New profile: prestige locked until the first boss")
    sim.state.group_kills[0]=1 # labelled: one regular kill
    check(not sim.campaign.prestige_unlocked(),"A regular kill does not unlock Prestige")
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1 # labelled: Snowman defeated
    check(sim.campaign.prestige_unlocked(),"First boss unlocks Prestige")
    check(sim.campaign.prestige_block_reason()=="NO_READY_PRESTIGE","Unlocked without a ready opportunity: needs one")
    check(sim.state.owned_cards.is_empty(),"No card owned beforehand")
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # labelled: ready opportunity
    check(sim.campaign.prestige_block_reason()=="","Ready opportunity with cards: reset allowed in Winter I")
    check(sim.campaign.begin_prestige(),"Batch begins")
    var offered: Array=sim.campaign.offered_cards()
    check(not offered.is_empty(),"Cards offered during the reset")
    check(sim.prestige(offered[0]),"Card chosen during the reset commits")
    check(sim.state.prestiges==1 and sim.state.owned_cards.has(offered[0]),"One reset, one card")
    check(sim.campaign.prestige_unlocked(),"The lifetime Snowman kill keeps Prestige open after the reset")

## 3.1-3.3 Outfits and skills merge their own copies up to the cap; weapons keep ^100.
func merge_cap_checks() -> void:
    fresh()
    sim.add_item("unit-blue-cap_outfit",600)
    check(sim.merge_cap("unit-blue-cap_outfit")==500 and sim.merge_cap("wood_sword")==20 and sim.merge_cap("obsidian_sword")==500,"Copy cap 500; weapon cap ^20 to evolve, Obsidian ^500 (Change 81)")
    check(sim.merge("unit-blue-cap_outfit",true) and int(sim.record("unit-blue-cap_outfit").merge)==500,"Merge all reaches ^500")
    check(not sim.merge("unit-blue-cap_outfit"),"No merge past the cap")
    var hp: float=sim.normal("unit-blue-cap_outfit").hp
    check(hp>55.9 and hp<60,"^500 outfit is bounded (%.1f HP: 7x base since Change 9, plus the spare-copy bonus)" % hp)
    check(str(sim.catalog.items["unit-blue-cap_outfit"].next)=="" and not sim.evolve("unit-blue-cap_outfit"),"Outfits do not evolve")
    check(sim.campaign.valid_snapshot(JSON.parse_string(JSON.stringify(sim.snapshot()))),"A ^500 save validates")

## Older saves load without a reset; Change 8 fields are derived, never copied from live state.
func save_migration_checks() -> void:
    fresh()
    sim.add_item("skill_frost",1);sim.state.group_kills[0]=3
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    for key in ["skills_seen","discovered_spots","camps_known"]:snap.erase(key) # labelled: Change 7 save
    sim.state.skills_seen=["heal"] # live state that must not leak into the load
    SaveService.last_load_result="" # fixture: judge this restore, not the boot-time load of the probe profile
    sim.restore(snap)
    await frames(2)
    check(SaveService.last_load_result not in ["development_reset","invalid_profile_reset"],"Change 7 save loads without a reset")
    check(sim.state.skills_seen==["frost"],"Owned skill backfills skills_seen (live state not copied)")
    check(sim.quantity("skill_frost")==1,"Items kept")

## 5.1 Permanent reveal vs momentary vision.
func fog_checks() -> void:
    fresh()
    var rules=sim.campaign.fog_rules
    check(is_equal_approx(rules.player_radius,48.0) and is_equal_approx(sim.campaign.vision_radius(),96.0),"Reveal 48 (a third of 144), vision 96")
    var p: Vector2=sim.position_of(sim.state.player)
    var near:=p+Vector2(84,0)
    check(sim.campaign.can_see(near) or sim.campaign.cell_visible(near),"84 units away is in sight")
    check(not sim.campaign.cell_visible(p+Vector2(200,0)),"200 units away is not in sight")

## 2.1 Change 16 replaces "walking into a camp opens it once": approaching never opens the panel; a
## View Camp button under the camp's name opens it (change_16_probe covers placement and the guide).
func camp_entry_checks() -> void:
    fresh()
    var camp: Array=sim.campaign.stage().spawns[1]
    sim.state.camps_known["1"]=[1]   # fixture: camp sighted
    sim.state.player.x=float(camp[0])+300;sim.state.player.y=float(camp[1]);game._settle_camp()
    sim.state.player.quiet=99.0
    sim.state.player.x=float(camp[0])+20;sim.movement=Vector2.LEFT   # fixture: walked in by hand
    await frames(3)
    check(not game.sheet.visible,"Walking into a camp no longer opens its panel (Change 16)")
    check(game.get_node("Safe/Layout/Map/ViewCamp").visible and game.view_camp==1,"…a View Camp button shows instead")
    game.get_node("Safe/Layout/Map/ViewCamp").pressed.emit();await frames(2)
    check(game.sheet.visible and game.panel=="camp" and game.selected_camp==1,"View Camp opens its panel")
    game._close();sim.movement=Vector2.ZERO
    sim.state.player.x=float(camp[0])+300;await frames(2)
    check(not game.get_node("Safe/Layout/Map/ViewCamp").visible,"Leaving the camp hides the button")
    sim.state.player.x=float(camp[0]);await frames(2)
    check(not game.sheet.visible,"Arriving without walking (teleport/respawn/auto-farm) never opens it")

## 2.2 Upgrades replaces Stats in the navigation; Stats opens from Settings.
func nav_checks() -> void:
    fresh()
    var nav: Node=game.dock.get_node("Navigation")
    check(nav.get_node_or_null("Stats")==null and nav.get_node_or_null("Upgrades")!=null,"Navigation has Upgrades, not Stats")
    nav.get_node("Upgrades").pressed.emit();await frames(2)
    check(game.panel=="upgrades","Upgrades opens Player Upgrades")
    nav.get_node("Upgrades").pressed.emit();await frames(2)
    check(not game.sheet.visible,"Upgrades toggles closed")
    nav.get_node("Settings").pressed.emit();await frames(2)
    var stats: Button=_button(game.rows,tr("STATS_OPEN"))
    check(stats!=null,"Settings lists Stats")
    if stats:
        stats.pressed.emit();await frames(2)
    check(game.panel=="stats" and _find_label(game.rows,tr("STATS_SECTION_OFFENSE"))!=null and _find_label(game.rows,tr("STATS_TIME_RUN"))!=null,"Stats opens with sections and playtime")
    check(_button(game.rows,tr("PANEL_UPGRADES"))==null,"Stats has no second way into a duplicate upgrades panel")
    game._close()

## 2.6 Equipped weapon and outfit are pinned, independent of filter and order.
func pinned_checks() -> void:
    fresh()
    sim.add_item("wood_sword",2);sim.add_item("unit-blue-cap_outfit",2);sim.add_item("stone_axe",1)
    sim.equip("wood_sword");sim.equip("unit-blue-cap_outfit");game._refresh_slots()
    var pinned: Node=game.dock.get_node("Inventory/GearColumn/Head/Equipped")
    check(pinned.get_node("Weapon").icon==game.icon_cache["wood_sword"] and pinned.get_node("Outfit").icon==game.icon_cache["unit-blue-cap_outfit"],"Dock pins the equipped weapon and outfit")
    game.inventory_filter=2;game._open("inventory");await frames(3)
    var texts: Array=[]
    for b in game.pinned_rows.find_children("*","Button",true,false):texts.append(b.text)
    check(texts.size()==2 and texts[0].contains(sim.catalog.display_name("wood_sword")) and texts[1].contains(sim.catalog.display_name("unit-blue-cap_outfit")),"Inventory panel pins both, even under the Outfits filter")
    check(_count_list_rows("wood_sword")==0,"The filtered list itself still respects the filter")
    game.inventory_filter=0;game._close()
    sim.equip("wood_sword");game._refresh_slots()
    check(pinned.get_node("Weapon").icon==null,"Unequipping clears the pinned weapon")
    check(sim.quantity("wood_sword")==2,"Pinning never changes quantities")

## 2.7 Equipped item on top, selected below by Equip, per-stat deltas; placeholder for an empty slot.
func compare_checks() -> void:
    fresh()
    sim.add_item("wood_sword",1);sim.add_item("stone_axe",1);sim.add_item("unit-blue-cap_outfit",1);sim.equip("wood_sword")
    game.selected="stone_axe";game.selected_slot=-1;game._open("item");await frames(3)
    var top:=_find_label(game.rows,tr("COMPARE_EQUIPPED"));var below:=_find_label(game.rows,tr("COMPARE_SELECTED"))
    check(top!=null and below!=null and top.get_global_rect().position.y<below.get_global_rect().position.y,"Equipped card above the selected card")
    check(_find_label_containing(game.rows,"▲")!=null,"Gains show with ▲ and a number")
    check(_find_label_containing(game.rows,tr("COMPARE_MIXED"))!=null or _find_label_containing(game.rows,tr("COMPARE_UPGRADE"))!=null,"A one-line verdict is shown")
    check(_button(game.actions,tr("EQUIP"))!=null and _button(game.rows,"Sell")==null,"Equip is pinned; no Sell")
    game.selected="unit-blue-cap_outfit";game._open("item");await frames(3)
    check(_find_label(game.rows,tr("NOTHING_EQUIPPED"))!=null,"Empty outfit slot shows a placeholder")
    game._close()

## 2.5 HP numbers inside actor bars.
func hp_text_checks() -> void:
    fresh()
    check(LootActorView.hp_text(12.3,25)=="13/25" and LootActorView.hp_text(1234,5678)=="1.2K/5.7K","HP text: rounded up, abbreviated from 1,000")
    var e: Dictionary=sim.state.enemies[0]
    e.hp=float(sim.enemy_definition(int(e.group),int(e.variant)).hp)*.5
    game.world.following_player=false;game.world.camera_position=sim.position_of(e) # Change 24 fixture: views animate only on screen
    await frames(3)
    var view=game.world.views[e.id]
    check(view.get_node("HP/Text").text==LootActorView.hp_text(e.hp,view.max_hp),"Enemy bar shows its remaining/maximum HP")
    game.world.follow_player()

## 3.1-3.3, 3.7 Skills merge their own copies; the first copy unlocks its upgrades once.
var notices:=0
func _notice(_family: String) -> void:notices+=1
func skill_checks() -> void:
    fresh()
    notices=0
    sim.skill_discovered.connect(_notice)
    check(sim.upgrade_block_reason("cooldown_frost")=="UNDISCOVERED","Frost upgrades hidden before Frost is found")
    sim.add_item("skill_frost",1);sim.add_item("skill_frost",3)
    check(notices==1 and sim.skill_seen("frost"),"First Frost notifies once; duplicates stay silent")
    check(sim.upgrade_block_reason("cooldown_frost")!="UNDISCOVERED","Frost upgrades unlocked")
    check(sim.merge("skill_frost",true) and sim.record("skill_frost").merge==3 and str(sim.catalog.items["skill_frost"].next)=="","Skill merges copies and never evolves")
    sim.skill_discovered.disconnect(_notice)
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1;sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    sim.campaign.begin_prestige();sim.prestige(sim.campaign.offered_cards()[0])
    check(sim.skill_seen("frost") and sim.quantity("skill_frost")==0,"Discovery survives prestige; the item does not")

## 3.4-3.6 Boss weapon tiers, 5% per carried item, Loot Chance 15 x 0.5 points.
func loot_checks() -> void:
    fresh()
    var bad:=0
    for st in sim.catalog.stages:
        var normal_tier:=0
        for g in st.groups:
            if not sim.catalog.groups[g].boss:normal_tier=int(sim.catalog.items[sim.catalog.groups[g].weapon].tier)
        for g in st.groups:
            var d: Dictionary=sim.catalog.groups[g]
            # Change 51 supersedes "+1 tier": a boss drops its stage's tier (boss-enhanced, Change 52).
            if d.boss and (int(sim.catalog.items[d.weapon].tier)!=normal_tier or not d.loot.has(d.weapon)):bad+=1
            if not d.boss and not is_equal_approx(sim.gear_chance(g),.05):bad+=1
            if d.boss and not is_equal_approx(sim.gear_chance(g),.3):bad+=1
    check(bad==0,"Bosses carry and drop their stage's tier (Change 51); normals 5%, bosses 30% per item on every stage")
    sim.state.upgrades["loot:0"]=15
    check(is_equal_approx(sim.gear_chance(0),.125) and int(sim.catalog.upgrades.loot.cap)==15,"Loot Chance 15 levels reach 12.5% per item")
    var g: int=sim.campaign.group_id("unit-blue-cap")
    check(sim.enemy_definition(g,2).loot.size()==2,"Each carried item rolls on its own (two items, two rolls)")

## 6 Price rules.
func price_checks() -> void:
    fresh()
    var ok:=true
    for n in range(0,30):
        sim.state.upgrades["gear_slots"]=n
        var a: int=sim.upgrade_cost("gear_slots")
        sim.state.upgrades["gear_slots"]=n+1
        if sim.upgrade_cost("gear_slots")<a+1:ok=false
    sim.state.upgrades["gear_slots"]=0
    check(ok and sim.upgrade_cost("gear_slots")==5,"Inventory slots start at 5 gems and rise at least 1 each")
    sim.state.upgrades.erase("gear_slots")
    var last:=0;ok=true
    for st in range(1,4):
        for r in range(3):
            var c: int=sim.upgrade_cost("map_detail",st)
            if c<=last:ok=false
            last=c;sim.state.upgrades["map_detail:%d" % st]=r+1
    check(ok,"Map Details: every purchase costs more than the one before")
    # Change 16: Collect Batch is bought with Gems (50 on Winter I), still x3 per level.
    check(str(sim.catalog.upgrades.collect_batch.currency)=="gems" and sim.upgrade_cost("collect_batch",0)==50 and float(sim.catalog.upgrades.collect_batch.growth)>=3.0,"Auto-Collect Batch is a premium Gem upgrade with steep growth")
    # Change 13 sets the second skill slot to 300 gems (auto-use keeps its Change 8 price).
    check(sim.upgrade_cost("auto_use")==100 and sim.upgrade_cost("skill_slots")==300,"Gem first prices: auto-use 100, second skill slot 300 (Change 13)")

## 4.2 Followed opportunity tracker: name, icon, step and Ready.
func follow_checks() -> void:
    fresh()
    sim.state.opportunities["expedition_o1"]={"ready":false,"baseline":{},"step":1,"count":12}
    check(sim.campaign.toggle_follow("expedition_o1"),"Follow an opportunity in progress")
    game.elapsed=1.0;await frames(3)
    var tracker: Control=game.get_node("Safe/Layout/Map/FollowTracker")
    var step: String=tracker.get_node("Row/Text/Step").text
    check(tracker.visible and step.begins_with("Step 2/3") and step.get_slice("
",0).ends_with("12/100"),"Tracker shows step and numeric progress: "+step.replace("
"," / "))
    check(tracker.get_node("Row/Icon").texture!=null and tracker.get_node("Row/Text/Name").text!="","Tracker shows icon and name")
    var map: Control=game.get_node("Safe/Layout/Map")
    game._layout_trackers()
    check(is_equal_approx(tracker.position.x,game.HUD_MARGIN) and tracker.get_rect().end.y<map.size.y*.5 and not tracker.get_global_rect().intersects(game.get_node("Safe/Layout/Map/Joystick").get_global_rect()),"Tracker sits in the left rail in the upper map, clear of the joystick (Change 72) %s stick %s map %s" % [tracker.get_rect(),game.get_node("Safe/Layout/Map/Joystick").get_rect(),game.get_node("Safe/Layout/Map").size])
    sim.state.opportunities.expedition_o1.ready=true
    game.elapsed=1.0;await frames(3)
    check(tracker.visible and tracker.get_node("Row/Text/Step").text==tr("FOLLOW_READY"),"Ready state shown until unfollowed")
    check(not sim.campaign.can_follow("expedition_o1"),"A ready opportunity cannot be newly followed")
    sim.campaign.toggle_follow("expedition_o1");game.elapsed=1.0;await frames(3)
    check(not tracker.visible,"Unfollow hides the tracker")

## 5.1-5.4 Vision shows and allows fighting; discovery needs exploring; markers only for found spots.
func discovery_checks() -> void:
    fresh()
    var g: int=sim.campaign.group_id("unit-blue-cap")
    var e: Dictionary={}
    for a in sim.state.enemies:
        if int(a.group)==g and int(a.variant)==1:
            e=a;break
    sim.state.player.x=float(e.x)+80;sim.state.player.y=float(e.y)   # fixture: within sight, not explored
    sim.state.explored["1"]={};sim.state.discovered={};sim.state.discovered_spots={}
    check(sim.campaign.can_see(sim.position_of(e)) and not sim.campaign.cell_known(sim.position_of(e)),"An enemy 80 away is visible but its ground unexplored")
    check(sim.campaign.target_allowed(e),"A visible enemy can be fought")
    check(not sim.campaign.spot_discovered(g,1),"Sight alone never discovers its spot")
    var map=preload("res://scripts/game/map_view.gd").new();map.sim=sim;map.size=Vector2(400,400)
    sim.state.upgrades["map_detail:1"]=3
    check(map.spots(map.transform_rect(),1.0).is_empty(),"No marker for an undiscovered spot at Map Details 3")
    sim.campaign.discover_spot(g,1)
    var found: Array=map.spots(map.transform_rect(),1.0)
    check(found.size()==1 and found[0][0]==g and found[0][1]==1,"Exactly one marker for the one found spot (not the whole type)")
    check(sim.enemy_definition(g,1).body=="" and sim.enemy_definition(g,1).weapon!="","That spot's loadout is weapon-only")
    map.free()
    sim.state.upgrades["focus"]=1 # Change 65: one global unlock
    var refused: bool=not sim.focus(g,0)
    var accepted: bool=sim.focus(g,1)
    check(refused and accepted,"Focus refuses an unfound spot and accepts a found one")

## 2.4 Prestige banner centred at the top of the safe area.
func banner_checks() -> void:
    fresh()
    sim.milestone.emit("discovered","hunter_o1")
    await frames(4)
    var b: Control=game.banner
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var center:=b.position.x+b.size.x*.5
    var expected: float=insets.x+(game.size.x-insets.x-insets.z)*.5
    check(b.visible and absf(center-expected)<=2.0,"Banner horizontally centred (%.1f vs %.1f)" % [center,expected])
    check(b.position.y>=insets.y and b.position.y<=insets.y+game.banner_top_gap+1,"Banner at the top of the safe area")

func _buttons(root: Node) -> Array:return root.find_children("*","Button",true,false)
func _button(root: Node,text: String) -> Button:
    for b in _buttons(root):
        if b.text==text:return b
    return null
func _find_label(root: Node,text: String) -> Label:
    for l in root.find_children("*","Label",true,false):
        if l.text==text:return l
    return null
func _find_label_containing(root: Node,text: String) -> Label:
    for l in root.find_children("*","Label",true,false):
        if l.text.contains(text):return l
    return null
func _count_list_rows(id: String) -> int:
    var n:=0
    for b in _buttons(game.rows):
        if b.text.begins_with(sim.catalog.display_name(id)+" ·"):n+=1
    return n
