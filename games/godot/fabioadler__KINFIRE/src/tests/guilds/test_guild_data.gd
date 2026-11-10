extends Node
## Testes de GuildData, ContractData, RankData
## Execute com: flatpak run org.godotengine.Godot --headless --path . -s tests/guilds/test_guild_data.gd

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	print("[test_guild] GuildData, ContractData, RankData")
	
	# Test 1: GuildData exists and loads
	var guild = GuildData.new()
	guild.id = &"aventureiros_humano"
	guild.display_name = "Guilda dos Aventureiros"
	guild.tipo = GuildData.Type.AVENTUREIROS
	guild.mestre_npc = &"gareth_aventureiros"
	guild.beneficios = {"contratos_ativos_max": 1}
	
	assert(guild is GuildData, "GuildData object created")
	assert(guild.display_name == "Guilda dos Aventureiros", "GuildData.display_name correct")
	assert(guild.tipo == GuildData.Type.AVENTUREIROS, "GuildData.tipo correct")
	assert(guild.mestre_npc == &"gareth_aventureiros", "GuildData.mestre_npc correct")
	assert("contratos_ativos_max" in guild.beneficios, "GuildData.beneficios populated")
	
	print("[test_guild] GuildData OK")
	
	# Test 2: ContractData
	var contract = ContractData.new()
	contract.id = &"caca_comum_1"
	contract.tipo = ContractData.Type.CACA
	contract.regiao = &"planicie"
	contract.dificuldade = "F"
	contract.tempo_limite_horas = 2.0
	
	assert(contract is ContractData, "ContractData object created")
	assert(contract.tipo == ContractData.Type.CACA, "ContractData.tipo correct")
	assert(contract.dificuldade == "F", "ContractData.dificuldade correct")
	
	print("[test_guild] ContractData OK")
	
	# Test 3: RankData
	var rank = RankData.new()
	rank.rank_letter = "E"
	rank.nivel_minimo = 1
	rank.titulo = "Aprendiz"
	
	assert(rank is RankData, "RankData object created")
	assert(rank.rank_letter == "E", "RankData.rank_letter correct")
	assert(rank.titulo == "Aprendiz", "RankData.titulo correct")
	
	print("[test_guild] RankData OK")
	
	print("[test_guild] PASS — all structures working")
	get_tree().quit()
