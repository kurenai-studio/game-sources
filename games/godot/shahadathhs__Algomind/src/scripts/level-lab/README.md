# Level lab

A development tool for designing levels. It finds candidate boards, measures them with the real solver, and draws contact sheets. It is not shipped. Everything is deterministic for a seed.

```sh
pnpm --filter @algomind/level-contract build      # once: the lab reads the built contract
node scripts/level-lab/cli.mjs families           # the candidate families
node scripts/level-lab/cli.mjs search world:1     # or one family, or `all`; --count 6 --seed 1 --tries N
node scripts/level-lab/cli.mjs check levels.json  # measure a hand-picked set and flag limit problems
```

Output goes to `scripts/level-lab/out/` (git-ignored): `<name>.json` plus `<name>-light.svg` and `<name>-dark.svg`.

## What it measures

| Number            | Meaning                                                                                        |
| ----------------- | ---------------------------------------------------------------------------------------------- |
| `par`             | The shortest program (the real solver)                                                         |
| `moves`/`turns`   | Its parts                                                                                      |
| `excess`          | Commands the walls cost: par here minus par on the same board with no walls                    |
| `decoy`           | Commands the fewest-moves route costs above par. Above zero: the obvious route is not cheapest |
| shortest programs | How many different programs reach par (1 means the route is unique)                            |
| `deadEnds`        | Floor cells with one open neighbour, away from the start and goal                              |

A candidate is kept when its numbers match its family's profile (`families.mjs`), look-alikes under rotation and mirroring are dropped, and a varied shortlist is picked by farthest-first distance over the numbers.

## The `check` file

A JSON list of `{ slug, title, rows, commands, maxCommands, hints, difficulty, chapter?, budget? }`. Rows use `.` floor, `#` wall, `G` goal, and `^ > v <` for the automaton and its facing. `check` reports invalid levels, unreachable goals, a limit below par, and a limit far above par.

Set rules, checked across the whole file in order: a level whose par equals an earlier level's par in the same `chapter` is flagged (levels in a chapter should differ); a level that offers `REPEAT` is flagged when a plain program already fits its limit (the loop is optional); a level marked `"budget": true` is flagged when its limit is above par (a worse program would pass, so the limit decides nothing).

## Carved boards

`carve.mjs` builds boards from solid wall instead of scattering wall pieces: `maze` (a spanning tree with start and goal at two far ends, so there is one route and every other branch is a dead end) and `decoy` (a staircase with the fewest moves beside a long way round that is the cheaper program). Families `budget-tree-maze` and `budget-carved-decoy` use them. On seed 1 they give 128 and 164 distinct candidates; the older random `budget-decoy` family gives 22.
