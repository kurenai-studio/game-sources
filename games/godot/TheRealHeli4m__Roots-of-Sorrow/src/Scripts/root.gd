extends Node

@onready var canvas = $Flash
@onready var colorRect = $Flash/ColorRect
@onready var roomScene = $"3d_room"
@onready var gameboyScene = $gameboy
@onready var vignette = $Vignette/ColorRect
@onready var panicIntensityShader = $CanvasLayer/PanicIntensityShader

@onready var gameboycam: Camera2D = get_node("gameboy/Camera2D")
@onready var roomcam: Camera2D = get_node("3d_room/Camera2D")

@onready var momTimer = $MomTimer
@onready var eyeJumpscare = $Mom/CanvasLayer/EyeJumpscare

@onready var shadMaterial: ShaderMaterial
@onready var panicMaterial: ShaderMaterial
@onready var audio = $AudioStreamPlayer2D

signal open
signal close
signal startMomMinigame

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	eyeJumpscare.hide()
	panicMaterial = panicIntensityShader.material as ShaderMaterial
	panicMaterial.set_shader_parameter("intensity", 0.1)
	shadMaterial = vignette.material as ShaderMaterial
	shadMaterial.set_shader_parameter("alpha", 0.6)
	self.open.connect(roomScene.openGameboy)
	self.close.connect(roomScene.closeGameboy)
	Global.currentRoom = Global.rooms.hallway
	gameboyScene.hide()
	canvas.show()
	colorRect.modulate.a = 0
	roomcam.make_current()
	
func _input(event: InputEvent) -> void:
	if roomScene.currentRoom == "cabinet": return;
	if Global.inMomMinigame: return;
	
	if Global.currentScene == "room" && event.is_action_pressed("switch_scenes"):
		self.open.emit()
		await roomScene.openGameboy()
		
		Global.currentScene = "gameboy"
		shadMaterial.set_shader_parameter("alpha", 0.8)
		gameboyScene.show()
		roomScene.hide()
		gameboycam.make_current()
		flash()
	elif Global.currentScene == "gameboy" && event.is_action_pressed("switch_scenes"):
		Global.currentScene = "room"
		shadMaterial.set_shader_parameter("alpha", 0.6)
		gameboyScene.hide()
		roomScene.show()
		roomcam.make_current() 
		flash()
		self.close.emit()
		
func fetchCorrectRoom() -> void:
	pass

func flash():
	colorRect.modulate.a = 1.0
	colorRect.move_to_front()
	var tween = create_tween()
	tween.tween_property(colorRect, "modulate:a", 0.0, 1.5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	print(Global.sanity)
	if Global.sanity > 90.0:
		Global.sanity = 90.0
	changePanic()
	if Global.currentScene == "room":
		Input.set_custom_mouse_cursor(null)

func jumpscare() -> void:
	audio.play()
	eyeJumpscare.show()
	eyeJumpscare.apply_shake()
	
func _on_mom_timer_timeout() -> void:
	jumpscare()
	Global.inMomMinigame = true
	startMomMinigame.emit()
	
	await get_tree().create_timer(1.0).timeout
	roomScene.currentRoom = "window"
	eyeJumpscare.hide()
	audio.stop()
	Global.sanity -= 30
	
func changePanic() -> void:
	var panicIntensity: float = (100.0 - Global.sanity) / 100.0
	panicMaterial.set_shader_parameter("intensity", panicIntensity)


func _on_sanity_timer_timeout() -> void:
	Global.sanity -= Global.eyeAmount
	if Global.currentScene == "gameboy":
		Global.sanity += 2
