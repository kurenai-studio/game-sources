class_name Cinzento
extends Node2D
## O Silhueta - Ithariel, o Cinzento (LORE #8).
## Ultimo Guardião da Kinfire: sombra consciente que guia o Laço-Vivo.
## Nunca diz "eu"; indica, não explica. Sua voz não tem eco - o Véu come o som.

const VOICE := Color(0.68, 0.64, 0.82)  ## pálido, cor de névoa à luz de brasa
const HOVER_RADIUS := 14.0

## Interatividade opt-in (duck-typed interactable, como Npc): o prólogo usa
## o Cinzento em cutscenes (não clicável); no acampamento ele permanece e
## pode ser reencontrado - quem fechar o diálogo de despertar antes da
## despedida não perde o rumo, e o estágio "volte ao Cinzento" de ato1_1
## tem com quem conversar (fix da missão inicial).
var world: World
var interactive := false

var _sprite: AnimatedSprite2D
var _light: PointLight2D
var _t := 0.0
var _hover := false


func _ready() -> void:
	z_index = 5
	if interactive:
		add_to_group("interactables")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = DB.frames("k:121")
	_sprite.play("idle")
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)
	_light = Fx.make_light(Color(0.5, 0.48, 0.68), 0.9, 1.0)
	_light.position = Vector2(0, -8)
	add_child(_light)


func _process(delta: float) -> void:
	_t += delta
	# Flutua; tremula como chama exposta ao vento
	_sprite.position.y = -8.0 + sin(_t * 2.1) * 2.5
	_sprite.modulate.a = 0.7 + sin(_t * 3.1) * 0.12 + sin(_t * 9.7) * 0.05
	# Hover: a brasa acende um pouco mais - "ele sabe que você olha"
	_light.energy = 0.75 + sin(_t * 5.3) * 0.15 + sin(_t * 13.7) * 0.08 + (0.35 if _hover else 0.0)


## Aparece suavemente em uma posição (o Véu não deixa ele "estar" - só chegar)
func appear_at(pos: Vector2) -> void:
	global_position = pos
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# ------------------------------------------------------------------ INTERACAO (duck-typed, opt-in)

func hover_check(mouse: Vector2) -> bool:
	_hover = interactive and (global_position + Vector2(0, -8)).distance_to(mouse) < HOVER_RADIUS
	return _hover


func display_name() -> String:
	return "Cinzento"


func interact(player: Player) -> void:
	if not interactive:
		return
	# Encara quem chega
	_sprite.flip_h = player.global_position.x < global_position.x
	Sfx.play(&"ui_open", -8.0)
	var d := DB.dialogue(&"cinzento_acampamento")
	if d == null:
		return
	world.hud.open_dialogue(d, "Cinzento")
