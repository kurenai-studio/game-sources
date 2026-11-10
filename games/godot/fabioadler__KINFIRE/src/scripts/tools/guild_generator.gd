extends Node

const CLASSES = [
	"humano", "barbaro", "alto_elfo", "elfo_floresta", "drow",
	"anao_montanha", "anao_colinas", "halfling", "meio_orc", "tiefling",
	"draconato", "gnomo", "meio_elfo", "tabaxi"
]

const GUILD_TYPES = ["aventureiros", "mercadores", "artesaos", "sombras"]

const GUILD_CONFIG = {
	"aventureiros": {
		"display_name": "Guilda dos Aventureiros",
		"mestre_npc": "gareth_aventureiros",
		"beneficios": {
			"contratos_ativos_max": 1,
			"desconto_leilao": 0.0
		}
	},
	"mercadores": {
		"display_name": "Guilda dos Mercadores",
		"mestre_npc": "matthias_mercadores",
		"beneficios": {
			"venda_preco_bonus": 0.20,
			"leilao_slots_bonus": 2,
			"emprestimo_disponivel": true
		}
	},
	"artesaos": {
		"display_name": "Guilda dos Artesãos",
		"mestre_npc": "elara_artesaos",
		"beneficios": {
			"crafting_velocidade": 0.85,
			"crafting_custo_material": 0.90
		}
	},
	"sombras": {
		"display_name": "Guilda das Sombras",
		"mestre_npc": "sariel_sombras",
		"beneficios": {
			"contratos_assassinato": true,
			"roubo_detectado_chance": 0.15
		}
	}
}

func generate_all() -> void:
	var tipo_map = {
		"aventureiros": GuildData.Type.AVENTUREIROS,
		"mercadores": GuildData.Type.MERCADORES,
		"artesaos": GuildData.Type.ARTESAOS,
		"sombras": GuildData.Type.SOMBRAS
	}
	
	# Garantir diretório
	DirAccess.make_dir_recursive_absolute("res://data/guilds/")
	
	var generated = 0
	for cls in CLASSES:
		for tipo_str in GUILD_TYPES:
			var guild = GuildData.new()
			guild.id = StringName("%s_%s" % [tipo_str, cls])
			guild.display_name = GUILD_CONFIG[tipo_str]["display_name"]
			guild.tipo = tipo_map[tipo_str]
			guild.mestre_npc = StringName(GUILD_CONFIG[tipo_str]["mestre_npc"])
			guild.descricao = "Guilda %s da classe %s" % [tipo_str, cls]
			guild.requisito_nivel = 1
			guild.requisito_ouro = 0
			guild.requisito_reputacao = -1
			guild.beneficios = GUILD_CONFIG[tipo_str]["beneficios"].duplicate()
			
			var path = "res://data/guilds/%s_%s.tres" % [tipo_str, cls]
			var error = ResourceSaver.save(guild, path)
			
			if error == OK:
				generated += 1
				print("[Guild Gen] Saved: %s" % path)
			else:
				push_error("Failed to save guild at %s (error %d)" % [path, error])
	
	print("[Guild Gen] Generated %d guild resources" % generated)

func _ready() -> void:
	generate_all()
	queue_free()
