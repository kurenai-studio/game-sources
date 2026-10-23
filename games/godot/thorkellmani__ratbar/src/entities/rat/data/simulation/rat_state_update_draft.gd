## Holds copied rat values for systems to prepare a state update.
## The rat validates and accepts the completed draft.
class_name RatStateUpdateDraft extends RefCounted

var rat_id: int
var needs: Needs
var stress: float
var effective_average_urgency: float


func _init(
	source_rat_id: int,
	source_needs: Needs,
	source_stress: float,
	source_effective_average_urgency: float
) -> void:
	rat_id = source_rat_id
	needs = source_needs.duplicate(true) as Needs
	stress = source_stress
	effective_average_urgency = source_effective_average_urgency


## Checks the calculated values before the rat accepts the draft.
## Needs and Status enforce their bounds when values are applied.
func validate() -> Error:
	if needs == null:
		push_error("Update draft for rat %d is missing needs." % rat_id)
		return ERR_INVALID_PARAMETER

	for need in NeedValues.get_keys():
		if not is_finite(needs[need]):
			push_error(
				"Update draft for rat %d has a non-finite value for '%s'."
				% [rat_id, need]
			)
			return ERR_INVALID_PARAMETER

	if not is_finite(stress):
		push_error(
			"Update draft for rat %d has non-finite stress." % rat_id
		)
		return ERR_INVALID_PARAMETER

	if (
		not is_finite(effective_average_urgency)
		or effective_average_urgency < 0.0
		or effective_average_urgency > 1.0
	):
		push_error(
			"Update draft for rat %d has invalid effective average urgency."
			% rat_id
		)
		return ERR_INVALID_PARAMETER

	return OK
