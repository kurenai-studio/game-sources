# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Checks that need a running scene tree: real layout at both Fold5 sizes, touch
## sizes, and real touches pushed through the GUI. The test runner builds its
## tests before the tree runs, so tests/ui/test_real_tree.gd starts this script
## in a second Godot process and reads what it prints.
##
##     godot --headless --path . --script res://tests/ui/real_tree_checks.gd
##
## Every problem prints a line starting with "FAIL". The exit code is 0 when
## nothing failed. A watchdog ends the run if it ever hangs.

const COVER: Vector2 = Vector2(1080.0, 2767.0)
const INNER: Vector2 = Vector2(1998.0, 2400.0)
const COVER_SAFE: Rect2 = Rect2(0.0, 96.0, 1080.0, 2500.0)
const INNER_SAFE: Rect2 = Rect2(0.0, 0.0, 1998.0, 2250.0)
## Only a guard against a hang. The checks take about 100 s on an idle dev PC and took 317 s
## with 20 other Godot jobs running (QA 2026-10-29), so the margin is nearly 3 times that.
const WATCHDOG_SECONDS: float = 900.0
## The Fold5 cover: 1080 logical px across 344 dp (docs/ARCHITECTURE.md 7.4).
const COVER_PX_PER_DP: float = 3.14
const BattleFixtures: GDScript = preload("res://tests/ui/battle_fixtures.gd")
const RunFx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")


## Stands in for the phone: remembers every address handed to it.
class Recorder extends RefCounted:
	var urls: Array[String] = []

	func record(url: String) -> void:
		urls.append(url)


var failures: int = 0
var checks: int = 0
var recorder: Recorder = Recorder.new()


func _initialize() -> void:
	create_timer(WATCHDOG_SECONDS).timeout.connect(func() -> void:
		print("FAIL watchdog: the checks did not finish")
		quit(2))
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL %s" % message)


func _frames(count: int = 3) -> void:
	for i: int in count:
		await process_frame


func _viewport(size: Vector2) -> SubViewport:
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(size)
	root.add_child(vp)
	return vp


func _hosted(vp: SubViewport, screen: Control, size: Vector2, safe: Rect2) -> void:
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = UiTheme.build()
	vp.add_child(holder)
	holder.add_child(screen)
	screen.call("apply_layout", size, safe)
	await _frames()


