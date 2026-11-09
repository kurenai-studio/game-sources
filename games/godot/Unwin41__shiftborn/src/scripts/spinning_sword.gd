class_name SpinningSword
extends Node2D
## Melee weapon (the warrior's axe). Rests in the hand; spin() sweeps it one full turn around
## the owner with a fading trail. Emits [signal swept] every physics frame
## of the spin with the angle range the blade covered, so the owner can
## hit each enemy exactly when the blade passes it.

signal swept(from_angle: float, to_angle: float)
signal spin_finished

const SPIN_TIME := 0.3
## Smallest distance from the owner's center to the grip while spinning.
## The grip moves out so the weapon's tip reaches the trail's outer edge.
const MIN_GRIP_RADIUS := 12.0
const TRAIL_INNER_RADIUS := 14.0
## Length of the trail behind the blade, in radians.
const TRAIL_ARC := 1.8
const TRAIL_SEGMENTS := 12
const TRAIL_FADE_TIME := 0.12
const TRAIL_COLOR := Color(0.85, 0.95, 1.0, 0.55)
## The sword sits inside the player's light, so a mild boost is enough to glow.
const TRAIL_GLOW_BOOST := 1.8
## Inner edge of the trail is fainter than the outer edge.
const TRAIL_INNER_ALPHA := 0.3
## Resting pose relative to the owner when facing right.
const HOLD_OFFSET := Vector2(6.0, 2.0)
const HOLD_ANGLE := 0.35

## Weapon sprite, drawn with its grip at the bottom center.
@export var texture: Texture2D = preload("res://assets/ninja/weapons/axe.png"):
	set(value):
		texture = value
		queue_redraw()
## Outer radius of the trail. The owner sets it to its attack radius.
@export var reach: float = 44.0
## Blades evenly spaced around the spin. Each one hits every enemy it passes.
@export_range(1, 8) var blade_count: int = 1:
	set(value):
		blade_count = maxi(value, 1)
		queue_redraw()

var facing_left: bool = false:
	set(value):
		if value != facing_left:
			facing_left = value
			queue_redraw()
var is_spinning: bool = false

var _spin_time: float = 0.0
var _direction: float = 1.0
var _angle: float = 0.0
var _trail_fade: float = 0.0


## True when [param angle] lies in the half-open sweep between
## [param from_angle] and [param to_angle], in either direction.
## Angles can be any real value; they are compared modulo TAU.
static func angle_in_sweep(angle: float, from_angle: float, to_angle: float) -> bool:
	var low := minf(from_angle, to_angle)
	var span := absf(to_angle - from_angle)
	if span >= TAU:
		return true
	return fposmod(angle - low, TAU) < span


## Indexes of the [param count] evenly spaced blades whose sweep from
## [param from_angle] to [param to_angle] (blade 0) covered [param angle].
static func blades_in_sweep(angle: float, from_angle: float, to_angle: float, count: int) -> Array[int]:
	var hits: Array[int] = []
	for i in count:
		var offset := TAU * i / count
		if angle_in_sweep(angle, from_angle + offset, to_angle + offset):
			hits.append(i)
	return hits


## Starts a full turn. Spins clockwise when facing right, and mirrored
## when facing left, starting from the facing side.
func spin() -> void:
	is_spinning = true
	_spin_time = 0.0
	_direction = -1.0 if facing_left else 1.0
	_angle = PI if facing_left else 0.0
	_trail_fade = 0.0
	queue_redraw()


func cancel() -> void:
	is_spinning = false
	_trail_fade = 0.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	if is_spinning:
		_advance_spin(delta)
	elif _trail_fade > 0.0:
		_trail_fade = maxf(_trail_fade - delta, 0.0)
		queue_redraw()


func _advance_spin(delta: float) -> void:
	var previous := _angle
	var start := PI if _direction < 0.0 else 0.0
	_spin_time = minf(_spin_time + delta, SPIN_TIME)
	_angle = start + _direction * TAU * (_spin_time / SPIN_TIME)
	swept.emit(previous, _angle)
	if _spin_time >= SPIN_TIME:
		is_spinning = false
		_trail_fade = TRAIL_FADE_TIME
		spin_finished.emit()
	queue_redraw()


## Grip distance during a spin: the tip lands on [member reach], so what the
## player sees matches the hit radius.
func grip_radius() -> float:
	var length := float(texture.get_height()) if texture != null else 0.0
	return maxf(reach - length, MIN_GRIP_RADIUS)


func _draw() -> void:
	for i in blade_count:
		_draw_trail(_angle + TAU * i / blade_count)
	if is_spinning:
		for i in blade_count:
			var angle := _angle + TAU * i / blade_count
			# The texture points up (-Y); rotate so the blade points outward.
			draw_set_transform(Vector2.from_angle(angle) * grip_radius(), angle + PI / 2.0)
			_draw_blade()
	else:
		var side := -1.0 if facing_left else 1.0
		draw_set_transform(Vector2(HOLD_OFFSET.x * side, HOLD_OFFSET.y), HOLD_ANGLE * side, Vector2(side, 1.0))
		_draw_blade()
	draw_set_transform(Vector2.ZERO)


## Grip (bottom of the texture) sits at the current transform origin.
func _draw_blade() -> void:
	if texture != null:
		draw_texture(texture, Vector2(-texture.get_width() * 0.5, -texture.get_height()))


## [param blade_angle] is where the blade leading this trail points.
func _draw_trail(blade_angle: float) -> void:
	var strength := 1.0 if is_spinning else _trail_fade / TRAIL_FADE_TIME
	var swept_arc := TAU * (_spin_time / SPIN_TIME)
	if strength <= 0.0 or swept_arc <= 0.0:
		return
	var arc := minf(TRAIL_ARC, swept_arc)
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in TRAIL_SEGMENTS + 1:
		_append_trail_point(points, colors, blade_angle, float(i) / TRAIL_SEGMENTS, arc, reach, strength)
	for i in range(TRAIL_SEGMENTS, -1, -1):
		_append_trail_point(points, colors, blade_angle, float(i) / TRAIL_SEGMENTS, arc, TRAIL_INNER_RADIUS, strength * TRAIL_INNER_ALPHA)
	draw_polygon(points, colors)


## [param t] runs from 0 at the tail of the trail to 1 at the blade.
func _append_trail_point(points: PackedVector2Array, colors: PackedColorArray, blade_angle: float, t: float, arc: float, radius: float, strength: float) -> void:
	var angle := blade_angle - _direction * arc * (1.0 - t)
	points.append(Vector2.from_angle(angle) * radius)
	colors.append(Color(Quality.glow(TRAIL_COLOR, TRAIL_GLOW_BOOST), TRAIL_COLOR.a * t * strength))
