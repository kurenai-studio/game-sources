extends Control
## Ball Sort Warna — kontroler game.
## Tap tabung untuk pilih, tap tabung lain untuk tuang.
## Tuang memindahkan seluruh rangkaian bola warna sama di atas
## (sebatas ruang kosong di tabung tujuan). Menang kalau tiap tabung
## yang terisi penuh dengan satu warna.
## Fase 1: 30 level (semua terverifikasi solver BFS), level select,
## save progres (ConfigFile user://), hint (solver BFS di runtime),
## deteksi deadlock (tidak ada langkah valid).

# Level: tiap tabung = Array warna (indeks 0 = paling bawah).
# Warna: 0 merah, 1 hijau, 2 biru, 3 kuning, 4 ungu.
# L1-3 buatan tangan; L4-30 digenerate acak (seed tetap) dan
# diverifikasi solvable pakai solver BFS dengan aturan tuang yang sama.
const LEVELS: Array = [
	[[0, 1, 0, 2], [1, 2, 1, 0], [2, 0, 2, 1], [], []],
	[[0, 1, 2, 3], [1, 2, 3, 0], [2, 3, 0, 1], [3, 0, 1, 2], [], []],
	[[0, 1, 2, 3], [1, 2, 3, 4], [2, 3, 4, 0], [3, 4, 0, 1], [4, 0, 1, 2], [], []],
	[[0, 1, 2, 0], [1, 2, 2, 0], [1, 2, 1, 0], [], []],
	[[0, 2, 1, 1], [0, 2, 1, 0], [2, 2, 0, 1], [], []],
	[[2, 0, 2, 1], [2, 1, 2, 1], [0, 0, 0, 1], [], []],
	[[2, 0, 1, 0], [1, 0, 1, 2], [1, 2, 0, 2], [], []],
	[[2, 0, 1, 0], [1, 1, 0, 2], [2, 2, 0, 1], [], []],
	[[1, 0, 2, 0], [0, 1, 0, 2], [1, 2, 2, 1], [], []],
	[[0, 2, 0, 1], [0, 2, 1, 1], [2, 1, 2, 0], [], []],
	[[2, 3, 1, 0], [1, 3, 2, 1], [2, 0, 0, 0], [1, 3, 2, 3], [], []],
	[[3, 1, 1, 0], [0, 2, 0, 3], [2, 1, 1, 2], [3, 3, 0, 2], [], []],
	[[0, 3, 1, 2], [2, 0, 3, 1], [1, 0, 2, 0], [1, 3, 3, 2], [], []],
	[[1, 3, 3, 0], [1, 3, 2, 1], [2, 2, 0, 0], [2, 0, 3, 1], [], []],
	[[3, 2, 2, 0], [3, 1, 0, 1], [3, 0, 3, 0], [1, 2, 2, 1], [], []],
	[[2, 1, 3, 0], [3, 2, 1, 3], [3, 0, 1, 2], [1, 0, 2, 0], [], []],
	[[1, 0, 0, 1], [2, 0, 1, 2], [1, 3, 3, 0], [2, 2, 3, 3], [], []],
	[[3, 3, 2, 0], [1, 1, 2, 2], [0, 1, 1, 3], [2, 0, 3, 0], [], []],
	[[1, 2, 2, 3], [1, 2, 0, 3], [1, 0, 1, 3], [3, 2, 0, 0], [], []],
	[[2, 0, 3, 3], [1, 0, 1, 0], [2, 3, 3, 2], [0, 1, 2, 1], [], []],
	[[1, 1, 2, 4], [3, 3, 0, 4], [4, 3, 0, 3], [0, 1, 0, 1], [4, 2, 2, 2], [], []],
	[[1, 3, 2, 0], [3, 4, 0, 4], [3, 1, 1, 4], [2, 0, 2, 1], [0, 3, 2, 4], [], []],
	[[3, 2, 0, 1], [0, 4, 1, 2], [2, 1, 4, 0], [0, 3, 4, 3], [2, 1, 4, 3], [], []],
	[[0, 2, 1, 0], [4, 4, 1, 2], [4, 3, 1, 3], [3, 1, 0, 2], [0, 2, 4, 3], [], []],
	[[1, 4, 0, 3], [4, 4, 2, 3], [1, 4, 0, 0], [1, 2, 2, 3], [1, 0, 2, 3], [], []],
	[[1, 2, 1, 3], [2, 4, 2, 3], [0, 1, 4, 3], [0, 4, 0, 1], [0, 2, 3, 4], [], []],
	[[0, 2, 4, 4], [1, 2, 1, 4], [1, 2, 3, 3], [1, 0, 0, 3], [4, 0, 3, 2], [], []],
	[[0, 1, 1, 0], [1, 2, 2, 3], [3, 4, 3, 2], [4, 0, 3, 2], [1, 0, 4, 4], [], []],
	[[4, 0, 0, 2], [3, 3, 2, 4], [0, 3, 4, 2], [1, 2, 4, 1], [3, 1, 0, 1], [], []],
	[[1, 0, 2, 1], [0, 2, 0, 4], [4, 4, 0, 3], [4, 2, 3, 1], [3, 2, 3, 1], [], []],
]
const MIN_MOVES: Array[int] = [10, 13, 16, 10, 8, 8, 11, 8, 9, 9, 12, 11, 13, 11, 13, 13, 10, 10, 12, 11, 12, 16, 17, 16, 15, 17, 14, 14, 15, 16]
const MAX_EXTRA_TUBES: int = 2
const SAVE_PATH := "user://ball_sort_save.cfg"
const HINT_STATE_CAP := 80000

