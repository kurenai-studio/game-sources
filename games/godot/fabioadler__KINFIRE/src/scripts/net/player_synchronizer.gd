## Player Synchronizer
## Gerencia sincronização de posição/estado dos players
## 60Hz para posição (unreliable), eventos importantes (reliable)

extends Node

# class_name PlayerSynchronizer

## ============================================================================
## PLAYER SPAWNING
## ============================================================================

## Spawna um player remoto no mundo
static func spawn_remote_player(peer_id: int, hero_data: Dictionary, spawn_pos: Vector2, world: Node) -> Hero:
	print("[Multiplayer] Spawnando player remoto (peer=%d) em %s" % [peer_id, spawn_pos])
	
	# Validar dados
	if not hero_data or hero_data.is_empty():
		push_error("Hero data vazia para peer %d" % peer_id)
		return null
	
	# Criar hero a partir dos dados
	var hero = Hero.new()
	if not hero.from_dict(hero_data):
		push_error("Falha ao desserializar hero data para peer %d" % peer_id)
		hero.queue_free()
		return null
	
	# Posicionar no mundo
	hero.global_position = spawn_pos
	hero.set_multiplayer_authority(peer_id)
	
	# Adicionar ao mundo
	if world:
		world.add_child(hero)
	else:
		(Engine.get_main_loop() as SceneTree).root.add_child(hero)
	
	# Registrar no manager
	MultiplayerManager.player_chars[peer_id] = hero
	
	return hero

## Remove um player do mundo
static func despawn_remote_player(peer_id: int) -> void:
	if peer_id not in MultiplayerManager.player_chars:
		return
	
	var hero = MultiplayerManager.player_chars[peer_id]
	print("[Multiplayer] Removendo player remoto (peer=%d)" % peer_id)
	
	if is_instance_valid(hero):
		hero.queue_free()
	
	MultiplayerManager.player_chars.erase(peer_id)

## ============================================================================
## POSITION SYNC (60Hz, Unreliable)
## ============================================================================

## Sincroniza posição local do player (chamado no _process)
static func sync_position(hero: Hero, peer_id: int) -> void:
	if not MultiplayerManager.is_multiplayer():
		return
	
	# Só host sincroniza posição dos clientes
	if not hero.is_multiplayer_authority():
		return
	
	# RPC unreliable para todos
	if hero.has_meta("last_sync_pos"):
		var last_pos: Vector2 = hero.get_meta("last_sync_pos")
		if last_pos.distance_to(hero.global_position) < 1.0:
			return  # Evitar spam se movimento pequeno
	
	hero.set_meta("last_sync_pos", hero.global_position)
	
	# Chamar RPC
	var direction = hero.velocity.normalized() if hero.velocity.length() > 0 else Vector2.ZERO
	hero.rpc_unreliable(
		MultiplayerRPC.RPC_SYNC_PLAYER_POSITION,
		peer_id,
		hero.global_position,
		direction
	)

## Recebe sincronização de posição de outro player
static func apply_remote_position(peer_id: int, position: Vector2, direction: Vector2) -> void:
	if peer_id not in MultiplayerManager.player_chars:
		return
	
	var hero = MultiplayerManager.player_chars[peer_id]
	if not is_instance_valid(hero):
		return
	
	# Smooth movement (lerp)
	hero.global_position = hero.global_position.lerp(position, 0.1)
	
	# Atualizar direção (para animações)
	if direction.length() > 0.1:
		hero.set_meta("remote_direction", direction)

## ============================================================================
## VITALS SYNC (Reliable, on change)
## ============================================================================

## Sincroniza HP/Mana de um player
static func sync_vitals(hero: Hero, peer_id: int) -> void:
	if not MultiplayerManager.is_server:
		return
	
	# Só syncroniza se mudou significativamente
	var last_hp = hero.get_meta("last_sync_hp") if hero.has_meta("last_sync_hp") else hero.hp
	var last_mana = hero.get_meta("last_sync_mana") if hero.has_meta("last_sync_mana") else hero.mana
	
	var hp_changed = abs(hero.hp - last_hp) > 0.1
	var mana_changed = abs(hero.mana - last_mana) > 0.1
	
	if not (hp_changed or mana_changed):
		return
	
	hero.set_meta("last_sync_hp", hero.hp)
	hero.set_meta("last_sync_mana", hero.mana)
	
	# RPC reliable (broadcast)
	hero.rpc_unreliable_id(
		peer_id,
		MultiplayerRPC.RPC_SYNC_PLAYER_VITALS,
		peer_id,
		hero.hp,
		hero.mana
	)

## Recebe sincronização de vitals
static func apply_remote_vitals(peer_id: int, hp: float, mana: float) -> void:
	if peer_id not in MultiplayerManager.player_chars:
		return
	
	var hero = MultiplayerManager.player_chars[peer_id]
	if not is_instance_valid(hero):
		return
	
	hero.hp = hp
	hero.mana = mana

## ============================================================================
## INVENTORY SYNC (Reliable, on change)
## ============================================================================

## Sincroniza inventário completo
static func sync_inventory(hero: Hero, peer_id: int) -> void:
	if not MultiplayerManager.is_server:
		return
	
	# Serializar inventário
	var inv_data = []
	for item in hero.inventory.get_all_items():
		if item:
			inv_data.append(item.to_dict())
	
	hero.rpc_unreliable_id(
		peer_id,
		MultiplayerRPC.RPC_SYNC_INVENTORY,
		peer_id,
		inv_data
	)

## Recebe sincronização de inventário
static func apply_remote_inventory(peer_id: int, inv_data: Array) -> void:
	if peer_id not in MultiplayerManager.player_chars:
		return
	
	var hero = MultiplayerManager.player_chars[peer_id]
	if not is_instance_valid(hero):
		return
	
	# Restaurar inventário
	hero.inventory.clear()
	for item_dict in inv_data:
		if item_dict:
			var item = Item.new()
			item.from_dict(item_dict)
			hero.inventory.add_item(item)

## ============================================================================
## SKILL COOLDOWN SYNC
## ============================================================================

## Sincroniza cooldown de skill
static func sync_skill_cooldown(hero: Hero, skill_slot: int, cooldown: float) -> void:
	if not MultiplayerManager.is_server:
		return
	
	hero.rpc_unreliable(
		MultiplayerRPC.RPC_SYNC_SKILL_COOLDOWN,
		MultiplayerManager.get_local_peer_id(),
		skill_slot,
		cooldown
	)

## ============================================================================
## DEBUG
## ============================================================================

static func debug_print_player_state(peer_id: int) -> void:
	if peer_id not in MultiplayerManager.player_chars:
		print("[Multiplayer] Player %d not found" % peer_id)
		return
	
	var hero = MultiplayerManager.player_chars[peer_id]
	print("\n=== PLAYER STATE (peer=%d) ===" % peer_id)
	print("Name: ", hero.name)
	print("Position: ", hero.global_position)
	print("HP: %.1f / %.1f" % [hero.hp, hero.max_hp])
	print("Mana: %.1f / %.1f" % [hero.mana, hero.max_mana])
	print("Authority: ", hero.is_multiplayer_authority())
	print("============================\n")
