# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name BattleScreen
extends ScreenFrame
## The battle: the map, the HUD, the panels and the touch input (docs/ARCHITECTURE.md
## 3.2, 3.6, 7.5). This is the only place that steps the sim and drains its events.
##
## Portrait: the HUD above the map and the map under it, top aligned, as big as the
## width allows. Nothing else takes height from the map, so cells stay 48 dp on the
## Fold5 cover whatever is showing. The gate strip is a small chip in the HUD's first
## row. The Paused strip, the messages and the wave preview form a dock that floats over
## the lower edge of the map, in the free room under it, and covers the lowest rows only
## on a tall map or a Paused strip. The wave preview opens in a build phase only when its
## open form fits under the map, and starts folded into its one line strip otherwise. The
## hint sits at the top of the dock when it still fits under the map, else it floats over
## a band of map rows with nothing in it to see or tap (docs/ARCHITECTURE.md 7.4). Each of
## these can be put away with one tap. The tower, build and creature panels are a bottom
## sheet over the lower map. The sheet never covers the HUD, and the map slides up so
## the tapped cell stays in sight. Landscape: the map on the left and one side column
## with the HUD, the open panel and the preview.
##
## Taps on a spot open the build or tower panel, a tap on a creature opens its
## numbers, and a tap on a gate socket places or takes back a gate. A gate can also be
## dragged (from the strip or from a socket) with the route lines showing the result,
## and a drop that would close every road is refused with the crossed out gate.
##
## A run or daily (set_run) adds the card draft. It opens by itself whenever the run owes a
## card in a build phase, as a sheet like the build panel, and only taking a card closes it:
## taps on the map do nothing while it is open and the back button opens Pause. A waiting risk
## card shows first in the wave preview. A Twist shows its rule as the first hint and in Pause.

## The game should be saved: a build phase began, a wave started or was called early, a card
## was picked, or the game was paused.
signal save_requested()
## Progress changed (a first sight was recorded).
signal progress_changed()
## The level was won, lost or abandoned. `result` is Battle.result() plus
## "abandoned", "relaxed" and "twist".
signal ended(result: Dictionary)
## Restart in Pause, after its question. The App ends this game and starts it again.
signal restart_confirmed()
## "Back to menu" in Pause. The game stays saved.
signal left()
## The player used the sound button in the HUD. `on` is what the sound should be now.
signal sound_changed(on: bool)
## Pause asked for the Info screen. The App opens it.
signal info_requested()
## Pause asked for Settings. The App opens it.
signal settings_requested()
## A modal to show above everything. With nothing connected (a lone screen in a test), the
## screen keeps the modal itself.
signal modal_requested(modal: Modal)

const NO_CELL: Vector2i = Vector2i(-1, -1)
## The landscape side column is always this wide. The HUD needs 728 px (its second row, plus
## the margins) and a scroll bar takes 28 more, so a narrower column would clip the HUD. A
## fixed width also means the map never changes size or place when a panel opens.
const SIDE_WIDTH: float = 760.0
## Panels keep this far from the screen edge. The map itself runs edge to edge.
const EDGE: float = 16.0
const GAP: float = 12.0
## A dragged gate snaps to a socket this close, in cells.
const SNAP_CELLS: float = 0.6
## The carried gate floats this far above the finger, in cells.
const GHOST_LIFT: float = 0.8
const PAN_RATE: float = 14.0
## Inner margin of the dock panels in portrait.
const DOCK_MARGIN: int = 14
## Frames the preview stays open and unseen before the screen measures it. The map, the HUD
## and the preview itself settle in that time.
const FIT_FRAMES: int = 3

var battle: Battle = null
var audio: AudioService = null
var progress: Progress = null
## Debug builds only: times every tick.
var probe: PerfProbe = null
var clock: BattleClock = BattleClock.new()
## False for a game with no stars (a run). A Twist has none either, which the screen sees
## in the battle itself. Star lines in Pause and the star warnings need this to be true.
var stars_in_play: bool = true

var map_area: Control
var map_view: MapView
var hud: BattleHud
var gate_tray: GateTray
var pause_strip: PauseStrip
var hint_banner: HintBanner
var preview: WavePreview
var build_panel: BuildPanel
var tower_panel: TowerPanel
var enemy_panel: EnemyPanel
var draft_panel: DraftPanel
var ghost: GateGhost
## The run or daily around the battle, or null in a campaign level (set_run).
var run: RunSession = null

var _stage: Control
var _flow: BoxContainer
var _top_wrap: MarginContainer
var _top_box: VBoxContainer
var _dock_wrap: MarginContainer
var _dock: VBoxContainer
## Over the map, above the dock: where the hint floats in portrait.
var _hint_layer: Control
## Holds `_side` and sets the column's width. It is a plain Control, so what the column shows
## can never make it wider: a ScrollContainer adds its scroll bar to its content's width,
## which used to widen the column and shrink the map whenever a tall panel opened.
var _side_slot: Control
var _side: ScrollContainer
var _side_wrap: MarginContainer
var _side_box: VBoxContainer
var _sheet: VBoxContainer
var _sheet_scroll: ScrollContainer
var _arranged: int = -1

var _context: BattlePanel = null
var _selected: Vector2i = NO_CELL
var _hint_cell: Vector2i = NO_CELL
var _pause_panel: PausePanel = null
var _card: InfoCard = null
var _modals: Array[Modal] = []
## Closed modals of a screen that is not in a scene tree; freed with the screen.
var _modals_gone: Array[Modal] = []
var _twist_hint_shown: bool = false
var _routes_sig: Array = []
var _finished: bool = false
## Creatures whose card the player closed in this build phase. They keep their "New"
## tag until the wave that brings them starts.
var _fresh: Array[StringName] = []
var _fresh_wave: int = -1
var _new_sig: Array = []
## True while a card paused a running wave, so closing it lets the wave go on.
var _card_froze: bool = false
var _card_resized: bool = false
## Frames left before the open preview is measured against the room under the map. 0: none.
var _fit_wait: int = 0
## Map rows that hold something to see or tap, for the hint's free band. Worked out once.
var _busy_rows: PackedByteArray = PackedByteArray()

var _pressing: bool = false
var _press_at: Vector2 = Vector2.ZERO
var _travel: float = 0.0
var _press_cell: Vector2i = NO_CELL
var _drag_active: bool = false
var _drag_from: Vector2i = NO_CELL
var _drag_target: Vector2i = NO_CELL
var _drag_sig: Array = []

var _map_base: Vector2 = Vector2.ZERO
var _pan: float = 0.0
var _pan_target: float = 0.0


