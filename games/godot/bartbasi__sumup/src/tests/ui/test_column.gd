extends "res://tests/base_test.gd"
## The content column (QA6-08, DESIGN_SYSTEM.md 2.8, ARCHITECTURE.md
## SafeArea.content_column): its width per skin and screen, and that the play
## screen, the dialog panels, the splash and the reading screens lay out
## inside it, also after a live resize (fold and unfold).
##
## Headless tests never enter the scene tree, so each screen is sized by hand
## and laid out through its layout_in with rects of the test's own.

const U := preload("res://tests/ui/ui_fixtures.gd")

const PHONE: Vector2i = Vector2i(1080, 2400)
const FOLD_INNER: Vector2i = Vector2i(1998, 2400)

var _stages: Array[Control] = []


func before_each() -> void:
	_stages = []


func after_each() -> void:
	for host: Control in _stages:
		U.free_stage(host)


func _stage(size_px: Vector2i, skin_id: StringName) -> Control:
	var host: Control = U.stage(size_px, skin_id)
	_stages.append(host)
	return host


func _screen(size_px: Vector2i) -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(size_px))


func _column(size_px: Vector2i, skin_id: StringName) -> Rect2:
	return SafeArea.column_in(U.safe_rect(size_px), SkinCatalog.get_skin(skin_id))


func test_qa6_08_column_width_per_skin() -> void:
	# DESIGN_SYSTEM.md 2.8 expects about 1,220 px (Gumdrop, Slate) and 1,270 px
	# (Nova) on the Fold5 inner screen, and the whole width on phones.
	# Those figures come from QA's runs, which had no insets; with the capture
	# tool's 120 and 66 px insets the board has 186 px less height, so the
	# column is about 116 px narrower.
	var expected: Dictionary[StringName, float] = {&"gumdrop": 1220.0, &"slate": 1220.0, &"nova": 1270.0}
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var phone: Rect2 = _column(PHONE, skin_id)
		assert_eq(phone, U.safe_rect(PHONE), "%s: a phone's column is the whole safe area" % skin_id)
		var no_insets: Rect2 = SafeArea.column_in(_screen(FOLD_INNER), skin)
		assert_near(no_insets.size.x, expected[skin_id], 15.0, "%s: the Fold5 inner column with no insets (measured %d px)" % [skin_id, roundi(no_insets.size.x)])
		var wide: Rect2 = _column(FOLD_INNER, skin_id)
		assert_near(wide.size.x, expected[skin_id] - 116.0, 15.0, "%s: with 120 and 66 px insets (measured %d px)" % [skin_id, roundi(wide.size.x)])
		assert_near(wide.position.x * 2.0 + wide.size.x, float(FOLD_INNER.x), 0.01, "%s: centered" % skin_id)
		assert_eq(wide.position.y, 120.0, "%s: from the safe area's top" % skin_id)
		assert_eq(wide.size.y, U.safe_rect(FOLD_INNER).size.y, "%s: to its bottom" % skin_id)
		# B fills the space between the HUD and the bar exactly.
		var board: float = wide.size.x - 2.0 * skin.num(&"board_margin")
		var space: float = wide.size.y - skin.num(&"hud_height") - skin.num(&"bar_height") - 2.0 * skin.num(&"space_s")
		var view: SkinBoardView = SkinCatalog.make_board_view(skin)
		view.setup(skin, 5, 8)
		assert_near(view.preferred_height(board), space, 0.5, "%s: the board's height fills the space between HUD and bar" % skin_id)
		view.free()


func test_column_from_a_viewport() -> void:
	assert_eq(SafeArea.content_column(null, SkinCatalog.get_skin(&"gumdrop")), Rect2(), "no viewport, no column")
	assert_eq(SafeArea.column_in(Rect2(), SkinCatalog.get_skin(&"gumdrop")), Rect2(), "an empty safe area")
	assert_eq(SafeArea.column_in(U.safe_rect(PHONE), null), U.safe_rect(PHONE), "no skin: the safe area")
	assert_eq(SafeArea.board_width_for_height(SkinCatalog.get_skin(&"nova"), 0.0), 0.0, "no height, no board")


func _game(size_px: Vector2i, skin_id: StringName, cells: PackedInt64Array) -> GameScreen:
	var host: Control = _stage(size_px, skin_id)
	var session: GameSession = GameSession.new()
	var audio: AudioService = AudioService.new()
	host.add_child(audio)
	var game: GameScreen = (load("res://scenes/ui/game_screen.tscn") as PackedScene).instantiate() as GameScreen
	host.add_child(game)
	U.fit(game, Vector2(size_px))
	game.setup(session, Settings.new(), audio, SkinCatalog.get_skin(skin_id))
	session.resume(U.run(cells, 5000))
	session.move_shown()
	return game


