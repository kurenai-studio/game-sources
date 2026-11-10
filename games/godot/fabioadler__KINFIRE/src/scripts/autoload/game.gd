extends Node
## Estado global: herói atual, profundidade da masmorra, configurações, save e troca de cenas.

const SAVE_PATH := "user://kinfire_save.json"
const SETTINGS_PATH := "user://kinfire_settings.cfg"
const VERSION := "0.3"
const SAVE_VERSION := 4

## 7.7: qualidade mudou nas opções (glow/sombras reagem em runtime)
signal quality_changed

const MAIN_MENU := "res://scenes/menus/main_menu.tscn"
const CHARACTER_CREATION := "res://scenes/menus/character_creation.tscn"
const WORLD := "res://scenes/game/world.tscn"
const OVERWORLD := "res://scenes/game/overworld.tscn"
const PROLOGUE := "res://scenes/game/prologue.tscn"

## Fase do jogador: "prologue" (aldeão do tutorial) ou "created" (personagem criado)
const PHASE_PROLOGUE := "prologue"
const PHASE_CREATED := "created"

const WINDOW_SIZES := [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const FPS_OPTIONS := [30, 60, 120, 144, 240, 0]

## Ações remapeáveis: nome -> [rótulo, teclas padrão]
const ACTIONS := {
	"move_up": ["Mover para cima", [KEY_W, KEY_UP]],
	"move_down": ["Mover para baixo", [KEY_S, KEY_DOWN]],
	"move_left": ["Mover para a esquerda", [KEY_A, KEY_LEFT]],
	"move_right": ["Mover para a direita", [KEY_D, KEY_RIGHT]],
	"skill_1": ["Habilidade 1", [KEY_Z]],
	"skill_2": ["Habilidade 2", [KEY_X]],
	"skill_3": ["Habilidade 3", [KEY_C]],
	"skill_4": ["Habilidade 4", [KEY_V]],
	"racial": ["Habilidade racial", [KEY_R]],
	"heal": ["Cura Simples (Q)", [KEY_Q]],
	"interact": ["Interagir", [KEY_E]],
	"dodge": ["Esquiva", [KEY_SPACE]],
	"force_stand": ["Atacar parado", [KEY_SHIFT]],
	"inventory": ["Inventário", [KEY_I]],
	"character": ["Personagem", [KEY_P]],
	"skills": ["Habilidades", [KEY_K]],
	"skill_tree": ["Arvore de Habilidades", [KEY_B]],
	"quests": ["Missões", [KEY_J]],
	"show_loot": ["Mostrar itens no chão", [KEY_ALT]],
	"pause": ["Menu / Pausa", [KEY_ESCAPE]],
	# Consumíveis 1-9 (barra de consumíveis na HUD)
	"consumable_1": ["Consumível 1", [KEY_1]],
	"consumable_2": ["Consumível 2", [KEY_2]],
	"consumable_3": ["Consumível 3", [KEY_3]],
	"consumable_4": ["Consumível 4", [KEY_4]],
	"consumable_5": ["Consumível 5", [KEY_5]],
	"consumable_6": ["Consumível 6", [KEY_6]],
	"consumable_7": ["Consumível 7", [KEY_7]],
	"consumable_8": ["Consumível 8", [KEY_8]],
	"consumable_9": ["Consumível 9", [KEY_9]],
}

## Fase 5.5: um diálogo emitiu efeito `comercio` - o HUD abre o TradePanel
signal trade_requested(race: StringName)

## Fase 7.1: a hora virou no mundo (MECANICAS #14.1) - 06:00 re-estoque,
## 00:00 autosave "A Vela Virou", contatos noturnos dos mistérios
signal hour_changed(hour: int)

var hero: Hero
var depth: int = 1
## Fase do jogador (PHASE_PROLOGUE | PHASE_CREATED) - REGRAS #15, MECANICAS #12
var phase: String = PHASE_CREATED
## Transiente: true logo após finish_prologue - dispara o diálogo de despertar
## no acampamento (não é salvo; o despertar acontece uma única vez)
var awakened_from_prologue := false
## Ignorância do Laço-Vivo (10 no pós-prólogo, decai ao aprender; REGRAS #2)
var ignorance: int = 0
## Reputação por raça: id da raça -> int 0..4 (Fase 5)
var reputation: Dictionary = {}
## Estado das quests (Fase 4)
var quests: Dictionary = {}
## Log de quests (Fase 4): progresso/recompensas sobre `quests`
var quest_log := QuestLog.new()
## Flags narrativas (diálogos/quests): nome -> valor (MECANICAS #7)
var flags: Dictionary = {}
## Fragmentos da Verdade coletados (Fase 4 - 8 destravam o Final Dourado)
var fragmentos: Array = []
## Guildas criadas pelos jogadores: id -> PlayerGuild
var player_guilds: Dictionary = {}
## Mistérios resolvidos (usado pelo RankSystem)
var mysteries_completed: int = 0
## Economia por território (Fase 5.2): {raça: {"demand": {cat: float}, "sold": [índices]}}
var market: Dictionary = {}
## Casa de leilões (Fase 5.4): {"day": int, "slots": [...]} (REGRAS #9)
var auction: Dictionary = {}
## Mundo aberto
var world_seed: int = 0
var world_time: float = 0.3
var in_dungeon := false
var overworld_pos := Vector2.INF
var respawn_pos := Vector2.INF
var waypoints: Array = []
var world_opened: Dictionary = {}
## Masmorra atual
var dungeon_level: int = 1
var dungeon_name: String = "Masmorra" 
var settings: Dictionary = {
	# Audio
	"master_volume": 0.8,
	"music_volume": 0.6,
	"sfx_volume": 0.8,
	"ambience_volume": 0.7,
	"ui_volume": 0.8,
	"mute_unfocused": true,
	# Vídeo
	"fullscreen": false,
	"vsync": true,
	"max_fps": 1,
	"window_size": 0,
	"ui_scale": 0.8,
	"brightness": 1.0,
	"show_fps": false,
	# 7.2: sombras dinâmicas 2D - 0=Desligadas, 1=Suaves (PCF5), 2=Nítidas (PCF13)
	"shadows": 1,
	# 7.7: FSR 2.2 / MSAA / presets (#14.6)
	"fsr_mode": 2,         # 0=Desligado, 1=Qualidade, 2=Equilibrado, 3=Desempenho
	"msaa": 1,             # 0=Desligado, 1=2x, 2=4x
	"texture_filter": 0,   # 0=Nearest (pixel-art), 1=Linear
	"particle_amount": 1,  # 0=50%, 1=75%, 2=100%
	"glow": true,          # preset Baixo desliga (#14.6)
	# Jogabilidade
	"damage_numbers": true,
	"shake_intensity": 1.0,
	"camera_zoom": 3.0,
	"always_show_health": false,
	"always_show_loot": true,
	"click_to_move": true,
	"monster_density": 1.0,
	"minimap_opacity": 0.85,
	"auto_save": true,
	# Controles: ação -> keycode físico (substitui o primeiro atalho)
	"bindings": {},
}

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _music: AudioStreamPlayer
var _fps_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.install_theme()
	RenderingServer.set_default_clear_color(Color(0.012, 0.008, 0.006))
	_setup_audio_buses()
	_setup_input()
	_load_settings()
	_setup_fade()
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	var cursor := load("res://assets/ui/cursorSword_gold.png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(2, 2))
	var args := OS.get_cmdline_user_args()
	if "--smoke" in args or "--smoke-quick" in args:
		add_child(load("res://tests/smoke_test.gd").new())


func _process(_delta: float) -> void:
	if _fps_label.visible:
		_fps_label.text = "%d FPS" % Engine.get_frames_per_second()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and settings.mute_unfocused:
		AudioServer.set_bus_mute(0, true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		AudioServer.set_bus_mute(0, false)


func aggro_mult() -> float:
	return 1.0 if hero == null else 1.0 + hero.difficulty * 0.1


## 7.7: multiplicador de partículas (#14.6) - presets 50%/75%/100%
func particle_mult() -> float:
	return [0.5, 0.75, 1.0][clampi(int(settings.particle_amount), 0, 2)]


# ------------------------------------------------------------------ CENAS

func change_scene(path: String) -> void:
	get_tree().paused = false
	# 7.5: áudio adaptativo pertence ao mundo - troca de cena silencia as
	# camadas (o novo mundo/menu reassume o que precisa no primeiro _process)
	Audio.stop_all()
	var tw := create_tween()
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	tw.tween_property(_fade_rect, "color:a", 1.0, 0.35)
	await tw.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "color:a", 0.0, 0.45)
	await tw2.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func new_game(h: Hero) -> void:
	hero = h
	phase = PHASE_CREATED
	depth = 1
	world_seed = randi()
	world_time = 0.3
	in_dungeon = false
	overworld_pos = Vector2.INF
	respawn_pos = Vector2.INF
	waypoints = []
	world_opened = {}
	reputation = {}
	quests = {}
	quest_log.tracked = &""
	flags = {}
	fragmentos = []
	market = {}
	auction = {}
	save_game()
	change_scene(OVERWORLD)


## Inicia o prólogo: o jogador é um aldeão nível 0 na Reminiscência (REGRAS #13)
func new_prologue() -> void:
	hero = Hero.create_villager()
	phase = PHASE_PROLOGUE
	ignorance = 0
	depth = 1
	world_seed = randi()
	world_time = 0.3
	in_dungeon = false
	overworld_pos = Vector2.INF
	respawn_pos = Vector2.INF
	waypoints = []
	world_opened = {}
	reputation = {}
	quests = {}
	quest_log.tracked = &""
	flags = {}
	fragmentos = []
	market = {}
	auction = {}
	save_game()
	change_scene(PROLOGUE)


## Conclui o prólogo: criação de personagem terminou, herói real acorda no
## acampamento da raça escolhida (REGRAS #13: nada do prólogo carrega).
func finish_prologue(h: Hero) -> void:
	hero = h
	phase = PHASE_CREATED
	ignorance = 10
	awakened_from_prologue = true
	depth = 1
	in_dungeon = false
	overworld_pos = Vector2.INF
	respawn_pos = Vector2.INF
	waypoints = []
	world_opened = {}
	reputation = {}
	quests = {}
	quest_log.tracked = &""
	flags = {}
	save_game()
	change_scene(OVERWORLD)


func continue_game() -> void:
	if load_game():
		if phase == PHASE_PROLOGUE:
			change_scene(PROLOGUE)
		else:
			change_scene(WORLD if in_dungeon else OVERWORLD)


## Entra numa masmorra a partir do mundo aberto
func enter_dungeon(level: int, dungeon: String, return_pos: Vector2) -> void:
	in_dungeon = true
	depth = 1
	dungeon_level = level
	dungeon_name = dungeon
	overworld_pos = return_pos
	save_game()
	change_scene(WORLD)


func exit_dungeon() -> void:
	in_dungeon = false
	save_game()
	change_scene(OVERWORLD)


func descend() -> void:
	depth += 1
	hero.deepest = maxi(hero.deepest, depth)
	if settings.auto_save:
		save_game()
	change_scene(WORLD)


func quit_to_menu() -> void:
	if hero and not (hero.hardcore and _hero_dead()):
		save_game()
	change_scene(MAIN_MENU)


func _hero_dead() -> bool:
	var w := get_tree().get_first_node_in_group("world")
	return w != null and w.player != null and w.player.is_dead()


func play_music(stream_path: String) -> void:
	var stream: AudioStream = load(stream_path)
	if _music.stream == stream and _music.playing:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music.stream = stream
	_music.play()


# ------------------------------------------------------------------ SAVE

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	if hero == null:
		return
	var w := get_tree().get_first_node_in_group("world") if is_inside_tree() else null
	if w and not in_dungeon and w.player and not w.player.is_dead():
		overworld_pos = w.player.global_position
	var data: Dictionary = {
		"version": SAVE_VERSION, "depth": depth, "hero": hero.to_dict(),
		"phase": phase, "ignorance": ignorance, "reputation": reputation,
		"quests": quests, "flags": flags, "fragmentos": fragmentos,
		"market": market, "auction": auction,
		"world_seed": world_seed, "world_time": world_time, "in_dungeon": in_dungeon,
		"overworld_pos": _vec(overworld_pos), "respawn_pos": _vec(respawn_pos),
		"waypoints": waypoints, "world_opened": world_opened,
		"dungeon_level": dungeon_level, "dungeon_name": dungeon_name,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not data is Dictionary:
		return false
	data = _migrate(data)
	depth = int(data.get("depth", 1))
	hero = Hero.from_dict(data.get("hero", {}))
	phase = str(data.get("phase", PHASE_CREATED))
	ignorance = int(data.get("ignorance", 0))
	reputation = data.get("reputation", {})
	quests = data.get("quests", {})
	quest_log.tracked = &""
	flags = data.get("flags", {})
	fragmentos = data.get("fragmentos", [])
	market = data.get("market", {})
	auction = data.get("auction", {})
	world_seed = int(data.get("world_seed", randi()))
	world_time = float(data.get("world_time", 0.3))
	in_dungeon = bool(data.get("in_dungeon", false))
	overworld_pos = _unvec(data.get("overworld_pos"))
	respawn_pos = _unvec(data.get("respawn_pos"))
	waypoints = data.get("waypoints", [])
	world_opened = data.get("world_opened", {})
	dungeon_level = int(data.get("dungeon_level", 1))
	dungeon_name = str(data.get("dungeon_name", "Masmorra"))
	return true


## Migração encadeada por versão - nunca quebra saves antigos (MECANICAS #12)
func _migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 3))
	if v < 4:
		# v3 -> v4: fase do jogador, ignorância, reputação, quests e fragmentos.
		# Saves antigos sempre têm personagem criado (não existia prólogo).
		data["phase"] = PHASE_CREATED
		data["ignorance"] = 0
		data["reputation"] = {}
		data["quests"] = {}
		data["fragmentos"] = []
		data["version"] = 4
	return data


func _vec(v: Vector2) -> Variant:
	return null if v == Vector2.INF else [v.x, v.y]


func _unvec(v: Variant) -> Vector2:
	return Vector2(float(v[0]), float(v[1])) if v is Array and v.size() == 2 else Vector2.INF


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func save_summary() -> String:
	if not has_save():
		return ""
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text()) if f else null
	if not data is Dictionary:
		return ""
	var h: Dictionary = data.get("hero", {})
	var r := DB.get_race(StringName(h.get("race", "")))
	var c := DB.get_class_data(StringName(h.get("class", "")))
	var diff: Dictionary = DB.DIFFICULTIES[clampi(int(h.get("difficulty", 0)), 0, 3)]
	if str(data.get("phase", "created")) == PHASE_PROLOGUE:
		return "%s - Prólogo (Aldeão, nível %d)" % [h.get("name", "?"), int(h.get("level", 0))]
	var where := "%s, andar %d" % [data.get("dungeon_name", "Masmorra"), int(data.get("depth", 1))] if data.get("in_dungeon", false) else "Mundo aberto"
	return "%s - %s %s nível %d - %s (%s%s)" % [h.get("name", "?"), r.display_name, c.display_name, int(h.get("level", 1)),
		where, diff.name, ", Hardcore" if h.get("hardcore", false) else ""]


# ------------------------------------------------------------------ CONFIGURACÕES

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(settings.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(settings.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(settings.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), linear_to_db(settings.ambience_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), linear_to_db(settings.ui_volume))
	# 7.7: FSR 2.2 (#14.6) - Desligado/Qualidade(0.77)/Equilibrado(0.67)/Desempenho(0.5)
	# aplicado no viewport raiz via API nativa (fsr_sharpness + scaling_3d)
	var vp := get_viewport()
	var fsr_mode := int(settings.fsr_mode)
	var fsr_scales: Array = [1.0, 0.77, 0.67, 0.5]
	if fsr_mode == 0:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	else:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
		vp.fsr_sharpness = 0.4
	vp.scaling_3d_scale = fsr_scales[clampi(fsr_mode, 0, 3)]
	# 7.7: MSAA 2x/4x (#14.6) - 0=Off, 2=2x, 4=4x
	var msaa_modes: Array = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X]
	vp.msaa_2d = msaa_modes[clampi(int(settings.msaa), 0, 2)]
	# 7.7: filtro de textura - nearest preserva pixel-art (#14.6)
	ProjectSettings.set("rendering/textures/canvas_textures/default_texture_filter",
		clampi(int(settings.texture_filter), 0, 1))
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
		if not settings.fullscreen:
			var ws: Vector2i = WINDOW_SIZES[clampi(int(settings.window_size), 0, WINDOW_SIZES.size() - 1)]
			if DisplayServer.window_get_size() != ws:
				DisplayServer.window_set_size(ws)
				var screen := DisplayServer.screen_get_size()
				DisplayServer.window_set_position((screen - ws) / 2)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = FPS_OPTIONS[clampi(int(settings.max_fps), 0, FPS_OPTIONS.size() - 1)]
	get_tree().root.content_scale_factor = float(settings.ui_scale)
	if _fps_label:
		_fps_label.visible = settings.show_fps
	_apply_bindings()
	quality_changed.emit()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in settings:
		cfg.set_value("settings", k, settings[k])
	cfg.save(SETTINGS_PATH)
	apply_settings()


