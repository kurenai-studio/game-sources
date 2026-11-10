class_name QRScanner
extends PanelContainer
## SCAN ITS CODE: point this tablet's camera at the QR code on the other
## tablet's PLAY TOGETHER screen to join its game. Shows what the camera sees,
## reads it a couple of times a second (on a worker thread, so the picture
## stays smooth) and says when it has the code. If there's no camera, or it
## isn't allowed, it says so: the games found on the Wi-Fi and the short code
## to type are still there. (After Reggie's Neon Adventure's scanner.)

signal found(host: String, port: int)
signal closed

const LOOK_EVERY := 0.45          ## seconds between reads
const PREVIEW := preload("res://ui/camera_preview.gdshader")

var view: TextureRect
var status: Label
var _feed: CameraFeed
var _tex: CameraTexture
var _task := -1
var _result := ""
var _t := 0.0
var _feeds: Array = []
var _which := 0
var _grabber: SubViewport         ## for cameras whose picture can't be read back directly
var _grab_rect: TextureRect
var _done := false
var _flip: Button


## The game's address in a code read off a PLAY TOGETHER screen
## ("http://192.168.1.23:8642/"): [host, port], or [] if it isn't one.
static func address(text: String) -> Array:
	var t := text.strip_edges()
	if not t.begins_with("http://"):
		return []
	t = t.trim_prefix("http://")
	t = t.get_slice("/", 0)
	var host := t.get_slice(":", 0)
	var port := int(t.get_slice(":", 1)) if t.contains(":") else Remote.PORTS[0]
	if not host.is_valid_ip_address() or port <= 0:
		return []
	return [host, port]


