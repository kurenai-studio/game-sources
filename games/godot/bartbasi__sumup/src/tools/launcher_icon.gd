extends Node
## Android launcher icon, drawn in code (docs/DESIGN_SYSTEM.md section 9).
##
## Headless Godot has no renderer, so this runs with a window and quits by
## itself when done. From the repo root:
##     godot --path . res://tools/launcher_icon.tscn
## It writes the four PNGs the Android export uses to launcher/ at the repo
## root (only this tool writes there):
##     main_192.png                 legacy icon, the 72 dp the launcher shows,
##                                  corners rounded, transparent outside
##     adaptive_foreground_432.png  the foreground layer on transparent
##     adaptive_background_432.png  the background layer, full bleed
##     adaptive_monochrome_432.png  the foreground silhouettes in white, labels
##                                  cut out, for Android 13 themed icons
## and a review sheet to docs/design/review/launcher-icon-check.png, which git
## ignores. It also writes the Google Play store icon (2026-10-17):
##     docs/store/graphics/icon_512.png  512 by 512, 32 bit RGBA, opaque: the
##                                  same 72 dp square as main_192.png, full
##                                  square with no rounded corners and no
##                                  shadow, since Play adds its own mask
## The store icon is held back too when the safe circle check fails.
##
## Every color comes from the Gumdrop SkinData (src/skins/gumdrop/gumdrop.tres)
## through SkinCatalog, as do the tile corner radius, the lip darkening, the
## tile font and the label size. The composition itself (positions, turns,
## sizes) is section 9.3 and lives in the constants below.
##
## How it renders: the rope, tiles, ring and labels are drawn with _draw() into
## a SubViewport at SUPERSAMPLE times the output size with no antialiasing, and
## each SUPERSAMPLE by SUPERSAMPLE block is averaged into one pixel. The
## background glow is worked out per pixel. Nothing depends on time, randomness
## or the window, so a second run writes the same pixels and the same files.
##
## Before writing, it checks that the foreground and monochrome layers stay
## inside the 66 dp safe circle; if not, launcher/ is left as it was. Exits
## with code 0 when the check passed and every file was written, 1 otherwise.

const SKIN_ID: StringName = &"gumdrop"

## Adaptive icon layers are 108 dp; at 4 px per dp that is 432 px.
const LAYER_SIZE: int = 432
## Every launcher mask keeps the inner 66 dp circle: radius 132 px.
const SAFE_CENTER: Vector2 = Vector2(216.0, 216.0)
const SAFE_RADIUS: float = 132.0
## The launcher shows the inner 72 dp (288 px). The legacy icon is that square.
const VISIBLE_SIDE: float = 288.0
const LEGACY_SIZE: int = 192
## Legacy icon corner radius, share of its side.
const LEGACY_CORNER: float = 0.22

## Background: a radial glow of surface on bg, smooth falloff.
const GLOW_CENTER: Vector2 = Vector2(216.0, 196.0)
const GLOW_RADIUS: float = 260.0

## Foreground: two 2 tiles about to merge, joined by the rope. Positions are
## tile centers in layer px; turns are degrees, positive is clockwise.
## The tile 2 as the skins take it: its exponent (ARCHITECTURE.md 17).
const TILE_EXPONENT: int = 1
const TILE_SIDE: float = 92.0
## Lip depth, share of the tile side.
const TILE_LIP: float = 0.075
const TILE_A_CENTER: Vector2 = Vector2(160.0, 164.0)
const TILE_A_TURN: float = -6.0
const TILE_B_CENTER: Vector2 = Vector2(272.0, 268.0)
const TILE_B_TURN: float = 5.0
const ROPE_WIDTH: float = 24.0
## The chained ring on tile B, just outside its face.
const RING_WIDTH: float = 5.0

## Render scale before averaging: 16 samples per output pixel.
const SUPERSAMPLE: int = 4
## Frames to wait before reading a SubViewport back.
const WAIT_FRAMES: int = 4

