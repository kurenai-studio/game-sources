extends RefCounted
class_name Guilds

## Sistema central de guildas - data-driven

const GuildData := preload("res://scripts/data/guild_data.gd")
const RankData := preload("res://scripts/data/rank_data.gd")
const ContractData := preload("res://scripts/data/contract_data.gd")

## Guildas do jogo (4 principais + ocultas)
static var _guilds: Dictionary[StringName, GuildData] = {}

## Retorna um GuildData pela ID
static func get_guild(guild_id: StringName) -> GuildData:
	if not _guilds.has(guild_id):
		_guilds[guild_id] = _load_guild(guild_id)
	return _guilds.get(guild_id)

## Retorna todas as guildas
static func all_guilds() -> Array[GuildData]:
	var result: Array[GuildData] = []
	var ids: Array = ["aventureiros", "mercadores", "artesaos", "sombras"]
	for gid in ids:
		var g := get_guild(StringName(gid))
		if g:
			result.append(g)
	return result

## Carrega dados de uma guilda (data-driven via .tres)
static func _load_guild(guild_id: StringName) -> GuildData:
	var path := "res://data/guilds/%s.tres" % guild_id
	if ResourceLoader.exists(path):
		return load(path)
	# Fallback: cria guilda vazia
	var g := GuildData.new()
	g.id = guild_id
	g.display_name = String(guild_id).capitalize()
	g.tipo = GuildData.Type.AVENTUREIROS
	return g

## Retorna todos os contratos de uma guilda
static func contracts_for(guild_id: StringName) -> Array[ContractData]:
	var result: Array[ContractData] = []
	var path := "res://data/contracts/index.json"
	if ResourceLoader.exists(path):
		var json := JSON.new()
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var data = json.parse_string(file.get_as_text())
			if data and data.has("contracts"):
				for cid in data["contracts"]:
					var contract_path := "res://data/contracts/%s.tres" % cid
					if ResourceLoader.exists(contract_path):
						var c: ContractData = load(contract_path)
						if c and c.guilda_id == guild_id:
							result.append(c)
	return result

## Retorna contrato pela ID
static func get_contract(contract_id: StringName) -> ContractData:
	var path := "res://data/contracts/%s.tres" % contract_id
	if ResourceLoader.exists(path):
		return load(path)
	return null
