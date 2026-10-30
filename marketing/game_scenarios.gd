extends "res://addons/marketing_capture/scenario_adapter.gd"
## LootFarmer marketing adapter (Change 27, Godot Marketing Capture Toolkit 1.0.2). One
## prepare_scenario(id, options) for the Google Play screenshots and the store trailer clips.
##
## Every scenario is real game state built through the game's own simulation (new_profile, add_item,
## equip, equip_skill, merge, begin_prestige, travel/stage setup, fog reveal) and then PLAYED by the
## real simulation: combat, summons, skills, drops and pickups all come from simulation.gd/campaign.gd.
## Fixtures only stand in for time: a plausible late-game profile (items that enemies really drop,
## merge levels the Change 9 balance fixture validated, Prestige cards actually chosen through
## begin_prestige/prestige) and timers moved forward to just before a real event (a summon cooldown).
## Nothing here changes damage, HP, drop rates, helpers or UI, and nothing ships: marketing/ is
## outside the Release export allowlist (tools/export_rules.json, exclude_filter).
##
## Safety: is_capture_safe() requires a capture-* profile namespace (BootContext, resolved before any
## save is read) and --no-autosave. The adapter starts every scenario from sim.new_profile(), so
## whatever the capture profile held before is never shown and the player's profile is never opened.

const LOG:="LOOTFARMER_MARKETING "
## Spring II late-game loadout: the Change 9 balance fixture's FINAL-tier set (every item dropped by a
## real enemy, weapons no higher than the best dropped tier), with the outfit at the ^500 level the
## fixture found a Spring II boss needs (Red Panda: beatable at ^500).
const LOADOUT:={"level":238,"weapon":["emerald_sword",90],
    "stored":[["diamond_sword",100],["diamond_axe",100],["gold_sword",100],["gold_axe",100]],
    "outfit":["unit-sprout_outfit_t5",500],"stored_outfits":[["boss-bee_outfit_t4",100],["boss-red-panda_outfit_t5",120],["unit-plain_outfit_t5",200]],
    "skills":[["skill_lightning",50],["skill_fire",50],["skill_strike",50]]}

var game
var sim
var job: Dictionary={}
var scenario:=""
var options: Dictionary={}
## Scripted taps during a clip: [[seconds, Callable], ...], run once each from _process.
var timeline: Array=[]
var clock:=0.0
var fps:=30.0

func is_capture_safe() -> bool:
    var boot: Node=Engine.get_main_loop().root.get_node_or_null("BootContext")
    if boot==null:return false
    return str(boot.profile_name).begins_with("capture-") and not bool(boot.autosave_enabled) and bool(boot.is_probe)

func prepare_scenario(scenario_id: String,options_: Dictionary,game_root: Node,capture: Dictionary) -> bool:
    game=game_root;sim=game.sim;job=capture;scenario=scenario_id;options=options_
    fps=float(capture.get("fps",30))
    # The game's root Control processes ALWAYS (its pause button and dialogs work while paused). A
    # screenshot freezes the tree after capture_frame frames; left ALWAYS, the HUD would keep updating
    # and show its own paused state ("Resume"), which the player never sees in play. PAUSABLE freezes
    # the HUD on the same frame as the world. Videos never pause.
    if str(capture.get("kind",""))=="screenshot":game.process_mode=Node.PROCESS_MODE_PAUSABLE
    var settings: Node=get_tree().root.get_node("SettingsState")
    settings.set_music_volume(0.0) # the trailer's music is one continuous track added at composition
    var ok:=false
    match scenario_id:
        "boss_sunflower":ok=_boss_sunflower()
        "loot_collection":ok=_loot_collection()
        "equipment_merge":ok=_equipment_merge()
        "late_farming":ok=_late_farming()
        "world_progress":ok=_world_progress()
        "prestige_cards":ok=_prestige_cards()
        "boss_victory":ok=_boss_victory()
        "explore":ok=_explore()
        "trailer_gear":ok=_trailer_gear()
        "trailer_merge":ok=_trailer_merge()
        "trailer_farm":ok=_trailer_farm()
        "match_boss":ok=_match_boss()
        "shot_gear":ok=_shot_gear()
        "shot_merge":ok=_shot_merge()
        "shot_explore":ok=_shot_explore()
        "shot_prestige":ok=_shot_prestige()
        _:push_error(LOG+"unknown scenario "+scenario_id)
    # Change 32: every banner raised during a take is logged, so a review can refuse one it should not show.
    if ok:sim.milestone.connect(func(kind,id):print(LOG,"MILESTONE ",kind," ",id," t=",clock))
    if ok and bool(options.get("clean",false)):_clean_view()
    print(LOG,"prepared ",scenario_id," ok=",ok," size=",capture.get("width"),"x",capture.get("height"))
    return ok

func _process(delta: float) -> void:
    clock+=delta
    while not timeline.is_empty() and clock>=float(timeline[0][0]):
        var entry: Array=timeline.pop_front()
        (entry[1] as Callable).call()
    if not hidden_ui.is_empty():
        for node in hidden_ui:node.visible=false # game code may re-show a HUD part
    if zoom_move.size()==4:
        var x:=clampf((clock-float(zoom_move[2]))/maxf(.001,float(zoom_move[3])),0.0,1.0)
        x=x*x*(3.0-2.0*x)
        _set_zoom(lerpf(float(zoom_move[0]),float(zoom_move[1]),x))
        if x>=1.0:zoom_move=[]

# ---------------------------------------------------------------- Change 32: clean, closer shots

## HUD parts hidden in a clean take (the toolkit's ui_group; Playbook 87.2 intentional clean shot).
var hidden_ui: Array=[]
## Camera push-in: [from, to, start clock, seconds].
var zoom_move: Array=[]

## A clean take shows the world alone: the HUD rows below the map are hidden (the map then fills the
## screen) and so is everything drawn over the map (minimap, side buttons, labels, joystick). The world,
## its actors, health bars, numbers, loot, speech and weather are untouched. Marketing capture only.
func _clean_view() -> void:
    var group:=str(job.get("ui_group","store_screenshot_ui"))
    var layout: Node=game.get_node("Safe/Layout")
    var parts: Array=[]
    for child in layout.get_children():
        if child.name!="Map":parts.append(child)
    for child in layout.get_node("Map").get_children():
        if child.name!="ViewportContainer":parts.append(child)
    parts.append(game.get_node("Toast"))
    for node in parts:
        if node is CanvasItem:
            node.add_to_group(group);node.visible=false;hidden_ui.append(node)
    print(LOG,"clean view: ",hidden_ui.size()," HUD parts hidden")

## The camera's zoom for a clean take. The Settings slider stops at 3x; a clean take has no slider on
## screen, so the camera may come closer (the same camera, the same follow; only the framing changes).
func _set_zoom(value: float) -> void:
    if bool(options.get("clean",false)):_settings().camera_zoom=value
    else:_settings().set_camera_zoom(value)

