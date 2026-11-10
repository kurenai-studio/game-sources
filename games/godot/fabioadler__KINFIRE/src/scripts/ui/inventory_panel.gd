class_name InventoryPanel
extends PanelContainer
## Inventário estilo Diablo: equipamento + grade com itens de tamanhos variados.
## Drag-and-drop completo: arraste entre grade e slots, solte fora para dropar, ESC cancela.
## MECANICAS #9.3: shift+clique = equipar/usar | ctrl+clique = vender (com vendor aberto)

const CELL := 40

var hud: HUD
var hero: Hero
var held: Item          ## Item "na mão" do cursor (click-to-hold legacy)
var _grid_view: Control
var _equip_views: Dictionary = {}
var _doll: Control
var _hero_sprite: SpritePreview
var _gold_label: Label
var _stats_label: RichTextLabel
var _tooltip: PanelContainer
var _tooltip_text: RichTextLabel
var _refresh_callback: Callable
var _gold_callback: Callable

## Estado de arraste (drag-and-drop unificado)
var _drag: Dictionary = {"source": null, "item": null, "slot": null, "start_pos": Vector2.ZERO, "ghost_visible": false}
func is_dragging() -> bool: return _drag != null and _drag.source != null
func drag_clear() -> void: _drag = {"source": null, "item": null, "slot": null, "start_pos": Vector2.ZERO, "ghost_visible": false}

# Helper tipado para acessar item do drag
func _get_drag_item() -> Item:
	return _drag.item if _drag and _drag.item else null


func setup(p_hud: HUD, p_hero: Hero) -> void:
	hud = p_hud
	hero = p_hero
	var w := UIKit.window_panel("Inventário", Vector2(740, 440), func(): hud.toggle_inventory())
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	w.panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(w.panel)
	var body: VBoxContainer = w.body
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)

	var main_hbox := HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 16)
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(main_hbox)

	# === COLUNA ESQUERDA: MOCHILA (GRADE) & AÇÕES ===
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 6)
	main_hbox.add_child(left_col)

	var inv_title := UIKit.label("Mochila", 15, UIKit.GOLD, true)
	left_col.add_child(inv_title)

	_grid_view = _GridView.new()
	_grid_view.panel = self
	_grid_view.custom_minimum_size = Vector2(hero.inventory.cols * CELL, hero.inventory.rows * CELL)
	left_col.add_child(_grid_view)

	var bottom := HBoxContainer.new()
	left_col.add_child(bottom)
	_gold_label = UIKit.label("", 16, Color(1, 0.85, 0.3), true)
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_gold_label)
	bottom.add_child(UIKit.button("Vender Comuns e Mágicos", _sell_junk))

	var hint := UIKit.label("Arraste: mover | Shift+clique: equipar/desequipar | Ctrl+clique: vender | ESC: cancelar | Fora: dropar", 12, UIKit.TEXT_DIM)
	left_col.add_child(hint)

	var v_sep := VSeparator.new()
	main_hbox.add_child(v_sep)

	# === COLUNA DIREITA: EQUIPAMENTO & PAPER DOLL ===
	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 6)
	right_col.custom_minimum_size = Vector2(320, 0)
	main_hbox.add_child(right_col)

	var equip_title := UIKit.label("Equipamento", 15, UIKit.GOLD, true)
	right_col.add_child(equip_title)

	_doll = Control.new()
	_doll.custom_minimum_size = Vector2(320, 216)
	_doll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_col.add_child(_doll)

	var char_bg := Panel.new()
	char_bg.position = Vector2(116, 46)
	char_bg.size = Vector2(88, 112)
	char_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	char_bg.add_theme_stylebox_override("panel", UIKit.box(Color(0.03, 0.025, 0.02, 0.8), Color(UIKit.GOLD_DIM.r, UIKit.GOLD_DIM.g, UIKit.GOLD_DIM.b, 0.35), 1, 6))
	_doll.add_child(char_bg)

	_hero_sprite = SpritePreview.new()
	_hero_sprite.name = "HeroSprite"
	_hero_sprite.set_sprite(hero.sprite_base(), hero.tint * hero.race.tint)
	_hero_sprite.size = Vector2(80, 106)
	_hero_sprite.position = Vector2(120, 49)
	_hero_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_doll.add_child(_hero_sprite)

	var layout: Dictionary = {
		"helm": Rect2(136, 2, 48, 42),
		"amulet": Rect2(192, 4, 40, 40),
		"weapon": Rect2(4, 48, 52, 100),
		"gloves": Rect2(60, 48, 52, 50),
		"ring": Rect2(60, 104, 52, 44),
		"chest": Rect2(208, 48, 52, 50),
		"accessory_1": Rect2(208, 104, 52, 44),
		"offhand": Rect2(264, 48, 52, 100),
		"accessory_2": Rect2(60, 160, 52, 48),
		"boots": Rect2(126, 160, 68, 48),
		"accessory_3": Rect2(208, 160, 52, 48),
	}
	for s in DB.EQUIP_SLOTS:
		if s not in layout:
			push_warning("Slot '%s' não tem layout definido" % s)
			continue
		var r: Rect2 = layout[s]
		var v := _EquipView.new()
		v.panel = self
		v.slot = s
		v.position = r.position
		v.size = r.size
		v.custom_minimum_size = r.size
		_doll.add_child(v)
		_equip_views[s] = v

	right_col.add_child(UIKit.separator())

	_stats_label = UIKit.rich()
	_stats_label.custom_minimum_size = Vector2(320, 24)
	right_col.add_child(_stats_label)

	_tooltip = PanelContainer.new()
	_tooltip.add_theme_stylebox_override("panel", UIKit.box(Color(0.02, 0.015, 0.01, 0.97), UIKit.GOLD_DIM, 2, 3))
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.visible = false
	_tooltip.top_level = true
	_tooltip.z_index = 100
	_tooltip_text = UIKit.rich()
	_tooltip_text.custom_minimum_size = Vector2(300, 0)
	_tooltip.add_child(_tooltip_text)
	add_child(_tooltip)

	hero.inventory.changed.connect(refresh)
	hero.stats_changed.connect(refresh)
	_gold_callback = func(_g): refresh()
	hero.gold_changed.connect(_gold_callback)
	refresh()


