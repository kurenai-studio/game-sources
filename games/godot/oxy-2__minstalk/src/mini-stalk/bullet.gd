extends Area2D

@export var bulletspeed := 1200
@export var bulletdamage := 1
@export var lifetime := 1.5

var direction := Vector2.RIGHT
var shooter: Node2D = null

func _ready() -> void:
	add_to_group("bullet")
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position += direction * bulletspeed * delta

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	# no friendly fire between outlaws
	if shooter != null and shooter.is_in_group("enemy") and body.is_in_group("enemy"):
		return
	if body.has_method("take_damage"):
		body.take_damage(bulletdamage)
	queue_free()
