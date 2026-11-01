extends Node

var VERSION: int
@onready var rng : RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	VERSION = rng.randi_range(1, 4)