func refresh() -> void:
	_gold_label.text = "Ouro: %d" % hero.gold
	_stats_label.text = "[center][color=#bbbbbb]DPS:[/color] [color=#ffffff]%.1f[/color]  [color=#bbbbbb]Arm.:[/color] [color=#ffffff]%.1f[/color]  [color=#bbbbbb]Vida:[/color] [color=#ffffff]%.1f[/color][/center]" % [hero.dps_estimate(), hero.armor(), hero.max_hp()]
	_grid_view.queue_redraw()
	for v in _equip_views.values():
		v.queue_redraw()
	if _hero_sprite:
		_hero_sprite.set_sprite(hero.sprite_base(), hero.tint * hero.race.tint)


func _process(_delta: float) -> void:
	if held:
		_grid_view.queue_redraw()
	if _tooltip.visible:
		var mp := get_viewport().get_mouse_position()
		var vs := get_viewport_rect().size
		var p := mp + Vector2(18, 10)
		if p.x + _tooltip.size.x > vs.x:
			p.x = mp.x - _tooltip.size.x - 12
		if p.y + _tooltip.size.y > vs.y:
			p.y = vs.y - _tooltip.size.y - 4
		_tooltip.global_position = p


func show_tooltip(it: Item) -> void:
	if it == null or held:
		_tooltip.visible = false
		return
	var equipped: Item = hero.equipment.get(it.slot)
	var cmp: Item = equipped if equipped != it else null
	_tooltip_text.text = it.tooltip_bbcode(cmp, hero)
	_tooltip.visible = true
	_tooltip.reset_size()


func hide_tooltip() -> void:
	_tooltip.visible = false


func _draw_item(ci: CanvasItem, it: Item, rect: Rect2, dim := false) -> void:
	var c := it.rarity_color()
	ci.draw_rect(rect.grow(-1), Color(c.r * 0.18, c.g * 0.18, c.b * 0.18, 0.9))
	ci.draw_rect(rect.grow(-1), Color(c, 0.6), false, 1.0)
	var s := minf(rect.size.x, rect.size.y) * 0.8
	var icon_rect: Rect2 = Rect2(rect.get_center() - Vector2(s, s) * 0.5, Vector2(s, s))
	var tint: Color = Color(1, 1, 1, 0.5 if dim else 1.0)
	if hero.equip_problem(it) != "" and it.slot in ["weapon", "offhand"] and not hero.can_use_category(it):
		tint = Color(1, 0.45, 0.45, tint.a)
	ci.draw_texture_rect(DB.icon(it.icon), icon_rect, false, tint)


