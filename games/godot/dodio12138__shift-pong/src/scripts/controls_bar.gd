extends Control
## Bottom controls legend. The six stroke keys are drawn as a little keyboard
## (Q W E / A S D) with the spin each one puts on the ball printed on the key;
## keys and mouse buttons light up while held. Compact by default (strokes,
## serve, skills); the full HUD (Tab) shows every key.

const Icons := preload("res://scripts/icons.gd")
const C_INK := Color(0.040, 0.050, 0.100)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_DIM := Color(0.720, 0.780, 0.860)
const C_LIT := Color(0.980, 0.800, 0.250)
const ROW_H := 48.0
const CAP := Vector2(66.0, 42.0)
const SCALE := 0.5    # whole legend is drawn at this size (24px text -> 12px pixel font); Tab hides it

# letter, keycode, main spin icon, side spin icon
var full := false     # every key, not just the few you need to play

const CLUSTER := [
	[["Q", KEY_Q, "top", "side_l"], ["W", KEY_W, "top", ""], ["E", KEY_E, "top", "side_r"]],
	[["A", KEY_A, "back", "side_l"], ["S", KEY_S, "back", ""], ["D", KEY_D, "back", "side_r"]],
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Redrawn only when a key or button goes down or up (or the language changes).
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED or what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(C_INK, 0.82))
	draw_rect(Rect2(Vector2.ZERO, size), C_DIM, false, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(SCALE, SCALE))
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var rmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	for r in 2:
		for c in 3:
			var k: Array = CLUSTER[r][c]
			var lit: bool = Input.is_key_pressed(k[1]) or (c == 1 and ((r == 0 and lmb) or (r == 1 and rmb)))
			spin_cap(Vector2(10.0 + c * (CAP.x + 6.0) + r * 14.0, 6.0 + r * ROW_H), k[0], k[2], k[3], lit)

	var any := lmb or rmb
	for row in CLUSTER:
		for k in row:
			any = any or Input.is_key_pressed(k[1])

	var x := 250.0
	var y := 6.0
	if not full:   # the keys speak for themselves (spin drawn on them): serve and skills only
		x = text(x, y, "发球: 按住选旋转, 松开发出", C_WHITE)
		x = key(x, y, "空格", KEY_SPACE)
		y += ROW_H
		x = 250.0
		for item in [["Shift", KEY_SHIFT, "技能轮盘"], ["T", KEY_T, "专注卡"], ["Tab", KEY_TAB, "详细信息"]]:
			x = key(x, y, item[0], item[1])
			x = text(x, y, item[2], C_DIM) + 4.0
		return
	# row 1: what the rows / columns mean, mouse
	x = text(x, y, "上排 拉/扣", Icons.C_ORANGE)
	x = text(x, y, "下排 搓", Icons.C_SKY)
	x = text(x, y, "左列 左侧旋", Icons.C_YELLOW)
	x = text(x, y, "右列 右侧旋", Icons.C_VIOLET)
	x = text(x, y, "不按 挡", C_LIT if not any else C_WHITE) + 10.0
	x = text(x, y, "按住时长 = 力度", C_DIM) + 10.0
	x = icon(x, y, Icons.mouse("move"))
	x = text(x, y, "站位", C_WHITE) + 6.0
	x = icon(x, y, Icons.mouse("left", lmb))
	x = text(x, y, "= W", C_DIM)
	x = icon(x, y, Icons.mouse("right", rmb))
	x = text(x, y, "= S", C_DIM)

	# row 2: serving and settings
	x = 250.0
	y += ROW_H
	x = text(x, y, "发球: 按住选旋转, 松开发出", C_WHITE)
	x = key(x, y, "空格", KEY_SPACE)
	x = icon(x, y, Icons.spin("none")) + 18.0
	for item in [["L", KEY_L, "难度"], ["G", KEY_G, "握拍"], ["T", KEY_T, "专注卡"], ["B", KEY_B, "回放"], ["C/V", KEY_C, "视角"], ["Tab", KEY_TAB, "简洁"], 
			["F", KEY_F, "观战"], ["R", KEY_R, "重开"], ["Y", KEY_Y, "暂停"], ["M", KEY_M, "菜单"], ["Shift", KEY_SHIFT, "技能轮盘 / 假动作发球"], ["1-4", KEY_1, "技能"], ["I", KEY_I, "数据"]]:
		x = key(x, y, item[0], item[1])
		x = text(x, y, item[2], C_DIM) + 4.0


## Stroke keycap: letter in the corner, the spin it plays drawn on the key.
func spin_cap(at: Vector2, letter: String, main: String, side: String, lit: bool) -> void:
	var font := get_theme_font("font", "Label")
	var press := Vector2(0.0, 3.0) if lit else Vector2.ZERO
	draw_rect(Rect2(at + Vector2(0.0, 4.0), CAP), Color(0.02, 0.03, 0.08))     # key side
	var face := Rect2(at + press, CAP)
	draw_rect(face, C_LIT if lit else Color(0.15, 0.19, 0.32))
	draw_rect(face, C_WHITE if not lit else C_INK, false, 2.0)
	draw_string(font, face.position + Vector2(4.0, 20.0), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, C_INK if lit else C_WHITE)
	var m := Icons.spin(main)
	draw_texture_rect(m, Rect2(face.position + Vector2(16.0, 6.0), m.get_size() * 1.5), false)
	if side != "":
		var s := Icons.spin(side)
		draw_texture_rect(s, Rect2(face.position + Vector2(44.0, 20.0), s.get_size()), false)


func icon(x: float, y: float, tex: Texture2D) -> float:
	var s := tex.get_size() * 2.0
	draw_texture_rect(tex, Rect2(Vector2(x, y + (ROW_H - 4.0 - s.y) * 0.5), s), false)
	return x + s.x + 4.0


func text(x: float, y: float, t: String, col: Color) -> float:
	var font := get_theme_font("font", "Label")
	draw_string(font, Vector2(x, y + 32.0), tr(t), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col)
	return x + font.get_string_size(tr(t), HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 12.0


## Small keycap; lights up while the key is held.
func key(x: float, y: float, label: String, keycode: int) -> float:
	var font := get_theme_font("font", "Label")
	var lit := Input.is_key_pressed(keycode)
	var w := maxf(font.get_string_size(tr(label), HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 14.0, 32.0)
	var r := Rect2(Vector2(x, y + 7.0), Vector2(w, 32.0))
	draw_rect(Rect2(r.position + Vector2(0.0, 3.0), r.size), Color(0.02, 0.03, 0.08))
	draw_rect(Rect2(r.position + (Vector2(0.0, 2.0) if lit else Vector2.ZERO), r.size), C_LIT if lit else C_WHITE)
	draw_string(font, r.position + Vector2(0.0, 25.0 + (2.0 if lit else 0.0)), tr(label), HORIZONTAL_ALIGNMENT_CENTER, w, 24, C_INK)
	return x + w + 6.0
