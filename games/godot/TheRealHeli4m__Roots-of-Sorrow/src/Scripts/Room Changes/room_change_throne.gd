extends Area2D

@export var hallway = load("res://Scenes/hallway.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Global.change_room.emit(hallway, Vector2(637, -5), Vector2(637, 325), false, true)
