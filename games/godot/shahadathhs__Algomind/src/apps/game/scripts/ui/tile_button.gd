class_name TileButton
extends Control
## A chamfered tile that acts as a button. Kinds:
## PRIMARY yellow fill (one per screen), SECONDARY outlined, TERTIARY underlined text,
## SOLID ink fill (selected or solved), LOCKED faint outline with a lock icon.
## Every kind also carries a label, so color is never the only signal.

signal pressed

enum Kind { PRIMARY, SECONDARY, TERTIARY, SOLID, LOCKED }

const MIN_TOUCH := 44.0
## A press that moves farther than this is a scroll, not a tap.
const TAP_SLOP := 12.0
## A depth key takes this long to sink or to spring back (well under the 250 ms limit).
const SINK_SECONDS := 0.06

var kind := Kind.SECONDARY
var label := ""
var icon := ""
var font_size := 20
var disabled := false
## Icon above the label instead of beside it (level tiles).
var stacked := false
## 1 to 3 solid stars (of three) drawn in place of the icon of a stacked tile; 0 for none.
var stars := 0
## Where a TERTIARY label sits in its box.
var align := HORIZONTAL_ALIGNMENT_CENTER

var _down := false
var _press_at := Vector2.ZERO
## How far a depth key has sunk, 0 (up) to 1 (pressed); it eases toward `_down` in a few frames.
var _sink := 0.0


func _ready() -> void:
	# Only a depth key that is moving needs a frame callback; an idle button never redraws itself.
	# (Godot turns processing on for a script with _process when the node becomes ready.)
	set_process(false)


static func make(
	button_kind: Kind, text_value: String, icon_kind: String = "", size_px: int = 20
) -> TileButton:
	var button := TileButton.new()
	button.kind = button_kind
	button.label = text_value
	button.icon = icon_kind
	button.font_size = size_px
	button.accessibility_name = text_value
	button.custom_minimum_size = Vector2(MIN_TOUCH, MIN_TOUCH)
	# PASS lets a parent ScrollContainer see drags that start on a tile.
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	return button


func _process(delta: float) -> void:
	var target := 1.0 if _down else 0.0
	_sink = target if not UiLook.animate else move_toward(_sink, target, delta / SINK_SECONDS)
	queue_redraw()
	if _sink == target:
		set_process(false)


func set_disabled(value: bool) -> void:
	disabled = value
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if disabled or kind == Kind.LOCKED:
		return
	var click := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		if click.pressed:
			_down = true
			_press_at = click.position
			set_process(UiLook.depth)
			queue_redraw()
		else:
			var inside := Rect2(Vector2.ZERO, size).has_point(click.position)
			var moved: bool = click.position.distance_to(_press_at) > TAP_SLOP
			var fire: bool = _down and inside and not moved
			_down = false
			set_process(UiLook.depth)
			queue_redraw()
			if fire:
				pressed.emit()
	elif motion != null and _down:
		if motion.position.distance_to(_press_at) > TAP_SLOP:
			_down = false
			set_process(UiLook.depth)
			queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if UiLook.depth and kind != Kind.TERTIARY:
		_draw_key(rect)
		return
	self_modulate.a = 1.0
	var ink := Palette.INK
	var on_color := Palette.INK
	match kind:
		Kind.PRIMARY:
			var fill := Palette.FAINT if disabled else Palette.SIGNAL
			if _down:
				fill = Palette.INK
			UiKit.fill_chamfer(self, rect, fill)
			on_color = (
				Palette.ON_INK if _down else (Palette.MUTE if disabled else Palette.ON_SIGNAL)
			)
		Kind.SECONDARY:
			var down_fill := Palette.INK if _down else Palette.GROUND
			UiKit.fill_chamfer(self, rect, down_fill)
			ink = Palette.FAINT if disabled else Palette.INK
			UiKit.outline_chamfer(self, rect, ink)
			on_color = Palette.ON_INK if _down else ink
		Kind.SOLID:
			UiKit.fill_chamfer(self, rect, Palette.INK)
			on_color = Palette.ON_INK
		Kind.LOCKED:
			UiKit.outline_chamfer(self, rect, Palette.FAINT)
			on_color = Palette.FAINT
		Kind.TERTIARY:
			on_color = Palette.MUTE if disabled else Palette.INK
	_draw_content(rect, on_color)


## The depth look: a key with a lip. A pressed key sinks onto its lip. A disabled or locked key is
## a sunk, neutral tile with a muted label: opaque, so nothing shows through it, and its label and
## icon still say what it is.
func _draw_key(rect: Rect2) -> void:
	var tone := DepthKit.Kind.TILE
	if kind == Kind.PRIMARY:
		tone = DepthKit.Kind.SIGNAL
	elif kind == Kind.SOLID:
		tone = DepthKit.Kind.INK
	var inert := disabled or kind == Kind.LOCKED
	var color := DepthKit.label_color(tone)
	if inert:
		tone = DepthKit.Kind.TILE
		color = Palette.MUTE
	self_modulate.a = 1.0
	var face := DepthKit.key_sunk(self, rect, tone, 1.0 if inert else _sink)
	draw_set_transform(face.position, 0.0, Vector2.ONE)
	_draw_content(Rect2(Vector2.ZERO, face.size), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_content(rect: Rect2, color: Color) -> void:
	if stacked and stars > 0:
		var radius := clampf(rect.size.x * 0.1, 4.0, 8.0)
		StarGlyph.row(self, Vector2(rect.size.x / 2.0, rect.size.y * 0.27), stars, 3, radius, color)
		var below := Rect2(0, rect.size.y * 0.42, rect.size.x, rect.size.y * 0.5)
		UiKit.text(self, label, below, font_size, color, 1)
		return
	if stacked and icon != "":
		var small := float(font_size) * 0.7
		UiKit.icon(self, icon, Vector2(rect.size.x / 2.0, rect.size.y * 0.3), small, color)
		var lower := Rect2(0, rect.size.y * 0.42, rect.size.x, rect.size.y * 0.5)
		# A long label (END LOOP) shrinks until it fits the tile.
		var px := font_size
		while px > 8 and UiKit.text_width(label, px) > rect.size.x - 4.0:
			px -= 1
		UiKit.text(self, label, lower, px, color, 1)
		return
	var icon_size := float(font_size) * 1.05
	# A label that is wider than the tile (ELSE IF) shrinks until it fits.
	var text_px := font_size
	if icon == "" and kind != Kind.TERTIARY:
		while text_px > 8 and UiKit.text_width(label, text_px) > rect.size.x - 6.0:
			text_px -= 1
	var text_w := UiKit.text_width(label, text_px)
	var gap := 8.0 if icon != "" and label != "" else 0.0
	var icon_w := icon_size if icon != "" else 0.0
	var total := icon_w + gap + text_w
	var x := (rect.size.x - total) / 2.0
	if align == HORIZONTAL_ALIGNMENT_LEFT:
		x = 0.0
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x = rect.size.x - total
	if icon != "":
		var center := Vector2(x + icon_w / 2.0, rect.size.y / 2.0)
		UiKit.icon(self, icon, center, icon_size, color)
	if label != "":
		var text_rect := Rect2(x + icon_w + gap, 0, text_w + 2.0, rect.size.y)
		UiKit.text(self, label, text_rect, text_px, color, 1, HORIZONTAL_ALIGNMENT_LEFT)
		if kind == Kind.TERTIARY:
			var y := rect.size.y / 2.0 + font_size * 0.5
			draw_line(
				Vector2(text_rect.position.x, y), Vector2(text_rect.end.x - 2.0, y), color, 2.0
			)
