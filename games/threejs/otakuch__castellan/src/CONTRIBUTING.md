# Contributing

## Before you start

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and in particular the part about fragment
order. The files in `src/js` are not ES modules; they are ordered slices of one closure and
the numeric prefixes decide when your code runs.

## Working on it

```bash
npm start        # build and serve on http://localhost:8080
npm run check    # build, balance braces, verify the closure closes
```

Edit files in `src/`, never `index.html` or `dist/castellan.html` — both are written by the
build. Commit the rebuilt output with your change; CI fails if it has drifted from `src/`.

## Adding a piece

1. Write a maker in `src/js/10-pieces.js` returning `{ group, meta }`.
2. Register it in `PIECES` (label, group, footprint radius, whether it rotates, a tip) and in
   `MAKERS`.
3. Publish whatever the simulation needs in `meta` — a `door`, a `face` for the ground arrow,
   `spots` for workable ground, a `smoke` point, a `torch`.
4. If it should create work, add a role in `15-bodies.js` and a schedule in `17-systems.js`.
5. If it is worth remarking on, add a line to `NOTE` in `26-chronicle.js`.

## House style

- British spelling, and prose in the interface rather than labels where there is room.
- No new dependencies. If it cannot be drawn, generated or synthesised, it does not go in.
- Anything repeated more than a handful of times should be an `InstancedMesh`.
- Anything that reads the terrain height must call `ground()`. Never cache it across a sculpt.
