extends Node
## Change 16 probe: the map economy (income x1.5 and map-tied Coin prices x1.55 on all eight maps,
## every category of map-specific Coin purchase), Gem Auto-Collect and Collect Batch (prices,
## currency, Prestige, existing levels), save migration of the new records, boss discovery and the
## Prestige unlock, boss names and skill icons, the Winter I objective, mission and Prestige tracking
## together, the follower text of all 33 opportunities, Prestige keeping Gems and exploration, the
## Health Potion's 10% -> 20% and external bonuses, Drop All and its pickup exploits, the Map Mastery
## reward swap and chip, the Cyan Robot's Heal interval, skill descriptions, the Prestige confirmation
## screen, audio hold rules, the Guided path opening, View Camp, Help and the removed development UI.
## Runs with --first-run-complete (menus revealed); the reveal-dependent checks set reveals as fixtures.
var checks:=0
var failures:=0
var sim
var game
var notices: Array=[]
var milestones: Array=[]
var heals: Array=[]
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func near(a: float,b: float,tolerance:=.0001) -> bool:return absf(a-b)<=tolerance*maxf(1.0,absf(b))
func _ready() -> void:call_deferred("run")
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func fresh(mode:="none") -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode=mode;sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=16016;game._close()
    if mode!="none":sim.state.tutorial.seen.append_array(["overview","aggression","skills","groups","prestige","rest","camp_done"]) # fixture: intros seen
    game._cancel_confirm();game.get_node("PrestigeConfirm").close()
    game.banner.queue.clear();game.banner._finish();game.toast_queue.clear()
    sim.campaign.focus_hint=-1
    notices.clear();milestones.clear();heals.clear()
    AudioService.reset_history()
