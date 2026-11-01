"""Verifica que el juego coincide con la Biblia del Juego (GAME_BIBLE) y que las clases LEEN de UNITS.

Uso (antes de cada commit):  python src/verify_balance.py
Imprime la lista de discrepancias (vacía = OK) y termina con código 1 si hay alguna.

GAME_BIBLE es la transcripción literal de la tabla de diseño (versión 4.0); no importa nada de UNITS a propósito: si
alguien cambia un número en UNITS.py sin actualizar el diseño (o al revés), aquí salta la diferencia. Además se
instancian las clases reales para comprobar que no arrastran cifras propias. Cubre Núcleos de Plasma, Energía y el
árbol de mejoras del Operador, el catálogo consolidado (2 torretas base, 4 rutas), mejoras del muro y
el Extractor de Plasma."""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)
os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

# --------------------------------------------------------------------------------------------------
# GAME BIBLE 4.0: transcripción de la tabla de diseño (distancias px, tiempos s, velocidades px/s)
# --------------------------------------------------------------------------------------------------
GAME_BIBLE = {
    "resources": {"scrap_initial_act1": 150, "scrap_initial_act2": 100, "cores_initial": 0, "energy_initial_capacity": 50},
    "energy_costs": {"twin_autocannon": 5, "balista": 12, "tesla": 15, "lanzallamas": 8},
    "drops": {
        "scout": {"scrap": (3, 5), "scrap_chance": 0.40, "cores": 0, "ammo_prob": 0.3},
        "soldier": {"scrap": (8, 12), "scrap_chance": 0.40, "cores": 0, "ammo_prob": 0.3},
        "ariete": {"scrap": (25, 35), "scrap_chance": 0.50, "cores": (1, 1), "core_chance": 0.50, "ammo_prob": 0.4},
        "tank": {"scrap": (50, 70), "scrap_chance": 0.50, "cores": (2, 2), "core_chance": 0.50, "ammo_prob": 0.4},
    },
    # Fábrica de Drones (sustituye al escuadrón Viper/Magneto/Aegis)
    "factory": {"cost": 220, "cores": 0, "hp": 600, "build_time": 20.0, "energy": 3, "drones_per_factory": 8,
                "production_queue_size": 4, "production_time": 10.0},
    "drone_types": {
        "recon": {"cost": 25, "cores": 0, "hp": 70, "speed": 240, "layer": "air", "vision_range": 400, "damage": 0},
        "attack": {"cost": 40, "cores": 0, "hp": 140, "speed": 170, "layer": "air", "damage": 16, "shot_interval": 0.5,
                   "range": 190},
        "bomber": {"cost": 75, "cores": 0, "hp": 130, "speed": 130, "layer": "air", "bomb_damage": 75, "bomb_radius": 60,
                   "bomb_cooldown": 2.5},
        "trooper": {"cost": 50, "cores": 0, "hp": 220, "armor": 3, "speed": 110, "layer": "ground", "damage": 15,
                    "shot_interval": 0.4, "range": 160},
    },
    "drone_upgrades": {"Velocity_Recon": ("recon", {"speed": 50}), "Damage_Attack": ("attack", {"damage": 8}),
                       "Payload_Bomber": ("bomber", {"bomb_damage": 25}),
                       "Plating_Trooper": ("trooper", {"hp": 60})},
    "buildings": {
        "tower": {"cost": 45, "cores": 0, "energy": 5, "hp": 300, "range": 200, "damage": 14, "fire_rate": 0.35},
        "balista": {"cost": 100, "cores": 0, "energy": 12, "hp": 450, "range": 320, "damage": 160, "fire_rate": 1.8,
                    "pierce": 2},
        "wall": {"cost": 30, "energy": 0, "hp": 400, "sell": 0.70, "break_blinks": 3},     # Balance P1: 15 -> 30
        "pylon": {"cost": 30, "energy": 1, "energy_output": 5},
        "extractor": {"cost": 60, "energy": 8},
        "core": {"energy_output": 50},
        "foco": {"cost": 50, "cores": 0, "energy": 3, "range_bonus": 30},
        "compuerta": {"cost": 45, "cores": 0, "energy": 1, "hp": 500, "width": 40, "height": 80},     # Prioridad 5
    },
    "removed": ("tesla", "flamethrower", "bastion"),          # ya no son edificios (Tesla y Lanzallamas son rutas B)
    "wall_levels": {
        2: {"cost": 30, "cores": 0, "energy": 0, "hp": 900, "ram_reduction": 0.30},
        3: {"cost": 60, "cores": 0, "energy": 2, "hp": 1400, "counter_damage": 20},
    },
    "routes": {
        "tower": {"A": {"cost": 60, "cores": 0, "energy_extra": 0,
                        "set": {"fire_rate": 0.20, "damage": 10, "armor_pierce": 4}},              # Balance P1
                  "B": {"cost": 60, "cores": 0, "energy_extra": 3,
                        "set": {"mode": "flame", "damage": 50, "fire_rate": 0.1, "range": 120, "cone": 70,
                                "armor_pierce": 99}}},                                             # Balance P1
        "balista": {"A": {"cost": 90, "cores": 0, "energy_extra": 0, "set": {"pierce": 4, "damage": 200}},
                    "B": {"cost": 110, "cores": 0, "energy_extra": 15,
                          "set": {"mode": "tesla", "damage": 45, "fire_rate": 1.0, "range": 160, "jumps": 4,
                                  "stun_slow": 0.40, "stun_time": 0.3, "chain_range": 110, "crowd_radius": 80}}},
    },
    "enemies": {
        "scout": {"hp": 45, "armor": 0, "speed": 180, "melee_dps": 8, "contact": "continuous",
                  "flank_far": 320, "flank_close": 70, "orbit_strength": 1.2, "orbit_strength_structures": 0.3},
        "soldier": {"hp": 144, "armor": 4, "speed": 100, "range": 160, "burst": 3, "shot_damage": 12,     # -20% vida, -18% alcance
                    "burst_gap": 0.12, "burst_cooldown": 2.0},
        "ariete": {"hp": 680, "front_reduction": 0.45, "weak_mult": 3.0, "speed": 70, "charge_speed": 220, "impact": 300},
        "tank": {"hp": 1120, "armor": 8, "speed": 45, "range": 312, "cannon_damage": 120, "cannon_cooldown": 3.5},  # nerf a distancia
    },
    "scavenger": {"hp": 25, "armor": 0, "speed": 250, "sabotage_time": 8.0, "latch_time": 1.2},
    # Balance P1: respiro entre oleadas y oleada 5 escalonada (Tanque abre, 2 Arietes a los 15 s)
    "pacing": {"break_time": 12.0,
               "wave5": [("tank", 1, 0.0), ("scout", 8), ("soldier", 4), ("ariete", 2, 15.0)],
               "wave4_rams": 1},
    # nodo: (rama, nivel, chatarra, núcleos, prerrequisito). Economía separada: el árbol se paga SOLO con núcleos.
    "tree": {
        "gatillo_automatico": ("offensive", 1, 0, 1, None),
        "calibre_perforante": ("offensive", 2, 0, 3, "gatillo_automatico"),
        "sobrecarga_balistica": ("offensive", 3, 0, 5, "calibre_perforante"),
        "impulso_doble": ("survival", 1, 0, 1, None),
        "blindaje_titanio": ("survival", 2, 0, 3, "impulso_doble"),
        "celda_vital": ("survival", 3, 0, 4, "blindaje_titanio"),
        "celda_vital_2": ("survival", 4, 0, 6, "celda_vital"),
    },
    "effects": {"rifle_damage_tier2": 16, "rifle_damage_tier3": 20, "rifle_pierce_tier2": 2, "overload_cooldown": 0.12,
                "dash_charges": 2, "flat_armor": 4, "extra_blocks": 1},
    "player": {"hp_base": 100, "speed": 300, "ammo_capacity": 150, "ammo_per_mag": 50, "shoot_range": 270,
               "shoot_damage": 12, "shoot_cooldown": 0.15, "shoot_speed": 600, "reload_time": 0.8, "melee_range": 70,
               "melee_damage": 25, "melee_cooldown": 0.4, "melee_knockback": 50,
               "regen_delay": 3.0, "regen_rate": 2.5, "hitbox_radius": 11, "dash_duration": 0.15,
               "health_blocks": 3, "block_regen_rate": 5.0, "aim_assist_cone": 15},
    "medkits": {"max": 5, "cache_chance": 0.6, "vault_count": 1,
                "enemy_chance": {"scout": 0.03, "soldier": 0.08, "ariete": 0.15, "tank": 0.20}},
    "ammo": {"crit_threshold_low": 30, "crit_threshold_critical": 10, "ammo_drop_chance": 0.30, "ammo_drop_amount": 50},
    "rescues": {"trigger_scrap_less_than": 80, "alijo_1_amount": 100, "alijo_2_amount": 50},
    # Prioridad 3.A: bases enemigas con IA y niebla de guerra
    "enemy_bases": {"core_hp": 1000, "start_scrap": 500, "start_cores": 3, "energy": 50, "energy_cap": 100,
                    "ai_interval": 45.0, "build_chance": 0.40, "repair_chance": 0.30, "build_radius": 200},
    "enemy_priority": {"easy": ["muro", "muro", "torreta_ligera", "muro"],
                       "medium": ["muro", "torreta_pesada", "muro", "generador", "torreta_ligera"],
                       "hard": ["torreta_pesada", "muro", "generador", "pilon", "torreta_pesada"]},
    "bases_by_alert": {1: (1, "easy"), 2: (1, "easy"), 3: (2, "medium"), 4: (3, "hard"), 5: (3, "hard")},
    "fog": {"cell": 40, "player_radius": 300, "recon_radius": 400},
    # Prioridad 3.B: mapas de campaña (tamaño, bases, tamaños de oleada, premios por base, duración)
    "campaign_maps": {
        "map_1_infiltration": {"difficulty": "easy", "map_size": (2000, 1500), "player_base": (1000, 1125), "bases": 1,
                               "small": [1, 1, 2, 1, 2, 2, 1], "big": [3, 5, 8], "total": 600,
                               "rewards": ["AURA_PART_1"]},
        "map_2_push": {"difficulty": "medium", "map_size": (2250, 1750), "player_base": (1125, 1375), "bases": 2,
                       "small": [2, 2, 3, 2, 3, 4, 3, 4], "big": [5, 8, 12], "total": 900,
                       "rewards": ["AURA_PART_2", "PLAYER_UPGRADE_1"]},
        "map_3_siege": {"difficulty": "hard", "map_size": (2500, 2000), "player_base": (525, 1250), "bases": 3,
                        "small": [3, 3, 4, 4, 5, 6, 6, 7], "big": [8, 12, 15, 20], "total": 1200,
                        "rewards": ["AURA_PART_3", "PLAYER_UPGRADE_2", "DRONE_UPGRADE_ATTACK"]},
    },
    "campaign_break": 30,
    # Prioridad 5 + Bloque 3.A
    "p5": {"regen_rate": 3, "gate": {"open_range": 70, "auto_close_delay": 2.0},
           "final_horde": {"scout": 8, "soldier": 3}, "overload_line_at": 5.0},
    # Prioridad 4: rewards (6 AURA + 6 Operador + 4 drones)
    "rewards": {
        "player": {"PLAYER_UPGRADE_1": {"damage_reduction": 0.20}, "PLAYER_UPGRADE_2": {"speed": 50},
                   "PLAYER_UPGRADE_3": {"ammo_max": 100}, "PLAYER_UPGRADE_4": {"regen_rate": 3},
                   "PLAYER_UPGRADE_5": {"vision_range": 100}, "PLAYER_UPGRADE_6": {"health_max": 50}},
        "drone": {"DRONE_UPGRADE_RECON": ("recon", {"speed": 70}, "Velocity_Recon"),
                  "DRONE_UPGRADE_ATTACK": ("attack", {"damage": 10}, "Damage_Attack"),
                  "DRONE_UPGRADE_BOMBER": ("bomber", {"bomb_damage": 35}, "Payload_Bomber"),
                  "DRONE_UPGRADE_TROOPER": ("trooper", {"hp": 80}, "Plating_Trooper")},
        "aura_parts": 6, "regen_delay": 3.0,
    },
    "campaign_big_interval": 5,                 # una grande tras cada 5 pequeñas (Stronghold Loop)
    "campaign_spawn_interval": 0.3,             # segundos entre apariciones
    "enemy_ai_escalation": {"every": 3, "step": 5.0, "floor": 20.0},
    # Prioridad 2
    "aura_chassis": {"scan_parts": 3, "drone_parts": 6},
    "aura_drone": {"hp": 150, "pulse_interval": 5.0, "pulse_radius": 100, "stun_slow": 0.40, "stun_time": 1.5,
                   "pulse_energy": 2, "damage": 14, "range": 200, "shot_interval": 0.6, "escort_radius": 70},
    "chassis_surplus": {"scrap": 30, "cores": 1},   # con 6/6 piezas, la que sobra (derivado)
    # Infraestructura y red eléctrica (sin Extractor de Plasma: los núcleos nunca los genera un edificio)
    "infra": {
        "core": {"hp": 500, "energy_output": 50},
        "pylon": {"cost": 30, "cores": 0, "hp": 120, "range": 160, "energy_output": 5},
        "extractor": {"cost": 60, "cores": 0, "hp": 120, "energy": 8, "income": 5, "interval": 1.2},
        "foco": {"cost": 50, "cores": 0, "hp": 150, "energy": 3, "range_bonus": 30, "reveal_radius": 320},
    },
    # Escala de las unidades y enemigos pesados (Tanque, Ariete, Ariete Ligero)
    "heavy": {
        "entity_scale": 0.83, "sizes": {"scout": 15, "soldier": 22, "ariete": 38, "tank": 33},
        "tank": {"hp": 1120, "armor": 8, "speed": 45, "cannon_damage": 120, "splash_radius": 70, "range": 312,
                 "turn_rate": 65, "aim_time": 0.8, "aim_tolerance": 8},
        "ariete": {"hp": 680, "armor": 0, "speed": 70, "impact": 300, "front_reduction": 0.45, "weak_mult": 3.0,
                   "windup_turn_rate": 120},
        "light_ram": {"hp": 260, "front_mult": 0.25, "side_mult": 0.5, "rear_mult": 2.0, "stun": 1.1,
                      "rear_arc": (135, 225), "smoke_below": 0.30},
    },
    # Economía separada (chatarra / núcleos / aleación) y prioridades de VULCANO
    "economy": {
        "alloy_initial": 0, "drone_upgrade_alloy": 2, "base_alloy": 1,
        "map_alloy": {"map_1_infiltration": 2, "map_2_push": 3, "map_3_siege": 4},
        "vulcano": {"repair_rate": 80, "threshold": 0.5, "scrap_per_hp": 0.095, "scrap_reserve": 25,
                    "priority": (("core",), ("pylon", "tower", "balista"), ("wall", "compuerta"))},
        "chassis_install_cost": 0,
    },
    # Fase 6: blindaje de bases, drones, desbloqueo/anti-farmeo y balance de daño
    "phase6": {
        "drones_per_factory": 8, "attack_dps": 32.0, "damage_cap": 0.35,
        "garrison": {"easy": {"muro": 2, "torreta_ligera": 1, "generador": 1},
                     "medium": {"muro": 3, "torreta_ligera": 1, "generador": 1},
                     "hard": {"muro": 4, "torreta_pesada": 2, "generador": 1}},
        "evacuation": {"easy": {"scout": 4}, "medium": {"scout": 6, "soldier": 1},
                       "hard": {"scout": 8, "soldier": 2, "ariete": 1}},
        "map_rewards": {"map_1_infiltration": (100, 3), "map_2_push": (150, 4), "map_3_siege": (200, 5)},
        "vulcano_fixed_profile": "medium", "cover_bonus_per_wall": 0.05,
        "vulcano_grace_time": 3.0, "vulcano_low_hp_warning": 0.3,
    },
    "vulcano_defense": {"duration": 25.0, "vulcano_hp": 200,
                        "profiles": {"small": {"scout": 4}, "medium": {"scout": 6, "soldier": 1},
                                     "large": {"scout": 8, "soldier": 2, "light_ram": 1}}},
}


