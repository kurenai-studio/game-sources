## RPC Protocol Definition
## Define todos os RPCs utilizados no sistema multiplayer
## Organizado por categoria e nível de permissão

class_name MultiplayerRPC

## ============================================================================
## ENEMY SYNCHRONIZATION
## ============================================================================

## Sincroniza posição de um inimigo (host -> clientes, unreliable)
## Parâmetros: enemy_id: int, position: Vector2
const RPC_SYNC_ENEMY_POSITION = "rpc_sync_enemy_position"

## Sincroniza HP de um inimigo (host -> clientes, reliable)
## Parâmetros: enemy_id: int, hp: float, max_hp: float
const RPC_SYNC_ENEMY_HP = "rpc_sync_enemy_hp"

## Sincroniza status de um inimigo (host -> clientes, reliable)
## Parâmetros: enemy_id: int, status_effects: Array[String]
const RPC_SYNC_ENEMY_STATUS = "rpc_sync_enemy_status"

## Notifica que um inimigo morreu (host -> clientes, reliable)
## Parâmetros: enemy_id: int, killer_peer: int, contributors: Dictionary
const RPC_ENEMY_DIED = "rpc_enemy_died"

## Spawn de um novo inimigo (host -> clientes, reliable)
## Parâmetros: enemy_id: int, position: Vector2, enemy_data_id: StringName, rarity: int
const RPC_SPAWN_ENEMY = "rpc_spawn_enemy"

## ============================================================================
## DAMAGE & COMBAT
## ============================================================================

## Aplica dano a um inimigo (cliente -> host, reliable)
## Parâmetros: enemy_id: int, damage: float, attacker_peer: int, skill_id: StringName
const RPC_APPLY_DAMAGE_TO_ENEMY = "rpc_apply_damage_to_enemy"

## Aplica dano a um player (host -> cliente, reliable)
## Parâmetros: damage: float, attacker_name: String
const RPC_DAMAGE_PLAYER = "rpc_damage_player"

## Sincroniza cooldown de skill (host -> clientes, reliable)
## Parâmetros: peer_id: int, skill_slot: int, cooldown_remaining: float
const RPC_SYNC_SKILL_COOLDOWN = "rpc_sync_skill_cooldown"

## ============================================================================
## LOOT & ITEMS
## ============================================================================

## Loot cai no chão (host -> clientes, reliable)
## Parâmetros: drop_id: int, position: Vector2, item_data: Dictionary
const RPC_LOOT_DROPPED = "rpc_loot_dropped"

## Um player reclama um item (cliente -> host, reliable)
## Parâmetros: drop_id: int, peer_id: int
const RPC_CLAIM_ITEM = "rpc_claim_item"

## Loot é reclamado com sucesso (host -> clientes, reliable)
## Parâmetros: drop_id: int, peer_id: int, item_data: Dictionary
const RPC_LOOT_CLAIMED = "rpc_loot_claimed"

## Sincroniza inventário de um player (host -> clientes, reliable)
## Parâmetros: peer_id: int, inventory_items: Array
const RPC_SYNC_INVENTORY = "rpc_sync_inventory"

## ============================================================================
## PLAYER SYNCHRONIZATION
## ============================================================================

## Sincroniza posição de um player (60Hz, unreliable)
## Parâmetros: peer_id: int, position: Vector2, direction: Vector2
const RPC_SYNC_PLAYER_POSITION = "rpc_sync_player_position"

## Sincroniza HP/Mana de um player (host -> clientes, reliable)
## Parâmetros: peer_id: int, hp: float, mana: float
const RPC_SYNC_PLAYER_VITALS = "rpc_sync_player_vitals"

## Um player se junta ao servidor (cliente -> host, reliable)
## Parâmetros: hero_data: Dictionary
const RPC_PLAYER_JOINED = "rpc_player_joined"

## Notifica todos que um player entrou (host -> clientes, reliable)
## Parâmetros: peer_id: int, hero_name: String
const RPC_ANNOUNCE_PLAYER_JOINED = "rpc_announce_player_joined"

## Um player sai (host -> clientes, reliable)
## Parâmetros: peer_id: int
const RPC_PLAYER_LEFT = "rpc_player_left"

## ============================================================================
## REVIVE SYSTEM
## ============================================================================

## Um player morre (host -> clientes, reliable)
## Parâmetros: peer_id: int, position: Vector2
const RPC_PLAYER_DIED = "rpc_player_died"

## Um player é revivido (host -> clientes, reliable)
## Parâmetros: target_peer: int, reviver_peer: int, position: Vector2
const RPC_PLAYER_REVIVED = "rpc_player_revived"

## ============================================================================
## PARTY SYSTEM
## ============================================================================

