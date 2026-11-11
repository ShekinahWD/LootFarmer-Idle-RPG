extends Node
## Change 66 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## - Enemy kill achievements: damage per milestone unchanged (thresholds, 5%, normal and boss types, 0 /
##   intermediate / full progress); no Gem Chance from them in gem_chance(), in real drop rolls or in the
##   enemy panel; the other Gem Chance sources (upgrade levels, Gem Wisdom, Boss Gem Chance) intact; an
##   existing profile keeps kills and damage across save/load and Prestige with no refund or drift.
## - Gem Chance: level 1 costs 10 Gems (+0.5 points), level 2 40, later prices unchanged, a low balance
##   refuses without spending, an owned level 1 stays owned; the Player Upgrades button shows 10.
## - Guided map_mastery lesson: after enemy_pins; the arrow on the live HUD chip; the chip opens this map's
##   five goals (arrow on Close, caption names them); Close finishes it; the World route (Map Mastery ->
##   Details); closing early resumes; save/load; ordered migration of older flows; Prestige keeps it;
##   Basic and None never see it; 100% explored shows no hint and still counts for the Explore goal.
## - Focused Farming copy in Player Upgrades and Help; 25 Gems; after death and respawn the hero returns
##   to the selected enemy and keeps farming.
const HelpCards=preload("res://scripts/game/help_cards.gd")
const FOCUS_COPY:="Select an enemy to farm automatically. If your hero dies, they'll return to that enemy and continue farming after respawning."
var checks:=0
var failures:=0
var game
var sim
var guide
var flow
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func near(a: float,b: float) -> bool:return absf(a-b)<1e-6
func _ready() -> void:call_deferred("run")

func run() -> void:
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;guide=game.guide;flow=sim.campaign.guided
    await frames()
    await achievement_checks()
    await price_checks()
    await mastery_lesson_checks()
    await focus_copy_checks()
    print("CHANGE_66_CHECKS %d FAILURES %d" % [checks,failures])
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- helpers
func fresh(mode:="none") -> void:
    get_tree().paused=false
    if game.help_viewer.visible:game.help_viewer.hide()
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode=mode
    if mode!="guided":sim.campaign.onboarding.reveal_all(true)
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()
    game.get_node("PrestigeConfirm").close();game._cancel_confirm()
    guide.long_shown.clear()
    sim.state.player.quiet=1e9
    for e in sim.state.enemies:e.aggro=false
func reload() -> void:
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
func done_until(step: String) -> void:
    flow.data().done=flow.STEPS.slice(0,flow.STEPS.find(step))
func snowman() -> Dictionary:
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id=="boss-snowman":return e
    return {}
func find_snowman() -> void:
    var s:=snowman()
    var keep:=Vector2(sim.state.player.x,sim.state.player.y)
    sim.state.player.x=s.x;sim.state.player.y=s.y+40;sim.campaign.reveal()
    sim.campaign.evaluate()
    sim.state.player.x=keep.x;sim.state.player.y=keep.y
func close_button() -> Button:return game.get_node("Sheet/Margin/Content/Header/Close")
func panel_button(key: String) -> Button:
    for root in [game.actions,game.rows]:
        for b in root.find_children("*","Button",true,false):
            if b.get_meta("guide","")==key and b.is_visible_in_tree() and not b.is_queued_for_deletion():return b
    return null
func panel_text() -> String:
    var out: Array=[]
    for root in [game.actions,game.rows]:
        for node in root.find_children("*","Label",true,false):
            if node.is_visible_in_tree() and not node.is_queued_for_deletion():out.append(node.text)
    return "\n".join(out)
func first_group(boss: bool) -> int:
    for g in range(sim.catalog.groups.size()):
        if bool(sim.catalog.groups[g].boss)==boss and int(sim.catalog.groups[g].stage)==1:return g
    return -1
func prestige_fixture() -> bool:
    sim.state.bosses_found=["boss-snowman"];sim.state.group_kills[sim.campaign.prestige_unlock_group()]=maxi(1,int(sim.state.group_kills[sim.campaign.prestige_unlock_group()]))
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    if not sim.campaign.begin_prestige():return false
    while not sim.state.prestige_batch.is_empty():sim.campaign.choose_card(sim.campaign.offered_cards()[0])
    return true

