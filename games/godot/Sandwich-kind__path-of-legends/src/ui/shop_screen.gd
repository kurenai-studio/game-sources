class_name ShopScreen
extends CanvasLayer
# Магазин: лавка в таверне. За стойкой — торговец, по бокам — полки с товарами.
# Вкладки на стойке: «Герои», «Предметы», «Усиления», «Сундуки».
# При смене вкладки торговец поворачивается, машет руками и переставляет товары
# (около 1,2 секунды); пока он занят, другую вкладку выбрать нельзя.
# «Герои» — легенды за монеты, «МЕГА» — МЕГА-усиление для каждой легенды
# (на выборе легенды появляется кнопка «МЕГА»). Нажми на товар — откроется
# карточка с ценой и кнопкой «Купить». Остальные вкладки пока для витрины.

signal back_pressed

const TABS := ["Герои", "МЕГА", "Предметы", "Сундуки"]
const SWAP_TIME := 1.2

var _k := 4.0
var _off := Vector2.ZERO
var _merchant: Merchant
var _tab := 0
var _busy := false
var _tab_btns: Array = []
var _items: Array = []
var _shelf_layer: Node2D
var _hot_layer: Control        # невидимые кнопки поверх товаров
var _offers: Array = []        # что продаётся в каждом слоте полки
var _coins: CoinBadge
var _popup: Control
var _hot_btns := {}            # слот полки -> кнопка товара (для геймпада)
var _last_j := -1

func _ready() -> void:
	var vs := Config.screen(self)
	var img := PixelArt.tavern()
	_k = maxf(vs.x / img.get_width(), vs.y / img.get_height())
	var bg := PixelArt.make_sprite(img, _k)
	_off = (vs - Vector2(img.get_size()) * _k) / 2
	bg.position = _off
	add_child(bg)
	_shelf_layer = Node2D.new()
	_shelf_layer.position = _off
	_shelf_layer.scale = Vector2(_k, _k)
	add_child(_shelf_layer)
	_merchant = Merchant.new()
	_merchant.position = _off + Vector2(160, 126) * _k
	_merchant.scale = Vector2(_k, _k) * 1.55
	add_child(_merchant)
	var counter := PixelArt.make_sprite(PixelArt.tavern_counter(), _k)
	counter.position = _off
	add_child(counter)
	# вывеска
	var sign := Label.new()
	sign.text = "ЛАВКА"
	sign.position = _off + Vector2(125, 18) * _k
	sign.size = Vector2(70, 16) * _k
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sign.add_theme_font_size_override("font_size", int(9 * _k))
	sign.add_theme_color_override("font_color", Color(0.25, 0.13, 0.05))
	sign.add_theme_constant_override("outline_size", 0)
	add_child(sign)
	# вкладки — деревянные таблички на стойке
	for i in TABS.size():
		var b := Button.new()
		b.text = TABS[i]
		b.position = _off + Vector2(38 + i * 62, 130) * _k
		b.size = Vector2(56, 22) * _k
		b.add_theme_font_size_override("font_size", int(6.5 * _k))
		for st_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(st_name, _plank(st_name))
		b.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
		b.add_theme_color_override("font_disabled_color", Color(0.8, 0.7, 0.55))
		b.pressed.connect(_select.bind(i))
		add_child(b)
		_tab_btns.append(b)
	_hot_layer = Control.new()
	_hot_layer.size = vs
	_hot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hot_layer)
	var note := Label.new()
	note.text = "Нажми на товар, чтобы посмотреть и купить"
	note.size = Vector2(vs.x, 30)
	note.position = Vector2(0, vs.y - 34)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 18)
	note.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	add_child(note)
	_coins = CoinBadge.corner(self)
	# «Назад» — внизу слева, чтобы не закрывать товары на верхней полке
	var back := MainMenu.make_button(self, "Назад", Vector2(16, vs.y - 72), Vector2(130, 55), 26)
	back.pressed.connect(func(): back_pressed.emit())
	_fill_shelves(0, false)
	_refresh_tabs()

func _plank(st_name: String) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	var c := Color(0.50, 0.31, 0.16)
	if st_name == "hover":
		c = c.lightened(0.1)
	elif st_name == "pressed":
		c = c.darkened(0.1)
	st.bg_color = c
	st.border_color = Color(0.28, 0.16, 0.08)
	st.set_border_width_all(4)
	if st_name == "focus":
		st.draw_center = false
		st.border_color = Color(1.0, 0.85, 0.35)       # выбрана геймпадом — золотая рамка
		st.set_border_width_all(6)
	st.set_corner_radius_all(4)
	return st