func _push_in(to: float,seconds: float) -> void:
    zoom_move=[float(_settings().camera_zoom),to,clock,seconds]
    print(LOG,"ZOOM ",zoom_move[0]," -> ",to," t=",clock)

## Equips through the simulation's own equip() (what the item panel's Equip button calls), with no
## panel on screen, so the shot stays on the player whose look changes.
func _equip_direct(id: String) -> void:
    var ok: bool=sim.equip(id)
    print(LOG,"EQUIP_DIRECT ",id," ok=",ok," t=",clock," weapon=",sim.state.weapon," outfit=",sim.state.outfit)

# ---------------------------------------------------------------- shared late-game profile

func _settings() -> Node:return get_tree().root.get_node("SettingsState")

func _group(id: String) -> int:
    for i in range(sim.catalog.groups.size()):
        if str(sim.catalog.groups[i].id)==id:return i
    return -1

func _actor_of(group_id: String) -> Dictionary:
    var g:=_group(group_id)
    for e in sim.state.enemies:
        if int(e.group)==g and not sim.is_helper(e):return e
    return {}

func _give(id: String,merge_level: int) -> bool:
    if not sim.add_item(id,1,true,false):
        push_error(LOG+"cannot add "+id);return false
    var r: Dictionary=sim.record(id)
    r.merge=merge_level;r.extras={} # fixture: the merge level a late-game player reaches
    return true

## A Spring II player who has cleared Winter I to Spring I in this run, prestiged before, and wears a
## real late-game loadout. Built with the simulation's own calls; fixtures stand in for play time.
func _late_profile(seed_value: int) -> bool:
    sim.new_profile()
    sim.rng.seed=seed_value
    sim.suspended=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    # A returning player has long since read the one-time Road Ahead announcement.
    if not sim.state.tutorial.seen.has("road_ahead"):sim.state.tutorial.seen.append("road_ahead")
    game._close();_hud_clean()
    sim.state.gear.resize(18);sim.state.gear.fill("") # fixture: equipment slots bought earlier (kept by Prestige)
    sim.state.upgrades["gear_slots"]=15
    sim.state.player_level=int(LOADOUT.level)
    # 1. Lifetime history: Winter I .. Spring I cleared before (gate bosses defeated, maps explored).
    for st in range(1,8):
        for boss_id in sim.catalog.stages[st-1].gates:
            var g:=_group(str(boss_id))
            sim.state.group_kills[g]=maxi(int(sim.state.group_kills[g]),3+st)
            if not sim.state.bosses_found.has(str(boss_id)):sim.state.bosses_found.append(str(boss_id))
            sim.state.discovered[str(g)]=true
        for g in sim.catalog.stages[st-1].groups:
            sim.state.discovered[str(g)]=true
            if not sim.catalog.groups[g].boss:sim.state.group_kills[g]=maxi(int(sim.state.group_kills[g]),400+40*st)
        sim.campaign.explore_cells(st,[],true)
        var camps: Array=[]
        for i in range(sim.catalog.stages[st-1].spawns.size()):camps.append(i)
        sim.state.camps_known[str(st)]=camps
    # 2. Earlier Prestiges, through the game's own reset: every opportunity the game marks ready is
    # redeemed with begin_prestige/prestige, so each owned card was genuinely awarded.
    # The previous run reached Spring II too (gates defeated, coins earned): the game itself decides
    # which opportunities that history makes ready.
    sim.state.unlocked_stage=8
    sim.campaign.progress("coins","",2_500_000.0)
    # Boss Hunter history: each target boss found, then farmed (the counters campaign.killed writes).
    for boss_id in ["boss-snowman","boss-gray-cat","boss-grim-reaper"]:_history_kills(boss_id,1)
    sim.campaign.mastery.evaluate(false);sim.campaign.evaluate()
    for boss_id in ["boss-snowman","boss-gray-cat","boss-grim-reaper"]:_history_kills(boss_id,30)
    for round in range(int(options.get("prestiges",1))):
        for i in range(2):
            sim.campaign.mastery.evaluate(false);sim.campaign.evaluate()
        var why: String=sim.campaign.prestige_block_reason()
        if not why.is_empty():
            print(LOG,"prestige blocked: ",why);break
        if not sim.campaign.begin_prestige():break
        while not sim.state.prestige_batch.is_empty() and not sim.campaign.offered_cards().is_empty():
            if not sim.prestige(sim.campaign.offered_cards()[0]):break
        sim.suspended=false
    print(LOG,"profile prestiges=",sim.state.prestiges," cards=",sim.state.owned_cards.size())
    # 3. This run: Winter I .. Spring I cleared again, Spring II reached, gear re-farmed.
    _run_cleared()
    for pair in [LOADOUT.weapon,LOADOUT.outfit]+LOADOUT.stored+LOADOUT.stored_outfits+LOADOUT.skills:
        if not _give(pair[0],pair[1]):return false
    if not sim.equip(LOADOUT.weapon[0]) or not sim.equip(LOADOUT.outfit[0]):
        push_error(LOG+"equip failed");return false
    # Change 34: options.wear swaps in stored LOADOUT gear (another real drop the profile owns).
    for id in options.get("wear",[]):
        if not sim.equip(str(id)):
            push_error(LOG+"cannot wear "+str(id));return false
    sim.state.upgrades["skill_slots"]=2
    # Player upgrades bought over the profile (gem upgrades are kept by Prestige; coin ones re-bought).
    for pair in [["critical_chance",14],["critical_damage",12],["movement",6],["respawn",5],["cooldown_lightning",4],["cooldown_fire",4],["cooldown_strike",4],["skill_auto_slots",3],["supply_slots",2]]:
        sim.state.upgrades[pair[0]]=pair[1]
    sim.state.supplies.resize(1+2);sim.state.supplies.fill("")
    for i in range(LOADOUT.skills.size()):
        sim.state.upgrades["skill_auto_%d" % i]=1;sim.state.skill_auto[i]=true
        if not sim.campaign.equip_skill(LOADOUT.skills[i][0],i):
            push_error(LOG+"skill equip failed");return false
    sim.state.coins=float(options.get("coins",48_600_000.0));sim.state.gems=float(options.get("gems",18_450.0))
    sim.state.unlocked_stage=8
    sim.state.camps["8"]=[0,1];sim.state.camps_known["8"]=[0,1,2]
    var stage_id:=int(options.get("stage",8))
    if not _travel(stage_id,int(options.get("camp",1))):return false
    # Spring II explored along the routes a player takes between its first camps and bosses.
    if stage_id==8:
        for spot in _spring_routes():sim.campaign.reveal_circle(spot,190.0)
    _settle()
    sim.state.player.hp=sim.stats().hp
    _settings().set_camera_zoom(float(options.get("zoom",2.0)))
    return true

