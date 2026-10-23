class_name Defs
extends RefCounted
## All static game data of Pixel TD: classes, difficulties, towers, enemies and the wave generator.
# ---------------------------------------------------------------- enemy classes
# Class only weakens CONTROL effects (stun, slow...). Damage of any kind is never reduced by class.
const CLASS_ROMAN := ["", "I", "II", "III", "IV"]
const CLASS_EFFECT := [1.0, 1.0, 0.7, 0.4, 0.2]
const CLASS_COLORS := [Color.WHITE, Color("c0cbdc"), Color("63c74d"), Color("feae34"), Color("e43b44")]

# ---------------------------------------------------------------- difficulties
const DIFFICULTIES := [
	{"id": "light", "name": "Light", "lives": 200, "cash": 1600, "hp": 0.8, "cost": 0.85, "waves": 20,
		"sell": 0.8, "color": Color("63c74d"), "btn": "green",
		"desc": "20 waves. Weaker enemies, cheaper towers, 200 lives.",
		"bonus_multi": 1.2},
	{"id": "medium", "name": "Medium", "lives": 150, "cash": 1300, "hp": 1.0, "cost": 1.0, "waves": 30,
		"sell": 0.7, "color": Color("0099db"), "btn": "blue",
		"desc": "30 waves. The standard challenge, 150 lives.",
		"bonus_multi": 1.0},
	{"id": "difficult", "name": "Difficult", "lives": 100, "cash": 1200, "hp": 1.12, "cost": 1.08, "waves": 40,
		"sell": 0.7, "color": Color("f77622"), "btn": "gold",
		"desc": "40 waves. Tougher enemies, pricier towers, 100 lives.",
		"bonus_multi": 0.95},
	{"id": "hardcore", "name": "Hardcore", "lives": 50, "cash": 1300, "hp": 1.12, "cost": 1.08, "waves": 40,
		"sell": 0.7, "color": Color("e43b44"), "btn": "red",
		"desc": "40 waves. Lots of lead enemies. 50 lives.",
		"bonus_multi": 0.7},
	{"id": "ultracore", "name": "Ultracore", "lives": 1, "cash": 1500, "hp": 1.25, "cost": 1.1, "waves": 40,
		"sell": 0.7, "color": Color("b25aff"), "btn": "purple",
		"desc": "40 waves. ONE life. Beat Hardcore here first.",
		"bonus_multi": 0.8, "needs": 3},
]

# ---------------------------------------------------------------- towers
# "base" holds level-0 stats; each upgrade overrides some of them ("set"). Upgrades are a single line.
const TOWER_ORDER := ["gunner", "knight", "soldier", "garage", "flamer", "sniper", "necro", "freezer", "toxic",
	"assassin", "minigun", "farm"]