func _refresh_tabs() -> void:
	# пока торговец переставляет товары, вкладки не нажимаются (но остаются выбранными
	# для геймпада — иначе выбор прыгал бы на «Назад»)
	for i in _tab_btns.size():
		var b: Button = _tab_btns[i]
		var k := 0.75 if _busy else 1.0
		b.modulate = (Color(1.3, 1.15, 0.7) if i == _tab else Color(0.85, 0.85, 0.85)) * Color(k, k, k)
		if i == _tab:
			b.set_meta("pad_default", true)
		elif b.has_meta("pad_default"):
			b.remove_meta("pad_default")

# ---------- Смена вкладки ----------
func _select(i: int) -> void:
	if _busy or i == _tab:
		return
	_busy = true
	_tab = i
	_refresh_tabs()
	_merchant.turn(true)
	_merchant.busy = true
	# старые товары улетают к торговцу
	var mpos := Vector2(160, 70)
	var n := _items.size()
	for j in n:
		var it: Node2D = _items[j]
		var t := it.create_tween()
		t.tween_interval(0.05 + 0.4 * j / maxf(n, 1))
		t.tween_property(it, "position", mpos, 0.16).set_trans(Tween.TRANS_SINE)
		t.parallel().tween_property(it, "scale", Vector2(0.2, 0.2), 0.16)
		t.tween_callback(it.queue_free)
	_items.clear()
	_clear_hot()
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(_fill_shelves.bind(i, true))
	tw.tween_interval(SWAP_TIME - 0.5 - 0.15)
	tw.tween_callback(func():
		_merchant.busy = false
		_merchant.turn(false))
	tw.tween_interval(0.15)
	tw.tween_callback(func():
		_busy = false
		_refresh_tabs())

# Полки: по 3 слота на каждой из 6 полок
func _slots() -> Array:
	var res := []
	for row in 3:
		for x0 in PixelArt.SHELF_X:
			for k in 3:
				res.append(Vector2(x0 + 16 + k * 30, PixelArt.SHELF_Y[row]))
	return res

func _fill_shelves(tab: int, animate: bool) -> void:
	var goods := _goods(tab)
	var slots := _slots()
	var mpos := Vector2(160, 70)
	_offers.clear()
	_clear_hot()
	for j in mini(goods.size(), slots.size()):
		var g = goods[j]
		var offer: Dictionary = {}
		var it: Node2D
		if g is Dictionary:
			offer = g
			it = _offer_node(g)
		else:
			var sp := PixelArt.make_sprite(g, 1.0)
			sp.centered = true
			sp.offset = Vector2(0, -g.get_height() / 2.0)
			it = sp
		_shelf_layer.add_child(it)
		_items.append(it)
		_offers.append(offer)
		var target: Vector2 = slots[j]
		if not offer.is_empty():
			_add_hot(target, offer, j)
		if animate:
			it.position = mpos
			it.scale = Vector2(0.2, 0.2)
			var t := it.create_tween()
			t.tween_interval(0.4 * j / maxf(goods.size(), 1))
			t.tween_property(it, "position", target, 0.16).set_trans(Tween.TRANS_SINE)
			t.parallel().tween_property(it, "scale", Vector2.ONE, 0.16)
		else:
			it.position = target

# ---------- Товары (маленькие пиксельные картинки) ----------
func _goods(tab: int) -> Array:
	var res := []
	match tab:
		0:   # герои: легенды за монеты, остальное место — таинственные коробки
			for i in Characters.LIST.size():
				if Characters.LIST[i].has("price"):
					res.append({"kind": "hero", "idx": i, "price": Characters.LIST[i]["price"]})
			for i in 7:
				res.append(_mystery_box())
		1:   # МЕГА: по усилению на каждую легенду
			for i in Characters.LIST.size():
				res.append({"kind": "mega", "idx": i, "price": Characters.MEGA_PRICE})
		2:   # предметы: зелья, бомбы, свитки, щиты
			var potions := [Color(0.9, 0.2, 0.25), Color(0.25, 0.5, 1.0), Color(0.3, 0.85, 0.35), Color(0.9, 0.75, 0.2)]
			for c in potions:
				res.append(_potion(c))
			res.append(_bomb())
			res.append(_bomb())
			res.append(_scroll())
			res.append(_scroll())
			res.append(_small_shield())
		3:   # сундуки
			for c in [Color(0.55, 0.36, 0.18), Color(0.6, 0.62, 0.68), Color(0.9, 0.72, 0.25)]:
				res.append(_chest(c))
				res.append(_chest(c))
	return res

