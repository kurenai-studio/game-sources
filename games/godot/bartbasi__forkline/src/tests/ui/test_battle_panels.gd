# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The battle panels on real Battle objects made from the real level data:
## the HUD, build, upgrade, path choice, sell, targeting, refusals, the creature
## panel and the wave preview. Panels only send commands, so most of this runs
## without stepping the sim, as when the game is paused.

const Fx: GDScript = preload("res://tests/ui/battle_fixtures.gd")
const REFUSALS: Array[StringName] = [
	&"over", &"not_a_spot", &"occupied", &"not_offered", &"too_poor", &"no_tower", &"top_tier",
	&"tier_cap", &"pick_spec", &"bad_spec", &"no_selling", &"no_aim", &"gates_locked",
	&"not_a_socket", &"has_gate", &"no_gate", &"no_gates_left", &"fixed_gate", &"would_seal",
	&"no_more_waves", &"still_spawning", &"too_many_waves", &"risk_waiting", &"bad_effect",
]

var spare: Array[Node] = []
var refusals_seen: Array[StringName] = []


func after_each() -> void:
	for node: Node in spare:
		if is_instance_valid(node):
			node.free()
	spare.clear()
	refusals_seen.clear()


func _keep(node: Node) -> Node:
	spare.append(node)
	return node


func _hud(b: Battle) -> BattleHud:
	var hud: BattleHud = _keep(BattleHud.new()) as BattleHud
	hud.refused.connect(func(reason: StringName, _text: String) -> void: refusals_seen.append(reason))
	hud.refresh(b)
	return hud


func _build(b: Battle) -> BuildPanel:
	var panel: BuildPanel = _keep(BuildPanel.new()) as BuildPanel
	panel.refused.connect(func(reason: StringName, _text: String) -> void: refusals_seen.append(reason))
	panel.setup(b)
	return panel


func _tower(b: Battle) -> TowerPanel:
	var panel: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
	panel.refused.connect(func(reason: StringName, _text: String) -> void: refusals_seen.append(reason))
	panel.setup(b)
	return panel


