extends "res://tests/change_20_probe.gd"
## Change 25: three genuinely different onboarding modes and the final mobile UI pass.
## - Basic/None: every ordinary menu usable the moment the mode is chosen (navigation, direct paths),
##   silently, with Large inventory slots; opening a menu grants nothing (stages, camps, purchases,
##   Prestige reset, Mastery rewards keep their rules).
## - Basic: the short overview deck (3-5 cards, Skip, no pointer), then The Road Ahead once; nothing
##   after. None: The Road Ahead only. Guided: the staged reveal, pointers and 15 s waits unchanged.
## - Slot size: set on the first choice only; reload, Prestige and Hard Reset never force it again.
## - Android Back / Escape priority and de-duplication; responsive HUD at portrait sizes.
## Runs with --first-run-complete; each mode test starts from a real chooser state (fixture: reveal
## and seen cleared as on a profile created without the probe flag).
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    await access_checks()
    await zoom_checks()
    await basic_checks()
    await none_checks()
    await guided_checks()
    await back_checks()
    await layout_checks()
    version_checks()
    print("CHANGE_25_CHECKS %d FAILURES %d" % [checks,failures])
    get_window().size=Vector2i(720,1280)
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

var notices: Array=[]
var milestones: Array=[]
## A profile at the guide chooser, exactly as a first launch (no probe reveal fixture).
func chooser() -> void:
    get_tree().paused=false
    sim.new_profile();sim.set_physics_process(false)
    sim.state.onboarding.reveal=[];sim.state.tutorial.seen=[];sim.state.tutorial.mode="pending"
    game._close();game._cancel_confirm();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear()
    notices.clear();milestones.clear();AudioService.reset_history()
func choose(mode: String) -> void:
    chooser();await frames(2)
    game.guide.choose(mode);await frames(4);game._process(.2)
func nav(name: String) -> Control:return game.dock.get_node("Navigation/"+name)
func map_node(path: String) -> Control:return game.get_node("Safe/Layout/Map/"+path)
func labels_text(root: Node) -> String:
    return " | ".join(root.find_children("*","Label",true,false).map(func(l):return l.text))
func usable(c: Control) -> bool:
    return c.is_visible_in_tree() and not (c is BaseButton and c.disabled) and c.modulate.a>=1.0 and c.mouse_filter!=Control.MOUSE_FILTER_IGNORE
func refresh_hud() -> void:
    game._refresh_reveal();game._refresh_badges();game._refresh_follow_tracker();game._refresh_mission_tracker();game._layout_trackers()
    game._refresh_explored();game._refresh_mastery_chip();game._refresh_gate();game._refresh_objective()
func progress_record() -> Dictionary:
    return {"stage":sim.state.stage,"unlocked":sim.state.unlocked_stage,"camps":sim.state.camps.duplicate(true),"upgrades":sim.state.upgrades.duplicate(true),
        "coins":sim.state.coins,"gems":sim.state.gems,"found":sim.state.bosses_found.duplicate(),"cards":sim.state.owned_cards.duplicate(),
        "explored":sim.campaign.explored_count(1),"opportunities":sim.state.opportunities.duplicate(true),"mastery":JSON.stringify(sim.state.get("mastery",{}))}
func do_prestige() -> bool:
    var g: int=sim.campaign.prestige_unlock_group()
    sim.state.group_kills[g]=maxi(1,int(sim.state.group_kills[g])) # fixture: the Snowman defeated once
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    return sim.campaign.begin_prestige() and sim.prestige(sim.campaign.offered_cards()[0])