func _run() -> void:
	Links.opener = recorder.record
	# `-- --only=hud` runs one group while working on it. No argument runs everything.
	if OS.get_cmdline_user_args().has("--only=u3"):
		await _u3_real()
		Links.opener = Callable()
		Fx.remove_all()
		print("%d checks, %d failed" % [checks, failures])
		quit(1 if failures > 0 else 0)
		return
	await _touch_sizes()
	await _front_door()
	await _taps()
	await _about_first_screenful()
	await _battle_panels()
	await _app()
	await _battle_screens()
	await _cell_floor()
	await _u1_real()
	await _u2_real()
	await _u3_real()
	Links.opener = Callable()
	Fx.remove_all()
	print("%d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)


# Touch sizes.

const SCREEN_NAMES: PackedStringArray = [
	"front door", "mode screen", "mode screen open", "info", "about", "license viewer",
	"settings", "pause", "pause stars", "confirm", "level select", "level card", "level card saved", "end win", "end loss",
	"info card tower", "info card creature", "notice", "damaged",
]


func _make(label: String) -> Control:
	match label:
		"front door":
			return FrontDoor.new()
		"mode screen":
			var locked: ModeScreen = ModeScreen.new()
			locked.set_continue("Continue", "Pick up where you left off.")
			locked.set_runs(false, 0, 12)
			return locked
		"mode screen open":
			var open: ModeScreen = ModeScreen.new()
			open.set_runs(true, 14, 12)
			return open
		"info":
			return InfoScreen.new()
		"about":
			return AboutScreen.new()
		"license viewer":
			return LicenseViewer.new("Test", LicenseText.build(LicenseText.FONT))
		"settings":
			return SettingsPanel.new(true)
		"pause":
			return PausePanel.new()
	return ConfirmDialog.new("Sure?", "This cannot be undone.", "Yes")


func _touch_sizes() -> void:
	var sizes: Array[Vector2] = [COVER, INNER]
	var safes: Array[Rect2] = [COVER_SAFE, INNER_SAFE]
	for label: String in SCREEN_NAMES:
		for i: int in sizes.size():
			var vp: SubViewport = _viewport(sizes[i])
			var screen: Control = _make(label)
			await _hosted(vp, screen, sizes[i], safes[i])
			var found: int = 0
			for node: Node in screen.find_children("*", "BaseButton", true, false):
				var button: BaseButton = node as BaseButton
				if not button.is_visible_in_tree():
					continue
				found += 1
				var where: String = "%s at %s: button '%s'" % [label, sizes[i], str((button as Button).text)]
				check(button.size.x >= Layout.MIN_TOUCH - 0.5, "%s is too narrow (%s)" % [where, button.size.x])
				check(button.size.y >= Layout.MIN_TOUCH - 0.5, "%s is too short (%s)" % [where, button.size.y])
				var rect: Rect2 = button.get_global_rect()
				check(rect.position.x >= -0.5 and rect.end.x <= sizes[i].x + 0.5, "%s runs off the screen sideways %s" % [where, rect])
			check(found > 0, "%s at %s has buttons" % [label, sizes[i]])
			vp.queue_free()


func _front_door() -> void:
	var vp: SubViewport = _viewport(COVER)
	var door: FrontDoor = FrontDoor.new()
	await _hosted(vp, door, COVER, COVER_SAFE)
	for button: TapButton in [door.play_button, door.info_button, door.about_button]:
		check(button.get_global_rect().get_center().y > COVER.y * 0.5, "a main button is too high for one thumb in portrait")
	check(door.coffee_button.get_global_rect().position.y > door.about_button.get_global_rect().end.y, "coffee is below the main buttons")
	check(door.settings_button.get_global_rect().end.x > COVER.x - 100.0, "the gear is at the top right")
	check(door.settings_button.get_global_rect().position.y < 400.0, "the gear is at the top")
	check(not door.landscape, "the cover screen is portrait")
	vp.queue_free()
	var vp2: SubViewport = _viewport(INNER)
	var door2: FrontDoor = FrontDoor.new()
	await _hosted(vp2, door2, INNER, INNER_SAFE)
	check(door2.landscape, "the inner screen is landscape")
	check(door2.art.get_global_rect().end.x <= door2.play_button.get_global_rect().position.x, "landscape: the picture is left of the buttons")
	vp2.queue_free()


# Real touches.

func _touch(vp: SubViewport, at: Vector2, travel: Vector2 = Vector2.ZERO) -> void:
	_press(vp, at, true)
	for i: int in 4:
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.position = at + travel * float(i + 1) / 4.0
		motion.global_position = motion.position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		vp.push_input(motion)
	_press(vp, at + travel, false)


func _press(vp: SubViewport, at: Vector2, down: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = at
	event.global_position = at
	vp.push_input(event)


func _coffee_in(vp: SubViewport) -> CoffeeButton:
	var button: CoffeeButton = CoffeeButton.new()
	vp.add_child(button)
	button.position = Vector2(100, 100)
	button.size = Vector2(700, 200)
	return button


func _taps() -> void:
	var vp: SubViewport = _viewport(Vector2(1080, 1000))
	var button: CoffeeButton = _coffee_in(vp)
	await _frames()
	var inside: Vector2 = Vector2(150, 150)
	recorder.urls.clear()
	_touch(vp, inside)
	check(recorder.urls == ([Links.COFFEE_URL] as Array[String]), "one clean tap hands the coffee address over exactly once, got %s" % [recorder.urls])
	recorder.urls.clear()
	_touch(vp, inside, Vector2(TapButton.DEADZONE * 0.5, 0.0))
	check(recorder.urls.size() == 1, "a small wobble still counts as a tap")
	recorder.urls.clear()
	_touch(vp, inside, Vector2(TapButton.DEADZONE * 3.0, 0.0))
	check(recorder.urls.size() == 0, "a drag that ends on the button is not a tap")
	_touch(vp, inside, Vector2(0.0, 600.0))
	check(recorder.urls.size() == 0, "a press that ends off the button is not a tap")
	# Out and back.
	_press(vp, inside, true)
	for point: Vector2 in [Vector2(300, 150), inside]:
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		vp.push_input(motion)
	_press(vp, inside, false)
	check(recorder.urls.size() == 0, "a drag that goes out and comes back is not a tap")
	recorder.urls.clear()
	_touch(vp, inside)
	_touch(vp, inside)
	check(recorder.urls.size() == 2, "two taps hand over twice")
	vp.queue_free()
	# A scroll between down and up.
	var vp2: SubViewport = _viewport(Vector2(1080, 1000))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size = Vector2(900, 500)
	vp2.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	var head: Control = Control.new()
	head.custom_minimum_size = Vector2(800, 100)
	column.add_child(head)
	var in_scroll: CoffeeButton = CoffeeButton.new()
	column.add_child(in_scroll)
	var tail: Control = Control.new()
	tail.custom_minimum_size = Vector2(800, 1500)
	column.add_child(tail)
	scroll.add_child(column)
	await _frames()
	var at: Vector2 = in_scroll.get_global_rect().get_center()
	recorder.urls.clear()
	_press(vp2, at, true)
	scroll.scroll_vertical = 40
	await _frames()
	_press(vp2, at, false)
	check(recorder.urls.size() == 0, "a scroll between down and up is not a tap")
	check(scroll.scroll_vertical == 40, "the test did scroll")
	_touch(vp2, in_scroll.get_global_rect().get_center())
	check(recorder.urls.size() == 1, "a clean tap inside a scroll container still works")
	vp2.queue_free()


# About.

func _about_first_screenful() -> void:
	for pair: Array in [[COVER, COVER_SAFE], [INNER, INNER_SAFE]]:
		var size: Vector2 = pair[0]
		var vp: SubViewport = _viewport(size)
		var screen: AboutScreen = AboutScreen.new()
		await _hosted(vp, screen, size, pair[1])
		for node: Control in [screen.wordmark, screen.version_label, screen.made_by_label, screen.copyright_label, screen.source_button]:
			check(node != null, "brand block part is missing at %s" % size)
			if node != null:
				check(node.get_global_rect().end.y <= size.y, "a brand block part is below the first screenful at %s" % size)
		check(screen.coffee_button.get_global_rect().end.y < screen.license_buttons[LicenseText.FORKLINE].get_global_rect().position.y, "Supporting comes before the license rows")
		recorder.urls.clear()
		_touch(vp, screen.source_button.get_global_rect().get_center())
		check(recorder.urls == ([Links.SOURCE_URL] as Array[String]), "the source link hands the source address over once, got %s" % [recorder.urls])
		vp.queue_free()


# The battle panels: real Battle objects, at both Fold5 sizes.

## A themed host with a column the width a layout gives the panels: the whole safe
## width in portrait, a side panel of 760 in landscape.
func _panel_host(size: Vector2, wide: bool) -> Array:
	var vp: SubViewport = _viewport(size)
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = UiTheme.build()
	vp.add_child(holder)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 16)
	var width: float = 1008.0 if wide else 760.0
	column.position = Vector2(36.0 if wide else size.x - 36.0 - width, 132.0 if wide else 36.0)
	column.custom_minimum_size = Vector2(width, 0.0)
	column.size = Vector2(width, 100.0)
	holder.add_child(column)
	return [vp, column, width]


func _battle_panels() -> void:
	for pair: Array in [[COVER, true], [INNER, false]]:
		var size: Vector2 = pair[0]
		var wide: bool = pair[1]
		for state: String in ["hud", "build", "build six", "tower 1", "paths", "path picked", "tier 3", "paths bell", "paths firework", "creature", "preview", "strip", "preview boss", "strip many", "hud wave", "boss creature"]:
			var host: Array = _panel_host(size, wide)
			var vp: SubViewport = host[0]
			var column: VBoxContainer = host[1]
			var width: float = host[2]
			var b: Battle = BattleFixtures.battle(&"r1_l6")
			b.gold = 900
			var cell: Vector2i = b.level.spots[0]
			var hud: BattleHud = BattleHud.new()
			hud.set_wide(wide)
			hud.refresh(b)
			var panel: BattlePanel = null
			match state:
				"build", "build six":
					if state == "build six":
						b = BattleFixtures.all_towers_battle(&"r1_l6")
						b.gold = 900
					var build: BuildPanel = BuildPanel.new()
					build.setup(b)
					build.set_wide(wide)
					build.show_spot(cell)
					panel = build
				"tower 1", "paths", "path picked", "tier 3", "paths bell", "paths firework":
					var built: StringName = &"pumpkin_catapult"
					if state == "paths bell" or state == "paths firework":
						# The widest rows: "Walkers and flyers" and "0.75 tiles to none".
						b = BattleFixtures.all_towers_battle(&"r1_l6")
						b.gold = 900
						built = &"lullaby_bell" if state == "paths bell" else &"firework_tower"
					b.place_tower(cell, built)
					if state != "tower 1":
						b.upgrade_tower(cell)
					if state == "tier 3":
						b.upgrade_tower(cell, 1)
					var tower: TowerPanel = TowerPanel.new()
					tower.setup(b)
					tower.set_wide(wide)
					tower.show_tower(cell)
					if state == "path picked":
						tower.pick_path(0)
					panel = tower
				"creature":
					b.start_next_wave()
					for i: int in 10:
						b.step()
					var enemy: EnemyPanel = EnemyPanel.new()
					enemy.setup(b)
					enemy.set_wide(wide)
					enemy.show_enemy(b.enemies[0].id)
					panel = enemy
				"preview", "strip", "preview boss", "strip many":
					if state == "strip":
						b.start_next_wave()
					if state == "preview boss" or state == "strip many":
						b.waves_started = b.wave_count() - 1
					if state == "strip many":
						b.phase = Battle.Phase.WAVE
					var preview: WavePreview = WavePreview.new()
					preview.set_wide(wide)
					var unseen: Array[StringName] = [&"grumblesack", &"flitter", &"scamp"]
					preview.set_unseen(unseen)
					preview.setup(b)
					if state == "preview boss":
						preview.toggle_row(&"scamp")
					panel = preview
				"hud wave":
					b.start_next_wave()
					for i: int in 120:
						b.step()
					hud.refresh()
					hud.set_paused(true)
					hud.set_speed(3)
				"boss creature":
					b = BattleFixtures.battle_with_first_wave([{"enemy": "grumblesack", "count": 1, "entrance": 1, "at_ms": 0, "every_ms": 1000}], &"r1_l6")
					b.start_next_wave()
					for i: int in 10:
						b.step()
					b.enemies[0].slow_pct = 40
					b.enemies[0].slow_ticks = 30
					var boss: EnemyPanel = EnemyPanel.new()
					boss.setup(b)
					boss.set_wide(wide)
					boss.show_enemy(b.enemies[0].id)
					hud.refresh(b)
					panel = boss
			column.add_child(hud)
			if panel != null:
				column.add_child(panel)
			await _frames()
			var where: String = "%s at %s" % [state, size]
			var column_rect: Rect2 = Rect2(column.global_position, Vector2(width, column.size.y))
			for node: Node in column.find_children("*", "BaseButton", true, false):
				var button: BaseButton = node as BaseButton
				if not button.is_visible_in_tree():
					continue
				var rect: Rect2 = button.get_global_rect()
				var label: String = "%s: button '%s'" % [where, str((button as Button).text)]
				check(rect.size.x >= Layout.MIN_TOUCH - 0.5 and rect.size.y >= Layout.MIN_TOUCH - 0.5, "%s is under 48 dp (%s)" % [label, rect.size])
				check(rect.position.x >= column_rect.position.x - 0.5 and rect.end.x <= column_rect.end.x + 0.5, "%s sticks out of the panel column %s" % [label, rect])
			# Nothing may lie outside the screen: every visible control, at any depth. The one
			# exception is the two tall tier 3 states in the narrow side panel, which stacks
			# the path cards and scrolls (the side column is a scroll area).
			var scrolls: bool = not wide and (state == "paths" or state == "path picked" or state == "paths bell" or state == "paths firework")
			var screen: Rect2 = Rect2(Vector2.ZERO, size)
			for node: Node in column.find_children("*", "Control", true, false):
				if scrolls:
					break
				var control: Control = node as Control
				if not control.is_visible_in_tree() or control.size.x <= 0.0 or control.size.y <= 0.0:
					continue
				var box: Rect2 = control.get_global_rect()
				check(screen.grow(0.5).encloses(box), "%s: %s (%s) lies outside the screen %s" % [where, control.get_class(), control.name, box])
			for part: Control in [hud, panel]:
				if part != null:
					check(part.size.x <= width + 0.5, "%s: a panel is wider than its column (%s)" % [where, part.size.x])
					check(scrolls or part.get_global_rect().end.y <= size.y, "%s: a panel runs off the screen bottom (%s)" % [where, part.get_global_rect().end.y])
			vp.queue_free()
	# A real tap on the Build button builds, and a real tap on Sell twice sells.
	var host: Array = _panel_host(COVER, true)
	var tap_vp: SubViewport = host[0]
	var tap_column: VBoxContainer = host[1]
	var live: Battle = BattleFixtures.battle()
	var spot: Vector2i = live.level.spots[0]
	var build_panel: BuildPanel = BuildPanel.new()
	build_panel.setup(live)
	build_panel.show_spot(spot)
	tap_column.add_child(build_panel)
	await _frames()
	_touch(tap_vp, build_panel.build_button.get_global_rect().get_center())
	check(live.tower_at(spot) != null, "a real tap on Build builds the tower")
	var tower_panel: TowerPanel = TowerPanel.new()
	tower_panel.setup(live)
	tower_panel.show_tower(spot)
	tap_column.remove_child(build_panel)
	tap_column.add_child(tower_panel)
	await _frames()
	_touch(tap_vp, tower_panel.sell_button.get_global_rect().get_center())
	check(live.tower_at(spot) != null, "the first real tap on Sell only asks")
	await _frames()
	_touch(tap_vp, tower_panel.sell_button.get_global_rect().get_center())
	check(live.tower_at(spot) != null, "a quick second tap on Sell does not sell")
	await create_timer(float(TowerPanel.SELL_DELAY_MS) / 1000.0 + 0.2).timeout
	_touch(tap_vp, tower_panel.sell_button.get_global_rect().get_center())
	check(live.tower_at(spot) == null, "a second real tap on Sell after the short wait sells")
	tap_vp.queue_free()


# The App.

func _app() -> void:
	var vp: SubViewport = _viewport(COVER)
	var app: App = (load("res://scenes/ui/app.tscn") as PackedScene).instantiate() as App
	vp.add_child(app)
	await _frames()
	check(app.current_screen() is FrontDoor, "the App boots to the front door")
	check(not app.get_tree().quit_on_go_back, "the App handles the back button itself")
	_touch(vp, app.front_door().play_button.get_global_rect().get_center())
	check(app.current_screen() is ModeScreen, "a real tap on Play opens the mode screen")
	check(app.handle_back() == &"page", "back leaves the mode screen")
	_touch(vp, app.front_door().info_button.get_global_rect().get_center())
	await _frames()
	check(app.current_screen() is InfoScreen, "a real tap on Info opens Info")
	check((app.current_screen() as InfoScreen).scroll.scroll_vertical == 0, "Info opens at the top")
	app.handle_back()
	await _frames()
	_touch(vp, app.front_door().settings_button.get_global_rect().get_center())
	check(app.modal_count() == 1, "a real tap on the gear opens Settings")
	app.handle_back()
	check(app.modal_count() == 0, "back closes Settings")
	# A fold: the window changes shape, the front door follows, and the state stays.
	var door: FrontDoor = app.front_door()
	vp.size = Vector2i(INNER)
	await _frames()
	check(door.landscape, "an unfolded window switches to the landscape layout")
	vp.size = Vector2i(COVER)
	await _frames()
	check(not door.landscape, "and back to portrait")
	vp.queue_free()


# The battle screen in a real scene tree, at both Fold5 sizes.

const Fx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const BATTLE_TAGS: PackedStringArray = [
	"real_cover_build", "real_inner_build", "real_cover_touch", "real_inner_touch",
	"real_cover_drag", "real_inner_drag", "real_fold", "real_back",
	"real_coverimm_build", "real_coverimm_touch",
]


func _battle_app(vp: SubViewport, size: Vector2, safe: Rect2, tag: String) -> App:
	Fx.wipe(tag)
	var made: App = (load("res://scenes/ui/app.tscn") as PackedScene).instantiate() as App
	made.game = BattleFixtures.game()
	made.store = SaveStore.new(Fx.dir(tag))
	made.audio = Fx.audio()
	made.end_delay = 0.0
	vp.add_child(made)
	await _frames()
	made.apply_layout(size, safe)
	Fx.mark_all_seen(made)
	return made


func _start_level(made: App, id: StringName) -> BattleScreen:
	made.start_level(id, false)
	await _frames(4)
	return made.battle_screen()


## Every visible control inside the viewport, and every button big enough.
func _inside_and_big(root: Node, size: Vector2, where: String) -> void:
	var screen: Rect2 = Rect2(Vector2.ZERO, size).grow(0.6)
	for node: Node in root.find_children("*", "Control", true, false):
		var control: Control = node as Control
		if not control.is_visible_in_tree() or control.size.x <= 0.0 or control.size.y <= 0.0:
			continue
		check(screen.encloses(control.get_global_rect()), "%s: %s (%s) lies outside the viewport %s" % [where, control.get_class(), control.name, control.get_global_rect()])
	for node: Node in root.find_children("*", "BaseButton", true, false):
		var button: BaseButton = node as BaseButton
		if button.is_visible_in_tree() and button.size.x > 0.0:
			check(button.size.x >= Layout.MIN_TOUCH - 0.5 and button.size.y >= Layout.MIN_TOUCH - 0.5, "%s: a button is under 48 dp (%s)" % [where, button.size])


func _cell_center(screen: BattleScreen, cell: Vector2i) -> Vector2:
	return screen.map_view.get_global_transform() * ((Vector2(cell) + Vector2(0.5, 0.5)) * MapView.CELL)


func _motion(vp: SubViewport, at: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	vp.push_input(motion)


## The points of a straight line, for a finger that moves.
func _line(from: Vector2, to: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i: int in 9:
		out.append(from.lerp(to, float(i) / 8.0))
	return out


func _battle_screens() -> void:
	# The cover screen in immersive mode as QA found it (2026-10-26, p4): the display reports
	# the whole screen but the 85 px camera cutout, and the gesture bar owns the bottom 39 px.
	var immersive: Rect2 = Layout.safe_in_viewport(COVER, Vector2(904.0, 2316.0), Vector2.ZERO, Rect2(0.0, 85.0, 904.0, 2231.0), Layout.GESTURE_MARGIN)
	check(is_equal_approx(immersive.end.y, COVER.y - Layout.GESTURE_MARGIN), "immersive cover: the safe area keeps the gesture margin clear")
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"], [COVER, immersive, "coverimm"]]:
		var size: Vector2 = pair[0]
		var safe: Rect2 = pair[1]
		var label: String = pair[2]
		await _battle_build_phase(size, safe, label)
		await _battle_panels_and_touch(size, safe, label)
		if label != "coverimm":
			await _battle_gate_drag(size, safe, label)
	await _battle_fold()
	await _battle_back_and_pause()
	await _battle_end_delay()
	for tag: String in BATTLE_TAGS:
		Fx.wipe(tag)
	Fx.audio().free()


func _battle_build_phase(size: Vector2, safe: Rect2, label: String) -> void:
	var vp: SubViewport = _viewport(size)
	var made: App = await _battle_app(vp, size, safe, "real_%s_build" % label)
	var screen: BattleScreen = await _start_level(made, &"r1_l2")
	var where: String = "battle build phase at %s" % size
	_inside_and_big(screen, size, where)
	var cell_px: float = screen.map_view.scale.x * MapView.CELL
	check(cell_px >= (140.0 if not screen.landscape else 165.0), "%s: map cells are %.0f px" % [where, cell_px])
	check(screen.landscape == (label == "inner"), "%s: the layout follows the window" % where)
	var rect: Rect2 = screen.map_area.get_global_rect()
	check(rect.size.x >= 7.0 * cell_px - 1.0 and rect.size.y >= 10.0 * cell_px - 1.0, "%s: the whole map fits its slot" % where)
	if not screen.landscape:
		check(screen.hud.get_global_rect().end.y <= rect.position.y + 1.0, "%s: the HUD is above the map" % where)
		check(screen.hud.get_global_rect().position.y >= safe.position.y - 0.5, "%s: the HUD is inside the safe area" % where)
		check(screen.preview.get_global_rect().end.y <= safe.end.y + 0.5, "%s: the preview is inside the safe area" % where)
		check(screen.hud.call_button.get_global_rect().get_center().y < size.y * 0.5, "%s: the HUD is on top" % where)
		check(screen.preview.expanded, "%s: the preview is open in portrait too" % where)
	else:
		check(screen.hud.get_global_rect().position.x >= rect.end.x - 1.0, "%s: the HUD is in the side column" % where)
		check(screen.preview.get_global_rect().position.x >= rect.end.x - 1.0, "%s: the preview is in the side column" % where)
		check(screen.preview.expanded, "%s: the preview is open in landscape" % where)
	vp.queue_free()
	# A first sight card and the hint in a real layout.
	var vp2: SubViewport = _viewport(size)
	var fresh: App = (load("res://scenes/ui/app.tscn") as PackedScene).instantiate() as App
	Fx.wipe("real_%s_build" % label)
	fresh.game = BattleFixtures.game()
	fresh.store = SaveStore.new(Fx.dir("real_%s_build" % label))
	fresh.audio = Fx.audio()
	fresh.end_delay = 0.0
	vp2.add_child(fresh)
	await _frames()
	fresh.apply_layout(size, safe)
	fresh.start_level(&"r1_l1", false)
	await _frames(4)
	var first: BattleScreen = fresh.battle_screen()
	check(first.card_open(), "%s: level 1-1 opens its first sight card" % where)
	_inside_and_big(fresh.top_modal(), size, "%s first sight card" % where)
	for i: int in 3:
		(fresh.top_modal() as InfoCard).advance()
	await _frames(2)
	check(first.hint_banner.visible, "%s: the hint shows after the cards" % where)
	_inside_and_big(first, size, "%s with the hint" % where)
	vp2.queue_free()
	await _frames(2)


func _battle_panels_and_touch(size: Vector2, safe: Rect2, label: String) -> void:
	var vp: SubViewport = _viewport(size)
	var made: App = await _battle_app(vp, size, safe, "real_%s_touch" % label)
	var screen: BattleScreen = await _start_level(made, &"r1_l3")
	var b: Battle = screen.battle
	var where: String = "battle touches at %s" % size
	# A real tap on a build spot opens the build panel.
	var spot: Vector2i = b.level.spots[0]
	var map_scale: Vector2 = screen.map_view.scale
	var map_at: Vector2 = screen.map_view.position
	_touch(vp, _cell_center(screen, spot))
	await _frames(3)
	check(screen.context_panel() == screen.build_panel, "%s: a tap on a spot opens the build panel" % where)
	check(screen.selected_cell() == spot, "%s: and selects it" % where)
	# Opening the panel never resizes the map, and in landscape never moves it either (U6b).
	check(screen.map_view.scale.is_equal_approx(map_scale), "%s: opening the build panel keeps the map's scale (%s to %s)" % [where, map_scale, screen.map_view.scale])
	if screen.landscape:
		check(screen.map_view.position.is_equal_approx(map_at), "%s: opening the build panel does not move the map (%s to %s)" % [where, map_at, screen.map_view.position])
	if not screen.landscape:
		var sheet_top: float = screen.build_panel.get_global_rect().position.y
		check(sheet_top >= screen.hud.get_global_rect().end.y - 0.5, "%s: the sheet never covers the HUD (%s vs %s)" % [where, sheet_top, screen.hud.get_global_rect().end.y])
		_inside_and_big(screen.build_panel, size, "%s build panel" % where)
		check(screen.build_panel.get_global_rect().end.y <= safe.end.y + 0.5, "%s: the build sheet is inside the safe area" % where)
	# A real tap on Build builds.
	screen.build_panel.select_tower(&"pumpkin_catapult")
	await _frames(2)
	_touch(vp, screen.build_panel.build_button.get_global_rect().get_center())
	check(b.tower_at(spot) != null, "%s: a real tap on Build builds the tower" % where)
	await _frames(2)
	check(screen.context_panel() == null, "%s: the panel closed after building" % where)
	# The lowest spot: the sheet must not hide it, the map slides up.
	var lowest: Vector2i = b.level.spots[0]
	for cell: Vector2i in b.level.spots:
		if cell.y > lowest.y:
			lowest = cell
	b.gold = 2000
	b.place_tower(lowest, &"sling_post")
	b.upgrade_tower(lowest)
	await _frames(2)
	_touch(vp, _cell_center(screen, lowest))
	await _frames(40)
	check(screen.context_panel() == screen.tower_panel, "%s: a tap on a tower opens its panel" % where)
	if not screen.landscape:
		var sheet: Rect2 = screen.tower_panel.get_global_rect()
		var side: float = screen._cell_px()
		var cell_rect: Rect2 = Rect2(_cell_center(screen, lowest) - Vector2(side, side) * 0.5, Vector2(side, side))
		check(cell_rect.end.y <= sheet.position.y + 2.0, "%s: the tapped tower is above the sheet (%s vs %s)" % [where, cell_rect, sheet])
		check(cell_rect.position.y >= screen.hud.get_global_rect().end.y - 2.0, "%s: and below the HUD" % where)
		check(sheet.end.y <= safe.end.y + 0.5, "%s: the sheet is inside the safe area" % where)
		_inside_and_big(screen.tower_panel, size, "%s tower panel" % where)
	else:
		check(screen.tower_panel.get_global_rect().position.x >= screen.map_area.get_global_rect().end.x - 1.0, "%s: the panel is in the side column" % where)
	# A tap on bare ground closes the panel.
	var ground: Vector2i = Vector2i(-1, -1)
	var map_rect: Rect2 = screen.map_area.get_global_rect()
	var open_top: float = screen.tower_panel.get_global_rect().position.y if not screen.landscape else size.y
	for row: int in b.level.rows:
		for column: int in Sim.MAP_COLUMNS:
			var probe_cell: Vector2i = Vector2i(column, row)
			var at_cell: Vector2 = _cell_center(screen, probe_cell)
			if ground.x < 0 and b.level.kind_at(probe_cell) == LevelData.Kind.SCENERY and map_rect.has_point(at_cell) and at_cell.y < open_top - 60.0:
				ground = probe_cell
	check(ground.x >= 0, "%s: there is bare ground in sight" % where)
	_touch(vp, _cell_center(screen, ground))
	await _frames(2)
	check(screen.context_panel() == null, "%s: a tap on bare ground closes the panel" % where)
	# A creature panel during a wave, also while paused.
	b.upgrade_tower(lowest, 0)
	screen.hud.call_button.tapped.emit()
	screen.clock.speed = 3
	var guard: int = 0
	while b.enemies.is_empty() and guard < 300:
		await process_frame
		guard += 1
	await _frames(3)
	check(not b.enemies.is_empty(), "%s: a wave is running" % where)
	if not b.enemies.is_empty():
		screen.freeze()
		await _frames(40)
		var enemy: EnemyState = b.enemies[0]
		var view: MapView.CreatureView = screen.map_view._creatures[enemy.id]
		var at: Vector2 = screen.map_view.get_global_transform() * view.center
		check(screen.map_area.get_global_rect().has_point(at), "%s: the creature is on the map slot" % where)
		_touch(vp, at)
		await _frames(3)
		check(screen.context_panel() == screen.enemy_panel, "%s: a tap on a creature shows its numbers, also while paused" % where)
		if not screen.landscape:
			_inside_and_big(screen.enemy_panel, size, "%s creature panel" % where)
	vp.queue_free()
	await _frames(2)


func _battle_gate_drag(size: Vector2, safe: Rect2, label: String) -> void:
	var vp: SubViewport = _viewport(size)
	var made: App = await _battle_app(vp, size, safe, "real_%s_drag" % label)
	var data: Dictionary = BattleFixtures.game().levels[&"r1_l2"].to_data()
	data["gates"] = 2
	var level: LevelData = LevelData.from_data(data, BattleFixtures.game().catalog)
	var b: Battle = Battle.create(level, BattleFixtures.game().catalog, false, [] as Array[Dictionary])
	var saved: SavedGame = SavedGame.new()
	saved.mode = SavedGame.LEVEL
	saved.level_id = &"r1_l2"
	saved.battle = b
	made._begin(saved, false)
	await _frames(4)
	var screen: BattleScreen = made.battle_screen()
	var where: String = "gate drag at %s" % size
	var a: Vector2i = level.sockets[0]
	var c: Vector2i = level.sockets[1]
	var lift: Vector2 = Vector2(0.0, BattleScreen.GHOST_LIFT * screen._cell_px())
	# A tap places a gate, a tap takes it back.
	_touch(vp, _cell_center(screen, a))
	check(b.gates.size() == 1 and b.gates[0].cell == a, "%s: a real tap on a socket places a gate" % where)
	_touch(vp, _cell_center(screen, a))
	check(b.gates.is_empty(), "%s: a second tap takes it back" % where)
	# A drag from a socket with a gate moves it.
	_touch(vp, _cell_center(screen, a))
	await _frames(2)
	var path: Array[Vector2] = _line(_cell_center(screen, a), _cell_center(screen, c) + lift)
	_press(vp, path[0], true)
	for point: Vector2 in path:
		_motion(vp, point)
	await _frames(2)
	check(screen.is_dragging(), "%s: a drag from a placed gate is going on" % where)
	check(screen.drag_target() == c, "%s: the gate snaps to the other socket" % where)
	check(screen.ghost.visible, "%s: the carried gate shows" % where)
	_press(vp, path[path.size() - 1], false)
	await _frames(2)
	check(b.gates.size() == 1 and b.gates[0].cell == c, "%s: the drop moved the gate" % where)
	check(not screen.ghost.visible, "%s: the carried gate is gone after the drop" % where)
	# A second gate from the strip onto the first socket would close every road.
	var tray_from: Vector2 = screen.gate_tray.icon.get_global_rect().get_center()
	var drag_path: Array[Vector2] = _line(tray_from, _cell_center(screen, a) + lift)
	_press(vp, drag_path[0], true)
	for point: Vector2 in drag_path:
		_motion(vp, point)
	await _frames(2)
	check(screen.is_dragging(), "%s: a drag from the gate strip is going on" % where)
	check(screen.ghost.look == MapArt.Gate.REFUSED, "%s: the carried gate is crossed out over a refused socket" % where)
	_press(vp, drag_path[drag_path.size() - 1], false)
	await _frames(2)
	check(b.gates.size() == 1, "%s: the refused gate does not stay" % where)
	check(screen.gate_tray.feedback_text() == "That would close every road.", "%s: the sentence shows (%s)" % [where, screen.gate_tray.feedback_text()])
	# The gate strip takes a dropped gate back into the hand.
	var back_path: Array[Vector2] = _line(_cell_center(screen, c), screen.gate_tray.get_global_rect().get_center() + lift)
	_press(vp, back_path[0], true)
	for point: Vector2 in back_path:
		_motion(vp, point)
	_press(vp, back_path[back_path.size() - 1], false)
	await _frames(2)
	check(b.gates.is_empty(), "%s: a gate dropped on the strip goes back to the hand" % where)
	# Gates are locked during a wave.
	b.start_next_wave()
	await _frames(3)
	_touch(vp, _cell_center(screen, a))
	check(b.gates.is_empty(), "%s: no gate during a wave" % where)
	check(screen.gate_tray.feedback_text() == "Gates are locked until the wave is over.", "%s: the locked sentence shows" % where)
	vp.queue_free()
	await _frames(2)


func _battle_fold() -> void:
	var vp: SubViewport = _viewport(COVER)
	var made: App = await _battle_app(vp, COVER, COVER_SAFE, "real_fold")
	var screen: BattleScreen = await _start_level(made, &"r1_l2")
	var b: Battle = screen.battle
	Fx.build(screen, b.level.spots[0], &"sling_post")
	screen.close_context()
	_touch(vp, screen.hud.call_button.get_global_rect().get_center())
	screen.clock.speed = 2
	var guard: int = 0
	while b.enemies.size() < 2 and guard < 400:
		await process_frame
		guard += 1
	check(b.phase == Battle.Phase.WAVE and not screen.is_paused(), "fold: a wave is running")
	screen.tap_at(b.level.spots[0])
	var before: String = JSON.stringify(b.to_data())
	var tick: int = b.tick
	var parts: Array[int] = [screen.map_view.get_instance_id(), screen.hud.get_instance_id(), screen.tower_panel.get_instance_id()]
	vp.size = Vector2i(INNER)
	await _frames(3)
	check(screen.is_paused(), "fold: unfolding mid-wave pauses")
	check(made.top_modal() is PausePanel, "fold: on the Pause menu")
	check(screen.landscape, "fold: the window is near square, so the layout is landscape")
	check(screen.tower_panel.is_open() and screen.context_panel() == screen.tower_panel, "fold: the open panel stays open")
	check(screen.selected_cell() == b.level.spots[0], "fold: and the selection")
	check(JSON.stringify(b.to_data()) == before, "fold: the battle is untouched")
	check([screen.map_view.get_instance_id(), screen.hud.get_instance_id(), screen.tower_panel.get_instance_id()] == parts, "fold: no state node was replaced")
	check(screen.clock.speed == 2, "fold: the speed stays")
	await _frames(20)
	check(b.tick == tick, "fold: nothing moved while paused")
	var map_rect: Rect2 = screen.map_area.get_global_rect()
	check(map_rect.end.x <= INNER.x and screen.hud.get_global_rect().position.x >= map_rect.end.x - 1.0, "fold: map left, side column right")
	made.handle_back()
	await _frames(2)
	check(not screen.is_paused(), "fold: Resume goes on")
	await _frames(10)
	check(b.tick > tick, "fold: and time runs again")
	vp.size = Vector2i(COVER)
	await _frames(3)
	check(screen.is_paused() and not screen.landscape, "fold: folding again pauses and returns to portrait")
	check(screen.tower_panel.is_open(), "fold: still the same open panel")
	vp.queue_free()
	await _frames(2)


func _battle_back_and_pause() -> void:
	var vp: SubViewport = _viewport(COVER)
	var made: App = await _battle_app(vp, COVER, COVER_SAFE, "real_back")
	var screen: BattleScreen = await _start_level(made, &"r1_l1")
	check(made.handle_back() == &"modal", "back: in a battle opens Pause")
	await _frames(3)
	var pause: PausePanel = made.top_modal() as PausePanel
	check(pause != null, "back: the Pause menu is up")
	if pause != null:
		_inside_and_big(pause, COVER, "back: Pause over a battle")
		recorder.urls.clear()
		var coffee: CoffeeButton = pause.find_children("*", "CoffeeButton", true, false)[0] as CoffeeButton
		_touch(vp, coffee.get_global_rect().get_center())
		check(recorder.urls == ([Links.COFFEE_URL] as Array[String]), "back: the quiet coffee row in Pause hands over the address once, got %s" % [recorder.urls])
	var coffee_in_battle: int = 0
	for node: Node in screen.find_children("*", "CoffeeButton", true, false):
		coffee_in_battle += 1
	check(coffee_in_battle == 0, "back: the coffee button is not on the play screen")
	made.handle_back()
	await _frames(2)
	check(made.top_modal() == null and not screen.is_paused(), "back: back again resumes")
	vp.queue_free()
	await _frames(2)


## The end panel waits a moment after the last creature, and the back button skips the wait.
func _battle_end_delay() -> void:
	var vp: SubViewport = _viewport(COVER)
	var made: App = await _battle_app(vp, COVER, COVER_SAFE, "real_back")
	made.end_delay = 0.3
	var screen: BattleScreen = await _start_level(made, &"r1_l1")
	var win: Dictionary = {"won": true, "stars": 3, "lives_left": 19, "waves_cleared": 8, "abandoned": false, "relaxed": false}
	made._on_battle_ended(win)
	check(made.end_pending() and made.top_modal() == null, "end: the panel waits")
	check(made.saved_games.is_empty(), "end: but the saved game is already gone, so a kill cannot undo the win")
	check(made.progress.cleared(&"r1_l1"), "end: and the stars are already recorded")
	await _frames(5)
	check(made.top_modal() == null, "end: still waiting")
	await create_timer(0.5).timeout
	await _frames(3)
	check(made.top_modal() is EndPanel, "end: the panel shows after the delay")
	check(screen != null and made.end_pending() == false, "end: nothing is pending any more")
	_inside_and_big(made.top_modal(), COVER, "end panel over a battle")
	vp.queue_free()
	await _frames(2)


# The map cell floor (hard rule): on the Fold5 cover in portrait, map cells stay at least
# 48 dp in every state, on every region 1 map and on a 13 row map. The 13 row map keeps its
# bottom row scenery only, as the level rule asks (docs/ARCHITECTURE.md 2.4).

const TALL_GRID: PackedStringArray = [
	"...1...", "...#...", ".o.#.o.", ".#####.", ".G...G.", ".#.o.#.", ".#####.",
	"..o#o..", "...#...", ".o.#.o.", "...#...", "..oBo..", ".......",
]


## A real level with its map swapped for 13 rows.
func _tall_battle() -> Battle:
	var data: Dictionary = BattleFixtures.game().levels[&"r1_l5"].to_data()
	data["grid"] = Array(TALL_GRID)
	data["hint"] = {"text": "Tap a glowing spot to build a tower by the road.", "cell": [3, 5]}
	var level: LevelData = LevelData.from_data(data, BattleFixtures.game().catalog)
	check(level != null, "the 13 row test map is a valid level")
	if level == null:
		return null
	return Battle.create(level, BattleFixtures.game().catalog, false, [] as Array[Dictionary])


func _all_seen() -> Progress:
	var progress: Progress = Progress.new()
	for id: StringName in BattleFixtures.game().catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in BattleFixtures.game().catalog.enemy_ids():
		progress.mark_seen(id)
	for id: StringName in BattleFixtures.game().levels:
		progress.mark_seen(id)
	return progress


func _cell_dp(screen: BattleScreen) -> float:
	return screen.map_view.get_global_transform().get_scale().x * MapView.CELL / COVER_PX_PER_DP


## Puts the screen in one state of the mix and checks the cell floor and the layout.
func _floor_state(screen: BattleScreen, label: String, hint: bool, folded: bool, paused: bool, panel: int, notes: bool, wave: bool) -> void:
	var b: Battle = screen.battle
	if wave and b.phase == Battle.Phase.BUILD:
		b.start_next_wave()
		BattleFixtures.steps(b, 4)
	screen.clock.speed = 1
	if paused:
		screen.freeze()
	else:
		screen.resume()
	if hint:
		screen.hint_banner.show_hint(b.level.hint_text)
		screen.map_view.show_hint(b.level.hint_cell)
	else:
		screen.hint_banner.dismiss()
	if screen.preview.expanded == folded:
		screen.preview.toggle()
	screen.close_context()
	if panel == 1:
		for cell: Vector2i in b.level.spots:
			if b.tower_at(cell) == null:
				screen.show_build(cell)
	elif panel == 2:
		screen.show_tower(b.towers[0].cell)
	if notes:
		screen.hud.show_feedback("The wave is still arriving.")
		screen.gate_tray.show_feedback("Gates are locked until the wave is over.")
	else:
		screen.hud.clear_feedback()
		screen.gate_tray.clear_feedback()
	await _frames(3)
	var where: String = "%s: hint %s, preview %s, paused %s, panel %d, notes %s, wave %s" % [label, hint, "folded" if folded else "open", paused, panel, notes, wave]
	check(_cell_dp(screen) >= 48.0, "cells are %.1f dp (%s)" % [_cell_dp(screen), where])
	# The map as laid out, before the sheet slides it up to show a selected cell.
	var origin: Vector2 = screen.map_area.get_global_rect().position + screen._map_base
	var map_rect: Rect2 = Rect2(origin, Vector2(float(Sim.MAP_COLUMNS), float(b.level.rows)) * MapView.CELL * screen.map_view.get_global_transform().get_scale().x)
	check(map_rect.position.y >= screen.hud.get_global_rect().end.y - 1.0, "the map starts under the HUD (%s)" % where)
	check(map_rect.end.y <= COVER_SAFE.end.y + 1.0, "the whole map is inside the safe area (%s)" % where)
	check(map_rect.position.x >= -0.5 and map_rect.end.x <= COVER.x + 0.5, "the map fits the width (%s)" % where)
	check(screen.hud.get_global_rect().position.y >= COVER_SAFE.position.y - 0.5, "the HUD is inside the safe area (%s)" % where)
	for part: Control in [screen.hint_banner, screen.pause_strip, screen.preview, screen.hud.feedback_box, screen.gate_tray.feedback_box]:
		if part.is_visible_in_tree():
			var r: Rect2 = part.get_global_rect()
			check(r.position.y >= screen.hud.get_global_rect().end.y - 1.0, "the dock never covers the HUD (%s)" % where)
			check(r.end.y <= COVER_SAFE.end.y + 1.0, "the dock is inside the safe area (%s)" % where)
	_inside_and_big(screen, COVER, where)


# What stays in sight (every level file, cover portrait, test insets): the home, every build
# spot, every gate socket and every entrance, and any tower on a spot, in the default build
# state (gate chip, preview open or folded as it fits, no hint, no panel) for every wave's
# preview, and during a wave with the preview folded. The folded strip is one line. The hint
# never covers any of them, nor the highlighted cell. The Paused strip and the messages may
# cover more, but never the highlighted cell (docs/ARCHITECTURE.md 7.4).

func _cell_rect(screen: BattleScreen, cell: Vector2i) -> Rect2:
	var side: float = screen._cell_px()
	return Rect2(screen.map_view.get_global_transform() * (Vector2(cell) * MapView.CELL), Vector2(side, side)).grow(-3.0)


func _must_see(b: Battle) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(b.level.spots)
	cells.append_array(b.level.sockets)
	cells.append_array(b.level.entrances)
	cells.append(b.level.base)
	return cells


func _dock_rects(screen: BattleScreen) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for part: Control in [screen.hud.feedback_box, screen.gate_tray.feedback_box, screen.pause_strip, screen.preview]:
		if part.is_visible_in_tree():
			rects.append(part.get_global_rect())
	return rects


func _first_hit(screen: BattleScreen, cells: Array[Vector2i], rects: Array[Rect2]) -> String:
	for cell: Vector2i in cells:
		var area: Rect2 = _cell_rect(screen, cell)
		for r: Rect2 in rects:
			if r.intersects(area):
				return "cell %s (rect %s) is covered by %s" % [cell, area, r]
		if area.end.y > COVER_SAFE.end.y or area.position.y < screen.hud.get_global_rect().end.y - 4.0:
			return "cell %s is outside the map slot" % cell
	return ""


## The folded strip is one line: its chips sit side by side inside it, the chips that do not
## fit are counted by the "+N" chip, and it is no taller than one chip.
func _strip_is_one_line(screen: BattleScreen, where: String) -> void:
	var strip: StripRow = screen.preview.strip
	check(strip != null, "%s: a folded preview has its strip" % where)
	if strip == null:
		return
	var rect: Rect2 = strip.get_global_rect()
	check(rect.size.y > 0.0 and rect.size.y <= 100.0, "%s: the strip is one line tall (%.0f px)" % [where, rect.size.y])
	check(strip.visible_chips() > 0 or strip.chip_count() == 0, "%s: the strip shows at least one chip" % where)
	var last_end: float = rect.position.x
	for control: Control in strip.chips():
		if not control.visible:
			continue
		var box: Rect2 = control.get_global_rect()
		check(rect.grow(1.0).encloses(box), "%s: a strip chip is inside the strip (%s in %s)" % [where, box, rect])
		check(box.position.x >= last_end - 1.0, "%s: strip chips do not overlap" % where)
		last_end = box.end.x
	var hidden: int = strip.chip_count() - strip.visible_chips()
	if hidden > 0:
		check(strip.more_text() == "+%d" % hidden, "%s: the +N chip counts the %d hidden (%s)" % [where, hidden, strip.more_text()])
		var tag: Rect2 = strip.more_chip.get_global_rect()
		check(rect.grow(1.0).encloses(tag), "%s: the +N chip is inside the strip (%s in %s)" % [where, tag, rect])
		check(tag.position.x >= last_end - 1.0, "%s: the +N chip comes after the last chip" % where)
	else:
		check(strip.more_text().is_empty(), "%s: no +N chip when every group shows" % where)
	check(screen.preview.get_global_rect().end.y <= COVER_SAFE.end.y + 0.5, "%s: the folded preview is inside the safe area" % where)


## The preview in its build state after the screen has decided whether it fits. Folded: it did
## not fit, and the open form measured now really is too tall. Open: it sits under the map.
func _preview_decision(screen: BattleScreen, where: String) -> void:
	check(screen._fit_wait == 0 and screen.preview.modulate.a == 1.0, "%s: the preview is decided and shown" % where)
	if screen.preview.expanded:
		check(screen.preview.get_global_rect().position.y >= screen._map_bottom() - 1.0, "%s: an open preview sits under the map (top %.0f, map bottom %.0f)" % [where, screen.preview.get_global_rect().position.y, screen._map_bottom()])
		return
	_strip_is_one_line(screen, where)
	screen.preview.set_open(true)
	await _frames(3)
	check(not screen.preview_fits(), "%s: the preview was folded, so its open form must not fit (%.0f px)" % [where, screen.preview.get_combined_minimum_size().y])
	screen.preview.set_open(false)
	await _frames(3)


func _dock_level(id: StringName, b: Battle, hint_text: String = "") -> void:
	var hint: String = hint_text if not hint_text.is_empty() else b.level.hint_text
	b.gold = 5000
	for cell: Vector2i in b.level.spots:
		b.place_tower(cell, b.level.towers[0])
	var vp: SubViewport = _viewport(COVER)
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, _all_seen())
	await _hosted(vp, screen, COVER, COVER_SAFE)
	await _frames(6)
	# A Twist says its rule as a hint at its fresh start. The default build state has none.
	screen.hint_banner.dismiss()
	var must: Array[Vector2i] = _must_see(b)
	check(screen.gate_tray.visible == (b.gates_in_hand + b.gates.size() > 0), "%s: the gate chip shows when the battle has gates" % id)
	if screen.gate_tray.visible:
		var chip: Rect2 = screen.gate_tray.get_global_rect()
		check(screen.hud.get_global_rect().encloses(chip), "%s: the gate chip is inside the HUD" % id)
		check(chip.size.x >= 150.0 and chip.size.y >= 150.0, "%s: the gate chip is a 48 dp target (%s)" % [id, chip.size])
	# 1. The default build state, with every wave's preview, open or folded as it fits.
	for wave: int in b.wave_count():
		b.waves_started = wave
		screen.preview.refresh()
		screen._start_fit()
		await _frames(screen.FIT_FRAMES + 3)
		var where: String = "%s wave %d, default build state" % [id, wave + 1]
		await _preview_decision(screen, where)
		var hit: String = _first_hit(screen, must, _dock_rects(screen))
		check(hit.is_empty(), "%s: %s" % [where, hit])
	b.waves_started = 0
	screen.preview.refresh()
	screen._start_fit()
	await _frames(screen.FIT_FRAMES + 3)
	# 2. With the hint: at the top of the dock when that stays under the map, else on a free
	# band of rows, else at the top of the dock. It never covers what matters.
	screen.hint_banner.show_hint(hint)
	screen.map_view.show_hint(b.level.hint_cell)
	screen._start_fit()
	await _frames(screen.FIT_FRAMES + 3)
	var important: Array[Vector2i] = must.duplicate()
	if b.level.hint_cell.x >= 0:
		important.append(b.level.hint_cell)
	var hint_rect: Rect2 = screen.hint_banner.get_global_rect()
	var rects: Array[Rect2] = _dock_rects(screen)
	if screen.hint_banner.get_parent() == screen._dock:
		var under_map: bool = hint_rect.position.y >= screen._map_bottom() - 1.0
		check(under_map or screen._free_band_top(HintBanner.HEIGHT) < 0.0, "%s: the hint is in the dock over the map although a free band exists" % id)
	else:
		check(screen.hint_banner.get_parent() == screen._hint_layer, "%s: the hint is in the dock or on the map layer" % id)
		rects.append(hint_rect)
	var hint_hit: String = _first_hit(screen, important, rects)
	if screen.hint_banner.get_parent() == screen._dock:
		for cell: Vector2i in important:
			if hint_rect.intersects(_cell_rect(screen, cell)):
				hint_hit = "cell %s is covered by the hint in the dock %s" % [cell, hint_rect]
	check(hint_hit.is_empty(), "%s with the hint: %s" % [id, hint_hit])
	check(hint_rect.size.y >= 150.0, "%s: the hint is a 48 dp target (%s)" % [id, hint_rect.size.y])
	check(COVER_SAFE.encloses(hint_rect), "%s: the hint is inside the safe area (%s)" % [id, hint_rect])
	# 3. The Paused strip and the messages may cover more, but never the highlighted cell.
	screen.freeze()
	screen.hud.show_feedback("The wave is still arriving.")
	screen.gate_tray.show_feedback("Gates are locked until the wave is over.")
	await _frames(3)
	var soft_rects: Array[Rect2] = _dock_rects(screen)
	soft_rects.append(screen.hint_banner.get_global_rect())
	if b.level.hint_cell.x >= 0:
		var soft: String = _first_hit(screen, [b.level.hint_cell] as Array[Vector2i], soft_rects)
		check(soft.is_empty(), "%s paused with messages: %s" % [id, soft])
	screen.resume()
	screen.hint_banner.dismiss()
	screen.hud.clear_feedback()
	screen.gate_tray.clear_feedback()
	# 4. During a wave, with the preview folded and its strip one line.
	b.start_next_wave()
	BattleFixtures.steps(b, 4)
	await _frames(3)
	check(not screen.preview.expanded, "%s: the preview is folded during a wave" % id)
	_strip_is_one_line(screen, "%s during a wave" % id)
	var wave_hit: String = _first_hit(screen, must, _dock_rects(screen))
	check(wave_hit.is_empty(), "%s during a wave: %s" % [id, wave_hit])
	vp.queue_free()
	await _frames(2)


## A wave with eight groups cannot fit one line: the strip shows what fits and a +N chip.
func _dock_many_groups() -> void:
	var groups: Array = []
	for enemy: String in ["scamp", "pip", "skitter", "flitter", "shellback", "scamp", "pip", "skitter"]:
		groups.append({"enemy": enemy, "count": 12, "entrance": 1, "at_ms": 0, "every_ms": 500})
	var b: Battle = BattleFixtures.battle_with_first_wave(groups, &"r1_l5")
	var vp: SubViewport = _viewport(COVER)
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, _all_seen())
	await _hosted(vp, screen, COVER, COVER_SAFE)
	await _frames(8)
	check(not screen.preview.expanded, "eight groups: the open preview does not fit under the map")
	_strip_is_one_line(screen, "eight groups")
	var strip: StripRow = screen.preview.strip
	if strip != null:
		check(strip.chip_count() == 8, "eight groups: eight chips (%d)" % strip.chip_count())
		check(strip.visible_chips() < 8 and strip.visible_chips() >= 2, "eight groups: some chips fit and some do not (%d)" % strip.visible_chips())
		check(strip.more_text().begins_with("+"), "eight groups: the +N chip shows (%s)" % strip.more_text())
	# A tap on the strip opens the full list over the map, a tap on its header folds it again.
	screen.preview.header.tapped.emit()
	await _frames(3)
	check(screen.preview.expanded, "eight groups: a tap on the strip opens the preview")
	check(screen.preview.rows.size() == 8 or screen.preview.rows.size() > 0, "eight groups: the open preview lists the groups")
	screen.preview.header.tapped.emit()
	await _frames(3)
	check(not screen.preview.expanded, "eight groups: a tap on the header folds it")
	# The choice holds until the layout changes, then the screen decides again.
	screen.preview.header.tapped.emit()
	await _frames(3)
	screen.apply_layout(COVER, COVER_SAFE)
	await _frames(screen.FIT_FRAMES + 3)
	check(not screen.preview.expanded, "eight groups: a layout change decides again, and it still does not fit")
	vp.queue_free()
	await _frames(2)


## The 13 row fixture, whose bottom row is scenery: the strip covers part of that row only.
func _dock_tall() -> void:
	var b: Battle = _tall_battle()
	if b == null:
		return
	b.gold = 5000
	for cell: Vector2i in b.level.spots:
		b.place_tower(cell, &"sling_post")
	var vp: SubViewport = _viewport(COVER)
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, _all_seen())
	await _hosted(vp, screen, COVER, COVER_SAFE)
	await _frames(8)
	var bottom_row: int = b.level.rows - 1
	for x: int in Sim.MAP_COLUMNS:
		check(b.level.kind_at(Vector2i(x, bottom_row)) == LevelData.Kind.SCENERY, "tall: the bottom row is scenery at column %d" % x)
	await _preview_decision(screen, "tall, default build state")
	check(not screen.preview.expanded, "tall: the preview starts folded on a 13 row map")
	_strip_is_one_line(screen, "tall")
	var must: Array[Vector2i] = _must_see(b)
	var hit: String = _first_hit(screen, must, _dock_rects(screen))
	check(hit.is_empty(), "tall: %s" % hit)
	screen.hint_banner.show_hint(b.level.hint_text)
	screen.map_view.show_hint(b.level.hint_cell)
	await _frames(3)
	var rects: Array[Rect2] = _dock_rects(screen)
	rects.append(screen.hint_banner.get_global_rect())
	var important: Array[Vector2i] = must.duplicate()
	important.append(b.level.hint_cell)
	var hint_hit: String = _first_hit(screen, important, rects)
	check(hint_hit.is_empty(), "tall with the hint: %s" % hint_hit)
	screen.hint_banner.dismiss()
	b.start_next_wave()
	BattleFixtures.steps(b, 4)
	await _frames(3)
	_strip_is_one_line(screen, "tall during a wave")
	var wave_hit: String = _first_hit(screen, must, _dock_rects(screen))
	check(wave_hit.is_empty(), "tall during a wave: %s" % wave_hit)
	vp.queue_free()
	await _frames(2)


