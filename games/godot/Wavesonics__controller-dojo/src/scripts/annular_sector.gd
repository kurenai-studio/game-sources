extends RefCounted


static func build(
	center: Vector2, inner: float, outer: float, from: float, to: float, steps: int = 28
) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in steps + 1:
		var angle: float = lerpf(from, to, float(i) / steps)
		pts.append(center + Vector2(cos(angle), sin(angle)) * outer)
	for i in steps + 1:
		var angle: float = lerpf(to, from, float(i) / steps)
		pts.append(center + Vector2(cos(angle), sin(angle)) * inner)
	return pts
