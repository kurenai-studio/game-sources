extends Node
## Screen controller: gameplay stays independent of UI and persistence.
const UI = preload("res://scripts/ui_kit.gd")
const CANDIDATES := [
	{"name": "VÂNIA DO VOUCHER", "short": "VÂNIA", "number": "40", "party": "MRJ", "art": "vania", "role": "A TECNOCRATA", "quote": "Privatiza o asfalto. Terceiriza a cratera.", "perk": "AGILIDADE", "detail": "Mais velocidade para alcançar a próxima promessa.", "color": Color("1d63b8")},
	{"name": "WALDEMAR DA EMENDA", "short": "WALDEMAR", "number": "99", "party": "PBN", "art": "waldemar", "role": "O VETERANO", "quote": "Se cabe no orçamento, cabe no buraco!", "perk": "CRESCIMENTO", "detail": "Um apetite maior para transformar verba em cratera.", "color": Color("8c4d0b")},
	{"name": "BRENO BICICLETINHA", "short": "BRENO", "number": "50", "party": "CCS", "art": "breno", "role": "O IDEALISTA", "quote": "Um buraco holístico, cicloviário e dialético.", "perk": "COMBO", "detail": "Mais tempo para emendar uma absorção na outra.", "color": Color("125b31")}
]
const RANKS := ["PANFLETEIRO", "VEREADOR", "DEPUTADO", "MINISTRO", "BURACO SUPREMO"]
var gameplay: Node2D
var screen: String = "menu"
var selected_candidate: int = 0
var best_score: int = 0
var muted: bool = false
var ui_root: Control
var page: Control
var score_label: Label
var time_label: Label
var rank_label: Label
var combo_label: Label
var progress_bar: ProgressBar
var hint_label: Label
var sound: AudioStreamPlayer
var last_score: int = 0
var last_level: int = 1
var result_stats: Dictionary = {}
var safe_margin: MarginContainer

func _ready() -> void:
	_load_settings()
	gameplay = Node2D.new()
	gameplay.set_script(load("res://scripts/gameplay.gd"))
	add_child(gameplay)
	gameplay.sound_enabled = not muted
	gameplay.stats_changed.connect(_on_stats)
	gameplay.round_finished.connect(show_results)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui_root)
	sound = AudioStreamPlayer.new()
	sound.volume_db = -20
	add_child(sound)
	show_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == "game":
		show_pause()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if screen == "game":
			show_pause()
		elif screen == "pause":
			resume_game()
		elif screen != "menu":
			show_menu()
		get_viewport().set_input_as_handled()

func _clear() -> void:
	for child in ui_root.get_children():
		ui_root.remove_child(child)
		child.queue_free()
	score_label = null
	time_label = null
	rank_label = null
	combo_label = null
	progress_bar = null
	hint_label = null

func _page(background: Color = UI.PAPER) -> VBoxContainer:
	_clear()
	var backdrop := ColorRect.new()
	backdrop.color = background
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(backdrop)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui_root.add_child(scroll)
	safe_margin = MarginContainer.new()
	safe_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	safe_margin.add_theme_constant_override("margin_left", 24)
	safe_margin.add_theme_constant_override("margin_right", 24)
	safe_margin.add_theme_constant_override("margin_top", 34)
	safe_margin.add_theme_constant_override("margin_bottom", 28)
	scroll.add_child(safe_margin)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	safe_margin.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 484
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)
	page = column
	var anim := create_tween()
	column.modulate.a = 0
	anim.tween_property(column, "modulate:a", 1.0, 0.18)
	return column

func _masthead(column: VBoxContainer, right: String = "EDIÇÃO EXTRA • 90s") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var mast := UI.label("CORREIO DO BURACO", 21, UI.INK, true)
	mast.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mast)
	row.add_child(UI.label(right, 13, UI.MUTED))
	column.add_child(UI.rule())

