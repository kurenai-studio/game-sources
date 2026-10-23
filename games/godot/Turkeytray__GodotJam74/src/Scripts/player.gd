extends CharacterBody2D

var speed := 300
var collectedPieces := 0
var running := false
@onready var lift = get_parent().get_node("Lift")
var switch_scene = 0

signal returnPieces

func _ready() -> void:
	$Heartbeat.play()

func _process(_delta: float) -> void:
	if switch_scene == 200:
		get_tree().change_scene_to_file("res://Scenes/Win.tscn")
		return
	
	if Input.is_key_pressed(KEY_SHIFT) and not running:
		@warning_ignore("narrowing_conversion")
		speed *= 1.75
		running = true
	if not Input.is_key_pressed(KEY_SHIFT) and running:
		@warning_ignore("narrowing_conversion")
		speed /= 1.75
		running = false
	
	if Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"):
		if not $Walk.playing:
			_walk_sounds()
			$Walk.play()
		$PlayerSprite.play()
	else:
		$Walk.stop()
		$PlayerSprite.stop()
	
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = speed * direction
	
	move_and_slide()

func _on_lift_place():
	if collectedPieces < 0:
		return
	returnPieces.emit(collectedPieces)
	collectedPieces = 0

func _on_enemy_touched(body: Node2D) -> void:
	if body is Enemy:
		get_tree().change_scene_to_file("res://Scenes/Death.tscn")

func _walk_sounds() -> void:
	match randi_range(0, 4):
		0: $Walk.stream = load("res://Resources/Audio/Walk Sounds/walk.ogg")
		1: $Walk.stream = load("res://Resources/Audio/Walk Sounds/walk2.ogg")
		2: $Walk.stream = load("res://Resources/Audio/Walk Sounds/walk3.ogg")
		3: $Walk.stream = load("res://Resources/Audio/Walk Sounds/walk4.ogg")

func _on_piece_collected() -> void:
	collectedPieces += 1

func _on_win() -> void:
	for i in range(255):
		if $Camera/CanvasLayer/FadeToBlack/Timer.is_stopped():
			await $Camera/CanvasLayer/FadeToBlack/Timer.is_stopped()
		$Camera/CanvasLayer/FadeToBlack/Timer.start(0.03)

func _on_timer_timeout() -> void:
	$Camera/CanvasLayer/FadeToBlack.color.a += 0.01
	switch_scene += 1
