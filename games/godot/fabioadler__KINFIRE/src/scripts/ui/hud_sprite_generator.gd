extends Node
## Gerador de sprites modernos para HUD em SVG -> PNG

static func create_hud_sprites() -> void:
	# Criar diretório de sprites se não existir
	var dir = DirAccess.open("res://assets/sprites/hud")
	if dir == null:
		DirAccess.make_dir_recursive_absolute("res://assets/sprites/hud")
	
	# Gerar sprites SVG
	_create_panel_frame()
	_create_bar_backgrounds()
	_create_skill_slots()
	_create_icons()
	print("[OK] Sprites HUD modernos criados")


static func _create_panel_frame() -> void:
	# Frame moderno com borda dourada
	var svg = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <!-- Fundo semi-transparente escuro -->
  <rect width="512" height="512" fill="#0d0904" opacity="0.95"/>
  
  <!-- Borda externa dourada -->
  <rect x="2" y="2" width="508" height="508" fill="none" stroke="#c4a860" stroke-width="2" rx="8"/>
  
  <!-- Linha interna decorativa -->
  <rect x="6" y="6" width="500" height="500" fill="none" stroke="#6b5d3f" stroke-width="1" rx="6" opacity="0.5"/>
  
  <!-- Cantos decorativos (diamantes) -->
  <circle cx="10" cy="10" r="3" fill="#c4a860"/>
  <circle cx="502" cy="10" r="3" fill="#c4a860"/>
  <circle cx="10" cy="502" r="3" fill="#c4a860"/>
  <circle cx="502" cy="502" r="3" fill="#c4a860"/>
</svg>"""
	_save_svg("res://assets/sprites/hud/panel_frame.svg", svg)


static func _create_bar_backgrounds() -> void:
	# Barra de vida (vermelha)
	var hp_svg = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="256" height="32" viewBox="0 0 256 32" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="hpGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#cc0000;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#660000;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="256" height="32" fill="#1a0000" rx="4"/>
  <rect width="256" height="32" fill="url(#hpGrad)" rx="4" opacity="0.8"/>
  <line x1="0" y1="0" x2="256" y2="0" stroke="#ff4444" stroke-width="1"/>
</svg>"""
	_save_svg("res://assets/sprites/hud/bar_hp.svg", hp_svg)
	
	# Barra de recurso (azul)
	var res_svg = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="256" height="32" viewBox="0 0 256 32" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="resGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#0099ff;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#003366;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="256" height="32" fill="#000033" rx="4"/>
  <rect width="256" height="32" fill="url(#resGrad)" rx="4" opacity="0.8"/>
  <line x1="0" y1="0" x2="256" y2="0" stroke="#44ccff" stroke-width="1"/>
</svg>"""
	_save_svg("res://assets/sprites/hud/bar_resource.svg", res_svg)


static func _create_skill_slots() -> void:
	# Slot de skill vazio
	var empty_svg = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="slotGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1a1410;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#0d0804;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="64" height="64" fill="url(#slotGrad)" rx="4"/>
  <rect x="1" y="1" width="62" height="62" fill="none" stroke="#6b5d3f" stroke-width="1" rx="4"/>
  <line x1="0" y1="0" x2="64" y2="0" stroke="#c4a860" stroke-width="1" opacity="0.3"/>
</svg>"""
	_save_svg("res://assets/sprites/hud/slot_empty.svg", empty_svg)
	
	# Slot de skill ativo (verde)
	var active_svg = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="activeGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1a3a1a;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#0d1a0d;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="64" height="64" fill="url(#activeGrad)" rx="4"/>
  <rect x="1" y="1" width="62" height="62" fill="none" stroke="#00dd00" stroke-width="2" rx="4"/>
  <line x1="0" y1="0" x2="64" y2="0" stroke="#44ff44" stroke-width="1"/>
</svg>"""
	_save_svg("res://assets/sprites/hud/slot_active.svg", active_svg)
	
	# Slot de skill em cooldown (cinza)
	var cooldown_svg = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <rect width="64" height="64" fill="#1a1410" rx="4"/>
  <rect x="1" y="1" width="62" height="62" fill="none" stroke="#4a4030" stroke-width="1" rx="4"/>
  <!-- Overlay semi-transparente -->
  <rect width="64" height="64" fill="#000000" opacity="0.4" rx="4"/>
</svg>"""
	_save_svg("res://assets/sprites/hud/slot_cooldown.svg", cooldown_svg)


static func _create_icons() -> void:
	# Icone de vida
	var hp_icon = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
  <path d="M 16 2 C 16 2, 24 6, 24 12 C 24 18, 16 28, 16 28 C 16 28, 8 18, 8 12 C 8 6, 16 2, 16 2 Z" 
        fill="#cc0000" stroke="#ff4444" stroke-width="1"/>
</svg>"""
	_save_svg("res://assets/sprites/hud/icon_health.svg", hp_icon)
	
	# Icone de mana
	var mana_icon = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
  <path d="M 16 4 L 24 12 L 24 24 C 24 26.2, 22.2 28, 20 28 L 12 28 C 9.8 28, 8 26.2, 8 24 L 8 12 Z" 
        fill="#0099ff" stroke="#44ccff" stroke-width="1"/>
</svg>"""
	_save_svg("res://assets/sprites/hud/icon_mana.svg", mana_icon)
	
	# Icone de XP
	var xp_icon = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
  <circle cx="16" cy="16" r="12" fill="none" stroke="#ffdd00" stroke-width="2"/>
  <text x="16" y="20" font-size="16" font-weight="bold" text-anchor="middle" fill="#ffdd00">XP</text>
</svg>"""
	_save_svg("res://assets/sprites/hud/icon_xp.svg", xp_icon)


static func _save_svg(path: String, content: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		print("[OK] Criado: %s" % path)
	else:
		print("[ERROR] Erro ao criar: %s" % path)
