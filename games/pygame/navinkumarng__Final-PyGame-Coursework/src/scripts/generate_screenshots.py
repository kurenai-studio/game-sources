"""Dev tool: renders the menu and an in-progress game board off-screen (SDL dummy
driver, no window) and saves them to screenshots/ for use in the README.

Run with: python3 scripts/generate_screenshots.py
"""
import os
import random
import sys

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pygame

from ai.strat2 import strat2
from core.game import Game
from core.player import Player
from ui.menu import MenuUI
from ui.screen import GameUI

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "screenshots")


def save_menu_screenshot() -> None:
    menu = MenuUI()
    menu.selected_players = 3
    menu.cpu1_ai = "hard"
    menu.cpu2_ai = "easy"
    menu.draw()
    pygame.image.save(menu.screen, os.path.join(OUT_DIR, "menu.png"))
    pygame.quit()


def save_gameplay_screenshot() -> None:
    random.seed(7)
    players = [
        Player("You", is_human=True),
        Player("CPU 1", is_human=False, ai_type="hard"),
        Player("CPU 2", is_human=False, ai_type="easy"),
    ]
    game = Game(players)

    # Play a few AI turns so the log and hands look like a real game in progress.
    for _ in range(3):
        strat2(game)

    ui = GameUI(game)
    ui.initial_deal_done = True
    ui.selected_cards = players[0].hand[:3]
    current = game.current_player()
    ui.set_status("Your turn" if current.is_human else f"{current.name}'s turn")

    ui.renderer.draw_background()
    ui.renderer.draw_deck(ui.game.deck)
    ui.renderer.draw_all_players(ui.game.players, selected_cards=ui.selected_cards)
    ui.renderer.draw_winner(ui.game.winner)
    ui.draw_buttons()
    ui.draw_status()
    ui.renderer.draw_game_log(ui.game.log)
    pygame.image.save(ui.screen, os.path.join(OUT_DIR, "gameplay.png"))
    pygame.quit()


if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    save_menu_screenshot()
    save_gameplay_screenshot()
    print(f"Saved screenshots to {os.path.abspath(OUT_DIR)}")