# ---------------------------------------------------------------- 1. menus open, content not granted
func access_checks() -> void:
    sim.notice.connect(func(kind: String,id: String)->void:notices.append([kind,id]))
    sim.milestone.connect(func(kind: String,id: String)->void:milestones.append([kind,id]))
    chooser();await frames(4);game._process(.2)
    var hidden:=true
    for n in ["World","Missions","Prestige","Upgrades"]:
        if usable(nav(n)):hidden=false
    check(hidden and game.guide.chooser.visible and game.guide.blocker.visible,"At the chooser nothing is open yet")
    for mode in ["basic","none"]:
        chooser();await frames(2)
        var before:=progress_record()
        game.guide.choose(mode);await frames(4);game._process(.2);refresh_hud()
        var all_nav:=true
        for n in ["World","Missions","Prestige","Upgrades","Settings"]:
            if not usable(nav(n)):all_nav=false
        check(all_nav,"%s: World, Missions, Prestige, Upgrades and Settings usable at once" % mode)
        check(map_node("MiniMap").visible and map_node("Explored").visible and map_node("Gate").visible and map_node("Mastery").visible,"%s: minimap, Map Explored, Next Stage and Mastery chips on the HUD" % mode)
        check(game.dock.get_node("Inventory/GearColumn/Head/Filters").visible,"%s: Filters available" % mode)
        var opened: Array=[]
        for p in ["missions","world","upgrades","prestige","filters","mastery","farming","stats","settings","help","history"]:
            game._open(p);await frames(1)
            if game.panel==p and game.sheet.visible:opened.append(p)
            game._close()
        check(opened.size()==11,"%s: every ordinary panel opens: %s" % [mode,str(opened)])
        game.world.actor_selected.emit(-1,2);await frames(1)
        check(game.panel=="upgrades","%s: tapping the character opens Player Upgrades" % mode)
        game._close();map_node("MiniMap").open_map.emit();await frames(1)
        check(game.panel=="world","%s: the minimap opens World" % mode)
        game._close();map_node("Mastery").pressed.emit();await frames(1)
        check(game.panel=="mastery","%s: the Mastery chip opens Map Mastery" % mode)
        game._close();game.banner.opened.emit("prestige_unlocked");await frames(1)
        check(game.panel=="prestige","%s: a Prestige banner opens Prestige" % mode)
        # Opening is not granting.
        var after:=progress_record()
        check(JSON.stringify(after)==JSON.stringify(before),"%s: choosing the mode and opening every menu changed no progress, currency, discovery or reward" % mode)
        check(sim.campaign.prestige_block_reason()=="PRESTIGE_LOCKED_FIRST_BOSS","%s: the Prestige reset still needs the Snowman found" % mode)
        game._open("prestige");await frames(2)
        var begin: Button=button("begin_prestige")
        check(begin!=null and begin.disabled and labels_text(game.rows).contains("✗ "+tr("PRESTIGE_REQ_BOSS")),"%s: Prestige shows the locked reset and its missing requirement" % mode)
        game._close();game._open("world");await frames(2)
        check(button("travel_stage_2")==null and int(sim.state.unlocked_stage)==1,"%s: World offers no travel to an unopened stage" % mode)
        game._close()
        check(not notices.any(func(n):return n[0]=="feature_unlocked") and AudioService.flush()!="feature_unlocked","%s: no unlock sound for the open menus" % mode)
        refresh_hud()
        check(not nav("World/Badge").visible and not nav("Upgrades/Badge").visible and not (nav("Prestige/Badge").visible and nav("Prestige/Badge").text=="✦"),"%s: no ✦ cascade on the open menus" % mode)
        # Undiscovered enemies stay unknown: the enemy chips need a discovered type.
        var g: int=game.combat_group
        check(map_node("EnemyUpgrades").visible==sim.campaign.discovered(g),"%s: enemy chips follow discovery, not the open menus" % mode)
        # Finding the Snowman: the reset becomes available, announced once.
        sim.state.bosses_found.append("boss-snowman");sim.campaign.onboarding.evaluate();sim.campaign.onboarding.evaluate()
        check(milestones.filter(func(m):return m[0]=="prestige_unlocked").size()==1 and sim.campaign.prestige_gate_reason()=="","%s: finding the Snowman announces the Prestige reset once" % mode)
        # Saved and reloaded.
        sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())));await frames(2);game._process(.2)
        check(sim.state.tutorial.mode==mode and usable(nav("World")) and usable(nav("Prestige")) and sim.campaign.onboarding.all_revealed(),"%s: still fully open after a JSON save/load" % mode)

