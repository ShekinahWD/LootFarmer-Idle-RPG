extends Node
## English-first gate. Device language is deliberately ignored until release gate.
## Localization Batch 01: completed catalogs can be unlocked for probes and captures only
## (BootContext.test_languages, or enable_test_batch() from a probe); normal players keep English.

signal language_applied(godot_locale: String)

const RELEASE_LANGUAGES: Array[String] = [
    "en_US", "es_419", "es_ES", "pt_BR", "fr_FR", "de_DE", "it_IT", "nl_NL",
    "pl_PL", "ru_RU", "uk_UA", "tr_TR", "id_ID", "vi_VN", "th_TH", "hi_IN",
    "ja_JP", "ko_KR", "zh_CN", "zh_TW",
]
const TRANSLATIONS_RELEASE_READY: bool = false
## Validated batches (Playbook 132.5), in order. A batch is test-only until the global 20-language gate.
const TEST_BATCHES: Dictionary = {
    "batch01": ["es_419", "es_ES", "pt_BR", "fr_FR", "de_DE"],
}
## Settings language id -> the locale Godot 4.7 resolves. Godot folds es_419 into generic "es", so "es"
## serves Latin America (and es_MX, es_AR, ...) while es_ES stays Spain (Playbook 132.6).
const GODOT_LOCALES: Dictionary = {
    "en_US": "en", "es_419": "es", "es_ES": "es_ES", "pt_BR": "pt_BR", "fr_FR": "fr_FR", "de_DE": "de_DE",
}
const CATALOG_PATH := "res://localization/%s.po"

var _test_languages: Array[String] = []
## Probes only: a locale pinned regardless of the preference (the pseudo-locale sweep).
var _test_locale := ""


func _ready() -> void:
    TranslationServer.set_locale("en")
    if BootContext.test_languages != "":
        enable_test_batch(BootContext.test_languages)
    # Saves load before this autoload is ready; later loads and resets announce settings_changed.
    SettingsState.settings_changed.connect(apply_language)
    apply_language()


## Probes and captures only: registers a validated batch's catalogs and makes them selectable.
func enable_test_batch(batch: String) -> bool:
    if not BootContext.is_probe or not TEST_BATCHES.has(batch):
        return false
    for language in TEST_BATCHES[batch]:
        if language in _test_languages:
            continue
        var translation: Translation = load(CATALOG_PATH % language)
        if translation == null:
            push_error("Missing test catalog " + language)
            return false
        TranslationServer.add_translation(translation)
        _test_languages.append(language)
    return true


## Probes only: pins a Godot locale (empty restores the preference). Returns false outside probes.
func set_test_locale(locale: String) -> bool:
    if not BootContext.is_probe:
        return false
    _test_locale = locale
    apply_language()
    return true


## Languages a player can pick now: English until the translations pass the release gate.
func available_languages() -> Array[String]:
    if TRANSLATIONS_RELEASE_READY:
        return RELEASE_LANGUAGES.duplicate()
    var languages: Array[String] = ["en_US"]
    for language in RELEASE_LANGUAGES:
        if language in _test_languages:
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


## Automatic stays English until the global gate enables device detection (Playbook 132.2).
func godot_locale(value: String) -> String:
    if _test_locale != "":
        return _test_locale
    if value == "automatic" or not is_selectable(value):
        return "en"
    return GODOT_LOCALES.get(value, "en")


## Applies the saved preference; one that is not selectable now falls back to Automatic.
func apply_language() -> void:
    if not is_selectable(SettingsState.selected_language):
        SettingsState.selected_language = "automatic"
    var locale := godot_locale(SettingsState.selected_language)
    if TranslationServer.get_locale() != locale:
        TranslationServer.set_locale(locale)
        language_applied.emit(locale)
