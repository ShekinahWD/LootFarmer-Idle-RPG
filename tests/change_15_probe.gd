extends Node
## Change 15 probe: the early equipment guarantee, menu access per mode (Change 25: Basic/None open
## every menu, Guided keeps its staged reveal; persistence), the notification sounds and Map Mastery
## (records, latches, percentages, rewards applied once, Prestige and Hard Reset, panels, reachable
## exploration). Runs WITHOUT --first-run-complete: fresh profiles start the real progression.
## Real main scene and simulation; state set directly is labelled "fixture".
var checks:=0
var failures:=0
var sim
var game
var notices: Array=[]
var milestones: Array=[]
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
    if game.help_viewer.visible:game.help_viewer.hide() # Change 65: a Basic opening left by an earlier step
    sim.held=false
    sim.new_profile();sim.state.tutorial.mode=mode;sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=15015;game._close()
    sim.campaign.focus_hint=-1
    game.banner.queue.clear();game.banner.current={};game.toast_queue.clear()
    notices.clear();milestones.clear()
    AudioService.reset_history()
func run() -> void:
    check(not BootContext.first_run_complete,"The probe runs the real first-profile progression (no fixture flag)")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false)
    SettingsState.mute_all_sfx()
    sim.notice.connect(func(kind: String,id: String)->void:notices.append([kind,id]))
    sim.milestone.connect(func(kind: String,id: String)->void:milestones.append([kind,id]))
    fresh()
    await frames(4)
    await guarantee_checks()
    await reveal_checks()
    await guided_checks()
    await basic_checks()
    await none_checks()
    await audio_checks()
    await mastery_checks()
    await reach_checks()
    await ui_checks()
    print("CHANGE_15_CHECKS ",checks," FAILURES ",failures)
    for g in range(3):sim.catalog.groups[g].gear_chance=.05
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

# ---------------------------------------------------------------- helpers
func group(id: String) -> int:return sim.campaign.group_id(id)
func enemy(g: int,v:=-1) -> Dictionary:
    for e in sim.state.enemies:
        if int(e.group)==g and not sim.is_helper(e) and float(e.hp)>0 and (v<0 or int(e.get("variant",2))==v):return e
    return {}
func kill(e: Dictionary) -> void:
    e.hp=0;sim._kill(e)
    for a in sim.state.enemies:
        if float(a.hp)<=0 and not sim.is_helper(a):a.hp=sim.enemy_definition(int(a.group),int(a.get("variant",2))).hp;a.respawn=0
func collect_all() -> void:
    for d in sim.state.pickups.duplicate():sim.collect(int(d.uid))
func gear_on_ground() -> int:
    var n:=0
    for d in sim.state.pickups:
        if sim.catalog.items[d.item].kind in ["weapon","outfit"]:n+=1
    return n
func owned_gear() -> Array:
    var ids: Array=[]
    for id in sim.state.items:
        if sim.quantity(id)>0 and sim.catalog.items[id].kind in ["weapon","outfit"]:ids.append(id)
    return ids
## Natural equipment drops off for the Winter I normal types (fixture), so the guarantee is the only source.
func natural(chance: float) -> void:
    for g in range(3):sim.catalog.groups[g].gear_chance=chance
func nav(name: String) -> Control:return game.dock.get_node("Navigation/"+name)
func map_node(path: String) -> Control:return game.get_node("Safe/Layout/Map/"+path)
func labels_text(root: Node) -> String:
    return " | ".join(root.find_children("*","Label",true,false).map(func(l):return l.text))
func buttons_text(root: Node) -> String:
    return " | ".join(root.find_children("*","Button",true,false).map(func(b):return b.text))
func button_with(root: Node,text: String) -> Button:
    for b in root.find_children("*","Button",true,false):
        if str(b.text).begins_with(text):return b
    return null
func ready_opportunity() -> void:
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
func do_prestige() -> bool:
    sim.state.group_kills[sim.campaign.prestige_unlock_group()]=maxi(1,int(sim.state.group_kills[sim.campaign.prestige_unlock_group()]))
    ready_opportunity()
    return sim.campaign.begin_prestige() and sim.prestige(sim.campaign.offered_cards()[0])
func snowman_defeated() -> void:
    var g: int=group("boss-snowman")
    sim.state.group_kills[g]=maxi(1,int(sim.state.group_kills[g])) # fixture: the lifetime kill
    sim.state.run_kills["boss-snowman"]=1
    sim.campaign.onboarding.evaluate()

