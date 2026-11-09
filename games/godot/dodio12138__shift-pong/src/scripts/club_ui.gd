extends Control
## The menus: the title screen, the cups (singles, teams and the legends), the
## training ground, settings, the line-up and tie pages of a team cup, match
## reports, and the coach's tablet between games and in timeouts. Lives in the
## HUD viewport; main.gd passes it input.

const Roster := preload("res://scripts/roster.gd")
const Tie := preload("res://scripts/team_tie.gd")
const Gear := preload("res://scripts/gear.gd")
const People := preload("res://scripts/people.gd")
const Skills := preload("res://scripts/skills.gd")
const UIcons := preload("res://scripts/ui_icons.gd")
const AnalysisPanel := preload("res://scripts/analysis_panel.gd")
## The icon beside each page's title.
const PAGE_ICONS := {"lineup": "squad", "tie": "ball", "boss": "boss", "cup": "cup", "cups": "cup", "solo_setup": "cup",
		"team_setup": "cup", "practice": "train", "loadout": "star", "run": "star", "run_setup": "star", "settings": "cog", "match_report": "league", "tut_done": "book",
		"drill_done": "train"}
const C_INK := Color(0.040, 0.050, 0.100)
const C_NAVY := Color(0.070, 0.090, 0.200)
const C_BAR := Color(0.15, 0.19, 0.32)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_DIM := Color(0.720, 0.780, 0.860)
const C_YELLOW := Color(0.980, 0.800, 0.250)
const C_RED := Color(0.900, 0.080, 0.120)
const C_SKY := Color(0.420, 0.820, 0.980)
const GRIP_NAMES := {"shake": "横拍", "pen": "直拍推挡", "rpb": "直拍横打"}

var main            # the game (main.gd)
var page := ""
var picks: Array = []   # your players (indexes into the club) in A B C order
var opp_plan := {}         # the other side's line-up for this tie, set before yours: {key, line, seen}
const SCOUTED := 1         # how many of their slots your assistant coach finds out
var order_pick := ""
var coach_kind := ""
var coach_by := 0
var boss_sel := "ml"
var boss_mine := 0      # which of your players takes on the boss
var boss_bo := 5
var boss_result := {}   # last boss match: {id, won, games, scores}
var drill_sel := "multi"
var report := {}           # post-match report to show (match_report page)
var report_next := "tie"   # page after the report
var cup_mode := false      # the line-up / tie pages are for a stand-alone team cup
var cup_pick := 0          # cup setup: chosen entrant in the pool
var cup_size := 8
var cup_bo := 5
var cup_pool: Array = []
var settings_back := "title"
var loadout_back := "title"    # where 技能装载 goes back to
var run_pick := 0              # SHIFT RUN setup: the player picked
var run_offer_sel := ""        # SHIFT RUN draft: the offered skill picked, waiting for a slot
var practice_who := 0
var _panel: PanelContainer
var _dim: ColorRect
var pad_tab := "tactics"   # the coach's tablet: "tactics" | "data" | "scout"
var _sb_panel: StyleBoxFlat
var _sb_tablet: StyleBoxTexture
var _box: VBoxContainer
var _focus: Control


