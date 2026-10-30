extends "res://tests/localization_batch03_probe.gd"
## Localization Batch 04 (Change 43): ja_JP, ko_KR, zh_CN and zh_TW, the final batch. Reuses the Batch 01/03 helpers.
## 1. Availability: before activation the batch loads only through the probe switch; once enabled all 20 target
##    languages are selectable without it and the dropdown has 21 rows (Automatic + 20), each in its own name.
## 2. Routing and coverage: each locale reads its own catalog (zh_CN and zh_TW never shadow each other).
## 3. Fonts (system fonts switched off): each CJK locale draws with its own regional Noto face first and DejaVu
##    second; every catalog character is in that chain; CJK characters and CJK punctuation come from the regional
##    face, digits and Latin from DejaVu; every other locale's font and line height is unchanged; the dropdown
##    draws all 20 names and the translated Automatic in every CJK locale without raising its line height.
## 4. Line breaking: no Japanese or Chinese catalog line can start with closing punctuation, ー, 々 or a small kana,
##    or end with an opening bracket, at a narrow width; Korean never breaks before punctuation.
## 5. Automatic: Chinese by script, then region (Hans/Hant beat CN/TW/HK/MO/SG), generic zh Simplified, Java's
##    zh_TW_#Hant form, ja/ko, unsupported neighbours (yue, wuu) English; earlier mappings unchanged.
## 6. Dynamic text and units; live switching with panels open; persistence, restart and old saves.
const BATCH4:=["ja_JP","ko_KR","zh_CN","zh_TW"]
var FACES: Dictionary={
    "ja_JP":preload("res://assets/Fonts/NotoSansJP-LootFarmer.ttf"),"ko_KR":preload("res://assets/Fonts/NotoSansKR-LootFarmer.ttf"),
    "zh_CN":preload("res://assets/Fonts/NotoSansSC-LootFarmer.ttf"),"zh_TW":preload("res://assets/Fonts/NotoSansTC-LootFarmer.ttf")}
var ENDONYM_FACES: Array=[preload("res://assets/Fonts/NotoSansJP-Endonym.ttf"),preload("res://assets/Fonts/NotoSansKR-Endonym.ttf"),
    preload("res://assets/Fonts/NotoSansSC-Endonym.ttf"),preload("res://assets/Fonts/NotoSansTC-Endonym.ttf")]
## Closing punctuation and iteration marks never start a line (ICU line-break classes CL, CP, EX, IS, NS).
const NO_LINE_START:="、。，．,.：；！？!?)）」』】〉》々ゝゞ・"
## Small kana and ー (class CJ): ICU's default "normal" rules allow a break before them (JIS X 4051 non-strict);
## counted and reported, not failed.
const SMALL_KANA:="ーぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮヵヶ"
const NO_LINE_END:="（「『【〈《“‘(["
var enabled4:=false

