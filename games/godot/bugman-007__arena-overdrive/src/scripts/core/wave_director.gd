class_name WaveDirector
extends RefCounted
## Builds wave compositions from data-driven enemy definitions using a point budget.

const BOSS_EVERY := 5


static func is_boss_wave(wave: int) -> bool:
	return wave > 0 and wave % BOSS_EVERY == 0


static func budget(wave: int) -> int:
	return 6 + wave * 3


static func health_scale(wave: int) -> float:
	return 1.0 + 0.14 * (wave - 1)


static func spawn_interval(wave: int) -> float:
	return maxf(0.18, 0.75 - wave * 0.045)


static func eligible(wave: int, db: Dictionary) -> Array[EnemyData]:
	var out: Array[EnemyData] = []
	for id: StringName in db:
		var e: EnemyData = db[id]
		if e.behavior != EnemyData.Behavior.BOSS and e.min_wave <= wave:
			out.append(e)
	out.sort_custom(func(a: EnemyData, b: EnemyData) -> bool: return String(a.id) < String(b.id))
	return out


static func compose(wave: int, rng: RandomNumberGenerator, db: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	var remaining := budget(wave)
	if is_boss_wave(wave):
		out.append(&"boss")
		remaining = int(remaining / 3.0)
	var pool := eligible(wave, db)
	if pool.is_empty():
		return out
	while remaining > 0:
		var total := 0.0
		for e in pool:
			total += e.spawn_weight
		var roll := rng.randf() * total
		var pick: EnemyData = pool[0]
		for e in pool:
			roll -= e.spawn_weight
			if roll <= 0.0:
				pick = e
				break
		out.append(pick.id)
		remaining -= maxi(1, pick.cost)
	return out
