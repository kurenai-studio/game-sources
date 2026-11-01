# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Wordmark
extends Control
## The Forkline wordmark, drawn in code: the name in heavy Outfit with an ink
## outline, a lantern for the dot of the "i", and a sandy road underneath that
## forks in two. It fills the control's rect and keeps its proportions.
## draw_into() draws the same mark onto any canvas (store graphics).

const NAME: String = "Forkline"
const DOTLESS_I: int = 0x131


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(480, 200)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	draw_into(self, Rect2(Vector2.ZERO, size))


## Draws the wordmark centered in `rect`, as large as fits.
static func draw_into(canvas: CanvasItem, rect: Rect2) -> void:
	var f: Font = UiTheme.font(UiTheme.WEIGHT_HEAVY)
	var dotless: bool = f.has_char(DOTLESS_I)
	var word: String = NAME.replace("i", String.chr(DOTLESS_I)) if dotless else NAME
	# The word takes 60 percent of the height, the road the rest.
	var fs: int = int(rect.size.y * 0.6)
	var width: float = f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if width > rect.size.x * 0.94:
		fs = int(float(fs) * rect.size.x * 0.94 / width)
		width = f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var cap: float = f.get_ascent(fs) * 0.72
	var block_h: float = cap + fs * 0.62
	var left: float = rect.position.x + (rect.size.x - width) * 0.5
	var baseline: float = rect.position.y + (rect.size.y - block_h) * 0.5 + cap + fs * 0.08
	var ink: float = maxf(2.0, float(fs) * 0.13)
	_road(canvas, Vector2(left, baseline + fs * 0.2), width, float(fs))
	canvas.draw_string_outline(f, Vector2(left + ink * 0.25, baseline + ink * 0.35), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(ink * 2.0), Palette.INK_LINE)
	canvas.draw_string_outline(f, Vector2(left, baseline), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(ink), Palette.INK_LINE)
	canvas.draw_string(f, Vector2(left, baseline), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.CARD)
	if dotless:
		var before: float = f.get_string_size(word.substr(0, 5), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var stem: float = f.get_string_size(word.substr(5, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x_height: float = cap * 0.7
		var pen: InkPen = InkPen.new(canvas)
		pen.line_px = maxf(1.5, ink * 0.45)
		pen.begin(Vector2(left + before + stem * 0.5, baseline - x_height - fs * 0.17), float(fs) / 100.0)
		pen.lantern(Vector2.ZERO, 7.5, 1.4)


## The sandy road under the word: straight from the left, then a fork.
static func _road(canvas: CanvasItem, start: Vector2, width: float, fs: float) -> void:
	var w: float = fs * 0.11
	var split: Vector2 = start + Vector2(width * 0.56, 0.0)
	var trunk: PackedVector2Array = PackedVector2Array([start + Vector2(-fs * 0.05, 0.0), split])
	var upper: PackedVector2Array = PackedVector2Array()
	var lower: PackedVector2Array = PackedVector2Array()
	for i: int in 13:
		var t: float = float(i) / 12.0
		upper.append(split + Vector2(width * 0.46 * t, -fs * 0.06 * sin(t * PI * 0.5)))
		lower.append(split + Vector2(width * 0.36 * t, fs * 0.2 * (1.0 - cos(t * PI * 0.5))))
	for pass_i: int in 2:
		var col: Color = Palette.INK_LINE if pass_i == 0 else Palette.ROAD
		var ww: float = w + (fs * 0.06 if pass_i == 0 else 0.0)
		for line: PackedVector2Array in [trunk, upper, lower]:
			canvas.draw_polyline(line, col, ww, true)
			canvas.draw_circle(line[0], ww * 0.5, col, true, -1.0, true)
			canvas.draw_circle(line[line.size() - 1], ww * 0.5, col, true, -1.0, true)
