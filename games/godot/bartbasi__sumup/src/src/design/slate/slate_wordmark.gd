extends SkinWordmark
## Slate wordmark (DESIGN_SYSTEM.md 7.2): flat and exact, the two words on one
## baseline, no effect at all, on the left edge. The drawn width is the two
## advances.
## With set_masthead(true) (the splash's brand block) it also draws the
## masthead rule: space_s below the text, a hairline line in line across the
## control's whole width, so the screen stretches it from margin to margin.

var _ink: Color = Color.WHITE
var _accent: Color = Color.WHITE
var _rule: Color = Color.WHITE
var _gap: float = 0.0
var _hairline: float = 0.0


func _on_setup() -> void:
	_ink = _skin.color(&"ink")
	_accent = _skin.color(&"accent")
	_rule = _skin.color(&"line")
	_gap = _skin.num(&"space_s")
	_hairline = _skin.num(&"hairline")


func _masthead_height() -> float:
	return _gap + _hairline if _masthead else 0.0


func _centered() -> bool:
	return false


func _draw_mark(left: float, baseline: float) -> void:
	_word(0, left, baseline, _ink)
	_word(1, left + _sum_width, baseline, _accent)
	if _masthead:
		draw_rect(Rect2(0.0, ceilf(_ascent + _descent) + _gap, size.x, _hairline), _rule)
