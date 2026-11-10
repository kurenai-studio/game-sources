class_name SkillTreePanel
extends PanelContainer
## Painel da Árvore de Habilidades: canvas procedural com linhas entre nós,
## pan (botão do meio) e zoom (roda do mouse, 0.75-1.5x). MECANICAS #9.3.

## Preloads para type hints funcionarem em parse time
const SkillTreeDataRes := preload("res://scripts/data/skill_tree_data.gd")
const SkillNodeDataRes := preload("res://scripts/data/skill_node_data.gd")

## Canvas interno que desenha as linhas de conexão (draw válido só no _draw)
class TreeCanvas extends Control:
	var panel: SkillTreePanel
	func _draw() -> void:
		if panel:
			panel._draw_connections(self)

var hud: HUD
var hero: Hero
var _tree: SkillTreeDataRes
var _viewport: Control          ## clip_contents = true; recebe o input de pan/zoom
var _world: Control             ## mundo pan/zoomável (scale = _zoom)
var _lines: TreeCanvas
var _points_label: RichTextLabel
var _reset_btn: Button
var _nodes_ui: Dictionary = {}  # node_id -> {container, button, icon, rank, style, pos, node}
var _tooltip: Control
var _zoom := 1.0
const MIN_ZOOM := 0.75
const MAX_ZOOM := 1.5
var _panning := false

const NODE_SIZE := 72.0
const COL_SPACING := 300.0
const ROW_SPACING := 160.0
const START_X := 120.0
const START_Y := 400.0
const WORLD_SIZE := Vector2(1600, 900)

const COLOR_LOCKED_BORDER := Color(0.4, 0.4, 0.4)
const COLOR_AVAILABLE_BORDER := Color(1, 0.85, 0.2)
const COLOR_LINE_LOCKED := Color(0.3, 0.3, 0.3, 0.5)


func setup(p_hud: HUD, p_hero: Hero) -> void:
	hud = p_hud
	hero = p_hero
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	add_child(body)

	# Barra superior: classe, pontos e respec
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	body.add_child(header)
	var title := UIKit.title(hero.cls.display_name, 20)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	_points_label = UIKit.rich("[center]Pontos: [color=#F0C060]%d[/color][/center]" % hero.tree_points)
	_points_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_points_label)
	_reset_btn = UIKit.button("Respec", func(): _on_respec_tree())
	_reset_btn.disabled = hero.tree_unlocked.is_empty()
	header.add_child(_reset_btn)

	# Canvas com clip + mundo interno (pan/zoom)
	_viewport = Control.new()
	_viewport.clip_contents = true
	_viewport.mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_viewport.custom_minimum_size = Vector2(700, 380)
	_viewport.gui_input.connect(_on_canvas_input)
	body.add_child(_viewport)
	_world = Control.new()
	_world.custom_minimum_size = WORLD_SIZE
	_viewport.add_child(_world)
	_lines = TreeCanvas.new()
	_lines.panel = self
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines.custom_minimum_size = WORLD_SIZE
	_world.add_child(_lines)

	_tree = DB.get_skill_tree(hero.cls.id)
	if not _tree:
		var msg := UIKit.label("Árvore de habilidades não disponível para %s" % hero.cls.display_name, 16, UIKit.TEXT_DIM)
		msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		msg.size_flags_vertical = Control.SIZE_EXPAND_FILL
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		body.add_child(msg)
		return

	_build_tree_ui()
	if not hero.stats_changed.is_connected(_update_points):
		hero.stats_changed.connect(_update_points)
	_update_points()
	call_deferred("_center_view")


func _build_tree_ui() -> void:
	for child in _world.get_children():
		if child != _lines:
			child.queue_free()
	_nodes_ui.clear()
	if not _tree:
		return
	var depths := _calculate_depths()
	var columns: Dictionary = {}
	for node_id in depths:
		var d: int = depths[node_id]
		if not columns.has(d):
			columns[d] = []
		columns[d].append(node_id)
	var max_depth := 0
	for d in columns.keys():
		max_depth = maxi(max_depth, d)
	for d in range(max_depth + 1):
		if not columns.has(d):
			continue
		var col: Array = columns[d]
		var col_x: float = START_X + d * COL_SPACING
		var col_start_y: float = START_Y - (col.size() - 1) * ROW_SPACING * 0.5
		for i in col.size():
			var node: SkillNodeDataRes = _tree.get_node(col[i])
			if node:
				_create_node_ui(node, Vector2(col_x, col_start_y + i * ROW_SPACING))
	_lines.queue_redraw()


