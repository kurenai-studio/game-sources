# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## QA round 3 (docs/reviews/qa-2026-10-26.md), the UI items: p1 the Pause menu on every
## way of leaving or folding mid-wave, p3 no lighter look on a tapped button, p4 the
## gesture margin at the bottom of the safe area. No running scene tree.

const Fx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const TAG: String = "qa3"

var apps: Array[App] = []
var kept: Array[Node] = []


func before_each() -> void:
	apps.clear()
	kept.clear()
	Fx.wipe(TAG)


func after_each() -> void:
	for made: App in apps:
		made.free()
	for node: Node in kept:
		node.free()
	Fx.wipe(TAG)


func _app() -> App:
	var made: App = Fx.app(TAG, true)
	apps.append(made)
	return made


## A level with a wave running and creatures on the map.
func _midwave(made: App) -> BattleScreen:
	Fx.mark_all_seen(made)
	made.open_mode()
	made.campaign_requested.emit()
	(made.current_screen() as LevelSelect).level_chosen.emit(&"r1_l1")
	(made.current_screen() as LevelCard).play_requested.emit(false)
	var screen: BattleScreen = made.battle_screen()
	Fx.build(screen, screen.battle.level.spots[0], &"sling_post")
	screen.hud.call_button.tapped.emit()
	Fx.run(screen, 200, func() -> bool: return screen.battle.enemies.size() >= 2)
	assert_true(screen.battle.phase == Battle.Phase.WAVE, "a wave is running")
	return screen


func _saved_tick() -> int:
	var games: Array[SavedGame] = SaveStore.new(Fx.dir(TAG)).load_games(Fx.BattleFixtures.game())
	return games[0].battle.tick if not games.is_empty() else -1


## Every way a fold or a leave reaches the game, each as a callable on the App.
func _paths() -> Dictionary:
	return {
		"resize": func(made: App) -> void: made.apply_layout(Fx.INNER, Fx.INNER_SAFE),
		"focus out": func(made: App) -> void: made.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT),
		"app paused": func(made: App) -> void: made.notification(Node.NOTIFICATION_APPLICATION_PAUSED),
		"close request": func(made: App) -> void: made.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST),
		"leave": func(made: App) -> void: made.leave_app(),
	}


# p1: the Pause menu, never only the strip.

func test_every_path_opens_the_pause_menu_when_the_wave_runs() -> void:
	var paths: Dictionary = _paths()
	for path_name: String in paths:
		var made: App = _app()
		var screen: BattleScreen = _midwave(made)
		var tick: int = screen.battle.tick
		(paths[path_name] as Callable).call(made)
		assert_true(screen.is_paused(), "%s pauses" % path_name)
		assert_true(screen.pause_menu_open(), "%s opens the Pause menu" % path_name)
		assert_false(screen.pause_strip.visible, "%s shows no strip" % path_name)
		assert_eq(screen.battle.tick, tick, "%s loses no tick" % path_name)
		assert_eq(_saved_tick(), tick, "%s saves the exact moment" % path_name)
		apps.erase(made)
		made.free()
		Fx.wipe(TAG)


func test_every_path_opens_the_pause_menu_over_the_hud_strip_too() -> void:
	# The HUD's pause button left the Paused strip up. A fold or a leave then still
	# brings the Pause menu, as ARCHITECTURE 7.5 says.
	var paths: Dictionary = _paths()
	for path_name: String in paths:
		var made: App = _app()
		var screen: BattleScreen = _midwave(made)
		screen.hud.pause_button.tapped.emit()
		assert_true(screen.pause_strip.visible, "the strip is up before %s" % path_name)
		assert_false(screen.pause_menu_open())
		var tick: int = screen.battle.tick
		(paths[path_name] as Callable).call(made)
		assert_true(screen.pause_menu_open(), "%s opens the Pause menu over the strip" % path_name)
		assert_false(screen.pause_strip.visible, "%s takes the strip down" % path_name)
		assert_true(screen.is_paused())
		assert_eq(screen.battle.tick, tick, "%s loses no tick" % path_name)
		assert_eq(_saved_tick(), tick, "%s saves the exact moment" % path_name)
		assert_eq(made.modal_count(), 1, "%s opens one menu" % path_name)
		apps.erase(made)
		made.free()
		Fx.wipe(TAG)


func test_a_focus_loss_then_the_resize_opens_one_menu() -> void:
	# Android may send the focus loss before the resize or after it. Either order, one menu.
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	made.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	made.apply_layout(Fx.INNER, Fx.INNER_SAFE)
	made.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	made.apply_layout(Fx.COVER, Fx.COVER_SAFE)
	assert_eq(made.modal_count(), 1, "still one Pause menu")
	assert_true(screen.pause_menu_open())
	assert_false(screen.pause_strip.visible)


func test_the_resize_then_a_focus_loss_opens_one_menu() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	made.apply_layout(Fx.INNER, Fx.INNER_SAFE)
	made.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(made.modal_count(), 1)
	assert_true(screen.pause_menu_open())
	assert_eq(_saved_tick(), screen.battle.tick)


func test_the_strip_in_a_build_phase_stays_a_strip() -> void:
	# Between waves nothing is running, so a fold or a leave only saves.
	var made: App = _app()
	Fx.mark_all_seen(made)
	made.open_mode()
	made.campaign_requested.emit()
	(made.current_screen() as LevelSelect).level_chosen.emit(&"r1_l1")
	(made.current_screen() as LevelCard).play_requested.emit(false)
	var screen: BattleScreen = made.battle_screen()
	screen.hud.pause_button.tapped.emit()
	made.apply_layout(Fx.INNER, Fx.INNER_SAFE)
	made.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(screen.pause_menu_open())
	assert_true(screen.pause_strip.visible)
	assert_false(screen.needs_pause_menu())


