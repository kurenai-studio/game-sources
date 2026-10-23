# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Screen
## The current star system: pick a planet, scan it, extract its resources.
## Also the hub for docking, refining fuel and opening the galaxy map.

var _selected := 0
var _info: VBoxContainer
var _actions: VBoxContainer
var _log: Label
var _planet_row: HBoxContainer


func enter(_params: Dictionary) -> void:
	if Game.check_game_over():
		go.call_deferred("game_over")
		return
	Game.save_game()
	var root := make_root()
	var col := UIKit.vbox(4)
	root.add_child(col)
	col.add_child(StatusBar.new())

	var sys := Game.system()
	var header := UIKit.hbox(8)
	header.add_child(UIKit.label(sys.system_name, UIKit.ACCENT, UIKit.TITLE_SIZE))
	var star_desc := "Class %s star   Danger %d/4" % [sys.star_class, sys.danger]
	if sys.has_starbase:
		star_desc += "   Starbase in orbit"
	var desc := UIKit.label(star_desc, UIKit.DIM)
	desc.size_flags_vertical = Control.SIZE_SHRINK_END
	header.add_child(desc)
	col.add_child(header)

	var body := UIKit.hbox(6)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)

	var left := UIKit.vbox(4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	_planet_row = UIKit.hbox(4)
	left.add_child(_planet_row)
	for p in sys.planets:
		var b := UIKit.button(StarSystem.ROMAN[p.index], _select.bind(p.index), false, "planet_%d" % p.index)
		b.icon = p.texture()
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.custom_minimum_size = Vector2(48, 50)
		b.focus_entered.connect(_select.bind(p.index))
		_planet_row.add_child(b)
	_info = UIKit.vbox(2)
	_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var info_panel := UIKit.panel(_info)
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(info_panel)

	_actions = UIKit.vbox(3)
	_actions.custom_minimum_size.x = 150
	body.add_child(_actions)

	_log = UIKit.wrap_label("", UIKit.DIM)
	_log.custom_minimum_size.y = 50
	col.add_child(UIKit.panel(_log))
	Game.message_logged.connect(_on_message)
	_on_message("")

	_rebuild()
	focus_first(_planet_row)


func _select(index: int) -> void:
	if index == _selected:
		return
	_selected = index
	_rebuild()


func _rebuild() -> void:
	var key := focused_key()
	_build_info()
	_build_actions()
	refocus(key, _planet_row)


func _build_info() -> void:
	UIKit.clear(_info)
	var sys := Game.system()
	var p: Planet = sys.planets[_selected]
	var head := UIKit.hbox()
	head.add_child(UIKit.label(p.planet_name, UIKit.TEXT))
	head.add_child(UIKit.label(p.type_name(), UIKit.DIM))
	_info.add_child(head)

	var science := Game.crew.skill("science")
	var scan_level := Game.galaxy.scan_level(sys.id, p)
	if scan_level < 0:
		_info.add_child(UIKit.wrap_label("Unscanned. Your science officer can survey it for deposits.", UIKit.DIM))
		_info.add_child(UIKit.button("Scan planet", _on_scan.bind(p), false, "scan"))
		return

	var hidden := 0
	var shown := 0
	for i in p.deposits.size():
		if not Game.galaxy.deposit_visible(sys.id, p, i):
			hidden += 1
			continue
		shown += 1
		var dep: Dictionary = p.deposits[i]
		var row := UIKit.hbox()
		row.add_child(UIKit.sprite(ResourceDB.icon(dep["res"]), 1))
		var name_l := UIKit.label(ResourceDB.name_of(dep["res"]), ResourceDB.color_of(dep["res"]))
		name_l.custom_minimum_size.x = 80
		row.add_child(name_l)
		var amount: int = dep["amount"]
		var amt_l := UIKit.label("%d units" % amount if amount > 0 else "depleted", UIKit.TEXT if amount > 0 else UIKit.DIM)
		amt_l.custom_minimum_size.x = 60
		row.add_child(amt_l)
		var full := Game.ship.cargo.free_space() <= 0
		var text := "Cargo full" if full else "Extract +%d" % Game.extraction_yield(p, i)
		row.add_child(UIKit.button(text, _on_extract.bind(p, i), amount <= 0 or full, "extract_%d" % i))
		_info.add_child(row)
	if shown == 0 and hidden == 0:
		_info.add_child(UIKit.label("No useful deposits.", UIKit.DIM))
	if hidden > 0:
		_info.add_child(UIKit.wrap_label("%d more deposit%s below scanner threshold (Science %d)." % [hidden, "" if hidden == 1 else "s", scan_level], UIKit.WARN))
	if science > scan_level:
		_info.add_child(UIKit.button("Rescan with Science %d" % science, _on_scan.bind(p), false, "scan"))


func _build_actions() -> void:
	UIKit.clear(_actions)
	var sys := Game.system()
	_actions.add_child(UIKit.button("Galaxy Map", go.bind("galaxy", {}), false, "act_map"))
	if sys.has_starbase:
		_actions.add_child(UIKit.button("Dock at Starbase", go.bind("starbase", {}), false, "act_dock"))
	var refine := UIKit.button("Refine Fuel (2 H > 1)", _on_refine, not Game.can_refine_fuel(), "act_refine")
	_actions.add_child(refine)
	if Game.ship.fuel <= 0 and not Game.can_refine_fuel():
		_actions.add_child(UIKit.button("Distress Beacon", _on_distress, false, "act_distress"))
	_actions.add_child(UIKit.spacer())
	_actions.add_child(_cargo_summary())
	_actions.add_child(UIKit.button("Save & Quit", _on_quit, false, "act_quit"))


func _cargo_summary() -> Control:
	var box := UIKit.vbox(1)
	box.add_child(UIKit.label("Cargo hold", UIKit.DIM))
	var cargo := Game.ship.cargo
	if cargo.is_empty():
		box.add_child(UIKit.label("  empty", UIKit.DIM))
	for id in ResourceDB.ORDER:
		if cargo.count(id) > 0:
			var row := UIKit.hbox(3)
			row.add_child(UIKit.sprite(ResourceDB.icon(id), 1))
			row.add_child(UIKit.label("%s x%d" % [ResourceDB.name_of(id), cargo.count(id)]))
			box.add_child(row)
	return box


func _on_message(_text: String) -> void:
	_log.text = "\n".join(Game.recent_messages(4))


func _on_scan(p: Planet) -> void:
	Game.scan_planet(p)
	_rebuild()


func _on_extract(p: Planet, deposit_index: int) -> void:
	Game.extract(p, deposit_index)
	Game.save_game()
	var enc := Game.roll_encounter("mining")
	if enc:
		go("encounter", {"encounter": enc})
		return
	_rebuild()


func _on_refine() -> void:
	Game.refine_fuel()
	_rebuild()


func _on_distress() -> void:
	Game.distress_tow()
	go("system")


func _on_quit() -> void:
	Game.save_game()
	go("title")
