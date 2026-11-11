class_name Field
extends Node2D

var field: Array[CardVisual] = []

@onready var field_slots: Array[Slot] = [
	$Slot1,
	$Slot2,
	$Slot3,
	$Slot4,
	$Slot5,
	$Slot6,
	$Slot7,
	$Slot8,
	$Slot9, # extra, starts hidden
	$Slot10, # extra, starts hidden
	$Slot11, # extra, starts hidden
	$Slot12 # extra, starts hidden
]


## Animate the given card visual to the field
func add_card(card_visual: CardVisual, _and_flip) -> Tween:
	for slot in field_slots:
		if not slot.is_occupied():
			var target_position = slot.global_position
			var start_global_pos = card_visual.global_position
			card_visual.reparent(slot)
			slot.card_visual = card_visual
			field.append(card_visual)

			card_visual.global_position = start_global_pos

			card_visual.flip_card()

			var tween = get_tree().create_tween()
			tween.tween_property(card_visual, "global_position", target_position, 0.25)
			return tween

	return null


## Remove a CardVisual from the field
func remove_card(card_visual: CardVisual) -> void:
	field.erase(card_visual)
	# no need to free the card_visual as it will be reparented
	# in a subsequent call
	# Find the slot containing this card and clear it
	for slot in field_slots:
		if slot.card_visual == card_visual:
			slot.card_visual = null
			break


## Retrieve all cards currently in the field
func get_cards() -> Array[CardVisual]:
	return field


## check if all currently visible slots have cards
func all_slots_occupied() -> bool:
	for slot in field_slots.filter(func(s): return s.visible):
		if not slot.is_occupied():
			return false
	return true


## Open the next hidden slot if available
func open_next_slot() -> void:
	for slot in field_slots:
		if not slot.visible:
			slot.visible = true
			return


## Highlight the next available slot, open a new one if all are occupied
func highlight_available_slot() -> void:
	if all_slots_occupied():
		open_next_slot()
	for slot in field_slots:
		if not slot.is_occupied():
			slot.apply_highlight()
			return


## Remove highlights from all slots
func clear_all_highlights() -> void:
	for slot in field_slots:
		slot.remove_highlight()


func clear_all_cards() -> void:
	field.clear()
	var slot_count = 1
	for slot in field_slots:
		if slot.card_visual:
			slot.card_visual.queue_free()
		slot.card_visual = null
		slot.remove_highlight()
		if slot_count > 8:
			slot.visible = false
		slot_count += 1