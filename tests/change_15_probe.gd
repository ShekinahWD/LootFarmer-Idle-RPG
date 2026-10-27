extends Node
## Change 15 probe: the early equipment guarantee, the first-profile menu reveal (Guided, Basic, None,
## unexpected orders, persistence, Show all menus now), the notification sounds and Map Mastery
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

# ---------------------------------------------------------------- 2. menu reveal
func reveal_checks() -> void:
    print("-- menu reveal")
    fresh();await frames(4)
    var settings_x: float=nav("Settings").get_global_rect().position.x
    check(sim.state.onboarding.reveal.is_empty(),"Fresh profile: nothing revealed")
    var hidden_nav: bool=true
    for n in ["World","Missions","Prestige","Upgrades"]:
        if not (nav(n).disabled and nav(n).modulate.a==0.0 and nav(n).mouse_filter==Control.MOUSE_FILTER_IGNORE):hidden_nav=false
    check(hidden_nav,"World, Missions, Prestige and Upgrades buttons hidden and untouchable")
    check(nav("Settings").visible and not nav("Settings").disabled,"Settings always available")
    check(not map_node("MiniMap").visible and not map_node("Explored").visible and not map_node("Gate").visible,"Minimap, Map Explored and Next Stage hidden")
    check(not game.dock.get_node("Inventory/GearColumn/Head/Filters").visible,"Filters hidden")
    check(game.stick.visible and game.dock.get_node("Inventory/GearColumn/GearScroll/Gear").visible and game.top.get_node("Bar/Pause").visible,"Joystick, equipment dock and Pause available")
    for p in ["missions","world","upgrades","prestige","enemy","filters","camp","teleport","farming","mastery"]:
        game._open(p)
    check(game.panel=="" and not game.sheet.visible,"Every hidden panel refuses to open")
    game.world.actor_selected.emit(-1,2);game.world.actor_selected.emit(0,2);map_node("MiniMap").open_map.emit()
    check(game.panel=="","Character tap, enemy tap and minimap open nothing yet")
    game._open("settings");check(game.panel=="settings","Settings opens");game._open("stats");check(game.panel=="stats","Stats opens");game._close()
    # The chain, step by step, from demonstrated actions.
    sim.state.counters["merge"]=1;sim.campaign.onboarding.evaluate() # fixture: first merge
    check(sim.state.onboarding.reveal==["missions"] and notices.has(["feature_unlocked","missions"]),"First merge: Missions revealed (one notice)")
    sim.state.main_claimed.append(0);sim.campaign.onboarding.evaluate() # fixture: first claim
    check(sim.state.onboarding.reveal==["missions","enemy"],"First claim: enemy information and upgrades")
    sim.state.counters["upgrade"]=1;sim.campaign.onboarding.evaluate()
    check(sim.state.onboarding.reveal==["missions","enemy","world"],"First upgrade: World")
    sim.state.counters["camp"]=1;sim.campaign.onboarding.evaluate()
    check(sim.state.onboarding.reveal==["missions","enemy","world","upgrades"],"First camp: Player Upgrades")
    sim.state.gems=50;check(sim.buy_upgrade("gear_slots") and sim.state.onboarding.reveal.has("objective"),"First Player Upgrade purchase: the Snowman objective")
    check(not sim.campaign.onboarding.revealed("prestige"),"Prestige stays hidden before the Snowman")
    await frames(2);game._process(.2);await frames(2)
    check(map_node("Gate").visible and not nav("Prestige").visible==false and nav("Prestige").disabled,"Next Stage chip shows; Prestige button still hidden")
    check(is_equal_approx(nav("Settings").get_global_rect().position.x,settings_x),"Settings never moves while menus appear")
    check(not nav("Missions").disabled and nav("Missions").modulate.a==1.0 and nav("Missions/Badge").visible and nav("Missions/Badge").text in ["✦","!"],"Missions in place with its badge")
    snowman_defeated()
    check(sim.campaign.onboarding.all_revealed() and milestones.filter(func(m):return m[0]=="prestige_unlocked").size()==1,"Snowman: everything revealed with one Prestige banner")
    game._open("prestige")
    check(game.panel=="prestige","Prestige opens")
    check(sim.campaign.prestige_block_reason()=="NO_READY_PRESTIGE","…but the reset still needs a ready opportunity")
    game._close()
    # The same steps by player level only (a player who ignores every new menu).
    fresh()
    var by_level: Array=[]
    for level in [3,4,5,6,7]:
        sim.state.player_level=level;sim.campaign.onboarding.evaluate() # fixture: level
        by_level.append(sim.state.onboarding.reveal.size())
    check(by_level==[1,2,3,4,5],"Level backstops 3/4/5/6/7 reveal one system each: %s" % str(by_level))
    # Unexpected order: a full equipment row reveals everything up to Player Upgrades.
    fresh()
    for id in ["wood_sword","wood_axe","unit-blue-cap_outfit"]:sim.add_item(id) # fixture
    sim.campaign.onboarding.evaluate()
    check(sim.state.onboarding.reveal==["missions","enemy","world","upgrades"],"A full equipment row reveals up to Player Upgrades at once")
    # Unexpected order: the Snowman before anything else.
    fresh()
    snowman_defeated()
    check(sim.campaign.onboarding.all_revealed(),"Snowman first: every menu revealed regardless of earlier progress")
    # A real Snowman kill: the new map's banner first, then Prestige.
    fresh();milestones.clear()
    var boss: Dictionary=enemy(group("boss-snowman"))
    boss.hp=0;sim._kill(boss)
    var kinds: Array=milestones.map(func(m):return m[0])
    check(kinds.find("stage")>=0 and kinds.find("stage")<kinds.find("prestige_unlocked"),"Killing the Snowman: \"Winter II\" banner, then \"Prestige unlocked\" (%s)" % str(kinds))
    # Opportunities found before the reveal: tracked silently, announced by the reveal.
    fresh();milestones.clear();game.banner.queue.clear()
    sim.state.counters["kill:unit-blue-cap"]=10;sim.campaign.evaluate() # fixture: Expedition discovered
    await frames(2)
    check(sim.state.opportunities.has("expedition_o1") and game.banner.pending()==0 and not nav("Prestige/Badge").visible,"An opportunity found before the Snowman: tracked, no banner, no badge")
    snowman_defeated();await frames(2)
    var titles: Array=game.banner.queue.map(func(e):return e.title)+[game.banner.current.get("title","")]
    check(titles.count(tr("MILESTONE_PRESTIGE_UNLOCKED"))==1,"The reveal announces Prestige once (\"%s\")" % tr("MILESTONE_PRESTIGE_UNLOCKED"))
    # Persistence: save/load, Prestige, Hard Reset.
    fresh()
    sim.state.counters["merge"]=1;sim.campaign.onboarding.evaluate()
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    sim.new_profile();sim.restore(snap)
    check(sim.state.onboarding.reveal==["missions"] and sim.state.schema==8,"Reveals survive a JSON save/load (schema 8)")
    snowman_defeated()
    check(do_prestige() and sim.campaign.onboarding.all_revealed(),"Prestige keeps every revealed menu")
    check(SaveService.hard_reset() and sim.state.onboarding.reveal.is_empty(),"Hard Reset hides them again")
    var bad: Dictionary=sim.snapshot();bad.onboarding.reveal=["missions","missions"]
    check(not sim.campaign.valid_snapshot(bad),"Validation rejects a duplicated reveal")
    # Change 16 removes "Show all menus now" (and "Choose guidance again") from the player's Settings;
    # Help takes their place (change_16_probe). reveal_all stays for probes and is checked directly.
    fresh();notices.clear()
    game._open("settings");await frames(2)
    check(labels_text(game.rows).contains(tr("SECTION_TUTORIAL")) and game.guide._panel_control("show_all_menus")==null and buttons_text(game.rows).contains(tr("HELP")),"Settings → Tutorial and help offers Help, no Show all menus (Change 16)")
    game._close()
    sim.campaign.onboarding.reveal_all(true)
    check(sim.campaign.onboarding.all_revealed() and not notices.any(func(n):return n[0]=="feature_unlocked"),"reveal_all(silent) still reveals every menu, silently (probe use)")
    check(sim.campaign.prestige_block_reason()=="PRESTIGE_LOCKED_FIRST_BOSS","…the Prestige reset still needs the Snowman found")

