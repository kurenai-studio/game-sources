class_name AthleteView
extends Node2D
## Draws one hot dog: its body put together from the sprite sheets (sausage,
## bun, toppings, sweatband), the frame that fits its squash and turn, a face
## on top that shows how it feels, and what it wears from the wardrobe (a hat,
## an outfit, a trail behind it).
##
## The node sits where the hot dog touches the ground; `lift` raises it
## (pixels), `squash` squashes and stretches it, `angle` turns it (degrees,
## 0 upright, 90 lying forward), `mood` picks its face.

const DOGS := "res://assets/art/dogs/"
const KIT := "res://assets/art/wardrobe/"
const SHADER := preload("res://ui/swap.gdshader")

static var _meta: Dictionary = {}
static var _bodies: Dictionary = {}
static var _face_tex: Texture2D
static var _face: Dictionary = {}
static var _kit: Dictionary = {}          ## wardrobe sheets, by path (null: there isn't one)

var look: Dictionary = {}
var lift := 0.0
var squash := 1.0
var angle := 0.0
var lean := 0.0                  ## 0..1: leaning into a fast bounce
var mood := "ready"
var twist := 0.0                 ## 0..1 through a twist (the dive)
var shadow := true
var ground_shadow := 1.0         ## how dark the shadow is (0 none)
var flash := 0.0
var trail_on := true             ## leave the look's trail behind when it moves
var scroll := 0.0                ## how far the world has scrolled on screen (the trail stays on the ground)
var _tex: Texture2D
var _hat: Texture2D
var _front: Texture2D
var _back: Texture2D
var _hair_shows := true
var _trail: Array = []           ## {p (where, on the parent), v, age, life, k}
var _trail_last := Vector2.INF
var _trail_t := 0.0
var _blink := 0.0
var _blink_t := 2.0

const FACES := {
	"ready": ["look", "smile", "none"],
	"push": ["look", "grit", "keen"],
	"happy": ["look", "grin", "none"],
	"ouch": ["wide", "o", "worried"],
	"dizzy": ["dizzy", "wobble", "none"],
	"joy": ["happy", "open", "none"],
	"sad": ["sleepy", "frown", "worried"],
	"fly": ["wide", "open", "up"],
	"sizzle": ["look", "grin", "keen"],
	"front": ["front", "smile", "none"],
	"wink": ["happy", "tongue", "none"],
}


static func meta() -> Dictionary:
	if _meta.is_empty():
		var f := FileAccess.open(DOGS + "dogs.json", FileAccess.READ)
		_meta = JSON.parse_string(f.get_as_text()) if f else {}
		_face_tex = load("res://assets/art/face/face.png")
		var g := FileAccess.open("res://assets/art/face/face.json", FileAccess.READ)
		_face = JSON.parse_string(g.get_as_text()) if g else {}
	return _meta


static func _layer(path: String) -> Image:
	if not ResourceLoader.exists(path):
		return null
	var t: Texture2D = load(path)
	var img := t.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


## The body sheet for a look: every layer painted together (cached).
static func body(look_: Dictionary) -> Texture2D:
	meta()
	var key := "%s|%s|%s" % [look_.get("sausage", "frank"), look_.get("bun", "soft"), ",".join(look_.get("toppings", []))]
	if _bodies.has(key):
		return _bodies[key]
	var paths: Array = []
	var bun := String(look_.get("bun", "soft"))
	paths.append(DOGS + "bun_back_%s.png" % bun)
	paths.append(DOGS + "sausage_%s.png" % look_.get("sausage", "frank"))
	paths.append(DOGS + "bun_%s.png" % bun)
	for t in look_.get("toppings", []):
		paths.append(DOGS + "top_%s.png" % t)
	var sausage := String(look_.get("sausage", ""))
	paths.append(DOGS + ("band_%s.png" % sausage if sausage in ["corn", "lorne"] else "band.png"))
	var img: Image = null
	for p in paths:
		var l := _layer(p)
		if l == null:
			continue
		if img == null:
			img = Image.create(l.get_width(), l.get_height(), false, Image.FORMAT_RGBA8)
		img.blend_rect(l, Rect2i(Vector2i.ZERO, l.get_size()), Vector2i.ZERO)
	var tex := ImageTexture.create_from_image(img)
	_bodies[key] = tex
	return tex


