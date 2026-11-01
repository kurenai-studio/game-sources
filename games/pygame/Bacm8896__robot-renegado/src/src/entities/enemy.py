import itertools
import math
import random

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.core.asset_manager import assets
from src.entities import GameSprite
from src.entities.projectile import Projectile, Shell
from src.mechanics import combat

_SIZES = {kind: base["size"] for kind, base in U.ENEMIES.items()}       # hitbox (px)
from src.ui import entity_art
from src.ui.combat_feedback import health_bar

_COLORS = {"scout": C.CYAN, "soldier": C.MAGENTA, "tank": C.RED, "ariete": C.ORANGE}
_image_cache = {}

# Sprites PNG (miran a la derecha = ángulo 0); lado del lienzo en pantalla. El hitbox sigue siendo _SIZES.
SPRITE_FILES = {"scout": "entities/scout.png", "soldier": "entities/soldier.png",
                "tank": "entities/tank.png", "ariete": "entities/ariete.png"}
SPRITE_SIZES = {k: U.scaled(v) for k, v in {"scout": 52, "soldier": 64, "tank": 88, "ariete": 96}.items()}   # x0,83
ROT_STEP = 6                                     # grados por paso de la caché de giros
TURN_RATE = 9.0                                  # suavizado del giro (1/s)
BLOCK_DOT = 0.1                                  # una estructura tocada con dot(rumbo) mayor que esto les bloquea el paso
_rot_cache = {}
_white_cache = {}


