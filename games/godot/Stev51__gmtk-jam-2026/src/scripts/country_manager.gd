extends Node

var timed_out_flag = false



var DELTA_MOD = 1
var time_since_ai = 0.0

var all_countries_signed_armistice = false

@export var countries: Array[Country]



func _ready() -> void:
	Globals.country_init()
	
	for country in countries:
		country.init()
	
	DoomsdayClock.zero_hour.connect(zero_hour)

func _process(delta: float) -> void:
	if not timed_out_flag and Globals.game_speed != Globals.GameSpeed.PAUSED:
		
		delta *= DELTA_MOD
		if Globals.game_speed == Globals.GameSpeed.FAST:
			delta *= 6
		
		var num_countries_signed_armistice = 0
		for country in countries:
			process_country(country, delta)
			if country.signed_armistice == true:
				num_countries_signed_armistice += 1
		if num_countries_signed_armistice == 4:
			all_countries_signed_armistice = true
		
		#run ais every few delta-seconds
		time_since_ai += delta
		if time_since_ai > 3:
			for country in countries:
				if country != Globals.PlayerCountry:
					if country.ai_is_busy == false:
						AiManager.run_npc_ai(country)

func process_country(country: Country, delta: float) -> void:
	#Five passive stats: money, uranium, research, willingness, influence
	#delta uranium and delta progress should never be negative. Money can go negative lol
	country.money += country.delta_money * delta
	country.uranium += country.mines * 0.001 * delta
	country.research_progress += country.labs * 0.05 * delta
	if country.research_progress > 100:
		country.research_progress = 100.0
	
	#Influence is bounded at zero and one hundred
	for country_b in countries:
		country.influence[country_b.index] += country.delta_influence[country_b.index] * delta
		if country.influence[country_b.index] < 0.0:
			country.influence[country_b.index] = 0.0
		if country.influence[country_b.index] > 100.0:
			country.influence[country_b.index] = 100.0
			
	#Calculate change in willingness to fire nukes
	country.delta_willingness_to_fire_nukes = 0
	if country.index == Globals.PlayerCountry.index:
		country.willingness_to_fire_nukes = 0
		return
	for country_b in countries:
		country.delta_willingness_to_fire_nukes += (country.nukes - country_b.nukes)/4
		country.delta_willingness_to_fire_nukes += (country.influence[country_b.index] - country_b.influence[country.index]) / 1000
	if abs(country.delta_willingness_to_fire_nukes) >= 1.0:
		country.delta_willingness_to_fire_nukes = sign(country.delta_willingness_to_fire_nukes)
	
	# Delta willingness to nuke is constantly increasing to force game end
	# country.delta_willingness_to_fire_nukes += 0.000005
	
	#Willingness is bounded at zero and one hundred
	country.willingness_to_fire_nukes += country.delta_willingness_to_fire_nukes * delta
	
	if country.willingness_to_fire_nukes < 0.0:
		country.willingness_to_fire_nukes = 0.0
	if country.willingness_to_fire_nukes >= 100.0:
		if country.nukes >= 1:
			DoomsdayClock.zero_hour.emit()
		else:
			country.willingness_to_fire_nukes = 100.0

#func get_total_influence() -> float:
	#var count = 0.0
	#for country in countries:
		#count += country.influence
	#return count

#func get_highest_influence() -> float:
	#var highest = 0.0
	#for country in countries:
		#if country.influence > highest:
			#highest = country.influence
	#return highest

# All of this process is just for demonstration
#func process_country(country: Country, total_influence: float, delta: float) -> void:
	#
	#country.influence += country.nukes * NUKES_TO_INFLUENCE * delta
	#country.influence -= ((total_influence - country.influence) / total_influence ) * INFLUENCE_WILLINGNESS_DECREASE * delta
	#if country.influence < 0.0:
		#country.influence = 0.0
	#
	#country.money += country.influence * INFLUENCE_TO_MONEY * delta
	#
	#if country.uranium >= URANIUM_TO_NUKES or country.money >= MONEY_TO_NUKES:
		#
		#while country.uranium >= URANIUM_TO_NUKES and country.money >= MONEY_TO_NUKES:
			#country.nukes += 1.0
			#country.uranium -= URANIUM_TO_NUKES
			#country.money -= MONEY_TO_NUKES
	#
	#else:
		#
		#while country.money >= MONEY_TO_URANIUM:
			#country.uranium += 1.0
			#country.money -= MONEY_TO_URANIUM

func zero_hour() -> void:
	timed_out_flag = true
