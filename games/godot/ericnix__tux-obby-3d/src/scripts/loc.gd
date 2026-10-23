extends Node
## Localizacao do jogo: portugues (Brasil), ingles e espanhol.
## Tambem guarda a lingua escolhida e atualiza os textos ja criados.

signal locale_changed(locale: String)

const SETTINGS_PATH := "user://tux_obby_settings.cfg"
const DEFAULT_LOCALE := "pt_BR"
const LOCALES := ["pt_BR", "en", "es"]

const STRINGS := {
	"pt_BR": {
		"language": "IDIOMA",
		"key_wasd": "W A S D",
		"key_mouse": "MOUSE",
		"key_space": "ESPAÇO",
		"key_shift": "SHIFT",
		"key_r": "R",
		"key_esc": "ESC",
		"menu_kicker": "PENGUIN PARKOUR",
		"menu_subtitle": "atravesse as ilhas, não deixe o pinguim cair",
		"menu_controls_move": "mover o Tux",
		"menu_controls_camera": "girar a câmera",
		"menu_controls_jump": "pular (e pulo duplo no ar)",
		"menu_controls_sprint": "correr",
		"menu_controls_checkpoint": "voltar ao checkpoint",
		"menu_controls_pause": "pausar o jogo",
		"menu_play": "JOGAR  ▸",
		"menu_best": "Melhor tempo: %s",
		"menu_tip": "ENTER também começa   ·   26 peixinhos estão escondidos pelo caminho",
		"menu_good_luck": "BOA SORTE!",
		"hud_deaths": "QUEDAS %d",
		"hud_fish": "PEIXES %d/%d",
		"hud_checkpoint": "CHECKPOINT %d/%d",
		"hud_best_title": "MELHOR TEMPO",
		"hud_hint": "WASD mover   ·   ESPAÇO pular (2x no ar)   ·   SHIFT correr   ·   R checkpoint   ·   ESC pausa",
		"pause_title": "PAUSADO",
		"pause_subtitle": "respire, o vazio espera",
		"pause_resume": "CONTINUAR",
		"pause_restart": "REINICIAR NÍVEL",
		"pause_quit": "SAIR",
		"pause_hint": "ESC continuar   ·   R reiniciar   ·   Q sair",
		"win_kicker": "PERCURSO COMPLETO",
		"win_title": "VOCÊ CONSEGUIU!",
		"win_subtitle": "o Tux atravessou o vazio — e voltou inteiro",
		"win_time": "TEMPO",
		"win_deaths": "QUEDAS",
		"win_fish": "PEIXES",
		"win_new_record": "NOVO RECORDE!",
		"win_best": "Melhor tempo: %s",
		"win_again": "JOGAR DE NOVO",
		"win_quit": "SAIR",
		"win_hint": "ENTER / R jogar de novo   ·   Q sair",
		"notify_fall": "QUEDA!",
		"notify_all_fish": "TODOS OS PEIXES!",
		"checkpoint_label": "CHECKPOINT %d",
		"finish_label": "META",
		"section_warmup": "1  AQUECIMENTO",
		"fish_hidden": "Peixes escondidos: %d",
	},
	"en": {
		"language": "LANGUAGE",
		"key_wasd": "W A S D",
		"key_mouse": "MOUSE",
		"key_space": "SPACE",
		"key_shift": "SHIFT",
		"key_r": "R",
		"key_esc": "ESC",
		"menu_kicker": "PENGUIN PARKOUR",
		"menu_subtitle": "cross the islands, don't let the penguin fall",
		"menu_controls_move": "move Tux",
		"menu_controls_camera": "rotate the camera",
		"menu_controls_jump": "jump (and double jump in mid-air)",
		"menu_controls_sprint": "sprint",
		"menu_controls_checkpoint": "return to checkpoint",
		"menu_controls_pause": "pause the game",
		"menu_play": "PLAY  ▸",
		"menu_best": "Best time: %s",
		"menu_tip": "ENTER also starts   ·   26 little fish are hidden along the way",
		"menu_good_luck": "GOOD LUCK!",
		"hud_deaths": "FALLS %d",
		"hud_fish": "FISH %d/%d",
		"hud_checkpoint": "CHECKPOINT %d/%d",
		"hud_best_title": "BEST TIME",
		"hud_hint": "WASD move   ·   SPACE jump (2x in mid-air)   ·   SHIFT sprint   ·   R checkpoint   ·   ESC pause",
		"pause_title": "PAUSED",
		"pause_subtitle": "breathe, the void is waiting",
		"pause_resume": "RESUME",
		"pause_restart": "RESTART LEVEL",
		"pause_quit": "QUIT",
		"pause_hint": "ESC resume   ·   R restart   ·   Q quit",
		"win_kicker": "COURSE COMPLETE",
		"win_title": "YOU MADE IT!",
		"win_subtitle": "Tux crossed the void — and made it back in one piece",
		"win_time": "TIME",
		"win_deaths": "FALLS",
		"win_fish": "FISH",
		"win_new_record": "NEW RECORD!",
		"win_best": "Best time: %s",
		"win_again": "PLAY AGAIN",
		"win_quit": "QUIT",
		"win_hint": "ENTER / R play again   ·   Q quit",
		"notify_fall": "FALL!",
		"notify_all_fish": "ALL FISH!",
		"checkpoint_label": "CHECKPOINT %d",
		"finish_label": "FINISH",
		"section_warmup": "1  WARM-UP",
		"fish_hidden": "Hidden fish: %d",
	},
	"es": {
		"language": "IDIOMA",
		"key_wasd": "W A S D",
		"key_mouse": "MOUSE",
		"key_space": "ESPACIO",
		"key_shift": "SHIFT",
		"key_r": "R",
		"key_esc": "ESC",
		"menu_kicker": "PENGUIN PARKOUR",
		"menu_subtitle": "cruza las islas, no dejes que el pingüino caiga",
		"menu_controls_move": "mover a Tux",
		"menu_controls_camera": "girar la cámara",
		"menu_controls_jump": "saltar (y doble salto en el aire)",
		"menu_controls_sprint": "correr",
		"menu_controls_checkpoint": "volver al checkpoint",
		"menu_controls_pause": "pausar el juego",
		"menu_play": "JUGAR  ▸",
		"menu_best": "Mejor tiempo: %s",
		"menu_tip": "ENTER también inicia   ·   26 pececitos están escondidos por el camino",
		"menu_good_luck": "¡BUENA SUERTE!",
		"hud_deaths": "CAÍDAS %d",
		"hud_fish": "PECES %d/%d",
		"hud_checkpoint": "CHECKPOINT %d/%d",
		"hud_best_title": "MEJOR TIEMPO",
		"hud_hint": "WASD mover   ·   ESPACIO saltar (2x en el aire)   ·   SHIFT correr   ·   R checkpoint   ·   ESC pausa",
		"pause_title": "EN PAUSA",
		"pause_subtitle": "respira, el vacío espera",
		"pause_resume": "CONTINUAR",
		"pause_restart": "REINICIAR NIVEL",
		"pause_quit": "SALIR",
		"pause_hint": "ESC continuar   ·   R reiniciar   ·   Q salir",
		"win_kicker": "RECORRIDO COMPLETO",
		"win_title": "¡LO LOGRASTE!",
		"win_subtitle": "Tux cruzó el vacío — y volvió entero",
		"win_time": "TIEMPO",
		"win_deaths": "CAÍDAS",
		"win_fish": "PECES",
		"win_new_record": "¡NUEVO RÉCORD!",
		"win_best": "Mejor tiempo: %s",
		"win_again": "JUGAR DE NUEVO",
		"win_quit": "SALIR",
		"win_hint": "ENTER / R jugar de nuevo   ·   Q salir",
		"notify_fall": "¡CAÍDA!",
		"notify_all_fish": "¡TODOS LOS PECES!",
		"checkpoint_label": "CHECKPOINT %d",
		"finish_label": "META",
		"section_warmup": "1  CALENTAMIENTO",
		"fish_hidden": "Peces escondidos: %d",
	},
}

