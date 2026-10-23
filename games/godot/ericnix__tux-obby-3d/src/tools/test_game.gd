extends Node
## Teste automatizado de jogabilidade. Roda sem interface:
## godot --headless --path . --scene res://tools/test_game.tscn
## Verifica movimento, pulo duplo, morte/respawn, checkpoints, peixes,
## trampolim, plataformas móveis, pausa, vitória e áudio.

const SAVE_PATH := "user://tux_obby.cfg"

var main: Node3D
var failures := 0
var checks := 0
var _had_save := false
var _save_backup := PackedByteArray()
var _original_locale := "pt_BR"
var _had_locale_settings := false
var _locale_settings_backup := PackedByteArray()


func _ready() -> void:
	print("=== TESTE AUTOMATICO TUX OBBY ===")
	# Guarda o save real para restaurar no fim do teste.
	if FileAccess.file_exists(SAVE_PATH):
		_had_save = true
		_save_backup = FileAccess.get_file_as_bytes(SAVE_PATH)
	# O teste roda sempre em portugues, independente da lingua salva pelo jogador.
	_original_locale = Loc.current_locale
	if FileAccess.file_exists(Loc.SETTINGS_PATH):
		_had_locale_settings = true
		_locale_settings_backup = FileAccess.get_file_as_bytes(Loc.SETTINGS_PATH)
	Loc.set_locale("pt_BR")
	main = load("res://scenes/main.tscn").instantiate()
	main.auto_pause_enabled = false
	add_child(main)
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	_test_menu()
	await _test_start()
	await _test_input_map()
	await _test_movement()
	await _test_jump()
	await _test_death()
	await _test_checkpoint()
	await _test_fish()
	await _test_pause()
	await _test_bounce()
	await _test_moving_platform()
	await _test_vanishing_platform()
	await _test_audio()
	await _test_finish()

	print("----------------------------------")
	print("VERIFICACOES: %d | FALHAS: %d" % [checks, failures])
	if failures == 0:
		print("RESULTADO: OK")
	else:
		print("RESULTADO: FALHOU")
	_cleanup_save()
	_cleanup_locale()
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)


func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("  [OK] ", label)
	else:
		failures += 1
		print("  [FALHA] ", label)


func _test_menu() -> void:
	print("\n-- Menu --")
	check(main.state == main.State.MENU, "estado inicial e MENU")
	check(main.hud.start_overlay.visible, "overlay inicial visivel")
	check(main.player.frozen, "jogador comecou congelado")
	check(main.level.total_fish == 26, "nivel tem 26 peixes (tem %d)" % main.level.total_fish)
	check(main.level.checkpoint_spawns.size() - 1 == 5, "nivel tem 5 checkpoints")
	check(main.hud.checkpoint_label.text == Loc.t("hud_checkpoint", [0, 5]), "HUD de checkpoints zerado")
	check(main.hud._lang_buttons.size() == 3, "menu tem 3 botoes de idioma")
	check(Loc.current_locale == "pt_BR", "teste comeca em portugues")
	check(_has_text(main.hud.start_overlay, "BOA SORTE!"), "menu em portugues")
	check(_has_text(main.level, "1  AQUECIMENTO"), "placa do nivel em portugues")

	main.hud._lang_buttons["en"].pressed.emit()
	check(Loc.current_locale == "en", "troca para ingles pelo botao do menu")
	var settings := ConfigFile.new()
	var settings_ok := settings.load(Loc.SETTINGS_PATH) == OK
	check(settings_ok and str(settings.get_value("ui", "language", "")) == "en", "idioma salvo no arquivo de configuracao")
	check(Loc.t("menu_play") == "PLAY  ▸", "botao JOGAR traduzido")
	check(main.hud.deaths_label.text == "FALLS 0", "HUD de mortes em ingles")
	check(main.hud.fish_label.text == "FISH 0/26", "HUD de peixes em ingles")
	check(main.hud.start_best_label.text.begins_with("Best time:"), "recorde em ingles")
	check(main.hud.hint_label.text.begins_with("WASD move"), "dica de controles em ingles")
	check(_has_text(main.hud.start_overlay, "GOOD LUCK!"), "menu em ingles")
	check(_has_text(main.level, "1  WARM-UP"), "placa do nivel em ingles")
	check(_has_text(main.level, "FINISH"), "portal de chegada em ingles")

	main.hud._lang_buttons["es"].pressed.emit()
	check(Loc.current_locale == "es", "troca para espanhol pelo botao do menu")
	check(Loc.t("notify_fall") == "¡CAÍDA!", "aviso de queda traduzido")
	check(main.hud.deaths_label.text == "CAÍDAS 0", "HUD de mortes em espanhol")
	check(main.hud.fish_label.text == "PECES 0/26", "HUD de peixes em espanhol")
	check(main.hud.start_best_label.text.begins_with("Mejor tiempo:"), "recorde em espanhol")
	check(main.hud.hint_label.text.contains("ESPACIO"), "dica de controles em espanhol")
	check(_has_text(main.hud.start_overlay, "¡BUENA SUERTE!"), "menu em espanhol")
	check(_has_text(main.level, "1  CALENTAMIENTO"), "placa do nivel em espanhol")

	main.hud._lang_buttons["pt_BR"].pressed.emit()
	check(Loc.current_locale == "pt_BR", "volta para portugues pelo botao do menu")
	check(main.hud.deaths_label.text == "QUEDAS 0", "HUD de mortes em portugues")
	check(main.hud.fish_label.text == "PEIXES 0/26", "HUD de peixes em portugues")
	check(_has_text(main.level, "1  AQUECIMENTO"), "placa do nivel em portugues de novo")


