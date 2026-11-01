"""Fábrica de Drones: estructura 2x2 que se despliega en 20 s y después fabrica drones (10 s cada uno) desde su propia cola.

Reglas (UNITS.STRUCTURES["fabrica"]): cola de 4 por fábrica y 3 de energía solo mientras fabrica (sin energía la producción
se detiene). Se pueden construir varias. La flota tiene una capacidad DINÁMICA: cada Fábrica operativa (en pie, desplegada y
conectada a la red) aporta UNITS.DRONES_PER_FACTORY (8) al máximo de drones vivos en el mapa. El límite cuenta los drones de
todas las fábricas, así que vender y reconstruir no lo reinicia. Con la flota llena se puede seguir encargando (la cola espera)
y el dron terminado aguarda hueco. Si una fábrica cae, sus drones sobreviven, pero no se fabrican reemplazos mientras la flota
supere la capacidad de las fábricas que quedan. Cada dron nace con su mejora permanente si el Operador la compró."""
from pygame.math import Vector2

from src.config import UNITS as U
from src.entities.building import Building
from src.entities.drones import DRONE_CLASSES, FactoryDrone
from src.ui import structure_art as art


def drone_stats(drone_type, upgrades=(), rewards=None):
    """Copia de UNITS.DRONE_TYPES[tipo] con su mejora permanente sumada si está en `upgrades`. Si el tracker de rewards
    tiene la mejora de recompensa de ese dron, se aplica el mayor de los dos bonus (comprado o de recompensa)."""
    stats = dict(U.DRONE_TYPES[drone_type])
    name = stats["upgrade_name"]
    bonus = dict(U.DRONE_UPGRADES[name]["bonus"]) if name in upgrades else {}
    if rewards is not None:
        for key, value in rewards.drone_bonus(drone_type).items():
            bonus[key] = max(bonus.get(key, 0), value)
    for key, value in bonus.items():
        stats[key] = stats.get(key, 0) + value
    stats["mk"] = 2 if bonus else 1                  # Mk.II con la mejora (nombre del tooltip del dron)
    return stats


def fleet_count(world):
    """Drones de Fábrica vivos en todo el mundo (los haya hecho la fábrica que sea)."""
    return sum(1 for d in world.drones if isinstance(d, FactoryDrone) and d.alive())


def fleet_capacity(world):
    """Máximo de drones vivos: 8 por cada Fábrica operativa."""
    return U.DRONES_PER_FACTORY * sum(1 for f in world.factories if f.alive() and getattr(f, "operational", False))


def explorer_cap(world):
    """Tope de Exploradores en todo el mapa: 2 con una Fábrica operativa, +1 por cada adicional, hasta 4 (UNITS.EXPLORER_CAP).
    Es global: lo respetan todas las fábricas."""
    c = U.EXPLORER_CAP
    operational = sum(1 for f in world.factories if f.alive() and getattr(f, "operational", False))
    return min(c["max"], c["base"] + c["per_extra_factory"] * max(0, operational - 1))


def explorer_count(world):
    """Exploradores vivos en el mapa."""
    return sum(1 for d in world.drones if isinstance(d, FactoryDrone) and d.alive() and d.drone_type == "recon")


def explorer_committed(world):
    """Exploradores vivos + los que están encargados o en fabricación en cualquier fábrica (lo que cuenta para el tope)."""
    pending = sum((1 if f.current_production == "recon" else 0) + f.production_queue.count("recon")
                  for f in world.factories if f.alive())
    return explorer_count(world) + pending


