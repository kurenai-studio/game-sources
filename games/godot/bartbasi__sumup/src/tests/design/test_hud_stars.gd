extends "res://tests/base_test.gd"
## The HUD star counter, the clear notice's stars and the star moment in
## every skin (GDD D-45, D-46; DESIGN_SYSTEM.md 3.6, 4.7, 5.7, 6.7, 7.5), the
## notice layer (QA6-04), and the HUD laid out in a content column narrower
## than the screen (QA6-08).

const Fixtures: GDScript = preload("res://tests/design/design_fixtures.gd")
const UiCopy: GDScript = preload("res://src/design/shared/ui_copy.gd")

## A board as the play screen places it, in global coordinates.
const BOARD: Rect2 = Rect2(36.0, 500.0, 1008.0, 1600.0)
## When the first star lands, from the notice's start (3.6): Gumdrop
## delay 0.10 + star_earn 0.40, Nova 0.10 + 0.44, Slate at once.
const FIRST_LANDING: Dictionary[StringName, float] = {&"gumdrop": 0.50, &"slate": 0.0, &"nova": 0.54}
## The widest Best Score (GDD 14.2).
const LONGEST: int = 9999999999

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


func _hud(skin_id: StringName, width: float = 1080.0) -> SkinHud:
	var hud: SkinHud = UiKit.make_hud(SkinCatalog.get_skin(skin_id))
	_made.append(hud)
	hud.size = Vector2(width, hud.preferred_height())
	hud.notification(Control.NOTIFICATION_RESIZED)
	return hud


func _layer() -> Control:
	var layer: Control = Control.new()
	layer.size = Vector2(1080.0, 2400.0)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_made.append(layer)
	return layer


func _texts(hud: SkinHud) -> PackedStringArray:
	return hud.call(&"counter_texts") as PackedStringArray


func _shown(hud: SkinHud) -> Vector2i:
	return hud.call(&"shown_stars") as Vector2i


func _notice(hud: SkinHud) -> Control:
	return hud.call(&"clear_notice") as Control


func _star(hud: SkinHud) -> Control:
	return hud.call(&"counter_star") as Control


func test_set_stars_shows_the_count_and_the_free_count() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		assert_eq(_texts(hud), PackedStringArray(["0", ""]), "%s shows 0 from the start of a run" % skin_id)
		var role: StringName = &"body" if skin_id == &"gumdrop" else &"label"
		var cases: Array[Vector2i] = [Vector2i(4, 1), Vector2i(5, 0), Vector2i(6, 2), Vector2i(12, 10), Vector2i(0, 0)]
		for values: Vector2i in cases:
			hud.set_stars(values.x, values.y)
			var free_text: String = UiCopy.free_held(skin, role, values.y) if values.y > 0 else ""
			assert_eq(_texts(hud), PackedStringArray([str(values.x), free_text]), "%s counter for %s" % [skin_id, values])
			assert_eq(int(_star(hud).call(&"steps")), values.x % 3, "%s progress fill for %d stars" % [skin_id, values.x])
		hud.set_stars(4, 1)
		assert_eq(_texts(hud)[1], {&"gumdrop": "1 free", &"slate": "1 FREE", &"nova": "1 free"}[skin_id], "%s free count copy" % skin_id)


func test_counter_star_colors_follow_each_look() -> void:
	var colors: Dictionary[StringName, StringName] = {&"gumdrop": &"badge", &"slate": &"accent", &"nova": &"accent"}
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		hud.set_stars(1, 0)
		var star: Control = _star(hud)
		assert_eq(star.call(&"color"), skin.color(colors[skin_id]), "%s counter star color" % skin_id)
		assert_eq(star.size, Vector2(skin.num(&"star_icon"), skin.num(&"star_icon")), "%s star_icon box" % skin_id)
		assert_eq(bool(star.call(&"glows")), skin_id == &"nova", "%s glow behind a filled star" % skin_id)
		hud.set_stars(3, 1)
		assert_false(bool(star.call(&"glows")), "%s no glow while empty" % skin_id)