# ---------------------------------------------------------------- 1. early equipment guarantee
func guarantee_checks() -> void:
    print("-- early equipment guarantee")
    fresh()
    check(sim.state.onboarding.loot_phase==0 and sim.state.onboarding.loot_kills==0 and owned_gear().is_empty(),"Fresh profile: no equipment, guarantee at the start")
    var rules=sim.campaign.onboarding.rules
    check(rules.first_item_kills==5 and rules.copy_kills==5,"Rules: first item within 5, a matching copy within 5 more (onboarding_rules.tres)")
    # Every Winter I type, every mode, several seeds, every loadout variant in turn, with natural drops on.
    var worst_first:=0;var worst_pair:=0;var all_ok:=true;var runs:=0
    for mode in ["guided","basic","none"]:
        for g in range(3):
            for seed in range(1,5):
                fresh(mode);sim.rng.seed=seed*97+g
                var first:=-1;var pair:=-1
                for i in range(12):
                    kill(enemy(g,i%3));collect_all()
                    var state: int=sim.campaign.onboarding.loot_state()
                    if state>=1 and first<0:first=i+1
                    if state>=3 and pair<0:pair=i+1
                runs+=1
                worst_first=maxi(worst_first,first);worst_pair=maxi(worst_pair,pair)
                if first<1 or first>5 or pair<1 or pair>10:all_ok=false
    check(all_ok,"%d runs (3 modes × 3 Winter I types × 4 seeds): first item by kill %d (≤5), a mergeable pair by kill %d (≤10)" % [runs,worst_first,worst_pair])
    # Natural drops off: the guarantee lands exactly on kills 5 and 10, for every type and loadout.
    natural(0.0)
    for g in range(3):
        for v in range(3):
            fresh();sim.rng.seed=7
            var at: Array=[]
            for i in range(10):
                kill(enemy(g,v));collect_all()
                if sim.campaign.onboarding.loot_state()>=1 and at.is_empty():at.append(i+1)
                if sim.campaign.onboarding.loot_state()>=3 and at.size()==1:at.append(i+1)
            var ids: Array=owned_gear()
            var mergeable: bool=not ids.is_empty() and sim.can_merge(ids[0])
            check(at==[5,10] and ids.size()==1 and mergeable,"Type %d variant %d: item on kill 5, matching copy on kill 10, mergeable (%s)" % [g,v,str(ids)])
    # The pair can be equipped and merged.
    var id: String=owned_gear()[0]
    check(sim.equip(id) and (sim.state.weapon==id or sim.state.outfit==id),"The guaranteed item equips")
    check(sim.merge(id) and int(sim.record(id).merge)==1,"…and merges with its guaranteed copy")
    # Switching type after the first item: the farmed enemy carries nothing owned, so its own item doubles.
    fresh();sim.rng.seed=11
    for i in range(5):kill(enemy(2,0));collect_all()
    var first_item: Array=owned_gear()
    for i in range(5):kill(enemy(0,1));collect_all()
    var pairs: Array=owned_gear().filter(func(x):return sim.quantity(x)>=2)
    check(first_item==["unit-chef-hat_outfit"] and pairs==["wood_sword"],"Chef Hat outfit first, then only weapon-only Blue Caps: two Wood Swords make the pair on kill 10")
    # A natural drop satisfies a step earlier and restarts the count.
    natural(1.0);fresh();sim.rng.seed=3
    kill(enemy(0,2))
    check(gear_on_ground()==2 and sim.state.onboarding.loot_phase==1 and sim.state.onboarding.loot_kills==0,"A natural drop on kill 1: no extra drop, phase advanced, count restarted")
    kill(enemy(0,2))
    check(gear_on_ground()==4 and sim.state.onboarding.loot_phase==2,"A natural matching copy on kill 2: pair waiting on the ground, nothing forced")
    collect_all();kill(enemy(0,2))
    check(sim.state.onboarding.loot_phase==3,"Picking the pair up ends the guarantee for good")
    natural(0.0)
    # Supplies and non-matching equipment never satisfy it.
    fresh();sim.add_item("potion",3) # fixture: supplies owned
    for i in range(4):kill(enemy(1,2));collect_all()
    check(owned_gear().is_empty() and sim.state.onboarding.loot_phase==0,"Owning supplies does not count as the first item")
    kill(enemy(1,2));collect_all()
    check(owned_gear().size()==1,"…the first item still comes on kill 5")
    var a_item: String=owned_gear()[0]
    var other: String="unit-chef-hat_outfit" if a_item!="unit-chef-hat_outfit" else "wood_axe"
    sim.add_item(other) # fixture: a non-matching item
    for i in range(4):kill(enemy(1,2));collect_all()
    check(owned_gear().all(func(x):return sim.quantity(x)==1) and sim.state.onboarding.loot_phase==1,"A different item is not a match: still waiting")
    kill(enemy(1,2));collect_all()
    check(sim.quantity(a_item)==2 and sim.state.onboarding.loot_phase==3,"…the matching copy still comes on the 5th kill")
    # Uncollected loot that expires is replaced on the next eligible kill.
    fresh()
    for i in range(5):kill(enemy(0,1))
    check(gear_on_ground()==1 and owned_gear().is_empty(),"Kill 5: the item waits on the ground (not collected)")
    sim.state.pickups.clear() # fixture: it expired
    kill(enemy(0,1))
    check(gear_on_ground()==1,"Expired: the next eligible kill drops it again")
    collect_all()
    for i in range(4):kill(enemy(0,1))
    check(gear_on_ground()==0,"The copy count restarted at the pickup's replacement")
    kill(enemy(0,1))
    check(gear_on_ground()==1,"…and the copy lands 5 kills later")
    sim.state.pickups.clear() # fixture: the copy expired
    check(sim.campaign.onboarding.loot_state()==1,"An expired copy lowers the phase again")
    kill(enemy(0,1))
    check(gear_on_ground()==1,"…and is replaced on the next eligible kill")
    # Bosses do not count; nothing is forced from a boss.
    fresh()
    for i in range(3):kill(enemy(0,0))
    var boss: Dictionary=enemy(group("boss-snowman"))
    boss.hp=0;sim._kill(boss)
    check(sim.state.onboarding.loot_kills==3,"A boss kill is not an eligible kill")
    # A full row: a copy of an owned item stacks (no slot needed).
    fresh()
    for id_ in ["wood_sword","wood_axe","unit-blue-cap_outfit"]:sim.add_item(id_) # fixture: three kinds, row full
    sim.state.onboarding.loot_phase=1
    for i in range(5):kill(enemy(1,0));collect_all()
    check(owned_gear().any(func(x):return sim.quantity(x)>=2) and owned_gear().size()==3,"Full equipment row: the copy stacks on an owned item")
    # Once per profile; normal chances afterwards.
    natural(.05)
    check(near(sim.gear_chance(0),.05),"Normal equipment chance unchanged (5%)")
    check(sim.campaign.onboarding.loot_kill(enemy(0,2),sim.enemy_definition(0,2),[]).is_empty(),"After the pair, the guarantee never adds a drop")
    natural(0.0)
    check(do_prestige() and sim.state.onboarding.loot_phase==3,"Prestige keeps it spent")
    for i in range(10):kill(enemy(0,2));collect_all()
    check(owned_gear().is_empty(),"…so the next run has no guaranteed drops")
    check(SaveService.hard_reset() and sim.state.onboarding.loot_phase==0,"Hard Reset restores it (a new profile)")
    natural(.05)

