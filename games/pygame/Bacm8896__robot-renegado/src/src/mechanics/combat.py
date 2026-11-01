"""Colisiones (groupcollide / spritecollide) y efectos de game feel (shake, chispas)."""
import math
import random

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U


class Effects:
    """Screen shake (petición global) y partículas de impacto ultraligeras."""

    MAX_SPARKS = 200

    def __init__(self):
        self.sparks = []            # [pos, vel, vida, color]
        self.debris_bits = []       # [pos, vel, vida, color, tamaño]: escombros de muros rotos
        self.blasts = []            # [pos, vida, radio]: onda de una detonación (se expande y se apaga)
        self.floaters = []          # [pos, vida, texto, color]: cifras de daño que suben y se desvanecen
        self.crumbles = []          # [rect, vida]: destello rojo y grietas donde acaba de caer un muro
        self._font = None
        self._rng = random.Random()          # propio: las cifras no alteran la aleatoriedad del juego
        self._shake = False

    def clear(self):
        self.sparks.clear()
        self.debris_bits.clear()
        self.blasts.clear()
        self.floaters.clear()
        self.crumbles.clear()
        self._shake = False

    FLOATER_LIFE = 0.8
    MAX_FLOATERS = 24
    CRUMBLE_LIFE = 0.4

    def floater(self, pos, text, color=(255, 70, 60)):
        """Cifra flotante (p. ej. el daño que recibe el Operador)."""
        if len(self.floaters) >= self.MAX_FLOATERS:
            self.floaters.pop(0)
        self.floaters.append([Vector2(pos) + Vector2(self._rng.randint(-8, 8), -22), self.FLOATER_LIFE, str(text), color])

    def crumble(self, rect):
        """Un muro acaba de romperse: destello rojo y grietas sobre su hueco durante 0,4 s."""
        self.crumbles.append([pygame.Rect(rect), self.CRUMBLE_LIFE])

    BLAST_LIFE = 0.6

    def blast(self, pos, radius, color=(255, 150, 60)):
        """Detonación: onda que crece hasta `radius` px en 0,6 s y una corona de chispas."""
        self.blasts.append([Vector2(pos), self.BLAST_LIFE, radius, color])
        for _ in range(4):
            self.spark(pos, color)

    def request_shake(self):
        self._shake = True

    def consume_shake(self):
        requested, self._shake = self._shake, False
        return requested

    def spark(self, pos, color=C.YELLOW):
        """3-5 chispas que viven 0.2 s y se desvanecen."""
        for _ in range(random.randint(*C.SPARK_COUNT)):
            if len(self.sparks) >= self.MAX_SPARKS:
                return
            ang = random.uniform(0, math.tau)
            speed = random.uniform(60, 180)
            self.sparks.append([Vector2(pos), Vector2(math.cos(ang), math.sin(ang)) * speed,
                                C.SPARK_LIFE, color])

    MAX_DEBRIS = 90
    DEBRIS_LIFE = 0.55

    def debris(self, pos, color=(104, 112, 132), count=9):
        """Trozos de escombro que salen despedidos y se frenan: se rompe un muro."""
        for _ in range(count):
            if len(self.debris_bits) >= self.MAX_DEBRIS:
                return
            ang = random.uniform(0, math.tau)
            tone = random.randint(-22, 22)
            self.debris_bits.append([Vector2(pos), Vector2(math.cos(ang), math.sin(ang)) * random.uniform(50, 150),
                                     self.DEBRIS_LIFE, tuple(max(0, min(255, c + tone)) for c in color),
                                     random.randint(2, 4)])
        self.spark(pos, (255, 214, 120))

    def update(self, dt):
        for s in self.sparks:
            s[0] += s[1] * dt
            s[2] -= dt
        self.sparks = [s for s in self.sparks if s[2] > 0]
        if self.floaters:
            for f in self.floaters:
                f[0].y -= 38 * dt
                f[1] -= dt
            self.floaters = [f for f in self.floaters if f[1] > 0]
        if self.crumbles:
            for c in self.crumbles:
                c[1] -= dt
            self.crumbles = [c for c in self.crumbles if c[1] > 0]
        if self.blasts:
            for b in self.blasts:
                b[1] -= dt
            self.blasts = [b for b in self.blasts if b[1] > 0]
        if self.debris_bits:
            drag = max(0.0, 1.0 - 4.0 * dt)
            for d in self.debris_bits:
                d[0] += d[1] * dt
                d[1] *= drag
                d[2] -= dt
            self.debris_bits = [d for d in self.debris_bits if d[2] > 0]

    def draw(self, surface, offset):
        for rect, life in self.crumbles:                             # muro roto: destello rojo que se apaga y grietas
            k = max(0.0, life / self.CRUMBLE_LIFE)
            r = rect.move(-round(offset.x), -round(offset.y))
            glow = pygame.Surface(r.size, pygame.SRCALPHA)
            glow.fill((255, 50, 40, int(150 * k)))
            surface.blit(glow, r)
            pygame.draw.line(surface, (255, 120, 100), r.topleft, r.bottomright, 2)
            pygame.draw.line(surface, (255, 120, 100), r.topright, r.bottomleft, 2)
        for pos, life, radius, color in self.blasts:                 # onda expansiva de las detonaciones
            k = 1.0 - max(0.0, life / self.BLAST_LIFE)
            r = max(2, round(radius * k))
            pygame.draw.circle(surface, tuple(int(c * (1.0 - 0.6 * k)) for c in color),
                               (round(pos.x - offset.x), round(pos.y - offset.y)), r, max(1, round(4 * (1 - k))))
        for pos, vel, life, color in self.sparks:                    # chispas metálicas: trazo corto en la dirección del vuelo
            f = max(0.0, life / C.SPARK_LIFE)
            head = (round(pos.x - offset.x), round(pos.y - offset.y))
            tail = (round(head[0] - vel.x * 0.04), round(head[1] - vel.y * 0.04))
            pygame.draw.line(surface, tuple(int(c * f) for c in color), tail, head, 2 if f > 0.5 else 1)
            if f > 0.6:
                pygame.draw.circle(surface, (255, 255, 255), head, 1)
        for pos, _, life, color, size in self.debris_bits:
            f = max(0.0, life / self.DEBRIS_LIFE)
            pygame.draw.rect(surface, tuple(int(c * (0.4 + 0.6 * f)) for c in color),
                             (round(pos.x - offset.x), round(pos.y - offset.y), size, size))
        if self.floaters:
            if self._font is None:
                self._font = pygame.font.SysFont("consolas", 22, bold=True)
            for pos, life, text, color in self.floaters:
                k = min(1.0, life / (self.FLOATER_LIFE * 0.5))
                p = (round(pos.x - offset.x), round(pos.y - offset.y))
                shade = self._font.render(text, True, (0, 0, 0))
                img = self._font.render(text, True, color)
                shade.set_alpha(int(255 * k))
                img.set_alpha(int(255 * k))
                surface.blit(shade, shade.get_rect(center=(p[0] + 2, p[1] + 2)))
                surface.blit(img, img.get_rect(center=p))