# ---------------------------------------------------------------- 3. Guided
func guided_checks() -> void:
    print("-- Guided (Change 20 sequence)")
    fresh("guided");await frames(4)
    var guide=game.guide
    var flow=sim.campaign.guided
    check(guide.pending=="move" and guide.pointer.visible,"Guided starts with movement")
    for step in ["move","kill","collect","equip","close_equip","merge","close_merge"]:flow.mark(step)
    sim.state.counters.kill=5;sim.campaign.evaluate_main()
    sim.state.playtime_total=59;await frames(4)
    check(guide.pending=="" and not sim.campaign.onboarding.revealed("missions"),"Missions hidden during timed farming interval")
    sim.state.playtime_total=60;await frames(4)
    check(guide.pending=="missions" and guide.target==nav("Missions"),"Missions introduced after 60 seconds")
    game._nav("missions");await frames(6)
    var claim: Button=guide._panel_control("claim",true)
    check(claim!=null and guide.step=="missions_claim","Mission guide points at real claim")
    if claim!=null:claim.pressed.emit()
    await frames(6)
    check(guide.step=="close_panel" and guide.target==game.get_node("Sheet/Margin/Content/Header/Close"),"Claim asks to close panel")
    game._close();sim.state.playtime_total+=60;await frames(4)
    check(guide.pending=="player_upgrade" and sim.campaign.onboarding.revealed("upgrades"),"Player Upgrades introduced after close and delay")
    sim.state.coins=1000;game._open("upgrades");await frames(6)
    var buy: Button=guide._panel_control("buy_upgrade",true)
    check(buy!=null,"Player Upgrade has a real purchase target")
    if buy!=null:buy.pressed.emit()
    await frames(4)
    check(guide.step=="close_panel","Upgrade requires close")
    game._close();await frames(4)
    check(guide.pending=="camp" and guide.path_point!=Vector2.INF,"Camp lesson directs physical approach")
    # An unrelated panel hides guidance without changing its pending outcome.
    game._open("settings");await frames(4)
    check(guide.pending=="camp" and not guide.pointer.visible and not guide.card.visible,"Unrelated panel suspends presentation")
    game._close();await frames(4)
    check(guide.pending=="camp" and guide.pointer.visible,"Closing unrelated panel restores live direction")
    flow.mark("camp");sim.state.bosses_found.append("boss-snowman");await frames(4)
    check(guide.pending=="boss_preparation" and not flow.data().done.has("boss_preparation"),"Boss preparation waits for acknowledgement")
    guide.intro_button.pressed.emit();await frames(4)
    check(flow.data().done.has("boss_preparation") and guide.pending=="boss_farm","Acknowledged boss lesson advances to additional farming")
    check(sim.campaign.prestige_gate_reason()=="PRESTIGE_TUTORIAL_LOCKED","Guided Prestige remains blocked until final acknowledgement")