# ---------------------------------------------------------------- 2. menu access
## Change 25 supersedes the Change 15 reveal table for Basic and None: those modes open every menu
## when chosen (change_25_probe covers it in depth); Guided keeps its own staged reveal (section 3).
func reveal_checks() -> void:
    print("-- menu access (Change 25)")
    fresh("pending");await frames(4)
    check(sim.state.onboarding.reveal.is_empty() and not sim.campaign.onboarding.revealed("missions"),"Before a mode is chosen nothing is revealed")
    var settings_x: float=nav("Settings").get_global_rect().position.x
    fresh("guided");await frames(4)
    var hidden_nav: bool=true
    for n in ["World","Missions","Prestige","Upgrades"]:
        if not (nav(n).disabled and nav(n).modulate.a==0.0 and nav(n).mouse_filter==Control.MOUSE_FILTER_IGNORE):hidden_nav=false
    check(hidden_nav,"Guided: World, Missions, Prestige and Upgrades start hidden and untouchable")
    for p in ["missions","world","upgrades","prestige","enemy","filters","camp","teleport","farming","mastery"]:
        game._open(p)
    check(game.panel=="" and not game.sheet.visible,"Guided: every hidden panel refuses to open")
    game._open("settings");check(game.panel=="settings","Settings opens");game._close()
    for mode in ["basic","none"]:
        fresh("pending");await frames(2);game.guide.choose(mode);await frames(4);game._process(.2)
        var open_nav:=true
        for n in ["World","Missions","Prestige","Upgrades","Settings"]:
            if nav(n).disabled or nav(n).modulate.a<1.0 or nav(n).mouse_filter!=Control.MOUSE_FILTER_STOP:open_nav=false
        check(open_nav and is_equal_approx(nav("Settings").get_global_rect().position.x,settings_x),"%s: every navigation button usable at once; Settings keeps its place" % mode)
        check(sim.campaign.onboarding.all_revealed() and sim.state.onboarding.reveal.size()==sim.campaign.onboarding.FEATURES.size(),"%s: every menu recorded as revealed" % mode)
        check(not notices.any(func(n):return n[0]=="feature_unlocked") and not nav("World/Badge").visible and not nav("Upgrades/Badge").visible,"%s: opened silently (no unlock sound, no ✦ cascade)" % mode)
        check(sim.campaign.prestige_block_reason()=="PRESTIGE_LOCKED_BOSS_DEFEAT" and int(sim.state.unlocked_stage)==1,"%s: the Prestige reset and Winter II keep their game rules" % mode)
    # Basic/None: finding the Snowman announces the Prestige reset once (the menu was already open).
    fresh();milestones.clear()
    var boss: Dictionary=enemy(group("boss-snowman"))
    boss.hp=0;sim._kill(boss)
    var kinds: Array=milestones.map(func(m):return m[0])
    check(kinds.find("stage")>=0 and kinds.find("stage")<kinds.find("prestige_unlocked"),"Killing the Snowman: \"Winter II\" banner, then \"Prestige unlocked\" (%s)" % str(kinds))
    sim.campaign.onboarding.evaluate();sim.campaign.onboarding.evaluate()
    check(milestones.filter(func(m):return m[0]=="prestige_unlocked").size()==1,"…announced once")
    check(do_prestige() and sim.campaign.onboarding.all_revealed(),"Prestige keeps every menu")
    sim.campaign.onboarding.evaluate()
    check(milestones.filter(func(m):return m[0]=="prestige_unlocked").size()==1,"…and never announces Prestige again")
    check(SaveService.hard_reset() and sim.state.onboarding.reveal.is_empty() and sim.state.tutorial.mode=="pending","Hard Reset returns to the chooser with nothing revealed")
    var bad: Dictionary=sim.snapshot();bad.onboarding.reveal=["missions","missions"]
    check(not sim.campaign.valid_snapshot(bad),"Validation rejects a duplicated reveal")
    fresh();notices.clear()
    game._open("settings");await frames(2)
    check(labels_text(game.rows).contains(tr("SECTION_HELP_TUTORIALS")) and game.guide._panel_control("show_all_menus")==null and buttons_text(game.rows).contains(tr("HELP")),"Settings → Help & Tutorials offers Help, no Show all menus (Change 16, 65)")
    game._close()
    fresh("pending");sim.campaign.onboarding.reveal_all(true)
    check(sim.campaign.onboarding.all_revealed() and not notices.any(func(n):return n[0]=="feature_unlocked"),"reveal_all(silent) records every menu, silently (probe use)")
    check(sim.campaign.prestige_block_reason()=="PRESTIGE_LOCKED_BOSS_DEFEAT","…the Prestige reset still needs the Snowman defeated")

