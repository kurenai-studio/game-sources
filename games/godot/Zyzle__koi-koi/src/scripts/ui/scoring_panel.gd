class_name ScoringPanel
extends NinePatchRect

const YAKU_SCENE_PATH = "res://scenes/yaku.tscn"

@onready var score_label: Label = %ScoreLabel
@onready var yaku_list_container: VBoxContainer = %YakuList
@onready var koi_koi_button: TextureButton = %KoiKoiButton
@onready var end_button: TextureButton = %EndButton

signal koi_koi_pressed
signal end_pressed

var game_state: GameState


func _ready():
	score_label.text = "%d pts" % game_state.player_score.total_score

	for yaku in game_state.player_score.yaku_achieved:
		var yaku_scene = preload(YAKU_SCENE_PATH)
		var yaku_visual: Yaku = yaku_scene.instantiate()
		yaku_visual.setup(Scoring.YAKU_NAMES_MAP[yaku][0], Scoring.YAKU_NAMES_MAP[yaku][1], 0, game_state.player_score.yaku_cards[yaku])
		yaku_list_container.add_child(yaku_visual)

	if game_state.player_hand.size() == 0:
		koi_koi_button.disabled = true


func _on_koi_koi_button_pressed():
	koi_koi_pressed.emit()


func _on_end_button_pressed():
	end_pressed.emit()


func set_game_state(state: GameState) -> void:
	game_state = state
