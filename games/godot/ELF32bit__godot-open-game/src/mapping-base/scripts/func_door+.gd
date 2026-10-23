extends AnimatableBody3D

signal generic(parameters: Dictionary)
signal generic_free() # for killtargets

signal activated(parameters: Dictionary)


func _on_opening_signal(parameters: Dictionary) -> void:
	generic_free.emit()
	generic.emit(parameters)

@warning_ignore("unused_parameter")
func _on_closing_signal(parameters: Dictionary) -> void:
	pass


func _on_generic_signal(parameters: Dictionary) -> void:
	activated.emit(parameters)
