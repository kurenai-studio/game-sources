extends Area2D

@export var item_id   : String = "engrenage"
@export var item_name : String = "Gear"
@export var prompt_text : String = "[E] Take"

func interact() -> void:
	GameState.add_item(item_id)
	AudioManager.play_sfx("item_pickup")
	queue_free()  # supprime l'item de la scène
