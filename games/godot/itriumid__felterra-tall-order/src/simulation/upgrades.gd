class_name Upgrades
extends RefCounted
## What a level-up card can offer, and what each does. A card offers three choices, each a kind
## of upgrade at a rarity; rarity changes only how much it gives, never what it does.

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Legendary"]
## How much each tier gives, against a common one.
const AMOUNTS: Array[float] = [1.0, 1.6, 2.4, 3.5]
## How often each tier turns up, before luck.
const WEIGHTS: Array[float] = [60.0, 28.0, 10.0, 2.0]
const CHOICES := 3
## Weapons take levels up to WEAPON_TOP, then evolve along their family, or at the last of it
## take mastery; gear takes levels up to GEAR_TOP, then mastery. Two tracks, tuned apart.
const WEAPON_TOP := 10
const GEAR_TOP := 5

## Stats come from what he wears, never on their own: each piece of gear gives some, and more
## with each level. What each stat is called and what it does, in one line.
const STATS := {
	"health": {"name": "Health", "explain": "How much he can take before he's down", "format": "+%d health"},
	"armor": {"name": "Armor", "explain": "Each hit takes this much less", "format": "+%.1f armor"},
	"regeneration": {"name": "Regeneration", "explain": "Health that comes back on its own, every second", "format": "+%.2f regeneration"},
	"adrenaline": {"name": "Adrenaline", "explain": "A share of the damage he deals comes back to him as health", "format": "+%d%% adrenaline"},
	"damage": {"name": "Damage", "explain": "Every weapon he holds hits harder", "format": "+%d%% damage"},
	"attack_speed": {"name": "Attack speed", "explain": "Every weapon fires and swings sooner", "format": "+%d%% attack speed"},
	"reach": {"name": "Reach", "explain": "Guns reach further, blades reach longer", "format": "+%d%% reach"},
	"speed": {"name": "Speed", "explain": "He runs faster", "format": "+%d%% speed"},
	"luck": {"name": "Luck", "explain": "Rarer cards turn up more often", "format": "+%.1f luck"},
	"critical": {"name": "Critical hits", "explain": "A chance for a hit to land twice as hard", "format": "+%d%% critical"},
	"knockback": {"name": "Knockback", "explain": "Every hit shoves harder", "format": "+%d%% knockback"},
}
## Stats that most players won't know: a card marks them as worth reading in full.
const UNFAMILIAR: Array[String] = ["adrenaline", "regeneration", "luck", "critical"]
## Gear, by id: the slot it's worn in, and what a common level of it gives.
const GEAR := {
	"vest": {"name": "Vest", "slot": "body", "stats": {"armor": 0.4, "health": 2.0}},
	"hard_hat": {"name": "Hard hat", "slot": "head", "stats": {"armor": 0.3, "health": 2.0}},
	"caping": {"name": "Conical hat", "slot": "head", "stats": {"regeneration": 0.05, "luck": 0.3}},
	"bell_collar": {"name": "Bell collar", "slot": "neck", "stats": {"luck": 0.6}},
	"scarf": {"name": "Red scarf", "slot": "neck", "stats": {"speed": 0.06}},
	"goggles": {"name": "Goggles", "slot": "eyes", "stats": {"reach": 0.08}},
	"gloves": {"name": "Gloves", "slot": "paws", "stats": {"damage": 0.1, "attack_speed": 0.05}},
	"boots": {"name": "Boots", "slot": "feet", "stats": {"speed": 0.05, "armor": 0.1}},
	"jamu_flask": {"name": "Herbal flask", "slot": "waist", "stats": {"adrenaline": 0.03}},
	"peci": {"name": "Velvet cap", "slot": "head", "stats": {"luck": 0.4, "health": 1.0}},
	"batik_shirt": {"name": "Batik shirt", "slot": "body", "stats": {"health": 3.0, "luck": 0.2}},
	"raincoat": {"name": "Raincoat", "slot": "body", "stats": {"armor": 0.6}},
	"headlamp": {"name": "Headlamp", "slot": "eyes", "stats": {"reach": 0.1}},
	"sunglasses": {"name": "Sunglasses", "slot": "eyes", "stats": {"critical": 0.04}},
	"bandana": {"name": "Bandana", "slot": "neck", "stats": {"attack_speed": 0.05}},
	"wristbands": {"name": "Wristbands", "slot": "paws", "stats": {"knockback": 0.15, "damage": 0.05}},
	"rubber_boots": {"name": "Rubber boots", "slot": "feet", "stats": {"armor": 0.25}},
	"sandals": {"name": "Sandals", "slot": "feet", "stats": {"speed": 0.07}},
	"sarong": {"name": "Sarong", "slot": "waist", "stats": {"speed": 0.03, "armor": 0.2}},
	"tool_belt": {"name": "Tool belt", "slot": "waist", "stats": {"attack_speed": 0.06}},
	"batik_headcloth": {"name": "Batik headcloth", "slot": "head", "stats": {"luck": 0.3, "attack_speed": 0.03}},
	"ear_defenders": {"name": "Ear defenders", "slot": "head", "stats": {"armor": 0.35}},
	"life_jacket": {"name": "Life jacket", "slot": "body", "stats": {"health": 4.0}},
	"kebaya": {"name": "Lace blouse", "slot": "body", "stats": {"regeneration": 0.06, "luck": 0.2}},
	"lanyard": {"name": "Company lanyard", "slot": "neck", "stats": {"critical": 0.03, "luck": 0.2}},
	"prayer_beads": {"name": "Prayer beads", "slot": "neck", "stats": {"regeneration": 0.05, "adrenaline": 0.01}},
	"safety_glasses": {"name": "Safety glasses", "slot": "eyes", "stats": {"armor": 0.15, "reach": 0.05}},
	"gem_rings": {"name": "Gem rings", "slot": "paws", "stats": {"luck": 0.5, "critical": 0.02}},
	"rattan_bracers": {"name": "Rattan bracers", "slot": "paws", "stats": {"armor": 0.2, "knockback": 0.12}},
	"wooden_clogs": {"name": "Wooden clogs", "slot": "feet", "stats": {"knockback": 0.15, "damage": 0.04}},
	"fighting_sash": {"name": "Fighting sash", "slot": "waist", "stats": {"damage": 0.06, "critical": 0.02}},
}
const SLOTS: Array[String] = ["head", "body", "neck", "eyes", "paws", "feet", "waist"]
## Weapons a card can hand him, if he has his mouth or his tail free for them.
## A weapon a family grows into isn't offered on its own: it's reached by evolving.
const WEAPONS: Array[String] = [
	"nunchaku", "knife", "handgun", "machete", "rifle", "shotgun", "grenade_launcher", "nail_gun", "flare_gun",
	"crossbow", "lamp_oil", "golok", "celurit", "rattan_staff", "ketapel", "sumpit", "petasan",
	"tombak", "bambu_runcing", "mandau", "rencong", "badik", "kujang", "panah",
]
const WEAPON_NAMES := {
	"nunchaku": "Nunchaku", "knife": "Knife", "keris": "Kris", "kerambit": "Karambit",
	"handgun": "Handgun", "submachine_gun": "Submachine gun",
	"machete": "Machete", "greatsword": "Greatsword", "rifle": "Rifle", "automatic_rifle": "Automatic rifle",
	"assault_rifle": "Assault rifle", "sniper_rifle": "Sniper rifle", "shotgun": "Shotgun",
	"grenade_launcher": "Grenade launcher", "nail_gun": "Nail gun", "flare_gun": "Flare gun",
	"crossbow": "Crossbow", "lamp_oil": "Lamp oil", "golok": "Golok", "celurit": "Sickle",
	"rattan_staff": "Rattan staff", "ketapel": "Slingshot", "sumpit": "Blowpipe", "petasan": "Firecrackers",
	"tombak": "Spear", "bambu_runcing": "Bamboo spear", "mandau": "Mandau", "rencong": "Rencong",
	"badik": "Badik", "kujang": "Kujang", "panah": "Bow",
}
## What each weapon does, in a line, for a card read in full and for the smithy.
const WEAPON_DOES := {
	"nunchaku": "Two sticks on a chain, swung most of the way round him; blunt, it shoves more than it cuts",
	"knife": "Close and quick, and it never runs out",
	"keris": "The knife grown up: a longer, harder wavy blade",
	"kerambit": "A curved claw blade: very fast, very close",
	"handgun": "Slow, but it reaches",
	"submachine_gun": "Fast and loose: many light rounds",
	"machete": "A broad blade, quick and wide",
	"greatsword": "Two-handed: slow, very wide, very hard, and it throws what it hits",
	"rifle": "Long, hard-hitting rounds",
	"automatic_rifle": "The rifle firing fast and loose",
	"assault_rifle": "Two-handed: faster still, and further",
	"sniper_rifle": "Two-handed: slow and very long; a round goes through four in a line",
	"shotgun": "Two-handed: seven pellets in a cone, close",
	"grenade_launcher": "Two-handed: lobs a grenade that bursts a meter wide",
	"nail_gun": "Fast and short; nails that miss stay where they land, in the next foot on them",
	"flare_gun": "One bright, slow shot that sets what it hits alight",
	"crossbow": "Two-handed: slow, and a bolt goes through one and into the next",
	"lamp_oil": "Thrown: the oil burns where it lands, setting alight what stands in it",
	"golok": "A heavy chopping blade: slower, harder",
	"celurit": "A sickle: hooks a leg and trips what it hits",
	"rattan_staff": "Two-handed: a full sweep around him, with heavy knockback",
	"ketapel": "Stones that glance off one into the next, twice",
	"sumpit": "Darts that poison and slow",
	"petasan": "Thrown: they land and pop, four times",
	"tombak": "Two-handed: a long thrust in a straight line",
	"bambu_runcing": "Two-handed: a long thrust; it breaks after fourteen hits, and he sharpens another",
	"mandau": "Heavy, wide swings",
	"rencong": "A quick thrust, not a swing",
	"badik": "Short, and deadly up close",
	"kujang": "Its hooked edge pulls what it catches in toward him",
	"panah": "Arrows lobbed over the horde, each going through one",
}
## Support, by id: what he carries on his back, and the slot it takes there.
const SUPPORT := {
	"gun_drone": {"name": "Gun drone", "lines": ["A drone on his pack", "Flies out and fires"]},
	"meriam_bambu": {"name": "Bamboo cannon", "lines": ["A bamboo cannon", "Set down, it lobs stones"]},
	"mines": {"name": "Mines", "lines": ["Pouches of mines", "Dropped as they close"]},
	"net_drone": {"name": "Net drone", "lines": ["A drone with nets", "Holds them down"]},
	"layang_layang": {"name": "Fighting kite", "lines": ["A fighting kite", "Its string cuts"]},
	"ranjau_bambu": {"name": "Bamboo spikes", "lines": ["A bed of bamboo spikes", "Set down as they close"]},
	"radio": {"name": "Radio", "lines": ["A loud radio", "The horde goes to it"]},
	"bee_swarm": {"name": "Bee swarm", "lines": ["A hive on his pack", "Its bees sting and slow"]},
	"alarm_drum": {"name": "Alarm drum", "lines": ["A bamboo drum", "Each beat throws them"]},
	"snare": {"name": "Snare", "lines": ["A rattan snare", "Holds the first foot"]},
}
## What each support slot is called on a card.
const SUPPORT_SLOT_NAMES := {"drone": "drone", "set_down": "set-down"}
## What a weapon at the top level can become: the families it evolves along. A weapon not listed
## is the last of its family, and takes mastery from there.
const EVOLVES := {
	"knife": ["keris"], "keris": ["kerambit"], "handgun": ["submachine_gun"],
	"machete": ["greatsword"], "rifle": ["automatic_rifle", "sniper_rifle"], "automatic_rifle": ["assault_rifle"],
}
## Dodge mutations: each changes what the dodge does. A cat takes up to Cat.MOST_MUTATIONS a run,
## and a card for one he has strengthens it. What each is called, and what it does in one line.
const MUTATIONS := {
	"rolling_slash": {"name": "Rolling slash", "explain": "The roll cuts what it passes through, harder the faster he rolls"},
	"pounce": {"name": "Pounce", "explain": "As the roll ends, he leaps onto the nearest enemy, over the horde"},
	"ankle_cutter": {"name": "Ankle cutter", "explain": "Rolling between a giant's legs cuts a share of his health"},
	"land_on_feet": {"name": "Land on your feet", "explain": "Knocked off his feet, he rolls out of it, for free"},
	"more_charges": {"name": "More charges", "explain": "Dodges he can hold; a rarer card brings them back faster"},
	"long_leap": {"name": "Long leap", "explain": "The roll leaves the ground: over rats, and over a chainsaw's sweep"},
	"riposte": {"name": "Riposte", "explain": "A hit dodged just as it lands, he answers at once"},
	"lick_your_wounds": {"name": "Lick your wounds", "explain": "Each roll heals a little, up to so much a minute"},
	"caltrops": {"name": "Caltrops", "explain": "The roll scatters caltrops behind him that lame the feet on them"},
	"slipstream": {"name": "Slipstream", "explain": "Rolling past a crewmate speeds them up a while"},
	"dust_cloud": {"name": "Dust cloud", "explain": "The roll kicks up dust, and the horde in it stops to cough"},
	"scent_trail": {"name": "Scent trail", "explain": "Where he rolls from, his scent lingers, and the horde goes to it"},
	"chain_roll": {"name": "Chain roll", "explain": "A kill during a roll gives back part of a charge, once a roll"},
}
## Past the top level, mastery: unlimited levels, each worth this share of an ordinary one. It's
## what lets a long run keep growing.
const MASTERY := 0.5
## What a level gives a weapon, before rarity.
const LEVEL_DAMAGE := 0.15
const LEVEL_TEMPO := 0.08


