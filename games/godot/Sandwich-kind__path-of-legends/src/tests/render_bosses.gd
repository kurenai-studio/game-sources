extends SceneTree
const KINDS := ["gladiator", "colossus", "chief", "treant", "spider_queen", "skeleton_king"]
var vps := []
var f := 0
func _initialize() -> void:
	for k in KINDS:
		var vp := SubViewport.new()
		vp.size = Vector2i(768, 768)
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(vp)
		var size: Vector2 = Bots.TYPES[k]["size"]
		var rig: Node2D
		if k == "spider_queen":
			var cr := CreatureRig.new(); cr.kind = k; cr.size = size; rig = cr
		else:
			var br := BotRig.new(); br.kind = k; br.size = size; rig = br
		var extra := 1.5 if k in ["treant", "colossus", "chief", "gladiator", "skeleton_king"] else 1.0
		var sc := minf(600.0 / (size.x * (1.6 if k == "spider_queen" else 1.4)), 600.0 / (size.y * extra))
		var holder := Node2D.new()
		holder.scale = Vector2(sc, sc)
		holder.position = Vector2(384, 384 + size.y * sc * (0.15 if extra > 1.0 else 0.0))
		holder.add_child(rig)
		vp.add_child(holder)
		vps.append([k, vp])
func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		for pair in vps:
			var img: Image = pair[1].get_texture().get_image()
			img.save_png("/home/claude/bosses/%s.png" % pair[0])
			print("saved ", pair[0])
		return true
	return false
