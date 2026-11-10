class_name TradePanel
extends Control
## UI de comércio unificada (Fase 5.5, MECANICAS #10): abas Comprar, Vender
## e Leilão. Aberta pelo diálogo do líder da capital (efeito `comercio`,
## que emite Game.trade_requested) - cada território negocia pelo seu
## líder; o leilão pertence só à Guilda de Porto Franco (humano).
## Tooltips mostram a decomposição do preço (base x demanda x especialidade
## x reputação) para o jogador entender a economia (REGRAS #8/#10).

signal closed

const TAB_BUY := 0
const TAB_SELL := 1
const TAB_AUCTION := 2
const AUCTION_RACE := &"humano"  ## casa de leilões: capital humana (REGRAS #9)

var race: StringName = &""
var region_level := 1
var _dim: ColorRect
var _panel: PanelContainer
var _content: VBoxContainer
var _tab_bar: HBoxContainer
var _status: Label
var _tab := TAB_BUY


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	var w := UIKit.window_panel("", Vector2(560, 0), close)
	_panel = w.panel
	add_child(_panel)
	var body: VBoxContainer = w.body
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 8)
	body.add_child(_tab_bar)
	# Scroll: estoque/leilão podem listar mais itens que cabem na janela
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 430)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 6)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)
	_status = UIKit.label("", 15, UIKit.TEXT_DIM)
	body.add_child(UIKit.separator())
	body.add_child(_status)


func open(p_race: StringName, p_region_level := 1) -> void:
	race = p_race
	region_level = p_region_level
	var vs := get_viewport_rect().size
	_panel.position = Vector2((vs.x - _panel.size.x) * 0.5, vs.y * 0.12)
	get_tree().paused = true
	UIKit.pop_in(_panel)
	Sfx.play(&"ui_open", -8.0)
	_show_tab(TAB_BUY)