## Ten ratings as two rows of short bars, coloured by how good they are.
class AttrBars extends Control:
	var p: Dictionary

	func _init(player: Dictionary) -> void:
		p = player
		custom_minimum_size = Vector2(330.0, 34.0)

	func _draw() -> void:
		var font := get_theme_font("font", "Label")
		# the labels' width sets the columns (the names run longer in English)
		var lw := 0.0
		for at in Roster.ATTRS:
			lw = maxf(lw, font.get_string_size(tr(at[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x)
		var col_w := lw + 4.0 + 36.0 + 8.0
		custom_minimum_size = Vector2(col_w * 5.0, 34.0)
		for i in Roster.ATTRS.size():
			var at := Vector2((i % 5) * col_w, (i / 5) * 17.0)
			var v: int = p.a[i]
			draw_string(font, at + Vector2(0.0, 12.0), tr(Roster.ATTRS[i][1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_DIM)
			var r := Rect2(at + Vector2(lw + 4.0, 3.0), Vector2(36.0, 9.0))
			draw_rect(r, C_BAR)
			var col := C_YELLOW if v >= 85 else (C_WHITE if v >= 72 else (C_SKY if v >= 62 else C_RED))
			draw_rect(Rect2(r.position, Vector2(r.size.x * minf(Roster.t(v), 1.0), r.size.y)), C_RED if v >= 96 else col)


## The ten ratings as a radar (spider) chart: the player's shape filled, an
## optional comparison shape (the squad average) outlined, the rating on each spoke.
class RadarChart extends Control:
	var p: Dictionary
	var cmp: Array      # comparison ratings, same order as Roster.ATTRS ([] = none)

	func _init(player: Dictionary, compare: Array, side := 300.0) -> void:
		p = player
		cmp = compare
		custom_minimum_size = Vector2(side, side)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _pt(c: Vector2, r: float, i: int, n: int, v: float) -> Vector2:
		var ang := -PI * 0.5 + TAU * i / n
		return c + Vector2(cos(ang), sin(ang)) * r * clampf(Roster.t(v), 0.04, 1.0)

	func _draw() -> void:
		var font := get_theme_font("font", "Label")
		var n: int = Roster.ATTRS.size()
		var c := size * 0.5
		var r: float = minf(size.x, size.y) * 0.5 - 34.0
		for ring in [0.25, 0.5, 0.75, 1.0]:
			var pts := PackedVector2Array()
			for i in n + 1:
				var ang := -PI * 0.5 + TAU * (i % n) / n
				pts.append(c + Vector2(cos(ang), sin(ang)) * r * ring)
			draw_polyline(pts, C_BAR, 1.0)
		for i in n:
			var ang := -PI * 0.5 + TAU * i / n
			draw_line(c, c + Vector2(cos(ang), sin(ang)) * r, C_BAR, 1.0)
		if not cmp.is_empty():
			var cp := PackedVector2Array()
			for i in n + 1:
				cp.append(_pt(c, r, i % n, n, float(cmp[i % n])))
			draw_polyline(cp, Color(C_SKY, 0.8), 1.5)
		var poly := PackedVector2Array()
		for i in n:
			poly.append(_pt(c, r, i, n, float(p.a[i])))
		draw_colored_polygon(poly, Color(C_RED, 0.35))
		poly.append(poly[0])
		draw_polyline(poly, C_YELLOW, 2.0)
		for i in n:
			var v: int = p.a[i]
			draw_circle(poly[i], 3.0, C_YELLOW if v >= 85 else C_WHITE)
			var ang := -PI * 0.5 + TAU * i / n
			var lp := c + Vector2(cos(ang), sin(ang)) * (r + 18.0)
			var txt := "%s %d" % [Roster.ATTRS[i][1], v]
			var w := font.get_string_size(tr(txt), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var col := C_YELLOW if v >= 85 else (C_WHITE if v >= 72 else (C_SKY if v >= 62 else C_RED))
			draw_string(font, lp + Vector2(-w * 0.5, 5.0), tr(txt), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)


## A bare 0..100 bar with its number, for table cells.
class MiniBar extends Control:
	var v: float
	var col: Color

	func _init(value: float, color: Color, w: float) -> void:
		v = value
		col = color
		custom_minimum_size = Vector2(w, 14.0)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var font := get_theme_font("font", "Label")
		var r := Rect2(Vector2(0.0, 3.0), Vector2(size.x - 30.0, 8.0))
		draw_rect(r, C_BAR)
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(v / 100.0, 0.0, 1.0), r.size.y)), col)
		draw_string(font, Vector2(r.end.x + 4.0, 12.0), str(int(v)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_WHITE)


## A labelled 0..100 gauge (morale, condition).
class Gauge extends Control:
	var label: String
	var v: float
	var col: Color

	func _init(label_: String, value: float, color: Color) -> void:
		label = label_
		v = value
		col = color
		custom_minimum_size = Vector2(260.0, 16.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var font := get_theme_font("font", "Label")
		draw_string(font, Vector2(0.0, 12.0), tr(label), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_DIM)
		var r := Rect2(Vector2(48.0, 3.0), Vector2(size.x - 84.0, 10.0))
		draw_rect(r, C_BAR)
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(v / 100.0, 0.0, 1.0), r.size.y)), col)
		draw_string(font, Vector2(r.end.x + 6.0, 12.0), str(int(v)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_WHITE)


## A knockout draw drawn as a bracket: one column per round, each match a box
## with both names (the winner bright, the loser dim, yours in red) and the score;
## lines join a match to the one its winner goes on to when the draw is fixed
## (`tree`), the champion at the far right.
## data: {titles [String], rounds [[{a, b, score, w (0 a / 1 b / -1 not played), mine (0 / 1 / -1)}]], tree, champ}
class BracketView extends Control:
	var data: Dictionary
	const BOX_H := 38.0

	func _init(d: Dictionary, sz: Vector2) -> void:
		data = d
		custom_minimum_size = sz
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ys(rounds: Array, top: float, h: float) -> Array:
		var ys := []
		for k in rounds.size():
			var col := []
			var n: int = rounds[k].size()
			for i in n:
				if k > 0 and data.get("tree", false) and ys[k - 1].size() == n * 2:
					col.append((ys[k - 1][i * 2] + ys[k - 1][i * 2 + 1]) * 0.5)
				else:
					col.append(top + (i + 0.5) * h / maxf(n, 1))
			ys.append(col)
		return ys

	func _draw() -> void:
		var font := get_theme_font("font", "Label")
		var rounds: Array = data.rounds
		var cols := rounds.size() + 1
		var cw := size.x / cols
		var bw := cw - 22.0
		var top := 22.0
		var ys := _ys(rounds, top, size.y - top)
		for k in rounds.size():
			var x := k * cw
			draw_string(font, Vector2(x, 13.0), tr(data.titles[k]), HORIZONTAL_ALIGNMENT_LEFT, bw, 12, C_YELLOW)
			for i in rounds[k].size():
				var m: Dictionary = rounds[k][i]
				var y: float = ys[k][i]
				var r := Rect2(Vector2(x, y - BOX_H * 0.5), Vector2(bw, BOX_H))
				var mine: int = m.get("mine", -1)
				draw_rect(r, C_NAVY)
				draw_rect(r, C_RED if mine >= 0 else C_BAR, false, 2.0 if mine >= 0 else 1.0)
				for s in 2:
					var nm: String = m.a if s == 0 else m.b
					var w: int = m.get("w", -1)
					var col := C_WHITE
					if w >= 0 and w != s:
						col = Color(C_DIM, 0.55)
					if mine == s:
						col = C_RED if w < 0 or w == s else Color(C_RED, 0.6)
					if nm == "?":
						col = C_BAR
					var ty := r.position.y + 14.0 + s * 18.0
					draw_string(font, Vector2(r.position.x + 5.0, ty), tr(nm), HORIZONTAL_ALIGNMENT_LEFT, bw - 30.0, 12, col)
					if w >= 0:
						var sc: PackedStringArray = str(m.get("score", "")).replace(" ", "").split(":")
						if sc.size() == 2:
							draw_string(font, Vector2(r.end.x - 20.0, ty), sc[s], HORIZONTAL_ALIGNMENT_RIGHT, 16.0, 12, C_YELLOW if w == s else C_DIM)
				# the line on to the next round
				if k + 1 < rounds.size():
					var x1 := x + bw
					var x2 := (k + 1) * cw
					var xm := (x1 + x2) * 0.5
					if data.get("tree", false) and ys[k + 1].size() * 2 == rounds[k].size():
						var ty2: float = ys[k + 1][i / 2]
						var lc := C_RED if mine >= 0 and m.get("w", -1) == mine else C_BAR
						draw_line(Vector2(x1, y), Vector2(xm, y), lc, 2.0)
						draw_line(Vector2(xm, y), Vector2(xm, ty2), lc, 2.0)
						draw_line(Vector2(xm, ty2), Vector2(x2, ty2), lc, 2.0)
					else:
						draw_line(Vector2(x1, y), Vector2(x1 + 8.0, y), C_BAR, 2.0)
		# the champion
		var cx := rounds.size() * cw
		draw_string(font, Vector2(cx, 13.0), tr("冠军"), HORIZONTAL_ALIGNMENT_LEFT, bw, 12, C_YELLOW)
		var last: Array = ys[rounds.size() - 1] if not rounds.is_empty() else [size.y * 0.5]
		var cy: float = last[0]
		var champ: String = data.get("champ", "")
		var cr := Rect2(Vector2(cx, cy - 20.0), Vector2(bw, 40.0))
		draw_rect(cr, Color(C_YELLOW, 0.18) if champ != "" else C_NAVY)
		draw_rect(cr, C_YELLOW if champ != "" else C_BAR, false, 2.0)
		draw_string(font, Vector2(cx + 6.0, cy + 6.0), tr(champ if champ != "" else "?"), HORIZONTAL_ALIGNMENT_LEFT, bw - 10.0, 16 if champ != "" else 12, C_YELLOW if champ != "" else C_BAR)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(C_INK, 0.6)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_INK, 0.94)
	sb.border_color = C_DIM
	sb.set_border_width_all(2)
	sb.set_content_margin_all(16.0)
	_sb_panel = sb
	# the coach's tablet: a pixel-art bezel (nine-patch) round the screen
	_sb_tablet = StyleBoxTexture.new()
	_sb_tablet.texture = UIcons.tablet_frame()
	var edge := float(UIcons.FRAME_EDGE * 2)
	_sb_tablet.texture_margin_left = edge
	_sb_tablet.texture_margin_right = edge
	_sb_tablet.texture_margin_top = edge
	_sb_tablet.texture_margin_bottom = edge
	_sb_tablet.set_content_margin_all(edge + 10.0)
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	_panel.add_child(_box)
	resized.connect(_center)


func show_page(p: String) -> void:
	page = p
	visible = true
	_panel.add_theme_stylebox_override("panel", _sb_tablet if p == "coach" else _sb_panel)
	_rebuild()


func show_coach(kind: String, by: int) -> void:
	coach_kind = kind
	coach_by = by
	order_pick = main.orders[main.PLAYER]
	show_page("coach")


func show_report(r: Dictionary, next: String) -> void:
	report = r
	report_next = next


## Esc: one step back (quits from the title screen).
func back() -> void:
	match page:
		"title":
			get_tree().quit()
		"cups", "practice":
			show_page("title")
		"solo_setup", "team_setup", "cup":
			show_page("cups")
		"match_report":
			show_page(report_next)
		"lineup":
			show_page("cup")
		"tie":
			main.tie = null
			show_page("cup" if cup_mode else "title")
		"tut_done":
			show_page(main.menu_from)
		"settings":
			show_page(settings_back)
		"drill_done":
			show_page("practice")
		"loadout":
			show_page(loadout_back)
		"run_setup":
			show_page("title")
		"run":
			show_page("title")
		"boss":
			show_page("cups")
		"coach":
			main.end_break(order_pick)


func _rebuild() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_focus = null
	call("_page_" + page)
	_panel.reset_size()
	_center.call_deferred()
	if _focus != null:
		_focus.grab_focus.call_deferred()


func _center() -> void:
	_panel.reset_size()
	_panel.position = ((size - _panel.size) * 0.5).floor()


# ---------------------------------------------------------------- pages

func _page_match_report() -> void:
	var r: Dictionary = report
	var won: bool = r.games[0] > r.games[1]
	_title("%s · %s" % [r.title, "胜" if won else "负"])
	_text("%s  %d : %d  %s     %s" % [r.names[0], r.games[0], r.games[1], r.names[1], " ".join(PackedStringArray(r.scores))], C_WHITE)
	_text("评分   %s %.1f      %s %.1f" % [r.names[0], r.ratings[0], r.names[1], r.ratings[1]], C_YELLOW)
	var tc: Dictionary = r.tech
	_gap()
	var P := 1
	var A := -1
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 28)
	_box.add_child(grid)
	var pct := func(w: int, n: int) -> String: return "%d%%" % int(100.0 * w / n) if n > 0 else "—"
	var rows := [["", r.names[0], r.names[1]],
			["得分", str(tc[P].pts), str(tc[A].pts)],
			["主动得分（对手没接到）", str(tc[P].winners), str(tc[A].winners)],
			["失误送分", str(tc[P].errors), str(tc[A].errors)],
			["发球轮得分率", pct.call(tc[P].serve_w, tc[P].serve_n), pct.call(tc[A].serve_w, tc[A].serve_n)],
			["接发轮得分率", pct.call(tc[P].recv_w, tc[P].recv_n), pct.call(tc[A].recv_w, tc[A].recv_n)]]
	for row in rows:
		for c in 3:
			_text(row[c], C_DIM if c == 0 or row[0] == "" else C_WHITE, grid)
	if int(tc.rally_n) > 0:
		_text("平均回合 %.1f 板 · 最长回合 %d 板" % [float(tc.rally_sum) / tc.rally_n, tc.rally_max], C_DIM)
	_gap()
	_focus = _button("继续", func(): show_page(report_next))


func _page_tut_done() -> void:
	_title("新手教学完成！")
	for line in ["上旋：挡或者拉；下旋：搓或者用力拉起来", "侧旋：用反方向的那一列（Q A / E D）抵消", "力度看球拍左边的弧线：按住到绿色区段（响一声）就松手，红了是用力过头",
			"搓球会自己吃掉大部分旋转，接下旋轻按 S 就能搓过去",
			"发球：按住选旋转，指针在亮区松手；按住 Shift 松手是假动作", "专注卡：连丢两分得一张，按 T 让时间变慢",
			"按住 Shift 打开技能轮盘：每场带 4 个技能（在「技能装载」里换），比分每到 4 的倍数规则会转移",
			"F 切换观战 / 亲自打，C 换视角，B 看回放，Tab 隐藏按键说明"]:
		_text("· " + line, C_WHITE)
	_gap()
	_focus = _button("返回训练场", func(): show_page("practice"))


func _page_settings() -> void:
	var st: Dictionary = main.settings
	_title("设置")
	# the language row first, each name in its own language
	var lrow0 := _row()
	_text("语言 · Language", C_YELLOW, lrow0)
	for lg in main.LANGS:
		var pick := func():
			st.lang = lg[0]
			_apply_settings()
		var lb := _button(lg[1], pick, lrow0, str(st.get("lang", "en")) == lg[0])
		lb.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var vrow := _row()
	_text("音量", C_YELLOW, vrow)
	var dn := func():
		st.volume = maxi(int(st.volume) - 1, 0)
		_apply_settings()
	var up := func():
		st.volume = mini(int(st.volume) + 1, 10)
		_apply_settings()
	_focus = _button("－", dn, vrow)
	_text(" %s %d " % ["■".repeat(int(st.volume)) + "□".repeat(10 - int(st.volume)), int(st.volume)], C_WHITE, vrow)
	_button("＋", up, vrow)
	var prow := _row()
	_text("像素大小", C_YELLOW, prow)
	for i in 5:
		var pick := func():
			st.pixel = i
			_apply_settings()
		_button(str(i + 1), pick, prow, int(st.pixel) == i)
	var crow := _row()
	_text("默认视角", C_YELLOW, crow)
	var cam := func():
		st.cam = (int(st.cam) + 1) % main.CAM_MODES.size()
		_apply_settings()
	_button(main.CAM_MODES[int(st.cam)], cam, crow)
	var hrow := _row()
	_text("操作辅助", C_YELLOW, hrow)
	for i in main.HELP_LEVELS.size():
		var pick_h := func():
			st.help = i
			_apply_settings()
		_button(main.HELP_LEVELS[i].name, pick_h, hrow, int(st.get("help", 1)) == i)
	_text(main.HELP_LEVELS[clampi(int(st.get("help", 1)), 0, main.HELP_LEVELS.size() - 1)].desc, C_DIM, hrow)
	var krow := _row()
	_text("技能乒乓球", C_YELLOW, krow)
	var sk := func():
		st.skill_mode = not bool(st.get("skill_mode", false))
		_apply_settings()
	_button("开" if st.get("skill_mode", false) else "关", sk, krow, st.get("skill_mode", false))
	_text("每局 5 张专注卡，按住 Shift 打开技能轮盘放离谱招数", C_DIM, krow)
	var urow := _row()
	_text("界面信息", C_YELLOW, urow)
	for v in [["simple", "简洁"], ["full", "详细"]]:
		var pick_u := func():
			st.hud = v[0]
			_apply_settings()
		_button(v[1], pick_u, urow, str(st.get("hud", "simple")) == v[0])
	_text("比赛中按 Tab 切换", C_DIM, urow)
	var mrow := _row()
	_text("音乐", C_YELLOW, mrow)
	var mus := func():
		st.music = not bool(st.get("music", true))
		_apply_settings()
	_button("开" if st.get("music", true) else "关", mus, mrow, st.get("music", true))
	var lrow := _row()
	_text("按键说明栏", C_YELLOW, lrow)
	var leg := func():
		st.legend = not bool(st.legend)
		_apply_settings()
	_button("显示" if st.legend else "隐藏", leg, lrow)
	_gap()
	_button("返回", func(): show_page(settings_back))


func _apply_settings() -> void:
	main.apply_settings()
	main.save_settings()
	show_page("settings")


# ---------------------------------------------------------------- title screen and modes

func _page_title() -> void:
	cup_mode = false
	# the pixel-art wordmark in the current language (art/logo_*.png)
	var lang: String = str(main.settings.get("lang", "en"))
	var logo := TextureRect.new()
	logo.texture = load("res://art/logo_%s@2.png" % (lang if lang in ["zh", "en", "ja"] else "en"))
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	logo.custom_minimum_size = Vector2(0.0, logo.texture.get_height() + 8.0)
	_box.add_child(logo)
	_gap()
	if not bool(main.settings.get("tut_offered", false)):
		# the very first time: the two-minute lessons, or straight in
		var frow := _row()
		frow.alignment = BoxContainer.ALIGNMENT_CENTER
		_text("第一次玩？", C_YELLOW, frow)
		var learn := func():
			main.settings.tut_offered = true
			main.save_settings()
			main.start_tutorial("practice")
		var skip := func():
			main.settings.tut_offered = true
			main.save_settings()
			show_page("title")
		_focus = _button("两分钟新手教学", learn, frow, true)
		_button("跳过", skip, frow)
		_gap()
	# one line under the buttons says what the one you point at does
	var hint := Label.new()
	var on_run: bool = main.shift_run != null and not main.shift_run.is_over()
	var best := int(main.settings.get("run_best", 0))
	var run_hint := "连打 %d 个对手，赢一场换一个技能" % main.ShiftRun.STAGES + ("   最佳：%d / %d" % [best, main.ShiftRun.STAGES] if best > 0 else "")
	var rb := _button("继续 SHIFT RUN" if on_run else "SHIFT RUN", func(): show_page("run" if on_run else "run_setup"))
	rb.add_theme_font_size_override("font_size", 16)
	rb.custom_minimum_size = Vector2(360.0, 40.0)
	_hint_on(rb, run_hint, hint)
	if _focus == null:
		_focus = rb
	var modes := _row()
	modes.add_theme_constant_override("separation", 6)
	for m in [["快速开始", func(): main.quick_start(), "直接打一局 7 分，带技能"],
			["杯赛", func(): show_page("cups"), "个人赛 · 团体赛 · BOSS 挑战"],
			["训练场", func(): show_page("practice"), "新手教学 · 训练项目 · 自由对练"]]:
		var b := _button(m[0], m[1], modes)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_hint_on(b, m[2], hint)
	hint.text = run_hint
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", C_SKY)
	hint.add_theme_font_size_override("font_size", 12)
	_box.add_child(hint)
	_gap()
	var row := _row()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var lo := func():
		loadout_back = "title"
		show_page("loadout")
	var lb := _button("技能装载", lo, row)
	lb.icon = UIcons.get_icon("star")
	_hint_on(lb, "、".join(PackedStringArray(main.settings.loadout.map(func(id): return tr(_skill(id).get("name", "?"))))), hint)
	var sets := func():
		settings_back = "title"
		show_page("settings")
	_button("设置", sets, row)
	_button("退出", func(): get_tree().quit(), row)


## Shows `text` in `label` while the mouse or the keyboard focus is on `b`.
func _hint_on(b: Control, text: String, label: Label) -> void:
	b.mouse_entered.connect(func(): label.text = text)
	b.focus_entered.connect(func(): label.text = text)


func _page_cups() -> void:
	_title("杯赛")
	_text("单独的一届杯赛，随机生成的世界。", C_DIM)
	_gap()
	var solo := func():
		main.cup_run = main.CupRun.new()
		cup_pool = main.cup_run.solo_pool()
		cup_pick = 4   # the best non-boss player
		show_page("solo_setup")
	_focus = _button("个人赛  ·  选一名球员（包括四位传奇）打淘汰赛", solo)
	var team := func():
		main.cup_run = main.CupRun.new()
		cup_pool = main.cup_run.team_pool()
		cup_pick = 1
		show_page("team_setup")
	_button("团体赛  ·  选一支球队（或传奇明星队）打团体淘汰赛", team)
	_button("BOSS 挑战  ·  挑战四位传奇", func(): show_page("boss"))
	_gap()
	_button("返回", func(): show_page("title"))


func _page_solo_setup() -> void:
	_title("个人赛 · 选择球员")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	_box.add_child(grid)
	for i in mini(cup_pool.size(), 24):
		var p: Dictionary = cup_pool[i]
		var pick := func():
			cup_pick = i
			show_page("solo_setup")
		var b := _button("%s %d" % [p.name, Roster.overall(p)], pick, grid, i == cup_pick)
		b.custom_minimum_size = Vector2(130.0, 24.0)
		if i == cup_pick:
			_focus = b
	var me: Dictionary = cup_pool[cup_pick]
	_gap()
	_text(_line(me), C_YELLOW)
	_box.add_child(AttrBars.new(me))
	_text(Skills.line(me, "tech") + "    " + Skills.line(me, "mind"), C_DIM)
	_gap()
	var nav := _row()
	var sz := func():
		cup_size = 16 if cup_size == 8 else 8
		show_page("solo_setup")
	_button("签表：%d 人" % cup_size, sz, nav)
	var fm := func():
		cup_bo = 3 if cup_bo == 5 else 5
		show_page("solo_setup")
	_button("赛制：%s" % ("5 局 3 胜" if cup_bo == 5 else "3 局 2 胜"), fm, nav)
	var go := func():
		main.cup_run.setup_solo(cup_pool, cup_pool[cup_pick], cup_size, cup_bo)
		show_page("cup")
	_button("开赛", go, nav)
	_button("返回", func(): show_page("cups"), nav)


func _page_team_setup() -> void:
	_title("团体赛 · 选择球队")
	for i in cup_pool.size():
		var c: Dictionary = cup_pool[i]
		var row := _row()
		var pick := func():
			cup_pick = i
			show_page("team_setup")
		var b := _button("%s  实力 %.0f" % [c.name, main.CupRun._top3(c)], pick, row, i == cup_pick)
		b.custom_minimum_size = Vector2(170.0, 24.0)
		if i == cup_pick:
			_focus = b
		_text("  ".join(PackedStringArray(c.players.map(func(p): return "%s %d" % [p.name, Roster.overall(p)]))), C_DIM, row)
	_gap()
	_text("八队单淘汰：每轮一场团体赛（五场单打，先赢三场），3 局 2 胜。", C_DIM)
	var nav := _row()
	var go := func():
		main.cup_run.setup_team(cup_pool, cup_pool[cup_pick])
		show_page("cup")
	_button("开赛", go, nav)
	_button("返回", func(): show_page("cups"), nav)


func _page_cup() -> void:
	var cr = main.cup_run
	var solo: bool = cr.kind == "solo"
	_title("%s · %s" % ["个人赛" if solo else "团体赛", "冠军揭晓" if cr.is_over() else cr.stage_name()])
	var n: int = cr.entrants.size()
	_box.add_child(BracketView.new(_bracket_cuprun(cr), Vector2(940.0 if n > 8 else 760.0, 430.0 if n > 8 else 300.0)))
	if cr.is_over():
		_gap()
		var champ: Dictionary = cr.entrants[cr.champion]
		var won: bool = cr.champion == cr.mine
		var t := _text(("%s 夺冠！" % champ.name) if won else "冠军：%s" % champ.name, C_YELLOW if won else C_WHITE)
		t.add_theme_font_size_override("font_size", 24)
		var nav := _row()
		_focus = _button("再来一届", func(): show_page("cups"), nav)
		_button("标题", func(): show_page("title"), nav)
		return
	_gap()
	if cr.my_tie() >= 0:
		var t: Array = cr.ties[cr.my_tie()]
		_text("本轮对手  %s" % cr.label(t[1] if t[0] == cr.mine else t[0]), C_YELLOW)
	var nav := _row()
	if cr.my_tie() >= 0:
		if solo:
			_focus = _button("亲自上台", func(): main.play_cup_solo(true), nav)
			_button("教练席指挥", func(): main.play_cup_solo(false), nav)
		else:
			var line_up := func():
				cup_mode = true
				picks = []
				show_page("lineup")
			_focus = _button("排阵出战", line_up, nav)
		var sim := func():
			cr.sim_mine()
			show_page("cup")
		_button("模拟这一轮", sim, nav)
		_loadout_button(nav, "cup")
	else:
		_text("你已经出局了。", C_DIM)
		var rest := func():
			while not cr.is_over():
				cr.resolve(false, 0, 0)
			show_page("cup")
		_focus = _button("看完剩下的比赛", rest, nav)
	_button("退出杯赛", func(): show_page("cups"), nav)


func _page_practice() -> void:
	_title("训练场")
	_text("随便练，想练什么练什么。", C_DIM)
	_gap()
	_focus = _button("新手教学（六课）", func(): main.start_tutorial("practice"))
	_button("自由对练（按 L 调难度）", func(): main.quick_play())
	_button("技能对轰（无限技能，按 L 调难度）", func(): main.skill_test_play())
	_loadout_button(_box, "practice")
	_gap()
	_text("训练项目 · 选一名球员", C_YELLOW)
	var ps: Array = Roster.CLUBS[0].players
	var row := _row()
	for i in ps.size():
		var pick := func():
			practice_who = i
			show_page("practice")
		_button("%s %d" % [ps[i].name, Roster.overall(ps[i])], pick, row, i == practice_who)
	var drow := _row()
	for k in ["multi", "target", "receive"]:
		var go := func():
			var p: Dictionary = ps[practice_who].duplicate(true)
			People.ensure(p)
			main.start_drill(k, p, true, true)
		_button(main.DRILLS[k].name, go, drow)
	_text("多球调动练步法 · 定点打靶练落点 · 接发球练读旋转", C_DIM)
	_gap()
	_button("返回", func(): show_page("title"))


## SHIFT RUN, before it starts: who you take in, and your four skills.
func _page_run_setup() -> void:
	_title("SHIFT RUN")
	_text("连打 %d 个对手，每场一局 %d 分，最后一个是传奇。赢一场可以从三个新技能里换一个进来。输一场扣一颗心，同一个对手再来；%d 颗心用完就结束。" % [main.ShiftRun.STAGES, main.ShiftRun.GAME_TO, main.ShiftRun.HEARTS], C_DIM).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gap()
	_text("选一名球员", C_YELLOW)
	var ps: Array = _challengers().players
	var row := _row()
	for i in ps.size():
		var pick := func():
			run_pick = i
			show_page("run_setup")
		var b := _button("%s %d" % [ps[i].name, Roster.overall(ps[i])], pick, row, i == run_pick)
		if i == run_pick:
			_focus = b
	var me: Dictionary = ps[run_pick]
	_text(_line(me), C_WHITE)
	_box.add_child(AttrBars.new(me))
	_gap()
	_loadout_button(_box, "run_setup")
	_gap()
	var nav := _row()
	var go := func():
		main.shift_run = main.ShiftRun.new(me.duplicate(true), main.settings.loadout)
		run_offer_sel = ""
		show_page("run")
	_button("开始", go, nav, true).icon = UIcons.get_icon("play")
	_button("返回", func(): show_page("title"), nav)


## SHIFT RUN: the ladder of six, your hearts and skills, then either the next
## opponent, the skills offered after a win, or how the run ended.
func _page_run() -> void:
	var r = main.shift_run
	var n: int = main.ShiftRun.STAGES
	_title("SHIFT RUN  ·  %s" % ("通关！" if r.won_all() else ("结束" if r.is_over() else "第 %d / %d 关" % [r.stage + 1, n])))
	# the ladder
	var lad := HBoxContainer.new()
	lad.add_theme_constant_override("separation", 6)
	_box.add_child(lad)
	for k in n:
		var o: Dictionary = r.ladder[k]
		var c := _card(lad)
		c.custom_minimum_size = Vector2(128.0, 0.0)
		var col := C_DIM if k > r.stage else (C_YELLOW if k == r.stage and not r.is_over() else C_SKY)
		_text(("BOSS" if k == n - 1 else "第 %d 关" % (k + 1)), col, c)
		_text(o.name if k <= r.stage or k == n - 1 else "?", C_WHITE if k <= r.stage else C_DIM, c)
		_text("综合 %d" % Roster.overall(o) if k <= r.stage or k == n - 1 else "", C_DIM, c)
		if k < r.stage:
			_text("✓ 胜", C_SKY, c)
	var st := _row()
	_text("心 " + "♥".repeat(r.hearts) + "♡".repeat(main.ShiftRun.HEARTS - r.hearts), C_RED, st)
	_text("   技能：" + "、".join(PackedStringArray(r.loadout.map(func(id): return _skill(id).get("name", "?")))), C_YELLOW, st)
	_gap()
	if r.is_over():
		var t := _text(("全部 %d 关通关！你就是 SHIFT 王者。" % n) if r.won_all() else ("止步第 %d 关。" % (r.stage + 1)), C_YELLOW if r.won_all() else C_WHITE)
		t.add_theme_font_size_override("font_size", 24)
		var nav := _row()
		var again := func():
			main.shift_run = null
			show_page("run_setup")
		_focus = _button("再来一次", again, nav)
		_button("标题", func():
			main.shift_run = null
			show_page("title"), nav)
		return
	if not r.offer.is_empty():
		_head("star", "赢了！选一个新技能换进来（也可以跳过）", _box)
		var grid := HBoxContainer.new()
		grid.add_theme_constant_override("separation", 8)
		_box.add_child(grid)
		for id in r.offer:
			var sk := _skill(id)
			var c := _card(grid)
			c.custom_minimum_size = Vector2(250.0, 0.0)
			var sel := func():
				run_offer_sel = id
				show_page("run")
			var b := _button(sk.name, sel, c, run_offer_sel == id)
			if _focus == null:
				_focus = b
			_text("专注 ×%d · %s" % [sk.cost, "击球附带" if main.STROKE_SKILLS.has(id) else "持续两分"], C_YELLOW, c)
			var d := _text(sk.desc, C_DIM, c)
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			d.custom_minimum_size = Vector2(230.0, 0.0)
		var srow := _row()
		if run_offer_sel != "":
			_text("换掉：", C_YELLOW, srow)
			for k in r.loadout.size():
				var swap := func():
					r.take(run_offer_sel, k)
					run_offer_sel = ""
					show_page("run")
				_button(_skill(r.loadout[k]).name, swap, srow)
		var skip := func():
			r.offer = []
			run_offer_sel = ""
			show_page("run")
		_button("跳过", skip, srow)
		return
	var opp: Dictionary = r.opponent()
	_head("boss" if r.is_boss() else "person", "下一个对手", _box)
	_text(_line(opp), C_WHITE)
	if r.is_boss():
		_text("「%s」  %s" % [opp.title, Skills.line(opp, "tech")], C_YELLOW)
	var nav := _row()
	_focus = _button("上台", func(): main.play_run(), nav, true)
	_focus.icon = UIcons.get_icon("play")
	var quit := func():
		main.shift_run = null
		show_page("title")
	_button("放弃", quit, nav)


## The button into 技能装载, with the four skills you're taking.
func _loadout_button(parent: Control, back_to: String) -> void:
	var names: Array = main.settings.loadout.map(func(id): return _skill(id).get("name", "?"))
	var go := func():
		loadout_back = back_to
		show_page("loadout")
	var b := _button("技能装载：%s" % "、".join(PackedStringArray(names)), go, parent)
	b.icon = UIcons.get_icon("star")


func _skill(id: String) -> Dictionary:
	for s in main.SKILL_SLOTS:
		if s.id == id:
			return s
	return {}


## 技能装载: the four skills you take into every match, picked from all of
## them; the order is the number keys' (1-4) and the wheel's (clockwise). With
## four picked, another one takes the last one's place.
func _page_loadout() -> void:
	var lo: Array = main.settings.loadout
	_title("技能装载（选 %d 个）" % main.LOADOUT_SIZE)
	_text("每场比赛带 %d 个技能：按住 Shift 打开轮盘，或者按数字键 1-%d。对手也只带 %d 个。" % [main.LOADOUT_SIZE, main.LOADOUT_SIZE, main.LOADOUT_SIZE], C_DIM)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_box.add_child(grid)
	for s in main.SKILL_SLOTS:
		var id: String = s.id
		var at := lo.find(id)
		var c := _card(grid)
		c.custom_minimum_size = Vector2(250.0, 0.0)
		var toggle := func():
			if lo.has(id):
				lo.erase(id)
			elif lo.size() < main.LOADOUT_SIZE:
				lo.append(id)
			else:
				lo[-1] = id   # full: swaps out the last one picked
			main.save_settings()
			show_page("loadout")
		var kind := "击球附带" if main.STROKE_SKILLS.has(id) else "持续两分"
		var b := _button(("%d  %s" % [at + 1, s.name]) if at >= 0 else s.name, toggle, c, at >= 0)
		if _focus == null:
			_focus = b
		_text("专注 ×%d · %s" % [s.cost, kind], C_YELLOW, c)
		var d := _text(s.desc, C_DIM, c)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(230.0, 0.0)
	_gap()
	var nav := _row()
	if lo.size() < main.LOADOUT_SIZE:
		_text("还差 %d 个" % (main.LOADOUT_SIZE - lo.size()), C_RED, nav)
	_button("返回", func(): show_page(loadout_back), nav).disabled = lo.size() < main.LOADOUT_SIZE


func _gap_in(parent: Control) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0.0, 6.0)
	parent.add_child(c)
	return c


