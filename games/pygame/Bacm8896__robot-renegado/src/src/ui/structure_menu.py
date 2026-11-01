"""Menú emergente de una estructura (clic derecho): rutas de mejora A/B de las torretas (dual-build) y venta.

Cada fila muestra el nombre, una descripción corta y el costo con iconos (chatarra, núcleos). Se elige con las
teclas 1-9 o con el clic izquierdo."""
import textwrap

import pygame

import config as C


class StructureMenu:
    WIDTH = 380
    HEADER = 34
    WRAP = 44

    def __init__(self, building, options):
        """`options`: [{"label", "desc", "scrap", "cores", "action", "enabled"}]; action = ("route", "A"|"B") | ("wall_up", nivel) | ("sell", None)."""
        self.building = building
        self.options = options

    # --- geometría ---
    def _lines(self, opt):
        return textwrap.wrap(opt.get("desc", ""), self.WRAP)[:2]

    def _row_height(self, opt):
        return 24 + 15 * len(self._lines(opt)) + 4

    def rect(self, camera):
        """Rectángulo en pantalla: a la derecha de la estructura, o a la izquierda si no cabe."""
        c = camera.to_screen(self.building.pos)
        h = self.HEADER + sum(self._row_height(o) for o in self.options) + 8
        x = int(c.x) + self.building.rect.w // 2 + 12
        if x + self.WIDTH > C.WINDOW_WIDTH - 8:
            x = int(c.x) - self.building.rect.w // 2 - 12 - self.WIDTH
        y = max(8, min(C.WINDOW_HEIGHT - h - 80, int(c.y) - h // 2))
        return pygame.Rect(max(8, x), y, self.WIDTH, h)

    def row_rect(self, camera, index):
        r = self.rect(camera)
        y = r.y + self.HEADER + sum(self._row_height(o) for o in self.options[:index])
        return pygame.Rect(r.x + 6, y, r.w - 12, self._row_height(self.options[index]) - 4)

    def hit(self, camera, pos):
        """Índice de la opción bajo `pos` (pantalla) o None."""
        for i in range(len(self.options)):
            if self.row_rect(camera, i).collidepoint(pos):
                return i
        return None

    # --- dibujo ---
    def draw(self, surface, hud, camera, resources=None):
        r = self.rect(camera)
        b = self.building
        hud.panel(surface, r, C.YELLOW)
        label = b.label
        hud.text(surface, f"{label}  {max(0, int(b.hp))}/{b.max_hp}", (r.x + 10, r.y + 8), "s", C.YELLOW)
        mouse = pygame.mouse.get_pos()
        for i, opt in enumerate(self.options):
            row = self.row_rect(camera, i)
            enabled = opt["enabled"]
            if enabled and row.collidepoint(mouse):
                pygame.draw.rect(surface, (40, 48, 70), row)
            pygame.draw.rect(surface, C.CYAN if enabled else C.DARK_GRAY, row, 1)
            hud.text(surface, f"[{i + 1}] {opt['label']}", (row.x + 6, row.y + 4), "s",
                     C.WHITE if enabled else C.DARK_GRAY)
            self._draw_cost(surface, hud, opt, row, resources)
            if opt.get("unlocked") is False:                          # rama sin desbloquear en el Terminal: candado
                x, y = row.right - 14, row.y + 16
                pygame.draw.arc(surface, C.ORANGE, (x - 5, y - 11, 10, 12), 0, 3.1416, 2)
                pygame.draw.rect(surface, C.ORANGE, (x - 7, y - 4, 14, 11), border_radius=2)
            for j, line in enumerate(self._lines(opt)):
                hud.text(surface, line, (row.x + 10, row.y + 24 + 15 * j), "s", (150, 156, 175) if enabled else C.DARK_GRAY,
                         shadow=False)

    @staticmethod
    def _draw_cost(surface, hud, opt, row, resources):
        scrap, cores, energy = opt["scrap"], opt["cores"], opt.get("energy", 0)
        x = row.right - 150
        y = row.y + 4
        if scrap < 0 or cores < 0:                                    # venta: lo que devuelve, en verde
            for kind, value in (("scrap", -scrap), ("cores", -cores)):
                if value > 0:
                    hud.icon(surface, kind, (x + 6, y + 8))
                    txt = f"+{value}"
                    hud.text(surface, txt, (x + 15, y), "s", C.GREEN, shadow=False)
                    x += 15 + hud._render("s", txt, C.GREEN).get_width() + 8
        elif scrap or cores or energy:
            afford = (resources is None or resources.can_afford(scrap), resources is None or resources.cores >= cores,
                      resources is None or energy <= resources.energy_cap - resources.energy)
            hud.cost_row(surface, (x, y), scrap, cores, energy, afford)
