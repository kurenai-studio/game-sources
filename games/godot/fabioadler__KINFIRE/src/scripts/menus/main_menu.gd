extends Control
## Menu principal: logo do Kinfire, névoa, brasas, desfile de heróis animados e telas de
## Opções, Como Jogar e Créditos.

const LOGO := preload("res://assets/kinfire_logo.png")
const FOG_SHADER := preload("res://shaders/fog.gdshader")
const AUTHORS := [
	{"name": "MichaelDCA", "url": "https://github.com/MichaelDouglasCA"},
	{"name": "fabioadler", "url": "https://github.com/fabioadler"},
]
const PARADE_HEROES := ["knight_m", "elf_f", "dwarf_m", "wizzard_f", "lizard_m", "knight_f", "elf_m", "dwarf_f", "wizzard_m", "lizard_f"]
const PARADE_MONSTERS := ["goblin", "skelet", "orc_warrior", "imp", "chort", "tiny_zombie", "masked_orc", "wogol"]

var _buttons: VBoxContainer
var _embers: CPUParticles2D
var _logo_embers: CPUParticles2D
var _logo: TextureRect
var _fog: ColorRect
var _strip: TextureRect
var _parade: Array[Dictionary] = []
var _parade_root: Control
var _byline: RichTextLabel
var _summary_panel: PanelContainer
var _t := 0.0
var _spawn_t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Game.play_music("res://assets/audio/music_menu.ogg")

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.012, 0.01)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Faixa de masmorra no rodapé (parede + chão)
	_strip = TextureRect.new()
	_strip.texture = _dungeon_strip()
	_strip.stretch_mode = TextureRect.STRETCH_TILE
	_strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_strip.modulate = Color(0.45, 0.38, 0.38)
	_strip.scale = Vector2(3, 3)
	add_child(_strip)
	_parade_root = Control.new()
	_parade_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_parade_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_parade_root)

	_fog = ColorRect.new()
	_fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fm := ShaderMaterial.new()
	fm.shader = FOG_SHADER
	_fog.material = fm
	add_child(_fog)

	_embers = CPUParticles2D.new()
	_embers.amount = 110
	_embers.lifetime = 6.0
	_embers.preprocess = 6.0
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.direction = Vector2.UP
	_embers.spread = 25.0
	_embers.gravity = Vector2(0, -12)
	_embers.initial_velocity_min = 20.0
	_embers.initial_velocity_max = 60.0
	_embers.scale_amount_min = 1.5
	_embers.scale_amount_max = 4.0
	_embers.color_ramp = _ember_ramp()
	add_child(_embers)

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = _vignette_shader()
	vignette.material = vm
	add_child(vignette)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -120
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 2)
	add_child(center)

	_logo = TextureRect.new()
	_logo.texture = LOGO
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.custom_minimum_size = Vector2(0, 300)
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var lm := CanvasItemMaterial.new()
	lm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_logo.material = lm
	center.add_child(_logo)
	# 6.3: brasas que sobem do próprio logo - o Kinfire que ainda arde
	_logo_embers = CPUParticles2D.new()
	_logo_embers.amount = 24
	_logo_embers.lifetime = 2.2
	_logo_embers.preprocess = 2.2
	_logo_embers.direction = Vector2.UP
	_logo_embers.spread = 35.0
	_logo_embers.gravity = Vector2(0, -30)
	_logo_embers.initial_velocity_min = 12.0
	_logo_embers.initial_velocity_max = 36.0
	_logo_embers.scale_amount_min = 1.0
	_logo_embers.scale_amount_max = 2.5
	_logo_embers.color_ramp = _ember_ramp()
	_logo.add_child(_logo_embers)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(hb)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 8)
	_buttons.custom_minimum_size = Vector2(320, 0)
	hb.add_child(_buttons)

	var summary := Game.save_summary()
	var cont := _menu_button("Continuar", "S_Buff09", Game.continue_game)
	cont.disabled = summary == ""
	cont.tooltip_text = summary
	_buttons.add_child(cont)
	_buttons.add_child(_menu_button("Novo Jogo", "S_Sword01", _on_new_game))
	_buttons.add_child(_menu_button("Opções", "I_Key01", _on_options))
	_buttons.add_child(_menu_button("Como Jogar", "I_Book", _on_help))
	_buttons.add_child(_menu_button("Créditos", "I_Scroll", _on_credits))
	_buttons.add_child(_menu_button("Sair", "I_Torch01", func(): get_tree().quit()))

	if summary != "":
		_summary_panel = _build_summary()
		add_child(_summary_panel)

	_byline = UIKit.rich("", true)
	_byline.mouse_filter = Control.MOUSE_FILTER_STOP
	_byline.autowrap_mode = TextServer.AUTOWRAP_OFF
	var links: Array = []
	for a in AUTHORS:
		links.append("[url=%s][color=#e8c060]%s[/color][/url]" % [a.url, a.name])
	_byline.text = "[color=#8a7a6a]Criado por[/color] %s [color=#8a7a6a]e[/color] %s   [color=#5a4f45]-  v%s - Godot 4[/color]" % [links[0], links[1], Game.VERSION]
	_byline.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
	add_child(_byline)

	get_viewport().size_changed.connect(_layout)
	_layout()
	for i in 4:
		_spawn_walker(randf_range(0.0, 1.0))
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)


