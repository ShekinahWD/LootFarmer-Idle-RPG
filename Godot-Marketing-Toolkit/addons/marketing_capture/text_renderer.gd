extends SceneTree
## Text blocks for the marketing composer (tools/marketing.py), set by Godot's
## own text server: HarfBuzz shaping (Thai marks, Devanagari conjuncts and
## reordered vowels), ICU line breaking (Thai words, CJK) and font fallback
## chains (marketing_fonts.gd). Headless: each glyph is rasterised by the text
## server's glyph cache and copied on the CPU, so no window or GPU is needed.
##
## tools/marketing.py runs it in a throwaway project (never the game's, whose
## autoloads would start), one batch per composition:
##   godot --headless --path <tmp> --script res://text_renderer.gd -- --job=<job.json>
## job.json: {"fonts": {key: [face spec, ...]}, "report": <path>,
##   "requests": [{"id", "text", "font", "language", "start_size", "min_size",
##                 "keep_floor", "max_width", "max_height", "out"}]}
## Each request gets the largest size from start_size down at which the text
## fits max_width x max_height (the composer's Pillow rule: the author's lines
## are kept whole down to keep_floor, then wrapped at word boundaries from
## start_size down, then, last, anywhere; a wrap is balanced: lines of even
## length). Its PNG is white text on transparency, each line centred,
## lines stacked by their ink with a gap of 17% of the size, PAD pixels around.
## The report gives per request: size, font_size, lines (text, range, ink
## size, glyph count), wrap mode, missing characters, or the error.

const Fonts := preload("marketing_fonts.gd")
const PAD := 2
const GAP_RATIO := 0.17
const WRAP_AUTHORED := 0
const WRAP_WORDS := 1
const WRAP_ANYWHERE := 2

var _ts: TextServer


func _initialize() -> void:
	_ts = TextServerManager.get_primary_interface()
	var job_path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--job="):
			job_path = a.trim_prefix("--job=")
	var job: Variant = JSON.parse_string(FileAccess.get_file_as_string(job_path)) if FileAccess.file_exists(job_path) else null
	if not job is Dictionary:
		printerr("MARKETING_TEXT: unreadable job ", job_path)
		quit(2)
		return
	var report := {"text_server": _ts.get_name(),
		"line_breaking": _ts.has_feature(TextServer.FEATURE_BREAK_ITERATORS), "results": {}}
	var fonts := {}
	var font_errors := {}
	for key: String in job.get("fonts", {}):
		var errors := []
		var font := Fonts.chain(job["fonts"][key], errors)
		if font == null:
			font_errors[key] = "; ".join(errors)
		else:
			fonts[key] = font
	for request: Dictionary in job.get("requests", []):
		var id := str(request.get("id"))
		var key := str(request.get("font", ""))
		if font_errors.has(key):
			report["results"][id] = {"ok": false, "error": font_errors[key]}
		elif not fonts.has(key):
			report["results"][id] = {"ok": false, "error": "No font chain " + key}
		else:
			report["results"][id] = _render(request, fonts[key])
	var out := FileAccess.open(str(job.get("report", "")), FileAccess.WRITE)
	if out == null:
		printerr("MARKETING_TEXT: cannot write the report")
		quit(2)
		return
	out.store_string(JSON.stringify(report, "  "))
	out.close()
	quit(0)


func _render(request: Dictionary, font: Font) -> Dictionary:
	var text := str(request.get("text", ""))
	var missing := Fonts.missing(font, text)
	if not missing.is_empty():
		return {"ok": false, "missing": Array(missing),
			"error": "The font chain has no glyph for " + ", ".join(missing)}
	var language := str(request.get("language", ""))
	var start := int(request.get("start_size", 48))
	var floor_size := int(request.get("min_size", 16))
	var keep_floor := int(request.get("keep_floor", start))
	var max_w := float(request.get("max_width", 0))
	var max_h := float(request.get("max_height", 0))
	var attempts: Array[Vector2i] = []
	for size in range(start, keep_floor - 1, -2):
		attempts.append(Vector2i(size, WRAP_AUTHORED))
	for mode in [WRAP_WORDS, WRAP_ANYWHERE]:
		for size in range(start, floor_size - 1, -2):
			attempts.append(Vector2i(size, mode))
	for attempt in attempts:
		var layout := _layout(text, font, attempt.x, language, max_w, attempt.y)
		if layout["fits_width"] and layout["height"] <= max_h:
			if attempt.y != WRAP_AUTHORED:
				layout = _balance(text, font, attempt.x, language, max_w, max_h, attempt.y, layout)
			var result := _draw(layout, str(request.get("out", "")))
			if not result.is_empty():
				return {"ok": false, "error": result}
			return {"ok": true, "font_size": attempt.x, "wrap": ["authored", "words", "anywhere"][attempt.y],
				"size": [layout["width"] + 2 * PAD, layout["height"] + 2 * PAD], "pad": PAD,
				"gap": layout["gap"], "lines": layout["lines"].map(func(l: Dictionary) -> Dictionary:
					return {"text": l["text"], "start": l["start"], "end": l["end"],
						"width": l["ink"].size.x, "height": l["ink"].size.y, "glyphs": l["glyph_count"]})}
	return {"ok": false, "error": "Text does not fit %dx%d even at %d px" % [max_w, max_h, floor_size]}


