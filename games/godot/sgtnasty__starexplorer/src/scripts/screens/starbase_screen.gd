# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Screen
## A docked starbase: market, shipyard, crew training and the Patrol office.

const TABS: Array[String] = ["Market", "Shipyard", "Crew", "Patrol Office"]

var _tab := 0
var _tabs: HBoxContainer
var _content: VBoxContainer
var _log: Label


func enter(_params: Dictionary) -> void:
	Game.log_msg("Docked at %s Starbase." % Game.star()["name"])
	Game.save_game()
	var root := make_root()
	var col := UIKit.vbox(4)
	root.add_child(col)
	col.add_child(StatusBar.new())

	var header := UIKit.hbox(8)
	header.add_child(UIKit.sprite(load("res://assets/sprites/starbase.png"), 1))
	header.add_child(UIKit.label("%s Starbase" % Game.star()["name"], UIKit.ACCENT, UIKit.TITLE_SIZE))
	col.add_child(header)

	_tabs = UIKit.hbox(3)
	col.add_child(_tabs)
	for i in TABS.size():
		var b := UIKit.button(TABS[i], _set_tab.bind(i), false, "tab_%d" % i)
		b.toggle_mode = true
		b.focus_entered.connect(_set_tab.bind(i))
		_tabs.add_child(b)
	_tabs.add_child(UIKit.spacer())
	_tabs.add_child(UIKit.button("Undock", back, false, "undock"))

	_content = UIKit.vbox(2)
	var panel := UIKit.panel(_content)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(panel)

	_log = UIKit.label("", UIKit.DIM)
	col.add_child(_log)
	Game.message_logged.connect(_on_message)

	_rebuild()
	focus_first(_tabs)


func _on_message(text: String) -> void:
	_log.text = text


func back() -> void:
	Game.save_game()
	go("system")


func _set_tab(i: int) -> void:
	if i == _tab:
		return
	_tab = i
	_rebuild()


func _rebuild() -> void:
	var key := focused_key()
	for i in TABS.size():
		(_tabs.get_child(i) as Button).set_pressed_no_signal(i == _tab)
	UIKit.clear(_content)
	match _tab:
		0: _build_market()
		1: _build_shipyard()
		2: _build_crew()
		3: _build_patrol()
	refocus(key, _tabs)


## Runs a Game action, shows its error if any, and redraws.
func _do(action: Callable) -> void:
	var err: String = action.call()
	if err != "":
		_log.text = err
	_rebuild()


func _grid(columns: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 2)
	_content.add_child(g)
	return g


func _build_market() -> void:
	var g := _grid(7)
	for h in ["", "Resource", "Hold", "Sell", "Buy", "", ""]:
		g.add_child(UIKit.label(h, UIKit.DIM))
	var cargo := Game.ship.cargo
	for id in ResourceDB.ORDER:
		var have := cargo.count(id)
		g.add_child(UIKit.sprite(ResourceDB.icon(id), 1))
		var n := UIKit.label(ResourceDB.name_of(id), ResourceDB.color_of(id))
		n.custom_minimum_size.x = 80
		g.add_child(n)
		g.add_child(UIKit.label(str(have)))
		g.add_child(UIKit.label("%d" % Game.sell_price(id), UIKit.GOLD))
		g.add_child(UIKit.label("%d" % Game.buy_price(id), UIKit.WARN))
		var sell := UIKit.hbox(2)
		sell.add_child(UIKit.button("Sell 1", _do.bind(_sell.bind(id, 1)), have <= 0, "sell1_" + id))
		sell.add_child(UIKit.button("Sell all", _do.bind(_sell.bind(id, have)), have <= 0, "sellall_" + id))
		g.add_child(sell)
		var full := cargo.free_space() <= 0 or Game.credits < Game.buy_price(id)
		g.add_child(UIKit.button("Buy 1", _do.bind(Game.buy.bind(id, 1)), full, "buy1_" + id))
	var row := UIKit.hbox(4)
	row.add_child(UIKit.button("Sell entire hold", _do.bind(_sell_all), cargo.is_empty(), "sell_everything"))
	row.add_child(UIKit.label("Captain skill %d raises sell prices." % Game.crew.skill("captain"), UIKit.DIM))
	_content.add_child(row)


func _sell(id: String, qty: int) -> String:
	Game.sell(id, qty)
	return ""


func _sell_all() -> String:
	Game.sell_all()
	return ""


