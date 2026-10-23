extends CanvasLayer

func increment_score(player_id: int, score: int) -> void:
	if player_id == 0:
		$PlayerAScore.text = "Score: " + str(score)
	else:
		$PlayerBScore.text = "Score: " + str(score)
