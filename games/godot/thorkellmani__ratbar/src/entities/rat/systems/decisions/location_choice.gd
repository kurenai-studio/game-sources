## Chooses a destination using the rat's wants and each location's appeal.
class_name LocationChoice extends Object

const SCORING_TUNING_CONSTANT = 3

## Chooses the destination that best matches the rat's current wants.
## Returns its option index, or -1 when no option has active appeal.
static func choose_destination_index(
	urgencies: NeedUrgencyValues,
	options: Array[LocationChoiceOption]
) -> int:
	var best_score: float = -INF
	var best_option_index: int = -1

	for index in range(options.size()):
		var option: LocationChoiceOption = options[index]
		var score: float = _calculate_location_score(
			option,
			urgencies
		)

		print("Location ", option.title, " has score: ", score)

		if score > best_score:
			best_score = score
			best_option_index = index

	return best_option_index


## Scores how well this destination appeals to the rat's current wants.
## Stronger matches receive more weight; employment pressure adds a bonus.
static func _calculate_location_score(
	option: LocationChoiceOption,
	urgencies: NeedUrgencyValues
) -> float:
	var total_powered_score: float = 0.0
	var active_need_count: int = 0

	for need in NeedValues.get_keys():
		if option.pull[need] > 0.0:
			active_need_count += 1
			var need_score: float = (
				urgencies[need]
				* option.pull.get_normalized_value(need)
			)
			total_powered_score += pow(
				need_score,
				SCORING_TUNING_CONSTANT
			)

	if active_need_count == 0:
		return -INF

	var combined_need_score: float = pow(
		total_powered_score / active_need_count,
		1.0 / SCORING_TUNING_CONSTANT
	)

	return combined_need_score + option.employment_pressure
