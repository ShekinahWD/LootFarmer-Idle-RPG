extends "res://tests/localization_batch01_probe.gd"
## Localization Batch 02 (Change 39): it_IT, nl_NL, pl_PL, ru_RU and uk_UA. Enabled for players in Change 40.
## Reuses the Batch 01 probe's helpers (check, frames, dropdown, choose, english_left).
## 1. Availability: the five are selectable without any test switch and load on first use; the nine drafts and an
##    unvalidated batch name are refused; a stored Russian choice is restored.
## 2. Routing: each locale routes to its own catalog through Godot's PO loader; every key resolves; every glyph
##    (Cyrillic incl. Ukrainian і ї є ґ, Polish diacritics, typographic quotes) exists in the theme font; Russian
##    and Ukrainian are separate catalogs; Automatic keeps Russian and Ukrainian devices apart.
## 3. Dynamic text: every placeholder string formats with sample values in each language, durations use the
##    locale's units, Polish/Russian/Ukrainian count lines stay count-neutral.
## 4. Live switching from the Settings dropdown and with panels open; persistence and old-save compatibility.
const BATCH2:=["it_IT","nl_NL","pl_PL","ru_RU","uk_UA"]
const LOCALES2:={"en_US":"en","it_IT":"it_IT","nl_NL":"nl_NL","pl_PL":"pl_PL","ru_RU":"ru_RU","uk_UA":"uk_UA"}
const SCRIPT_LETTERS:={
    "ru_RU":"АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя«»—",
    "uk_UA":"АБВГҐДЕЄЖЗИІЇЙКЛМНОПРСТУФХЦЧШЩЬЮЯабвгґдеєжзиіїйклмнопрстуфхцчшщьюя’«»—",
    "pl_PL":"ĄĆĘŁŃÓŚŹŻąćęłńóśźż„”—",
    "it_IT":"ÀÈÉÌÒÙàèéìòù’",
    "nl_NL":"ËÏëïéIJ",
}