const TOWERS := {
	"gunner": {
		"name": "Gunslinger", "role": "Ranged - single target", "cost": 250, "sprite": "gunner",
		"desc": "Quick pistol shots at one target. Armor reduces each bullet.",
		"unlock": {},
		"base": {"damage": 3, "rate": 2.0, "range": 72, "targets": 1, "slow": 0.0, "slow_time": 0.0,
			"kind": "physical", "armor_pierce": 0.0, "camo": false, "air": true},
		"upgrades": [
			{"name": "Quick Draw", "icon": "quick_draw", "cost": 170, "desc": "Fire rate +50%.", "set": {"rate": 3.0}},
			{"name": "Hollow Points", "icon": "hollow_points", "cost": 380,
				"desc": "Damage 3 > 5. Range +12. Spots INVISIBLE enemies.",
				"set": {"damage": 5, "range": 84, "camo": true}},
			{"name": "Dual Pistols", "icon": "dual_pistols", "cost": 890,
				"desc": "Shoots 2 targets, damage 7. Bullets slow by 35% (control).",
				"set": {"targets": 2, "damage": 7, "slow": 0.35, "slow_time": 0.7, "rate": 3.4}},
			{"name": "Fan the Hammer", "icon": "fan_hammer", "cost": 2700,
				"desc": "Damage 7 > 10, fires faster.",
				"set": {"damage": 10, "rate": 4.2}},
		],
	},
	"knight": {
		"name": "Knight", "role": "Melee - stuns", "cost": 450, "sprite": "knight",
		"desc": "Heavy sword. Ignores half of armor. Every 3rd hit stuns (control).",
		"unlock": {},
		"base": {"damage": 11, "rate": 0.9, "range": 30, "cleave": false, "stun_every": 3, "stun": 0.5,
			"aura": 0.0, "kind": "physical", "armor_pierce": 0.5, "camo": false, "air": false},
		"upgrades": [
			{"name": "Sharpened Blade", "icon": "sharpened_blade", "cost": 250, "desc": "Damage 11 > 18, swings faster.",
				"set": {"damage": 18, "rate": 1.1}},
			{"name": "Cleave", "icon": "cleave", "cost": 560, "desc": "Swings hit ALL enemies in range. Range +4.",
				"set": {"cleave": true, "range": 34}},
			{"name": "Champion", "icon": "champion", "cost": 1340, "desc": "Damage 41. Every 2nd hit stuns for 0.8s.",
				"set": {"damage": 41, "rate": 1.3, "stun_every": 2, "stun": 0.8, "armor_pierce": 0.75}},
			{"name": "Templar", "icon": "templar", "cost": 3400, "desc": "Damage 41 > 76, swings faster.",
				"set": {"damage": 76, "rate": 1.4}},
			{"name": "Paladin", "icon": "paladin", "cost": 8000, "desc": "Damage 150. Cuts through ANY armor.",
				"set": {"damage": 150, "rate": 1.5, "armor_pierce": 1.0}},
			{"name": "Holy Champion", "icon": "holy_champion", "cost": 20100,
				"desc": "Damage 325. Holy aura: towers within 48 px deal 15% more damage.",
				"set": {"damage": 325, "rate": 1.6, "aura": 0.15}},
		],
	},
	"soldier": {
		"name": "Soldier", "role": "Ranged - bursts, anti-armor", "cost": 650, "sprite": "soldier",
		"desc": "Assault rifle firing 3-round bursts from long range.",
		"unlock": {"price": 25},   # on sale from the start
		"base": {"damage": 4, "rate": 0.8, "burst": 3, "burst_gap": 0.09, "range": 92, "armor_pierce": 0.0,
			"grenade_every": 0, "grenade_dmg": 0, "grenade_radius": 0, "kind": "physical",
			"camo": false, "air": true},
		"upgrades": [
			{"name": "AP Rounds", "icon": "ap_rounds", "cost": 360,
				"desc": "Bullets ignore 75% of armor and pierce LEAD. Damage 4 > 5. Spots INVISIBLE enemies.",
				"set": {"armor_pierce": 0.75, "damage": 5, "camo": true, "lead": true}},
			{"name": "Grenades", "icon": "grenades", "cost": 790,
				"desc": "Every 3rd burst also throws a grenade (35 dmg) that hits a whole area.",
				"set": {"grenade_every": 3, "grenade_dmg": 35, "grenade_radius": 24}},
			{"name": "Machine Gun", "icon": "machine_gun", "cost": 1900,
				"desc": "Long 8-round bursts. Damage 5 > 6. Grenades every 2nd burst.",
				"set": {"burst": 8, "burst_gap": 0.06, "rate": 1.0, "damage": 6, "grenade_every": 2}},
			{"name": "Elite Soldier", "icon": "headshot", "cost": 3200,
				"desc": "Long 11-round bursts, and faster. Damage 6 > 7.",
				"set": {"burst": 11, "burst_gap": 0.06, "rate": 1.1, "damage": 7, "grenade_every": 2}},
			{"name": "Heavy Gunner", "icon": "heavy_gunner", "cost": 10300,
				"desc": "14-round bursts, damage 13. Grenades hit for 70.",
				"set": {"burst": 14, "rate": 1.15, "damage": 13, "grenade_dmg": 70}},
			{"name": "Commando", "icon": "commando", "cost": 25300,
				"desc": "16-round bursts, damage 28. Grenades hit for 170 over a bigger area.",
				"set": {"burst": 16, "burst_gap": 0.05, "rate": 1.2, "damage": 28, "grenade_dmg": 170,
					"grenade_radius": 30}},
		],
	},
	"garage": {
		"name": "Garage", "role": "Road - friendly cars", "cost": 900, "sprite": "garage",
		"desc": "Build next to a road. Sends cars that drive INTO the enemies, invisible and LEAD ones too. On a crash both lose the HP of the weaker one.",
		"unlock": {"map": "gas_station", "difficulty": 2, "price": 75},
		"base": {"interval": 6.0, "car_hp": 22, "car_speed": 70, "vehicle": "car",
			"gun_dmg": 0, "gun_rate": 0.0, "range": 0, "lead": true,
			"camo": true, "air": false},
		"upgrades": [
			{"name": "Pickup", "icon": "pickup", "cost": 390, "desc": "Sturdier car (45 HP), comes out more often.",
				"set": {"vehicle": "pickup", "car_hp": 45, "interval": 5.0}},
			{"name": "Truck", "icon": "truck", "cost": 870, "desc": "Heavy truck with 85 HP. Plows through crowds.",
				"set": {"vehicle": "truck", "car_hp": 85, "car_speed": 60}},
			{"name": "Armored Car", "icon": "armored", "cost": 2000,
				"desc": "125 HP and a turret that shoots while driving.",
				"set": {"vehicle": "armored", "car_hp": 125, "gun_dmg": 5, "gun_rate": 2.5, "interval": 4.5}},
			{"name": "Reinforced Plating", "icon": "plating", "cost": 4500,
				"desc": "280 HP, turret 9 dmg, comes out more often.",
				"set": {"car_hp": 280, "gun_dmg": 9, "gun_rate": 3.0, "interval": 4.0}},
			{"name": "Twin Turret", "icon": "twin_turret", "cost": 10500,
				"desc": "675 HP. Two turrets: 22 dmg, faster.",
				"set": {"car_hp": 675, "gun_dmg": 22, "gun_rate": 4.0}},
		],
	},
	"flamer": {
		"name": "Flamethrower", "role": "Close - area burn", "cost": 1000, "sprite": "flamer",
		"desc": "Sprays fire in a cone and sets enemies ablaze. Fire ignores armor and melts LEAD. Can't aim at invisible enemies, but the flames still burn them.",
		"unlock": {"map": "volcano", "difficulty": 1, "price": 140},
		"base": {"damage": 1.1, "range": 46, "cone": 56.0, "burn": 2.0, "burn_time": 2.0, "fire_pierce": 0.0,
			"kind": "fire", "camo": false, "air": false, "lead": true},
		"upgrades": [
			{"name": "Bigger Tank", "icon": "bigger_tank", "cost": 470, "desc": "Range 46 > 58. Wider cone.",
				"set": {"range": 58, "cone": 72.0}},
			{"name": "Napalm", "icon": "napalm", "cost": 950, "desc": "Burn 2 > 7 dps for 3s. Spray damage +40%.",
				"set": {"burn": 7.0, "burn_time": 3.0, "damage": 1.6}},
			{"name": "Blue Flame", "icon": "blue_flame", "cost": 2200, "desc": "Spray 29 dps, burn 14. Ignores half of fire resistance.",
				"set": {"damage": 2.9, "burn": 14.0, "fire_pierce": 0.5}},
			{"name": "Pyromania", "icon": "blue_flame", "cost": 4000, "desc": "Spray 46 dps, burn 21. Ignores 3/4 of fire resistance.",
				"set": {"damage": 4.6, "burn": 21.0, "fire_pierce": 0.75}},
			{"name": "Inferno", "icon": "inferno", "cost": 11100, "desc": "Spray 92 dps, burn 46. Longer, wider flames.",
				"set": {"damage": 9.2, "burn": 46.0, "range": 64, "cone": 80.0}},
			{"name": "Dragon's Breath", "icon": "dragon_breath", "cost": 25300,
				"desc": "Spray 207 dps, burn 80 for 4s. Burns through ANY fire resistance.",
				"set": {"damage": 20.7, "burn": 80.0, "burn_time": 4.0, "fire_pierce": 1.0, "range": 70}},
		],
	},
	"sniper": {
		"name": "Sniper", "role": "Ranged - huge range, sees all", "cost": 1200, "sprite": "sniper",
		"desc": "Slow, heavy shots from across the map. Sees INVISIBLE and hits FLYING enemies.",
		"unlock": {"map": "meadow", "difficulty": 2, "price": 40},
		"base": {"damage": 18, "rate": 0.45, "range": 170, "armor_pierce": 0.3, "headshot": 0.0,
			"kind": "physical", "camo": true, "air": true},
		"upgrades": [
			{"name": "Optics", "icon": "optics", "cost": 420, "desc": "Range 170 > 240. Damage 18 > 26.",
				"set": {"range": 240, "damage": 26}},
			{"name": "Full Metal Jacket", "icon": "fmj", "cost": 830,
				"desc": "Ignores ALL armor and pierces LEAD. Damage 26 > 50, shoots faster.",
				"set": {"armor_pierce": 1.0, "damage": 50, "rate": 0.55, "lead": true}},
			{"name": "Headshot", "icon": "headshot", "cost": 2300,
				"desc": "Damage 95. 15% chance to kill any non-boss enemy outright.",
				"set": {"damage": 95, "rate": 0.65, "headshot": 0.15}},
			{"name": "Elite Sniper", "icon": "headshot", "cost": 3200,
				"desc": "Damage 115 and faster rate. 20% chance to kill any non-boss enemy outright.",
				"set": {"damage": 115, "rate": 0.70, "headshot": 0.20}},
			{"name": "Anti-Material Rifle", "icon": "anti_material", "cost": 12100,
				"desc": "Damage 265 a shot.",
				"set": {"damage": 265}},
			{"name": "Deadeye", "icon": "deadeye", "cost": 29400,
				"desc": "Damage 540, shoots faster. 25% chance to kill any non-boss enemy outright.",
				"set": {"damage": 540, "rate": 0.75, "headshot": 0.25}},
		],
	},
	# Halloween event character (can be unlocked any time of the year)
	"necro": {
		"name": "Necromancer", "role": "Magic - raises the dead", "cost": 850, "sprite": "necro",
		"desc": "Dark bolts that ignore most armor. Enemies it finishes off rise as FRIENDLY undead somewhere on the road in its range, walk back and crash into enemies. Never raises flyers or bosses.",
		"unlock": {"map": "graveyard", "difficulty": 2, "price": 130},
		"base": {"damage": 10, "rate": 1.0, "range": 80, "armor_pierce": 0.6, "raise_hp": 0.2, "raise_class": 1,
			"kind": "physical", "camo": false, "air": true},
		"upgrades": [
			{"name": "Dark Pact", "icon": "dark_pact", "cost": 360,
				"desc": "Undead keep 35% HP. Raises class II too. Damage 10 > 14.",
				"set": {"raise_hp": 0.35, "raise_class": 2, "damage": 14}},
			{"name": "Bone Army", "icon": "bone_army", "cost": 850,
				"desc": "Undead keep 50% HP. Damage 24, faster bolts. Spots INVISIBLE enemies.",
				"set": {"raise_hp": 0.5, "damage": 24, "rate": 1.2, "camo": true}},
			{"name": "Lich", "icon": "lich", "cost": 2100,
				"desc": "Undead keep 70% HP. Raises class III. Damage 44.",
				"set": {"raise_hp": 0.7, "raise_class": 3, "damage": 44, "rate": 1.3}},
			{"name": "Soul Harvest", "icon": "soul_harvest", "cost": 4100,
				"desc": "Undead keep 85% HP. Damage 65, faster bolts.",
				"set": {"raise_hp": 0.85, "damage": 65, "rate": 1.4}},
			{"name": "Lord of Bones", "icon": "lord_bones", "cost": 10300,
				"desc": "Undead keep ALL their HP. Damage 110.",
				"set": {"raise_hp": 1.0, "damage": 110, "rate": 1.5}},
		],
	},
	"freezer": {
		"name": "Freezer", "role": "Close - chills and freezes", "cost": 650, "sprite": "freezer",
		"desc": "Hoses enemies in a cone with ice water. Soaked enemies slow down more and more, then freeze solid in a block of ice. Higher classes chill slower and thaw faster. Water puts out burning enemies, and fire melts the ice.",
		"unlock": {"map": "frozen_lake", "difficulty": 2, "price": 130},
		"base": {"damage": 0.0, "range": 44, "cone": 60.0, "chill": 0.45, "chill_slow": 0.35, "freeze": 1.0,
			"brittle": 0.0, "kind": "cold", "camo": false, "air": false},
		"upgrades": [
			{"name": "Cold Water", "icon": "cold_water", "cost": 300,
				"desc": "Colder water: chills faster (45% > 65% a second), slows up to 45%.",
				"set": {"chill": 0.65, "chill_slow": 0.45}},
			{"name": "Pressure Hose", "icon": "pressure_hose", "cost": 520,
				"desc": "Range 44 > 56, wider cone. Frozen for 1.5s.",
				"set": {"range": 56, "cone": 72.0, "freeze": 1.5}},
			{"name": "Ice Water", "icon": "ice_water", "cost": 1020,
				"desc": "Ice-cold water now hurts: 7 dps that ignores armor. Chills faster, frozen for 2s.",
				"set": {"damage": 0.7, "chill": 0.9, "chill_slow": 0.55, "freeze": 2.0}},
			{"name": "Liquid Nitrogen", "icon": "nitrogen", "cost": 2500,
				"desc": "Swaps water for liquid nitrogen: 16 dps, freezes very fast, frozen for 2.5s.",
				"set": {"damage": 1.6, "chill": 1.4, "chill_slow": 0.65, "freeze": 2.5}},
			{"name": "Cryo Cannon", "icon": "cryo_cannon", "cost": 8900,
				"desc": "65 dps, range 64, frozen for 3s. Enemies it freezes take 25% more damage from everything.",
				"set": {"damage": 6.5, "chill": 1.8, "range": 64, "freeze": 3.0, "brittle": 0.25}},
		],
	},
	# acid towers: acid hurts over time through armor and eats some armor while it lasts
	"toxic": {
		"name": "Toxic Gunner", "role": "Ranged - acid", "cost": 550, "sprite": "toxic",
		"desc": "Shoots globs of acid. Acid burns through armor and LEAD over time and eats some of the armor while it lasts, so every other tower hits harder too.",
		"unlock": {"map": "refinery", "difficulty": 2, "price": 130},
		"base": {"damage": 3, "rate": 1.2, "range": 80, "acid_dps": 3.0, "acid_time": 3.0, "acid_shred": 1.0,
			"splash": 0.0, "kind": "physical", "camo": false, "air": true, "lead": true},
		"upgrades": [
			{"name": "Corrosive Mix", "icon": "corrosive_mix", "cost": 280,
				"desc": "Stronger acid: 3 > 6 dps, eats 2 armor.",
				"set": {"acid_dps": 6.0, "acid_shred": 2.0}},
			{"name": "Scope", "icon": "toxic_scope", "cost": 480,
				"desc": "Range 80 > 96, shoots faster. Spots INVISIBLE enemies.",
				"set": {"range": 96, "rate": 1.5, "camo": true}},
			{"name": "Acid Splash", "icon": "acid_splash", "cost": 880,
				"desc": "Globs burst: everyone within 18 px of the target gets the acid too.",
				"set": {"splash": 18.0}},
			{"name": "Toxic Overload", "icon": "toxic_overload", "cost": 2000,
				"desc": "Acid 16 dps for 4s, eats 4 armor. Damage 7, faster, bigger splash.",
				"set": {"damage": 7, "rate": 1.8, "acid_dps": 16.0, "acid_time": 4.0, "acid_shred": 4.0, "splash": 24.0}},
		],
	},
	"assassin": {
		"name": "Toxic Assassin", "role": "Melee - fast, acid, daggers", "cost": 1500, "sprite": "assassin",
		"desc": "Quick poisoned blades up close, they cut LEAD too. From level 4 the Assassin also throws daggers at range, and the daggers reach FLYING enemies.",
		"unlock": {"map": "refinery", "difficulty": 3, "price": 200},
		"base": {"damage": 15, "rate": 2.4, "range": 28, "armor_pierce": 0.25, "acid_dps": 6.0, "acid_time": 2.0,
			"acid_shred": 1.0, "dagger_dmg": 0, "dagger_rate": 0.0, "dagger_range": 0, "daggers": 0, "lead": true,
			"kind": "physical", "camo": false, "air": false},
		"upgrades": [
			{"name": "Poisoned Blades", "icon": "poisoned_blades", "cost": 470,
				"desc": "Acid 6 > 18 dps, eats 2 armor.",
				"set": {"acid_dps": 18.0, "acid_shred": 2.0}},
			{"name": "Swift Strikes", "icon": "swift_strikes", "cost": 770,
				"desc": "Attacks 2.4 > 3 times a second, damage 15 > 18.",
				"set": {"rate": 3.0, "damage": 18}},
			{"name": "Throwing Daggers", "icon": "throwing_daggers", "cost": 1280,
				"desc": "NEW ATTACK: throws a poisoned dagger (20 dmg) at range 90. Daggers hit FLYING enemies.",
				"set": {"dagger_dmg": 20, "dagger_rate": 1.2, "dagger_range": 90, "daggers": 1}},
			{"name": "Twin Daggers", "icon": "twin_daggers", "cost": 2000,
				"desc": "Throws 2 daggers at once, 24 dmg. Spots INVISIBLE enemies.",
				"set": {"dagger_dmg": 24, "daggers": 2, "camo": true}},
			{"name": "Master Assassin", "icon": "master_assassin", "cost": 4000,
				"desc": "Blades 30 dmg, 3.3 attacks a second, acid 30 dps eating 4 armor. Daggers 28 dmg, faster.",
				"set": {"damage": 30, "rate": 3.3, "acid_dps": 30.0, "acid_shred": 4.0, "dagger_dmg": 28,
					"dagger_rate": 1.6}},
			{"name": "Shadow Blade", "icon": "shadow_blade", "cost": 29200,
				"desc": "Blades 150 dmg, 3.6 a second, acid 75 dps eating 8 armor. Throws 3 daggers of 50.",
				"set": {"damage": 150, "rate": 3.6, "acid_dps": 75.0, "acid_shred": 8.0, "dagger_dmg": 50,
					"daggers": 3, "dagger_rate": 2.0}},
		],
	},
	"minigun": {
		"name": "Minigunner", "role": "Ranged - spins up, huge DPS", "cost": 1400, "sprite": "minigun",
		"desc": "Spins up while it keeps shooting: from a few shots a second to a storm of bullets. With nothing to shoot it winds down fast, so it shines on bosses and tanks. Hits FLYING enemies.",
		"unlock": {"map": "meadow", "difficulty": 3, "price": 90},
		"base": {"damage": 3, "min_rate": 3.0, "max_rate": 12.0, "spin_time": 3.0, "range": 84, "armor_pierce": 0.0,
			"kind": "physical", "camo": false, "air": true},
		"upgrades": [
			{"name": "Bigger Drum", "icon": "bigger_drum", "cost": 500, "desc": "Top speed 12 > 16 shots a second.",
				"set": {"max_rate": 16.0}},
			{"name": "Hot Barrels", "icon": "hot_barrels", "cost": 900,
				"desc": "Spins up in 2s instead of 3, starts at 5 shots a second. Damage 3 > 4.",
				"set": {"spin_time": 2.0, "min_rate": 5.0, "damage": 4}},
			{"name": "Tungsten Rounds", "icon": "tungsten", "cost": 1600,
				"desc": "Bullets ignore 60% of armor and pierce LEAD. Damage 5. Spots INVISIBLE enemies.",
				"set": {"armor_pierce": 0.6, "lead": true, "camo": true, "damage": 5}},
			{"name": "Twin Barrels", "icon": "twin_barrels", "cost": 3000, "desc": "Top speed 24 shots a second, damage 6.",
				"set": {"max_rate": 24.0, "damage": 6}},
			{"name": "Heavy Minigun", "icon": "heavy_minigun", "cost": 7000,
				"desc": "Damage 10, top speed 28, starts at 7 shots a second.",
				"set": {"damage": 10, "max_rate": 28.0, "min_rate": 7.0}},
			{"name": "Bullet Storm", "icon": "bullet_storm", "cost": 26000,
				"desc": "Damage 22, top speed 32, spins up in 1.5s, ignores ALL armor.",
				"set": {"damage": 22, "max_rate": 32.0, "spin_time": 1.5, "armor_pierce": 1.0}},
		],
	},
	"farm": {
		"name": "Farm", "role": "Economy - money every wave", "cost": 450, "sprite": "farm", "limit": 8,
		"desc": "Doesn't fight: pays money at the end of every wave. The upgrades pay more and more. At most 8 farms in a battle.",
		"unlock": {"map": "farmlands", "difficulty": 2, "price": 75},
		"base": {"income": 60, "range": 0},
		"upgrades": [
			{"name": "Bigger Fields", "icon": "bigger_fields", "cost": 350, "desc": "Pays $110 a wave instead of $60.",
				"set": {"income": 110}},
			{"name": "Barn", "icon": "barn", "cost": 900, "desc": "Pays $230 a wave.", "set": {"income": 230}},
			{"name": "Tractor", "icon": "tractor", "cost": 2200, "desc": "Pays $500 a wave.", "set": {"income": 500}},
			{"name": "Irrigation", "icon": "irrigation", "cost": 4500, "desc": "Pays $1000 a wave.",
				"set": {"income": 1000}},
			{"name": "Greenhouses", "icon": "greenhouse", "cost": 9000, "desc": "Pays $2000 a wave.",
				"set": {"income": 2000}},
			{"name": "Agro Empire", "icon": "agro_empire", "cost": 18000, "desc": "Pays $4000 a wave.",
				"set": {"income": 4000}},
		],
	},
}

