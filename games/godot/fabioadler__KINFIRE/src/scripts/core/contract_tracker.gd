extends RefCounted
class_name ContractTracker

var hero: Hero
var contract: ContractData
var start_time: float
var progress: Dictionary

func _init(p_hero: Hero, p_contract_id: StringName) -> void:
	hero = p_hero
	# Carregar contrato do Autoload (será gerado se não existir)
	contract = _get_or_generate_contract(p_contract_id)
	if not contract:
		push_error("ContractTracker: Contrato %s não encontrado" % p_contract_id)
		contract = ContractData.new()  # Fallback
	start_time = Time.get_ticks_msec() / 1000.0
	progress = {}

func _get_or_generate_contract(contract_id: StringName) -> ContractData:
	# TODO: Implementar cache de contratos no Autoload Guilds
	# Por enquanto: gera contrato simples
	var c = ContractData.new()
	c.id = contract_id
	c.tipo = ContractData.Type.CACA
	c.regiao = &"planicie"
	c.dificuldade = "F"
	c.tempo_limite_horas = 2.0
	c.requisitos = {"inimigos": 3}
	c.recompensas = {"ouro": 50, "xp": 25}
	c.risco = 1.0
	return c

func is_expired() -> bool:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - start_time
	return elapsed > contract.tempo_limite_horas * 3600.0

func complete() -> void:
	hero.contracts_active.erase(contract.id)
	hero.contracts_completed += 1
	if "ouro" in contract.recompensas:
		hero.gold += int(contract.recompensas["ouro"])
	if "xp" in contract.recompensas:
		hero.add_xp(int(contract.recompensas["xp"]))
