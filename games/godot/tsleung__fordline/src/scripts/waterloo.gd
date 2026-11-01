class_name Waterloo
extends RefCounted
## Waterloo, 18 June 1815, as a grand battle. Pure data: the ground, who
## starts where and when each French corps goes in, and when the Prussians
## come.
##
## The field is drawn with the French to the north (the top) and Wellington's
## ridge to the south, so each army's rear is its own map edge. About 4.3 km
## across at 750 units to the km. The day runs from 11:00 to dusk at 21:00
## in 900 seconds, so an hour is 90 seconds.

const K := UnitTypes.Kind
const HOUR := 90.0
const UP := -PI * 0.5
## Raw troops, a star below the line: the Dutch-Belgians, the Nassauers and
## the Hanoverian militia, in their first battle.
const RAW := -1
const DOWN := PI * 0.5

## Flags, by index.
const HOUGOUMONT := 0
const LA_HAYE_SAINTE := 1
const PAPELOTTE := 2
const MONT_SAINT_JEAN := 3
const LA_BELLE_ALLIANCE := 4
const PLANCENOIT := 5

const FLAGS := [
	{"name": "Hougoumont", "at": Vector2(985, 960)},
	{"name": "La Haye Sainte", "at": Vector2(1665, 1185)},
	{"name": "Papelotte", "at": Vector2(2455, 1150)},
	{"name": "Mont-Saint-Jean", "at": Vector2(1600, 1360)},
	{"name": "La Belle Alliance", "at": Vector2(1650, 560)},
	{"name": "Plancenoit", "at": Vector2(2510, 530)},
]

const PLAN := {
	"id": "waterloo",
	"size": Vector2(3200, 2200),
	"ridges": [
		{"line": [Vector2(700, 520), Vector2(1650, 560), Vector2(2600, 500)], "r": 150.0},
		{"line": [Vector2(450, 1390), Vector2(1600, 1360), Vector2(2750, 1300)], "r": 170.0},
	],
	"hills": [
		{"c": Vector2(1780, 860), "r": 120.0},
	],
	"forests": [
		{"c": Vector2(975, 830), "r": 115.0},
		{"c": Vector2(2930, 700), "r": 170.0},
		{"c": Vector2(2800, 1010), "r": 110.0},
		{"c": Vector2(300, 1700), "r": 150.0},
	],
	"towns": [
		[Vector2(920, 915), Vector2(1050, 915), Vector2(1050, 1010), Vector2(920, 1010)],
		[Vector2(1630, 1150), Vector2(1705, 1150), Vector2(1705, 1218), Vector2(1630, 1218)],
		[Vector2(2400, 1110), Vector2(2510, 1110), Vector2(2510, 1190), Vector2(2400, 1190)],
		[Vector2(2420, 460), Vector2(2600, 460), Vector2(2600, 600), Vector2(2420, 600)],
		[Vector2(1540, 1440), Vector2(1680, 1440), Vector2(1680, 1520), Vector2(1540, 1520)],
	],
	"streams": [
		[Vector2(2300, 1240), Vector2(2700, 1120), Vector2(3210, 1060)],
		[Vector2(2700, -10), Vector2(2660, 420), Vector2(2720, 760), Vector2(2690, 1100)],
	],
	"roads": [
		[Vector2(1650, -10), Vector2(1650, 560), Vector2(1620, 1180), Vector2(1600, 2210)],
		[Vector2(1600, 1450), Vector2(900, 890), Vector2(300, -10)],
		[Vector2(300, 1370), Vector2(1600, 1355), Vector2(2900, 1320)],
		[Vector2(1650, 560), Vector2(2510, 530), Vector2(3210, 620)],
		[Vector2(2455, 1150), Vector2(3210, 1180)],
	],
	"flags": FLAGS,
}

