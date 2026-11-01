class_name InfoPanel extends "res://src/ui/reading_screen.gd"
## Info (GDD D-44 and section 21, DESIGN_SYSTEM.md 7.11 and 7.12): a reading
## screen titled "Info" with the seventeen sections IN1 to IN17, each title and
## text word for word, always opened scrolled to the top. Example rows sit
## under the text after space_m, left aligned on one line, vertically centered:
## - a chain row: the chain drawn by the skin's own board view as a one row
##   board, every tile in the chain, no preview and no highlight, sized for
##   112 px tiles; space_m, the arrow icon (56 px, ink_muted), space_m; the
##   result, the skin's tile view at 112 px, resting;
## - a change row (Double's 8 then 16): the tile before as a tile view, the
##   arrow, the tile after, with no board and no chain line.
## A booster section (IN9 to IN13) leads with that booster's icon in an
## icon_hud box, in ink with no face: two columns, the icon on the left
## centered on the heading's first line, space_s, then the heading, text and
## any row on the right.
## Nothing in a row takes input, so a drag on it scrolls. It changes nothing
## in the game and holds no live numbers. Opened only by Info on the splash
## or in Pause; its close button and Android back return there.
##
## The build is split across frames (7.12 "A long page", QA SPL-02), as the
## license view does (7.14): each frame builds one part of a section (its
## box and heading, its text, or its example row). The screen stays invisible until the
## sections built fill the scroll area (FIRST), then fades in with nothing
## built during the fade (FADING), then builds the rest below the reader
## (REST) until every section is there (DONE).

## DESIGN_SYSTEM.md 7.9 fixed component constants.
const EXAMPLE_TILE: float = 112.0
const EXAMPLE_ARROW: float = 56.0
## Building time one frame may spend, in microseconds, at least one part.
## 0 means one part per frame: a part costs up to about 7 ms to build, and
## its layout and first drawing come on top, so with two parts a frame went
## over 16.7 ms on the desktop and with one it stays within it.
const FRAME_BUILD_USEC: int = 0

enum Stage { FIRST, FADING, REST, DONE }
## The parts a section is built in, one after another.
const PART_HEADING: int = 0
const PART_TEXT: int = 1
const PART_ROW: int = 2

var _pending: Array[Dictionary] = []
## The section being built, and its next part.
var _next: int = 0
var _part: int = PART_HEADING
var _text_column: VBoxContainer = null
var _parts_built: int = 0
var _stage: Stage = Stage.FIRST
var _fade_wanted: bool = false
## Test seam: the build time one frame may spend. 0 builds one section per
## frame. The game never changes it.
var frame_budget_usec: int = FRAME_BUILD_USEC
## The longest single frame's build so far, in microseconds. For measuring.
var worst_build_usec: int = 0


func setup(skin: SkinData) -> void:
	_frame(skin, Copy.INFO)
	_pending = Copy.info_sections()
	_next = 0
	_part = PART_HEADING
	_text_column = null
	_parts_built = 0
	_stage = Stage.FIRST
	worst_build_usec = 0
	_scroll.scroll_vertical = 0
	if is_inside_tree() and not get_tree().process_frame.is_connected(_next_batch):
		get_tree().process_frame.connect(_next_batch)


## Fades in once the first screenful is built; until then it stays
## invisible over what opened it.
func play_in() -> void:
	if _skin == null:
		return
	_fade_wanted = true
	modulate.a = 0.0
	if _stage == Stage.REST or _stage == Stage.DONE:
		_start_fade()


## One frame of the build, for the scroll area's height. Each frame calls
## it; tests call it with a height of their own. In FIRST the page's height
## is the one laid out in the last frame.
func step(view_height: float) -> void:
	match _stage:
		Stage.FIRST:
			if _next > 0 and _part == PART_HEADING and (_sections.size.y >= view_height or is_built()):
				_first_screen_built()
				return
			_build(frame_budget_usec)
		Stage.REST:
			_build(frame_budget_usec)
			if is_built():
				_stage = Stage.DONE


## The fade in has ended: the rest may build. The fade's tween calls it;
## tests call it.
func fade_finished() -> void:
	if _stage == Stage.FADING:
		_stage = Stage.DONE if is_built() else Stage.REST


## Builds every section left now. For tests.
func finish() -> void:
	_build(-1)
	if _stage == Stage.FIRST:
		_first_screen_built()
	elif _stage == Stage.REST:
		_stage = Stage.DONE


## True once all seventeen sections are built.
func is_built() -> bool:
	return _next >= _pending.size()


## The build's stage, a Stage value. For tests.
func stage() -> Stage:
	return _stage


## The section parts built so far (box and heading, text, row). For tests.
func built_parts() -> int:
	return _parts_built


## The sections built whole so far. For tests.
func built_sections() -> int:
	return _next


func _next_batch() -> void:
	if _closing or not is_inside_tree():
		_stop_batches()
		return
	step(_scroll.size.y)
	if _stage == Stage.DONE:
		_stop_batches()


func _first_screen_built() -> void:
	if _fade_wanted:
		_stage = Stage.FADING
		_start_fade()
	else:
		_stage = Stage.DONE if is_built() else Stage.REST


func _start_fade() -> void:
	if not is_inside_tree():
		return
	var tween: Tween = Motion.fade(self, _skin, 1.0)
	tween.finished.connect(fade_finished)


func _stop_batches() -> void:
	if is_inside_tree() and get_tree().process_frame.is_connected(_next_batch):
		get_tree().process_frame.disconnect(_next_batch)


func _exit_tree() -> void:
	_stop_batches()


