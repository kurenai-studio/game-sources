class_name TideLook
extends RefCounted
## What the tide looks like on the east beach. Pure and headless: the simulation's `tide_at` gives
## a level (0 lowest, 1 highest) and this says how far out the sea is: which of the flats' steps the
## view shows. Nothing here is saved; the step just follows the level.

## At or above the first level the sea covers the flats. Each level the water falls below bares one
## more step: step 1 under 0.55, step 2 under 0.35 and step 3 (fully out) under 0.15.
const STEP_LEVELS: Array[float] = [0.55, 0.35, 0.15]


## 0 when the sea covers the flats, up to STEP_LEVELS.size() when it is fully out.
static func flats_step(level: float) -> int:
	var step: int = 0
	for threshold: float in STEP_LEVELS:
		if level < threshold:
			step += 1
	return step
