extends Resource
class_name RankData

@export var rank_letter: String = "F"
@export var nivel_minimo: int = 1
@export var titulo: String = ""
@export var requisitos_conquistas: Dictionary = {}
@export var beneficios: Dictionary = {}

func _init(p_letter: String = "F", p_titulo: String = "") -> void:
	rank_letter = p_letter
	titulo = p_titulo