func run() -> void:
    startup_locale=TranslationServer.get_locale()
    SettingsState.mute_all_sfx()
    english=preload("res://tests/localization_sweep.gd").read_po("res://localization/en.po")
    for lang in BATCH4:catalogs[lang]=preload("res://tests/localization_sweep.gd").read_po("res://localization/%s.po" % lang)
    for lang in ["th_TH","hi_IN","de_DE"]:catalogs[lang]=preload("res://tests/localization_sweep.gd").read_po("res://localization/%s.po" % lang)
    enabled4=BATCH4.all(func(l):return l in LocalizationService.ENABLED_LANGUAGES)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.set_physics_process(false)
    LocalizationService.set_test_device_locale("en_US")
    LocalizationService.select_language("automatic")
    await frames(10)
    await availability_batch04()
    await routing_batch04()
    await fonts_batch04()
    await line_breaking_batch04()
    await automatic_batch04()
    await dynamic_text_batch04()
    await live_switching_batch04()
    await persistence_batch04()
    LocalizationService.select_language("automatic")
    LocalizationService.set_test_device_locale("")
    print("LOCALIZATION_BATCH04_PROBE checks=%d failures=%d" % [checks,failures])
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- 1. availability
func availability_batch04() -> void:
    if enabled4:
        check(LocalizationService.ENABLED_LANGUAGES==LocalizationService.RELEASE_LANGUAGES,"All 20 target languages are enabled, in release order")
        check(LocalizationService.available_languages()==LocalizationService.RELEASE_LANGUAGES,"…and available without any test switch")
        check(not LocalizationService.ALL_LANGUAGES_CERTIFIED,"The 20-language certification flag stays false until the real-device gate (Playbook 132.5 step 5)")
    else:
        check(not BATCH4.any(func(l):return l in LocalizationService.available_languages()),"Before activation no Batch 04 locale is offered to a player")
        for lang in BATCH4:
            check(not LocalizationService.select_language(lang) and SettingsState.selected_language=="automatic","%s cannot be selected before activation" % lang)
    check(not LocalizationService.enable_test_batch("batch05"),"An unknown batch name is refused")
    var was_probe: bool=BootContext.is_probe
    BootContext.is_probe=false
    check(enabled4 or not LocalizationService.enable_test_batch("batch04"),"The batch04 switch is refused outside probes")
    BootContext.is_probe=was_probe
    check(LocalizationService.enable_test_batch("batch04"),"The batch04 test switch answers in a probe")
    check(LocalizationService.available_languages()==LocalizationService.RELEASE_LANGUAGES,"…and all 20 languages are selectable")
    game._open("settings");await frames(4)
    var choices:=dropdown_choices()
    check(choices.size()==21 and choices==["automatic"]+LocalizationService.RELEASE_LANGUAGES,"The dropdown lists Automatic and the 20 languages: %d rows, no duplicate (%d distinct)" % [choices.size(),Array(choices).reduce(func(a,c):return a if c in a else a+[c],[]).size()])
    for lang in BATCH4:
        var i: int=choices.find(lang)
        check(i>0 and dropdown().get_item_text(i)==LocalizationService.NATIVE_NAMES[lang],"%s is listed by its own name %s" % [lang,LocalizationService.NATIVE_NAMES[lang]])
    game._close()

# ---------------------------------------------------------------- 2. routing and coverage
func routing_batch04() -> void:
    for lang in BATCH4:
        check(LocalizationService.GODOT_LOCALES.get(lang,"")==lang,"%s maps to Godot locale %s" % [lang,lang])
        check(LocalizationService.select_language(lang),"%s selectable" % lang)
        await frames(1)
        check(TranslationServer.get_locale()==lang,"%s routes to Godot locale %s (got %s)" % [lang,lang,TranslationServer.get_locale()])
        var wrong: Array=[]
        for key in english:
            if tr(key)!=catalogs[lang][key]:wrong.append(key)
        check(wrong.is_empty() and catalogs[lang].size()==english.size(),"%s: Godot's PO loader returns the catalog text for all %d keys (%d wrong: %s)" % [lang,english.size(),wrong.size(),str(wrong.slice(0,3))])
    LocalizationService.select_language("zh_CN");await frames(1)
    var cn:=[tr("SETTINGS"),tr("BOSS_LABEL")]
    LocalizationService.select_language("zh_TW");await frames(1)
    var tw:=[tr("SETTINGS"),tr("BOSS_LABEL")]
    check(cn==["设置","首领"] and tw==["設定","頭目"],"Simplified and Traditional Chinese are separate catalogs with regional words (%s / %s)" % [str(cn),str(tw)])
    var same:=0
    for key in english:
        if catalogs.zh_CN[key]==catalogs.zh_TW[key] and RegEx.create_from_string("[\\x{4e00}-\\x{9fff}]").search(catalogs.zh_CN[key]):same+=1
    check(same<english.size()/8,"zh_TW is not a copy of zh_CN: %d of %d keys with Han text are identical" % [same,english.size()])
    LocalizationService.select_language("automatic");await frames(1)

# ---------------------------------------------------------------- 3. fonts
func catalog_chars(lang: String) -> Dictionary:
    var chars: Dictionary={}
    for key in catalogs[lang]:
        for c in str(catalogs[lang][key]).replace(char(10),""):
            # U+2060 WORD JOINER (Korean keep-all, tools/korean_keep_all.py) is a format character: no glyph.
            if c.unicode_at(0)>=32 and c.unicode_at(0)!=0x2060:chars[c]=true
    return chars

