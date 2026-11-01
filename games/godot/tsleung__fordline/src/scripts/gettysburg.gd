class_name Gettysburg
extends RefCounted
## The first day at Gettysburg, 1 July 1863, as a grand battle. Pure data:
## the ground, who starts where, and who comes up which road when.
##
## North is up; the field is about 5.7 km across at 560 units to the km,
## with the town's square (the Diamond) at (1950, 1050). The day runs from
## 8:00 to dusk at 19:30 in 900 seconds, so an hour is 78 seconds.

const K := UnitTypes.Kind
const HOUR := 78.0

## Flags, by index: what each division fights for.
const MCPHERSON := 0
const SEMINARY := 1
const OAK_HILL := 2
const BARLOW := 3
const TOWN := 4
const CEMETERY := 5

const FLAGS := [
	{"name": "McPherson Ridge", "at": Vector2(1300, 1000)},
	{"name": "Seminary Ridge", "at": Vector2(1610, 1080)},
	{"name": "Oak Hill", "at": Vector2(1474, 330)},
	{"name": "Barlow's Knoll", "at": Vector2(2146, 370)},
	{"name": "Gettysburg", "at": Vector2(1960, 1040)},
	{"name": "Cemetery Hill", "at": Vector2(2060, 1500)},
]

const PLAN := {
	"id": "gettysburg",
	"size": Vector2(3200, 2200),
	"ridges": [
		{"line": [Vector2(640, 420), Vector2(690, 1000), Vector2(660, 1560)], "r": 150.0},
		{"line": [Vector2(1300, 620), Vector2(1305, 1000), Vector2(1285, 1380)], "r": 120.0},
		{"line": [Vector2(1500, 260), Vector2(1620, 560), Vector2(1615, 1080), Vector2(1600, 1700), Vector2(1620, 2150)], "r": 130.0},
		{"line": [Vector2(2060, 1500), Vector2(2030, 1800), Vector2(2000, 2160)], "r": 130.0},
	],
	"hills": [
		{"c": Vector2(1474, 330), "r": 190.0},
		{"c": Vector2(2146, 370), "r": 120.0},
		{"c": Vector2(2060, 1500), "r": 190.0},
		{"c": Vector2(2410, 1670), "r": 180.0},
	],
	"forests": [
		{"c": Vector2(1255, 1110), "r": 85.0},
		{"c": Vector2(1580, 1330), "r": 75.0},
		{"c": Vector2(1570, 1640), "r": 105.0},
		{"c": Vector2(2420, 1700), "r": 140.0},
		{"c": Vector2(2560, 1520), "r": 90.0},
		{"c": Vector2(470, 1240), "r": 120.0},
		{"c": Vector2(1390, 210), "r": 70.0},
	],
	"towns": [
		[Vector2(1730, 790), Vector2(1960, 760), Vector2(2170, 800), Vector2(2210, 1050), Vector2(2190, 1260), Vector2(1960, 1300), Vector2(1760, 1270), Vector2(1710, 1040)],
	],
	"streams": [
		[Vector2(1170, -10), Vector2(1150, 400), Vector2(1135, 800), Vector2(1150, 1200), Vector2(1110, 1700), Vector2(1080, 2210)],
		[Vector2(2290, -10), Vector2(2340, 400), Vector2(2420, 800), Vector2(2470, 1250), Vector2(2520, 1700), Vector2(2560, 2210)],
	],
	"roads": [
		[Vector2(-10, 880), Vector2(660, 950), Vector2(1300, 975), Vector2(1950, 1050)],
		[Vector2(1950, 1050), Vector2(1700, 720), Vector2(1310, 300), Vector2(1100, -10)],
		[Vector2(1950, 1050), Vector2(1960, 500), Vector2(1950, -10)],
		[Vector2(1950, 1050), Vector2(2150, 720), Vector2(2600, 300), Vector2(3000, -10)],
		[Vector2(1950, 1050), Vector2(2600, 980), Vector2(3210, 950)],
		[Vector2(1950, 1050), Vector2(2120, 1480), Vector2(2650, 1950), Vector2(2900, 2210)],
		[Vector2(2010, 1280), Vector2(2080, 1700), Vector2(2150, 2210)],
		[Vector2(1900, 1220), Vector2(1620, 1720), Vector2(1300, 2210)],
		[Vector2(1950, 1050), Vector2(1300, 1320), Vector2(-10, 1720)],
	],
	"flags": FLAGS,
}

