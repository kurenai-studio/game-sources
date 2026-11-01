class_name GameScreen extends Control
## The play screen (docs/ARCHITECTURE.md section 11, DESIGN_SYSTEM.md 2.3 and
## 7.1). Top to bottom inside the safe area and the content column (2.8): the
## HUD, space_s, the board, space_s, the booster bar. The backdrop fills the
## whole screen. The board takes the widest size inside board_margin whose
## preferred height fits between the HUD and the bar, centered in the column;
## if it does not fit it shrinks evenly and stays centered.
##
## While the no moves offer is open, OfferPanel takes the HUD's place and the
## board shrinks to fit under it; the board and the bar stay usable (7.5).
##
## It mirrors the session into the components: scores into the HUD (counting
## up when a chain adds points), statuses into the bar and the offer, the
## targeting hint into the bar (Gumdrop, Nova) and the HUD context row
## (Slate), the chain into the context row and preview slot (Slate), and the
## clear notice (AT-104, D-45). Every color, size and timing comes from the
## skin.
##
## A move shows only once its save has landed (QA6-06, GDD 15.1). While the
## board holds a move at its show gate, the HUD score, the booster bar, the
## offer and the clear notice stay as they were at the lift; the newest
## status and the newest move's notice show at the board's next
## move_started. A held move that a newer one replaces gets no move_started of
## its own, so this keeps only the latest, never a count.
##
## The Buy me a coffee button (DESIGN_SYSTEM.md 7.15, GDD 15.5) sits in room
## nothing else uses: below the board, in its one line form, when the space
## between the board and the bar holds touch_min plus space_s each side,
## else in the left gutter beside the column, in its stacked form, when the
## gutter leaves space_m clear on both sides of its touch area, else nowhere.
## It never moves or shrinks anything else. It is hidden
## while the offer, targeting or any App panel over this screen (Pause and
## what opens from it, the new game confirmation, the end of run screen) is
## open. It reacts only to a touch that went down and came up on it: Godot
## sends a release to the control that took the press, and the board reads
## real touches, so a drag from the board or a second finger never reaches it.

signal pause_requested()

const BOARD_SCENE: PackedScene = preload("res://scenes/board/board.tscn")
const OFFER_SCENE: PackedScene = preload("res://scenes/ui/offer_panel.tscn")
const Copy: GDScript = preload("res://src/ui/screen_copy.gd")
const CoffeeButton: GDScript = preload("res://src/ui/coffee_button.gd")

## Where the coffee button goes (7.15).
enum CoffeePlace { NONE, BELOW_BOARD, GUTTER }

const _NO_CELL: Vector2i = Vector2i(-1, -1)

var _session: GameSession = null
var _settings: Settings = null
var _audio: AudioService = null
var _skin: SkinData = null
var _backdrop: SkinBackdrop = null
var _board: BoardController = null
var _hud: SkinHud = null
var _bar: SkinBoosterBar = null
var _offer: OfferPanel = null
## QA6-04, DESIGN_SYSTEM.md 7.1: the clear notice and the flying stars draw
## here, above the board and the offer panel and below every dialog (the
## App's panels sit above the whole screen), so they show while the offer
## hides the HUD.
var _notice_layer: Control = null
var _preview: SkinTileView = null
var _chain_context: String = ""
var _chain_preview: int = 0
var _shown_score: BigNum = null    # null until a score is shown
## True from a chain's move_resolved to the status_changed that follows it.
var _chain_points_pending: bool = false
## A status_changed came while the board held a move at the gate.
var _status_held: bool = false
## The newest move whose clear notice waits for the board's move_started.
var _notice_held: MoveResult = null
## What the HUD, the bar and the offer show now, for a rebuild while a move
## is held: score, Best Score, booster statuses.
var _shown_best: BigNum = BigNum.zero()
var _shown_statuses: Array[BoosterStatus] = []
var _shown_stars: int = 0
var _shown_free: int = 0
## The Buy me a coffee button (7.15), just above the backdrop, so it is under
## the board, HUD, bar, offer and notice layer (it overlaps none of them).
var _coffee: Control = null
## Where the last layout put it.
var _coffee_place: CoffeePlace = CoffeePlace.NONE
## An App panel covers this screen (set_covered).
var _covered: bool = false
## The button shows, or fades in: placed and nothing hides it.
var _coffee_shown: bool = false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Builds the screen for session in skin. Call it with the screen in the tree.
func setup(session: GameSession, settings: Settings, audio: AudioService, skin: SkinData) -> void:
	_session = session
	_settings = settings
	_audio = audio
	_skin = skin
	_board = BOARD_SCENE.instantiate() as BoardController
	_board.name = "Board"
	# The board scene fills its parent; here _layout places it by hand.
	_board.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(_board)
	_board.setup(session, skin, audio)
	_board.chain_changed.connect(_on_chain_changed)
	_board.move_started.connect(_on_move_started)
	_offer = OFFER_SCENE.instantiate() as OfferPanel
	_offer.name = "Offer"
	_offer.visible = false
	add_child(_offer)
	_offer.booster_chosen.connect(_on_booster_pressed)
	_offer.end_run_chosen.connect(_on_end_run)
	_offer.minimum_size_changed.connect(_layout)
	_coffee = CoffeeButton.new()
	_coffee.visible = false
	_coffee.modulate.a = 0.0
	_coffee.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_coffee)
	# Its label measures once its theme reaches it: place it again then.
	_coffee.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	_notice_layer = Control.new()
	_notice_layer.name = "NoticeLayer"
	_notice_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_notice_layer)
	session.status_changed.connect(_on_status_changed)
	session.targeting_changed.connect(_on_targeting_changed)
	session.offer_changed.connect(_on_offer_changed)
	session.move_resolved.connect(_on_move_resolved)
	session.run_started.connect(_on_run_started)
	_build_skinned(skin)
	_refresh()


