extends Control

const TIME_MAP = [
	["30s", 30],
	["1 min", 60],
	["2 min", 120],
	["3 min", 180],
	["4 min", 240]
]

var team_idx: int = 0
var max_teams: int = 32

@onready var team_label = %TeamLabel
@onready var head = %Head
@onready var body = %Body
@onready var foot = %Foot

func _ready() -> void:
	team_idx = Globals.home_team_index
	Globals.period_length = TIME_MAP[2][1]

	$VBoxContainer/Buttons/Start.grab_focus()
	update_ui()

func update_ui() -> void:
	var team = StatBook.TEAMS[team_idx]

	team_label.text = team["name"]
	head.color = team["head_color"]
	body.color = team["body_color"]
	foot.color = team["foot_color"]

func _on_prev_pressed() -> void:
	team_idx -= 1
	if team_idx < 0:
		team_idx = StatBook.TEAMS.size() - 2 # skip pinkertons
	update_ui()

func _on_next_pressed() -> void:
	team_idx += 1
	if team_idx >= StatBook.TEAMS.size() - 1: # skip pinkertons
		team_idx = 0
	update_ui()

func _on_start_pressed() -> void:
	Globals.home_team_index = team_idx
	Globals.save_settings()
	Season.new_season(team_idx)
	Season.season_on = true
	get_tree().change_scene_to_file("res://menu/season_hub.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")

func _on_time_value_changed(value: float) -> void:
	var setting = TIME_MAP[int(value)]
	%TimeLabel.text = "Period Length: " + setting[0]
	Globals.period_length = setting[1]
