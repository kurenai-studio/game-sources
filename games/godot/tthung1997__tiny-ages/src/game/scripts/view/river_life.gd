class_name RiverLife
extends RefCounted
## When the creatures of the river and the far bank are about. Pure and headless: fish rise and
## birds sit on the reeds all day (the view just animates them), and a deer comes down to drink at
## dawn and dusk. Only the view uses this; it changes nothing in the simulation.

## The hours (24h clock) the deer is at the water: [from, to).
const DEER_HOURS: Array[Vector2] = [Vector2(5.0, 8.5), Vector2(17.0, 20.5)]


static func deer_visible(hour: float) -> bool:
	for window: Vector2 in DEER_HOURS:
		if hour >= window.x and hour < window.y:
			return true
	return false
