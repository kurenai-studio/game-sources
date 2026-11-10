class_name DialogueBox
extends Control
## UI de diálogo (MECANICAS #7, tarefa 2.2): caixa inferior com retrato animado,
## texto paginado com efeito máquina-de-escrever e botões de escolha.
## Consome `DialogueEngine` por sinais; pausa o mundo enquanto aberta.
## Tokens de texto: {heroi}, {raca}, {classe} são substituídos ao exibir.

signal closed

const TOKENS := ["{heroi}", "{raca}", "{classe}"]
const TYPE_SPEED := 40.0  ## caracteres por segundo

var engine := DialogueEngine.new()
var speaker := ""

var _dim: ColorRect
var _panel: PanelContainer
var _name_label: Label
var _text: RichTextLabel
var _portrait: AnimatedSprite2D
var _choices_box: VBoxContainer
var _continue_btn: Button
var _type_tween: Tween
var _pages: PackedStringArray = PackedStringArray()
var _gui_input_callback: Callable  # Para desconectar depois


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Dim suave por trás - o mundo pausa, a caixa respira
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.0)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	var tw := create_tween()
	tw.tween_property(_dim, "color:a", 0.45, 0.25)

	# Caixa inferior centralizada
	_panel = PanelContainer.new()
	var vs := get_viewport_rect().size
	var w := minf(vs.x * 0.72, 880.0)
	_panel.custom_minimum_size = Vector2(w, 0)
	_panel.add_theme_stylebox_override("panel", UIKit.box(UIKit.PANEL_BG, UIKit.PANEL_BORDER, 1, UIKit.RADIUS_LG))
	add_child(_panel)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	_panel.add_child(h)

	# Retrato: quadro escuro com o sprite idle do falante (silhueta padrão)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIKit.box(Color(0.05, 0.04, 0.05, 0.9), UIKit.GOLD_DIM, 1, UIKit.RADIUS_SM))
	var pv := PanelContainer.new()
	pv.custom_minimum_size = Vector2(96, 96)
	frame.add_child(pv)
	_portrait = AnimatedSprite2D.new()
	_portrait.sprite_frames = DB.frames("k:121")  # silhueta padrão (Cinzento)
	_portrait.scale = Vector2(2.4, 2.4)
	_portrait.position = Vector2(48, 52)
	_portrait.play("idle")
	pv.add_child(_portrait)
	h.add_child(frame)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	h.add_child(v)
	_name_label = UIKit.label("", 20, UIKit.GOLD, true)
	v.add_child(_name_label)
	_text = UIKit.rich("", false)
	_text.custom_minimum_size = Vector2(0, 84)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_text)
	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 6)
	v.add_child(_choices_box)
	_continue_btn = Button.new()
	_continue_btn.text = "Continuar ▶"
	_continue_btn.focus_mode = Control.FOCUS_NONE
	_continue_btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_btn.pressed.connect(_advance)
	v.add_child(_continue_btn)

	_panel.position = Vector2((vs.x - w) * 0.5, vs.y - 210)
	engine.page_shown.connect(_show_page)
	engine.choices_shown.connect(_show_choices)
	engine.dialogue_ended.connect(_close)
	_gui_input_callback = func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_advance()
	gui_input.connect(_gui_input_callback)


func open(data: DialogueData, speaker_name: String = "") -> void:
	speaker = speaker_name if speaker_name != "" else data.display_name
	if data.portrait != "":
		_portrait.sprite_frames = DB.frames(data.portrait)
		_portrait.play("idle")
	_name_label.text = speaker
	get_tree().paused = true
	UIKit.pop_in(_panel)
	Sfx.play(&"ui_open", -8.0)
	# 7.5: música abaixa -6dB durante o diálogo (MECANICAS #15.1)
	Audio.duck_music(true)
	engine.start(data)


func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_advance()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			engine.stop()
			get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ PAGINAS/ESCOLHAS

func _show_page(text: String, portrait: String) -> void:
	_choices_box.visible = false
	for c in _choices_box.get_children():
		c.queue_free()
	_continue_btn.visible = true
	if portrait != "" and _portrait.sprite_frames != DB.frames(portrait):
		_portrait.sprite_frames = DB.frames(portrait)
		_portrait.play("idle")
	_text.text = _substitute(text)
	# Efeito máquina-de-escrever; primeiro clique conclui o texto
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	_text.visible_characters = -1
	var n := _text.get_total_character_count()
	if n > 0:
		_text.visible_characters = 0
		_type_tween = create_tween()
		_type_tween.tween_property(_text, "visible_characters", n, n / TYPE_SPEED)\
			.set_trans(Tween.TRANS_LINEAR)


func _show_choices(choices: Array[DialogueChoice]) -> void:
	_continue_btn.visible = false
	_choices_box.visible = true
	for c in _choices_box.get_children():
		c.queue_free()
	for i in choices.size():
		var ch: DialogueChoice = choices[i]
		var b := UIKit.button(ch.text, func(): engine.choose(i))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_choices_box.add_child(b)


func _advance() -> void:
	# Digitando: o primeiro clique conclui o texto
	if _text.visible_characters >= 0 and _text.visible_characters < _text.get_total_character_count():
		if _type_tween and _type_tween.is_valid():
			_type_tween.kill()
		_text.visible_characters = -1
		return
	engine.advance()


func _close() -> void:
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	
	# Desconectar signals para evitar memory leak
	if _continue_btn.pressed.is_connected(_advance):
		_continue_btn.pressed.disconnect(_advance)
	if engine.page_shown.is_connected(_show_page):
		engine.page_shown.disconnect(_show_page)
	if engine.choices_shown.is_connected(_show_choices):
		engine.choices_shown.disconnect(_show_choices)
	if engine.dialogue_ended.is_connected(_close):
		engine.dialogue_ended.disconnect(_close)
	if gui_input.is_connected(_gui_input_callback):
		gui_input.disconnect(_gui_input_callback)
	
	get_tree().paused = false
	Sfx.play(&"ui_close", -10.0)
	# 7.5: diálogo acabou - música volta ao volume (MECANICAS #15.1)
	Audio.duck_music(false)
	var tw := create_tween()
	tw.tween_property(_dim, "color:a", 0.0, 0.18)
	UIKit.pop_out(_panel, func():
		closed.emit()
		queue_free()
	)


func _substitute(text: String) -> String:
	if Game.hero == null:
		return text
	return text.replace("{heroi}", Game.hero.hero_name)\
		.replace("{raca}", Game.hero.race.display_name)\
		.replace("{classe}", Game.hero.cls.display_name)
