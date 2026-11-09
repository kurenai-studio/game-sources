extends RefCounted
class_name LayoutFit
## Pure layout math for portrait playfield (board + tray above bottom chrome).

const GAP := 5
const BOARD_SZ := 8
const HUD_HEIGHT := 144.0
const CHROME_TOP_OFFSET := 132.0
const TRAY_GAP := 26.0
const MIN_CELL := 26


static func tray_box_w(view_w: float, margin_l: float, margin_r: float) -> float:
	var inner_w: float = view_w - margin_l - margin_r
	return minf(210.0, (inner_w - 48.0) / 3.0 - 8.0)


static func board_span(cell: int) -> float:
	return float(BOARD_SZ) * float(cell + GAP)


static func compute(view: Vector2, margin_l: float, margin_t: float, margin_r: float, margin_b: float) -> Dictionary:
	var inner_w: float = view.x - margin_l - margin_r
	var hud_bottom: float = margin_t + HUD_HEIGHT
	var chrome_top: float = view.y - margin_b - CHROME_TOP_OFFSET
	var avail_h: float = maxf(chrome_top - hud_bottom, 80.0)
	var box_w: float = tray_box_w(view.x, margin_l, margin_r)
	var tray_block: float = TRAY_GAP + box_w
	var max_board_h: float = avail_h - tray_block
	var cell_w: int = maxi(int((inner_w - 36.0) / float(BOARD_SZ)) - GAP, MIN_CELL)
	var cell_h: int = maxi(int(max_board_h / float(BOARD_SZ)) - GAP, MIN_CELL)
	var cell: int = mini(cell_w, cell_h)
	while cell > MIN_CELL:
		var span := board_span(cell)
		if span <= inner_w - 36.0 and span + tray_block <= avail_h:
			break
		cell -= 1
	var board_w: float = board_span(cell)
	var origin := Vector2(margin_l + (inner_w - board_w) * 0.5, hud_bottom)
	var tray_top: float = origin.y + board_w + TRAY_GAP
	var tray_bottom: float = tray_top + box_w
	return {
		"cell": cell,
		"origin": origin,
		"box_w": box_w,
		"tray_top": tray_top,
		"tray_bottom": tray_bottom,
		"chrome_top": chrome_top,
	}


static func fits(view: Vector2, margin_l: float, margin_t: float, margin_r: float, margin_b: float) -> bool:
	var m: Dictionary = compute(view, margin_l, margin_t, margin_r, margin_b)
	return float(m["tray_bottom"]) <= float(m["chrome_top"]) - 1.0