func _stays_in_sight() -> void:
	for id: StringName in BattleFixtures.all_level_ids():
		var b: Battle = BattleFixtures.file_battle(id)
		check(b != null, "%s makes a battle" % id)
		if b != null:
			await _dock_level(id, b)
			# The Twist of the level, with its rule as the first hint (RULES 13).
			if not b.level.twist_effects.is_empty():
				var twist: Battle = Battle.create(b.level, BattleFixtures.game().catalog, false, b.level.twist_effects)
				check(twist != null, "%s makes a Twist battle" % id)
				if twist != null:
					await _dock_level(StringName("%s twist" % id), twist, "Twist: %s" % b.level.twist_text)
	await _dock_many_groups()
	await _dock_tall()


func _cell_floor() -> void:
	await _stays_in_sight()
	var level_ids: Array[String] = ["r1_l1", "r1_l2", "r1_l3", "r1_l4", "r1_l5", "r1_l6", "tall"]
	for level_id: String in level_ids:
		var b: Battle = _tall_battle() if level_id == "tall" else BattleFixtures.battle(StringName(level_id))
		if b == null:
			continue
		b.gold = 5000
		for i: int in mini(2, b.level.spots.size()):
			b.place_tower(b.level.spots[i], &"sling_post")
		var vp: SubViewport = _viewport(COVER)
		var screen: BattleScreen = BattleScreen.new()
		screen.setup(b, null, _all_seen())
		await _hosted(vp, screen, COVER, COVER_SAFE)
		check(not screen.landscape, "%s: the cover is portrait" % level_id)
		var full: bool = level_id == "tall" or level_id == "r1_l5"
		if full:
			for hint: bool in [true, false]:
				for folded: bool in [false, true]:
					for paused: bool in [false, true]:
						for panel: int in [0, 1, 2]:
							for notes: bool in [false, true]:
								await _floor_state(screen, level_id, hint, folded, paused, panel, notes, false)
			# A running wave too: the strip, the panels and the messages.
			for folded: bool in [true, false]:
				for paused: bool in [false, true]:
					for panel: int in [0, 2]:
						await _floor_state(screen, level_id, false, folded, paused, panel, true, true)
		else:
			await _floor_state(screen, level_id, true, false, false, 0, false, false)
			await _floor_state(screen, level_id, true, false, true, 1, true, false)
			await _floor_state(screen, level_id, false, true, true, 0, true, true)
		vp.queue_free()
		await _frames(2)