func _ready() -> void:
	meta()
	_blink_t = randf_range(1.0, 4.0)


static func kit(path: String) -> Texture2D:
	if not _kit.has(path):
		_kit[path] = load(path) if ResourceLoader.exists(path) else null
	return _kit[path]


func set_look(l: Dictionary) -> void:
	look = l
	_tex = body(look)
	var hat := String(look.get("hat", "none"))
	var outfit := String(look.get("outfit", "none"))
	_hat = kit(KIT + "hat_%s.png" % hat) if hat != "none" else null
	_front = kit(KIT + "out_%s.png" % outfit) if outfit != "none" else null
	_back = kit(KIT + "out_back_%s.png" % outfit) if outfit != "none" else null
	_hair_shows = _hat == null or hat in Wardrobe.art().get("hair_shows", [])
	if String(look.get("trail", "none")) == "none":
		_trail.clear()
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var m := meta()
	var keys: Dictionary = m.get("band_keys", {})
	var teams: Dictionary = m.get("teams", {})
	var band: Array = look.get("band", ["red", "white"])
	mat.set_shader_parameter("key_main", _cols(keys.get("main", [])))
	mat.set_shader_parameter("key_stripe", _cols(keys.get("stripe", [])))
	mat.set_shader_parameter("main_col", _cols(teams.get(String(band[0]), teams.get("red", []))))
	mat.set_shader_parameter("stripe_col", _cols(teams.get(String(band[1]), teams.get("white", []))))
	material = mat
	queue_redraw()


static func _cols(list: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	for c in list:
		out.append(Vector3(float(c[0]) / 255.0, float(c[1]) / 255.0, float(c[2]) / 255.0))
	while out.size() < 3:
		out.append(Vector3(1, 0, 1))
	return out


func _process(delta: float) -> void:
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink = 0.12
		_blink_t = randf_range(2.0, 5.0)
	if _blink > 0.0:
		_blink -= delta
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 4.0)
		(material as ShaderMaterial).set_shader_parameter("flash", flash)
	_update_trail(delta)
	queue_redraw()


# -- the trail ---------------------------------------------------------------------

const TRAIL_MAX := 48
const RAINBOW := [Color("e2443e"), Color("ff7a2e"), Color("ffd83a"), Color("7ad448"), Color("3e6ae2"), Color("7a3ad2")]


## A trail is left on the parent (it stays where the hot dog was), a puff each
## few pixels it moves, or now and then when it stands still.
func _update_trail(delta: float) -> void:
	var kind := String(look.get("trail", "none"))
	for i in range(_trail.size() - 1, -1, -1):
		var q: Dictionary = _trail[i]
		q.age += delta
		q.p += q.v * delta
		if q.age >= q.life:
			_trail.remove_at(i)
	if kind == "none" or not trail_on or not visible:
		return
	# from just behind the bun (out of sight inside it, a still hot dog would show none)
	var here := transform * Vector2(-15, -lift - 16) - Vector2(scroll, 0.0)
	_trail_t += delta
	var step := 2.0 if kind == "rainbow" else 5.0
	var moved := here.distance_to(_trail_last) if _trail_last != Vector2.INF else 99.0
	if moved < step * absf(scale.x) and _trail_t < 0.16:
		return
	_trail_t = 0.0
	_trail_last = here
	var v := Vector2(randf_range(-12, 0), randf_range(-14, -4)) * absf(scale.x)
	match kind:
		"bubbles":
			v = Vector2(randf_range(-4, 4), randf_range(-22, -12)) * absf(scale.x)
		"fire":
			v = Vector2(randf_range(-5, 5), randf_range(-26, -14)) * absf(scale.x)
		"rainbow":
			v = Vector2.ZERO
	var jitter := Vector2(randf_range(-4, 4), randf_range(-8, 8)) * absf(scale.x) if kind != "rainbow" else Vector2.ZERO
	_trail.append({"p": here + jitter, "v": v, "age": 0.0, "life": 0.5 if kind == "rainbow" else randf_range(0.5, 0.8),
		"k": randi() % 4})
	if _trail.size() > TRAIL_MAX:
		_trail.pop_front()


