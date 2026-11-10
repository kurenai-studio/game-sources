extends Node2D
# Главный скрипт: переключает экраны (меню, выбор карты, выбор героя, бой),
# ведёт матч из раундов и считает очки.
#
# Где что лежит:
#   core/        — общие настройки (config), слои физики (layer), помощники (util),
#                  камера режима на двоих (duel_camera), выбор места возрождения (spawner)
#   ui/          — главное меню, свиток дуэли (duel_setup), свиток Арены (arena_setup),
#                  колонны выбора легенд (legend_picker), магазин, инвентарь, счёт,
#                  экран победы, экранные кнопки
#   characters/  — список персонажей (characters) и сам герой (player)
#   weapons/     — пули, снаряды, гранаты, огонь, ульта-землетрясение
#   maps/        — карты (maps), колизей Арены (colosseum), факелы (torch),
#                  разрушаемые объекты (destructible), осколки (fragment)
#   modes/       — режим «Арена» с волнами ботов (arena_mode)
#   characters/  — ещё виды ботов и волны (bots)
#   core/        — ещё пиксельные картинки (pixel_art) и стиль интерфейса (ui_theme)

var world: Node2D           # всё, что сейчас на экране
var mode := ""              # "menu", "select", "duel", "solo"
var map_id := "test_field"  # выбранная карта для режима на двоих
var sel := [0, 1]           # выбранные персонажи
var score := [0, 0]
var hud: Hud

# Матч на двоих
var wins_needed := 3        # сколько раундов нужно выиграть
var kills_needed := 5       # сколько убийств нужно для победы в раунде
var round_num := 1
var round_wins := [0, 0]
var kills := [0, 0]
var round_over := true      # во время отсчёта и между раундами смерти не считаются
var map_info := {}
var duel_players: Array = []
var arena_coop := false
var duel_opts := {"heal": false, "buffs": false, "mega": false, "sd": false, "sd_time": 120}
var events: DuelEvents

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.07, 0.06, 0.09))
	var th := UiTheme.build()                    # общий стиль кнопок и надписей
	get_tree().root.theme = th
	ThemeDB.get_default_theme().merge_with(th)   # и внутри CanvasLayer тоже
	TouchControls.add_actions()
	TouchControls._add("p1", {"ranged": KEY_G, "interact": KEY_T, "inv": KEY_I, "quests": KEY_J, "menu": KEY_ESCAPE})
	Pad.add_actions()
	var pad := Pad.new()
	pad.main = self
	add_child(pad)
	StorySettings.apply()
	Save.load_game()
	show_menu()

# F11 (или Alt+Enter) — полноэкранный режим на компьютере.
# В бою (Дуэль, Арена): Start на геймпаде или Esc — пауза.
func _unhandled_input(event: InputEvent) -> void:
	if mode in ["duel", "arena"] and not get_tree().paused:
		var start: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
		if start or event.is_action_pressed("p1_menu"):
			get_viewport().set_input_as_handled()
			open_pause()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED if full
					else DisplayServer.WINDOW_MODE_FULLSCREEN)

# ---------- Экраны ----------
func _new_world() -> void:
	if world:
		remove_child(world)
		world.queue_free()
	world = Node2D.new()
	add_child(world)
	score = [0, 0]
	hud = null

func _fixed_camera() -> void:
	var cam := Camera2D.new()
	cam.position = Vector2(Config.W / 2, Config.H / 2)
	world.add_child(cam)
	cam.make_current()

func show_menu() -> void:
	_new_world()
	mode = "menu"
	_fixed_camera()
	var menu := MainMenu.new()
	menu.mode_chosen.connect(_on_mode_chosen)
	world.add_child(menu)

func _on_mode_chosen(m: String) -> void:
	match m:
		"story":
			show_story_slots()
		"duel":
			show_duel_setup()
		"arena":
			show_arena_setup()
		"shop":
			_show_screen(ShopScreen.new())
		"inventory":
			_show_screen(InventoryScreen.new())
		"bestiary":
			_show_screen(BestiaryScreen.new())
		"controls":
			_show_screen(ControlsScreen.new())
		"settings":
			_show_screen(SettingsScreen.new())

# ---------- Режим: История ----------
func show_story_slots() -> void:
	_new_world()
	mode = "story_slots"
	_fixed_camera()
	var screen := StorySlots.new()
	screen.back_pressed.connect(show_menu)
	screen.new_game.connect(show_story_creator)
	screen.continue_game.connect(start_story)
	world.add_child(screen)

func show_story_creator(slot: int) -> void:
	_new_world()
	mode = "story_creator"
	_fixed_camera()
	var screen := StoryCreator.new()
	screen.slot = slot
	screen.back_pressed.connect(show_story_slots)
	screen.created.connect(start_story)
	world.add_child(screen)

func start_story(slot: int, data: Dictionary) -> void:
	_new_world()
	mode = "story"
	var sm := StoryMode.new()
	sm.world = world
	sm.slot = slot
	sm.data = data
	sm.exit_to_menu.connect(show_menu)
	world.add_child(sm)

