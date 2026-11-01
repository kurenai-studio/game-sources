extends "res://tests/base_test.gd"
## The 2026-10-17 copyright line and the Buy me a coffee button (GDD 15.5,
## AT-141, AT-155 to AT-157, TH22, TH24; DESIGN_SYSTEM.md 7.2, 7.10, 7.13).
## Every test swaps the hand off for a capture, so no browser ever opens and
## nothing reaches the network.

const U := preload("res://tests/ui/ui_fixtures.gd")
const Copy := preload("res://src/ui/screen_copy.gd")
const CoffeeButton := preload("res://src/ui/coffee_button.gd")

const SUPPORT_TEXT: String = "SumUp is free, with no ads and no tracking, and it always will be. If you'd like to support more games like it, you can buy me a coffee. Never expected, always appreciated."
const OFFLINE_TEXT: String = "SumUp works fully offline. It collects no data, has no ads or accounts and asks for no permissions. The Buy me a coffee button only opens a web page in your phone's browser, and the game itself sends nothing."
const PHONE: Vector2i = Vector2i(1080, 2400)
## 16:9 with a 48 dp button bar: the shortest supported safe area (7.2).
const WIDE: Vector2i = Vector2i(1350, 2400)
const WIDE_SAFE: Rect2 = Rect2(0.0, 90.0, 1350.0, 2130.0)

var _hosts: Array[Control] = []
var _dir: String = ""
var _app: App = null
var _quits: Array[int] = []
var _sent: Array[String] = []
var _answer: Error = OK


func before_each() -> void:
	_hosts = []
	_dir = ""
	_app = null
	_quits = []
	_sent = []
	_answer = OK
	CoffeeButton.opener = _capture
	SafeArea.simulated_insets = Vector2(120.0, 66.0)
	Motion.bind_tweens = false


func after_each() -> void:
	if _app != null:
		U.stop_app(_app)
	if not _dir.is_empty():
		U.remove_temp_dir(_dir)
	for host: Control in _hosts:
		U.free_stage(host)
	CoffeeButton.use_system_opener()
	SafeArea.simulated_insets = Vector2(-1.0, -1.0)
	Motion.bind_tweens = true


## TH24: records each address instead of opening a browser.
func _capture(address: String) -> Error:
	_sent.append(address)
	return _answer


func _host(skin_id: StringName, size_px: Vector2i = PHONE) -> Control:
	var host: Control = U.stage(size_px, skin_id)
	_hosts.append(host)
	return host


func _splash(skin_id: StringName, records: Records, size_px: Vector2i = PHONE) -> SplashScreen:
	var splash: SplashScreen = (load("res://scenes/ui/splash_screen.tscn") as PackedScene).instantiate() as SplashScreen
	_host(skin_id, size_px).add_child(splash)
	U.fit(splash, Vector2(size_px))
	splash.setup(SkinCatalog.get_skin(skin_id), records)
	return splash


func _about(skin_id: StringName) -> AboutPanel:
	var panel: AboutPanel = (load("res://scenes/ui/about_panel.tscn") as PackedScene).instantiate() as AboutPanel
	_host(skin_id).add_child(panel)
	U.fit(panel, Vector2(PHONE))
	panel.setup(SkinCatalog.get_skin(skin_id))
	return panel


func _start(skin_id: StringName) -> App:
	if _app != null:
		U.stop_app(_app)
	if _dir.is_empty():
		_dir = U.make_temp_dir()
	var settings: Settings = Settings.new()
	settings.set_skin_id(skin_id)
	U.save_game(_dir, U.run(U.board_p(), 5000), 6000, 6, settings)
	_app = U.start_app(_dir, _quits)
	return _app


