class_name EnemyBolt
extends Node2D
## Boss projectile. Flies straight and hurts the target (the player) on
## touch. The player has no collision shape, so hits are a distance check,
## like enemy contact damage.

const SPEED := 95.0
const LIFETIME := 4.0
const RADIUS := 3.5
const COLOR := Color(1.0, 0.35, 0.3)
const GLOW_BOOST := 3.0
const UNSHADED := preload("res://assets/fx/unshaded.tres")
## Every live bolt is in this group so the run can clear them at the end.
const GROUP := &"enemy_bolt"

var target: Node2D
var damage: float = 1.0

var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0


static func create(at: Vector2, direction: Vector2, hit_damage: float) -> EnemyBolt:
	var bolt := EnemyBolt.new()
	bolt.position = at
	bolt._velocity = direction.normalized() * SPEED
	bolt.damage = hit_damage
	return bolt


static func touches(bolt_position: Vector2, target_position: Vector2, bolt_radius: float, target_radius: float) -> bool:
	return bolt_position.distance_squared_to(target_position) <= pow(bolt_radius + target_radius, 2.0)


func _init() -> void:
	material = UNSHADED
	z_index = 4
	add_to_group(GROUP)


func _physics_process(delta: float) -> void:
	if step(delta):
		queue_free()


## Moves by [param delta] seconds. Returns true when the bolt is done:
## it hit the target or its lifetime ran out.
func step(delta: float) -> bool:
	position += _velocity * delta
	_age += delta
	if is_instance_valid(target) and touches(_where(self), _where(target), RADIUS, Player.BODY_RADIUS):
		if target.has_method("take_damage"):
			target.take_damage(damage)
		return true
	return _age >= LIFETIME


## Global position in the tree; local position in isolated unit tests.
static func _where(node: Node2D) -> Vector2:
	return node.global_position if node.is_inside_tree() else node.position


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 1.0, Color(0.1, 0.0, 0.0, 0.8))
	draw_circle(Vector2.ZERO, RADIUS, Quality.glow(COLOR, GLOW_BOOST))
