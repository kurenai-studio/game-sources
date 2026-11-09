"""The pause scene: the run frozen behind a card with its numbers so far."""

import pygame

from app.render.text import draw_text
from app.scenes.base import Scene, card_rect, dim, draw_card, draw_stat_tile
from app.scenes.confirm import ConfirmScene
from app.scenes.play import PlayScene, is_free_escape
from app.theme.palette import PALETTE, danger_color
from app.theme.styles import BUTTON_GAP, BUTTON_HEIGHT, BUTTON_WIDTH, CARD_PAD
from app.ui.widgets import Button, ButtonList
from app.util.timefmt import fmt_time

TILES_TOP = 86          # px below the card's top: the row of stat tiles
TILE_H = 62
BUTTONS_TOP = 176       # px below the card's top: the first button


class PauseScene(Scene):
    """Nothing updates while paused, so the run continues exactly where it stopped."""

    music = "ducked"

    def __init__(self, game, play: PlayScene) -> None:
        super().__init__(game)
        self.play = play
        keys = game.settings.keybinds                  # read live: a key rebound from here works at once
        buttons = [
            Button("Resume", self.resume, hotkey=lambda: keys["pause"], primary=True, icon="play"),
            Button("Restart", self.ask("Restart run?", "Your current run ends. Coins you picked up are kept.",
                                       "Restart", game.start_run),
                   hotkey=lambda: keys["restart"], icon="restart"),
            Button("How to play", game.open_guide, hotkey="h", icon="book"),
            Button("Settings", game.open_settings, icon="gear"),
            Button("Main menu", self.ask("Leave this run?", "You'll return to the main menu. Coins you picked up "
                                         "are kept.", "Leave run", game.open_main_menu), hotkey="m", icon="exit"),
            Button("Quit game", self.ask("Quit the game?", "Your progress and coins are saved.", "Quit",
                                         game.quit), variant="danger", icon="exit"),
        ]
        stack = len(buttons) * BUTTON_HEIGHT + (len(buttons) - 1) * BUTTON_GAP
        self.card = card_rect(BUTTON_WIDTH + CARD_PAD * 2 + 60, BUTTONS_TOP + stack + CARD_PAD)
        self.buttons = ButtonList(buttons, center=(self.card.centerx, self.card.top + BUTTONS_TOP + stack // 2))

    def resume(self) -> None:
        self.game.scene = self.play

    def ask(self, title: str, message: str, label: str, action):
        """A button action that asks first: the run is only thrown away after a second, explicit yes."""
        def open_dialog() -> None:
            self.game.scene = ConfirmScene(self.game, self, title, message, label, action)
        return open_dialog

    def handle_event(self, event: pygame.event.Event) -> None:
        if event.type == pygame.KEYDOWN and is_free_escape(event, self.game.settings):
            self.resume()
            return
        self.buttons.handle_event(event)

    def update(self, dt: float) -> None:
        self.buttons.update(dt)

    def draw(self, surface: pygame.Surface) -> None:
        self.game.draw_world(surface)
        dim(surface, 150)
        card = self.card
        draw_card(surface, card)
        draw_text(surface, "PAUSED", "heading", PALETTE.text, shadow=True, midtop=(card.centerx, card.top + 22))
        # Three tiles: the run so far.
        world = self.game.world
        tiles = (("TIME", fmt_time(world.survival_time), PALETTE.text),
                 ("COINS", f"+{world.coins_picked}", PALETTE.coin),
                 ("DANGER", f"{int(world.danger * 100)}%", danger_color(world.danger)))
        inner = card.width - CARD_PAD * 2
        tile_w = (inner - 2 * 10) // 3
        for i, (label, value, color) in enumerate(tiles):
            rect = pygame.Rect(card.x + CARD_PAD + i * (tile_w + 10), card.top + TILES_TOP, tile_w, TILE_H)
            draw_stat_tile(surface, rect, label, value, color)
        self.buttons.draw(surface)