## A rarity, rolled. Luck moves the odds toward the rarer tiers.
static func roll_rarity(random: RandomNumberGenerator, luck: float) -> int:
	var weights: Array[float] = []
	var total := 0.0
	for tier in WEIGHTS.size():
		var weight: float = WEIGHTS[tier] * (1.0 + luck * tier * 0.5)
		weights.append(weight)
		total += weight
	var roll := random.randf() * total
	for tier in weights.size():
		roll -= weights[tier]
		if roll <= 0.0:
			return tier
	return Rarity.COMMON


## Everything that could be offered to a cat right now, by id: gear for a free slot, a level for
## gear or a weapon he has, or a weapon for his mouth or his tail, whichever's free.
static func available(cat: Cat) -> Array[String]:
	var ids: Array[String] = []
	for id: String in GEAR:
		var slot: String = GEAR[id].slot
		if cat.gear.get(slot, "") == id:
			ids.append(("gear_level:" if cat.gear_levels.get(id, 1) < GEAR_TOP else "gear_mastery:") + id)
		elif cat.gear.get(slot, "") == "":
			ids.append("gear:" + id)
	var holds_used := 0
	for weapon in cat.weapons:
		holds_used += weapon.hands
		if weapon.level < WEAPON_TOP:
			ids.append("level:" + weapon.name)
		elif EVOLVES.has(weapon.name):
			# A family can branch: a card for each way it can grow.
			for grown: String in EVOLVES[weapon.name]:
				ids.append("evolve:" + weapon.name + ("" if grown == EVOLVES[weapon.name][0] else ">" + grown))
		else:
			ids.append("mastery:" + weapon.name)
	for support_name: String in SUPPORT:
		var slot: String = Support.SLOTS[support_name]
		var held: Support = cat.supports.get(slot)
		if held == null:
			ids.append("support:" + support_name)
		elif held.name == support_name:
			ids.append(("support_level:" if held.level < WEAPON_TOP else "support_mastery:") + support_name)
	for mutation: String in MUTATIONS:
		if cat.has(mutation):
			ids.append("mutation_up:" + mutation)
		elif cat.mutations.size() < Cat.MOST_MUTATIONS:
			ids.append("mutation:" + mutation)
	for weapon_name in WEAPONS:
		var family_held := cat.weapons.any(func(weapon: Weapon) -> bool: return _family(weapon.name) == _family(weapon_name))
		if not family_held and holds_used + Weapon.named(weapon_name).hands <= Cat.HOLDS:
			ids.append("weapon:" + weapon_name)
	return ids.filter(func(id: String) -> bool: return not cat.banished.has(id) and not id in cat.locked)