# ---------------------------------------------------------------- 2. slot size
func zoom_checks() -> void:
    for mode in ["basic","none"]:
        SettingsState.set_inventory_zoom(0)
        await choose(mode)
        check(SettingsState.inventory_zoom==2,"%s: the first choice starts with Large slots (from Small)" % mode)
        SettingsState.set_inventory_zoom(1)
        var saved: Dictionary=SettingsState.to_save_dict()
        sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())));SettingsState.from_save_dict(saved);await frames(2)
        check(SettingsState.inventory_zoom==1,"%s: a later size change survives reload" % mode)
        check(do_prestige() and SettingsState.inventory_zoom==1 and sim.state.tutorial.mode==mode,"%s: …and Prestige (mode kept)" % mode)
        check(SaveService.hard_reset() and sim.state.tutorial.mode=="pending" and SettingsState.inventory_zoom==1,"%s: Hard Reset returns to the chooser and keeps settings" % mode)
        game.guide.choose(mode);await frames(2)
        check(SettingsState.inventory_zoom==2,"%s: choosing again after Hard Reset sets Large again (deterministic first choice)" % mode)
    SettingsState.set_inventory_zoom(0)
    await choose("guided")
    check(SettingsState.inventory_zoom==0,"Guided keeps the current slot size")
    SettingsState.set_inventory_zoom(2)
    # Each density lays out all 70 slots and keeps the grid scrollable.
    sim.state.upgrades.gear_slots=67;sim.state.gear.resize(sim.equipment_slot_count());sim.state.gear.fill("")
    sim.state.onboarding.reveal=sim.campaign.onboarding.FEATURES.duplicate()
    var grid: GridContainer=game.dock.get_node("Inventory/GearColumn/GearScroll/Gear")
    var scroll: ScrollContainer=game.dock.get_node("Inventory/GearColumn/GearScroll")
    for z in [0,1,2]:
        SettingsState.set_inventory_zoom(z);game._refresh_slots();await frames(3);game._layout_inventory();await frames(2)
        check(grid.get_child_count()==70 and scroll.get_v_scroll_bar().max_value>scroll.size.y,"Slot size %d: 70 slots, scrollable" % z)
        check(game.dock.get_node("Inventory/SupplyColumn/SupplyScroll/Supplies").get_child_count()==sim.state.supplies.size(),"Slot size %d: every supply slot laid out (%d)" % [z,sim.state.supplies.size()])
    SettingsState.set_inventory_zoom(2)

