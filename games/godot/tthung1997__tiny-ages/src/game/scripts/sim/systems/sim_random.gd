class_name SimRandom
extends RefCounted
## Deterministic helpers on top of a seeded RandomNumberGenerator. All simulation randomness
## goes through the Simulation's rng so a seed plus a tick count reproduces a world exactly.


## Picks an index with probability proportional to its weight. Returns -1 if nothing has weight.
static func pick_weighted(rng: RandomNumberGenerator, weights: Array[float]) -> int:
	var total: float = 0.0
	for weight: float in weights:
		total += maxf(weight, 0.0)
	if total <= 0.0:
		return -1
	var roll: float = rng.randf() * total
	for index: int in weights.size():
		roll -= maxf(weights[index], 0.0)
		if roll < 0.0:
			return index
	return weights.size() - 1


## A shuffled list of 0..count-1 (Fisher-Yates).
static func shuffled_indices(rng: RandomNumberGenerator, count: int) -> Array[int]:
	var order: Array[int] = []
	for index: int in count:
		order.append(index)
	for index: int in range(count - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var held: int = order[index]
		order[index] = order[other]
		order[other] = held
	return order
