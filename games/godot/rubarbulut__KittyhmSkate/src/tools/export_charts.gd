extends SceneTree
const Level = preload("res://scripts/level.gd")

func _initialize() -> void:
	var tracks: Array[Dictionary] = []
	for index in [-1,0,1,2]:
		var data: Dictionary = Level.spec(index)
		data["index"] = index
		data["notes"] = Level.notes(index)
		data["obstacles"] = Level.obstacles(index)
		data["rails"] = Level.rails(index)
		tracks.append(data)
	var file := FileAccess.open("res://assets/audio/charts.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(tracks,"\t"))
	print("Exported authoritative chart metadata for music composition")
	quit()
