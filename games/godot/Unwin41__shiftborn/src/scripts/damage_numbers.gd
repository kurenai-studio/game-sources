class_name DamageNumbers
extends Node2D
## Floating damage numbers, all drawn by this one node so hundreds of hits
## cost one draw call batch instead of hundreds of Label nodes. The oldest
## number is dropped when [member max_active] is reached.

const LIFETIME := 0.55
## Pixels a number rises over its lifetime.
const RISE := 14.0
const FONT_SIZE := 8
const OUTLINE_SIZE := 3
const TEXT_WIDTH := 40.0
const MAX_ACTIVE_HIGH := 80
const MAX_ACTIVE_LOW := 30
const COLOR := Color(1.0, 0.95, 0.8)
## Hits on a resisted form: grey, so the player sees the attack is weak.
const RESISTED_COLOR := Color(0.6, 0.6, 0.66)
## Critical hits: bigger and gold.
const CRIT_COLOR := Color(1.0, 0.78, 0.2)
const CRIT_FONT_SIZE := 16
const IMMUNE_TEXT := "IMMUNE"
## At most one IMMUNE popup this often, so a bolt spray does not flood it.
const IMMUNE_INTERVAL := 0.2
const OUTLINE_COLOR := Color(0.05, 0.03, 0.08, 0.9)
## Numbers start a bit above the enemy's feet.
const START_OFFSET := Vector2(0.0, -10.0)
const UNSHADED := preload("res://assets/fx/unshaded.tres")
const FONT := preload("res://assets/fx/ui_font.tres")
## Shaped text is cached per string; damage values repeat a lot.
const MAX_CACHED_LINES := 64

var max_active: int = MAX_ACTIVE_HIGH

## Parallel arrays, oldest first: cheaper than a Dictionary per number.
var _positions: PackedVector2Array = []
var _texts: PackedStringArray = []
var _ages: PackedFloat32Array = []
var _colors: PackedColorArray = []
var _sizes: PackedInt32Array = []
var _lines: Dictionary[String, TextLine] = {}
var _immune_cooldown: float = 0.0


static func format_amount(amount: float) -> String:
	if amount >= 10.0 or is_equal_approx(amount, roundf(amount)):
		return str(roundi(amount))
	return "%.1f" % amount


func _init() -> void:
	max_active = MAX_ACTIVE_HIGH if Quality.is_high() else MAX_ACTIVE_LOW
	z_index = 20
	material = UNSHADED


func spawn(at: Vector2, amount: float, resisted: bool = false, crit: bool = false) -> void:
	if amount <= 0.0:
		if resisted and _immune_cooldown <= 0.0:
			_immune_cooldown = IMMUNE_INTERVAL
			spawn_text(at, IMMUNE_TEXT, RESISTED_COLOR, FONT_SIZE)
		return
	if _positions.size() >= max_active:
		_remove_oldest()
	_positions.append(at + START_OFFSET)
	_texts.append(format_amount(amount))
	_ages.append(0.0)
	if crit and not resisted:
		_colors.append(CRIT_COLOR)
		_sizes.append(CRIT_FONT_SIZE)
	else:
		_colors.append(RESISTED_COLOR if resisted else COLOR)
		_sizes.append(FONT_SIZE)


## A word instead of a number, e.g. "PERFECT" over the player.
func spawn_text(at: Vector2, text: String, color: Color, font_size: int = CRIT_FONT_SIZE) -> void:
	if _positions.size() >= max_active:
		_remove_oldest()
	_positions.append(at + START_OFFSET)
	_texts.append(text.to_upper())
	_ages.append(0.0)
	_colors.append(color)
	_sizes.append(font_size)


func size_of_newest() -> int:
	return _sizes[_sizes.size() - 1] if not _sizes.is_empty() else FONT_SIZE


func color_of_newest() -> Color:
	return _colors[_colors.size() - 1] if not _colors.is_empty() else COLOR


func count() -> int:
	return _positions.size()


func oldest_position() -> Vector2:
	return _positions[0] - START_OFFSET if not _positions.is_empty() else Vector2.ZERO


## Ages every number by [param delta] and drops the expired ones.
func advance(delta: float) -> void:
	_immune_cooldown = maxf(_immune_cooldown - delta, 0.0)
	for i in _ages.size():
		_ages[i] += delta
	while not _ages.is_empty() and _ages[0] >= LIFETIME:
		_remove_oldest()


func _process(delta: float) -> void:
	var had_numbers := not _positions.is_empty()
	advance(delta)
	if had_numbers:
		queue_redraw()


func _draw() -> void:
	var canvas := get_canvas_item()
	for i in _positions.size():
		var t := _ages[i] / LIFETIME
		var alpha := 1.0 - t * t
		var line := _line_for(_texts[i], _sizes[i])
		var at := _positions[i] + Vector2(-line.width * 0.5, -RISE * t - line.get_line_ascent())
		line.draw_outline(canvas, at, OUTLINE_SIZE, Color(OUTLINE_COLOR, OUTLINE_COLOR.a * alpha))
		line.draw(canvas, at, Color(_colors[i], alpha))


func _line_for(text: String, font_size: int = FONT_SIZE) -> TextLine:
	var key := "%s@%d" % [text, font_size]
	var line: TextLine = _lines.get(key)
	if line != null:
		return line
	if _lines.size() >= MAX_CACHED_LINES:
		_lines.clear()
	line = TextLine.new()
	line.add_string(text, FONT, font_size)
	# Numbers share one width; longer words ("PERFECT") get their own.
	line.width = maxf(TEXT_WIDTH, line.get_size().x)
	line.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lines[key] = line
	return line


func _remove_oldest() -> void:
	_positions.remove_at(0)
	_texts.remove_at(0)
	_ages.remove_at(0)
	_colors.remove_at(0)
	_sizes.remove_at(0)
