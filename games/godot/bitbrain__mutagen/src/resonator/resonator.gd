@tool
class_name Resonator extends Node2D


signal on_activated
signal on_reset


@export_enum("red", "green", "blue", "yellow", "magenta", "cyan") var mutation_color = "red":
	set(mc):
		mutation_color = mc
		_update_color.call_deferred()


@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var player_collision: Area2D = $PlayerCollision
@onready var player = get_tree().get_first_node_in_group("player")


var mutagen_color:MutagenColor = MutagenColor.DEFAULT
var activated = false:
	set(ac):
		var was_activated = activated
		activated = ac
		if activated and not was_activated:
			sprite_2d.play("activating")
			on_activated.emit()
		if not activated and was_activated:
			sprite_2d.play("deactivating")
var other_resonators:Array[Resonator] = []
var resonator_activation_count:int = 0


func _ready() -> void:
	randomize()
	sprite_2d.frame = randi_range(0, sprite_2d.sprite_frames.get_frame_count("inactive"))
	_update_color()
	sprite_2d.animation_finished.connect(func():
		if sprite_2d.animation == "activating":
			sprite_2d.play("active")
		if sprite_2d.animation == "deactivating":
			sprite_2d.play("inactive")
		)
	player_collision.body_entered.connect(_on_player_entered)
	
	visible = false
	player.mutated.connect(_on_player_mutated)
	

func _on_player_mutated(color:MutagenColor) -> void:
	visible = color.is_same(mutagen_color)


func _on_player_entered(body:Node2D) -> void:
	if not body is Player:
		return
	var player = body as Player
	if not player.mutagen_color.is_same(self.mutagen_color):
		return
	if not activated:
		activate()
	else:
		on_reset.emit()


func activate() -> void:
	activated = true
	

func deactivate() -> void:
	activated = false
	

func _update_color() -> void:
	if sprite_2d:
		sprite_2d.modulate = MutagenColor.resolve(mutation_color).color
	mutagen_color = MutagenColor.resolve(mutation_color)
