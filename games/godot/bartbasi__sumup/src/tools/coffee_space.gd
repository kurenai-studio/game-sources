extends SceneTree
## Free space on the play screen for the Buy me a coffee button
## (DESIGN_SYSTEM.md 7.15). Run from the repo root:
##     godot --headless --path . --script res://tools/coffee_space.gd
##
## For each phone shape, inset case and skin it lays the play screen out the
## way GameScreen.layout_in does (DESIGN_SYSTEM.md 2.3 and 2.8): the safe
## area, the content column (SafeArea.column_in), the HUD and the bar at their
## preferred heights, and the board centered in the region between them,
## sized by the skin's real board view. It prints, in logical px: the space D
## below the board, the left gutter outside the column, the size of the one
## line button (below the board) and of the stacked button (in the gutter),
## where the 7.15 rule puts the button, and for the gutter the clearance from
## the touch area to the safe edge and to the column on each side. It only
## measures; it always exits with 0.

## One phone: its size in physical px, its density, and its inset cases as
## the top and bottom safe insets in physical px. Fold5 numbers read from
## Bart's phone by adb on 2026-10-21 (density 420, so 2.625; the cover's
## camera cutout inset 85 px). The gesture hint's inset is not reported by
## the phone; 22 dp (58 px at 2.625) is assumed as in DESIGN_SYSTEM.md 2.4.
## "No insets" is the bound for every case with smaller bars (immersive mode,
## the hint hidden and no cutout reported): a taller safe area only narrows
## the gutter, so it is the worst case for the gutter.
const PHONES: Array[Dictionary] = [
	{"name": "20:9 phone, 1080 x 2400 px at 3.0", "px": Vector2(1080, 2400), "density": 3.0,
		"cases": [["status 40 dp, gesture 22 dp", 120.0, 66.0], ["no insets", 0.0, 0.0]]},
	{"name": "Fold5 cover, 904 x 2316 px at 2.625", "px": Vector2(904, 2316), "density": 2.625,
		"cases": [["cutout 85 px, gesture hint 58 px", 85.0, 58.0], ["cutout 85 px, hint hidden", 85.0, 0.0], ["no insets", 0.0, 0.0]]},
	{"name": "Fold5 inner, 1812 x 2176 px at 2.625", "px": Vector2(1812, 2176), "density": 2.625,
		"cases": [["status 85 px, gesture hint 58 px", 85.0, 58.0], ["status 85 px, hint hidden", 85.0, 0.0], ["no insets", 0.0, 0.0], ["status 85 px, taskbar 48 dp (126 px)", 85.0, 126.0]]},
	{"name": "16:9 phone, 1080 x 1920 px at 3.0, button bar", "px": Vector2(1080, 1920), "density": 3.0,
		"cases": [["status 24 dp, button bar 48 dp", 72.0, 144.0]]},
]
const BASE: Vector2 = Vector2(1080, 2400)
const LINE: String = "Buy me a coffee"
const STACK_TOP: String = "Buy me"
const STACK_BOTTOM: String = "a coffee"
## DESIGN_SYSTEM.md 7.9: the gap between the icon and the label, as a share
## of the body role's font size.
const ICON_GAP: float = 0.25


func _initialize() -> void:
	for phone: Dictionary in PHONES:
		var px: Vector2 = phone["px"]
		# Logical canvas: keep 2400 tall when wider than 9:20, else 1080 wide.
		var scale: float = px.y / BASE.y
		if px.x / px.y < BASE.x / BASE.y:
			scale = px.x / BASE.x
		var canvas: Vector2 = px / scale
		var per_dp: float = float(phone["density"]) / scale
		print("")
		print("%s: canvas %d x %d logical px, %.3f px per dp" % [phone["name"], roundi(canvas.x), roundi(canvas.y), per_dp])
		for case: Array in phone["cases"]:
			var top: float = float(case[1]) / scale
			var bottom: float = float(case[2]) / scale
			var safe: Rect2 = Rect2(0.0, top, canvas.x, canvas.y - top - bottom)
			print("  %s: safe area y %d to %d" % [case[0], roundi(safe.position.y), roundi(safe.end.y)])
			for skin_id: StringName in SkinCatalog.IDS:
				_measure(SkinCatalog.get_skin(skin_id), safe, per_dp)
	quit(0)


func _measure(skin: SkinData, safe: Rect2, per_dp: float) -> void:
	var column: Rect2 = SafeArea.column_in(safe, skin)
	var margin: float = skin.num(&"board_margin")
	var gap: float = skin.num(&"space_s")
	var clear: float = skin.num(&"space_m")
	var touch: float = skin.num(&"touch_min")
	var board: SkinBoardView = SkinCatalog.make_board_view(skin)
	board.setup(skin, 5, 8)
	var region_top: float = column.position.y + skin.num(&"hud_height") + gap
	var bar_top: float = column.end.y - skin.num(&"bar_height")
	var region_height: float = maxf(0.0, bar_top - gap - region_top)
	var width: float = maxf(0.0, column.size.x - margin * 2.0)
	var height: float = board.preferred_height(width)
	if height > region_height:
		width = SafeArea.board_width_for_height(skin, region_height)
		height = board.preferred_height(width)
	board.free()
	var below: float = bar_top - (region_top + maxf(0.0, region_height - height) * 0.5 + height)
	var gutter: float = column.position.x - safe.position.x

	var font: Font = skin.font(&"body")
	var font_px: int = skin.font_size(&"body")
	var icon_gap: float = float(roundi(ICON_GAP * float(font_px)))
	var line_width: float = float(font_px) + icon_gap + _width(font, LINE, font_px)
	var stack_width: float = maxf(float(font_px), maxf(_width(font, STACK_TOP, font_px), _width(font, STACK_BOTTOM, font_px)))
	var stack_content: float = float(font_px) + icon_gap + 2.0 * font.get_height(font_px)
	var stack_height: float = maxf(touch, stack_content)
	var stack_touch: float = stack_width + 2.0 * gap

	var place: String = "not shown"
	var detail: String = ""
	if below >= touch + 2.0 * gap:
		place = "below the board"
		detail = ", touch area %.1f px from the board and the bar" % ((below - touch) * 0.5)
	elif gutter >= stack_touch + 2.0 * clear:
		place = "in the gutter, stacked"
		detail = ", touch area %d px from the safe edge and from the column" % roundi((gutter - stack_touch) * 0.5)
	print("    %-7s D %d, gutter %d; one line %d x %d (touch %d wide); stacked content %d x %d, button %d x %d (touch %d wide), gutter needs %d; %s%s" % [
		skin.display_name, roundi(below), roundi(gutter), roundi(line_width), roundi(touch), roundi(line_width + 2.0 * gap),
		roundi(stack_width), roundi(stack_content), roundi(stack_width), roundi(stack_height), roundi(stack_touch),
		roundi(stack_touch + 2.0 * clear), place, detail])


func _width(font: Font, text: String, font_px: int) -> float:
	return ceilf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_px).x)
