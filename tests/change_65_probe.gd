extends Node
## Change 65 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## - Focused Farming: one global 25-Gem Player upgrade read by sim.focus(); Farm works on two enemy types
##   and two maps at no further cost; a group-scoped purchase is refused; locked / undiscovered spots are
##   refused; movement stops farming; enemy automation stays per type at its price; the enemy panel keeps
##   Farm (locked with a way to Player Upgrades) and lists no Focus purchase; migration of 0 / 1 / many
##   legacy per-type records, the hybrid case and a repeated load; Prestige keeps it; Hard Reset clears it.
## - Tutorial cards: one 14-card registry (8 essential), keys, word caps, one category each, 14 demos that
##   animate, restart on switching, stop when hidden and change no game state.
## - Help: landing, topics, category cards, Read All, Previous/Next, Back to Topics, Close, Auto-Advance
##   (off by default, persisted, never wraps), Viewed marks and the last card survive a reload.
## - Modes: Basic opening (8 cards in the viewer, world held, Skip, Finish, resume, legacy decks), None
##   (only the chooser line), Guided (finale line), Help never touches Guided lessons.
## - Guided first attack: no unattended player attack before the gesture; the real hit on the chosen
##   enemy finishes the lesson and turns autoattack on, with one explanation; death of the target,
##   movement, reloads, the empty-map escape and older profiles; Basic and None never gated.
const HelpCards=preload("res://scripts/game/help_cards.gd")
var checks:=0
var failures:=0
var game
var sim
var guide
var viewer
var events: Array=[]
## Damage the player dealt to enemies (sim.feedback for non-player actors).
var hits:=0
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")
func fresh(mode:="none") -> void:
    get_tree().paused=false
    if viewer.visible:viewer.hide()
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode=mode
    if mode!="guided":sim.campaign.onboarding.reveal_all(true)
    if mode=="basic":HelpCards.progress(sim.state.tutorial).basic_done=true # fixture: opening finished
    game._close();game.toast_queue.clear();game.get_node("Toast").hide()
    game.get_node("PrestigeConfirm").close();game._cancel_confirm()
    sim.state.player.quiet=1e9
    for e in sim.state.enemies:e.aggro=false
    sim.campaign.focus_hint=-1;sim.clear_target()
    events.clear()
func run() -> void:
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;guide=game.guide;viewer=game.help_viewer
    sim.event.connect(func(key: String)->void:events.append(key))
    sim.feedback.connect(func(id: String,_amount: float,_crit: bool)->void:if id!="player":hits+=1)
    await frames()
    await focus_checks()
    await migration_checks()
    await registry_checks()
    await demo_checks()
    await help_checks()
    await mode_checks()
    await first_attack_checks()
    print("CHANGE_65_CHECKS %d FAILURES %d" % [checks,failures])
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- helpers
func button_meta(root: Node,key: String) -> Button:
    for b in root.find_children("*","Button",true,false):
        if b.get_meta("guide","")==key and not b.is_queued_for_deletion() and b.is_visible_in_tree():return b
    return null
func upgrade_buttons(id: String) -> Array:
    return game.action_buttons.filter(func(i):return i.id==id and is_instance_valid(i.node) and not i.node.is_queued_for_deletion())
func stage_groups(st: int) -> Array:
    var out: Array=[]
    for g in sim.catalog.stages[st-1].groups:
        if not sim.catalog.groups[int(g)].boss:out.append(int(g))
    return out
func discover(g: int) -> void:
    for v in sim.campaign.variants(g):sim.campaign.discover_spot(g,int(v)) # fixture: spot found
func reload() -> void:
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))
func gems_items() -> String:
    return JSON.stringify([sim.state.gems,sim.state.coins,sim.state.items,sim.state.upgrades,sim.state.xp,sim.state.player_level,sim.state.counters,sim.state.missions,sim.state.tutorial.flow if sim.state.tutorial.has("flow") else {},sim.state.player.hp,sim.state.enemies.map(func(e):return e.hp)])
func near_enemy() -> Dictionary:
    # fixture: the hero stands within reach of the nearest living normal enemy, all quiet
    var best: Dictionary={}
    for e in sim.state.enemies:
        if float(e.hp)>0 and not sim.catalog.groups[int(e.group)].boss and (best.is_empty() or sim.position_of(e).distance_to(sim.position_of(sim.state.player))<sim.position_of(best).distance_to(sim.position_of(sim.state.player))):best=e
    sim.state.player.x=float(best.x)-20;sim.state.player.y=float(best.y)
    sim.state.player.hp=sim.stats().hp;sim.state.player.respawn=0.0
    for e in sim.state.enemies:e.aggro=false;e.quiet=0.0
    best.aggro=false
    sim.campaign.reveal()
    return best