class Factory(Building):
    def __init__(self, pos):
        super().__init__("fabrica", pos)
        spec = self.stats
        self.build_left = spec["build_time"]         # segundos de ensamblaje antes de poder fabricar
        self.production_queue = []                   # tipos en espera
        self.current_production = None               # tipo que se fabrica ahora
        self.production_time_left = 0.0
        self.drones = []                             # drones fabricados (vivos o caídos)
        self.energy_cost = 0                         # solo consume mientras fabrica
        self.upgrades = set()                        # mejoras permanentes compradas (las fija la escena)
        self.rewards = None                          # RewardTracker: mejoras de recompensa (las fija la escena)
        self.on_collect = None                       # callback(chatarra) de los Exploradores al llegar al Centro de Control
        self.on_drop = None                          # callback(chatarra, pos) cuando derriban a un Explorador con carga
        self.on_spawn = None                         # callback(dron) al terminar uno

    # --- estado ---
    @property
    def built(self):
        return self.build_left <= 0

    @property
    def operational(self):
        """Suma a la capacidad de la flota: desplegada (20 s cumplidos) y conectada a la red."""
        return self.built and self.is_powered

    def load(self):
        """Encargos pendientes de esta fábrica (en cola + el que fabrica): para repartir los pedidos entre fábricas."""
        return len(self.production_queue) + (1 if self.current_production else 0)

    def active_drones(self):
        return [d for d in self.drones if d.alive()]

    def get_active_drones_count(self):
        return len(self.active_drones())

    def world_drone_count(self):
        """Drones de Fábrica vivos en TODO el mundo (la única cuenta que vale para el límite)."""
        if self.world is None:
            return self.get_active_drones_count()
        return fleet_count(self.world)

    def fleet_capacity(self):
        """Capacidad de toda la flota (8 por fábrica operativa); sin mundo, la de esta fábrica sola."""
        if self.world is None:
            return U.DRONES_PER_FACTORY if self.operational else 0
        return fleet_capacity(self.world)

    @property
    def at_limit(self):
        """¿La flota ya llena (o excede) la capacidad de las fábricas operativas? Entonces no nacen más drones."""
        return self.world_drone_count() >= self.fleet_capacity()

    @property
    def waiting(self):
        """Dron terminado esperando hueco bajo el límite global."""
        return self.current_production is not None and self.production_time_left <= 0

    def committed(self):
        """Drones vivos en el mundo + el que se fabrica + los de la cola."""
        return self.world_drone_count() + len(self.production_queue) + (1 if self.current_production else 0)

    # --- producción ---
    def can_queue(self, drone_type, res=None):
        """(True, "") o (False, motivo) para encargar un dron. Con el límite lleno se puede encargar: espera en la cola."""
        spec = self.stats
        if not self.built:
            return False, f"La Fábrica aún se está ensamblando ({self.build_left:.0f} s)."
        if len(self.production_queue) >= spec["production_queue_size"]:
            return False, f"La cola de producción está llena ({spec['production_queue_size']})."
        dt = U.DRONE_TYPES[drone_type]
        if drone_type == "recon" and self.world is not None and explorer_committed(self.world) >= explorer_cap(self.world):
            return False, (f"Tope de Exploradores alcanzado ({explorer_cap(self.world)}): "
                           "pierde uno o construye otra Fábrica.")
        if res is not None and not res.can_pay(dt["cost"], dt["cores"]):
            return False, ("Núcleos de plasma insuficientes" if res.metal >= dt["cost"] else "Chatarra insuficiente") \
                + f" para el {dt['name']}."
        return True, ""

    def produce_drone(self, drone_type, res=None):
        """Encarga un dron (cobra al encargar). Devuelve True si entró en la cola."""
        ok, _ = self.can_queue(drone_type, res)
        if not ok:
            return False
        if res is not None:
            spec = U.DRONE_TYPES[drone_type]
            res.pay(spec["cost"], spec["cores"])
        self.production_queue.append(drone_type)
        return True

    def create_drone(self, drone_type):
        """Da a luz el dron si cabe bajo el límite de la flota (y, para el Explorador, bajo su tope). False si no cabe: el
        encargo sigue esperando."""
        if self.at_limit:
            return False
        if drone_type == "recon" and self.world is not None and explorer_count(self.world) >= explorer_cap(self.world):
            return False
        self._spawn_drone(drone_type)
        return True

    def _spawn_drone(self, drone_type):
        stats = drone_stats(drone_type, self.upgrades, self.rewards)
        cls = DRONE_CLASSES[drone_type]
        if U.DRONE_TYPES[drone_type].get("layer") == "air":                  # despegan del helipuerto (centro de la Fábrica)
            pos = Vector2(self.pos)
        else:                                                                # el Soldado sale por la compuerta inferior
            pos = Vector2(self.pos) + Vector2(0, self.rect.h // 2 + 18)
        drone = cls(pos, stats, home=self.pos)
        if drone_type == "recon":
            drone.on_collect, drone.on_drop = self.on_collect, self.on_drop
        self.drones.append(drone)
        if self.world is not None:
            self.world.drones.add(drone)
            self.world.all_sprites.add(drone)
        if self.on_spawn:
            self.on_spawn(drone)
        return drone

    def update(self, dt, enemies_group, bullets_group):
        super().update(dt, enemies_group, bullets_group)
        if self.build_left > 0:                                     # ensamblaje (no necesita energía)
            self.build_left = max(0.0, self.build_left - dt)
            return
        if self.current_production is None and self.production_queue and not self.at_limit:
            self.current_production = self.production_queue.pop(0)
            self.production_time_left = self.stats["production_time"]
        if self.waiting:                                            # terminado: espera hueco sin gastar energía
            self.energy_cost = 0
            if self.create_drone(self.current_production):
                self.current_production = None
            return
        self.energy_cost = self.stats["energy"] if self.current_production else 0
        if self.current_production and self.active:                # sin energía, la producción se detiene
            self.production_time_left = max(0.0, self.production_time_left - dt)
            if self.production_time_left <= 0 and self.create_drone(self.current_production):
                self.current_production = None
                self.energy_cost = self.stats["energy"] if self.production_queue else 0

    # --- dibujo ---
    def _render(self):
        return art.render_factory(Building.SIZES["fabrica"])

    def draw_dynamic(self, surface, screen_rect, offset):
        t = art.now()
        art.draw_factory_status(surface, screen_rect, t, self.build_left / self.stats["build_time"],
                                (1 - self.production_time_left / self.stats["production_time"]) if self.current_production else None,
                                self.current_production, len(self.production_queue), self.active)
