extends RefCounted
## Font fallback chains for marketing text, built at run time from font files
## anywhere on disk (absolute paths). No font enters res://, so nothing reaches
## a game export: a full CJK face alone is 10-17 MB, and a game whose own UI is
## not localized should not ship marketing scripts on Android.
##
## A chain is an Array of face specs, the first is the primary face and the
## rest its fallbacks, in order: {"path": "D:/.../NotoSansThai[wdth,wght].ttf",
## "weight": 700, "width": 100}. "weight" / "width" set a variable font's wght /
## wdth axes (a static face has none: pick the file of the weight instead).
## Godot's text server takes each character from the first face that has it
## (HarfBuzz shapes each run in its face). System fonts are never used: a
## capture must render the same on every machine, in licensed fonts only.
##
## Usable from a game's capture adapter too (preload this file), e.g. for a
## localized caption drawn inside the game during a capture.

const AXES := {"weight": "wght", "width": "wdth"}


## The chain as one Font (the first face, the others as its fallbacks), or
## null with the reasons appended to `errors`.
static func chain(specs: Array, errors: Array) -> Font:
	var faces: Array[Font] = []
	for spec in specs:
		if not spec is Dictionary:
			errors.append("Font spec must be a dictionary: %s" % [spec])
			return null
		var face := load_face(spec, errors)
		if face == null:
			return null
		faces.append(face)
	if faces.is_empty():
		errors.append("Empty font chain")
		return null
	var head := faces[0]
	if faces.size() > 1:
		head.fallbacks = faces.slice(1)
	return head


## One face: a FontFile set up for large, exact marketing text, wrapped in a
## FontVariation when variable axes are requested.
static func load_face(spec: Dictionary, errors: Array) -> Font:
	var path := str(spec.get("path", ""))
	if path.is_empty() or not FileAccess.file_exists(path):
		errors.append("Font file not found: " + path)
		return null
	var file := FontFile.new()
	if file.load_dynamic_font(path) != OK:
		errors.append("Not a font Godot can load: " + path)
		return null
	file.allow_system_fallback = false
	file.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	# Display sizes: unhinted outlines keep the designed shapes; whole-pixel
	# positions keep one glyph image per glyph (sizes are far above 20 px).
	file.hinting = TextServer.HINTING_NONE
	file.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	file.multichannel_signed_distance_field = false
	file.generate_mipmaps = false
	var coords := {}
	var supported := file.get_supported_variation_list()
	var ts := TextServerManager.get_primary_interface()
	for key: String in AXES:
		if not spec.has(key) or spec[key] == null:
			continue
		var tag := ts.name_to_tag(AXES[key])
		if not supported.has(tag):
			errors.append("%s has no %s axis (a static face: choose the file of that %s)" % [path.get_file(), AXES[key], key])
			return null
		var limits: Vector3i = supported[tag]
		var value := float(spec[key])
		if value < limits.x or value > limits.y:
			errors.append("%s: %s %s is outside the font's range %d-%d" % [path.get_file(), key, value, limits.x, limits.y])
			return null
		coords[tag] = value
	if coords.is_empty():
		return file
	var variation := FontVariation.new()
	variation.base_font = file
	variation.variation_opentype = coords
	return variation


## Characters of `text` no face of the chain has (spaces and invisible
## formatting characters excluded): a font chain must cover its copy fully.
static func missing(font: Font, text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var faces: Array[Font] = [font]
	faces.append_array(font.fallbacks)
	for i in text.length():
		var c := text.unicode_at(i)
		if _invisible(c):
			continue
		var found := false
		for face in faces:
			if face.has_char(c):
				found = true
				break
		if not found:
			var label := "U+%04X %s" % [c, String.chr(c)]
			if label not in out:
				out.append(label)
	return out


static func _invisible(c: int) -> bool:
	# Whitespace, line breaks, ZWSP/ZWNJ/ZWJ, direction marks, word joiner,
	# variation selectors, BOM: formatting, never drawn.
	return c <= 0x20 or c == 0xA0 or c == 0x3000 or (c >= 0x200B and c <= 0x200F) \
		or c == 0x2060 or (c >= 0xFE00 and c <= 0xFE0F) or c == 0xFEFF
