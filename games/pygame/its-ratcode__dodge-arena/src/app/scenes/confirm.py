"""A yes / no question over another scene, for actions that throw something away."""

from collections.abc import Callable

import pygame

from app.render.text import draw_text, line_height, wrap_text
from app.scenes.base import Scene, card_rect, dim, draw_card
from app.theme.palette import PALETTE
from app.ui.widgets import Button, ButtonGroup

CARD_W = 500
BUTTON_SIZE = (200, 46)


class ConfirmScene(Scene):
    """Drawn on top of ``back``, which stays frozen behind it. Cancel is focused first,
    so pressing Enter by reflex never confirms; Esc cancels too."""

    def __init__(self, game, back: Scene, title: str, message: str, confirm_label: str,
                 on_confirm: Callable[[], None]) -> None:
        super().__init__(game)
        self.back = back
        self.music = back.music
        self.title = title
        self.lines = wrap_text(message, "body", CARD_W - 70)
        # Sized to its text: title, message, then the buttons.
        height = 26 + line_height("timer") + 14 + len(self.lines) * line_height("body") + 30 + BUTTON_SIZE[1] + 28
        self.card = card_rect(CARD_W, height)
        cancel = Button("Cancel", self.cancel, hotkey="escape", sound="back", size=BUTTON_SIZE, align="center")
        confirm = Button(confirm_label, on_confirm, variant="danger", size=BUTTON_SIZE, align="center")
        cancel.rect.bottomright = (self.card.centerx - 8, self.card.bottom - 28)
        confirm.rect.bottomleft = (self.card.centerx + 8, self.card.bottom - 28)
        self.buttons = ButtonGroup([cancel, confirm])

    def cancel(self) -> None:
        self.game.scene = self.back

    def handle_event(self, event: pygame.event.Event) -> None:
        self.buttons.handle_event(event)

    def update(self, dt: float) -> None:
        self.buttons.update(dt)

    def draw(self, surface: pygame.Surface) -> None:
        self.back.draw(surface)
        dim(surface, 110)
        card = self.card
        draw_card(surface, card)
        title = draw_text(surface, self.title, "timer", PALETTE.text, shadow=True, midtop=(card.centerx, card.y + 26))
        y = title.bottom + 14
        for line in self.lines:
            draw_text(surface, line, "body", PALETTE.text_dim, midtop=(card.centerx, y))
            y += line_height("body")
        self.buttons.draw(surface)
