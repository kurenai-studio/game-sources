"""Consola de transmisión y capa de diálogo narrativo.

- Mensajes normales (alertas breves, pistas): flotan en la esquina y NO pausan la simulación.
- Mensajes `blocking` (historia clave: inicio/fin de sub-acto, AURA, VULCANO, checkpoints): la escena congela el
  mundo por completo y se muestran con retrato del emisor en un recuadro tipo «Codec». Se avanzan con
  ESPACIO, ENTER o clic izquierdo: la primera pulsación completa el teletipo y la siguiente pasa a la línea
  siguiente; al terminar la última, la acción se reanuda de inmediato.
"""
import math

import pygame

import config as C
from src.core.asset_manager import assets as default_assets
from src.core.audio_manager import audio

SENDER_COLORS = {"AURA": C.CYAN, "VULCANO": C.ORANGE, "SISTEMA": C.GREEN, "OPERADOR": C.GREEN}
SENDER_ROLES = {"AURA": "IA · copiloto neuronal", "VULCANO": "IA de mantenimiento",
                "SISTEMA": "Sistema táctico", "OPERADOR": "Operador"}


def _dim(color, f):
    return tuple(int(c * f) for c in color)


# ---------------------------------------------------------------------------- retratos procedurales
def _portrait_aura(surface, rect, t, color):
    """AURA: pulso neuronal cian (anillos que respiran, onda y nodos)."""
    cx, cy = rect.center
    for i in range(3):
        r = 20 + i * 15 + 4 * math.sin(t * 3 - i * 0.8)
        pygame.draw.circle(surface, _dim(color, 0.35 + 0.2 * i), (cx, cy), round(r), 2 if i == 0 else 1)
    pts = []
    for x in range(rect.left + 10, rect.right - 9, 5):
        env = 1 - abs((x - cx) / (rect.w / 2))
        pts.append((x, cy + 22 * env * math.sin(x * 0.13 + t * 6)))
    pygame.draw.lines(surface, color, False, pts, 2)
    for k in range(7):                                        # nodos neuronales
        a = k * math.tau / 7 + t * 0.6
        p = (round(cx + 58 * math.cos(a)), round(cy + 50 * math.sin(a)))
        pygame.draw.line(surface, _dim(color, 0.4), (cx, cy), p, 1)
        pygame.draw.circle(surface, color, p, 3)
    pygame.draw.circle(surface, C.WHITE, (cx, cy), 4)


