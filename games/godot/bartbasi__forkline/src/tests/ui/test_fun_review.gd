# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Task U1: the fixes Bart approved after the region 1 playtest (FUN_REVIEW_R1 items 2 to 6, 8
## and 9, and "Upgrade no towers."), the stars in Pause and their warnings, the 2-1 call
## button ring, the one line strip, every region in the level list, the Bell, Bakery and new
## creatures in the panels, and the new towers and creatures in Info. Layout and the dock are
## in real_tree_checks.gd.

const Fx: GDScript = preload("res://tests/ui/battle_fixtures.gd")
const Flow: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const TAG: String = "fun_review"
const CHIP_SENTENCE: String = "Drag one onto a marked road, or tap a marked road."

var keep: Array[Node] = []


func after_each() -> void:
	for node: Node in keep:
		if is_instance_valid(node):
			node.free()
	keep.clear()


func _keep(node: Node) -> Node:
	keep.append(node)
	return node


func _seen_all() -> Progress:
	var progress: Progress = Progress.new()
	for id: StringName in Fx.game().catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in Fx.game().catalog.enemy_ids():
		progress.mark_seen(id)
	for id: StringName in Fx.game().levels:
		progress.mark_seen(id)
	return progress


func _screen(battle: Battle, progress: Progress = null) -> BattleScreen:
	var screen: BattleScreen = _keep(BattleScreen.new()) as BattleScreen
	screen.setup(battle, null, progress if progress != null else _seen_all())
	return screen


