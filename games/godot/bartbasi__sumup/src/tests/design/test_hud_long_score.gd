extends "res://tests/base_test.gd"
## A score longer than the 15 characters display_fit_min is made for
## (DESIGN_SYSTEM.md 2.6 and 14.2: 16 characters, three suffix letters, only
## from a score of 1,754 digits or more): in every skin's HUD at 1080 px the
## score keeps shrinking below the floor until it fits its slot, and never
## reaches the Best label or the pause button's touch area (the QA6-10 rule).

const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")
const Fixtures: GDScript = preload("res://tests/design/design_fixtures.gd")

## 16 character scores as their repeated digit and digit count: the widest
## letters "mmm" with Outfit's widest digit 4 and the system font's 1 (14.2),
## and the first three letter score, "9,999,999,999aaa".
const LONG_DIGITS: Array[String] = ["4", "1", "9"]
const LONG_LENGTHS: Array[int] = [21589, 21589, 1756]
## The widest full score (14.2), 13 characters.
const LONGEST_SCORE: int = 9999999999

var _long_scores: Array[BigNum] = []

var _made: Array[Node] = []


func before_each() -> void:
	Motion.bind_tweens = false
	_long_scores.clear()
	for i: int in LONG_DIGITS.size():
		_long_scores.append(Fixtures.digits(LONG_DIGITS[i].repeat(LONG_LENGTHS[i])))


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


## Where the score's digits are drawn, from its cap height to its comma tail.
func _score_ink(skin: SkinData, label: Label) -> Rect2:
	var size: int = label.get_theme_font_size(&"font_size")
	var display: Font = skin.font(&"display")
	var width: float = display.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	var left: float = label.position.x
	if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		left += (label.size.x - width) * 0.5
	var baseline: float = label.position.y + display.get_ascent(size)
	var top: float = baseline - FontMetrics.CAP_HEIGHT * float(size)
	return Rect2(left, top, width, FontMetrics.CAP_HEIGHT * float(size) + FontMetrics.COMMA_DEPTH * float(size))


func test_a_16_character_score_stays_in_its_slot() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for score: BigNum in _long_scores:
			var hud: SkinHud = _hud(skin_id)
			hud.set_scores(score, _long_scores[0])
			var label: Label = hud.score_label()
			assert_eq(label.text.length(), 16, "%s %s is 16 characters" % [skin_id, label.text])
			var ink: Rect2 = _score_ink(skin, label)
			assert_true(label.get_theme_font_size(&"font_size") >= 1, "%s a real font size" % skin_id)
			assert_true(ink.position.x >= label.position.x - 0.01, "%s %s: starts at %.1f, slot at %.1f" % [skin_id, NumberFormat.score(score), ink.position.x, label.position.x])
			assert_true(ink.end.x <= label.position.x + label.size.x + 0.01, "%s %s: ends at %.1f, slot ends at %.1f" % [skin_id, NumberFormat.score(score), ink.end.x, label.position.x + label.size.x])
			assert_true(label.position.x >= skin.num(&"board_margin") - 0.01, "%s slot inside the margin" % skin_id)
			assert_true(label.position.x + label.size.x <= hud.size.x - skin.num(&"board_margin") + 0.01, "%s slot inside the margin" % skin_id)


## Slate: clear of the whole touch area, which is also what Slate fills
## while the button is held.
func test_a_16_character_score_is_clear_of_slate_pause_touch_area() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"slate")
	for score: BigNum in _long_scores:
		var hud: SkinHud = _hud(&"slate")
		hud.set_scores(score, _long_scores[0])
		var pause: Control = hud.get_node(^"Pause") as Control
		var touch: Rect2 = Rect2(pause.position, pause.size)
		var ink: Rect2 = _score_ink(skin, hud.score_label())
		assert_false(ink.intersects(touch), "slate %s: score %s, pause %s" % [NumberFormat.score(score), ink, touch])


