class_name Body
extends RefCounted
## Anything that moves: a position on the ground and a height above it, in meters, so thrown
## things arc, land, bounce and slide to a stop.

const GRAVITY := 9.81
## A landing slower than this, in meters a second, doesn't bounce: the body settles.
const SETTLE_SPEED := 0.6

var position := Vector2.ZERO
var height := 0.0
var velocity := Vector2.ZERO
var vertical_speed := 0.0
var radius := 0.1
## What it is or was ("rat", "dog"), so the fallen are drawn as what they were.
var kind := ""
## How tall it stands, for what passes over it.
var tall := 0.1
## The share of its falling speed a bounce keeps.
var restitution := 0.35
## How fast sliding along the ground slows it, in meters a second each second.
var friction := 6.0


func airborne() -> bool:
	return height > 0.0 or vertical_speed > 0.0


## Lying still on the ground: nothing to simulate until something moves it.
func resting() -> bool:
	return not airborne() and velocity == Vector2.ZERO


## Throws it: a push along the ground and up.
func push(along_ground: Vector2, up: float) -> void:
	velocity += along_ground
	vertical_speed += up


func step(delta: float) -> void:
	if airborne():
		vertical_speed -= GRAVITY * delta
		height += vertical_speed * delta
		if height <= 0.0:
			height = 0.0
			if -vertical_speed > SETTLE_SPEED:
				vertical_speed = -vertical_speed * restitution
				# Striking the ground scrubs off some of the way along it too.
				velocity *= 0.7
			else:
				vertical_speed = 0.0
	position += velocity * delta


## Slows a body sliding on the ground. Walkers don't slide: they set their own pace.
func slide(delta: float) -> void:
	if airborne():
		return
	var speed := velocity.length()
	var drop := friction * delta
	velocity = Vector2.ZERO if speed <= drop else velocity * (1.0 - drop / speed)
