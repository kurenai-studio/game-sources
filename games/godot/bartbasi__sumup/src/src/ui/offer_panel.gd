class_name OfferPanel extends PanelContainer
## The out of moves offer (DESIGN_SYSTEM.md 7.5, GDD D-19 and D-42). It takes
## the HUD's place, so the board and the booster bar stay visible and usable:
## - "Out of moves" (the signal label) with the current score beside it;
## - "Pick a booster to keep this run going." (muted);
## - the suggested buy button ("Shuffle for 4K", primary; "Shuffle for free"
##   while a free booster is held, GDD D-46) and End run (secondary).
## With no suggestion, End run stands alone as the primary button and the text
## reads "No rescue left. Pick a booster or end the run."
##
## In a skin whose dialog panel floats (Gumdrop) the offer is a card; in a
## sheet skin (Slate, Nova) it sits on the backdrop with no box. GameScreen
## places it in the content column under the safe area's top and reads its
## height from its minimum size. setup must run with the panel in the tree.

signal booster_chosen(booster_id: StringName)
signal end_run_chosen()

const UiParts: GDScript = preload("res://src/ui/ui_parts.gd")
const Copy: GDScript = preload("res://src/ui/screen_copy.gd")

var _skin: SkinData = null
var _statuses: Array[BoosterStatus] = []
var _score: BigNum = BigNum.zero()
var _shown: bool = false
var _shown_key: String = ""
var _buy: Button = null
var _end: Button = null
var _body: Label = null
var _score_label: Label = null
var _title: Label = null
## The width GameScreen gives the offer, or negative before it has one.
var _width: float = -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(skin: SkinData) -> void:
	_skin = skin
	theme_type_variation = &"CardPanel" if UiParts.panel_floats(self) else &""
	_shown_key = ""
	if _shown:
		_rebuild()


## D-19: the offer for these statuses (bar order) and score. The suggested
## rescue is the status marked suggested (D-42), if any. Safe to call on every
## status change: it rebuilds only when what it shows changes.
func show_offer(statuses: Array[BoosterStatus], score: BigNum) -> void:
	_statuses = statuses
	_score = score if score != null else BigNum.zero()
	_shown = true
	var suggested: BoosterStatus = _suggested()
	var key: String = _key(suggested)
	if key != _shown_key and _skin != null:
		_rebuild()


## The buy button for the suggested booster, or null when nothing is
## suggested. For tests.
func buy_button() -> Button:
	return _buy


## End run, primary when it stands alone. For tests.
func end_run_button() -> Button:
	return _end


## The muted line as shown. For tests.
func body_text() -> String:
	return _body.text if _body != null else ""


## The score as shown. For tests.
func score_text() -> String:
	return _score_label.text if _score_label != null else ""


## Fits the score to width, the offer's width in the content column, so the
## offer never grows past the column however long the score (QA6-10). Safe
## to call on every layout.
func fit_width(width: float) -> void:
	_width = width
	_fit()


func _fit() -> void:
	if _width < 0.0 or _skin == null or _score_label == null or _title == null:
		return
	var skin: SkinData = _skin
	var padding_type: StringName = theme_type_variation if theme_type_variation != &"" else &"PanelContainer"
	var room: float = _width - UiParts.panel_padding(self, padding_type) - float(roundi(skin.num(&"space_s")))
	room -= UiParts.text_width(skin, _title.theme_type_variation, _title.text, skin.font_size(UiParts.role(skin, _title.theme_type_variation)))
	UiParts.fit_label(skin, _score_label, room, skin.font_size(UiParts.role(skin, _score_label.theme_type_variation)))


## What the offer shows, so it rebuilds only when that changes: the score as
## shown and the suggested booster with its cost, usability and free state.
func _key(suggested: BoosterStatus) -> String:
	if suggested == null:
		return "%s|" % NumberFormat.score(_score)
	return "%s|%s|%d|%s|%s" % [NumberFormat.score(_score), suggested.id, suggested.cost, suggested.usable, suggested.free]


func _suggested() -> BoosterStatus:
	for status: BoosterStatus in _statuses:
		if status.suggested:
			return status
	return null


func _rebuild() -> void:
	UiParts.clear(self)
	var skin: SkinData = _skin
	var suggested: BoosterStatus = _suggested()
	_shown_key = _key(suggested)
	var content: VBoxContainer = UiParts.vbox(skin.num(&"space_s"))
	add_child(content)

	var top: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	content.add_child(top)
	_title = UiParts.label(skin, &"SignalLabel", Copy.OUT_OF_MOVES)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	var score_box: VBoxContainer = UiParts.vbox(0.0)
	score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(score_box)
	score_box.add_child(UiParts.label(skin, &"CaptionLabel", Copy.SCORE, HORIZONTAL_ALIGNMENT_RIGHT))
	_score_label = UiParts.label(skin, &"BodyLabel", NumberFormat.score(_score), HORIZONTAL_ALIGNMENT_RIGHT)
	_score_label.name = "Score"
	score_box.add_child(_score_label)

	var text: String = Copy.OFFER_BODY if suggested != null else Copy.OFFER_NO_RESCUE
	_body = UiParts.paragraph(skin, &"MutedLabel", text, HORIZONTAL_ALIGNMENT_LEFT)
	content.add_child(_body)

	var buttons: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	content.add_child(buttons)
	_buy = null
	if suggested != null:
		_buy = UiParts.button(skin, &"PrimaryButton", Copy.buy(suggested.id, suggested.cost, suggested.free))
		_buy.name = "Buy"
		_buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_buy.disabled = not suggested.usable
		_buy.pressed.connect(_on_buy.bind(suggested.id))
		buttons.add_child(_buy)
	_end = UiParts.button(skin, &"SecondaryButton" if suggested != null else &"PrimaryButton", Copy.END_RUN)
	_end.name = "EndRun"
	_end.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end.pressed.connect(_on_end_run)
	buttons.add_child(_end)
	_fit()


func _on_buy(booster_id: StringName) -> void:
	booster_chosen.emit(booster_id)


func _on_end_run() -> void:
	end_run_chosen.emit()
