class_name Interactable
extends Node2D
## Objeto no mundo: baú, santuário, escadaria, espinhos, fogueira (viagem rápida),
## mercador, entrada e saída de masmorra.

enum Kind { CHEST, SHRINE, STAIRS, SPIKES, CAMPFIRE, MERCHANT, DUNGEON_ENTRANCE, DUNGEON_EXIT, MIRROR }

const SHRINES := [
	{"name": "Santuário do Poder", "stat": "damage", "amount": 0.5, "color": Color(1, 0.35, 0.2)},
	{"name": "Santuário da Proteção", "stat": "armor", "amount": 100.0, "color": Color(0.5, 0.7, 1.0)},
	{"name": "Santuário do Frenesi", "stat": "attack_speed", "amount": 0.4, "color": Color(1, 0.8, 0.2)},
	{"name": "Santuário da Rapidez", "stat": "speed", "amount": 0.4, "color": Color(0.4, 1, 0.5)},
	{"name": "Santuário da Fortuna", "stat": "crit", "amount": 0.15, "color": Color(1, 0.9, 0.4)},
]
const SPIKE_FRAMES := ["floor_spikes_anim_f0", "floor_spikes_anim_f1", "floor_spikes_anim_f2", "floor_spikes_anim_f3"]
const OW_SHEET := preload("res://assets/sprites/overworld/roguelike_sheet.png")

var kind: Kind = Kind.CHEST
var world: World
var used := false
var locked := false
var label := ""
var dungeon_level := 1
## Identificador salvo para não reaparecer (baús/santuários do mundo aberto)
var persist_id := ""
var _sprite: Sprite2D
var _anim: AnimatedSprite2D
var _light: PointLight2D
var _t := 0.0
var _hover := false
var _spike_hit := false
var _spiked: Dictionary = {}


static func create(w: World, p_kind: Kind, pos: Vector2) -> Interactable:
	var i := Interactable.new()
	i.world = w
	i.kind = p_kind
	i.position = pos
	if p_kind in [Kind.STAIRS, Kind.SPIKES, Kind.DUNGEON_EXIT]:
		w.decals.add_child(i)
	else:
		w.entities.add_child(i)
	return i


static func ow_texture(coords: Vector2i) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = OW_SHEET
	at.region = Rect2(coords.x * 17, coords.y * 17, 16, 16)
	return at


func _ready() -> void:
	if kind != Kind.SPIKES:
		add_to_group("interactables")
	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)
	_t = randf() * 3.0
	match kind:
		Kind.CHEST:
			_sprite.texture = DB.dt2_texture("chest_full_open_anim_f0")
			_sprite.position = Vector2(0, -6)
		Kind.SHRINE:
			_sprite.texture = DB.tile(8)
			_light = Fx.make_light(Color(0.3, 1, 0.6), 1.0, 0.9)
		Kind.STAIRS:
			_sprite.texture = DB.dt2_texture("floor_stairs")
			_sprite.position = Vector2.ZERO
			_light = Fx.make_light(Color(0.7, 0.4, 1.0), 1.4, 1.2)
		Kind.SPIKES:
			_sprite.texture = DB.dt2_texture(SPIKE_FRAMES[0])
			_sprite.position = Vector2.ZERO
		Kind.CAMPFIRE:
			_sprite.texture = ow_texture(Vector2i(14, 8))
			# 7.2: fogueira oscila viva e projeta sombras reais (#14.2)
			_light = Fx.make_light(Color(1, 0.6, 0.25), 2.2, 1.3, LightFx.Flicker.FIRE, true)
			# 7.4: a chama curva-se com o vento (#14.5.2) - uniformes no _process
			var sway := ShaderMaterial.new()
			sway.shader = preload("res://shaders/wind_sway.gdshader")
			sway.set_shader_parameter("flexibility", 0.5)
			_sprite.material = sway
		Kind.MERCHANT:
			_sprite.visible = false
			_anim = AnimatedSprite2D.new()
			_anim.sprite_frames = DB.frames("dwarf_f")
			_anim.position = Vector2(0, -14)
			_anim.modulate = Color(1.0, 0.9, 0.75)
			_anim.play("idle")
			add_child(_anim)
			var stall := Sprite2D.new()
			stall.texture = ow_texture(Vector2i(10, 1))
			stall.position = Vector2(16, -8)
			add_child(stall)
			_light = Fx.make_light(Color(1, 0.85, 0.5), 1.2, 0.6)
		Kind.DUNGEON_ENTRANCE:
			_sprite.texture = DB.dt2_texture("doors_leaf_open")
			_sprite.position = Vector2(0, -14)
			_light = Fx.make_light(Color(0.6, 0.3, 1.0), 1.6, 1.1)
		Kind.DUNGEON_EXIT:
			_sprite.texture = DB.dt2_texture("floor_ladder")
			_sprite.position = Vector2.ZERO
			_light = Fx.make_light(Color(0.5, 0.9, 1.0), 1.4, 1.2)
		Kind.MIRROR:
			# Vazio escuro sem reflexo (o Véu roubou o reflexo - LORE #9)
			_sprite.texture = DB.dt2_texture("hole")
			_sprite.scale = Vector2(1.25, 1.5)
			_sprite.position = Vector2(0, -10)
			_light = Fx.make_light(Color(0.55, 0.52, 0.72), 1.1, 0.8)
	if _light:
		_light.position = Vector2(0, -6)
		add_child(_light)