# ---------------------------------------------------------------- 4. Basic
func basic_checks() -> void:
    print("-- Basic")
    fresh("basic");await frames(4)
    var guide=game.guide
    check(guide.pending=="overview" and guide.card.visible and not guide.pointer.visible,"Basic: a concrete opening card, no pointer")
    check(tr("GUIDE_OVERVIEW_DETAIL").contains("joystick") and tr("GUIDE_MODE_BASIC").begins_with("Basic"),"The opening says how to walk, fight and collect; the mode is named Basic")
    guide.intro_button.pressed.emit();await frames(4)
    check(guide.pending=="","Got it: nothing more until something new happens")
    sim.add_item("wood_sword");await frames(4)
    check(guide.pending=="tip_equip" and guide.card.visible and not guide.pointer.visible,"First gear: a short equip tip (text only)")
    sim.equip("wood_sword");await frames(4)
    check(guide.pending!="tip_equip","Equipped: the tip is gone")
    sim.add_item("wood_sword");await frames(4)
    check(guide.pending=="tip_merge","A copy: the merge tip")
    sim.merge("wood_sword");sim.campaign.onboarding.evaluate();await frames(4)
    check(guide.pending=="feature_missions" and guide.title.text==tr("GUIDE_FEATURE_MISSIONS") and not guide.pointer.visible,"Missions revealed: one short card")
    guide._process(sim.campaign.onboarding.rules.card_seconds+1.0);await frames(2)
    check(sim.state.tutorial.seen.has("feature_missions"),"The card retires on its own after %d s on screen" % int(sim.campaign.onboarding.rules.card_seconds))
    snowman_defeated();await frames(4)
    var titles: Array=[]
    for i in range(8):
        if guide.pending=="":break
        titles.append(guide.pending)
        check(not guide.pointer.visible,"No pointer on %s" % guide.pending)
        guide.intro_button.pressed.emit();await frames(3)
    check(titles==["feature_enemy","feature_world","feature_upgrades","feature_objective","feature_prestige"],"One card per revealed system, in reveal order: %s" % str(titles))