func test_notice_shows_plus_n_and_a_star_only_with_stars() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var role: StringName = &"body" if skin_id == &"gumdrop" else &"label"
		var hud: SkinHud = _hud(skin_id)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD)
		var plain: Control = _notice(hud)
		assert_eq(plain.get(&"text"), UiCopy.clear_notice(skin, role, PackedInt64Array([2])), "%s names the value" % skin_id)
		assert_eq(plain.get(&"stars_text"), "", "%s no +n without stars" % skin_id)
		assert_eq(plain.call(&"star_center"), Vector2(-1.0, -1.0), "%s no star without stars" % skin_id)
		var narrow: float = plain.call(&"content_width")
		hud.show_clear_notice(PackedInt64Array([2, 4]), BOARD, 2)
		var starred: Control = _notice(hud)
		assert_eq(starred.get(&"text"), UiCopy.clear_notice(skin, role, PackedInt64Array([2, 4])), "%s names the values it was given" % skin_id)
		assert_eq(starred.get(&"stars_text"), "+2", "%s +n" % skin_id)
		var center: Vector2 = starred.call(&"star_center") as Vector2
		assert_true(center.x > 0.0, "%s a star after the copy" % skin_id)
		var star: SkinIcon = starred.get_node(^"Star") as SkinIcon
		assert_eq(star.size, Vector2(skin.font_size(role), skin.font_size(role)), "%s the star's box is the role's font size" % skin_id)
		assert_eq(star.call(&"ink"), skin.color(&"badge_ink"), "%s the star in badge_ink" % skin_id)
		assert_true(float(starred.call(&"content_width")) > narrow, "%s the notice widens to fit" % skin_id)


func test_the_count_shows_by_the_time_input_reopens() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = _hud(skin_id)
		hud.set_stars(0, 0)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
		hud.set_stars(1, 0)
		var land: float = FIRST_LANDING[skin_id]
		if land > 0.0:
			hud.call(&"seek_star_moment", land - 0.01)
			assert_eq(_shown(hud), Vector2i(0, 0), "%s not yet before the landing" % skin_id)
		hud.call(&"seek_star_moment", land + 0.001)
		assert_eq(_shown(hud), Vector2i(1, 0), "%s the count shows at %.2f s" % [skin_id, land])
		assert_eq(_texts(hud)[0], "1", "%s the counter text" % skin_id)


func test_a_star_moment_ends_on_the_values_set_stars_gave() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = _hud(skin_id)
		hud.set_stars(2, 0)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
		hud.set_stars(3, 1)
		var clock: Tween = hud.call(&"star_moment") as Tween
		assert_true(clock != null and clock.is_valid(), "%s the moment plays on for the values it ends on" % skin_id)
		if skin_id != &"slate":
			assert_eq(_shown(hud), Vector2i(2, 0), "%s still the old values as it starts" % skin_id)
		clock.custom_step(5.0)
		assert_true(hud.call(&"star_moment") == null, "%s the moment ended" % skin_id)
		assert_eq(_shown(hud), Vector2i(3, 1), "%s ends on set_stars' values" % skin_id)
		assert_eq(_texts(hud)[0], "3", "%s count text" % skin_id)
		assert_ne(_texts(hud)[1], "", "%s free count shows" % skin_id)


func test_a_set_stars_the_moment_will_not_deliver_shows_at_once() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = _hud(skin_id)
		hud.set_stars(2, 0)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
		# A new run, a load or a free booster used: values the moment does
		# not end on.
		hud.set_stars(0, 0)
		assert_true(hud.call(&"star_moment") == null, "%s the moment ends" % skin_id)
		assert_eq(_shown(hud), Vector2i(0, 0), "%s the new values at once" % skin_id)
		assert_eq((hud.call(&"flying_stars") as Array[Control]).size(), 0, "%s no star left flying" % skin_id)


func test_several_stars_land_one_at_a_time() -> void:
	# Gumdrop: stagger 0.10, Nova 0.08; Slate flashes once with the final count.
	var second: Dictionary[StringName, float] = {&"gumdrop": 0.60, &"slate": 0.0, &"nova": 0.62}
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = _hud(skin_id)
		hud.set_stars(0, 0)
		hud.show_clear_notice(PackedInt64Array([2, 4]), BOARD, 2)
		hud.set_stars(2, 0)
		if skin_id == &"slate":
			hud.call(&"seek_star_moment", 0.0)
			assert_eq(_shown(hud), Vector2i(2, 0), "slate shows the final count at once")
			continue
		assert_eq((hud.call(&"flying_stars") as Array[Control]).size(), 2, "%s one flying star each" % skin_id)
		hud.call(&"seek_star_moment", FIRST_LANDING[skin_id] + 0.001)
		assert_eq(_shown(hud).x, 1, "%s the first landing" % skin_id)
		hud.call(&"seek_star_moment", second[skin_id] - 0.01)
		assert_eq(_shown(hud).x, 1, "%s the second still flying" % skin_id)
		hud.call(&"seek_star_moment", second[skin_id] + 0.001)
		assert_eq(_shown(hud).x, 2, "%s the second landing" % skin_id)


