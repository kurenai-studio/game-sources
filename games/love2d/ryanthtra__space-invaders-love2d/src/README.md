# Space Invaders — LÖVE 2D clone

A self-contained classic Space Invaders clone for [LÖVE](https://love2d.org) 11.x.
No external assets: sprites and sound effects are generated procedurally at load time.

## Run

With LÖVE installed, from this folder:

```
love .
```

or point LÖVE at the folder explicitly:

```
"path\to\love\love.exe" path\to\repo_folder
```

## Controls

| Key             | Action            |
| --------------- | ----------------- |
| ← → or A / D    | Move the ship     |
| Space           | Fire              |
| P               | Pause             |
| M               | Mute / unmute     |
| Esc             | Quit              |

## Features

- 5×11 invader grid with the classic march: drops and reverses at the edges,
  and speeds up as the ranks thin out
- Destructible shields that erode from both player and enemy fire
- Mystery UFO crossing the top for bonus points
- Waves with escalating difficulty, score + session high score, lives with
  respawn invulnerability
- Procedural retro sound: shoot blips, explosions, UFO ding and the
  four-note marching bass line

## Smoke test

```
SI_SMOKE_TEST=1 love .
```

Auto-starts a game, auto-plays (weaving + firing) for ~10 seconds and exits,
writing `smoke_result.txt` (`SMOKE OK ...`). Any runtime error is written to
`love_error.log`.