func drop_held_to_world() -> void:
	if held == null:
		return
	if hud and hud.world:
		LootDrop.drop_item(hud.world, hud.world.player.global_position, held)
	held = null
	refresh()


## --- DRAG-AND-DROP UNIFICADO ---

func _start_drag(source: String, item: Item, slot: Variant, mouse_pos: Vector2) -> void:
	if not item:
		return
	# Se já tem item na mão, devolve para a mochila antes de pegar outro (sem perda)
	if held:
		if not hero.inventory.add(held):
			drop_held_to_world()
		held = null
	_drag = {"source": source, "item": item, "slot": slot, "start_pos": mouse_pos, "ghost_visible": true}
	held = null
	hide_tooltip()
	Sfx.play(&"cloth")
	_grid_view.queue_redraw()
	for v in _equip_views.values():
		v.queue_redraw()


func drag_from_grid(item: Item, cell: Vector2i, mouse_pos: Vector2) -> void:
	_start_drag("grid", item, cell, mouse_pos)


func drag_from_equip(slot: String, mouse_pos: Vector2) -> void:
	var it: Item = hero.equipment.get(slot) if slot in hero.equipment else null
	_start_drag("equip", it, slot, mouse_pos)


func _cancel_drag() -> void:
	if not is_dragging():
		return
	# Devolve item para origem
	var item: Item = _drag.item
	var source: String = _drag.source
	var slot: Variant = _drag.slot
	
	if source == "grid":
		# Recoloca na grade na posição original
		if hero.inventory.in_bounds(item, slot):
			hero.inventory.place(item, slot)
		elif hero.inventory.add(item):
			pass # já estava no inventário
		else:
			drop_to_floor(item)
	elif source == "equip":
		# Re-equipa
		hero.equip(item)
	
	drag_clear()
	_grid_view.queue_redraw()
	for v in _equip_views.values():
		v.queue_redraw()


func _drop_on_grid(cell: Vector2i) -> void:
	if not is_dragging():
		return
	var item: Item = _drag.item
	if item == null:
		drag_clear()
		return
	
	# Se item está equipado, desequipa primeiro
	if hero.equipment.get(item.slot) == item:
		hero.unequip(item.slot)
	
	if not hero.inventory.in_bounds(item, cell):
		drop_to_floor(item)
		return
	
	var over := hero.inventory.overlapping(item, cell)
	if over.size() == 1:
		# Swap com outro item da grade
		var other: Item = over[0]
		hero.inventory.remove(other)
		hero.inventory.place(item, cell)
		held = other
		Sfx.play(&"drop")
	elif hero.inventory.can_place(item, cell):
		hero.inventory.place(item, cell)
		Sfx.play(&"drop")
	elif hero.inventory.add(item):
		if hud:
			hud.show_message("Movido para outro espaço livre", Color(1, 0.8, 0.4))
		Sfx.play(&"drop")
	else:
		drop_to_floor(item)
		return
	drag_clear()


func drop_to_floor(item: Item) -> void:
	if hud and hud.world:
		LootDrop.drop_item(hud.world, hud.world.player.global_position, item)
	Sfx.play(&"drop")
	if hud:
		hud.show_message("Item jogado fora: %s" % item.name, Color(0.8, 0.3, 0.3))
	drag_clear()


func _drop_on_slot(slot: String) -> void:
	if not is_dragging():
		return
	var item: Item = _drag.item
	if item == null:
		drag_clear()
		return
	
	# Dropar de volta no mesmo slot de equipamento: no-op
	if _drag.source == "equip" and slot == _drag.slot:
		drag_clear()
		return
	
	# Verifica se slot é compatível
	if item.slot != slot:
		if hud:
			hud.show_message("Este item não vai neste espaço", Color(1, 0.5, 0.4))
		_cancel_drag()
		return
	
	var problem := hero.equip_problem(item)
	if problem != "":
		if hud:
			hud.show_message(problem, Color(1, 0.5, 0.4))
		_cancel_drag()
		return
	
	# Slot livre: equipa direto
	if not slot in hero.equipment or hero.equipment[slot] == null:
		if _drag.source == "grid":
			equip_from_inventory(item)
		else:
			hero.equip(item)
			Sfx.play(&"equip")
			if hud:
				hud.show_message("Equipado: %s" % item.name, Color(0.4, 1, 0.4))
		drag_clear()
		return
	
	# Slot ocupado: swap automático (remove do inventário ANTES de equipar para não duplicar)
	var old: Item = hero.equipment[slot]
	if _drag.source == "grid":
		hero.inventory.remove(item)
	hero.equip(item)
	if not hero.inventory.add(old):
		drop_to_floor(old)
	Sfx.play(&"equip")
	if hud:
		hud.show_message("Equipado: %s" % item.name, Color(0.4, 1, 0.4))
	drag_clear()