## Builds parts of sections until budget_usec is spent (-1 for no limit),
## at least one part per call, so it always moves on. Each section is built
## in parts: its box and heading, its text, and its example row. A row (a
## board view or tiles) costs most, so it only starts a frame, never joins
## one already spent on something else.
func _build(budget_usec: int) -> void:
	var started: int = Time.get_ticks_usec()
	var parts: int = 0
	while _next < _pending.size():
		var section: Dictionary = _pending[_next]
		var has_row: bool = not (section["example"] as PackedInt64Array).is_empty()
		if budget_usec >= 0 and parts > 0 and _part == PART_ROW:
			break
		var first_child: int = _sections.get_child_count()
		_build_part(_skin, section)
		parts += 1
		_parts_built += 1
		_part += 1
		if _part == PART_ROW and not has_row:
			_part += 1
		if _part > PART_ROW:
			_part = PART_HEADING
			_next += 1
		for index: int in range(first_child, _sections.get_child_count()):
			_quiet(_sections.get_child(index))
		if _text_column != null and _part != PART_TEXT:
			_quiet(_text_column)
		if budget_usec >= 0 and Time.get_ticks_usec() - started >= budget_usec:
			break
	worst_build_usec = maxi(worst_build_usec, Time.get_ticks_usec() - started)


func _build_part(skin: SkinData, section: Dictionary) -> void:
	match _part:
		PART_HEADING:
			var column: VBoxContainer = _add_section()
			var icon_name: StringName = section["icon"]
			_text_column = column
			if icon_name != &"":
				_text_column = _icon_columns(skin, column, icon_name)
			_text_column.add_child(_heading(String(section["title"])))
		PART_TEXT:
			_text_column.add_child(_reading(String(section["text"])))
		PART_ROW:
			var example: PackedInt64Array = section["example"]
			_text_column.add_child(UiParts.spacer(skin.num(&"space_m") - skin.num(&"space_xs")))
			_text_column.add_child(_example_row(skin, example, int(section["result"]), section["row"]))


## Rebuilds the screen in a new skin, still open.
func apply_skin(skin: SkinData) -> void:
	setup(skin)


## TH21. One Dictionary per section IN1 to IN17, in order: {"title": String,
## "text": String, "example": PackedInt64Array (the joined tiles, or the one
## changed tile for a change row; empty for none), "result": int (0 for
## none), "row": &"chain", &"change" or &"", "icon": the booster icon name for
## IN9 to IN13 or &""}. Tiles are exponents (ARCHITECTURE.md section 17).
## A copy: changing it changes nothing shown.
func content() -> Array[Dictionary]:
	var copied: Array[Dictionary] = []
	for section: Dictionary in Copy.info_sections():
		copied.append(section.duplicate(true))
	return copied


## The example rows as built, in section order. For tests.
func example_rows() -> Array[HBoxContainer]:
	var rows: Array[HBoxContainer] = []
	for node: Node in _sections.find_children("Example", "HBoxContainer", true, false):
		rows.append(node as HBoxContainer)
	return rows


## The booster icons as built, in section order. For tests.
func section_icons() -> Array[SkinIcon]:
	var icons: Array[SkinIcon] = []
	for node: Node in _sections.find_children("BoosterIcon", "", true, false):
		icons.append(node as SkinIcon)
	return icons


## Splits a section into the icon column and the text column (7.12) and
## returns the text column. The icon is centered on the heading's first line:
## whichever of the two is shorter gets a top spacer of half the difference.
func _icon_columns(skin: SkinData, column: VBoxContainer, icon_name: StringName) -> VBoxContainer:
	var columns: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	columns.name = "Columns"
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(columns)
	var side: float = skin.num(&"icon_hud")
	var line: float = skin.font(&"heading").get_height(skin.font_size(&"heading"))
	var icon_column: VBoxContainer = UiParts.vbox(0.0)
	icon_column.name = "IconColumn"
	icon_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	columns.add_child(icon_column)
	if line > side:
		icon_column.add_child(UiParts.spacer(roundf((line - side) * 0.5)))
	var icon: SkinIcon = UiKit.make_icon(skin)
	icon.name = "BoosterIcon"
	icon.custom_minimum_size = Vector2(side, side)
	icon.size = Vector2(side, side)
	icon.set_icon(icon_name)
	icon.set_look(SkinIcon.LOOK_NORMAL)
	icon.set_color(skin.color(&"ink"))
	icon_column.add_child(icon)
	var text_column: VBoxContainer = UiParts.vbox(skin.num(&"space_xs"))
	text_column.name = "TextColumn"
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(text_column)
	if side > line:
		# The spacer's own separation counts toward the drop.
		var drop: float = roundf((side - line) * 0.5)
		text_column.add_theme_constant_override(&"separation", 0)
		var inner: VBoxContainer = UiParts.vbox(skin.num(&"space_xs"))
		inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_column.add_child(UiParts.spacer(drop))
		text_column.add_child(inner)
		return inner
	return text_column


func _example_row(skin: SkinData, values: PackedInt64Array, result: int, kind: StringName) -> HBoxContainer:
	var row: HBoxContainer = UiParts.hbox(0.0)
	row.name = "Example"
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	if kind == &"change":
		var before: SkinTileView = UiParts.tile(skin, values[0], EXAMPLE_TILE)
		before.name = "Before"
		before.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(before)
	else:
		row.add_child(UiParts.chain_board(skin, values, EXAMPLE_TILE))
	row.add_child(UiParts.spacer(0.0, skin.num(&"space_m")))
	row.add_child(UiParts.arrow(skin, EXAMPLE_ARROW))
	row.add_child(UiParts.spacer(0.0, skin.num(&"space_m")))
	var tile: SkinTileView = UiParts.tile(skin, result, EXAMPLE_TILE)
	tile.name = "Result"
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tile)
	return row
