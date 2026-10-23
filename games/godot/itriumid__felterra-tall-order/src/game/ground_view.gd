class_name GroundView
extends Node2D
## The clearing and the jungle around it: the ground, the grass and ferns growing over it, and
## the trees and big leaves at its edge. No outlines: the environment stays behind the
## characters. Each liberation area has its own ground, wrecked while the company holds it and
## healed once it's free; freeing it, the healed ground spreads out from where its boss fell.

## How fast freed ground spreads, in pixels a second.
const HEAL_SPEED := 260.0
## How far past the clearing the jungle is drawn, in pixels.
const JUNGLE_DEPTH := 400.0
## How many tufts and ferns grow in the clearing, and how close a body must pass to bend one, in
## meters.
const GROWTH := 900
const BRUSH_REACH := 0.08

var arena: Arena
var _ground: ImageTexture
## The healed ground, while it spreads over the wrecked: from where, and how far it's reached, in
## pixels (negative while it isn't spreading).
var _healed: ImageTexture
var _healing_from := Vector2.ZERO
var healing := -1.0
## Scorched peat still smoldering, in pixels, while the area's held: its smoke rises off it.
var _smoldering: Array = []
var _smoke: Array[Dictionary] = []
var _growth: Array[Dictionary] = []
var _edge: Array[Dictionary] = []
var _upright := {}
## Whether this place is as the company left it: fewer trees stand at its edges.
var _wrecked := false
var _bent := {}


func _ready() -> void:
	for kind in ["tuft", "fern"]:
		for lean in [-1, 0, 1]:
			var picture: Image = EnvironmentArt.tuft(lean) if kind == "tuft" else EnvironmentArt.fern(lean)
			var texture := ImageTexture.create_from_image(picture)
			if lean == 0:
				_upright[kind] = texture
			else:
				_bent["%s%d" % [kind, lean]] = texture
	paint("clearing", 39, false)


## Paints the ground for a place: its look, wrecked or healed, and its growth and its trees from a
## seed, so a fixed area looks the same every time and Endless's clearing is new each run.
func paint(theme: String, seed_value: int, healed: bool) -> void:
	var size := Vector2i(Arena.SIZE * World.PIXELS_PER_METER)
	_smoldering = []
	_smoke.clear()
	_ground = ImageTexture.create_from_image(EnvironmentArt.area_ground(size, seed_value, theme, healed, _smoldering))
	_healed = null
	healing = -1.0
	_wrecked = not healed
	var random := RandomNumberGenerator.new()
	random.seed = seed_value + 3
	_growth.clear()
	_edge.clear()
	# Growth is thin where the company has been, and thick where it's gone.
	for index in GROWTH * (2 if healed else 1) / (1 if theme in ["clearing", "edge", "deep", "slide"] or healed else 3):
		var where := Vector2(random.randf() * Arena.SIZE.x, random.randf() * Arena.SIZE.y)
		_growth.append({"position": where, "kind": "fern" if random.randf() < 0.25 else "tuft"})
	_plant_edge(random)


## Freeing the area: the healed ground spreads out from a point.
func heal(from: Vector2, theme: String, seed_value: int) -> void:
	var size := Vector2i(Arena.SIZE * World.PIXELS_PER_METER)
	_healed = ImageTexture.create_from_image(EnvironmentArt.area_ground(size, seed_value, theme, true))
	_healing_from = World.to_screen(from)
	healing = 0.0
	# The fires go out as it heals.
	_smoldering.clear()


func _process(delta: float) -> void:
	if healing >= 0.0:
		healing += HEAL_SPEED * delta
	# Smoke off the smoldering peat: a wisp now and then, rising and drifting, gone as it thins.
	for spot: Vector2 in _smoldering:
		if randf() < delta * 3.0:
			_smoke.append({"at": spot + Vector2(randf_range(-20.0, 20.0), randf_range(-10.0, 10.0)), "life": randf_range(1.5, 3.0)})
	var rising: Array[Dictionary] = []
	for wisp in _smoke:
		wisp.life -= delta
		wisp.at += Vector2(randf_range(-4.0, 6.0), -14.0) * delta
		if wisp.life > 0.0:
			rising.append(wisp)
	_smoke = rising
	queue_redraw()


