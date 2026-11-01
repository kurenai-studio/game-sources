extends "res://tests/base_test.gd"
## Screens and panels on their own (docs/ARCHITECTURE.md section 11,
## DESIGN_SYSTEM.md section 7), each in a host Control that carries the skin's
## Theme, as the App's root does.

const U := preload("res://tests/ui/ui_fixtures.gd")
const Copy := preload("res://src/ui/screen_copy.gd")
const UiParts := preload("res://src/ui/ui_parts.gd")

var _hosts: Array[Control] = []
var _events: Array[String] = []


func before_each() -> void:
	_hosts = []
	_events = []
	SafeArea.simulated_insets = Vector2(-1.0, -1.0)


func after_each() -> void:
	for host: Control in _hosts:
		if is_instance_valid(host):
			host.get_parent().remove_child(host)
			host.free()
	SafeArea.simulated_insets = Vector2(-1.0, -1.0)


func _host(skin_id: StringName) -> Control:
	var host: Control = Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.theme = UiKit.build_theme(SkinCatalog.get_skin(skin_id))
	U.root().add_child(host)
	_hosts.append(host)
	return host


func _record(event: String) -> void:
	_events.append(event)


func _record_id(booster_id: StringName) -> void:
	_events.append("buy " + String(booster_id))


## A session showing the offer for this state.
func _offer_session(state: RunState, config: GameConfig = null) -> GameSession:
	var session: GameSession = GameSession.new(config)
	session.resume(state)
	session.move_shown()
	return session


func _offer_panel(skin_id: StringName, session: GameSession) -> OfferPanel:
	var panel: OfferPanel = (load("res://scenes/ui/offer_panel.tscn") as PackedScene).instantiate() as OfferPanel
	_host(skin_id).add_child(panel)
	panel.setup(SkinCatalog.get_skin(skin_id))
	panel.show_offer(session.booster_statuses(), session.state.score)
	panel.booster_chosen.connect(_record_id)
	panel.end_run_chosen.connect(_record.bind("end run"))
	return panel


# OfferPanel, D-42 (AT-47, AT-49, AT-109)

func test_at_47_offer_marks_shuffle() -> void:
	var session: GameSession = _offer_session(U.run(U.board_d1024(), 5000, U.snapshot_board(), 40))
	assert_true(session.is_offer_open(), "the offer is open")
	var panel: OfferPanel = _offer_panel(&"gumdrop", session)
	assert_not_null(panel.buy_button(), "a buy button")
	assert_eq(panel.buy_button().text, "Shuffle for 1024", "for the suggested Shuffle, cost as a tile label")
	assert_eq(panel.buy_button().theme_type_variation, &"PrimaryButton", "primary")
	assert_eq(panel.end_run_button().theme_type_variation, &"SecondaryButton", "End run is secondary")
	assert_eq(panel.body_text(), Copy.OFFER_BODY, "the offer text")
	assert_eq(panel.score_text(), "5,000", "the current score")
	panel.buy_button().pressed.emit()
	panel.end_run_button().pressed.emit()
	assert_eq(_events, ["buy shuffle", "end run"] as Array[String], "both buttons report")


func test_at_49_offer_marks_undo() -> void:
	var session: GameSession = _offer_session(U.run(U.board_d1024(), 600, U.snapshot_board(), 40))
	var panel: OfferPanel = _offer_panel(&"gumdrop", session)
	assert_eq(panel.buy_button().text, "Undo for 512", "Undo is the rescue")
	panel.buy_button().pressed.emit()
	assert_eq(_events, ["buy undo"] as Array[String], "buys Undo")


func test_at_109_d_offer_with_nothing_marked() -> void:
	var config: GameConfig = GameConfig.new()
	config.cost_shift[&"shuffle"] = 2
	config.cost_shift[&"undo"] = 2
	var session: GameSession = _offer_session(U.run(U.board_d1024(), 1500, U.snapshot_board(), 40), config)
	assert_true(session.is_offer_open(), "Hammer and Swap keep the offer open")
	var panel: OfferPanel = _offer_panel(&"gumdrop", session)
	assert_null(panel.buy_button(), "no buy button")
	assert_eq(panel.end_run_button().theme_type_variation, &"PrimaryButton", "End run alone, as the primary button")
	assert_eq(panel.body_text(), Copy.OFFER_NO_RESCUE, "the no rescue text")


