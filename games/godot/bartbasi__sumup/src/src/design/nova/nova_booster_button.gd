extends "res://src/design/shared/booster_button_base.gd"
## One Nova booster (DESIGN_SYSTEM.md 6.7): a ring button ring_button across,
## ring_width wide, in line, the icon_booster icon inside, and the cost under
## the ring in the label role, space_xs below it. No container; the whole
## slot is the touch area.
##   Pressed: Motion.press scale, the ring brightens to ink.
##   Active: the ring fills accent inside a breathing accent and violet glow
##     (ring_glow_spread, ring_glow_alpha, target_pulse); icon ink_dark, cost
##     accent.
##   Disabled: a dashed ring (disabled_ring_dashes) at disabled_ring_alpha,
##     the icon disabled_ink at disabled_icon_alpha, the cost disabled_ink
##     struck through with a hairline line. Never a glow.
##   Suggested: the ring breathes in accent on target_pulse (the bar draws
##     the badge).
##   Free: the star and "free" centered under the ring, in accent (normal,
##     pressed and active) or disabled_ink (disabled, the hairline strike
##     across the whole group). No glow on the small star.
## Text pairs: ink, accent and disabled_ink on bg_glow.

const NovaIcon: GDScript = preload("res://src/design/nova/nova_icon.gd")
const NovaRing: GDScript = preload("res://src/design/nova/nova_ring.gd")
const NovaRingGlow: GDScript = preload("res://src/design/nova/nova_ring_glow.gd")

var _glow: NovaRingGlow = null
var _ring: NovaRing = null
var _icon: SkinIcon = null
var _font: Font = null
var _font_size: int = 1
var _text_origin: Vector2 = Vector2.ZERO
var _strike_from: Vector2 = Vector2.ZERO
var _strike_to: Vector2 = Vector2.ZERO
var _breathing: bool = false


## Height a booster needs: the ring, space_xs, one cost line.
static func needed_height(skin: SkinData) -> float:
	return skin.num(&"ring_button") + skin.num(&"space_xs") + skin.font(&"label").get_height(skin.font_size(&"label"))


func _on_setup() -> void:
	_font = _skin.font(&"label")
	_font_size = _skin.font_size(&"label")
	if _icon == null:
		_glow = NovaRingGlow.new()
		add_child(_glow)
		_ring = NovaRing.new()
		add_child(_ring)
		_icon = NovaIcon.new()
		add_child(_icon)
	_glow.setup(_skin)
	_glow.visible = false
	_icon.setup(_skin)
	if booster_id != &"":
		_icon.set_icon(booster_id)


func _on_booster_changed() -> void:
	if _icon != null:
		_icon.set_icon(booster_id)


func _apply(was: int) -> void:
	if _icon == null:
		return
	_icon.set_look(look)
	var active: bool = look == SkinIcon.LOOK_ACTIVE
	_glow.visible = active
	if active and was != SkinIcon.LOOK_ACTIVE:
		Motion.pulse(_glow, _skin)
	elif not active:
		Motion.stop_pulse(_glow)
	var breathe: bool = suggested and look == SkinIcon.LOOK_NORMAL
	if breathe and not _breathing:
		Motion.pulse(_ring, _skin)
	elif not breathe and _breathing:
		Motion.stop_pulse(_ring)
	_breathing = breathe
	_show_ring()
	queue_redraw()


func _held_changed() -> void:
	_show_ring()


func _show_ring() -> void:
	var width: float = _skin.num(&"ring_width")
	match look:
		SkinIcon.LOOK_ACTIVE:
			_ring.show_ring(NovaRing.STYLE_FILLED, _skin.color(&"accent"), width)
		SkinIcon.LOOK_DISABLED:
			var faint: Color = Color(_skin.color(&"line"), _skin.num(&"disabled_ring_alpha"))
			_ring.show_ring(NovaRing.STYLE_DASHED, faint, width, int(_skin.num(&"disabled_ring_dashes")), _skin.num(&"orbit_dash_fill"))
		_:
			var color: Color = _skin.color(&"line")
			if held:
				color = _skin.color(&"ink")
			elif suggested:
				color = _skin.color(&"accent")
			_ring.show_ring(NovaRing.STYLE_SOLID, color, width)


func _layout() -> void:
	if _skin == null or _icon == null:
		return
	var ring_side: float = _skin.num(&"ring_button")
	var center: Vector2 = Vector2(size.x * 0.5, ring_side * 0.5)
	_ring.size = Vector2(ring_side, ring_side)
	_ring.position = center - _ring.size * 0.5
	_ring.pivot_offset = _ring.size * 0.5
	_glow.place(center, ring_side * 0.5)
	var icon_side: float = _skin.num(&"icon_booster")
	_icon.size = Vector2(icon_side, icon_side)
	_icon.position = center - _icon.size * 0.5
	var line_top: float = ring_side + _skin.num(&"space_xs")
	_text_origin = Vector2(0.0, line_top + _font.get_ascent(_font_size))
	var cost_width: float = _font.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x
	if free:
		cost_width = _free_width()
	var hairline: float = _skin.num(&"hairline")
	var middle: float = roundf(_text_origin.y - float(_font_size) * FontMetrics.CAP_HEIGHT * 0.5)
	var left: float = (size.x - cost_width) * 0.5
	_strike_from = Vector2(left - hairline, middle)
	_strike_to = Vector2(left + cost_width + hairline, middle)
	_place_free(left, _text_origin.y, _free_ink())
	queue_redraw()


## The Free group's color for the look.
func _free_ink() -> Color:
	if look == SkinIcon.LOOK_DISABLED:
		return _skin.color(&"disabled_ink")
	return _skin.color(&"accent")


func _ink() -> Color:
	if look == SkinIcon.LOOK_ACTIVE:
		return _skin.color(&"accent")
	if look == SkinIcon.LOOK_DISABLED:
		return _skin.color(&"disabled_ink")
	return _skin.color(&"ink")


func _draw() -> void:
	if _skin == null:
		return
	var ink: Color = _ink()
	if free:
		draw_string(_font, _free_origin, free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, _free_ink())
	else:
		draw_string(_font, _text_origin, cost_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, _font_size, ink)
	if look == SkinIcon.LOOK_DISABLED:
		draw_line(_strike_from, _strike_to, ink, _skin.num(&"hairline"), true)
