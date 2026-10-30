extends Node
## Progressive activation (Change 40, Playbook 132.5): each locale has its own readiness. A locale in
## ENABLED_LANGUAGES has passed its batch validation and was approved for players: its catalog ships (the export
## manifest enumerates this list), Settings offers it and Automatic may choose it. Every other target locale is
## absent from player builds; probes and captures can still load a validated test batch (TEST_BATCHES).

signal language_applied(godot_locale: String)

## The approved target set (Playbook 132.1), in Settings order. Not a statement that every one is ready.
const RELEASE_LANGUAGES: Array[String] = [
    "en_US", "es_419", "es_ES", "pt_BR", "fr_FR", "de_DE", "it_IT", "nl_NL",
    "pl_PL", "ru_RU", "uk_UA", "tr_TR", "id_ID", "vi_VN", "th_TH", "hi_IN",
    "ja_JP", "ko_KR", "zh_CN", "zh_TW",
]
## Per-locale readiness, the one list a player build reads: English, Batch 01 (Change 38), Batch 02 (Change 39),
## Batch 03 (Change 42) and Batch 04 (Change 43): all 20 target languages.
## Add a locale here only after its batch passed and the developer approved it; keep it on one line
## (tools/export_manifest.py and tools/validate_localization.py read it).
const ENABLED_LANGUAGES: Array[String] = ["en_US", "es_419", "es_ES", "pt_BR", "fr_FR", "de_DE", "it_IT", "nl_NL", "pl_PL", "ru_RU", "uk_UA", "tr_TR", "id_ID", "vi_VN", "th_TH", "hi_IN", "ja_JP", "ko_KR", "zh_CN", "zh_TW"]
## The final 20-language QA gate (132.5 step 5) is separate from enabling validated locales: it certifies the
## whole set together and stays false while any target locale is missing from ENABLED_LANGUAGES. All 20 are enabled
## since Change 43, but the gate also needs the Playbook 132.6 real-device matrix, which has not been run yet.
const ALL_LANGUAGES_CERTIFIED: bool = false
## Validated batches a probe or capture may load by name (--test-languages=batch01). An enabled batch changes
## nothing; a batch under validation is added here first (Batch 04, Change 43).
const TEST_BATCHES: Dictionary = {
    "batch01": ["es_419", "es_ES", "pt_BR", "fr_FR", "de_DE"],
    "batch02": ["it_IT", "nl_NL", "pl_PL", "ru_RU", "uk_UA"],
    "batch03": ["tr_TR", "id_ID", "vi_VN", "th_TH", "hi_IN"],
    "batch04": ["ja_JP", "ko_KR", "zh_CN", "zh_TW"],
}
## Settings language id -> the locale Godot 4.7 resolves. Godot folds es_419 into generic "es", so "es"
## serves Latin America while es_ES stays Spain (Playbook 132.6).
const GODOT_LOCALES: Dictionary = {
    "en_US": "en", "es_419": "es", "es_ES": "es_ES", "pt_BR": "pt_BR", "fr_FR": "fr_FR", "de_DE": "de_DE",
    "it_IT": "it_IT", "nl_NL": "nl_NL", "pl_PL": "pl_PL", "ru_RU": "ru_RU", "uk_UA": "uk_UA",
    "tr_TR": "tr_TR", "id_ID": "id_ID", "vi_VN": "vi_VN", "th_TH": "th_TH", "hi_IN": "hi_IN",
    "ja_JP": "ja_JP", "ko_KR": "ko_KR", "zh_CN": "zh_CN", "zh_TW": "zh_TW",
}
## Each language's own name in its own language and script. These are proper names: never translated, the same
## whatever the current locale.
const NATIVE_NAMES: Dictionary = {
    "en_US": "English", "es_419": "Español (Latinoamérica)", "es_ES": "Español (España)",
    "pt_BR": "Português (Brasil)", "fr_FR": "Français", "de_DE": "Deutsch", "it_IT": "Italiano",
    "nl_NL": "Nederlands", "pl_PL": "Polski", "ru_RU": "Русский", "uk_UA": "Українська",
    "tr_TR": "Türkçe", "id_ID": "Bahasa Indonesia", "vi_VN": "Tiếng Việt", "th_TH": "ไทย", "hi_IN": "हिन्दी",
    "ja_JP": "日本語", "ko_KR": "한국어", "zh_CN": "简体中文", "zh_TW": "繁體中文",
}
## Device language codes older Android versions still report (java.util.Locale legacy codes).
const LEGACY_LANGUAGE_CODES: Dictionary = {"in": "id", "iw": "he", "ji": "yi"}
const CATALOG_PATH := "res://localization/%s.po"
## The theme font (DejaVu Sans) has no Thai or Devanagari. Those locales draw with the theme font plus an OFL Noto
## fallback (Change 42); every other locale keeps the plain theme font, because Godot sizes a line by the tallest
## font in the chain and the taller Noto metrics would otherwise change every Latin and Cyrillic layout.
## Japanese, Korean and both Chinese locales (Change 43) put their own regional Noto Sans face first and DejaVu
## second: kana, Hangul, Han and full-width punctuation take that region's glyph forms, Latin letters and digits
## keep DejaVu's. The faces are catalog subsets built by tools/build_cjk_fonts.py.
const SCRIPT_FONTS: Dictionary = {
    "th_TH": preload("res://resources/game/ui_font_thai.tres"),
    "hi_IN": preload("res://resources/game/ui_font_devanagari.tres"),
    "ja_JP": preload("res://resources/game/ui_font_japanese.tres"),
    "ko_KR": preload("res://resources/game/ui_font_korean.tres"),
    "zh_CN": preload("res://resources/game/ui_font_chinese_simplified.tres"),
    "zh_TW": preload("res://resources/game/ui_font_chinese_traditional.tres"),
}
## The language dropdown: every language name in its own script (the endonym fonts keep 日本語, 简体中文 and 繁體中文
## in their own regional forms in any locale), plus the current locale's face for "Automatic" in a CJK locale.
const ALL_SCRIPTS_FONT: FontVariation = preload("res://resources/game/ui_font_all_scripts.tres")

