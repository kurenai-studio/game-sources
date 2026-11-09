extends Control

var home_idx: int = 0
var away_idx: int = 1

@onready var home_label = %HomeLabel
@onready var home_head = %HomeHead
@onready var home_body = %HomeBody
@onready var home_foot = %HomeFoot

@onready var away_label = %AwayLabel
@onready var away_head = %AwayHead
@onready var away_body = %AwayBody
@onready var away_foot = %AwayFoot

@onready var home_difficulty = %HomeDifficulty
@onready var home_difficulty_label = %HomeDifficultyLabel
@onready var away_difficulty = %AwayDifficulty
@onready var away_difficulty_label = %AwayDifficultyLabel

const TIME_MAP = 	[
	["30s", 30],
	["1 min", 60],
	["2 min", 120],
	["3 min", 180],
	["4 min", 240]	
]

func _ready() -> void:
	home_idx = Globals.home_team_index
	away_idx = Globals.away_team_index
	Globals.period_length = TIME_MAP[2][1]
	%GoalieControl.button_pressed = Globals.allow_goalie_control
	home_difficulty.value = Globals.home_ai_difficulty
	away_difficulty.value = Globals.away_ai_difficulty
	home_difficulty.value_changed.connect(_on_home_difficulty_changed)
	away_difficulty.value_changed.connect(_on_away_difficulty_changed)
	_on_home_difficulty_changed(home_difficulty.value)
	_on_away_difficulty_changed(away_difficulty.value)

	$VBoxContainer/Buttons/Play.grab_focus()
	update_ui()

func _on_home_difficulty_changed(value: float) -> void:
	home_difficulty_label.text = "AI: Hard" if value == 1 else "AI: Extra Hard" if value > 1.5 else "AI: Easy"

func _on_away_difficulty_changed(value: float) -> void:
	away_difficulty_label.text = "AI: Hard" if value == 1 else "AI: Extra Hard" if value > 1.5 else "AI: Easy"

func update_ui() -> void:
	var home_team = StatBook.TEAMS[home_idx]
	var away_team = StatBook.TEAMS[away_idx]

	home_label.text = home_team["name"]
	home_head.color = home_team["head_color"]
	home_body.color = home_team["body_color"]
	home_foot.color = home_team["foot_color"]

	away_label.text = away_team["name"]
	away_head.color = away_team.get("away_head_color", away_team["head_color"])
	away_body.color = away_team.get("away_body_color", away_team["body_color"])
	away_foot.color = away_team.get("away_foot_color", away_team["foot_color"])

func _on_home_prev_pressed() -> void:
	home_idx -= 1
	if home_idx < 0:
		home_idx = StatBook.TEAMS.size() - 1
	update_ui()

func _on_home_next_pressed() -> void:
	home_idx += 1
	if home_idx >= StatBook.TEAMS.size():
		home_idx = 0
	update_ui()

func _on_away_prev_pressed() -> void:
	away_idx -= 1
	if away_idx < 0:
		away_idx = StatBook.TEAMS.size() - 1
	update_ui()

func _on_away_next_pressed() -> void:
	away_idx += 1
	if away_idx >= StatBook.TEAMS.size():
		away_idx = 0
	update_ui()

func _on_play_pressed() -> void:
	Globals.allow_goalie_control = %GoalieControl.button_pressed
	Globals.home_team_index = home_idx
	Globals.away_team_index = away_idx
	Globals.home_ai_difficulty = int(home_difficulty.value)
	Globals.away_ai_difficulty = int(away_difficulty.value)
	Globals.save_settings()
	Globals.update_team_textures()
	get_tree().change_scene_to_file("res://objects/environment/match_rink.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")

func _on_time_value_changed(value: float) -> void:
	var setting = TIME_MAP[int(value)]
	%TimeLabel.text = "Period Length: " + setting[0]
	Globals.period_length = setting[1]