def _cmp(problems, label, got, want):
    if isinstance(want, float) or isinstance(got, float):
        same = abs(float(got) - float(want)) < 1e-9
    else:
        same = got == want
    if not same:
        problems.append(f"{label}: juego={got!r} Biblia={want!r}")


def verify():
    """Devuelve la lista de discrepancias entre la Biblia, UNITS.py y las clases que lo leen."""
    import pygame
    pygame.init()
    if pygame.display.get_surface() is None:
        pygame.display.set_mode((64, 64))
    import config as C
    from src.config import UNITS as U
    from src.entities.building import BUILD_MENU, Building
    from src.entities.enemy import Enemy
    from src.entities.player import Player
    from src.entities.scavenger import ScavengerDrone
    from src.managers.resource_manager import ResourceManager

    problems = []
    B = GAME_BIBLE

    # 1) UNITS.py contra la Biblia
    _cmp(problems, "UNITS.RESOURCES.scrap.initial_act1", U.RESOURCES["scrap"]["initial_act1"], B["resources"]["scrap_initial_act1"])
    _cmp(problems, "UNITS.RESOURCES.scrap.initial_act2", U.RESOURCES["scrap"]["initial_act2"], B["resources"]["scrap_initial_act2"])
    _cmp(problems, "UNITS.RESOURCES.cores.initial", U.RESOURCES["cores"]["initial"], B["resources"]["cores_initial"])
    _cmp(problems, "UNITS.RESOURCES.energy.initial_capacity", U.RESOURCES["energy"]["initial_capacity"],
         B["resources"]["energy_initial_capacity"])
    for key, want in B["energy_costs"].items():
        _cmp(problems, f"UNITS.ENERGY_COSTS[{key}]", U.ENERGY_COSTS[key], want)
    for kind, spec in B["drops"].items():
        for key, want in spec.items():
            _cmp(problems, f"UNITS.ENEMY_DROPS[{kind}].{key}", U.ENEMY_DROPS[kind][key], want)
    for key, want in B["factory"].items():
        _cmp(problems, f"UNITS.BUILDINGS[fabrica].{key}", U.BUILDINGS["fabrica"][key], want)
    for kind, spec in B["drone_types"].items():
        for key, want in spec.items():
            _cmp(problems, f"UNITS.DRONE_TYPES[{kind}].{key}", U.DRONE_TYPES[kind][key], want)
    for name, (kind, bonus) in B["drone_upgrades"].items():
        _cmp(problems, f"UNITS.DRONE_UPGRADES[{name}]", (U.DRONE_UPGRADES[name]["type"], U.DRONE_UPGRADES[name]["bonus"]),
             (kind, bonus))
        _cmp(problems, f"UNITS.DRONE_TYPES[{kind}].upgrade_name", U.DRONE_TYPES[kind]["upgrade_name"], name)
    for kind, spec in B["buildings"].items():
        for key, want in spec.items():
            got = U.SELL_REFUND if key == "sell" else U.BUILDINGS[kind].get(key, 0)
            _cmp(problems, f"UNITS.BUILDINGS[{kind}].{key}", got, want)
    for kind in B["removed"]:
        if kind in U.BUILDINGS or kind in Building.STATS:
            problems.append(f"{kind} ya no debe existir como edificio (Biblia 4.0)")
    for level, spec in B["wall_levels"].items():
        for key, want in spec.items():
            _cmp(problems, f"UNITS.WALL_LEVELS[{level}].{key}", U.WALL_LEVELS[level].get(key, 0), want)
    for kind, routes in B["routes"].items():
        for rk, spec in routes.items():
            real = U.TURRET_ROUTES[kind][rk]
            for key in ("cost", "cores", "energy_extra", "set"):
                _cmp(problems, f"UNITS.TURRET_ROUTES[{kind}][{rk}].{key}", real[key], spec[key])
    for kind, spec in B["enemies"].items():
        for key, want in spec.items():
            _cmp(problems, f"UNITS.ENEMIES[{kind}].{key}", U.ENEMIES[kind].get(key, 0), want)
    for key, want in B["scavenger"].items():
        _cmp(problems, f"UNITS.SCAVENGER.{key}", U.SCAVENGER[key], want)
    for node, (branch, tier, scrap, cores, req) in B["tree"].items():
        spec = U.OPERATOR_TREE[node]
        _cmp(problems, f"UNITS.OPERATOR_TREE[{node}].branch", spec["branch"], branch)
        _cmp(problems, f"UNITS.OPERATOR_TREE[{node}].tier", spec["tier"], tier)
        _cmp(problems, f"UNITS.OPERATOR_TREE[{node}].cost", spec["cost"], scrap)
        _cmp(problems, f"UNITS.OPERATOR_TREE[{node}].cores", spec["cores"], cores)
        _cmp(problems, f"UNITS.OPERATOR_TREE[{node}].requires", spec["requires"], req)
    listed = {n for nodes in U.UPGRADES_TREE.values() for n in nodes}
    _cmp(problems, "UNITS.UPGRADES_TREE (nodos listados)", sorted(listed), sorted(B["tree"]))
    for key, want in B["effects"].items():
        _cmp(problems, f"UNITS.OPERATOR_EFFECTS[{key}]", U.OPERATOR_EFFECTS[key], want)
    for key, want in B["player"].items():
        _cmp(problems, f"UNITS.PLAYER_STATS.{key}", U.PLAYER_STATS[key], want)
    pl_hb = Player((0, 0), 800, 600)                            # la clase lee la hitbox y la regeneración de UNITS
    _cmp(problems, "Player.radius (hitbox circular)", pl_hb.radius, B["player"]["hitbox_radius"])
    _cmp(problems, "Player.rect (caja envolvente)", pl_hb.rect.size, (2 * B["player"]["hitbox_radius"],) * 2)
    pl_hb.aura_regen = True
    _cmp(problems, "Player: regeneración del bloque con AURA (HP/s)", pl_hb.regen_per_second,
         B["player"]["block_regen_rate"] + B["player"]["regen_rate"])
    for key, want in B["medkits"].items():
        _cmp(problems, f"UNITS.MEDKITS.{key}", U.MEDKITS[key], want)
    for key, want in B["ammo"].items():
        _cmp(problems, f"UNITS.AMMO_SYSTEM.{key}", U.AMMO_SYSTEM[key], want)
    _cmp(problems, "UNITS.AMMO_SYSTEM.infinite_act1", U.AMMO_SYSTEM["infinite_act1"], True)
    for key, want in B["rescues"].items():
        _cmp(problems, f"UNITS.RESCUES.vulcano_sub_1_4.{key}", U.RESCUES["vulcano_sub_1_4"].get(key), want)

    # 2) Las clases reales leen de UNITS (nada de cifras propias)
    for kind in U.ENEMIES:
        e = Enemy(kind, (0, 0), (10, 10), pygame.sprite.Group())
        base = U.ENEMIES[kind]
        _cmp(problems, f"Enemy[{kind}].hp", e.max_hp, base["hp"])
        _cmp(problems, f"Enemy[{kind}].speed", e.speed, base["speed"])
        _cmp(problems, f"Enemy[{kind}].armor", e.armor, base.get("armor", 0))
        _cmp(problems, f"Enemy[{kind}].damage (contacto)", e.damage, base["melee_dps"] * base["attack_cooldown"])
    for kind in U.BUILDINGS:
        if kind == "extractor":
            continue
        stats = Building.STATS[kind]
        for key in ("cost", "cores", "energy", "hp"):
            _cmp(problems, f"Building.STATS[{kind}].{key}", stats[key], U.BUILDINGS[kind].get(key, 0))
        if kind in ("tower", "balista"):
            b = Building(kind, (100, 100))
            _cmp(problems, f"Building({kind}).range", b.range, U.BUILDINGS[kind]["range"])
            _cmp(problems, f"Building({kind}).damage", b.damage, U.BUILDINGS[kind]["damage"])
            _cmp(problems, f"Building({kind}).fire_rate", b.fire_rate, U.BUILDINGS[kind]["fire_rate"])
            _cmp(problems, f"Building({kind}).hp", b.max_hp, U.BUILDINGS[kind]["hp"])
            _cmp(problems, f"Building({kind}).energy_cost", b.energy_cost, U.BUILDINGS[kind]["energy"])
    _cmp(problems, "Building(balista).pierce", Building("balista", (0, 0)).pierce, U.BUILDINGS["balista"]["pierce"])
    _cmp(problems, "Building(pylon).energy_cost (mantenimiento)", Building("pylon", (0, 0)).energy_cost, 1)
    for kind, spec in B["buildings"].items():                  # el menú de construcción solo ofrece estructuras que existen
        _cmp(problems, f"Building.STATS[{kind}] existe", kind in Building.STATS, True)
    _cmp(problems, "config.ENERGY_CORE", C.ENERGY_CORE, U.BUILDINGS["core"]["energy_output"])
    _cmp(problems, "Generador retirado: el Pilón es la única estructura de red",
         ("generator" in U.BUILDINGS, "generator" in Building.STATS, hasattr(C, "ENERGY_GENERATOR"),
          [b_ for _, b_ in BUILD_MENU].count("pylon")),
         (False, False, False, 1))
    _cmp(problems, "config.ENERGY_PYLON", C.ENERGY_PYLON, U.BUILDINGS["pylon"]["energy_output"])
    from src.entities.drones import DRONE_CLASSES
    from src.entities.factory import Factory, drone_stats
    for kind, cls in DRONE_CLASSES.items():
        d = cls((0, 0), drone_stats(kind))
        _cmp(problems, f"{cls.__name__}.hp", d.max_hp, U.DRONE_TYPES[kind]["hp"])
        _cmp(problems, f"{cls.__name__}.speed", d.speed, U.DRONE_TYPES[kind]["speed"])
        up = U.DRONE_TYPES[kind]["upgrade_name"]
        boosted = drone_stats(kind, {up})
        for key, value in U.DRONE_UPGRADES[up]["bonus"].items():
            _cmp(problems, f"{kind} con {up}: {key}", boosted[key], U.DRONE_TYPES[kind][key] + value)
    fac = Factory((200, 200))
    _cmp(problems, "Factory.hp", fac.max_hp, B["factory"]["hp"])
    _cmp(problems, "Factory.rect", fac.rect.size, (80, 80))
    _cmp(problems, "Factory: consumo en reposo", fac.energy_cost, 0)
    p = Player((0, 0), 100, 100)
    _cmp(problems, "Player.speed", p.speed, U.PLAYER["speed"])
    _cmp(problems, "Player.shoot_cooldown", p.shoot_cooldown, U.PLAYER["shoot_cooldown"])
    _cmp(problems, "Player.hp", p.max_hp, U.PLAYER["hp_base"])
    _cmp(problems, "Player.melee_damage", p.melee_damage, U.PLAYER["melee_damage"])
    _cmp(problems, "Player.capacity", p.capacity, U.PLAYER["ammo_capacity"])
    sc = ScavengerDrone((0, 0), (1, 1), (2, 2))
    _cmp(problems, "ScavengerDrone.speed", sc.speed, U.SCAVENGER["speed"])
    _cmp(problems, "config.PLAYER_SPEED", C.PLAYER_SPEED, U.PLAYER["speed"])
    _cmp(problems, "config.WAVE_SIZE_MULTIPLIER", C.WAVE_SIZE_MULTIPLIER, U.WAVES["size_multiplier"])
    _cmp(problems, "config.SELL_REFUND", C.SELL_REFUND, U.SELL_REFUND)
    rm = ResourceManager()
    _cmp(problems, "ResourceManager.metal inicial", rm.metal, U.RESOURCES["scrap"]["initial_act1"])
    _cmp(problems, "ResourceManager.cores inicial", rm.cores, U.RESOURCES["cores"]["initial"])
    _cmp(problems, "ResourceManager.energy_cap inicial", rm.energy_cap, U.RESOURCES["energy"]["initial_capacity"])

    # 3) Rutas de torreta: aplicar cada una debe dar exactamente los valores de la Biblia
    for kind, routes in B["routes"].items():
        for rk, spec in routes.items():
            b = Building(kind, (0, 0))
            b.choose_route(rk)
            for attr, want in spec["set"].items():
                _cmp(problems, f"Building({kind}) ruta {rk}: {attr}", getattr(b, attr), want)
    # 3b) Consumo total tras la ruta: Tesla 12 + 15 = 27; Lanzallamas 5 + 3 = 8
    tesla = Building("balista", (0, 0))
    tesla.choose_route("B")
    _cmp(problems, "Tesla: consumo total", tesla.energy_cost, 27)
    flame = Building("tower", (0, 0))
    flame.choose_route("B")
    _cmp(problems, "Lanzallamas: consumo total", flame.energy_cost, U.ENERGY_COSTS["lanzallamas"])
    # 3c) Mejoras del muro
    wall = Building("wall", (0, 0))
    for level, spec in B["wall_levels"].items():
        wall.apply_wall_level(level)
        _cmp(problems, f"Building(wall) nivel {level}: hp", wall.max_hp, spec["hp"])
        _cmp(problems, f"Building(wall) nivel {level}: consumo", wall.energy_cost, spec["energy"])
    _cmp(problems, "Building(wall) Reforzado: ram_reduction", wall.ram_reduction, 0.30)
    _cmp(problems, "Building(wall) Electrificado: counter_damage", wall.counter_damage, 20)
    _cmp(problems, "Building(wall): venta (70% de lo invertido)", wall.sell_value,
         int((B["buildings"]["wall"]["cost"] + B["wall_levels"][2]["cost"] + B["wall_levels"][3]["cost"]) * 0.70))
    _cmp(problems, "Carroñero roba núcleos", hasattr(ScavengerDrone((0, 0), (1, 1), (2, 2)), "cores_value"), True)
    # 4) Árbol de mejoras (2 ramas lineales, solo Núcleos de Plasma): los efectos de cada nodo llegan al Operador
    import collections
    import json as _json
    from src.managers.resource_manager import CampaignRun as _CR4
    fx = B["effects"]
    rm = ResourceManager()
    rm.metal, rm.cores = 10 ** 6, 100
    _cmp(problems, "Árbol: Ofensiva de 3 nodos y Supervivencia de 4 (Celda Vital I y II)",
         {br: len(nodes) for br, nodes in U.UPGRADES_TREE.items()}, {"offensive": 3, "survival": 4})
    _cmp(problems, "Árbol: sin chatarra en ningún nodo", [U.OPERATOR_TREE[n]["cost"] for n in U.OPERATOR_TREE], [0] * 7)
    rm_lock = ResourceManager()
    rm_lock.cores = 50
    _cmp(problems, "Árbol: un nodo no se compra sin su prerrequisito",
         (rm_lock.buy_node("sobrecarga_balistica"), rm_lock.buy_node("celda_vital"), rm_lock.cores), (False, False, 50))
    for node in B["tree"]:
        _cmp(problems, f"Árbol: comprar {node}", rm.buy_node(node), True)
    _cmp(problems, "Árbol: coste total en Núcleos (1+3+5 y 1+3+4+6 = 23)", 100 - rm.cores, 23)
    _cmp(problems, "Árbol: comprar de nuevo no cobra", (rm.buy_node("impulso_doble"), rm.cores), (False, 77))
    _cmp(problems, "Árbol: Nanoregeneración retirada", "nanoregeneracion" in U.OPERATOR_TREE, False)
    _cmp(problems, "Recompensa de asalto con nombre propio (no choca con la mejora del Terminal)",
         U.REWARD_DEFINITIONS["DRONE_UPGRADE_ATTACK"]["name"], "Cañón Pesado de Asalto")
    pl = Player((0, 0), 100, 100)
    pl.apply_upgrades(rm)
    _cmp(problems, "Player (árbol completo): disparo automático", pl.automatic_fire, True)
    _cmp(problems, "Player (árbol completo).shoot_cooldown", pl.shoot_cooldown, fx["overload_cooldown"])
    _cmp(problems, "Player (árbol completo).bullet_damage", pl.bullet_damage, fx["rifle_damage_tier3"])
    _cmp(problems, "Player (árbol completo).bullet_pierce", pl.bullet_pierce, fx["rifle_pierce_tier2"])
    _cmp(problems, "Player (árbol completo).dash_charges_max", pl.dash_charges_max, fx["dash_charges"])
    _cmp(problems, "Player (árbol completo).flat_armor", pl.flat_armor, fx["flat_armor"])
    _cmp(problems, "Player (árbol completo): regeneración base (sin Nanoregeneración)", (pl.regen_delay, pl.regen_mult),
         (B["player"]["regen_delay"], 1.0))
    _cmp(problems, "Player (árbol completo).capacity (sin bonus de árbol)", pl.capacity, B["player"]["ammo_capacity"])
    _cmp(problems, "Player (árbol completo): Celda Vital I y II = 5 bloques (166 HP)",
         (pl.health_blocks, pl.max_hp), (B["player"]["health_blocks"] + 2 * fx["extra_blocks"], 166))
    rm_c1 = ResourceManager()
    rm_c1.op_nodes.update({"impulso_doble", "blindaje_titanio", "celda_vital"})
    _cmp(problems, "Celda Vital I sola: 4 bloques y 133 HP", (rm_c1.extra_health_blocks(), rm_c1.player_max_hp), (1, 133))
    rm_a = ResourceManager()
    rm_a.cores = 20
    for node in ("gatillo_automatico", "calibre_perforante"):
        rm_a.buy_node(node)
    pl_a = Player((0, 0), 100, 100)
    pl_a.apply_upgrades(rm_a)
    _cmp(problems, "Player (A1+A2): daño 16, perfora 1 más, cadencia 0,15 s",
         (pl_a.bullet_damage, pl_a.bullet_pierce, pl_a.shoot_cooldown), (fx["rifle_damage_tier2"], 2, B["player"]["shoot_cooldown"]))
    pl_base = Player((0, 0), 100, 100)
    pl_base.apply_upgrades(ResourceManager())
    _cmp(problems, "Player sin árbol: daño 12, 1 carga de Dash, sin armadura plana, regeneración base",
         (pl_base.bullet_damage, pl_base.bullet_pierce, pl_base.automatic_fire, pl_base.dash_charges_max, pl_base.flat_armor,
          pl_base.regen_delay, pl_base.regen_mult),
         (B["player"]["shoot_damage"], 1, False, 1, 0, B["player"]["regen_delay"], 1.0))
    # el disparo sale con el daño y la perforación del Operador
    pl.projectile_groups = (pygame.sprite.Group(),)
    pl.shoot()
    bullet_ = next(iter(pl.projectile_groups[0]))
    _cmp(problems, "Player.shoot: la bala lleva daño 20 y pierce 2", (bullet_.damage, bullet_.pierce), (20, 2))
    # armadura plana (B2): -4 por impacto, mínimo 1; en daño continuo, -4 HP/s (mínimo 1 HP/s)
    pl.hp = pl.max_hp
    pl.take_damage(10, direct=True)
    pl.take_damage(2, direct=True)
    _cmp(problems, "Player (Blindaje de Titanio): 10 -> 6 y 2 -> 1", pl.max_hp - pl.hp, 7)
    pl.hp = pl.max_hp
    for _ in range(60):
        pl.take_damage(8 / 60, direct=True, continuous_dt=1 / 60)
    _cmp(problems, "Player (Blindaje de Titanio): mordida de 8 HP/s -> 4 HP/s", round(pl.max_hp - pl.hp, 4), 4.0)
    # Impulso Doble (B1): 2 dashes seguidos, i-frames propios y recargas independientes
    ks = collections.defaultdict(bool)

    def tick(n, shift):
        ks[pygame.K_LSHIFT] = shift
        for _ in range(n):
            pl._update_dash(1 / 60, ks, pygame.math.Vector2())
    tick(1, True)
    _cmp(problems, "Dash 1: i-frames y una carga restante", (pl.is_invulnerable, pl.dash_charges), (True, 1))
    tick(12, False)
    _cmp(problems, "Dash 1 terminado: sin i-frames", (pl.is_invulnerable, pl.dash_timer), (False, 0.0))
    tick(1, True)
    _cmp(problems, "Dash 2 en rápida sucesión: i-frames propios y 0 cargas", (pl.is_invulnerable, pl.dash_charges), (True, 0))
    tick(12, False)
    tick(1, True)
    _cmp(problems, "Sin cargas no hay tercer dash", (pl.dash_timer, pl.dash_charges), (0.0, 0))
    tick(60, False)
    _cmp(problems, "Recarga independiente: vuelve la primera carga antes que la segunda", pl.dash_charges, 1)
    tick(15, False)
    _cmp(problems, "...y luego la segunda", pl.dash_charges, 2)
    ks[pygame.K_LSHIFT] = True                                    # SHIFT sostenido: una pulsación = un dash
    pl._dash_prev = True
    pl.dash_timer = 0.0
    pl._update_dash(1 / 60, ks, pygame.math.Vector2())
    _cmp(problems, "Impulso Doble: mantener SHIFT no gasta las dos cargas", (pl.dash_timer, pl.dash_charges), (0.0, 2))
    # árbol completo (5 bloques): la regeneración del bloque es la base, 3,0 s y 5 + 2,5 HP/s
    pl.aura_regen = True
    pl.hp = 50.0
    pl.since_hit = 2.9
    pl._regenerate(1.0)
    _cmp(problems, "Árbol completo: antes de 3,0 s no regenera", pl.hp, 50.0)
    pl.since_hit = 3.0
    pl._regenerate(1.0)
    _cmp(problems, "Árbol completo: desde 3,0 s, 5 + 2,5 HP/s (bloques de 33,2)", pl.hp, 57.5)
    pl_base.aura_regen = True
    pl_base.hp = 50.0
    pl_base.since_hit = 2.9
    pl_base._regenerate(1.0)
    _cmp(problems, "Regeneración del bloque: antes de 3,0 s no regenera", pl_base.hp, 50.0)
    pl_base.since_hit = 3.0
    pl_base._regenerate(1.0)
    _cmp(problems, "Regeneración del bloque: desde 3,0 s, 5 + 2,5 HP/s", pl_base.hp, 57.5)
    pl_base._regenerate(10.0)
    _cmp(problems, "Regeneración del bloque: se detiene en el tope del bloque (2 de 3)", round(pl_base.hp, 3), round(200 / 3, 3))
    pl_base.hp = 30.0
    pl_base._regenerate(10.0)
    _cmp(problems, "Bloque vaciado: no se regenera por encima de su tope (1 de 3)", round(pl_base.hp, 3), round(100 / 3, 3))
    _cmp(problems, "Botiquín: devuelve un bloque perdido", (pl_base.use_medkit(), round(pl_base.hp, 3)), (True, round(200 / 3, 3)))
    # persistencia en CampaignRun (sin romper partidas antiguas)
    saved_ = rm.campaign_run.to_dict()
    _cmp(problems, "CampaignRun.to_dict: op_nodes serializable", (sorted(saved_["op_nodes"]) == sorted(B["tree"]),
                                                                  bool(_json.dumps(saved_))), (True, True))
    _cmp(problems, "CampaignRun: op_nodes ida y vuelta", _CR4.from_dict(saved_).op_nodes, set(B["tree"]))
    _cmp(problems, "CampaignRun.from_dict sin op_nodes (partida antigua)", _CR4.from_dict({}).op_nodes, set())
    old_ = _CR4.from_dict({"op_nodes": ["disparador_automatico", "modulo_iman", "cadencia_extrema", "inventado"]})
    _cmp(problems, "Partida del árbol anterior: Disparador -> Gatillo; el resto, devuelto en Núcleos (3 + 3)",
         (old_.op_nodes, old_.legacy_core_refund), ({"gatillo_automatico"}, 6))
    _cmp(problems, "CampaignRun: un nodo sin su prerrequisito se descarta",
         _CR4.from_dict({"op_nodes": ["celda_vital", "blindaje_titanio"]}).op_nodes, set())
    nano_ = _CR4.from_dict({"op_nodes": ["impulso_doble", "blindaje_titanio", "nanoregeneracion", "celda_vital"]})
    _cmp(problems, "Partida con Nanoregeneración: se devuelven sus 3 Núcleos y la Celda Vital I se conserva",
         (nano_.op_nodes, nano_.legacy_core_refund), ({"impulso_doble", "blindaje_titanio", "celda_vital"}, 3))
    rm_old = ResourceManager()
    rm_old.campaign_run = old_
    cores_before = rm_old.cores
    _cmp(problems, "ResourceManager.claim_core_refund: cobra una sola vez",
         (rm_old.claim_core_refund(), rm_old.cores - cores_before, rm_old.claim_core_refund()), (6, 6, 0))
    _cmp(problems, "ResourceManager.op_nodes vive en CampaignRun", rm.op_nodes is rm.campaign_run.op_nodes, True)
    rm_snap = ResourceManager()
    rm_snap.cores = 10
    rm_snap.buy_node("impulso_doble")
    snap_ = rm_snap.snapshot()
    rm_snap.op_nodes.clear()
    rm_snap.restore(snap_)
    _cmp(problems, "Checkpoint: los nodos comprados se restauran", rm_snap.op_nodes, {"impulso_doble"})
    from src.entities.drones import AuraDrone, ReconDrone
    _cmp(problems, "Explorador: detección de chatarra", ReconDrone((0, 0), drone_stats("recon")).scan_range,
         U.DRONE_TYPES["recon"]["scan_range"])
    for key, want in B["aura_chassis"].items():
        _cmp(problems, f"UNITS.AURA_CHASSIS.{key}", U.AURA_CHASSIS[key], want)
    for key, want in B["aura_drone"].items():
        _cmp(problems, f"UNITS.DRONES[aura].{key}", U.DRONES["aura"][key], want)
    _cmp(problems, "AuraDrone.hp", AuraDrone((0, 0)).max_hp, B["aura_drone"]["hp"])
    _cmp(problems, "UNITS.CHASSIS_SURPLUS", U.CHASSIS_SURPLUS, B["chassis_surplus"])
    rm_ch = ResourceManager()
    rm_ch.chassis_found = C.CHASSIS_TOTAL_PARTS - 1
    _cmp(problems, "Chasis de AURA: no caen más piezas de las 6 necesarias (contando las del suelo)",
         (rm_ch.chassis_part_due(), rm_ch.chassis_part_due(1)), (True, False))
    for key, want in B["enemy_bases"].items():
        _cmp(problems, f"UNITS.ENEMY_BASES.{key}", U.ENEMY_BASES[key], want)
    for diff, want in B["enemy_priority"].items():
        _cmp(problems, f"UNITS.ENEMY_BASES.priority[{diff}]", U.ENEMY_BASES["priority"][diff], want)
    for alert, want in B["bases_by_alert"].items():
        _cmp(problems, f"UNITS.ENEMY_BASES.by_alert[{alert}]", tuple(U.ENEMY_BASES["by_alert"][alert]), want)
    for key, want in B["fog"].items():
        _cmp(problems, f"UNITS.FOG.{key}", U.FOG[key], want)
    for key, want in B["campaign_maps"].items():                                  # Prioridad 3.B
        cfg = U.CAMPAIGN_MAPS[key]
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].difficulty", cfg["difficulty"], want["difficulty"])
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].map_size", tuple(cfg["map_size"]), want["map_size"])
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].player_base", tuple(cfg["player_base"]), want["player_base"])
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].enemy_bases", (cfg["enemy_bases"], len(cfg["enemy_spawn_positions"])),
             (want["bases"], want["bases"]))
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].wave_small_sizes", cfg["wave_small_sizes"], want["small"])
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].wave_big_sizes", cfg["wave_big_sizes"], want["big"])
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].total_duration", cfg["total_duration"], want["total"])
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].break_time", cfg["break_time"], B["campaign_break"])
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].rewards", [r["id"] for r in cfg["rewards"]][:len(want["rewards"])], want["rewards"])
        w_, h_ = cfg["map_size"]
        for slot in cfg["enemy_spawn_positions"]:                                # todo cabe dentro del mapa
            if not (0 < slot["x"] < w_ and 0 < slot["y"] < h_):
                problems.append(f"CAMPAIGN_MAPS[{key}]: base {slot['id']} fuera del mapa")
        cc_ = cfg["player_base"]
        for off_ in cfg.get("outer_deposits", ()):                               # depósitos exteriores: dentro del mapa y fuera de la base
            x_, y_ = cc_[0] + off_[0], cc_[1] + off_[1]
            if not (60 < x_ < w_ - 60 and 60 < y_ < h_ - 60) or (off_[0] ** 2 + off_[1] ** 2) ** 0.5 < 400:
                problems.append(f"CAMPAIGN_MAPS[{key}]: depósito exterior {off_} fuera del mapa o demasiado cerca de la base")
        for rw in cfg["rewards"]:                                                # cada premio tiene efecto definido
            if rw["id"] not in U.REWARD_DEFINITIONS:
                problems.append(f"CAMPAIGN_MAPS[{key}]: premio {rw['id']} sin definición en REWARD_DEFINITIONS")
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].wave_big_interval", cfg["wave_big_interval"], B["campaign_big_interval"])
        # Stronghold Loop: tras cada N pequeñas una grande; tamaños en bucle y la grande repite la última
        n_small, n_big = len(want["small"]), len(want["big"])
        cycle = B["campaign_big_interval"] + 1
        for n in range(1, 4 * cycle * max(n_small, n_big)):
            kind, size, roster = U.campaign_wave_entry(cfg, n)
            c_, pos_ = divmod(n - 1, cycle)
            exp_kind = "big" if pos_ == cycle - 1 else "small"
            exp_size = (want["big"][min(c_, n_big - 1)] if exp_kind == "big"
                        else want["small"][(c_ * B["campaign_big_interval"] + pos_) % n_small])
            if (kind, size) != (exp_kind, exp_size) or len(roster) != size or any(k not in U.ENEMIES for k in roster):
                problems.append(f"campaign_wave_entry[{key}][{n}]: {kind}/{size} en vez de {exp_kind}/{exp_size}")
                break
        _cmp(problems, f"campaign_wave_plan[{key}] (primera vuelta)", len(U.campaign_wave_plan(cfg)), n_small + n_small // 5)
        _cmp(problems, f"CAMPAIGN_MAPS[{key}].spawn_interval", cfg.get("spawn_interval", U.CAMPAIGN_SPAWN_INTERVAL),
             B["campaign_spawn_interval"])
    from src.mechanics.rewards import RewardTracker
    P5 = B["p5"]                                                                # Prioridad 5 y Bloque 3.A
    _cmp(problems, "Reward de regeneración (PLAYER_UPGRADE_4)", U.REWARD_DEFINITIONS["PLAYER_UPGRADE_4"]["bonus"]["regen_rate"],
         P5["regen_rate"])
    for key, want in P5["gate"].items():
        _cmp(problems, f"BUILDINGS[compuerta].{key}", U.BUILDINGS["compuerta"][key], want)
    _cmp(problems, "BUILDINGS[compuerta].bloquea enemigos y abre a aliados",
         (U.BUILDINGS["compuerta"]["blocks_enemies"], tuple(U.BUILDINGS["compuerta"]["auto_opens_for"])),
         (True, ("player", "drones")))
    _cmp(problems, "VULCANO_DEFENSE.final_horde", U.VULCANO_DEFENSE["final_horde"], P5["final_horde"])
    _cmp(problems, "VULCANO_DEFENSE.overload_line_at", U.VULCANO_DEFENSE["overload_line_at"], P5["overload_line_at"])
    _cmp(problems, "OPERATOR_BONUSES cubre todos los nodos", sorted(U.OPERATOR_BONUSES), sorted(U.OPERATOR_TREE))
    _cmp(problems, "OPERATOR_BONUSES: nombres públicos únicos", len({v["name"] for v in U.OPERATOR_BONUSES.values()}),
         len(U.OPERATOR_BONUSES))
    fxb = U.OPERATOR_EFFECTS                              # las cifras que coinciden con efectos reales del Operador
    for node, key, want in (("sobrecarga_balistica", "fire_cooldown", fxb["overload_cooldown"]),
                            ("blindaje_titanio", "flat_armor", fxb["flat_armor"]),
                            ("celda_vital", "health_blocks", fxb["extra_blocks"]),
                            ("celda_vital_2", "health_blocks", fxb["extra_blocks"]),
                            ("impulso_doble", "dash_charges", 1), ("calibre_perforante", "bullet_pierce", 1)):
        _cmp(problems, f"OPERATOR_BONUSES[{node}].{key}", U.OPERATOR_BONUSES[node]["bonus"][key], want)
    _cmp(problems, "OPERATOR_BONUSES: daño del rifle 12 + A2 + A3 = 20",
         B["player"]["shoot_damage"] + U.OPERATOR_BONUSES["calibre_perforante"]["bonus"]["bullet_damage"]
         + U.OPERATOR_BONUSES["sobrecarga_balistica"]["bonus"]["bullet_damage"], fxb["rifle_damage_tier3"])
    _cmp(problems, "OPERATOR_BONUSES: daño del rifle 12 + A2 = 16",
         B["player"]["shoot_damage"] + U.OPERATOR_BONUSES["calibre_perforante"]["bonus"]["bullet_damage"], fxb["rifle_damage_tier2"])
    from src.mechanics.upgrades import UpgradeManager
    um_ = UpgradeManager()
    um_.unlock_node("Blindaje_Titanio")
    _cmp(problems, "UpgradeManager: bonus de Blindaje de Titanio", um_.get_bonus("flat_armor"), fxb["flat_armor"])
    _cmp(problems, "UpgradeManager: categorías", sorted(um_.upgrade_tree), ["OFENSIVA", "RECOMPENSAS", "SUPERVIVENCIA"])
    um_.unlock_node("Regen_Enhanced")                                           # el reward de regeneración sigue ahí
    pl_r = Player((0, 0), 800, 600)
    pl_r.apply_upgrades(um_.res)
    _cmp(problems, "Player con el reward de regeneración", (pl_r.regen_rate, pl_r.flat_armor), (P5["regen_rate"], fxb["flat_armor"]))
    R = B["rewards"]                                                            # Prioridad 4: rewards
    _cmp(problems, "REWARD_DEFINITIONS: total", len(U.REWARD_DEFINITIONS), R["aura_parts"] + len(R["player"]) + len(R["drone"]))
    _cmp(problems, "REWARD_DEFINITIONS: AURA_PART_1..6", sorted(k for k, v in U.REWARD_DEFINITIONS.items()
                                                                  if v["type"] == "aura_part"),
         [f"AURA_PART_{i}" for i in range(1, R["aura_parts"] + 1)])
    for rid, bonus in R["player"].items():
        _cmp(problems, f"REWARD_DEFINITIONS[{rid}].bonus", U.REWARD_DEFINITIONS[rid]["bonus"], bonus)
    for rid, (dtype, bonus, node) in R["drone"].items():
        spec_ = U.REWARD_DEFINITIONS[rid]
        _cmp(problems, f"REWARD_DEFINITIONS[{rid}]", (spec_["drone_type"], spec_["bonus"], spec_["operator_tree_node"]),
             (dtype, bonus, node))
        _cmp(problems, f"REWARD_DEFINITIONS[{rid}] nodo = mejora de la Fábrica", U.DRONE_UPGRADES[node]["type"], dtype)
        rt_ = RewardTracker()
        rt_.add_reward(rid)
        for key_, val_ in bonus.items():                                        # el dron nace con el bonus del reward
            _cmp(problems, f"drone_stats({dtype}) con {rid}.{key_}", round(drone_stats(dtype, (), rt_)[key_], 6),
                 round(U.DRONE_TYPES[dtype].get(key_, 0) + val_, 6))
    _cmp(problems, "UNITS.REWARD_REGEN_DELAY", U.REWARD_REGEN_DELAY, R["regen_delay"])
    from src.managers.resource_manager import ResourceManager as _RM
    rm_ = _RM()
    for rid in R["player"]:
        rm_.reward_tracker.add_reward(rid)
    pl_ = Player((0, 0), 800, 600)
    pl_.apply_upgrades(rm_)
    _cmp(problems, "Player con rewards: velocidad", pl_.speed, C.PLAYER_SPEED + 50)
    _cmp(problems, "Player con rewards: vida máxima", pl_.max_hp, C.PLAYER_START_HP + 50)
    _cmp(problems, "Player con rewards: munición máxima", pl_.capacity, C.PLAYER_AMMO_CAPACITY + 100)
    _cmp(problems, "Player con rewards: reducción de daño", round(pl_.armor_reduction, 6), 0.20)
    _cmp(problems, "Player con rewards: regeneración y visión", (pl_.regen_rate, pl_.vision_bonus), (3, 100))
    esc = B["enemy_ai_escalation"]                                              # Prioridad 3.C: la IA acelera al perder edificios
    from src.entities.enemy_base import EnemyBase as _EB
    eb_ = _EB((0, 0), "easy")
    for _ in range(esc["every"]):
        eb_.on_building_lost(object())
    _cmp(problems, "EnemyBase: intervalo de IA tras 3 edificios perdidos", eb_.ai_action_interval,
         B["enemy_bases"]["ai_interval"] - esc["step"])
    for _ in range(200):
        eb_.on_building_lost(object())
    _cmp(problems, "EnemyBase: suelo del intervalo de IA", eb_.ai_action_interval, esc["floor"])
    _cmp(problems, "Explorador: radio de visión = el de la niebla", U.DRONE_TYPES["recon"]["vision_range"], B["fog"]["recon_radius"])
    for kind in set(k for lst in B["enemy_priority"].values() for k in lst):
        _cmp(problems, f"UNITS.ENEMY_BASES.structures tiene {kind}", kind in U.ENEMY_BASES["structures"], True)
    from src.entities.enemy_base import EnemyBase
    eb = EnemyBase((0, 0), "medium")
    _cmp(problems, "EnemyBase.health", eb.health, B["enemy_bases"]["core_hp"])
    _cmp(problems, "EnemyBase.scrap", eb.scrap, B["enemy_bases"]["start_scrap"])
    _cmp(problems, "EnemyBase.build_priority", eb.build_priority, B["enemy_priority"]["medium"])
    for key, want in B["vulcano_defense"].items():
        _cmp(problems, f"UNITS.VULCANO_DEFENSE.{key}", U.VULCANO_DEFENSE[key], want)
    # 4b) Balance P1: ritmo de oleadas y efectos de armadura
    _cmp(problems, "config.BREAK_TIME", C.BREAK_TIME, B["pacing"]["break_time"])
    _cmp(problems, "UNITS.WAVES[5]", U.WAVES["composition"][5], B["pacing"]["wave5"])
    _cmp(problems, "UNITS.WAVES[4] arietes", dict((e[0], e[1]) for e in U.WAVES["composition"][4]).get("ariete", 0),
         B["pacing"]["wave4_rams"])
    # Alivio de la oleada 3: sin Ariete SOLO a alertas 1-2; a alertas 3-5 la oleada 3 queda como en la composición base
    from src.mechanics.wave import Wave as _Wave
    w3_ = {a: dict(_Wave(3, a, (0, 0)).get_enemy_spawns()) for a in range(1, 6)}
    _cmp(problems, "UNITS.WAVE_ALERT_RELIEF: oleada 3 sin Ariete solo a alertas 1-2",
         [w3_[a].get("ariete", 0) > 0 for a in range(1, 6)], [False, False, True, True, True])
    _cmp(problems, "UNITS.WAVE_ALERT_RELIEF: solo la oleada 3, a alertas 1-2",
         {n: sorted(v) for n, v in U.WAVE_ALERT_RELIEF.items()}, {3: [1, 2]})
    import pygame as _pg
    for kind_, expect in (("soldier", 10 - 0), ("tank", 10 - 4)):           # Minigun: 10 de daño perforando 4
        e_ = Enemy(kind_, (0, 0), (1, 1), _pg.sprite.Group())
        _cmp(problems, f"Minigun vs {kind_} (daño por bala)", e_.mitigate(10, None, 4), expect)
    e_ = Enemy("tank", (0, 0), (1, 1), _pg.sprite.Group())
    _cmp(problems, "Lanzallamas vs tank (tick 0.1 s, ignora armadura)", e_.mitigate(5, None, 99), 5)
    # 4a-sexies) Flota F1-F4: capas aérea/terrestre, tope de Exploradores y datos de cada dron
    from src.entities import WorldRefs as _W4
    from src.entities.drones import DRONE_CLASSES as _DC4, Bomb as _Bomb
    from src.entities.factory import Factory as _F4, explorer_cap as _ecap4
    _cmp(problems, "Flota: solo recon/attack/bomber/trooper", sorted(U.DRONE_TYPES), ["attack", "bomber", "recon", "trooper"])
    _cmp(problems, "Flota: clases", sorted(_DC4), ["attack", "bomber", "recon", "trooper"])
    _cmp(problems, "Flota: teclas F1-F4", [U.DRONE_TYPES[k]["key"] for k in ("recon", "attack", "bomber", "trooper")],
         ["F1", "F2", "F3", "F4"])
    layers = {k: (U.DRONE_TYPES[k]["layer"], _DC4[k]((0, 0), drone_stats(k)).aerial) for k in _DC4}
    _cmp(problems, "Capas: Explorador, Asalto y Bombardero aéreos; Soldado terrestre", layers,
         {"recon": ("air", True), "attack": ("air", True), "bomber": ("air", True), "trooper": ("ground", False)})
    atk = U.DRONE_TYPES["attack"]
    _cmp(problems, "Asalto: láser 16 c/0,5 s a 190 px (DPS 32), 140 HP, 40 de chatarra",
         (atk["damage"] / atk["shot_interval"], atk["range"], atk["hp"], atk["cost"]), (32.0, 190, 140, 40))
    trp = U.DRONE_TYPES["trooper"]
    _cmp(problems, "Soldado Dron: 15 c/0,4 s a 160 px, armadura 3", (trp["damage"], trp["shot_interval"], trp["range"],
                                                                  trp["armor"]), (15, 0.4, 160, 3))
    t_big, t_small = _DC4["trooper"]((0, 0), drone_stats("trooper")), _DC4["trooper"]((0, 0), drone_stats("trooper"))
    t_big.take_damage(10)
    t_small.take_damage(2)
    _cmp(problems, "Soldado Dron: la armadura resta a cada impacto (mínimo 1)",
         (t_big.max_hp - t_big.hp, t_small.max_hp - t_small.hp), (7.0, 1.0))
    w4 = _W4()
    caps = []
    for i in range(4):
        g = _F4((100 + 200 * i, 100))
        g.build_left, g.is_powered, g.world = 0.0, True, w4
        w4.factories.add(g)
        caps.append(_ecap4(w4))
    _cmp(problems, "Tope de Exploradores con 1, 2, 3 y 4 fábricas operativas", caps, [2, 3, 4, 4])
    bomb_ = _Bomb((0, 0), 75, 60, 0.5)
    _cmp(problems, "Bomba: 75 de daño en radio 60 (caída 0,5 s)", (bomb_.damage, bomb_.radius, bomb_.fall_time), (75, 60, 0.5))
    # 4a-quinquies) Bloque 3: nada de plasma en defensa/drones, Tech-Tree de torretas y capacidad dinámica de la flota
    from src.entities.factory import Factory as _Fac, fleet_capacity as _cap
    from src.entities import WorldRefs as _W3
    from src.managers.resource_manager import CampaignRun as _CR3
    for kind in ("tower", "balista", "fabrica"):
        _cmp(problems, f"{kind}: sin núcleos", U.BUILDINGS[kind]["cores"], 0)
    for turret, routes in U.TURRET_ROUTES.items():
        for r, spec_ in routes.items():
            _cmp(problems, f"TURRET_ROUTES[{turret}][{r}]: solo chatarra", spec_["cores"], 0)
    _cmp(problems, "Costes de drones 25/40/75/50 (solo chatarra, Fase 5)",
         tuple((U.DRONE_TYPES[k]["cost"], U.DRONE_TYPES[k]["cores"]) for k in ("recon", "attack", "bomber", "trooper")),
         ((25, 0), (40, 0), (75, 0), (50, 0)))
    _cmp(problems, "Menú de producción: [1] Asalto [2] Explorador [3] Bombardero [4] Soldado", U.PRODUCTION_MENU,
         ("attack", "recon", "bomber", "trooper"))
    _cmp(problems, "Torreta Ligera / Balista base", (U.BUILDINGS["tower"]["cost"], U.BUILDINGS["tower"]["energy"],
                                                      U.BUILDINGS["balista"]["cost"], U.BUILDINGS["balista"]["energy"]),
         (45, 5, 100, 12))
    _cmp(problems, "Especializaciones: chatarra extra 60/60/90/110", tuple(
        U.TURRET_ROUTES[t][r]["cost"] for t, r in (("tower", "A"), ("tower", "B"), ("balista", "A"), ("balista", "B"))),
         (60, 60, 90, 110))
    _cmp(problems, "Especializaciones: energía extra 0/3/0/15", tuple(
        U.TURRET_ROUTES[t][r]["energy_extra"] for t, r in (("tower", "A"), ("tower", "B"), ("balista", "A"), ("balista", "B"))),
         (0, 3, 0, 15))
    _cmp(problems, "TURRET_TECH cubre las 4 ramas", sorted(U.TURRET_TECH),
         sorted(f"{t}_{r}" for t in U.TURRET_ROUTES for r in U.TURRET_ROUTES[t]))
    rm3 = ResourceManager()
    _cmp(problems, "Tech-Tree: todo bloqueado de inicio", [k for k in U.TURRET_TECH if rm3.route_unlocked(*k.split("_"))], [])
    rm3.alloy = 2
    _cmp(problems, "Tech-Tree: desbloquear cuesta aleación", (rm3.unlock_route("tower_A"), rm3.alloy), (True, 0))
    _cmp(problems, "Tech-Tree: sin aleación no se desbloquea otra", (rm3.unlock_route("balista_B"), rm3.route_unlocked("balista", "B")),
         (False, False))
    _cmp(problems, "Tech-Tree: persiste en CampaignRun", _CR3.from_dict(rm3.campaign_run.to_dict()).tech_unlocked, {"tower_A"})
    _cmp(problems, "Tech-Tree: partida antigua sin datos = nada desbloqueado", _CR3.from_dict({}).tech_unlocked, set())
    w3 = _W3()
    f1, f2 = _Fac((100, 100)), _Fac((300, 100))
    for f in (f1, f2):
        f.build_left, f.is_powered, f.world = 0.0, True, w3
        w3.factories.add(f)
    _cmp(problems, "Capacidad: 2 fábricas operativas = 16", _cap(w3), 16)
    f2.is_powered = False
    _cmp(problems, "Capacidad: una sin red no suma", _cap(w3), 8)
    f2.is_powered, f2.build_left = True, 5.0
    _cmp(problems, "Capacidad: una sin desplegar no suma", _cap(w3), 8)
    # 4a-quater) Bloque 2: muros por cursor y Compuerta ligada a la red
    from src.entities.building import Compuerta as _Gate
    _cmp(problems, "Muro N1", (U.STRUCTURES["wall"]["cost"], U.STRUCTURES["wall"]["energy"], U.STRUCTURES["wall"]["hp"]),
         (30, 0, 400))
    _cmp(problems, "Muro N2 Reforzado: coste, HP, -30% embestida",
         (U.WALL_LEVELS[2]["cost"], U.WALL_LEVELS[2]["cores"], U.WALL_LEVELS[2]["hp"], U.WALL_LEVELS[2]["ram_reduction"]),
         (30, 0, 900, 0.30))
    _cmp(problems, "Muro N3 Electrificado: +60⚙, 2⚡, sin núcleos, 1400 HP, refleja 20",
         (U.WALL_LEVELS[3]["cost"], U.WALL_LEVELS[3]["cores"], U.WALL_LEVELS[3]["energy"], U.WALL_LEVELS[3]["hp"],
          U.WALL_LEVELS[3]["counter_damage"]), (60, 0, 2, 1400, 20))
    gate_ = _Gate((0, 0))
    _cmp(problems, "Compuerta: 45⚙, 1⚡, 500 HP", (gate_.stats["cost"], gate_.stats["energy"], gate_.max_hp), (45, 1, 500))
    _cmp(problems, "Compuerta: depende de la red", gate_.requires_power, True)
    gate_.is_powered, gate_.energized = True, True
    gate_.open()
    _cmp(problems, "Compuerta con energía: se abre y deja pasar a un aliado",
         (gate_.is_open, gate_.ally_passable), (True, True))
    gate_.is_powered = False                                                      # corte o sabotaje
    gate_.update(0.1)
    _cmp(problems, "Compuerta sin energía: congelada cerrada y sólida para todos",
         (gate_.is_open, gate_.ally_passable, gate_.check_collision(type("A", (), {"is_ally": True})())), (False, False, False))
    gate_.open()
    _cmp(problems, "Compuerta sin energía: no se abre", gate_.is_open, False)
    # 4a-ter) Infraestructura y red: catálogo exacto, y el Extractor de Plasma ya no existe
    from src.entities.building import BUILD_MENU, create_building
    for kind, want in B["infra"].items():
        for key, value in want.items():
            _cmp(problems, f"UNITS.BUILDINGS[{kind}].{key}", U.BUILDINGS[kind][key], value)
    _cmp(problems, "Extractor de chatarra: depósito agotable (suministro)", C.DEPOSIT_METAL > 0, True)
    _cmp(problems, "config.EXTRACTOR_INCOME/INTERVAL", (C.EXTRACTOR_INCOME, C.EXTRACTOR_INTERVAL), (5, 1.2))
    _cmp(problems, "Extractor de chatarra: tasa x2.5 respecto a los 5 c/3 s originales",
         round((C.EXTRACTOR_INCOME / C.EXTRACTOR_INTERVAL) / (5 / 3.0), 6), 2.5)
    _cmp(problems, "config.ENERGY_CORE/PYLON", (C.ENERGY_CORE, C.ENERGY_PYLON), (50, 5))
    _cmp(problems, "Centro de Control: HP", Building("core", (0, 0)).max_hp, 500)
    for kind in ("plasma_extractor",):
        _cmp(problems, f"purga: {kind} fuera de UNITS.BUILDINGS/STRUCTURES/TOOLTIPS",
             (kind in U.BUILDINGS, kind in U.STRUCTURES, kind in U.TOOLTIPS), (False, False, False))
        _cmp(problems, f"purga: {kind} fuera de Building.STATS/LABELS/SIZES", (kind in Building.STATS, kind in Building.LABELS,
                                                                           kind in Building.SIZES), (False, False, False))
        _cmp(problems, f"purga: {kind} fuera del menú de construcción", kind in [b for _, b in BUILD_MENU], False)
        try:
            create_building(kind, (0, 0))
            created = True
        except KeyError:                                      # el tipo ya no existe: no hay forma de construirlo
            created = False
        _cmp(problems, f"purga: {kind} no se puede crear", created, False)
    from src.entities import WorldRefs as _WR
    _cmp(problems, "purga: WorldRefs sin grupo plasma_extractors", hasattr(_WR(), "plasma_extractors"), False)
    for kind, spec_ in U.BUILDINGS.items():
        _cmp(problems, f"UNITS.BUILDINGS[{kind}]: ningún edificio cuesta núcleos (salvo el Búnker de Mando: 2)",
             spec_.get("cores", 0), 2 if kind == "bunker" else 0)
        _cmp(problems, f"UNITS.BUILDINGS[{kind}]: ningún edificio genera núcleos",
             any("cores_per" in k or k == "cores_out" for k in spec_), False)
    # 4a-quater) Búnker de Mando (Paso B): 400 chatarra + 2 núcleos + Módulo de Mando, 800 HP, huella 3x3, solo en su sitio de obra
    _cmp(problems, "Búnker de Mando: 400 chatarra, 2 núcleos, 800 HP y huella 3x3",
         (U.BUNKER["cost"], U.BUNKER["cores"], U.BUNKER["hp"], U.BUNKER["cells"]), (400, 2, 800, 3))
    _cmp(problems, "Búnker de Mando: la estructura sale de UNITS.BUNKER y mide 120x120",
         (U.BUILDINGS["bunker"]["cost"], U.BUILDINGS["bunker"]["cores"], U.BUILDINGS["bunker"]["hp"], Building.SIZES["bunker"]),
         (400, 2, 800, (120, 120)))
    _cmp(problems, "Búnker de Mando: fuera del menú de construcción (solo se ensambla en el sitio de obra)",
         "bunker" in [b for _, b in BUILD_MENU], False)
    _cmp(problems, "Búnker de Mando: la consola está desbloqueada (inicia el asedio) en la Base Central",
         (U.BUNKER["console_label"], "Bloqueada" in U.BUNKER["console_label"], "Bloqueada" in U.BUNKER["console_label_remote"]),
         ("Iniciar Asedio Táctico a la Fortaleza Enemiga", False, False))
    _cmp(problems, "Búnker de Mando: posiciones de reserva fuera de la zona del Núcleo",
         [o for o in U.BUNKER["offsets"] if (o[0] ** 2 + o[1] ** 2) ** 0.5 < 220], [])
    # 4a-quinquies) VULCANO constructor de la Base Central (Paso C): ensambla a la misma tasa que repara (80 HP/s), a velocidad finita
    _cmp(problems, "VULCANO constructor: 80 HP/s de ensamblaje, 170 px/s y alcance de obra 70 px",
         (U.VULCANO["repair_rate"], U.VULCANO["speed"], U.VULCANO["work_range"]), (80, 170, 70))
    _cmp(problems, "VULCANO constructor: C.VULCANO_SPEED / C.VULCANO_WORK_RANGE salen de UNITS",
         (C.VULCANO_SPEED, C.VULCANO_WORK_RANGE), (U.VULCANO["speed"], U.VULCANO["work_range"]))
    _cmp(problems, "VULCANO: las reparaciones críticas (Núcleo, red, muros) van antes que las obras (niveles 0-2)",
         [k for tier in U.VULCANO["priority"] for k in tier], ["core", "pylon", "tower", "balista", "wall", "compuerta"])
    from src.scenes import base_management as _bm
    _cmp(problems, "Base Central en modo Comandante: sin Operador y con construcción por sitios de obra",
         (hasattr(_bm, "Player"), _bm.BaseManagementState.INSTANT_BUILD), (False, False))
    # 4a-sexies) Guerra de Asedio (Paso D): mapa, reloj de amenaza, fortaleza evolutiva y nodos de plasma
    from src.map.levels import build_siege_level
    from src.managers.state_machine import GameState as _GS, SubAct as _SA
    SG, TCK, PN = U.SIEGE, U.THREAT_CLOCK, U.PLASMA_NODE
    _cmp(problems, "Asedio: mapa de 3000x2000 px y base-fortaleza a >= 2200 px", (SG["map"], SG["min_separation"]), ((3000, 2000), 2200))
    _cmp(problems, "Reloj de amenaza: fases a los 0, 4 y 8 minutos", tuple(TCK["phase_starts"]), (0.0, 240.0, 480.0))
    _cmp(problems, "Reloj de amenaza: Fase I Scouts y Carroñeros; II Soldados y Arietes contra pilones; III Tanques con Factoría",
         [(s["id"], s["phase"], tuple(s["kinds"]), s["target"], s.get("requires")) for s in TCK["streams"]],
         [("raiders", 1, ("scout",), "core", None), ("scavengers", 1, ("scavenger",), "scrap", None),
          ("strike", 2, ("soldier", "ariete"), "pylon", None), ("armor", 3, ("tank", "soldier"), "core", "factory")])
    FT = TCK["fortress"]
    _cmp(problems, "Fortaleza: núcleo de 1200 HP, 2 torretas ligeras en la fase I",
         (FT["core_hp"], [k for k, _, _ in FT["phase_1"]]), (1200, ["torreta_ligera", "torreta_ligera"]))
    _cmp(problems, "Fortaleza: fase II escudo + torretas pesadas; fase III Factoría",
         ([k for k, _, _ in FT["phase_2"]], [k for k, _, _ in FT["phase_3"]]),
         (["generador", "torreta_pesada", "torreta_pesada"], ["fabrica"]))
    _cmp(problems, "Fortaleza: lo destruido no reaparece al instante (retardo de reconstrucción y obra > 0)",
         (all(v > 0 for v in FT["rebuild_delay"].values()), FT["build_time"] > 0), (True, True))
    _cmp(problems, "Nodos de plasma: reserva finita de 3 Núcleos por nodo (1 + 2) y tope de campaña",
         (PN["first_cores"] + PN["drip_cores"], PN["campaign_cap"] >= PN["first_cores"] + PN["drip_cores"]), (3, True))
    _cmp(problems, "Fábrica de Drones: planos al completar la incursión inicial (el ejército del Comandante en el Acto 2)",
         U.STRUCTURE_UNLOCKS["fabrica"], ("incursion", 2))
    rm_s = ResourceManager()
    gate_s = []
    for built_, plans_ in ((False, False), (True, False), (False, True), (True, True)):
        rm_s.bunker_built, rm_s.factory_blueprints = built_, plans_       # planos: solo la Op 4 los da
        gate_s.append(rm_s.can_start_siege)
    _cmp(problems, "Asedio: solo con Búnker de Mando Y planos de la Fábrica de Drones", gate_s, [False, False, False, True])
    _cmp(problems, "Asedio: Fábrica, Pilón y Balista libres, y 4 de chatarra directa por baja",
         (tuple(SG["free_structures"]), SG["kill_metal"]), (("fabrica", "pylon", "balista"), 4))
    _cmp(problems, "Asedio: estado y sub-acto registrados", (_GS.SIEGE.name, _SA.S3_0.name), ("SIEGE", "S3_0"))
    _cmp(problems, "Asedio: tope duro de 65 enemigos vivos y pantalla de victoria de campaña", (SG["max_enemies"], _GS.CAMPAIGN_VICTORY.name),
         (65, "CAMPAIGN_VICTORY"))
    from src.mechanics.threat_clock import SpawnQueue as _SQ
    q_ = _SQ(SG["max_enemies"])
    q_.enqueue("scout", "core", 200)
    _cmp(problems, "Asedio: la cola entrega como mucho lo que cabe bajo el tope", (len(q_.release(0)), len(q_.release(65)), q_.pending),
         (65, 0, 135))
    for seed_ in range(6):
        ls_ = build_siege_level(seed_)
        a_, b_ = ls_.marker("player_base"), ls_.marker("fortress")
        _cmp(problems, f"Asedio (semilla {seed_}): 3000x2000, separación y rutas conectadas",
             (ls_.size, a_.distance_to(b_) >= 2200, ls_.is_reachable(a_, b_),
              all(ls_.is_reachable(a_, p_) for p_ in ls_.markers["plasma_node"]), 2 <= len(ls_.markers["plasma_node"]) <= 3),
             ((3000, 2000), True, True, True, True))
    # 4a-bis) Escala de las unidades y enemigos pesados
    HV = B["heavy"]
    _cmp(problems, "UNITS.ENTITY_SCALE", U.ENTITY_SCALE, HV["entity_scale"])
    _cmp(problems, "ENTITY_SCALE entre 0,82 y 0,85", 0.82 <= U.ENTITY_SCALE <= 0.85, True)
    for kind, want in HV["sizes"].items():
        _cmp(problems, f"UNITS.ENEMIES[{kind}].size (x0,83)", U.ENEMIES[kind]["size"], want)
    for kind in ("tank", "ariete"):
        for key, want in HV[kind].items():
            _cmp(problems, f"UNITS.ENEMIES[{kind}].{key}", U.ENEMIES[kind][key], want)
    _cmp(problems, "Tanque: 180° entre 2,4 y 3,0 s", 2.4 <= 180 / U.ENEMIES["tank"]["turn_rate"] <= 3.0, True)
    for key, want in HV["light_ram"].items():
        _cmp(problems, f"UNITS.LIGHT_RAM.{key}", U.LIGHT_RAM[key], want)
    _cmp(problems, "Ariete Ligero: aturdimiento entre 1,0 y 1,2 s", 1.0 <= U.LIGHT_RAM["stun"] <= 1.2, True)
    import pygame as _pgh
    from pygame.math import Vector2 as _V2
    ram_ = Enemy("ariete", (0, 0), (1, 0), _pgh.sprite.Group())
    ram_.facing = 0.0                                                     # mira a +x: su frente está a la derecha
    front_ = 1.0 - HV["ariete"]["front_reduction"]                       # de frente pasa el 55%
    for deg in range(0, 360, 45):                                         # la bala VIAJA en esta dirección
        travel = _V2(1, 0).rotate(deg)
        want = 100 * (front_ if deg == 180 else 3.0) if deg in (0, 45, 90, 135, 180, 225, 270, 315) else None
        if deg in (135, 225):                                             # 45° del frente: dentro del arco de 60°
            want = 100 * front_
        _cmp(problems, f"Ariete: bala viajando a {deg}° (frente en 0°)", round(ram_.mitigate(100, travel), 6), want)
    from src.entities.boss import LightRam as _LR
    lr_ = _LR((0, 0))
    lr_.facing = _V2(1, 0)
    # la bala VIAJA a `deg`: viajando a 0° (igual que el frente) entra por la espalda. Arco trasero 135°-225° medido desde el
    # frente (±45° de la espalda) = x2; frente (±45°) = x0,25; costados = x0,5
    for deg, mult, zone in ((180, 0.25, "front"), (0, 2.0, "rear"), (90, 0.5, "side"), (270, 0.5, "side"),
                            (45, 2.0, "rear"), (-45, 2.0, "rear"), (46, 0.5, "side"), (-46, 0.5, "side"),
                            (135, 0.25, "front"), (-135, 0.25, "front"), (134, 0.5, "side")):
        lr_.hp = lr_.max_hp
        _cmp(problems, f"Ariete Ligero: zona de impacto a {deg}°", lr_.impact_zone(_V2(1, 0).rotate(deg)), zone)
        lr_.take_damage(10, _V2(1, 0).rotate(deg))
        _cmp(problems, f"Ariete Ligero: golpe viajando a {deg}°", round(lr_.max_hp - lr_.hp, 6), 10 * mult)
    lr_.facing = _V2(0, 1)                                                # el arco gira con el chasis
    _cmp(problems, "Ariete Ligero: el arco trasero sigue al chasis", (lr_.impact_zone(_V2(0, 1)), lr_.impact_zone(_V2(1, 0))),
         ("rear", "side"))
    _cmp(problems, "Ariete Ligero: LIGHT_RAM.rear_arc", tuple(U.LIGHT_RAM["rear_arc"]), (135, 225))
    # 4b-bis) Economía separada: chatarra = táctico, núcleos = árbol del Operador, aleación = Terminal (drones)
    EC = B["economy"]
    _cmp(problems, "UNITS.RESOURCES.alloy.initial", U.RESOURCES["alloy"]["initial"], EC["alloy_initial"])
    tactical = [(f"BUILDINGS[{k}]", v) for k, v in U.BUILDINGS.items()]
    tactical += [(f"WALL_LEVELS[{k}]", v) for k, v in U.WALL_LEVELS.items()]
    tactical += [(f"TURRET_ROUTES[{t}][{r}]", v) for t, rs in U.TURRET_ROUTES.items() for r, v in rs.items()]
    tactical += [(f"DRONE_TYPES[{k}]", v) for k, v in U.DRONE_TYPES.items()]
    for label, spec_ in tactical:                                            # lo que se compra en el mapa: solo chatarra
        _cmp(problems, f"{label}: sin núcleos (compra táctica = chatarra; el Búnker de Mando es la excepción)",
             spec_.get("cores", 0), 2 if label == "BUILDINGS[bunker]" else 0)
        _cmp(problems, f"{label}: sin aleación", spec_.get("alloy", 0), 0)
    for node, spec_ in U.OPERATOR_TREE.items():                              # el árbol: solo núcleos
        _cmp(problems, f"OPERATOR_TREE[{node}]: chatarra 0 y núcleos > 0", (spec_["cost"], spec_["cores"] > 0), (0, True))
    for name, spec_ in U.DRONE_UPGRADES.items():                             # el Terminal (drones): solo aleación
        _cmp(problems, f"DRONE_UPGRADES[{name}]: solo aleación",
             (spec_["cost"], spec_["cores"], spec_["alloy"]), (0, 0, EC["drone_upgrade_alloy"]))
    _cmp(problems, "ENEMY_BASES.destroy_reward.alloy", U.ENEMY_BASES["destroy_reward"]["alloy"], EC["base_alloy"])
    _cmp(problems, "UNITS.CAMPAIGN_MAP_ALLOY", U.CAMPAIGN_MAP_ALLOY, EC["map_alloy"])
    for key, want in EC["vulcano"].items():
        _cmp(problems, f"UNITS.VULCANO.{key}", U.VULCANO[key], want)
    _cmp(problems, "config.VULCANO_SCRAP_RESERVE", C.VULCANO_SCRAP_RESERVE, EC["vulcano"]["scrap_reserve"])
    _cmp(problems, "config.VULCANO_REPAIR_RATE", C.VULCANO_REPAIR_RATE, EC["vulcano"]["repair_rate"])
    _cmp(problems, "config.CHASSIS_INSTALL_COST (montar el chasis es gratis)", C.CHASSIS_INSTALL_COST,
         EC["chassis_install_cost"])
    from src.managers.resource_manager import CampaignRun as _CR
    _cmp(problems, "CampaignRun.from_dict sin tech_alloy (partida antigua) = 0", _CR.from_dict({}).tech_alloy, 0)
    _cmp(problems, "CampaignRun: tech_alloy ida y vuelta", _CR.from_dict({"tech_alloy": 7}).to_dict()["tech_alloy"], 7)
    # 4c) Fase 6: blindaje de bases, drones, anti-farmeo y tope de reducción de daño
    P6 = B["phase6"]
    _cmp(problems, "UNITS.DRONES_PER_FACTORY", U.DRONES_PER_FACTORY, P6["drones_per_factory"])
    _cmp(problems, "Fábrica: drones_per_factory = DRONES_PER_FACTORY", U.STRUCTURES["fabrica"]["drones_per_factory"],
         U.DRONES_PER_FACTORY)
    _cmp(problems, "UNITS sin 'MAX_DRONES' fijo ni 'max_drones'", (hasattr(U, "MAX_DRONES"), "max_drones" in U.STRUCTURES["fabrica"]),
         (False, False))
    atk = U.DRONE_TYPES["attack"]
    _cmp(problems, "Dron de Ataque: DPS (damage / shot_interval)", atk["damage"] / atk["shot_interval"], P6["attack_dps"])
    _cmp(problems, "Dron de Ataque: sin 'fire_rate' ambiguo", "fire_rate" in atk, False)
    for diff, want in P6["garrison"].items():
        got = {}
        for kind, _off, _role in U.ENEMY_BASES["garrison"][diff]:
            got[kind] = got.get(kind, 0) + 1
        _cmp(problems, f"UNITS.ENEMY_BASES.garrison[{diff}]", got, want)
        roles = [r for _k, _o, r in U.ENEMY_BASES["garrison"][diff]]
        _cmp(problems, f"garrison[{diff}]: 1 generador y 1+ centinela", (roles.count("generator"), roles.count("sentinel") >= 1),
             (1, True))
    _cmp(problems, "UNITS.ENEMY_BASES.evacuation.roster", U.ENEMY_BASES["evacuation"]["roster"], P6["evacuation"])
    _cmp(problems, "UNITS.CAMPAIGN_MAP_REWARDS", U.CAMPAIGN_MAP_REWARDS, P6["map_rewards"])
    _cmp(problems, "CAMPAIGN_MAP_REWARDS cubre todos los mapas", set(U.CAMPAIGN_MAP_REWARDS), set(U.CAMPAIGN_MAPS))
    _cmp(problems, "UNITS.DAMAGE_REDUCTION_CAP", U.DAMAGE_REDUCTION_CAP, P6["damage_cap"])
    rm6 = ResourceManager()
    rm6.reward_tracker.add_reward("PLAYER_UPGRADE_1")
    pl6 = Player((0, 0), 800, 600)
    pl6.apply_upgrades(rm6)
    pl6.damage_aura = 0.20                                                       # bono externo: 20% (reward) + 20% -> tope
    _cmp(problems, "Player: 20% + 20% de reducción con tope", pl6.damage_reduction, P6["damage_cap"])
    _cmp(problems, "UNITS.VULCANO_DEFENSE.fixed_profile", U.VULCANO_DEFENSE["fixed_profile"], P6["vulcano_fixed_profile"])
    _cmp(problems, "UNITS.VULCANO_DEFENSE.cover_bonus_per_wall", U.VULCANO_DEFENSE["cover_bonus_per_wall"],
         P6["cover_bonus_per_wall"])
    _cmp(problems, "UNITS.VULCANO_DEFENSE.grace_time", U.VULCANO_DEFENSE["grace_time"], P6["vulcano_grace_time"])
    _cmp(problems, "UNITS.VULCANO_DEFENSE.low_hp_warning", U.VULCANO_DEFENSE["low_hp_warning"],
         P6["vulcano_low_hp_warning"])
    # 5) Coherencia de la composición de oleadas con los tipos de enemigo
    for n, comp in U.WAVES["composition"].items():
        for entry in comp:
            kind, count = entry[0], entry[1]
            if kind not in U.ENEMIES or count <= 0 or (len(entry) > 2 and entry[2] < 0):
                problems.append(f"UNITS.WAVES[{n}]: tipo, cantidad o retraso inválidos ({entry})")
    # 9) Incursiones: botín de los alijos (120-180 c/u, 350-500 en total a nivel 1) y mapas con salas
    import random as _rnd
    from src.map.levels import build_incursion_level
    from src.mechanics import incursion as _inc
    lo_, hi_ = C.INCURSION_LOOT_RANGE
    tmin_, tmax_ = C.INCURSION_LOOT_TOTAL
    _cmp(problems, "Incursión: rango por alijo y total (config)", (lo_, hi_, tmin_, tmax_), (120, 180, 350, 500))
    bad_ = [s for s in range(3000)
            if not all(lo_ <= v <= hi_ for v in _inc.loot_amounts(1, C.INCURSION_DEPOSITS, _rnd.Random(s)))
            or not tmin_ <= sum(_inc.loot_amounts(1, C.INCURSION_DEPOSITS, _rnd.Random(s))) <= tmax_]
    _cmp(problems, "Incursión nivel 1: cada alijo 120-180 y la incursión completa 350-500 (3000 semillas fuera de rango)",
         bad_, [])
    _cmp(problems, "Infiltración Tecnológica: cámara 150-200, hackeo 5 s, nido +3 guardias y 2 pesados mínimo",
         (C.INCURSION_TECH_VAULT_LOOT, C.INCURSION_TECH_HACK_TIME, C.INCURSION_TECH_NEST_EXTRA, C.INCURSION_TECH_NEST_HEAVY),
         ((150, 200), 5.0, 3, 2))
    # Tablero de 5 operaciones: orden, dificultad, objetivo y recompensas de la especificación de la Fase 3
    ops_ = U.INCURSION_OPS
    _cmp(problems, "Incursiones: tablero de 5 operaciones en orden", U.OPS_ORDER, ["recon", "drill", "convoy", "tech", "recovery"])
    _cmp(problems, "Incursiones: índice, nivel y objetivo de cada operación",
         [(ops_[k]["index"], ops_[k]["level"], ops_[k]["objective"]) for k in U.OPS_ORDER],
         [(1, 1, "loot"), (2, 1, "drill"), (3, 2, "convoy"), (4, 3, "hack"), (5, 3, "timed")])
    _cmp(problems, "Op 1: solo Scouts a su nivel", _inc.kind_weights(ops_["recon"]["level"]), {"scout": 1.0})
    _cmp(problems, "Op 2: taladro 90 s, oleadas cada 15 s, nivel 1-2, 1-2 núcleos",
         (ops_["drill"]["drill_time"], ops_["drill"]["wave_every"], ops_["drill"]["replay_level"], ops_["drill"]["cores"]),
         (90.0, 15.0, 2, (1, 2)))
    _cmp(problems, "Op 3: 2 Arietes escoltados, chatarra pesada y 2-3 núcleos",
         (ops_["convoy"]["rams"], ops_["convoy"]["escorts"] > 0, ops_["convoy"]["scrap"][0] > ops_["drill"]["scrap"][1],
          ops_["convoy"]["cores"]), (2, True, True, (2, 3)))
    _cmp(problems, "Op 4: terminal con Tanques, 2 aleación y 2 núcleos",
         (ops_["tech"]["tanks"] > 0, ops_["tech"]["alloy"], ops_["tech"]["cores"]), (True, 2, (2, 2)))
    _cmp(problems, "Op 5: contrarreloj con guardia reforzada, 4-5 núcleos y 2 aleación",
         (ops_["recovery"]["time_limit"] > 0, ops_["recovery"]["extra_guards"] > 0, ops_["recovery"]["cores"],
          ops_["recovery"]["alloy"]), (True, True, (4, 5), 2))
    from src.managers.resource_manager import ResourceManager as _RM
    rm_ = _RM()
    t0_ = rm_.threat_level
    seen_ = [[k for k in U.OPS_ORDER if rm_.op_unlocked(k)]]
    for k in U.OPS_ORDER:
        rm_.finish_op(k, 0, cleared=True, blueprints=k == "tech")
        seen_.append([k for k in U.OPS_ORDER if rm_.op_unlocked(k)])
    _cmp(problems, "Incursiones: desbloqueo lineal 1 -> 2 -> 3 -> 4 -> 5", [len(s) for s in seen_], [1, 2, 3, 4, 5, 5])
    _cmp(problems, "Incursiones: la Op 1 no sube la alerta y el resto la sube con tope",
         rm_.threat_level - t0_, U.OP_ALERT_CAP)
    m_ = rm_.metal
    _cmp(problems, "Incursiones: las superadas se repiten sin bono ni nivel extra",
         (rm_.finish_op("recon", 0), rm_.metal, rm_.incursion_level), (0, m_, C.INCURSION_LEVEL_START + 5))
    rb_ = _RM()
    rb_.bunker_built = True
    blocked_ = rb_.can_start_siege
    rb_.finish_op("tech", 0, blueprints=True)
    _cmp(problems, "Asedio: exige los planos de la Fábrica de la Op 4 (además del Búnker)", (blocked_, rb_.can_start_siege),
         (False, True))
    bad_vault_ = [s for s in range(500) if not 150 <= _inc.vault_loot(1, _rnd.Random(s)) <= 200]
    _cmp(problems, "Infiltración nivel 1: la cámara siempre suelta 150-200 de chatarra (semillas fuera de rango)", bad_vault_, [])
    for seed_ in range(4):
        lt_ = build_incursion_level(seed_, 1, "tech")
        _cmp(problems, f"Infiltración (semilla {seed_}): 1 cámara fuerte, sin depósitos y todo alcanzable",
             (len(lt_.markers.get("vault", [])), "deposit" in lt_.markers,
              lt_.is_reachable(lt_.marker("start"), lt_.marker("vault")) and lt_.is_reachable(lt_.marker("start"), lt_.marker("extract"))),
             (1, False, True))
    _cmp(problems, "Incursión: el botín crece con el nivel (+25% por nivel)",
         sum(_inc.loot_amounts(5, 3, _rnd.Random(1))) > 1.9 * sum(_inc.loot_amounts(1, 3, _rnd.Random(1))), True)
    for seed_ in range(6):
        lv_ = build_incursion_level(seed_, 2)
        o_ = lv_.marker("start")
        _cmp(problems, f"Incursión (semilla {seed_}): 12 salas, 3 depósitos y todo alcanzable",
             (len(lv_.rooms), len(lv_.markers["deposit"]),
              all(lv_.is_reachable(o_, lv_.marker(n_, i_)) for n_ in ("extract", "deposit", "plasma_cache", "plasma_extractor")
                  for i_ in range(len(lv_.markers[n_])))), (12, 3, True))
    return problems


def main():
    problems = verify()
    if problems:
        print(f"verify_balance: {len(problems)} discrepancia(s) con la Biblia del Juego:")
        for line in problems:
            print("  -", line)
        return 1
    print("verify_balance: OK · sin discrepancias entre la Biblia, UNITS.py y las clases")
    return 0


if __name__ == "__main__":
    sys.exit(main())