func _spring_routes() -> Array:
    var points: Array=[]
    var st: Dictionary=sim.catalog.stages[7]
    for i in [0,1]:points.append(Vector2(st.spawns[i][0],st.spawns[i][1]))
    for id in ["boss-sunflower","boss-red-panda"]:
        var a:=_actor_of(id)
        if not a.is_empty():points.append(Vector2(a.home_x,a.home_y))
    var routed: Array=points.duplicate()
    for i in range(points.size()-1):
        for k in range(1,6):routed.append(points[i].lerp(points[i+1],k/6.0))
    return routed

## The built profile goes through the game's own save/load path once, which records Map Mastery and
## other milestones silently (as a load does), then the tick that announces Prestige opportunities runs
## before the first frame; whatever it queued is cleared, so the HUD starts as a returning player sees it.
func _settle() -> void:
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    sim.suspended=false
    for i in range(2):
        sim.campaign.evaluate();sim.campaign.onboarding.evaluate();sim.campaign.mastery.evaluate(false)
    _hud_clean()

## Every boss of Winter I .. `last` (default Spring I) defeated in the current run and every camp there owned.
func _run_cleared(last:=7) -> void:
    for st in range(1,last+1):
        for g in sim.catalog.stages[st-1].groups:
            if sim.catalog.groups[g].boss:sim.state.run_kills[str(sim.catalog.groups[g].id)]=1
        var owned: Array=[]
        for i in range(sim.catalog.stages[st-1].spawns.size()):owned.append(i)
        sim.state.camps[str(st)]=owned

## Earlier boss defeats as campaign.killed records them (boss_kill and boss counters).
func _history_kills(boss_id: String,n: int) -> void:
    for i in range(n):
        sim.campaign.progress("boss_kill",boss_id,1);sim.campaign.progress("boss",boss_id,1)

func _travel(st: int,camp: int) -> bool:
    sim.state.stage=st;sim.state.spawn=camp
    sim._reset_world()
    sim.campaign.reveal()
    game.world.follow_player()
    return int(sim.state.stage)==st

func _place_player(at: Vector2) -> void:
    sim.state.player.x=at.x;sim.state.player.y=at.y
    sim.campaign.reveal()
    game.world.follow_player()

## Runs the real simulation forward (combat, skills, summons, drops) before the first frame.
func _advance(seconds: float) -> void:
    var t:=0.0
    while t<seconds:
        sim.step(.05);t+=.05

func _hud_clean() -> void:
    game.banner.queue.clear();game.banner._finish()
    game.toast_queue.clear();game.get_node("Toast").hide()

# ---------------------------------------------------------------- scenarios

func _boss_sunflower() -> bool:
    if not _late_profile(int(options.get("seed",2701))):return false
    var boss:=_actor_of("boss-sunflower")
    if boss.is_empty():push_error(LOG+"no sunflower");return false
    # Change 32: the trailer dresses the player in a stored outfit that reads apart from the Sprouts.
    if options.has("outfit") and str(sim.state.outfit)!=str(options.outfit) and not sim.equip(str(options.outfit)):
        push_error(LOG+"cannot wear "+str(options.outfit));return false
    _place_player(sim.position_of(boss)+Vector2(float(options.get("dx",34)),float(options.get("dy",12))))
    boss.aggro=true
    # Staging: the summon timer moved forward to just before the boss's real call (the game then
    # telegraphs and spawns its Sprouts itself).
    boss.summon_cd=float(options.get("summon_in",0.6))
    # Staging: skills used shortly before (their real cooldowns still running), so the casts land
    # during the shot instead of all on its first frame.
    var skill_at: Dictionary=options.get("skill_at",{})
    for key in skill_at:sim.state.skill_cooldowns[key]=float(skill_at[key])
    sim.summoned.connect(func(id,ids):print(LOG,"SUMMON ",id," helpers=",ids.size()," t=",clock))
    sim.spell_cast.connect(func(id,key,_p):if id=="player":print(LOG,"PLAYER_SKILL ",key," t=",clock))
    _advance(float(options.get("advance",0.0)))
    _hud_clean()
    return true

## Late-game farming upgrades a player has bought for the types it farms (real upgrade
## levels within each upgrade's cap; Auto-Collect only when the scenario asks for it).
func _farm_upgrades(groups: Array,auto_collect: bool) -> void:
    for g in groups:
        for pair in [["loot",15],["spawn_amount",3],["spawn_cooldown",5],["coin_amount",12],["supply_drop",10],["skill_drop",8],["reveal_stats",1],["reveal_drops",1]]:
            sim.state.upgrades["%s:%d" % [pair[0],g]]=pair[1]
        if auto_collect:
            for pair in [["collect",1],["collect_range",4],["collect_speed",5],["collect_batch",3]]:sim.state.upgrades["%s:%d" % [pair[0],g]]=pair[1]
    sim._sync_spawn_counts()
    sim.state.player.hp=sim.stats().hp

func _spot_of(group_id: String) -> Vector2:
    var e:=_actor_of(group_id)
    return Vector2(e.home_x,e.home_y)

## Player beside a normal pack of the current stage; everything after this is the simulation fighting.
func _farm_at(group_id: String,offset: Vector2,auto_collect: bool) -> bool:
    var g:=_group(group_id)
    _farm_upgrades(sim.campaign.stage().groups.filter(func(x):return not sim.catalog.groups[x].boss),auto_collect)
    var spot:=_spot_of(group_id)
    for e in sim.state.enemies:
        if int(e.group)==g:sim.campaign.discover_spot(g,int(e.get("variant",2)))
    _place_player(spot+offset)
    return g>=0

func _pickups_near(radius: float) -> Array:
    var at: Vector2=sim.position_of(sim.state.player)
    return sim.state.pickups.filter(func(d):return at.distance_to(Vector2(d.x,d.y))<=radius)

## Advances real farming until at least `want` drops lie near the player (bounded).
func _farm_until_drops(want: int,limit: float) -> int:
    var t:=0.0
    while t<limit and _pickups_near(150.0).size()<want:
        sim.step(.05);t+=.05
        if sim.state.player.hp<sim.stats().hp*.2:break
    print(LOG,"farmed ",t,"s drops=",_pickups_near(150.0).size()," kills=",sim.campaign.counter("kill"))
    return _pickups_near(150.0).size()

