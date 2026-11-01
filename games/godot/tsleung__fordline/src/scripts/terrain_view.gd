extends Node2D
## Paints the map once per battle; Godot keeps the drawing until the next
## queue_redraw.

var terrain: Terrain
var seed_value := 0


func show_terrain(t: Terrain, s: int) -> void:
	terrain = t
	seed_value = s
	queue_redraw()


func _draw() -> void:
	if terrain == null:
		return
	var size := terrain.size
	draw_rect(Rect2(Vector2(-400, -400), size + Vector2(800, 800)), Palette.GRASS.darkened(0.25))
	draw_rect(Rect2(Vector2.ZERO, size), Palette.GRASS)
	_fields()
	_hills()
	for town in terrain.towns:
		_town(town)
	for stream in terrain.streams:
		_stream(stream)
	for road in terrain.roads:
		_road(road)
	if terrain.has_river:
		_river()
	if terrain.has_walls():
		_fortress()
	_forests()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.25), false, 3.0)


## Field patches in a jittered grid, each a slightly different green with a
## pale hedge line, like a printed survey map.
func _fields() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cell := Vector2(200.0, 160.0)
	var cols := int(ceil(terrain.size.x / cell.x)) + 1
	var rows := int(ceil(terrain.size.y / cell.y)) + 1
	var grid := []
	for y in rows + 1:
		var line := []
		for x in cols + 1:
			var p := Vector2(x * cell.x, y * cell.y)
			if x > 0 and x < cols and y > 0 and y < rows:
				p += Vector2(rng.randf_range(-50, 50), rng.randf_range(-40, 40))
			line.append(p)
		grid.append(line)
	for y in rows:
		for x in cols:
			var poly := PackedVector2Array([grid[y][x], grid[y][x + 1], grid[y + 1][x + 1], grid[y + 1][x]])
			var tone := rng.randf()
			if tone < 0.35:
				draw_colored_polygon(_inset(poly, 5.0), Palette.FIELD_LIGHT)
			elif tone < 0.6:
				draw_colored_polygon(_inset(poly, 5.0), Palette.FIELD_DARK)
			var closed := poly.duplicate()
			closed.append(poly[0])
			draw_polyline(closed, Palette.FIELD_EDGE, 2.0, true)


func _inset(poly: PackedVector2Array, by: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= poly.size()
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + (c - p).normalized() * by)
	return out


## Three contour bands. Each band is drawn for every hill and ridge before
## the next, and its line as a slightly larger shape beneath it, so where
## hills and ridges overlap each band shows one clean outline.
func _hills() -> void:
	for i in 3:
		var k := 1.0 - i * 0.28
		for h in terrain.hills:
			draw_circle(h.c, h.r * k + 1.5, Palette.HILL_LINE)
		for ridge in terrain.ridges:
			_band(ridge.line, ridge.r * k + 1.5, Palette.HILL_LINE)
		for h in terrain.hills:
			draw_circle(h.c, h.r * k, Palette.HILL[i])
		for ridge in terrain.ridges:
			_band(ridge.line, ridge.r * k, Palette.HILL[i])


## A ridge's band: everything within `r` of its crest line.
func _band(line: PackedVector2Array, r: float, color: Color) -> void:
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var side := (b - a).normalized().orthogonal() * r
		draw_colored_polygon(PackedVector2Array([a + side, b + side, b - side, a - side]), color)
	for p in line:
		draw_circle(p, r, color)


## A town: paving, and rows of house roofs wherever there is room off the
## roads.
func _town(town: PackedVector2Array) -> void:
	draw_colored_polygon(town, Palette.PAVING)
	draw_polyline(town + PackedVector2Array([town[0]]), Palette.PAVING_LINE, 2.0, true)
	var box := Rect2(town[0], Vector2.ZERO)
	for p in town:
		box = box.expand(p)
	var y := box.position.y + 18.0
	while y < box.end.y - 10.0:
		var x := box.position.x + 18.0
		while x < box.end.x - 10.0:
			var c := Vector2(x, y)
			if Geometry2D.is_point_in_polygon(c, town) and not terrain.on_road(c):
				draw_rect(Rect2(c - Vector2(12, 8), Vector2(24, 16)), Palette.ROOF)
				draw_line(c - Vector2(12, 0), c + Vector2(12, 0), Palette.ROOF_LIGHT, 2.0)
			x += 34.0
		y += 30.0


