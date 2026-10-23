# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Screen
## Shown when the hull or the crew reaches zero. The save is already gone.


func enter(_params: Dictionary) -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := UIKit.vbox(4)
	center.add_child(UIKit.panel(col))

	col.add_child(UIKit.label("GAME OVER", UIKit.BAD, UIKit.TITLE_SIZE))
	col.add_child(UIKit.label(Game.game_over_reason))
	col.add_child(UIKit.label(" "))
	var s := Game.stats
	var rows := [
		["Jumps made", s.get("jumps", 0)],
		["Systems visited", Game.visited.size()],
		["Units mined", s.get("units_mined", 0)],
		["Credits earned", s.get("credits_earned", 0)],
		["Pirates defeated", s.get("pirates_defeated", 0)],
		["Ships boarded", s.get("ships_boarded", 0)],
		["Monsters slain", s.get("monsters_slain", 0)],
	]
	for r in rows:
		var h := UIKit.hbox()
		var k := UIKit.label(r[0], UIKit.DIM)
		k.custom_minimum_size.x = 120
		h.add_child(k)
		h.add_child(UIKit.label(str(r[1]), UIKit.GOLD))
		col.add_child(h)
	col.add_child(UIKit.label(" "))
	col.add_child(UIKit.button("Return to Title", back))
	focus_first(col)


func back() -> void:
	go("title")