# ---------------------------------------------------------------- enemies
const ENEMY_ORDER := ["slime", "rat", "bat", "goblin", "skeleton", "wolf", "ironclad", "imp", "ghost",
	"berserker", "shaman", "slime_king", "harpy", "ogre", "troll", "wraith", "gargoyle", "dark_knight", "mammoth",
	"golem", "bone_dragon", "demon", "titan"]
# Every enemy type has fixed HP (like TDS): later waves get harder with tougher types, bigger groups and
# Bloated enemies (BLOATED_HP times the HP), not by inflating the HP of the same enemy.
# Waves can also send any enemy as Lead: only towers with "lead" in their stats hurt it.
const BLOATED_HP := 2.0
const ENEMIES := {
	"slime": {"name": "Slime", "class": 1, "hp": 7, "speed": 28, "bounty": 2, "radius": 6,
		"desc": "Bouncy and squishy."},
	"rat": {"name": "Sewer Rat", "class": 1, "hp": 5, "speed": 56, "bounty": 2, "radius": 5,
		"desc": "Small and very fast."},
	"goblin": {"name": "Goblin", "class": 1, "hp": 16, "speed": 34, "bounty": 3, "radius": 6,
		"desc": "Standard foot soldier."},
	"bat": {"name": "Bat", "class": 1, "hp": 5, "speed": 52, "bounty": 2, "radius": 5, "flying": true,
		"desc": "Flies in swarms. Melee, fire and cars can't reach it."},
	"skeleton": {"name": "Skeleton", "class": 1, "hp": 17, "speed": 32, "bounty": 3, "radius": 6, "revive": 0.5,
		"desc": "Falls apart, then gets back up once with half HP."},
	"ghost": {"name": "Ghost", "class": 2, "hp": 36, "speed": 36, "bounty": 6, "radius": 6, "invisible": true,
		"desc": "Invisible. Only towers that spot invisible enemies can aim at it."},
	"berserker": {"name": "Orc Berserker", "class": 2, "hp": 78, "speed": 28, "bounty": 9, "radius": 7,
		"rage": 2.0, "desc": "Runs twice as fast once below half HP."},
	"harpy": {"name": "Harpy", "class": 3, "hp": 250, "speed": 30, "bounty": 22, "radius": 8, "flying": true,
		"armor": 1, "desc": "Tough flyer. Ground and melee towers can't touch her."},
	"wolf": {"name": "Dire Wolf", "class": 2, "hp": 24, "speed": 56, "bounty": 5, "radius": 7,
		"desc": "Runs past slow defences."},
	"ironclad": {"name": "Ironclad", "class": 2, "hp": 48, "speed": 25, "bounty": 7, "radius": 7, "armor": 4,
		"desc": "Heavy armor. Pistol bullets barely scratch it."},
	"imp": {"name": "Fire Imp", "class": 2, "hp": 33, "speed": 40, "bounty": 6, "radius": 6, "fire_res": 1.0,
		"desc": "Born in flames. Fire does nothing."},
	"shaman": {"name": "Goblin Shaman", "class": 3, "hp": 100, "speed": 30, "bounty": 12, "radius": 7,
		"heal": 0.12, "desc": "Heals nearby enemies."},
	"slime_king": {"name": "Slime King", "class": 3, "hp": 216, "speed": 24, "bounty": 20, "radius": 9,
		"split": 6, "desc": "Bursts into slimes when defeated."},
	"ogre": {"name": "Ogre", "class": 3, "hp": 310, "speed": 22, "bounty": 25, "radius": 9, "armor": 2,
		"desc": "Big, slow and stubborn."},
	"troll": {"name": "Cave Troll", "class": 3, "hp": 600, "speed": 24, "bounty": 24, "radius": 9, "regen": 0.02,
		"desc": "Heals 2% of its HP a second, but not while it burns or acid eats it."},
	"wraith": {"name": "Wraith", "class": 3, "hp": 840, "speed": 38, "bounty": 30, "radius": 7, "invisible": true,
		"desc": "Invisible and quick. A ghost that grew up."},
	"gargoyle": {"name": "Gargoyle", "class": 3, "hp": 960, "speed": 30, "bounty": 32, "radius": 8, "flying": true,
		"armor": 3, "desc": "Stone wings. Flies, and its hide stops weak bullets."},
	"dark_knight": {"name": "Dark Knight", "class": 3, "hp": 1800, "speed": 24, "bounty": 45, "radius": 8,
		"armor": 8, "desc": "Black plate armor. Bring armor piercing, acid or fire."},
	"mammoth": {"name": "War Mammoth", "class": 3, "hp": 3600, "speed": 18, "bounty": 62, "radius": 12,
		"armor": 2, "desc": "A walking wall of fur and tusks."},
	"golem": {"name": "Stone Golem", "class": 4, "hp": 4500, "speed": 15, "bounty": 250, "radius": 12,
		"armor": 2, "desc": "BOSS. Living rock. Shrugs off weak hits."},
	"bone_dragon": {"name": "Bone Dragon", "class": 4, "hp": 18000, "speed": 16, "bounty": 400, "radius": 13,
		"armor": 3, "revive": 0.3, "desc": "BOSS. Falls apart, then gets back up once with 30% HP."},
	"demon": {"name": "Demon Lord", "class": 4, "hp": 30000, "speed": 17, "bounty": 560, "radius": 13,
		"armor": 4, "fire_res": 0.5, "desc": "FINAL BOSS. Lord of the burning pit."},
	"titan": {"name": "Void Titan", "class": 4, "hp": 600000, "speed": 12, "bounty": 2000, "radius": 15,
		"armor": 6, "fire_res": 0.5, "desc": "ULTRACORE BOSS. A giant from the void between the stars."},
}

