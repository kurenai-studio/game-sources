extends Node

signal tick(tick_count: int)

func _ready() -> void:
	$TickTimer.wait_time = GameConstants.SECONDS_PER_GAME_TICK

var _tick_count: int:
	set(value):
		_tick_count = value
		tick.emit(_tick_count)

func _on_tick_timer_timeout() -> void:
	print("Game clock tick iterated, tick ", _tick_count)
	_tick_count += 1
