## Holds captured rat values and prepared information for display.
class_name RatDebugDisplayData extends RefCounted

var state_snapshot: RatState
var assigned_job_title: String = "Unassigned"
var current_location_title: String = ""

var need_tier_label: String
var need_stress_rate_per_game_hour: float = NAN
var working_stress_rate_per_game_hour: float = NAN
var net_stress_rate_per_game_hour: float = NAN


func _init(snapshot: RatState) -> void:
	state_snapshot = snapshot
