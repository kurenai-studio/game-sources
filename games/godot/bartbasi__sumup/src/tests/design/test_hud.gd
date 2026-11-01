extends "res://tests/base_test.gd"
## Every skin's HUD: height, the score label and its auto fit (DESIGN_SYSTEM.md
## 2.6), the pause button, Slate's context row and preview slot, and the
## clear notice copy, placement and input (7.10, AT-104).

const Fixtures: GDScript = preload("res://tests/design/design_fixtures.gd")
const UiCopy: GDScript = preload("res://src/design/shared/ui_copy.gd")
const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")

## The widest score the GDD allows (14.2).
const LONGEST_SCORE: int = 9999999999
## A board as the play screen places it, in global coordinates.
const BOARD: Rect2 = Rect2(36.0, 500.0, 1008.0, 1600.0)

var _made: Array[Node] = []


func before_each() -> void:
	Motion.bind_tweens = false


func after_each() -> void:
	Motion.bind_tweens = true
	# Unbound tweens outlive the nodes they animated; stop them all.
	for tween: Tween in (Engine.get_main_loop() as SceneTree).get_processed_tweens():
		tween.kill()
	for node: Node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func _hud(skin_id: StringName) -> SkinHud:
	var hud: SkinHud = UiKit.make_hud(SkinCatalog.get_skin(skin_id))
	_made.append(hud)
	hud.size = Vector2(1080.0, hud.preferred_height())
	# Outside the scene tree Godot sends no resize notification; send it as
	# the engine does in the tree.
	hud.notification(Control.NOTIFICATION_RESIZED)
	return hud


func test_preferred_height_is_hud_height() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		assert_eq(_hud(skin_id).preferred_height(), skin.num(&"hud_height"), "%s height" % skin_id)


func test_score_label_shows_the_score() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		hud.set_scores(Fixtures.big(41286), Fixtures.big(96520))
		var label: Label = hud.score_label()
		assert_true(label != null and hud.is_ancestor_of(label), "%s score label is the HUD's" % skin_id)
		assert_eq(label.text, "41,286", "%s score text" % skin_id)
		assert_eq(label.get_theme_font_size(&"font_size"), skin.font_size(&"display"), "%s a short score keeps the display size" % skin_id)
		assert_true(label.get_theme_font(&"font") == skin.font(&"display"), "%s display font" % skin_id)


func test_the_longest_score_fits_its_slot() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		hud.set_scores(Fixtures.big(LONGEST_SCORE), Fixtures.big(LONGEST_SCORE))
		var label: Label = hud.score_label()
		var text: String = NumberFormat.score(Fixtures.big(LONGEST_SCORE))
		assert_eq(label.text, text, "%s longest score text" % skin_id)
		var size: int = label.get_theme_font_size(&"font_size")
		assert_eq(size, skin.score_font_size(text, label.size.x), "%s size comes from score_font_size for the slot" % skin_id)
		assert_true(size >= int(skin.num(&"display_fit_min")), "%s never below display_fit_min" % skin_id)
		var width: float = skin.font(&"display").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
		assert_true(width <= label.size.x, "%s %d px of score fits %d px" % [skin_id, width, label.size.x])
		assert_true(label.position.x >= skin.num(&"board_margin") - 0.01, "%s slot inside the margin" % skin_id)
		assert_true(label.position.x + label.size.x <= hud.size.x - skin.num(&"board_margin") + 0.01, "%s slot inside the margin" % skin_id)


