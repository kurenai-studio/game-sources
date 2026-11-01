extends Control
## A battle's field and both armies where they deploy, drawn small: the
## briefing's picture of what is coming. Uses the battle's own terrain
## painter, so the preview and the field are the same picture.

const TerrainView := preload("res://scripts/terrain_view.gd")

var _terrain: Node2D
var _marks: Marks
## The shown field's extent, for fitting it.
var _field := Terrain.SIZE


func _ready() -> void:
	clip_contents = true
	_ensure_children()
	_fit()


## Fit whenever the size settles, including a size set before the preview
## joined the tree (then no resize arrives later).
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _terrain != null:
		_fit()


## Show `b` as deployed. `field_seed` must match the battle screen's, so
## the field patches are the same: the hash of the battle's title.
func show_battle(b: Battle, field_seed: int) -> void:
	_ensure_children()
	_terrain.show_terrain(b.terrain, field_seed)
	_field = b.terrain.size
	_marks.battle = b
	_marks.queue_redraw()
	_fit()


func _ensure_children() -> void:
	if _terrain != null:
		return
	_terrain = TerrainView.new()
	add_child(_terrain)
	_marks = Marks.new()
	add_child(_marks)


func _fit() -> void:
	var s := minf(size.x / _field.x, size.y / _field.y)
	for child in [_terrain, _marks]:
		child.scale = Vector2(s, s)
		child.position = (size - _field * s) * 0.5
	_marks.queue_redraw()


## Flags, soldiers and banners, sized for a small picture.
class Marks extends Node2D:
	var battle: Battle

	func _draw() -> void:
		if battle == null:
			return
		var p := 1.0 / maxf(scale.x, 0.001)
		for f in battle.flags:
			var owner: int = f.owner
			var color: Color = Palette.NEUTRAL if owner < 0 else Palette.TEAM[owner]
			draw_arc(f.pos, Battle.FLAG_RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.45), 1.5 * p)
			draw_line(f.pos, f.pos + Vector2(0, -16.0 * p), Color(0.2, 0.15, 0.1), 1.5 * p)
			draw_colored_polygon(PackedVector2Array([
				f.pos + Vector2(0, -16.0 * p), f.pos + Vector2(10.0 * p, -13.0 * p), f.pos + Vector2(0, -10.0 * p),
			]), color)
		for r in battle.regiments:
			var body: Color = Palette.TEAM[r.team]
			for s in r.soldiers:
				draw_rect(Rect2(s - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), body)
		for r in battle.regiments:
			Glyphs.banner(self, r.kind, r.team, r.pos, 7.0 * p, r.strength(), false, false, false)
