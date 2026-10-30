extends "res://tests/change_25_probe.gd"
## Change 35: the cross-platform review invitation and the enemy-targeting lesson.
## Review: 3,600 s of saved active play makes the one invitation pending; it opens only at a quiet
## moment (world and screen safe for ReviewRules.safe_seconds) on a build whose export declares a
## storefront; the world is held while it is open; Maybe Later / Back / Review are final across
## reload, Prestige and a storefront change; a failed store launch is retryable; Hard Reset re-arms.
## Storefront: Google Play and itch.io (Android APK and desktop) from the real export presets'
## feature tags; untagged, unknown or ambiguous builds never prompt.
## Targeting: Basic card 2/6 and Help; Guided step "target" after "move", completed only by a real
## drag from the player released on an enemy (sim.select_target via the map gesture).
## Runs with --first-run-complete. Storefront is switched with BootContext.store_channel_override
## (the --store-channel test override); the real export configuration is read from export_presets.cfg.
const PLAY_URL:="https://play.google.com/store/apps/details?id=com.shekinahwelefuldesigns.lootfarmeridlerpg"
const ITCH_URL:="https://shekinawd.itch.io/lootfarmer-idlerpg"
var review
var dialog: Control
var opened_urls: Array=[]
var open_result:=OK

func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    review=sim.campaign.review;dialog=game.get_node("ReviewInvitation")
    review.opener=func(url: String)->int:
        opened_urls.append(url);return open_result
    await frames(6)
    channel_checks()
    await eligibility_checks()
    await safety_checks()
    await presentation_checks()
    await persistence_checks()
    await clock_checks()
    await basic_target_checks()
    await guided_target_checks()
    await guided_recovery_checks()
    catalog_checks()
    BootContext.store_channel_override=""
    print("CHANGE_35_CHECKS %d FAILURES %d" % [checks,failures])
    get_window().size=Vector2i(720,1280)
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

## A profile whose opening is finished (None, The Road Ahead read), standing at the arrival camp with
## no living enemy, full health, out of combat: the quietest moment the game has.
func quiet(channel:="google_play",playtime:=3600.0) -> void:
    BootContext.store_channel_override=channel
    get_tree().paused=false
    if dialog.visible:dialog.close()
    fresh("none");sim.suspended=false;sim.held=false
    sim.state.tutorial.seen.append("road_ahead")
    sim.state.playtime_total=playtime
    for e in sim.state.enemies:e.hp=0;e.respawn=999.0;e.aggro=false;e.windup=0.0
    sim.state.player.hp=sim.stats().hp;sim.state.player.quiet=9.0;sim.state.player.windup=0.0
    sim.movement=Vector2.ZERO;game.stick_input=Vector2.ZERO
    game._cancel_confirm();game.get_node("PrestigeConfirm").close();game.toast_queue.clear()
    game.review_safe=0.0
    opened_urls.clear();open_result=OK
    await frames(2) # the guide and HUD settle on the new profile
    sim.movement=Vector2.ZERO;game.stick_input=Vector2.ZERO
## Offers the invitation the given seconds of continuous frames would (the UI's own clock).
func offer(seconds: float) -> void:
    var left:=seconds
    while left>0.0001:
        game._offer_review(minf(.25,left));left-=.25

