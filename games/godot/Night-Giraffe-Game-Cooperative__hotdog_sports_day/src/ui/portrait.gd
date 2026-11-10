class_name Portrait
extends RefCounted
## A still picture of one hot dog, painted without the screen: the body sheet's
## upright frame, the sweatband in its colours, a happy face, and its hat and
## outfit. The phones show it (the game serves it as a PNG), so a player can
## see who they are.
##
## The same parts and anchors AthleteView draws with, done on an Image.

const FRAME := 3                 ## upright, neither squashed nor stretched


static func of(look: Dictionary, scale := 4, mood := "happy") -> Image:
	var m := AthleteView.meta()
	var frames: Array = m.get("frames", [])
	if frames.size() <= FRAME:
		return null
	var cell: Array = m.get("cell", [52, 72])
	var f: Dictionary = frames[FRAME]
	var sheet := _rgba(AthleteView.body(look))
	var kit := Wardrobe.art()
	var kcell: Array = kit.get("cell", [88, 104])
	var off := Vector2i(int(kit.get("offset", [18, 32])[0]), int(kit.get("offset", [18, 32])[1]))
	var w := int(cell[0])
	var h := int(cell[1])
	var W := int(kcell[0])
	var H := int(kcell[1])
	var cols := int(kit.get("cols", 8))
	var ksrc := Rect2i((FRAME % cols) * W, (FRAME / cols) * H, W, H)
	var hat := String(look.get("hat", "none"))
	var outfit := String(look.get("outfit", "none"))
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var layer := func(path: String) -> void:
		var t := AthleteView.kit(path)
		if t:
			img.blend_rect(_rgba(t), ksrc, Vector2i.ZERO)
	if outfit != "none":
		layer.call(AthleteView.KIT + "out_back_%s.png" % outfit)
	var body := Image.create(w, h, false, Image.FORMAT_RGBA8)
	body.blit_rect(sheet, Rect2i(int(f.cell[0]), int(f.cell[1]), w, h), Vector2i.ZERO)
	_swap_band(body, look, m)
	img.blend_rect(body, Rect2i(0, 0, w, h), off)
	if outfit != "none":
		layer.call(AthleteView.KIT + "out_%s.png" % outfit)
	var hair_shows: bool = hat == "none" or hat in kit.get("hair_shows", [])
	_face(img, f, look, mood, Vector2(off), hair_shows)
	if hat != "none":
		layer.call(AthleteView.KIT + "hat_%s.png" % hat)
	var used := img.get_used_rect()
	if used.size.x <= 0:
		return null
	img = img.get_region(used.grow(1).intersection(Rect2i(0, 0, W, H)))
	if scale > 1:
		img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	return img


static func _rgba(t: Texture2D) -> Image:
	var img := t.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


static func png(look: Dictionary, scale := 4) -> PackedByteArray:
	var img := of(look, scale)
	return img.save_png_to_buffer() if img else PackedByteArray()


## The sheets paint every sweatband in key colours; swap in the look's.
static func _swap_band(img: Image, look: Dictionary, m: Dictionary) -> void:
	var keys: Dictionary = m.get("band_keys", {})
	var teams: Dictionary = m.get("teams", {})
	var band: Array = look.get("band", ["red", "white"])
	var pairs: Array = []
	var main_k: Array = keys.get("main", [])
	var stripe_k: Array = keys.get("stripe", [])
	var main_c: Array = teams.get(String(band[0]), teams.get("red", []))
	var stripe_c: Array = teams.get(String(band[1]) if band.size() > 1 else "white", teams.get("white", []))
	for i in mini(main_k.size(), main_c.size()):
		pairs.append([_c(main_k[i]), _c(main_c[i])])
	for i in mini(stripe_k.size(), stripe_c.size()):
		pairs.append([_c(stripe_k[i]), _c(stripe_c[i])])
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a <= 0.0:
				continue
			for pr in pairs:
				var k: Color = pr[0]
				if absf(p.r - k.r) + absf(p.g - k.g) + absf(p.b - k.b) < 0.05:
					var to: Color = pr[1]
					img.set_pixel(x, y, Color(to.r, to.g, to.b, p.a))
					break


static func _c(a: Array) -> Color:
	return Color8(int(a[0]), int(a[1]), int(a[2]))


static func _face(img: Image, f: Dictionary, look: Dictionary, mood: String, off := Vector2.ZERO, hair_shows := true) -> void:
	AthleteView.meta()
	var atlas_tex: Texture2D = load("res://assets/art/face/face.png")
	var gf := FileAccess.open("res://assets/art/face/face.json", FileAccess.READ)
	if atlas_tex == null or gf == null:
		return
	var atlas := atlas_tex.get_image()
	if atlas.is_compressed():
		atlas.decompress()
	atlas.convert(Image.FORMAT_RGBA8)
	var face: Dictionary = JSON.parse_string(gf.get_as_text())
	var anchors: Dictionary = f.anchors
	var expr: Array = AthleteView.FACES.get(mood, AthleteView.FACES.ready)
	var eyes := String(expr[0])
	if look.get("eyes", "look") != "look" and eyes == "look":
		eyes = String(look.eyes)
	var stamp := func(group: String, name: String, at: Vector2, sit := Vector2.ZERO) -> void:
		var g: Dictionary = face.get(group, {})
		if not g.has(name):
			return
		var r: Array = g[name]
		var size := Vector2(float(r[2]), float(r[3]))
		var c := (at + off + sit * size * 0.5).round() + (-size / 2.0).round()
		img.blend_rect(atlas, Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])), Vector2i(int(c.x), int(c.y)))
	var hair := String(look.get("hair", "none"))
	if hair != "none" and hair_shows:
		stamp.call("hair", hair, _v(anchors.top), Vector2(0, -1))
	var e := _v(anchors.eyes)
	stamp.call("eyes", eyes, e - Vector2(3, 0))
	stamp.call("eyes", eyes, e + Vector2(3, 0))
	var specs := String(look.get("specs", "none"))
	if specs != "none":
		stamp.call("specs", specs, e + Vector2(0, -0.5))
	stamp.call("mouth", String(expr[1]), _v(anchors.mouth))
	var tache := String(look.get("tache", "none"))
	if tache != "none":
		stamp.call("tache", tache, _v(anchors.mouth) + Vector2(0, -2))
	if String(expr[2]) != "none" and specs == "none":
		stamp.call("brow", String(expr[2]), _v(anchors.brow))


static func _v(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))