## 02: a Spring I boss (the Bee) defeated by the real simulation; its genuine drops lie on the ground.
## In a clip the player then taps them in one by one (sim.collect, the action a tap on a pickup runs).
func _loot_collection() -> bool:
    if not _late_profile(int(options.get("seed",2702))):return false
    var boss_id:=str(options.get("boss","boss-bee"))
    var boss:=_actor_of(boss_id)
    if boss.is_empty():push_error(LOG+"no "+boss_id);return false
    _farm_upgrades([int(boss.group)],false)
    _place_player(sim.position_of(boss)+Vector2(float(options.get("dx",30)),float(options.get("dy",10))))
    boss.aggro=true
    # A clip stops the fight just before the last blows so the defeat and its drops are recorded.
    var finish:=float(options.get("finish_hp",0.0))
    var max_hp: float=float(sim.enemy_definition(int(boss.group)).hp)
    var t:=0.0
    while t<90.0 and float(boss.hp)>max_hp*finish and sim.state.player.hp>0:
        sim.step(.05);t+=.05
    _watch(boss)
    if finish<=0.0:
        _advance(float(options.get("after",0.4)))
        var near:=_pickups_near(150.0)
        print(LOG,"boss fight ",t,"s defeated=",float(boss.hp)<=0," drops=",near.map(func(d):return d.item))
        if float(boss.hp)>0 or near.is_empty():return false
    else:
        print(LOG,"boss fight staged ",t,"s boss=",float(boss.hp)/max_hp)
    _hud_clean()
    if str(job.get("kind",""))=="video":
        var at:=float(options.get("collect_from",1.2))
        for i in range(int(options.get("collect_count",3))):
            timeline.append([at,func():_collect_next()])
            at+=float(options.get("collect_every",0.35))
    return true

## Taps the nearest pickup (sim.collect is what tapping a pickup in the world runs).
func _collect_next() -> void:
    var near:=_pickups_near(150.0)
    if near.is_empty():print(LOG,"COLLECT nothing near");return
    var at: Vector2=sim.position_of(sim.state.player)
    near.sort_custom(func(a,b):return at.distance_to(Vector2(a.x,a.y))<at.distance_to(Vector2(b.x,b.y)))
    print(LOG,"COLLECT ",near[0].item," ok=",sim.collect(int(near[0].uid))," t=",clock)

## Logs the defeat of a staged enemy during a clip (scenario postcondition for the review).
var watched: Dictionary={}
var watched_done:=false
## Taps timed from the watched enemy's defeat: [[seconds after it, Callable], ...] (Change 32).
var after_defeat: Array=[]
func _watch(a: Dictionary) -> void:
    watched=a;watched_done=false

func _physics_process(_delta: float) -> void:
    if not watched.is_empty() and not watched_done and float(watched.hp)<=0:
        watched_done=true
        var drops: Array=sim.state.pickups.filter(func(d):return int(d.group)==int(watched.group)).map(func(d):return d.item)
        print(LOG,"DEFEATED ",watched.id," t=",clock," player_hp=",sim.state.player.hp," drops=",drops)
        for entry in after_defeat:timeline.append([clock+float(entry[0]),entry[1]])
        timeline.sort_custom(func(a,b):return float(a[0])<float(b[0]))

## 03: copies of the equipped Emerald Sword collected from real drops (fixture: owned copies), the
## item panel open, and Merge pressed through its own button: the merge level and Damage rise.
func _equipment_merge() -> bool:
    if not _late_profile(int(options.get("seed",2703))):return false
    var id:=str(options.get("item","emerald_sword"))
    var copies:=int(options.get("copies",3))
    if not sim.add_item(id,copies,true,false):return false # fixture: copies picked up from Spring II bosses
    _hud_clean()
    game.selected=id
    game._open("item")
    var merges:=int(options.get("merges_before",0))
    for i in range(merges):
        if not sim.merge(id):return false
    var times: Array=options.get("press_at",[])
    for at in times:
        timeline.append([float(at),func():_press_merge(id)])
    print(LOG,"merge item ",id," level=",sim.record(id).merge," qty=",sim.quantity(id))
    return true

func _merge_button() -> Button:
    for b in game.pinned_rows.find_children("*","Button",true,false)+game.actions.find_children("*","Button",true,false)+game.rows.find_children("*","Button",true,false):
        if str(b.text)==tr("ITEM_MERGE_ACTION") and b.visible:return b
    return null

func _press_merge(id: String) -> void:
    var b:=_merge_button()
    var before:=int(sim.record(id).merge)
    if b!=null and not b.disabled:b.pressed.emit()
    print(LOG,"MERGE pressed=",b!=null," ",before," -> ",int(sim.record(id).merge))

## 04: a dense late-game fight: the player at the pack spot with the most live enemies around it,
## auto-attacks and auto-cast skills running, Auto-Collect on.
func _late_farming() -> bool:
    if not _late_profile(int(options.get("seed",2704))):return false
    var normals: Array=sim.campaign.stage().groups.filter(func(x):return not sim.catalog.groups[x].boss)
    _farm_upgrades(normals,true)
    var best:=Vector2.ZERO;var most:=-1
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].boss or sim.is_helper(e):continue
        var at:=Vector2(e.home_x,e.home_y)
        var n:=0
        for o in sim.state.enemies:
            if not sim.catalog.groups[int(o.group)].boss and at.distance_to(Vector2(o.home_x,o.home_y))<=float(options.get("radius",150.0)):n+=1
        if n>most:most=n;best=at
    for e in sim.state.enemies:
        if best.distance_to(Vector2(e.home_x,e.home_y))<=260.0:sim.campaign.discover_spot(int(e.group),int(e.get("variant",2)))
    sim.campaign.reveal_circle(best,float(options.get("explored",420.0))) # fixture: the player has farmed here before
    _place_player(best+Vector2(float(options.get("dx",0)),float(options.get("dy",24))))
    print(LOG,"farm spot ",best," enemies near=",most)
    _advance(float(options.get("advance",1.0)))
    _hud_clean()
    return most>0

## 05: the World panel for Spring II (real camps, travel state and explored map).
func _world_progress() -> bool:
    if not _late_profile(int(options.get("seed",2705))):return false
    _farm_at("unit-green-cap",Vector2(-60,40),false)
    _advance(float(options.get("advance",0.0)))
    _hud_clean()
    var at:=float(options.get("open_at",-1.0))
    if at<0:game._open("world")
    else:timeline.append([at,func():game._open("world")])
    return true

## 06: the Prestige panel: cards this profile genuinely earned and the opportunities ready now.
func _prestige_cards() -> bool:
    if not _late_profile(int(options.get("seed",2706))):return false
    _farm_at("unit-green-cap",Vector2(-60,40),false)
    _advance(float(options.get("advance",0.0)))
    sim.campaign.evaluate()
    _hud_clean()
    var at:=float(options.get("open_at",-1.0))
    if at<0:game._open("prestige")
    else:timeline.append([at,func():game._open("prestige")])
    if bool(options.get("choose",false)):
        # The real Prestige button: begin_prestige saves the batch and the card choice opens.
        var begin_at:=float(options.get("begin_at",0.0))
        timeline.append([begin_at,func():_begin_prestige()])
    var scroll:=float(options.get("scroll",0.0))
    if scroll>0:timeline.append([maxf(at,0.0)+float(options.get("scroll_at",1.0)),func():game.get_node("Sheet/Margin/Content/Scroll").scroll_vertical=int(scroll)])
    return true

