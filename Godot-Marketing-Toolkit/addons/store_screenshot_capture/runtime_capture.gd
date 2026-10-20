extends Node

## Shared with the Marketing Capture runner: window sizing, settle and
## readback, UI-group hiding, safe PNG writes.
const Capture := preload("res://addons/store_screenshot_capture/viewport_capture.gd")

const TARGETS := [
	{"key": "phone", "label": "Phone", "filename_prefix": "Phone"},
	{"key": "tablet_7", "label": "7-inch tablet", "filename_prefix": "Tablet_7"},
	{"key": "tablet_10", "label": "10-inch tablet", "filename_prefix": "Tablet_10"},
	{"key": "desktop", "label": "Desktop", "filename_prefix": "Desktop"},
]

var _overlay_layer: CanvasLayer
var _panel: PanelContainer
var _orientation: OptionButton
var _capture_ui: CheckBox
var _target_checks: Dictionary = {}
var _shot_number: SpinBox
var _label_edit: LineEdit
var _status: Label
var _capture_button: Button
var _original_window_size := Vector2i.ZERO
var _original_window_mode := DisplayServer.WINDOW_MODE_WINDOWED
var _original_max_size := Vector2i.ZERO
var _capture_in_progress := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _is_editor_runtime():
		set_process(false)
		set_process_unhandled_key_input(false)
		return
	_build_runtime_overlay()
	_call_scan_next_shot()


func _is_editor_runtime() -> bool:
	# `debug` is also true for exported debug templates (including Android).
	# `editor_runtime` is specifically the project process launched from Godot Editor.
	return OS.has_feature("editor_runtime") and not OS.has_feature("template")


func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_editor_runtime() or not is_instance_valid(_panel):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()


func _build_runtime_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 4095
	_overlay_layer.name = "StoreScreenshotCaptureOverlay"
	add_child(_overlay_layer)

	_panel = PanelContainer.new()
	_panel.name = "CapturePanel"
	_panel.position = Vector2(24, 80)
	_panel.custom_minimum_size = Vector2(360, 0)
	_overlay_layer.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)

	var title := Label.new()
	title.text = "STORE SCREENSHOT CAPTURE"
	title.add_theme_font_size_override("font_size", 18)
	body.add_child(title)

	var shot_row := HBoxContainer.new()
	var shot_label := Label.new()
	shot_label.text = "Shot #"
	shot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shot_row.add_child(shot_label)
	_shot_number = SpinBox.new()
	_shot_number.min_value = 1
	_shot_number.max_value = 999
	_shot_number.step = 1
	_shot_number.value = 1
	shot_row.add_child(_shot_number)
	body.add_child(shot_row)

	_label_edit = LineEdit.new()
	_label_edit.placeholder_text = "Optional filename override, e.g. PrestigeChoice"
	body.add_child(_label_edit)

	_orientation = OptionButton.new()
	_orientation.add_item("Landscape 16:9")
	_orientation.add_item("Portrait 9:16")
	var default_orientation := str(ProjectSettings.get_setting("store_screenshot_capture/default_orientation", "landscape"))
	_orientation.select(1 if default_orientation == "portrait" else 0)
	body.add_child(_orientation)

	var targets_title := Label.new()
	targets_title.text = "Targets"
	body.add_child(targets_title)
	for target in TARGETS:
		var check := CheckBox.new()
		check.text = target["label"]
		check.button_pressed = true
		_target_checks[target["key"]] = check
		body.add_child(check)

	_capture_ui = CheckBox.new()
	_capture_ui.text = "Capture UI"
	_capture_ui.button_pressed = bool(ProjectSettings.get_setting("store_screenshot_capture/capture_ui_default", true))
	body.add_child(_capture_ui)

	_capture_button = Button.new()
	_capture_button.text = "CAPTURE SELECTED"
	_capture_button.pressed.connect(_on_capture_pressed)
	body.add_child(_capture_button)

	var scan_button := Button.new()
	scan_button.text = "Find Next Shot Number"
	scan_button.pressed.connect(_call_scan_next_shot)
	body.add_child(scan_button)

	var hint := Label.new()
	hint.text = "F10 hides/shows this panel. UI-off captures hide nodes in the configured UI group."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(hint)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_status)


func _on_capture_pressed() -> void:
	if _capture_in_progress:
		return
	var selected := _selected_target_keys()
	if selected.is_empty():
		_status.text = "Select at least one target."
		return
	_capture_in_progress = true
	_capture_button.disabled = true
	_status.text = "Capturing..."
	await _capture_selected(selected)
	_capture_button.disabled = false
	_capture_in_progress = false


func _capture_selected(selected: Array[String]) -> void:
	var tree := get_tree()
	var was_paused := tree.paused
	_original_window_size = DisplayServer.window_get_size()
	_original_window_mode = DisplayServer.window_get_mode()
	_original_max_size = DisplayServer.window_get_max_size()
	if _original_window_mode != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		await _wait_for_settle_frames()
	var visibility_snapshot: Array[Dictionary] = []
	_panel.visible = false
	if not _capture_ui.button_pressed:
		visibility_snapshot = _hide_registered_ui()

	tree.paused = true
	await tree.process_frame

	var failures: Array[String] = []
	var shot := int(_shot_number.value)
	var filename_override := _sanitize_filename_base(_label_edit.text)
	for target_key in selected:
		var resolution := _resolution_for(target_key)
		var error_text := await _capture_one(target_key, resolution, shot, filename_override, _capture_ui.button_pressed)
		if not error_text.is_empty():
			failures.append(error_text)

	Capture.restore_window(_original_window_size, _original_max_size)
	await _wait_for_settle_frames()
	if _original_window_mode != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(_original_window_mode)
		await _wait_for_settle_frames()
	_restore_visibility(visibility_snapshot)
	_panel.visible = true
	tree.paused = was_paused

	if failures.is_empty():
		_shot_number.value = shot + 1
		_status.text = "Captured shot #%02d for %d target(s)." % [shot, selected.size()]
	else:
		_status.text = "Capture completed with errors: %s" % "; ".join(failures)


