import math
import random
from collections import deque

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities.enemy import Enemy


class Wave:
    """Composición y calendario de una oleada (1-5)."""
    COMPOSITION = U.WAVES["composition"]

    def __init__(self, wave_num, threat_level, control_center_pos, spawn_zone=None, size_factor=1.0, roster=None):
        self.roster = list(roster) if roster is not None else None      # mapas de campaña: lista fija de enemigos
        self.wave_num = wave_num
        self.threat_level = threat_level
        self.duration = C.WAVE_DURATION
        self.relief = {} if roster is not None else U.WAVE_ALERT_RELIEF.get(wave_num, {}).get(threat_level, {})
        self.spawn_rate = C.WAVE_SPAWN_RATE
        self.control_center_pos = Vector2(control_center_pos)
        self.spawn_zone = pygame.Rect(spawn_zone) if spawn_zone is not None else None
        self.size_factor = size_factor               # <1 si el jugador intercepta la chatarra
        self.enemies_spawned = []
        self.threat_multiplier = 1 + (threat_level - C.THREAT_LEVEL_BASE) * C.THREAT_LEVEL_MULTIPLIER
        self.schedule = self._build_schedule()

    def _entries(self):
        """(tipo, cantidad escalada, retraso o None) de la composición de esta oleada."""
        spawns = self.COMPOSITION[min(self.wave_num, max(self.COMPOSITION))]
        spawns = [e for e in spawns if e[0] not in self.relief.get("skip", ())]   # oleada 3 a alertas 1-2: sin Ariete
        factor = C.WAVE_SIZE_MULTIPLIER * self.threat_multiplier * self.size_factor
        relief = U.THREAT_HEAVY_RELIEF.get(self.threat_level, 1.0)       # alertas 3-4: menos pesados simultáneos
        return [(e[0], max(1, round(e[1] * factor * (relief if e[0] in U.HEAVY_KINDS else 1.0))),
                 e[2] if len(e) > 2 else None) for e in spawns]

    def get_enemy_spawns(self):
        """Lista de (tipo, cantidad) con multiplicador de amenaza y de oleada aplicados (incluye los retrasados)."""
        totals = {}
        if self.roster is not None:
            for kind in self.roster:
                totals[kind] = totals.get(kind, 0) + 1
            return list(totals.items())
        for kind, count, _ in self._entries():
            totals[kind] = totals.get(kind, 0) + count
        return list(totals.items())

    def delayed_spawns(self):
        """[(retraso_s, tipo)] de los refuerzos que entran a mitad de oleada (p. ej. Arietes de la oleada 5 a los 15 s)."""
        if self.roster is not None:
            return []
        return sorted((delay, kind) for kind, count, delay in self._entries() if delay for _ in range(count))

    @property
    def batch_size(self):
        """Enemigos por aparición: la oleada entera llega dentro de `duration` segundos."""
        slots = max(1, int(self.duration // self.spawn_rate))
        return max(1, math.ceil(len(self.schedule) / slots))

    def _build_schedule(self):
        """Calendario inicial: los de retraso 0 abren la oleada; el resto se baraja; los retrasados entran después."""
        if self.roster is not None:
            body = list(self.roster)
            random.shuffle(body)
            return body
        entries = self._entries()
        lead = [kind for kind, count, delay in entries if delay == 0 for _ in range(count)]
        body = [kind for kind, count, delay in entries if delay is None for _ in range(count)]
        random.shuffle(body)
        return lead + body

    def _spawn_point(self):
        if self.spawn_zone is not None:              # puertas de la Fundición
            z = self.spawn_zone
            return Vector2(random.uniform(z.left, z.right), random.uniform(z.top, z.bottom))
        side = random.choice("lrtb")
        w, h = C.WINDOW_WIDTH, C.WINDOW_HEIGHT
        if side == "l":
            return Vector2(-30, random.uniform(0, h))
        if side == "r":
            return Vector2(w + 30, random.uniform(0, h))
        if side == "t":
            return Vector2(random.uniform(0, w), -30)
        return Vector2(random.uniform(0, w), h + 30)

    def spawn_enemy(self, spawn_index, enemies_group):
        """Crea el enemigo `spawn_index` del calendario, rumbo al Centro de Control."""
        enemy = Enemy(self.schedule[spawn_index], self._spawn_point(), self.control_center_pos, enemies_group)
        enemies_group.add(enemy)
        self.enemies_spawned.append(enemy)
        return enemy


class WaveGenerator:
    """Generador de oleadas escaladas de un mapa de campaña (Stronghold Loop), 100% dirigido por CAMPAIGN_MAPS.

    Tras cada `wave_big_interval` oleadas pequeñas llega una grande. Las listas de tamaños se recorren en bucle y las
    grandes repiten la última. `entry(n)` es la oleada nº n (sin estado); `start_wave/update` son la cola de apariciones
    con ritmo fijo (`spawn_interval`), que usa la partida para saber qué toca y los tests para comprobar el timing."""

    def __init__(self, cfg):
        self.cfg = cfg
        self.wave_small_sizes = cfg["wave_small_sizes"]
        self.wave_big_interval = cfg["wave_big_interval"]
        self.wave_big_sizes = cfg["wave_big_sizes"]
        self.break_time = cfg["break_time"]
        self.spawn_interval = cfg.get("spawn_interval", U.CAMPAIGN_SPAWN_INTERVAL)
        self.plan = U.campaign_wave_plan(cfg)                    # primera vuelta
        self.assault_after = U.campaign_assault_after(cfg)
        self.current_wave_index = 0                              # oleadas empezadas
        self.is_big_wave = False
        self.wave_active = False
        self.wave_complete = True
        self.spawn_queue = deque()
        self.spawn_timer = 0.0

    def entry(self, n):
        """(etiqueta, tamaño, lista de enemigos) de la oleada nº n (1, 2, 3...)."""
        return U.campaign_wave_entry(self.cfg, n)

    def start_wave(self):
        """Empieza la siguiente oleada (solo si la anterior terminó de aparecer)."""
        if not self.wave_complete:
            return
        kind, _, roster = self.entry(self.current_wave_index + 1)
        self.is_big_wave = kind == "big"
        roster = list(roster)
        random.shuffle(roster)
        self.spawn_queue = deque(roster)
        self.spawn_timer = 0.0
        self.wave_active, self.wave_complete = True, False
        self.current_wave_index += 1

    def update(self, dt):
        """Avanza el reloj; devuelve el tipo de enemigo que toca aparecer ahora (o None)."""
        if not self.wave_active:
            return None
        self.spawn_timer -= dt
        if self.spawn_timer <= 0 and self.spawn_queue:
            self.spawn_timer = self.spawn_interval
            return self.spawn_queue.popleft()
        if not self.spawn_queue:
            self.wave_active, self.wave_complete = False, True
        return None

    def get_wave_info(self):
        return {"wave_number": self.current_wave_index, "is_big_wave": self.is_big_wave,
                "enemies_remaining": len(self.spawn_queue)}

    def should_start_next_wave(self):
        return self.wave_complete and not self.wave_active


class RenegadeFoundry:
    """Fábrica enemiga fuera de pantalla: convierte la chatarra robada en refuerzos.

    Cada 75 de metal robado añade un Ariete blindado o acorta el intervalo de asedio (alternando).
    Si el jugador intercepta la chatarra, las oleadas se vuelven más pequeñas."""

    def __init__(self):
        self.enemy_scrap_pool = 0
        self.tiers = 0
        self.rams_queued = 0
        self.interval_mult = 1.0
        self.intercepted = 0

    def add_scrap(self, value):
        """Devuelve la lista de mejoras ("ram" / "speed") que desbloquea el metal robado."""
        self.enemy_scrap_pool += value
        upgrades = []
        while self.enemy_scrap_pool >= C.FOUNDRY_SCRAP_STEP:
            self.enemy_scrap_pool -= C.FOUNDRY_SCRAP_STEP
            self.tiers += 1
            if self.tiers % 2 == 1:
                self.rams_queued += 1
                upgrades.append("ram")
            else:
                self.interval_mult = max(C.FOUNDRY_MIN_INTERVAL, self.interval_mult * C.FOUNDRY_INTERVAL_STEP)
                upgrades.append("speed")
        return upgrades

    def intercept(self, value):
        self.intercepted += value

    @property
    def size_factor(self):
        return 1.0 - min(0.4, 0.4 * self.intercepted / C.INTERCEPT_WEAKNESS_STEP)


class WaveManager:
    """Preparación (20s, -50% construcción), 5 oleadas de asedio y después incursiones de la Fundición."""

    def __init__(self, world, threat_level, control_center_pos, on_death, spawn_zone=None, foundry=None, plan=None,
                 break_time=None, generator=None, endless=False):
        self.world = world
        self.generator = generator            # mapas de campaña: WaveGenerator (oleadas más allá del plan, en bucle)
        self.endless = endless                # sin Fundición: las oleadas no acaban hasta ganar o agotar el tiempo
        self.plan = plan                      # mapas de campaña: [(etiqueta, tamaño, lista de enemigos)]; None = clásico
        self.break_time = C.BREAK_TIME if break_time is None else break_time
        self.threat_level = threat_level
        self.control_center_pos = Vector2(control_center_pos)
        self.on_death = on_death
        self.spawn_zone = spawn_zone
        self.foundry = foundry if foundry is not None else RenegadeFoundry()
        self.total_waves = len(plan) if plan else C.TOTAL_WAVES_ACT2
        self.wave = 0
        self.current = None
        self.phase = "prep"           # prep | wave | break | assault
        self.timer = C.PREPARATION_TIME
        self.raid_timer = 0.0
        self.spawn_timer = 0.0
        self.spawned = 0
        self.wave_time = 0.0          # segundos transcurridos de la oleada en curso (cuenta atrás del HUD)
        self.pending_delayed = []     # refuerzos retrasados de la oleada en curso: [(segundos, tipo)]
        self.events = []

    @property
    def build_discount(self):
        return C.PREP_DISCOUNT if self.phase == "prep" else 0.0

    def _wave_enemies(self):
        """Enemigos vivos que cuentan para la oleada (los evacuados de una base caída no)."""
        return sum(1 for e in self.world.enemies if not getattr(e, "is_evacuation", False))

    @property
    def remaining(self):
        pending = len(self.current.schedule) - self.spawned if self.current else 0
        return pending + len(self.pending_delayed) + self._wave_enemies()

    def pop_events(self):
        ev, self.events = self.events, []
        return ev

    def skip_prep(self):
        if self.phase == "prep" or (self.phase == "break" and self.plan is not None):   # en los mapas también se salta el respiro
            self.timer = 0.0

    @property
    def wave_kind(self):
        """"small" / "big" de la oleada en curso en un mapa de campaña (None en el clásico)."""
        return self.generator.entry(self.wave)[0] if self.generator and self.wave >= 1 else None

    # --- oleadas e incursiones ---
    def _new_wave(self, number, size=1.0, roster=None):
        if roster is None and self.generator:
            roster = self.generator.entry(number)[2]
        static = None if callable(self.spawn_zone) else self.spawn_zone      # la dinámica se resuelve en cada aparición
        self.current = Wave(number, self.threat_level, self.control_center_pos, static,
                            size * self.foundry.size_factor, roster)
        if self.generator:
            self.current.spawn_rate = self.generator.spawn_interval      # aparición continua (0,3 s por enemigo)
        self.spawned = 0
        self.spawn_timer = 0.0
        self.pending_delayed = self.current.delayed_spawns()     # [(segundos, tipo)] aún por entrar

    def _start_wave(self, n):
        self.wave = n
        self.wave_time = 0.0
        self.phase = "wave"
        self._new_wave(n)
        self.events.append(("wave_start", n))

    def _inject_rams(self):
        """Los Arietes que financió la chatarra robada se suman al calendario en curso."""
        if self.current is not None and self.foundry.rams_queued > 0:
            n = self.foundry.rams_queued
            self.foundry.rams_queued = 0
            self.current.schedule.extend(["ariete"] * n)
            self.events.append(("foundry_ram", n))

    def _zone(self):
        """Puerta de aparición: un rectángulo fijo, o uno al azar de la lista (las bases enemigas vivas)."""
        zone = self.spawn_zone() if callable(self.spawn_zone) else self.spawn_zone
        if isinstance(zone, (list, tuple)) and zone and isinstance(zone[0], pygame.Rect):
            return random.choice(zone)
        return zone

    def _spawn_next(self):
        w = self.world
        zone = self._zone()
        if zone is not None:
            self.current.spawn_zone = pygame.Rect(zone)
        enemy = self.current.spawn_enemy(self.spawned, w.enemies)
        enemy.on_death = self.on_death
        enemy.world = w                       # dispara / carga contra lo que tiene delante
        enemy.always_active = True
        w.all_sprites.add(enemy)
        w.targets.add(enemy)
        self.spawned += 1

    def _spawn_done(self):
        return self.current is None or (self.spawned >= len(self.current.schedule) and not self.pending_delayed)

    def _step_spawns(self, dt):
        cur = self.current
        if cur is None:
            return
        self._inject_rams()
        while self.pending_delayed and self.wave_time >= self.pending_delayed[0][0]:   # refuerzo retrasado: entra ya
            cur.schedule.append(self.pending_delayed.pop(0)[1])
            self.spawn_timer = min(self.spawn_timer, 0.0)
        self.spawn_timer -= dt
        if self.spawn_timer <= 0 and self.spawned < len(cur.schedule):
            for _ in range(cur.batch_size):
                if self.spawned < len(cur.schedule):
                    self._spawn_next()
            self.spawn_timer += cur.spawn_rate * self.foundry.interval_mult

    def update(self, dt):
        if self.phase in ("prep", "break"):
            self.timer -= dt
            if self.timer <= 0:
                if self.phase == "prep":
                    self.events.append(("prep_end", 0))
                self._start_wave(self.wave + 1)
        elif self.phase == "wave":
            self.wave_time += dt
            self._step_spawns(dt)
            if self._spawn_done() and self._wave_enemies() == 0:
                self.events.append(("wave_clear", self.wave))
                if self.wave >= self.total_waves and not self.endless:
                    # Las oleadas solo ganan tiempo: ahora hay que asaltar la Fundición
                    self.phase = "assault"
                    self.raid_timer = 5.0
                    self.events.append(("assault_start", 0))
                else:
                    self.phase = "break"
                    self.timer = self.break_time
        elif self.phase == "assault":
            self._step_spawns(dt)
            self.raid_timer -= dt
            if self.raid_timer <= 0 and self._spawn_done():
                if self.plan:                                        # mapas: incursiones del tamaño de la última pequeña
                    last_small = next(r for lab, _, r in reversed(self.plan) if lab == "small")
                    self._new_wave(self.total_waves, roster=last_small)
                else:
                    self._new_wave(self.total_waves, C.ASSAULT_RAID_SIZE)
                self.raid_timer = C.ASSAULT_RAID_INTERVAL
