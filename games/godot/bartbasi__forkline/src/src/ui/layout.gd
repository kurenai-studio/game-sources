# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Layout
extends RefCounted
## Which layout to use, and where the safe area is (docs/ARCHITECTURE.md 7.4).
##
## The layout is a pure function of the window size. It never reads the
## orientation of the phone. All sizes are logical pixels of the 1080 wide base.

## Landscape layout when the window is less than 1.5 times taller than wide.
const LANDSCAPE_BELOW: float = 1.5
## At least 48 dp on every screen in section 7.4.
const MIN_TOUCH: float = 160.0
## Outer padding of every screen, inside the safe area.
const PAD: float = 36.0
## Text pages never get wider than this, so lines stay readable.
const CONTENT_MAX: float = 1100.0
## Android's immersive mode reports no bottom inset, yet the gesture bar still sits in the
## bottom 39 px of the Fold5 (QA 2026-10-26, p4: 15 dp, 47 logical px on the cover).
## Godot 4.7.2 exposes no gesture inset (DisplayServer has only get_display_safe_area and
## get_display_cutouts), so on Android the safe area keeps this much clear at the bottom:
## 64 logical px, about 20 dp on the cover (3.14 px per dp) and 24 dp at 2.63 px per dp.
const GESTURE_MARGIN: float = 64.0


## True when the window is close to square or wider than tall.
static func is_landscape(window_size: Vector2) -> bool:
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return false
	return window_size.y < LANDSCAPE_BELOW * window_size.x


## The display safe area in viewport coordinates. The whole viewport when the
## display reports nothing useful (desktop windows, headless runs, SubViewports).
static func safe_rect(viewport: Viewport) -> Rect2:
	var full: Vector2 = viewport.get_visible_rect().size
	var window: Window = viewport as Window
	if window == null:
		return Rect2(Vector2.ZERO, full)
	var id: int = window.get_window_id()
	return safe_in_viewport(
		full,
		Vector2(DisplayServer.window_get_size(id)),
		Vector2(DisplayServer.window_get_position(id)),
		Rect2(DisplayServer.get_display_safe_area()),
		GESTURE_MARGIN if OS.has_feature("android") else 0.0)


## Maps a safe area given in screen pixels into viewport coordinates.
## `window_px` and `window_pos` describe the window on the screen. `min_bottom` is the
## least room kept clear at the bottom of the result, for the gesture bar (0 for none).
static func safe_in_viewport(full: Vector2, window_px: Vector2, window_pos: Vector2, safe_screen: Rect2, min_bottom: float = 0.0) -> Rect2:
	var whole: Rect2 = Rect2(Vector2.ZERO, full)
	if window_px.x <= 0.0 or window_px.y <= 0.0 or safe_screen.size.x <= 0.0 or safe_screen.size.y <= 0.0:
		return keep_bottom_clear(whole, full, min_bottom)
	var k: Vector2 = Vector2(full.x / window_px.x, full.y / window_px.y)
	var local: Rect2 = Rect2((safe_screen.position - window_pos) * k, safe_screen.size * k)
	var clipped: Rect2 = whole.intersection(local)
	if clipped.size.x <= 0.0 or clipped.size.y <= 0.0:
		return keep_bottom_clear(whole, full, min_bottom)
	return keep_bottom_clear(clipped, full, min_bottom)


## The safe area, shortened so that at least `min_bottom` of the viewport stays clear below
## it. A bottom inset that is already larger stays as it is, and so does an area that
## would be left shorter than one touch target.
static func keep_bottom_clear(safe: Rect2, full: Vector2, min_bottom: float) -> Rect2:
	var bottom: float = minf(safe.end.y, full.y - maxf(0.0, min_bottom))
	if bottom >= safe.end.y or bottom - safe.position.y < MIN_TOUCH:
		return safe
	return Rect2(safe.position, Vector2(safe.size.x, bottom - safe.position.y))


## The width a text page may use: the safe width, less padding, capped.
static func content_width(window_width: float, safe: Rect2) -> float:
	return minf(CONTENT_MAX, maxf(MIN_TOUCH, minf(window_width, safe.size.x) - 2.0 * PAD))
