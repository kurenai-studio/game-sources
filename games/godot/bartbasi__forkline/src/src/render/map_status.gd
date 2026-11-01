# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name MapStatus
extends Node2D
## Health bars for hurt creatures, the drowsy and bubble marks, and the boost marks, in one
## overlay (docs/ARCHITECTURE.md 9.3). The marks are regions of the MapAtlas texture. The
## overlay is redrawn only while something needs it. Internal to src/render/.

const CELL: float = 128.0
## A creature wears its marks this much smaller than its box, so a crowd stays readable, but never
## smaller than MARK_MIN_SIZE (in cells), so a Pip's mark can still be read. The low ring marks the
## shadow line, which is 0.40 of the full box below the creature, so it is never made smaller.
const MARK_SCALE: float = 0.8
const MARK_MIN_SIZE: float = 0.5
## The tower the doze mark is drawn for is the tower's own drawing (MapAtlas.TOWER_SCALE).
const DOZE_SCALE: float = MapAtlas.TOWER_SCALE


## What to draw for one creature this frame.
class Item:
	extends RefCounted
	var center: Vector2 = Vector2.ZERO
	var size: float = 0.0
	var hp: float = 1.0
	var bar: bool = false
	var drowsy: bool = false
	var bubble: bool = false
	var frame: int = 0
	## Status marks: bit i is Silhouettes.MARKS[i]. Not &"dug" and not &"doze" (see MapView).
	var marks: int = 0
	## Where the shadow line of a flyer is measured from: its flight line, above the body when it is low.
	var ground_center: Vector2 = Vector2.ZERO


var items: Array[Item] = []
var boosted: Array[Vector2] = []
## Centers (as draw_tower takes them) of the towers that doze.
var dozing: Array[Vector2] = []
var atlas: MapAtlas
var _drawn_last: bool = false


## Replaces the lists. Redraws while they are not empty, and once more when they empty.
func set_items(new_items: Array[Item], new_boosted: Array[Vector2], new_dozing: Array[Vector2] = []) -> void:
	items = new_items
	boosted = new_boosted
	dozing = new_dozing
	var busy: bool = not items.is_empty() or not boosted.is_empty() or not dozing.is_empty()
	if busy or _drawn_last:
		queue_redraw()
	_drawn_last = busy


func _draw() -> void:
	if atlas == null:
		return
	var tex: Texture2D = atlas.get_texture()
	var bubble: MapAtlas.Entry = atlas.entry_for("m:bubble")
	var boost: MapAtlas.Entry = atlas.entry_for("m:boost")
	var drowsy: Array[MapAtlas.Entry] = []
	for f: int in 4:
		drowsy.append(atlas.entry_for("m:drowsy:%d" % f))
	# Textured marks first, then the bars: one texture in a row batches into one draw call.
	for it: Item in items:
		var k: float = it.size / CELL
		if it.bubble and bubble != null:
			draw_texture_rect_region(tex, Rect2(it.center - bubble.anchor * k, bubble.tile * k), bubble.rect)
		if it.drowsy:
			var d: MapAtlas.Entry = drowsy[it.frame & 3]
			if d != null:
				draw_texture_rect_region(tex, Rect2(it.center - d.anchor * k, d.tile * k), d.rect)
		if it.marks != 0:
			_draw_marks(tex, it)
	var doze: MapAtlas.Entry = atlas.entry_for(MapAtlas.mark_key(&"doze", 0))
	if doze != null:
		for t: Vector2 in dozing:
			draw_texture_rect_region(tex, Rect2(t - doze.anchor * DOZE_SCALE, doze.tile * DOZE_SCALE), doze.rect)
	if boost != null:
		for b: Vector2 in boosted:
			draw_texture_rect_region(tex, Rect2(b - boost.anchor, boost.tile), boost.rect)
	for it: Item in items:
		if it.bar:
			var w: float = maxf(it.size * 0.7, CELL * 0.3)
			var h: float = maxf(it.size * 0.09, 5.0)
			var bar: Rect2 = Rect2(it.center.x - w * 0.5, it.center.y - it.size * 0.62, w, h)
			draw_rect(bar.grow(3.0), Palette.INK_LINE)
			draw_rect(bar, Palette.HP_BACK)
			draw_rect(Rect2(bar.position, Vector2(w * clampf(it.hp, 0.0, 1.0), h)), Palette.HP_FILL)


## The marks one creature wears. They are regions of the sheet, sized to the creature's box.
func _draw_marks(tex: Texture2D, it: Item) -> void:
	var small: float = maxf(it.size * MARK_SCALE, MARK_MIN_SIZE * CELL) / CELL
	var full: float = it.size / CELL
	for i: int in Silhouettes.MARKS.size():
		if it.marks & (1 << i) == 0:
			continue
		var e: MapAtlas.Entry = atlas.entry_for(MapAtlas.mark_key(Silhouettes.MARKS[i], 0))
		if e == null:
			continue
		var low: bool = Silhouettes.MARKS[i] == &"low"
		var k: float = full if low else small
		var at: Vector2 = it.ground_center if low else it.center
		draw_texture_rect_region(tex, Rect2(at - e.anchor * k, e.tile * k), e.rect)