func _capture_one(target_key: String, resolution: Vector2i, shot: int, filename_override: String, with_ui: bool) -> String:
	Capture.fit_window(resolution)
	var grabbed: Dictionary = await Capture.grab(get_viewport(), resolution, _settle_frames())
	if grabbed.has("error"):
		return "%s: %s" % [target_key, grabbed["error"]]
	var image: Image = grabbed["image"]

	var absolute_dir := ProjectSettings.globalize_path(_target_output_dir(target_key))
	_ensure_gdignore()

	var filename_base := filename_override
	if filename_base.is_empty():
		filename_base = "%s_%02d" % [_filename_prefix_for(target_key), shot]
	if not with_ui:
		filename_base += "_no_ui"
	var filename := "%s.png" % filename_base
	var save_error := Capture.save_png(image, absolute_dir.path_join(filename))
	if not save_error.is_empty():
		return "%s: %s" % [target_key, save_error]
	return ""


func _settle_frames() -> int:
	return clampi(int(ProjectSettings.get_setting("store_screenshot_capture/settle_frames", 3)), 1, 10)


func _wait_for_settle_frames() -> void:
	for _i in range(_settle_frames()):
		await get_tree().process_frame


func _selected_target_keys() -> Array[String]:
	var selected: Array[String] = []
	for target in TARGETS:
		var check := _target_checks[target["key"]] as CheckBox
		if check.button_pressed:
			selected.append(target["key"])
	return selected


func _resolution_for(target_key: String) -> Vector2i:
	var landscape: Vector2i = ProjectSettings.get_setting("store_screenshot_capture/%s_landscape" % target_key, Vector2i(1920, 1080))
	if _orientation.selected == 1:
		return Vector2i(landscape.y, landscape.x)
	return landscape


func _target_output_dir(target_key: String) -> String:
	var root := str(ProjectSettings.get_setting("store_screenshot_capture/output_root", "res://store_assets/screenshots")).trim_suffix("/")
	var orientation_dir := "portrait" if _orientation.selected == 1 else "landscape"
	return "%s/%s/%s" % [root, orientation_dir, target_key]


func _hide_registered_ui() -> Array[Dictionary]:
	return Capture.hide_group(get_tree(), str(ProjectSettings.get_setting("store_screenshot_capture/ui_group", "store_screenshot_ui")))


func _restore_visibility(snapshot: Array[Dictionary]) -> void:
	Capture.restore_group(snapshot)


func _sanitize_filename_base(value: String) -> String:
	var result := value.strip_edges()
	if result.to_lower().ends_with(".png"):
		result = result.left(result.length() - 4)
	for character in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		result = result.replace(character, "-")
	result = result.replace(" ", "_")
	while result.contains("__"):
		result = result.replace("__", "_")
	while result.contains("--"):
		result = result.replace("--", "-")
	return result.strip_edges().trim_prefix("-").trim_suffix("-").trim_prefix("_").trim_suffix("_")


func _filename_prefix_for(target_key: String) -> String:
	for target in TARGETS:
		if target["key"] == target_key:
			return str(target["filename_prefix"])
	return target_key.capitalize()


func _call_scan_next_shot() -> void:
	if not is_instance_valid(_shot_number):
		return
	_shot_number.value = _find_next_shot_number()
	if is_instance_valid(_status):
		_status.text = "Next available shot: #%02d" % int(_shot_number.value)


func _find_next_shot_number() -> int:
	var highest := 0
	for orientation_name in ["landscape", "portrait"]:
		for target in TARGETS:
			var root := str(ProjectSettings.get_setting("store_screenshot_capture/output_root", "res://store_assets/screenshots")).trim_suffix("/")
			var path := "%s/%s/%s" % [root, orientation_name, target["key"]]
			var absolute := ProjectSettings.globalize_path(path)
			var dir := DirAccess.open(absolute)
			if dir == null:
				continue
			dir.list_dir_begin()
			var filename := dir.get_next()
			while not filename.is_empty():
				if not dir.current_is_dir() and filename.to_lower().ends_with(".png"):
					var base_name := filename.get_basename()
					var target_prefix := str(target["filename_prefix"]) + "_"
					if base_name.begins_with(target_prefix):
						var remainder := base_name.trim_prefix(target_prefix)
						var number_text := remainder.get_slice("_", 0)
						if number_text.is_valid_int():
							highest = maxi(highest, int(number_text))
					else:
						# Backward compatibility with v1.0.x files such as 03_battle.png.
						var legacy_prefix := base_name.get_slice("_", 0)
						if legacy_prefix.is_valid_int():
							highest = maxi(highest, int(legacy_prefix))
				filename = dir.get_next()
			dir.list_dir_end()
	return highest + 1


func _ensure_gdignore() -> void:
	var root := str(ProjectSettings.get_setting("store_screenshot_capture/output_root", "res://store_assets/screenshots"))
	if not root.begins_with("res://"):
		return
	Capture.ensure_gdignore(root, "Generated by Store Screenshot Capture. Prevents store images from being imported as game assets.")