func _init() -> void:
	super()
	pad = 0.0
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_flow = BoxContainer.new()
	_flow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow.add_theme_constant_override(&"separation", 0)
	_stage.add_child(_flow)
	_build_map()
	_build_panels()
	_build_containers()
	_stage.add_child(_dock_wrap)
	_hint_layer = Control.new()
	_hint_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hint_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_hint_layer)
	_sheet = VBoxContainer.new()
	_sheet.alignment = BoxContainer.ALIGNMENT_END
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.visible = false
	var sheet_margin: MarginContainer = _wrap(_sheet, 0.0, GAP)
	sheet_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(sheet_margin)
	_sheet_scroll = ScrollContainer.new()
	_sheet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sheet_scroll.scroll_deadzone = int(TapButton.DEADZONE)
	_sheet_scroll.size_flags_horizontal = Control.SIZE_FILL
	_sheet_scroll.size_flags_vertical = Control.SIZE_SHRINK_END
	_sheet_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_sheet.add_child(_sheet_scroll)
	ghost = GateGhost.new()
	_stage.add_child(ghost)
	_connect_panels()


func _build_map() -> void:
	map_area = Control.new()
	map_area.mouse_filter = Control.MOUSE_FILTER_STOP
	map_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_area.custom_minimum_size = Vector2(Layout.MIN_TOUCH, Layout.MIN_TOUCH)
	map_area.gui_input.connect(_on_map_input)
	map_area.resized.connect(_fit_map)
	map_view = MapView.new()
	# Behind every panel and modal, in front of the backdrop (which is at -10), so a
	# panel covers the thickets that reach past the map edge. The map's own layers
	# sit between -4 and -1.
	map_view.z_index = -5
	map_area.add_child(map_view)


func _build_panels() -> void:
	hud = BattleHud.new()
	gate_tray = GateTray.new()
	pause_strip = PauseStrip.new()
	hint_banner = HintBanner.new()
	preview = WavePreview.new()
	build_panel = BuildPanel.new()
	tower_panel = TowerPanel.new()
	enemy_panel = EnemyPanel.new()
	draft_panel = DraftPanel.new()
	for panel: BattlePanel in [build_panel, tower_panel, enemy_panel, draft_panel]:
		panel.visible = false


func _build_containers() -> void:
	_top_box = VBoxContainer.new()
	_top_box.add_theme_constant_override(&"separation", GAP)
	_top_wrap = _wrap(_top_box, 6.0, 6.0)
	_dock = VBoxContainer.new()
	_dock.alignment = BoxContainer.ALIGNMENT_END
	_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dock.add_theme_constant_override(&"separation", GAP)
	_dock_wrap = _wrap(_dock, 0.0, GAP)
	_dock_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_side_box = VBoxContainer.new()
	_side_box.add_theme_constant_override(&"separation", GAP)
	_side_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side_wrap = _wrap(_side_box, GAP, GAP)
	_side_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side = ScrollContainer.new()
	_side.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_side.scroll_deadzone = int(TapButton.DEADZONE)
	_side.set_anchors_preset(Control.PRESET_FULL_RECT)
	_side.add_child(_side_wrap)
	_side_slot = Control.new()
	_side_slot.custom_minimum_size.x = SIDE_WIDTH
	_side_slot.add_child(_side)


func _wrap(inner: Control, top: float, bottom: float) -> MarginContainer:
	var wrap: MarginContainer = MarginContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_theme_constant_override(&"margin_left", roundi(EDGE))
	wrap.add_theme_constant_override(&"margin_right", roundi(EDGE))
	wrap.add_theme_constant_override(&"margin_top", roundi(top))
	wrap.add_theme_constant_override(&"margin_bottom", roundi(bottom))
	wrap.add_child(inner)
	return wrap


func _connect_panels() -> void:
	hud.speed_selected.connect(func(speed: int) -> void: clock.speed = speed)
	hud.pause_requested.connect(freeze)
	hud.sound_selected.connect(func(on: bool) -> void: sound_changed.emit(on))
	hud.resume_requested.connect(resume)
	hud.wave_started.connect(func() -> void: save_requested.emit())
	pause_strip.menu_requested.connect(_on_strip_menu)
	hint_banner.closed.connect(_on_hint_closed)
	preview.build_began.connect(_start_fit)
	for panel: BattlePanel in [hud, gate_tray, build_panel, tower_panel, draft_panel]:
		panel.refused.connect(_on_refused)
	build_panel.range_changed.connect(_on_range_changed)
	tower_panel.range_changed.connect(_on_range_changed)
	build_panel.built.connect(_on_built)
	for panel: BattlePanel in [build_panel, tower_panel, enemy_panel, draft_panel]:
		panel.closed.connect(_on_panel_closed.bind(panel))
	draft_panel.picked.connect(_on_draft_picked)
	enemy_panel.gone.connect(func(_id: int) -> void: enemy_panel.close())
	gate_tray.drag_began.connect(_on_tray_drag_began)
	gate_tray.drag_moved.connect(move_drag)
	gate_tray.drag_ended.connect(end_drag)


## Gives the screen its battle. Call once, before the screen is shown. `region` is the campaign
## region that holds the level, which picks the map's ground (docs/ARCHITECTURE.md 14.10). A run
## or daily passes &"", and its ground comes from the map's own features.
func setup(new_battle: Battle, new_audio: AudioService, new_progress: Progress, region: StringName = &"lantern_hill") -> void:
	battle = new_battle
	audio = new_audio
	progress = new_progress
	map_view.setup(battle, region)
	hud.refresh(battle)
	hud.set_speed(clock.speed)
	_sync_warnings()
	for panel: BattlePanel in [gate_tray, preview, build_panel, tower_panel, enemy_panel, draft_panel]:
		panel.setup(battle)
	_refresh_new_tags()
	if probe != null:
		probe.watch(battle, map_view)
	_fit_map()
	_check_sights()


## Makes this screen a run or a daily around `new_run` (docs/ARCHITECTURE.md 3.6). Call it after
## setup(). The run has no stars. The cards' names and texts come from the run itself.
func set_run(new_run: RunSession) -> void:
	run = new_run
	stars_in_play = false
	hud.run = run
	hud.refresh()
	_sync_warnings()
	_sync_risk()
	_sync_draft()


# The clock.

func is_paused() -> bool:
	return clock.paused


## True when a wave is on and the Pause menu is not up yet: the clock is running, or only
## the HUD's Paused strip holds it. A fold, a focus loss or a leave then calls pause(), so
## the Pause menu opens on every path (docs/ARCHITECTURE.md 7.5). A first sight card that
## froze the wave is not counted: it opens the menu itself when it closes.
func needs_pause_menu() -> bool:
	if battle == null or battle.phase != Battle.Phase.WAVE or _pause_panel != null:
		return false
	return not clock.paused or pause_strip.visible


