extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Puck:
		if Globals.manager.is_practice:
			body.home.call_deferred()
			return

		if not body.shot_on_goal_counted and body.last_possessor != "":
			if not Globals.shot_stats.has(body.last_possessor):
				Globals.shot_stats[body.last_possessor] = 0
			Globals.shot_stats[body.last_possessor] += 1
			body.shot_on_goal_counted = true

		Globals.manager.goal_scored(get_parent().name, body.last_possessor, body.assist_possessor)
		if "anim_manager" in Globals.manager and Globals.manager.anim_manager != null:
			Globals.manager.anim_manager.on_goal_scored()
		else:
			var pucks = get_tree().get_nodes_in_group("pucks")
			for p in pucks:
				p.home.call_deferred()
			var skaters = get_tree().get_nodes_in_group("skaters")
			for s in skaters:
				if s.has_method("home"):
					s.home.call_deferred()
