extends TestCase
## Bodies: thrown things arc, land, bounce lower each time and slide to a stop.


func test_a_thrown_body_arcs_and_lands_where_physics_says() -> void:
	var body := Body.new()
	body.push(Vector2(2.0, 0.0), 3.0)
	var peak := 0.0
	var landed_at := -1.0
	for step in 120:
		body.step(1.0 / 60.0)
		peak = maxf(peak, body.height)
		if landed_at < 0.0 and step > 2 and body.height == 0.0:
			landed_at = body.position.x
	# Thrown up at 3 m/s it rises 3²/(2g), about 46 cm, and comes down after 2·3/g, 0.61 s.
	check(absf(peak - 0.459) < 0.03, "peaked at %.3f m" % peak)
	check(absf(landed_at - 1.22) < 0.06, "landed %.2f m along" % landed_at)


func test_bounces_get_lower_and_it_settles() -> void:
	var body := Body.new()
	body.height = 1.0
	var peaks: Array[float] = []
	var rising := false
	var last := body.height
	for step in 60 * 4:
		body.step(1.0 / 60.0)
		if body.height > last:
			rising = true
		elif rising and body.height < last:
			peaks.append(last)
			rising = false
		last = body.height
	check(peaks.size() >= 1, "it never bounced")
	for index in range(1, peaks.size()):
		check(peaks[index] < peaks[index - 1], "bounce %d rose higher than the one before" % index)
	check(not body.airborne(), "still bouncing after four seconds")


func test_sliding_slows_to_a_stop() -> void:
	var body := Body.new()
	body.velocity = Vector2(3.0, 0.0)
	for step in 60 * 2:
		body.slide(1.0 / 60.0)
		body.step(1.0 / 60.0)
	check(body.velocity == Vector2.ZERO, "still sliding at %s" % body.velocity)
	# From 3 m/s at 6 m/s², it slides 3²/(2·6), 75 cm.
	check(absf(body.position.x - 0.75) < 0.05, "slid %.2f m" % body.position.x)
