#----------------------------------------------------
# Gripple - Droofus Games
#----------------------------------------------------
# High Score Script
#----------------------------------------------------
# Release Under Mit License (c) 2026
#----------------------------------------------------

extends Node2D


func _ready() -> void:

	$LabelScore.text = " " + str(Game_Globals.high_score)
	$LabelMoves.text = " " + str(Game_Globals.fewest_moves)
	$LabelTime.text = " " + str(Game_Globals.best_time)

	match Game_Globals.high_score_type:
		1:
			$LabelScore.text += "   Easy"
		2:
			$LabelScore.text += "   Medium"
		3:
			$LabelScore.text += "   Hard"