# ---------------------------------------------------------------- A. kill achievements
func achievement_checks() -> void:
    print("-- kill achievements")
    fresh()
    var a: Dictionary=sim.catalog.progression.achievements
    check(a.kills.map(func(v):return int(v))==[25,100,250,500,1000,2500,5000,10000] and a.boss_kills.map(func(v):return int(v))==[1,3,10,25,50,100,250,500] and near(float(a.damage_per_milestone),.05),"Thresholds and +5% damage per milestone unchanged")
    check(not a.has("gems_per_milestone") and not sim.has_method("achievement_gems"),"No Gem Chance part remains in the catalog or simulation")
    var normal:=first_group(false);var boss:=first_group(true)
    for g in [normal,boss]:
        var t: Array=sim.achievement_thresholds(g)
        for kills in [0,int(t[2]),int(t.back())]:
            sim.state.group_kills[g]=kills # fixture: kill count
            var level: int=sim.achievement_level(g)
            var expected: float=sim.boss_gem_chance() if sim.catalog.groups[g].boss else sim.gem_base_chance()
            check(near(sim.achievement_damage(g),level*.05) and near(sim.gem_chance(g),expected),"%s at %d kills: %d milestones, +%d%% damage, Gem chance %.3f (no achievement part)" % [sim.catalog.groups[g].name,kills,level,roundi(level*5),sim.gem_chance(g)])
    check(sim.achievement_level(normal)==8 and sim.achievement_level(boss)==8,"Full progress: 8 milestones each")
    # The damage formula still applies the bonus against that type only.
    var other:=-1
    for g in range(sim.catalog.groups.size()):
        if g!=normal and not sim.catalog.groups[g].boss:other=g;break
    sim.state.group_kills[other]=0
    check(near(sim.achievement_damage(other),0.0) and near(sim.achievement_damage(normal),.40),"Damage reward targets its own type (+40%% vs %s, +0%% vs another)" % sim.catalog.groups[normal].name)
    # Other Gem Chance sources intact.
    sim.state.upgrades["gem_chance"]=4;sim.state.owned_cards.append("offering_c2") # fixture: 4 levels + Gem Wisdom
    check(near(sim.gem_chance(normal),.05+.02+.05),"Normal: base 5%% + 4 levels (+2) + Gem Wisdom (+5) = 12%% (%.3f)" % sim.gem_chance(normal))
    sim.state.upgrades["boss_gem_chance"]=2
    check(near(sim.gem_chance(boss),.12+.10),"Boss: the same + Boss Gem Chance 2 x 5 points = 22%% (%.3f)" % sim.gem_chance(boss))
    # Real drop rolls with full achievements: the observed rate is the base rate.
    sim.state.upgrades.erase("gem_chance");sim.state.upgrades.erase("boss_gem_chance");sim.state.owned_cards.clear()
    var enemy: Dictionary={}
    for e in sim.state.enemies:
        if int(e.group)==normal:enemy=e;break
    sim.rng.seed=66
    var drops:=0
    var per: float=sim.gem_amount(0,normal)
    for i in range(3000):
        var before: float=sim.state.gems
        sim._reward(enemy)
        if sim.state.gems>before:drops+=1
        sim.state.pickups.clear();sim.state.items.clear()
    check(absf(drops/3000.0-.05)<.015,"Real kills at full achievements drop Gems at the 5%% base (%.3f; the old rule would give 9%%), %s per drop" % [drops/3000.0,per])
    # Enemy panel: damage only, named for this type.
    sim.state.items.clear()
    for v in sim.campaign.variants(normal):sim.campaign.discover_spot(normal,int(v)) # fixture: spot found
    game.group=normal;game.enemy_tab=2;game._open("enemy");await frames(6)
    var text:=panel_text()
    check(text.contains(tr("ACHIEVEMENT_DAMAGE_BONUS") % [sim.catalog.groups[normal].name,40.0]) and text.contains(tr("ACHIEVEMENT_DAMAGE_REWARD") % 5.0),"Achievements tab: damage against %s (+40%%) and +5%% per milestone" % sim.catalog.groups[normal].name)
    check(not text.to_lower().contains("gem chance") and not text.to_lower().contains("points"),"…and no Gem Chance promise")
    print("     ",text.split("\n").slice(0,2))
    game._close();await frames(2)
    # Existing profile with earned milestones: save/load and Prestige keep kills and damage, no gems change.
    fresh()
    sim.state.group_kills[normal]=1000;sim.state.group_kills[boss]=50;sim.state.gems=123.0 # fixture: earned milestones
    var damage_n: float=sim.achievement_damage(normal);var damage_b: float=sim.achievement_damage(boss)
    reload()
    check(int(sim.state.group_kills[normal])==1000 and near(sim.achievement_damage(normal),damage_n) and near(sim.achievement_damage(boss),damage_b) and near(sim.state.gems,123.0) and near(sim.gem_chance(normal),.05),"Save/load: kills and damage kept, no refund, Gem chance 5%")
    check(prestige_fixture(),"Prestige (fixture: ready opportunity)")
    check(int(sim.state.group_kills[normal])==1000 and near(sim.achievement_damage(normal),damage_n) and near(sim.gem_chance(normal),sim.gem_base_chance()),"Prestige keeps kills and damage; no obsolete Gem modifier (%.3f = base %.3f)" % [sim.gem_chance(normal),sim.gem_base_chance()])