## Steps the simulation; returns the lowest HP the watched enemy had (a kill and quick respawn would
## otherwise hide a hit).
func run_sim(seconds: float,watch: Dictionary={}) -> float:
    var t:=0.0
    hits=0
    var low:=float(watch.get("hp",INF))
    while t<seconds:
        sim.step(.05);t+=.05
        if not watch.is_empty():low=minf(low,float(watch.hp))
    return low

# ---------------------------------------------------------------- A. Focused Farming
func focus_checks() -> void:
    fresh("none")
    var def: Dictionary=sim.catalog.upgrades.focus
    check(str(def.scope)=="global" and int(def.cap)==1 and str(def.currency)=="gems","Focused Farming is one global Gem upgrade (cap 1)")
    check(sim.upgrade_cost("focus")==25,"It costs exactly 25 Gems")
    var a: Array=stage_groups(1)
    discover(a[0]);discover(a[1])
    sim.state.gems=100.0 # fixture
    events.clear()
    check(not sim.focus(a[0]) and events.has("FOCUS_LOCKED_GLOBAL") and int(sim.state.focus)==-1,"Before the purchase Farm is refused with the Player-upgrade reason")
    check(not sim.buy_upgrade("focus",a[0]) and float(sim.state.gems)==100.0,"A per-enemy purchase is refused and charges nothing")
    check(sim.buy_upgrade("focus") and float(sim.state.gems)==75.0 and sim.focus_owned(),"The global purchase charges 25 Gems once and unlocks Focus")
    check(sim.state.upgrades.keys()==["focus"],"Only one global record exists")
    check(not sim.buy_upgrade("focus") and float(sim.state.gems)==75.0 and sim.upgrade_maxed("focus"),"A second purchase is refused (Max)")
    check(sim.level("focus",a[1])==1,"Any caller naming an enemy type reads the same global rank")
    check(sim.focus(a[0]) and int(sim.state.focus)==a[0],"Farm works on a first enemy type")
    check(sim.focus(a[1]) and int(sim.state.focus)==a[1] and float(sim.state.gems)==75.0,"…and switches to a second type at no cost")
    var hidden:=-1
    for g in stage_groups(1):
        if not sim.campaign.discovered(g):hidden=g;break
    if hidden>=0:check(not sim.focus(hidden) and int(sim.state.focus)==a[1],"An undiscovered enemy type is still refused")
    sim.campaign.discover_spot(a[0],2) # fixture: one loadout found
    var undiscovered_variant:=-1
    for v in sim.campaign.variants(a[0]):
        if not sim.campaign.spot_discovered(a[0],int(v)):undiscovered_variant=int(v)
    if undiscovered_variant<0:
        sim.state.discovered_spots.erase(sim.campaign.spot_key(a[0],0));undiscovered_variant=0 # fixture: one spot unseen
    events.clear()
    check(not sim.focus(a[0],undiscovered_variant) and events.has("SPOT_UNDISCOVERED"),"An unseen farming spot is still refused")
    sim.movement=Vector2.RIGHT;sim.state.player.hp=sim.stats().hp
    sim.step(.1);sim.movement=Vector2.ZERO
    check(int(sim.state.focus)==-1,"Manual movement stops farming")
    # Second map.
    sim.state.unlocked_stage=2;if not sim.state.camps.has("2"):sim.state.camps["2"]=[0] # fixture: Winter II reached
    for e in sim.state.enemies:e.aggro=false
    check(sim.campaign.camp_action(2,0,true) and int(sim.state.stage)==2,"Travel to a second map")
    var b: Array=stage_groups(2)
    discover(b[0])
    check(sim.focus(b[0]) and int(sim.state.focus)==b[0] and float(sim.state.gems)==75.0,"Farm works on the second map with the same purchase")
    # Enemy automation remains per type, at its old price.
    check(str(sim.catalog.upgrades.collect.scope)=="type" and str(sim.catalog.upgrades.merge_gear.scope)=="type" and str(sim.catalog.upgrades.auto_evolve.scope)=="type","Auto-Collect, Auto-Merge and Auto Evolution stay per enemy type")
    check(sim.upgrade_cost("collect",a[0])==20 and sim.upgrade_cost("merge_gear",a[0])==30,"Their prices are unchanged on Winter I")
    sim.state.gems=1000.0 # fixture
    check(sim.buy_upgrade("collect",b[0]) and sim.level("collect",b[0])==1 and sim.level("collect",a[0])==0,"Buying Auto-Collect for one type leaves the others untouched")

    # Enemy panel UI.
    fresh("none")
    discover(a[0])
    game.group=a[0];game.enemy_tab=1;game.enemy_variant=2;game._open("enemy");await frames(3)
    check(upgrade_buttons("focus").is_empty(),"The enemy Upgrades tab lists no Focused Farming purchase")
    check(not upgrade_buttons("collect").is_empty() and not upgrade_buttons("merge_gear").is_empty(),"…while Auto-Collect and Auto-Merge are still offered per type")
    var locked: Button=button_meta(game.rows,"focus_locked")
    check(locked!=null and locked.disabled and tr("FOCUS_LOCKED_GLOBAL") in locked.text,"Farm shows locked, with its reason")
    var path: Button=button_meta(game.rows,"focus_open_upgrades")
    check(path!=null and not path.disabled,"…and a way to Player Upgrades")
    path.pressed.emit();await frames(3)
    check(game.panel=="upgrades" and game.player_tab==0 and button_meta(game.rows,"buy_focus")!=null,"It opens Player Upgrades on the tab with Focused Farming")
    check(button_meta(game.rows,"buy_focus").disabled,"With no Gems the purchase is disabled (no accidental unlock)")
    sim.state.gems=30.0;game._refresh_panel(true);await frames(2)
    var buy: Button=button_meta(game.rows,"buy_focus")
    check(buy!=null and not buy.disabled and buy.text=="25","With Gems it reads 25")
    buy.pressed.emit();await frames(3)
    check(sim.focus_owned() and float(sim.state.gems)==5.0,"Buying it from Player Upgrades unlocks Focus")
    game._refresh_panel(true);await frames(2)
    buy=button_meta(game.rows,"buy_focus")
    if buy!=null:print("  info  owned button: '%s' disabled=%s" % [buy.text,buy.disabled])
    check(buy!=null and buy.disabled and buy.text==tr("UPGRADE_MAX"),"Owned reads MAX")
    game.group=a[0];game.enemy_tab=0;game._open("enemy");await frames(3)
    var farm: Button=button_meta(game.rows,"focus_toggle")
    check(farm!=null and not farm.disabled and button_meta(game.rows,"focus_locked")==null,"The enemy panel now offers Farm")
    farm.pressed.emit();await frames(2)
    check(int(sim.state.focus)==a[0],"Farm from the enemy panel starts farming")
    game._close()
    # The first-purchase hint in Guided points at the next actionable Farm (never an old purchase).
    fresh("guided");sim.campaign.onboarding.reveal_all(true)
    discover(a[0]);sim.state.gems=25.0
    sim.buy_upgrade("focus")
    check(sim.state.tutorial.seen.has("focus_unlocked") and sim.campaign.focus_hint==a[0],"Guided: the first purchase hints the nearest found enemy's Farm")
    fresh("basic");discover(a[0]);sim.state.gems=25.0;sim.buy_upgrade("focus")
    check(sim.campaign.focus_hint==-1,"Basic: no pointer after the purchase")

