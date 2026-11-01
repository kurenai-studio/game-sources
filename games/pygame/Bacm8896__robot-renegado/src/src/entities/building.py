import math

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.core.audio_manager import audio
from src.entities import GameSprite
from src.entities.projectile import Projectile
from src.mechanics import combat
from src.ui import structure_art as art
from src.ui.combat_feedback import health_bar

G = C.BUILD_GRID

TURRETS = ("tower", "balista")        # tower = Torreta Ligera (Twin-Autocannon), balista = Torreta Pesada
# paleta (anillo de base y acentos) por aspecto de torreta: base Ligera roja, Pesada verde militar y cada ruta la suya
_KIND_PALETTE = {"tower": "light", "minigun": "light", "flame": "flame", "balista": "heavy", "railgun": "rail",
                 "tesla": "tesla"}
_WALL_PALETTE = {1: "ally", 2: "wall2", 3: "wall3"}
# Balance P1 · puntería de la Balista (base y Perforante): 1) Tanque; 2) Ariete de flanco o espalda (el frente
# reduce un 45%); 3) Soldado; 4) cualquier otro; un Ariete que solo ofrece el frente es la última opción, y si es lo
# único en rango la Balista no gasta el disparo.
_BALISTA_RANK = {"tank": 0, "ariete_flank": 1, "soldier": 2}


def _stats(kind, color):
    s = dict(U.BUILDINGS[kind])
    s.setdefault("range", 0)
    s.setdefault("damage", 0)
    s.setdefault("fire_rate", 0)
    s.setdefault("cores", 0)
    s["color"] = color
    return s


