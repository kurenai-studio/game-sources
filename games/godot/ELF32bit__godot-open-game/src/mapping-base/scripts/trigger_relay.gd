extends Node3D

signal generic(parameters: Dictionary)
signal generic_free() # for killtargets

@export_node_path("AudioStreamPlayer3D") var _sound_player: NodePath
@onready var sound_player: AudioStreamPlayer3D = get_node(_sound_player)

@export var delay_time: float = 0.0


func _on_delay_timer_timeout() -> void:
	sound_player.play()
	generic_free.emit()
	generic.emit({})

@warning_ignore("shadowed_variable")
static func _start_delay_timer_from(from: Node, delay_time: float) -> Timer:
	if delay_time < 0.0: return null
	var delay_timer := Timer.new()
	from.add_child(delay_timer, false)
	delay_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	delay_timer.timeout.connect(from._on_delay_timer_timeout)
	delay_timer.timeout.connect(delay_timer.queue_free)
	delay_timer.wait_time = clampf(delay_time, 0.05, INF)
	delay_timer.one_shot = true
	delay_timer.start()
	return delay_timer

@warning_ignore("shadowed_variable")
func _start_delay_timer(delay_time: float) -> void:
	_start_delay_timer_from(self, delay_time)

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	_start_delay_timer(delay_time)
