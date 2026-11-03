extends CharacterBody2D

const ENEMY_ID = "rat"

@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent


func _ready() -> void:
	add_to_group("enemy")
	Balance.apply_enemy_stats(self, ENEMY_ID)


func _process(_delta: float) -> void:
	velocity_component.accelerate_to_player()
	velocity_component.move(self)
	
	var move_sign = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(move_sign, 1)