func _begin_prestige() -> void:
    for b in game.actions.find_children("*","Button",true,false)+game.rows.find_children("*","Button",true,false)+game.pinned_rows.find_children("*","Button",true,false):
        if b.visible and not b.disabled and str(b.text).begins_with(tr("PRESTIGE_BATCH").split("%")[0].strip_edges()):
            b.pressed.emit();print(LOG,"PRESTIGE pressed ",b.text," batch=",not sim.state.prestige_batch.is_empty());return
    print(LOG,"PRESTIGE button not found")

## Trailer closing beat: a Spring II boss (default the Red Panda, also non-final) fought in the real
## simulation until it is nearly beaten; the clip records the finishing blows and its drops.
func _boss_victory() -> bool:
    if not _late_profile(int(options.get("seed",2707))):return false
    var boss_id:=str(options.get("boss","boss-red-panda"))
    var boss:=_actor_of(boss_id)
    if boss.is_empty():push_error(LOG+"no "+boss_id);return false
    _farm_upgrades([int(boss.group)],false)
    _place_player(sim.position_of(boss)+Vector2(float(options.get("dx",34)),float(options.get("dy",12))))
    boss.aggro=true
    var max_hp: float=float(sim.enemy_definition(int(boss.group)).hp)
    var t:=0.0
    while t<240.0 and float(boss.hp)>max_hp*float(options.get("until",0.06)):
        sim.step(.05);t+=.05
        if sim.state.player.hp<=0:break
    print(LOG,"victory fight ",boss_id," ",t,"s boss=",float(boss.hp)/max_hp," player=",sim.state.player.hp/sim.stats().hp)
    _watch(boss)
    _hud_clean()
    return sim.state.player.hp>0 and float(boss.hp)>0

## Development aid: the late-game profile with one panel open (options.panel), for choosing shots.
func _explore() -> bool:
    if not _late_profile(int(options.get("seed",2799))):return false
    var panel_name:=str(options.get("panel",""))
    if panel_name!="":
        if options.has("selected"):game.selected=str(options.selected)
        if options.has("travel_stage"):game.travel_stage=int(options.travel_stage)
        game._open(panel_name)
        if options.has("scroll"):timeline.append([0.3,func():game.get_node("Sheet/Margin/Content/Scroll").scroll_vertical=int(options.scroll)])
    return true

# ---------------------------------------------------------------- Change 32 store trailer

## A first-run profile that has reached `stage_id`: every earlier map cleared (bosses defeated, camps
## owned, maps explored), this map's non-final bosses already found (no first-sight banner during a
## shot), `items` ([id, merge level]) owned and `wear` equipped. Built like _late_profile through the
## simulation's own calls, without the Prestige history none of these shots shows.
func _stage_profile(stage_id: int,player_level: int,items: Array,wear: Array,seed_value: int) -> bool:
    sim.new_profile()
    sim.rng.seed=seed_value
    sim.suspended=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    if not sim.state.tutorial.seen.has("road_ahead"):sim.state.tutorial.seen.append("road_ahead")
    game._close();_hud_clean()
    sim.state.gear.resize(18);sim.state.gear.fill("") # fixture: equipment slots bought earlier
    sim.state.upgrades["gear_slots"]=15
    sim.state.player_level=player_level
    for st in range(1,stage_id):
        for boss_id in sim.catalog.stages[st-1].gates:
            var g:=_group(str(boss_id))
            sim.state.group_kills[g]=maxi(int(sim.state.group_kills[g]),3+st)
            if not sim.state.bosses_found.has(str(boss_id)):sim.state.bosses_found.append(str(boss_id))
        for g in sim.catalog.stages[st-1].groups:
            sim.state.discovered[str(g)]=true
            if not sim.catalog.groups[g].boss:sim.state.group_kills[g]=maxi(int(sim.state.group_kills[g]),300+40*st)
        sim.campaign.explore_cells(st,[],true)
        var camps: Array=[]
        for i in range(sim.catalog.stages[st-1].spawns.size()):camps.append(i)
        sim.state.camps_known[str(st)]=camps
    _run_cleared(stage_id-1)
    for g in sim.catalog.stages[stage_id-1].groups:
        var d: Dictionary=sim.catalog.groups[g]
        if d.boss and not d.final and not sim.state.bosses_found.has(str(d.id)):sim.state.bosses_found.append(str(d.id))
    sim.state.unlocked_stage=maxi(stage_id,int(options.get("unlocked",stage_id)))
    for pair in items:
        if not _give(pair[0],pair[1]):return false
    for id in wear:
        if not sim.equip(str(id)):
            push_error(LOG+"equip failed "+str(id));return false
    var skills: Array=options.get("skills",[])
    sim.state.upgrades["skill_slots"]=maxi(0,skills.size()-1)
    for i in range(skills.size()):
        if not _give(skills[i][0],skills[i][1]):return false
        sim.state.upgrades["skill_auto_%d" % i]=1;sim.state.skill_auto[i]=true
        if not sim.campaign.equip_skill(skills[i][0],i):
            push_error(LOG+"skill equip failed");return false
    sim.state.coins=float(options.get("coins",0.0));sim.state.gems=float(options.get("gems",0.0))
    # History behind the kills above (the counters campaign.killed writes), so the Prestige
    # opportunities it uncovers were announced long before, never as a banner during a shot.
    # options.boss_history: bosses of this map defeated before (without the drop this shot shows);
    # options.challenges: of those, the ones a player beat with no supply used (its challenge done).
    for st in range(1,stage_id+1):
        for g in sim.catalog.stages[st-1].groups:
            if not sim.catalog.groups[g].boss:sim.campaign.progress("kill",str(sim.catalog.groups[g].id),maxi(50,int(sim.state.group_kills[g])))
    for boss_id in options.get("boss_history",[]):
        _history_kills(str(boss_id),1)
        sim.state.group_kills[_group(str(boss_id))]=maxi(1,int(sim.state.group_kills[_group(str(boss_id))]))
    sim.campaign.evaluate()
    for boss_id in options.get("challenges",[]):sim.campaign.progress("restricted",str(boss_id),1)
    # options.known_opportunities: ones a player at this map met long ago with gear it no longer owns
    # (first tier-3 item, first worn pair), recorded as campaign.evaluate() records a discovery.
    for op_id in options.get("known_opportunities",[]):
        if not sim.state.opportunities.has(op_id):sim.state.opportunities[op_id]={"ready":false,"baseline":sim.state.counters.duplicate(true),"step":0,"count":0}
    if not _travel(stage_id,int(options.get("camp",0))):return false
    _settle()
    sim.state.player.hp=sim.stats().hp
    _set_zoom(float(options.get("zoom",2.0)))
    print(LOG,"stage profile ",stage_id," level=",player_level," weapon=",sim.state.weapon," outfit=",sim.state.outfit)
    return true