func _img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

func _figurine(c: Color) -> Image:
	var im := _img(10, 16)
	im.fill_rect(Rect2i(1, 13, 8, 3), Color(0.35, 0.25, 0.18))      # подставка
	BotRig._box(im, 2, 2, 6, 11, c)
	im.fill_rect(Rect2i(5, 4, 2, 2), Color.BLACK)
	return im

func _mystery_box() -> Image:
	var im := _img(12, 12)
	BotRig._box(im, 0, 1, 12, 11, Color(0.55, 0.35, 0.6))
	im.fill_rect(Rect2i(5, 1, 2, 11), Color(0.95, 0.8, 0.3))
	im.fill_rect(Rect2i(4, 4, 4, 1), Color(1, 1, 1))
	im.fill_rect(Rect2i(7, 5, 1, 2), Color(1, 1, 1))
	im.fill_rect(Rect2i(5, 7, 2, 1), Color(1, 1, 1))
	im.fill_rect(Rect2i(5, 9, 2, 1), Color(1, 1, 1))
	return im

func _potion(c: Color) -> Image:
	var im := _img(9, 14)
	im.fill_rect(Rect2i(3, 0, 3, 2), Color(0.55, 0.38, 0.2))       # пробка
	im.fill_rect(Rect2i(3, 2, 3, 3), Color(0.85, 0.9, 0.95, 0.8))
	BotRig._box(im, 0, 5, 9, 9, Color(0.85, 0.9, 0.95))
	im.fill_rect(Rect2i(1, 8, 7, 5), c)
	im.set_pixel(2, 7, Color.WHITE)
	return im

func _bomb() -> Image:
	var im := _img(10, 12)
	BotRig._box(im, 0, 3, 10, 9, Color(0.15, 0.15, 0.17))
	im.fill_rect(Rect2i(4, 0, 2, 3), Color(0.6, 0.5, 0.35))
	im.set_pixel(5, 0, Color(1.0, 0.6, 0.2))
	im.set_pixel(2, 5, Color(0.5, 0.5, 0.55))
	return im

func _scroll() -> Image:
	var im := _img(14, 9)
	BotRig._box(im, 2, 1, 10, 7, Color(0.93, 0.85, 0.66))
	BotRig._box(im, 0, 0, 3, 9, Color(0.75, 0.6, 0.4))
	BotRig._box(im, 11, 0, 3, 9, Color(0.75, 0.6, 0.4))
	im.fill_rect(Rect2i(6, 3, 2, 3), Color(0.8, 0.15, 0.15))
	return im

func _small_shield() -> Image:
	var im := _img(11, 13)
	for y in 13:
		var hw := int(5.5 - maxf(0.0, y - 7) * 0.8)
		im.fill_rect(Rect2i(5 - hw, y, hw * 2 + 1, 1), Color(0.3, 0.45, 0.8))
	im.fill_rect(Rect2i(5, 1, 1, 10), Color(0.95, 0.8, 0.3))
	return im

func _gem(c: Color) -> Image:
	var im := _img(10, 11)
	for y in 11:
		var hw := 4 - absi(y - 4) if y <= 4 else int((10 - y) * 0.7)
		im.fill_rect(Rect2i(5 - hw, y, hw * 2, 1), c if y > 2 else c.lightened(0.35))
	im.set_pixel(4, 3, Color.WHITE)
	return im

func _rune(c: Color) -> Image:
	var im := _img(10, 12)
	BotRig._box(im, 0, 0, 10, 12, Color(0.45, 0.45, 0.5))
	im.fill_rect(Rect2i(4, 2, 2, 8), c)
	im.fill_rect(Rect2i(2, 4, 6, 1), c)
	im.fill_rect(Rect2i(3, 7, 4, 1), c)
	return im

func _chest(c: Color) -> Image:
	var im := _img(16, 12)
	BotRig._box(im, 0, 3, 16, 9, c)
	BotRig._box(im, 0, 0, 16, 5, c.lightened(0.12))
	im.fill_rect(Rect2i(0, 5, 16, 1), Color(0.2, 0.15, 0.1))
	im.fill_rect(Rect2i(7, 4, 2, 3), Color(0.95, 0.8, 0.3))
	for x in [2, 13]:
		im.fill_rect(Rect2i(x, 0, 1, 12), c.darkened(0.35))
	return im