func _ready() -> void:
	add_theme_stylebox_override("panel", Kit.box(Color("1a1424"), Kit.INK, 1, 2))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	var title := Kit.label("SCAN ITS CODE", "big", Kit.MUSTARD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", Kit.box(Color("120c1a"), Kit.INK, 1, 0))
	v.add_child(frame)
	view = TextureRect.new()
	view.custom_minimum_size = Vector2(240, 150)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(view)
	var aim := Corners.new()
	aim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(aim)
	status = Kit.label("POINT THE CAMERA AT THE CODE ON THE OTHER TABLET", "small", Kit.PAPER)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(240, 22)
	v.add_child(status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var back := Kit.small_button("BACK", Color("4e4a62"), 70)
	back.pressed.connect(func(): closed.emit())
	row.add_child(back)
	_flip = Kit.small_button("OTHER CAMERA", Color("2a5a7a"), 100)
	_flip.visible = false
	_flip.pressed.connect(func():
		if _feeds.size() > 1:
			_use((_which + 1) % _feeds.size()))
	row.add_child(_flip)
	QRReader._tables()               # ready before the worker thread needs them
	_start.call_deferred()


func _start() -> void:
	if OS.get_name() == "Android" and not OS.get_granted_permissions().has("android.permission.CAMERA"):
		say("MAY I USE THE CAMERA? TAP ALLOW.")
		if not OS.request_permission("android.permission.CAMERA"):
			var waited := 0.0
			while waited < 20.0 and is_inside_tree() and not OS.get_granted_permissions().has("android.permission.CAMERA"):
				await get_tree().create_timer(0.25).timeout
				waited += 0.25
			if not is_inside_tree():
				return
			if not OS.get_granted_permissions().has("android.permission.CAMERA"):
				say("NO CAMERA. PICK THE GAME FROM THE LIST, OR TYPE ITS CODE.", true)
				return
	CameraServer.monitoring_feeds = true
	var waited := 0.0
	while CameraServer.get_feed_count() == 0 and waited < 3.0 and is_inside_tree():
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	if not is_inside_tree():
		return
	_feeds = CameraServer.feeds()
	if _feeds.is_empty():
		say("NO CAMERA HERE. PICK THE GAME FROM THE LIST, OR TYPE ITS CODE.", true)
		return
	# the camera on the back first: it's the one that looks at another screen
	_feeds.sort_custom(func(a, b): return int(a.get_position() == CameraFeed.FEED_BACK) > int(b.get_position() == CameraFeed.FEED_BACK))
	_flip.visible = _feeds.size() > 1
	_use(0)


func _use(i: int) -> void:
	if _feed:
		_feed.feed_is_active = false
	_which = i
	_feed = _feeds[i]
	# a picture about 640 across is plenty, and quick
	var formats: Array = _feed.get_formats()
	var best := -1
	var best_d := INF
	for k in formats.size():
		var f: Dictionary = formats[k]
		if f.has("width"):
			var d := absf(float(f.width) - 640.0)
			if d < best_d:
				best_d = d
				best = k
	if best >= 0:
		_feed.set_format(best, {})
	_feed.feed_is_active = true
	_tex = CameraTexture.new()
	_tex.camera_feed_id = _feed.get_id()
	_tex.which_feed = CameraServer.FEED_RGBA_IMAGE    # (the light-and-dark picture, for cameras that send it on its own)
	_tex.camera_is_active = true
	view.texture = _tex
	# cameras that send brightness and colour separately: put them back together to show
	view.material = null
	if _feed.get_datatype() in [CameraFeed.FEED_YCBCR_SEP, CameraFeed.FEED_YCBCR]:
		var m := ShaderMaterial.new()
		m.shader = PREVIEW
		if _feed.get_datatype() == CameraFeed.FEED_YCBCR_SEP:
			var cbcr := CameraTexture.new()
			cbcr.camera_feed_id = _feed.get_id()
			cbcr.which_feed = CameraServer.FEED_CBCR_IMAGE
			cbcr.camera_is_active = true
			m.set_shader_parameter("cbcr_tex", cbcr)
			m.set_shader_parameter("has_cbcr", true)
		view.material = m
	say("POINT THE CAMERA AT THE CODE ON THE OTHER TABLET")


func _process(dt: float) -> void:
	if _done:
		return
	if _task >= 0:
		if WorkerThreadPool.is_task_completed(_task):
			WorkerThreadPool.wait_for_task_completion(_task)
			_task = -1
			var a := QRScanner.address(_result)
			if not a.is_empty():
				_done = true
				say("GOT IT! JOINING...")
				Sound.play("finish", 0.7)
				found.emit(String(a[0]), int(a[1]))
			elif _result != "":
				say("THAT'S A DIFFERENT CODE. POINT AT THE ONE ON PLAY TOGETHER.")
		return
	if _tex == null or not _feed or not _feed.feed_is_active:
		return
	_t -= dt
	if _t > 0.0:
		return
	_t = LOOK_EVERY
	var img := _picture()
	if img == null or img.is_empty():
		return
	_result = ""
	_task = WorkerThreadPool.add_task(func(): _result = QRReader.read(img))


## What the camera sees, as an image to read.
func _picture() -> Image:
	var img: Image = _tex.get_image()
	if img != null and not img.is_empty():
		return img
	# some cameras' pictures only live on the graphics card: draw one into a
	# little hidden screen and read that back
	if _grabber == null:
		_grabber = SubViewport.new()
		_grabber.size = Vector2i(640, 480)
		_grabber.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_grab_rect = TextureRect.new()
		_grab_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_grab_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_grab_rect.size = Vector2(640, 480)
		_grabber.add_child(_grab_rect)
		add_child(_grabber)
	_grab_rect.texture = _tex
	return _grabber.get_texture().get_image()


func say(text: String, trouble := false) -> void:
	if is_instance_valid(status):
		status.text = text
		status.add_theme_color_override("font_color", Kit.KETCHUP if trouble else Kit.PAPER)


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	if _feed:
		_feed.feed_is_active = false
	CameraServer.monitoring_feeds = false


## Corner marks over the picture: "put the code in here".
class Corners extends Control:
	func _draw() -> void:
		var s := minf(size.x, size.y) * 0.7
		var r := Rect2(size * 0.5 - Vector2(s, s) * 0.5, Vector2(s, s))
		var l := s * 0.18
		var col := Color(Kit.MUSTARD, 0.9)
		for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			var dx := l if c.x == r.position.x else -l
			var dy := l if c.y == r.position.y else -l
			var hx: float = c.x if dx > 0 else c.x - absf(dx)
			var vy: float = c.y if dy > 0 else c.y - absf(dy)
			draw_rect(Rect2(hx, c.y - (0.0 if dy > 0 else 2.0), absf(dx), 2), col)
			draw_rect(Rect2(c.x - (0.0 if dx > 0 else 2.0), vy, 2, absf(dy)), col)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()
