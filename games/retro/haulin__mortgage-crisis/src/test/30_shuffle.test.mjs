import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("shuffleInPlace is deterministic given a seed", async () => {
  const ctx = await loadSrcIntoVm();
  const rng = new ctx.MC.rng.RNG(1);

  const arr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  ctx.MC.shuffle.inPlaceWithRng(arr, rng);

  const expected = [3, 1, 0, 2, 6, 7, 8, 5, 4, 9];
  assert.deepEqual(arr, expected);
});

