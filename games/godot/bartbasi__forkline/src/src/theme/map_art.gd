# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name MapArt
extends RefCounted
## Draws the map on the 7 column grid (contract 2.2): each region's ground and
## scenery, roads, build spots, gate sockets and gates, the entrances and the
## base, route lines, and the map features (contract 14.9).
##
## Everything is drawn in the map's local space: cell (column, row) covers
## [column * cell, (column + 1) * cell] by [row * cell, (row + 1) * cell]. The
## grid is the level file's rows, one character per cell (`.` ground, `#` road,
## `G` road with a socket, `o` build spot, `1` to `4` entrance, `B` base, and
## the features: `T` tunnel, `X` bridge, `^ v < >` ice slide, `P Q` stumps).
##
## Roads are sandy bands through the cell centers. A cell where the road turns
## draws a quarter circle of radius half a cell, so turns are round. Forks and
## the base draw a round plaza. route_points() follows the same curves.
##
## The scenery is in SceneryArt and the features in FeatureArt, both internal.

enum Gate { SOCKET, CLOSED, FIXED, BROKEN, REFUSED, OPEN }
enum Route { WALK, BREAK, FLY }

## The 8 region grounds, in campaign order.
const GROUNDS: Array[StringName] = [&"lantern_hill", &"millbrook", &"willow_fen", &"moonspire_keep",
	&"hollow_lanes", &"russet_orchards", &"frostpine_ridge", &"starglen"]
## The road characters, the same as LevelData.ROAD_CHARS (contract 14.2).
const ROAD_CHARS: String = "#G1234BTX^v<>PQ"
## A run map's ground: the region of its first feature character.
const _FEATURE_GROUND: Dictionary[String, StringName] = {
	"T": &"hollow_lanes", "X": &"russet_orchards",
	"^": &"frostpine_ridge", "v": &"frostpine_ridge", "<": &"frostpine_ridge", ">": &"frostpine_ridge",
	"P": &"starglen", "Q": &"starglen",
}
const _SLIDES: String = "^v<>"

## Road band width and its border, as fractions of a cell.
const ROAD_WIDTH: float = 0.5
const ROAD_EDGE_WIDTH: float = 0.62
## Build spot pad: center below the cell center, and its half sizes.
const SPOT_DROP: float = 0.2
const SPOT_RX: float = 0.4
const SPOT_RY: float = 0.22
const ENTRANCE_LETTERS: String = "ABCD"

const _DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const _OVERLAP: float = 0.03


# The static map layer.

## The ground to draw a map on. `region` when it is one of GROUNDS. Otherwise
## (a run map, region &"") the region of the first feature character in
## reading order: T Hollow Lanes, X Russet Orchards, ^ v < > Frostpine Ridge,
## P Q Starglen. With no feature, Lantern Hill.
static func ground_of(region: StringName, grid: PackedStringArray) -> StringName:
	if GROUNDS.has(region):
		return region
	for line: String in grid:
		for i: int in line.length():
			if _FEATURE_GROUND.has(line[i]):
				return _FEATURE_GROUND[line[i]]
	return &"lantern_hill"


## Draws everything that does not move: the ground of `ground` (one of
## GROUNDS; any other id draws Lantern Hill) with its scenery, roads, ice
## slides with their chevrons, the road under a bridge and through a tunnel,
## spots, socket posts, entrance thickets and the base. Gates, route lines and
## the feature layer (draw_features) are drawn separately. With a font, each
## entrance gets its letter (A to D) on a sign.
static func draw_ground(canvas: CanvasItem, grid: PackedStringArray, cell: float, font: Font = null, ground: StringName = &"lantern_hill") -> void:
	var pen: InkPen = InkPen.new(canvas)
	ground_into(pen, grid, cell, ground)
	pen.begin(Vector2.ZERO, 1.0)
	var rows: int = grid.size()
	var cols: int = _cols(grid)
	for r: int in rows:
		for c: int in cols:
			var at: Vector2i = Vector2i(c, r)
			var ch: String = _char(grid, at)
			if ch >= "1" and ch <= "4":
				_thicket(pen, grid, at, cell)
				if font != null:
					_entrance_sign(canvas, pen, grid, at, cell, font, ENTRANCE_LETTERS[ch.to_int() - 1])
			elif ch == "B":
				draw_base(canvas, _center(at, cell), cell)


## The feature layer only: tunnel mounds with their mouths, bridge decks, and
## stumps with their symbols. It goes above the route lines and the walkers
## under a deck or inside a tunnel (contract 14.10). Ice slides are part of
## the ground.
static func draw_features(canvas: CanvasItem, grid: PackedStringArray, cell: float) -> void:
	features_into(InkPen.new(canvas), grid, cell)


