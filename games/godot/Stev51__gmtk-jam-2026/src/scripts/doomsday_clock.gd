extends Node

signal zero_hour
signal infinite_hour

var MAX_MINUTES = 720.0
var START_MINUTES = MAX_MINUTES

var minutes
var timed_out_flag = false

func _process(_delta: float) -> void:
	if not timed_out_flag:
		set_minutes()
		#check_timeout()

func get_country_time_to_midnight(country: Country) -> float:
	var time = minf(720, (100 - country.willingness_to_fire_nukes) / max(country.delta_willingness_to_fire_nukes, 0.01))
	return time

func set_minutes() -> void:
	var lowest = 1000.0
	for country in CountryManager.countries:
		if get_country_time_to_midnight(country) < lowest:
			lowest = get_country_time_to_midnight(country)
	minutes = lowest

func _on_zero_hour():
	timed_out_flag = true
	pass

func _on_infinite_hour():
	while timed_out_flag == false:
		if Globals.game_speed == Globals.GameSpeed.PAUSED:
			await get_tree().create_timer(0.1).timeout
			continue
		if Globals.game_speed == Globals.GameSpeed.NORMAL:
			await get_tree().create_timer(3.0).timeout
		if Globals.game_speed == Globals.GameSpeed.FAST:
			await get_tree().create_timer(1.5).timeout
		var nukes_remaining = false
		for country in CountryManager.countries:
			if country.nukes >= 1:
				country.nukes -= 1
			if country.nukes >= 1:
				nukes_remaining = true
		if nukes_remaining == false:
			win()

func win():
	timed_out_flag = true
	pass

#func check_timeout() -> void:
	#if minutes <= 0.0 and not timed_out_flag:
		#minutes = 0.0
		#zero_hour.emit()
		#timed_out_flag = true
