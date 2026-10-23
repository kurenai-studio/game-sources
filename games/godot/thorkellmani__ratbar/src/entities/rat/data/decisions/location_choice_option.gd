## Holds the information used to score one possible destination.
## Copies its appeal so scoring does not access live location values.
class_name LocationChoiceOption extends RefCounted

var title: String
var pull: LocationPull
var employment_pressure: float


func _init(
	location_title: String,
	location_pull: LocationPull,
	location_employment_pressure: float
) -> void:
	title = location_title
	pull = location_pull.duplicate() as LocationPull
	employment_pressure = location_employment_pressure
