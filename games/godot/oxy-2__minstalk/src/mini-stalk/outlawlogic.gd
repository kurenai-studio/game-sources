extends CharacterBody2D

@export var outlawspeed := 100.0
@export var health := 3
@export var keepdistance := 160.0
@export var strafespeed := 55.0

# Fill these in the Inspector by dragging in your audio files
var engage_voicelines: Array[AudioStream] = [
	preload("res://assets/sounds/input/outlaw-voicelines/alaaahalidahaa.mp3"),
	preload("res://assets/sounds/input/outlaw-voicelines/alaahavidaha.mp3"),
	preload("res://assets/sounds/input/outlaw-voicelines/ambletslambabe.mp3"),
	preload("res://assets/sounds/input/outlaw-voicelines/ambletslambabee.mp3"),
	preload("res://assets/sounds/input/outlaw-voicelines/annnnuuuchikibriki.mp3"),
	preload("res://assets/sounds/input/outlaw-voicelines/anuuchikibriki.mp3"),
]

var death_voicelines: Array[AudioStream] = [
	preload("res://assets/sounds/input/outlaw-voicelines/aiaaiaa.mp3"),
	preload("res://assets/sounds/input/outlaw-voicelines/ouiouiou.mp3"),
	preload("res://assets/sounds/input/outlaw-voicelines/papacanii.mp3"),
	preload("res://assets/sounds/input/outlaw-voicelines/papapapacanii.mp3"),
]

@onready var player = get_tree().get_first_node_in_group("player")
@onready var anim = $outlawsprite
@onready var notifier = $VisibleOnScreenNotifier2D

var activated := false
var _strafedir := 1.0
var _strafetimer := 0.0
var blood = load("res://bloodFIXED.tscn")

func _ready() -> void:
	add_to_group("enemy")
	notifier.screen_entered.connect(_on_screen_entered)

func _on_screen_entered() -> void:
	if not activated:
		activated = true
		print(name, " woke up")
		_play_random_voiceline(engage_voicelines)

func is_gun_ready() -> bool:
	return activated

# Spawns a temporary player so the sound keeps playing even if this enemy is freed
func _play_random_voiceline(lines: Array[AudioStream]) -> void:
	if lines.is_empty():
		return
	var sfx := AudioStreamPlayer2D.new()
	sfx.stream = lines.pick_random()
	sfx.global_position = global_position
	sfx.finished.connect(sfx.queue_free)
	get_tree().current_scene.add_child(sfx)
	sfx.play()

func _physics_process(delta: float) -> void:
	if not activated or not is_instance_valid(player):
		velocity = Vector2.ZERO
		anim.stop()
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var dir = to_player.normalized() if dist > 0.001 else Vector2.RIGHT

	_strafetimer -= delta
	if _strafetimer <= 0.0:
		_strafetimer = randf_range(1.6, 3.2)
		_strafedir = -_strafedir

	var motion := Vector2.ZERO
	if dist > keepdistance + 28.0:
		motion = dir
	elif dist < keepdistance - 28.0:
		motion = -dir
	motion += dir.orthogonal() * _strafedir * (strafespeed / maxf(outlawspeed, 1.0))

	if motion.length() > 0.0:
		velocity = motion.normalized() * outlawspeed
	else:
		velocity = Vector2.ZERO

	anim.play("walk")
	anim.flip_h = dir.x < 0
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	print(name, " hp: ", health)
	var blood_instance = blood.instantiate()
	get_tree().current_scene.add_child(blood_instance)
	blood_instance.global_position = global_position
	if health <= 0:
		print(name, " died")
		_play_random_voiceline(death_voicelines)
		queue_free()
