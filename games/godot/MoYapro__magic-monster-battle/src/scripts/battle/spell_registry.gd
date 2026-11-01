class_name SpellRegistry

# Single source of truth for all available spells.
# Add new spell classes here — the catalog and any other consumer updates automatically.


static func all_body_spells() -> Array[SpellData]:
	return [
		# Projectiles
		SpellEmber.create(),
		SpellFrost.create(),
		SpellVenom.create(),
		SpellBone.create(),
		SpellLightning.create(),
		# Catalysts
		SpellFireCatalyst.create(),
		SpellForcePush.create(),
		# Modifiers
		SpellAmplify.create(),
		SpellShield.create(),
		SpellCorrupted.create(),
		SpellReactive.create(),
		SpellDistillation.create(),
	]


static func all_tip_spells() -> Array[SpellData]:
	return [
		SpellSingle.create(),
		SpellLine.create(),
		SpellPierce.create(),
		SpellBomb.create(),
		SpellBoltN.create(),
		SpellBoltNE.create(),
		SpellBoltE.create(),
		SpellBoltSE.create(),
		SpellBoltS.create(),
		SpellBoltSW.create(),
		SpellBoltW.create(),
		SpellBoltNW.create(),
	]
