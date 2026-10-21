extends Node
## Change 7 behaviour probe (Android playtest corrections). Real main scene and simulation; one
## named case per acceptance item of the brief. State set directly is labelled.
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
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=77123;game._close()
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false);fresh()
    await tutorial_checks()
    shared_weapon_checks()
    outfit_checks()
    await save_mapping_checks()
    await offline_checks()
    await prestige_checks()
    await mission_checks()
    await tonic_checks()
    await nav_checks()
    fog_checks()
    await world_checks()
    await playtime_checks()
    print("CHANGE_7_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

## 1. The Equip lesson follows the real inventory in every mode.
func tutorial_checks() -> void:
    fresh();var guide=game.guide
    sim.state.tutorial.mode="guided";sim.state.tutorial.done=["move","kill","collect"]
    sim.add_item("potion",1);guide.evaluate()
    check(guide.pending=="equip" and guide.step=="equip_find","Guided: a consumable first drop asks to find gear, not to equip")
    check(guide.target==null or guide.target.get_parent().name=="Gear","Guided: no Equip control is targeted without gear")
    var p: Dictionary=sim.state.player
    sim.state.pickups.append({"uid":991,"item":"wood_sword","x":p.x+20.0,"y":p.y,"ttl":300.0,"group":0});guide.evaluate()
    check(guide.step=="equip_collect" and guide.world_target!=Vector2.INF,"Guided: visible gear on the ground is the next step")
    sim.state.pickups.clear();sim.add_item("wood_sword",1);guide.evaluate()
    check(guide.step=="equip" and guide.target!=null,"Guided: owned gear points at its slot")
    sim.equip("wood_sword");guide._complete_lessons();guide.evaluate()
    check(sim.state.tutorial.done.has("equip"),"Guided: equipping completes the lesson")
    for mode in ["basic","none"]:
        fresh();sim.state.tutorial.mode=mode;sim.add_item("potion",1);guide.evaluate()
        check(not guide.step.begins_with("equip"),mode+": never asks for an Equip step")
    await frames(2)

## 2. One identity per weapon type and tier, whoever carries it.
func shared_weapon_checks() -> void:
    var c=sim.catalog
    var bad:=0
    for id in c.items:
        if id.ends_with("_weapon") or "_weapon_t" in id:bad+=1
    check(bad==0,"No enemy-specific weapon items remain")
    var families: Dictionary={}
    for g in range(c.groups.size()):
        var d: Dictionary=c.groups[g]
        var w: Dictionary=c.items[d.weapon]
        families[w.family]=true
        # Change 8: bosses carry one tier above their stage's normal enemies.
        if int(w.tier)!=1+(int(d.stage)-1)/2+(1 if d.boss else 0):bad+=1
    check(bad==0 and families.keys().size()==2,"Every enemy carries a shared Sword or Axe of its stage tier (bosses +1, Change 8)")
    check(c.groups[sim.campaign.group_id("unit-red-scarf")].weapon=="wood_sword" and c.groups[sim.campaign.group_id("unit-blue-cap")].weapon=="wood_sword","Red Scarf and Blue Cap carry the same Wood Sword")
    var chain: Array=[];var id:="wood_sword"
    while id!="":chain.append(id);id=c.items[id].next
    check(chain==["wood_sword","stone_sword","iron_sword","gold_sword","diamond_sword","emerald_sword","obsidian_sword"],"Evolution walks the material ladder: "+", ".join(chain))
    var art: Dictionary={}
    for w in chain:art[c.items[w].attack+str(c.items[w].icon)]=true
    check(art.size()==7,"Each tier has its own owned icon and swing art")
    var g: int=sim.campaign.group_id("unit-straw-hat")
    check(sim.enemy_definition(g,1).loot==["stone_sword"] and sim.enemy_definition(g,0).loot==["unit-straw-hat_outfit_t2"] and sim.enemy_definition(g,2).loot.size()==2,"Variants drop the shared weapon or the stage-tier outfit")
    for legacy in c.legacy_items:
        if not c.items.has(c.legacy_items[legacy]):bad+=1
    check(bad==0 and c.legacy_items.has("unit-red-scarf_weapon"),"Every removed id maps to a current item")
    var gear:=0
    for item in c.items.values():if item.kind!="consumable":gear+=1
    check(int(c.upgrades.gear_slots.cap)+3==gear,"Gear slot cap still holds every gear item")
    # Auto-merge finds a type for shared weapons and tiered outfits.
    fresh();sim.state.gems=1000000;sim.state.discovered["0"]=true;sim.buy_upgrade("merge_gear",0)
    check(sim.gear_group("wood_sword")==0 and sim.gear_group("unit-blue-cap_outfit_t3")==0 and sim.can_auto_merge("wood_sword"),"Auto merge covers shared weapons and every outfit tier")

## 3. Same-tier normal outfits are equal; boss outfits are stronger; 30% stored share unchanged.
func outfit_checks() -> void:
    var c=sim.catalog
    var bases: Dictionary={};var spread:=0.0
    for id in c.items:
        var d: Dictionary=c.items[id]
        if d.kind!="outfit" or str(d.art_id).begins_with("boss-"):continue
        var t:=int(d.tier);var hp:=float(d.normal.hp[0])
        if bases.has(t):spread=maxf(spread,absf(bases[t]-hp))
        else:bases[t]=hp
    check(spread<.001,"Normal outfits of a tier share one base")
    check(is_equal_approx(float(c.items["boss-snowman_outfit"].normal.hp[0]),3.0*float(c.items["unit-blue-cap_outfit"].normal.hp[0])) and is_equal_approx(float(c.items["boss-gray-cat_outfit_t2"].normal.hp[0]),3.0*float(c.items["unit-straw-hat_outfit_t2"].normal.hp[0])),"Boss outfits are 3x a normal outfit of the same tier")
    check(is_equal_approx(float(c.progression.stored_weapon_factor),.3),"Stored gear still contributes 30%")
    fresh();sim.add_item("wood_sword",1);sim.add_item("wood_axe",1);sim.equip("wood_sword")
    var stored: Dictionary=sim.stat_sources().SOURCE_STORED
    check(is_equal_approx(float(stored.get("damage",0)),3.2*.3) and is_equal_approx(float(stored.get("hp",0)),12*.3),"An owned Axe adds 30% of its damage and HP")

## 2 (saves). A current-schema save with old weapon ids keeps its gear through a disk reload.
func save_mapping_checks() -> void:
    fresh()
    sim.add_item("wood_sword",5);sim.record("wood_sword").merge=3
    sim.state.items["unit-red-scarf_weapon"]={"qty":4,"merge":9,"extras":{}}
    sim.state.items["unit-chef-hat_weapon_t2"]={"qty":2,"merge":1,"extras":{"crit":.02}}
    sim.state.gear=["wood_sword","unit-red-scarf_weapon","unit-chef-hat_weapon_t2"]
    sim.state.weapon="unit-chef-hat_weapon_t2"
    sim.state.pickups.append({"uid":5,"item":"unit-blue-cap_weapon","x":10.0,"y":10.0,"ttl":100.0,"group":0})
    sim.state.history.push_front({"key":"HISTORY_ITEM","id":"unit-red-scarf_weapon","amount":1.0,"coins":0.0,"time":0.0})
    sim.state.counters["merge:unit-red-scarf_weapon"]=9.0
    sim.state.opportunities["masterwork_o1"]={"ready":false,"baseline":{},"step":0,"count":0,"merge_unit-red-scarf_weapon":9}
    sim.suspended=true # snapshot without reading the removed ids through the catalog
    check(SaveService.save_now(),"Old-id profile writes")
    sim.suspended=false;sim.state.items={};SaveService.load_and_apply()
    check(not SaveService.write_blocked and SaveService.last_load_result not in ["development_reset","invalid_profile_reset"],"Old-id save loads without a reset")
    check(sim.quantity("wood_sword")==9 and int(sim.record("wood_sword").merge)==9,"Same-tier stacks join: quantities add, best merge stays")
    check(sim.quantity("stone_axe")==2 and sim.state.weapon=="stone_axe","Equipped old weapon maps to its shared successor")
    check(sim.state.gear.count("wood_sword")==1 and sim.state.gear.has("stone_axe") and sim.state.pickups[0].item=="wood_sword","Slots and ground loot follow the map")
    check(sim.state.history[0].id=="wood_sword" and sim.state.counters.get("merge:wood_sword",0)==9.0 and sim.state.opportunities.masterwork_o1.has("merge_wood_sword"),"History, counters and opportunity progress follow the map")
    sim.stats();game._open("item");await frames(2);game._close()

## 4. Offline earnings are claimed in game; discovery follows the claim; no double claims.
func offline_checks() -> void:
    fresh();sim.state.offline_total=0.0
    sim.state.offline_snapshot=sim.campaign.offline_snapshot();sim.state.offline_snapshot.time=1000
    sim.campaign.settle_offline(1000+3*3600)
    check(sim.state.coins==0 and sim.state.offline_total==0 and not sim.state.opportunities.has("offline_o1"),"Background settlement pays nothing and discovers nothing")
    var pending: Dictionary=sim.state.offline_pending.duplicate(true)
    check(is_equal_approx(float(pending.coins),360) and is_equal_approx(float(pending.rewarded_hours),3),"Pending claim keeps the offline math")
    sim.campaign.settle_offline(1000+7*3600)
    check(is_equal_approx(float(sim.state.offline_pending.seconds),7*3600) and float(sim.state.offline_pending.coins)>360,"A second absence joins the pending claim")
    var snap=JSON.parse_string(JSON.stringify(sim.snapshot()));sim.restore(snap)
    check(not sim.state.offline_pending.is_empty() and sim.state.coins==0,"Pending claim survives a reload unpaid")
    game.offline_prompted="";game._offer_offline_claim();await frames(3)
    check(game.sheet.visible and game.panel=="offline","The claim step opens in game")
    var claim:=_button(game.actions,tr("OFFLINE_CLAIM"))
    check(claim!=null and not claim.disabled,"Claim button is offered")
    if claim:claim.pressed.emit()
    await frames(3)
    check(sim.state.coins>0 and sim.state.offline_pending.is_empty() and sim.state.opportunities.has("offline_o1"),"Claim pays and then discovers the offline opportunity")
    var coins: float=sim.state.coins
    check(not sim.campaign.claim_offline() and sim.state.coins==coins,"Claim cannot repeat")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    check(sim.state.coins==coins and sim.state.offline_pending.is_empty(),"A reload after claiming grants nothing again")

## 5-6. Ready opportunities cannot be followed; the Prestige button names the gate.
func prestige_checks() -> void:
    fresh()
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    sim.state.opportunities["masterwork_o1"]={"ready":false,"baseline":{},"step":0,"count":0}
    check(not sim.campaign.toggle_follow("hunter_o1") and sim.state.follow=="","Action layer refuses to follow a ready opportunity")
    check(sim.campaign.toggle_follow("masterwork_o1") and sim.state.follow=="masterwork_o1","An opportunity in progress can be followed")
    game._open("prestige");await frames(3)
    check(_count_buttons(game.rows,tr("FOLLOW"))+_count_buttons(game.rows,tr("UNFOLLOW"))==1,"Only the in-progress card offers Follow")
    sim.state.opportunities.masterwork_o1.baseline={};sim.add_item("wood_sword",101);sim.merge("wood_sword",true)
    check(sim.state.opportunities.masterwork_o1.ready and sim.state.follow=="","Becoming ready ends the follow")
    game._close()
    game._refresh_badges()
    var nav: Button=game.dock.get_node("Navigation/Prestige")
    # Change 8 replaced the Winter II gate with the first kill.
    check(nav.text.contains(tr("NAV_PRESTIGE_LOCKED")),"Gated Prestige button names its requirement: "+nav.text.replace("\n"," | "))
    sim.state.group_kills[0]=1;game._refresh_badges()
    check(nav.text==tr("NAV_PRESTIGE"),"Ungated Prestige button returns to its plain label")
    await frames(2)
    check(nav.get_combined_minimum_size().y<=nav.custom_minimum_size.y+12,"Gate label keeps the navigation height")

## 7. In progress, ready and claimed missions look different; claimed has no Claim control.
func mission_checks() -> void:
    fresh()
    var m: Array=sim.state.missions
    m[0].progress=m[0].goal;check(sim.campaign.claim_mission(0),"Mission claims")
    m[1].progress=m[1].goal
    game._open("missions");await frames(3)
    check(_count_buttons(game.rows,tr("CLAIM"))==1,"Exactly the ready mission shows a Claim button")
    check(_find_label(game.rows,tr("MISSION_STATE_CLAIMED"))!=null and _find_label(game.rows,tr("IN_PROGRESS"))!=null,"Claimed and in-progress states are labelled")
    sim.state.main_ready["0"]=true;check(sim.campaign.claim_main(0),"Main objective claims")
    game._refresh_panel(true);await frames(2)
    var toggle:=_button_containing(game.rows,tr("MAIN_COMPLETED_TOGGLE").get_slice("(",0))
    check(toggle!=null,"Completed main objectives stay reachable")
    if toggle:toggle.pressed.emit()
    await frames(2)
    check(_find_label(game.rows,"✓ "+tr("MAIN_0"))!=null,"Completed objective history lists the claimed objective")
    game._close()

## 8. Coin Tonic shows effect and total duration, and its remaining time while active.
func tonic_checks() -> void:
    fresh();sim.add_item("coin_boost",2)
    game.selected="coin_boost";game.selected_slot=sim.state.supplies.find("coin_boost");game._open("item");await frames(3)
    var role:=tr("COIN_TONIC_ROLE") % [game.fmt(sim.normal("coin_boost").coin_bonus*100),game.fmt_value(sim.coin_boost_duration())]
    check(_find_label(game.rows,role)!=null and role.contains("30"),"Description states effect and total duration")
    check(sim.use_item("coin_boost") and is_equal_approx(sim.state.boost_time,30.0),"Real duration unchanged (30 s)")
    for i in range(50):sim.step(.1)
    game._refresh_panel(true);await frames(2)
    check(_find_label_containing(game.rows,"25s left")!=null,"Item panel shows the remaining time")
    game._update_supply_cooldowns()
    var slot=game.dock.get_node("Inventory/SupplyColumn/SupplyScroll/Supplies").get_child(sim.state.supplies.find("coin_boost"))
    check(slot.get_node("Cooldown").text.begins_with("25"),"Supply slot shows the remaining time: "+slot.get_node("Cooldown").text)
    game._close()

## 9-10. Navigation toggles; item comparison keeps signed deltas.
func nav_checks() -> void:
    fresh()
    var nav: Node=game.dock.get_node("Navigation")
    nav.get_node("Upgrades").pressed.emit();await frames(2)
    check(game.sheet.visible and game.panel=="upgrades","Nav opens its panel")
    nav.get_node("Missions").pressed.emit();await frames(2)
    check(game.sheet.visible and game.panel=="missions","Another nav button switches panels")
    nav.get_node("Missions").pressed.emit();await frames(2)
    check(not game.sheet.visible,"Tapping the open panel's button closes it")
    # Change 8: Stats lives in Settings; from it, the Upgrades button switches pages.
    game._open("stats");nav.get_node("Upgrades").pressed.emit();await frames(2)
    check(game.sheet.visible and game.panel=="upgrades","A sub-panel switches to the tapped page instead of closing")
    game._close()
    sim.add_item("wood_sword",1);sim.add_item("stone_sword",1);sim.equip("wood_sword")
    game.selected="stone_sword";game.selected_slot=-1;game._open("item");await frames(3)
    check(_find_label_containing(game.rows,"▲")!=null and _find_label_containing(game.rows,sim.catalog.display_name("wood_sword"))!=null,"Selected-versus-equipped comparison shows a gain and the equipped item")
    game._close()

## 11. Smaller arrival reveal, first enemy still discoverable.
func fog_checks() -> void:
    fresh()
    var rules=sim.campaign.fog_rules
    check(rules.camp_radius<192 and rules.player_radius<=144,"Arrival camp reveal is lower; walking reveal not raised")
    var cells: int=sim.state.explored.get("1",{}).size()
    check(cells<170,"Arrival reveals fewer cells (%d)" % cells)
    # As in Change 6, the first type sits just beyond the arrival reveal; a short walk toward it
    # (under three seconds at base speed) must find it.
    var camp: Array=sim.campaign.stage().spawns[0]
    var start:=Vector2(camp[0],camp[1]);var first: Array=sim.catalog.groups[sim.campaign.group_id("unit-blue-cap")].center
    # Change 8: spots are found by walking to them (48 reveal); sight alone never discovers them.
    var g: int=sim.campaign.group_id("unit-blue-cap")
    sim.campaign.reveal_segment(start,sim.campaign.spot(g,2))
    check(sim.campaign.discovered(g),"The first enemy type is found by walking to its nearest spot")

## 12-15. Boss markers, respawn camera, world weather, self-effect placement.
func world_checks() -> void:
    fresh();sim.state.stage=2;sim.state.unlocked_stage=2;sim._reset_world()
    sim.campaign.reveal_circle(Vector2(800,800),5000);sim.campaign.identify_sites()
    await frames(4)
    var map=preload("res://scripts/game/map_view.gd").new();map.sim=sim
    var boss_g: int=sim.campaign.group_id("boss-cyan-robot")
    var boss: Dictionary=sim.state.enemies.filter(func(a):return int(a.group)==boss_g)[0]
    check(map.marker_visible(boss_g),"Discovered living boss has a marker")
    boss.hp=0.0;boss.respawn=60.0
    check(not map.marker_visible(boss_g),"Defeated boss loses its marker")
    boss.hp=1.0
    check(map.marker_visible(boss_g),"Respawned boss regains its marker")
    sim.state.discovered.erase(str(boss_g));sim.state.discovered_spots.erase(sim.campaign.spot_key(boss_g,2))
    check(not map.marker_visible(boss_g),"Undiscovered boss never shows a marker")
    map.free()
    # Heal on the 2x robot: ground ring on its feet, scaled with it.
    sim.campaign.reveal_circle(Vector2(800,800),5000)
    await frames(2)
    var before: int=game.world.get_children().size()
    game.world._spell(boss.id,"heal",sim.position_of(boss))
    var effect: AnimatedSprite2D=game.world.get_child(game.world.get_child_count()-1)
    check(game.world.get_children().size()==before+1 and is_equal_approx(effect.scale.x,1.5) and is_equal_approx(effect.position.y,boss.y-30.0),"Robot heal sits on its feet at its scale (%.1f, %.1f)" % [effect.scale.x,effect.position.y-boss.y])
    game.world._spell("player","heal",sim.position_of(sim.state.player))
    effect=game.world.get_child(game.world.get_child_count()-1)
    check(is_equal_approx(effect.scale.x,.75) and is_equal_approx(effect.position.y,sim.state.player.y-15.0),"Player heal sits on the player's feet")
    # Revival recenters a dragged camera.
    game.world.pan_camera(Vector2(300,200))
    check(not game.world.following_player,"Drag detaches the camera")
    sim.state.player.hp=0.0;sim._kill(sim.state.player)
    for i in range(int(sim.player_upgrade_value("respawn")*10)+5):sim.step(.1)
    check(sim.state.player.hp>0 and game.world.following_player and game.world.camera_position.distance_to(sim.position_of(sim.state.player))<1,"Revival recenters and resumes follow")
    # Weather belongs to the world: two camera rects agree on every shared particle.
    var weather=null
    for child in game.world.get_children():
        if child.get_script()==preload("res://scripts/game/season_weather.gd"):weather=child
    weather.clock=12.5
    var a: Array=weather.particles(Rect2(0,0,600,600));var b: Array=weather.particles(Rect2(150,100,600,600))
    var shared:=Rect2(150,100,450,500);var pa: Array=[];var pb: Array=[]
    for p in a:if shared.has_point(p[0]):pa.append(p[0])
    for p in b:if shared.has_point(p[0]):pb.append(p[0])
    pa.sort();pb.sort()
    check(not pa.is_empty() and pa==pb,"Weather particles do not move with the camera (%d shared)" % pa.size())
    weather.clock=12.6
    var moved: Array=weather.particles(Rect2(0,0,600,600))
    check(moved.size()>0 and moved[0][0]!=a[0][0],"Particles still drift with time")

## 16. Active playtime: lifetime and current run, no pause/background/offline time.
func playtime_checks() -> void:
    fresh()
    for i in range(100):sim.step(.1)
    check(is_equal_approx(sim.state.playtime_run,10.0) and is_equal_approx(sim.state.playtime_total,10.0),"Ten active seconds count in run and lifetime")
    get_tree().paused=true;sim.step(.1);get_tree().paused=false
    sim.suspended=true;sim.step(.1);sim.suspended=false
    check(is_equal_approx(sim.state.playtime_run,10.0),"Pause and background do not count")
    sim.state.offline_snapshot=sim.campaign.offline_snapshot();sim.state.offline_snapshot.time-=3600;sim.campaign.settle_offline();sim.campaign.claim_offline()
    check(is_equal_approx(sim.state.playtime_total,10.0),"Offline time does not count")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    check(is_equal_approx(sim.state.playtime_total,10.0) and is_equal_approx(sim.state.playtime_run,10.0),"Playtime persists across save and load")
    game._open("stats");await frames(2)
    check(_find_label(game.rows,tr("STATS_TIME_TOTAL"))!=null and _find_label(game.rows,game.fmt_duration(sim.state.playtime_total))!=null and _find_label(game.rows,tr("STATS_TIME_RUN"))!=null,"Stats shows lifetime and run playtime (Change 8 rows)")
    game._close()
    sim.state.group_kills[0]=1;sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    check(sim.campaign.begin_prestige(),"Prestige begins")
    sim.prestige(sim.campaign.offered_cards()[0])
    check(sim.state.prestiges==1 and is_equal_approx(sim.state.playtime_total,10.0) and sim.state.playtime_run==0.0,"Prestige keeps lifetime and resets the run")
    check(game.fmt_duration(3725)=="1h 02m" and game.fmt_duration(249)=="4m 09s" and game.fmt_duration(37)=="37s","Durations are short and readable")

# ---------------------------------------------------------------- helpers
func _buttons(root: Node) -> Array:return root.find_children("*","Button",true,false)
func _button(root: Node,text: String) -> Button:
    for b in _buttons(root):
        if b.text==text:return b
    return null
func _button_containing(root: Node,text: String) -> Button:
    for b in _buttons(root):
        if b.text.contains(text):return b
    return null
func _count_buttons(root: Node,text: String) -> int:
    var n:=0
    for b in _buttons(root):
        if b.text==text:n+=1
    return n
func _find_label(root: Node,text: String) -> Label:
    for l in root.find_children("*","Label",true,false):
        if l.text==text:return l
    return null
func _find_label_containing(root: Node,text: String) -> Label:
    for l in root.find_children("*","Label",true,false):
        if l.text.contains(text):return l
    return null
