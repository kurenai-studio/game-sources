extends "res://src/design/shared/icon_button_base.gd"
## Slate icon button (UiKit.make_icon_button): the skin's IconButton theme
## styles with its icon_hud icon on the face: no container and the full touch area; pressed
## fills the touch area with surface.

const SlateIcon: GDScript = preload("res://src/design/slate/slate_icon.gd")
const SlateTheme: GDScript = preload("res://src/design/slate/slate_theme.gd")


func _make_icon() -> SkinIcon:
	return SlateIcon.new() as SkinIcon


func _make_styles(for_skin: SkinData) -> Dictionary[StringName, StyleBox]:
	return SlateTheme.icon_button_styles(for_skin)
