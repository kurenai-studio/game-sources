extends Node2D
class_name Level

signal won

@export var starting_anim_size : int
@export var disable_shrink : bool = false
@export var lanterns_required : int = 1
@export var player : PackedScene
@onready var spawn_point = $SpawnPoint

var player_instance : CandleMan
var lanterns_lit = 0
@export var lanterns : Array[Lantern]

var has_won = false

# Called when the node enters the scene tree for the first time.
func _ready():
	player_instance = player.instantiate()
	player_instance.position = spawn_point.position
	add_child(player_instance)
	player_instance.disable_shrink = disable_shrink
	player_instance.set_anim_size(starting_anim_size)
	player_instance.died.connect(lost)
	for l in lanterns:
		l.fire_lit.connect(inc_lantern)


func inc_lantern():
	print("lit")
	lanterns_lit += 1
	if lanterns_lit == lanterns_required:
		win()


func win():
	print("won")
	has_won = true
	won.emit()
	# display victory text or whatever
	# load next level / call signal to load next level

func lost():
	if not has_won:
		lanterns_lit = 0
		await get_tree().create_timer(1.5).timeout
		player_instance.respawn(starting_anim_size)
		player_instance.position = spawn_point.position
		for l in lanterns:
			l.lit = false
