class_name PassageTrigger
extends Area2D

# Les layers à rendre visibles quand le trigger s'active
@export var layer_sol : TileMapLayer
@export var layer_murs : TileMapLayer
@export var layer_murs_derriere : TileMapLayer
@export var hidden_door : Door
@export var hidden_object : Circuit

# Le layer qui cache le passage — à désactiver
@export var layer_cache : TileMapLayer

var _triggered: bool = false

func _ready() -> void:
	# Au départ, sol et murs sont cachés
	if layer_sol:
		layer_sol.enabled = false
	if layer_murs:
		layer_murs.enabled = false
	if layer_murs_derriere:
		layer_murs.enabled = false
	if hidden_door:
		hidden_door.visible = false
	if hidden_object:
		hidden_object.visible = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	_reveal_passage()

func _reveal_passage() -> void:
	if layer_sol:
		layer_sol.enabled = true
	if layer_murs:
		layer_murs.enabled = true
	if layer_murs_derriere:
		layer_murs.enabled = true
	if hidden_door:
		hidden_door.visible = true
	if hidden_object:
		hidden_object.visible = true
	if layer_cache:
		layer_cache.enabled = false
