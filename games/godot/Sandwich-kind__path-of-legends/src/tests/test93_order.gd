extends SceneTree
func _initialize() -> void:
	var names := []
	for i in Characters.display_order():
		names.append(Characters.LIST[i]["name"])
	print(names)
	var cur := 0
	var walk := []
	for k in 12:
		walk.append(Characters.LIST[cur]["name"])
		cur = Characters.step(cur, 1)
	print("вперёд: ", walk)
	print("назад от Охотницы: ", Characters.LIST[Characters.step(0, -1)]["name"])
	quit()