func test_offer_rebuilds_only_when_it_changes() -> void:
	var session: GameSession = _offer_session(U.run(U.board_d1024(), 5000, U.snapshot_board(), 40))
	var panel: OfferPanel = _offer_panel(&"gumdrop", session)
	var first: Button = panel.buy_button()
	panel.show_offer(session.booster_statuses(), session.state.score)
	assert_true(panel.buy_button() == first, "the same offer keeps its buttons")
	panel.show_offer(session.booster_statuses(), BigNum.from_int(4000))
	assert_eq(panel.score_text(), "4,000", "a new score shows")


func test_offer_signal_label_follows_the_skin_case() -> void:
	var session: GameSession = _offer_session(U.run(U.board_d1024(), 5000, U.snapshot_board(), 40))
	var slate: OfferPanel = _offer_panel(&"slate", session)
	assert_true(_has_text(slate, "OUT OF MOVES"), "Slate's signal label is in capitals")
	assert_eq(slate.theme_type_variation, &"", "Slate's offer has no card")
	var gumdrop: OfferPanel = _offer_panel(&"gumdrop", session)
	assert_true(_has_text(gumdrop, "Out of moves"), "Gumdrop's is as written")
	assert_eq(gumdrop.theme_type_variation, &"CardPanel", "Gumdrop's offer is a card")


# EndPanel (AT-50, AT-54, D-41)

func _summary(new_best: bool) -> RunSummary:
	var summary: RunSummary = RunSummary.new()
	summary.final_score = BigNum.from_int(76410)
	summary.best_score = BigNum.from_int(96520 if not new_best else 76410)
	summary.best_tile = 13
	summary.run_highest = 11
	summary.new_best_score = new_best
	return summary


func _end_panel(skin_id: StringName, summary: RunSummary) -> EndPanel:
	var panel: EndPanel = (load("res://scenes/ui/end_panel.tscn") as PackedScene).instantiate() as EndPanel
	_host(skin_id).add_child(panel)
	panel.setup(SkinCatalog.get_skin(skin_id))
	panel.show_summary(summary)
	return panel


func test_end_panel_shows_the_run_highest_tile_and_new_best() -> void:
	var panel: EndPanel = _end_panel(&"gumdrop", _summary(true))
	assert_eq(panel.score_text(), "76,410", "final score")
	assert_true(panel.shows_new_best(), "New best badge")
	assert_eq(panel.tile_values(), PackedInt64Array([13, 11]), "Best Tile 8192 and this run's highest tile 2048")
	assert_true(_has_text(panel, "New best"), "the badge text")
	assert_true(_has_text(panel, "This run's highest tile"), "the row caption")


func test_end_panel_without_a_new_best() -> void:
	var panel: EndPanel = _end_panel(&"nova", _summary(false))
	assert_false(panel.shows_new_best(), "no badge")
	assert_true(_has_text(panel, "96,520"), "Best Score shown")
	assert_true(_has_text(panel, "Run over"), "Nova's signal label takes the title role, as written")
	assert_true(_has_text(panel, "best score"), "Nova's captions are lowercase")


func test_qa4_01_end_panel_says_no_moves_left() -> void:
	var summary: RunSummary = _summary(false)
	summary.no_moves_left = true
	for skin_id: StringName in SkinCatalog.IDS:
		var panel: EndPanel = _end_panel(skin_id, summary)
		assert_eq(panel.reason_text(), SkinCatalog.get_skin(skin_id).cased(&"body", "No moves left."), "%s: the reason, cased" % skin_id)
		var reason: Label = panel.find_child("Reason", true, false) as Label
		assert_eq(reason.theme_type_variation, &"MutedLabel", "%s: muted body style" % skin_id)
		var expected: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT if skin_id == &"slate" else HORIZONTAL_ALIGNMENT_CENTER
		assert_eq(reason.horizontal_alignment, expected, "%s: aligned like the title" % skin_id)
		var content: Node = reason.get_parent()
		assert_eq(reason.get_index(), 1, "%s: right under the title" % skin_id)
		assert_true(content.get_child(0) is Label, "%s: the title first" % skin_id)


