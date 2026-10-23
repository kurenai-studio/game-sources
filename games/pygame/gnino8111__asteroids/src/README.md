# Asteroids
I built the retro Asteroids game using pygame, with notable features being collision detection and a scoring system.

Goal of the game is to gain points by shooting asteroids with your ship.

The game runs infinitely until your ship collides with an asteroid, then the game ends and prints score to the console.

# How did I make it?
I made the game using the popular game library on python called pygame, I made it without the use of AI to practice coding manually.

In the AI era it's easy to feel like our problem solving skills are being dulled out over time, that's why I challenged myself to make this without the use of an LLM.

# How can you can play it?
1. Clone the repo: "git clone [github_url]"
2. cd into the repo: "cd [directory]"
3. Using uv(reccomended) run: "uv run main.py"

# Controls
| Key   | Action        |
|-------|---------------|
| W / S | Move forward / backward |
| A / D | Rotate left / right |
| Space | Shoot |

# Scoring system

You get points based on what size asteroid you shoot:
| Size   | Points Earned |
|--------|---------------|
| Large  | 25            |
| Medium | 50            |
| Small  | 100           |

Enjoy!