func migration_checks() -> void:
    var a: Array=stage_groups(1)
    var cases:=[["zero",{"collect:%d" % a[0]:1},0,0],["one",{"focus:%d" % a[0]:1},1,1],["many",{"focus:%d" % a[0]:1,"focus:%d" % a[1]:1,"focus:%d" % a[2]:1,"gem_chance":2,"collect:%d" % a[0]:1},1,3],["hybrid",{"focus":1,"focus:%d" % a[1]:1},1,1]]
    for c in cases:
        fresh("basic")
        discover(a[0]);discover(a[1])
        sim.state.gems=42.0;sim.state.coins=77.0
        sim.state.focus=a[0];sim.state.focus_variant=2
        var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
        snap.upgrades=c[1].duplicate() # fixture: a pre-Change 65 upgrade record
        sim.restore(snap)
        var others: Dictionary={}
        for k in c[1]:
            if not str(k).begins_with("focus"):others[k]=c[1][k]
        var kept:=true
        for k in others:kept=kept and int(sim.state.upgrades.get(k,-1))==int(others[k])
        check(sim.level("focus")==int(c[2]) and not sim.state.upgrades.keys().any(func(k):return str(k).begins_with("focus:")),"Migration %s: global rank %d, no per-type records left" % [c[0],c[2]])
        check(kept and float(sim.state.gems)==42.0 and float(sim.state.coins)==77.0 and int(sim.state.focus)==a[0],"Migration %s: other upgrades, currencies and the farming choice unchanged (no refund)" % c[0])
        print("  info  legacy per-type Focus records found (%s): %d" % [c[0],sim.campaign.legacy_focus_records])
        check(sim.campaign.legacy_focus_records==int(c[3]) or c[0]=="zero","Migration %s: %d legacy record(s) counted" % [c[0],c[3]])
        if int(c[2])>0:check(sim.state.tutorial.seen.has("focus_unlocked"),"Migration %s: the first-purchase hint is not replayed" % c[0])
        reload()
        check(sim.level("focus")==int(c[2]) and float(sim.state.gems)==42.0 and sim.campaign.legacy_focus_records==0,"Migration %s: a repeated load changes nothing" % c[0])
    # Prestige keeps it; Hard Reset clears it.
    fresh("none")
    sim.state.gems=25.0;sim.buy_upgrade("focus")
    var g: int=sim.campaign.prestige_unlock_group()
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman") # fixture: found
    sim.state.group_kills[g]=1 # fixture: defeated once
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # fixture: ready
    check(sim.campaign.begin_prestige() and sim.prestige(sim.campaign.offered_cards()[0]),"A Prestige completes")
    check(sim.focus_owned() and sim.state.upgrades.keys().filter(func(k):return str(k).begins_with("focus")).size()==1,"Prestige keeps the global unlock (one record)")
    SaveService.hard_reset();await frames(2)
    check(not sim.focus_owned(),"Hard Reset clears it")
    sim.set_physics_process(false)