func test_a_landing_on_a_multiple_of_3_converts() -> void:
	# Gumdrop: the free count rises when the star reaches the free pill,
	# star_convert 0.18 after the landing; Nova as it lands; Slate at once.
	var arrives: Dictionary[StringName, float] = {&"gumdrop": 0.68, &"slate": 0.0, &"nova": 0.54}
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		hud.set_stars(2, 0)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
		hud.set_stars(3, 1)
		var land: float = FIRST_LANDING[skin_id]
		hud.call(&"seek_star_moment", land + 0.001)
		assert_eq(_shown(hud).x, 3, "%s count 3 on landing" % skin_id)
		assert_eq(int(_star(hud).call(&"steps")), 3, "%s the counter star shows full for the moment" % skin_id)
		if skin_id == &"gumdrop":
			assert_eq(_shown(hud).y, 0, "gumdrop free count waits for the travelling star")
		hud.call(&"seek_star_moment", arrives[skin_id] + 0.001)
		assert_eq(_shown(hud).y, 1, "%s one free booster" % skin_id)
		if skin_id == &"slate":
			assert_eq(_star(hud).call(&"color"), skin.color(&"ink"), "slate flashes the star in paper")
			hud.call(&"seek_star_moment", skin.duration(&"star_earn") + 0.001)
			assert_eq(_star(hud).call(&"color"), skin.color(&"accent"), "slate cuts back to accent")
		var clock: Tween = hud.call(&"star_moment") as Tween
		clock.custom_step(5.0)
		assert_eq(int(_star(hud).call(&"steps")), 0, "%s empty after the conversion" % skin_id)


func test_a_star_after_a_conversion_waits_for_it() -> void:
	# Gumdrop: the conversion runs star_convert 0.18 then empty 0.12 from the
	# first landing at 0.50; the second star then flies 0.40: it lands at 1.20.
	var hud: SkinHud = _hud(&"gumdrop")
	hud.set_stars(2, 0)
	hud.show_clear_notice(PackedInt64Array([2, 4]), BOARD, 2)
	hud.set_stars(4, 1)
	hud.call(&"seek_star_moment", 1.19)
	assert_eq(_shown(hud), Vector2i(3, 1), "still flying after the conversion")
	hud.call(&"seek_star_moment", 1.201)
	assert_eq(_shown(hud), Vector2i(4, 1), "lands after the conversion ended")


func test_a_later_notice_finishes_a_running_moment() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = _hud(skin_id)
		hud.set_stars(0, 0)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
		hud.set_stars(1, 0)
		hud.call(&"seek_star_moment", 0.05)
		hud.show_clear_notice(PackedInt64Array([4]), BOARD, 1)
		hud.set_stars(2, 0)
		hud.call(&"seek_star_moment", 0.0)
		assert_eq(_shown(hud).x, 2 if skin_id == &"slate" else 1, "%s the first moment jumped to its end" % skin_id)
		(hud.call(&"star_moment") as Tween).custom_step(5.0)
		assert_eq(_shown(hud), Vector2i(2, 0), "%s the second ends on its values" % skin_id)