# ---------------------------------------------------------------- B. Gem Chance price
func price_checks() -> void:
    print("-- Gem Chance price")
    fresh()
    var up: Dictionary=sim.catalog.upgrades.gem_chance
    check(up.prices.map(func(v):return int(v))==[10,40,58,80,105,135,170,210,260,320,390,470,560,660,770,890,1020,1160,1310,1470] and int(up.cap)==20 and near(float(up.effect),.005),"Prices 10, 40, 58 … 1,470; 20 levels of +0.5 points")
    check(sim.upgrade_cost("gem_chance")==10,"Level 1 costs 10 Gems")
    sim.state.gems=9.0
    check(not sim.buy_upgrade("gem_chance") and near(sim.state.gems,9.0) and sim.level("gem_chance")==0,"9 Gems: refused, nothing spent")
    sim.state.gems=10.0
    check(sim.buy_upgrade("gem_chance") and near(sim.state.gems,0.0) and sim.level("gem_chance")==1 and near(sim.gem_base_chance(),.055),"10 Gems: bought, +0.5 points (5.5%)")
    check(sim.upgrade_cost("gem_chance")==40,"Level 2 costs 40 Gems")
    sim.state.gems=39.0
    check(not sim.buy_upgrade("gem_chance") and near(sim.state.gems,39.0),"39 Gems: refused")
    sim.state.gems=40.0
    check(sim.buy_upgrade("gem_chance") and near(sim.state.gems,0.0) and sim.upgrade_cost("gem_chance")==58,"40 Gems: level 2; level 3 costs 58")
    check(sim.upgrade_cost("gem_amount")==25 and sim.upgrade_cost("boss_gem_chance")==50 and sim.upgrade_cost("focus")==25,"Gem Amount 25, Boss Gem Chance 50 and Focused Farming 25 unchanged")
    # A profile that bought level 1 at 25 keeps it (no refund).
    fresh();sim.state.upgrades["gem_chance"]=1;sim.state.gems=7.0 # fixture: old purchase
    reload()
    check(sim.level("gem_chance")==1 and near(sim.state.gems,7.0) and sim.upgrade_cost("gem_chance")==40,"An owned level 1 stays owned, no refund; next costs 40")
    # The Player Upgrades Gems tab shows the 10-Gem price.
    fresh();sim.state.gems=10.0
    game.player_tab=3;game._open("upgrades");await frames(6)
    var buy: Button=null
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("upgrade","")=="gem_chance" and b.is_visible_in_tree():buy=b
    check(buy!=null and buy.text==game.fmt_cost(10) and not buy.disabled,"Gems tab: Gem Chance button reads %s and is enabled" % (buy.text if buy else "?"))
    buy.pressed.emit();await frames(3)
    check(sim.level("gem_chance")==1 and near(sim.state.gems,0.0),"Tapping it buys level 1 for 10 Gems")
    game._close();await frames(2)