func _show_screen(screen: CanvasLayer) -> void:
	_new_world()
	mode = "screen"
	_fixed_camera()
	screen.back_pressed.connect(show_menu)
	world.add_child(screen)

# Свиток дуэли: условия матча, место битвы, затем выбор легенд на колоннах
func show_duel_setup(on_legends := false) -> void:
	_new_world()
	mode = "duel_setup"
	_fixed_camera()
	var screen := DuelSetup.new()
	screen.wins = wins_needed
	screen.kills = kills_needed
	screen.sel = sel.duplicate()
	screen.opts = duel_opts.duplicate()
	if on_legends:
		screen.map_id = map_id
		screen.start_on_legends = true
	screen.start_pressed.connect(_on_duel_ready)
	screen.back_pressed.connect(show_menu)
	world.add_child(screen)

func _on_duel_ready(id: String, wins: int, kills_to_win: int, chosen: Array, opts := {}) -> void:
	if not opts.is_empty():
		duel_opts = opts
	map_id = id
	wins_needed = wins
	kills_needed = kills_to_win
	sel = chosen.duplicate()
	start_duel()

# Арена: один или вдвоём, новая игра или продолжение, затем выбор легенд
func show_arena_setup() -> void:
	_new_world()
	mode = "arena_setup"
	_fixed_camera()
	var screen := ArenaSetup.new()
	screen.coop = arena_coop
	screen.sel = sel.duplicate()
	screen.start_pressed.connect(func(coop: bool, wave: int, chosen: Array):
		sel = chosen.duplicate()
		start_arena(coop, wave))
	screen.back_pressed.connect(show_menu)
	world.add_child(screen)

# ---------- Режим: 2 игрока ----------
# Матч состоит из раундов. Раунд выигрывает тот, кто первым набрал kills_needed
# убийств. Матч выигрывает тот, кто первым выиграл wins_needed раундов.
# Перед каждым раундом карта строится заново — полностью целой.
func start_duel() -> void:
	round_num = 1
	round_wins = [0, 0]
	_start_round()

func _start_round() -> void:
	_new_world()
	mode = "duel"
	kills = [0, 0]
	round_over = true
	var info := Maps.build(world, map_id)
	map_info = info
	var size: Vector2 = info["size"]
	var p1 := Characters.create(sel[0], "p1", 0, 0, info["p1"], 1, Config.OUTLINE_P1)
	p1.team_color = Config.OUTLINE_P1
	var p2 := Characters.create(sel[1], "p2", 1, 1, info["p2"], -1, Config.OUTLINE_P2)
	p2.team_color = Config.OUTLINE_P2
	duel_players = [p1, p2]
	for dp in duel_players:
		Balance.apply(dp, "duel")          # баланс легенд для Дуэли (core/balance.gd)
	for p in duel_players:
		p.map_w = size.x
		p.map_top = float(info.get("top_y", 0.0)) - 30.0
		if p.kit:
			p.kit.duel = true              # в Дуэли у тотемов Терновника есть заряды
		p.frozen = true
		p.spawn_picker = _pick_spawn
		p.died.connect(_on_player_died)
		world.add_child(p)

	# камера: вся арена целиком или слежение за обоими игроками
	var cam := DuelCamera.new()
	cam.bounds = info.get("cam_rect", Rect2(Vector2.ZERO, size))
	cam.follow = info["follow"]
	cam.open_top = info["open_top"]
	cam.targets = [p1, p2]
	cam.min_zoom = info.get("min_zoom", 0.0)
	world.add_child(cam)
	# на огромных картах экран делится, когда игроки далеко друг от друга
	if info.get("split", false):
		var sv := SplitView.new()
		sv.players = [p1, p2]
		sv.bounds = Rect2(Vector2.ZERO, size)
		sv.open_top = info["open_top"]
		world.add_child(sv)
	TouchControls.build_panel(world, true)
	p1.ui = TouchControls.build(world, "p1", "left", p1)
	p2.ui = TouchControls.build(world, "p2", "right", p2)
	_build_hud()
	for p in duel_players:
		p.allow_mega = duel_opts.get("mega", false)
	# сферы с неба и «Мгновенная смерть»
	events = DuelEvents.new()
	events.world = world
	events.hud = hud
	events.map_id = map_id
	events.info = info
	events.players = duel_players
	events.opts = duel_opts
	world.add_child(events)
	# станции и алтари баффов на картах-аренах и TEST_BUFFS — надписи о подборе
	for n in world.get_children():
		if n is PickupSpawner:
			n.picked.connect(events.float_text)
	_countdown()

# «Раунд N» → 3 → 2 → 1 → «Бой!»
func _countdown() -> void:
	hud.show_banner("Раунд %d" % round_num)
	_after(0.9, hud.show_banner.bind("3"))
	_after(1.45, hud.show_banner.bind("2"))
	_after(2.0, hud.show_banner.bind("1"))
	_after(2.55, _fight)

func _fight() -> void:
	hud.show_banner("Бой!", Color(1.0, 0.85, 0.3))
	round_over = false
	events.active = true
	for p in duel_players:
		p.frozen = false
	_after(0.7, hud.hide_banner)

