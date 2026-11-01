extends "res://src/design/shared/icon_button_base.gd"
## Nova icon button (UiKit.make_icon_button): the skin's IconButton theme
## styles with its icon_hud icon on the face: a hud_ring ring, ring_width wide, in line; pressed
## brightens the ring to ink; disabled fades it to disabled_ring_alpha.

const NovaIcon: GDScript = preload("res://src/design/nova/nova_icon.gd")
const NovaTheme: GDScript = preload("res://src/design/nova/nova_theme.gd")


func _make_icon() -> SkinIcon:
	return NovaIcon.new() as SkinIcon


func _make_styles(for_skin: SkinData) -> Dictionary[StringName, StyleBox]:
	return NovaTheme.icon_button_styles(for_skin)
