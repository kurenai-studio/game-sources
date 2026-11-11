import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("xorshift32 produces deterministic sequence", async () => {
  const ctx = await loadSrcIntoVm();
  const rng = new ctx.MC.rng.RNG(1);
  const got = [
    rng.nextU32() >>> 0,
    rng.nextU32() >>> 0,
    rng.nextU32() >>> 0,
    rng.nextU32() >>> 0,
    rng.nextU32() >>> 0
  ];
  const expected = [270369, 67634689, 2647435461, 307599695, 2398689233];
  assert.deepEqual(got, expected);
});

test("nextInt(n) stays within [0, n)", async () => {
  const ctx = await loadSrcIntoVm();
  const rng = new ctx.MC.rng.RNG(123);
  const n = 7;
  for (let i = 0; i < 1000; i++) {
    const v = rng.nextInt(n);
    assert.ok(v >= 0 && v < n, `value ${v} out of range`);
  }
});

