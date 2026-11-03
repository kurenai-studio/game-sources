class_name Combat
extends RefCounted
## Pure damage helpers.


static func roll_damage(base: float, crit_chance: float, crit_mult: float, rng: RandomNumberGenerator) -> Dictionary:
	var crit := rng.randf() < crit_chance
	var amount := int(round(base * (crit_mult if crit else 1.0)))
	return {"amount": maxi(1, amount), "crit": crit}


## Armor gives diminishing returns: 10 armor = 50% reduction. Never below 1.
static func mitigate(amount: int, armor: float) -> int:
	if amount <= 0:
		return 0
	return maxi(1, int(round(amount * 100.0 / (100.0 + maxf(armor, 0.0) * 10.0))))


## Fan of `count` unit vectors around `aim`.
static func spread_directions(aim: Vector2, count: int, spread_deg: float = 10.0) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var base := aim.normalized() if aim != Vector2.ZERO else Vector2.RIGHT
	if count <= 1:
		out.append(base)
		return out
	var step := deg_to_rad(spread_deg)
	var start := -step * (count - 1) / 2.0
	for i in count:
		out.append(base.rotated(start + step * i))
	return out


static func ring_directions(count: int, offset: float = 0.0) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in count:
		out.append(Vector2.RIGHT.rotated(offset + TAU * i / count))
	return out