func run() -> void:
    startup_locale=TranslationServer.get_locale()
    SettingsState.mute_all_sfx()
    english=preload("res://tests/localization_sweep.gd").read_po("res://localization/en.po")
    for lang in BATCH2:catalogs[lang]=preload("res://tests/localization_sweep.gd").read_po("res://localization/%s.po" % lang)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.set_physics_process(false)
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    await frames(10)
    await gate_batch02()
    await routing_batch02()
    await dynamic_text()
    await live_switching_batch02()
    await persistence_batch02()
    LocalizationService.select_language("automatic")
    LocalizationService.set_test_device_locale("")
    print("LOCALIZATION_BATCH02_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- 1. availability
func gate_batch02() -> void:
    check(LocalizationService.available_languages()==(ENABLED as Array[String]),"Batch 02 is available without any test switch")
    var loaded: PackedStringArray=TranslationServer.get_loaded_locales()
    check(BATCH2.all(func(l):return not loaded.has(LOCALES2[l]) or LOCALES2[l]==startup_locale),"No Batch 02 catalog is loaded before it is used, except the one the profile restored (%s; restored %s)" % [str(loaded),startup_locale])
    check(LocalizationService.godot_locale("automatic")=="en","Automatic on an English device is English")
    for lang in DRAFTS:
        check(not LocalizationService.select_language(lang) and SettingsState.selected_language=="automatic","%s (draft) cannot be selected by a player" % lang)
    SettingsState.from_save_dict({"selected_language":"ru_RU"});await frames(1)
    check(SettingsState.selected_language=="ru_RU" and TranslationServer.get_locale()=="ru_RU","A saved Russian choice is restored")
    LocalizationService.select_language("automatic");await frames(1)
    var was_probe: bool=BootContext.is_probe
    BootContext.is_probe=false
    check(not LocalizationService.enable_test_batch("batch02") and not LocalizationService.set_test_locale("uk_UA"),"The test switches are refused outside probes and captures")
    BootContext.is_probe=was_probe
    check(not LocalizationService.enable_test_batch("batch03"),"An unvalidated batch name is refused")
    check(LocalizationService.available_languages()==(ENABLED as Array[String]),"…and nothing was added by the refused calls")
    game._open("settings");await frames(4)
    var choices:=dropdown_choices()
    check(choices.size()==12 and DRAFTS.all(func(l):return not l in choices),"The dropdown lists 12 choices and none of the nine drafts")
    game._close()

# ---------------------------------------------------------------- 2. routing, coverage, glyphs
func routing_batch02() -> void:
    check(LocalizationService.enable_test_batch("batch02") and LocalizationService.available_languages()==(ENABLED as Array[String]),"The batch02 test switch still answers and adds nothing (the batch is enabled)")
    var font: Font=game.get_theme_default_font()
    for lang in BATCH2:
        check(LocalizationService.GODOT_LOCALES.get(lang,"")==LOCALES2[lang],"%s maps to Godot locale %s" % [lang,LOCALES2[lang]])
        check(LocalizationService.select_language(lang),"%s selectable" % lang)
        await frames(1)
        check(TranslationServer.get_locale()==LOCALES2[lang],"%s routes to Godot locale %s (got %s)" % [lang,LOCALES2[lang],TranslationServer.get_locale()])
        var wrong: Array=[]
        for key in english:
            if tr(key)!=catalogs[lang][key]:wrong.append(key)
        check(wrong.is_empty() and catalogs[lang].size()==english.size(),"%s: Godot's PO loader returns the catalog text for all %d keys (%d wrong: %s)" % [lang,english.size(),wrong.size(),str(wrong.slice(0,3))])
        var chars: Dictionary={}
        for key in catalogs[lang]:
            for c in catalogs[lang][key]:
                if c.unicode_at(0)>=32:chars[c]=true
        for c in SCRIPT_LETTERS[lang]:chars[c]=true
        var missing: Array=[]
        for c in chars:
            if not font.has_char(c.unicode_at(0)):missing.append(c)
        check(missing.is_empty(),"%s: the theme font has all %d glyphs (catalog plus the script's letters; missing %s)" % [lang,chars.size(),str(missing)])
    # Russian and Ukrainian are independent catalogs (shared lines are numbers, abbreviations and true cognates).
    var same:=0;var worded:=0
    for key in english:
        if RegEx.create_from_string("[\\p{L}]{4,}").search(catalogs.ru_RU[key])==null:continue
        worded+=1
        if catalogs.ru_RU[key]==catalogs.uk_UA[key]:same+=1
    check(same*20<worded,"Russian and Ukrainian are written separately (%d of %d worded lines identical)" % [same,worded])
    for pair in [["ru_RU","SETTINGS","Настройки"],["uk_UA","SETTINGS","Налаштування"],["uk_UA","PANEL_MAP","Мапа"],["pl_PL","SETTINGS","Ustawienia"]]:
        LocalizationService.select_language(pair[0]);await frames(1)
        check(tr(pair[1])==pair[2],"%s reads %s as %s" % pair)
    # Automatic (Change 40): Russian and Ukrainian devices keep their own language wherever they are; a
    # language without a catalog (Belarusian, Kazakh) is English, never a neighbouring language.
    LocalizationService.select_language("automatic")
    for pair in [["ru","ru_RU"],["ru_RU","ru_RU"],["ru_UA","ru_RU"],["ru_KZ","ru_RU"],["uk","uk_UA"],["uk_UA","uk_UA"],["pl_PL","pl_PL"],["it_CH","it_IT"],["nl_BE","nl_NL"],["ru_RU.UTF-8","ru_RU"],["be_BY","en_US"],["kk_KZ","en_US"]]:
        LocalizationService.set_test_device_locale(pair[0]);await frames(1)
        var expected: String=catalogs[pair[1]].SETTINGS if pair[1]!="en_US" else english.SETTINGS
        check(LocalizationService.resolved_language("automatic")==pair[1] and tr("SETTINGS")==expected,"Automatic on a %s device reads %s (%s)" % [pair[0],pair[1],tr("SETTINGS")])
    LocalizationService.set_test_device_locale("en_US");await frames(1)
    LocalizationService.select_language("de_DE");await frames(1)
    var german:=tr("SETTINGS")
    LocalizationService.select_language("nl_NL");await frames(1)
    check(german!=tr("SETTINGS") and tr("SETTINGS")==catalogs.nl_NL.SETTINGS,"Batch 01 and 02 catalogs do not shadow each other (de %s, nl %s)" % [german,tr("SETTINGS")])
    LocalizationService.select_language("automatic");await frames(1)
    check(TranslationServer.get_locale()=="en","Automatic on an English device is English with every catalog loaded")

# ---------------------------------------------------------------- 3. dynamic text
func sample_args(text: String) -> Array:
    var args: Array=[]
    var re:=RegEx.create_from_string("%(?:[-+0#]*\\d*(?:\\.\\d+)?[sdif]|%)")
    for m in re.search_all(text):
        var p:=m.get_string()
        if p=="%%":continue
        if p.ends_with("s"):args.append("7")
        elif p.ends_with("f"):args.append(2.5)
        else:args.append(3)
    return args

func dynamic_text() -> void:
    for lang in BATCH2:
        LocalizationService.select_language(lang);await frames(1)
        var bad: Array=[]
        for key in english:
            var text: String=tr(key)
            var args:=sample_args(text)
            if args.is_empty():continue
            var out: String=text % args
            if out.strip_edges()=="" or RegEx.create_from_string("%[sdif]").search(out)!=null:bad.append(key)
        check(bad.is_empty(),"%s: every placeholder string formats with sample values (%s)" % [lang,str(bad.slice(0,3))])
        var d: String=game.fmt_duration(3725)
        check(d==tr("DURATION_HOURS_MINUTES") % [1,2] and d!="1h 02m","%s: durations use the locale's units (%s, %s, %s)" % [lang,d,game.fmt_duration(249),game.fmt_duration(37)])
    # Count lines read correctly for 1, 2, 5, 21 and 22 because the number sits after a label.
    LocalizationService.select_language("ru_RU");await frames(1)
    for n in [1,2,5,21,22]:
        var line: String=tr("MERGE_ALL_DONE") % [n,n]
        check(line.begins_with("Объединено копий: %d" % n),"ru count line for %d: %s" % [n,line])
    LocalizationService.select_language("pl_PL");await frames(1)
    check((tr("CAMPS_HIDDEN") % 2).contains(": jeszcze 2"),"pl hidden-camp line keeps the count after its label: %s" % (tr("CAMPS_HIDDEN") % 2))
    LocalizationService.select_language("uk_UA");await frames(1)
    check((tr("MILESTONE_PRESTIGED_DETAIL") % 3).ends_with(": 3."),"uk prestige card count follows its label: %s" % (tr("MILESTONE_PRESTIGED_DETAIL") % 3))
    LocalizationService.select_language("automatic");await frames(1)

# ---------------------------------------------------------------- 4. live switching and persistence
func live_switching_batch02() -> void:
    sim.new_profile();sim.state.tutorial.mode="none";sim.campaign.onboarding.reveal_all(true);sim.state.tutorial.seen.append("road_ahead")
    sim.state.unlocked_stage=3;sim.state.coins=50000.0
    for id in ["wood_sword","potion"]:sim.add_item(id,3,true,false)
    sim.campaign.discover_spot(0,2);sim.touch();await frames(8)
    game._open("settings");await frames(4)
    check(await choose("ru_RU"),"The dropdown offers Русский")
    await frames(4)
    check(SettingsState.selected_language=="ru_RU" and TranslationServer.get_locale()=="ru_RU","Choosing Русский switches at once (no restart)")
    check(game.get_node("Sheet/Margin/Content/Header/Title").text==catalogs.ru_RU.PANEL_SETTINGS,"The open Settings panel redraws its title in Russian")
    check(dropdown().text=="Русский" and dropdown().get_item_text(0)==catalogs.ru_RU.LANG_AUTOMATIC+" (English)","…the closed dropdown shows Русский; Automatic reads %s" % dropdown().get_item_text(0))
    await get_tree().create_timer(.3).timeout
    var nav: Button=game.get_node("Safe/Layout/Dock/Content/Navigation/World")
    check(nav.atr(nav.text)==catalogs.ru_RU.WORLD,"Scene-authored navigation reads Russian")
    check(game.get_node("Safe/Layout/Top/Content/Meters/XP/Text").text.begins_with("УРОВЕНЬ"),"The HUD level line redraws in Russian")
    check(game.get_node("Safe/Layout/Map/ViewCamp").text==catalogs.ru_RU.VIEW_CAMP,"The View Camp button redraws in Russian")
    check(game.guide.skip_button.text==catalogs.ru_RU.GUIDE_SKIP and game.guide.intro_button.text==catalogs.ru_RU.GUIDE_GOT_IT,"The guide's fixed buttons redraw in Russian")
    check(sim.catalog.groups[0].name==catalogs.ru_RU["CONTENT_GROUPS_UNIT-BLUE-CAP"] and sim.catalog.stages[2].name==catalogs.ru_RU.CONTENT_STAGES_3,"Catalog enemy and stage names are re-translated (%s, %s)" % [sim.catalog.groups[0].name,sim.catalog.stages[2].name])
    check(english_left("ru_RU").is_empty(),"Nothing on screen is still English after the switch: %s" % str(english_left("ru_RU")))
    var order:=["uk_UA","pl_PL","it_IT","nl_NL","ru_RU","uk_UA"]
    var panels:=["upgrades","prestige","missions","world","mastery","item"]
    for i in range(panels.size()):
        var lang: String=order[i]
        if panels[i]=="item":game._select_slot(0,0)
        else:game._open(panels[i])
        await frames(4)
        LocalizationService.select_language(lang);await frames(6)
        await get_tree().create_timer(.2).timeout
        var title: String=game.get_node("Sheet/Margin/Content/Header/Title").text
        var left:=english_left(lang)
        check(left.is_empty() and title!="" and TranslationServer.get_locale()==LOCALES2[lang],"%s open, switched to %s: redrawn (title %s), no English left %s" % [panels[i],lang,title,str(left)])
    game._close()
    game._open("upgrades");await frames(3);game._close();await frames(2)
    LocalizationService.select_language("pl_PL");await frames(3)
    game._open("upgrades");await frames(4)
    check(game.get_node("Sheet/Margin/Content/Header/Title").text==catalogs.pl_PL.PANEL_UPGRADES and english_left("pl_PL").is_empty(),"A panel reopened after a switch is rebuilt in Polish")
    game._close()
    LocalizationService.select_language("en_US");await frames(6)
    await get_tree().create_timer(.3).timeout
    check(TranslationServer.get_locale()=="en" and sim.catalog.groups[0].name==english["CONTENT_GROUPS_UNIT-BLUE-CAP"] and game.get_node("Safe/Layout/Map/ViewCamp").text==english.VIEW_CAMP,"Switching back to English restores English names and labels")

func persistence_batch02() -> void:
    sim.state.coins=555.0;sim.state.player_level=37;sim.touch()
    LocalizationService.select_language("uk_UA");await frames(2)
    check(SaveService.save_now(),"A save with Ukrainian selected is written")
    var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SaveService.save_path()))
    check(str(saved.settings.selected_language)=="uk_UA","The preference is stored in settings, apart from progression")
    LocalizationService.select_language("ru_RU");await frames(2)
    SaveService.load_and_apply();await frames(3)
    check(SettingsState.selected_language=="uk_UA" and TranslationServer.get_locale()=="uk_UA","Reloading restores Ukrainian, not Russian")
    check(int(sim.state.player_level)==37 and is_equal_approx(float(sim.state.coins),555.0),"Progression is unchanged by language changes and reloads")
    for data in [{},{"selected_language":"en_US"},{"selected_language":"it"},{"selected_language":"ru"}]:
        SettingsState.from_save_dict(data);await frames(1)
        var expected: String="en_US" if str(data.get("selected_language",""))=="en_US" else "automatic"
        check(SettingsState.selected_language==expected and TranslationServer.get_locale()=="en","Old/foreign settings %s load as %s (English)" % [str(data),expected])
    LocalizationService.select_language("pl_PL");await frames(1)
    SaveService.save_now()
    LocalizationService._test_languages.clear()
    SaveService.load_and_apply();await frames(3)
    check(SettingsState.selected_language=="pl_PL" and TranslationServer.get_locale()=="pl_PL","Without any test switch the same save opens in Polish")
    check(int(sim.state.player_level)==37,"…and its progression loads intact")