## The other side's line-up for the tie about to be played: settled before
## yours (the AI coach doesn't see yours either), and how many of its slots your
## assistant coach found out (one of the three). Kept for the round, so going
## back and forth changes nothing.
func _opp_plan(opp: Dictionary) -> Dictionary:
	var key := "%s@%d" % [opp.get("id", opp.name), main.cup_run.hist.size()]
	if opp_plan.get("key", "") != key:
		var line: Array = Tie.ai_lineup(opp)
		var n := SCOUTED
		var slots := [0, 1, 2]
		var rng := RandomNumberGenerator.new()
		rng.seed = absi(hash(key))
		for k in 3:
			var m := rng.randi_range(k, 2)
			var tmp: int = slots[k]
			slots[k] = slots[m]
			slots[m] = tmp
		opp_plan = {"key": key, "line": line, "seen": slots.slice(0, n)}
	return opp_plan


## 排阵 (田忌赛马): what your assistant coach found out about their order, your
## three in A B C, and the five matches that makes with your chances in the ones
## you can see.
func _page_lineup() -> void:
	_title("排出场名单 · 田忌赛马")
	_text("五场单打 A-X  B-Y  C-Z  A-Y  B-X，每场一局 11 分，先赢三场获胜。前三场三人各打一场，A、B 可能再打一场。", C_DIM)
	var club: Dictionary = _my_club()
	var opp: Dictionary = main.cup_run.opponent()
	var plan := _opp_plan(opp)
	var their: Array = plan.line
	var seen: Array = plan.seen
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	_box.add_child(cols)
	# their side, as far as your assistant knows
	var oc := _card(cols)
	oc.custom_minimum_size = Vector2(330.0, 0.0)
	_head("eye", "对方排阵（助教情报 %d / 3）" % seen.size(), oc)
	for k in 3:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		oc.add_child(row)
		var sl := _text(Tie.SLOTS_AWAY[k], C_YELLOW, row)
		sl.custom_minimum_size = Vector2(20.0, 0.0)
		if seen.has(k):
			var p: Dictionary = their[k]
			_text("%s  综合 %d  %s" % [p.name, Roster.overall(p), GRIP_NAMES[p.grip]], C_WHITE, row)
		else:
			_text("?  （没打听到）", C_DIM, row)
	_text("助理教练打听到了 1 个位置，其余靠猜", C_DIM, oc)
	_text("对方名单：" + "、".join(PackedStringArray(opp.players.map(func(p): return "%s %d" % [p.name, Roster.overall(p)]))), C_DIM, oc).autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	# yours
	var mc := _card(cols)
	mc.custom_minimum_size = Vector2(420.0, 0.0)
	_head("squad", "我方：按顺序点三名球员（A → B → C）", mc)
	for i in club.players.size():
		var p: Dictionary = club.players[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		mc.add_child(row)
		var at := picks.find(i)
		var tag: String = Tie.SLOTS_HOME[at] if at >= 0 else ("伤" if p.get("injured", 0) > 0 else "—")
		var toggle := func():
			if picks.has(i):
				picks.erase(i)
			elif picks.size() < 3:
				picks.append(i)
			show_page("lineup")
		var b := _button(" %s " % tag, toggle, row, at >= 0)
		b.custom_minimum_size = Vector2(40.0, 30.0)
		b.disabled = p.get("injured", 0) > 0
		if _focus == null:
			_focus = b
		_text("%s  综合 %d  %s  状态 %d" % [p.name, Roster.overall(p), GRIP_NAMES[p.grip], int(p.get("cond", 100.0))], C_WHITE, row)
	# the five matches this makes
	var tc := _card(_box)
	_head("league", "对位与胜率（只算得出看得到的位置）", tc)
	for m in Tie.ORDER.size():
		var hi: int = Tie.ORDER[m][0]
		var ai: int = Tie.ORDER[m][1]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		tc.add_child(row)
		var ml := _text("第 %d 场  %s-%s" % [m + 1, Tie.SLOTS_HOME[hi], Tie.SLOTS_AWAY[ai]], C_DIM, row)
		ml.custom_minimum_size = Vector2(110.0, 0.0)
		var me_s: String = club.players[picks[hi]].name if hi < picks.size() else "?"
		var th_s: String = their[ai].name if seen.has(ai) else "?"
		var vl := _text("%s  vs  %s" % [me_s, th_s], C_WHITE, row)
		vl.custom_minimum_size = Vector2(180.0, 0.0)
		if hi < picks.size() and seen.has(ai):
			var pw: float = main.Tour.game_p(Roster.effective(club.players[picks[hi]]), Roster.effective(their[ai]))
			row.add_child(MiniBar.new(pw * 100.0, C_SKY if pw >= 0.5 else C_RED, 160.0))
			_text("%d%%" % int(pw * 100.0), C_SKY if pw >= 0.5 else C_RED, row)
		else:
			_text("—", C_DIM, row)
	_text("田忌赛马：用你的强点去打对方的弱点，弱一点的球员放在对方主力那一路，换来另外两场的胜算。", C_DIM)
	var nav := _row()
	var confirm := func():
		var line := []
		for i in picks:
			line.append(club.players[i])
		main.begin_cup_tie(line, their)
		show_page("tie")
	var ok := _button("确认名单", confirm, nav, picks.size() == 3)
	ok.icon = UIcons.get_icon("play")
	ok.disabled = picks.size() < 3
	_button("返回", func(): show_page("cup"), nav)


func _page_tie() -> void:
	var t = main.tie
	_title("%s  %d : %d  %s" % [t.home.name, t.wins[1], t.wins[-1], t.away.name])
	_text("赛制：五场单打，每场一局 11 分，先赢三场", C_DIM)
	_gap()
	for i in 5:
		var pr: Array = t.pair(i)
		var slots := "%s-%s" % [Tie.SLOTS_HOME[Tie.ORDER[i][0]], Tie.SLOTS_AWAY[Tie.ORDER[i][1]]]
		var s := "第 %d 场  %s  %s  vs  %s" % [i + 1, slots, pr[0].name, pr[1].name]
		var col := C_DIM
		if i < t.results.size():
			var r: Dictionary = t.results[i]
			s += "    %d : %d   (%s)" % [r.games[0], r.games[1], " ".join(PackedStringArray(r.scores))]
			col = C_YELLOW if r.winner == 1 else C_SKY
		elif i == t.index() and not t.is_over():
			s = "下一场  " + s
			col = C_WHITE
		elif t.is_over():
			s += "    未进行"
		_text(s, col)
	_gap()
	if t.is_over():
		var won: bool = t.wins[1] >= 3
		_title("%s 赢下团体赛!" % t.home.name if won else "惜败 · %s 获胜" % t.away.name)
		var nav := _row()
		if cup_mode:
			var go_on := func():
				main.cup_run.resolve(t.wins[1] > t.wins[-1], t.wins[1], t.wins[-1])
				main.tie = null
				show_page("cup")
			_focus = _button("继续", go_on, nav)
			return
		_focus = _button("主菜单", func(): show_page("title"), nav)
		return
	var pr: Array = t.pair()
	var duel := _row()
	for k in 2:
		var p: Dictionary = pr[k]
		var col := VBoxContainer.new()
		duel.add_child(col)
		_text(("我方 " if k == 0 else "对方 ") + _line(p), C_RED if k == 0 else C_SKY, col)
		col.add_child(AttrBars.new(p))
		if k == 1:
			_text("球探：" + Roster.scout_note(p), C_YELLOW, col)
	# pre-match plan for your player: what he does from the first point
	var me_p: Dictionary = pr[0]
	var sug: String = Tie.suggest(pr[1])
	var prow := _row()
	_text("赛前战术", C_YELLOW, prow)
	for k in Tie.ORDER_KEYS:
		var pick := func():
			me_p["plan"] = k
			show_page("tie")
		_button(Tie.ORDERS[k].name, pick, prow, str(me_p.get("plan", "")) == k)
	_text("球探建议：%s%s" % [Tie.ORDERS[sug].name, "（已采用）" if me_p.get("plan", "") == sug else ""], C_SKY)
	_gap()
	var nav := _row()
	_focus = _button("亲自上台", func(): main.play_tie_match(true), nav)
	_button("教练席指挥", func(): main.play_tie_match(false), nav)
	var quit_tie := func():
		main.tie = null
		show_page("cup" if cup_mode else "title")
	_button("放弃团体赛", quit_tie, nav)
	_text("比赛中：F 切换上台 / 教练席 · Y 叫暂停（每场一次）· M 退出本场", C_DIM)


func _page_drill_done() -> void:
	var r: Dictionary = main.drill_result
	_title("%s · 评级 %s" % [main.DRILLS[r.kind].name, r.grade])
	_text("%s   得分 %d / %d" % [r.name, r.score, r.max], C_WHITE)
	_gap()
	var nav := _row()
	_focus = _button("再练一组", func(): main.callv("start_drill", main.last_drill), nav)
	_button("返回训练场", func(): show_page("practice"), nav)


func _my_club() -> Dictionary:
	return main.cup_run.entrants[main.cup_run.mine]


## BOSS 挑战: the four legends as cards (beaten or not), the one picked
## against the player you'd send (radar), his game and the last result.
func _page_boss() -> void:
	var beaten: Array = main.settings.beaten
	_title("BOSS 挑战")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_box.add_child(row)
	for b0 in Roster.BOSSES:
		var b: Dictionary = b0
		var id: String = b.id
		var c := _card(row)
		c.custom_minimum_size = Vector2(220.0, 0.0)
		var pick := func():
			boss_sel = id
			show_page("boss")
		var btn := _button("%s「%s」" % [b.name, b.title], pick, c, id == boss_sel)
		btn.icon = UIcons.get_icon("boss")
		if id == boss_sel:
			_focus = btn
		var st := "已击败" if beaten.has(id) else "未击败"
		_text("%s · 综合 %d" % [st, Roster.overall(b)], C_YELLOW if beaten.has(id) else C_DIM, c)
	var b: Dictionary = Roster.boss(boss_sel)
	var club: Dictionary = _challengers()
	boss_mine = clampi(boss_mine, 0, club.players.size() - 1)
	var me: Dictionary = club.players[boss_mine]
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	_box.add_child(cols)
	var lv := VBoxContainer.new()
	cols.add_child(lv)
	lv.add_child(RadarChart.new(b, me.a, 300.0))
	var key := HBoxContainer.new()
	key.add_theme_constant_override("separation", 8)
	lv.add_child(key)
	_icon("sw_y", key)
	_text(b.name, C_YELLOW, key)
	_icon("sw_s", key)
	_text(me.name, C_SKY, key)
	var info := _card(cols)
	info.custom_minimum_size = Vector2(520.0, 0.0)
	_head("boss", "%s「%s」  %s · %s%s" % [b.name, b.title, GRIP_NAMES[b.grip], Roster.STYLES[b.style].name, " · 左手" if b.hand < 0 else ""], info)
	for sk in b.notes:
		_text("%s —— %s" % [sk[0], sk[1]], C_WHITE, info)
	_text(Skills.line(b, "tech"), C_YELLOW, info)
	_text(Skills.line(b, "mind"), C_YELLOW, info)
	if not boss_result.is_empty() and boss_result.id == boss_sel:
		_text("上一场：%s  %d : %d   (%s)" % ["赢了!" if boss_result.won else "输了", boss_result.games[0], boss_result.games[1],
				" ".join(PackedStringArray(boss_result.scores))], C_YELLOW if boss_result.won else C_SKY, info)
	_head("person", "派谁上", info)
	var mine := HBoxContainer.new()
	mine.add_theme_constant_override("separation", 6)
	info.add_child(mine)
	for k in club.players.size():
		var p: Dictionary = club.players[k]
		var choose := func():
			boss_mine = k
			show_page("boss")
		_button("%s %d" % [p.name, Roster.overall(p)], choose, mine, k == boss_mine)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	info.add_child(nav)
	var flip := func():
		boss_bo = 3 if boss_bo == 5 else 5
		show_page("boss")
	_button("赛制：%s" % ("3 局 2 胜" if boss_bo == 3 else "5 局 3 胜"), flip, nav)
	_loadout_button(nav, "boss")
	_button("亲自上台", func(): main.play_boss(boss_sel, me, true, boss_bo), nav, true).icon = UIcons.get_icon("play")
	_button("教练席指挥", func(): main.play_boss(boss_sel, me, false, boss_bo), nav)
	_button("返回", func(): show_page("cups"), nav).icon = UIcons.get_icon("left")


## The challengers for the legends: the six best players of the hand-made clubs.
var _pool := {}

func _challengers() -> Dictionary:
	if _pool.is_empty():
		var ps := []
		for c in Roster.CLUBS:
			for p in c.players:
				var d: Dictionary = p.duplicate(true)
				People.ensure(d)
				ps.append(d)
		ps.sort_custom(func(x, y): return Roster.overall(x) > Roster.overall(y))
		_pool = {"players": ps.slice(0, 6)}
	return _pool


func _page_coach() -> void:
	var m = main
	var P: int = m.PLAYER
	var A: int = m.AI
	# status bar: what break this is, the score, a battery
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	_box.add_child(bar)
	_icon("board", bar)
	var title := "局间休息 · 第 %d 局后" % (m.games[P] + m.games[A])
	if coach_kind == "timeout":
		title = "暂停 · 我方" if coach_by == P else "暂停 · 对方叫的"
	_text("战术平板  ·  " + title, C_YELLOW, bar).add_theme_font_size_override("font_size", 16)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(sp)
	var s := "%s  %d : %d  %s" % [m.pname[P], m.games[P], m.games[A], m.pname[A]]
	if not m.game_scores.is_empty():
		s += "   (%s)" % " ".join(PackedStringArray(m.game_scores))
	if coach_kind == "timeout":
		s += "   本局 %d : %d" % [m.score[P], m.score[A]]
	_text(s, C_WHITE, bar)
	_icon("battery", bar)
	_text("76%", C_DIM, bar)
	# tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	_box.add_child(tabs)
	for t in [["tactics", "staff", "战术板"], ["data", "league", "数据"], ["scout", "eye", "对手"]]:
		var go := func():
			pad_tab = t[0]
			show_page("coach")
		var b := _button(t[2], go, tabs, pad_tab == t[0])
		b.icon = UIcons.get_icon(t[1])
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.custom_minimum_size = Vector2(130.0, 32.0)
	# the screen is a fixed size whatever the tab: what doesn't fit scrolls
	var glass := _scroll(_box, 960.0)
	glass.custom_minimum_size = Vector2(960.0, 470.0)
	glass.size_flags_vertical = Control.SIZE_FILL
	var screen := VBoxContainer.new()
	screen.add_theme_constant_override("separation", 6)
	screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glass.add_child(screen)
	var keep := _box
	_box = screen
	match pad_tab:
		"data":
			_pad_data()
		"scout":
			_pad_scout()
		_:
			_pad_tactics()
	_box = keep
	var nav := _row()
	var go_on := _button("继续比赛", func(): m.end_break(order_pick), nav, true)
	go_on.icon = UIcons.get_icon("play")
	go_on.custom_minimum_size = Vector2(160.0, 34.0)
	if pad_tab != "tactics" or _focus == null:
		_focus = go_on


## 战术板: how both are doing, what the other bench seems to want, your instruction.
func _pad_tactics() -> void:
	var m = main
	var P: int = m.PLAYER
	var A: int = m.AI
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	_box.add_child(cols)
	for sd in [P, A]:
		var c := _card(cols)
		c.custom_minimum_size = Vector2(460.0, 0.0)
		_head("person" if sd == P else "club", str(m.pname[sd]), c)
		c.add_child(Gauge.new("体力", float(m.stamina[sd]) / maxf(float(m.max_stamina[sd]), 1.0) * 100.0, C_SKY if sd == P else C_RED))
		var w: Dictionary = m.weak[sd]
		var tot: float = maxf(w.fh + w.bh, 1.0)
		c.add_child(Gauge.new("正手丢", w.fh / tot * 100.0, C_YELLOW))
		c.add_child(Gauge.new("反手丢", w.bh / tot * 100.0, C_YELLOW))
		_text("丢分：正手 %d · 反手 %d    本局主动失误 %d" % [w.fh, w.bh, m.errors[sd]], C_DIM, c)
		if m.duel.size() == 2:
			var pl: Dictionary = m.duel[0 if sd == P else 1]
			var fl := Skills.flaw_names(pl)
			if fl != "":
				_text("短板：" + fl, C_RED, c)
	var oc := _card(_box)
	_head("eye", "对方教练的布置，看起来是：%s" % Tie.ORDERS[m.orders[A]].name, oc)
	_text(Tie.ORDERS[m.orders[A]].desc, C_DIM, oc)
	var mc := _card(_box)
	_head("staff", "给 %s 的指令" % m.pname[P], mc)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	mc.add_child(grid)
	for k in Tie.ORDER_KEYS:
		var choose := func():
			order_pick = k
			show_page("coach")
		var b := _button(Tie.ORDERS[k].name, choose, grid, k == order_pick)
		b.custom_minimum_size = Vector2(150.0, 30.0)
		if k == order_pick:
			_focus = b
	_text(Tie.ORDERS[order_pick].desc, C_YELLOW, mc)
	if not m.autoplay:
		_text("你亲自上台：指令只对教练席托管的球员生效，这里当作提醒。", C_DIM, mc)


## 数据: the game's analysis, on the tablet's screen.
func _pad_data() -> void:
	# the game's analysis, shrunk to fit the tablet's screen
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(940.0, 466.0)
	_box.add_child(holder)
	var ap = AnalysisPanel.new()
	ap.main = main
	ap.embedded = true
	ap.size = Vector2(940.0, 550.0)
	ap.scale = Vector2(0.846, 0.846)
	ap.position = Vector2(73.0, 0.0)
	holder.add_child(ap)
	ap.visible = true


## 对手: the opponent against your player on one radar, what he has and lacks,
## the scouts' note, and where he is losing points today.
func _pad_scout() -> void:
	var m = main
	if m.duel.size() != 2:
		_text("没有对手资料。", C_DIM)
		return
	var me: Dictionary = m.duel[0]
	var opp: Dictionary = m.duel[1]
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	_box.add_child(cols)
	var lv := VBoxContainer.new()
	cols.add_child(lv)
	lv.add_child(RadarChart.new(opp, me.a, 300.0))
	var key := HBoxContainer.new()
	key.add_theme_constant_override("separation", 14)
	lv.add_child(key)
	_icon("sw_y", key)
	_text(opp.name, C_YELLOW, key)
	_icon("sw_s", key)
	_text(me.name, C_SKY, key)
	var info := _card(cols)
	info.custom_minimum_size = Vector2(560.0, 0.0)
	_head("eye", "%s  ·  综合 %d" % [opp.name, Roster.overall(opp)], info)
	_text("%s · %s%s" % [GRIP_NAMES.get(opp.grip, ""), Roster.STYLES[opp.style].name, " · 左手" if int(opp.get("hand", 1)) < 0 else ""], C_WHITE, info)
	_text(Skills.line(opp, "tech"), C_YELLOW, info)
	_text(Skills.line(opp, "mind"), C_YELLOW, info)
	var note := _text("球探：" + Roster.scout_note(opp), C_WHITE, info)
	note.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	note.custom_minimum_size = Vector2(540.0, 0.0)
	var w: Dictionary = m.weak[m.AI]
	_gap_in(info)
	_head("league", "今天他在哪丢分", info)
	var tot: float = maxf(w.fh + w.bh, 1.0)
	info.add_child(Gauge.new("正手", w.fh / tot * 100.0, C_YELLOW))
	info.add_child(Gauge.new("反手", w.bh / tot * 100.0, C_YELLOW))
	_text("本局主动失误 %d    体力 %d / %d" % [m.errors[m.AI], m.stamina[m.AI], m.max_stamina[m.AI]], C_DIM, info)
	var hint := "建议：压他%s" % ("反手" if w.bh > w.fh else ("正手" if w.fh > w.bh else "两边，看谁先撑不住"))
	if Skills.flaws(opp).has("weak_bh"):
		hint = "建议：压反手（他反手薄弱）"
	elif Skills.flaws(opp).has("choke"):
		hint += "，关键分稳住，他会怯场"
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 6)
	info.add_child(hr)
	_icon("arrow", hr)
	_text(hint, C_SKY, hr)


