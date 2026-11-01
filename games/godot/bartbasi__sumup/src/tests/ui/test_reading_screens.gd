extends "res://tests/base_test.gd"
## The reading screens on their own (DESIGN_SYSTEM.md 7.11 to 7.14): Info
## (GDD D-44, TH21, AT-115, AT-116), About (TH22, AT-141) and the license
## texts (AT-142), and the rows that open a screen.

const U := preload("res://tests/ui/ui_fixtures.gd")
const Copy := preload("res://src/ui/screen_copy.gd")
const LicenseTexts := preload("res://src/ui/license_texts.gd")
const OpenRow := preload("res://src/ui/open_row.gd")

const GDD_PATH: String = "res://docs/GDD.md"

var _hosts: Array[Control] = []
var _stages: Array[Control] = []
var _taps: int = 0
var _dir: String = ""


func before_each() -> void:
	_hosts = []
	_stages = []
	_taps = 0
	_dir = ""
	SafeArea.simulated_insets = Vector2(120.0, 66.0)


func after_each() -> void:
	for host: Control in _hosts:
		if is_instance_valid(host):
			host.get_parent().remove_child(host)
			host.free()
	for host: Control in _stages:
		U.free_stage(host)
	SafeArea.simulated_insets = Vector2(-1.0, -1.0)
	if not _dir.is_empty():
		U.remove_temp_dir(_dir)


func _host(skin_id: StringName) -> Control:
	var host: Control = Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.theme = UiKit.build_theme(SkinCatalog.get_skin(skin_id))
	U.root().add_child(host)
	_hosts.append(host)
	return host


func _info(skin_id: StringName) -> InfoPanel:
	var panel: InfoPanel = (load("res://scenes/ui/info_panel.tscn") as PackedScene).instantiate() as InfoPanel
	_host(skin_id).add_child(panel)
	panel.setup(SkinCatalog.get_skin(skin_id))
	panel.finish()
	return panel


func _about(skin_id: StringName) -> AboutPanel:
	var panel: AboutPanel = (load("res://scenes/ui/about_panel.tscn") as PackedScene).instantiate() as AboutPanel
	_host(skin_id).add_child(panel)
	panel.setup(SkinCatalog.get_skin(skin_id))
	return panel


func _count_tap() -> void:
	_taps += 1


## GDD 21.2's table rows, read from the GDD itself: [title, text, example,
## result] per row, the example as values and "none" as empty / 0.
func _gdd_sections() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var text: String = FileAccess.get_file_as_string(GDD_PATH)
	var row_name: RegEx = RegEx.create_from_string("^IN([1-9]|1[0-7])$")
	for line: String in text.split("\n"):
		var cells: PackedStringArray = line.split("|")
		# The 21.2 table: | IN1 | title | text | example | result |
		if cells.size() != 7 or row_name.search(cells[1].strip_edges()) == null:
			continue
		var example: PackedInt64Array = PackedInt64Array()
		var example_text: String = cells[4].strip_edges()
		if example_text != "none":
			for value: String in example_text.split(","):
				example.append(_exponent(int(value.strip_edges())))
		var result_text: String = cells[5].strip_edges()
		var result: int = 0
		if result_text == "2K":
			result = 11
		elif result_text != "none":
			result = _exponent(int(result_text))
		rows.append({"title": cells[2].strip_edges(), "text": cells[3].strip_edges(), "example": example, "result": result})
	return rows


## The exponent of a tile value from the GDD (2 is 1, 1024 is 10): the
## content holds exponents since ARCHITECTURE.md section 17.
static func _exponent(value: int) -> int:
	var exponent: int = 0
	while (1 << (exponent + 1)) <= value:
		exponent += 1
	return exponent


# Info: TH21 and AT-116

func test_at_116_th21_content_is_gdd_21_2_word_for_word() -> void:
	var expected: Array[Dictionary] = _gdd_sections()
	assert_eq(expected.size(), 17, "the GDD lists seventeen sections")
	var panel: InfoPanel = _info(&"gumdrop")
	var content: Array[Dictionary] = panel.content()
	assert_eq(content.size(), 17, "seventeen sections")
	var total: int = 0
	for index: int in mini(content.size(), expected.size()):
		var section: Dictionary = content[index]
		var gdd: Dictionary = expected[index]
		var tag: String = "IN%d" % (index + 1)
		assert_eq(section["title"], gdd["title"], "%s title" % tag)
		assert_eq(section["text"], gdd["text"], "%s text, word for word" % tag)
		assert_eq(section["example"], gdd["example"], "%s example row" % tag)
		assert_eq(section["result"], gdd["result"], "%s result tile" % tag)
		var words: int = String(section["title"]).split(" ", false).size()
		assert_true(words >= 1 and words <= 4, "%s title is 1 to 4 words" % tag)
		var text: String = section["text"]
		var sentences: int = text.count(". ") + 1
		assert_true(sentences >= 1 and sentences <= 3, "%s text is 1 to 3 sentences" % tag)
		assert_true(text.ends_with("."), "%s text ends a sentence" % tag)
		var text_words: int = text.split(" ", false).size()
		assert_true(text_words <= 40, "%s text is at most 40 words (%d)" % [tag, text_words])
		total += text_words
		var icon: StringName = section["icon"]
		var expected_icon: StringName = [&"hammer", &"swap", &"shuffle", &"double", &"undo"][index - 8] if index >= 8 and index <= 12 else &""
		assert_eq(icon, expected_icon, "%s booster icon" % tag)
	assert_eq(total, 502, "502 words in all, as the GDD counts")
	if content.size() == 17:
		assert_eq(content[16]["title"], "Big numbers", "IN17 is Big numbers")
	assert_eq(panel.title_text(), "Info", "the screen title")


