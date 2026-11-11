class_name Deck
extends Node2D

var cards: Array[CardVisual] = []

func add_card(card_visual: CardVisual) -> void:
	cards.append(card_visual)
	add_child(card_visual)


func remove_card(card_visual: CardVisual) -> void:
	cards.erase(card_visual)
	# there's no need to free the visual here as
	# remove_card is only used before reparent


func get_top_card() -> CardVisual:
	if cards.size() > 0:
		return cards[cards.size() - 1]
	return null


func clear_all_cards() -> void:
	for card in cards:
		if is_instance_valid(card):
			card.queue_free()
	cards.clear()