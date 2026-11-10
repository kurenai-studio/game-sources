#Name:Ashish Pahari 
#ERP=:RU-26-02321
#Problem Statement:62: Catch the Falling Objects Game

**Course:** Bachelor of Computer Applications (BCA)  
**Language:** Python 3  
**Library:** Pygame  
**Project file:** `one.py`

# Catch the Falling Objects 🎮

## 1. About the Project

**Catch the Falling Objects** is a small game made with Python and Pygame.

A ball falls from the top of the screen. The player moves a basket left and right to catch it.

- Catch the ball: Get 1 point.
- Miss the ball: Lose 1 life.
- Lose all 3 lives: The game is over.

Only **one ball falls at a time**.

## 2. What We Used

- **Python 3:** The programming language used to build the game.
- **Pygame:** A Python library used to make the game window, draw the ball and basket, and read keyboard controls.
- **Random module:** Chooses a new position for the ball.
- **Rectangles and collision detection:** Check whether the ball touches the basket.

## 3. How We Built the Game

We built the game step by step:

1. Created a game window that is 500 pixels wide and 600 pixels high.
2. Made a blue basket at the bottom of the screen.
3. Made one red ball appear at a random position at the top.
4. Added LEFT and RIGHT arrow controls to move the basket smoothly.
5. Made the ball fall down the screen.
6. Checked whether the ball touches the basket.
7. Added a score that increases when the ball is caught.
8. Added 3 lives. A missed ball removes one life.
9. Added a Game Over message when all lives are lost.

## 4. Main Game Rules

| Item | Value / Rule |
|---|---|
| Window size | 500 × 600 pixels |
| Basket size | 80 × 20 pixels |
| Basket starting position | x = 210, y = 560 |
| Ball size | 20 × 20 pixels |
| Ball starting position | Random x-position at the top |
| Ball speed | 5 pixels per frame |
| Starting lives | 3 |
| Catching a ball | Score increases by 1 |
| Missing a ball | Lives decrease by 1 |
| Number of balls | One at a time |

**Note:** The basket moves smoothly while an arrow key is held. Its speed is set in the `basket_speed` variable in `one.py`.

## 5. Requirements

Before starting, make sure you have:

- Python 3 installed.
- Pygame installed.
- The project file named `one.py`.

## 6. How to Install Pygame

Open Command Prompt or a terminal and type:

```bash
python -m pip install pygame
```

Press Enter and wait for the installation to finish.

## 7. How to Start the Game

1. Save the game code in a file named `one.py`.
2. Open the folder containing `one.py`.
3. Open Command Prompt or a terminal in that folder.
4. Type:

```bash
python one.py
```

5. Press Enter. The game window will open.

## 8. How to Play

- Press and hold the **LEFT arrow** to move the basket left.
- Press and hold the **RIGHT arrow** to move the basket right.
- Catch the red ball with the blue basket.
- Press **ESC** to close the game.

## 9. Score and Lives

- The game starts with a score of **0** and **3 lives**.
- Every caught ball gives **1 point**.
- Every missed ball takes away **1 life**.
- When lives become **0**, the game shows **GAME OVER** and your final score.

## 10. Important Code Parts

| Code / Function | What it does |
|---|---|
| `pygame.init()` | Starts Pygame |
| `pygame.display.set_mode()` | Creates the game window |
| `random.randint()` | Picks a random ball position |
| `pygame.key.get_pressed()` | Checks which key is being held |
| `pygame.Rect()` | Creates rectangles for collision checking |
| `colliderect()` | Checks whether the ball touches the basket |
| `clock.tick(60)` | Limits the game to about 60 frames per second |

## 11. Project File

```text
Catch-the-Falling-Objects/
│
├── one.py
└── README.md
```

No extra image or data files are needed. The game draws the basket and ball using Pygame.

## 12. Troubleshooting

**Problem: `No module named pygame`**

Install Pygame:

```bash
python -m pip install pygame
```

**Problem: The game does not start**

- Check that Python 3 is installed.
- Check that the file is named `one.py`.
- Run the command from the folder where `one.py` is saved.

**Problem: The basket does not move**

- Click inside the game window first.
- Use the LEFT and RIGHT arrow keys.

## 13. Conclusion

This project helped us learn Python, Pygame, keyboard controls, coordinates, random numbers, loops, conditions, and collision detection.

The aim is simple: **Move the basket, catch the ball, and score points!**

*Mentored by:* [Mr. Satyaprakash Sethy](https://github.com/SATYAPRAKASHSETHY)

*GitHub:* [@SATYAPRAKASHSETHY](https://github.com/SATYAPRAKASHSETHY)

*Role:* Python Mentor / Technical Guide