func cleanup() -> void:
	if hero.inventory.changed.is_connected(refresh):
		hero.inventory.changed.disconnect(refresh)
	if hero.stats_changed.is_connected(refresh):
		hero.stats_changed.disconnect(refresh)
	if hero.gold_changed.is_connected(_gold_callback):
		hero.gold_changed.disconnect(_gold_callback)


func _sell(it: Item) -> void:
	hero.inventory.remove(it)
	hero.add_gold(int(it.sell_value() * hero.sell_multiplier()))
	Sfx.play(&"coins")


func _sell_junk() -> void:
	var to_sell: Array[Item] = []
	for it in hero.inventory.items:
		if it.rarity <= Item.Rarity.MAGIC:
			to_sell.append(it)
	var total := 0
	for it in to_sell:
		total += int(it.sell_value() * hero.sell_multiplier())
		hero.inventory.remove(it)
	if total > 0:
		hero.add_gold(total)
		Sfx.play(&"coins")
		if hud:
			hud.show_message("Vendido por %d de ouro" % total, Color(1, 0.85, 0.3))


## Equipa item da mochila instantaneamente (shift+clique)
func equip_from_inventory(it: Item) -> void:
	var problem := hero.equip_problem(it)
	if problem != "":
		if hud:
			hud.show_message(problem, Color(1, 0.5, 0.4))
		return
	hero.inventory.remove(it)
	for old in hero.equip(it):
		if not hero.inventory.add(old):
			drop_to_floor(old)
	Sfx.play(&"equip")
	if hud:
		hud.show_message("Equipado: %s" % it.name, Color(0.4, 1, 0.4))
	hide_tooltip()
	_grid_view.queue_redraw()


## Desequipa para a mochila instantaneamente (shift+clique no slot)
func unequip_to_inventory(slot: String) -> void:
	var it: Item = hero.equipment.get(slot) if slot in hero.equipment else null
	if it == null:
		return
	hero.unequip(slot)
	if not hero.inventory.add(it):
		hero.equip(it)  # sem espaço: volta pro slot
		if hud:
			hud.show_message("Inventário cheio", Color(1, 0.5, 0.4))
		return
	Sfx.play(&"cloth")
	_grid_view.queue_redraw()


## Vende item instantaneamente (ctrl+clique)
func sell_item(it: Item) -> void:
	_sell(it)
	if hud:
		hud.show_message("Vendido: %s (+%d ouro)" % [it.name, int(it.sell_value() * hero.sell_multiplier())], Color(1, 0.9, 0.4))


# ================================================================== GRADE

