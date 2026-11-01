# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Renders the review images in docs/art/ with the src/theme/ code: a grid map
## in portrait (Fold5 cover screen) and on the Fold5 inner screen shape, the
## comparison with the theme slice, the silhouette sheets, the map pieces,
## every gate look, a strip at true cover screen size, the wordmark and the
## icon previews.
## Needs a display, so run it without --headless, from the repo root:
##     godot --path . --script res://tools/icon/art_review.gd
## Review images only: nothing here ships. Display names in the labels are the
## proposals in docs/art/NAMES.md.

const OUT: String = "res://docs/art/"
const CELL: float = 128.0
## Logical window sizes (1080 x 2400 base, canvas_items stretch, expand).
const COVER: Vector2i = Vector2i(1080, 2767)
const INNER: Vector2i = Vector2i(1998, 2400)
## Physical pixels per logical pixel on the cover screen (904 / 1080).
const COVER_PHYSICAL: float = 904.0 / 1080.0

const GRID: PackedStringArray = [
	"...1...",
	".o.#.o.",
	".#####.",
	".#.o.#.",
	"oG...#o",
	".#.o.#.",
	".#####.",
	".o.#.o.",
	"...#...",
	".#####.",
	".#.o.G.",
	".#####.",
	"..oBo..",
]
const GATE_CELL: Vector2i = Vector2i(1, 4)
const OPEN_SOCKET: Vector2i = Vector2i(5, 10)

const NAMES: Dictionary[StringName, String] = {
	&"sling_post": "Sling Post", &"pumpkin_catapult": "Pumpkin Catapult", &"lullaby_bell": "Lullaby Bell",
	&"longbow_loft": "Longbow Loft", &"firework_tower": "Firework Tower", &"bakery": "Bakery",
	&"scamp": "Scamp", &"pip": "Pip", &"skitter": "Skitter", &"flitter": "Flitter", &"shellback": "Shellback",
	&"bubbler": "Bubbler", &"puffball": "Puffball", &"puff": "Puff", &"mender": "Mender",
	&"gatecrasher": "Gatecrasher", &"dusk_moth": "Dusk Moth", &"grumblesack": "Grumblesack",
	&"ironshell": "Ironshell", &"moon_moth": "Moon Moth", &"old_tusk": "Old Tusk",
}
const JOBS: Dictionary[StringName, String] = {
	&"sling_post": "quick single target", &"pumpkin_catapult": "splash", &"lullaby_bell": "slows walkers",
	&"longbow_loft": "long range, ignores armor", &"firework_tower": "anti air", &"bakery": "boosts neighbors",
	&"scamp": "basic", &"pip": "swarm", &"skitter": "fast", &"flitter": "flyer", &"shellback": "armored",
	&"bubbler": "bubble", &"puffball": "splits", &"puff": "from a Puffball", &"mender": "heals",
	&"gatecrasher": "breaks gates", &"dusk_moth": "armored flyer", &"grumblesack": "boss 1",
	&"ironshell": "boss 2", &"moon_moth": "boss 3", &"old_tusk": "boss 4",
}
const SPEC_NAMES: Dictionary[StringName, String] = {
	&"quickshot": "Quickshot", &"stone_sling": "Stone Sling", &"prize_pumpkin": "Prize Pumpkin", &"jam_pot": "Jam Pot",
	&"hush_bell": "Hush Bell", &"night_bell": "Night Bell", &"giant_bow": "Giant Bow", &"triple_bow": "Triple Bow",
	&"star_bloom": "Star Bloom", &"skyrocket": "Skyrocket", &"grand_oven": "Grand Oven", &"spice_kitchen": "Spice Kitchen",
}
## The first four regions' cast, which these images show. The later regions'
## cast is on the expansion sheets (docs/art/EXPANSION_LOOK.md).
const CAST_TOWERS: Array[StringName] = [&"sling_post", &"pumpkin_catapult", &"lullaby_bell", &"longbow_loft", &"firework_tower", &"bakery"]
const CAST_CREATURES: Array[StringName] = [&"scamp", &"pip", &"skitter", &"flitter", &"shellback", &"bubbler", &"puffball", &"puff", &"mender", &"gatecrasher", &"dusk_moth"]
const CAST_BOSSES: Array[StringName] = [&"grumblesack", &"ironshell", &"moon_moth", &"old_tusk"]
## Per tower in CAST_TOWERS.
const COSTS: Array[int] = [100, 120, 90, 150, 110, 130]


## A node that draws through a callable, so each picture is a few lines.
class Painter extends Node2D:
	var paint: Callable

	func _draw() -> void:
		paint.call(self)


## A small Control that draws a tower or glyph inside its rect.
class Icon extends Control:
	var paint: Callable

	func _draw() -> void:
		paint.call(self, Rect2(Vector2.ZERO, size))


var _theme: Theme


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("art_review.gd needs a display. Run it without --headless.")
		quit(1)
		return
	_theme = UiTheme.build()
	var portrait_wave: Image = await _render(COVER, _battle_scene(COVER, false, false))
	_save(portrait_wave, "grid_portrait.png", 0.5)
	var portrait_build: Image = await _render(COVER, _battle_scene(COVER, false, true))
	_save(portrait_build, "grid_portrait_build.png", 0.5)
	var inner: Image = await _render(INNER, _battle_scene(INNER, true, false))
	_save(inner, "grid_fold_inner.png", 0.5)
	_save(portrait_wave.get_region(Rect2i(0, 236, 1080, 1100)), "grid_cover_actual_size.png", COVER_PHYSICAL)
	_save_comparison(portrait_wave)
	_save(await _render(Vector2i(1800, 1460), _sheet_scene(Vector2(1800, 1460))), "silhouettes.png", 1.0)
	_save(await _render(Vector2i(1800, 1600), _tiers_scene(Vector2(1800, 1600))), "tiers.png", 1.0)
	_save(await _render(Vector2i(1800, 1320), _pieces_scene(Vector2(1800, 1320))), "map_pieces.png", 1.0)
	_save(await _render(Vector2i(2560, 1420), _gate_looks_scene(Vector2(2560, 1420))), "gate_looks.png", 1.0)
	_save(await _render(Vector2i(1660, 800), _cover_strip_scene(Vector2(1660, 800))), "cover_actual_size.png", 1.0)
	_save(await _render(Vector2i(1200, 420), _wordmark_scene(Vector2(1200, 420))), "wordmark.png", 1.0)
	await _icon_preview()
	quit(0)


