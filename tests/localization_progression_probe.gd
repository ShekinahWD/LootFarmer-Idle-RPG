extends "res://tests/localization_sweep.gd"
## Localization Batch 01 of the progression update (Changes 50-55; Playbook 132.5): the screens that show the 104
## new or changed keys, rendered in each integrated language at the phone shapes, with the sweep's own checks
## (raw keys, English leaks, missing glyphs, clipped or off-screen text, small buttons) plus:
## - coverage: on each screen, the listed progression keys are really on screen in the current language (the
##   literal text of the translation, or its longest fragment between placeholders, is found in a visible label,
##   button or rich text), so a fixture that stops showing a key fails instead of passing silently;
## - layout: the Prestige confirmation plate and the item panel stay inside the screen;
## - live switching with the Prestige card choice (eight Expedition cards) and the boss-enhanced item panel open:
##   the panel redraws in the new language.
## Screens: World with the Map Detail hint, welcome-back with the offline gear hint and its jump button, Upgrades >
## Offline, a boss-enhanced weapon with three Reroll slots and the reroll confirmation, a plain weapon (boss bonus
## hint), a weapon at its merge cap (evolution rule), an old-stat legacy copy, the evolution-ready toast, the
## Prestige panel with 48 opportunities, the Prestige confirmation (keep/reset lines) and the eight-card choice.
## Headless: -- --probe --profile=probe-l10n-progression --no-autosave --first-run-complete
##   [--langs=en,es_419,es_ES,pt_BR,fr_FR,de_DE] [--sizes=432x960,540x960]
## Windowed evidence: --resolution 432x960 ... --shots=res://docs/.../ --shape=432 (one size per run).
const PROGRESSION_LANGS:=["en","es_419","es_ES","pt_BR","fr_FR","de_DE"]
## Keys whose text must be visible on each screen (format keys: their longest literal fragment).
const EXPECT:={
    "world_map_hint":["MAP_MARKERS_HINT"],
    "offline_gear_hint":["OFFLINE_ITEMS_HINT","OFFLINE_UPGRADES_JUMP"],
    "upgrades_offline":["OFFLINE_GEAR_BENEFIT"],
    "item_boss_enhanced":["ITEM_BOSS_BONUS","ITEM_BOSS_BONUS_EXPLAIN","REROLL_ATTRIBUTE"],
    "confirm_reroll":["REROLL_ATTRIBUTE_CONFIRM"],
    "item_boss_hint":["ITEM_BOSS_BONUS_HINT"],
    "item_evolution_rule":["EVOLUTION_RULE"],
    "item_legacy":["ITEM_LEGACY_NAME","LEGACY_ITEM_EXPLAIN"],
    "toast_evolve_ready":["EVOLVE_READY_HINT"],
    "prestige_confirm":["KEEP_LINE_COINS","KEEP_LINE_ALL_UPGRADES","KEEP_LINE_MERGES","KEEP_LINE_MAIN_OBJECTIVES","RESET_LINE_CARRIED_ITEMS","RESET_LINE_RUN_PROGRESS"],
    "prestige_cards8":["PRESTIGE_KEEP_ALL","PRESTIGE_RESET_RUN","CONTENT_EXPEDITION_C4_NAME","CONTENT_EXPEDITION_C5_NAME","CONTENT_EXPEDITION_C6_NAME","CONTENT_EXPEDITION_C7_NAME","CONTENT_EXPEDITION_C8_NAME"],
}
var coverage_checks:=0
var switch_checks:=0
## Pre-existing findings that English shows too and that do not depend on the translation: counted and reported
## (summary "known"), not failed. The History feed's +N pickup buttons are 40 units tall; the Prestige panel's
## card chips (Change 54) are ellipsis labels sharing one row by design.
var known: Dictionary={}

