extends AnimatableBody2D

var pieces := 0
var inRadius := false
@onready var rootNode := get_parent()
@onready var interactionPopUp : CanvasLayer = rootNode.get_node("InteractionPopup")
@onready var interactTextPopUp : RichTextLabel = interactionPopUp.get_node("InteractText")
@onready var piecesText : RichTextLabel = interactionPopUp.get_node("PiecesLeft")
var meh := false

signal place
signal win

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if meh:
		return
	
	if pieces == 10:
		win.emit()
		meh = true
		interactionPopUp.visible = false
	
	if Input.is_key_pressed(KEY_E) and inRadius:
		place.emit()

func _on_player_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	interactTextPopUp.show()
	piecesText.show()
	inRadius = true

func _on_player_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	interactTextPopUp.hide()
	piecesText.hide()
	inRadius = false

func _on_player_return_pieces(piecesToFill: int) -> void:
	pieces += piecesToFill
	piecesText.text = "[center]Pieces Left: " + str(pieces) + "/10"
