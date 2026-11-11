extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: "+message)
func _initialize() -> void:
	var main := FileAccess.get_file_as_string("res://ui/main.gd")
	var race := FileAccess.get_file_as_string("res://ui/race_display.gd")
	var settings := FileAccess.get_file_as_string("res://ui/settings_panel.gd")
	check("begin_payouts" in race,"payout presentation stays in race sidebar")
	check("var navigation: ItemList" in settings,"fixed left settings menu")
	check("close_up" in FileAccess.get_file_as_string("res://ui/track_view.gd"),"track has close-up camera")
	check(not "payout_screen.completed.connect" in main,"payout never automatically advances betting")
	var values=load("res://core/game_settings.gd").new()
	check(values.values.has("start_signal"),"start signal selector exists")
	check(not values.values.has("table_currency"),"settings use credits only")
	print("REVISION CONTRACT: %d failures" % failures)
	quit(1 if failures else 0)
