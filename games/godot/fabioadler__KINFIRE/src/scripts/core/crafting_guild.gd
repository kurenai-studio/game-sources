extends Object
class_name CraftingGuild

static func start_craft(hero: Hero, recipe_id: StringName) -> bool:
	if hero.guild_joined != &"artesaos":
		return false
	# TODO: Implementar crafting completo na Fase 12
	return true

static func get_crafting_recipe(recipe_id: StringName) -> Dictionary:
	# TODO: Resource-based recipes
	return {}

static func get_available_recipes(hero: Hero) -> Array[StringName]:
	if hero.guild_joined != &"artesaos":
		return []
	return []
