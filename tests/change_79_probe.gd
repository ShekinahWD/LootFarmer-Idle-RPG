extends Node
## Change 79 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## 1. Auto Farm return: after a respawn under a Focused Farming target the hero walks straight to the spot,
##    never targets, attacks, casts an attack skill or chases on the way (even while being hit), through
##    several deaths; arrival resumes Focus combat; stopping or changing the Focus, a manual target or a
##    travel ends the return; at the spot the hero does not chase a stranger away from it; a realistic
##    Summer II respawn reaches the spot (and the pre-fix rule demonstrably stopped to fight on the way).
## 2. Reroll Stats: one action rerolls every unlocked attribute; locks keep stat and value; additive price
##    (base x (1 + 0.2 regular + 0.4 boss)) for 0/1/several/all locks on weapons and outfits; all locked
##    blocks without charge; too few Gems change nothing; locks belong to one item and survive merges and a
##    disk reload; an old save without locks loads; the item panel shows one Reroll Stats with the exact price.
## 3. Followed objectives: the Mastery, mission and Prestige pills say the action and its target
##    ("Defeat Teal Dinosaur"), wrap without cutting text at 432 and 540 px, and keep clear of the HUD.
## 4. Offline Skills: locked grants none; unlocked grants copies of owned skills only (none without stock),
##    at the documented rate for several durations; one claim, no duplicate after reload; kept by Prestige,
##    cleared by Hard Reset; the Upgrades and Welcome back panels show it.
## Run: Godot --headless --path . res://tests/change_79_probe.tscn -- --probe --profile=probe-c79 --no-autosave --first-run-complete
var checks=0
var failures=0
var game
var sim

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(720,1280)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    auto_farm_checks()
    auto_farm_summer_checks()
    reroll_checks()
    await reroll_persistence_checks()
    await reroll_ui_checks()
    await tracker_checks()
    offline_checks()
    await offline_persistence_checks()
    await offline_ui_checks()
    boss_balance_checks()
    print("CHANGE_79_CHECKS %d FAILURES %d" % [checks,failures])
    sim.clock_override=-1.0
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func fresh() -> void:
    get_tree().paused=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    game._close();game._cancel_confirm()
    game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_important.clear();game.get_node("Toast").hide();game.toast_time=0.0

func gi(id: String) -> int:return sim.campaign.group_id(id)

## Moves the profile to `st` (fixture: stage reached), rebuilding its world.
func to_stage(st: int) -> void:
    sim.state.unlocked_stage=maxi(st,int(sim.state.unlocked_stage));sim.state.reward_stage=maxi(st,int(sim.state.reward_stage))
    sim.state.stage=st
    sim._reset_world()
    sim.campaign.reveal()

func own_focus() -> void:
    sim.state.gems=float(sim.state.gems)+float(sim.upgrade_cost("focus")) # fixture: Gems for the Focused Farming unlock
    sim.buy_upgrade("focus")

# ---------------------------------------------------------------- 1. Auto Farm return
## Kills the hero (fixture) and steps until the respawn. Returns true when it came back alive.
func die_and_respawn() -> bool:
    var p: Dictionary=sim.state.player
    p.hp=0.0;p.respawn=0.0
    for i in range(5):
        sim.step(.1)
        if float(p.hp)>0:return true
    return false

## Steps `seconds` while the return runs; records whether the hero ever targeted, swung or chased, its lowest
## HP, and when the return ended. Stops at the end of the return.
func watch_return(seconds: float) -> Dictionary:
    var p: Dictionary=sim.state.player
    var out={"engaged":false,"min_hp":float(p.hp),"arrived_at":-1.0,"hits_taken":0.0,"t":0.0}
    var t=0.0
    while t<seconds:
        var before=float(p.hp)
        sim.step(.1);t+=.1
        if float(p.hp)<before:out.hits_taken+=before-float(p.hp)
        out.min_hp=minf(out.min_hp,float(p.hp))
        if sim.focus_returning():
            if str(p.target)!="" or float(p.windup)>0 or sim.locked_target!="" or float(p.attack_age)<.11:out.engaged=true
        else:
            out.arrived_at=t
            break
    out.t=t
    return out

