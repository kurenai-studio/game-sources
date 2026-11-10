class_name SkillNodeData
extends Resource
## Nó individual da árvore de habilidades.
## Pode destravar uma nova skill OU melhorar uma skill existente (ranks).

@export var id: StringName
@export var skill_id: StringName        # ID da skill alvo (nova ou existente)
@export var is_new_skill: bool = false  # true = destrava nova skill, false = melhora existente
@export var max_rank: int = 3           # rank máximo do nó (1-5 típico)
@export var requires: Array[StringName] = []  # IDs dos nós pré-requisito
@export var per_rank: Dictionary[String, float] = {}   # {"damage": 0.15, "cooldown": -0.07, "projectile_count": 1, "duration": 0.2, ...}
@export var display_name: String = ""   # Nome mostrado na UI
@export var description: String = ""    # Descrição mostrada no tooltip
@export var icon: String = "S_Sword01"  # Icone do nó


## Verifica se o nó está disponível para compra (pré-requisitos atendidos)
func is_available(unlocked: Array[StringName]) -> bool:
	for req in requires:
		if req not in unlocked:
			return false
	return true


## Retorna o multiplicador/bônus acumulado para um rank específico
func get_bonus_at_rank(rank: int) -> Dictionary:
	var bonus: Dictionary = {}
	for key in per_rank:
		bonus[key] = per_rank[key] * rank
	return bonus


## Retorna descrição formatada do efeito no rank atual
func get_effect_description(rank: int) -> String:
	if per_rank.is_empty():
		return ""
	var parts: Array = []
	for key in per_rank:
		var val := per_rank[key] * rank
		match key:
			"damage":
				parts.append("+{0}% dano".format(roundi(val * 100)))
			"cooldown":
				parts.append("{0}% cooldown".format(roundi(val * 100)))
			"projectile_count":
				parts.append("+{0} projéteis".format(roundi(val)))
			"duration":
				parts.append("+{0:.1f}s duração".format(val))
			"heal":
				parts.append("+{0}% cura".format(roundi(val * 100)))
			"radius":
				parts.append("+{0}% raio".format(roundi(val * 100)))
			"reach":
				parts.append("+{0}% alcance".format(roundi(val * 100)))
			"resource_gain":
				parts.append("+{0} recurso".format(roundi(val)))
			_:
				parts.append("{0}: +{1}".format(key, str(val)))
	return ", ".join(parts)