extends SceneTree
# Внешний вид Воплощения Тьмы: голова и руки (раскрытые, кулак, плашмя)
var f := 0
var rigs: Array = []
func _initialize() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.08, 0.10)
	bg.size = Vector2(1600, 720)
	root.add_child(bg)
	var head := AvatarRig.new()
	head.part = "head"
	head.size = Vector2(300, 270)
	head.position = Vector2(800, 220)
	root.add_child(head)
	rigs.append(head)
	for s in [-1, 1]:
		var h := AvatarRig.new()
		h.part = "hand"
		h.side = s
		h.size = Vector2(190, 150)
		h.position = Vector2(800 + s * 520, 330)
		root.add_child(h)
		rigs.append(h)
	var fist := AvatarRig.new()
	fist.part = "hand"
	fist.side = -1
	fist.size = Vector2(190, 150)
	fist.fist = true
	fist.position = Vector2(260, 600)
	root.add_child(fist)
	var flat := AvatarRig.new()
	flat.part = "hand"
	flat.side = 1
	flat.size = Vector2(190, 150)
	flat.flat = true
	flat.position = Vector2(1340, 620)
	root.add_child(flat)
func _process(_d: float) -> bool:
	f += 1
	if f == 30:
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/avatar_a.png")
		rigs[0].play("open")
	if f == 70:
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/avatar_b.png")
		return true
	return false
