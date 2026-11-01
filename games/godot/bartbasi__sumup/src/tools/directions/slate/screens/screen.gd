extends "res://tools/directions/shared/screen_base.gd"
## Slate's composed screens. Board and targeting come from screen_base.
## Game over: the no moves offer (D-19) takes the header: "OUT OF MOVES" in
## signal vermilion over the score, a hairline, the two actions side by side,
## and the board stays fully visible below with the strip offering every booster.
## Settings: a sheet of ruled rows drops from the top over the dimmed board.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

## The display numerals carry a lot of space above the digits; pull the
## score up under its label by this share of the display size, as the HUD does.
const DISPLAY_PULL: float = 0.2


func direction_id() -> String:
	return "slate"


func compose_gameover() -> void:
	var margin: float = tokens.num("board_margin")
	var box: VBoxContainer = vbox(tokens.num("space_s"))
	add_child(box)

	var top_row: HBoxContainer = hbox(tokens.num("space_s"))
	box.add_child(top_row)
	var score_box: VBoxContainer = vbox(-tokens.font_size("display") * DISPLAY_PULL)
	score_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(score_box)
	var signal_label: Label = label("CaptionLabel", "label", MockState.GAMEOVER_TITLE)
	signal_label.add_theme_color_override("font_color", tokens.color("accent"))
	score_box.add_child(signal_label)
	score_box.add_child(label("DisplayLabel", "display", MockState.format_number(MockState.FINAL_SCORE)))
	var best_box: VBoxContainer = vbox(0.0)
	best_box.alignment = BoxContainer.ALIGNMENT_END
	top_row.add_child(best_box)
	best_box.add_child(label("CaptionLabel", "label", MockState.BEST_LABEL, HORIZONTAL_ALIGNMENT_RIGHT))
	best_box.add_child(label("BodyLabel", "body", MockState.format_number(MockState.BEST_SCORE), HORIZONTAL_ALIGNMENT_RIGHT))

	box.add_child(_rule())

	var buttons: HBoxContainer = hbox(tokens.num("space_s"))
	box.add_child(buttons)
	var rescue_cost: int = MockState.GAMEOVER_COSTS[MockState.BOOSTER_IDS.find(MockState.RESCUE_BOOSTER)]
	var primary: Button = button("PrimaryButton", MockState.buy_text(MockState.RESCUE_BOOSTER, rescue_cost), HORIZONTAL_ALIGNMENT_LEFT)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.size_flags_stretch_ratio = 1.8
	buttons.add_child(primary)
	var end_run: Button = button("SecondaryButton", MockState.GAMEOVER_END, HORIZONTAL_ALIGNMENT_LEFT)
	end_run.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(end_run)

	var height: float = place_container(box, Vector2(margin, float(MockState.safe_top)), canvas.x - margin * 2.0)
	text_holders.append(box)
	place_bar(MockState.GAMEOVER_COSTS, MockState.gameover_usable(), "")
	place_board(box.position.y + height, bar_top(true), MockState.gameover_values())


func compose_settings() -> void:
	compose_play(false, false)
	add_scrim()
	var margin: float = tokens.num("board_margin")
	# The sheet: a full width band of bg from the top of the screen, with a
	# hairline along its bottom edge.
	var sheet: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = tokens.color("bg")
	style.border_color = tokens.color("rule")
	style.border_width_bottom = int(tokens.num("rule_width"))
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = float(MockState.safe_top) + tokens.num("space_s")
	style.content_margin_bottom = tokens.num("space_m")
	sheet.add_theme_stylebox_override("panel", style)
	add_child(sheet)
	var box: VBoxContainer = vbox(tokens.num("space_s"))
	sheet.add_child(box)

	var header: HBoxContainer = hbox(tokens.num("space_s"))
	box.add_child(header)
	var title: Label = label("TitleLabel", "title", MockState.SETTINGS_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_vertical = Control.SIZE_FILL
	header.add_child(title)
	icon_button(header, "close", 96.0, 64.0)

	box.add_child(_rule())
	toggle(setting_row(box, MockState.SOUND_LABEL, tokens.num("row_height")), MockState.SOUND_ON)
	box.add_child(_rule())
	box.add_child(label("CaptionLabel", "label", MockState.SKIN_LABEL))
	var choices: HBoxContainer = hbox(tokens.num("space_s"))
	box.add_child(choices)
	for index: int in MockState.SKIN_IDS.size():
		skin_choice(choices, index, 72.0, tokens.num("button_radius"))
	box.add_child(_rule())
	box.add_child(label("CaptionLabel", "label", MockState.VERSION_TEXT))

	place_container(sheet, Vector2.ZERO, canvas.x)
	text_holders.append(sheet)


func _rule() -> HSeparator:
	var rule: HSeparator = HSeparator.new()
	rule.theme_type_variation = "Hairline"
	return rule
