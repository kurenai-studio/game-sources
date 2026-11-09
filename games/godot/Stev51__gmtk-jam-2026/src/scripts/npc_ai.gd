extends Node

var RWT_weight = 0.0
var SP_weight = 0.0
var BL_weight = 0.0
var BM_weight = 0.0
var ENC_weight = 0.0
var BN_weight = 0.0
var Domestic_Pass_weight = 0.0

var SG_weight = 0.0
var SCP_weight = 0.0
var SD_weight = 0.0
var SOT_weight = 0.0
var SM_weight = 0.0
var SL_weight = 0.0
var SU_weight = 0.0
var CF_weight = 0.0
var Foreign_Pass_weight = 0.0

var RWT_time = 0.0
var SP_time = 0.0
var BL_time = 0.0
var BM_time = 0.0
var ENC_time = 0.0
var BN_time = 0.0

var SG_time = 0.0
var SCP_time = 0.0
var SD_time = 0.0
var SOT_time = 0.0
var SM_time = 0.0
var SL_time = 0.0
var SU_time = 0.0
var CF_time = 0.0

#Called by CountryManager
func run_npc_ai(country: Country):
	#calculate weight for each action
	#0 if it's unaffordable/impossible, then increasing as it "seems favorable"
	if country.war_taxes_influence_cost < country.influence[country.index]:
		RWT_time = (country.war_taxes_influence_cost - country.influence[country.index] ) / country.delta_influence[country.index]
		if RWT_time > 10.0:
			RWT_weight = 0
		else:
			RWT_weight = 3
	else:
		RWT_weight = 5
	
	if country.money < country.spread_propaganda_cost:
		SP_time = (country.spread_propaganda_cost - country.money ) / country.delta_money
		if SP_time > 10.0:
			SP_weight = 0
		else:
			SP_weight = 3
	else:
		SP_weight = 5
		
	if country.money < country.build_lab_cost or country.can_build_nukes == true:
		BL_time = (country.build_lab_cost - country.money) / country.delta_money
		if BL_time > 10.0 or country.can_build_nukes == true:
			BL_weight = 0
		else:
			BL_weight = 1
	else:
		BL_weight = 2
		
	if country.money < country.build_mine_cost:
		BM_time = (country.build_lab_cost - country.money) / country.delta_money
		if BM_time > 10.0:
			BM_weight = 0
		else:
			BM_weight = 1
	else:
		BM_weight = 2
	
	if country.research_progress < 99.9 or country.can_build_nukes == true:
		ENC_time = (100 - country.research_progress) / (country.labs * 0.05)
		if ENC_time > 10.0:
			ENC_weight = 0
		else:
			ENC_weight = 5
	else:
		ENC_weight = 1000
	
	if country.money < country.nuke_cost or country.uranium < 1.0:
		BN_time = maxf((country.nuke_cost - country.money) / country.delta_money, (1 - country.uranium) / (country.mines * 0.001))
		if BN_time > 10.0:
			BN_weight = 0
		else:
			BN_weight = 4
	else:
		BN_weight = 5
	
	Domestic_Pass_weight = 30
	
	var sum_domestic_weight = RWT_weight + SP_weight + BL_weight + BM_weight + ENC_weight + BN_weight + Domestic_Pass_weight
	var weight_target = randf_range(0.0, sum_domestic_weight)
	var weight_partial_sum = RWT_weight
	#choose one of the following based on weights
	if weight_target < weight_partial_sum:
		if country.influence[country.index] < country.war_taxes_influence_cost:
			country.ai_is_busy = true
			await get_tree().create_timer(RWT_time).timeout
			country.ai_is_busy = false
		country.raise_war_taxes()
	else:
		weight_partial_sum += SP_weight
		if weight_target < weight_partial_sum:
			if country.money < country.spread_propaganda_cost:
				country.ai_is_busy = true
				await get_tree().create_timer(SP_time).timeout
				country.ai_is_busy = false
			country.spread_propaganda()
		else:
			weight_partial_sum += BL_weight
			if weight_target < weight_partial_sum:
				if country.money < country.build_lab_cost:
					country.ai_is_busy = true
					await get_tree().create_timer(BL_time).timeout
					country.ai_is_busy = false
				country.build_lab()
			else:
				weight_partial_sum += BM_weight
				if weight_target < weight_partial_sum:
					if country.money < country.build_mine_cost:
						country.ai_is_busy = true
						await get_tree().create_timer(BM_time).timeout
						country.ai_is_busy = false
					country.build_mine()
				else:
					weight_partial_sum += ENC_weight
					if weight_target < weight_partial_sum:
						if country.research_progress < 99.95:
							country.ai_is_busy = true
							await get_tree().create_timer(ENC_time).timeout
							country.ai_is_busy = false
						country.establish_nuclear_capabilities()
					else:
						weight_partial_sum += BN_weight
						if weight_target < weight_partial_sum:
							if country.money < country.nuke_cost or country.uranium < 1:
								country.ai_is_busy = true
								await get_tree().create_timer(BN_time).timeout
								country.ai_is_busy = false
							country.build_nuke()
						else:
							pass
	
	for country_b in CountryManager.countries:
		#calculate weight for each action
		#0 if it's unaffordable/impossible, then increasing as it "seems favorable"
		if country.money < country.gift_cost or country.influence[country_b.index] > (100 - country.gift_influence_gain):
			SG_weight = 0
		else:
			SG_weight = 1
		
		if country.money < country.spread_counter_propaganda_cost:
			SCP_weight = 0
		else:
			SCP_weight = 1
		
		if country.influence[country.index] < country.send_diplomat_influence_cost:
			SD_weight = 0
		else:
			SD_weight = 1
		
		if country.money < country.spy_on_technology_cost or country.research_progress < country_b.research_progress:
			SOT_weight = 0
		else:
			SOT_weight = 1
		
		if country.money < country.sabotage_mine_cost or country.influence[country_b.index] < country.sabotage_mine_influence_cost or country_b.mines < 1:
			SM_weight = 0
		else:
			SM_weight = 1
		
		if country.money < country.sabotage_lab_cost or country.influence[country_b.index] < country.sabotage_lab_influence_cost or country_b.labs < 1:
			SL_weight = 0
		else:
			SL_weight = 1
		
		if country.money < country.spread_counter_propaganda_cost:
			SCP_weight = 0
		else:
			SCP_weight = 1
		
		if country.money < country.steal_uranium_cost or country.influence[country_b.index] < country.steal_uranium_influence_cost or country_b.uranium < country.steal_uranium_uranium_gain:
			SU_weight = 0
		else:
			SU_weight = 1
		
		if country.influence[country_b.index] < country.calm_fears_influence_cost or country_b.willingness_to_fire_nukes < country.calm_fears_willingness_decrease:
			CF_weight = 0
		else:
			CF_weight = 0 #disables action for AI
		
		Foreign_Pass_weight = 20
		
		var sum_foreign_weight = SG_weight + SCP_weight + SD_weight + SOT_weight + SM_weight + SL_weight + SU_weight + CF_weight + Foreign_Pass_weight
		weight_target = randf_range(0.0, sum_foreign_weight)
		weight_partial_sum = SG_weight
		#choose one of the following based on weights
		if weight_target < weight_partial_sum:
			country.send_gift(country_b)
		else:
			weight_partial_sum += SCP_weight
			if weight_target < weight_partial_sum:
				country.spread_counter_propaganda(country_b)
			else:
				weight_partial_sum += SD_weight
				if weight_target < weight_partial_sum:
					country.send_diplomat(country_b)
				else:
					weight_partial_sum += SOT_weight
					if weight_target < weight_partial_sum:
						country.spy_on_technology(country_b)
					else:
						weight_partial_sum += SM_weight
						if weight_target < weight_partial_sum:
							country.sabotage_mine(country_b)
						else:
							weight_partial_sum += SL_weight
							if weight_target < weight_partial_sum:
								country.sabotage_lab(country_b)
							else:
								weight_partial_sum += SU_weight
								if weight_target < weight_partial_sum:
									country.steal_uranium(country_b)
								else:
									weight_partial_sum += CF_weight
									if weight_target < weight_partial_sum:
										country.calm_fears(country_b)
									else:
										pass
