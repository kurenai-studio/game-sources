extends Node
## The game's screens and the run that threads through them:
## title → briefing → battle → result → briefing (with a reward) … → final,
## and the quick battles: title → scenarios → scenario → battle → result.

const K := UnitTypes.Kind
const BattleScreen := preload("res://scripts/battle_screen.gd")
const MapPreview := preload("res://scripts/map_preview.gd")
## Lines of a scenario's brief shown on its card in a list.
const CARD_BRIEF_LINES := 2
## The open rules' box, as a share of the screen's height.
const RULES_HEIGHT := 0.32
## Seconds within which a second tap abandons the campaign.
const ABANDON_WINDOW := 3.0
## Where progress is kept; tests point it at a file of their own.
var save_path := "user://fordline.cfg"

var run: Dictionary = {}
var best := 0
var _theme: Theme
var _stage: Node


func _ready() -> void:
	randomize()
	_theme = _make_theme()
	best = int(_load("score", "best", 0))
	show_title()


# --- screens ---------------------------------------------------------------

func show_title() -> void:
	var demo_run := Campaign.new_run(randi())
	demo_run.battle = randi() % 2
	demo_run = Campaign.apply_reward(demo_run, {"id": "recruit", "kind": K.CANNONS})
	var screen := BattleScreen.new()
	screen.setup(Campaign.make_battle(demo_run), "aggressive", "demo", true)
	var ui := _fresh(screen)
	var shade := ColorRect.new()
	shade.color = Color(Palette.DESK, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	var col := _column(ui, 520)
	var name := _text("FORDLINE", 76, Palette.INK)
	name.add_theme_constant_override("outline_size", 12)
	name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	col.add_child(name)
	col.add_child(_text("Hold the crossings. Five battles, one army,\nabout twenty minutes.", 20, Palette.INK))
	col.add_child(_spacer(12))
	col.add_child(_button("New campaign", _start_run, true))
	col.add_child(_button("Quick battle", show_scenarios))
	col.add_child(_button("Grand battles", show_grand))
	# The rules scroll inside a box a third of the screen tall, so the title
	# column still fits a landscape phone with them open.
	var rules := ScrollContainer.new()
	rules.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rules.custom_minimum_size = Vector2(0, get_viewport().get_visible_rect().size.y * RULES_HEIGHT)
	var rules_text := _panel_text(_how_to_play())
	rules_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules.add_child(rules_text)
	rules.visible = false
	col.add_child(_button("How to play", func(): rules.visible = not rules.visible))
	col.add_child(rules)
	if best > 0:
		col.add_child(_text("Best score  %d" % best, 18, Palette.BRASS))


## The scenarios of one era, picked by the tabs along the top; with no
## era given, the one last looked at.
func show_scenarios(era_id := "") -> void:
	Sfx.play("click")
	if Scenarios.era(era_id).is_empty():
		era_id = _load("ui", "era", Scenarios.ERAS[0].id)
		if Scenarios.era(era_id).is_empty():
			era_id = Scenarios.ERAS[0].id
	_save("ui", "era", era_id)
	var col := _page()
	col.add_child(_inline("QUICK BATTLE", 15, Palette.BRASS))
	col.add_child(_text("Scenarios", 40, Palette.INK, false))
	col.add_child(_text("One battle each, three to five minutes. Earn up to three stars.", 18, Palette.INK_DIM, false))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	for e in Scenarios.ERAS:
		var tab := _button(e.name, show_scenarios.bind(e.id), e.id == era_id)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# The chosen tab is coloured like a primary button, but keeps the
		# tabs' one size of lettering.
		tab.remove_theme_font_size_override("font_size")
		tabs.add_child(tab)
	col.add_child(tabs)
	for spec in Scenarios.of_era(era_id):
		col.add_child(_scenario_card(spec))
	col.add_child(_button("Back", show_title))


## The historical days, each a field several screens across.
func show_grand() -> void:
	Sfx.play("click")
	var col := _page()
	col.add_child(_inline("GRAND BATTLES", 15, Palette.BRASS))
	col.add_child(_text("Historical days", 40, Palette.INK, false))
	col.add_child(_text("A whole day's battle on a field several screens across, with armies arriving by road. About fifteen minutes; drag the field to look around.", 18, Palette.INK_DIM, false))
	for spec in Scenarios.GRAND:
		col.add_child(_scenario_card(spec))
	col.add_child(_button("Back", show_title))


## A scenario's card: its field, its name and brief, and the stars earned.
func _scenario_card(spec: Dictionary) -> Button:
	var thumb_w := 150.0 if get_viewport().get_visible_rect().size.x > 760 else 110.0
	# Skirmish's field is drawn now, so the thumbnail is the field you get.
	var seed_value := randi()
	var resolved := Scenarios.resolve(spec.id, seed_value)
	var b := Scenarios.make_battle(resolved, seed_value)
	var aspect := b.terrain.size.y / b.terrain.size.x
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(0, thumb_w * aspect + 28.0)
	card.pressed.connect(show_scenario.bind(spec.id, seed_value))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := _inline(spec.name, 22, Palette.INK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(title)
	var brief := _text(spec.brief, 15, Palette.INK_DIM, false)
	brief.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A card is as tall as its map, so a long brief shows its first lines
	# rather than running into the next card. The briefing has all of it.
	brief.max_lines_visible = CARD_BRIEF_LINES
	words.add_child(brief)
	var thumb := MapPreview.new()
	thumb.custom_minimum_size = Vector2(thumb_w, thumb_w * aspect)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.show_battle(b, hash(resolved.name))
	row.add_child(thumb)
	row.add_child(words)
	row.add_child(StarRow.make(int(_load("stars", spec.id, 0)), 22))
	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 14)
	pad.add_child(row)
	card.add_child(pad)
	return card


## `seed_value` picks Skirmish's field (and every scenario's dice); a new
## one is drawn when none is given.
func show_scenario(id: String, seed_value := -1) -> void:
	Sfx.play("click")
	if seed_value < 0:
		seed_value = randi()
	var spec := Scenarios.resolve(id, seed_value)
	var grand := Scenarios.is_grand(spec)
	var col := _page()
	col.add_child(_inline("GRAND BATTLE" if grand else "QUICK BATTLE", 15, Palette.BRASS))
	col.add_child(_text(spec.name, 40, Palette.INK, false))
	col.add_child(_text(spec.brief, 18, Palette.INK_DIM, false))
	col.add_child(_map(Scenarios.make_battle(spec, seed_value), spec.name))
	if Scenarios.is_random(id):
		col.add_child(_button("New field", show_scenario.bind(id)))
	col.add_child(_inline("GOAL", 14, Palette.BRASS))
	col.add_child(_text(Scenarios.goal_text(spec), 18, Palette.INK, false))
	col.add_child(_inline("STARS", 14, Palette.BRASS))
	var earned := int(_load("stars", id, 0))
	var lines := ["Win"]
	for c in spec.stars:
		lines.append(Scenarios.condition_text(c))
	for i in lines.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(StarRow.make(1 if earned > i else 0, 18, 1))
		row.add_child(_inline(lines[i], 17, Palette.INK))
		col.add_child(row)
	if grand:
		col.add_child(_inline("THE DAY", 14, Palette.BRASS))
		col.add_child(_panel_text(_day_text(spec)))
	else:
		col.add_child(_inline("THEY BRING", 14, Palette.BRASS))
		col.add_child(_army_strip(_army(spec.enemy), 1))
		col.add_child(_inline("YOU BRING", 14, Palette.BRASS))
		col.add_child(_army_strip(_army(spec.player), 0))
	col.add_child(_button("Fight", _start_scenario.bind(spec, seed_value), true))
	col.add_child(_button("Back", show_grand if grand else show_scenarios))


## A grand battle's order of march: who is on the field at the start and
## who comes up which road when, both sides, by the hour.
func _day_text(spec: Dictionary) -> String:
	var sides := ["You", "They"]
	var start := Scenarios.hour_text(spec, 0.0)
	var lines := PackedStringArray()
	for team in 2:
		var forces: Array = spec.start.filter(func(f): return f.team == team)
		lines.append("%s  %s: %s" % [start, sides[team], ", ".join(forces.map(func(f): return f.formation))])
	var arrivals: Array = spec.arrivals.duplicate()
	arrivals.sort_custom(func(a, c): return a.hour < c.hour)
	for a in arrivals:
		var at := Scenarios.hour_text(spec, (a.hour - spec.start_hour) * spec.hour)
		lines.append("%s  %s: %s, %s (%d)" % [at, sides[a.team], a.formation, a.from, a.units.size()])
	return "\n".join(lines)


## The field `b` will be fought on, both armies deployed, as wide as the
## page and no taller than a third of the screen.
func _map(b: Battle, title: String) -> Control:
	var vp := get_viewport().get_visible_rect().size
	var map := MapPreview.new()
	var h := minf((vp.x - 40.0) * b.terrain.size.y / b.terrain.size.x, vp.y * 0.36)
	map.custom_minimum_size = Vector2(0, h)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.show_battle(b, hash(title))
	return map


## A scenario's [kind, stars] list as the roster entries the strips draw,
## with the general that every army has.
func _army(list: Array) -> Array:
	var out: Array = [{"kind": K.GENERAL}]
	for e in list:
		out.append({"kind": e[0]})
	return out


func _start_scenario(spec: Dictionary, seed_value: int) -> void:
	Sfx.play("click")
	var screen := BattleScreen.new()
	screen.setup(Scenarios.make_battle(spec, seed_value), spec.persona, spec.name)
	screen.goal = Scenarios.goal_text(spec)
	screen.quick = true
	if Scenarios.is_grand(spec):
		screen.grand = true
		screen.clock = func(t: float) -> String: return Scenarios.hour_text(spec, t)
		screen.cam_centre = spec.view
	screen.finished.connect(_scenario_over.bind(spec))
	screen.left.connect(show_grand if Scenarios.is_grand(spec) else show_scenarios)
	screen.restarted.connect(_start_scenario.bind(spec, seed_value))
	_fresh(screen)


func _scenario_over(b: Battle, spec: Dictionary) -> void:
	var stars := Scenarios.stars(spec, b)
	var before := int(_load("stars", spec.id, 0))
	if stars > before:
		_save("stars", spec.id, stars)
	var col := _overlay()
	var won := b.winner == 0
	col.add_child(_text("Victory" if won else "Defeat", 60, Palette.GOLD if won else Palette.TEAM_LIGHT[1]))
	col.add_child(_text(spec.name, 20, Palette.INK_DIM))
	var stars_row := StarRow.make(stars, 34)
	stars_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(stars_row)
	var met := Scenarios.conditions_met(spec, b)
	var lines := PackedStringArray(["%s  Win" % ("Done" if won else "Not yet")])
	for i in spec.stars.size():
		lines.append("%s  %s" % ["Done" if met[i] else "Not yet", Scenarios.condition_text(spec.stars[i])])
	var t := int(b.time)
	if Scenarios.is_grand(spec):
		lines.append("Ended  %s" % Scenarios.hour_text(spec, b.time))
	else:
		lines.append("Time  %d:%02d" % [t / 60, t % 60])
	if stars > before:
		lines.append("New best for this scenario")
	col.add_child(_panel_text("\n".join(lines)))
	col.add_child(_button("Another field" if Scenarios.is_random(spec.id) else "Again", show_scenario.bind(spec.id), true))
	col.add_child(_button("Grand battles" if Scenarios.is_grand(spec) else "Scenarios", show_grand if Scenarios.is_grand(spec) else show_scenarios))


func _start_run() -> void:
	Sfx.play("click")
	run = Campaign.new_run(randi())
	show_briefing([])


func show_briefing(rewards: Array) -> void:
	var spec := Campaign.current(run)
	var col := _page()
	var head := HBoxContainer.new()
	col.add_child(head)
	var step := _inline("BATTLE %d OF %d" % [run.battle + 1, Campaign.BATTLES.size()], 15, Palette.BRASS)
	step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(step)
	head.add_child(_inline("Score  %d" % run.score, 15, Palette.INK_DIM))
	col.add_child(_route())
	col.add_child(_text(spec.name, 40, Palette.INK, false))
	col.add_child(_text(spec.brief, 18, Palette.INK_DIM, false))
	var map := _map(Campaign.make_battle(run), spec.name)
	col.add_child(map)
	col.add_child(_text("THEY BRING", 14, Palette.BRASS, false))
	col.add_child(_army_strip(Campaign.enemy_army(run), 1))
	var choice := {"reward": null}
	var march := _button("To battle", func(): _start_battle(choice.reward), true)
	if not rewards.is_empty():
		col.add_child(_text("CHOOSE A REWARD", 14, Palette.BRASS, false))
		var group := ButtonGroup.new()
		var cards := GridContainer.new()
		cards.columns = 3 if get_viewport().get_visible_rect().size.x > 760 else 1
		cards.add_theme_constant_override("h_separation", 10)
		cards.add_theme_constant_override("v_separation", 10)
		for r in rewards:
			var card := Button.new()
			card.toggle_mode = true
			card.button_group = group
			card.text = "%s\n%s" % [r.title, r.text]
			card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.custom_minimum_size = Vector2(220, 84)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.focus_mode = Control.FOCUS_NONE
			card.pressed.connect(func():
				choice.reward = r
				march.disabled = false
				map.show_battle(Campaign.make_battle(Campaign.apply_reward(run, r)), hash(spec.name))
				Sfx.play("click"))
			cards.add_child(card)
		col.add_child(cards)
		march.disabled = true
	col.add_child(_text("YOUR ARMY", 14, Palette.BRASS, false))
	col.add_child(_roster())
	col.add_child(march)
	col.add_child(_abandon_button())


## Leaving between battles gives the run up; it asks for a second tap.
func _abandon_button() -> Button:
	var b := _button("Abandon the campaign", func(): pass)
	var armed := {"until": 0.0}
	b.pressed.connect(func():
		var now := Time.get_ticks_msec() / 1000.0
		if now <= armed.until:
			show_title()
		else:
			armed.until = now + ABANDON_WINDOW
			b.text = "Tap again to abandon it"
			Sfx.play("click"))
	return b


func _start_battle(reward: Variant) -> void:
	if reward != null:
		run = Campaign.apply_reward(run, reward)
	Sfx.play("click")
	var spec := Campaign.current(run)
	var screen := BattleScreen.new()
	screen.setup(Campaign.make_battle(run), spec.persona, spec.name)
	screen.finished.connect(_battle_over)
	screen.left.connect(_leave_campaign_battle.bind(screen))
	_fresh(screen)


## Leaving before the fighting starts goes back to the briefing; once it
## has started it is a retreat, which the run counts as a defeat.
func _leave_campaign_battle(screen) -> void:
	Sfx.play("click")
	var b: Battle = screen.battle
	if b.phase == "deploy":
		show_briefing([])
		return
	var result := Campaign.battle_result(b)
	result.won = false
	run = Campaign.after_battle(run, result)
	show_final()


func _battle_over(b: Battle) -> void:
	var result := Campaign.battle_result(b)
	var before: int = run.score
	run = Campaign.after_battle(run, result)
	var lost := 0
	for r in b.regiments:
		if r.team == 0:
			lost += r.men_max - r.men()
	var ui := CanvasLayer.new()
	ui.layer = 5
	_stage.add_child(ui)
	var root := Control.new()
	root.theme = _theme
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(Palette.DESK, 0.7)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var col := _column(root, 460)
	var won: bool = result.won
	col.add_child(_text("Victory" if won else "Defeat", 60, Palette.GOLD if won else Palette.TEAM_LIGHT[1]))
	col.add_child(_text(Campaign.BATTLES[run.battle].name, 20, Palette.INK_DIM))
	var t := int(b.time)
	col.add_child(_panel_text("Time  %d:%02d\nEnemy fallen  %d\nYour fallen  %d\nScore  +%d" % [t / 60, t % 60, b.killed[0], lost, run.score - before]))
	col.add_child(_button("Continue" if not run.over else "See the war's end", _after_result, true))


func _after_result() -> void:
	Sfx.play("click")
	if run.over:
		show_final()
		return
	run = Campaign.advance(run)
	show_briefing(Campaign.offer_rewards(run))


func show_final() -> void:
	var record: bool = run.score > best
	if record:
		best = run.score
		_save("score", "best", best)
	var ui := _fresh(null)
	var bg := ColorRect.new()
	bg.color = Palette.DESK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var col := _column(ui, 520)
	var won: bool = run.won
	col.add_child(_text("The war is won" if won else "Your army is broken", 44, Palette.GOLD if won else Palette.TEAM_LIGHT[1]))
	col.add_child(_text("Score  %d" % run.score + ("   New best!" if record else "   Best  %d" % best), 24, Palette.INK))
	var lines := PackedStringArray()
	for entry in run.log:
		var t := int(entry.time)
		lines.append("%s   %s   %d:%02d   +%d" % ["Won " if entry.won else "Lost", entry.name, t / 60, t % 60, entry.score])
	col.add_child(_panel_text("\n".join(lines)))
	col.add_child(_button("New campaign", _start_run, true))
	col.add_child(_button("Title", show_title))


# --- building blocks -------------------------------------------------------

## A full-screen scrolling page on the desk background; returns its column.
func _page() -> VBoxContainer:
	var ui := _fresh(null)
	var bg := ColorRect.new()
	bg.color = Palette.DESK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	scroll.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(col)
	return col


## A dimmed layer over the battle that just ended; returns its column.
func _overlay() -> VBoxContainer:
	var ui := CanvasLayer.new()
	ui.layer = 5
	_stage.add_child(ui)
	var root := Control.new()
	root.theme = _theme
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(Palette.DESK, 0.7)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	return _column(root, 460)


## Replace whatever is on stage with `screen` (or nothing) and a fresh UI
## layer; returns the UI root.
func _fresh(screen: Node) -> Control:
	if _stage != null:
		_stage.queue_free()
	_stage = Node.new()
	add_child(_stage)
	if screen != null:
		_stage.add_child(screen)
	var layer := CanvasLayer.new()
	layer.layer = 4
	_stage.add_child(layer)
	var root := Control.new()
	root.theme = _theme
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	return root


func _column(parent: Control, width: float) -> VBoxContainer:
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(centre)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = minf(width, get_viewport().get_visible_rect().size.x - 40.0)
	col.add_theme_constant_override("separation", 12)
	centre.add_child(col)
	return col


func _text(s: String, size: int, color: Color, centred := true) -> Label:
	var l := _inline(s, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centred:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## A label that sits in a row and keeps to one line.
func _inline(s: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _panel_text(s: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_child(_text(s, 17, Palette.INK, false))
	return p


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


func _button(text: String, action: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	if primary:
		b.add_theme_stylebox_override("normal", _box(Palette.BRASS, Palette.BRASS))
		b.add_theme_stylebox_override("hover", _box(Palette.GOLD, Palette.GOLD))
		b.add_theme_stylebox_override("pressed", _box(Palette.GOLD, Palette.GOLD))
		b.add_theme_stylebox_override("disabled", _box(Palette.DESK_RAISED, Palette.DESK_RAISED))
		b.add_theme_color_override("font_color", Palette.DESK)
		b.add_theme_color_override("font_hover_color", Palette.DESK)
		b.add_theme_color_override("font_pressed_color", Palette.DESK)
		b.add_theme_font_size_override("font_size", 22)
	return b


## Five bars, one per battle: done, here, ahead.
func _route() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for i in Campaign.BATTLES.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(44, 6)
		dot.color = Palette.BRASS if i < run.battle else (Palette.GOLD if i == run.battle else Palette.DESK_RAISED)
		row.add_child(dot)
	return row


func _army_strip(army: Array, team: int) -> Control:
	var counts := {}
	for reg in army:
		counts[reg.kind] = counts.get(reg.kind, 0) + 1
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	for kind in counts:
		var item := HBoxContainer.new()
		item.add_child(UnitIcon.make(kind, team, 30))
		item.add_child(_inline("%s ×%d" % [UnitTypes.label(kind), counts[kind]], 16, Palette.INK))
		flow.add_child(item)
	return flow


func _roster() -> Control:
	var grid := GridContainer.new()
	grid.columns = 2 if get_viewport().get_visible_rect().size.x > 760 else 1
	grid.add_theme_constant_override("h_separation", 24)
	for reg in run.roster:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(UnitIcon.make(reg.kind, 0, 30))
		var full: int = UnitTypes.stat(reg.kind, "men")
		var stars: String = ("  " + "★".repeat(reg.stars)) if reg.stars > 0 else ""
		var name := _inline(UnitTypes.label(reg.kind) + stars, 17, Palette.INK)
		name.custom_minimum_size.x = 150
		row.add_child(name)
		var bar := ProgressBar.new()
		bar.max_value = full
		bar.value = reg.men
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(120, 10)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		row.add_child(_inline("%d/%d" % [reg.men, full], 15, Palette.INK_DIM))
		grid.add_child(row)
	return grid


func _how_to_play() -> String:
	return "\n".join([
		"Hold more of the three flags to drain the enemy's resolve. Rout their regiments to drain it faster. At zero, their army breaks.",
		"",
		"Tap a banner to select. Double-tap selects every regiment of that kind. With nothing selected, drag to box-select.",
		"Tap the field to move. Drag an arrow: they stand where it starts and face where it points. Tap an enemy to attack.",
		"To add a stop, tap the gold marker at the end of a route, then tap where to go next (or shift-click on a computer).",
		"",
		"Pikes stop cavalry. Swords beat pikes. Cavalry rides down archers, muskets and guns. Muskets go through armour and shake whoever they hit. Flanks and rears take more damage and break faster.",
		"Before a castle: select guns and tap a gate to batter it; foot pressed against a gate ram it.",
		"Pause any time; orders still work. Rally brings broken regiments back near your general.",
	])


# --- theme and save --------------------------------------------------------

func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	t.set_stylebox("normal", "Button", _box(Palette.DESK_RAISED, Color(Palette.BRASS, 0.45)))
	t.set_stylebox("hover", "Button", _box(Palette.DESK_RAISED.lightened(0.08), Palette.BRASS))
	t.set_stylebox("pressed", "Button", _box(Palette.BRASS.darkened(0.45), Palette.GOLD))
	t.set_stylebox("disabled", "Button", _box(Palette.DESK_PANEL, Color(Palette.BRASS, 0.15)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Palette.INK)
	t.set_color("font_hover_color", "Button", Palette.INK)
	t.set_color("font_pressed_color", "Button", Palette.GOLD)
	t.set_color("font_disabled_color", "Button", Palette.INK_DIM)
	t.set_color("font_color", "Label", Palette.INK)
	t.set_stylebox("panel", "PanelContainer", _box(Color(Palette.DESK_PANEL, 0.95), Color(Palette.BRASS, 0.35)))
	var bar_bg := _box(Palette.DESK_RAISED, Palette.DESK_RAISED)
	bar_bg.content_margin_top = 0
	bar_bg.content_margin_bottom = 0
	t.set_stylebox("background", "ProgressBar", bar_bg)
	var bar_fill := _box(Palette.TEAM[0], Palette.TEAM[0])
	bar_fill.content_margin_top = 0
	bar_fill.content_margin_bottom = 0
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	return t


func _load(section: String, key: String, default: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return default
	return cfg.get_value(section, key, default)


## Read, change one value, write back: the file holds the campaign's best
## score and every scenario's stars together.
## Write one value, keeping the rest. A save file that exists but will not
## read is set aside as `.damaged` rather than written over, so whatever
## could be recovered from it is not lost.
func _save(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK and FileAccess.file_exists(save_path):
		DirAccess.rename_absolute(save_path, save_path + ".damaged")
		cfg = ConfigFile.new()
	cfg.set_value(section, key, value)
	cfg.save(save_path)


## Stars drawn rather than typed, so they show whatever the font has.
class StarRow extends Control:
	var earned := 0
	var out_of := 3

	static func make(n: int, px: float, of := 3) -> StarRow:
		var row := StarRow.new()
		row.earned = n
		row.out_of = of
		row.custom_minimum_size = Vector2(px * of + 4.0 * (of - 1), px)
		row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return row

	func _draw() -> void:
		var r := size.y * 0.5
		for i in out_of:
			var c := Vector2(r + i * (size.y + 4.0), r)
			var pts := PackedVector2Array()
			for k in 10:
				pts.append(c + Vector2.from_angle(-PI * 0.5 + k * PI / 5.0) * r * (1.0 if k % 2 == 0 else 0.42))
			draw_colored_polygon(pts, Palette.GOLD if i < earned else Color(Palette.INK_DIM, 0.35))


## A banner as a UI element, for the roster and the enemy list.
class UnitIcon extends Control:
	var kind := 0
	var team := 0

	static func make(k: int, t: int, px: float) -> UnitIcon:
		var icon := UnitIcon.new()
		icon.kind = k
		icon.team = t
		icon.custom_minimum_size = Vector2(px, px)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return icon

	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.5 - 3.0
		Glyphs.banner(self, kind, team, size * 0.5, r * 0.75, 0.0, false, false, false)