## Profundidade = coluna; pré-requisitos à esquerda, lá no depth+1 à direita
func _calculate_depths() -> Dictionary:
	var depths: Dictionary = {}
	var visited: Dictionary = {}
	var stack: Array = []
	for n in _tree.nodes:
		if n.requires.is_empty():
			stack.append({"id": n.id, "depth": 0})
	while not stack.is_empty():
		var item: Dictionary = stack.pop_back()
		var id: StringName = item.id
		var depth: int = item.depth
		depths[id] = maxi(depths.get(id, -1000000), depth)
		if visited.has(id):
			continue
		visited[id] = true
		var node := _tree.get_node(id)
		if not node:
			continue
		for req in node.requires:
			stack.append({"id": req, "depth": depth - 1})
		for dep in _tree.get_dependent_nodes(id):
			stack.append({"id": dep.id, "depth": depth + 1})
	var min_depth := 1000000
	for d in depths.values():
		min_depth = mini(min_depth, d)
	if min_depth < 0:
		for k in depths.keys():
			depths[k] += -min_depth
	return depths


func _create_node_ui(node: SkillNodeDataRes, pos: Vector2) -> void:
	var container := Control.new()
	container.name = "Node_%s" % node.id
	container.position = pos
	container.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
	_world.add_child(container)

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 32
	style.corner_radius_top_right = 32
	style.corner_radius_bottom_left = 32
	style.corner_radius_bottom_right = 32
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(64, 64)
	btn.position = Vector2(4, 4)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.add_theme_stylebox_override("focus", style)
	container.add_child(btn)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.position = Vector2(8, 8)
	icon.texture = DB.icon(node.icon)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)

	# Rank sempre visível (0/N antes da primeira compra)
	var rank := Label.new()
	rank.custom_minimum_size = Vector2(64, 20)
	rank.position = Vector2(0, 52)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.add_theme_font_size_override("font_size", 12)
	rank.add_theme_color_override("font_color", Color(1, 1, 0.5))
	container.add_child(rank)

	btn.mouse_entered.connect(func(): _show_tooltip(node, btn))
	btn.mouse_exited.connect(func(): _hide_tooltip())
	btn.pressed.connect(func(): _on_node_pressed(node))

	_nodes_ui[node.id] = {"container": container, "button": btn, "icon": icon, "rank": rank, "style": style, "pos": pos, "node": node}
	_update_node_ui(node.id)


func _update_node_ui(node_id: StringName) -> void:
	if not _nodes_ui.has(node_id):
		return
	var ui: Dictionary = _nodes_ui[node_id]
	var node: SkillNodeDataRes = ui["node"]
	var rank: int = hero.get_tree_node_rank(node_id)
	var unlocked := rank > 0
	var available := node.is_available(hero.tree_unlocked)
	var style: StyleBoxFlat = ui["style"]
	if unlocked:
		style.bg_color = Color(0.25, 0.18, 0.06, 0.95)
		style.border_color = UIKit.ACCENT_GOLD
		ui["icon"].modulate = Color.WHITE
		ui["button"].disabled = rank >= node.max_rank
	elif available:
		style.bg_color = Color(0.3, 0.2, 0.05, 0.95)
		style.border_color = COLOR_AVAILABLE_BORDER
		ui["icon"].modulate = Color.WHITE
		ui["button"].disabled = false
	else:
		style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
		style.border_color = COLOR_LOCKED_BORDER
		ui["icon"].modulate = Color(0.5, 0.5, 0.5)
		ui["button"].disabled = true
	ui["rank"].text = "%d/%d" % [rank, node.max_rank]


func _draw_connections(c: Control) -> void:
	if not _tree or _nodes_ui.is_empty():
		return
	for node_id in _nodes_ui:
		var ui: Dictionary = _nodes_ui[node_id]
		var node: SkillNodeDataRes = ui["node"]
		var from: Vector2 = ui["pos"] + Vector2(36, 36)
		for req_id in node.requires:
			if not _nodes_ui.has(req_id):
				continue
			var to: Vector2 = _nodes_ui[req_id]["pos"] + Vector2(36, 36)
			# Dourado = pré-requisito desbloqueado; cinza = bloqueado
			var color: Color = UIKit.ACCENT_GOLD if req_id in hero.tree_unlocked else COLOR_LINE_LOCKED
			var mid_x := (from.x + to.x) * 0.5
			var p1 := from
			var p2 := Vector2(mid_x, from.y)
			var p3 := Vector2(mid_x, to.y)
			var p4 := to
			var prev := p1
			for i in range(1, 11):
				var t := float(i) / 10.0
				var u := 1.0 - t
				var curr := Vector2(
					u*u*u*p1.x + 3*u*u*t*p2.x + 3*u*t*t*p3.x + t*t*t*p4.x,
					u*u*u*p1.y + 3*u*u*t*p2.y + 3*u*t*t*p3.y + t*t*t*p4.y)
				c.draw_line(prev, curr, color, 2.0)
				prev = curr


