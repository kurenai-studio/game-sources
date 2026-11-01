"""Estado persistente de la campaña: chatarra, núcleos de plasma, energía, árbol de mejoras, alerta y base."""
import copy
import logging
from types import SimpleNamespace

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.mechanics.rewards import RewardTracker

log = logging.getLogger("robot_renegado.campaign")


def validate_structure_position(structure, map_width, map_height, margin=(0, 0)):
    """Mete la posición de `structure` (cualquier objeto con x/y; si tiene `pos` Vector2 también se actualiza) dentro del
    mapa. `margin` = media medida (para que el rectángulo entero quede dentro). Devuelve True si hubo que ajustarla."""
    mx, my = margin
    x, y = structure.x, structure.y
    structure.x = max(mx, min(x, map_width - mx))
    structure.y = max(my, min(y, map_height - my))
    if isinstance(getattr(structure, "pos", None), Vector2):
        structure.pos.update(structure.x, structure.y)
    moved = (structure.x, structure.y) != (x, y)
    if moved:
        log.info("posición ajustada al mapa %sx%s: (%.0f, %.0f) -> (%.0f, %.0f)",
                 map_width, map_height, x, y, structure.x, structure.y)
    return moved


class CampaignRun:
    """Estado de una partida de campaña del Acto 2, separado en dos capas para que nada se filtre de un mapa a otro.

    Persistente (sobrevive al cambio de mapa y a los reintentos; solo son datos, nunca referencias vivas):
      current_map_key, completed_maps, layout_data (la base del jugador), drone_data (drones vivos),
      factory_queue_data (cola de la Fábrica) y aura_drone_lost.
    Efímero (solo mientras el mapa está activo; lo fija `bind` y lo vacían `start_map` / `on_map_complete`):
      bases, fog, drones, layout (la escena que posee el Centro de Control) y world.

    `start_map` prepara un mapa (también al reintentarlo): borra lo efímero, reinicia el reloj y a AURA, y deja en el
    ResourceManager la base guardada trasladada al Centro de Control del mapa nuevo. `on_map_complete(True)` registra el
    mapa ganado y guarda la base, los drones y la cola para el siguiente; una derrota no guarda nada.

    Desbloqueo lineal: cada mapa de UNITS.CAMPAIGN_MAPS exige haber ganado el anterior (el clásico siempre está abierto).
    Anti-farmeo: el premio de mapa (UNITS.CAMPAIGN_MAP_REWARDS) solo se cobra la primera vez que se gana."""

    def __init__(self, initial_map_key=None):
        self.current_map_key = initial_map_key
        self.difficulty = None
        self.completed_maps = set()
        self.layout_data = {}            # {"control_center", "core_hp", "deposits", "buildings"}; {} = aún sin guardar
        self.drone_data = []             # [{"type", "hp", "x", "y", "upgrades"[, "shield"]}]
        self.drone_origin = None         # Centro de Control donde se guardaron esas posiciones (Base Central o mapa ganado)
        self.factory_queue_data = []     # [{"drone_type", "cost": (chatarra, núcleos)}]
        self.aura_drone_lost = False     # el dron AURA cayó: no vuelve hasta el próximo start_map
        self.tech_alloy = U.RESOURCES["alloy"]["initial"]   # Aleación Militar (persiste toda la campaña)
        self.tech_unlocked = set()       # especializaciones de torreta desbloqueadas en el Terminal ("tower_A", ...)
        self.command_module = False      # Módulo de Mando del Búnker (Infiltración Tecnológica): persiste toda la campaña
        self.campaign_completed = False  # el asedio se ganó y la victoria de campaña se guardó
        self.bunker_built = False        # Búnker de Mando ensamblado en la Base Central (se paga una vez; si cae, se rehace)
        self.siege_cores_earned = 0      # Núcleos que han dado los nodos de plasma del asedio en TODA la campaña (tope anti-farmeo)
        self.op_nodes = set()            # mejoras del Operador compradas con Núcleos (UNITS.OPERATOR_TREE): persisten en la campaña
        self.medkits = 0                 # botiquines en el bolsillo del Operador (máx. UNITS.MEDKITS["max"]): persisten
        self.player_name = "Operador"    # nombre que el Operador le da a AURA en el 1.2 (perfil de guardado saves/{nombre}.json)
        self.named = False               # ¿ya lo dijo? Sin nombre no hay autoguardado (partidas heredadas: "Operador")
        self.tutorial_done = set()       # hitos del Mentor VULCANO terminados (o saltados): src/mechanics/vulcan_advisor.py
        self.ops_cleared = set()         # operaciones de incursión superadas (UNITS.INCURSION_OPS): abren la siguiente
        self.factory_blueprints = False  # planos de la Fábrica de Drones (Op 4): exigidos por la consola del asedio
        self.legacy_core_refund = 0      # Núcleos por nodos del árbol anterior que ya no existen (se cobran con claim_core_refund)
        self._timer = 0.0                # segundos jugados en el mapa (límite total_duration)
        self.last_layout_dropped = 0     # estructuras descartadas en el último traslado (no cabían en el mapa)
        self.last_result_message = ""    # "Primer viaje: +100⚙ +3🔷" / "Mapa repetido: sin recursos"
        self._clear_runtime()

    # --- capa efímera ---
    def _clear_runtime(self):
        self.bases = None
        self.fog = None
        self.drones = None
        self.layout = None
        self.world = None

    def bind(self, scene):
        """La escena del Acto 2 registra sus objetos vivos (se sueltan al terminar el mapa)."""
        self.world = scene.world
        self.layout = scene
        self.bases = scene.enemy_bases
        self.fog = scene.fog
        self.drones = [d for d in scene.world.drones if d.alive() and hasattr(d, "home")]

    # --- desbloqueo lineal y anti-farmeo ---
    @staticmethod
    def map_order():
        return list(U.CAMPAIGN_MAPS)

    def is_unlocked(self, map_key):
        """map_1 siempre; cada mapa siguiente, solo si el anterior está ganado. El clásico (None) siempre."""
        order = self.map_order()
        if map_key not in order:
            return True
        i = order.index(map_key)
        return i == 0 or order[i - 1] in self.completed_maps

    def required_map(self, map_key):
        """Mapa que hay que ganar para desbloquear `map_key` (None si ya está abierto)."""
        if self.is_unlocked(map_key):
            return None
        order = self.map_order()
        return order[order.index(map_key) - 1]

    @property
    def is_repeat(self):
        """¿El mapa en curso ya estaba ganado? (sus premios no vuelven a pagar)."""
        return self.current_map_key in self.completed_maps

    @property
    def timer(self):
        """Segundos jugados en el mapa en curso (solo lectura: lo avanza la escena vía ResourceManager.campaign_time)."""
        return self._timer

    # --- guardado / carga (solo datos persistentes) ---
    def to_dict(self):
        """Estado persistente como datos simples (sin referencias vivas): para guardar la partida."""
        return {"current_map_key": self.current_map_key, "completed_maps": sorted(self.completed_maps),
                "layout_data": copy.deepcopy(self.layout_data), "drone_data": copy.deepcopy(self.drone_data),
                "factory_queue_data": copy.deepcopy(self.factory_queue_data), "aura_drone_lost": self.aura_drone_lost,
                "tech_alloy": self.tech_alloy, "tech_unlocked": sorted(self.tech_unlocked), "command_module": self.command_module, "bunker_built": self.bunker_built,
                "siege_cores_earned": self.siege_cores_earned, "campaign_completed": self.campaign_completed,
                "op_nodes": sorted(self.op_nodes), "legacy_core_refund": self.legacy_core_refund, "timer": self._timer,
                "medkits": self.medkits, "player_name": self.player_name, "named": self.named,
                "tutorial_done": sorted(self.tutorial_done), "ops_cleared": sorted(self.ops_cleared),
                "factory_blueprints": self.factory_blueprints,
                "drone_origin": list(self.drone_origin) if self.drone_origin is not None else None}

    @classmethod
    def from_dict(cls, data):
        """Reconstruye el estado guardado. Las claves que falten (partidas anteriores) toman su valor inicial: en
        particular `tech_alloy` = 0, así una partida sin Aleación no se corrompe."""
        run = cls(data.get("current_map_key"))
        run.completed_maps = set(data.get("completed_maps", ()))
        run.layout_data = copy.deepcopy(data.get("layout_data") or {})
        run.drone_data = copy.deepcopy(data.get("drone_data") or [])
        run.factory_queue_data = copy.deepcopy(data.get("factory_queue_data") or [])
        run.aura_drone_lost = bool(data.get("aura_drone_lost", False))
        run.command_module = bool(data.get("command_module", False))      # partidas anteriores: sin módulo
        run.bunker_built = bool(data.get("bunker_built", False))
        run.siege_cores_earned = max(0, int(data.get("siege_cores_earned", 0)))
        run.campaign_completed = bool(data.get("campaign_completed", False))
        run.tech_alloy = max(0, int(data.get("tech_alloy", U.RESOURCES["alloy"]["initial"])))
        run.tech_unlocked = {k for k in data.get("tech_unlocked", ()) if k in U.TURRET_TECH}   # claves ajenas: se ignoran
        run.op_nodes, refund = cls.migrate_op_nodes(data.get("op_nodes", ()))
        run.legacy_core_refund = max(0, int(data.get("legacy_core_refund", 0))) + refund
        run._timer = float(data.get("timer", 0.0))
        run.medkits = max(0, min(U.MEDKITS["max"], int(data.get("medkits", 0))))     # partidas anteriores: sin botiquines
        run.player_name = str(data.get("player_name") or "Operador")          # partidas anteriores: "Operador"
        run.named = bool(data.get("named", "player_name" in data))
        run.tutorial_done = set(data.get("tutorial_done", ()))               # partidas anteriores: sin hitos
        run.ops_cleared = {k for k in data.get("ops_cleared", ()) if k in U.INCURSION_OPS}
        run.factory_blueprints = bool(data.get("factory_blueprints", False))
        origin = data.get("drone_origin")
        run.drone_origin = (float(origin[0]), float(origin[1])) if origin else None
        return run

    @staticmethod
    def migrate_op_nodes(raw):
        """(nodos válidos, Núcleos a devolver) a partir de una lista guardada, aunque sea de una versión anterior: el
        Disparador Automático pasa a Gatillo Automático, los nodos del árbol viejo se devuelven en Núcleos, las claves
        desconocidas se ignoran y solo se conserva lo alcanzable por la cadena de prerrequisitos de cada rama."""
        names = {U.LEGACY_OPERATOR_NODES.get(n, n) for n in raw}
        refund = sum(U.LEGACY_NODE_REFUND.get(n, 0) for n in raw if n in U.LEGACY_NODE_REFUND)
        kept = set()
        for node, spec in sorted(U.OPERATOR_TREE.items(), key=lambda kv: kv[1]["tier"]):
            if node in names and (spec["requires"] is None or spec["requires"] in kept):
                kept.add(node)
        return kept, refund

    # --- ciclo de vida de un mapa ---
    def start_map(self, map_key, difficulty=None, res=None):
        """Prepara `map_key` (o lo reinicia tras una derrota). Con `res`, deja en él la base guardada, ya trasladada al
        Centro de Control del mapa, y limpia la niebla, las bases enemigas y los premios del mapa anterior."""
        from src.mechanics.fog import MapFog                         # import local: evita ciclos con las escenas
        from src.mechanics.scenario import Scenario
        new = Scenario(map_key)
        if res is not None and not self.layout_data:                 # primera vez: la base viene de la Base Central
            self.layout_data = self.layout_from_resources(res, Scenario(self.current_map_key).cc_pos)
        self.current_map_key = map_key
        self.difficulty = difficulty if difficulty is not None else new.difficulty
        self._timer = 0.0
        self.aura_drone_lost = False
        self._clear_runtime()
        self.bases, self.drones = [], []
        self.fog = MapFog(new.w, new.h, U.FOG["cell"])
        if res is not None:
            res.campaign_rewards = []
            res.enemy_bases_state = None
            res.act2_fog = None
            res.base_layout = self.deserialize_layout(self.layout_data, new.cc_pos, new.size)
            deposits = self.layout_data.get("deposits")
            res.base_deposits = list(deposits) if deposits is not None else None
            res.base_core_hp = self.layout_data.get("core_hp")
        return new

    def restart_attempt(self):
        """Reintento de un sub-acto que no empieza el mapa (2.2): AURA vuelve y se sueltan las referencias vivas."""
        self.aura_drone_lost = False
        self._clear_runtime()

    def on_map_complete(self, victory, scene=None, res=None):
        """Fin del mapa. Solo una victoria lo registra y guarda la base, los drones y la cola de la Fábrica.
        La primera victoria de cada mapa paga su premio (UNITS.CAMPAIGN_MAP_REWARDS) a `res`; repetirlo no paga nada.
        Devuelve el mensaje del resultado ("" en derrota o en el clásico)."""
        scene = scene if scene is not None else self.layout
        self.last_result_message = ""
        if victory:
            key = self.current_map_key
            if key in U.CAMPAIGN_MAP_REWARDS:
                if key not in self.completed_maps:                   # transacción única: primer viaje
                    scrap, cores = U.CAMPAIGN_MAP_REWARDS[key]
                    alloy = U.CAMPAIGN_MAP_ALLOY.get(key, 0)
                    if res is not None:
                        res.add_metal(scrap)
                        res.add_cores(cores)
                    core = getattr(scene, "core", None)
                    if core is not None and core.alive() and core.hp > core.max_hp * U.ALLOY_BONUS["clear_core_hp"]:
                        alloy += U.ALLOY_BONUS["clear_reward"]                 # Centro de Control casi intacto
                    self.tech_alloy += alloy
                    self.last_result_message = f"Primer viaje: +{scrap}⚙ +{cores}🔷 +{alloy}▣"
                else:
                    self.last_result_message = "Mapa repetido: sin recursos"
            if key is not None:
                self.completed_maps.add(key)
            if scene is not None:
                self.layout_data = self.serialize_layout(scene)
                world = scene.world
                self.drone_data = self.serialize_drones(world.drones)
                self.drone_origin = self.layout_data["control_center"]
                factory = next((f for f in world.factories if f.alive()), None)
                self.factory_queue_data = self.serialize_factory_queue(factory)
        self._timer = 0.0
        self._clear_runtime()

    # --- base del jugador ---
    @staticmethod
    def layout_from_resources(res, control_center):
        """layout_data a partir de la base que guarda el ResourceManager (Base Central o checkpoint)."""
        return {"control_center": (float(control_center[0]), float(control_center[1])),
                "core_hp": res.base_core_hp,
                "deposits": list(res.base_deposits) if res.base_deposits is not None else None,
                "buildings": copy.deepcopy(res.base_layout)}

    @staticmethod
    def serialize_layout(scene):
        """Centro de Control (posición y vida), metal de sus depósitos y todas las estructuras como datos."""
        from src.mechanics.base_layout import layout_entries
        core = scene.core
        return {"control_center": (float(core.pos.x), float(core.pos.y)), "core_hp": core.hp,
                "deposits": [d.total_metal for d in scene.deposit_list],
                "buildings": layout_entries(scene)}

    def deserialize_layout(self, layout_data, control_center, map_size):
        """Estructuras de `layout_data` trasladadas al nuevo Centro de Control y metidas dentro del mapa.
        Las que hubo que recolocar para que cupieran y entonces chocan con el núcleo u otra estructura se descartan
        (`last_layout_dropped`); las que caben donde estaban se conservan tal cual."""
        from src.entities.building import Building
        self.last_layout_dropped = 0
        if not layout_data:
            return []
        delta = Vector2(control_center) - Vector2(layout_data["control_center"])
        w, h = map_size
        core_rect = _rect(Vector2(control_center), Building.SIZES["core"])
        placed, out = [], []
        for entry in layout_data.get("buildings", []):
            size = Building.SIZES.get(entry["type"], (C.BUILD_GRID, C.BUILD_GRID))
            x, y = entry["pos"][0] + delta.x, entry["pos"][1] + delta.y
            spot = self.validate_base_position(SimpleNamespace(x=x, y=y), w, h, margin=(size[0] / 2, size[1] / 2))
            rect = _rect(Vector2(spot.x, spot.y), size)
            moved = (spot.x, spot.y) != (x, y)                     # solo lo recolocado puede chocar con algo nuevo
            if moved and (rect.colliderect(core_rect) or rect.collidelist(placed) != -1):
                self.last_layout_dropped += 1
                continue
            placed.append(rect)
            out.append({**copy.deepcopy(entry), "pos": (spot.x, spot.y)})
        return out

    @staticmethod
    def validate_base_position(base, map_width, map_height, margin=(0, 0)):
        """Mete la posición de `base` (EnemyBase o cualquier objeto con x/y) dentro del mapa (con log si la ajusta)."""
        validate_structure_position(base, map_width, map_height, margin)
        return base

    # --- drones de la Fábrica ---
    def store_fleet(self, drones, control_center):
        """La flota de la Base Central pasa a ser la de la campaña: la recibe el próximo mapa del Acto 2 o el asedio."""
        self.drone_data = self.serialize_drones(drones)
        self.drone_origin = (float(control_center[0]), float(control_center[1]))

    @staticmethod
    def serialize_drones(drones):
        """Drones de la Fábrica vivos como datos (tipo, vida, posición y mejoras ya aplicadas). El dron AURA no cuenta."""
        out = []
        for d in drones:
            if not d.alive() or not hasattr(d, "home") or getattr(d, "drone_type", None) not in U.DRONE_TYPES:
                continue
            base = U.DRONE_TYPES[d.drone_type]
            upgrades = {k: d.stats[k] - v for k, v in base.items()
                        if isinstance(v, (int, float)) and not isinstance(v, bool) and k in d.stats and d.stats[k] != v}
            entry = {"type": d.drone_type, "hp": float(d.hp), "x": float(d.pos.x), "y": float(d.pos.y),
                     "upgrades": upgrades}
            if getattr(d, "carried_scrap", 0):
                entry["carried"] = int(d.carried_scrap)                  # el Explorador conserva su carga
            out.append(entry)
        return out

    def deserialize_drones(self, world, factory=None, upgrades=(), rewards=None, on_collect=None,
                           data=None, origin=None, factories=None, on_drop=None):
        """Recrea los drones de `data` (por defecto `drone_data`) en `world`: los supervivientes vuelven todos (el límite de
        la flota solo frena la fabricación de reemplazos, no a quien ya existe). Si hay fábricas, los drones se reparten entre
        ellas y usan sus mejoras. Las posiciones se trasladan con la base (`origin` = Centro de Control donde se guardaron);
        si caen fuera del mapa, aparecen en la base.
        No consume los datos: reintentar el mapa vuelve a crear los mismos drones en un mundo nuevo, sin duplicarlos."""
        from src.entities.drones import DRONE_CLASSES
        from src.entities.factory import drone_stats
        facs = [f for f in (factories if factories is not None else ([factory] if factory is not None else []))]
        if facs:
            upgrades, rewards = facs[0].upgrades, facs[0].rewards
            on_collect, on_drop = facs[0].on_collect, facs[0].on_drop
        default_home = Vector2(world.core.pos) if world.core is not None else Vector2()
        if origin is None and data is None and self.drone_origin is not None:
            origin = self.drone_origin                                       # flota guardada en la Base Central o en un mapa
        data = self.drone_data if data is None else data
        if origin is None and self.layout_data:
            origin = self.layout_data.get("control_center")
        delta = Vector2(world.core.pos) - Vector2(origin) if origin is not None and world.core is not None else Vector2()
        bounds = world.bounds
        created = []
        for entry in data:
            kind = entry["type"]
            if kind not in DRONE_CLASSES:
                continue
            owner = facs[len(created) % len(facs)] if facs else None             # reparto equitativo entre fábricas
            home = Vector2(owner.pos) if owner is not None else default_home
            stats = drone_stats(kind, upgrades, rewards)
            pos = Vector2(entry["x"], entry["y"]) + delta
            if bounds is not None and not bounds.collidepoint(pos):          # fuera del mapa: aparece en la base
                pos = Vector2(home)
            cls = DRONE_CLASSES[kind]
            if kind == "recon":
                drone = cls(pos, stats, home=home)
                drone.on_collect, drone.on_drop = on_collect, on_drop
                drone.carried_scrap = int(entry.get("carried", 0))
            else:
                drone = cls(pos, stats, home=home)
            drone.hp = max(1.0, min(float(entry["hp"]), drone.max_hp))
            if owner is not None:
                owner.drones.append(drone)
            world.drones.add(drone)
            world.all_sprites.add(drone)
            created.append(drone)
        self.drones = list(created)
        return created

    # --- cola de la Fábrica ---
    @staticmethod
    def serialize_factory_queue(factories):
        """Lo que estaba encargado (y pagado) en cada fábrica: el dron en fabricación primero (con el tiempo que le faltaba)
        y su cola. `factories` = una Fábrica o varias; cada entrada guarda de cuál venía ("slot")."""
        if factories is None:
            return []
        facs = [factories] if hasattr(factories, "production_queue") else sorted(factories, key=lambda f: f.build_order)
        out = []
        for slot, factory in enumerate(facs):
            if factory.current_production:
                k = factory.current_production
                out.append({"drone_type": k, "cost": (U.DRONE_TYPES[k]["cost"], U.DRONE_TYPES[k]["cores"]),
                            "time_left": float(factory.production_time_left), "slot": slot})
            out += [{"drone_type": k, "cost": (U.DRONE_TYPES[k]["cost"], U.DRONE_TYPES[k]["cores"]), "slot": slot}
                    for k in factory.production_queue]
        return out

    def deserialize_factory_queue(self, factory, res=None, data=None):
        """Vuelve a encargar lo pagado (sin cobrarlo otra vez) en su fábrica de origen o, si ya no está o no tiene sitio, en la
        que tenga hueco; el dron que se estaba fabricando sigue donde se quedó. Lo que no cabe en ninguna se devuelve a
        `res`. `factory` = una Fábrica o varias. Devuelve los tipos recuperados."""
        spec = U.STRUCTURES["fabrica"]
        data = self.factory_queue_data if data is None else data
        if factory is None:
            facs = []
        elif hasattr(factory, "production_queue"):
            facs = [factory]
        else:
            facs = sorted(factory, key=lambda f: f.build_order)
        queued = []
        for entry in data:
            order = ([facs[entry["slot"]]] if 0 <= entry.get("slot", -1) < len(facs) else []) + facs
            target = None
            for f in order:
                if "time_left" in entry and f.current_production is None:
                    target = f
                    break
                if len(f.production_queue) < spec["production_queue_size"]:
                    target = f
                    break
            if target is None:
                if res is not None:
                    scrap, cores = entry["cost"]
                    res.add_metal(scrap)
                    res.add_cores(cores)
                continue
            if "time_left" in entry and target.current_production is None:
                target.current_production = entry["drone_type"]              # reanuda la fabricación en curso
                target.production_time_left = float(entry["time_left"])
            else:
                target.production_queue.append(entry["drone_type"])
            queued.append(entry["drone_type"])
        return queued