## Probes and captures: locales of a test batch that are not enabled for players (none once every batch is enabled).
var _test_languages: Array[String] = []
## Dropdown fonts per CJK locale, built on first use.
var _selector_fonts: Dictionary = {}
## Locales whose catalog is registered with the TranslationServer (loaded on first use, not at startup).
var _loaded: Array[String] = ["en_US"]
## Probes only: a locale pinned regardless of the preference (the pseudo-locale sweep).
var _test_locale := ""
## Probes only: a device locale standing in for OS.get_locale() (Automatic tests).
var _test_device_locale := ""
## The theme's own default font, restored for every locale without a script fallback.
var _theme: Theme = preload("res://resources/game/theme.tres")
var _theme_font: Font = _theme.default_font


func _ready() -> void:
    TranslationServer.set_locale("en")
    # --test-languages=batch01,batch02 loads several validated batches at once.
    for batch in BootContext.test_languages.split(",", false):
        enable_test_batch(batch.strip_edges())
    # Saves load before this autoload is ready; later loads and resets announce settings_changed.
    SettingsState.settings_changed.connect(apply_language)
    apply_language()


## Probes and captures only: makes a validated batch's locales selectable (an enabled locale needs nothing).
func enable_test_batch(batch: String) -> bool:
    if not BootContext.is_probe or not TEST_BATCHES.has(batch):
        return false
    for language in TEST_BATCHES[batch]:
        if language in ENABLED_LANGUAGES or language in _test_languages:
            continue
        if not _load_catalog(language):
            return false
        _test_languages.append(language)
    return true


## Probes only: pins a Godot locale (empty restores the preference). Returns false outside probes.
func set_test_locale(locale: String) -> bool:
    if not BootContext.is_probe:
        return false
    _test_locale = locale
    apply_language()
    return true


## Probes only: simulates the device language Automatic reads (empty restores OS.get_locale()).
func set_test_device_locale(locale: String) -> bool:
    if not BootContext.is_probe:
        return false
    _test_device_locale = locale
    apply_language()
    return true


## Languages a player can pick now, in Settings order: the enabled locales (plus a probe's test batch).
func available_languages() -> Array[String]:
    var languages: Array[String] = []
    for language in RELEASE_LANGUAGES:
        if language in ENABLED_LANGUAGES or language in _test_languages:
            languages.append(language)
    return languages


func is_selectable(value: String) -> bool:
    return value == "automatic" or value in available_languages()


func select_language(value: String) -> bool:
    if not is_selectable(value):
        return false
    SettingsState.selected_language = value
    SettingsState.settings_changed.emit()
    return true


func device_locale() -> String:
    return _test_device_locale if _test_device_locale != "" else OS.get_locale()


