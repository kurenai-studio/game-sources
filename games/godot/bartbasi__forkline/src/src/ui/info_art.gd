# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name InfoArt
extends Control
## The small real examples in the Info guide. Each one is drawn by the same
## src/theme/ code the game uses, so what the guide shows is what the player
## will see (the creatures section shows the bosses too). Kinds: walk, hud, spots, tiers, towers, creatures, features,
## gates, signals, stars. The towers, creatures and features kinds draw the ids they are given (from the catalog and
## the levels, never from a fixed list), and nothing when given none. Captions (names under towers and creatures) are optional: the guide
## passes them only when the data has names, and draws shapes alone otherwise. A name
## wraps onto two lines when it must, and the pictures go three to a row when the names
## need the room, so a name is never cut off and never shrinks below CAPTION_SIZE.

## Height of each kind as a share of its width.
const RATIOS: Dictionary[StringName, float] = {
	&"walk": 0.4286, &"hud": 0.30, &"spots": 0.36, &"tiers": 0.30, &"towers": 0.34,
	&"creatures": 0.50, &"features": 0.34, &"gates": 0.7143, &"signals": 0.62, &"stars": 0.20,
}
## Caption text, in logical px. It never gets smaller than this.
const CAPTION_SIZE: int = 38
const CAPTION_LINE: float = 46.0
const MAX_PER_ROW: int = 6
const MIN_PER_ROW: int = 2
## The four map features (contract 14.1), in the order of the regions that bring them: fixed text,
## the small map each one is drawn on, and the ground of the region that brings it.
const FEATURE_IDS: Array[StringName] = [&"tunnel", &"bridge", &"slide", &"stumps"]
const FEATURE_NAMES: Dictionary[StringName, String] = {
	&"tunnel": "Tunnel", &"bridge": "Bridge", &"slide": "Ice slide", &"stumps": "Hollow stumps",
}
const FEATURE_GRIDS: Dictionary[StringName, PackedStringArray] = {
	&"tunnel": ["...", "#T#", "..."], &"bridge": [".#.", "#X#", ".#."],
	&"slide": [".v.", ".v.", ".#."], &"stumps": ["P#.", "...", ".#P"],
}
const FEATURE_GROUNDS: Dictionary[StringName, StringName] = {
	&"tunnel": &"hollow_lanes", &"bridge": &"russet_orchards", &"slide": &"frostpine_ridge", &"stumps": &"starglen",
}
const WALK_GRID: PackedStringArray = ["..o....", "1#####B", "....o.."]
const GATES_GRID: PackedStringArray = ["...1...", "...#...", ".#####.", ".G.o.G.", ".##B##."]
const GATES_ROUTE: Array[Vector2i] = [
	Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2),
	Vector2i(5, 3), Vector2i(5, 4), Vector2i(4, 4), Vector2i(3, 4),
]

var kind: StringName
var captions: PackedStringArray
var ids: Array[StringName] = []


func _init(art_kind: StringName, art_captions: PackedStringArray = PackedStringArray(), art_ids: Array[StringName] = []) -> void:
	kind = art_kind
	captions = art_captions
	ids = art_ids.duplicate()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


## The example is as tall as its kind needs for this width.
func fit_width(width: float) -> void:
	if _lists_ids():
		custom_minimum_size = Vector2(width, float(_grid(width)["height"]))
		return
	custom_minimum_size = Vector2(width, width * float(RATIOS.get(kind, 0.4)))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 0.0:
		return
	match kind:
		&"walk":
			_walk()
		&"hud":
			_hud()
		&"spots":
			_spots()
		&"tiers":
			_tiers()
		&"towers":
			_towers()
		&"creatures":
			_creatures()
		&"features":
			_features()
		&"gates":
			_gates()
		&"signals":
			_signals()
		&"stars":
			_stars()


# Examples.

func _walk() -> void:
	var cell: float = size.x / 7.0
	MapArt.draw_ground(self, WALK_GRID, cell)
	_walker(&"scamp", Vector2(3.4, 1.5), cell, 1)
	_walker(&"pip", Vector2(4.5, 1.5), cell, 2)
	_walker(&"skitter", Vector2(2.2, 1.5), cell, 3)