func hover_check(mouse: Vector2) -> bool:
	if not can_interact(null):
		return false
	var r := 14.0 if kind in [Kind.DUNGEON_ENTRANCE, Kind.MERCHANT] else 10.0
	_hover = (global_position + Vector2(0, -8)).distance_to(mouse) < r
	return _hover


## O objeto pode ser interagido no estado atual do mundo?
func can_interact(_p: Player = null) -> bool:
	if used and kind in [Kind.CHEST, Kind.SHRINE]:
		return false
	if kind == Kind.MIRROR:
		var pro := world as Prologue
		if pro != null and pro.tut_step != Prologue.TutStep.DONE:
			return false
	return true


func display_name() -> String:
	match kind:
		Kind.CHEST: return "Baú"
		Kind.SHRINE: return "Santuário"
		Kind.STAIRS: return "Descer para o andar %d" % (Game.depth + 1)
		Kind.CAMPFIRE: return "%s (viagem rápida)" % label
		Kind.MERCHANT: return "Mercador Bartolomeu"
		Kind.DUNGEON_ENTRANCE: return "%s - Nível %d" % [label, dungeon_level]
		Kind.DUNGEON_EXIT: return "Voltar ao mundo aberto"
		Kind.MIRROR: return "Espelho Antigo"
	return ""


func interact(player: Player) -> void:
	match kind:
		Kind.CHEST:
			if used:
				return
			used = true
			_persist()
			Sfx.play(&"door", -4.0)
			if world.level() >= 2 and randf() < 0.12:
				world.hud.show_message("E um Mímico!", Color(1, 0.3, 0.2))
				world.spawn_enemy(DB.get_enemy(&"mimico"), global_position, Enemy.Rarity.COMUM)
				queue_free()
				return
			_animate_chest()
			for i in randi_range(1, 2):
				LootDrop.drop_item(world, global_position, world.roll_loot_item(0.15))
			LootDrop.drop_gold(world, global_position, world.gold_amount() * 2)
		Kind.SHRINE:
			if used:
				return
			used = true
			_persist()
			var s: Dictionary = SHRINES.pick_random()
			player.add_buff(s.stat, s.amount, 30.0, s.name, s.color)
			_sprite.texture = DB.tile(7)
			_light.color = Color(0.4, 0.4, 0.4)
			_light.energy = 0.3
			Sfx.play(&"magic")
			FxShape.spawn(world.fx_layer, FxShape.Type.PILLAR, global_position, s.color, 30.0, 0.8)
		Kind.STAIRS:
			if locked:
				world.hud.show_message("Um poder sombrio sela a passagem. Derrote o guardião!", Color(1, 0.5, 0.3))
				return
			Sfx.play(&"door")
			Game.descend()
		Kind.CAMPFIRE:
			Sfx.play(&"magic", -6.0)
			world._on_campfire_lit(self)
		Kind.MERCHANT:
			Sfx.play(&"coins", -4.0)
			world.hud.open_merchant()
		Kind.DUNGEON_ENTRANCE:
			Sfx.play(&"door")
			Game.enter_dungeon(dungeon_level, label, global_position + Vector2(0, 24))
		Kind.DUNGEON_EXIT:
			Sfx.play(&"door")
			Game.exit_dungeon()
		Kind.MIRROR:
			Sfx.play(&"magic", -10.0)
			world._on_mirror(self)


