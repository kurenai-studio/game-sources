# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Draws the Google Play graphics with the src/theme/ code and writes them to
## docs/store/graphics/: the 512 x 512 icon and the 1024 x 500 feature graphic.
## It needs a rendering display, so run it without --headless, from the repo root:
##     godot --path . --script res://tools/store/make_graphics.gd
## It opens a small window for a moment and exits 0 when both files are written.
## Nothing here ships in the APK.

const OUT_DIR: String = "res://docs/store/graphics"
const ICON_FILE: String = "icon_512.png"
const FEATURE_FILE: String = "feature_1024x500.png"
const FEATURE_SIZE: Vector2i = Vector2i(1024, 500)
## The feature graphic is drawn at twice the size and scaled down for smooth edges.
const SUPER: int = 2

## A small map piece for the right half: a road that forks around the town,
## a gate on the left branch, towers on the pads, the hearth hall at the end.
const GRID: PackedStringArray = [
	"...1...",
	".o.#.o.",
	".#####.",
	".#.o.#.",
	".G.o.#.",
	".#####.",
	"..oBo..",
]
const CELL: float = 72.0
const GATE_CELL: Vector2i = Vector2i(1, 4)
const MAP_ORIGIN: Vector2 = Vector2(520.0, -2.0)
## Towers: cell, id, tier, spec.
const TOWERS: Array[Array] = [
	[Vector2i(1, 1), &"sling_post", 2, 0],
	[Vector2i(5, 1), &"longbow_loft", 3, 0],
	[Vector2i(3, 3), &"lullaby_bell", 2, 0],
	[Vector2i(3, 4), &"pumpkin_catapult", 2, 0],
	[Vector2i(2, 6), &"firework_tower", 2, 0],
	[Vector2i(4, 6), &"bakery", 2, 0],
]
## Creatures on the right branch and in the air: id, position in cells, frame.
const CREATURES: Array[Array] = [
	[&"scamp", Vector2(3.0, 0.9), 1],
	[&"pip", Vector2(3.0, 1.9), 0],
	[&"shellback", Vector2(4.1, 2.0), 2],
	[&"skitter", Vector2(5.0, 3.1), 1],
	[&"flitter", Vector2(5.4, 4.3), 1],
]
## Sparkles where a creature has just been beaten: position in cells, size in cells.
const SPARKLES: Array[Array] = [
	[Vector2(5.0, 4.9), 0.2], [Vector2(5.35, 4.6), 0.12], [Vector2(4.7, 4.6), 0.1],
]


