extends Button

@export var doc_number: int
@onready var game = $"../../../../"

func _pressed() -> void:
	game.switchDoc(doc_number)
	
