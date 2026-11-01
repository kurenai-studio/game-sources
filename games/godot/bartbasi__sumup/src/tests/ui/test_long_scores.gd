extends "res://tests/base_test.gd"
## Long scores and big tiles on the panels (QA6-10, DESIGN_SYSTEM.md 2.6, 7.9
## and 14, GDD D-31 and D-32). Since 2026-10-21 a score shows at most 10
## digits plus a suffix: 15 characters in any real run ("9,999,999,999zz"),
## 16 near the ceiling. Every place fits a 15 character score at or above
## display_fit_min and a 16 character one by shrinking, and no panel is ever
## wider than the screen column. Record row mini tiles are 96 px and fit a 5
## character label such as "512aa". Up to 13 characters nothing changes.
##
## Headless tests never enter the scene tree, so theme lookups on nodes give
## Godot's defaults. These checks measure every text with the skin's own
## fonts and sizes and read the paddings from the skin's Theme resource.

const U := preload("res://tests/ui/ui_fixtures.gd")
const UiParts: GDScript = preload("res://src/ui/ui_parts.gd")

const PHONE: Vector2i = Vector2i(1080, 2400)
## Bart's real score of 2026-10-20 (AT-159).
const BART_SCORE: String = "9221253119629040934"
## 2^69, the tile labelled "512aa" (AT-162): the widest 5 character label kind.
const TOP_TILE: int = 69
const MINI_TILE: float = 96.0

var _stages: Array[Control] = []


func before_each() -> void:
	_stages = []


func after_each() -> void:
	for host: Control in _stages:
		U.free_stage(host)


## A score shown as "9,999,999,999zz", 15 characters: 1,753 nines, so 581
## groups of three are dropped and the suffix is zz.
static func score_15() -> BigNum:
	return BigNum.parse("9".repeat(1753), 2000)


## A score shown with 16 characters, "4,444,444,444aaa": 582 groups dropped.
static func score_16() -> BigNum:
	return BigNum.parse("4".repeat(1756), 2000)


static func bart_score() -> BigNum:
	return BigNum.parse(BART_SCORE, 20)


## The scores every place is checked with: 15 characters, Bart's 14, and 16.
static func scores() -> Array[BigNum]:
	return [score_15(), bart_score(), score_16()]


func _stage(skin_id: StringName) -> Control:
	var host: Control = U.stage(PHONE, skin_id)
	_stages.append(host)
	return host


func _column(skin: SkinData) -> Rect2:
	return SafeArea.column_in(U.safe_rect(PHONE), skin)


## The font size a label shows at: its override, else its role's size.
func _size_of(skin: SkinData, label: Label) -> int:
	if label.has_theme_font_size_override(&"font_size"):
		return label.get_theme_font_size(&"font_size")
	return skin.font_size(UiParts.role(skin, label.theme_type_variation))


## A label's text width in the skin's font for its role, at the size it shows.
func _width_of(skin: SkinData, label: Label) -> float:
	var face: Font = skin.font(UiParts.role(skin, label.theme_type_variation))
	return face.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _size_of(skin, label)).x


func _style_width(theme: Theme, item: StringName, type: StringName, fallback: StringName) -> float:
	if theme.has_stylebox(item, type):
		return theme.get_stylebox(item, type).get_minimum_size().x
	if theme.has_stylebox(item, fallback):
		return theme.get_stylebox(item, fallback).get_minimum_size().x
	return 0.0


func _button_width(skin: SkinData, theme: Theme, button: Button) -> float:
	var face: Font = skin.font(UiParts.role(skin, button.theme_type_variation))
	var text: float = face.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, skin.font_size(UiParts.role(skin, button.theme_type_variation))).x
	return text + _style_width(theme, &"normal", button.theme_type_variation, &"Button")


func _summary(final_score: BigNum, best_score: BigNum) -> RunSummary:
	var summary: RunSummary = RunSummary.new()
	summary.final_score = final_score
	summary.best_score = best_score
	summary.best_tile = TOP_TILE
	summary.run_highest = TOP_TILE
	summary.new_best_score = true
	summary.no_moves_left = true
	return summary


func _end_panel(skin_id: StringName, summary: RunSummary) -> EndPanel:
	var skin: SkinData = SkinCatalog.get_skin(skin_id)
	var host: Control = _stage(skin_id)
	var panel: EndPanel = (load("res://scenes/ui/end_panel.tscn") as PackedScene).instantiate() as EndPanel
	host.add_child(panel)
	U.fit(panel, Vector2(PHONE))
	panel.setup(skin)
	panel.show_summary(summary)
	panel.layout_in(Rect2(Vector2.ZERO, Vector2(PHONE)), _column(skin), skin_id == &"gumdrop")
	return panel


func _splash(skin_id: StringName, best_score: BigNum) -> SplashScreen:
	var skin: SkinData = SkinCatalog.get_skin(skin_id)
	var host: Control = _stage(skin_id)
	var splash: SplashScreen = (load("res://scenes/ui/splash_screen.tscn") as PackedScene).instantiate() as SplashScreen
	host.add_child(splash)
	U.fit(splash, Vector2(PHONE))
	var records: Records = Records.new()
	records.best_score = best_score
	records.best_tile = TOP_TILE
	splash.setup(skin, records)
	splash.layout_in(Rect2(Vector2.ZERO, Vector2(PHONE)), _column(skin))
	return splash