func _press(target: Control, at: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.global_position = at
	event.position = at
	target._gui_input(event)


func _move(target: Control, at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.global_position = at
	event.position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	target._gui_input(event)


func _tap(target: Control) -> void:
	_press(target, Vector2(40.0, 40.0), true)
	_press(target, Vector2(44.0, 46.0), false)


func _coffee_nodes(node: Node) -> Array[Node]:
	return node.find_children("Coffee", "", true, false)


## The checks every Coffee button passes, wherever it is.
func _assert_button(button: Control, skin: SkinData, label: String) -> void:
	assert_not_null(button, "%s: the button is there" % label)
	if button == null:
		return
	assert_eq(String(button.name), "Coffee", "%s: named Coffee" % label)
	assert_true(button.get_script() == CoffeeButton, "%s: the one button script" % label)
	assert_false(bool(button.call(&"is_stacked")), "%s: the one line form (QA21-05)" % label)
	assert_eq((button.call(&"labels") as Array).size(), 1, "%s: one label" % label)
	var text: Label = button.call(&"label") as Label
	assert_eq(text.text, "Buy me a coffee", "%s: reads as written, never cased" % label)
	assert_eq(text.theme_type_variation, &"MutedLabel", "%s: MutedLabel" % label)
	var icon: SkinIcon = button.call(&"icon") as SkinIcon
	assert_not_null(icon, "%s: an icon" % label)
	assert_eq(icon.get(&"_icon"), &"coffee", "%s: the coffee icon" % label)
	assert_true(bool(icon.get(&"_has_override")), "%s: its color set" % label)
	assert_eq(icon.get(&"_override"), skin.color(&"ink_muted"), "%s: in ink_muted" % label)
	var side: float = float(skin.font_size(&"body"))
	assert_eq(icon.custom_minimum_size, Vector2(side, side), "%s: a square the body font size" % label)
	var line: HBoxContainer = text.get_parent() as HBoxContainer
	assert_eq(line.get_theme_constant(&"separation"), roundi(0.25 * side), "%s: a gap of 0.25 of the body size" % label)
	assert_true(button.custom_minimum_size.y >= skin.num(&"touch_min"), "%s: touch_min tall" % label)
	var touch_width: float = button.get_combined_minimum_size().x + 2.0 * skin.num(&"space_s")
	assert_true(touch_width >= skin.num(&"touch_min"), "%s: at least touch_min wide (%d px)" % [label, roundi(touch_width)])
	assert_ne(button.size_flags_horizontal & Control.SIZE_EXPAND, Control.SIZE_EXPAND, "%s: shrinks to its content" % label)
	assert_eq(button.mouse_filter, Control.MOUSE_FILTER_PASS, "%s: takes the tap, passes drags on" % label)
	for child: Node in button.find_children("*", "Control", true, false):
		assert_eq((child as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s: %s ignores the mouse" % [label, child.name])


func test_splash_has_the_coffee_button_in_every_skin() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var splash: SplashScreen = _splash(skin_id, Records.new())
		var found: Array[Node] = _coffee_nodes(splash)
		assert_eq(found.size(), 1, "%s: one Coffee control" % skin_id)
		var button: Control = splash.coffee_button()
		assert_eq(found[0], button, "%s: the one the splash reports" % skin_id)
		_assert_button(button, skin, "%s splash" % skin_id)
		var layout: Node = splash.find_child("Layout", true, false)
		var look_up: Node = splash.find_child("LookUp", true, false)
		var buttons_row: Node = look_up.get_parent().get_parent()
		assert_true(buttons_row.get_index() < button.get_parent().get_index(), "%s: after the Info and About row" % skin_id)
		assert_eq(button.get_parent().get_index(), layout.get_child_count() - 1, "%s: last, on the bottom of the safe area" % skin_id)
		var expected: int = Control.SIZE_SHRINK_BEGIN if skin_id == &"slate" else Control.SIZE_SHRINK_CENTER
		assert_eq(button.size_flags_horizontal, expected, "%s: centered (Slate: on the left edge)" % skin_id)
		assert_eq(button.modulate.a, 1.0, "%s: shows from the first frame" % skin_id)
		splash.play_entrance()
		assert_eq(button.modulate.a, 1.0, "%s: the entrance does not fade it" % skin_id)
		assert_eq(button.mouse_filter, Control.MOUSE_FILTER_PASS, "%s: and it takes input during the entrance" % skin_id)


func test_about_has_the_coffee_button_in_every_skin() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var app: App = _start(skin_id)
		app.splash_screen().about_chosen.emit()
		var from_splash: AboutPanel = app.top_panel() as AboutPanel
		_assert_about_button(from_splash, skin, "%s About from the splash" % skin_id)
		from_splash.close_button().pressed.emit()
		app.splash_screen().settings_chosen.emit()
		(app.top_panel() as SettingsPanel).about_row().emit_signal(&"tapped")
		var from_settings: AboutPanel = app.top_panel() as AboutPanel
		assert_ne(from_settings, from_splash, "%s: a fresh About" % skin_id)
		_assert_about_button(from_settings, skin, "%s About from Settings" % skin_id)


func _assert_about_button(about: AboutPanel, skin: SkinData, label: String) -> void:
	assert_not_null(about, "%s: open" % label)
	if about == null:
		return
	var found: Array[Node] = _coffee_nodes(about)
	assert_eq(found.size(), 1, "%s: one Coffee control" % label)
	var button: Control = about.coffee_button()
	_assert_button(button, skin, label)
	var column: Node = button.get_parent()
	var heading: Label = column.get_child(0) as Label
	assert_eq(heading.text, skin.cased(&"heading", "Supporting SumUp"), "%s: inside Supporting SumUp" % label)
	var text: Label = column.get_child(1) as Label
	assert_eq(text.text, SUPPORT_TEXT, "%s: Bart's text first" % label)
	assert_eq(button.get_index(), 2, "%s: the button right after the text" % label)
	assert_eq((column as VBoxContainer).get_theme_constant(&"separation"), roundi(skin.num(&"space_xs")), "%s: space_xs after the text" % label)
	assert_eq(button.size_flags_horizontal, Control.SIZE_SHRINK_BEGIN, "%s: left aligned with the text" % label)


func test_about_support_text_is_exact() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var about: AboutPanel = _about(skin_id)
		var info: String = about.info_text()
		assert_true(info.contains(SUPPORT_TEXT), "%s: Bart's sentence group exactly (TH22, AT-156)" % skin_id)
		var offline: int = info.find("\n" + skin.cased(&"heading", "Offline, no data") + "\n")
		var support: int = info.find("\n" + skin.cased(&"heading", "Supporting SumUp") + "\n")
		var licenses: int = info.find("\n" + skin.cased(&"heading", "Licenses") + "\n")
		assert_true(offline > 0 and support > offline and licenses > support, "%s: after Offline, no data and before Licenses" % skin_id)
		assert_true(info.contains(skin.cased(&"heading", "Supporting SumUp") + "\n" + SUPPORT_TEXT + "\nBuy me a coffee\n"), "%s: heading, text, then the button, in page order" % skin_id)
		if skin_id == &"slate":
			assert_true(info.contains("\nSUPPORTING SUMUP\n"), "slate: the heading in capitals")
		var labels: Array[String] = []
		for node: Node in about.find_children("*", "Label", true, false):
			labels.append((node as Label).text)
		assert_true(labels.has(SUPPORT_TEXT), "%s: shown exactly, never cased" % skin_id)


func test_offline_sentence_is_exact() -> void:
	var offline: Dictionary = {}
	for section: Dictionary in Copy.ABOUT_SECTIONS:
		if String(section["title"]) == "Offline, no data":
			offline = section
	assert_eq(String(offline.get("text", "")), OFFLINE_TEXT, "the three sentence text")
	for skin_id: StringName in SkinCatalog.IDS:
		assert_true(_about(skin_id).info_text().contains("\n" + OFFLINE_TEXT + "\n"), "%s: shown as written" % skin_id)


func test_coffee_tap_hands_off_the_constant_once() -> void:
	assert_true(Copy.COFFEE_URL.begins_with("https://buymeacoffee.com/"), "an https Buy Me a Coffee address")
	assert_true(Copy.COFFEE_URL.length() > "https://buymeacoffee.com/".length(), "with a handle after it")
	assert_eq(Copy.COFFEE_URL, "https://buymeacoffee.com/playinc", "the address Bart gave")
	for skin_id: StringName in SkinCatalog.IDS:
		_sent = []
		var splash: SplashScreen = _splash(skin_id, Records.new())
		var about: AboutPanel = _about(skin_id)
		_tap(splash.coffee_button())
		assert_eq(_sent.size(), 1, "%s: one tap on the splash, one hand off" % skin_id)
		_tap(about.coffee_button())
		assert_eq(_sent.size(), 2, "%s: one tap in About, one hand off" % skin_id)
		for index: int in 3:
			_tap(splash.coffee_button())
			_tap(about.coffee_button())
		assert_eq(_sent.size(), 8, "%s: four taps on each, four hand offs each" % skin_id)
		for address: String in _sent:
			assert_eq(address, Copy.COFFEE_URL, "%s: always the one constant, nothing added" % skin_id)


func test_coffee_tap_failure_changes_nothing() -> void:
	_answer = ERR_CANT_OPEN
	for skin_id: StringName in SkinCatalog.IDS:
		var app: App = _start(skin_id)
		var splash: SplashScreen = app.splash_screen()
		var nodes_before: int = app.find_children("*", "", true, false).size()
		_tap(splash.coffee_button())
		assert_eq(_sent.size(), 1, "%s: handed off once" % skin_id)
		assert_false(CoffeeButton.hand_off(), "%s: the failure is seen as could not open" % skin_id)
		_sent.pop_back()
		assert_true(app.open_panels().is_empty(), "%s: no dialog over the splash" % skin_id)
		assert_eq(app.splash_screen(), splash, "%s: the same splash" % skin_id)
		assert_eq(app.find_children("*", "", true, false).size(), nodes_before, "%s: no node added (no message)" % skin_id)
		splash.settings_chosen.emit()
		(app.top_panel() as SettingsPanel).about_row().emit_signal(&"tapped")
		var about: AboutPanel = app.top_panel() as AboutPanel
		var panels_before: Array[Control] = app.open_panels().duplicate()
		nodes_before = app.find_children("*", "", true, false).size()
		_tap(about.coffee_button())
		assert_eq(_sent.size(), 2, "%s: About handed off once too" % skin_id)
		assert_eq(app.open_panels(), panels_before, "%s: the open overlays as they were" % skin_id)
		assert_eq(app.top_panel(), about, "%s: About stays on top" % skin_id)
		assert_false(about.is_closing(), "%s: and open" % skin_id)
		assert_eq(app.find_children("*", "", true, false).size(), nodes_before, "%s: no node added" % skin_id)
		assert_true(_quits.is_empty(), "%s: no exit" % skin_id)
		_sent = []


func test_coffee_drag_does_not_hand_off() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var about: AboutPanel = _about(skin_id)
		var button: Control = about.coffee_button()
		_press(button, Vector2(40.0, 40.0), true)
		assert_true(button.call(&"is_held"), "%s: the pressed look while held" % skin_id)
		_move(button, Vector2(40.0, 80.0))
		_press(button, Vector2(40.0, 80.0), false)
		assert_true(_sent.is_empty(), "%s: a drag past the deadzone makes no hand off" % skin_id)
		_press(button, Vector2(40.0, 40.0), true)
		about.scroll().scroll_vertical = 30
		_press(button, Vector2(40.0, 40.0), false)
		assert_true(_sent.is_empty(), "%s: a scroll in between makes no hand off" % skin_id)
		_press(button, Vector2(40.0, 40.0), false)
		assert_true(_sent.is_empty(), "%s: a release with no press makes no hand off" % skin_id)


func test_coffee_pressed_look_and_touch_area() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var splash: SplashScreen = _splash(skin_id, Records.new())
		var button: Control = splash.coffee_button()
		# The RowButton look itself is set on entering the tree (open_row.gd),
		# which headless tests never do; the held state that picks it is
		# checked here.
		assert_false(button.call(&"is_held"), "%s: at rest" % skin_id)
		_press(button, Vector2(40.0, 40.0), true)
		assert_true(button.call(&"is_held"), "%s: held: the pressed look" % skin_id)
		_press(button, Vector2(40.0, 40.0), false)
		assert_false(button.call(&"is_held"), "%s: released" % skin_id)
		var reach: float = skin.num(&"space_s")
		U.fit(button, Vector2(388.0, skin.num(&"touch_min")))
		assert_true(button._has_point(Vector2(-reach + 1.0, 10.0)), "%s: the touch area reaches space_s left of the content" % skin_id)
		assert_true(button._has_point(Vector2(388.0 + reach - 1.0, 10.0)), "%s: and space_s right of it" % skin_id)
		assert_false(button._has_point(Vector2(-reach - 1.0, 10.0)), "%s: no further" % skin_id)
		assert_false(button._has_point(Vector2(10.0, skin.num(&"touch_min") + 1.0)), "%s: touch_min tall" % skin_id)


func test_source_line_is_still_not_a_link() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var about: AboutPanel = _about(skin_id)
		var source: Label = about.source_label()
		assert_eq(source.text, "Source code: github.com/bartbasi/sumup", "%s: plain text" % skin_id)
		assert_eq(source.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s: MOUSE_FILTER_IGNORE (BC5)" % skin_id)
		assert_true(source.get_script() == null, "%s: a plain Label" % skin_id)
		assert_true(source.get_signal_connection_list(&"gui_input").is_empty(), "%s: nothing listens for a tap on it" % skin_id)
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		source.gui_input.emit(event)
		event.pressed = false
		source.gui_input.emit(event)
		assert_true(_sent.is_empty(), "%s: a tap on it makes no hand off" % skin_id)
		for node: Node in about.find_children("*", "Label", true, false):
			assert_false((node as Label).text.contains("buymeacoffee"), "%s: the address is never shown" % skin_id)


func test_attribution_reads_play_inc() -> void:
	assert_eq(Copy.COPYRIGHT, "Copyright 2026 Play, Inc.", "the copy")
	assert_eq(Copy.MADE_BY, "Made by Bart Basi", "Made by stays")
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var about: AboutPanel = _about(skin_id)
		var label: Label = about.copyright_label()
		assert_eq(label.text, "Copyright 2026 Play, Inc.", "%s: exactly, not cased" % skin_id)
		assert_false(about.info_text().contains("Copyright 2026 Bart Basi"), "%s: the old attribution is gone" % skin_id)
		var width: float = skin.font(&"body").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, skin.font_size(&"body")).x
		assert_true(width <= 1080.0 - 2.0 * skin.num(&"board_margin") - 2.0 * skin.num(&"space_m"), "%s: one line at 1080 px (%d px)" % [skin_id, roundi(width)])


func test_coffee_button_only_where_specified() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var app: App = _start(skin_id)
		app.splash_screen().settings_chosen.emit()
		assert_true(_coffee_nodes(app.top_panel()).is_empty(), "%s: not in Settings" % skin_id)
		app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		app.splash_screen().info_chosen.emit()
		assert_true(_coffee_nodes(app.top_panel()).is_empty(), "%s: not in Info" % skin_id)
		U.stop_app(_app)
		_app = U.start_app(_dir, _quits)
		U.play(_app)
		# Since 2026-10-21 the play screen has one (shown only where 7.15 finds
		# room, test_coffee_play_screen.gd) and Pause has one (7.3).
		assert_eq(_coffee_nodes(_app.game_screen()).size(), 1, "%s: one on the play screen" % skin_id)
		_app.open_pause()
		assert_eq(_coffee_nodes(_app.top_panel()).size(), 1, "%s: one in Pause" % skin_id)
		assert_false(_app.game_screen().is_coffee_shown(), "%s: the play screen's hidden behind Pause" % skin_id)
		_app.open_settings()
		assert_true(_coffee_nodes(_app.top_panel()).is_empty(), "%s: not in Settings over Pause" % skin_id)
		var offer_session: GameSession = GameSession.new()
		offer_session.resume(U.run(U.board_d(), 100000))
		offer_session.move_shown()
		var offer: OfferPanel = (load("res://scenes/ui/offer_panel.tscn") as PackedScene).instantiate() as OfferPanel
		_host(skin_id).add_child(offer)
		offer.setup(skin)
		offer.show_offer(offer_session.booster_statuses(), offer_session.state.score)
		assert_true(_coffee_nodes(offer).is_empty(), "%s: not on the offer" % skin_id)
		var summary: RunSummary = RunSummary.new()
		summary.final_score = BigNum.from_int(1000)
		summary.best_score = BigNum.from_int(6000)
		summary.best_tile = 6
		summary.run_highest = 6
		var end: EndPanel = (load("res://scenes/ui/end_panel.tscn") as PackedScene).instantiate() as EndPanel
		_host(skin_id).add_child(end)
		end.setup(skin)
		end.show_summary(summary)
		assert_true(_coffee_nodes(end).is_empty(), "%s: not on the end of run screen" % skin_id)
		assert_true(_sent.is_empty(), "%s: nothing handed off" % skin_id)


## The heights a VBoxContainer would give the splash's layout children in a
## column height px tall: each its minimum, and the free height shared by the
## expanding spacers by their ratios. Headless tests run outside the scene
## tree, where containers do not sort, so this sorts the one column by hand.
## The brand block's slot is read by its custom minimum (set by layout_in),
## since outside the tree its combined minimum is not refreshed.
func _sorted_heights(splash: SplashScreen, height: float) -> Array[float]:
	var layout: Control = splash.find_child("Layout", true, false) as Control
	var slot: Control = splash.find_child("BrandSlot", true, false) as Control
	var heights: Array[float] = []
	var ratios: float = 0.0
	var used: float = 0.0
	for child: Node in layout.get_children():
		var control: Control = child as Control
		var own: float = control.get_combined_minimum_size().y
		if control == slot.get_parent():
			own = maxf(own, slot.custom_minimum_size.y)
		heights.append(own)
		used += own
		if control.size_flags_vertical & Control.SIZE_EXPAND:
			ratios += control.size_flags_stretch_ratio
	var free: float = maxf(0.0, height - used)
	for index: int in heights.size():
		var control: Control = layout.get_child(index) as Control
		if control.size_flags_vertical & Control.SIZE_EXPAND and ratios > 0.0:
			heights[index] += free * control.size_flags_stretch_ratio / ratios
	return heights


## The brand block's center as a share of the screen height at 1080 x 2400
## with a 120 / 66 px safe area.
func _brand_share(skin_id: StringName, records: Records) -> float:
	var splash: SplashScreen = _splash(skin_id, records)
	var column: Rect2 = SafeArea.column_in(U.safe_rect(PHONE), SkinCatalog.get_skin(skin_id))
	splash.layout_in(Rect2(Vector2.ZERO, Vector2(PHONE)), column)
	var heights: Array[float] = _sorted_heights(splash, column.size.y)
	var slot: Control = splash.find_child("BrandSlot", true, false) as Control
	var index: int = slot.get_parent().get_index()
	var top: float = column.position.y
	for before: int in index:
		top += heights[before]
	return (top + heights[index] * 0.5) / float(PHONE.y)


func test_splash_brand_stays_in_band_with_the_one_to_one_split() -> void:
	assert_eq(SplashScreen.SPLIT_ABOVE_BRAND, 1.0, "1 to 1: above")
	assert_eq(SplashScreen.SPLIT_BELOW_BRAND, 1.0, "1 to 1: below")
	var with_tile: Records = Records.new()
	with_tile.best_score = BigNum.from_int(96520)
	with_tile.best_tile = 13
	for skin_id: StringName in SkinCatalog.IDS:
		var shown: float = _brand_share(skin_id, with_tile)
		var first: float = _brand_share(skin_id, Records.new())
		print("  %s brand center: %.1f%% with a best tile, %.1f%% without" % [skin_id, shown * 100.0, first * 100.0])
		for share: float in [shown, first]:
			assert_true(share >= 0.35 and share <= 0.42, "%s: the brand center inside 35 to 42%% (%.1f%%)" % [skin_id, share * 100.0])


func test_splash_fits_the_shortest_safe_area() -> void:
	var with_tile: Records = Records.new()
	with_tile.best_score = BigNum.from_int(96520)
	with_tile.best_tile = 13
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var splash: SplashScreen = _splash(skin_id, with_tile, WIDE)
		var column: Rect2 = SafeArea.column_in(WIDE_SAFE, skin)
		splash.layout_in(Rect2(Vector2.ZERO, Vector2(WIDE)), column)
		assert_eq(splash.sum_tile_side(), 144.0, "%s: the sum row keeps 144 px on 16:9" % skin_id)
		var heights: Array[float] = _sorted_heights(splash, column.size.y)
		var total: float = 0.0
		for height: float in heights:
			total += height
		assert_near(total, column.size.y, 0.5, "%s: the content fits the safe area, spacers included" % skin_id)
		var minimum: float = 0.0
		var layout: Control = splash.find_child("Layout", true, false) as Control
		for child: Node in layout.get_children():
			if not ((child as Control).size_flags_vertical & Control.SIZE_EXPAND):
				minimum += heights[child.get_index()]
		print("  %s on 16:9: content %d of %d px" % [skin_id, roundi(minimum), roundi(column.size.y)])
		assert_true(minimum <= column.size.y, "%s: the content fits with room to spare" % skin_id)
		var coffee_row: Control = splash.coffee_button().get_parent() as Control
		assert_eq(coffee_row.get_index(), layout.get_child_count() - 1, "%s: the coffee row ends the column, on the bottom of the safe area" % skin_id)
		assert_near(heights.back(), skin.num(&"touch_min"), 0.5, "%s: touch_min tall" % skin_id)
