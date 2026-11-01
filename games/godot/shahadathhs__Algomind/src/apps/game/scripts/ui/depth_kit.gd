class_name DepthKit
extends RefCounted
## The depth look's pieces, drawn with _draw() only (no shader): the ground gradient, keys with a
## lip and a soft shadow, and the recessed tape trough. Colors come from DepthPalette and nothing
## here writes a color. Never mix with UiKit's flat tiles on one screen.
## See docs/README_VISUAL_DESIGN.md, section 14.

enum Kind { TILE, SIGNAL, INK }

## Stacked translucent copies make a soft edge; more layers are smoother and cost more draw calls.
const SHADOW_LAYERS := 8
## The visible thickness under a key, as a share of its height, kept between two sizes.
const LIP_RATIO := 0.07
const LIP_MIN := 2.0
const LIP_MAX := 4.0
const SHADOW_ALPHA := 0.26
const TROUGH_BANDS := 5
const TROUGH_BAND_HEIGHT := 2.0
const TROUGH_SHADE := 0.32
const TROUGH_LIGHT := 0.14


## Thickness of the lip under a key of this size.
static func lip_height(rect: Rect2) -> float:
	return clampf(rect.size.y * LIP_RATIO, LIP_MIN, LIP_MAX)


## Vertical gradient from the top to the bottom ground color, drawn with per-vertex colors.
static func ground(canvas: CanvasItem, rect: Rect2) -> void:
	var top := DepthPalette.GROUND_TOP
	var bottom := DepthPalette.GROUND_BOTTOM
	var corners := PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		]
	)
	canvas.draw_polygon(corners, PackedColorArray([top, top, bottom, bottom]))


## The polygons of a soft shadow, outermost first: the shape moved by `offset`, grown by up to
## `spread`. Pure, so it can be tested.
static func shadow_polygons(
	points: PackedVector2Array, offset: Vector2, spread: float, layers: int = SHADOW_LAYERS
) -> Array[PackedVector2Array]:
	var moved := PackedVector2Array()
	for point in points:
		moved.append(point + offset)
	var result: Array[PackedVector2Array] = []
	for i in range(layers, 0, -1):
		var grown := Geometry2D.offset_polygon(
			moved, spread * float(i) / float(layers), Geometry2D.JOIN_ROUND
		)
		for polygon in grown:
			result.append(polygon)
	return result


## A soft shadow under a shape. `alpha` is the total opacity at the center, shared by the layers.
static func soft_shadow(
	canvas: CanvasItem,
	points: PackedVector2Array,
	offset: Vector2,
	spread: float,
	alpha: float = SHADOW_ALPHA,
	layers: int = SHADOW_LAYERS
) -> void:
	var color := DepthPalette.SHADOW
	color.a = alpha / float(layers)
	for polygon in shadow_polygons(points, offset, spread, layers):
		canvas.draw_colored_polygon(polygon, color)


## Color of a label or icon on a key of this kind.
static func label_color(kind: Kind) -> Color:
	match kind:
		Kind.SIGNAL:
			return DepthPalette.ON_SIGNAL
		Kind.INK:
			return DepthPalette.ON_INK
		_:
			return DepthPalette.INK


## The face of a key inside its rect (the rect includes the lip under the face).
static func face_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position, Vector2(rect.size.x, rect.size.y - lip_height(rect)))


## A key: a soft shadow, the lip, and the chamfered face. A pressed key sinks onto its lip and
## casts a smaller shadow. Returns the face rect, where the label and icon go.
static func key(
	canvas: CanvasItem, rect: Rect2, kind: Kind = Kind.TILE, pressed: bool = false
) -> Rect2:
	return key_sunk(canvas, rect, kind, 1.0 if pressed else 0.0)


## The same key sunk by `sink`: 0 is up, 1 is pressed all the way onto its lip (a press eases
## between the two).
static func key_sunk(
	canvas: CanvasItem, rect: Rect2, kind: Kind = Kind.TILE, sink: float = 0.0
) -> Rect2:
	var lip := lip_height(rect)
	var face := face_rect(rect)
	face.position.y += lip * sink
	var face_color: Color
	var lip_color: Color
	match kind:
		Kind.SIGNAL:
			face_color = DepthPalette.SIGNAL
			lip_color = DepthPalette.SIGNAL_LIP
		Kind.INK:
			face_color = DepthPalette.INK
			lip_color = DepthPalette.INK_LIP
		_:
			face_color = DepthPalette.TILE
			lip_color = DepthPalette.TILE_LIP
	# The base (shadow and lip) stays put; only the face sinks onto it.
	var rest := UiKit.chamfer_points(face_rect(rect))
	var offset := Vector2(0.0, lerpf(lip * 1.8, lip, sink))
	soft_shadow(canvas, rest, offset, lerpf(lip * 2.6, lip * 1.6, sink))
	var under := PackedVector2Array()
	for point in rest:
		under.append(point + Vector2(0.0, lip))
	canvas.draw_colored_polygon(under, lip_color)
	var outline := UiKit.chamfer_points(face)
	canvas.draw_colored_polygon(outline, face_color)
	return face


## The recessed tape trough: a strip with a soft inner shadow along the top and a lit lower edge.
static func trough(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, DepthPalette.STRIP)
	var shade := DepthPalette.SHADOW
	for i in TROUGH_BANDS:
		shade.a = TROUGH_SHADE * (1.0 - float(i) / float(TROUGH_BANDS))
		var band := Rect2(
			rect.position + Vector2(0.0, float(i) * TROUGH_BAND_HEIGHT),
			Vector2(rect.size.x, TROUGH_BAND_HEIGHT)
		)
		canvas.draw_rect(band, shade)
	var light := DepthPalette.ON_INK
	light.a = TROUGH_LIGHT
	canvas.draw_rect(Rect2(rect.position.x, rect.end.y - 1.0, rect.size.x, 1.0), light)


## An extruded piece from a footprint in board units: the side faces the camera sees, then the top
## with a lit edge. Returns the top face as screen points.
static func prism(
	canvas: CanvasItem,
	view: BoardProjection,
	footprint: PackedVector2Array,
	z_low: float,
	z_high: float,
	colors: Dictionary
) -> PackedVector2Array:
	var points := footprint
	if _signed_area(points) < 0.0:
		points = PackedVector2Array()
		for i in range(footprint.size() - 1, -1, -1):
			points.append(footprint[i])
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var along := b - a
		var normal := Vector2(along.y, -along.x).normalized()
		var middle := (a + b) / 2.0
		if not view.sees(middle.x, middle.y, normal.x, normal.y):
			continue
		var face := PackedVector2Array(
			[
				view.project(a.x, a.y, z_high),
				view.project(b.x, b.y, z_high),
				view.project(b.x, b.y, z_low),
				view.project(a.x, a.y, z_low),
			]
		)
		canvas.draw_colored_polygon(face, colors["side"] if normal.x > 0.3 else colors["front"])
	var top := PackedVector2Array()
	for point in points:
		top.append(view.project(point.x, point.y, z_high))
	canvas.draw_colored_polygon(top, colors["top"])
	var closed := top.duplicate()
	closed.append(top[0])
	canvas.draw_polyline(closed, colors["edge"], 1.0)
	return top


## Twice the signed area of a polygon; positive when it runs clockwise on screen (y down).
static func _signed_area(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		total += a.x * b.y - b.x * a.y
	return total
