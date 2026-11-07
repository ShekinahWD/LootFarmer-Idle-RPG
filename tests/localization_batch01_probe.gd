extends Node
## Localization Batch 01 (Change 38): es_419, es_ES, pt_BR, fr_FR and de_DE. Enabled for players in Change 40.
## 1. Availability (Playbook 132.5 progressive activation): the Settings dropdown offers Automatic, English and
##    the fifteen enabled languages (Batch 03 since Change 42), nothing else; the Batch 04 draft languages are absent and refused; a stored draft
##    choice shows English and stays stored; the probe-only switches are refused outside probes.
## 2. Routing: each locale reads its own catalog through Godot's own PO loader, loaded on first use (Latin America
##    and Spain stay apart); every key resolves to the catalog text; every glyph exists in the theme font;
##    Automatic picks the closest enabled language for Spanish, Portuguese, French and German device locales.
## 3. Live switching from the real dropdown and with other panels open: panels, HUD, catalog names, the guide's
##    fixed texts and the View Camp button redraw; no English is left behind.
## 4. Persistence: the choice survives save and reload (also after a restart without any test switch); older
##    settings load as Automatic without touching progression.
var checks:=0
var failures:=0
var game
var sim
const BATCH:=["es_419","es_ES","pt_BR","fr_FR","de_DE"]
const LOCALES:={"en_US":"en","es_419":"es","es_ES":"es_ES","pt_BR":"pt_BR","fr_FR":"fr_FR","de_DE":"de_DE"}
var catalogs: Dictionary={}
var english: Dictionary={}
## The locale the probe profile's stored preference applied at startup (an earlier run may have chosen one).
var startup_locale:=""

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
    startup_locale=TranslationServer.get_locale()
    SettingsState.mute_all_sfx()
    english=preload("res://tests/localization_sweep.gd").translated_english() # Change 50: pending keys excluded
    for lang in BATCH:catalogs[lang]=preload("res://tests/localization_sweep.gd").read_po("res://localization/%s.po" % lang)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.set_physics_process(false)
    # The developer laptop's own language must not decide what Automatic shows.
    LocalizationService.set_test_device_locale("en_US")
    # The probe profile may hold a language an earlier run chose; every run starts from Automatic.
    LocalizationService.select_language("automatic")
    await frames(10)
    await availability()
    await routing_and_coverage()
    await live_switching()
    await persistence()
    LocalizationService.select_language("automatic")
    LocalizationService.set_test_device_locale("")
    print("LOCALIZATION_BATCH01_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

## The Settings language dropdown (Change 40) and the choice id behind each of its items.
func dropdown() -> OptionButton:
    for b in game.rows.find_children("*","OptionButton",true,false):
        if b.get_script()==game.LANGUAGE_DROPDOWN:return b
    return null

func dropdown_choices() -> Array:
    var d:=dropdown()
    if d==null:return []
    return range(d.item_count).map(func(i):return d.get_item_metadata(i))

## The player's path: open the menu, tap the item.
func choose(lang: String) -> bool:
    var d:=dropdown()
    if d==null:return false
    var index:=dropdown_choices().find(lang)
    if index<0:return false
    d.show_popup();await frames(2)
    d.get_popup().set_focused_item(index)
    var accept:=InputEventAction.new();accept.action=&"ui_accept";accept.pressed=true
    get_tree().root.push_input(accept);await frames(2)
    return true

## The Batch 04 drafts were the last unvalidated languages; Change 43 enabled them, so no draft remains.
const DRAFTS:=[]
const ENABLED:=["en_US","es_419","es_ES","pt_BR","fr_FR","de_DE","it_IT","nl_NL","pl_PL","ru_RU","uk_UA","tr_TR","id_ID","vi_VN","th_TH","hi_IN","ja_JP","ko_KR","zh_CN","zh_TW"]

# ---------------------------------------------------------------- 1. availability
func availability() -> void:
    check(LocalizationService.available_languages()==(ENABLED as Array[String]),"English and Batches 01-04 (all 20 target languages) are available, in release order (%s)" % str(LocalizationService.available_languages()))
    check(LocalizationService.ENABLED_LANGUAGES==(ENABLED as Array[String]) and not LocalizationService.ALL_LANGUAGES_CERTIFIED,"One readiness list enables all twenty; the 20-language certification is still separate and open")
    check(TranslationServer.get_locale()=="en" and LocalizationService.godot_locale("automatic")=="en","Automatic on an English device resolves to English")
    var early: Array=Array(TranslationServer.get_loaded_locales()).filter(func(l):return l!="en" and l!=startup_locale)
    check(early.is_empty(),"A catalog loads on first use, not at startup (loaded %s; the profile restored %s)" % [str(TranslationServer.get_loaded_locales()),startup_locale])
    var registered: PackedStringArray=ProjectSettings.get_setting("internationalization/locale/translations")
    check(registered==PackedStringArray(["res://localization/en.po"]),"project.godot registers only en.po (the enabled catalogs load through LocalizationService)")
    for lang in DRAFTS:
        check(not LocalizationService.select_language(lang) and SettingsState.selected_language=="automatic","%s (draft) cannot be selected by a player" % lang)
    game._open("settings");await frames(4)
    check(game.rows.find_children("*","Button",true,false).filter(func(b):return b.has_meta("language")).is_empty(),"The language button grid is gone")
    var d:=dropdown()
    check(d!=null and dropdown_choices()==["automatic"]+ENABLED,"Settings has one dropdown: Automatic, English, Batches 01-04 (%s)" % str(dropdown_choices()))
    var names: Array=range(d.item_count).map(func(i):return d.get_item_text(i))
    check(names==["Automatic (English)","English","Español (Latinoamérica)","Español (España)","Português (Brasil)","Français","Deutsch","Italiano","Nederlands","Polski","Русский","Українська","Türkçe","Bahasa Indonesia","Tiếng Việt","ไทย","हिन्दी","日本語","한국어","简体中文","繁體中文"],"Each language is listed in its own name and script: %s" % str(names))
    check(range(d.item_count).all(func(i):return not d.is_item_disabled(i)),"No item is a disabled placeholder")
    check(d.text=="Automatic (English)" and d.selected==0,"The closed dropdown shows the current choice: %s" % d.text)
    var notice:=false
    for l in game.rows.find_children("*","Label",true,false):
        if l.text==tr("LANG_DISABLED") or l.text==tr("LANGUAGE_NOTE"):notice=true
    check(not notice,"No development notice (Change 16)")
    # A test-era save asking for a draft language shows English and keeps the stored choice for later.
    # A test-era save that stored ja_JP while it was a draft: kept, and since Change 43 it applies.
    SettingsState.from_save_dict({"selected_language":"ja_JP"});await frames(2)
    check(SettingsState.selected_language=="ja_JP" and TranslationServer.get_locale()=="ja_JP" and d.text=="日本語","A stored ja_JP choice from a draft-era save is kept and now applies Japanese (%s, %s)" % [SettingsState.selected_language,d.text])
    SettingsState.from_save_dict({"selected_language":"ar_SA"});await frames(2)
    check(SettingsState.selected_language=="automatic" and TranslationServer.get_locale()=="en","A stored locale outside the target set resets to Automatic (%s)" % SettingsState.selected_language)
    SettingsState.from_save_dict({"selected_language":"automatic"});await frames(1)
    var was_probe: bool=BootContext.is_probe
    BootContext.is_probe=false
    check(not LocalizationService.enable_test_batch("batch01") and not LocalizationService.set_test_locale("de_DE") and not LocalizationService.set_test_device_locale("de_DE"),"The test switches are refused outside probes and captures")
    BootContext.is_probe=was_probe
    check(LocalizationService.available_languages()==(ENABLED as Array[String]) and TranslationServer.get_locale()=="en","…and changed nothing")
    game._close()

# ---------------------------------------------------------------- 2. routing, coverage, glyphs
func routing_and_coverage() -> void:
    check(LocalizationService.enable_test_batch("batch01") and LocalizationService.available_languages()==(ENABLED as Array[String]),"The batch01 test switch still answers and adds nothing (the batch is enabled)")
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
    # Automatic (Change 40): the device language picks the closest enabled catalog; Spain stays Spain.
    LocalizationService.select_language("automatic")
    for pair in [["es_ES","es_ES","Ajustes"],["es-419","es_419","Configuración"],["es_MX","es_419","Configuración"],["es_AR","es_419","Configuración"],["es_US","es_419","Configuración"],["es","es_419","Configuración"],["pt_BR","pt_BR",catalogs.pt_BR.SETTINGS],["pt_PT","pt_BR",catalogs.pt_BR.SETTINGS],["fr_CA","fr_FR",catalogs.fr_FR.SETTINGS],["de_AT","de_DE",catalogs.de_DE.SETTINGS],["de_CH","de_DE",catalogs.de_DE.SETTINGS]]:
        LocalizationService.set_test_device_locale(pair[0]);await frames(1)
        check(LocalizationService.resolved_language("automatic")==pair[1] and TranslationServer.get_locale()==LOCALES[pair[1]] and tr("SETTINGS")==pair[2],"Automatic on a %s device reads %s (%s)" % [pair[0],pair[1],tr("SETTINGS")])
    check(SettingsState.selected_language=="automatic","Automatic stays the stored preference while it follows the device")
    LocalizationService.set_test_device_locale("en_US");await frames(1)
    check(TranslationServer.get_locale()=="en","Automatic on an English device is English again")

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
    # The player's path: Settings, open the language dropdown, tap Deutsch.
    game._open("settings");await frames(4)
    check(await choose("de_DE"),"The dropdown offers Deutsch")
    await frames(4)
    check(SettingsState.selected_language=="de_DE" and TranslationServer.get_locale()=="de_DE","Choosing Deutsch switches at once (no restart)")
    check(game.get_node("Sheet/Margin/Content/Header/Title").text==catalogs.de_DE.PANEL_SETTINGS,"The open Settings panel redraws its title in German")
    check(dropdown().text=="Deutsch" and dropdown().get_item_text(0)=="Automatisch (English)" and not dropdown().get_popup().visible,"…the closed dropdown shows Deutsch, Automatic reads Automatisch (English), and the menu closed")
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
    # A player build has no test switch: the same save still opens in French (Batch 01 is enabled).
    LocalizationService.select_language("fr_FR");await frames(1)
    SaveService.save_now()
    LocalizationService._test_languages.clear()
    SaveService.load_and_apply();await frames(3)
    check(SettingsState.selected_language=="fr_FR" and TranslationServer.get_locale()=="fr_FR","Without any test switch the same save opens in French")
    check(int(sim.state.player_level)==42,"…and its progression loads intact")
