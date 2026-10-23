const MAPPER_GAMES: Dictionary = {
	"Mapping": {
		"game_directory": "res://mapping",
		"alternative_game_directories": [
			"res://mapping-base"
		],
		"game_loader": MapperSettings.DEFAULT_GAME_LOADER,
		"world_entity_extra_brush_entities_classnames": [
			"func_detail",
		],
		"texture_filter":
			BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC,
	},
	"Characters": {
		"game_directory": "res://characters",
		"alternative_game_directories": [
			"res://mapping",
			"res://mapping-base"
		],
		"game_loader": MapperSettings.DEFAULT_GAME_LOADER,
		"world_entity_extra_brush_entities_enabled": false,
		"cast_shadow_meshes": false,
		"texture_filter":
			BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC,
	},
}
