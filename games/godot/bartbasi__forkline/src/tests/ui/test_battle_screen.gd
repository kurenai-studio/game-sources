# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## BattleScreen on its own, without an App (docs/ARCHITECTURE.md 3.2): taps open the
## right panel, gates place, move and refuse, the clock obeys pause and speed, events
## are drained, and first sights open once each and are recorded in Progress. No
## running scene tree; touches on a real layout are in real_tree_checks.gd.

const Fx: GDScript = preload("res://tests/ui/battle_fixtures.gd")
const NO_CELL: Vector2i = Vector2i(-1, -1)

var screens: Array[BattleScreen] = []


func before_each() -> void:
	screens.clear()


func after_each() -> void:
	for screen: BattleScreen in screens:
		screen.free()


func _screen(battle: Battle, progress: Progress = null) -> BattleScreen:
	var screen: BattleScreen = BattleScreen.new()
	screens.append(screen)
	if progress == null:
		progress = _seen_all(Progress.new())
	screen.setup(battle, null, progress)
	return screen


func _seen_all(progress: Progress) -> Progress:
	for id: StringName in Fx.game().catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in Fx.game().catalog.enemy_ids():
		progress.mark_seen(id)
	for id: StringName in Fx.game().levels:
		progress.mark_seen(id)
	return progress


## A level with two gates, so a second gate can be refused.
func _two_gates() -> Battle:
	var data: Dictionary = Fx.game().levels[&"r1_l2"].to_data()
	data["gates"] = 2
	var level: LevelData = LevelData.from_data(data, Fx.game().catalog)
	return Battle.create(level, Fx.game().catalog, false, [] as Array[Dictionary])


# Taps.

func test_a_tap_on_an_empty_spot_opens_the_build_panel_and_selects_it() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	var spot: Vector2i = screen.battle.level.spots[0]
	screen.tap_at(spot)
	assert_eq(screen.context_panel(), screen.build_panel)
	assert_true(screen.build_panel.is_open())
	assert_eq(screen.selected_cell(), spot)


func test_a_tap_on_a_tower_opens_its_panel() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	var spot: Vector2i = screen.battle.level.spots[0]
	screen.battle.place_tower(spot, &"sling_post")
	screen.tap_at(spot)
	assert_eq(screen.context_panel(), screen.tower_panel)
	assert_true(screen.tower_panel.is_open())


func test_a_tap_on_a_creature_opens_its_numbers() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	screen.battle.start_next_wave()
	Fx.steps(screen.battle, 12)
	var enemy: EnemyState = screen.battle.enemies[0]
	screen.tap_at(Vector2i(3, 1), enemy.id)
	assert_eq(screen.context_panel(), screen.enemy_panel)
	assert_eq(screen.enemy_panel.enemy_id, enemy.id)


func test_a_tap_on_bare_ground_closes_the_panel() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	screen.tap_at(screen.battle.level.spots[0])
	screen.tap_at(Vector2i(0, 0))
	assert_null(screen.context_panel())
	assert_eq(screen.selected_cell(), NO_CELL)
	screen.tap_at(screen.battle.level.spots[0])
	screen.tap_at(NO_CELL)
	assert_null(screen.context_panel(), "a tap outside the map closes it too")


func test_only_one_panel_is_open_and_the_ring_follows() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	var a: Vector2i = screen.battle.level.spots[0]
	var b: Vector2i = screen.battle.level.spots[1]
	screen.tap_at(a)
	screen.tap_at(b)
	assert_eq(screen.selected_cell(), b)
	assert_true(screen.build_panel.is_open())
	screen.battle.place_tower(a, &"sling_post")
	screen.tap_at(a)
	assert_false(screen.build_panel.is_open(), "the build panel closed for the tower panel")
	assert_true(screen.tower_panel.is_open())


func test_a_tower_built_from_the_panel_closes_it() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	var spot: Vector2i = screen.battle.level.spots[0]
	screen.tap_at(spot)
	screen.build_panel.confirm()
	assert_not_null(screen.battle.tower_at(spot))
	assert_null(screen.context_panel())


# The HUD and the clock.

func test_every_battle_starts_at_1x_and_the_hud_sets_the_speed() -> void:
	var screen: BattleScreen = _screen(Fx.battle())
	assert_eq(screen.clock.speed, 1)
	screen.hud.speed_buttons[2].tapped.emit()
	assert_eq(screen.clock.speed, 3)
	assert_eq(_screen(Fx.battle()).clock.speed, 1, "the speed is not remembered between levels")


