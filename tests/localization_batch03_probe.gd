extends "res://tests/localization_batch01_probe.gd"
## Localization Batch 03 (Change 42): tr_TR, id_ID, vi_VN, th_TH and hi_IN. Reuses the Batch 01 probe's helpers.
## 1. Availability: before activation the batch loads only through the probe switch; once enabled the five are
##    selectable without it, the four Batch 04 drafts and an unvalidated batch name are refused.
## 2. Routing and coverage: each locale reads its own catalog through Godot's PO loader; every key resolves.
## 3. Fonts and shaping (system fonts switched off for the check): every catalog character is in the font the
##    locale draws with; Thai and Hindi swap the theme font to a Noto fallback chain while every other locale keeps
##    the plain DejaVu theme font; Devanagari conjuncts ligate, Thai marks are positioned, Thai breaks into words
##    without spaces; the language dropdown always draws ไทย and हिन्दी.
## 4. Automatic: tr, id (and the legacy in), vi, th, hi device locales; neighbours (en_IN, ms_MY, jv_ID) stay English.
## 5. Dynamic text, Turkish dotted capitals, Hindi count-neutral lines; live switching with panels open;
##    persistence and old saves.
const BATCH3:=["tr_TR","id_ID","vi_VN","th_TH","hi_IN"]
const BATCH04:=["ja_JP","ko_KR","zh_CN","zh_TW"]
var THEME: Theme=preload("res://resources/game/theme.tres")
var DEJAVU: FontFile=preload("res://assets/Fonts/DejaVuSans.ttf")
var NOTO_THAI: FontFile=preload("res://assets/Fonts/NotoSansThai.ttf")
var NOTO_DEVANAGARI: FontFile=preload("res://assets/Fonts/NotoSansDevanagari.ttf")
var enabled_now:=false

