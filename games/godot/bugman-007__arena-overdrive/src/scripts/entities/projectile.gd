class_name Projectile
extends Node2D
## Pooled bullet. Movement and collision are resolved by the game's combat step.

enum Team { PLAYER, ENEMY }

var velocity: Vector2 = Vector2.ZERO
var damage: int = 10
var crit: bool = false
var pierce: int = 0
var radius: float = 6.0
var lifetime: float = 2.0
var team: Team = Team.PLAYER
var color: Color = Color.WHITE
var hit_ids: Dictionary = {}


func launch(origin: Vector2, vel: Vector2, dmg: int, t: Team, c: Color, pierce_count: int = 0,
		is_crit: bool = false, r: float = 6.0, life: float = 1.6) -> void:
	position = origin
	velocity = vel
	damage = dmg
	team = t
	color = c
	pierce = pierce_count
	crit = is_crit
	radius = r
	lifetime = life
	hit_ids.clear()
	rotation = vel.angle()
	queue_redraw()


## Returns false once expired.
func advance(delta: float) -> bool:
	position += velocity * delta
	lifetime -= delta
	return lifetime > 0.0


## Registers a hit on `id`; returns true when the projectile should be removed.
func register_hit(id: int) -> bool:
	hit_ids[id] = true
	pierce -= 1
	return pierce < 0


func already_hit(id: int) -> bool:
	return hit_ids.has(id)


func _draw() -> void:
	var len := 14.0 if team == Team.PLAYER else 6.0
	draw_circle(Vector2.ZERO, radius * 2.6, Color(color, 0.18))
	draw_line(Vector2(-len, 0), Vector2.ZERO, Color(color, 0.5), radius * 1.2, true)
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.5, Color(1, 1, 1, 0.95))
