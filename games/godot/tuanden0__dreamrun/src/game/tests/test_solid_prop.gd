extends "res://tests/test_case.gd"

const KINDS := {
	SolidProp.Kind.GROUND: Vector2(2000, 200),
	SolidProp.Kind.SLAB: Vector2(240, 26),
	SolidProp.Kind.PILLAR: Vector2(60, 300),
	SolidProp.Kind.BOULDER: Vector2(130, 70),
}


func _bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0], Vector2.ZERO)
	for p in points:
		rect = rect.expand(p)
	return rect


func test_outlines_are_irregular_deterministic_and_sized() -> void:
	for kind in KINDS:
		var size: Vector2 = KINDS[kind]
		var outline := SolidProp.build_outline(kind, size, 7, 4.0)
		check(outline.size() > 8, "kind %s should have many vertices, got %d" % [kind, outline.size()])
		check(outline == SolidProp.build_outline(kind, size, 7, 4.0), "kind %s must be deterministic per seed" % kind)
		check(outline != SolidProp.build_outline(kind, size, 8, 4.0), "kind %s must change with the seed" % kind)
		var box := _bounds(outline)
		check(absf(box.size.x - size.x) < size.x * 0.35, "kind %s width %s far from %s" % [kind, box.size.x, size.x])
		check(absf(box.size.y - size.y) < size.y * 0.5 + 12.0, "kind %s height %s far from %s" % [kind, box.size.y, size.y])


func test_node_shares_one_outline_for_visual_collision_and_shadow() -> void:
	var prop := SolidProp.new()
	prop.kind = SolidProp.Kind.SLAB
	prop.size = Vector2(240, 26)
	tree.root.add_child(prop)
	var shape := prop.get_node("Shape") as Polygon2D
	var collision := prop.get_node("Collision") as CollisionPolygon2D
	var occluder := prop.get_node("Occluder") as LightOccluder2D
	check(shape.polygon == collision.polygon, "collision must use the visible outline")
	check(shape.polygon == occluder.occluder.polygon, "occluder must use the visible outline")
	check(shape.vertex_colors.size() == shape.polygon.size(), "one shade colour per vertex")
	prop.queue_free()
	await frames(1)


func test_non_solid_prop_has_no_collision() -> void:
	var prop := SolidProp.new()
	prop.solid = false
	prop.casts_shadow = false
	tree.root.add_child(prop)
	check(not prop.has_node("Collision") and not prop.has_node("Occluder"), "solid/casts_shadow off must skip nodes")
	prop.queue_free()
	await frames(1)