# ---------------------------------------------------------------- 6a. storefront matrix
func channel_checks() -> void:
    check(not dialog.visible and not dialog.is_open() and not dialog.prewarming and dialog.mouse_filter==Control.MOUSE_FILTER_STOP and dialog.get_node("Shade").mouse_filter==Control.MOUSE_FILTER_STOP and dialog.get_node("Plate").mouse_filter==Control.MOUSE_FILTER_STOP and dialog.modulate.a==1.0,"After startup the panel is hidden, its one invisible layout pass done, its input filters restored")
    var channels=review.channels
    check(channels.url("google_play")==PLAY_URL and channels.url("itch_io")==ITCH_URL,"Exact store URLs from the brief")
    check(tr(channels.cta("google_play"))=="Review on Google Play" and tr(channels.cta("itch_io"))=="Review on itch.io","Store-specific button text")
    var has:=func(tags: Array)->Callable:return func(tag: String)->bool:return tags.has(tag)
    check(channels.resolve(has.call(["Android","mobile","store_google_play"]))=="google_play","Google Play Android build -> google_play")
    check(channels.resolve(has.call(["Android","mobile","store_itch_io"]))=="itch_io","itch.io Android build -> itch_io")
    check(channels.resolve(has.call(["Windows","pc","store_itch_io"]))=="itch_io","itch.io desktop build -> itch_io")
    check(channels.resolve(has.call(["Android","mobile"]))=="" and channels.resolve(has.call(["Windows","pc"]))=="","Untagged Android or desktop build -> none (the OS is not the store)")
    check(channels.resolve(has.call(["store_google_play","store_itch_io"]))=="","Two store tags -> none (ambiguous)")
    check(channels.resolve(has.call(["store_steam"]))=="","Unknown store tag -> none")
    BootContext.store_channel_override=""
    check(channels.current()=="","This probe run (editor/debug, no export tag) has no storefront")
    BootContext.store_channel_override="none"
    check(channels.current()=="","--store-channel=none -> none")
    # The real export configuration.
    var cfg:=ConfigFile.new()
    check(cfg.load("res://export_presets.cfg")==OK,"export_presets.cfg readable")
    var found: Dictionary={}
    for section in cfg.get_sections():
        if section.ends_with(".options") or not section.begins_with("preset."):continue
        var name: String=cfg.get_value(section,"name","")
        found[name]={"platform":cfg.get_value(section,"platform",""),"channel":channels.channel_for_features(cfg.get_value(section,"custom_features","")),
            "package":cfg.get_value(section+".options","package/unique_name",""),"format":cfg.get_value(section+".options","gradle_build/export_format",-1),
            "files":cfg.get_value(section,"export_files",PackedStringArray()).size()}
    check(found.get("Android Release",{}).get("platform")=="Android" and found["Android Release"].channel=="google_play" and found["Android Release"].format==1,"Export 'Android Release' (Play AAB) -> google_play")
    check(found.get("Android itch.io APK",{}).get("platform")=="Android" and found["Android itch.io APK"].channel=="itch_io" and found["Android itch.io APK"].format==0,"Export 'Android itch.io APK' -> itch_io")
    check(found.has("Windows itch.io") and found["Windows itch.io"].platform=="Windows Desktop" and found["Windows itch.io"].channel=="itch_io","Export 'Windows itch.io' -> itch_io on desktop")
    check(found["Android Release"].package==found["Android itch.io APK"].package and found["Android Release"].channel!=found["Android itch.io APK"].channel,"Same Android OS and package, two distinguishable storefronts")
    check(found.get("Android Bootstrap APK",{}).get("channel","x")=="","The bootstrap test APK declares no storefront (never prompts)")
    check(found["Android itch.io APK"].files==found["Android Release"].files and found["Windows itch.io"].files==found["Android Release"].files and found["Android Release"].files>0,"Every release preset ships the same allowlist")
    for path in ["res://scripts/game/review_invitation.gd","res://scripts/game/distribution_channels.gd","res://scripts/game/review_dialog.gd"]:
        var src:=FileAccess.get_file_as_string(path)
        check(not src.contains("has_feature(\"Android") and not src.contains("has_feature(\"mobile") and not src.contains("OS.get_name") and not src.contains("unique_name"),"%s never infers the store from OS, platform or package" % path.get_file())

# ---------------------------------------------------------------- 1. eligibility
func eligibility_checks() -> void:
    await quiet("google_play",3599.0)
    offer(10.0)
    check(review.status()=="none" and not dialog.visible and game.review_block=="time","3,599 s: not eligible, never shown")
    sim.state.playtime_total=3600.0;await quiet("google_play",3600.0)
    sim.state.enemies[0].hp=10.0;sim.state.enemies[0].aggro=true # fixture: a fight in progress
    offer(10.0)
    check(review.status()=="pending" and float(sim.state.review.eligible_at)==3600.0 and not dialog.visible and game.review_block=="combat","Exactly 3,600 s in combat: pending, not shown")
    sim.state.enemies[0].hp=0.0;sim.state.enemies[0].aggro=false;sim.state.player.quiet=0.0
    offer(4.0)
    check(not dialog.visible and game.review_block=="combat","Just after the fight (the 5 s combat cool-down) it still waits")
    sim.state.player.quiet=9.0
    offer(1.0)
    check(not dialog.visible and game.review_block=="","Safe again: waits for the continuous safe period")
    offer(1.25)
    check(dialog.visible and sim.held,"After %.0f s of continuous safety it opens and holds the world" % review.rules.safe_seconds)
    game._review_later()

