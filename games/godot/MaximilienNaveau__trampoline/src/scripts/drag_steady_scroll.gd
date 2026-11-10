# A ScrollContainer that holds still while a tile is dragged out of it,
# and that scrolls when a dragged tile nears its top or bottom edge.
# Used for the page (main.tscn's Layout, scrollable when it doesn't fit
# the screen, e.g. free play's palette in portrait) and the "À rendre"
# tray (discard_tray.gd), which scrolls sideways.
#
# On a touchscreen, a finger dragged across a ScrollContainer scrolls it,
# including the finger dragging a tile: the page slid under the tile. So
# a tile drag starting puts this back where it was when the finger went
# down, which also stops the scrolling there.
#
# But then nothing scrolls the page during the drag: with free play's
# palette scrolled into view under the board, a tile from its last lines
# (the Z) couldn't reach the board's top row, off the top of the screen.
# So, while a tile is dragged, holding it near the top or bottom edge
# scrolls the page that way — faster the closer to the edge.
extends ScrollContainer

# How far from the top or bottom edge (in pixels of the 480x854 logical
# screen, see project.godot) a dragged tile starts scrolling the page.
const EDGE_BAND := 80.0
# The scrolling speed with the tile right at the edge, in pixels per
# second; it falls to 0 at the inner side of the band.
const EDGE_SPEED := 1200.0

# The scroll position when the last finger/button went down.
var _scroll_at_press := Vector2i.ZERO
# The scroll position as a float during an edge scroll: `scroll_vertical`
# is a whole number of pixels, and a slow scroll moves less than one
# pixel a frame, which rounding down would lose every frame.
var _edge_scroll := 0.0
# The dragged tile's height in this container (the finger's: Godot reports
# a finger as the mouse), 0 at its top edge, kept up to date by `_input`.
var _pointer_y := 0.0


func _ready() -> void:
	# `_process` (below) runs only during a drag: Godot calls a node's
	# `_process` every frame unless it's switched off like this.
	set_process(false)


# Called with every input event that reaches this container, including
# those a child (a tile, a cell) lets through (`mouse_filter` PASS). A
# touch arrives here as a left mouse button.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_scroll_at_press = Vector2i(scroll_horizontal, scroll_vertical)


# Godot sends NOTIFICATION_DRAG_BEGIN to every node when a drag-and-drop
# starts (a tile picked up, see tile_panel.gd's `_get_drag_data`), and
# NOTIFICATION_DRAG_END when it ends, dropped or not.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		# Setting the scroll position also ends the touch scroll under way,
		# and the glide it would have had on release (see Godot's
		# ScrollContainer.set_v_scroll).
		scroll_horizontal = _scroll_at_press.x
		scroll_vertical = _scroll_at_press.y
		_edge_scroll = scroll_vertical
		# Mid-height (no scrolling) until the finger's next move.
		_pointer_y = size.y / 2.0
		# Only a container that scrolls up and down, and is on screen, has
		# edges to scroll from — not the sideways tray, nor a hidden one.
		set_process(vertical_scroll_mode != SCROLL_MODE_DISABLED and is_visible_in_tree())
	elif what == NOTIFICATION_DRAG_END:
		set_process(false)


# Called with every input event, before any Control gets it — unlike
# `_gui_input`, also the moves of a finger dragging a tile from elsewhere.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_processing():
		# `event.position` is in screen (viewport) coordinates; the inverse
		# of this container's own screen transform brings it into ours.
		_pointer_y = (get_global_transform_with_canvas().affine_inverse() * event.position).y


# Called every frame during a drag (see `_ready`), `delta` being the
# seconds since the last frame: scrolls the page when the dragged tile is
# near an edge.
func _process(delta: float) -> void:
	var y := _pointer_y
	# How deep into the top or bottom band the finger is: 0 at its inner
	# side, 1 at the edge (or beyond, clamped), negative for upwards.
	var depth := 0.0
	if y < EDGE_BAND:
		depth = -minf((EDGE_BAND - y) / EDGE_BAND, 1.0)
	elif y > size.y - EDGE_BAND:
		depth = minf((y - (size.y - EDGE_BAND)) / EDGE_BAND, 1.0)
	if depth == 0.0:
		return
	# The furthest the page can scroll, from its (hidden or not) scroll
	# bar: the content's height (`max_value`) minus the part on screen
	# (`page`). `clampf` keeps the position within 0..that.
	var bar := get_v_scroll_bar()
	var bottom := maxf(bar.max_value - bar.page, 0.0)
	_edge_scroll = clampf(_edge_scroll + depth * EDGE_SPEED * delta, 0.0, bottom)
	scroll_vertical = int(_edge_scroll)