class Building(GameSprite):
    """Estructura del jugador: muro, torretas (Twin-Autocannon, Balista, Tesla, Lanzallamas), baluarte, Foco Vigía,
    Centro de Control y (subclases) red eléctrica y extractor. Todas las cifras salen de UNITS."""
    layer = 1
    casts_shadow = True
    recoil_t = 0.0                # 1 -> 0 en 0.1 s tras disparar: el cañón retrocede 3 px
    spin = 0.0                    # fase del tambor del Minigun (gira despacio en reposo y rápido al disparar)
    hp_floor = 0                  # vida mínima durante una prueba guiada de VULCANO (0: puede caer)
    self_defense = False          # Centro de Control en modo Comandante: cañón centinela integrado (lo activa la escena)
    fire_flash = 0.0              # segundos que quedan del destello de disparo (bobina del Railgun, boca del Minigun)
    STATS = {
        "tower": _stats("tower", C.MAGENTA),
        "balista": _stats("balista", C.ORANGE),
        "wall": _stats("wall", C.DARK_GRAY),
        "core": _stats("core", C.CYAN),
        "pylon": _stats("pylon", C.CYAN),
        "extractor": _stats("extractor", C.GREEN),
        "foco": _stats("foco", (180, 255, 120)),
        "fabrica": _stats("fabrica", (50, 180, 255)),
        "compuerta": _stats("compuerta", (150, 150, 200)),
        "bunker": _stats("bunker", (120, 200, 255)),
    }
    LABELS = {"tower": "Twin-Autocannon", "balista": "Balista", "wall": "Muro de Acero", "core": "Centro de Control",
              "pylon": "Pilón Repetidor", "extractor": "Extractor",
              "foco": "Foco Vigía", "fabrica": "Fábrica de Drones",
              "compuerta": "Compuerta Blindada", "bunker": "Búnker de Mando"}
    SHORT = {"tower": "Ligera", "balista": "Pesada", "wall": "Muro", "core": "Núcleo",
             "pylon": "Pilón", "extractor": "Extract.", "foco": "Foco", "fabrica": "Fábrica",
             "compuerta": "Compuerta", "bunker": "Búnker"}
    SIZES = {"tower": (G, G), "balista": (G, G), "wall": (G, G), "core": (64, 64),
             "pylon": (G, G), "extractor": (G, G), "foco": (G, G),
             "fabrica": (2 * G, 2 * G), "compuerta": (G, 2 * G),
             "bunker": (U.BUNKER["cells"] * G, U.BUNKER["cells"] * G)}
    # solo funcionan dentro del radio de un nodo energizado (el muro lo necesita únicamente al electrificarse)
    REQUIRES_POWER = TURRETS + ("extractor", "foco", "fabrica", "compuerta")
    repairable = True
    _destroyed = False                            # True tras kill(): ya no recibe daño ni vuelve a avisar
    art_style = None                              # "reactor": núcleo rediseñado del 1.3 (solo cambia el dibujo)

    def __init__(self, building_type, pos):
        super().__init__()
        self.building_type = building_type
        self.stats = Building.STATS[building_type]
        self.pos = Vector2(pos)
        self.hp = self.stats["hp"]
        self.max_hp = self.stats["hp"]
        self.energy_cost = self.stats["energy"]
        self.core_cost = self.stats["cores"]
        self.route = None                         # dual-build: "A" o "B" una vez elegida la ruta de mejora
        self.mode = building_type                 # comportamiento de la torreta: tower, balista, tesla o flame (rutas B)
        self.level = 1                            # muro: 1 base, 2 Reforzado, 3 Electrificado
        self.invested_scrap = self.stats["cost"]  # lo gastado en la estructura y sus mejoras (la venta devuelve el 70%)
        self.invested_cores = self.stats["cores"]
        self.cone = 0
        self.chain_range = 0
        self.stun_time = 0.0
        self.crowd_radius = 0
        self.ram_reduction = 0.0                  # muro Reforzado: reducción del impacto del Ariete
        self.counter_damage = 0                   # muro Electrificado: daño eléctrico a quien lo golpea cuerpo a cuerpo
        self.armor_pierce = 0                     # armadura plana que ignora (Minigun 4, Lanzallamas toda)
        self.range = self.stats["range"]
        self.damage = self.stats["damage"]
        self.fire_rate = self.stats["fire_rate"]
        self.pierce = self.stats.get("pierce", 1)
        self.jumps = self.stats.get("jumps", 0)
        self.splash = self.stats.get("splash", 0)               # balista explosiva: daño en área
        self.splash_radius = self.stats.get("splash_radius", 0)
        self.stun_slow = self.stats.get("stun_slow", 0.0)       # tesla: ralentización del aturdimiento
        self.energized = True                     # ¿hay energía en la red para esta torreta? (la fija la construcción)
        self._was_active = True
        self.build_order = 0                      # orden de construcción: sin energía se apagan primero las más nuevas
        self.fire_timer = 0
        self.angle = 0.0
        self.blink = 0.0
        self.flame = 0.0                          # tiempo que le queda al chorro del lanzallamas en pantalla
        self.arcs = []                            # arcos de la Tesla: [origen, destino, ttl]
        self.breaking = False                     # el muro se rompe: parpadeo rojo y luego se destruye
        self.break_timer = 0.0
        self.is_powered = not self.requires_power
        self.on_destroyed = None                  # callback(edificio) al ser destruido
        self.world = None                         # WorldRefs: lo fija la escena al registrarlo (focos, red)
        self.image = self._render()
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    @property
    def requires_power(self):
        return self.building_type in Building.REQUIRES_POWER or (self.building_type == "wall" and self.level >= 3)

    @property
    def active(self):
        """Operativa: conectada a la red (pilón/núcleo) Y con energía disponible."""
        return self.is_powered and self.energized

    @property
    def visual_kind(self):
        """Aspecto de la torreta: tower/minigun/flame (Ligera y sus rutas) o balista/railgun/tesla (Pesada y sus rutas)."""
        if self.building_type == "tower":
            return {"A": "minigun", "B": "flame"}.get(self.route, "tower")
        if self.building_type == "balista":
            return {"A": "railgun", "B": "tesla"}.get(self.route, "balista")
        return self.building_type

    @property
    def label(self):
        """Nombre actual: la ruta B de una torreta la convierte en Lanzallamas o Tesla."""
        if self.route is not None:
            return U.TURRET_ROUTES[self.building_type][self.route]["name"].title()
        return Building.LABELS[self.building_type]

    # --- mejoras del muro: Reforzado (nivel 2) y Electrificado (nivel 3) ---
    def wall_upgrade(self):
        """Especificación de la siguiente mejora del muro (dict de UNITS.WALL_LEVELS) o None."""
        if self.building_type != "wall":
            return None
        return U.WALL_LEVELS.get(self.level + 1)

    def apply_wall_level(self, level):
        spec = U.WALL_LEVELS[level]
        gain = spec["hp"] - self.max_hp
        self.max_hp = spec["hp"]
        self.hp = min(self.max_hp, self.hp + gain)                # la mejora añade la vida nueva (conserva el daño)
        self.level = level
        self.invested_scrap += spec["cost"]
        self.invested_cores += spec["cores"]
        self.energy_cost = spec["energy"]
        self.ram_reduction = spec.get("ram_reduction", self.ram_reduction)
        self.counter_damage = spec.get("counter_damage", 0)
        if level >= 3:
            self.is_powered = False                               # lo fija la red al recalcularse
        self.image = self._render()

    # --- dual-build (clic derecho sobre la torreta): una sola ruta, A o B ---
    def route_options(self):
        """[(clave, nombre, descripción, chatarra, núcleos)] de las rutas disponibles; [] si no tiene o ya la eligió."""
        if self.route is not None:
            return []
        return [(k, spec["name"], spec["desc"], spec["cost"], spec["cores"])
                for k, spec in U.TURRET_ROUTES.get(self.building_type, {}).items()]

    def choose_route(self, key):
        """Aplica la ruta (cambia su comportamiento). El cobro lo hace quien llama. Devuelve True si se aplicó."""
        spec = U.TURRET_ROUTES.get(self.building_type, {}).get(key)
        if spec is None or self.route is not None:
            return False
        for attr, value in spec["set"].items():
            setattr(self, attr, value)
        self.route = key
        self.energy_cost += spec.get("energy_extra", 0)
        self.invested_scrap += spec["cost"]
        self.invested_cores += spec["cores"]
        self.image = self._render()                               # la Tesla y el Lanzallamas cambian de aspecto
        return True

    @property
    def sell_value(self):
        return int(self.invested_scrap * C.SELL_REFUND)

    @property
    def core_refund(self):
        return int(self.invested_cores * C.SELL_REFUND)

    def linked_foco(self):
        """Foco Vigía operativo (con red Y energía) a menos de `range` px de esta torreta: la torreta está enlazada."""
        if self.world is None or self.building_type not in TURRETS:
            return None
        for f in self.world.focos:
            if f.alive() and f.active and f.pos.distance_to(self.pos) <= f.stats["range"]:
                return f
        return None

    def effective_range(self):
        """Alcance de la torreta: +30 px si está enlazada a un Foco Vigía operativo."""
        foco = self.linked_foco()
        return self.range + (foco.stats["range_bonus"] if foco is not None else 0)

    DETECT_HOLD = 0.4             # s que un Carroñero sigue marcado tras salir del radio del Foco (o apagarse este)

    def _detect_scavengers(self, targets_group):
        """Foco Vigía operativo: todo Carroñero a menos de `reveal_radius` px queda revelado y marcado como prioritario."""
        r2 = self.stats["reveal_radius"] ** 2
        for e in targets_group:
            if getattr(e, "is_scavenger", False) and e.alive() and self.pos.distance_squared_to(e.pos) <= r2:
                e.detected_timer = self.DETECT_HOLD

    # --- dibujo procedural: base estática cacheada (image) + capa dinámica en cada fotograma ---
    def _render(self):
        t, size = self.building_type, Building.SIZES[self.building_type]
        if t == "wall":
            return art.render_wall(size, _WALL_PALETTE[self.level], self.level)
        if t in TURRETS:
            return art.render_tower_base(size, _KIND_PALETTE[self.visual_kind])
        if t == "compuerta":
            return art.render_gate(size, getattr(self, "is_open", False))
        if t == "foco":
            return art.render_foco(size)
        if t == "bunker":
            return art.render_bunker(size)
        if self.art_style == "reactor":
            return art.render_reactor(size)
        return art.render_core(size)

    def use_reactor_art(self):
        """Reactor Central industrial (sub-acto 1.3): misma caja de 64x64 y mismo centro, solo cambia el dibujo."""
        self.art_style = "reactor"
        self.image = self._render()

    def draw_dynamic(self, surface, screen_rect, offset):
        """Cañón que gira hacia su objetivo, arcos de la Tesla, llamas, núcleo de energía pulsante y rotura del muro."""
        t, c = art.now(), screen_rect.center
        kind = self.building_type
        if kind == "bunker":
            art.draw_bunker_lamp(surface, screen_rect, t)
            return
        if kind in TURRETS:
            vk = self.visual_kind
            pal = _KIND_PALETTE[vk]
            if self.mode == "flame" and self.flame > 0:
                art.draw_flame(surface, c, self.angle, self.cone, self.effective_range(), t)
            hc = c
            if self.recoil_t > 0:                                     # retroceso del cañón (solo dibujo)
                a = math.radians(self.angle)
                hc = (c[0] - round(math.cos(a) * 3 * self.recoil_t), c[1] - round(math.sin(a) * 3 * self.recoil_t))
            art.draw_turret_head(surface, hc, self.angle, pal, self.active, t, vk, self.spin, self.fire_flash)
            for a, b, ttl in self.arcs:
                art.draw_arc(surface, Vector2(a) - offset, Vector2(b) - offset, t, (200, 190, 255), seed=int(a[0]))
        elif kind == "core":
            if self.art_style == "reactor":
                art.draw_reactor(surface, c, t, self.hp / self.max_hp)
            else:
                art.draw_energy_core(surface, c, "ally", t, 18)
        elif kind == "foco":
            art.draw_foco_sweep(surface, c, t, self.is_powered)
        elif kind == "wall":
            if self.breaking:
                art.draw_breaking(surface, screen_rect, self.break_timer / self.stats["break_time"],
                                  self.stats["break_blinks"])
            elif self.level >= 3 and self.active:
                art.draw_wall_sparks(surface, screen_rect, t, id(self) % 97)

    # --- vida ---
    def take_damage(self, amount, direction=None, attacker=None, ram=False):
        """Devuelve True si el golpe agota la vida. El muro no desaparece de golpe: parpadea en rojo 3 veces.
        `ram`: impacto de embestida (el muro Reforzado lo reduce); `attacker`: el muro Electrificado le devuelve
        20 de daño si es un Scout o un Soldado que lo golpea cuerpo a cuerpo."""
        if self.breaking or self._destroyed:                      # ya destruido: no recibe más daño
            return False
        if ram and self.ram_reduction:
            amount *= 1.0 - self.ram_reduction
        if (attacker is not None and self.counter_damage and self.active and attacker.alive()
                and getattr(attacker, "enemy_type", "") in ("scout", "soldier")
                and getattr(attacker, "counter_timer", 0.0) <= 0):          # la descarga: 1 vez por segundo y atacante
            attacker.counter_timer = 1.0
            attacker.take_damage(self.counter_damage, attacker.pos - self.pos)
            combat.FX.spark(attacker.pos, (255, 235, 90))
        if self.hp_floor > 0:                                         # prueba guiada de VULCANO: nada cae del todo
            amount = max(0.0, min(amount, self.hp - self.hp_floor))
        self.hp -= amount
        self.flash()
        if self.hp <= 0:
            if self.building_type == "wall":
                self.hp = 0
                combat.FX.crumble(self.rect)                          # destello rojo y grietas donde estaba el muro
            self.kill()                                               # desaparece ya: ni bloquea ni recibe más golpes
            return True
        return False

    def kill(self):
        was_alive = self.alive()
        self._destroyed = True
        super().kill()
        if was_alive:
            if self.building_type == "wall":
                combat.FX.debris(self.pos, (104, 112, 132), 10)       # el muro se desmorona en escombros
            else:
                combat.FX.blast(self.pos, 48, (255, 70, 50))          # onda roja: se ve dónde cayó la estructura
            combat.FX.request_shake()             # cae un edificio: tiembla la pantalla
            if self.on_destroyed:
                self.on_destroyed(self)

    def dismantle(self):
        """Desmontaje voluntario (venta): sin temblor ni eventos de destrucción."""
        self.on_destroyed = None
        pygame.sprite.Sprite.kill(self)

    def repair(self, amount):
        if self.breaking:
            return
        self.hp = min(self.max_hp, self.hp + amount)

    def collect_income(self):
        return 0

    # --- torretas ---
    def _targets_in_range(self, enemies_group):
        rng = self.effective_range()
        r2 = rng * rng
        return [e for e in enemies_group if e.alive() and self.pos.distance_squared_to(e.pos) <= r2]

    def _core_defense(self, enemies_group, bullets_group):
        """Cañón centinela de pulso ligero del Centro de Control: dispara al enemigo más cercano dentro de su corto
        alcance (Scouts y Carroñeros que se cuelan hasta el núcleo). No gasta energía."""
        if self.fire_timer > 0 or bullets_group is None:
            return
        st = U.BUILDINGS["core"]
        r2 = st["defense_range"] ** 2
        cands = [e for e in enemies_group if e.alive() and self.pos.distance_squared_to(e.pos) <= r2]
        if not cands:
            return
        target = min(cands, key=lambda e: self.pos.distance_squared_to(e.pos))
        direction = target.pos - self.pos
        if direction.length_squared() == 0:
            return
        life = st["defense_range"] * 1.25 / st["defense_bullet_speed"]
        bullets_group.add(Projectile(self.pos, direction, st["defense_damage"], "tower", lifetime=life,
                                     speed=st["defense_bullet_speed"]))
        self.fire_timer = st["defense_fire_rate"]
        self.fire_flash = 0.08
        audio.play("core_shot")

    def _turret_logic(self, dt, enemies_group, bullets_group):
        cands = self._targets_in_range(enemies_group)
        if not cands:
            return
        kind = self.mode

        def d2(e):
            return self.pos.distance_squared_to(e.pos)
        marked = [e for e in cands if getattr(e, "detected", False)] if self.linked_foco() is not None else []
        if marked:                                                # Foco Vigía: los Carroñeros detectados van primero
            target = min(marked, key=d2)
        elif kind == "tower":                                     # Twin-Autocannon: Scouts primero, luego el más cercano
            target = min(cands, key=lambda e: (0 if getattr(e, "enemy_type", "") == "scout" else 1, d2(e)))
        elif kind == "balista":                                   # Balista: Tanques y Arietes de flanco (ver _BALISTA_RANK)
            target = min(cands, key=lambda e: (self._balista_rank(e), d2(e)))
            if self._balista_rank(target) >= 9:                   # solo queda un Ariete de frente: no malgasta el tiro
                self.angle = math.degrees(math.atan2(target.pos.y - self.pos.y, target.pos.x - self.pos.x))
                return
        elif kind == "tesla":                                     # Tesla: el centro del grupo más aglomerado
            crowd = self.crowd_radius
            target = min(cands, key=lambda e: (-sum(1 for o in cands if o.pos.distance_squared_to(e.pos) <= crowd ** 2), d2(e)))
        else:
            target = min(cands, key=d2)
        direction = target.pos - self.pos
        if direction.length_squared() == 0:
            return
        self.angle = math.degrees(math.atan2(direction.y, direction.x))
        if self.fire_timer > 0:
            return
        if kind == "tower":
            life = self.effective_range() * 1.25 / self.stats["bullet_speed"]
            bullets_group.add(Projectile(self.pos, direction, self.damage, "tower",
                                         lifetime=life, speed=self.stats["bullet_speed"], armor_pierce=self.armor_pierce))
        elif kind == "balista":
            life = self.effective_range() * 1.25 / self.stats["bullet_speed"]
            bullets_group.add(Projectile(self.pos, direction, self.damage, "balista", lifetime=life,
                                         speed=self.stats["bullet_speed"], pierce=self.pierce, radius=6,
                                         splash=self.splash, splash_radius=self.splash_radius))
        elif kind == "tesla":
            self._tesla_arc(target, cands)
        else:
            self._flame_tick(cands)
        self.fire_timer = self.fire_rate
        self.fire_flash = 0.3
        if kind in ("tower", "balista"):
            self.recoil_t = 1.0

    def _balista_rank(self, e):
        """Prioridad de la Balista (menor = antes). Un Ariete de frente vale 9: solo si no hay nada más."""
        kind = getattr(e, "enemy_type", "")
        if kind == "ariete":
            return 9 if e.is_frontal(e.pos - self.pos) else _BALISTA_RANK["ariete_flank"]
        return _BALISTA_RANK.get(kind, 3)

    def _tesla_arc(self, primary, cands):
        """Arco que salta entre `jumps` enemigos cercanos: daño a cada uno y aturdimiento (-40% movimiento 0.3 s)."""
        chain, last = [primary], primary
        pool = [e for e in cands if e is not primary]
        while len(chain) < self.jumps and pool:
            nxt = min(pool, key=lambda e: last.pos.distance_squared_to(e.pos))
            if last.pos.distance_to(nxt.pos) > self.chain_range:
                break
            chain.append(nxt)
            pool.remove(nxt)
            last = nxt
        origin = Vector2(self.pos)
        self.arcs = []
        for victim in chain:
            victim.take_damage(self.damage, victim.pos - origin)
            if hasattr(victim, "apply_slow"):
                victim.apply_slow(self.stun_time, self.stun_slow)
            self.arcs.append([tuple(origin), tuple(victim.pos), 0.18])
            combat.FX.spark(victim.pos, (200, 190, 255))
            origin = Vector2(victim.pos)

    def _flame_tick(self, cands):
        """Daño continuo en un sector frente a la torreta (damage = daño por segundo)."""
        tick = self.damage * self.fire_rate
        face = Vector2(1, 0).rotate(self.angle)
        half = self.cone / 2
        self.flame = 0.18
        for e in cands:
            to = e.pos - self.pos
            if to.length_squared() > 0:
                off = abs(face.angle_to(to))
                if min(off, 360 - off) <= half:
                    if hasattr(e, "armor"):                           # daño elemental: ignora la armadura plana
                        e.take_damage(tick, to, armor_pierce=self.armor_pierce)
                    else:
                        e.take_damage(tick, to)

    # --- logica ---
    def update(self, dt, enemies_group, bullets_group):
        self.fire_timer -= dt
        self.blink += dt
        if self.breaking:                                         # cuenta atrás de la rotura del muro
            self.break_timer -= dt
            if self.break_timer <= 0:
                self.kill()
            return
        if self.recoil_t > 0:
            self.recoil_t = max(0.0, self.recoil_t - dt / 0.1)
        if self.fire_flash > 0:
            self.fire_flash = max(0.0, self.fire_flash - dt)
        if self.self_defense and self.building_type == "core":
            self._core_defense(enemies_group, bullets_group)
        if self.building_type in TURRETS and self.active:
            self.spin += dt * (22.0 if self.fire_flash > 0 else 0.8)         # tambor: lento en reposo, rápido al disparar
        if self.flame > 0:
            self.flame -= dt
        if self.arcs:
            self.arcs = [[a, b, ttl - dt] for a, b, ttl in self.arcs if ttl - dt > 0]
        if self.building_type == "foco" and self.active:
            self._detect_scavengers(enemies_group)               # detección temprana de Carroñeros
        if self.building_type in TURRETS:
            act = self.active
            if self._was_active and not act:                      # se apaga (sin red o sin energía): chispas rojas
                for _ in range(2):
                    combat.FX.spark(self.pos, C.RED)
            self._was_active = act
            if act:
                self._turret_logic(dt, enemies_group, bullets_group)
        self.rect.center = (round(self.pos.x), round(self.pos.y))

    def draw_overlay(self, surface, screen_rect, offset):
        self.draw_dynamic(surface, screen_rect, offset)
        if self.hp < self.max_hp:
            health_bar(surface, self, pygame.Rect(screen_rect.left, screen_rect.top - 9, screen_rect.w, 5),
                       self.hp / self.max_hp)
        if self.requires_power:
            if self.active:                                                                      # LED cian: operativa
                if int(self.blink * 1.6) % 2 == 0:
                    pygame.draw.circle(surface, (0, 235, 255), (screen_rect.right - 5, screen_rect.top + 5), 3)
            elif int(self.blink * 2.5) % 2 == 0:
                draw_empty_battery(surface, (screen_rect.centerx, screen_rect.top - 8))         # sin energía


