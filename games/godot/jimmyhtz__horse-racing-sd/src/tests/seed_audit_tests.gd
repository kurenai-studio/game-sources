extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label_text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+label_text)
func _initialize() -> void:
	var stream = load("res://tools/audit_crypto_stream.gd")
	var candidate = load("res://tools/audit_super_seed_experiment.gd")
	var master := "00".repeat(32)
	var changed := "00".repeat(31)+"01"
	var a = stream.new(master,"scheduler")
	var b = stream.new(master,"scheduler")
	var c = stream.new(changed,"scheduler")
	var d = stream.new(master,"horse:0")
	var different_master := false
	var different_domain := false
	for i in range(1000):
		var draw: int = a.raw()
		check(draw == b.raw(),"same master/domain reproduces exact stream")
		different_master = different_master or draw != c.raw()
		different_domain = different_domain or draw != d.raw()
		check(draw >= 0 and draw < 4294967296,"unsigned 32-bit random draw")
	check(different_master and different_domain,"master bits and domain labels separate streams")
	var seen := {}
	for i in range(1000):
		var fresh: String = candidate.fresh_seed("fixed-mouse-digest")
		check(fresh.length() == 64 and fresh.is_valid_hex_number(false),"fresh full-width hex master")
		check(not seen.has(fresh),"no repeated masters in sampled fresh-seed calls")
		seen[fresh] = true
		check(JSON.parse_string(JSON.stringify({"seed":fresh})).seed == fresh,"seed round-trips without numeric precision loss")
	var first = candidate.new(master)
	var second = candidate.new(master)
	second._positions = [80.0,-20.0,30.0,0.0,-5.0]
	var repeat_seen := false
	var long_gap_seen := false
	var previous: Array = []
	for round_index in range(100):
		var order: Array = []
		for slot in range(5):
			first.advance_event()
			second.advance_event()
			order.append(first.last_event().selected)
			check(first.snapshot().velocities == second.snapshot().velocities,"stronger streams introduce no position feedback")
		if not previous.is_empty():
			repeat_seen = repeat_seen or previous.back() == order.front()
			long_gap_seen = long_gap_seen or previous.front() == order.back()
		previous = order.duplicate()
		order.sort()
		check(order == [0,1,2,3,4],"five distinct turns per round with stronger streams")
	check(repeat_seen and long_gap_seen,"boundary repeats and longest intervals retained")
	var replay = candidate.new(master).run()
	check(candidate.new(master).run() == replay,"exact same stored master replays the race")
	check(replay.seed == master and replay.settings.round_seconds == .005,"full master and unchanged standard timing retained")
	# Demonstrate the old engine's seed collapse, without changing it.
	var old = load("res://core/effort_race_engine.gd")
	var old_a: Dictionary = old.new(1).run()
	var old_b: Dictionary = old.new(2147483647).run()
	check(old_a.positions == old_b.positions and old_a.first_time == old_b.first_time,"old seeds separated by 2147483646 replay the same movement")
	print("SEED AUDIT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