func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(_zoom * 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(_zoom / 1.1)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = true
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		_panning = false
	elif event is InputEventMouseMotion and _panning:
		_world.position += event.relative
		_clamp_pan()


func _set_zoom(z: float) -> void:
	_zoom = clampf(z, MIN_ZOOM, MAX_ZOOM)
	_world.scale = Vector2(_zoom, _zoom)
	_clamp_pan()
	_lines.queue_redraw()


func _clamp_pan() -> void:
	var vp := _viewport.size
	_world.position.x = clampf(_world.position.x, minf(0.0, vp.x - WORLD_SIZE.x * _zoom), 0.0)
	_world.position.y = clampf(_world.position.y, minf(0.0, vp.y - WORLD_SIZE.y * _zoom), 0.0)


func _center_view() -> void:
	_clamp_pan()
	_world.position = (Vector2(_viewport.size) - WORLD_SIZE * _zoom) * 0.5
	_clamp_pan()


func _on_node_pressed(node: SkillNodeDataRes) -> void:
	if hero.spend_tree_point(node.id):
		Sfx.play(&"click")
		refresh()
		if hud:
			hud.show_message("%s adquirido! (Rank %d)" % [node.display_name, hero.get_tree_node_rank(node.id)], Color(0.4, 1, 0.4), 1.5)
	elif hud:
		if hero.tree_points <= 0:
			hud.show_message("Sem pontos de árvore!", Color(1, 0.4, 0.4), 1.5)
		elif not node.is_available(hero.tree_unlocked):
			hud.show_message("Pré-requisitos não atendidos", Color(1, 0.5, 0.3), 2.0)
		else:
			hud.show_message("Nó no rank máximo!", Color(1, 0.7, 0.3), 1.5)


func _on_respec_tree() -> void:
	hero.respec_tree()
	Sfx.play(&"click")
	refresh()
	if hud:
		hud.show_message("Pontos de árvore resetados!", Color(1, 0.9, 0.4), 1.5)


func _update_points() -> void:
	if _points_label:
		_points_label.text = "[center]Pontos: [color=#F0C060]%d[/color][/center]" % hero.tree_points


func _show_tooltip(node: SkillNodeDataRes, btn: Button) -> void:
	if hud == null:
		return
	_hide_tooltip()
	_tooltip = Control.new()
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_tooltip)
	_tooltip.position = btn.get_global_position() + Vector2(75, -10)
	var panel := PanelContainer.new()
	var style := UIKit.box(Color(0.06, 0.05, 0.03, 0.98), Color(0.7, 0.6, 0.2), 1, 8)
	panel.add_theme_stylebox_override("panel", style)
	_tooltip.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)
	var rank: int = hero.get_tree_node_rank(node.id)
	content.add_child(UIKit.rich("[font_size=18][color=#F0C060]%s[/color][/font_size]  [color=#9A917F]%d/%d[/color]" % [node.display_name, rank, node.max_rank]))
	if node.description != "":
		var desc := UIKit.rich(node.description)
		desc.add_theme_color_override("default_color", UIKit.TEXT_DIM)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.custom_minimum_size = Vector2(260, 0)
		content.add_child(desc)
	if not node.requires.is_empty():
		var reqs: Array = []
		for req_id in node.requires:
			var req_node := _tree.get_node(req_id)
			if req_node:
				reqs.append(req_node.display_name)
		content.add_child(UIKit.rich("[color=#9A917F]Requer: %s[/color]" % ", ".join(reqs)))


func _hide_tooltip() -> void:
	if _tooltip:
		_tooltip.queue_free()
		_tooltip = null


## Atualiza a UI (pontos, estados dos nós, linhas)
func refresh() -> void:
	_update_points()
	for node_id in _nodes_ui:
		_update_node_ui(node_id)
	if _reset_btn:
		_reset_btn.disabled = hero.tree_unlocked.is_empty()
	_lines.queue_redraw()


func cleanup() -> void:
	if hero and hero.stats_changed.is_connected(_update_points):
		hero.stats_changed.disconnect(_update_points)
	_hide_tooltip()
