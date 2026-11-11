class_name WinLosePanel
extends NinePatchRect

const WIN_CALLOUT_TEXTURE_PATH = "res://assets/callout_blue.png"
const LOSE_CALLOUT_TEXTURE_PATH = "res://assets/callout_red.png"
const DRAW_CALLOUT_TEXTURE_PATH = "res://assets/callout_tan.png"
const YAKU_SCENE_PATH = "res://scenes/yaku.tscn"

@onready var callout: NinePatchRect = %Callout
@onready var wld_label: Label = %WLDLabel
@onready var opponent_score_label: Label = %OpponentScoreLabel
@onready var player_score_label: Label = %PlayerScoreLabel
@onready var yaku_list_container: VBoxContainer = %YakuList

signal next_pressed

var game_state: GameState

func _ready():
	opponent_score_label.text = "%d pts" % game_state.opponent_running_score
	player_score_label.text = "%d pts" % game_state.player_running_score

	if game_state.round_wins[game_state.round_number - 1] == 1:
		callout.texture = load(WIN_CALLOUT_TEXTURE_PATH)
		wld_label.text = "You Win!"
		populate_yaku_list(game_state.player_score)
	elif game_state.round_wins[game_state.round_number - 1] == 2:
		callout.texture = load(LOSE_CALLOUT_TEXTURE_PATH)
		wld_label.text = "You Lose!"
		populate_yaku_list(game_state.opponent_score)
	else:
		callout.texture = load(DRAW_CALLOUT_TEXTURE_PATH)
		wld_label.text = "Draw!"


func _on_texture_button_pressed():
	next_pressed.emit()


func populate_yaku_list(score_result: Scoring.ScoreResult) -> void:
	for yaku in score_result.yaku_achieved:
		var yaku_scene = preload(YAKU_SCENE_PATH)
		var yaku_visual: Yaku = yaku_scene.instantiate()
		yaku_visual.setup(Scoring.YAKU_NAMES_MAP[yaku][0], Scoring.YAKU_NAMES_MAP[yaku][1], 0, score_result.yaku_cards[yaku])
		yaku_list_container.add_child(yaku_visual)


func set_game_state(state: GameState) -> void:
	game_state = state