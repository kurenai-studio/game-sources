# The header's game clock: counts the game's hour of actual play (see
# game_session.gd's TIME_LIMIT_SECONDS) and shows what's left — "52:10"
# in faint cream, orange and bold in the last 5 minutes, then "Dernier
# tour" once the hour is up and the current round is the last.
#
# It only counts while `is_running` says someone is really playing — the
# caller (main.gd) knows about the handoff screen ("Au tour de …"), menus and
# dialogs — and never while the app is in the background.
class_name GameClock
extends Label

const _WARNING_SECONDS := 300
# Faint `cream_text` normally; `ribbon` orange near the end (see
# doc/ART_DIRECTION.md's palette).
const _NORMAL_COLOR := Color(0.953, 0.937, 0.847, 0.6)
const _WARNING_COLOR := Color("e4733a")

# The game being timed; null (and the clock hidden) when there's none, or
# in free play, which has no time limit.
var session: GameSession:
	set(value):
		session = value
		visible = session != null
# Asked every frame whether play is under way right now (a Callable: a
# function passed around as a value, like a C++ std::function).
var is_running: Callable

# Whether the app is in the foreground (see `_notification`).
var _app_focused := true


# Runs every frame: counts the frame's `delta` seconds if the game is
# being played, then shows the time left.
func _process(delta: float) -> void:
	if session == null:
		return
	if _app_focused and is_running.call():
		session.add_play_time(delta)
	_show_time()


func _show_time() -> void:
	var seconds := int(ceil(session.remaining_time()))
	if session.is_last_round():
		text = "Dernier tour"
	elif session.is_game_over():
		text = ""
	else:
		text = "%d:%02d" % [seconds / 60, seconds % 60]
	var urgent := session.is_last_round() or seconds <= _WARNING_SECONDS
	add_theme_color_override("font_color", _WARNING_COLOR if urgent else _NORMAL_COLOR)
	# Bold (the tiles' Jost SemiBold) once urgent, the theme's font before.
	if urgent:
		add_theme_font_override("font", TileView.LETTER_FONT)
	else:
		remove_theme_font_override("font")


# Built-in callback Godot calls on a node for various engine events (see
# clue_markers_view.gd). Here: the app going to the background (another
# window, or the phone's home screen) pauses the clock, and coming back
# resumes it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_app_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_app_focused = true