# ---------------------------------------------------------------- 3. Guided
func guided_checks() -> void:
    print("-- Guided (Change 20 sequence, Change 61 order)")
    fresh("guided");await frames(4)
    var guide=game.guide
    var flow=sim.campaign.guided
    check(guide.pending=="move" and guide.pointer.visible,"Guided starts with movement")
    for step in ["move","kill","collect","equip","close_equip","gear_bonus","merge","close_merge"]:flow.mark(step)
    sim.state.counters.kill=5;sim.campaign.evaluate_main()
    # Change 22/23 (Change 24 fixture): Guided waits count real active seconds in TutorialGuide._process
    # (tutorial.flow.wait_seconds), not the simulation's playtime. The probe drives that clock directly.
    var delay: float=float(flow.rules().mission_delay)
    flow.advance_waits(delay-1.0);sim.state.playtime_total=1000.0;await frames(4)
    check(guide.pending=="" and not sim.campaign.onboarding.revealed("missions"),"Missions hidden during the timed farming interval (playtime alone never opens them)")
    flow.advance_waits(1.0);await frames(4)
    check(guide.pending=="missions" and guide.target==nav("Missions"),"Missions introduced after %d real active seconds" % int(delay))
    game._nav("missions");await frames(6)
    var claim: Button=guide._panel_control("claim",true)
    check(claim!=null and guide.step=="missions_claim","Mission guide points at real claim")
    if claim!=null:claim.pressed.emit()
    await frames(6)
    check(guide.step=="close_panel" and guide.target==game.get_node("Sheet/Margin/Content/Header/Close"),"Claim asks to close panel")
    game._close();flow.advance_waits(float(flow.rules().upgrade_delay));await frames(4)
    check(guide.pending=="player_upgrade" and sim.campaign.onboarding.revealed("upgrades"),"Player Upgrades introduced after close and delay")
    sim.state.coins=1000;game._open("upgrades");await frames(6)
    var buy: Button=guide._panel_control("buy_upgrade",true)
    check(buy!=null,"Player Upgrade has a real purchase target")
    if buy!=null:buy.pressed.emit()
    await frames(4)
    # Change 61: the Offline tab (inspected, nothing bought) comes before closing Upgrades.
    var offline_tab: Button=guide._panel_control("tab_tab_offline")
    check(guide.pending=="offline_rewards" and guide.target==offline_tab and offline_tab!=null,"Offline lesson points at the real Offline tab")
    if offline_tab!=null:offline_tab.pressed.emit()
    await frames(4)
    check(guide.step=="close_panel","Upgrade requires close")
    game._close();await frames(4)
    # Inventory and potion lessons (change_20_probe walks them) now precede the camp.
    check(guide.pending=="expand_inventory","Inventory lesson follows Player Upgrades")
    for step in ["expand_inventory","close_inventory","potion_buy","potion_use"]:flow.mark(step)
    await frames(4)
    check(guide.pending=="camp" and guide.path_point!=Vector2.INF,"Camp lesson directs physical approach")
    # An unrelated panel hides guidance without changing its pending outcome.
    game._open("settings");await frames(4)
    check(guide.pending=="camp" and not guide.pointer.visible and not guide.card.visible,"Unrelated panel suspends presentation")
    game._close();await frames(4)
    check(guide.pending=="camp" and guide.pointer.visible,"Closing unrelated panel restores live direction")
    flow.mark("camp");await frames(4)
    check(guide.pending=="respawn_select","Choosing the respawn camp follows the camp unlock")
    flow.mark("respawn_select");flow.mark("camp_travel");sim.state.bosses_found.append("boss-snowman");await frames(4)
    check(guide.pending=="map_details" and guide.step=="boss_found" and guide.target==nav("World") and not guide.intro_button.visible,"Finding the Snowman leads to Map detail through World, with no acknowledgement card")
    check(sim.campaign.prestige_gate_reason()=="PRESTIGE_TUTORIAL_LOCKED","Guided Prestige remains blocked until the optional Prestige lesson")

# ---------------------------------------------------------------- 4. Basic
## Change 25: a short up-front overview deck, then The Road Ahead; nothing after (change_25_probe).
func basic_checks() -> void:
    print("-- Basic")
    fresh("basic");await frames(4)
    var guide=game.guide
    # Change 65: the opening is the shared card viewer with the 8 essential cards (change_65_probe).
    var viewer=game.help_viewer
    var deck: Array=viewer.HelpCards.essential()
    check(viewer.visible and viewer.context=="basic" and viewer.current()=="movement_combat" and not guide.pointer.visible,"Basic: a concrete opening card (Movement & Combat), no pointer")
    check(tr(viewer.HelpCards.action_key("movement_combat")).contains("joystick") and tr("GUIDE_MODE_BASIC").begins_with("Basic"),"The opening says how to walk and fight; the mode is named Basic")
    viewer.toggle_auto() # Auto-Advance is off by default; the player may turn it on
    for k in range(60):viewer._process(.25)
    check(viewer.index>=1 and viewer.HelpCards.viewed(sim.state.tutorial,deck[0]),"A card advances on its own after its demonstration and reading time")
    var titles: Array=[viewer.current()]
    for i in range(10):
        if not viewer.visible:break
        check(not guide.pointer.visible,"No pointer on %s" % viewer.current())
        viewer.step(1)
        if viewer.visible:titles.append(viewer.current())
    await frames(3)
    check(titles==deck.slice(viewer.HelpCards.essential().find(titles[0])) and guide.pending==guide.ROAD_AHEAD_ID,"The rest of the overview, then The Road Ahead once: %s" % str(titles))
    game.banner.queue.clear();game.banner.current={};guide._process(float(sim.campaign.guided.rules().final_delay)+.1)
    guide.intro_button.pressed.emit();await frames(3)
    check(guide.pending=="","…which closes for good")