# Task U1 in a real tree: the call button ring, the gate chip's tap, Pause with its star
# lines, and the preview deciding again when the layout changes.

func _u1_real() -> void:
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		var size: Vector2 = pair[0]
		var safe: Rect2 = pair[1]
		var label: String = pair[2]
		var tag: String = "real_%s_u1" % label
		var vp: SubViewport = _viewport(size)
		var made: App = await _battle_app(vp, size, safe, tag)
		var screen: BattleScreen = await _start_level(made, &"r2_l1")
		var b: Battle = screen.battle
		var where: String = "u1 at %s" % size
		check(not screen.hud.call_ring.visible, "%s: no ring in a build phase" % where)
		check(Fx.build(screen, b.level.spots[0], &"sling_post"), "%s: a first tower" % where)
		check(Fx.build(screen, b.level.spots[1], &"pumpkin_catapult"), "%s: a second tower" % where)
		screen.close_context()
		await _frames(2)
		_touch(vp, screen.hud.call_button.get_global_rect().get_center())
		check(b.phase == Battle.Phase.WAVE, "%s: a real tap on Start wave starts it" % where)
		screen.clock.speed = 3
		var guard: int = 0
		while b.next_wave_info()["refusal"] != &"" and guard < 400 and b.phase == Battle.Phase.WAVE:
			await process_frame
			guard += 1
		await _frames(3)
		check(b.next_wave_info()["refusal"] == &"", "%s: an early call is offered" % where)
		check(screen.hud.call_ring.visible, "%s: the ring shows while an early call is offered" % where)
		var button_rect: Rect2 = screen.hud.call_button.get_global_rect()
		var ring_rect: Rect2 = screen.hud.call_ring.get_global_rect()
		check(ring_rect.encloses(button_rect), "%s: the ring is around the button (%s around %s)" % [where, ring_rect, button_rect])
		check(Rect2(Vector2.ZERO, size).grow(0.6).encloses(ring_rect), "%s: the ring is inside the screen" % where)
		check(screen.hud.call_button.theme_type_variation == &"Button", "%s: the glowing button is not honey" % where)
		_touch(vp, button_rect.get_center())
		await _frames(3)
		check(b.waves_started == 2, "%s: a real tap on the glowing button calls the wave" % where)
		check(not screen.hud.call_ring.visible, "%s: the first early call puts the ring away" % where)
		# Pause with its star lines, inside the screen and the safe area.
		screen.pause()
		await _frames(3)
		var pause: PausePanel = made.top_modal() as PausePanel
		check(pause != null and pause.star_lines.size() == 3, "%s: Pause shows three star lines" % where)
		if pause != null:
			_inside_and_big(pause, size, "%s Pause with star lines" % where)
			check(safe.grow(0.6).encloses(pause.card.get_global_rect()), "%s: the Pause card is inside the safe area (%s)" % [where, pause.card.get_global_rect()])
			# QA 2026-10-26 p3: a tapped row keeps no lighter look, so hover draws as normal.
			var rows: Array[Node] = pause.find_children("*", "TapButton", true, false)
			check(rows.size() >= 5, "%s: the Pause rows were found" % where)
			for node: Node in rows:
				var row_button: TapButton = node as TapButton
				check(row_button.get_theme_stylebox(&"hover") == row_button.get_theme_stylebox(&"normal"), "%s: the Pause button '%s' draws no hover look" % [where, row_button.text])
			for line: StarLine in pause.star_lines:
				check(line.sentence.get_global_rect().size.x >= 200.0, "%s: a star sentence has room (%.0f px)" % [where, line.sentence.get_global_rect().size.x])
		made.handle_back()
		await _frames(2)
		vp.queue_free()
		Fx.wipe(tag)
		await _frames(2)
	await _u1_chip_and_fold()