FX = Effects()


def _hit(bullet_group_result, color):
    for bullet in bullet_group_result:
        FX.spark(bullet.pos, color)


def _plain_hit(bullet, victim):
    """Colisión de las balas normales; las perforantes (pierce > 1) se resuelven aparte."""
    # una bala perforante que ya golpeó a este objetivo (y bajó a pierce 1) no vuelve a dañarlo en el fotograma siguiente
    return bullet.pierce <= 1 and id(victim) not in bullet.hit and pygame.sprite.collide_rect(bullet, victim)


def _hurt(victim, bullet, enemies=None):
    """Daño de una bala; la víctima recibe además la dirección (armadura frontal del Ariete).
    Una bala explosiva (balista) daña también a los enemigos del radio de impacto."""
    pierce = getattr(bullet, "armor_pierce", 0)
    if pierce and hasattr(victim, "armor"):                    # perforación de armadura (Minigun)
        victim.take_damage(bullet.damage, bullet.vel, armor_pierce=pierce)
    else:
        victim.take_damage(bullet.damage, bullet.vel)
    if bullet.splash and enemies is not None:
        for other in list(enemies):
            if other is not victim and other.alive() and other.pos.distance_to(bullet.pos) <= bullet.splash_radius:
                other.take_damage(bullet.splash, other.pos - bullet.pos)
        FX.spark(bullet.pos, C.ORANGE)


def _resolve_piercing(bullet, groups, enemies=None):
    """Bala perforante: golpea a cada objetivo una sola vez y se gasta tras `pierce` impactos."""
    for group in groups:
        if group is None:
            continue
        for victim in pygame.sprite.spritecollide(bullet, group, False):
            if id(victim) in bullet.hit:
                continue
            bullet.hit.add(id(victim))
            FX.spark(bullet.pos, C.ORANGE)
            _hurt(victim, bullet, enemies)
            bullet.pierce -= 1
            if bullet.pierce <= 0:
                bullet.kill()
                return


