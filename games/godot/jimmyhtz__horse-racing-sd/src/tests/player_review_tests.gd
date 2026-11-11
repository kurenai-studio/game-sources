extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, caption: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + caption)

func named(app: Node, caption: String) -> Node:
	return app.find_child(caption,true,false)

func labels(parent: Node) -> String:
	var result := ""
	for label in parent.find_children("*","Label",true,false):
		result += label.text + "\n"
	return result

func run() -> void:
	var app = load("res://ui/main.tscn").instantiate()
	app.save_path = "user://player-review-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0)
	root.add_child(app)
	await process_frame
	app.select_player(0)
	app.request_cash_out(0)
	var dialogs: Array = app.find_children("*","ConfirmationDialog",true,false)
	check(dialogs.size() == 1,"cash-out confirmation opens")
	dialogs[0].confirmed.emit()
	await process_frame
	check(app.session.players[0].state == "PENDING PAYOUT" and app.flow.screen == "overview","cash-out closes the departed player's console")
	app.select_player(1)
	check(app.flow.active_player == 1 and app.flow.screen == "betting","another player can act immediately after cash-out")
	# Isolate later assertions from the known failed transition in a red run.
	app.flow.screen = "overview"
	app.flow.active_player = -1
	app.select_player(1)
	app.preferences.set_value("wheel_betting",false)
	app.preferences.set_value("bet_increment",5)
	app.show_betting()
	var amount: SpinBox = named(app,"Wager_1_2")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	amount.gui_input.emit(wheel)
	check(amount.value == 0,"wheel preference off leaves wager unchanged")
	app.preferences.set_value("wheel_betting",true)
	amount.gui_input.emit(wheel)
	check(amount.value == 5 and app.session.wager_total(1) == 5,"wheel preference on uses configured increment")
	await process_frame
	app.preferences.set_value("credit_label","Points")
	app.preferences.set_value("show_totals",false)
	app.preferences.set_value("show_round",false)
	app.preferences.set_value("tooltips",false)
	app.preferences.set_value("compact_stations",true)
	app.show_betting()
	var summary: Button = named(app,"PlayerSummary1")
	var meter_text: String=named(app,"BettingMini1").get_child(0).text.to_lower()
	check("points" in meter_text and not "bet" in meter_text,"credit label and totals preference remain active")
	check(not "RACE 1" in labels(named(app,"PlayerSummaries")),"race number can be hidden")
	check(summary.tooltip_text.is_empty(),"summary tooltip can be disabled")
	var compact_height := summary.custom_minimum_size.y
	app.preferences.set_value("compact_stations",false)
	app.show_betting()
	check(named(app,"PlayerSummary1").custom_minimum_size.y > compact_height,"compact station preference changes layout")
	app.flow.ready()
	app.session.access.set_pin("player_1","1122")
	app.select_player(1)
	app.show_settings()
	await process_frame
	var first: LineEdit = named(app,"NewPin1")
	var second: LineEdit = named(app,"ConfirmPin1")
	first.text = "9876"
	first.text_changed.emit(first.text)
	second.text = "9876"
	second.text_changed.emit(second.text)
	var removal: CheckBox
	for checkbox in named(app,"PlayerBlock1").find_children("*","CheckBox",true,false):
		if checkbox.text == "Remove player PIN":
			removal = checkbox
	removal.button_pressed = true
	check(app.flow.drafts[1].pin.is_empty() and app.flow.drafts[1].confirm.is_empty(),"Remove PIN clears staged replacement entries")
	# A profile/category rebuild must retain the removal form state.
	app.settings_panel.build()
	check(not named(app,"NewPin1").editable and not named(app,"ConfirmPin1").editable,"removed PIN fields stay disabled after rebuild")
	app.flow.drafts[1].pin = ""
	app.flow.drafts[1].confirm = ""
	app.settings_panel.return_to_game()
	await process_frame
	check(not app.session.access.credentials.has("player_1"),"removal commits")
	check(app.flow.screen == "overview" and app.flow.active_player == -1 and app.session.players[1].state == "READY","removal exits obsolete PIN prompt without clearing Ready")
	app.select_player(1)
	check(app.flow.screen == "betting","removed PIN opens directly on next selection")
	app.queue_free()
	await process_frame
	await process_frame
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0,"review UI frees all nodes")
	print("PLAYER REVIEW: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
