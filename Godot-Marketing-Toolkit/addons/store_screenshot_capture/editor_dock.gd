@tool
extends VBoxContainer

const TARGET_KEYS := ["phone", "tablet_7", "tablet_10", "desktop"]
const TARGET_LABELS := ["Phone", "7-inch tablet", "10-inch tablet", "Desktop"]

var _output_edit: LineEdit
var _ui_group_edit: LineEdit
var _orientation: OptionButton
var _capture_ui: CheckBox
var _settle_frames: SpinBox
var _resolution_edits: Dictionary = {}
var _status: Label

func _ready() -> void:
	name = "Store Capture"
	custom_minimum_size = Vector2(320, 0)
	_build_ui()
	_load_settings()


func _build_ui() -> void:
	var title := Label.new()
	title.text = "Store Screenshot Capture"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)

	var hint := Label.new()
	hint.text = "Configure project defaults here. Capture from the runtime overlay while running the game."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)

	add_child(HSeparator.new())
	_output_edit = _add_labeled_line("Output root")
	_ui_group_edit = _add_labeled_line("UI root group")

	var orientation_row := HBoxContainer.new()
	var orientation_label := Label.new()
	orientation_label.text = "Default orientation"
	orientation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orientation_row.add_child(orientation_label)
	_orientation = OptionButton.new()
	_orientation.add_item("Landscape")
	_orientation.add_item("Portrait")
	orientation_row.add_child(_orientation)
	add_child(orientation_row)

	_capture_ui = CheckBox.new()
	_capture_ui.text = "Capture UI by default"
	_capture_ui.button_pressed = true
	add_child(_capture_ui)

	var settle_row := HBoxContainer.new()
	var settle_label := Label.new()
	settle_label.text = "Layout settle frames"
	settle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settle_row.add_child(settle_label)
	_settle_frames = SpinBox.new()
	_settle_frames.min_value = 1
	_settle_frames.max_value = 10
	_settle_frames.step = 1
	settle_row.add_child(_settle_frames)
	add_child(settle_row)

	var res_title := Label.new()
	res_title.text = "Landscape resolution presets"
	res_title.add_theme_font_size_override("font_size", 15)
	add_child(res_title)

	for i in range(TARGET_KEYS.size()):
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = TARGET_LABELS[i]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var edit := LineEdit.new()
		edit.placeholder_text = "1920x1080"
		edit.custom_minimum_size.x = 120
		row.add_child(edit)
		_resolution_edits[TARGET_KEYS[i]] = edit
		add_child(row)

	var note := Label.new()
	note.text = "Portrait automatically swaps width/height. Add the UI roots you want hidden to the configured node group. The capture overlay itself is always excluded."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)

	var save_button := Button.new()
	save_button.text = "Save Defaults"
	save_button.pressed.connect(_save_settings)
	add_child(save_button)

	var open_button := Button.new()
	open_button.text = "Open Output Folder"
	open_button.pressed.connect(_open_output_folder)
	add_child(open_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)


func _add_labeled_line(label_text: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	add_child(label)
	var edit := LineEdit.new()
	add_child(edit)
	return edit


func _load_settings() -> void:
	_output_edit.text = str(ProjectSettings.get_setting("store_screenshot_capture/output_root", "res://store_assets/screenshots"))
	_ui_group_edit.text = str(ProjectSettings.get_setting("store_screenshot_capture/ui_group", "store_screenshot_ui"))
	var orientation_value := str(ProjectSettings.get_setting("store_screenshot_capture/default_orientation", "landscape"))
	_orientation.select(1 if orientation_value == "portrait" else 0)
	_capture_ui.button_pressed = bool(ProjectSettings.get_setting("store_screenshot_capture/capture_ui_default", true))
	_settle_frames.value = int(ProjectSettings.get_setting("store_screenshot_capture/settle_frames", 3))
	for key in TARGET_KEYS:
		var value: Vector2i = ProjectSettings.get_setting("store_screenshot_capture/%s_landscape" % key, Vector2i(1920, 1080))
		(_resolution_edits[key] as LineEdit).text = "%dx%d" % [value.x, value.y]


func _save_settings() -> void:
	var parsed: Dictionary = {}
	for key in TARGET_KEYS:
		var value := _parse_resolution((_resolution_edits[key] as LineEdit).text)
		var validation_error := _validate_play_store_resolution(key, value)
		if not validation_error.is_empty():
			_status.text = validation_error
			return
		parsed[key] = value

	ProjectSettings.set_setting("store_screenshot_capture/output_root", _output_edit.text.strip_edges())
	ProjectSettings.set_setting("store_screenshot_capture/ui_group", _ui_group_edit.text.strip_edges())
	ProjectSettings.set_setting("store_screenshot_capture/default_orientation", "portrait" if _orientation.selected == 1 else "landscape")
	ProjectSettings.set_setting("store_screenshot_capture/capture_ui_default", _capture_ui.button_pressed)
	ProjectSettings.set_setting("store_screenshot_capture/settle_frames", int(_settle_frames.value))
	for key in TARGET_KEYS:
		ProjectSettings.set_setting("store_screenshot_capture/%s_landscape" % key, parsed[key])
	var error := ProjectSettings.save()
	_status.text = "Defaults saved." if error == OK else "Could not save project settings (error %d)." % error


func _parse_resolution(text: String) -> Vector2i:
	var cleaned := text.to_lower().replace(" ", "")
	var parts := cleaned.split("x", false)
	if parts.size() != 2:
		return Vector2i.ZERO
	if not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i.ZERO
	var width := int(parts[0])
	var height := int(parts[1])
	if width < 320 or height < 320:
		return Vector2i.ZERO
	return Vector2i(width, height)


func _validate_play_store_resolution(target_key: String, value: Vector2i) -> String:
	if value == Vector2i.ZERO:
		return "Invalid resolution for %s. Use WIDTHxHEIGHT, for example 1920x1080." % target_key
	if value.x <= value.y:
		return "%s landscape preset must be wider than it is tall. Portrait is generated automatically." % target_key
	var ratio_error := absf((float(value.x) / float(value.y)) - (16.0 / 9.0))
	if ratio_error > 0.002:
		return "%s must use a 16:9 landscape resolution. Portrait automatically becomes 9:16." % target_key
	var minimum_side := 1080 if target_key in ["tablet_10", "desktop"] else 320
	var maximum_side := 7680 if target_key in ["tablet_10", "desktop"] else 3840
	if value.x < minimum_side or value.y < minimum_side or value.x > maximum_side or value.y > maximum_side:
		return "%s must keep both sides between %d and %d px for its Play Store category." % [target_key, minimum_side, maximum_side]
	return ""


func _open_output_folder() -> void:
	var root := _output_edit.text.strip_edges()
	if root.is_empty():
		_status.text = "Output root is empty."
		return
	var absolute := ProjectSettings.globalize_path(root)
	var error := DirAccess.make_dir_recursive_absolute(absolute)
	if error != OK and error != ERR_ALREADY_EXISTS:
		_status.text = "Could not create output directory (error %d)." % error
		return
	OS.shell_open(absolute)