## Draws the ground layer with `pen`, all but the entrance thickets, signs
## and the base. The tests record it with a pen that has no canvas. Internal
## to src/theme/ and its tests, like InkPen.
static func ground_into(pen: InkPen, grid: PackedStringArray, cell: float, ground: StringName) -> void:
	var g: StringName = ground if GROUNDS.has(ground) else &"lantern_hill"
	var road: Color = Palette.ground_color(g, "ROAD")
	pen.line_px = clampf(cell * 0.03, 1.2, 5.0)
	var cols: int = _cols(grid)
	var rows: int = grid.size()
	var size: Vector2 = Vector2(float(cols), float(rows)) * cell
	pen.begin(Vector2.ZERO, 1.0)
	pen.box(0.0, 0.0, size.x, size.y, Palette.ground_color(g, "GROUND"), false)
	# Lighter patches, then the roads over them.
	var light: Color = Color(Palette.ground_color(g, "GROUND_LIGHT"), 0.5)
	for r: int in rows:
		for c: int in cols:
			var h: int = _hash(c, r)
			if h % 5 == 0:
				var p: Vector2 = _center(Vector2i(c, r), cell) + Vector2(float(h % 7) - 3.0, float(h % 5) - 2.0) * cell * 0.08
				pen.detail_poly(InkPen.ellipse_pts(p, cell * (0.55 + float(h % 3) * 0.12), cell * 0.28, 20), light)
	if g == &"hollow_lanes":
		# Sunken lanes: a dark bank along both sides of every lane.
		_draw_roads(pen, grid, cell, 0.86, Palette.LANES_BANK)
	_draw_roads(pen, grid, cell, ROAD_EDGE_WIDTH, Palette.ground_color(g, "ROAD_EDGE"))
	_draw_roads(pen, grid, cell, ROAD_WIDTH, road)
	if g == &"willow_fen":
		# Boardwalks: two thin seams along the road, never across it, so no
		# seam looks like a gate's plank or a bridge deck's boards.
		_draw_roads(pen, grid, cell, 0.27, Palette.FEN_SEAM)
		_draw_roads(pen, grid, cell, 0.21, road)
	# Ice slides: pale ice with a blue border over the road.
	_draw_roads(pen, grid, cell, ROAD_EDGE_WIDTH, Palette.ICE_EDGE, true)
	_draw_roads(pen, grid, cell, ROAD_WIDTH, Palette.ICE, true)
	for r: int in rows:
		for c: int in cols:
			var at: Vector2i = Vector2i(c, r)
			var ch: String = _char(grid, at)
			pen.begin(Vector2.ZERO, 1.0)
			if ch.length() == 1 and _SLIDES.contains(ch):
				FeatureArt.chevrons(pen, _center(at, cell), cell, _slide_dir(ch))
			elif ch == "X":
				FeatureArt.bridge_shadow(pen, _center(at, cell), cell)
			elif _is_road(ch) and ch != "T" and _is_straight(grid, at) and g != &"willow_fen":
				_cobbles(pen, at, cell, Palette.ground_color(g, "ROAD_DOT"))
			if ch == "G":
				_socket_posts(pen, grid, at, cell)
			elif ch == "o":
				_spot_into(pen, _center(at, cell), cell)
	# Scenery, back to front.
	for r: int in rows:
		for c: int in cols:
			var at: Vector2i = Vector2i(c, r)
			if _char(grid, at) == ".":
				var near_road: bool = false
				for d: Vector2i in _DIRS:
					if _is_road(_char(grid, at + d)):
						near_road = true
				SceneryArt.draw(pen, _center(at, cell), cell, _hash(c, r), near_road, g)


## Draws the feature layer with `pen`. Internal to src/theme/ and its tests.
## A tunnel is a straight run of tunnel tiles: one mound covers the run.
static func features_into(pen: InkPen, grid: PackedStringArray, cell: float) -> void:
	pen.line_px = clampf(cell * 0.03, 1.2, 5.0)
	var done: Dictionary[Vector2i, bool] = {}
	for r: int in grid.size():
		for c: int in _cols(grid):
			var at: Vector2i = Vector2i(c, r)
			var ch: String = _char(grid, at)
			if ch == "T" and not done.has(at):
				var vertical: bool = _road_runs_vertically(grid, at)
				var step: Vector2i = Vector2i(0, 1) if vertical else Vector2i(1, 0)
				var last: Vector2i = at
				done[at] = true
				while _char(grid, last + step) == "T":
					last += step
					done[last] = true
				FeatureArt.tunnel(pen, at, last, vertical, cell)
			elif ch == "X":
				FeatureArt.bridge(pen, _center(at, cell), cell)
			elif ch == "P" or ch == "Q":
				FeatureArt.stump(pen, _center(at, cell), cell, ch == "Q")


