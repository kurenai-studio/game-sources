extends SceneTree
var checks := 0
var failures := 0
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
func _init() -> void:
	if not FileAccess.file_exists("res://tools/payback_v2/race_candidate.gd"):
		check(false,"Movement-derived candidate is not implemented")
		quit(1)
		return
	var engine = load("res://tools/payback_v2/race_candidate.gd")
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://test-results/payback-v2/catalog.json"))
	for percent in [70,80,90,100,125,200]:
		for seed_number in range(4):
			var master := ("candidate-test-%d" % seed_number).sha256_text()
			var race = engine.new(master,catalog,percent,seed_number == 0)
			check(race.result().is_empty() and not race.finished,"No finishing result exists at initialization")
			var seen: Array = []
			var previous_round := 0
			var old_positions: Array = [0,0,0,0,0]
			while not race.finished:
				race.advance_event()
				var event: Dictionary = race.last_event()
				if event.round != previous_round:
					check(previous_round == 0 or seen.size() == 5,"Every complete round moves every horse")
					seen.clear()
					previous_round=event.round
				check(event.selected not in seen,"Each horse moves only once per round")
				seen.append(event.selected)
				for h in range(5):
					var delta: float = event.end_positions[h]-old_positions[h]
					check(delta > 0.0 if h == event.selected else delta == 0.0,"Only selected horse moves, always positively")
				old_positions=event.end_positions
			var result: Dictionary = race.result()
			check(result.full_order.size() == 5,"Five actual crossings recorded")
			check(result.first_time < result.second_time,"Serial turns prevent tied crossing times")
			check(result.first == result.full_order[0] and result.second == result.full_order[1],"Outcome is actual crossing order")
			check(result.rounds <= 10000,"Positive steps guarantee bounded completion")
			check(result.round_seconds == 0.005,"Standard timing unchanged")
			if seed_number == 0:
				var replay = engine.new(master,catalog,percent,false)
				check(result == replay.run(),"Same seed replays the actual result exactly")
				var finish_positions: Array = race.positions_at(result.second_time)
				check(absf(finish_positions[result.second]-1000.0)<0.00000001,"Replay reaches actual second crossing")
	print("PAYBACK CANDIDATE CHECKS: %d | FAILURES: %d" % [checks,failures])
	quit(1 if failures else 0)