## The trailer's gear story (Summer II, rain): a player in the plain body with a Wood Sword finishes
## the Teal Dinosaur, which wears its outfit and holds its Iron Sword (catalog groups[].body/weapon;
## its loot is exactly those two). The real kill rolls the drops; the clip then taps each drop, opens
## it from the gear grid and presses Equip, as a player does. The fight before the clip is the real
## simulation fast-forwarded; the seed is chosen so this kill drops both items (checked, never forced:
## a drop that did not happen logs COLLECT MISSING and the take is refused at review).
func _trailer_gear() -> bool:
    var weapon:=str(options.get("weapon","wood_sword"))
    if not _stage_profile(4,int(options.get("level",150)),[[weapon,int(options.get("weapon_merge",100))]],[weapon],int(options.get("seed",3201))):return false
    var boss:=_actor_of("boss-teal-dinosaur")
    if boss.is_empty():push_error(LOG+"no teal dinosaur");return false
    _farm_upgrades([int(boss.group)],false)
    sim.campaign.reveal_circle(Vector2(boss.home_x,boss.home_y),float(options.get("explored",320.0))) # fixture: walked here
    _place_player(sim.position_of(boss)+Vector2(float(options.get("dx",30)),float(options.get("dy",10))))
    boss.aggro=true
    var def: Dictionary=sim.enemy_definition(int(boss.group))
    var max_hp: float=float(def.hp)
    var t:=0.0
    while t<240.0 and float(boss.hp)>max_hp*float(options.get("until",0.1)):
        sim.step(.05);t+=.05
        if sim.state.player.hp<=0:break
    print(LOG,"gear fight ",t,"s boss=",float(boss.hp)/max_hp," player=",sim.state.player.hp/sim.stats().hp," boss_body=",def.body," boss_weapon=",def.weapon," loot=",def.loot)
    if sim.state.player.hp<=0 or float(boss.hp)<=0:return false
    _watch(boss)
    _hud_clean()
    var steps: Dictionary=options.get("steps",{})
    for id in def.loot:
        var kind: String=sim.catalog.items[id].kind
        after_defeat.append([float(steps.get("collect_"+kind,1.0)),func():_collect_item(id)])
        if steps.has("open_"+kind):after_defeat.append([float(steps["open_"+kind]),func():_tap_gear(id)])
        if steps.has("equip_"+kind):after_defeat.append([float(steps["equip_"+kind]),func():_press_pinned("EQUIP",id)])
        if steps.has("wear_"+kind):after_defeat.append([float(steps["wear_"+kind]),func():_equip_direct(id)])
    if steps.has("close"):after_defeat.append([float(steps.close),func():_close_panel()])
    # Change 32 revision: [seconds after the defeat, zoom, push-in seconds]
    if steps.has("push_in"):
        var p: Array=steps.push_in
        after_defeat.append([float(p[0]),func():_push_in(float(p[1]),float(p[2]))])
    return true

## Taps one specific drop on the ground (sim.collect is what tapping a pickup runs).
func _collect_item(id: String) -> void:
    for d in sim.state.pickups:
        if str(d.item)==id:
            print(LOG,"COLLECT ",id," ok=",sim.collect(int(d.uid))," t=",clock," qty=",sim.quantity(id));return
    print(LOG,"COLLECT MISSING ",id," t=",clock)

## Taps an item's tile in the gear grid (the slot's own handler opens the item panel).
func _tap_gear(id: String) -> void:
    var index: int=sim.state.gear.find(id)
    if index<0:print(LOG,"TAP MISSING ",id," t=",clock);return
    game._select_slot(0,index)
    print(LOG,"OPEN ",id," t=",clock)

## Presses a pinned item-panel button by its label (Equip), as a tap does.
func _press_pinned(key: String,id: String) -> void:
    for b in game.actions.find_children("*","Button",true,false):
        if str(b.text)==tr(key) and b.visible and not b.disabled:
            b.pressed.emit()
            print(LOG,"PRESS ",key," ",id," t=",clock," weapon=",sim.state.weapon," outfit=",sim.state.outfit)
            return
    print(LOG,"PRESS MISSING ",key," ",id," t=",clock)

func _close_panel() -> void:
    game._close()
    print(LOG,"CLOSE t=",clock," weapon=",sim.state.weapon," outfit=",sim.state.outfit)

## The trailer's merge (Summer II): the Teal Dinosaur outfit worn, with `copies` spare copies farmed
## from it (fixture: copies picked up earlier, merge level 0). The clip taps its tile, then the item
## panel's own "Merge N spare copies" button: one real merge raises its ^level, HP and the HUD's max HP.
func _trailer_merge() -> bool:
    var outfit:=str(options.get("item","boss-teal-dinosaur_outfit_t2"))
    if not _stage_profile(4,int(options.get("level",200)),[["iron_sword",int(options.get("weapon_merge",0))],[outfit,0],["wood_sword",100]],["iron_sword",outfit],int(options.get("seed",3202))):return false
    if not sim.add_item(outfit,int(options.get("copies",40)),true,false):return false
    var spot:=_spot_of("boss-teal-dinosaur")
    sim.campaign.reveal_circle(spot,float(options.get("explored",320.0)))
    _place_player(spot+Vector2(float(options.get("dx",40)),float(options.get("dy",30))))
    _advance(float(options.get("advance",0.0)))
    _hud_clean()
    timeline.append([float(options.get("open_at",0.6)),func():_tap_gear(outfit)])
    timeline.append([float(options.get("merge_at",1.8)),func():_press_merge_all(outfit)])
    print(LOG,"merge item ",outfit," level=",sim.record(outfit).merge," qty=",sim.quantity(outfit)," hp=",sim.stats().hp)
    return true

func _press_merge_all(id: String) -> void:
    var before:=int(sim.record(id).merge)
    var label:=tr("MERGE_ALL") % mini(sim.quantity(id)-1,sim.merge_cap(id)-before)
    var hp_before: float=sim.stats().hp
    for b in game.rows.find_children("*","Button",true,false):
        if str(b.text)==label and b.visible and not b.disabled:
            b.pressed.emit()
            print(LOG,"MERGE_ALL '",label,"' ",id," ^",before," -> ^",int(sim.record(id).merge)," hp ",hp_before," -> ",sim.stats().hp," t=",clock)
            return
    print(LOG,"MERGE_ALL MISSING t=",clock)