func _draw_trail() -> void:
	var kind := String(look.get("trail", "none"))
	if _trail.is_empty() or kind == "none":
		return
	var inv := transform.affine_inverse()
	for q in _trail:
		var p: Vector2 = (inv * ((q.p as Vector2) + Vector2(scroll, 0.0))).round()
		var a := clampf(1.0 - float(q.age) / float(q.life), 0.0, 1.0)
		var k := int(q.k)
		match kind:
			"sparkles":
				var c := Color(Kit.PAPER if k % 2 else Kit.MUSTARD, a)
				draw_rect(Rect2(p + Vector2(-1, 0), Vector2(3, 1)), c)
				draw_rect(Rect2(p + Vector2(0, -1), Vector2(1, 3)), c)
			"stars":
				var c := Color(Kit.MUSTARD, a)
				draw_rect(Rect2(p + Vector2(-2, 0), Vector2(5, 1)), c)
				draw_rect(Rect2(p + Vector2(0, -2), Vector2(1, 5)), c)
				draw_rect(Rect2(p + Vector2(-1, -1), Vector2(3, 3)), c)
				draw_rect(Rect2(p, Vector2(1, 1)), Color(Kit.PAPER, a))
			"hearts":
				var c := Color("ff5ab4", a)
				draw_rect(Rect2(p + Vector2(-2, -1), Vector2(2, 2)), c)
				draw_rect(Rect2(p + Vector2(1, -1), Vector2(2, 2)), c)
				draw_rect(Rect2(p + Vector2(-1, 0), Vector2(3, 2)), c)
				draw_rect(Rect2(p + Vector2(0, 2), Vector2(1, 1)), c)
			"bubbles":
				draw_arc(p, 2.0 + k * 0.5, 0.0, TAU, 10, Color(Kit.SKY.lightened(0.3), a), 1.0)
				draw_rect(Rect2(p + Vector2(-1, -1), Vector2(1, 1)), Color(Kit.PAPER, a))
			"fire":
				var t := float(q.age) / float(q.life)
				var c := Kit.MUSTARD.lerp(Kit.KETCHUP, t)
				draw_rect(Rect2(p - Vector2(1, 1), Vector2(2 + (k % 2), 2 + (k % 2))), Color(c, a))
			"rainbow":
				for i in RAINBOW.size():
					draw_rect(Rect2(p + Vector2(-1, i - 3), Vector2(3, 1)), Color(RAINBOW[i], a * 0.9))


## Which frame of the sheet fits the pose now.
func frame() -> Dictionary:
	var frames: Array = meta().get("frames", [])
	return frames[frame_index()]


func frame_index() -> int:
	var a := fposmod(angle, 360.0)
	var upright := a < 7.0 or a > 353.0
	if upright or (lean > 0.5 and absf(angle - 14.0) < 8.0):
		var squashes := [0.68, 0.78, 0.88, 1.0, 1.1, 1.2, 1.3]
		var best := 3
		for i in squashes.size():
			if absf(squashes[i] - squash) < absf(squashes[best] - squash):
				best = i
		var base := 7 if (lean > 0.5 and not upright) or (lean > 0.5 and absf(angle) < 3.0) else 0
		return base + best
	var k := int(roundf(a / 15.0)) % 24
	return 14 + k


