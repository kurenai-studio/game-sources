# py2ports Breakout

Clear three authored brick layouts with three lives. Launch each ball explicitly;
later levels move faster. Clear the third level to win.

A complete desktop and ARM64 Knulli game, created through **Use this template**
from [py2port_pygame_template](https://github.com/OscarJHernandez/py2port_pygame_template).

## Play on desktop

You need Python 3.11+ and Make. No Docker or handheld is needed.

```sh
git clone https://github.com/OscarJHernandez/py2ports_breakout.git
cd py2ports_breakout
make setup  # or: make setup PYTHON=python3.12
make run
make test
```

Desktop dependencies stay pinned to `pygame==2.6.1`. The entrypoint is
`src/run.py`; headless verification is `python src/run.py --smoke-test` after setup.

## Controls

| Action | Keyboard | Controller |
| --- | --- | --- |
| Move paddle | Left/right arrows / A/D | D-pad / left stick |
| Play / resume / launch | Enter / Space | A |
| Pause / resume | P | Start |
| Pause / back to menu / exit from menu | Escape | B / Back |
| Exit | Q / close window | B from menu |

SDL controller mappings provide standard buttons. Unmapped joysticks use their
hat or axes 0/1, button 0 to confirm, 1/6 to go back and 7 to pause. Connect a
controller before launch or hot-plug it. Remap nonstandard devices through SDL
`SDL_GAMECONTROLLERCONFIG`. Loss of window focus pauses the game.

Graphics scale from 640×480 with letterboxing. Set
`BREAKOUT_FULLSCREEN=1` for fullscreen; py2ports configures this on the handheld.
Scores use `PY2PORTS_DATA_DIR` when deployed, or
`$XDG_DATA_HOME/py2ports_breakout/scores.json` (default `~/.local/share/...`) on desktop.
Unreadable or unwritable scores do not prevent play.

## Play on Knulli

In a separate [py2ports](https://github.com/OscarJHernandez/py2ports) checkout:

```sh
make setup
make check-device
make deploy GAME=py2ports_breakout
# If knulli cannot be resolved, append DEVICE_HOST=192.168.1.50.
```

Open **Ports → py2ports_breakout**. The existing runtime uses Python 3.12.8 and
Pygame-CE 2.5.6. Knulli build, runtime and deployment configuration stays in
py2ports. Physical display, controls and firmware compatibility still require
verification on your device. Automated tests never contact a handheld.

## Template origin and license

MIT licensed; retain [LICENSE](LICENSE) and this attribution. The template's
original movement-demo code and thin entrypoint originated in Oscar Javier
Hernandez's `python_game` revision `8a63594750dea6553a5e44dabe6e7a737371b747`.
The owner authorized public MIT redistribution of the template and derived games.
This repository has independent template-generated history; `TEMPLATE_ORIGIN.json`
records the source template revision and initial tree. Breakout gameplay,
procedural artwork and tests were developed after generation. Pygame and its
default font retain their own licenses. This project is unofficial and not
affiliated with Knulli.