func test_qa4_01_no_reason_after_end_run() -> void:
	var panel: EndPanel = _end_panel(&"gumdrop", _summary(true))
	assert_eq(panel.reason_text(), "", "End run ends with something usable: no reason line")
	assert_null(panel.find_child("Reason", true, false), "and no label")


func test_qa4_04_new_best_sits_on_the_best_score_row() -> void:
	var panel: EndPanel = _end_panel(&"gumdrop", _summary(true))
	var badge: Control = panel.new_best_badge()
	assert_not_null(badge, "the badge shows")
	assert_eq(badge.get_parent().name, &"BestScore", "on the Best score row")
	var row: Node = badge.get_parent()
	assert_true(_has_text(row, "76,410"), "beside the Best Score")
	var score: Label = panel.find_child("FinalScore", true, false) as Label
	assert_false(score.get_parent() == row, "not with the final score")


func test_end_panel_buttons() -> void:
	var panel: EndPanel = _end_panel(&"slate", _summary(false))
	panel.new_game_chosen.connect(_record.bind("new game"))
	panel.home_chosen.connect(_record.bind("home"))
	(panel.find_child("NewGame", true, false) as Button).pressed.emit()
	(panel.find_child("Home", true, false) as Button).pressed.emit()
	assert_eq(_events, ["new game", "home"] as Array[String], "both report")
	assert_null(panel.find_child("MainMenu", true, false), "no Main menu button (AT-150)")
	assert_eq((panel.find_child("Home", true, false) as Button).text, "Home", "Home reads as written")
	assert_eq((panel.find_child("Home", true, false) as Button).theme_type_variation, &"SecondaryButton", "Home is secondary")
	assert_true(_has_text(panel, "RUN OVER"), "Slate's signal label in capitals")
	panel.close()
	(panel.find_child("NewGame", true, false) as Button).pressed.emit()
	assert_eq(_events.size(), 2, "a closing panel takes no input")


# Pause and the confirmation (7.3, 7.4)

func test_pause_panel_buttons() -> void:
	var panel: PausePanel = (load("res://scenes/ui/pause_panel.tscn") as PackedScene).instantiate() as PausePanel
	_host(&"gumdrop").add_child(panel)
	panel.setup(SkinCatalog.get_skin(&"gumdrop"))
	panel.resume_chosen.connect(_record.bind("resume"))
	panel.new_game_chosen.connect(_record.bind("new game"))
	panel.settings_chosen.connect(_record.bind("settings"))
	panel.info_chosen.connect(_record.bind("info"))
	for button_name: String in ["Resume", "Newgame", "Info", "Settings"]:
		(panel.find_child(button_name, true, false) as Button).pressed.emit()
	assert_eq(_events, ["resume", "new game", "info", "settings"] as Array[String], "every choice reports")
	assert_true(_has_text(panel, "Paused"), "the title")


func test_pause_arrangement_7_3() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var panel: PausePanel = (load("res://scenes/ui/pause_panel.tscn") as PackedScene).instantiate() as PausePanel
		_host(skin_id).add_child(panel)
		panel.setup(skin)
		var content: Node = panel.find_child("Resume", true, false).get_parent()
		var order: Array[String] = []
		var variations: Array[StringName] = []
		for child: Node in content.get_children():
			if child is Button:
				order.append(String(child.name))
				variations.append((child as Button).theme_type_variation)
		assert_eq(order, ["Resume", "Newgame", "Info", "Settings"] as Array[String], "%s: Resume, New game, Info, Settings" % skin_id)
		assert_eq(variations, [&"PrimaryButton", &"SecondaryButton", &"SecondaryButton", &"SecondaryButton"] as Array[StringName], "%s: Resume primary, the rest secondary" % skin_id)
		var how: Button = content.find_child("Info", false, false) as Button
		assert_eq(how.text, "Info", "%s: the copy, as written" % skin_id)
		assert_true(how.custom_minimum_size.y >= skin.num(&"touch_min"), "%s: at least touch_min tall" % skin_id)


