"""Pantalla de Victoria de Campaña: estadísticas del asedio y guardado de la victoria (CampaignRun.campaign_completed)."""
import pygame

import config as C
from src.managers.state_machine import GameState, State


class CampaignVictoryState(State):
    def enter(self, stats=()):
        self.stats = list(stats)                       # [(etiqueta, valor)]
        self.button = pygame.Rect(C.WINDOW_WIDTH // 2 - 300, 590, 600, 66)

    def save_and_exit(self):
        """Guarda la victoria en la campaña y vuelve al Menú Principal."""
        self.game.resources.campaign_completed = True
        self.game.autosave("ACT_2_BASE")                         # autoguardado: asedio cerrado con la victoria
        self.game.machine.transition(GameState.MENU)

    def handle_event(self, event):
        if event.type == pygame.KEYDOWN and event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
            self.save_and_exit()
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1 and self.button.collidepoint(event.pos):
            self.save_and_exit()

    def draw(self, screen):
        hud, cx = self.game.hud, C.WINDOW_WIDTH // 2
        screen.fill(C.BG_COLOR)
        for y in range(0, C.WINDOW_HEIGHT, 4):
            pygame.draw.line(screen, (8, 18, 14), (0, y), (C.WINDOW_WIDTH, y))
        hud.text(screen, "¡VICTORIA DE CAMPAÑA!", (cx, 96), "xl", C.GREEN, center=True)
        hud.text(screen, "El núcleo de la Fortaleza enemiga ha caído: sus torretas se apagan y no llegarán más refuerzos.",
                 (cx, 166), "s", C.WHITE, center=True)
        panel = pygame.Rect(cx - 380, 210, 760, 60 + 52 * len(self.stats))
        hud.panel(screen, panel, C.GREEN)
        hud.text(screen, "INFORME DEL ASEDIO", (cx, panel.y + 12), "m", C.CYAN, center=True)
        for i, (label, value) in enumerate(self.stats):
            y = panel.y + 56 + i * 52
            hud.text(screen, label, (panel.x + 30, y), "m", C.DARK_GRAY)
            hud.text(screen, value, (panel.right - 30 - hud.fonts["m"].size(value)[0], y), "m", C.WHITE)
        hover = self.button.collidepoint(pygame.mouse.get_pos())
        hud.panel(screen, self.button, C.YELLOW if hover else C.GREEN)
        hud.text(screen, "[ENTER] GUARDAR VICTORIA Y VOLVER AL MENÚ PRINCIPAL", self.button.center, "m", C.YELLOW, center=True)
