extends Area2D

var inRadius := false
@onready var interactionPopUp : CanvasLayer = get_parent().get_parent().get_node("InteractionPopup")
@onready var interactTextPopUp : RichTextLabel = interactionPopUp.get_node("InteractText")
@onready var textPopUp : RichTextLabel = interactionPopUp.get_node("TextPopUp")
var text := "null"

func _ready() -> void:
	text = get_parent().get_meta("text")

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_E) and inRadius:
		textPopUp.text = text
		textPopUp.show()

func _on_player_enter(body: Node2D) -> void:
	if body.name != "Player":
		return
	interactTextPopUp.show()
	inRadius = true

func _on_player_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	interactTextPopUp.hide()
	textPopUp.hide()
	inRadius = false