func _texts(root: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return out


func _spot(b: Battle, index: int = 0) -> Vector2i:
	return b.level.spots[index]


func _built(b: Battle, type: StringName = &"sling_post", index: int = 0) -> Vector2i:
	var cell: Vector2i = _spot(b, index)
	assert_eq(b.place_tower(cell, type), Battle.DONE)
	return cell


func _stat_value(panel: Node, label: String) -> String:
	for node: Node in panel.find_children("*", "StatRow", true, false):
		var row: StatRow = node as StatRow
		if row.name_label.text == label and row.value_label != null:
			return row.value_label.text
	return "<missing %s>" % label


func _change_rows(root: Node) -> Array[Node]:
	return root.find_children("*", "StatRow", true, false).filter(func(n: Node) -> bool: return (n as StatRow).before_label != null)


# Text.

func test_every_refusal_has_a_short_sentence() -> void:
	var fallback: String = BattleText.refusal(&"nonsense")
	for reason: StringName in REFUSALS:
		var text: String = BattleText.refusal(reason)
		assert_ne(text, fallback, "%s has its own sentence" % reason)
		assert_true(text.length() <= 48, "%s is short" % reason)
		assert_false(text.contains("\u2014") or text.contains("--"), "no dashes in %s" % reason)
	assert_eq(BattleText.refusal(&"gates_locked"), "Gates are locked until the wave is over.")
	assert_eq(BattleText.refusal(&"would_seal"), "That would close every road.")
	assert_eq(BattleText.refusal(&"too_poor", 40), "Need 40 more gold.")


func test_seconds_round_up_to_the_next_tenth() -> void:
	# QA 2026-10-30 L2: time left above zero never reads "0.0".
	assert_eq(BattleText.seconds(50), "0.1")
	assert_eq(BattleText.seconds(1), "0.1")
	assert_eq(BattleText.seconds(100), "0.1")
	assert_eq(BattleText.seconds(101), "0.2")
	assert_eq(BattleText.seconds(1050), "1.1")
	assert_eq(BattleText.seconds(2500), "2.5")
	assert_eq(BattleText.seconds(3000), "3.0")
	assert_eq(BattleText.seconds(0), "0.0")
	assert_eq(BattleText.seconds(-40), "0.0")
	var lines: PackedStringArray = BattleText.status_lines({"slow_pct": 60, "slow_ms": 50})
	assert_eq(lines[0], "Slowed 60% for 0.1 s")


func test_number_formats() -> void:
	assert_eq(BattleText.tiles(250), "2.5")
	assert_eq(BattleText.tiles(300), "3")
	assert_eq(BattleText.tiles(75), "0.75")
	assert_eq(BattleText.seconds(1000), "1.0")
	assert_eq(BattleText.speed(120), "1.20")
	assert_eq(BattleText.rate(500), "2.0")
	assert_eq(BattleText.rate(2000, 50), "0.8")
	assert_eq(BattleText.entrance_letter(1), "A")
	assert_eq(BattleText.entrance_letter(4), "D")


# The HUD.

func test_hud_shows_lives_gold_and_wave() -> void:
	var b: Battle = Fx.battle()
	var hud: BattleHud = _hud(b)
	assert_eq(hud.lives_label.text, str(b.lives))
	assert_eq(hud.gold_label.text, str(b.gold))
	assert_eq(hud.wave_label.text, "Wave 1/%d" % b.wave_count())
	assert_eq(hud.call_button.text, "Start wave 1")
	b.place_tower(_spot(b), &"sling_post")
	hud.refresh()
	assert_eq(hud.gold_label.text, str(b.gold))
	hud.call_button.tapped.emit()
	assert_eq(b.phase, Battle.Phase.WAVE)
	assert_eq(hud.wave_label.text, "Wave 1/%d" % b.wave_count())


func test_hud_speed_and_pause_signals() -> void:
	var hud: BattleHud = _hud(Fx.battle())
	var speeds: Array[int] = []
	hud.speed_selected.connect(func(s: int) -> void: speeds.append(s))
	assert_eq(hud.speed, 1)
	hud.speed_buttons[2].tapped.emit()
	hud.speed_buttons[1].tapped.emit()
	assert_eq(speeds, [3, 2] as Array[int])
	assert_eq(hud.speed, 2)
	var asked: Array[String] = []
	hud.pause_requested.connect(func() -> void: asked.append("pause"))
	hud.resume_requested.connect(func() -> void: asked.append("resume"))
	hud.pause_button.tapped.emit()
	hud.set_paused(true)
	hud.pause_button.tapped.emit()
	assert_eq(asked, ["pause", "resume"] as Array[String])


func test_hud_call_button_shows_the_bonus_and_calls_while_the_sim_is_paused() -> void:
	var b: Battle = Fx.battle()
	var hud: BattleHud = _hud(b)
	var clock: BattleClock = BattleClock.new()
	clock.paused = true
	assert_eq(clock.advance(1.0), 0, "the clock is frozen")
	hud.call_button.tapped.emit()
	assert_eq(b.phase, Battle.Phase.WAVE)
	# The wave has not spawned all its groups: the call is refused, with a sentence.
	assert_eq(hud.call_button.text, "Call wave 2")
	hud.call_button.tapped.emit()
	assert_eq(refusals_seen, [&"still_spawning"] as Array[StringName])
	assert_eq(hud.feedback_text(), "The wave is still arriving.")
	assert_eq(b.waves_started, 1)
	# Step (the screen does this when running) until the wave has spawned, then the bonus shows.
	Fx.steps(b, 120)
	hud.refresh()
	var info: Dictionary = b.next_wave_info()
	assert_eq(info["refusal"], &"")
	assert_true(int(info["bonus"]) > 0)
	assert_eq(hud.call_button.text, "Call wave 2  +%d" % int(info["bonus"]))
	var gold: int = b.gold
	hud.call_button.tapped.emit()
	assert_eq(b.waves_started, 2)
	assert_eq(b.gold, gold + int(info["bonus"]))
	assert_eq(hud.feedback_text(), "", "a carried out command clears the message")


func test_hud_shows_too_many_waves_and_the_last_wave() -> void:
	var b: Battle = Fx.battle()
	var hud: BattleHud = _hud(b)
	b.start_next_wave()
	var found: bool = false
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < 6000 and not found:
		Fx.steps(b, 1)
		guard += 1
		var refusal: StringName = b.next_wave_info()["refusal"]
		if refusal == &"" and b.waves_started == 1:
			b.start_next_wave()
		elif refusal == &"too_many_waves":
			found = true
	assert_true(found, "two waves can be on the map")
	hud.refresh()
	hud.call_button.tapped.emit()
	assert_eq(hud.feedback_text(), "Too many waves on the map.")
	# The last wave: nothing more to call.
	var last: Battle = Fx.battle()
	var last_hud: BattleHud = _hud(last)
	last.waves_started = last.wave_count()
	last.phase = Battle.Phase.WAVE
	last_hud.refresh()
	last_hud.call_button.tapped.emit()
	assert_eq(last_hud.feedback_text(), "That was the last wave.")


func test_a_lives_drop_starts_the_hud_pulse_and_it_scales_around_the_center() -> void:
	var b: Battle = Fx.battle()
	var hud: BattleHud = _hud(b)
	assert_false(hud.pulsing(), "nothing at rest")
	var box: Control = hud.lives_label.get_parent() as Control
	box.size = Vector2(80.0, 56.0)
	var before_size: Vector2 = box.size
	b.lives -= 1
	hud.refresh()
	assert_true(hud.pulsing())
	assert_eq(hud.lives_label.text, str(b.lives))
	hud.advance_pulse(BattleHud.PULSE_TIME * 0.5)
	assert_true(box.scale.x > 1.2, "grown at the peak")
	assert_eq(box.scale.x, box.scale.y)
	assert_eq(box.pivot_offset, before_size * 0.5, "turns around the center")
	assert_eq(box.size, before_size, "the layout size never changes")
	assert_ne(box.modulate, Color.WHITE, "warm tint at the peak")
	hud.advance_pulse(BattleHud.PULSE_TIME)
	assert_false(hud.pulsing())
	assert_eq(box.scale, Vector2.ONE)
	assert_eq(box.modulate, Color.WHITE)


func test_leaks_in_quick_succession_restart_the_pulse_and_do_not_stack() -> void:
	var b: Battle = Fx.battle()
	var hud: BattleHud = _hud(b)
	var box: Control = hud.lives_label.get_parent() as Control
	b.lives -= 1
	hud.refresh()
	hud.advance_pulse(0.2)
	b.lives -= 1
	hud.refresh()
	hud.advance_pulse(BattleHud.PULSE_TIME * 0.5)
	assert_true(hud.pulsing(), "restarted, so still going past the first one's end")
	assert_true(box.scale.x <= 1.0 + BattleHud.PULSE_GROW + 0.001, "never grows past one pulse")
	hud.refresh()
	assert_true(hud.pulsing(), "no drop, no restart, no end")
	hud.stop_pulse()
	assert_eq(box.scale, Vector2.ONE)


func test_a_restored_game_does_not_pulse() -> void:
	var b: Battle = Fx.battle()
	b.lives -= 3
	var restored: Battle = Battle.from_data(b.to_data(), Fx.game().catalog)
	assert_not_null(restored)
	var hud: BattleHud = _hud(restored)
	assert_false(hud.pulsing(), "the first read is the baseline")
	assert_eq(hud.lives_label.text, str(restored.lives))
	hud.refresh()
	assert_false(hud.pulsing())
	# A new battle handed to the same HUD is a fresh baseline too.
	hud.refresh(Fx.battle())
	assert_false(hud.pulsing())


func test_hud_arrangement_follows_the_width() -> void:
	var hud: BattleHud = _hud(Fx.battle())
	hud.set_wide(true)
	assert_eq(hud.call_button.get_parent(), hud.speed_buttons[0].get_parent(), "portrait: speeds and call share a row")
	hud.set_wide(false)
	assert_ne(hud.call_button.get_parent(), hud.speed_buttons[0].get_parent(), "narrow: the call button has its own row")


# Building.

func test_build_panel_shows_silhouette_cards_with_cost_and_the_name_below() -> void:
	var b: Battle = Fx.battle()
	var panel: BuildPanel = _build(b)
	var cell: Vector2i = _spot(b)
	panel.show_spot(cell)
	var options: Array[Dictionary] = b.build_options(cell)
	assert_eq(panel.card_buttons.size(), options.size())
	for option: Dictionary in options:
		var card: TapButton = panel.card_buttons[option["tower"]]
		var texts: PackedStringArray = _texts(card)
		assert_true(texts.has(str(int(option["cost"]))), "the card shows the cost")
		for text: String in texts:
			assert_ne(text, b.catalog.tower(option["tower"]).name, "names do not go on cards")
		assert_eq(card.find_children("*", "GlyphIcon", true, false).size(), 1, "one silhouette on a card")
	assert_eq(panel.selected, options[0]["tower"])
	assert_eq(panel.name_label.text, b.catalog.tower(panel.selected).name)
	assert_eq(panel.info_label.text, b.catalog.tower(panel.selected).info)
	panel.select_tower(options[1]["tower"])
	assert_eq(panel.name_label.text, b.catalog.tower(options[1]["tower"]).name)


func test_build_panel_shows_range_while_placing_and_hides_it_after() -> void:
	var b: Battle = Fx.battle()
	var panel: BuildPanel = _build(b)
	var rings: Array = []
	panel.range_changed.connect(func(cell: Vector2i, reach: int, boost: bool) -> void: rings.append([cell, reach, boost]))
	var cell: Vector2i = _spot(b)
	panel.show_spot(cell)
	var first: StringName = b.level.towers[0]
	assert_eq(rings.back(), [cell, b.catalog.tower(first).stats(1, -1).reach, false])
	var second: StringName = b.level.towers[1]
	panel.select_tower(second)
	assert_eq(rings.back(), [cell, b.catalog.tower(second).stats(1, -1).reach, false])
	assert_eq(_stat_value(panel, "Range"), "%s tiles" % BattleText.tiles(b.catalog.tower(second).stats(1, -1).reach))
	panel.build_button.tapped.emit()
	assert_eq(rings.back()[0], Vector2i(-1, -1), "the ring hides when the panel closes")


func test_build_buys_the_chosen_tower() -> void:
	var b: Battle = Fx.battle()
	var panel: BuildPanel = _build(b)
	var built: Array = []
	panel.built.connect(func(cell: Vector2i, type: StringName) -> void: built.append([cell, type]))
	var cell: Vector2i = _spot(b)
	panel.show_spot(cell)
	var type: StringName = b.level.towers[1]
	panel.select_tower(type)
	var price: int = b.catalog.tower(type).stats(1, -1).cost
	assert_eq(panel.build_button.text, "Build for %d" % price)
	var gold: int = b.gold
	panel.build_button.tapped.emit()
	assert_not_null(b.tower_at(cell))
	assert_eq(b.tower_at(cell).type, type)
	assert_eq(b.gold, gold - price)
	assert_eq(built, [[cell, type]])
	assert_false(panel.is_open())


func test_build_refused_when_gold_is_short() -> void:
	var b: Battle = Fx.battle()
	b.gold = 50
	var panel: BuildPanel = _build(b)
	var cell: Vector2i = _spot(b)
	panel.show_spot(cell)
	var price: int = b.catalog.tower(panel.selected).stats(1, -1).cost
	var card_texts: PackedStringArray = _texts(panel.card_buttons[panel.selected])
	assert_true(card_texts.has("Need %d" % (price - 50)), "a short card says how much is missing")
	panel.build_button.tapped.emit()
	assert_null(b.tower_at(cell))
	assert_eq(refusals_seen, [&"too_poor"] as Array[StringName])
	assert_eq(panel.feedback_text(), "Need %d more gold." % (price - 50))
	assert_eq(b.gold, 50)
	assert_true(panel.is_open())


func test_build_refused_when_the_spot_was_taken_meanwhile() -> void:
	var b: Battle = Fx.battle()
	var panel: BuildPanel = _build(b)
	var cell: Vector2i = _spot(b)
	panel.show_spot(cell)
	b.place_tower(cell, &"sling_post")
	panel.confirm()
	assert_eq(refusals_seen, [&"occupied"] as Array[StringName])
	assert_eq(panel.feedback_text(), "A tower is already there.")


func test_build_with_all_six_towers_and_in_a_wave() -> void:
	var b: Battle = Fx.all_towers_battle()
	b.gold = 1000
	var panel: BuildPanel = _build(b)
	panel.show_spot(_spot(b))
	assert_eq(panel.card_buttons.size(), b.catalog.tower_ids().size())
	panel.set_wide(false)
	assert_eq(panel.card_buttons.size(), b.catalog.tower_ids().size())
	b.start_next_wave()
	panel.select_tower(&"bakery")
	panel.build_button.tapped.emit()
	assert_eq(b.tower_at(_spot(b)).type, &"bakery", "building works during a wave")


# Inspecting a tower and targeting.

func test_tower_panel_shows_the_real_numbers() -> void:
	var b: Battle = Fx.battle()
	var cell: Vector2i = _built(b)
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	var numbers: Dictionary = b.tower_numbers(cell)
	assert_eq(panel.name_label.text, b.catalog.tower(&"sling_post").name)
	assert_eq(panel.tier_label.text, "Tier 1")
	assert_eq(_stat_value(panel, "Damage"), str(int(numbers["damage"])))
	assert_eq(_stat_value(panel, "Rate"), "%s/s" % BattleText.rate(int(numbers["reload_ms"])))
	assert_eq(_stat_value(panel, "Range"), "%s tiles" % BattleText.tiles(int(numbers["reach"])))
	assert_eq(_stat_value(panel, "Hits"), "Walkers and flyers")
	assert_eq(_stat_value(panel, "Total spent"), str(int(numbers["spent"])))
	assert_eq(_stat_value(panel, "Sell value"), str(b.sell_value(cell)))


func test_tower_panel_for_a_splash_tower_lists_the_splash() -> void:
	var b: Battle = Fx.battle()
	var cell: Vector2i = _built(b, &"pumpkin_catapult")
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	var splash: int = int(b.tower_numbers(cell)["splash"])
	assert_eq(_stat_value(panel, "Splash"), "%s tiles" % BattleText.tiles(splash))
	assert_eq(_stat_value(panel, "Hits"), "Walkers")


func test_targeting_can_be_changed_and_stays_through_an_upgrade() -> void:
	var b: Battle = Fx.battle()
	var cell: Vector2i = _built(b)
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	assert_eq(panel.aim_buttons.size(), 3)
	assert_eq(panel.aim_buttons[0].theme_type_variation, &"PrimaryButton", "First is chosen")
	panel.aim_buttons[2].tapped.emit()
	assert_eq(b.tower_at(cell).aim, TowerState.Aim.STRONG)
	assert_eq(panel.aim_buttons[2].theme_type_variation, &"PrimaryButton")
	assert_not_null(panel.aim_buttons[2].icon, "the chosen mode also wears a check mark")
	assert_null(panel.aim_buttons[0].icon)
	panel.aim_buttons[1].tapped.emit()
	assert_eq(b.tower_at(cell).aim, TowerState.Aim.LAST)
	panel.upgrade_button.tapped.emit()
	assert_eq(b.tower_at(cell).aim, TowerState.Aim.LAST)
	assert_eq(panel.aim_buttons[1].theme_type_variation, &"PrimaryButton")


func test_a_bell_has_no_targeting_buttons() -> void:
	var b: Battle = Fx.all_towers_battle()
	var cell: Vector2i = _built(b, &"lullaby_bell")
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	assert_eq(panel.aim_buttons.size(), 0)
	assert_eq(_stat_value(panel, "Slow"), "%d%%" % int(b.tower_numbers(cell)["slow_pct"]))
	assert_eq(b.set_aim(cell, TowerState.Aim.LAST), &"no_aim")
	assert_eq(BattleText.refusal(&"no_aim"), "This tower has no targeting.")


# Upgrades.

func test_upgrade_shows_before_and_after_and_buys() -> void:
	var b: Battle = Fx.battle()
	b.gold = 500
	var cell: Vector2i = _built(b)
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	var option: Dictionary = b.upgrade_options(cell)[0]
	var expected: Array[Dictionary] = BattleText.change_rows(option["before"], option["after"], &"attack")
	assert_true(expected.size() >= 2, "damage and rate change")
	var rows: Array[Node] = _change_rows(panel)
	assert_eq(rows.size(), expected.size())
	for i: int in rows.size():
		var row: StatRow = rows[i] as StatRow
		assert_eq(row.name_label.text, expected[i]["label"])
		assert_eq(row.before_label.text, expected[i]["before"])
		assert_eq(row.after_label.text, expected[i]["after"])
		assert_not_null(row.arrow.texture, "an arrow is drawn between them")
	var damage_row: StatRow = rows[0] as StatRow
	assert_eq(damage_row.before_label.text, str(int(option["before"]["damage"])))
	assert_eq(damage_row.after_label.text, str(int(option["after"]["damage"])))
	assert_eq(panel.upgrade_button.text, "Upgrade for %d" % int(option["cost"]))
	var gold: int = b.gold
	panel.upgrade_button.tapped.emit()
	assert_eq(b.tower_at(cell).tier, 2)
	assert_eq(b.gold, gold - int(option["cost"]))
	assert_eq(panel.tier_label.text, "Tier 2")


func test_upgrade_refused_when_gold_is_short() -> void:
	var b: Battle = Fx.battle()
	var cell: Vector2i = _built(b)
	b.gold = 10
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	var price: int = int(b.upgrade_options(cell)[0]["cost"])
	panel.upgrade_button.tapped.emit()
	assert_eq(b.tower_at(cell).tier, 1)
	assert_eq(refusals_seen, [&"too_poor"] as Array[StringName])
	assert_eq(panel.feedback_text(), "Need %d more gold." % (price - 10))


func test_both_tier_3_paths_show_side_by_side_and_the_choice_asks_once() -> void:
	var b: Battle = Fx.battle()
	b.gold = 2000
	var cell: Vector2i = _built(b)
	assert_eq(b.upgrade_tower(cell), Battle.DONE)
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	assert_eq(panel.path_cards.size(), 2)
	assert_eq(panel.path_cards[0].get_parent(), panel.path_cards[1].get_parent(), "side by side")
	var type: TowerType = b.catalog.tower(&"sling_post")
	var options: Array[Dictionary] = b.upgrade_options(cell)
	for i: int in 2:
		var texts: PackedStringArray = _texts(panel.path_cards[i])
		assert_true(texts.has(type.spec_name(i)), "the path name comes from the catalog")
		assert_true(texts.has(type.spec_info(i)), "and its one line")
		var rows: Array[Node] = _change_rows(panel.path_cards[i])
		var expected: Array[Dictionary] = BattleText.change_rows(options[i]["before"], options[i]["after"], &"attack")
		assert_eq(rows.size(), expected.size())
		for j: int in rows.size():
			assert_eq((rows[j] as StatRow).before_label.text, expected[j]["before"])
			assert_eq((rows[j] as StatRow).after_label.text, expected[j]["after"])
	assert_true(_texts(panel).has("Pick a path for tier 3. The choice is permanent."))
	assert_null(panel.confirm_button, "nothing to confirm before a path is picked")
	var gold: int = b.gold
	panel.path_cards[1].tapped.emit()
	assert_eq(b.tower_at(cell).tier, 2, "picking buys nothing")
	assert_eq(b.gold, gold)
	assert_not_null(panel.confirm_button)
	assert_not_null(panel.permanent_label)
	assert_true(panel.permanent_label.text.contains("permanent"))
	assert_eq(panel.confirm_button.text, "Choose %s for %d" % [type.spec_name(1), int(options[1]["cost"])])
	panel.path_cards[0].tapped.emit()
	assert_eq(panel.confirm_button.text, "Choose %s for %d" % [type.spec_name(0), int(options[0]["cost"])], "the pick can still change")
	panel.path_cards[1].tapped.emit()
	panel.confirm_button.tapped.emit()
	assert_eq(b.tower_at(cell).tier, 3)
	assert_eq(b.tower_at(cell).spec, 1)
	assert_eq(b.gold, gold - int(options[1]["cost"]))
	assert_eq(panel.tier_label.text, "Tier 3: %s" % type.spec_name(1))
	assert_eq(panel.path_cards.size(), 0)
	assert_true(_texts(panel).has("Fully upgraded."))


func test_choosing_a_path_is_refused_when_gold_is_short() -> void:
	var b: Battle = Fx.battle()
	b.gold = 2000
	var cell: Vector2i = _built(b)
	b.upgrade_tower(cell)
	b.gold = 60
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	panel.path_cards[0].tapped.emit()
	panel.confirm_button.tapped.emit()
	assert_eq(b.tower_at(cell).tier, 2)
	assert_eq(refusals_seen, [&"too_poor"] as Array[StringName])
	assert_eq(panel.feedback_text(), "Need %d more gold." % (int(b.upgrade_options(cell)[0]["cost"]) - 60))


# Selling.

func test_selling_in_the_build_phase_refunds_in_full() -> void:
	var b: Battle = Fx.battle()
	var cell: Vector2i = _built(b)
	var panel: TowerPanel = _tower(b)
	var sold: Array[Vector2i] = []
	panel.sold.connect(func(c: Vector2i) -> void: sold.append(c))
	panel.show_tower(cell)
	var price: int = b.catalog.tower(&"sling_post").stats(1, -1).cost
	assert_eq(b.sell_value(cell), price)
	assert_eq(panel.sell_button.text, "Sell for %d" % price)
	assert_eq(panel.refund_label.text, "Full refund: bought this build phase.")
	var gold: int = b.gold
	panel.sell_button.tapped.emit()
	assert_not_null(b.tower_at(cell), "the first tap only asks")
	assert_eq(panel.sell_button.text, "Tap again to sell for %d" % price)
	panel.sell_button.tapped.emit()
	assert_not_null(b.tower_at(cell), "a quick second tap does not sell")
	assert_eq(b.gold, gold)
	panel.armed_at_msec -= TowerPanel.SELL_DELAY_MS
	panel.sell_button.tapped.emit()
	assert_null(b.tower_at(cell))
	assert_eq(b.gold, gold + price)
	assert_eq(sold, [cell] as Array[Vector2i])
	assert_eq(panel.last_refund(), price)


func test_selling_after_the_build_phase_refunds_the_rules_percent() -> void:
	var b: Battle = Fx.battle()
	b.gold = 1000
	var cell: Vector2i = _built(b)
	b.place_tower(_spot(b, 1), &"sling_post")
	b.start_next_wave()
	Fx.steps(b, 5)
	assert_eq(b.upgrade_tower(cell), Battle.DONE)
	var percent: int = b.catalog.rules.refund_pct
	var paid: int = 100 + int(b.catalog.tower(&"sling_post").stats(2, -1).cost)
	var expected: int = paid * percent / 100
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	assert_eq(b.sell_value(cell), expected, "a wave purchase never refunds in full")
	assert_eq(panel.refund_label.text, "%d%% of the %d you paid." % [percent, paid])
	assert_eq(panel.sell_button.text, "Sell for %d" % expected)
	var gold: int = b.gold
	panel.sell_button.tapped.emit()
	panel.armed_at_msec -= TowerPanel.SELL_DELAY_MS
	panel.sell_button.tapped.emit()
	assert_null(b.tower_at(cell))
	assert_eq(b.gold, gold + expected)


func test_selling_mixes_full_and_percent_in_one_build_phase() -> void:
	var b: Battle = Fx.battle()
	b.gold = 1000
	var cell: Vector2i = _built(b)
	b.place_tower(_spot(b, 1), &"sling_post")
	b.start_next_wave()
	Fx.finish_wave(b)
	assert_eq(b.phase, Battle.Phase.BUILD, "the wave is over")
	assert_eq(b.upgrade_tower(cell), Battle.DONE)
	var percent: int = b.catalog.rules.refund_pct
	var upgrade: int = int(b.catalog.tower(&"sling_post").stats(2, -1).cost)
	var expected: int = upgrade + 100 * percent / 100
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	assert_eq(b.sell_value(cell), expected)
	assert_eq(panel.refund_label.text, "Full price for the %d bought this build phase, %d%% of the other 100." % [upgrade, percent])
	assert_eq(panel.sell_button.text, "Sell for %d" % expected)


func test_changing_the_tower_disarms_the_sale() -> void:
	var b: Battle = Fx.battle()
	var cell: Vector2i = _built(b)
	var other: Vector2i = _built(b, &"sling_post", 1)
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	panel.sell_button.tapped.emit()
	assert_true(panel.sell_armed)
	panel.show_tower(other)
	assert_false(panel.sell_armed)
	assert_true(panel.sell_button.text.begins_with("Sell for"))


func test_the_panel_closes_when_its_tower_is_gone() -> void:
	var b: Battle = Fx.battle()
	var cell: Vector2i = _built(b)
	var panel: TowerPanel = _tower(b)
	var closed: Array[int] = []
	panel.closed.connect(func() -> void: closed.append(1))
	panel.show_tower(cell)
	b.sell_tower(cell)
	panel.refresh()
	assert_eq(closed.size(), 1)
	assert_false(panel.is_open())


func test_tower_panel_reports_its_range_to_the_map() -> void:
	var b: Battle = Fx.battle()
	var cell: Vector2i = _built(b)
	var panel: TowerPanel = _tower(b)
	var rings: Array = []
	panel.range_changed.connect(func(c: Vector2i, reach: int, boost: bool) -> void: rings.append([c, reach, boost]))
	panel.show_tower(cell)
	assert_eq(rings.back(), [cell, int(b.tower_numbers(cell)["reach"]), false])
	b.gold = 500
	panel.upgrade()
	assert_eq(rings.back(), [cell, int(b.tower_numbers(cell)["reach"]), false], "the ring follows the new reach")


# Everything works while paused: no panel steps the sim.

func test_commands_work_mid_wave_without_a_single_tick() -> void:
	var b: Battle = Fx.battle()
	b.gold = 1000
	b.start_next_wave()
	var tick: int = b.tick
	var build: BuildPanel = _build(b)
	build.show_spot(_spot(b))
	build.confirm()
	var cell: Vector2i = _spot(b)
	assert_not_null(b.tower_at(cell))
	var panel: TowerPanel = _tower(b)
	panel.show_tower(cell)
	panel.aim_buttons[1].tapped.emit()
	panel.upgrade_button.tapped.emit()
	panel.path_cards[0].tapped.emit()
	panel.confirm_button.tapped.emit()
	assert_eq(b.tower_at(cell).tier, 3)
	assert_eq(b.tower_at(cell).aim, TowerState.Aim.LAST)
	panel.sell_button.tapped.emit()
	panel.armed_at_msec -= TowerPanel.SELL_DELAY_MS
	panel.sell_button.tapped.emit()
	assert_null(b.tower_at(cell))
	assert_eq(b.tick, tick, "no tick ran")


# The creature panel.

func test_enemy_panel_shows_the_real_numbers_and_its_special_rule() -> void:
	var b: Battle = Fx.battle()
	b.start_next_wave()
	Fx.steps(b, 5)
	var enemy: EnemyState = b.enemies[0]
	var panel: EnemyPanel = _keep(EnemyPanel.new()) as EnemyPanel
	panel.setup(b)
	panel.show_enemy(enemy.id)
	var type: EnemyType = b.catalog.enemy(enemy.type)
	var numbers: Dictionary = b.enemy_numbers(enemy.id)
	assert_eq(panel.name_label.text, type.name)
	assert_eq(panel.info_label.text, type.info, "the special rule is the data's one line")
	assert_eq(panel.health_label.text, "Health %d / %d" % [int(numbers["health"]), int(numbers["max_health"])])
	assert_eq(panel.armor_row.value_label.text, str(int(numbers["armor"])))
	assert_eq(panel.speed_row.value_label.text, "%s tiles/s" % BattleText.speed(int(numbers["speed"])))
	assert_eq(panel.lives_row.value_label.text, str(type.lives))
	assert_eq(panel.bounty_row.value_label.text, str(int(numbers["bounty"])))
	assert_eq(panel.move_label.text, "Walks")


func test_enemy_panel_follows_damage_and_a_slow() -> void:
	var b: Battle = Fx.battle()
	b.start_next_wave()
	Fx.steps(b, 3)
	var enemy: EnemyState = b.enemies[0]
	var panel: EnemyPanel = _keep(EnemyPanel.new()) as EnemyPanel
	panel.setup(b)
	panel.show_enemy(enemy.id)
	enemy.health -= 15
	enemy.slow_pct = 40
	enemy.slow_ticks = 40
	panel.refresh()
	assert_eq(panel.health_label.text, "Health %d / %d" % [enemy.health, enemy.max_health])
	assert_true(panel.speed_row.value_label.text.contains("base"), "slowed speed shows the base too")
	assert_true(_texts(panel).has("Slowed 40% for 2.0 s"))


func test_enemy_panel_for_a_flyer_and_a_boss() -> void:
	var b: Battle = Fx.battle_with_first_wave([
		{"enemy": "flitter", "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 1000},
		{"enemy": "grumblesack", "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 1000},
	])
	b.start_next_wave()
	Fx.steps(b, 3)
	var panel: EnemyPanel = _keep(EnemyPanel.new()) as EnemyPanel
	panel.setup(b)
	panel.show_enemy(b.enemies[0].id)
	assert_eq(panel.move_label.text, "Flies")
	panel.show_enemy(b.enemies[1].id)
	assert_eq(panel.name_label.text, b.catalog.enemy(&"grumblesack").name)
	assert_eq(panel.lives_row.value_label.text, str(b.catalog.enemy(&"grumblesack").lives))
	assert_eq(panel.info_label.text, b.catalog.enemy(&"grumblesack").info)


func test_enemy_panel_says_when_the_creature_is_gone() -> void:
	var b: Battle = Fx.battle()
	b.start_next_wave()
	Fx.steps(b, 3)
	var id: int = b.enemies[0].id
	var panel: EnemyPanel = _keep(EnemyPanel.new()) as EnemyPanel
	panel.setup(b)
	var gone: Array[int] = []
	panel.gone.connect(func(g: int) -> void: gone.append(g))
	panel.show_enemy(id)
	Fx.finish_wave(b)
	panel.refresh()
	panel.refresh()
	assert_eq(gone, [id] as Array[int], "announced once")
	assert_eq(panel.health_label.text, "Gone from the map.")


# The wave preview.

func _preview_texts(panel: WavePreview) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for row: TapRow in panel.rows:
		out.append_array(_texts(row))
	return out


func test_preview_matches_the_next_wave_of_every_region_1_level() -> void:
	for id: StringName in Fx.game().levels:
		var b: Battle = Fx.battle(id)
		var panel: WavePreview = _keep(WavePreview.new()) as WavePreview
		panel.setup(b)
		var groups: Array[WaveGroup] = b.level.waves[0].groups
		assert_eq(panel.rows.size(), groups.size(), String(id))
		var texts: PackedStringArray = _preview_texts(panel)
		for group: WaveGroup in groups:
			assert_true(texts.has(b.catalog.enemy(group.enemy).name), "%s shows %s" % [id, group.enemy])
			assert_true(texts.has("x%d" % group.count))
			assert_true(texts.has("from %s" % BattleText.entrance_letter(group.entrance + 1)))
		assert_true(_texts(panel).has("Next: wave 1 of %d" % b.wave_count()))


func test_preview_moves_to_the_next_wave_and_folds_during_a_wave() -> void:
	var b: Battle = Fx.battle(&"r1_l1")
	var panel: WavePreview = _keep(WavePreview.new()) as WavePreview
	panel.setup(b)
	assert_true(panel.expanded)
	b.start_next_wave()
	panel.refresh()
	assert_false(panel.expanded, "folded into a strip during a wave")
	assert_eq(panel.rows.size(), 0)
	assert_true(_texts(panel).has("Next: wave 2 of %d" % b.wave_count()))
	assert_eq(panel.index, 1)
	var chips: PackedStringArray = _texts(panel)
	var first: WaveGroup = b.level.waves[1].groups[0]
	assert_true(chips.has("%d %s" % [first.count, BattleText.entrance_letter(first.entrance + 1)]), "the strip shows counts and entrances")
	panel.toggle()
	assert_true(panel.expanded, "a tap opens the strip")
	assert_eq(panel.rows.size(), b.level.waves[1].groups.size())
	Fx.finish_wave(b)
	panel.refresh()
	assert_true(panel.expanded, "open again in the build phase")


func test_preview_new_tag_boss_line_and_creature_numbers() -> void:
	var b: Battle = Fx.battle(&"r1_l6")
	var last: int = b.wave_count() - 1
	b.waves_started = last
	var panel: WavePreview = _keep(WavePreview.new()) as WavePreview
	var unseen: Array[StringName] = [&"grumblesack"]
	panel.set_unseen(unseen)
	panel.setup(b)
	assert_eq(panel.index, last)
	var texts: PackedStringArray = _preview_texts(panel)
	assert_true(texts.has("New"), "an unseen creature is tagged with the word")
	assert_true(texts.has(b.catalog.enemy(&"grumblesack").info), "a boss row always shows its one line")
	assert_false(texts.has(b.catalog.enemy(&"scamp").info), "an ordinary row does not")
	var boss: Dictionary = {}
	for entry: Dictionary in b.wave_preview(last):
		if entry["enemy"] == &"grumblesack":
			boss = entry
	panel.toggle_row(&"grumblesack")
	assert_true(_preview_texts(panel).has("Health %d, gold %d when defeated" % [int(boss["health"]), int(boss["bounty"])]))
	var none: Array[StringName] = []
	panel.set_unseen(none)
	assert_false(_preview_texts(panel).has("New"))


# Names come from the data.

func test_no_display_name_is_written_in_the_panel_sources() -> void:
	var names: PackedStringArray = PackedStringArray()
	var catalog: Catalog = Fx.game().catalog
	for id: StringName in catalog.tower_ids():
		var type: TowerType = catalog.tower(id)
		names.append(type.name)
		names.append(type.plural)
		names.append(type.spec_name(0))
		names.append(type.spec_name(1))
	for id: StringName in catalog.enemy_ids():
		names.append(catalog.enemy(id).name)
	var files: PackedStringArray = [
		"battle_text", "battle_panel", "battle_hud", "build_panel", "tower_panel", "enemy_panel",
		"wave_preview", "glyph_icon", "stat_row", "tap_row", "health_bar",
	]
	var literal: RegEx = RegEx.create_from_string("\"[^\"\\n]*\"")
	for file: String in files:
		var path: String = "res://src/ui/%s.gd" % file
		var source: String = FileAccess.get_file_as_string(path)
		assert_false(source.is_empty(), path)
		for hit: RegExMatch in literal.search_all(source):
			var text: String = hit.get_string()
			for display: String in names:
				if text.contains(display):
					fail("%s writes the name %s in %s" % [path, display, text])
