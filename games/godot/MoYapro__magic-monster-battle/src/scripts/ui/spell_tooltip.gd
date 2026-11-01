class_name SpellTooltip extends CanvasLayer

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const TOOLTIP_DELAY := 1.0
const EFFECT_TAGS: Array = ["fire", "water", "frost", "poison", "shield", "amplify", "aoe"]

var _panel: PanelContainer = null
var _name_label: Label = null
var _desc_label: Label = null
var _stats_label: Label = null
var _effects_label: Label = null

var _hover_spell: SpellData = null
var _timer: float = 0.0
var _cursor_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	layer = 15


func _ready() -> void:
	_build()


func _build() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.COLOR_TOOLTIP_BG
	style.border_color = Palette.COLOR_BORDER
	style.set_border_width_all(1)
	style.set_content_margin_all(10)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(230, 0)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.modulate = Palette.COLOR_TEXT_BRIGHT
	vbox.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 11)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.modulate = Palette.COLOR_SECTION
	vbox.add_child(_desc_label)

	vbox.add_child(HSeparator.new())

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 11)
	_stats_label.modulate = Palette.COLOR_TEXT_BRIGHT
	vbox.add_child(_stats_label)

	_effects_label = Label.new()
	_effects_label.add_theme_font_size_override("font_size", 11)
	_effects_label.modulate = Palette.COLOR_SECTION
	vbox.add_child(_effects_label)


func _process(delta: float) -> void:
	if _hover_spell == null or _panel.visible:
		return
	_timer += delta
	if _timer >= TOOLTIP_DELAY:
		_show(_hover_spell, _cursor_pos)


# Call on every mouse-motion event. Pass null when not hovering over a spell.
func notify_hover(pos: Vector2, spell: SpellData) -> void:
	_cursor_pos = pos
	if spell != _hover_spell:
		_hover_spell = spell
		_timer = 0.0
		_panel.visible = false


func _show(spell: SpellData, pos: Vector2) -> void:
	_name_label.text = spell.display_name
	_desc_label.text = spell.description
	_desc_label.visible = not spell.description.is_empty()
	_stats_label.text = "Damage: %d     Mana: %d" % [spell.damage, spell.mana_cost]
	var effects: Array = spell.tags.filter(func(t: String) -> bool: return t in EFFECT_TAGS)
	if effects.is_empty():
		_effects_label.visible = false
	else:
		_effects_label.text = "Effects: " + ", ".join(
				effects.map(func(t: String) -> String: return t.capitalize()))
		_effects_label.visible = true
	var tp := pos + Vector2(18.0, 18.0)
	tp.x = clampf(tp.x, 0.0, SCREEN_W - 250.0)
	tp.y = clampf(tp.y, 0.0, SCREEN_H - 160.0)
	_panel.position = tp
	_panel.visible = true