# ---------------------------------------------------------------- 3. Basic overview
func basic_checks() -> void:
    await choose("basic")
    var guide=game.guide
    var deck: Array=guide.BASIC_DECK
    check(deck.size()>=3 and deck.size()<=5,"Basic: an overview of %d cards (3-5)" % deck.size())
    var texts_ok:=true
    for id in deck:
        var t: String=tr("GUIDE_"+id.to_upper());var d: String=tr("GUIDE_"+id.to_upper()+"_DETAIL")
        if t.begins_with("GUIDE_") or d.begins_with("GUIDE_") or d.length()>220:texts_ok=false
    check(texts_ok,"Every overview card has a short title and text (≤220 characters)")
    check(guide.pending==deck[0] and guide.card.visible and not guide.pointer.visible and not guide.highlight.visible,"The first card shows, text only")
    check(guide.title.text.ends_with("1/%d" % deck.size()) and guide.skip_button.visible and guide.intro_button.visible,"It counts the deck and offers Skip and Got it")
    check(guide.card.mouse_filter==Control.MOUSE_FILTER_IGNORE and not guide.blocker.visible and not sim.suspended,"The card blocks nothing (no modal, the game runs)")
    game._open("missions");await frames(2)
    check(game.panel=="missions" and not guide.card.visible,"A menu opens while it is pending (the card waits)")
    game._close();await frames(2)
    guide.intro_button.pressed.emit();await frames(3)
    check(guide.pending==deck[1] and sim.state.tutorial.seen.has(deck[0]),"Got it: the next card")
    guide.skip_button.pressed.emit();await frames(3)
    check(deck.all(func(id):return sim.state.tutorial.seen.has(id)) and guide.pending==guide.ROAD_AHEAD_ID,"Skip: the rest of the deck retires; The Road Ahead follows")
    check(not guide.skip_button.visible and not guide.pointer.visible and guide.final_backdrop.visible,"The Road Ahead: centred, no Skip, no pointer")
    guide.intro_button.pressed.emit()
    check(not sim.state.tutorial.seen.has(guide.ROAD_AHEAD_ID),"…which keeps its non-auto-dismiss delay")
    game.banner.queue.clear();game.banner._finish()
    guide._process(float(sim.campaign.guided.rules().final_delay)+.1);guide.evaluate();guide._present()
    guide.intro_button.pressed.emit();await frames(3)
    check(sim.state.tutorial.seen.has(guide.ROAD_AHEAD_ID) and guide.pending=="","…then closes once")
    var shown:=false
    var events: Array=[func():sim.add_item("wood_sword",2),func():sim.merge("wood_sword"),func():sim.state.counters["camp"]=1,
        func():sim.state.player.hp=1,func():sim.state.upgrades["mission_claim"]=1,func():sim.state.bosses_found.append("boss-snowman"),
        func():sim.state.upgrades["focus:0"]=1;sim.campaign.focus_hint=0]
    for e in events:
        e.call();sim.campaign.onboarding.evaluate();await frames(3)
        if guide.card.visible or guide.pointer.visible or guide.highlight.visible:shown=true
    check(not shown,"Basic: no later cards, tips or pointers (gear, merge, camp, low health, Auto Claim, Snowman, Focus)")
    sim.state.player.hp=sim.stats().hp
    var seen: Array=sim.state.tutorial.seen.duplicate()
    game._open("settings");await frames(2);game._open("help");await frames(2)
    var text: String=labels_text(game.rows)
    check(deck.all(func(id):return text.contains(tr("GUIDE_"+id.to_upper()))),"Help shows the same overview cards")
    game._close();await frames(2)
    check(sim.state.tutorial.seen==seen and guide.pending=="","Reading Help repeats nothing")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())));await frames(3)
    check(guide.pending=="" and not guide.card.visible,"No repeat after save/load")
    check(do_prestige(),"Prestige");await frames(3)
    check(guide.pending=="" and not guide.card.visible and sim.state.tutorial.mode=="basic","No repeat after Prestige")
    # Each card also retires on its own after its time on screen.
    await choose("basic")
    guide._process(sim.campaign.onboarding.rules.card_seconds+.5);await frames(2)
    check(sim.state.tutorial.seen.has(deck[0]) and guide.pending==deck[1],"A card advances after %d s on screen" % int(sim.campaign.onboarding.rules.card_seconds))
    # A skip on the last card is Got it (no Skip shown there); The Road Ahead still follows.
    for id in deck.slice(0,deck.size()-1):sim.state.tutorial.seen.append(id)
    await frames(2)
    check(guide.pending==deck.back() and not guide.skip_button.visible,"The last card offers Got it only")

