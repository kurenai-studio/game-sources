class_name QuestRewards
extends Resource
## Recompensas ao concluir uma quest (Fase 4). REGRAS #12: quest principal dá
## XP = 40 x nível da quest x ato + ouro proporcional + 1 item
## (raridade mínima = ato: Mágico/Raro/Lendário). xp = 0 usa a fórmula.

@export var xp := 0
@export var gold := 0
@export var essence := 0
## Item de recompensa (base_id); vazio = nenhum
@export var item_base: StringName = &""
## Raridade do item (sobe ao mínimo do ato na concessão)
@export var item_rarity: int = Item.Rarity.MAGIC
## Ganho de reputação por raça: {race_id: delta}
@export var reputation: Dictionary = {}
## Cadeia de mistério: rende 1 Fragmento da Verdade (REGRAS #12)
@export var fragment := false