func add(screen: String,kind: String,text: String,node: Node=null) -> void:
    var why:=""
    if kind=="small_button" and node!=null and game.has_node("Safe/Layout/Map/History") and game.get_node("Safe/Layout/Map/History").is_ancestor_of(node):why="history_feed_button_40"
    elif kind=="clipped" and node is Label and node.text_overrun_behavior==TextServer.OVERRUN_TRIM_ELLIPSIS and node.get_parent() is HBoxContainer and game.panel=="prestige":why="prestige_card_chip_ellipsis"
    if why!="":
        known[why]=int(known.get(why,0))+1
        return
    super.add(screen,kind,text,node)

func run() -> void:
    langs=PROGRESSION_LANGS.duplicate()
    sizes=[]
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--langs="):langs=Array(arg.trim_prefix("--langs=").split(","))
        elif arg.begins_with("--sizes="):sizes=Array(arg.trim_prefix("--sizes=").split(","))
        elif arg.begins_with("--shots="):shots=arg.trim_prefix("--shots=")
        elif arg.begins_with("--shape="):shape=arg.trim_prefix("--shape=")
        elif arg.begins_with("--report="):report_path=arg.trim_prefix("--report=")
    english=read_po("res://localization/en.po")
    for key in english:
        var value: String=english[key]
        if value.split(" ").size()>=3 and not "%" in value:english_values[value]=key
    for lang in langs:
        if lang!="en":translations[lang]=read_po("res://localization/%s.po" % lang)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.campaign.review.opener=func(_url: String)->int:return ERR_CANT_OPEN
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    await frames(10)
    if sizes.is_empty():sizes=["%dx%d" % [get_window().size.x,get_window().size.y]] if shots!="" else ["432x960","540x960"]
    for size_text in sizes:
        var parts: PackedStringArray=size_text.split("x")
        if shots=="":get_window().size=Vector2i(int(parts[0]),int(parts[1]))
        await settle()
        current_size=size_text
        for lang in langs:
            current_lang=lang
            check_select(lang)
            await frames(3)
            await progression_screens()
        await live_switch()
    LocalizationService.select_language("automatic")
    LocalizationService.set_test_device_locale("")
    var summary:={"langs":langs,"sizes":sizes,"screens":screens_seen,"coverage_checks":coverage_checks,"switch_checks":switch_checks,"known":known,"findings":findings}
    if report_path!="":
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(report_path.get_base_dir()))
        var f:=FileAccess.open(report_path,FileAccess.WRITE);f.store_string(JSON.stringify(summary,"  "));f.close()
    for item in findings:print("FINDING ",JSON.stringify(item))
    print("LOCALIZATION_PROGRESSION_PROBE checks=%d screens=%d coverage=%d switch=%d findings=%d known=%s" % [screens_seen+coverage_checks+switch_checks,screens_seen,coverage_checks,switch_checks,findings.size(),JSON.stringify(known)])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit(1 if not findings.is_empty() else 0)

# ---------------------------------------------------------------- coverage
## Every text the player can see right now, scene text auto-translated.
func screen_text() -> String:
    var out:=""
    for c in visible_controls(game):
        for t in texts_of(c):out+=t+"\n"
    return out

## The part of a translation that is fixed text: the longest run between placeholders.
func literal(key: String) -> String:
    var best:=""
    for part in RegEx.create_from_string("%(?:[-+0#]*\\d*(?:\\.\\d+)?[sdif]|%)").sub(tr(key),"\u0001",true).split("\u0001"):
        if part.strip_edges().length()>best.length():best=part.strip_edges()
    return best

func expect(screen: String) -> void:
    var text:=screen_text()
    for key in EXPECT.get(screen,[]):
        coverage_checks+=1
        var want:=literal(key)
        # A key awaiting translation (tools/localization_pending.json) may show its English fallback in a
        # locale its batch has not delivered yet (Change 61: OFFLINE_ITEMS_HINT), as the validator allows.
        if current_lang!="en" and tr(key)==english.get(key,"") and not awaiting_translation(key):add(screen,"untranslated",key)
        elif want=="" or not text.contains(want):
            add(screen,"not_shown","%s: '%s'" % [key,want.left(50)])