var current_level: int = 0
var tubes: Array = []
var selected_index: int = -1
var moves: int = 0
var undo_stack: Array = []
var extra_tubes_left: int = MAX_EXTRA_TUBES
var deadlocked: bool = false
var animating: bool = false
# Progres tersimpan
var unlocked: int = 1
var saved_stars: Array[int] = []
var saved_best: Array[int] = []
var level_buttons: Array = []

@onready var tubes_container: Control = $TubesContainer
@onready var pour_fx: PourFx = $PourFx
@onready var sound: SoundSynth = $SoundSynth
@onready var level_label: Label = $LevelPill/LevelLabel
@onready var moves_label: Label = $MovesPill/MovesLabel
@onready var message_label: Label = $MessageLabel
@onready var level_button: Button = $LevelButton
@onready var undo_button: Button = $UndoButton
@onready var add_tube_button: Button = $AddTubeButton
@onready var hint_button: Button = $HintButton
@onready var restart_button: Button = $RestartButton
@onready var win_panel: PanelContainer = $WinPanel
@onready var stars_label: Label = $WinPanel/VBox/StarsLabel
@onready var win_label: Label = $WinPanel/VBox/WinLabel
@onready var win_info_label: Label = $WinPanel/VBox/WinInfoLabel
@onready var next_button: Button = $WinPanel/VBox/NextButton
@onready var select_level_button: Button = $WinPanel/VBox/SelectLevelButton
@onready var level_select_panel: PanelContainer = $LevelSelectPanel
@onready var select_summary: Label = $LevelSelectPanel/SelectVBox/SelectSummary
@onready var select_grid: GridContainer = $LevelSelectPanel/SelectVBox/SelectGrid
@onready var sound_button: Button = $LevelSelectPanel/SelectVBox/SoundButton


func _ready() -> void:
	undo_button.pressed.connect(_on_undo_pressed)
	add_tube_button.pressed.connect(_on_add_tube_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	next_button.pressed.connect(_on_next_pressed)
	select_level_button.pressed.connect(_show_level_select)
	level_button.pressed.connect(_show_level_select)
	sound_button.pressed.connect(_on_sound_toggled)
	_load_progress()
	_show_level_select()


# ------------------------------------------------------------------ progres
func _load_progress() -> void:
	saved_stars.resize(LEVELS.size())
	saved_stars.fill(0)
	saved_best.resize(LEVELS.size())
	saved_best.fill(0)
	unlocked = 1
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		_update_sound_button()
		return
	unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, LEVELS.size())
	var s: Array = cfg.get_value("progress", "stars", [])
	for i in range(mini(s.size(), LEVELS.size())):
		saved_stars[i] = clampi(int(s[i]), 0, 3)
	var b: Array = cfg.get_value("progress", "best", [])
	for i in range(mini(b.size(), LEVELS.size())):
		saved_best[i] = maxi(0, int(b[i]))
	sound.muted = bool(cfg.get_value("settings", "muted", false))
	_update_sound_button()


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "stars", saved_stars)
	cfg.set_value("progress", "best", saved_best)
	cfg.set_value("settings", "muted", sound.muted)
	cfg.save(SAVE_PATH)


func _update_sound_button() -> void:
	sound_button.text = "Suara: Mati" if sound.muted else "Suara: Nyala"


func _on_sound_toggled() -> void:
	sound.muted = not sound.muted
	_update_sound_button()
	_save_progress()
	sound.play("click")


func _total_stars() -> int:
	var total := 0
	for v in saved_stars:
		total += v
	return total