## Live skin switch: a new backdrop, HUD and booster bar, the board's new
## view and the offer in the new look. The board keeps its state.
func apply_skin(skin: SkinData) -> void:
	_skin = skin
	_board.set_skin(skin)
	_build_skinned(skin)
	_refresh()


func board() -> BoardController:
	return _board


## The HUD in use. For tests and the App.
func hud() -> SkinHud:
	return _hud


## The booster bar in use. For tests.
func booster_bar() -> SkinBoosterBar:
	return _bar


## The offer panel; visible while the offer is open. For tests.
func offer_panel() -> OfferPanel:
	return _offer


## The score last given to the HUD (its final value, before any count up),
## or null before the first.
## For tests.
func shown_score() -> BigNum:
	return _shown_score


## The booster statuses last given to the bar and the offer. For tests.
func shown_statuses() -> Array[BoosterStatus]:
	return _shown_statuses


## The notice layer, above the board and the offer. For tests.
func notice_layer() -> Control:
	return _notice_layer


## The Buy me a coffee button. For tests.
func coffee_button() -> Control:
	return _coffee


## Where the last layout placed the coffee button. For tests.
func coffee_place() -> CoffeePlace:
	return _coffee_place


## True while the coffee button shows (or fades in) and takes taps.
func is_coffee_shown() -> bool:
	return _coffee_shown


## The App sets this while any of its panels is open over the play screen
## (Pause and what opens from it, the new game confirmation, the end of run
## screen): the coffee button hides until they all close.
func set_covered(covered: bool) -> void:
	_covered = covered
	_update_coffee()


func _build_skinned(skin: SkinData) -> void:
	for old: Control in [_backdrop, _hud, _bar]:
		if old != null:
			remove_child(old)
			old.queue_free()
	_preview = null
	_backdrop = UiKit.make_backdrop(skin)
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)
	move_child(_backdrop, 0)
	_coffee.call(&"setup", skin)
	_coffee.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	move_child(_coffee, 1)
	_hud = UiKit.make_hud(skin)
	_hud.name = "Hud"
	add_child(_hud)
	_hud.pause_pressed.connect(_on_pause_pressed)
	var slot: Control = _hud.preview_slot()
	if slot != null:
		_preview = SkinCatalog.make_tile_view(skin)
		_preview.name = "Preview"
		_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_preview.visible = false
		slot.add_child(_preview)
	_bar = UiKit.make_booster_bar(skin)
	_bar.name = "BoosterBar"
	add_child(_bar)
	_bar.booster_pressed.connect(_on_booster_pressed)
	move_child(_offer, get_child_count() - 1)
	move_child(_notice_layer, get_child_count() - 1)
	_offer.setup(skin)
	_hud.set_notice_layer(_notice_layer)
	_hud.set_stars(_shown_stars, _shown_free)
	_shown_score = null
	_layout()


