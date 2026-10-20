extends RefCounted
## The capture steps both capture tools share (game-independent): the Store
## Screenshot Capture overlay (runtime_capture.gd, interactive) and the
## Marketing Capture runner (addons/marketing_capture/capture_runner.gd,
## command line). One implementation of: sizing the real game window,
## waiting for the layout and a finished render, reading the frame back and
## checking its size, hiding and restoring the registered UI roots, and
## writing a PNG without overwriting anything.
##
## Use through preload("res://addons/store_screenshot_capture/viewport_capture.gd").


## Sizes the real game window to `size` pixels and returns the previous
## maximum size (for restore_window). Windows clamps a window to the screen
## unless its maximum size is raised first: without this, a 2560x1440 tablet
## or a 1080x1920 portrait capture fails on a 1920x1080 monitor.
static func fit_window(size: Vector2i) -> Vector2i:
	var previous_max := DisplayServer.window_get_max_size()
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_max_size(Vector2i(maxi(size.x, previous_max.x), maxi(size.y, previous_max.y)))
	DisplayServer.window_set_size(size)
	return previous_max


static func restore_window(size: Vector2i, previous_max: Vector2i) -> void:
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_max_size(previous_max)


## Waits `settle_frames` frames (responsive layout) and a completed render,
## then returns {"image": Image} or {"error": String}. The rendered size must
## be exactly `expected`: a clamped or embedded window fails loudly instead of
## producing a mislabelled file. Works while the tree is paused.
static func grab(viewport: Viewport, expected: Vector2i, settle_frames: int) -> Dictionary:
	var tree := viewport.get_tree()
	for _i in range(clampi(settle_frames, 1, 30)):
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		return {"error": "viewport image unavailable"}
	if image.get_size() != expected:
		return {"error": "requested %dx%d but the viewport rendered %dx%d (a clamped or embedded window: run in its own window)" % [expected.x, expected.y, image.get_width(), image.get_height()]}
	return {"image": image}


## Hides every CanvasItem / CanvasLayer root in `group` (only the roots a game
## registered: world-space labels and bars stay). Returns what restore_group
## needs.
static func hide_group(tree: SceneTree, group: String) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	if group.is_empty():
		return snapshot
	for node in tree.get_nodes_in_group(group):
		if node == null or not is_instance_valid(node):
			continue
		if node is CanvasItem:
			snapshot.append({"node": node, "visible": (node as CanvasItem).visible})
			(node as CanvasItem).visible = false
		elif node is CanvasLayer:
			snapshot.append({"node": node, "visible": (node as CanvasLayer).visible})
			(node as CanvasLayer).visible = false
	return snapshot


static func restore_group(snapshot: Array[Dictionary]) -> void:
	for entry in snapshot:
		var node: Node = entry.get("node")
		if node == null or not is_instance_valid(node):
			continue
		var visible := bool(entry.get("visible", true))
		if node is CanvasItem:
			(node as CanvasItem).visible = visible
		elif node is CanvasLayer:
			(node as CanvasLayer).visible = visible


## Writes `image` to the absolute or res:// `path`; "" or the reason it did
## not. Never overwrites an existing file.
static func save_png(image: Image, path: String) -> String:
	var absolute := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		return "cannot create %s" % absolute.get_base_dir()
	if FileAccess.file_exists(absolute):
		return "%s already exists" % absolute
	var error := image.save_png(absolute)
	if error != OK:
		return "PNG save failed (%d)" % error
	return ""


## A .gdignore in `dir` (absolute or res://), so generated images are never
## imported as game assets.
static func ensure_gdignore(dir: String, note: String) -> void:
	var absolute := ProjectSettings.globalize_path(dir) if dir.begins_with("res://") else dir
	var error := DirAccess.make_dir_recursive_absolute(absolute)
	if error != OK and error != ERR_ALREADY_EXISTS:
		return
	var path := absolute.path_join(".gdignore")
	if FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string("# %s\n" % note)