## Who holds the field at 11:00: each force's side, name, objectives, and
## the hour its orders start, with its blocks as [kind, name, where, facing,
## extra stars].
const START := [
	{"team": 0, "formation": "Wellington", "objectives": [MONT_SAINT_JEAN], "units": [
		[K.GENERAL, "Wellington", Vector2(1450, 1440), UP],
	]},
	{"team": 0, "formation": "Cooke's Guards", "objectives": [HOUGOUMONT], "units": [
		[K.LINE, "Byng's Guards", Vector2(985, 965), UP],
		[K.LINE, "Maitland's Guards", Vector2(1160, 1360), UP],
	]},
	{"team": 0, "formation": "Alten's Division", "objectives": [MONT_SAINT_JEAN], "units": [
		[K.LINE, "Halkett's Brigade", Vector2(1320, 1355), UP],
		[K.LINE, "Kielmansegge's Brigade", Vector2(1450, 1350), UP],
		[K.LINE, "Ompteda's Brigade", Vector2(1560, 1350), UP],
	]},
	{"team": 0, "formation": "Baring's Germans", "objectives": [LA_HAYE_SAINTE], "units": [
		[K.LINE, "the King's German Legion", Vector2(1665, 1190), UP],
	]},
	{"team": 0, "formation": "Picton's Division", "objectives": [MONT_SAINT_JEAN], "units": [
		[K.LINE, "Kempt's Brigade", Vector2(1780, 1345), UP],
		[K.LINE, "Pack's Brigade", Vector2(1960, 1340), UP],
		[K.LINE, "Vincke's Hanoverians", Vector2(2140, 1335), UP, RAW],
		[K.LINE, "Best's Hanoverians", Vector2(2300, 1330), UP, RAW],
	]},
	{"team": 0, "formation": "Perponcher's Division", "objectives": [PAPELOTTE], "units": [
		[K.LINE, "Bijlandt's Brigade", Vector2(1880, 1270), UP, RAW],
		[K.LINE, "Saxe-Weimar's Nassauers", Vector2(2455, 1155), UP, RAW],
	]},
	{"team": 0, "formation": "Clinton's Division", "objectives": [MONT_SAINT_JEAN], "units": [
		[K.LINE, "Adam's Brigade", Vector2(1200, 1520), UP],
		[K.LINE, "du Plat's Brigade", Vector2(1050, 1520), UP],
	]},
	{"team": 0, "formation": "Uxbridge's Cavalry", "objectives": [MONT_SAINT_JEAN], "units": [
		[K.CAVALRY, "the Household Brigade", Vector2(1480, 1540), UP],
		[K.CAVALRY, "the Union Brigade", Vector2(1860, 1530), UP],
		[K.CAVALRY, "Vandeleur's Brigade", Vector2(2300, 1460), UP],
		[K.CAVALRY, "Vivian's Brigade", Vector2(2480, 1440), UP],
	]},
	{"team": 0, "formation": "the Royal Artillery", "objectives": [MONT_SAINT_JEAN], "units": [
		[K.CANNONS, "Bull's Battery", Vector2(1250, 1320), UP],
		[K.CANNONS, "Ross's Battery", Vector2(1640, 1315), UP],
		[K.CANNONS, "Rogers's Battery", Vector2(1900, 1310), UP],
	]},
	{"team": 1, "formation": "Napoleon", "objectives": [LA_BELLE_ALLIANCE], "units": [
		[K.GENERAL, "Napoleon", Vector2(1650, 470), DOWN],
	]},
	{"team": 1, "formation": "Jérôme's Division", "objectives": [HOUGOUMONT], "from_hour": 11.5, "units": [
		[K.LINE, "Bauduin's Brigade", Vector2(900, 690), DOWN],
		[K.LINE, "Soye's Brigade", Vector2(1040, 690), DOWN],
	]},
	{"team": 1, "formation": "Foy's Division", "objectives": [HOUGOUMONT, MONT_SAINT_JEAN], "from_hour": 12.5, "units": [
		[K.LINE, "Gauthier's Brigade", Vector2(1180, 680), DOWN],
		[K.LINE, "Jamin's Brigade", Vector2(1310, 680), DOWN],
	]},
	{"team": 1, "formation": "d'Erlon's Corps", "objectives": [LA_HAYE_SAINTE, MONT_SAINT_JEAN], "from_hour": 13.5, "units": [
		[K.LINE, "Charlet's Brigade", Vector2(1530, 700), DOWN],
		[K.LINE, "Bourgeois's Brigade", Vector2(1530, 610), DOWN],
		[K.LINE, "Schmitz's Brigade", Vector2(1690, 700), DOWN],
		[K.LINE, "Aulard's Brigade", Vector2(1690, 610), DOWN],
		[K.LINE, "Nogues's Brigade", Vector2(1850, 700), DOWN],
		[K.LINE, "Grenier's Brigade", Vector2(1850, 610), DOWN],
		[K.LINE, "Pégot's Brigade", Vector2(2010, 700), DOWN],
		[K.LINE, "Brue's Brigade", Vector2(2010, 610), DOWN],
	]},
	{"team": 1, "formation": "the Grand Battery", "objectives": [MONT_SAINT_JEAN], "from_hour": 12.5, "units": [
		[K.CANNONS, "the Guard's twelve-pounders", Vector2(1480, 820), DOWN],
		[K.CANNONS, "d'Erlon's guns", Vector2(1620, 830), DOWN],
		[K.CANNONS, "Reille's guns", Vector2(1760, 830), DOWN],
		[K.CANNONS, "Lobau's guns", Vector2(1900, 830), DOWN],
		[K.CANNONS, "the Guard horse guns", Vector2(2040, 830), DOWN],
	]},
	{"team": 1, "formation": "Milhaud's Cuirassiers", "objectives": [MONT_SAINT_JEAN], "from_hour": 16.0, "units": [
		[K.CAVALRY, "Wathier's Cuirassiers", Vector2(1350, 520), DOWN],
		[K.CAVALRY, "Delort's Cuirassiers", Vector2(1480, 520), DOWN],
		[K.CAVALRY, "the Guard Lancers", Vector2(1220, 500), DOWN],
	]},
	{"team": 1, "formation": "Kellermann's Cuirassiers", "objectives": [MONT_SAINT_JEAN], "from_hour": 17.0, "units": [
		[K.CAVALRY, "L'Héritier's Cuirassiers", Vector2(1080, 480), DOWN],
		[K.CAVALRY, "Roussel's Cuirassiers", Vector2(950, 480), DOWN],
	]},
	{"team": 1, "formation": "Bachelu's Division", "objectives": [MONT_SAINT_JEAN], "from_hour": 17.0, "units": [
		[K.LINE, "Husson's Brigade", Vector2(1260, 600), DOWN],
		[K.LINE, "Campi's Brigade", Vector2(1390, 600), DOWN],
	]},
	{"team": 1, "formation": "Lobau's Corps", "objectives": [PLANCENOIT], "from_hour": 16.0, "units": [
		[K.LINE, "Simmer's Division", Vector2(2050, 470), DOWN],
		[K.LINE, "Jeanin's Division", Vector2(2180, 470), DOWN],
	]},
	{"team": 1, "formation": "the Imperial Guard", "objectives": [MONT_SAINT_JEAN], "from_hour": 19.5, "units": [
		[K.LINE, "the Grenadiers of the Middle Guard", Vector2(1540, 400), DOWN, 2],
		[K.LINE, "the Chasseurs of the Middle Guard", Vector2(1670, 400), DOWN, 2],
		[K.LINE, "the Old Guard", Vector2(1800, 400), DOWN, 2],
	]},
	{"team": 1, "formation": "the Young Guard", "objectives": [PLANCENOIT], "from_hour": 18.0, "units": [
		[K.LINE, "Duhesme's Young Guard", Vector2(1900, 420), DOWN, 1],
	]},
]