## Re-reads everything from the session, or, while the board holds a move at
## its gate, shows again what was shown at the lift.
func _refresh() -> void:
	if _held() and _shown_score != null:
		_present(_shown_score, _shown_best, _shown_statuses, _shown_stars, _shown_free, false)
	else:
		_show_status(false)
	_set_offer_open(_session.is_offer_open())
	_show_context()


## True while the board holds a move at its show gate (TH23).
func _held() -> bool:
	return _board != null and _board.is_waiting_for_save()


## Shows the session's status now. Clears a held status: this is the newest.
func _show_status(count: bool) -> void:
	if _session == null or _hud == null:
		return
	_status_held = false
	_present(_session.state.score, _session.records.best_score, _session.booster_statuses(), _session.stars(), _session.free_held(), count)


## Shows a status: the scores and the star counter in the HUD (D-45, D-46),
## the statuses in the bar and the offer.
func _present(score: BigNum, best_score: BigNum, statuses: Array[BoosterStatus], stars: int, free_held: int, count: bool) -> void:
	_hud.set_scores(score, best_score)
	_hud.set_stars(stars, free_held)
	_shown_stars = stars
	_shown_free = free_held
	# Count up only for the points a chain just added. Any other change shows
	# at once; that call also replaces a count still running, so a stale count
	# can never overwrite the score.
	var from: BigNum = score
	if count and _chain_points_pending and _shown_score != null and score.compare(_shown_score) > 0:
		from = _shown_score
	_chain_points_pending = false
	if is_inside_tree():
		Motion.count_up(_hud.score_label(), _skin, from, score)
	_shown_score = score
	_shown_best = best_score
	_shown_statuses = statuses
	_bar.show_boosters(statuses)
	if _offer.visible or _session.is_offer_open():
		_offer.show_offer(statuses, score)


func _set_offer_open(is_open: bool) -> void:
	if is_open:
		if _shown_score != null:
			_offer.show_offer(_shown_statuses, _shown_score)
		else:
			_offer.show_offer(_session.booster_statuses(), _session.state.score)
	_offer.visible = is_open
	_hud.visible = not is_open
	_layout()
	_update_coffee()


## The targeting hint goes to the bar (Gumdrop, Nova) and the HUD context row
## (Slate); each skin shows it in one place. Otherwise the context row shows
## the chain, with the preview tile, while one is dragged.
func _show_context() -> void:
	if _session == null or _hud == null:
		return
	var booster_id: StringName = _session.targeting_booster()
	if booster_id != &"":
		var chosen: bool = _session.swap_first() != _NO_CELL
		_bar.set_hint(Copy.hint(booster_id, chosen))
		_hud.set_context(Copy.targeting_context(booster_id, chosen), true)
		if _preview != null:
			_preview.visible = false
		return
	_bar.set_hint("")
	_hud.set_context(_chain_context, false)
	if _preview != null:
		_preview.visible = _chain_preview > 0
		_preview.set_value(_chain_preview)


func _on_status_changed() -> void:
	if _held():
		_status_held = true
		return
	_show_status(true)


func _on_targeting_changed(_booster_id: StringName, _swap_first: Vector2i) -> void:
	_show_context()
	_update_coffee()


## Comes from move_shown(), once the move has been shown: never held.
func _on_offer_changed(is_open: bool, _suggested: StringName) -> void:
	_set_offer_open(is_open)
	_show_status(false)


func _on_run_started(_result: MoveResult) -> void:
	_chain_context = ""
	_chain_preview = 0
	_notice_held = null
	_show_context()
	if _held():
		_status_held = true
		return
	_shown_score = null
	_show_status(false)


## The clear notice (AT-104, D-45) shows when the move earned a star or
## cleared small tiles, naming every value that left the spawn window. It
## waits with the move at the board's gate.
func _on_move_resolved(result: MoveResult) -> void:
	_chain_points_pending = result.kind == MoveResult.Kind.CHAIN
	if _held():
		_notice_held = result
		return
	_show_notice(result)


## The board's gate opened and the move's effects begin: show what was held,
## the notice first so its star leaves before the counter takes the count.
func _on_move_started() -> void:
	var result: MoveResult = _notice_held
	_notice_held = null
	if result != null:
		_show_notice(result)
	if _status_held:
		_show_status(true)