func _hud() -> void:
	var w: float = size.x
	var h: float = size.y
	var chip_w: float = (w - 2.0 * 24.0) / 3.0
	var chip_h: float = h * 0.42
	var glyphs: Array[StringName] = [&"heart", &"coin", &"moon"]
	var values: PackedStringArray = ["20", "150", "3 / 10"]
	for i: int in 3:
		var rect: Rect2 = Rect2(float(i) * (chip_w + 24.0), 0.0, chip_w, chip_h)
		_chip(rect, Palette.PANEL, Palette.PANEL_EDGE)
		Silhouettes.draw_glyph(self, glyphs[i], rect.position + Vector2(chip_h * 0.55, chip_h * 0.5), chip_h * 0.6)
		_text(values[i], rect.position + Vector2(chip_h * 1.05, chip_h * 0.5), UiTheme.FONT_BODY, Palette.TEXT_LIGHT, UiTheme.WEIGHT_BOLD)
	for i: int in 3:
		var rect: Rect2 = Rect2(float(i) * (chip_w + 24.0), h * 0.58, chip_w, chip_h)
		_chip(rect, Palette.PANEL_RAISED, Palette.HONEY if i == 0 else Palette.PANEL_EDGE)
		_text("%dx" % (i + 1), rect.get_center(), UiTheme.FONT_BODY, Palette.TEXT_LIGHT, UiTheme.WEIGHT_BOLD, true)


func _spots() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO, size), Palette.MEADOW)
	var cell: float = h * 0.62
	MapArt.draw_spot(self, Vector2(w * 0.2, h * 0.5), cell)
	_arrow(Vector2(w * 0.34, h * 0.5), Vector2(w * 0.5, h * 0.5))
	var tower_at: Vector2 = Vector2(w * 0.72, h * 0.5)
	draw_circle(tower_at, cell * 1.35, Color(Palette.ROUTE, 0.16))
	draw_arc(tower_at, cell * 1.35, 0.0, TAU, 64, Color(Palette.ROUTE, 0.9), 4.0, true)
	MapArt.draw_spot(self, tower_at, cell)
	Silhouettes.draw_tower(self, &"sling_post", 1, -1, tower_at, cell)


func _tiers() -> void:
	var w: float = size.x
	var h: float = size.y
	_card_background()
	var cell: float = w * 0.17
	var y: float = h * 0.62
	Silhouettes.draw_tower(self, &"sling_post", 1, -1, Vector2(w * 0.10, y), cell)
	_arrow(Vector2(w * 0.20, y), Vector2(w * 0.30, y), Palette.TEXT_MUTED)
	Silhouettes.draw_tower(self, &"sling_post", 2, -1, Vector2(w * 0.40, y), cell)
	_arrow(Vector2(w * 0.50, y), Vector2(w * 0.58, y), Palette.TEXT_MUTED)
	Silhouettes.draw_tower(self, &"sling_post", 3, 0, Vector2(w * 0.68, y), cell)
	_text("or", Vector2(w * 0.795, y), UiTheme.FONT_BODY, Palette.TEXT_MUTED, UiTheme.WEIGHT_BOLD, true)
	Silhouettes.draw_tower(self, &"sling_post", 3, 1, Vector2(w * 0.90, y), cell)


func _towers() -> void:
	_card_background()
	var g: Dictionary = _grid(size.x)
	var slot: float = g["slot"]
	for i: int in ids.size():
		var at: Vector2 = _slot_center(g, i)
		Silhouettes.draw_tower(self, ids[i], 1, -1, at, float(g["picture"]))
		_caption(i, at + Vector2(0.0, float(g["picture"]) * 0.62), slot, g)


func _creatures() -> void:
	_card_background()
	var g: Dictionary = _grid(size.x)
	var slot: float = g["slot"]
	for i: int in ids.size():
		var at: Vector2 = _slot_center(g, i)
		Silhouettes.draw_enemy(self, ids[i], at, Silhouettes.enemy_size(ids[i], float(g["picture"])), 1)
		_caption(i, at + Vector2(0.0, float(g["picture"]) * 0.62), slot, g)


## Each map feature on a small map of the ground of the region that brings it, with its name.
func _features() -> void:
	_card_background()
	var g: Dictionary = _grid(size.x)
	var slot: float = g["slot"]
	for i: int in ids.size():
		var at: Vector2 = _slot_center(g, i)
		var side: float = float(g["picture"])
		var cell: float = side / 3.0
		var grid: PackedStringArray = FEATURE_GRIDS.get(ids[i], PackedStringArray())
		if not grid.is_empty():
			draw_set_transform(at - Vector2(side, side) * 0.5)
			MapArt.draw_ground(self, grid, cell, null, FEATURE_GROUNDS.get(ids[i], &"lantern_hill"))
			MapArt.draw_features(self, grid, cell)
			draw_set_transform(Vector2.ZERO)
		_caption(i, at + Vector2(0.0, side * 0.62), slot, g)


