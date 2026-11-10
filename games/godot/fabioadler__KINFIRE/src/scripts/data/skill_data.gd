class_name SkillData
extends Resource
## Habilidade ativa. A lógica de execução fica em scripts/combat/skill_executor.gd

enum Kind {
	MELEE_ARC,      ## Golpe em cone na frente do herói
	PROJECTILE,     ## Projétil(eis) em direção ao mouse
	AOE_SELF,       ## Explosão/aura ao redor do herói
	AOE_TARGET,     ## Area no ponto do mouse (após atraso)
	DASH,           ## Avanço causando dano no caminho (ou teleporte se dano = 0)
	HEAL,           ## Cura
	BUFF,           ## Bônus temporário
	SUMMON_RAIN,    ## Vários impactos aleatórios em área
	BEAM,           ## Raio instantâneo que perfura tudo em linha
	CHAIN,          ## Raio que salta entre inimigos
	SUMMON,         ## Invoca aliados (esqueletos, lobo...)
	LEAP,           ## Salto que causa dano na aterrissagem
	SHAPESHIFT,     ## Transformação (muda o sprite e dá bônus)
	SLOW_ZONE,      ## Zona que desacelera inimigos e projéteis
	CONE,           ## Sopro em cone
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var kind: Kind = Kind.MELEE_ARC
## Nome do ícone em assets/icons (sem .png)
@export var icon: String = "S_Sword01"
@export var color: Color = Color.WHITE
## physical, fire, ice, lightning, poison, holy, shadow, arcane
@export var element: String = "physical"
@export var unlock_level: int = 1

@export_group("Dano e custo")
## Multiplicador sobre o dano da arma
@export var damage_mult: float = 1.0
@export var cost: float = 0.0
## Recurso gerado ao acertar
@export var generate: float = 0.0
@export var cooldown: float = 0.0

@export_group("Forma")
@export var reach: float = 40.0
@export var radius: float = 30.0
@export var arc_degrees: float = 100.0
@export var projectile_count: int = 1
@export var spread_degrees: float = 0.0
@export var projectile_speed: float = 300.0
## Sprite do projétil (nome no tile_list 0x72) ou "" para orbe brilhante
@export var projectile_sprite: String = ""
@export var pierce: int = 0
@export var explode_radius: float = 0.0
@export var hits: int = 1
@export var delay: float = 0.0

@export_group("Efeitos")
@export var knockback: float = 60.0
@export var stun: float = 0.0
## Lentidão aplicada (0.5 = 50% mais lento) por "duration"
@export var slow: float = 0.0
## Confusão: inimigos atacam uns aos outros
@export var confuse: float = 0.0
## Medo: inimigos fogem
@export var fear: float = 0.0
## Maldição: inimigos marcados explodem ao morrer
@export var curse: bool = false
@export var heal_percent: float = 0.0
## Buff: "damage", "armor", "speed", "attack_speed", "crit", "lifesteal"
@export var buff_stat: String = ""
@export var buff_amount: float = 0.0
@export var duration: float = 0.0

@export_group("Invocação / Transformação")
## Sprite do aliado invocado ou da forma (nome-base 0x72)
@export var summon_sprite: String = ""
@export var summon_count: int = 0
@export var summon_max: int = 0
@export var summon_hp_mult: float = 0.5
## Segundo bônus da transformação
@export var buff_stat_2: String = ""
@export var buff_amount_2: float = 0.0

@export var sound: StringName = &"swing1"