func test_at_116_example_rows_check_out_on_the_rules_model() -> void:
	var config: GameConfig = GameConfig.new()
	var chains: int = 0
	var changes: int = 0
	for section: Dictionary in Copy.info_sections():
		var example: PackedInt64Array = section["example"]
		if example.is_empty():
			assert_eq(section["result"], 0, "no row, no result")
			assert_eq(section["row"], &"", "no row kind")
			continue
		# Laid out as touching cells along the top row of a board of 2s.
		var cells: PackedInt64Array = PackedInt64Array()
		cells.resize(config.cell_count())
		cells.fill(1)
		for index: int in example.size():
			cells[index] = example[index]
		if section["row"] == &"change":
			changes += 1
			# The IN12 row: Double on a tile of 8 (TH11) makes the result tile.
			var state: RunState = U.run(cells, 100000)
			var rng: RunRandom = RunRandom.new()
			rng.set_seed(1)
			var result: MoveResult = BoosterRules.apply(&"double", state, Records.new(), [Vector2i(0, 0)] as Array[Vector2i], rng, config)
			assert_true(result.accepted, "Double applies to the 2^%d" % example[0])
			assert_eq(state.value_at(Vector2i(0, 0)), section["result"], "2^%d doubles to its result tile" % example[0])
			continue
		chains += 1
		assert_eq(section["row"], &"chain", "%s: a chain row" % str(example))
		var chain: Array[Vector2i] = []
		for index: int in example.size():
			chain.append(Vector2i(index, 0))
		assert_true(CoreRules.is_valid_chain(cells, BigNum.zero(), chain, config), "%s: a valid chain" % str(example))
		assert_eq(CoreRules.merge_result(example), section["result"], "%s: its result is the merge result" % str(example))
	assert_eq(chains, 3, "three chain rows")
	assert_eq(changes, 1, "one change row")
	assert_eq(NumberFormat.tile_label(10), "1024", "the label 1024")
	assert_eq(NumberFormat.tile_label(11), "2K", "the label 2K")


func test_content_is_a_copy() -> void:
	var panel: InfoPanel = _info(&"slate")
	var content: Array[Dictionary] = panel.content()
	content[0]["title"] = "Changed"
	assert_eq(panel.content()[0]["title"], "Make a chain", "changing the copy changes nothing")


# Info: AT-115 (the UI half)

func test_at_115_rows_are_real_tiles_in_each_skin() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var panel: InfoPanel = _info(skin_id)
		var rows: Array[HBoxContainer] = panel.example_rows()
		assert_eq(rows.size(), 4, "%s: four example rows" % skin_id)
		var expected: Array[PackedInt64Array] = [PackedInt64Array([1, 1, 2]), PackedInt64Array([1, 1, 1]), PackedInt64Array([10, 10])]
		for index: int in rows.size():
			var row: HBoxContainer = rows[index]
			var arrow: SkinIcon = row.get_node("Arrow") as SkinIcon
			assert_not_null(arrow, "%s row %d: the arrow" % [skin_id, index])
			assert_eq(arrow.custom_minimum_size, Vector2(56.0, 56.0), "%s: a 56 px arrow" % skin_id)
			var result: SkinTileView = row.get_node("Result") as SkinTileView
			assert_not_null(result, "%s row %d: the result is the skin's tile view" % [skin_id, index])
			assert_eq(result.custom_minimum_size, Vector2(112.0, 112.0), "%s: a 112 px result tile" % skin_id)
			assert_true(result.get_index() > arrow.get_index() and arrow.get_index() > 0, "%s row %d: the tiles, the arrow, then the result, set apart" % [skin_id, index])
			assert_eq(row.get_child(1).custom_minimum_size.x, skin.num(&"space_m"), "%s: space_m before the arrow" % skin_id)
			if index == 3:
				# IN12, the change row: two plain tiles, no board and no chain.
				var before: SkinTileView = row.get_child(0) as SkinTileView
				assert_not_null(before, "%s: the change row starts with a tile view" % skin_id)
				assert_eq(int(before.get(&"_value")), 3, "%s: 8" % skin_id)
				assert_eq(int(result.get(&"_value")), 4, "%s: then 16" % skin_id)
				assert_eq(row.find_children("*", "SkinBoardView", true, false).size(), 0, "%s: no board view" % skin_id)
				continue
			var board: SkinBoardView = row.get_child(0) as SkinBoardView
			assert_not_null(board, "%s row %d: the chain is the skin's own board view" % [skin_id, index])
			var script: Script = board.get_script() as Script
			assert_true(script.resource_path.contains(String(skin_id)), "%s row %d: drawn by %s's board view" % [skin_id, index, skin_id])
			assert_near(board.custom_minimum_size.y, board.preferred_height(board.custom_minimum_size.x), 0.01, "%s row %d: sized by its own height" % [skin_id, index])
			assert_eq(expected[index].size(), int(board.get(&"columns")), "%s row %d: one tile per chain value" % [skin_id, index])
			assert_eq(int(board.get(&"rows")), 1, "%s row %d: a one row board" % [skin_id, index])
		_assert_takes_no_input(panel.sections(), skin_id)