const OUTPUT_DIR: String = "res://launcher"
## The Play store icon: 512 px, the visible 72 dp square, square corners.
const STORE_ICON_SIZE: int = 512
const STORE_ICON_PATH: String = "res://docs/store/graphics/icon_512.png"
const REVIEW_PATH: String = "res://docs/design/review/launcher-icon-check.png"

## Review sheet colors. Not part of the icon.
const SHEET_COLOR: Color = Color(0.36, 0.36, 0.4)
const GUIDE_SAFE: Color = Color(0.3, 1.0, 0.45)
const GUIDE_VISIBLE: Color = Color(1.0, 1.0, 1.0, 0.55)
const THEMED_BACK: Color = Color(0.89, 0.88, 0.93)
const THEMED_INK: Color = Color(0.25, 0.28, 0.35)
const SHEET_MARGIN: int = 24


## One layer of the foreground, drawn in viewport px. Which parts it draws:
##   COLOR: rope, tiles with lips, the ring on B, labels in ink
##   SILHOUETTE: rope and both tile shapes (lip and face) in white
##   LABELS: only the two labels, in white
class IconArt extends Node2D:
	const COLOR: int = 0
	const SILHOUETTE: int = 1
	const LABELS: int = 2
	## StyleBoxFlat's highest corner detail. Without antialiasing the corners
	## are exact polygons; supersampling smooths them.
	const CORNER_DETAIL: int = 20

	var layer: int = COLOR
	## Layer px at the viewport's top left corner, and viewport px per layer px.
	var origin: Vector2 = Vector2.ZERO
	var px_per_unit: float = 1.0
	var fill: Color = Color.MAGENTA
	var lip: Color = Color.MAGENTA
	var ink: Color = Color.MAGENTA
	var chain: Color = Color.MAGENTA
	var radius_share: float = 0.0
	var font: Font = null
	var label: String = ""
	var label_size: int = 1
	## Middle of the label's ink box, from the pen position on the baseline.
	var label_middle: Vector2 = Vector2.ZERO

	var _box: StyleBoxFlat = null
	var _ring: StyleBoxFlat = null


	## Reads everything from the skin. Returns an error text, or "" when ready.
	func setup(skin: SkinData, p_layer: int, p_origin: Vector2, p_px_per_unit: float) -> String:
		layer = p_layer
		origin = p_origin
		px_per_unit = p_px_per_unit
		fill = skin.fill_for(TILE_EXPONENT)
		lip = fill.darkened(skin.num(&"lip_darken"))
		ink = skin.ink_for(TILE_EXPONENT)
		chain = skin.color(&"chain")
		radius_share = skin.num(&"tile_radius")
		font = skin.font(&"tile")
		label = NumberFormat.tile_label(TILE_EXPONENT)
		label_size = roundi(float(skin.tile_font_size(TILE_SIDE, label)) * px_per_unit)
		_box = StyleBoxFlat.new()
		_box.anti_aliasing = false
		_box.corner_detail = CORNER_DETAIL
		_ring = _box.duplicate() as StyleBoxFlat
		_ring.draw_center = false
		_ring.border_color = chain
		return _measure_label()


	func _draw() -> void:
		if layer != LABELS:
			var rope_color: Color = Color.WHITE if layer == SILHOUETTE else chain
			var a: Vector2 = _px(TILE_A_CENTER)
			var b: Vector2 = _px(TILE_B_CENTER)
			var half_width: float = ROPE_WIDTH * 0.5 * px_per_unit
			draw_line(a, b, rope_color, ROPE_WIDTH * px_per_unit)
			draw_circle(a, half_width, rope_color)
			draw_circle(b, half_width, rope_color)
		_draw_tile(TILE_A_CENTER, TILE_A_TURN, false)
		_draw_tile(TILE_B_CENTER, TILE_B_TURN, true)


	## One Gumdrop tile, as DESIGN_SYSTEM.md 4.7 draws it: the lip is the
	## full tile shape, the face sits on top of it raised by the lip depth, so
	## the lip shows along the tile's bottom. Both turn with the tile.
	func _draw_tile(center: Vector2, turn_degrees: float, chained: bool) -> void:
		draw_set_transform(_px(center), deg_to_rad(turn_degrees), Vector2.ONE)
		var side: float = TILE_SIDE * px_per_unit
		var half: float = side * 0.5
		var radius: float = radius_share * side
		var body: Rect2 = Rect2(-half, -half, side, side)
		var face: Rect2 = Rect2(-half, -half, side, side - TILE_LIP * side)
		if layer == SILHOUETTE:
			_fill_box(body, radius, Color.WHITE)
		elif layer == COLOR:
			_fill_box(body, radius, lip)
			_fill_box(face, radius, fill)
			if chained:
				var width: float = RING_WIDTH * px_per_unit
				_ring.set_border_width_all(roundi(width))
				_ring.set_corner_radius_all(roundi(radius + width))
				_ring.draw(get_canvas_item(), face.grow(width))
		if layer != SILHOUETTE:
			var label_color: Color = ink if layer == COLOR else Color.WHITE
			draw_string(font, face.get_center() - label_middle, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_size, label_color)
		draw_set_transform_matrix(Transform2D.IDENTITY)


	func _fill_box(rect: Rect2, radius: float, color: Color) -> void:
		_box.bg_color = color
		_box.set_corner_radius_all(roundi(radius))
		_box.draw(get_canvas_item(), rect)


	func _px(point: Vector2) -> Vector2:
		return (point - origin) * px_per_unit


	## Finds the middle of the label's ink box from the glyph outlines at the
	## size it is drawn, so the digit sits visually centered on the face.
	func _measure_label() -> String:
		var server: TextServer = TextServerManager.get_primary_interface()
		var rids: Array[RID] = font.get_rids()
		if rids.is_empty():
			return "the tile font has no font data"
		var low: Vector2 = Vector2(INF, INF)
		var high: Vector2 = Vector2(-INF, -INF)
		var pen_x: float = 0.0
		for i: int in label.length():
			var glyph: int = server.font_get_glyph_index(rids[0], label_size, label.unicode_at(i), 0)
			if glyph == 0:
				return "the tile font has no glyph for '%s'" % label[i]
			var outline: Dictionary = server.font_get_glyph_contours(rids[0], label_size, glyph)
			var points: PackedVector3Array = outline.get("points", PackedVector3Array())
			if points.is_empty():
				return "no outline for '%s'" % label[i]
			for point: Vector3 in points:
				low = Vector2(minf(low.x, pen_x + point.x), minf(low.y, point.y))
				high = Vector2(maxf(high.x, pen_x + point.x), maxf(high.y, point.y))
			pen_x += font.get_char_size(label.unicode_at(i), label_size).x
		label_middle = (low + high) * 0.5
		return ""


