extends Node

class_name Utils

static func pick_weighted_random(a: Array) -> int:
	var weights: Array[float] = []
	for i in a:
		weights.append(1.0 / (i + 1))
	var total_weight = weights.reduce(func(acc, x): return acc + x, 0)
	var roll = randf_range(0, total_weight)

	var cumulative = 0.0

	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return i

	return weights.size() - 1   # fallback for float rounding at the tail