func test_spl_02_info_builds_across_frames() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var panel: InfoPanel = (load("res://scenes/ui/info_panel.tscn") as PackedScene).instantiate() as InfoPanel
		_host(skin_id).add_child(panel)
		panel.frame_budget_usec = 0
		panel.setup(SkinCatalog.get_skin(skin_id))
		assert_eq(panel.built_sections(), 0, "%s: setup builds no section in the tap's frame" % skin_id)
		assert_eq(panel.content().size(), 17, "%s: content() is whole before the build" % skin_id)
		panel.play_in()
		assert_eq(panel.modulate.a, 0.0, "%s: invisible until its first screenful" % skin_id)
		var frames: int = 0
		var view: float = 1e9
		while panel.stage() == InfoPanel.Stage.FIRST and frames < 80:
			var before: int = panel.built_parts()
			panel.step(view)
			assert_true(panel.built_parts() > before or panel.stage() != InfoPanel.Stage.FIRST, "%s: every frame moves on" % skin_id)
			frames += 1
			if frames == 1:
				assert_eq(panel.built_parts(), 1, "%s: a frame builds what its budget allows, here one part" % skin_id)
				assert_eq(panel.built_sections(), 0, "%s: so the first section is not whole yet" % skin_id)
			if frames == 6:
				view = 0.0
		assert_eq(panel.stage(), InfoPanel.Stage.FADING, "%s: the fade starts on what is built" % skin_id)
		var at_fade: int = panel.built_sections()
		assert_true(at_fade < 16, "%s: the rest is left for after the fade" % skin_id)
		panel.step(0.0)
		assert_eq(panel.built_sections(), at_fade, "%s: nothing builds during the fade" % skin_id)
		panel.fade_finished()
		while panel.stage() == InfoPanel.Stage.REST and frames < 200:
			panel.step(0.0)
			frames += 1
		assert_eq(panel.stage(), InfoPanel.Stage.DONE, "%s: then the rest builds" % skin_id)
		assert_eq(panel.built_sections(), 17, "%s: all seventeen sections" % skin_id)

		assert_true(frames > 2, "%s: over several frames (%d)" % [skin_id, frames])
		assert_eq(panel.example_rows().size(), 4, "%s: the same rows as a whole build" % skin_id)
		assert_eq(panel.section_icons().size(), 5, "%s: and icons" % skin_id)
		_assert_takes_no_input(panel.sections(), skin_id)