def _rect(center, size):
    r = pygame.Rect(0, 0, int(size[0]), int(size[1]))
    r.center = (round(center.x), round(center.y))
    return r


class ResourceManager:
    def __init__(self):
        self.reset()

    def reset(self):
        self.campaign_run = CampaignRun()      # mapa en curso, mapas ganados, base/drones entre mapas y AURA (ver CampaignRun)
        self.metal = C.STARTING_METAL_ACT1     # Chatarra (⚙)
        self.cores = U.RESOURCES["cores"]["initial"]       # Núcleos de Plasma (🔷)
        self.energy = 0                        # energía en uso (consumo de las torretas activas; la fija la construcción)
        self.energy_cap = C.ENERGY_CORE        # capacidad total de la red (Centro de Control + pilones)
        self.threat_level = C.THREAT_LEVEL_BASE
        self.expeditions_used = 0
        self.initial_done = False
        self.history = []
        # Progreso narrativo (se guarda en los checkpoints de sub-acto)
        self.equipped = False          # exoesqueleto y rifle (alijo del 1.1)
        self.aura_linked = False       # AURA en el traje: radar y guías (1.2)
        self.vulcano_online = False    # VULCANO vinculado al Centro de Control (1.4)
        # Base Central (la gestiona VULCANO entre sub-actos)
        self.base_layout = []          # estructuras: [{"type", "pos", "hp", ...}]
        self.base_deposits = None      # metal restante de cada depósito de chatarra
        self.base_core_hp = None       # vida del Centro de Control
        self.base_drones = []          # drones de la Fábrica vivos al pasar de 2.1 a 2.2 (datos de CampaignRun)
        self.base_factory_queue = []   # ...y su cola de producción
        self.metal_mark = C.STARTING_METAL_ACT1     # metal en el último despliegue (para el reporte)
        self.chassis_found = 0         # componentes del chasis de AURA recuperados en misión
        self.chassis_installed = 0     # ...y ya instalados en la base
        self.drone_upgrades = set()    # mejoras permanentes de los drones de la Fábrica (Terminal Táctico)
        self.enemy_bases_state = None  # bases enemigas con IA del Acto 2 (viajan de 2.1 a 2.2)
        self.act2_fog = None           # niebla de guerra descubierta en el Acto 2
        self.campaign_rewards = []     # ids de los premios obtenidos en el mapa en curso
        self.reward_tracker = RewardTracker()   # desbloqueos permanentes: persisten entre mapas (Prioridad 4)
        self.incursion_level = C.INCURSION_LEVEL_START    # sube con cada extracción con vida
        self.all_structures_unlocked = False   # utilidad (simulación y pruebas): todo el menú de construcción abierto
        self.siege_active = False              # dentro del asedio (lo fija SiegeState): Fábrica, Pilón y Balista siempre disponibles
        self.siege_transfer = None             # (chatarra, núcleos) que la consola del Búnker transfiere al iniciar el asedio

    # --- estado del mapa de campaña: vive en CampaignRun (estas propiedades conservan los nombres de siempre) ---
    @property
    def campaign_map(self):
        """Mapa elegido en el menú de campaña (None = Acto 2 clásico con la Fundición)."""
        return self.campaign_run.current_map_key

    @campaign_map.setter
    def campaign_map(self, key):
        self.campaign_run.current_map_key = key

    @property
    def campaign_time(self):
        """Segundos jugados en el mapa (para el límite total_duration)."""
        return self.campaign_run._timer

    @campaign_time.setter
    def campaign_time(self, value):
        self.campaign_run._timer = float(value)

    @property
    def unlocked_tech(self):
        """Especializaciones de torreta desbloqueadas ("tower_A", "balista_B"...): viven en CampaignRun (persistentes)."""
        return self.campaign_run.tech_unlocked

    def route_unlocked(self, turret, route):
        return f"{turret}_{route}" in self.campaign_run.tech_unlocked

    def unlock_route(self, key):
        """Terminal Táctico: desbloquea una especialización de torreta con aleación. False si ya la tienes o falta aleación."""
        if key in self.campaign_run.tech_unlocked or key not in U.TURRET_TECH:
            return False
        if not self.spend_alloy(U.TURRET_TECH[key]["alloy"]):
            return False
        self.campaign_run.tech_unlocked.add(key)
        return True

    # --- estructuras bloqueadas (UNITS.STRUCTURE_UNLOCKS) ---
    def structure_unlocked(self, kind):
        req = U.STRUCTURE_UNLOCKS.get(kind)
        if req is None or self.all_structures_unlocked:
            return True
        if self.siege_active and kind in U.SIEGE["free_structures"]:      # el asedio necesita Fábrica, Pilón y Balista
            return True
        if kind == "fabrica" and (self.campaign_run.factory_blueprints
                                  or any(e.get("type") == "fabrica" for e in self.base_layout)):
            return True                                                   # ya tienes la tecnología (planos o una Fábrica)
        source, value = req
        if source == "incursion":
            return self.incursion_level >= value
        return value in self.campaign_run.completed_maps

    def structure_requirement(self, kind, short=False):
        """Qué desbloquea la estructura `kind` (texto para el panel de construcción y el tooltip); "" si ya está abierta."""
        req = U.STRUCTURE_UNLOCKS.get(kind)
        if req is None or self.structure_unlocked(kind):
            return ""
        source, value = req
        if source == "incursion":
            if short:
                return f"Incursión {value}"
            return "Completa la incursión inicial" if value == 2 else f"Alcanza el nivel de incursión {value}"
        cfg = U.CAMPAIGN_MAPS[value]
        return f"Gana mapa {cfg['map_id']}" if short else f"Gana el mapa «{cfg['name']}»"

    def unlock_all_structures(self):
        """Utilidad (simulación y pruebas): todas las estructuras disponibles, sin cumplir requisitos."""
        self.all_structures_unlocked = True

    def unlock_all_tech(self):
        """Utilidad (simulación y pruebas): todas las especializaciones desbloqueadas, sin coste."""
        self.campaign_run.tech_unlocked.update(U.TURRET_TECH)

    @property
    def alloy(self):
        """Aleación Militar (▣): vive en CampaignRun (persistente); solo la gasta el Terminal Táctico."""
        return self.campaign_run.tech_alloy

    @alloy.setter
    def alloy(self, value):
        self.campaign_run.tech_alloy = max(0, int(value))

    @property
    def aura_drone_lost(self):
        """El dron AURA (chasis 6/6) cayó: no vuelve hasta que empiece o se reintente el mapa."""
        return self.campaign_run.aura_drone_lost

    @aura_drone_lost.setter
    def aura_drone_lost(self, value):
        self.campaign_run.aura_drone_lost = bool(value)

    # --- checkpoints de sub-acto ---
    _BASE_FIELDS = ("base_layout", "base_deposits", "base_core_hp", "base_drones", "base_factory_queue",
                    "metal_mark", "chassis_found",
                    "chassis_installed", "incursion_level", "op_nodes", "drone_upgrades", "enemy_bases_state",
                    "act2_fog", "campaign_map", "campaign_time", "campaign_rewards", "reward_tracker")

    def snapshot(self):
        snap = {"metal": self.metal, "cores": self.cores, "alloy": self.alloy, "energy": self.energy,
                "tech_unlocked": sorted(self.campaign_run.tech_unlocked),
                "threat_level": self.threat_level,
                "expeditions_used": self.expeditions_used, "initial_done": self.initial_done,
                "history": list(self.history), "equipped": self.equipped,
                "aura_linked": self.aura_linked, "vulcano_online": self.vulcano_online,
                "command_module": self.command_module, "bunker_built": self.bunker_built,
                "factory_blueprints": self.campaign_run.factory_blueprints}
        snap.update({f: copy.deepcopy(getattr(self, f)) for f in self._BASE_FIELDS})
        return snap

    # --- guardado por perfiles (src/mechanics/save_manager.py) ---
    @property
    def player_name(self):
        return self.campaign_run.player_name

    def to_save(self):
        """Recursos y progreso persistentes (el CampaignRun se guarda aparte)."""
        snap = self.snapshot()
        snap["energy_cap"] = self.energy_cap
        return snap

    def load_save(self, data):
        """Aplica un guardado sobre un ResourceManager recién reiniciado; las claves que falten conservan su valor inicial."""
        full = self.snapshot()
        full.update({k: v for k, v in data.items() if k in full or k == "energy_cap"})
        self.restore(full)
        self.energy_cap = full.get("energy_cap", self.energy_cap)

    def restore(self, snap):
        self.metal, self.cores, self.energy = snap["metal"], snap["cores"], snap["energy"]
        self.alloy = snap.get("alloy", U.RESOURCES["alloy"]["initial"])      # checkpoints antiguos: 0
        self.campaign_run.tech_unlocked = {k for k in snap.get("tech_unlocked", ()) if k in U.TURRET_TECH}
        self.threat_level, self.expeditions_used = snap["threat_level"], snap["expeditions_used"]
        self.initial_done, self.history = snap["initial_done"], list(snap["history"])
        self.equipped, self.aura_linked = snap["equipped"], snap["aura_linked"]
        self.vulcano_online = snap["vulcano_online"]
        self.command_module = snap.get("command_module", False)           # checkpoints antiguos: sin módulo
        self.bunker_built = snap.get("bunker_built", False)
        # planos de la Op 4: estrictamente persistentes (un checkpoint o un guardado más antiguo nunca los quita)
        self.factory_blueprints = self.campaign_run.factory_blueprints or bool(snap.get("factory_blueprints", False))
        for f in self._BASE_FIELDS:
            setattr(self, f, copy.deepcopy(snap[f]))

    # --- chasis de AURA ---
    @property
    def chassis_available(self):
        return self.chassis_found - self.chassis_installed

    def chassis_part_due(self, on_ground=0):
        """¿Hace falta otra pieza del chasis? Con 6 recuperadas (contando las `on_ground` aún por recoger) ya no caen más:
        el excedente se convierte en UNITS.CHASSIS_SURPLUS."""
        return self.chassis_found + on_ground < C.CHASSIS_TOTAL_PARTS

    @property
    def assembly_pct(self):
        return round(100 * self.chassis_installed / C.CHASSIS_TOTAL_PARTS)

    def extra_health_blocks(self):
        """Bloques de vida extra del árbol: uno por cada Celda Vital comprada (I y II)."""
        return U.OPERATOR_EFFECTS["extra_blocks"] * sum(1 for n in U.OPERATOR_EFFECTS["vital_cells"] if self.owns(n))

    @property
    def player_max_hp(self):
        """Vida máxima: la base del Operador más los componentes del chasis instalados; cada Celda Vital añade un bloque más
        del mismo tamaño (3 -> 4 -> 5 bloques: 100 -> 133 -> 166 HP)."""
        hp = (C.PLAYER_START_HP + C.CHASSIS_HP_BONUS * self.chassis_installed
              + self.reward_tracker.player_bonus("health_max"))
        extra = self.extra_health_blocks()
        if extra:
            blocks = C.PLAYER_HEALTH_BLOCKS
            hp = int(hp * (blocks + extra) / blocks)
        return hp

    # --- botiquines (bolsillo del Operador, persistente en CampaignRun) ---
    @property
    def medkits(self):
        return self.campaign_run.medkits

    @medkits.setter
    def medkits(self, value):
        self.campaign_run.medkits = max(0, min(U.MEDKITS["max"], int(value)))

    def add_medkits(self, n=1):
        """Guarda botiquines hasta llenar el bolsillo. Devuelve cuántos entraron."""
        before = self.medkits
        self.medkits = before + n
        return self.medkits - before

    # --- árbol de mejoras del Operador (Terminal Táctico, persistente en CampaignRun) ---
    @property
    def op_nodes(self):
        """Nodos comprados del árbol del Operador: viven en CampaignRun (persistente en la campaña)."""
        return self.campaign_run.op_nodes

    @op_nodes.setter
    def op_nodes(self, value):
        self.campaign_run.op_nodes = set(value)

    def claim_core_refund(self):
        """Cobra los Núcleos que dejó pendientes una partida guardada con el árbol anterior. Devuelve cuántos."""
        refund, self.campaign_run.legacy_core_refund = self.campaign_run.legacy_core_refund, 0
        self.cores += refund
        return refund

    def owns(self, node):
        return node in self.op_nodes

    def node_state(self, node):
        """"owned" (comprado), "available" o "locked" (falta el nodo anterior de su rama)."""
        if node in self.op_nodes:
            return "owned"
        req = U.OPERATOR_TREE[node]["requires"]
        return "locked" if req is not None and req not in self.op_nodes else "available"

    @staticmethod
    def node_cost(node):
        """(chatarra, núcleos) del nodo. El árbol se paga solo con núcleos: la chatarra es siempre 0."""
        spec = U.OPERATOR_TREE[node]
        return spec["cost"], spec["cores"]

    def buy_node(self, node):
        """Compra un nodo si su prerrequisito está comprado y alcanzan los NÚCLEOS (único recurso del árbol)."""
        scrap, cores = self.node_cost(node)
        if scrap:
            raise ValueError(f"{node}: el árbol del Operador solo se paga con núcleos")
        if self.node_state(node) != "available" or not self.spend_cores(cores):
            return False
        self.op_nodes.add(node)
        return True

    # efectos de los nodos (los lee Player.apply_upgrades y las escenas)
    def fire_cooldown(self):
        """Segundos entre disparos: 0,15 s, o 0,12 s con la Sobrecarga Balística (A3)."""
        return U.OPERATOR_EFFECTS["overload_cooldown"] if self.owns("sobrecarga_balistica") else C.PLAYER_SHOOT_RATE

    def bullet_damage(self):
        """Daño del rifle: 12; 16 con el Calibre Perforante I (A2); 20 con la Sobrecarga Balística (A3)."""
        if self.owns("sobrecarga_balistica"):
            return U.OPERATOR_EFFECTS["rifle_damage_tier3"]
        return U.OPERATOR_EFFECTS["rifle_damage_tier2"] if self.owns("calibre_perforante") else C.PLAYER_BULLET_DAMAGE

    def bullet_pierce(self):
        """Objetivos que atraviesa cada bala: 1; 2 desde el Calibre Perforante I."""
        return U.OPERATOR_EFFECTS["rifle_pierce_tier2"] if self.owns("calibre_perforante") else 1

    def ammo_capacity(self):
        return C.PLAYER_AMMO_CAPACITY + self.reward_tracker.player_bonus("ammo_max")

    @property
    def aura_scan(self):
        """Chasis 3/6: escaneo táctico de AURA en el radar."""
        return self.chassis_installed >= U.AURA_CHASSIS["scan_parts"]

    @property
    def aura_drone(self):
        """Chasis 6/6: AURA combate en el Acto 2 como dron autónomo."""
        return self.chassis_installed >= U.AURA_CHASSIS["drone_parts"]

    # --- mejoras permanentes de los drones (Fábrica) ---
    def buy_drone_upgrade(self, name):
        """Mejora permanente de dron (Terminal Táctico): se paga solo con ALEACIÓN MILITAR."""
        spec = U.DRONE_UPGRADES[name]
        if spec.get("cost") or spec.get("cores"):
            raise ValueError(f"{name}: las mejoras de drones solo se pagan con aleación")
        if name in self.drone_upgrades or not self.spend_alloy(spec["alloy"]):
            return False
        self.drone_upgrades.add(name)
        return True

    def install_chassis(self):
        """Instala un componente recuperado. Es gratis (el coste real es extraerlo con vida): no toca ningún recurso.
        Devuelve True si se instaló."""
        if self.chassis_available <= 0 or self.chassis_installed >= C.CHASSIS_TOTAL_PARTS:
            return False
        self.chassis_installed += 1
        return True

    # --- economía: tres pools separados (cada gasto toca UNO solo, nunca dos) ---
    def add_metal(self, amount):
        self.metal += int(amount)

    def add_cores(self, amount):
        self.cores += int(amount)

    def add_alloy(self, amount):
        self.alloy += int(amount)

    def can_afford(self, amount):
        return self.metal >= amount

    def can_pay(self, scrap, cores=0):
        """¿Alcanza para un gasto de UN pool? Un gasto que mezcle chatarra y núcleos nunca es válido."""
        if scrap and cores:
            return False
        return self.metal >= scrap and self.cores >= cores

    def pay(self, scrap, cores=0):
        """Cobra chatarra (compras tácticas) o núcleos (árbol), nunca las dos a la vez. Devuelve True si pudo."""
        if scrap and cores:
            raise ValueError("economía separada: un gasto no puede mezclar chatarra y núcleos")
        if not self.can_pay(scrap, cores):
            return False
        self.metal -= int(scrap)
        self.cores -= int(cores)
        return True

    def spend_metal(self, amount):
        """Chatarra: construir, mejorar muros, especializar torretas y reparar (moneda táctica del mapa)."""
        if amount < 0 or not self.can_afford(amount):
            return False
        self.metal -= int(amount)
        return True

    spend_scrap = spend_metal

    def spend_cores(self, amount):
        """Núcleos de Plasma: solo el árbol de habilidades del Operador."""
        if amount < 0 or self.cores < amount:
            return False
        self.cores -= int(amount)
        return True

    def spend_alloy(self, amount):
        """Aleación Militar: solo el Terminal Táctico (mejoras permanentes de drones)."""
        if amount < 0 or self.alloy < amount:
            return False
        self.alloy -= int(amount)
        return True

    @property
    def energy_free(self):
        return self.energy_cap - self.energy

    # --- terminal tactico / tablero de 5 operaciones de incursión (UNITS.INCURSION_OPS) ---
    def op_cleared(self, op):
        return op in self.campaign_run.ops_cleared

    def op_unlocked(self, op):
        """La Op 1 siempre; cada una, al superar la anterior. Las superadas quedan disponibles para siempre."""
        i = U.OPS_ORDER.index(op)
        return i == 0 or self.op_cleared(U.OPS_ORDER[i - 1])

    def op_level(self, op):
        """Dificultad de la operación (las repeticiones pueden subirla: "replay_level")."""
        spec = U.INCURSION_OPS[op]
        return spec.get("replay_level", spec["level"]) if self.op_cleared(op) else spec["level"]

    @staticmethod
    def _label(op):
        spec = U.INCURSION_OPS[op]
        return f"Op {spec['index']}: {spec['name']}"

    @property
    def command_module(self):
        """¿Tienes el Módulo de Mando del Búnker? (vive en CampaignRun)"""
        return self.campaign_run.command_module

    @command_module.setter
    def command_module(self, value):
        self.campaign_run.command_module = bool(value)

    @property
    def bunker_built(self):
        """¿Está ensamblado el Búnker de Mando? (vive en CampaignRun)"""
        return self.campaign_run.bunker_built

    @bunker_built.setter
    def bunker_built(self, value):
        self.campaign_run.bunker_built = bool(value)

    @property
    def campaign_completed(self):
        """¿Se ganó la campaña (asedio completado y guardado)? (vive en CampaignRun)"""
        return self.campaign_run.campaign_completed

    @campaign_completed.setter
    def campaign_completed(self, value):
        self.campaign_run.campaign_completed = bool(value)

    @property
    def can_start_siege(self):
        """El asedio se inicia desde la consola del Búnker: hace falta tenerlo ensamblado Y los planos de la Fábrica de Drones
        (el asalto se coordina con drones)."""
        return self.bunker_built and self.factory_blueprints

    @property
    def factory_blueprints(self):
        """¿Planos de la Fábrica de Drones? Se consiguen en la Op 4 (Infiltración en Complejo Tecnológico); los exige la
        consola del asedio. (Construir Fábricas en el Acto 2 depende de STRUCTURE_UNLOCKS: ejército del Comandante.)"""
        return self.all_structures_unlocked or self.campaign_run.factory_blueprints

    @factory_blueprints.setter
    def factory_blueprints(self, value):
        self.campaign_run.factory_blueprints = bool(value)

    def build_bunker(self):
        """Ensambla el Búnker de Mando: exige el Módulo de Mando y cobra 400 de chatarra y 2 núcleos a la vez (todo o nada).
        Devuelve (ok, mensaje)."""
        spec = U.BUNKER
        if self.bunker_built:
            return False, "El Búnker de Mando ya está ensamblado."
        missing = []
        if not self.command_module:
            missing.append("el Módulo de Mando")
        if self.metal < spec["cost"]:
            missing.append(f"{spec['cost'] - self.metal} de chatarra")
        if self.cores < spec["cores"]:
            missing.append(f"{spec['cores'] - self.cores} núcleo(s) de plasma")
        if missing:
            return False, (f"Requiere: {spec['cost']} de chatarra, {spec['cores']} núcleos de plasma y Módulo de Mando. "
                           f"Te falta: {', '.join(missing)}.")
        self.spend_metal(spec["cost"])
        self.spend_cores(spec["cores"])
        self.bunker_built = True
        self.history.append(f"Búnker de Mando ensamblado (-{spec['cost']} chatarra, -{spec['cores']} núcleos)")
        return True, "Búnker de Mando ensamblado."

    def finish_op(self, op, loot, cores=0, alloy=0, cleared=True, module=False, blueprints=False):
        """Extracción con vida: asegura todo el botín. Si el objetivo se cumplió (`cleared`) y es la primera vez: bono de la
        misión, +1 al nivel de incursión, la operación siguiente se abre y, desde la Op 2, +1 de alerta (con tope).
        Devuelve el bono cobrado."""
        spec = U.INCURSION_OPS[op]
        first = cleared and not self.op_cleared(op)
        bonus = spec["first_bonus"] if first else 0
        self.add_metal(loot + bonus)
        self.add_cores(cores)
        self.add_alloy(alloy)
        extra = (f" +{cores} núcleos" if cores else "") + (f" +{alloy} aleación" if alloy else "")
        if module and not self.command_module:
            self.command_module = True
            extra += " · Módulo de Mando"
        if blueprints and not self.factory_blueprints:
            self.factory_blueprints = True
            extra += " · Planos de la Fábrica de Drones"
        if first:
            self.campaign_run.ops_cleared.add(op)
            self.incursion_level += 1
            if spec["index"] == 1:
                self.initial_done = True
            elif self.threat_level < C.THREAT_LEVEL_BASE + U.OP_ALERT_CAP:
                self.threat_level += 1
        state = "superada" if cleared else "objetivo incompleto"
        self.history.append(f"{self._label(op)} ({state}): +{loot + bonus} chatarra{extra}")
        return bonus

    def fail_op(self, op, kept, lost, cores_kept=0, module_lost=False):
        """Operación fallida (Operador caído, taladro destruido o tiempo agotado): solo se conserva parte del botín."""
        self.add_metal(kept)
        self.add_cores(cores_kept)
        extra = " · Módulo de Mando perdido" if module_lost else ""
        self.history.append(f"{self._label(op)}: fallida, botín perdido -{lost} (conservado +{kept}){extra}")

    @property
    def threat_multiplier(self):
        return 1.0 + C.THREAT_LEVEL_MULTIPLIER * (self.threat_level - C.THREAT_LEVEL_BASE)

    @property
    def threat_bonus_pct(self):
        return round((self.threat_multiplier - 1.0) * 100)
