class_name Circuit
extends Area2D

@export var item_id   : String = "circuit"
@export var item_name : String = "Circuit"
@export var prompt_text : String = "[E] Take"

func interact() -> void:
	GameState.add_item(item_id)
	AudioManager.play_sfx("item_pickup")
	var hud: HUD = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_log"):
		hud.show_log("LOG  %s picked up. Inventory updated." % item_id)
	queue_free()  # supprime l'item de la scène