## Seasonal farming (options.stage): the player at the densest normal pack of that map (or beside
## options.near), auto-attacks, auto-cast skills and Auto-Collect running, wearing options.wear.
func _trailer_farm() -> bool:
    var stage_id:=int(options.get("stage",6))
    if not _stage_profile(stage_id,int(options.get("level",150)),options.get("items",[]),options.get("wear",[]),int(options.get("seed",3203))):return false
    var normals: Array=sim.campaign.stage().groups.filter(func(x):return not sim.catalog.groups[x].boss)
    _farm_upgrades(normals,bool(options.get("auto_collect",true))) # Change 34: false keeps loot on the ground
    var best:=Vector2.ZERO;var most:=-1
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].boss or sim.is_helper(e):continue
        var at:=Vector2(e.home_x,e.home_y)
        var n:=0
        for o in sim.state.enemies:
            if not sim.catalog.groups[int(o.group)].boss and at.distance_to(Vector2(o.home_x,o.home_y))<=float(options.get("radius",150.0)):n+=1
        if n>most:most=n;best=at
    if options.has("near"):best=_spot_of(str(options.near))
    for e in sim.state.enemies:
        if best.distance_to(Vector2(e.home_x,e.home_y))<=260.0:sim.campaign.discover_spot(int(e.group),int(e.get("variant",2)))
    sim.campaign.reveal_circle(best,float(options.get("explored",420.0))) # fixture: the player has farmed here before
    _place_player(best+Vector2(float(options.get("dx",0)),float(options.get("dy",24))))
    var types: Array=[]
    for e in sim.state.enemies:
        if best.distance_to(sim.position_of(e))<=260.0 and not types.has(sim.catalog.groups[int(e.group)].id):types.append(sim.catalog.groups[int(e.group)].id)
    print(LOG,"farm spot ",best," enemies near=",most," types=",types)
    _advance(float(options.get("advance",1.0)))
    # Change 34 staging: skills used shortly before (real cooldowns still running), as boss_sunflower.
    var skill_at: Dictionary=options.get("skill_at",{})
    for key in skill_at:sim.state.skill_cooldowns[key]=float(skill_at[key])
    if not skill_at.is_empty():sim.spell_cast.connect(func(id,key,_p):if id=="player":print(LOG,"PLAYER_SKILL ",key," t=",clock))
    var pickups: Array=_pickups_near(200.0).map(func(d):return d.item)
    print(LOG,"farm drops near=",pickups)
    _hud_clean()
    return most>0

# ---------------------------------------------------------------- Change 44 match-cut experiment

## A genuine boss encounter for the match-cut experiment (marketing/match_cut/): a staged profile at
## options.stage wearing real drops, the player placed below options.boss (dx/dy from the boss, so the
## boss stands straight above in portrait) and the boss aggroed. The fight is the real simulation; as
## boss_sunflower, the only staging is a summon or skill cooldown moved to just before its real event.
## Every hit on an enemy is logged (HIT target t=) so cut frames can be chosen on real impacts.
func _match_boss() -> bool:
    if not _stage_profile(int(options.stage),int(options.get("level",200)),options.get("items",[]),options.get("wear",[]),int(options.get("seed",4401))):return false
    var boss:=_actor_of(str(options.boss))
    if boss.is_empty():push_error(LOG+"no boss "+str(options.boss));return false
    _farm_upgrades([int(boss.group)],false)
    sim.campaign.reveal_circle(Vector2(boss.home_x,boss.home_y),float(options.get("explored",360.0))) # fixture: walked here
    _place_player(sim.position_of(boss)+Vector2(float(options.get("dx",0)),float(options.get("dy",30))))
    boss.aggro=true
    if options.has("summon_in"):boss.summon_cd=float(options.summon_in)
    var skill_at: Dictionary=options.get("skill_at",{})
    for key in skill_at:sim.state.skill_cooldowns[key]=float(skill_at[key])
    sim.summon_warning.connect(func(id):print(LOG,"SUMMON_WARNING ",id," t=",clock))
    sim.summoned.connect(func(id,ids):print(LOG,"SUMMON ",id," helpers=",ids.size()," t=",clock))
    sim.spell_cast.connect(func(id,key,_p):if id=="player":print(LOG,"PLAYER_SKILL ",key," t=",clock))
    sim.feedback.connect(func(id,amount,healing):if not healing and id!="player":print(LOG,"HIT ",id," ",snappedf(amount,1.0)," t=",clock))
    _advance(float(options.get("advance",0.0)))
    print(LOG,"match boss ",options.boss," hp=",float(boss.hp)/float(sim.enemy_definition(int(boss.group)).hp)," weapon=",sim.state.weapon," outfit=",sim.state.outfit)
    _hud_clean()
    return true

# ---------------------------------------------------------------- Change 34 store screenshots

## 02 (Summer II, rain): the gear an enemy carries is the gear it drops. A player in the plain body with
## a Wood Sword defeats the Teal Dinosaur in the real simulation; the kill rolls its two loot items (the
## seed is chosen so this kill drops both, never forced: a missing drop fails the scenario). The player
## taps both drops (sim.collect) and wears them (sim.equip, what the item panel's Equip calls). Then the
## boss's own 60 s respawn runs in the simulation and the player, now dressed as it, fights it again:
## the frame shows the boss and the same outfit and Iron Sword on the player.
## options.seed_search > 1 is a development aid: the seeds seed .. seed+n-1 are played in turn and
## the first whose kill drops both items is kept (logged; the manifest then pins that seed).
func _shot_gear() -> bool:
    var first:=int(options.get("seed",3401))
    for s in range(first,first+maxi(1,int(options.get("seed_search",1)))):
        var r:=_shot_gear_seed(s)
        if r!=0:
            print(LOG,"GEAR seed ",s," ok=",r>0)
            return r>0
    return false

