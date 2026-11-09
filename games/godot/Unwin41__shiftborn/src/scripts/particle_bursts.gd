class_name ParticleBursts
extends Node2D
## Every particle in the run lives in this one node and is drawn as a
## small square, like [DamageNumbers] does for text: cheap enough for the
## web build. Bursts fly out, slow down and fade. LOW quality halves the
## counts; a cap drops the oldest particles first.

const MAX_PARTICLES_HIGH := 700
const MAX_PARTICLES_LOW := 250
const DEFAULT_LIFETIME := 0.45
## Velocity is multiplied by exp(-DRAG * t), so bursts ease out.
const DRAG := 5.0
const SIZE := 2.0
const GLOW_BOOST := 2.5
const UNSHADED := preload("res://assets/fx/unshaded.tres")

var max_particles: int = MAX_PARTICLES_HIGH

var _positions: PackedVector2Array = []
var _velocities: PackedVector2Array = []
var _ages: PackedFloat32Array = []
var _lifetimes: PackedFloat32Array = []
var _colors: PackedColorArray = []


## [param count] on HIGH, about half (at least 1) on LOW.
static func scaled_count(count: int, high: bool) -> int:
	return count if high else maxi(count / 2, 1)


func _init() -> void:
	max_particles = MAX_PARTICLES_HIGH if Quality.is_high() else MAX_PARTICLES_LOW
	z_index = 18
	material = UNSHADED


## Particles in random directions, at up to [param speed] px/s.
func burst(at: Vector2, color: Color, count: int, speed: float, lifetime: float = DEFAULT_LIFETIME) -> void:
	for i in scaled_count(count, Quality.is_high()) if is_inside_tree() else count:
		var velocity := Vector2.from_angle(randf() * TAU) * speed * randf_range(0.4, 1.0)
		_add(at, velocity, color, lifetime * randf_range(0.7, 1.0))


## Particles evenly around a circle, all at [param speed] px/s.
func ring(at: Vector2, color: Color, count: int, speed: float, lifetime: float = DEFAULT_LIFETIME) -> void:
	var total := scaled_count(count, Quality.is_high()) if is_inside_tree() else count
	for i in total:
		_add(at, Vector2.from_angle(TAU * i / total) * speed, color, lifetime)


func count() -> int:
	return _positions.size()


func position_of(index: int) -> Vector2:
	return _positions[index]


## Moves every particle by [param delta] seconds and drops expired ones.
func advance(delta: float) -> void:
	var slow := exp(-DRAG * delta)
	var i := 0
	while i < _positions.size():
		_ages[i] += delta
		if _ages[i] >= _lifetimes[i]:
			_remove(i)
			continue
		_positions[i] += _velocities[i] * delta
		_velocities[i] *= slow
		i += 1


func _process(delta: float) -> void:
	if _positions.is_empty():
		return
	advance(delta)
	queue_redraw()


func _draw() -> void:
	for i in _positions.size():
		var fade := 1.0 - _ages[i] / _lifetimes[i]
		var size := SIZE * (0.5 + 0.5 * fade)
		var color := Quality.glow(_colors[i], GLOW_BOOST)
		color.a *= fade
		draw_rect(Rect2(_positions[i] - Vector2.ONE * size * 0.5, Vector2.ONE * size), color)


func _add(at: Vector2, velocity: Vector2, color: Color, lifetime: float) -> void:
	if _positions.size() >= max_particles:
		_remove(0)
	_positions.append(at)
	_velocities.append(velocity)
	_ages.append(0.0)
	_lifetimes.append(lifetime)
	_colors.append(color)


func _remove(index: int) -> void:
	_positions.remove_at(index)
	_velocities.remove_at(index)
	_ages.remove_at(index)
	_lifetimes.remove_at(index)
	_colors.remove_at(index)
