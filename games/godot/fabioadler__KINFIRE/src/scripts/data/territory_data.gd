class_name TerritoryData
extends Resource
## Território racial (MECANICAS #3, tarefa 2.4; LORE #X): capital, líder,
## economia e cultura viva. Fica em res://data/territories/<race_id>.tres.
## A posição da capital é procedural (Voronoi pela semente) - ver Territories.

@export var race_id: StringName = &""
## Nome da capital (LORE #X): "Porto Franco", "Raiz-Mãe"...
@export var capital_name: String = ""
@export var leader_name: String = ""
## Papel do líder para o hover/apresentação: "Guildmaster", "Thane"...
@export var leader_role: String = ""
@export var economy: String = ""
@export_multiline var culture: String = ""
## Bioma preferido da capital (a semente tenta respeitar; não é garantia)
@export var preferred_biome: String = "planicie"
## Modificador de nível do território (REGRAS #11: distância + modificador)
@export var level_modifier := 0
## Fala única do Cinzento ao acender a Fogueira Principal (LORE #X)
@export_multiline var cinzento_line: String = ""