# ---------------------------------------------------------------- 2. never interrupts
func safety_checks() -> void:
    var cases: Array=[
        ["boss nearby",func():
            for e in sim.state.enemies:
                if sim.catalog.groups[int(e.group)].boss:e.hp=100.0;sim.state.player.x=e.x+120;sim.state.player.y=e.y;break,"boss"],
        ["boss engaging",func():
            for e in sim.state.enemies:
                if sim.catalog.groups[int(e.group)].boss:e.hp=100.0;e.aggro=true;break,"boss"],
        ["HP 49%",func():sim.state.player.hp=sim.stats().hp*.49,"health"],
        ["enemy attack wind-up",func():sim.state.enemies[1].hp=5.0;sim.state.enemies[1].windup=.3,"combat"],
        ["player attack pending",func():sim.state.player.windup=.2,"combat"],
        ["dead / respawning",func():sim.state.player.hp=0.0;sim.state.player.respawn=4.0,"dead"],
        ["Guided tutorial",func():sim.state.tutorial.mode="guided";sim.campaign.guided.data().done=[],"tutorial"],
        ["Basic overview",func():sim.state.tutorial.mode="basic";sim.state.tutorial.seen.erase("road_ahead"),"tutorial"],
        ["guide chooser",func():sim.state.tutorial.mode="pending","chooser"],
        ["panel open",func():game._open("missions"),"panel"],
        ["confirmation",func():game._confirm("probe",func()->void:pass),"modal"],
        ["Prestige confirmation",func():game.get_node("PrestigeConfirm").show(),"modal"],
        ["Prestige choice",func():sim.state.prestige_batch={"ids":["x"],"choices":[]},"prestige"],
        ["offline claim pending",func():sim.state.offline_pending={"id":"probe","seconds":60.0},"offline"],
        ["pause",func():get_tree().paused=true,"paused"],
        ["background",func():sim.suspended=true,"paused"],
        ["announcement",func():game.banner.current={"kind":"probe"},"announcement"],
        ["joystick held",func():game.stick_input=Vector2(1,0),"input"],
        ["moving",func():sim.movement=Vector2(0,1),"moving"],
        ["map touch",func():game.get_node("Safe/Layout/Map/GestureSurface").pointers[0]=Vector2(10,10),"input"]]
    for c in cases:
        await quiet()
        c[1].call()
        offer(30.0)
        check(not dialog.visible and game.review_block==c[2] and review.status()=="pending","Never interrupts: %s (%s)" % [c[0],game.review_block])
        game.get_node("Safe/Layout/Map/GestureSurface").pointers.clear()
        game.banner.current={};game._close();sim.state.prestige_batch={};sim.state.offline_pending={};game.offline_prompted=""
    get_tree().paused=false
    # Short gaps between attacks never accumulate into a show.
    await quiet()
    for i in range(10):
        offer(1.5);sim.state.player.windup=.2;offer(.25);sim.state.player.windup=0.0
    check(not dialog.visible,"Safe gaps of 1.5 s between attacks never open it")
    # Missing storefront: pending stays pending and is not consumed.
    await quiet("none")
    offer(30.0)
    check(not dialog.visible and review.status()=="pending" and game.review_block=="channel","No configured storefront: no prompt, eligibility kept")
    BootContext.store_channel_override="itch_io"
    offer(2.5)
    check(dialog.visible and dialog.review_button.text=="Review on itch.io","A correctly configured build later still offers it (itch.io)")
    game._review_later()

