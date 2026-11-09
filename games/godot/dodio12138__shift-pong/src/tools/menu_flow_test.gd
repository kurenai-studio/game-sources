extends SceneTree
## Opens every menu page once, plays through a cup, a team tie set-up, a SHIFT
## RUN and the tutorial's skill lesson, headless, printing "[flow] ok ..." as it
## goes; any script error shows in the output.
## usage: godot --headless --path . -s tools/menu_flow_test.gd -- --nosave [--lang=en]

var m
var t := 0


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	root.add_child(m)


func _process(_d: float) -> bool:
	t += 1
	if t != 5:
		return false
	var ui = m.club_ui
	for pg in ["title", "cups", "practice", "settings", "boss", "loadout", "run_setup"]:
		ui.show_page(pg)
		print("[flow] ok ", pg)
	m.cup_run = m.CupRun.new()
	ui.cup_pool = m.cup_run.solo_pool()
	ui.show_page("solo_setup")
	m.cup_run.setup_solo(ui.cup_pool, ui.cup_pool[4], 8, 3)
	ui.show_page("cup")
	while not m.cup_run.is_over() and m.cup_run.my_tie() >= 0:
		m.cup_run.sim_mine()
		ui.show_page("cup")
	print("[flow] ok solo cup")
	m.cup_run = m.CupRun.new()
	ui.cup_pool = m.cup_run.team_pool()
	ui.show_page("team_setup")
	m.cup_run.setup_team(ui.cup_pool, ui.cup_pool[1])
	ui.cup_mode = true
	ui.picks = [0, 1, 2]
	ui.show_page("lineup")
	var plan = ui._opp_plan(m.cup_run.opponent())
	var line := []
	for i in ui.picks:
		line.append(ui._my_club().players[i])
	m.begin_cup_tie(line, plan.line)
	ui.show_page("tie")
	print("[flow] ok team cup")
	m.shift_run = m.ShiftRun.new(ui._challengers().players[0].duplicate(true), m.settings.loadout)
	var ids: Array = m.SKILL_SLOTS.map(func(s): return s.id)
	ui.show_page("run")
	m.shift_run.resolve(false, "5:7", ids)
	m.shift_run.resolve(true, "7:3", ids)
	ui.run_offer_sel = m.shift_run.offer[0]
	ui.show_page("run")
	m.shift_run.take(ui.run_offer_sel, 0)
	ui.run_offer_sel = ""
	for k in 6:
		m.shift_run.resolve(true, "7:1", ids)
	ui.show_page("run")
	print("[flow] ok shift run")
	m.start_tutorial()
	m.drill.stage = 5
	m.drill_feed()
	print("[flow] ok skill lesson ", m.skill_on())
	m.quick_start()
	print("[flow] ok quick start, game to ", m.game_to)
	m.open_menu("title")
	print("[flow] done")
	quit()
	return false