func auto_farm_checks() -> void:
    print("-- 1. Auto Farm: return to the spot after a respawn")
    fresh()
    own_focus()
    var g=gi("unit-blue-cap")
    sim.campaign.discover_spot(g,1) # fixture: spot found while exploring
    check(sim.focus(g,1),"Focused Farming on a found spot")
    var spot=sim.farming_position()
    # Enemies of another type lie in wait half way along the route, already attacking (fixture).
    var camp: Array=sim.campaign.stage().spawns[int(sim.state.spawn)]
    var mid=(Vector2(camp[0],camp[1])+spot)*.5
    var ambush: Array=[]
    var other=gi("unit-red-scarf")
    for e in sim.state.enemies:
        if int(e.group)==other and ambush.size()<3:
            e.x=mid.x+ambush.size()*10;e.y=mid.y;e.home_x=e.x;e.home_y=e.y;e.aggro=true;e.hp=1e6 # fixture: an aggressive ambush on the route
            ambush.append(e)
    sim.state.player_level=25 # fixture: level reached (a hero that outlasts a Winter I ambush)
    check(die_and_respawn(),"The hero dies and respawns at its camp")
    check(sim.focus_returning() and int(sim.state.focus)==g and int(sim.state.focus_variant)==1,"After the respawn the Focus (spot) is kept and the return starts")
    var w=watch_return(60.0)
    check(w.arrived_at>0,"The hero reaches the spot (%.1f s)" % float(w.arrived_at))
    check(not bool(w.engaged),"On the way it never targets, swings at or chases anything")
    check(float(w.hits_taken)>0,"…although the ambush hit it on the way (%.0f damage)" % float(w.hits_taken))
    check(sim.position_of(sim.state.player).distance_to(spot)<=sim.FOCUS_ARRIVE_RADIUS+.01,"It stands at the spot when the return ends")
    # At the spot: Focus combat resumes against the focused type.
    var focused=false
    for i in range(80):
        sim.step(.1)
        var t=sim._find_actor(str(sim.state.player.target))
        if not t.is_empty() and int(t.group)==g:focused=true;break
    check(focused,"Arrived, the hero attacks its focused type again")
    for e in ambush:e.hp=0.0;e.respawn=1e9 # fixture: the ambush is gone
    # Several deaths in a row: each respawn starts the return again.
    for n in range(3):
        check(die_and_respawn() and sim.focus_returning(),"Death %d: the return starts again" % (n+1))
        for i in range(10):sim.step(.1)
    w=watch_return(60.0)
    check(w.arrived_at>0 and not bool(w.engaged),"After several deaths the hero still walks straight to the spot")
    # Arrival tolerance: no oscillation once there (position steady while nothing attacks).
    for e in sim.state.enemies:
        if int(e.group)==g:e.hp=0.0;e.respawn=1e9 # fixture: the spot is empty
    var a=sim.position_of(sim.state.player)
    for i in range(30):sim.step(.1)
    check(sim.position_of(sim.state.player).distance_to(a)<=sim.FOCUS_ARRIVE_RADIUS+.5,"At the spot the hero stays put (no back-and-forth)")
    # Cancels.
    check(die_and_respawn() and sim.focus_returning(),"Return running again")
    check(sim.focus(g,1) and not sim.focus_returning() and int(sim.state.focus)<0,"Stopping Auto Farm ends the return")
    sim.focus(g,1)
    check(die_and_respawn() and sim.focus_returning(),"Return running again")
    sim.campaign.discover_spot(g,0)
    check(sim.focus(g,0) and not sim.focus_returning(),"Changing the destination ends the post-respawn return")
    check(die_and_respawn() and sim.focus_returning(),"Return running again")
    var target: Dictionary={}
    for e in sim.state.enemies:
        if e.hp>0 and sim.campaign.target_allowed(e):target=e;break
    if not target.is_empty():
        check(sim.select_target(str(target.id)) and not sim.focus_returning(),"Choosing a target by hand ends the return (and the Focus, as before)")
    sim.campaign.discover_spot(g,1);sim.focus(g,1)
    check(die_and_respawn() and sim.focus_returning(),"Return running again")
    sim.movement=Vector2.RIGHT
    var px=float(sim.state.player.x)
    for i in range(5):sim.step(.1)
    check(float(sim.state.player.x)>px+20 and sim.focus_returning(),"Manual walking moves the hero at once; the return resumes after it")
    sim.movement=Vector2.ZERO
    sim.state.camps[str(sim.state.stage)]=[0,1];sim.state.spawns=[0,1] # fixture: second camp owned
    for e in sim.state.enemies:e.aggro=false
    if sim.campaign.travel_reason(int(sim.state.stage),1)=="":
        check(sim.campaign.camp_action(int(sim.state.stage),1,true) and not sim.focus_returning(),"A Teleport ends the return (and the Focus, as before)")
    # Auto skills wait for the arrival, Heal excepted.
    fresh();own_focus()
    sim.campaign.discover_spot(g,1);sim.focus(g,1)
    sim.add_item("skill_fire",1);sim.add_item("skill_heal",1)
    sim.state.gems=1e6;sim.buy_upgrade("skill_slots");sim.buy_upgrade("skill_auto_slots");sim.buy_upgrade("skill_auto_slots")
    sim.campaign.equip_skill("skill_fire",0);sim.campaign.equip_skill("skill_heal",1)
    sim.assign_automatic_skills([0,1])
    die_and_respawn()
    for e in sim.state.enemies:
        if int(e.group)==other:e.x=float(sim.state.player.x)+20;e.y=float(sim.state.player.y);e.aggro=true;e.hp=1e6;break # fixture: an attacker beside the respawned hero
    sim.state.player.hp=float(sim.stats().hp)*.5
    var fire_before=float(sim.state.skill_cooldowns.get("fire",0))
    for i in range(10):sim.step(.1)
    check(float(sim.state.skill_cooldowns.get("fire",0))<=fire_before,"No automatic attack skill is cast during the return")
    check(float(sim.state.skill_cooldowns.get("heal",0))>0,"Automatic Heal still helps the hero on the way")
    # At the spot, a stranger out of reach is not chased away from the spot.
    fresh();own_focus()
    sim.campaign.discover_spot(g,1);sim.focus(g,1)
    var home=sim.farming_position()
    sim.state.player.x=home.x;sim.state.player.y=home.y
    for e in sim.state.enemies:
        if int(e.group)==g:e.hp=0.0;e.respawn=1e9 # fixture: the focused type is gone
    var stranger: Dictionary={}
    for e in sim.state.enemies:
        if int(e.group)==other:stranger=e;break
    stranger.x=home.x+float(sim.catalog.world.acquisition)+60;stranger.y=home.y;stranger.aggro=true;stranger.windup=0.0 # fixture: an attacker beyond the spot
    var chase=sim._may_chase(stranger)
    check(not chase,"Under a Focus a stranger far from the spot is not chased")
    stranger.x=home.x+40
    check(sim._may_chase(stranger),"…one near the spot still is (self-defence)")

