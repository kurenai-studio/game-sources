# Records one screen of the game as pictures, for `nix run .#screenshots`
# (see flake.nix). Which screen, and where to, come after a `--`:
#   godot4 --path . --fixed-fps 15 --script tools/capture_media.gd -- start OUT
#       the start card on the box lid: OUT/still.png
#   godot4 --path . --fixed-fps 15 --script tools/capture_media.gd -- howto 3 OUT
#       "Comment jouer" card 3 (from 0): one whole turn of its animation as
#       OUT/0000.png, 0001.png…, and OUT/still.png, the moment showing the
#       most (the latest frame with the most tiles, fully visible).
# `--fixed-fps` makes every frame step the game by exactly 1/15 s, however
# slow the drawing (here: software OpenGL, no GPU), so the pictures play
# back at the game's real speed. Needs a window to draw in (not --headless).
extends SceneTree

# The game's whole screen, as the game itself starts it.
const _MAIN := preload("res://scenes/main.tscn")
# How long the start screen gets to settle before its picture, in frames.
const _START_FRAMES := 30

# The folder the pictures go to.
var _out := ""
# The "Comment jouer" screen being recorded (null on the start screen).
var _view: HowToPlayView = null
# Frames drawn so far.
var _drawn := 0
# The instance ids (unique numbers, like Python's `id()`) of the tiles on
# the card in the last drawn frame, as Dictionary keys (used as a set).
var _previous := {}
# Pictures saved so far: the next one's number.
var _saved := 0
# True once the first turn of the card's animation has begun.
var _recording := false
# In that turn: the most tiles seen fully visible so far.
var _most_tiles := 0


# Called once by Godot when this script is the program (`--script`), like
# a C `main()`: here, before the first frame is drawn.
func _initialize() -> void:
	# Builds the game's scene and puts it on screen. Adding it to `root`
	# (the window) runs every node's `_ready()` at once, as a real start.
	var main := _MAIN.instantiate()
	root.add_child(main)
	# The scene only finishes starting (its `@onready` variables set) once
	# the first frame begins: wait for that. `process_frame` is a signal
	# the SceneTree emits every frame; ONE_SHOT disconnects it after one.
	process_frame.connect(_show.bind(main), CONNECT_ONE_SHOT)
	# `frame_post_draw`: emitted each time a frame has been drawn, so what
	# is on the nodes now is exactly what that picture shows.
	RenderingServer.frame_post_draw.connect(_on_frame_drawn)


# Opens the screen named on the command line, on the started game `main`.
func _show(main: Node) -> void:
	# The words after `--` on the command line, as an Array of Strings.
	var args := OS.get_cmdline_user_args()
	_out = args[-1]
	DirAccess.make_dir_recursive_absolute(_out)
	match args[0]:
		# The start card on the closed box lid: nothing to do.
		"start":
			pass
		# "Comment jouer": opened on its first card, then moved forward
		# to the one asked for.
		"howto":
			_view = main._how_to_play
			_view.open()
			_view._show_card(int(args[1]))
		_:
			push_error("unknown screen %s: start or howto N" % args[0])
			quit(1)


# The window's picture as it was just drawn, as an Image (pixels in memory).
func _picture() -> Image:
	return root.get_texture().get_image()


# After each frame is drawn: on the start screen, saves the picture once
# it has settled; on a card, saves every picture of the animation's first
# whole turn, until it starts over.
func _on_frame_drawn() -> void:
	_drawn += 1
	if _view == null:
		if _drawn == _START_FRAMES:
			_picture().save_png(_out.path_join("still.png"))
			quit()
		return
	var now := {}
	for node in _view._card_layer.get_children():
		# Tiles being removed stay until the frame ends: leave them out.
		if not node.is_queued_for_deletion():
			now[node.get_instance_id()] = true
	# A turn starts when every tile of the last frame is gone at once (see
	# how_to_play_view.gd's `_reset`; the card may even be empty for a
	# moment) — or, for the very first one, when its first tiles appear.
	var restarted := (
		(not _previous.is_empty() and _previous.keys().all(func(id): return not now.has(id)))
		or (not _recording and _previous.is_empty() and not now.is_empty())
	)
	_previous = now
	if restarted and _recording:
		# The second turn starts: the first one is all saved.
		quit()
		return
	if restarted:
		_recording = true
	if not _recording:
		return
	var picture := _picture()
	picture.save_png(_out.path_join("%04d.png" % _saved))
	_saved += 1
	# Fully visible (not fading in or out) with at least as many tiles as
	# the best so far: the new still.
	if _view._card_layer.modulate.a >= 0.999 and now.size() >= _most_tiles:
		_most_tiles = now.size()
		picture.save_png(_out.path_join("still.png"))