## The app is being left (focus lost, home, a close). Opens the Pause menu when a wave needs
## it and returns true: the menu's save request has then saved the game. A first sight card
## that froze the wave opens the menu when it closes, as after a resize. Returns false when
## the caller still has to save.
func pause_for_leave() -> bool:
	if _card_froze:
		_card_resized = true
		return false
	if not needs_pause_menu():
		return false
	pause()
	return true


## Freezes the clock and opens the Pause menu.
func pause() -> void:
	if _pause_panel != null:
		return
	_freeze_clock()
	save_requested.emit()
	_open_pause_menu()


## The HUD's pause button: freezes the clock and keeps the game open to build and look.
func freeze() -> void:
	_freeze_clock()
	pause_strip.visible = _pause_panel == null
	save_requested.emit()


func resume() -> void:
	clock.paused = false
	hud.set_paused(false)
	pause_strip.visible = false


func _freeze_clock() -> void:
	clock.paused = true
	hud.set_paused(true)
	if _drag_active:
		cancel_drag()


## The Paused strip's Menu button: whatever was built, upgraded or sold while frozen is
## saved first, as for the pause button and the back button.
func _on_strip_menu() -> void:
	save_requested.emit()
	_open_pause_menu()


func _open_pause_menu() -> void:
	if _pause_panel != null:
		return
	pause_strip.visible = false
	_pause_panel = PausePanel.new()
	_pause_panel.set_stars(star_entries())
	if not battle.twist_effects.is_empty():
		_pause_panel.set_twist(battle.level.twist_name, battle.level.twist_text)
	_pause_panel.resume_requested.connect(resume)
	_pause_panel.info_requested.connect(_open_info)
	_pause_panel.settings_requested.connect(_open_settings)
	_pause_panel.leave_requested.connect(_on_leave)
	_pause_panel.abandon_confirmed.connect(_on_abandon)
	_pause_panel.restart_confirmed.connect(_on_restart)
	_pause_panel.set_restart_text(restart_text())
	_pause_panel.closed.connect(_on_pause_closed)
	_open_modal(_pause_panel)


func _on_pause_closed() -> void:
	_pause_panel = null


func _open_info() -> void:
	info_requested.emit()


func _open_settings() -> void:
	settings_requested.emit()


func _on_leave() -> void:
	left.emit()


func _on_abandon() -> void:
	if _finished:
		return
	_finished = true
	var result: Dictionary = battle.result()
	result["abandoned"] = true
	result["relaxed"] = battle.relaxed
	result["twist"] = not battle.twist_effects.is_empty()
	ended.emit(result)


## Restart was confirmed. This game is over for the screen: nothing more ends from it. The
## App records what the rules say and starts the same game again.
func _on_restart() -> void:
	if _finished:
		return
	_finished = true
	restart_confirmed.emit()


## What the Restart question says happens (RULES 4.10, 14.7): a level or Twist records
## nothing, a run or daily counts as lost on its current wave.
func restart_text() -> String:
	if run == null:
		if battle.twist_effects.is_empty():
			return PausePanel.RESTART_LEVEL
		return "This Twist starts over from the beginning, on the same difficulty. Nothing from this game is recorded."
	if run.daily:
		return "This daily counts as lost on its current wave. Then the same day's daily starts again."
	return "This run counts as lost on its current wave. Then a new run starts, on the same difficulty."


## Shows the sound switch (sound effects and music together) on the HUD's sound button.
func set_sound_state(sound_on: bool) -> void:
	hud.set_sound(sound_on)


## True while the Pause menu is open.
func pause_menu_open() -> bool:
	return _pause_panel != null


## True while a first sight card is open.
func card_open() -> bool:
	return _card != null


# Modals.

func _open_modal(modal: Modal) -> void:
	if not modal_requested.get_connections().is_empty():
		modal_requested.emit(modal)
		return
	_modals.append(modal)
	add_child(modal)
	modal.closed.connect(_own_modal_closed.bind(modal))
	modal.apply_layout(window_size, safe)


func _own_modal_closed(modal: Modal) -> void:
	_modals.erase(modal)
	remove_child(modal)
	if is_inside_tree():
		modal.queue_free()
	else:
		_modals_gone.append(modal)


# Layout.

## From ScreenFrame. A size change during a wave pauses first (docs/ARCHITECTURE.md 7.5).
func apply_layout(new_window_size: Vector2, new_safe: Rect2) -> void:
	var resized: bool = window_size != Vector2.ZERO and not window_size.is_equal_approx(new_window_size)
	if resized and _card_froze:
		# A first sight card froze the wave. The wave pauses on the menu when the card closes.
		_card_resized = true
	if resized and needs_pause_menu():
		pause()
	cancel_drag()
	super.apply_layout(new_window_size, new_safe)


func _relayout() -> void:
	_arrange()
	var wide: bool = not landscape
	for panel: BattlePanel in [hud, gate_tray, pause_strip, hint_banner, preview, build_panel, tower_panel, enemy_panel, draft_panel]:
		panel.set_wide(wide)
	if not landscape:
		for panel: BattlePanel in [pause_strip, hint_banner, preview]:
			panel.set_tight(true, DOCK_MARGIN)
	gate_tray.set_chip(not landscape)
	_place_context()
	_sheet.visible = _context != null and not landscape
	_sync_dock()
	_fit_map.call_deferred()
	if landscape:
		# In landscape the preview is always open in a build phase (RULES 9.1).
		_fit_wait = 0
		preview.modulate.a = 1.0
		if battle != null and battle.phase == Battle.Phase.BUILD:
			preview.set_open(true)
	else:
		_start_fit()


## Puts the parts in the portrait or landscape arrangement. Nothing is freed.
func _arrange() -> void:
	var mode: int = 1 if landscape else 0
	if mode == _arranged:
		return
	_arranged = mode
	for node: Control in [hud, hud.feedback_box, gate_tray, gate_tray.feedback_box, pause_strip, hint_banner, preview, build_panel, tower_panel, enemy_panel, draft_panel, map_area, _top_wrap, _side_slot]:
		var parent: Node = node.get_parent()
		if parent != null:
			parent.remove_child(node)
	_flow.vertical = not landscape
	if landscape:
		hud.set_gate_slot(null)
		_flow.add_child(map_area)
		_flow.add_child(_side_slot)
		for node: Control in [hud, gate_tray, pause_strip, hint_banner, preview]:
			_side_box.add_child(node)
		hud.column.add_child(hud.feedback_box)
		gate_tray.column.add_child(gate_tray.feedback_box)
	else:
		_flow.add_child(_top_wrap)
		_flow.add_child(map_area)
		_top_box.add_child(hud)
		# The gate chip sits in the HUD's first row. The dock, top to bottom, holds the
		# messages (so a refusal never makes the HUD taller), the Paused strip and the
		# preview. The hint floats over a free row of the map (_place_hint).
		hud.set_gate_slot(gate_tray)
		for node: Control in [hud.feedback_box, gate_tray.feedback_box, pause_strip, preview]:
			_dock.add_child(node)
		_hint_layer.add_child(hint_banner)
	_context_parent_changed()


