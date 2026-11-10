extends SceneTree
# Крупный план моделей легенд (для проверки внешнего вида)
var f := 0
func _initialize() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.85, 0.80, 0.68)
	bg.size = Vector2(1600, 720)
	root.add_child(bg)
	var kinds := (OS.get_environment("KINDS") if OS.get_environment("KINDS") != "" else "osoka,prism,hunter,ternovnik").split(",")
	for i in kinds.size():
		var r := BotRig.new()
		r.kind = kinds[i]
		r.size = Vector2(40, 74)
		r.puppet_facing = 1
		var holder := Node2D.new()
		holder.position = Vector2(200 + i * 380, 380)
		holder.scale = Vector2(4, 4)
		root.add_child(holder)
		holder.add_child(r)
func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/rigs.png")
		return true
	return false
