# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name StarLine
extends HBoxContainer
## One star line of the Pause menu (RULES 10.6): a star, the sentence, and one word for
## where the star stands. A lost line is struck through and says "Lost", so it never relies
## on color. `entry` comes from StarText.play_lines.

var icon: StarIcon
var sentence: RichTextLabel
var state_label: Label
var struck: bool = false
var state: String = ""


func _init(entry: Dictionary) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", 18)
	struck = bool(entry["struck"])
	state = str(entry["state"])
	icon = StarIcon.new(56.0, bool(entry["earned"]))
	add_child(icon)
	sentence = RichTextLabel.new()
	sentence.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sentence.bbcode_enabled = true
	sentence.fit_content = true
	sentence.scroll_active = false
	sentence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sentence.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sentence.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sentence.custom_minimum_size.x = 120.0
	sentence.add_theme_font_override(&"normal_font", UiTheme.font(UiTheme.WEIGHT_REGULAR))
	sentence.add_theme_font_size_override(&"normal_font_size", UiTheme.FONT_BODY)
	sentence.add_theme_color_override(&"default_color", Palette.TEXT_SOFT if struck else Palette.TEXT_LIGHT)
	var plain: String = str(entry["text"]).replace("[", "[lb]")
	sentence.text = "[s]%s[/s]" % plain if struck else plain
	add_child(sentence)
	state_label = UiKit.label(state, &"Label" if bool(entry["earned"]) or struck else &"SoftLabel")
	state_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	state_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	state_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if struck:
		state_label.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_HEAVY))
	add_child(state_label)


## The sentence as plain text, without the strike-through mark.
func sentence_text() -> String:
	return sentence.get_parsed_text()
