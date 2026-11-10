class_name MainMenu
extends CanvasLayer
# Главное меню: пиксельная заставка (поле, река, лес, гора) и выбор режима.

signal mode_chosen(mode: String)   # "story", "duel", "arena", "shop", "inventory", "bestiary"

var _clouds: Array = []
var _scale := 4.0
var _vs := Vector2.ZERO
var _coins: CoinBadge

func _ready() -> void:
	_vs = Config.screen(self)
	var img := PixelArt.title_landscape()
	# картинка заполняет весь экран, лишнее обрезается
	_scale = maxf(_vs.x / img.get_width(), _vs.y / img.get_height())
	var bg := PixelArt.make_sprite(img, _scale)
	bg.position = (_vs - Vector2(img.get_size()) * _scale) / 2
	add_child(bg)
	# облака плывут по небу
	for i in 5:
		var c := PixelArt.make_sprite(PixelArt.cloud(), _scale)
		c.position = Vector2(randf_range(0, _vs.x), randf_range(10, _vs.y * 0.3))
		c.set_meta("speed", randf_range(8.0, 22.0))
		add_child(c)
		_clouds.append(c)
	# затемнение под надписями, чтобы их было лучше видно
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.18)
	shade.size = _vs
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var title := Label.new()
	title.text = "PATH OF LEGENDS"
	title.size = Vector2(_vs.x, 100)
	title.position = Vector2(0, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	title.add_theme_constant_override("outline_size", 16)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.08))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	add_child(title)

	# режимы — крупно, магазин и инвентарь — под ними
	var cx := _vs.x / 2
	var bs := make_button(self, "История", Vector2(cx - 330, 186), Vector2(660, 92), 40)
	bs.pressed.connect(func(): mode_chosen.emit("story"))
	bs.modulate = Color(1.12, 1.05, 0.9)
	var b1 := make_button(self, "Дуэль", Vector2(cx - 330, 292), Vector2(320, 74), 32)
	b1.pressed.connect(func(): mode_chosen.emit("duel"))
	var b2 := make_button(self, "Арена", Vector2(cx + 10, 292), Vector2(320, 74), 32)
	b2.pressed.connect(func(): mode_chosen.emit("arena"))
	var b3 := make_button(self, "Магазин", Vector2(cx - 330, 380), Vector2(320, 64), 26)
	b3.pressed.connect(func(): mode_chosen.emit("shop"))
	var b4 := make_button(self, "Инвентарь", Vector2(cx + 10, 380), Vector2(320, 64), 26)
	b4.pressed.connect(func(): mode_chosen.emit("inventory"))
	var b5 := make_button(self, "Бестиарий", Vector2(cx - 330, 458), Vector2(213, 60), 22)
	b5.pressed.connect(func(): mode_chosen.emit("bestiary"))
	var b6 := make_button(self, "Управление", Vector2(cx - 106, 458), Vector2(213, 60), 22)
	b6.pressed.connect(func(): mode_chosen.emit("controls"))
	var b7 := make_button(self, "Настройки", Vector2(cx + 117, 458), Vector2(213, 60), 22)
	b7.pressed.connect(func(): mode_chosen.emit("settings"))
	_coins = CoinBadge.corner(self)
	# временные кнопки для проверки
	var d1 := make_button(self, "Добавить 100 золотых", Vector2(20, _vs.y - 70), Vector2(270, 50), 18)
	d1.pressed.connect(func():
		Save.add_gold(100)
		_coins.refresh())
	var d2 := make_button(self, "Очистить прогресс", Vector2(300, _vs.y - 70), Vector2(240, 50), 18)
	d2.pressed.connect(func():
		Save.reset()                   # золото, арена и бестиарий — всё заново
		_coins.refresh()
		d2.text = "Прогресс очищен")
	var d3 := make_button(self, "Открыть все арены", Vector2(550, _vs.y - 70), Vector2(240, 50), 18)
	d3.pressed.connect(func():
		Save.unlock_all_stages()
		d3.text = "Арены открыты")
	var d4 := make_button(self, "Открыть всех легенд", Vector2(800, _vs.y - 70), Vector2(250, 50), 18)
	d4.pressed.connect(func():
		Save.unlock_all_heroes()
		d4.text = "Легенды открыты")

func _process(delta: float) -> void:
	for c in _clouds:
		c.position.x += float(c.get_meta("speed")) * delta
		if c.position.x > _vs.x:
			c.position.x = -50.0 * _scale

static func make_button(parent: Node, text: String, pos: Vector2, size: Vector2,
		font: int) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", font)
	parent.add_child(b)
	return b