# ---------------------------------------------------------------- friendly units (sent by the Garage)
# They are Enemy nodes with is_friendly = true: drive backwards along the road and crash into enemies.
# HP and speed come from the garage's stats (car_hp / car_speed).
const VEHICLES := {
	"car": {"name": "Car", "radius": 6, "desc": "Friendly. Crashes into enemies."},
	"pickup": {"name": "Pickup", "radius": 7, "desc": "Friendly. Crashes into enemies."},
	"truck": {"name": "Truck", "radius": 8, "desc": "Friendly. Crashes into enemies."},
	"armored": {"name": "Armored Car", "radius": 8, "desc": "Friendly. Crashes and shoots."},
}

# first wave each enemy may appear in, and its "threat cost" for the wave budget
const POOL := [
	["slime", 1, 1.2], ["rat", 4, 1.0], ["goblin", 5, 2.6], ["bat", 8, 2.2], ["skeleton", 9, 4.2],
	["wolf", 10, 4.5], ["ironclad", 11, 9.0], ["ghost", 12, 7.0], ["imp", 13, 5.5], ["berserker", 15, 11.0],
	["shaman", 16, 17.0], ["slime_king", 19, 36.0], ["harpy", 21, 42.0], ["ogre", 23, 52.0],
	["troll", 26, 90.0], ["wraith", 28, 110.0], ["gargoyle", 30, 125.0], ["dark_knight", 33, 220.0],
	["mammoth", 36, 400.0],
]
# placement limits per battle: all towers together, and per tower type unless the tower sets its own "limit"
const MAX_TOWERS := 50
const MAX_PER_TYPE := 10