func _draw() -> void:
	var clearing := Rect2(Vector2.ZERO, Arena.SIZE * World.PIXELS_PER_METER)
	draw_rect(clearing.grow(JUNGLE_DEPTH), Palette.JUNGLE_DEEP)
	draw_texture(_ground, Vector2.ZERO)
	if _healed != null and healing >= 0.0:
		# The healed ground, row by row inside a growing circle: a hard pixel edge, no blend.
		var size := _healed.get_size()
		for y in range(maxi(int(_healing_from.y - healing), 0), mini(int(_healing_from.y + healing), int(size.y))):
			var half := sqrt(maxf(healing * healing - pow(y - _healing_from.y, 2.0), 0.0))
			var from_x := clampf(_healing_from.x - half, 0.0, size.x)
			var to_x := clampf(_healing_from.x + half, 0.0, size.x)
			if to_x > from_x:
				draw_texture_rect_region(_healed, Rect2(from_x, y, to_x - from_x, 1), Rect2(from_x, y, to_x - from_x, 1))
	var view := _visible_meters()
	for plant in _growth:
		var where: Vector2 = plant.position
		if not view.has_point(where):
			continue
		var lean := arena.brushing(where, BRUSH_REACH) if arena != null else 0
		var texture: Texture2D = _upright[plant.kind] if lean == 0 else _bent["%s%d" % [plant.kind, lean]]
		draw_texture(texture, World.to_screen(where) - Vector2(texture.get_width() / 2, texture.get_height() - 1))
	for wisp in _smoke:
		draw_rect(Rect2(wisp.at.round(), Vector2(2, 1) if wisp.life > 1.0 else Vector2.ONE), Palette.SMOKE)
	for piece in _edge:
		draw_texture(piece.texture, piece.at)


## The part of the clearing on screen, in meters, with a margin.
func _visible_meters() -> Rect2:
	var screen := get_viewport_rect().size
	var center := get_viewport().get_camera_2d().get_screen_center_position() if get_viewport().get_camera_2d() != null else Vector2.ZERO
	return Rect2((center - screen / 2.0) / World.PIXELS_PER_METER, screen / World.PIXELS_PER_METER).grow(0.5)


## Trees stand just outside the clearing, with big leaves and undergrowth in front of their feet.
func _plant_edge(random: RandomNumberGenerator) -> void:
	var size := Arena.SIZE * World.PIXELS_PER_METER
	var perimeter := 2.0 * (size.x + size.y)
	var along := 0.0
	var trees: Array[Dictionary] = []
	var front: Array[Dictionary] = []
	while along < perimeter:
		along += random.randf_range(40.0, 90.0) * (2.2 if _wrecked else 1.0)
		var point := _on_edge(along, size)
		var outward := _outward(along, size)
		var height := random.randi_range(70, 120)
		var picture := EnvironmentArt.trunk(height, random.randi_range(8, 14), random.randi())
		var foot := point + outward * random.randf_range(14.0, 40.0)
		trees.append({"texture": ImageTexture.create_from_image(picture), "at": (foot - Vector2(picture.get_width() / 2, height)).round(), "y": foot.y})
	along = 0.0
	while along < perimeter:
		along += random.randf_range(10.0, 20.0)
		var point := _on_edge(along, size)
		var outward := _outward(along, size)
		var picture: Image
		if random.randf() < 0.35:
			picture = EnvironmentArt.banana_leaf(random.randi_range(26, 40), random.randi())
			if random.randf() < 0.5:
				picture.flip_x()
		else:
			picture = EnvironmentArt.leaves(random.randi_range(9, 16), random.randi(), random.randf() < 0.5)
		var at := point + outward * random.randf_range(0.0, 12.0)
		front.append({"texture": ImageTexture.create_from_image(picture), "at": (at - Vector2(picture.get_size()) / 2.0).round(), "y": at.y})
	trees.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.y < b.y)
	_edge.append_array(trees)
	_edge.append_array(front)


func _on_edge(along: float, size: Vector2) -> Vector2:
	if along < size.x:
		return Vector2(along, 0.0)
	along -= size.x
	if along < size.y:
		return Vector2(size.x, along)
	along -= size.y
	if along < size.x:
		return Vector2(size.x - along, size.y)
	return Vector2(0.0, size.y - (along - size.x))


func _outward(along: float, size: Vector2) -> Vector2:
	if along < size.x:
		return Vector2.UP
	if along < size.x + size.y:
		return Vector2.RIGHT
	if along < 2.0 * size.x + size.y:
		return Vector2.DOWN
	return Vector2.LEFT