## 1: staged; -1: failed; 0: this seed's kill did not drop both items.
func _shot_gear_seed(seed_value: int) -> int:
    var weapon:=str(options.get("weapon","wood_sword"))
    if not _stage_profile(4,int(options.get("level",200)),[[weapon,int(options.get("weapon_merge",100))]],[weapon],seed_value):return -1
    var boss:=_actor_of("boss-teal-dinosaur")
    if boss.is_empty():
        push_error(LOG+"no teal dinosaur");return -1
    _farm_upgrades([int(boss.group)],false)
    var home:=Vector2(boss.home_x,boss.home_y)
    sim.campaign.reveal_circle(home,float(options.get("explored",320.0))) # fixture: walked here
    _place_player(sim.position_of(boss)+Vector2(30,10))
    boss.aggro=true
    var def: Dictionary=sim.enemy_definition(int(boss.group))
    var t:=0.0
    while t<240.0 and float(boss.hp)>0 and sim.state.player.hp>0:
        sim.step(.05);t+=.05
    var drops: Array=sim.state.pickups.filter(func(d):return int(d.group)==int(boss.group))
    print(LOG,"GEAR first kill ",t,"s defeated=",float(boss.hp)<=0," loot=",def.loot," drops=",drops.map(func(d):return d.item))
    var dropped: Array=drops.map(func(d):return str(d.item))
    for id in def.loot:
        if not dropped.has(id):
            print(LOG,"GEAR drop missing ",id);return 0
    for id in def.loot:
        for d in drops:
            if str(d.item)==id:
                print(LOG,"GEAR collect ",id," ok=",sim.collect(int(d.uid)));break
        if not sim.equip(id):
            push_error(LOG+"cannot wear "+id);return -1
    print(LOG,"GEAR worn weapon=",sim.state.weapon," outfit=",sim.state.outfit," boss_body=",def.body," boss_weapon=",def.weapon)
    # The boss's real respawn: time passes in the simulation while the player waits nearby.
    _place_player(home+Vector2(0,float(options.get("wait_dy",140))))
    t=0.0
    while t<90.0 and float(boss.hp)<=0:
        sim.step(.05);t+=.05
    sim.state.player.hp=sim.stats().hp # fixture: rested back to full before the rematch
    print(LOG,"GEAR respawn after ",t,"s alive=",float(boss.hp)>0)
    if float(boss.hp)<=0:return -1
    _place_player(sim.position_of(boss)+Vector2(float(options.get("dx",0)),float(options.get("dy",34))))
    boss.aggro=true
    _advance(float(options.get("fight",1.0)))
    print(LOG,"GEAR rematch boss=",float(boss.hp)/float(def.hp)," player=",sim.state.player.hp/sim.stats().hp)
    _hud_clean()
    return 1 if float(boss.hp)>0 and sim.state.player.hp>0 else -1

## 03 (options.stage, default Winter II): `copies` spare copies of a worn item (fixture: picked up
## from earlier kills of its owner), the player at a pack of that map. The shot taps the item's tile
## and then the item panel's own "Merge N spare copies" button, so its ^level and stat rise for real.
func _shot_merge() -> bool:
    var item:=str(options.get("item","boss-cyan-robot_outfit"))
    if not _stage_profile(int(options.get("stage",2)),int(options.get("level",60)),options.get("items",[]),options.get("wear",[]),int(options.get("seed",3403))):return false
    if not sim.add_item(item,int(options.get("copies",30)),true,false):return false
    if options.has("near"):
        var spot:=_spot_of(str(options.near))
        sim.campaign.reveal_circle(spot,float(options.get("explored",320.0)))
        _place_player(spot+Vector2(float(options.get("dx",0)),float(options.get("dy",40))))
    _advance(float(options.get("advance",0.0)))
    _hud_clean()
    timeline.append([float(options.get("open_at",0.2)),func():_tap_gear(item)])
    if options.has("merge_at"):timeline.append([float(options.merge_at),func():_press_merge_all(item)])
    print(LOG,"merge item ",item," level=",sim.record(item).merge," qty=",sim.quantity(item))
    return true

## 05: exploring a map in this run. The earlier maps are cleared; this one is explored only along
## options.route (world points the player walked, each step revealed with options.reveal radius, the
## same circles the player's own vision reveals), the player at the route's end, at the fog's edge.
## options.camps lists the camps of this map the player owns.
func _shot_explore() -> bool:
    var stage_id:=int(options.get("stage",3))
    if not _stage_profile(stage_id,int(options.get("level",80)),options.get("items",[]),options.get("wear",[]),int(options.get("seed",3405))):return false
    var route: Array=options.get("route",[])
    var prev:=Vector2.ZERO
    for i in range(route.size()):
        var p:=Vector2(route[i][0],route[i][1])
        var steps:=1 if i==0 else maxi(1,ceili(prev.distance_to(p)/20.0))
        for k in range(1,steps+1):sim.campaign.reveal_circle(prev.lerp(p,float(k)/steps) if i>0 else p,float(options.get("reveal",110.0)))
        prev=p
    sim.state.camps[str(stage_id)]=options.get("camps",[0])
    if not route.is_empty():_place_player(prev)
    sim.campaign.identify_sites()
    _advance(float(options.get("advance",0.5)))
    _hud_clean()
    if options.has("panel"):timeline.append([float(options.get("open_at",0.2)),func():game._open(str(options.panel))])
    print(LOG,"explore stage ",stage_id," explored=",sim.campaign.explored_percent(stage_id),"% camps=",sim.state.camps[str(stage_id)])
    return true

## 06: the Prestige card choice. The late-game profile (one Prestige already redeemed) at
## options.stage; its ready opportunities are redeemed through the game's own begin_prestige (what the
## confirm dialog's button runs) and the panel offers the first batch card; options.pick taps one
## offered card (selected, not yet kept).
func _shot_prestige() -> bool:
    if not _late_profile(int(options.get("seed",3406))):return false
    if options.has("near"):
        if not _farm_at(str(options.near),Vector2(float(options.get("dx",0)),float(options.get("dy",40))),false):return false
    _advance(float(options.get("advance",0.0)))
    # options.boss_history: bosses defeated before (how a challenge opportunity is discovered);
    # options.challenges: of those, the ones this run defeated with no supply used (the counter
    # campaign.killed writes).
    for boss_id in options.get("boss_history",[]):_history_kills(str(boss_id),1)
    sim.campaign.evaluate()
    for boss_id in options.get("challenges",[]):sim.campaign.progress("restricted",str(boss_id),1)
    for i in range(2):sim.campaign.evaluate()
    _hud_clean()
    var why: String=sim.campaign.prestige_block_reason()
    if not why.is_empty():
        print(LOG,"prestige blocked: ",why);return false
    if not sim.campaign.begin_prestige():return false
    # options.path: the earlier choices of the batch are kept (their first card, as the Keep button
    # does through sim.prestige) until the batch reaches that path's opportunity.
    var target:=str(options.get("path",""))
    while target!="":
        var batch: Dictionary=sim.state.prestige_batch
        var index: int=batch.choices.size()
        if index>=batch.ids.size()-1 or str(game._opportunity(batch.ids[index]).path)==target:break
        var kept: String=sim.campaign.offered_cards()[0]
        print(LOG,"PRESTIGE keep ",kept," for ",batch.ids[index]," ok=",sim.prestige(kept))
    var offered: Array=sim.campaign.offered_cards()
    print(LOG,"PRESTIGE batch=",sim.state.prestige_batch.ids," offered=",offered," owned=",sim.state.owned_cards)
    game._open("prestige")
    var pick:=int(options.get("pick",-1))
    if pick>=0 and pick<offered.size():
        timeline.append([float(options.get("pick_at",0.3)),func():
            game.selected_card=offered[pick];game._refresh_panel(true)
            print(LOG,"PRESTIGE card selected ",offered[pick])])
    return true
