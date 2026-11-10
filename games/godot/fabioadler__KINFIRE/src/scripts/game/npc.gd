class_name Npc
extends Node2D
## NPC conversável (tarefa 2.3, MECANICAS #7): gente viva no mundo -
## respira, cumprimenta e conversa via DialogueData ramificado.
## Diálogos mudam com ignorância/reputação/flags (ConditionResolver);
## efeitos aplicam rep/ignorância/flags no save (DialogueEngine).
## Duck-typed como interactable: hover_check()/display_name()/interact().

const HOVER_RADIUS := 12.0

var data: NpcData
var world: World

var _sprite: AnimatedSprite2D
var _light: PointLight2D
var _t := 0.0
var _hover := false
var _phase := 0.0


static func create(w: World, p_data: NpcData, pos: Vector2) -> Npc:
	var n := Npc.new()
	n.world = w
	n.data = p_data
	n.position = pos
	w.entities.add_child(n)
	return n


func _ready() -> void:
	z_index = 5
	add_to_group("interactables")
	add_to_group("npcs")
	_phase = randf() * TAU  # des-sincroniza a respiração entre NPCs
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = DB.frames(_sprite_base())
	_sprite.play("idle")
	_sprite.position = Vector2(0, -8)
	var race := _race()
	if race:
		_sprite.modulate = race.tint
		if race.body_scale != 1.0:
			_sprite.scale = Vector2(race.body_scale, race.body_scale)
	add_child(_sprite)
	# Brasa fraca: uma vida no meio do Véu
	_light = Fx.make_light(Color(1.0, 0.78, 0.5), 0.45, 0.8)
	_light.position = Vector2(0, -10)
	add_child(_light)


func _process(_delta: float) -> void:
	_t += _delta
	# Respiração sutil - ninguém fica parado como estátua
	_sprite.position.y = -8.0 + sin(_t * 1.8 + _phase) * 0.7
	_light.energy = 0.4 + sin(_t * 2.4 + _phase) * 0.07
	_sprite.modulate = _tint() * Color(1.4, 1.3, 1.1) if _hover else _tint()


# ------------------------------------------------------------------ INTERACAO (duck-typed)

func hover_check(mouse: Vector2) -> bool:
	_hover = (global_position + Vector2(0, -8)).distance_to(mouse) < HOVER_RADIUS
	return _hover


func display_name() -> String:
	if data == null:
		return "???"
	if data.role == "":
		return data.display_name
	return "%s — %s" % [data.display_name, data.role]


func interact(player: Player) -> void:
	# Encara quem chega
	_sprite.flip_h = player.global_position.x < global_position.x
	Sfx.play(&"ui_open", -8.0)
	var d := DB.dialogue(data.dialogue_id)
	if d == null:
		world.hud.show_message("%s não tem nada a dizer agora." % data.display_name, UIKit.TEXT_DIM)
		return
	world.hud.open_dialogue(d, data.display_name)


# ------------------------------------------------------------------ APARENCIA

func _race() -> RaceData:
	if data == null or data.shadow:
		return null
	return DB.get_race(data.race_id)


func _tint() -> Color:
	var r := _race()
	return r.tint if r else Color.WHITE


func _sprite_base() -> String:
	if data == null or data.shadow:
		return "k:121"
	var r := _race()
	if r == null:
		return "knight_m"
	return r.sprite_f if data.sex == "f" else r.sprite_m
