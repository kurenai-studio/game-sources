class_name ArsenalArt
extends RefCounted
## The arsenal's weapons as he holds them, each at three drawn angles with where it's gripped
## and where it fires or points. Each was described once, facing east, and drawn turned at the
## others, its lines redrawn at every angle rather than its pixels rotated.

const WEAPONS := {
	"nunchaku": {
		"east": {"art": """
.kkkkk.....kkkkk.
kbbBBbkhhhkbBBbbk
.kkkkk.....kkkkk.
""", "grip": Vector2(2, 1), "muzzle": Vector2(15, 1)},
		"northeast": {"art": """
.........kk.
........kBbk
.......kBbk.
......kbbk..
.....kh.....
....h.......
...h........
..kk........
.kBbk.......
kBbk........
kbk.........
.k..........
""", "grip": Vector2(1, 9), "muzzle": Vector2(10, 1)},
		"north": {"art": """
.k.
kBk
kBk
kbk
kbk
.h.
.h.
.h.
.k.
kBk
kBk
kbk
kbk
.k.
""", "grip": Vector2(1, 11), "muzzle": Vector2(1, 1)},
	},
	"machete": {
		"east": {"art": """
....kkkkkkkk..
.kkkssssssssk.
kbbbSSSSSSSSsk
.kkkkkkkkkkkk.
""", "grip": Vector2(2, 2), "muzzle": Vector2(12, 2)},
		"northeast": {"art": """
.......kk.
......kssk
.....ksSSk
....ksSSk.
...ksSSk..
..ksSSk...
.ksSSk....
.kbSk.....
kbbk......
kbk.......
.k........
""", "grip": Vector2(1, 8), "muzzle": Vector2(8, 1)},
		"north": {"art": """
..k.
.ksk
ksSk
ksSk
ksSk
ksSk
ksSk
ksSk
ksSk
ksSk
.kbk
.kbk
.kbk
..k.
""", "grip": Vector2(2, 11), "muzzle": Vector2(2, 1)},
	},
	"greatsword": {
		"east": {"art": """
.....k..............
....khkkkkkkkkkkk...
.kkkkhssssssssssskk.
kbbbbhSSSSSSSSSSSSsk
.kkkkhkkkkkkkkkkkkk.
....khk.............
.....k..............
""", "grip": Vector2(2, 3), "muzzle": Vector2(18, 3)},
		"northeast": {"art": """
...........kkk.
..........ksSsk
.........ksSSk.
........ksSSk..
.......ksSSk...
......ksSSk....
.....ksSSk.....
..kkksSSk......
.khhsSSk.......
..khSSk........
..khhSk........
.kbbhhk........
kbbkkk.........
kbk............
.k.............
""", "grip": Vector2(1, 12), "muzzle": Vector2(13, 1)},
		"north": {"art": """
...k...
..ksk..
..kSk..
.ksSk..
.ksSk..
.ksSk..
.ksSk..
.ksSk..
.ksSk..
.ksSk..
.ksSk..
.ksSk..
.ksSk..
.ksSkk.
khhhhhk
.kkbkk.
..kbk..
..kbk..
..kbk..
...k...
""", "grip": Vector2(3, 17), "muzzle": Vector2(3, 1)},
	},
	"rifle": {
		"east": {"art": """
.kkkkkkkkkkkkkkkk.
kBBBBdddddSSSSSSSk
kbbbbkkdkkkkkkkkk.
.kkkk..k..........
""", "grip": Vector2(6, 2), "muzzle": Vector2(16, 1)},
		"northeast": {"art": """
...........k.
..........kSk
.........kSSk
........kSSk.
.......kSkk..
......kSSk...
.....kdkk....
....kddk.....
...kdddk.....
..kkdkk......
.kBBbk.......
kBBbk........
kBbk.........
.kk..........
""", "grip": Vector2(5, 9), "muzzle": Vector2(11, 1)},
		"north": {"art": """
.k..
kSk.
kSk.
kSk.
kSk.
kSk.
kSk.
kSk.
kdk.
kdk.
kddk
kdk.
kdk.
kBbk
kBbk
kBbk
kBbk
.kk.
""", "grip": Vector2(2, 11), "muzzle": Vector2(1, 1)},
	},
	"automatic_rifle": {
		"east": {"art": """
.....kkkkkk.......
.kkkkSSSSSSkkkkkk.
kBBBBddddddSSSSSSk
kbbbbkkkdkkkkkkkk.
.kkkk..kdk........
.......kdk........
........k.........
""", "grip": Vector2(6, 3), "muzzle": Vector2(16, 2)},
		"northeast": {"art": """
...........k.
..........kSk
.........kSSk
........kSSk.
......kkSSk..
.....kSdSk...
....kSddk....
...kSdddk....
..kSddddk....
..kSdkkkdk...
.kBBbk..k....
kBBbk........
kBbk.........
.kk..........
""", "grip": Vector2(5, 9), "muzzle": Vector2(11, 1)},
		"north": {"art": """
..k....
.kSk...
.kSk...
.kSk...
.kSk...
.kSk...
.kSk...
kSdk...
kSdkkk.
kSddddk
kSdkkk.
kSdk...
kSdk...
.kBbk..
.kBbk..
.kBbk..
.kBbk..
..kk...
""", "grip": Vector2(3, 11), "muzzle": Vector2(2, 1)},
	},
	"assault_rifle": {
		"east": {"art": """
.....kkkkkkk.......
.kkkkdddddddkkkkkk.
kddddSSSSSSSSSSSSSk
kddkkkdddSkkkkkkkk.
.kk...kkddk........
........kdk........
.........k.........
""", "grip": Vector2(6, 3), "muzzle": Vector2(17, 2)},
		"northeast": {"art": """
............k.
...........kSk
..........kSSk
.........kSSk.
.......kkSSk..
......kdSkk...
.....kdSSk....
....kdSSk.....
...kdSdSk.....
..kdSSkddk....
..kdSdkkk.....
.kddkk........
kddk..........
kddk..........
.kk...........
""", "grip": Vector2(5, 10), "muzzle": Vector2(12, 1)},
		"north": {"art": """
..k....
.kSk...
.kSk...
.kSk...
.kSk...
.kSk...
.kSk...
kdSk...
kdSkkk.
kdSSddk
kdSddk.
kdSdk..
kdSdk..
kdSk...
.kdk...
.kdk...
.kddk..
.kddk..
..kk...
""", "grip": Vector2(3, 12), "muzzle": Vector2(2, 1)},
	},
	"sniper_rifle": {
		"east": {"art": """
......kkkkk..........
.....ksssssk.........
.kkkkkssdsskkkkkkkkk.
kBBBBBdddddSSSSSSSSSk
kbbbbbkkkkkkkkkkkkkk.
.kkkkk...............
""", "grip": Vector2(7, 4), "muzzle": Vector2(19, 3)},
		"northeast": {"art": """
.............k.
............kSk
...........kSk.
..........kSSk.
.........kSSk..
.....kkkkSSk...
....ksssSSk....
...ksssdSk.....
..kssdddk......
..kssddk.......
..ksddk........
..kBBk.........
.kBBbk.........
kBBbk..........
kBbk...........
.kk............
""", "grip": Vector2(6, 10), "muzzle": Vector2(13, 1)},
		"north": {"art": """
...k..
..kSk.
..kSk.
..kSk.
..kSk.
..kSk.
..kSk.
..kSk.
..kSk.
.kkSk.
kssdk.
kssdk.
ksddk.
kssdk.
kssdk.
.kkBbk
..kBbk
..kBbk
..kBbk
..kBbk
...kk.
""", "grip": Vector2(4, 13), "muzzle": Vector2(3, 1)},
	},
	"shotgun": {
		"east": {"art": """
......kkkkkkkkk.
.kkkkkSSSSSSSSSk
kbbbbbdddddddddk
kBBBBkkkBBBkkkk.
.kkkk...kkk.....
""", "grip": Vector2(6, 3), "muzzle": Vector2(14, 1)},
		"northeast": {"art": """
.........k..
........kSk.
.......kSddk
......kSdkk.
.....kSddk..
....kSddBk..
...kSdBBk...
...kddkk....
..kbbk......
.kbbBk......
kbbBk.......
kBBk........
.kk.........
""", "grip": Vector2(5, 8), "muzzle": Vector2(9, 1)},
		"north": {"art": """
.kk..
kSdk.
kSdk.
kSdk.
kSdk.
kSdBk
kSdBk
kSdBk
kSdk.
kSdk.
.kbk.
.kbBk
.kbBk
.kbBk
.kbBk
..kk.
""", "grip": Vector2(3, 9), "muzzle": Vector2(1, 1)},
	},
	"grenade_launcher": {
		"east": {"art": """
.....kkkkkkkk..
....kSSSSSSSSk.
.kkkkddddddddkk
kddddSSSSSSSSk.
.kkkkkdkkkkkk..
......k........
""", "grip": Vector2(6, 4), "muzzle": Vector2(13, 2)},
		"northeast": {"art": """
........kk.
.......kSkk
......kSdkk
.....kSddSk
....kSddSk.
...kSddSk..
..kSddSk...
...kdSSk...
...kSSdk...
.kkdkkk....
kddk.......
.kk........
""", "grip": Vector2(6, 8), "muzzle": Vector2(9, 1)},
		"north": {"art": """
..k...
.kkk..
kSdSk.
kSdSk.
kSdSk.
kSdSk.
kSdSk.
kSdSk.
kSdSdk
kSdSk.
.kkdk.
..kdk.
..kdk.
..kdk.
...k..
""", "grip": Vector2(4, 8), "muzzle": Vector2(2, 1)},
	},
	"nail_gun": {
		"east": {"art": """
.kkkkkk.....
kxxxhxxkkkk.
kxxxxxxSSSSk
.kkdkkkkkkk.
..kdk.......
..kdk.......
...k........
""", "grip": Vector2(3, 4), "muzzle": Vector2(10, 2)},
		"northeast": {"art": """
........k.
.......kSk
.....kkSSk
....kxSSk.
...kxxkk..
..khxxk...
.kxxxk....
kxxxdk....
.kxkkdk...
..k..k....
""", "grip": Vector2(5, 8), "muzzle": Vector2(8, 1)},
		"north": {"art": """
..k....
.kSk...
.kSk...
.kSk...
.kSk...
kxxk...
kxxk...
khxkkk.
kxxdddk
kxxkkk.
kxxk...
.kk....
""", "grip": Vector2(4, 8), "muzzle": Vector2(2, 1)},
	},
	"flare_gun": {
		"east": {"art": """
.kkkkkkkkk.
kxxxHxxxxSk
kxxxxxxxxSk
.kxkkkkkkk.
.kxk.......
..k........
""", "grip": Vector2(2, 3), "muzzle": Vector2(9, 1)},
		"northeast": {"art": """
.......k.
......kSk
.....kxSk
....kxxxk
...kxxxk.
..kHxxk..
.kxxxk...
kxxxxk...
.kxxxk...
..kkk....
""", "grip": Vector2(3, 8), "muzzle": Vector2(7, 1)},
		"north": {"art": """
.kk...
kSSk..
kxxk..
kxxk..
kxxk..
kxxk..
kHxk..
kxxkk.
kxxxxk
kxxkk.
.kk...
""", "grip": Vector2(3, 8), "muzzle": Vector2(1, 1)},
	},
	"crossbow": {
		"east": {"art": """
.......kk....
......ksSk...
..k....kSk...
.kBkkkkkSkkk.
kbBbbbbbSsssk
.kBkkkkkSkkk.
..k....kSk...
......ksSk...
.......kk....
""", "grip": Vector2(4, 4), "muzzle": Vector2(11, 4)},
		"northeast": {"art": """
...kk..kk.
..ksSkkssk
...kSSssk.
...kSSSsk.
...kbbbSk.
.kkbbkkSSk
kBbbk.ksk.
kBBk...k..
kbBk......
.kk.......
""", "grip": Vector2(3, 6), "muzzle": Vector2(8, 1)},
		"north": {"art": """
....k....
...ksk...
...ksk...
.kkkskkk.
kSSSSSSSk
kskkbkksk
.k.kbk.k.
...kbk...
...kbk...
...kbk...
..kBBBk..
...kbk...
....k....
""", "grip": Vector2(4, 8), "muzzle": Vector2(4, 1)},
	},
	"lamp_oil": {
		"east": {"art": """
.kkkk..k.
ksssskkck
kSSSSSck.
khhhhkk..
.kkkk....
""", "grip": Vector2(2, 2), "muzzle": Vector2(7, 2)},
		"northeast": {"art": """
.....k.
....kck
...kkck
..kssSk
.ksSShk
ksSShk.
.khhk..
..kk...
""", "grip": Vector2(2, 5), "muzzle": Vector2(6, 1)},
		"north": {"art": """
.k...
kck..
.kck.
.kSk.
ksShk
ksShk
ksShk
ksShk
.kkk.
""", "grip": Vector2(2, 6), "muzzle": Vector2(2, 1)},
	},
	"golok": {
		"east": {"art": """
....kkkkkkk..
.kkksssssssk.
kbbbSSSSSSssk
.kkkSSSSSSSsk
....kkkkkkkk.
""", "grip": Vector2(2, 2), "muzzle": Vector2(11, 2)},
		"northeast": {"art": """
......kkk.
.....ksssk
....ksSSSk
...ksSSSk.
..ksSSSk..
.ksSSSk...
.kbSSk....
kbbkk.....
kbk.......
.k........
""", "grip": Vector2(1, 7), "muzzle": Vector2(8, 1)},
		"north": {"art": """
..kk.
.kssk
kssSk
ksSSk
ksSSk
ksSSk
ksSSk
ksSSk
ksSSk
.kbk.
.kbk.
.kbk.
..k..
""", "grip": Vector2(2, 10), "muzzle": Vector2(2, 1)},
	},
	"celurit": {
		"east": {"art": """
.......kkkk..
......ksSssk.
.....ksSkkssk
....kSsk..kk.
.kkkksk......
kbbbSk.......
.kkkk........
""", "grip": Vector2(2, 5), "muzzle": Vector2(11, 2)},
		"northeast": {"art": """
....kkk.
...ksssk
...kskk.
..ksk...
..ksk...
..ksk...
..ksk...
..ksk...
..kSk...
.kbbk...
kbbk....
.kk.....
""", "grip": Vector2(2, 9), "muzzle": Vector2(6, 1)},
		"north": {"art": """
..k....
.ksk...
kssk...
ksk....
kSk....
ksSk...
.kssk..
..kSsk.
...kSSk
....kbk
....kbk
....kbk
.....k.
""", "grip": Vector2(5, 10), "muzzle": Vector2(2, 1)},
	},
	"rattan_staff": {
		"east": {"art": """
.kkkkkkkkkkkkkkkkkk.
kAAAAbAAAAbAAAAbAAAk
kaaaabaaaabaaaabaaak
.kkkkkkkkkkkkkkkkkk.
""", "grip": Vector2(6, 2), "muzzle": Vector2(18, 1)},
		"northeast": {"art": """
............kk.
...........kAak
..........kAaak
.........kAbak.
........kAAbk..
.......kAAak...
......kbbak....
.....kAbbk.....
....kAAak......
...kAAak.......
..kAbak........
.kAabk.........
kAaak..........
kaak...........
.kk............
""", "grip": Vector2(5, 10), "muzzle": Vector2(13, 1)},
		"north": {"art": """
.kk.
kAak
kAak
kAak
kbbk
kAak
kAak
kAak
kAak
kbbk
kAak
kAak
kAak
kAak
kbbk
kAak
kAak
kAak
kAak
.kk.
""", "grip": Vector2(2, 13), "muzzle": Vector2(1, 1)},
	},
	"ketapel": {
		"east": {"art": """
......k.
.....kck
.kkkkbck
kbbbbbck
.kkkkbck
.....kck
......k.
""", "grip": Vector2(2, 3), "muzzle": Vector2(6, 3)},
		"northeast": {"art": """
....k...
...kck..
...kck..
...kbck.
..kkbbck
.kbbkkk.
kbbk....
.kk.....
""", "grip": Vector2(2, 6), "muzzle": Vector2(5, 3)},
		"north": {"art": """
.kkkkk.
kccccck
.kbbbk.
..kbk..
..kbk..
..kbk..
..kbk..
...k...
""", "grip": Vector2(3, 5), "muzzle": Vector2(3, 1)},
	},
	"sumpit": {
		"east": {"art": """
.................kk..
.kkkkkkkkkkkkkkkkSSk.
kbbAAAAAAAAAAAAAAsssk
.kkkkkkkkkkkkkkkkSSk.
.................kk..
""", "grip": Vector2(5, 2), "muzzle": Vector2(19, 2)},
		"northeast": {"art": """
............kk.
...........kSsk
..........kSsSk
..........kAASk
.........kAAkk.
........kAAk...
.......kAAk....
......kAkk.....
.....kAk.......
....kAAk.......
...kAAk........
..kAAk.........
.kAAk..........
kbAk...........
kbk............
.k.............
""", "grip": Vector2(4, 11), "muzzle": Vector2(13, 1)},
		"north": {"art": """
..k..
.ksk.
kSsSk
kSsSk
.kAk.
.kAk.
.kAk.
.kAk.
.kAk.
.kAk.
.kAk.
.kAk.
.kAk.
.kAk.
.kAk.
.kAk.
.kAk.
.kAk.
.kbk.
.kbk.
..k..
""", "grip": Vector2(2, 15), "muzzle": Vector2(2, 1)},
	},
	"petasan": {
		"east": {"art": """
.kkkkkkkk.
kccHcccBBk
kccHccBBk.
kccHcckk..
.kkkkk....
""", "grip": Vector2(2, 2), "muzzle": Vector2(8, 1)},
		"northeast": {"art": """
......k.
.....kBk
....kkBk
...kcBk.
..kccck.
.kHHcck.
kccHHk..
.kcck...
..kk....
""", "grip": Vector2(2, 6), "muzzle": Vector2(6, 1)},
		"north": {"art": """
.k...
kBk..
kBBk.
kBBk.
kccck
kccck
kHHHk
kccck
kccck
.kkk.
""", "grip": Vector2(2, 7), "muzzle": Vector2(1, 1)},
	},
	"tombak": {
		"east": {"art": """
................kkk...
.kkkkkkkkkkkkkkkssskk.
kbbbbbbbbbbbbbbcSSSSsk
.kkkkkkkkkkkkkkccSSkk.
...............kkkk...
""", "grip": Vector2(6, 2), "muzzle": Vector2(20, 2)},
		"northeast": {"art": """
..............k.
............kksk
...........ksSk.
..........ksSSk.
..........kSSSk.
.........kbckk..
........kbbck...
.......kbbkk....
......kbbk......
.....kbbk.......
....kbbk........
...kbbk.........
..kbbk..........
.kbbk...........
kbbk............
kbk.............
.k..............
""", "grip": Vector2(4, 11), "muzzle": Vector2(14, 1)},
		"north": {"art": """
..k..
.ksk.
.kSk.
ksSSk
ksSSk
ksSSk
.kcck
.kbk.
.kbk.
.kbk.
.kbk.
.kbk.
.kbk.
.kbk.
.kbk.
.kbk.
.kbk.
.kbk.
.kbk.
.kbk.
.kbk.
..k..
""", "grip": Vector2(2, 15), "muzzle": Vector2(2, 1)},
	},
	"bambu_runcing": {
		"east": {"art": """
.kkkkkkkkkkkkkkkkkkk.
kAAAAAaAAAAaAAAAAAAZk
kaaaaaaaaaaaaaaaAAkk.
.kkkkkkkkkkkkkkkkk...
""", "grip": Vector2(6, 2), "muzzle": Vector2(19, 1)},
		"northeast": {"art": """
.............k.
............kZk
...........kkAk
..........kAAk.
.........kAAAk.
........kAAak..
.......kAaak...
......kAaak....
.....kAaak.....
....kAaak......
...kaaak.......
..kAaak........
.kAaak.........
kAaak..........
kaak...........
.kk............
""", "grip": Vector2(5, 11), "muzzle": Vector2(13, 1)},
		"north": {"art": """
.k..
kZk.
kAk.
kAAk
kAAk
kAak
kAak
kAak
kAak
kaak
kAak
kAak
kAak
kAak
kaak
kAak
kAak
kAak
kAak
kAak
.kk.
""", "grip": Vector2(2, 14), "muzzle": Vector2(1, 1)},
	},
	"mandau": {
		"east": {"art": """
.k....kkkkkkkkk.
kckkkksssssssssk
kBBBBSSSSSSSSsk.
.kkkkSSSSkkkkk..
.....kkkk.......
""", "grip": Vector2(3, 2), "muzzle": Vector2(14, 1)},
		"northeast": {"art": """
..........k.
.........ksk
........kssk
.......ksSSk
......ksSSk.
.....ksSSk..
....ksSSk...
....kSSSk...
...kkSSk....
.kkBBSk.....
kcBBkk......
.kBk........
..k.........
""", "grip": Vector2(3, 9), "muzzle": Vector2(10, 1)},
		"north": {"art": """
.k...
ksk..
kssk.
ksSk.
ksSk.
ksSk.
ksSk.
ksSSk
ksSSk
ksSSk
.kSSk
.kBk.
.kBk.
.kBk.
kcBk.
.kk..
""", "grip": Vector2(2, 12), "muzzle": Vector2(1, 1)},
	},
	"rencong": {
		"east": {"art": """
....kkkkkk..
..kkssssssk.
.khhSSSSSSSk
kbbkkkkkkkk.
kbk.........
.k..........
""", "grip": Vector2(2, 3), "muzzle": Vector2(10, 2)},
		"northeast": {"art": """
......kk.
.....ksSk
....ksSSk
...ksSSk.
..ksSSk..
.ksSSk...
.khSk....
khhk.....
.kbk.....
.kbk.....
..k......
""", "grip": Vector2(2, 8), "muzzle": Vector2(7, 1)},
		"north": {"art": """
..k...
.kSk..
ksSk..
ksSk..
ksSk..
ksSk..
ksSk..
ksSk..
.khk..
.khbk.
..kbbk
...kk.
""", "grip": Vector2(3, 9), "muzzle": Vector2(2, 1)},
	},
	"badik": {
		"east": {"art": """
.k..kkkk..
kbkkssssk.
kbbbSSSSSk
.kkkkSSSk.
.....kkk..
""", "grip": Vector2(2, 2), "muzzle": Vector2(8, 2)},
		"northeast": {"art": """
.....kkk.
....ksSSk
...ksSSSk
..ksSSSk.
.kkbSSk..
kbbbkk...
.kbk.....
..k......
""", "grip": Vector2(2, 5), "muzzle": Vector2(7, 1)},
		"north": {"art": """
..k..
.kSk.
ksSSk
ksSSk
ksSSk
ksSk.
.kbk.
.kbk.
kbbk.
.kk..
""", "grip": Vector2(2, 7), "muzzle": Vector2(2, 1)},
	},
	"kujang": {
		"east": {"art": """
......k..k...
....kkSkksk..
.kkksssSsssk.
kbbbSSSSSSSsk
.kkkkkkkkkkk.
""", "grip": Vector2(2, 3), "muzzle": Vector2(11, 3)},
		"northeast": {"art": """
......kkk.
.....ksssk
....kkssSk
...kSSSSk.
...kssSk..
..kssSk...
..ksSk....
.kbbk.....
kbbk......
.kk.......
""", "grip": Vector2(2, 8), "muzzle": Vector2(8, 1)},
		"north": {"art": """
...k.
..ksk
.ksSk
kssSk
.ksSk
.kSSk
kSsSk
.ksSk
.ksSk
..kbk
..kbk
..kbk
...k.
""", "grip": Vector2(3, 10), "muzzle": Vector2(3, 1)},
	},
	"panah": {
		"east": {"art": """
....k.......
...ksk......
...ksk......
...ksbk.....
.kkksbkkkkk.
kcSSSSSSSSsk
.kkksbkkkkk.
...ksbk.....
...ksk......
...ksk......
....k.......
""", "grip": Vector2(5, 5), "muzzle": Vector2(10, 5)},
		"northeast": {"art": """
........k.
.......ksk
.kk...kSk.
ksbkkkSSk.
.ksbbSkk..
..ksSSk...
..kSSbk...
.kSSSssk..
.kckkkssk.
..k...kk..
""", "grip": Vector2(5, 5), "muzzle": Vector2(8, 1)},
		"north": {"art": """
.....k.....
....ksk....
....kSk....
....kSk....
....kSk....
...kkSkkk..
.kkbbSbbbk.
kssssSssssk
.kkkkSkkkk.
....kSk....
....kck....
.....k.....
""", "grip": Vector2(5, 6), "muzzle": Vector2(5, 1)},
	},
}
