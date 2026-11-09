class_name Country extends Resource

var money
var uranium
var nukes
var influence
var labs
var mines
var research_progress
var can_build_nukes
var willingness_to_fire_nukes
var signed_armistice

var delta_money
var delta_uranium
var delta_influence
var delta_research_progress
var delta_willingness_to_fire_nukes

var ai_is_busy = false

@export var long_name: String
@export var short_name: String
@export var index: int

@export var initial_money = 0.0
@export var initial_uranium = 0.0
@export var initial_nukes = 0
@export var initial_influence = [0.0, 0.0, 0.0, 0.0, 0.0]
@export var initial_labs = 0
@export var initial_mines = 0
@export var initial_research_progress = 0.0
@export var initial_can_build_nukes = false
@export var initial_willingness_to_fire_nukes = 0.0
@export var initial_signed_armistice = false

@export var initial_delta_money = 0.0
@export var initial_delta_uranium = 0.0
@export var initial_delta_influence = [0.0, 0.0, 0.0, 0.0, 0.0]
@export var initial_delta_research_progress = 0.0
@export var initial_delta_willingness_to_fire_nukes = 0.0

const cost_multiplier = 1
@export var war_taxes_influence_cost = 10
@export var war_taxes_exponential = 1.2
@export var war_taxes_delta_money_gain = 20
@export var spread_propaganda_cost = 3000*cost_multiplier
@export var spread_propaganda_exponential = 1.05
@export var spread_progaganda_delta_influence_gain = 0.05
@export var build_lab_cost = 5000*cost_multiplier
@export var lab_exponential = 1.1
@export var build_mine_cost = 5000*cost_multiplier
@export var mine_exponential = 1.1
@export var nuke_cost = 10000*cost_multiplier
@export var nuke_exponential = 1.1
@export var gift_cost = 5000*cost_multiplier
@export var gift_exponential = 1.05
@export var gift_influence_gain = 10
@export var spread_counter_propaganda_cost = 5000*cost_multiplier
@export var spread_counter_propaganda_exponential = 1.05
@export var spread_counter_propaganda_delta_influence_enemy_loss = 0.05
@export var send_diplomat_influence_cost = 10
@export var send_diplomat_exponential = 1.1
@export var send_diplomat_delta_influence_gain = 0.1
@export var spy_on_technology_cost = 6000*cost_multiplier
@export var sabotage_mine_cost = 7000*cost_multiplier
@export var sabotage_mine_exponential = 1.1
@export var sabotage_mine_influence_cost = 30
@export var sabotage_lab_cost = 7000*cost_multiplier
@export var sabotage_lab_exponential = 1.1
@export var sabotage_lab_influence_cost = 30
@export var steal_uranium_cost = 5000*cost_multiplier
@export var steal_uranium_exponential = 1.05
@export var steal_uranium_influence_cost = 30
@export var steal_uranium_uranium_gain = 0.2
@export var calm_fears_influence_cost = 30
@export var calm_fears_exponential = 1.08
@export var calm_fears_willingness_decrease = 20
@export var convince_to_sign_influence_cost = 80

@export var ai_exponential_handicap = 1/2

func init() -> void:
	reset_resources()
	# Go through AI countries and decrease exponential bases by factor 
	# of ai_exponential (so 1.1 -> 1.05 if ai_exponential=1/2 for instance) for all of them
	if not self == Globals.PlayerCountry:
		war_taxes_exponential = (war_taxes_exponential - 1)*ai_exponential_handicap + 1
		spread_propaganda_exponential = (spread_propaganda_exponential - 1)*ai_exponential_handicap + 1
		lab_exponential = (lab_exponential - 1)*ai_exponential_handicap + 1
		mine_exponential = (mine_exponential - 1)*ai_exponential_handicap + 1
		nuke_exponential = (nuke_exponential - 1)*ai_exponential_handicap + 1
		gift_exponential = (gift_exponential - 1)*ai_exponential_handicap + 1
		spread_counter_propaganda_exponential = (spread_counter_propaganda_exponential - 1)*ai_exponential_handicap + 1
		send_diplomat_exponential = (send_diplomat_exponential - 1)*ai_exponential_handicap + 1
		sabotage_mine_exponential = (sabotage_mine_exponential - 1)*ai_exponential_handicap + 1
		sabotage_lab_exponential = (sabotage_lab_exponential - 1)*ai_exponential_handicap + 1
		steal_uranium_exponential = (steal_uranium_exponential - 1)*ai_exponential_handicap + 1
		calm_fears_exponential = (calm_fears_exponential - 1)*ai_exponential_handicap + 1