# Rendering.

func _render(size: Vector2i, content: Node) -> Image:
	var vp: SubViewport = SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.add_child(content)
	root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _save(img: Image, file_name: String, scale: float) -> void:
	var out: Image = img.duplicate() as Image
	if scale != 1.0:
		out.resize(int(img.get_width() * scale), int(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var err: Error = out.save_png(OUT + file_name)
	print("%s%s %dx%d: %s" % [OUT, file_name, out.get_width(), out.get_height(), error_string(err)])


## The slice's portrait screenshot next to the grid version, same height.
func _save_comparison(grid_img: Image) -> void:
	var slice: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + "slice_portrait.png"))
	if slice == null:
		print("slice_portrait.png missing; no comparison")
		return
	slice.convert(Image.FORMAT_RGBA8)
	var h: int = 1200
	var right: Image = grid_img.duplicate() as Image
	right.resize(int(float(grid_img.get_width()) * float(h) / float(grid_img.get_height())), h, Image.INTERPOLATE_LANCZOS)
	var left: Image = slice.duplicate() as Image
	left.resize(int(float(slice.get_width()) * float(h) / float(slice.get_height())), h, Image.INTERPOLATE_LANCZOS)
	var gap: int = 24
	var out: Image = Image.create(left.get_width() + right.get_width() + gap, h, false, Image.FORMAT_RGBA8)
	out.fill(Palette.CARD)
	out.blit_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), Vector2i.ZERO)
	out.blit_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), Vector2i(left.get_width() + gap, 0))
	_save(out, "grid_vs_slice.png", 1.0)


# The battle mock: the 7 x 13 grid map with HUD, in either layout.

func _battle_scene(size: Vector2i, landscape: bool, build: bool) -> Control:
	var root_c: Control = Control.new()
	root_c.size = Vector2(size)
	root_c.theme = _theme
	var map_rect: Rect2
	var side: Rect2
	if landscape:
		var top: float = 60.0
		var bottom: float = 170.0
		var cell: float = (float(size.y) - top - bottom) / 13.0
		map_rect = Rect2(24.0, top, cell * 7.0, cell * 13.0)
		side = Rect2(map_rect.end.x + 32.0, top, float(size.x) - map_rect.end.x - 56.0, map_rect.size.y)
	else:
		var cell: float = float(size.x) / 7.0
		map_rect = Rect2(0.0, 236.0, float(size.x), cell * 13.0)
		side = Rect2(24.0, map_rect.end.y + 12.0, float(size.x) - 48.0, float(size.y) - map_rect.end.y - 12.0 - 30.0)
	var bg: Painter = Painter.new()
	bg.paint = func(ci: CanvasItem) -> void: _sky(ci, Vector2(size), map_rect)
	root_c.add_child(bg)
	var map: Node2D = Node2D.new()
	map.position = map_rect.position
	map.scale = Vector2.ONE * (map_rect.size.x / (CELL * 7.0))
	root_c.add_child(map)
	_fill_map(map, build)
	if landscape:
		_hud_landscape(root_c, side, build)
	else:
		_hud_portrait(root_c, Rect2(24.0, 88.0, float(size.x) - 48.0, 136.0), side, build)
	return root_c


func _sky(ci: CanvasItem, vs: Vector2, map_rect: Rect2) -> void:
	var horizon: float = map_rect.position.y + 10.0
	var stops: Array[float] = [0.0, horizon * 0.45, horizon * 0.8, horizon]
	var cols: Array[Color] = [Palette.SKY_TOP, Palette.SKY_MID, Palette.SKY_LOW, Palette.SKY_GLOW]
	for i: int in 3:
		ci.draw_polygon(PackedVector2Array([Vector2(0, stops[i]), Vector2(vs.x, stops[i]), Vector2(vs.x, stops[i + 1]), Vector2(0, stops[i + 1])]),
			PackedColorArray([cols[i], cols[i], cols[i + 1], cols[i + 1]]))
	ci.draw_rect(Rect2(0, horizon, vs.x, vs.y - horizon), Palette.HILL_NEAR)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in 50:
		ci.draw_circle(Vector2(rng.randf() * vs.x, rng.randf() * horizon * 0.7), rng.randf_range(1.5, 3.5), Color(Palette.STAR, rng.randf_range(0.4, 0.9)), true, -1.0, true)
	var hills: PackedVector2Array = PackedVector2Array([Vector2(0, horizon + 4)])
	var x: float = 0.0
	while x <= vs.x + 30.0:
		hills.append(Vector2(x, horizon - 40.0 - 26.0 * sin(x * 0.004 + 1.3)))
		x += 30.0
	hills.append(Vector2(vs.x + 30.0, horizon + 4))
	ci.draw_colored_polygon(hills, Palette.HILL_FAR)


