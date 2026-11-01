# ruff: noqa: E402
from __future__ import annotations

import os

os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")

import pygame

from python_game_suite.common.game_template import Game
from python_game_suite.lucky9.colors import (
    BLACK,
    CARD_BACK,
    CARD_FACE,
    GOLD,
    GRAY,
    RED,
    TABLE_GREEN,
    WHITE,
)
from python_game_suite.lucky9.gui_engine import (
    BET_OPTIONS,
    Lucky9Session,
    Phase,
)

WIDTH = 960
HEIGHT = 600
FPS = 60
CARD_W = 70
CARD_H = 100
CARD_GAP = 12
SUIT_LABELS = {
    chr(9830): ("D", RED),
    chr(9829): ("H", RED),
    chr(9824): ("S", BLACK),
    chr(9827): ("C", BLACK),
    "D": ("D", RED),
    "H": ("H", RED),
    "S": ("S", BLACK),
    "C": ("C", BLACK),
}


class Lucky9Gui(Game):
    def __init__(self, session: Lucky9Session | None = None):
        pygame.font.init()
        self.session = session or Lucky9Session()
        self.buttons: dict[str, pygame.Rect] = {}
        self.font_title = pygame.font.Font(None, 52)
        self.font = pygame.font.Font(None, 30)
        self.font_small = pygame.font.Font(None, 22)

    @staticmethod
    def get_name():
        return "Lucky9 (GUI)"

    @property
    def dealer_revealed(self) -> bool:
        return self.session.phase in (
            Phase.ROUND_OVER,
            Phase.GAME_OVER,
        )

    def run(self) -> None:
        pygame.init()
        pygame.display.set_caption("Lucky 9")
        screen = pygame.display.set_mode((WIDTH, HEIGHT))
        clock = pygame.time.Clock()
        running = True
        while running:
            for event in pygame.event.get():
                running = self.handle_event(event)
                if not running:
                    break
            self.render(screen)
            pygame.display.flip()
            clock.tick(FPS)
        pygame.quit()

    def handle_event(self, event) -> bool:
        if event.type == pygame.QUIT:
            return False

        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_q:
                return False
            if self.session.phase is Phase.BETTING and event.key in (
                pygame.K_1,
                pygame.K_2,
                pygame.K_3,
            ):
                index = event.key - pygame.K_1
                self.session.place_bet(BET_OPTIONS[index])
            elif self.session.phase is Phase.PLAYER_TURN:
                if event.key == pygame.K_h:
                    self.session.hit()
                elif event.key == pygame.K_g:
                    self.session.stand()
            elif self.session.phase is Phase.ROUND_OVER and event.key == pygame.K_n:
                self.session.next_round()
            elif self.session.phase is Phase.GAME_OVER and event.key == pygame.K_r:
                self.session.restart()

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for action, rect in self.buttons.items():
                if rect.collidepoint(event.pos):
                    return self._run_action(action)

        return True

    def _run_action(self, action: str) -> bool:
        if action == "quit":
            return False
        if action.startswith("bet:"):
            self.session.place_bet(int(action.split(":", 1)[1]))
        elif action == "hit":
            self.session.hit()
        elif action == "stand":
            self.session.stand()
        elif action == "next":
            self.session.next_round()
        elif action == "restart":
            self.session.restart()
        return True

    def render(self, surface) -> None:
        surface.fill(TABLE_GREEN)
        self.buttons = {}

        title = self.font_title.render("Lucky 9", True, GOLD)
        surface.blit(title, (WIDTH // 2 - title.get_width() // 2, 12))

        stats = [
            f"Level: {self.session.level}",
            f"You: {self.session.player.money:,}",
            f"Dealer: {self.session.dealer.name} "
            f"({max(self.session.dealer.money, 0):,})",
            f"Bet: {self.session.bet:,}",
        ]
        x = 24
        for text in stats:
            rendered = self.font_small.render(text, True, WHITE)
            surface.blit(rendered, (x, 72))
            x += rendered.get_width() + 28

        revealed = self.dealer_revealed
        dealer_value = self.session.dealer.getHandValue() if revealed else "??"
        self._draw_hand(
            surface,
            self.session.dealer.hand,
            (WIDTH // 2 - CARD_W, 130),
            f"Dealer: {dealer_value}",
            face_up=revealed,
            hidden_index=1,
        )
        self._draw_hand(
            surface,
            self.session.player.hand,
            (WIDTH // 2 - CARD_W, 330),
            f"You: {self.session.player.getHandValue()}",
            face_up=True,
        )

        message = self.font.render(self.session.message, True, GOLD)
        surface.blit(
            message,
            (WIDTH // 2 - message.get_width() // 2, 470),
        )
        self._draw_buttons(surface)

    def _draw_hand(
        self,
        surface,
        hand,
        origin,
        label,
        face_up=True,
        hidden_index=None,
    ) -> None:
        text = self.font_small.render(label, True, WHITE)
        surface.blit(text, (origin[0], origin[1] - 26))
        if not hand:
            empty = self.font_small.render("No cards", True, GRAY)
            surface.blit(empty, (origin[0], origin[1] + 30))
            return
        for index, card in enumerate(hand):
            shown = face_up or index != hidden_index
            self._draw_card(
                surface,
                card,
                (origin[0] + index * (CARD_W + CARD_GAP), origin[1]),
                shown,
            )

    def _draw_card(self, surface, card, pos, face_up) -> None:
        rect = pygame.Rect(pos, (CARD_W, CARD_H))
        if not face_up:
            pygame.draw.rect(surface, CARD_BACK, rect, border_radius=8)
            pygame.draw.rect(surface, WHITE, rect, 2, border_radius=8)
            inner = rect.inflate(-20, -20)
            pygame.draw.rect(surface, WHITE, inner, 1, border_radius=4)
            label = self.font_small.render("L9", True, WHITE)
            surface.blit(
                label,
                (
                    rect.centerx - label.get_width() // 2,
                    rect.centery - label.get_height() // 2,
                ),
            )
            return

        pygame.draw.rect(surface, CARD_FACE, rect, border_radius=8)
        pygame.draw.rect(surface, BLACK, rect, 2, border_radius=8)
        rank, suit = card
        label, color = SUIT_LABELS.get(suit, ("?", BLACK))
        rank_text = self.font.render(str(rank), True, color)
        suit_text = self.font.render(label, True, color)
        surface.blit(rank_text, (pos[0] + 8, pos[1] + 8))
        surface.blit(suit_text, (pos[0] + 8, pos[1] + 44))

    def _draw_buttons(self, surface) -> None:
        x = 24
        for amount in BET_OPTIONS:
            action = f"bet:{amount}"
            rect = pygame.Rect(x, 520, 140, 46)
            enabled = (
                self.session.phase is Phase.BETTING
                and amount <= self.session.player.money
            )
            self._draw_button(surface, rect, f"{amount:,}", enabled, action)
            x += 154

        actions = []
        if self.session.phase is Phase.PLAYER_TURN:
            actions = [("H Hit", "hit"), ("G Stand", "stand")]
        elif self.session.phase is Phase.ROUND_OVER:
            actions = [("N Next", "next")]
        elif self.session.phase is Phase.GAME_OVER:
            actions = [("R Restart", "restart")]
        actions.append(("Q Quit", "quit"))

        x = 520
        for label, action in actions:
            rect = pygame.Rect(x, 520, 130, 46)
            self._draw_button(surface, rect, label, True, action)
            x += 144

    def _draw_button(self, surface, rect, label, enabled, action) -> None:
        color = GOLD if enabled else GRAY
        pygame.draw.rect(surface, color, rect, border_radius=8)
        pygame.draw.rect(surface, BLACK, rect, 2, border_radius=8)
        text = self.font_small.render(label, True, BLACK)
        surface.blit(
            text,
            (
                rect.centerx - text.get_width() // 2,
                rect.centery - text.get_height() // 2,
            ),
        )
        self.buttons[action] = rect
