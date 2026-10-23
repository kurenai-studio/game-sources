# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Screen
## A random encounter: the non-combat choices for each kind of contact.
## Fights hand off to the combat screen.

var _enc: Encounter
var _body: VBoxContainer
var _text: Label


func enter(params: Dictionary) -> void:
	_enc = params["encounter"]
	var root := make_root()
	var col := UIKit.vbox(4)
	root.add_child(col)
	col.add_child(StatusBar.new())

	var stage := UIKit.hbox()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_child(UIKit.sprite(load("res://assets/sprites/ship_player.png"), 4))
	var gap := Control.new()
	gap.custom_minimum_size.x = 200
	stage.add_child(gap)
	stage.add_child(UIKit.sprite(load(_enc.sprite), 4 if _enc.kind != "monster" else 3, _enc.kind != "monster"))
	col.add_child(stage)

	var info := UIKit.vbox(3)
	col.add_child(UIKit.panel(info))
	info.add_child(UIKit.label(_enc.title, _kind_color(), UIKit.TITLE_SIZE))
	_text = UIKit.wrap_label(_enc.description)
	info.add_child(_text)

	_body = UIKit.vbox(3)
	_body.custom_minimum_size.y = 40
	col.add_child(_body)
	_show_choices()


func _kind_color() -> Color:
	match _enc.kind:
		"pirate", "monster":
			return UIKit.BAD
		"trader":
			return UIKit.GOLD
	return UIKit.ACCENT


func _flee_chance() -> int:
	return CombatEngine.new(Game.ship, Game.crew, _enc, Game.rng).flee_chance()


func _show_choices() -> void:
	UIKit.clear(_body)
	var row := UIKit.hbox(4)
	_body.add_child(row)
	match _enc.kind:
		"pirate":
			row.add_child(UIKit.button("Fight", _fight.bind(false), false, "opt_fight"))
			row.add_child(UIKit.button("Flee (%d%%)" % _flee_chance(), _try_flee, false, "opt_flee"))
			row.add_child(UIKit.button("Pay tribute", _tribute, false, "opt_tribute"))
			row.add_child(UIKit.button("Intimidate (%d%%)" % Game.intimidate_chance(_enc), _intimidate, false, "opt_intimidate"))
		"trader":
			row.add_child(UIKit.button("Trade", _show_trade, false, "opt_trade"))
			row.add_child(UIKit.button("Attack", _attack_lawful, false, "opt_attack"))
			row.add_child(UIKit.button("Leave", _finish.bind("You wish them safe travels."), false, "opt_leave"))
		"patrol":
			if Game.notoriety > 0:
				_text.text = "\"%s, you are wanted for piracy. Pay %d cr in fines or be taken in.\"" % [Game.ship.ship_name, Game.fine_amount()]
				row.add_child(UIKit.button("Pay fine (%d)" % Game.fine_amount(), _pay_fine, Game.credits < Game.fine_amount(), "opt_fine"))
				row.add_child(UIKit.button("Resist", _attack_lawful, false, "opt_attack"))
				row.add_child(UIKit.button("Flee (%d%%)" % _flee_chance(), _try_flee, false, "opt_flee"))
			else:
				_text.text = "\"Routine inspection, Captain. Your papers are in order.\""
				if Game.bounties > 0:
					row.add_child(UIKit.button("Claim %d bount%s" % [Game.bounties, "y" if Game.bounties == 1 else "ies"], _claim, false, "opt_claim"))
				if Game.ship.fuel <= 0:
					row.add_child(UIKit.button("Request fuel", _request_fuel, false, "opt_fuel"))
				row.add_child(UIKit.button("Attack", _attack_lawful, false, "opt_attack"))
				row.add_child(UIKit.button("Leave", _finish.bind("The cutter waves you on."), false, "opt_leave"))
		"monster":
			row.add_child(UIKit.button("Fight", _fight.bind(false), false, "opt_fight"))
			row.add_child(UIKit.button("Flee (%d%%)" % _flee_chance(), _try_flee, false, "opt_flee"))
			row.add_child(UIKit.button("Go dark (%d%%)" % Game.sneak_chance(_enc), _sneak, false, "opt_sneak"))
	focus_first(_body)


