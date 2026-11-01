"""Stage 4 checks: runs the GUI without a window and saves screenshots.
Run: python3 test_stage4.py
"""
import os
import random

os.environ["SDL_VIDEODRIVER"] = "dummy"   # no real window needed
import pygame

import gui
from gui import HEIGHT, WIDTH, PokerApp

gui.AI_DELAY_MS = 0                      # don't wait for the AIs in tests
random.seed(3)
pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
app = PokerApp(screen)
os.makedirs("screenshots", exist_ok=True)


def click(button):
    app.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=button.rect.center))


def run_ai():
    """Let the AIs act until it's the human's turn or the hand ends."""
    while not app.game.hand_over and not app.human_turn():
        app.update()


# 1. Screenshot of a decision point
run_ai()
app.draw()
pygame.image.save(screen, "screenshots/1_your_turn.png")

# 2. Play hands by clicking buttons; grab a showdown screenshot when one happens
shots = {"showdown": False}
for hand in range(80):
    while not app.game.hand_over:
        run_ai()
        if app.human_turn():
            app.draw()     # make sure the buttons are labelled/enabled before clicking
            click(random.choice([app.btn_call, app.btn_call, app.btn_raise, app.btn_fold]))
    app.draw()
    if app.game.street == "showdown" and not shots["showdown"]:
        pygame.image.save(screen, "screenshots/2_showdown.png")
        shots["showdown"] = True
    total = sum(p.chips for p in app.game.players)
    assert total == 3000, total
    click(app.btn_next)    # next hand (or play again after game over)

print("Played 80 hands through the GUI without errors")
print("Screenshots saved to screenshots/")
print("\nStage 4 passed!")
