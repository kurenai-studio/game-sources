## A solid world object with an irregular, organic outline. One outline drives the visible
## polygon, the collision and the light occluder, so shadows always match what the player sees.
## Anchors: GROUND top-centre, SLAB centre, PILLAR, BOULDER and ROCK bottom-centre.
class_name SolidProp
extends StaticBody2D

enum Kind { GROUND, SLAB, PILLAR, BOULDER, ROCK }

## Target spacing between outline vertices along an edge.
const DETAIL := 28.0

@export var kind := Kind.SLAB
@export var size := Vector2(200.0, 40.0)
@export var shape_seed := 1
## Edge jitter in px; also scales how chipped the corners are.
@export var roughness := 4.0
@export var color := Color(0.015, 0.015, 0.02)
## Slightly lighter along the top so the shape reads as a volume, not a flat cut-out.
@export var rim_color := Color(0.07, 0.07, 0.09)
@export var solid := true
@export var casts_shadow := true


static func build_outline(shape_kind: Kind, shape_size: Vector2, seed_value: int, rough: float) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	match shape_kind:
		Kind.GROUND:
			return _ground(rng, shape_size, rough)
		Kind.SLAB:
			var rect := Rect2(-shape_size * 0.5, shape_size)
			return _rough_rect(rng, rect, Vector4(rough * 0.6, rough, rough * 1.6, rough), rough * 2.5)
		Kind.PILLAR:
			return _pillar(rng, shape_size, rough)
	if shape_kind == Kind.ROCK:
		return _rock(rng, shape_size, rough)
	return _boulder(rng, shape_size, rough)


func _ready() -> void:
	var outline := build_outline(kind, size, shape_seed, roughness)
	var poly := Polygon2D.new()
	poly.name = &"Shape"
	poly.polygon = outline
	poly.color = color
	poly.vertex_colors = _shade(outline)
	poly.antialiased = true
	add_child(poly)
	if solid:
		var collision := CollisionPolygon2D.new()
		collision.name = &"Collision"
		collision.polygon = outline
		add_child(collision)
	if casts_shadow:
		var occluder := LightOccluder2D.new()
		occluder.name = &"Occluder"
		occluder.occluder = OccluderPolygon2D.new()
		occluder.occluder.polygon = outline
		add_child(occluder)


## Vertex colours blend from rim_color at the top to color over ~60 px.
func _shade(outline: PackedVector2Array) -> PackedColorArray:
	var top := INF
	for p in outline:
		top = minf(top, p.y)
	var depth := maxf(minf(size.y * 0.5, 60.0), 1.0)
	var colors := PackedColorArray()
	for p in outline:
		colors.append(rim_color.lerp(color, clampf((p.y - top) / depth, 0.0, 1.0)))
	return colors


## Clockwise rectangle with chipped corners and jittered edges. amps = (top, right, bottom, left).
static func _rough_rect(rng: RandomNumberGenerator, rect: Rect2, amps: Vector4, chip: float) -> PackedVector2Array:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	var amp := [amps.x, amps.y, amps.z, amps.w]
	var chips := PackedFloat32Array()
	for i in 4:
		chips.append(rng.randf_range(0.3, 1.0) * chip)
	var pts := PackedVector2Array()
	for i in 4:
		var from: Vector2 = corners[i]
		var to: Vector2 = corners[(i + 1) % 4]
		var dir := (to - from).normalized()
		var normal := dir.rotated(-PI * 0.5)
		var start := from + dir * chips[i]
		var end := to - dir * chips[(i + 1) % 4]
		var segments := maxi(int(start.distance_to(end) / DETAIL), 3)
		for k in segments + 1:
			var base := start.lerp(end, float(k) / segments)
			pts.append(base + normal * rng.randf_range(-1.0, 1.0) * amp[i])
	return pts


static func _pillar(rng: RandomNumberGenerator, size: Vector2, rough: float) -> PackedVector2Array:
	# Broken column: ragged top, tapering shaft, flared base.
	var rect := Rect2(-size.x * 0.5, -size.y, size.x, size.y)
	var pts := _rough_rect(rng, rect, Vector4(size.y * 0.06, rough * 0.8, rough, rough * 0.8), rough * 2.0)
	for i in pts.size():
		var p := pts[i]
		var h := clampf(-p.y / size.y, 0.0, 1.0)
		p.x *= lerpf(1.0, 0.78, h) * (1.0 + 0.3 * exp(-h * 14.0))
		pts[i] = p
	return pts


static func _boulder(rng: RandomNumberGenerator, size: Vector2, rough: float) -> PackedVector2Array:
	# Half a superellipse (broad, nearly flat top you can stand on) with a flat base.
	var pts := PackedVector2Array()
	var steps := 20
	for k in steps + 1:
		var a := PI * k / steps
		var wobble := 1.0 if k == 0 or k == steps else 1.0 + rng.randf_range(-1.0, 1.0) * rough * 0.012
		var x := signf(cos(a)) * pow(absf(cos(a)), 0.5) * size.x * 0.5
		var y := -pow(sin(a), 0.5) * size.y
		pts.append(Vector2(x, y) * Vector2(1.0, wobble))
	return pts


## A loose, closed lump (a chunk that can fall or roll): an ellipse with a jittered radius, bottom at y = 0.
static func _rock(rng: RandomNumberGenerator, size: Vector2, rough: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var count := 14
	var phase := rng.randf() * TAU
	for k in count:
		var a := TAU * k / count
		var r := 1.0 + rng.randf_range(-1.0, 1.0) * rough * 0.012 + sin(a * 2.0 + phase) * 0.07
		pts.append(Vector2(cos(a) * size.x * 0.5, -size.y * 0.5 + sin(a) * size.y * 0.5) * r)
	return pts


static func _ground(rng: RandomNumberGenerator, size: Vector2, rough: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var phase_a := rng.randf() * TAU
	var phase_b := rng.randf() * TAU
	var steps := int(size.x / 40.0)
	for k in steps + 1:
		var x := -size.x * 0.5 + size.x * k / steps
		var y := rough * 0.7 * (sin(x * 0.004 + phase_a) + 0.5 * sin(x * 0.013 + phase_b)) + rng.randf_range(-0.4, 0.4)
		pts.append(Vector2(x, y))
	pts.append(Vector2(size.x * 0.5, size.y))
	pts.append(Vector2(-size.x * 0.5, size.y))
	return pts
