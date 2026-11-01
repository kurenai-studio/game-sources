class_name SplashScreen extends Control
## The splash screen (GDD D-47 and 15.4, DESIGN_SYSTEM.md 7.2), the game's
## front door. It shows at every launch, with or without a saved run, and
## after the end of run screen's Home. Over the skin's backdrop, inside the
## safe area and the content column (2.8), top to bottom:
## - the settings icon button, top right;
## - the brand block, centered (Slate left aligns it): the drawn wordmark
##   (UiKit.make_wordmark, with Slate's masthead rule), fitted to the sum row's
##   width; space_m; the sum row: 2, 2, 4, 8 drawn by the skin's own board
##   view as a chained one row board of 144 px tiles, space_m, the arrow
##   (72 px), space_m, and the result 16 as the skin's tile view;
## - the records, space_l above the buttons: Best score with the number, then
##   Best tile with a mini tile once there is one;
## - Play (primary) full width less board_margin each side, space_s, then Info
##   and About (secondary) side by side;
## - space_xs, then the Buy me a coffee button (coffee_button.gd), its touch
##   area on the bottom of the safe area: centered in the column (Slate: its
##   content starts on the content's left edge). It hands the one address to
##   the system on a tap and changes nothing else.
## The free height between the settings button and the records splits 1 to 1
## above and below the brand block (2026-10-17, was 2 to 3). Should it ever run out, the sum row's
## tiles shrink, never below 112 px, and the wordmark follows them.
##
## The entrance (play_entrance) is decoration and never blocks input: the
## brand block plays dialog_in, the sum row starts empty and at half of
## dialog_in spawns its four tiles with the board view's play_spawn; when
## that ends the chain appears whole and the arrow and the result fade in.
## The App plays it when the splash is shown anew (launch, Home), never when
## a panel over it closes, and never on a skin switch (apply_skin rebuilds it
## at rest).
##
## The splash changes nothing: it only reports its buttons. setup must run
## with the splash in the tree.

signal play_chosen()
signal info_chosen()
signal about_chosen()
signal settings_chosen()

const UiParts: GDScript = preload("res://src/ui/ui_parts.gd")
const Copy: GDScript = preload("res://src/ui/screen_copy.gd")
const CoffeeButton: GDScript = preload("res://src/ui/coffee_button.gd")

## DESIGN_SYSTEM.md 7.9: the sum row's tiles, the smallest they may shrink
## to, and its arrow.
const SUM_TILE: float = 144.0
const SUM_TILE_MIN: float = 112.0
const SUM_ARROW: float = 72.0
## 7.2: the sum row, a true move: 2 + 2 + 4 + 8 = 16, as exponents (2 is 1).
const SUM_VALUES: Array[int] = [1, 1, 2, 3]
const SUM_RESULT: int = 4
## Side of the Best tile mini tile in the record rows (DESIGN_SYSTEM.md 7.9,
## 96 px since 2026-10-21 so a 5 character label reads as large as 4 did).
const MINI_TILE: float = 96.0
## DESIGN_SYSTEM.md 7.2: the free height splits 1 to 1 above and below the
## brand block (2026-10-17), which keeps the brand where it was before the
## coffee row took its height.
const SPLIT_ABOVE_BRAND: float = 1.0
const SPLIT_BELOW_BRAND: float = 1.0

## Where the entrance is: at rest, the brand coming in before the spawn, or
## the tiles spawning.
enum Entrance { REST, BRAND_IN, SPAWNING }

