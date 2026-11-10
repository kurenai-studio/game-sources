class_name Results
extends RefCounted
## The scoreboards: one event's final standings, and the championship's medal
## table. Built from Kit pieces so they look like the rest.

const MEDAL := [Color("ffd25a"), Color("d4d4e0"), Color("d0902e")]


## A medal: a little disc with a ribbon, drawn as a control.
static func medal(place: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(12, 12)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		if place < 1 or place > 3:
			return
		var col: Color = MEDAL[place - 1]
		c.draw_rect(Rect2(3, 0, 2, 4), Color("e0383a"))
		c.draw_rect(Rect2(7, 0, 2, 4), Color("2a4ad2"))
		c.draw_circle(Vector2(6, 7.5), 4.5, Color("24152e"))
		c.draw_circle(Vector2(6, 7.5), 3.5, col)
		c.draw_rect(Rect2(4, 5, 1, 1), Color(1, 1, 1, 0.8)))
	return c


## The scoreboard; `got` is what this event unlocked in the dressing room.
static func board(meet: Meet, got: Array = []) -> Control:
	var root := Control.new()
	Kit.fill(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.03, 0.1, 0.55)
	Kit.fill(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var panel := Kit.panel(Color("1a1424"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var title := Kit.label(String(meet.info.get("name", "")).to_upper(), "big", Kit.MUSTARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(podium(meet))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 3)
	box.add_child(grid)
	var st := meet.standings()
	for p in st.size():
		var i: int = st[p]
		var e: Dictionary = meet.entrants[i]
		var human := int(e.get("player", -1)) >= 0
		var col := Kit.MUSTARD if human else Kit.PAPER
		var has_mark := meet.best(i) > 0.0 and not (meet.kind == "race" and not meet.times.has(i))
		grid.add_child(medal(p + 1 if has_mark else 0))
		grid.add_child(Kit.label("%d" % (p + 1), "small", Kit.GREY))
		grid.add_child(Kit.flag_rect(String(e.get("nation", "ngc")), "s"))
		var n := Kit.label(String(e.get("name", "?")), "small", col)
		n.custom_minimum_size.x = 150
		grid.add_child(n)
		var mark := "NO MARK"
		if has_mark:
			mark = Catalog.show_mark(meet.id, meet.best(i))
		var m := Kit.label(mark, "small", Kit.AMBER)
		m.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		m.custom_minimum_size.x = 60
		grid.add_child(m)
	var q := float(meet.info.get("qualify", {}).get(meet.level, 0.0))
	for h in meet.humans():
		var e2: Dictionary = meet.entrants[h]
		var ok := meet.qualified(h)
		var line := Kit.label("%s  %s" % [String(e2.get("name", "")).split(" ")[0],
			("QUALIFIED!" if ok else "NEEDED %s TO QUALIFY" % Catalog.show_mark(meet.id, q))],
			"small", Kit.RELISH if ok else Kit.KETCHUP)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(line)
	var rec := Profile.record(meet.id)
	var r := Kit.label("WORLD RECORD  %s  %s" % [Catalog.show_mark(meet.id, float(rec.mark)), String(rec.get("name", ""))],
		"small", Kit.GREY)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(r)
	if not got.is_empty():
		var new := Kit.label("NEW TO WEAR!  " + Wardrobe.news(got), "small", Kit.RELISH)
		new.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(new)
	var go := Kit.label("TAP TO GO ON", "small", Kit.PAPER)
	go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(go)
	root.add_child(panel)
	Kit.centre(panel, Vector2(0, 6))   # (a little low: the scoreboard's lights are up top)
	return root


## The event's top three on a little podium, flags behind them.
static func podium(meet: Meet) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(200, 72)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := meet.standings()
	var spots := [Vector2(100, 50), Vector2(64, 58), Vector2(136, 63)]
	var heights := [21.0, 13.0, 8.0]
	var views: Array = []
	for p in mini(3, st.size()):
		var e: Dictionary = meet.entrants[st[p]]
		var v := AthleteView.new()
		v.set_look(e.get("look", {}))
		v.position = spots[p]
		v.mood = "joy" if p == 0 else "happy"
		v.ground_shadow = 0.0
		c.add_child(v)
		views.append(v)
	c.draw.connect(func():
		var cols := [Color("ffd25a"), Color("d4d4e0"), Color("d0902e")]
		for p in mini(3, st.size()):
			var at: Vector2 = spots[p]
			var h: float = heights[p]
			c.draw_rect(Rect2(at.x - 17, at.y, 34, h), Color("4e4a62"))
			c.draw_rect(Rect2(at.x - 17, at.y, 34, 2), cols[p])
			var f := Kit.font("small")
			c.draw_string(f, Vector2(at.x - 2, at.y + minf(h - 1, 10)), str(p + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, cols[p]))
	return c


## The nations' medal table for the championship.
static func table(champ: Championship, title_text := "MEDAL TABLE") -> Control:
	var panel := Kit.panel(Color("1a1424"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var title := Kit.label(title_text, "big", Kit.MUSTARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	box.add_child(grid)
	grid.add_child(Control.new())
	grid.add_child(Control.new())
	for p in 3:
		grid.add_child(medal(p + 1))
	var rows := champ.table()
	for row in rows.slice(0, 8):
		grid.add_child(Kit.flag_rect(String(row.nation), "s"))
		var n := Catalog.nation(String(row.nation))
		var name := String(n.get("country", "Night Giraffe" if row.nation == "ngc" else String(row.nation).to_upper()))
		var l := Kit.label(name, "small", Kit.PAPER)
		l.custom_minimum_size.x = 110
		grid.add_child(l)
		for k in ["gold", "silver", "bronze"]:
			grid.add_child(Kit.label(str(row[k]), "small", Kit.AMBER))
	if rows.is_empty():
		box.add_child(Kit.label("No medals yet", "small", Kit.GREY))
	return panel
