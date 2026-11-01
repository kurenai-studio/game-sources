"""Selección RTS de drones en modo Comandante (Acto 2 y asedio).

Clic izquierdo sobre un dron de combate lo selecciona; arrastrar con el clic izquierdo traza una caja que selecciona todos los
que quedan dentro. Con selección, el clic derecho ordena: sobre un enemigo o una estructura hostil, foco prioritario de ataque;
en el suelo, vuelo en formación al punto y guardia allí. Sin selección, el clic derecho sigue siendo la orden global de ataque.

La escena aporta: world, camera, fog, combat_drones(), unit_under_cursor(), structure_under(), panel_hit(), ally, menu y
build_choice (ConstructionMixin / Act2State)."""
import math

import pygame
from pygame.math import Vector2

import config as C
from src.core.audio_manager import audio
from src.ui.tooltips import unit_under

COMBAT_KINDS = ("attack", "bomber", "trooper")   # drones que se seleccionan (Explorador y AURA son autónomos)
DRAG_MIN = 6                      # px de arrastre a partir de los que el clic es una caja de selección
FORMATION_GAP = 44                 # px entre drones de la formación


def formation(point, n, gap=FORMATION_GAP):
    """Puntos de una formación en rejilla centrada en `point` para `n` drones."""
    cols = max(1, math.ceil(math.sqrt(n)))
    rows = math.ceil(n / cols)
    return [Vector2(point) + Vector2((i % cols - (cols - 1) / 2) * gap, (i // cols - (rows - 1) / 2) * gap)
            for i in range(n)]


class DroneSelectionMixin:
    selected = ()                  # drones de combate seleccionados
    drag_start = None              # inicio (pantalla) del arrastre del clic izquierdo
    drag_now = None
    focus_marker = None            # [objetivo, segundos]: marcador rojo del foco de ataque

    def selected_drones(self):
        self.selected = [d for d in self.selected if d.alive()]
        return self.selected

    def select_drones(self, drones):
        self.selected = list(drones)
        return self.selected

    def drones_in_box(self, rect):
        """Drones de combate cuyo centro (en pantalla) cae dentro de `rect`."""
        return [d for d in self.combat_drones() if rect.collidepoint(self.camera.to_screen(d.pos))]

    def hostile_under(self, world_pos):
        """Enemigo visible o estructura hostil bajo el ratón (blanco de un foco de ataque), o None."""
        w = self.world
        foes = [u for group in (w.enemies, w.scavengers) for u in group if self.unit_visible(u)]
        unit = unit_under((foes,), world_pos)
        if unit is not None:
            return unit
        for s in getattr(w, "hostile", ()):
            if s.alive() and s.rect.collidepoint(world_pos) and self.unit_visible(s):
                return s
        return None

    # --- órdenes ---
    def order_move(self, point):
        """Vuelo en formación a `point` y guardia allí (atacan lo que se acerque)."""
        drones = self.selected_drones()
        level = getattr(self, "level", None)
        for d, spot in zip(drones, formation(point, len(drones))):
            route = level.waypoints(d.pos, spot) if d.kind == "trooper" and level is not None else ()
            d.give_order(spot, route)
        self.order_marker = [Vector2(point), 2.0]
        audio.play("order")
        self.ally.say(f"{len(drones)} dron(es) en formación hacia el punto marcado: guardia allí.", 3, sender="SISTEMA")
        return len(drones)

    def order_focus(self, target):
        """Foco prioritario: los seleccionados persiguen y atacan a `target` hasta destruirlo."""
        drones = self.selected_drones()
        for d in drones:
            d.give_focus(target)
        self.focus_marker = [target, 2.5]
        audio.play("order")
        self.ally.say(f"Foco de ataque: {len(drones)} dron(es) sobre el objetivo marcado.", 3, sender="SISTEMA")
        return len(drones)

    # --- entrada ---
    def selection_event(self, event):
        """Clics de selección y órdenes. Devuelve True si consumió el evento."""
        if self.menu is not None or self.build_choice is not None:
            self.drag_start = None
            return False
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.panel_hit(event.pos) is not None:
                return False
            self.drag_start = self.drag_now = event.pos
            return True
        if event.type == pygame.MOUSEMOTION and self.drag_start is not None:
            self.drag_now = event.pos
            return False
        if event.type == pygame.MOUSEBUTTONUP and event.button == 1 and self.drag_start is not None:
            start, self.drag_start = self.drag_start, None
            box = pygame.Rect(min(start[0], event.pos[0]), min(start[1], event.pos[1]),
                              abs(event.pos[0] - start[0]), abs(event.pos[1] - start[1]))
            if box.w >= DRAG_MIN or box.h >= DRAG_MIN:
                self.select_drones(self.drones_in_box(box))
            else:
                d = unit_under((self.combat_drones(),), self.camera.to_world(event.pos))
                self.select_drones([d] if d is not None else [])
            return True
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 3 and self.selected_drones():
            wp = self.camera.to_world(event.pos)
            target = self.hostile_under(wp)
            if target is not None:
                self.order_focus(target)
                return True
            if self.structure_under(wp) is not None:
                return False                                     # estructura propia: su menú, como siempre
            self.order_move(wp)
            return True
        if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE and self.selected_drones():
            self.select_drones([])                               # ESC suelta la selección
            return True
        return False

    def tick_selection(self, dt):
        if self.focus_marker is not None:
            self.focus_marker[1] -= dt
            if self.focus_marker[1] <= 0 or not self.focus_marker[0].alive():
                self.focus_marker = None

    # --- dibujo ---
    def draw_selection_rings(self, screen):
        """Anillo cian brillante bajo cada dron seleccionado (se dibuja antes que los drones)."""
        for d in self.selected_drones():
            c = self.camera.to_screen(d.pos)
            r = max(d.rect.w, d.rect.h) // 2 + 7
            ring = pygame.Surface((r * 2 + 8, r * 2 + 8), pygame.SRCALPHA)
            mid = r + 4
            pygame.draw.circle(ring, (*C.CYAN, 60), (mid, mid), r)
            pygame.draw.circle(ring, (*C.CYAN, 255), (mid, mid), r, 2)
            screen.blit(ring, ring.get_rect(center=(round(c.x), round(c.y) + 4)))

    def draw_selection_overlay(self, screen):
        """Caja de arrastre y marcador rojo del foco de ataque."""
        if self.drag_start is not None and self.drag_now is not None:
            box = pygame.Rect(min(self.drag_start[0], self.drag_now[0]), min(self.drag_start[1], self.drag_now[1]),
                              abs(self.drag_now[0] - self.drag_start[0]), abs(self.drag_now[1] - self.drag_start[1]))
            if box.w >= DRAG_MIN or box.h >= DRAG_MIN:
                fill = pygame.Surface(box.size, pygame.SRCALPHA)
                fill.fill((*C.CYAN, 40))
                screen.blit(fill, box)
                pygame.draw.rect(screen, C.CYAN, box, 1)
        if self.focus_marker is not None:
            target, left = self.focus_marker
            c = self.camera.to_screen(target.pos)
            r = max(target.rect.w, target.rect.h) // 2 + 6 + int(6 * (left % 0.5) / 0.5)
            pos = (round(c.x), round(c.y))
            pygame.draw.circle(screen, C.RED, pos, r, 2)
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                pygame.draw.line(screen, C.RED, (pos[0] + dx * (r - 6), pos[1] + dy * (r - 6)),
                                 (pos[0] + dx * (r + 6), pos[1] + dy * (r + 6)), 2)

    def draw_units(self, screen):
        """Sprites del mundo, niebla y, por encima de ella, los drones aliados (con sus anillos de selección)."""
        cam, w = self.camera, self.world
        drones = [d for d in w.drones if d.alive()]
        flying = set(drones)
        cam.draw_group(screen, [s for s in self.visible_sprites() if s not in flying], w.bullets, w.enemy_bullets)
        from src.mechanics import combat
        combat.FX.draw(screen, cam.offset)
        self.fog.draw(screen, cam)
        self.draw_selection_rings(screen)
        cam.draw_group(screen, drones)                               # los aliados nunca quedan tapados por la niebla