# ---------------------------------------------------------------- 3/4. presentation and holding
func presentation_checks() -> void:
    for shape in [Vector2i(720,1280),Vector2i(540,960),Vector2i(432,960),Vector2i(360,640),Vector2i(1200,1600),Vector2i(1280,720)]:
        get_window().size=shape;await frames(3)
        await quiet("google_play")
        game.open_review() # same call the quiet-moment offer makes; inspected before any frame passes
        var plate: Control=dialog.get_node("Plate")
        var first: Rect2=plate.get_global_rect()
        var view: Rect2=game.get_global_rect()
        var title: Label=dialog.get_node("Plate/Margin/Content/Header/Text/Title")
        var body: Label=dialog.get_node("Plate/Margin/Content/Scroll/Body/Text")
        var first_ok: bool=dialog.visible and dialog.modulate.a==1.0 and plate.modulate.a==1.0 and plate.scale==Vector2.ONE and tr(title.text)=="Enjoying LootFarmer?" and tr(body.text).contains("honest review") and usable(dialog.review_button) and usable(dialog.later_button) and dialog.review_button.text=="Review on Google Play" and tr(dialog.later_button.text)=="Maybe Later"
        check(first_ok,"%s first frame: whole message and both working buttons, no fade or scale" % str(shape))
        await frames(4)
        var settled: Rect2=plate.get_global_rect()
        check(settled.size.distance_to(first.size)<=2.0 and settled.position.distance_to(first.position)<=2.0,"%s first frame already has its final size (%s vs %s)" % [str(shape),str(first),str(settled)])
        var review_rect: Rect2=dialog.review_button.get_global_rect();var later_rect: Rect2=dialog.later_button.get_global_rect()
        check(view.grow(1).encloses(settled) and settled.grow(1).encloses(review_rect) and settled.grow(1).encloses(later_rect) and not review_rect.intersects(later_rect),"%s panel and both buttons on screen" % str(shape))
        check(review_rect.size.y>=72 and later_rect.size.y>=56 and dialog.review_button.get_theme_font_size("font_size")>dialog.later_button.get_theme_font_size("font_size") and dialog.review_button.theme_type_variation==&"Primary","%s store button prominent (%.0f px), Maybe Later touch-sized (%.0f px)" % [str(shape),review_rect.size.y,later_rect.size.y])
        dialog.later_button.pressed.emit()
    get_window().size=Vector2i(720,1280);await frames(3)
    # The world is held while it is open: no step, damage, clocks or playtime.
    await quiet("google_play")
    offer(2.5)
    var foe: Dictionary=sim.state.enemies[2]
    foe.hp=50.0;foe.x=sim.state.player.x+10;foe.y=sim.state.player.y;foe.aggro=true;foe.windup=.05
    var before:={"hp":sim.state.player.hp,"play":sim.state.playtime_total,"clock":sim.state.clock}
    for i in range(50):sim.step(.1)
    await frames(2)
    check(dialog.visible and sim.state.player.hp==before.hp and sim.state.playtime_total==before.play and sim.state.clock==before.clock,"While open: no damage, no clock, no playtime")
    check(game.modal_open() and not game.guide.card.visible and game.banner.held,"While open it counts as a modal (guide and banners wait)")
    foe.hp=0.0;foe.aggro=false;foe.windup=0.0
    # Back = Maybe Later.
    game.back();await frames(2)
    check(not dialog.visible and not sim.held and review.status()=="dismissed","Back dismisses it like Maybe Later and the world resumes")
    sim.step(.1)
    check(sim.state.playtime_total>before.play,"Playtime runs again after closing")
    var esc:=InputEventKey.new();esc.keycode=KEY_ESCAPE;esc.physical_keycode=KEY_ESCAPE;esc.pressed=true
    await quiet("itch_io");offer(2.5)
    game._unhandled_key_input(esc);await frames(2)
    check(not dialog.visible and review.status()=="dismissed" and not game.get_node("Confirm").visible,"Escape (desktop) dismisses it too, without the exit confirmation")
    # Pseudo-localized (about 40% longer) text still fits the smallest phone.
    get_window().size=Vector2i(360,640);await frames(3)
    await quiet("google_play")
    game.open_review()
    var long:=func(t: String)->String:return "[" + t + " " + t.substr(0,int(t.length()*.4)) + "]"
    for path in ["Header/Text/Title","Header/Text/Lead","Scroll/Body/Text"]:
        var l: Label=dialog.get_node("Plate/Margin/Content/"+path);l.text=long.call(tr(l.text))
    dialog.review_button.text=long.call(dialog.review_button.text);dialog.later_button.text=long.call(tr(dialog.later_button.text))
    dialog._layout();await frames(4)
    var r: Rect2=dialog.get_node("Plate").get_global_rect()
    check(game.get_global_rect().grow(1).encloses(r) and r.grow(1).encloses(dialog.review_button.get_global_rect()) and r.grow(1).encloses(dialog.later_button.get_global_rect()) and dialog.review_button.get_global_rect().size.x<=r.size.x,"360x640 with 40% longer text: buttons stay on screen (the message scrolls)")
    dialog.later_button.pressed.emit()
    get_window().size=Vector2i(720,1280);await frames(3)