## Realistic Summer II: a level-55 hero with a stage-appropriate build dies and respawns at the arrival camp while
## farming the stage's farthest found spot; the route crosses the stage's real spots (no fixture enemies).
func auto_farm_summer_checks() -> void:
    print("-- 1. Auto Farm: realistic Summer II respawn")
    for mode in ["fixed","pre_fix"]:
        fresh();own_focus()
        to_stage(4)
        sim.state.player_level=55 # fixture: level reached
        sim.add_item("gold_sword",1);sim.state.items["gold_sword"].merge=11;sim.equip("gold_sword") # fixture: merges from copies
        sim.add_item("boss-gray-cat_outfit_t2",1);sim.state.items["boss-gray-cat_outfit_t2"].merge=100;sim.equip("boss-gray-cat_outfit_t2")
        var camp: Array=sim.campaign.stage().spawns[0]
        var far=-1;var far_v=0;var best=0.0
        for gg in sim.campaign.stage().groups:
            if sim.catalog.groups[gg].boss:continue
            for v in sim.campaign.variants(gg):
                sim.campaign.discover_spot(gg,v) # fixture: spots found while exploring
                var d: float=sim.campaign.spot(gg,v).distance_to(Vector2(camp[0],camp[1]))
                if d>best:best=d;far=gg;far_v=v
        sim.focus(far,far_v)
        sim.campaign.explore_cells(4,[],true) # fixture: the map explored, so every enemy on the route is visible
        sim.state.spawn=0
        die_and_respawn()
        var engaged=false;var arrived=false;var deaths=0;var t=0.0
        while t<240.0:
            if mode=="pre_fix":sim.end_focus_return() # the old rule: no return state
            sim.step(.1);t+=.1
            if float(sim.state.player.hp)<=0:
                deaths+=1
                while float(sim.state.player.hp)<=0 and t<240.0:sim.step(.1);t+=.1
            var target=sim._find_actor(str(sim.state.player.target))
            if not target.is_empty() and int(target.group)!=far:engaged=true
            if sim.position_of(sim.state.player).distance_to(sim.farming_position())<=sim.FOCUS_ARRIVE_RADIUS+.5:arrived=true;break
        print("     Summer II %s: route %.0f px, arrived %s after %.1f s, deaths %d, fought on the way %s" % [mode,best,str(arrived),t,deaths,str(engaged)])
        if mode=="fixed":
            check(arrived and not engaged,"Summer II: the respawned hero reaches the farthest spot without fighting on the way (%.1f s, %d deaths)" % [t,deaths])
        else:
            check(engaged,"Root cause reproduced: without the return state the hero stops to fight enemies on the route")

# ---------------------------------------------------------------- 2. Reroll Stats
func boss_item(id: String,boss: String) -> void:
    sim._drop(id,{"group":gi(boss),"x":200.0,"y":200.0})
    sim.collect(int(sim.state.pickups.back().uid))

func attributes(id: String) -> Array:
    var out: Array=[]
    var r: Dictionary=sim.state.items[id]
    for k in r.extras:out.append([k,float(r.extras[k])])
    for e in sim.boss_extras(id):out.append([str(e.stat),float(e.value)])
    return out

func unique_stats(id: String) -> bool:
    var seen: Array=[]
    for a in attributes(id):
        if seen.has(a[0]):return false
        seen.append(a[0])
    return true