# ---------------------------------------------------------------- B. registry and demos
func registry_checks() -> void:
    var ids: Array=HelpCards.ids()
    check(ids==["movement_combat","manual_target","collect_equip","merge_gear","player_upgrades","enemy_automation","missions","explore_camps","skills_supplies","offline_rewards","weapon_evolution","prestige","map_details_mastery","advanced_farming"],"One registry of the 14 approved cards, in order")
    check(HelpCards.essential()==ids.slice(0,8),"The Basic opening uses its first 8 cards")
    check(not "BASIC_DECK" in guide,"The guide keeps no separate deck")
    var all_categories:=true
    var total:=0
    for c in HelpCards.CATEGORIES:total+=HelpCards.in_category(c).size()
    for id in ids:all_categories=all_categories and HelpCards.CATEGORIES.has(HelpCards.category_of(id))
    check(all_categories and total==14,"Every card belongs to exactly one category")
    var keys_ok:=true
    var caps_ok:=true
    for id in ids:
        for key in [HelpCards.title_key(id),HelpCards.action_key(id),HelpCards.support_key(id)]:keys_ok=keys_ok and tr(key)!=key
        caps_ok=caps_ok and tr(HelpCards.action_key(id)).split(" ",false).size()<=12 and tr(HelpCards.support_key(id)).split(" ",false).size()<=18
    for c in HelpCards.CATEGORIES:keys_ok=keys_ok and tr(HelpCards.category_key(c))!=HelpCards.category_key(c)
    check(keys_ok,"Every title, action, support and category has English text")
    check(caps_ok,"Action lines stay within 12 words and support lines within 18 (Playbook 18.3)")
    var loops_ok:=true
    for id in ids:loops_ok=loops_ok and HelpCards.loop_seconds(id)>=4.0 and HelpCards.loop_seconds(id)<=8.0
    check(loops_ok,"Each demonstration loops in 4-8 s")

func demo_checks() -> void:
    fresh("none")
    var before:=gems_items()
    var ids: Array=HelpCards.ids()
    viewer.open_help("help_all",0)
    var demo: Control=viewer.demo
    check(demo.card_id=="movement_combat" and demo.time==0.0,"Opening starts the first card's loop at 0")
    await frames(2)
    var methods_ok:=true
    var advance_ok:=true
    var restart_ok:=true
    for i in range(ids.size()):
        methods_ok=methods_ok and demo.has_method("_demo_"+str(ids[i]))
        restart_ok=restart_ok and demo.card_id==ids[i] and demo.time<.1
        var t0: float=demo.time
        for f in range(20):await get_tree().process_frame
        # Sweep the whole loop once (drawing every phase) without real waiting.
        for k in range(16):
            demo.time=HelpCards.loop_seconds(ids[i])*k/16.0;demo.queue_redraw();await get_tree().process_frame
        advance_ok=advance_ok and (t0!=demo.time)
        if i<ids.size()-1:
            demo.time=3.0;viewer.step(1)
            restart_ok=restart_ok and demo.time==0.0
            await frames(1)
    check(methods_ok,"All 14 cards have their own demonstration")
    check(restart_ok,"Every card restarts its loop when shown")
    check(advance_ok,"Every demonstration animates while visible")
    var t: float=demo.time
    viewer.hide();await frames(10)
    check(demo.time==t and not demo.running(),"A hidden demonstration stops")
    viewer.show();sim.suspended=true;var t2: float=demo.time;await frames(10)
    check(demo.time==t2,"…and pauses while the app is in the background")
    sim.suspended=false
    demo.reduced_motion=true;demo.restart();await frames(3)
    check(not demo.running() and demo.self_modulate.a==1.0,"Reduced motion draws one static key frame")
    demo.reduced_motion=false
    viewer.close_viewer();await frames(2)
    sim.state.tutorial.erase("help")
    check(gems_items()==before,"Playing all demonstrations changed no game state (currencies, items, upgrades, XP, missions, health)")

