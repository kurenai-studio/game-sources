extends PanelContainer

@export var volume_slider: HSlider

var master_bus: int

func _ready() -> void:
	master_bus = AudioServer.get_bus_index("Master")
	
	if volume_slider:
		# Set min/max to match slider properties (usually 0.0 to 1.0)
		volume_slider.min_value = 0.0
		volume_slider.max_value = 1.0
		volume_slider.step = 0.01
		
		# Initialize value from the audio server
		volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
		
		# Connect signal
		volume_slider.value_changed.connect(_on_volume_slider_changed)

func _on_volume_slider_changed(value: float) -> void:
	if value <= 0.0:
		AudioServer.set_bus_volume_db(master_bus, -80.0)
		AudioServer.set_bus_mute(master_bus, true)
	else:
		AudioServer.set_bus_mute(master_bus, false)
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