func _stream(stream: PackedVector2Array) -> void:
	var smooth := _smooth(stream)
	var w := Terrain.STREAM_HALF * 1.1
	draw_polyline(smooth, Palette.RIVER_EDGE, w + 3.0, true)
	draw_polyline(smooth, Palette.RIVER, w, true)


func _road(road: PackedVector2Array) -> void:
	var smooth := _smooth(road)
	draw_polyline(smooth, Palette.ROAD_EDGE, Terrain.ROAD_HALF * 1.2 + 2.0, true)
	draw_polyline(smooth, Palette.ROAD, Terrain.ROAD_HALF * 1.2, true)


## Chaikin smoothing, so roads bend rather than kink.
func _smooth(points: PackedVector2Array) -> PackedVector2Array:
	var pts := points
	for pass_i in 3:
		var out := PackedVector2Array([pts[0]])
		for i in pts.size() - 1:
			out.append(pts[i].lerp(pts[i + 1], 0.25))
			out.append(pts[i].lerp(pts[i + 1], 0.75))
		out.append(pts[pts.size() - 1])
		pts = out
	return pts


func _river() -> void:
	var w := Terrain.RIVER_HALF * 2.0
	draw_polyline(terrain.river, Palette.RIVER_EDGE, w + 5.0, true)
	draw_polyline(terrain.river, Palette.RIVER, w, true)
	var shine := PackedVector2Array()
	for p in terrain.river:
		shine.append(p + Vector2(0, -w * 0.18))
	draw_polyline(shine, Palette.RIVER_SHINE, 2.0, true)
	for c in terrain.crossings:
		var x: float = c.x
		var half: float = c.half
		var y := terrain.river_y(x)
		var slope := atan2(terrain.river_y(x + 10.0) - terrain.river_y(x - 10.0), 20.0)
		draw_set_transform(Vector2(x, y), slope)
		if c.bridge:
			draw_rect(Rect2(-half, -w * 0.5 - 6.0, half * 2.0, w + 12.0), Palette.BRIDGE)
			for i in int(half * 2.0 / 5.0):
				draw_line(Vector2(-half + i * 5.0, -w * 0.5 - 6.0), Vector2(-half + i * 5.0, w * 0.5 + 6.0), Palette.BRIDGE_RAIL, 1.0)
			draw_line(Vector2(-half, -w * 0.5 - 6.0), Vector2(half, -w * 0.5 - 6.0), Palette.BRIDGE_RAIL, 2.5)
			draw_line(Vector2(-half, w * 0.5 + 6.0), Vector2(half, w * 0.5 + 6.0), Palette.BRIDGE_RAIL, 2.5)
		else:
			var ford := Palette.FORD
			ford.a = 0.8
			draw_rect(Rect2(-half, -w * 0.5 - 2.0, half * 2.0, w + 4.0), ford)
			for i in 6:
				var sx := -half + 6.0 + i * (half * 2.0 - 12.0) / 5.0
				draw_line(Vector2(sx, -w * 0.4), Vector2(sx + 4.0, w * 0.4), Palette.RIVER_SHINE, 1.5)
		draw_set_transform(Vector2.ZERO)


func _forests() -> void:
	for f in terrain.forests:
		draw_circle(f.c + Vector2(4, 6), f.r, Palette.TREE_SHADOW)
	for f in terrain.forests:
		draw_circle(f.c, f.r, Palette.TREE)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 99
	for f in terrain.forests:
		var c: Vector2 = f.c
		var r: float = f.r
		for i in int(r / 6.0):
			var p := c + Vector2.from_angle(rng.randf() * TAU) * rng.randf() * r * 0.7
			draw_circle(p, rng.randf_range(3.0, 7.0), Palette.TREE_LIGHT)


# --- fortress --------------------------------------------------------------

