extends Object
class_name ShadowGuild

const SAFEHOUSE_LOCATIONS = [&"porto_franco_oculto", &"colinas_escuras_santuario"]

static func get_safehouse_locations() -> Array[StringName]:
	return SAFEHOUSE_LOCATIONS.duplicate()

static func get_contract(hero: Hero) -> ContractData:
	if hero.guild_joined != &"sombras":
		return null
	var contract = ContractData.new()
	contract.tipo = ContractData.Type.CACA
	return contract
