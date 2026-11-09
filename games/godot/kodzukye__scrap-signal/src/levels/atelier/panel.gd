class_name PanelJournal
extends Area2D

@export var prompt_text: String = "[E] Read"
@export var journal_id: String = "D-891"

const DIALOGUE: Array[Dictionary] = [
	{ "name": "JOURNAL D-891", "text": "Last day. I checked the generators... they'll hold for years." },
	{ "name": "JOURNAL D-891", "text": "I left the maintenance tanks full. I don't know if that's even allowed." },
	{ "name": "JOURNAL D-891", "text": "But it means something to me.  — Matteo Corda, Director" },
]


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func interact() -> void:
	var hud: HUD = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.hide_prompt()
	
	if journal_id != "":
		GameState.set_flag(journal_id + "_read", true)
	
	var dialogue_box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box")
	
	AudioManager.play_sfx("interact")
	if dialogue_box:
		dialogue_box.start(DIALOGUE)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var hud: HUD = get_tree().get_first_node_in_group("hud")
		if hud: hud.show_prompt(prompt_text)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		var hud: HUD = get_tree().get_first_node_in_group("hud")
		if hud: hud.hide_prompt()
