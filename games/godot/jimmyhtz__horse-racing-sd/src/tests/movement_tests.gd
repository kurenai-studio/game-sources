extends SceneTree
var checks := 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)
func near(a: float, b: float) -> bool:
	return absf(a-b) < 0.000001
func _initialize() -> void:
	if not ResourceLoader.exists("res://core/effort_race_engine.gd"):
		check(false, "new effort movement engine is available")
		finish()
		return
	var engine = load("res://core/effort_race_engine.gd")
	if engine == null:
		check(false, "movement engine loads")
		finish()
		return
	check(engine.validate_config({}).is_empty(), "default configuration accepted")
	for invalid in [{"winner":2}, {"round_seconds":0}, {"speed_spread":1.0}, {"base_speed":true}, {"strengths":[0,0]}, {"finish_steps":INF}, {"base_speed":1.7e308,"finish_steps":1.7e308,"speed_spread":0.4,"acceleration":1.0,"strengths":[0.3,0.3,0.3,0.3,0.3]}]:
		check(not engine.validate_config(invalid).is_empty(), "unsafe or outcome-selecting configuration rejected")
	var race = engine.new(123)
	var turns: Array = []
	var repeat_found := false
	var longest_found := false
	var prior_order: Array = []
	for round_index in range(200):
		var order: Array = []
		for slot in range(5):
			var before: Dictionary = race.snapshot()
			race.advance_event()
			var after: Dictionary = race.snapshot()
			var event: Dictionary = race.last_event()
			order.append(event.selected)
			for horse in range(5):
				check(after.positions[horse] > before.positions[horse] if horse == event.selected else after.positions[horse] == before.positions[horse], "only the scheduled horse receives its movement quantum")
				check(after.effort[horse] >= 0.0 and after.effort[horse] <= 1.0, "effort reserve bounded")
				check(after.velocities[horse] > 0.0, "positive running speeds")
				check(absf(after.velocities[horse]-before.velocities[horse]) <= 30.0*0.08*0.005+0.000001, "bounded smooth acceleration")
		var sorted := order.duplicate()
		sorted.sort()
		check(sorted == [0,1,2,3,4], "every horse moves exactly once per round")
		if not prior_order.is_empty():
			repeat_found = repeat_found or prior_order.back() == order.front()
			longest_found = longest_found or prior_order.front() == order.back()
		prior_order = order
	check(repeat_found, "boundary repeats are not suppressed")
	check(longest_found, "maximum boundary interval is not suppressed")
	# Same own state and random streams must give identical effort decisions despite different standings.
	var left = engine.new(47)
	var right = engine.new(47)
	right._positions = [80.0, -20.0, 30.0, 0.0, -5.0]
	for index in range(500):
		left.advance_event()
		right.advance_event()
		var a: Dictionary = left.snapshot()
		var b: Dictionary = right.snapshot()
		check(a.velocities == b.velocities and a.effort == b.effort and a.phases == b.phases, "no rank or gap feedback in horse dynamics")
	# Every turn moves 0.1 distance over 0.002 time. All five reach 0.1 in round one.
	# Round two's first horse crosses 0.15 halfway through turn six; the next crosses halfway through turn seven.
	var exact = engine.new(5, {"base_speed":10.0, "speed_spread":0.0, "round_seconds":0.01, "finish_steps":0.15, "record_trace":true})
	var result: Dictionary = exact.run()
	check(near(result.first_time, 0.011), "first crossing inside serial movement event")
	check(near(result.second_time, 0.013), "second crossing inside the following event")
	check(result.first != result.second, "serial crossing order has distinct winners")
	check(near(result.positions[result.second], 0.15), "freeze exactly at second crossing")
	var partial: Array = exact.positions_at(0.0105)
	check(near(partial[result.first], 0.125), "render interpolation preserves the scheduled partial move")
	for horse in range(5):
		if horse != result.first:
			check(near(partial[horse], 0.1), "interpolation does not spread a turn to other horses")
	var immutable: Dictionary = exact.result()
	result.positions[0] = -99
	exact.advance_event()
	check(exact.result() == immutable, "result immutable after finish and caller mutation")
	var first = engine.new(91, {"record_trace":true})
	var second = engine.new(91)
	var outcome: Dictionary = first.run()
	check(outcome == second.run(), "trace collection does not change seeded outcomes")
	check(first.positions_at(outcome.second_time) == outcome.positions, "playback ends at official snapshot")
	check(not outcome.calibrated, "prototype does not claim calibrated probabilities")
	finish()
func finish() -> void:
	print("MOVEMENT CHECKS: %d | FAILURES: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
