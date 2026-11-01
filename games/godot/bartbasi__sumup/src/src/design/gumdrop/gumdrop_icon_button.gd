extends "res://src/design/shared/icon_button_base.gd"
## Gumdrop icon button (UiKit.make_icon_button): the skin's IconButton theme
## styles with its icon_hud icon on the face: a raised squircle face hud_button_face wide on a
## button_lip lip; pressed sinks the face onto button_lip_pressed and the icon
## sinks with it; disabled lies flat and low in disabled_surface.

const GumdropIcon: GDScript = preload("res://src/design/gumdrop/gumdrop_icon.gd")
const GumdropTheme: GDScript = preload("res://src/design/gumdrop/gumdrop_theme.gd")


func _make_icon() -> SkinIcon:
	return GumdropIcon.new() as SkinIcon


func _make_styles(for_skin: SkinData) -> Dictionary[StringName, StyleBox]:
	return GumdropTheme.icon_button_styles(for_skin)
