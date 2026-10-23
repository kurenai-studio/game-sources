extends Node2D

@onready var weapon_image: Sprite2D = $WeaponImage
@onready var weapon_label: Label = $WeaponLabel
@onready var ui: CanvasLayer = $UI
@onready var wind: HScrollBar = %Wind
@onready var shake_timer: Timer = $ShakeTimer
@onready var camera_2d: Camera2D = $Camera2D

var moving: bool = false
var can_move: bool = false
var shake_amount: float = 0.0
var weapon_amount: int
var weapon: int
var ecs_mode: int = 0


func _ready() -> void:
	hide()
	ui.hide()
	
	for x in range(4):
		for y in range(4):
			var new_sprite = Sprite2D.new()
			var sprite_weapon: int = y * 4 + x
			
			if sprite_weapon >= len(Globals.WEAPONS):
				continue
			
			if ResourceLoader.exists("res://assets/images/"+Globals.WEAPONS[sprite_weapon]+".png"):
				new_sprite.texture = load("res://assets/images/"+Globals.WEAPONS[sprite_weapon]+".png")
			else:
				new_sprite.texture = load("res://assets/images/rocket.png")
			
			new_sprite.global_position = Vector2(512 + x * 18, 256 + y * 18)
			ui.add_child(new_sprite)


func _process(_delta: float) -> void:
	camera_2d.limit_bottom = Globals.water_level + 64
	wind.value = Globals.wind
	
	if ResourceLoader.exists("res://assets/images/"+Globals.WEAPONS[weapon]+".png"):
		weapon_image.texture = load("res://assets/images/"+Globals.WEAPONS[weapon]+".png")
	else:
		weapon_image.texture = load("res://assets/images/rocket.png")
	
	if weapon_amount >= 0:
		weapon_label.text = Globals.WEAPONS_NAMES[weapon]+" "+str(weapon_amount)
	else:
		weapon_label.text = Globals.WEAPONS_NAMES[weapon]
	
	if !shake_timer.is_stopped():
		camera_2d.offset.x = randf_range(-shake_amount, shake_amount)
		camera_2d.offset.y = randf_range(-shake_amount, shake_amount)
	else:
		camera_2d.offset = Vector2.ZERO
	
	if Input.is_action_just_pressed("esc"):
		if ecs_mode == 1:
			get_tree().quit()
		else:
			ecs_mode = 1
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			hide()


func _input(event: InputEvent) -> void:
	if !Input.is_action_pressed("attack") and event is InputEventMouseMotion and can_move and visible:
		moving = true
		global_position += event.relative
	else:
		moving = false
		if Input.is_action_just_pressed("mouse_lock"):
			ecs_mode = 0
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			show()


@rpc("any_peer","reliable","call_local")
func shake(amount: float = 3.0, time: float = 0.15):
	shake_amount = amount
	shake_timer.start(time)