# ---------------------------------------------------------------- 5. persistence and routing
func persistence_checks() -> void:
    # Maybe Later: final across reload (JSON and disk), Prestige and a storefront change.
    await quiet("google_play");offer(2.5)
    dialog.later_button.pressed.emit()
    check(review.status()=="dismissed" and opened_urls.is_empty() and sim.state.review.channel=="google_play","Maybe Later: dismissed, nothing opened")
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())));offer(10.0)
    check(review.status()=="dismissed" and not dialog.visible,"…kept after a save/load round trip")
    check(SaveService.save_now(),"…saved to disk");SaveService.load_and_apply();offer(10.0)
    check(review.status()=="dismissed" and not dialog.visible,"…kept after a real disk reload")
    check(do_prestige(),"Prestige");await frames(2);offer(10.0)
    check(review.status()=="dismissed" and not dialog.visible,"…kept by Prestige")
    BootContext.store_channel_override="itch_io";offer(10.0)
    check(not dialog.visible and review.status()=="dismissed","…no new prompt when the save moves to another storefront")
    # Review on Google Play opens the exact listing; nothing claims a review was written.
    await quiet("google_play");offer(2.5)
    dialog.review_button.pressed.emit()
    check(opened_urls==[PLAY_URL] and review.status()=="opened" and not dialog.visible,"Google Play button opens the Play listing; recorded as opened")
    var labels: String=labels_text(game)
    check(not labels.to_lower().contains("thank you for your review") and not labels.to_lower().contains("review submitted"),"No claim that a review was submitted")
    BootContext.store_channel_override="itch_io";offer(10.0)
    check(not dialog.visible,"Opened is final across storefronts too")
    # itch.io build: exact game page.
    await quiet("itch_io");offer(2.5)
    dialog.review_button.pressed.emit()
    check(opened_urls==[ITCH_URL] and review.status()=="opened","itch.io button opens the itch.io game page")
    # Launch failure: retryable, explained, never recorded as opened.
    await quiet("google_play");offer(2.5)
    open_result=ERR_CANT_OPEN
    dialog.review_button.pressed.emit()
    var error: Label=dialog.get_node("Plate/Margin/Content/Scroll/Body/Error")
    check(dialog.visible and error.visible and error.text==tr("REVIEW_OPEN_FAILED") and review.status()=="pending" and int(sim.state.review.open_failures)==1 and usable(dialog.review_button) and usable(dialog.later_button),"Store launch failure: message shown, still pending, both buttons usable")
    open_result=OK
    dialog.review_button.pressed.emit()
    check(not dialog.visible and review.status()=="opened" and opened_urls==[PLAY_URL,PLAY_URL],"…and the retry opens it")
    # Settings: an unprompted manual action for the active storefront only.
    await quiet("itch_io");sim.state.playtime_total=10.0
    game._open("settings");await frames(2)
    var manual: Button=button("review_store")
    check(manual!=null and manual.text=="Review on itch.io","Settings offers Review on itch.io on an itch.io build")
    if manual!=null:manual.pressed.emit()
    check(opened_urls==[ITCH_URL] and review.status()=="opened","…it opens the itch.io page and settles the automatic invitation")
    game._close()
    await quiet("none");game._open("settings");await frames(2)
    check(button("review_store")==null,"…and is absent on a build without a storefront")
    game._close()
    # Hard Reset: a genuinely new profile earns the invitation after a new hour.
    await quiet("google_play");offer(2.5);dialog.later_button.pressed.emit()
    check(SaveService.hard_reset(),"Hard Reset");await frames(2)
    check(review.status()=="none" and float(sim.state.playtime_total)==0.0,"Hard Reset: a new profile starts at not offered with no playtime")
    # Old saves (no review record) and malformed records load cleanly.
    var old: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()));old.erase("review");old.playtime_total=4000.0
    sim.restore(old)
    check(SaveService.last_load_result!="invalid_profile_reset" and review.status()=="none" and review.wanted()==(review.channel()!="") and review.status()=="pending","A pre-Change-35 save past one hour loads and becomes pending")
    var bad: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()));bad.review={"status":"weird","open_failures":"x"}
    sim.restore(bad)
    check(review.status()=="none" and int(sim.state.review.open_failures)==0,"A malformed record is repaired, not fatal")

# ---------------------------------------------------------------- 6. the eligibility clock
func clock_checks() -> void:
    await quiet("google_play",100.0)
    var t: float=sim.state.playtime_total
    get_tree().paused=true;for i in range(20):sim.step(.1)
    get_tree().paused=false
    sim.suspended=true;for i in range(20):sim.step(.1)
    sim.suspended=false
    sim.held=true;for i in range(20):sim.step(.1)
    sim.held=false
    sim.state.prestige_batch={"ids":["x"],"choices":[]};for i in range(20):sim.step(.1)
    sim.state.prestige_batch={}
    check(is_equal_approx(float(sim.state.playtime_total),t),"Pause, background, the open invitation and a Prestige choice add no playtime")
    for i in range(20):sim.step(.1)
    check(is_equal_approx(float(sim.state.playtime_total),t+2.0),"Active play adds exactly its seconds")
    sim.state.boss_saved_at=Time.get_unix_time_from_system()-7200.0;sim.state.offline_snapshot=sim.campaign.offline_snapshot()
    var before: float=sim.state.playtime_total
    sim.campaign.settle_offline()
    check(is_equal_approx(float(sim.state.playtime_total),before),"Offline settlement adds no playtime")

