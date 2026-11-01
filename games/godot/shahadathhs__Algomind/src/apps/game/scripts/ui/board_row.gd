class_name BoardRow
extends Control
## One row of a leaderboard: rank, name, and the result (points, or "commands / steps"). The
## player's own row is a solid tile with a YOU tag, so it stands out by shape and word, not only
## by color. Another player's row carries a small REPORT action.

signal report(entry: Dictionary)

const ROW_HEIGHT := 56.0
const REPORT_WIDTH := 64.0

var entry: Dictionary = {}
var can_report := false

var _report: TileButton


func _ready() -> void:
	custom_minimum_size = Vector2(0, ROW_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if can_report and not bool(entry.get("you", false)) and str(entry["name"]) != "Anonymous":
		_report = TileButton.make(TileButton.Kind.TERTIARY, "REPORT", "", 12)
		_report.accessibility_name = "Report %s" % entry["name"]
		_report.pressed.connect(func() -> void: report.emit(entry))
		add_child(_report)
	resized.connect(_place)
	_place()


## The result text: points, or commands and steps.
func value_text() -> String:
	if entry.has("points"):
		return str(entry["points"])
	return "%d / %d" % [entry["slots"], entry["steps"]]


func _place() -> void:
	if _report != null:
		_report.position = Vector2(size.x - REPORT_WIDTH, 6.0)
		_report.size = Vector2(REPORT_WIDTH, ROW_HEIGHT - 12.0)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(size.x, ROW_HEIGHT - 4.0))
	var you := bool(entry.get("you", false))
	var ink := Palette.ON_INK if you else Palette.INK
	if you:
		rect = TileDraw.tile(self, rect, TileDraw.Tone.SOLID)
	else:
		draw_line(Vector2(0, rect.size.y), Vector2(size.x, rect.size.y), Palette.FAINT, 2.0)
	var middle := Rect2(0, 0, 0, rect.size.y)
	UiKit.text(
		self,
		str(entry["rank"]),
		Rect2(10, 0, 44, rect.size.y),
		22,
		ink,
		0,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	var right := size.x - (10.0 if you or _report == null else REPORT_WIDTH + 4.0)
	var value := value_text()
	var value_w := UiKit.text_width(value, 22, 0) + 4.0
	UiKit.text(
		self,
		value,
		Rect2(right - value_w, 0, value_w, rect.size.y),
		22,
		ink,
		0,
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	var name_x := 58.0
	var name_right := right - value_w - 10.0
	if you:
		var tag := TileDraw.tile(
			self,
			Rect2(name_right - 44.0, rect.size.y / 2.0 - 11.0, 44.0, 22.0),
			TileDraw.Tone.ACTIVE
		)
		UiKit.text(self, "YOU", tag, 14, Palette.ON_SIGNAL, 1)
		name_right -= 52.0
	middle = Rect2(name_x, 0, maxf(name_right - name_x, 0.0), rect.size.y)
	var shown := _fit(str(entry["name"]), 20, middle.size.x)
	UiKit.text(self, shown, middle, 20, ink, 1, HORIZONTAL_ALIGNMENT_LEFT)


## The name, shortened with an ellipsis until it fits.
static func _fit(text: String, size_px: int, width: float) -> String:
	if UiKit.text_width(text, size_px) <= width:
		return text
	var cut := text
	while cut.length() > 1 and UiKit.text_width(cut + "...", size_px) > width:
		cut = cut.substr(0, cut.length() - 1)
	return cut + "..."