## The Prussians, along the lanes from Wavre.
const PARIS_WOOD := [Vector2(3195, 620), Vector2(2960, 650)]
const SMOHAIN := [Vector2(3195, 1180), Vector2(2780, 1220)]

const ARRIVALS := [
	{
		"hour": 16.5, "team": 0, "formation": "Bülow's Corps", "road": PARIS_WOOD, "face": PI,
		"from": "out of the Paris Wood", "objectives": [PLANCENOIT, LA_BELLE_ALLIANCE],
		"units": [[K.LINE, "Losthin's Brigade"], [K.LINE, "Hiller's Brigade"], [K.LINE, "Hacke's Brigade"], [K.CAVALRY, "Prince William's Cavalry"], [K.CANNONS, "Bülow's Guns"]],
	},
	{
		"hour": 18.0, "team": 0, "formation": "Pirch's Corps", "road": PARIS_WOOD, "face": PI,
		"from": "out of the Paris Wood", "objectives": [PLANCENOIT, LA_BELLE_ALLIANCE],
		"units": [[K.LINE, "Tippelskirch's Brigade"], [K.LINE, "Krafft's Brigade"]],
	},
	{
		"hour": 19.0, "team": 0, "formation": "Zieten's Corps", "road": SMOHAIN, "face": PI,
		"from": "by Smohain", "objectives": [PAPELOTTE, LA_HAYE_SAINTE],
		"units": [[K.LINE, "Steinmetz's Brigade"], [K.LINE, "Jagow's Brigade"], [K.CAVALRY, "Röder's Cavalry"]],
	},
]

const SPEC := {
	"id": "waterloo", "era": "napoleonic", "mode": "grand", "name": "Waterloo",
	"brief": "18 June 1815. Wellington's army holds the ridge of Mont-Saint-Jean, with Hougoumont and La Haye Sainte out in front. Napoleon attacks all afternoon. The Prussians are on the march from Wavre. Hold the ridge until they come, and until night.",
	"plan": PLAN, "persona": "aggressive", "abilities": ["rally"],
	"view": Vector2(1600, 1100),
	"start_hour": 11.0, "hour": HOUR, "deadline": HOUR * 10.0, "deadline_flags": [MONT_SAINT_JEAN],
	"own_flags": [HOUGOUMONT, LA_HAYE_SAINTE, PAPELOTTE, MONT_SAINT_JEAN],
	"their_flags": [LA_BELLE_ALLIANCE, PLANCENOIT],
	"flag_drain": 0.0, "rout_scale": 0.5, "pace": 0.4,
	## The Armée du Nord's veterans and its élan: two stars; the Guard more.
	"veterancy": [0, 2],
	"start": START, "arrivals": ARRIVALS,
	"goal": "Hold Mont-Saint-Jean at dusk (21:00), or break their army.",
	"stars": [{"hold": LA_HAYE_SAINTE, "noun": "La Haye Sainte"}, {"hold": PLANCENOIT, "noun": "Plancenoit", "verb": "Have taken"}],
}
