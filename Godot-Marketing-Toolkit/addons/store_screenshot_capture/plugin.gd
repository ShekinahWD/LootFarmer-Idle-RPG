@tool
extends EditorPlugin

const AUTOLOAD_NAME := "StoreScreenshotCapture"
const AUTOLOAD_PATH := "res://addons/store_screenshot_capture/runtime_capture.gd"
const DOCK_SCRIPT := preload("res://addons/store_screenshot_capture/editor_dock.gd")

var _dock: EditorDock
var _dock_content: Control


func _enable_plugin() -> void:
	if not ProjectSettings.has_setting("autoload/%s" % AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _disable_plugin() -> void:
	if ProjectSettings.has_setting("autoload/%s" % AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)


func _enter_tree() -> void:
	_ensure_project_defaults()
	_dock = EditorDock.new()
	_dock.title = "Store Capture"
	_dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	_dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING
	_dock_content = DOCK_SCRIPT.new()
	_dock.add_child(_dock_content)
	add_dock(_dock)


func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_dock(_dock)
		_dock.queue_free()
	_dock = null
	_dock_content = null


func _ensure_project_defaults() -> void:
	_set_default("store_screenshot_capture/output_root", "res://store_assets/screenshots")
	_set_default("store_screenshot_capture/ui_group", "store_screenshot_ui")
	_set_default("store_screenshot_capture/default_orientation", "landscape")
	_set_default("store_screenshot_capture/capture_ui_default", true)
	_set_default("store_screenshot_capture/settle_frames", 3)
	_set_default("store_screenshot_capture/phone_landscape", Vector2i(1920, 1080))
	_set_default("store_screenshot_capture/tablet_7_landscape", Vector2i(1920, 1080))
	_set_default("store_screenshot_capture/tablet_10_landscape", Vector2i(2560, 1440))
	_set_default("store_screenshot_capture/desktop_landscape", Vector2i(2560, 1440))
	ProjectSettings.save()


func _set_default(key: String, value: Variant) -> void:
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, value)
