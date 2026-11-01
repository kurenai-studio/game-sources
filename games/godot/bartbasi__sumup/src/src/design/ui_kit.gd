class_name UiKit extends RefCounted
## The one way screens get a skin's Theme and interface components
## (docs/ARCHITECTURE.md section 7). Each skin's implementations live in
## src/design/<id>/ and are loaded here with preload; screens use only the
## base classes (SkinHud, SkinBoosterBar, SkinIcon, SkinToggle, SkinBackdrop,
## SkinWordmark).
##
## Every component comes back already set up for the skin. It works before it
## is in the scene tree: add it, then size and place it. Calling setup() again
## with the same skin is harmless.
##
## A skin id with no implementation is a bug: it is reported and the default
## skin's components are used, still reading the given skin's tokens.

const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")

const _THEMES: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/design/gumdrop/gumdrop_theme.gd"),
	&"slate": preload("res://src/design/slate/slate_theme.gd"),
	&"nova": preload("res://src/design/nova/nova_theme.gd"),
}
const _HUDS: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/design/gumdrop/gumdrop_hud.gd"),
	&"slate": preload("res://src/design/slate/slate_hud.gd"),
	&"nova": preload("res://src/design/nova/nova_hud.gd"),
}
const _BARS: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/design/gumdrop/gumdrop_booster_bar.gd"),
	&"slate": preload("res://src/design/slate/slate_booster_bar.gd"),
	&"nova": preload("res://src/design/nova/nova_booster_bar.gd"),
}
const _ICONS: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/design/gumdrop/gumdrop_icon.gd"),
	&"slate": preload("res://src/design/slate/slate_icon.gd"),
	&"nova": preload("res://src/design/nova/nova_icon.gd"),
}
const _TOGGLES: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/design/gumdrop/gumdrop_toggle.gd"),
	&"slate": preload("res://src/design/slate/slate_toggle.gd"),
	&"nova": preload("res://src/design/nova/nova_toggle.gd"),
}
const _ICON_BUTTONS: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/design/gumdrop/gumdrop_icon_button.gd"),
	&"slate": preload("res://src/design/slate/slate_icon_button.gd"),
	&"nova": preload("res://src/design/nova/nova_icon_button.gd"),
}
const _BACKDROPS: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/design/gumdrop/gumdrop_backdrop.gd"),
	&"slate": preload("res://src/design/slate/slate_backdrop.gd"),
	&"nova": preload("res://src/design/nova/nova_backdrop.gd"),
}
const _WORDMARKS: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/design/gumdrop/gumdrop_wordmark.gd"),
	&"slate": preload("res://src/design/slate/slate_wordmark.gd"),
	&"nova": preload("res://src/design/nova/nova_wordmark.gd"),
}


## The skin's Theme: the body font as default and every type variation of
## ThemeKit.VARIATIONS (ARCHITECTURE.md section 7 plus the ones
## DESIGN_SYSTEM.md adds), with normal, hover, pressed, disabled and focus
## styles on every button type. Builds a new Theme on every call.
static func build_theme(skin: SkinData) -> Theme:
	var builder: GDScript = _pick(_THEMES, skin)
	return builder.call(&"build", skin) as Theme


static func make_hud(skin: SkinData) -> SkinHud:
	var hud: SkinHud = _pick(_HUDS, skin).new() as SkinHud
	hud.setup(skin)
	return hud


static func make_booster_bar(skin: SkinData) -> SkinBoosterBar:
	var bar: SkinBoosterBar = _pick(_BARS, skin).new() as SkinBoosterBar
	bar.setup(skin)
	return bar


## A new icon sized icon_hud, with no icon chosen yet: call set_icon().
static func make_icon(skin: SkinData) -> SkinIcon:
	var icon: SkinIcon = _pick(_ICONS, skin).new() as SkinIcon
	icon.setup(skin)
	return icon


## A touch_min square button with the skin's icon on its face (the IconButton
## look: Gumdrop's raised squircle, Slate's bare icon, Nova's ring), for the
## settings and close buttons of DESIGN_SYSTEM.md 7.2 and 7.7. The icon
## follows Gumdrop's pressed face. A tap emits the built-in pressed signal
## exactly once, by finger, mouse or ui_accept, never again for the copies
## Godot's mouse and touch emulation make (QA6-01); set disabled to grey it
## out. icon_name is one of SkinIcon.ICON_NAMES.
static func make_icon_button(skin: SkinData, icon_name: StringName) -> BaseButton:
	var button: BaseButton = _pick(_ICON_BUTTONS, skin).new() as BaseButton
	button.call(&"setup", skin, icon_name)
	return button


## A new toggle, off.
static func make_toggle(skin: SkinData) -> SkinToggle:
	var toggle: SkinToggle = _pick(_TOGGLES, skin).new() as SkinToggle
	toggle.setup(skin)
	return toggle


static func make_backdrop(skin: SkinData) -> SkinBackdrop:
	var backdrop: SkinBackdrop = _pick(_BACKDROPS, skin).new() as SkinBackdrop
	backdrop.setup(skin)
	return backdrop


## The drawn "SumUp" wordmark in the skin's look (DESIGN_SYSTEM.md 7.2,
## 7.13), at the display role's size (About). Call fit_width() for the
## splash, and on Slate set_masthead(true) for the splash's rule.
static func make_wordmark(skin: SkinData) -> SkinWordmark:
	var mark: SkinWordmark = _pick(_WORDMARKS, skin).new() as SkinWordmark
	mark.setup(skin)
	return mark


static func _pick(table: Dictionary[StringName, GDScript], skin: SkinData) -> GDScript:
	if table.has(skin.id):
		return table[skin.id]
	push_error("UiKit: no components for skin '%s', using %s's" % [skin.id, SkinCatalog.DEFAULT_ID])
	return table[SkinCatalog.DEFAULT_ID]
