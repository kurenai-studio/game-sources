class_name SkinBoosterBar extends Control
## The booster bar of one skin (docs/ARCHITECTURE.md section 7). Each skin
## subclasses it in src/design/<id>/. Screens get one from
## UiKit.make_booster_bar(), place it full width with its bottom on the safe
## area's bottom, height preferred_height(), and use only the signal and
## methods below.

## A usable booster was tapped. Disabled boosters never emit.
signal booster_pressed(booster_id: StringName)


func setup(_skin: SkinData) -> void:
	_missing(&"setup")


## One button per status, in the order given (bar order). Each shows its
## look (normal, active while targeting, disabled when not usable), its cost
## as a tile label, and the Suggested badge (D-42). A status with free set
## (D-46) shows the star and Free in place of its cost, disabled included.
## Call again whenever the statuses change; buttons are reused.
func show_boosters(_statuses: Array[BoosterStatus]) -> void:
	_missing(&"show_boosters")


## The targeting hint, already in the screen's words. "" hides it. A skin that
## shows the hint in its HUD context row (Slate) ignores it.
func set_hint(_text: String) -> void:
	_missing(&"set_hint")


## Local y where the always visible part of the bar starts. Above it is the
## hint row, empty while no hint shows. Valid once the bar has its size.
func content_top() -> float:
	_missing(&"content_top")
	return 0.0


## The bar's height in px: the skin's bar_height.
func preferred_height() -> float:
	_missing(&"preferred_height")
	return 0.0


func _missing(method: StringName) -> void:
	var script: Script = get_script() as Script
	var path: String = script.resource_path if script != null else "?"
	push_error("%s does not implement SkinBoosterBar.%s()" % [path, method])
