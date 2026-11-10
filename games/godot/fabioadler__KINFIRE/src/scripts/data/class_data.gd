class_name ClassData
extends Resource
## Classe jogável (treinamento, recurso e habilidades). Fica em res://data/classes/*.tres

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var role: String = ""
## Icone da classe (nome do arquivo em assets/icons, sem .png)
@export var icon: String = "S_Sword01"

@export_group("Vida e atributos")
## Dado de vida (d6, d8, d10, d12): define quanto de vida ganha por nível
@export var hit_die: int = 8
@export var base_hp: int = 40
## Atributo primário: "str", "dex", "con", "int", "wis", "cha"
@export var primary_ability: String = "str"
## Ordem de prioridade para o point-buy recomendado
@export var recommended: PackedStringArray = PackedStringArray()
@export var base_armor: int = 5
## Status base da classe (pontos fixos que sobem com o nível, não podem ser respeitados)
## Chaves: "forca", "agilidade", "mente", "vitalidade"
@export var base_status: Dictionary = {"forca": 10, "agilidade": 10, "mente": 10, "vitalidade": 10}
## Crescimento automático de status por nível (aplicado a base_status)
@export var status_growth: Dictionary = {"forca": 0, "agilidade": 0, "mente": 0, "vitalidade": 0}

@export_group("Recurso")
@export var resource_label: String = "Fúria"
@export var resource_color: Color = Color(0.9, 0.5, 0.1)
@export var resource_max: float = 100.0
## Regeneração passiva por segundo
@export var resource_regen: float = 0.0
## Começa vazio e decai fora de combate (Fúria)
@export var resource_decays: bool = false
## Recurso ganho ao receber dano (Bárbaro)
@export var gain_on_hurt: float = 0.0
## Recurso ganho quando um inimigo morre por perto (Necromante)
@export var gain_on_kill: float = 0.0
## Regeneração multiplicada após 2s sem gastar (Ladino)
@export var burst_regen_after_idle: float = 0.0
## Regeneração só enquanto parado (Caçador)
@export var regen_only_still: bool = false
## Habilidades custam vida em vez de recurso (Bruxo): custo vira % da vida máxima x 0,25
@export var costs_life: bool = false

@export_group("Mecânicas de classe")
## Fração do dano causado convertida em vida
@export var lifesteal: float = 0.0
## A cada N acertos do ataque básico, o golpe causa dano dobrado e atordoa (Monge)
@export var combo_every: int = 0
## Ataques corpo a corpo reduzem recarga das magias em X segundos (Lâmina Arcana)
@export var melee_cdr_on_hit: float = 0.0
## Usar magias encanta a arma: +dano no ataque básico (Lâmina Arcana)
@export var spell_imbue_bonus: float = 0.0
## Chance de bloquear golpes (escudos)
@export var block_chance: float = 0.0
## Recurso ganho ao bloquear (Paladino)
@export var gain_on_block: float = 0.0

@export_group("Equipamento")
## Categorias permitidas: sword, axe, mace, dagger, spear, staff, bow, fist, wand
@export var allowed_weapons: PackedStringArray = PackedStringArray()
## Mão secundária permitida: shield, book, quiver, orb
@export var allowed_offhands: PackedStringArray = PackedStringArray()
@export var starting_weapon: StringName = &"sword"
@export var starting_offhand: StringName = &""
@export var skills: Array[SkillData] = []
