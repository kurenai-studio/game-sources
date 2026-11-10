class_name OptionsPanel
extends PanelContainer
## Tela de opções com abas (Audio, Vídeo, Jogabilidade, Controles). Usada no menu e na pausa.

signal closed

var _waiting_action := ""
var _bind_buttons: Dictionary = {}
var _tabs: TabContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_build(0)


func _build(tab: int) -> void:
	_bind_buttons.clear()
	var w := UIKit.window_panel("Opções", Vector2(640, 0), _close)
	add_child(w.panel)
	var body: VBoxContainer = w.body

	_tabs = TabContainer.new()
	_tabs.custom_minimum_size = Vector2(620, 440)
	body.add_child(_tabs)

	var audio := _page("Audio")
	_slider(audio, "Volume Geral", "master_volume", 0.0, 1.0, 0.05, true)
	_slider(audio, "Música", "music_volume", 0.0, 1.0, 0.05, true)
	_slider(audio, "Efeitos Sonoros", "sfx_volume", 0.0, 1.0, 0.05, true)
	_slider(audio, "Ambiência", "ambience_volume", 0.0, 1.0, 0.05, true)
	_slider(audio, "Interface", "ui_volume", 0.0, 1.0, 0.05, true)
	_check(audio, "Silenciar quando a janela perde o foco", "mute_unfocused")
	_reset_button(audio, ["master_volume", "music_volume", "sfx_volume", "ambience_volume", "ui_volume", "mute_unfocused"])

	var video := _page("Vídeo")
	_check(video, "Tela Cheia", "fullscreen")
	var sizes: Array = []
	for s in Game.WINDOW_SIZES:
		sizes.append("%d x %d" % [s.x, s.y])
	_option(video, "Tamanho da Janela", "window_size", sizes)
	_check(video, "Sincronização Vertical (VSync)", "vsync")
	var fps: Array = []
	for f in Game.FPS_OPTIONS:
		fps.append("Ilimitado" if f == 0 else str(f))
	_option(video, "FPS Máximo", "max_fps", fps)
	_slider(video, "Escala da Interface", "ui_scale", 0.75, 1.5, 0.05, true)
	_slider(video, "Brilho da Masmorra", "brightness", 0.6, 1.8, 0.05, true)
	_check(video, "Mostrar FPS", "show_fps")
	_option(video, "Sombras", "shadows", ["Desligadas", "Suaves (PCF5)", "Nítidas (PCF13)"])
	# 7.7: FSR 2.2 / MSAA / presets de qualidade (#14.6)
	_preset_option(video)
	_option(video, "FSR 2.2 (ampliação)", "fsr_mode", ["Desligado", "Qualidade", "Equilibrado", "Desempenho"])
	_option(video, "MSAA", "msaa", ["Desligado", "2x", "4x"])
	_option(video, "Filtro de Textura", "texture_filter", ["Nítido (pixel-art)", "Suave (linear)"])
	_option(video, "Partículas", "particle_amount", ["50%", "75%", "100%"])
	_check(video, "Brilho/Glow (bloom de luzes, loot raro e vagalumes)", "glow")
	_reset_button(video, ["fullscreen", "window_size", "vsync", "max_fps", "ui_scale", "brightness", "show_fps", "shadows", "fsr_mode", "msaa", "texture_filter", "particle_amount", "glow"])

	var game := _page("Jogabilidade")
	_check(game, "Números de Dano", "damage_numbers")
	_slider(game, "Intensidade do Tremor de Tela", "shake_intensity", 0.0, 2.0, 0.1, true)
	_slider(game, "Zoom da Câmera", "camera_zoom", 2.0, 4.5, 0.25, false)
	_check(game, "Sempre mostrar barras de vida dos inimigos", "always_show_health")
	_check(game, "Sempre mostrar nomes dos itens no chão (senão: segure Alt)", "always_show_loot")
	_check(game, "Clique para mover (estilo Diablo)", "click_to_move")
	_slider(game, "Densidade de Monstros", "monster_density", 0.5, 2.0, 0.25, true)
	_slider(game, "Opacidade do Minimapa", "minimap_opacity", 0.0, 1.0, 0.05, true)
	_check(game, "Salvar automaticamente ao descer de nível", "auto_save")
	_reset_button(game, ["damage_numbers", "shake_intensity", "camera_zoom", "always_show_health", "always_show_loot", "click_to_move", "monster_density", "minimap_opacity", "auto_save"])

	var controls := _page("Controles")
	controls.add_child(UIKit.label("Clique em um atalho e pressione a nova tecla (Esc cancela).", 14, UIKit.TEXT_DIM))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	controls.add_child(grid)
	for action in Game.ACTIONS:
		var l := UIKit.label(Game.ACTIONS[action][0], 15)
		l.custom_minimum_size.x = 300
		grid.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(160, 30)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(_start_rebind.bind(action))
		grid.add_child(b)
		_bind_buttons[action] = b
	controls.add_child(UIKit.label("Mouse: botão esquerdo = mover/atacar - botão direito = habilidade secundária", 13, UIKit.TEXT_DIM))
	_reset_button(controls, ["bindings"])
	_refresh_bindings()

	var back := UIKit.button("Voltar", _close)
	body.add_child(back)
	_tabs.current_tab = tab


