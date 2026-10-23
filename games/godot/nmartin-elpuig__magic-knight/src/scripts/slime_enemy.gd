extends Node2D

const SPEED = 60

var direccion = 1

@onready var ray_cast_derecha: RayCast2D = $RayCastDerecha
@onready var ray_cast_izquierda: RayCast2D = $RayCastIzquierda
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if ray_cast_derecha.is_colliding():
		direccion = -1
		animated_sprite.flip_h = true
	if ray_cast_izquierda.is_colliding():
		direccion = 1
		animated_sprite.flip_h = false  

	position.x += direccion * SPEED * delta
