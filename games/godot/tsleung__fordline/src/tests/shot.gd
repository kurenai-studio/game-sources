extends Node
## Plays a campaign battle on autopilot in a real window and saves
## screenshots, so the look can be checked without a browser.
##   Godot --path . --resolution 1280x720 res://tests/shot.tscn -- --battle=0 --out=build/shots/land
## Saves <out>-deploy.png, then <out>-<seconds>s.png at each time in SHOTS.
## With --menus it instead saves the title and the first briefing; with
## --routes, a paused battle with one regiment given a two-stop route;
## with --arrow, a paused battle with an arrow being dragged for two regiments;
## with --scenarios, the Pike and Shot scenario list and one briefing; with
## --grand, the grand battles list and Waterloo's briefing.
## --scenario=<id> plays that quick battle instead of a campaign battle; a
## grand battle runs at 4× and saves the opening, a close look and the whole
## field at GRAND_SHOTS instead.

const BattleScreen := preload("res://scripts/battle_screen.gd")
const Main := preload("res://scenes/main.tscn")
const SHOTS := [25.0, 50.0, 80.0]
const GRAND_SHOTS := [2.0, 330.0, 500.0, 620.0, 800.0]

var _screen
var _out := "build/shots/shot"
var _taken := 0
var _frames := 0
var _main: Node


func _ready() -> void:
	var battle_index := 0
	var scenario := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--battle="):
			battle_index = int(arg.get_slice("=", 1))
		elif arg.begins_with("--scenario="):
			scenario = arg.get_slice("=", 1)
		elif arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out.get_base_dir()))
	if "--menus" in OS.get_cmdline_user_args() or "--scenarios" in OS.get_cmdline_user_args() or "--grand" in OS.get_cmdline_user_args():
		_main = Main.instantiate()
		_main.save_path = "user://shot.cfg"
		add_child(_main)
		return
	_screen = BattleScreen.new()
	if scenario != "":
		var resolved := Scenarios.resolve(scenario, 7)
		_screen.setup(Scenarios.make_battle(resolved, 7), resolved.persona, resolved.name)
		_screen.autopilot = true
		if Scenarios.is_grand(resolved):
			_screen.grand = true
			_screen.clock = func(t: float) -> String: return Scenarios.hour_text(resolved, t)
			_screen.cam_centre = resolved.view
		add_child(_screen)
		return
	var run := Campaign.new_run(7)
	run.battle = battle_index
	var spec: Dictionary = Campaign.BATTLES[battle_index]
	_screen.setup(Campaign.make_battle(run), spec.persona, spec.name)
	_screen.autopilot = true
	add_child(_screen)


func _process(_delta: float) -> void:
	_frames += 1
	if _main != null and "--grand" in OS.get_cmdline_user_args():
		if _frames == 60:
			_main.show_grand()
		elif _frames == 80:
			_save(_out + "-grand.png")
			_main.show_scenario("waterloo")
		elif _frames == 100:
			set_process(false)
			_save(_out + "-grand-briefing.png")
			get_tree().quit()
		return
	if _main != null and "--scenarios" in OS.get_cmdline_user_args():
		if _frames == 60:
			_main.show_scenarios("pike_shot")
		elif _frames == 80:
			_save(_out + "-scenarios.png")
			_main.show_scenario("fords_shot")
		elif _frames == 100:
			set_process(false)
			_save(_out + "-scenario.png")
			get_tree().quit()
		return
	if _main != null:
		if _frames == 90:
			_save(_out + "-title.png")
			_main._start_run()
		elif _frames == 110:
			set_process(false)
			await _save(_out + "-briefing.png")
			get_tree().quit()
		return
	var b: Battle = _screen.battle
	if "--routes" in OS.get_cmdline_user_args():
		_routes()
		return
	if "--arrow" in OS.get_cmdline_user_args():
		_arrow()
		return
	if _screen.grand:
		_grand()
		return
	if b.phase == "deploy":
		if _frames == 20:
			await _save(_out + "-deploy.png")
			_screen.begin_battle()
			_screen.speed = 4.0
		return
	if b.time > 18.0 and _screen.selected.is_empty():
		_screen.select_all()
		_screen.selected.resize(2)
	if _taken < SHOTS.size() and b.time >= SHOTS[_taken]:
		_save("%s-%ds.png" % [_out, int(SHOTS[_taken])])
		_taken += 1
	if _taken >= SHOTS.size() or b.phase == "over":
		set_process(false)
		if b.phase == "over":
			await _save(_out + "-end.png")
		get_tree().quit()