func test_gumdrop_and_nova_scores_end_above_the_notice() -> void:
	for skin_id: StringName in [&"gumdrop", &"nova"]:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var notice_top: float = skin.num(&"hud_height") + skin.num(&"space_s") - skin.num(&"notice_height") * 0.5
		for score: int in [41286, LONGEST_SCORE]:
			var hud: SkinHud = _hud(skin_id)
			hud.set_scores(Fixtures.big(score), Fixtures.big(LONGEST_SCORE))
			var label: Label = hud.score_label()
			var size: int = label.get_theme_font_size(&"font_size")
			var baseline: float = label.position.y + skin.font(&"display").get_ascent(size)
			var comma_bottom: float = baseline + FontMetrics.COMMA_DEPTH * float(size)
			assert_true(comma_bottom <= notice_top - skin.num(&"space_xs") + 0.01, "%s %d: comma ends at %.1f, notice starts at %.1f" % [skin_id, score, comma_bottom, notice_top])
			assert_true(baseline - FontMetrics.CAP_HEIGHT * float(size) >= 0.0, "%s %d: digits start inside the HUD" % [skin_id, score])
			var before: Vector2 = label.position
			hud.show_clear_notice(PackedInt64Array([2]), Rect2(36.0, hud.size.y + skin.num(&"space_s"), 1008.0, 1600.0))
			assert_eq(label.position, before, "%s the score stays put when a notice shows" % skin_id)


