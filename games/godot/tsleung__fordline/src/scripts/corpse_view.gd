extends Node2D
## The fallen. Redrawn only when someone new has fallen, a few times a
## second at most.

const CAP := 4000

var _corpses: Array[Vector3] = []
var _dirty := false
var _wait := 0.0


func add(pos: Vector2, team: int) -> void:
	_corpses.append(Vector3(pos.x, pos.y, team))
	if _corpses.size() > CAP:
		_corpses = _corpses.slice(_corpses.size() - CAP)
	_dirty = true


func _process(delta: float) -> void:
	_wait -= delta
	if _dirty and _wait <= 0.0:
		_dirty = false
		_wait = 0.25
		queue_redraw()


func _draw() -> void:
	for i in _corpses.size():
		var c := _corpses[i]
		var p := Vector2(c.x, c.y)
		var color: Color = Palette.CORPSE[int(c.z)]
		var size := Vector2(4.0, 2.2) if i % 2 == 0 else Vector2(2.2, 4.0)
		draw_rect(Rect2(p - size * 0.5, size), color)
		if i % 5 == 0:
			draw_rect(Rect2(p + Vector2(1.5, 0.5), Vector2(1.8, 1.8)), Color(0.45, 0.05, 0.04, 0.5))
