extends "res://src/ui/reading_screen.gd"
## One license text (DESIGN_SYSTEM.md 7.14), opened from an About row inside
## AboutPanel: a reading screen titled "SumUp license", "Godot Engine" or
## "Outfit font". The text sits straight on the backdrop in every skin, no
## card: paragraphs in the reading role space_s apart, headings in the
## heading role with space_m above, part and license names in the body role,
## and each rule line of the source as the skin's divider. The texts are
## reflowed for the phone (license_texts.gd).
##
## One label per paragraph, never one label for the whole text. The build
## runs in stages, one step per frame (7.14, "Building the view"):
## - LAYOUT: wait for the page's first layout, so every label is shaped at
##   its final width, once;
## - FIRST: build the paragraphs that fill the scroll area, while the view is
##   still invisible (a frame or two);
## - FADING: the fade in runs, and nothing is built, so it runs at full rate;
## - REST: build the rest a little each frame, so every frame stays within
##   16.7 ms with its layout and drawing; the page grows below the reader;
## - DONE.
## Each label joins the page before its text is set, so it has its final
## font, and takes its width first, so its text is shaped once.

const LicenseTexts: GDScript = preload("res://src/ui/license_texts.gd")
## Blocks per column inside the page, so a re-sort of the page touches a few
## columns rather than every label built so far.
const COLUMN_SIZE: int = 12
## What one frame may build, in characters of text. Shaping a label is
## cheap; its first draw in the same frame costs about 7 ms per 1,000
## characters on the desktop, wherever it sits on the page, so the text, not
## the time spent making labels, sets the pace (every frame within 16.7 ms,
## 7.14). At least one block is built per frame, so even the longest
## paragraph (1,463 characters, about 11 ms) gets a frame of its own.
const FIRST_CHARACTERS: int = 700
const REST_CHARACTERS: int = 450

enum Stage { LAYOUT, FIRST, FADING, REST, DONE }

var _id: StringName = &""
var _blocks: Array[Dictionary] = []
var _blocks_ready: bool = false
var _built: int = 0
var _labels: int = 0
var _body: VBoxContainer = null
var _column: VBoxContainer = null
var _stage: Stage = Stage.LAYOUT
var _fade_wanted: bool = false
## Height of what is built, in px, the gaps included.
var _built_height: float = 0.0
## Time from setup to the last label, in microseconds; 0 while building.
var build_usec: int = 0
## Time from setup to the start of the fade (the first screenful built).
var first_screen_usec: int = 0
var _started_usec: int = 0


func setup(skin: SkinData, id: StringName) -> void:
	_id = id
	_started_usec = Time.get_ticks_usec()
	build_usec = 0
	first_screen_usec = 0
	_fade_wanted = false
	_frame(skin, String(Copy.LICENSE_TITLES.get(id, "")))
	_body = UiParts.vbox(skin.num(&"space_s"))
	_body.name = "Text"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sections.add_child(_body)
	_column = null
	# The text is read and reflowed on the next frame (_ensure_blocks), not in
	# the frame of the tap.
	_blocks = []
	_blocks_ready = false
	_built = 0
	_labels = 0
	_built_height = 0.0
	_stage = Stage.LAYOUT
	if is_inside_tree() and not get_tree().process_frame.is_connected(_next_batch):
		get_tree().process_frame.connect(_next_batch)


## Fades the view in once its first screenful is built (7.14); until then it
## stays invisible over About.
func play_in() -> void:
	if _skin == null:
		return
	_fade_wanted = true
	modulate.a = 0.0
	if _stage == Stage.REST or _stage == Stage.DONE:
		_start_fade()


## Rebuilds the view in a new skin, still open (and already visible).
func apply_skin(skin: SkinData) -> void:
	setup(skin, _id)


## The license shown.
func license_id() -> StringName:
	return _id


## True once every block is built.
func is_built() -> bool:
	_ensure_blocks()
	return _built >= _blocks.size()


func _ensure_blocks() -> void:
	if not _blocks_ready:
		_blocks = LicenseTexts.blocks(_id)
		_blocks_ready = true


## The build's stage, a Stage value. For tests.
func stage() -> int:
	return _stage


## One frame of the build, for the page's width and the scroll area's
## height. Each frame calls it; tests call it with sizes of their own.
func step(width: float, view_height: float) -> void:
	if _stage == Stage.LAYOUT:
		# The frame after the tap: read and reflow the text, and wait for the
		# page's width.
		if not _blocks_ready:
			_ensure_blocks()
			return
		if width <= 0.0:
			return
		_stage = Stage.FIRST
	match _stage:
		Stage.FIRST:
			_build(FIRST_CHARACTERS, width, view_height)
			if _built_height >= view_height or is_built():
				_first_screen_built()
		Stage.REST:
			_build(REST_CHARACTERS, width, INF)
			if is_built():
				_stage = Stage.DONE


