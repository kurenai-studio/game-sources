class_name EnemyData
extends Resource
## Definição de monstro. Fica em res://data/enemies/*.tres

enum Behavior { MELEE, RANGED, CHARGER, SWARM, BOSS }
## Tipo elemental para resistências/vulnerabilidades (REGRAS #3):
## "undead" = fraco a holy (x1.5), "demon" = imune a shadow + fraco a holy
enum ElementalType { NONE, UNDEAD, DEMON }

@export var id: StringName
@export var display_name: String = ""
## Nome-base do sprite animado (0x72): "goblin", "skelet", "big_demon"...
@export var sprite: String = "goblin"
@export var behavior: Behavior = Behavior.MELEE
@export var max_hp: float = 30.0
@export var damage: float = 6.0
## physical, fire, ice, poison, shadow, arcane, holy
@export var element: String = "physical"
@export var elemental_type: ElementalType = ElementalType.NONE  ## REGRAS #3
@export var armor: float = 0.0
@export var move_speed: float = 55.0
@export var attack_range: float = 18.0
@export var attack_cooldown: float = 1.2
@export var aggro_range: float = 170.0
@export var xp: int = 10
@export var scale: float = 1.0
@export var min_depth: int = 1
@export var spawn_weight: float = 1.0
@export var projectile_color: Color = Color(0.6, 1.0, 0.4)
@export var tint: Color = Color.WHITE
## Para chefes: em qual profundidade aparece (a cada N níveis)
@export var boss_order: int = 0
## Onde aparece: "dungeon" e/ou biomas do mundo aberto
## (planicie, floresta, deserto, tundra, pantano, vulcanico, corrompido)
@export var habitats: PackedStringArray = PackedStringArray(["dungeon"])
## Chefe de mundo (aparece raramente em regiões distantes)
@export var world_boss: bool = false
## 3.3 - eixo por inimigo do LootTableData: base_id de um item único
## (lendário nomeado) garantido ao matar este inimigo; vazio = nenhum
@export var unique_drop: StringName = &""
