extends "res://tests/base_test.gd"
## The 2026-10-21 unlimited numbers in the design area (DESIGN_SYSTEM.md 2.5,
## 2.6, 4.7, 7.10 and 14): HUD scores past 64 bits, the score fit for 15 and
## 16 characters, Gumdrop's Best pill fit, the clear notice plural, booster
## costs past Q, and star counts in the tens of thousands.

const Fixtures: GDScript = preload("res://tests/design/design_fixtures.gd")
const UiCopy: GDScript = preload("res://src/design/shared/ui_copy.gd")

## Bart's score when the 64 bit limit stopped his run (CLAUDE.md, 2026-10-21).
const BART_SCORE: String = "9221253119629040934"
## A score showing as 9,999,999,999zz (15 characters): 10 shown digits and 581
## dropped groups of three.
const ZZ_DIGITS: int = 1753
## A score showing as 4,444,444,444mm, Outfit's widest 15 characters (14.2):
## mm is suffix 281, so 10 + 3 * 281 digits.
const MM_DIGITS: int = 853
## A 16 character score: the first with three letters, 9,999,999,999aaa.
const AAA_DIGITS: int = 1756
const BOARD: Rect2 = Rect2(36.0, 500.0, 1008.0, 1600.0)

var _made: Array[Node] = []


func before_each() -> void:
	Motion.bind_tweens = false


func after_each() -> void:
	Motion.bind_tweens = true
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
	hud.notification(Control.NOTIFICATION_RESIZED)
	return hud


func _repeat(digit: String, count: int) -> BigNum:
	return Fixtures.digits(digit.repeat(count))


## The score's drawn width at its fitted size.
func _score_width(skin: SkinData, label: Label) -> float:
	return skin.font(&"display").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label.get_theme_font_size(&"font_size")).x


func test_bart_score_and_powers_of_two_show_with_their_suffix() -> void:
	var cases: Dictionary[String, BigNum] = {
		"9,221,253,119B": Fixtures.digits(BART_SCORE),
		"9,223,372,036B": BigNum.pow2(63),
		"1,267,650,600ab": BigNum.pow2(100),
	}
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for text: String in cases:
			var hud: SkinHud = _hud(skin_id)
			hud.set_scores(cases[text], cases[text])
			var label: Label = hud.score_label()
			assert_eq(label.text, text, "%s score" % skin_id)
			assert_true(label.get_theme_font_size(&"font_size") >= int(skin.num(&"display_fit_min")), "%s %s at or above display_fit_min" % [skin_id, text])
			assert_true(_score_width(skin, label) <= label.size.x + 0.01, "%s %s fits its slot" % [skin_id, text])
			var best: String = ""
			match skin_id:
				&"nova":
					best = hud.call(&"best_text") as String
					assert_eq(best, skin.cased(&"label", "Best") + " " + text, "nova best line, the number never cased")
				_:
					best = hud.get(&"_best_text") as String
					assert_eq(best, text, "%s best number" % skin_id)


func test_15_characters_stay_at_or_above_display_fit_min() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for digits: Array in [["9", ZZ_DIGITS], ["4", MM_DIGITS], ["1", MM_DIGITS]]:
			var score: BigNum = _repeat(digits[0] as String, digits[1] as int)
			var hud: SkinHud = _hud(skin_id)
			hud.set_scores(score, score)
			hud.set_stars(12, 10)
			var label: Label = hud.score_label()
			assert_eq(label.text.length(), 15, "%s %s is 15 characters" % [skin_id, label.text])
			var size: int = label.get_theme_font_size(&"font_size")
			assert_true(size >= int(skin.num(&"display_fit_min")), "%s %s at %d, floor %d" % [skin_id, label.text, size, int(skin.num(&"display_fit_min"))])
			assert_true(_score_width(skin, label) <= label.size.x + 0.01, "%s %s fits its slot" % [skin_id, label.text])


func test_a_16_character_score_fits_its_slot_in_every_skin() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var score: BigNum = _repeat("9", AAA_DIGITS)
		var hud: SkinHud = _hud(skin_id)
		hud.set_scores(score, score)
		var label: Label = hud.score_label()
		assert_eq(label.text, "9,999,999,999aaa", "%s 16 characters" % skin_id)
		assert_true(label.get_theme_font_size(&"font_size") >= 1, "%s a real size" % skin_id)
		assert_true(_score_width(skin, label) <= label.size.x + 0.01, "%s %.1f px fits %.1f px" % [skin_id, _score_width(skin, label), label.size.x])
		assert_true(label.position.x >= skin.num(&"board_margin") - 0.01, "%s slot inside the margin" % skin_id)
		assert_true(label.position.x + label.size.x <= hud.size.x - skin.num(&"board_margin") + 0.01, "%s slot inside the margin" % skin_id)


