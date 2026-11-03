extends Node
class_name HealthComponent

signal died
signal health_changed

@export var max_health: float = 5
var current_health

func _ready() -> void:
	current_health = max_health


func set_max_health(value: float) -> void:
	max_health = value
	current_health = value


func damage(damage_amount: float):
	current_health = max(current_health - damage_amount, 0)
	health_changed.emit()
	Callable(_check_death).call_deferred()


func heal(heal_amount: float) -> void:
	current_health = min(current_health + heal_amount, max_health)
	health_changed.emit()


func get_health_percent():
	if max_health <= 0:
		return
	
	return min(current_health / max_health, 1)


func _check_death():
	if current_health == 0:
		died.emit()
		owner.queue_free()
	