# readable names for stats (tower info screens)
const STAT_LABELS := {"damage": "Damage", "rate": "Attacks/s", "range": "Range", "targets": "Targets",
	"slow": "Slow", "slow_time": "Slow time", "armor_pierce": "Armor pierce", "cleave": "Cleave",
	"stun_every": "Stun every N hits", "stun": "Stun time", "burst": "Burst size", "burst_gap": "Burst gap",
	"grenade_every": "Grenade every N bursts", "grenade_dmg": "Grenade dmg", "grenade_radius": "Grenade radius",
	"interval": "Car every (s)", "car_hp": "Car HP",
	"car_speed": "Car speed", "vehicle": "Vehicle", "gun_dmg": "Turret dmg", "gun_rate": "Turret shots/s",
	"cone": "Cone angle", "burn": "Burn dps", "burn_time": "Burn time", "fire_pierce": "Fire res. pierce",
	"headshot": "Headshot chance", "camo": "Sees invisible", "air": "Hits flying",
	"raise_hp": "Undead HP", "raise_class": "Raises up to class",
	"chill": "Chill /s", "chill_slow": "Max slow", "freeze": "Freeze time",
	"acid_dps": "Acid dps", "acid_time": "Acid time", "acid_shred": "Armor eaten", "splash": "Acid splash",
	"dagger_dmg": "Dagger dmg", "dagger_rate": "Daggers/s", "dagger_range": "Dagger range", "daggers": "Daggers",
	"aura": "Aura dmg bonus", "brittle": "Frozen take extra", "lead": "Pierces lead",
	"income": "Money per wave", "min_rate": "Shots/s cold", "max_rate": "Shots/s spun up",
	"spin_time": "Spin-up time"}
