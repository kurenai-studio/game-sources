class_name MCTSAction
extends RefCounted

## Represents a single action the AI can take in Koi-Koi

enum ActionType {
	HAND_CAPTURE, # Play hand card to capture from field
	PLAY_TO_FIELD, # Play hand card to field (no capture)
	DECK_CAPTURE, # Capture with deck card
	DECK_TO_FIELD, # Deck card goes to field (auto)
	KOI_KOI_YES, # Continue playing after scoring
	KOI_KOI_NO # End round after scoring
}

var action_type: ActionType
var hand_card: Card # Card from hand (if applicable)
var field_card: Card # Card from field to capture (if applicable)

func _init(type: ActionType, h_card: Card = null, f_card: Card = null) -> void:
	action_type = type
	hand_card = h_card
	field_card = f_card


func get_description() -> String:
	match action_type:
		ActionType.HAND_CAPTURE:
			return "HAND_CAPTURE: %d-%d captures %d-%d" % [hand_card.month, hand_card.number, field_card.month, field_card.number]
		ActionType.PLAY_TO_FIELD:
			return "PLAY_TO_FIELD: %d-%d" % [hand_card.month, hand_card.number]
		ActionType.DECK_CAPTURE:
			return "DECK_CAPTURE: field card %d-%d" % [field_card.month, field_card.number]
		ActionType.DECK_TO_FIELD:
			return "DECK_TO_FIELD (auto)"
		ActionType.KOI_KOI_YES:
			return "KOI_KOI: YES"
		ActionType.KOI_KOI_NO:
			return "KOI_KOI: NO"
	return "UNKNOWN"