var _skin: SkinData = null


func _ready() -> void:
	var exit_code: int = await _run()
	get_tree().quit(exit_code)


func _run() -> int:
	var problem: String = _load_skin()
	if not problem.is_empty():
		print("launcher icon: FAIL %s" % problem)
		return 1
	print("launcher icon: colors, radius, lip, font and label size from %s" % _skin.resource_path)

	var layer_px: float = float(LAYER_SIZE)
	var visible_origin: Vector2 = SAFE_CENTER - Vector2.ONE * VISIBLE_SIDE * 0.5
	var foreground: PackedFloat32Array = await _render(IconArt.COLOR, Vector2.ZERO, layer_px, LAYER_SIZE)
	var silhouette: PackedFloat32Array = await _render(IconArt.SILHOUETTE, Vector2.ZERO, layer_px, LAYER_SIZE)
	var labels: PackedFloat32Array = await _render(IconArt.LABELS, Vector2.ZERO, layer_px, LAYER_SIZE)
	var legacy_front: PackedFloat32Array = await _render(IconArt.COLOR, visible_origin, VISIBLE_SIDE, LEGACY_SIZE)
	var store_front: PackedFloat32Array = await _render(IconArt.COLOR, visible_origin, VISIBLE_SIDE, STORE_ICON_SIZE)
	for pixels: PackedFloat32Array in [foreground, silhouette, labels, legacy_front, store_front]:
		if pixels.is_empty():
			print("launcher icon: FAIL a layer did not render at the expected size")
			return 1

	var background: PackedFloat32Array = _background(Vector2.ZERO, layer_px, LAYER_SIZE)
	var monochrome: PackedFloat32Array = _cut_out(silhouette, labels)
	var legacy: PackedFloat32Array = _over(legacy_front, _background(visible_origin, VISIBLE_SIDE, LEGACY_SIZE))
	_round_corners(legacy, LEGACY_SIZE, LEGACY_CORNER)

	var failed: int = 0
	for entry: Array in [["foreground", foreground], ["monochrome", monochrome]]:
		var reach: float = _reach(entry[1] as PackedFloat32Array, LAYER_SIZE)
		var inside: bool = reach <= SAFE_RADIUS
		if not inside:
			failed += 1
		print("%s %s reaches %.1f px from the center; the 66 dp safe circle is %d px" % [
			"PASS" if inside else "FAIL", entry[0], reach, int(SAFE_RADIUS)])

	var files: Dictionary[String, Image] = {
		"main_192.png": _to_image(legacy, LEGACY_SIZE, false),
		"adaptive_foreground_432.png": _to_image(foreground, LAYER_SIZE, false),
		"adaptive_background_432.png": _to_image(background, LAYER_SIZE, true),
		"adaptive_monochrome_432.png": _to_image(monochrome, LAYER_SIZE, false),
	}
	# A layout that leaves the safe circle never replaces the icon in launcher/.
	if failed == 0:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
		for file_name: String in files.keys():
			var path: String = ProjectSettings.globalize_path(OUTPUT_DIR.path_join(file_name))
			if not _save(files[file_name], path):
				failed += 1
		# Opaque, but kept RGBA: Play asks for a 32 bit PNG.
		var store: PackedFloat32Array = _over(store_front, _background(visible_origin, VISIBLE_SIDE, STORE_ICON_SIZE))
		var store_path: String = ProjectSettings.globalize_path(STORE_ICON_PATH)
		DirAccess.make_dir_recursive_absolute(store_path.get_base_dir())
		if not _save(_to_image(store, STORE_ICON_SIZE, false), store_path):
			failed += 1
	else:
		print("launcher/ and the store icon left as they were, because the foreground leaves the safe circle")

	var sheet: Image = _review_sheet(foreground, background, files["main_192.png"], monochrome)
	var review_path: String = ProjectSettings.globalize_path(REVIEW_PATH)
	DirAccess.make_dir_recursive_absolute(review_path.get_base_dir())
	if sheet.save_png(review_path) == OK:
		print("review sheet %s (%dx%d)" % [review_path, sheet.get_width(), sheet.get_height()])
	else:
		print("FAIL could not write the review sheet %s" % review_path)
		failed += 1

	print("launcher icon: %s, %d problems." % ["PASS" if failed == 0 else "FAIL", failed])
	return 0 if failed == 0 else 1


