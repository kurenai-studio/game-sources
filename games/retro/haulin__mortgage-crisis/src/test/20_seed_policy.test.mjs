import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("seed policy: Dev tools OFF uses time-based seed", async () => {
  let now = 1000;
  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      tstamp: () => now,
    }
  });

  ctx.MC.debug.toolsOn = false;
  const a = ctx.MC.seed.computeSeedU32();
  now = 1001;
  const b = ctx.MC.seed.computeSeedU32();
  assert.notEqual(a, b);
});

test("seed policy: Dev tools ON stays deterministic", async () => {
  let now = 1000;
  const ctx = await loadSrcIntoVm({
    extraGlobals: {
      tstamp: () => now,
    }
  });

  ctx.MC.debug.toolsOn = true;
  const a = ctx.MC.seed.computeSeedU32();
  now = 2000;
  const b = ctx.MC.seed.computeSeedU32();
  assert.equal(a, b);
  assert.equal(a, ctx.MC.rng.u32NonZero(ctx.MC.config.seedBase));
});

