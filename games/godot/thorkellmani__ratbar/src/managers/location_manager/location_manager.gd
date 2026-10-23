extends Node2D

class_name LocationManager

var _locations_valid: bool = false


func _ready() -> void:
	_locations_valid = _validate_location_ids()


## Checks that each scene location has a nonempty, unique identity.
func _validate_location_ids() -> bool:
	var seen_ids: Dictionary[StringName, bool] = {}

	for child in get_children():
		if not child is Location:
			continue

		var location := child as Location

		if location.location_id.is_empty():
			push_error(
				"Location '%s' is missing its location ID."
				% location.name
			)
			return false

		if seen_ids.has(location.location_id):
			push_error(
				"Location '%s' repeats location ID '%s'."
				% [location.name, location.location_id]
			)
			return false

		seen_ids[location.location_id] = true

	return true


## Returns the location matching this ID, or null if none is available.
func get_location_by_id(location_id: StringName) -> Location:
	if not _locations_valid or location_id.is_empty():
		return null

	for child in get_children():
		if child is Location and child.location_id == location_id:
			return child

	return null


## Returns the scene's locations in their existing child order.
func get_location_data() -> Array[Location]:
	var locations: Array[Location] = []

	if not _locations_valid:
		return locations

	for child in get_children():
		if child is Location:
			locations.append(child)

	return locations