func _gates() -> void:
	var cell: float = size.x / 7.0
	MapArt.draw_ground(self, GATES_GRID, cell)
	MapArt.draw_gate(self, GATES_GRID, Vector2i(1, 3), cell, MapArt.Gate.CLOSED)
	MapArt.draw_gate(self, GATES_GRID, Vector2i(5, 3), cell, MapArt.Gate.SOCKET)
	MapArt.draw_route(self, MapArt.route_points(GATES_ROUTE, cell), cell, MapArt.Route.WALK)
	_walker(&"scamp", Vector2(3.5, 0.55), cell, 1)


func _signals() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO, size), Palette.MEADOW)
	var cell: float = h * 0.2
	var styles: Array[MapArt.Route] = [MapArt.Route.WALK, MapArt.Route.BREAK, MapArt.Route.FLY]
	var names: PackedStringArray = ["Walkers", "Gate breakers", "Flyers"]
	for i: int in 3:
		var y: float = h * (0.12 + 0.18 * float(i))
		_chip(Rect2(w * 0.03, y - cell * 0.5, w * 0.36, cell), Palette.PANEL, Palette.PANEL_EDGE)
		_text(names[i], Vector2(w * 0.03 + 24.0, y), UiTheme.FONT_SMALL, Palette.TEXT_LIGHT, UiTheme.WEIGHT_BOLD)
		var points: PackedVector2Array = PackedVector2Array([Vector2(w * 0.43, y), Vector2(w * 0.95, y)])
		MapArt.draw_route(self, points, cell * 0.8, styles[i])
	var gate_y: float = h * 0.80
	var gate_cell: float = h * 0.24
	var gates: Array[MapArt.Gate] = [MapArt.Gate.REFUSED, MapArt.Gate.BROKEN]
	var gate_names: PackedStringArray = ["Refused", "Broken"]
	for i: int in 2:
		var x: float = w * (0.10 + 0.47 * float(i))
		MapArt.draw_gate_at(self, Vector2(x, gate_y), gate_cell, false, gates[i])
		_chip(Rect2(x + gate_cell * 0.6, gate_y - cell * 0.5, w * 0.28, cell), Palette.PANEL, Palette.PANEL_EDGE)
		_text(gate_names[i], Vector2(x + gate_cell * 0.6 + 24.0, gate_y), UiTheme.FONT_SMALL, Palette.TEXT_LIGHT, UiTheme.WEIGHT_BOLD)


func _stars() -> void:
	var w: float = size.x
	var h: float = size.y
	_card_background()
	var dim: Color = Color(Palette.TEXT_MUTED, 0.5)
	for i: int in 3:
		var flat: Color = Silhouettes.NO_FLAT if i < 2 else dim
		Silhouettes.draw_glyph(self, &"star", Vector2(w * (0.30 + 0.20 * float(i)), h * 0.5), h * 0.72, flat)


# Pieces.

func _walker(id: StringName, at_cell: Vector2, cell: float, frame: int) -> void:
	Silhouettes.draw_enemy(self, id, at_cell * cell, Silhouettes.enemy_size(id, cell), frame)


func _card_background() -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Palette.CARD
	box.set_corner_radius_all(UiTheme.RADIUS)
	box.set_border_width_all(3)
	box.border_color = Palette.INK_LINE
	draw_style_box(box, Rect2(Vector2.ZERO, size))


func _chip(rect: Rect2, fill: Color, edge: Color) -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(3)
	box.set_corner_radius_all(18)
	draw_style_box(box, rect)


func _arrow(from: Vector2, to: Vector2, color: Color = Palette.ROUTE) -> void:
	draw_line(from, to - Vector2(10.0, 0.0), color, 6.0, true)
	draw_colored_polygon(PackedVector2Array([to, to - Vector2(26.0, 16.0), to - Vector2(26.0, -16.0)]), color)


## True for the kinds that lay out one picture and caption per id.
func _lists_ids() -> bool:
	return kind == &"towers" or kind == &"creatures" or kind == &"features"