## The fade in has ended: the rest may build. The fade's tween calls it;
## tests call it.
func fade_finished() -> void:
	if _stage == Stage.FADING:
		_stage = Stage.DONE if is_built() else Stage.REST


## Builds every block left now. For tests.
func finish() -> void:
	_ensure_blocks()
	var width: float = _body.size.x if _body != null else 0.0
	_build(-1, width, INF)
	if _stage == Stage.LAYOUT or _stage == Stage.FIRST:
		_first_screen_built()
	elif _stage == Stage.REST:
		_stage = Stage.DONE


## Everything the view shows, label by label, blank lines between. Rules
## hold no text.
func shown_text() -> String:
	_ensure_blocks()
	var parts: PackedStringArray = PackedStringArray()
	for block: Dictionary in _blocks:
		if int(block["kind"]) != LicenseTexts.Kind.RULE:
			parts.append(_shown(block))
	return "\n\n".join(parts)


## The labels built so far. For tests.
func label_count() -> int:
	return _labels


## The dividers built so far, one per rule line. For tests.
func rule_count() -> int:
	var count: int = 0
	if _body != null:
		count = _body.find_children("*", "HSeparator", true, false).size()
	return count


func _next_batch() -> void:
	if _closing or not is_inside_tree():
		_stop_batches()
		return
	step(_body.size.x, _scroll.size.y)
	if _stage == Stage.DONE:
		_stop_batches()


func _first_screen_built() -> void:
	first_screen_usec = Time.get_ticks_usec() - _started_usec
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


## Builds blocks until characters of text are built (-1 for no limit) or
## what is built reaches height_goal. At least one block per call, so it
## always moves on.
func _build(characters: int, width: float, height_goal: float) -> void:
	_ensure_blocks()
	var made: int = 0
	var spent: int = 0
	while _built < _blocks.size():
		var block: Dictionary = _blocks[_built]
		var length: int = String(block["text"]).length()
		if made > 0 and characters >= 0 and spent + length > characters:
			break
		if _built_height >= height_goal:
			break
		_add_block(block, width, characters >= 0)
		_built += 1
		made += 1
		spent += length
	if is_built() and build_usec == 0:
		build_usec = Time.get_ticks_usec() - _started_usec


func _add_block(block: Dictionary, width: float, shape_now: bool) -> void:
	if _column == null or _column.get_child_count() >= COLUMN_SIZE:
		_column = UiParts.vbox(_skin.num(&"space_s"))
		_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_body.add_child(_column)
		if width > 0.0:
			_column.size = Vector2(width, _column.size.y)
	var gap: float = _skin.num(&"space_s")
	var kind: int = int(block["kind"])
	if kind == LicenseTexts.Kind.RULE:
		var rule: HSeparator = UiParts.divider()
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_column.add_child(rule)
		_built_height += rule.get_combined_minimum_size().y + gap
		return
	if kind == LicenseTexts.Kind.HEADING and _built > 0:
		var space: float = _skin.num(&"space_m") - gap
		_column.add_child(UiParts.spacer(space))
		_built_height += space + gap
	var variation: StringName = &"ReadingLabel"
	if kind == LicenseTexts.Kind.HEADING:
		variation = &"HeadingLabel"
	elif kind == LicenseTexts.Kind.NAME:
		variation = &"BodyLabel"
	var made: Label = UiParts.paragraph(_skin, variation, "", HORIZONTAL_ALIGNMENT_LEFT)
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(made)
	if width > 0.0:
		made.size = Vector2(width, 0.0)
	made.text = _shown(block)
	if shape_now:
		# Shape it now, inside the budget, and settle its size so the page's
		# layout finds nothing left to do for it.
		var height: float = made.get_minimum_size().y
		if width > 0.0:
			made.size = Vector2(width, height)
		_built_height += height + gap
	_labels += 1


func _stop_batches() -> void:
	if is_inside_tree() and get_tree().process_frame.is_connected(_next_batch):
		get_tree().process_frame.disconnect(_next_batch)


## The text a block shows: headings take the heading role's case rule;
## names, paragraphs and the missing text message show as written.
func _shown(block: Dictionary) -> String:
	if int(block["kind"]) == LicenseTexts.Kind.HEADING:
		return _skin.cased(&"heading", String(block["text"]))
	return String(block["text"])


func _exit_tree() -> void:
	_stop_batches()