func _fortress() -> void:
	var t := terrain
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 7
	# Moat, with the bridge to the gatehouse.
	var mw := Terrain.MOAT.y - Terrain.MOAT.x
	draw_polyline(t.moat, Palette.RIVER_EDGE, mw + 5.0, true)
	draw_polyline(t.moat, Palette.RIVER, mw, true)
	for g in t.gates:
		if g.keep:
			continue
		var c: Vector2 = g.c + g.out * (Terrain.MOAT.x + mw * 0.5)
		var along: Vector2 = g.along
		var span: Vector2 = g.out * (mw * 0.5 + 8.0)
		var half := along * (Terrain.GATE_HALF - 6.0)
		draw_colored_polygon(PackedVector2Array([c - half - span, c + half - span, c + half + span, c - half + span]), Palette.BRIDGE)
		for i in 7:
			var k := lerpf(-1.0, 1.0, i / 6.0)
			draw_line(c + span * k - half, c + span * k + half, Palette.BRIDGE_RAIL, 1.0)
		draw_line(c - half - span, c - half + span, Palette.BRIDGE_RAIL, 2.5)
		draw_line(c + half - span, c + half + span, Palette.BRIDGE_RAIL, 2.5)
	# Paved wards: the bailey, then the keep's yard over it.
	draw_colored_polygon(t.curtain, Palette.PAVING)
	draw_colored_polygon(t.keep, Palette.PAVING_KEEP)
	_flagstones(t, rng)
	# Shadows, then the walls, towers and great tower on top.
	var thick := Terrain.WALL_HALF * 2.0
	for w in t.walls:
		draw_line(w[0] + Vector2(4, 6), w[1] + Vector2(4, 6), Palette.WALL_SHADOW, thick + 2.0)
	for tw in t.towers:
		draw_circle(tw.c + Vector2(5, 7), tw.r, Palette.WALL_SHADOW)
	for r in t.blocks:
		draw_rect(Rect2(r.position + Vector2(7, 10), r.size), Palette.WALL_SHADOW)
	for w in t.walls:
		_wall(w[0], w[1], thick)
	for g in t.gates:
		_gate_arch(g)
	for i in t.gates.size():
		_gate_doors(t.gates[i], t.gate_broken[i], rng)
	for tw in t.towers:
		_tower(tw.c, tw.r)
	for r in t.blocks:
		_great_tower(r)
	# Pennants on the corner towers, in the holder's colour.
	for tw in t.towers:
		if tw.r >= 26.0:
			_pennant(tw.c, Palette.TEAM[t.holder])


func _flagstones(t: Terrain, rng: RandomNumberGenerator) -> void:
	var cell := 26.0
	var y := 0.0
	var row := 0
	while y < terrain.size.y:
		var x := -cell * 0.5 * (row % 2)
		while x < terrain.size.x:
			var c := Vector2(x + cell * 0.5, y + cell * 0.5)
			if t.inside(c):
				draw_rect(Rect2(Vector2(x, y), Vector2(cell, cell)), Palette.PAVING_LINE, false, 1.0)
				if rng.randf() < 0.08:
					draw_rect(Rect2(Vector2(x + 2, y + 2), Vector2(cell - 4, cell - 4)), Color(1, 1, 1, 0.07))
			x += cell
		y += cell
		row += 1


func _wall(a: Vector2, b: Vector2, thick: float) -> void:
	draw_line(a, b, Palette.STONE_DARK, thick + 3.0)
	draw_line(a, b, Palette.STONE, thick)
	# A walkway down the middle and merlons along both faces.
	var dir := (b - a).normalized()
	var side := dir.orthogonal()
	draw_line(a, b, Palette.STONE_LIGHT, thick * 0.35)
	var n := int(a.distance_to(b) / 9.0)
	for i in n:
		var p := a + dir * (i * 9.0 + 4.5)
		for face in [-1.0, 1.0]:
			var q: Vector2 = p + side * face * (thick * 0.5 - 1.5)
			draw_rect(Rect2(q - Vector2(2.2, 2.2), Vector2(4.4, 4.4)), Palette.STONE_DARK if i % 2 == 0 else Palette.STONE)


