class_name Hand
extends Node2D

const CARD_SPACING = 130 # Actual spacing between card centers

var hand: Array[CardVisual] = []

func _tighten_hand_layout() -> void:
	for i in range(hand.size()):
		var target_position = Vector2(i * CARD_SPACING, 0)
		var card_visual = hand[i]
		var tween = get_tree().create_tween()
		tween.tween_property(card_visual, "position", target_position, 0.25)


func add_card(card_visual: CardVisual, and_flip: bool = false) -> Tween:
	var target_index = hand.size()
	var target_local_position = Vector2(target_index * CARD_SPACING, 0)
	# Store the global position before reparenting
	var start_global_pos = card_visual.global_position
	
	card_visual.reparent(self)
	hand.append(card_visual)
	
	# Restore global position after reparenting to prevent jump
	card_visual.global_position = start_global_pos

	if and_flip:
		card_visual.flip_card()
	
	var tween = get_tree().create_tween()
	tween.tween_property(card_visual, "position", target_local_position, 0.25)
	return tween


func remove_card(card_visual: CardVisual) -> void:
	# no need to free the card_visual as it will be reparented
	# in a subsequent call
	if hand.has(card_visual):
		hand.erase(card_visual)
		_tighten_hand_layout()


func clear_all_cards() -> void:
	hand.clear()
	for child in get_children():
		child.queue_free()