# ---------------------------------------------------------------- 4. None
func none_checks() -> void:
    await choose("none")
    var guide=game.guide
    check(guide.pending==guide.ROAD_AHEAD_ID and guide.card.visible and guide.final_backdrop.visible and not guide.pointer.visible,"None: The Road Ahead right after the choice")
    game.banner.queue.clear();game.banner._finish()
    guide._process(float(sim.campaign.guided.rules().final_delay)+.1);guide.evaluate();guide._present()
    guide.intro_button.pressed.emit();await frames(3)
    var shown:=false
    var events: Array=[func():sim.add_item("wood_sword",2),func():sim.merge("wood_sword"),func():sim.state.counters["camp"]=1,
        func():sim.state.player.hp=1,func():sim.state.upgrades["mission_claim"]=1,func():sim.state.bosses_found.append("boss-snowman"),
        func():sim.state.stage=2;sim.state.unlocked_stage=2]
    for e in events:
        e.call();sim.campaign.onboarding.evaluate();await frames(3)
        if guide.card.visible or guide.pointer.visible or guide.highlight.visible:shown=true
    check(not shown and guide.pending=="","None: nothing instructional afterwards")
    sim.state.player.hp=sim.stats().hp
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())));await frames(3)
    check(guide.pending=="","No Road Ahead repeat after reload")

# ---------------------------------------------------------------- 5. Guided unchanged
func guided_checks() -> void:
    await choose("guided")
    var guide=game.guide
    var flow=sim.campaign.guided
    check(not usable(nav("World")) and not usable(nav("Missions")) and not usable(nav("Prestige")) and not usable(nav("Upgrades")),"Guided: menus still appear one at a time")
    check(guide.pending=="move" and guide.pointer.visible,"Guided: the first lesson points")
    check(flow.STEPS.size()==28 and is_equal_approx(float(flow.rules().mission_delay),15.0) and is_equal_approx(float(flow.rules().upgrade_delay),15.0),"Guided: 28 steps and two 15 s active waits")
    for step in ["move","kill","collect","equip","close_equip","merge","close_merge"]:flow.mark(step)
    flow.advance_waits(14.9)
    check(flow.next_step()=="mission_wait" and not sim.campaign.onboarding.revealed("missions"),"Missions wait the full 15 s")
    flow.advance_waits(.1)
    check(flow.next_step()=="missions" and sim.campaign.onboarding.revealed("missions"),"…and open at 15 s")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
    check(sim.campaign.onboarding.revealed("missions") and not sim.campaign.onboarding.revealed("world") and sim.state.tutorial.mode=="guided","Partial Guided progress survives reload")

# ---------------------------------------------------------------- 6. Android Back / Escape
func back_checks() -> void:
    check(ProjectSettings.get_setting("application/config/quit_on_go_back")==false,"Back never quits the app silently (quit_on_go_back off)")
    await choose("none");sim.state.tutorial.seen.append("road_ahead");await frames(2)
    var confirm: Control=game.get_node("Confirm")
    game._open("missions");await frames(2)
    game._confirm("probe",func()->void:pass);await frames(3)
    game.back();await frames(1)
    check(not confirm.visible and game.sheet.visible and game.panel=="missions","Back 1: cancels the confirmation, the panel stays")
    game.back();await frames(1)
    check(not game.sheet.visible,"Back 2: closes the panel")
    game.back();await frames(3)
    check(confirm.visible and game.get_node("Confirm/Panel/Margin/Content/Title").text==tr("EXIT_TITLE") and game.confirm_action.get_method()=="_quit","Back 3 on the bare HUD: an exit confirmation (never a silent quit)")
    game.back();await frames(1)
    check(not confirm.visible,"Back 4: cancels it and play goes on")
    game._open("upgrades");await frames(2)
    game.back();game.back();await frames(2)
    check(not game.sheet.visible and not confirm.visible,"Two Back events in one frame act once")
    game._open("stats");await frames(2)
    game.notification(NOTIFICATION_WM_GO_BACK_REQUEST);await frames(2)
    check(not game.sheet.visible,"The Android notification closes the panel")
    game._open("stats");await frames(2)
    var esc:=InputEventKey.new();esc.keycode=KEY_ESCAPE;esc.physical_keycode=KEY_ESCAPE;esc.pressed=true
    game._unhandled_key_input(esc);await frames(2)
    check(not game.sheet.visible,"Escape (ui_cancel) uses the same handler")
    var prestige_confirm: Control=game.get_node("PrestigeConfirm")
    game._open("prestige");await frames(1);prestige_confirm.show();await frames(1)
    game.back();await frames(1)
    check(not prestige_confirm.visible and game.sheet.visible,"The Prestige confirmation closes before its panel")
    game._close()
    chooser();await frames(3)
    game.back();await frames(3)
    check(not confirm.visible and game.guide.chooser.visible,"At the chooser Back does nothing")