func _menu_button(text: String, icon_name: String, cb: Callable) -> Button:
	var b := UIKit.button(text, cb, 320)
	b.icon = DB.icon(icon_name)
	b.add_theme_constant_override("icon_max_width", 26)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size.y = 42
	b.mouse_entered.connect(func():
		var tw := b.create_tween()
		tw.tween_property(b, "position:x", 10.0, 0.08)
	)
	b.mouse_exited.connect(func():
		var tw := b.create_tween()
		tw.tween_property(b, "position:x", 0.0, 0.12)
	)
	return b


func _build_summary() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.box(Color(0.05, 0.035, 0.03, 0.85), UIKit.GOLD_DIM, 1, 6))
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(UIKit.label("Ultimo herói", 14, UIKit.GOLD, true))
	var f := FileAccess.open(Game.SAVE_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text()) if f else null
	if data is Dictionary:
		var h: Dictionary = data.get("hero", {})
		var r := DB.get_race(StringName(h.get("race", "")))
		var c := DB.get_class_data(StringName(h.get("class", "")))
		var pv := SpritePreview.new()
		pv.custom_minimum_size = Vector2(150, 70)
		pv.set_sprite(r.sprite_f if h.get("sex", "m") == "f" else r.sprite_m, Color.html(h.get("tint", "ffffffff")) * r.tint)
		v.add_child(pv)
		var l := UIKit.rich("[center][color=#e8c060]%s[/color]\n%s %s - nv %d\n[color=#999999]Profundidade %d[/color][/center]" % [
			h.get("name", "?"), r.display_name, c.display_name, int(h.get("level", 1)), int(data.get("depth", 1))])
		l.custom_minimum_size.x = 170
		v.add_child(l)
	return p


func _dungeon_strip() -> Texture2D:
	var img := Image.create(64, 48, false, Image.FORMAT_RGBA8)
	var sheet := DB.DT2_SHEET.get_image()
	if sheet.is_compressed():
		sheet.decompress()
	sheet.convert(Image.FORMAT_RGBA8)
	for x in 4:
		var wall: String = "wall_mid" if randf() > 0.3 else ["wall_banner_red", "wall_hole_1", "wall_banner_blue", "wall_goo"].pick_random()
		img.blit_rect(sheet, DB.dt2_rect("wall_top_mid"), Vector2i(x * 16, 0))
		img.blit_rect(sheet, DB.dt2_rect(wall), Vector2i(x * 16, 16))
		img.blit_rect(sheet, DB.dt2_rect("floor_1" if randf() > 0.3 else "floor_%d" % randi_range(2, 8)), Vector2i(x * 16, 32))
	return ImageTexture.create_from_image(img)


func _vignette_shader() -> Shader:
	var s := Shader.new()
	s.code = """shader_type canvas_item;
void fragment() {
	float d = distance(UV, vec2(0.5));
	COLOR = vec4(0.0, 0.0, 0.0, smoothstep(0.35, 0.85, d) * 0.85);
}"""
	return s


## Gradiente das brasas: nasce laranja translúcido, acende no pico e
## morre vermelho apagado - a mesma rampa do rodapé e do logo (#9.1:
## "brasa viva" do tema dark fantasy premium).
func _ember_ramp() -> Gradient:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 0.6, 0.15, 0))
	ramp.add_point(0.2, Color(1, 0.5, 0.1, 0.9))
	ramp.set_color(ramp.get_point_count() - 1, Color(0.8, 0.1, 0, 0))
	return ramp


func _layout() -> void:
	var vs := get_viewport_rect().size
	_embers.position = Vector2(vs.x * 0.5, vs.y + 10)
	_embers.emission_rect_extents = Vector2(vs.x * 0.5, 10)
	_logo.custom_minimum_size.y = clampf(vs.y * 0.4, 200, 460)
	_place_logo_embers.call_deferred()
	_strip.size = Vector2(vs.x / 3.0 + 16, 48)
	_strip.position = Vector2(0, vs.y - 48 * 3)
	_byline.reset_size()
	_byline.position = Vector2(14, vs.y - 30)
	if _summary_panel:
		_summary_panel.reset_size()
		_summary_panel.position = Vector2(vs.x - _summary_panel.size.x - 16, vs.y * 0.42)


