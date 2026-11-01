# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name IconArt
extends RefCounted
## The launcher and store icon, drawn in code (docs/art/THEME.md).
##
## A road comes out of the night thicket and forks around a lantern-lit Sling
## Post. A gate closes the left branch, night creatures walk the right one,
## and the tower's shot puffs one into sparkles. A tower, enemies on a road
## and a shot say "tower defense"; the fork and the gate say what is new.
##
## paint() draws onto any canvas. draw() and draw_layer() render an Image.
## They need a rendering display (not --headless) and must be awaited:
##     var image: Image = await IconArt.draw(512)

enum Layer { FULL, FOREGROUND, BACKGROUND, MONOCHROME }

## Android adaptive icons show the middle 72 of 108 dp; content stays in it.
const ADAPTIVE_VIEW: float = 72.0 / 108.0

const NO_FLAT: Color = Color(0.0, 0.0, 0.0, 0.0)


## The full icon as an Image of size x size pixels. Await it.
static func draw(size: int) -> Image:
	return await draw_layer(size, Layer.FULL)


## One layer as an Image of size x size pixels, straight (not premultiplied)
## alpha. Renders at twice the size and scales down for smooth edges. Await it.
static func draw_layer(size: int, layer: Layer) -> Image:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var big: int = size * 2
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(big, big)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var node: Node2D = Node2D.new()
	node.draw.connect(func() -> void: paint(node, Rect2(0.0, 0.0, float(big), float(big)), layer))
	vp.add_child(node)
	tree.root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	_unpremultiply(img)
	return img


## Draws one layer of the icon filling `rect`.
static func paint(canvas: CanvasItem, rect: Rect2, layer: Layer) -> void:
	var content: Rect2 = rect
	if layer != Layer.FULL:
		var side: float = rect.size.x * ADAPTIVE_VIEW
		content = Rect2(rect.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))
	match layer:
		Layer.FULL:
			_background(canvas, rect, content)
			_foreground(canvas, content, NO_FLAT)
		Layer.BACKGROUND:
			_background(canvas, rect, content)
		Layer.FOREGROUND:
			_foreground(canvas, content, NO_FLAT)
		Layer.MONOCHROME:
			_foreground(canvas, content, Color.WHITE)


# Layers. `o` and `s` place content units (0 to 1) on the canvas.

static func _background(canvas: CanvasItem, rect: Rect2, content: Rect2) -> void:
	var o: Vector2 = content.position
	var s: float = content.size.x
	var top: float = rect.position.y
	var stops: Array[float] = [top, o.y + 0.2 * s, o.y + 0.36 * s, o.y + 0.46 * s]
	var sky: Array[Color] = [Palette.SKY_TOP, Palette.SKY_MID, Palette.SKY_LOW, Palette.SKY_GLOW]
	for i: int in 3:
		canvas.draw_polygon(PackedVector2Array([Vector2(rect.position.x, stops[i]), Vector2(rect.end.x, stops[i]), Vector2(rect.end.x, stops[i + 1]), Vector2(rect.position.x, stops[i + 1])]),
			PackedColorArray([sky[i], sky[i], sky[i + 1], sky[i + 1]]))
	canvas.draw_rect(Rect2(rect.position.x, stops[3], rect.size.x, rect.end.y - stops[3]), Palette.SKY_GLOW)
	var pen: InkPen = InkPen.new(canvas)
	pen.begin(o, s)
	for st: Vector2 in [Vector2(0.1, 0.08), Vector2(0.24, 0.17), Vector2(0.66, 0.06), Vector2(0.14, 0.28), Vector2(0.7, 0.24), Vector2(0.93, 0.31)]:
		pen.star(st, 0.014, Palette.STAR)
	pen.glow(Vector2(0.84, 0.13), 0.15, Palette.MOON, 1.2)
	Silhouettes.draw_glyph(canvas, &"moon", o + Vector2(0.84, 0.13) * s, 0.13 * s, NO_FLAT)
	# Far hill, then the meadow down to the bottom edge.
	var far: PackedVector2Array = PackedVector2Array()
	for i: int in 25:
		var t: float = float(i) / 24.0
		far.append(Vector2(lerpf(rect.position.x, rect.end.x, t), o.y + (0.41 - 0.03 * sin(t * 5.0 + 1.0)) * s))
	far.append(rect.end)
	far.append(Vector2(rect.position.x, rect.end.y))
	canvas.draw_colored_polygon(far, Palette.HILL_FAR)
	var meadow: PackedVector2Array = PackedVector2Array()
	for i: int in 25:
		var t: float = float(i) / 24.0
		meadow.append(Vector2(lerpf(rect.position.x, rect.end.x, t), o.y + (0.46 - 0.05 * sin(t * PI) + 0.01 * sin(t * 13.0)) * s))
	meadow.append(rect.end)
	meadow.append(Vector2(rect.position.x, rect.end.y))
	canvas.draw_colored_polygon(meadow, Palette.MEADOW)