func test_confirm_dialog() -> void:
	var dialog: ConfirmDialog = (load("res://scenes/ui/confirm_dialog.tscn") as PackedScene).instantiate() as ConfirmDialog
	_host(&"nova").add_child(dialog)
	dialog.setup(SkinCatalog.get_skin(&"nova"), Copy.CONFIRM_TITLE, Copy.CONFIRM_BODY, Copy.NEW_GAME, Copy.CANCEL)
	dialog.confirmed.connect(_record.bind("yes"))
	dialog.cancelled.connect(_record.bind("no"))
	(dialog.find_child("Confirm", true, false) as Button).pressed.emit()
	(dialog.find_child("Cancel", true, false) as Button).pressed.emit()
	assert_eq(_events, ["yes", "no"] as Array[String], "both report")
	assert_true(_has_text(dialog, Copy.CONFIRM_BODY), "the body")


# Settings (7.7)

func test_settings_panel_controls() -> void:
	var settings: Settings = Settings.new()
	settings.set_skin_id(&"slate")
	var panel: SettingsPanel = (load("res://scenes/ui/settings_panel.tscn") as PackedScene).instantiate() as SettingsPanel
	_host(&"slate").add_child(panel)
	panel.setup(SkinCatalog.get_skin(&"slate"), settings)
	panel.closed.connect(_record.bind("closed"))
	var chips: Dictionary[StringName, Button] = panel.skin_chips()
	assert_eq(chips.keys(), [&"gumdrop", &"slate", &"nova"], "three choices in settings order")
	assert_true(chips[&"slate"].button_pressed, "the current skin is selected")
	assert_false(chips[&"gumdrop"].button_pressed, "the others are not")
	assert_eq(chips[&"nova"].text, "Nova", "named")
	panel.sound_toggle().toggled.emit(false)
	assert_false(settings.sound_on, "the toggle sets sound")
	chips[&"gumdrop"].pressed.emit()
	assert_eq(settings.skin_id, &"gumdrop", "a chip sets the skin")
	(panel.find_child("Close", true, false) as BaseButton).pressed.emit()
	assert_eq(_events, ["closed"] as Array[String], "close reports")


func test_settings_about_row_7_7() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var settings: Settings = Settings.new()
		var panel: SettingsPanel = (load("res://scenes/ui/settings_panel.tscn") as PackedScene).instantiate() as SettingsPanel
		_host(skin_id).add_child(panel)
		panel.setup(skin, settings)
		var row: Control = panel.about_row()
		var content: Node = row.get_parent()
		var count: int = content.get_child_count()
		assert_eq(row.get_index(), count - 2, "%s: the About row is next to last" % skin_id)
		assert_true(content.get_child(count - 3) is HSeparator, "%s: after a divider" % skin_id)
		var version: Label = content.get_child(count - 1) as Label
		assert_eq(version.text, skin.cased(&"label", Copy.version_line()), "%s: then the version line, as today" % skin_id)
		assert_eq(row.call(&"title_text"), skin.cased(&"body", "About"), "%s: About in the body role" % skin_id)
		assert_eq(row.call(&"detail_text"), "", "%s: no detail line" % skin_id)
		assert_true(row.custom_minimum_size.y >= skin.num(&"touch_min"), "%s: at least touch_min" % skin_id)
		assert_true(row.custom_minimum_size.y >= skin.num(&"row_height"), "%s: at least row_height" % skin_id)
		assert_not_null(row.find_child("Chevron", true, false) as SkinIcon, "%s: the chevron on the right" % skin_id)
		assert_eq(row.find_child("Chevron", true, false).get_index(), 1, "%s: after the title" % skin_id)
		panel.about_chosen.connect(_record.bind("about %s" % skin_id))
		row.emit_signal(&"tapped")
		assert_true(_events.has("about %s" % skin_id), "%s: a tap on the row opens About" % skin_id)
		panel.close()
		row.emit_signal(&"tapped")
		assert_eq(_events.count("about %s" % skin_id), 1, "%s: a closing panel takes no tap" % skin_id)