func test_the_counter_and_the_effect_never_take_input() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = _hud(skin_id)
		var layer: Control = _layer()
		hud.set_notice_layer(layer)
		hud.set_stars(2, 0)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
		hud.set_stars(3, 1)
		hud.call(&"seek_star_moment", 0.3)
		var pause: Control = hud.get_node(^"Pause") as Control
		for control: Control in Fixtures.controls_under(hud):
			if control == pause or pause.is_ancestor_of(control):
				continue
			assert_eq(control.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s HUD part %s" % [skin_id, control.name])
		for control: Control in Fixtures.controls_under(layer):
			if control == layer:
				continue
			assert_eq(control.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s layer part %s" % [skin_id, control.name])


func test_the_moment_draws_on_the_notice_layer() -> void:
	for skin_id: StringName in [&"gumdrop", &"nova"]:
		var hud: SkinHud = _hud(skin_id)
		var layer: Control = _layer()
		hud.set_notice_layer(layer)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
		var notice: Control = _notice(hud)
		assert_true(notice.get_parent() == layer, "%s the notice is the layer's child" % skin_id)
		assert_false(notice.top_level, "%s ordered by the layer, not top level" % skin_id)
		var flyers: Array[Control] = hud.call(&"flying_stars") as Array[Control]
		assert_eq(flyers.size(), 1, "%s one flying star" % skin_id)
		assert_true(flyers[0].get_parent() == layer, "%s it flies on the layer" % skin_id)
		hud.call(&"seek_star_moment", 0.3)
		assert_true(flyers[0].visible, "%s mid flight it shows" % skin_id)
		# Mid flight it has left the notice and is on its way up to the counter.
		var start: Vector2 = notice.position + (notice.call(&"star_center") as Vector2)
		var at: Vector2 = flyers[0].position + flyers[0].size * 0.5
		assert_true(at.y < start.y, "%s on its way up" % skin_id)


func test_qa6_04_with_the_hud_hidden_the_notice_shows_in_its_offer_placement() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id)
		var layer: Control = _layer()
		hud.set_notice_layer(layer)
		hud.set_stars(2, 0)
		hud.visible = false
		hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
		hud.set_stars(3, 1)
		var notice: Control = _notice(hud)
		assert_true(notice != null and notice.get_parent() == layer, "%s on the layer" % skin_id)
		assert_true(notice.visible, "%s visible while the HUD is hidden" % skin_id)
		var rise: float = float(skin.motion_spec(&"clear_notice").get("from_offset", 0.0))
		assert_near(notice.position.x + notice.size.x * 0.5, BOARD.get_center().x, 0.01, "%s centered on the board" % skin_id)
		assert_near(notice.position.y + notice.size.y * 0.5, BOARD.position.y + rise, 0.01, "%s on the board's top edge" % skin_id)
		if skin_id == &"slate":
			var badge: float = ThemeKitLine.badge_height(skin)
			assert_near(notice.size.y, badge, 0.01, "slate: a badge bar of the badge height")
			assert_near(notice.size.x, float(notice.call(&"content_width")), 0.01, "slate: sized to its content")
			assert_eq((hud.call(&"flying_stars") as Array[Control]).size(), 0, "slate shows only the notice")
		else:
			assert_near(notice.size.y, skin.num(&"notice_height"), 0.01, "%s as in play" % skin_id)
			var flyers: Array[Control] = hud.call(&"flying_stars") as Array[Control]
			assert_eq(flyers.size(), 1, "%s the star rises from the notice" % skin_id)
			var start: Vector2 = notice.position + (notice.call(&"star_center") as Vector2) - Vector2(0.0, rise)
			hud.call(&"seek_star_moment", 0.3)
			var at: Vector2 = flyers[0].position + flyers[0].size * 0.5
			assert_near(at.x, start.x, 0.5, "%s it rises straight up" % skin_id)
			assert_true(at.y < start.y and at.y >= start.y - skin.num(&"space_l") - 0.01, "%s by at most space_l" % skin_id)
			assert_true(flyers[0].modulate.a < 1.0, "%s and fades" % skin_id)
		assert_eq(_shown(hud), Vector2i(3, 1), "%s the hidden counter takes its values at once" % skin_id)
		# The HUD comes back: the counter shows its values with no effect and
		# the notice stays where it is.
		var before: Vector2 = notice.position
		hud.visible = true
		assert_eq(_texts(hud)[0], "3", "%s counter on return" % skin_id)
		assert_true(_notice(hud) == notice and notice.position == before, "%s the notice stays put" % skin_id)


func test_qa6_04_slate_context_notice_moves_to_the_board_edge_when_the_hud_hides() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"slate")
	var hud: SkinHud = _hud(&"slate")
	var layer: Control = _layer()
	hud.position = Vector2(0.0, 120.0)
	hud.set_notice_layer(layer)
	hud.show_clear_notice(PackedInt64Array([2]), BOARD)
	var notice: Control = _notice(hud)
	var row_top: float = 120.0 + skin.num(&"hud_height") - skin.num(&"hint_height")
	assert_eq(notice.position, Vector2(0.0, row_top), "in the context row, in the layer's space")
	hud.visible = false
	assert_true(_notice(hud) == notice and notice.visible, "the same notice, still showing")
	assert_near(notice.position.y + notice.size.y * 0.5, BOARD.position.y, 0.01, "now on the board's top edge")
	hud.visible = true
	assert_near(notice.position.y + notice.size.y * 0.5, BOARD.position.y, 0.01, "and it never jumps back into the context row")