# ---------- Товары, которые можно купить ----------
# Фигурка легенды (настоящая модель) или МЕГА-кристалл с цветом легенды
func _offer_node(o: Dictionary) -> Node2D:
	var ch: Dictionary = Characters.LIST[o["idx"]]
	var root := Node2D.new()
	if o["kind"] == "hero":
		var stand := Polygon2D.new()
		stand.polygon = PackedVector2Array([Vector2(-8, -2), Vector2(8, -2), Vector2(8, 0), Vector2(-8, 0)])
		stand.color = Color(0.35, 0.25, 0.18)
		root.add_child(stand)
		var rig := BotRig.new()
		rig.kind = ch["rig"]
		rig.size = Vector2(12, 19)
		rig.position = Vector2(0, -2 - 9.5)
		root.add_child(rig)
	else:
		var img := _gem(ch["color"].lightened(0.15))
		var sp := PixelArt.make_sprite(img, 1.0)
		sp.centered = true
		sp.offset = Vector2(0, -img.get_height() / 2.0)
		root.add_child(sp)
		var m := Label.new()
		m.text = "M"
		m.position = Vector2(-4, -9)
		m.size = Vector2(8, 8)
		m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m.add_theme_font_size_override("font_size", 6)
		m.add_theme_color_override("font_color", Color(1, 1, 1))
		m.add_theme_constant_override("outline_size", 2)
		root.add_child(m)
	return root

func _owned(o: Dictionary) -> bool:
	var name: String = Characters.LIST[o["idx"]]["name"]
	return Save.owns_hero(name) if o["kind"] == "hero" else Save.has_mega(name)

func _clear_hot() -> void:
	_hot_btns.clear()
	if _hot_layer:
		for c in _hot_layer.get_children():
			c.queue_free()

# Невидимая кнопка над товаром и ценник под ним
func _add_hot(slot: Vector2, o: Dictionary, j: int) -> void:
	var b := Button.new()
	b.flat = true
	b.position = _off + (slot + Vector2(-13, -22)) * _k
	b.size = Vector2(26, 24) * _k
	b.focus_mode = Control.FOCUS_ALL          # товар можно выбрать геймпадом
	for st_name in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(1, 1, 1, 0.0 if st_name == "normal" else 0.12)
		st.set_corner_radius_all(6)
		if st_name == "focus":
			st.bg_color = Color(1.0, 0.85, 0.35, 0.16)     # выбранный геймпадом — в золотой рамке
			st.border_color = Color(1.0, 0.85, 0.35, 0.95)
			st.set_border_width_all(4)
		b.add_theme_stylebox_override(st_name, st)
	b.pressed.connect(_open_offer.bind(j))
	_hot_layer.add_child(b)
	_hot_btns[j] = b
	var tag := Label.new()
	tag.position = _off + (slot + Vector2(-14, 0.5)) * _k
	tag.size = Vector2(28, 7) * _k
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", int(4.6 * _k))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _owned(o):
		tag.text = "есть"
		tag.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	else:
		tag.text = "%d G" % o["price"]
		tag.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_hot_layer.add_child(tag)

