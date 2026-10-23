@tool
class_name Mutagen extends Node2D


@export_enum("red", "green", "blue") var mutation_color = "red":
	set(mc):
		mutation_color = mc
		_update_color.call_deferred()
@export var resonator_lock:ResonatorContainer


@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var collection_area: Area2D = $CollectionArea



func _ready() -> void:
	if resonator_lock:
		set_process(false)
		visible = false
		resonator_lock.unlocked.connect(func():
			set_process(true)
			visible = true)
	else:
		set_process(true)
	
	_update_color()
	
	collection_area.body_entered.connect(_collect)


func _collect(node:Node2D) -> void:
	if not is_processing():
		return
	if not node is Player:
		return
	var player = node as Player
	var combined = MutagenColor.resolve_multiple(mutation_color, player.mutagen_color.key)
	player.mutate(combined)


func _update_color() -> void:
	if sprite_2d:
		sprite_2d.modulate = MutagenColor.resolve(mutation_color).color
