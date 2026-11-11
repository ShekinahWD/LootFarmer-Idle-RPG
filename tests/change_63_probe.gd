extends Node
## Change 63 (Guided tutorial UI corrections), focused checks only:
## - Winter II optional Prestige: inside Prestige the arrow is on the live Close button and the caption
##   says closing continues; Close finishes the lesson, and so does a real Prestige (through the UI).
## - Stats (gear_bonus): the arrow is on Close, not on the passive Stored gear line.
## - A pass over the 35 Guided steps (HUD state and the panels they use): every arrow sits on a visible,
##   enabled button, a real World map enemy marker, or a world / path cue; never on a passive control.
## - Optional Map Mastery hint: nothing at 99%, one hint at 100% on any map, Guided only, once per profile
##   (save/load and Prestige), dismiss / ignore / open all retire it, never blocks a lesson.
## - Toasts and banners never cover the guide's caption or arrow at 432x960 and 540x960, and an open
##   lesson panel keeps room for its caption above it.
## The Prestige unlock rules themselves are checked by change_16_probe and change_61_probe.
var checks:=0
var failures:=0
var game
var sim
var guide
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")
func fresh(mode:="guided") -> void:
    get_tree().paused=false
    if game.help_viewer.visible:game.help_viewer.hide() # Change 65: a Basic opening left by an earlier step
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false
    sim.state.tutorial.mode=mode
    if mode!="guided":sim.campaign.onboarding.reveal_all(true)
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_time=0.0;game.toast_resume={};game.get_node("Toast").hide()
    game.get_node("PrestigeConfirm").close();game._cancel_confirm()
    guide.long_shown.clear();guide.mastery_live=false;guide.mastery_shown=0.0
    calm()
func calm() -> void:
    sim.state.player.quiet=1e9
    for e in sim.state.enemies:e.aggro=false
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
func done_until(step: String) -> void:
    var flow=sim.campaign.guided
    flow.data().done=flow.STEPS.slice(0,flow.STEPS.find(step))
func close_button() -> Button:return game.get_node("Sheet/Margin/Content/Header/Close")
## A tap arrow may only sit on a visible, enabled button, a World map marker (screen_target), the stick,
## or come from a world / path cue (no control target).
func legit_target() -> bool:
    if not guide.pointer.visible:return true
    var t=guide.target
    if t==null or not is_instance_valid(t):return true
    if t==game.stick:return true
    if t.has_meta("guide_map"):return guide.screen_target.size!=Vector2.ZERO
    return t is BaseButton and not t.disabled and t.is_visible_in_tree()
## The guide's caption, arrow and target frame as drawn (no margins): what a notice must never cover.
func clear_of_guide(r: Rect2) -> bool:
    for node in [guide.card,guide.pointer,guide.highlight]:
        if node.visible and node.get_global_rect().intersects(r):return false
    return true
func winter_two_lesson() -> void:
    fresh("guided")
    var flow=sim.campaign.guided
    done_until("winter_two")
    sim.state.unlocked_stage=2;find_snowman();sim._kill(snowman());calm()
    sim.campaign.camp_action(2,0,true);calm()
    sim.campaign.onboarding.reveal_all(true)
    await frames(6)
