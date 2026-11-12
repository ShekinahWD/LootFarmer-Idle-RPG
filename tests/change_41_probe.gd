extends "res://tests/change_20_probe.gd"
## Change 41 playtest corrections:
## 1. Collection contracts ask for their true requirement (21 / 31 / 41: the copies handed in plus the one
##    kept) on every surface, and Submit accepts exactly that (the reported 20-of-20 case).
## 2. Focus Farming: the focused type first, then an enemy actively attacking the player, else the spot;
##    never a bystander, and the focus regains priority when a focused enemy is eligible again.
## 3. Joystick position Left / Center / Right: placement in the bottom map band, persistence, settings
##    survive Hard Reset, live move, touch on the stick versus the map.
## 4. The mode chooser cards and the Guided movement lesson framing the real joystick at each position.
## 5. Equipment drops: arrival presentation only (no state, RNG or pickup change, collectible at once).
## 6. Settings → Discord opens the exact invite once, fails gracefully, no Community section.
## Runs with --first-run-complete.
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    SettingsState.set_joystick_position(1)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    collection_checks()
    await collection_ui_checks()
    focus_checks()
    await joystick_checks()
    await chooser_checks()
    await lesson_checks()
    await drop_checks()
    await discord_checks()
    await localization_checks()
    SettingsState.set_joystick_position(1)
    print("CHANGE_41_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

# ---------------------------------------------------------------- 1. Prestige collection
## A discovered Winter collection with nothing credited yet (what evaluate() creates on discovery).
func contract(n:=1) -> String:
    var id:="collection_o%d" % n
    sim.state.opportunities[id]={"ready":false,"baseline":sim.state.counters.duplicate(true),"step":0,"count":0}
    return id
func outfits(n:=1) -> Array:
    return sim.campaign.collection_names(n).map(func(name_)->String:return sim.campaign.contract_outfit(name_))
## Picks up copies through the real ground-loot path (pickup + collect), as a player does.
func pick_up(item: String,copies: int) -> void:
    for i in range(copies):
        sim.state.next_pickup+=1
        sim.state.pickups.append({"uid":sim.state.next_pickup,"item":item,"x":sim.state.player.x,"y":sim.state.player.y,"ttl":300.0,"group":0})
        sim.collect(int(sim.state.next_pickup))
func roomy() -> void:
    sim.state.upgrades["gear_slots"]=9;sim.state.gear.resize(12);sim.state.gear.fill("")

func collection_checks() -> void:
    var c=sim.campaign
    check([c.collection_goal(1),c.collection_goal(2),c.collection_goal(3)]==[20,30,40],"Submit still hands in 20 / 30 / 40 of each outfit")
    check([c.collection_required(1),c.collection_required(2),c.collection_required(3)]==[21,31,41],"Contracts ask for 21 / 31 / 41 (the hand-in plus the copy kept)")
    # The reported case: exactly the old displayed number (20 of each) is now shown as one short.
    fresh();roomy();var id:=contract()
    for item in outfits():pick_up(item,20)
    check(outfits().all(func(i):return sim.quantity(i)==20),"Fixture: 20 of each picked up through the real collect path")
    check(c.collection_counts(id)==[20,20,20],"20 of each reads 20/21, never 20/20: %s" % [c.collection_counts(id)])
    check(not c.collection_complete(id) and c.follow_steps_done(id)==0,"Not complete, no step announced as done")
    var line: String=c.follow_summary(id)
    check(line.contains("20/21") and not line.contains(tr("FOLLOW_COLLECTION_SUBMIT")),"The follower asks for the 21st copy up front: \"%s\"" % line.replace("\n"," / "))
    check(c.opportunity_progress(id).contains("20/21"),"The Prestige card lists 20/21")
    check(c.follow_focus(id)=={"item":outfits()[0]},"The tracker icon is the first outfit still short")
    check(not c.submit(id) and outfits().all(func(i):return sim.quantity(i)==20),"Submit refuses at 20 and takes nothing")
    # Exact count: the 21st copy of each makes it complete, Submit takes 20 and leaves one.
    for item in outfits():pick_up(item,1)
    check(c.collection_counts(id)==[21,21,21] and c.collection_complete(id) and c.follow_steps_done(id)==3,"21 of each: 21/21 everywhere, three steps done")
    check(c.follow_summary(id)==tr("FOLLOW_COLLECTION_SUBMIT"),"The follower says hand them in")
    check(c.submit(id),"Submit accepts exactly the displayed requirement")
    check(outfits().all(func(i):return sim.quantity(i)==1),"Each outfit keeps one copy")
    check(bool(sim.state.opportunities[id].ready) and c.ready_ids().has(id),"The contract is ready for Prestige")
    # One short on a single outfit.
    fresh();roomy();id=contract()
    var items:=outfits()
    pick_up(items[0],21);pick_up(items[1],21);pick_up(items[2],20)
    check(c.collection_counts(id)==[21,21,20] and not c.collection_complete(id),"One short on the third outfit: 21, 21, 20")
    check(c.follow_focus(id)=={"item":items[2]} and c.follow_steps_done(id)==2,"The tracker moves to the outfit still short; two steps done")
    check(not c.submit(id) and sim.quantity(items[0])==21,"Submit refuses one short and spends nothing")
    # One over: counts cap at the requirement, Submit takes 20 and leaves two.
    pick_up(items[2],2)
    check(c.collection_counts(id)==[21,21,21],"Counts never exceed the requirement")
    pick_up(items[0],1)
    check(c.submit(id) and sim.quantity(items[0])==2 and sim.quantity(items[1])==1 and sim.quantity(items[2])==2,"One over: two copies stay")
    # A copy owned before the contract was discovered is the kept copy (the rule Submit always had).
    fresh();roomy()
    for item in outfits():sim.add_item(item,1,false,false)
    id=contract()
    check(c.collection_counts(id)==[1,1,1],"An older copy already counts as the one kept")
    for item in outfits():pick_up(item,20)
    check(c.collection_complete(id) and c.submit(id) and outfits().all(func(i):return sim.quantity(i)==1),"Older copy + 20 picked up: complete; it is the copy left")
    # The equipped last copy is never handed in.
    fresh();roomy();id=contract()
    for item in outfits():pick_up(item,21)
    check(sim.equip(items[0]) and sim.state.outfit==items[0],"Fixture: Blue Cap outfit equipped")
    check(c.submit(id) and sim.quantity(items[0])==1 and sim.state.outfit==items[0],"Submit leaves the worn copy worn")
    # Spent copies lower the count on every surface at once (a merge spends one).
    fresh();roomy();id=contract()
    for item in outfits():pick_up(item,21)
    check(sim.merge(items[1]),"Fixture: one Red Scarf copy merged")
    check(c.collection_counts(id)==[21,20,21] and c.follow_steps_done(id)==2 and not c.submit(id),"A merged copy is no longer counted: 20/21, Submit refuses")
    # Save and reload keep the counts (they are derived, nothing new is saved).
    fresh();roomy();id=contract()
    for item in outfits():pick_up(item,20)
    check(SaveService.save_now(),"Saved one short")
    SaveService.load_and_apply()
    check(sim.campaign.collection_counts(id)==[20,20,20] and not sim.campaign.collection_complete(id),"Reloaded: still 20/21")
    for item in outfits():pick_up(item,1)
    check(sim.campaign.submit(id) and SaveService.save_now(),"Submitted and saved")
    SaveService.load_and_apply()
    check(bool(sim.state.opportunities[id].ready) and outfits().all(func(i):return sim.quantity(i)==1),"Reloaded after Submit: ready, one copy each")
    # Summer and Spring use the same rule.
    for n in [2,3]:
        fresh();roomy();id=contract(n)
        for item in outfits(n):pick_up(item,c.collection_goal(n))
        check(not c.collection_complete(id) and c.collection_counts(id).all(func(v):return v==c.collection_goal(n)),"Collection %d: %d picked up reads %d/%d" % [n,c.collection_goal(n),c.collection_goal(n),c.collection_required(n)])
        for item in outfits(n):pick_up(item,1)
        check(c.submit(id) and outfits(n).all(func(i):return sim.quantity(i)==1),"Collection %d: %d of each completes and keeps one" % [n,c.collection_required(n)])
    check(tr("CONTENT_COLLECTION_O1_DESCRIPTION").contains("21") and tr("CONTENT_COLLECTION_O2_DESCRIPTION").contains("31") and tr("CONTENT_COLLECTION_O3_DESCRIPTION").contains("41"),"Descriptions ask for 21 / 31 / 41")

func collection_ui_checks() -> void:
    fresh();roomy();var id:=contract()
    for item in outfits():pick_up(item,20)
    sim.state.follow=id
    game._refresh_follow_tracker();await frames(2)
    var step: Label=game.get_node("Safe/Layout/Map/FollowTracker/Row/Text/Step")
    check(game.get_node("Safe/Layout/Map/FollowTracker").visible and step.text.contains("20/21"),"HUD tracker: 20/21")
    game._open("prestige");await frames(8)
    var texts: Array=[]
    for node in game.rows.find_children("*","Label",true,false):texts.append(str(node.text))
    check(texts.any(func(t):return t.contains("20/21")) and not texts.any(func(t):return t.contains("/20")),"Prestige panel: every collection count is out of 21")
    game._close()

# ---------------------------------------------------------------- 2. Focus Farming
var focused:=-1
var focused_variant:=2
var stranger:=-1
## A Focus on one Winter II normal type (Winter I enemies are all passive), reached by the real camp
## travel, and an aggressive stranger type on the same map.
func focus_scene() -> void:
    fresh()
    sim.state.unlocked_stage=2;sim.state.camps["2"]=[0]
    check(sim.campaign.camp_action(2,0,true) and int(sim.state.stage)==2,"Fixture: travelled to Winter II")
    sim.state.player.hp=sim.stats().hp
    var groups: Array=sim.campaign.stage().groups.filter(func(g):return not sim.catalog.groups[g].boss)
    focused=-1;stranger=-1
    for g in groups:
        if focused<0 and sim.state.enemies.any(func(e):return int(e.group)==g):focused=g
        elif stranger<0 and str(sim.catalog.groups[g].aggro_mode)!="passive" and sim.state.enemies.any(func(e):return int(e.group)==g):stranger=g
    for e in sim.state.enemies:
        if int(e.group)==focused:focused_variant=int(e.get("variant",2));break
    sim.campaign.discover_spot(focused,focused_variant)
    sim.state.upgrades["focus"]=1 # Change 65: one global unlock
    check(sim.focus(focused,focused_variant) and int(sim.state.focus)==focused,"Fixture: Focus on one type")
    sim.movement=Vector2.ZERO
    sim.clear_target()
## Every enemy dead and parked, except those the case moves next to the player.
func park_all() -> void:
    for e in sim.state.enemies:
        e.hp=0;e.respawn=9999.0;e.aggro=false;e.returning=false
func place(group: int,offset: Vector2,aggro: bool,variant:=-1) -> Dictionary:
    for e in sim.state.enemies:
        if int(e.group)==group and float(e.hp)<=0 and (variant<0 or int(e.get("variant",2))==variant):
            var at: Vector2=sim.position_of(sim.state.player)+offset
            e.hp=float(sim.enemy_definition(group,int(e.get("variant",2))).hp);e.respawn=0.0;e.dead_age=0.0
            e.x=at.x;e.y=at.y;e.home_x=at.x;e.home_y=at.y;e.aggro=aggro;e.returning=false;e.windup=0.0
            sim.campaign.reveal_circle(at,60)
            return e
    return {}

func focus_checks() -> void:
    focus_scene()
    check(focused>=0 and stranger>=0,"Fixture: a focused type and an aggressive stranger type on Winter II")
    var reach: float=float(sim.catalog.world.acquisition)
    # Priority 1: an eligible focused enemy beats an attacker.
    park_all()
    var mark:=place(focused,Vector2(60,0),false,focused_variant)
    var attacker:=place(stranger,Vector2(-30,0),true)
    check(not mark.is_empty() and not attacker.is_empty(),"Fixture: a focused enemy and an attacker beside the player")
    check(sim.threatens_player(attacker) and not sim.threatens_player(mark),"Threat = aggro and not leashing; a calm enemy is not one")
    check(sim._combat_target().id==mark.id,"1) The focused enemy comes first, even with a closer attacker")
    check(sim.campaign.skill_activation_target().id==mark.id or sim.position_of(mark).distance_to(sim.position_of(sim.state.player))>sim.campaign.skill_activation_distance(),"Skills follow the same priority")
    # Priority 2: no focused enemy eligible (dead, respawning) -> the attacker.
    mark.hp=0;mark.respawn=30.0;sim.clear_target()
    check(sim._combat_target().id==attacker.id,"2) Focused enemies respawning: the hero fights the enemy attacking it")
    check(sim.campaign.skill_activation_target().id==attacker.id,"…and skills target that attacker too")
    # A bystander (not attacking) is never chosen under a Focus.
    attacker.aggro=false;sim.clear_target()
    check(sim._combat_target().is_empty() and sim.campaign.skill_activation_target().is_empty(),"3) A calm stranger is ignored: no target, the hero returns to the spot")
    # A leashing attacker (returning home) is no longer a threat.
    attacker.aggro=true;attacker.returning=true;sim.clear_target()
    check(sim._combat_target().is_empty(),"An enemy leashing home is not chased")
    attacker.returning=false
    # An attacker outside acquisition is not chased across the map.
    attacker.x=sim.state.player.x+reach+40;sim.clear_target()
    check(sim._combat_target().is_empty(),"An attacker beyond acquisition range is not chased")
    attacker.x=sim.state.player.x-30
    # Multiple attackers: the nearest; equal distance keeps roster order (deterministic).
    var second:=place(stranger,Vector2(0,24),true)
    sim.clear_target()
    check(not second.is_empty() and sim._combat_target().id==second.id,"Several attackers: the nearest one")
    second.x=sim.state.player.x+30;second.y=sim.state.player.y;sim.clear_target()
    var first_in_roster: String=attacker.id if sim.state.enemies.find(attacker)<sim.state.enemies.find(second) else second.id
    check(sim._combat_target().id==first_in_roster,"Equal distance: roster order decides")
    # Priority restoration: a focused enemy back in range takes over from a defensive lock.
    sim.clear_target();check(sim._combat_target().id!="","Defensive lock taken")
    mark.hp=float(sim.enemy_definition(focused,focused_variant).hp);mark.respawn=0.0
    check(sim._combat_target().id==mark.id,"The focused enemy regains priority as soon as it is eligible")
    # Manual targeting is the player's choice: it ends the Focus (unchanged) and keeps its target.
    check(sim.select_target(attacker.id) and int(sim.state.focus)<0 and sim._combat_target().id==attacker.id,"A manual target overrides and ends Focus Farming, as before")
    # Without a Focus nothing changed: the nearest visible enemy, attacking or not.
    focus_scene();sim.focus(focused,focused_variant)
    check(int(sim.state.focus)<0,"Fixture: Focus turned off again")
    park_all();var calm:=place(stranger,Vector2(40,0),false);sim.clear_target()
    check(sim._combat_target().id==calm.id,"No Focus: the nearest enemy, as before")
    await_free_steps()

## The reported loop, stepped in the real simulation: aggro picked up on the way to the spot while the
## focused enemies are respawning. The hero fights back, then walks on to the spot; a calm stranger
## on the way is left alone.
func await_free_steps() -> void:
    focus_scene();park_all()
    var spot: Vector2=sim.farming_position()
    sim.state.player.x=spot.x+170;sim.state.player.y=spot.y
    sim.campaign.reveal_circle(sim.position_of(sim.state.player),140)
    var attacker:=place(stranger,Vector2(-20,0),true)
    attacker.hp=minf(float(attacker.hp),1.0)
    # Outside its aggro radius (58) but inside acquisition (110): visible, nearby and calm.
    var calm:=place(stranger,Vector2(0,90),false)
    calm.home_x=calm.x;calm.home_y=calm.y
    var hp_before: float=sim.state.player.hp
    var kills_before: int=int(sim.state.group_kills[stranger])
    var before:=-1.0
    for i in range(80):
        sim.step(.1)
        if before<0 and float(attacker.hp)<=0:before=sim.position_of(sim.state.player).distance_to(spot)
    check(before>=0 and int(sim.state.group_kills[stranger])==kills_before+1,"Stepped: the hero defeats the enemy that attacked it during travel")
    check(float(calm.hp)>0 and not bool(calm.aggro),"…and leaves the calm stranger alone")
    var after: float=sim.position_of(sim.state.player).distance_to(spot)
    check(before>100 and after<before-60 and int(sim.state.focus)==focused,"Then it walks on to the spot (%.0f -> %.0f) and Focus stays on" % [before,after])
    check(float(sim.state.player.hp)>0 and float(sim.state.player.hp)>=hp_before*.3,"No helpless damage loop (HP %.0f of %.0f)" % [sim.state.player.hp,hp_before])

# ---------------------------------------------------------------- 3. Joystick position
func joystick_checks() -> void:
    fresh();sim.state.tutorial.seen.append("road_ahead")
    var map: Control=game.get_node("Safe/Layout/Map")
    var stick: Control=game.stick
    check(SettingsState.joystick_position==1,"Default: Center")
    var rects: Array=[]
    for position in [0,1,2]:
        SettingsState.set_joystick_position(position);await frames(3)
        var r: Rect2=stick.get_global_rect();var m: Rect2=map.get_global_rect()
        rects.append(r)
        check(m.encloses(r),"%s: inside the map band" % stick.POSITIONS[position])
        check(is_equal_approx(r.end.y,m.end.y-stick.bottom_margin) and r.size==stick.custom_minimum_size,"%s: same height and size at the bottom" % stick.POSITIONS[position])
        var expected_x: float=[m.position.x+stick.edge_margin,m.get_center().x-r.size.x*.5,m.end.x-stick.edge_margin-r.size.x][position]
        check(absf(r.position.x-expected_x)<1.0,"%s: x %.0f (expected %.0f)" % [stick.POSITIONS[position],r.position.x,expected_x])
        check(not r.intersects(game.get_node("Safe/Layout/Skills").get_global_rect()) and not r.intersects(game.dock.get_global_rect()),"%s: clear of the skill bar and dock" % stick.POSITIONS[position])
    check(rects[0].position.x<rects[1].position.x and rects[1].position.x<rects[2].position.x,"Left < Center < Right")
    # Trackers stay above the joystick wherever it is.
    var id:=contract();sim.state.follow=id;sim.state.follow_mission="main:0";sim.touch()
    for position in [0,2]:
        SettingsState.set_joystick_position(position);await frames(4)
        game._refresh_follow_tracker();game._refresh_mission_tracker();game._layout_trackers()
        var tracker: Control=game.get_node("Safe/Layout/Map/FollowTracker")
        # Change 71: above the joystick when it shares the trackers' column, else down to the map's bottom margin.
        check(tracker.visible and not tracker.get_global_rect().intersects(stick.get_global_rect()),"%s: the followed tracker is clear of the joystick" % stick.POSITIONS[position])
    sim.state.follow="";sim.state.follow_mission=""
    # Persistence: saved with the settings, kept by Hard Reset, older saves default to Center.
    SettingsState.set_joystick_position(0)
    check(SaveService.save_now(),"Saved with Left")
    SettingsState.joystick_position=2;SaveService.load_and_apply();await frames(2)
    check(SettingsState.joystick_position==0 and stick.slot==0,"Reload restores Left and places the stick")
    check(SaveService.hard_reset() and SettingsState.joystick_position==0,"Hard Reset keeps the joystick position with the other settings")
    SettingsState.from_save_dict({});check(SettingsState.joystick_position==1,"A save without the setting: Center")
    SettingsState.from_save_dict({"joystick_position":"left"});check(SettingsState.joystick_position==1,"A malformed value: Center")
    SettingsState.from_save_dict({"joystick_position":7});check(SettingsState.joystick_position==2,"Out of range: clamped")
    fresh();sim.state.tutorial.seen.append("road_ahead")
    # Settings row: three choices, the current one highlighted, a press moves the stick at once.
    SettingsState.set_joystick_position(1)
    game._open("settings");await frames(8)
    for key in ["joystick_left","joystick_center","joystick_right"]:check(button(key)!=null,"Settings offers "+key)
    check(button("joystick_center").theme_type_variation==&"Primary","The current position is highlighted")
    button("joystick_right").pressed.emit();await frames(6)
    check(SettingsState.joystick_position==2 and stick.slot==2 and stick.anchor_left==1.0,"Right applies immediately")
    check(button("joystick_right")!=null and button("joystick_right").theme_type_variation==&"Primary","…and is highlighted after the refresh")
    game._close();await frames(2)
    # Touch: a press on the stick drives it and never starts a map gesture; with the stick on the
    # left, a press where the centre stick was belongs to the map.
    SettingsState.set_joystick_position(0);await frames(3)
    var surface=game.get_node("Safe/Layout/Map/GestureSurface")
    var c: Vector2=stick.get_global_rect().get_center()
    touch(c,true);drag(c+Vector2(-50,0),Vector2(-50,0));await frames(1)
    check(stick.pointer==0 and stick.direction.x<-.5 and surface.pointers.is_empty(),"A touch on the left stick moves it; the map never sees it")
    SettingsState.set_joystick_position(2);await frames(1)
    check(stick.pointer==-2 and stick.direction==Vector2.ZERO,"Moving the stick under a thumb releases it (no stuck direction)")
    touch(c+Vector2(-50,0),false);await frames(1)
    SettingsState.set_joystick_position(0);await frames(3)
    var old_center: Vector2=Vector2(map.get_global_rect().get_center().x,stick.get_global_rect().get_center().y)
    touch(old_center,true);await frames(1)
    check(stick.pointer==-2 and not surface.pointers.is_empty(),"With the stick on the left, the old centre spot is map (pan/target) again")
    touch(old_center,false);await frames(1)
    surface.cancel_gesture()
    SettingsState.set_joystick_position(1);await frames(2)

func touch(point: Vector2,pressed: bool) -> void:
    var e:=InputEventScreenTouch.new();e.position=point;e.index=0;e.pressed=pressed
    get_viewport().push_input(e,true)
    var mouse:=InputEventMouseButton.new();mouse.device=InputEvent.DEVICE_ID_EMULATION;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=point;mouse.pressed=pressed
    get_viewport().push_input(mouse,true)
func drag(point: Vector2,relative: Vector2) -> void:
    var e:=InputEventScreenDrag.new();e.index=0;e.position=point;e.relative=relative
    get_viewport().push_input(e,true)

# ---------------------------------------------------------------- 4. Chooser and movement lesson
func chooser_checks() -> void:
    for size in [Vector2i(720,1280),Vector2i(576,1280),Vector2i(1024,1366)]:
        get_window().size=size
        fresh("pending");sim.state.tutorial.seen=[];sim.suspended=true
        await frames(16)
        var guide=game.guide
        var buttons: Array=guide.chooser_heading.get_parent().get_children().filter(func(n):return n is Button)
        check(buttons.size()==3 and buttons.map(func(b):return str(b.get_meta("mode")))==["guided","basic","none"],"%s: three mode cards in order" % size)
        check(guide.chooser.modulate.a==1.0 and game.get_global_rect().encloses(guide.chooser.get_global_rect()),"%s: chooser shown at its settled size, on screen" % size)
        for b in buttons:
            var title: Label=b.get_node("Row/Text/Title");var detail: Label=b.get_node("Row/Text/Detail")
            check(b.size.y>=guide.MODE_MIN_HEIGHT and b.size.y>=76 and guide.chooser.get_global_rect().encloses(b.get_global_rect()),"%s %s: card %.0f px tall, inside the chooser" % [size,b.get_meta("mode"),b.size.y])
            check(title.text!="" and detail.text!="" and detail.get_line_count()<=3 and b.get_global_rect().encloses(detail.get_global_rect().grow(-1)),"%s %s: name and detail fit (%d lines)" % [size,b.get_meta("mode"),detail.get_line_count()])
            check(b.get_node("Row").mouse_filter==Control.MOUSE_FILTER_IGNORE and title.mouse_filter==Control.MOUSE_FILTER_IGNORE,"%s %s: the whole card is the touch target" % [size,b.get_meta("mode")])
        check(buttons[0].theme_type_variation==&"Primary" and buttons[2].theme_type_variation!=&"Primary","Guided is the highlighted beginner card; None is not")
    get_window().size=Vector2i(720,1280);await frames(4)
    # Each card still chooses exactly its mode.
    for mode in ["guided","basic","none"]:
        fresh("pending");sim.state.tutorial.seen=[];sim.suspended=true;await frames(6)
        var card: Button=game.guide.chooser.find_child("Mode_"+mode,true,false)
        card.pressed.emit();await frames(2)
        check(str(sim.state.tutorial.mode)==mode and not game.guide.chooser.visible and not sim.suspended,"The %s card chooses %s" % [mode,mode])

func lesson_checks() -> void:
    var guide=game.guide
    var stick: Control=game.stick
    for position in [1,0,2]:
        SettingsState.set_joystick_position(position)
        fresh("pending");sim.state.tutorial.seen=[];sim.suspended=true;await frames(4)
        guide.choose("guided");await frames(8)
        var r: Rect2=stick.get_global_rect()
        check(guide.step=="move" and guide.path_point!=Vector2.INF,"%s: Guided starts on the movement lesson along the path" % stick.POSITIONS[position])
        check(guide.highlight.visible and Rect2(guide.highlight.position,guide.highlight.size).encloses(r),"%s: the real joystick is framed" % stick.POSITIONS[position])
        check(guide.stick_demo.visible and guide.stick_rect.is_equal_approx(r) and guide.stick_direction.x<0,"%s: the ghost knob plays on the stick, toward the path (left)" % stick.POSITIONS[position])
        check(guide.pointer.visible,"%s: the path arrow still shows beside the hero" % stick.POSITIONS[position])
        check(guide.stick_demo.mouse_filter==Control.MOUSE_FILTER_IGNORE and guide.highlight.mouse_filter==Control.MOUSE_FILTER_IGNORE,"%s: the guidance takes no input" % stick.POSITIONS[position])
    # The frame follows a change made during the lesson.
    SettingsState.set_joystick_position(0);await frames(3)
    check(Rect2(guide.highlight.position,guide.highlight.size).encloses(stick.get_global_rect()) and guide.stick_rect.is_equal_approx(stick.get_global_rect()),"Moving the stick mid-lesson moves the frame and demo with it")
    # A thumb on the stick: the demo steps aside.
    var c: Vector2=stick.get_global_rect().get_center()
    touch(c,true);await frames(2)
    check(not guide.stick_demo.visible,"While the player holds the stick, the demo hides")
    touch(c,false);await frames(2)
    # Done by walking the path (the lesson's real completion), the emphasis is gone for good.
    var rules=sim.campaign.onboarding.rules
    sim.state.player.x=rules.path_target.x;sim.state.player.y=rules.path_target.y;await frames(4)
    check(guide.step!="move" and not guide.stick_demo.visible,"After the movement lesson no joystick emphasis remains (step now %s)" % guide.step)
    # Basic and None never frame it (they never point); the Basic card names the joystick.
    for mode in ["basic","none"]:
        fresh("pending");sim.state.tutorial.seen=[];sim.suspended=true;await frames(4)
        guide.choose(mode);await frames(6)
        check(not guide.stick_demo.visible and not guide.highlight.visible,"%s: no joystick pointer" % mode)
    check(tr("GUIDE_OVERVIEW_DETAIL").contains("joystick") and tr("GUIDE_OVERVIEW_DETAIL").contains("bottom of the map"),"The Basic (and Help) card says where the joystick is")
    SettingsState.set_joystick_position(1)

# ---------------------------------------------------------------- 5. Drops
func drop_checks() -> void:
    fresh();sim.state.tutorial.seen.append("road_ahead");await frames(2)
    var style: Resource=preload("res://resources/game/pickup_style.tres")
    check(style.hop_seconds>0 and style.hop_seconds<=.5,"The arrival is short (%.2f s)" % style.hop_seconds)
    var foe: Dictionary={}
    for e in sim.state.enemies:
        if not sim.catalog.groups[int(e.group)].boss:foe=e;break
    foe.x=sim.state.player.x+30;foe.y=sim.state.player.y
    sim.campaign.reveal_circle(sim.position_of(foe),60)
    var def: Dictionary=sim.enemy_definition(int(foe.group),int(foe.get("variant",2)))
    var weapon: String=""
    for id in def.loot:
        if sim.catalog.items[id].kind in ["weapon","outfit"]:weapon=id;break
    var rng_state: int=sim.rng.state
    sim.state.pickups.clear()
    sim._drop(weapon,foe);sim._drop("potion",foe)
    var snapshot: Array=sim.state.pickups.duplicate(true)
    rng_state=sim.rng.state
    await frames(1)
    var nodes: Dictionary=game.world.pickups
    var gear_node=nodes[int(snapshot[0].uid)];var supply_node=nodes[int(snapshot[1].uid)]
    check(gear_node.gear and not supply_node.gear,"Equipment and supplies are told apart")
    check(gear_node.age<style.hop_seconds and gear_node.z_index==(2 if style.hop_above_actors else 0),"A new drop arrives (hop, drawn above the defeated enemy)")
    var icon_size: float=gear_node.get_node("Icon").texture.get_width()*gear_node.base_scale.x
    check(is_equal_approx(maxf(gear_node.get_node("Icon").texture.get_width(),gear_node.get_node("Icon").texture.get_height())*gear_node.base_scale.x,style.gear_size),"Equipment renders at %.0f px" % style.gear_size)
    check(sim.state.pickups==snapshot and sim.rng.state==rng_state,"Presentation changes no pickup and draws no random number")
    for i in range(30):gear_node._process(.02);supply_node._process(.02)
    check(gear_node.age>=style.hop_seconds and gear_node.z_index==0 and gear_node.get_node("Icon").position==Vector2.ZERO,"After the hop it rests on its real spot, beneath the actors")
    check(gear_node.position==Vector2(snapshot[0].x,snapshot[0].y),"The drop is drawn exactly where the simulation put it")
    check(nodes[int(snapshot[0].uid)].phase!=nodes[int(snapshot[1].uid)].phase,"Each drop sparkles at its own phase")
    # Collectible at once, mid-arrival.
    sim._drop(weapon,foe);await frames(1)
    var uid: int=int(sim.state.pickups[-1].uid)
    check(game.world.pickups[uid].age<style.hop_seconds and sim.collect(uid),"A drop can be collected during its arrival")
    await frames(2)
    check(not game.world.pickups.has(uid),"…and its view leaves with it")
    # A drop already on the ground (a reload) does not hop again.
    sim.state.pickups.append({"uid":9999,"item":weapon,"x":foe.x,"y":foe.y,"ttl":120.0,"group":int(foe.group)})
    await frames(1)
    check(game.world.pickups[9999].age==INF and game.world.pickups[9999].z_index==0,"An older drop is simply there")
    sim.state.pickups.clear();await frames(1)

# ---------------------------------------------------------------- 6. Discord
func discord_checks() -> void:
    var links: Resource=preload("res://resources/game/external_links.tres")
    check(links.discord_url=="https://discord.gg/zbr9RH6QWa","The invite is the approved URL, defined once")
    var opened: Array=[]
    links.opener=func(url: String)->int:opened.append(url);return OK
    links.reset_guard()
    fresh();sim.state.tutorial.seen.append("road_ahead")
    game._open("settings");await frames(8)
    var before: Dictionary=sim.snapshot()
    var b:=button("discord")
    check(b!=null and b.text=="Discord" and b.is_visible_in_tree() and not b.disabled,"Settings shows one Discord button")
    check(b!=null and b.get_parent()==button("open_stats").get_parent(),"…directly in Settings, beside Stats (no section of its own)")
    var labels: Array=game.rows.find_children("*","Label",true,false).map(func(l):return str(l.text).to_lower())
    check(not labels.any(func(t):return t.contains("community")),"No Community heading")
    var count:=0
    for node in game.rows.find_children("*","Button",true,false):
        if node.text=="Discord":count+=1
    check(count==1,"Exactly one Discord button")
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    check(scroll.get_global_rect().encloses(b.get_global_rect()),"Reachable without scrolling at 720x1280")
    b.pressed.emit();b.pressed.emit();await frames(1)
    check(opened==["https://discord.gg/zbr9RH6QWa"],"One press opens the exact URL; an immediate second press opens nothing")
    links.reset_guard();game.toast_queue.clear()
    links.opener=func(_url: String)->int:return ERR_CANT_OPEN
    b.pressed.emit();await frames(2)
    check(game.notice.text==tr("LINK_OPEN_FAILED"),"A failed launch says so in the panel's notice line")
    check(game.sheet.visible and game.panel=="settings","…and Settings stays open")
    var after: Dictionary=sim.snapshot()
    for key in ["coins","gems","items","opportunities","tutorial","review"]:check(str(after[key])==str(before[key]),"Opening the link changes no game state: "+key)
    links.opener=func(url: String)->int:return OS.shell_open(url)
    links.reset_guard()
    game._close()

# ---------------------------------------------------------------- localization
func localization_checks() -> void:
    game._open("settings");await frames(6)
    check(LocalizationService.select_language("de_DE"),"German selectable")
    await frames(6)
    check(tr("JOYSTICK_POSITION")=="Joystick-Position" and tr("DISCORD")=="Discord","German: Joystick-Position; Discord stays Discord")
    game._close();await frames(2);game._open("settings");await frames(6)
    check(button("joystick_left")!=null and button("joystick_left").text=="Links" and button("discord").text=="Discord","Settings redrawn in German")
    for lang in LocalizationService.ENABLED_LANGUAGES:
        if lang=="en_US":continue
        var catalog: Dictionary=read_po("res://localization/%s.po" % lang)
        var missing: Array=["JOYSTICK_POSITION","JOYSTICK_LEFT","JOYSTICK_CENTER","JOYSTICK_RIGHT","DISCORD","LINK_OPEN_FAILED","GUIDE_CHOOSE_DETAIL","GUIDE_MODE_GUIDED_DETAIL","GUIDE_MODE_BASIC_DETAIL","GUIDE_MODE_NONE_DETAIL"].filter(func(k):return str(catalog.get(k,"")).strip_edges()=="")
        check(missing.is_empty() and catalog.DISCORD=="Discord" and catalog.CONTENT_COLLECTION_O1_DESCRIPTION.contains("21"),"%s: every Change 41 key translated, Discord kept, 21 in the Winter collection" % lang)
    LocalizationService.select_language("automatic");await frames(4)
    game._close()

static func read_po(path: String) -> Dictionary:
    var result: Dictionary={}
    var key:=""
    for line in FileAccess.get_file_as_string(path).split("\n"):
        if line.begins_with("msgid \""):key=line.substr(7,line.length()-8)
        elif line.begins_with("msgstr \"") and key!="":result[key]=line.substr(8,line.length()-9);key=""
    return result