func reset_resources() -> void:
	money = initial_money
	uranium = initial_uranium
	nukes = initial_nukes
	influence = initial_influence
	labs = initial_labs
	mines = initial_mines
	research_progress = initial_research_progress
	can_build_nukes = initial_can_build_nukes
	willingness_to_fire_nukes = initial_willingness_to_fire_nukes
	signed_armistice = initial_signed_armistice
	delta_money = initial_delta_money
	delta_uranium = initial_delta_uranium
	delta_influence = initial_delta_influence
	delta_research_progress = initial_delta_research_progress
	delta_willingness_to_fire_nukes = initial_delta_willingness_to_fire_nukes

#Domestic Actions

func raise_war_taxes() -> void:
	if influence[index] >= war_taxes_influence_cost:
		influence[index] -= war_taxes_influence_cost
		delta_money += war_taxes_delta_money_gain
		war_taxes_influence_cost *= war_taxes_exponential

#function called for spreading positive propaganda of own country
func spread_propaganda() -> void:
	if money >= spread_propaganda_cost:
		money -= spread_propaganda_cost
		delta_influence[index] += spread_progaganda_delta_influence_gain
		spread_propaganda_cost *= spread_propaganda_exponential

func build_lab() -> void:
	if money >= build_lab_cost:
		money -= build_lab_cost
		labs += 1
		build_lab_cost *= lab_exponential

func build_mine() -> void:
	if money >= build_mine_cost:
		money -= build_mine_cost
		mines += 1
		build_mine_cost *= mine_exponential

func establish_nuclear_capabilities() -> void:
	if research_progress > 99.9 && can_build_nukes == false:
		can_build_nukes = true

func build_nuke() -> void:
	if money >= nuke_cost && uranium > 1 && can_build_nukes == true:
		money -= nuke_cost
		uranium -= 1
		nukes += 1
		nuke_cost *= nuke_exponential

#Only available to the player
func enforce_armistice() -> void:
	if CountryManager.all_countries_signed_armistice == true:
		DoomsdayClock.infinite_hour.emit()

#Foreign Actions

func send_gift(target: Country) -> void:
	if money >= gift_cost:
		money -= gift_cost
		influence[target.index] += gift_influence_gain
		gift_cost *= gift_exponential

#function called for spreading negative propaganda of target country
func spread_counter_propaganda(target: Country) -> void:
	if money >= spread_counter_propaganda_cost:
		money -= spread_counter_propaganda_cost
		target.delta_influence[target.index] -= spread_counter_propaganda_delta_influence_enemy_loss
		spread_counter_propaganda_cost *= spread_counter_propaganda_exponential

func send_diplomat(target: Country) -> void:
	if influence[index] > send_diplomat_influence_cost:
		influence[index] -= send_diplomat_influence_cost
		delta_influence[target.index] += send_diplomat_delta_influence_gain
		send_diplomat_influence_cost *= send_diplomat_exponential

func spy_on_technology(target: Country) -> void:
	if money >= spy_on_technology_cost:
		money -= spy_on_technology_cost
		#Boost progress by half the tech gap, at least 4
		research_progress += maxf(4, (target.research_progress - research_progress) / 4)

func sabotage_mine(target: Country) -> void:
	if money >= sabotage_mine_cost && influence[target.index] >= sabotage_mine_influence_cost && target.mines >= 1:
		money -= sabotage_mine_cost
		influence[target.index] -= sabotage_mine_influence_cost
		sabotage_mine_cost *= sabotage_mine_exponential
		target.mines -= 1

func sabotage_lab(target: Country) -> void:
	if money >= sabotage_lab_cost && influence[target.index] >= sabotage_lab_influence_cost && target.labs >= 1:
		money -= sabotage_lab_cost
		influence[target.index] -= sabotage_lab_influence_cost
		sabotage_lab_cost *= sabotage_lab_exponential
		target.labs -= 1

func steal_uranium(target: Country) -> void:
	if money >= steal_uranium_cost && influence[target.index] >= steal_uranium_influence_cost && target.uranium >= steal_uranium_uranium_gain:
		money -= steal_uranium_cost
		influence[target.index] -= steal_uranium_influence_cost
		target.uranium -= steal_uranium_uranium_gain
		uranium += steal_uranium_uranium_gain
		steal_uranium_cost *= steal_uranium_exponential

func calm_fears(target: Country):
	if influence[target.index] >= calm_fears_influence_cost && target.willingness_to_fire_nukes >= calm_fears_willingness_decrease:
		influence[target.index] -= calm_fears_influence_cost
		target.willingness_to_fire_nukes -= calm_fears_willingness_decrease
		calm_fears_influence_cost *= calm_fears_exponential

#Only available to the player
func convince_to_sign_armistice(target: Country) -> void:
	if influence[target.index] >= convince_to_sign_influence_cost && target.willingness_to_fire_nukes <= 10 && target.signed_armistice == false:
		influence[target.index] -= convince_to_sign_influence_cost
		target.willingness_to_fire_nukes -=10
		target.signed_armistice = true
