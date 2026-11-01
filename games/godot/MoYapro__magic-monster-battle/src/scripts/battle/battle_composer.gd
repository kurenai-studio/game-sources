class_name BattleComposer

enum BattleType { HORDE, ELITE }

const MIN_MONSTERS := 2
const MAX_LEVEL    := 10
const BUDGET_L1    := 25   # total difficulty budget at level 1  (~2 easy monsters)
const BUDGET_L10   := 500  # total difficulty budget at level 10



static func compose(biome: BiomeData, biome_level: int, rng: RandomNumberGenerator) -> Dictionary:
	var elite_chance := 0.5 * clampf(float(biome_level - 1) / float(MAX_LEVEL - 1), 0.0, 1.0)
	var battle_type: BattleType = BattleType.ELITE if rng.randf() < elite_chance else BattleType.HORDE
	var enemies := _select_monsters(biome.monster_pool, battle_type, biome_level, rng)
	var obstacles := _select_obstacles(biome.obstacle_pool, rng)

	# Obstacles placed first — they claim front rows before enemies.
	var occupied: Dictionary = {}
	var raw_obs_pos := _place_items(obstacles, rng, occupied)
	var raw_enemy_pos := _place_items(enemies, rng, occupied)

	var placed_obstacles: Array[ObstacleData] = []
	var placed_obs_positions: Array[Vector2i] = []
	for i in obstacles.size():
		if raw_obs_pos[i].x >= 0:
			placed_obstacles.append(obstacles[i])
			placed_obs_positions.append(raw_obs_pos[i])

	var placed_enemies: Array[EnemyData] = []
	var placed_positions: Array[Vector2i] = []
	for i in enemies.size():
		if raw_enemy_pos[i].x >= 0:
			placed_enemies.append(enemies[i])
			placed_positions.append(raw_enemy_pos[i])

	return {
		"enemies": placed_enemies,
		"positions": placed_positions,
		"obstacles": placed_obstacles,
		"obstacle_positions": placed_obs_positions,
	}


static func _select_monsters(
	pool: Array,
	battle_type: BattleType,
	biome_level: int,
	rng: RandomNumberGenerator
) -> Array[EnemyData]:
	var sorted_pool := _sort_by_difficulty(pool)
	var ratings := _build_ratings(sorted_pool)
	var budget := _difficulty_budget(biome_level)

	var candidates: Array = _lower_half(sorted_pool) \
		if battle_type == BattleType.HORDE else _upper_half(sorted_pool)

	var enemies: Array[EnemyData] = []
	var id_counts: Dictionary = {}
	var spent := 0

	# Keep picking while something in the candidate pool is still affordable.
	while true:
		var affordable := candidates.filter(func(cls): return ratings[cls] <= budget - spent)
		if affordable.is_empty():
			break
		var cls: GDScript = affordable[rng.randi() % affordable.size()]
		var enemy: EnemyData = cls.new()
		var base_id := enemy.display_name.to_lower().replace(" ", "_")
		id_counts[base_id] = id_counts.get(base_id, 0) + 1
		enemy.id = base_id + "_" + str(id_counts[base_id])
		enemies.append(enemy)
		spent += ratings[cls]

	# Guarantee minimum even when budget was exhausted before reaching it.
	while enemies.size() < MIN_MONSTERS:
		var cls: GDScript = candidates[0]  # cheapest in sorted candidates
		var enemy: EnemyData = cls.new()
		var base_id := enemy.display_name.to_lower().replace(" ", "_")
		id_counts[base_id] = id_counts.get(base_id, 0) + 1
		enemy.id = base_id + "_" + str(id_counts[base_id])
		enemies.append(enemy)

	return enemies


static func _select_obstacles(pool: Array, rng: RandomNumberGenerator) -> Array[ObstacleData]:
	var weights: Array[int] = []
	var total_weight := 0
	for cls in pool:
		var w: int = cls.new().generation_weight
		weights.append(w)
		total_weight += w

	var count := rng.randi_range(4, 6)
	var obstacles: Array[ObstacleData] = []
	var id_counts: Dictionary = {}
	for _i in count:
		var roll := rng.randi_range(0, total_weight - 1)
		var cumulative := 0
		var chosen_cls: Variant = pool[pool.size() - 1]
		for j in pool.size():
			cumulative += weights[j]
			if roll < cumulative:
				chosen_cls = pool[j]
				break
		var obstacle: ObstacleData = chosen_cls.new()
		var base_id := obstacle.display_name.to_lower()
		id_counts[base_id] = id_counts.get(base_id, 0) + 1
		obstacle.id = base_id + "_" + str(id_counts[base_id])
		obstacles.append(obstacle)

	return obstacles


# Total difficulty budget for a given biome level, scaling linearly from
# BUDGET_L1 at level 1 to BUDGET_L10 at MAX_LEVEL.
static func _difficulty_budget(biome_level: int) -> int:
	var t := clampf(float(biome_level - 1) / float(MAX_LEVEL - 1), 0.0, 1.0)
	return int(lerpf(float(BUDGET_L1), float(BUDGET_L10), t))