func _act(callback: Callable) -> Callable:
	return func() -> void:
		_beep(520)
		callback.call()

func show_menu() -> void:
	screen = "menu"
	gameplay.set_paused(true)
	gameplay.visible = false
	var column := _page()
	_masthead(column)
	var eyebrow := UI.label("BRASÍLIA, TEMOS UM PEQUENO PROBLEMA.", 15, UI.RED)
	column.add_child(eyebrow)
	var heading := UI.label("BURACO\nPOLÍTICO", 81, UI.INK, true)
	heading.add_theme_constant_override("line_spacing", -20)
	column.add_child(heading)
	column.add_child(UI.body("Promessas enormes. Um apetite ainda maior.", 21, UI.INK))
	var hero := UI.Hero.new()
	hero.custom_minimum_size.y = 223
	hero.clip_contents = true
	column.add_child(hero)
	var story := HBoxContainer.new()
	story.add_theme_constant_override("separation", 18)
	column.add_child(story)
	var edition := UI.label("90", 48, UI.RED, true)
	story.add_child(edition)
	story.add_child(UI.body("SEGUNDOS DE MANDATO\nEngula a praça. Cresça. Faça história.", 18, UI.INK))
	column.add_child(UI.rule())
	var candidate: Dictionary = CANDIDATES[selected_candidate]
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 14)
	column.add_child(strip)
	strip.add_child(UI.framed_portrait("res://assets/art/%s.png" % candidate.art, 58))
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 1)
	strip.add_child(details)
	details.add_child(UI.label("SEU CANDIDATO", 12, UI.MUTED))
	details.add_child(UI.label(candidate.name, 23, UI.INK, true))
	var swap := UI.button("TROCAR", _act(show_selection))
	swap.size_flags_horizontal = Control.SIZE_SHRINK_END
	swap.add_theme_font_size_override("font_size", 19)
	strip.add_child(swap)
	column.add_child(UI.button("ABRIR O BURACO   →", _act(func(): start_game(selected_candidate)), true))
	var footer := HBoxContainer.new()
	column.add_child(footer)
	var record := UI.label("RECORDE  %s" % _number(best_score), 17, UI.MUTED)
	record.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(record)
	var audio_button := UI.button("SOM: OFF" if muted else "SOM: ON", _toggle_audio)
	audio_button.add_theme_font_size_override("font_size", 18)
	audio_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	footer.add_child(audio_button)
	column.add_child(UI.body("Arraste para mover • WASD / setas no computador\nSátira fictícia. Aqui, toda promessa vai pro buraco.", 14))

