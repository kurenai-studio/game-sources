extends SkinIcon
## What the three skins' icons share: the name, look and color state, and a
## recording of the drawing that is rebuilt only when the icon or its size
## changes, so _draw() allocates nothing. Each skin's icon extends this and
## gives _record() (the drawing), _look_color() (its colors) and its STAR.
##
## The chevron, the arrow and the coffee are quiet marks (rows that open a
## screen, the Info example rows, the Buy me a coffee button): in the normal
## look they draw in ink_muted in every skin (DESIGN_SYSTEM.md 4.7, 5.7, 6.7).

const IconPen: GDScript = preload("res://src/design/shared/icon_pen.gd")
const StarShape: GDScript = preload("res://src/design/shared/star_shape.gd")

## Icons whose normal look is ink_muted.
const MUTED_ICONS: Array[StringName] = [&"chevron", &"arrow", &"coffee"]

var _skin: SkinData = null
var _icon: StringName = &""
var _look: int = LOOK_NORMAL
var _color: Color = Color.WHITE
var _has_override: bool = false
var _override: Color = Color.WHITE
var _pen: IconPen = IconPen.new()
## Size and icon the recording was made for.
var _built_size: Vector2 = Vector2(-1.0, -1.0)
var _built_icon: StringName = &""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(skin: SkinData) -> void:
	_skin = skin
	if size == Vector2.ZERO:
		var side: float = skin.num(&"icon_hud")
		size = Vector2(side, side)
	_on_setup()
	_pick_color()
	_rebuild()


func set_icon(icon_name: StringName) -> void:
	if not ICON_NAMES.has(icon_name):
		push_error("%s icon: unknown icon '%s'" % [_skin.id if _skin != null else &"", icon_name])
		return
	_icon = icon_name
	_pick_color()
	_rebuild()


func set_look(look: int) -> void:
	_look = clampi(look, LOOK_NORMAL, LOOK_DISABLED)
	_pick_color()
	queue_redraw()


func set_color(color: Color) -> void:
	_has_override = true
	_override = color
	_pick_color()
	queue_redraw()


## The current look.
func look() -> int:
	return _look


## The color the icon draws in now.
func ink() -> Color:
	return _color


## Draw commands in the recording for the current icon and size. Builds the
## recording first if it is out of date. For tests.
func drawn_parts() -> int:
	if size != _built_size or _icon != _built_icon:
		_build()
	return _pen.part_count()


## Called by setup(), for a skin's icon to read its tokens.
func _on_setup() -> void:
	pass


## Records the named icon with _pen, which begin() has already fitted to
## _grid_area(). Each skin overrides it.
func _record(_icon_name: StringName) -> void:
	push_error("%s does not record icons" % (get_script() as Script).resource_path)


## The color a look draws in. Each skin overrides it.
func _look_color(_for_look: int) -> Color:
	push_error("%s has no look colors" % (get_script() as Script).resource_path)
	return SkinData.MISSING_COLOR


## Alpha the look multiplies the color by.
func _look_alpha(_for_look: int) -> float:
	return 1.0


## The area the 24 unit grid is fitted to.
func _grid_area() -> Rect2:
	return Rect2(Vector2.ZERO, size)


## Drawn under the icon, for a glow. Must not allocate.
func _draw_under() -> void:
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild()


func _draw() -> void:
	if _skin == null or _icon == &"":
		return
	# An icon sized outside the tree gets no resize notification, so it builds
	# here when it first draws at a new size.
	if size != _built_size or _icon != _built_icon:
		_build()
	_draw_under()
	_pen.replay(self, _color)


func _pick_color() -> void:
	if _skin == null:
		return
	var base: Color = _override if _has_override else _look_color(_look)
	if not _has_override and _look == LOOK_NORMAL and MUTED_ICONS.has(_icon):
		base = _skin.color(&"ink_muted")
	_color = Color(base, base.a * _look_alpha(_look))


func _rebuild() -> void:
	_build()
	queue_redraw()


func _build() -> void:
	_built_size = size
	_built_icon = _icon
	_pen.begin(_grid_area())
	if _skin == null or _icon == &"":
		return
	_record(_icon)