func _u1_chip_and_fold() -> void:
	var vp: SubViewport = _viewport(COVER)
	var made: App = await _battle_app(vp, COVER, COVER_SAFE, "real_cover_u1")
	var screen: BattleScreen = await _start_level(made, &"r1_l2")
	var chip: GateTray = screen.gate_tray
	check(chip.chip and chip.visible, "chip: the portrait gate chip shows")
	_touch(vp, chip.get_global_rect().get_center())
	await _frames(2)
	check(chip.feedback_text() == "Drag one onto a marked road, or tap a marked road.", "chip: a real tap shows its sentence (%s)" % chip.feedback_text())
	check(chip.feedback_box.is_visible_in_tree(), "chip: the sentence is on screen")
	check(screen.battle.gates.is_empty(), "chip: and a tap placed nothing")
	vp.queue_free()
	Fx.wipe("real_cover_u1")
	await _frames(2)
	# The preview decides again after a fold and an unfold.
	var vp2: SubViewport = _viewport(COVER)
	var made2: App = await _battle_app(vp2, COVER, COVER_SAFE, "real_cover_u1")
	var tall: BattleScreen = await _start_level(made2, &"r2_l6")
	await _frames(8)
	check(not tall.preview.expanded, "fold: a 13 row map starts folded on the cover")
	vp2.size = Vector2i(INNER)
	await _frames(3)
	made2.apply_layout(INNER, INNER_SAFE)
	await _frames(8)
	check(tall.landscape and tall.preview.expanded, "fold: the landscape layout opens the preview")
	check(tall.preview.modulate.a == 1.0, "fold: and shows it")
	vp2.size = Vector2i(COVER)
	await _frames(3)
	made2.apply_layout(COVER, COVER_SAFE)
	await _frames(10)
	check(not tall.landscape and not tall.preview.expanded, "fold: back on the cover it is folded again (landscape %s, open %s, wait %d, alpha %s, dock end %.0f, map bottom %.0f, min %.0f)" % [tall.landscape, tall.preview.expanded, tall._fit_wait, tall.preview.modulate.a, tall._dock.get_global_rect().end.y, tall._map_bottom(), tall.preview.get_combined_minimum_size().y])
	check(tall.preview.modulate.a == 1.0 and tall._fit_wait == 0, "fold: decided and shown")
	check(tall.battle.phase == Battle.Phase.BUILD and tall.battle.waves_started == 0, "fold: nothing else changed")
	vp2.queue_free()
	Fx.wipe("real_cover_u1")
	await _frames(2)


