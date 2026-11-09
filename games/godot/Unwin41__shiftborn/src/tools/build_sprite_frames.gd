extends SceneTree
## Builds SpriteFrames resources from the Ninja Adventure sheets in
## assets/ninja/ (CC0, Pixel-boy and AAA).
## Usage: godot --headless -s res://tools/build_sprite_frames.gd
## Run `godot --headless --import` first so the PNGs are imported.
##
## Two sheet kinds:
## - grid: 16x16 cells, one column per direction (down, up, left, right),
##   rows 0-3 are the walk cycle. Builds walk_<dir> and idle_<dir>.
## - strip: one row of square frames (bosses), facing the camera.
##   Builds idle and run (run falls back to idle when there is no walk).
## Every SpriteFrames also gets "idle" and "run", so scenes and code that
## only know those names keep working.

const ASSET_DIR := "res://assets/ninja/"
const OUTPUT_DIR := "res://assets/sprite_frames"
const CELL := 16
const DIRECTIONS: Array[StringName] = [&"down", &"up", &"left", &"right"]
const WALK_FRAMES := 4
const WALK_FPS := 8.0
const IDLE_FPS := 6.0

const SHEETS := {
	"warrior": {kind = "grid", sheet = "characters/warrior.png"},
	"mage": {kind = "grid", sheet = "characters/mage.png"},
	"spider": {kind = "grid", sheet = "monsters/spider.png"},
	"spirit": {kind = "grid", sheet = "monsters/spirit.png"},
	"skull": {kind = "grid", sheet = "monsters/skull.png"},
	"eye": {kind = "grid", sheet = "monsters/eye.png"},
	"beast": {kind = "grid", sheet = "monsters/beast.png"},
	"slime": {kind = "grid", sheet = "monsters/slime.png"},
	"cyclops": {kind = "strip", size = 50, idle = "bosses/cyclops_idle.png", walk = "bosses/cyclops_walk.png"},
	"giant_spirit": {kind = "strip", size = 50, idle = "bosses/giant_spirit_idle.png"},
	"tengu": {kind = "strip", size = 82, idle = "bosses/tengu_idle.png", walk = "bosses/tengu_walk.png"},
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var failed := false
	for output_name: String in SHEETS:
		var spec: Dictionary = SHEETS[output_name]
		var frames := _build_grid(spec) if spec.kind == "grid" else _build_strip(spec)
		if frames == null or not _save(frames, output_name):
			failed = true
	quit(1 if failed else 0)


func _build_grid(spec: Dictionary) -> SpriteFrames:
	var sheet := _load(spec.sheet)
	if sheet == null:
		return null
	var frames := _empty_frames()
	for column in DIRECTIONS.size():
		var direction := DIRECTIONS[column]
		var walk := StringName("walk_%s" % direction)
		var idle := StringName("idle_%s" % direction)
		_add_animation(frames, walk, WALK_FPS)
		_add_animation(frames, idle, IDLE_FPS)
		for row in WALK_FRAMES:
			frames.add_frame(walk, _region(sheet, Rect2(column * CELL, row * CELL, CELL, CELL)))
		frames.add_frame(idle, _region(sheet, Rect2(column * CELL, 0, CELL, CELL)))
	_alias(frames, &"run", &"walk_down")
	_alias(frames, &"idle", &"idle_down")
	return frames


func _build_strip(spec: Dictionary) -> SpriteFrames:
	var size: int = spec.size
	var idle_sheet := _load(spec.idle)
	if idle_sheet == null:
		return null
	var walk_sheet := _load(spec.walk) if spec.has("walk") else idle_sheet
	var frames := _empty_frames()
	_add_strip(frames, &"idle", idle_sheet, size, IDLE_FPS)
	_add_strip(frames, &"run", walk_sheet, size, WALK_FPS)
	return frames


func _add_strip(frames: SpriteFrames, animation: StringName, sheet: Texture2D, size: int, fps: float) -> void:
	_add_animation(frames, animation, fps)
	for i in sheet.get_width() / size:
		frames.add_frame(animation, _region(sheet, Rect2(i * size, 0, size, size)))


func _alias(frames: SpriteFrames, alias: StringName, source: StringName) -> void:
	_add_animation(frames, alias, frames.get_animation_speed(source))
	for i in frames.get_frame_count(source):
		frames.add_frame(alias, frames.get_frame_texture(source, i))


func _empty_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	return frames


func _add_animation(frames: SpriteFrames, animation: StringName, fps: float) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, true)


func _region(sheet: Texture2D, rect: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = rect
	return atlas


func _load(relative_path: String) -> Texture2D:
	var texture := load(ASSET_DIR + relative_path) as Texture2D
	if texture == null:
		push_error("cannot load %s%s (run --import first?)" % [ASSET_DIR, relative_path])
	return texture


func _save(frames: SpriteFrames, output_name: String) -> bool:
	var path := OUTPUT_DIR.path_join(output_name + ".tres")
	var error := ResourceSaver.save(frames, path)
	if error != OK:
		push_error("%s: save failed (%s)" % [path, error_string(error)])
		return false
	print("built %s (%s)" % [path, ", ".join(frames.get_animation_names())])
	return true