func _build_shipyard() -> void:
	var ship := Game.ship
	var top := UIKit.hbox(4)
	top.add_child(UIKit.button("Repair hull (%d cr)" % Game.repair_cost(), _do.bind(Game.repair), ship.hull >= ship.max_hull, "repair"))
	top.add_child(UIKit.button("Refuel (%d cr)" % Game.refuel_cost(), _do.bind(Game.refuel), ship.fuel >= ship.max_fuel(), "refuel"))
	top.add_child(UIKit.label("Power %d/%d used" % [ship.power_used(), ship.power_capacity()], UIKit.ACCENT))
	_content.add_child(top)
	var g := _grid(5)
	for h in ["System", "Lv", "Effect", "Next level cost", ""]:
		g.add_child(UIKit.label(h, UIKit.DIM))
	for sys in Ship.SYSTEMS:
		var n := UIKit.label(Ship.SYSTEM_NAMES[sys])
		n.custom_minimum_size.x = 70
		g.add_child(n)
		g.add_child(UIKit.label("%d/%d" % [ship.level(sys), Ship.MAX_LEVEL], UIKit.GOLD))
		g.add_child(UIKit.label(Ship.SYSTEM_DESC[sys], UIKit.DIM))
		g.add_child(_cost_box(sys))
		var reason := Game.upgrade_block_reason(sys)
		var b := UIKit.button("Upgrade" if reason == "" else reason, _do.bind(Game.upgrade.bind(sys)), reason != "", "up_" + sys)
		g.add_child(b)


func _cost_box(sys: String) -> Control:
	var box := UIKit.hbox(2)
	if Game.ship.level(sys) >= Ship.MAX_LEVEL:
		box.add_child(UIKit.label("-", UIKit.DIM))
		return box
	var cost := Game.ship.upgrade_cost(sys)
	var c: int = cost["credits"]
	box.add_child(UIKit.label("%d cr" % c, UIKit.GOLD if Game.credits >= c else UIKit.BAD))
	var res: Dictionary = cost["resources"]
	for id in res:
		box.add_child(UIKit.sprite(ResourceDB.icon(id), 1))
		var ok: bool = Game.ship.cargo.count(id) >= res[id]
		box.add_child(UIKit.label("%d" % res[id], UIKit.TEXT if ok else UIKit.BAD))
	return box


func _build_crew() -> void:
	var crew := Game.crew
	var top := UIKit.hbox(4)
	var full := crew.hands >= crew.max_hands
	top.add_child(UIKit.button("Hire crew (%d cr)" % Crew.HIRE_COST, _do.bind(Game.hire), full or Game.credits < Crew.HIRE_COST, "hire"))
	top.add_child(UIKit.label("Hands aboard: %d/%d" % [crew.hands, crew.max_hands], UIKit.ACCENT))
	_content.add_child(top)
	var g := _grid(4)
	for h in ["Officer", "Skill", "Effect", ""]:
		g.add_child(UIKit.label(h, UIKit.DIM))
	for role in Crew.ROLES:
		var n := UIKit.label(Crew.ROLE_NAMES[role])
		n.custom_minimum_size.x = 90
		g.add_child(n)
		g.add_child(UIKit.label("%d/%d" % [crew.skill(role), Crew.MAX_SKILL], UIKit.GOLD))
		g.add_child(UIKit.label(Crew.ROLE_DESC[role], UIKit.DIM))
		var text := "Maxed"
		var disabled := true
		if crew.can_train(role):
			text = "Train (%d cr)" % crew.training_cost(role)
			disabled = Game.credits < crew.training_cost(role)
		g.add_child(UIKit.button(text, _do.bind(Game.train.bind(role)), disabled, "train_" + role))


func _build_patrol() -> void:
	_content.add_child(UIKit.label("Star Patrol liaison office", UIKit.ACCENT))
	if Game.notoriety > 0:
		_content.add_child(UIKit.label("You are WANTED (notoriety %d). Patrol cutters will stop you." % Game.notoriety, UIKit.BAD))
		_content.add_child(UIKit.button("Pay fines (%d cr)" % Game.fine_amount(), _do.bind(Game.pay_fine), Game.credits < Game.fine_amount(), "fine"))
	else:
		_content.add_child(UIKit.label("Your record is clean.", UIKit.GOOD))
	var reward := Game.bounties * Game.BOUNTY_PER_PIRATE
	_content.add_child(UIKit.label("Unclaimed pirate bounties: %d (%d cr)" % [Game.bounties, reward]))
	_content.add_child(UIKit.button("Claim bounties", _do.bind(Game.claim_bounties), Game.bounties <= 0, "claim"))
	_content.add_child(UIKit.label(" "))
	var s := Game.stats
	_content.add_child(UIKit.label("Service record: %d jumps, %d systems, %d units mined, %d pirates, %d monsters." % [
		s.get("jumps", 0), Game.visited.size(), s.get("units_mined", 0),
		s.get("pirates_defeated", 0), s.get("monsters_slain", 0)], UIKit.DIM))
	_content.add_child(UIKit.label("Net worth: %d cr" % Game.net_worth(), UIKit.GOLD))
