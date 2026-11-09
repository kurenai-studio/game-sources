class_name Bolt
extends Area2D
## Mage projectile. Flies straight and damages enemies it touches.
## [member chain] hits redirect it to the nearest unhit enemy nearby;
## after that, [member pierce] hits let it fly on through.

const COLOR := Color("e2c4ff")
const CHAIN_COLOR := Color("fff3a0")
const GLOW_BOOST := 3.5
const UNSHADED := preload("res://assets/fx/unshaded.tres")
const LIGHT_TEXTURE := preload("res://assets/fx/light_radial.tres")
const LIGHT_ENERGY := 0.6
const LIGHT_SCALE := 0.7
const RADIUS := 3.0
## How far a chain hit looks for the next enemy.
const CHAIN_RANGE := 90.0
## Flight time granted after each chain jump.
const CHAIN_LIFETIME := 0.5

@export var speed: float = 320.0
@export var lifetime: float = 1.2

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0
var pierce: int = 0
var chain: int = 0
## Rolled per hit; see [method Player.is_crit].
var crit_chance: float = 0.0
## Group searched for chain targets. The player sets it.
var enemy_group: StringName = &"horde_enemy"
## Push speed (px/s) given to each enemy hit (Storm Cleaver).
var knockback: float = 0.0
## HP given to [member healer] per hit (Blood Pact).
var lifesteal: float = 0.0
var healer: Player

var _spent: bool = false
var _chained: bool = false
## Instance ids of enemies this bolt already hit.
var _hit: Dictionary[int, bool] = {}
var _light: PointLight2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	material = UNSHADED
	if Quality.is_high():
		_light = PointLight2D.new()
		_light.texture = LIGHT_TEXTURE
		_light.texture_scale = LIGHT_SCALE
		_light.energy = LIGHT_ENERGY
		_light.color = COLOR
		add_child(_light)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _spent or not area.has_method("take_damage"):
		return
	# A corpse keeps its area until the deferred monitorable change lands.
	if area is Enemy and area.health <= 0.0:
		return
	var id := area.get_instance_id()
	if _hit.has(id):
		return
	_hit[id] = true
	var hit_position := area.global_position
	var crit := Player.is_crit(crit_chance, randf())
	area.take_damage(Player.hit_damage(damage, crit), Player.Form.MAGE, crit)
	if knockback > 0.0 and area.has_method("knockback"):
		area.knockback(direction * knockback)
	if lifesteal > 0.0 and is_instance_valid(healer):
		healer.heal(lifesteal)
	var resisted: bool = area is Enemy and area.resists(Player.Form.MAGE)
	AudioManager.play(&"hit_resisted" if resisted else &"bolt_hit")
	if chain > 0 and _jump_from(hit_position):
		chain -= 1
		return
	if pierce > 0:
		pierce -= 1
		return
	_spent = true
	queue_free()


## Aims at the nearest unhit enemy within [constant CHAIN_RANGE] of
## [param origin]. Returns false when there is none.
func _jump_from(origin: Vector2) -> bool:
	var best: Node2D = null
	var best_distance := CHAIN_RANGE * CHAIN_RANGE
	for node in get_tree().get_nodes_in_group(enemy_group):
		var enemy := node as Node2D
		if enemy == null or _hit.has(enemy.get_instance_id()) or enemy.is_queued_for_deletion():
			continue
		var distance := enemy.global_position.distance_squared_to(origin)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	if best == null:
		return false
	global_position = origin
	direction = origin.direction_to(best.global_position)
	lifetime = CHAIN_LIFETIME
	if not _chained:
		_chained = true
		if _light != null:
			_light.color = CHAIN_COLOR
		queue_redraw()
	return true


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Quality.glow(CHAIN_COLOR if _chained else COLOR, GLOW_BOOST))