# Task U2 in a real tree: the Twist and run pages at both sizes, the draft sheet and its real
# touches, and the dock test on run maps (13 rows with a scenery bottom row) played through
# 18 waves with their cards, risk chips included.

func _u2_real() -> void:
	await _u2_pages()
	await _u2_draft()
	await _dock_runs()


## Every visible button is 48 dp and nothing runs off the sides. A page scrolls, so its height is free.
func _sides_and_buttons(root: Node, size: Vector2, where: String) -> void:
	var found: int = 0
	for node: Node in root.find_children("*", "BaseButton", true, false):
		var button: BaseButton = node as BaseButton
		if not button.is_visible_in_tree() or button.size.x <= 0.0:
			continue
		found += 1
		check(button.size.x >= Layout.MIN_TOUCH - 0.5 and button.size.y >= Layout.MIN_TOUCH - 0.5, "%s: a button is under 48 dp (%s)" % [where, button.size])
		var rect: Rect2 = button.get_global_rect()
		check(rect.position.x >= -0.5 and rect.end.x <= size.x + 0.5, "%s: a button runs off the side %s" % [where, rect])
	check(found > 0, "%s has buttons" % where)


func _u2_pages() -> void:
	var game: GameData = BattleFixtures.game()
	var data: RunData = RunFx.run_data()
	var open: Progress = Progress.new()
	open.record_level(&"r1_l2", 7)
	var cleared: Progress = Progress.new()
	cleared.record_level(&"r1_l2", 7)
	cleared.record_twist(&"r1_l2")
	var twist_win: Dictionary = {"won": true, "stars": 0, "lives_left": 12, "waves_cleared": 8, "abandoned": false, "relaxed": false, "twist": true}
	var twist_loss: Dictionary = {"won": false, "stars": 0, "lives_left": 0, "waves_cleared": 3, "abandoned": false, "relaxed": false, "twist": true}
	var run_win: Dictionary = {"won": true, "waves": 18, "lives": 9, "reached": 18, "risks": 2}
	var run_loss: Dictionary = {"won": false, "waves": 7, "lives": 0, "reached": 8, "risks": 0}
	var best: Dictionary = {"won": false, "waves": 9, "lives": 0}
	var pages: Array[Array] = [
		["twist card", true, func() -> Control: return LevelCard.new(game, open, &"r1_l2", false)],
		["twist card cleared", true, func() -> Control: return LevelCard.new(game, cleared, &"r1_l2", false)],
		["twist card saved", true, func() -> Control: return LevelCard.new(game, open, &"r1_l2", true, true, true)],
		["run card", true, func() -> Control: return RunCard.new(game, data)],
		["run card saved", true, func() -> Control: return RunCard.new(game, data, false, "", {}, 0, "Your saved run is on wave 4 of 18.")],
		["daily card", true, func() -> Control: return RunCard.new(game, data, true, "2026-10-24", best, 3)],
		["daily card bad date", true, func() -> Control: return RunCard.new(game, data, true, "", {}, 0)],
		["twist end win", false, func() -> Control: return EndPanel.new(game, &"r1_l2", twist_win, 0, &"")],
		["twist end loss", false, func() -> Control: return EndPanel.new(game, &"r1_l2", twist_loss, 0, &"")],
		["run end win", false, func() -> Control: return RunEndPanel.new(game, run_win)],
		["run end loss", false, func() -> Control: return RunEndPanel.new(game, run_loss)],
		["daily end", false, func() -> Control: return RunEndPanel.new(game, run_loss, false, "2026-10-24", best, 3)],
	]
	for pair: Array in [[COVER, COVER_SAFE], [INNER, INNER_SAFE]]:
		var size: Vector2 = pair[0]
		for page: Array in pages:
			var vp: SubViewport = _viewport(size)
			var made: Callable = page[2]
			var screen: Control = made.call()
			await _hosted(vp, screen, size, pair[1])
			var where: String = "%s at %s" % [page[0], size]
			_sides_and_buttons(screen, size, where)
			if not bool(page[1]):
				_inside_and_big(screen, size, where)
				check((pair[1] as Rect2).grow(0.6).encloses((screen as Modal).card.get_global_rect()), "%s: the card is inside the safe area" % where)
			vp.queue_free()
			await _frames(1)