# ---------------------------------------------------------------- 7. portrait layouts
func layout_checks() -> void:
    for shape in [Vector2i(540,960),Vector2i(432,960),Vector2i(360,640)]:
        get_window().size=shape
        await choose("basic");sim.state.tutorial.seen.append_array(game.guide.BASIC_DECK);sim.state.tutorial.seen.append("road_ahead")
        sim.state.follow_mission="main:0" # fixture: a followed objective
        sim.state.opportunities["hunter_o1"]={"ready":false,"baseline":{},"step":0,"count":0};sim.state.follow="hunter_o1" # fixture: a followed opportunity
        await frames(6);refresh_hud();await frames(2)
        var map: Rect2=game.get_node("Safe/Layout/Map").get_global_rect()
        var stick: Rect2=map_node("Joystick").get_global_rect()
        var ok:=map.encloses(stick)
        for t in ["FollowTracker","MissionTracker"]:
            var r: Rect2=map_node(t).get_global_rect()
            if map_node(t).visible and (r.intersects(stick) or not map.grow(1).encloses(r)):ok=false
        check(ok and map_node("MissionTracker").visible and map_node("FollowTracker").visible,"%s: both trackers sit above the joystick, inside the map" % str(shape))
        var cluster:=true
        for c in ["MiniMap","Explored","Gate","Mastery"]:
            if map_node(c).visible and not map.grow(1).encloses(map_node(c).get_global_rect()):cluster=false
        check(cluster,"%s: the map cluster stays on screen" % str(shape))
        game._open("prestige");await frames(4)
        var sheet: Rect2=game.sheet.get_global_rect()
        var close: Control=game.get_node("Sheet/Margin/Content/Header/Close")
        var view: Rect2=game.get_global_rect()
        check(view.grow(1).encloses(sheet) and view.encloses(close.get_global_rect()) and close.size.y>=44,"%s: the sheet and its Close fit the screen" % str(shape))
        var headers: Array=game.rows.find_children("*","Button",true,false).filter(func(b):return b.has_meta("prestige_stage"))
        check(not headers.is_empty() and headers.all(func(b):return b.size.y>=44 and b.get_theme_font_size("font_size")>=16),"%s: Prestige stage headers are touch-sized and readable" % str(shape))
        var pinned: Button=button("begin_prestige")
        check(pinned!=null and view.encloses(pinned.get_global_rect()),"%s: the pinned Prestige action stays reachable" % str(shape))
        game._close()
        game._confirm("A longer confirmation message that has to wrap over several lines on a narrow portrait screen without leaving it.",func()->void:pass);await frames(4)
        check(view.encloses(game.get_node("Confirm/Panel").get_global_rect()),"%s: a confirmation fits the screen" % str(shape))
        game._cancel_confirm()
        await choose("basic");await frames(4)
        var card: Rect2=game.guide.card.get_global_rect()
        check(game.guide.card.visible and map.grow(1).encloses(card) and not card.intersects(stick),"%s: the Basic card fits the map above the joystick" % str(shape))
    get_window().size=Vector2i(720,1280);await frames(4)

func version_checks() -> void:
    # Change 26: later batches raise both numbers together (exact match lives in the newest probe).
    var version:=int(str(ProjectSettings.get_setting("application/config/version")))
    check(version>=25,"Project version is at least 25 (Change 25)")
    var presets:=FileAccess.get_file_as_string("res://export_presets.cfg")
    var release:=presets.substr(presets.find("name=\"Android Release\""))
    release=release.substr(0,release.find("[preset.1]"))
    check(release.contains("version/code=%d" % version) and release.contains("version/name=\"\""),"Android Release version code equals the project version, name inherited")
