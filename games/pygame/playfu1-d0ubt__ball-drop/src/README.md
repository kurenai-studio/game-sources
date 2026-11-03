# Ball Drop
 
A catch-the-falling-balls game made with Python and Pygame. Move the basket, catch as many balls as you can, and don't run out of lives.
 
It's a Python version of a Scratch game I made earlier [Basic Ball Drop](https://scratch.mit.edu/projects/1388327647/).
 
## What it does
 
### How to play
 
- Balls of different colours fall from the top of the screen.
- Catch them in the basket to score a point.
- Every ball you miss costs a life. You start with 3.
- Every 5 points the balls and the basket speed up, and you gain an extra life.
- When you run out of lives the game ends. Press **R** to play again.
### Controls
 
| Key | Action |
| --- | --- |
| A or Left arrow | Move left |
| D or Right arrow | Move right |
| R | Restart (on the game over screen) |
 
### How it works
 
- **Game states:** a `game_over` variable decides whether the game is being played or the game over screen is showing.
- **Balls:** each ball is a small dictionary (its `Rect`, an exact float `y` position and a colour), and all the balls on screen live in one list. A timer adds a new ball every 1.25 seconds.
- **Movement:** speeds are in pixels per second and multiplied by the time since the last frame (`dt`), so the game runs at the same speed whatever the frame rate. Positions are kept as floats because a Rect only stores whole pixels.
- **Collisions:** `basket.colliderect(ball)` counts a catch. A ball that passes below the screen counts as a miss.
- **Functions:** `make_ball()` creates a ball, `game()` runs one frame of play, and `reset_game()` puts everything back to its starting values.
- **Speed cap:** ball and basket speed are both capped at 750 pixels per second so the game stays playable.
## How to run
 
You need Python 3 and Pygame.
 
```bash
git clone git@github.com:playfu1-d0ubt/ball-drop.git
cd ball-drop
python3 -m venv venv
source venv/bin/activate
pip install pygame
python ball-drop.py
```
 
Tested with Python 3.12 and Pygame 2.6.1 on Linux Mint.
 
## Limitations
 
- The high score is not saved between games.
- No sound effects and no pause key.
- One difficulty level, with no start menu.
- All balls are good balls. There are no power-ups or bad balls.
- The code is in one file, with no classes or tests.
## What I learned
 
**What I practised:** the Pygame game loop, game states, collisions with `Rect`, and frame-rate independent movement using `dt`.
 
**Moving from Scratch to Python:** in Scratch the sprites, collisions and loop are built in. In Pygame I had to build each of those myself, such as storing every ball as a dictionary in a list and checking collisions by hand.
 
**Ideas for later:**
 
- Save a high score between games
- Sound effects
- Different ball types (for example, bad balls that cost a life if caught)
- A start menu with difficulty options