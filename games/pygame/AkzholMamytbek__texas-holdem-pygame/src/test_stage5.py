"""Stage 5 checks: grammar, animations, speech bubbles, stats.
Run: python3 test_stage5.py
"""
import os
import random

os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["SDL_AUDIODRIVER"] = "dummy"
import pygame

import gui
from gui import HEIGHT, WIDTH, PokerApp

random.seed(11)
pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
os.makedirs("screenshots", exist_ok=True)


def frame(app, wait_ms=0):
    pygame.time.wait(wait_ms)
    app.update()
    app.draw()


# 1. Grammar: the human is "You raise", bots are "Shark raises"
app = PokerApp(screen)
log = " ".join(app.game.log)
assert "You has" not in log and "You posts" not in log, log
print("Grammar OK:", app.game.log[0])

# 2. Deal animation: right after the deal, cards are still in flight
frame(app, 0)
frame(app, 120)
pygame.image.save(screen, "screenshots/3_dealing.png")
assert any(start > pygame.time.get_ticks() - gui.DEAL_MS for start in app.anim.values())
print("Deal animation OK (cards in flight)")

# 3. Play hands with the real AI delay until an AI says something
gui.AI_DELAY_MS = 0
shot = False
for _ in range(60):
    while not app.game.hand_over:
        frame(app)
        if app.human_turn():
            app.human_act(random.choice(["call", "call", "raise", "fold"]), app.slider.value)
        if not shot and app.bubbles and not app.game.hand_over:
            frame(app, 900)
            pygame.image.save(screen, "screenshots/4_table_talk.png")
            shot = True
    frame(app)
    if app.game.game_over:
        app.new_game()
    else:
        app.start_hand()
assert shot, "nobody talked in 60 hands"
st = app.stats
assert st["played"] > 0 and 0 <= st["won"] <= st["played"]
print(f"Table talk OK, stats tracked: you won {st['won']}/{st['played']}")

# 4. Payout animation: chips fly to the winner
while not app.game.hand_over:
    frame(app)
    if app.human_turn():
        app.human_act("call")
frame(app)
frame(app, 250)
pygame.image.save(screen, "screenshots/5_payout.png")
print("Screenshots saved")
print("\nStage 5 passed!")