func run() -> void:
    get_window().size=Vector2i(540,960)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;guide=game.guide
    await frames()
    var flow=sim.campaign.guided
    # ---------------------------------------------------------------- A. Winter II optional Prestige
    print("-- Winter II optional Prestige")
    await winter_two_lesson()
    check(flow.next_step()=="prestige_optional","Winter II reached: the optional Prestige lesson is next (%s)" % flow.next_step())
    check(guide.target==game.dock.get_node("Navigation/Prestige") and guide.pointer.visible,"Closed: the arrow is on the real Prestige button")
    game._open("prestige");await frames(14)
    check(guide.step=="prestige_optional_close","In Prestige: the close substate (%s)" % guide.step)
    check(guide.target==close_button() and guide.pointer.visible and guide.highlight.visible and guide.highlight.get_global_rect().encloses(close_button().get_global_rect()),"The arrow and frame are on the live Close button, not the First Bounty card")
    check(guide.card.visible and guide.title.text==tr("GUIDE_PRESTIGE_OPTIONAL_CLOSE") and guide.support.text.contains("tap Close") and guide.support.text.contains("Prestige now"),"The caption is shown and says Close continues, Prestige is the alternative")
    check(not guide.card.get_global_rect().intersects(game.sheet.get_global_rect()),"The caption sits above the panel (%s / %s)" % [guide.card.get_global_rect(),game.sheet.get_global_rect()])
    var begin: Button=null
    for b in game.actions.find_children("*","Button",true,false):
        if b.get_meta("guide","")=="begin_prestige":begin=b
    check(begin!=null and not begin.disabled,"The Prestige reset is available at this lesson")
    check(legit_target(),"Legitimate tap target")
    close_button().pressed.emit();await frames(4)
    check(flow.data().done.has("prestige_optional") and flow.next_step()=="tutorial_final","Close finishes the lesson; The Road Ahead is next")
    check(int(sim.state.prestiges)==0,"…without a reset")
    # The alternative: a real Prestige from the panel.
    await winter_two_lesson()
    game._open("prestige");await frames(14)
    begin=null
    for b in game.actions.find_children("*","Button",true,false):
        if b.get_meta("guide","")=="begin_prestige":begin=b
    begin.pressed.emit();await frames(3)
    var screen: Control=game.get_node("PrestigeConfirm")
    check(screen.visible and not guide.pointer.visible,"The Prestige confirmation suspends the guide (modal first)")
    screen.get_node("Plate/Margin/Content/Actions/Begin").pressed.emit();await frames(2)
    while not sim.state.prestige_batch.is_empty():sim.campaign.choose_card(sim.campaign.offered_cards()[0])
    await frames(4)
    check(int(sim.state.prestiges)==1 and flow.data().done.has("prestige_optional") and flow.next_step()=="tutorial_final","A real Prestige also finishes the lesson; The Road Ahead follows")
    # ---------------------------------------------------------------- B. Stats (gear_bonus)
    print("-- Stats lesson")
    fresh("guided");done_until("gear_bonus");await frames(4)
    check(flow.next_step()=="gear_bonus","gear_bonus is next")
    game._open("stats");await frames(10)
    check(guide.step=="gear_bonus_close" and guide.target==close_button() and guide.pointer.visible,"In Stats the arrow is on Close (%s)" % guide.step)
    check(guide.card.visible and guide.support.text.contains("Tap Close"),"…and the caption says Close continues")
    close_button().pressed.emit();await frames(3)
    check(flow.data().done.has("gear_bonus"),"Closing Stats finishes the lesson")
    # ---------------------------------------------------------------- C. pointer pass over the 35 steps
    print("-- pointer pass")
    var bad: Array=[]
    var seen_steps: Array=[]
    for step in flow.STEPS:
        if step=="tutorial_final":continue
        fresh("guided");done_until(step)
        if flow.STEPS.find(step)>flow.STEPS.find("boss_find"):find_snowman()
        await frames(3)
        seen_steps.append(guide.step)
        if not legit_target():bad.append(step+"/"+guide.step+":"+str(guide.target))
        for panel in guide.surfaces:
            if panel in ["stats","upgrades","missions","world","prestige","level","settings"]:
                game._open(panel);await frames(8)
                if not legit_target():bad.append(step+"/"+panel+"/"+guide.step+":"+str(guide.target))
                if guide.card.visible and guide.card.get_global_rect().intersects(game.sheet.get_global_rect()):bad.append(step+"/"+panel+": caption over panel")
                game._close();await frames(2)
    check(bad.is_empty(),"Every arrow over the Guided steps is on a real tap target %s" % str(bad))
    print("     substates seen: ",seen_steps)
    # ---------------------------------------------------------------- D. optional Map Mastery hint
    print("-- Map Mastery hint")
    fresh("guided");flow.data().done=flow.STEPS.duplicate();sim.campaign.onboarding.reveal_all(true)
    var m: Dictionary=sim.campaign.mastery.data()
    m.explored["1"]=99;await frames(4)
    check(guide.pending!="mastery_intro" and not sim.state.tutorial.seen.has("mastery_intro"),"99% explored: nothing")
    m.explored["1"]=100;await frames(4)
    var chip: Control=game.get_node("Safe/Layout/Map/Mastery")
    check(guide.pending=="mastery_intro" and guide.card.visible and guide.target==chip and guide.pointer.visible,"100%: one optional hint pointing at the live Mastery chip")
    check(guide.title.text==tr("GUIDE_MASTERY_INTRO") and guide.support.text.contains("optional") and guide.intro_button.visible,"…saying it is optional, with Got it")
    check(sim.state.tutorial.seen.has("mastery_intro"),"Shown once is recorded in the profile")
    guide.intro_button.pressed.emit();await frames(3)
    check(guide.pending!="mastery_intro","Got it dismisses it")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())));guide.mastery_live=false;await frames(4)
    check(guide.pending!="mastery_intro" and sim.state.tutorial.seen.has("mastery_intro"),"Save/load does not repeat it")
    sim.state.bosses_found=["boss-snowman"];sim.state.group_kills[sim.campaign.prestige_unlock_group()]=1
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    check(sim.campaign.begin_prestige(),"Prestige (fixture: ready opportunity)")
    while not sim.state.prestige_batch.is_empty():sim.campaign.choose_card(sim.campaign.offered_cards()[0])
    m=sim.campaign.mastery.data();await frames(4)
    check(int(m.explored.get("1",0))>=100 and guide.pending!="mastery_intro","Prestige does not repeat it (record kept: %s)" % str(m.explored.get("1",0)))
    # Late 100% on another map, after the tutorial; ignoring it retires it after its time on screen.
    fresh("guided");flow.data().done=flow.STEPS.duplicate();sim.campaign.onboarding.reveal_all(true)
    sim.campaign.mastery.data().explored["3"]=100;await frames(4)
    check(guide.pending=="mastery_intro","Any map at 100% (Summer I record) after the tutorial: the hint shows")
    guide._process(guide.MASTERY_HINT_SECONDS+1);await frames(3)
    check(guide.pending!="mastery_intro","Ignored: it retires on its own")
    # Opening Map Mastery retires it.
    fresh("guided");flow.data().done=flow.STEPS.duplicate();sim.campaign.onboarding.reveal_all(true)
    sim.campaign.mastery.data().explored["1"]=100;await frames(4)
    chip.pressed.emit();await frames(4)
    check(game.panel=="mastery" and game.sheet.visible,"The chip opens Map Mastery")
    game._close();await frames(3)
    check(guide.pending!="mastery_intro" and sim.state.tutorial.seen.has("mastery_intro"),"Opening Map Mastery retires the hint")
    # During the first-run tutorial: never over a mandatory lesson, never blocking.
    fresh("guided");done_until("boss_win");find_snowman();sim.campaign.mastery.data().explored["1"]=100;await frames(4)
    check(flow.next_step()=="boss_win" and guide.pending=="boss_win","A mandatory lesson on screen keeps the guide (%s)" % guide.pending)
    guide.long_shown["boss_win"]=guide.LONG_CARD_SECONDS+1;await frames(4)
    check(guide.pending=="mastery_intro" and flow.next_step()=="boss_win","With its card retired, the optional hint shows; the lesson stays pending")
    check(not flow.STEPS.has("mastery_intro"),"Map Mastery is not a step of the Guided tutorial")
    # Not before Map Mastery is revealed (no arrow at hidden content).
    fresh("guided");done_until("camp");sim.campaign.mastery.data().explored["1"]=100;await frames(4)
    check(guide.pending!="mastery_intro" and not sim.state.tutorial.seen.has("mastery_intro"),"Before Map Mastery is revealed it waits")
    for mode in ["basic","none"]:
        fresh(mode);sim.state.tutorial.seen.append(guide.ROAD_AHEAD_ID);game.help_viewer.hide();game.help_viewer.HelpCards.progress(sim.state.tutorial).basic_done=true;sim.held=false;sim.campaign.mastery.data().explored["1"]=100;await frames(4)
        check(guide.pending!="mastery_intro","%s: no Guided hint" % mode)
    # ---------------------------------------------------------------- E. notifications vs the guide
    for size in [Vector2i(432,960),Vector2i(540,960)]:
        get_window().size=size;await frames(6)
        print("-- notifications at ",size," (ui ",game.size,")")
        fresh("guided");done_until("kill");await frames(6)
        var shown_step: String=guide.step
        check(guide.card.visible,"A Guided caption is on screen (%s)" % shown_step)
        game._toast(tr("CAMP_SIGHTED"));await frames(3)
        var toast: Control=game.get_node("Toast")
        var clear:=true
        for node in [guide.card,guide.pointer,guide.highlight]:
            if node.visible and toast.visible and node.get_global_rect().intersects(toast.get_global_rect()):clear=false
        check(toast.visible and clear,"Camp Found shows clear of the caption and arrow (toast %s, card %s, arrow %s %s, frame %s %s)" % [toast.get_global_rect(),guide.card.get_global_rect(),guide.pointer.visible,guide.pointer.get_global_rect(),guide.highlight.visible,guide.highlight.get_global_rect()])
        check(game.get_global_rect().encloses(toast.get_global_rect()),"…inside the screen")
        check(guide.card.visible and guide.step==shown_step,"The lesson keeps its step and caption")
        # A milestone banner (top) with the lesson on screen.
        game.banner.push("stage",tr("MILESTONE_STAGE"),"Winter II");await frames(4)
        var both: bool=game.banner.visible and guide.card.visible
        check(not game.banner.visible or not guide.covers(game.banner.get_global_rect()),"A banner never covers the caption or arrow")
        check(both,"Banner and caption share the screen")
        game.banner._finish();game.banner.queue.clear()
        # The path arrow beside the hero (boss_find walks toward the Snowman) with a toast queued.
        fresh("guided");done_until("boss_find");await frames(6)
        game._toast(tr("CAMP_SIGHTED"));await frames(3)
        clear=true
        for node in [guide.card,guide.pointer]:
            if node.visible and toast.visible and node.get_global_rect().intersects(toast.get_global_rect()):clear=false
        check(guide.pointer.visible and guide.card.visible and clear and (toast.visible or not game.toast_queue.is_empty()),"Path arrow + caption: the toast shows clear of both or waits queued (toast %s %s, arrow %s)" % [toast.visible,toast.get_global_rect(),guide.pointer.get_global_rect()])
        # Correction: the Map Mastery hint's chip sits in the banner's usual place. The banner moves to free
        # space below it; the hint keeps its caption, arrow and a tappable chip.
        fresh("guided");flow.data().done=flow.STEPS.duplicate();sim.campaign.onboarding.reveal_all(true)
        sim.campaign.mastery.data().explored["1"]=100
        for i in range(120): # the HUD refreshes the chip every 0.15 s
            if guide.pending=="mastery_intro" and guide.pointer.visible:break
            await get_tree().process_frame
        chip=game.get_node("Safe/Layout/Map/Mastery")
        check(guide.pending=="mastery_intro" and guide.pointer.visible and game._banner_rect().intersects(chip.get_global_rect()),"Mastery hint: its chip is inside the banner usual place (%s %s %s %s)" % [guide.pending,guide.pointer.visible,game._banner_rect(),chip.get_global_rect()])
        game.banner.push("stage",tr("MILESTONE_STAGE"),"Spring I");await frames(30)
        var br: Rect2=game.banner.get_global_rect()
        check(game.banner.visible and clear_of_guide(br) and not br.intersects(chip.get_global_rect()),"...the banner shows clear of the chip, caption and arrow (banner %s, chip %s)" % [br,chip.get_global_rect()])
        check(guide.card.visible and guide.pointer.visible and guide.suspended_by=="","...and the hint stays on screen")
        check(game.get_node("Safe/Layout/Map").get_global_rect().encloses(br),"...over the map")
        var steady:=true
        for i in range(30):
            await get_tree().process_frame
            if game.banner.visible and not is_equal_approx(game.banner.position.y,br.position.y):steady=false
        check(steady and clear_of_guide(game.banner.get_global_rect()),"...and keeps its place while the arrow bobs (no wobble)")
        game.banner._finish();game.banner.queue.clear();await frames(2)
        # No free place: the banner waits in its queue (held, not dropped) and shows once there is room.
        fresh("guided");flow.data().done=flow.STEPS.duplicate();sim.campaign.onboarding.reveal_all(true)
        sim.campaign.mastery.data().explored["1"]=100;await frames(6)
        var hold_before: float=guide.card.custom_minimum_size.y
        guide.card.custom_minimum_size.y=game.get_node("Safe/Layout/Map").size.y # fixture: a caption filling the map
        await frames(4)
        game.banner.push("stage",tr("MILESTONE_STAGE"),"Summer I");await frames(6)
        check(not game.banner.visible and game.banner.pending()==1 and game._banner_slot()==Vector2.INF,"No free place: the banner waits queued")
        guide.card.custom_minimum_size.y=hold_before;await frames(8)
        check(game.banner.visible and str(game.banner.current.get("subtitle",""))=="Summer I" and clear_of_guide(game.banner.get_global_rect()),"...and shows clear of the guide as soon as there is room")
        game.banner._finish();game.banner.queue.clear();await frames(2)
        # Open lesson panel: the caption keeps room above it; the notice line replaces toasts.
        fresh("guided");done_until("gear_bonus");await frames(3);game._open("stats");await frames(12)
        check(guide.card.visible and not guide.card.get_global_rect().intersects(game.sheet.get_global_rect()) and game.get_global_rect().encloses(guide.card.get_global_rect()),"Open panel: caption above it (%s / %s)" % [guide.card.get_global_rect(),game.sheet.get_global_rect()])
        game._toast("probe");await frames(2)
        check(not game.get_node("Toast").visible,"...and no toast over the panel")
        game._close();await frames(2)
        check(game.sheet_reserved==0.0 or not game.sheet.visible,"Closing the panel drops the reserve")
        # Correction: the panel keeps its size while a lesson finishes inside it (Follow on the 30-defeat
        # mission), and stays scrollable with Close reachable.
        fresh("guided");done_until("hunt_follow");find_snowman();await frames(4);game._open("missions");await frames(16)
        var sheet_before: Rect2=game.sheet.get_global_rect()
        var follow: Button=guide._panel_control("follow_hunt",true)
        check(follow!=null and guide.target==follow and game.sheet_reserved>0,"Missions: the arrow is on Follow with the caption room kept (%s)" % game.sheet_reserved)
        follow.pressed.emit()
        var stable:=true
        for i in range(20):
            await get_tree().process_frame
            if not game.sheet.get_global_rect().is_equal_approx(sheet_before):stable=false
        check(flow.next_step()=="hunt_farm" and stable,"After Follow (lesson done) the panel keeps its size for 20 frames (%s -> %s)" % [sheet_before,game.sheet.get_global_rect()])
        var bar:=(game.get_node("Sheet/Margin/Content/Scroll") as ScrollContainer).get_v_scroll_bar()
        check(bar.max_value>bar.page and close_button().is_visible_in_tree() and game.get_global_rect().encloses(close_button().get_global_rect()),"...it still scrolls and Close is reachable")
        game._close();await frames(2);game._open("missions");await frames(16)
        check(game.sheet_reserved==0.0,"Reopened with no lesson in it: no reserve (full height)")
        game._close();await frames(2)
        # Correction: a toast on screen when a panel opens returns with its remaining time, once.
        fresh("guided");flow.data().done=flow.STEPS.duplicate();sim.campaign.onboarding.reveal_all(true);await frames(4)
        var toast_node: Control=game.get_node("Toast")
        game._toast("Probe notice A");await frames(3)
        check(toast_node.visible and toast_node.get_node("Text").text=="Probe notice A","A toast is on screen")
        var left: float=game.toast_time
        game._open("settings");await frames(6)
        check(not toast_node.visible and game.toast_queue.count("Probe notice A")==1,"A panel opens: the toast waits in its queue (once)")
        game._toast("Probe notice A");await frames(1)
        check(game.toast_queue.count("Probe notice A")==1,"...the same notice is not queued twice")
        game._close();await frames(3)
        check(toast_node.visible and toast_node.get_node("Text").text=="Probe notice A" and game.toast_time>left-0.3,"Closed: it returns with its remaining time (%.2f of %.2f)" % [game.toast_time,left])
        # More than four waiting notices: none dropped, all eventually shown.
        game._open("settings");await frames(4)
        for i in range(6):game._toast("Queued notice %d" % i)
        game.banner.hold_seconds=.05
        for i in range(6):game.banner.push("stage","Probe banner %d" % i,"")
        check(game.toast_queue.size()>=6 and game.banner.pending()==6,"Six toasts and six banners wait while a panel is open (none dropped: %d / %d)" % [game.toast_queue.size(),game.banner.pending()])
        game._close()
        var toasts_seen: Dictionary={}
        var banners_seen: Dictionary={}
        var start: int=Time.get_ticks_msec()
        while Time.get_ticks_msec()-start<20000 and (toasts_seen.size()<7 or banners_seen.size()<6):
            await get_tree().process_frame
            if toast_node.visible:toasts_seen[toast_node.get_node("Text").text]=true
            if game.banner.visible:banners_seen[str(game.banner.current.get("title",""))]=true
        var t_all:=range(6).all(func(i):return toasts_seen.has("Queued notice %d" % i))
        var b_all:=range(6).all(func(i):return banners_seen.has("Probe banner %d" % i))
        check(t_all and b_all,"...every one of them is shown afterwards (toasts %s, banners %d/6)" % [str(toasts_seen.keys()),banners_seen.size()])
        game.banner.hold_seconds=3.2;game.banner._finish();game.banner.queue.clear()
    print("CHANGE_63_CHECKS ",checks," FAILURES ",failures)
    get_tree().quit(1 if failures else 0)