func reroll_checks() -> void:
    print("-- 2. Reroll Stats with locks")
    for item in [["wood_axe","boss-snowman"],["boss-snowman_outfit","boss-snowman"]]:
        fresh()
        var id: String=item[0]
        boss_item(id,item[1])
        check(sim.reroll_slot_keys(id)==["base:0","boss:0","boss:1"],"%s: one regular and two boss bonus slots" % id)
        var base=sim.reroll_cost(id)
        check(base>0,"%s: base price %d" % [id,base])
        # Additive price for every lock combination (integer, rounded up).
        var expected=[[[],100],[["base:0"],120],[["boss:0"],140],[["base:0","boss:0"],160],[["boss:0","boss:1"],180],[["base:0","boss:0","boss:1"],200]]
        for pair in expected:
            var locks: Array=pair[0]
            for key in sim.reroll_slot_keys(id):sim.set_reroll_lock(id,key,locks.has(key))
            var want=(base*int(pair[1])+99)/100
            check(sim.reroll_total_cost(id)==want,"%s: %s locked costs %d (%d%% of %d)" % [id,str(locks),want,int(pair[1]),base])
        # 1 regular + 1 boss locked: those keep stat and value, the other boss slot changes.
        for key in sim.reroll_slot_keys(id):sim.set_reroll_lock(id,key,key in ["base:0","boss:0"])
        var before=attributes(id)
        sim.state.gems=1000.0 # fixture: Gems
        var cost=sim.reroll_total_cost(id)
        var changed=0
        for i in range(12):
            var prior=attributes(id)
            var gems=float(sim.state.gems)
            var done=sim.reroll_stats(id)
            if i==0:check(done and is_equal_approx(gems-float(sim.state.gems),float(cost)),"%s: one reroll charged exactly the shown %d Gems" % [id,cost])
            if JSON.stringify(attributes(id)[2])!=JSON.stringify(prior[2]):changed+=1
        var after=attributes(id)
        check(JSON.stringify(after[0])==JSON.stringify(before[0]) and JSON.stringify(after[1])==JSON.stringify(before[1]),"%s: the locked regular and boss attributes kept stat AND value" % id)
        check(changed>=10,"%s: the unlocked boss attribute rerolled (%d/12 changed)" % [id,changed])
        check(sim.boss_extras(id).size()==2 and sim.state.items[id].extras.size()==1 and unique_stats(id),"%s: still 1 regular + 2 boss slots, no stat repeated" % id)
        # No locks: everything can change, at the base price.
        for key in sim.reroll_slot_keys(id):sim.set_reroll_lock(id,key,false)
        check(sim.reroll_total_cost(id)==base,"%s: no locks costs the base price" % id)
        var moved=[0,0,0]
        for i in range(10):
            var prior=attributes(id)
            sim.reroll_stats(id)
            for s in range(3):
                if JSON.stringify(attributes(id)[s])!=JSON.stringify(prior[s]):moved[s]+=1
        check(moved.all(func(n):return n>=7) and unique_stats(id),"%s: with no locks every attribute rerolls %s" % [id,str(moved)])
        # All locked: blocked, no charge, nothing changes, nothing unlocks.
        for key in sim.reroll_slot_keys(id):sim.set_reroll_lock(id,key,true)
        var gems_all=float(sim.state.gems);var all_before=attributes(id)
        check(sim.reroll_block_reason(id)=="REROLL_ALL_LOCKED" and not sim.reroll_stats(id),"%s: all locked blocks the reroll" % id)
        check(float(sim.state.gems)==gems_all and JSON.stringify(attributes(id))==JSON.stringify(all_before) and sim.reroll_locks(id).size()==3,"%s: …without a charge, a change or an unlock" % id)
        # Too few Gems: nothing changes at all.
        sim.set_reroll_lock(id,"boss:1",false)
        sim.state.gems=float(sim.reroll_total_cost(id)-1)
        var poor=attributes(id)
        check(not sim.reroll_stats(id) and sim.reroll_block_reason(id)=="NOT_ENOUGH_GEMS","%s: too few Gems refuses" % id)
        check(float(sim.state.gems)==float(sim.reroll_total_cost(id)-1) and JSON.stringify(attributes(id))==JSON.stringify(poor),"%s: …and changes no attribute (no partial reroll)" % id)
    # Locks belong to one item: another item of the same stats has none; merging and Precise Reroll.
    fresh()
    boss_item("wood_axe","boss-snowman")
    sim.add_item("wood_sword",1)
    sim.set_reroll_lock("wood_axe","base:0",true)
    check(sim.reroll_locks("wood_sword").is_empty(),"A lock on one item never appears on another")
    check(not sim.set_reroll_lock("wood_sword","boss:0",true),"A slot an item does not have cannot be locked")
    sim.add_item("wood_axe",1)
    var kept=attributes("wood_axe")
    check(sim.merge("wood_axe") and sim.reroll_locks("wood_axe")==["base:0"] and JSON.stringify(attributes("wood_axe"))==JSON.stringify(kept),"Merging keeps the attributes and their locks")
    sim.state.owned_cards=["collection_c7"] # fixture: Precise Reroll owned
    sim.state.gems=1e6
    var same=0
    for i in range(20):
        var prior=attributes("wood_axe")
        sim.reroll_stats("wood_axe")
        for s in [1,2]:
            if str(attributes("wood_axe")[s][0])==str(prior[s][0]):same+=1
    check(same==0 and unique_stats("wood_axe"),"Precise Reroll: an unlocked slot never rolls its own stat again")
    check(sim.campaign.valid_snapshot(sim.save_snapshot()),"A profile with locks validates")
    var r: Dictionary=sim.state.items["wood_axe"]
    r["locks"]=["boss:7",3,"base:0","base:0"] # fixture: a damaged locks value
    check(sim.reroll_locks("wood_axe")==["base:0"],"Unknown, malformed and repeated lock entries are ignored")
    r["locks"]="nonsense"
    check(sim.reroll_locks("wood_axe").is_empty() and sim.reroll_total_cost("wood_axe")==sim.reroll_cost("wood_axe"),"A non-list locks value reads as no locks")
    check(sim.campaign.valid_snapshot(sim.save_snapshot()),"…and still validates")

func reroll_persistence_checks() -> void:
    print("-- 2. Reroll locks: save, reload, older saves, Prestige")
    fresh()
    boss_item("boss-snowman_outfit","boss-snowman")
    sim.set_reroll_lock("boss-snowman_outfit","boss:1",true)
    var kept=attributes("boss-snowman_outfit")
    check(SaveService.save_now(),"Disk save")
    sim.state.items["boss-snowman_outfit"].erase("locks") # fixture: in-memory change the reload must undo
    SaveService.load_and_apply();await frames(2)
    check(sim.reroll_locks("boss-snowman_outfit")==["boss:1"] and JSON.stringify(attributes("boss-snowman_outfit"))==JSON.stringify(kept),"Reload keeps the lock and the attributes")
    sim.state.items["boss-snowman_outfit"].erase("locks") # fixture: a save written before Change 79
    check(SaveService.save_now(),"Disk save without locks (older save)")
    SaveService.load_and_apply();await frames(2)
    check(sim.reroll_locks("boss-snowman_outfit").is_empty() and sim.reroll_total_cost("boss-snowman_outfit")==sim.reroll_cost("boss-snowman_outfit"),"An older save loads with every attribute unlocked")

