extends Node2D

## Breakout Clone: bounce the ball off your paddle to smash every brick.
## Move with Left/Right or the mouse, launch with Space/Enter/click.
## Everything (bricks, paddle, ball, UI) is built and drawn in code.

const W := 1152.0
const H := 648.0
const HUD_H := 44.0

const PADDLE_W := 120.0
const PADDLE_H := 16.0
const PADDLE_Y := H - 48.0
const PADDLE_SPEED := 820.0

const BALL_R := 8.0
const BALL_START_SPEED := 380.0
const BALL_MAX_SPEED := 760.0
const BALL_SPEEDUP := 5.0 # added to speed on every brick hit
const MAX_BOUNCE_ANGLE := PI / 3.0 # 60 degrees from vertical at the paddle edge
const SUBSTEP := 4.0 # max pixels the ball moves per collision check

const COLS := 12
const ROWS := 6
const BRICK_W := 84.0
const BRICK_H := 24.0
const BRICK_GAP := 6.0
const BRICK_TOP := 84.0
const ROW_COLORS: Array[Color] = [
	Color(0.93, 0.27, 0.33), # red
	Color(0.97, 0.52, 0.24), # orange
	Color(0.98, 0.80, 0.26), # yellow
	Color(0.40, 0.84, 0.42), # green
	Color(0.27, 0.66, 0.96), # blue
	Color(0.62, 0.44, 0.95), # purple
]
const ROW_POINTS: Array[int] = [70, 50, 40, 30, 20, 10]

const START_LIVES := 3

enum State { TITLE, SERVE, PLAYING, WON, GAME_OVER }

## Debug/testing aid: when true the paddle follows the ball on its own.
var autopilot := false
var autopilot_aim := 0.0

var state := State.TITLE
var paddle_x := W / 2.0
var ball_pos := Vector2.ZERO
var ball_vel := Vector2.ZERO
var ball_speed := BALL_START_SPEED
var bricks: Array[Dictionary] = [] # {rect: Rect2, color: Color, points: int, hits: int}
var particles: Array[Dictionary] = [] # {pos, vel, color, life}
var score := 0
var best := 0
var lives := START_LIVES
var use_mouse := false
var shake := 0.0

var score_label: Label
var lives_label: Label
var info_label: Label


func _ready() -> void:
	_build_ui()
	_build_bricks()
	_reset_ball()
	_show_info("BREAKOUT\n\nLeft / Right or mouse to move\nSpace, Enter or click to launch")
	_update_hud()


# --- Setup --------------------------------------------------------------------

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	score_label = _make_label(26, HORIZONTAL_ALIGNMENT_LEFT)
	score_label.position = Vector2(20, 6)
	ui.add_child(score_label)

	lives_label = _make_label(26, HORIZONTAL_ALIGNMENT_RIGHT)
	lives_label.position = Vector2(W - 320, 6)
	lives_label.size = Vector2(300, 32)
	ui.add_child(lives_label)

	info_label = _make_label(34, HORIZONTAL_ALIGNMENT_CENTER)
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.position = Vector2(0, BRICK_TOP + ROWS * (BRICK_H + BRICK_GAP) + 20)
	info_label.size = Vector2(W, PADDLE_Y - info_label.position.y - 40)
	ui.add_child(info_label)


