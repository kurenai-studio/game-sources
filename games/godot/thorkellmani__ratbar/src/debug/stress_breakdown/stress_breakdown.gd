## Displays the prepared stress breakdown for the selected rat.
class_name DebugStressBreakdown extends FoldableContainer


#region State

@onready var _average_urgency_label: Label = $Details/AverageUrgency
@onready var _need_tier_label: Label = $Details/NeedTier
@onready var _working_rate_label: Label = $Details/WorkingRate
@onready var _net_rate_label: Label = $Details/NetRate

#endregion


#region Display

func display_stress_breakdown(
	display_data: RatDebugDisplayData
) -> void:
	var average_urgency: float = (
		display_data.state_snapshot.effective_average_urgency
	)

	if is_nan(average_urgency):
		_average_urgency_label.text = "Average urgency: --"
		_need_tier_label.text = "Need tier: --"
		_working_rate_label.text = "Working: --"
		_net_rate_label.text = "Net stress rate: --"
		return

	_average_urgency_label.text = (
		"Average urgency: %.3f" % average_urgency
	)
	_need_tier_label.text = "Need tier: %s (%s)" % [
		display_data.need_tier_label,
		_format_hourly_rate(
			display_data.need_stress_rate_per_game_hour
		),
	]
	_working_rate_label.text = "Working: %s" % (
		_format_hourly_rate(
			display_data.working_stress_rate_per_game_hour
		)
	)
	_net_rate_label.text = "Net stress rate: %s" % (
		_format_hourly_rate(
			display_data.net_stress_rate_per_game_hour
		)
	)

#endregion


#region Formatting

func _format_hourly_rate(rate: float) -> String:
	return ("+" if rate > 0.0 else "") + ("%.0f/h" % rate)

#endregion
