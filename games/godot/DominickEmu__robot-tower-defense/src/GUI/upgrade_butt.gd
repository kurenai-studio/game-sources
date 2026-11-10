extends Button

var upgrade = "?";
var new_value = -1
var cost = 0
@onready var stat_gui = get_tree().get_first_node_in_group("StatGUI") 


func _on_pressed():
	if Global.money >= cost:
		Global.update_curr(-cost,0)
		stat_gui.upgrade_tower(upgrade, new_value);