var _pending: Dictionary={}
func awaiting_translation(key: String) -> bool:
    if _pending.is_empty():
        _pending=JSON.parse_string(FileAccess.get_file_as_string("res://tools/localization_pending.json")).get("keys",{})
    return _pending.has(key) and not _pending[key].get("translated",[]).has(current_lang)

## The sweep's checks, plus: a wrapping label narrower than one of its own words breaks inside that word
## ("Bonificació|n" on a boss-enhanced weapon before Change 58).
func inspect(screen: String) -> void:
    await super.inspect(screen)
    for c in visible_controls(game):
        if not (c is Label) or c.autowrap_mode==TextServer.AUTOWRAP_OFF or c.size.x<=0:continue
        if game.get_node("Safe/Layout/Map/ViewportContainer").is_ancestor_of(c):continue
        var font: Font=c.get_theme_font("font");var fs: int=c.get_theme_font_size("font_size")
        for word in displayed(c).replace("\n"," ").split(" ",false):
            if font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>c.size.x+1:
                add(screen,"word_split","'%s' in '%s' w=%d" % [word,displayed(c).left(40),int(c.size.x)],c)

func shown(screen: String) -> void:
    await quiet_shot()
    await inspect(screen)
    expect(screen)

## The item panel and the Prestige confirmation plate stay inside the screen (Change 55 rule, every language).
func inside(screen: String,c: Control) -> void:
    var view: Rect2=get_viewport().get_visible_rect().grow(1)
    if not view.encloses(c.get_global_rect()):add(screen,"plate_off_screen","%s %s" % [c.name,str(c.get_global_rect())],c)

# ---------------------------------------------------------------- screens
func boss_weapon() -> void:
    sim._drop("wood_axe",{"group":sim.campaign.group_id("boss-snowman"),"x":10.0,"y":10.0})
    sim.collect(int(sim.state.pickups.back().uid))