## Moves the open panel to where the layout keeps it: the sheet or the side column.
func _place_context() -> void:
	if _context == null:
		return
	var target: Node = _side_box if landscape else _sheet_scroll
	if _context.get_parent() != target:
		var parent: Node = _context.get_parent()
		if parent != null:
			parent.remove_child(_context)
		target.add_child(_context)
		if landscape:
			_side_box.move_child(_context, mini(3, _side_box.get_child_count() - 1))
	_context.visible = true
	_context.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _context_parent_changed() -> void:
	# Panels leave their old parent in _arrange; the open one is put back by _place_context.
	for panel: BattlePanel in [build_panel, tower_panel, enemy_panel, draft_panel]:
		var parent: Node = panel.get_parent()
		if parent != null:
			parent.remove_child(panel)
	_place_context()


## Fits the map into its slot, then slides it if the sheet would hide the selection.
## The slot is everything under the HUD, so the map is as big as the width allows. In
## portrait it sits at the top of the slot, so it never moves when the dock changes.
func _fit_map() -> void:
	if battle == null:
		return
	var area: Vector2 = map_area.size
	var grid: Vector2 = Vector2(float(Sim.MAP_COLUMNS), float(battle.level.rows)) * MapView.CELL
	var k: float = minf(area.x / grid.x, area.y / grid.y)
	if k <= 0.0:
		return
	var fitted: Vector2 = grid * k
	var top: float = (area.y - fitted.y) * 0.5 if landscape else 0.0
	map_view.fit(Rect2(Vector2((area.x - fitted.x) * 0.5, top), fitted))
	_map_base = map_view.position
	_apply_pan()


## The map slides up so the selected cell stays above the sheet.
func _update_pan() -> void:
	_pan_target = 0.0
	if _context != null and not landscape and _selected.x >= 0 and _sheet.visible:
		var cell_px: float = map_view.scale.y * MapView.CELL
		var cell_top: float = _map_base.y + float(_selected.y) * cell_px
		var sheet_top: float = _sheet_scroll.global_position.y - map_area.global_position.y
		var need: float = cell_top + cell_px * 1.2 - sheet_top
		_pan_target = clampf(need, 0.0, maxf(0.0, cell_top - cell_px * 0.2))


## The dock hides while the sheet is open, so the two never overlap.
func _sync_dock() -> void:
	_dock_wrap.visible = not landscape and _context == null
	_hint_layer.visible = _dock_wrap.visible


## In portrait the hint takes no height. It goes to the first of these that works
## (docs/ARCHITECTURE.md 7.4): the top of the dock, when the dock with the hint still stays
## at or below the map's lowest row; a band of whole map rows wholly above the dock with
## nothing in it to see or tap, nearest the highlight (nearest the top of the map for the
## call button, nearest the bottom with no highlight); else the top of the dock anyway.
func _place_hint() -> void:
	if landscape or battle == null or not hint_banner.visible or hint_banner.get_parent() == null:
		return
	if _fit_wait > 0:
		return
	if _hint_fits_in_dock():
		_put_hint_in_dock()
		return
	var top: float = _free_band_top(HintBanner.HEIGHT)
	if top < 0.0:
		_put_hint_in_dock()
		return
	if hint_banner.get_parent() != _hint_layer:
		hint_banner.get_parent().remove_child(hint_banner)
		_hint_layer.add_child(hint_banner)
	hint_banner.position = Vector2(EDGE, top)
	hint_banner.size = Vector2(maxf(Layout.MIN_TOUCH, _stage.size.x - 2.0 * EDGE), HintBanner.HEIGHT)


func _put_hint_in_dock() -> void:
	if hint_banner.get_parent() != _dock:
		hint_banner.get_parent().remove_child(hint_banner)
		_dock.add_child(hint_banner)
	_dock.move_child(hint_banner, 0)


## The height of the parts of the dock that stay: the Paused strip and the preview. Messages
## come and go, so they are left out and the hint does not jump about.
func _dock_steady_height() -> float:
	var total: float = 0.0
	for part: Control in [pause_strip, preview]:
		if part.visible:
			total += part.get_combined_minimum_size().y + GAP
	return total


## True when the dock with the hint stays at or below the map's lowest row. `steady` is the
## height of the dock's steady parts, or -1 for the parts as they are now.
func _hint_fits_in_dock(steady: float = -1.0) -> bool:
	var height: float = maxf(HintBanner.HEIGHT, hint_banner.get_combined_minimum_size().y)
	var top: float = _dock.get_global_rect().end.y - (_dock_steady_height() if steady < 0.0 else steady) - height
	return top >= _map_bottom() - 0.5


## The bottom edge of the map's last row on screen (before any slide for a sheet).
func _map_bottom() -> float:
	return map_area.get_global_rect().position.y + _map_base.y + float(battle.level.rows) * _cell_px()


## True for a road cell with three or four road neighbors: a fork or a join.
func _is_junction(cell: Vector2i) -> bool:
	if not battle.level.is_road(cell):
		return false
	var roads: int = 0
	for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if battle.level.is_road(cell + step):
			roads += 1
	return roads >= 3


## 1 for each map row that holds a build spot, gate socket, entrance, home, highlighted cell,
## fork or join. The level never changes, so this is worked out once.
func _busy_row_marks() -> PackedByteArray:
	var rows: int = battle.level.rows
	if _busy_rows.size() == rows:
		return _busy_rows
	var busy: PackedByteArray = PackedByteArray()
	busy.resize(rows)
	var cells: Array[Vector2i] = []
	cells.append_array(battle.level.spots)
	cells.append_array(battle.level.sockets)
	cells.append_array(battle.level.entrances)
	cells.append(battle.level.base)
	cells.append(battle.level.hint_cell)
	for cell: Vector2i in cells:
		if cell.y >= 0 and cell.y < rows:
			busy[cell.y] = 1
	for y: int in rows:
		for x: int in Sim.MAP_COLUMNS:
			if _is_junction(Vector2i(x, y)):
				busy[y] = 1
	_busy_rows = busy
	return busy