# ---------------------------------------------------------------- 5. None
func none_checks() -> void:
    print("-- None")
    fresh("none");await frames(4)
    var guide=game.guide
    var shown:=false
    var steps: Array=[func():sim.add_item("wood_sword"),func():sim.add_item("wood_sword"),func():sim.state.counters["merge"]=1,func():sim.state.main_claimed.append(0),func():sim.state.counters["upgrade"]=1,func():sim.state.counters["camp"]=1,func():sim.state.counters["supply_buy"]=1,func():snowman_defeated()]
    for s in steps:
        s.call();sim.campaign.onboarding.evaluate();await frames(4)
        if guide.card.visible or guide.pointer.visible:shown=true
    check(not shown,"None: no card, pointer or tip at any step")
    check(sim.campaign.onboarding.all_revealed(),"…while the menus still appear through play")
    game._process(.2)
    check(nav("World/Badge").visible and nav("World/Badge").text=="✦","A newly revealed menu carries ✦ (status, not instruction)")
    game._open("world");game._close();game._process(.2)
    check(not nav("World/Badge").visible,"Opening it clears the ✦")
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
    AudioService.reset_history()
    sim.notice.emit("mission_ready","kill")
    check(AudioService.flush()=="","A mission ready while Missions is hidden stays silent")
    sim.state.counters["merge"]=1;sim.campaign.onboarding.evaluate()
    check(AudioService.flush()=="feature_unlocked","A feature revealed plays the notification")
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
    check(counts[0]==[3,4,8,7,5],"Winter I: Explore 3 (100% + 2 camps), Hunt 4, Research 8, Collect 7, Forge 5 (4 outfits + 1 evolution)")
    check(m.hunt_target(0)==100 and m.hunt_target(group("boss-snowman"))==3,"Hunt = second kill achievement: 100 normal, 3 boss")
    check(m.outfit_target(1,"unit-blue-cap_outfit")==25 and m.outfit_target(1,"boss-snowman_outfit")==5,"Forge: normal outfits ^25, boss outfits ^5")
    check(m.map_percent(1)==0 and m.game_percent()==0,"Fresh: 0%")
    # Records follow play and only rise.
    sim.add_item("unit-blue-cap_outfit",30);sim.merge("unit-blue-cap_outfit",true)
    m.evaluate()
    check(sim.state.mastery.found.has("unit-blue-cap_outfit") and int(sim.state.mastery.merge["unit-blue-cap_outfit"])>=25,"Obtained items and best merge levels are recorded")
    var c1: Dictionary=m.content(1)
    # Shared weapons: one Wood Sword evolution counts on both winter maps.
    sim.state.items["wood_sword"]={"qty":102,"merge":100,"extras":{}} # fixture: evolution-ready
    var slot: int=sim.state.gear.find("")
    if slot>=0:sim.state.gear[slot]="wood_sword"
    check(sim.evolve("wood_sword"),"Wood Sword evolves")
    m.evaluate()
    var evolve_ok: Array=[]
    for st in [1,2]:evolve_ok.append(m.objective(st,"forge").parts[-1][2]==1)
    check(evolve_ok==[true,true] and sim.state.mastery.found.has("stone_sword"),"Its evolution counts for Winter I and Winter II Forge; the Stone Sword counts as found")
    var stone_maps: Array=[]
    for st in range(1,9):
        if m.content(st).items.has("stone_sword"):stone_maps.append(st)
    check(stone_maps.size()>=2 and stone_maps.all(func(st):return m.objective(st,"collect").parts.any(func(p):return p[1]=="stone_sword" and p[2]==1)),"A shared item counts in Collect on every map that drops it: %s" % str(stone_maps))
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
    check(near(sim.campaign.bonus("coins"),.1) and near(sim.coin_reward(0)/coins_before,1.1),"Winter I reward: +10% coins, applied once (×1.10)")
    # Partial maps read below 100.
    sim.state.mastery.explored["2"]=100
    check(m.map_percent(2)>0 and m.map_percent(2)<100,"A partial map reads between 0 and 99 (%d%%)" % m.map_percent(2))
    # All eight maps: every reward once, plus completion.
    var hp0: float=sim.stats().hp;var dmg0: float=sim.stats().damage;var xp0: float=sim.group_xp(0);var loot0: float=sim.gear_chance(0);var gem0: float=sim.gem_base_chance();var coin0: float=sim.coin_reward(0)/1.1
    for st in range(1,9):complete_map(st)
    milestones.clear();notices.clear()
    m.evaluate()
    check(m.game_complete() and m.game_percent()==100,"All eight maps → 100% game completion")
    check(milestones.has(["mastery_game",""]) and notices.has(["game_complete",""]),"100% is announced once (banner and sound)")
    var r: Dictionary=m.rewards()
    check(near(r.hp,.35) and near(r.damage,.35) and near(r.coins,.35) and near(r.xp,.35) and near(r.gear_chance,.01) and near(r.gem_chance,.02),"Reward totals: HP/damage/coins/XP +35%%, Loot +1 pt, Gem +2 pts: %s" % str(r))
    sim.touch()
    check(near(sim.stats().hp/hp0,1.35) and near(sim.stats().damage/dmg0,1.35),"Max HP and damage ×1.35 exactly (no double application)")
    check(near(sim.group_xp(0)/xp0,1.35) and near(sim.coin_reward(0)/coin0,1.35),"XP and coins ×1.35")
    check(near(sim.gear_chance(0)-loot0,.01) and near(sim.gem_base_chance()-gem0,.02),"Loot Chance +1 point, Gem Chance +2 points")
    var breakdown: Dictionary=sim.stat_breakdown("hp")
    check(near(float(breakdown.multiplier),1.35) and near(float(breakdown.total),sim.stats().hp),"Stats breakdown shows the same multiplier the combat getter uses")
    # Prestige keeps everything; the run resets underneath.
    sim.state.explored["1"]={"1,1":true}
    check(do_prestige(),"Prestige")
    check(m.game_complete() and m.map_complete(1) and m.objective(1,"explore").complete and sim.campaign.explored_percent(1)<100,"After Prestige: run exploration reset (%d%%), Mastery still 100%% (latched)" % sim.campaign.explored_percent(1))
    check(near(sim.campaign.bonus("hp"),.35) and near(sim.campaign.mastery.bonus("coins"),.35),"Rewards kept by Prestige")
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
    sim.state.counters["merge"]=1;sim.state.main_claimed.append(0);sim.state.counters["upgrade"]=1;sim.campaign.onboarding.evaluate() # fixture: World revealed
    game._open("world");await frames(4)
    check(game.panel=="world" and button_with(game.rows,tr("MASTERY_OPEN").split("·")[0].strip_edges())==null,"Before the Snowman, World has no Map Mastery entry")
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
    check(labels_text(game.rows).contains(tr("STATS_MASTERY")) and labels_text(game.rows).contains("+10% coins"),"Stats lists the Mastery bonuses")
    game._close()