## 4.7: the Best pill's left edge stays space_s right of the free pill's end
## (the star pill's end with no free pill); the number shrinks, never below
## the label role size. Two digit counts are the measured worst case.
func test_gumdrop_best_pill_stays_clear_of_the_star_and_free_pills() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var floor_size: int = skin.font_size(&"label")
	var space_s: float = skin.num(&"space_s")
	var longest: BigNum = _repeat("9", ZZ_DIGITS)
	var widest: BigNum = _repeat("4", MM_DIGITS)
	for score: BigNum in [longest, widest]:
		for counts: Vector2i in [Vector2i(4, 1), Vector2i(12, 10), Vector2i(12, 0)]:
			var hud: SkinHud = _hud(&"gumdrop")
			hud.set_scores(score, score)
			hud.set_stars(counts.x, counts.y)
			var rects: Array[Rect2] = hud.call(&"pill_rects") as Array[Rect2]
			var row_end: float = rects[1].end.x if counts.y > 0 else rects[0].end.x
			var label: String = "%s with %d stars, %d free" % [NumberFormat.score(score), counts.x, counts.y]
			assert_true(rects[2].position.x >= row_end + space_s - 0.01, "%s: Best pill at %.1f, row ends %.1f" % [label, rects[2].position.x, row_end])
			var size: int = hud.call(&"best_number_size") as int
			assert_true(size >= floor_size, "%s: number at %d, floor %d" % [label, size, floor_size])
			assert_near(rects[2].end.x, 1080.0 - skin.num(&"board_margin"), 0.01, "%s: right edge on the margin" % label)
	# The measured worst: 40 px with two digit counts (14.2).
	var worst: SkinHud = _hud(&"gumdrop")
	worst.set_scores(widest, widest)
	worst.set_stars(12, 10)
	assert_true(worst.call(&"best_number_size") as int >= 40, "the worst 15 characters fit at 40 px or more")


func test_gumdrop_best_up_to_13_characters_keeps_the_body_size() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	for counts: Vector2i in [Vector2i(0, 0), Vector2i(12, 10)]:
		var hud: SkinHud = _hud(&"gumdrop")
		hud.set_scores(Fixtures.big(9999999999), Fixtures.big(9999999999))
		hud.set_stars(counts.x, counts.y)
		assert_eq(hud.call(&"best_number_size"), skin.font_size(&"body"), "13 characters with %s keep the body size" % counts)


## GDD D-46: stars and free counts can reach tens of thousands. The counters
## show the plain number and the top row stays inside the HUD. Gumdrop's
## Best number goes below the label size only here, when even that size would
## reach the free pill (the QA6-10 rule, as for the score).
func test_large_star_counts_show_and_stay_inside() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		var score: BigNum = Fixtures.digits(BART_SCORE)
		hud.set_scores(score, score)
		hud.set_stars(65535, 21845)
		assert_eq(hud.call(&"shown_stars"), Vector2i(65535, 21845), "%s the counts" % skin_id)
		match skin_id:
			&"gumdrop":
				var texts: PackedStringArray = hud.call(&"counter_texts") as PackedStringArray
				assert_eq(texts[0], "65535", "gumdrop count")
				assert_eq(texts[1], UiCopy.free_held(skin, &"body", 21845), "gumdrop free")
				var rects: Array[Rect2] = hud.call(&"pill_rects") as Array[Rect2]
				assert_true(rects[1].end.x <= rects[2].position.x - skin.num(&"space_s") + 0.01, "gumdrop: the free pill ends before the Best pill")
			&"slate":
				var span: Vector2 = hud.call(&"counter_span") as Vector2
				assert_true(span.x >= skin.num(&"board_margin"), "slate: the counter stays inside (%d)" % span.x)
			&"nova":
				var line: Vector2 = hud.call(&"best_line_span") as Vector2
				assert_true(line.x >= skin.num(&"board_margin") - 0.01 and line.y <= 1080.0 - skin.num(&"board_margin") + 0.01, "nova: the best line stays inside the margins (%d to %d)" % [line.x, line.y])


