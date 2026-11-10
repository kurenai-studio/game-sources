extends PanelContainer
class_name GuildPanel

var hero: Hero

func setup(p_hero: Hero) -> void:
	hero = p_hero
	# Stub para Fase 11 - UI completa em Fase 12

func toggle() -> void:
	visible = !visible