## An empty build spot: a round stone pad.
static func draw_spot(canvas: CanvasItem, center: Vector2, cell: float) -> void:
	_spot_into(InkPen.new(canvas), center, cell)


static func _spot_into(pen: InkPen, center: Vector2, cell: float) -> void:
	var line: float = pen.line_px
	pen.line_px = clampf(cell * 0.025, 1.2, 4.0)
	pen.begin(center + Vector2(0.0, SPOT_DROP * cell), cell / 100.0)
	pen.ellipse(Vector2(0, 4), SPOT_RX * 100.0 + 2.0, SPOT_RY * 100.0 + 2.0, Palette.PAD_EDGE, false)
	pen.ellipse(Vector2(0, 0), SPOT_RX * 100.0, SPOT_RY * 100.0, Palette.PAD)
	pen.detail_path(_closed(InkPen.ellipse_pts(Vector2.ZERO, 26.0, 13.0, 24)), 2.0, Color(Palette.PAD_EDGE, 0.7))
	for k: int in 4:
		var a: float = TAU * float(k) / 4.0 + PI / 4.0
		var p: Vector2 = Vector2(cos(a) * 33.0, sin(a) * 17.0)
		pen.detail(p * 0.8, p * 1.12, 2.0, Color(Palette.PAD_EDGE, 0.7))
	pen.line_px = line


## The base: the village hearth hall, standing on the base cell.
static func draw_base(canvas: CanvasItem, center: Vector2, cell: float) -> void:
	var pen: InkPen = InkPen.new(canvas)
	pen.line_px = clampf(cell * 0.03, 1.2, 5.0)
	pen.begin(center + Vector2(0.0, 0.40 * cell), cell / 100.0)
	pen.shadow(Vector2(0, -1), 50.0)
	pen.box(22, -78, 32, -50, Palette.STONE)
	pen.box(-44, -40, 44, 0, Palette.PLASTER)
	for x: float in [-30.0, 30.0]:
		pen.detail(Vector2(x, -40), Vector2(x, 0), 2.0, Palette.TIMBER)
	pen.detail(Vector2(-44, -20), Vector2(44, -20), 2.0, Palette.TIMBER)
	pen.window(-40, -34, -32, -24)
	pen.window(32, -34, 40, -24)
	pen.poly(PackedVector2Array([Vector2(-52, -36), Vector2(52, -36), Vector2(36, -66), Vector2(-36, -66)]), Palette.ROOF_CLAY)
	pen.glow(Vector2(0, -12), 30.0, Palette.GLOW, 1.3)
	pen.door(Vector2(0, 0), 11.0, 26.0, Palette.LANTERN)
	pen.detail(Vector2(0, -24), Vector2(0, 0), 1.6, Palette.TIMBER)
	pen.circle(Vector2(0, -50), 10.0, Palette.CARD)
	Silhouettes.draw_glyph(canvas, &"heart", pen.to_canvas(Vector2(0, -49)), cell * 0.14)
	for x: float in [-20.0, 20.0]:
		pen.stroke(Vector2(x, 0), Vector2(x, -18), 2.4, Palette.TIMBER, false)
		pen.lantern(Vector2(x, -22), 3.6)


## A highlight ring on a cell: the selection, a hint, or the free spots while
## a tower card is picked. `pulse` from 0 to 1 brightens it.
static func draw_highlight(canvas: CanvasItem, at: Vector2i, cell: float, pulse: float = 1.0) -> void:
	var pen: InkPen = InkPen.new(canvas)
	pen.begin(_center(at, cell), cell / 100.0)
	pen.line_px = clampf(cell * 0.03, 1.2, 5.0)
	var ring: PackedVector2Array = _closed(InkPen.ellipse_pts(Vector2(0, 6), 44.0, 40.0, 32))
	pen.path(ring, 5.0, Color(Palette.HONEY, 0.6 + 0.4 * clampf(pulse, 0.0, 1.0)))


# Gates.