func _test_start() -> void:
	print("\n-- Inicio da partida --")
	main.start_game()
	await get_tree().create_timer(0.35).timeout
	check(main.state == main.State.PLAYING, "start_game muda para PLAYING")
	check(not main.player.frozen, "jogador liberado")
	check(not main.hud.start_overlay.visible, "overlay inicial escondido")
	check(main.elapsed > 0.0, "cronometro andando")
	await get_tree().physics_frame
	check(main.player.is_on_floor(), "jogador apoiado na plataforma inicial")


func _test_input_map() -> void:
	print("\n-- Mapa de entrada --")
	for action in ["move_forward", "move_back", "move_left", "move_right", "jump", "sprint", "pause", "respawn", "quit"]:
		check(InputMap.has_action(action), "acao '%s' existe" % action)
	check(InputMap.action_get_events("quit").size() == 1, "Q mapeado para sair")
	check(InputMap.action_get_events("pause").size() >= 1, "ESC mapeado para pausar")


func _test_movement() -> void:
	print("\n-- Movimento --")
	var start_z: float = main.player.global_position.z
	Input.action_press("move_forward")
	await get_tree().create_timer(0.55).timeout
	Input.action_release("move_forward")
	await get_tree().create_timer(0.35).timeout
	var moved: float = start_z - main.player.global_position.z
	check(moved > 2.0, "W move para frente (%.2f m)" % moved)
	check(main.player.is_on_floor(), "continuou no chao ao andar")
	var speed_dbg: String = "vel=%.2f" % Vector2(main.player.velocity.x, main.player.velocity.z).length()
	print("    ", speed_dbg)


func _test_jump() -> void:
	print("\n-- Pulo e pulo duplo --")
	var y0: float = main.player.global_position.y
	Input.action_press("jump")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("jump")
	check(main.player.velocity.y > 3.0, "pulo simples aplica impulso (%.2f)" % main.player.velocity.y)
	await get_tree().create_timer(0.30).timeout
	check(not main.player.is_on_floor(), "esta no ar depois do pulo")
	check(main.player.jumps_left == 1, "pulo duplo disponivel no ar")
	var y_before: float = main.player.global_position.y
	Input.action_press("jump")
	await get_tree().create_timer(0.08).timeout
	Input.action_release("jump")
	check(main.player.jumps_left == 0, "pulo duplo consumido")
	check(main.player.velocity.y > 2.0, "pulo duplo da impulso extra (%.2f)" % main.player.velocity.y)
	await get_tree().create_timer(0.15).timeout
	check(main.player.global_position.y > y_before, "altura aumentou apos pulo duplo")
	await get_tree().create_timer(1.2).timeout
	check(main.player.is_on_floor(), "voltou ao chao")
	check(main.player.global_position.y >= y0 - 0.5, "nao atravessou a plataforma")