const PERCENT_STATS := ["slow", "armor_pierce", "fire_pierce", "headshot", "raise_hp", "chill", "chill_slow", "aura",
	"brittle"]
# level colors: red, yellow, green, blue, purple, pink, and gold for the top level
const RAINBOW := [Color("e43b44"), Color("fee761"), Color("63c74d"), Color("2c9aceff"), Color(0.473, 0.411, 0.962, 1.0),
	Color("f6757a"), Color("feae34")]

# global knobs used for balancing
static var BUDGET_MULT := 1.0
static var HP_GROWTH := 1.0
static var BOUNTY_MULT := 3.5
const BOSS_TYPES := ["golem", "bone_dragon", "demon", "titan"]
const SPACING := {"slime": 0.55, "rat": 0.35, "goblin": 0.6, "wolf": 0.45, "ironclad": 0.9, "imp": 0.6,
	"shaman": 1.4, "slime_king": 1.8, "ogre": 2.2, "golem": 6.0, "demon": 6.0,
	"bat": 0.3, "skeleton": 0.6, "ghost": 0.8, "berserker": 1.1, "harpy": 2.0, "troll": 1.8, "wraith": 1.2,
	"gargoyle": 1.6, "dark_knight": 2.0, "mammoth": 3.0, "bone_dragon": 6.0, "titan": 6.0}