## A gate on the socket at `at`, in one of the Gate looks. Each look has its
## own shape: the open socket is a dashed ring, a fixed gate has a big
## padlock hanging below it, a broken gate hangs open with a crack, a refused
## one is crossed out, and an open gate (OPEN, under `gates_open`) stands
## under a wooden arch with its leaves swung back and the road clear between
## its posts.
static func draw_gate(canvas: CanvasItem, grid: PackedStringArray, at: Vector2i, cell: float, look: Gate) -> void:
	draw_gate_at(canvas, _center(at, cell), cell, _road_runs_vertically(grid, at), look)


## A gate centered on `center` for a cell of `cell` pixels. `across` is true
## on a road that runs up and down the screen. With `flat`, one color only.
static func draw_gate_at(canvas: CanvasItem, center: Vector2, cell: float, across: bool, look: Gate, flat: Color = Color(0.0, 0.0, 0.0, 0.0)) -> void:
	gate_into(InkPen.new(canvas, flat), center, cell, across, look)


## Draws a gate look with `pen`. The tests record it with a pen that has no
## canvas. Internal to src/theme/ and its tests, like InkPen.
static func gate_into(pen: InkPen, center: Vector2, cell: float, across: bool, look: Gate) -> void:
	pen.line_px = clampf(cell * 0.03, 1.2, 5.0)
	pen.begin(center, cell / 100.0)
	match look:
		Gate.SOCKET:
			_socket_ring(pen)
			_gate_shape(pen, across, 0.3)
		Gate.CLOSED:
			_gate_shape(pen, across, 1.0)
		Gate.FIXED:
			_gate_shape(pen, across, 1.0)
			_padlock(pen, Vector2(0, 25) if across else Vector2(-28, -2))
		Gate.BROKEN:
			_broken_gate(pen, across)
		Gate.REFUSED:
			_gate_shape(pen, across, 0.3)
			for d: Vector2 in [Vector2(1, 1), Vector2(1, -1)]:
				pen.stroke(-d * 26.0 + Vector2(0, -8), d * 26.0 + Vector2(0, -8), 7.0, Palette.HEART)
		Gate.OPEN:
			_open_gate(pen, across)


# Route lines.

## Draws a route line through `points` (map local pixels), in one of the
## Route styles: solid for walkers, dashed for gate breakers, dotted for
## flyers. Walker and breaker lines carry arrows. `phase` from 0 to 1 slides
## the dashes and arrows along, for a gentle motion.
static func draw_route(canvas: CanvasItem, points: PackedVector2Array, cell: float, style: Route, phase: float = 0.0) -> void:
	if points.size() < 2:
		return
	var casing: float = cell * 0.11
	var core: float = cell * 0.055
	var lengths: PackedFloat32Array = _cumulative(points)
	var total: float = lengths[lengths.size() - 1]
	match style:
		Route.WALK:
			canvas.draw_polyline(points, Palette.INK_LINE, casing, true)
			canvas.draw_polyline(points, Palette.ROUTE, core, true)
		Route.BREAK:
			var period: float = cell * 0.36
			var d: float = fposmod(phase, 1.0) * period
			while d < total:
				var seg: PackedVector2Array = _slice(points, lengths, d, minf(d + period * 0.55, total))
				canvas.draw_polyline(seg, Palette.INK_LINE, casing, true)
				canvas.draw_polyline(seg, Palette.ROUTE, core, true)
				d += period
		Route.FLY:
			var gap: float = cell * 0.24
			var d: float = fposmod(phase, 1.0) * gap
			while d < total:
				var p: Vector2 = _point_at(points, lengths, d)
				canvas.draw_circle(p, casing * 0.5, Palette.INK_LINE, true, -1.0, true)
				canvas.draw_circle(p, core * 0.62, Palette.ROUTE, true, -1.0, true)
				d += gap
			return
	# Arrows show which way the creatures go.
	var step: float = cell * 1.25
	var a: float = cell * 0.7 + fposmod(phase, 1.0) * step
	while a < total - cell * 0.4:
		var p: Vector2 = _point_at(points, lengths, a)
		var dir: Vector2 = (_point_at(points, lengths, a + 1.0) - p).normalized()
		var side: Vector2 = Vector2(-dir.y, dir.x)
		var s: float = cell * 0.13
		var chevron: PackedVector2Array = PackedVector2Array([p - dir * s * 0.3 + side * s, p + dir * s * 0.7, p - dir * s * 0.3 - side * s])
		canvas.draw_polyline(chevron, Palette.INK_LINE, casing, true)
		canvas.draw_polyline(chevron, Palette.ROUTE, core, true)
		a += step