# ---------------------------------------------------------------- widgets

func _line(p: Dictionary) -> String:
	var ovr := Roster.overall(p)
	var s := "%s  %d岁  %s · %s   综合 %d %s" % [p.name, p.age, GRIP_NAMES[p.grip], Roster.STYLES[p.style].name, ovr, Roster.level_name(ovr)]
	if p.has("cond"):
		s += "   状态 %d" % int(p.cond)
		if p.injured > 0:
			s += "  受伤"
	return s


func _title(s: String) -> void:
	if PAGE_ICONS.has(page) and page != "home":
		var row := _row()
		row.add_theme_constant_override("separation", 10)
		_icon(PAGE_ICONS[page], row, 3)
		var l := _text(s, C_YELLOW, row)
		l.add_theme_font_size_override("font_size", 24)
		return
	var l := _text(s, C_YELLOW)
	l.add_theme_font_size_override("font_size", 24)


## A pixel icon (UIcons) as a node, `scale` x its 12 px.
func _icon(name: String, parent: Control, scale := 2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = UIcons.get_icon(name, scale)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


## A vertical scroller in `parent` that takes the height left over (and at
## least `min_w` wide), so a long column scrolls instead of pushing the page
## off the screen.
func _scroll(parent: Control, min_w: float) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(min_w, 0.0)
	# a flat, square scrollbar to match the pixel look
	var bar := sc.get_v_scroll_bar()
	bar.add_theme_stylebox_override("scroll", _box_style(C_INK, C_BAR))
	bar.add_theme_stylebox_override("grabber", _box_style(C_BAR, C_BAR))
	bar.add_theme_stylebox_override("grabber_highlight", _box_style(C_DIM, C_DIM))
	bar.add_theme_stylebox_override("grabber_pressed", _box_style(C_YELLOW, C_YELLOW))
	bar.custom_minimum_size = Vector2(8.0, 0.0)
	parent.add_child(sc)
	return sc


## A section heading: icon, label, and a rule underneath.
func _head(icon: String, s: String, parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	_icon(icon, row)
	var l := _text(s, C_YELLOW, row)
	l.add_theme_font_size_override("font_size", 16)
	return row


## A card: a panel with a lighter fill for a block of the page.
func _card(parent: Control) -> VBoxContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_NAVY, 0.55)
	sb.border_color = C_BAR
	sb.set_border_width_all(1)
	sb.border_width_top = 3
	sb.set_content_margin_all(10.0)
	pc.add_theme_stylebox_override("panel", sb)
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	return v


func _text(s: String, col := C_WHITE, parent: Control = null) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", 12)
	(parent if parent != null else _box).add_child(l)
	return l


func _gap() -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0.0, 6.0)
	_box.add_child(c)


