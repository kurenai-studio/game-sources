extends Node
## Fase 7.5 (MECANICAS #15): áudio adaptativo - o jogador sente a noite
## antes de vê-la no relógio. Música em camadas com crossfade, ambiência
## por bioma, ducking de diálogo, cues posicionais, reverb de masmorra
## e bus Ambience controlado por WindField.strength.

const AMB := "res://assets/audio/amb/"
const CROSSFADE := 3.0

# --- PLAYERS ---
var _base_a: AudioStreamPlayer
var _base_b: AudioStreamPlayer
var _amb_a: AudioStreamPlayer
var _amb_b: AudioStreamPlayer
var _layer: AudioStreamPlayer
var _sting: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _thunder: AudioStreamPlayer
var _rain_stream: AudioStream
var _thunder_stream: AudioStream

# --- ESTADO ---
var _base_path: String = ""
var _amb_path: String = ""
var _layer_path: String = ""
var _layer_fade_out: float = 4.0
var _duck_db: float = 0.0          # diálogo: música -6dB (#15.1)
var _amb_duck_db: float = 0.0      # fogueira à noite: ambience -3dB
var _reverb_on: bool = false
var _raining := false
var _wind_db: float = 0.0
var _last_state: Dictionary = {}
var _tweens: Dictionary = {}  # AudioStreamPlayer -> Tween

# fade das camadas aditivas por tipo de caminho
const LAYER_FADES: Dictionary = {
	AMB + "mus_combate.wav": [1.5, 4.0],
	AMB + "mus_noite.wav": [3.0, 3.0],
	AMB + "mus_chefe.wav": [1.5, 6.0],
	AMB + "amb_fogueira.wav": [2.0, 2.0],
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# cria players de música base (bus Music)
	_base_a = AudioStreamPlayer.new()
	_base_a.bus = "Music"
	add_child(_base_a)
	_base_b = AudioStreamPlayer.new()
	_base_b.bus = "Music"
	add_child(_base_b)
	# ambiência (bus Ambience)
	_amb_a = AudioStreamPlayer.new()
	_amb_a.bus = "Ambience"
	add_child(_amb_a)
	_amb_b = AudioStreamPlayer.new()
	_amb_b.bus = "Ambience"
	add_child(_amb_b)
	# camada aditiva (bus Music, soma sobre a base)
	_layer = AudioStreamPlayer.new()
	_layer.bus = "Music"
	add_child(_layer)
	# sting (bus SFX)
	_sting = AudioStreamPlayer.new()
	_sting.bus = "SFX"
	add_child(_sting)
	# chuva (bus Ambience, fade 3s) e trovão (bus SFX, one-shot) - 7.6
	_rain = AudioStreamPlayer.new()
	_rain.bus = "Ambience"
	add_child(_rain)
	_rain.volume_db = -60.0
	_thunder = AudioStreamPlayer.new()
	_thunder.bus = "SFX"
	add_child(_thunder)
	# pré-carrega stings
	_sting_camp = load(AMB + "sting_campeao.wav")
	_sting_leg = load(AMB + "sting_lendario.wav")
	_rain_stream = _looped(AMB + "rain_loop.wav")
	_thunder_stream = load(AMB + "thunder.wav")
	# garante loop nos WAVs
	for p in [_base_a, _base_b, _amb_a, _amb_b, _layer]:
		p.finished.connect(func(): _ensure_loop(p))
	# aplica volumes iniciais a partir das settings (duck=0)
	_apply_music_bus()
	_apply_amb_bus()

func _ensure_loop(p: AudioStreamPlayer) -> void:
	if p.stream is AudioStreamWAV:
		(p.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

# ------------------------------------------------------------------ BASE MUSIC

func set_base(path: String) -> void:
	if path == _base_path and _base_path != "":
		return
	_base_path = path
	if path == "":
		_fade_stop(_base_a)
		_fade_stop(_base_b)
		return
	var s := _looped(path)
	var entering := _base_b if _base_a.volume_db > -40.0 else _base_a
	var leaving := _base_a if entering == _base_b else _base_b
	entering.stream = s
	entering.volume_db = -60.0
	entering.play()
	_kill_tweens(entering)
	_kill_tweens(leaving)
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(entering, "volume_db", 0.0, CROSSFADE)
	t.tween_property(leaving, "volume_db", -60.0, CROSSFADE)
	t.chain().tween_callback(leaving.stop)
	_tweens[entering] = t
	_tweens[leaving] = t

func _looped(path: String) -> AudioStream:
	var s: AudioStream = load(path)
	if s is AudioStreamWAV:
		var wav := s as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size()  # loop_end 0 = loop quebrado
	elif s is AudioStreamOggVorbis:
		s.loop = true
	return s

func _fade_stop(p: AudioStreamPlayer) -> void:
	if p.playing:
		_kill_tweens(p)
		var t: Tween = create_tween()
		t.tween_property(p, "volume_db", -60.0, 1.2)
		t.tween_callback(p.stop)
		_tweens[p] = t

# ------------------------------------------------------------------ AMBIENCIA

func set_ambience(path: String) -> void:
	if path == _amb_path and _amb_path != "":
		return
	_amb_path = path
	if path == "":
		_fade_stop(_amb_a)
		_fade_stop(_amb_b)
		return
	var s := _looped(path)
	var entering := _amb_b if _amb_a.volume_db > -40.0 else _amb_a
	var leaving := _amb_a if entering == _amb_b else _amb_b
	entering.stream = s
	entering.volume_db = -60.0
	entering.play()
	_kill_tweens(entering)
	_kill_tweens(leaving)
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(entering, "volume_db", 0.0, CROSSFADE)
	t.tween_property(leaving, "volume_db", -60.0, CROSSFADE)
	t.chain().tween_callback(leaving.stop)
	_tweens[entering] = t
	_tweens[leaving] = t

func update_wind_gain(pos: Vector2) -> void:
	# #15.1: bus Ambience respira com o vento (-7dB na calmaria... +3dB na ventania)
	_wind_db = lerpf(-7.0, 3.0, clampf(WindField.at(pos).length(), 0.0, 1.0))
	_apply_amb_bus()

# ------------------------------------------------------------------ CAMADA ADITIVA (combate/noite/chefe/descanso)

func set_layer(path: String) -> void:
	if path == _layer_path:
		return
	var old := _layer_path
	_layer_path = path
	var fades: Array = LAYER_FADES.get(path, [2.0, 2.0])
	_kill_tweens(_layer)
	if _layer.playing and old != "":
		var out_t: Tween = create_tween()
		out_t.tween_property(_layer, "volume_db", -60.0, float(fades[1]))
		out_t.tween_callback(func(): _start_layer(path, fades))
		_tweens[_layer] = out_t
	else:
		_start_layer(path, fades)

func _start_layer(path: String, fades: Array) -> void:
	if path != _layer_path:
		return
	if path == "":
		_layer.stop()
		return
	var s := _looped(path)
	_layer.stream = s
	_layer.volume_db = -60.0
	_layer.play()
	var t: Tween = create_tween()
	t.tween_property(_layer, "volume_db", 0.0, float(fades[0]))
	_tweens[_layer] = t

# ------------------------------------------------------------------ STING (chefes/campeões)

var _sting_camp: AudioStream
var _sting_leg: AudioStream

func sting(rarity: int) -> bool:
	if rarity >= Enemy.Rarity.LENDARIO:
		_sting.stream = _sting_leg
	elif rarity == Enemy.Rarity.CAMPEAO:
		_sting.stream = _sting_camp
	else:
		return false
	if _sting.stream != null:
		_sting.play()
	return true

# ------------------------------------------------------------------ DUCKING / REVERB

## 7.6: chuva molha o som (#14.4) - loop de chuva no bus Ambience, fade 3s
func set_rain(on: bool) -> void:
	if on == _raining:
		return
	_raining = on
	if on:
		_rain.stream = _rain_stream
		_rain.play()
	_kill_tweens(_rain)
	var t: Tween = create_tween()
	t.tween_property(_rain, "volume_db", -9.0 if on else -60.0, 3.0)
	_tweens[_rain] = t
	if not on:
		t.chain().tween_callback(_rain.stop)

## 7.6: trovão - one-shot no bus SFX
func play_thunder() -> void:
	if _thunder_stream == null:
		return
	_thunder.stream = _thunder_stream
	_thunder.play()

func duck_music(on: bool) -> void:
	_duck_db = -6.0 if on else 0.0
	_apply_music_bus()

func _apply_music_bus() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(Game.settings.music_volume) + _duck_db)

func set_amb_duck(db: float) -> void:
	_amb_duck_db = db
	_apply_amb_bus()

func _apply_amb_bus() -> void:
	var idx := AudioServer.get_bus_index("Ambience")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(Game.settings.ambience_volume) + _wind_db + _amb_duck_db)

# reverb de masmorra: adiciona/remove efeito no bus SFX e Ambience
func set_dungeon_reverb(on: bool) -> void:
	if on == _reverb_on:
		return
	_reverb_on = on
	var sfx_idx := AudioServer.get_bus_index("SFX")
	var amb_idx := AudioServer.get_bus_index("Ambience")
	if on:
		var rev := AudioEffectReverb.new()
		rev.room_size = 0.8
		rev.damping = 0.6
		rev.wet = 0.35
		AudioServer.add_bus_effect(sfx_idx, rev)
		AudioServer.add_bus_effect(amb_idx, rev.duplicate())
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 2500.0
		lp.resonance = 0.8
		AudioServer.add_bus_effect(amb_idx, lp)
	else:
		# remove efeitos (assume ordem: reverb, [lp no amb])
		AudioServer.remove_bus_effect(sfx_idx, AudioServer.get_bus_effect_count(sfx_idx) - 1)
		var amb_count := AudioServer.get_bus_effect_count(amb_idx)
		if amb_count > 0:
			AudioServer.remove_bus_effect(amb_idx, amb_count - 1)  # lowpass
		if amb_count > 1:
			AudioServer.remove_bus_effect(amb_idx, amb_count - 2)  # reverb

# ------------------------------------------------------------------ UPDATE DO MUNDO

func _combat_near(world: World) -> bool:
	for e in world.enemies_near(world.player.global_position, 450.0):
		if e.state in [Enemy.State.CHASE, Enemy.State.WINDUP, Enemy.State.ATTACK] and e._target == world.player:
			return true
	return false

func _boss_near(world: World) -> bool:
	var ow := world as Overworld
	if ow != null:
		for e in ow.enemies_near(world.player.global_position, 700.0):
			if e.rarity >= Enemy.Rarity.CAMPEAO:
				return true
		return false
	return world.boss != null and is_instance_valid(world.boss) and not world.boss.is_dead()

func _rest_near(ow: Overworld) -> bool:
	if not ow._is_night():
		return false
	for n in ow.get_tree().get_nodes_in_group("interactables"):
		if n is Interactable and n.kind == Interactable.Kind.CAMPFIRE:
			if n.global_position.distance_squared_to(ow.player.global_position) < 14400.0:  # 1202
				return true
	return false

func update_world(world: World) -> void:
	if world == null or world.player == null:
		return
	var amb := ""
	var layer := ""
	var base := ""
	var reverb := false
	var ow := world as Overworld
	var pro := world as Prologue
	if ow != null:
		base = AMB + "mus_overworld.wav"
		var b: StringName = ow.og.biome_at(ow.world_to_cell(world.player.global_position))
		amb = AMB + "amb_%s.wav" % b
		if not FileAccess.file_exists(amb):
			amb = AMB + "amb_planicie.wav"
		if _rest_near(ow):
			layer = AMB + "amb_fogueira.wav"
			set_amb_duck(-3.0 if ow._is_night() else 0.0)
		else:
			set_amb_duck(0.0)
		if layer == "" and ow._is_night():
			layer = AMB + "mus_noite.wav"
	elif pro != null:
		# Prólogo: clareira na floresta à noite - sem reverb, ambiência de floresta
		amb = AMB + "amb_floresta.wav"
	else:
		# Masmorra: reverb fake + ping (#15.3); música base vem do Game.play_music
		amb = AMB + "amb_masmorra.wav"
		reverb = true
	if _combat_near(world):
		layer = AMB + "mus_combate.wav"
	if _boss_near(world):
		layer = AMB + "mus_chefe.wav"
	set_base(base)
	set_ambience(amb)
	set_layer(layer)
	_apply_amb_bus()
	update_wind_gain(world.player.global_position)
	set_dungeon_reverb(reverb)

# ------------------------------------------------------------------ GETTERS (smoke)

func stop_all() -> void:
	## Troca de cena: silencia as camadas adaptativas (sem mexer em Game._music)
	set_base("")
	set_ambience("")
	set_layer("")
	set_rain(false)
	_duck_db = 0.0
	_amb_duck_db = 0.0
	_apply_music_bus()

func base_path() -> String: return _base_path
func ambience_path() -> String: return _amb_path
func layer_path() -> String: return _layer_path
func amb_gain_db() -> float: return _wind_db
func has_reverb() -> bool: return _reverb_on
func music_duck_db() -> float: return _duck_db
func amb_duck_db() -> float: return _amb_duck_db

# ------------------------------------------------------------------ HELPERS

func _kill_tweens(target: Node) -> void:
	if _tweens.has(target):
		var t: Tween = _tweens[target]
		if t and t.is_valid():
			t.kill()
		_tweens.erase(target)

func _tween(target: Node, property: String, final_val: Variant, duration: float) -> Tween:
	_kill_tweens(target)
	var tw: Tween = create_tween()
	tw.tween_property(target, property, final_val, duration)
	_tweens[target] = tw
	return tw

func _tween_chain(target: Node, property: String, final_val: Variant, duration: float, callback: Callable) -> Tween:
	_kill_tweens(target)
	var tw: Tween = create_tween()
	tw.tween_property(target, property, final_val, duration)
	tw.chain().tween_callback(callback)
	_tweens[target] = tw
	return tw