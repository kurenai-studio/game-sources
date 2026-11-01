extends "res://tools/directions/shared/screen_base.gd"
## Nova's composed screens. Board and targeting come from screen_base.
## Game over: the no moves offer (D-19) floats centered where the HUD was:
## "Out of moves" in light type, the score under it, the two actions, and the
## board stays fully visible below with the rings offering every booster.
## Settings: a sheet with rounded top corners rises over the dimmed play screen.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.


func direction_id() -> String:
	return "nova"


func compose_gameover() -> void:
	var margin: float = tokens.num("board_margin")
	var box: VBoxContainer = vbox(tokens.num("space_xs"))
	add_child(box)
	box.add_child(label("TitleLabel", "title", MockState.GAMEOVER_TITLE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(label("MutedLabel", "body", "%s %s" % [MockState.SCORE_LABEL.to_lower(), MockState.format_number(MockState.FINAL_SCORE)], HORIZONTAL_ALIGNMENT_CENTER))
	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(0.0, tokens.num("space_xs"))
	box.add_child(gap)

	var buttons: HBoxContainer = hbox(tokens.num("space_s"))
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)
	var rescue_cost: int = MockState.GAMEOVER_COSTS[MockState.BOOSTER_IDS.find(MockState.RESCUE_BOOSTER)]
	var primary: Button = button("PrimaryButton", MockState.buy_text(MockState.RESCUE_BOOSTER, rescue_cost))
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.size_flags_stretch_ratio = 1.5
	buttons.add_child(primary)
	var end_run: Button = button("SecondaryButton", MockState.GAMEOVER_END)
	end_run.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(end_run)

	var height: float = place_container(box, Vector2(margin, float(MockState.safe_top) + tokens.num("space_s")), canvas.x - margin * 2.0)
	text_holders.append(box)
	place_bar(MockState.GAMEOVER_COSTS, MockState.gameover_usable(), "")
	place_board(box.position.y + height, bar_top(true), MockState.gameover_values())


func compose_settings() -> void:
	compose_play(false, false)
	add_scrim()
	var sheet: PanelContainer = PanelContainer.new()
	sheet.theme_type_variation = "CardPanel"
	add_child(sheet)
	var box: VBoxContainer = vbox(tokens.num("space_m"))
	sheet.add_child(box)

	var header: HBoxContainer = hbox(tokens.num("space_s"))
	box.add_child(header)
	var title: Label = label("TitleLabel", "title", MockState.SETTINGS_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_vertical = Control.SIZE_FILL
	header.add_child(title)
	icon_button(header, "close", 96.0, 64.0)

	toggle(setting_row(box, MockState.SOUND_LABEL, tokens.num("touch_min")), MockState.SOUND_ON)
	var rule: HSeparator = HSeparator.new()
	rule.theme_type_variation = "Hairline"
	box.add_child(rule)
	box.add_child(label("CaptionLabel", "label", MockState.SKIN_LABEL))
	var choices: HBoxContainer = hbox(tokens.num("space_s"))
	box.add_child(choices)
	for index: int in MockState.SKIN_IDS.size():
		skin_choice(choices, index, 72.0, tokens.num("sheet_radius") * 0.5)
	box.add_child(label("CaptionLabel", "label", MockState.VERSION_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	# Room for the gesture bar under the sheet's content.
	var under: Control = Control.new()
	under.custom_minimum_size = Vector2(0.0, float(MockState.safe_bottom))
	box.add_child(under)

	var height: float = place_container(sheet, Vector2.ZERO, canvas.x)
	sheet.position = Vector2(0.0, canvas.y - height)
	text_holders.append(sheet)
