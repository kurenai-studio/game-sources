extends Node3D

@export_node_path("Area3D") var _area: NodePath
@onready var area: Area3D = get_node(_area)

@export var liquid_type: int = 0

# OBJECT: swim_areas: Dictionary
func _on_body_entered(body: Node3D) -> void:
	if typeof(body.get("swim_areas")) == TYPE_DICTIONARY:
		body.swim_areas[self] = liquid_type

# OBJECT: swim_areas: Dictionary
func _on_body_exited(body: Node3D) -> void:
	if typeof(body.get("swim_areas")) == TYPE_DICTIONARY:
		body.swim_areas.erase(self)

# OBJECT: receive_damage(from: Node, value: float)
func _on_wait_timer_timeout() -> void:
	for body in area.get_overlapping_bodies():
		if not body.has_method("receive_damage"): continue
		body.receive_damage(self, float(liquid_type)) # TODO:


func has_point(point: Vector3) -> bool:
	for child in area.find_children("*", "CollisionShape3D", false):
		if not child.has_meta("AABB"): continue
		if not child.has_meta("PLANES"): continue

		var aabb: AABB = child.get_meta("AABB")
		if not aabb.has_point(point): continue

		var has := true
		for plane in child.get_meta("PLANES"):
			if plane.is_point_over(point):
				if not is_zero_approx(plane.distance_to(point)):
					has = false
					break

		if has: return true
	return false