## Shapes and breaks `text` at one size. Lines keep their glyphs and ink
## rectangles (relative to the pen start on the baseline).
func _layout(text: String, font: Font, size: int, language: String, max_w: float, mode: int) -> Dictionary:
	var lines: Array[Dictionary] = []
	var offset := 0
	for paragraph in text.split("\n"):
		var para := TextParagraph.new()
		para.add_string(paragraph, font, size, language)
		if mode == WRAP_AUTHORED:
			para.break_flags = TextServer.BREAK_MANDATORY
		else:
			para.width = max_w
			para.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND \
				| (TextServer.BREAK_ADAPTIVE if mode == WRAP_ANYWHERE else 0)
		for i in maxi(1, para.get_line_count()):
			var rid := para.get_line_rid(i) if para.get_line_count() else RID()
			var glyphs: Array = _ts.shaped_text_get_glyphs(rid) if rid.is_valid() else []
			var span := _ts.shaped_text_get_range(rid) if rid.is_valid() else Vector2i.ZERO
			lines.append({"glyphs": glyphs, "ink": _ink(glyphs),
				"text": paragraph.substr(span.x, span.y - span.x).strip_edges(),
				"start": offset + span.x, "end": offset + span.y,
				# Virtual entries (break opportunities between CJK characters) draw nothing.
				"glyph_count": glyphs.filter(func(g: Dictionary) -> bool:
					return (int(g["flags"]) & TextServer.GRAPHEME_IS_VIRTUAL) == 0).size()})
		offset += paragraph.length() + 1
	var gap := maxi(3, roundi(size * GAP_RATIO))
	var width := 0
	var height := gap * (lines.size() - 1)
	var fits := true
	for line in lines:
		var ink: Rect2 = line["ink"]
		width = maxi(width, ceili(ink.size.x))
		height += ceili(ink.size.y)
		fits = fits and ink.size.x <= max_w
	return {"lines": lines, "width": width, "height": height, "gap": gap, "fits_width": fits}


## Lines of even length: the narrowest break width that keeps the line count
## of `fitted` (a wrap at max_w), so no word is left alone on a last line.
func _balance(text: String, font: Font, size: int, language: String, max_w: float, max_h: float, mode: int,
		fitted: Dictionary) -> Dictionary:
	var count: int = fitted["lines"].size()
	var best := fitted
	var lo := max_w / 3.0
	var hi := max_w
	while hi - lo > 2.0:
		var mid := (lo + hi) / 2.0
		var trial := _layout(text, font, size, language, mid, mode)
		# Measured against the real limit: a word wider than `mid` may stand alone.
		var widest := 0.0
		for line: Dictionary in trial["lines"]:
			widest = maxf(widest, (line["ink"] as Rect2).size.x)
		if trial["lines"].size() <= count and widest <= max_w and trial["height"] <= max_h:
			best = trial
			hi = mid
		else:
			lo = mid
	return best


## The union of a line's glyph images: where its ink is.
func _ink(glyphs: Array) -> Rect2:
	var ink := Rect2()
	var first := true
	for rect in _glyph_rects(glyphs):
		ink = rect if first else ink.merge(rect)
		first = false
	return ink


## Every drawn glyph's image rectangle, in pen coordinates (baseline y = 0),
## with what draws it: [Rect2, font_rid, size, index].
func _glyph_rects(glyphs: Array, with_glyph := false) -> Array:
	var out := []
	var x := 0.0
	for g: Dictionary in glyphs:
		for _r in int(g.get("repeat", 1)):
			var rid: RID = g["font_rid"]
			if rid.is_valid() and (int(g["flags"]) & TextServer.GRAPHEME_IS_VIRTUAL) == 0:
				var size := Vector2i(int(g["font_size"]), 0)
				var index := int(g["index"])
				var rect := Rect2(Vector2(x, 0) + g["offset"] + _ts.font_get_glyph_offset(rid, size, index),
					_ts.font_get_glyph_size(rid, size, index))
				if rect.size.x > 0 and rect.size.y > 0:
					out.append([rect, rid, size, index] if with_glyph else rect)
			x += float(g["advance"])
	return out


## Copies each glyph's image out of the text server's glyph cache into one
## white-on-transparent block. Returns "" or an error.
func _draw(layout: Dictionary, path: String) -> String:
	var w: int = layout["width"] + 2 * PAD
	var h: int = layout["height"] + 2 * PAD
	var image := Image.create_empty(maxi(1, w), maxi(1, h), false, Image.FORMAT_RGBA8)
	var placed := []
	var y := float(PAD)
	for line: Dictionary in layout["lines"]:
		var ink: Rect2 = line["ink"]
		# Centred by its ink, its top on y: the pen sits ink.position away.
		var pen := Vector2(PAD + floorf((layout["width"] - ink.size.x) / 2.0) - ink.position.x, y - ink.position.y)
		for item in _glyph_rects(line["glyphs"], true):
			placed.append([item, pen])
		y += ceilf(ink.size.y) + layout["gap"]
	# Every glyph is rendered into the cache before any cache image is read
	# (the cache may grow while glyphs are added).
	for p in placed:
		_ts.font_get_glyph_uv_rect(p[0][1], p[0][2], p[0][3])
	var sheets := {}
	for p in placed:
		var rid: RID = p[0][1]
		var size: Vector2i = p[0][2]
		var index: int = p[0][3]
		var sheet_index := _ts.font_get_glyph_texture_idx(rid, size, index)
		var key := "%s/%s/%d" % [rid.get_id(), size, sheet_index]
		if not sheets.has(key):
			var sheet := _ts.font_get_texture_image(rid, size, sheet_index)
			if sheet == null:
				return "The glyph cache gave no image"
			sheet = sheet.duplicate()
			sheet.convert(Image.FORMAT_RGBA8)
			sheets[key] = sheet
		var uv := Rect2i(_ts.font_get_glyph_uv_rect(rid, size, index))
		var rect: Rect2 = p[0][0]
		image.blend_rect(sheets[key], uv, Vector2i((p[1] + rect.position).round()))
	if image.save_png(path) != OK:
		return "Cannot write " + path
	return ""
