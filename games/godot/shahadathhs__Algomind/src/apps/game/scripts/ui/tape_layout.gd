class_name TapeLayout
extends RefCounted
## Places the cells of the tape in strip coordinates (before scroll): the tile rectangles, the
## brackets of procedures, loops and IFs (nested as the cells' `groups` say), the dashed slot
## where the next tile goes, and the divider between the definitions and the main program.

const PAD := 12.0
## Room between a bracket and its tiles, and between a bracket and its neighbours.
const GROUP_PAD := 5.0


## `metrics` has tile, pitch and top (pixels), editing (no run is shown) and room (the program
## is below its command limit). `open_keys` are the keys of the open groups,
## outermost first; the slot goes inside the innermost one, else after the last tile. Returns
## { rects, groups, dashed, slot, divider, end }: `divider` is the x between definitions and
## the main program (-1 when there is none) and `end` the x just past the strip.
static func compute(cells: Array[Dictionary], metrics: Dictionary, open_keys: Array) -> Dictionary:
	var out := {
		"rects": [] as Array[Rect2],
		"groups": [] as Array[Rect2],
		"dashed": [] as Array[bool],
		"slot": Rect2(),
		"divider": -1.0,
		"end": 0.0,
	}
	var tile: float = metrics["tile"]
	var pitch: float = metrics["pitch"]
	var top: float = metrics["top"]
	var innermost: String = "" if open_keys.is_empty() else String(open_keys.back())
	var show_slot: bool = metrics["editing"] and metrics["room"]
	var x := PAD
	var stack: Array[Dictionary] = []
	var in_defs := false
	for cell in cells:
		var want: Array = cell["groups"]
		var keep := 0
		while keep < stack.size() and keep < want.size() and stack[keep]["key"] == want[keep]:
			keep += 1
		while stack.size() > keep:
			x = _close(out, stack.pop_back(), x, metrics, innermost)
		var is_def := int(cell["proc"]) >= 0
		if in_defs and not is_def:
			# The main program starts here: a little room and a divider after the definitions.
			out["divider"] = x - (pitch - tile) / 2.0 + tile * 0.25
			x += tile * 0.5
		in_defs = is_def
		for g in range(keep, want.size()):
			x += GROUP_PAD
			stack.append({"key": want[g], "start": x})
			x += GROUP_PAD
		(out["rects"] as Array[Rect2]).append(Rect2(Vector2(x, top), Vector2(tile, tile)))
		x += pitch
	while not stack.is_empty():
		x = _close(out, stack.pop_back(), x, metrics, innermost)
	if (out["slot"] as Rect2).size == Vector2.ZERO and show_slot:
		out["slot"] = Rect2(Vector2(x, top), Vector2(tile, tile))
		x += pitch
	out["end"] = x + PAD
	return out


## Ends the bracket of `group`; returns the x after it. The slot of the next command goes inside
## it when it is the innermost open group.
static func _close(
	out: Dictionary, group: Dictionary, x: float, metrics: Dictionary, innermost: String
) -> float:
	var tile: float = metrics["tile"]
	var pitch: float = metrics["pitch"]
	var top: float = metrics["top"]
	var open: bool = group["key"] == innermost
	if open and metrics["editing"] and metrics["room"]:
		out["slot"] = Rect2(Vector2(x, top), Vector2(tile, tile))
		x += pitch
	var gap := pitch - tile
	var end_x := x - gap + GROUP_PAD
	var start: float = group["start"]
	(out["groups"] as Array[Rect2]).append(
		Rect2(start, top - GROUP_PAD, end_x - start, tile + 2.0 * GROUP_PAD)
	)
	(out["dashed"] as Array[bool]).append(open and metrics["editing"])
	return end_x + gap