func _make_label(font_size: int, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.horizontal_alignment = align
	return l


func _build_bricks() -> void:
	bricks.clear()
	var total_w := COLS * BRICK_W + (COLS - 1) * BRICK_GAP
	var left := (W - total_w) / 2.0
	for row in ROWS:
		for col in COLS:
			var pos := Vector2(left + col * (BRICK_W + BRICK_GAP), BRICK_TOP + row * (BRICK_H + BRICK_GAP))
			bricks.append({
				"rect": Rect2(pos, Vector2(BRICK_W, BRICK_H)),
				"color": ROW_COLORS[row],
				"points": ROW_POINTS[row],
				"hits": 2 if row == 0 else 1, # the top row is armoured
			})


# --- Game flow ----------------------------------------------------------------

func _new_game() -> void:
	score = 0
	lives = START_LIVES
	ball_speed = BALL_START_SPEED
	particles.clear()
	_build_bricks()
	_serve()


func _serve() -> void:
	state = State.SERVE
	_reset_ball()
	_show_info("Space, Enter or click to launch")
	_update_hud()


func _reset_ball() -> void:
	ball_vel = Vector2.ZERO
	ball_pos = Vector2(paddle_x, PADDLE_Y - BALL_R - 1.0)


func _launch() -> void:
	state = State.PLAYING
	var angle := randf_range(-0.35, 0.35)
	ball_vel = Vector2(sin(angle), -cos(angle)) * ball_speed
	_show_info("")


func _lose_life() -> void:
	lives -= 1
	shake = 12.0
	if lives <= 0:
		state = State.GAME_OVER
		best = max(best, score)
		_show_info("GAME OVER\n\nScore: %d\nSpace, Enter or click to try again" % score)
	else:
		# Ease off a little after losing a ball.
		ball_speed = max(BALL_START_SPEED, ball_speed - 60.0)
		_serve()
	_update_hud()


func _win() -> void:
	state = State.WON
	score += lives * 100 # bonus for spare lives
	best = max(best, score)
	ball_vel = Vector2.ZERO
	_show_info("YOU WIN!\n\nScore: %d  (+%d life bonus)\nSpace, Enter or click to play again" % [score, lives * 100])
	_update_hud()


# --- Input --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		use_mouse = true
		return

	var pressed: bool = event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return

	match state:
		State.TITLE, State.WON, State.GAME_OVER:
			_new_game()
		State.SERVE:
			_launch()


# --- Simulation ---------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_update_particles(delta)
	shake = max(0.0, shake - 40.0 * delta)

	if state == State.SERVE or state == State.PLAYING:
		_move_paddle(delta)

	if state == State.SERVE:
		ball_pos = Vector2(paddle_x, PADDLE_Y - BALL_R - 1.0)
	elif state == State.PLAYING:
		_move_ball(delta)

	queue_redraw()


func _move_paddle(delta: float) -> void:
	if autopilot:
		# Aim off-centre by a random amount so the ball keeps changing angle.
		var target := ball_pos.x + autopilot_aim
		paddle_x = move_toward(paddle_x, target, PADDLE_SPEED * delta)
	else:
		var axis := Input.get_axis("ui_left", "ui_right")
		if axis != 0.0:
			use_mouse = false
			paddle_x += axis * PADDLE_SPEED * delta
		elif use_mouse:
			paddle_x = get_global_mouse_position().x
	paddle_x = clamp(paddle_x, PADDLE_W / 2.0, W - PADDLE_W / 2.0)


func _move_ball(delta: float) -> void:
	var travel := ball_vel.length() * delta
	var steps := maxi(1, ceili(travel / SUBSTEP))
	var step_dt := delta / steps
	for i in steps:
		ball_pos += ball_vel * step_dt
		_collide_walls()
		if state != State.PLAYING:
			return
		_collide_paddle()
		_collide_bricks()
		if state != State.PLAYING:
			return


func _collide_walls() -> void:
	if ball_pos.x < BALL_R:
		ball_pos.x = BALL_R
		ball_vel.x = absf(ball_vel.x)
	elif ball_pos.x > W - BALL_R:
		ball_pos.x = W - BALL_R
		ball_vel.x = -absf(ball_vel.x)
	if ball_pos.y < HUD_H + BALL_R:
		ball_pos.y = HUD_H + BALL_R
		ball_vel.y = absf(ball_vel.y)
	elif ball_pos.y > H + BALL_R * 2.0:
		_lose_life()


func _collide_paddle() -> void:
	if ball_vel.y <= 0.0:
		return
	var rect := _paddle_rect()
	if not _circle_hits_rect(ball_pos, rect):
		return
	# Only bounce if the ball is above the paddle's middle; otherwise it's gone.
	if ball_pos.y > rect.get_center().y:
		return
	# Where it hit the paddle (-1 = left edge, 1 = right edge) sets the angle.
	var offset := clampf((ball_pos.x - paddle_x) / (PADDLE_W / 2.0 + BALL_R), -1.0, 1.0)
	var angle := offset * MAX_BOUNCE_ANGLE
	ball_vel = Vector2(sin(angle), -cos(angle)) * ball_speed
	ball_pos.y = rect.position.y - BALL_R
	autopilot_aim = randf_range(-0.4, 0.4) * PADDLE_W
	_burst(Vector2(ball_pos.x, rect.position.y), Color(0.85, 0.9, 1.0), 4)


func _collide_bricks() -> void:
	for i in bricks.size():
		var brick: Dictionary = bricks[i]
		var r: Rect2 = brick.rect
		if not _circle_hits_rect(ball_pos, r):
			continue

		# Bounce off whichever side the ball overlaps least.
		var overlap_x := minf(ball_pos.x + BALL_R - r.position.x, r.end.x - (ball_pos.x - BALL_R))
		var overlap_y := minf(ball_pos.y + BALL_R - r.position.y, r.end.y - (ball_pos.y - BALL_R))
		var c := r.get_center()
		if overlap_x < overlap_y:
			var dir := 1.0 if ball_pos.x >= c.x else -1.0
			ball_vel.x = absf(ball_vel.x) * dir
			ball_pos.x += overlap_x * dir
		else:
			var dir := 1.0 if ball_pos.y >= c.y else -1.0
			ball_vel.y = absf(ball_vel.y) * dir
			ball_pos.y += overlap_y * dir

		brick.hits -= 1
		if brick.hits <= 0:
			score += brick.points
			_burst(c, brick.color, 14)
			bricks.remove_at(i)
			shake = maxf(shake, 3.0)
		else:
			_burst(c, Color.WHITE, 6)

		ball_speed = minf(BALL_MAX_SPEED, ball_speed + BALL_SPEEDUP)
		ball_vel = ball_vel.normalized() * ball_speed
		_update_hud()
		if bricks.is_empty():
			_win()
		return # at most one brick per sub-step


func _paddle_rect() -> Rect2:
	return Rect2(paddle_x - PADDLE_W / 2.0, PADDLE_Y, PADDLE_W, PADDLE_H)


func _circle_hits_rect(center: Vector2, rect: Rect2) -> bool:
	var closest := center.clamp(rect.position, rect.end)
	return center.distance_squared_to(closest) <= BALL_R * BALL_R


# --- Effects ------------------------------------------------------------------

func _burst(at: Vector2, color: Color, count: int) -> void:
	for i in count:
		var dir := Vector2.from_angle(randf() * TAU)
		particles.append({
			"pos": at,
			"vel": dir * randf_range(60.0, 260.0),
			"color": color,
			"life": randf_range(0.3, 0.7),
		})


func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.life -= delta
		if p.life <= 0.0:
			particles.remove_at(i)
			continue
		p.vel.y += 500.0 * delta
		p.pos += p.vel * delta


# --- Drawing ------------------------------------------------------------------

func _draw() -> void:
	var offset := Vector2.ZERO
	if shake > 0.0:
		offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	draw_set_transform(offset)

	# Play field and HUD strip.
	draw_rect(Rect2(0, 0, W, H), Color(0.07, 0.08, 0.12))
	draw_rect(Rect2(0, 0, W, HUD_H), Color(0.04, 0.05, 0.08))
	draw_line(Vector2(0, HUD_H), Vector2(W, HUD_H), Color(0.3, 0.35, 0.5), 2.0)

	for brick in bricks:
		var r: Rect2 = brick.rect
		var col: Color = brick.color
		if brick.hits > 1:
			col = col.lightened(0.15)
			draw_rect(r.grow(2.0), Color(1, 1, 1, 0.8), false, 2.0) # armour outline
		draw_rect(r, col)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), col.lightened(0.35))
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 4)), col.darkened(0.35))

	# Paddle.
	var pr := _paddle_rect()
	draw_rect(pr, Color(0.85, 0.9, 1.0))
	draw_rect(Rect2(pr.position, Vector2(pr.size.x, 4)), Color.WHITE)

	# Ball (with a faint trail while moving).
	if state == State.PLAYING:
		draw_circle(ball_pos - ball_vel * 0.02, BALL_R * 0.8, Color(1, 1, 1, 0.15))
		draw_circle(ball_pos - ball_vel * 0.01, BALL_R * 0.9, Color(1, 1, 1, 0.3))
	if state != State.WON and state != State.GAME_OVER:
		draw_circle(ball_pos, BALL_R, Color(1.0, 0.95, 0.8))

	for p in particles:
		var c: Color = p.color
		c.a = clampf(p.life / 0.4, 0.0, 1.0)
		draw_rect(Rect2(p.pos - Vector2(2, 2), Vector2(4, 4)), c)

	draw_set_transform(Vector2.ZERO)


# --- UI -----------------------------------------------------------------------

func _show_info(text: String) -> void:
	info_label.text = text


func _update_hud() -> void:
	score_label.text = "Score: %d   Best: %d" % [score, best]
	lives_label.text = "Lives: %d" % maxi(lives, 0)