# ---------------------------------------------------------------- C. Guided Map Mastery lesson
func at_lesson() -> void:
    fresh("guided");done_until("map_mastery");find_snowman()
    for i in range(60): # the HUD refreshes the chip every 0.15 s
        await get_tree().process_frame
        if guide.pending=="map_mastery" and guide.pointer.visible:break

func mastery_lesson_checks() -> void:
    print("-- Guided Map Mastery")
    check(flow.STEPS.size()==36 and flow.STEPS.find("map_mastery")==flow.STEPS.find("enemy_pins")+1 and flow.STEPS.find("hunt_follow")==flow.STEPS.find("map_mastery")+1,"map_mastery sits between enemy_pins and hunt_follow (36 steps)")
    await at_lesson()
    var chip: Button=game.get_node("Safe/Layout/Map/Mastery")
    check(flow.next_step()=="map_mastery" and chip.visible,"After the enemy markers the Mastery chip is on screen and the lesson is next")
    check(guide.step=="map_mastery" and guide.target==chip and guide.pointer.visible and guide.card.visible and guide.title.text==tr("GUIDE_MAP_MASTERY"),"Arrow on the live Mastery chip, caption \"%s\"" % guide.title.text)
    check(int(sim.campaign.mastery.data().explored.get("1",0))<100,"Nothing about 100%% exploration is required (Winter I %s%%)" % str(sim.campaign.mastery.data().explored.get("1",0)))
    chip.pressed.emit();await frames(8)
    check(game.sheet.visible and game.panel=="mastery" and game.mastery_stage==1 and bool(flow.data().get("mastery_viewed",false)),"The chip opens Winter I's Mastery page (seen)")
    var text:=panel_text()
    var five:=true
    for c in ["EXPLORE","HUNT","RESEARCH","COLLECT","FORGE"]:five=five and text.contains(tr("MASTERY_"+c))
    check(five,"The real page lists Explore, Hunt, Research, Collect and Forge with their progress")
    check(guide.step=="map_mastery_close" and guide.target==close_button() and guide.pointer.visible and guide.card.visible,"Arrow on the live Close button (%s)" % guide.step)
    check(guide.support.text.contains("Explore") and guide.support.text.contains("Forge") and guide.support.text.contains("Close"),"Caption names the five goals, the permanent reward and Close")
    check(not guide.card.get_global_rect().intersects(game.sheet.get_global_rect()),"Caption sits clear of the open panel")
    check(not flow.data().done.has("map_mastery"),"Opening alone does not finish it")
    # Save/load with the page seen: the lesson resumes at Close.
    game._close();await frames(2)
    check(flow.data().done.has("map_mastery") and flow.next_step()=="hunt_follow","Close finishes the lesson; the hunt lesson follows")
    reload();await frames(4)
    check(flow.data().done.has("map_mastery") and flow.next_step()=="hunt_follow","…and stays finished after a reload")
    # Reload while the page is open: seen is saved, reopening points straight at Close.
    await at_lesson()
    chip.pressed.emit();await frames(6)
    reload();await frames(4)
    check(not flow.data().done.has("map_mastery") and bool(flow.data().get("mastery_viewed",false)),"A reload with the page open keeps the seen record (lesson still pending)")
    close_button().pressed.emit();await frames(3)
    check(flow.data().done.has("map_mastery"),"…then Close finishes it")
    # Seen earlier but closed without finishing (fixture: e.g. the app was closed on the page): the arrow
    # is on the chip; any way into Map Mastery points straight at Close.
    await at_lesson()
    flow.data().mastery_viewed=true # fixture
    await frames(3)
    check(guide.step=="map_mastery" and guide.target==chip,"Seen but not closed: the arrow is on the chip again")
    game._open("world");await frames(6);panel_button("mastery").pressed.emit();await frames(6)
    check(game.mastery_stage==0 and guide.step=="map_mastery_close" and guide.target==close_button(),"Reopened (overview): the arrow goes straight to Close")
    close_button().pressed.emit();await frames(3)
    check(flow.data().done.has("map_mastery"),"Close finishes it")
    # World route: World -> Map Mastery (overview) -> this map's Details -> page -> Back -> Close.
    await at_lesson()
    game._open("world");await frames(8)
    var world_button:=panel_button("mastery")
    check(guide.step=="map_mastery_world" and world_button!=null and guide.target==world_button and not world_button.disabled,"In World the arrow is on the Map Mastery button")
    world_button.pressed.emit();await frames(8)
    var details:=panel_button("mastery_map_1")
    check(game.panel=="mastery" and game.mastery_stage==0 and guide.step=="map_mastery_details" and details!=null and guide.target==details,"Overview: the arrow is on Winter I's Details")
    # Closing early does not finish it and the arrow returns to the chip.
    game._close();await frames(4)
    check(not flow.data().done.has("map_mastery") and guide.step=="map_mastery" and guide.target==chip,"Closing before the goals were shown: not finished, arrow back on the chip")
    game._open("world");await frames(6);panel_button("mastery").pressed.emit();await frames(6)
    panel_button("mastery_map_1").pressed.emit();await frames(8)
    check(game.mastery_stage==1 and guide.step=="map_mastery_close" and guide.target==close_button(),"Details opens the five goals; the arrow moves to Close")
    panel_button("mastery_back").pressed.emit();await frames(6)
    check(game.mastery_stage==0 and guide.step=="map_mastery_close" and guide.target==close_button(),"Back to the overview keeps the arrow on Close (goals already seen)")
    close_button().pressed.emit();await frames(3)
    check(flow.data().done.has("map_mastery") and flow.next_step()=="hunt_follow","Close finishes the World route too")
    # Other panels suspend it; nothing is purchased or required.
    await at_lesson()
    game._open("missions");await frames(6)
    check(not guide.pointer.visible or guide.suspended_by!="","Another panel (Missions) suspends the lesson")
    game._close();await frames(4)
    check(guide.step=="map_mastery" and guide.target==chip,"…and it returns on the chip")
    # Ordered migration of older flows (version 61, no map_mastery id).
    for case in [["enemy_pins",false,"at the insertion point: meets the lesson"],["hunt_follow",true,"past it (hunt_follow done): treated as done"],["tutorial_final",true,"finished tutorial: stays finished"]]:
        fresh("guided")
        var steps: Array=flow.STEPS.slice(0,flow.STEPS.find(case[0])+1).filter(func(id):return id!="map_mastery")
        if case[0]=="tutorial_final":steps=flow.STEPS.filter(func(id):return id!="map_mastery")
        flow.data().done=steps;flow.data().version=61;sim.state.tutorial.seen.append("mastery_intro") # fixture: Change 65 save, hint seen
        find_snowman()
        reload()
        check(flow.data().done.has("map_mastery")==bool(case[1]) and int(flow.data().version)==66,"Version 61 flow %s (%s)" % [case[2],flow.next_step()])
        if not case[1]:check(flow.next_step()=="map_mastery","…the old \"hint seen\" record does not skip it")
        if case[0]=="tutorial_final":check(flow.complete(),"…complete")
    # Prestige keeps it; Hard Reset (a new profile) starts the tutorial over.
    await at_lesson()
    chip.pressed.emit();await frames(4);game._close();await frames(2)
    flow.data().done=flow.STEPS.slice(0,flow.STEPS.find("prestige_optional")) # fixture: at the optional Prestige lesson
    check(prestige_fixture() and flow.data().done.has("map_mastery") and flow.next_step()!="map_mastery","Prestige keeps the finished lesson (next %s)" % flow.next_step())
    sim.new_profile();sim.state.tutorial.mode="guided"
    check(not flow.data().done.has("map_mastery"),"A Hard Reset profile has not seen it")
    # 100% exploration: no hint, the Explore goal still counts it.
    await at_lesson()
    sim.campaign.mastery.data().explored["1"]=100;await frames(4)
    check(guide.pending=="map_mastery" and not sim.state.tutorial.seen.has("mastery_intro") and guide.title.text==tr("GUIDE_MAP_MASTERY"),"100% explored during the lesson: the lesson, no extra hint")
    var part: Array=sim.campaign.mastery.objective(1,"explore").parts[0]
    check(str(part[0])=="explored" and int(part[2])==100,"…and the Explore goal records 100%")
    fresh("guided");flow.data().done=flow.STEPS.duplicate();sim.campaign.onboarding.reveal_all(true)
    sim.campaign.mastery.data().explored["1"]=100;await frames(6)
    check(not guide.step.begins_with("map_mastery") and guide.pending!="mastery_intro" and not sim.state.tutorial.seen.has("mastery_intro"),"Finished tutorial at 100%%: no Mastery hint (%s)" % guide.pending)
    # Basic and None: never this lesson, Map Mastery is open with no pointer.
    for mode in ["basic","none"]:
        fresh(mode);sim.state.tutorial.seen.append(guide.ROAD_AHEAD_ID);HelpCards.progress(sim.state.tutorial).basic_done=true;game.help_viewer.hide();sim.held=false
        sim.campaign.mastery.data().explored["1"]=100;await frames(6)
        check(chip.visible and not guide.step.begins_with("map_mastery") and not guide.pointer.visible,"%s: Mastery chip available, no lesson or arrow" % mode)
        chip.pressed.emit();await frames(4)
        check(game.panel=="mastery" and not guide.pointer.visible and not guide.card.visible,"%s: opening Map Mastery shows no guide" % mode)
        game._close();await frames(2)
    # The shared Help card names the five goals.
    check(tr("HELP_CARD_MAP_DETAILS_MASTERY_SUPPORT").contains("Explore, Hunt, Research, Collect and Forge"),"Help card: Map Mastery's five goals named as on the panel")