## GDD 11.5: a move shows the notice when it earned a star or cleared small
## tiles (a floor that rose with neither shows none, ARCHITECTURE.md
## section 4).
static func wants_notice(result: MoveResult) -> bool:
	return result != null and (result.stars_earned > 0 or not result.cleared_small.is_empty())


## Flow 4: the notice with the values that left the window and the stars the
## move earned, then the counter with the session's new count, which the
## star moment lands on (DESIGN_SYSTEM.md 3.6).
func _show_notice(result: MoveResult) -> void:
	if not wants_notice(result):
		return
	_hud.show_clear_notice(result.notice_values, _board_rect(), result.stars_earned)
	_hud.set_stars(_session.stars(), _session.free_held())


## The board's rect in global coordinates (the HUD places the notice by it).
func _board_rect() -> Rect2:
	if _board.is_inside_tree():
		return _board.get_global_rect()
	return Rect2(_board.position, _board.size)


func _on_chain_changed(chain: Array[Vector2i], preview_value: int) -> void:
	_chain_preview = preview_value
	_chain_context = Copy.chain(chain.size()) if preview_value > 0 else ""
	_show_context()


func _on_booster_pressed(booster_id: StringName) -> void:
	_session.press_booster(booster_id)


func _on_end_run() -> void:
	_session.end_run()


func _on_pause_pressed() -> void:
	pause_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_ENTER_TREE:
		_layout()


func _layout() -> void:
	if _skin == null or _hud == null or not is_inside_tree():
		return
	var screen: Rect2 = get_global_rect()
	var safe: Rect2 = SafeArea.viewport_safe_rect(get_viewport())
	layout_in(screen, SafeArea.column_in(safe, _skin), safe)


## Keeps the backdrop's decoration off the bar, the HUD (or the offer) and
## the coffee button's touch area while it shows.
func _update_clear_rects() -> void:
	if _backdrop == null or _bar == null or not is_inside_tree():
		return
	var clear: Array[Rect2] = [_bar.get_global_rect()]
	clear.append(_offer.get_global_rect() if _offer.visible else _hud.get_global_rect())
	if _coffee_shown:
		var reach: float = _skin.num(&"space_s")
		clear.append(_coffee.get_global_rect().grow_individual(reach, 0.0, reach, 0.0))
	_backdrop.set_clear_rects(clear)


## Lays the screen out for its own rect, the content column and the safe
## area, all in the same (global) coordinates: the HUD, the offer and the bar
## in the column, the board centered in it, then the coffee button where
## there is room (7.15). An empty safe rect counts as the column (no gutter).
## _layout calls it; tests call it with rects of their own, since headless
## tests never enter the scene tree.
func layout_in(screen: Rect2, column: Rect2, safe: Rect2 = Rect2()) -> void:
	if _skin == null or _hud == null:
		return
	if safe.size.x <= 0.0 or safe.size.y <= 0.0:
		safe = column
	var inner: Rect2 = Rect2(column.position - screen.position, column.size)
	var margin: float = _skin.num(&"board_margin")
	var gap: float = _skin.num(&"space_s")

	var top: float = inner.position.y
	if _offer.visible:
		_offer.position = Vector2(inner.position.x + margin, inner.position.y)
		_offer.fit_width(inner.size.x - margin * 2.0)
		_offer.size = Vector2(inner.size.x - margin * 2.0, 0.0)
		top = inner.position.y + _offer.get_combined_minimum_size().y
	var hud_height: float = _hud.preferred_height()
	_hud.position = inner.position
	_hud.size = Vector2(inner.size.x, hud_height)
	if not _offer.visible:
		top = inner.position.y + hud_height

	var bar_height: float = _bar.preferred_height()
	_bar.position = Vector2(inner.position.x, inner.end.y - bar_height)
	_bar.size = Vector2(inner.size.x, bar_height)

	var region_top: float = top + gap
	var region_height: float = maxf(0.0, _bar.position.y - gap - region_top)
	var width: float = maxf(0.0, inner.size.x - margin * 2.0)
	var height: float = _board.preferred_height(width)
	if height > region_height and height > 0.0:
		width = _width_for_height(width, region_height)
		height = _board.preferred_height(width)
	_board.position = Vector2(inner.position.x + (inner.size.x - width) * 0.5, region_top + maxf(0.0, region_height - height) * 0.5)
	_board.size = Vector2(width, height)
	_place_coffee(inner, safe.position.x - screen.position.x)
	_update_coffee()
	_update_clear_rects()