func _routes() -> void:
	if _frames == 10:
		_screen.autopilot = false
		_screen.begin_battle()
		_screen.paused = true
		var r: Regiment = _screen.battle.team_regiments(0).filter(func(x): return x.kind == UnitTypes.Kind.SWORDS)[0]
		for at in [r.pos, r.pos + Vector2(-160, -60), r.pos + Vector2(-160, -60), r.pos + Vector2(-330, -40)]:
			var sp: Vector2 = _screen.to_screen(at)
			_screen._press(sp, false, false)
			_screen._release(sp)
		# Pin the new end again, to show the pinned marker.
		var end: Vector2 = _screen.to_screen(_screen.route_end(r))
		_screen._press(end, false, false)
		_screen._release(end)
	elif _frames == 30:
		set_process(false)
		_save(_out + "-routes.png")
		get_tree().quit()


## A grand battle at 4×: the opening as the player first sees it, then at
## each later shot the fighting up close and the whole field.
func _grand() -> void:
	var b: Battle = _screen.battle
	if _frames == 5:
		_screen.speed = 4.0
	if _frames == 30:
		_screen.paused = false
	if _taken >= GRAND_SHOTS.size() or b.phase == "over":
		set_process(false)
		await _save(_out + "-end.png")
		get_tree().quit()
		return
	if b.time >= GRAND_SHOTS[_taken] and _frames > 20:
		var at := int(GRAND_SHOTS[_taken])
		if _taken > 0:
			_screen.cam_zoom = 0.6
			_screen.look_at(_busiest(b))
			await get_tree().process_frame
			await _save("%s-%ds-close.png" % [_out, at])
			_screen.cam_zoom = 0.01
			_screen.look_at(Vector2.ZERO)
			await get_tree().process_frame
			await _save("%s-%ds-field.png" % [_out, at])
		else:
			await _save("%s-open.png" % _out)
		_taken += 1


## Where the most blocks of both sides are within reach of each other.
func _busiest(b: Battle) -> Vector2:
	var best := b.terrain.size * 0.5
	var most := -1
	for r in b.regiments:
		if not r.fighting():
			continue
		var n := 0
		for o in b.regiments:
			if o.fighting() and o.team != r.team and o.pos.distance_to(r.pos) < 400.0:
				n += 1
		if n > most:
			most = n
			best = r.pos
	return best


## Two regiments selected and an arrow held mid-drag, pointing at the
## right flank: the preview the player sees before letting go.
func _arrow() -> void:
	if _frames == 10:
		_screen.autopilot = false
		_screen.begin_battle()
		_screen.paused = true
		var foot: Array = _screen.battle.team_regiments(0).filter(func(x): return x.kind == UnitTypes.Kind.SWORDS)
		_screen._select([foot[0].id, foot[1].id] as Array[int])
		var at: Vector2 = foot[0].pos + Vector2(60, -120)
		_screen._press(_screen.to_screen(at), false, false)
		_screen.drag.now_world = at + Vector2(130, 40)
		_screen.drag.now_screen = _screen.to_screen(_screen.drag.now_world)
	elif _frames == 30:
		set_process(false)
		_save(_out + "-arrow.png")
		get_tree().quit()


## The window must stay visible: macOS stops drawing a covered window and
## the shot then shows the last frame it drew.
func _save(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://" + path))
	print("saved ", path)
