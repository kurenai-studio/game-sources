extends SkinWordmark
## Gumdrop wordmark (DESIGN_SYSTEM.md 7.2): candy letters with a lip, like its
## tiles and buttons. Under each face the same text is drawn again at every
## whole px offset from 1 to d below it, d = round(0.06 x size); then the
## faces on top. Lip colors: "Sum" in ink_muted darkened by lip_darken, "Up"
## in accent_lip. "Up" steps up: its baseline sits round(0.06 x size) above
## the baseline of "Sum", like a tile lifted for the joinable highlight.
## The drawn width is the two advances.

## Lip depth and the step of "Up", as shares of the size (7.9).
const LIP_SHARE: float = 0.06
const STEP_SHARE: float = 0.06

var _ink: Color = Color.WHITE
var _accent: Color = Color.WHITE
var _sum_lip: Color = Color.WHITE
var _up_lip: Color = Color.WHITE
var _lip: int = 0
var _step: float = 0.0


func _on_setup() -> void:
	_ink = _skin.color(&"ink")
	_accent = _skin.color(&"accent")
	_sum_lip = _skin.color(&"ink_muted").darkened(_skin.num(&"lip_darken"))
	_up_lip = _skin.color(&"accent_lip")


func _on_built() -> void:
	_lip = _lip_depth(_px)
	_step = float(roundi(STEP_SHARE * float(_px)))


func _lip_depth(at_px: int) -> int:
	return roundi(LIP_SHARE * float(at_px))


func _draw_mark(left: float, baseline: float) -> void:
	var up_left: float = left + _sum_width
	var up_baseline: float = baseline - _step
	for offset: int in range(_lip, 0, -1):
		_word(0, left, baseline + float(offset), _sum_lip)
		_word(1, up_left, up_baseline + float(offset), _up_lip)
	_word(0, left, baseline, _ink)
	_word(1, up_left, up_baseline, _accent)