## The top, in stage coordinates, of a band `height` tall made of whole map rows, wholly above
## the steady part of the dock, with nothing in them to see or tap: no build spot, gate
## socket, entrance, home, highlighted cell, fork or join. -1 when there is none.
func _free_band_top(height: float, steady: float = -1.0) -> float:
	var cell_px: float = _cell_px()
	if cell_px <= 0.0:
		return -1.0
	var rows: int = battle.level.rows
	var busy: PackedByteArray = _busy_row_marks()
	var need: int = maxi(1, ceili((height - 0.5) / cell_px))
	var anchor: float = float(rows) - 0.5
	if battle.level.hint_cell.y >= 0:
		anchor = float(battle.level.hint_cell.y) + 0.5
	elif battle.level.hint_button == &"call":
		anchor = 0.5
	var map_top: float = map_area.get_global_rect().position.y + _map_base.y
	var dock_top: float = _dock.get_global_rect().end.y - (_dock_steady_height() if steady < 0.0 else steady)
	var best: int = -1
	var best_d: float = INF
	for first: int in range(0, rows - need + 1):
		if map_top + float(first + need) * cell_px > dock_top + 0.5:
			continue
		var free: bool = true
		for r: int in range(first, first + need):
			if busy[r] == 1:
				free = false
		if free:
			var d: float = absf(float(first) + float(need) * 0.5 - anchor)
			if d < best_d:
				best_d = d
				best = first
	if best < 0:
		return -1.0
	var middle: float = map_top + (float(best) + float(need) * 0.5) * cell_px
	return middle - height * 0.5 - _stage.get_global_rect().position.y


# The preview fits under the map, or starts folded (docs/ARCHITECTURE.md 7.4, RULES 9.1).

## A build phase began, or the layout changed: in portrait the preview opens unseen for a few
## frames, is measured, and stays open only if its open form fits in the room under the map.
func _start_fit() -> void:
	if landscape or battle == null or battle.phase != Battle.Phase.BUILD or not is_inside_tree():
		return
	preview.set_open(true)
	preview.modulate.a = 0.0
	_fit_wait = FIT_FRAMES


func _step_fit() -> void:
	if _fit_wait <= 0:
		return
	if landscape or battle.phase != Battle.Phase.BUILD:
		_fit_wait = 0
		preview.modulate.a = 1.0
		return
	if not _dock_wrap.is_visible_in_tree():
		return
	_fit_wait -= 1
	if _fit_wait > 0:
		return
	var open: bool = preview_fits()
	if open and hint_banner.visible and not _hint_has_room(_dock_steady_height()):
		# The hint would have to cover the map next to an open preview. A folded strip is
		# shorter, so fold it: the strip still shows what is coming. A tap opens it.
		open = false
	preview.set_open(open)
	preview.modulate.a = 1.0


## True when the hint has a place that covers nothing next to dock parts of height `steady`:
## the top of the dock under the map, or a free band of map rows.
func _hint_has_room(steady: float) -> bool:
	return _hint_fits_in_dock(steady) or _free_band_top(HintBanner.HEIGHT, steady) >= 0.0


## True when the open preview's top, with the dock's bottom gap, stays at or below the
## map's lowest row. Measured on the preview as it is now.
func preview_fits() -> bool:
	var room: float = _dock.get_global_rect().end.y - _map_bottom()
	return preview.get_combined_minimum_size().y <= room + 0.5


func _apply_pan() -> void:
	map_view.position = Vector2(_map_base.x, _map_base.y - _pan)


func _update_sheet() -> void:
	_sheet.visible = _context != null and not landscape
	_sync_dock()
	if not _sheet.visible:
		return
	var wanted: float = _context.get_combined_minimum_size().y
	var room: float = _stage.size.y - _top_wrap.size.y - GAP
	_sheet_scroll.custom_minimum_size.y = clampf(wanted, 0.0, maxf(room, Layout.MIN_TOUCH))


# Each frame.

func _process(delta: float) -> void:
	if battle != null and is_visible_in_tree():
		frame(delta)


## One frame of the battle (docs/ARCHITECTURE.md 3.2). Tests call it with their own delta.
func frame(delta: float) -> void:
	if battle == null:
		return
	if battle.phase == Battle.Phase.WAVE:
		for i: int in clock.advance(delta):
			if probe != null:
				var started: int = Time.get_ticks_usec()
				battle.step()
				probe.record_tick_usec(Time.get_ticks_usec() - started)
			else:
				battle.step()
	else:
		clock.reset()
	var events: Array[Dictionary] = battle.take_events()
	map_view.sync(clock.alpha())
	map_view.play_events(events)
	if audio != null:
		audio.play_events(events)
	hud.refresh()
	# The lives pulse moves only while the game runs: a pause, the Pause menu or a card
	# (all of which freeze the clock) put it back at rest.
	if clock.paused:
		hud.stop_pulse()
	else:
		hud.advance_pulse(delta)
	gate_tray.refresh()
	preview.refresh()
	if _context != null:
		_context.refresh()
	_handle(events)
	_sync_draft()
	_sync_risk()
	_watch_sights()
	_sync_warnings()
	_step_fit()
	_place_hint()
	if _drag_active and battle.phase != Battle.Phase.BUILD:
		cancel_drag()
	if not _drag_active:
		_sync_routes()
	if is_inside_tree():
		_update_sheet()
		_update_pan()
		if delta <= 0.0 or absf(_pan_target - _pan) < 0.5:
			_pan = _pan_target
		else:
			_pan = lerpf(_pan, _pan_target, 1.0 - exp(-PAN_RATE * delta))
		_apply_pan()


func _handle(events: Array[Dictionary]) -> void:
	for e: Dictionary in events:
		var kind: Variant = e.get("kind")
		if kind == &"build_started":
			save_requested.emit()
			_check_sights()
		elif kind == &"wave_cleared":
			# The clear bonus was paid. Kills only move the gold number, so say it once here.
			hud.show_feedback(BattleText.cleared_text(int(e.get("wave", 0)), int(e.get("gold", 0))))
		# Nothing is shown for the other events (released, break_started, sped_up, interest):
		# RULES asks for no message, and the map and the sounds carry them.
	if (battle.phase == Battle.Phase.WON or battle.phase == Battle.Phase.LOST) and not _finished:
		_finished = true
		var result: Dictionary = battle.result()
		result["abandoned"] = false
		result["relaxed"] = battle.relaxed
		result["twist"] = not battle.twist_effects.is_empty()
		ended.emit(result)