class _GridView extends Control:
	var panel: InventoryPanel
	var _hover_cell: Vector2i = Vector2i(-1, -1)
	var _drop_target_cell: Vector2i = Vector2i(-1, -1)
	var _drop_valid: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _cell_at(p: Vector2) -> Vector2i:
		return Vector2i(floori(p.x / InventoryPanel.CELL), floori(p.y / InventoryPanel.CELL))

	func _gui_input(event: InputEvent) -> void:
		var inv := panel.hero.inventory
		
		if event is InputEventMouseMotion:
			var mp := (event as InputEventMouseMotion).position  # posição do evento (local ao controle)
			var cell := _cell_at(mp)
			_hover_cell = cell
			
			var drag_item: Item = panel._get_drag_item()
			panel.show_tooltip(inv.item_at(cell) if drag_item == null else drag_item)
			
			# Atualiza preview de drop
			if panel.is_dragging() and panel._drag.source in ["grid", "equip"] and drag_item:
				_drop_target_cell = cell
				_drop_valid = inv.in_bounds(drag_item, cell) and inv.overlapping(drag_item, cell).size() <= 1
			else:
				_drop_target_cell = Vector2i(-1, -1)
				_drop_valid = false
			queue_redraw()

		elif event is InputEventMouseButton and event.pressed:
			var cell := _cell_at(event.position)
			var it := inv.item_at(cell)
			
			# Shift+clique: equipa instantaneamente
			if event.button_index == MOUSE_BUTTON_LEFT and event.shift_pressed and it:
				panel.equip_from_inventory(it)
				accept_event()
				return
			
			# Ctrl+clique: vende instantaneamente
			if event.button_index == MOUSE_BUTTON_LEFT and event.ctrl_pressed and it:
				panel.sell_item(it)
				accept_event()
				return
			
			# Botão esquerdo: arraste
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Inicia arraste da grade
				if not panel.is_dragging():
					if it:
						panel.drag_from_grid(it, cell, event.global_position)
						queue_redraw()
						accept_event()
						return
				
				# Solta item arrastado na grade
				if panel.is_dragging() and panel._drag.source in ["grid", "equip"]:
					panel._drop_on_grid(cell)
					accept_event()
					return
			
			# Botão direito: sem ação (shift+clique/ctrl+clique substituem)

		elif event is InputEventMouseButton and not event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT and panel.is_dragging():
				# Release: solta na célula sob o cursor (press-hold-release padrão)
				if _drop_target_cell != Vector2i(-1, -1) and _drop_valid:
					panel._drop_on_grid(_drop_target_cell)
				else:
					panel._cancel_drag()
				queue_redraw()
				accept_event()

		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			if panel.is_dragging():
				panel._cancel_drag()
				queue_redraw()
				accept_event()

	func _anchor_for(it: Item, mouse: Vector2) -> Vector2i:
		var c := InventoryPanel.CELL
		var top_left := mouse - Vector2(it.size) * c * 0.5
		return Vector2i(roundi(top_left.x / c), roundi(top_left.y / c))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT:
			_hover_cell = Vector2i(-1, -1)
			_drop_target_cell = Vector2i(-1, -1)
			_drop_valid = false
			panel.hide_tooltip()
			queue_redraw()

	func _draw() -> void:
		var inv := panel.hero.inventory
		var cs := InventoryPanel.CELL
		
		# Grade de fundo
		for x in inv.cols:
			for y in inv.rows:
				var r: Rect2 = Rect2(x * cs, y * cs, cs, cs)
				draw_rect(r.grow(-1), Color(0.08, 0.06, 0.05))
				draw_rect(r.grow(-1), Color(0.22, 0.17, 0.12), false, 1.0)
		
		# Highlight célula de drop válida
		if _drop_target_cell != Vector2i(-1, -1) and panel._get_drag_item():
			var r := Rect2(Vector2(_drop_target_cell) * cs, Vector2(panel._drag.item.size) * cs)
			draw_rect(r, Color(0.2, 0.8, 0.2, 0.3) if _drop_valid else Color(0.8, 0.1, 0.1, 0.3))
		
		# Itens na grade
		for it in inv.items:
			panel._draw_item(self, it, Rect2(Vector2(it.grid_pos) * cs, Vector2(it.size) * cs))
		
		# Preview do item segurado (legacy held)
		if panel.held:
			var mouse := get_local_mouse_position()
			if Rect2(Vector2.ZERO, size).has_point(mouse):
				var pos := _anchor_for(panel.held, mouse)
				var ok := inv.in_bounds(panel.held, pos) and inv.overlapping(panel.held, pos).size() <= 1
				draw_rect(Rect2(Vector2(pos) * cs, Vector2(panel.held.size) * cs), Color(0.2, 0.8, 0.2, 0.25) if ok else Color(0.8, 0.1, 0.1, 0.25))
		
		# Ghost do drag-and-drop
		if panel.is_dragging() and panel._drag.source in ["grid", "equip"] and panel._drag.ghost_visible and panel._get_drag_item():
			var mouse := get_local_mouse_position()
			var s: Vector2 = panel._drag.item.size * cs
			var ghost_rect := Rect2(mouse - s * 0.5, s)
			draw_rect(ghost_rect, Color(0.2, 0.2, 0.2, 0.3))
			panel._draw_item(self, panel._drag.item, ghost_rect)


# ================================================================== EQUIPAMENTO