class Compuerta(Building):
    """Compuerta Blindada (1x2 celdas, 1 de energía, conectada a la red). Con energía se abre sola ante un aliado (dron,
    V.U.L.C.A.N.O. u Operador) y se cierra `auto_close_delay` s después de que pase; bloquea siempre a los enemigos, que
    deben destruirla. Sin energía (corte de red, sabotaje de un pilón o red saturada) queda CONGELADA CERRADA: sólida
    para aliados y enemigos hasta que vuelva la red."""

    @property
    def ally_passable(self):
        """Player._resolve_collisions la franquea solo si hay energía; sin ella es un muro sólido para todos."""
        return self.active

    def __init__(self, pos, y=None):
        super().__init__("compuerta", (pos, y) if y is not None else pos)
        self.is_open = False
        self.open_timer = 0.0
        self.auto_close_delay = self.stats["auto_close_delay"]
        self.image = self._render()

    @property
    def health(self):
        return self.hp

    @property
    def max_health(self):
        return self.max_hp

    def check_collision(self, entity):
        """¿Puede pasar `entity`? Sin energía, nadie (congelada cerrada). Con energía: los aliados (y la abren); los
        enemigos nunca."""
        if not self.active:
            return False
        if getattr(entity, "is_ally", False):
            self.open()
            return True
        return not hasattr(entity, "enemy_type")

    def open(self):
        if not self.active:
            return                                            # sin energía no se abre
        if not self.is_open:
            self.is_open = True
            self.image = self._render()
        self.open_timer = self.auto_close_delay

    def _freeze_closed(self):
        if self.is_open:
            self.is_open = False
            self.image = self._render()
        self.open_timer = 0.0

    def update(self, dt, enemies_group=None, bullets_group=None):
        super().update(dt, enemies_group or (), bullets_group or ())
        if not self.active:                                   # corte de energía: congelada cerrada
            self._freeze_closed()
            return
        self._sense_allies()
        if self.is_open:
            self.open_timer -= dt
            if self.open_timer <= 0:
                self.is_open = False
                self.image = self._render()

    def _sense_allies(self):
        """Sensor: un dron aliado, V.U.L.C.A.N.O. o el Operador a menos de `open_range` px la abre."""
        w = self.world
        if w is None:
            return
        r2 = self.stats["open_range"] ** 2
        allies = ([w.player] if w.player is not None and w.player.alive() else []) + list(w.drones)
        if getattr(w, "vulcano", None) is not None:
            allies.append(w.vulcano)
        if any(a.alive() and self.pos.distance_squared_to(a.pos) <= r2 for a in allies):
            self.open()

    def draw_dynamic(self, surface, screen_rect, offset):
        art.draw_gate_lights(surface, screen_rect, self.is_open, art.now())