## The first weapon of a family: a keris is a knife that grew up.
static func _family(weapon_name: String) -> String:
	for from: String in EVOLVES:
		if weapon_name in EVOLVES[from]:
			return _family(from)
	return weapon_name


## What an evolve card grows a weapon into: the first of its family's next, unless it names one.
static func evolves_into(id: String) -> String:
	var from := id.get_slice(":", 1)
	if from.contains(">"):
		return from.get_slice(">", 1)
	return EVOLVES[from][0]


static func evolves_from(id: String) -> String:
	return id.get_slice(":", 1).get_slice(">", 0)


## A fresh offer of three different choices, as [{id, rarity}].
static func offer(cat: Cat, random: RandomNumberGenerator, leaving_out: Array[String] = []) -> Array[Dictionary]:
	var pool := available(cat).filter(func(id: String) -> bool: return not id in leaving_out)
	var choices: Array[Dictionary] = []
	while choices.size() < CHOICES and not pool.is_empty():
		var id: String = pool.pop_at(random.randi_range(0, pool.size() - 1))
		choices.append({"id": id, "rarity": roll_rarity(random, cat.luck)})
	return choices


static func apply(cat: Cat, choice: Dictionary) -> void:
	var id: String = choice.id
	var amount: float = AMOUNTS[choice.rarity]
	if id.begins_with("gear"):
		var gear_id := id.get_slice(":", 1)
		var gear: Dictionary = GEAR[gear_id]
		var share := 1.0
		if id.begins_with("gear:"):
			cat.gear[gear.slot] = gear_id
			cat.gear_levels[gear_id] = 1
		else:
			cat.gear_levels[gear_id] = cat.gear_levels.get(gear_id, 1) + 1
			if id.begins_with("gear_mastery:"):
				share = MASTERY
		for stat: String in gear.stats:
			cat.raise(stat, gear.stats[stat] * amount * share)
	elif id.begins_with("level:") or id.begins_with("mastery:"):
		var share := MASTERY if id.begins_with("mastery:") else 1.0
		for weapon in cat.weapons:
			if weapon.name == id.get_slice(":", 1):
				weapon.level += 1
				weapon.power += LEVEL_DAMAGE * amount * share
				weapon.tempo += LEVEL_TEMPO * amount * share
	elif id.begins_with("evolve:"):
		for index in cat.weapons.size():
			var old: Weapon = cat.weapons[index]
			if old.name != evolves_from(id):
				continue
			# It keeps everything its levels gave it, and rarity adds a little more.
			var grown := Weapon.named(evolves_into(id))
			grown.power = old.power + LEVEL_DAMAGE * (amount - 1.0)
			grown.tempo = old.tempo + LEVEL_TEMPO * (amount - 1.0)
			cat.weapons[index] = grown
	elif id.begins_with("support:"):
		var support := Support.named(id.trim_prefix("support:"))
		# A rarer find comes better made, as a weapon does.
		for tier in choice.rarity:
			support.level += 1
			support.power += LEVEL_DAMAGE
			support.tempo += LEVEL_TEMPO
		cat.supports[support.slot] = support
	elif id.begins_with("support_level:") or id.begins_with("support_mastery:"):
		var support: Support = cat.supports[Support.SLOTS[id.get_slice(":", 1)]]
		var share := MASTERY if id.begins_with("support_mastery:") else 1.0
		support.level += 1
		support.power += LEVEL_DAMAGE * amount * share
		support.tempo += LEVEL_TEMPO * amount * share
	elif id.begins_with("mutation"):
		var mutation := id.get_slice(":", 1)
		cat.mutations[mutation] = cat.strength(mutation) + amount
		cat.mutation_cards[mutation] = cat.mutation_cards.get(mutation, 0) + 1
		if mutation == "more_charges":
			# The new charge comes ready.
			cat.dodge_charges += 1.0
	elif id.begins_with("weapon:"):
		var weapon := Weapon.named(id.trim_prefix("weapon:"))
		# A rarer find comes better made: a level up for each tier above common.
		for tier in choice.rarity:
			weapon.level += 1
			weapon.power += LEVEL_DAMAGE
			weapon.tempo += LEVEL_TEMPO
		cat.weapons.append(weapon)