## Route lines show through the whole build phase and hide during waves (RULES 7.5).
func _sync_routes() -> void:
	var sig: Array = [battle.phase, battle.waves_started, battle.closed_cells()]
	if sig == _routes_sig:
		return
	_routes_sig = sig
	if battle.phase == Battle.Phase.BUILD:
		map_view.show_routes(battle.routes(battle.closed_cells()))
	else:
		map_view.show_routes([] as Array[Dictionary])


# Stars during play (RULES 10.6).

## The star bits the player already has for this level.
func _earned_bits() -> int:
	if progress == null or battle == null:
		return 0
	return int(progress.levels.get(battle.level.id, 0))


## True in a campaign level that is not a Twist: runs, dailies and Twists have no stars.
func has_stars() -> bool:
	return battle != null and stars_in_play and battle.twist_effects.is_empty()


## The three star lines Pause shows, or none for a game without stars.
func star_entries() -> Array[Dictionary]:
	if not has_stars():
		var none: Array[Dictionary] = []
		return none
	return StarText.play_lines(battle.level, battle.catalog, _earned_bits(), battle.stars_possible(), battle.relaxed)


## The panels warn before a tap that would lose star 3 only while the game has stars and the
## third star is not already earned. The sim says whether a tap would lose it (loses_star3).
func _sync_warnings() -> void:
	var on: bool = has_stars() and (_earned_bits() & StarText.BIT_CHALLENGE) == 0
	for panel: BattlePanel in [build_panel, tower_panel, gate_tray]:
		panel.star_warnings = on


# First sights (RULES 9.2, 9.6).

## A tower or creature counts as seen only when the player closes its card, and the hint
## when the player closes it or the first wave starts. A card or hint that was open when
## the game was left opens again.
func _check_sights() -> void:
	if battle == null or progress == null or battle.phase != Battle.Phase.BUILD:
		return
	var items: Array[Dictionary] = []
	var fresh: bool = battle.waves_started == 0 and battle.tick == 0
	if fresh:
		for id: StringName in battle.level.towers:
			if not progress.seen.has(id):
				items.append({"kind": &"tower", "id": id, "wave": 0})
	var next: int = battle.waves_started
	for entry: Dictionary in battle.wave_preview(next):
		var id: StringName = entry["enemy"]
		if not progress.seen.has(id) and not _has_item(items, id):
			items.append({"kind": &"enemy", "id": id, "wave": next})
	if fresh and not battle.twist_effects.is_empty():
		# A Twist's rule is its first hint, once per screen. It is not remembered as read, so
		# every fresh start of a Twist says it again (RULES 13).
		if not _twist_hint_shown and not hint_banner.visible:
			_twist_hint_shown = true
			hint_banner.show_hint("Twist: %s" % battle.level.twist_text)
	elif fresh and not battle.level.hint_text.is_empty() and not progress.seen.has(battle.level.id) and not hint_banner.visible:
		hint_banner.show_hint(battle.level.hint_text)
		_hint_cell = battle.level.hint_cell
		map_view.show_hint(_hint_cell)
	_refresh_new_tags()
	if not items.is_empty():
		_show_card(items)


## Each frame: a creature of a kind the player has not seen is on the map (its wave was
## called early, or it was released from another): its card opens and the wave waits.
## The hint goes when the first wave starts.
func _watch_sights() -> void:
	if hint_banner.visible and battle.phase != Battle.Phase.BUILD:
		hint_banner.dismiss()
	if _fresh_wave != battle.waves_started and not _fresh.is_empty():
		_fresh.clear()
	_refresh_new_tags()
	if _card != null or progress == null or clock.paused or battle.phase != Battle.Phase.WAVE:
		return
	var items: Array[Dictionary] = []
	for enemy: EnemyState in battle.enemies:
		if not progress.seen.has(enemy.type) and not _has_item(items, enemy.type):
			items.append({"kind": &"enemy", "id": enemy.type, "wave": _wave_of(enemy.type)})
	if not items.is_empty():
		_show_card(items)


## The wave a creature on the map belongs to, newest first, for the strength of its numbers.
func _wave_of(id: StringName) -> int:
	for i: int in range(battle.running.size() - 1, -1, -1):
		for entry: Dictionary in battle.wave_preview(battle.running[i]):
			if entry["enemy"] == id:
				return battle.running[i]
	return maxi(0, battle.waves_started - 1)


func _has_item(items: Array[Dictionary], id: StringName) -> bool:
	for item: Dictionary in items:
		if item["id"] == id:
			return true
	return false


func _show_card(items: Array[Dictionary]) -> void:
	if _card != null:
		return
	if battle.phase == Battle.Phase.WAVE and not clock.paused:
		# A running wave waits for the card.
		clock.paused = true
		_card_froze = true
	_card = InfoCard.new(battle, items)
	_card.finished.connect(_on_card_finished.bind(items))
	_card.closed.connect(_on_card_closed)
	_open_modal(_card)


## The player closed the card: everything on it counts as seen now.
func _on_card_finished(items: Array[Dictionary]) -> void:
	var changed: bool = false
	for item: Dictionary in items:
		var id: StringName = item["id"]
		if progress != null and not progress.seen.has(id):
			progress.mark_seen(id)
			changed = true
		if item["kind"] == &"enemy" and not _fresh.has(id):
			_fresh.append(id)
			_fresh_wave = battle.waves_started
	if changed:
		progress_changed.emit()
	_refresh_new_tags()


func _on_card_closed() -> void:
	_card = null
	if _card_froze:
		_card_froze = false
		clock.paused = false
		if _card_resized:
			_card_resized = false
			pause()
	_check_sights()


## The preview tags the creatures that are new to the player: not seen yet, or seen on a
## card in this build phase and not met on the map yet.
func _refresh_new_tags() -> void:
	var ids: Array[StringName] = []
	if progress != null:
		for id: StringName in battle.catalog.enemy_ids():
			if not progress.seen.has(id) or _fresh.has(id):
				ids.append(id)
	if ids != _new_sig:
		_new_sig = ids
		preview.set_unseen(ids)


func _on_hint_closed() -> void:
	_hint_cell = NO_CELL
	map_view.show_hint(NO_CELL)
	if battle != null and progress != null and battle.twist_effects.is_empty() and not progress.seen.has(battle.level.id):
		progress.mark_seen(battle.level.id)
		progress_changed.emit()


# Panel signals.

func _on_refused(_reason: StringName, _text: String) -> void:
	if audio != null:
		audio.play_ui(&"refuse")


func _on_range_changed(cell: Vector2i, reach: int, boost: bool) -> void:
	map_view.show_range(cell, reach, boost)


