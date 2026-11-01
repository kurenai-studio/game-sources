"""Legibilidad en combate: barras de vida con estela de daño, banner de oleada, viñeta de daño y avisos de pérdidas.

Todo es solo presentación: no toca vida, daño ni colisiones. Los relojes usan `_now()` (ms de pygame) para poder
sustituirlos en las pruebas."""
import math

import pygame

import config as C

GHOST_DRAIN = 0.55           # fracción de barra que la estela blanca recupera por segundo
LOW_HP = 0.25                # bajo este umbral las barras parpadean en rojo


def _now():
    return pygame.time.get_ticks() / 1000.0


# ------------------------------------------------------------------ barras de vida ----
def bar_color(frac, hostile=False, now=None):
    """Verde > ámbar > rojo según la vida (los enemigos siempre en rojo). Bajo LOW_HP parpadea."""
    if hostile:
        return (232, 72, 60)
    if frac > 0.5:
        return (70, 235, 120)
    if frac > LOW_HP:
        return (255, 184, 48)
    t = _now() if now is None else now
    return (255, 70, 56) if int(t * 4) % 2 == 0 else (255, 150, 130)


def _ghost(entity, frac, now):
    """Estela de daño: vuelve a la vida real poco a poco; si la entidad se cura, no deja rastro."""
    ghost, t0 = getattr(entity, "_bar_ghost", (1.0, now))
    dt = max(0.0, min(0.1, now - t0))
    ghost = frac if frac >= ghost else max(frac, ghost - GHOST_DRAIN * dt)
    entity._bar_ghost = (ghost, now)
    return ghost


def health_bar(surface, entity, rect, frac, hostile=False):
    """Barra con contorno oscuro, marcas al 25/50/75 %, color por tramo y estela blanca del último daño."""
    frac = max(0.0, min(1.0, frac))
    now = _now()
    ghost = _ghost(entity, frac, now)
    r = pygame.Rect(rect)
    pygame.draw.rect(surface, (8, 8, 12), r.inflate(2, 2))
    pygame.draw.rect(surface, (54, 10, 10) if hostile else (22, 26, 36), r)
    fw, gw = round(r.w * frac), round(r.w * ghost)
    if gw > fw:
        pygame.draw.rect(surface, (244, 244, 232), (r.x + fw, r.y, gw - fw, r.h))
    if fw > 0:
        color = bar_color(frac, hostile, now)
        pygame.draw.rect(surface, color, (r.x, r.y, fw, r.h))
        if r.h >= 4:
            pygame.draw.line(surface, tuple(min(255, c + 70) for c in color), (r.x, r.y), (r.x + fw - 1, r.y))
    if r.w >= 40:
        for k in (1, 2, 3):
            x = r.x + r.w * k // 4
            pygame.draw.line(surface, (8, 8, 12), (x, r.y), (x, r.bottom - 1))