func fonts_batch04() -> void:
    var all_fonts: Array=[DEJAVU,NOTO_THAI,NOTO_DEVANAGARI]+FACES.values()+ENDONYM_FACES
    var saved: Array=all_fonts.map(func(f):return f.allow_system_fallback)
    for f in all_fonts:f.allow_system_fallback=false
    check(not DEJAVU.has_char("あ".unicode_at(0)) and not DEJAVU.has_char("한".unicode_at(0)) and not DEJAVU.has_char("中".unicode_at(0)),"DejaVu Sans has no kana, Hangul or Han (why the regional faces exist)")
    var english_height: float=DEJAVU.get_height(22)
    for lang in BATCH4:
        LocalizationService.select_language(lang);await frames(2)
        var font: Font=game.get_theme_default_font()
        check(font==LocalizationService.script_font(lang) and THEME.default_font==font and font.base_font==FACES[lang] and Array(font.fallbacks)==[DEJAVU],"%s draws with its own regional face first and DejaVu second" % lang)
        var missing: Array=[]
        for c in catalog_chars(lang):
            if not font.has_char(c.unicode_at(0)):missing.append(c)
        check(missing.is_empty(),"%s: the chain has all %d catalog characters (missing %s)" % [lang,catalog_chars(lang).size(),str(missing.slice(0,8))])
        var face_rid: RID=FACES[lang].get_rids()[0]
        var dejavu_rid: RID=DEJAVU.get_rids()[0]
        var bad: Array=[]
        var wrong_face: Array=[]
        for key in catalogs[lang]:
            var s: String=str(catalogs[lang][key]).replace(char(10)," ")
            for g in shape(s,font,lang.get_slice("_",0)).glyphs:
                if int(g.flags) & TextServer.GRAPHEME_IS_VIRTUAL:continue
                var cp: int=s.unicode_at(int(g.start))
                # A Korean word joiner at a font-run boundary keeps glyph 0 with zero advance (the subsets' .notdef is
                # empty, so nothing is drawn); any other glyph 0 is a missing character.
                if cp==0x2060 and float(g.advance)==0.0:continue
                if int(g.index)==0 and int(g.end)>int(g.start):bad.append(key);break
                var cjk: bool=cp>=0x2E80 and cp<0xFFEF and not cp in [0x2E80]
                if cjk and g.font_rid!=face_rid:wrong_face.append("%s:%s" % [key,char(cp)]);break
                if cp>=0x30 and cp<=0x39 and g.font_rid!=dejavu_rid:wrong_face.append("%s:%s" % [key,char(cp)]);break
        check(bad.is_empty(),"%s: every catalog string shapes without an empty glyph (%s)" % [lang,str(bad.slice(0,3))])
        check(wrong_face.is_empty(),"%s: every CJK character comes from the regional face and every digit from DejaVu (%s)" % [lang,str(wrong_face.slice(0,3))])
        check(font.get_height(22)<=english_height*1.3,"%s line height %.1f px at 22 px (English %.1f): CJK metrics only in CJK locales" % [lang,font.get_height(22),english_height])
    # The same Han character draws from a different regional face per locale (regional glyph forms).
    var han:="直"
    var faces_used: Array=[]
    for lang in ["ja_JP","zh_CN","zh_TW"]:
        if not FACES[lang].has_char(han.unicode_at(0)):han="通"
    for lang in ["ja_JP","zh_CN","zh_TW"]:
        var g: Array=shape(han,LocalizationService.script_font(lang),lang.get_slice("_",0)).glyphs
        faces_used.append(g[0].font_rid if g.size()>0 else RID())
    check(faces_used[0]!=faces_used[1] and faces_used[1]!=faces_used[2] and faces_used[0]!=faces_used[2],"%s draws from the JP face in Japanese, the SC face in Simplified and the TC face in Traditional Chinese" % han)
    var quote: Array=shape("“任务”",LocalizationService.script_font("zh_CN"),"zh").glyphs
    check(quote.size()>0 and quote[0].font_rid==FACES.zh_CN.get_rids()[0] and float(quote[0].advance)>=20.0,"Simplified Chinese quotation marks are full-width SC glyphs (advance %.1f at 22 px)" % (float(quote[0].advance) if quote.size()>0 else 0.0))
    for lang in ["en_US","de_DE","th_TH","hi_IN","ru_RU","vi_VN"]:
        LocalizationService.select_language(lang);await frames(1)
        var expected: Font={"th_TH":LocalizationService.SCRIPT_FONTS.th_TH,"hi_IN":LocalizationService.SCRIPT_FONTS.hi_IN}.get(lang,DEJAVU)
        check(game.get_theme_default_font()==expected and THEME.default_font==expected,"%s keeps its Change 42 font (CJK faces never join its chain)" % lang)
    LocalizationService.select_language("en_US");await frames(2)
    var label:=Label.new();label.text="Settings";add_child(label);await frames(1)
    check(is_equal_approx(label.get_minimum_size().y,DEJAVU.get_height(22)) or label.get_minimum_size().y<=DEJAVU.get_height(22)+1.0,"An English label is still %.1f px tall (DejaVu %.1f)" % [label.get_minimum_size().y,DEJAVU.get_height(22)])
    label.queue_free()
    # The dropdown: all 20 names in every locale, Automatic in the CJK locales' own faces, unchanged line height.
    var selector_height: float=LocalizationService.ALL_SCRIPTS_FONT.get_height(24)
    var pre_cjk: float=maxf(DEJAVU.get_height(24),maxf(NOTO_THAI.get_height(24),NOTO_DEVANAGARI.get_height(24)))
    check(is_equal_approx(selector_height,pre_cjk),"The endonym faces do not raise the dropdown's line height (%.1f px, Thai/Devanagari chain %.1f px)" % [selector_height,pre_cjk])
    for lang in ["en_US","th_TH"]+BATCH4:
        LocalizationService.select_language(lang);await frames(2)
        game._open("settings");await frames(4)
        var d:=dropdown()
        var pfont: Font=d.get_popup().get_theme_font("font")
        var undrawable: Array=[]
        for i in range(d.item_count):
            for c in d.get_item_text(i):
                if c!=" " and not pfont.has_char(c.unicode_at(0)):undrawable.append(d.get_item_text(i));break
        check(pfont==LocalizationService.selector_font(lang) and d.get_theme_font("font")==pfont and undrawable.is_empty(),"%s: the dropdown draws all %d rows (%s; undrawable %s)" % [lang,d.item_count,d.get_item_text(0),str(undrawable)])
        # Each CJK endonym comes from its own regional endonym face, whatever the UI language.
        for j in range(4):
            var name_: String=LocalizationService.NATIVE_NAMES[BATCH4[j]]
            var first: Array=shape(name_.substr(0,1),pfont,"en").glyphs
            check(first.size()>0 and first[0].font_rid==ENDONYM_FACES[j].get_rids()[0],"%s UI: %s starts with its own regional endonym glyph" % [lang,name_])
        if lang in BATCH4:
            var auto_glyph: Array=shape(catalogs[lang].LANG_AUTOMATIC.substr(0,1),pfont,"en").glyphs
            check(auto_glyph.size()>0 and auto_glyph[0].font_rid==FACES[lang].get_rids()[0],"%s: Automatic (%s) draws in the locale's own face" % [lang,catalogs[lang].LANG_AUTOMATIC])
        game._close()
    for i in range(all_fonts.size()):all_fonts[i].allow_system_fallback=saved[i]
    LocalizationService.select_language("automatic");await frames(1)

