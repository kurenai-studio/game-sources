extends RefCounted
## Shared helpers for the design tests.

## The type variations docs/ARCHITECTURE.md section 7 names, with their base
## types, then the ones the design system adds. Written out here on purpose,
## not read from the code, so the tests check the contract.
const CONTRACT_VARIATIONS: Dictionary[StringName, StringName] = {
	&"DisplayLabel": &"Label",
	&"TitleLabel": &"Label",
	&"BodyLabel": &"Label",
	&"MutedLabel": &"Label",
	&"CaptionLabel": &"Label",
	&"PrimaryButton": &"Button",
	&"SecondaryButton": &"Button",
	&"ChipButton": &"Button",
	&"CardPanel": &"PanelContainer",
	&"PillPanel": &"PanelContainer",
	&"HintPanel": &"PanelContainer",
	&"Hairline": &"HSeparator",
	&"HeadingLabel": &"Label",
	&"ReadingLabel": &"Label",
	&"SectionPanel": &"PanelContainer",
	&"RowButton": &"Button",
	&"RowDetailLabel": &"Label",
}
const ADDED_VARIATIONS: Dictionary[StringName, StringName] = {
	&"IconButton": &"Button",
	&"BadgePanel": &"PanelContainer",
	&"BadgeLabel": &"Label",
	&"SignalLabel": &"Label",
	&"HintLabel": &"Label",
}
const BUTTON_TYPES: Array[StringName] = [&"Button", &"PrimaryButton", &"SecondaryButton", &"ChipButton", &"IconButton", &"RowButton"]
const BUTTON_STATES: Array[StringName] = [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]
const BUTTON_COLORS: Array[StringName] = [
	&"font_color", &"font_hover_color", &"font_focus_color",
	&"font_pressed_color", &"font_hover_pressed_color", &"font_disabled_color",
]
const BOOSTERS: Array[StringName] = [&"hammer", &"swap", &"shuffle", &"double", &"undo"]
## The page a skin's transparent buttons and plain labels sit on, worst case.
const PAGE: Dictionary[StringName, StringName] = {&"gumdrop": &"bg", &"slate": &"bg", &"nova": &"bg_glow"}


## One status per booster in bar order: hammer usable, swap active
## (targeting), shuffle usable and suggested, double too dear, undo with no
## snapshot.
static func offer_statuses() -> Array[BoosterStatus]:
	var statuses: Array[BoosterStatus] = []
	statuses.append(status(&"hammer", 11, true, BoosterStatus.Usability.USABLE, false, false))
	statuses.append(status(&"swap", 11, true, BoosterStatus.Usability.USABLE, true, false))
	statuses.append(status(&"shuffle", 12, true, BoosterStatus.Usability.USABLE, false, true))
	statuses.append(status(&"double", 17, false, BoosterStatus.Usability.CANNOT_AFFORD, false, false))
	statuses.append(status(&"undo", 10, false, BoosterStatus.Usability.NO_SNAPSHOT, false, false))
	return statuses


## Every booster usable, none active or suggested, all at cost (an exponent:
## the price is 2^cost).
static func plain_statuses(cost: int) -> Array[BoosterStatus]:
	var statuses: Array[BoosterStatus] = []
	for id: StringName in BOOSTERS:
		statuses.append(status(id, cost, true, BoosterStatus.Usability.USABLE, false, false))
	return statuses


## A free booster held (D-46): every status free, hammer active (targeting)
## and undo disabled with no snapshot, the rest usable.
static func free_statuses() -> Array[BoosterStatus]:
	var statuses: Array[BoosterStatus] = []
	for i: int in BOOSTERS.size():
		var usable: bool = i != 4
		var reason: BoosterStatus.Usability = BoosterStatus.Usability.USABLE if usable else BoosterStatus.Usability.NO_SNAPSHOT
		var made: BoosterStatus = status(BOOSTERS[i], 12, usable, reason, i == 0, false)
		made.free = true
		statuses.append(made)
	return statuses


## Every control under root, root included.
static func controls_under(root: Node) -> Array[Control]:
	var found: Array[Control] = []
	if root is Control:
		found.append(root as Control)
	for child: Node in root.get_children():
		found.append_array(controls_under(child))
	return found


## A score as a BigNum, from an int.
static func big(value: int) -> BigNum:
	return BigNum.from_int(value)


## A score as a BigNum, from its decimal digits (any length).
static func digits(text: String) -> BigNum:
	return BigNum.parse(text, text.length())


## cost is an exponent: the price is 2^cost.
static func status(id: StringName, cost: int, usable: bool, reason: BoosterStatus.Usability, active: bool, suggested: bool) -> BoosterStatus:
	var made: BoosterStatus = BoosterStatus.new()
	made.id = id
	made.cost = cost
	made.usable = usable
	made.reason = reason
	made.active = active
	made.suggested = suggested
	return made


## Whether fg on bg is one of the skin's listed text pairs, comparing the
## colors the tokens hold.
static func is_listed_pair(skin: SkinData, fg: Color, bg: Color) -> bool:
	for entry: Dictionary in skin.text_pairs:
		var pair_fg: Color = _resolve(skin, String(entry["fg"]))
		var pair_bg: Color = _resolve(skin, String(entry["bg"]))
		if pair_fg.is_equal_approx(fg) and pair_bg.is_equal_approx(bg):
			return true
	return false


## Whether color is the text color of any listed pair.
static func is_listed_text_color(skin: SkinData, color: Color) -> bool:
	for entry: Dictionary in skin.text_pairs:
		if _resolve(skin, String(entry["fg"])).is_equal_approx(color):
			return true
	return false


## The color a button's text sits on in a style: the style's fill, or the
## page when it draws no fill.
static func face_color(skin: SkinData, style: StyleBox) -> Color:
	var flat: StyleBoxFlat = style as StyleBoxFlat
	if flat != null and flat.draw_center and flat.bg_color.a > 0.0:
		return flat.bg_color
	return skin.color(PAGE[skin.id])


## A text pair token as a color. "tile:<value>" names a tile value (65536);
## the skin takes the tile's exponent.
static func _resolve(skin: SkinData, token: String) -> Color:
	if token.begins_with("tile:"):
		return skin.fill_for(SkinData.exponent_of(token.substr(5).to_int()))
	return skin.color(StringName(token))