func test_pause_button_emits_pause_pressed() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		var heard: Array[bool] = []
		hud.pause_pressed.connect(func() -> void: heard.append(true))
		var pause: Control = hud.get_node(^"Pause") as Control
		assert_true(pause.size.x >= skin.num(&"touch_min") and pause.size.y >= skin.num(&"touch_min"), "%s pause is a touch target" % skin_id)
		assert_true(pause.position.y >= 0.0, "%s pause stays inside the HUD's top" % skin_id)
		pause._gui_input(_mouse(true, pause.size * 0.5))
		pause._gui_input(_mouse(false, pause.size * 0.5))
		assert_eq(heard.size(), 1, "%s pause_pressed" % skin_id)
		assert_eq(hud.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s the HUD itself ignores touches" % skin_id)


func test_preview_slot_and_context_row() -> void:
	for skin_id: StringName in [&"gumdrop", &"nova"]:
		var hud: SkinHud = _hud(skin_id)
		assert_true(hud.preview_slot() == null, "%s previews on the board" % skin_id)
		hud.set_context("Chain 6", false)
	var skin: SkinData = SkinCatalog.get_skin(&"slate")
	var slate: SkinHud = _hud(&"slate")
	var slot: Control = slate.preview_slot()
	assert_true(slot != null and slate.is_ancestor_of(slot), "slate has a preview slot")
	var row: float = skin.num(&"hint_height")
	assert_eq(slot.size, Vector2(row, row), "the slot fills the context row's height")
	assert_eq(slot.position.y, skin.num(&"hud_height") - row, "the slot sits in the context row")
	assert_near(slot.position.x + slot.size.x, 1080.0 - skin.num(&"board_margin"), 0.01, "on the right margin")
	slate.set_context("Chain 6", false)
	assert_eq(slate.call(&"context_text"), "CHAIN 6", "context in capitals")
	slate.set_context("Hammer: Tap a tile to smash it", true)
	assert_eq(slate.call(&"context_text"), "HAMMER: TAP A TILE TO SMASH IT", "hint in capitals")


func test_clear_notice_copy_matches_the_design() -> void:
	var cases: Array[PackedInt64Array] = [
		PackedInt64Array([1]),
		PackedInt64Array([1, 2]),
		PackedInt64Array([1, 2, 3]),
		PackedInt64Array([1, 2, 3, 4, 5]),
		PackedInt64Array([11]),
		PackedInt64Array([10, 11]),
	]
	var expected: Dictionary[StringName, PackedStringArray] = {
		&"gumdrop": PackedStringArray(["No more 2s", "No more 2s or 4s", "No more 2s to 8s", "No more 2s to 32s", "No more 2Ks", "No more 1024s or 2Ks"]),
		&"slate": PackedStringArray(["NO MORE 2s", "NO MORE 2s OR 4s", "NO MORE 2s TO 8s", "NO MORE 2s TO 32s", "NO MORE 2Ks", "NO MORE 1024s OR 2Ks"]),
		&"nova": PackedStringArray(["no more 2s", "no more 2s or 4s", "no more 2s to 8s", "no more 2s to 32s", "no more 2Ks", "no more 1024s or 2Ks"]),
	}
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = _hud(skin_id)
		for i: int in cases.size():
			hud.show_clear_notice(cases[i], BOARD)
			var notice: Control = hud.call(&"clear_notice") as Control
			assert_true(notice != null, "%s shows a notice" % skin_id)
			assert_eq(notice.get(&"text"), expected[skin_id][i], "%s notice for %s" % [skin_id, cases[i]])


func test_clear_notice_shows_struck_mini_tiles() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		hud.show_clear_notice(PackedInt64Array([2, 4, 8]), BOARD)
		var notice: Control = hud.call(&"clear_notice") as Control
		var tiles: Array[Control] = notice.call(&"tiles") as Array[Control]
		assert_eq(tiles.size(), 3, "%s one tile per value" % skin_id)
		var height: float = skin.num(&"hint_height") if skin_id == &"slate" else skin.num(&"notice_height")
		for tile: Control in tiles:
			assert_true(tile is SkinTileView, "%s mini tiles come from the skin's tile view" % skin_id)
			assert_near(tile.size.x, skin.num(&"notice_tile_scale") * height, 0.01, "%s tile size" % skin_id)


func test_clear_notice_never_takes_input() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = _hud(skin_id)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD)
		var notice: Control = hud.call(&"clear_notice") as Control
		assert_eq(notice.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s notice" % skin_id)
		for child: Node in notice.get_children():
			assert_eq((child as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s notice part %s" % [skin_id, child.name])


func test_a_later_notice_replaces_the_first() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = _hud(skin_id)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD)
		var first: Control = hud.call(&"clear_notice") as Control
		hud.show_clear_notice(PackedInt64Array([4]), BOARD)
		var second: Control = hud.call(&"clear_notice") as Control
		assert_true(first != second, "%s a new notice" % skin_id)
		assert_false(hud.is_ancestor_of(first), "%s the old one is gone" % skin_id)


func test_gumdrop_and_nova_notices_sit_on_the_board_top_edge() -> void:
	for skin_id: StringName in [&"gumdrop", &"nova"]:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		hud.show_clear_notice(PackedInt64Array([2, 4]), BOARD)
		var notice: Control = hud.call(&"clear_notice") as Control
		assert_true(notice.top_level, "%s placed in global space" % skin_id)
		assert_near(notice.position.x + notice.size.x * 0.5, BOARD.get_center().x, 0.01, "%s centered on the board" % skin_id)
		assert_near(notice.size.y, skin.num(&"notice_height"), 0.01, "%s notice_height" % skin_id)
		var rise: float = float(skin.motion_spec(&"clear_notice").get("from_offset", 0.0))
		assert_near(notice.position.y + notice.size.y * 0.5, BOARD.position.y + rise, 0.01, "%s centered on the top edge, before rising from_offset" % skin_id)
		assert_true(notice.size.x <= BOARD.size.x, "%s narrower than the board" % skin_id)


func test_slate_notice_takes_the_context_row_and_waits_for_the_drag() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"slate")
	var hud: SkinHud = _hud(&"slate")
	hud.set_context("Chain 3", false)
	hud.show_clear_notice(PackedInt64Array([2]), BOARD)
	var notice: Control = hud.call(&"clear_notice") as Control
	assert_eq(notice.position, Vector2(0.0, skin.num(&"hud_height") - skin.num(&"hint_height")), "in the context row")
	assert_eq(notice.size, Vector2(1080.0, skin.num(&"hint_height")), "full width bar")
	assert_false(notice.visible, "waits while a chain is dragged")
	hud.set_context("", false)
	assert_true(notice.visible, "shows when the finger lifts")
	assert_false(hud.preview_slot().visible, "the preview slot steps aside")


func _mouse(pressed: bool, at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	return event