func show_selection() -> void:
	screen = "selection"
	gameplay.set_paused(true)
	gameplay.visible = false
	var column := _page()
	_masthead(column, "CADERNO ELEITORAL")
	column.add_child(UI.label("ESCOLHA QUEM\nVAI AFUNDAR.", 58, UI.INK, true))
	column.add_child(UI.body("Três candidatos. Nenhum plano de contenção.", 20))
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 10)
	column.add_child(grid)
	for i in range(CANDIDATES.size()):
		var candidate: Dictionary = CANDIDATES[i]
		var card := Button.new()
		card.custom_minimum_size = Vector2(154, 232)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("normal", UI.style(UI.PALE if i != selected_candidate else Color("d5e6ce"), UI.GREEN if i == selected_candidate else UI.INK, 3))
		card.add_theme_stylebox_override("hover", UI.style(Color("fff9ec"), UI.GREEN, 3))
		card.add_theme_stylebox_override("pressed", UI.style(UI.PALE, UI.GREEN, 3))
		card.add_theme_stylebox_override("focus", UI.style(Color(0,0,0,0), UI.GOLD, 3))
		card.pressed.connect(_act(func():
			selected_candidate = i
			_save_settings()
			show_selection()
		), CONNECT_DEFERRED)
		grid.add_child(card)
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 8
		content.offset_top = 10
		content.offset_right = -8
		content.offset_bottom = -10
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", 5)
		card.add_child(content)
		var number := UI.label(candidate.number + " / " + candidate.party, 21, candidate.color, true)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(number)
		content.add_child(UI.portrait("res://assets/art/%s.png" % candidate.art, 118))
		var name_label := UI.label(candidate.short, 26, UI.INK, true)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(name_label)
		var badge := UI.label("✓ ELEITO" if selected_candidate == i else candidate.perk, 13, Color("125b31") if selected_candidate == i else UI.MUTED)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(badge)
	var selected: Dictionary = CANDIDATES[selected_candidate]
	var dossier := UI.panel()
	column.add_child(dossier)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	dossier.add_child(inner)
	inner.add_child(UI.label("FICHA Nº %s   /   %s" % [selected.number, selected.role], 14, UI.RED))
	inner.add_child(UI.label(selected.name, 32, UI.INK, true))
	inner.add_child(UI.body('“%s”' % selected.quote, 23, UI.INK))
	inner.add_child(UI.rule())
	inner.add_child(UI.label("VANTAGEM: " + selected.perk, 18, UI.GREEN, true))
	inner.add_child(UI.body(selected.detail, 18))
	column.add_child(UI.button("CONFIRMA   →   JOGAR", _act(func(): start_game(selected_candidate)), true))
	column.add_child(UI.button("← VOLTAR À CAPA", _act(show_menu)))
	column.add_child(UI.body("Personagens e partidos fictícios. Qualquer promessa\né mera coincidência.", 14))

func start_game(candidate_index: int = 0) -> void:
	selected_candidate = clampi(candidate_index, 0, 2)
	_save_settings()
	screen = "game"
	last_score = 0
	last_level = 1
	gameplay.visible = true
	_build_hud()
	gameplay.sound_enabled = not muted
	gameplay.start_round(selected_candidate)
	_on_stats(gameplay.get_stats())