def create_building(building_type, pos, **kwargs):
    """Fábrica: los tipos con lógica propia viven en power.py y resource_node.py."""
    if building_type == "pylon":
        from src.entities.power import PowerPylon
        return PowerPylon(pos)
    if building_type == "extractor":
        from src.entities.resource_node import Extractor
        return Extractor(pos, kwargs["deposit"])
    if building_type == "fabrica":
        from src.entities.factory import Factory
        return Factory(pos)
    if building_type == "compuerta":
        return Compuerta(pos)
    return Building(building_type, pos)


def draw_empty_battery(surface, center, size=1):
    """Icono de batería vacía en rojo: la estructura no tiene energía."""
    cx, cy = round(center[0]), round(center[1])
    body = pygame.Rect(0, 0, 18, 10)
    body.center = (cx, cy)
    pygame.draw.rect(surface, (30, 6, 10), body)
    pygame.draw.rect(surface, C.RED, body, 2)
    pygame.draw.rect(surface, C.RED, (body.right, cy - 2, 2, 4))
    pygame.draw.rect(surface, C.RED, (body.x + 2, body.y + 2, 2, 6))        # un último rayita de carga


# Menu de construccion: tecla -> tipo de edificio (reducido en la Biblia 4.0: 2 torretas base y las estructuras de la red)
BUILD_MENU = [(pygame.K_1, "wall"), (pygame.K_2, "tower"), (pygame.K_3, "balista"), (pygame.K_4, "pylon"),
              (pygame.K_5, "extractor"), (pygame.K_6, "foco"), (pygame.K_7, "fabrica"), (pygame.K_8, "compuerta")]
# Tipos de estructura que ya no existen y en qué se convierten al cargar una base guardada (el Generador era otra fuente
# de red: hoy esa función es solo del Pilón).
LEGACY_STRUCTURES = {"generator": "pylon", "generador": "pylon"}
