class_name UpgradeCatalog
extends RefCounted
## Every upgrade in Shiftborn. Level-up offers come from the active form's
## tag plus the untagged (shared) upgrades. [UpgradeEffects] applies them.
## Numbers in descriptions must match the steps in [UpgradeEffects].

const KNIGHT_TAG := "knight"
const MAGE_TAG := "mage"
const ICON_DIR := "res://assets/ninja/icons/"

const ENTRIES: Array[Dictionary] = [
	# Knight: four stats, two behaviours.
	{id = &"knight_damage", title = "Honed Edge", text = "Axe damage +25%", icon = "AttackUpgrade", max = 5, tag = KNIGHT_TAG},
	{id = &"knight_reach", title = "Long Haft", text = "Axe reach +15%", icon = "Cut", max = 5, tag = KNIGHT_TAG},
	{id = &"knight_haste", title = "Quick Spin", text = "Spin 12% more often", icon = "Counter", max = 5, tag = KNIGHT_TAG},
	{id = &"knight_lifesteal", title = "Vampiric Edge", text = "Heal 0.25 HP per axe hit", icon = "Necromancy", max = 3, tag = KNIGHT_TAG},
	{id = &"knight_twin_blade", title = "Twin Axe", text = "One more axe per spin", icon = "MagicWeapon", max = 2, tag = KNIGHT_TAG},
	{id = &"knight_knockback", title = "Heavy Swing", text = "Axe hits knock enemies back", icon = "Punch", max = 3, tag = KNIGHT_TAG},
	# Mage: four stats, two behaviours.
	{id = &"mage_damage", title = "Arcane Power", text = "Bolt damage +25%", icon = "Fireball", max = 5, tag = MAGE_TAG},
	{id = &"mage_haste", title = "Swift Casting", text = "Cast 15% more often", icon = "BookWind", max = 5, tag = MAGE_TAG},
	{id = &"mage_range", title = "Far Sight", text = "Targeting range +20%", icon = "Vision", max = 3, tag = MAGE_TAG},
	{id = &"mage_pierce", title = "Piercing Bolt", text = "Bolts pass through +1 enemy", icon = "Arrow", max = 3, tag = MAGE_TAG},
	{id = &"mage_multishot", title = "Split Bolt", text = "Cast one more bolt", icon = "Shuriken", max = 3, tag = MAGE_TAG},
	{id = &"mage_chain", title = "Chain Spark", text = "Bolts jump to +1 nearby enemy", icon = "BookThunder", max = 3, tag = MAGE_TAG},
	# Shared.
	{id = &"vitality", title = "Vitality", text = "Max HP +25% and heal the gain", icon = "DefenseUpgrade", max = 5, tag = ""},
	{id = &"swiftness", title = "Swiftness", text = "Move speed +10%", icon = "Boot", max = 5, tag = ""},
	{id = &"regen", title = "Regeneration", text = "Recover 0.3 HP per second", icon = "Heal", max = 3, tag = ""},
	{id = &"shift_burst", title = "Shift Burst", text = "Shifting blasts nearby enemies for 4 damage (every 2s)", icon = "Explosion", max = 3, tag = ""},
	{id = &"precision", title = "Precision", text = "Critical hit chance +8% (crits deal x2)", icon = "LuckUpgrade", max = 5, tag = ""},
	{id = &"momentum", title = "Momentum", text = "+20% damage for 2s after a shift", icon = "Sun", max = 3, tag = ""},
	# Evolutions: offered in both forms once both upgrades they need are
	# maxed. Their attacks ignore resistances.
	{id = &"evo_arcane_orbit", title = "Arcane Orbit", text = "Three magic orbs circle you in both forms", icon = "OrbLight", max = 1, tag = "", needs = [&"knight_twin_blade", &"mage_multishot"]},
	{id = &"evo_storm_cleaver", title = "Storm Cleaver", text = "Axe hits arc lightning to 2 enemies. Bolts knock back", icon = "Rain", max = 1, tag = "", needs = [&"knight_knockback", &"mage_chain"]},
	{id = &"evo_blood_pact", title = "Blood Pact", text = "Bolts steal life too. +25% damage at full HP", icon = "BookDeath", max = 1, tag = "", needs = [&"knight_lifesteal", &"mage_damage"]},
	{id = &"evo_twin_soul", title = "Twin Soul", text = "Shift Burst doubles in size and unleashes the new form's attack", icon = "Permutation", max = 1, tag = "", needs = [&"shift_burst", &"momentum"]},
]
## Evolutions are rare to unlock, so once ready they come up often.
const EVOLUTION_WEIGHT := 4.0


static func build() -> Array[Upgrade]:
	var upgrades: Array[Upgrade] = []
	for entry in ENTRIES:
		var upgrade := Upgrade.new()
		upgrade.id = entry.id
		upgrade.title = entry.title
		upgrade.description = entry.text
		upgrade.icon = load(ICON_DIR + entry.icon + ".png")
		upgrade.max_level = entry.max
		if entry.tag != "":
			upgrade.tags = PackedStringArray([entry.tag])
		if entry.has("needs"):
			upgrade.requires_maxed.assign(entry.needs)
			upgrade.weight = EVOLUTION_WEIGHT
		upgrades.append(upgrade)
	return upgrades


## Tag filter for [method UpgradePool.offer] while in [param form].
static func tags_for_form(form: Player.Form) -> PackedStringArray:
	return PackedStringArray([KNIGHT_TAG if form == Player.Form.KNIGHT else MAGE_TAG])