## Nova and Gumdrop: the approved 13 character layout already lets the score
## reach a little into the pause button's touch area (the score ignores
## touches, so a tap there still pauses). What must stay clear is the button
## as drawn: Nova's ring with space_xs to spare, Gumdrop's face and lip.
func test_a_16_character_score_is_clear_of_the_drawn_pause_button() -> void:
	for score: BigNum in _long_scores:
		var nova: SkinData = SkinCatalog.get_skin(&"nova")
		var nova_hud: SkinHud = _hud(&"nova")
		nova_hud.set_scores(score, _long_scores[0])
		var nova_pause: Control = nova_hud.get_node(^"Pause") as Control
		var ring: Control = nova_pause.get(&"_ring") as Control
		var ring_rect: Rect2 = Rect2(nova_pause.position + ring.position, ring.size).grow(nova.num(&"space_xs") - 0.01)
		var nova_ink: Rect2 = _score_ink(nova, nova_hud.score_label())
		assert_false(nova_ink.intersects(ring_rect), "nova %s: score %s, ring %s" % [NumberFormat.score(score), nova_ink, ring_rect])
		var gumdrop: SkinData = SkinCatalog.get_skin(&"gumdrop")
		var gumdrop_hud: SkinHud = _hud(&"gumdrop")
		gumdrop_hud.set_scores(score, _long_scores[0])
		var gumdrop_pause: Control = gumdrop_hud.get_node(^"Pause") as Control
		var rest: Rect2 = gumdrop_pause.call(&"rest_rect") as Rect2
		var face_rect: Rect2 = Rect2(gumdrop_pause.position + rest.position, rest.size)
		var gumdrop_ink: Rect2 = _score_ink(gumdrop, gumdrop_hud.score_label())
		assert_false(gumdrop_ink.intersects(face_rect), "gumdrop %s: score %s, button %s" % [NumberFormat.score(score), gumdrop_ink, face_rect])


func test_a_16_character_score_is_clear_of_the_best_label() -> void:
	for score: BigNum in _long_scores:
		# Slate: the BEST caption and number sit right of the score's slot.
		var slate: SkinData = SkinCatalog.get_skin(&"slate")
		var hud: SkinHud = _hud(&"slate")
		hud.set_scores(score, _long_scores[0])
		var ink: Rect2 = _score_ink(slate, hud.score_label())
		var best_left: float = minf((hud.get(&"_best_origin") as Vector2).x, (hud.get(&"_best_caption_origin") as Vector2).x)
		assert_true(ink.end.x <= best_left - slate.num(&"space_s") + 0.01, "slate %s: score ends at %.1f, BEST starts at %.1f" % [NumberFormat.score(score), ink.end.x, best_left])
		# Nova: the best line sits under the score; the comma tail ends
		# space_xs above its letters.
		var nova: SkinData = SkinCatalog.get_skin(&"nova")
		var nova_hud: SkinHud = _hud(&"nova")
		nova_hud.set_scores(score, _long_scores[0])
		var nova_ink: Rect2 = _score_ink(nova, nova_hud.score_label())
		var best_baseline: float = (nova_hud.get(&"_best_origin") as Vector2).y
		var letters_top: float = best_baseline - FontMetrics.CAP_HEIGHT * float(nova.font_size(&"label"))
		assert_true(nova_ink.end.y <= letters_top - nova.num(&"space_xs") + 0.01, "nova %s: score ends at %.1f, best letters at %.1f" % [NumberFormat.score(score), nova_ink.end.y, letters_top])
		# Gumdrop: the Best pill and the star pill sit above the score.
		var gumdrop: SkinData = SkinCatalog.get_skin(&"gumdrop")
		var gumdrop_hud: SkinHud = _hud(&"gumdrop")
		gumdrop_hud.set_scores(score, _long_scores[0])
		var gumdrop_ink: Rect2 = _score_ink(gumdrop, gumdrop_hud.score_label())
		assert_false(gumdrop_ink.intersects(gumdrop_hud.get(&"_pill_rect") as Rect2), "gumdrop %s: score clear of the Best pill" % NumberFormat.score(score))


func test_up_to_13_characters_the_size_is_unchanged() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		hud.set_scores(Fixtures.big(LONGEST_SCORE), Fixtures.big(LONGEST_SCORE))
		var label: Label = hud.score_label()
		assert_eq(label.get_theme_font_size(&"font_size"), skin.score_font_size(label.text, label.size.x), "%s 13 characters keep score_font_size" % skin_id)