func test_offer_reads_for_free_while_a_free_booster_is_held() -> void:
	# AT-135 (a): Board D1024, score 0, run highest 8192, 1 free booster held.
	var session: GameSession = _offer_session(U.run(U.board_d1024(), 0, PackedInt64Array(), 0, 13))
	assert_true(session.is_offer_open(), "the offer opens")
	for skin_id: StringName in SkinCatalog.IDS:
		var panel: OfferPanel = _offer_panel(skin_id, session)
		assert_eq(panel.buy_button().text, SkinCatalog.get_skin(skin_id).cased(&"body", "Shuffle for free"), "%s: Shuffle for free" % skin_id)
	assert_eq(Copy.buy(&"undo", 11, true), "Undo for free", "any booster")
	assert_eq(Copy.buy(&"undo", 11, false), "Undo for 2K", "paid: the cost is an exponent, 11 is 2K")
	assert_eq(Copy.buy(&"shuffle", 69, false), "Shuffle for 512aa", "a lettered cost keeps its case")


func test_settings_swatch_edge_only_when_it_matches_the_panel() -> void:
	var settings: Settings = Settings.new()
	settings.set_skin_id(&"slate")
	var panel: SettingsPanel = (load("res://scenes/ui/settings_panel.tscn") as PackedScene).instantiate() as SettingsPanel
	_host(&"slate").add_child(panel)
	panel.setup(SkinCatalog.get_skin(&"slate"), settings)
	var slate_swatch: PanelContainer = panel.find_child("Swatch_slate", true, false) as PanelContainer
	var nova_swatch: PanelContainer = panel.find_child("Swatch_nova", true, false) as PanelContainer
	var slate_style: StyleBoxFlat = slate_swatch.get_theme_stylebox(&"panel") as StyleBoxFlat
	var nova_style: StyleBoxFlat = nova_swatch.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_eq(slate_style.border_width_top, 2, "Slate's swatch matches Slate's sheet, so it gets the edge")
	assert_eq(nova_style.border_width_top, 0, "Nova's does not")
	assert_eq(slate_style.bg_color, SkinCatalog.get_skin(&"slate").color(&"bg"), "each swatch in its own skin's bg")
	assert_eq(nova_style.bg_color, SkinCatalog.get_skin(&"nova").color(&"bg"), "Nova's bg")


# Splash (7.2, GDD D-47)

func _splash(skin_id: StringName, records: Records) -> SplashScreen:
	var splash: SplashScreen = (load("res://scenes/ui/splash_screen.tscn") as PackedScene).instantiate() as SplashScreen
	_host(skin_id).add_child(splash)
	splash.setup(SkinCatalog.get_skin(skin_id), records)
	return splash


func test_splash() -> void:
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(96520)
	records.best_tile = 13
	var splash: SplashScreen = _splash(&"gumdrop", records)
	splash.play_chosen.connect(_record.bind("play"))
	splash.info_chosen.connect(_record.bind("info"))
	splash.about_chosen.connect(_record.bind("about"))
	splash.settings_chosen.connect(_record.bind("settings"))
	assert_eq(splash.best_score_text(), "96,520", "Best Score")
	assert_not_null(splash.wordmark(), "the drawn wordmark")
	assert_eq(_tile_count(splash), 2, "the sum row's result tile, then Best Tile")
	assert_true(_has_text(splash, "Best tile"), "the Best tile row")
	(splash.find_child("Play", true, false) as Button).pressed.emit()
	(splash.find_child("Info", true, false) as Button).pressed.emit()
	(splash.find_child("About", true, false) as Button).pressed.emit()
	(splash.find_child("Settings", true, false) as BaseButton).pressed.emit()
	assert_eq(_events, ["play", "info", "about", "settings"] as Array[String], "every button reports")


