class_name StormCleaver
extends Node2D
## Storm Cleaver evolution, warrior half: an axe hit arcs lightning to
## the nearest other enemies. This node is the short-lived bolt drawing;
## [method strike] finds the targets, deals the damage and spawns it.

const TARGETS := 2
const RANGE := 70.0
## Lightning damage is this share of the axe hit that caused it.
const DAMAGE_SHARE := 0.5
const LIFETIME := 0.15
const SEGMENTS := 5
const JITTER := 4.0
const WIDTH := 1.5
const COLOR := Color(0.75, 0.9, 1.0)
const GLOW_BOOST := 3.0
const UNSHADED := preload("res://assets/fx/unshaded.tres")

var _points: PackedVector2Array = []
var _age: float = 0.0


## Indices of up to [param count] [param positions] nearest to
## [param origin] within [param max_range], nearest first.
static func pick_targets(origin: Vector2, positions: Array[Vector2], count: int, max_range: float) -> Array[int]:
	var in_range: Array[int] = []
	for i in positions.size():
		if origin.distance_to(positions[i]) <= max_range:
			in_range.append(i)
	in_range.sort_custom(func(a: int, b: int) -> bool:
		return origin.distance_squared_to(positions[a]) < origin.distance_squared_to(positions[b]))
	return in_range.slice(0, count)


## Arcs from [param from] to the nearest enemies of [param group] and
## hurts them for [param damage]. Drawn under [param fx_parent].
static func strike(from: Enemy, group: StringName, damage: float, fx_parent: Node) -> void:
	var candidates: Array[Enemy] = []
	var positions: Array[Vector2] = []
	for node in from.get_tree().get_nodes_in_group(group):
		var enemy := node as Enemy
		if enemy == null or enemy == from or enemy.health <= 0.0:
			continue
		candidates.append(enemy)
		positions.append(enemy.global_position)
	for index in pick_targets(from.global_position, positions, TARGETS, RANGE):
		var target := candidates[index]
		fx_parent.add_child(_create(from.global_position, target.global_position))
		target.take_damage(damage)


static func _create(from: Vector2, to: Vector2) -> StormCleaver:
	var fx := StormCleaver.new()
	fx._points = _jagged(from, to)
	return fx


static func _jagged(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array([from])
	var normal := (to - from).orthogonal().normalized()
	for i in range(1, SEGMENTS):
		points.append(from.lerp(to, float(i) / SEGMENTS) + normal * randf_range(-JITTER, JITTER))
	points.append(to)
	return points


func _ready() -> void:
	material = UNSHADED
	z_index = 15
	top_level = true


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var alpha := 1.0 - _age / LIFETIME
	draw_polyline(_points, Color(Quality.glow(COLOR, GLOW_BOOST), alpha), WIDTH)