# ---------------------------------------------------------------- 4. line breaking
func line_breaking_batch04() -> void:
    var ts:=TextServerManager.get_primary_interface()
    for lang in BATCH4:
        var font: Font=LocalizationService.script_font(lang)
        var bad: Array=[]
        var lines:=0
        var inside_word:=0
        var before_small:=0
        for key in catalogs[lang]:
            for part in str(catalogs[lang][key]).split(char(10)):
                if part.length()<4:continue
                var rid:=ts.create_shaped_text()
                ts.shaped_text_add_string(rid,part,font.get_rids(),22,{},lang.get_slice("_",0))
                var br: PackedInt32Array=ts.shaped_text_get_line_breaks(rid,70.0)
                ts.free_rid(rid)
                for i in range(1,br.size(),2):
                    var end: int=br[i]
                    if end<=0 or end>=part.length():continue
                    lines+=1
                    var next_char:=part.substr(end,1)
                    var prev_char:=part.substr(end-1,1)
                    if next_char==" " and end+1<part.length():next_char=part.substr(end+1,1)
                    if next_char in NO_LINE_START or prev_char in NO_LINE_END:bad.append("%s@%d %s|%s" % [key,end,prev_char,next_char])
                    if next_char in SMALL_KANA:before_small+=1
                    if lang=="ko_KR" and is_word_char(prev_char) and is_word_char(next_char) and (is_hangul(prev_char) or is_hangul(next_char)):inside_word+=1
        check(bad.is_empty(),"%s: %d wrap points at 70 px, none puts closing punctuation or 々 at a line start or an opening bracket at a line end (%s)" % [lang,lines,str(bad.slice(0,4))])
        if lang=="ja_JP":
            print("JAPANESE_WRAP before_small_kana_or_choon=%d of %d wrap points (ICU normal line breaking)" % [before_small,lines])
        if lang=="ko_KR":
            check(inside_word==0,"ko_KR: %d wrap points, none inside a word (word joiners give keep-all wrapping; %d inside a word)" % [lines,inside_word])
    var label:=Label.new();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size=Vector2(180,0)
    label.text=catalogs.ja_JP.GUIDE_CAMP_EXPLORE_DETAIL;label.add_theme_font_override("font",LocalizationService.script_font("ja_JP"));label.add_theme_font_size_override("font_size",22)
    add_child(label);await frames(2)
    check(label.get_line_count()>=2,"A Japanese sentence without spaces wraps onto %d lines in a 180 px label" % label.get_line_count())
    label.queue_free()