func _pick_spawn(p: Player) -> Dictionary:
	var enemy: Player = duel_players[1 - p.team]
	var r := Spawner.pick(world, p, enemy, map_info)
	if events and is_instance_valid(events):
		r = events.safe_spawn(r, p)
	return r

func _end_round(winner: int) -> void:
	round_over = true
	events.active = false
	round_wins[winner] += 1
	for p in duel_players:
		p.frozen = true
	_update_score()
	var c := Config.OUTLINE_P1 if winner == 0 else Config.OUTLINE_P2
	if round_wins[winner] >= wins_needed:
		hud.show_banner("Матч за Игроком %d!" % (winner + 1), c)
		_after(1.8, _show_match_end.bind(winner))
	else:
		hud.show_banner("Раунд за Игроком %d" % (winner + 1), c)
		_after(2.2, _next_round)

func _next_round() -> void:
	round_num += 1
	_start_round()

func _show_match_end(winner: int) -> void:
	hud.hide_banner()
	var screen := MatchEnd.new()
	screen.winner = winner
	screen.rounds = round_wins
	screen.again_pressed.connect(start_duel)
	screen.maps_pressed.connect(show_duel_setup)
	screen.menu_pressed.connect(show_menu)
	world.add_child(screen)

# Таймер, который исчезает вместе с текущим экраном
func _after(time: float, fn: Callable) -> void:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = time
	world.add_child(t)
	t.timeout.connect(fn)
	t.timeout.connect(t.queue_free)
	t.start()

# ---------- Режим: Арена ----------
func start_arena(coop: bool, wave: int) -> void:
	_new_world()
	mode = "arena"
	arena_coop = coop
	hud = Hud.new()
	hud.menu_pressed.connect(open_pause)
	world.add_child(hud)
	var arena := ArenaMode.new()
	arena.world = world
	arena.hud = hud
	arena.coop = coop
	arena.chars = sel.duplicate()
	arena.start_wave = wave
	arena.finished.connect(_on_arena_finished)
	world.add_child(arena)
	arena.start()

func _on_arena_finished(victory: bool, waves_done: int, gold: int) -> void:
	var screen := MatchEnd.new()
	screen.title_text = "Победа!" if victory else "Поражение"
	screen.title_color = Color(1.0, 0.85, 0.3) if victory else Color(1.0, 0.4, 0.35)
	screen.sub_text = "Пройдено волн: %d из %d   ·   Золото: +%d" % [waves_done, ArenaMode.TOTAL_WAVES, gold]
	if not victory:
		screen.sub_text += "\nМожно продолжить с волны %d" % (waves_done + 1)
	screen.show_maps = false
	var key := "coop" if arena_coop else "solo"
	screen.again_pressed.connect(func():
		var p := Save.arena_progress(key)
		start_arena(arena_coop, int(p.get("wave", 1))))
	screen.menu_pressed.connect(show_menu)
	world.add_child(screen)

# ---------- Пауза в бою ----------
# «Меню» в Дуэли и на Арене больше не выкидывает сразу в главное меню,
# а ставит игру на паузу и открывает окно с выбором.
func open_pause() -> void:
	if not (mode in ["duel", "arena"]) or world == null or get_tree().paused:
		return
	for c in world.get_children():
		if c is BattlePause or c is MatchEnd:
			return                        # уже на паузе или бой закончен
	var pz := BattlePause.new()
	pz.main = self
	pz.kind = mode
	get_tree().paused = true
	world.add_child(pz)

# После «Настроек» из паузы — экранные кнопки перестраиваются сразу
func rebuild_controls() -> void:
	if world == null:
		return
	for g in ["touch_ui", "pad_ui"]:
		for n in get_tree().get_nodes_in_group(g):
			if world.is_ancestor_of(n):
				n.queue_free()
	if mode == "duel" and duel_players.size() == 2:
		TouchControls.build_panel(world, true)
		duel_players[0].ui = TouchControls.build(world, "p1", "left", duel_players[0])
		duel_players[1].ui = TouchControls.build(world, "p2", "right", duel_players[1])
	elif mode == "arena":
		for n in world.get_children():
			if n is ArenaMode:
				n.rebuild_controls()

# ---------- Счёт ----------
func _build_hud() -> void:
	hud = Hud.new()
	hud.menu_pressed.connect(open_pause)
	world.add_child(hud)
	_update_score()

func _on_player_died(index: int) -> void:
	if mode == "duel":
		if round_over:
			return
		var killer := 1 - index
		kills[killer] += 1
		_update_score()
		if kills[killer] >= kills_needed:
			_end_round(killer)

func _update_score() -> void:
	if hud == null:
		return
	if mode == "duel":
		hud.set_text("%d : %d" % [kills[0], kills[1]])
		hud.set_sub("Раунд %d  ·  до %d убийств  ·  победы в раундах %d : %d (до %d)" % [
				round_num, kills_needed, round_wins[0], round_wins[1], wins_needed])
