extends Node
## Versioned snapshots; isolated profiles, checked replacement and backup recovery.
## Change 24 (Playbook 30): saves are coalesced in two tiers. Ordinary progress (kills, loot, XP,
## exploration: mark_dirty) is written at most ORDINARY_SAVE_DELAY seconds after its first unsaved
## change; a committed player action (a purchase, an inventory or settings change: mark_committed)
## is written COMMITTED_SAVE_DELAY seconds later, so a burst of taps costs one write. Transactions
## that must never roll back (travel, claims, Prestige, Hard Reset) and backgrounding or quitting
## still call save_now() at once. A write is verified by size and digest, not by parsing it back.

signal saved()
signal save_failed(reason: String)

## Version 3 (Change 24): explored fog cells are stored as compact per-stage masks. Development
## profiles of earlier versions start fresh (Playbook 61.1); there is no migration.
const SAVE_VERSION: int = 3
## Longest rollback window of ordinary progress after a crash or force-stop without a pause notice.
const ORDINARY_SAVE_DELAY: float = 30.0
const COMMITTED_SAVE_DELAY: float = 1.0
const PERIODIC_SAVE_INTERVAL: float = 120.0
var _providers: Dictionary = {}
var _loaded_sections: Dictionary = {}
var _dirty: bool = false
var _dirty_since: float = -1.0
var _commit_at: float = -1.0
var write_blocked: bool = false
var last_load_result: String = "new"
var _periodic_timer: Timer
## The primary file on disk is a valid current-version save (loaded from it, or written by us), and
## its byte length; only then may it replace the backup. Kept in memory: the old primary is never
## parsed again before a save.
var _primary_valid: bool = false
var _primary_bytes: int = -1


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    load_and_apply()
    SettingsState.settings_changed.connect(mark_committed)
    _periodic_timer = Timer.new()
    _periodic_timer.wait_time = PERIODIC_SAVE_INTERVAL
    _periodic_timer.autostart = true
    _periodic_timer.timeout.connect(_periodic_save)
    add_child(_periodic_timer)


func save_path() -> String:
    return BootContext.save_directory() + "/save.json"


func register_section(key: String, snapshot: Callable, restore: Callable,
        reset: Callable = Callable()) -> void:
    _providers[key] = {"save": snapshot, "load": restore, "reset": reset}
    if _loaded_sections.get(key) is Dictionary and restore.is_valid():
        restore.call(_loaded_sections[key].duplicate(true))


## Ordinary progress: written within ORDINARY_SAVE_DELAY seconds. Repeated marks do not postpone it.
func mark_dirty() -> void:
    if not _dirty:
        _dirty = true
        _dirty_since = _now()


## A committed player action: written within COMMITTED_SAVE_DELAY seconds (bursts coalesce).
func mark_committed() -> void:
    mark_dirty()
    if _commit_at < 0.0:
        _commit_at = _now() + COMMITTED_SAVE_DELAY


func _now() -> float:
    return Time.get_ticks_msec() / 1000.0


func _process(_delta: float) -> void:
    if not _dirty or not BootContext.autosave_enabled:
        return
    var now := _now()
    if (_commit_at >= 0.0 and now >= _commit_at) or now - _dirty_since >= ORDINARY_SAVE_DELAY:
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
    _primary_valid = int(data.get("version", -1)) == SAVE_VERSION
    _primary_bytes = _file_length(ProjectSettings.globalize_path(save_path())) if _primary_valid else -1
    if not _primary_valid:
        var backup:=_read(save_path()+".bak")
        if int(backup.get("version",-1))==SAVE_VERSION:
            data=backup;last_load_result="backup"
        else:
            # Development-only policy: obsolete or unreadable profiles start fresh.
            _loaded_sections={}
            if data.get("settings") is Dictionary:SettingsState.from_save_dict(data.settings)
            last_load_result="development_reset" if FileAccess.file_exists(save_path()) else "new"
            mark_dirty()
            return
    else:last_load_result="primary"
    SettingsState.from_save_dict(data["settings"])
    _loaded_sections = data["sections"]
    for key in _providers:
        if _loaded_sections.get(key) is Dictionary:
            var restore: Callable = _providers[key]["load"]
            if restore.is_valid():
                restore.call(_loaded_sections[key].duplicate(true))


func _file_length(path: String) -> int:
    var file := FileAccess.open(path, FileAccess.READ)
    return -1 if file == null else int(file.get_length())


func save_now() -> bool:
    if write_blocked:
        return _fail("save_read_only")
    var directory := ProjectSettings.globalize_path(BootContext.save_directory())
    if DirAccess.make_dir_recursive_absolute(directory) != OK:
        return _fail("directory")
    # Sections without a live provider are kept exactly as loaded; providers serialize their own
    # state directly (no whole-profile copy).
    var sections := {}
    for key in _loaded_sections:
        if not _providers.has(key):
            sections[key] = _loaded_sections[key]
    for key in _providers:
        var snapshot: Callable = _providers[key]["save"]
        if snapshot.is_valid():
            sections[key] = snapshot.call()
    var data := {"version": SAVE_VERSION, "settings": SettingsState.to_save_dict(),
        "sections": sections, "last_seen_unix": int(Time.get_unix_time_from_system())}
    var bytes := JSON.stringify(data).to_utf8_buffer()
    var path := ProjectSettings.globalize_path(save_path())
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return _fail("open")
    file.store_buffer(bytes)
    file.flush()
    var result := file.get_error()
    file.close()
    # The temporary file must hold exactly the serialized bytes: same length and same digest.
    if result != OK or _file_length(temporary) != bytes.size() or FileAccess.get_md5(temporary) != _md5(bytes):
        return _fail("write")
    # Do not replace a good backup with an invalid primary after recovery (or one changed on disk).
    if _primary_valid and _file_length(path) == _primary_bytes:
        if DirAccess.copy_absolute(path, path + ".bak") != OK:
            return _fail("backup")
    if DirAccess.rename_absolute(temporary, path) != OK:
        return _fail("replace")
    _primary_valid = true
    _primary_bytes = bytes.size()
    for key in _providers:
        _loaded_sections.erase(key)
    _dirty = false
    _dirty_since = -1.0
    _commit_at = -1.0
    saved.emit()
    return true


func _md5(bytes: PackedByteArray) -> String:
    var context := HashingContext.new()
    context.start(HashingContext.HASH_MD5)
    context.update(bytes)
    return context.finish().hex_encode()


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