# ---------------------------------------------------------------- C. Help
func help_checks() -> void:
    fresh("none")
    game._open("settings");await frames(3)
    var labels: Array=game.rows.find_children("*","Label",true,false).map(func(l):return l.text)
    check(labels.has(tr("SECTION_HELP_TUTORIALS")),"Settings shows the Help & Tutorials section")
    button_meta(game.rows,"help").pressed.emit();await frames(3)
    check(game.panel=="help" and button_meta(game.rows,"help_read_all")!=null and button_meta(game.rows,"help_topics")!=null,"Help offers Read All Tutorials and Choose a Topic")
    check(button_meta(game.rows,"help_continue")==null,"No Continue before anything was read")
    button_meta(game.rows,"help_topics").pressed.emit();await frames(3)
    var cats_ok:=true
    for c in HelpCards.CATEGORIES:cats_ok=cats_ok and button_meta(game.rows,"help_cat_"+c)!=null
    check(cats_ok,"Choose a Topic lists the five categories")
    button_meta(game.rows,"help_cat_equipment").pressed.emit();await frames(3)
    var cards_ok:=true
    for id in HelpCards.in_category("equipment"):cards_ok=cards_ok and button_meta(game.rows,"help_card_"+id)!=null
    check(cards_ok and game.help_page=="equipment","A category lists its cards")
    var merge: Button=button_meta(game.rows,"help_card_merge_gear")
    check(tr("HELP_NOT_VIEWED") in merge.text,"An unread card is marked Not viewed")
    merge.pressed.emit();await frames(3)
    var index: int=HelpCards.ids().find("merge_gear")
    check(viewer.visible and viewer.context=="help_topic" and viewer.current()=="merge_gear" and viewer.position_label.text=="%d/14" % (index+1),"The card opens in the viewer at its place (N/14)")
    check(sim.held,"The world is held while a card is read")
    check(viewer.topics_button.visible and viewer.close_button.visible and not viewer.skip_button.visible,"Help shows Back to Topics and Close, never Skip Overview")
    var panel_rect: Rect2=viewer.panel.get_global_rect()
    viewer.step(1);await frames(3)
    check(viewer.current()==HelpCards.ids()[index+1] and HelpCards.viewed(sim.state.tutorial,"merge_gear"),"Next goes to the next card of the whole library and marks the read one Viewed")
    check(viewer.panel.get_global_rect().is_equal_approx(panel_rect),"The panel keeps its geometry when cards advance")
    viewer.step(-1);await frames(2)
    check(viewer.current()=="merge_gear","Previous goes back")
    viewer.shown=0.2;viewer.back_to_topics();await frames(3)
    check(not viewer.visible and game.panel=="help" and game.help_page=="equipment","Back to Topics returns to the card's category")
    merge=button_meta(game.rows,"help_card_merge_gear")
    check(merge!=null and tr("HELP_VIEWED") in merge.text,"…where the read card is marked Viewed")
    # Read All and Auto-Advance.
    viewer.open_help("help_all",0);await frames(2)
    check(viewer.position_label.text=="1/14" and not viewer.auto,"Read All starts at 1/14 with Auto-Advance off")
    viewer.toggle_auto()
    check(viewer.auto and bool(HelpCards.progress(sim.state.tutorial).auto),"Auto-Advance turns on and is remembered")
    var need: float=HelpCards.dwell_seconds(viewer.current(),viewer.action_label.text,viewer.support_label.text)
    check(need>=HelpCards.loop_seconds(viewer.current()),"It waits at least one demonstration loop")
    for k in range(int(need/.25)-1):viewer._process(.25)
    check(viewer.index==0,"…and a comfortable reading time before advancing")
    for k in range(4):viewer._process(.25)
    check(viewer.index==1 and HelpCards.viewed(sim.state.tutorial,HelpCards.ids()[0]),"Then it advances and marks the card Viewed")
    viewer.index=13;viewer._show_card()
    for k in range(200):viewer._process(.25)
    check(viewer.index==13 and viewer.visible and not viewer.auto,"On the last card it stops (never wraps)")
    check(viewer.next_button.disabled,"Next is disabled on the last Help card")
    viewer.close_viewer();await frames(3)
    check(not viewer.visible and not game.sheet.visible,"Close closes the card and Help")
    check(not sim.held,"The world runs again")
    # Persistence.
    var viewed: Array=HelpCards.progress(sim.state.tutorial).viewed.duplicate()
    var last: String=str(HelpCards.progress(sim.state.tutorial).last)
    reload()
    check(HelpCards.progress(sim.state.tutorial).viewed==viewed and str(HelpCards.progress(sim.state.tutorial).last)==last and bool(HelpCards.progress(sim.state.tutorial).auto),"Viewed cards, the last card and Auto-Advance survive a reload")
    game.help_page="home";game._open("help");await frames(3)
    var cont: Button=button_meta(game.rows,"help_continue")
    check(cont!=null and tr(HelpCards.title_key(last)) in cont.text,"Continue where you left off appears")
    cont.pressed.emit();await frames(2)
    check(viewer.visible and viewer.current()==last,"…and opens that card")
    viewer.close_viewer();await frames(2)
    # Save fixtures: unknown ids are dropped, malformed values repaired.
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    snap.tutorial.help={"viewed":["merge_gear","nope",3],"last":"gone","auto":"yes","basic_done":1}
    sim.restore(snap)
    var p: Dictionary=HelpCards.progress(sim.state.tutorial)
    check(p.viewed==["merge_gear"] and p.last=="" and p.auto==false and p.basic_done==false,"Malformed Help progress is repaired on load")
    # Guided: reading Help never marks a lesson.
    fresh("guided")
    var done_before: Array=sim.campaign.guided.data().done.duplicate()
    viewer.open_help("help_all",0);for k in range(13):viewer.step(1)
    viewer.shown=2.0;viewer.close_viewer();await frames(2)
    check(sim.campaign.guided.data().done==done_before,"Reading every card in Guided changes no lesson")
    # Prestige keeps the record (tutorial is kept); Hard Reset clears it.
    check(sim.campaign.has_method("begin_prestige") and HelpCards.viewed_count(sim.state.tutorial)==14,"All 14 viewed")
    SaveService.hard_reset();await frames(2);sim.set_physics_process(false)
    check(HelpCards.viewed_count(sim.state.tutorial)==0 and not HelpCards.basic_done(sim.state.tutorial),"Hard Reset clears Help progress")