## Emissor de brasas no centro do logo (deferred: espera os containers
## reposicionarem o TextureRect antes de ler o seu size)
func _place_logo_embers() -> void:
	if _logo_embers and _logo:
		_logo_embers.position = _logo.size * 0.5


func _spawn_walker(progress := 0.0) -> void:
	var vs := get_viewport_rect().size
	var is_monster := randf() < 0.45
	var base: String = PARADE_MONSTERS.pick_random() if is_monster else PARADE_HEROES.pick_random()
	var right := randf() < 0.5
	var pv := SpritePreview.new()
	if not DB:
		return
	var fs := DB.frame_size(base)
	pv.size = Vector2(fs.x, fs.y) * 3.0
	pv.set_sprite(base, Color(0.7, 0.62, 0.6))
	pv.animation = "run"
	pv.flip = not right
	var y := vs.y - 48 * 3 + 30 * 3 - pv.size.y + randf_range(0, 18)
	var x := -pv.size.x if right else vs.x
	pv.position = Vector2(lerpf(x, vs.x - x, progress), y)
	_parade_root.add_child(pv)
	_parade.append({"node": pv, "speed": randf_range(50, 90) * (1 if right else -1)})


func _process(delta: float) -> void:
	_t += delta
	var k := 1.0 + sin(_t * 1.6) * 0.06
	_logo.modulate = Color(k, k * 0.98, k * 0.95)
	_logo.position.y = sin(_t * 0.9) * 4.0
	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = randf_range(1.5, 3.5)
		_spawn_walker()
	var vs := get_viewport_rect().size
	for w in _parade.duplicate():
		var n: SpritePreview = w.node
		n.position.x += w.speed * delta
		if n.position.x > vs.x + 80 or n.position.x < -120:
			n.queue_free()
			_parade.erase(w)


func _on_new_game() -> void:
	# Todo novo jogo começa no prólogo: o aldeão e o espelho (REGRAS #13)
	if Game.has_save():
		_confirm("Iniciar um novo jogo apagará o personagem salvo. Continuar?", func(): Game.new_prologue())
	else:
		Game.new_prologue()


func _on_options() -> void:
	var o := OptionsPanel.new()
	var c := _modal()
	c.add_child(o)
	o.closed.connect(c.get_parent().queue_free)


func _on_help() -> void:
	var c := _modal()
	var w := UIKit.window_panel("Como Jogar", Vector2(640, 0), c.get_parent().queue_free)
	c.add_child(w.panel)
	var r := UIKit.rich("""[font_size=17][color=#e8c060]Controles[/color][/font_size]
[table=2][cell][color=#aaaaaa]Mover   [/color][/cell][cell]WASD ou clique esquerdo no chão[/cell]
[cell][color=#aaaaaa]Atacar   [/color][/cell][cell]Clique esquerdo no inimigo (segure para continuar)[/cell]
[cell][color=#aaaaaa]Atacar parado   [/color][/cell][cell]Shift + clique esquerdo[/cell]
[cell][color=#aaaaaa]Habilidades   [/color][/cell][cell]Botão direito, 1, 2, 3, 4 e R (racial)[/cell]
[cell][color=#aaaaaa]Esquiva   [/color][/cell][cell]Espaço - cancela a recuperação do ataque[/cell]
[cell][color=#aaaaaa]Poção   [/color][/cell][cell]Q (recarga de 20s)[/cell]
[cell][color=#aaaaaa]Painéis   [/color][/cell][cell]I inventário - P personagem - K habilidades - B árvore - J missões - Esc menu[/cell]
[cell][color=#aaaaaa]Itens no chão   [/color][/cell][cell]Clique no nome para pegar; Alt mostra todos[/cell][/table]

[font_size=17][color=#e8c060]Dicas[/color][/font_size]
- Cada classe usa um recurso diferente: Fúria enche ao bater e apanhar, Energia volta rápido se você parar de gastar, Concentração só regenera parado, o Bruxo paga com a própria vida.
- Raças têm passivas: o Meio-Orc sobrevive a um golpe fatal, o Elfo da Floresta esquiva automaticamente, o Draconato tem um sopro de fogo (R).
- Monstros com contorno [color=#6090ff]azul[/color] são elites e sempre deixam itens. A cada 3 profundidades, um chefe guarda a escada.
- O mundo é aberto e infinito: quanto mais longe do acampamento, mais fortes os inimigos. Acenda fogueiras para viajar rápido e renascer nelas. Entradas de masmorra levam a andares com chefes.
- Globos vermelhos no chão curam. Santuários dão bônus de 30s. Cuidado com baús: alguns são Mímicos!
- No inventário, Shift + clique equipa/desequipa e Ctrl + clique vende. Itens em vermelho não podem ser usados pela sua classe.""")
	r.custom_minimum_size = Vector2(620, 0)
	w.body.add_child(r)
	w.body.add_child(UIKit.button("Fechar", c.get_parent().queue_free))