func _fill_map(map: Node2D, build: bool) -> void:
	var ground: Painter = Painter.new()
	ground.paint = func(ci: CanvasItem) -> void:
		MapArt.draw_ground(ci, GRID, CELL, UiTheme.font(UiTheme.WEIGHT_BOLD))
		MapArt.draw_gate(ci, GRID, GATE_CELL, CELL, MapArt.Gate.CLOSED)
		MapArt.draw_gate(ci, GRID, OPEN_SOCKET, CELL, MapArt.Gate.SOCKET)
	map.add_child(ground)
	var route_pts: PackedVector2Array = MapArt.route_points(_route(GRID, [GATE_CELL], false), CELL)
	if build:
		var lines: Painter = Painter.new()
		lines.paint = func(ci: CanvasItem) -> void:
			MapArt.draw_route(ci, MapArt.route_points(_route(GRID, [GATE_CELL], true), CELL), CELL, MapArt.Route.BREAK, 0.5)
			MapArt.draw_route(ci, route_pts, CELL, MapArt.Route.WALK)
			MapArt.draw_route(ci, PackedVector2Array([_c(Vector2i(3, 0)), _c(Vector2i(3, 12))]), CELL, MapArt.Route.FLY)
			MapArt.draw_highlight(ci, Vector2i(0, 4), CELL, 1.0)
			MapArt.draw_highlight(ci, Vector2i(2, 12), CELL, 0.5)
			MapArt.draw_highlight(ci, Vector2i(4, 12), CELL, 0.5)
		map.add_child(lines)
	var towers: Array[Array] = [
		[Vector2i(1, 1), &"sling_post", 1, -1], [Vector2i(5, 1), &"pumpkin_catapult", 1, -1],
		[Vector2i(3, 3), &"lullaby_bell", 2, -1], [Vector2i(6, 4), &"longbow_loft", 1, -1],
		[Vector2i(3, 5), &"bakery", 1, -1], [Vector2i(1, 7), &"firework_tower", 1, -1],
		[Vector2i(5, 7), &"sling_post", 3, 0], [Vector2i(3, 10), &"pumpkin_catapult", 3, 1],
	]
	var items: Array[Array] = []
	for t: Array in towers:
		var at: Vector2i = t[0]
		items.append([_c(at).y + CELL * 0.3, "tower", t])
	if not build:
		var walkers: Array[Array] = [
			[0.4, &"pip"], [0.75, &"pip"], [1.05, &"pip"], [2.4, &"skitter"], [3.6, &"scamp"], [4.6, &"shellback"],
			[5.8, &"scamp"], [7.0, &"bubbler"], [8.4, &"puffball"], [9.6, &"mender"], [10.9, &"gatecrasher"],
			[12.6, &"puff"], [12.95, &"puff"], [14.2, &"scamp"],
		]
		var lengths: PackedFloat32Array = _cumulative(route_pts)
		for w: Array in walkers:
			var d: float = float(w[0]) * CELL
			var p: Vector2 = _point_at(route_pts, lengths, d)
			var ahead: Vector2 = _point_at(route_pts, lengths, d + 4.0)
			items.append([p.y, "enemy", [w[1], p, ahead.x < p.x - 0.5]])
		items.append([_c(Vector2i(4, 5)).y, "enemy", [&"flitter", _c(Vector2i(3, 0)).lerp(_c(Vector2i(3, 12)), 0.36) + Vector2(CELL * 0.62, 0), false]])
		items.append([_c(Vector2i(2, 8)).y, "enemy", [&"dusk_moth", _c(Vector2i(3, 0)).lerp(_c(Vector2i(3, 12)), 0.6) + Vector2(-CELL * 0.7, 0), false]])
	items.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for item: Array in items:
		var node: Painter = Painter.new()
		var data: Array = item[2]
		if item[1] == "tower":
			var at: Vector2i = data[0]
			node.position = _c(at)
			node.paint = func(ci: CanvasItem) -> void:
				Silhouettes.draw_tower(ci, data[1], data[2], data[3], Vector2.ZERO, CELL)
				if at == Vector2i(5, 7):
					Silhouettes.draw_boost(ci, Vector2.ZERO, CELL)
		else:
			var type: StringName = data[0]
			var at_p: Vector2 = data[1]
			var size: float = Silhouettes.enemy_size(type, CELL)
			node.position = at_p
			if bool(data[2]):
				node.scale = Vector2(-1, 1)
			var frame: int = int(at_p.x + at_p.y) % 4
			node.paint = func(ci: CanvasItem) -> void:
				Silhouettes.draw_enemy(ci, type, Vector2.ZERO, size, frame)
				if type == &"bubbler":
					Silhouettes.draw_bubble(ci, Vector2.ZERO, size)
				if type == &"shellback" or type == &"skitter":
					Silhouettes.draw_drowsy(ci, Vector2.ZERO, size, frame)
				if type == &"shellback" or type == &"scamp" or type == &"mender":
					var w: float = size * 0.7
					var bar: Rect2 = Rect2(-w * 0.5, -size * 0.62, w, size * 0.09)
					ci.draw_rect(bar.grow(3.0), Palette.HP_BACK)
					ci.draw_rect(Rect2(bar.position, Vector2(w * 0.6, bar.size.y)), Palette.HP_FILL)
		map.add_child(node)
	if not build:
		var fx: Painter = Painter.new()
		fx.paint = func(ci: CanvasItem) -> void:
			var from: Vector2 = _c(Vector2i(5, 7)) + Vector2(0, -CELL * 0.62)
			var to: Vector2 = _point_at(route_pts, _cumulative(route_pts), 5.8 * CELL) + Vector2(0, -CELL * 0.1)
			ci.draw_line(from, to, Color(Palette.LANTERN, 0.4), 10.0, true)
			ci.draw_line(from.lerp(to, 0.6), to, Palette.LANTERN_CORE, 4.0, true)
			var pen: InkPen = InkPen.new(ci)
			pen.begin(Vector2.ZERO, 1.0)
			for i: int in 6:
				var a: float = TAU * float(i) / 6.0
				pen.star(to + Vector2(cos(a), sin(a)) * 30.0, 11.0, Palette.SPARKLE if i % 2 == 0 else Palette.SPARKLE_LILAC)
		map.add_child(fx)