# ---------------------------------------------------------------- 7. Basic card and Help
func basic_target_checks() -> void:
    BootContext.store_channel_override=""
    await choose("basic")
    var guide=game.guide
    check(guide.BASIC_DECK[1]=="basic_target" and guide.BASIC_DECK.size()==6,"Basic deck: the targeting card right after the overview (6 cards)")
    guide.intro_button.pressed.emit();await frames(3)
    check(guide.pending=="basic_target" and guide.card.visible and guide.title.text=="Target an enemy  2/6" and guide.support.text.begins_with("Drag from your hero to an enemy, then release to target it."),"Basic shows \"%s\": %s" % [guide.title.text,guide.support.text])
    check(not guide.pointer.visible and not guide.aim.visible and guide.skip_button.visible and guide.intro_button.visible,"…text only (no pointer or demo), with Skip and Got it")
    guide._process(sim.campaign.onboarding.rules.card_seconds+.5);await frames(2)
    check(sim.state.tutorial.seen.has("basic_target") and guide.pending=="basic_gear","…and retires on its own after %d s" % int(sim.campaign.onboarding.rules.card_seconds))
    var none_shown:=false
    await choose("none")
    for i in range(5):
        guide._process(.5);await frames(1)
        if guide.pending in ["basic_target","target"] or guide.aim.visible:none_shown=true
    check(not none_shown,"None never shows the targeting lesson")
    sim.state.tutorial.seen.append("road_ahead")
    game._open("settings");await frames(2);game._open("help");await frames(2)
    var text: String=labels_text(game.rows)
    check(text.contains("Target an enemy") and text.contains("Drag from your hero to an enemy"),"Help includes the targeting card")
    game._close()

# ---------------------------------------------------------------- 8. Guided: the real gesture
var surface: Control
func guided_at_target() -> Dictionary:
    BootContext.store_channel_override=""
    get_tree().paused=false
    fresh("guided");sim.suspended=false
    sim.campaign.guided.data().done=["move"]
    var rules: OnboardingRules=sim.campaign.onboarding.rules
    sim.state.player.x=rules.path_target.x;sim.state.player.y=rules.path_target.y
    var foe: Dictionary={}
    for e in sim.state.enemies:
        if not sim.catalog.groups[int(e.group)].boss and foe.is_empty():foe=e
        else:e.hp=0.0;e.respawn=999.0
    foe.hp=maxf(foe.hp,30.0);foe.x=sim.state.player.x+55;foe.y=sim.state.player.y-25;foe.aggro=false
    sim.campaign.reveal_circle(sim.position_of(foe),80)
    surface=game.get_node("Safe/Layout/Map/GestureSurface")
    game.world.follow_player();game.world.update_camera()
    await frames(4)
    return foe
func screen_of(world_point: Vector2) -> Vector2:
    var scale_: Vector2=surface.size/game.world.get_viewport_rect().size
    return (game.world.get_canvas_transform()*world_point)*scale_
func drag(from: Vector2,to: Vector2) -> void:
    surface.begin_pointer(0,from);surface.move_pointer(0,from.lerp(to,.5));surface.move_pointer(0,to);surface.end_pointer(0,to)
func target_count() -> int:return sim.campaign.guided.data().done.count("target")

