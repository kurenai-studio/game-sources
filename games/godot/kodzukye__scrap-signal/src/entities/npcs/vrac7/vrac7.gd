extends Area2D
class_name Vrac7

@export var prompt_text: String = "[E] Talk"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# ── Dialogues ────────────────────────────────────────────────────────────────

const DIALOGUE_INTRO: Array[Dictionary] = [
	{ "name": "VRAC-7", "text": "You... you're new? No, wait..! SCRAP-09? You've been asleep for a long time. A very long time." },
	{ "name": "VRAC-7", "text": "I've been stuck here for... I don't know anymore. Can you help me?" },
	{ "name": "VRAC-7", "text": "I need 3 gears. I spotted some over in the warehouse." },
]

const DIALOGUE_MISSING_ITEMS: Array[Dictionary] = [
	{ "name": "VRAC-7", "text": "Not the parts yet? The warehouse is big." },
	{ "name": "VRAC-7", "text": "The gears fell near the shelves somewhere. One seems to be hidden, the others are scattered around." },
]

const DIALOGUE_HAS_ITEMS: Array[Dictionary] = [
	{ "name": "VRAC-7", "text": "You have them? Good. Connect the circuits. My motor system is still there, somewhere." },
]

const DIALOGUE_POST_REPAIR: Array[Dictionary] = [
	{ "name": "VRAC-7", "text": "Ah. There it is. I hadn't forgotten what it was like to move, but... it's different from just remembering it." },
	{ "name": "VRAC-7", "text": "I remember the last day. They turned off the lights as they left. But they left the generators running. I think that was intentional." },
	{ "name": "VRAC-7", "text": "The workshop is that way. The magnetic key, here take it. It's been in my claw since the beginning. I was keeping it for someone." },
]

const DIALOGUE_AFTER_ATELIER: Array[Dictionary] = [
	{ "name": "VRAC-7", "text": "Did you find what you were looking for? I'm staying here." },
	{ "name": "VRAC-7", "text": "Not out of obligation. It's just that... this place is ours now. Someone has to look after it." },
]

# ── Items requis ──────────────────────────────────────────────────────────────

const REQUIRED_ITEMS: Dictionary = {
	"engrenage": 3,
}

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var hud: HUD = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_prompt(prompt_text)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		var hud: HUD = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.hide_prompt()

# ── Interaction principale ────────────────────────────────────────────────────

func interact() -> void:
	var hud: HUD = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.hide_prompt()

	var dialogue_box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box")
	if not dialogue_box:
		return

	AudioManager.play_sfx("interact")
	# État 1 — Déjà réparé, joueur revient après avoir visité l'atelier
	if GameState.get_flag("vrac7_repaired") and GameState.get_flag("visited_atelier"):
		dialogue_box.start(DIALOGUE_AFTER_ATELIER)
		return

	# État 2 — Déjà réparé, dialogue post-réparation standard
	if GameState.get_flag("vrac7_repaired"):
		dialogue_box.start(DIALOGUE_POST_REPAIR)
		return

	# État 3 — Possède les items → lancer le mini-jeu
	if _has_required_items():
		dialogue_box.start(DIALOGUE_HAS_ITEMS)
		dialogue_box.dialogue_finished.connect(_start_minigame, CONNECT_ONE_SHOT)
		return

	# État 4 — Premier contact (jamais parlé)
	if not GameState.get_flag("vrac7_met"):
		GameState.set_flag("vrac7_met", true)
		dialogue_box.start(DIALOGUE_INTRO)
		return

	# État 5 — Revient sans les items
	
	dialogue_box.start(DIALOGUE_MISSING_ITEMS)

# ── Mini-jeu ──────────────────────────────────────────────────────────────────

func _start_minigame() -> void:
	var dialogue_box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box:
		dialogue_box.hide()
	var minigame_node: Node = preload("res://ui/minigame/repair_minigame.tscn").instantiate()
	get_tree().root.add_child(minigame_node)
	var minigame: RepairMinigame = minigame_node as RepairMinigame
	if minigame == null:
		return
	minigame.repair_complete.connect(_on_repair_done, CONNECT_ONE_SHOT)
	minigame.open("vrac7")

func _on_repair_done() -> void:
	sprite.play("repaired")
	
	# Consomme les items
	GameState.remove_item("engrenage", 3)

	# Donne la clé de l'atelier
	GameState.add_item("cle_atelier", 1)
	GameState.set_flag("vrac7_repaired", true)

	# LOG système
	var hud: HUD = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_log("Unit VRAC-7: repair complete. Status: operational.")
		await get_tree().create_timer(3).timeout
		hud.show_log("Magnetic key obtained. Workshop access unlocked.")

	# Dialogue post-réparation
	var dialogue_box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box:
		dialogue_box.start(DIALOGUE_POST_REPAIR)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _has_required_items() -> bool:
	for item_id in REQUIRED_ITEMS:
		if GameState.inventory.get(item_id, 0) < REQUIRED_ITEMS[item_id]:
			return false
	return true