func _c(at: Vector2i) -> Vector2:
	return (Vector2(at) + Vector2(0.5, 0.5)) * CELL


## The walkers' route from entrance 1 to the base, with the RULES.md 7.3 tie
## break (south, west, east, north). `ignore_gates` gives the breaker's route.
func _route(grid: PackedStringArray, closed: Array[Vector2i], ignore_gates: bool) -> Array[Vector2i]:
	var rows: int = grid.size()
	var dist: Dictionary[Vector2i, int] = {}
	var base: Vector2i = Vector2i(-1, -1)
	var start: Vector2i = Vector2i(-1, -1)
	for r: int in rows:
		for c: int in 7:
			if grid[r][c] == "B":
				base = Vector2i(c, r)
			if grid[r][c] == "1":
				start = Vector2i(c, r)
	var dirs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]
	var queue: Array[Vector2i] = [base]
	dist[base] = 0
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		for d: Vector2i in dirs:
			var n: Vector2i = cur + d
			if n.x < 0 or n.y < 0 or n.x >= 7 or n.y >= rows or dist.has(n):
				continue
			if "#G1234B".find(grid[n.y][n.x]) < 0:
				continue
			if not ignore_gates and closed.has(n):
				continue
			dist[n] = dist[cur] + 1
			queue.append(n)
	var out: Array[Vector2i] = [start]
	var at: Vector2i = start
	while at != base:
		for d: Vector2i in dirs:
			var n: Vector2i = at + d
			if dist.has(n) and dist[n] == dist[at] - 1:
				at = n
				break
		out.append(at)
	return out


func _cumulative(pts: PackedVector2Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array([0.0])
	for i: int in range(1, pts.size()):
		out.append(out[i - 1] + pts[i - 1].distance_to(pts[i]))
	return out


func _point_at(pts: PackedVector2Array, lengths: PackedFloat32Array, d: float) -> Vector2:
	for i: int in range(1, pts.size()):
		if lengths[i] >= d:
			var seg: float = lengths[i] - lengths[i - 1]
			return pts[i - 1].lerp(pts[i], 0.0 if seg <= 0.0 else (d - lengths[i - 1]) / seg)
	return pts[pts.size() - 1]


# HUD mock-ups built from UiTheme controls.

func _hud_portrait(root_c: Control, top: Rect2, bottom: Rect2, build: bool) -> void:
	var stats: PanelContainer = _stats_bar()
	stats.position = top.position
	stats.size = top.size
	root_c.add_child(stats)
	var col: VBoxContainer = VBoxContainer.new()
	col.position = bottom.position
	col.size = bottom.size
	col.add_theme_constant_override(&"separation", 10)
	root_c.add_child(col)
	col.add_child(_hint(build))
	var cards: HBoxContainer = HBoxContainer.new()
	cards.add_theme_constant_override(&"separation", 10)
	cards.custom_minimum_size = Vector2(0, 168)
	col.add_child(cards)
	for i: int in CAST_TOWERS.size():
		cards.add_child(_card(CAST_TOWERS[i], i == 0 and build, i == 3))
	col.add_child(_buttons(build))


func _hud_landscape(root_c: Control, side: Rect2, build: bool) -> void:
	var col: VBoxContainer = VBoxContainer.new()
	col.position = side.position
	col.size = side.size
	col.add_theme_constant_override(&"separation", 22)
	root_c.add_child(col)
	var stats: PanelContainer = _stats_bar()
	stats.custom_minimum_size = Vector2(0, 140)
	col.add_child(stats)
	var preview: PanelContainer = PanelContainer.new()
	var pv: VBoxContainer = VBoxContainer.new()
	preview.add_child(pv)
	var title: Label = Label.new()
	title.text = "Next: wave 4"
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override(&"font_size", 56)
	pv.add_child(title)
	for row: Array in [[&"scamp", "Scamp", "x 8"], [&"pip", "Pip", "x 12"], [&"flitter", "Flitter", "x 3"]]:
		var h: HBoxContainer = HBoxContainer.new()
		h.add_theme_constant_override(&"separation", 18)
		var ic: Icon = Icon.new()
		ic.custom_minimum_size = Vector2(96, 96)
		var t: StringName = row[0]
		ic.paint = func(ci: CanvasItem, r: Rect2) -> void: Silhouettes.draw_enemy(ci, t, r.get_center(), r.size.y * 0.95, 0)
		h.add_child(ic)
		var name_l: Label = Label.new()
		name_l.text = row[1]
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(name_l)
		var count_l: Label = Label.new()
		count_l.text = row[2]
		h.add_child(count_l)
		var from_l: Label = Label.new()
		from_l.text = "from A"
		from_l.theme_type_variation = &"SoftLabel"
		h.add_child(from_l)
		for l: Label in [name_l, count_l, from_l]:
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pv.add_child(h)
	col.add_child(preview)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 14)
	grid.add_theme_constant_override(&"v_separation", 14)
	for i: int in CAST_TOWERS.size():
		var card: Button = _card(CAST_TOWERS[i], false, i == 3)
		card.custom_minimum_size = Vector2(0, 230)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
	col.add_child(grid)
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	col.add_child(_hint(build))
	var buttons: HBoxContainer = _buttons(build)
	for b: Button in [buttons.get_child(0) as Button, buttons.get_child(1) as Button]:
		b.custom_minimum_size = Vector2(160, 160)
	(buttons.get_child(2) as Button).text = "Start wave 4" if build else "Call early"
	col.add_child(buttons)


