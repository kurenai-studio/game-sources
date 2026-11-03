extends Area2D

@export var hall = load("res://Scenes/hall.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Global.change_room.emit(hall, Vector2(2500, 1875), Vector2(2200, 1875), true, true)