func close() -> void:
	get_tree().paused = false
	Sfx.play(&"ui_close", -10.0)
	var tw := create_tween()
	tw.tween_property(_dim, "color:a", 0.0, 0.18)
	UIKit.pop_out(_panel, func():
		closed.emit()
		queue_free()
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_I:
			close()
			get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ ABAS

func _show_tab(tab: int) -> void:
	# o leilão pertence só à Guilda de Porto Franco (REGRAS #9)
	if tab == TAB_AUCTION and race != AUCTION_RACE:
		tab = TAB_BUY
	_tab = tab
	for c in _tab_bar.get_children():
		c.queue_free()
	var vendor: VendorData = DB.vendor(race)
	var tabs: Dictionary = {"Comprar": TAB_BUY, "Vender": TAB_SELL}
	if race == AUCTION_RACE:
		tabs["Leilão"] = TAB_AUCTION
	for label in tabs:
		var b := UIKit.button(label, func(): _show_tab(tabs[label]))
		if tabs[label] == _tab:
			b.modulate = UIKit.ACCENT_GOLD
		_tab_bar.add_child(b)
	for c in _content.get_children():
		c.queue_free()
	if _tab == TAB_BUY:
		_show_buy(vendor)
	elif _tab == TAB_SELL:
		_show_sell(vendor)
	else:
		_show_auction()
	_refresh_status()


func _refresh_status() -> void:
	var hero := Game.hero
	var rep := int(Game.reputation.get(race, 0)) if Game.hero != null else 0
	_status.text = "Ouro: %d    Essência: %d    Reputação aqui: %s (-%d%%)" % [
		hero.gold, hero.essence, Market.tier_name(rep), 5 * rep]


# ------------------------------------------------------------------ COMPRAR

func _show_buy(vendor: VendorData) -> void:
	var intro := UIKit.rich("[b]%s[/b] - [color=#9A917F]\"%s\"[/color]" % [
		vendor.display_name, vendor.greeting])
	_content.add_child(intro)
	var stock: Array = vendor.stock_for(Market.market_day(), region_level)
	for i in stock.size():
		var e: Dictionary = stock[i]
		var base: Dictionary = DB.BASES[e["base"]]
		var price := Market.buy_price(race, e)
		var rname: String = Item.RARITY_NAMES[e["rarity"]]
		if Market.is_sold(race, i):
			var sold := UIKit.label("  %s - vendido hoje" % base["name"], 15, UIKit.TEXT_DIM)
			_content.add_child(sold)
			continue
		var b := UIKit.button("%s (nv %d, %s) - %d ouro" % [base["name"], e["level"], rname, price],
			func(): do_buy(i), 520)
		b.tooltip_text = _buy_tooltip(e, price)
		_content.add_child(b)


## Tooltip: decomposição do preço de compra (MECANICAS #10)
func _buy_tooltip(e: Dictionary, price: int) -> String:
	var cat := Market.category_of(e["base"])
	var v: VendorData = DB.vendor(race)
	var producer := cat in v.specialties
	var dem := Market.demand(race, cat)
	var rep := int(Game.reputation.get(race, 0)) if Game.hero != null else 0
	return "base %d\nx demanda local %.2f\nx %s (produto daqui, dump do produtor)\nx reputação %s (-%d%%)\n= %d ouro" % [
		int(e["price"]), dem, "0.45" if producer else "1.00",
		Market.tier_name(rep), 5 * rep, price]


## Jogador compra o slot `i` do estoque do dia
func do_buy(i: int) -> void:
	var vendor: VendorData = DB.vendor(race)
	var stock: Array = vendor.stock_for(Market.market_day(), region_level)
	if i < 0 or i >= stock.size() or Market.is_sold(race, i):
		return
	var e: Dictionary = stock[i]
	var price := Market.buy_price(race, e)
	var hero := Game.hero
	if hero.gold < price:
		_notice("Ouro insuficiente", Color(1, 0.5, 0.4))
		return
	var it := DB.create_item(e["base"], int(e["level"]), int(e["rarity"]))
	if not hero.inventory.add(it):
		_notice("Inventário cheio", Color(1, 0.5, 0.4))
		return
	hero.add_gold(-price)
	Market.on_buy(race, Market.category_of(e["base"]), i)
	Sfx.play(&"coins")
	_notice("Comprou: %s" % it.name, it.rarity_color())
	_show_tab(TAB_BUY)


# ------------------------------------------------------------------ VENDER

func _show_sell(_vendor: VendorData) -> void:
	var hero := Game.hero
	var count := 0
	for it in hero.inventory.items:
		if it == null:
			continue
		count += 1
		var price := Market.sell_price(race, it)
		var b := UIKit.button("%s - %d ouro" % [it.name, price],
			do_sell.bind(it), 520)
		b.modulate = it.rarity_color()
		b.tooltip_text = _sell_tooltip(it, price)
		_content.add_child(b)
	if count == 0:
		_content.add_child(UIKit.label("Nada para vender.", 16, UIKit.TEXT_DIM))


## Tooltip: decomposição do preço de venda (REGRAS #8)
func _sell_tooltip(it: Item, price: int) -> String:
	var cat := StringName(it.category) if it.category != "" else Market.category_of(it.base_id)
	var v: VendorData = DB.vendor(race)
	var scarce := not (cat in v.specialties)
	var dem := Market.demand(race, cat)
	return "base %d (valor REGRAS #8)\nx 40%% (vendor compra abaixo do valor)\nx demanda local %.2f\nx %s (o que falta aqui paga mais)\n= %d ouro" % [
		VendorData._base_value(it.item_level, it.rarity), dem,
		"1.25" if scarce else "0.80", price]


## Jogador vende um item do inventário
func do_sell(it: Item) -> void:
	var hero := Game.hero
	if it == null or not hero.inventory.items.has(it):
		return
	var price := Market.sell_price(race, it)
	hero.add_gold(price)
	hero.inventory.remove(it)
	Market.on_sell(race, Market.category_of(it.base_id))
	Sfx.play(&"coins")
	_notice("Vendeu: %s (+%d ouro)" % [it.name, price], Color(1, 0.85, 0.3))
	_show_tab(TAB_SELL)


# ------------------------------------------------------------------ LEILAO

func _show_auction() -> void:
	var slots: Array = Auction.slots()
	for i in slots.size():
		var e: Dictionary = slots[i]
		var base_id: StringName = e["base"]
		var base: Dictionary = DB.BASES.get(base_id, {})
		if base.is_empty():
			continue
		var rname: String = Item.RARITY_NAMES[e["rarity"]]
		var cur: String = "essência" if String(e["currency"]) == "essence" else "ouro"
		if bool(e["sold"]):
			_content.add_child(UIKit.label("  %s - arrematado" % base["name"], 15, UIKit.TEXT_DIM))
			continue
		var flavor := " - Relíquia de chefe!" if bool(e["unique"]) else ""
		var b := UIKit.button("%s (nv %d, %s%s) - lance %d %s" % [
				base["name"], e["level"], rname, flavor, e["min_bid"], cur],
			func(): do_bid(i), 520)
		if int(e["rarity"]) >= Item.Rarity.LEGENDARY:
			b.modulate = Color(1, 0.55, 0.1)
		b.tooltip_text = "Valor de tabela: %d\nLance mínimo sobe 10%% por contra-lance rival (%d restante(s))" % [
			int(e["value"]), int(e["rivals_left"])]
		_content.add_child(b)
	_content.add_child(UIKit.rich("[color=#9A917F]A Guilda aceita essência no slot especial - moeda dura de Campeões e Chefes (REGRAS #9).[/color]"))


## Jogador dá lance no slot `i` do leilão
func do_bid(i: int) -> void:
	var r := Auction.place_bid(i)
	match String(r["result"]):
		"outbid":
			_notice("Rival cobriu seu lance - o mínimo subiu 10%", Color(1, 0.6, 0.3))
			Sfx.play(&"ui_close", -12.0)
		"won":
			var it: Item = r["item"]
			_notice("Arrematou: %s!" % it.name, it.rarity_color())
			Sfx.play(&"coins")
		"broke":
			_notice("Recursos insuficientes para este lance", Color(1, 0.5, 0.4))
		"full":
			_notice("Inventário cheio", Color(1, 0.5, 0.4))
	_show_tab(TAB_AUCTION)


# ------------------------------------------------------------------ AUX

func _notice(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)