def _sprite(enemy_type, angle):
    """Sprite girado hacia `angle` (grados, sentido horario en pantalla) o None si falta el PNG."""
    size = SPRITE_SIZES[enemy_type]
    base = assets.scaled(SPRITE_FILES[enemy_type], (size, size))
    if base is None:
        return None
    step = round(angle / ROT_STEP) % (360 // ROT_STEP)
    key = (enemy_type, step)
    img = _rot_cache.get(key)
    if img is None:
        img = pygame.transform.rotate(base, -step * ROT_STEP)
        _rot_cache[key] = img
    return img, key


def _white(key, img):
    if key not in _white_cache:
        _white_cache[key] = pygame.mask.from_surface(img).to_surface(setcolor=(255, 255, 255, 255),
                                                                      unsetcolor=(0, 0, 0, 0))
    return _white_cache[key]


def _build_image(enemy_type, color):
    if enemy_type not in _image_cache:
        s = _SIZES[enemy_type]
        if enemy_type == "ariete":                   # respaldo procedural: chasis blindado, orugas, escudo y reactor
            _image_cache[enemy_type] = entity_art.render_ariete(s)
            return _image_cache[enemy_type]
        img = pygame.Surface((s, s), pygame.SRCALPHA)
        pygame.draw.rect(img, tuple(c // 5 for c in color), img.get_rect())
        pygame.draw.rect(img, color, img.get_rect(), 2)
        core = max(4, s // 4)
        pygame.draw.rect(img, color, (s // 2 - core // 2, s // 2 - core // 2, core, core))
        _image_cache[enemy_type] = img
    return _image_cache[enemy_type]


def roll_drop(enemy_type, rng=random):
    """Chatarra que suelta un enemigo al morir (0 si no suelta): probabilidad y rango según UNITS.ENEMY_DROPS."""
    drops = U.ENEMY_DROPS[enemy_type]
    if rng.random() >= drops["scrap_chance"]:
        return 0
    return rng.randint(*drops["scrap"])


def roll_core_drop(enemy_type, rng=random):
    """Núcleos de Plasma que suelta (Ariete: 1, Tanque: 2, ambos con un 50%); 0 para el resto."""
    drops = U.ENEMY_DROPS[enemy_type]
    if not drops["cores"] or rng.random() >= drops["core_chance"]:
        return 0
    return rng.randint(*drops["cores"])


def ammo_drop_chance(enemy_type):
    return U.ENEMY_DROPS[enemy_type]["ammo_prob"]


def _legacy_stats(kind):
    base = U.ENEMIES[kind]
    return {"hp": base["hp"], "speed": base["speed"], "damage": base["melee_dps"] * base["attack_cooldown"],
            "color": _COLORS[kind]}


class Enemy(GameSprite):
    """Renegado que avanza hacia target_pos, ataca lo que le bloquea el paso y, según su tipo:
    scout (enjambre que rodea), soldado (se detiene a rango y dispara ráfagas), tanque (bombardea con obuses)
    y ariete (blindaje frontal, carga contra estructuras en línea recta)."""
    layer = 2
    casts_shadow = True
    SCOUT = _legacy_stats("scout")
    SOLDIER = _legacy_stats("soldier")
    TANK = _legacy_stats("tank")
    ARIETE = _legacy_stats("ariete")

    def __init__(self, enemy_type, start_pos, target_pos, enemies_group):
        super().__init__()
        self.pos = Vector2(start_pos)
        self.enemy_type = enemy_type                 # "scout" | "soldier" | "tank" | "ariete"
        self.stats = getattr(Enemy, enemy_type.upper())
        base = U.ENEMIES[enemy_type]
        self.base = base
        self.hp = self.max_hp = base["hp"]
        self.armor = base.get("armor", 0)             # armadura plana: se resta del daño de cada impacto
        self.speed = base["speed"]
        self.attack_cooldown = base["attack_cooldown"]
        self.damage = base["melee_dps"] * base["attack_cooldown"]      # daño por contacto
        self.power = 1.0                              # multiplicador de ataque (escala de las incursiones)
        self.target_pos = Vector2(target_pos)
        self.enemies_group = enemies_group           # para repulsion
        self.attack_timer = 0
        self.image = _build_image(enemy_type, self.stats["color"])
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))
        self.facing = 0.0                             # ángulo de giro del sprite (grados)
        self.chasing = False                          # lo usa el Acto 1 (guardianes)
        self.straight = False                         # patrulla: va en línea recta a su punto (sin campo de flujo)
        self.own_nav = None                           # asedio: campo de flujo propio (marchas dirigidas a un pilón)
        self.always_active = False                    # los enemigos de oleada atacan sin necesitar "despertar"
        self.sight = C.AGGRO_RADIUS * 0.8             # a qué distancia ve al jugador (con línea de visión)
        self.dead = False
        self.on_death = None                          # callback(enemy) al morir
        self.world = None                             # WorldRefs: lo fijan quienes los generan (disparos, cargas)
        self.carries_part = False                     # portador de una pieza del chasis de AURA (marcado en pantalla)
        self.is_evacuation = False                    # dotación que huye de una base caída: no cuenta para las oleadas
        self.counter_timer = 0.0                      # muro Electrificado: su descarga golpea como mucho 1 vez por segundo
        self.aim_timer = 0.0                          # Tanque: segundos que le quedan apuntando antes de disparar
        self.aim_point = None                         # Tanque: punto de impacto fijado al empezar a apuntar
        self.strafe_side = random.choice((-1, 1))     # Soldado: hacia qué lado se desplaza en la pausa entre ráfagas
        self.vulnerability = 1.0                      # multiplicador del daño recibido (cobertura del sub-acto 1.4)
        self.slow_timer = 0.0                         # aturdimiento de la Tesla (-40% de movimiento)
        self.slow_factor = 0.0
        self.flank = random.choice((-1, 1)) if enemy_type == "scout" else 0
        self.flank_jitter = random.uniform(0.6, 1.4)   # cada Scout rodea con su propio ángulo: el enjambre se abre en abanico
        # armas a distancia
        self.shoot_timer = random.uniform(0.0, 0.8)
        self.burst_left = 0
        self.burst_timer = 0.0
        self.aim = None
        self.aim_check = random.uniform(0.0, 0.25)
        # ariete
        self.state = "march"                          # march -> windup -> charge -> recover
        self.state_timer = random.uniform(0.0, 0.3)
        self.charge_dir = Vector2(1, 0)
        self.traveled = 0.0
        self.hit_units = False
        self._blocker = None                          # estructura que me frenó en el último choque
        self._blocker_age = 9.0
        self._has_los = True                          # ¿recta libre hasta su objetivo? (si no, sigue el campo de flujo)
        self._guided = False                          # ¿lo guía un campo de flujo? (si no, bordea los muros por su cuenta)
        self._stuck_t = 0.0                           # ventana de vigilancia del atasco (s)
        self._stuck_want = 0.0                        # px que intentó avanzar en la ventana
        self._stuck_anchor = Vector2(self.pos)        # dónde empezó la ventana
        self._unstick_t = 0.0                         # s que le quedan de desvío sostenido
        self._unstick_dir = Vector2()
        self._unstick_side = 0                        # lado del último desvío (se repite si vuelve a atascarse enseguida)
        self._unstick_streak = 0                      # desvíos seguidos: cada uno dura más
        self._since_unstick = 99.0

    @property
    def active(self):
        return self.always_active or self.chasing

    # --- daño -----------------------------------------------------------------------------------------
    def facing_vector(self):
        return Vector2(math.cos(math.radians(self.facing)), math.sin(math.radians(self.facing)))

    def is_frontal(self, direction):
        """¿Un ataque que viaja en `direction` le da en el frente blindado? (solo el Ariete tiene frente)."""
        if self.enemy_type != "ariete" or direction is None or Vector2(direction).length_squared() == 0:
            return False
        dot = Vector2(direction).normalize().dot(self.facing_vector())
        return dot <= -math.cos(math.radians(self.base["front_arc"]))

    def mitigate(self, amount, direction=None, armor_pierce=0):
        """Daño final: el Ariete reduce un 45% lo que llega de frente y recibe x3 por detrás o de costado;
        la armadura plana se resta después (mínimo 1 de daño)."""
        if self.enemy_type == "ariete" and direction is not None and Vector2(direction).length_squared() > 0:
            if self.is_frontal(direction):                                   # el golpe viene de su frente
                amount *= 1.0 - self.base["front_reduction"]
            else:                                                            # espalda o costado: punto débil
                amount *= self.base["weak_mult"]
        armor = max(0, self.armor - armor_pierce)                            # Minigun perfora 4; el Lanzallamas, toda
        if armor > 0:
            amount = max(1.0, amount - armor)
        return amount

    def take_damage(self, amount, direction=None, armor_pierce=0):
        """`direction` = velocidad del proyectil (o del atacante al objetivo). Devuelve True si el golpe lo mata."""
        if self.dead:
            return False
        self.hp -= self.mitigate(amount, direction, armor_pierce) * self.vulnerability
        self.flash()
        if self.hp <= 0:
            self.dead = True
            self.kill()
            if self.on_death:
                self.on_death(self)
            return True
        return False

    def _evacuated(self):
        """Evacuado que ya llegó a su punto de salida o abandonó el mapa."""
        if self.pos.distance_to(self.target_pos) <= 24:
            return True
        bounds = getattr(self.world, "bounds", None)
        return bounds is not None and not bounds.inflate(60, 60).collidepoint(self.pos)

    def apply_slow(self, seconds, factor=None):
        """Aturdimiento de la Tesla: -`factor` de movimiento durante `seconds` (por defecto el de la Tesla base)."""
        self.slow_timer = max(self.slow_timer, seconds)
        self.slow_factor = max(self.slow_factor, U.TURRET_ROUTES["balista"]["B"]["set"]["stun_slow"] if factor is None else factor)

    # --- movimiento --------------------------------------------------------------------------------------
    def _heading(self, nav):
        """Dirección de avance: campo de flujo (rodea muros si hay hueco) o línea recta. Los evacuados van en línea recta
        a su salida (el campo de flujo lleva al Centro de Control del jugador)."""
        if nav is not None and not self.is_evacuation and not self.straight:
            self._guided = True                                           # el campo de flujo ya rodea los muros
            heading, self._has_los = nav.route(self.pos, self.target_pos, self.rect.w * 0.71 + 2,   # caja cuadrada: radio
                                               U.ENEMY_STEERING["lookahead"])                      # circunscrito
            return heading
        self._has_los, self._guided = True, False
        to_target = self.target_pos - self.pos
        return to_target.normalize() if to_target.length_squared() > 1 else Vector2()

    def _turn_towards(self, target, dt, max_rate=None):
        """Gira el cuerpo hacia `target` (grados). Con `max_rate` (o un `turn_rate` en UNITS, como el Tanque) el giro está
        limitado a esos grados por segundo; si no, se suaviza (TURN_RATE)."""
        diff = (target - self.facing + 180) % 360 - 180
        rate = max_rate if max_rate is not None else self.base.get("turn_rate")
        if rate is not None:
            step = rate * dt
            self.facing = (self.facing + max(-step, min(step, diff))) % 360
        else:
            self.facing = (self.facing + diff * min(1.0, TURN_RATE * dt)) % 360

    def angle_to(self, point):
        """Grados (con signo) que le faltan al cuerpo para mirar a `point`."""
        to = Vector2(point) - self.pos
        if to.length_squared() == 0:
            return 0.0
        return (math.degrees(math.atan2(to.y, to.x)) - self.facing + 180) % 360 - 180

    @property
    def contact_continuous(self):
        """¿Su daño de contacto es continuo (melee_dps * dt) en vez de un golpe por segundo? (el Scout)."""
        return self.base.get("contact") == "continuous"

    def contact_damage(self, dt=None):
        """Daño de contacto de este fotograma: continuo (dps * dt) si hay dt y el tipo lo pide; si no, un golpe."""
        if dt is not None and self.contact_continuous:
            return self.base["melee_dps"] * dt
        return self.damage

    def _hunting_player(self):
        """¿Va a por el Operador (su objetivo es la posición del jugador)? Si no, su objetivo es una estructura."""
        w = self.world
        p = getattr(w, "player", None) if w is not None else None
        return p is not None and p.alive() and p.pos.distance_to(self.target_pos) < 40

    def _orbit_side(self):
        """Hacia qué lado rodea: hacia la espalda del Operador si va a por él (mira hacia donde apunta); si no, su lado."""
        w = self.world
        p = getattr(w, "player", None) if w is not None else None
        if self._hunting_player():
            back = p.pos - Vector2(p.aim_dir) * 60
            to_t, to_back = self.target_pos - self.pos, back - self.pos
            cross = to_t.x * to_back.y - to_t.y * to_back.x
            if abs(cross) > 1e-6:
                return 1 if cross > 0 else -1
        return self.flank

    def _flank(self, heading):
        """Scouts: lejos se acercan con un leve desvío; en rango medio añaden una componente tangencial que los hace rodear
        y entrar por el costado o la espalda; cerca van directos a morder. `flank = 0`: sin flanqueo (línea recta)."""
        if heading.length_squared() == 0 or self.flank == 0 or not self._has_los:
            return heading                                               # sin línea de visión: sigue el flujo, sin rodear
        b = self.base
        dist = self.pos.distance_to(self.target_pos)
        if dist <= b["flank_close"]:
            return heading
        if dist >= b["flank_far"]:
            return heading.rotate(b["flank_angle"] * self.flank * self.flank_jitter)
        t = (dist - b["flank_close"]) / (b["flank_far"] - b["flank_close"])
        strength = b["orbit_strength"] if self._hunting_player() else b["orbit_strength_structures"]
        weight = math.sin(math.pi * t) * strength * self.flank_jitter   # máximo a media distancia
        side = self._orbit_side()
        tangent = Vector2(-heading.y, heading.x) * side
        out = heading + tangent * weight
        return out.normalize() if out.length_squared() > 0 else heading

    def _reposition(self, speed):
        """Soldado en la pausa entre ráfagas: se aparta si lo tienen encima, se acerca si se le escapa y, si no, se desplaza
        de lado (orbita) para no ser un blanco fijo. Devuelve (rumbo, velocidad)."""
        b = self.base
        to = self.aim.pos - self.pos
        d = to.length()
        if d < 1:
            return Vector2(), 0.0
        radial = to / d
        tangent = Vector2(-radial.y, radial.x) * self.strafe_side
        if d < b["range"] * b["keep_min"]:
            heading = (tangent * 0.8 - radial).normalize()               # mantiene la distancia
        elif d > b["range"] * 0.95:
            heading = radial                                             # vuelve a entrar en alcance
        else:
            heading = tangent
        return heading, speed * b["reposition_speed"]

    @staticmethod
    def _wall_rects(solids, obstacles_group, area):
        """Muros de nivel (no estructuras del jugador) que tocan `area`."""
        return [s.rect for s in solids if area.colliderect(s.rect)
                and not (obstacles_group is not None and s in obstacles_group)]

    def _ray_hit(self, direction, length, walls):
        """Fracción (0-1] del rayo a la que toca un muro, o None si está libre."""
        for frac in (0.35, 0.7, 1.0):
            p = self.pos + direction * (length * frac)
            if any(r.collidepoint(p.x, p.y) for r in walls):
                return frac
        return None

    def _whiskers(self, heading, solids, obstacles_group):
        """Sensores de anticipación: rayos a ±30° del rumbo. Si uno detecta un muro inminente y el otro no, gira suavemente
        hacia el lado libre para bordear la esquina antes del choque frontal."""
        st = U.ENEMY_STEERING
        length = self.rect.w / 2 + st["whisker_len"]
        walls = self._wall_rects(solids, obstacles_group, self.rect.inflate(2 * length, 2 * length))
        if not walls:
            return heading
        ang = st["whisker_angle"]
        left = self._ray_hit(heading.rotate(-ang), length, walls)
        right = self._ray_hit(heading.rotate(ang), length, walls)
        if (left is None) == (right is None):
            return heading                                        # ambos libres, o pasillo: la colisión desliza
        near = left if left is not None else right
        turn = st["whisker_turn"] * (2.0 if near <= 0.5 else 1.0)
        return heading.rotate(turn if left is not None else -turn)

    def _nearest_wall_normal(self, solids, obstacles_group, margin=6):
        """Normal (hacia fuera) del muro de nivel más cercano a menos de `margin` px del cuerpo, o None."""
        reach = self.rect.w / 2 + margin
        best, best_d = None, reach
        for r in self._wall_rects(solids, obstacles_group, self.rect.inflate(2 * margin + 2, 2 * margin + 2)):
            d = Vector2(self.pos.x - max(r.left, min(self.pos.x, r.right)), self.pos.y - max(r.top, min(self.pos.y, r.bottom)))
            dist = d.length()
            if 1e-6 < dist < best_d:
                best, best_d = d / dist, dist
        return best

    def _follow_wall(self, heading, solids, obstacles_group):
        """Desvío sostenido: arranca a 45-90° del rumbo y, mientras toque muro, lo bordea siempre por el mismo lado
        (tangente que sigue el sentido del desvío). Termina en cuanto el rumbo al objetivo ya no empuja contra la pared."""
        n = self._nearest_wall_normal(solids, obstacles_group)
        if n is None:
            return Vector2(self._unstick_dir)
        if heading.dot(n) >= -0.05:
            self._unstick_t = 0.0                                          # vía libre hacia el objetivo: se acabó
            return heading
        tangent = Vector2(-n.y, n.x)
        if tangent.dot(self._unstick_dir) < 0:
            tangent = -tangent
        self._unstick_dir = tangent                                        # en las esquinas la tangente gira con el muro
        return tangent

    def _start_follow(self, n):
        """Empieza a bordear el muro de normal `n`: por el lado del objetivo, o por el mismo que la última vez si acaba
        de bordear (no rebota de un lado a otro en el centro de la pared)."""
        tangent = Vector2(-n.y, n.x)
        if self._since_unstick < 2.0 and self._unstick_side != 0:
            side = self._unstick_side
        else:
            side = 1 if tangent.dot(self.target_pos - self.pos) >= 0 else -1
        self._unstick_side = side
        self._unstick_dir = tangent * side
        self._unstick_t = U.ENEMY_STEERING["unstick_time"] * 4
        self._since_unstick = 0.0

    def _push_out(self, rect, radius):
        """Vector que saca el círculo del enemigo del rectángulo (None si no se tocan): normal del punto de contacto."""
        cx = max(rect.left, min(self.pos.x, rect.right))
        cy = max(rect.top, min(self.pos.y, rect.bottom))
        d = Vector2(self.pos.x - cx, self.pos.y - cy)
        dist2 = d.length_squared()
        if dist2 >= radius * radius:
            return None
        if dist2 > 1e-12:
            dist = math.sqrt(dist2)
            return d / dist * (radius - dist)
        gaps = {"l": self.pos.x - rect.left, "r": rect.right - self.pos.x, "t": self.pos.y - rect.top, "b": rect.bottom - self.pos.y}
        side = min(gaps, key=gaps.get)
        return {"l": Vector2(-(gaps["l"] + radius), 0), "r": Vector2(gaps["r"] + radius, 0),
                "t": Vector2(0, -(gaps["t"] + radius)), "b": Vector2(0, gaps["b"] + radius)}[side]

    def _slide_walls(self, solids, obstacles_group):
        """Proyección tangencial: tras moverse, sale de los muros por la normal del contacto. Lo que avanzó a lo largo de
        la pared se conserva (fricción tangencial cero), así que desliza hacia el espacio libre en vez de clavarse."""
        radius = self.rect.w / 2
        for _ in range(3):                                        # una esquina interior puede pedir dos empujes
            self.rect.center = (round(self.pos.x), round(self.pos.y))
            pushed = False
            for r in self._wall_rects(solids, obstacles_group, self.rect.inflate(2, 2)):
                push = self._push_out(r, radius)
                if push is not None:
                    self.pos += push
                    pushed = True
            if not pushed:
                break
        self.rect.center = (round(self.pos.x), round(self.pos.y))

    def _side_towards_target(self, normal):
        """Tangente a la pared (de las dos) que le acerca a su objetivo."""
        t1 = Vector2(-normal.y, normal.x)
        to = self.target_pos - self.pos
        return t1 if t1.dot(to) >= 0 else -t1

    def _repulsion(self):
        """Empuje hacia afuera si otro enemigo esta demasiado cerca (px/s)."""
        push = Vector2()
        for other in self.enemies_group:
            if other is self:
                continue
            offset = self.pos - other.pos
            distance = offset.length()
            # 30 px como minimo; los enemigos grandes piden mas para no solaparse
            min_distance = max(C.ENEMY_MIN_DISTANCE, (self.rect.w + other.rect.w) / 2 + 4)
            if distance < min_distance:
                direction = offset.normalize() if distance > 0.01 else Vector2(1, 0).rotate(random.uniform(0, 360))
                push += direction * (min_distance - distance) * C.REPULSION_STRENGTH
        return push

    # --- armas a distancia (soldado y tanque) ---------------------------------------------------------------
    def _acquire(self, nav=None):
        """Objetivo más cercano dentro del alcance: piloto, drones aliados o estructuras.
        En los niveles con muros, solo cuenta lo que tiene a tiro (un soldado no se queda disparando a una pared)."""
        w = self.world
        best, best_d = None, self.base["range"] ** 2
        player = [w.player] if w.player is not None and w.player.alive() else []
        for t in itertools.chain(player, w.drones, w.structures):
            d = self.pos.distance_squared_to(t.pos)
            if d < best_d and (nav is None or nav.has_clear_shot(self.pos, t.pos)):
                best, best_d = t, d
        return best

    def _fire_logic(self, dt, nav=None):
        """Devuelve True si se detiene a disparar (tiene un objetivo en alcance)."""
        self.shoot_timer -= dt
        self.aim_check -= dt
        if self.aim_check <= 0:
            self.aim_check = 0.25
            self.aim = self._acquire(nav)
        target = self.aim
        if target is None or not target.alive() or self.pos.distance_to(target.pos) > self.base["range"] * 1.05:
            self.aim = None
            self.burst_left = 0
            return False
        direction = target.pos - self.pos
        if direction.length_squared() > 1:
            self._turn_towards(math.degrees(math.atan2(direction.y, direction.x)), dt)
        w = self.world
        if self.enemy_type == "soldier":
            if self.burst_left > 0:
                self.burst_timer -= dt
                if self.burst_timer <= 0:
                    life = self.base["range"] * 1.15 / Projectile.SPEED
                    w.enemy_bullets.add(Projectile(self.pos, direction, self.base["shot_damage"] * self.power,
                                                   "enemy", lifetime=life))
                    self.burst_left -= 1
                    self.burst_timer = self.base["burst_gap"]
                    if self.burst_left == 0:
                        self.shoot_timer = self.base["burst_cooldown"]
                        self.strafe_side = random.choice((-1, 1))      # la próxima pausa, a un lado cualquiera
            elif self.shoot_timer <= 0:
                self.burst_left, self.burst_timer = self.base["burst"], 0.0
        elif self.aim_timer > 0:                                              # tanque apuntando: impacto ya fijado
            self.aim_timer -= dt
            if self.aim_timer <= 0:
                shell = Shell(self.pos, self.aim_point, self.base["cannon_damage"] * self.power,
                              self.base["splash_radius"], w, self.base["shell_speed"], self.base["player_splash"])
                w.shells.add(shell)
                w.all_sprites.add(shell)
                self.shoot_timer = self.base["cannon_cooldown"]
                self.aim_point = None
        elif self.shoot_timer <= 0 and abs(self.angle_to(target.pos)) <= self.base["aim_tolerance"]:
            self.aim_timer = self.base["aim_time"]                            # alineado: apunta (aviso) y fija el impacto
            self.aim_point = Vector2(target.pos)
        # El soldado se planta mientras dispara la ráfaga y en la pausa se reposiciona (ver _reposition); el tanque solo se
        # detiene mientras apunta (y avanza muy lento el resto del tiempo): su alcance de 380 px no lo vuelve intocable.
        if self.enemy_type == "tank":
            return self.aim_timer > 0
        return self.enemy_type == "soldier" and self.burst_left > 0

    # --- Ariete: marcha, aviso, embestida, recuperación ----------------------------------------------------------
    def _charge_target(self, heading):
        """Estructura que queda al frente (en línea recta, dentro del alcance de carga), o None."""
        if heading.length_squared() == 0:
            return None
        best, best_d = None, self.base["charge_trigger"]
        for s in self.world.structures:
            to = s.pos - self.pos
            d = to.length()
            if 0 < d < best_d:
                off = abs(heading.angle_to(to))
                if min(off, 360 - off) < 25:
                    best, best_d = s, d
        return best

    def _ram_logic(self, dt, heading, speed):
        """Devuelve (rumbo, velocidad, quieto)."""
        st = self.state
        if st == "march":
            self.state_timer -= dt
            if self.state_timer <= 0:
                self.state_timer = 0.25
                target = self._charge_target(heading)
                if target is not None:
                    self.state, self.state_timer = "windup", self.base["windup"]
                    self.charge_dir = (target.pos - self.pos).normalize()       # hacia dónde QUIERE embestir
            return heading, speed, False
        if st == "windup":                                                     # gira poco (120 °/s), sin saltos
            self.state_timer -= dt
            want = math.degrees(math.atan2(self.charge_dir.y, self.charge_dir.x))
            self._turn_towards(want, dt, max_rate=self.base["windup_turn_rate"])
            if self.state_timer <= 0:
                self.charge_dir = self.facing_vector()                         # embiste hacia donde quedó mirando
                self.state, self.traveled, self.hit_units = "charge", 0.0, False
            return heading, speed, True
        if st == "charge":
            self.facing = math.degrees(math.atan2(self.charge_dir.y, self.charge_dir.x)) % 360
            p = self.world.player
            if (p is not None and p.alive() and not self.hit_units
                    and self.rect.colliderect(p.rect)):
                p.take_damage(self.base["impact_vs_units"] * self.power)       # el dash (i-frames) lo esquiva
                self.hit_units = True
            if self.traveled > self.base["charge_trigger"] + 160:
                self.state, self.state_timer = "recover", self.base["recover"]
            return self.charge_dir, self.base["charge_speed"], False
        self.state_timer -= dt                                                  # recover
        if self.state_timer <= 0:
            self.state, self.state_timer = "march", 0.4
        return heading, speed, True

    def _ram_impact(self, obstacle):
        """Choque de la embestida contra una estructura: 300 de impacto y aturdimiento propio."""
        if hasattr(obstacle, "ram_reduction"):                   # muro Reforzado: -30% al impacto de embestida
            obstacle.take_damage(self.base["impact"] * self.power, ram=True)
        else:
            obstacle.take_damage(self.base["impact"] * self.power)
        combat.FX.request_shake()
        combat.FX.spark(self.pos + self.charge_dir * 24, C.ORANGE)
        self.state, self.state_timer = "recover", self.base["recover"]

    # --- bucle -----------------------------------------------------------------------------------------------
    def update(self, dt, obstacles_group, nav=None, solids=None):
        """`obstacles_group`: estructuras que ataca si le cierran el paso; `solids`: muros de nivel
        indestructibles que simplemente le bloquean (colisión pasiva por ejes)."""
        if self.is_evacuation and self._evacuated():
            self.kill()                                   # salió del mapa: ni botín ni muerte (no cuenta como baja)
            return
        if self.own_nav is not None:
            nav = self.own_nav
        self.attack_timer -= dt
        self.counter_timer = max(0.0, self.counter_timer - dt)
        self.slow_timer = max(0.0, self.slow_timer - dt)
        if self.slow_timer <= 0:
            self.slow_factor = 0.0
        charging = self.enemy_type == "ariete" and self.state == "charge"
        push = Vector2() if charging else self._repulsion()
        heading = self._heading(nav)
        speed = self.speed * (1.0 - self.slow_factor if self.slow_timer > 0 else 1.0)
        hold = False
        if self.enemy_type == "scout":
            heading = self._flank(heading)
        elif self.world is not None and self.active:
            if self.enemy_type in ("soldier", "tank"):
                hold = self._fire_logic(dt, nav)
                if self.enemy_type == "soldier" and not hold and self.aim is not None and self.aim.alive():
                    heading, speed = self._reposition(speed)               # pausa entre ráfagas: reposicionarse
            else:
                heading, speed, hold = self._ram_logic(dt, heading, speed)
                charging = self.state == "charge"
        # TODOS los enemigos (también los scouts en grupo) atacan la estructura que les cierra el paso: la que de
        # verdad los frenó en los últimos instantes (colisión) y queda por delante; la que solo rozan de costado
        # se desliza.
        obstacle = None
        self._blocker_age += dt
        blocker = self._blocker
        if blocker is not None and blocker.alive() and self._blocker_age < 0.25:
            if charging or heading.length_squared() == 0:
                obstacle = blocker
            else:
                ahead = blocker.pos - self.pos
                if ahead.length_squared() > 0 and ahead.normalize().dot(heading) > BLOCK_DOT:
                    obstacle = blocker

        forward = Vector2()
        if obstacle is not None and self.rect.inflate(10, 10).colliderect(obstacle.rect):
            # sigue pegado a ella (margen > lo que avanza en un fotograma): el contacto no se corta cada 0,25 s
            self._blocker_age = 0.0
        if obstacle is not None:
            if charging:
                self._ram_impact(obstacle)
            elif self.contact_continuous and self.damage > 0:             # Scout: muerde sin pausa (dps * dt)
                if hasattr(obstacle, "counter_damage"):
                    obstacle.take_damage(self.contact_damage(dt), attacker=self)
                else:
                    obstacle.take_damage(self.contact_damage(dt))
            elif self.attack_timer <= 0 and self.damage > 0:
                if hasattr(obstacle, "counter_damage"):          # muro Electrificado: contraataca a Scouts y Soldados
                    obstacle.take_damage(self.damage, attacker=self)
                else:
                    obstacle.take_damage(self.damage)
                self.attack_timer = self.attack_cooldown
        elif hold:
            pass
        elif heading.length_squared() > 0:
            if solids is not None and not charging:
                if self._unstick_t > 0:                                     # desvío sostenido para salir de la esquina
                    self._unstick_t -= dt
                    heading = self._follow_wall(heading, solids, obstacles_group)
                else:
                    heading = self._whiskers(heading, solids, obstacles_group)
                    n = self._nearest_wall_normal(solids, obstacles_group)
                    if n is not None and heading.dot(n) < -0.6 and not self._guided:   # en línea recta, de frente:
                        self._start_follow(n)                               # la bordea por un lado fijo
                        heading = self._follow_wall(heading, solids, obstacles_group)
            # Apretado entre otros enemigos: frena y hace cola en lugar de apilarse
            crowd = min(1.0, push.length() / max(1.0, 0.5 * speed))
            forward = heading * speed * (1.0 - (0.0 if charging else crowd))

        if obstacle is not None and push.length_squared() > 0:
            to_obstacle = obstacle.pos - self.pos
            if to_obstacle.length_squared() > 0:                       # la multitud no los empuja contra lo que atacan
                n = to_obstacle.normalize()
                if push.dot(n) > 0:
                    push -= n * push.dot(n)
        move = (forward + push) * dt
        # Las estructuras del jugador bloquean por ejes (y la que frena es la que ataca); si ya estaba solapado con una
        # (p. ej. se construyó encima), puede salir libremente. Los muros de nivel no frenan: desliza a lo largo de ellos.
        stuck_in = obstacles_group is not None and pygame.sprite.spritecollideany(self, obstacles_group) is not None
        for axis in ("x", "y"):
            setattr(self.pos, axis, getattr(self.pos, axis) + getattr(move, axis))
            self.rect.center = (round(self.pos.x), round(self.pos.y))
            if stuck_in or obstacles_group is None:
                continue
            hit = pygame.sprite.spritecollideany(self, obstacles_group)
            if hit is not None:
                setattr(self.pos, axis, getattr(self.pos, axis) - getattr(move, axis))
                self._blocker, self._blocker_age = hit, 0.0             # esta estructura me cierra el paso
        if solids is not None:
            self._slide_walls(solids, obstacles_group)
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        self._check_stuck(dt, forward, heading, solids, obstacles_group, obstacle or (hold or None))
        if charging:
            self.traveled += move.length()
        elif (not hold and move.length_squared() > 0.25 and obstacle is None
              and not (self.enemy_type == "tank" and self.aim is not None)):    # el Tanque con blanco lo sigue apuntando
            self._turn_towards(math.degrees(math.atan2(move.y, move.x)), dt)
        elif obstacle is not None and not charging:
            ahead = obstacle.pos - self.pos
            if ahead.length_squared() > 0:
                self._turn_towards(math.degrees(math.atan2(ahead.y, ahead.x)), dt)   # encara lo que golpea

    def _reset_stuck(self):
        self._stuck_t, self._stuck_want = 0.0, 0.0
        self._stuck_anchor = Vector2(self.pos)

    def _check_stuck(self, dt, forward, heading, solids, obstacles_group, busy):
        """Desatasco: si durante `stuck_time` s (0,4) intentó avanzar pero su desplazamiento NETO no llega al
        `stuck_ratio` de lo intentado (clavado o vibrando en una esquina cóncava), se desvía de forma sostenida entre 45° y
        90° del rumbo, hacia el lado que tenga libre, durante `unstick_time` s."""
        st = U.ENEMY_STEERING
        want = forward.length() * dt
        self._since_unstick += dt
        if solids is None or busy is not None or want < 0.05 or self._unstick_t > 0:
            self._reset_stuck()
            return
        self._stuck_t += dt
        self._stuck_want += want
        if self._stuck_t < st["stuck_time"]:
            return
        net = self.pos.distance_to(self._stuck_anchor)
        if net < self._stuck_want * st["stuck_ratio"] and heading.length_squared() > 0:
            lo, hi = st["unstick_angle"]
            angle = random.uniform(lo, hi)
            length = self.rect.w / 2 + st["whisker_len"]
            walls = self._wall_rects(solids, obstacles_group, self.rect.inflate(2 * length, 2 * length))
            repeat = self._since_unstick < 2.0 and self._unstick_side != 0      # otra vez atascado: insiste por el mismo lado
            self._unstick_streak = self._unstick_streak + 1 if repeat else 0
            if repeat:
                side = self._unstick_side
            else:
                to = self.target_pos - self.pos
                options = {1: heading.rotate(angle), -1: heading.rotate(-angle)}
                free = [s for s, d in options.items() if self._ray_hit(d, length, walls) is None] or [1, -1]
                side = max(free, key=lambda s: options[s].dot(to))
            self._unstick_side = side
            self._unstick_dir = heading.rotate(angle * side)
            self._unstick_t = st["unstick_time"] * min(4.0, 1.0 + self._unstick_streak)   # cada vez bordea más tiempo
            self._since_unstick = 0.0
        self._reset_stuck()

    def draw(self, surface, offset=None):
        """Sprite PNG girado hacia donde avanza; si falta el archivo, el dibujo procedural de siempre."""
        found = _sprite(self.enemy_type, self.facing)
        if found is None:
            return super().draw(surface, offset)
        img, key = found
        offset = Vector2() if offset is None else offset
        r = img.get_rect(center=(round(self.pos.x - offset.x), round(self.pos.y - offset.y)))
        if self.enemy_type == "ariete" and self.state in ("windup", "charge"):     # aviso de embestida
            dir_ = self.facing_vector() if self.state == "windup" else self.charge_dir
            end = Vector2(r.center) + dir_ * (self.base["charge_trigger"] + 40)
            pygame.draw.line(surface, (255, 60, 60), r.center, end, 2)
        if self.flash_frames > 0:
            surface.blit(_white(key, img), r)
            self.flash_frames -= 1
        else:
            surface.blit(img, r)
        self.draw_overlay(surface, r, offset)

    def draw_overlay(self, surface, screen_rect, offset):
        if self.aim_point is not None and self.aim_timer > 0:                  # Tanque apuntando: línea y zona del impacto
            k = 1.0 - self.aim_timer / self.base["aim_time"]
            spot = (round(self.aim_point.x - offset.x), round(self.aim_point.y - offset.y))
            pygame.draw.line(surface, (255, 90, 60), screen_rect.center, spot, 1)
            pygame.draw.circle(surface, (255, 90, 60), spot, self.base["splash_radius"], 1)
            pygame.draw.circle(surface, (255, 160, 80), spot, max(2, round(self.base["splash_radius"] * k)), 2)
        if self.carries_part:                                                  # rombo amarillo: lleva una pieza del chasis
            c = (screen_rect.centerx, screen_rect.top - 12)
            pygame.draw.polygon(surface, C.YELLOW, [(c[0], c[1] - 6), (c[0] + 6, c[1]), (c[0], c[1] + 6), (c[0] - 6, c[1])])
        if self.hp < self.max_hp:
            w = max(20, screen_rect.w)
            health_bar(surface, self, pygame.Rect(screen_rect.centerx - w // 2, screen_rect.top - 8, w, 5),
                       self.hp / self.max_hp, hostile=True)
