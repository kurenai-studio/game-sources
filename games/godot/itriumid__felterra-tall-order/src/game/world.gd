class_name World
extends RefCounted
## Where the simulation's meters meet the screen's pixels.

## A cat about 45 centimeters tall is 18 pixels; a human, 70.
const PIXELS_PER_METER := 40.0


static func to_screen(position: Vector2, height := 0.0) -> Vector2:
	return (position * PIXELS_PER_METER - Vector2(0.0, height * PIXELS_PER_METER)).round()
