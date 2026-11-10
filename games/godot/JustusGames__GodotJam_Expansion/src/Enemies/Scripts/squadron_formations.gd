extends Node3D

var _all_bombers:Array = []

func _ready() -> void:
	_all_bombers = get_children()

func start_bombing_run():
	if _all_bombers.size() >= 1:
		for _bomber in _all_bombers:
			if is_instance_valid(_bomber):
				_bomber.start_bombing()
	
func end_bombing_run():
	if _all_bombers.size() >= 1:
		for _bomber in _all_bombers:
			if is_instance_valid(_bomber):
				_bomber.end_bombing()