## A run on the fixture data in a real battle screen, with its first card owed.
func _run_screen(vp: SubViewport, size: Vector2, safe: Rect2, run_seed: int) -> BattleScreen:
	var data: RunData = RunFx.run_data()
	var session: RunSession = RunSession.start(run_seed, "", false, data.pool({}), data, RunFx.catalog())
	check(session != null, "the fixture run %d starts" % run_seed)
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(session.battle, null, _all_seen())
	screen.set_run(session)
	await _hosted(vp, screen, size, safe)
	await _frames(4)
	return screen


## Starts the next wave with the HUD button and plays it out with plenty of lives.
func _play_run_wave(screen: BattleScreen) -> void:
	var b: Battle = screen.battle
	var started: int = b.waves_started
	screen.hud.call_button.tapped.emit()
	check(b.waves_started == started + 1, "wave %d started from the HUD button" % (started + 1))
	b.lives = 99
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < 40000:
		b.step()
		guard += 1
	await _frames(3)


func _u2_draft() -> void:
	for pair: Array in [[COVER, COVER_SAFE], [INNER, INNER_SAFE]]:
		var size: Vector2 = pair[0]
		var safe: Rect2 = pair[1]
		var vp: SubViewport = _viewport(size)
		var screen: BattleScreen = await _run_screen(vp, size, safe, 5)
		var where: String = "draft at %s" % size
		check(not screen.draft_is_open(), "%s: no card is owed before the first wave" % where)
		await _play_run_wave(screen)
		check(screen.draft_is_open(), "%s: the draft opens after the first wave" % where)
		var panel: DraftPanel = screen.draft_panel
		check(panel.offered().size() == 3, "%s: three cards (%d)" % [where, panel.offered().size()])
		check(panel.is_visible_in_tree(), "%s: the panel shows" % where)
		var rect: Rect2 = panel.get_global_rect()
		check(safe.grow(0.6).encloses(rect), "%s: the draft is inside the safe area (%s)" % [where, rect])
		if not screen.landscape:
			check(rect.position.y >= screen.hud.get_global_rect().end.y - 1.0, "%s: the sheet never covers the HUD" % where)
			check(not screen._dock_wrap.visible, "%s: the dock waits while the sheet is open" % where)
		else:
			check(screen.hud.get_global_rect().end.y <= rect.position.y + 1.0, "%s: the side column puts the draft under the HUD" % where)
		for id: StringName in panel.offered():
			var row: Rect2 = panel.rows[id].get_global_rect()
			check(row.size.y >= Layout.MIN_TOUCH, "%s: a card is a 48 dp target (%.0f px)" % [where, row.size.y])
			check(rect.grow(1.0).encloses(row), "%s: a card is inside the panel" % where)
		_sides_and_buttons(panel, size, where)
		# Real touches: a tap on a card chooses it, a tap on Take adds it.
		var first: StringName = panel.offered()[1]
		_touch(vp, panel.rows[first].get_global_rect().get_center())
		await _frames(2)
		check(panel.selected == first, "%s: a real tap chooses a card" % where)
		check(screen.run.picks.is_empty(), "%s: and takes nothing yet" % where)
		check(panel.take_button.theme_type_variation == &"PrimaryButton", "%s: Take turns honey" % where)
		_touch(vp, panel.take_button.get_global_rect().get_center())
		await _frames(3)
		check(screen.run.picks == ([first] as Array[StringName]), "%s: a real tap on Take adds the card (%s)" % [where, screen.run.picks])
		check(not screen.draft_is_open(), "%s: the draft closes" % where)
		# The back button never closes a draft that is owed.
		await _play_run_wave(screen)
		check(screen.draft_is_open(), "%s: the second draft opens" % where)
		check(not screen.close_panel_for_back(), "%s: back does not close the draft" % where)
		vp.queue_free()
		await _frames(2)
	await _u2_draft_fold()


## Folding with a draft open and a half-made choice keeps everything.
func _u2_draft_fold() -> void:
	var vp: SubViewport = _viewport(COVER)
	var screen: BattleScreen = await _run_screen(vp, COVER, COVER_SAFE, 5)
	await _play_run_wave(screen)
	var offers: Array[StringName] = screen.draft_panel.offered()
	screen.draft_panel.select(offers[2])
	var before: String = JSON.stringify(screen.battle.to_data()) + JSON.stringify(screen.run.to_data())
	vp.size = Vector2i(INNER)
	await _frames(3)
	screen.apply_layout(INNER, INNER_SAFE)
	await _frames(4)
	check(screen.landscape and screen.draft_is_open(), "fold: the draft stays open on the inner screen")
	check(screen.draft_panel.offered() == offers and screen.draft_panel.selected == offers[2], "fold: same offers, same choice")
	check(INNER_SAFE.grow(0.6).encloses(screen.draft_panel.get_global_rect()), "fold: the draft is inside the safe area")
	vp.size = Vector2i(COVER)
	await _frames(3)
	screen.apply_layout(COVER, COVER_SAFE)
	await _frames(4)
	check(not screen.landscape and screen.draft_is_open() and screen.draft_panel.selected == offers[2], "fold: and back again")
	check(JSON.stringify(screen.battle.to_data()) + JSON.stringify(screen.run.to_data()) == before, "fold: nothing else changed")
	vp.queue_free()
	await _frames(2)


func _dock_runs() -> void:
	for run_seed: int in [3, 11, 29]:
		await _dock_run(run_seed)


func _is_risk_card(id: StringName) -> bool:
	return String(RunFx.run_data().card(id).get("kind", "")) == "risk"


## A fixture run on the cover: every build phase of an 18 wave run, with its cards picked
## through the draft (a risk card on some waves, whenever one is offered), checked as the dock
## test checks a level: the home, spots, sockets, entrances and towers stay in sight, the folded
## strip is one line, and a waiting risk card shows first.
func _dock_run(run_seed: int) -> void:
	var vp: SubViewport = _viewport(COVER)
	var screen: BattleScreen = await _run_screen(vp, COVER, COVER_SAFE, run_seed)
	var b: Battle = screen.battle
	var tag: String = "run %d" % run_seed
	check(b.level.rows == 13, "%s: a run map has 13 rows" % tag)
	for x: int in Sim.MAP_COLUMNS:
		check(b.level.kind_at(Vector2i(x, b.level.rows - 1)) == LevelData.Kind.SCENERY, "%s: the bottom row is scenery at column %d" % [tag, x])
	var must: Array[Vector2i] = _must_see(b)
	var saw_risk: bool = false
	for wave: int in 18:
		var where: String = "%s wave %d" % [tag, wave + 1]
		# The cards owed: the sheet is open and the dock waits; pick one after the other.
		var guard: int = 0
		while screen.draft_is_open() and guard < 6:
			guard += 1
			var offers: Array[StringName] = screen.draft_panel.offered()
			check(not screen._dock_wrap.visible, "%s: the dock waits for the card" % where)
			check(COVER_SAFE.grow(0.6).encloses(screen.draft_panel.get_global_rect()), "%s: the draft sheet is inside the safe area (%s)" % [where, screen.draft_panel.get_global_rect()])
			var choice: StringName = offers[0]
			for id: StringName in offers:
				if wave % 3 == 1 and _is_risk_card(id):
					choice = id
			screen.draft_panel.rows[choice].tapped.emit()
			screen.draft_panel.take_button.tapped.emit()
			await _frames(2)
		check(not screen.draft_is_open(), "%s: every owed card was picked" % where)
		b.gold = 20000
		for cell: Vector2i in b.level.spots:
			b.place_tower(cell, &"sling_post")
		# The default build state has no message: "Wave N cleared" is gone after its 3 s.
		screen.hud.clear_feedback()
		screen.gate_tray.clear_feedback()
		await _frames(screen.FIT_FRAMES + 3)
		await _preview_decision(screen, where)
		var hit: String = _first_hit(screen, must, _dock_rects(screen))
		check(hit.is_empty(), "%s: %s" % [where, hit])
		if screen.run.risk_card() != &"":
			saw_risk = true
			check(screen.preview.risk_name != "", "%s: a waiting risk card shows in the preview" % where)
			if screen.preview.expanded:
				check(screen.preview.risk_row != null and screen.preview.get_global_rect().encloses(screen.preview.risk_row.get_global_rect()), "%s: the risk row is inside the open preview" % where)
			elif screen.preview.strip != null:
				check(screen.preview.strip.chips()[0] == screen.preview.risk_chip and screen.preview.risk_chip.visible, "%s: the risk chip comes first and shows" % where)
		await _play_run_wave(screen)
		if b.phase == Battle.Phase.WON or b.phase == Battle.Phase.LOST:
			break
	check(saw_risk, "%s: a risk card waited at least once" % tag)
	vp.queue_free()
	await _frames(2)


