class_name InventoryGrid
extends RefCounted
## Inventário em grade estilo Diablo: cada item ocupa wxh células.

signal changed

var cols: int
var rows: int
var items: Array[Item] = []


func _init(c: int = 10, r: int = 6) -> void:
	cols = c
	rows = r


func in_bounds(item: Item, pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x + item.size.x <= cols and pos.y + item.size.y <= rows


func overlapping(item: Item, pos: Vector2i) -> Array[Item]:
	var out: Array[Item] = []
	var r: Rect2i = Rect2i(pos, item.size)
	for other in items:
		if other == item:
			continue
		if r.intersects(Rect2i(other.grid_pos, other.size)):
			out.append(other)
	return out


func can_place(item: Item, pos: Vector2i) -> bool:
	return in_bounds(item, pos) and overlapping(item, pos).is_empty()


func find_space(item: Item) -> Vector2i:
	for x in cols:
		for y in rows:
			var p: Vector2i = Vector2i(x, y)
			if can_place(item, p):
				return p
	return Vector2i(-1, -1)


func place(item: Item, pos: Vector2i) -> void:
	item.grid_pos = pos
	if not items.has(item):
		items.append(item)
	changed.emit()


func add(item: Item) -> bool:
	var p := find_space(item)
	if p.x < 0:
		return false
	place(item, p)
	Game.quest_log.notify_collect()  # Fase 4: objetivos COLLECT
	return true


func remove(item: Item) -> void:
	items.erase(item)
	changed.emit()


func item_at(cell: Vector2i) -> Item:
	for it in items:
		if Rect2i(it.grid_pos, it.size).has_point(cell):
			return it
	return null


func to_array() -> Array:
	var out: Array = []
	for it in items:
		out.append(it.to_dict())
	return out


func load_array(arr: Array) -> void:
	items.clear()
	for d in arr:
		var it := Item.from_dict(d)
		if can_place(it, it.grid_pos):
			items.append(it)
		else:
			add(it)
	changed.emit()
