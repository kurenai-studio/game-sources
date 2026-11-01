class_name SkinToggle extends Control
## The sound toggle, in the style of one skin (docs/ARCHITECTURE.md section 7).
## Each skin subclasses it in src/design/<id>/. Screens get one from
## UiKit.make_toggle() and use only the signal and methods below.
##
## A tap flips it, animates the change and emits toggled. The control is at
## least touch_min on each side.

## The player flipped the toggle. Not emitted by set_on().
signal toggled(on: bool)


func setup(_skin: SkinData) -> void:
	_missing(&"setup")


## Shows on or off. With animate the knob slides on the skin's button_release
## motion; without it the change is instant. Never emits toggled.
func set_on(_on: bool, _animate: bool = false) -> void:
	_missing(&"set_on")


func _missing(method: StringName) -> void:
	var script: Script = get_script() as Script
	var path: String = script.resource_path if script != null else "?"
	push_error("%s does not implement SkinToggle.%s()" % [path, method])