func _texts(root: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return out


func _stat_value(panel: Node, label: String) -> String:
	for node: Node in panel.find_children("*", "StatRow", true, false):
		var row: StatRow = node as StatRow
		if row.name_label.text == label and row.value_label != null:
			return row.value_label.text
	return "<missing %s>" % label


func _mouse(control: Control, pressed: bool, at: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	control.call("_gui_input", event)


func _move(control: Control, at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	control.call("_gui_input", event)


# "Upgrade no towers." (item 4).

func test_a_tier_cap_of_1_reads_upgrade_no_towers_and_a_cap_of_2_does_not() -> void:
	var game: GameData = Fx.game()
	for id: StringName in [&"r1_l1", &"r1_l2", &"r1_l4"]:
		assert_eq(StarText.challenge(game.levels[id], game.catalog), "Upgrade no towers.", id)
	for id: StringName in [&"r1_l5", &"r2_l3"]:
		assert_eq(StarText.challenge(game.levels[id], game.catalog), "No tower above tier 2.", id)
	var card: LevelCard = _keep(LevelCard.new(game, Progress.new(), &"r1_l1", false)) as LevelCard
	assert_eq(card.star_sentences[2].text, "Upgrade no towers.", "the level card says it before a tier is seen")


# Star lines in Pause (item 2, RULES 10.6).

func test_play_lines_say_earned_not_yet_lost_and_normal_only() -> void:
	var game: GameData = Fx.game()
	var level: LevelData = game.levels[&"r1_l1"]
	var fresh: Array[Dictionary] = StarText.play_lines(level, game.catalog, 0, 7, false)
	assert_eq([fresh[0]["state"], fresh[1]["state"], fresh[2]["state"]], ["Not yet", "Not yet", "Not yet"])
	assert_eq(fresh[0]["text"], "Win the level.")
	assert_eq(fresh[1]["text"], "Keep 15 lives.")
	assert_eq(fresh[2]["text"], "Upgrade no towers.")
	var mixed: Array[Dictionary] = StarText.play_lines(level, game.catalog, 1, 1 | 4, false)
	assert_eq([mixed[0]["state"], mixed[1]["state"], mixed[2]["state"]], ["Earned", "Lost", "Not yet"])
	assert_eq([mixed[0]["struck"], mixed[1]["struck"], mixed[2]["struck"]], [false, true, false], "only a lost line is struck through")
	var earned_and_gone: Array[Dictionary] = StarText.play_lines(level, game.catalog, 4, 1, false)
	assert_eq(earned_and_gone[2]["state"], "Earned", "a star the player already has stays earned, whatever this game does")
	assert_false(earned_and_gone[2]["struck"])
	var relaxed: Array[Dictionary] = StarText.play_lines(level, game.catalog, 0, 1, true)
	assert_eq([relaxed[0]["state"], relaxed[1]["state"], relaxed[2]["state"]], ["Not yet", "Normal only", "Normal only"])
	assert_eq([relaxed[1]["struck"], relaxed[2]["struck"]], [false, false], "nothing was lost, so nothing is struck through")
	var relaxed_earned: Array[Dictionary] = StarText.play_lines(level, game.catalog, 2, 1, true)
	assert_eq(relaxed_earned[1]["state"], "Earned", "a star already earned shows as earned on Relaxed too")


func test_pause_shows_the_three_star_lines_of_the_level() -> void:
	var b: Battle = Fx.battle(&"r1_l1")
	var screen: BattleScreen = _screen(b)
	screen.pause()
	var pause: PausePanel = screen._pause_panel
	assert_eq(pause.star_lines.size(), 3)
	assert_eq([pause.star_lines[0].state, pause.star_lines[1].state, pause.star_lines[2].state], ["Not yet", "Not yet", "Not yet"])
	assert_eq(pause.star_lines[2].sentence_text(), "Upgrade no towers.")
	assert_true(_texts(pause).has("Stars"))
	for line: StarLine in pause.star_lines:
		assert_false(line.struck)
		assert_true(line.state_label.visible)


func test_a_lost_star_is_struck_through_and_says_lost() -> void:
	var b: Battle = Fx.battle(&"r1_l1")
	b.gold = 5000
	b.place_tower(b.level.spots[0], b.level.towers[0])
	b.lives = 14
	assert_eq(b.upgrade_tower(b.level.spots[0]), Battle.DONE)
	var screen: BattleScreen = _screen(b)
	screen.pause()
	var lines: Array[StarLine] = screen._pause_panel.star_lines
	assert_eq([lines[0].state, lines[1].state, lines[2].state], ["Not yet", "Lost", "Lost"])
	assert_false(lines[0].struck)
	assert_true(lines[1].struck and lines[2].struck)
	assert_true(lines[1].sentence.text.begins_with("[s]") and lines[1].sentence.text.ends_with("[/s]"), "the sentence is struck through")
	assert_eq(lines[1].sentence_text(), "Keep 15 lives.")
	assert_false(lines[0].sentence.text.contains("[s]"))
	# Selling the tower afterwards does not bring the star back.
	b.sell_tower(b.level.spots[0])
	screen._pause_panel.set_stars(screen.star_entries())
	assert_eq(screen._pause_panel.star_lines[2].state, "Lost", "a tower sold after going over the cap still counts")


func test_stars_the_player_already_has_say_earned() -> void:
	var progress: Progress = _seen_all()
	progress.record_level(&"r1_l1", 1 | 4)
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"), progress)
	screen.pause()
	var lines: Array[StarLine] = screen._pause_panel.star_lines
	assert_eq([lines[0].state, lines[1].state, lines[2].state], ["Earned", "Not yet", "Earned"])
	assert_true(lines[0].icon.earned and lines[2].icon.earned and not lines[1].icon.earned)


func test_on_relaxed_lines_2_and_3_say_normal_only() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1", true))
	screen.pause()
	var lines: Array[StarLine] = screen._pause_panel.star_lines
	assert_eq([lines[0].state, lines[1].state, lines[2].state], ["Not yet", "Normal only", "Normal only"])
	assert_false(lines[1].struck or lines[2].struck)


func test_the_early_call_star_is_lost_when_too_few_waves_are_left() -> void:
	var b: Battle = Fx.battle(&"r2_l1")
	assert_eq(b.level.star3["kind"], &"early_calls_at_least")
	var screen: BattleScreen = _screen(b)
	assert_eq(screen.star_entries()[2]["state"], "Not yet")
	b.waves_started = b.wave_count() - 1
	assert_eq(screen.star_entries()[2]["state"], "Lost", "one wave left cannot make six early calls")
	assert_true(screen.star_entries()[2]["struck"])


func test_a_twist_or_a_run_has_no_star_lines() -> void:
	var level: LevelData = Fx.game().levels[&"r2_l1"]
	assert_false(level.twist_effects.is_empty(), "r2_l1 has a Twist")
	var twist: Battle = Battle.create(level, Fx.game().catalog, false, level.twist_effects)
	var twist_screen: BattleScreen = _screen(twist)
	assert_false(twist_screen.has_stars())
	assert_true(twist_screen.star_entries().is_empty())
	twist_screen.pause()
	assert_true(twist_screen._pause_panel.star_lines.is_empty(), "Pause of a Twist shows no star lines")
	var run: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	run.stars_in_play = false
	assert_true(run.star_entries().is_empty(), "a run is not a campaign level")


# Warnings before a tap (item 2).

func _two_towers(id: StringName, relaxed: bool = false) -> Battle:
	var b: Battle = Fx.battle(id, relaxed)
	b.gold = 100000
	b.place_tower(b.level.spots[0], b.level.towers[0])
	b.place_tower(b.level.spots[1], b.level.towers[0])
	return b


func test_a_third_tower_on_a_two_tower_level_warns_in_the_build_panel() -> void:
	var b: Battle = Fx.battle(&"r1_l3")
	assert_eq(b.level.star3["kind"], &"towers_at_most")
	b.gold = 100000
	var screen: BattleScreen = _screen(b)
	screen.show_build(b.level.spots[0])
	assert_null(screen.build_panel.star_warning_label, "the first tower is safe")
	b.place_tower(b.level.spots[0], b.level.towers[0])
	screen.show_build(b.level.spots[1])
	assert_null(screen.build_panel.star_warning_label, "so is the second")
	b.place_tower(b.level.spots[1], b.level.towers[0])
	screen.show_build(b.level.spots[2])
	assert_not_null(screen.build_panel.star_warning_label, "the third breaks the limit")
	assert_eq(screen.build_panel.star_warning_label.text, "Loses the third star.")
	assert_true(screen.build_panel.star_warning_label.get_parent() is StarNote)
	b.sell_tower(b.level.spots[1])
	screen.build_panel.refresh()
	assert_null(screen.build_panel.star_warning_label, "after selling one it is safe again")


func test_a_banned_tower_warns_and_the_others_do_not() -> void:
	var b: Battle = Fx.battle(&"r2_l5")
	assert_eq(b.level.star3["tower"], &"longbow_loft")
	var screen: BattleScreen = _screen(b)
	screen.show_build(b.level.spots[0])
	screen.build_panel.select_tower(&"sling_post")
	assert_null(screen.build_panel.star_warning_label)
	screen.build_panel.select_tower(&"longbow_loft")
	assert_not_null(screen.build_panel.star_warning_label, "the banned tower warns")
	screen.build_panel.select_tower(&"lullaby_bell")
	assert_null(screen.build_panel.star_warning_label)


func test_a_new_kind_over_the_kinds_limit_warns_and_a_kind_already_built_does_not() -> void:
	var b: Battle = Fx.battle(&"r2_l6")
	assert_eq(b.level.star3["kind"], &"kinds_at_most")
	b.gold = 100000
	var kinds: Array[StringName] = [&"sling_post", &"pumpkin_catapult", &"lullaby_bell"]
	for i: int in 3:
		assert_eq(b.place_tower(b.level.spots[i], kinds[i]), Battle.DONE)
	var screen: BattleScreen = _screen(b)
	screen.show_build(b.level.spots[3])
	screen.build_panel.select_tower(&"sling_post")
	assert_null(screen.build_panel.star_warning_label, "a kind already built is no new kind")
	screen.build_panel.select_tower(&"longbow_loft")
	assert_not_null(screen.build_panel.star_warning_label, "a fourth kind breaks the limit")


func test_an_upgrade_warns_from_the_sim_and_a_tower_sold_over_the_cap_ends_the_warning() -> void:
	var b: Battle = _two_towers(&"r1_l1")
	var panel: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
	panel.setup(b)
	panel.show_tower(b.level.spots[1])
	assert_not_null(panel.star_warning_label, "tier 2 breaks 'Upgrade no towers.'")
	assert_eq(b.upgrade_tower(b.level.spots[0]), Battle.DONE)
	assert_eq(b.sell_tower(b.level.spots[0]), Battle.DONE)
	panel.show_tower(b.level.spots[1])
	assert_null(panel.star_warning_label, "no tower is above the cap now, but the star is gone, so no warning")


func test_there_are_no_warnings_on_relaxed_in_a_twist_or_once_star_3_is_earned() -> void:
	var relaxed: BattleScreen = _screen(_two_towers(&"r1_l1", true))
	relaxed.show_tower(relaxed.battle.level.spots[0])
	assert_null(relaxed.tower_panel.star_warning_label, "Relaxed")
	var earned: Progress = _seen_all()
	earned.record_level(&"r1_l1", 4)
	var done: BattleScreen = _screen(_two_towers(&"r1_l1"), earned)
	done.show_tower(done.battle.level.spots[0])
	assert_null(done.tower_panel.star_warning_label, "star 3 already earned")
	var open: BattleScreen = _screen(_two_towers(&"r1_l1"))
	open.show_tower(open.battle.level.spots[0])
	assert_not_null(open.tower_panel.star_warning_label, "and the same game warns when it is not earned")
	var level: LevelData = Fx.game().levels[&"r1_l1"]
	var twist: Battle = Battle.create(level, Fx.game().catalog, false, [{"type": "speed_pct", "pct": 120}] as Array[Dictionary])
	twist.gold = 100000
	twist.place_tower(level.spots[0], level.towers[0])
	var twist_screen: BattleScreen = _screen(twist)
	twist_screen.show_tower(level.spots[0])
	assert_null(twist_screen.tower_panel.star_warning_label, "a Twist has no stars")


func test_a_gate_over_the_gate_rule_says_the_star_is_lost_if_a_wave_starts() -> void:
	var b: Battle = Fx.battle(&"r1_l6")
	assert_eq(b.level.star3["kind"], &"gates_at_most")
	assert_eq(int(b.level.star3["value"]), 0)
	var screen: BattleScreen = _screen(b)
	screen.tap_socket(b.level.sockets[0])
	assert_eq(b.gates.size(), 1, "placing it loses nothing")
	assert_eq(screen.gate_tray.feedback_text(), "Start a wave with this gate and the third star is lost.")
	screen.tap_socket(b.level.sockets[0])
	assert_eq(b.gates.size(), 0, "the player can still take it back")
	assert_eq(screen.gate_tray.feedback_text(), "", "and the warning goes with it")


func test_the_second_gate_warns_on_a_one_gate_rule_and_the_first_does_not() -> void:
	var b: Battle = Fx.battle(&"r2_l4")
	assert_eq(int(b.level.star3["value"]), 1)
	assert_eq(b.gates_in_hand, 2)
	var screen: BattleScreen = _screen(b)
	screen.tap_socket(b.level.sockets[0])
	assert_eq(screen.gate_tray.feedback_text(), "", "one gate is within the rule")
	for socket: Vector2i in b.level.sockets:
		if b.gates.size() < 2:
			screen.tap_socket(socket)
	assert_eq(b.gates.size(), 2)
	assert_eq(screen.gate_tray.feedback_text(), StarNote.GATE_TEXT)


func test_a_gate_does_not_warn_on_a_level_with_another_rule_or_after_the_star_is_lost() -> void:
	var plain: BattleScreen = _screen(Fx.battle(&"r1_l2"))
	plain.tap_socket(plain.battle.level.sockets[0])
	assert_eq(plain.battle.gates.size(), 1)
	assert_eq(plain.gate_tray.feedback_text(), "")
	# On a gate rule level, once a wave has started with too many gates the star is gone.
	var b: Battle = Fx.battle(&"r1_l6")
	var screen: BattleScreen = _screen(b)
	screen.tap_socket(b.level.sockets[0])
	b.start_next_wave()
	assert_eq(b.stars_possible() & 4, 0, "a wave started with a gate on a no gate level")
	assert_false(screen.gate_tray.warns(&"gate"))


# The call button (item 3) and its ring on 2-1.

func _hud(b: Battle) -> BattleHud:
	var hud: BattleHud = _keep(BattleHud.new()) as BattleHud
	hud.refresh(b)
	return hud


func test_honey_is_only_for_start_wave_and_an_early_call_keeps_the_plain_look() -> void:
	var b: Battle = Fx.battle(&"r1_l1")
	var hud: BattleHud = _hud(b)
	assert_eq(hud.call_button.text, "Start wave 1")
	assert_eq(hud.call_button.theme_type_variation, &"PrimaryButton")
	hud.call_button.tapped.emit()
	Fx.steps(b, 120)
	hud.refresh()
	var info: Dictionary = b.next_wave_info()
	assert_eq(info["refusal"], &"")
	assert_true(bool(info["early"]))
	assert_eq(hud.call_button.text, "Call wave 2  +%d" % int(info["bonus"]), "the early call keeps its +N")
	assert_eq(hud.call_button.theme_type_variation, &"Button", "but not the honey look")
	assert_null(hud.call_button.icon, "and no lock: it can be called")


func test_a_call_that_cannot_be_made_yet_wears_a_lock() -> void:
	var b: Battle = Fx.battle(&"r1_l1")
	var hud: BattleHud = _hud(b)
	hud.call_button.tapped.emit()
	hud.refresh()
	assert_eq(hud.call_button.text, "Call wave 2")
	assert_eq(hud.call_button.theme_type_variation, &"Button")
	assert_not_null(hud.call_button.icon, "the wave is still arriving: a lock shows")


func test_the_call_ring_shows_on_2_1_only_while_an_early_call_is_offered_until_the_first_one() -> void:
	var b: Battle = Fx.battle(&"r2_l1")
	assert_eq(b.level.hint_button, &"call")
	var hud: BattleHud = _hud(b)
	assert_false(hud.call_ring.visible, "never in a build phase, where the button starts the wave")
	hud.call_button.tapped.emit()
	hud.refresh()
	assert_false(hud.call_ring.visible, "not while the wave is still arriving")
	Fx.steps(b, 160)
	hud.refresh()
	assert_eq(b.next_wave_info()["refusal"], &"")
	assert_true(hud.call_ring.visible, "an early call is offered")
	assert_true(hud.call_ring.is_processing(), "and the ring pulses")
	assert_eq(hud.call_button.theme_type_variation, &"Button", "the ring is the only glow: the button is not honey")
	hud.call_button.tapped.emit()
	assert_false(hud.call_ring.visible, "the first early call puts the ring away")
	for i: int in 400:
		Fx.steps(b, 1)
		hud.refresh()
		assert_false(hud.call_ring.visible, "and it never comes back on this screen")


func test_other_levels_never_show_the_call_ring() -> void:
	var b: Battle = Fx.battle(&"r1_l1")
	var hud: BattleHud = _hud(b)
	hud.call_button.tapped.emit()
	Fx.steps(b, 160)
	hud.refresh()
	assert_eq(b.next_wave_info()["refusal"], &"")
	assert_false(hud.call_ring.visible)


# The gate chip's tap (item 6).

func _tray(b: Battle, chip: bool = true) -> GateTray:
	var tray: GateTray = _keep(GateTray.new()) as GateTray
	tray.setup(b)
	tray.set_wide(chip)
	tray.set_chip(chip)
	tray.refresh()
	return tray


func _tap(tray: GateTray) -> void:
	_mouse(tray, true, Vector2(40.0, 40.0))
	_mouse(tray, false, Vector2(40.0, 40.0))


func test_a_tap_on_the_portrait_chip_shows_its_sentence() -> void:
	var b: Battle = Fx.battle(&"r1_l2")
	var tray: GateTray = _tray(b)
	assert_eq(tray.feedback_text(), "")
	_tap(tray)
	assert_eq(tray.feedback_text(), CHIP_SENTENCE)
	assert_true(tray.feedback_box.visible)


func test_the_chip_sentence_follows_the_state() -> void:
	var b: Battle = Fx.battle(&"r1_l2")
	var tray: GateTray = _tray(b)
	b.place_gate(b.level.sockets[0])
	tray.refresh()
	_tap(tray)
	assert_eq(tray.feedback_text(), "Drag a gate to move it. Tap a gate to take it back.")
	b.start_next_wave()
	tray.refresh()
	_tap(tray)
	assert_eq(tray.feedback_text(), "Gates are locked until the wave is over.")


func test_a_drag_from_the_chip_is_not_a_tap_and_the_landscape_strip_needs_no_tap() -> void:
	var b: Battle = Fx.battle(&"r1_l2")
	var tray: GateTray = _tray(b)
	var began: Array[bool] = []
	tray.drag_began.connect(func(_at: Vector2) -> void: began.append(true))
	_mouse(tray, true, Vector2(40.0, 40.0))
	_move(tray, Vector2(40.0, 140.0))
	_mouse(tray, false, Vector2(40.0, 140.0))
	assert_eq(began.size(), 1, "the drag began")
	assert_eq(tray.feedback_text(), "", "and it showed no sentence")
	var strip: GateTray = _tray(Fx.battle(&"r1_l2"), false)
	_tap(strip)
	assert_eq(strip.feedback_text(), "", "the landscape strip already shows its sentences")


# The wave cleared message (item 8) and the events that show nothing.

func test_a_cleared_wave_says_what_it_paid() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	screen._handle([{"kind": &"wave_cleared", "wave": 2, "gold": 35}] as Array[Dictionary])
	assert_eq(screen.hud.feedback_text(), "Wave 3 cleared: +35 gold.")
	screen.hud.clear_feedback()
	screen._handle([{"kind": &"wave_cleared", "wave": 0, "gold": 0}] as Array[Dictionary])
	assert_eq(screen.hud.feedback_text(), "Wave 1 cleared.")


func test_a_wave_cleared_in_play_shows_its_bonus_in_the_dock() -> void:
	var b: Battle = Fx.battle(&"r1_l1")
	b.gold = 100000
	for i: int in b.level.spots.size():
		b.place_tower(b.level.spots[i], b.level.towers[0])
	var screen: BattleScreen = _screen(b)
	screen.hud.call_button.tapped.emit()
	Flow.run(screen, 4000, func() -> bool: return b.phase == Battle.Phase.BUILD)
	assert_eq(b.phase, Battle.Phase.BUILD, "the wave was cleared")
	assert_eq(screen.hud.feedback_text(), "Wave 1 cleared: +%d gold." % b._clear_bonus(0))


func test_released_break_started_sped_up_and_interest_show_no_message() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"))
	var events: Array[Dictionary] = [
		{"kind": &"released", "id": 1, "source": &"puffball", "enemy": &"puff", "count": 3, "pos": Vector2i.ZERO},
		{"kind": &"break_started", "id": 2, "cell": Vector2i(1, 1)},
		{"kind": &"sped_up", "id": 3, "speed": 50},
		{"kind": &"interest", "gold": 7},
	]
	screen._handle(events)
	assert_eq(screen.hud.feedback_text(), "")
	assert_eq(screen.gate_tray.feedback_text(), "")


# The loss line (item 9).

func test_a_normal_loss_points_to_relaxed_with_the_number_from_the_data() -> void:
	var game: GameData = Fx.game()
	var loss: Dictionary = {"won": false, "stars": 0, "lives_left": 0, "waves_cleared": 3, "relaxed": false}
	var panel: EndPanel = _keep(EndPanel.new(game, &"r1_l1", loss, 0, &"r1_l2")) as EndPanel
	assert_not_null(panel.relaxed_label)
	assert_eq(panel.relaxed_label.text, "Stuck? Relaxed gives 40 lives and more gold.")
	assert_eq(EndPanel.relaxed_hint(game), "Stuck? Relaxed gives %d lives and more gold." % (game.catalog.rules.start_lives * game.catalog.rules.relaxed_lives_pct / 100))


func test_no_relaxed_line_after_a_win_a_relaxed_loss_or_a_twist() -> void:
	var game: GameData = Fx.game()
	var win: Dictionary = {"won": true, "stars": 7, "lives_left": 20, "waves_cleared": 8, "relaxed": false}
	assert_null((_keep(EndPanel.new(game, &"r1_l1", win, 0, &"r1_l2")) as EndPanel).relaxed_label, "a win")
	var easy: Dictionary = {"won": false, "stars": 0, "lives_left": 0, "waves_cleared": 3, "relaxed": true}
	assert_null((_keep(EndPanel.new(game, &"r1_l1", easy, 0, &"r1_l2")) as EndPanel).relaxed_label, "a Relaxed loss")
	var twist: Dictionary = {"won": false, "stars": 0, "lives_left": 0, "waves_cleared": 3, "relaxed": false, "twist": true}
	assert_null((_keep(EndPanel.new(game, &"r1_l1", twist, 0, &"r1_l2")) as EndPanel).relaxed_label, "a Twist")


# The one line strip (RULES 9.1).

func test_the_strip_shows_what_fits_then_a_count_of_the_rest() -> void:
	var widths: Array[float] = [100.0, 100.0, 100.0]
	assert_eq(StripRow.count_that_fit(widths, 50.0, 400.0), 3, "all fit")
	assert_eq(StripRow.count_that_fit(widths, 50.0, 300.0), 1, "two chips and the tag do not fit 300, one does")
	assert_eq(StripRow.count_that_fit(widths, 50.0, 100.0), 0, "only the tag fits")
	assert_eq(StripRow.count_that_fit([] as Array[float], 50.0, 100.0), 0)
	assert_eq(StripRow.count_that_fit(widths, 50.0, 3.0 * 100.0 + 2.0 * StripRow.GAP), 3, "exactly full")


func test_a_folded_preview_has_one_chip_per_group_in_spawn_order() -> void:
	var b: Battle = Fx.battle(&"r1_l1")
	var preview: WavePreview = _keep(WavePreview.new()) as WavePreview
	preview.setup(b)
	assert_null(preview.strip, "open in a build phase: no strip")
	preview.toggle()
	assert_not_null(preview.strip)
	assert_eq(preview.strip.chip_count(), b.wave_preview(0).size())
	preview.toggle()
	assert_null(preview.strip, "an open preview has no strip")


func test_the_preview_says_when_a_build_phase_began() -> void:
	var b: Battle = Fx.battle(&"r1_l1")
	var preview: WavePreview = _keep(WavePreview.new()) as WavePreview
	var began: Array[int] = []
	preview.build_began.connect(func() -> void: began.append(1))
	preview.setup(b)
	assert_eq(began.size(), 1, "the first build phase")
	b.start_next_wave()
	preview.refresh()
	assert_eq(began.size(), 1, "a wave is not a build phase")
	Fx.finish_wave(b)
	preview.refresh()
	assert_eq(began.size(), 2, "the next build phase")
	preview.set_open(false)
	assert_false(preview.expanded)
	preview.set_open(true)
	assert_true(preview.expanded)


func test_a_junction_is_a_road_cell_with_three_or_four_road_neighbors() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r2_l1"))
	assert_true(screen._is_junction(Vector2i(2, 2)), "a fork on 2-1")
	assert_false(screen._is_junction(Vector2i(0, 2)), "the end of a road")
	assert_false(screen._is_junction(Vector2i(2, 6)), "a plain bend or straight")
	assert_false(screen._is_junction(Vector2i(3, 1)), "scenery")


# The level list shows every region with its unlock (RULES 16).

func test_the_level_list_shows_every_region_and_every_level_of_the_campaign() -> void:
	var game: GameData = Fx.game()
	var list: LevelSelect = _keep(LevelSelect.new()) as LevelSelect
	list.populate(game, Progress.new(), &"")
	var total: int = 0
	for region: Dictionary in game.campaign:
		total += (region["levels"] as Array).size()
	assert_eq(list.rows.size(), total)
	assert_eq(list.region_labels.size(), game.campaign.size())
	assert_true(game.campaign.size() >= 2, "region 2 is in the campaign")
	for id: StringName in game.levels:
		assert_true(list.rows.has(id), "%s is in the list" % id)


func test_region_2_opens_with_level_1_6_cleared_and_6_stars() -> void:
	var game: GameData = Fx.game()
	var list: LevelSelect = _keep(LevelSelect.new()) as LevelSelect
	var progress: Progress = Progress.new()
	list.populate(game, progress, &"")
	assert_true(list.rows[&"r2_l1"].overlay.disabled, "locked at the start")
	assert_true(_texts(list).has("Locked. Clear level 1-6 and earn 6 stars."))
	assert_true(_texts(list.rows[&"r2_l2"]).has("Clear level 2-1 first."))
	progress.record_level(&"r1_l6", 1)
	list.populate(game, progress, &"")
	assert_true(list.rows[&"r2_l1"].overlay.disabled, "level 1-6 alone is not enough: 6 stars are needed")
	for n: int in range(1, 6):
		progress.record_level(StringName("r1_l%d" % n), 1)
	list.populate(game, progress, &"")
	assert_false(list.rows[&"r2_l1"].overlay.disabled, "six levels cleared open region 2")
	assert_true(list.rows[&"r2_l2"].overlay.disabled, "its second level waits for the first")
	assert_false(_texts(list).has("Locked. Clear level 1-6 and earn 6 stars."))
	progress.record_level(&"r2_l1", 1)
	list.populate(game, progress, &"")
	assert_false(list.rows[&"r2_l2"].overlay.disabled)


func test_a_four_region_campaign_lists_each_region_with_its_own_unlock() -> void:
	var game: GameData = Fx.four_region_game()
	var list: LevelSelect = _keep(LevelSelect.new()) as LevelSelect
	var progress: Progress = Progress.new()
	list.populate(game, progress, &"")
	assert_eq(list.rows.size(), 24)
	assert_eq(list.region_labels.size(), 4)
	assert_eq(list.region_labels[3].text, "Region 4: Fixture region 4")
	var texts: PackedStringArray = _texts(list)
	assert_true(texts.has("Locked. Clear level 1-6 and earn 6 stars."))
	assert_true(texts.has("Locked. Clear level 2-6 and earn 12 stars."))
	assert_true(texts.has("Locked. Clear level 3-6 and earn 18 stars."))
	assert_false(list.rows[&"x1_l1"].overlay.disabled)
	for id: StringName in [&"x2_l1", &"x3_l1", &"x4_l1"]:
		assert_true(list.rows[id].overlay.disabled, "%s is locked" % id)
	# Six stars at one per level open region 2, twelve open region 3, eighteen region 4.
	for region: int in 3:
		for n: int in 6:
			progress.record_level(StringName("x%d_l%d" % [region + 1, n + 1]), 1)
		list.populate(game, progress, &"")
		var next_first: StringName = StringName("x%d_l1" % [region + 2])
		assert_false(list.rows[next_first].overlay.disabled, "%s opens after region %d is cleared" % [next_first, region + 1])
	assert_false(_texts(list).has("Locked. Clear level 3-6 and earn 18 stars."))


# The Bell, the Bakery and the new creatures in the panels (RULES 9.3, 9.4).

func _build_all(b: Battle, type: StringName, cell: Vector2i) -> void:
	b.gold = 1000000
	assert_eq(b.place_tower(cell, type), Battle.DONE)


func _check_rows(panel: TowerPanel, b: Battle, cell: Vector2i, where: String) -> void:
	var numbers: Dictionary = b.tower_numbers(cell)
	var kind: StringName = b.catalog.tower(b.tower_at(cell).type).kind
	var reach: String = BattleText.tiles_text(int(numbers["reach"]))
	if kind == &"slow":
		assert_eq(_stat_value(panel, "Slow"), "%d%%" % int(numbers["slow_pct"]), where)
		assert_eq(_stat_value(panel, "Range"), reach, where)
		assert_eq(_stat_value(panel, "Linger"), "%s s" % BattleText.seconds(int(numbers["slow_ms"])), where)
		assert_eq(_stat_value(panel, "Affects"), BattleText.hits_text(numbers), where)
	elif kind == &"boost":
		assert_eq(_stat_value(panel, "Rate boost"), "+%d%%" % int(numbers["boost_pct"]), where)
		assert_eq(_stat_value(panel, "Damage bonus"), "+%d" % int(numbers["boost_damage"]), where)
		assert_eq(_stat_value(panel, "Reach"), reach, where)
		assert_eq(_stat_value(panel, "Boosting now"), str(int(numbers["boosting"])), where)
	elif kind == &"fright":
		# The Scarecrow (RULES 9.3): a ring tower like the Bell, with a fright instead of a slow.
		assert_eq(_stat_value(panel, "Fright"), "%d%%" % int(numbers["fright_pct"]), where)
		assert_eq(_stat_value(panel, "Range"), reach, where)
		assert_eq(_stat_value(panel, "Linger"), "%s s" % BattleText.seconds(int(numbers["fright_ms"])), where)
		assert_eq(_stat_value(panel, "Affects"), BattleText.hits_text(numbers), where)
	else:
		assert_eq(_stat_value(panel, "Damage"), str(int(numbers["damage"])), where)
		assert_eq(_stat_value(panel, "Rate"), "%s/s" % BattleText.rate(int(numbers["reload_ms"])), where)
		# A pulse tower (the Bramble Cottage) names its reach "Ring"; every other attack says "Range".
		assert_eq(_stat_value(panel, BattleText.range_label(bool(numbers.get("pulse", false)))), reach, where)
		assert_eq(_stat_value(panel, "Hits"), BattleText.hits_text(numbers), where)
		if int(numbers.get("splash", 0)) > 0:
			assert_eq(_stat_value(panel, "Splash"), BattleText.tiles_text(int(numbers["splash"])), where)
		if bool(numbers.get("pierce", false)):
			assert_eq(_stat_value(panel, "Armor"), "Ignored", where)
	assert_eq(_stat_value(panel, "Total spent"), str(int(numbers["spent"])), where)


func test_every_tower_shows_its_real_numbers_at_every_tier_and_path() -> void:
	for type: StringName in Fx.game().catalog.tower_ids():
		for spec: int in [0, 1]:
			var b: Battle = Fx.all_towers_battle(&"r1_l1")
			var cell: Vector2i = b.level.spots[0]
			_build_all(b, type, cell)
			var panel: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
			panel.setup(b)
			panel.show_tower(cell)
			_check_rows(panel, b, cell, "%s tier 1" % type)
			assert_eq(b.upgrade_tower(cell), Battle.DONE)
			panel.refresh()
			_check_rows(panel, b, cell, "%s tier 2" % type)
			assert_eq(b.upgrade_tower(cell, spec), Battle.DONE)
			panel.refresh()
			_check_rows(panel, b, cell, "%s tier 3 path %d" % [type, spec])
			assert_eq(panel.tier_label.text, "Tier 3: %s" % b.catalog.tower(type).spec_name(spec))


func test_upgrades_of_the_bell_and_the_bakery_show_before_and_after() -> void:
	for type: StringName in [&"lullaby_bell", &"bakery"]:
		var b: Battle = Fx.all_towers_battle(&"r1_l1")
		var cell: Vector2i = b.level.spots[0]
		_build_all(b, type, cell)
		var panel: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
		panel.setup(b)
		panel.show_tower(cell)
		var rows: Array[Node] = panel.find_children("*", "StatRow", true, false).filter(func(n: Node) -> bool: return (n as StatRow).before_label != null)
		assert_false(rows.is_empty(), "%s: the tier 2 upgrade lists what changes" % type)
		var option: Dictionary = b.upgrade_options(cell)[0]
		for row: Node in rows:
			var line: StatRow = row as StatRow
			assert_ne(line.before_label.text, line.after_label.text, "%s %s changes" % [type, line.name_label.text])
		assert_eq(rows.size(), BattleText.change_rows(option["before"], option["after"], b.catalog.tower(type).kind).size())


## A level with one more build spot next to the first, so a Bakery has a neighbor.
func _neighbor_battle() -> Battle:
	var data: Dictionary = Fx.game().levels[&"r1_l1"].to_data()
	var grid: Array = data["grid"]
	var spot: Vector2i = Fx.game().levels[&"r1_l1"].spots[0]
	for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var at: Vector2i = spot + step
		if at.x >= 0 and at.x < Sim.MAP_COLUMNS and at.y >= 0 and at.y < grid.size() and String(grid[at.y])[at.x] == ".":
			var row: String = grid[at.y]
			grid[at.y] = row.substr(0, at.x) + "o" + row.substr(at.x + 1)
			break
	data["towers"] = Fx.game().catalog.tower_ids()
	var level: LevelData = LevelData.from_data(data, Fx.game().catalog)
	assert_not_null(level, "the neighbor level is valid")
	return Battle.create(level, Fx.game().catalog, false, [] as Array[Dictionary])


func test_a_bakery_counts_the_towers_it_boosts_and_the_tower_shows_what_it_gets() -> void:
	var b: Battle = _neighbor_battle()
	var bakery_cell: Vector2i = Fx.game().levels[&"r1_l1"].spots[0]
	var sling_cell: Vector2i = Vector2i(-1, -1)
	for cell: Vector2i in b.level.spots:
		if cell != bakery_cell and absi(cell.x - bakery_cell.x) + absi(cell.y - bakery_cell.y) == 1:
			sling_cell = cell
	assert_true(sling_cell.x >= 0, "a spot next to the Bakery")
	b.gold = 100000
	assert_eq(b.place_tower(bakery_cell, &"bakery"), Battle.DONE)
	assert_eq(b.place_tower(sling_cell, &"sling_post"), Battle.DONE)
	var panel: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
	panel.setup(b)
	panel.show_tower(bakery_cell)
	assert_eq(_stat_value(panel, "Boosting now"), "1")
	panel.show_tower(sling_cell)
	var numbers: Dictionary = b.tower_numbers(sling_cell)
	assert_true(int(numbers["got_pct"]) > 0)
	assert_eq(_stat_value(panel, "Boost received"), "+%d%% rate, +%d damage" % [int(numbers["got_pct"]), int(numbers["got_damage"])])
	assert_eq(_stat_value(panel, "Rate"), "%s/s" % BattleText.rate(int(numbers["reload_ms"]), int(numbers["got_pct"])), "the rate includes the boost")


func _creature_battle(id: StringName) -> Battle:
	var group: Dictionary = {"enemy": String(id), "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 100}
	var b: Battle = Fx.battle_with_waves([{"groups": [group]}])
	assert_not_null(b, "a battle with %s" % id)
	b.start_next_wave()
	Fx.steps(b, 3)
	return b


func test_every_creature_and_boss_shows_its_real_numbers() -> void:
	for id: StringName in Fx.game().catalog.enemy_ids():
		var b: Battle = _creature_battle(id)
		assert_false(b.enemies.is_empty(), "%s walked in" % id)
		var enemy: EnemyState = b.enemies[0]
		var type: EnemyType = b.catalog.enemy(id)
		var numbers: Dictionary = b.enemy_numbers(enemy.id)
		var panel: EnemyPanel = _keep(EnemyPanel.new()) as EnemyPanel
		panel.setup(b)
		panel.show_enemy(enemy.id)
		assert_eq(panel.name_label.text, type.name, id)
		assert_eq(panel.move_label.text, "Flies" if type.flying else "Walks", id)
		assert_eq(panel.info_label.text, type.info, id)
		assert_eq(panel.health_label.text, "Health %d / %d" % [int(numbers["health"]), int(numbers["max_health"])], id)
		assert_eq(panel.armor_row.value_label.text, str(int(numbers["armor"])), id)
		assert_eq(panel.speed_row.value_label.text, "%s tiles/s" % BattleText.speed(int(numbers["speed"])), id)
		assert_eq(panel.lives_row.value_label.text, str(int(numbers["lives"])), id)
		assert_eq(panel.bounty_row.value_label.text, str(int(numbers["bounty"])), id)
		assert_eq(panel.heal_row.visible, type.heal > 0, "%s: the heal row is for healers" % id)
		if type.heal > 0:
			assert_eq(panel.heal_row.value_label.text, "%d every %s s" % [type.heal, BattleText.seconds(type.heal_ms)])
		if type.bubble:
			assert_true(_texts(panel.status_box).has("Bubble up"), "%s: its bubble is up" % id)


func test_a_gate_breaker_and_a_slowed_creature_show_their_status() -> void:
	var b: Battle = _creature_battle(&"gatecrasher")
	var enemy: EnemyState = b.enemies[0]
	enemy.breaking = 150000
	var panel: EnemyPanel = _keep(EnemyPanel.new()) as EnemyPanel
	panel.setup(b)
	panel.show_enemy(enemy.id)
	assert_true(_texts(panel.status_box).has("Breaking a gate: 1.5 s left"))
	enemy.breaking = 0
	enemy.slow_pct = 40
	enemy.slow_ticks = 20
	panel.refresh()
	assert_true(_texts(panel.status_box).has("Slowed 40% for 1.0 s"))
	assert_true(panel.speed_row.value_label.text.contains("(base "), "the base speed shows next to the slowed one")


func test_first_sight_cards_work_for_every_tower_and_creature() -> void:
	var b: Battle = Fx.all_towers_battle(&"r1_l1")
	for id: StringName in b.catalog.tower_ids():
		var card: InfoCard = _keep(InfoCard.new(b, [{"kind": &"tower", "id": id, "wave": 0}] as Array[Dictionary])) as InfoCard
		assert_eq(card.name_label.text, b.catalog.tower(id).name)
		assert_eq(card.info_label.text, b.catalog.tower(id).info)
	for id: StringName in b.catalog.enemy_ids():
		var card: InfoCard = _keep(InfoCard.new(b, [{"kind": &"enemy", "id": id, "wave": 0}] as Array[Dictionary])) as InfoCard
		assert_eq(card.name_label.text, b.catalog.enemy(id).name)


# The new towers and creatures in Info.

func test_info_draws_every_tower_creature_and_boss_of_the_data() -> void:
	var game: GameData = Fx.game()
	var catalog: Catalog = game.catalog
	var content: InfoContent = InfoContent.from_game(game)
	assert_eq(content.towers, catalog.tower_ids(), "every tower of the data, in its order")
	var creatures: Array[StringName] = content.pictures()
	var enemies: Array[StringName] = catalog.enemy_ids()
	for id: StringName in enemies:
		assert_true(creatures.has(id), "%s is drawn" % id)
	assert_eq(creatures.size(), enemies.size(), "and nothing else")
	for id: StringName in content.bosses:
		assert_true(catalog.enemy(id).boss, "%s, a boss, is drawn last" % id)
		assert_true(creatures.find(id) >= content.creatures.size())
	for id: StringName in content.creatures:
		assert_false(catalog.enemy(id).boss)


func test_info_names_every_tower_and_creature_under_its_picture() -> void:
	var made: App = _keep(Flow.app(TAG)) as App
	var names: Dictionary = made.names
	var screen: InfoScreen = _keep(InfoScreen.new(made.rules, names, InfoContent.from_game(made.game))) as InfoScreen
	var captioned: int = 0
	for art: Node in screen.find_children("*", "InfoArt", true, false):
		var info_art: InfoArt = art as InfoArt
		if info_art.kind == &"towers":
			assert_eq(info_art.captions.size(), made.game.catalog.tower_ids().size())
			captioned += 1
		elif info_art.kind == &"creatures":
			assert_eq(info_art.captions.size(), made.game.catalog.enemy_ids().size())
			for caption: String in info_art.captions:
				assert_false(caption.is_empty(), "every creature has a name under it")
			captioned += 1
	assert_eq(captioned, 2)
	var text: String = " ".join(_texts(screen))
	assert_true(text.contains("boss"), "Info says what a boss is")
	assert_true(text.contains("bubble"), "and the bubble")
	assert_true(text.contains("slow creatures down"), "and the towers that slow")


func test_the_app_shows_the_relaxed_line_after_a_normal_loss_only() -> void:
	var made: App = _keep(Flow.app(TAG)) as App
	Flow.mark_all_seen(made)
	made.start_level(&"r1_l1", false)
	var loss: Dictionary = {"won": false, "stars": 0, "lives_left": 0, "waves_cleared": 2, "abandoned": false, "relaxed": false}
	made._on_battle_ended(loss)
	var panel: EndPanel = made.top_modal() as EndPanel
	assert_not_null(panel, "the end panel shows")
	assert_eq(panel.relaxed_label.text, "Stuck? Relaxed gives 40 lives and more gold.")
	panel.request_close()
	made.start_level(&"r1_l1", true)
	var easy: Dictionary = loss.duplicate()
	easy["relaxed"] = true
	made._on_battle_ended(easy)
	var second: EndPanel = made.top_modal() as EndPanel
	assert_not_null(second)
	assert_null(second.relaxed_label, "a Relaxed loss has nothing to point to")
