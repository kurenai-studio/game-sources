# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name StatRow
extends BoxContainer
## One line of numbers. Either a name and a value, or a name with a number
## before and after an upgrade with an arrow drawn between them (RULES 9.5). A stacked change
## row puts the name on its own line and lets the after text wrap, for words too long to sit
## beside the name in a narrow card ("Walkers and flyers").

var name_label: Label
var value_label: Label
var before_label: Label
var after_label: Label
var arrow: TextureRect


## `name_variation` and `value_variation` are UiTheme label types, so the row
## reads on a dark panel (Label, SoftLabel) or on a card (CardLabel, CardMutedLabel).
static func pair(label_text: String, value_text: String, name_variation: StringName = &"SoftLabel", value_variation: StringName = &"Label") -> StatRow:
	var row: StatRow = StatRow.new()
	row.name_label = UiKit.label(label_text, name_variation)
	row.name_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.value_label = UiKit.label(value_text, value_variation)
	row.value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(row.name_label)
	row.add_child(row.value_label)
	return row


static func change(label_text: String, before_text: String, after_text: String, name_variation: StringName = &"SoftLabel", value_variation: StringName = &"Label", tint: Color = Palette.TEXT_LIGHT, font_size: int = UiTheme.FONT_SMALL, stacked: bool = false) -> StatRow:
	var row: StatRow = StatRow.new()
	row.name_label = UiKit.label(label_text, name_variation)
	row.name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.before_label = UiKit.label(before_text, value_variation)
	row.before_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.before_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.arrow = TextureRect.new()
	row.arrow.texture = IconTex.make(&"arrow", 64)
	row.arrow.custom_minimum_size = Vector2(44.0, 44.0)
	row.arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row.arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.arrow.modulate = tint
	row.arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.after_label = UiKit.label(after_text, value_variation)
	row.after_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.after_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.after_label.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_BOLD))
	for l: Label in [row.name_label, row.before_label, row.after_label]:
		l.add_theme_font_size_override(&"font_size", font_size)
	if stacked:
		row.vertical = true
		row.after_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.after_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var values: HBoxContainer = HBoxContainer.new()
		values.mouse_filter = Control.MOUSE_FILTER_IGNORE
		values.add_theme_constant_override(&"separation", 8)
		values.add_child(row.before_label)
		values.add_child(row.arrow)
		values.add_child(row.after_label)
		row.add_child(row.name_label)
		row.add_child(values)
		return row
	row.add_child(row.name_label)
	row.add_child(row.before_label)
	row.add_child(row.arrow)
	row.add_child(row.after_label)
	return row


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", 8)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