func _stats_bar() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	panel.add_child(row)
	for item: Array in [[&"heart", "20"], [&"coin", "135"], [&"moon", "Wave 3/12"]]:
		var ic: Icon = Icon.new()
		ic.custom_minimum_size = Vector2(64, 64)
		var g: StringName = item[0]
		ic.paint = func(ci: CanvasItem, r: Rect2) -> void: Silhouettes.draw_glyph(ci, g, r.get_center(), r.size.y * 0.9)
		row.add_child(ic)
		var l: Label = Label.new()
		l.text = item[1]
		l.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_BOLD))
		l.add_theme_font_size_override(&"font_size", 50)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
	return panel


func _hint(build: bool) -> PanelContainer:
	var hint: PanelContainer = PanelContainer.new()
	var l: Label = Label.new()
	l.text = "Tap a glowing spot to build." if build else "Gates stay put until the wave ends."
	l.add_theme_font_size_override(&"font_size", UiTheme.FONT_SMALL)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_child(l)
	return hint


func _card(type: StringName, selected: bool, dim: bool) -> Button:
	var b: Button = Button.new()
	b.theme_type_variation = &"CardButton"
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if dim:
		b.disabled = true
	if selected:
		b.toggle_mode = true
		b.button_pressed = true
	var v: VBoxContainer = VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 8
	v.offset_bottom = -6
	v.add_theme_constant_override(&"separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var ic: Icon = Icon.new()
	ic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ic.paint = func(ci: CanvasItem, r: Rect2) -> void:
		var cell: float = minf(r.size.y * 0.9, r.size.x * 0.95)
		Silhouettes.draw_tower(ci, type, 1, -1, r.get_center() + Vector2(0, cell * 0.12), cell)
	v.add_child(ic)
	var cost: Label = Label.new()
	cost.text = "%d" % COSTS[CAST_TOWERS.find(type)]
	cost.theme_type_variation = &"CardMutedLabel"
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_BOLD))
	v.add_child(cost)
	return b


func _buttons(build: bool) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	row.custom_minimum_size = Vector2(0, 160)
	for text: String in ["Pause", "1x"]:
		var b: Button = Button.new()
		b.text = text
		b.custom_minimum_size = Vector2(190, 160)
		row.add_child(b)
	var go: Button = Button.new()
	go.theme_type_variation = &"PrimaryButton"
	go.text = "Start wave 4" if build else "Call early +12"
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(go)
	return row


# Sheets.

func _sheet_base(size: Vector2, title: String, sub: String) -> Control:
	var root_c: Control = Control.new()
	root_c.size = size
	root_c.theme = _theme
	var bg: ColorRect = ColorRect.new()
	bg.color = Palette.CARD
	bg.size = size
	root_c.add_child(bg)
	var t: Label = Label.new()
	t.text = title
	t.theme_type_variation = &"CardLabel"
	t.add_theme_font_size_override(&"font_size", 54)
	t.position = Vector2(40, 18)
	root_c.add_child(t)
	var s: Label = Label.new()
	s.text = sub
	s.theme_type_variation = &"CardMutedLabel"
	s.add_theme_font_size_override(&"font_size", 30)
	s.position = Vector2(40, 90)
	root_c.add_child(s)
	return root_c


