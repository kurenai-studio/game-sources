# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name GlyphIcon
extends Control
## A square picture drawn in code with the theme's silhouettes: a HUD glyph
## (heart, coin, moon, star, gate), a tower or a creature. It never takes touches.

enum Kind { NONE, GLYPH, TOWER, ENEMY }

var kind: Kind = Kind.NONE
var id: StringName = &""
var tier: int = 1
var spec: int = -1
## Draw with the ink lines only, in one color, when set (a "locked" look).
var flat: Color = Silhouettes.NO_FLAT


func _init(side: float = 96.0) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(side, side)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func show_glyph(glyph: StringName) -> GlyphIcon:
	kind = Kind.GLYPH
	id = glyph
	queue_redraw()
	return self


func show_tower(type: StringName, at_tier: int = 1, at_spec: int = -1) -> GlyphIcon:
	kind = Kind.TOWER
	id = type
	tier = at_tier
	spec = at_spec
	queue_redraw()
	return self


func show_enemy(type: StringName) -> GlyphIcon:
	kind = Kind.ENEMY
	id = type
	queue_redraw()
	return self


func _draw() -> void:
	var side: float = minf(size.x, size.y)
	if side <= 0.0:
		return
	var middle: Vector2 = size * 0.5
	match kind:
		Kind.GLYPH:
			Silhouettes.draw_glyph(self, id, middle, side * 0.9, flat)
		Kind.TOWER:
			if Silhouettes.has_tower(id):
				# A tower reaches 0.85 above its center and 0.30 below: 1.15 in all.
				var unit: float = side / 1.2
				var top: float = (side - 1.15 * unit) * 0.5
				Silhouettes.draw_tower(self, id, tier, spec, Vector2(middle.x, top + 0.85 * unit), unit, flat)
		Kind.ENEMY:
			if Silhouettes.has_enemy(id):
				var box: float = side * 0.9
				Silhouettes.draw_enemy(self, id, middle + Vector2(0.0, -0.06 * side), box, 0, flat)