func test_splash_arrangement_7_2() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var splash: SplashScreen = _splash(skin_id, Records.new())
		var play: Button = splash.find_child("Play", true, false) as Button
		var info: Button = splash.find_child("Info", true, false) as Button
		var about: Button = splash.find_child("About", true, false) as Button
		var buttons: VBoxContainer = play.get_parent() as VBoxContainer
		assert_eq(play.get_index(), 0, "%s: Play first" % skin_id)
		assert_eq(info.get_parent().get_parent(), buttons, "%s: Info and About in one row under Play" % skin_id)
		assert_eq(info.get_parent(), about.get_parent(), "%s: side by side" % skin_id)
		assert_true(info.get_index() < about.get_index(), "%s: Info, then About" % skin_id)
		assert_eq(buttons.get_theme_constant(&"separation"), roundi(skin.num(&"space_s")), "%s: space_s apart" % skin_id)
		assert_eq((info.get_parent() as HBoxContainer).get_theme_constant(&"separation"), roundi(skin.num(&"space_s")), "%s: space_s between Info and About" % skin_id)
		assert_eq(info.size_flags_horizontal, Control.SIZE_EXPAND_FILL, "%s: Info shares the width" % skin_id)
		assert_eq(about.size_flags_horizontal, Control.SIZE_EXPAND_FILL, "%s: About shares the width" % skin_id)
		assert_eq(play.theme_type_variation, &"PrimaryButton", "%s: Play primary" % skin_id)
		assert_eq(info.theme_type_variation, &"SecondaryButton", "%s: Info secondary" % skin_id)
		assert_eq(about.theme_type_variation, &"SecondaryButton", "%s: About secondary" % skin_id)
		for button: Button in [play, info, about]:
			assert_eq(button.text, String(button.name), "%s: %s reads as written (body role)" % [skin_id, button.name])
			assert_true(button.custom_minimum_size.y >= skin.num(&"button_height"), "%s: button_height tall" % skin_id)
			assert_eq(button.alignment, HORIZONTAL_ALIGNMENT_LEFT if skin_id == &"slate" else HORIZONTAL_ALIGNMENT_CENTER, "%s: Slate left aligns button text" % skin_id)
		var layout: Node = splash.find_child("Layout", true, false)
		# 2026-10-17: space_xs and the coffee row now sit under the buttons, on
		# the bottom of the safe area.
		assert_eq(buttons.get_parent().get_index(), layout.get_child_count() - 3, "%s: the buttons, then space_xs and the coffee row" % skin_id)
		var coffee: Control = splash.coffee_button()
		assert_eq(coffee.get_parent().get_index(), layout.get_child_count() - 1, "%s: the coffee row on the bottom of the safe area" % skin_id)
		assert_near((layout.get_child(layout.get_child_count() - 2) as Control).custom_minimum_size.y, skin.num(&"space_xs"), 0.01, "%s: space_xs above it" % skin_id)
		var margins: MarginContainer = buttons.get_parent() as MarginContainer
		assert_eq(margins.get_theme_constant(&"margin_left"), roundi(skin.num(&"board_margin")), "%s: full width less board_margin" % skin_id)
		# The sum row: the skin's board view chained 2, 2, 4, 8 at 144 px, the
		# 72 px arrow, the result 16.
		var board: SkinBoardView = splash.sum_board()
		assert_true((board.get_script() as Script).resource_path.contains(String(skin_id)), "%s: the skin's own board view" % skin_id)
		assert_eq(int(board.get(&"columns")), 4, "%s: four cells" % skin_id)
		assert_eq(int(board.get(&"rows")), 1, "%s: one row" % skin_id)
		assert_eq(board.get(&"_cells"), PackedInt64Array([1, 1, 2, 3]), "%s: 2, 2, 4, 8" % skin_id)
		assert_eq((board.get(&"_chain") as Array).size(), 4, "%s: all four chained" % skin_id)
		assert_near(board.custom_minimum_size.x, UiParts.chain_width(skin, 4, 144.0), 0.01, "%s: sized for 144 px tiles" % skin_id)
		assert_eq(splash.sum_arrow().custom_minimum_size, Vector2(72.0, 72.0), "%s: the 72 px arrow" % skin_id)
		assert_eq(splash.sum_result().custom_minimum_size, Vector2(144.0, 144.0), "%s: the 144 px result" % skin_id)
		assert_eq(int(splash.sum_result().get(&"_value")), 4, "%s: the result 16" % skin_id)
		var row: HBoxContainer = board.get_parent() as HBoxContainer
		assert_eq(row.alignment, BoxContainer.ALIGNMENT_BEGIN if skin_id == &"slate" else BoxContainer.ALIGNMENT_CENTER, "%s: Slate left aligns the row" % skin_id)
		# The wordmark: the skin's drawn one, fitted to the row, never below
		# the display size.
		var wordmark: SkinWordmark = splash.wordmark()
		assert_true((wordmark.get_script() as Script).resource_path.contains(String(skin_id)), "%s: the skin's own wordmark" % skin_id)
		var row_width: float = row.get_combined_minimum_size().x
		var drawn: float = float(wordmark.call(&"_drawn_width_at", int(wordmark.get(&"_px"))))
		assert_true(drawn <= row_width + 0.01, "%s: no wider than the sum row (%d of %d px)" % [skin_id, roundi(drawn), roundi(row_width)])
		assert_true(int(wordmark.get(&"_px")) >= skin.font_size(&"display"), "%s: never below the display size" % skin_id)
		assert_eq(bool(wordmark.get(&"_masthead")), true, "%s: the masthead asked for (only Slate draws it)" % skin_id)
		_assert_ignores_mouse(splash.find_child("Brand", true, false), skin_id)


