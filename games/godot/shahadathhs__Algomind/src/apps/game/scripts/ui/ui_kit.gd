class_name UiKit
extends RefCounted
## Drawing helpers for the Instruction Tape look: chamfered tiles, hatching, icons, text.
## Every color comes from Palette. No gradients, shadows, or glow exist here by design.

const FONT_PATH := "res://assets/fonts/BarlowCondensed-Bold.ttf"
## Chamfer size as a share of the shorter side (docs/README_VISUAL_DESIGN.md section 4).
const CHAMFER := 0.2
const CHAMFER_MAX := 14.0

static var _fonts := {}


## The UI font with letter spacing in pixels and tabular numerals.
static func font(spacing: int = 0) -> Font:
	if not _fonts.has(spacing):
		var variation := FontVariation.new()
		variation.base_font = load(FONT_PATH)
		variation.spacing_glyph = spacing
		variation.opentype_features = {"tnum": 1}
		_fonts[spacing] = variation
	return _fonts[spacing]


static func chamfer_size(rect: Rect2) -> float:
	return minf(minf(rect.size.x, rect.size.y) * CHAMFER, CHAMFER_MAX)


## Square with the top-right corner cut at 45 degrees.
static func chamfer_points(rect: Rect2, cut: float = -1.0) -> PackedVector2Array:
	var c := chamfer_size(rect) if cut < 0.0 else cut
	var right := rect.position.x + rect.size.x
	var bottom := rect.position.y + rect.size.y
	return PackedVector2Array(
		[
			rect.position,
			Vector2(right - c, rect.position.y),
			Vector2(right, rect.position.y + c),
			Vector2(right, bottom),
			Vector2(rect.position.x, bottom),
		]
	)


