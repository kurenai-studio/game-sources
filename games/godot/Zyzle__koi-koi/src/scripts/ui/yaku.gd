class_name Yaku
extends VBoxContainer

const CARD_SCENE_PATH = "res://scenes/card_visual.tscn"

@onready var english_label: Label = %EnglishLabel
@onready var japanese_label: Label = %JapaneseLabel
@onready var cards_container: HBoxContainer = %CardsContainer

var english_name: String
var japanese_name: String
var points: int
var cards: Array[Card]

func _ready() -> void:
	english_label.text = english_name
	japanese_label.text = japanese_name

	for card in cards:
		var card_control = TextureRect.new()
		card_control.custom_minimum_size = Vector2(55, 90)
		card_control.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_control.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		card_control.texture = load("res://assets/%d-%d.png" % [card.month, card.number])
		cards_container.add_child(card_control)

func setup(english: String, japanese: String, pts: int, c: Array[Card]) -> void:
	english_name = english
	japanese_name = japanese
	points = pts
	cards = c