func test_booster_sections_lead_with_their_icon() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var panel: InfoPanel = _info(skin_id)
		var icons: Array[SkinIcon] = panel.section_icons()
		assert_eq(icons.size(), 5, "%s: five booster icons" % skin_id)
		var names: Array[StringName] = [&"hammer", &"swap", &"shuffle", &"double", &"undo"]
		for index: int in icons.size():
			var icon: SkinIcon = icons[index]
			assert_eq(icon.custom_minimum_size, Vector2(skin.num(&"icon_hud"), skin.num(&"icon_hud")), "%s: an icon_hud box" % skin_id)
			assert_eq(icon.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s: it takes no input" % skin_id)
			var columns: HBoxContainer = icon.get_parent().get_parent() as HBoxContainer
			assert_eq(columns.get_theme_constant(&"separation"), roundi(skin.num(&"space_s")), "%s: space_s to the text" % skin_id)
			var heading: Label = columns.find_children("*", "Label", true, false)[0] as Label
			assert_eq(heading.text, skin.cased(&"heading", String(names[index]).capitalize()), "%s: %s's icon by its section" % [skin_id, names[index]])
			assert_eq(icon.get(&"_icon"), names[index], "%s: %s's own icon" % [skin_id, names[index]])
		# IN12 holds both its icon and its change row, in the right column.
		var double_row: HBoxContainer = panel.example_rows()[3]
		assert_true(icons[3].get_parent().get_parent().is_ancestor_of(double_row), "%s: the Double row sits in its section's columns" % skin_id)
		assert_false(icons[3].get_parent().is_ancestor_of(double_row), "%s: in the text column, not under the icon" % skin_id)


func _assert_takes_no_input(node: Node, label: String) -> void:
	for child: Node in node.find_children("*", "Control", true, false):
		if child is OpenRow:
			assert_eq((child as Control).mouse_filter, Control.MOUSE_FILTER_PASS, "%s: rows pass drags on" % label)
		elif not (child.get_parent() is OpenRow) and not _inside_row(child):
			assert_eq((child as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s: %s ignores the mouse" % [label, child.name])


func _inside_row(node: Node) -> bool:
	var parent: Node = node.get_parent()
	while parent != null:
		if parent is OpenRow:
			return true
		parent = parent.get_parent()
	return false


func test_reading_screen_frame() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var panel: InfoPanel = _info(skin_id)
		var scroll: ScrollContainer = panel.scroll()
		assert_eq(scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, "%s: vertical only" % skin_id)
		assert_eq(scroll.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_RESERVE, "%s: the indicator's room is kept" % skin_id)
		assert_eq(scroll.scroll_deadzone, 24, "%s: the 24 px deadzone" % skin_id)
		assert_false(scroll.follow_focus, "%s: no follow focus" % skin_id)
		assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_STOP, "%s: opaque to touch" % skin_id)
		var header: HBoxContainer = panel.find_child("Header", true, false) as HBoxContainer
		assert_eq(header.custom_minimum_size.y, skin.num(&"touch_min"), "%s: the header is touch_min tall" % skin_id)
		var hairlines: int = panel.find_child("Page", true, false).get_child(1).find_children("*", "HSeparator", true, false).size()
		assert_eq(hairlines > 0, skin_id == &"slate", "%s: a hairline under the header only in Slate" % skin_id)
		var sections: VBoxContainer = panel.sections()
		var expected_gap: int = 0 if skin_id == &"slate" else roundi(skin.num(&"space_l") if skin_id == &"nova" else skin.num(&"space_s"))
		assert_eq(sections.get_theme_constant(&"separation"), expected_gap, "%s: the section gap" % skin_id)
		for label: Node in panel.find_children("*", "Label", true, false):
			var made: Label = label as Label
			assert_eq(made.custom_minimum_size.x, 0.0, "%s: %s sets no minimum width" % [skin_id, made.name])
			if made.get_parent().get_parent() is PanelContainer and made.theme_type_variation in [&"HeadingLabel", &"ReadingLabel"]:
				assert_eq(made.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "%s: %s wraps" % [skin_id, made.name])
	var slate: InfoPanel = _info(&"slate")
	var heading: Label = slate.sections().find_children("*", "Label", true, false)[0] as Label
	assert_eq(heading.text, SkinCatalog.get_skin(&"slate").cased(&"heading", "Make a chain"), "headings take the heading role's case")


## A reading screen on a stage of size_px, laid out.
func _staged(scene: String, skin_id: StringName, size_px: Vector2i) -> Control:
	var host: Control = U.stage(size_px, skin_id)
	_stages.append(host)
	var panel: Control = (load(scene) as PackedScene).instantiate() as Control
	host.add_child(panel)
	U.fit(panel, Vector2(size_px))
	var skin: SkinData = SkinCatalog.get_skin(skin_id)
	panel.call(&"setup", skin)
	if panel is InfoPanel:
		(panel as InfoPanel).finish()
	var safe: Rect2 = U.safe_rect(size_px)
	panel.call(&"layout_in", Rect2(Vector2.ZERO, Vector2(size_px)), safe, SafeArea.column_in(safe, skin))
	return panel


func test_reading_screen_fits_the_content_column() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for size_px: Vector2i in [Vector2i(1080, 2400), Vector2i(1998, 2400)]:
			var panel: InfoPanel = _staged("res://scenes/ui/info_panel.tscn", skin_id, size_px) as InfoPanel
			var page: Control = panel.find_child("Page", true, false) as Control
			var column: Rect2 = SafeArea.column_in(U.safe_rect(size_px), skin)
			var label: String = "%s %s" % [skin_id, size_px]
			assert_eq(page.position.y, 120.0, "%s: the header starts at the safe area's top" % label)
			assert_eq(page.position.y + page.size.y, float(size_px.y), "%s: the page runs to the screen's bottom edge" % label)
			assert_eq(page.position.x, column.position.x, "%s: in the content column" % label)
			assert_eq(page.size.x, column.size.x, "%s: as wide as it" % label)
			if size_px.x == 1080:
				assert_eq(page.size.x, 1080.0, "%s: a phone's column is the whole width" % label)
			else:
				assert_true(page.size.x < float(size_px.x), "%s: a wide screen gets a centered column" % label)
				assert_near(page.position.x * 2.0 + page.size.x, float(size_px.x), 0.01, "%s: centered" % label)
			var pad: MarginContainer = panel.find_child("Pad", true, false) as MarginContainer
			assert_eq(pad.get_theme_constant(&"margin_bottom"), roundi(skin.num(&"space_xl") + 66.0), "%s: the end clears the gesture bar" % label)
	var gumdrop: InfoPanel = _info(&"gumdrop")
	var pad_left: MarginContainer = gumdrop.find_child("Pad", true, false) as MarginContainer
	var skin_g: SkinData = SkinCatalog.get_skin(&"gumdrop")
	assert_eq(pad_left.get_theme_constant(&"margin_left"), roundi(skin_g.num(&"board_margin")), "board_margin on the left")
	assert_eq(pad_left.get_theme_constant(&"margin_right"), 0, "the indicator fills the right margin")
	assert_eq(pad_left.get_theme_constant(&"margin_top"), roundi(skin_g.num(&"space_s")), "space_s on top")


func test_close_button_reports_and_close_stops_input() -> void:
	var panel: InfoPanel = _info(&"nova")
	panel.closed.connect(_count_tap)
	panel.close_button().pressed.emit()
	assert_eq(_taps, 1, "the close control reports")
	panel.close()
	assert_true(panel.is_closing(), "closing")
	panel.close_button().pressed.emit()
	assert_eq(_taps, 1, "a closing screen takes no input")
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_IGNORE, "and lets touches through while it fades")


# About: TH22 and AT-141

func test_at_141_about_shows_what_it_is_and_who_made_it() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var panel: AboutPanel = _about(skin_id)
		var info: String = panel.info_text()
		assert_true(info.contains("Copyright 2026 Play, Inc."), "%s: the exact attribution" % skin_id)
		assert_true(info.begins_with("SumUp"), "%s: the game's name first" % skin_id)
		assert_true(info.contains("Made by Bart Basi"), "%s: who made it" % skin_id)
		assert_true(info.contains("works fully offline") and info.contains("collects no data"), "%s: offline and no data" % skin_id)
		var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
		assert_false(version.is_empty(), "the project sets a version")
		assert_true(Copy.version_line().ends_with(version), "the Settings line shows it")
		assert_true(info.to_lower().contains("version %s" % version), "%s: About shows the same version" % skin_id)
		var copyright: Label = panel.copyright_label()
		assert_eq(copyright.text, "Copyright 2026 Play, Inc.", "%s: never cased" % skin_id)
		assert_eq(copyright.theme_type_variation, &"BodyLabel", "%s: in the body role, never muted" % skin_id)
		assert_eq(copyright.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING, "%s: never truncated" % skin_id)
		assert_false(copyright.has_theme_font_size_override(&"font_size"), "%s: never shrunk" % skin_id)
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var width: float = skin.font(&"body").get_string_size(copyright.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, skin.font_size(&"body")).x
		assert_true(width <= 1080.0 - 2.0 * skin.num(&"board_margin") - 2.0 * skin.num(&"space_m"), "%s: the attribution fits one line on a 1080 px canvas (%d px)" % [skin_id, roundi(width)])


func test_at_141_attribution_is_in_the_first_screenful() -> void:
	# Headless tests cannot lay containers out, so this adds up the line
	# heights above the attribution's last line: the safe top, the header, the
	# page's top padding, a section's top padding, the wordmark, the version,
	# space_m, "Made by Bart Basi" and the attribution itself. On a 16:9 phone
	# (the shortest screen, 2400 px tall like every canvas) that must end well
	# inside the scroll area (DESIGN_SYSTEM.md 7.13: about 700 px down).
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var panel: AboutPanel = _about(skin_id)
		var brand: Control = panel.find_child("Brand", true, false) as Control
		assert_eq(brand.get_parent(), panel.sections(), "%s: the brand block is the first thing in the scroll area" % skin_id)
		assert_eq(brand.get_index(), 0, "%s: first" % skin_id)
		var lines: Array[Label] = []
		for label: Node in brand.find_children("*", "Label", true, false):
			lines.append(label as Label)
		assert_eq(lines[lines.size() - 2], panel.copyright_label(), "%s: the attribution, then only the source line" % skin_id)
		assert_eq(lines.back(), panel.source_label(), "%s: the source line ends the brand block" % skin_id)
		var mark: Control = brand.find_child("Wordmark", true, false) as Control
		var bottom: float = 120.0 + skin.num(&"touch_min") + skin.num(&"space_s") * 2.0 + skin.num(&"space_m") * 2.0
		bottom += mark.get_combined_minimum_size().y + skin.num(&"space_xs")
		for label: Label in lines:
			if label == panel.source_label():
				break
			var role: StringName = &"label" if label.theme_type_variation == &"CaptionLabel" else &"body"
			bottom += skin.font(role).get_height(skin.font_size(role)) + skin.num(&"space_xs")
		assert_true(bottom < 1000.0, "%s: the attribution ends about %d px down, in the first screenful" % [skin_id, roundi(bottom)])
		assert_true(bottom < 2400.0 - 66.0 - 400.0, "%s: well inside the scroll area" % skin_id)


func test_about_source_code_line() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var panel: AboutPanel = _about(skin_id)
		var source: Label = panel.source_label()
		assert_eq(source.text, "Source code: github.com/bartbasi/sumup", "%s: exactly, never cased" % skin_id)
		assert_eq(source.theme_type_variation, &"MutedLabel", "%s: body role, ink_muted" % skin_id)
		assert_eq(source.autowrap_mode, TextServer.AUTOWRAP_OFF, "%s: never broken inside the address" % skin_id)
		assert_eq(source.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s: plain text, not a link" % skin_id)
		var width: float = skin.font(&"body").get_string_size(source.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, skin.font_size(&"body")).x
		assert_true(width <= 1080.0 - 2.0 * skin.num(&"board_margin") - 2.0 * skin.num(&"space_m"), "%s: it fits one line on a 1080 px canvas (%d px)" % [skin_id, roundi(width)])
		assert_true(panel.info_text().contains("Copyright 2026 Play, Inc.
Source code: github.com/bartbasi/sumup"), "%s: right under the attribution (TH22)" % skin_id)


func test_about_wordmark_and_rows() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var about: AboutPanel = _about(skin_id)
		var mark: SkinWordmark = about.find_child("Wordmark", true, false) as SkinWordmark
		assert_not_null(mark, "%s: the drawn wordmark" % skin_id)
		assert_true((mark.get_script() as Script).resource_path.contains(String(skin_id)), "%s: in the skin's own look" % skin_id)
		assert_eq(int(mark.get(&"_px")), SkinCatalog.get_skin(skin_id).font_size(&"display"), "%s: at the display size, not fitted" % skin_id)
		assert_false(bool(mark.get(&"_masthead")), "%s: no masthead rule on About" % skin_id)
	var nova: AboutPanel = _about(&"nova")
	var skin: SkinData = SkinCatalog.get_skin(&"nova")
	var rows: Dictionary[StringName, Control] = nova.license_rows()
	assert_eq(rows.keys(), [&"game", &"godot", &"outfit"], "three license rows in order")
	assert_eq(rows[&"godot"].call(&"detail_text"), "MIT license and its parts", "Nova keeps the names' capitals")
	var slate: AboutPanel = _about(&"slate")
	assert_eq(slate.license_rows()[&"game"].call(&"detail_text"), "GNU GPL VERSION 3, ADDED TERMS", "Slate capitals may apply")
	for id: StringName in rows:
		var row: Control = rows[id]
		assert_true(row.custom_minimum_size.y >= skin.num(&"touch_min"), "%s: at least touch_min tall" % id)


# License texts: AT-142

func test_at_142_game_license_matches_its_sources() -> void:
	var panel: AboutPanel = _about(&"gumdrop")
	var notice: String = FileAccess.get_file_as_string("res://NOTICE")
	var copying: String = FileAccess.get_file_as_string("res://COPYING")
	assert_true(notice.length() > 100 and copying.length() > 30000, "both files are there")
	var expected: String = "Notice\n" + notice + "\nGNU General Public License\n" + copying
	assert_eq(LicenseTexts.squeeze(panel.license_text(&"game")), LicenseTexts.squeeze(expected), "NOTICE then COPYING, whitespace normalized")


func test_at_142_outfit_license_matches_its_source() -> void:
	var panel: AboutPanel = _about(&"gumdrop")
	var ofl: String = FileAccess.get_file_as_string("res://src/design/fonts/OFL.txt")
	assert_true(ofl.contains("SIL OPEN FONT LICENSE"), "OFL.txt is there")
	assert_eq(LicenseTexts.squeeze(panel.license_text(&"outfit")), LicenseTexts.squeeze(LicenseTexts.without_rules(ofl)), "OFL.txt, whitespace normalized, rule lines left out (AT-142)")
	var view_paragraphs: int = 0
	for block: Dictionary in LicenseTexts.blocks(&"outfit"):
		if int(block["kind"]) == LicenseTexts.Kind.PARAGRAPH:
			view_paragraphs += 1
	assert_eq(view_paragraphs, LicenseTexts.reflow(ofl).size(), "the same number of paragraphs as the source")


func test_at_142_godot_license_matches_the_engine() -> void:
	var panel: AboutPanel = _about(&"slate")
	var skin: SkinData = SkinCatalog.get_skin(&"slate")
	var parts: PackedStringArray = PackedStringArray([skin.cased(&"heading", "Godot Engine license"), Engine.get_license_text(), skin.cased(&"heading", "Third party parts")])
	var components: int = 0
	for component: Dictionary in Engine.get_copyright_info():
		components += 1
		parts.append(String(component["name"]))
		for part: Dictionary in component["parts"]:
			for line: String in part["copyright"]:
				parts.append("Copyright " + line)
			parts.append("License: " + String(part["license"]))
	parts.append(skin.cased(&"heading", "Android libraries"))
	parts.append("The Android version of SumUp also includes these libraries, which the Godot Engine's Android build adds.")
	for library: Array in [["AndroidX libraries", "The Android Open Source Project", "Apache-2.0"], ["Kotlin standard library", "JetBrains s.r.o. and Kotlin Programming Language contributors", "Apache-2.0"], ["kotlinx.coroutines", "JetBrains s.r.o. and contributors", "Apache-2.0"], ["JetBrains Java Annotations", "JetBrains s.r.o.", "Apache-2.0"], ["LLVM libc++", "The LLVM Project contributors", "Apache-2.0 WITH LLVM-exception"]]:
		parts.append(String(library[0]))
		parts.append("Copyright " + String(library[1]))
		parts.append("License: " + String(library[2]))
	parts.append(skin.cased(&"heading", "License texts"))
	var licenses: Dictionary = Engine.get_license_info()
	for license_name: String in licenses:
		parts.append(license_name)
		parts.append(String(licenses[license_name]))
	assert_true(components > 10 and licenses.size() > 5, "the engine lists its parts and licenses")
	var shown: String = panel.license_text(&"godot")
	assert_eq(LicenseTexts.squeeze(shown), LicenseTexts.squeeze(LicenseTexts.without_rules("
".join(parts))), "every part and license text, whitespace normalized, rule lines left out")
	assert_true(shown.contains("GODOT ENGINE LICENSE"), "Slate's headings in capitals")


func test_reflow_rules() -> void:
	var text: String = "Line one\nstill one  with   spaces.\n\n  Two\r\n\r\nThree\n   \nFour\n"
	assert_eq(LicenseTexts.reflow(text), PackedStringArray(["Line one still one with spaces.", "Two", "Three", "Four"]), "blank lines split, every other break and run of spaces is one space")
	assert_eq(LicenseTexts.squeeze("  a\t\nb  "), "a b", "squeeze")


func test_a_damaged_license_file_shows_a_plain_message() -> void:
	_dir = U.make_temp_dir()
	var wrong: String = _dir.path_join("COPYING")
	U.SaveFixtures.write_text(wrong, "x".repeat(35149))
	assert_eq(LicenseTexts.read_checked(wrong, "GNU GENERAL PUBLIC LICENSE", "Version 3"), "", "the right length with the wrong contents is refused")
	var with_nul: PackedByteArray = "GNU GENERAL PUBLIC LICENSE Version 3".to_utf8_buffer()
	with_nul.append(0)
	U.SaveFixtures.write_bytes(_dir.path_join("with_zero.txt"), with_nul)
	assert_eq(LicenseTexts.read_checked(_dir.path_join("with_zero.txt"), "GNU GENERAL PUBLIC LICENSE", "Version 3"), "", "a NUL byte is refused")
	assert_eq(LicenseTexts.read_checked(_dir.path_join("missing"), "", ""), "", "a missing file gives nothing")
	U.SaveFixtures.write_text(_dir.path_join("good"), "  GNU GENERAL PUBLIC LICENSE\n Version 3, 29 June 2007")
	assert_ne(LicenseTexts.read_checked(_dir.path_join("good"), "GNU GENERAL PUBLIC LICENSE", "Version 3"), "", "the right text reads")
	for path: String in [LicenseTexts.NOTICE_PATH, LicenseTexts.COPYING_PATH, LicenseTexts.OFL_PATH]:
		assert_ne(LicenseTexts.read_license_file(path), "", "%s reads and looks like itself" % path)
	assert_false(Copy.TEXT_MISSING.contains("--"), "the message is plain")


func test_license_view_opens_inside_about_one_label_per_paragraph() -> void:
	var panel: AboutPanel = _about(&"gumdrop")
	panel.license_rows()[&"outfit"].emit_signal(&"tapped")
	var view: Control = panel.license_view()
	assert_not_null(view, "the row opens the text")
	assert_eq(view.get_parent(), panel, "inside About")
	assert_eq(view.call(&"title_text"), "Outfit font", "titled")
	view.call(&"finish")
	assert_true(view.call(&"is_built"), "built")
	var paragraphs: int = LicenseTexts.reflow(FileAccess.get_file_as_string("res://src/design/fonts/OFL.txt")).size()
	assert_eq(int(view.call(&"label_count")), paragraphs, "one label per paragraph")
	assert_eq(view.call(&"shown_text"), panel.license_text(&"outfit"), "what it shows is the license text")
	assert_true(panel.close_license(), "closing the text")
	assert_null(panel.license_view(), "it is gone")
	assert_false(panel.close_license(), "a second close finds none")


func test_godot_license_view_builds_in_batches() -> void:
	var panel: AboutPanel = _about(&"nova")
	panel.open_license(&"godot")
	var view: Control = panel.license_view()
	assert_eq(view.call(&"title_text"), "Godot Engine", "the header at once")
	assert_false(view.call(&"is_built"), "the paragraphs follow frame by frame, never all in the opening frame")
	view.call(&"finish")
	assert_true(view.call(&"is_built"), "then complete")
	var rules: int = 0
	for block: Dictionary in LicenseTexts.blocks(&"godot"):
		if int(block["kind"]) == LicenseTexts.Kind.RULE:
			rules += 1
	assert_eq(rules, 37, "Godot's license texts hold 37 rule lines (DESIGN_SYSTEM.md 7.14)")
	assert_eq(int(view.call(&"label_count")), LicenseTexts.blocks(&"godot").size() - rules, "one label per block that is not a rule")
	assert_eq(int(view.call(&"rule_count")), rules, "one divider per rule line")


# Rows that open a screen (7.11)

func _press(row: Control, at: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.global_position = at
	event.position = at
	row._gui_input(event)


func _move(row: Control, at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.global_position = at
	event.position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	row._gui_input(event)


func test_a_row_opens_only_on_a_tap() -> void:
	var panel: AboutPanel = _about(&"gumdrop")
	var row: Control = panel.license_rows()[&"game"]
	row.connect(&"tapped", _count_tap)
	_press(row, Vector2(100, 100), true)
	assert_true(row.call(&"is_held"), "pressed look while held")
	_press(row, Vector2(110, 108), false)
	assert_eq(_taps, 1, "down and up within the deadzone: a tap")
	assert_false(row.call(&"is_held"), "released")

	_press(row, Vector2(100, 100), true)
	_move(row, Vector2(100, 140))
	assert_false(row.call(&"is_held"), "a drag past 24 px cancels the press")
	_press(row, Vector2(100, 101), false)
	assert_eq(_taps, 1, "a drag that starts on a row never opens it")

	_press(row, Vector2(100, 100), true)
	panel.scroll().scroll_vertical = 30
	_press(row, Vector2(100, 100), false)
	assert_eq(_taps, 1, "a scroll in between: no tap")

	_press(row, Vector2(100, 100), false)
	assert_eq(_taps, 1, "a release without a press does nothing")
	assert_eq(row.mouse_filter, Control.MOUSE_FILTER_PASS, "it passes events on to the scroll area")


func test_a_row_ignores_other_buttons() -> void:
	var panel: AboutPanel = _about(&"slate")
	var row: Control = panel.license_rows()[&"godot"]
	row.connect(&"tapped", _count_tap)
	var right: InputEventMouseButton = InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	row._gui_input(right)
	right.pressed = false
	row._gui_input(right)
	assert_eq(_taps, 0, "only the left button or a touch")


func test_rule_lines_become_dividers() -> void:
	var text: String = "Copyright 2021 X\n\n----------------------------------------\nSIL OPEN FONT LICENSE Version 1.1 - 26 February 2007\n----------------------------------------\n\nIntroduction\n============\nSome text\n*  6. Disclaimer of Warranty  *\n  * * *  \n-- x\n"
	var parts: PackedStringArray = LicenseTexts.reflow_parts(text)
	assert_eq(parts[0], "Copyright 2021 X", "text before")
	assert_eq(parts[1], "", "a line of dashes is a rule")
	assert_eq(parts[2], "SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007", "the OFL title stands alone between two rules")
	assert_eq(parts[3], "", "the second rule")
	assert_eq(parts[4], "Introduction", "an underlined title stands alone")
	assert_eq(parts[5], "", "over a rule of equals signs")
	assert_eq(parts[6], "Some text * 6. Disclaimer of Warranty *", "a line with other characters stays text (the MPL box border)")
	assert_eq(parts[7], "", "spaced asterisks are a rule too")
	assert_eq(parts[8], "-- x", "two dashes and a letter stay text")
	assert_eq(parts.size(), 9, "nothing else")
	assert_true(LicenseTexts.is_rule_line("==="), "three is enough")
	assert_false(LicenseTexts.is_rule_line("--"), "two is not")
	assert_false(LicenseTexts.is_rule_line("-=-"), "one character only")
	assert_false(LicenseTexts.is_rule_line("~~~~"), "only -, = or *")
	assert_eq(LicenseTexts.reflow(text).size(), 5, "reflow leaves the rules out")
	var blocks: Array[Dictionary] = LicenseTexts.blocks(&"outfit")
	var kinds: Array[int] = []
	for block: Dictionary in blocks:
		kinds.append(int(block["kind"]))
	assert_eq(kinds.count(LicenseTexts.Kind.RULE), 2, "OFL.txt has 2 rule lines")


## A license view on the stage, with step() fed sizes of the test's own.
func _staged_view(id: StringName) -> Control:
	var panel: AboutPanel = _about(&"gumdrop")
	panel.open_license(id)
	return panel.license_view()


func test_license_view_fades_in_only_after_its_first_screenful() -> void:
	var view: Control = _staged_view(&"game")
	assert_eq(view.call(&"stage"), 0, "waiting for layout")
	assert_eq(view.modulate.a, 0.0, "invisible until the first screenful is built")
	view.call(&"step", 0.0, 2000.0)
	assert_eq(int(view.call(&"label_count")), 0, "the frame after the tap reads the text, builds nothing")
	view.call(&"step", 0.0, 2000.0)
	assert_eq(view.call(&"stage"), 0, "no width yet, no labels")
	var steps: int = 0
	while int(view.call(&"stage")) == 1 or int(view.call(&"stage")) == 0:
		view.call(&"step", 936.0, 2000.0)
		steps += 1
		assert_true(steps < 50, "the first screenful comes in a few frames")
		if steps >= 50:
			return
	assert_eq(view.call(&"stage"), 2, "the fade starts once the first screenful is built")
	var built: int = int(view.call(&"label_count"))
	assert_true(built > 0, "the first screenful is there (%d labels)" % built)
	assert_false(view.call(&"is_built"), "not the whole text")
	for i: int in 5:
		view.call(&"step", 936.0, 2000.0)
	assert_eq(int(view.call(&"label_count")), built, "nothing more is built during the fade")
	view.call(&"fade_finished")
	assert_eq(view.call(&"stage"), 3, "after the fade the rest builds")
	view.call(&"step", 936.0, 2000.0)
	assert_true(int(view.call(&"label_count")) > built, "a little each frame")
	var frames: int = 0
	while not bool(view.call(&"is_built")) and frames < 2000:
		var before: int = int(view.call(&"label_count"))
		view.call(&"step", 936.0, 2000.0)
		assert_true(int(view.call(&"label_count")) > before, "at least one block per frame")
		frames += 1
	assert_eq(view.call(&"stage"), 4, "done")
