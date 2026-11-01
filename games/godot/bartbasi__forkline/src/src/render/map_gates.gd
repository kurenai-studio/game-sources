# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name MapGates
extends Node2D
## Gates on their sockets: closed, fixed, broken, open, the open socket ring, and the crossed
## out refused gate. Each look is a region of the MapAtlas sheet, so a gate is one batched
## draw, not the hundred lines it takes to draw one. Redrawn only when the list changes, and
## every frame while a breaker works on a gate: that gate shakes and a crack grows across it.
## Internal to src/render/.

const CELL: float = 128.0
## A crack across the gate, as points along the gate's width (-1 to 1) and across it.
const CRACK: Array[Vector2] = [
	Vector2(-0.34, -0.06), Vector2(-0.22, 0.07), Vector2(-0.11, -0.05), Vector2(0.0, 0.08),
	Vector2(0.1, -0.07), Vector2(0.22, 0.06), Vector2(0.34, -0.04),
]

var grid: PackedStringArray = PackedStringArray()
var atlas: MapAtlas
var cells: Array[Vector2i] = []
var looks: Array[int] = []
var redraws: int = 0
## Gates being broken right now, and how far along each is (0 to 1). Set by set_cracking().
var cracking: Array[Vector2i] = []
var crack_progress: PackedFloat32Array = PackedFloat32Array()
var now: float = 0.0
var _crack_drawn: bool = false


## Sets the list. Returns true when it changed and a redraw was queued.
func set_gates(new_cells: Array[Vector2i], new_looks: Array[int]) -> bool:
	if new_cells == cells and new_looks == looks:
		return false
	cells = new_cells.duplicate()
	looks = new_looks.duplicate()
	redraws += 1
	queue_redraw()
	return true


## Sets the gates that are being broken, each with its progress. Redraws every frame while the
## list is not empty, and once more when it empties.
func set_cracking(new_cells: Array[Vector2i], progress: PackedFloat32Array, time_now: float) -> void:
	now = time_now
	cracking = new_cells
	crack_progress = progress
	if not cracking.is_empty() or _crack_drawn:
		redraws += 1
		queue_redraw()
	_crack_drawn = not cracking.is_empty()


func _draw() -> void:
	if atlas == null:
		return
	var tex: Texture2D = atlas.get_texture()
	for i: int in cells.size():
		var across: bool = MapArt.road_runs_vertically(grid, cells[i])
		var e: MapAtlas.Entry = atlas.entry_for(MapAtlas.gate_key(looks[i], across))
		if e == null:
			continue
		var c: Vector2 = (Vector2(cells[i]) + Vector2(0.5, 0.5)) * CELL
		var at: int = cracking.find(cells[i])
		var shake: Vector2 = Vector2.ZERO
		if at >= 0:
			var wobble: float = sin(now * 52.0) * CELL * 0.018
			shake = Vector2(0.0, wobble) if across else Vector2(wobble, 0.0)
		draw_texture_rect_region(tex, Rect2(c - e.anchor + shake, e.tile), e.rect)
		if at >= 0:
			_draw_crack(c + shake, across, crack_progress[at])


## The crack grows along the gate, left to right, as the breaking goes on.
func _draw_crack(c: Vector2, across: bool, progress: float) -> void:
	var shown: int = clampi(int(ceilf(progress * float(CRACK.size()))), 1, CRACK.size())
	var pts: PackedVector2Array = PackedVector2Array()
	for j: int in shown:
		var q: Vector2 = CRACK[j] * CELL
		pts.append(c + (Vector2(q.y, q.x) if across else q))
	if pts.size() < 2:
		pts.append(pts[0] + Vector2(2.0, 2.0))
	draw_polyline(pts, Palette.INK_LINE, CELL * 0.045, true)
	draw_polyline(pts, Palette.PLASTER, CELL * 0.016, true)


## The sheet was laid out again: the regions moved, so draw again.
func refresh() -> void:
	queue_redraw()