static func fill_chamfer(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_colored_polygon(chamfer_points(rect), color)


## A 2 px outline drawn inside the rect.
static func outline_chamfer(
	canvas: CanvasItem, rect: Rect2, color: Color, width: float = 2.0, dashed: bool = false
) -> void:
	var inset := rect.grow(-width / 2.0)
	var points := chamfer_points(inset, maxf(chamfer_size(rect) - width / 2.0, 0.0))
	points.append(points[0])
	if dashed:
		for i in points.size() - 1:
			canvas.draw_dashed_line(points[i], points[i + 1], color, width, 6.0)
	else:
		canvas.draw_polyline(points, color, width)


## Diagonal stripes ("/") of horizontal thickness `width`, clipped to the rect.
static func hatch(
	canvas: CanvasItem, rect: Rect2, color: Color, spacing: float, width: float
) -> void:
	var w := rect.size.x
	var h := rect.size.y
	var box := PackedVector2Array(
		[
			rect.position,
			rect.position + Vector2(w, 0),
			rect.position + Vector2(w, h),
			rect.position + Vector2(0, h),
		]
	)
	var t := -h
	while t < w:
		var stripe := PackedVector2Array(
			[
				rect.position + Vector2(t, h),
				rect.position + Vector2(t + width, h),
				rect.position + Vector2(t + width + h, 0),
				rect.position + Vector2(t + h, 0),
			]
		)
		for piece in Geometry2D.intersect_polygons(stripe, box):
			canvas.draw_colored_polygon(piece, color)
		t += spacing


## Text centered in a rect, both ways.
static func text(
	canvas: CanvasItem,
	value: String,
	rect: Rect2,
	size: int,
	color: Color,
	spacing: int = 1,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
) -> void:
	if size <= 0 or rect.size.x <= 0.0:
		return
	var f := font(spacing)
	var y := rect.position.y + (rect.size.y - f.get_height(size)) / 2.0 + f.get_ascent(size)
	canvas.draw_string(f, Vector2(rect.position.x, y), value, align, rect.size.x, size, color)


static func text_width(value: String, size: int, spacing: int = 1) -> float:
	return font(spacing).get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func label(value: String, size: int, color: Color, spacing: int = 1) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_override("font", font(spacing))
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Draws a command or control icon inside a square of side `s` centered on `c`.
## Kinds: move, left, right, back, play, pause, step, reset, plus, x, check, lock, prev, next,
## menu, help, download, up, offline, star, repeat, until, and the IfIcons, ProcIcons and
## MarkerIcons kinds.
static func icon(canvas: CanvasItem, kind: String, c: Vector2, s: float, color: Color) -> void:
	var w := maxf(2.0, s * 0.12)
	match kind:
		"move":
			canvas.draw_rect(Rect2(c.x - s * 0.1, c.y - s * 0.05, s * 0.2, s * 0.45), color)
			_triangle(canvas, c + Vector2(0, -s * 0.45), Vector2(0, 1), s * 0.62, s * 0.5, color)
		"left", "right":
			var dir_sign := -1.0 if kind == "left" else 1.0
			var corner := Vector2(c.x - dir_sign * s * 0.2, c.y - s * 0.12)
			canvas.draw_line(
				Vector2(corner.x, c.y + s * 0.4), corner + Vector2(0, w * 0.5), color, w
			)
			canvas.draw_line(corner, corner + Vector2(dir_sign * s * 0.4, 0), color, w)
			_triangle(
				canvas,
				corner + Vector2(dir_sign * s * 0.62, 0),
				Vector2(-dir_sign, 0),
				s * 0.56,
				s * 0.44,
				color
			)
		"back", "prev", "next":
			var d := 1.0 if kind == "next" else -1.0
			(
				canvas
				. draw_polyline(
					PackedVector2Array(
						[
							c + Vector2(-d * s * 0.14, -s * 0.32),
							c + Vector2(d * s * 0.14, 0),
							c + Vector2(-d * s * 0.14, s * 0.32),
						]
					),
					color,
					w * 1.3
				)
			)
		"play":
			_triangle(canvas, c + Vector2(s * 0.4, 0), Vector2(-1, 0), s * 0.7, s * 0.7, color)
		"pause":
			canvas.draw_rect(Rect2(c.x - s * 0.3, c.y - s * 0.32, s * 0.22, s * 0.64), color)
			canvas.draw_rect(Rect2(c.x + s * 0.08, c.y - s * 0.32, s * 0.22, s * 0.64), color)
		"step":
			canvas.draw_rect(Rect2(c.x + s * 0.18, c.y - s * 0.32, s * 0.16, s * 0.64), color)
			_triangle(canvas, c + Vector2(s * 0.12, 0), Vector2(-1, 0), s * 0.55, s * 0.6, color)
		"reset":
			var points := PackedVector2Array()
			for i in 21:
				var angle := deg_to_rad(-130.0 + 260.0 * float(i) / 20.0)
				points.append(c + Vector2(-cos(angle), sin(angle)) * s * 0.34)
			canvas.draw_polyline(points, color, w)
			var end := points[points.size() - 1]
			var tangent := Vector2(-sin(deg_to_rad(130.0)), -cos(deg_to_rad(130.0)))
			_triangle(canvas, end + tangent * s * 0.14, -tangent, s * 0.36, s * 0.34, color)
		"plus":
			canvas.draw_rect(Rect2(c.x - s * 0.3, c.y - w / 2.0, s * 0.6, w), color)
			canvas.draw_rect(Rect2(c.x - w / 2.0, c.y - s * 0.3, w, s * 0.6), color)
		"minus":
			canvas.draw_rect(Rect2(c.x - s * 0.3, c.y - w / 2.0, s * 0.6, w), color)
		"repeat":
			# Two arrows chasing each other: one to the right above, one to the left below.
			var rise := s * 0.2
			canvas.draw_line(
				Vector2(c.x - s * 0.36, c.y - rise), Vector2(c.x + s * 0.16, c.y - rise), color, w
			)
			_triangle(
				canvas,
				Vector2(c.x + s * 0.42, c.y - rise),
				Vector2(-1, 0),
				s * 0.34,
				s * 0.36,
				color
			)
			canvas.draw_line(
				Vector2(c.x + s * 0.36, c.y + rise), Vector2(c.x - s * 0.16, c.y + rise), color, w
			)
			_triangle(
				canvas,
				Vector2(c.x - s * 0.42, c.y + rise),
				Vector2(1, 0),
				s * 0.34,
				s * 0.36,
				color
			)
		"until":
			# An arrow running right into a wall: the loop goes on until the way is blocked.
			canvas.draw_line(c + Vector2(-s * 0.42, 0), c + Vector2(s * 0.1, 0), color, w)
			_triangle(canvas, c + Vector2(s * 0.28, 0), Vector2(-1, 0), s * 0.4, s * 0.34, color)
			canvas.draw_rect(Rect2(c.x + s * 0.34, c.y - s * 0.4, w * 1.3, s * 0.8), color)
		"x":
			canvas.draw_line(
				c + Vector2(-s * 0.3, -s * 0.3), c + Vector2(s * 0.3, s * 0.3), color, w
			)
			canvas.draw_line(
				c + Vector2(s * 0.3, -s * 0.3), c + Vector2(-s * 0.3, s * 0.3), color, w
			)
		"check":
			(
				canvas
				. draw_polyline(
					PackedVector2Array(
						[
							c + Vector2(-s * 0.32, 0),
							c + Vector2(-s * 0.08, s * 0.26),
							c + Vector2(s * 0.34, -s * 0.26),
						]
					),
					color,
					w * 1.2
				)
			)
		"lock":
			canvas.draw_rect(Rect2(c.x - s * 0.3, c.y - s * 0.05, s * 0.6, s * 0.42), color)
			canvas.draw_arc(Vector2(c.x, c.y - s * 0.08), s * 0.2, PI, TAU, 12, color, w * 0.9)
		"menu":
			for i in 3:
				var y := c.y + (float(i) - 1.0) * s * 0.26
				canvas.draw_rect(Rect2(c.x - s * 0.32, y - w / 2.0, s * 0.64, w), color)
		"help":
			text(canvas, "?", Rect2(c.x - s * 0.5, c.y - s * 0.5, s, s), int(s * 1.1), color, 0)
		"download":
			canvas.draw_rect(Rect2(c.x - w / 2.0, c.y - s * 0.4, w, s * 0.46), color)
			_triangle(canvas, c + Vector2(0, s * 0.3), Vector2(0, -1), s * 0.5, s * 0.36, color)
			canvas.draw_rect(Rect2(c.x - s * 0.34, c.y + s * 0.36, s * 0.68, w), color)
		"up":
			canvas.draw_rect(Rect2(c.x - w / 2.0, c.y - s * 0.06, w, s * 0.46), color)
			_triangle(canvas, c + Vector2(0, -s * 0.4), Vector2(0, 1), s * 0.56, s * 0.4, color)
		"star":
			StarGlyph.draw(canvas, c, s * 0.5, color, true)
		"offline":
			for i in 3:
				var radius := s * (0.12 + 0.14 * float(i + 1))
				canvas.draw_arc(
					c + Vector2(0, s * 0.3),
					radius,
					deg_to_rad(-135.0),
					deg_to_rad(-45.0),
					10,
					color,
					w
				)
			canvas.draw_circle(c + Vector2(0, s * 0.3), w * 0.8, color)
			canvas.draw_line(
				c + Vector2(-s * 0.4, -s * 0.34), c + Vector2(s * 0.4, s * 0.4), color, w
			)
		_:
			if not IfIcons.draw(canvas, kind, c, s, color):
				if not ProcIcons.draw(canvas, kind, c, s, color):
					MarkerIcons.draw(canvas, kind, c, s, color)


## A filled triangle: tip point, unit direction pointing from tip toward the base, base width
## `across`, length `length`.
static func _triangle(
	canvas: CanvasItem,
	tip: Vector2,
	toward_base: Vector2,
	across: float,
	length: float,
	color: Color
) -> void:
	var base := tip + toward_base * length
	var side := Vector2(-toward_base.y, toward_base.x) * across / 2.0
	canvas.draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)
