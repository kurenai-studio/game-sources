extends SceneTree
const RaceEngine = preload("res://core/race_engine.gd")

func _initialize() -> void:
	var race := RaceEngine.new(20261020)
	print(JSON.stringify(race.run(),"  "))
	quit(0)