func _label(parent: Control, text: String, center: Vector2, width: float, font_size: int, muted: bool) -> void:
	var l: Label = Label.new()
	l.text = text
	l.theme_type_variation = &"CardMutedLabel" if muted else &"CardLabel"
	l.add_theme_font_size_override(&"font_size", font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(center.x - width * 0.5, center.y)
	l.size = Vector2(width, font_size * 1.4)
	parent.add_child(l)


func _band(parent: Control, r: Rect2, col: Color) -> void:
	var p: Panel = Panel.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(26)
	p.add_theme_stylebox_override(&"panel", sb)
	p.position = r.position
	p.size = r.size
	parent.add_child(p)


func _sheet_scene(size: Vector2) -> Control:
	var root_c: Control = _sheet_base(size, "Forkline silhouettes", "Every tower at tier 1, every creature and boss: in color, then in one flat color. Each must read by shape alone.")
	var w: float = size.x - 80.0
	var tw: float = w / 6.0
	var cw: float = w / 11.0
	var bw: float = w / 8.0
	_band(root_c, Rect2(40, 140, w, 250), Palette.MEADOW)
	_band(root_c, Rect2(40, 700, w, 170), Palette.ROAD)
	_band(root_c, Rect2(40, 1110, w, 250), Palette.ROAD)
	for i: int in 6:
		var t: StringName = CAST_TOWERS[i]
		var x: float = 40.0 + tw * (float(i) + 0.5)
		_label(root_c, NAMES[t], Vector2(x, 395), tw, 32, false)
		_label(root_c, JOBS[t], Vector2(x, 437), tw, 24, true)
	for i: int in 11:
		var t: StringName = CAST_CREATURES[i]
		var x: float = 40.0 + cw * (float(i) + 0.5)
		_label(root_c, NAMES[t], Vector2(x, 875), cw + 20.0, 26, false)
		_label(root_c, JOBS[t], Vector2(x, 910), cw + 20.0, 20, true)
	for i: int in 4:
		var t: StringName = CAST_BOSSES[i]
		var x: float = 40.0 + bw * (float(i) * 2.0 + 1.0)
		_label(root_c, NAMES[t], Vector2(x, 1365), bw * 2.0, 30, false)
		_label(root_c, JOBS[t], Vector2(x, 1405), bw * 2.0, 22, true)
	var art: Painter = Painter.new()
	art.z_index = 1
	art.paint = func(ci: CanvasItem) -> void:
		for i: int in 6:
			var x: float = 40.0 + tw * (float(i) + 0.5)
			var t: StringName = CAST_TOWERS[i]
			MapArt.draw_spot(ci, Vector2(x, 290), 190.0)
			Silhouettes.draw_tower(ci, t, 1, -1, Vector2(x, 290), 190.0)
			Silhouettes.draw_tower(ci, t, 1, -1, Vector2(x, 600), 152.0, Palette.INK_LINE)
		for i: int in 11:
			var x: float = 40.0 + cw * (float(i) + 0.5)
			var t: StringName = CAST_CREATURES[i]
			var cs: float = Silhouettes.enemy_size(t, 180.0)
			Silhouettes.draw_enemy(ci, t, Vector2(x, 840 - cs * Silhouettes.FEET), cs, 0)
			Silhouettes.draw_enemy(ci, t, Vector2(x, 1078 - cs * Silhouettes.FEET), cs, 0, Palette.INK_LINE)
		for i: int in 4:
			var t: StringName = CAST_BOSSES[i]
			var bs: float = Silhouettes.enemy_size(t, 150.0)
			Silhouettes.draw_enemy(ci, t, Vector2(40.0 + bw * (float(i) * 2.0 + 0.5), 1330 - bs * Silhouettes.FEET), bs, 0)
			Silhouettes.draw_enemy(ci, t, Vector2(40.0 + bw * (float(i) * 2.0 + 1.5), 1330 - bs * Silhouettes.FEET), bs, 0, Palette.INK_LINE)
	root_c.add_child(art)
	return root_c


func _tiers_scene(size: Vector2) -> Control:
	var root_c: Control = _sheet_base(size, "Tiers and paths", "Each tier adds a stone step. At tier 3 the path replaces the signature piece. Left: color. Right: one flat color.")
	var label_w: float = 220.0
	var col_w: float = (size.x - 80.0 - label_w) / 8.0
	var row_h: float = 232.0
	var top: float = 150.0
	var heads: Array[String] = ["Tier 1", "Tier 2", "Path A", "Path B"]
	for k: int in 8:
		_label(root_c, heads[k % 4], Vector2(40.0 + label_w + col_w * (float(k) + 0.5), top), col_w, 26, true)
	for i: int in 6:
		var t: StringName = CAST_TOWERS[i]
		var y: float = top + 40.0 + row_h * float(i)
		_band(root_c, Rect2(40.0 + label_w, y, col_w * 4.0 - 10.0, 176.0), Palette.MEADOW)
		var l: Label = Label.new()
		l.text = NAMES[t]
		l.theme_type_variation = &"CardLabel"
		l.add_theme_font_size_override(&"font_size", 30)
		l.position = Vector2(40, y + 40)
		l.size = Vector2(label_w - 10.0, 40)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root_c.add_child(l)
		var specs: Array = Silhouettes.SPECS[t]
		for k: int in 2:
			_label(root_c, SPEC_NAMES[specs[k]], Vector2(40.0 + label_w + col_w * (float(k) + 2.5), y + 178.0), col_w + 20.0, 22, false)
			_label(root_c, SPEC_NAMES[specs[k]], Vector2(40.0 + label_w + col_w * (float(k) + 6.5), y + 178.0), col_w + 20.0, 22, true)
	var art: Painter = Painter.new()
	art.z_index = 1
	art.paint = func(ci: CanvasItem) -> void:
		for i: int in 6:
			var t: StringName = CAST_TOWERS[i]
			var y: float = top + 40.0 + row_h * float(i)
			for k: int in 8:
				var x: float = 40.0 + label_w + col_w * (float(k) + 0.5)
				var tier: int = [1, 2, 3, 3][k % 4]
				var spec: int = [-1, -1, 0, 1][k % 4]
				var c: Vector2 = Vector2(x, y + 108.0)
				if k < 4:
					Silhouettes.draw_tower(ci, t, tier, spec, c, 140.0)
				else:
					Silhouettes.draw_tower(ci, t, tier, spec, c, 140.0, Palette.INK_LINE)
	root_c.add_child(art)
	return root_c


func _pieces_scene(size: Vector2) -> Control:
	var root_c: Control = _sheet_base(size, "Map pieces and signals", "Gates on a road running down and on one running across, spots, the base, an entrance, route lines and status marks.")
	var cell: float = 110.0
	# Every gate look, in narrower columns so they fit left of the route lines.
	var gate_cell: float = 74.0
	for k: int in MapArt.Gate.size():
		_label(root_c, String(MapArt.Gate.keys()[k]).capitalize(), Vector2(170.0 + 230.0 * float(k), 820), 220.0, 28, false)
	var labels: Array[String] = ["Empty spot", "Hint, selection", "Base", "Entrance A"]
	for k: int in labels.size():
		_label(root_c, labels[k], Vector2(205.0 + 300.0 * float(k), 1240), 290.0, 26, false)
	_label(root_c, "Walkers, breakers, flyers", Vector2(1610.0, 820), 320.0, 26, false)
	_label(root_c, "Drowsy, bubble, boost", Vector2(1610.0, 1240), 320.0, 26, false)
	var art: Painter = Painter.new()
	art.z_index = 1
	art.paint = func(ci: CanvasItem) -> void:
		var down: PackedStringArray = [".#.", ".G.", ".#."]
		var across: PackedStringArray = ["...", "#G#", "..."]
		for k: int in MapArt.Gate.size():
			var x0: float = 170.0 + 230.0 * float(k) - gate_cell * 1.5
			_mini(ci, down, Vector2(x0, 194.0), gate_cell, null)
			MapArt.draw_gate(ci, down, Vector2i(1, 1), gate_cell, k as MapArt.Gate)
			_end_mini(ci)
			_mini(ci, across, Vector2(x0, 534.0), gate_cell, null)
			MapArt.draw_gate(ci, across, Vector2i(1, 1), gate_cell, k as MapArt.Gate)
			_end_mini(ci)
		var spot: PackedStringArray = ["...", ".o.", "..."]
		_mini(ci, spot, Vector2(205.0 - cell * 1.5, 890.0), cell, null)
		_end_mini(ci)
		_mini(ci, spot, Vector2(505.0 - cell * 1.5, 890.0), cell, null)
		MapArt.draw_highlight(ci, Vector2i(1, 1), cell)
		_end_mini(ci)
		_mini(ci, PackedStringArray([".#.", ".#.", ".B."]), Vector2(805.0 - cell * 1.5, 890.0), cell, null)
		_end_mini(ci)
		_mini(ci, PackedStringArray(["...", ".1.", ".#."]), Vector2(1105.0 - cell * 1.5, 890.0), cell, UiTheme.font(UiTheme.WEIGHT_BOLD))
		_end_mini(ci)
		ci.draw_rect(Rect2(1450, 140, 320, 660), Palette.MEADOW)
		for k: int in 3:
			var x0: float = 1490.0 + 100.0 * float(k)
			var pts: PackedVector2Array = PackedVector2Array([Vector2(x0, 780), Vector2(x0, 520), Vector2(x0 + 30, 480), Vector2(x0 + 60, 480), Vector2(x0 + 60, 170)])
			if k == 2:
				pts = PackedVector2Array([Vector2(x0, 780), Vector2(x0 + 60, 170)])
			MapArt.draw_route(ci, pts, cell, k as MapArt.Route)
		ci.draw_rect(Rect2(1450, 890, 320, 330), Palette.ROAD)
		var cs: float = Silhouettes.enemy_size(&"scamp", 150.0)
		Silhouettes.draw_enemy(ci, &"scamp", Vector2(1520, 1000), cs, 0)
		Silhouettes.draw_drowsy(ci, Vector2(1520, 1000), cs, 0)
		cs = Silhouettes.enemy_size(&"bubbler", 150.0)
		Silhouettes.draw_enemy(ci, &"bubbler", Vector2(1690, 1010), cs, 0)
		Silhouettes.draw_bubble(ci, Vector2(1690, 1010), cs)
		Silhouettes.draw_tower(ci, &"sling_post", 1, -1, Vector2(1600, 1140), 110.0)
		Silhouettes.draw_boost(ci, Vector2(1600, 1140), 110.0)
	root_c.add_child(art)
	return root_c


## Every gate look side by side at true Fold5 cover size, on a road running
## down and one running across, then in one flat color.
func _gate_looks_scene(size: Vector2) -> Control:
	var root_c: Control = _sheet_base(size, "Gate looks", "MapArt.Gate at true size on the Fold5 cover screen: one cell is 129 screen pixels (49 dp). Road running down, road running across, then one flat color.")
	var when: Array[String] = ["empty, a gate can go here", "placed, blocks walkers", "Twist or Iron Gate", "until the next build phase", "would close every road", "under Gateless Night"]
	var cell: float = 154.0 * COVER_PHYSICAL
	var col_w: float = (size.x - 120.0) / float(MapArt.Gate.size())
	for k: int in MapArt.Gate.size():
		var cx: float = 60.0 + col_w * (float(k) + 0.5)
		_label(root_c, String(MapArt.Gate.keys()[k]).capitalize(), Vector2(cx, 160), col_w, 38, false)
		_label(root_c, when[k] if k < when.size() else "", Vector2(cx, 212), col_w, 26, true)
	var art: Painter = Painter.new()
	art.z_index = 1
	art.paint = func(ci: CanvasItem) -> void:
		var down: PackedStringArray = [".#.", ".G.", ".#."]
		var across: PackedStringArray = ["...", "#G#", "..."]
		for k: int in MapArt.Gate.size():
			var cx: float = 60.0 + col_w * (float(k) + 0.5)
			var look: MapArt.Gate = k as MapArt.Gate
			_mini(ci, down, Vector2(cx - cell * 1.5, 270.0), cell, null)
			MapArt.draw_gate(ci, down, Vector2i(1, 1), cell, look)
			_end_mini(ci)
			_mini(ci, across, Vector2(cx - cell * 1.5, 700.0), cell, null)
			MapArt.draw_gate(ci, across, Vector2i(1, 1), cell, look)
			_end_mini(ci)
			MapArt.draw_gate_at(ci, Vector2(cx - cell * 0.6, 1290.0), cell, true, look, Palette.INK_LINE)
			MapArt.draw_gate_at(ci, Vector2(cx + cell * 0.6, 1290.0), cell, false, look, Palette.INK_LINE)
	root_c.add_child(art)
	return root_c


func _mini(ci: CanvasItem, grid: PackedStringArray, origin: Vector2, cell: float, font: Font) -> void:
	ci.draw_set_transform(origin, 0.0, Vector2.ONE)
	MapArt.draw_ground(ci, grid, cell, font)


func _end_mini(ci: CanvasItem) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _cover_strip_scene(size: Vector2) -> Control:
	var root_c: Control = _sheet_base(size, "At true size on the Fold5 cover screen", "One map cell is 129 screen pixels here (49 dp). Every tower at tier 1, creature and boss, in color and in one flat color.")
	var art: Painter = Painter.new()
	art.z_index = 1
	var cell: float = 154.0 * COVER_PHYSICAL
	art.paint = func(ci: CanvasItem) -> void:
		ci.draw_rect(Rect2(20, 140, size.x - 40.0, 160), Palette.MEADOW)
		for i: int in 6:
			var x: float = 90.0 + cell * float(i)
			Silhouettes.draw_tower(ci, CAST_TOWERS[i], 1, -1, Vector2(x, 215), cell)
			Silhouettes.draw_tower(ci, CAST_TOWERS[i], 1, -1, Vector2(x + 6.0 * cell + 40.0, 215), cell, Palette.INK_LINE)
		ci.draw_rect(Rect2(20, 320, size.x - 40.0, 110), Palette.ROAD)
		var x: float = 50.0
		for t: StringName in CAST_CREATURES:
			var cs: float = Silhouettes.enemy_size(t, cell)
			x += cs * 0.5
			Silhouettes.draw_enemy(ci, t, Vector2(x, 375), cs, 0)
			Silhouettes.draw_enemy(ci, t, Vector2(x, 490), cs, 0, Palette.INK_LINE)
			x += cs * 0.5 + 12.0
		ci.draw_rect(Rect2(20, 570, size.x - 40.0, 190), Palette.ROAD)
		x = 60.0
		for t: StringName in CAST_BOSSES:
			var bs: float = Silhouettes.enemy_size(t, cell)
			Silhouettes.draw_enemy(ci, t, Vector2(x + bs * 0.5, 670), bs, 0)
			Silhouettes.draw_enemy(ci, t, Vector2(x + bs * 1.5 + 10.0, 670), bs, 0, Palette.INK_LINE)
			x += bs * 2.0 + 60.0
	root_c.add_child(art)
	return root_c


func _wordmark_scene(size: Vector2) -> Control:
	var root_c: Control = Control.new()
	root_c.size = size
	var bg: Painter = Painter.new()
	bg.paint = func(ci: CanvasItem) -> void:
		ci.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
			PackedColorArray([Palette.SKY_TOP, Palette.SKY_TOP, Palette.SKY_MID, Palette.SKY_MID]))
	root_c.add_child(bg)
	var mark: Wordmark = Wordmark.new()
	mark.position = Vector2(60, 40)
	mark.size = size - Vector2(120, 80)
	root_c.add_child(mark)
	return root_c


