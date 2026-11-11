import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("targeting: rent cycles spatially, defaults to highest-rent set", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  // Start from a clean scenario-like state with a full uid pool.
  const s = MC.state.newGame({ seedU32: 1 });
  MC.scenarios.resetForScenario(s);

  // Two Orange sets (left-to-right by setI):
  // - setI=0: size 1 => rent $2
  // - setI=1: size 2 => rent $3 (highest, and NOT leftmost)
  const set0 = MC.state.newEmptySet();
  MC.scenarios.setAddPropByDefId(s, set0, "prop_orange", MC.state.NO_COLOR);
  s.players[0].sets.push(set0);

  const set1 = MC.state.newEmptySet();
  MC.scenarios.setAddPropByDefId(s, set1, "prop_orange", MC.state.NO_COLOR);
  MC.scenarios.setAddPropByDefId(s, set1, "prop_orange", MC.state.NO_COLOR);
  s.players[0].sets.push(set1);

  const rentUid = MC.state.takeUid(s, "rent_mo");
  s.players[0].hand.push(rentUid);

  s.activeP = 0;
  s.playsLeft = 3;

  const v = MC.ui.newView();

  MC.ui.targetingEnter(s, v, "rent", false, rentUid, { p: 0, zone: "hand", i: 0 });
  assert.equal(v.mode, "targeting");
  assert.ok(v.targeting.active);

  // One tick to allow profile-driven spatial sorting to apply.
  MC.ui.step(s, v, { nav: {}, a: {}, b: {}, x: {} });

  const cmds = v.targeting.cmds;
  assert.ok(Array.isArray(cmds) && cmds.length > 0, "expected targeting cmds");

  // Spatial cycle order: left-to-right by set index (not by rent amount).
  const rentCmds = cmds.filter((c) => c && c.kind === "playRent");
  const setIs = Array.from(rentCmds, (c) => c.setI);
  assert.deepEqual(
    setIs,
    [0, 1],
    "expected Rent cycle order to be spatial (left-to-right)"
  );

  // Default selection: highest rent set (setI=1).
  const sel = cmds[v.targeting.cmdI];
  assert.ok(sel && sel.kind === "playRent", "expected a Rent cmd selected");
  assert.equal(sel.setI, 1, "expected default Rent selection to pick the highest-rent set");
});