func test_the_clock_gives_ticks_only_when_a_wave_runs_and_not_paused() -> void:
	var screen: BattleScreen = _screen(Fx.battle())
	screen.frame(0.25)
	assert_eq(screen.battle.tick, 0, "a build phase has no time")
	screen.battle.start_next_wave()
	screen.frame(0.25)
	assert_eq(screen.battle.tick, 5, "a quarter second at 1x is 5 ticks")
	screen.clock.speed = 3
	screen.frame(0.1)
	assert_eq(screen.battle.tick, 11, "at 3x it is three times as many")
	screen.freeze()
	screen.frame(0.25)
	assert_eq(screen.battle.tick, 11, "paused")
	assert_true(screen.is_paused())
	assert_true(screen.hud.paused)
	screen.resume()
	screen.frame(0.1)
	assert_eq(screen.battle.tick, 17)


func test_the_lives_pulse_runs_only_while_the_clock_runs() -> void:
	var screen: BattleScreen = _screen(Fx.battle())
	var box: Control = screen.hud.lives_label.get_parent() as Control
	screen.battle.start_next_wave()
	screen.battle.lives -= 1
	screen.frame(0.1)
	assert_true(screen.hud.pulsing(), "a drop while running pulses")
	screen.frame(0.1)
	assert_true(box.scale.x > 1.0)
	screen.freeze()
	screen.frame(0.05)
	assert_false(screen.hud.pulsing(), "paused: at rest")
	assert_eq(box.scale, Vector2.ONE)
	screen.resume()
	# Behind a card the clock is frozen the same way.
	screen.battle.lives -= 1
	screen.clock.paused = true
	screen.frame(0.1)
	assert_false(screen.hud.pulsing(), "behind a card: at rest")
	assert_eq(box.scale, Vector2.ONE)


func test_events_are_drained_each_frame() -> void:
	var screen: BattleScreen = _screen(Fx.battle())
	screen.battle.start_next_wave()
	screen.frame(0.1)
	assert_true(screen.battle.take_events().is_empty(), "the screen took them")


func test_the_pause_menu_and_the_freeze_save_and_the_menu_resumes() -> void:
	var screen: BattleScreen = _screen(Fx.battle())
	var saves: Array[int] = [0]
	screen.save_requested.connect(func() -> void: saves[0] += 1)
	screen.pause()
	assert_eq(saves[0], 1, "opening Pause asks for a save")
	assert_true(screen.pause_menu_open())
	screen.pause()
	assert_eq(saves[0], 1, "a second call changes nothing")
	var panel: PausePanel = screen.get_children().filter(func(n: Node) -> bool: return n is PausePanel)[0] as PausePanel
	panel.request_close()
	assert_false(screen.is_paused())
	assert_false(screen.pause_menu_open())


func test_a_finished_wave_asks_for_a_save_and_a_win_ends_once() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	var saves: Array[int] = [0]
	var ends: Array[Dictionary] = []
	screen.save_requested.connect(func() -> void: saves[0] += 1)
	screen.ended.connect(func(result: Dictionary) -> void: ends.append(result))
	var b: Battle = screen.battle
	b.gold = 5000
	for cell: Vector2i in b.level.spots:
		b.place_tower(cell, &"sling_post")
		b.upgrade_tower(cell)
	b.start_next_wave()
	Fx.finish_wave(b)
	screen.frame(0.0)
	assert_true(saves[0] >= 1, "the build phase after a wave asks for a save")
	assert_eq(ends.size(), 0)
	while b.phase != Battle.Phase.WON and b.phase != Battle.Phase.LOST:
		b.start_next_wave()
		Fx.finish_wave(b)
	screen.frame(0.0)
	screen.frame(0.0)
	assert_eq(ends.size(), 1, "the end is reported once")
	assert_eq(ends[0]["won"], b.phase == Battle.Phase.WON)


# Gates.

func test_a_tap_on_a_socket_places_and_takes_back_a_gate() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l2"))
	var socket: Vector2i = screen.battle.level.sockets[0]
	screen.tap_at(socket)
	assert_eq(screen.battle.gates.size(), 1)
	assert_eq(screen.battle.gates_in_hand, 0)
	screen.tap_at(socket)
	assert_eq(screen.battle.gates.size(), 0, "a tap on a placed gate takes it back")
	assert_eq(screen.battle.gates_in_hand, 1)


func test_a_socket_with_no_gate_in_hand_says_so() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l2"))
	screen.tap_at(screen.battle.level.sockets[0])
	screen.tap_at(screen.battle.level.sockets[1])
	assert_eq(screen.battle.gates.size(), 1)
	assert_eq(screen.gate_tray.feedback_text(), "No gates left in hand.")


func test_gates_are_locked_during_a_wave_with_the_exact_sentence() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l2"))
	var socket: Vector2i = screen.battle.level.sockets[0]
	screen.tap_at(socket)
	screen.battle.start_next_wave()
	screen.tap_at(socket)
	assert_eq(screen.battle.gates.size(), 1, "the gate stays")
	assert_eq(screen.gate_tray.feedback_text(), "Gates are locked until the wave is over.")
	screen.tap_at(screen.battle.level.sockets[1])
	assert_eq(screen.battle.gates.size(), 1)
	screen.begin_drag(NO_CELL, Vector2(100, 100))
	assert_false(screen.is_dragging(), "no drag starts during a wave")


