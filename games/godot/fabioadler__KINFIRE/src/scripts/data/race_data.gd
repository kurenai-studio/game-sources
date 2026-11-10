class_name RaceData
extends Resource
## Raça jogável (biologia e passivas). Fica em res://data/races/*.tres

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Aparência")
## Nome-base do sprite animado (0x72): "knight", "elf", "dwarf"...
@export var sprite_m: String = "knight_m"
@export var sprite_f: String = "knight_f"
@export var tint: Color = Color.WHITE
@export var body_scale: float = 1.0

@export_group("Atributos")
## Bônus de atributos: {"str": 2, "con": 1, "dex": -1}
@export var ability_bonus: Dictionary = {}
## Quantos +1 extras o jogador escolhe na criação (Meio-Elfo)
@export var free_bonus_choices: int = 0

@export_group("Status base")
@export var move_speed_mult: float = 1.0
@export var bonus_hp: int = 0
@export var armor_mult: float = 1.0
@export var resource_max_mult: float = 1.0
@export var resource_regen_mult: float = 1.0
@export var cooldown_reduction: float = 0.0

@export_group("Resistências (0.25 = 25%)")
@export var physical_resist: float = 0.0
@export var magic_resist: float = 0.0
@export var fire_resist: float = 0.0
@export var ice_resist: float = 0.0
@export var poison_resist: float = 0.0
@export var knockback_immune: bool = false

@export_group("Passiva única")
@export var trait_name: String = ""
@export_multiline var trait_description: String = ""
@export var xp_bonus: float = 0.0
@export var gold_find: float = 0.0
@export var crit_chance_bonus: float = 0.0
## Chance de um crítico causar dano dobrado (Halfling)
@export var double_crit_chance: float = 0.0
## Esquiva automática do primeiro golpe a cada N segundos (0 = desativado)
@export var auto_dodge_interval: float = 0.0
## Dano extra contra inimigos atordoados/congelados/confusos (Drow)
@export var cc_damage_bonus: float = 0.0
## Multiplicador da regeneração de vida fora de combate (Anão das Colinas)
@export var ooc_regen_mult: float = 1.0
## Evita a morte uma vez a cada N segundos (Meio-Orc). 0 = desativado
@export var cheat_death_cooldown: float = 0.0
## Devolve parte do dano físico recebido como fogo (Tiefling)
@export var thorns: float = 0.0
## Sopro elemental ativo (Draconato): "" ou "fire", "ice", "lightning"
@export var breath_element: String = ""
## Golpes consecutivos para ativar Arrancada Feroz (Tabaxi). 0 = desativado
@export var frenzy_hits: int = 0
## Colunas extras no inventário (Golias)
@export var extra_inventory_cols: int = 0
## Velocidade extra com armas de duas mãos (Golias)
@export var two_hand_speed: float = 0.0
## Pode equipar itens N níveis acima do seu (Meio-Elfo)
@export var item_level_leeway: int = 0
