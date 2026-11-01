class_name SkinIcon extends Control
## One icon drawn in code, in the style of one skin (docs/ARCHITECTURE.md
## section 7). Each skin subclasses it in src/design/<id>/. Screens get one
## from UiKit.make_icon() and use only the methods below.
##
## The icon is drawn on the 24 unit design grid (DESIGN_SYSTEM.md 7.9), scaled
## to min(width, height) of the control and centered in it, so it stays crisp
## at any size. The control ignores the mouse, so it can sit on any button.
## UiKit sizes a new icon to the skin's icon_hud; set size to change it.

## The three looks every icon has.
const LOOK_NORMAL: int = 0
## For an icon on an active fill (the targeting booster).
const LOOK_ACTIVE: int = 1
const LOOK_DISABLED: int = 2

## Every icon name DESIGN_SYSTEM.md lists. Every skin draws all of them.
const ICON_NAMES: Array[StringName] = [
	&"hammer", &"swap", &"shuffle", &"double", &"undo", &"pause",
	&"settings", &"sound_on", &"sound_off", &"close", &"check",
	&"star", &"chevron", &"arrow", &"coffee",
]


func setup(_skin: SkinData) -> void:
	_missing(&"setup")


## One of ICON_NAMES. An unknown name is reported and changes nothing.
func set_icon(_icon_name: StringName) -> void:
	_missing(&"set_icon")


## LOOK_NORMAL, LOOK_ACTIVE or LOOK_DISABLED.
func set_look(_look: int) -> void:
	_missing(&"set_look")


## Draws the icon in this color instead of the one its look picks, for an icon
## that sits on a button or chip of its own. The override stays until the next
## set_color call; the look still applies its other effects (Nova's disabled
## alpha, for example).
func set_color(_color: Color) -> void:
	_missing(&"set_color")


func _missing(method: StringName) -> void:
	var script: Script = get_script() as Script
	var path: String = script.resource_path if script != null else "?"
	push_error("%s does not implement SkinIcon.%s()" % [path, method])
