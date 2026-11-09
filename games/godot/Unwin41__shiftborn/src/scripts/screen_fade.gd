class_name ScreenFade
extends CanvasLayer
## Autoload "Fade": a black layer over everything that fades out before a
## scene change and back in after it. Without the autoload (unit tests)
## [method go_to] changes the scene at once.

const LAYER := 100
const FADE_TIME := 0.25

static var _instance: ScreenFade

var _rect: ColorRect
var _busy: bool = false


## Fades out, changes to [param path] (or reloads the current scene when
## it is empty) and fades back in.
static func go_to(tree: SceneTree, path: String = "") -> void:
	if _instance == null or not _instance.is_inside_tree():
		_change(tree, path)
		return
	_instance._go_to(path)


static func _change(tree: SceneTree, path: String) -> void:
	tree.paused = false
	if path.is_empty():
		tree.reload_current_scene()
	else:
		tree.change_scene_to_file(path)


func _init() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func _enter_tree() -> void:
	_instance = self


func _exit_tree() -> void:
	if _instance == self:
		_instance = null


func alpha() -> float:
	return _rect.modulate.a


func _go_to(path: String) -> void:
	if _busy:
		return
	_busy = true
	# Block clicks while the screen is dark.
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var out := create_tween()
	out.tween_property(_rect, ^"modulate:a", 1.0, FADE_TIME)
	await out.finished
	_change(get_tree(), path)
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_rect, ^"modulate:a", 0.0, FADE_TIME)
	await back.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