func _row() -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 8)
	_box.add_child(r)
	return r


func _button(s: String, cb: Callable, parent: Control = null, selected := false) -> Button:
	var b := Button.new()
	b.text = s
	b.add_theme_font_size_override("font_size", 12)
	b.custom_minimum_size = Vector2(0.0, 28.0)
	b.add_theme_stylebox_override("normal", _box_style(C_RED if selected else C_NAVY, C_DIM))
	b.add_theme_stylebox_override("hover", _box_style(C_RED if selected else C_BAR, C_YELLOW))
	b.add_theme_stylebox_override("pressed", _box_style(C_RED, C_WHITE))
	b.add_theme_stylebox_override("focus", _box_style(Color(0, 0, 0, 0), C_YELLOW, false))
	b.add_theme_stylebox_override("disabled", _box_style(C_INK, C_BAR))
	b.add_theme_color_override("font_color", C_WHITE)
	b.add_theme_color_override("font_hover_color", C_YELLOW)
	b.add_theme_color_override("font_focus_color", C_YELLOW)
	b.add_theme_color_override("font_disabled_color", C_BAR)
	b.pressed.connect(func(): main.sfx.fx("click", -10.0))
	b.pressed.connect(cb)
	(parent if parent != null else _box).add_child(b)
	return b


