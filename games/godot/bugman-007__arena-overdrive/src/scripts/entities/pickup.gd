class_name Pickup
extends Node2D
## Pooled collectible (XP shard, coin or health) with magnet attraction.

enum Kind { XP, COIN, HEALTH }

const COLLECT_DISTANCE := 22.0
const MAGNET_SPEED := 760.0

var kind: Kind = Kind.XP
var value: int = 1
var velocity: Vector2 = Vector2.ZERO
var magnetized: bool = false
var _t: float = 0.0


func setup(k: Kind, v: int, at: Vector2, scatter: Vector2 = Vector2.ZERO) -> void:
	kind = k
	value = v
	position = at
	velocity = scatter
	magnetized = false
	_t = randf() * TAU
	queue_redraw()


## Moves toward `target` once inside `radius`. Returns true when collected.
func update(delta: float, target: Vector2, radius: float) -> bool:
	_t += delta
	var to := target - position
	var dist := to.length()
	if dist <= COLLECT_DISTANCE:
		return true
	if dist < radius:
		magnetized = true
	if magnetized:
		velocity = velocity.lerp(to / dist * MAGNET_SPEED, minf(1.0, delta * 9.0))
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	position += velocity * delta
	return position.distance_to(target) <= COLLECT_DISTANCE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 5.0) * 2.0
	match kind:
		Kind.XP:
			var c := Color("5dffd0")
			var s := 6.0 + minf(value, 10) * 0.6
			draw_circle(Vector2(0, bob), s * 2.2, Color(c, 0.15))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -s + bob), Vector2(s * 0.7, bob), Vector2(0, s + bob), Vector2(-s * 0.7, bob)]), c)
		Kind.COIN:
			draw_circle(Vector2(0, bob), 14.0, Color(UiTheme.GOLD, 0.18))
			draw_circle(Vector2(0, bob), 7.0, UiTheme.GOLD)
			draw_circle(Vector2(-2, bob - 2), 2.5, Color(1, 1, 0.85))
		Kind.HEALTH:
			var c := UiTheme.SUCCESS
			draw_circle(Vector2(0, bob), 18.0, Color(c, 0.15))
			draw_rect(Rect2(-3.5, -10 + bob, 7, 20), c)
			draw_rect(Rect2(-10, -3.5 + bob, 20, 7), c)
