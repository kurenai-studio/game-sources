## Holds this rat's relationship values, keyed by the other rat's ID.
## Announces changes after adding, removing, or updating a relationship.
class_name Camaraderie extends Resource

signal stat_changed

const MIN_RELATIONSHIP_VALUE: float = -100.0
const MAX_RELATIONSHIP_VALUE: float = 100.0

@export var camaraderie: Dictionary[int, float] = {}


## Adds or replaces a relationship, keeping its initial value within bounds.
func add_relationship(rat_id: int, value: float = 0.0) -> void:
	camaraderie[rat_id] = clampf(
		value,
		MIN_RELATIONSHIP_VALUE,
		MAX_RELATIONSHIP_VALUE
	)
	stat_changed.emit()


func remove_relationship(rat_id: int) -> void:
	if rat_id in camaraderie:
		camaraderie.erase(rat_id)
		stat_changed.emit()


func update_relationship(rat_id: int, modifier: float) -> void:
	if rat_id in camaraderie:
		camaraderie[rat_id] = clampf(
			camaraderie[rat_id] + modifier,
			MIN_RELATIONSHIP_VALUE,
			MAX_RELATIONSHIP_VALUE
		)
		stat_changed.emit()


func _get_min() -> float:
	return MIN_RELATIONSHIP_VALUE


func _get_max() -> float:
	return MAX_RELATIONSHIP_VALUE
