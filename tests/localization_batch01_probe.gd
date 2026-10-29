extends Node
## Localization Batch 01 (Change 38): es_419, es_ES, pt_BR, fr_FR and de_DE are complete but test-only.
## 1. Production gate: Settings lists Automatic, English and the 19 other release languages, 19 of them
##    disabled; nothing but English can be selected or restored; Automatic is English (Playbook 132.2).
## 2. Test override: the batch registers through Godot's own PO loader; each locale routes to its own
##    catalog (Latin America and Spain stay apart); every key resolves to the catalog text; every glyph
##    exists in the theme font.
## 3. Live switching from the real Settings button and with other panels open: panels, HUD, catalog names,
##    the guide's fixed texts and the View Camp button redraw; no English is left behind.
## 4. Persistence: the choice survives save and reload; older settings and saves load as Automatic
##    (English) without touching progression.
var checks:=0
var failures:=0
var game
var sim
const BATCH:=["es_419","es_ES","pt_BR","fr_FR","de_DE"]
const LOCALES:={"en_US":"en","es_419":"es","es_ES":"es_ES","pt_BR":"pt_BR","fr_FR":"fr_FR","de_DE":"de_DE"}
var catalogs: Dictionary={}
var english: Dictionary={}

func check(value: bool,message: String) -> void:
    checks+=1
    if not value:
        failures+=1
        push_error(message)
    else:print("ok  ",message)
func _ready() -> void:call_deferred("run")
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame

func run() -> void:
    SettingsState.mute_all_sfx()
    english=preload("res://tests/localization_sweep.gd").read_po("res://localization/en.po")
    for lang in BATCH:catalogs[lang]=preload("res://tests/localization_sweep.gd").read_po("res://localization/%s.po" % lang)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.set_physics_process(false)
    await frames(10)
    await production_gate()
    await routing_and_coverage()
    await live_switching()
    await persistence()
    LocalizationService.select_language("automatic")
    print("LOCALIZATION_BATCH01_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

func language_buttons() -> Array:
    var out: Array=[]
    for b in game.rows.find_children("*","Button",true,false):
        if b.has_meta("language"):out.append(b)
    return out

# ---------------------------------------------------------------- 1. production gate
func production_gate() -> void:
    check(LocalizationService.available_languages()==(["en_US"] as Array[String]),"Before the test override only English is available")
    check(TranslationServer.get_locale()=="en" and LocalizationService.godot_locale("automatic")=="en","Automatic resolves to English")
    check(not TranslationServer.get_loaded_locales().has("de_DE") and not TranslationServer.get_loaded_locales().has("es"),"No batch catalog is loaded without the override")
    var registered: PackedStringArray=ProjectSettings.get_setting("internationalization/locale/translations")
    check(registered==PackedStringArray(["res://localization/en.po"]),"project.godot ships only en.po until the global gate")
    check(not LocalizationService.TRANSLATIONS_RELEASE_READY,"The 20-language release gate is still closed")
    for lang in BATCH+["it_IT","ja_JP","zh_TW"]:
        check(not LocalizationService.select_language(lang) and SettingsState.selected_language=="automatic","%s cannot be selected by a player" % lang)
    game._open("settings");await frames(4)
    var buttons:=language_buttons()
    var disabled:=buttons.filter(func(b):return b.disabled)
    check(buttons.size()==21 and disabled.size()==19,"Settings lists Automatic, English and the 19 other languages, 19 disabled (%d/%d)" % [buttons.size(),disabled.size()])
    check(buttons.filter(func(b):return not b.disabled).map(func(b):return b.get_meta("language"))==["automatic","en_US"],"Only Automatic and English are enabled")
    check(buttons.any(func(b):return b.get_meta("language")=="automatic" and b.theme_type_variation==&"Primary"),"The current choice (Automatic) is highlighted")
    var notice:=false
    for l in game.rows.find_children("*","Label",true,false):
        if l.text==tr("LANG_DISABLED") or l.text==tr("LANGUAGE_NOTE"):notice=true
    check(not notice,"No development notice accompanies the disabled languages (Change 16)")
    # A forged or test-era save asking for German loads as Automatic in a normal build.
    SettingsState.from_save_dict({"selected_language":"de_DE"})
    check(SettingsState.selected_language=="automatic" and TranslationServer.get_locale()=="en","A saved non-English choice falls back to Automatic (English) while the gate is closed")
    var was_probe: bool=BootContext.is_probe
    BootContext.is_probe=false
    check(not LocalizationService.enable_test_batch("batch01") and not LocalizationService.set_test_locale("de_DE"),"The test override is refused outside probes and captures")
    BootContext.is_probe=was_probe
    check(LocalizationService.available_languages()==(["en_US"] as Array[String]),"…and nothing was registered by the refused call")
    game._close()

# ---------------------------------------------------------------- 2. routing, coverage, glyphs
func routing_and_coverage() -> void:
    check(LocalizationService.enable_test_batch("batch01"),"The test override registers Batch 01")
    check(LocalizationService.available_languages()==(["en_US","es_419","es_ES","pt_BR","fr_FR","de_DE"] as Array[String]),"Batch 01 becomes selectable in a probe")
    var font: Font=game.get_theme_default_font()
    for lang in BATCH:
        check(LocalizationService.select_language(lang),"%s selectable" % lang)
        await frames(1)
        check(TranslationServer.get_locale()==LOCALES[lang],"%s routes to Godot locale %s (got %s)" % [lang,LOCALES[lang],TranslationServer.get_locale()])
        var wrong: Array=[]
        for key in english:
            var value: String=catalogs[lang][key].c_unescape() if "\\" in catalogs[lang][key] else catalogs[lang][key]
            if tr(key)!=value:wrong.append(key)
        check(wrong.is_empty(),"%s: Godot's PO loader returns the catalog text for all %d keys (%d wrong: %s)" % [lang,english.size(),wrong.size(),str(wrong.slice(0,3))])
        var chars: Dictionary={}
        for key in catalogs[lang]:
            for c in catalogs[lang][key]:
                if c.unicode_at(0)>=32:chars[c]=true
        var missing: Array=[]
        for c in chars:
            if not font.has_char(c.unicode_at(0)):missing.append(c)
        check(missing.is_empty(),"%s: the theme font has all %d glyphs the catalog uses (missing %s)" % [lang,chars.size(),str(missing)])
    LocalizationService.select_language("es_419");await frames(1)
    var latam:=tr("SETTINGS")
    LocalizationService.select_language("es_ES");await frames(1)
    check(latam=="Configuración" and tr("SETTINGS")=="Ajustes" and tr("CONTENT_GROUPS_UNIT-SUNGLASSES")=="Gafas de Sol","Latin America and Spain read their own catalogs (Configuración / Ajustes, Lentes / Gafas de Sol)")
    # Device locales Godot would match once Automatic is enabled (informational: Automatic stays English now).
    for pair in [["es_MX","Configuración"],["es_AR","Configuración"],["fr_CA",catalogs.fr_FR.SETTINGS],["de_AT",catalogs.de_DE.SETTINGS]]:
        LocalizationService.set_test_locale(pair[0]);await frames(1)
        check(tr("SETTINGS")==pair[1],"Device locale %s would read %s" % pair)
    LocalizationService.set_test_locale("")
    LocalizationService.select_language("automatic");await frames(1)
    check(TranslationServer.get_locale()=="en","Automatic is still English with the batch registered")

# ---------------------------------------------------------------- 3. live switching
func visible_texts(root: Node) -> Array:
    var out: Array=[]
    for c in root.find_children("*","Control",true,false):
        if c.is_visible_in_tree() and (c is Label or c is Button):
            var t: String=c.atr(str(c.text)) if c.can_auto_translate() else str(c.text)
            if t.strip_edges()!="":out.append(t)
    return out

func english_left(lang: String) -> Array:
    var english_values: Dictionary={}
    for key in english:
        var v: String=english[key]
        if v.split(" ").size()>=2 and not "%" in v and catalogs[lang][key]!=v:english_values[v]=key
    var left: Array=[]
    for t in visible_texts(game):
        for line in t.split("\n"):
            if english_values.has(line.strip_edges()):left.append(line.strip_edges())
    return left

func live_switching() -> void:
    sim.new_profile();sim.state.tutorial.mode="none";sim.campaign.onboarding.reveal_all(true);sim.state.tutorial.seen.append("road_ahead")
    sim.state.unlocked_stage=3;sim.state.coins=50000.0
    for id in ["wood_sword","potion"]:sim.add_item(id,3,true,false)
    sim.campaign.discover_spot(0,2);sim.touch();await frames(8)
    # The player's path: Settings, then the German button.
    game._open("settings");await frames(4)
    var german: Button
    for b in language_buttons():
        if b.get_meta("language")=="de_DE":german=b
    check(german!=null and not german.disabled,"With the batch registered the German button is enabled")
    german.pressed.emit();await frames(6)
    check(SettingsState.selected_language=="de_DE" and TranslationServer.get_locale()=="de_DE","Tapping Deutsch switches at once (no restart)")
    check(game.get_node("Sheet/Margin/Content/Header/Title").text==catalogs.de_DE.PANEL_SETTINGS,"The open Settings panel redraws its title in German")
    var highlighted: Array=language_buttons().filter(func(b):return b.theme_type_variation==&"Primary").map(func(b):return b.get_meta("language"))
    check(highlighted==["de_DE"],"…and highlights Deutsch as the current choice")
    await get_tree().create_timer(.3).timeout
    var nav: Button=game.get_node("Safe/Layout/Dock/Content/Navigation/World")
    check(nav.atr(nav.text)==catalogs.de_DE.WORLD,"Scene-authored navigation reads German")
    check(game.get_node("Safe/Layout/Top/Content/Meters/XP/Text").text.begins_with("STUFE"),"The HUD level line redraws in German")
    check(game.get_node("Safe/Layout/Map/ViewCamp").text==catalogs.de_DE.VIEW_CAMP,"The View Camp button redraws in German")
    check(game.guide.skip_button.text==catalogs.de_DE.GUIDE_SKIP and game.guide.intro_button.text==catalogs.de_DE.GUIDE_GOT_IT,"The guide's fixed buttons redraw in German")
    check(sim.catalog.groups[0].name==catalogs.de_DE["CONTENT_GROUPS_UNIT-BLUE-CAP"] and sim.catalog.stages[2].name==catalogs.de_DE.CONTENT_STAGES_3,"Catalog enemy and stage names are re-translated (%s, %s)" % [sim.catalog.groups[0].name,sim.catalog.stages[2].name])
    check(english_left("de_DE").is_empty(),"Nothing on screen is still English after the switch: %s" % str(english_left("de_DE")))
    # Switching with other panels open (the reconciler rewrites their rows in place).
    var order:=["fr_FR","pt_BR","es_ES","es_419","de_DE"]
    var panels:=["upgrades","prestige","missions","world","mastery","item"]
    for i in range(panels.size()):
        var lang: String=order[i%order.size()]
        if panels[i]=="item":game._select_slot(0,0)
        else:game._open(panels[i])
        await frames(4)
        LocalizationService.select_language(lang);await frames(6)
        await get_tree().create_timer(.2).timeout
        var title: String=game.get_node("Sheet/Margin/Content/Header/Title").text
        var left:=english_left(lang)
        check(left.is_empty() and title!="" and TranslationServer.get_locale()==LOCALES[lang],"%s open, switched to %s: redrawn (title %s), no English left %s" % [panels[i],lang,title,str(left)])
    game._close()
    # A retained panel reopened after a switch shows the new language, not its old rows.
    game._open("upgrades");await frames(3);game._close();await frames(2)
    LocalizationService.select_language("pt_BR");await frames(3)
    game._open("upgrades");await frames(4)
    check(game.get_node("Sheet/Margin/Content/Header/Title").text==catalogs.pt_BR.PANEL_UPGRADES and english_left("pt_BR").is_empty(),"A panel reopened after a switch is rebuilt in the new language")
    game._close()
    LocalizationService.select_language("en_US");await frames(6)
    await get_tree().create_timer(.3).timeout
    check(TranslationServer.get_locale()=="en" and sim.catalog.groups[0].name==english["CONTENT_GROUPS_UNIT-BLUE-CAP"] and game.get_node("Safe/Layout/Map/ViewCamp").text==english.VIEW_CAMP,"Switching back to English restores English names and labels")

# ---------------------------------------------------------------- 4. persistence and compatibility
func persistence() -> void:
    sim.state.coins=777.0;sim.state.player_level=42;sim.touch()
    LocalizationService.select_language("fr_FR");await frames(2)
    check(SaveService.save_now(),"A save with French selected is written")
    var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SaveService.save_path()))
    check(str(saved.settings.selected_language)=="fr_FR","The preference is stored in settings, apart from progression")
    LocalizationService.select_language("de_DE");await frames(2)
    SaveService.load_and_apply();await frames(3)
    check(SettingsState.selected_language=="fr_FR" and TranslationServer.get_locale()=="fr_FR","Reloading restores French (restart persistence)")
    check(int(sim.state.player_level)==42 and is_equal_approx(float(sim.state.coins),777.0),"Progression is unchanged by language changes and reloads")
    # Settings written before Batch 01 (no language key, English, Automatic) and unknown values.
    for data in [{},{"selected_language":"en_US"},{"selected_language":"automatic"},{"selected_language":"xx_YY"},{"selected_language":7}]:
        SettingsState.from_save_dict(data);await frames(1)
        var expected: String="en_US" if str(data.get("selected_language",""))=="en_US" else "automatic"
        check(SettingsState.selected_language==expected and TranslationServer.get_locale()=="en","Old/foreign settings %s load as %s (English)" % [str(data),expected])
    # A restart without the test override (a player build) keeps English even if the save says French.
    LocalizationService.select_language("fr_FR");await frames(1)
    SaveService.save_now()
    LocalizationService._test_languages.clear()
    SaveService.load_and_apply();await frames(3)
    check(SettingsState.selected_language=="automatic" and TranslationServer.get_locale()=="en","Without the override the same save opens in English (gate closed)")
    check(int(sim.state.player_level)==42,"…and its progression loads intact")
    LocalizationService.enable_test_batch("batch01")
