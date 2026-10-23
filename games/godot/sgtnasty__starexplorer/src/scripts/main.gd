# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
extends Control
## Root of the game: draws the starfield and swaps between screens.

const SCREENS := {
	"title": preload("res://scripts/screens/title_screen.gd"),
	"system": preload("res://scripts/screens/system_screen.gd"),
	"galaxy": preload("res://scripts/screens/galaxy_screen.gd"),
	"encounter": preload("res://scripts/screens/encounter_screen.gd"),
	"combat": preload("res://scripts/screens/combat_screen.gd"),
	"starbase": preload("res://scripts/screens/starbase_screen.gd"),
	"game_over": preload("res://scripts/screens/game_over_screen.gd"),
}

var _current: Screen


func _ready() -> void:
	theme = UIKit.build_theme()
	add_child(Starfield.new())
	goto("title")


func goto(screen_name: String, params: Dictionary = {}) -> void:
	if _current:
		remove_child(_current)
		_current.queue_free()
	_current = SCREENS[screen_name].new()
	_current.navigate.connect(goto)
	add_child(_current)
	_current.enter(params)