func reroll_ui_checks() -> void:
    print("-- 2. Reroll Stats in the item panel")
    for size in [Vector2i(432,960),Vector2i(540,960)]:
        fresh()
        get_window().size=size;await frames(4)
        game._cancel_confirm();sim.held=false;await frames(2)
        boss_item("wood_axe","boss-snowman")
        check(sim.quantity("wood_axe")==1 and sim.boss_extras("wood_axe").size()==2,"%dx%d: the boss weapon is collected (action lock '%s')" % [size.x,size.y,sim.action_lock_reason()])
        sim.state.gems=10000.0
        game.selected="wood_axe";game.selected_slot=-1;game._open("item");await frames(6)
        for i in range(60): # a resize can rebuild the panel once more; wait (bounded) for the live rows
            if live(game.rows.find_children("RerollLock","Button",true,false)).size()==3:break
            await frames(1)
        var locks: Array=live(game.rows.find_children("RerollLock","Button",true,false))
        var reroll: Array=live(game.rows.find_children("RerollStats","Button",true,false))
        var old: int=live(game.rows.find_children("*","Button",true,false)).filter(func(b):return b.name!="RerollStats" and str(b.text).begins_with(tr("REROLL_ATTRIBUTE").get_slice("%",0))).size()
        check(locks.size()==3 and reroll.size()==1 and old==0,"%dx%d: one Lock per attribute row and one Reroll Stats (no per-stat buttons)" % [size.x,size.y])
        check(locks.all(func(b):return b.size.y>=48 and b.size.x>=96),"%dx%d: Lock toggles are touch-sized" % [size.x,size.y])
        check(reroll.size()==1 and str(reroll[0].text).contains(game.fmt_cost(sim.reroll_cost("wood_axe"))),"%dx%d: the button shows the base price with no locks" % [size.x,size.y])
        var boss_lock: Button=locks.filter(func(b):return str(b.get_meta("reroll_lock",""))=="boss:0")[0]
        boss_lock.pressed.emit();await frames(4)
        check(sim.reroll_locks("wood_axe")==["boss:0"],"%dx%d: tapping Lock locks that attribute" % [size.x,size.y])
        reroll=live(game.rows.find_children("RerollStats","Button",true,false))
        check(reroll.size()==1 and str(reroll[0].text).contains(game.fmt_cost(sim.reroll_total_cost("wood_axe"))) and sim.reroll_total_cost("wood_axe")==(sim.reroll_cost("wood_axe")*140+99)/100,"%dx%d: the price updates at once (boss lock +40%%)" % [size.x,size.y])
        var relocked: Array=live(game.rows.find_children("RerollLock","Button",true,false)).filter(func(b):return str(b.get_meta("reroll_lock",""))=="boss:0")
        check(relocked.size()==1 and relocked[0].theme_type_variation==&"ToggleOn" and relocked[0].text==tr("REROLL_LOCKED"),"%dx%d: a locked attribute reads Locked in the ON style" % [size.x,size.y])
        check(_fits(game.get_viewport_rect().size.x),"%dx%d: the item panel fits the screen width" % [size.x,size.y])
        var gems=float(sim.state.gems);var cost=sim.reroll_total_cost("wood_axe")
        reroll[0].pressed.emit();await frames(6)
        check(game.get_node("Confirm").visible,"%dx%d: Reroll Stats asks for confirmation" % [size.x,size.y])
        game.get_node("Confirm/Panel/Margin/Content/Actions/Confirm").pressed.emit();await frames(6)
        check(is_equal_approx(gems-float(sim.state.gems),float(cost)),"%dx%d: confirming charges the shown %d Gems" % [size.x,size.y,cost])
        game.selected="wood_axe";game._open("item");await frames(4)
        await shot("reroll_%dx%d" % [size.x,size.y])
        for key in sim.reroll_slot_keys("wood_axe"):sim.set_reroll_lock("wood_axe",key,true)
        game._refresh_panel();await frames(4)
        reroll=live(game.rows.find_children("RerollStats","Button",true,false))
        check(reroll.size()==1 and reroll[0].disabled and str(reroll[0].text).contains(tr("REROLL_ALL_LOCKED")),"%dx%d: all locked, Reroll Stats is disabled with its reason" % [size.x,size.y])
        game._close()
    get_window().size=Vector2i(720,1280);await frames(4)

## Nodes of the current panel build only (a rebuild frees the previous rows at the end of the frame).
func live(nodes: Array) -> Array:
    return nodes.filter(func(n):return not n.is_queued_for_deletion())

func _fits(width: float) -> bool:
    var ok=true
    for c in game.rows.find_children("*","Control",true,false):
        if c.is_visible_in_tree() and c.get_global_rect().end.x>width+1:
            print("     overflow %s %s end %.0f" % [c.name,c.get_class(),c.get_global_rect().end.x]);ok=false
    return ok

func shot(name_: String) -> void:
    await frames(2)
    if DisplayServer.get_name()=="headless":return
    var dir="res://tests/tmp/change_79_probe/"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
    get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dir+name_+".png"))

# ---------------------------------------------------------------- 3. Followed objectives
func refresh_hud() -> void:
    for i in range(3):
        game._refresh_follow_tracker();game._refresh_mission_tracker();game._refresh_mastery_tracker();game._layout_trackers()
        await frames(3)