func _on_built(cell: Vector2i, _type: StringName) -> void:
	if cell == _hint_cell:
		_hint_cell = NO_CELL
		map_view.show_hint(NO_CELL)


func _on_panel_closed(panel: BattlePanel) -> void:
	if panel != _context:
		return
	_context = null
	_selected = NO_CELL
	panel.visible = false
	map_view.show_selection(NO_CELL)
	map_view.show_range(NO_CELL, 0, false)
	_sheet.visible = false


## The open build, tower or creature panel, or null.
func context_panel() -> BattlePanel:
	return _context


func selected_cell() -> Vector2i:
	return _selected


func _open_context(panel: BattlePanel, cell: Vector2i) -> void:
	if _context != null:
		_close_panel(_context)
	_context = panel
	_selected = cell
	map_view.show_selection(cell)
	_place_context()
	_sheet.visible = not landscape
	if audio != null:
		audio.play_ui(&"tap")


func _close_panel(panel: BattlePanel) -> void:
	# The draft is not closed from here: only taking a card ends it.
	if panel is BuildPanel:
		(panel as BuildPanel).close()
	elif panel is TowerPanel:
		(panel as TowerPanel).close()
	elif panel is EnemyPanel:
		(panel as EnemyPanel).close()


func close_context() -> void:
	if _context != null and _context != draft_panel:
		_close_panel(_context)


## The back button: closes the open build, tower or creature panel and says so, so the
## next press can open Pause. False when no panel is open.
func close_panel_for_back() -> bool:
	# The draft never closes on back: the next press opens Pause instead (docs/ARCHITECTURE.md 3.6).
	if _context == null or _context == draft_panel:
		return false
	_close_panel(_context)
	return true


# The card draft of a run (RULES 14.4).

## True while the draft is open. The map, the gates and the other panels wait for it.
func draft_is_open() -> bool:
	return _context != null and _context == draft_panel


## The card of the run files with this id; {} when unknown.
func _card_of(id: StringName) -> Dictionary:
	return run.card(id) if run != null else {}


## Opens the draft when the run owes a card in a build phase, and puts it away when it does not.
## It opens by itself, one draft after another, so a draft cannot be skipped.
func _sync_draft() -> void:
	if run == null:
		return
	var owed: bool = run.draft_open()
	if owed and not draft_is_open():
		_open_draft()
	elif not owed and draft_is_open():
		draft_panel.close()


func _open_draft() -> void:
	var offers: Array[Dictionary] = []
	for id: StringName in run.offers():
		var card: Dictionary = _card_of(id)
		if card.is_empty():
			card = {"id": id, "kind": &"economy", "tower": &"", "name": String(id), "text": ""}
		offers.append(card)
	if offers.is_empty():
		return
	if _drag_active:
		cancel_drag()
	draft_panel.show_offers(offers, "Wave %d cleared. Pick a card." % (run.picks.size() + 1))
	_open_context(draft_panel, NO_CELL)


## The player took a card. The run adds it, the draft closes, the game is saved, and a new
## tower gets its first sight card. The next draft owed opens on the next frame.
func _on_draft_picked(card_id: StringName) -> void:
	if run == null or not draft_is_open():
		return
	var card: Dictionary = _card_of(card_id)
	var result: StringName = run.pick(card_id)
	if result != Battle.DONE:
		draft_panel.reject(result)
		return
	draft_panel.close()
	save_requested.emit()
	if card.get("kind", &"") == &"tower" and progress != null:
		var tower: StringName = card.get("tower", &"")
		if tower != &"" and not progress.seen.has(tower):
			_show_card([{"kind": &"tower", "id": tower, "wave": 0}] as Array[Dictionary])


## The waiting risk card shows first in the wave preview, as a row and as a chip (RULES 9.1).
func _sync_risk() -> void:
	if run == null:
		return
	var id: StringName = run.risk_card()
	if id == &"":
		preview.set_risk("", "")
		return
	var card: Dictionary = _card_of(id)
	preview.set_risk(String(card.get("name", String(id))), String(card.get("text", "")))


# Taps.

func _on_map_input(event: InputEvent) -> void:
	if battle == null:
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		var at: Vector2 = map_area.get_global_transform() * button.position
		if button.pressed:
			_pressing = true
			_press_at = at
			_travel = 0.0
			_press_cell = map_view.cell_at(at)
		elif _pressing:
			_pressing = false
			if _drag_active:
				end_drag(at)
			elif _travel < TapButton.DEADZONE:
				tap_at(map_view.cell_at(at), map_view.enemy_at(at))
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _pressing:
		var where: Vector2 = map_area.get_global_transform() * motion.position
		_travel = maxf(_travel, where.distance_to(_press_at))
		if not _drag_active and _travel >= TapButton.DEADZONE:
			_maybe_begin_drag(where)
		if _drag_active:
			move_drag(where)


## A tap at a cell, with the creature under the finger (-1 for none). Public so tests can tap.
func tap_at(cell: Vector2i, enemy_id: int = -1) -> void:
	if battle == null or draft_is_open():
		return
	var kind: LevelData.Kind = battle.level.kind_at(cell) if cell.x >= 0 else LevelData.Kind.SCENERY
	if enemy_id >= 0:
		var enemy: EnemyState = battle.enemy_with_id(enemy_id)
		if enemy != null and (enemy.flying or kind != LevelData.Kind.SPOT):
			show_enemy(enemy_id)
			return
	match kind:
		LevelData.Kind.SPOT:
			if battle.tower_at(cell) != null:
				show_tower(cell)
			else:
				show_build(cell)
		LevelData.Kind.SOCKET:
			tap_socket(cell)
		_:
			close_context()


func show_build(cell: Vector2i) -> void:
	if draft_is_open():
		return
	_open_context(build_panel, cell)
	build_panel.show_spot(cell)


func show_tower(cell: Vector2i) -> void:
	if draft_is_open():
		return
	_open_context(tower_panel, cell)
	tower_panel.show_tower(cell)


func show_enemy(id: int) -> void:
	if draft_is_open():
		return
	_open_context(enemy_panel, NO_CELL)
	enemy_panel.show_enemy(id)


## A tap on a socket: place a gate there, or take the gate on it back (RULES 7.2).
func tap_socket(cell: Vector2i) -> void:
	if draft_is_open():
		return
	close_context()
	if battle.gates_in_hand == 0 and battle.gates.is_empty():
		# No gates at all: a level with none, or the No Gates Twist. A socket tap says nothing.
		return
	var result: StringName
	var warn: bool = false
	if battle.phase != Battle.Phase.BUILD:
		result = &"gates_locked"
	elif _gate_at(cell) != null:
		result = battle.remove_gate(cell)
	else:
		warn = gate_tray.warns(&"gate")
		result = battle.place_gate(cell)
	if not _finish_gate(result, warn):
		map_view.show_refused(cell)