# ---------------------------------------------------------------- D. modes
func mode_checks() -> void:
    # The chooser carries the one Help line.
    sim.new_profile();sim.set_physics_process(false);game._close();await frames(4)
    check(guide.chooser.visible and guide.chooser_help.is_visible_in_tree() and guide.chooser_help.text==tr("HELP_DISCOVERY_CHOOSER"),"The mode chooser says Help & Tutorials is always in Settings")
    # None: no instructional overlay after choosing.
    guide.choose("none");await frames(6)
    check(not viewer.visible and guide.intro_id in ["","road_ahead"] and not guide.pointer.visible,"None: no Help card, pointer or lesson (only The Road Ahead)")
    check(not sim.campaign.guided.auto_attack_gated(),"None: autoattack is never gated")
    # Basic opening.
    sim.new_profile();sim.set_physics_process(false);game._close();await frames(2)
    guide.choose("basic");await frames(4)
    check(viewer.visible and viewer.context=="basic" and viewer.position_label.text=="1/8" and viewer.current()=="movement_combat","Basic opens the shared viewer at 1/8")
    check(sim.held and viewer.skip_button.visible and not viewer.topics_button.visible and viewer.auto,"…holding the world, with Skip Overview and Auto-Advance")
    check(not sim.campaign.guided.auto_attack_gated(),"Basic: autoattack is never gated")
    viewer.step(1);viewer.step(1);await frames(2)
    check(viewer.current()=="collect_equip","Basic Next advances")
    reload();viewer.hide();await frames(4)
    check(viewer.visible and viewer.current()=="collect_equip","After a reload the opening resumes on the same card")
    for k in range(5):viewer.step(1)
    await frames(2)
    check(viewer.position_label.text=="8/8" and viewer.note_label.visible and viewer.note_label.text==tr("HELP_DISCOVERY_BASIC") and viewer.next_button.text==tr("HELP_FINISH"),"The last Basic card says where the other guides are, with Finish")
    check(not viewer.skip_button.visible,"No Skip on the last card")
    viewer.step(1);await frames(4)
    check(not viewer.visible and HelpCards.basic_done(sim.state.tutorial),"Finish ends the opening")
    check(guide.intro_id=="road_ahead","The Road Ahead follows (no duplicate final card)")
    reload();await frames(4)
    check(not viewer.visible,"A finished opening never replays after a reload")
    # Skip.
    sim.new_profile();sim.set_physics_process(false);game._close();await frames(2)
    guide.choose("basic");await frames(3)
    viewer.skip_button.pressed.emit();await frames(3)
    check(not viewer.visible and HelpCards.basic_done(sim.state.tutorial),"Skip Overview ends the opening at once")
    # Legacy Basic decks.
    for c in [["finished",["overview","basic_target","basic_gear","basic_growth","basic_world","basic_prestige"],true],["road",["road_ahead"],true],["partial",["overview"],false]]:
        sim.new_profile();sim.state.tutorial.mode="basic";sim.state.tutorial.seen.append_array(c[1]);sim.state.tutorial.erase("help") # fixture: pre-Change 65 Basic save
        reload()
        check(HelpCards.basic_done(sim.state.tutorial)==bool(c[2]),"Legacy Basic save (%s): opening %s" % [c[0],"finished" if c[2] else "still to show"])
    viewer.hide();sim.set_physics_process(false)
    # Guided finale keeps its text and adds the Help line.
    fresh("guided")
    var f: Dictionary=sim.campaign.guided.data()
    f.done=sim.campaign.guided.STEPS.slice(0,sim.campaign.guided.STEPS.size()-1) # fixture: at the finale
    await frames(4)
    check(guide.intro_id=="flow:tutorial_final" and guide.title.text==tr("GUIDE_TUTORIAL_FINAL") and guide.support.text.begins_with(tr("GUIDE_TUTORIAL_FINAL_DETAIL")) and guide.support.text.ends_with(tr("HELP_DISCOVERY_GUIDED")),"Guided: The Road Ahead keeps its title and text and adds the Help line")
    check(not viewer.visible,"Guided never opens the Basic cards")

