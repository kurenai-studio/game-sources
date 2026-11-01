# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name DraftPanel
extends BattlePanel
## The card draft (RULES 14.4): one to three cards after a wave, shown as a bottom sheet in
## portrait and in the side column in landscape. Each card has its picture (the tower's
## silhouette for a tower or a perk, a glyph for the other kinds), its kind in words, its
## name and its text. A tap on a card chooses it, with a thick edge and a check mark, and a
## separate Take button confirms. The panel cannot be put away: only taking a card ends it
## (the screen closes it then, and the back button never does). Names and texts come from the
## cards in the run data, never from this file.

## The player took this card. The screen asks the run to pick it and answers with `close`
## or `reject`.
signal picked(card_id: StringName)

const KIND_WORDS: Dictionary[StringName, String] = {
	&"tower": "New tower",
	&"perk": "Tower perk",
	&"gate": "Extra gate",
	&"economy": "Economy",
	&"risk": "Risk",
}
const KIND_GLYPHS: Dictionary[StringName, StringName] = {
	&"gate": &"gate",
	&"economy": &"coin",
	&"risk": &"moon",
}

var cards: Array[Dictionary] = []
var selected: StringName = &""
var rows: Dictionary[StringName, TapRow] = {}
var marks: Dictionary[StringName, TextureRect] = {}
var title_label: Label = null
var take_button: TapButton = null


## Shows these cards (each a card of the run data) under `title`. Nothing is chosen.
func show_offers(offers: Array[Dictionary], title: String) -> void:
	cards = offers.duplicate()
	selected = &""
	clear_feedback()
	_rebuild(title)


## The ids on offer, in the order shown.
func offered() -> Array[StringName]:
	var out: Array[StringName] = []
	for card: Dictionary in cards:
		out.append(card["id"])
	return out


## Chooses a card, as a tap on it does.
func select(id: StringName) -> void:
	if not rows.has(id):
		return
	selected = id
	clear_feedback()
	_show_choice()


## Takes the chosen card, as the Take button does. Nothing chosen gives a short message.
func take() -> void:
	if selected == &"":
		var text: String = "Tap a card first."
		show_feedback(text)
		refused.emit(&"no_card", text)
		return
	picked.emit(selected)


## The run refused the card (it never should). The panel stays open and says so.
func reject(reason: StringName) -> void:
	var text: String = BattleText.pick_refusal(reason)
	show_feedback(text)
	refused.emit(reason, text)


## The card was taken: the panel is done.
func close() -> void:
	closed.emit()


func _rebuild(title: String) -> void:
	clear_column()
	rows.clear()
	marks.clear()
	title_label = UiKit.heading(title)
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_child(title_label)
	for card: Dictionary in cards:
		var row: TapRow = _row(card)
		rows[card["id"]] = row
		column.add_child(row)
	take_button = UiKit.wrapped(UiKit.button("Take a card"))
	take_button.tapped.connect(take)
	column.add_child(take_button)
	column.add_child(feedback_box)
	_show_choice()


func _row(card: Dictionary) -> TapRow:
	var id: StringName = card["id"]
	var row: TapRow = TapRow.new()
	row.tapped.connect(select.bind(id))
	var line: HBoxContainer = HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override(&"separation", 18)
	line.add_child(_picture(card))
	var text: VBoxContainer = VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_theme_constant_override(&"separation", 2)
	text.add_child(UiKit.label(KIND_WORDS.get(card["kind"], "Card"), &"SoftLabel"))
	text.add_child(UiKit.heading(String(card["name"])))
	text.add_child(UiKit.label(String(card["text"])))
	line.add_child(text)
	var mark: TextureRect = TextureRect.new()
	mark.texture = IconTex.make(&"check", 64)
	mark.custom_minimum_size = Vector2(52.0, 52.0)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marks[id] = mark
	line.add_child(mark)
	row.body.add_child(line)
	return row


func _picture(card: Dictionary) -> GlyphIcon:
	var picture: GlyphIcon = GlyphIcon.new(120.0)
	var kind: StringName = card["kind"]
	var tower: StringName = card.get("tower", &"")
	if (kind == &"tower" or kind == &"perk") and Silhouettes.has_tower(tower):
		return picture.show_tower(tower, 1, -1)
	return picture.show_glyph(KIND_GLYPHS.get(kind, &"gate"))


## The chosen card has a thick honey edge, a check mark and the Take button in honey with its
## name: three signals, so a choice is never shown by color alone.
func _show_choice() -> void:
	for id: StringName in rows:
		var chosen: bool = id == selected
		rows[id].set_look(Palette.PANEL_RAISED, Palette.HONEY if chosen else Palette.PANEL_EDGE, 10 if chosen else 3, 18)
		marks[id].modulate = Palette.HONEY if chosen else Color(1.0, 1.0, 1.0, 0.0)
	if take_button == null:
		return
	if selected == &"":
		take_button.text = "Take a card"
		take_button.theme_type_variation = &"Button"
		take_button.icon = IconTex.make(&"lock", 56)
		for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color", &"icon_hover_pressed_color"]:
			take_button.add_theme_color_override(state, Palette.TEXT_SOFT)
	else:
		for card: Dictionary in cards:
			if card["id"] == selected:
				take_button.text = "Take %s" % String(card["name"])
		take_button.theme_type_variation = &"PrimaryButton"
		take_button.icon = null
