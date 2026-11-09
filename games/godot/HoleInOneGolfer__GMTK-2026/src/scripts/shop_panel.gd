extends Control

@export var speed_button: Button
@export var size_button: Button
@export var time_button: Button

func _ready() -> void:
	update_button_labels()
	
	if speed_button: speed_button.pressed.connect(_on_speed_pressed)
	if size_button: size_button.pressed.connect(_on_size_pressed)
	if time_button: time_button.pressed.connect(_on_time_pressed)

func update_button_labels() -> void:
	if speed_button:
		speed_button.text = "Speed Up (Lvl %d)\nCost: %d" % [GameManager.speed_level, GameManager.speed_cost]
	if size_button:
		size_button.text = "Size Up (Lvl %d)\nCost: %d" % [GameManager.size_level, GameManager.size_cost]
	if time_button:
		time_button.text = "Time Up (Lvl %d)\nCost: %d" % [GameManager.time_level, GameManager.time_cost]

func _on_speed_pressed() -> void:
	if GameManager.can_afford(GameManager.speed_cost):
		GameManager.spend_score(GameManager.speed_cost)
		GameManager.speed_level += 1
		GameManager.speed_cost = int(GameManager.speed_cost * 2.0)
		update_button_labels()

func _on_size_pressed() -> void:
	if GameManager.can_afford(GameManager.size_cost):
		GameManager.spend_score(GameManager.size_cost)
		GameManager.size_level += 1
		GameManager.size_cost = int(GameManager.size_cost * 2.0)
		update_button_labels()

func _on_time_pressed() -> void:
	if GameManager.can_afford(GameManager.time_cost):
		GameManager.spend_score(GameManager.time_cost)
		GameManager.time_level += 1
		GameManager.time_cost = int(GameManager.time_cost * 2.0)
		update_button_labels()
