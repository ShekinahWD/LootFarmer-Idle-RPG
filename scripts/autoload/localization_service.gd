extends Node
## English-first gate. Device language is deliberately ignored until release gate.

const RELEASE_LANGUAGES: Array[String] = [
    "en_US", "es_419", "es_ES", "pt_BR", "fr_FR", "de_DE", "it_IT", "nl_NL",
    "pl_PL", "ru_RU", "uk_UA", "tr_TR", "id_ID", "vi_VN", "th_TH", "hi_IN",
    "ja_JP", "ko_KR", "zh_CN", "zh_TW",
]
const TRANSLATIONS_RELEASE_READY: bool = false


func _ready() -> void:
    TranslationServer.set_locale("en")


func select_language(value: String) -> bool:
    if value != "automatic" and value != "en_US":
        return false
    SettingsState.selected_language = value
    SettingsState.settings_changed.emit()
    TranslationServer.set_locale("en")
    return true
