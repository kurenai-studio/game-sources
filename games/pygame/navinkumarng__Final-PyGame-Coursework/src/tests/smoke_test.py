"""Smoke test run by CI: exercises the core game rules, both AI strategies, and
UI module init (headless, via the SDL dummy driver) to catch import/runtime
regressions without needing a real display.

Run with: python3 tests/smoke_test.py
"""
import os
import random
import sys

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from ai.strat1 import strat1
from ai.strat2 import strat2
from core.card import Card
from core.deck import Deck
from core.game import Game
from core.groups import is_valid_group
from core.player import Player


def check(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def test_deck_integrity() -> None:
    deck = Deck()
    check(len(deck.cards) == 90, f"expected 90 cards, got {len(deck.cards)}")

    colours = {"red", "green", "yellow", "blue", "black"}
    check(all(c.colour in colours for c in deck.cards), "unexpected colour in deck")
    check(all(1 <= c.number <= 9 for c in deck.cards), "card number out of range")

    drawn = deck.draw(5)
    check(len(drawn) == 5, "draw(5) should return 5 cards")
    check(len(deck.cards) == 85, "deck should shrink after drawing")

    deck.add_and_shuffle(drawn)
    check(len(deck.cards) == 90, "deck should be back to 90 after returning cards")


def test_group_validation() -> None:
    sequence = [Card("red", 1), Card("red", 2), Card("red", 3)]
    check(is_valid_group(sequence) == "sequence", "3 consecutive same-colour cards should be a sequence")

    a_set = [Card("red", 5), Card("green", 5), Card("yellow", 5), Card("blue", 5)]
    check(is_valid_group(a_set) == "set", "4 same-number different-colour cards should be a set")

    invalid = [Card("red", 1), Card("green", 3), Card("blue", 7)]
    check(is_valid_group(invalid) is None, "unrelated cards should not form a group")


def test_turn_state_resets_fully() -> None:
    players = [Player("A", is_human=False), Player("B", is_human=False)]
    game = Game(players)
    game.turn.used_draw_up_to_3 = True
    game.turn.used_steal = True
    game.turn.draw_up_to_3 = [Card("red", 1)]

    game.next_player()

    check(game.turn.used_draw_up_to_3 is False, "used_draw_up_to_3 should reset")
    check(game.turn.used_steal is False, "used_steal should reset")
    check(game.turn.draw_up_to_3 == [], "draw_up_to_3 buffer should reset")


def test_ai_strategies_play_without_crashing() -> None:
    random.seed(0)
    players = [
        Player("A", is_human=False, ai_type="hard"),
        Player("B", is_human=False, ai_type="easy"),
    ]
    game = Game(players)

    for _ in range(200):
        if game.winner is not None:
            break
        player = game.current_player()
        if player.ai_type == "hard":
            strat1(game)
        else:
            strat2(game)

    check(len(game.deck.cards) + sum(len(p.hand) for p in players) == 90, "no cards should be lost or duplicated")


def test_ui_modules_init_headless() -> None:
    from ui.menu import MenuUI
    from ui.screen import GameUI

    menu = MenuUI()
    menu.draw()
    import pygame
    pygame.quit()

    players = [Player("You", is_human=True), Player("CPU 1", is_human=False, ai_type="easy")]
    game = Game(players)
    ui = GameUI(game)
    ui.initial_deal_done = True
    ui.renderer.draw_background()
    ui.renderer.draw_all_players(ui.game.players)
    pygame.quit()


if __name__ == "__main__":
    tests = [
        test_deck_integrity,
        test_group_validation,
        test_turn_state_resets_fully,
        test_ai_strategies_play_without_crashing,
        test_ui_modules_init_headless,
    ]

    failures = 0
    for test in tests:
        try:
            test()
            print(f"PASS {test.__name__}")
        except Exception as exc:
            failures += 1
            print(f"FAIL {test.__name__}: {exc}")

    if failures:
        sys.exit(1)
    print(f"\n{len(tests)} smoke tests passed.")
