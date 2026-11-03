class_name ArenaGenerator
extends RefCounted
## Seeded procedural arena: a colour theme, obstacle pillars and environmental hazards.

enum Hazard { BURN, SLOW, SHOCK }

const DEFAULT_SIZE := Vector2(2400, 1600)
const SAFE_RADIUS := 320.0
const THEMES: Array[Dictionary] = [
	{"key": "THEME_NEON", "bg": Color(0.035, 0.045, 0.085), "grid": Color(0.2, 0.75, 1.0), "accent": Color(0.25, 0.9, 1.0), "hazard": Hazard.SHOCK},
	{"key": "THEME_EMBER", "bg": Color(0.07, 0.035, 0.035), "grid": Color(1.0, 0.45, 0.2), "accent": Color(1.0, 0.35, 0.2), "hazard": Hazard.BURN},
	{"key": "THEME_FROST", "bg": Color(0.03, 0.06, 0.09), "grid": Color(0.55, 0.85, 1.0), "accent": Color(0.7, 0.95, 1.0), "hazard": Hazard.SLOW},
	{"key": "THEME_TOXIC", "bg": Color(0.03, 0.07, 0.045), "grid": Color(0.45, 1.0, 0.4), "accent": Color(0.6, 1.0, 0.3), "hazard": Hazard.BURN},
]


static func generate(seed_value: int, size: Vector2 = DEFAULT_SIZE) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var theme_index := rng.randi_range(0, THEMES.size() - 1)
	var center := size / 2.0
	var margin := 120.0
	var obstacles: Array[Rect2] = []
	var target_obstacles := rng.randi_range(7, 11)
	var tries := 0
	while obstacles.size() < target_obstacles and tries < 400:
		tries += 1
		var s := Vector2(rng.randf_range(60, 150), rng.randf_range(60, 150))
		var p := Vector2(rng.randf_range(margin, size.x - margin - s.x), rng.randf_range(margin, size.y - margin - s.y))
		var r := Rect2(p, s)
		if _too_close(r, center, SAFE_RADIUS) or _overlaps_any(r.grow(90.0), obstacles):
			continue
		obstacles.append(r)
	var hazards: Array[Dictionary] = []
	var hazard_type: int = THEMES[theme_index]["hazard"]
	var target_hazards := rng.randi_range(3, 5)
	tries = 0
	while hazards.size() < target_hazards and tries < 400:
		tries += 1
		var s := Vector2(rng.randf_range(170, 300), rng.randf_range(150, 260))
		var p := Vector2(rng.randf_range(margin, size.x - margin - s.x), rng.randf_range(margin, size.y - margin - s.y))
		var r := Rect2(p, s)
		if _too_close(r, center, SAFE_RADIUS) or _overlaps_any(r.grow(30.0), obstacles):
			continue
		var clash := false
		for h in hazards:
			if (h["rect"] as Rect2).grow(60.0).intersects(r):
				clash = true
				break
		if clash:
			continue
		hazards.append({"rect": r, "type": hazard_type})
	return {"seed": seed_value, "size": size, "theme": theme_index, "obstacles": obstacles, "hazards": hazards}


static func _too_close(r: Rect2, center: Vector2, radius: float) -> bool:
	var closest := Vector2(clampf(center.x, r.position.x, r.end.x), clampf(center.y, r.position.y, r.end.y))
	return closest.distance_to(center) < radius


static func _overlaps_any(r: Rect2, list: Array[Rect2]) -> bool:
	for o in list:
		if o.intersects(r):
			return true
	return false


static func point_blocked(p: Vector2, obstacles: Array[Rect2], pad: float = 0.0) -> bool:
	for o in obstacles:
		if o.grow(pad).has_point(p):
			return true
	return false