func reset_settings_section(keys: Array) -> void:
	var defaults: Dictionary = {
		"master_volume": 0.8, "music_volume": 0.6, "sfx_volume": 0.8, "ambience_volume": 0.7, "ui_volume": 0.8, "mute_unfocused": true,
		"fullscreen": false, "vsync": true, "max_fps": 1, "window_size": 0, "ui_scale": 0.8, "brightness": 1.0, "show_fps": false, "shadows": 1,
		"fsr_mode": 2, "msaa": 1, "texture_filter": 0, "particle_amount": 1, "glow": true,
		"damage_numbers": true, "shake_intensity": 1.0, "camera_zoom": 3.0, "always_show_health": false, "always_show_loot": true,
		"click_to_move": true, "monster_density": 1.0, "minimap_opacity": 0.85, "auto_save": true, "bindings": {},
	}
	for k in keys:
		settings[k] = defaults[k].duplicate() if defaults[k] is Dictionary else defaults[k]
	save_settings()


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for k in settings:
			var v: Variant = cfg.get_value("settings", k, settings[k])
			if typeof(v) == typeof(settings[k]) or (settings[k] is float and v is int):
				settings[k] = v
	apply_settings()


func _setup_audio_buses() -> void:
	for bus_name in ["Music", "SFX", "Ambience", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _setup_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)
	_fps_label = Label.new()
	_fps_label.position = Vector2(8, 4)
	_fps_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	_fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps_label.add_theme_constant_override("outline_size", 4)
	_fps_label.add_theme_font_size_override("font_size", 13)
	_fps_label.visible = settings.show_fps
	_fade_layer.add_child(_fps_label)


# ------------------------------------------------------------------ INPUT

func _setup_input() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	_apply_bindings()
	var mouse: Dictionary = {"primary": MOUSE_BUTTON_LEFT, "secondary": MOUSE_BUTTON_RIGHT}
	for action in mouse:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var mb := InputEventMouseButton.new()
			mb.button_index = mouse[action]
			InputMap.action_add_event(action, mb)


## Reconstrói os atalhos: tecla personalizada (se houver) + teclas padrão restantes
func _apply_bindings() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var keys: Array = ACTIONS[action][1].duplicate()
		var custom: Variant = settings.bindings.get(action)
		if custom != null:
			keys[0] = int(custom)
		for k in keys:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


func key_for(action: String) -> int:
	var custom: Variant = settings.bindings.get(action)
	return int(custom) if custom != null else ACTIONS[action][1][0]


func key_name(action: String) -> String:
	return OS.get_keycode_string(key_for(action))


func rebind(action: String, keycode: int) -> void:
	settings.bindings[action] = keycode
	save_settings()