# -------------------------------------------------------------- level select
func _stars_text(n: int) -> String:
	return "★".repeat(n) + "☆".repeat(3 - n)


func _level_button_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(16)
	return s


func _build_level_select() -> void:
	for child in select_grid.get_children():
		child.queue_free()
	level_buttons.clear()
	var open_style := _level_button_style(Color(0.2, 0.23, 0.33, 1))
	var open_hover := _level_button_style(Color(0.27, 0.3, 0.42, 1))
	var open_pressed := _level_button_style(Color(0.15, 0.17, 0.25, 1))
	var locked_style := _level_button_style(Color(0.12, 0.13, 0.2, 1))
	for i in range(LEVELS.size()):
		var b := Button.new()
		b.custom_minimum_size = Vector2(120, 86)
		b.add_theme_font_size_override("font_size", 22)
		var is_open := i < unlocked
		b.text = "%d\n%s" % [i + 1, _stars_text(saved_stars[i]) if is_open else "☆☆☆"]
		b.disabled = not is_open
		if is_open:
			b.add_theme_stylebox_override("normal", open_style)
			b.add_theme_stylebox_override("hover", open_hover)
			b.add_theme_stylebox_override("pressed", open_pressed)
			b.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			b.add_theme_stylebox_override("normal", locked_style)
			b.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
			b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
		b.pressed.connect(_on_level_button_pressed.bind(i))
		select_grid.add_child(b)
		level_buttons.append(b)
	select_summary.text = "Level terbuka: %d/%d  •  Bintang: %d/%d" % [
		unlocked, LEVELS.size(), _total_stars(), LEVELS.size() * 3]


func _show_level_select() -> void:
	_deselect()
	win_panel.visible = false
	_build_level_select()
	level_select_panel.visible = true


func _on_level_button_pressed(index: int) -> void:
	sound.play("click")
	level_select_panel.visible = false
	load_level(index)


# ------------------------------------------------------------------- gameplay
func load_level(index: int) -> void:
	current_level = index
	undo_stack.clear()
	selected_index = -1
	moves = 0
	extra_tubes_left = MAX_EXTRA_TUBES
	deadlocked = false
	animating = false
	pour_fx.cancel()
	win_panel.visible = false
	message_label.text = ""
	var def: Array = []
	for t in LEVELS[current_level]:
		def.append((t as Array).duplicate())
	_build_tubes(def)
	_update_labels()
	_check_deadlock()


func _build_tubes(state: Array) -> void:
	for child in tubes_container.get_children():
		child.queue_free()
	tubes.clear()
	selected_index = -1
	var count := state.size()
	var avail := size.x - 32.0
	var gap := 12.0
	var tube_w := minf(96.0, (avail - float(count - 1) * gap) / float(count))
	var total := float(count) * tube_w + float(count - 1) * gap
	var start_x := (size.x - total) * 0.5
	for i in range(count):
		var tube := Tube.new()
		tube.position = Vector2(start_x + float(i) * (tube_w + gap), 20)
		tube.size = Vector2(tube_w, 360)
		tube.set_balls(state[i])
		tube.tapped.connect(_on_tube_tapped)
		tubes_container.add_child(tube)
		tubes.append(tube)


func _current_balls() -> Array:
	var out: Array = []
	for t in tubes:
		out.append(t.balls.duplicate())
	return out


func _on_tube_tapped(tube) -> void:
	if win_panel.visible or level_select_panel.visible or animating:
		return
	var index := tubes.find(tube)
	if index == -1:
		return
	if selected_index == -1:
		if tube.is_empty():
			return
		selected_index = index
		tube.set_selected(true)
		sound.play("select")
		return
	if index == selected_index:
		tube.set_selected(false)
		selected_index = -1
		return
	_try_pour(selected_index, index)


func _tube_mouth(index: int) -> Vector2:
	var t = tubes[index]
	return tubes_container.position + t.position + Vector2(t.size.x * 0.5, 20.0)


