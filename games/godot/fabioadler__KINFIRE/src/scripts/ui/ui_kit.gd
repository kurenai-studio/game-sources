class_name UIKit
extends RefCounted
## Design tokens e helpers de UI - linguagem "dark fantasy premium".
## Spec canônica: docs/MECANICAS.md #9. Todo painel novo nasce a partir daqui.

const FONT_TITLE := preload("res://assets/fonts/Cinzel.ttf")
const FONT_BODY := preload("res://assets/fonts/Alegreya.ttf")

# ------------------------------------------------------------------ TOKENS
# Núcleo (#9.1)
const BG_BASE := Color("0B0908")                    ## fundo do jogo/menus
const PANEL_BG := Color(0.086, 0.067, 0.051, 0.86)  ## vidro escuro (rgba 22,17,13 / 0.86)
const PANEL_BORDER := Color(0.94, 0.75, 0.38, 0.25) ## contorno dourado sutil 1px
const ACCENT_GOLD := Color("F0C060")                ## destaques, títulos, seleção
const ACCENT_EMBER := Color("E06C2A")               ## brasa: XP, fogo, aviso
const TEXT_MAIN := Color("E8E2D6")                  ## texto principal (bege claro)
const TEXT_DIM := Color("9A917F")                  ## texto secundário
const HP_RED := Color(0.75, 0.12, 0.08)
const MANA_BLUE := Color(0.35, 0.55, 0.95)
const XP_GOLD := Color(0.94, 0.75, 0.38)

# Aliases legados (nomes usados pelo jogo base - valores atualizados aos tokens)
const GOLD := ACCENT_GOLD
const GOLD_DIM := Color(0.5, 0.38, 0.2)
const TEXT := TEXT_MAIN
const BG := Color(0.043, 0.033, 0.027, 0.94)
const BG_LIGHT := Color(0.12, 0.09, 0.07, 0.94)
const RED := HP_RED

# Raridades (#9.1) - cores + formas p/ daltônismo
const RARITY_COLORS := [
	Color("B8B8B8"),  # Comum     - círculo
	Color("5B8DFF"),  # Mágico    - losango
	Color("C65CFF"),  # Raro      - triângulo
	Color("FF9A3C"),  # Lendário  - estrela
]
const RARITY_SHAPES := ["●", "◆", "▲", "★"]

# Geometria (#9.1)
const RADIUS_SM := 8   ## botões
const RADIUS_LG := 12  ## painéis
const SPACING := [4, 8, 12, 16, 24]
const SHADOW_COLOR := Color(0, 0, 0, 0.5)  ## sombra 0 4px 16px

# Tempos de micro-interação (#9.3)
const TWEEN_FAST := 0.18  ## abrir/fechar painéis (back-ease)


# ------------------------------------------------------------------ TEMA
static func install_theme() -> void:
	var t := ThemeDB.get_default_theme()
	ThemeDB.fallback_font = FONT_BODY
	t.default_font = FONT_BODY
	t.default_font_size = 17

	# Painéis: vidro escuro, borda dourada 1px, sombra de elevação
	var panel := box(PANEL_BG, PANEL_BORDER, 1, RADIUS_LG)
	panel.shadow_size = 16
	panel.shadow_color = SHADOW_COLOR
	panel.shadow_offset = Vector2(0, 4)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)

	# Botões: estados completos idle/hover/press/focus/disabled (#9.4)
	var normal := box(Color(0.16, 0.08, 0.06, 0.9), PANEL_BORDER, 1, RADIUS_SM)
	var hover := box(Color(0.30, 0.12, 0.07, 0.95), ACCENT_GOLD, 1, RADIUS_SM)
	hover.shadow_size = 12
	hover.shadow_color = Color(ACCENT_GOLD.r, ACCENT_GOLD.g, ACCENT_GOLD.b, 0.25)  # glow no hover
	var pressed := box(Color(0.10, 0.05, 0.04, 0.95), ACCENT_GOLD, 1, RADIUS_SM)
	var disabled := box(Color(0.1, 0.09, 0.08, 0.9), Color(0.25, 0.22, 0.2, 0.6), 1, RADIUS_SM)
	for st in [normal, hover, pressed, disabled]:
		st.content_margin_left = 14
		st.content_margin_right = 14
		st.content_margin_top = 6
		st.content_margin_bottom = 6
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("hover_pressed", "Button", hover)
	# Foco de teclado: anel dourado 2px (#9.3)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = ACCENT_GOLD
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(RADIUS_SM)
	focus.content_margin_left = 12
	focus.content_margin_right = 12
	focus.content_margin_top = 4
	focus.content_margin_bottom = 4
	t.set_stylebox("focus", "Button", focus)
	t.set_font("font", "Button", FONT_TITLE)
	t.set_font_size("font_size", "Button", 17)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 0.92, 0.7))
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.37, 0.33))
	t.set_color("font_focus_color", "Button", Color(1, 0.92, 0.7))

	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font("normal_font", "RichTextLabel", FONT_BODY)
	t.set_font("bold_font", "RichTextLabel", FONT_TITLE)
	t.set_font_size("normal_font_size", "RichTextLabel", 16)
	t.set_font_size("bold_font_size", "RichTextLabel", 17)

	var le := box(Color(0.03, 0.02, 0.02), PANEL_BORDER, 1, RADIUS_SM)
	le.content_margin_left = 10
	t.set_stylebox("normal", "LineEdit", le)
	var le_focus := box(Color(0.03, 0.02, 0.02), ACCENT_GOLD, 2, RADIUS_SM)
	le_focus.content_margin_left = 10
	t.set_stylebox("focus", "LineEdit", le_focus)
	t.set_font("font", "LineEdit", FONT_TITLE)
	t.set_color("font_color", "LineEdit", TEXT)

	t.set_stylebox("slider", "HSlider", box(Color(0.03, 0.02, 0.02), PANEL_BORDER, 1, RADIUS_SM))
	t.set_stylebox("grabber_area", "HSlider", box(ACCENT_EMBER, ACCENT_EMBER, 0, RADIUS_SM))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(Color(0.95, 0.45, 0.18), Color(0.95, 0.45, 0.18), 0, RADIUS_SM))

	var tt := box(Color(0.03, 0.02, 0.02, 0.97), PANEL_BORDER, 1, RADIUS_SM)
	tt.shadow_size = 10
	tt.shadow_color = SHADOW_COLOR
	t.set_stylebox("panel", "TooltipPanel", tt)
	t.set_color("font_color", "TooltipLabel", TEXT)

	var tab_sel := box(Color(0.25, 0.1, 0.06, 0.95), ACCENT_GOLD, 1, RADIUS_SM)
	var tab_un := box(Color(0.1, 0.06, 0.05, 0.9), PANEL_BORDER, 1, RADIUS_SM)
	for st in [tab_sel, tab_un]:
		st.content_margin_left = 12
		st.content_margin_right = 12
		st.content_margin_top = 4
		st.content_margin_bottom = 4
	t.set_stylebox("tab_selected", "TabContainer", tab_sel)
	t.set_stylebox("tab_unselected", "TabContainer", tab_un)
	t.set_stylebox("tab_hovered", "TabContainer", tab_sel)
	t.set_stylebox("panel", "TabContainer", box(BG_LIGHT, PANEL_BORDER, 1, RADIUS_LG))
	t.set_font("font", "TabContainer", FONT_TITLE)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.02, 0.02, 0.5)
	t.set_stylebox("scroll", "VScrollBar", sb)
	t.set_stylebox("grabber", "VScrollBar", box(GOLD_DIM, GOLD_DIM, 0, RADIUS_SM))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(GOLD, GOLD, 0, RADIUS_SM))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(GOLD, GOLD, 0, RADIUS_SM))


