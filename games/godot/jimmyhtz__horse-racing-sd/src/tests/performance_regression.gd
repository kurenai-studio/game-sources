extends SceneTree
var failures := 0
var draws := 0
var themes := 0
func check(ok: bool, caption: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var prefs = load("res://core/game_settings.gd").new().values
	prefs.master_volume = 0.0
	var session = load("res://core/game_session.gd").new()
	session.fund_demo()
	session.players[0].bets = {"1-2":2}
	var display = load("res://ui/race_display.gd").new()
	root.add_child(display)
	display.configure(session,prefs)
	display.track.moving = false
	display.minis[0].cells["1-2"].label.theme_changed.connect(func(): themes += 1)
	display.track.draw.connect(func(): draws += 1)
	for i in range(8): await process_frame
	draws = 0
	themes = 0
	for i in range(8): await process_frame
	check(draws == 0,"paused track does not redraw unchanged scenery")
	check(themes == 0,"unchanged wager labels do not invalidate layout")
	display.track.photo_hold = true
	display.track.highlight = 1
	display.track._highlight_clock = 0.1
	for i in range(3): await process_frame
	draws = 0
	display.track._highlight_clock = 0.7
	for i in range(3): await process_frame
	check(draws > 0,"paused photo finish redraws its single flashing number")
	display.set_winning_pair("1-2")
	var lit: Color = display.minis[0].cells["1-2"].amount.ink
	display.flash_clock = 0.8
	display.update_flash()
	check(display.minis[0].cells["1-2"].amount.ink != lit,"official winning wager still flashes")
	display.prefs.reduce_flashing = true
	display.update_flash()
	check(display.minis[0].cells["1-2"].amount.ink == lit,"reduced flashing retains bright winner")
	display.queue_free()
	await process_frame
	print("PERFORMANCE REGRESSION: %d failures" % failures)
	quit(0 if failures == 0 else 1)
