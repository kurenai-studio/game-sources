extends Area3D
class_name BuildSpot

@onready var highlight_building_root:Node3D = get_node("%BaseSelectedHighlight")

var _placed_building_inst:StaticBody3D = null
var spot_taken:bool = false

var building_dict:Dictionary = {
	"Power":"res://Buildings/Scenes/power_station.tscn",
	"Ammo":"res://Buildings/Scenes/ammo_station.tscn",
	"Health":"res://Buildings/Scenes/health_station.tscn",
	"Upgrade":"res://Buildings/Scenes/upgrade_building.tscn"
}

signal building_was_destroyed(pBuildingString:String)

func spawn_new_building(pBuilding:String = "") -> void:
	var _load_building:PackedScene = load(building_dict[pBuilding])
	if is_instance_valid(_load_building):
		_placed_building_inst = _load_building.instantiate()
		get_tree().root.add_child(_placed_building_inst)
		_placed_building_inst.global_position = self.global_position
		if !_placed_building_inst.is_connected("placed_building_destroyed",_reset_building_spot.bind(pBuilding)):
			_placed_building_inst.connect("placed_building_destroyed",_reset_building_spot.bind(pBuilding))
		Global.add_to_targetable_locations(self.global_position)
		spot_taken = true

func _reset_building_spot(pBuilding:String):
	spot_taken = false
	emit_signal("building_was_destroyed")
	Global.remove_targetable_location(self.global_position)
	if is_instance_valid(_placed_building_inst) and _placed_building_inst.is_connected("placed_building_destroyed",_reset_building_spot.bind(pBuilding)):
		_placed_building_inst.disconnect("placed_building_destroyed",_reset_building_spot.bind(pBuilding))

func _on_mouse_entered() -> void:
	if !spot_taken:
		highlight_building_root.visible = true

func _mouse_exit() -> void:
	highlight_building_root.visible = false
