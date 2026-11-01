class_name DepthKitSample
extends Control
## Debug screenshots only (see main.gd, --screen=depth_kit): every piece of DepthKit on the ground
## gradient, so the look can be checked in both themes and at the three phone sizes.

const MARGIN := 20.0


func _draw() -> void:
	DepthKit.ground(self, Rect2(Vector2.ZERO, size))
	var width := size.x - 2.0 * MARGIN
	var y := MARGIN + 28.0
	UiKit.text(
		self,
		"DEPTH KIT",
		Rect2(MARGIN, y, width, 40.0),
		34,
		DepthPalette.INK,
		2,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	y += 56.0
	_caption("COMMANDS", y)
	y += 22.0
	var gap := 12.0
	var third := (width - 2.0 * gap) / 3.0
	for i in 3:
		var rect := Rect2(MARGIN + i * (third + gap), y, third, 58.0)
		_labelled_key(rect, ["move", "left", "right"][i], ["MOVE", "LEFT", "RIGHT"][i])
	y += 58.0 + 30.0
	_caption("ACTIONS", y)
	y += 22.0
	var quarter := (width - 2.0 * gap) / 4.0
	_labelled_key(Rect2(MARGIN, y, quarter, 54.0), "step", "STEP")
	_labelled_key(
		Rect2(MARGIN + quarter + gap, y, quarter * 2.0, 54.0), "play", "RUN", DepthKit.Kind.SIGNAL
	)
	_labelled_key(Rect2(MARGIN + quarter * 3.0 + gap * 2.0, y, quarter, 54.0), "reset", "RESET")
	y += 54.0 + 30.0
	_caption("PRESSED AND SOLID", y)
	y += 22.0
	_labelled_key(Rect2(MARGIN, y, third, 54.0), "move", "MOVE", DepthKit.Kind.TILE, true)
	_labelled_key(Rect2(MARGIN + third + gap, y, third, 54.0), "move", "DONE", DepthKit.Kind.INK)
	_labelled_key(
		Rect2(MARGIN + 2.0 * (third + gap), y, third, 54.0), "move", "NOW", DepthKit.Kind.SIGNAL
	)
	y += 54.0 + 30.0
	_caption("PROGRAM", y)
	y += 22.0
	var trough := Rect2(MARGIN, y, width, 110.0)
	DepthKit.trough(self, trough)
	var tile := 58.0
	var kinds := [DepthKit.Kind.INK, DepthKit.Kind.INK, DepthKit.Kind.SIGNAL, DepthKit.Kind.TILE]
	var icons := ["move", "right", "move", "move"]
	for i in kinds.size():
		var rect := Rect2(trough.position.x + 12.0 + i * (tile + 8.0), y + 20.0, tile, tile)
		var face := DepthKit.key(self, rect, kinds[i])
		UiKit.icon(self, icons[i], face.get_center(), 26.0, DepthKit.label_color(kinds[i]))
		UiKit.text(
			self,
			"%02d" % (i + 1),
			Rect2(rect.position.x, rect.end.y + 4.0, rect.size.x, 16.0),
			13,
			DepthPalette.MUTE
		)
	y += 110.0 + 30.0
	_caption("SOFT SHADOW ON A PLATE", y)
	y += 22.0
	var plate := Rect2(MARGIN + 8.0, y, width - 16.0, maxf(60.0, size.y - y - 40.0))
	var outline := PackedVector2Array(
		[
			plate.position,
			Vector2(plate.end.x, plate.position.y),
			plate.end,
			Vector2(plate.position.x, plate.end.y)
		]
	)
	DepthKit.soft_shadow(self, outline, Vector2(0.0, 12.0), 16.0, 0.5, 8)
	draw_colored_polygon(outline, DepthPalette.PLATE)
	var inner := plate.grow(-8.0)
	draw_rect(inner, DepthPalette.FLOOR)


func _caption(value: String, y: float) -> void:
	UiKit.text(
		self,
		value,
		Rect2(MARGIN + 2.0, y, size.x - 2.0 * MARGIN, 18.0),
		13,
		DepthPalette.MUTE,
		2,
		HORIZONTAL_ALIGNMENT_LEFT
	)


func _labelled_key(
	rect: Rect2,
	icon_kind: String,
	label: String,
	kind: DepthKit.Kind = DepthKit.Kind.TILE,
	pressed: bool = false
) -> void:
	var face := DepthKit.key(self, rect, kind, pressed)
	var color := DepthKit.label_color(kind)
	var icon_size := 24.0
	var text_width := UiKit.text_width(label, 17, 2)
	var total := icon_size + 8.0 + text_width
	var left := face.get_center().x - total / 2.0
	UiKit.icon(
		self, icon_kind, Vector2(left + icon_size / 2.0, face.get_center().y), icon_size, color
	)
	UiKit.text(
		self,
		label,
		Rect2(left + icon_size + 8.0, face.position.y, text_width + 4.0, face.size.y),
		17,
		color,
		2,
		HORIZONTAL_ALIGNMENT_LEFT
	)