func run() -> void:
    check(BootContext.first_run_complete,"Runs with --first-run-complete (fresh profiles start with every menu revealed)")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false)
    SettingsState.mute_all_sfx()
    sim.notice.connect(func(kind: String,id: String)->void:notices.append([kind,id]))
    sim.milestone.connect(func(kind: String,id: String)->void:milestones.append([kind,id]))
    sim.feedback.connect(func(id: String,amount: float,healing: bool)->void:if healing:heals.append([id,amount,float(sim.state.clock)]))
    fresh()
    await frames(4)
    await economy_checks()
    await collect_checks()
    await migration_checks()
    await boss_checks()
    await overhead_checks()
    await objective_checks()
    await tracker_checks()
    await follow_text_checks()
    await prestige_keep_checks()
    await potion_checks()
    await drop_checks()
    await mastery_checks()
    await robot_checks()
    await skill_text_checks()
    await confirm_checks()
    await audio_checks()
    await guide_checks()
    await settings_checks()
    print("CHANGE_16_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

# ---------------------------------------------------------------- helpers
func group(id: String) -> int:return sim.campaign.group_id(id)
func actor_of(id: String) -> Dictionary:
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id==id and not sim.is_helper(e):return e
    return {}
func stage(n: int) -> void:
    sim.state.stage=n;sim.state.unlocked_stage=maxi(int(sim.state.unlocked_stage),n);sim._reset_world() # fixture
func map_node(path: String) -> Control:return game.get_node("Safe/Layout/Map/"+path)
func labels_text(root: Node) -> String:
    return " | ".join(root.find_children("*","Label",true,false).map(func(l):return l.text))
func buttons(root: Node) -> Array:return root.find_children("*","Button",true,false)
func button_with(root: Node,text: String) -> Button:
    for b in buttons(root):
        if str(b.text).begins_with(text):return b
    return null
func guide_button(key: String) -> Button:
    for root in [game.rows,game.actions]:
        for b in buttons(root):
            if b.get_meta("guide","")==key:return b
    return null
func first_normal(st: int) -> int:
    for g in sim.catalog.stages[st-1].groups:
        if not sim.catalog.groups[g].boss:return int(g)
    return -1
func first_boss(st: int) -> int:
    for g in sim.catalog.stages[st-1].groups:
        if sim.catalog.groups[g].boss:return int(g)
    return -1
func lum(c: Color) -> float:
    var f:=func(v: float)->float:return v/12.92 if v<=.03928 else pow((v+.055)/1.055,2.4)
    return .2126*f.call(c.r)+.7152*f.call(c.g)+.0722*f.call(c.b)
func contrast(a: Color,b: Color) -> float:
    var la:=lum(a);var lb:=lum(b)
    return (maxf(la,lb)+.05)/(minf(la,lb)+.05)
const SNOW:=Color(.93,.95,.98)
func do_prestige() -> bool:
    var g: int=sim.campaign.prestige_unlock_group()
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman") # fixture: found
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    return sim.campaign.begin_prestige() and sim.prestige(sim.campaign.offered_cards()[0])
func refresh_hud() -> void:
    game._refresh_reveal();game._refresh_follow_tracker();game._refresh_mission_tracker();game._layout_trackers()
    game._refresh_explored();game._refresh_mastery_chip();game._refresh_gate();game._refresh_objective()

# ---------------------------------------------------------------- 1. economy
func economy_checks() -> void:
    print("-- economy")
    fresh()
    var incomes: Array=[]
    var ok:=true
    for g in range(sim.catalog.groups.size()):
        var d: Dictionary=sim.catalog.groups[g]
        if not near(float(d.coins),pow(1.5,int(d.stage)-1)*(8.0 if d.boss else 1.0)):ok=false
    for st in range(1,9):incomes.append(sim.coin_reward(first_normal(st)))
    check(ok and near(incomes[0],1.0) and near(incomes[7],pow(1.5,7)),"Base Coin reward ×1.5 per map, compounded (Winter I %s, Spring II %s); bosses 8×" % [incomes[0],incomes[7]])
    var steps_ok:=true
    for st in range(2,9):steps_ok=steps_ok and near(incomes[st-1]/incomes[st-2],1.5)
    check(steps_ok,"Each map pays exactly 1.5× the previous one: %s" % str(incomes.map(func(v):return snappedf(v,.001))))
    var bosses_ok:=true
    for st in range(1,9):bosses_ok=bosses_ok and near(sim.coin_reward(first_boss(st)),8.0*incomes[st-1])
    check(bosses_ok,"Every map's boss pays 8× its normal enemies")
    var g3:=first_normal(3)
    sim.state.upgrades["coin_amount:%d" % g3]=3 # fixture
    check(near(sim.coin_reward(g3),incomes[2]*2.5),"Coin Amount still adds +50% of base per level on the new base (Summer I, level 3: ×2.5)")
    sim.state.owned_cards.append("offering_c1");sim.touch() # fixture: +25% coins card
    check(near(sim.coin_reward(g3),incomes[2]*2.5*1.25),"External coin bonuses still multiply the new base (Coin Wisdom +25%)")
    fresh()
    # Every category of Coin purchase tied to an enemy type, a map or a camp: 1.55 per map, levels kept.
    var type_ids: Array=[];var stage_ids: Array=[]
    for id in sim.catalog.upgrades:
        var u: Dictionary=sim.catalog.upgrades[id]
        if str(u.currency)!="coins" or int(u.cap)==0:continue
        if str(u.scope) in ["type","normal_type"]:type_ids.append(id)
        elif str(u.scope)=="stage" and not u.get("sequence",false):stage_ids.append(id)
    var all_ok:=true;var bad: Array=[]
    for st in range(1,9):
        var factor:=pow(1.55,st-1)
        for g in [first_normal(st),first_boss(st)]:
            for id in type_ids:
                for level in [0,2]:
                    var u: Dictionary=sim.catalog.upgrades[id]
                    if level>=int(u.cap):continue
                    sim.state.upgrades["%s:%d" % [id,g]]=level # fixture: owned levels
                    # Change 56: levels 1-5 of Coin Amount, Enemy XP and Loot Chance cost x0.25 ("cheap first five").
                    var cheap: float=.25 if id in ["coin_amount","group_xp","loot"] and level<5 else 1.0
                    var want:=maxi(1,ceili(float(u.base)*pow(float(u.growth),level)*cheap*factor))
                    if sim.upgrade_cost(id,g)!=want:all_ok=false;bad.append("%s s%d L%d %d!=%d" % [id,st,level,sim.upgrade_cost(id,g),want])
                    sim.state.upgrades.erase("%s:%d" % [id,g])
        for id in stage_ids:
            var u: Dictionary=sim.catalog.upgrades[id]
            if sim.upgrade_cost(id,st)!=maxi(1,ceili(float(u.base)*factor)):all_ok=false;bad.append(id+" s%d" % st)
        for camp in range(1,sim.catalog.stages[st-1].spawns.size()):
            var u: Dictionary=sim.catalog.upgrades.camp_radius
            if sim.upgrade_cost("camp_radius",st*10+camp)!=maxi(1,ceili(float(u.base)*factor)):all_ok=false;bad.append("camp_radius s%d" % st)
    check(all_ok and type_ids.size()>=8,"Enemy upgrades (%s), map upgrades (%s) and camp radius cost base × growth^level × 1.55^(map−1) on all 8 maps %s" % [", ".join(type_ids),", ".join(stage_ids),str(bad.slice(0,4))])
    var camps_ok:=true
    for st in range(1,9):
        stage(st)
        for camp in range(1,sim.catalog.stages[st-1].spawns.size()):
            if sim.campaign.camp_price(camp)!=ceili([0,50,150][camp]*pow(1.55,st-1)):camps_ok=false
    stage(1)
    check(camps_ok,"Camp unlock prices: 50 / 150 × 1.55^(map−1) (Winter I 50, Spring II %d)" % ceili(50*pow(1.55,7)))
    var detail_ok:=true
    for st in range(1,9):
        if sim.upgrade_cost("map_detail",st)!=ceili(maxf(60.0,40.0*pow(1.55,st-1))):detail_ok=false
    check(detail_ok,"Map Details floor: 40 × 1.55^(map−1) (its per-purchase sequence unchanged)")
    var global_ok: bool=sim.upgrade_cost("movement")==40 and sim.upgrade_cost("respawn")==30 and sim.upgrade_cost("use_speed")==100 and sim.upgrade_cost("offline_coins")==100
    check(global_ok,"Global prices: Movement 40, Respawn 30, Use speed 100 Gems, Offline coins 100")
    var gem_ok:=true
    for st in range(1,9):
        var g:=first_normal(st)
        if sim.upgrade_cost("merge_gear",g)!=ceili(30*(1+.25*(st-1))) or sim.upgrade_cost("auto_evolve",g)!=2000 or sim.upgrade_cost("spawn_amount",g)!=ceili(75*(1+.25*(st-1))):gem_ok=false
    check(gem_ok,"Gem upgrades unchanged: ×(1 + 0.25 × (map−1)), Auto Evolution flat 2,000, Spawn Amount 75 base")
    var rising:=true
    # Compared at level 6, past Change 56's discounted first five levels (the per-map growth rule itself).
    for st in range(1,9):sim.state.upgrades["loot:%d" % first_normal(st)]=5
    for st in range(2,9):
        var prev: float=float(sim.upgrade_cost("loot",first_normal(st-1)))/incomes[st-2]
        var now: float=float(sim.upgrade_cost("loot",first_normal(st)))/incomes[st-1]
        if now<=prev:rising=false
    for st in range(1,9):sim.state.upgrades.erase("loot:%d" % first_normal(st))
    check(rising,"Every new map costs slightly more relative to its base income (Loot Chance price ÷ income rises map by map)")

# ---------------------------------------------------------------- 2. Gem Auto-Collect and Collect Batch
func collect_checks() -> void:
    print("-- Gem Auto-Collect and Collect Batch")
    fresh()
    var g:=group("unit-blue-cap")
    sim.campaign.discover_spot(g,2)
    check(sim.catalog.upgrades.collect.currency=="gems" and sim.catalog.upgrades.collect_batch.currency=="gems","Auto-Collect and Collect Batch are bought with Gems")
    check(sim.upgrade_cost("collect",g)==20,"Auto-Collect costs 20 Gems on Winter I")
    sim.state.gems=2000;sim.state.coins=0
    check(sim.buy_upgrade("collect",g) and int(sim.state.gems)==1980 and int(sim.state.coins)==0,"Buying Auto-Collect spends 20 Gems and no Coins")
    var prices: Array=[]
    for i in range(3):
        prices.append(sim.upgrade_cost("collect_batch",g))
        sim.buy_upgrade("collect_batch",g)
    check(prices==[50,150,450] and int(sim.state.gems)==1980-650,"Collect Batch: 50, 150, 450 Gems (×3 per level as before) %s" % str(prices))
    check(int(sim.group_upgrade_value("collect_batch",g))==4 and int(sim.catalog.upgrades.collect_batch.cap)==5,"Batch grows 1 → 4 after three levels; the 5-level limit (batch 6) is unchanged")
    var g2:=first_normal(2)
    check(sim.upgrade_cost("collect",g2)==25 and sim.upgrade_cost("collect_batch",g2)==63,"Winter II: 25 and 63 Gems (Gem scaling 1 + 0.25 per map)")
    check(sim.upgrade_kept("collect") and sim.upgrade_kept("collect_batch"),"Both are Gem upgrades, so Prestige keeps them")
    check(do_prestige() and sim.level("collect",g)==1 and sim.level("collect_batch",g)==3,"After a Prestige: Auto-Collect 1, Collect Batch 3")
    # Levels bought with Coins before Change 16 load and keep working.
    fresh()
    sim.state.upgrades["collect:0"]=1;sim.state.upgrades["collect_batch:0"]=2 # fixture: an older save's Coin levels
    var data=JSON.parse_string(JSON.stringify(sim.snapshot()))
    sim.restore(data)
    check(sim.level("collect",0)==1 and sim.level("collect_batch",0)==2 and int(sim.group_upgrade_value("collect_batch",0))==3,"Levels bought with Coins earlier load unchanged (batch 3)")
    check(do_prestige() and sim.level("collect",0)==1 and sim.level("collect_batch",0)==2,"…and are kept by the next Prestige")

# ---------------------------------------------------------------- 3. save migration
func migration_checks() -> void:
    print("-- save compatibility")
    fresh()
    var snow:=group("boss-snowman");var robot:=group("boss-cyan-robot")
    sim.state.group_kills[snow]=3;sim.state.group_kills[robot]=1 # fixture: an existing schema-8 profile
    sim.state.upgrades["gear_slots"]=4;sim.state.gear.append_array(["","","",""]);sim.state.upgrades["focus:0"]=1
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    snap.erase("bosses_found");snap.erase("follow_mission")
    # Change 50: an existing schema-8 profile (as released) migrates to schema 9 instead of resetting.
    check(int(snap.schema)==sim.SCHEMA,"Current save schema %d" % int(snap.schema))
    snap.schema=8;snap.erase("merge_memory");snap.erase("migrations")
    SaveService.last_load_result="" # fixture: judge this restore, not the boot-time load of the probe profile
    sim.restore(snap)
    check(SaveService.last_load_result not in ["development_reset","invalid_profile_reset"] and sim.state.bosses_found.has("boss-snowman") and sim.state.bosses_found.has("boss-cyan-robot") and sim.state.bosses_found.size()==2,"A save without the new records loads: defeated bosses count as found %s" % str(sim.state.bosses_found))
    check(str(sim.state.follow_mission)=="" and sim.campaign.prestige_unlocked(),"…no followed mission, and its Prestige unlock is kept")
    check(sim.level("gear_slots")==4 and sim.state.gear.size()==7 and sim.level("focus",0)==1,"…and every permanent upgrade is kept")
    check(SaveService.save_now(),"The migrated profile saves")
    SaveService.load_and_apply()
    check(sim.state.bosses_found.size()==2 and sim.level("gear_slots")==4,"…and reloads from disk unchanged")
    var bad: Dictionary=sim.snapshot().duplicate(true)
    bad.bosses_found=["unit-blue-cap"]
    check(not sim.campaign.valid_snapshot(sim.campaign.normalize_snapshot(bad)),"Validation refuses a normal enemy in bosses_found")

# ---------------------------------------------------------------- 4. boss discovery and the Prestige unlock
func boss_checks() -> void:
    print("-- boss discovery and Prestige")
    fresh()
    sim.state.onboarding.reveal=["missions","enemy","world","upgrades","objective"] # fixture: before the Snowman
    var snow:=actor_of("boss-snowman")
    var at:=Vector2(snow.x,snow.y)
    check(not sim.campaign.prestige_unlocked() and sim.state.bosses_found.is_empty(),"Fresh profile: no boss found, Prestige locked")
    sim.state.player.x=at.x-240;sim.state.player.y=at.y+40;sim.campaign.reveal()
    check(sim.state.bosses_found.is_empty(),"240 units away (out of sight): not found")
    SettingsState.mute_special=false;SettingsState.sfx_volume=1.0;AudioService.reset_history()
    sim.state.player.x=at.x-80;sim.state.player.y=at.y+10;sim.campaign.reveal()
    var played: String=AudioService.flush()
    check(sim.state.bosses_found==["boss-snowman"],"Approaching within sight finds the Snowman")
    check(notices.count(["boss_found","boss-snowman"])==1 and played=="boss_found","One notice and the boss cue (%s, the mission-ready sound)" % played)
    var cue_stream=AudioService._cues.get("boss_found",{}).get("stream")
    check(cue_stream!=null and cue_stream==AudioService._cues.mission_ready.stream,"The boss cue uses the mission_ready sound")
    var kinds: Array=milestones.map(func(m):return m[0])
    check(kinds.has("boss_found") and kinds.has("prestige_unlocked") and kinds.find("boss_found")<kinds.find("prestige_unlocked"),"Milestones: the warning first, then Prestige unlocked %s" % str(kinds))
    var first: Dictionary=game.banner.current if not game.banner.current.is_empty() else (game.banner.queue[0] if not game.banner.queue.is_empty() else {})
    check(str(first.get("title",""))=="!WARNING BOSS FOUND!" and bool(first.get("warning",false)) and str(first.get("subtitle","")).contains("Snowman"),"Banner: \"%s\" in red, naming the Snowman" % str(first.get("title","")))
    check(sim.campaign.prestige_unlocked() and sim.campaign.onboarding.revealed("prestige") and sim.campaign.prestige_gate_reason()=="","Finding the Snowman opens Prestige (button and reset gate)")
    check(int(sim.state.group_kills[group("boss-snowman")])==0 and float(snow.hp)>0 and int(sim.state.unlocked_stage)==1 and int(sim.state.run_kills.get("boss-snowman",0))==0,"…without defeating it or opening Winter II")
    notices.clear();milestones.clear()
    for i in range(5):sim.campaign.reveal()
    sim.state.player.x=at.x+300;sim.campaign.reveal();sim.state.player.x=at.x-60;sim.campaign.reveal()
    check(not notices.any(func(n):return n[0]=="boss_found") and not milestones.any(func(m):return m[0]=="boss_found"),"Approaching again never repeats the warning")
    # A dead boss is not found.
    fresh()
    snow=actor_of("boss-snowman");snow.hp=0
    sim.state.player.x=float(snow.x)-60;sim.state.player.y=float(snow.y);sim.campaign.reveal()
    check(sim.state.bosses_found.is_empty(),"A defeated (respawning) boss is not found by walking past its spot")
    fresh()
    sim.state.bosses_found.append("boss-snowman") # fixture
    check(do_prestige() and sim.state.bosses_found==["boss-snowman"] and sim.campaign.prestige_unlocked(),"Prestige keeps the bosses found and the unlock")
    game._open("prestige");await frames(2)
    check(labels_text(game.rows).contains("✓ Find the Winter I Snowman"),"The Prestige checklist reads \"Find the Winter I Snowman\"")
    game._close()
    SaveService.hard_reset();sim.state.tutorial.mode="none";sim.suspended=false
    check(sim.state.bosses_found.is_empty() and not sim.campaign.prestige_unlocked(),"Hard Reset clears the found bosses")
    SettingsState.mute_all_sfx()

# ---------------------------------------------------------------- 4b. names and skill icons
func rect_of_name(v: LootActorView) -> Rect2:
    var label: Label=v.get_node("Name")
    return Rect2(label.position,label.size*label.scale)
func rect_of_bar(v: LootActorView) -> Rect2:
    var bar: Control=v.get_node("HP")
    return Rect2(bar.position,bar.size)
func rect_of_icons(v: LootActorView) -> Rect2:
    var r:=Rect2()
    for s in v.get_node("Skills").get_children():
        var sprite: Sprite2D=s
        var size: Vector2=sprite.texture.get_size()*sprite.scale
        var box:=Rect2(sprite.position-size*.5,size)
        r=box if r.size==Vector2.ZERO else r.merge(box)
    return r
func overhead_checks() -> void:
    print("-- boss names and skill icons")
    fresh()
    stage(2)
    var robot:=actor_of("boss-cyan-robot")
    sim.campaign.discover_spot(group("boss-cyan-robot"),2)
    sim.campaign.reveal_circle(Vector2(robot.x,robot.y),120.0)
    robot.hp=float(sim.enemy_definition(int(robot.group),2).hp)*.5
    await frames(1) # the stage switch recentres the camera on its first frame
    game.world.following_player=false;game.world.camera_position=sim.position_of(robot) # Change 24 fixture: views animate only on screen
    await frames(3)
    var v: LootActorView=game.world.views[str(robot.id)]
    var label: Label=v.get_node("Name")
    check(label.visible and label.text=="Cyan Robot","The Cyan Robot's name shows above it")
    var red: Color=label.get_theme_color("font_color")
    check(red.r>.9 and red.g<.4 and red.b<.4,"…in threatening red (%s)" % red)
    check(contrast(red,label.get_theme_color("font_outline_color"))>=4.5 and label.get_theme_constant("outline_size")>=8,"…with a dark outline: %.1f:1 against it, readable on snow and grass" % contrast(red,label.get_theme_color("font_outline_color")))
    var icons:=v.get_node("Skills")
    check(icons.visible and icons.get_child_count()==1 and (icons.get_child(0) as Sprite2D).texture==sim.catalog.icon("skill_heal"),"One skill icon: Heal")
    var n:=rect_of_name(v);var b:=rect_of_bar(v);var i:=rect_of_icons(v);var gate: Sprite2D=v.get_node("Gate")
    var g:=Rect2(gate.position-Vector2(6,6),Vector2(12,12))
    check(gate.visible,"The World banner of the required boss still shows")
    check(not n.intersects(b) and not i.intersects(n) and not i.intersects(b) and not g.intersects(i) and not g.intersects(n),"Name, skill icon, banner and HP bar never overlap")
    check(n.end.y<=b.position.y+.01 and i.end.y<=n.position.y+.01 and g.end.y<=i.position.y+.01,"Stacked upward: HP bar, name, skill icon, banner")
    check((v.get_node("Speech") as Control).position.y<g.position.y,"The speech line sits above the stack")
    # A normal enemy with a skill: icon, no name.
    var elite:={}
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id=="unit-space-helmet" and int(e.get("variant",2))==3:elite=e
    sim.campaign.reveal_circle(Vector2(elite.x,elite.y),60.0)
    game.world.following_player=false;game.world.camera_position=sim.position_of(elite) # Change 24 fixture: views animate only on screen
    await frames(2)
    var ev: LootActorView=game.world.views[str(elite.id)]
    check(not ev.get_node("Name").visible and ev.get_node("Skills").visible and ev.get_node("Skills").get_child_count()==1,"A Space Helmet elite shows its skill icon and no name")
    var plain:={}
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id=="unit-space-helmet" and int(e.get("variant",2))==2:plain=e
    sim.campaign.reveal_circle(Vector2(plain.x,plain.y),60.0)
    game.world.following_player=false;game.world.camera_position=sim.position_of(plain) # Change 24 fixture: views animate only on screen
    await frames(2)
    var pv: LootActorView=game.world.views[str(plain.id)]
    check(not pv.get_node("Skills").visible and not pv.get_node("Name").visible,"Enemies without skills show neither")
    robot.hp=0;sim._kill(robot)
    game.world.following_player=false;game.world.camera_position=sim.position_of(robot) # Change 24 fixture: views animate only on screen
    await frames(2)
    check(not label.visible and not icons.visible,"A defeated boss hides its name and icons")
    # Three skills (the final boss) stay in one row centred over the head.
    stage(8)
    var alien:=actor_of("boss-green-alien")
    sim.campaign.reveal_circle(Vector2(alien.x,alien.y),140.0)
    await frames(1) # the stage switch recentres the camera on its first frame
    game.world.following_player=false;game.world.camera_position=sim.position_of(alien) # Change 24 fixture: views animate only on screen
    await frames(3)
    var av: LootActorView=game.world.views[str(alien.id)]
    var row: Rect2=rect_of_icons(av)
    check(av.get_node("Skills").get_child_count()==3 and absf(row.get_center().x)<.5 and not row.intersects(rect_of_name(av)),"The final boss: three skill icons in one centred row, clear of its name")
    game.world.follow_player()

# ---------------------------------------------------------------- 5. persistent Winter I objective
func objective_checks() -> void:
    print("-- Winter I objective")
    fresh()
    refresh_hud();await frames(2)
    var node:=map_node("Objective")
    var text: Label=node.get_node("Text")
    check(not node.visible and text.text=="Farm until you can beat the boss.","Winter I shows \"%s\"" % text.text)
    check(node.mouse_filter==Control.MOUSE_FILTER_IGNORE and text.mouse_filter==Control.MOUSE_FILTER_IGNORE,"It never takes touches")
    var gate:=map_node("Gate")
    check(not node.visible,"It sits under the Next Stage chip, on the same right edge")
    check(text.get_theme_font_size("font_size")>=15 and contrast(text.get_theme_color("font_color"),Color(.04,.06,.09))>=7.0,"Readable: %d px on the dark chip, %.1f:1" % [text.get_theme_font_size("font_size"),contrast(text.get_theme_color("font_color"),Color(.04,.06,.09))])
    sim.state.bosses_found.append("boss-snowman") # fixture: found but not defeated
    refresh_hud()
    check(node.visible,"Finding the Snowman keeps it (it stays until the Snowman is defeated)")
    sim.state.bosses_found.clear()
    refresh_hud();await frames(2)
    check(not node.visible,"No objective before boss discovery")
    sim.state.onboarding.reveal=sim.campaign.onboarding.FEATURES.duplicate()
    sim.state.group_kills[group("boss-snowman")]=1;sim.state.run_kills["boss-snowman"]=1 # fixture: defeated
    refresh_hud()
    check(not node.visible,"Defeating the Snowman removes it")
    fresh();stage(2);refresh_hud()
    check(not node.visible,"Other maps never show it")

# ---------------------------------------------------------------- 6. missions and Prestige tracking
func tracker_checks() -> void:
    print("-- mission and Prestige trackers")
    fresh()
    var i:=-1
    for k in range(sim.state.missions.size()):
        if str(sim.state.missions[k].kind)=="kill":i=k
    check(i>=0 and sim.campaign.toggle_follow_mission("daily",i) and sim.campaign.mission_followed("daily",i),"Follow a regular mission")
    sim.state.opportunities["expedition_o1"]={"ready":false,"baseline":{},"step":0,"count":12} # fixture: discovered
    check(sim.campaign.toggle_follow("expedition_o1"),"Follow a Prestige opportunity as well")
    refresh_hud();await frames(3);refresh_hud();await frames(1)
    var mission:=map_node("MissionTracker");var follow:=map_node("FollowTracker")
    check(mission.visible and follow.visible,"Both trackers show at once")
    var map_rect: Rect2=map_node("").get_rect() if false else Rect2(Vector2.ZERO,game.get_node("Safe/Layout/Map").size)
    var mr:=mission.get_rect();var fr:=follow.get_rect()
    check(map_rect.encloses(mr) and map_rect.encloses(fr),"Both inside the map")
    check(absf(fr.end.y-game.stick.get_rect().position.y+12)<1 and fr.position.y>mr.position.y,"Both stacked directly above joystick")
    check(not mr.intersects(fr) and mr.end.y<=fr.position.y,"Stacked: mission above Prestige, no overlap")
    var stick: Rect2=game.stick.get_rect()
    check(not mr.intersects(stick) and not fr.intersects(stick),"Clear of the joystick")
    check(not mr.intersects(map_node("Gate").get_rect()) and not mr.intersects(map_node("MiniMap").get_rect()) and not mr.intersects(map_node("Objective").get_rect()),"Clear of the map cluster")
    var m: Dictionary=sim.state.missions[i]
    var step: String=mission.get_node("Row/Text/Step").text
    var name_: String=sim.catalog.groups[group(str(m.target))].name
    check(step.contains(name_) and step.contains(sim.catalog.stages[int(sim.catalog.groups[group(str(m.target))].stage)-1].name) and step.contains("/"),"The mission tracker says what to do, where and how far: \"%s\"" % step)
    check(mission.get_node("Row/Icon").texture==game.icon_cache.get(sim.catalog.groups[group(str(m.target))].body),"…with the enemy's portrait")
    check(mission.get_theme_font_size("font_size")>=0 and mission.get_node("Row/Text/Step").get_theme_font_size("font_size")>=16,"Readable text (16 px)")
    var press:=InputEventMouseButton.new();press.pressed=true;press.button_index=MOUSE_BUTTON_LEFT
    mission.gui_input.emit(press)
    check(game.sheet.visible and game.panel=="missions","Tapping the mission tracker opens Missions")
    var pin:=button_with(game.rows,"Unfollow")
    check(pin!=null and button_with(game.rows,"Follow")!=null,"Mission cards carry Follow / Unfollow")
    game._close()
    follow.gui_input.emit(press)
    check(game.panel=="prestige","Tapping the Prestige tracker opens Prestige")
    game._close()
    sim.campaign.toggle_follow_mission("daily",i);refresh_hud()
    check(not mission.visible and follow.visible,"Unfollowing the mission leaves the Prestige tracker")
    sim.campaign.toggle_follow_mission("daily",i);sim.campaign.toggle_follow("expedition_o1");refresh_hud();await frames(1);refresh_hud()
    check(mission.visible and not follow.visible and mission.get_rect().position.y>=map_node("EnemyUpgrades").get_rect().end.y,"Unfollowing the opportunity leaves the mission tracker, below contextual Upgrades")
    m.progress=m.goal
    refresh_hud()
    check(mission.get_node("Row/Text/Step").text=="Ready! Claim it in Missions","A complete mission says to claim it")
    check(sim.campaign.claim_mission(i) and str(sim.state.follow_mission)=="","Claiming it ends the follow")
    refresh_hud()
    check(not mission.visible,"…and the tracker goes")
    # A main objective can be followed too, with real progress.
    sim.campaign.toggle_follow_mission("main",0)
    sim.state.counters["kill"]=3.0 # fixture
    check(sim.campaign.mission_follow_summary()=="Defeat enemies: 3/5","Main objective 1 reads \"%s\"" % sim.campaign.mission_follow_summary())
    sim.state.main_ready["0"]=true
    check(sim.campaign.claim_main(0) and str(sim.state.follow_mission)=="","Claiming a followed objective ends the follow")
    # Only one mission at a time.
    sim.campaign.toggle_follow_mission("main",1);sim.campaign.toggle_follow_mission("main",2)
    check(sim.campaign.mission_followed("main",2) and not sim.campaign.mission_followed("main",1),"Following another mission replaces the first (one at a time)")
    var key: String=sim.state.follow_mission
    var data=JSON.parse_string(JSON.stringify(sim.snapshot()))
    sim.restore(data)
    check(str(sim.state.follow_mission)==key,"The followed mission is saved")
    check(do_prestige() and str(sim.state.follow_mission)=="","Prestige clears the followed mission (missions restart)")

# ---------------------------------------------------------------- 6b. all 33 opportunities explained
func follow_text_checks() -> void:
    print("-- Prestige follower text (33 opportunities)")
    fresh()
    for op in sim.catalog.campaign.opportunities:sim.state.opportunities[op.id]={"ready":false,"baseline":{},"step":0,"count":0} # fixture: discovered
    var progress:=RegEx.create_from_string("\\d+(\\.\\d)?%?\\s*/\\s*\\^?\\d")
    var raw:=RegEx.create_from_string("unit-|boss-|_o\\d|_outfit|GOAL_|FOLLOW_")
    var bad: Array=[]
    for op in sim.catalog.campaign.opportunities:
        var text: String=sim.campaign.follow_summary(op.id)
        var path: String=op.path
        var ok: bool=text!="" and progress.search(text)!=null and raw.search(text)==null
        if path in ["hunter","challenge","expedition","trophy","collection"]:
            # names the enemy and the map it lives on
            ok=ok and text.contains("(") and text.contains(")")
        if path in ["expedition","specialist","collection","trophy","regional"]:ok=ok and (text.contains("\nNext: ") or text.contains("\nThen: "))
        if not ok:bad.append("%s: %s" % [op.id,text])
    check(bad.is_empty(),"Every opportunity says what to do with current/required progress, names the enemy and map where one applies and the next requirement %s" % str(bad))
    var col: String=sim.campaign.follow_summary("collection_o1")
    var item: String=sim.campaign.contract_outfit("blue-cap")
    check(col.contains(sim.catalog.display_name(item)) and col.contains("Blue Cap (Winter I)") and col.contains("0/21") and col.contains("Next: "+sim.catalog.display_name(sim.campaign.contract_outfit("red-scarf"))),"Winter collection names the exact item: \"%s\"" % col.replace("\n"," / "))
    check(sim.campaign.follow_focus("collection_o1")=={"item":item},"…and the tracker shows that item's icon")
    sim.state.follow="collection_o1";game._refresh_follow_tracker()
    check(map_node("FollowTracker").get_node("Row/Icon").texture==game.icon_cache.get(item),"Tracker icon = the Blue Cap Outfit")
    # Change 41: 21 of an outfit completes its step (20 handed in, one kept).
    sim.add_item(item,21,false,false)
    sim.state.online_items[item]=21.0;sim.state.opportunities.collection_o1["item_"+item]=21.0 # fixture: 21 found
    col=sim.campaign.follow_summary("collection_o1")
    check(col.begins_with("Step 2/3") and col.contains(sim.catalog.display_name(sim.campaign.contract_outfit("red-scarf"))),"After 21 Blue Caps the next outfit is named: \"%s\"" % col.replace("\n"," / "))
    var exp: String=sim.campaign.follow_summary("expedition_o1")
    check(exp.begins_with("Step 1/3 · Defeat Blue Cap (Winter I): 0/100") and exp.contains("Next: Defeat Red Scarf (Winter I) ×100"),"Winter route: \"%s\"" % exp.replace("\n"," / "))
    check(sim.campaign.follow_summary("hunter_o1")=="Defeat Snowman (Winter I): 0/1","First bounty: \"%s\"" % sim.campaign.follow_summary("hunter_o1"))
    var spec: String=sim.campaign.follow_summary("specialist_o2")
    check(spec.begins_with("Step 1/4 · Defeat any enemies: 0/250") and spec.contains("Next: Defeat any bosses ×3"),"Long chain: \"%s\"" % spec.replace("\n"," / "))
    var tro: String=sim.campaign.follow_summary("trophy_o1")
    check(tro.begins_with("Defeat Snowman (Winter I) for its trophy · trophies 0/2") and tro.contains("Next: Cyan Robot (Winter II)"),"Winter trophies: \"%s\"" % tro.replace("\n"," / "))
    var reg: String=sim.campaign.follow_summary("regional_o1")
    check(reg.begins_with("Explore Winter I: ") and reg.get_slice("\n",0).ends_with("%/90%") and reg.contains("\nThen: "),"Winter mastery: \"%s\"" % reg.replace("\n"," / "))
    check(sim.campaign.follow_summary("offline_o2").begins_with("Longest single absence: 0.0/24 h"),"Long rest: \"%s\"" % sim.campaign.follow_summary("offline_o2"))
    var descriptions_ok:=true
    for op in sim.catalog.campaign.opportunities:
        if str(op.description).begins_with("CONTENT_") or str(op.description).length()<20:descriptions_ok=false
    check(descriptions_ok and str(sim.catalog.campaign.opportunities[0].description).contains("Winter I"),"Descriptions are written out and name their maps (\"%s\")" % sim.catalog.campaign.opportunities[0].description)
    game._open("prestige");await frames(2)
    check(labels_text(game.rows).contains("Step 1/3 · Defeat Blue Cap (Winter I)"),"The Prestige panel shows the same actionable line")
    game._close()

# ---------------------------------------------------------------- 7. what Prestige keeps
func prestige_keep_checks() -> void:
    print("-- Prestige keeps Gems and exploration")
    fresh()
    sim.state.gems=345;sim.state.coins=999
    sim.campaign.reveal_circle(Vector2(480,700),260.0)
    sim.state.explored.erase("2");sim.campaign.explore_cells(2,[Vector2i(10,10),Vector2i(11,10)]) # fixture: Winter II cells
    sim.state.camps_known["1"]=[1];sim.state.camps["1"]=[0,1];sim.state.spawns=sim.state.camps["1"]
    sim.state.upgrades["map_detail:1"]=2;sim.state.upgrades["reveal_radius:1"]=1
    sim.campaign.identify_sites()
    var explored: Dictionary=sim.state.explored.duplicate(true)
    var spots: Dictionary=sim.state.discovered_spots.duplicate(true)
    var pct: int=sim.campaign.explored_percent(1)
    check(do_prestige(),"Prestige")
    check(int(sim.state.gems)==345,"Gems kept: %s" % str(sim.state.gems))
    check(sim.campaign.explored_count(1)>=explored["1"].count(1) and sim.campaign.explored_count(2)==2 and sim.campaign.explored_percent(1)>=pct,"Explored cells kept on both maps (Winter I %d%%)" % sim.campaign.explored_percent(1))
    check(sim.state.camps_known.get("1",[]).has(1) and sim.state.discovered_spots.size()>=spots.size(),"Sighted camps and found spots kept")
    # Change 50 (approved): Coins and every upgrade (map upgrades included) are kept; owned camps and the
    # run's online Gem credit still reset.
    check(int(sim.state.coins)>=999 and sim.state.camps.get("1",[])==[0] and sim.level("map_detail",1)==2 and sim.level("reveal_radius",1)==1 and float(sim.state.online_gems)==0.0,"Coins and map upgrades kept; owned camps and the run's online Gem credit reset")
    check(sim.state.prestiges==1 and sim.state.owned_cards.size()==1 and int(sim.state.unlocked_stage)==1,"Other Prestige rules unchanged (card granted, back to Winter I)")

# ---------------------------------------------------------------- 8. Health Potion
func potion_checks() -> void:
    print("-- Health Potion")
    fresh()
    sim.add_item("potion",1)
    check(sim.supply_mastery("potion")==0 and near(sim.supply_value("potion"),.1),"^0 heals 10% of max HP")
    sim.state.supply_uses["potion"]=50*int(sim.catalog.progression.change17.supply_uses_per_level) # fixture: ^50
    check(near(sim.supply_value("potion"),.15),"^50 heals 15%")
    sim.state.supply_uses["potion"]=500 # fixture: ^100
    check(sim.supply_mastery("potion")==100 and near(sim.supply_value("potion"),.2),"^100 heals 20% before external bonuses")
    var maxhp: float=sim.stats().hp
    sim.state.player.hp=maxhp*.1
    var before: float=sim.state.player.hp
    sim.use_item("potion")
    check(near(float(sim.state.player.hp)-before,maxhp*.2),"Using it at ^100 restores %.1f of %.0f HP (20%%)" % [float(sim.state.player.hp)-before,maxhp])
    sim.state.owned_cards.append("arsenal_c1");sim.touch() # fixture: +20% max HP card
    sim.add_item("potion",1);sim.state.use_cd=0.0
    var bigger: float=sim.stats().hp
    sim.state.player.hp=bigger*.1;before=sim.state.player.hp
    sim.use_item("potion")
    check(near(bigger,maxhp*1.2) and near(float(sim.state.player.hp)-before,bigger*.2) and float(sim.state.player.hp)-before>maxhp*.2,"External max-HP bonuses still raise what it restores (%.1f HP, above 20%% of the base %.0f): no healing cap" % [float(sim.state.player.hp)-before,maxhp])
    check(near(sim.supply_cooldown("potion"),10.0),"Mastered cooldown unchanged (10 s)")

# ---------------------------------------------------------------- 10. Drop All
## Online credit entries that hold credit (spending any copy leaves a harmless 0 entry behind).
func nonzero(d: Dictionary) -> Dictionary:
    var out: Dictionary={}
    for key in d:
        if float(d[key])!=0.0:out[key]=d[key]
    return out
func counters_snapshot() -> Dictionary:
    return {"counters":sim.state.counters.duplicate(true),"online":sim.state.online_items.duplicate(true),"ops":sim.state.opportunities.duplicate(true),"missions":sim.state.missions.duplicate(true),"found":sim.state.supply_found.duplicate(true),"history":sim.state.history.size(),"mastery":sim.state.mastery.duplicate(true)}
func drop_checks() -> void:
    print("-- Drop All")
    fresh()
    sim.add_item("wood_sword",6);sim.merge("wood_sword");sim.merge("wood_sword")
    sim.add_item("unit-blue-cap_outfit",3)
    sim.state.opportunities["specialist_o1"]={"ready":false,"baseline":{},"step":1,"count":2} # fixture: on the "find gear" step
    sim.state.opportunities["collection_o1"]={"ready":false,"baseline":{},"step":0,"count":0,"item_unit-blue-cap_outfit":3.0}
    sim.state.online_items["unit-blue-cap_outfit"]=3.0
    sim.state.missions[0]={"kind":"gear","target":"","goal":12.0,"progress":1.0,"coins":10.0,"gems":0.0,"day":Time.get_date_string_from_system(),"claimed":false}
    var used: int=sim.state.gear.count("")
    var slot: int=sim.state.gear.find("wood_sword")
    check(sim.discard("wood_sword"),"Drop All on the Wood Sword stack")
    check(sim.quantity("wood_sword")==0 and sim.state.gear[slot]=="" and sim.state.gear.count("")==used+1,"The whole stack leaves and its slot is free at once")
    check(int(sim.record("wood_sword").merge)==2,"Its merge level stays with the record")
    var pile: Dictionary=sim.state.pickups.back()
    check(pile.item=="wood_sword" and int(pile.qty)==4 and int(pile.group)==-1 and float(pile.ttl)==300.0 and Vector2(pile.x,pile.y).distance_to(sim.position_of(sim.state.player))<30,"One pile of 4 at the player's feet, owned by no enemy type, expiring like loot")
    # Auto-Collect never takes it back.
    for g in range(3):sim.state.upgrades["collect:%d" % g]=1;sim.state.upgrades["collect_range:%d" % g]=4 # fixture
    for k in range(400):sim.campaign.automate(.1)
    check(sim.state.pickups.has(pile) and sim.quantity("wood_sword")==0,"40 s of Auto-Collect beside it: still on the ground")
    await frames(3)
    var node: Node2D=game.world.pickups[int(pile.uid)]
    check(node.get_node("Count").visible and node.get_node("Count").text=="×4","The pile shows ×4")
    var before:=counters_snapshot()
    check(sim.collect(int(pile.uid)) and sim.quantity("wood_sword")==4 and int(sim.record("wood_sword").merge)==2,"Tapping it brings back all 4 at ^2")
    var after:=counters_snapshot()
    check(after.counters==before.counters and after.missions==before.missions and after.ops==before.ops and after.history==before.history,"Picking it up gives no mission, Prestige or counter progress and no recent-find line")
    # Repeated drop and pickup earns nothing; credit leaves and returns exactly.
    sim.add_item("potion",2)
    var start:=counters_snapshot()
    for k in range(10):
        for id in ["wood_sword","unit-blue-cap_outfit","potion"]:
            sim.discard(id)
            sim.collect(int(sim.state.pickups.back().uid))
    var end:=counters_snapshot()
    check(end.counters==start.counters and end.missions==start.missions and end.found==start.found and end.mastery==start.mastery,"10 drop-and-pickup loops: missions, counters, supply mastery and Map Mastery unchanged")
    check(nonzero(end.online)==nonzero(start.online) and end.ops==start.ops and sim.quantity("unit-blue-cap_outfit")==3,"…and the collection credit leaves and returns exactly (3 Blue Cap Outfits, credit 3)")
    sim.discard("unit-blue-cap_outfit")
    check(float(sim.state.online_items.get("unit-blue-cap_outfit",0))==0.0 and float(sim.state.opportunities.collection_o1.get("item_unit-blue-cap_outfit",0))==0.0,"While on the ground its credit is gone (it cannot be handed in)")
    sim.collect(int(sim.state.pickups.back().uid))
    sim.equip("wood_sword")
    check(not sim.discard("wood_sword") and sim.discard_block_reason("wood_sword")=="DROP_EQUIPPED" and sim.quantity("wood_sword")==4,"An equipped item cannot be dropped (unequip it first)")
    get_tree().paused=true
    check(sim.discard_block_reason("potion")=="ACTION_PAUSED","Not while paused")
    get_tree().paused=false
    # A full row: dropping frees the slot a new item needs.
    fresh()
    var ids: Array=["wood_sword","wood_axe","unit-blue-cap_outfit"]
    for id in ids:sim.add_item(id,1)
    check(not sim.can_add("unit-red-scarf_outfit"),"Full equipment row (fixture)")
    sim.discard("wood_axe")
    check(sim.can_add("unit-red-scarf_outfit") and sim.add_item("unit-red-scarf_outfit"),"Dropping one stack makes room for a new item")
    check(not sim.collect(int(sim.state.pickups.back().uid)) and sim.state.pickups.size()==1,"With the row full again the pile waits on the ground (Inventory full)")
    var data=JSON.parse_string(JSON.stringify(sim.snapshot()))
    SaveService.last_load_result="" # fixture: judge this restore, not the boot-time load of the probe profile
    sim.restore(data)
    check(SaveService.last_load_result not in ["invalid_profile_reset"] and sim.state.pickups.size()==1 and sim.state.pickups[0].has("dropped"),"A dropped pile saves and loads")
    sim.state.pickups[0].ttl=.05
    sim.step(.1)
    check(sim.state.pickups.is_empty(),"…and expires like other loot")
    # UI: Drop All in red, confirmation with name, level and quantity, red Drop All button.
    fresh()
    sim.add_item("wood_sword",7);sim.merge("wood_sword")
    game.selected="wood_sword";game.selected_slot=-1;game._open("item");await frames(2)
    var drop: Button=guide_button("drop_all")
    check(drop!=null and drop.text=="Drop All" and drop.theme_type_variation==&"Danger" and not drop.disabled,"Item details offer a red Drop All")
    drop.pressed.emit();await frames(2)
    var confirm: Control=game.get_node("Confirm")
    var body: String=confirm.get_node("Panel/Margin/Content/Scroll/Text").text
    var yes: Button=confirm.get_node("Panel/Margin/Content/Actions/Confirm")
    check(confirm.visible and body.begins_with("Wood Sword ^1 · ×6"),"The confirmation names the item, its merge level and quantity: \"%s\"" % body.get_slice("\n",0))
    check(yes.text=="Drop All" and yes.theme_type_variation==&"Danger","…and its button is a red Drop All")
    yes.pressed.emit();await frames(2)
    check(sim.quantity("wood_sword")==0 and sim.state.pickups.size()==1,"Confirming drops the stack")
    check(yes.theme_type_variation==&"" or not confirm.visible,"The dialog closes")
    game._confirm("x",func()->void:pass)
    check(yes.theme_type_variation==&"" and yes.text=="Confirm","Other confirmations keep the ordinary button")
    game._cancel_confirm();game._close()
    sim.add_item("potion",3)
    game.selected="potion";game.selected_slot=sim.state.supplies.find("potion");game._open("item");await frames(2)
    check(guide_button("drop_all")!=null,"Supplies can be dropped too")
    game._close()

# ---------------------------------------------------------------- 8b. Map Mastery
func mastery_checks() -> void:
    print("-- Map Mastery")
    fresh()
    var r=sim.campaign.mastery.rules
    check(r.map_rewards[5]=={"gem_chance":0.02} and r.map_rewards[7]=={"hp":0.15},"Autumn II rewards +2 pts Gem Chance, Spring II +15% max HP")
    var gem: float=sim.gem_base_chance();var hp: float=sim.card("hp")
    sim.state.mastery.done.append("map:6");sim.campaign.mastery.reset_cache() # fixture: Autumn II mastered in an existing save
    check(near(sim.gem_base_chance()-gem,.02) and near(sim.card("hp"),hp),"A latched Autumn II pays the Gem Chance (no claim state to migrate)")
    sim.state.mastery.done.append("map:8");sim.campaign.mastery.reset_cache();sim.touch()
    check(near(sim.card("hp")-hp,.15),"A latched Spring II pays +15% max HP")
    var data=JSON.parse_string(JSON.stringify(sim.snapshot()))
    sim.restore(data)
    check(near(sim.gem_base_chance()-gem,.02) and near(sim.card("hp")-hp,.15),"…through save and load")
    game._open("mastery");await frames(2)
    check(labels_text(game.rows).contains("Autumn II") and labels_text(game.rows).contains("+2 pts Gem Chance"),"The Mastery list shows the swapped rewards")
    game._close()
    # The summary chip above Map Explored.
    refresh_hud();await frames(2)
    var chip: Button=map_node("Mastery")
    var st:=int(sim.state.stage)
    check(chip.visible and chip.text==tr("MASTERY_CHIP") % [sim.campaign.mastery.map_percent(st),0,5],"Chip reads \"%s\"" % chip.text)
    var explored:=map_node("Explored")
    check(chip.get_rect().end.y<=explored.get_rect().position.y and is_equal_approx(chip.get_rect().end.x,explored.get_rect().end.x) and chip.get_rect().position.y>=map_node("Zoom").get_rect().end.y,"It sits above Map Explored, under the zoom, on the cluster's right edge")
    check(chip.size.y>=44 and chip.get_theme_font_size("font_size")>=16,"A 44 px tap target, 17 px text")
    chip.pressed.emit();await frames(2)
    check(game.sheet.visible and game.panel=="mastery" and game.mastery_stage==st and game.get_node("Sheet/Margin/Content/Header/Title").text==tr("MASTERY_MAP_TITLE") % sim.catalog.stages[st-1].name,"Tapping it opens this map's Mastery page directly")
    game._close()
    # Change 25: Basic/None open Map Mastery at once; Guided shows it with its Prestige lesson.
    sim.state.tutorial.mode="guided";sim.campaign.guided.data().done=[] # fixture: Guided, lessons ahead
    refresh_hud()
    check(not chip.visible,"Guided: hidden until Map Mastery is revealed")
    sim.state.tutorial.mode="none";refresh_hud()
    check(chip.visible,"None: shown from the start")

# ---------------------------------------------------------------- 9. Cyan Robot Heal
func robot_checks() -> void:
    print("-- Cyan Robot Heal")
    fresh()
    var robot_def: Dictionary=sim.catalog.groups[group("boss-cyan-robot")]
    check(near(sim.campaign.enemy_skill_cooldown(robot_def,"heal"),12.0) and near(float(sim.catalog.skills.heal.cooldown),20.0),"Configured: catalog Heal 20 s, Cyan Robot 12 s (50% more often)")
    var others_ok:=true
    for g in range(sim.catalog.groups.size()):
        var d: Dictionary=sim.catalog.groups[g]
        if d.id=="boss-cyan-robot":continue
        for key in d.skills:
            if not near(sim.campaign.enemy_skill_cooldown(d,key),float(sim.catalog.skills[key].cooldown)):others_ok=false
    check(others_ok,"Every other enemy keeps the catalog cooldowns (Space Helmet, Squirrel, Bee, Red Panda and Sunflower Heal 18 s)")
    stage(2)
    var robot:=actor_of("boss-cyan-robot")
    var maxhp: float=float(sim.enemy_definition(int(robot.group),2).hp)
    heals.clear()
    for k in range(400):
        robot.aggro=true;robot.returning=false
        if float(robot.hp)>maxhp*.5:robot.hp=maxhp*.4
        sim.state.clock=float(sim.state.clock)+.1
        sim.campaign.step(.1)
    var times: Array=heals.filter(func(h):return h[0]==str(robot.id)).map(func(h):return h[2])
    var gaps: Array=[]
    for k in range(1,times.size()):gaps.append(snappedf(times[k]-times[k-1],.1))
    check(times.size()>=3 and gaps.all(func(gap):return gap>=12.0 and gap<=13.0),"In combat below 80%% HP it heals every %s s (12 s + the 0.6 s wind-up; was 18.6)" % str(gaps))

# ---------------------------------------------------------------- 12. skill descriptions
func skill_text_checks() -> void:
    print("-- skill descriptions")
    fresh()
    sim.state.upgrades["gear_slots"]=7 # fixture: room for all six skills
    for k in range(7):sim.state.gear.append("")
    var bad: Array=[]
    for key in sim.catalog.skills:
        var id: String="skill_"+key
        sim.add_item(id,3)
        var lines: Array=game.skill_description(id)
        var text: String="\n".join(lines)
        var ok: bool=lines.size()>=2 and not text.contains("Power") and text.contains("Cooldown: %s s" % game.fmt_value(sim.player_upgrade_value("cooldown_"+key))) and RegEx.create_from_string("\\d").search(lines[0])!=null
        if key in ["frost","fire","lightning","strike"]:ok=ok and text.contains(game.fmt_value(float(sim.stats().damage)*float(sim.normal(id).power))) and text.contains("× attack damage")
        if key=="frost":ok=ok and text.contains("all enemies in the area") and text.contains("96") and text.contains("slows them 25% for 3 s")
        if key=="fire":ok=ok and text.contains("64") and text.contains("Range: 120")
        if key=="lightning":ok=ok and text.contains("1 enemy") and text.contains("Range: 120")
        if key=="strike":ok=ok and text.contains("Range: 80")
        if key=="heal":ok=ok and text.contains("10% of maximum HP") and text.contains("outside combat") and text.contains("Range: self")
        if key=="focus":ok=ok and text.contains("+10% attack damage for 5 s") and text.contains("only in combat")
        if not ok:bad.append(text)
    check(bad.is_empty(),"All six skills describe damage or healing, multiplier, targets, range or area, duration and cooldown with today's numbers %s" % str(bad))
    # Change 17 UI handoff: Heal eligibility prose and new Lightning/boss status prose remain
    # Claude-owned. This probe checks existing numeric wiring, not completion of that deferred UI.
    var before: String=game.skill_description("skill_fire")[0]
    sim.merge("skill_fire")
    check(game.skill_description("skill_fire")[0]!=before,"A merge updates the numbers (\"%s\")" % game.skill_description("skill_fire")[0])
    sim.state.upgrades["cooldown_fire"]=2;sim.touch()
    check(game.skill_description("skill_fire")[1].contains("Cooldown: 18 s"),"The cooldown upgrade shows (20 s → 18 s)")
    sim.state.owned_cards.append("specialist_c3");sim.touch() # fixture: +25% skill strength
    check(game.skill_description("skill_fire")[0].begins_with(game.fmt_value(float(sim.normal("skill_fire").power)*1.25)+"×"),"Skill cards raise the shown multiplier")
    game.selected="skill_lightning";game.selected_slot=-1;game._open("item");await frames(2)
    var shown: String=labels_text(game.rows)
    check(shown.contains("attack damage") and not shown.contains("Power  "),"Item details show the description instead of \"Power\" (%s)" % shown)
    game._close()

# ---------------------------------------------------------------- 13. Prestige confirmation screen
func confirm_checks() -> void:
    print("-- Prestige confirmation")
    fresh()
    sim.state.bosses_found.append("boss-snowman")
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    sim.state.gems=77;sim.state.coins=1234
    game._open("prestige");await frames(2)
    var begin: Button=guide_button("begin_prestige")
    check(begin!=null and not begin.disabled,"The Prestige action is available")
    begin.pressed.emit();await frames(3)
    var screen: Control=game.get_node("PrestigeConfirm")
    check(screen.visible and not game.get_node("Confirm").visible,"It opens the Prestige screen, not the ordinary dialog")
    var plate: Control=screen.get_node("Plate")
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var safe:=Rect2(Vector2(insets.x,insets.y),game.size-Vector2(insets.x+insets.z,insets.y+insets.w))
    check(safe.encloses(plate.get_global_rect()),"It fits the safe area (%s)" % str(plate.get_global_rect()))
    check(screen.get_node("Plate/Frame").visible and screen.get_node("Plate/Sparks").get_child_count()==4 and screen.get_node("Plate/Margin/Content/Header/Art").texture!=null,"Milestone look: gold frame, sparks and the star, like the discovery banner")
    var keep: String=screen.get_node("Plate/Margin/Content/Scroll/Body/Keep/Box/List").text
    var reset: String=screen.get_node("Plate/Margin/Content/Scroll/Body/Reset/Box/List").text
    # Change 50: the approved lists (Coins, every upgrade and merge levels are kept).
    check(keep.contains("Your Gems: 77") and keep.contains("Your Coins: 1.23K") and keep.contains("Explored map areas") and keep.contains("Every upgrade you bought") and keep.contains("Merge levels"),"Permanent card lists Coins, Gems, exploration, every upgrade and merge levels")
    check(reset.contains("Every item you carry") and reset.contains("random bonus attributes") and reset.contains("owned camps") and not reset.contains("Coins:"),"Reset card lists items and their attributes, camps; not Coins")
    check(screen.get_node("Plate/Margin/Content/Scroll/Body/Keep/Box/Title").get_theme_color("font_color").g>.9 and screen.get_node("Plate/Margin/Content/Scroll/Body/Reset/Box/Title").get_theme_color("font_color").r>.9,"Kept and reset read apart (green, orange)")
    check(screen.get_node("Plate/Margin/Content/Scroll/Body/Opportunities").get_child_count()==1,"It lists the one opportunity redeemed")
    var cancel: Button=screen.get_node("Plate/Margin/Content/Actions/Cancel")
    var go: Button=screen.get_node("Plate/Margin/Content/Actions/Begin")
    check(cancel.size.y>=64 and go.size.y>=64 and safe.encloses(go.get_global_rect()),"Both buttons are large and reachable")
    cancel.pressed.emit();await frames(1)
    check(not screen.visible and sim.state.prestige_batch.is_empty(),"Cancel changes nothing")
    begin=guide_button("begin_prestige");begin.pressed.emit();await frames(2)
    screen.get_node("Plate/Margin/Content/Actions/Begin").pressed.emit();await frames(2)
    check(not screen.visible and not sim.state.prestige_batch.is_empty(),"Begin Prestige starts the card choice")
    sim.campaign.cancel_prestige();game._close()

# ---------------------------------------------------------------- 3. audio
func audio_checks() -> void:
    print("-- music settings")
    var saved:=SettingsState.music_volume
    SettingsState.set_music_volume(.6)
    check(not AudioService.music_should_hold(),"Music plays at 60%")
    SettingsState.set_music_volume(0.0)
    check(AudioService.music_should_hold(),"At 0 the track holds its place (paused, not stopped)")
    SettingsState.set_music_volume(.3)
    check(not AudioService.music_should_hold(),"Above 0 it resumes")
    get_tree().paused=true
    check(AudioService.music_should_hold(),"While the game is paused it holds")
    get_tree().paused=false
    check(not AudioService.music_should_hold(),"…and resumes after the pause")
    SettingsState.set_music_volume(saved)
    print("  note  real playback (position kept through 0 volume, pause and a scene reload) is checked by tests/change_16_audio (windowed)")

# ---------------------------------------------------------------- 11. Guided opening and camps
func guide_checks() -> void:
    print("-- Guided opening and View Camp")
    fresh("guided")
    sim.state.tutorial.done.clear()
    var rules: OnboardingRules=sim.campaign.onboarding.rules
    await frames(3)
    check(game.guide.pending=="move" and game.guide.step=="move" and game.guide.title.text=="Follow the path to your left.","Guided opens with \"%s\"" % game.guide.title.text)
    check(game.guide.path_point==rules.path_target and game.guide.pointer.visible,"An arrow points along the path (OnboardingRules.path_target)")
    var dir:=Vector2.RIGHT.rotated(game.guide.pointer.rotation+game.guide.ARROW_BASE_ANGLE)
    check(dir.x<-.8,"…to the left (%.2f, %.2f)" % [dir.x,dir.y])
    var player_screen: Vector2=game.world.player_screen_position()
    check(game.guide.pointer.get_global_rect().get_center().x<game.get_node("Safe/Layout/Map").global_position.x+player_screen.x*game.get_node("Safe/Layout/Map").size.x/game.world.get_viewport_rect().size.x,"…placed on the player's left side")
    # Walking another way does not complete it, and does not break it.
    sim.state.player.x+=220;sim.campaign.reveal();await frames(2)
    check(game.guide.pending=="move","Walking right instead: the lesson stays and keeps pointing")
    var dir2:=Vector2.RIGHT.rotated(game.guide.pointer.rotation+game.guide.ARROW_BASE_ANGLE)
    check(dir2.x<-.8,"…still toward the path")
    sim.state.counters["kill"]=1.0 # fixture: a defeat somewhere else
    await frames(2)
    check(sim.state.tutorial.done.has("move") and game.guide.pending!="move","A first defeat anywhere continues the tutorial")
    fresh("guided");sim.state.tutorial.done.clear()
    sim.state.player.x=rules.path_target.x+40;sim.state.player.y=rules.path_target.y
    await frames(2)
    # Change 35: the targeting lesson now follows the path walk, before the first kill.
    check(sim.state.tutorial.done.has("move") and game.guide.pending=="target","Reaching the path completes it and the normal sequence continues (%s)" % game.guide.pending)
    # Camps: no pop-up on approach; a View Camp button under the camp's name instead.
    fresh("none")
    var camp: Array=sim.campaign.stage().spawns[1]
    sim.state.camps_known["1"]=[1]
    sim.state.player.x=float(camp[0])+50;sim.state.player.y=float(camp[1])
    sim.movement=Vector2(-1,0)
    for k in range(6):
        sim.state.player.x-=10;await frames(1)
    sim.movement=Vector2.ZERO
    await frames(2)
    var view: Button=map_node("ViewCamp")
    check(not game.sheet.visible,"Walking into a camp no longer opens its panel")
    check(view.visible and view.text=="View Camp" and game.view_camp==1,"A View Camp button shows")
    var label_point: Vector2=game._camp_label_point(1)
    check(view.get_rect().position.y>=label_point.y and absf(view.get_rect().get_center().x-label_point.x)<2 and view.size.y>=48,"…just below the camp's name, centred, 56 px tall")
    view.pressed.emit();await frames(2)
    check(game.sheet.visible and game.panel=="camp" and game.selected_camp==1,"View Camp opens that camp")
    check(not view.visible,"…and hides under the panel")
    game._close()
    game.world.camp_selected.emit(1);await frames(1)
    check(game.panel=="camp","Tapping the camp itself still opens it")
    game._close()
    sim.state.player.x=float(camp[0])+300;await frames(2)
    check(not view.visible,"Walking away hides the button")
    # Guided camp lesson points at View Camp when standing there.
    fresh("guided")
    # Change 61: the camp lesson now follows the inventory and potion lessons.
    sim.campaign.guided.data().done=sim.campaign.guided.STEPS.slice(0,sim.campaign.guided.STEPS.find("potion_use")+1)
    sim.state.camps_known["1"]=[1];sim.state.coins=1000
    sim.state.player.x=float(camp[0]);sim.state.player.y=float(camp[1])+20
    await frames(3)
    check(game.guide.pending=="camp" and game.guide.step=="camp_view" and game.guide.target==view,"The camp lesson points at View Camp (%s)" % game.guide.step)
    view.pressed.emit();await frames(3)
    check(game.guide.step=="camp_buy" and game.guide.target!=null and game.guide.target.get_meta("guide","")=="camp_buy_1","…then at Unlock in the camp")
    game._close()
    sim.state.player.x=float(camp[0])+400;await frames(3)
    check(game.guide.step=="camp_approach" and game.guide.path_point!=Vector2.INF,"Away from camp, arrow guides physical approach")

# ---------------------------------------------------------------- 14. Settings: Help, no development UI
func settings_checks() -> void:
    print("-- Settings and Help")
    fresh("guided")
    sim.state.onboarding.reveal=["missions","enemy","world"] # fixture: mid-progression
    sim.state.tutorial.done=["move","kill"]
    sim.campaign.guided.data().done=sim.campaign.guided.STEPS.slice(0,sim.campaign.guided.STEPS.find("close_upgrade")+1)
    game._open("settings");await frames(2)
    var all: String=" | ".join(buttons(game.rows).map(func(b):return b.text))
    check(not all.contains("Show all menus") and not all.contains("Choose guidance again"),"Settings has no Show all menus and no Choose guidance again")
    check(button_with(game.rows,"Help")!=null,"…and offers Help")
    var labels: String=labels_text(game.rows)
    check(not labels.contains("during development") and not all.contains("during development") and not labels.contains("translation validation") and not all.contains("Available after"),"No development notices (Change 40: languages not enabled yet are not listed, and nothing says why)")
    var before: Dictionary={"tutorial":sim.state.tutorial.duplicate(true),"reveal":sim.state.onboarding.reveal.duplicate(),"explored":sim.state.explored.duplicate(true),"counters":sim.state.counters.duplicate(true)}
    button_with(game.rows,"Help").pressed.emit();await frames(2)
    var text: String=labels_text(game.rows)
    check(game.panel=="help" and text.contains("Walk, fight, collect") and text.contains(tr("GUIDE_BASIC_WORLD")) and text.contains(tr("GUIDE_BASIC_GEAR")),"Help opens the Basic overview deck (Change 25: the same cards Basic shows)")
    check(not text.contains(tr("GUIDE_BASIC_PRESTIGE")) and text.contains(tr("GUIDE_BASIC_GROWTH")),"Guided: Help includes revealed upgrades and hides unrevealed Prestige")
    check(sim.state.tutorial==before.tutorial and sim.state.onboarding.reveal==before.reveal and sim.state.explored==before.explored and sim.state.counters==before.counters and sim.state.tutorial.mode=="guided","Reading it changes no progress, discovery, menu or guidance mode")
    guide_button("help_back").pressed.emit();await frames(1)
    check(game.panel=="settings","Back returns to Settings")
    game._close()
    var source: String=FileAccess.get_file_as_string("res://scripts/game/game_ui.gd")
    check(not source.contains("_event(\"DEVELOPMENT_SAVE_RESET\")"),"No development-save toast after a profile reset")