## Who holds the field at 8:00: each force's side, name and objectives,
## and its blocks as [kind, name, where, facing].
const START := [
	{
		"team": 0, "formation": "Buford's Cavalry", "objectives": [MCPHERSON],
		"units": [
			[K.GENERAL, "Reynolds", Vector2(1640, 1060), PI],
			[K.RIFLES, "Gamble's Brigade", Vector2(1310, 1080), PI],
			[K.RIFLES, "Devin's Brigade", Vector2(1330, 800), PI],
			[K.CANNONS, "Calef's Battery", Vector2(1330, 960), PI],
		],
	},
	{
		"team": 1, "formation": "Heth's Division", "objectives": [MCPHERSON, SEMINARY, CEMETERY],
		"units": [
			[K.GENERAL, "A. P. Hill", Vector2(420, 960), 0.0],
			[K.RIFLES, "Archer's Brigade", Vector2(700, 1070), 0.0],
			[K.RIFLES, "Davis's Brigade", Vector2(700, 860), 0.0],
			[K.CANNONS, "Pegram's Battalion", Vector2(660, 960), 0.0],
		],
	},
]

## The roads in, each from the map edge to where its column musters.
const EMMITSBURG_ROAD := [Vector2(1300, 2195), Vector2(1620, 1720), Vector2(1560, 1180)]
const SEMINARY_SOUTH := [Vector2(1300, 2195), Vector2(1620, 1720), Vector2(1660, 1120)]
const MUMMASBURG_LANE := [Vector2(1300, 2195), Vector2(1620, 1720), Vector2(1700, 760)]
const TANEYTOWN_ROAD := [Vector2(2150, 2195), Vector2(2080, 1700), Vector2(1990, 1250), Vector2(2010, 620)]
const CEMETERY_HILL := [Vector2(2150, 2195), Vector2(2080, 1700), Vector2(2060, 1470)]
const CHAMBERSBURG_PIKE := [Vector2(5, 880), Vector2(660, 960)]
const MIDDLETOWN_ROAD := [Vector2(1200, 5), Vector2(1440, 310)]
const HARRISBURG_ROAD := [Vector2(3000, 5), Vector2(2600, 300), Vector2(2380, 420)]

