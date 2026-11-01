"""Bases enemigas con IA (Prioridad 3.A): mini-bases que extraen su mineral, construyen y contraatacan.

Cada `EnemyBase` tiene un núcleo (`EnemyBaseCore`, 1000 HP), dos depósitos de chatarra propios, recursos (chatarra,
núcleos, energía) y una cola de prioridades según la dificultad. Cada 45 s decide: construir (40%), reparar (30%) o
esperar; antes que nada pone extractores en sus depósitos libres (economía primero, como en StarCraft). Si el jugador
le destruye un edificio, sube su escalada y lanza un contraataque. Todo lo que construye es hostil (world.hostile).

Fase 6 · blindaje: cada base nace (una sola vez) con una guarnición gratuita según su dificultad (UNITS.ENEMY_BASES
["garrison"]): muros, torretas centinela y un generador. Mientras el generador Y al menos una centinela sigan en pie, el
núcleo es invulnerable. Cuando por fin cae, detona y su dotación evacúa hacia el borde del mapa (no es una oleada)."""
import itertools
import math
import random
from types import SimpleNamespace

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities.foundry import HostileStructure
from src.entities.projectile import Projectile
from src.entities.resource_node import ScrapDeposit
from src.managers.resource_manager import validate_structure_position
from src.mechanics import combat
from src.ui import structure_art as art

SPEC = U.ENEMY_BASES
G = C.BUILD_GRID


def _hostile_tint(img):
    img = img.copy()
    img.fill((255, 120, 120, 255), special_flags=pygame.BLEND_RGBA_MULT)
    return img


class EnemyBuilding(HostileStructure):
    """Edificio construido por una base IA. Al caer avisa a su base (escalada y contraataque)."""

    def __init__(self, kind, pos, base, size=(G, G)):
        self.kind = kind
        self.base = base
        self.role = None                      # guarnición: "wall" / "sentinel" / "generator" (None = la levantó la IA)
        self.spec = SPEC["structures"].get(kind, {})
        super().__init__(pos, self.spec.get("hp", 100), size)

    def _render(self, size):
        return art.render_wall(size, "hostile")

    def kill(self):
        was_alive = self.alive()
        super().kill()
        if was_alive and self.base is not None:
            self.base.on_building_lost(self)


class EnemyWall(EnemyBuilding):
    pass


class EnemyTurret(EnemyBuilding):
    """Torreta de la IA: dispara al jugador, a sus drones y a sus estructuras dentro de su alcance."""

    def __init__(self, kind, pos, base):
        self.fire_timer = 0.0
        self.angle = 180.0
        super().__init__(kind, pos, base)

    def _render(self, size):
        return art.render_tower_base(size, "hostile")

    def draw_dynamic(self, surface, screen_rect, offset):
        art.draw_turret_head(surface, screen_rect.center, self.angle, "hostile", True, art.now(),
                             "balista" if self.kind == "torreta_pesada" else "tower")

    def update(self, dt, world):
        self.fire_timer -= dt
        best, best_d = None, self.spec["range"] ** 2
        player = [world.player] if world.player is not None and world.player.alive() else []
        for target in itertools.chain(player, world.drones, world.structures):
            d = self.pos.distance_squared_to(target.pos)
            if d < best_d:
                best, best_d = target, d
        if best is None:
            return
        direction = best.pos - self.pos
        self.angle = math.degrees(math.atan2(direction.y, direction.x))
        if self.fire_timer <= 0 and direction.length_squared() > 0:
            world.enemy_bullets.add(Projectile(self.pos, direction, self.spec["damage"], "enemy",
                                               lifetime=self.spec["range"] * 1.2 / 500))
            self.fire_timer = self.spec["delay"]


class SentinelTower(EnemyTurret):
    """Torreta centinela de la guarnición: mientras viva una (y el generador), el núcleo de su base es invulnerable."""


class EnemyPower(EnemyBuilding):
    """Generador o pilón de la IA: amplía su capacidad de energía."""

    def _render(self, size):
        maker = art.render_generator if self.kind == "generador" else art.render_pylon
        return _hostile_tint(maker(size))


