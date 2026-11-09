class_name Stats extends Node
var Classes = []

enum ClassTypes {
	LIGHT,
	MEDIUM,
	HEAVY
}

class StatBlock extends Node:
	var weight: float          # mass of skater
	var speed: float           # impulse applied when skating
	var sprite_index: int      # y coordinate of sprite
	var shot_power: float      # maximum shot velocity
	var snap_power: float      # shot velocity with 0 charge
	var shot_variance: float   # cone of inaccuracy
	var check_damage: float
	var max_health: float
	var size: String
	
func _init() -> void:
	for X in ClassTypes.values():
		Classes.push_back(StatBlock.new())
	Classes[ClassTypes.LIGHT].weight = 1
	Classes[ClassTypes.LIGHT].speed = 5
	Classes[ClassTypes.LIGHT].sprite_index = 60
	Classes[ClassTypes.LIGHT].shot_power = 1.3
	Classes[ClassTypes.LIGHT].snap_power = 0.4
	Classes[ClassTypes.LIGHT].shot_variance = deg_to_rad(5)
	Classes[ClassTypes.LIGHT].check_damage = 20.0
	Classes[ClassTypes.LIGHT].max_health = 80.0
	Classes[ClassTypes.LIGHT].size = "light"
	
	Classes[ClassTypes.MEDIUM].weight = 1.5
	Classes[ClassTypes.MEDIUM].speed = 5.5
	Classes[ClassTypes.MEDIUM].sprite_index = 0
	Classes[ClassTypes.MEDIUM].shot_power = 1
	Classes[ClassTypes.MEDIUM].snap_power = 0.3
	Classes[ClassTypes.MEDIUM].shot_variance = deg_to_rad(10)
	Classes[ClassTypes.MEDIUM].check_damage = 30.0
	Classes[ClassTypes.MEDIUM].max_health = 100.0
	Classes[ClassTypes.MEDIUM].size = "medium"
	
	Classes[ClassTypes.HEAVY].weight = 2
	Classes[ClassTypes.HEAVY].speed = 6
	Classes[ClassTypes.HEAVY].sprite_index = 26
	Classes[ClassTypes.HEAVY].shot_power = 1.3
	Classes[ClassTypes.HEAVY].snap_power = 0.2
	Classes[ClassTypes.HEAVY].shot_variance = deg_to_rad(30)
	Classes[ClassTypes.HEAVY].check_damage = 45.0
	Classes[ClassTypes.HEAVY].max_health = 130.0
	Classes[ClassTypes.HEAVY].size = "heavy"


