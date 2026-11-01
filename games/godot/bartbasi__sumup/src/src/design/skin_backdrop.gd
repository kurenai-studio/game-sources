class_name SkinBackdrop extends Control
## The screen background of one skin (docs/ARCHITECTURE.md section 7). Each
## skin subclasses it in src/design/<id>/. Screens get one from
## UiKit.make_backdrop(), size it to the whole screen (under the safe area
## insets too) and use only the methods below. It ignores the mouse.


func setup(_skin: SkinData) -> void:
	_missing(&"setup")


## Global rects that hold text. A backdrop with decoration (Nova's star dust)
## keeps it clear of them; a flat backdrop ignores them.
func set_clear_rects(_rects: Array[Rect2]) -> void:
	_missing(&"set_clear_rects")


func _missing(method: StringName) -> void:
	var script: Script = get_script() as Script
	var path: String = script.resource_path if script != null else "?"
	push_error("%s does not implement SkinBackdrop.%s()" % [path, method])