# Icon previews: the full icon, the adaptive layers under round and squircle
# masks, the themed monochrome icon, and the icon at 48 pixels.

func _icon_preview() -> void:
	var full: Image = await IconArt.draw(512)
	var fg: Image = await IconArt.draw_layer(432, IconArt.Layer.FOREGROUND)
	var bg: Image = await IconArt.draw_layer(432, IconArt.Layer.BACKGROUND)
	var mono: Image = await IconArt.draw_layer(432, IconArt.Layer.MONOCHROME)
	var adaptive: Image = bg.duplicate() as Image
	adaptive.blend_rect(fg, Rect2i(0, 0, 432, 432), Vector2i.ZERO)
	# The launcher shows the middle 72 of 108 dp: crop to 288 px, then mask.
	var view: Image = adaptive.get_region(Rect2i(72, 72, 288, 288))
	var round_icon: Image = _masked(view, 1.0)
	var squircle: Image = _masked(view, 0.42)
	var themed: Image = Image.create(288, 288, false, Image.FORMAT_RGBA8)
	var mono_view: Image = mono.get_region(Rect2i(72, 72, 288, 288))
	for y: int in 288:
		for x: int in 288:
			var a: float = mono_view.get_pixel(x, y).a
			themed.set_pixel(x, y, Color("3b4a3f").lerp(Color("cfe8d2"), a))
	themed = _masked(themed, 1.0)
	var small: Image = full.duplicate() as Image
	small.resize(48, 48, Image.INTERPOLATE_LANCZOS)
	var out: Image = Image.create(512 + 288 * 3 + 48 + 5 * 24, 560, false, Image.FORMAT_RGBA8)
	out.fill(Palette.CARD)
	out.blit_rect(full, Rect2i(0, 0, 512, 512), Vector2i(24, 24))
	var x: int = 512 + 48
	for img: Image in [round_icon, squircle, themed]:
		out.blend_rect(img, Rect2i(0, 0, 288, 288), Vector2i(x, 136))
		x += 288 + 24
	out.blit_rect(small, Rect2i(0, 0, 48, 48), Vector2i(x, 256))
	_save(out, "icon_preview.png", 1.0)
	_save(full, "icon_512.png", 1.0)
	_save(small, "icon_512_48.png", 1.0)


## Masks a square image: `roundness` 1 is a circle, lower is a squircle.
func _masked(img: Image, roundness: float) -> Image:
	var out: Image = img.duplicate() as Image
	var n: float = 2.0 + (1.0 - roundness) * 6.0
	var h: float = float(img.get_width()) * 0.5
	for y: int in img.get_height():
		for x: int in img.get_width():
			var dx: float = absf((float(x) + 0.5 - h) / h)
			var dy: float = absf((float(y) + 0.5 - h) / h)
			var d: float = pow(pow(dx, n) + pow(dy, n), 1.0 / n)
			var a: float = clampf((1.0 - d) * h, 0.0, 1.0)
			var c: Color = out.get_pixel(x, y)
			out.set_pixel(x, y, Color(c, c.a * a))
	return out