func pill_ok(tracker: Control) -> bool:
    var title: Label=tracker.get_node("Row/Text/Name")
    var lines: int=title.get_line_count()
    var visible: int=title.get_visible_line_count()
    return tracker.visible and lines>=1 and visible>=lines and title.size.y+.5>=title.get_combined_minimum_size().y and title.text_overrun_behavior==TextServer.OVERRUN_NO_TRIMMING

func tracker_checks() -> void:
    print("-- 3. Followed objective pills: action and target, wrapped, never cut")
    for size in [Vector2i(432,960),Vector2i(540,960)]:
        fresh()
        get_window().size=size;await frames(4)
        to_stage(4)
        var teal=gi("boss-teal-dinosaur")
        var c: Dictionary=sim.campaign.mastery.content(4)
        for g in c.groups:
            if int(g)!=teal:sim.state.group_kills[int(g)]=sim.campaign.mastery.hunt_target(int(g)) # fixture: every other hunt done
        sim.state.discovered[str(teal)]=true
        sim.campaign.mastery.toggle_follow(4,"hunt")
        # A daily mission about the longest-named Summer II enemy, followed.
        var long_g=-1
        for g in sim.campaign.stage().groups:
            if not sim.catalog.groups[g].boss and (long_g<0 or str(sim.catalog.groups[g].name).length()>str(sim.catalog.groups[long_g].name).length()):long_g=g
        sim.state.missions[0]={"kind":"kill","target":str(sim.catalog.groups[long_g].id),"progress":2.0,"goal":40.0,"claimed":false,"rewards":sim.state.missions[0].get("rewards",{}),"day":sim.state.missions[0].get("day","")} # fixture: today's mission
        sim.campaign.toggle_follow_mission("daily",0)
        # The Challenge II opportunity (defeat Teal Dinosaur without supplies), followed.
        sim.state.opportunities["challenge_o2"]={"ready":false,"baseline":{},"step":0,"count":0} # fixture: discovered
        sim.state.follow="challenge_o2"
        await refresh_hud()
        var mastery: Control=game.mastery_tracker
        var mission: Control=game.get_node("Safe/Layout/Map/MissionTracker")
        var prestige: Control=game.get_node("Safe/Layout/Map/FollowTracker")
        var mt: String=mastery.get_node("Row/Text/Name").text
        check(mt==tr("FOLLOW_GOAL_KILL_TARGET") % str(sim.catalog.groups[teal].name),"%dx%d: the Mastery pill reads \"%s\"" % [size.x,size.y,mt])
        var mi: String=mission.get_node("Row/Text/Name").text
        check(mi.contains(str(sim.catalog.groups[long_g].name)) and mi.begins_with(tr("MISSION_DO_KILL").get_slice("%",0)),"%dx%d: the mission pill says what to do: \"%s\"" % [size.x,size.y,mi])
        var pt: String=prestige.get_node("Row/Text/Name").text
        check(pt.contains(str(sim.catalog.groups[teal].name)) and pt.begins_with(tr("FOLLOW_CHALLENGE").get_slice("%",0)),"%dx%d: the Prestige pill keeps the full instruction: \"%s\"" % [size.x,size.y,pt])
        for tracker in [mastery,mission,prestige]:
            check(pill_ok(tracker),"%dx%d: %s shows every line of its text (%d lines)" % [size.x,size.y,tracker.name,tracker.get_node("Row/Text/Name").get_line_count()])
            check(tracker.get_node("Row/Progress").text!="" or tracker==prestige,"%dx%d: %s keeps its progress" % [size.x,size.y,tracker.name])
        check(game.tracker_clearance()>=0,"%dx%d: the pills start below the enemy controls" % [size.x,size.y])
        var rects: Array=[mastery.get_global_rect(),mission.get_global_rect(),prestige.get_global_rect()]
        var map: Control=game.get_node("Safe/Layout/Map")
        var apart=true
        for i in range(rects.size()):
            for j in range(i+1,rects.size()):
                if rects[i].intersects(rects[j]):apart=false
            for path in ["MiniMap","ZoomButton","Mastery","Gate"]:
                var node: Control=map.get_node(path)
                if node.visible and rects[i].intersects(node.get_global_rect()):apart=false
            if game.stick.visible and rects[i].intersects(game.stick.get_global_rect()):apart=false
            if rects[i].end.x>size.x or rects[i].end.y>map.get_global_rect().end.y:apart=false
        check(apart,"%dx%d: the pills overlap nothing (each other, minimap, chips, joystick) and stay on screen" % [size.x,size.y])
        # The hero stands at its camp (as after every respawn): View Camp shows under the camp name and must not
        # cover a pill.
        game._refresh_view_camp();await frames(2);game._refresh_view_camp()
        var view: Button=map.get_node("ViewCamp")
        var clear_of_pills=true
        if view.visible:
            for r in rects:
                if r.intersects(view.get_global_rect()):clear_of_pills=false
            for path in game.VIEW_CAMP_AVOID:
                var node: Control=map.get_node(path)
                if node.visible and node.get_global_rect().intersects(view.get_global_rect()):clear_of_pills=false;print("     View Camp over ",path)
        print("     View Camp visible %s at %s" % [str(view.visible),str(view.get_global_rect())])
        check(clear_of_pills,"%dx%d: View Camp keeps clear of the pills and the HUD rails" % [size.x,size.y])
        await shot("trackers_%dx%d" % [size.x,size.y])
    get_window().size=Vector2i(720,1280);await frames(4)

# ---------------------------------------------------------------- 4. Offline Skills
## Records `hours` of time away from now (virtual clock) and returns the pending record.
func away(hours: float) -> Dictionary:
    sim.state.offline_snapshot=sim.campaign.offline_snapshot()
    sim.campaign.settle_offline(float(sim.state.offline_snapshot.time)+hours*3600.0)
    return sim.state.offline_pending

