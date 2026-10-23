# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name ResourceDB
extends RefCounted
## Static table of the minable resources: names, prices and how hard they
## are to detect with a science scan.

## Display order everywhere in the UI.
const ORDER: Array[String] = ["iron", "ice", "hydrogen", "organics", "uranium", "crystals", "exotic"]

## price: base credits per unit at a starbase.
## difficulty: minimum science officer skill needed to detect a deposit
## (each deposit may roll +1 on top of this).
const DATA := {
	"iron": {"name": "Iron Ore", "price": 12, "difficulty": 0, "color": "#c2c3c7"},
	"ice": {"name": "Water Ice", "price": 9, "difficulty": 0, "color": "#a8e4ff"},
	"hydrogen": {"name": "Hydrogen", "price": 7, "difficulty": 0, "color": "#ffb0e0"},
	"organics": {"name": "Organics", "price": 16, "difficulty": 1, "color": "#6ad35a"},
	"uranium": {"name": "Uranium", "price": 34, "difficulty": 2, "color": "#d4ff3a"},
	"crystals": {"name": "Crystals", "price": 42, "difficulty": 2, "color": "#c070ff"},
	"exotic": {"name": "Exotic Matter", "price": 95, "difficulty": 3, "color": "#ff5adc"},
}


static func name_of(id: String) -> String:
	return DATA[id]["name"]


static func base_price(id: String) -> int:
	return DATA[id]["price"]


static func difficulty(id: String) -> int:
	return DATA[id]["difficulty"]


static func color_of(id: String) -> Color:
	return Color(DATA[id]["color"])


static func icon(id: String) -> Texture2D:
	return load("res://assets/sprites/res_%s.png" % id)
