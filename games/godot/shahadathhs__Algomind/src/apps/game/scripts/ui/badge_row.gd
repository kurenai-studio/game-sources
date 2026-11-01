class_name BadgeRow
extends Control
## One badge: a square tile, its name, whether it is earned (with the date) or locked, and what
## it asks for. Earned is a solid tile with a check; locked is an outline with a lock, and the
## words EARNED and LOCKED say it too, so color is never the only signal.

var title := ""
var description := ""
## The date earned (YYYY-MM-DD), "" while locked.
var earned_on := ""


func _init() -> void:
	custom_minimum_size = Vector2(0, 84)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var tile := Rect2(Vector2(0, 6), Vector2(44, 44))
	var earned := not earned_on.is_empty()
	if earned:
		var face := TileDraw.tile(self, tile, TileDraw.Tone.SOLID)
		UiKit.icon(self, "check", face.get_center(), 26.0, Palette.ON_INK)
	elif UiLook.depth:
		var face := TileDraw.tile(self, tile, TileDraw.Tone.PLAIN)
		UiKit.icon(self, "lock", face.get_center(), 24.0, Palette.MUTE)
	else:
		UiKit.outline_chamfer(self, tile, Palette.FAINT)
		UiKit.icon(self, "lock", tile.get_center(), 24.0, Palette.FAINT)
	var x := 58.0
	var width := size.x - x
	var ink := Palette.INK if earned else Palette.MUTE
	UiKit.text(
		self, title.to_upper(), Rect2(x, 0, width, 28), 20, ink, 1, HORIZONTAL_ALIGNMENT_LEFT
	)
	var status := "EARNED %s" % earned_on if earned else "LOCKED"
	UiKit.text(self, status, Rect2(x, 28, width, 18), 13, ink, 2, HORIZONTAL_ALIGNMENT_LEFT)
	var font := UiKit.font(1)
	var baseline := 48.0 + font.get_ascent(13)
	draw_multiline_string(
		font,
		Vector2(x, baseline),
		description.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT,
		width,
		13,
		2,
		Palette.MUTE
	)
