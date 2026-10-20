extends Node
## Minimal cross-game player settings. Add game-specific preferences only when needed.

signal settings_changed()
signal game_speed_changed(new_speed: float)

var selected_language: String = "automatic"
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var sfx_enabled: bool = true
var music_enabled: bool = true
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
    sfx_enabled = true
    music_enabled = true
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


func set_sfx_enabled(value: bool) -> void:
    sfx_enabled = value
    settings_changed.emit()


func set_music_enabled(value: bool) -> void:
    music_enabled = value
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
        "sfx_enabled": sfx_enabled,
        "music_enabled": music_enabled,
        "selected_game_speed": selected_game_speed,
    }


func from_save_dict(data: Dictionary) -> void:
    selected_language = String(data.get("selected_language", "automatic"))
    if selected_language not in ["automatic", "en_US"]:
        selected_language = "automatic"
    sfx_volume = clampf(float(data.get("sfx_volume", 1.0)), 0.0, 1.0)
    music_volume = clampf(float(data.get("music_volume", 1.0)), 0.0, 1.0)
    sfx_enabled = bool(data.get("sfx_enabled", true))
    music_enabled = bool(data.get("music_enabled", true))
    set_camera_zoom(float(data.get("camera_zoom", 2.0)))
    set_game_speed(float(data.get("selected_game_speed", 1.0)))
    settings_changed.emit()