class _EquipView extends Control:
	var panel: InventoryPanel
	var slot := "weapon"
	var _is_drop_target: bool = false
	var _drop_valid: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		var hero := panel.hero
		
		if event is InputEventMouseMotion:
			var equipped: Item = hero.equipment.get(slot) if slot in hero.equipment else null
			var drag_item: Item = panel._get_drag_item()
			panel.show_tooltip(drag_item if drag_item else equipped)
			
			# Atualiza preview de drop no slot
			if panel.is_dragging() and panel._drag.source == "grid":
				_is_drop_target = true
				var item: Item = panel._get_drag_item()
				_drop_valid = (item.slot == slot) and (hero.equip_problem(item) == "")
			else:
				_is_drop_target = false
				_drop_valid = false
			queue_redraw()

		elif event is InputEventMouseButton and event.pressed:
			# Shift+clique no slot: desequipa para a mochila
			if event.button_index == MOUSE_BUTTON_LEFT and event.shift_pressed and not panel.is_dragging():
				panel.unequip_to_inventory(slot)
				accept_event()
				return
			
			# Ctrl+clique no slot: vende o item equipado
			if event.button_index == MOUSE_BUTTON_LEFT and event.ctrl_pressed and not panel.is_dragging():
				var equipped: Item = hero.equipment.get(slot) if slot in hero.equipment else null
				if equipped:
					panel.sell_item(equipped)
				accept_event()
				return
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Drop de item da grade neste slot
				if panel.is_dragging() and panel._drag.source == "grid":
					panel._drop_on_slot(slot)
					accept_event()
					return
				
				# Legacy click-to-hold (item na mão)
				if panel.held:
					if panel.held.slot != slot:
						if panel.hud:
							panel.hud.show_message("Este item não vai neste espaço", Color(1, 0.5, 0.4))
					elif hero.equip_problem(panel.held) != "":
						if panel.hud:
							panel.hud.show_message(hero.equip_problem(panel.held), Color(1, 0.5, 0.4))
					else:
						var out := hero.equip(panel.held)
						panel.held = out.pop_front() if not out.is_empty() else null
						for extra in out:
							if not hero.inventory.add(extra):
								LootDrop.drop_item(panel.hud.world, panel.hud.world.player.global_position, extra)
						Sfx.play(&"equip")
				
				# Inicia arraste do slot de equip
				var equipped: Item = hero.equipment.get(slot) if slot in hero.equipment else null
				if equipped:
					panel.drag_from_equip(slot, event.global_position)
					accept_event()
					return
			
			# Botão direito: sem ação

		elif event is InputEventMouseButton and not event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT and panel.is_dragging():
				if _is_drop_target and _drop_valid:
					panel._drop_on_slot(slot)
				else:
					panel._cancel_drag()
				queue_redraw()
				accept_event()

		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			if panel.is_dragging():
				panel._cancel_drag()
				queue_redraw()
				accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT:
			_is_drop_target = false
			_drop_valid = false
			panel.hide_tooltip()
			queue_redraw()

	func _draw() -> void:
		var r: Rect2 = Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.05, 0.035, 0.03))
		
		var is_drag_source: bool = panel.is_dragging() and panel._drag.source == "equip" and panel._drag.slot == slot
		var highlight: bool = panel.held != null and panel.held.slot == slot or is_drag_source
		
		# Highlight de drop target
		if _is_drop_target:
			draw_rect(r.grow(2), Color(0.2, 0.8, 0.2, 0.5) if _drop_valid else Color(0.8, 0.1, 0.1, 0.5))
			draw_rect(r.grow(2), Color(0.2, 0.8, 0.2) if _drop_valid else Color(0.8, 0.1, 0.1), false, 3.0)
		elif highlight:
			draw_rect(r, UIKit.GOLD, false, 2.0)
		else:
			draw_rect(r, UIKit.GOLD_DIM, false, 2.0)
		
		var it: Item = panel.hero.equipment.get(slot) if slot in panel.hero.equipment else null
		if it and not is_drag_source:
			panel._draw_item(self, it, r.grow(-3))
		
		# Ghost do drag-and-drop (desenha no viewport global)
		if is_drag_source and panel._drag.ghost_visible and panel._get_drag_item():
			var mp := get_local_mouse_position()
			panel._draw_item(self, panel._drag.item, Rect2(mp.x - size.x * 0.5, mp.y - size.y * 0.5, size.x, size.y))
		
		if not it and not is_drag_source:
			var f := UIKit.FONT_BODY
			var txt: String = DB.SLOT_NAMES.get(slot, slot)
			if txt == "Mão Secundária":
				txt = "Secundária"
			elif txt == "Acessório 1":
				txt = "Acess. 1"
			elif txt == "Acessório 2":
				txt = "Acess. 2"
			elif txt == "Acessório 3":
				txt = "Acess. 3"
			draw_string(f, Vector2(0, size.y * 0.5 + 4), txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0.45, 0.4, 0.35))