var _skin: SkinData = null
var _records: Records = null
var _backdrop: SkinBackdrop = null
var _layout_root: VBoxContainer = null
var _brand_slot: Control = null
var _brand: VBoxContainer = null
var _wordmark: SkinWordmark = null
var _sum_board: SkinBoardView = null
var _arrow: SkinIcon = null
var _result: SkinTileView = null
var _tile_side: float = SUM_TILE
var _records_box: VBoxContainer = null
var _settings_button: BaseButton = null
var _play: Button = null
var _info: Button = null
var _about: Button = null
var _coffee: Control = null
var _best_score: Label = null
var _entrance: Entrance = Entrance.REST
var _entrance_tween: Tween = null
## Every tween the entrance started, so a rebuild or the splash going away
## stops them all with it.
var _entrance_tweens: Array[Tween] = []


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(skin: SkinData, records: Records) -> void:
	_skin = skin
	_records = records
	_stop_entrance()
	UiParts.clear(self)
	_backdrop = UiKit.make_backdrop(skin)
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var margin: float = skin.num(&"board_margin")
	_layout_root = UiParts.vbox(0.0)
	_layout_root.name = "Layout"
	add_child(_layout_root)

	var top_margin: MarginContainer = _margins(_layout_root, UiParts.icon_button_inset(skin))
	var top_row: HBoxContainer = UiParts.hbox(0.0)
	top_row.alignment = BoxContainer.ALIGNMENT_END
	top_margin.add_child(top_row)
	_settings_button = UiParts.icon_button(skin, &"settings")
	_settings_button.name = "Settings"
	_settings_button.pressed.connect(settings_chosen.emit)
	top_row.add_child(_settings_button)

	# The brand block sits in a plain slot, so its entrance can move it with
	# no container putting it back.
	_layout_root.add_child(_spacer(SPLIT_ABOVE_BRAND))
	var brand_margin: MarginContainer = _margins(_layout_root, margin)
	_brand_slot = Control.new()
	_brand_slot.name = "BrandSlot"
	_brand_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand_margin.add_child(_brand_slot)
	_brand_slot.resized.connect(_update_clear_rects)
	_tile_side = SUM_TILE
	_brand = null
	_build_brand()
	_layout_root.add_child(_spacer(SPLIT_BELOW_BRAND))

	# The records and the buttons, one group in the thumb zone.
	var records_margin: MarginContainer = _margins(_layout_root, margin)
	_records_box = UiParts.vbox(0.0)
	_records_box.name = "Records"
	records_margin.add_child(_records_box)
	_records_box.resized.connect(_update_clear_rects)
	_best_score = UiParts.label(skin, &"BodyLabel", NumberFormat.score(records.best_score if records != null else BigNum.zero()))
	_best_score.name = "BestScore"
	_records_box.add_child(UiParts.record_row(skin, Copy.BEST_SCORE, _best_score))
	if records != null and records.best_tile > 0:
		_records_box.add_child(UiParts.divider())
		_records_box.add_child(UiParts.record_row(skin, Copy.BEST_TILE, UiParts.tile(skin, records.best_tile, MINI_TILE)))
	_layout_root.add_child(UiParts.spacer(skin.num(&"space_l")))
	var bottom: MarginContainer = _margins(_layout_root, margin)
	var buttons: VBoxContainer = UiParts.vbox(skin.num(&"space_s"))
	buttons.name = "Buttons"
	bottom.add_child(buttons)
	_play = _button(skin, &"PrimaryButton", Copy.PLAY, "Play", play_chosen)
	buttons.add_child(_play)
	var pair: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	pair.name = "LookUp"
	buttons.add_child(pair)
	_info = _button(skin, &"SecondaryButton", Copy.INFO, "Info", info_chosen)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pair.add_child(_info)
	_about = _button(skin, &"SecondaryButton", Copy.ABOUT, "About", about_chosen)
	_about.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pair.add_child(_about)
	_layout_root.add_child(UiParts.spacer(skin.num(&"space_xs")))
	var coffee_margin: MarginContainer = _margins(_layout_root, margin)
	_coffee = CoffeeButton.new()
	_coffee.call(&"setup", skin)
	_coffee.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if UiParts.align_start(skin) else Control.SIZE_SHRINK_CENTER
	coffee_margin.add_child(_coffee)
	_coffee.resized.connect(_update_clear_rects)
	_layout()


## Rebuilds the splash in a new skin, at rest: the skin_switch cross-fade
## carries the change, so the entrance does not play again.
func apply_skin(skin: SkinData) -> void:
	setup(skin, _records)


## The entrance (DESIGN_SYSTEM.md 7.2). Decoration only: every button works
## from the first frame, and it stops with the splash.
func play_entrance() -> void:
	if _skin == null or _brand == null:
		return
	_stop_entrance()
	_entrance = Entrance.BRAND_IN
	_sum_board.set_chain([] as Array[Vector2i], Vector2(-1.0, -1.0))
	var empty: PackedInt64Array = PackedInt64Array()
	empty.resize(SUM_VALUES.size())
	empty.fill(0)
	_sum_board.set_board(empty)
	_arrow.modulate.a = 0.0
	_result.modulate.a = 0.0
	_entrance_tweens.append(Motion.dialog_in(_brand, _skin))
	_entrance_tween = Motion.tween_for(self, _skin, &"dialog_in")
	_entrance_tweens.append(_entrance_tween)
	_entrance_tween.tween_interval(_skin.duration(&"dialog_in") * 0.5)
	_entrance_tween.tween_callback(_spawn_sum_row)


## Where the entrance is. For tests.
func entrance_stage() -> Entrance:
	return _entrance


