extends CanvasLayer

@export var hud_node: Control
@export var menu_node: Control
@export var timer_label: Label
@export var score_label: Label

func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.round_started.connect(_on_round_started)
	_set_ui_state(false)

func _process(_delta: float) -> void:
	_update_hud_display()

func _on_round_started() -> void:
	_set_ui_state(true)

func _on_game_over() -> void:
	_set_ui_state(false)

func _set_ui_state(in_game: bool) -> void:
	if hud_node: 
		hud_node.visible = true
		
	if menu_node: 
		menu_node.visible = not in_game

func _update_hud_display() -> void:
	if score_label:
		score_label.text = str(GameManager.score)
		
	if timer_label and GameManager.round_active:
		var seconds = floori(GameManager.time_left)
		var milliseconds = floori((GameManager.time_left - seconds) * 100)
		timer_label.text = "%02d:%02d" % [seconds, milliseconds]