# Returns a difficulty_rating lookup keyed by GDScript class reference.
static func _build_ratings(sorted_pool: Array) -> Dictionary:
	var ratings := {}
	for cls in sorted_pool:
		ratings[cls] = (cls as GDScript).new().difficulty_rating
	return ratings


static func _sort_by_difficulty(pool: Array) -> Array:
	var sorted := pool.duplicate()
	var cache: Dictionary = {}
	for cls in sorted:
		cache[cls] = (cls as GDScript).new().difficulty_rating
	sorted.sort_custom(func(a: GDScript, b: GDScript) -> bool: return cache[a] < cache[b])
	return sorted


# Returns the easier half of the pool (for Horde).
# Pools of size <= 2 return the full pool so both battle types have variety.
static func _lower_half(sorted_pool: Array) -> Array:
	if sorted_pool.size() <= 2:
		return sorted_pool.duplicate()
	return sorted_pool.slice(0, sorted_pool.size() / 2 + 1)


# Returns the harder half of the pool (for Elite).
# Pools of size <= 2 return the full pool so both battle types have variety.
static func _upper_half(sorted_pool: Array) -> Array:
	if sorted_pool.size() <= 2:
		return sorted_pool.duplicate()
	return sorted_pool.slice(sorted_pool.size() / 2)


# Places any items with .main_role and .grid_size, biased by role order.
# Mutates occupied so callers can chain multiple placement passes.
static func _place_items(items: Array, rng: RandomNumberGenerator, occupied: Dictionary) -> Array[Vector2i]:
	var order := range(items.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		return int(items[a].main_role) < int(items[b].main_role)
	)

	var positions: Array[Vector2i] = []
	positions.resize(items.size())

	for i in order:
		var grid_size: Vector2i = items[i].grid_size
		var role: MonsterRole.Type = items[i].main_role
		var valid: Array[Vector2i] = []
		for col in range(EnemyGrid.COLS - grid_size.x + 1):
			for row in range(EnemyGrid.ROWS - grid_size.y + 1):
				var pos := Vector2i(col, row)
				if _can_place(pos, grid_size, occupied):
					valid.append(pos)
		if valid.is_empty():
			positions[i] = Vector2i(-1, -1)
			continue
		var _raw_off_role: Variant = items[i].get("off_role")
		var off_role: MonsterRole.Type = _raw_off_role if _raw_off_role != null else MonsterRole.Type.NONE
		var pref_col := _blended_col(role, off_role)
		var chosen := _pick_biased(valid, pref_col, rng)
		positions[i] = chosen
		for dx in range(grid_size.x):
			for dy in range(grid_size.y):
				occupied[chosen + Vector2i(dx, dy)] = true

	return positions


# Maps a role's enum value onto a preferred grid column (0 = left/front, COLS-1 = right/back).
# Returns -1 for NONE and OBSTACLE, meaning no column preference (place randomly).
static func _preferred_col(role: MonsterRole.Type) -> int:
	if role == MonsterRole.Type.NONE or role == MonsterRole.Type.OBSTACLE:
		return -1
	return int(round(float(role - MonsterRole.Type.TANK) / float(MonsterRole.Type.ARTILLERY - MonsterRole.Type.TANK) * (EnemyGrid.COLS - 1)))


# Blends main and off role preferred columns (2:1 weight). Falls back to main only if off is NONE.
static func _blended_col(main_role: MonsterRole.Type, off_role: MonsterRole.Type) -> int:
	var main_col := _preferred_col(main_role)
	if main_col == -1:
		return -1
	if off_role == MonsterRole.Type.NONE:
		return main_col
	var off_col := _preferred_col(off_role)
	if off_col == -1:
		return main_col
	return int(round((main_col * 2.0 + off_col) / 3.0))


# Picks randomly from valid positions biased toward preferred_col.
# -1 means no preference — pick uniformly at random.
# Accepts the closest available column plus one further — guideline, not strict.
static func _pick_biased(valid: Array[Vector2i], preferred_col: int, rng: RandomNumberGenerator) -> Vector2i:
	if preferred_col == -1:
		return valid[rng.randi() % valid.size()]
	var sorted := valid.duplicate()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return abs(a.x - preferred_col) < abs(b.x - preferred_col)
	)
	var min_dist: int = abs((sorted[0] as Vector2i).x - preferred_col)
	var candidates: Array[Vector2i] = sorted.filter(func(p: Vector2i) -> bool:
		return abs(p.x - preferred_col) <= min_dist + 1
	)
	return candidates[rng.randi() % candidates.size()]


static func _can_place(pos: Vector2i, size: Vector2i, occupied: Dictionary) -> bool:
	for dx in range(size.x):
		for dy in range(size.y):
			if occupied.has(pos + Vector2i(dx, dy)):
				return false
	return true