## A choice as a card shows it: {name, kind, lines (what it gives), explain (what those mean),
## unfamiliar (whether any of it is worth reading in full), item (the gear or weapon it is)}.
## A card, as it's shown: its name, what it gives in a line or two, what that means (read with Tab),
## and where the thing came from, its story.
static func describe(choice: Dictionary) -> Dictionary:
	var card := _describe(choice)
	card.story = Lore.of(card.kind, card.item)
	card.does = _does(card)
	return card


## What a thing does, in a line, wherever it's shown off the cards: a weapon's way of fighting, a
## piece of gear's stats, a support's job, a mutation's change to the dodge.
static func _does(card: Dictionary) -> String:
	match card.kind:
		"weapon": return WEAPON_DOES.get(card.item, "")
		"gear":
			var gives: Array[String] = []
			for stat: String in GEAR[card.item].stats:
				gives.append(_amount_text(STATS[stat].format, GEAR[card.item].stats[stat]))
			return "Worn on his %s: %s" % [GEAR[card.item].slot, ", ".join(gives)]
		"support": return "%s, %s" % [SUPPORT[card.item].lines[0], (SUPPORT[card.item].lines[1] as String).to_lower()]
		"mutation": return MUTATIONS[card.item].explain
	return ""


static func _describe(choice: Dictionary) -> Dictionary:
	var id: String = choice.id
	var amount: float = AMOUNTS[choice.rarity]
	var card := {"lines": [], "explain": [], "unfamiliar": false, "item": "", "kind": ""}
	if id.begins_with("gear"):
		var gear_id := id.get_slice(":", 1)
		var gear: Dictionary = GEAR[gear_id]
		var mastery := id.begins_with("gear_mastery:")
		card.item = gear_id
		card.kind = "gear"
		card.name = gear.name if id.begins_with("gear:") else gear.name + (" mastery" if mastery else " up")
		for stat: String in gear.stats:
			card.lines.append(_amount_text(STATS[stat].format, gear.stats[stat] * amount * (MASTERY if mastery else 1.0)))
			card.explain.append("%s: %s" % [STATS[stat].name, STATS[stat].explain])
			card.unfamiliar = card.unfamiliar or stat in UNFAMILIAR
		if mastery:
			card.explain.append("Mastery: past level %d, there's no limit; each is worth half a level" % GEAR_TOP)
	elif id.begins_with("evolve:"):
		var from := evolves_from(id)
		card.item = evolves_into(id)
		card.kind = "weapon"
		card.name = WEAPON_NAMES[card.item]
		card.lines = ["The %s evolves" % WEAPON_NAMES[from].to_lower(), "Keeps all its levels"]
		card.explain = ["%s: %s" % [card.name, WEAPON_DOES[card.item]], "Evolving: at level %d a weapon can grow into the next of its family" % WEAPON_TOP]
	elif id.begins_with("level:") or id.begins_with("mastery:"):
		var mastery := id.begins_with("mastery:")
		var share := MASTERY if mastery else 1.0
		card.item = id.get_slice(":", 1)
		card.kind = "weapon"
		card.name = WEAPON_NAMES[card.item] + (" mastery" if mastery else " up")
		card.lines = ["+%d%% damage" % roundi(LEVEL_DAMAGE * amount * share * 100.0), "+%d%% attack speed" % roundi(LEVEL_TEMPO * amount * share * 100.0)]
		if mastery:
			card.explain = ["Mastery: past level %d, there's no limit; each is worth half a level" % WEAPON_TOP]
			return card
		card.explain = ["Weapon levels: each raises its damage and attack speed; at level %d it evolves" % WEAPON_TOP]
	elif id.begins_with("support"):
		var support_name := id.get_slice(":", 1)
		card.item = support_name
		card.kind = "support"
		var slot_name: String = SUPPORT_SLOT_NAMES[Support.SLOTS[support_name]]
		if id.begins_with("support:"):
			card.name = SUPPORT[support_name].name
			card.lines = (SUPPORT[support_name].lines as Array).duplicate()
			card.explain = ["Support: on his back, one drone and one thing set down; this is his %s" % slot_name]
		else:
			var mastery := id.begins_with("support_mastery:")
			var share := MASTERY if mastery else 1.0
			card.name = SUPPORT[support_name].name + (" mastery" if mastery else " up")
			card.lines = ["+%d%% damage" % roundi(LEVEL_DAMAGE * amount * share * 100.0), "+%d%% attack speed" % roundi(LEVEL_TEMPO * amount * share * 100.0)]
			card.explain = ["Support levels: each raises its damage and how often it fires"]
			if mastery:
				card.explain.append("Mastery: past level %d, there's no limit; each is worth half a level" % WEAPON_TOP)
	elif id.begins_with("mutation"):
		var mutation := id.get_slice(":", 1)
		card.item = mutation
		card.kind = "mutation"
		card.name = MUTATIONS[mutation].name + ("" if id.begins_with("mutation:") else " up")
		card.lines = _mutation_lines(mutation, amount, id.begins_with("mutation:"))
		card.explain = ["%s: %s" % [MUTATIONS[mutation].name, MUTATIONS[mutation].explain],
			"Dodge mutations: %d a run; another card for one makes it stronger" % Cat.MOST_MUTATIONS]
		card.unfamiliar = true
	else:
		card.item = id.trim_prefix("weapon:")
		card.kind = "weapon"
		card.name = WEAPON_NAMES[card.item]
		card.lines = ["A new weapon", "Level %d" % (1 + choice.rarity)]
		card.explain = ["%s: %s" % [card.name, WEAPON_DOES[card.item]], "Mouth and tail: a weapon takes one; a two-handed one takes both"]
	return card


