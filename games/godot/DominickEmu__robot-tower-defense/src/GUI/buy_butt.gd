extends Button

@export var tower : PackedScene;
@onready var type = tower.instantiate();
@onready var cost : int = type.cost

func _ready():
	text = str(type.get_groups()[0],"\n(",type.cost,")")
	disabled = (cost > Global.money);

# checks what tower it holds, and creates tower that can be placed.
func _on_pressed():
	var bought = tower.instantiate();
	get_tree().get_first_node_in_group("Towers").add_child(bought)
	if Global.bought_tower != null:
		Global.bought_tower.queue_free();
	Global.bought_tower = bought
