class_name WeatherSystem
extends RefCounted
## Ends a weather spell when its time is up and starts whatever follows it. Weather is started by
## events (SET_WEATHER); a spell never changes anything but what the group brings in
## (Simulation.food_multiplier) and never waits on the player.


func step(sim: Simulation) -> void:
	var world: WorldState = sim.world
	if world.weather == &"" or world.tick < world.weather_until_tick:
		return
	var def: WeatherDef = sim.content.get_weather(world.weather)
	if def != null and def.then != &"":
		sim.set_weather(def.then)
	else:
		sim.clear_weather()
