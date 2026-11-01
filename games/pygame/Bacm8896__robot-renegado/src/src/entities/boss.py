"""Ariete Ligero (el "Tanque" del sub-acto 1.2): mini-jefe blindado. Embiste en línea recta; su punto débil es el radiador trasero.

Daño direccional según por dónde entra la bala, medido desde el frente del chasis:
  * arco trasero (135°-225°): x2 de daño, chispas críticas, humo, destello del radiador, sacudida y sonido;
  * frente (±45°): blindaje pesado (x0,25) y rebote metálico;
  * costados: blindaje medio (x0,5) y rebote metálico.
Con menos del 30% de vida sale una columna constante de humo negro del radiador."""
import math
import random

import pygame
from pygame.math import Vector2

import config as C
from src.core import sfx
from src.entities import GameSprite
from src.mechanics import combat
from src.ui import entity_art

_EPS = 1e-6
_font = None


def _crit_font():
    global _font
    if _font is None:
        _font = pygame.font.SysFont("consolas", 16, bold=True)
    return _font


class LightRam(GameSprite):
    layer = 2
    casts_shadow = True
    SIZE = 54
    TURRET_SPEED = 260.0                       # grados/s: la torreta gira por su cuenta, más rápido que el chasis
    CRIT_TIME = 0.8                            # s que dura el "¡CRÍTICO!" flotante
    FLARE_TIME = 0.5                           # s de destello del radiador tras un golpe crítico

    def __init__(self, pos):
        super().__init__()
        self.pos = Vector2(pos)
        self.hp = self.max_hp = C.RAM_LIGHT_HP
        self.state = "idle"                  # idle -> windup -> charge -> stun
        self.timer = 0.6
        self.facing = Vector2(-1, 0)
        self.charge_dir = Vector2(-1, 0)
        self.turret_dir = Vector2(-1, 0)     # hacia donde apunta la torreta (independiente del chasis)
        self.traveled = 0.0
        self.hit_player = False
        self.dead = False
        self.on_death = None
        self.t = 0.0
        self.smoke = []                      # [pos, vel, edad, vida, tamaño, claro]: humo del radiador
        self._smoke_acc = 0.0
        self.crit_timer = 0.0
        self.flare = 0.0
        self.crits = 0                       # golpes críticos recibidos
        self.ricochets = 0                   # golpes que rebotaron en el blindaje
        self.base_image = self._render()
        self.core_glow = entity_art.render_tank_core_glow(self.SIZE)
        self.turret_image = entity_art.render_tank_turret(self.SIZE)
        self.image = self.base_image
        self.rect = pygame.Rect(0, 0, self.SIZE, self.SIZE)
        self.rect.center = (round(self.pos.x), round(self.pos.y))

    def _render(self):
        return entity_art.render_tank_chassis(self.SIZE)    # mirando a la derecha: radiador atrás, glacis delante

    @property
    def rear_pos(self):
        """Posición en el mundo del radiador trasero (donde sale el humo y donde se ve el pulso ámbar)."""
        return self.pos - self.facing * (self.SIZE * 0.34)

    # --- daño direccional ---
    def impact_zone(self, direction):
        """"rear" | "front" | "side" según el lado por el que entra un proyectil que viaja en `direction`; None sin dirección.
        El ángulo es el del punto de impacto medido desde el frente del chasis: 135°-225° = arco trasero."""
        v = Vector2(direction) if direction is not None else Vector2()
        if v.length_squared() == 0:
            return None
        angle = self.facing.angle_to(-v) % 360.0
        lo, hi = C.RAM_REAR_ARC
        half = (hi - lo) / 2.0
        if lo - _EPS <= angle <= hi + _EPS:
            return "rear"
        if angle <= half + _EPS or angle >= 360.0 - half - _EPS:
            return "front"
        return "side"

    def take_damage(self, amount, direction=None):
        """`direction` = velocidad del proyectil. Por la espalda x2 (crítico), de frente x0,25 y de costado x0,5, salvo
        aturdido (entonces nunca baja de x1)."""
        if self.dead:
            return False
        zone = self.impact_zone(direction)
        mult = {"rear": C.RAM_REAR_MULT, "front": C.RAM_FRONT_MULT, "side": C.RAM_SIDE_MULT}.get(zone, 1.0)
        if self.state == "stun":
            mult = max(mult, 1.0)
        if zone == "rear":
            self._critical_feedback()
        elif zone is not None:
            self._ricochet_feedback(direction)
        self.hp -= amount * mult
        self.flash()
        if self.hp <= 0:
            self.dead = True
            self.kill()
            if self.on_death:
                self.on_death(self)
            return True
        return False

    def _critical_feedback(self):
        """Golpe en el radiador: chispas críticas, bocanada de humo, destello, texto, sacudida y sonido."""
        self.crits += 1
        spot = self.rear_pos
        combat.FX.spark(spot, (255, 196, 60))
        combat.FX.spark(spot, (255, 255, 255))
        combat.FX.request_shake()
        self.crit_timer, self.flare = self.CRIT_TIME, self.FLARE_TIME
        for _ in range(5):
            self.smoke.append([Vector2(spot), Vector2(random.uniform(-26, 26), random.uniform(-48, -18)),
                               0.0, random.uniform(0.7, 1.1), random.uniform(5, 8), True])
        sfx.play("crit")

    def _ricochet_feedback(self, direction):
        """Rebote en el blindaje pesado: chispas metálicas en el punto por el que entró la bala."""
        self.ricochets += 1
        v = Vector2(direction)
        spot = self.pos - v.normalize() * (self.SIZE * 0.5)
        combat.FX.spark(spot, (200, 206, 220))
        sfx.play("ricochet")

    # --- movimiento ---
    def _move(self, delta, solids):
        """Mueve por ejes; devuelve True si chocó con un sólido."""
        hit = False
        for axis in ("x", "y"):
            setattr(self.pos, axis, getattr(self.pos, axis) + getattr(delta, axis))
            self.rect.center = (round(self.pos.x), round(self.pos.y))
            if pygame.sprite.spritecollideany(self, solids) is not None:
                setattr(self.pos, axis, getattr(self.pos, axis) - getattr(delta, axis))
                self.rect.center = (round(self.pos.x), round(self.pos.y))
                hit = True
        return hit

    def _update_fx(self, dt, aim):
        """Torreta independiente, humo del radiador (columna constante con menos del 30% de vida) y temporizadores."""
        self.t += dt
        self.crit_timer = max(0.0, self.crit_timer - dt)
        self.flare = max(0.0, self.flare - dt)
        if aim is not None and aim.length_squared() > 1:
            diff = (self.turret_dir.angle_to(aim.normalize()) + 180.0) % 360.0 - 180.0
            self.turret_dir.rotate_ip(max(-self.TURRET_SPEED * dt, min(self.TURRET_SPEED * dt, diff)))
        if self.hp / self.max_hp < C.RAM_SMOKE_BELOW:
            self._smoke_acc += dt
            while self._smoke_acc >= 0.07:
                self._smoke_acc -= 0.07
                self.smoke.append([self.rear_pos + Vector2(random.uniform(-3, 3), random.uniform(-3, 3)),
                                   Vector2(random.uniform(-9, 9), random.uniform(-52, -34)), 0.0,
                                   random.uniform(1.0, 1.5), random.uniform(4, 6), False])
        for p in self.smoke:
            p[0] += p[1] * dt
            p[2] += dt
        self.smoke = [p for p in self.smoke if p[2] < p[3]]

    def update(self, dt, world):
        player = world.player
        alive = player is not None and player.alive()
        to_player = (player.pos - self.pos) if alive else Vector2()
        self._update_fx(dt, to_player if alive else self.facing)
        if self.state == "idle":
            self.timer -= dt
            if alive and to_player.length_squared() > 1:
                self.facing = to_player.normalize()
            if alive and self.timer <= 0 and to_player.length() < C.RAM_TRIGGER:
                self.state, self.timer = "windup", 0.0
        elif self.state == "windup":
            self.timer += dt
            if alive and self.timer < C.RAM_WINDUP - 0.3 and to_player.length_squared() > 1:
                self.facing = to_player.normalize()       # sigue al jugador y se fija 0.3 s antes
            if self.timer >= C.RAM_WINDUP:
                self.state, self.charge_dir = "charge", Vector2(self.facing)
                self.traveled, self.hit_player = 0.0, False
        elif self.state == "charge":
            self.facing = Vector2(self.charge_dir)
            step = self.charge_dir * C.RAM_CHARGE_SPEED * dt
            if self._move(step, world.solids):
                self.state, self.timer = "stun", C.RAM_STUN            # choca con un muro: aturdido
                combat.FX.request_shake()
                combat.FX.spark(self.pos + self.charge_dir * 30, C.ORANGE)
            else:
                self.traveled += step.length()
                if alive and not self.hit_player and self.rect.colliderect(player.rect):
                    player.take_damage(C.RAM_CONTACT_DAMAGE)        # el dash (i-frames) lo esquiva
                    self.hit_player = True
                if self.traveled > 900:
                    self.state, self.timer = "idle", 1.0
        elif self.state == "stun":
            self.timer -= dt
            if self.timer <= 0:
                self.state, self.timer = "idle", 0.8
        self.rect.center = (round(self.pos.x), round(self.pos.y))

    # --- dibujo ---
    @staticmethod
    def _spin(image, direction):
        return pygame.transform.rotate(image, -math.degrees(math.atan2(direction.y, direction.x)))

    def draw(self, surface, offset=None):
        off = Vector2() if offset is None else offset
        center = (round(self.pos.x - off.x), round(self.pos.y - off.y))
        if self.state == "windup":                          # aviso: línea roja hacia donde va a embestir
            end = Vector2(center) + self.facing * 520
            pygame.draw.line(surface, (255, 60, 60), center, end, 2)
        chassis = self._spin(self.base_image, self.facing)
        turret = self._spin(self.turret_image, self.turret_dir)
        if self.flash_frames > 0:
            chassis = pygame.mask.from_surface(chassis).to_surface(setcolor=(255, 255, 255, 255), unsetcolor=(0, 0, 0, 0))
            turret = pygame.mask.from_surface(turret).to_surface(setcolor=(255, 255, 255, 255), unsetcolor=(0, 0, 0, 0))
            self.flash_frames -= 1
        surface.blit(chassis, chassis.get_rect(center=center))
        # pulso ámbar oscilante del núcleo del radiador: señal de zona vulnerable (más fuerte tras un crítico)
        pulse = 0.5 + 0.5 * math.sin(self.t * 5.0)
        strength = min(1.0, 0.35 + 0.45 * pulse + 1.2 * (self.flare / self.FLARE_TIME))
        glow = self._spin(self.core_glow, self.facing)
        glow.set_alpha(int(255 * strength))
        surface.blit(glow, glow.get_rect(center=center))
        surface.blit(turret, turret.get_rect(center=center))
        for pos, _, age, life, size, light in self.smoke:    # humo: negro (radiador dañado) o gris claro (impacto crítico)
            k = age / life
            r = max(2, int(size * (1.0 + 1.6 * k)))
            puff = pygame.Surface((r * 2 + 2, r * 2 + 2), pygame.SRCALPHA)
            color = (92, 92, 98) if light else (12, 12, 14)
            pygame.draw.circle(puff, (*color, int((150 if light else 185) * (1 - k))), (r + 1, r + 1), r)
            surface.blit(puff, puff.get_rect(center=(round(pos.x - off.x), round(pos.y - off.y))))
        if self.crit_timer > 0:                                # "¡CRÍTICO!" flotante sobre el radiador
            k = 1.0 - self.crit_timer / self.CRIT_TIME
            txt = _crit_font().render("¡CRÍTICO!", True, (255, 214, 70))
            txt.set_alpha(int(255 * (1 - k * k)))
            spot = self.rear_pos - off
            surface.blit(txt, txt.get_rect(midbottom=(round(spot.x), round(spot.y - 18 - 22 * k))))
        bar = pygame.Rect(center[0] - 30, center[1] - 44, 60, 5)
        pygame.draw.rect(surface, (40, 0, 0), bar)
        pygame.draw.rect(surface, C.ORANGE, (bar.x, bar.y, int(bar.w * max(0, self.hp) / self.max_hp), 5))
        if self.state == "stun":
            pygame.draw.circle(surface, C.YELLOW, center, 34, 1)