static func _foreground(canvas: CanvasItem, content: Rect2, flat: Color) -> void:
	var o: Vector2 = content.position
	var s: float = content.size.x
	var mono: bool = flat.a > 0.0
	var trunk: PackedVector2Array = _curve([Vector2(0.5, 0.16), Vector2(0.5, 0.3), Vector2(0.5, 0.4)], o, s)
	var left: PackedVector2Array = _curve([Vector2(0.5, 0.4), Vector2(0.31, 0.54), Vector2(0.18, 0.76), Vector2(0.1, 1.08)], o, s)
	var right: PackedVector2Array = _curve([Vector2(0.5, 0.4), Vector2(0.69, 0.54), Vector2(0.82, 0.76), Vector2(0.9, 1.08)], o, s)
	if mono:
		# One flat color has no room for a filled road under the creatures,
		# so the road is its outline.
		for outline: PackedVector2Array in _road_outlines([trunk, left, right], 0.07 * s):
			outline.append(outline[0])
			canvas.draw_polyline(outline, flat, 0.024 * s, true)
	else:
		for road: PackedVector2Array in [trunk, left, right]:
			_thick(canvas, road, 0.145 * s, Palette.ROAD_EDGE)
		for road: PackedVector2Array in [trunk, left, right]:
			_thick(canvas, road, 0.115 * s, Palette.ROAD)
		# The route line down the open branch.
		var route: PackedVector2Array = trunk.duplicate()
		route.append_array(right)
		for i: int in range(3, route.size() - 4, 4):
			canvas.draw_line(route[i], route[i + 2], Palette.INK_LINE, 0.026 * s, true)
			canvas.draw_line(route[i], route[i + 2], Palette.ROUTE, 0.013 * s, true)
		_thicket(canvas, o + Vector2(0.5, 0.15) * s, s, flat)
	MapArt.draw_gate_at(canvas, o + Vector2(0.235, 0.6) * s, 0.3 * s, true, MapArt.Gate.CLOSED, flat)
	Silhouettes.draw_enemy(canvas, &"scamp", o + Vector2(0.7, 0.55) * s, 0.2 * s, 0, flat)
	Silhouettes.draw_enemy(canvas, &"scamp", o + Vector2(0.78, 0.79) * s, 0.2 * s, 1, flat)
	var cell: float = 0.52 * s
	var ground: Vector2 = o + Vector2(0.47, 0.99) * s
	Silhouettes.draw_tower(canvas, &"sling_post", 1, -1, ground - Vector2(0.0, Silhouettes.TOWER_GROUND * cell), cell, flat)
	# The shot: a lantern streak from the tower to the first creature, and
	# sparkles where it lands.
	var from: Vector2 = ground + Vector2(0.18 * cell, -0.5 * cell)
	var to: Vector2 = o + Vector2(0.68, 0.52) * s
	if not mono:
		canvas.draw_line(from, to, Color(Palette.LANTERN, 0.35), 0.032 * s, true)
		canvas.draw_line(from.lerp(to, 0.45), to, Palette.LANTERN_CORE, 0.013 * s, true)
	var pen: InkPen = InkPen.new(canvas, flat)
	pen.begin(Vector2.ZERO, 1.0)
	for i: int in 6:
		var a: float = TAU * float(i) / 6.0 + 0.3
		pen.star(to + Vector2(cos(a), sin(a)) * 0.085 * s, 0.03 * s, Palette.SPARKLE if i % 2 == 0 else Palette.SPARKLE_LILAC)