func _page(title_text: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title_text
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	scroll.add_child(v)
	return v


func _slider(parent: Control, text: String, key: String, mn: float, mx: float, step: float, percent: bool) -> void:
	var row := HBoxContainer.new()
	var l := UIKit.label(text, 15)
	l.custom_minimum_size.x = 270
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.value = float(Game.settings[key])
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size.y = 24
	row.add_child(s)
	var val := UIKit.label("", 14, UIKit.GOLD)
	val.custom_minimum_size.x = 56
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val)
	var fmt := func(v: float) -> String: return ("%d%%" % roundi(v * 100)) if percent else ("%.2fx" % v)
	val.text = fmt.call(s.value)
	s.value_changed.connect(func(v: float):
		Game.settings[key] = v
		val.text = fmt.call(v)
		if key != "ui_scale":
			Game.apply_settings()
	)
	s.drag_ended.connect(func(_c):
		Sfx.play(&"click")
		if key == "ui_scale":
			Game.apply_settings()
	)
	parent.add_child(row)


func _check(parent: Control, text: String, key: String) -> void:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = Game.settings[key]
	c.focus_mode = Control.FOCUS_NONE
	c.toggled.connect(func(on: bool):
		Game.settings[key] = on
		Game.apply_settings()
		Sfx.play(&"click")
	)
	parent.add_child(c)


func _option(parent: Control, text: String, key: String, items: Array) -> void:
	var row := HBoxContainer.new()
	var l := UIKit.label(text, 15)
	l.custom_minimum_size.x = 270
	row.add_child(l)
	var o := OptionButton.new()
	o.focus_mode = Control.FOCUS_NONE
	for it in items:
		o.add_item(it)
	o.selected = int(Game.settings[key])
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o.item_selected.connect(func(i: int):
		Game.settings[key] = i
		Game.apply_settings()
		Sfx.play(&"click")
	)
	row.add_child(o)
	parent.add_child(row)


## 7.7: Preset de Qualidade (#14.6) - aplica uma combinação de settings de
## uma vez (Baixo/Médio/Alto) e reconstrói o painel para os controles
## individuais refletirem o novo estado.
func _preset_option(parent: Control) -> void:
	var row := HBoxContainer.new()
	var l := UIKit.label("Preset de Qualidade", 15)
	l.custom_minimum_size.x = 270
	row.add_child(l)
	var o := OptionButton.new()
	o.focus_mode = Control.FOCUS_NONE
	for it in ["Personalizado", "Baixo (desempenho)", "Médio (recomendado)", "Alto (visual)"]:
		o.add_item(it)
	o.selected = 0
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o.item_selected.connect(func(i: int):
		var presets: Dictionary = {
			1: {"shadows": 0, "fsr_mode": 3, "msaa": 0, "glow": false, "particle_amount": 0},
			2: {"shadows": 1, "fsr_mode": 2, "msaa": 1, "glow": true, "particle_amount": 1},
			3: {"shadows": 2, "fsr_mode": 1, "msaa": 2, "glow": true, "particle_amount": 2},
		}
		if not presets.has(i):
			return
		for k: String in presets[i]:
			Game.settings[k] = presets[i][k]
		Game.save_settings()
		Game.apply_settings()
		Sfx.play(&"click")
		var tab := _tabs.current_tab
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_build(tab)
	)
	row.add_child(o)
	parent.add_child(row)


func _reset_button(parent: Control, keys: Array) -> void:
	parent.add_child(UIKit.separator())
	var b := UIKit.button("Restaurar padrões desta aba", func():
		Game.reset_settings_section(keys)
		var tab := _tabs.current_tab
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_build(tab)
	)
	parent.add_child(b)


func _start_rebind(action: String) -> void:
	_waiting_action = action
	_bind_buttons[action].text = "Pressione..."
	Sfx.play(&"click")


func _input(event: InputEvent) -> void:
	if _waiting_action == "" or not event is InputEventKey or not event.pressed:
		return
	var k := (event as InputEventKey).physical_keycode
	if k != KEY_ESCAPE or _waiting_action == "pause":
		Game.rebind(_waiting_action, k)
	_waiting_action = ""
	_refresh_bindings()
	get_viewport().set_input_as_handled()


func _refresh_bindings() -> void:
	for action in _bind_buttons:
		_bind_buttons[action].text = Game.key_name(action)


func _close() -> void:
	Game.save_settings()
	closed.emit()
	queue_free()