func skill_copies(pending: Dictionary) -> Dictionary:
    var out: Dictionary={}
    for id in pending.get("items",{}):
        if str(sim.catalog.items[id].kind)=="skill":out[id]=int(pending.items[id])
    return out

func offline_checks() -> void:
    print("-- 4. Offline Skills")
    sim.clock_override=2000000000.0
    fresh()
    sim.add_item("skill_fire",2) # fixture: owned skill stock
    sim.add_item("wood_sword",1)
    check(sim.catalog.upgrades.has("offline_skill") and sim.catalog.upgrades.has("offline_skill_rate"),"The Offline Skills unlock and rate upgrades exist")
    check(sim.upgrade_block_reason("offline_skill_rate")=="AUTOMATION_LOCKED","The rate needs the unlock first")
    var p=away(10.0)
    check(skill_copies(p).is_empty(),"Locked: 10 hours away grant no skill")
    sim.state.offline_pending={}
    sim.state.gems=float(sim.upgrade_cost("offline_skill")) # fixture: Gems
    check(sim.upgrade_cost("offline_skill")==75 and sim.buy_upgrade("offline_skill") and float(sim.state.gems)==0.0,"Unlock costs 75 Gems")
    check(is_equal_approx(float(sim.campaign.offline_snapshot().rates.skill),.5),"Unlocked rate 0.5 skills per hour")
    for hours in [4.0,6.0,1.0]:
        sim.state.offline_pending={};sim.state.offline_remainders={}
        p=away(hours)
        var copies=skill_copies(p)
        var total=0
        for id in copies:total+=int(copies[id])
        check(total==int(floor(minf(hours,5.0)*.5)) and copies.keys().all(func(id):return id=="skill_fire"),"%.0f h away (5 h cap): %d copies, all of the owned skill" % [hours,total])
    sim.state.coins=1e6
    sim.buy_upgrade("offline_skill_rate");sim.buy_upgrade("offline_skill_rate")
    check(is_equal_approx(float(sim.campaign.offline_snapshot().rates.skill),1.0) and is_equal_approx(sim.player_upgrade_value("offline_skill_rate"),1.0),"Two rate levels: 1 skill per hour")
    sim.state.offline_pending={};sim.state.offline_remainders={}
    p=away(100.0)
    var capped=0
    for id in skill_copies(p):capped+=int(skill_copies(p)[id])
    check(capped==5,"The offline duration cap applies (5 h cap: %d copies)" % capped)
    # Claim once.
    var before=sim.quantity("skill_fire")
    check(sim.campaign.claim_offline() and sim.quantity("skill_fire")==before+capped,"Claim adds the copies to the owned skill's stack")
    check(not sim.campaign.claim_offline() and sim.quantity("skill_fire")==before+capped,"A second claim pays nothing")
    # No stock, no skill.
    sim._remove("skill_fire",sim.quantity("skill_fire"))
    sim.state.offline_pending={};sim.state.offline_remainders={}
    check(skill_copies(away(8.0)).is_empty(),"Without skill stock at departure, no skill is granted (no discovery)")
    # An older snapshot without the skill kind grants none and settles normally.
    sim.add_item("skill_heal",1)
    sim.state.offline_pending={}
    var old: Dictionary=sim.campaign.offline_snapshot()
    old.eligible.erase("skill");old.rates.erase("skill")
    sim.state.offline_snapshot=old
    sim.campaign.settle_offline(float(old.time)+5*3600.0)
    check(skill_copies(sim.state.offline_pending).is_empty() and float(sim.state.offline_pending.get("coins",0))>0,"A snapshot saved before Change 79 settles without skills")

