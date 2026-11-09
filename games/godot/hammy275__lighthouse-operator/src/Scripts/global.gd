extends Node

enum Powerup {FASTER_MOVEMENT, BETTER_OIL, STUDY_SHIP_VIEW}
enum Direction {NORTH, EAST, SOUTH, WEST}

## Whether the player saw the tutorial screen.
var saw_tutorial: bool = false
## Current level number.
var level_num: int = 1
## Current hour in the day.
var current_hour: int = 1
## Number of ships that had safe passage.
var score: int = 0
## Highest score scored.
var high_score: int = 0
## Number of ships that crashed.
var crashed: int = 0
## Active powerups. Stored as a dictionary, since Godot doesn't have sets.
var powerups: Dictionary[Powerup, bool] = {}

## Lighthouse node
var lighthouse: Lighthouse

func reset() -> void:
	self.level_num = 1
	self.current_hour = 1
	self.score = 0
	self.crashed = 0
	self.powerups = {}