def resolve_projectiles(bullets, enemies, scavengers, obstacles=None, hostile=None, bosses=None):
    """Balas (jugador, torres, drones) contra obstáculos, enemigos, carroñeros, estructuras hostiles y jefes.
    Los jefes y los enemigos reciben también la dirección del proyectil (daño direccional: punto ciego)."""
    if obstacles is not None:
        _hit(pygame.sprite.groupcollide(bullets, obstacles, True, False), (210, 214, 228))
    for bullet in [b for b in bullets if b.pierce > 1]:
        _resolve_piercing(bullet, (enemies, scavengers, hostile, bosses), enemies)
    for victims_group in (enemies, scavengers, hostile):
        if victims_group is None:
            continue
        hits = pygame.sprite.groupcollide(bullets, victims_group, True, False, collided=_plain_hit)
        for bullet, victims in hits.items():
            FX.spark(bullet.pos)
            _hurt(victims[0], bullet, enemies if victims_group is enemies else None)
    if bosses is not None:
        hits = pygame.sprite.groupcollide(bullets, bosses, True, False, collided=_plain_hit)
        for bullet, victims in hits.items():
            FX.spark(bullet.pos, C.ORANGE)
            victims[0].take_damage(bullet.damage, bullet.vel)


def resolve_enemy_bullets(enemy_bullets, player, drones, structures):
    """Disparos enemigos (torretas de la Fundición y soldados) contra jugador, drones y estructuras."""
    if player.alive():
        for bullet in pygame.sprite.spritecollide(player, enemy_bullets, True):
            FX.spark(bullet.pos, C.RED)
            player.take_damage(bullet.damage)
    for group in (drones, structures):
        hits = pygame.sprite.groupcollide(enemy_bullets, group, True, False)
        for bullet, victims in hits.items():
            FX.spark(bullet.pos, C.RED)
            victims[0].take_damage(bullet.damage)


def _continuous(enemy, dt):
    return dt is not None and getattr(enemy, "contact_continuous", False)


def resolve_enemy_player(player, enemies, dt=None):
    """Contacto cuerpo a cuerpo con el jugador. Con `dt`, el de los Scouts es continuo (melee_dps * dt cada fotograma);
    el resto (y todos si no se pasa dt) golpea una vez por `attack_cooldown`."""
    if not player.alive():
        return
    for enemy in pygame.sprite.spritecollide(player, enemies, False):
        if enemy.damage <= 0:
            continue
        if _continuous(enemy, dt):
            player.take_damage(enemy.contact_damage(dt), continuous_dt=dt)
        elif enemy.attack_timer <= 0:
            player.take_damage(enemy.damage)
            enemy.attack_timer = enemy.attack_cooldown


def resolve_enemy_allies(enemies, drones, dt=None):
    """Los enemigos que tocan a un dron aliado le hacen daño (continuo para los Scouts si hay dt). Los drones de la capa
    AÉREA son inmunes al contacto cuerpo a cuerpo (solo los alcanzan proyectiles, obuses y torretas)."""
    hits = pygame.sprite.groupcollide(enemies, drones, False, False)
    for enemy, victims in hits.items():
        victims = [v for v in victims if not getattr(v, "aerial", False)]
        if enemy.damage <= 0 or not victims:
            continue
        if _continuous(enemy, dt):
            victims[0].take_damage(enemy.contact_damage(dt))
        elif enemy.attack_timer <= 0:
            victims[0].take_damage(enemy.damage)
            enemy.attack_timer = enemy.attack_cooldown


def pickup_parts(player, parts, radius=16):
    """Recoge los componentes del chasis que ya llegaron al jugador. Devuelve cuántos."""
    got = pygame.sprite.spritecollide(
        player, parts, True, collided=lambda p, s: p.pos.distance_to(s.pos) <= radius)
    return len(got)


def pickup_cores(player, items, radius=14):
    """Recoge los Núcleos de Plasma que ya llegaron al jugador. Devuelve cuántos núcleos."""
    got = pygame.sprite.spritecollide(
        player, items, True, collided=lambda p, s: p.pos.distance_to(s.pos) <= radius)
    return sum(s.value for s in got)


def pickup_ammo(player, boxes, radius=16):
    """Recoge las cajas de munición que ya llegaron al jugador (si no tiene la munición llena). Devuelve las balas."""
    gained = 0
    for box in list(boxes):
        if player.ammo >= player.capacity:
            break
        if player.pos.distance_to(box.pos) <= radius:
            gained += player.add_ammo(box.amount)
            box.kill()
    return gained


def pickup_medkits(player, medkits, res, radius=16):
    """Guarda en el bolsillo los botiquines que llegaron al jugador (si cabe alguno). Devuelve cuántos."""
    got = 0
    for kit in list(medkits):
        if res.medkits >= U.MEDKITS["max"]:
            break
        if player.pos.distance_to(kit.pos) <= radius:
            got += res.add_medkits(1)
            kit.kill()
    if got:
        FX.floater(player.pos, f"+{got} botiquín")
    return got


def pickup_scraps(player, scraps, radius=14):
    """Recoge la chatarra que ya llegó al jugador (el magnetismo la acerca desde 48 px)."""
    got = pygame.sprite.spritecollide(
        player, scraps, True, collided=lambda p, s: p.pos.distance_to(s.pos) <= radius)
    return sum(s.value for s in got)
