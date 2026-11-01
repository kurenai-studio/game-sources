# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name MapLeaks
extends Node2D
## The heart that floats up from the home and fades when a creature gets through (the dull
## puff beside it is a MapSparkles burst). A fixed pool of SLOTS, so nothing is allocated
## while it plays: an event past the pool reuses the oldest heart. A creature worth more
## than one life shows its count on the heart ("-3"), and a boss gets a bigger heart. The
## heart is a region of the MapAtlas sheet, so the shape reads without any color. Several
## creatures through within MERGE_SECONDS share one heart and add up. Internal to src/render/.

const CELL: float = 128.0
const SLOTS: int = 6
const SECONDS: float = 0.8
const MERGE_SECONDS: float = 0.12
## Heart size in cells: one life, several lives, a boss.
const SIZE_ONE: float = 0.62
const SIZE_MANY: float = 0.84
const SIZE_BOSS: float = 1.05
## How high the heart climbs, in cells, and where it starts above the home's center.
const RISE: float = 0.9
const START_UP: float = 0.3


class Slot:
	extends RefCounted
	var active: bool = false
	var at: Vector2 = Vector2.ZERO
	var lives: int = 0
	var boss: bool = false
	var t0: float = 0.0
	var side: float = 0.0
	var text: String = ""


## Draws the numbers in normal blending (the hearts use the sheet's premultiplied blend).
class TextLayer:
	extends Node2D
	var owner_layer: MapLeaks

	func _draw() -> void:
		owner_layer.draw_text(self)


var atlas: MapAtlas
## Hearts started, merged ones not counted again.
var started: int = 0

var _slots: Array[Slot] = []
var _text: TextLayer
var _now: float = 0.0
var _drawn_last: bool = false


func _init() -> void:
	for i: int in SLOTS:
		_slots.append(Slot.new())
	_text = TextLayer.new()
	_text.owner_layer = self
	add_child(_text)


func active_count() -> int:
	var n: int = 0
	for s: Slot in _slots:
		if s.active:
			n += 1
	return n


## The lives written on the heart in slot `i`, 0 when it is not showing.
func lives_in(i: int) -> int:
	return _slots[i].lives if _slots[i].active else 0


## True when slot `i` shows a number (more than one life).
func shows_count(i: int) -> bool:
	return _slots[i].active and not _slots[i].text.is_empty()


## Starts a heart at the home `at` (map pixels) worth `lives`, at time `at_time`.
func spawn(at: Vector2, lives: int, boss: bool, at_time: float) -> void:
	_now = at_time
	for s: Slot in _slots:
		if s.active and at_time - s.t0 < MERGE_SECONDS and at_time >= s.t0:
			s.lives += lives
			s.boss = s.boss or boss
			_set_text(s)
			_wake()
			return
	var pick: Slot = _slots[0]
	for s: Slot in _slots:
		if not s.active:
			pick = s
			break
		if s.t0 < pick.t0:
			pick = s
	pick.active = true
	pick.at = at
	pick.lives = lives
	pick.boss = boss
	pick.t0 = at_time
	pick.side = float((started % 5) - 2) * 0.16 * CELL
	started += 1
	_set_text(pick)
	_wake()


## Moves the clock on and ends hearts that finished.
func advance(time_now: float) -> void:
	_now = time_now
	var busy: bool = false
	for s: Slot in _slots:
		if s.active and (time_now - s.t0 >= SECONDS or time_now < s.t0):
			s.active = false
		busy = busy or s.active
	if busy:
		_redraw()
		_drawn_last = true
	elif _drawn_last:
		_drawn_last = false
		_redraw()


func is_busy() -> bool:
	return active_count() > 0


## Size in cells of a heart worth `lives`.
static func size_cells(lives: int, boss: bool) -> float:
	if boss:
		return SIZE_BOSS
	return SIZE_MANY if lives > 1 else SIZE_ONE


func _set_text(s: Slot) -> void:
	s.text = "-%d" % s.lives if s.lives > 1 else ""


func _wake() -> void:
	_redraw()
	_drawn_last = true


func _redraw() -> void:
	queue_redraw()
	_text.queue_redraw()


## Where a heart is and how big it is drawn, at progress `u` (0 to 1): x, y, pop scale, alpha.
func _look(s: Slot) -> Vector4:
	var u: float = clampf((_now - s.t0) / SECONDS, 0.0, 1.0)
	var rise: float = 1.0 - (1.0 - u) * (1.0 - u)
	var x: float = s.at.x + s.side + sin(u * TAU) * 0.04 * CELL
	var y: float = s.at.y - (START_UP + RISE * rise) * CELL
	var pop: float = 1.0
	if u < 0.15:
		pop = lerpf(0.4, 1.15, u / 0.15)
	elif u < 0.3:
		pop = lerpf(1.15, 1.0, (u - 0.15) / 0.15)
	var alpha: float = 1.0 if u < 0.55 else 1.0 - (u - 0.55) / 0.45
	return Vector4(x, y, pop, clampf(alpha, 0.0, 1.0))


func _draw() -> void:
	if atlas == null:
		return
	var e: MapAtlas.Entry = atlas.entry_for("m:heart")
	if e == null:
		return
	for s: Slot in _slots:
		if not s.active:
			continue
		var l: Vector4 = _look(s)
		var k: float = size_cells(s.lives, s.boss) * l.z
		var a: float = l.w
		# The sheet is premultiplied, so a fade scales the color too.
		draw_texture_rect_region(atlas.get_texture(), Rect2(Vector2(l.x, l.y) - e.anchor * k, e.tile * k), e.rect, Color(a, a, a, a))


func draw_text(layer: Node2D) -> void:
	var font: Font = UiTheme.font(UiTheme.WEIGHT_BOLD)
	for s: Slot in _slots:
		if not s.active or s.text.is_empty():
			continue
		var l: Vector4 = _look(s)
		var size_c: float = size_cells(s.lives, s.boss)
		var fs: int = int(roundf(CELL * (0.42 if s.boss else 0.34)))
		layer.draw_set_transform(Vector2(l.x, l.y + size_c * CELL * 0.13), 0.0, Vector2(l.z, l.z))
		var base: Vector2 = Vector2(-CELL, (font.get_ascent(fs) - font.get_descent(fs)) * 0.5)
		layer.draw_string_outline(font, base, s.text, HORIZONTAL_ALIGNMENT_CENTER, CELL * 2.0, fs, 9, Color(Palette.INK_LINE, l.w))
		layer.draw_string(font, base, s.text, HORIZONTAL_ALIGNMENT_CENTER, CELL * 2.0, fs, Color(Palette.TEXT_LIGHT, l.w))
	layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