func test_a_leave_while_a_first_sight_card_holds_the_wave_opens_the_menu_when_it_closes() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	var kind: StringName = screen.battle.enemies[0].type
	screen._show_card([{"kind": &"enemy", "id": kind, "wave": 0}])
	assert_true(screen.card_open())
	assert_true(screen.is_paused(), "the card holds the wave")
	made.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(screen.pause_menu_open(), "the card stays on top")
	assert_eq(_saved_tick(), screen.battle.tick, "the moment is saved")
	screen._card.advance()
	assert_true(screen.pause_menu_open(), "the Pause menu opens when the card closes")
	assert_true(screen.is_paused())


# p3: no lighter look after a tap.

func _themed(variation: StringName) -> TapButton:
	var b: TapButton = TapButton.new()
	b.theme_type_variation = variation
	b.theme = UiTheme.build()
	# The runner has no tree that is running, so send the notification the tree would send.
	# tests/ui/real_tree_checks.gd proves the same inside a real tree.
	b.notification(Control.NOTIFICATION_THEME_CHANGED)
	kept.append(b)
	return b


func test_a_tap_button_never_draws_the_hover_look() -> void:
	for variation: StringName in [&"Button", &"PrimaryButton", &"QuietButton", &"CardButton"]:
		var b: TapButton = _themed(variation)
		assert_true(b.get_theme_stylebox(&"hover") == b.get_theme_stylebox(&"normal"), "%s: hover is the normal look" % variation)
		assert_true(b.get_theme_stylebox(&"pressed") != b.get_theme_stylebox(&"normal") or variation == &"CardButton", "%s: pressed still differs" % variation)


func test_a_variation_change_keeps_hover_in_step_with_normal() -> void:
	var b: TapButton = _themed(&"Button")
	b.theme_type_variation = &"PrimaryButton"
	b.notification(Control.NOTIFICATION_THEME_CHANGED)
	assert_true(b.get_theme_stylebox(&"hover") == b.get_theme_stylebox(&"normal"))
	b.theme_type_variation = &"Button"
	b.notification(Control.NOTIFICATION_THEME_CHANGED)
	assert_true(b.get_theme_stylebox(&"hover") == b.get_theme_stylebox(&"normal"))


func test_a_tap_button_takes_no_focus() -> void:
	# Touch only: nothing to linger as a focus look, and no keyboard focus is used.
	var b: TapButton = TapButton.new()
	assert_eq(b.focus_mode, Control.FOCUS_NONE)
	b.free()


# p4: the gesture margin.

func test_the_safe_area_keeps_the_gesture_margin_when_the_display_reports_no_bottom_inset() -> void:
	# QA numbers: the cover is 904 x 2316 px shown as 1080 x 2767, camera cutout 85 px,
	# no bottom inset, gesture bar in the bottom 39 px.
	var safe: Rect2 = Layout.safe_in_viewport(Vector2(1080, 2767), Vector2(904, 2316), Vector2.ZERO, Rect2(0, 85, 904, 2231), Layout.GESTURE_MARGIN)
	assert_near(safe.end.y, 2767.0 - Layout.GESTURE_MARGIN, 0.01)
	assert_near(safe.position.y, 85.0 * 1080.0 / 904.0, 0.01, "the top is untouched")
	assert_near(safe.size.x, 1080.0, 0.01)
	var gesture_logical: float = 39.0 * 1080.0 / 904.0
	assert_true(Layout.GESTURE_MARGIN > gesture_logical, "the margin clears the 39 px strip (%.0f logical px)" % gesture_logical)
	assert_true(Layout.GESTURE_MARGIN / 3.14 >= 15.0 and Layout.GESTURE_MARGIN / 2.63 <= 28.0, "about 20 to 25 dp")


func test_a_larger_bottom_inset_is_kept() -> void:
	var safe: Rect2 = Layout.safe_in_viewport(Vector2(1080, 2767), Vector2(904, 2316), Vector2.ZERO, Rect2(0, 85, 904, 2000), Layout.GESTURE_MARGIN)
	assert_near(safe.end.y, 2085.0 * 1080.0 / 904.0, 0.1, "an inset the display reports is not made smaller")


func test_no_margin_without_the_argument() -> void:
	var safe: Rect2 = Layout.safe_in_viewport(Vector2(1080, 2767), Vector2(904, 2316), Vector2.ZERO, Rect2(0, 85, 904, 2231))
	assert_near(safe.end.y, 2767.0, 0.01)


func test_the_margin_applies_to_the_fallback_whole_viewport_and_never_crushes_it() -> void:
	var whole: Rect2 = Layout.safe_in_viewport(Vector2(1080, 2400), Vector2(432, 960), Vector2.ZERO, Rect2(), Layout.GESTURE_MARGIN)
	assert_near(whole.end.y, 2400.0 - Layout.GESTURE_MARGIN, 0.01)
	var tiny: Rect2 = Layout.keep_bottom_clear(Rect2(0, 0, 100, 100), Vector2(100, 100), Layout.GESTURE_MARGIN)
	assert_eq(tiny, Rect2(0, 0, 100, 100), "a window with no room is left as it is")


func test_the_inner_screen_keeps_the_margin_too() -> void:
	# 1812 x 2176 shown as 1998 x 2400, no cutout, gesture bar at the bottom.
	var safe: Rect2 = Layout.safe_in_viewport(Vector2(1998, 2400), Vector2(1812, 2176), Vector2.ZERO, Rect2(0, 0, 1812, 2176), Layout.GESTURE_MARGIN)
	assert_near(safe.end.y, 2400.0 - Layout.GESTURE_MARGIN, 0.01)
	assert_near(safe.size.x, 1998.0, 0.01)