func _on_credits() -> void:
	var c := _modal()
	var w := UIKit.window_panel("Créditos", Vector2(600, 0), c.get_parent().queue_free)
	c.add_child(w.panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	w.body.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	scroll.add_child(v)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 380
	v.add_child(spacer)
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 160)
	var lm := CanvasItemMaterial.new()
	lm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	logo.material = lm
	v.add_child(logo)
	var dev := ""
	for a in AUTHORS:
		dev += "[font_size=24][url=%s][color=#ffd27a]%s[/color][/url][/font_size]\n[font_size=13][url=%s][color=#8a9bd0]%s[/color][/url][/font_size]\n\n" % [a.url, a.name, a.url, a.url.replace("https://", "")]
	var r := UIKit.rich("""[center][font_size=15][color=#999999]Um RPG de ação top-down com raças e classes de D&D
e combate inspirado em Diablo.[/color][/font_size]

[font_size=20][color=#e8c060]- Criação e Desenvolvimento -[/color][/font_size]

%s[font_size=20][color=#e8c060]- Arte -[/color][/font_size]
Personagens, monstros e masmorra: [color=#ffffff]0x72[/color] - DungeonTileset II (CC0)
Icones de itens e habilidades: [color=#ffffff]Henrique Lazarini (7Soul1)[/color] - 496 RPG Icons (CC0)
Mundo aberto, tiles e UI: [color=#ffffff]Kenney[/color] - Roguelike RPG Pack, Tiny Dungeon, UI Pack RPG (CC0)

[font_size=20][color=#e8c060]- Audio -[/color][/font_size]
Efeitos: [color=#ffffff]Kenney[/color] - RPG Audio, Impact Sounds (CC0)
"Cave Theme" - OpenGameArt.org (CC0)
"Dark Ambience Loop" - [color=#ffffff]Iwan Gabovitch (qubodup)[/color] (CC-BY 3.0)

[font_size=20][color=#e8c060]- Fontes -[/color][/font_size]
Cinzel - Natanael Gama (SIL OFL)
Alegreya - Huerta Tipográfica (SIL OFL)

[font_size=20][color=#e8c060]- Motor -[/color][/font_size]
[url=https://godotengine.org][color=#8a9bd0]Godot Engine[/color][/url]

[font_size=15][color=#999999]Obrigado por jogar![/color][/font_size][/center]""" % dev)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	r.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
	v.add_child(r)
	var end_spacer := Control.new()
	end_spacer.custom_minimum_size.y = 200
	v.add_child(end_spacer)
	# Rolagem automática estilo filme (o mouse/roda interrompe)
	var state: Dictionary = {"auto": true, "pos": 0.0}
	scroll.gui_input.connect(func(e):
		if e is InputEventMouseButton:
			state.auto = false
	)
	var timer := Timer.new()
	timer.wait_time = 0.016
	timer.autostart = true
	timer.timeout.connect(func():
		if state.auto:
			state.pos += 0.7
			scroll.scroll_vertical = int(state.pos)
	)
	scroll.add_child(timer)
	w.body.add_child(UIKit.button("Fechar", c.get_parent().queue_free))


func _confirm(text: String, on_yes: Callable) -> void:
	var c := _modal()
	var w := UIKit.window_panel("Confirmar", Vector2(440, 0))
	c.add_child(w.panel)
	var l := UIKit.label(text, 17)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.custom_minimum_size = Vector2(400, 0)
	w.body.add_child(l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	w.body.add_child(row)
	row.add_child(UIKit.button("Sim", func():
		c.get_parent().queue_free()
		on_yes.call()
	, 120))
	row.add_child(UIKit.button("Não", c.get_parent().queue_free, 120))


## Cria um fundo escuro + CenterContainer e retorna o container
func _modal() -> CenterContainer:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.75)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_child(c)
	return c


func _exit_tree() -> void:
	"""Desconectar signals para evitar memory leak"""
	if get_viewport():
		get_viewport().size_changed.disconnect(_layout)
