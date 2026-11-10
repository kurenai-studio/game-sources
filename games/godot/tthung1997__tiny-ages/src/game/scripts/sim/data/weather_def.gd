class_name WeatherDef
extends Resource
## A kind of weather: how long a spell lasts and what it does to the group's work while it lasts.
## It never hurts anyone; it only slows what the villagers bring in. Started by an event's
## SET_WEATHER effect, ended by WeatherSystem.

@export var id: StringName = &""
@export var display_name: String = ""
## Shortest and longest spell, in game days. A spell draws its length from the simulation's rng.
@export_range(0.1, 60.0, 0.1) var min_days: float = 1.0
@export_range(0.1, 60.0, 0.1) var max_days: float = 3.0
## Multiplies what foraging, hunting and food-making buildings bring in while it lasts.
@export_range(0.0, 2.0, 0.05) var food_multiplier: float = 1.0
## The same for cutting wood and wood-making buildings.
@export_range(0.0, 2.0, 0.05) var wood_multiplier: float = 1.0
## The weather that follows when this spell ends (a tornado leaves debris), or &"" for clear sky.
@export var then: StringName = &""
## Which art the view draws; empty means the id.
@export var look: StringName = &""


func look_id() -> StringName:
	return look if look != &"" else id