## A node that paints with a Callable, so one scene can be built from lambdas.
class Painter extends Node2D:
	var paint: Callable = Callable()

	func _draw() -> void:
		if paint.is_valid():
			paint.call(self)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("make_graphics.gd needs a display. Run it without --headless.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var failed: int = 0
	var icon: Image = await IconArt.draw(512)
	_opaque(icon)
	failed += _save(icon, ICON_FILE)
	var feature: Image = await _render_feature()
	failed += _save(feature, FEATURE_FILE)
	quit(1 if failed > 0 else 0)


func _save(img: Image, file_name: String) -> int:
	var path: String = OUT_DIR.path_join(file_name)
	var err: Error = img.save_png(path)
	print("%s %dx%d: %s" % [path, img.get_width(), img.get_height(), error_string(err)])
	return 0 if err == OK else 1


## The full icon has no see-through pixels (Play shows it on its own background).
func _opaque(img: Image) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a < 1.0:
				img.set_pixel(x, y, Color(c, 1.0))


func _render_feature() -> Image:
	var big: Vector2i = FEATURE_SIZE * SUPER
	var vp: SubViewport = SubViewport.new()
	vp.size = big
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var scene: Node2D = Node2D.new()
	scene.scale = Vector2(float(SUPER), float(SUPER))
	vp.add_child(scene)
	_layer(scene, Vector2.ZERO, _paint_sky)
	_layer(scene, MAP_ORIGIN, _paint_map)
	_layer(scene, MAP_ORIGIN, _paint_actors)
	_layer(scene, Vector2.ZERO, _paint_words)
	root.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(FEATURE_SIZE.x, FEATURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	_opaque(img)
	return img


func _layer(parent: Node2D, at: Vector2, paint: Callable) -> void:
	var p: Painter = Painter.new()
	p.position = at
	p.paint = paint
	parent.add_child(p)


# The dusk sky behind everything, drawn in the same order as the app's backdrop.

func _paint_sky(c: CanvasItem) -> void:
	var w: float = float(FEATURE_SIZE.x)
	var h: float = float(FEATURE_SIZE.y)
	var stops: Array[float] = [0.0, h * 0.7, h * 0.92, h]
	var sky: Array[Color] = [Palette.SKY_TOP, Palette.SKY_MID, Palette.SKY_LOW, Palette.SKY_GLOW]
	for i: int in 3:
		c.draw_polygon(PackedVector2Array([Vector2(0.0, stops[i]), Vector2(w, stops[i]), Vector2(w, stops[i + 1]), Vector2(0.0, stops[i + 1])]),
			PackedColorArray([sky[i], sky[i], sky[i + 1], sky[i + 1]]))
	for i: int in 40:
		var a: int = (i * 7919 + 13) % 1000
		var b: int = (i * 104729 + 71) % 1000
		var p: Vector2 = Vector2(w * float(a) / 1000.0, h * 0.5 * float(b) / 1000.0)
		c.draw_circle(p, 1.2 + float(i % 3) * 0.6, Color(Palette.STAR, 0.4 + 0.1 * float(i % 4)))
	c.draw_circle(Vector2(430.0, 62.0), 34.0, Palette.MOON)
	c.draw_circle(Vector2(442.0, 55.0), 29.0, Palette.SKY_TOP.lerp(Palette.SKY_MID, 0.1))
	_hills(c, w, h, 0.74, 24.0, Palette.HILL_FAR, 0.4)
	_hills(c, w, h, 0.82, 28.0, Palette.HILL_MID, 2.1)
	_hills(c, w, h, 0.90, 22.0, Palette.HILL_NEAR, 3.6)


func _hills(c: CanvasItem, w: float, h: float, base: float, amp: float, col: Color, phase: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 25:
		var x: float = w * float(i) / 24.0
		pts.append(Vector2(x, h * base + sin(x / w * 5.0 + phase) * amp))
	pts.append(Vector2(w, h))
	pts.append(Vector2(0.0, h))
	c.draw_colored_polygon(pts, col)


# The map piece. Its layer sits at MAP_ORIGIN, so cells start at (0, 0).

func _paint_map(c: CanvasItem) -> void:
	MapArt.draw_ground(c, GRID, CELL)
	MapArt.draw_gate(c, GRID, GATE_CELL, CELL, MapArt.Gate.CLOSED)
	# A route line down the open branch, so the fork reads at a glance.
	var cells: Array[Vector2i] = [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5), Vector2i(3, 6)]
	MapArt.draw_route(c, MapArt.route_points(cells, CELL), CELL, MapArt.Route.WALK, 0.0)
	# A frame so the picture sits on the sky like a page in a book.
	var size: Vector2 = Vector2(float(GRID[0].length()), float(GRID.size())) * CELL
	c.draw_rect(Rect2(Vector2.ZERO, size), Palette.INK_LINE, false, 6.0)


func _paint_actors(c: CanvasItem) -> void:
	for t: Array in TOWERS:
		var cell: Vector2i = t[0]
		var center: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5)) * CELL
		Silhouettes.draw_tower(c, t[1], t[2], t[3], center, CELL)
	for e: Array in CREATURES:
		var type: StringName = e[0]
		var pos: Vector2 = e[1]
		var box: float = Silhouettes.enemy_size(type, CELL)
		Silhouettes.draw_enemy(c, type, pos * CELL, box, e[2])
	for s: Array in SPARKLES:
		var pos: Vector2 = s[0]
		_sparkle(c, pos * CELL, float(s[1]) * CELL)


## A four point star: the creatures puff into these.
func _sparkle(c: CanvasItem, at: Vector2, r: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0 - PI * 0.5
		var k: float = r if i % 2 == 0 else r * 0.32
		pts.append(at + Vector2(cos(a), sin(a)) * k)
	c.draw_colored_polygon(pts, Palette.SPARKLE)
	var outline: PackedVector2Array = pts.duplicate()
	outline.append(pts[0])
	c.draw_polyline(outline, Palette.INK_LINE, 1.5, true)


# The words, on the left.

func _paint_words(c: CanvasItem) -> void:
	Wordmark.draw_into(c, Rect2(16.0, 50.0, 490.0, 230.0))
	var f: Font = UiTheme.font(UiTheme.WEIGHT_BOLD)
	var lines: Array[String] = ["Tower defense", "where the roads fork"]
	var y: float = 316.0
	for line: String in lines:
		var w: float = f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		c.draw_string(f, Vector2(16.0 + (490.0 - w) * 0.5, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Palette.TEXT_LIGHT)
		y += 38.0
	var small: Font = UiTheme.font(UiTheme.WEIGHT_REGULAR)
	var tag: String = "Free. No ads. Works offline."
	var tw: float = small.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	c.draw_string(small, Vector2(16.0 + (490.0 - tw) * 0.5, y + 28.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.TEXT_LIGHT)
