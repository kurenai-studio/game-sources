class_name NeedUrgencies extends Resource

@export var need_urgencies: NeedUrgency

## Summarizes the rat's current want across all needs.
## A need being fulfilled contributes urgency sampled at full satisfaction.
## This sampling leaves the stored need value unchanged.
func get_effective_average_urgency(
	needs: Needs,
	net_need_rates_per_game_hour: NeedRates
) -> float:
	var need_keys: Array[String] = NeedValues.get_keys()
	var total_urgency: float = 0.0

	for need in need_keys:
		var need_value_for_urgency: float = needs[need]

		if net_need_rates_per_game_hour[need] > 0.0:
			need_value_for_urgency = needs._get_max()

		total_urgency += need_urgencies[need].sample(
			need_value_for_urgency
		)

	return total_urgency / need_keys.size()