func _box_style(bg: Color, border: Color, fill := true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.draw_center = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	return sb


# ---------------------------------------------------------------- brackets

## Fills the rounds still to come with empty boxes: each holds half the matches
## of the round before it.
static func _pad_rounds(rounds: Array, total: int) -> void:
	while rounds.size() < total:
		var n: int = maxi(rounds[-1].size() / 2, 1) if not rounds.is_empty() else 1
		var col := []
		for i in n:
			col.append({"a": "?", "b": "?", "w": -1, "mine": -1})
		rounds.append(col)


func _bracket_cuprun(cr) -> Dictionary:
	var nm := func(i: int) -> String:
		var e: Dictionary = cr.entrants[i]
		return e.name if cr.kind == "solo" else str(e.get("short", e.name))
	var rounds := []
	for rd in cr.hist:
		var col := []
		for m in rd:
			col.append({"a": nm.call(m.a), "b": nm.call(m.b), "score": m.score, "w": 0 if m.w == m.a else 1,
					"mine": 0 if m.a == cr.mine else (1 if m.b == cr.mine else -1)})
		rounds.append(col)
	if not cr.is_over():
		var col := []
		for t in cr.ties:
			col.append({"a": nm.call(t[0]), "b": nm.call(t[1]), "w": -1, "mine": 0 if t[0] == cr.mine else (1 if t[1] == cr.mine else -1)})
		rounds.append(col)
	var total := int(round(log(float(cr.entrants.size())) / log(2.0)))
	_pad_rounds(rounds, total)
	var titles := []
	for k in total:
		titles.append(cr.STAGE_NAMES.get(int(pow(2, total - k)), "决赛"))
	return {"titles": titles, "rounds": rounds, "tree": true, "champ": nm.call(cr.champion) if cr.is_over() else ""}

