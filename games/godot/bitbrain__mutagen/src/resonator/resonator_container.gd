class_name ResonatorContainer extends Node2D


signal unlocked


var resonators:Array[Resonator] = []
var activated_count = 0


func _ready() -> void:
	resonators.assign(get_children())
	for resonator in resonators:
		resonator.on_reset.connect(_reset_all)
		resonator.on_activated.connect(_activate)


func _activate() -> void:
	activated_count += 1
	if activated_count == resonators.size():
		for resonator in resonators:
			resonator.queue_free()
		unlocked.emit()


func _reset_all() -> void:
	activated_count = 0
	for resonator in resonators:
		resonator.deactivate()
