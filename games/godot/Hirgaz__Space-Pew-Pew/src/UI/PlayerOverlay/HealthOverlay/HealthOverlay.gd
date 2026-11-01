extends Control


@onready var health_counter := %HealthCounter


func update_health(lives: int) -> void:
	health_counter.text = "%dx" % lives