func test_a_level_with_no_gates_ignores_a_socket_tap() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	assert_true(screen.battle.level.sockets.is_empty())
	assert_false(screen.gate_tray.visible)


func test_the_gate_strip_shows_only_on_a_level_with_gates() -> void:
	var with_gates: BattleScreen = _screen(Fx.battle(&"r1_l2"))
	with_gates.frame(0.0)
	assert_true(with_gates.gate_tray.visible)
	assert_eq(with_gates.gate_tray.title_label.text, "Gates: 1 in hand")
	with_gates.tap_at(with_gates.battle.level.sockets[0])
	with_gates.frame(0.0)
	assert_eq(with_gates.gate_tray.title_label.text, "Gates: all placed")
	with_gates.battle.start_next_wave()
	with_gates.frame(0.0)
	assert_eq(with_gates.gate_tray.title_label.text, "Gates: locked")


func _center(screen: BattleScreen, cell: Vector2i) -> Vector2:
	return screen._socket_center(cell)


## The finger point that puts the carried gate (it floats above the finger) on a cell.
func _finger_for(screen: BattleScreen, cell: Vector2i) -> Vector2:
	return _center(screen, cell) + Vector2(0.0, BattleScreen.GHOST_LIFT * screen._cell_px())


func test_a_dragged_gate_snaps_to_a_socket_and_drops_there() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l2"))
	var socket: Vector2i = screen.battle.level.sockets[1]
	screen.begin_drag(NO_CELL, _finger_for(screen, socket) + Vector2(10.0, 10.0))
	assert_true(screen.is_dragging())
	assert_eq(screen.drag_target(), socket, "the gate snaps to the close socket")
	assert_true(screen.ghost.visible)
	screen.end_drag(_finger_for(screen, socket))
	assert_false(screen.is_dragging())
	assert_false(screen.ghost.visible)
	assert_eq(screen.battle.gates.size(), 1)
	assert_eq(screen.battle.gates[0].cell, socket)


func test_a_drop_away_from_every_socket_changes_nothing() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l2"))
	screen.begin_drag(NO_CELL, Vector2(5.0, 5.0))
	assert_eq(screen.drag_target(), NO_CELL)
	screen.end_drag(Vector2(5.0, 5.0))
	assert_eq(screen.battle.gates.size(), 0)
	assert_eq(screen.battle.gates_in_hand, 1)


func test_a_placed_gate_is_moved_by_a_drag() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l2"))
	var a: Vector2i = screen.battle.level.sockets[0]
	var b: Vector2i = screen.battle.level.sockets[1]
	screen.tap_at(a)
	screen.begin_drag(a, _finger_for(screen, a))
	screen.end_drag(_finger_for(screen, b))
	assert_eq(screen.battle.gates.size(), 1)
	assert_eq(screen.battle.gates[0].cell, b)
	assert_eq(screen.battle.gates_in_hand, 0, "a move does not use another gate")


func test_a_drop_that_would_close_every_road_is_refused_with_the_sentence() -> void:
	var battle: Battle = _two_gates()
	var screen: BattleScreen = _screen(battle)
	var first: Vector2i = battle.level.sockets[0]
	var second: Vector2i = battle.level.sockets[1]
	assert_eq(battle.place_gate(first), Battle.DONE)
	var refusals: Array[StringName] = []
	screen.gate_tray.refused.connect(func(reason: StringName, _text: String) -> void: refusals.append(reason))
	screen.begin_drag(NO_CELL, _finger_for(screen, second))
	assert_eq(screen.drag_target(), second)
	screen.end_drag(_finger_for(screen, second))
	assert_eq(battle.gates.size(), 1, "the gate does not stay")
	assert_eq(battle.gates_in_hand, 1, "and is still in hand")
	assert_eq(refusals, [&"would_seal"] as Array[StringName])
	assert_eq(screen.gate_tray.feedback_text(), "That would close every road.")


func test_the_carried_gate_looks_crossed_out_over_a_refused_socket() -> void:
	var battle: Battle = _two_gates()
	var screen: BattleScreen = _screen(battle)
	battle.place_gate(battle.level.sockets[0])
	screen.begin_drag(NO_CELL, _finger_for(screen, battle.level.sockets[1]))
	assert_eq(screen.ghost.look, MapArt.Gate.REFUSED)
	screen.move_drag(Vector2(5.0, 5.0))
	assert_eq(screen.ghost.look, MapArt.Gate.CLOSED)
	screen.cancel_drag()
	assert_false(screen.ghost.visible)