## The tween driving the entrance's current step, or null at rest. For tests,
## which step it by hand.
func entrance_tween() -> Tween:
	return _entrance_tween


## The Best score as shown. For tests.
func best_score_text() -> String:
	return _best_score.text if _best_score != null else ""


## The brand block's global rect, for layout checks.
func brand_rect() -> Rect2:
	return _brand_slot.get_global_rect() if _brand_slot != null else Rect2()


## The Buy me a coffee button. For tests.
func coffee_button() -> Control:
	return _coffee


## The parts of the brand block. For tests.
func wordmark() -> SkinWordmark:
	return _wordmark


func sum_board() -> SkinBoardView:
	return _sum_board


func sum_arrow() -> SkinIcon:
	return _arrow


func sum_result() -> SkinTileView:
	return _result


## The sum row tiles' side as built: 144 px unless the screen has no room.
func sum_tile_side() -> float:
	return _tile_side


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_ENTER_TREE:
		_layout()
	elif what == NOTIFICATION_PREDELETE:
		_stop_entrance()


## The layout fills the content column; the backdrop fills the screen.
func _layout() -> void:
	if _layout_root == null or not is_inside_tree():
		return
	layout_in(get_global_rect(), SafeArea.content_column(get_viewport(), _skin))
	_update_clear_rects()


## Lays the splash out for its own rect and the content column, both in the
## same (global) coordinates. _layout calls it; tests call it with rects of
## their own, since headless tests never enter the scene tree.
func layout_in(screen: Rect2, column: Rect2) -> void:
	if _layout_root == null:
		return
	_layout_root.position = column.position - screen.position
	_layout_root.size = column.size
	var inner: float = column.size.x - 2.0 * float(roundi(_skin.num(&"board_margin")))
	_fit_best_score(inner)
	_shrink_to_fit(column.size.y)
	_size_brand(inner)


## 7.2 fallback: when the content is taller than the column, the sum row's
## tiles shrink (never below 112 px) and the wordmark follows them.
func _shrink_to_fit(height: float) -> void:
	if _entrance != Entrance.REST:
		return
	var brand_height: float = _brand_height()
	var deficit: float = _content_height(brand_height) - height
	if deficit <= 0.0 or _tile_side <= SUM_TILE_MIN:
		return
	var side: float = maxf(SUM_TILE_MIN, floorf(_tile_side * (brand_height - deficit) / brand_height))
	if side >= _tile_side:
		return
	_tile_side = side
	_build_brand()


## The brand block's height: the wordmark, space_m and the sum row, whose
## tallest part is the board view or the result tile.
func _brand_height() -> float:
	var row: float = maxf(_sum_board.custom_minimum_size.y, maxf(_tile_side, SUM_ARROW))
	return _wordmark.get_minimum_size().y + _skin.num(&"space_m") + row


## The splash's content height with no free space: the settings row, the
## brand block, the records, space_l, the buttons and the coffee row. Worked out from the
## tokens, so it holds before the containers have sorted.
func _content_height(brand_height: float) -> float:
	var rows: int = 2 if _records != null and _records.best_tile > 0 else 1
	var records: float = float(rows) * _skin.num(&"row_height") + float(rows - 1) * _skin.num(&"hairline")
	var buttons: float = 2.0 * _skin.num(&"button_height") + _skin.num(&"space_s")
	var coffee: float = _skin.num(&"space_xs") + _skin.num(&"touch_min")
	return _skin.num(&"touch_min") + brand_height + records + _skin.num(&"space_l") + buttons + coffee


## The brand block fills its slot's width; its own boxes center it (Slate:
## left). Its place in the slot is its resting place, which the entrance
## moves it from and back to.
func _size_brand(width: float) -> void:
	var height: float = maxf(_brand.get_combined_minimum_size().y, _brand_height())
	_brand_slot.custom_minimum_size = Vector2(0.0, height)
	_brand.size = Vector2(maxf(0.0, width), height)


