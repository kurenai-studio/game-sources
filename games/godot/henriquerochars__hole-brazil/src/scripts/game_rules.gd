extends RefCounted
## Pure rules shared by the simulation and headless regression tests.

const ROUND_SECONDS: float = 90.0
const START_RADIUS: float = 29.0
const MAX_RADIUS: float = 156.0
const WORLD_SIZE: Vector2 = Vector2(1900.0, 1900.0)
const START_POSITION: Vector2 = Vector2(950.0, 1130.0)
const LEVEL_RADII: Array[float] = [29.0, 42.0, 59.0, 80.0, 106.0, 138.0]
const LEVEL_NAMES: Array[String] = ["Boca de urna", "Promessa de obra", "Caixa dois", "Coligação", "Maioria absoluta", "Engole Brasília"]
const PROP_TYPES: Array[Dictionary] = [
	{"kind": "paper", "name": "Promessa", "radius": 9.0, "mass": 10.0, "points": 10},
	{"kind": "cone", "name": "Obra parada", "radius": 16.0, "mass": 16.0, "points": 20},
	{"kind": "bench", "name": "Banco da praça", "radius": 25.0, "mass": 28.0, "points": 40},
	{"kind": "tree", "name": "Árvore", "radius": 36.0, "mass": 42.0, "points": 60},
	{"kind": "car", "name": "Carro oficial", "radius": 49.0, "mass": 76.0, "points": 110},
	{"kind": "kiosk", "name": "Gabinete", "radius": 70.0, "mass": 130.0, "points": 190},
	{"kind": "congress", "name": "Congresso de mentirinha", "radius": 112.0, "mass": 300.0, "points": 700},
]

static func valid_candidate(candidate: int) -> int:
	return clampi(candidate, 0, 2)

static func radius_for_mass(mass: float) -> float:
	return clampf(sqrt(START_RADIUS * START_RADIUS + maxf(mass, 0.0) * 9.0), START_RADIUS, MAX_RADIUS)

static func can_absorb(hole_radius: float, object_radius: float) -> bool:
	return hole_radius >= object_radius + 5.0

static func level_for_radius(radius: float) -> int:
	var level: int = 0
	for i in range(LEVEL_RADII.size()):
		if radius >= LEVEL_RADII[i]:
			level = i
	return level

static func growth_progress(radius: float) -> float:
	var level: int = level_for_radius(radius)
	if level >= LEVEL_RADII.size() - 1:
		return 1.0
	return clampf(inverse_lerp(LEVEL_RADII[level], LEVEL_RADII[level + 1], radius), 0.0, 1.0)

static func combo_multiplier(combo: int) -> float:
	return 1.0 + minf(floorf(float(maxi(combo - 1, 0)) / 5.0) * 0.25, 2.0)

static func combo_window(candidate: int) -> float:
	return 3.6 if valid_candidate(candidate) == 2 else 2.6

static func movement_speed(candidate: int, radius: float) -> float:
	return (285.0 if valid_candidate(candidate) == 0 else 264.0) * lerpf(1.0, 0.88, clampf((radius - START_RADIUS) / (MAX_RADIUS - START_RADIUS), 0.0, 1.0))

static func growth_mass(base_mass: float, candidate: int) -> float:
	return maxf(base_mass, 0.0) * (1.12 if valid_candidate(candidate) == 1 else 1.0)

static func score_for(base_points: int, combo: int) -> int:
	return roundi(float(maxi(base_points, 0)) * combo_multiplier(combo))

static func bounded_position(position: Vector2, radius: float) -> Vector2:
	var margin: float = maxf(radius, 24.0) + 12.0
	return position.clamp(Vector2.ONE * margin, WORLD_SIZE - Vector2.ONE * margin)