func _try_pour(from_index: int, to_index: int) -> void:
	var src = tubes[from_index]
	var dst = tubes[to_index]
	var from_color: int = src.top_color()
	if dst.is_full():
		_show_message("Tabung tujuan sudah penuh!")
		sound.play("invalid")
		Input.vibrate_handheld(40)
		_shake(src)
		_deselect()
		return
	if not dst.is_empty() and dst.top_color() != from_color:
		_show_message("Warna atas tidak cocok!")
		sound.play("invalid")
		Input.vibrate_handheld(40)
		_shake(src)
		_deselect()
		return
	undo_stack.append(_snapshot())
	var space: int = Tube.CAPACITY - dst.balls.size()
	var n: int = mini(src.top_run(), space)
	var moving: Array[int] = []
	for k in range(n):
		moving.append(from_color)
	# Animasi dulu, commit belakangan: bola sumber disembunyikan
	# selama diterbangkan PourFx, input diblokir sampai selesai.
	_deselect()
	var from_mouth := _tube_mouth(from_index)
	var to_mouth := _tube_mouth(to_index)
	var ball_r: float = src.size.x * 0.5 - 8.0
	animating = true
	src.set_hidden_top(n)
	pour_fx.start_pour(from_mouth, to_mouth, moving, ball_r)
	await pour_fx.finished
	for k in range(n):
		src.balls.pop_back()
	for v in moving:
		dst.balls.append(v)
	src.set_hidden_top(0)
	moves += 1
	animating = false
	src.queue_redraw()
	dst.queue_redraw()
	_pop(dst)
	sound.play("pour")
	if dst.is_complete():
		sound.play("complete")
	Input.vibrate_handheld(60)
	_update_labels()
	if _check_win():
		_show_win()
	else:
		_check_deadlock()


func _snapshot() -> Dictionary:
	return {"balls": _current_balls(), "moves": moves, "extra": extra_tubes_left}


func _restore(snapshot: Dictionary) -> void:
	extra_tubes_left = int(snapshot["extra"])
	moves = int(snapshot["moves"])
	_build_tubes(snapshot["balls"])
	_update_labels()
	_check_deadlock()


func _on_undo_pressed() -> void:
	if animating:
		return
	if undo_stack.is_empty():
		_show_message("Tidak ada langkah untuk diurungkan.")
		return
	_deselect()
	_restore(undo_stack.pop_back())
	sound.play("click")
	_show_message("Langkah diurungkan.")


func _on_add_tube_pressed() -> void:
	if animating:
		return
	if extra_tubes_left <= 0:
		_show_message("Tabung tambahan sudah habis!")
		return
	undo_stack.append(_snapshot())
	extra_tubes_left -= 1
	var state := _current_balls()
	state.append([])
	_build_tubes(state)
	_update_labels()
	_check_deadlock()
	sound.play("click")
	_show_message("Tabung kosong ditambah!")


func _on_restart_pressed() -> void:
	if animating:
		return
	load_level(current_level)
	sound.play("click")
	_show_message("Level diulang dari awal.")


func _on_next_pressed() -> void:
	sound.play("click")
	if current_level + 1 >= LEVELS.size():
		load_level(0)
	else:
		load_level(current_level + 1)


func _deselect() -> void:
	if selected_index >= 0 and selected_index < tubes.size():
		tubes[selected_index].set_selected(false)
	selected_index = -1


func _check_win() -> bool:
	for t in tubes:
		if t.is_empty():
			continue
		if not t.is_complete():
			return false
	return true


func _show_win() -> void:
	var best: int = MIN_MOVES[current_level]
	var stars := 3 if moves <= best else (2 if moves <= best + 5 else 1)
	saved_stars[current_level] = maxi(saved_stars[current_level], stars)
	if saved_best[current_level] == 0 or moves < saved_best[current_level]:
		saved_best[current_level] = moves
	if current_level + 1 < LEVELS.size():
		unlocked = maxi(unlocked, current_level + 2)
	_save_progress()
	stars_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	sound.play("win")
	Input.vibrate_handheld(120)
	if current_level + 1 >= LEVELS.size():
		win_label.text = "Semua Level Selesai!"
		win_info_label.text = "Langkah: %d • Minimal: %d" % [moves, best]
		next_button.text = "Main Lagi dari Level 1"
	else:
		win_label.text = "Level Selesai!"
		win_info_label.text = "Langkah: %d • Minimal: %d" % [moves, best]
		next_button.text = "Level Berikutnya"
	win_panel.visible = true


# ----------------------------------------------------------------------- hint
func _state_key(balls_state: Array) -> String:
	var parts: PackedStringArray = []
	for t in balls_state:
		var s := ""
		for v in t:
			s += str(v)
		parts.append(s)
	return ",".join(parts)


func _valid_pours(balls_state: Array) -> Array:
	var out: Array = []
	for i in range(balls_state.size()):
		var src: Array = balls_state[i]
		if src.is_empty():
			continue
		var top: int = src[src.size() - 1]
		var run := 0
		for k in range(src.size() - 1, -1, -1):
			if src[k] == top:
				run += 1
			else:
				break
		for j in range(balls_state.size()):
			if i == j:
				continue
			var dst: Array = balls_state[j]
			if dst.size() >= Tube.CAPACITY:
				continue
			if not dst.is_empty() and dst[dst.size() - 1] != top:
				continue
			out.append([i, j, mini(run, Tube.CAPACITY - dst.size())])
	return out