func _persist() -> void:
	if persist_id != "":
		Game.world_opened[persist_id] = true


func _animate_chest() -> void:
	for i in 3:
		_sprite.texture = DB.dt2_texture("chest_full_open_anim_f%d" % i)
		await get_tree().create_timer(0.08).timeout
		if not is_instance_valid(self):
			return
	_sprite.texture = DB.dt2_texture("chest_empty_open_anim_f2")


func _process(delta: float) -> void:
	_t += delta
	match kind:
		Kind.STAIRS:
			_light.energy = (1.0 if not locked else 0.4) + sin(_t * 3.0) * 0.25
			_light.color = Color(0.7, 0.4, 1.0) if not locked else Color(1, 0.2, 0.1)
		Kind.CAMPFIRE:
			_sprite.texture = ow_texture(Vector2i(14 + int(_t * 6.0) % 2, 8))
			_light.energy = 1.2 + sin(_t * 9.0) * 0.12 + sin(_t * 23.0) * 0.08
			# 7.4: chama inclina com o vento e ventania (>0.7) sufoca a fogueira
			# (#14.5.4 - tochas desprotegidas quase se apagam)
			var w := WindField.at(global_position)
			(_sprite.material as ShaderMaterial).set_shader_parameter("wind", w)
			_light.energy *= 1.0 - 0.35 * clampf(w.length() - 0.7, 0.0, 0.3) / 0.3
		Kind.DUNGEON_ENTRANCE, Kind.DUNGEON_EXIT:
			_light.energy = 1.0 + sin(_t * 2.5) * 0.3
		Kind.MIRROR:
			# O vazio "respira" - luz fria que não reflete nada
			_light.energy = 1.0 + sin(_t * 1.3) * 0.2 + sin(_t * 4.7) * 0.08
			_sprite.modulate = Color(0.9, 0.88, 1.0) if sin(_t * 0.7) > 0 else Color(0.8, 0.78, 0.95)
		Kind.SPIKES:
			# Ciclo: escondido 1.6s, subindo, ativo 0.6s, descendo
			var c := fmod(_t, 2.6)
			var f := 0
			if c > 1.6 and c < 1.75:
				f = 2
			elif c >= 1.75 and c < 2.35:
				f = 3
			elif c >= 2.35:
				f = 1
			_sprite.texture = DB.dt2_texture(SPIKE_FRAMES[f])
			if f == 3:
				var p := world.player
				if not _spike_hit and p and not p.is_dead() and p.global_position.distance_to(global_position) < 9.0:
					_spike_hit = true
					p.take_damage(p.max_hp * 0.08 + world.level() * 2.0, global_position)
				for e in world.enemies_near(global_position, 9.0):
					if not _spiked.has(e):
						_spiked[e] = true
						e.take_damage(5.0 + world.level() * 3.0, false, global_position, 0.0)
			else:
				_spike_hit = false
				_spiked.clear()
	if _sprite and kind != Kind.SPIKES:
		_sprite.modulate = Color(1.4, 1.3, 1.1) if _hover else Color.WHITE