func test_a_drag_in_progress_is_cancelled_by_a_layout_change_and_a_wave() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l2"))
	screen.begin_drag(NO_CELL, Vector2(5.0, 5.0))
	screen.apply_layout(Vector2(1080.0, 2767.0), Rect2(0.0, 96.0, 1080.0, 2500.0))
	assert_false(screen.is_dragging(), "a touch in progress is cancelled by a layout change")
	assert_eq(screen.battle.gates.size(), 0)
	screen.begin_drag(NO_CELL, Vector2(5.0, 5.0))
	screen.battle.start_next_wave()
	screen.frame(0.05)
	assert_false(screen.is_dragging(), "gates lock when the wave starts")


# First sights.

func test_first_sights_open_once_each_and_are_recorded() -> void:
	var progress: Progress = Progress.new()
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"), progress)
	assert_true(screen.card_open(), "the first level opens its cards by itself")
	for id: StringName in [&"sling_post", &"pumpkin_catapult", &"scamp", &"r1_l1"]:
		assert_false(progress.seen.has(id), "%s is not recorded before the card is closed" % id)
	assert_true(screen.hint_banner.visible, "and the level's hint shows")
	assert_eq(screen.hint_banner.text_label.text, screen.battle.level.hint_text)
	var left_open: BattleScreen = _screen(Fx.battle(&"r1_l1"), progress)
	assert_true(left_open.card_open(), "a card that was never closed opens again")
	screen._card.request_close()
	assert_false(screen.card_open())
	for id: StringName in [&"sling_post", &"pumpkin_catapult", &"scamp"]:
		assert_true(progress.seen.has(id), "%s is recorded once the card is closed" % id)
	assert_false(progress.seen.has(&"r1_l1"), "the hint is recorded when it is closed, not when it shows")
	screen.hint_banner.dismiss()
	assert_true(progress.seen.has(&"r1_l1"))
	var again: BattleScreen = _screen(Fx.battle(&"r1_l1"), progress)
	assert_false(again.card_open(), "never a second time")
	assert_false(again.hint_banner.visible)


func test_a_creature_card_opens_in_the_build_phase_before_its_first_wave() -> void:
	var battle: Battle = Fx.battle(&"r1_l4")
	battle.gold = 100000
	for cell: Vector2i in battle.level.spots:
		battle.place_tower(cell, &"sling_post")
		battle.upgrade_tower(cell)
	var index: int = -1
	for i: int in battle.wave_count():
		for entry: Dictionary in battle.wave_preview(i):
			if entry["enemy"] == &"pip" and index < 0:
				index = i
	assert_true(index >= 0, "level 1-4 brings pips")
	while battle.waves_started < index:
		battle.start_next_wave()
		Fx.finish_wave(battle)
	assert_eq(battle.phase, Battle.Phase.BUILD)
	var progress: Progress = _seen_all(Progress.new())
	progress.seen.erase(&"pip")
	var screen: BattleScreen = _screen(battle, progress)
	assert_true(screen.card_open(), "the card opens in the build phase before the wave")
	assert_eq(screen._card.items.size(), 1, "only the new creature")
	assert_eq(screen._card.items[0]["id"], &"pip")
	assert_false(progress.seen.has(&"pip"), "counted only when the card is closed")
	screen._card.advance()
	assert_true(progress.seen.has(&"pip"))
	assert_false(screen.hint_banner.visible, "the hint is for the first start of a level only")


func test_the_preview_tags_creatures_not_met_yet() -> void:
	var progress: Progress = _seen_all(Progress.new())
	progress.seen.erase(&"flitter")
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"), progress)
	assert_false(screen.card_open(), "flitters are not in wave 1, so no card yet")
	assert_true(screen.preview._unseen.has(&"flitter"), "but the preview would tag them")
	assert_false(screen.preview._unseen.has(&"scamp"))


func test_the_first_sight_card_pages_through_its_items_and_marks_nothing_twice() -> void:
	var battle: Battle = Fx.battle(&"r1_l1")
	var items: Array[Dictionary] = [
		{"kind": &"tower", "id": &"sling_post", "wave": 0},
		{"kind": &"enemy", "id": &"scamp", "wave": 0},
	]
	var card: InfoCard = InfoCard.new(battle, items)
	var closed: Array[int] = [0]
	card.finished.connect(func() -> void: closed[0] += 1)
	assert_eq(card.next_button.text, "Next")
	assert_eq(card.name_label.text, battle.catalog.tower(&"sling_post").name, "the name comes from the Catalog")
	assert_eq(card.info_label.text, battle.catalog.tower(&"sling_post").info)
	card.advance()
	assert_eq(card.name_label.text, battle.catalog.enemy(&"scamp").name)
	assert_eq(card.next_button.text, "Got it")
	card.advance()
	assert_eq(closed[0], 1)
	card.free()
