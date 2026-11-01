"""Menú de selección de campaña (Prioridad 3.B): se abre desde el Terminal Táctico antes de empezar el Acto 2.

Lista los mapas de UNITS.CAMPAIGN_MAPS (cada uno con su dificultad, bases, duración y premios) y, al final, el Acto 2
clásico (Asalto a la Fundición, que escala con el Nivel de Alerta). Añadir un mapa a UNITS.py basta para que aparezca.
Desbloqueo lineal (Fase 6): cada mapa exige haber ganado el anterior; los bloqueados se ven con candado y no se inician."""
import pygame

import config as C
from src.config import UNITS as U
from src.entities.building import Building
from src.managers.state_machine import GameState, State
from src.mechanics.scenario import Scenario

DIFF_COLORS = {"easy": (100, 255, 100), "medium": (255, 200, 50), "hard": (255, 100, 100), None: (180, 140, 255)}
DIFF_LABELS = {"easy": "FÁCIL", "medium": "MEDIA", "hard": "DIFÍCIL", None: "CLÁSICO"}


class CampaignMenuState(State):
    ROW_H = 118
    ROW_STEP = 128

    def enter(self, **kwargs):
        self.maps = list(U.CAMPAIGN_MAPS.keys()) + [None]          # el último: Acto 2 clásico (Fundición, por Alerta)
        self.current_index = 0
        self.selected_map = None
        self.notice = ""
        run = self.game.campaign_run
        self.buttons = []
        for i, key in enumerate(self.maps):
            cfg = U.CAMPAIGN_MAPS.get(key)
            self.buttons.append({
                "locked": not run.is_unlocked(key),
                "completed": key in run.completed_maps,
                "key": key,
                "name": cfg["name"] if cfg else "Asalto a la Fundición (clásico)",
                "description": cfg["description"] if cfg else "El Acto 2 de siempre: 5 oleadas, bases según el Nivel de Alerta y la Fundición",
                "difficulty": cfg["difficulty"] if cfg else None,
                "rect": pygame.Rect(100, 118 + i * self.ROW_STEP, 1080, self.ROW_H),
                "selected": i == 0,
            })

    # --- selección ---
    def _update_selection(self):
        for i, button in enumerate(self.buttons):
            button["selected"] = i == self.current_index

    def start_campaign(self, key):
        """Fija el mapa y empieza el Acto 2. CampaignRun.start_map reinicia el reloj, los premios, la niebla, las bases
        enemigas y a AURA, y traslada la base guardada al Centro de Control del mapa (sin salirse de él).
        Un mapa bloqueado no se inicia: devuelve False y avisa de qué mapa hay que ganar antes."""
        run = self.game.campaign_run
        if not run.is_unlocked(key):
            need = U.CAMPAIGN_MAPS[run.required_map(key)]["name"]
            self.notice = f"BLOQUEADO: gana «{need}» para desbloquear este mapa."
            return False
        self.selected_map = key
        run.start_map(key, res=self.game.resources)
        self.game.machine.transition(GameState.ACT_2_SETUP)
        return True

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_UP:
                self.current_index = max(0, self.current_index - 1)
                self._update_selection()
            elif event.key == pygame.K_DOWN:
                self.current_index = min(len(self.buttons) - 1, self.current_index + 1)
                self._update_selection()
            elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
                self.start_campaign(self.buttons[self.current_index]["key"])
            elif event.key == pygame.K_ESCAPE:
                self.game.machine.transition(GameState.ACT_2_BASE)      # volver al Terminal Táctico
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for i, button in enumerate(self.buttons):
                if button["rect"].collidepoint(event.pos):
                    self.current_index = i
                    self._update_selection()
                    self.start_campaign(button["key"])
                    return

    # --- dibujo ---
    @staticmethod
    def _draw_lock(screen, center):
        """Candado: arco del grillete sobre un cuerpo rectangular."""
        x, y = center
        pygame.draw.arc(screen, C.DARK_GRAY, (x - 9, y - 18, 18, 20), 0, 3.1416, 3)
        pygame.draw.rect(screen, C.DARK_GRAY, (x - 12, y - 8, 24, 18), border_radius=3)
        pygame.draw.circle(screen, (30, 34, 44), (x, y), 3)

    @staticmethod
    def summary(button):
        """Líneas de datos de un mapa: bases, oleadas, duración y premios."""
        if button["key"] is None:
            return ["Bases según el Nivel de Alerta (1-3) · 5 oleadas + Fundición Renegada",
                    "Premios: +100 chatarra y +1 núcleo por base destruida"]
        cfg = U.CAMPAIGN_MAPS[button["key"]]
        sc = Scenario(button["key"])
        rewards = ", ".join(r["id"] for r in cfg["rewards"])
        unlocks = [Building.LABELS[k] for k, (source, value) in U.STRUCTURE_UNLOCKS.items() if source == "map" and value == button["key"]]
        if unlocks:
            rewards += " · Desbloquea: " + ", ".join(unlocks)
        foundry = " + Fundición" if cfg.get("foundry") else ""
        return [f"{cfg['enemy_bases']} base(s) enemiga(s){foundry} · {len(sc.plan)} oleadas · "
                f"{cfg['total_duration'] // 60} min · mapa {cfg['map_size'][0]}x{cfg['map_size'][1]}",
                "Premios: " + rewards]

    def draw(self, screen):
        hud = self.game.hud
        screen.fill((10, 14, 24))
        for y in range(0, C.WINDOW_HEIGHT, 4):
            pygame.draw.line(screen, (14, 20, 32), (0, y), (C.WINDOW_WIDTH, y))
        hud.text(screen, "SELECCIONA CAMPAÑA", (100, 36), "l", C.CYAN)
        hud.text(screen, "Cada mapa es un escenario del Acto 2: destruye todas las bases enemigas para ganar", (102, 84), "s",
                 C.DARK_GRAY, shadow=False)
        mouse = pygame.mouse.get_pos()
        for button in self.buttons:
            rect, diff = button["rect"], button["difficulty"]
            color = DIFF_COLORS[diff]
            selected = button["selected"] or rect.collidepoint(mouse)
            hud.panel(screen, rect, C.GREEN if selected else (80, 110, 150))
            if selected:
                pygame.draw.rect(screen, C.GREEN, rect, 3)
            locked = button["locked"]
            title_color = C.DARK_GRAY if locked else (C.GREEN if selected else C.WHITE)
            hud.text(screen, button["name"], (rect.x + 20, rect.y + 10), "m", title_color)
            hud.text(screen, DIFF_LABELS[diff], (rect.right - 120, rect.y + 12), "m", C.DARK_GRAY if locked else color)
            if locked:
                self._draw_lock(screen, (rect.right - 160, rect.y + 24))
                need = U.CAMPAIGN_MAPS[self.game.campaign_run.required_map(button["key"])]["name"]
                hud.text(screen, f"BLOQUEADO · gana «{need}» para desbloquearlo", (rect.x + 20, rect.y + 42), "s",
                         C.DARK_GRAY, shadow=False)
            else:
                desc = button["description"] + ("  ·  GANADO (repetirlo no da recursos)" if button["completed"] else "")
                hud.text(screen, desc, (rect.x + 20, rect.y + 42), "s", (180, 186, 205), shadow=False)
            for j, line in enumerate(self.summary(button)):
                hud.text(screen, line, (rect.x + 20, rect.y + 66 + j * 20), "s",
                         (80, 90, 105) if locked else (120, 160, 190), shadow=False)
        if self.notice:
            hud.text(screen, self.notice, (C.WINDOW_WIDTH // 2, C.WINDOW_HEIGHT - 54), "s", C.ORANGE, center=True)
        hud.text(screen, "↑/↓ navegar · ENTER o clic: comenzar · ESC: volver al Terminal",
                 (C.WINDOW_WIDTH // 2, C.WINDOW_HEIGHT - 28), "s", C.DARK_GRAY, center=True)
