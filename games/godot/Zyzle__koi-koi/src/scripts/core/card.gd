class_name Card
## Represents a single Hanafuda card
extends RefCounted

## Card types
enum CardType {
	PLAIN,
	ANIMAL,
	RIBBON,
	BRIGHT
}

var month: int
var number: int
var type: CardType
var points: int
var is_player_card: bool = false
var is_field_card: bool = false

func _init(m: int, n: int, t: CardType, p: int) -> void:
	month = m
	number = n
	type = t
	points = p


func _to_string():
	return "Card(month=%d, number=%d, type=%s, points=%d)" % [month, number, str(type), points]


func make_player_card() -> void:
	is_field_card = false
	is_player_card = true


func make_field_card() -> void:
	is_player_card = false
	is_field_card = true


func equals(other: Card) -> bool:
	return month == other.month and number == other.number and type == other.type and points == other.points