func _assert_play_screen_in(game: GameScreen, size_px: Vector2i, skin_id: StringName) -> void:
	var column: Rect2 = _column(size_px, skin_id)
	game.layout_in(_screen(size_px), column)
	var label: String = "%s %s" % [skin_id, size_px]
	var hud: SkinHud = game.hud()
	var bar: SkinBoosterBar = game.booster_bar()
	if hud.visible:
		assert_eq(hud.position.x, column.position.x, "%s: the HUD in the column" % label)
		assert_eq(hud.size.x, column.size.x, "%s: as wide as it" % label)
	assert_eq(bar.position.x, column.position.x, "%s: the bar in the column" % label)
	assert_eq(bar.size.x, column.size.x, "%s: as wide as it" % label)
	var board: BoardController = game.board()
	assert_near(board.position.x - column.position.x, column.end.x - (board.position.x + board.size.x), 0.01, "%s: the board centered in the column" % label)
	assert_true(board.size.x <= column.size.x - 2.0 * SkinCatalog.get_skin(skin_id).num(&"board_margin") + 0.01, "%s: inside board_margin" % label)
	if game.offer_panel().visible:
		var margin: float = SkinCatalog.get_skin(skin_id).num(&"board_margin")
		assert_eq(game.offer_panel().position.x, column.position.x + margin, "%s: the offer in the column" % label)
		assert_eq(game.offer_panel().size.x, column.size.x - 2.0 * margin, "%s: inside board_margin" % label)


func test_qa6_08_play_screen_in_the_column_and_after_a_resize() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var game: GameScreen = _game(FOLD_INNER, skin_id, U.board_p())
		_assert_play_screen_in(game, FOLD_INNER, skin_id)
		var column: Rect2 = _column(FOLD_INNER, skin_id)
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		assert_near(game.board().size.x, column.size.x - 2.0 * skin.num(&"board_margin"), 1.0, "%s: on the Fold5 inner screen the board fills the column inside its margins" % skin_id)
		# Fold and unfold: the same screen laid out for the cover size, then
		# for the inner size again.
		U.fit(game, Vector2(PHONE))
		_assert_play_screen_in(game, PHONE, skin_id)
		U.fit(game, Vector2(FOLD_INNER))
		_assert_play_screen_in(game, FOLD_INNER, skin_id)


func test_qa6_08_offer_in_the_column() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var game: GameScreen = _game(FOLD_INNER, skin_id, U.board_d1024())
		assert_true(game.offer_panel().visible, "%s: the offer is open" % skin_id)
		_assert_play_screen_in(game, FOLD_INNER, skin_id)


func test_qa6_08_dialog_panels_in_the_column() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var floats: bool = skin_id == &"gumdrop"
		for size_px: Vector2i in [PHONE, FOLD_INNER]:
			var host: Control = _stage(size_px, skin_id)
			var pause: PausePanel = (load("res://scenes/ui/pause_panel.tscn") as PackedScene).instantiate() as PausePanel
			host.add_child(pause)
			U.fit(pause, Vector2(size_px))
			pause.setup(skin)
			var column: Rect2 = _column(size_px, skin_id)
			pause.layout_in(_screen(size_px), column, floats)
			var panel: PanelContainer = pause.panel()
			var label: String = "%s %s" % [skin_id, size_px]
			var margin: float = skin.num(&"board_margin") if floats else 0.0
			assert_eq(panel.offset_left, column.position.x + margin, "%s: the panel's left edge" % label)
			assert_eq(-panel.offset_right, float(size_px.x) - column.end.x + margin, "%s: the panel's right edge" % label)
			if floats:
				assert_eq(-panel.offset_bottom, 66.0 + margin, "%s: Gumdrop's card floats board_margin above the inset" % label)
			else:
				assert_eq(panel.offset_bottom, 0.0, "%s: a sheet reaches the screen's bottom edge" % label)


func test_qa6_08_splash_in_the_column() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var host: Control = _stage(FOLD_INNER, skin_id)
		var splash: SplashScreen = (load("res://scenes/ui/splash_screen.tscn") as PackedScene).instantiate() as SplashScreen
		host.add_child(splash)
		U.fit(splash, Vector2(FOLD_INNER))
		splash.setup(SkinCatalog.get_skin(skin_id), Records.new())
		var column: Rect2 = _column(FOLD_INNER, skin_id)
		splash.layout_in(_screen(FOLD_INNER), column)
		var root: Control = splash.find_child("Layout", true, false) as Control
		assert_eq(Rect2(root.position, root.size), column, "%s: the splash fills the column" % skin_id)