# Task U3 in a real tree: the HUD with the biggest numbers a tampered save could hold, and the
# dock test on the run maps of ten fixed seeds with the real data.

func _u3_real() -> void:
	await _hud_extremes()
	await _dock_real_runs()
	await _u3_app_runs()


## Lives and gold far beyond anything a player reaches. The HUD must stay inside the screen, the
## numbers inside the HUD, and nothing may push the pause button or the speed buttons out.
func _hud_extremes() -> void:
	var cases: Array[Vector2i] = [Vector2i(20, 300), Vector2i(999, 99999), Vector2i(1000000, 1000000000), Vector2i(999, 1000000000)]
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		var size: Vector2 = pair[0]
		var safe: Rect2 = pair[1]
		for numbers: Vector2i in cases:
			for level_id: StringName in [&"r1_l1", &"r1_l2"]:
				var b: Battle = BattleFixtures.battle(level_id)
				b.lives = numbers.x
				b.gold = numbers.y
				var vp: SubViewport = _viewport(size)
				var screen: BattleScreen = BattleScreen.new()
				screen.setup(b, null, _all_seen())
				await _hosted(vp, screen, size, safe)
				await _frames(4)
				var where: String = "hud lives %d gold %d at %s on %s" % [numbers.x, numbers.y, size, level_id]
				var hud: Rect2 = screen.hud.get_global_rect()
				check(safe.grow(0.6).encloses(hud), "%s: the HUD is inside the safe area (%s)" % [where, hud])
				for part: Control in [screen.hud.lives_label, screen.hud.gold_label, screen.hud.wave_label, screen.hud.pause_button, screen.hud.call_button, screen.hud.speed_buttons[0], screen.hud.speed_buttons[2]]:
					check(hud.grow(1.0).encloses(part.get_global_rect()), "%s: a HUD part is inside the HUD (%s in %s)" % [where, part.get_global_rect(), hud])
				var numbers_rect: Rect2 = screen.hud.lives_label.get_global_rect().merge(screen.hud.gold_label.get_global_rect()).merge(screen.hud.wave_label.get_global_rect())
				check(screen.hud._stats.get_global_rect().grow(1.0).encloses(numbers_rect), "%s: the numbers are inside their row" % where)
				check(screen.hud.pause_button.get_global_rect().position.x >= screen.hud.wave_label.get_global_rect().end.x - 1.0 or screen.landscape, "%s: the numbers stop before the pause button" % where)
				_inside_and_big(screen.hud, size, where)
				vp.queue_free()
				await _frames(2)


## Ten fixed seeds, the real segments, packs and cards: each run's map has 13 rows and a scenery
## bottom row, and for every one of its 18 waves the build state keeps the home, the spots, the
## sockets and the entrances in sight with a one line strip (the dock test of section 13).
func _dock_real_runs() -> void:
	for run_seed: int in [1, 7, 42, 99, 123, 777, 2024, 31337, 65535, 4294967295]:
		await _dock_real_run(run_seed)


func _dock_real_run(run_seed: int) -> void:
	var game: GameData = BattleFixtures.game()
	var session: RunSession = RunSession.start(run_seed, "", false, game.run.pool({}), game.run, game.catalog)
	var tag: String = "real run %d" % run_seed
	check(session != null, "%s starts" % tag)
	if session == null:
		return
	var b: Battle = session.battle
	check(b.level.rows == 13, "%s: the map has 13 rows" % tag)
	for x: int in Sim.MAP_COLUMNS:
		check(b.level.kind_at(Vector2i(x, b.level.rows - 1)) == LevelData.Kind.SCENERY, "%s: the bottom row is scenery at column %d" % [tag, x])
	b.gold = 20000
	for cell: Vector2i in b.level.spots:
		b.place_tower(cell, &"sling_post")
	var vp: SubViewport = _viewport(COVER)
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, _all_seen())
	screen.set_run(session)
	await _hosted(vp, screen, COVER, COVER_SAFE)
	await _frames(6)
	var must: Array[Vector2i] = _must_see(b)
	check(screen.gate_tray.visible == (b.gates_in_hand + b.gates.size() > 0), "%s: the gate chip shows when the run has gates" % tag)
	if screen.gate_tray.visible:
		var chip: Rect2 = screen.gate_tray.get_global_rect()
		check(screen.hud.get_global_rect().encloses(chip), "%s: the gate chip is inside the HUD" % tag)
		check(chip.size.x >= 150.0 and chip.size.y >= 150.0, "%s: the gate chip is a 48 dp target (%s)" % [tag, chip.size])
	for wave: int in b.wave_count():
		# Every wave before this one was cleared and its card taken, so no draft covers the dock.
		b.waves_started = wave
		while session.picks.size() < mini(wave, RunSession.DRAFTS):
			session.picks.append(&"gold_purse")
		screen.preview.refresh()
		screen._start_fit()
		await _frames(screen.FIT_FRAMES + 3)
		var where: String = "%s wave %d" % [tag, wave + 1]
		check(not screen.draft_is_open(), "%s: no card is owed in this state" % where)
		await _preview_decision(screen, where)
		var hit: String = _first_hit(screen, must, _dock_rects(screen))
		check(hit.is_empty(), "%s: %s" % [where, hit])
	# During a wave the preview is folded and its strip is one line.
	b.waves_started = 0
	session.picks.clear()
	screen.preview.refresh()
	b.start_next_wave()
	BattleFixtures.steps(b, 4)
	await _frames(3)
	_strip_is_one_line(screen, "%s during a wave" % tag)
	var wave_hit: String = _first_hit(screen, must, _dock_rects(screen))
	check(wave_hit.is_empty(), "%s during a wave: %s" % [tag, wave_hit])
	vp.queue_free()
	await _frames(2)


## The App's run flow in a real tree at both sizes: the mode screen with the Daily line and a
## Continue card, the run card, a run and a daily on screen, and Continue after leaving.
func _u3_app_runs() -> void:
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		var size: Vector2 = pair[0]
		var safe: Rect2 = pair[1]
		var tag: String = "real_%s_u3" % pair[2]
		var where: String = "u3 app at %s" % size
		var vp: SubViewport = _viewport(size)
		var made: App = await _battle_app(vp, size, safe, tag)
		made.date_source = func() -> Dictionary: return {"year": 2026, "month": 10, "day": 24}
		made.seed_source = func() -> int: return 77
		for id: StringName in [&"r1_l1", &"r1_l2", &"r1_l3", &"r1_l4"]:
			made.progress.record_level(id, 7)
		made.daily_record.record_finish("2026-10-24", {"won": false, "waves": 9, "lives": 0})
		made.save_progress()
		made.open_mode()
		await _frames(3)
		var mode: ModeScreen = made.current_screen() as ModeScreen
		check(not mode.roguelite_button.disabled and not mode.daily_button.disabled, "%s: both run buttons are open" % where)
		_sides_and_buttons(mode, size, "%s mode screen" % where)
		check(mode.daily_button.get_global_rect().size.y >= 160.0, "%s: the Daily button is tall enough (%s)" % [where, mode.daily_button.size])
		# A real tap on Roguelite opens the card, a real tap on Start begins the run.
		_touch(vp, mode.roguelite_button.get_global_rect().get_center())
		await _frames(3)
		var card: RunCard = made.current_screen() as RunCard
		check(card != null, "%s: a real tap on Roguelite opens the run card" % where)
		if card == null:
			vp.queue_free()
			continue
		_sides_and_buttons(card, size, "%s run card" % where)
		_touch(vp, card.start_button.get_global_rect().get_center())
		await _frames(4)
		var screen: BattleScreen = made.battle_screen()
		check(screen != null and screen.run != null, "%s: a real tap on Start begins a run" % where)
		if screen == null:
			vp.queue_free()
			continue
		check(screen.run.run_seed == 77 and screen.clock.speed == 1, "%s: the run has its seed and 1x" % where)
		check(safe.grow(0.6).encloses(screen.hud.get_global_rect()), "%s: the run's HUD is inside the safe area" % where)
		screen.pause()
		await _frames(3)
		check(made.top_modal() is PausePanel, "%s: Pause opens in a run" % where)
		(made.top_modal() as PausePanel).leave_requested.emit()
		await _frames(3)
		# The daily too, and then Continue shows the most recent.
		made.open_mode()
		await _frames(3)
		mode = made.current_screen() as ModeScreen
		_touch(vp, mode.daily_button.get_global_rect().get_center())
		await _frames(3)
		var daily_card: RunCard = made.current_screen() as RunCard
		check(daily_card != null and daily_card.daily, "%s: a real tap on Daily opens the daily card" % where)
		if daily_card != null:
			check(daily_card.best_label.text == "Best today: Lost with 9 of 18 waves cleared.", "%s: the card shows the best (%s)" % [where, daily_card.best_label.text])
			_sides_and_buttons(daily_card, size, "%s daily card" % where)
			_touch(vp, daily_card.start_button.get_global_rect().get_center())
			await _frames(4)
		var daily_screen: BattleScreen = made.battle_screen()
		check(daily_screen != null and daily_screen.run != null and daily_screen.run.daily, "%s: a real tap on Start begins the daily" % where)
		if daily_screen != null:
			daily_screen.pause()
			await _frames(3)
			(made.top_modal() as PausePanel).leave_requested.emit()
			await _frames(3)
		made.open_mode()
		await _frames(3)
		mode = made.current_screen() as ModeScreen
		check(mode.continue_button != null, "%s: the Continue card shows" % where)
		_sides_and_buttons(mode, size, "%s mode screen with Continue" % where)
		if mode.continue_button != null:
			_touch(vp, mode.continue_button.get_global_rect().get_center())
			await _frames(4)
			check(made.battle_screen() != null and made.battle_screen().run != null and made.battle_screen().run.daily, "%s: a real tap on Continue resumes the daily, the most recent" % where)
			check(made.battle_screen() != null and made.battle_screen().is_paused() and made.top_modal() is PausePanel, "%s: paused on the Pause menu" % where)
		vp.queue_free()
		Fx.wipe(tag)
		await _frames(2)
	# The longest Daily line there can be: a 100000 day streak next to a lost best.
	for pair: Array in [[COVER, COVER_SAFE], [INNER, INNER_SAFE]]:
		var size: Vector2 = pair[0]
		var vp: SubViewport = _viewport(size)
		var long_mode: ModeScreen = ModeScreen.new()
		long_mode.set_continue("Continue", "Daily 2026-10-24. Wave 17 of 18. Relaxed.")
		long_mode.set_runs(true, 14, 12, true, ModeScreen.daily_detail({"won": false, "waves": 17, "lives": 0}, Daily.STREAK_MAX))
		await _hosted(vp, long_mode, size, pair[1])
		_sides_and_buttons(long_mode, size, "longest Daily line at %s" % size)
		vp.queue_free()
		await _frames(1)