func offline_persistence_checks() -> void:
    print("-- 4. Offline Skills: reload, Prestige, Hard Reset")
    fresh()
    sim.add_item("skill_frost",1)
    sim.state.gems=1000.0;sim.buy_upgrade("offline_skill")
    sim.state.offline_pending={};sim.state.offline_remainders={}
    away(4.0)
    check(SaveService.save_now(),"Disk save with a pending claim")
    SaveService.load_and_apply();await frames(2)
    check(skill_copies(sim.state.offline_pending).get("skill_frost",0)==2,"The pending skill copies survive a reload")
    check(sim.campaign.claim_offline() and SaveService.save_now(),"Claimed and saved")
    var n=sim.quantity("skill_frost")
    SaveService.load_and_apply();await frames(2)
    check(sim.state.offline_pending.is_empty() and sim.quantity("skill_frost")==n and not sim.campaign.claim_offline(),"After a reload the claim cannot repeat")
    # Prestige keeps the unlock (every upgrade is kept).
    var g=sim.campaign.prestige_unlock_group()
    sim.state.bosses_found.append("boss-snowman");sim.state.group_kills[g]=maxi(1,int(sim.state.group_kills[g])) # fixture: Prestige unlocked
    sim.state.opportunities["offering_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: a ready opportunity
    if sim.campaign.begin_prestige():
        var guard=0
        while not sim.state.prestige_batch.is_empty() and guard<20:
            guard+=1
            var offered: Array=sim.campaign.offered_cards()
            if offered.is_empty() or not sim.campaign.choose_card(str(offered[0])):break
    check(int(sim.state.prestiges)>=1 and sim.level("offline_skill")==1,"Prestige keeps Offline Skills")
    check(SaveService.hard_reset() and sim.level("offline_skill")==0,"Hard Reset clears it")

func offline_ui_checks() -> void:
    print("-- 4. Offline Skills in the panels")
    fresh()
    sim.add_item("skill_fire",1)
    game.player_tab=4;game._open("upgrades");await frames(6)
    var text=""
    for l in game.rows.find_children("*","Label",true,false):text+=str(l.text)+"\n"
    check(text.contains(tr("UP_OFFLINE_SKILL")) and text.contains(tr("UP_OFFLINE_SKILL_RATE")) and text.contains(tr("OFFLINE_SKILL_BENEFIT")),"Upgrades → Offline lists the Offline Skills unlock and its rate")
    check(text.contains(tr("AUTOMATION_LOCKED")),"…the rate shows it needs the unlock")
    game._close()
    sim.state.offline_pending={"id":"x","seconds":7200.0,"longest":7200.0,"rewarded_hours":2.0,"coins":10.0,"gems":1.0,"items":{"skill_fire":1}} # fixture: a pending claim
    game._open("offline");await frames(6)
    var skills_row=false;var locked=false
    for line in game.rows.find_children("*","HBoxContainer",true,false):
        if str(line.get_meta("offline_category",""))=="skill":
            skills_row=true
            for l in line.get_children():
                if l is Label and l.text==tr("OFFLINE_CAT_LOCKED"):locked=true
    check(skills_row and locked,"Welcome back lists Skills, marked Locked before the unlock")
    game._close()

# ---------------------------------------------------------------- 5. Boss balance data
## Before (Change 78, commit 1cde5b5) -> after values of every boss; skills after. Bosses not listed as changed keep
## their exact Change 78 values.
const BOSSES:={
    "boss-snowman":[599.9,8.0,599.9,8.0],"boss-cyan-robot":[1096.2,13.3,1096.2,13.3],"boss-gray-cat":[2089.2,23.23,2089.2,23.23],
    "boss-elephant":[3926.74,38.41,3141.39,44.17],"boss-teal-dinosaur":[4378.11,38.41,3721.39,44.17],
    "boss-squirrel":[7543.26,56.68,6034.61,73.69],"boss-red-fox":[8410.34,56.68,7148.79,65.19],
    "boss-black-cat":[20083.96,98.85,18075.56,108.74],"boss-grim-reaper":[22392.56,98.85,20153.31,86.99],
    "boss-bee":[66473.5,150.18,66473.5,150.18],"boss-orange-tabby-cat":[74114.5,160.99,74114.5,160.99],
    "boss-red-panda":[176985.99,280.74,79643.69,379.01],"boss-sunflower":[197330.11,300.95,88798.55,346.10],
    "boss-green-alien":[304513.69,345.84,137031.16,415.01]}
const DAMAGING:=["fire","strike","frost","lightning"]
func boss_balance_checks() -> void:
    print("-- 5. Boss balance data")
    fresh()
    for id in BOSSES:
        var g:=gi(id)
        var d: Dictionary=sim.enemy_definition(g,2)
        var want: Array=BOSSES[id]
        check(absf(float(d.hp)-float(want[2]))<.05 and absf(float(d.damage)-float(want[3]))<.01,"%s: HP %.0f -> %.0f, hit %.2f -> %.2f" % [id,float(want[0]),float(d.hp),float(want[1]),float(d.damage)])
        if int(sim.catalog.groups[g].stage)>=4 and not bool(sim.catalog.groups[g].final):
            check(Array(d.skills).any(func(k):return DAMAGING.has(str(k))),"%s has a telegraphed damaging skill %s" % [id,str(d.skills)])
    check(Array(sim.enemy_definition(gi("boss-elephant"),2).skills)==["strike","focus"] and Array(sim.enemy_definition(gi("boss-squirrel"),2).skills)==["strike","heal"] and Array(sim.enemy_definition(gi("boss-sunflower"),2).skills)==["fire","heal"],"Elephant Strike + Focus, Squirrel Strike + Heal, Sunflower Fire + Heal")
    check(Array(sim.abilities.final_attack_pool).has("strike") and Array(sim.abilities.final_attack_pool).has("fire"),"Green Alien keeps its final kit")
    sim.state.owned_cards=["hunter_c1","hunter_c2","trophy_c2"] # fixture: the boss cards owned
    check(is_equal_approx(sim.campaign.bonus("boss_damage"),.25) and is_equal_approx(sim.campaign.bonus("boss_guard"),.10),"Giant Slayer +15%, Trophy Power +10% (sum +25%), Boss Guard -10%")
    sim.state.owned_cards=["challenge_c1","challenge_c2","challenge_c3","hunter_c2","trophy_c2"] # fixture: Challenge set and Boss Specialist
    check(is_equal_approx(sim.campaign.bonus("boss_damage"),.10+.05+.05),"Challenge set and Boss Specialist combos: +5% each")
    check(tr("CONTENT_HUNTER_C1_DESCRIPTION").contains("15%") and tr("CONTENT_HUNTER_C2_DESCRIPTION").contains("10%") and tr("CONTENT_TROPHY_C2_DESCRIPTION").contains("10%"),"Card descriptions state the new values")
    var boss: Dictionary=sim._find_actor("player").duplicate();boss.id="x";boss.group=gi("boss-red-panda")
    sim.state.owned_cards=["hunter_c2"]
    check(is_equal_approx(sim.campaign.damage_multiplier(boss,sim.state.player),.9),"Boss Guard: a boss hits for 90%")
