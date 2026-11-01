# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The playbook standard screens: About copy and order, license texts, Info,
## Settings, Pause, the mode screen and the App's back button order. These need
## no running scene tree. Layout and touch are in real_tree_checks.gd.

const Probe: GDScript = preload("res://tests/ui/ui_probe.gd")
const Fx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const COVER: Vector2 = Vector2(1080.0, 2767.0)
const COVER_SAFE: Rect2 = Rect2(0.0, 96.0, 1080.0, 2500.0)

var recorder: Probe.Recorder
var app: App
var spare: Array[Node] = []


func before_each() -> void:
	recorder = Probe.Recorder.new()
	Links.opener = recorder.record
	app = null
	spare.clear()


func after_each() -> void:
	Links.opener = Callable()
	Fx.wipe("standard")
	if app != null:
		app.free()
	for node: Node in spare:
		node.free()


func _keep(node: Node) -> Node:
	spare.append(node)
	return node


func _app() -> App:
	app = Fx.app("standard")
	return app


func _texts(root: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return out


func _about() -> AboutScreen:
	return _keep(AboutScreen.new()) as AboutScreen


# About.

func test_about_brand_block_wording() -> void:
	var screen: AboutScreen = _about()
	assert_not_null(screen.wordmark)
	assert_eq(screen.made_by_label.text, "Made by Bart Basi")
	assert_eq(screen.copyright_label.text, "Copyright 2026 Play, Inc.")
	assert_eq(screen.version_label.text, "Version %s" % str(ProjectSettings.get_setting("application/config/version")))
	assert_eq(screen.source_button.text, "Source code: github.com/bartbasi/forkline")
	# The copyright line is body text like the credit: the same look, not muted, no small print.
	assert_eq(screen.copyright_label.theme_type_variation, screen.made_by_label.theme_type_variation)
	assert_eq(screen.copyright_label.theme_type_variation, &"Label")
	assert_false(screen.copyright_label.has_theme_font_size_override(&"font_size"))
	assert_false(screen.made_by_label.has_theme_font_size_override(&"font_size"))


func test_about_brand_block_comes_first() -> void:
	var screen: AboutScreen = _about()
	var first: Node = screen.column.get_child(0)
	assert_true(first.is_ancestor_of(screen.wordmark))
	assert_true(first.is_ancestor_of(screen.copyright_label))
	assert_true(first.is_ancestor_of(screen.source_button))
	assert_false(first.is_ancestor_of(screen.coffee_button))


func test_about_source_link_hands_over_the_source_address() -> void:
	var screen: AboutScreen = _about()
	screen.source_button.tapped.emit()
	assert_eq(recorder.urls, [Links.SOURCE_URL] as Array[String])


func test_about_feedback_button_opens_the_draft() -> void:
	var screen: AboutScreen = _about()
	screen.feedback_button.tapped.emit()
	assert_eq(recorder.urls.size(), 1)
	assert_true(recorder.urls[0].begins_with("mailto:bartbasi@gmail.com?subject="))
	assert_true(_texts(screen).has("I'd love to hear what you think: what you enjoyed, where you got stuck, and what you'd like to see next."))
	assert_eq(screen.feedback_button.text, "Send feedback")


func test_about_coffee_button_hands_over_the_coffee_address() -> void:
	var screen: AboutScreen = _about()
	screen.coffee_button.tapped.emit()
	assert_eq(recorder.urls, [Links.COFFEE_URL] as Array[String])


func test_about_sections_come_in_the_playbook_order_with_its_words() -> void:
	var screen: AboutScreen = _about()
	var texts: PackedStringArray = _texts(screen)
	var order: PackedStringArray = ["What it is", "Offline, no data", "Supporting Forkline", "Licenses"]
	var last: int = -1
	for title: String in order:
		var at: int = texts.find(title)
		assert_true(at > last, "section %s missing or out of order" % title)
		last = at
	assert_true(texts.has("Forkline works fully offline. It collects no data, has no ads or accounts and asks for no permissions. Three buttons hand a fixed address to another app on your phone: Buy me a coffee and the source code link open a web page in your browser, and Send feedback opens a message in your email app. The app itself sends nothing."))
	assert_true(texts.has("Forkline is free, with no ads and no tracking, and it always will be. If you'd like to support more games like it, you can buy me a coffee. Never expected, always appreciated."))
	assert_true(texts.has("Forkline is free software: you can share and change it under the GNU General Public License, version 3, with additional terms. Any copy keeps the attribution above, and changed versions are marked as changed. Forkline comes with no warranty."))
	# The coffee button sits in Supporting, before the Licenses section.
	var supporting_at: int = screen.column.get_children().find(screen.coffee_button.get_parent().get_parent())
	var licenses_at: int = screen.column.get_children().find(screen.license_buttons[LicenseText.FORKLINE].get_parent().get_parent())
	assert_true(supporting_at >= 0 and licenses_at > supporting_at)


func test_about_never_counts_the_additional_terms() -> void:
	var screen: AboutScreen = _about()
	for text: String in _texts(screen):
		assert_false(text.contains("two additional") or text.contains("three additional"), "UI copy must not count the terms")


func test_about_license_rows_ask_for_their_text() -> void:
	var screen: AboutScreen = _about()
	var asked: Array[StringName] = []
	screen.license_requested.connect(func(kind: StringName) -> void: asked.append(kind))
	for kind: StringName in [LicenseText.FORKLINE, LicenseText.GODOT, LicenseText.FONT]:
		screen.license_buttons[kind].tapped.emit()
	assert_eq(asked, [LicenseText.FORKLINE, LicenseText.GODOT, LicenseText.FONT] as Array[StringName])


# License texts.

func _words(text: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for part: String in text.split("\n"):
		for word: String in part.split(" ", false):
			if not word.strip_edges().is_empty():
				out.append(word.strip_edges())
	return out


func test_reflow_keeps_every_word_and_drops_hard_line_breaks() -> void:
	var raw: String = "   TITLE\n\nFirst line of a\nparagraph that wraps\n   and is indented.\n\n\nSecond paragraph.\n"
	var paragraphs: PackedStringArray = LicenseText.reflow(raw)
	assert_eq(paragraphs.size(), 3)
	assert_eq(paragraphs[0], "TITLE")
	assert_eq(paragraphs[1], "First line of a paragraph that wraps and is indented.")
	assert_eq(paragraphs[2], "Second paragraph.")


func test_reflow_loses_no_word_of_the_real_license() -> void:
	var raw: String = LicenseText.read_file(LicenseText.LICENSE_PATH)
	assert_true(raw.length() > 30000, "the GPL text should be readable")
	assert_eq(_words(raw), _words("\n\n".join(LicenseText.reflow(raw))))


func test_pieces_are_small_and_lose_no_word() -> void:
	var raw: String = LicenseText.read_file(LicenseText.LICENSE_PATH)
	var pieces: PackedStringArray = LicenseText.pieces(LicenseText.reflow(raw), 1200)
	assert_true(pieces.size() > 10, "a long text comes in many pieces")
	var all: String = ""
	for piece: String in pieces:
		assert_true(piece.length() <= 1200, "a piece is too long: %d" % piece.length())
		all += " " + piece
	assert_eq(_words(raw), _words(all))


func test_a_very_long_word_is_still_cut() -> void:
	var pieces: PackedStringArray = LicenseText.pieces(PackedStringArray(["x".repeat(3000)]), 1200)
	assert_true(pieces.size() >= 3)
	for piece: String in pieces:
		assert_true(piece.length() <= 1200)


func test_each_about_row_builds_text() -> void:
	for kind: StringName in [LicenseText.FORKLINE, LicenseText.GODOT, LicenseText.FONT]:
		var built: Array[Dictionary] = LicenseText.build(kind)
		assert_true(built.size() > 2, "%s has text" % kind)
		assert_true(built[0]["head"], "%s starts with a heading" % kind)
		for piece: Dictionary in built:
			assert_false(str(piece["text"]).contains(LicenseText.MISSING), "%s should be readable here" % kind)
	assert_eq(LicenseText.build(&"nothing").size(), 0)


func _joined(kind: StringName) -> String:
	var texts: PackedStringArray = PackedStringArray()
	for piece: Dictionary in LicenseText.build(kind):
		texts.append(piece["text"])
	return "\n".join(texts)


func test_forkline_row_has_the_notice_then_the_gpl() -> void:
	var all: String = _joined(LicenseText.FORKLINE)
	var notice_at: int = all.find("Designed and written by Bart Basi, with assistance from Claude.")
	var gpl_at: int = all.find("GNU GENERAL PUBLIC LICENSE")
	assert_true(notice_at >= 0 and gpl_at > notice_at, "the NOTICE comes first, then the GPL")


func test_godot_row_has_the_engine_parts_and_the_android_libraries() -> void:
	var all: String = _joined(LicenseText.GODOT)
	assert_true(all.contains("Permission is hereby granted"), "the engine license text")
	assert_true(all.contains("Android libraries"))
	assert_true(all.contains("AndroidX") and all.contains("libc++"), "the Android libraries named in NOTICE")
	assert_true(all.contains("License: Apache-2.0"), "the Apache text is included")
	assert_true(all.contains("FreeType"), "the engine's own third party list")


func test_font_row_has_the_ofl() -> void:
	assert_true(_joined(LicenseText.FONT).contains("SIL OPEN FONT LICENSE"))


func test_a_missing_file_shows_the_missing_message() -> void:
	assert_eq(LicenseText.read_file("res://does_not_exist.txt"), "")
	assert_eq(LicenseText.MISSING, "This text could not be read in this copy of Forkline. Installing the app again should bring it back.")


func test_the_viewer_adds_its_pieces_over_time_and_can_finish() -> void:
	var pieces: Array[Dictionary] = []
	for i: int in 400:
		pieces.append({"text": "Piece %d. " % i + "word ".repeat(150), "head": i % 50 == 0})
	var viewer: LicenseViewer = _keep(LicenseViewer.new("Test", pieces)) as LicenseViewer
	var box: Node = viewer.column.get_child(0).get_child(0)
	assert_false(viewer.is_complete(), "the first frame does not build everything")
	assert_true(box.get_child_count() > 0, "but the first pieces are there")
	viewer.finish_now()
	assert_true(viewer.is_complete())
	assert_eq(box.get_child_count(), 400)


# Info.

func test_info_has_no_names_and_a_title() -> void:
	var info: InfoScreen = _keep(InfoScreen.new()) as InfoScreen
	assert_eq(info.title_label.text, "Info")
	assert_eq(info.scroll.scroll_vertical, 0)
	var all: String = " ".join(_texts(info)).to_lower()
	for word: String in ["sling", "pumpkin", "lullaby", "longbow", "firework", "bakery", "scamp", "pip", "skitter", "flitter", "grumblesack", "lantern hill", "millbrook", "willow", "moonspire"]:
		assert_false(all.contains(word), "fixed Info text must not name %s" % word)


func test_info_uses_rules_numbers_only_when_given() -> void:
	var plain: InfoScreen = _keep(InfoScreen.new()) as InfoScreen
	var numbered: InfoScreen = _keep(InfoScreen.new({"refund_pct": 70, "star2_lives": 15, "max_waves_running": 2, "run_stars": 12})) as InfoScreen
	var plain_text: String = " ".join(_texts(plain))
	var numbered_text: String = " ".join(_texts(numbered))
	assert_false(plain_text.contains("70%"))
	assert_true(numbered_text.contains("70% of what you spent"))
	assert_true(numbered_text.contains("15 or more lives"))
	assert_true(numbered_text.contains("At most 2 waves"))
	assert_true(numbered_text.contains("12 stars"))


func test_info_captions_come_from_names_only() -> void:
	var plain: InfoScreen = _keep(InfoScreen.new()) as InfoScreen
	for node: Node in plain.find_children("*", "InfoArt", true, false):
		assert_eq((node as InfoArt).captions.size(), 0)
	var content: InfoContent = InfoContent.from_game(Fx.BattleFixtures.game())
	var named: InfoScreen = _keep(InfoScreen.new({}, {&"sling_post": "Test Name"}, content)) as InfoScreen
	var found: bool = false
	for node: Node in named.find_children("*", "InfoArt", true, false):
		var art: InfoArt = node as InfoArt
		if art.kind == &"towers":
			found = art.captions.size() == content.towers.size() and art.captions[0] == "Test Name"
	assert_true(found)


func test_info_has_short_sections_in_order_with_pictures() -> void:
	var info: InfoScreen = _keep(InfoScreen.new()) as InfoScreen
	assert_true(info.find_children("*", "InfoArt", true, false).size() >= 7, "the guide shows real examples")
	var texts: PackedStringArray = _texts(info)
	assert_true(texts.find("The goal") < texts.find("Gold"))
	assert_true(texts.find("Gold") < texts.find("Gates"))
	assert_true(texts.find("Gates") < texts.find("Stars"))
	for text: String in texts:
		assert_false(text.contains("—") or text.contains("--"), "no em dashes or double hyphens")


# Settings, Pause, the mode screen.

func test_settings_toggles_sound_and_has_an_about_row() -> void:
	var panel: SettingsPanel = _keep(SettingsPanel.new(true)) as SettingsPanel
	var seen: Array[bool] = []
	panel.sound_changed.connect(func(on: bool) -> void: seen.append(on))
	assert_eq(panel.sound_button.text, "Sound effects: On")
	panel.sound_button.tapped.emit()
	assert_eq(panel.sound_button.text, "Sound effects: Off")
	panel.sound_button.tapped.emit()
	assert_eq(seen, [false, true] as Array[bool])
	var rows: Array[String] = []
	for node: Node in panel.find_children("*", "TapButton", true, false):
		rows.append((node as TapButton).text)
	assert_true(rows.has("About"))
	assert_false(rows.has("Resume"))


func test_settings_starts_with_the_given_sound_state() -> void:
	var panel: SettingsPanel = _keep(SettingsPanel.new(false)) as SettingsPanel
	assert_eq(panel.sound_button.text, "Sound effects: Off")


func test_pause_has_its_rows_and_a_quiet_coffee_row_last() -> void:
	var panel: PausePanel = _keep(PausePanel.new()) as PausePanel
	var texts: Array[String] = []
	var last: Node = null
	for child: Node in panel.body.get_children():
		last = child
		var button: Button = child as Button
		if button != null:
			texts.append(button.text)
		for inner: Node in child.get_children() if child is HBoxContainer else []:
			texts.append((inner as Button).text)
	assert_eq(texts, ["Resume", "Info", "Settings", "Back to menu", "Restart", "Abandon", "Buy me a coffee"] as Array[String])
	assert_true(last is CoffeeButton)


func _pause_button(panel: Control, label: String) -> TapButton:
	for node: Node in panel.find_children("*", "TapButton", true, false):
		if (node as TapButton).text == label:
			return node as TapButton
	return null


func test_pause_abandon_asks_first_and_back_cancels_the_question() -> void:
	var panel: PausePanel = _keep(PausePanel.new()) as PausePanel
	panel.apply_layout(COVER, COVER_SAFE)
	var events: Array[String] = []
	panel.abandon_confirmed.connect(func() -> void: events.append("abandon"))
	panel.resume_requested.connect(func() -> void: events.append("resume"))
	_pause_button(panel, "Abandon").tapped.emit()
	assert_true(panel.confirm_open())
	assert_eq(events.size(), 0, "nothing ends before the answer")
	panel.request_close()
	assert_false(panel.confirm_open(), "back cancels the question first")
	assert_eq(events.size(), 0)
	_pause_button(panel, "Abandon").tapped.emit()
	var confirm: ConfirmDialog = panel.get_child(panel.get_child_count() - 1) as ConfirmDialog
	assert_not_null(confirm)
	_pause_button(confirm, "Abandon").tapped.emit()
	assert_eq(events, ["abandon"] as Array[String])


func test_pause_buttons_send_their_signals_and_back_resumes() -> void:
	var panel: PausePanel = _keep(PausePanel.new()) as PausePanel
	var events: Array[String] = []
	panel.resume_requested.connect(func() -> void: events.append("resume"))
	panel.info_requested.connect(func() -> void: events.append("info"))
	panel.settings_requested.connect(func() -> void: events.append("settings"))
	panel.leave_requested.connect(func() -> void: events.append("leave"))
	_pause_button(panel, "Info").tapped.emit()
	_pause_button(panel, "Settings").tapped.emit()
	_pause_button(panel, "Back to menu").tapped.emit()
	panel.request_close()
	assert_eq(events, ["info", "settings", "leave", "resume"] as Array[String])


func test_mode_screen_locks_roguelite_and_daily_with_the_star_count() -> void:
	var screen: ModeScreen = _keep(ModeScreen.new()) as ModeScreen
	screen.set_runs(false, 3, 12)
	assert_true(screen.roguelite_button.disabled)
	assert_true(screen.daily_button.disabled)
	assert_true(" ".join(_texts(screen)).contains("Needs 12 stars, you have 3"))
	assert_null(screen.continue_button, "no Continue card without a saved game")
	screen.set_continue("Continue", "Pick up where you left off.")
	assert_not_null(screen.continue_button)
	assert_eq(screen.continue_button.get_parent(), screen.column.get_child(0), "the Continue card is on top")
	screen.set_continue("", "")
	assert_null(screen.continue_button)
	screen.set_runs(true, 12, 12)
	assert_false(screen.roguelite_button.disabled)
	assert_false(screen.daily_button.disabled)


func test_mode_screen_buttons_send_their_signals() -> void:
	var screen: ModeScreen = _keep(ModeScreen.new()) as ModeScreen
	screen.set_runs(true, 12, 12)
	screen.set_continue("Continue", "x")
	var seen: Array[String] = []
	screen.campaign_pressed.connect(func() -> void: seen.append("campaign"))
	screen.roguelite_pressed.connect(func() -> void: seen.append("roguelite"))
	screen.daily_pressed.connect(func() -> void: seen.append("daily"))
	screen.continue_pressed.connect(func() -> void: seen.append("continue"))
	screen.campaign_button.tapped.emit()
	screen.roguelite_button.tapped.emit()
	screen.daily_button.tapped.emit()
	screen.continue_button.tapped.emit()
	assert_eq(seen, ["campaign", "roguelite", "daily", "continue"] as Array[String])


# The App.

func test_app_boots_to_the_front_door() -> void:
	var a: App = _app()
	assert_eq(a.screen_count(), 1)
	assert_true(a.current_screen() is FrontDoor)
	assert_eq(a.modal_count(), 0)
	assert_false(a.front_door().play_button.disabled)


func test_app_front_door_buttons_open_their_screens() -> void:
	var a: App = _app()
	a.front_door().play_pressed.emit()
	assert_true(a.current_screen() is ModeScreen)
	a.handle_back()
	a.front_door().info_pressed.emit()
	assert_true(a.current_screen() is InfoScreen)
	a.handle_back()
	a.front_door().about_pressed.emit()
	assert_true(a.current_screen() is AboutScreen)
	a.handle_back()
	a.front_door().settings_pressed.emit()
	assert_eq(a.modal_count(), 1)
	assert_eq(a.screen_count(), 1, "Settings is a panel, not a screen")


func test_app_front_door_changes_nothing() -> void:
	var a: App = _app()
	a.sound_on = true
	a.front_door().info_pressed.emit()
	a.handle_back()
	a.front_door().about_pressed.emit()
	a.handle_back()
	assert_true(a.sound_on)
	assert_eq(a.screen_count(), 1)


func test_app_back_button_order() -> void:
	var a: App = _app()
	assert_eq(a.handle_back(), &"quit", "on the front door back quits")
	a.open_mode()
	a.open_about()
	a.open_settings()
	assert_eq(a.modal_count(), 1)
	assert_eq(a.handle_back(), &"modal", "a panel closes first")
	assert_eq(a.modal_count(), 0)
	assert_eq(a.handle_back(), &"page")
	assert_true(a.current_screen() is ModeScreen)
	assert_eq(a.handle_back(), &"page")
	assert_true(a.current_screen() is FrontDoor)
	assert_eq(a.handle_back(), &"quit")


func test_app_a_page_opened_from_a_panel_hides_the_panel_until_back() -> void:
	var a: App = _app()
	a.open_settings()
	var panel: Modal = a.top_modal()
	assert_not_null(panel)
	a.open_about()
	assert_false(a.modals_showing(), "the panel must not cover the page")
	assert_eq(a.handle_back(), &"page")
	assert_true(a.modals_showing(), "back returns to the panel")
	assert_eq(a.handle_back(), &"modal")
	assert_eq(a.modal_count(), 0)


func test_app_settings_sound_reaches_the_app() -> void:
	var a: App = _app()
	var seen: Array[bool] = []
	a.sound_changed.connect(func(on: bool) -> void: seen.append(on))
	a.open_settings()
	(a.top_modal() as SettingsPanel).sound_button.tapped.emit()
	assert_eq(seen, [false] as Array[bool])
	assert_false(a.sound_on)
	a.handle_back()
	a.open_settings()
	assert_eq((a.top_modal() as SettingsPanel).sound_button.text, "Sound effects: Off", "Settings shows the current state")


func test_app_settings_about_row_opens_about_and_back_returns() -> void:
	var a: App = _app()
	a.open_settings()
	(a.top_modal() as SettingsPanel).about_requested.emit()
	assert_true(a.current_screen() is AboutScreen)
	a.handle_back()
	assert_true(a.modals_showing())
	assert_true(a.current_screen() is FrontDoor)


func test_app_opens_a_license_viewer() -> void:
	var a: App = _app()
	a.open_about()
	(a.current_screen() as AboutScreen).license_buttons[LicenseText.FONT].tapped.emit()
	assert_true(a.current_screen() is LicenseViewer)
	assert_eq(a.screen_count(), 3)


func test_app_the_mode_screen_reports_the_runs_lock_and_signals() -> void:
	var a: App = _app()
	var seen: Array[String] = []
	a.campaign_requested.connect(func() -> void: seen.append("campaign"))
	a.open_mode()
	var mode: ModeScreen = a.current_screen() as ModeScreen
	assert_true(mode.roguelite_button.disabled, "locked until the progress says otherwise")
	mode.campaign_button.tapped.emit()
	assert_eq(seen, ["campaign"] as Array[String])


func test_app_lays_every_screen_out_again_on_a_new_window_shape() -> void:
	var a: App = _app()
	a.open_info()
	a.apply_layout(Vector2(1998, 2400), Rect2(0, 0, 1998, 2250))
	assert_true(a.front_door().landscape)
	assert_true(a.current_screen().landscape)
	a.apply_layout(COVER, COVER_SAFE)
	assert_false(a.front_door().landscape)
	assert_false(a.current_screen().landscape)
