# Contributing to Ant Wars

Thanks for looking. The game is early and the direction is open, so ideas are as welcome as code.

## Before a pull request

1. `cd game && npm ci`
2. `npm test` stays green (the table tests in `src/sim/`).
3. A change to the scenes or the HUD also runs `npm run smoke` (headless Chrome at an iPhone viewport) and passes.
4. One change per pull request, with a short note on what it does and how you tested it on a phone.

## Where things live

- Rules and numbers: `game/src/sim/` (the round curve, the roster, the economy, the powers, the daily seed). Change a number there and its table test tells you what moved.
- Scenes: `game/src/` (boot, the Yard, the HUD, the title).
- The smoke harness: `game/scripts/smoke.mjs`.

## Licence

By opening a pull request you agree that your contribution lands under the MIT licence of this repository.
