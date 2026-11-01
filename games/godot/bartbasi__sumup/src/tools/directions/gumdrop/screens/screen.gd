extends "res://tools/directions/shared/screen_base.gd"
## Gumdrop's composed screens. Board and targeting come from screen_base.
## Game over: the no moves offer (D-19) is a rounded card where the HUD was,
## the board stays fully visible below it, and the dock offers every booster.
## Settings: a card over the dimmed play screen.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.


func direction_id() -> String:
	return "gumdrop"


func compose_gameover() -> void:
	var margin: float = tokens.num("board_margin")
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "CardPanel"
	add_child(card)
	var box: VBoxContainer = vbox(tokens.num("space_s"))
	card.add_child(box)

	var top_row: HBoxContainer = hbox(tokens.num("space_s"))
	box.add_child(top_row)
	var title: Label = label("TitleLabel", "title", MockState.GAMEOVER_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_vertical = Control.SIZE_FILL
	top_row.add_child(title)
	var score_box: VBoxContainer = vbox(0.0)
	score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_child(score_box)
	score_box.add_child(label("CaptionLabel", "label", MockState.SCORE_LABEL, HORIZONTAL_ALIGNMENT_RIGHT))
	score_box.add_child(label("BodyLabel", "body", MockState.format_number(MockState.FINAL_SCORE), HORIZONTAL_ALIGNMENT_RIGHT))

	box.add_child(label("MutedLabel", "body", MockState.GAMEOVER_BODY))

	var buttons: HBoxContainer = hbox(tokens.num("space_s"))
	box.add_child(buttons)
	var rescue_cost: int = MockState.GAMEOVER_COSTS[MockState.BOOSTER_IDS.find(MockState.RESCUE_BOOSTER)]
	var primary: Button = button("PrimaryButton", MockState.buy_text(MockState.RESCUE_BOOSTER, rescue_cost))
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.size_flags_stretch_ratio = 1.6
	buttons.add_child(primary)
	var end_run: Button = button("SecondaryButton", MockState.GAMEOVER_END)
	end_run.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(end_run)

	var card_height: float = place_container(card, Vector2(margin, float(MockState.safe_top) + tokens.num("space_xs")), canvas.x - margin * 2.0)
	text_holders.append(card)
	place_bar(MockState.GAMEOVER_COSTS, MockState.gameover_usable(), "")
	place_board(card.position.y + card_height, bar_top(true), MockState.gameover_values())


func compose_settings() -> void:
	compose_play(false, false)
	add_scrim()
	var margin: float = tokens.num("board_margin")
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "CardPanel"
	add_child(card)
	var box: VBoxContainer = vbox(tokens.num("space_m"))
	card.add_child(box)

	var header: HBoxContainer = hbox(tokens.num("space_s"))
	box.add_child(header)
	var title: Label = label("TitleLabel", "title", MockState.SETTINGS_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_vertical = Control.SIZE_FILL
	header.add_child(title)
	icon_button(header, "close", 108.0, 64.0)

	toggle(setting_row(box, MockState.SOUND_LABEL, tokens.num("touch_min")), MockState.SOUND_ON)
	var rule: HSeparator = HSeparator.new()
	rule.theme_type_variation = "Hairline"
	box.add_child(rule)

	box.add_child(label("BodyLabel", "body", MockState.SKIN_LABEL))
	var choices: HBoxContainer = hbox(tokens.num("space_s"))
	box.add_child(choices)
	for index: int in MockState.SKIN_IDS.size():
		skin_choice(choices, index, 72.0, tokens.num("button_radius"))
	box.add_child(label("CaptionLabel", "label", MockState.VERSION_TEXT, HORIZONTAL_ALIGNMENT_CENTER))

	var height: float = place_container(card, Vector2.ZERO, canvas.x - margin * 2.0)
	card.position = Vector2(margin, canvas.y - float(MockState.safe_bottom) - margin - height)
	text_holders.append(card)
