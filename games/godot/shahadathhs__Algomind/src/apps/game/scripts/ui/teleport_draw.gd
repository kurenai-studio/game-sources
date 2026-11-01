class_name TeleportDraw
extends RefCounted
## Teleporters (`teleports`), drawn the same way on the flat and the depth board; `place` maps a
## point in board units to the canvas, as in LockDraw. Each end is two concentric rings (the target
## is a ring around a solid dot). With several pairs, the two ends of a pair carry the same number
## of pips, so the pairing is never only a color.


static func draw(canvas: CanvasItem, level: Dictionary, place: Callable, ink: Color) -> void:
	var pairs: Array = level["teleports"]
	for i in pairs.size():
		for part in ["a", "b"]:
			var cell := LockDraw.cell_of(pairs[i], part)
			var center := Vector2(0.5, 0.45) if pairs.size() > 1 else Vector2(0.5, 0.5)
			for radius in [0.32, 0.17]:
				var outline := PackedVector2Array()
				for point in LockDraw.ring(center, radius):
					outline.append(place.call(Vector2(cell) + point))
				outline.append(outline[0])
				canvas.draw_polyline(outline, ink, 2.5)
			if pairs.size() > 1:
				LockDraw.pips(canvas, place, cell, i, ink)