## The drawn path for a list of road cells (entrance to base): through the
## cell centers, with the same quarter circle turns as the roads.
static func route_points(cells: Array[Vector2i], cell: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	if cells.is_empty():
		return out
	out.append(_center(cells[0], cell))
	for i: int in range(1, cells.size() - 1):
		var d_in: Vector2i = cells[i] - cells[i - 1]
		var d_out: Vector2i = cells[i + 1] - cells[i]
		var c: Vector2 = _center(cells[i], cell)
		if d_in == d_out:
			out.append(c)
			continue
		var from: Vector2 = c - Vector2(d_in) * cell * 0.5
		var to: Vector2 = c + Vector2(d_out) * cell * 0.5
		out.append_array(_quarter_arc(c, from, to, cell, 8))
	out.append(_center(cells[cells.size() - 1], cell))
	return out


## True when the road at `at` runs up and down the screen.
static func road_runs_vertically(grid: PackedStringArray, at: Vector2i) -> bool:
	return _road_runs_vertically(grid, at)


# Roads.

## One band of every road (or, with `slides_only`, of every ice slide) at
## `width_frac` of a cell. A bridge draws only its north-south road here: the
## east-west road crosses on the deck (FeatureArt.bridge).
static func _draw_roads(pen: InkPen, grid: PackedStringArray, cell: float, width_frac: float, col: Color, slides_only: bool = false) -> void:
	pen.begin(Vector2.ZERO, 1.0)
	var w: float = width_frac * cell
	for r: int in grid.size():
		for c: int in _cols(grid):
			var at: Vector2i = Vector2i(c, r)
			var ch: String = _char(grid, at)
			if not _is_road(ch) or (slides_only and not _SLIDES.contains(ch)):
				continue
			var dirs: Array[Vector2i] = _road_dirs(grid, at)
			var center: Vector2 = _center(at, cell)
			var ext: float = 0.5 + _OVERLAP
			if ch == "X":
				pen.path(PackedVector2Array([center + Vector2(0, -ext) * cell, center + Vector2(0, ext) * cell]), w, col, false)
			elif dirs.size() == 2 and dirs[0] == -dirs[1]:
				pen.path(PackedVector2Array([center + Vector2(dirs[0]) * cell * ext, center + Vector2(dirs[1]) * cell * ext]), w, col, false)
			elif dirs.size() == 2:
				var from: Vector2 = center + Vector2(dirs[0]) * cell * 0.5
				var to: Vector2 = center + Vector2(dirs[1]) * cell * 0.5
				var arc: PackedVector2Array = PackedVector2Array([from + Vector2(dirs[0]) * cell * _OVERLAP])
				arc.append_array(_quarter_arc(center, from, to, cell, 12))
				arc.append(to + Vector2(dirs[1]) * cell * _OVERLAP)
				pen.path(arc, w, col, false)
			else:
				for d: Vector2i in dirs:
					var reach: float = ext
					if _is_outward(grid, at, d):
						reach = 1.2
					pen.path(PackedVector2Array([center, center + Vector2(d) * cell * reach]), w, col, false)
				var plaza: float = w * (0.62 if dirs.size() >= 3 else 0.5)
				pen.circle(center, plaza, col, false)


## The directions a road cell connects in: its road neighbors, plus the way
## out of the map for an entrance.
static func _road_dirs(grid: PackedStringArray, at: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d: Vector2i in _DIRS:
		if _is_road(_char(grid, at + d)) or _is_outward(grid, at, d):
			out.append(d)
	return out


## True when `at` is an entrance and `d` points off the map.
static func _is_outward(grid: PackedStringArray, at: Vector2i, d: Vector2i) -> bool:
	var ch: String = _char(grid, at)
	if not (ch >= "1" and ch <= "4"):
		return false
	var n: Vector2i = at + d
	return n.x < 0 or n.y < 0 or n.x >= _cols(grid) or n.y >= grid.size()


static func _is_straight(grid: PackedStringArray, at: Vector2i) -> bool:
	var dirs: Array[Vector2i] = _road_dirs(grid, at)
	return dirs.size() == 2 and dirs[0] == -dirs[1]


static func _road_runs_vertically(grid: PackedStringArray, at: Vector2i) -> bool:
	return _is_road(_char(grid, at + Vector2i(0, -1))) or _is_road(_char(grid, at + Vector2i(0, 1)))


## A quarter circle from `from` to `to` (two edge middles of the cell at
## `center`), around the cell corner between them.
static func _quarter_arc(center: Vector2, from: Vector2, to: Vector2, cell: float, n: int) -> PackedVector2Array:
	var corner: Vector2 = from + to - center
	var a0: float = (from - corner).angle()
	var delta: float = wrapf((to - corner).angle() - a0, -PI, PI)
	return InkPen.arc_pts(corner, cell * 0.5, cell * 0.5, a0, a0 + delta, n)


static func _cobbles(pen: InkPen, at: Vector2i, cell: float, col: Color) -> void:
	var h: int = _hash(at.x, at.y)
	var c: Vector2 = _center(at, cell)
	for k: int in 3:
		var hk: int = (h >> (k * 4)) & 15
		var off: Vector2 = Vector2(float(hk % 4) - 1.5, float(hk / 4) - 1.5) * cell * 0.08
		pen.detail_poly(InkPen.ellipse_pts(c + off, cell * 0.045, cell * 0.03, 8), col)


static func _socket_posts(pen: InkPen, grid: PackedStringArray, at: Vector2i, cell: float) -> void:
	var c: Vector2 = _center(at, cell)
	var across: Vector2 = Vector2(1, 0) if _road_runs_vertically(grid, at) else Vector2(0, 1)
	for s: float in [-1.0, 1.0]:
		pen.circle(c + across * s * cell * 0.33, cell * 0.055, Palette.STONE_DARK)


# Gate shapes. Local units: 100 is one cell, origin at the socket center.

## The gate. `across` is true on a road that runs up and down the screen: the
## gate then faces the viewer. On a road that runs across the screen it is
## seen from the side, with a plank across the road.
static func _gate_shape(pen: InkPen, across: bool, alpha: float) -> void:
	var ghost: bool = alpha < 1.0
	var wood: Color = Color(Palette.PLASTER, alpha) if ghost else Palette.WOOD
	var post: Color = Color(Palette.PLASTER, alpha) if ghost else Palette.TIMBER
	if across:
		if not ghost:
			pen.box(-33, 10, 33, 17, Palette.TIMBER)
		pen.poly(PackedVector2Array([Vector2(-28, -30), Vector2(28, -30), Vector2(28, 6), Vector2(-28, 6)]), wood, not ghost)
		if not ghost:
			for x: float in [-14.0, 0.0, 14.0]:
				pen.detail(Vector2(x, -28), Vector2(x, 4), 2.4, Palette.TIMBER)
			pen.detail(Vector2(-26, 2), Vector2(26, -26), 3.0, Palette.TIMBER)
		pen.stroke(Vector2(-33, 14), Vector2(-33, -38), 6.0, post, not ghost)
		pen.stroke(Vector2(33, 14), Vector2(33, -38), 6.0, post, not ghost)
		if not ghost:
			pen.lantern(Vector2(-33, -44), 5.0)
			pen.lantern(Vector2(33, -44), 5.0)
	else:
		if not ghost:
			pen.box(-4, -33, 4, 33, Palette.TIMBER)
		pen.poly(PackedVector2Array([Vector2(-11, -40), Vector2(11, -46), Vector2(11, 14), Vector2(-11, 20)]), wood, not ghost)
		if not ghost:
			pen.detail(Vector2(0, -40), Vector2(0, 14), 2.4, Palette.TIMBER)
			pen.detail(Vector2(-9, 14), Vector2(9, -40), 3.0, Palette.TIMBER)
		pen.stroke(Vector2(-13, 24), Vector2(-13, -44), 6.0, post, not ghost)
		pen.stroke(Vector2(13, 18), Vector2(13, -50), 6.0, post, not ghost)
		if not ghost:
			pen.lantern(Vector2(-13, -50), 4.5)
			pen.lantern(Vector2(13, -56), 4.5)


static func _socket_ring(pen: InkPen) -> void:
	for i: int in 10:
		var a0: float = TAU * float(i) / 10.0
		pen.path(InkPen.arc_pts(Vector2(0, -4), 36.0, 36.0, a0, a0 + 0.36, 4), 4.0, Palette.ROUTE)


## A big padlock whose body hangs from `top`, the middle of its top edge.
## It hangs outside the gate's own outline, below the gate facing the viewer
## and on the near post of a gate seen from the side, so it shows as its own
## shape even in one flat color: a fixed gate never differs from a closed one
## by color alone.
static func _padlock(pen: InkPen, top: Vector2) -> void:
	pen.path(InkPen.arc_pts(top, 10.0, 10.0, PI, TAU, 12), 4.0, Palette.IRON)
	pen.box(top.x - 20, top.y, top.x + 20, top.y + 22, Palette.IRON)
	pen.detail_circle(top + Vector2(0, 8), 3.2, Palette.LANTERN)
	pen.detail(top + Vector2(0, 9), top + Vector2(0, 16), 2.6, Palette.LANTERN)


static func _broken_gate(pen: InkPen, across: bool) -> void:
	if across:
		# Two halves swung open, each with a jagged broken edge.
		pen.poly(PackedVector2Array([Vector2(-28, -30), Vector2(-14, -36), Vector2(-9, -22), Vector2(-15, -12), Vector2(-9, 0), Vector2(-28, 6)]), Palette.WOOD)
		pen.poly(PackedVector2Array([Vector2(28, -30), Vector2(14, -36), Vector2(10, -24), Vector2(4, -14), Vector2(10, -2), Vector2(28, 6)]), Palette.WOOD)
		pen.stroke(Vector2(-33, 14), Vector2(-33, -38), 6.0, Palette.TIMBER)
		pen.stroke(Vector2(33, 14), Vector2(33, -38), 6.0, Palette.TIMBER)
		pen.lantern(Vector2(-33, -44), 5.0, 0.4)
		pen.lantern(Vector2(33, -44), 5.0, 0.4)
	else:
		pen.poly(PackedVector2Array([Vector2(-11, -40), Vector2(11, -46), Vector2(4, -26), Vector2(11, -14), Vector2(-4, -6), Vector2(-11, 0)]), Palette.WOOD)
		pen.stroke(Vector2(-13, 24), Vector2(-13, -44), 6.0, Palette.TIMBER)
		pen.stroke(Vector2(13, 18), Vector2(13, -50), 6.0, Palette.TIMBER)
	# The crack mark: a zigzag, so a broken gate never shows by color alone.
	pen.path(PackedVector2Array([Vector2(-2, -44), Vector2(6, -32), Vector2(-4, -22), Vector2(5, -10), Vector2(-1, 2)]), 3.5, Palette.FLOUR)


## A gate standing open: both posts, a wooden arch over the opening with a
## lantern on each foot, and the leaves swung back out of the road. The middle
## of the road stays clear, so it reads as "they walk through" by shape, and
## the round arch tells it apart from a broken gate, which has none.
static func _open_gate(pen: InkPen, across: bool) -> void:
	if across:
		# Each leaf swung away from the viewer, hinged on its post: a narrow
		# panel that rises and leans in, leaving the middle of the road clear.
		for s: float in [-1.0, 1.0]:
			pen.poly(PackedVector2Array([Vector2(33 * s, -30), Vector2(33 * s, 6), Vector2(20 * s, -10), Vector2(20 * s, -42)]), Palette.WOOD)
			pen.detail(Vector2(30 * s, 0), Vector2(23 * s, -36), 2.4, Palette.TIMBER)
		pen.stroke(Vector2(-33, 14), Vector2(-33, -38), 6.0, Palette.TIMBER)
		pen.stroke(Vector2(33, 14), Vector2(33, -38), 6.0, Palette.TIMBER)
		pen.path(InkPen.arc_pts(Vector2(0, -38), 33.0, 22.0, PI, TAU, 18), 6.0, Palette.TIMBER)
		pen.lantern(Vector2(-33, -44), 5.0)
		pen.lantern(Vector2(33, -44), 5.0)
	else:
		# The one leaf swung back along the road, hinged on the far post.
		pen.poly(PackedVector2Array([Vector2(13, -46), Vector2(38, -40), Vector2(38, 20), Vector2(13, 14)]), Palette.WOOD)
		pen.detail(Vector2(26, -42), Vector2(26, 16), 2.4, Palette.TIMBER)
		pen.detail(Vector2(15, 10), Vector2(36, -38), 3.0, Palette.TIMBER)
		pen.stroke(Vector2(-13, 24), Vector2(-13, -44), 6.0, Palette.TIMBER)
		pen.stroke(Vector2(13, 18), Vector2(13, -50), 6.0, Palette.TIMBER)
		# The arch from post top to post top, following the posts' slant.
		var arch: PackedVector2Array = InkPen.arc_pts(Vector2(0, -47), 13.0, 12.0, PI, TAU, 12)
		for i: int in arch.size():
			arch[i].y -= arch[i].x * 3.0 / 13.0
		pen.path(arch, 5.0, Palette.TIMBER)
		pen.lantern(Vector2(-13, -50), 4.5)
		pen.lantern(Vector2(13, -56), 4.5)


# Entrances.

## The dark thicket the night creatures come out of, just outside the map
## edge at an entrance.
static func _thicket(pen: InkPen, grid: PackedStringArray, at: Vector2i, cell: float) -> void:
	var out: Vector2i = Vector2i.ZERO
	for d: Vector2i in _DIRS:
		if _is_outward(grid, at, d):
			out = d
	var c: Vector2 = _center(at, cell) + Vector2(out) * cell * 0.62
	pen.begin(c, cell / 100.0)
	var side: Vector2 = Vector2(-out.y, out.x)
	for i: int in 7:
		var t: float = float(i) / 6.0 - 0.5
		var p: Vector2 = side * t * 150.0 + Vector2(out) * (absf(t) * 30.0 + 6.0)
		var r: float = 30.0 + float((i * 7) % 3) * 6.0
		pen.circle(p, r, Palette.TREE_DARK if i % 2 == 0 else Palette.HILL_NEAR)
	pen.ellipse(-Vector2(out) * 6.0, 30.0, 22.0, Palette.THICKET, false)
	if not pen.is_flat():
		for k: int in 3:
			var e: Vector2 = side * (float(k) - 1.0) * 22.0 - Vector2(out) * (4.0 + float(k % 2) * 8.0)
			for dx: float in [-4.5, 4.5]:
				pen.glow(e + side * dx, 7.0, Palette.EYE, 0.8)
				pen.detail_poly(InkPen.ellipse_pts(e + side * dx, 2.8, 3.4, 10), Palette.EYE)


static func _entrance_sign(canvas: CanvasItem, pen: InkPen, grid: PackedStringArray, at: Vector2i, cell: float, font: Font, letter: String) -> void:
	var out: Vector2i = Vector2i.ZERO
	for d: Vector2i in _DIRS:
		if _is_outward(grid, at, d):
			out = d
	var side: Vector2 = Vector2(absf(float(out.y)), absf(float(out.x)))
	var c: Vector2 = _center(at, cell) + side * cell * 0.5 - Vector2(out) * cell * 0.05
	pen.begin(c, cell / 100.0)
	pen.stroke(Vector2(0, 2), Vector2(0, 30), 4.0, Palette.TIMBER)
	pen.circle(Vector2.ZERO, 17.0, Palette.CARD)
	var fs: int = int(cell * 0.22)
	var w: float = font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var base: Vector2 = c + Vector2(-w * 0.5, (font.get_ascent(fs) - font.get_descent(fs)) * 0.5)
	canvas.draw_string(font, base, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT_DARK)


# Grid and path helpers.

static func _cols(grid: PackedStringArray) -> int:
	return grid[0].length() if grid.size() > 0 else 0


static func _char(grid: PackedStringArray, at: Vector2i) -> String:
	if at.y < 0 or at.y >= grid.size() or at.x < 0 or at.x >= grid[at.y].length():
		return ""
	return grid[at.y][at.x]


static func _is_road(ch: String) -> bool:
	return ch.length() == 1 and ROAD_CHARS.contains(ch)


## A slide's way out: ^ north, v south, < west, > east.
static func _slide_dir(ch: String) -> Vector2i:
	match ch:
		"^":
			return Vector2i(0, -1)
		"v":
			return Vector2i(0, 1)
		"<":
			return Vector2i(-1, 0)
		">":
			return Vector2i(1, 0)
	return Vector2i.ZERO


static func _center(at: Vector2i, cell: float) -> Vector2:
	return (Vector2(at) + Vector2(0.5, 0.5)) * cell


## A small fixed hash per cell, so scenery is the same on every draw.
static func _hash(c: int, r: int) -> int:
	var h: int = (c * 73856093) ^ (r * 19349663) ^ 0x5bd1
	h = (h ^ (h >> 13)) * 1274126177
	return (h ^ (h >> 16)) & 0x7fffffff


static func _cumulative(pts: PackedVector2Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array([0.0])
	for i: int in range(1, pts.size()):
		out.append(out[i - 1] + pts[i - 1].distance_to(pts[i]))
	return out


static func _point_at(pts: PackedVector2Array, lengths: PackedFloat32Array, d: float) -> Vector2:
	var total: float = lengths[lengths.size() - 1]
	var dd: float = clampf(d, 0.0, total)
	for i: int in range(1, pts.size()):
		if lengths[i] >= dd:
			var seg: float = lengths[i] - lengths[i - 1]
			var t: float = 0.0 if seg <= 0.0 else (dd - lengths[i - 1]) / seg
			return pts[i - 1].lerp(pts[i], t)
	return pts[pts.size() - 1]


static func _slice(pts: PackedVector2Array, lengths: PackedFloat32Array, d0: float, d1: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array([_point_at(pts, lengths, d0)])
	for i: int in pts.size():
		if lengths[i] > d0 and lengths[i] < d1:
			out.append(pts[i])
	out.append(_point_at(pts, lengths, d1))
	return out


static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = pts.duplicate()
	out.append(pts[0])
	return out