func _draw() -> void:
	if _tex == null:
		return
	var m := meta()
	var cell: Array = m.get("cell", [52, 72])
	var fi := frame_index()
	var f: Dictionary = m.get("frames", [])[fi]
	var spin := String(f.name).begins_with("spin")
	_draw_trail()
	if shadow and ground_shadow > 0.0:
		var w := clampf(10.0 - lift * 0.08 + (1.0 - squash) * 5.0, 4.0, 12.0)
		var c := Color(0.08, 0.04, 0.12, 0.38 * ground_shadow)
		draw_rect(Rect2(-w, -1, w * 2, 2), c)
		draw_rect(Rect2(-w + 2, -2, w * 2 - 4, 4), c)
	var org: Array = f.origin
	var at := Vector2(0, -lift)
	if spin:
		at += Vector2(0, -22)
	var sx := 1.0
	if twist > 0.0:
		sx = cos(twist * TAU)
		sx = signf(sx) * maxf(absf(sx), 0.25)
	_base = Transform2D(0.0, Vector2(sx, 1.0), 0.0, at.round())
	draw_set_transform_matrix(_base)
	var src := Rect2(float(f.cell[0]), float(f.cell[1]), float(cell[0]), float(cell[1]))
	var dst := Rect2(-float(org[0]), -float(org[1]), float(cell[0]), float(cell[1]))
	if _back:
		_draw_kit(_back, fi, dst.position)
	draw_texture_rect_region(_tex, dst, src)
	if _front:
		_draw_kit(_front, fi, dst.position)
	if absf(sx) > 0.4:
		_draw_face(f, Vector2(-float(org[0]), -float(org[1])), signf(sx))
	if _hat:
		_draw_kit(_hat, fi, dst.position)
	draw_set_transform(Vector2.ZERO)


## A wardrobe layer's frame: its cell is bigger than the body's, by `offset`.
func _draw_kit(tex: Texture2D, fi: int, body_at: Vector2) -> void:
	var w := Wardrobe.art()
	var cell: Array = w.get("cell", [88, 104])
	var off: Array = w.get("offset", [18, 32])
	var cols := int(w.get("cols", 8))
	var src := Rect2(float((fi % cols) * int(cell[0])), float((fi / cols) * int(cell[1])), float(cell[0]), float(cell[1]))
	draw_texture_rect_region(tex, Rect2(body_at - Vector2(float(off[0]), float(off[1])), src.size), src)


func _draw_face(f: Dictionary, off: Vector2, facing: float) -> void:
	var anchors: Dictionary = f.anchors
	var quarter := int(roundf(fposmod(float(f.angle), 360.0) / 90.0)) % 4
	var expr: Array = FACES.get(mood, FACES.ready)
	var eyes := String(expr[0])
	if _blink > 0.0 and eyes in ["look", "front", "wide"]:
		eyes = "shut"
	if look.get("eyes", "look") != "look" and eyes == "look":
		eyes = String(look.eyes)
	var hair := String(look.get("hair", "none"))
	if hair != "none" and _hair_shows:
		_stamp("hair", hair, off + _v(anchors.top), quarter, Vector2(0, -1), true)
	var e := off + _v(anchors.eyes)
	var side := _turn(Vector2(3, 0), quarter)
	_stamp("eyes", eyes, e - side, quarter)
	_stamp("eyes", eyes, e + side, quarter)
	var specs := String(look.get("specs", "none"))
	if specs != "none" and eyes not in ["dizzy", "star"]:
		_stamp("specs", specs, e + _turn(Vector2(0, -0.5), quarter), quarter)
	_stamp("mouth", String(expr[1]), off + _v(anchors.mouth), quarter)
	var tache := String(look.get("tache", "none"))
	if tache != "none":
		_stamp("tache", tache, off + _v(anchors.mouth) + _turn(Vector2(0, -2), quarter), quarter)
	if String(expr[2]) != "none" and specs == "none":
		_stamp("brow", String(expr[2]), off + _v(anchors.brow), quarter)


static func _v(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


static func _turn(v: Vector2, quarter: int) -> Vector2:
	for i in quarter:
		v = Vector2(-v.y, v.x)
	return v


## Draw a stamp from the face atlas centred at `at`, turned by quarter turns.
## `sit` moves it so its edge (not its centre) sits on the anchor.
func _stamp(group: String, name: String, at: Vector2, quarter: int, sit := Vector2.ZERO, _hair := false) -> void:
	var g: Dictionary = _face.get(group, {})
	if not g.has(name):
		return
	var r: Array = g[name]
	var size := Vector2(float(r[2]), float(r[3]))
	var c := at + _turn(sit * size * 0.5, quarter)
	var xf := Transform2D(quarter * PI / 2.0, c.round())
	draw_set_transform_matrix(_base * xf)
	draw_texture_rect_region(_face_tex, Rect2((-size / 2.0).round(), size), Rect2(float(r[0]), float(r[1]), size.x, size.y))
	draw_set_transform_matrix(_base)


var _base := Transform2D.IDENTITY