func _gate_arch(g: Dictionary) -> void:
	var half: Vector2 = g.along * Terrain.GATE_HALF
	var depth: Vector2 = g.out * (Terrain.WALL_HALF + 3.0)
	var c: Vector2 = g.c
	draw_colored_polygon(PackedVector2Array([c - half - depth, c + half - depth, c + half + depth, c - half + depth]), Palette.STONE_DARK)
	draw_colored_polygon(PackedVector2Array([c - half * 0.9 - depth * 0.7, c + half * 0.9 - depth * 0.7, c + half * 0.9 + depth * 0.7, c - half * 0.9 + depth * 0.7]), Color(0.25, 0.22, 0.18))


## Shut: oak doors banded with iron. Broken: splinters on the stones.
func _gate_doors(g: Dictionary, broken: bool, rng: RandomNumberGenerator) -> void:
	var c: Vector2 = g.c
	var along: Vector2 = g.along
	var out: Vector2 = g.out
	var half := along * (Terrain.GATE_HALF - 3.0)
	if broken:
		for i in 14:
			var p := c + along * rng.randf_range(-30, 30) + out * rng.randf_range(-16, 16)
			var d := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(3.0, 8.0)
			draw_line(p - d, p + d, Palette.WOOD_DARK if i % 3 == 0 else Palette.WOOD, 2.5)
		return
	var depth := out * 4.0
	draw_colored_polygon(PackedVector2Array([c - half - depth, c + half - depth, c + half + depth, c - half + depth]), Palette.WOOD)
	for i in 9:
		var k := lerpf(-1.0, 1.0, i / 8.0)
		draw_line(c + half * k - depth, c + half * k + depth, Palette.WOOD_DARK, 1.0)
	for k in [-0.55, 0.0, 0.55]:
		draw_line(c - half + out * 4.0 * k, c + half + out * 4.0 * k, Color(0.18, 0.18, 0.2), 1.5)


func _tower(c: Vector2, r: float) -> void:
	draw_circle(c, r + 1.5, Palette.STONE_DARK)
	draw_circle(c, r, Palette.STONE)
	draw_circle(c, r * 0.62, Palette.STONE_LIGHT)
	draw_arc(c, r * 0.62, 0, TAU, 32, Palette.STONE_DARK, 1.2, true)
	var n := int(TAU * r / 9.0)
	for i in n:
		if i % 2 == 0:
			var p := c + Vector2.from_angle(TAU * i / n) * (r - 2.5)
			draw_rect(Rect2(p - Vector2(2.4, 2.4), Vector2(4.8, 4.8)), Palette.STONE_DARK)


## The great tower: a hipped roof seen from above.
func _great_tower(r: Rect2) -> void:
	draw_rect(r.grow(2.0), Palette.STONE_DARK)
	draw_rect(r, Palette.STONE)
	var roof := r.grow(-9.0)
	var ridge_a := Vector2(roof.position.x + roof.size.y * 0.5, roof.get_center().y)
	var ridge_b := Vector2(roof.end.x - roof.size.y * 0.5, roof.get_center().y)
	var tl := roof.position
	var tr := Vector2(roof.end.x, roof.position.y)
	var br := roof.end
	var bl := Vector2(roof.position.x, roof.end.y)
	draw_colored_polygon(PackedVector2Array([tl, tr, ridge_b, ridge_a]), Palette.ROOF_LIGHT)
	draw_colored_polygon(PackedVector2Array([bl, br, ridge_b, ridge_a]), Palette.ROOF)
	draw_colored_polygon(PackedVector2Array([tl, ridge_a, bl]), Palette.ROOF_LIGHT.lerp(Palette.ROOF, 0.5))
	draw_colored_polygon(PackedVector2Array([tr, ridge_b, br]), Palette.ROOF.darkened(0.15))
	draw_line(ridge_a, ridge_b, Palette.WOOD_DARK, 2.0)
	for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		_tower(corner, 13.0)
	_pennant(r.get_center() + Vector2(0, -4), Palette.TEAM[terrain.holder])


func _pennant(at: Vector2, color: Color) -> void:
	var top := at + Vector2(0, -26)
	draw_line(at, top, Palette.WOOD_DARK, 2.0)
	draw_colored_polygon(PackedVector2Array([top, top + Vector2(18, 4), top + Vector2(0, 9)]), color)
	draw_polyline(PackedVector2Array([top, top + Vector2(18, 4), top + Vector2(0, 9)]), Color(0, 0, 0, 0.4), 1.0)