func _apply_pour(balls_state: Array, pour: Array) -> Array:
	var out: Array = []
	for t in balls_state:
		out.append((t as Array).duplicate())
	var src: Array = out[pour[0]]
	var dst: Array = out[pour[1]]
	var top: int = src[src.size() - 1]
	for k in range(pour[2]):
		src.pop_back()
	for k in range(pour[2]):
		dst.append(top)
	return out


func _is_win_state(balls_state: Array) -> bool:
	for t in balls_state:
		if t.is_empty():
			continue
		if t.size() != Tube.CAPACITY:
			return false
		for v in t:
			if v != t[0]:
				return false
	return true


func _solve_first_move(balls_state: Array) -> Array:
	## BFS dari state sekarang; kembalikan [from, to] langkah pertama
	## dari solusi optimal, atau [] kalau tidak ada / batas state tercapai.
	var start_key := _state_key(balls_state)
	if _is_win_state(balls_state):
		return []
	var queue: Array = [balls_state]
	var head := 0
	var parent: Dictionary = {start_key: null}
	var parent_move: Dictionary = {}
	var visited := 1
	while head < queue.size():
		var s: Array = queue[head]
		head += 1
		for pour in _valid_pours(s):
			var ns := _apply_pour(s, pour)
			var ns_key := _state_key(ns)
			if parent.has(ns_key):
				continue
			parent[ns_key] = _state_key(s)
			parent_move[ns_key] = [pour[0], pour[1]]
			visited += 1
			if visited > HINT_STATE_CAP:
				return []
			if _is_win_state(ns):
				var k := ns_key
				var first: Array = parent_move[k]
				while parent[k] != start_key:
					k = parent[k]
					first = parent_move[k]
				return first
			queue.append(ns)
	return []


func _on_hint_pressed() -> void:
	if win_panel.visible or level_select_panel.visible or animating:
		return
	sound.play("click")
	_show_message("Mencari petunjuk…")
	var move := _solve_first_move(_current_balls())
	if move.is_empty():
		var pours := _valid_pours(_current_balls())
		if pours.is_empty():
			message_label.text = "Buntu! Tidak ada langkah valid — urungkan atau ulangi level."
			deadlocked = true
		else:
			_suggest_move(pours[0][0], pours[0][1], true)
		return
	_suggest_move(move[0], move[1], false)


func _suggest_move(from_i: int, to_i: int, approx: bool) -> void:
	_deselect()
	selected_index = from_i
	tubes[from_i].set_selected(true)
	var label := "Petunjuk: tuang tabung %d ke tabung %d" % [from_i + 1, to_i + 1]
	if approx:
		label += " (langkah valid)"
	_show_message(label)


# ------------------------------------------------------------------- deadlock
func _check_deadlock() -> void:
	if _check_win():
		return
	if _valid_pours(_current_balls()).is_empty():
		deadlocked = true
		message_label.text = "Buntu! Tidak ada langkah valid — urungkan atau ulangi level."
	elif deadlocked:
		deadlocked = false
		message_label.text = ""


# --------------------------------------------------------------------- polish
func _pop(tube: Tube) -> void:
	tube.pivot_offset = tube.size * 0.5
	var tw := tube.create_tween()
	tw.tween_property(tube, "scale", Vector2(1.07, 1.07), 0.09)
	tw.tween_property(tube, "scale", Vector2.ONE, 0.12)


func _shake(tube: Tube) -> void:
	var tw := tube.create_tween()
	tw.tween_property(tube, "position:x", tube.base_x + 8.0, 0.05)
	tw.tween_property(tube, "position:x", tube.base_x - 8.0, 0.05)
	tw.tween_property(tube, "position:x", tube.base_x, 0.05)


func _update_labels() -> void:
	level_label.text = "LEVEL %d" % (current_level + 1)
	moves_label.text = "Langkah %d" % moves
	undo_button.text = "↩ Urung (%d)" % undo_stack.size() if not undo_stack.is_empty() else "↩ Urung"
	add_tube_button.text = "＋ Tabung (%d)" % extra_tubes_left
	add_tube_button.disabled = extra_tubes_left <= 0


func _show_message(text: String) -> void:
	message_label.text = text
	await get_tree().create_timer(1.5).timeout
	if message_label.text == text:
		message_label.text = ""
