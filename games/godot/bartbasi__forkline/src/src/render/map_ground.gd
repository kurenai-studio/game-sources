# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name MapGround
extends Node2D
## A static map layer drawn once with MapArt into a texture and shown as one sprite
## (docs/ARCHITECTURE.md 9.3). It is drawn again only when the sharpness it needs changes,
## for example when a fold gives the map bigger cells. Internal to src/render/.
##
## Two kinds. The ground layer holds the ground, scenery, roads, spots, sockets, the base and
## the entrance thickets, with room around the map for the thickets. The feature layer
## (`features_only`) holds the tunnel mounds, bridge decks and stumps (MapArt.draw_features).
## It covers only the box around those features, so a map with one bridge keeps a small
## texture. It sits above the route lines and the walkers under a deck (14.10).

const CELL: float = 128.0
## Room around the map in the texture, in cells, for the entrance thickets.
const MARGIN: float = 0.75
## The characters MapArt.draw_features draws (ice slides belong to the ground).
const FEATURE_CHARS: String = "TXPQ"

## Draws the map into the viewport.
class Painter:
	extends Node2D
	var ground: MapGround

	func _draw() -> void:
		ground.paint(self)


var texel_scale: float = 1.0
## How many times the picture was queued for drawing.
var bakes: int = 0

var _grid: PackedStringArray = PackedStringArray()
var _ground_id: StringName = &"lantern_hill"
var _features_only: bool = false
## The box the texture covers, in cells.
var _area: Rect2 = Rect2()
var _viewport: SubViewport
var _painter: Painter
var _sprite: Sprite2D
var _draws: int = 0


## The box around every feature character of `grid`, in cells, with room for what overhangs a
## cell (a deck is a little longer than its cell). An empty Rect2 when the grid holds none.
static func feature_area(grid: PackedStringArray) -> Rect2:
	var box: Rect2 = Rect2()
	var found: bool = false
	for r: int in grid.size():
		var line: String = grid[r]
		for c: int in line.length():
			if FEATURE_CHARS.contains(line[c]):
				var cell_box: Rect2 = Rect2(float(c), float(r), 1.0, 1.0)
				box = cell_box if not found else box.merge(cell_box)
				found = true
	return box.grow(MARGIN) if found else Rect2()


func setup(grid: PackedStringArray, material: Material, ground: StringName = &"lantern_hill", features_only: bool = false) -> void:
	_grid = grid
	_ground_id = ground
	_features_only = features_only
	if features_only:
		_area = feature_area(grid)
	else:
		_area = Rect2(Vector2(-MARGIN, -MARGIN), Vector2(float(Sim.MAP_COLUMNS) + 2.0 * MARGIN, float(grid.size()) + 2.0 * MARGIN))
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.gui_disable_input = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)
	_painter = Painter.new()
	_painter.ground = self
	_viewport.add_child(_painter)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.material = material
	_sprite.position = _area.position * CELL
	_sprite.texture = _viewport.get_texture()
	add_child(_sprite)
	bake(1.0)


## Queues one draw at `scale` texels per local pixel.
func bake(scale: float) -> void:
	texel_scale = maxf(scale, 0.25)
	_viewport.size = Vector2i(ceili(_area.size.x * CELL * texel_scale), ceili(_area.size.y * CELL * texel_scale))
	_painter.position = -_area.position * CELL * texel_scale
	_painter.scale = Vector2(texel_scale, texel_scale)
	_sprite.scale = Vector2.ONE / texel_scale
	bakes += 1
	_painter.queue_redraw()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## Called by the painter, inside its _draw().
func paint(canvas: CanvasItem) -> void:
	_draws += 1
	if _features_only:
		MapArt.draw_features(canvas, _grid, CELL)
	else:
		MapArt.draw_ground(canvas, _grid, CELL, UiTheme.font(UiTheme.WEIGHT_BOLD), _ground_id)


## How many times the map was really drawn (not just queued).
func draw_count() -> int:
	return _draws


## The box this layer covers, in cells.
func area() -> Rect2:
	return _area


## The texture size in texels, for tests.
func texture_size() -> Vector2i:
	return _viewport.size
