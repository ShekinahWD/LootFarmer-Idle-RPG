extends Node
## Versioned snapshots; isolated profiles, checked replacement and backup recovery.

signal saved()
signal save_failed(reason: String)

const SAVE_VERSION: int = 1
const DIRTY_SAVE_INTERVAL: float = 5.0
const PERIODIC_SAVE_INTERVAL: float = 120.0
var _providers: Dictionary = {}
var _loaded_sections: Dictionary = {}
var _dirty: bool = false
var write_blocked: bool = false
var last_load_result: String = "new"
var _dirty_timer: Timer
var _periodic_timer: Timer


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    load_and_apply()
    SettingsState.settings_changed.connect(mark_dirty)
    _dirty_timer = _timer(DIRTY_SAVE_INTERVAL, _flush_dirty)
    _periodic_timer = _timer(PERIODIC_SAVE_INTERVAL, _periodic_save)


func _timer(seconds: float, callback: Callable) -> Timer:
    var timer := Timer.new()
    timer.wait_time = seconds
    timer.autostart = true
    timer.timeout.connect(callback)
    add_child(timer)
    return timer


func save_path() -> String:
    return BootContext.save_directory() + "/save.json"


func register_section(key: String, snapshot: Callable, restore: Callable,
        reset: Callable = Callable()) -> void:
    _providers[key] = {"save": snapshot, "load": restore, "reset": reset}
    if _loaded_sections.get(key) is Dictionary and restore.is_valid():
        restore.call(_loaded_sections[key].duplicate(true))


func mark_dirty() -> void:
    _dirty = true


func _flush_dirty() -> void:
    if _dirty and BootContext.autosave_enabled:
        save_now()


func _periodic_save() -> void:
    if BootContext.autosave_enabled:
        save_now()


func _notification(what: int) -> void:
    if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED,
            NOTIFICATION_APPLICATION_FOCUS_OUT]:
        if is_node_ready() and BootContext.autosave_enabled:
            save_now()


func _read(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parser := JSON.new()
    if parser.parse(file.get_as_text()) != OK:
        return {}
    var value: Variant = parser.data
    if not value is Dictionary:
        return {}
    if not value.get("settings") is Dictionary or not value.get("sections") is Dictionary:
        return {}
    return value


func load_and_apply() -> void:
    var data := _read(save_path())
    write_blocked = false
    if int(data.get("version", 0)) > SAVE_VERSION:
        write_blocked = true
        last_load_result = "newer_version"
        return
    if int(data.get("version", -1)) != SAVE_VERSION:
        data = _read(save_path() + ".bak")
        if int(data.get("version", 0)) > SAVE_VERSION:
            write_blocked = true
            last_load_result = "newer_version"
            return
        last_load_result = "backup"
    else:
        last_load_result = "primary"
    if int(data.get("version", -1)) != SAVE_VERSION:
        _loaded_sections = {}
        SettingsState.reset_to_defaults()
        # Preserve unreadable files until a deliberate Hard Reset, not an autosave.
        write_blocked = FileAccess.file_exists(save_path()) or FileAccess.file_exists(save_path() + ".bak")
        last_load_result = "invalid" if write_blocked else "new"
        return
    SettingsState.from_save_dict(data["settings"])
    _loaded_sections = data["sections"].duplicate(true)
    for key in _providers:
        if _loaded_sections.get(key) is Dictionary:
            var restore: Callable = _providers[key]["load"]
            if restore.is_valid():
                restore.call(_loaded_sections[key].duplicate(true))


func save_now() -> bool:
    if write_blocked:
        return _fail("save_read_only")
    var directory := ProjectSettings.globalize_path(BootContext.save_directory())
    if DirAccess.make_dir_recursive_absolute(directory) != OK:
        return _fail("directory")
    var sections := _loaded_sections.duplicate(true)
    for key in _providers:
        var snapshot: Callable = _providers[key]["save"]
        if snapshot.is_valid():
            sections[key] = snapshot.call()
    var data := {"version": SAVE_VERSION, "settings": SettingsState.to_save_dict(),
        "sections": sections, "last_seen_unix": int(Time.get_unix_time_from_system())}
    var path := ProjectSettings.globalize_path(save_path())
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return _fail("open")
    file.store_string(JSON.stringify(data))
    file.flush()
    var result := file.get_error()
    file.close()
    if result != OK or _read(temporary).is_empty():
        return _fail("write")
    # Do not replace a good backup with an invalid primary after recovery.
    if int(_read(path).get("version", -1)) == SAVE_VERSION:
        if DirAccess.copy_absolute(path, path + ".bak") != OK:
            return _fail("backup")
    if DirAccess.rename_absolute(temporary, path) != OK:
        return _fail("replace")
    _loaded_sections = sections
    _dirty = false
    saved.emit()
    return true


func _fail(reason: String) -> bool:
    push_warning("SaveService: " + reason)
    save_failed.emit(reason)
    return false


func hard_reset() -> bool:
    # Confirmation is owned by the calling UI. Settings intentionally survive.
    write_blocked = false
    _loaded_sections = {}
    for key in _providers:
        var reset: Callable = _providers[key]["reset"]
        if reset.is_valid():
            reset.call()
    get_tree().paused = false
    Engine.time_scale = 1.0
    if not save_now():
        return false
    # Make recovery agree with reset instead of resurrecting previous progression.
    var path := ProjectSettings.globalize_path(save_path())
    if DirAccess.copy_absolute(path, path + ".bak") != OK:
        return _fail("reset_backup")
    return true