static func _thicket(canvas: CanvasItem, c: Vector2, s: float, flat: Color) -> void:
	var pen: InkPen = InkPen.new(canvas, flat)
	pen.line_px = maxf(1.0, s * 0.006)
	pen.begin(c, s / 100.0)
	for i: int in 5:
		var x: float = -13.0 + float(i) * 6.5
		var r: float = 6.5 + float((i * 7) % 3) * 1.2
		var y: float = -1.0 - absf(float(i) - 2.0) * 1.2
		pen.circle(Vector2(x, y), r, Palette.TREE_DARK if i % 2 == 0 else Palette.HILL_NEAR)
	pen.ellipse(Vector2(0, 3), 7.5, 5.5, Palette.THICKET, false)
	if flat.a <= 0.0:
		for e: Vector2 in [Vector2(-3, 2.5), Vector2(3.5, 4), Vector2(-10.5, -1.5)]:
			for dx: float in [-1.3, 1.3]:
				pen.glow(e + Vector2(dx, 0), 2.4, Palette.EYE, 0.8)
				pen.detail_poly(InkPen.ellipse_pts(e + Vector2(dx, 0), 0.85, 1.05, 8), Palette.EYE)


# Helpers.

static func _curve(ctrl: Array[Vector2], o: Vector2, s: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var n: int = ctrl.size()
	for i: int in n - 1:
		var p0: Vector2 = ctrl[maxi(i - 1, 0)]
		var p1: Vector2 = ctrl[i]
		var p2: Vector2 = ctrl[i + 1]
		var p3: Vector2 = ctrl[mini(i + 2, n - 1)]
		for k: int in 12:
			out.append(o + p1.cubic_interpolate(p2, p0, p3, float(k) / 12.0) * s)
	out.append(o + ctrl[n - 1] * s)
	return out


## The outline of the roads merged into one shape, as closed point loops.
static func _road_outlines(roads: Array[PackedVector2Array], half_width: float) -> Array[PackedVector2Array]:
	var shapes: Array[PackedVector2Array] = []
	for road: PackedVector2Array in roads:
		for part: PackedVector2Array in Geometry2D.offset_polyline(road, half_width, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND):
			shapes.append(part)
	var merged: bool = true
	while merged and shapes.size() > 1:
		merged = false
		for i: int in shapes.size():
			for j: int in range(i + 1, shapes.size()):
				var union: Array[PackedVector2Array] = Geometry2D.merge_polygons(shapes[i], shapes[j])
				if union.size() == 1:
					shapes[i] = union[0]
					shapes.remove_at(j)
					merged = true
					break
			if merged:
				break
	return shapes


static func _thick(canvas: CanvasItem, pts: PackedVector2Array, width: float, col: Color) -> void:
	canvas.draw_polyline(pts, col, width, true)
	canvas.draw_circle(pts[0], width * 0.5, col, true, -1.0, true)
	canvas.draw_circle(pts[pts.size() - 1], width * 0.5, col, true, -1.0, true)


## The viewport stores premultiplied color; turn it back into straight alpha.
static func _unpremultiply(img: Image) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.0 and c.a < 1.0:
				img.set_pixel(x, y, Color(minf(c.r / c.a, 1.0), minf(c.g / c.a, 1.0), minf(c.b / c.a, 1.0), c.a))