func _load_skin() -> String:
	_skin = SkinCatalog.get_skin(SKIN_ID)
	if _skin == null or _skin.id != SKIN_ID:
		return "could not load the %s skin" % SKIN_ID
	var problems: PackedStringArray = _skin.validate()
	if not problems.is_empty():
		return "the %s skin is incomplete: %s" % [SKIN_ID, ", ".join(problems)]
	for token: StringName in [&"tile_radius", &"lip_darken"]:
		if not _skin.numbers.has(token):
			return "the %s skin has no %s" % [SKIN_ID, token]
	# Without its font file the skin falls back to the system font; the icon
	# must not ship like that.
	var tile_font: FontVariation = _skin.font(&"tile") as FontVariation
	if _skin.font_path.is_empty() or tile_font == null or not (tile_font.base_font is FontFile):
		return "the tile font is not the skin's font file %s" % _skin.font_path
	return ""


## Renders one layer of the square that starts at origin (layer px) and is
## span layer px wide, out_size px across. Returns straight alpha RGBA, 4
## floats per pixel, or an empty array when the render went wrong.
func _render(layer: int, origin: Vector2, span: float, out_size: int) -> PackedFloat32Array:
	var size: int = out_size * SUPERSAMPLE
	var art: IconArt = IconArt.new()
	var problem: String = art.setup(_skin, layer, origin, float(size) / span)
	if not problem.is_empty():
		print("launcher icon: FAIL %s" % problem)
		art.free()
		return PackedFloat32Array()
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(size, size)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.msaa_2d = Viewport.MSAA_DISABLED
	viewport.oversampling_override = 1.0
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.add_child(art)
	add_child(viewport)
	for _frame: int in WAIT_FRAMES:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	if image == null or image.get_size() != Vector2i(size, size):
		return PackedFloat32Array()
	return _average(image, SUPERSAMPLE)


