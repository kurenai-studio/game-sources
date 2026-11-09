extends Node

enum GameSpeed {PAUSED, NORMAL, FAST}

signal country_hover()
signal country_unhover

signal country_click(pos: Vector2)
signal country_unclick

var hovered_countries = 0
var clicked = false

var game_speed = GameSpeed.PAUSED
var map_hoverable = true

var PlayerCountry
var selected_country

func _ready() -> void:
	# Fetch the root of the active scene and check if it's already done
	var current_scene = get_tree().current_scene
	if current_scene.is_node_ready():
		_on_entire_tree_ready()
	else:
		current_scene.ready.connect(_on_entire_tree_ready)

func _on_entire_tree_ready():
	pass

func country_init() -> void:
	
	PlayerCountry = CountryManager.countries[4]
	selected_country = CountryManager.countries[0]

func map_hover(country: Country) -> void:
	hovered_countries += 1
	if not clicked:
		selected_country = country
	country_hover.emit()

func map_unhover() -> void:
	hovered_countries -= 1
	if hovered_countries <= 0:
		country_unhover.emit()

func map_click(country: Country, pos: Vector2) -> void:
	clicked = true
	selected_country = country
	country_click.emit(pos)

func map_unclick() -> void:
	clicked = false
	country_unclick.emit()