# ------------------------------------------------------------------ HELPERS
static func box(bg: Color, border: Color, border_w: int = 1, radius: int = RADIUS_LG) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func label(text: String, size: int = 17, color: Color = TEXT, title_font: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if title_font:
		l.add_theme_font_override("font", FONT_TITLE)
	return l


static func title(text: String, size: int = 26) -> Label:
	var l := label(text, size, GOLD, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	return l


static func button(text: String, callback: Callable, min_w: int = 0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 40)
	b.pressed.connect(func(): Sfx.play(&"click", -6.0))
	b.pressed.connect(callback)
	b.mouse_entered.connect(func():
		if not b.disabled:
			Sfx.play(&"cloth", -18.0)
			_lift(b, 1.04)
	)
	b.mouse_exited.connect(func(): _lift(b, 1.0))
	b.button_down.connect(func(): _lift(b, 0.96))
	b.button_up.connect(func(): _lift(b, 1.04 if b.is_hovered() else 1.0))
	return b


## Micro-interação de escala suave (hover lift / press scale) - #9.3
static func _lift(c: Control, target_scale: float, time: float = 0.12) -> void:
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(target_scale, target_scale), time)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Abre um painel com tween pop (0.18s back-ease) e fade - #9.3
static func pop_in(panel: Control, final_scale: Vector2 = Vector2.ONE) -> Tween:
	panel.scale = final_scale * 0.92
	panel.modulate.a = 0.0
	var tw := panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale", final_scale, TWEEN_FAST)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, TWEEN_FAST * 0.8)
	return tw


## Fecha um painel com fade + leve redução; on_done ao terminar.
## Retorna o Tween para o chamador poder interrompê-lo (6.5: abrir no
## meio de um fechamento deve cancelar o callback de esconder).
static func pop_out(panel: Control, on_done: Callable = Callable()) -> Tween:
	var tw := panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 0.0, TWEEN_FAST * 0.8)
	tw.tween_property(panel, "scale", Vector2(0.94, 0.94), TWEEN_FAST)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if on_done.is_valid():
		tw.chain().tween_callback(on_done)
	return tw


static func rich(text: String = "", fit: bool = true) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = fit
	r.scroll_active = not fit
	r.text = text
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func separator() -> Control:
	var c := ColorRect.new()
	c.color = PANEL_BORDER
	c.custom_minimum_size = Vector2(0, 1)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func icon(icon_name: String, px: int = 32) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = DB.icon(icon_name)
	tr.custom_minimum_size = Vector2(px, px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## Painel modal centralizado com título e botão de fechar
static func window_panel(title_text: String, size: Vector2, on_close: Callable = Callable()) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var header := HBoxContainer.new()
	v.add_child(header)
	var t := title(title_text, 24)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(t)
	if on_close.is_valid():
		var x := Button.new()
		x.text = "✕"
		x.custom_minimum_size = Vector2(34, 34)
		x.pressed.connect(on_close)
		header.add_child(x)
	v.add_child(separator())
	return {"panel": panel, "body": v}