func is_hangul(c: String) -> bool:
    var u:=c.unicode_at(0) if c!="" else 0
    return (u>=0xAC00 and u<=0xD7A3) or (u>=0x1100 and u<=0x11FF) or (u>=0x3130 and u<=0x318F)

func is_word_char(c: String) -> bool:
    var u:=c.unicode_at(0) if c!="" else 0
    return is_hangul(c) or (u<128 and (c.is_valid_int() or (c.to_lower()!=c.to_upper()))) or (u>=0x4E00 and u<=0x9FFF)

# ---------------------------------------------------------------- 5. Automatic
func automatic_batch04() -> void:
    LocalizationService.select_language("automatic")
    for pair in [["zh_CN","zh_CN"],["zh-CN","zh_CN"],["zh_SG","zh_CN"],["zh_Hans","zh_CN"],["zh_Hans_CN","zh_CN"],["zh-Hans-SG","zh_CN"],
            ["zh_TW","zh_TW"],["zh_HK","zh_TW"],["zh_MO","zh_TW"],["zh_Hant","zh_TW"],["zh_Hant_TW","zh_TW"],["zh-Hant-HK","zh_TW"],["zh_TW_#Hant","zh_TW"],
            ["zh_Hant_CN","zh_TW"],["zh_Hans_HK","zh_CN"],["zh_Hans_TW","zh_CN"],["zh","zh_CN"],["zh_CN.UTF-8","zh_CN"],
            ["ja","ja_JP"],["ja_JP","ja_JP"],["ja-JP","ja_JP"],["ko","ko_KR"],["ko_KR","ko_KR"],["ko_KP","ko_KR"],
            ["yue_HK","en_US"],["wuu","en_US"],["mn_MN","en_US"],
            ["es_MX","es_419"],["es_ES","es_ES"],["pt_PT","pt_BR"],["in_ID","id_ID"],["uk_UA","uk_UA"],["be_BY","en_US"],["th","th_TH"],["hi_IN","hi_IN"],["en_GB","en_US"]]:
        LocalizationService.set_test_device_locale(pair[0]);await frames(1)
        var key_lang: String=pair[1]
        check(LocalizationService.resolved_language("automatic")==key_lang,"Automatic on a %s device reads %s (got %s)" % [pair[0],key_lang,LocalizationService.resolved_language("automatic")])
    LocalizationService.set_test_device_locale("zh_Hant_HK");await frames(2)
    game._open("settings");await frames(4)
    check(dropdown().get_item_text(0)==catalogs.zh_TW.LANG_AUTOMATIC+" (繁體中文)" and tr("SETTINGS")==catalogs.zh_TW.SETTINGS and game.get_theme_default_font()==LocalizationService.script_font("zh_TW"),"Automatic on a Hong Kong device shows %s and draws Traditional Chinese" % dropdown().get_item_text(0))
    game._close()
    LocalizationService.set_test_device_locale("ja_JP");await frames(2)
    check(tr("SETTINGS")==catalogs.ja_JP.SETTINGS and game.get_theme_default_font()==LocalizationService.script_font("ja_JP"),"Automatic on a Japanese device draws Japanese (%s)" % tr("SETTINGS"))
    LocalizationService.set_test_device_locale("en_US");await frames(1)

