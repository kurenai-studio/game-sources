extends RefCounted
## Gumdrop's raised candy surface (DESIGN_SYSTEM.md 4.7), shared by its
## theme, booster buttons, pause button, notice and toggle. A raised surface
## is a face in its fill with a darker lip showing along the bottom. It is
## laid out in a rest rect that holds the face and the lip at rest:
##   normal: the face on a lip button_lip deep
##   held: the lip down to button_lip_pressed, the face sunk onto it
##   active: accent on an accent_lip lip, raised active_raise higher
##   disabled: flat with no lip, sitting at the bottom of the rest rect

const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")

const LOOK_NORMAL: int = 0
const LOOK_ACTIVE: int = 1
const LOOK_DISABLED: int = 2


## A raised box: face in fill with lip px of lip_color along the bottom.
static func raised(fill: Color, lip_color: Color, radius: float, lip: float) -> StyleBoxFlat:
	var made: StyleBoxFlat = ThemeKit.box(fill, radius)
	made.border_color = lip_color
	made.border_width_bottom = roundi(lip)
	return made


## The style for a look, held or not, of a surface_raised control. Build
## these once and keep them.
static func style(skin: SkinData, look: int, held: bool, radius: float) -> StyleBoxFlat:
	var lip: float = skin.num(&"button_lip")
	if held:
		lip = skin.num(&"button_lip_pressed")
	match look:
		LOOK_ACTIVE:
			var raise: float = 0.0 if held else skin.num(&"active_raise")
			return raised(skin.color(&"accent"), skin.color(&"accent_lip"), radius, lip + raise)
		LOOK_DISABLED:
			return ThemeKit.box(skin.color(&"disabled_surface"), radius)
	return raised(skin.color(&"surface_raised"), skin.color(&"surface_lip"), radius, lip)


## Where to draw a look's style, given the rest rect (face and lip).
static func style_rect(skin: SkinData, rest: Rect2, look: int, held: bool) -> Rect2:
	var lip: float = skin.num(&"button_lip")
	if look == LOOK_DISABLED:
		return Rect2(rest.position.x, rest.position.y + lip, rest.size.x, rest.size.y - lip)
	if held:
		var sink: float = lip - skin.num(&"button_lip_pressed")
		return Rect2(rest.position.x, rest.position.y + sink, rest.size.x, rest.size.y - sink)
	if look == LOOK_ACTIVE:
		var raise: float = skin.num(&"active_raise")
		return Rect2(rest.position.x, rest.position.y - raise, rest.size.x, rest.size.y + raise)
	return rest


## The top face of a look, where icons and text sit.
static func face_rect(skin: SkinData, rest: Rect2, look: int, held: bool) -> Rect2:
	var drawn: Rect2 = style_rect(skin, rest, look, held)
	if look == LOOK_DISABLED:
		return drawn
	var lip: float = skin.num(&"button_lip_pressed") if held else skin.num(&"button_lip")
	if look == LOOK_ACTIVE and not held:
		lip += skin.num(&"active_raise")
	return Rect2(drawn.position, Vector2(drawn.size.x, drawn.size.y - lip))


## The badge box of DESIGN_SYSTEM.md 7.8: a lemon pill with a badge_lip lip,
## face_height tall above the lip.
static func badge(skin: SkinData, face_height: float) -> StyleBoxFlat:
	return raised(skin.color(&"badge"), skin.color(&"badge_lip"), face_height * 0.5, skin.num(&"button_lip"))
