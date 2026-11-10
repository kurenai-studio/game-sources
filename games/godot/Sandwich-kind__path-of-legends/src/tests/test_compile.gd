extends SceneTree
func _init():
	for d in ["core", "ui", "characters", "weapons", "maps", "modes", "story"]:
		for f in DirAccess.get_files_at("res://" + d):
			if f.ends_with(".gd"):
				var s = load("res://%s/%s" % [d, f])
				if s == null or not s.can_instantiate():
					print("FAIL ", d, "/", f)
	print("compiled")
	quit()
