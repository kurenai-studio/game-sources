extends SceneTree
# Внешности героя Истории: пол, телосложение, причёски, бороды, снаряжение.
var f := 0
func _initialize() -> void:
	var c := CanvasLayer.new()
	root.add_child(c)
	var bg := ColorRect.new()
	bg.color = Color(0.3, 0.45, 0.35)
	bg.size = Vector2(1600, 720)
	c.add_child(bg)
	var looks := []
	var i := 0
	for g in ["m", "f"]:
		for h in StoryLook.HAIRS:
			var lk := StoryLook.default_look()
			lk["gender"] = g
			lk["hair"] = h
			lk["build"] = StoryLook.BUILDS[i % 3]
			lk["skin"] = i % 6
			lk["hair_color"] = i % 7
			lk["eyes"] = (i + 2) % 6
			lk["beard"] = StoryLook.BEARDS[i % 4]
			lk["mark"] = StoryLook.MARKS[i % 3]
			looks.append([lk, {"chest": "leather_shirt", "legs": "leather_pants"}])
			i += 1
	var full := {"head": "iron_helm", "chest": "chainmail", "legs": "guard_greaves", "boots": "leather_boots",
			"hands": "leather_gloves", "cape": "traveler_cape", "melee": "short_sword", "ranged": "hunting_bow"}
	looks.append([StoryLook.default_look(), full])
	var lk2 := StoryLook.default_look()
	lk2["gender"] = "f"
	looks.append([lk2, {"chest": "chainmail", "legs": "guard_greaves", "melee": "rogue_dagger", "ranged": "sling"}])
	for k in looks.size():
		var holder := Node2D.new()
		holder.scale = Vector2(2.6, 2.6)
		holder.position = Vector2(80 + (k % 6) * 250, 150 + (k / 6) * 230)
		c.add_child(holder)
		var rig := BotRig.new()
		rig.kind = "story"
		rig.size = Player.SIZE
		rig.custom_spec = StoryLook.spec(looks[k][0], looks[k][1])
		holder.add_child(rig)
		if k == looks.size() - 2:
			rig.alt = "ranged"
			rig.hold = "draw"
func _process(_d: float) -> bool:
	f += 1
	if f == 30:
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/looks.png")
		return true
	return false