# ---------------------------------------------------------------- 5. None
func none_checks() -> void:
    print("-- None")
    fresh("none");await frames(4)
    var guide=game.guide
    # Change 22: The Road Ahead is None's only guidance (shown once, text only); Change 24 (UI-05)
    # removed the Auto-Claim pointer there, so nothing else ever appears.
    check(guide.pending==guide.ROAD_AHEAD_ID and guide.card.visible and not guide.pointer.visible,"None: The Road Ahead once, without a pointer")
    guide._process(float(sim.campaign.guided.rules().final_delay)+.1);guide.intro_button.pressed.emit();await frames(4)
    check(sim.state.tutorial.seen.has(guide.ROAD_AHEAD_ID) and not guide.card.visible,"…and it closes for good")
    var shown:=false
    var steps: Array=[func():sim.add_item("wood_sword"),func():sim.add_item("wood_sword"),func():sim.state.counters["merge"]=1,func():sim.state.main_claimed.append(0),func():sim.state.counters["upgrade"]=1,func():sim.state.counters["camp"]=1,func():sim.state.counters["supply_buy"]=1,func():snowman_defeated(),func():sim.state.upgrades["mission_claim"]=1]
    for s in steps:
        s.call();sim.campaign.onboarding.evaluate();await frames(4)
        if guide.card.visible or guide.pointer.visible:shown=true
    check(not shown,"None: no card, pointer or tip at any step after it (Auto Claim bought included)")
    check(sim.campaign.onboarding.all_revealed(),"…with every menu open throughout")
    check(map_node("Gate").visible or sim.campaign.gate_status().is_empty(),"The Next Stage objective chip shows in None")

# ---------------------------------------------------------------- 6. notification sounds
func audio_checks() -> void:
    print("-- notification sounds")
    fresh()
    SettingsState.set_mute_gameplay(false);SettingsState.set_mute_special(false);SettingsState.set_sfx_volume(1.0)
    var cues: Resource=game.audio_cues
    var stream_of:=func(id: String)->AudioStream:
        for c in cues.cues:
            if c.id==id:return c.stream
        return null
    var ready_stream: AudioStream=stream_of.call("mission_ready")
    check(ready_stream!=null and ready_stream.resource_path.ends_with("mission_ready.wav"),"mission_ready plays assets/sounds/mission_ready.wav")
    var same: Array=[]
    for id in ["main_ready","prestige_discovered","prestige_step","prestige_ready","feature_unlocked","mastery_objective","mastery_map"]:
        if stream_of.call(id)==ready_stream and AudioService.cue_category(id)=="special":same.append(id)
    check(same.size()==7,"Main objective, Prestige discovered/step/ready, feature, Mastery objective and map use it: %s" % str(same))
    check(stream_of.call("stage_unlocked").resource_path.ends_with("stage_clear.wav") and stream_of.call("game_complete").resource_path.ends_with("stage_clear.wav"),"A new map and 100% completion keep stage_clear")
    check(stream_of.call("prestiged").resource_path.ends_with("prestige.wav"),"Performing a Prestige keeps the Prestige sound")
    # Triggers through the real notice routing.
    sim.state.tutorial.mode="guided";AudioService.reset_history()
    sim.notice.emit("mission_ready","kill")
    check(AudioService.flush()=="","A mission ready while Missions is hidden (Guided) stays silent")
    sim.state.tutorial.mode="none";AudioService.reset_history();snowman_defeated()
    check(AudioService.flush()=="feature_unlocked","The Prestige reset becoming available (Snowman found) plays the notification")
    AudioService.reset_history()
    sim.state.counters["kill"]=5;sim.campaign.evaluate_main()
    check(AudioService.flush()=="main_ready","A main objective ready to claim plays it")
    sim.campaign.evaluate_main()
    check(AudioService.flush()=="","…once (not again while still waiting)")
    AudioService.reset_history()
    sim.notice.emit("mission_ready","kill")
    check(AudioService.flush()=="mission_ready","A mission ready to claim by hand plays it")
    # Two notifications a frame apart do not repeat the same sound.
    sim.notice.emit("feature_unlocked","enemy")
    check(AudioService.flush()=="","A second notification inside the shared cooldown is skipped (no double sound)")
    AudioService.reset_history()
    sim.notice.emit("feature_unlocked","enemy");sim.milestone.emit("stage","2")
    check(AudioService.flush()=="stage_unlocked","Same frame as a new map: one sound, the map's")
    AudioService.reset_history();snowman_defeated()
    sim.state.follow="";sim.milestone.emit("discovered","hunter_o1")
    check(AudioService.flush()=="prestige_discovered","Prestige discovered (after the reveal) plays the notification sound")
    AudioService.reset_history();sim.milestone.emit("ready","hunter_o1")
    check(AudioService.flush()=="prestige_ready","Opportunity ready plays it")
    AudioService.reset_history();sim.notice.emit("follow_step","hunter_o1")
    check(AudioService.flush()=="prestige_step","Followed step plays it")
    AudioService.reset_history();sim.notice.emit("mastery_objective","1:research")
    check(AudioService.flush()=="mastery_objective","Mastery category complete plays it")
    AudioService.reset_history();sim.notice.emit("mastery_map","1")
    check(AudioService.flush()=="mastery_map","A mastered map plays it")
    AudioService.reset_history();sim.notice.emit("game_complete","")
    check(AudioService.flush()=="game_complete","100% completion plays stage_clear")
    # Mutes and settings unchanged.
    SettingsState.set_mute_special(true);AudioService.reset_history()
    sim.notice.emit("feature_unlocked","world")
    check(AudioService.flush()=="","Mute special sounds silences them")
    SettingsState.set_mute_special(false);SettingsState.set_mute_gameplay(true);AudioService.reset_history()
    sim.notice.emit("feature_unlocked","world")
    check(AudioService.flush()=="feature_unlocked","…independently of Mute gameplay")
    var saved: Dictionary=SettingsState.to_save_dict()
    check(saved.has("mute_gameplay") and saved.has("mute_special") and saved.has("sfx_volume"),"Both mutes and the volume still saved")
    SettingsState.mute_all_sfx();AudioService.reset_history()

