class_name ScreenBase
extends Control
## Shared behavior of every screen: ground color, margins, safe-area insets, and navigation.
## Screens build their children in `_build` and place them in `_layout`; they are rebuilt from
## scratch when the theme changes, so nothing caches a color.

## Ask the shell to show another screen by name (the names are the keys in main.gd).
signal navigate(target: String, args: Dictionary)

var app: AppState
var args: Dictionary = {}


func setup(state: AppState, screen_args: Dictionary = {}) -> void:
	app = state
	args = screen_args


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout)
	_build()
	_layout()


## Android back button or the on-screen back tile.
func go_back() -> void:
	pass


func margin() -> float:
	return 20.0 if size.x >= 380.0 else 16.0


## Space taken by the system bars on a phone; zero on a desktop window.
func inset_top() -> float:
	return _inset(true)


func inset_bottom() -> float:
	return _inset(false)


func _inset(top: bool) -> float:
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return 0.0
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	var scale := float(DisplayServer.window_get_size().x) / maxf(size.x, 1.0)
	if top:
		return float(safe.position.y) / scale
	return float(screen.y - safe.end.y) / scale


func _draw() -> void:
	if UiLook.depth:
		DepthKit.ground(self, Rect2(Vector2.ZERO, size))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.GROUND)


func _build() -> void:
	pass


func _layout() -> void:
	pass