func _assert_ignores_mouse(node: Node, label: String) -> void:
	for child: Node in node.find_children("*", "Control", true, false):
		assert_eq((child as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s: %s takes no input" % [label, child.name])


func test_splash_hides_best_tile_before_the_first_run() -> void:
	var splash: SplashScreen = _splash(&"slate", Records.new())
	assert_eq(splash.best_score_text(), "0", "Best Score 0")
	assert_eq(_tile_count(splash), 1, "only the sum row's result tile")
	assert_false(_has_text(splash, "BEST TILE"), "no Best Tile row yet")
	assert_true(_has_text(splash, "BEST SCORE"), "Slate captions in capitals")


func test_splash_entrance() -> void:
	Motion.bind_tweens = false
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var splash: SplashScreen = _splash(skin_id, Records.new())
		var board: SkinBoardView = splash.sum_board()
		assert_eq(splash.entrance_stage(), SplashScreen.Entrance.REST, "%s: built at rest" % skin_id)
		splash.play_entrance()
		assert_eq(splash.entrance_stage(), SplashScreen.Entrance.BRAND_IN, "%s: the brand comes in" % skin_id)
		assert_eq(board.get(&"_cells"), PackedInt64Array([0, 0, 0, 0]), "%s: the sum row starts empty" % skin_id)
		assert_true((board.get(&"_chain") as Array).is_empty(), "%s: with no chain" % skin_id)
		assert_eq(splash.sum_arrow().modulate.a, 0.0, "%s: the arrow hidden" % skin_id)
		assert_eq(splash.sum_result().modulate.a, 0.0, "%s: the result hidden" % skin_id)
		for button: String in ["Play", "Info", "About"]:
			assert_eq((splash.find_child(button, true, false) as Button).modulate.a, 1.0, "%s: %s shows from the first frame" % [skin_id, button])
		var half: float = skin.duration(&"dialog_in") * 0.5
		splash.entrance_tween().custom_step(half * 0.9)
		assert_eq(splash.entrance_stage(), SplashScreen.Entrance.BRAND_IN, "%s: no spawn before half of dialog_in" % skin_id)
		splash.entrance_tween().custom_step(half * 0.2)
		assert_eq(splash.entrance_stage(), SplashScreen.Entrance.SPAWNING, "%s: the tiles spawn at half of dialog_in" % skin_id)
		assert_eq(board.get(&"_cells"), PackedInt64Array([1, 1, 2, 3]), "%s: 2, 2, 4 and 8 come in" % skin_id)
		assert_true((board.get(&"_chain") as Array).is_empty(), "%s: still with no chain line" % skin_id)
		splash.entrance_tween().custom_step(10.0)
		assert_eq(splash.entrance_stage(), SplashScreen.Entrance.REST, "%s: the entrance ends" % skin_id)
		assert_eq((board.get(&"_chain") as Array).size(), 4, "%s: the chain appears whole" % skin_id)
		assert_eq(splash.sum_arrow().modulate.a, 0.0, "%s: the arrow starts its fade" % skin_id)
		splash.apply_skin(skin)
		assert_eq(splash.entrance_stage(), SplashScreen.Entrance.REST, "%s: a skin switch rebuilds it at rest" % skin_id)
		assert_eq(splash.sum_result().modulate.a, 1.0, "%s: with the result showing" % skin_id)
	Motion.bind_tweens = true


func test_splash_sum_row_shrinks_only_without_room() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var splash: SplashScreen = _splash(&"gumdrop", Records.new())
	splash.layout_in(Rect2(0.0, 0.0, 1080.0, 2400.0), Rect2(0.0, 120.0, 1080.0, 2214.0))
	assert_eq(splash.sum_tile_side(), 144.0, "144 px on a phone")
	splash.layout_in(Rect2(0.0, 0.0, 1080.0, 1100.0), Rect2(0.0, 0.0, 1080.0, 1100.0))
	assert_true(splash.sum_tile_side() < 144.0, "smaller when there is no room")
	assert_true(splash.sum_tile_side() >= 112.0, "never below 112 px")
	assert_near(splash.sum_board().custom_minimum_size.x, UiParts.chain_width(skin, 4, splash.sum_tile_side()), 0.01, "the board follows")


# Shared rules

func test_panel_shape_follows_the_skin() -> void:
	assert_true(UiParts.panel_floats(_host(&"gumdrop")), "Gumdrop's panel is a floating card")
	assert_false(UiParts.panel_floats(_host(&"slate")), "Slate's is a sheet")
	assert_false(UiParts.panel_floats(_host(&"nova")), "Nova's is a sheet")


func test_slate_rules() -> void:
	var slate: SkinData = SkinCatalog.get_skin(&"slate")
	var nova: SkinData = SkinCatalog.get_skin(&"nova")
	assert_eq(UiParts.role(slate, &"SignalLabel"), &"label", "Slate's signal label is the label role")
	assert_eq(UiParts.role(nova, &"SignalLabel"), &"title", "elsewhere the title role")
	var made: Array[Button] = []
	for variation: StringName in [&"PrimaryButton", &"SecondaryButton"]:
		var slate_button: Button = UiParts.button(slate, variation, "Go")
		var nova_button: Button = UiParts.button(nova, variation, "Go")
		assert_eq(slate_button.alignment, HORIZONTAL_ALIGNMENT_LEFT, "Slate left aligns %s text" % variation)
		assert_eq(nova_button.alignment, HORIZONTAL_ALIGNMENT_CENTER, "others center %s text" % variation)
		made.append_array([slate_button, nova_button])
	var chip: Button = UiParts.button(slate, &"ChipButton", "Go")
	assert_eq(chip.alignment, HORIZONTAL_ALIGNMENT_CENTER, "Slate chips keep centered text")
	made.append(chip)
	for button: Button in made:
		button.free()


func test_safe_area() -> void:
	assert_eq(SafeArea.viewport_safe_rect(null), Rect2(), "no viewport, no rect")
	var viewport: Viewport = U.root()
	var visible: Rect2 = viewport.get_visible_rect()
	assert_eq(SafeArea.viewport_safe_rect(viewport), visible, "headless: the whole visible rect")
	SafeArea.simulated_insets = Vector2(120.0, 66.0)
	var simulated: Rect2 = SafeArea.viewport_safe_rect(viewport)
	assert_eq(simulated.position.y, visible.position.y + 120.0, "top inset")
	assert_eq(simulated.end.y, visible.end.y - 66.0, "bottom inset")
	assert_eq(simulated.size.x, visible.size.x, "full width")


func _has_text(node: Node, text: String) -> bool:
	for child: Node in node.find_children("*", "Label", true, false):
		if (child as Label).text == text:
			return true
	return false


func _tile_count(node: Node) -> int:
	var count: int = 0
	for child: Node in node.find_children("*", "", true, false):
		if child is SkinTileView:
			count += 1
	return count