func _fight(ambushed: bool) -> void:
	go("combat", {"encounter": _enc, "ambush": ambushed})


func _attack_lawful() -> void:
	Game.attack_lawful(_enc)
	_fight(false)


func _try_flee() -> void:
	if Game.roll_percent(_flee_chance()):
		_finish("You outrun them and lose them in the dark.")
	else:
		Game.log_msg("Escape failed!")
		_fight(true)


func _tribute() -> void:
	Game.pay_tribute(_enc)
	_finish("The pirates take their cut and vanish.")


func _intimidate() -> void:
	if Game.roll_percent(Game.intimidate_chance(_enc)):
		_finish("Your captain's cold stare and loaded guns do the talking. The pirates back off.")
	else:
		Game.log_msg("The pirates laugh off your threats.")
		_fight(true)


func _sneak() -> void:
	if Game.roll_percent(Game.sneak_chance(_enc)):
		_finish("You cut power and drift silently until the creature loses interest.")
	else:
		Game.log_msg("The creature senses you!")
		_fight(true)


func _pay_fine() -> void:
	Game.pay_fine()
	_finish("Fines paid. The Patrol updates your record.")


func _claim() -> void:
	Game.claim_bounties()
	_show_choices()


func _request_fuel() -> void:
	Game.ship.fuel = 1
	Game.log_msg("The Patrol transfers one unit of fuel.")
	Game.changed()
	_show_choices()


func _show_trade() -> void:
	var key := focused_key()
	UIKit.clear(_body)
	_text.text = "\"Let's see what you've got.\" Fuel for sale at %d cr." % (Game.FUEL_PRICE + 5)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	_body.add_child(grid)
	var cargo := Game.ship.cargo
	for id in ResourceDB.ORDER:
		if cargo.count(id) <= 0:
			continue
		var price := _enc.trader_buy_price(id, Game.crew.skill("captain"))
		grid.add_child(UIKit.label("%s x%d" % [ResourceDB.name_of(id), cargo.count(id)], ResourceDB.color_of(id)))
		grid.add_child(UIKit.label("%d cr" % price, UIKit.GOLD))
		grid.add_child(UIKit.button("Sell 1", _trade_sell.bind(id, 1, price), false, "sell1_" + id))
		grid.add_child(UIKit.button("Sell all", _trade_sell.bind(id, cargo.count(id), price), false, "sellall_" + id))
	if cargo.is_empty():
		_body.add_child(UIKit.label("Your hold is empty.", UIKit.DIM))
	var row := UIKit.hbox(4)
	_body.add_child(row)
	var fuel_full := Game.ship.fuel >= Game.ship.max_fuel()
	row.add_child(UIKit.button("Buy fuel", _trade_fuel, fuel_full or Game.credits < Game.FUEL_PRICE + 5, "buy_fuel"))
	row.add_child(UIKit.button("Done", _finish.bind("The trader departs."), false, "done"))
	refocus(key, _body)


func _trade_sell(id: String, qty: int, price: int) -> void:
	Game.sell(id, qty, price)
	_show_trade()


func _trade_fuel() -> void:
	Game.credits -= Game.FUEL_PRICE + 5
	Game.ship.fuel += 1
	Game.log_msg("Bought 1 fuel from the trader.")
	Game.changed()
	_show_trade()


func _finish(text: String) -> void:
	Game.log_msg(text)
	UIKit.clear(_body)
	_text.text = text
	_body.add_child(UIKit.button("Continue", go.bind("system", {}), false, "continue"))
	focus_first(_body)


func back() -> void:
	pass  # an encounter must be resolved