class EnemyExtractor(EnemyBuilding):
    """Extractor de la IA sobre uno de sus depósitos: +5 de chatarra cada 3 s hasta agotarlo."""

    def __init__(self, pos, base, deposit):
        self.deposit = deposit
        self.timer = 0.0
        super().__init__("extractor", pos, base)
        deposit.extractor = self

    def _render(self, size):
        return _hostile_tint(art.render_extractor(size))

    def update(self, dt, world):
        if self.deposit.depleted:
            return
        self.timer += dt
        if self.timer >= self.spec["interval"]:
            self.timer -= self.spec["interval"]
            self.base.scrap += self.deposit.take_metal(self.spec["income"])

    def kill(self):
        self.deposit.extractor = None
        super().kill()


class EnemyBaseCore(HostileStructure):
    """Núcleo de una base IA: si cae, la base queda destruida."""

    SHIELD_COLOR = (90, 200, 255)

    def __init__(self, pos, base):
        self.base = base
        self.shield_flash = 0.0
        super().__init__(pos, SPEC["core_hp"], (SPEC["core_size"], SPEC["core_size"]))

    def _render(self, size):
        return art.render_core(size, "hostile")

    @property
    def shielded(self):
        return self.base is not None and self.base.has_active_defenses()

    def take_damage(self, amount, direction=None):
        """Con el generador y una centinela en pie, el escudo absorbe el golpe entero."""
        if self.shielded:
            self.shield_flash = 0.25
            combat.FX.spark(self.pos, self.SHIELD_COLOR)
            return False
        return super().take_damage(amount, direction)

    def update(self, dt, world):
        self.shield_flash = max(0.0, self.shield_flash - dt)

    def draw_dynamic(self, surface, screen_rect, offset):
        art.draw_energy_core(surface, screen_rect.center, "hostile", art.now(), 30)
        if self.shielded:                                            # burbuja del escudo (más viva al recibir un golpe)
            r = SPEC["core_size"] // 2 + 14
            width = 3 if self.shield_flash > 0 else 1
            pygame.draw.circle(surface, self.SHIELD_COLOR, screen_rect.center, r, width)

    def kill(self):
        was_alive = self.alive()
        super().kill()
        if was_alive and self.base is not None:
            self.base.on_core_destroyed()