# ------------------------------------------------------------------ banner de oleada ----
class WaveBanner:
    """Anuncio centrado cuando cambia la fase: preparación, oleada n/N (o la final), oleada superada y asalto."""
    SHOW = 2.6

    def __init__(self):
        self._key = None
        self._t0 = -99.0
        self._style = None

    def _announce(self, wave):
        phase, n = wave.phase, wave.wave
        total = getattr(wave, "total_waves", 0)
        endless = getattr(wave, "endless", False)
        if phase == "wave":
            if not endless and total and n >= total:
                return "¡OLEADA FINAL!", C.RED, "enemies"
            return f"OLEADA {n}" + ("" if endless or not total else f" / {total}"), C.RED, "enemies"
        if phase == "break":
            return f"OLEADA {n} SUPERADA", C.GREEN, "next"
        if phase == "prep":
            return "PREPARA LA DEFENSA", C.CYAN, None
        return "ASALTO", C.ORANGE, None

    def draw(self, surface, hud, wave):
        now = _now()
        key = (wave.phase, wave.wave)
        if key != self._key:
            self._key = key
            self._t0 = now
            self._style = self._announce(wave)
        age = now - self._t0
        if age >= self.SHOW or self._style is None:
            return
        title, color, sub_kind = self._style
        a = max(0.0, min(1.0, age / 0.25, (self.SHOW - age) / 0.5))
        y = round(C.WINDOW_HEIGHT * 0.30) + round((1 - min(1.0, age / 0.25)) * -14)
        strip = pygame.Surface((C.WINDOW_WIDTH, 96), pygame.SRCALPHA)
        strip.fill((6, 8, 14, int(165 * a)))
        pygame.draw.line(strip, (*color, int(230 * a)), (0, 1), (C.WINDOW_WIDTH, 1), 2)
        pygame.draw.line(strip, (*color, int(230 * a)), (0, 94), (C.WINDOW_WIDTH, 94), 2)
        surface.blit(strip, (0, y - 48))
        img = hud._render("xl", title, color).copy()
        img.set_alpha(int(255 * a))
        surface.blit(img, img.get_rect(center=(C.WINDOW_WIDTH // 2, y - 12)))
        sub = None
        if sub_kind == "enemies":
            sub = f"Enemigos: {getattr(wave, 'remaining', 0)}"
        elif sub_kind == "next":
            sub = f"Siguiente en {max(0, math.ceil(getattr(wave, 'timer', 0)))} s"
        if sub:
            s_img = hud._render("m", sub, C.WHITE).copy()
            s_img.set_alpha(int(255 * a))
            surface.blit(s_img, s_img.get_rect(center=(C.WINDOW_WIDTH // 2, y + 32)))


# ------------------------------------------------------------------ viñeta de daño ----
class DamageVignette:
    """Borde rojo que destella al perder vida el Operador y late de forma continua con vida baja (< 30 %)."""
    FLASH_TIME = 0.5
    DEPTH = 130

    def __init__(self):
        self._hp = None
        self._flash = 0.0
        self._t = None
        self._surf = None

    def _vignette(self, size):
        if self._surf is None or self._surf.get_size() != size:
            surf = pygame.Surface(size, pygame.SRCALPHA)
            for i in range(self.DEPTH):
                pygame.draw.rect(surf, (200, 0, 0, int(215 * (1 - i / self.DEPTH) ** 1.6)),
                                 (i, i, size[0] - 2 * i, size[1] - 2 * i), 1)
            self._surf = surf
        return self._surf

    def strength(self, hp, max_hp, now):
        dt = 0.0 if self._t is None else max(0.0, min(0.1, now - self._t))
        self._t = now
        if self._hp is not None and hp < self._hp - 0.01:
            self._flash = min(1.0, max(self._flash, 0.55 + (self._hp - hp) / max(1.0, max_hp) * 1.5))
        self._hp = hp
        self._flash = max(0.0, self._flash - dt / self.FLASH_TIME)
        low = max(0.0, (0.3 - hp / max(1.0, max_hp)) / 0.3) if hp > 0 else 0.0
        return max(self._flash, low * (0.35 + 0.15 * math.sin(now * 6)))

    def draw(self, surface, player):
        s = self.strength(player.hp, player.max_hp, _now())
        if s < 0.02:
            return
        vig = self._vignette(surface.get_size())
        vig.set_alpha(int(255 * min(1.0, s)))
        surface.blit(vig, (0, 0))


# ------------------------------------------------------------------ avisos de pérdidas ----
class AlertToasts:
    """Avisos breves apilados (estructura perdida, Centro de Control bajo ataque). Los repetidos se agrupan (x3)."""
    TTL = 3.5
    MAX = 3

    def __init__(self):
        self.items = []                 # [clave, texto, color, instante, repeticiones]

    def clear(self):
        self.items.clear()

    def push(self, text, color=C.RED, key=None):
        key = text if key is None else key
        now = _now()
        for it in self.items:
            if it[0] == key:
                it[3] = now
                it[4] += 1
                return
        self.items.append([key, text, color, now, 1])
        del self.items[:-self.MAX]

    def draw(self, surface, hud, pos=None):
        now = _now()
        self.items = [it for it in self.items if now - it[3] < self.TTL]
        x, y = pos or (C.WINDOW_WIDTH // 2, round(C.WINDOW_HEIGHT * 0.30) + 74)
        for key, text, color, t0, n in self.items:
            label = text if n == 1 else f"{text} ×{n}"
            a = max(0.0, min(1.0, (self.TTL - (now - t0)) / 0.6))
            img = hud._render("m", label, color)
            pill = pygame.Surface((img.get_width() + 24, img.get_height() + 8), pygame.SRCALPHA)
            pill.fill((8, 8, 14, int(190 * a)))
            pygame.draw.rect(pill, (*color, int(230 * a)), pill.get_rect(), 1)
            surface.blit(pill, pill.get_rect(center=(x, y)))
            faded = img.copy()
            faded.set_alpha(int(255 * a))
            surface.blit(faded, faded.get_rect(center=(x, y)))
            y += pill.get_height() + 4


ALERTS = AlertToasts()
