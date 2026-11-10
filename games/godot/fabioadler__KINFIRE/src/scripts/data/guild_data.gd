extends Resource
class_name GuildData

enum Type { AVENTUREIROS, MERCADORES, ARTESAOS, SOMBRAS }

@export var id: StringName
@export var display_name: String
@export var tipo: Type
@export var mestre_npc: StringName
@export var descricao: String = ""
@export var requisito_nivel: int = 1
@export var requisito_ouro: int = 0
@export var requisito_reputacao: int = -1
@export var beneficios: Dictionary = {}
@export var rank_reqs: Dictionary = {}

func _init(p_id: StringName = &"", p_name: String = "", p_tipo: Type = Type.AVENTUREIROS, p_mestre: StringName = &"") -> void:
	id = p_id
	display_name = p_name
	tipo = p_tipo
	mestre_npc = p_mestre