# ---------------------------------------------------------------- E. Guided first manual attack
func at_target_step() -> void:
    fresh("guided")
    sim.campaign.guided.mark("move") # fixture: the path is walked
func first_attack_checks() -> void:
    at_target_step()
    check(sim.campaign.guided.next_step()=="target" and sim.campaign.guided.auto_attack_gated(),"Fresh Guided at the targeting lesson: autoattack is gated")
    var e: Dictionary=near_enemy()
    var hp: float=float(e.hp)
    run_sim(4.0,e)
    check(hits==0 and sim.locked_target=="","Standing in reach and waiting: no automatic player attack")
    await frames(2)
    check(guide.step=="target","The gesture lesson is shown")
    # Selection alone does not complete it; the target dying first returns to the gesture.
    check(sim.select_target(e.id) and not sim.campaign.guided.data().done.has("target"),"Releasing on an enemy selects it but does not finish the lesson")
    await frames(2)
    check(guide.step=="target_strike","The caption waits for the hero's attack")
    e.hp=0.0;e.respawn=30.0;e.dead_age=0.0 # fixture: the chosen enemy is gone (not a player kill)
    await frames(2)
    run_sim(.1)
    check(sim.manual_target=="" and guide.step in ["target","target_find"] and sim.campaign.guided.auto_attack_gated(),"Target gone before the strike: back to the gesture, still gated")
    run_sim(3.0)
    e=near_enemy();hp=float(e.hp)
    # Movement cancels a selection.
    var picked: bool=sim.select_target(e.id);sim.movement=Vector2.RIGHT;sim.step(.05);sim.movement=Vector2.ZERO
    check(picked,"(selection accepted)")
    check(sim.manual_target=="" and sim.campaign.guided.auto_attack_gated(),"Moving cancels the selection (still gated)")
    # Save/load between selection and attack.
    e=near_enemy();sim.select_target(e.id);reload()
    check(sim.manual_target=="" and sim.campaign.guided.auto_attack_gated() and sim.campaign.guided.next_step()=="target","A reload after selecting returns to the gesture (no retroactive attack)")
    e=near_enemy();hp=float(e.hp)
    run_sim(2.0,e)
    check(hits==0,"…and still no automatic attack after the reload")
    # Player death keeps the gate.
    sim.state.player.hp=0.0;sim._kill(sim.state.player);run_sim(.2)
    check(sim.campaign.guided.auto_attack_gated() and sim.manual_target=="","Death before the first strike keeps the lesson")
    sim.state.player.respawn=0.0;run_sim(.2)
    # The real attack.
    e=near_enemy();hp=float(e.hp)
    check(sim.select_target(e.id),"A new valid selection")
    var t:=0.0
    while t<4.0 and float(e.hp)==hp:sim.step(.05);t+=.05
    check(float(e.hp)<hp,"The hero walks up and really hits the chosen enemy")
    check(sim.campaign.guided.data().done.has("target") and not sim.campaign.guided.auto_attack_gated(),"That hit finishes the lesson and turns autoattack on")
    await frames(3)
    check(guide.intro_id=="auto_attack" and guide.title.text==tr("GUIDE_AUTO_ATTACK") and guide.support.text==tr("GUIDE_AUTO_ATTACK_DETAIL") and guide.intro_button.visible,"One dismissible explanation: Auto-Attack Enabled!")
    check(guide.card.mouse_filter==Control.MOUSE_FILTER_IGNORE and not guide.pointer.visible,"It takes no touches except Got it and points at nothing")
    var map: Control=game.get_node("Safe/Layout/Map")
    var scale: Vector2=map.size/Vector2(game.world.get_viewport_rect().size)
    var hero_at: Vector2=map.global_position+game.world.player_screen_position()*scale
    var foe_at: Vector2=map.global_position+(game.world.get_canvas_transform()*sim.position_of(e))*scale
    # Placement is the ordinary caption's (above the joystick); judged at phone sizes in change_65_capture.
    if game.size.y>game.size.x:check(not guide.card.get_global_rect().has_point(hero_at) and not guide.card.get_global_rect().has_point(foe_at),"It covers neither the hero nor its target")
    else:print("  info  landscape headless window: caption/hero overlap is checked in change_65_capture")
    reload();await frames(2)
    check(not sim.campaign.guided.auto_attack_gated() and guide.intro_id=="auto_attack","After a reload autoattack stays on and the explanation is still pending once")
    guide.intro_button.pressed.emit();await frames(3)
    check(not bool(sim.campaign.guided.data().auto_attack_notice) and guide.intro_id!="auto_attack","Got it retires it for good")
    # Autoattack now acquires targets on its own.
    for x in sim.state.enemies:if float(x.hp)>0:x.hp=float(sim.enemy_definition(int(x.group),int(x.get("variant",2))).hp)
    e=near_enemy();hp=float(e.hp);sim.clear_target()
    run_sim(3.0,e)
    check(hits>0,"Ordinary autoattack works after the lesson")
    # Escape on an empty map.
    at_target_step()
    sim.campaign.guided.target_unavailable(sim.campaign.onboarding.rules.target_escape_seconds+1)
    check(sim.campaign.guided.data().done.has("target") and not sim.campaign.guided.auto_attack_gated() and bool(sim.campaign.guided.data().auto_attack_notice),"The empty-map escape restores autoattack (and explains it)")
    # Older profiles.
    at_target_step();sim.state.counters["kill"]=1 # fixture: past the first defeat
    check(not sim.campaign.guided.auto_attack_gated(),"A profile past its first defeat is never gated")
    at_target_step();sim.campaign.guided.mark("target") # fixture: pre-Change 65 selection-completed lesson
    check(not sim.campaign.guided.auto_attack_gated(),"A profile whose targeting lesson is done is never gated")
    at_target_step();sim.campaign.guided.data().done=sim.campaign.guided.STEPS.duplicate() # fixture: finished
    check(not sim.campaign.guided.auto_attack_gated(),"A finished tutorial is never gated")
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    snap.tutorial.flow.done=["move","kill"];snap.tutorial.flow.erase("auto_attack_notice") # fixture: Change 61 save past the kill
    sim.restore(snap)
    check(sim.campaign.guided.data().done.has("target") and not sim.campaign.guided.auto_attack_gated() and not bool(sim.campaign.guided.data().auto_attack_notice),"An old save past the first kill keeps its place, no gate, no new explanation")
    # Basic and None: autoattack from the first moment.
    for mode in ["basic","none"]:
        fresh(mode)
        e=near_enemy();hp=float(e.hp)
        run_sim(3.0,e)
        check(hits>0,"%s: the hero attacks a nearby enemy by itself from the start" % mode)
