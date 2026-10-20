extends Control
## Editable bootstrap utility only. No gameplay or final-art certification.

@export var safe_padding: int = 28
@onready var content: VBoxContainer = $SafeArea/Scroll/Content
@onready var reset_confirm: ConfirmationDialog = $ResetConfirm
var touch_count: int = 0


func _ready() -> void:
    SaveService.register_section("bootstrap", _snapshot, _restore, _reset_progress)
    content.get_node("Version").text = tr("BOOT_VERSION") % ProjectSettings.get_setting("application/config/version")
    content.get_node("Tap").pressed.connect(_tap)
    content.get_node("Pause").pressed.connect(_pause)
    content.get_node("Reset").pressed.connect(func() -> void: reset_confirm.popup_centered())
    reset_confirm.confirmed.connect(_confirm_reset)
    SaveService.saved.connect(_saved)
    SaveService.save_failed.connect(_save_failed)
    content.get_node("Languages/automatic").pressed.connect(func() -> void: _language("automatic"))
    content.get_node("Languages/en_US").pressed.connect(func() -> void: _language("en_US"))
    get_viewport().size_changed.connect(_update_safe_area)
    _update_safe_area()
    _refresh()
    if SaveService.write_blocked:
        content.get_node("Status").text = tr("BOOT_SAVE_READONLY")


func _snapshot() -> Dictionary:
    return {"touch_count": touch_count}


func _restore(data: Dictionary) -> void:
    touch_count = maxi(0, int(data.get("touch_count", 0)))
    if is_node_ready():
        _refresh()


func _reset_progress() -> void:
    touch_count = 0


func _tap() -> void:
    touch_count += 1
    SaveService.mark_dirty()
    SaveService.save_now()
    _refresh()


func _language(value: String) -> void:
    LocalizationService.select_language(value)
    SaveService.save_now()


func _pause() -> void:
    get_tree().paused = not get_tree().paused
    _refresh()


func _confirm_reset() -> void:
    SaveService.hard_reset()
    _refresh()


func _saved() -> void:
    content.get_node("Status").text = tr("BOOT_SAVED")


func _save_failed(_reason: String) -> void:
    content.get_node("Status").text = tr("BOOT_SAVE_ERROR")


func _refresh() -> void:
    content.get_node("Count").text = tr("BOOT_TAPS") % touch_count
    content.get_node("Pause").text = tr("BOOT_RESUME") if get_tree().paused else tr("BOOT_PAUSE")


func _update_safe_area() -> void:
    var insets := LayoutService.get_safe_area_insets_canvas()
    var safe_area: MarginContainer = $SafeArea
    safe_area.add_theme_constant_override("margin_left", safe_padding + ceili(insets.x))
    safe_area.add_theme_constant_override("margin_top", safe_padding + ceili(insets.y))
    safe_area.add_theme_constant_override("margin_right", safe_padding + ceili(insets.z))
    safe_area.add_theme_constant_override("margin_bottom", safe_padding + ceili(insets.w))
