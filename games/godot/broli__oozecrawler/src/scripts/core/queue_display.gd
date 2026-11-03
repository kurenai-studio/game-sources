extends Control

var upcoming_tiers: Array[int] = []

# Called by Main whenever the queue changes
func update_queue(peeked: Array[int]) -> void:
	if peeked.size() >= 2:
		Kerno.setup_visual($NextSlime1, peeked[0], Vector2(0.0, 20.0))
		Kerno.setup_visual($NextSlime2, peeked[1], Vector2(0.0, 90.0))
		if can_peek_more():
			Kerno.setup_visual($NextSlime3, peeked[2], Vector2(0.0, 160.0))
			Kerno.setup_visual($NextSlime4, peeked[3], Vector2(0.0, 230.0))
		else:
			#$NextSlime3.visible = false
			#$NextSlime4.visible = false
			has_node("$NextSlime3") 
			has_node("$NextSlime4") 
	else:
			$NextSlime1.visible = false
			$NextSlime2.visible = false
			#$NextSlime3.visible = false
			#$NextSlime4.visible = false

	queue_redraw() # Requests Godot to call _draw()

func can_peek_more() -> bool:
	return false # Placeholder for future logic to determine if more kernoj can be peeked