func guided_target_checks() -> void:
    var foe: Dictionary=await guided_at_target()
    var guide=game.guide
    check(guide.pending=="target" and guide.step=="target" and guide.title.text=="Target an enemy","Guided: after the path, \"%s\"" % guide.title.text)
    check(guide.support.text=="Drag from your hero to an enemy, then release to target it. You'll focus your attacks on the selected enemy.","…with the gesture spelled out")
    check(guide.world_target==sim.position_of(foe) and guide.aim.visible and guide.pointer.visible,"…and a drawn demo from the hero to that enemy")
    var hero: Vector2=game.get_node("Safe/Layout/Map").global_position+game.world.player_screen_position()*game.get_node("Safe/Layout/Map").size/game.world.get_viewport_rect().size
    check(guide.aim_from.distance_to(hero)<2.0 and guide.aim_to.distance_to(game.get_node("Safe/Layout/Map").global_position+screen_of(sim.position_of(foe)+Vector2(0,-10)))<2.0,"…starting on the hero and ending on the enemy")
    check(guide.aim.mouse_filter==Control.MOUSE_FILTER_IGNORE and guide.card.mouse_filter==Control.MOUSE_FILTER_IGNORE and guide.pointer.mouse_filter==Control.MOUSE_FILTER_IGNORE and guide.mouse_filter==Control.MOUSE_FILTER_IGNORE,"The demo, card and pointer never take input")
    var hero_point: Vector2=game.world.player_screen_position()*surface.size/game.world.get_viewport_rect().size
    var foe_point: Vector2=screen_of(sim.position_of(foe)+Vector2(0,-10))
    # Wrong gestures never complete it.
    drag(hero_point+Vector2(160,140),foe_point)
    check(target_count()==0 and sim.manual_target=="","A drag that starts off the hero (a camera pan) does not count")
    game.world.follow_player();game.world.update_camera();await frames(2)
    hero_point=game.world.player_screen_position()*surface.size/game.world.get_viewport_rect().size;foe_point=screen_of(sim.position_of(foe)+Vector2(0,-10))
    drag(hero_point,hero_point+Vector2(-120,90))
    check(target_count()==0 and sim.manual_target=="","A drag from the hero released on empty ground does not count")
    surface.begin_pointer(0,foe_point);surface.end_pointer(0,foe_point)
    check(target_count()==0,"Tapping the enemy does not count")
    var at: Vector2=sim.position_of(sim.state.player)
    sim.movement=Vector2(1,0);for i in range(3):sim.step(.1)
    sim.movement=Vector2.ZERO
    check(target_count()==0,"Joystick movement does not count")
    sim.state.player.x=at.x;sim.state.player.y=at.y
    sim.state.player.idle=1.0;sim._combat_target();sim.step(.1)
    check(target_count()==0 and sim.locked_target!="" and sim.manual_target=="","Automatic acquisition (locked, not manual) does not count")
    check(not sim.select_target("player") and target_count()==0,"A refused selection does not count")
    sim.state.counters["kill"]=1.0;await frames(2)
    check(guide.pending=="target" and target_count()==0,"An automatic kill does not skip it")
    sim.state.counters.erase("kill")
    # The real gesture.
    game.world.follow_player();game.world.update_camera();await frames(2)
    hero_point=game.world.player_screen_position()*surface.size/game.world.get_viewport_rect().size;foe_point=screen_of(sim.position_of(foe)+Vector2(0,-10))
    surface.begin_pointer(0,hero_point);surface.move_pointer(0,foe_point)
    await frames(1)
    check(surface.aiming and not guide.aim.visible,"While the player aims, the demo steps aside for the real aim line")
    surface.end_pointer(0,foe_point);await frames(2)
    check(sim.manual_target==foe.id and target_count()==1,"Drag from the hero, release on the enemy: selected and the step completes")
    check(guide.pending=="kill" and not guide.aim.visible,"The tutorial continues (%s), demo gone" % guide.pending)
    sim.clear_target();game.world.follow_player();game.world.update_camera();await frames(2)
    hero_point=game.world.player_screen_position()*surface.size/game.world.get_viewport_rect().size;foe_point=screen_of(sim.position_of(foe)+Vector2(0,-10))
    drag(hero_point,foe_point)
    check(target_count()==1,"A second targeting does not complete it twice")
    # Basic and None profiles never receive the Guided action.
    fresh("basic");sim.state.enemies[0].hp=10;sim.campaign.reveal_circle(sim.position_of(sim.state.enemies[0]),60)
    sim.select_target(sim.state.enemies[0].id)
    check(not sim.campaign.guided.data().done.has("target"),"Basic: targeting records no Guided step")