# ---------- Карточка товара ----------
func _open_offer(j: int) -> void:
	if _busy or j >= _offers.size() or _offers[j].is_empty():
		return
	_close_offer(false)
	_last_j = j
	var o: Dictionary = _offers[j]
	var ch: Dictionary = Characters.LIST[o["idx"]]
	var vs := Config.screen(self)
	_popup = Control.new()
	_popup.size = vs
	_popup.add_to_group("pad_scope")            # геймпад выбирает только кнопки карточки
	add_child(_popup)
	var dim := ColorRect.new()
	dim.size = vs
	dim.color = Color(0, 0, 0, 0.55)
	dim.gui_input.connect(_dim_input)
	_popup.add_child(dim)
	var card := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.93, 0.86, 0.68)
	st.border_color = Color(0.45, 0.28, 0.12)
	st.set_border_width_all(6)
	st.set_corner_radius_all(14)
	card.add_theme_stylebox_override("panel", st)
	card.size = Vector2(760, 470)
	card.position = (vs - card.size) / 2
	_popup.add_child(card)
	var mega: bool = o["kind"] == "mega"
	var ink := Color(0.25, 0.14, 0.06)
	var title: String = ("МЕГА: " if mega else "") + ch["name"]
	_card_label(card, title, Vector2(250, 22), Vector2(490, 50), 34, ink)
	var text := ""
	if mega:
		text = "Постоянный МЕГА для легенды «%s».\nНа выборе легенды под героем появится кнопка «МЕГА». Включишь — герой всегда использует только МЕГА-способности и МЕГА-ульту, даже без баффа. Выключишь — обычные способности, а МЕГА — только с баффом «МЕГА-усиление»." % ch["name"]
	else:
		text = ch["role"] + "\n" + ch["weapon"] + "\nЗдоровье: %d   Скорость: %d" % [ch["hp"], int(ch["speed"])]
	_card_label(card, text, Vector2(250, 80), Vector2(480, 260), 19, ink)
	HeroFigure.draw(card, Vector2(130, 330), 3.0, o["idx"], Color(0, 0, 0, 0), 1, not Characters.unlocked(o["idx"]) and mega)
	if mega:
		var glow := Label.new()
		glow.text = "МЕГА"
		glow.position = Vector2(40, 345)
		glow.size = Vector2(180, 40)
		glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glow.add_theme_font_size_override("font_size", 30)
		glow.add_theme_color_override("font_color", Color(0.75, 0.35, 1.0))
		card.add_child(glow)
	var owned := _owned(o)
	var can_open: bool = Characters.unlocked(o["idx"]) or not mega
	var buy := MainMenu.make_button(card, "", Vector2(250, 370), Vector2(300, 74), 30)
	if owned:
		buy.text = "Уже куплено"
		buy.disabled = true
	elif not can_open:
		buy.text = "Сначала открой легенду"
		buy.add_theme_font_size_override("font_size", 20)
		buy.disabled = true
	elif Save.gold() < o["price"]:
		buy.text = "Нужно %d G" % o["price"]
		buy.disabled = true
	else:
		buy.text = "Купить за %d G" % o["price"]
		buy.pressed.connect(_buy.bind(o))
	var close := MainMenu.make_button(card, "Закрыть", Vector2(570, 370), Vector2(160, 74), 24)
	close.pressed.connect(_close_offer)
	# геймпад: сразу на «Купить» (или на «Закрыть», если купить нельзя)
	var first: Button = close if buy.disabled else buy
	first.grab_focus.call_deferred()

func _card_label(parent: Control, text: String, pos: Vector2, size: Vector2, font: int, c: Color) -> void:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", c)
	l.add_theme_constant_override("outline_size", 0)
	parent.add_child(l)

func _dim_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed:
		_close_offer()

func _close_offer(refocus := true) -> void:
	if _popup and is_instance_valid(_popup):
		_popup.remove_from_group("pad_scope")
		_popup.queue_free()
	_popup = null
	if refocus and _hot_btns.has(_last_j) and is_instance_valid(_hot_btns[_last_j]):
		_hot_btns[_last_j].grab_focus.call_deferred()      # выбор возвращается на товар

# B на геймпаде: сначала закрывает карточку товара, а уже потом — магазин
func handle_back() -> bool:
	if _popup and is_instance_valid(_popup):
		_close_offer()
		return true
	return false

func _buy(o: Dictionary) -> void:
	var ch: Dictionary = Characters.LIST[o["idx"]]
	if not Save.buy(o["kind"], ch["name"], o["price"]):
		return
	_close_offer(false)
	if _coins:
		_coins.refresh()
	# торговец радуется: поворачивается и машет, товар на полке подписан «есть»
	_merchant.turn(true)
	var t := create_tween()
	t.tween_interval(0.35)
	t.tween_callback(func(): _merchant.turn(false))
	_clear_hot()
	var slots := _slots()
	for j in _offers.size():
		if not _offers[j].is_empty():
			_add_hot(slots[j], _offers[j], j)
	if _hot_btns.has(_last_j):
		_hot_btns[_last_j].grab_focus.call_deferred()
	var vs := Config.screen(self)
	var msg := Label.new()
	msg.text = ("Куплено: МЕГА для «%s»!" if o["kind"] == "mega" else "Новая легенда: %s!") % ch["name"]
	msg.size = Vector2(vs.x, 60)
	msg.position = Vector2(0, vs.y * 0.18)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 40)
	msg.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	add_child(msg)
	var mt := msg.create_tween()
	mt.tween_interval(1.4)
	mt.tween_property(msg, "modulate:a", 0.0, 0.5)
	mt.tween_callback(msg.queue_free)
