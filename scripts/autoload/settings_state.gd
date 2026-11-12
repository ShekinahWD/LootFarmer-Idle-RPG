extends Node
## Minimal cross-game player settings. Add game-specific preferences only when needed.

signal settings_changed()

const LOCALIZATION_SERVICE := preload("res://scripts/autoload/localization_service.gd")
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
var inventory_zoom: int = 2
## Change 41: where the movement joystick sits along the bottom of the map: 0 Left, 1 Center (default and
## the place every earlier profile had), 2 Right. Like every setting it survives Hard Reset.
var joystick_position: int = 1
## Change 71: how the main gear inventory is organised (presentation only, never item ownership). Category:
## 0 All, 1 Weapons, 2 Outfits, 3 Skills; sort: 0 Default (slot order), 1 Tier, 2 Evolution, 3 Quantity. Kept
## across panel close, travel, Prestige and relaunch; older saves load All / Default. Hard Reset returns both to
## All / Default (a fresh inventory must never start hidden behind an old category), see reset_inventory_view().
const INVENTORY_FILTERS := 4
const INVENTORY_SORTS := 4
var inventory_filter: int = 0
var inventory_sort: int = 0
## Change 71: the Supplies shop's purchase quantity, shared by every supply and remembered until the player
## changes it (x1 on older saves). 1..SUPPLY_BUY_MAX; the presets are x1, x5, x10, x25, any other value is Custom.
const SUPPLY_BUY_MAX := 999
var supply_buy_amount: int = 1

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
    inventory_zoom = 2
    joystick_position = 1
    inventory_filter = 0
    inventory_sort = 0
    supply_buy_amount = 1
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


func set_inventory_zoom(value: int) -> void:
    inventory_zoom = clampi(value,0,2)
    settings_changed.emit()
    SaveService.mark_dirty()


func set_joystick_position(value: int) -> void:
    joystick_position = clampi(value, 0, 2)
    settings_changed.emit()


## Change 71: one setter for the inventory organisation; emits (and so saves) only on a real change.
func set_inventory_view(filter: int, sort: int) -> void:
    var f := clampi(filter, 0, INVENTORY_FILTERS - 1)
    var s := clampi(sort, 0, INVENTORY_SORTS - 1)
    if f == inventory_filter and s == inventory_sort:
        return
    inventory_filter = f
    inventory_sort = s
    settings_changed.emit()


## Hard Reset starts the new profile on All / Default; the other settings survive it as before.
func reset_inventory_view() -> void:
    set_inventory_view(0, 0)


func set_supply_buy_amount(value: int) -> void:
    var amount := clampi(value, 1, SUPPLY_BUY_MAX)
    if amount == supply_buy_amount:
        return
    supply_buy_amount = amount
    settings_changed.emit()


func to_save_dict() -> Dictionary:
    return {
        "selected_language": selected_language,
        "camera_zoom": camera_zoom,
        "inventory_zoom": inventory_zoom,
        "joystick_position": joystick_position,
        "inventory_filter": inventory_filter,
        "inventory_sort": inventory_sort,
        "supply_buy_amount": supply_buy_amount,
        "sfx_volume": sfx_volume,
        "music_volume": music_volume,
        "mute_gameplay": mute_gameplay,
        "mute_special": mute_special,
        "selected_game_speed": selected_game_speed,
    }


func from_save_dict(data: Dictionary) -> void:
    selected_language = str(data.get("selected_language", "automatic"))
    # A target language survives the load (Change 40): LocalizationService applies it on settings_changed if this
    # build offers it and shows English otherwise, without rewriting the stored choice. Unknown values reset.
    if selected_language != "automatic" and selected_language not in LOCALIZATION_SERVICE.RELEASE_LANGUAGES:
        selected_language = "automatic"
    sfx_volume = clampf(float(data.get("sfx_volume", 1.0)), 0.0, 1.0)
    music_volume = clampf(float(data.get("music_volume", 1.0)), 0.0, 1.0)
    mute_gameplay = bool(data.get("mute_gameplay", false))
    mute_special = bool(data.get("mute_special", false))
    inventory_zoom = clampi(int(data.get("inventory_zoom",2)),0,2)
    # Saves before Change 41 have no joystick position: Center, where the joystick always was.
    var joystick = data.get("joystick_position", 1)
    joystick_position = clampi(int(joystick), 0, 2) if joystick is int or joystick is float else 1
    # Change 71: saves without these load the full, unsorted inventory and single purchases.
    inventory_filter = _int_setting(data.get("inventory_filter", 0), 0, INVENTORY_FILTERS - 1, 0)
    inventory_sort = _int_setting(data.get("inventory_sort", 0), 0, INVENTORY_SORTS - 1, 0)
    supply_buy_amount = _int_setting(data.get("supply_buy_amount", 1), 1, SUPPLY_BUY_MAX, 1)
    set_camera_zoom(float(data.get("camera_zoom", 2.0)))
    set_game_speed(float(data.get("selected_game_speed", 1.0)))
    settings_changed.emit()


## A saved integer setting: JSON numbers arrive as floats; anything else (or NaN) takes the default.
func _int_setting(value, low: int, high: int, fallback: int) -> int:
    if not (value is int or value is float) or (value is float and not is_finite(value)):
        return fallback
    return clampi(int(value), low, high)