static func enemy_hp_scale(wave: int) -> float:
	return 1.0 + (0.03 * float(wave - 1) + 0.0006 * float((wave - 1) * (wave - 1))) * HP_GROWTH


## Colour of a tower level: red, yellow, green, blue, purple, pink ... and gold for the tower's top level,
## however many levels it has (early towers stop at 5, mid ones at 6).
static func level_color(level: int, top: int) -> Color:
	if level >= top:
		return RAINBOW[RAINBOW.size() - 1]
	return RAINBOW[clampi(level, 0, RAINBOW.size() - 2)]


## Damage per second a tower deals with these stats, all its attacks together (several targets, daggers,
## burn and acid included); 0 for towers that don't attack (Farm, Freezer before Ice Water).
static func tower_dps(t: String, s: Dictionary) -> float:
	match t:
		"gunner":
			return float(s["damage"]) * float(s["rate"]) * float(s["targets"])
		"knight", "sniper", "necro":
			return float(s["damage"]) * float(s["rate"])
		"minigun":   # fully spun up
			return float(s["damage"]) * float(s["max_rate"])
		"soldier":
			var g := float(s["grenade_dmg"]) * float(s["rate"]) / float(s["grenade_every"]) if int(s["grenade_every"]) > 0 else 0.0
			return float(s["damage"]) * float(s["burst"]) * float(s["rate"]) + g
		"garage":   # a car crashes for its HP once per interval, plus the armored car's turret
			return float(s["car_hp"]) / float(s["interval"]) + float(s["gun_dmg"]) * float(s["gun_rate"])
		"flamer":   # the cone hits 10 times a second, then the burn
			return float(s["damage"]) * 10.0 + float(s["burn"])
		"freezer":
			return float(s["damage"]) * 10.0
		"toxic":
			return float(s["damage"]) * float(s["rate"]) + float(s["acid_dps"])
		"assassin":
			return float(s["damage"]) * float(s["rate"]) + float(s["acid_dps"]) + \
				float(s["dagger_dmg"]) * float(s["dagger_rate"]) * float(s["daggers"])
	return 0.0


