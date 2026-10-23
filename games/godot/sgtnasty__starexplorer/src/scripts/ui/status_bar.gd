# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name StatusBar
extends PanelContainer
## One-line HUD with credits, hull, shield, fuel, cargo and crew.
## Redraws itself whenever Game emits state_changed.

var _label: RichTextLabel


func _init() -> void:
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_label)


func _ready() -> void:
	Game.state_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var s := Game.ship
	var c := Game.crew
	var parts: Array[String] = [
		_kv("CR", str(Game.credits), UIKit.GOLD),
		_kv("HULL", "%d/%d" % [s.hull, s.max_hull], _ratio_color(s.hull, s.max_hull)),
		_kv("SHLD", "%d/%d" % [s.shield_points, s.max_shield()], UIKit.ACCENT),
		_kv("FUEL", "%d/%d" % [s.fuel, s.max_fuel()], _ratio_color(s.fuel, s.max_fuel())),
		_kv("CARGO", "%d/%d" % [s.cargo.total(), s.cargo.capacity], UIKit.TEXT),
		_kv("CREW", "%d/%d" % [c.hands, c.max_hands], _ratio_color(c.hands, c.max_hands)),
	]
	if Game.notoriety > 0:
		parts.append(_kv("WANTED", str(Game.notoriety), UIKit.BAD))
	_label.text = "  ".join(parts)


func _kv(key: String, value: String, color: Color) -> String:
	return "[color=#%s]%s[/color] [color=#%s]%s[/color]" % [UIKit.DIM.to_html(false), key, color.to_html(false), value]


func _ratio_color(v: int, m: int) -> Color:
	if v * 3 <= m:
		return UIKit.BAD
	if v * 3 <= m * 2:
		return UIKit.WARN
	return UIKit.GOOD
