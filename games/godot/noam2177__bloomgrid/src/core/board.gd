class_name Board
extends RefCounted
## לוח 8×8. 0 = תא ריק, 1–6 = צבע.
## ניקוי: שורה מלאה או עמודה מלאה. שתיהן באותו מהלך = סופרנובה.

const SIZE := 8

var cells: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	cells.resize(SIZE * SIZE)
	cells.fill(0)


func idx(x: int, y: int) -> int:
	# שורה ראשית: y * 8 + x. בלי זה קל להתבלבל בין שורה לעמודה.
	return y * SIZE + x


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < SIZE and y < SIZE


func get_cell(x: int, y: int) -> int:
	if not in_bounds(x, y):
		return 0
	return cells[idx(x, y)]


func set_cell(x: int, y: int, v: int) -> void:
	if not in_bounds(x, y):
		return
	cells[idx(x, y)] = v


func can_place(key: String, ox: int, oy: int, rot: int = 0) -> bool:
	# ox,oy = פינה שמאלית-עליונה של החלק אחרי הסיבוב.
	if not PieceCatalog.is_known(key):
		return false
	for c in PieceCatalog.cells_of(key, rot):
		var x: int = ox + int(c.x)
		var y: int = oy + int(c.y)
		if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
			return false
		if get_cell(x, y) != 0:
			return false
	return true


func place(key: String, ox: int, oy: int, color: int, rot: int = 0) -> int:
	if not can_place(key, ox, oy, rot):
		return 0
	var n := 0
	for c in PieceCatalog.cells_of(key, rot):
		set_cell(ox + int(c.x), oy + int(c.y), color)
		n += 1
	return n


func _full_rows() -> Array[int]:
	var out: Array[int] = []
	for y in range(SIZE):
		var full := true
		for x in range(SIZE):
			if get_cell(x, y) == 0:
				full = false
				break
		if full:
			out.append(y)
	return out


func _full_cols() -> Array[int]:
	var out: Array[int] = []
	for x in range(SIZE):
		var full := true
		for y in range(SIZE):
			if get_cell(x, y) == 0:
				full = false
				break
		if full:
			out.append(x)
	return out


## מחזיר כמה קווים נמחקו + האם זו סופרנובה (שורה ועמודה יחד).
func clear_lines() -> Dictionary:
	var rows := _full_rows()
	var cols := _full_cols()
	if rows.is_empty() and cols.is_empty():
		return {"count": 0, "rows": rows, "cols": cols, "cross": false}
	for y in rows:
		for x in range(SIZE):
			set_cell(x, y, 0)
	for x in cols:
		for y in range(SIZE):
			set_cell(x, y, 0)
	return {
		"count": rows.size() + cols.size(),
		"rows": rows,
		"cols": cols,
		"cross": (not rows.is_empty()) and (not cols.is_empty()),
	}


func occupied() -> int:
	var n := 0
	for i in range(cells.size()):
		if cells[i] != 0:
			n += 1
	return n


func fits_anywhere(key: String, rot: int = 0) -> bool:
	# סריקה גסה לפי bounding box — חוסך בדיקות מחוץ ללוח.
	var wh := PieceCatalog.size_of(key, rot)
	for y in range(SIZE - int(wh.y) + 1):
		for x in range(SIZE - int(wh.x) + 1):
			if can_place(key, x, y, rot):
				return true
	return false