## DESIGN_SYSTEM.md 7.15, from the rects just placed. The touch area reaches
## space_s past the button's content on each side (coffee_button.gd).
## 1. Below the board when the space D from the board's bottom to the bar's
##    top is at least touch_min plus 2 x space_s: centered in the column and
##    vertically in D, so the gaps to the board and the bar are equal and at
##    least space_s each.
##    The button takes its one line form.
## 2. Else in the left gutter (the safe area's left edge to the column's), in
##    the stacked form, when the gutter is at least the stacked content
##    width plus 2 x space_s plus 2 x space_m, so the touch area is at least
##    space_m clear of the safe edge and of the column: centered in the
##    gutter and on the bar.
## 3. Else nowhere, the form left as it was. With the offer open this is not
##    the plain play screen, so nowhere either (the button is hidden then
##    anyway).
## The form follows the place at every layout, so a fold or unfold moves it
## between the two. Setting the form it already has does nothing.
func _place_coffee(inner: Rect2, safe_left: float) -> void:
	_coffee_place = CoffeePlace.NONE
	if _offer.visible:
		return
	var gap: float = _skin.num(&"space_s")
	var clear: float = _skin.num(&"space_m")
	var line_size: Vector2 = _coffee.call(&"size_for", false)
	var stacked_size: Vector2 = _coffee.call(&"size_for", true)
	var board_bottom: float = _board.position.y + _board.size.y
	var below: float = _bar.position.y - board_bottom
	var gutter: float = inner.position.x - safe_left
	if below >= line_size.y + 2.0 * gap:
		_coffee_place = CoffeePlace.BELOW_BOARD
		_coffee.call(&"set_stacked", false)
		var button_size: Vector2 = _coffee.call(&"content_size")
		_coffee.size = button_size
		_coffee.position = Vector2(inner.position.x + (inner.size.x - button_size.x) * 0.5, board_bottom + (below - button_size.y) * 0.5)
	elif gutter >= stacked_size.x + 2.0 * gap + 2.0 * clear:
		_coffee_place = CoffeePlace.GUTTER
		_coffee.call(&"set_stacked", true)
		var button_size: Vector2 = _coffee.call(&"content_size")
		_coffee.size = button_size
		_coffee.position = Vector2(safe_left + (gutter - button_size.x) * 0.5, _bar.position.y + (_bar.size.y - button_size.y) * 0.5)


## Shows the coffee button when it has a place and nothing hides it, else
## hides it. Inside the tree it fades on screen_fade. On hiding it ignores
## touches at once and drops a press already on it, so no release counts.
func _update_coffee() -> void:
	if _coffee == null or _offer == null:
		return
	var targeting: bool = _session != null and _session.targeting_booster() != &""
	var wanted: bool = _coffee_place != CoffeePlace.NONE and not _covered and not _offer.visible and not targeting
	if wanted == _coffee_shown:
		return
	_coffee_shown = wanted
	var animate: bool = is_inside_tree() and _skin != null
	if wanted:
		_coffee.visible = true
		_coffee.mouse_filter = Control.MOUSE_FILTER_PASS
		if animate:
			_coffee.modulate.a = 0.0
			Motion.fade(_coffee, _skin, 1.0)
		else:
			_coffee.modulate.a = 1.0
	else:
		_coffee.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_coffee.call(&"cancel_hold")
		if animate and _coffee.visible:
			Motion.fade(_coffee, _skin, 0.0).finished.connect(_end_coffee_fade)
		else:
			_coffee.visible = false
			_coffee.modulate.a = 0.0
	_update_clear_rects()


func _end_coffee_fade() -> void:
	if not _coffee_shown:
		_coffee.visible = false


## The board width whose preferred height is height, at most width. A board's
## preferred height is linear in its width, so two samples give it exactly.
func _width_for_height(width: float, height: float) -> float:
	if width <= 0.0:
		return 0.0
	var half: float = width * 0.5
	var at_width: float = _board.preferred_height(width)
	var at_half: float = _board.preferred_height(half)
	var slope: float = (at_width - at_half) / (width - half)
	if slope <= 0.0:
		return 0.0
	return clampf(half + (height - at_half) / slope, 0.0, width)