# ---------------------------------------------------------------- D. Focused Farming copy and behaviour
func focus_copy_checks() -> void:
    print("-- Focused Farming copy")
    check(tr("FOCUS_GLOBAL_BENEFIT")==FOCUS_COPY,"Unlock description is the approved copy")
    fresh();sim.state.gems=25.0
    game.player_tab=0;game._open("upgrades");await frames(6)
    check(panel_text().contains(FOCUS_COPY),"Player Upgrades: the Focused Farming row shows it")
    var buy: Button=null
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("upgrade","")=="focus" and b.is_visible_in_tree():buy=b
    check(buy!=null and buy.text==game.fmt_cost(25) and sim.upgrade_cost("focus")==25,"…priced 25 Gems")
    buy.pressed.emit();await frames(4)
    game._refresh_panel();await frames(3)
    check(sim.focus_owned() and near(sim.state.gems,0.0) and panel_text().contains(tr("FOCUS_GLOBAL_OWNED")),"Bought once: owned line shown")
    if not panel_text().contains(tr("FOCUS_GLOBAL_OWNED")):print("     panel: ",panel_text().replace("
"," | ").substr(0,600))
    game._close();await frames(2)
    check(tr("HELP_CARD_ADVANCED_FARMING_SUPPORT").contains("respawn") and tr("HELP_CARD_PLAYER_UPGRADES_SUPPORT").contains("25 Gems"),"Help cards: return after respawning; 25 Gems")
    # Behaviour: Farm a spot, die, respawn at the camp, walk back and keep farming.
    var g:=first_group(false)
    for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,int(v)) # fixture: spot found
    check(sim.focus(g,2) and int(sim.state.focus)==g,"Farm on %s" % sim.catalog.groups[g].name)
    sim.state.player.hp=0.0;sim._kill(sim.state.player)
    check(int(sim.state.focus)==g,"Death keeps the selected enemy")
    var t:=0.0
    while sim.state.player.hp<=0 and t<30.0:sim.step(.05);t+=.05
    var spot: Vector2=sim.farming_position()
    var start: float=sim.position_of(sim.state.player).distance_to(spot)
    for i in range(int(4.0/.05)):sim.step(.05)
    var after: float=sim.position_of(sim.state.player).distance_to(spot)
    check(sim.state.player.hp>0 and int(sim.state.focus)==g and (after<start-20 or after<60),"After respawning the hero walks back to the spot (%.0f -> %.0f px) and farming stays on" % [start,after])
