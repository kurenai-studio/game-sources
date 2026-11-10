## World Synchronizer
## Gerencia snapshot/restore do estado do mundo
## Usado para sincronizar clientes ao conectarem

extends Node

class_name WorldSynchronizer

## ============================================================================
## SNAPSHOT - HOST SIDE
## ============================================================================

## Cria snapshot completo do mundo atual
static func create_snapshot(world: Node) -> Dictionary:
	var snapshot: Dictionary = {
		"timestamp": Time.get_ticks_msec(),
		"world_seed": Game.world_seed if Game.has_meta("world_seed") else 0,
		"world_time": Game.world_time,
		"difficulty": Game.settings.difficulty,
		"biome": "planicie",  # Será atualizado
		"enemies": [],
		"loot": [],
		"environment": {},
	}
	
	# Determinar bioma baseado na posição do player
	if world is Overworld:
		var ow: Overworld = world as Overworld
		if ow.player:
			snapshot["biome"] = ow.og.biome_at(ow.world_to_cell(ow.player.global_position))
	
	# Snapshot de inimigos ativos
	for enemy in world.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy:
			snapshot["enemies"].append({
				"id": enemy.get_instance_id(),
				"position": enemy.global_position,
				"hp": enemy.hp,
				"max_hp": enemy.max_hp,
				"rarity": enemy.rarity,
				"data_id": enemy.data.id,
			})
	
	# Snapshot de loot no chão
	for drop in world.get_tree().get_nodes_in_group("pickups"):
		if drop is LootDrop:
			snapshot["loot"].append({
				"id": drop.get_instance_id(),
				"position": drop.global_position,
				"item": drop.item.to_dict() if drop.item else {},
			})
	
	# Environment (luz, sombras, etc)
	snapshot["environment"] = {
		"has_occlusion": world.get_node_or_null("wall_layer") != null,
	}
	
	return snapshot

## Retorna snapshot spawn point para novo cliente
static func get_spawn_point(host_position: Vector2) -> Vector2:
	# Spawn 50px à direita do host
	return host_position + Vector2(50, 0)

## ============================================================================
## RESTORE - CLIENT SIDE
## ============================================================================

## Restaura mundo do snapshot
static func restore_world_from_snapshot(snapshot: Dictionary, world: Node) -> bool:
	print("[Multiplayer] Restaurando mundo do snapshot...")
	
	# Validações básicas
	if not snapshot.has_all(["world_time", "difficulty", "enemies", "loot"]):
		push_error("Snapshot inválido: campos faltando")
		return false
	
	# Restaurar tempo do mundo
	Game.world_time = snapshot["world_time"]
	
	# Restaurar dificuldade
	if snapshot.has("difficulty"):
		Game.settings.difficulty = snapshot["difficulty"]
	
	# Restaurar seed do mundo
	if snapshot.has("world_seed"):
		Game.world_seed = snapshot["world_seed"]
	
	# Enemies serão spawnados pelo host via RPC
	# Loot será sincronizado via RPC
	
	print("[Multiplayer] Mundo restaurado (time=%.2f, enemies=%d, loot=%d)" % [
		snapshot["world_time"],
		snapshot["enemies"].size(),
		snapshot["loot"].size()
	])
	
	return true

## ============================================================================
## VALIDATION
## ============================================================================

## Valida integridade de um snapshot
static func validate_snapshot(snapshot: Dictionary) -> bool:
	# Campos obrigatórios
	var required = ["timestamp", "world_time", "difficulty", "enemies", "loot", "environment"]
	for field in required:
		if not snapshot.has(field):
			push_error("Snapshot inválido: campo '%s' faltando" % field)
			return false
	
	# Tipos corretos
	if not snapshot["enemies"] is Array:
		push_error("Snapshot inválido: 'enemies' não é Array")
		return false
	
	if not snapshot["loot"] is Array:
		push_error("Snapshot inválido: 'loot' não é Array")
		return false
	
	if not snapshot["environment"] is Dictionary:
		push_error("Snapshot inválido: 'environment' não é Dictionary")
		return false
	
	# Limites razoáveis
	if snapshot["enemies"].size() > 1000:
		push_error("Snapshot inválido: muitos inimigos (%d)" % snapshot["enemies"].size())
		return false
	
	if snapshot["loot"].size() > 500:
		push_error("Snapshot inválido: muito loot (%d)" % snapshot["loot"].size())
		return false
	
	return true

## ============================================================================
## DEBUG
## ============================================================================

static func debug_print_snapshot(snapshot: Dictionary) -> void:
	print("\n=== WORLD SNAPSHOT ===")
	print("Timestamp: ", snapshot.get("timestamp", "?"))
	print("World Time: %.2f" % snapshot.get("world_time", 0))
	print("Difficulty: ", snapshot.get("difficulty", "?"))
	print("Biome: ", snapshot.get("biome", "?"))
	print("Enemies: %d" % snapshot.get("enemies", []).size())
	print("Loot: %d" % snapshot.get("loot", []).size())
	print("Valid: ", validate_snapshot(snapshot))
	print("======================\n")