func _build_hud() -> void:
	_clear()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 34)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(margin)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 7)
	margin.add_child(stack)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	stack.add_child(row)
	var score_box := UI.panel(UI.INK)
	score_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(score_box)
	var score_stack := VBoxContainer.new()
	score_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_stack.add_theme_constant_override("separation", 0)
	score_box.add_child(score_stack)
	score_stack.add_child(UI.label("PONTOS NO ORÇAMENTO", 12, UI.PAPER))
	score_label = UI.label("0", 34, UI.GOLD, true)
	score_stack.add_child(score_label)
	var timer_box := UI.panel()
	timer_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(timer_box)
	var timer_stack := VBoxContainer.new()
	timer_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_stack.add_theme_constant_override("separation", 0)
	timer_box.add_child(timer_stack)
	timer_stack.add_child(UI.label("MANDATO", 12, UI.MUTED))
	time_label = UI.label("01:30", 34, UI.INK, true)
	timer_stack.add_child(time_label)
	var pause := UI.button("Ⅱ", _act(show_pause))
	pause.custom_minimum_size = Vector2(60, 60)
	pause.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pause.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(pause)
	var strip := PanelContainer.new()
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strip_style := UI.style(UI.PAPER, UI.INK, 1, false)
	strip_style.content_margin_left = 10
	strip_style.content_margin_right = 10
	strip_style.content_margin_top = 5
	strip_style.content_margin_bottom = 5
	strip.add_theme_stylebox_override("panel", strip_style)
	stack.add_child(strip)
	var strip_stack := VBoxContainer.new()
	strip_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip_stack.add_theme_constant_override("separation", 4)
	strip.add_child(strip_stack)
	var info := HBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip_stack.add_child(info)
	rank_label = UI.label("PANFLETEIRO", 21, UI.INK, true)
	rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(rank_label)
	combo_label = UI.label("", 20, UI.RED, true)
	info.add_child(combo_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 10
	progress_bar.show_percentage = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for entry in [["background", UI.PALE], ["fill", UI.GREEN]]:
		var bar_style := StyleBoxFlat.new()
		bar_style.bg_color = entry[1]
		bar_style.border_color = UI.INK
		bar_style.set_border_width_all(2)
		bar_style.set_content_margin_all(0)
		progress_bar.add_theme_stylebox_override(entry[0], bar_style)
	strip_stack.add_child(progress_bar)
	hint_label = UI.label("ARRASTE PARA MOVER • COMECE PELOS PAPÉIS", 15, UI.INK)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_top = -58
	hint_label.offset_bottom = -30
	ui_root.add_child(hint_label)

func _on_stats(stats: Dictionary) -> void:
	if screen != "game" or not is_instance_valid(score_label):
		return
	var score := int(stats.get("score", 0))
	score_label.text = _number(score)
	var seconds := maxi(0, int(ceil(float(stats.get("time_left", 0)))))
	time_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	time_label.add_theme_color_override("font_color", UI.RED if seconds <= 15 else UI.INK)
	var level := int(stats.get("level", 1))
	rank_label.text = "NÍVEL %d  /  %s" % [level, str(stats.get("level_name", RANKS[clampi(level - 1, 0, RANKS.size() - 1)])).to_upper()]
	var combo := int(stats.get("combo", 0))
	combo_label.text = "COMBO %d • %.2fx" % [combo, float(stats.get("multiplier", 1.0))] if combo > 1 else ""
	combo_label.add_theme_font_size_override("font_size", 16)
	progress_bar.value = float(stats.get("progress", 0.0)) * 100.0
	if int(stats.get("absorbed", 0)) >= 4:
		hint_label.text = "CONTORNE OS MAIORES. CRESÇA PARA ENGOLIR."
	if int(stats.get("absorbed", 0)) >= 12:
		hint_label.text = ""
	if score > last_score:
		_beep(240 + mini(combo, 8) * 45, 0.055)
	if level > last_level:
		_beep(880, 0.16)
	last_score = score
	last_level = level

func show_pause() -> void:
	if screen != "game":
		return
	screen = "pause"
	gameplay.set_paused(true)
	var column := _page(Color("e4d9c3"))
	_masthead(column, "PEDIDO DE VISTA")
	column.add_child(UI.label("SESSÃO\nSUSPENSA.", 72, UI.RED, true))
	column.add_child(UI.body("Até a cratera tem direito a um intervalo.", 22, UI.INK))
	var stats: Dictionary = gameplay.get_stats()
	column.add_child(UI.rule())
	column.add_child(UI.label("%s PONTOS   •   %ds RESTANTES" % [_number(int(stats.get("score", 0))), int(ceil(float(stats.get("time_left", 0))))], 26, UI.INK, true))
	column.add_child(UI.button("RETOMAR MANDATO   →", _act(resume_game), true))
	column.add_child(UI.button("RECOMEÇAR ELEIÇÃO", _act(func(): start_game(selected_candidate))))
	var utilities := HBoxContainer.new()
	utilities.add_theme_constant_override("separation", 12)
	column.add_child(utilities)
	utilities.add_child(UI.button("VOLTAR À CAPA", _act(show_menu)))
	utilities.add_child(UI.button("SOM: OFF" if muted else "SOM: ON", _toggle_audio))
	column.add_child(UI.body("O relógio fica parado durante a pausa.\nESC também retoma a sessão.", 17))

func resume_game() -> void:
	screen = "game"
	_build_hud()
	gameplay.set_paused(false)
	_on_stats(gameplay.get_stats())

func show_results(stats: Dictionary) -> void:
	screen = "results"
	gameplay.set_paused(true)
	gameplay.visible = false
	result_stats = stats.duplicate(true)
	var score := int(stats.get("score", 0))
	var record := score > best_score
	if record:
		best_score = score
		_save_settings()
	var column := _page()
	_masthead(column, "APURAÇÃO: 100%")
	column.add_child(UI.label("FIM DE MANDATO", 17, UI.RED))
	var level := int(stats.get("level", 1))
	var headline := "PROMETEU TUDO.\nENGOLIU O RESTO."
	if level >= 4:
		headline = "BRASÍLIA FOI\nPRO BURACO!"
	column.add_child(UI.label(headline, 59, UI.INK, true))
	column.add_child(UI.rule())
	var total := HBoxContainer.new()
	column.add_child(total)
	total.add_child(UI.framed_portrait("res://assets/art/%s.png" % CANDIDATES[selected_candidate].art, 118))
	var score_stack := VBoxContainer.new()
	score_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_stack.add_theme_constant_override("separation", 0)
	total.add_child(score_stack)
	score_stack.add_child(UI.label("SALDO DA GESTÃO", 15, UI.MUTED))
	score_stack.add_child(UI.label(_number(score), 74, UI.INK, true))
	score_stack.add_child(UI.label("NOVO RECORDE!" if record else "RECORDE: " + _number(best_score), 19, UI.RED, true))
	var receipt := UI.panel()
	column.add_child(receipt)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	receipt.add_child(list)
	list.add_child(UI.label("PRESTAÇÃO DE CONTAS", 24, UI.INK, true))
	list.add_child(UI.rule())
	_receipt_row(list, "Objetos engolidos", str(int(stats.get("absorbed", 0))))
	_receipt_row(list, "Título final", str(stats.get("level_name", RANKS[clampi(level - 1, 0, RANKS.size() - 1)])))
	_receipt_row(list, "Tamanho da cratera", "%.1f m" % (float(stats.get("radius", 20)) / 10.0))
	list.add_child(UI.body("Mandato encerrado. As promessas continuam.", 16))
	column.add_child(UI.button("NOVA ELEIÇÃO   →", _act(func(): start_game(selected_candidate)), true))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	column.add_child(actions)
	actions.add_child(UI.button("TROCAR CANDIDATO", _act(show_selection)))
	actions.add_child(UI.button("CAPA", _act(show_menu)))
	column.add_child(UI.body("Dica: absorva vários objetos em sequência para\nmanter o combo e multiplicar seus pontos.", 17))

func _receipt_row(list: VBoxContainer, key: String, value: String) -> void:
	var row := HBoxContainer.new()
	list.add_child(row)
	var label := UI.label(key, 18, UI.MUTED)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(UI.label(value, 21, UI.INK, true))

func _toggle_audio() -> void:
	muted = not muted
	gameplay.sound_enabled = not muted
	_save_settings()
	if not muted:
		_beep(660)
	if screen == "pause":
		screen = "game"
		show_pause()
	else:
		show_menu()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var saved_score: Variant = config.get_value("game", "best_score", 0)
		var saved_candidate: Variant = config.get_value("game", "candidate", 0)
		var saved_muted: Variant = config.get_value("audio", "muted", false)
		if saved_score is int:
			best_score = clampi(saved_score, 0, 999999999)
		if saved_candidate is int:
			selected_candidate = clampi(saved_candidate, 0, 2)
		if saved_muted is bool:
			muted = saved_muted

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "best_score", best_score)
	config.set_value("game", "candidate", selected_candidate)
	config.set_value("audio", "muted", muted)
	config.save("user://settings.cfg")

func _number(value: int) -> String:
	var digits := str(value)
	var result := ""
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += "."
		result += digits[i]
	return result

func _beep(frequency: float, duration: float = 0.08) -> void:
	if muted or not is_instance_valid(sound):
		return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(int(22050 * duration))
	for i in range(samples.size()):
		var envelope := pow(1.0 - float(i) / samples.size(), 2.0)
		var value := int(sin(TAU * frequency * i / 22050.0) * 85 * envelope)
		samples[i] = value & 255
	stream.data = samples
	sound.stream = stream
	sound.play()
