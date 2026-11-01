# bouncing_ball 🔴
A small pygame project — a red ball bounces around the screen off the walls, and every bounce adds a point to your score. Built as a first taste of Python and pygame, right after a day spent shipping projects in Rust and Go.

## What it does

- Opens a window with a bouncing ball
- Ball reverses direction off any wall
- Score increments by 1 on every bounce
- Score is displayed live on screen

## Requirements

- [Python 3](https://www.python.org/downloads/)
- pip

## Installation & running

```bash
git clone https://github.com/etokiyra/bounc_ball.git
cd bounc_ball

python -m venv venv
source venv/bin/activate

pip install -r requirements.txt

python bounc.py
```

Close the window (or hit the window's close button) to quit.

## Notes

- Every time you open a new terminal to work on this, remember to run `source venv/bin/activate` again before `python bounc.py` — otherwise Python won't find pygame.
- If pygame complains about a missing font module on Linux, install your distro's SDL2_ttf package (e.g. `sudo pacman -S sdl2_ttf` on Arch/Artix) and reinstall pygame.

## License

See [LICENSE](LICENSE).