## Money for clearing a wave: grows fast, late waves pay for the expensive top upgrades (BTD6-style).
static func wave_bonus(wave: int) -> int:
	return roundi(25.0 * pow(float(wave), 1.5) + 100.0 * wave)


## Returns {"spawns": [[time, type], ...], "boss": bool}
static func build_wave(wave: int, total: int, seed_base: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_base * 1000 + wave * 7919
	var spawns: Array = []
	var budget := (6.0 + wave * 2.5 + wave * wave * 0.9) * BUDGET_MULT
	if wave <= 10:
		budget *= 0.55 + 0.045 * wave   # gentle early game
	elif wave > 20:
		budget *= 1.0 + 0.012 * (wave - 20)  # late game pressure
	var boss := false
	# boss waves
	var boss_list: Array = []
	if wave == total:
		if total >= 40:
			boss_list = ["demon"]
		elif total >= 30:
			boss_list = ["golem", "golem"]
		else:
			boss_list = ["golem"]
	elif wave == 20 and total > 20:
		boss_list = ["golem"]
	elif wave == 30 and total > 30:
		boss_list = ["golem", "golem"]
	if boss_list.size() > 0:
		boss = true
		budget *= 0.45
	# early hand-tuned waves
	var t := 0.0
	var avail: Array = []
	for p in POOL:
		if wave >= p[1] and not (wave >= 15 and p[1] <= 5):
			avail.append(p)
	var groups := 1
	if wave >= 4:
		groups = 2
	if wave >= 12:
		groups = 3
	if wave >= 26:
		groups = 4
	var used: Array = []
	for g in groups:
		# prefer newer enemy types, avoid repeating a type inside one wave
		var p: Array = []
		for attempt in 8:
			var idx := avail.size() - 1 - int(pow(rng.randf(), 1.6) * avail.size())
			p = avail[clampi(idx, 0, avail.size() - 1)]
			if not used.has(p[0]) or used.size() >= avail.size():
				break
		used.append(p[0])
		var share := budget / groups
		var count := maxi(1, int(round(share / p[2])))
		count = mini(count, 60)
		var gap: float = SPACING[p[0]] * (0.9 if wave > 20 else (1.6 if wave <= 5 else 1.0))
		for i in count:
			spawns.append([t, p[0]])
			t += gap
		t += 1.2
	for b in boss_list:
		spawns.append([t + 1.0, b])
		t += SPACING[b]
	spawns.sort_custom(func(a, b): return a[0] < b[0])
	return {"spawns": spawns, "boss": boss}
