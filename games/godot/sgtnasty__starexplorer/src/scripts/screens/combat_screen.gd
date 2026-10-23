# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Screen
## Turn-based ship combat and boarding on top of CombatEngine.

var _engine: CombatEngine
var _player_sprite: TextureRect
var _enemy_sprite: TextureRect
var _player_stats: VBoxContainer
var _enemy_stats: VBoxContainer
var _log: RichTextLabel
var _actions: HBoxContainer
var _beam: ColorRect


func enter(params: Dictionary) -> void:
	var enc: Encounter = params["encounter"]
	_engine = CombatEngine.new(Game.ship, Game.crew, enc, Game.rng)

	var root := make_root()
	var col := UIKit.vbox(4)
	root.add_child(col)
	col.add_child(StatusBar.new())

	var stage := UIKit.hbox(6)
	stage.custom_minimum_size.y = 110
	col.add_child(stage)
	_player_stats = UIKit.vbox(2)
	_player_stats.custom_minimum_size.x = 120
	stage.add_child(UIKit.panel(_player_stats))
	_player_sprite = UIKit.sprite(load("res://assets/sprites/ship_player.png"), 3)
	stage.add_child(_player_sprite)
	stage.add_child(UIKit.spacer())
	var is_monster := enc.kind == "monster"
	_enemy_sprite = UIKit.sprite(load(enc.sprite), 2 if is_monster else 3, not is_monster)
	stage.add_child(_enemy_sprite)
	_enemy_stats = UIKit.vbox(2)
	_enemy_stats.custom_minimum_size.x = 120
	stage.add_child(UIKit.panel(_enemy_stats))

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var log_panel := UIKit.panel(_log)
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(log_panel)

	_actions = UIKit.hbox(4)
	col.add_child(_actions)

	_beam = ColorRect.new()
	_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beam.visible = false
	add_child(_beam)

	_say("[color=#%s]%s[/color]" % [UIKit.WARN.to_html(false), enc.title])
	_refresh()
	if params.get("ambush", false):
		await get_tree().process_frame  # let layout settle so the beam lines up
		_engine.ambush()
		_after_turn()


func _refresh() -> void:
	_fill_stats(_player_stats, Game.ship.ship_name, Game.ship.hull, Game.ship.max_hull,
		Game.ship.shield_points, Game.ship.max_shield(), Game.crew.hands)
	var e := _engine.enemy
	_fill_stats(_enemy_stats, e.title.get_slice("'", 1) if e.title.contains("'") else e.title,
		e.hull, e.max_hull, e.shield, e.max_shield, e.hands if e.boardable else -1)
	_build_actions()


func _fill_stats(box: VBoxContainer, title: String, hull: int, max_hull: int, shield: int, max_shield: int, hands: int) -> void:
	UIKit.clear(box)
	box.add_child(UIKit.label(title, UIKit.ACCENT))
	box.add_child(UIKit.label("Hull %d/%d" % [hull, max_hull]))
	box.add_child(UIKit.bar(hull, max_hull, UIKit.GOOD, 110))
	if max_shield > 0:
		box.add_child(UIKit.label("Shield %d/%d" % [shield, max_shield]))
		box.add_child(UIKit.bar(shield, max_shield, UIKit.ACCENT, 110))
	if hands >= 0:
		box.add_child(UIKit.label("Crew %d" % hands))


func _build_actions() -> void:
	var key := focused_key()
	UIKit.clear(_actions)
	var e := _engine
	if e.over:
		_actions.add_child(UIKit.button("Continue", _on_continue, false, "continue"))
	elif e.boarding:
		_actions.add_child(UIKit.button("Charge (%d)" % e.boarding_strength(true), _board.bind("charge"), false, "charge"))
		_actions.add_child(UIKit.button("Hold (%d)" % e.boarding_strength(false), _board.bind("hold"), false, "hold"))
		_actions.add_child(UIKit.button("Retreat", _board.bind("retreat"), false, "retreat"))
		_actions.add_child(UIKit.label("Defenders: %d" % e.enemy_boarding_strength(), UIKit.DIM))
	else:
		_actions.add_child(UIKit.button("Fire (%d%%)" % e.player_hit_chance(), _act.bind("fire"), false, "fire"))
		_actions.add_child(UIKit.button("Evade", _act.bind("evade"), false, "evade"))
		var full := Game.ship.shield_points >= Game.ship.max_shield()
		_actions.add_child(UIKit.button("Shields +%d" % Game.ship.shield_recharge(), _act.bind("recharge"), full, "recharge"))
		var board := UIKit.button("Board", _act.bind("board"), not e.can_board(), "board")
		board.tooltip_text = e.board_reason()
		_actions.add_child(board)
		_actions.add_child(UIKit.button("Flee (%d%%)" % e.flee_chance(), _act.bind("flee"), false, "flee"))
	refocus(key, _actions)


func _act(action: String) -> void:
	_engine.act(action)
	_after_turn()


func _board(action: String) -> void:
	_engine.board(action)
	_after_turn()


func _after_turn() -> void:
	for line in _engine.lines:
		_say(line)
	for ev in _engine.events:
		if ev["type"] == "shot":
			_shoot(ev["by"] == "player", ev["hit"])
	if _engine.over:
		for line in Game.apply_combat_outcome(_engine):
			_say("[color=#%s]%s[/color]" % [UIKit.GOOD.to_html(false), line])
	Game.changed()
	_refresh()


func _say(text: String) -> void:
	_log.append_text(text + "\n")


## A short laser flash between the ships, and a flicker on a hit.
func _shoot(by_player: bool, hit: bool) -> void:
	var from := _player_sprite if by_player else _enemy_sprite
	var to := _enemy_sprite if by_player else _player_sprite
	var a := from.get_global_rect().get_center()
	var b := to.get_global_rect().get_center()
	if not hit:
		b.y += 24.0
	_beam.visible = true
	_beam.color = UIKit.GOOD if by_player else UIKit.BAD
	_beam.position = Vector2(minf(a.x, b.x), (a.y + b.y) * 0.5)
	_beam.size = Vector2(absf(b.x - a.x), 1)
	var t := create_tween()
	t.tween_property(_beam, "modulate:a", 0.0, 0.25).from(1.0)
	t.tween_callback(func() -> void: _beam.visible = false)
	if hit:
		var f := create_tween()
		f.tween_property(to, "modulate", Color(3, 3, 3), 0.05)
		f.tween_property(to, "modulate", Color.WHITE, 0.15)


func _on_continue() -> void:
	if _engine.outcome == "defeat" or Game.check_game_over():
		go("game_over")
	else:
		go("system")


func back() -> void:
	pass  # no backing out of a fight; use Flee
