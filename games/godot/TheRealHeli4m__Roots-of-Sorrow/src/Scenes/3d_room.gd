extends Node2D

@onready var animPlayer = $AnimationPlayer
@onready var gameboy = $Gameboy
@onready var currentRoom = "door"
@onready var camera = $Camera2D
@onready var root = $".."

@onready var window = $Window
@onready var door = $Door
@onready var cabinet = $Cabinet
@onready var isTurning = false
@onready var turnAnim = $CanvasLayer/AnimationPlayer
@onready var turnColRect = $CanvasLayer/ColorRect

@onready var switchToCabinetAnim = $CanvasLayer2/SwitchToCabinet
@onready var cabinetSprite = $Door/Cabinet/AnimatedSprite2D
@onready var cabinetHighlight = $Door/CabinetHighlight

@onready var progressBar = $MomMinigame/ProgressBar

@onready var hover = $MomMinigame/Hover

@onready var eye1 = preload("res://Assets/eye1.png")
@onready var eye2 = preload("res://Assets/eye2.png")
@onready var eye3 = preload("res://Assets/eye3.png")
@onready var eye4 = preload("res://Assets/eye4.png")
@onready var eyeNode = preload("res://eye.tscn")

var eyeArray: Array
var eyeSpawnRate = 0.001
@onready var eyeSpawnRoot = $Window

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	eyeArray = [eye1, eye2, eye3, eye4]
	root.startMomMinigame.connect(startMomMinigame)
	turnColRect.modulate.a = 0
	currentRoom = "door"
	gameboy.hide()
	
func createEye() -> void:
	randomize()
	if randf() < eyeSpawnRate:
		Global.eyeAmount += 1
		if randf() > 0.5:
			eyeSpawnRoot = $Window
		else:
			eyeSpawnRoot = $Door
		var eye = eyeNode.instantiate()
		eye.texture_normal = eyeArray.pick_random()
		eyeSpawnRoot.add_child(eye)
		eye.scale = Vector2(0.125, 0.125)
		eye.position = Vector2(randi_range(-75, 75), randi_range(-40, 40))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(Global.eyeAmount)
	createEye()
	if progressBar.value == 100:
		Global.inMomMinigame = false
		progressBar.hide()
		hover.hide()
		animPlayer.play_backwards("open_gameboy")
		await animPlayer.animation_finished
		gameboy.hide()
			
	if progressBar.value == 0 and Global.inMomMinigame:
		Global.inMomMinigame = false
		root.jumpscare()
			
	if Global.inMomMinigame: 
		window.show()
		door.hide()
		cabinet.hide()
		gameboy.show()
		gameboy.position = Vector2(40, 100)
		gameboy.scale = Vector2(10, 10)
		camera.apply_shake()
		return;
	if Global.currentScene == "room":
		if currentRoom == "cabinet":
			if Input.is_action_just_pressed("escape") or Input.is_action_just_pressed("scroll_banner_up"):
				switchToCabinetAnim.play("change_room")
				cabinetSprite.frame = 0
				cabinetHighlight.show()
				await get_tree().create_timer(0.25).timeout
				currentRoom = "door"
				
		else:
			if Input.is_action_just_pressed("move_left"):
				turnAnim.play("change_room")
				turn(true)
			if Input.is_action_just_pressed("move_right"):
				turnAnim.play("change_room")
				turn(false)
		
	if currentRoom == "door":
		window.hide()
		door.show()
		cabinet.hide()
	elif currentRoom == "window":
		window.show()
		door.hide()
		cabinet.hide()
	else:
		cabinet.show()
		window.hide()
		door.hide()

func openGameboy() -> bool:
	gameboy.show()
	animPlayer.play("open_gameboy")
	
	await animPlayer.animation_finished
	return true
	
func closeGameboy() -> bool:
	gameboy.show()
	animPlayer.play_backwards("open_gameboy")
	
	await animPlayer.animation_finished
	gameboy.hide()
	return true
	
func turn(isLeft: bool) -> void:
	isTurning = true
	if isLeft:
		var tweenstart = create_tween()
		tweenstart.tween_property(camera, "position", Vector2(-1000, 0), 0.2)
		
		await tweenstart.finished
		
		currentRoom = "door" if currentRoom == "window" else "window"
		camera.position = Vector2(1000, 0)
		var tweenend = create_tween()
		tweenend.tween_property(camera, "position", camera.calculatedPos, 0.2)
		
		await tweenend.finished
	else:
		var tweenstart = create_tween()
		tweenstart.tween_property(camera, "position", Vector2(1000, 0), 0.2)
		
		await tweenstart.finished
		
		currentRoom = "door" if currentRoom == "window" else "window"
		camera.position = Vector2(-1000, 0)
		var tweenend = create_tween()
		tweenend.tween_property(camera, "position", camera.calculatedPos, 0.2)
		
		await tweenend.finished
	isTurning = false
	
func startMomMinigame() -> void:
	progressBar.value = 40
	