func progression_screens() -> void:
    # World: the Map Detail hint (M1) on a map with found enemies.
    fresh();sim.campaign.discover_spot(0,2)
    game._open("world");await shown("world_map_hint")
    game._close()
    # Welcome back: the offline gear hint (O1) and its jump button.
    fresh();sim.add_item("wood_sword",1);sim.state.gems=200
    sim.state.offline_pending={"id":"l10n","seconds":3600.0,"longest":3600.0,"rewarded_hours":1.0,"coins":120.0,"gems":2.0,"items":{}}
    game._open("offline");await shown("offline_gear_hint")
    game._close();sim.state.offline_pending={}
    # Upgrades > Offline: the unlock's benefit line (O2).
    game.player_tab=4;game._open("upgrades");await shown("upgrades_offline")
    game.player_tab=0;game._close()
    # A boss-enhanced weapon: boss bonus, three Reroll slots; then the reroll confirmation.
    fresh();sim.state.gems=5000;boss_weapon()
    game.selected="wood_axe";game._open("item");await shown("item_boss_enhanced")
    inside("item_boss_enhanced",game.get_node("Sheet"))
    var reroll: Button=null
    for b in game.find_children("*","Button",true,false):
        if b.is_visible_in_tree() and str(b.text).contains(literal("REROLL_ATTRIBUTE")):reroll=b;break
    if reroll==null:add("item_boss_enhanced","not_shown","no Reroll button")
    else:
        reroll.pressed.emit();await shown("confirm_reroll")
        inside("confirm_reroll",game.get_node("Confirm"))
        game._cancel_confirm()
    game._close()
    # A plain weapon: the boss bonus hint.
    fresh();sim.add_item("wood_sword",1)
    game.selected="wood_sword";game._open("item");await shown("item_boss_hint")
    game._close()
    # A weapon at its merge cap: the evolution rule; reaching it raised the evolution-ready toast (E1).
    fresh();game.toast_queue.clear()
    # E1 shows once per profile; the record survives the probe's profile reset between languages.
    while sim.state.tutorial.seen.has("hint_evolve_ready_done"):sim.state.tutorial.seen.erase("hint_evolve_ready_done")
    sim.add_item("wood_sword",21);sim.merge("wood_sword",true)
    # The toast queue may still be timing out an earlier toast: wait until this one is on screen.
    var want:=literal("EVOLVE_READY_HINT")
    for i in range(600):
        if game.get_node("Toast").visible and screen_text().contains(want):break
        await get_tree().process_frame
    # Reaching ^20 also finds a Masterwork opportunity: its banner animates in over the toast; settle it first.
    game.banner.queue.clear();game.banner._finish();await frames(2)
    await inspect("toast_evolve_ready");expect("toast_evolve_ready")
    game.selected="wood_sword";game._open("item");await shown("item_evolution_rule")
    game._close()
    # An old-stat copy kept from before the weapon update.
    fresh();sim.add_item("iron_sword_legacy",1)
    game.selected="iron_sword_legacy";game._open("item");await shown("item_legacy")
    game._close()
    # Prestige: the panel with all 48 opportunities, the confirmation, then the eight-card Expedition choice.
    fresh()
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman")
    for op in sim.catalog.campaign.opportunities:sim.state.opportunities[op.id]={"ready":false,"baseline":{},"step":0,"count":0}
    sim.state.opportunities["hunter_o1"].ready=true
    sim.state.unlocked_stage=8
    await panel("prestige","prestige_48")
    game._open_prestige_confirm(["hunter_o1"]);await shown("prestige_confirm")
    inside("prestige_confirm",game.get_node("PrestigeConfirm/Plate"))
    game.get_node("PrestigeConfirm").close()
    game._close()
    fresh()
    if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman")
    sim.state.opportunities["expedition_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
    if not sim.campaign.begin_prestige() or sim.campaign.offered_cards().size()!=8:add("prestige_cards8","fixture","Expedition did not offer eight cards")
    game._open("prestige");await shown("prestige_cards8")
    var scroll: ScrollContainer=game.get_node("Sheet/Margin/Content/Scroll")
    var bar:=scroll.get_v_scroll_bar()
    if bar.max_value>scroll.size.y+4:
        scroll.scroll_vertical=int(bar.max_value);await frames(3);await inspect("prestige_cards8_end");scroll.scroll_vertical=0
    game._close()
    sim.campaign.cancel_prestige()

## Live switching with progression panels open (from the real selection path the dropdown uses): the panel's
## code-built text redraws in the new language.
func live_switch() -> void:
    var pairs:=[["es_419","de_DE"],["fr_FR","pt_BR"],["de_DE","es_ES"]]
    for pair in pairs:
        if not (pair[0] in langs and pair[1] in langs):continue
        LocalizationService.select_language(pair[0]);await frames(2)
        fresh()
        if not sim.state.bosses_found.has("boss-snowman"):sim.state.bosses_found.append("boss-snowman")
        sim.state.opportunities["expedition_o1"]={"ready":true,"baseline":{},"step":0,"count":0}
        sim.campaign.begin_prestige()
        game._open("prestige");await frames(4)
        var before:=tr("PRESTIGE_KEEP_ALL")
        LocalizationService.select_language(pair[1]);await frames(4)
        switch_checks+=1
        var text:=screen_text()
        if not text.contains(tr("PRESTIGE_KEEP_ALL")) or text.contains(before) or not text.contains(tr("CONTENT_EXPEDITION_C6_NAME")):
            add("live_switch","stale_after_switch","Prestige choice %s -> %s" % [pair[0],pair[1]])
        game._close();sim.campaign.cancel_prestige()
        fresh();sim.state.gems=5000;boss_weapon()
        game.selected="wood_axe";game._open("item");await frames(4)
        var before_item:=literal("ITEM_BOSS_BONUS_EXPLAIN")
        LocalizationService.select_language(pair[0]);await frames(4)
        switch_checks+=1
        text=screen_text()
        if not text.contains(literal("ITEM_BOSS_BONUS_EXPLAIN")) or text.contains(before_item) or not text.contains(literal("REROLL_ATTRIBUTE")):
            add("live_switch","stale_after_switch","boss weapon item %s -> %s" % [pair[1],pair[0]])
        game._close()
