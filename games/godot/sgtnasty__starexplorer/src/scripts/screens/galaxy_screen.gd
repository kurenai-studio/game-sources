# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Screen
## The galaxy map. Lists the systems in jump range; focusing one highlights
## it on the map, pressing it spends one fuel and jumps there.


## Draws the stars, the jump range and the selected route.
class MapView extends Control:
	var target := -1
	var _blink := 0.0

	func _process(delta: float) -> void:
		_blink = fmod(_blink + delta, 1.0)
		queue_redraw()

	func _draw() -> void:
		var g := Game.galaxy
		draw_rect(Rect2(Vector2.ZERO, size), Color(UIKit.BG, 0.7))
		draw_rect(Rect2(Vector2.ZERO, size), UIKit.BORDER, false)
		var here: Vector2 = g.star(Game.current_star)["pos"]
		draw_arc(here, Game.ship.jump_range(), 0.0, TAU, 64, Color(UIKit.ACCENT, 0.35), 1.0)
		if target >= 0:
			draw_line(here, g.star(target)["pos"], UIKit.GOLD, 1.0)
		for s in g.stars:
			var id: int = s["id"]
			var pos: Vector2 = (s["pos"] as Vector2).floor()
			var col := g.star_color(id)
			if not Game.visited.has(id):
				col = col.darkened(0.45)
			draw_rect(Rect2(pos - Vector2(1, 1), Vector2(3, 3)), col)
			if s["starbase"]:
				draw_rect(Rect2(pos - Vector2(3, 3), Vector2(7, 7)), UIKit.GOOD, false)
		if _blink < 0.6:
			draw_rect(Rect2(here.floor() - Vector2(4, 4), Vector2(9, 9)), Color.WHITE, false)
		if target >= 0:
			var tp: Vector2 = g.star(target)["pos"]
			draw_rect(Rect2(tp.floor() - Vector2(4, 4), Vector2(9, 9)), UIKit.GOLD, false)


var _map: MapView
var _info: Label
var _list: VBoxContainer


func enter(_params: Dictionary) -> void:
	var root := make_root()
	var col := UIKit.vbox(4)
	root.add_child(col)
	col.add_child(StatusBar.new())

	var body := UIKit.hbox(6)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)

	var left := UIKit.vbox(4)
	body.add_child(left)
	_map = MapView.new()
	_map.custom_minimum_size = Vector2(Galaxy.WIDTH, Galaxy.HEIGHT)
	left.add_child(_map)
	var legend := UIKit.label("[ ] you    green box / *: starbase    circle: jump range", UIKit.DIM)
	left.add_child(legend)
	_info = UIKit.wrap_label("", UIKit.TEXT)
	left.add_child(_info)

	var right := UIKit.vbox(3)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var fuel := Game.ship.fuel
	right.add_child(UIKit.label("Jump targets (fuel %d)" % fuel, UIKit.ACCENT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	right.add_child(scroll)
	_list = UIKit.vbox(2)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	for id in Game.reachable_stars():
		var s := Game.galaxy.star(id)
		var mark := "*" if s["starbase"] else " "
		var b := UIKit.button("%s %s  %.0f ly" % [mark, s["name"], Game.galaxy.distance(Game.current_star, id)], _on_jump.bind(id), fuel <= 0, "jump_%d" % id)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_entered.connect(_show.bind(id))
		_list.add_child(b)
	if fuel <= 0:
		right.add_child(UIKit.wrap_label("No fuel! Refine hydrogen or call for help.", UIKit.BAD))
	right.add_child(UIKit.button("Back to system", back))
	_show(-1)
	focus_first(right)


func _show(id: int) -> void:
	_map.target = id
	if id < 0:
		_info.text = "Current system: %s" % Game.star()["name"]
		return
	var s := Game.galaxy.star(id)
	var parts: Array[String] = ["%s  (class %s)" % [s["name"], s["cls"]], "Danger %d/4" % s["danger"]]
	if s["starbase"]:
		parts.append("Starbase")
	parts.append("Visited" if Game.visited.has(id) else "Unexplored")
	_info.text = "   ".join(parts)


func _on_jump(id: int) -> void:
	var err := Game.jump_to(id)
	if err != "":
		_info.text = err
		return
	var enc := Game.roll_encounter("arrival")
	if enc:
		go("encounter", {"encounter": enc})
	else:
		go("system")


func back() -> void:
	go("system")