# ---------------------------------------------------------------- 7. Map Mastery
func complete_map(st: int) -> void:
    var m=sim.campaign.mastery
    var c: Dictionary=m.content(st)
    sim.state.mastery.explored[str(st)]=100
    var camps: Array=[]
    for i in range(sim.catalog.stages[st-1].spawns.size()):camps.append(i)
    sim.state.mastery.camps[str(st)]=camps
    for g in c.groups:
        sim.state.group_kills[g]=maxi(int(sim.state.group_kills[g]),m.hunt_target(g))
        sim.state.upgrades["reveal_stats:%d" % g]=1;sim.state.upgrades["reveal_drops:%d" % g]=1
    for id in c.items:sim.state.mastery.found[id]=true
    for id in c.outfits:sim.state.mastery.merge[id]=maxi(int(sim.state.mastery.merge.get(id,0)),m.outfit_target(st,id))
    sim.state.mastery.evolved[c.weapons[0]]=true
    # Change 51: Spring maps (Obsidian only) ask for one of their weapons at ^20 instead of an evolution.
    for id in c.weapons:sim.state.mastery.merge[id]=maxi(int(sim.state.mastery.merge.get(id,0)),int(sim.catalog.progression.evolution.required_merge))
func mastery_checks() -> void:
    print("-- Map Mastery")
    fresh()
    var m=sim.campaign.mastery
    var counts: Array=[]
    for st in range(1,9):
        var t: Array=[]
        for cat in m.CATEGORIES:t.append(int(m.objective(st,cat).total))
        counts.append(t)
    print("    category totals per map ",counts)
    # Change 51: the Snowman drops the Wood Axe (Winter I's own tier), so Winter I collects 6 items.
    check(counts[0]==[3,4,8,6,5],"Winter I: Explore 3 (100% + 2 camps), Hunt 4, Research 8, Collect 6, Forge 5 (4 outfits + 1 evolution)")
    check(m.hunt_target(0)==100 and m.hunt_target(group("boss-snowman"))==3,"Hunt = second kill achievement: 100 normal, 3 boss")
    check(m.outfit_target(1,"unit-blue-cap_outfit")==25 and m.outfit_target(1,"boss-snowman_outfit")==5,"Forge: normal outfits ^25, boss outfits ^5")
    check(m.map_percent(1)==0 and m.game_percent()==0,"Fresh: 0%")
    # Records follow play and only rise.
    sim.add_item("unit-blue-cap_outfit",30);sim.merge("unit-blue-cap_outfit",true)
    m.evaluate()
    check(sim.state.mastery.found.has("unit-blue-cap_outfit") and int(sim.state.mastery.merge["unit-blue-cap_outfit"])>=25,"Obtained items and best merge levels are recorded")
    var c1: Dictionary=m.content(1)
    # Change 51: one weapon tier per map, so a Wood Sword evolution counts on Winter I only.
    sim.state.items["wood_sword"]={"qty":102,"merge":100,"extras":{}} # fixture: evolution-ready
    var slot: int=sim.state.gear.find("")
    if slot>=0:sim.state.gear[slot]="wood_sword"
    check(sim.evolve("wood_sword"),"Wood Sword evolves")
    m.evaluate()
    var evolve_ok: Array=[]
    for st in [1,2]:evolve_ok.append(m.objective(st,"forge").parts[-1][2]==1)
    check(evolve_ok==[true,false] and sim.state.mastery.found.has("stone_sword"),"Its evolution counts for Winter I Forge (Winter II drops Stone); the Stone Sword counts as found")
    # Obsidian is shared by Spring I and Spring II.
    sim.state.mastery.found["obsidian_sword"]=true
    var shared_maps: Array=[]
    for st in range(1,9):
        if m.content(st).items.has("obsidian_sword"):shared_maps.append(st)
    check(shared_maps==[7,8] and shared_maps.all(func(st):return m.objective(st,"collect").parts.any(func(p):return p[1]=="obsidian_sword" and p[2]==1)),"A shared item counts in Collect on every map that drops it: %s" % str(shared_maps))
    # Complete Winter I.
    fresh();notices.clear();milestones.clear()
    var coins_before: float=sim.coin_reward(0)
    complete_map(1);m.evaluate()
    check(m.map_complete(1) and m.map_percent(1)==100,"Winter I: all five categories → 100%")
    # Shared winter items also count toward Winter II's Collect, so the game is a little past 1/8.
    check(m.game_percent()>=12 and m.game_percent()<25,"Game completion %d%%: one map mastered of eight (shared items add a little to Winter II)" % m.game_percent())
    var objective_notices: int=notices.filter(func(n):return n[0]=="mastery_objective").size()
    check(objective_notices==5 and notices.filter(func(n):return n[0]=="mastery_map").size()==1 and milestones.has(["mastery_map","1"]),"Five category notices, one map notice and one banner")
    m.evaluate()
    check(notices.filter(func(n):return n[0]=="mastery_objective").size()==5,"Evaluating again announces nothing twice")
    check(near(sim.campaign.bonus("gem_chance"),.02) and near(sim.coin_reward(0)/coins_before,1.0),"Winter I reward: +2 pts Gem Chance, applied once")
    # Partial maps read below 100.
    sim.state.mastery.explored["2"]=100
    check(m.map_percent(2)>0 and m.map_percent(2)<100,"A partial map reads between 0 and 99 (%d%%)" % m.map_percent(2))
    # All eight maps: every reward once, plus completion.
    var hp0: float=sim.stats().hp;var dmg0: float=sim.stats().damage;var xp0: float=sim.group_xp(0);var loot0: float=sim.gear_chance(0);var gem0: float=sim.gem_base_chance();var coin0: float=sim.coin_reward(0)
    for st in range(1,9):complete_map(st)
    milestones.clear();notices.clear()
    m.evaluate()
    check(m.game_complete() and m.game_percent()==100,"All eight maps → 100% game completion")
    check(milestones.has(["mastery_game",""]) and notices.has(["game_complete",""]),"100% is announced once (banner and sound)")
    var r: Dictionary=m.rewards()
    check(near(r.hp,.35) and near(r.damage,.35) and near(r.coins,.25) and near(r.xp,.35) and near(r.gear_chance,.01) and near(r.gem_chance,.07),"Reward totals: HP/damage/XP +35%%, Coins +25%%, Loot +1 pt, Gem +7 pts: %s" % str(r))
    sim.touch()
    check(near(sim.stats().hp/hp0,1.35) and near(sim.stats().damage/dmg0,1.35),"Max HP and damage ×1.35 exactly (no double application)")
    check(near(sim.group_xp(0)/xp0,1.35) and near(sim.coin_reward(0)/coin0,1.25),"XP ×1.35 and coins ×1.25")
    check(near(sim.gear_chance(0)-loot0,.01) and near(sim.gem_base_chance()-gem0,.05),"Loot Chance +1 point, Gem Chance +5 more points after Winter I")
    var breakdown: Dictionary=sim.stat_breakdown("hp")
    check(near(float(breakdown.multiplier),1.35) and near(float(breakdown.total),sim.stats().hp),"Stats breakdown shows the same multiplier the combat getter uses")
    # Prestige keeps everything; the run resets underneath.
    sim.state.explored.erase("1");sim.campaign.explore_cells(1,[Vector2i(1,1)])
    check(do_prestige(),"Prestige")
    check(m.game_complete() and m.map_complete(1) and m.objective(1,"explore").complete and sim.campaign.explored_percent(1)<100,"After Prestige: run exploration reset (%d%%), Mastery still 100%% (latched)" % sim.campaign.explored_percent(1))
    check(near(sim.campaign.bonus("hp"),.35) and near(sim.campaign.mastery.bonus("coins"),.25),"Rewards kept by Prestige")
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    sim.new_profile();sim.restore(snap)
    check(m.game_complete() and near(sim.campaign.bonus("damage"),.35),"Save/load keeps Mastery and its rewards")
    var bad: Dictionary=sim.snapshot();bad.mastery.found["no_such_item"]=true
    check(not sim.campaign.valid_snapshot(bad),"Validation rejects an unknown item in the records")
    check(SaveService.hard_reset() and sim.state.mastery.done.is_empty() and near(sim.campaign.bonus("hp"),0.0),"Hard Reset clears Mastery and its rewards")
    # Mastery is optional: campaign progress never depends on it.
    fresh()
    var boss: Dictionary=enemy(group("boss-snowman"))
    boss.hp=0;sim._kill(boss)
    check(int(sim.state.unlocked_stage)==2 and m.game_percent()<5,"Campaign progress needs no Mastery (Winter II opens at 0%)")

