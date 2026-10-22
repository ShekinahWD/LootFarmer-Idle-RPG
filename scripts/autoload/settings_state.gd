extends Node
## Minimal cross-game player settings. Add game-specific preferences only when needed.

signal settings_changed()
signal game_speed_changed(new_speed: float)

var selected_language: String = "automatic"
## Audio (Change 12): two volumes (0 = silent) and two independent sound-effect categories. The
## sound-effect volume applies to both categories; each mute silences only its own category.
var sfx_volume: float = 1.0
var music_volume: float = 1.0
## Repeatable action, UI, combat and pickup sounds.
var mute_gameplay: bool = false
## Milestones and notifications (Prestige discovered/ready, followed step done, mission ready).
var mute_special: bool = false
var camera_zoom: float = 2.0

## Optional but useful for incremental/idle projects. If the game has no speed
## control, simply leave this at 1.0 and do not expose a UI for it.
const MIN_GAME_SPEED: float = 1.0
const MAX_GAME_SPEED: float = 3.0
var selected_game_speed: float = 1.0


func reset_to_defaults() -> void:
    selected_language = "automatic"
    sfx_volume = 1.0
    music_volume = 1.0
    mute_gameplay = false
    mute_special = false
    selected_game_speed = 1.0
    camera_zoom = 2.0
    Engine.time_scale = 1.0
    settings_changed.emit()
    game_speed_changed.emit(selected_game_speed)


func set_sfx_volume(value: float) -> void:
    sfx_volume = clampf(value, 0.0, 1.0)
    settings_changed.emit()


func set_music_volume(value: float) -> void:
    music_volume = clampf(value, 0.0, 1.0)
    settings_changed.emit()


func set_mute_gameplay(value: bool) -> void:
    mute_gameplay = value
    settings_changed.emit()


func set_mute_special(value: bool) -> void:
    mute_special = value
    settings_changed.emit()


## Silences every sound-effect category at once (headless probes use it).
func mute_all_sfx() -> void:
    mute_gameplay = true
    mute_special = true
    settings_changed.emit()


func set_game_speed(value: float) -> void:
    var clamped := clampf(value, MIN_GAME_SPEED, MAX_GAME_SPEED)
    var changed := not is_equal_approx(clamped, selected_game_speed)
    selected_game_speed = clamped
    Engine.time_scale = clamped
    if changed:
        settings_changed.emit()
        game_speed_changed.emit(clamped)


func set_camera_zoom(value: float) -> void:
    camera_zoom = clampf(value, 1.0, 3.0) if is_finite(value) else 2.0
    settings_changed.emit()


func to_save_dict() -> Dictionary:
    return {
        "selected_language": selected_language,
        "camera_zoom": camera_zoom,
        "sfx_volume": sfx_volume,
        "music_volume": music_volume,
        "mute_gameplay": mute_gameplay,
        "mute_special": mute_special,
        "selected_game_speed": selected_game_speed,
    }


func from_save_dict(data: Dictionary) -> void:
    selected_language = String(data.get("selected_language", "automatic"))
    if selected_language not in ["automatic", "en_US"]:
        selected_language = "automatic"
    sfx_volume = clampf(float(data.get("sfx_volume", 1.0)), 0.0, 1.0)
    music_volume = clampf(float(data.get("music_volume", 1.0)), 0.0, 1.0)
    mute_gameplay = bool(data.get("mute_gameplay", false))
    mute_special = bool(data.get("mute_special", false))
    set_camera_zoom(float(data.get("camera_zoom", 2.0)))
    set_game_speed(float(data.get("selected_game_speed", 1.0)))
    settings_changed.emit()
