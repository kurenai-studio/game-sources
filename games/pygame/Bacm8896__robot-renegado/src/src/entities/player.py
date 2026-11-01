import math

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.core.asset_manager import assets
from src.core.audio_manager import audio
from src.entities import GameSprite
from src.entities.projectile import Projectile
from src.mechanics import combat

SPRITE_ARMED = "entities/player.png"               # exoesqueleto + rifle (apunta a la derecha)
SPRITE_UNARMED = "entities/player_unarmored.png"
SPRITE_SIZE_ARMED = U.scaled(100)                  # lado del lienzo en pantalla (83); el eje de giro está en el centro
SPRITE_SIZE_UNARMED = U.scaled(72)                 # 60
ROT_STEP = 4                                       # grados por paso de la caché de giros
SHOT_BUFFER = 0.25                                 # s que se recuerda un clic dado durante el enfriamiento


class Player(GameSprite):
    """Piloto del chasis. Twin-stick: WASD mueve, el ratón apunta, ESPACIO/SHIFT hace dash."""
    layer = 4
    casts_shadow = True
    recoil = 0.0                  # 1 -> 0 en 0.09 s tras disparar: el sprite se echa 3 px hacia atrás
    bob_t = 0.0                   # fase del balanceo al caminar
    bob_amp = 0.0                 # 0 parado, 1 en marcha (suavizado)

    def __init__(self, start_pos, world_width, world_height):
        super().__init__()
        self.pos = Vector2(start_pos)
        self.vel = Vector2(0, 0)
        # Colisión física: un círculo de radio 13 en el centro del Operador (el sprite de 100 px es solo dibujo).
        # `rect` (26x26) es su caja envolvente: sirve para la fase gruesa y para los impactos.
        self.radius = U.PLAYER["hitbox_radius"]
        self.rect = pygame.Rect(0, 0, 2 * self.radius, 2 * self.radius)
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        self.hp = C.PLAYER_START_HP
        self.max_hp = C.PLAYER_START_HP
        self.speed = C.PLAYER_SPEED
        self.shoot_cooldown = C.PLAYER_SHOOT_RATE
        self.shoot_timer = self.shoot_cooldown         # listo: el primer disparo (o golpe) no espera
        self.world_width, self.world_height = world_width, world_height
        self.aim_dir = Vector2(1, 0)
        self.angle = 0.0
        self.repair_mode = False
        self.repair_timer = 0.0
        self.since_hit = 99.0             # segundos seguidos sin recibir daño (lo reinicia solo un golpe que entra)
        self.aura_regen = False           # AURA en el traje: +4 HP/s tras 3 s sin daño (lo fija apply_upgrades)
        self.regen_rate = 0.0             # HP/s extra de la mejora de recompensa de regeneración, sobre la de AURA
        self.regen_delay = C.PLAYER_REGEN_DELAY            # s sin recibir daño antes de regenerar (B3 Nanoregeneración: 1,8)
        self.regen_mult = 1.0                              # multiplicador de la tasa de regeneración (hoy ningún nodo lo cambia)
        self.health_blocks = C.PLAYER_HEALTH_BLOCKS        # bloques de vida (Celda Vital I: 4 · Celda Vital II: 5)
        self.vision_bonus = 0             # px extra de visión de la Visión Táctica (reward)
        self.dead = False
        # Exoesqueleto y rifle (el sub-acto 1.1 empieza sin equipar: sin disparo ni dash)
        self.equipped = True
        self.mag_size = C.PLAYER_MAG_SIZE                 # balas por cargador
        self.capacity = C.PLAYER_AMMO_CAPACITY            # balas en total (3 cargadores; el Terminal Táctico amplía)
        self.mag_rounds = self.mag_size                   # balas en el cargador actual
        self.reserve = self.capacity - self.mag_size      # balas en los demás cargadores
        self.reload_timer = 0.0
        self.infinite_ammo = False                        # Acto 1 (tutorial): munición infinita
        self.automatic_fire = False                       # A1 Gatillo Automático: mantener clic = fuego continuo
        self.bullet_damage = C.PLAYER_BULLET_DAMAGE       # A2 y A3 lo suben (16 y 20)
        self.bullet_pierce = 1                            # A2: 2 (atraviesa un enemigo más)
        self.shots_fired = 0
        self.bullet_range = C.PLAYER_BULLET_RANGE
        # Cuerpo a cuerpo (sin munición): golpe corto con repulsión
        self.melee_damage, self.melee_range = C.PLAYER_MELEE_DAMAGE, C.PLAYER_MELEE_RANGE
        self.melee_cooldown, self.melee_knockback = C.PLAYER_MELEE_COOLDOWN, C.PLAYER_MELEE_KNOCKBACK
        self.melee_timer = 0.0
        self.melee_swings = 0
        self.swing_visual = 0.0
        self.melee_targets = ()                           # grupos de enemigos al alcance del golpe (los fija la escena)
        self.aim_targets = None                           # grupos que atrae la asistencia de apuntado (None: melee_targets)
        self.aim_assist = True
        self.aim_filter = None                            # callable(enemigo) -> bool: p. ej. solo los visibles en la niebla
        self._solids = ()
        self._click_prev = False                          # semiautomático: un disparo por clic
        self._queued_click = 0.0                          # clic pendiente (búfer) si cae durante el enfriamiento
        self._melee_request = 0.0                         # clic derecho pendiente: golpe cuerpo a cuerpo
        # Entradas suprimidas tras avanzar un diálogo: evita un Dash o disparo accidentales hasta soltar la tecla
        self._suppress_space = False
        self._suppress_mouse = False
        # Dash
        self.is_invulnerable = False
        self.dash_timer = 0.0
        self.dash_charges_max = 1                         # B1 Impulso Doble: 2
        self.dash_recharge = []                           # una cuenta atrás por carga gastada (recargas independientes)
        self._dash_prev = False                           # SHIFT del fotograma anterior (con 2 cargas, un dash por pulsación)
        self.dash_dir = Vector2()
        # Baluarte y aturdimiento
        self.stun_timer = 0.0
        # Los configura el estado que crea al jugador:
        self.projectile_groups = ()       # grupos donde entran las balas
        self.repair_callback = None       # callable(edificio) -> bool (cobra el metal)
        self.build_mode = False           # con un edificio elegido o un menú abierto, el clic no dispara
        # Árbol de mejoras (Terminal Táctico): efectos que fija apply_upgrades
        self.armor_reduction = 0.0        # % de daño recibido que quitan los rewards de armadura
        self.flat_armor = 0               # B2 Blindaje de Titanio: puntos de armadura plana por impacto
        self.damage_aura = 0.0            # bono de reducción de daño de una fuente externa (hoy ninguna unidad lo fija)
        self.repair_delay = C.REPAIR_DELAY

    # --- dano / curacion ---
    @property
    def is_dashing(self):
        return self.dash_timer > 0

    def take_damage(self, amount, direct=False, continuous_dt=None):
        """`direct=True` ignora la invulnerabilidad del dash (p. ej. la caída de un baluarte). Durante el dash (0,15 s) no
        entra ningún daño: ni balas, ni obuses, ni contacto, y tampoco se reinicia el reloj de la regeneración.
        `continuous_dt`: daño continuo de este fotograma (mordida de Scout = dps * dt): la armadura plana del Blindaje de
        Titanio se descuenta por segundo (mínimo 1 HP/s) y no sacude la cámara en cada fotograma."""
        if (self.is_dashing or self.is_invulnerable) and not direct:
            return
        amount *= 1.0 - self.damage_reduction                                 # rewards de armadura + bono externo (tope)
        if self.flat_armor > 0:                                               # B2 Blindaje de Titanio: armadura plana pasiva
            if continuous_dt is not None:
                amount = max(continuous_dt, amount - self.flat_armor * continuous_dt)
            else:
                amount = max(1.0, amount - self.flat_armor)
        blocks_before = self.blocks_left
        self.hp -= amount
        self.since_hit = 0.0
        if self.blocks_left < blocks_before and self.hp > 0:
            audio.play("block_break")                                # se vació un bloque de vida entero
        audio.play("hit")                                            # (el canal de impactos limita las mordidas seguidas)
        if continuous_dt is None:
            combat.FX.request_shake()
            combat.FX.floater(self.pos, f"-{max(1, round(amount))}")          # cifra de daño sobre el Operador
            combat.FX.spark(self.pos, (255, 70, 60))
        else:                                                                # mordidas: una cifra cada ~4 HP acumulados
            self._dot_acc = getattr(self, "_dot_acc", 0.0) + amount
            if self._dot_acc >= 4.0:
                combat.FX.floater(self.pos, f"-{round(self._dot_acc)}")
                combat.FX.spark(self.pos, (255, 70, 60))
                self._dot_acc = 0.0
        if self.hp <= 0:
            self.hp = 0
            self.dead = True             # el estado activo lanza el reintento del sub-acto
            self.kill()

    @property
    def damage_reduction(self):
        """Reducción de daño porcentual total: rewards de armadura + bono externo, sumadas y con tope del 35%."""
        return min(U.DAMAGE_REDUCTION_CAP, self.armor_reduction + self.damage_aura)

    REGEN_EPS = 1e-6                     # la suma de dt en coma flotante (180 x 1/60) puede quedar a 1e-15 de 3,0

    @property
    def regen_per_second(self):
        """HP/s con que se rellena el bloque dañado: (base del bloque + AURA + reward de regeneración) x multiplicador de
        la Nanoregeneración."""
        return (C.PLAYER_BLOCK_REGEN + (C.PLAYER_REGEN_RATE if self.aura_regen else 0.0) + self.regen_rate) * self.regen_mult

    # --- vida segmentada en bloques ---
    @property
    def block_size(self):
        return self.max_hp / max(1, self.health_blocks)

    def block_ceiling(self):
        """Tope hasta el que regenera: el borde superior del bloque en curso (0 si no queda vida). Un bloque vaciado del
        todo se pierde y no vuelve solo."""
        if self.hp <= self.REGEN_EPS:
            return 0.0
        size = self.block_size
        return min(float(self.max_hp), math.ceil(self.hp / size - 1e-6) * size)

    @property
    def blocks_left(self):
        """Bloques con algo de vida (el dañado cuenta)."""
        return 0 if self.hp <= self.REGEN_EPS else round(self.block_ceiling() / self.block_size)

    @property
    def lost_blocks(self):
        return self.health_blocks - self.blocks_left

    def use_medkit(self):
        """[H] Botiquín: devuelve un bloque perdido entero (y rellena el dañado). Sin bloques perdidos no se gasta."""
        if self.dead or self.lost_blocks <= 0:
            return False
        self.hp = min(float(self.max_hp), self.block_ceiling() + self.block_size)
        combat.FX.floater(self.pos, "+1 bloque")
        audio.play("medkit")                                         # inyección: bloque recuperado
        return True

    def _regenerate(self, dt):
        """Tras exactamente `regen_delay` (3,0 s) seguidos sin daño, el bloque dañado recupera
        regen_per_second * dt, sin pasar de su tope: los bloques perdidos no se regeneran."""
        rate = self.regen_per_second
        if (rate > 0 and not self.dead and self.hp < self.max_hp
                and self.since_hit >= self.regen_delay - self.REGEN_EPS):
            self.hp = min(self.block_ceiling(), self.hp + rate * dt)

    def heal(self, amount):
        self.hp = min(self.max_hp, self.hp + amount)

    # --- munición ---
    @property
    def ammo(self):
        """Balas totales que quedan (cargador actual + reserva)."""
        return self.mag_rounds + self.reserve

    @property
    def out_of_ammo(self):
        return not self.infinite_ammo and self.ammo <= 0 and self.reload_timer <= 0

    def full_ammo(self):
        self.mag_rounds = min(self.mag_size, self.capacity)
        self.reserve = self.capacity - self.mag_rounds
        self.reload_timer = 0.0

    def add_ammo(self, amount):
        """Recoge munición (hasta la capacidad). Devuelve cuántas balas entraron; recarga sola si estaba vacío."""
        added = max(0, min(amount, self.capacity - self.ammo))
        self.reserve += added
        if added and self.mag_rounds <= 0 and self.reload_timer <= 0:
            self.reload_timer = C.PLAYER_RELOAD_TIME
        return added

    def _finish_reload(self):
        take = min(self.mag_size, self.reserve)
        self.mag_rounds = take
        self.reserve -= take

    def can_fire(self):
        return self.infinite_ammo or (self.mag_rounds > 0 and self.reload_timer <= 0)

    def _in_melee_reach(self, e):
        """¿`e` está al alcance del golpe y delante (hacia el cursor)?"""
        to = e.pos - self.pos
        d = to.length()
        if d > self.melee_range + e.rect.w / 2:
            return False
        return d <= 1 or self.aim_dir.dot(to / d) >= -0.2

    def melee(self):
        """Golpe defensivo: daño y repulsión a los enemigos cercanos (delante de ti). Devuelve cuántos golpeó."""
        hits = 0
        for group in self.melee_targets:
            for e in list(group):
                if not self._in_melee_reach(e):
                    continue
                to = e.pos - self.pos
                d = to.length()
                e.take_damage(self.melee_damage, to)
                if e.alive() and d > 1:
                    step = to / d
                    for k in (1.0, 0.5, 0.25):                         # la repulsión no mete al enemigo en un muro
                        new = e.pos + step * self.melee_knockback * k
                        probe = e.rect.copy()
                        probe.center = (round(new.x), round(new.y))
                        if probe.collidelist([s.rect for s in self._solids]) == -1:
                            e.pos = new
                            e.rect.center = probe.center
                            break
                hits += 1
        self.melee_timer = self.melee_cooldown
        self.melee_swings += 1
        self.swing_visual = 0.14
        return hits

    def apply_upgrades(self, res):
        """Aplica el árbol de mejoras del Terminal Táctico (Balística y Exotraje) al Operador."""
        fx = U.OPERATOR_EFFECTS
        self.shoot_cooldown = res.fire_cooldown()
        self.bullet_damage = res.bullet_damage()
        self.bullet_pierce = res.bullet_pierce()
        self.max_hp = self.hp = res.player_max_hp
        self.automatic_fire = res.owns("gatillo_automatico")
        self.capacity = res.ammo_capacity()
        self.full_ammo()
        self.refresh_rewards(res, heal=False)
        self.flat_armor = fx["flat_armor"] if res.owns("blindaje_titanio") else 0
        self.dash_charges_max = fx["dash_charges"] if res.owns("impulso_doble") else 1
        self.dash_recharge = [t for t in self.dash_recharge][:self.dash_charges_max]
        self.health_blocks = C.PLAYER_HEALTH_BLOCKS + res.extra_health_blocks()
        self.regen_delay = C.PLAYER_REGEN_DELAY
        self.regen_mult = 1.0
        self.aura_regen = bool(res.aura_linked)                 # AURA en el traje (desde el 1.2): regeneración base

    def refresh_rewards(self, res, heal=True):
        """Mejoras de recompensa (Prioridad 4): velocidad, reducción de daño, regeneración, visión, vida y munición máximas.
        Se llama al desplegar (apply_upgrades) y al desbloquear un reward en pleno combate (sin rellenar nada)."""
        rw = res.reward_tracker
        self.speed = C.PLAYER_SPEED + rw.player_bonus("speed")
        self.armor_reduction = round(rw.player_bonus("damage_reduction"), 6)    # el tope se aplica en damage_reduction
        self.regen_rate = rw.player_bonus("regen_rate")
        self.vision_bonus = rw.player_bonus("vision_range")
        new_max = res.player_max_hp
        if heal:
            self.hp += max(0, new_max - self.max_hp)
        self.max_hp = new_max
        self.hp = min(self.hp, self.max_hp)
        self.capacity = res.ammo_capacity()

    def suppress_inputs(self):
        """Tras avanzar un diálogo con ESPACIO o clic: ignora el Dash y el disparo hasta que se suelten."""
        self._suppress_space = True
        self._suppress_mouse = True

    # --- acciones ---
    def assisted_aim(self):
        """Dirección del disparo con asistencia magnética: si hay un enemigo vivo dentro del alcance del rifle a menos de
        `aim_assist_cone` grados del cursor, la bala sale hacia él (el más alineado; a igualdad, el más cercano)."""
        if not self.aim_assist:
            return Vector2(self.aim_dir)
        cone = U.PLAYER["aim_assist_cone"]
        best, best_key = None, None
        groups = self.aim_targets if self.aim_targets is not None else self.melee_targets
        for group in groups:
            for e in group:
                if not e.alive() or getattr(e, "dead", False) or (self.aim_filter is not None and not self.aim_filter(e)):
                    continue
                to = e.pos - self.pos
                d = to.length()
                if d < 1 or d > self.bullet_range:
                    continue
                off = abs(self.aim_dir.angle_to(to))
                off = min(off, 360 - off)
                if off <= cone:
                    key = (round(off, 1), d)
                    if best_key is None or key < best_key:
                        best, best_key = to / d, key
        return best if best is not None else Vector2(self.aim_dir)

    def shoot(self):
        lifetime = self.bullet_range / C.PLAYER_BULLET_SPEED
        direction = self.assisted_aim()
        bullet = Projectile(self.pos + direction * 20, direction, self.bullet_damage, "player", lifetime,
                            speed=C.PLAYER_BULLET_SPEED, pierce=self.bullet_pierce)
        for group in self.projectile_groups:
            group.add(bullet)
        audio.play("rifle")
        self.shots_fired += 1
        self.recoil = 1.0
        if not self.infinite_ammo:
            self.mag_rounds -= 1
            if self.mag_rounds <= 0 and self.reserve > 0:
                self.reload_timer = C.PLAYER_RELOAD_TIME       # recarga automática al vaciar el cargador (0.8 s)

    def _repair_nearby(self, buildings_group):
        nearby = pygame.sprite.spritecollide(
            self, buildings_group, False,
            collided=lambda p, b: p.pos.distance_to(b.pos) < C.REPAIR_RANGE)
        for b in nearby:
            if not getattr(b, "repairable", False) or b.hp >= b.max_hp:
                continue
            if self.repair_callback is None or self.repair_callback(b):
                b.repair(b.max_hp * C.REPAIR_FRACTION)

    def _move(self, dt, solids):
        """Mueve el círculo de colisión en sub-pasos de medio radio (el dash no atraviesa muros ni a 20 FPS) y, tras cada
        uno, lo saca de lo que pise empujándolo por la normal del punto más cercano: contra una pared desliza y en las
        esquinas se redondea en lugar de engancharse."""
        delta = self.vel * dt
        steps = max(1, math.ceil(delta.length() / (self.radius * 0.5)))
        step = delta / steps
        for _ in range(steps):
            self.pos += step
            self._resolve_collisions(solids)
        self.rect.center = (round(self.pos.x), round(self.pos.y))

    def _resolve_collisions(self, solids):
        for _ in range(3):                                   # una esquina interior puede necesitar dos empujes
            self.rect.center = (round(self.pos.x), round(self.pos.y))
            pushed = False
            for hit in pygame.sprite.spritecollide(self, solids, False):    # fase gruesa: caja envolvente
                if self.dash_timer > 0 and getattr(hit, "dash_passable", False):
                    continue                                 # el dash franquea la tubería rota
                if getattr(hit, "ally_passable", False):
                    hit.open()                               # Compuerta Blindada: se abre sola para el Operador
                    continue
                push = self._push_out(hit.rect)
                if push is not None:
                    self.pos += push
                    pushed = True
            if not pushed:
                break

    def _push_out(self, rect):
        """Vector que saca el círculo del rectángulo (None si no se tocan)."""
        r = self.radius
        cx = max(rect.left, min(self.pos.x, rect.right))
        cy = max(rect.top, min(self.pos.y, rect.bottom))
        d = Vector2(self.pos.x - cx, self.pos.y - cy)
        dist2 = d.length_squared()
        if dist2 >= r * r:
            return None
        if dist2 > 1e-12:
            dist = math.sqrt(dist2)
            return d / dist * (r - dist)
        gaps = {"l": self.pos.x - rect.left, "r": rect.right - self.pos.x,     # centro dentro: sale por el lado más cercano
                "t": self.pos.y - rect.top, "b": rect.bottom - self.pos.y}
        side = min(gaps, key=gaps.get)
        return {"l": Vector2(-(gaps["l"] + r), 0), "r": Vector2(gaps["r"] + r, 0),
                "t": Vector2(0, -(gaps["t"] + r)), "b": Vector2(0, gaps["b"] + r)}[side]

    @property
    def dash_charges(self):
        """Cargas de Dash disponibles ahora (1 base, 2 con el Impulso Doble)."""
        return max(0, self.dash_charges_max - len(self.dash_recharge))

    @property
    def dash_cooldown_timer(self):
        """Segundos hasta tener una carga de Dash (0 si ya hay alguna)."""
        return 0.0 if self.dash_charges > 0 else min(self.dash_recharge)

    def _update_dash(self, dt, keys, wasd):
        self.dash_recharge = [t - dt for t in self.dash_recharge if t - dt > self.REGEN_EPS]    # cada carga se recarga sola
        self.dash_timer = max(0.0, self.dash_timer - dt)
        if self.dash_timer < self.REGEN_EPS:                  # sin residuos de coma flotante: el dash dura 0,15 s justos
            self.dash_timer = 0.0
        if self._suppress_space and not keys[pygame.K_SPACE]:
            self._suppress_space = False                      # ya se soltó: vuelve a funcionar
        held = bool(keys[pygame.K_LSHIFT])                    # ESPACIO es la pausa táctica: el dash va en SHIFT
        wants_dash = held and (self.dash_charges_max == 1 or not self._dash_prev)    # 2 cargas: un dash por pulsación
        self._dash_prev = held
        if (wants_dash and self.equipped and self.dash_charges > 0 and self.dash_timer <= 0
                and self.stun_timer <= 0):
            self.dash_timer = C.DASH_DURATION                 # i-frames propios de ESTE dash
            self.dash_recharge.append(C.DASH_COOLDOWN)        # ...y su recarga independiente
            self.dash_dir = Vector2(wasd) if wasd.length_squared() > 0 else Vector2(self.aim_dir)
            audio.play("dash")
        self.is_invulnerable = self.dash_timer > 0

    # --- update ---
    def update(self, dt, keys, mouse_pos, buildings_group, repair_mode=False):
        wasd = Vector2(keys[pygame.K_d] - keys[pygame.K_a], keys[pygame.K_s] - keys[pygame.K_w])
        if wasd.length_squared() > 0:
            wasd.normalize_ip()
        self.since_hit += dt
        self._regenerate(dt)
        self.shoot_timer += dt
        self.repair_timer -= dt
        self.stun_timer = max(0.0, self.stun_timer - dt)
        self.melee_timer = max(0.0, self.melee_timer - dt)
        self.swing_visual = max(0.0, self.swing_visual - dt)
        self._solids = buildings_group
        if self.reload_timer > 0:
            self.reload_timer -= dt
            if self.reload_timer <= 0:
                self._finish_reload()
        self._update_dash(dt, keys, wasd)

        speed = self.speed * (C.STUN_SPEED_FACTOR if self.stun_timer > 0 else 1.0)
        if self.dash_timer > 0:
            self.vel = self.dash_dir * self.speed * C.DASH_SPEED_MULT
        else:
            self.vel = wasd * speed
        self._move(dt, buildings_group)                       # círculo de colisión: desliza contra muros y esquinas
        moving = self.vel.length_squared() > 100 and self.dash_timer <= 0
        self.bob_amp += ((1.0 if moving else 0.0) - self.bob_amp) * min(1.0, dt * 10)
        if moving:
            self.bob_t += dt * 14
        self.recoil = max(0.0, self.recoil - dt / 0.09)
        self.pos.x = max(self.radius, min(self.world_width - self.radius, self.pos.x))
        self.pos.y = max(self.radius, min(self.world_height - self.radius, self.pos.y))
        self.rect.center = (round(self.pos.x), round(self.pos.y))

        # Apuntar al raton
        to_mouse = Vector2(mouse_pos) - self.pos
        if to_mouse.length_squared() > 1:
            self.angle = math.atan2(to_mouse.y, to_mouse.x)
            self.aim_dir = Vector2(math.cos(self.angle), math.sin(self.angle))

        self.repair_mode = bool(repair_mode or keys[pygame.K_r])
        # Clic izquierdo: dispara (semiautomático, o continuo con el Gatillo Automático); sin munición, golpea.
        # Clic derecho (la escena llama a queue_melee): golpe cuerpo a cuerpo hacia el cursor, con o sin munición.
        # El golpe respeta su enfriamiento (0,4 s) y, tras un disparo, también la cadencia del rifle: nada de golpes a
        # frecuencias irreales. El disparo no espera al golpe.
        left_click = pygame.mouse.get_pressed()[0] and not self.build_mode
        if self._suppress_mouse:
            if not left_click:
                self._suppress_mouse = False
            left_click = False                                # el clic que avanzó el diálogo no dispara
        fresh_click = left_click and not self._click_prev      # semiautomático: un clic = un disparo
        self._click_prev = left_click
        self._queued_click = SHOT_BUFFER if fresh_click else max(0.0, self._queued_click - dt)
        if self.repair_mode:
            if left_click and self.repair_timer <= 0:
                self._repair_nearby(buildings_group)
                self.repair_timer = self.repair_delay
        elif (((left_click and self.automatic_fire) or self._queued_click > 0) and self.equipped
              and self.stun_timer <= 0 and self.can_fire() and self.shoot_timer >= self.shoot_cooldown):
            self.shoot()
            self.shoot_timer = 0.0
            self._queued_click = 0.0
        elif (left_click and self.equipped and self.stun_timer <= 0 and self.out_of_ammo
              and self.melee_timer <= 0 and self.shoot_timer >= self.shoot_cooldown):
            self.melee()                                      # sin munición, el clic izquierdo también golpea
        self._melee_request = max(0.0, self._melee_request - dt)
        if (self._melee_request > 0 and self.equipped and not self.repair_mode and self.stun_timer <= 0
                and self.melee_timer <= 0 and self.shoot_timer >= self.shoot_cooldown):
            self.melee()                                      # clic derecho: golpe a voluntad
            self._melee_request = 0.0

    def queue_melee(self):
        """Clic derecho: pide un golpe cuerpo a cuerpo (se ejecuta en cuanto los enfriamientos lo permitan, 0,25 s)."""
        self._melee_request = SHOT_BUFFER

    # --- sprite PNG (con exoesqueleto o sin él) girado hacia el ratón; respaldo procedural si falta ---
    _rot_cache = {}

    def _sprite(self):
        name = SPRITE_ARMED if self.equipped else SPRITE_UNARMED
        size = SPRITE_SIZE_ARMED if self.equipped else SPRITE_SIZE_UNARMED
        base = assets.scaled(name, (size, size))
        if base is None:
            return None
        step = round(math.degrees(math.atan2(self.aim_dir.y, self.aim_dir.x)) / ROT_STEP) % (360 // ROT_STEP)
        key = (name, size, step)
        img = Player._rot_cache.get(key)
        if img is None:
            img = pygame.transform.rotate(base, -step * ROT_STEP)      # pygame gira en sentido antihorario
            Player._rot_cache[key] = img
        return img

    HURT_FLASH = 0.25                    # s de destello rojo tras recibir un golpe

    def _tint(self, img):
        """Destello blanco durante el dash y rojo al estar aturdido (sobre una copia: la caché no se toca)."""
        if self.is_invulnerable:
            color = (110, 110, 110, 0)
        elif self.stun_timer > 0:
            color = (120, 0, 0, 0)
        elif self.since_hit < self.HURT_FLASH:                               # golpe recibido: el sprite destella en rojo
            color = (round(210 * (1 - self.since_hit / self.HURT_FLASH)), 0, 0, 0)
        else:
            return img
        img = img.copy()
        img.fill(color, special_flags=pygame.BLEND_RGBA_ADD)
        return img

    # --- dibujo: sprite si existe; si no, cabeza (circulo), cuerpo (rectangulo), arma (linea) ---
    def draw(self, surface, offset=None):
        off = Vector2() if offset is None else offset
        c = Vector2(self.pos) - off
        ci = (round(c.x), round(c.y))
        si = (ci[0] - round(self.aim_dir.x * 3 * self.recoil),                     # balanceo + retroceso: solo el dibujo,
              ci[1] + round(math.sin(self.bob_t) * 2 * self.bob_amp) - round(self.aim_dir.y * 3 * self.recoil))   # no la colisión
        if self.swing_visual > 0:                                      # golpe cuerpo a cuerpo: arco frente al Operador
            a = math.degrees(self.angle)
            rect = pygame.Rect(0, 0, 2 * self.melee_range, 2 * self.melee_range)
            rect.center = ci
            pygame.draw.arc(surface, C.WHITE, rect, math.radians(-a - 70), math.radians(-a + 70), 3)
        img = self._sprite()
        if img is not None:
            surface.blit(self._tint(img), img.get_rect(center=si))
            if self.repair_mode:
                pygame.draw.circle(surface, C.YELLOW, ci, C.REPAIR_RANGE, 1)
            return
        body = pygame.Rect(0, 0, 24, 24)
        body.center = si
        body_color = C.WHITE if self.is_invulnerable else (C.RED if self.since_hit < self.HURT_FLASH else C.CYAN)
        pygame.draw.rect(surface, (20, 40, 50), body)
        pygame.draw.rect(surface, body_color, body, 2)
        pygame.draw.line(surface, C.WHITE, si, Vector2(si) + self.aim_dir * 26, 4)
        pygame.draw.circle(surface, C.RED if self.stun_timer > 0 else C.MAGENTA, ci, 8)
        pygame.draw.circle(surface, C.WHITE, ci, 3)
        if self.repair_mode:
            pygame.draw.circle(surface, C.YELLOW, ci, C.REPAIR_RANGE, 1)