## What a card for a mutation gives, at its rarity's amount, in two short lines: what it does, for
## a new one, or what it adds, for one he has.
static func _mutation_lines(mutation: String, amount: float, fresh: bool) -> Array:
	var leap_time := 2.0 * Cat.LEAP_LIFT / Body.GRAVITY
	match mutation:
		"rolling_slash":
			return ["The roll cuts" if fresh else "Sharper", "%s%.1f damage a cut" % ["" if fresh else "+", Cat.SLASH_DAMAGE * amount]]
		"pounce":
			return ["Ends in a pounce" if fresh else "Harder", "%s%.1f damage landing" % ["" if fresh else "+", Cat.POUNCE_DAMAGE * amount]]
		"ankle_cutter":
			return ["Roll through his legs" if fresh else "Deeper", "%s%d%% of his health" % ["" if fresh else "+", roundi(Cat.ANKLE_SHARE * amount * 100.0)]]
		"land_on_feet":
			if fresh:
				return ["Knocked, he rolls", "Safe for %.2f seconds" % (Cat.RECOVER_SAFE_TIME + Cat.RECOVER_SAFE_GROWTH * amount)]
			return ["Safer", "+%.2f seconds safe" % (Cat.RECOVER_SAFE_GROWTH * amount)]
		"more_charges":
			if amount > 1.0:
				return ["+1 dodge charge", "Recharge %d%% faster" % roundi(Cat.RECHARGE_GROWTH * (amount - 1.0) * 100.0)]
			return ["+1 dodge charge"]
		"long_leap":
			if fresh:
				return ["The roll is a leap", "%.1f meters long" % (Cat.DODGE_SPEED * (Cat.LEAP_SPEED + Cat.LEAP_GROWTH * amount) * leap_time)]
			return ["Further", "+%.1f meters" % (Cat.DODGE_SPEED * Cat.LEAP_GROWTH * amount * leap_time)]
		"riposte":
			return ["Dodge as a hit lands" if fresh else "Sharper", "%s%.1f damage back" % ["" if fresh else "+", Cat.RIPOSTE_DAMAGE * amount]]
		"lick_your_wounds":
			return ["Rolling heals" if fresh else "Heals more", "%s%.1f health a roll" % ["" if fresh else "+", Cat.LICK_HEAL * amount]]
		"caltrops":
			return ["Caltrops behind him" if fresh else "Sharper", "%s%.1f damage each" % ["" if fresh else "+", Cat.CALTROP_DAMAGE * amount]]
		"slipstream":
			return ["Speeds up his crew" if fresh else "Faster", "%s%d%% speed" % ["" if fresh else "+", roundi(Cat.SLIPSTREAM_SPEED * amount * 100.0)]]
		"dust_cloud":
			return ["The roll raises dust" if fresh else "Thicker", "%s%.1f seconds coughing" % ["" if fresh else "+", Cat.DUST_TIME * amount]]
		"scent_trail":
			return ["Leaves his scent" if fresh else "Stronger", "%s%.1f seconds" % ["" if fresh else "+", Cat.SCENT_TIME * amount]]
		"chain_roll":
			return ["A kill, a charge back" if fresh else "More back", "%s%d%% of a charge" % ["" if fresh else "+", roundi(minf(Cat.CHAIN_SHARE * amount, 1.0) * 100.0)]]
	return []


static func _amount_text(text: String, value: float) -> String:
	# Shares read as percentages; the rest as they are.
	if text.contains("%d%%"):
		return text % roundi(value * 100.0)
	if text.contains("%d"):
		return text % roundi(value)
	return text % value
