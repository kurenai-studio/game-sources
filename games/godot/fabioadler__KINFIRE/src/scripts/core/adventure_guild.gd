extends Object
class_name AdventureGuild

const CONTRACT_TYPES = [ContractData.Type.CACA, ContractData.Type.COLETA, ContractData.Type.EXPLORACAO, ContractData.Type.ESCOLTA]

static func generate_contract(rank: String, region: StringName, seed: int = 0) -> ContractData:
	var rng := RandomNumberGenerator.new()
	if seed > 0:
		rng.seed = seed
	
	var tipo = CONTRACT_TYPES[rng.randi() % CONTRACT_TYPES.size()]
	var contract := ContractData.new()
	contract.id = StringName("%s_%s_%d" % [tipo, region, seed if seed > 0 else rng.randi()])
	contract.tipo = tipo
	contract.regiao = region
	contract.dificuldade = rank
	contract.tempo_limite_horas = 2.0
	contract.requisitos = {"inimigos": max(1, int(rank_to_difficulty(rank) * 5))}
	contract.recompensas = {"ouro": int(50 * rank_to_difficulty(rank)), "xp": int(25 * rank_to_difficulty(rank))}
	contract.risco = rank_to_difficulty(rank)
	return contract

static func rank_to_difficulty(rank: String) -> float:
	match rank:
		"F": return 1.0
		"E": return 1.5
		"D": return 2.0
		"C": return 2.5
		"B": return 3.0
		"A": return 3.5
		"S": return 4.0
		_: return 1.0

static func validate_contract_complete(hero: Hero, contract_id: StringName) -> bool:
	return true