## Averages each factor by factor block into one pixel, weighting color by
## coverage so edges on transparent never darken. Straight alpha out.
static func _average(image: Image, factor: int) -> PackedFloat32Array:
	image.convert(Image.FORMAT_RGBA8)
	var src: PackedByteArray = image.get_data()
	var src_width: int = image.get_width()
	@warning_ignore("integer_division")
	var width: int = src_width / factor
	@warning_ignore("integer_division")
	var height: int = image.get_height() / factor
	var samples: float = float(factor * factor) * 255.0
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(width * height * 4)
	for y: int in height:
		for x: int in width:
			var r: int = 0
			var g: int = 0
			var b: int = 0
			var a: int = 0
			for sy: int in factor:
				var i: int = ((y * factor + sy) * src_width + x * factor) * 4
				for _sx: int in factor:
					var alpha: int = src[i + 3]
					r += src[i] * alpha
					g += src[i + 1] * alpha
					b += src[i + 2] * alpha
					a += alpha
					i += 4
			var o: int = (y * width + x) * 4
			if a > 0:
				var weight: float = 1.0 / (float(a) * 255.0)
				out[o] = float(r) * weight
				out[o + 1] = float(g) * weight
				out[o + 2] = float(b) * weight
			out[o + 3] = float(a) / samples
	return out


## The background glow for the square that starts at origin (layer px) and
## is span layer px wide, out_size px across: surface at GLOW_CENTER fading
## smoothly to bg at GLOW_RADIUS and beyond. Opaque.
func _background(origin: Vector2, span: float, out_size: int) -> PackedFloat32Array:
	var bg: Color = _skin.color(&"bg")
	var glow: Color = _skin.color(&"surface")
	var step: float = span / float(out_size)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(out_size * out_size * 4)
	for y: int in out_size:
		for x: int in out_size:
			var point: Vector2 = origin + Vector2(float(x) + 0.5, float(y) + 0.5) * step
			var t: float = clampf(point.distance_to(GLOW_CENTER) / GLOW_RADIUS, 0.0, 1.0)
			var color: Color = glow.lerp(bg, t * t * (3.0 - 2.0 * t))
			var o: int = (y * out_size + x) * 4
			out[o] = color.r
			out[o + 1] = color.g
			out[o + 2] = color.b
			out[o + 3] = 1.0
	return out