# ---------------------------------------------------------------- 9. recovery
func guided_recovery_checks() -> void:
    var guide=game.guide
    var foe: Dictionary=await guided_at_target()
    var other: Dictionary={}
    for e in sim.state.enemies:
        if e.id!=foe.id and not sim.catalog.groups[int(e.group)].boss:other=e;break
    other.hp=30.0;other.respawn=0.0;other.x=sim.state.player.x-55;other.y=sim.state.player.y+20
    sim.campaign.reveal_circle(sim.position_of(other),80)
    foe.hp=0.0;foe.respawn=999.0;await frames(3)
    check(guide.pending=="target" and guide.world_target==sim.position_of(other) and guide.aim.visible,"The suggested enemy dies: the demo moves to another")
    other.hp=0.0;other.respawn=999.0;await frames(3)
    check(guide.step=="target_find" and guide.title.text=="Find an enemy to target" and not guide.aim.visible,"No enemy in sight: \"%s\", no demo" % guide.title.text)
    var limit: float=sim.campaign.onboarding.rules.target_escape_seconds
    guide._process(limit*.5);await frames(1)
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())));sim.set_physics_process(false)
    for e in sim.state.enemies:e.hp=0.0;e.respawn=999.0
    await frames(3)
    check(guide.pending=="target" and absf(float(sim.campaign.guided.data().target_unavailable)-limit*.5)<1.0,"Reload mid-step: still pending, the escape time is kept")
    get_tree().paused=true;guide._process(limit);get_tree().paused=false
    check(target_count()==0,"Paused time never counts")
    guide._process(limit*.5+.1);await frames(2)
    check(target_count()==1 and sim.campaign.guided.data().target_skipped==true and guide.pending!="target","After %.0f s with nothing to target the step passes (target_skipped) instead of waiting" % limit)
    # With an enemy to target, time alone never passes it.
    foe=await guided_at_target()
    for i in range(10):guide._process(limit*.5)
    check(target_count()==0 and guide.pending=="target","With an enemy in sight, %.0f s pass without completing it" % (limit*5))
    # Other surfaces suspend it without losing it.
    game._open("settings");await frames(2)
    check(game.sheet.visible and not guide.card.visible and not guide.aim.visible and not guide.pointer.visible and guide.pending=="target","A panel suspends the lesson")
    game._close();await frames(2)
    check(guide.aim.visible,"…which returns when the panel closes")
    get_tree().paused=true;await frames(2)
    check(not guide.aim.visible and not guide.card.visible,"Pause hides it")
    get_tree().paused=false;await frames(2)
    # Screen sizes: the demo stays on the map.
    for shape in [Vector2i(540,960),Vector2i(432,960),Vector2i(360,640)]:
        get_window().size=shape;await frames(4)
        foe=await guided_at_target()
        var map: Rect2=game.get_node("Safe/Layout/Map").get_global_rect()
        check(guide.aim.visible and map.has_point(guide.aim_from) and map.has_point(guide.aim_to) and map.encloses(guide.card.get_global_rect()),"%s: demo and card on the map" % str(shape))
    get_window().size=Vector2i(720,1280);await frames(3)
    # Old saves keep their place.
    fresh("guided");sim.campaign.guided.data().done=["move","kill","collect","equip"]
    check(sim.campaign.guided.next_step()!="target","A save from before the step, past the first kill, never goes back")
    var old: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    old.tutorial.flow.done=["move","kill"];old.tutorial.flow.erase("target_unavailable");old.tutorial.flow.erase("target_skipped")
    sim.restore(old)
    check(sim.campaign.guided.data().done.has("target") and sim.campaign.guided.next_step()!="target","…and is reconciled on load")
    fresh("guided");sim.state.tutorial.erase("flow");sim.state.stage=2
    check(sim.campaign.guided.data().done.has("target"),"Existing players beyond Winter I receive the step as done")
    fresh("guided");sim.campaign.guided.data().done=sim.campaign.guided.STEPS.duplicate();sim.campaign.guided.data().done.erase("target");await frames(2)
    check(guide.pending!="target" and not guide.aim.visible,"A finished tutorial never shows the targeting lesson")

# ---------------------------------------------------------------- 10. English catalog
func catalog_checks() -> void:
    var keys: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/change35_strings.json"))
    var po:=FileAccess.get_file_as_string("res://localization/en.po")
    var ok:=true
    for key in keys:
        if tr(key)!=keys[key] or not po.contains("msgid \"%s\"" % key) or "%" in keys[key] or "--" in keys[key]:ok=false
    check(ok and keys.size()==14,"All 14 new English strings in en.po, no placeholders, no double dashes")
    # Change 40 (progressive activation): localization/ also holds the developer's drafts; what matters is what a
    # player can reach. English is registered in project.godot, the nineteen enabled catalogs ship through the export
    # manifest and are selectable, and no draft is packaged or selectable.
    var registered: PackedStringArray=ProjectSettings.get_setting("internationalization/locale/translations")
    var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/export_manifest.json"))
    var shipped: Array=manifest.files.keys().filter(func(f):return f.begins_with("res://localization/"))
    var expected: Array=LocalizationService.ENABLED_LANGUAGES.map(func(l):return "res://localization/%s.po" % ("en" if l=="en_US" else l))
    shipped.sort();expected.sort()
    var drafts:=LocalizationService.RELEASE_LANGUAGES.filter(func(l):return not l in LocalizationService.ENABLED_LANGUAGES)
    check(registered==PackedStringArray(["res://localization/en.po"]) and shipped==expected and expected.size()==20,"Exactly English and the nineteen enabled catalogs ship (%d localization files in the manifest)" % shipped.size())
    check(LocalizationService.available_languages()==LocalizationService.ENABLED_LANGUAGES and drafts.is_empty() and not LocalizationService.select_language("ar_SA"),"No draft remains and a locale outside the target set is not selectable")
    var text: String=tr("REVIEW_BODY")+" "+tr("REVIEW_TITLE")+" "+tr("REVIEW_LEAD")
    var lower:=text.to_lower()
    check(lower.contains("honest") and not lower.contains("5 star") and not lower.contains("five star") and not lower.contains("reward") and not lower.contains("gem"),"The request is for an honest review: no stars, rewards or pressure")