## The record rows' tile views: count of them at 96 px, each holding 2^69,
## and the label "512aa" no wider than label_fit of the side at the size the
## skin gives it.
func _check_mini_tiles(screen: Control, skin: SkinData, count: int, tag: String) -> void:
	var tiles: Array[SkinTileView] = []
	for node: Node in screen.find_children("*", "SkinTileView", true, false):
		var view: SkinTileView = node as SkinTileView
		if view.custom_minimum_size == Vector2(MINI_TILE, MINI_TILE):
			tiles.append(view)
	assert_eq(tiles.size(), count, "%s: %d mini tiles of 96 px" % [tag, count])
	for view: SkinTileView in tiles:
		assert_eq(int(view.get(&"_value")), TOP_TILE, "%s: the mini tile holds 2^69" % tag)
	var label: String = NumberFormat.tile_label(TOP_TILE)
	var px: int = skin.tile_font_size(MINI_TILE, label)
	var width: float = skin.font(&"tile").get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
	assert_true(width <= skin.num(&"label_fit") * MINI_TILE + 0.01, "%s: \"%s\" (%d px wide at %d px) fits the 96 px mini tile" % [tag, label, roundi(width), px])


func test_the_score_texts() -> void:
	assert_eq(NumberFormat.score(score_15()), "9,999,999,999zz", "15 characters")
	assert_eq(NumberFormat.score(bart_score()), "9,221,253,119B", "Bart's score")
	assert_eq(NumberFormat.score(score_16()), "4,444,444,444aaa", "16 characters")
	assert_eq(NumberFormat.tile_label(TOP_TILE), "512aa", "the 5 character label")


func test_end_panel_with_long_scores_fits_the_column() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for value: BigNum in scores():
			_check_end_panel(skin_id, value)


func _check_end_panel(skin_id: StringName, final_score: BigNum) -> void:
	var skin: SkinData = SkinCatalog.get_skin(skin_id)
	var theme: Theme = UiKit.build_theme(skin)
	var shown: String = NumberFormat.score(final_score)
	var tag: String = "%s, %s" % [skin_id, shown]
	var panel: EndPanel = _end_panel(skin_id, _summary(final_score, final_score))
	var column: Rect2 = _column(skin)
	var card: PanelContainer = panel.panel()
	var left: float = card.offset_left
	var right: float = float(PHONE.x) + card.offset_right
	assert_true(left >= column.position.x and right <= column.end.x, "%s: the panel's place is inside the column (%d to %d)" % [tag, roundi(left), roundi(right)])
	var content: float = right - left - _style_width(theme, &"panel", &"CardPanel", &"PanelContainer")
	assert_true(content > 0.0, "%s: room for content" % tag)

	var score: Label = panel.find_child("FinalScore", true, false) as Label
	assert_eq(score.text, shown, "%s: the score as NumberFormat shows it" % tag)
	assert_true(_width_of(skin, score) <= content, "%s: the score (%d px at %d px type) fits the panel's %d px" % [tag, roundi(_width_of(skin, score)), _size_of(skin, score), roundi(content)])
	var font_px: int = _size_of(skin, score)
	if shown.length() <= 15:
		assert_true(font_px >= int(skin.num(&"display_fit_min")), "%s: at or above display_fit_min (%d px)" % [tag, font_px])
	var slot: float = column.size.x - 2.0 * (skin.num(&"board_margin") + skin.num(&"space_m"))
	var expected: int = skin.score_font_size(score.text, minf(slot, content))
	var face: Font = skin.font(UiParts.role(skin, score.theme_type_variation))
	if face.get_string_size(score.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, expected).x <= content:
		assert_eq(font_px, expected, "%s: the size 2.6 gives it, shrunk only as far as it must" % tag)
	else:
		assert_true(font_px < expected, "%s: below that only when it must" % tag)

	# Every single line label fits on its own: "Run over", the captions,
	# the numbers.
	for node: Node in card.find_children("*", "Label", true, false):
		var label: Label = node as Label
		if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
			continue
		assert_true(_width_of(skin, label) <= content, "%s: \"%s\" fits the panel" % [tag, label.text])

	# The Best score row: caption, badge and number side by side.
	var gap: float = float(roundi(skin.num(&"space_s")))
	var row: HBoxContainer = panel.find_child("BestScore", true, false).get_parent() as HBoxContainer
	var caption: Label = row.get_child(0) as Label
	var badge: PanelContainer = panel.new_best_badge()
	assert_not_null(badge, "%s: the New best badge shows" % tag)
	var number: Label = panel.find_child("Number", true, false) as Label
	assert_eq(number.text, shown, "%s: the Best score shows" % tag)
	var badge_width: float = _width_of(skin, badge.get_child(0) as Label) + _style_width(theme, &"panel", &"BadgePanel", &"PanelContainer")
	var row_width: float = _width_of(skin, caption) + gap + badge_width + gap + _width_of(skin, number)
	assert_true(row_width <= content, "%s: the Best score row (%d px) fits the panel's %d px" % [tag, roundi(row_width), roundi(content)])

	# The mini tiles: Best tile and this run's highest tile, 96 px, 512aa.
	_check_mini_tiles(panel, skin, 2, tag)

	# The buttons side by side.
	var buttons: float = _button_width(skin, theme, panel.find_child("NewGame", true, false) as Button) + gap + _button_width(skin, theme, panel.find_child("Home", true, false) as Button)
	assert_true(buttons <= content, "%s: New game and Home fit" % tag)