## Shows the outcome of a gate command in the gate message. A new gate that goes over the
## level's gate rule says the third star is lost if a wave starts with it (RULES 10.6).
## Returns true when the command was carried out.
func _finish_gate(result: StringName, warn: bool) -> bool:
	if not gate_tray.finish(result):
		return false
	if warn:
		gate_tray.show_feedback(StarNote.GATE_TEXT)
	return true


func _gate_at(cell: Vector2i) -> GateState:
	for gate: GateState in battle.gates:
		if gate.cell == cell:
			return gate
	return null


# The gate drag.

func _maybe_begin_drag(where: Vector2) -> void:
	if battle.phase != Battle.Phase.BUILD or draft_is_open():
		return
	if battle.level.kind_at(_press_cell) != LevelData.Kind.SOCKET:
		return
	var gate: GateState = _gate_at(_press_cell)
	if gate != null:
		if gate.fixed:
			return
		begin_drag(_press_cell, where)
	elif battle.gates_in_hand > 0:
		begin_drag(NO_CELL, where)


func _on_tray_drag_began(where: Vector2) -> void:
	if battle.phase == Battle.Phase.BUILD and battle.gates_in_hand > 0 and not draft_is_open():
		begin_drag(NO_CELL, where)


## Starts carrying a gate. `from` is the socket it was lifted from, or (-1, -1) for a
## new gate from the hand.
func begin_drag(from: Vector2i, where: Vector2) -> void:
	if battle == null or battle.phase != Battle.Phase.BUILD or draft_is_open():
		return
	close_context()
	_drag_active = true
	_drag_from = from
	_drag_target = NO_CELL
	_drag_sig = []
	move_drag(where)


func is_dragging() -> bool:
	return _drag_active


func drag_target() -> Vector2i:
	return _drag_target


## The finger moved. The gate floats above it and snaps to a socket that is close.
func move_drag(where: Vector2) -> void:
	if not _drag_active:
		return
	var cell_px: float = _cell_px()
	var carried: Vector2 = where - Vector2(0.0, GHOST_LIFT * cell_px)
	var target: Vector2i = _socket_near(carried, cell_px)
	_drag_target = target
	var shown: Vector2 = _socket_center(target) if target.x >= 0 else carried
	var along: Vector2i = target if target.x >= 0 else (_drag_from if _drag_from.x >= 0 else _first_socket())
	var sealed: bool = _would_seal(target)
	ghost.show_at(shown, cell_px, MapArt.road_runs_vertically(battle.level.grid, along) if along.x >= 0 else false,
		MapArt.Gate.REFUSED if sealed else MapArt.Gate.CLOSED)
	var sig: Array = [target]
	if sig != _drag_sig:
		_drag_sig = sig
		_show_drag_routes(sealed)


## The finger lifted. A drop on a socket places or moves the gate. A gate lifted from a
## socket and dropped on the strip goes back to the hand. Anywhere else changes nothing.
func end_drag(where: Vector2) -> void:
	if not _drag_active:
		return
	move_drag(where)
	var target: Vector2i = _drag_target
	var from: Vector2i = _drag_from
	_drag_active = false
	ghost.hide_ghost()
	var result: StringName = &""
	var warn: bool = false
	if target.x >= 0:
		if from.x < 0:
			warn = gate_tray.warns(&"gate")
			result = battle.place_gate(target)
		elif target != from:
			result = battle.move_gate(from, target)
	elif from.x >= 0 and gate_tray.visible and (gate_tray.get_global_rect().has_point(where) or gate_tray.get_global_rect().has_point(where - Vector2(0.0, GHOST_LIFT * _cell_px()))):
		result = battle.remove_gate(from)
	if result != &"" and not _finish_gate(result, warn):
		map_view.show_refused(target if target.x >= 0 else from)
	_routes_sig = []
	_sync_routes()


## Drops a drag with no change (a layout change, the wave starting, the pause).
func cancel_drag() -> void:
	_pressing = false
	gate_tray.cancel_drag()
	if not _drag_active:
		return
	_drag_active = false
	ghost.hide_ghost()
	_routes_sig = []
	if battle != null:
		_sync_routes()


## The closed sockets as they would be if the carried gate were dropped where it hovers.
func _drag_closed(target: Vector2i) -> Array[Vector2i]:
	var closed: Array[Vector2i] = battle.closed_cells()
	if _drag_from.x >= 0:
		closed.erase(_drag_from)
	if target.x >= 0 and not closed.has(target) and (_gate_at(target) == null or target == _drag_from):
		closed.append(target)
	return closed


func _would_seal(target: Vector2i) -> bool:
	return target.x >= 0 and battle.seals(_drag_closed(target))


## The lines as they would be if the carried gate were dropped where it hovers. Over a
## socket that would close every road the crossed out gate shows instead.
func _show_drag_routes(sealed: bool) -> void:
	if sealed:
		map_view.show_refused(_drag_target)
		map_view.show_routes(battle.routes(battle.closed_cells()))
	else:
		map_view.show_routes(battle.routes(_drag_closed(_drag_target)))


func _cell_px() -> float:
	return map_view.get_global_transform().get_scale().x * MapView.CELL


func _socket_center(cell: Vector2i) -> Vector2:
	return map_view.get_global_transform() * ((Vector2(cell) + Vector2(0.5, 0.5)) * MapView.CELL)


func _socket_near(point: Vector2, cell_px: float) -> Vector2i:
	var best: Vector2i = NO_CELL
	var best_d: float = SNAP_CELLS * cell_px
	for socket: Vector2i in battle.level.sockets:
		var d: float = _socket_center(socket).distance_to(point)
		if d <= best_d:
			best_d = d
			best = socket
	return best


func _first_socket() -> Vector2i:
	return battle.level.sockets[0] if not battle.level.sockets.is_empty() else NO_CELL


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Parts that are not in the tree when the screen goes (the other layout's, the
		# closed panels) are freed here so nothing leaks.
		# One may hold another (the HUD holds its message box), so each is checked as it comes.
		for part: Variant in [hud, hud.feedback_box, gate_tray, gate_tray.feedback_box, pause_strip, hint_banner, preview, build_panel, tower_panel, enemy_panel, draft_panel, map_area, _top_wrap, _side_slot, ghost, _sheet]:
			if is_instance_valid(part) and (part as Control).get_parent() == null:
				(part as Control).free()
		for modal: Modal in _modals + _modals_gone:
			if is_instance_valid(modal) and modal.get_parent() == null:
				modal.free()