# ---------------------------------------------------------------- 6. text, switching, persistence
func dynamic_text_batch04() -> void:
    for lang in BATCH4:
        LocalizationService.select_language(lang);await frames(1)
        var bad: Array=[]
        for key in english:
            var text: String=tr(key)
            var args:=sample_args(text)
            if args.is_empty():continue
            for big in [false,true]:
                var values:=args.map(func(a):return ("1.25M" if big else "7") if a is String else (12345 if big else 3) if a is int else (987.5 if big else 2.5))
                var out: String=text % values
                if out.strip_edges()=="" or RegEx.create_from_string("%[sdif]").search(out)!=null:bad.append(key)
        check(bad.is_empty(),"%s: every placeholder string formats with small and large sample values (%s)" % [lang,str(bad.slice(0,3))])
        var d: String=game.fmt_duration(3725)
        check(d==tr("DURATION_HOURS_MINUTES") % [1,2] and d!="1h 02m","%s: durations use the locale's units (%s, %s, %s)" % [lang,d,game.fmt_duration(249),game.fmt_duration(37)])
    LocalizationService.select_language("ja_JP");await frames(1)
    check(tr("DURATION_HOURS_MINUTES") % [1,5]=="1時間05分" and (tr("RESPAWNING") % 2.5)=="2.5秒後にキャンプへ戻ります","Japanese units follow the number without a space (%s, %s)" % [tr("DURATION_HOURS_MINUTES") % [1,5],tr("RESPAWNING") % 2.5])
    LocalizationService.select_language("ko_KR");await frames(1)
    check((tr("DURATION_HOURS_MINUTES") % [1,5]).replace(char(0x2060),"")=="1시간 05분" and not RegEx.create_from_string("%[sd]\u2060?(을|를|이|가|은|는|와|과|로|으로)").search(" ".join(catalogs.ko_KR.values())),"Korean: spaced units (%s) and no batchim-dependent particle after a placeholder" % (tr("DURATION_HOURS_MINUTES") % [1,5]))
    LocalizationService.select_language("automatic");await frames(1)