var current_locale := DEFAULT_LOCALE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_locale()
	TranslationServer.set_locale(current_locale)


func t(key: String, args: Array = []) -> String:
	var table: Dictionary = STRINGS.get(current_locale, STRINGS[DEFAULT_LOCALE])
	var text: String = table.get(key, "")
	if text.is_empty():
		text = STRINGS[DEFAULT_LOCALE].get(key, key)
	if not args.is_empty():
		text = text % args
	return text


func set_locale(locale: String) -> void:
	if not STRINGS.has(locale) or locale == current_locale:
		return
	current_locale = locale
	TranslationServer.set_locale(locale)
	_save_locale()
	refresh_bindings()
	locale_changed.emit(locale)


func bind_text(node: Node, key: String, args: Array = []) -> void:
	if node == null:
		return
	node.set_meta("loc_key", key)
	node.set_meta("loc_args", args)
	node.add_to_group("loc_text")
	_apply(node)


func refresh_bindings() -> void:
	for node in get_tree().get_nodes_in_group("loc_text"):
		if is_instance_valid(node):
			_apply(node)


func _apply(node: Node) -> void:
	var key: String = str(node.get_meta("loc_key", ""))
	if key.is_empty():
		return
	var args: Array = node.get_meta("loc_args", [])
	var text := t(key, args)
	if node is Label3D:
		node.text = text
	elif node is Label or node is Button:
		node.text = text


func _load_locale() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var code := str(config.get_value("ui", "language", DEFAULT_LOCALE))
	if STRINGS.has(code):
		current_locale = code


func _save_locale() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("ui", "language", current_locale)
	config.save(SETTINGS_PATH)