## White silhouettes with the labels cut out. The labels lie inside the
## silhouettes, so coverage subtracts.
static func _cut_out(silhouette: PackedFloat32Array, labels: PackedFloat32Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(silhouette.size())
	for o: int in range(0, silhouette.size(), 4):
		var alpha: float = clampf(silhouette[o + 3] - labels[o + 3], 0.0, 1.0)
		out[o] = 1.0
		out[o + 1] = 1.0
		out[o + 2] = 1.0
		out[o + 3] = alpha
	return out


## front over an opaque back, in sRGB like Godot's 2D blending. Opaque out.
static func _over(front: PackedFloat32Array, back: PackedFloat32Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(back.size())
	for o: int in range(0, back.size(), 4):
		var a: float = front[o + 3]
		for c: int in 3:
			out[o + c] = front[o + c] * a + back[o + c] * (1.0 - a)
		out[o + 3] = 1.0
	return out


## Multiplies alpha by the coverage of a rounded square filling the image,
## its corner radius corner_share of the side (0.5 is a circle).
static func _round_corners(pixels: PackedFloat32Array, size: int, corner_share: float) -> void:
	for y: int in size:
		for x: int in size:
			var o: int = (y * size + x) * 4
			pixels[o + 3] *= _coverage(Vector2(float(x) + 0.5, float(y) + 0.5), float(size), corner_share)


## How much of the pixel at point lies inside a rounded square of side
## side at the origin, from its signed distance: 1 inside, 0 outside, a one
## pixel ramp across the edge.
static func _coverage(point: Vector2, side: float, corner_share: float) -> float:
	var half: float = side * 0.5
	var radius: float = corner_share * side
	var q: Vector2 = (point - Vector2(half, half)).abs() - Vector2(half - radius, half - radius)
	var distance: float = Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - radius
	return clampf(0.5 - distance, 0.0, 1.0)


## Farthest painted pixel center from the middle of the layer, in layer px.
static func _reach(pixels: PackedFloat32Array, size: int) -> float:
	var reach: float = 0.0
	for y: int in size:
		for x: int in size:
			if pixels[(y * size + x) * 4 + 3] > 0.0:
				reach = maxf(reach, Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(SAFE_CENTER))
	return reach


## 8 bit image from float pixels, rounded to the nearest step.
static func _to_image(pixels: PackedFloat32Array, size: int, opaque: bool) -> Image:
	var channels: int = 3 if opaque else 4
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(size * size * channels)
	for p: int in size * size:
		for c: int in channels:
			bytes[p * channels + c] = roundi(clampf(pixels[p * 4 + c], 0.0, 1.0) * 255.0)
	return Image.create_from_data(size, size, false, Image.FORMAT_RGB8 if opaque else Image.FORMAT_RGBA8, bytes)


func _save(image: Image, path: String) -> bool:
	var err: Error = image.save_png(path)
	if err != OK:
		print("FAIL could not write %s (error %d)" % [path, err])
		return false
	var bytes: int = FileAccess.get_file_as_bytes(path).size()
	print("ok   %s %dx%d, %d bytes, sha256 %s" % [path, image.get_width(), image.get_height(), bytes, FileAccess.get_sha256(path)])
	return true


## Review sheet, left to right: the foreground over the background with the
## 66 dp safe circle (green) and the 72 dp visible square (white); the
## visible area in a round mask, as a launcher shows it; main_192.png; the
## monochrome layer as a themed icon; and the round icon at 144 and 72 px.
func _review_sheet(foreground: PackedFloat32Array, background: PackedFloat32Array, legacy: Image, monochrome: PackedFloat32Array) -> Image:
	var layer: Image = _to_image(_over(foreground, background), LAYER_SIZE, false)
	var visible_start: int = roundi(SAFE_CENTER.x - VISIBLE_SIDE * 0.5)
	var visible_rect: Rect2i = Rect2i(visible_start, visible_start, int(VISIBLE_SIDE), int(VISIBLE_SIDE))
	var round_icon: Image = _masked(layer.get_region(visible_rect), 0.5)

	var themed: Image = Image.create_empty(LAYER_SIZE, LAYER_SIZE, false, Image.FORMAT_RGBA8)
	for y: int in LAYER_SIZE:
		for x: int in LAYER_SIZE:
			themed.set_pixel(x, y, THEMED_BACK.lerp(THEMED_INK, monochrome[(y * LAYER_SIZE + x) * 4 + 3]))
	var themed_icon: Image = _masked(themed.get_region(visible_rect), 0.5)

	var guides: Image = layer.duplicate() as Image
	_draw_ring(guides, SAFE_CENTER, SAFE_RADIUS, 2.0, GUIDE_SAFE)
	_draw_square(guides, Rect2(visible_rect), GUIDE_VISIBLE)

	var small: Array[Image] = []
	for size: int in [144, 72]:
		var scaled: Image = layer.get_region(visible_rect)
		scaled.resize(size, size, Image.INTERPOLATE_LANCZOS)
		small.append(_masked(scaled, 0.5))

	var width: int = SHEET_MARGIN * 6 + LAYER_SIZE + int(VISIBLE_SIDE) * 2 + LEGACY_SIZE + 144
	var height: int = SHEET_MARGIN * 2 + LAYER_SIZE
	var sheet: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	sheet.fill(SHEET_COLOR)
	var x: int = SHEET_MARGIN
	var top: int = SHEET_MARGIN
	var middle: int = SHEET_MARGIN + int(LAYER_SIZE * 0.5)
	for item: Image in [guides, round_icon, legacy, themed_icon]:
		var y: int = top if item.get_height() == LAYER_SIZE else middle - int(item.get_height() * 0.5)
		sheet.blend_rect(item, Rect2i(Vector2i.ZERO, item.get_size()), Vector2i(x, y))
		x += item.get_width() + SHEET_MARGIN
	sheet.blend_rect(small[0], Rect2i(Vector2i.ZERO, small[0].get_size()), Vector2i(x, middle - 144 - int(SHEET_MARGIN * 0.5)))
	sheet.blend_rect(small[1], Rect2i(Vector2i.ZERO, small[1].get_size()), Vector2i(x + 36, middle + int(SHEET_MARGIN * 0.5)))
	sheet.convert(Image.FORMAT_RGB8)
	return sheet


## A copy with alpha cut to a rounded square filling the image.
static func _masked(image: Image, corner_share: float) -> Image:
	var out: Image = image.duplicate() as Image
	out.convert(Image.FORMAT_RGBA8)
	var side: float = float(out.get_width())
	for y: int in out.get_height():
		for x: int in out.get_width():
			var color: Color = out.get_pixel(x, y)
			color.a *= _coverage(Vector2(float(x) + 0.5, float(y) + 0.5), side, corner_share)
			out.set_pixel(x, y, color)
	return out


## Blends a circle outline, width px wide, into an image.
static func _draw_ring(image: Image, center: Vector2, radius: float, width: float, color: Color) -> void:
	for y: int in image.get_height():
		for x: int in image.get_width():
			var distance: float = absf(Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(center) - radius)
			var cover: float = clampf(width * 0.5 + 0.5 - distance, 0.0, 1.0)
			if cover > 0.0:
				var under: Color = image.get_pixel(x, y)
				image.set_pixel(x, y, under.lerp(color, cover * color.a))


## Blends a one px square outline into an image.
static func _draw_square(image: Image, rect: Rect2, color: Color) -> void:
	var left: int = int(rect.position.x)
	var right: int = int(rect.end.x) - 1
	var top: int = int(rect.position.y)
	var bottom: int = int(rect.end.y) - 1
	for i: int in range(left, right + 1):
		for y: int in [top, bottom]:
			image.set_pixel(i, y, image.get_pixel(i, y).lerp(color, color.a))
	for i: int in range(top + 1, bottom):
		for x: int in [left, right]:
			image.set_pixel(x, i, image.get_pixel(x, i).lerp(color, color.a))