func test_up_to_13_characters_nothing_changes() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var summary: RunSummary = _summary(BigNum.from_int(9999999999), BigNum.from_int(9999999999))
		var panel: EndPanel = _end_panel(skin_id, summary)
		var score: Label = panel.find_child("FinalScore", true, false) as Label
		assert_eq(score.text, "9,999,999,999", skin_id)
		var slot: float = _column(skin).size.x - 2.0 * (skin.num(&"board_margin") + skin.num(&"space_m"))
		assert_eq(_size_of(skin, score), skin.score_font_size(score.text, slot), "%s: the score keeps the size 2.6 gives it" % skin_id)
		var number: Label = panel.find_child("Number", true, false) as Label
		assert_false(number.has_theme_font_size_override(&"font_size"), "%s: the Best score number keeps the body size" % skin_id)


func test_15_characters_keep_the_body_size_in_record_rows() -> void:
	# DESIGN_SYSTEM.md 14.2: a 15 character Best score fits every record row
	# at the body size.
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var panel: EndPanel = _end_panel(skin_id, _summary(score_15(), score_15()))
		var number: Label = panel.find_child("Number", true, false) as Label
		assert_eq(_size_of(skin, number), skin.font_size(UiParts.role(skin, number.theme_type_variation)), "%s: the end of run Best score at the body size" % skin_id)
		var splash: SplashScreen = _splash(skin_id, score_15())
		var best: Label = splash.find_child("BestScore", true, false) as Label
		assert_eq(_size_of(skin, best), skin.font_size(UiParts.role(skin, best.theme_type_variation)), "%s: the splash Best score at the body size" % skin_id)


func test_offer_with_long_scores_fits_its_width() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for value: BigNum in scores():
			var skin: SkinData = SkinCatalog.get_skin(skin_id)
			var theme: Theme = UiKit.build_theme(skin)
			var shown: String = NumberFormat.score(value)
			var tag: String = "%s, %s" % [skin_id, shown]
			var host: Control = _stage(skin_id)
			var offer: OfferPanel = (load("res://scenes/ui/offer_panel.tscn") as PackedScene).instantiate() as OfferPanel
			host.add_child(offer)
			offer.setup(skin)
			var session: GameSession = GameSession.new()
			session.resume(U.run(U.board_d1024(), value))
			session.move_shown()
			offer.show_offer(session.booster_statuses(), value)
			var width: float = _column(skin).size.x - 2.0 * skin.num(&"board_margin")
			offer.fit_width(width)
			assert_eq(offer.score_text(), shown, "%s: the score as NumberFormat shows it" % tag)
			var variation: StringName = offer.theme_type_variation if offer.theme_type_variation != &"" else &"PanelContainer"
			var content: float = width - _style_width(theme, &"panel", variation, &"PanelContainer")
			var score: Label = offer.find_child("Score", true, false) as Label
			var top: HBoxContainer = score.get_parent().get_parent() as HBoxContainer
			var title: Label = top.get_child(0) as Label
			var row_width: float = _width_of(skin, title) + float(roundi(skin.num(&"space_s"))) + _width_of(skin, score)
			assert_true(row_width <= content, "%s: \"Out of moves\" and the score (%d px) fit the offer's %d px" % [tag, roundi(row_width), roundi(content)])
			if shown.length() <= 15:
				assert_false(score.has_theme_font_size_override(&"font_size"), "%s: at the body size" % tag)


func test_splash_best_score_fits_the_column() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for value: BigNum in scores():
			var skin: SkinData = SkinCatalog.get_skin(skin_id)
			var shown: String = NumberFormat.score(value)
			var tag: String = "%s, %s" % [skin_id, shown]
			var splash: SplashScreen = _splash(skin_id, value)
			var column: Rect2 = _column(skin)
			assert_eq(splash.best_score_text(), shown, "%s: the Best score as NumberFormat shows it" % tag)
			var number: Label = splash.find_child("BestScore", true, false) as Label
			var caption: Label = number.get_parent().get_child(0) as Label
			var row_width: float = _width_of(skin, caption) + float(roundi(skin.num(&"space_s"))) + _width_of(skin, number)
			var room: float = column.size.x - 2.0 * float(roundi(skin.num(&"board_margin")))
			assert_true(row_width <= room, "%s: the Best score row (%d px) fits the column's %d px" % [tag, roundi(row_width), roundi(room)])
			_check_mini_tiles(splash, skin, 1, tag)
