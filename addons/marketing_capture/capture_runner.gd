extends Node
## Development-only capture scene: launch explicitly via tools/marketing.py record.
## Uses the game's actual scene and per-game adapter. No game-specific imports.
## For videos, use Godot Movie Maker + --quit-after <frames>, since _ready()
## completes synchronously before the first recorded frame.
##
## Order: adapter added -> is_capture_safe() -> window sized to the job ->
## game scene instantiated -> prepare_scenario() -> optional UI hiding ->
## size check -> (screenshot) capture_frame frames of live play, freeze,
## settle, read back, write the PNG and quit; (video) Movie Maker records
## until --quit-after.

## Shared with the Store Screenshot Capture overlay (one implementation).
const Capture := preload("res://addons/store_screenshot_capture/viewport_capture.gd")
## Development overlays (editor-runtime autoloads) never show in a capture.
const DEV_OVERLAY_AUTOLOADS := ["StoreScreenshotCapture"]

var _config: Dictionary = {}
var _job: Dictionary = {}
var _capture_kind := ""
var _size := Vector2i.ZERO
var _game: Node
var _adapter: Node


func _ready() -> void:
	# The runner keeps processing while it freezes the game for a screenshot.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _init_job():
		get_tree().quit(2)
		return
	if _capture_kind == "screenshot":
		_capture_png.call_deferred()


func _init_job() -> bool:
	var args := OS.get_cmdline_user_args()
	if "--marketing-capture" not in args:
		push_error("MarketingCapture: explicit --marketing-capture required")
		return false
	var manifest_path := ""
	var job_id := ""
	for a in args:
		if a.begins_with("--manifest="):
			manifest_path = a.trim_prefix("--manifest=")
		if a.begins_with("--job="):
			job_id = a.trim_prefix("--job=")
	if manifest_path.is_empty() or job_id.is_empty():
		push_error("MarketingCapture: missing --manifest= or --job=")
		return false
	if not FileAccess.file_exists(manifest_path):
		push_error("MarketingCapture: manifest not found: " + manifest_path)
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not data is Dictionary:
		push_error("MarketingCapture: invalid manifest JSON")
		return false
	_config = data
	for item in _config.get("capture_jobs", []):
		if item is Dictionary and str(item.get("id", "")) == job_id:
			_job = item
			break
	if _job.is_empty():
		push_error("MarketingCapture: job not found: " + job_id)
		return false
	_capture_kind = str(_job.get("kind", ""))
	if _capture_kind not in ["video", "screenshot"]:
		push_error("MarketingCapture: unsupported job kind")
		return false
	_size = Vector2i(int(_job.get("width", 0)), int(_job.get("height", 0)))
	if _size.x <= 0 or _size.y <= 0:
		push_error("MarketingCapture: dimensions must be positive")
		return false
	if _capture_kind == "video" and not OS.has_feature("movie"):
		push_error("MarketingCapture: video jobs need Godot --write-movie")
		return false
	var main_scene_path := str(_config.get("game_scene", ""))
	var adapter_path := str(_config.get("adapter_script", ""))
	if not main_scene_path.begins_with("res://") or not adapter_path.begins_with("res://"):
		push_error("MarketingCapture: game_scene and adapter_script must use res://")
		return false
	var scene := load(main_scene_path) as PackedScene
	var adapter_script := load(adapter_path) as GDScript
	if scene == null or adapter_script == null:
		push_error("MarketingCapture: failed to load scene/adapter")
		return false
	# A capture tool must never accidentally change a real player's saved game.
	# The game-specific adapter proves its isolated test save first.
	_adapter = adapter_script.new() as Node
	if _adapter == null:
		push_error("MarketingCapture: adapter must extend Node")
		return false
	# The game and the adapter's per-frame staging freeze with the tree for a
	# screenshot (they would otherwise inherit this runner's ALWAYS mode).
	if _adapter.process_mode == Node.PROCESS_MODE_INHERIT:
		_adapter.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_adapter)
	if not _adapter.has_method("is_capture_safe") or not bool(_adapter.call("is_capture_safe")):
		push_error("MarketingCapture: adapter did not prove isolated test-save safety")
		return false
	# The real game window at the job's size, before the game lays itself out
	# (past the screen's size too: a portrait or tablet target on a smaller
	# monitor). Movie Maker's frame size is set by the window override that
	# tools/marketing.py writes for the run.
	Capture.fit_window(_size)
	_hide_dev_overlays()
	_game = scene.instantiate()
	if _game.process_mode == Node.PROCESS_MODE_INHERIT:
		_game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_game)
	move_child(_game, 0)
	if not _adapter.has_method("prepare_scenario") or not bool(_adapter.call("prepare_scenario", str(_job.get("scenario", job_id)), _job.get("options", {}), _game, _job)):
		push_error("MarketingCapture: scenario adapter failed: " + job_id)
		return false
	if not bool(_job.get("capture_ui", true)):
		Capture.hide_group(get_tree(), str(_config.get("ui_group", "store_screenshot_ui")))
	# The render size (the window), not the game's virtual canvas size: a game
	# that stretches with aspect "expand" lays out a larger canvas than the
	# picture it renders.
	var window_size := get_window().size
	if window_size != _size:
		push_error("MarketingCapture: the window is %dx%d, wanted %dx%d (the OS refused the size, or the run is embedded)" % [window_size.x, window_size.y, _size.x, _size.y])
		return false
	print("MARKETING_CAPTURE READY ", job_id, " ", _capture_kind, " ", _size)
	return true


func _hide_dev_overlays() -> void:
	for n in DEV_OVERLAY_AUTOLOADS:
		var tool := get_tree().root.get_node_or_null(n)
		if tool == null:
			continue
		for c in tool.get_children():
			if c is CanvasLayer:
				(c as CanvasLayer).visible = false


func _capture_png() -> void:
	# The held moment: capture_frame frames of live play (the adapter's staging
	# and the game run as they would in a video of the same scenario), then the
	# simulation is frozen so the layout settles on that exact frame.
	for _i in range(maxi(0, int(_job.get("capture_frame", 0)))):
		await get_tree().process_frame
	get_tree().paused = true
	var grabbed: Dictionary = await Capture.grab(get_viewport(), _size, int(_job.get("settle_frames", 3)))
	if grabbed.has("error"):
		push_error("MarketingCapture: " + str(grabbed["error"]))
		get_tree().quit(3)
		return
	var out_path := str(_job.get("output", ""))
	# Only explicit external output paths; no write into real save directories.
	if out_path.is_empty() or out_path.begins_with("user://") or not out_path.is_absolute_path():
		push_error("MarketingCapture: screenshot output must be an explicit absolute filesystem path")
		get_tree().quit(3)
		return
	var error := Capture.save_png(grabbed["image"], out_path)
	if not error.is_empty():
		push_error("MarketingCapture: " + error)
		get_tree().quit(3)
		return
	print("MARKETING_CAPTURE OK ", out_path)
	get_tree().quit()
