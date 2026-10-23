## Calculates how the rat's needs change and how strongly it currently wants them fulfilled.
## Works on copied simulation state, leaving the rat unchanged until it accepts the update.
class_name NeedSystem extends Object

const DECAY_RATES := preload(
	"res://entities/rat/config/needs/need_decay_rate.tres"
)
const URGENCIES := preload(
	"res://entities/rat/config/needs/need_urgencies.tres"
)


## Calculates how strongly the rat wants each need fulfilled.
## Samples current satisfaction without changing the supplied needs.
static func calculate_need_urgencies(
	needs: Needs
) -> NeedUrgencyValues:
	var urgencies := NeedUrgencyValues.new()

	for need in NeedValues.get_keys():
		urgencies[need] = URGENCIES.need_urgencies[need].sample(
			needs[need]
		)

	return urgencies


## Applies one game tick of decay and location/job effects.
## Effective average urgency illustrates the rat's current want.
## A need being currently fulfilled contributes full need satisfaction,
## indicating ongoing relief.
## This function modifies the update draft only.
static func apply_tick_effects(
	draft: RatStateUpdateDraft,
	location_and_job_rates_per_game_hour: NeedRates
) -> void:
	var net_need_rates_per_game_hour := NeedRates.new()

	for need in NeedValues.get_keys():
		var net_need_rate_per_game_hour: float = (
			DECAY_RATES[need] + location_and_job_rates_per_game_hour[need]
		)
		net_need_rates_per_game_hour[need] = net_need_rate_per_game_hour

		var need_change_per_tick: float = (
			net_need_rate_per_game_hour
			/ GameConstants.GAME_TICKS_PER_IN_GAME_HOUR
		)
		draft.needs[need] += need_change_per_tick

	draft.effective_average_urgency = (
		URGENCIES.get_effective_average_urgency(
			draft.needs,
			net_need_rates_per_game_hour
		)
	)