const ARRIVALS := [
	{
		"hour": 10.0, "team": 0, "formation": "Wadsworth's Division", "road": EMMITSBURG_ROAD, "face": PI,
		"from": "up the Emmitsburg Road", "objectives": [MCPHERSON],
		"units": [[K.RIFLES, "Cutler's Brigade"], [K.RIFLES, "the Iron Brigade"], [K.CANNONS, "Hall's Battery"]],
	},
	{
		"hour": 10.0, "team": 1, "formation": "Heth's Division", "road": CHAMBERSBURG_PIKE, "face": 0.0,
		"from": "down the Chambersburg Pike", "objectives": [MCPHERSON, SEMINARY, CEMETERY],
		"units": [[K.RIFLES, "Pettigrew's Brigade"], [K.RIFLES, "Brockenbrough's Brigade"]],
	},
	{
		"hour": 11.5, "team": 0, "formation": "Rowley's Division", "road": SEMINARY_SOUTH, "face": PI,
		"from": "up the Emmitsburg Road", "objectives": [SEMINARY],
		"units": [[K.RIFLES, "Biddle's Brigade"], [K.RIFLES, "Stone's Brigade"], [K.CANNONS, "Cooper's Battery"]],
	},
	{
		"hour": 12.0, "team": 0, "formation": "Robinson's Division", "road": MUMMASBURG_LANE, "face": -PI * 0.75,
		"from": "up the Emmitsburg Road", "objectives": [SEMINARY],
		"units": [[K.RIFLES, "Paul's Brigade"], [K.RIFLES, "Baxter's Brigade"]],
	},
	{
		"hour": 12.5, "team": 0, "formation": "Schurz's Division", "road": TANEYTOWN_ROAD, "face": -PI * 0.5,
		"from": "up the Taneytown Road", "objectives": [TOWN],
		"units": [[K.RIFLES, "von Amsberg's Brigade"], [K.RIFLES, "Krzyzanowski's Brigade"]],
	},
	{
		"hour": 12.75, "team": 0, "formation": "Barlow's Division", "road": TANEYTOWN_ROAD, "face": -PI * 0.5,
		"from": "up the Taneytown Road", "objectives": [BARLOW],
		"units": [[K.RIFLES, "von Gilsa's Brigade"], [K.RIFLES, "Ames's Brigade"], [K.CANNONS, "Wilkeson's Battery"]],
	},
	{
		"hour": 13.0, "team": 0, "formation": "von Steinwehr's Division", "road": CEMETERY_HILL, "face": -PI * 0.5,
		"from": "up the Taneytown Road", "objectives": [CEMETERY],
		"units": [[K.RIFLES, "Coster's Brigade"], [K.RIFLES, "Smith's Brigade"], [K.CANNONS, "Wiedrich's Battery"]],
	},
	{
		"hour": 12.5, "team": 1, "formation": "Rodes's Division", "road": MIDDLETOWN_ROAD, "face": PI * 0.5,
		"from": "onto Oak Hill", "objectives": [OAK_HILL, SEMINARY, TOWN, CEMETERY],
		"units": [[K.RIFLES, "O'Neal's Brigade"], [K.RIFLES, "Iverson's Brigade"], [K.RIFLES, "Daniel's Brigade"], [K.RIFLES, "Doles's Brigade"], [K.RIFLES, "Ramseur's Brigade"], [K.CANNONS, "Carter's Battalion"]],
	},
	{
		"hour": 11.5, "team": 1, "formation": "Pender's Division", "road": CHAMBERSBURG_PIKE, "face": 0.0,
		"from": "down the Chambersburg Pike", "objectives": [MCPHERSON, SEMINARY, CEMETERY],
		"units": [[K.RIFLES, "Perrin's Brigade"], [K.RIFLES, "Lane's Brigade"], [K.RIFLES, "Scales's Brigade"], [K.RIFLES, "Thomas's Brigade"]],
	},
	{
		"hour": 14.5, "team": 1, "formation": "Early's Division", "road": HARRISBURG_ROAD, "face": PI * 0.75,
		"from": "down the Harrisburg Road", "objectives": [BARLOW, TOWN, CEMETERY],
		"units": [[K.RIFLES, "Gordon's Brigade"], [K.RIFLES, "Hays's Brigade"], [K.RIFLES, "Avery's Brigade"], [K.RIFLES, "Smith's Brigade"], [K.CANNONS, "Jones's Battalion"]],
	},
]


const SPEC := {
	"id": "gettysburg", "era": "rifles", "mode": "grand", "name": "Gettysburg, the First Day",
	"brief": "1 July 1863. Buford's troopers hold the ridges west of town against Heth's division. Your two corps are on the roads from the south; theirs are coming from the west and the north. Hold Cemetery Hill when night falls.",
	"plan": PLAN, "persona": "aggressive", "abilities": ["rally"],
	## Where the camera opens: the ridges west of town, where it begins.
	"view": Vector2(1150, 1000),
	"start_hour": 8.0, "hour": HOUR, "deadline": HOUR * 11.5, "deadline_flags": [CEMETERY],
	"own_flags": [MCPHERSON], "flag_drain": 0.0, "rout_scale": 0.5, "pace": 0.4,
	## The Army of Northern Virginia in the summer of 1863: larger brigades,
	## and the confidence of Chancellorsville. One star each.
	"veterancy": [0, 1],
	"start": START, "arrivals": ARRIVALS,
	"goal": "Hold Cemetery Hill at dusk (19:30), or break their army.",
	"stars": [{"hold": SEMINARY, "noun": "Seminary Ridge"}, {"losses": 0.45}],
}
