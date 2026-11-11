extends RefCounted
## Versioned Park-Miller stream. Integer arithmetic is reproducible across platforms.
const MODULUS := 2147483647
var state: int

func _init(seed_value: int) -> void:
	state = posmod(seed_value, MODULUS - 1) + 1

func next_int() -> int:
	state = (state * 48271) % MODULUS
	return state

func unit() -> float:
	return float(next_int() - 1) / float(MODULUS - 1)

func index(count: int) -> int:
	assert(count > 0 and count < MODULUS)
	var limit: int = (MODULUS - 1) - ((MODULUS - 1) % count)
	var draw := next_int() - 1
	while draw >= limit:
		draw = next_int() - 1
	return draw % count

func permutation(count: int) -> Array:
	var values := range(count)
	for i in range(count - 1, 0, -1):
		var j := index(i + 1)
		var temporary: int = values[i]
		values[i] = values[j]
		values[j] = temporary
	return values