const TEAMS = [
	{
		"name": "Wide Street Wackos",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(1.0, 1.0, 1.0, 1.0),
		"body_color": Color(0.957, 0.363, 0.116, 1.0),
		"foot_color": Color(0.035, 0.035, 0.035, 1.0),
		"away_head_color": Color(0.945, 0.945, 0.945, 1.0),
		"away_body_color": Color(0.898, 0.906, 0.902, 1.0),
		"away_foot_color": Color(0.043, 0.047, 0.063, 1.0),
		"popularity": 0.89,
		"conference": "eastern",
		"division": "city",
		"logo": 1,
		"logo_style": 2
	},
	{
		"name": "Thunderbolts",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.043, 0.329, 0.776, 1.0),
		"body_color": Color(0.0, 0.098, 0.427, 1.0),
		"foot_color": Color(0.0, 0.149, 0.475, 1.0),
		"away_head_color": Color(0.957, 0.965, 0.953, 1.0),
		"away_body_color": Color(0.9, 0.9, 0.9),
		"away_foot_color": Color(0.18, 0.247, 0.4, 1.0),
		"popularity": 0.95,
		"conference": "eastern",
		"division": "coastal",
		"logo": 3,
		"logo_style": 1
	},
	{
		"name": "Flightless Birds",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.957, 0.773, 0.0, 1.0),
		"body_color": Color(0.969, 0.757, 0.055, 1.0),
		"foot_color": Color(0.2, 0.2, 0.2),
		"away_head_color": Color(0.749, 0.741, 0.788, 1.0),
		"away_body_color": Color(0.9, 0.9, 0.9),
		"away_foot_color": Color(0.153, 0.161, 0.157, 1.0),
		"popularity": 0.73,
		"conference": "eastern",
		"division": "city",
		"logo": 2,
		"logo_style": 1
	},
	{
		"name": "Candy Canes",
		"composition": [
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.027, 0.005, 0.005, 1.0),
		"body_color": Color(0.012, 0.012, 0.012, 1.0),
		"foot_color": Color(1, 0.2, 0.2),
		"away_head_color": Color(1.0, 0.102, 0.102, 1.0),
		"away_body_color": Color(1.0, 0.993, 0.95, 1.0),
		"away_foot_color": Color(1.0, 0.102, 0.102, 1.0),
		"popularity": 0.88,
		"conference": "eastern",
		"division": "city",
		"logo": 4,
		"logo_style": 1
	},
	{
		"name": "Loch Ness Monsters",
		"composition": [
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.0, 0.086, 0.157, 1.0),
		"body_color": Color(0.0, 0.086, 0.157, 1.0),
		"foot_color": Color(0.529, 0.812, 0.816, 1.0),
		"away_head_color": Color(1.0, 1.0, 1.0, 1.0),
		"away_body_color": Color(1, 1, 1),
		"away_foot_color": Color(0.0, 0.086, 0.157, 1.0),
		"popularity": 0.76,
		"conference": "western",
		"division": "ocean",
		"logo": 5,
		"logo_style": 1
	},
	{
		"name": "Shapes",
		"composition": [
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.2, 0.2, 0.2),
		"body_color": Color(.2, .6, .2),
		"foot_color": Color(0.2, 0.2, 0.2),
		"away_head_color": Color(1.0, 1.0, 1.0, 1.0),
		"away_body_color": Color(1, 1, 1),
		"away_foot_color": Color(0.149, 0.141, 0.137, 1.0),
		"popularity": 0.90,
		"conference": "western",
		"division": "middle",
		"logo": 6,
		"logo_style": 1
	},
	{
		"name": "Bears",
		"composition": [
			ClassTypes.LIGHT,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY
		],
		"head_color": Color(0.098, 0.094, 0.086, 1.0),
		"body_color": Color(0.1, 0.1, 0.1),
		"foot_color": Color(1.0, 0.765, 0.0, 1.0),
		"away_head_color": Color(1, 1, 1),
		"away_body_color": Color(1.0, 1.0, 1.0, 1.0),
		"away_foot_color": Color(0.098, 0.094, 0.086, 1.0),
		"popularity": 0.81,
		"conference": "eastern",
		"division": "coastal",
		"logo": 16,
		"logo_style": 1
	},
	{
		"name": "Long Island Ice Teas",
		"composition": [
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY
		],
		"head_color": Color(0.0, 0.0, 0.518, 1.0),
		"body_color": Color(0.0, 0.0, 0.518, 1.0),
		"foot_color": Color(0.969, 0.388, 0.094, 1.0),
		"away_head_color": Color(0.996, 0.996, 1.0, 1.0),
		"away_body_color": Color(1.0, 0.875, 1.0, 1.0),
		"away_foot_color": Color(0.0, 0.0, 0.518, 1.0),
		"popularity": 0.71,
		"conference": "eastern",
		"division": "city",
		"logo": 7,
		"logo_style": 1
	},
		{
		"name": "Haberdashers",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.0, 0.129, 0.388, 1.0),
		"body_color": Color(0.78, 0.0, 0.0, 1.0),
		"foot_color": Color(0.0, 0.129, 0.388, 1.0),
		"away_head_color": Color(1.0, 1.0, 1.0, 1.0),
		"away_body_color": Color(1, 1, 1),
		"away_foot_color": Color(0.0, 0.129, 0.388, 1.0),
		"popularity": 0.98,
		"conference": "eastern",
		"division": "coastal",
		"logo": 8,
		"logo_style": 1
	},
	{
		"name": "Rockslides",
		"composition": [
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.HEAVY
		],
		"head_color": Color(0.119, 0.388, 0.653),
		"body_color": Color(0.578, 0.121, 0.254),
		"foot_color": Color(0.119, 0.388, 0.653),
		"away_head_color": Color(0.784, 0.784, 0.784, 1.0),
		"away_body_color": Color(1.0, 0.875, 1.0, 1.0),
		"away_foot_color": Color(0.004, 0.173, 0.329, 1.0),
		"popularity": 0.86,
		"conference": "western",
		"division": "middle",
		"logo": 9,
		"logo_style": 1
	},
	{
		"name": "Queens",
		"composition": [
			ClassTypes.LIGHT,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.059, 0.059, 0.063, 1.0),
		"body_color": Color(0.1, 0.1, 0.1),
		"foot_color": Color(0.024, 0.024, 0.031, 1.0),
		"away_head_color": Color(0.878, 0.882, 0.89, 1.0),
		"away_body_color": Color(0.9, 0.9, 0.9, 1.0),
		"away_foot_color": Color(0.1, 0.1, 0.1),
		"popularity": 0.86,
		"conference": "western",
		"division": "ocean",
		"logo": 11,
		"logo_style": 1
	},
	{
		"name": "Swords",
		"composition": [
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.0, 0.188, 0.529, 1.0),
		"body_color": Color(0.0, 0.188, 0.529, 1.0),
		"foot_color": Color(1.0, 0.753, 0.086, 1.0),
		"away_head_color": Color(1.0, 1.0, 1.0, 1.0),
		"away_body_color": Color(0.996, 0.992, 0.98, 1.0),
		"away_foot_color": Color(0.0, 0.188, 0.529, 1.0),
		"popularity": 0.86,
		"conference": "eastern",
		"division": "coastal",
		"logo": 13,
		"logo_style": 1
	},
	{
		"name": "Syrups",
		"composition": [
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.HEAVY,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.031, 0.086, 0.498, 1.0),
		"body_color": Color(0.031, 0.086, 0.498, 1.0),
		"foot_color": Color(0.031, 0.086, 0.498, 1.0),
		"away_head_color": Color(1.0, 1.0, 1.0, 1.0),
		"away_body_color": Color(0.9, 0.9, 0.9, 1),
		"away_foot_color": Color(0.031, 0.086, 0.498, 1.0),
		"popularity": 0.86,
		"conference": "eastern",
		"division": "coastal",
		"logo": 12,
		"logo_style": 1
	},
	{
		"name": "Evil Wrenches",
		"composition": [
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.HEAVY,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.1, 0.1, 0.1),
		"body_color": Color(0.9, 0.3, 0.3),
		"foot_color": Color(0.02, 0.02, 0.02, 1.0),
		"away_head_color": Color(0.972, 1.0, 0.929, 1.0),
		"away_body_color": Color(1.0, 1.0, 1.0, 1.0),
		"away_foot_color": Color(0.035, 0.035, 0.035, 1.0),
		"popularity": 0.86,
		"conference": "eastern",
		"division": "city",
		"logo": 10,
		"logo_style": 1
	},
	{
		"name": "Hot Wings",
		"composition": [
			ClassTypes.LIGHT,
			ClassTypes.HEAVY,
			ClassTypes.LIGHT,
			ClassTypes.HEAVY,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.627, 0.035, 0.02, 1.0),
		"body_color": Color(0.667, 0.027, 0.02, 1.0),
		"foot_color": Color(0.557, 0.071, 0.039, 1.0),
		"away_head_color": Color(0.8, 0.816, 0.808, 1.0),
		"away_body_color": Color(0.9, 0.9, 0.9, 1),
		"away_foot_color": Color(0.702, 0.149, 0.129, 1.0),
		"popularity": 0.86,
		"conference": "eastern",
		"division": "coastal",
		"logo": 17,
		"logo_style": 1
	},
	{
		"name": "Gasoline Fights",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.125, 0.157, 0.447, 1.0),
		"body_color": Color(0.012, 0.145, 0.463, 1.0),
		"foot_color": Color(0.741, 0.322, 0.165, 1.0),
		"away_head_color": Color(0.965, 0.965, 0.965, 1.0),
		"away_body_color": Color(0.965, 0.965, 0.965, 1.0),
		"away_foot_color": Color(0.0, 0.059, 0.235, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "ocean",
		"logo": 15,
		"logo_style": 1
	},
	{
		"name": "Tire Fires",
		"composition": [
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM
		],
		"head_color": Color(0.923, 0.003, 0.086, 1.0),
		"body_color": Color(0.9, 0.067, 0.027, 1.0),
		"foot_color": Color(0.874, 0.657, 0.096, 1.0),
		"away_head_color": Color(0.9, 0.0, 0.083, 1.0),
		"away_body_color": Color(0.898, 0.886, 0.923, 1.0),
		"away_foot_color": Color(0.965, 0.755, 0.064, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "ocean",
		"logo": 14,
		"logo_style": 1
	},
	{
		"name": "Ranges",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM
		],
		"head_color": Color(0.06, 0.069, 0.923, 1.0),
		"body_color": Color(0, 0, 0.9),
		"foot_color": Color(0.874, 0.135, 0.05, 1.0),
		"away_head_color": Color(0.886, 0.9, 0.872, 1.0),
		"away_body_color": Color(0.98, 0.91, 0.904, 1.0),
		"away_foot_color": Color(0.965, 0.078, 0.0, 1.0),
		"popularity": 0.89,
		"conference": "eastern",
		"division": "city",
		"logo": 18,
		"logo_style": 1
	},
	{
		"name": "Music",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY
		],
		"head_color": Color(0.064, 0.014, 0.125, 1.0),
		"body_color": Color(0, 0, 0.9),
		"foot_color": Color(0.002, 0.0, 0.102, 1.0),
		"away_head_color": Color(0.825, 0.839, 0.9, 1.0),
		"away_body_color": Color(0.923, 0.879, 0.886, 1.0),
		"away_foot_color": Color(0.016, 0.011, 0.059, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "middle",
		"logo": 19,
		"logo_style": 1
	},
	{
		"name": "Congressmen",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM
		],
		"head_color": Color(0.031, 0.03, 0.031, 1.0),
		"body_color": Color(0.022, 0.023, 0.023, 1.0),
		"foot_color": Color(0.078, 0.078, 0.078, 1.0),
		"away_head_color": Color(0.9, 0.875, 0.898, 1.0),
		"away_body_color": Color(0.923, 0.92, 0.913, 1.0),
		"away_foot_color": Color(0.02, 0.02, 0.02, 1.0),
		"popularity": 0.89,
		"conference": "eastern",
		"division": "coastal",
		"logo": 20,
		"logo_style": 1
	},
	{
		"name": "Planes",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY
		],
		"head_color": Color(0.027, 0.028, 0.313, 1.0),
		"body_color": Color(0.0, 0.0, 0.273, 1.0),
		"foot_color": Color(0.029, 0.034, 0.223, 1.0),
		"away_head_color": Color(0.896, 0.893, 0.9, 1.0),
		"away_body_color": Color(0.916, 0.923, 0.909, 1.0),
		"away_foot_color": Color(0.04, 0.036, 0.313, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "middle",
		"logo": 21,
		"logo_style": 1
	},
	{
		"name": "Hammerheads",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.19, 0.367, 0.326, 1.0),
		"body_color": Color(0.19, 0.367, 0.326, 1.0),
		"foot_color": Color(0.19, 0.367, 0.326, 1.0),
		"away_head_color": Color(0.19, 0.367, 0.326, 1.0),
		"away_body_color": Color(0.894, 0.879, 0.923, 1.0),
		"away_foot_color": Color(0.19, 0.367, 0.326, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "ocean",
		"logo": 22,
		"logo_style": 1
	},
	{
		"name": "Hosers",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM
		],
		"head_color": Color(0.004, 0.184, 0.424, 1.0),
		"body_color": Color(0.004, 0.184, 0.424, 1.0),
		"foot_color": Color(0.004, 0.184, 0.424, 1.0),
		"away_head_color": Color(0.867, 0.862, 0.9, 1.0),
		"away_body_color": Color(0.892, 0.9, 0.923, 1.0),
		"away_foot_color": Color(0.004, 0.184, 0.424, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "ocean",
		"logo": 23,
		"logo_style": 1
	},
	{
		"name": "Mighty Movie Tie-Ins",
		"composition": [
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.923, 0.477, 0.139, 1.0),
		"body_color": Color(0.923, 0.477, 0.139, 1.0),
		"foot_color": Color(0.923, 0.477, 0.139, 1.0),
		"away_head_color": Color(0.923, 0.477, 0.139, 1.0),
		"away_body_color": Color(0.914, 0.877, 0.923, 1.0),
		"away_foot_color": Color(0.923, 0.477, 0.139, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "ocean",
		"logo": 24,
		"logo_style": 1
	},
	{
		"name": "Elephants",
		"composition": [
			ClassTypes.LIGHT,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.759, 0.819, 0.973, 1.0),
		"body_color": Color(0.153, 0.165, 0.196, 1.0),
		"foot_color": Color(0.153, 0.165, 0.196, 1.0),
		"away_head_color": Color(0.759, 0.819, 0.973, 1.0),
		"away_body_color": Color(0.759, 0.819, 0.973, 1.0),
		"away_foot_color": Color(0.153, 0.165, 0.196, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "middle",
		"logo": 25,
		"logo_style": 1
	},
	{
		"name": "Silver Squires",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY
		],
		"head_color": Color(0.188, 0.235, 0.227, 1.0),
		"body_color": Color(0.188, 0.235, 0.227, 1.0),
		"foot_color": Color(0.0, 0.0, 0.0, 1.0),
		"away_head_color": Color(0.989, 0.992, 1.0, 1.0),
		"away_body_color": Color(0.999, 0.983, 1.0, 1.0),
		"away_foot_color": Color(0.0, 0.0, 0.0, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "ocean",
		"logo": 26,
		"logo_style": 1
	},
	{
		"name": "Apache Choppers",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.016, 0.0, 0.0, 1.0),
		"body_color": Color(0.8, 0.0, 0.02, 1.0),
		"foot_color": Color(0.0, 0.0, 0.0, 1.0),
		"away_head_color": Color(0.989, 0.916, 1.0, 1.0),
		"away_body_color": Color(0.957, 0.929, 1.0, 1.0),
		"away_foot_color": Color(0.0, 0.0, 0.0, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "middle",
		"logo": 27,
		"logo_style": 1
	},
	{
		"name": "Blue Belts",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.0, 0.055, 0.184, 1.0),
		"body_color": Color(0.004, 0.078, 0.259, 1.0),
		"foot_color": Color(0.698, 0.059, 0.0, 1.0),
		"away_head_color": Color(1.0, 1.0, 1.0, 1.0),
		"away_body_color": Color(0.996, 0.996, 1.0, 1.0),
		"away_foot_color": Color(0.004, 0.078, 0.259, 1.0),
		"popularity": 0.89,
		"conference": "eastern",
		"division": "city",
		"logo": 28,
		"logo_style": 1
	},
	{
		"name": "Prey",
		"composition": [
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM
		],
		"head_color": Color(0.949, 0.663, 0.0, 1.0),
		"body_color": Color(0.949, 0.663, 0.0, 1.0),
		"foot_color": Color(0.0, 0.027, 0.059, 1.0),
		"away_head_color": Color(0.969, 0.969, 0.969, 1.0),
		"away_body_color": Color(0.969, 0.969, 0.969, 1.0),
		"away_foot_color": Color(0.0, 0.098, 0.212, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "middle",
		"logo": 29,
		"logo_style": 1
	},
	{
		"name": "Block Busters",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.0, 0.039, 0.082, 1.0),
		"body_color": Color(0.725, 0.0, 0.059, 1.0),
		"foot_color": Color(0.0, 0.094, 0.212, 1.0),
		"away_head_color": Color(0.969, 0.969, 0.969, 1.0),
		"away_body_color": Color(0.969, 0.969, 0.969, 1.0),
		"away_foot_color": Color(0.0, 0.094, 0.212, 1.0),
		"popularity": 0.89,
		"conference": "eastern",
		"division": "coastal",
		"logo": 30,
		"logo_style": 1
	},
	{
		"name": "Freeze",
		"composition": [
			ClassTypes.MEDIUM,
			ClassTypes.MEDIUM,
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.008, 0.286, 0.188, 1.0),
		"body_color": Color(0.008, 0.278, 0.192, 1.0),
		"foot_color": Color(0.008, 0.278, 0.192, 1.0),
		"away_head_color": Color(1.0, 1.0, 1.0, 1.0),
		"away_body_color": Color(1.0, 1.0, 1.0, 1.0),
		"away_foot_color": Color(0.071, 0.278, 0.204, 1.0),
		"popularity": 0.89,
		"conference": "western",
		"division": "middle",
		"logo": 31,
		"logo_style": 1
	},
	{
		"name": "Lowercases",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT,
			ClassTypes.MEDIUM,
			ClassTypes.LIGHT
		],
		"head_color": Color(0.62, 0.114, 0.11, 1.0),
		"body_color": Color(0.612, 0.051, 0.059, 1.0),
		"foot_color": Color(0.149, 0.192, 0.286, 1.0),
		"away_head_color": Color(0.894, 0.91, 0.945, 1.0),
		"away_body_color": Color(0.788, 0.788, 0.894, 1.0),
		"away_foot_color": Color(0.094, 0.18, 0.373, 1.0),
		"popularity": 0.89,
		"conference": "eastern",
		"division": "city",
		"logo": 32,
		"logo_style": 1
	},
	{
		"name": "Pinkertons",
		"composition": [
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY,
			ClassTypes.HEAVY
		],
		"head_color": Color(1, 0.5, 0.6),
		"body_color": Color(1, 0.6, 1),
		"foot_color": Color(1, 0.5, 0.6),
		"away_head_color": Color(1, 0.5, 0.6),
		"away_body_color": Color(0.961, 0.961, 0.965, 1.0),
		"away_foot_color": Color(1, 0.5, 0.6),
		"popularity": 0.50,
		"conference": "n/a",
		"division": "n/a",
		"logo": 1,
		"logo_style": 1
	},
]
