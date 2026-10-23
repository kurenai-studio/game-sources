## Holds the rat's current values.
## The rat owns this state and handles requests to change it.
class_name RatState extends Resource

@export_group("Identity")
@export var rat_id: int
@export var title: String

@export_group("Needs")
@export var needs: Needs
@export var effective_average_urgency: float = NAN
@export var locked_need: String

@export_group("Personality")
@export var personality: Personality

@export_group("Status")
@export var status: Status
@export var crisis: RatConstants.CRISIS = RatConstants.CRISIS.UNAFFECTED

@export_group("Relationships")
@export var camaraderie: Camaraderie
@export var owner_relationship: float = 0.0

@export_group("Economy")
@export var currency: float = 0.0

@export_group("Activity")
@export var activity_state: RatConstants.STATE = RatConstants.STATE.IDLE
@export var current_location_id: StringName = &""
@export var destination_id: StringName = &""


## Checks the complete proposed state before the rat accepts it.
func validate() -> Error:
	var checks: Array[Callable] = [
		_validate_numeric_attributes.bind(
			needs, Needs.get_keys(), "needs"
		),
		_validate_numeric_attributes.bind(
			personality, Personality.get_keys(), "personality"
		),
		_validate_numeric_attributes.bind(
			status, Status.get_keys(), "status"
		),
		_validate_relationship_values,
		_validate_activity_values,
		_validate_scalar_values,
	]

	for check in checks:
		var validation_error: Error = check.call()

		if validation_error != OK:
			return validation_error

	return OK


## Compares stored values, including the nested attribute Resources.
func is_equal_to(other: RatState) -> bool:
	return _have_same_resource_values(self, other)


func _have_same_resource_values(
	first: Resource,
	second: Resource
) -> bool:
	if first == null or second == null:
		return first == second

	if first.get_script() != second.get_script():
		return false

	for property in first.get_property_list():
		var usage: int = property.usage

		if (usage & PROPERTY_USAGE_STORAGE) == 0:
			continue
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue

		if not _have_same_property_value(
			first.get(property.name),
			second.get(property.name)
		):
			return false

	return true


func _have_same_property_value(
	first: Variant,
	second: Variant
) -> bool:
	if first is Resource or second is Resource:
		if not (first is Resource and second is Resource):
			return false

		return _have_same_resource_values(first, second)

	if first is float and second is float:
		if is_nan(first) and is_nan(second):
			return true

	return first == second


func _validate_scalar_values() -> Error:
	if not is_finite(currency):
		push_error("State for rat %d has non-finite currency." % rat_id)
		return ERR_INVALID_PARAMETER

	if crisis not in RatConstants.CRISIS.values():
		push_error(
			"State for rat %d has unknown crisis %d." % [rat_id, crisis]
		)
		return ERR_INVALID_PARAMETER

	if locked_need != "" and locked_need not in NeedValues.get_keys():
		push_error(
			"State for rat %d has unknown locked need '%s'."
			% [rat_id, locked_need]
		)
		return ERR_INVALID_PARAMETER

	if not is_nan(effective_average_urgency):
		if (
			not is_finite(effective_average_urgency)
			or effective_average_urgency < 0.0
			or effective_average_urgency > 1.0
		):
			push_error("State for rat %d has invalid average urgency." % rat_id)
			return ERR_INVALID_PARAMETER

	return OK


func _validate_activity_values() -> Error:
	var locations_match_activity: bool = false

	match activity_state:
		RatConstants.STATE.TRAVELLING:
			locations_match_activity = (
				current_location_id == &""
				and destination_id != &""
			)
		RatConstants.STATE.WORKING:
			locations_match_activity = (
				current_location_id != &""
				and destination_id == &""
			)
		RatConstants.STATE.IDLE:
			locations_match_activity = destination_id == &""
		_:
			push_error(
				"State for rat %d has unknown activity %d."
				% [rat_id, activity_state]
			)
			return ERR_INVALID_PARAMETER

	if not locations_match_activity:
		push_error(
			"State for rat %d has locations incompatible with activity %d."
			% [rat_id, activity_state]
		)
		return ERR_INVALID_PARAMETER

	return OK


func _validate_relationship_values() -> Error:
	if not is_finite(owner_relationship):
		push_error(
			"State for rat %d has non-finite owner relationship."
			% rat_id
		)
		return ERR_INVALID_PARAMETER

	if camaraderie == null:
		push_error(
			"State for rat %d is missing camaraderie."
			% rat_id
		)
		return ERR_INVALID_PARAMETER

	for other_rat_id in camaraderie.camaraderie:
		if not is_finite(camaraderie.camaraderie[other_rat_id]):
			push_error(
				"State for rat %d has non-finite camaraderie with rat %d."
				% [rat_id, other_rat_id]
			)
			return ERR_INVALID_PARAMETER

	return OK


func _validate_numeric_attributes(
	attributes: Resource,
	field_names: Array[String],
	group_name: String
) -> Error:
	if attributes == null:
		push_error(
			"State for rat %d is missing %s."
			% [rat_id, group_name]
		)
		return ERR_INVALID_PARAMETER

	for field_name in field_names:
		var value: Variant = attributes.get(field_name)

		if not (value is float or value is int):
			push_error(
				"State for rat %d has invalid %s.%s."
				% [rat_id, group_name, field_name]
			)
			return ERR_INVALID_PARAMETER

		if not is_finite(float(value)):
			push_error(
				"State for rat %d has non-finite %s.%s."
				% [rat_id, group_name, field_name]
			)
			return ERR_INVALID_PARAMETER

	return OK
