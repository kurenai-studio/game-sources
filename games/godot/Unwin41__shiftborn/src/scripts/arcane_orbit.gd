class_name ArcaneOrbit
extends Node2D
## Arcane Orbit evolution: orbs circle the player in both forms and hurt
## the enemies they touch. Each orb hits a given enemy at most once per
## [constant HIT_COOLDOWN]. Hybrid damage, so resistances do not apply.

const ORB_COUNT := 3
const RING_RADIUS := 30.0
const ORB_RADIUS := 4.0
## Radians per second.
const SPIN_SPEED := 3.2
const HIT_COOLDOWN := 0.5
## Orb damage is this share of the stronger form's base damage.
const DAMAGE_SHARE := 0.8
const GLOW_BOOST := 3.0
const UNSHADED := preload("res://assets/fx/unshaded.tres")

var player: Player
var _angle: float = 0.0
## Instance id -> seconds until that enemy can be hit again.
var _cooldowns: Dictionary[int, float] = {}


## Offsets of [param count] orbs evenly spaced on a ring, starting at
## [param angle].
static func orb_offsets(angle: float, count: int, radius: float) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	for i in count:
		offsets.append(Vector2.from_angle(angle + TAU * i / count) * radius)
	return offsets


func _ready() -> void:
	material = UNSHADED
	z_index = 5


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		visible = false
		return
	_angle = wrapf(_angle + SPIN_SPEED * delta, 0.0, TAU)
	_tick_cooldowns(delta)
	_hit_enemies()
	queue_redraw()


func _tick_cooldowns(delta: float) -> void:
	for id in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)


func _hit_enemies() -> void:
	var damage := maxf(player.knight_damage, player.mage_damage) * DAMAGE_SHARE * player.damage_multiplier(player.form)
	var orbs := orb_offsets(_angle, ORB_COUNT, RING_RADIUS)
	for node in get_tree().get_nodes_in_group(player.enemy_group):
		var enemy := node as Enemy
		if enemy == null or enemy.health <= 0.0 or _cooldowns.has(enemy.get_instance_id()):
			continue
		var local := enemy.global_position - global_position
		for orb in orbs:
			if orb.distance_to(local) <= ORB_RADIUS + enemy.body_radius:
				_cooldowns[enemy.get_instance_id()] = HIT_COOLDOWN
				enemy.take_damage(damage)
				AudioManager.play(&"bolt_hit")
				break


func _draw() -> void:
	var orbs := orb_offsets(_angle, ORB_COUNT, RING_RADIUS)
	for i in orbs.size():
		var color := Player.KNIGHT_UI_COLOR if i % 2 == 0 else Player.MAGE_UI_COLOR
		draw_circle(orbs[i], ORB_RADIUS, Quality.glow(color, GLOW_BOOST))
		draw_circle(orbs[i], ORB_RADIUS * 0.45, Quality.glow(Color.WHITE, GLOW_BOOST))