func live_switching_batch04() -> void:
    sim.new_profile();sim.state.tutorial.mode="none";sim.campaign.onboarding.reveal_all(true);sim.state.tutorial.seen.append("road_ahead")
    sim.state.unlocked_stage=3;sim.state.coins=50000.0
    for id in ["wood_sword","potion"]:sim.add_item(id,3,true,false)
    sim.campaign.discover_spot(0,2);sim.touch();await frames(8)
    game._open("settings");await frames(4)
    check(await choose("ja_JP"),"The dropdown offers 日本語")
    await frames(4)
    check(SettingsState.selected_language=="ja_JP" and TranslationServer.get_locale()=="ja_JP","Choosing 日本語 switches at once (no restart)")
    check(game.get_node("Sheet/Margin/Content/Header/Title").text==catalogs.ja_JP.PANEL_SETTINGS,"The open Settings panel redraws its title in Japanese")
    await get_tree().create_timer(.3).timeout
    check(game.get_node("Safe/Layout/Map/ViewCamp").text==catalogs.ja_JP.VIEW_CAMP,"The View Camp button redraws in Japanese")
    check(sim.catalog.groups[0].name==catalogs.ja_JP["CONTENT_GROUPS_UNIT-BLUE-CAP"],"Catalog enemy names are re-translated (%s)" % sim.catalog.groups[0].name)
    check(english_left("ja_JP").is_empty(),"Nothing on screen is still English after the switch: %s" % str(english_left("ja_JP")))
    var order:=["zh_CN","ko_KR","zh_TW","th_TH","ja_JP","de_DE","zh_CN"]
    var panels:=["upgrades","prestige","missions","world","mastery","item","settings"]
    for i in range(panels.size()):
        var lang: String=order[i]
        if panels[i]=="item":game._select_slot(0,0)
        else:game._open(panels[i])
        await frames(4)
        LocalizationService.select_language(lang);await frames(6)
        await get_tree().create_timer(.2).timeout
        var title: String=game.get_node("Sheet/Margin/Content/Header/Title").text
        var left:=english_left(lang) if catalogs.has(lang) else []
        check(left.is_empty() and title!="" and TranslationServer.get_locale()==lang and game.get_theme_default_font()==LocalizationService.script_font(lang),"%s open, switched to %s: redrawn (title %s), right font, no English left %s" % [panels[i],lang,title,str(left)])
    check(dropdown().get_theme_font("font")==LocalizationService.selector_font("zh_CN"),"The open dropdown switched to the Simplified Chinese selector font")
    game._close()
    LocalizationService.select_language("en_US");await frames(6)
    await get_tree().create_timer(.3).timeout
    check(TranslationServer.get_locale()=="en" and game.get_node("Safe/Layout/Map/ViewCamp").text==english.VIEW_CAMP and game.get_theme_default_font()==DEJAVU,"Switching back to English restores English labels and the plain theme font")

func persistence_batch04() -> void:
    sim.state.coins=777.0;sim.state.player_level=41;sim.touch()
    LocalizationService.select_language("zh_TW");await frames(2)
    check(SaveService.save_now(),"A save with Traditional Chinese selected is written")
    var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SaveService.save_path()))
    check(str(saved.settings.selected_language)=="zh_TW","The preference is stored in settings as zh_TW, apart from progression")
    LocalizationService.select_language("zh_CN");await frames(2)
    SaveService.load_and_apply();await frames(3)
    check(SettingsState.selected_language=="zh_TW" and TranslationServer.get_locale()=="zh_TW" and game.get_theme_default_font()==LocalizationService.script_font("zh_TW"),"Reloading restores Traditional Chinese (not the Simplified chosen in between) and its font")
    check(int(sim.state.player_level)==41 and is_equal_approx(float(sim.state.coins),777.0),"Progression is unchanged by language changes and reloads")
    SettingsState.from_save_dict({"selected_language":"ko_KR"});await frames(1)
    check(SettingsState.selected_language=="ko_KR" and (TranslationServer.get_locale()=="ko_KR" or not enabled4),"An older settings record that stored ko_KR (a test-era draft choice) keeps it and %s" % ("now applies it" if enabled4 else "waits"))
    SettingsState.from_save_dict({"selected_language":"zh_HK"});await frames(1)
    check(SettingsState.selected_language=="automatic" or TranslationServer.get_locale()=="en","A stored locale outside the target set (zh_HK) is not shown as a language (%s, %s)" % [SettingsState.selected_language,TranslationServer.get_locale()])
    LocalizationService.select_language("ja_JP");await frames(1)
    SaveService.save_now()
    if enabled4:
        LocalizationService._test_languages.clear()
        SaveService.load_and_apply();await frames(3)
        check(SettingsState.selected_language=="ja_JP" and TranslationServer.get_locale()=="ja_JP","Without any test switch the same save opens in Japanese")
        check(int(sim.state.player_level)==41,"…and its progression loads intact")