def _portrait_vulcano(surface, rect, t, color):
    """VULCANO: engranaje industrial con llama naranja."""
    cx, cy = rect.centerx, rect.centery + 12
    pts = []
    for k in range(24):
        a = k * math.tau / 24 + t * 0.5
        r = 46 if (k // 1) % 3 != 2 else 36
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    pygame.draw.polygon(surface, (60, 30, 8), pts)
    pygame.draw.polygon(surface, color, pts, 2)
    pygame.draw.circle(surface, (20, 10, 4), (cx, cy), 20)
    pygame.draw.circle(surface, color, (cx, cy), 20, 2)
    pygame.draw.circle(surface, C.YELLOW, (cx, cy), 6)
    for k, dx in enumerate((-16, 0, 16)):                     # llama
        h = 22 + 10 * math.sin(t * 9 + k * 2)
        base = cy - 48
        pygame.draw.polygon(surface, color, [(cx + dx - 7, base), (cx + dx, base - h), (cx + dx + 7, base)])
        pygame.draw.polygon(surface, C.YELLOW, [(cx + dx - 3, base), (cx + dx, base - h * 0.55), (cx + dx + 3, base)])


def _portrait_visor(surface, rect, t, color):
    """OPERADOR / SISTEMA: visor táctico verde con retícula y barrido."""
    visor = rect.inflate(-26, -56)
    pygame.draw.rect(surface, _dim(color, 0.18), visor, border_radius=14)
    pygame.draw.rect(surface, color, visor, 2, border_radius=14)
    sweep = visor.top + int((t * 70) % visor.h)
    pygame.draw.line(surface, color, (visor.left + 4, sweep), (visor.right - 4, sweep), 2)
    cx, cy = visor.center
    pygame.draw.circle(surface, _dim(color, 0.8), (cx, cy), 22, 1)
    pygame.draw.line(surface, color, (cx - 30, cy), (cx + 30, cy), 1)
    pygame.draw.line(surface, color, (cx, cy - 30), (cx, cy + 30), 1)
    for i in range(4):                                        # barras de estado
        pygame.draw.rect(surface, _dim(color, 0.7), (rect.left + 12, rect.bottom - 40 + i * 7, 18 + (i * 13) % 40, 3))
    pygame.draw.polygon(surface, color, [(rect.right - 28, rect.bottom - 14), (rect.right - 12, rect.bottom - 14),
                                         (rect.right - 20, rect.bottom - 30)], 1)


_scan_cache = {}


def draw_portrait(surface, rect, sender, t, assets=None):
    """Marco del emisor: usa su PNG de `assets/images/portraits/` si existe; si no, el arte procedural."""
    assets = assets if assets is not None else default_assets
    color = SENDER_COLORS.get(sender, C.WHITE)
    pygame.draw.rect(surface, (5, 9, 16), rect)
    image = assets.portrait(sender, rect.size)                # None si falta el archivo (respaldo procedural)
    if image is not None:
        surface.blit(image, image.get_rect(center=rect.center))
    elif sender == "AURA":
        _portrait_aura(surface, rect, t, color)
    elif sender == "VULCANO":
        _portrait_vulcano(surface, rect, t, color)
    else:
        _portrait_visor(surface, rect, t, color)
    key = rect.size
    if key not in _scan_cache:                                # líneas de escaneo tenues
        scan = pygame.Surface(rect.size, pygame.SRCALPHA)
        for y in range(0, rect.h, 4):
            pygame.draw.line(scan, (0, 0, 0, 55), (0, y), (rect.w, y))
        _scan_cache[key] = scan
    surface.blit(_scan_cache[key], rect)
    pygame.draw.rect(surface, color, rect, 2)
    for x, y, sx, sy in ((rect.left, rect.top, 1, 1), (rect.right, rect.top, -1, 1),
                         (rect.left, rect.bottom, 1, -1), (rect.right, rect.bottom, -1, -1)):   # esquinas
        pygame.draw.lines(surface, C.WHITE, False, [(x + 12 * sx, y), (x, y), (x, y + 12 * sy)], 2)


# ---------------------------------------------------------------------------- líneas y caja
class DialogueLine:
    def __init__(self, sender, text, duration, blocking):
        self.sender = sender
        self.text = text
        self.ttl = duration
        self.blocking = blocking
        self.shown = 0.0             # caracteres revelados

    @property
    def revealed(self):
        return self.shown >= len(self.text)


class DialogueBox:
    CHARS_PER_SEC = 70
    MAX_LINES = 4
    BLIP_EVERY = 3                   # un blip de teletipo cada 3 letras impresas
    BLIP_SOUNDS = {"AURA": "text_aura", "VULCANO": "text_vulcano", "SISTEMA": "text_sistema"}

    def __init__(self):
        self.lines = []
        self.clock = 0.0             # para animar retratos e indicador parpadeante
        self._seq_total = 0          # líneas bloqueantes de la secuencia en curso
        self._seq_done = 0
        self.assets = default_assets   # de dónde salen los retratos (PNG con respaldo procedural)

    def say(self, sender, text, duration=5.0, blocking=False):
        if blocking and not self.blocking_active:
            self._seq_total = self._seq_done = 0
        self.lines.append(DialogueLine(sender, text, duration, blocking))
        if blocking:
            self._seq_total += 1
        normal = [ln for ln in self.lines if not ln.blocking]
        while len(normal) > self.MAX_LINES:            # descarta las más antiguas
            self.lines.remove(normal.pop(0))

    @property
    def blocking_active(self):
        return any(ln.blocking for ln in self.lines)

    @property
    def current_blocking(self):
        return next((ln for ln in self.lines if ln.blocking), None)

    def clear(self):
        self.lines.clear()
        self._seq_total = self._seq_done = 0

    def update(self, dt):
        self.clock += dt
        active = self.current_blocking
        for ln in self.lines:
            if ln.blocking and ln is not active:
                continue                                # las cinemáticas se muestran de una en una
            before = int(ln.shown)
            ln.shown = min(len(ln.text), ln.shown + self.CHARS_PER_SEC * dt)
            if int(ln.shown) // self.BLIP_EVERY > before // self.BLIP_EVERY and ln.sender in self.BLIP_SOUNDS \
                    and ln.text[min(len(ln.text) - 1, int(ln.shown))].strip():
                audio.play(self.BLIP_SOUNDS[ln.sender])              # el teletipo suena mientras imprime (no en espacios)
            if not ln.blocking and ln.revealed:
                ln.ttl -= dt
        self.lines = [ln for ln in self.lines if ln.blocking or ln.ttl > 0]

    def advance(self):
        """ESPACIO / ENTER / clic: completa el teletipo de golpe o pasa a la línea siguiente."""
        ln = self.current_blocking
        if ln is None:
            return
        if not ln.revealed:
            ln.shown = len(ln.text)
        else:
            self.lines.remove(ln)
            self._seq_done += 1

    # --- dibujo ---
    @staticmethod
    def _wrap(text, font, width):
        words, rows, row = text.split(), [], ""
        for w in words:
            trial = (row + " " + w).strip()
            if font.size(trial)[0] <= width:
                row = trial
            else:
                rows.append(row)
                row = w
        rows.append(row)
        return rows

    def draw(self, surface, hud):
        blocking = self.current_blocking
        if blocking is None:
            y = C.WINDOW_HEIGHT - 130 - 24 * len([ln for ln in self.lines if not ln.blocking])
            for ln in (ln for ln in self.lines if not ln.blocking):
                color = SENDER_COLORS.get(ln.sender, C.WHITE)
                fade = 1.0 if not ln.revealed else max(0.35, min(1.0, ln.ttl))
                hud.text(surface, f"{ln.sender}> {ln.text[:int(ln.shown)]}", (16, y), "m", _dim(color, fade))
                y += 24
            return
        self._draw_overlay(surface, hud, blocking)

    def _draw_overlay(self, surface, hud, ln):
        """Capa de diálogo pausado estilo Codec: retrato, nombre, texto e indicador parpadeante."""
        W, H = C.WINDOW_WIDTH, C.WINDOW_HEIGHT
        if "dim" not in _scan_cache:
            dim = pygame.Surface((W, H), pygame.SRCALPHA)
            dim.fill((0, 0, 0, 120))
            _scan_cache["dim"] = dim
        surface.blit(_scan_cache["dim"], (0, 0))                   # el mundo queda congelado y atenuado
        color = SENDER_COLORS.get(ln.sender, C.WHITE)
        panel = pygame.Rect(W // 2 - 540, H - 240, 1080, 208)
        hud.panel(surface, panel, color)
        portrait = pygame.Rect(panel.x + 18, panel.y + 20, 168, 168)
        draw_portrait(surface, portrait, ln.sender, self.clock, self.assets)
        tx = portrait.right + 24
        hud.text(surface, ln.sender, (tx, panel.y + 16), "l", color)
        hud.text(surface, SENDER_ROLES.get(ln.sender, ""), (tx + 190, panel.y + 28), "s", C.DARK_GRAY)
        rows = self._wrap(ln.text[:int(ln.shown)], hud.fonts["m"], panel.right - tx - 28)
        for i, row in enumerate(rows[:5]):
            hud.text(surface, row, (tx, panel.y + 62 + i * 25), "m", C.WHITE)
        if self._seq_total > 1:
            hud.text(surface, f"{self._seq_done + 1}/{self._seq_total}", (panel.right - 70, panel.y + 12), "s", C.DARK_GRAY)
        if int(self.clock * 2.5) % 2 == 0:                        # indicador parpadeante
            label = "[ ESPACIO ] Continuar  >>" if ln.revealed else "[ ESPACIO ] Mostrar todo"
            hud.text(surface, label, (panel.right - 260, panel.bottom - 30), "s", color)