## How the pictures sit in `width`: pictures per row, the slot each gets, the picture
## size, each caption split into lines, the row height and the whole height. With names,
## the most pictures per row (6 down to 2) whose names fit their slot.
func _grid(width: float) -> Dictionary:
	var count: int = ids.size()
	if count == 0:
		return {"per_row": 1, "slot": width, "picture": 0.0, "lines": [] as Array[PackedStringArray], "row_height": 0.0, "rows": 0, "height": 0.0}
	var per_row: int = MAX_PER_ROW
	if not captions.is_empty():
		while per_row > MIN_PER_ROW and not _fit(_caption_lines(width / float(per_row) * 0.94), width / float(per_row) * 0.94):
			per_row -= 1
	# Rows of the same length: 6 pictures at 5 a row become 3 and 3, not 5 and 1.
	@warning_ignore("integer_division")
	var rows: int = (count + per_row - 1) / per_row
	@warning_ignore("integer_division")
	per_row = (count + rows - 1) / rows
	var slot: float = width / float(per_row)
	var lines: Array[PackedStringArray] = []
	if not captions.is_empty():
		lines = _caption_lines(slot * 0.94)
	var picture: float = minf(slot * 0.62, 190.0)
	var most: int = 0
	for l: PackedStringArray in lines:
		most = maxi(most, l.size())
	var row_height: float = picture * 1.3 + float(most) * CAPTION_LINE + 28.0
	return {
		"per_row": per_row, "slot": slot, "picture": picture, "lines": lines, "row_height": row_height,
		"rows": rows, "height": row_height * float(rows) + 20.0,
	}


## Where picture `index` is centered. A short last row is centered.
func _slot_center(g: Dictionary, index: int) -> Vector2:
	var per_row: int = g["per_row"]
	@warning_ignore("integer_division")
	var row: int = index / per_row
	var in_row: int = mini(per_row, ids.size() - row * per_row)
	var column: int = index - row * per_row
	var x: float = size.x * 0.5 + (float(column) - float(in_row - 1) * 0.5) * float(g["slot"])
	var y: float = 10.0 + float(g["row_height"]) * float(row) + float(g["picture"]) * 0.62
	return Vector2(x, y)


## Each caption split on spaces into lines that fit `max_width` where they can.
func _caption_lines(max_width: float) -> Array[PackedStringArray]:
	var font: Font = UiTheme.font(UiTheme.WEIGHT_BOLD)
	var out: Array[PackedStringArray] = []
	for text: String in captions:
		var lines: PackedStringArray = PackedStringArray()
		var line: String = ""
		for word: String in text.split(" ", false):
			var tried: String = word if line.is_empty() else "%s %s" % [line, word]
			if line.is_empty() or font.get_string_size(tried, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE).x <= max_width:
				line = tried
			else:
				lines.append(line)
				line = word
		if not line.is_empty():
			lines.append(line)
		out.append(lines)
	return out


func _fit(lines: Array[PackedStringArray], max_width: float) -> bool:
	var font: Font = UiTheme.font(UiTheme.WEIGHT_BOLD)
	for caption: PackedStringArray in lines:
		for line: String in caption:
			if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE).x > max_width:
				return false
	return true


## A caption, centered under its picture, one line per entry.
func _caption(index: int, at: Vector2, width: float, g: Dictionary) -> void:
	var all: Array = g["lines"]
	if index >= all.size():
		return
	var font: Font = UiTheme.font(UiTheme.WEIGHT_BOLD)
	var lines: PackedStringArray = all[index]
	for i: int in lines.size():
		var y: float = at.y + CAPTION_LINE * (float(i) + 0.5) + font.get_ascent(CAPTION_SIZE) * 0.3
		draw_string(font, Vector2(at.x - width * 0.5, y), lines[i], HORIZONTAL_ALIGNMENT_CENTER, width, CAPTION_SIZE, Palette.TEXT_DARK)


## Draws text with its vertical middle (or its center, when `centered`) at `at`.
func _text(text: String, at: Vector2, font_size: int, color: Color, weight: int, centered: bool = false) -> void:
	var font: Font = UiTheme.font(weight)
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x: float = at.x - width * 0.5 if centered else at.x
	var y: float = at.y + font.get_ascent(font_size) * 0.5 - font.get_descent(font_size) * 0.5
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
