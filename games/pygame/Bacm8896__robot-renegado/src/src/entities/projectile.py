import pygame
from pygame.math import Vector2

import config as C
from src.entities import GameSprite
from src.mechanics import combat

_COLORS = {"player": C.YELLOW, "tower": C.YELLOW, "ally": C.CYAN, "enemy": C.RED, "balista": C.ORANGE}


class Projectile(GameSprite):
    """Bala del jugador, de una torre, de un dron aliado o de un enemigo.

    `pierce` = cuántos objetivos atraviesa antes de desaparecer (balista); `hit` recuerda a quién ya golpeó."""
    layer = 3
    SPEED = 500
    LIFETIME = 5
    world_rect = pygame.Rect(0, 0, C.WINDOW_WIDTH, C.WINDOW_HEIGHT)   # el estado lo ajusta

    def __init__(self, start_pos, direction, damage=C.PLAYER_BULLET_DAMAGE, owner="player", lifetime=None,
                 speed=None, pierce=1, radius=4, splash=0, splash_radius=0, armor_pierce=0):
        super().__init__()
        self.pos = Vector2(start_pos)
        d = Vector2(direction)
        self.speed = self.SPEED if speed is None else speed
        self.vel = (d.normalize() if d.length_squared() > 0 else Vector2(1, 0)) * self.speed
        self.radius = radius
        self.lifetime = self.LIFETIME if lifetime is None else lifetime
        self.owner = owner           # "player" | "tower" | "ally" | "enemy" | "balista"
        self.damage = damage
        self.pierce = pierce
        self.splash = splash                  # daño extra en área al impactar (balista explosiva)
        self.splash_radius = splash_radius
        self.armor_pierce = armor_pierce     # puntos de armadura plana que ignora (Minigun: 4)
        self.hit = set()             # ids de los objetivos que ya atravesó
        self.color = _COLORS.get(owner, C.YELLOW)
        self.rect = pygame.Rect(0, 0, self.radius * 2, self.radius * 2)
        self.rect.center = (round(self.pos.x), round(self.pos.y))

    def update(self, dt):
        self.pos += self.vel * dt
        self.lifetime -= dt
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        if self.lifetime <= 0 or not self.world_rect.colliderect(self.rect):
            self.kill()

    def draw(self, surface, offset=None):
        off = Vector2() if offset is None else offset
        c = (round(self.pos.x - off.x), round(self.pos.y - off.y))
        pygame.draw.circle(surface, self.color, c, self.radius)
        if self.pierce > 1:                                      # estela de la bala perforante
            tail = Vector2(c) - self.vel.normalize() * 14
            pygame.draw.line(surface, self.color, c, tail, 2)


class Shell(GameSprite):
    """Obús del tanque: vuela hasta un punto del suelo y explota en área (daño con caída hacia el borde)."""
    layer = 3

    def __init__(self, start_pos, target_pos, damage, radius, world, speed=360, player_factor=1.0):
        super().__init__()
        self.pos = Vector2(start_pos)
        self.target = Vector2(target_pos)
        self.damage = damage
        self.radius = radius
        self.world = world
        self.speed = speed
        self.player_factor = player_factor        # fracción del daño que recibe el Operador (el resto de blancos, 1.0)
        self.exploded = False
        self.rect = pygame.Rect(0, 0, 12, 12)
        self.rect.center = (round(self.pos.x), round(self.pos.y))

    def update(self, dt):
        to = self.target - self.pos
        step = self.speed * dt
        if to.length() <= step:
            self.pos = Vector2(self.target)
            self.rect.center = (round(self.pos.x), round(self.pos.y))
            self.explode()
        else:
            self.pos += to.normalize() * step
            self.rect.center = (round(self.pos.x), round(self.pos.y))

    def absorb(self):
        """Un escudo lo intercepta: desaparece sin explotar."""
        self.exploded = True
        self.kill()

    def explode(self):
        if self.exploded:
            return
        self.exploded = True
        w = self.world
        victims = []
        if w.player is not None and w.player.alive():
            victims.append(w.player)
        victims += list(w.drones) + list(w.structures)
        for v in victims:
            d = Vector2(v.pos).distance_to(self.pos)
            if d <= self.radius:
                amount = self.damage if d <= self.radius * 0.5 else self.damage * 0.5
                v.take_damage(amount * (self.player_factor if v is w.player else 1.0))
        for _ in range(3):
            combat.FX.spark(self.pos, C.ORANGE)
        combat.FX.request_shake()
        self.kill()

    def draw(self, surface, offset=None):
        off = Vector2() if offset is None else offset
        tgt = (round(self.target.x - off.x), round(self.target.y - off.y))
        pygame.draw.circle(surface, (150, 30, 30), tgt, int(self.radius), 1)         # aviso: zona de impacto
        pygame.draw.circle(surface, C.RED, tgt, max(2, int(self.radius * 0.5)), 1)
        pygame.draw.circle(surface, C.ORANGE, (round(self.pos.x - off.x), round(self.pos.y - off.y)), 6)