class EnemyBase:
    """Lógica de una mini-base enemiga (no es un sprite: sus piezas sí)."""

    def __init__(self, pos, difficulty="easy", world=None, rng=None, garrison=True):
        self.x, self.y = float(pos[0]), float(pos[1])
        half = SPEC["core_size"] / 2
        if world is not None and world.bounds is not None:           # colocación de la base: siempre dentro del mapa
            validate_structure_position(self, world.bounds.w, world.bounds.h, (half, half))
        self.pos = Vector2(self.x, self.y)
        self.difficulty = difficulty
        self.world = world
        self.rng = rng or random.Random(random.random())    # reproducible si se fija la semilla global
        self.scrap = SPEC["start_scrap"]
        self.plasma_cores = SPEC["start_cores"]
        self.energy = float(SPEC["energy"])
        self.base_energy_cap = SPEC["energy_cap"]
        self.buildings = []
        self.deposits = []
        self.ai_timer = SPEC["ai_interval"] - SPEC["first_decision"]
        self.ai_action_interval = SPEC["ai_interval"]
        self.build_priority = list(SPEC["priority"][difficulty])
        self.detected = False                 # revelada en la niebla (minimapa)
        self.destroyed = False
        self.escalation = 0
        self.decisions = []                   # historial: "build:muro", "repair", "wait", "extractor"...
        self.on_counterattack = None          # callback(base, roster) que lanza la escena
        self.on_evacuate = None               # callback(base, roster): dotación que huye al caer el núcleo
        self.on_destroyed = None              # callback(base)
        self.generator = None                 # guarnición: el generador del escudo...
        self.sentinels = []                   # ...y sus torretas centinela
        self.garrison_created = False         # la guarnición se crea UNA vez (restore no la repite)
        self.core = EnemyBaseCore(self.pos, self)
        if world is not None:
            self._add(self.core)
            for off in SPEC["deposits"]:
                dep = ScrapDeposit(self.pos + Vector2(off))
                self.deposits.append(dep)
                world.deposits.add(dep)
                world.all_sprites.add(dep)
            if garrison and not self.garrison_created:
                self._create_garrison()

    # --- utilidades ---
    @property
    def health(self):
        return max(0, self.core.hp)

    @property
    def max_health(self):
        return self.core.max_hp

    @property
    def energy_cap(self):
        return self.base_energy_cap + sum(b.spec.get("energy_cap", 0) for b in self.buildings if b.alive())

    def _add(self, sprite):
        w = self.world
        w.hostile.add(sprite)
        w.solids.add(sprite)
        w.all_sprites.add(sprite)

    def alive_buildings(self):
        return [b for b in self.buildings if b.alive()]

    def take_damage(self, damage):
        """Daño directo al núcleo (las balas lo dañan por la vía normal de las estructuras hostiles). Con defensas
        activas el escudo lo absorbe (ver EnemyBaseCore.take_damage)."""
        return self.core.take_damage(damage)

    # --- guarnición y escudo ---
    def has_active_defenses(self):
        """True si el generador de la guarnición Y al menos una torreta centinela siguen en pie (núcleo invulnerable)."""
        gen = self.generator
        if gen is None or not gen.alive() or gen.hp <= 0:
            return False
        return any(t.alive() and t.hp > 0 for t in self.sentinels)

    def _garrison_spot(self, offset, size):
        """Celda para una pieza de la guarnición: dentro del mapa y sin pisar el núcleo, un depósito ni otra estructura.
        Si está ocupada, se desplaza de celda en celda hacia el frente (+y), luego hacia atrás y, si la columna entera
        está llena (p. ej. una base pegada a una esquina), recorre anillos de celdas alrededor."""
        w = self.world
        probe = pygame.sprite.Sprite()
        base_x, base_y = self.x + offset[0], self.y + offset[1]
        steps = [(0, k) for k in range(0, 8)] + [(0, -k) for k in range(1, 8)]
        steps += [(dx, dy) for r in range(1, 8) for dy in range(-r, r + 1) for dx in (-r, r)]   # anillos (columnas)
        steps += [(dx, dy) for r in range(1, 8) for dx in range(-r + 1, r) for dy in (-r, r)]   # anillos (filas)
        spot = None
        for dx, dy in steps:
            spot = SimpleNamespace(x=base_x + dx * G, y=base_y + dy * G)
            if w.bounds is not None:
                validate_structure_position(spot, w.bounds.w, w.bounds.h, (size[0] / 2, size[1] / 2))
            probe.rect = pygame.Rect(0, 0, *size)
            probe.rect.center = (round(spot.x), round(spot.y))
            if not (pygame.sprite.spritecollideany(probe, w.solids) or pygame.sprite.spritecollideany(probe, w.deposits)):
                return Vector2(spot.x, spot.y)
        return Vector2(spot.x, spot.y)

    def _create_garrison(self):
        """Muros, centinelas y generador según la dificultad (gratis). Solo la primera vez."""
        for kind, offset, role in SPEC["garrison"][self.difficulty]:
            b = self._make_building(kind, self._garrison_spot(offset, (G, G)), role)
            self.buildings.append(b)
            self._add(b)
        self.garrison_created = True

    def _make_building(self, kind, pos, role=None):
        """Pieza de la base del tipo `kind`; `role` marca las de la guarnición (y enlaza generador y centinelas)."""
        if role == "sentinel":
            b = SentinelTower(kind, pos, self)
            self.sentinels.append(b)
        elif kind.startswith("torreta"):
            b = EnemyTurret(kind, pos, self)
        elif kind in ("generador", "pilon"):
            b = EnemyPower(kind, pos, self)
        else:
            b = EnemyWall(kind, pos, self)
        b.role = role
        if role == "generator":
            self.generator = b
        return b

    # --- IA ---
    def update(self, dt, player_position=None):
        if self.destroyed:
            return
        self.energy = min(self.energy + SPEC["energy_regen"] * dt, self.energy_cap)
        self.ai_timer += dt
        if self.ai_timer >= self.ai_action_interval:
            self.ai_timer = 0.0
            self._ai_decide_action()

    def _ai_decide_action(self):
        if self._ai_build_extractor():                    # economía primero: extractores en sus depósitos libres
            return
        roll = self.rng.random()
        if roll < SPEC["build_chance"]:
            self.decisions.append("build:" + str(self._ai_try_build()))
        elif roll < SPEC["build_chance"] + SPEC["repair_chance"]:
            self._ai_repair_buildings()
            self.decisions.append("repair")
        else:
            self.decisions.append("wait")

    def _can_afford(self, spec):
        return (self.scrap >= spec.get("cost", 0) and self.plasma_cores >= spec.get("cores", 0)
                and self.energy >= spec.get("energy", 0))

    def _charge(self, spec):
        self.scrap -= spec.get("cost", 0)
        self.plasma_cores -= spec.get("cores", 0)
        self.energy -= spec.get("energy", 0)

    def _ai_build_extractor(self):
        spec = SPEC["structures"]["extractor"]
        free = [d for d in self.deposits if d.extractor is None and not d.depleted]
        if not free or not self._can_afford(spec) or self.world is None:
            return False
        dep = free[0]
        self._charge(spec)
        ext = EnemyExtractor(Vector2(dep.pos), self, dep)
        self.buildings.append(ext)
        self._add(ext)
        self.decisions.append("extractor")
        return True

    def _free_spot(self):
        """Celda libre a menos de 200 px de la base: dentro del mapa, sin solapar nada y lejos del Centro de Control."""
        w = self.world
        bounds = w.bounds
        player_core = w.core.pos if w.core is not None else None
        probe = pygame.sprite.Sprite()
        for _ in range(16):
            ox = self.rng.randint(-SPEC["build_radius"], SPEC["build_radius"])
            oy = self.rng.randint(-SPEC["build_radius"], SPEC["build_radius"])
            cx = int((self.x + ox) // G) * G + G // 2
            cy = int((self.y + oy) // G) * G + G // 2
            rect = pygame.Rect(0, 0, G, G)
            rect.center = (cx, cy)
            if not bounds.contains(rect):
                continue
            if player_core is not None and player_core.distance_to((cx, cy)) < SPEC["min_dist_player_core"]:
                continue
            probe.rect = rect.inflate(4, 4)
            if pygame.sprite.spritecollideany(probe, w.solids) or pygame.sprite.spritecollideany(probe, w.deposits):
                continue
            return Vector2(cx, cy)
        return None

    def _ai_try_build(self):
        """Construye lo siguiente de su cola (rotándola). Devuelve el tipo construido o None."""
        if not self.build_priority or self.world is None:
            return None
        kind = self.build_priority[0]
        spec = SPEC["structures"][kind]
        if not self._can_afford(spec):
            return None
        spot = self._free_spot()
        if spot is None:
            return None
        self._charge(spec)
        b = self._make_building(kind, spot)
        self.buildings.append(b)
        self._add(b)
        self.build_priority.append(self.build_priority.pop(0))
        return kind

    def _ai_repair_buildings(self):
        rep = SPEC["repair"]
        damaged = [b for b in self.alive_buildings() + [self.core] if b.alive() and b.hp < b.max_hp * rep["threshold"]]
        if not damaged:
            return None
        worst = min(damaged, key=lambda b: b.hp / b.max_hp)
        amount = min(rep["amount"], worst.max_hp - worst.hp)
        cost = int(amount * rep["cost_per_hp"])
        if self.scrap < cost:
            return None
        self.scrap -= cost
        worst.hp = min(worst.max_hp, worst.hp + amount)
        return worst

    # --- reacciones ---
    def on_building_lost(self, building):
        if building in self.buildings:
            self.buildings.remove(building)
        if self.destroyed:
            return
        self.escalation += 1
        if self.escalation % 3 == 0:                      # cada 3 edificios perdidos, la IA decide más deprisa
            self.ai_action_interval = max(20.0, self.ai_action_interval - 5.0)
        cfg = SPEC["counterattack"]
        roster = ["scout"] * (cfg["scouts"] + self.escalation) + ["soldier"] * (self.escalation // cfg["soldier_every"])
        if self.on_counterattack:
            self.on_counterattack(self, roster)

    def on_core_destroyed(self):
        if self.destroyed:
            return
        self.destroyed = True
        for b in self.alive_buildings():                 # sin núcleo, la base se desmorona
            b.base = None
            combat.FX.debris(b.pos, (150, 60, 60), 6)
            HostileStructure.kill(b)
        ev = SPEC["evacuation"]                          # detonación y evacuación de la dotación (no es una oleada)
        combat.FX.blast(self.pos, ev["blast_radius"])
        combat.FX.debris(self.pos, (255, 140, 60), 18)
        combat.FX.request_shake()
        roster = [kind for kind, n in ev["roster"].get(self.difficulty, {}).items() for _ in range(n)]
        if roster and self.on_evacuate:
            self.on_evacuate(self, roster)
        if self.on_destroyed:
            self.on_destroyed(self)

    # --- persistencia (entre 2.1 y 2.2) ---
    def dump(self):
        return {"pos": (self.x, self.y), "difficulty": self.difficulty, "destroyed": self.destroyed,
                "core_hp": self.core.hp, "scrap": self.scrap, "cores": self.plasma_cores, "energy": self.energy,
                "escalation": self.escalation, "priority": list(self.build_priority),
                "base_id": getattr(self, "base_id", None), "index": getattr(self, "index", None),
                "deposits": [d.total_metal for d in self.deposits], "garrison_created": self.garrison_created,
                "buildings": [(b.kind, (b.pos.x, b.pos.y), b.hp, getattr(b, "role", None)) for b in self.alive_buildings()]}

    @classmethod
    def restore(cls, data, world, rng=None):
        base = cls(data["pos"], data["difficulty"], world, rng, garrison=False)        # la guarnición viaja en "buildings"
        base.garrison_created = data.get("garrison_created", False)
        base.base_id, base.index = data.get("base_id"), data.get("index")     # premio del mapa de campaña
        base.scrap, base.plasma_cores, base.energy = data["scrap"], data["cores"], data["energy"]
        base.escalation, base.build_priority = data["escalation"], list(data["priority"])
        base.ai_action_interval = max(20.0, base.ai_action_interval - 5.0 * (base.escalation // 3))
        for dep, left in zip(base.deposits, data["deposits"]):
            dep.total_metal = left
        for entry in data["buildings"]:
            kind, pos, hp = entry[0], entry[1], entry[2]
            role = entry[3] if len(entry) > 3 else None
            if kind == "extractor":
                dep = min(base.deposits, key=lambda d: d.pos.distance_squared_to(pos))
                b = EnemyExtractor(Vector2(dep.pos), base, dep)
            else:
                b = base._make_building(kind, Vector2(pos), role)
            b.hp = hp
            base.buildings.append(b)
            base._add(b)
        base.core.hp = data["core_hp"]
        if data["destroyed"]:
            base.destroyed = True
            HostileStructure.kill(base.core)
        return base


def base_positions(n):
    """Posiciones de n bases: las ranuras fijas del mapa y, a partir de la sexta, un círculo alrededor del centro."""
    slots = [Vector2(p) for p in SPEC["slots"]]
    if n <= len(slots):
        return slots[:n]
    center = Vector2(C.ACT2_W * 0.55, C.ACT2_H / 2)
    return [center + Vector2(math.cos(math.tau * i / n), math.sin(math.tau * i / n)) * 430 for i in range(n)]


def bases_for_alert(alert):
    """(número de bases, dificultad) según el Nivel de Alerta."""
    table = SPEC["by_alert"]
    return table[max(min(table), min(max(table), alert))]