# ---------------------------------------------------------------- 8. reachable exploration
func reach_checks() -> void:
    print("-- reachable exploration")
    var rules=sim.campaign.fog_rules
    var mismatch: Array=[]
    for st in range(1,9):
        var cells: Array=sim.campaign.compute_unreachable_cells(sim.catalog.stages[st-1],st)
        var stored: Array=rules.unreachable_cells.get(st,[])
        if cells.size()!=stored.size() or not cells.all(func(c):return stored.has(c)):mismatch.append(st)
    check(mismatch.is_empty(),"Stored unreachable cells match a fresh flood fill on all eight maps")
    check(rules.unreachable_cells.keys()==[4] and rules.unreachable_cells[4].size()==4,"Only Summer II has unreachable cells (4, inside solid scenery)")
    fresh()
    var all_ok:=true;var details: Array=[]
    for st in range(1,9):
        # Walk every reachable point of the map (the reveal rule itself, not the stored list).
        sim.state.stage=st;sim.state.unlocked_stage=maxi(int(sim.state.unlocked_stage),st);sim._reset_world() # fixture
        var d: Dictionary=sim.catalog.stages[st-1]
        var step:=8.0
        var start:=Vector2i(roundi(float(d.spawns[0][0])/step),roundi(float(d.spawns[0][1])/step))
        var seen: Dictionary={start:true};var queue: Array=[start];var i:=0
        while i<queue.size():
            var n: Vector2i=queue[i];i+=1
            sim.campaign.reveal_circle(Vector2(n)*step,sim.campaign.fog_rules.player_radius)
            for o in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
                var mm: Vector2i=n+o
                if seen.has(mm):continue
                var p:=Vector2(mm)*step
                if p.x<14 or p.y<30 or p.x>float(d.size[0])-14 or p.y>float(d.size[1])-14 or sim.campaign.solid_at(p):continue
                seen[mm]=true;queue.append(mm)
        var pct: int=sim.campaign.explored_percent(st)
        details.append("%d:%d%%" % [st,pct])
        if pct!=100:all_ok=false
    check(all_ok,"Walking every reachable point reaches Map Explored 100%% on all eight maps (%s)" % ", ".join(details))
    check(sim.campaign.explore_area(4)==72*72-4,"Summer II's area excludes its 4 unreachable cells")

