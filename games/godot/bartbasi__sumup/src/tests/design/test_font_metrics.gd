extends "res://tests/base_test.gd"
## The font metrics in src/design/shared/font_metrics.gd hold for every
## skin's display, body and label fonts (DESIGN_SYSTEM.md 3.4), measured from
## the glyph outlines the way tools/label_check.gd measures digits. Slate is
## measured in this machine's system font (Segoe UI on Windows).

const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")
const ROLES: Array[StringName] = [&"display", &"body", &"label"]
## Font size the outlines are measured at.
const MEASURE_SIZE: int = 400
## How far a measured cap height may sit from CAP_HEIGHT.
const CAP_TOLERANCE: float = 0.02


func test_cap_height_matches_every_font() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for role: StringName in ROLES:
			var extent: Vector2 = _extent(skin.font(role), "H")
			assert_true(extent != Vector2.ZERO, "%s %s: H measured" % [skin_id, role])
			var cap: float = -extent.x / float(MEASURE_SIZE)
			assert_near(cap, FontMetrics.CAP_HEIGHT, CAP_TOLERANCE, "%s %s cap height" % [skin_id, role])


func test_comma_depth_bounds_every_font() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for role: StringName in ROLES:
			var extent: Vector2 = _extent(skin.font(role), ",")
			assert_true(extent != Vector2.ZERO, "%s %s: comma measured" % [skin_id, role])
			var depth: float = extent.y / float(MEASURE_SIZE)
			assert_true(depth > 0.0, "%s %s: the comma reaches below the baseline" % [skin_id, role])
			assert_true(depth <= FontMetrics.COMMA_DEPTH, "%s %s comma depth %.3f is within %.2f" % [skin_id, role, depth, FontMetrics.COMMA_DEPTH])


## The top and bottom of a character's outline at MEASURE_SIZE, as
## (top, bottom) in px from the baseline, y down. Zero when it has no outline.
func _extent(font: Font, character: String) -> Vector2:
	var server: TextServer = TextServerManager.get_primary_interface()
	for rid: RID in font.get_rids():
		var glyph: int = server.font_get_glyph_index(rid, MEASURE_SIZE, character.unicode_at(0), 0)
		if glyph == 0:
			continue
		var outline: Dictionary = server.font_get_glyph_contours(rid, MEASURE_SIZE, glyph)
		var points: PackedVector3Array = outline.get("points", PackedVector3Array())
		if points.is_empty():
			continue
		var top: float = INF
		var bottom: float = -INF
		for point: Vector3 in points:
			top = minf(top, point.y)
			bottom = maxf(bottom, point.y)
		return Vector2(top, bottom)
	return Vector2.ZERO