func run() -> void:
    startup_locale=TranslationServer.get_locale()
    SettingsState.mute_all_sfx()
    english=preload("res://tests/localization_sweep.gd").read_po("res://localization/en.po")
    for lang in BATCH3:catalogs[lang]=preload("res://tests/localization_sweep.gd").read_po("res://localization/%s.po" % lang)
    enabled_now=BATCH3.all(func(l):return l in LocalizationService.ENABLED_LANGUAGES)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.set_physics_process(false)
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    await frames(10)
    await availability_batch03()
    await routing_batch03()
    await fonts_and_shaping()
    await automatic_batch03()
    await dynamic_text_batch03()
    await live_switching_batch03()
    await persistence_batch03()
    LocalizationService.select_language("automatic")
    LocalizationService.set_test_device_locale("")
    print("LOCALIZATION_BATCH03_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- 1. availability
func availability_batch03() -> void:
    var drafts: Array=LocalizationService.RELEASE_LANGUAGES.filter(func(l):return not l in LocalizationService.ENABLED_LANGUAGES)
    if enabled_now:
        check(LocalizationService.ENABLED_LANGUAGES.size()==16 and drafts==BATCH04,"English and 15 translations are enabled; only the four Batch 04 drafts remain (%s)" % str(drafts))
        check(LocalizationService.available_languages()==LocalizationService.ENABLED_LANGUAGES,"Batch 03 is available without any test switch")
    else:
        check(not BATCH3.any(func(l):return l in LocalizationService.available_languages()),"Before activation no Batch 03 locale is offered to a player")
    for lang in BATCH04:
        check(not LocalizationService.select_language(lang) and SettingsState.selected_language=="automatic","%s (Batch 04 draft) cannot be selected" % lang)
    check(not LocalizationService.enable_test_batch("batch04"),"An unvalidated batch name (batch04) is refused")
    var was_probe: bool=BootContext.is_probe
    BootContext.is_probe=false
    check(enabled_now or not LocalizationService.enable_test_batch("batch03"),"The batch03 switch is refused outside probes")
    BootContext.is_probe=was_probe
    check(LocalizationService.enable_test_batch("batch03"),"The batch03 test switch answers in a probe")
    check(BATCH3.all(func(l):return l in LocalizationService.available_languages()),"…and the five are selectable")
    game._open("settings");await frames(4)
    var choices:=dropdown_choices()
    check(choices==["automatic"]+LocalizationService.available_languages() and not BATCH04.any(func(l):return l in choices),"The dropdown lists Automatic and the available languages, no Batch 04 draft (%d choices)" % choices.size())
    for lang in BATCH3:
        var i: int=choices.find(lang)
        check(i>0 and dropdown().get_item_text(i)==LocalizationService.NATIVE_NAMES[lang],"%s is listed by its own name %s" % [lang,LocalizationService.NATIVE_NAMES[lang]])
    game._close()

# ---------------------------------------------------------------- 2. routing and coverage
func routing_batch03() -> void:
    for lang in BATCH3:
        check(LocalizationService.GODOT_LOCALES.get(lang,"")==lang,"%s maps to Godot locale %s" % [lang,lang])
        check(LocalizationService.select_language(lang),"%s selectable" % lang)
        await frames(1)
        check(TranslationServer.get_locale()==lang,"%s routes to Godot locale %s (got %s)" % [lang,lang,TranslationServer.get_locale()])
        var wrong: Array=[]
        for key in english:
            if tr(key)!=catalogs[lang][key]:wrong.append(key)
        check(wrong.is_empty() and catalogs[lang].size()==english.size(),"%s: Godot's PO loader returns the catalog text for all %d keys (%d wrong: %s)" % [lang,english.size(),wrong.size(),str(wrong.slice(0,3))])
    LocalizationService.select_language("de_DE");await frames(1)
    var german:=tr("SETTINGS")
    LocalizationService.select_language("tr_TR");await frames(1)
    check(german!=tr("SETTINGS") and tr("SETTINGS")==catalogs.tr_TR.SETTINGS,"Earlier and Batch 03 catalogs do not shadow each other (de %s, tr %s)" % [german,tr("SETTINGS")])
    LocalizationService.select_language("automatic");await frames(1)

# ---------------------------------------------------------------- 3. fonts and shaping
func chain_rids(font: Font) -> Array:
    var out: Array=[]
    for rid in font.get_rids():out.append(rid)
    return out

## Shapes text with a font chain and returns the glyphs and word breaks Godot's text server produced.
func shape(text: String,font: Font,lang: String,size:=22) -> Dictionary:
    var ts:=TextServerManager.get_primary_interface()
    var rid:=ts.create_shaped_text()
    ts.shaped_text_add_string(rid,text,font.get_rids(),size,{},lang)
    ts.shaped_text_shape(rid)
    # Line-break opportunities at a narrow width: Thai has no spaces, so these come from the ICU dictionary.
    var out:={"glyphs":ts.shaped_text_get_glyphs(rid),"breaks":ts.shaped_text_get_line_breaks(rid,40.0)}
    ts.free_rid(rid)
    return out

func fonts_and_shaping() -> void:
    var system_fallback:=[DEJAVU.allow_system_fallback,NOTO_THAI.allow_system_fallback,NOTO_DEVANAGARI.allow_system_fallback]
    for f in [DEJAVU,NOTO_THAI,NOTO_DEVANAGARI]:f.allow_system_fallback=false
    check(not DEJAVU.has_char("ก".unicode_at(0)) and not DEJAVU.has_char("क".unicode_at(0)),"DejaVu Sans has no Thai or Devanagari (why the fallbacks exist)")
    for lang in BATCH3:
        LocalizationService.select_language(lang);await frames(2)
        var font: Font=game.get_theme_default_font()
        var expected: Font=LocalizationService.script_font(lang)
        check(font==expected and THEME.default_font==expected,"%s draws with %s" % [lang,"the Thai chain" if lang=="th_TH" else ("the Devanagari chain" if lang=="hi_IN" else "the plain theme font")])
        var chars: Dictionary={}
        for key in catalogs[lang]:
            for c in catalogs[lang][key]:
                if c.unicode_at(0)>=32:chars[c]=true
        var missing: Array=[]
        for c in chars:
            if not font.has_char(c.unicode_at(0)):missing.append(c)
        check(missing.is_empty(),"%s: the locale's bundled font chain has all %d catalog characters (missing %s)" % [lang,chars.size(),str(missing)])
        # Every glyph of every catalog string comes from a bundled font: no system font, no empty box.
        var rids:=chain_rids(font)
        var bad: Array=[]
        for key in catalogs[lang]:
            for g in shape(str(catalogs[lang][key]).replace(char(10)," "),font,lang).glyphs:
                if int(g.index)==0 and not str(catalogs[lang][key]).is_empty() or not rids.has(g.font_rid):
                    if int(g.flags) & TextServer.GRAPHEME_IS_VIRTUAL:continue
                    bad.append(key);break
            if bad.size()>3:break
        check(bad.is_empty(),"%s: every catalog string shapes with bundled glyphs only (%s)" % [lang,str(bad)])
    LocalizationService.select_language("en_US");await frames(2)
    check(game.get_theme_default_font()==DEJAVU and THEME.default_font==DEJAVU,"English goes back to the plain DejaVu theme font (Latin and Cyrillic line heights unchanged)")
    # Devanagari: conjuncts become ligatures, the matra sits on its consonant.
    var deva: Font=LocalizationService.script_font("hi_IN")
    var ksha:=shape("क्ष",deva,"hi")
    check(ksha.glyphs.size()<3 and ksha.glyphs.all(func(g):return g.font_rid==NOTO_DEVANAGARI.get_rids()[0]),"क्ष (ka + virama + ssa) shapes as a conjunct (%d glyphs for 3 code points)" % ksha.glyphs.size())
    var tro:=shape("ट्रॉफ़ियाँ",deva,"hi")
    check(tro.glyphs.size()<"ट्रॉफ़ियाँ".length(),"ट्रॉफ़ियाँ shapes with ligatures and marks (%d glyphs, %d code points)" % [tro.glyphs.size(),"ट्रॉफ़ियाँ".length()])
    var ki:=shape("कि",deva,"hi")
    var ka_index: int=TextServerManager.get_primary_interface().font_get_glyph_index(NOTO_DEVANAGARI.get_rids()[0],22,"क".unicode_at(0),0)
    check(ki.glyphs.size()==2 and int(ki.glyphs[1].index)==ka_index and int(ki.glyphs[0].index)!=ka_index,"कि draws the i-matra before its consonant in one cluster (no dotted circle; %d glyphs)" % ki.glyphs.size())
    # Thai: stacked marks are positioned (GPOS offset or contextual alternate), words break without spaces.
    var thai: Font=LocalizationService.script_font("th_TH")
    var ts:=TextServerManager.get_primary_interface()
    var stack:=shape("ปั้น",thai,"th")
    var positioned:=false
    for g in stack.glyphs:
        if Vector2(g.offset)!=Vector2.ZERO:positioned=true
        if int(g.index)!=ts.font_get_glyph_index(NOTO_THAI.get_rids()[0],22,"ปั้น".unicode_at(int(g.start)),0):positioned=true
    check(stack.glyphs.size()==4 and positioned,"ปั้น: the vowel and tone mark stack above ป (positioned or substituted, %d glyphs)" % stack.glyphs.size())
    var words:=shape("ปลดล็อกค่ายแล้ว",thai,"th")
    var edges: Array=Array(words.breaks).filter(func(i):return i>0 and i<15)
    check(not edges.is_empty() and edges.all(func(i):return i in [3,7,11]),"Thai without spaces wraps only between words ปลด|ล็อก|ค่าย|แล้ว (breaks at %s; break iterators %s)" % [str(edges),str(ts.has_feature(TextServer.FEATURE_BREAK_ITERATORS))])
    # No wrapped Thai line may start with a following vowel, mai yamok or a combining mark.
    var bad_starts: Array=[]
    for key in catalogs.th_TH:
        var s: String=str(catalogs.th_TH[key]).replace(char(10)," ")
        for i in Array(shape(s,thai,"th").breaks):
            if i>0 and i<s.length() and s.unicode_at(i) in [0x0E30,0x0E32,0x0E33,0x0E45,0x0E46,0x0E31,0x0E34,0x0E35,0x0E36,0x0E37,0x0E38,0x0E39,0x0E3A,0x0E47,0x0E48,0x0E49,0x0E4A,0x0E4B,0x0E4C,0x0E4D,0x0E4E]:
                bad_starts.append(key);break
    check(bad_starts.is_empty(),"No Thai catalog line can wrap before a following vowel, ๆ or a mark (%s)" % str(bad_starts.slice(0,4)))
    var label:=Label.new();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size=Vector2(130,0)
    label.text=catalogs.th_TH.GUIDE_CAMP_EXPLORE_DETAIL;label.add_theme_font_override("font",thai);label.add_theme_font_size_override("font_size",22)
    add_child(label);await frames(2)
    check(label.get_line_count()>=3,"A Thai sentence wraps onto %d lines in a 130 px label" % label.get_line_count())
    label.queue_free()
    # Vietnamese stacked diacritics are precomposed characters DejaVu draws whole.
    var vi:=shape("Đã mở khóa Ghép tất cả · Thành thạo",DEJAVU,"vi")
    check(vi.glyphs.all(func(g):return int(g.index)!=0),"Vietnamese stacked diacritics shape in DejaVu Sans without missing glyphs")
    # The dropdown names every language in its own script, in any locale.
    game._open("settings");await frames(4)
    var d:=dropdown()
    var dfont: Font=d.get_theme_font("font")
    var pfont: Font=d.get_popup().get_theme_font("font")
    check(dfont==LanguageDropdownFont() and pfont==dfont,"The dropdown and its menu draw with the all-scripts chain in English")
    for lang in LocalizationService.available_languages():
        var name_: String=LocalizationService.NATIVE_NAMES[lang]
        check(Array(name_.split("")).all(func(c):return c==" " or pfont.has_char(c.unicode_at(0))),"The menu can draw %s" % name_)
    game._close()
    DEJAVU.allow_system_fallback=system_fallback[0];NOTO_THAI.allow_system_fallback=system_fallback[1];NOTO_DEVANAGARI.allow_system_fallback=system_fallback[2]

func LanguageDropdownFont() -> Font:
    return game.LANGUAGE_DROPDOWN.ALL_SCRIPTS_FONT

# ---------------------------------------------------------------- 4. Automatic
func automatic_batch03() -> void:
    LocalizationService.select_language("automatic")
    for pair in [["tr","tr_TR"],["tr_TR","tr_TR"],["tr_CY","tr_TR"],["id","id_ID"],["id_ID","id_ID"],["in_ID","id_ID"],["in","id_ID"],["id-ID","id_ID"],
            ["vi","vi_VN"],["vi_VN","vi_VN"],["th","th_TH"],["th_TH","th_TH"],["hi","hi_IN"],["hi_IN","hi_IN"],
            ["en_IN","en_US"],["ms_MY","en_US"],["jv_ID","en_US"],["ja_JP","en_US"],["zh_CN","en_US"]]:
        LocalizationService.set_test_device_locale(pair[0]);await frames(1)
        var expected: String=catalogs[pair[1]].SETTINGS if catalogs.has(pair[1]) else english.SETTINGS
        check(LocalizationService.resolved_language("automatic")==pair[1] and tr("SETTINGS")==expected,"Automatic on a %s device reads %s (%s)" % [pair[0],pair[1],tr("SETTINGS")])
    LocalizationService.set_test_device_locale("th_TH");await frames(2)
    game._open("settings");await frames(4)
    check(dropdown().get_item_text(0)==catalogs.th_TH.LANG_AUTOMATIC+" (ไทย)" and game.get_theme_default_font()==LocalizationService.script_font("th_TH"),"Automatic on a Thai device shows %s and draws Thai" % dropdown().get_item_text(0))
    game._close()
    LocalizationService.set_test_device_locale("en_US");await frames(1)

# ---------------------------------------------------------------- 5. text, switching, persistence
func dynamic_text_batch03() -> void:
    for lang in BATCH3:
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
    LocalizationService.select_language("tr_TR");await frames(1)
    check(tr("LEVEL")=="SEVİYE" and tr("COMPARE_EQUIPPED")=="KUŞANILI","Turkish capitals keep dotted İ and dotless I (%s, %s)" % [tr("LEVEL"),tr("COMPARE_EQUIPPED")])
    check((tr("DROP_GEMS") % ["12","3"]).contains("%12"),"Turkish writes the percent sign before the number: %s" % (tr("DROP_GEMS") % ["12","3"]))
    LocalizationService.select_language("hi_IN");await frames(1)
    for n in [1,2,5]:
        check((tr("MERGE_ALL_DONE") % [n,n]).contains(": %d" % n) and (tr("CLAIM_REWARD") % [str(n),str(n)]).contains(": %d" % n),"Hindi count lines keep the number after its label for %d: %s" % [n,tr("CLAIM_REWARD") % [str(n),str(n)]])
    LocalizationService.select_language("automatic");await frames(1)

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

func live_switching_batch03() -> void:
    sim.new_profile();sim.state.tutorial.mode="none";sim.campaign.onboarding.reveal_all(true);sim.state.tutorial.seen.append("road_ahead")
    sim.state.unlocked_stage=3;sim.state.coins=50000.0
    for id in ["wood_sword","potion"]:sim.add_item(id,3,true,false)
    sim.campaign.discover_spot(0,2);sim.touch();await frames(8)
    game._open("settings");await frames(4)
    check(await choose("th_TH"),"The dropdown offers ไทย")
    await frames(4)
    check(SettingsState.selected_language=="th_TH" and TranslationServer.get_locale()=="th_TH","Choosing ไทย switches at once (no restart)")
    check(game.get_node("Sheet/Margin/Content/Header/Title").text==catalogs.th_TH.PANEL_SETTINGS,"The open Settings panel redraws its title in Thai")
    await get_tree().create_timer(.3).timeout
    check(game.get_node("Safe/Layout/Map/ViewCamp").text==catalogs.th_TH.VIEW_CAMP,"The View Camp button redraws in Thai")
    check(sim.catalog.groups[0].name==catalogs.th_TH["CONTENT_GROUPS_UNIT-BLUE-CAP"],"Catalog enemy names are re-translated (%s)" % sim.catalog.groups[0].name)
    check(english_left("th_TH").is_empty(),"Nothing on screen is still English after the switch: %s" % str(english_left("th_TH")))
    var order:=["hi_IN","tr_TR","vi_VN","id_ID","th_TH","hi_IN"]
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
        check(left.is_empty() and title!="" and TranslationServer.get_locale()==lang and game.get_theme_default_font()==LocalizationService.script_font(lang),"%s open, switched to %s: redrawn (title %s), right font, no English left %s" % [panels[i],lang,title,str(left)])
    game._close()
    LocalizationService.select_language("en_US");await frames(6)
    await get_tree().create_timer(.3).timeout
    check(TranslationServer.get_locale()=="en" and game.get_node("Safe/Layout/Map/ViewCamp").text==english.VIEW_CAMP and game.get_theme_default_font()==DEJAVU,"Switching back to English restores English labels and the plain theme font")

func persistence_batch03() -> void:
    sim.state.coins=555.0;sim.state.player_level=37;sim.touch()
    LocalizationService.select_language("hi_IN");await frames(2)
    check(SaveService.save_now(),"A save with Hindi selected is written")
    var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SaveService.save_path()))
    check(str(saved.settings.selected_language)=="hi_IN","The preference is stored in settings, apart from progression")
    LocalizationService.select_language("vi_VN");await frames(2)
    SaveService.load_and_apply();await frames(3)
    check(SettingsState.selected_language=="hi_IN" and TranslationServer.get_locale()=="hi_IN" and game.get_theme_default_font()==LocalizationService.script_font("hi_IN"),"Reloading restores Hindi and its font")
    check(int(sim.state.player_level)==37 and is_equal_approx(float(sim.state.coins),555.0),"Progression is unchanged by language changes and reloads")
    SettingsState.from_save_dict({"selected_language":"th_TH"});await frames(1)
    check(SettingsState.selected_language=="th_TH","An older settings record that stored th_TH (a test build) keeps it")
    SettingsState.from_save_dict({"selected_language":"ja_JP"});await frames(1)
    check(SettingsState.selected_language=="ja_JP" and TranslationServer.get_locale()=="en" and game.get_theme_default_font()==DEJAVU,"A stored Batch 04 draft shows English and stays stored")
    LocalizationService.select_language("tr_TR");await frames(1)
    SaveService.save_now()
    if enabled_now:
        LocalizationService._test_languages.clear()
        SaveService.load_and_apply();await frames(3)
        check(SettingsState.selected_language=="tr_TR" and TranslationServer.get_locale()=="tr_TR","Without any test switch the same save opens in Turkish")
        check(int(sim.state.player_level)==37,"…and its progression loads intact")
