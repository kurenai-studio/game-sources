extends AnimationPlayer


var _current_wave:int = 1

@onready var _wave_timer:Timer = get_node("%TimeBetweenWaves")

var _wave_array:Array = ["Level1_Wave1","Level1_Wave2","Level1_Wave3","Level1_BossWave"]

func _ready() -> void:
	_start_wave(1)
	
func _start_wave(pWave:int):
	current_animation = _wave_array[pWave - 1]
	play()

func _on_time_between_waves_timeout() -> void:
	_start_wave(_current_wave)

func _on_animation_finished(_anim_name: StringName) -> void:
	_current_wave += 1
	if _current_wave <= 4:		
		_wave_timer.start()

	