## 7.10: no plural "s" after a lowercase suffix; values never cased.
func test_clear_notice_plural_after_suffix_letters() -> void:
	var cases: Array[PackedInt64Array] = [
		PackedInt64Array([56]),
		PackedInt64Array([66]),
		PackedInt64Array([67, 68, 69]),
		PackedInt64Array([59, 60]),
		PackedInt64Array([55, 56, 57]),
	]
	var expected: Dictionary[StringName, PackedStringArray] = {
		&"gumdrop": PackedStringArray(["No more 64Qs", "No more 64aa", "No more 128aa to 512aa", "No more 512Qs or 1aa", "No more 32Qs to 128Qs"]),
		&"slate": PackedStringArray(["NO MORE 64Qs", "NO MORE 64aa", "NO MORE 128aa TO 512aa", "NO MORE 512Qs OR 1aa", "NO MORE 32Qs TO 128Qs"]),
		&"nova": PackedStringArray(["no more 64Qs", "no more 64aa", "no more 128aa to 512aa", "no more 512Qs or 1aa", "no more 32Qs to 128Qs"]),
	}
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var role: StringName = &"body" if skin_id == &"gumdrop" else &"label"
		var hud: SkinHud = _hud(skin_id)
		for i: int in cases.size():
			assert_eq(UiCopy.clear_notice(skin, role, cases[i]), expected[skin_id][i], "%s copy for %s" % [skin_id, cases[i]])
			hud.show_clear_notice(cases[i], BOARD)
			var notice: Control = hud.call(&"clear_notice") as Control
			assert_eq(notice.get(&"text"), expected[skin_id][i], "%s notice for %s" % [skin_id, cases[i]])


## QA21-04: the plural "s" is never cased. For every skin and every exponent
## from 1 to 200, the notice ends with the exact tile label followed by
## nothing (lowercase suffix) or one lowercase "s", and Slate never shows a
## capital suffix followed by "S" after a digit.
func test_clear_notice_plural_s_is_never_cased() -> void:
	var pair: RegEx = RegEx.create_from_string("[0-9][A-Z]S")
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var role: StringName = &"body" if skin_id == &"gumdrop" else &"label"
		for exponent: int in range(1, 201):
			var label: String = NumberFormat.tile_label(exponent)
			var last: String = label.right(1)
			var tail: String = label if last != last.to_upper() else label + "s"
			var text: String = UiCopy.clear_notice(skin, role, PackedInt64Array([exponent]))
			assert_true(text.ends_with(" " + tail), "%s notice for %d ends with %s: %s" % [skin_id, exponent, tail, text])
			assert_true(pair.search(text) == null, "%s notice for %d has no cased plural: %s" % [skin_id, exponent, text])


## 14.1: costs use the tile label of the cost exponent, never cased, and the
## widest six character cost fits the cost line at full size.
func test_costs_past_q_use_the_tile_label_and_fit() -> void:
	var exponents: PackedInt64Array = PackedInt64Array([68, 71938])
	var labels: PackedStringArray = PackedStringArray(["256aa", "256mmm"])
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var bar: SkinBoosterBar = UiKit.make_booster_bar(skin)
		_made.append(bar)
		bar.size = Vector2(1080.0, bar.preferred_height())
		bar.notification(Control.NOTIFICATION_RESIZED)
		for i: int in exponents.size():
			bar.show_boosters(Fixtures.plain_statuses(exponents[i]))
			for button: Control in bar.call(&"buttons") as Array[Control]:
				assert_eq(button.get(&"cost_text"), labels[i], "%s cost label" % skin_id)
				var width: float = skin.font(&"label").get_string_size(labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, skin.font_size(&"label")).x
				# The cost line's room: Gumdrop centers it on the button's
				# face, Slate starts it space_s in, Nova centers it under
				# the ring across the button.
				var room: float = button.size.x
				match skin_id:
					&"gumdrop":
						room = (button.call(&"rest_rect") as Rect2).size.x
					&"slate":
						room = button.size.x - skin.num(&"space_s") * 2.0
				assert_true(width <= room, "%s %s: %.1f px in %.1f px" % [skin_id, labels[i], width, room])


## 4.7, 14.1: a notice mini tile draws its label only up to 3 characters;
## longer ones are color chips, and the copy still names the values.
func test_notice_mini_tiles_draw_labels_up_to_3_characters() -> void:
	var cases: Array[PackedInt64Array] = [
		PackedInt64Array([67, 68, 69]),
		PackedInt64Array([1, 2]),
		PackedInt64Array([9, 10, 11]),
		PackedInt64Array([60, 66]),
	]
	var shown: Array[Array] = [[false, false, false], [true, true], [true, false, true], [true, false]]
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = _hud(skin_id)
		for i: int in cases.size():
			hud.show_clear_notice(cases[i], BOARD)
			var notice: Control = hud.call(&"clear_notice") as Control
			var tiles: Array[Control] = notice.call(&"tiles") as Array[Control]
			assert_eq(tiles.size(), cases[i].size(), "%s one tile per value" % skin_id)
			for t: int in tiles.size():
				var label: String = NumberFormat.tile_label(cases[i][t])
				assert_eq(tiles[t].get(&"_label_shown"), shown[i][t], "%s mini tile %s label shown" % [skin_id, label])
			for t: int in cases[i].size():
				if t == 0 or t == cases[i].size() - 1:
					assert_true((notice.get(&"text") as String).contains(NumberFormat.tile_label(cases[i][t])), "%s the copy names %s" % [skin_id, NumberFormat.tile_label(cases[i][t])])