## Builds the brand block in the slot, at rest, for the current tile side.
func _build_brand() -> void:
	var skin: SkinData = _skin
	var start: bool = UiParts.align_start(skin)
	if _brand != null:
		_brand_slot.remove_child(_brand)
		_brand.queue_free()
	_brand = UiParts.vbox(skin.num(&"space_m"))
	_brand.name = "Brand"
	_brand.position = Vector2.ZERO
	_brand_slot.add_child(_brand)

	var row: HBoxContainer = UiParts.hbox(0.0)
	row.name = "SumRow"
	row.alignment = BoxContainer.ALIGNMENT_BEGIN if start else BoxContainer.ALIGNMENT_CENTER
	var values: PackedInt64Array = PackedInt64Array(SUM_VALUES)
	_sum_board = UiParts.chain_board(skin, values, _tile_side)
	row.add_child(_sum_board)
	row.add_child(UiParts.spacer(0.0, skin.num(&"space_m")))
	_arrow = UiParts.arrow(skin, SUM_ARROW)
	row.add_child(_arrow)
	row.add_child(UiParts.spacer(0.0, skin.num(&"space_m")))
	_result = UiParts.tile(skin, SUM_RESULT, _tile_side)
	_result.name = "Result"
	_result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_result)

	_wordmark = UiKit.make_wordmark(skin)
	_wordmark.name = "Wordmark"
	_wordmark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wordmark.set_masthead(true)
	_wordmark.fit_width(row.get_combined_minimum_size().x)
	_brand.add_child(_wordmark)
	_brand.add_child(row)
	_ignore_mouse(_brand)


func _stop_entrance() -> void:
	for tween: Tween in _entrance_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_entrance_tweens.clear()
	_entrance_tween = null
	_entrance = Entrance.REST


## Step 3 of the entrance: the four tiles spawn in chain order.
func _spawn_sum_row() -> void:
	if _sum_board == null or _entrance != Entrance.BRAND_IN:
		return
	_entrance = Entrance.SPAWNING
	var length: float = _sum_board.play_spawn(UiParts.row_cells(SUM_VALUES.size()), PackedInt64Array(SUM_VALUES))
	_entrance_tween = Motion.tween_for(self, _skin, &"spawn")
	_entrance_tweens.append(_entrance_tween)
	_entrance_tween.tween_interval(maxf(length, 0.001))
	_entrance_tween.tween_callback(_finish_entrance)


## Step 4: the chain appears whole, the arrow and the result fade in.
func _finish_entrance() -> void:
	if _sum_board == null or _entrance != Entrance.SPAWNING:
		return
	_entrance = Entrance.REST
	_entrance_tween = null
	_sum_board.set_board(PackedInt64Array(SUM_VALUES))
	_sum_board.set_chain(UiParts.row_cells(SUM_VALUES.size()), Vector2(-1.0, -1.0))
	_entrance_tweens.append(Motion.fade(_arrow, _skin, 1.0))
	_entrance_tweens.append(Motion.fade(_result, _skin, 1.0))


## Fits the Best score number to its row, width wide less the caption, so the
## splash never grows past the column however long the number (QA6-10).
func _fit_best_score(width: float) -> void:
	if _best_score == null:
		return
	var caption: Label = _best_score.get_parent().get_child(0) as Label
	var room: float = width - float(roundi(_skin.num(&"space_s")))
	room -= UiParts.text_width(_skin, caption.theme_type_variation, caption.text, _skin.font_size(UiParts.role(_skin, caption.theme_type_variation)))
	UiParts.fit_label(_skin, _best_score, room, _skin.font_size(UiParts.role(_skin, _best_score.theme_type_variation)))


## Keeps the backdrop's decoration clear of the settings button, the brand
## block (its resting rect), the records, the three buttons and the coffee
## button with the reach of its pressed fill.
func _update_clear_rects() -> void:
	if _backdrop == null or _brand_slot == null or not is_inside_tree():
		return
	var reach: float = _skin.num(&"space_s")
	var coffee: Rect2 = _coffee.get_global_rect().grow_individual(reach, 0.0, reach, 0.0)
	var clear: Array[Rect2] = [_brand_slot.get_global_rect(), _records_box.get_global_rect(), _play.get_global_rect(), _info.get_global_rect(), _about.get_global_rect(), coffee, _settings_button.get_global_rect()]
	_backdrop.set_clear_rects(clear)


func _button(skin: SkinData, variation: StringName, text: String, node_name: String, chosen: Signal) -> Button:
	var made: Button = UiParts.button(skin, variation, text)
	made.name = node_name
	made.pressed.connect(chosen.emit)
	return made


## A spacer that takes ratio shares of the free height.
func _spacer(ratio: float) -> Control:
	var gap: Control = Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.size_flags_stretch_ratio = ratio
	return gap


func _margins(parent: Node, side: float) -> MarginContainer:
	var box: MarginContainer = MarginContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"margin_left", roundi(side))
	box.add_theme_constant_override(&"margin_right", roundi(side))
	parent.add_child(box)
	return box


## Nothing in the brand block takes input.
static func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_ignore_mouse(child)