func test_hiding_the_hud_mid_flight_ends_the_moment() -> void:
	for skin_id: StringName in [&"gumdrop", &"nova"]:
		var hud: SkinHud = _hud(skin_id)
		hud.set_notice_layer(_layer())
		hud.set_stars(0, 0)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
		hud.set_stars(1, 0)
		hud.call(&"seek_star_moment", 0.2)
		hud.visible = false
		assert_true(hud.call(&"star_moment") == null, "%s the moment ends" % skin_id)
		assert_eq(_shown(hud), Vector2i(1, 0), "%s on its end values" % skin_id)


func test_freeing_the_hud_takes_its_notice_off_the_layer() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var hud: SkinHud = UiKit.make_hud(SkinCatalog.get_skin(skin_id))
		hud.size = Vector2(1080.0, hud.preferred_height())
		var layer: Control = _layer()
		hud.set_notice_layer(layer)
		hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
		assert_true(layer.get_child_count() > 0, "%s the notice and star are on the layer" % skin_id)
		hud.free()
		assert_eq(layer.get_child_count(), 0, "%s nothing left on the layer" % skin_id)


func test_star_counters_fit_at_1080() -> void:
	# A 13 character Best Score, a two digit count and 1 free (4.7, 5.7, 6.7).
	var gumdrop: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var hud: SkinHud = _hud(&"gumdrop")
	hud.set_scores(Fixtures.big(LONGEST), Fixtures.big(LONGEST))
	hud.set_stars(12, 1)
	var rects: Array[Rect2] = hud.call(&"pill_rects") as Array[Rect2]
	var touch_right: float = gumdrop.num(&"board_margin") + gumdrop.num(&"hud_button_face") * 0.5 + gumdrop.num(&"touch_min") * 0.5
	assert_near(rects[0].position.x, touch_right, 0.01, "gumdrop: the star pill starts at the pause touch area's right edge")
	assert_near(rects[0].position.x, 164.0, 0.01, "gumdrop: 164 px")
	assert_true(rects[1].end.x < rects[2].position.x, "gumdrop: the free pill ends before the Best pill (%d < %d)" % [rects[1].end.x, rects[2].position.x])

	var slate: SkinData = SkinCatalog.get_skin(&"slate")
	var slate_hud: SkinHud = _hud(&"slate")
	slate_hud.set_scores(Fixtures.big(LONGEST), Fixtures.big(LONGEST))
	slate_hud.set_stars(12, 1)
	var span: Vector2 = slate_hud.call(&"counter_span") as Vector2
	var pause_left: float = 1080.0 - slate.num(&"board_margin") - (slate.num(&"touch_min") + slate.num(&"icon_hud")) * 0.5
	assert_near(span.y, pause_left, 0.01, "slate: the counter ends at the pause touch area")
	var score_end: float = slate.num(&"board_margin") + slate.font(&"label").get_string_size(slate.cased(&"label", "Score"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, slate.font_size(&"label")).x
	assert_true(span.x > score_end + slate.num(&"space_m"), "slate: clear of SCORE (%d > %d)" % [span.x, score_end])
	var star: Control = _star(slate_hud)
	assert_true(star.position.y >= 0.0 and star.position.y + star.size.y <= slate.font(&"label").get_height(slate.font_size(&"label")) + 0.01, "slate: the star stays inside the caption line")

	var nova: SkinData = SkinCatalog.get_skin(&"nova")
	var nova_hud: SkinHud = _hud(&"nova")
	nova_hud.set_scores(Fixtures.big(LONGEST), Fixtures.big(LONGEST))
	nova_hud.set_stars(12, 1)
	var line: Vector2 = nova_hud.call(&"best_line_span") as Vector2
	assert_true(line.x >= nova.num(&"board_margin") and line.y <= 1080.0 - nova.num(&"board_margin"), "nova: the best line stays inside the margins (%d to %d)" % [line.x, line.y])


func test_qa6_08_the_hud_lays_out_inside_a_narrow_column() -> void:
	# The Fold5 inner screen: a 1,220 px column inside a 1,998 px viewport.
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var hud: SkinHud = _hud(skin_id, 1220.0)
		hud.set_scores(Fixtures.big(LONGEST), Fixtures.big(LONGEST))
		hud.set_stars(12, 1)
		for control: Control in Fixtures.controls_under(hud):
			if control == hud:
				continue
			var rect: Rect2 = Rect2(control.position, control.size)
			if control.get_parent() != hud:
				continue
			assert_true(rect.position.x >= -0.01 and rect.end.x <= 1220.01, "%s %s inside the column: %s" % [skin_id, control.name, rect])
		var pause: Control = hud.get_node(^"Pause") as Control
		if skin_id == &"gumdrop":
			assert_near(pause.position.x + pause.size.x * 0.5, skin.num(&"board_margin") + skin.num(&"hud_button_face") * 0.5, 0.01, "gumdrop pause on the column's margin")
			var rects: Array[Rect2] = hud.call(&"pill_rects") as Array[Rect2]
			assert_near(rects[2].end.x, 1220.0 - skin.num(&"board_margin"), 0.01, "gumdrop Best pill on the column's right margin")
		else:
			assert_true(pause.position.x + pause.size.x <= 1220.0 + skin.num(&"board_margin"), "%s pause near the column's right edge" % skin_id)
			assert_true(pause.position.x > 1220.0 - 300.0, "%s pause follows the column's right edge" % skin_id)


## The badge height of DESIGN_SYSTEM.md 7.8.
class ThemeKitLine:
	static func badge_height(skin: SkinData) -> float:
		return skin.font(&"label").get_height(skin.font_size(&"label")) + skin.num(&"space_xs") * 2.0


func test_the_flying_and_rising_stars_carry_a_badge_ink_edge() -> void:
	# 2026-10-13 review, DESIGN_SYSTEM.md 3.6: the star is the notice pill's
	# own color, so it flies (and, while the offer is open, rises) on an edge
	# in badge_ink: Gumdrop target_edge_width, Nova hairline.
	var widths: Dictionary[StringName, StringName] = {&"gumdrop": &"target_edge_width", &"nova": &"hairline"}
	var stars: Dictionary[StringName, GDScript] = {
		&"gumdrop": preload("res://src/design/gumdrop/gumdrop_icon.gd"),
		&"nova": preload("res://src/design/nova/nova_icon.gd"),
	}
	for skin_id: StringName in widths:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var width: float = skin.num(widths[skin_id])
		for offer: bool in [false, true]:
			var hud: SkinHud = _hud(skin_id)
			hud.set_notice_layer(_layer())
			hud.visible = not offer
			hud.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
			var flyers: Array[Control] = hud.call(&"flying_stars") as Array[Control]
			var what: String = "%s %s" % [skin_id, "rising star" if offer else "flying star"]
			assert_eq(flyers.size(), 1, "%s exists" % what)
			var flyer: Control = flyers[0]
			assert_eq(flyer.call(&"edge_color"), skin.color(&"badge_ink"), "%s edge in badge_ink" % what)
			assert_eq(float(flyer.call(&"edge_width")), width, "%s edge %d px" % [what, width])
			# The edge is the star's outline grown by the width: its top point
			# sits width above the star's.
			var edge: PackedVector2Array = flyer.call(&"edge_points") as PackedVector2Array
			var star: PackedVector2Array = flyer.call(&"star_points", stars[skin_id].get(&"STAR") as Dictionary) as PackedVector2Array
			var edge_top: float = INF
			var star_top: float = INF
			for p: Vector2 in edge:
				edge_top = minf(edge_top, p.y)
			for p: Vector2 in star:
				star_top = minf(star_top, p.y)
			assert_near(star_top - edge_top, width, 0.5, "%s grown outward by the width" % what)
			assert_eq(flyer.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s takes no input" % what)
			# It scales and fades with the star: the edge is drawn by the flyer.
			hud.call(&"seek_star_moment", 0.2)
			assert_true(flyer.scale.x < 1.0 or flyer.modulate.a < 1.0, "%s scales or fades as one" % what)
	# The counter star, the notice's star and Slate (no flight) do not change.
	var slate: SkinHud = _hud(&"slate")
	slate.show_clear_notice(PackedInt64Array([2]), BOARD, 1)
	assert_eq((slate.call(&"flying_stars") as Array[Control]).size(), 0, "slate has no flight")
