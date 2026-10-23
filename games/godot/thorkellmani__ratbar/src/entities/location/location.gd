class_name Location extends Marker2D

## Identifies this location independently of its display title or scene path.
@export var location_id: StringName = &""

@export var modifiers: LocationModifiers = LocationModifiers.new()
@export var title: String = ""
@export var pull: LocationPull = LocationPull.new()