# ---------------------------------------------------------------- 9. panels
func ui_checks() -> void:
    print("-- panels")
    fresh();await frames(2)
    game._open("world");await frames(4)
    check(game.panel=="world" and game.guide._panel_control("mastery")!=null,"None: World offers Map Mastery before the Snowman (Change 25: menus open, rewards by the rules)")
    game._close()
    snowman_defeated()
    game._open("world");await frames(4)
    # Fix found by the suite: refreshing an open World panel must keep the map's player dot.
    sim.touch();game._refresh_panel();await frames(2);sim.touch();game._refresh_panel();await frames(2)
    var maps: Array=game.rows.find_children("*","Control",true,false).filter(func(n):return n.get_script()==preload("res://scripts/game/map_view.gd"))
    check(maps.size()==1 and is_instance_valid(maps[0].player_dot) and maps[0].player_dot.get_parent()==maps[0],"World map keeps its player dot through in-place panel refreshes")
    var entry: Button=game.guide._panel_control("mastery")
    check(entry!=null and entry.text==tr("MASTERY_OPEN") % sim.campaign.mastery.game_percent(),"World → \"%s\"" % (entry.text if entry else "-"))
    entry.pressed.emit();await frames(6)
    check(game.panel=="mastery" and labels_text(game.rows).contains(tr("MASTERY_GAME") % sim.campaign.mastery.game_percent()),"Map Mastery shows game completion")
    var text: String=labels_text(game.rows)
    var names_ok:=true
    for st in range(1,9):
        if not text.contains(str(sim.catalog.stages[st-1].name)):names_ok=false
    check(names_ok and text.contains(game.mastery_reward_text(sim.campaign.mastery.rules.map_rewards[0])) and text.contains(tr("MASTERY_NOT_REACHED")),"Eight maps with percent and reward; maps not reached say so")
    var details: Button=game.guide._panel_control("mastery_map_1",true)
    check(details!=null and game.guide._panel_control("mastery_map_3")==null,"Details only on reached maps")
    details.pressed.emit();await frames(6)
    var page: String=labels_text(game.rows)
    var cats_ok:=true
    for cat in sim.campaign.mastery.CATEGORIES:
        if not page.contains(tr("MASTERY_"+cat.to_upper())):cats_ok=false
    check(game.mastery_stage==1 and cats_ok,"Winter I page: Explore, Hunt, Research, Collect, Forge")
    check(page.contains(tr("MASTERY_UNKNOWN_ENEMY")) and not page.contains(str(sim.catalog.groups[2].name)),"Unmet enemies stay unnamed (\"Undiscovered enemy\")")
    sim.campaign.discover_spot(0,2);game._refresh_panel(true);await frames(4)
    check(labels_text(game.rows).contains(str(sim.catalog.groups[0].name)),"A discovered type is named in what remains")
    var rect: Rect2=game.sheet.get_global_rect()
    check(rect.size.x<=game.size.x+1 and game.rows.get_child_count()<=12,"Compact: one card per category within the sheet")
    game.guide._panel_control("mastery_back").pressed.emit();await frames(4)
    check(game.mastery_stage==0,"Back returns to all maps")
    game._close()
    game._open("stats");await frames(4)
    check(labels_text(game.rows).contains(tr("STATS_COMPLETION")),"Stats shows Game completion")
    game._close()
    complete_map(1);sim.campaign.mastery.evaluate()
    game._open("stats");await frames(4)
    check(labels_text(game.rows).contains(tr("STATS_MASTERY")) and labels_text(game.rows).contains("+2 pts Gem Chance"),"Stats lists the Mastery bonuses")
    game._close()
