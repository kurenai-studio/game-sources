## One parallax layer of procedural dead trees that repeats horizontally: swaying trunks with root
## flare, curved forking branches. Replace by painted art later: nothing in gameplay references it.
class_name SilhouetteLayer
extends Parallax2D

const TRUNK_SEGMENTS := 12
const BRANCH_SEGMENTS := 7

@export var span := 2400.0
@export var count := 14
@export var height_range := Vector2(260.0, 520.0)
## Trunk width at the base (before the root flare).
@export var width_range := Vector2(16.0, 40.0)
@export var branches_per_tree := 3
## Sub-branch levels per branch (0 = bare branches).
@export_range(0, 3) var branch_depth := 2
## World y of the trunk bases (below the floor so no gap shows).
@export var base_y := 120.0
@export var color := Color(0.5, 0.5, 0.52)
@export var shape_seed := 1
## Foreground mode: soft-edged plain trunks (no branches), like out-of-focus trees close to the camera.
@export var soft_edges := false

static var _soft_texture: GradientTexture2D


func _ready() -> void:
	repeat_size = Vector2(span, 0.0)
	repeat_times = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	for i in count:
		var x := span * (i + rng.randf_range(0.0, 0.8)) / count
		_add_tree(rng, x, rng.randf_range(width_range.x, width_range.y), rng.randf_range(height_range.x, height_range.y))


func _add_tree(rng: RandomNumberGenerator, x: float, width: float, height: float) -> void:
	if soft_edges:
		_add_soft_trunk(x, width, height)
		return
	var phase := rng.randf() * TAU
	var points := PackedVector2Array()
	var widths := PackedFloat32Array()
	for i in TRUNK_SEGMENTS + 1:
		var t := float(i) / TRUNK_SEGMENTS
		var sway := (sin(t * 3.0 + phase) * 0.025 + sin(t * 7.0 + phase * 2.0) * 0.008) * height
		points.append(Vector2(x + sway, base_y - height * t))
		var flare := 1.0 + 1.2 * exp(-t * 18.0)
		var bulge := 1.0 + 0.12 * sin(t * 11.0 + phase)
		widths.append(width * lerpf(1.0, 0.18, t) * flare * bulge)
	_add_strip(points, widths)
	for b in branches_per_tree:
		var t := rng.randf_range(0.35, 0.92)
		var idx := int(t * TRUNK_SEGMENTS)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var angle := -PI * 0.5 + side * rng.randf_range(0.4, 1.1)
		var length := height * rng.randf_range(0.18, 0.34) * (1.1 - t * 0.5)
		_add_branch(rng, points[idx], angle, length, widths[idx] * 0.5, branch_depth)


## A curved, twiggy branch as one tapering strip; forks into thinner sub-branches halfway.
func _add_branch(rng: RandomNumberGenerator, origin: Vector2, angle: float, length: float, thickness: float, depth: int) -> void:
	var points := PackedVector2Array()
	var widths := PackedFloat32Array()
	var pos := origin
	var heading := angle
	var bend := rng.randf_range(-0.4, 0.4)
	var step := length / BRANCH_SEGMENTS
	for i in BRANCH_SEGMENTS + 1:
		var t := float(i) / BRANCH_SEGMENTS
		points.append(pos)
		widths.append(maxf(thickness * (1.0 - t * 0.9), 0.8))
		if i == BRANCH_SEGMENTS:
			break
		heading += bend / BRANCH_SEGMENTS + rng.randf_range(-0.12, 0.12)
		pos += Vector2.from_angle(heading) * step
		if depth > 0 and (i == 2 or i == 4) and rng.randf() < 0.8:
			var fork := heading + (1.0 if i == 2 else -1.0) * rng.randf_range(0.5, 1.0)
			_add_branch(rng, pos, fork, length * 0.5, thickness * 0.55, depth - 1)
	_add_strip(points, widths)


## Polygon around a polyline, each point with its own full width.
func _add_strip(points: PackedVector2Array, widths: PackedFloat32Array) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in points.size():
		var prev := points[maxi(i - 1, 0)]
		var next := points[mini(i + 1, points.size() - 1)]
		var normal := (next - prev).normalized().orthogonal() * widths[i] * 0.5
		left.append(points[i] + normal)
		right.append(points[i] - normal)
	right.reverse()
	var poly := Polygon2D.new()
	poly.color = color
	poly.antialiased = true
	poly.polygon = left + right
	add_child(poly)


## A horizontally feathered column: one shared gradient texture stretched to the trunk size.
func _add_soft_trunk(x: float, width: float, height: float) -> void:
	if _soft_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
		_soft_texture = GradientTexture2D.new()
		_soft_texture.gradient = gradient
		_soft_texture.width = 64
		_soft_texture.height = 4
		_soft_texture.fill_from = Vector2(0.0, 0.0)
		_soft_texture.fill_to = Vector2(1.0, 0.0)
	var sprite := Sprite2D.new()
	sprite.texture = _soft_texture
	sprite.modulate = color
	sprite.position = Vector2(x, base_y - height * 0.5)
	sprite.scale = Vector2(width * 2.0 / 64.0, height / 4.0)
	add_child(sprite)
