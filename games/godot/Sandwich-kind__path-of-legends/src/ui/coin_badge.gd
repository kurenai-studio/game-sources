class_name CoinBadge
extends Control
# Монеты в углу экрана: золотая монетка и число.

var _label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(190, 56)
	var bg := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.12, 0.09, 0.07, 0.85)
	st.set_corner_radius_all(28)
	st.border_color = Color(0.95, 0.75, 0.3, 0.8)
	st.set_border_width_all(3)
	bg.add_theme_stylebox_override("panel", st)
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var coin := Node2D.new()
	coin.position = Vector2(30, 28)
	add_child(coin)
	var outer := Polygon2D.new()
	outer.polygon = Util.circle(17.0, 20)
	outer.color = Color(0.85, 0.6, 0.15)
	coin.add_child(outer)
	var inner := Polygon2D.new()
	inner.polygon = Util.circle(12.0, 20)
	inner.color = Color(1.0, 0.82, 0.3)
	coin.add_child(inner)
	var mark := Label.new()
	mark.text = "G"
	mark.position = Vector2(-10, -15)
	mark.size = Vector2(20, 30)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.add_theme_font_size_override("font_size", 18)
	mark.add_theme_color_override("font_color", Color(0.6, 0.4, 0.1))
	mark.add_theme_constant_override("outline_size", 0)
	coin.add_child(mark)
	_label = Label.new()
	_label.position = Vector2(56, 6)
	_label.size = Vector2(124, 44)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	add_child(_label)
	refresh()

func refresh() -> void:
	_label.text = str(Save.gold())

# Положить в правый верхний угол слоя
static func corner(layer: Node) -> CoinBadge:
	var c := CoinBadge.new()
	layer.add_child(c)
	c.position = Vector2(Config.screen(layer).x - 210, 20)
	return c
