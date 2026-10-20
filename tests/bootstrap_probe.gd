extends Node
## Always invoke with -- --probe --no-autosave. Never uses production state.

var failures: Array[String] = []
var sample_value: int = 0


func _ready() -> void:
    if not BootContext.is_probe or BootContext.profile_name == "production":
        push_error("BOOTSTRAP_PROBE: isolated profile required")
        get_tree().quit(1)
        return
    _check(NumberFormat.number(1250.0, 2) == "1.25K", "number formatting")
    _check(ProjectSettings.get_setting("display/window/handheld/orientation") == 1, "portrait enum")
    _check(LocalizationService.RELEASE_LANGUAGES.size() == 20, "language count")
    _check(LocalizationService.select_language("automatic"), "automatic allowed")
    _check(TranslationServer.get_locale().begins_with("en"), "automatic English")
    _check(not LocalizationService.select_language("es_ES"), "unvalidated locale blocked")
    _check(tr("BOOT_TAP") != "BOOT_TAP", "English catalog loaded")
    SaveService.register_section("probe", _snapshot, _restore, _reset)
    SaveService.hard_reset()
    sample_value = 7
    _check(SaveService.save_now(), "snapshot save")
    sample_value = 0
    SaveService.load_and_apply()
    _check(sample_value == 7, "snapshot restore")
    # Create a valid backup, then verify recovery from a damaged primary.
    sample_value = 8
    _check(SaveService.save_now(), "backup save")
    var file := FileAccess.open(SaveService.save_path(), FileAccess.WRITE)
    file.store_string("broken-json")
    file.close()
    SaveService.load_and_apply()
    _check(sample_value == 7 and SaveService.last_load_result == "backup", "backup recovery")
    SettingsState.set_music_volume(0.25)
    get_tree().paused = true
    _check(SaveService.hard_reset(), "paused reset")
    _check(not get_tree().paused and sample_value == 0, "reset resumes and clears state")
    _check(is_equal_approx(SettingsState.music_volume, 0.25), "reset preserves settings")
    SaveService.load_and_apply()
    _check(sample_value == 0, "reset survives reload")
    if failures.is_empty():
        print("BOOTSTRAP_PROBE PASS")
        get_tree().quit(0)
    else:
        for failure in failures:
            push_error("BOOTSTRAP_PROBE: " + failure)
        get_tree().quit(1)


func _snapshot() -> Dictionary:
    return {"sample": sample_value}


func _restore(data: Dictionary) -> void:
    sample_value = int(data.get("sample", 0))


func _reset() -> void:
    sample_value = 0


func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
