extends HSlider


@export_enum("Master", "SFX", "Music") var audio_bus := "Master"
@onready var bus_index := AudioServer.get_bus_index(audio_bus)


func _value_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_linear(bus_index, new_value)