## Party é criada (host -> clientes, reliable)
## Parâmetros: party_id: int, members: Array[int]
const RPC_PARTY_CREATED = "rpc_party_created"

## Um player se junta à party (host -> clientes, reliable)
## Parâmetros: party_id: int, peer_id: int
const RPC_PARTY_MEMBER_JOINED = "rpc_party_member_joined"

## Party é dissolvida (host -> clientes, reliable)
## Parâmetros: party_id: int
const RPC_PARTY_DISBANDED = "rpc_party_disbanded"

## ============================================================================
## WORLD STATE
## ============================================================================

## Cliente pede snapshot do mundo (cliente -> host, reliable)
## Parâmetros: (nenhum)
const RPC_REQUEST_WORLD_STATE = "rpc_request_world_state"

## Host envia snapshot do mundo (host -> cliente, reliable)
## Parâmetros: snapshot: Dictionary
const RPC_SEND_WORLD_SNAPSHOT = "rpc_send_world_snapshot"

## Cliente confirmou que carregou (cliente -> host, reliable)
## Parâmetros: (nenhum)
const RPC_CLIENT_READY = "rpc_client_ready"

## ============================================================================
## RESPAWN SYSTEM
## ============================================================================

## Inimigo respawna (host -> clientes, reliable)
## Parâmetros: enemy_id: int, position: Vector2
const RPC_ENEMY_RESPAWNED = "rpc_enemy_respawned"

## ============================================================================
## EFFECTS & VISUALS
## ============================================================================

## Efeito visual (host -> clientes, unreliable)
## Parâmetros: fx_type: String, position: Vector2, data: Dictionary
const RPC_SPAWN_FX = "rpc_spawn_fx"

## Som no mundo (host -> clientes, unreliable)
## Parâmetros: sound_name: String, position: Vector2
const RPC_PLAY_SOUND = "rpc_play_sound"

## ============================================================================
## HELPER - Permissões RPC
## ============================================================================

## Define permissões de RPC
## authority = só host pode chamar
## any_peer = qualquer um pode chamar (host valida)
## call_remote = chama nos clientes remotos

static func get_authority_type(rpc_name: String) -> String:
	# RPCs que só host chama
	var host_only = [
		RPC_SYNC_ENEMY_POSITION,
		RPC_SYNC_ENEMY_HP,
		RPC_ENEMY_DIED,
		RPC_SPAWN_ENEMY,
		RPC_LOOT_DROPPED,
		RPC_LOOT_CLAIMED,
		RPC_SYNC_INVENTORY,
		RPC_ANNOUNCE_PLAYER_JOINED,
		RPC_PLAYER_LEFT,
		RPC_PLAYER_DIED,
		RPC_PLAYER_REVIVED,
		RPC_PARTY_CREATED,
		RPC_PARTY_MEMBER_JOINED,
		RPC_PARTY_DISBANDED,
		RPC_SEND_WORLD_SNAPSHOT,
		RPC_ENEMY_RESPAWNED,
		RPC_SPAWN_FX,
		RPC_PLAY_SOUND,
	]
	
	if rpc_name in host_only:
		return "authority"
	return "any_peer"

static func get_call_type(rpc_name: String) -> String:
	# RPCs unreliable (60Hz sync)
	var unreliable = [
		RPC_SYNC_ENEMY_POSITION,
		RPC_SYNC_PLAYER_POSITION,
		RPC_SPAWN_FX,
		RPC_PLAY_SOUND,
	]
	
	if rpc_name in unreliable:
		return "call_remote_unreliable"
	return "call_remote"

## Debug - imprime todos os RPCs
static func debug_print_all() -> void:
	print("\n=== MULTIPLAYER RPC PROTOCOL ===")
	print("Enemy Sync: ", RPC_SYNC_ENEMY_POSITION, ", ", RPC_SYNC_ENEMY_HP, ", ", RPC_ENEMY_DIED)
	print("Combat: ", RPC_APPLY_DAMAGE_TO_ENEMY, ", ", RPC_DAMAGE_PLAYER)
	print("Loot: ", RPC_LOOT_DROPPED, ", ", RPC_CLAIM_ITEM, ", ", RPC_LOOT_CLAIMED)
	print("Player: ", RPC_SYNC_PLAYER_POSITION, ", ", RPC_PLAYER_JOINED, ", ", RPC_PLAYER_LEFT)
	print("Revive: ", RPC_PLAYER_DIED, ", ", RPC_PLAYER_REVIVED)
	print("Party: ", RPC_PARTY_CREATED, ", ", RPC_PARTY_DISBANDED)
	print("World: ", RPC_REQUEST_WORLD_STATE, ", ", RPC_SEND_WORLD_SNAPSHOT)
	print("================================\n")
