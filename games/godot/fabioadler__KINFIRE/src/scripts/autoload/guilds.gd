extends Node

var guild_cache: Dictionary = {}

func _ready() -> void:
	_preload_guild_data()

func _preload_guild_data() -> void:
	# Carrega 56 guildas de .tres (14 classes x 4 tipos)
	var classes = ["humano", "barbaro", "alto_elfo", "elfo_floresta", "drow",
		"anao_montanha", "anao_colinas", "halfling", "meio_orc", "tiefling",
		"draconato", "gnomo", "meio_elfo", "tabaxi"]
	var tipos = ["aventureiros", "mercadores", "artesaos", "sombras"]
	
	var loaded = 0
	for cls in classes:
		for tipo in tipos:
			var path = "res://data/guilds/%s_%s.tres" % [tipo, cls]
			var guild = load(path)
			if guild:
				guild_cache[guild.id] = guild
				loaded += 1
			else:
				print("[Guilds] WARN: Failed to load %s" % path)
	
	print("[Guilds] Loaded %d guild resources" % loaded)

func guild(guild_id: StringName) -> GuildData:
	return guild_cache.get(guild_id)

func get_player_guild(hero: Hero) -> PlayerGuild:
	if hero.player_guild_id != &"":
		return Game.player_guilds.get(hero.player_guild_id) if Game.player_guilds else null
	return null
