extends Resource
class_name ContractData

enum Type { CACA, COLETA, EXPLORACAO, ESCOLTA }

@export var id: StringName
@export var tipo: Type
@export var regiao: StringName
@export var descricao_template: String = ""
@export var requisitos: Dictionary = {}
@export var recompensas: Dictionary = {}
@export var tempo_limite_horas: float = 2.0
@export var dificuldade: String = "F"
@export var risco: float = 1.0

func _init(p_id: StringName = &"") -> void:
	id = p_id
