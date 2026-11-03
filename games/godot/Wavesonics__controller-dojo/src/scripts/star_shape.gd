extends RefCounted


static func points(center: Vector2, outer: float, inner: float, spin: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var radius: float = outer if i % 2 == 0 else inner
		var angle: float = -PI * 0.5 + spin + PI * 0.2 * i
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts
