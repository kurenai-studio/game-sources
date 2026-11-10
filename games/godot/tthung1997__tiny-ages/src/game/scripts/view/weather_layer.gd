class_name WeatherLayer
extends Node
## Draws falling rain or snow over the scene from one sheet of art (assets/world/weather.png, drawn
## by tools/art/weather.js). It does not scroll with the world: the streaks stay put as you pan.
## It only reads WorldState through WeatherLook. Nothing else about the weather is drawn.
##
## Cheap when ignored: under a clear sky nothing shows and this node does not process at all.
## While it rains or snows a three-frame loop swaps on a slow clock. There are no flashes. Sheet
## rows (each 80 px high) are mirrored in tools/art/weather.js.

const SHEET: String = "res://assets/world/weather.png"
const ROW_HEIGHT: int = 80
const ROW_RAIN: int = 0
const ROW_SNOW: int = 3
const FRAMES: int = 3
## How long each frame stays up, in seconds.
const FALL_SECONDS: float = 0.14
const FALL_Z: int = 95
const FALL_ALPHA: float = 0.85

var _sheet: Texture2D
var _fall: Sprite2D = Sprite2D.new()
var _frames: Array[AtlasTexture] = []
var _kind: StringName = &""
var _frame: int = -1
var _clock: float = 0.0
var _full_scene: bool = true


## `screen_root` is the clip, which does not scroll.
func setup(screen_root: Control) -> void:
	_sheet = load(SHEET) as Texture2D
	if _sheet == null:
		push_error("Missing weather art: %s" % SHEET)
		return
	for row: int in [ROW_RAIN, ROW_SNOW]:
		for frame: int in FRAMES:
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = _sheet
			atlas.region = Rect2(
				Vector2(0, (row + frame) * ROW_HEIGHT), Vector2(WorldLayout.VIEW_SIZE)
			)
			_frames.append(atlas)
	_fall.centered = false
	_fall.z_index = FALL_Z
	_fall.modulate.a = FALL_ALPHA
	_fall.visible = false
	screen_root.add_child(_fall)
	set_process(false)


## Shows what the weather in `world` calls for. Call whenever the world changes.
func apply(world: WorldState, full_scene: bool) -> void:
	if _sheet == null:
		return
	_full_scene = full_scene
	_kind = WeatherLook.fall(world.weather)
	_fall.visible = _kind != &""
	_frame = -1
	_show_frame()
	set_process(_fall.visible)


## Whether the frames are being swapped, which is only while it rains or snows.
func is_animating() -> bool:
	return _fall.visible


## Whether rain or snow is falling with no sky behind it (strip and corner mode). It falls from the
## top of the viewport, so the whole viewport has to be drawn, and on Windows what is drawn is
## what is clickable: the game adds the viewport to the click region while this is true.
func covers_sky() -> bool:
	return _fall.visible and not _full_scene


func _process(delta: float) -> void:
	_clock = fmod(_clock + delta, 3600.0)
	_show_frame()


func _show_frame() -> void:
	if not _fall.visible:
		return
	var frame: int = int(_clock / FALL_SECONDS) % FRAMES
	if frame == _frame:
		return
	_frame = frame
	var first: int = 0 if _kind == WeatherLook.RAIN else FRAMES
	_fall.texture = _frames[first + frame]