func _test_death() -> void:
	print("\n-- Queda e respawn --")
	var deaths_before: int = main.deaths
	main.player.global_position = Vector3(0.0, -10.0, -20.0)
	await get_tree().create_timer(1.9).timeout
	check(main.deaths == deaths_before + 1, "queda conta uma morte")
	check(not main.player.dead, "jogador reviveu")
	check(main.player.global_position.distance_to(main.spawn) < 1.0, "renasceu no ponto atual")
	check(main.hud.deaths_label.text == Loc.t("hud_deaths", [main.deaths]), "HUD de mortes atualizado")


func _test_checkpoint() -> void:
	print("\n-- Checkpoint --")
	var cp: Checkpoint = null
	for node in main.level.get_children():
		if node is Checkpoint and node.index == 1:
			cp = node
			break
	check(cp != null, "checkpoint 1 existe")
	if cp == null:
		return
	main.player.global_position = cp.global_position + Vector3(0, 0.2, 0)
	await get_tree().create_timer(0.45).timeout
	check(cp.active, "checkpoint 1 ativou ao encostar")
	check(main.current_checkpoint == 1, "jogo registrou checkpoint 1")
	check(main.spawn.distance_to(cp.respawn_point) < 0.01, "ponto de respawn atualizado")
	check(main.hud.checkpoint_label.text == Loc.t("hud_checkpoint", [1, 5]), "HUD mostra 1/5")

	# Morre de proposito para confirmar que renasce no checkpoint novo.
	main.player.global_position = Vector3(0.0, -10.0, -20.0)
	await get_tree().create_timer(1.9).timeout
	check(main.player.global_position.distance_to(cp.respawn_point) < 1.0, "renasceu no checkpoint 1")

	# R (respawn manual) deve voltar ao mesmo checkpoint sem contar morte.
	var deaths_before: int = main.deaths
	main.manual_respawn()
	await get_tree().create_timer(0.8).timeout
	check(main.player.global_position.distance_to(cp.respawn_point) < 1.0, "R voltou ao checkpoint")
	check(main.deaths == deaths_before, "R nao conta queda")
	check(main.state == main.State.PLAYING, "R mantem a partida ativa")


func _test_fish() -> void:
	print("\n-- Peixes --")
	var fish_nodes := _find_fish(main.level)
	check(fish_nodes.size() + main.fish == main.level.total_fish, "todos os peixes instanciados ou ja coletados (%d restantes + %d coletados)" % [fish_nodes.size(), main.fish])
	if fish_nodes.is_empty():
		return
	var fish_before: int = main.fish
	var target: Node3D = fish_nodes[0]
	main.player.global_position = target.global_position + Vector3(0, -1.15, 0)
	main.player.velocity = Vector3.ZERO
	await get_tree().create_timer(0.45).timeout
	check(main.fish == fish_before + 1, "peixe coletado ao encostar")
	check(main.hud.fish_label.text == Loc.t("hud_fish", [main.fish, 26]), "HUD de peixes atualizado")


func _test_pause() -> void:
	print("\n-- Pausa --")
	var elapsed_before: float = main.elapsed
	main.pause_game()
	await get_tree().create_timer(0.3).timeout
	check(main.state == main.State.PAUSED, "estado PAUSED")
	check(get_tree().paused, "arvore pausada")
	check(main.hud.pause_overlay.visible, "overlay de pausa visivel")
	check(is_equal_approx(main.elapsed, elapsed_before), "cronometro parado na pausa")
	main.resume_game()
	await get_tree().create_timer(0.2).timeout
	check(main.state == main.State.PLAYING, "voltou para PLAYING")
	check(not get_tree().paused, "arvore despausada")
	check(main.elapsed > elapsed_before, "cronometro voltou a andar")


func _test_bounce() -> void:
	print("\n-- Trampolim --")
	var pad: BouncePad = null
	for node in main.level.get_children():
		if node is BouncePad:
			pad = node
			break
	check(pad != null, "trampolim existe")
	if pad == null:
		return
	main.player.global_position = pad.global_position + Vector3(0, 0.35, 0)
	main.player.velocity = Vector3.ZERO
	await get_tree().create_timer(0.3).timeout
	check(main.player.velocity.y > 6.0 or main.player.global_position.y > pad.global_position.y + 2.0, "trampolim arremessa o Tux para cima")
	await get_tree().create_timer(1.4).timeout


