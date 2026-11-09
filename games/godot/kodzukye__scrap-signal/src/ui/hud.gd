class_name HUD
extends CanvasLayer

var _log_tween : Tween

@onready var slots: Dictionary = {
	"engrenage": $InventoryBar/ItemRow/EngrenageSlot/Count,
	"circuit":   $InventoryBar/ItemRow/CircuitSlot/Count,
}
@onready var interact_prompt: Control = $InteractPrompt
@onready var prompt_label: Label = $InteractPrompt/PromptLabel

@onready var log_container: Control = $LogContainer
@onready var log_label: RichTextLabel = $LogContainer/LogLabel

func _ready() -> void:
	GameState.inventory_changed.connect(_refresh)
	_refresh()

func show_prompt(text: String) -> void:
	prompt_label.text = text
	interact_prompt.visible = true

func hide_prompt() -> void:
	interact_prompt.visible = false
		
func show_log(message: String) -> void:
	log_label.text = "> " + message
	log_container.modulate.a = 1.0
	log_container.show()

	# Annule le tween précédent si un log était encore visible
	if _log_tween:
		_log_tween.kill()

	# Disparaît après 3 secondes avec un fade out
	_log_tween = create_tween()
	_log_tween.tween_interval(3.5)
	_log_tween.tween_property(log_container, "modulate:a", 0.0, 0.5)
	_log_tween.tween_callback(log_container.hide)

func _refresh() -> void:
	for item_id in slots:
		var count : int = GameState.inventory.get(item_id, 0)
		slots[item_id].text = "x%d" % count
		slots[item_id].get_parent().modulate.a = 0.4 if count == 0 else 1.0