## The closest available language for a device locale ("es_MX", "pt-PT", "zh_Hant_TW", "ru_RU.UTF-8"), else
## English. Exact language and region first; then the variant rules; then any available locale of the language.
static func match_device_locale(device: String, available: Array) -> String:
    var tags := device.replace("-", "_").get_slice(".", 0).get_slice("@", 0).split("_", false)
    if tags.is_empty():
        return "en_US"
    var language: String = tags[0].to_lower()
    language = LEGACY_LANGUAGE_CODES.get(language, language)
    var script := ""
    var region := ""
    # Java's Locale.toString() writes the script last with a '#' (zh_TW_#Hant), BCP 47 before the region.
    for raw in tags.slice(1):
        var tag: String = raw.trim_prefix("#")
        if tag.length() == 4 and script == "" and not tag.is_valid_int():
            script = tag.capitalize()
        elif region == "":
            region = tag.to_upper()
    # Chinese is chosen by script before region (Change 43): zh_Hant_CN is Traditional text, zh_Hans_HK Simplified.
    if region != "" and (language + "_" + region) in available and not (language == "zh" and script != ""):
        return language + "_" + region
    var preferred := ""
    match language:
        # Spain is es_ES; every other Spanish (es_419, es_MX, es_US, generic es) reads Latin American Spanish.
        "es": preferred = "es_ES" if region == "ES" else "es_419"
        # A script tag decides (Hant Traditional, Hans Simplified); without one, Taiwan, Hong Kong and Macao read
        # Traditional and every other Chinese (CN, SG, generic zh) Simplified: the documented generic-zh fallback.
        "zh":
            if script == "Hant" or (script == "" and region in ["TW", "HK", "MO"]):
                preferred = "zh_TW"
            else:
                preferred = "zh_CN"
    if preferred in available:
        return preferred
    for candidate in available:
        if str(candidate).get_slice("_", 0) == language:
            return candidate
    return "en_US"


## The language a preference shows: Automatic's best match for the device, the choice itself, or English for
## a stored choice that is not available in this build (the stored preference is kept as it is).
func resolved_language(value: String) -> String:
    if value == "automatic":
        return match_device_locale(device_locale(), available_languages())
    return value if is_selectable(value) else "en_US"


func godot_locale(value: String) -> String:
    if _test_locale != "":
        return _test_locale
    return GODOT_LOCALES.get(resolved_language(value), "en")


## Applies the saved preference. A stored language this build does not offer shows English but stays stored,
## so it applies again once that language is enabled.
func apply_language() -> void:
    var language := resolved_language(SettingsState.selected_language)
    if _test_locale == "" and not _load_catalog(language):
        language = "en_US"
    var locale: String = _test_locale if _test_locale != "" else GODOT_LOCALES.get(language, "en")
    var font: Font = SCRIPT_FONTS.get(language, _theme_font)
    if _theme.default_font != font:
        _theme.default_font = font
    if TranslationServer.get_locale() != locale:
        TranslationServer.set_locale(locale)
        language_applied.emit(locale)


## The font a language draws with: the theme font, or its script chain (Thai, Devanagari, Japanese, Korean, Chinese).
func script_font(language: String) -> Font:
    return SCRIPT_FONTS.get(language, _theme_font)


## The dropdown's font for a language: the all-scripts chain, with a CJK locale's own face last so the translated
## "Automatic" draws in that locale's glyph forms (the endonym faces hold no character of those words).
func selector_font(language: String) -> Font:
    if not language in ["ja_JP", "ko_KR", "zh_CN", "zh_TW"]:
        return ALL_SCRIPTS_FONT
    if not _selector_fonts.has(language):
        var font := FontVariation.new()
        font.base_font = ALL_SCRIPTS_FONT.base_font
        var chain: Array[Font] = ALL_SCRIPTS_FONT.fallbacks.duplicate()
        chain.append(SCRIPT_FONTS[language].base_font)
        font.fallbacks = chain
        _selector_fonts[language] = font
    return _selector_fonts[language]


## Registers a catalog the first time its locale is used. English ships in project.godot.
func _load_catalog(language: String) -> bool:
    if language in _loaded:
        return true
    var translation: Translation = load(CATALOG_PATH % language)
    if translation == null:
        push_error("Missing language catalog " + language)
        return false
    TranslationServer.add_translation(translation)
    _loaded.append(language)
    return true