func _test_moving_platform() -> void:
	print("\n-- Plataforma movel --")
	var platform: MovingPlatform = null
	for node in main.level.get_children():
		if node is MovingPlatform:
			platform = node
			break
	check(platform != null, "plataforma movel existe")
	if platform == null:
		return
	var before: Vector3 = platform.global_position
	await get_tree().create_timer(0.45).timeout
	check(platform.global_position.distance_to(before) > 0.1, "plataforma se moveu")

	# O Tux deve ser carregado pela plataforma.
	main.player.global_position = platform.global_position + Vector3(0, 0.55, 0)
	main.player.velocity = Vector3.ZERO
	await get_tree().create_timer(0.25).timeout
	var offset: Vector3 = main.player.global_position - platform.global_position
	await get_tree().create_timer(0.9).timeout
	var drift: float = (main.player.global_position - (platform.global_position + offset)).length()
	check(drift < 1.2, "Tux acompanha a plataforma movel (deriva %.2f m)" % drift)
	check(main.player.is_on_floor(), "Tux continua apoiado na plataforma movel")


func _test_vanishing_platform() -> void:
	print("\n-- Plataforma que some --")
	var platform: VanishingPlatform = null
	for node in main.level.get_children():
		if node is VanishingPlatform:
			platform = node
			break
	check(platform != null, "plataforma fantasma existe")
	if platform == null:
		return
	var saw_solid := false
	var saw_off := false
	for i in 50:
		if platform.collision_layer == 1:
			saw_solid = true
		else:
			saw_off = true
		await get_tree().create_timer(0.08).timeout
	check(saw_solid, "plataforma fica solida")
	check(saw_off, "plataforma desaparece no ciclo")


func _test_audio() -> void:
	print("\n-- Audio --")
	var sfx: Node = get_node("/root/Sfx")
	check(sfx._streams.size() == 9, "9 efeitos carregados (tem %d)" % sfx._streams.size())
	check(sfx._music.stream != null, "trilha carregada")
	check(sfx._music.playing, "trilha tocando")
	for sound_name in ["jump", "double_jump", "bounce", "land", "death", "checkpoint", "fish", "win", "click"]:
		check(sfx._streams.has(sound_name), "som '%s' presente" % sound_name)


func _test_finish() -> void:
	print("\n-- Chegada --")
	var gate: FinishGate = null
	for node in main.level.get_children():
		if node is FinishGate:
			gate = node
			break
	check(gate != null, "portal de chegada existe")
	if gate == null:
		return
	main.player.global_position = gate.global_position + Vector3(0, 0.25, 0)
	main.player.velocity = Vector3.ZERO
	await get_tree().create_timer(0.5).timeout
	check(main.state == main.State.WON, "entrar no portal vence a partida")
	check(main.hud.win_overlay.visible, "tela de vitoria visivel")
	check(main.best_time > 0.0, "melhor tempo registrado (%.2f s)" % main.best_time)
	check(main.player.frozen, "jogador congelado na vitoria")


func _find_fish(root: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for child in root.get_children():
		if child is FishPickup:
			out.append(child)
		out.append_array(_find_fish(child))
	return out


func _has_text(root: Node, text: String) -> bool:
	for child in root.get_children():
		if child is Label and child.text == text:
			return true
		if child is Button and child.text == text:
			return true
		if child is Label3D and child.text == text:
			return true
		if _has_text(child, text):
			return true
	return false


func _cleanup_save() -> void:
	if _had_save:
		var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_buffer(_save_backup)
			file.close()
		print("(recordes originais restaurados)")
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		print("(recordes de teste removidos)")


func _cleanup_locale() -> void:
	Loc.set_locale(_original_locale)
	if _had_locale_settings:
		var file := FileAccess.open(Loc.SETTINGS_PATH, FileAccess.WRITE)
		if file != null:
			file.store_buffer(_locale_settings_backup)
			file.close()
		print("(idioma original restaurado)")
	elif FileAccess.file_exists(Loc.SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Loc.SETTINGS_PATH))
		print("(configuracao de idioma do teste removida)")
