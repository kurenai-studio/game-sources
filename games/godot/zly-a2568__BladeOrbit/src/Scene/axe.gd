extends CharacterBody2D
class_name Axe

var RADIUS: float=40.0
var BASE_DAMAGE := 2.0
var HIT_CAMERA_SHAKE: float

var rotate_speed = PI
var angular: float = PI / 4 * 3
var player: Player


func _ready() -> void:
	var c: Dictionary = Config.data["axe"]
	HIT_CAMERA_SHAKE = c["hit_camera_shake"]


func _physics_process(delta: float) -> void:
	position.x = RADIUS * cos(angular)
	position.y = RADIUS * sin(angular)
	angular -= rotate_speed * delta
	rotation = angular + PI / 4 * 3


func _on_detector_body_entered(body: Node2D) -> void:
	if not (body is Enemy):
		return
	var enemy := body as Enemy
	if enemy.damaged:
		return
	var is_high_damage := randf_range(0.0, 1.0) <= player.high_damage_chance
	var damage := BASE_DAMAGE * (player.high_damage_rate if is_high_damage else 1.0)
	enemy.take_hit(damage, is_high_damage)
	SoundManager.play_sound("laser", "enemy")
	if is_high_damage:
		player.shock_camera(HIT_CAMERA_SHAKE*2)
		player.notify_high_damage()
	else:
		player.shock_camera(HIT_CAMERA_SHAKE)
