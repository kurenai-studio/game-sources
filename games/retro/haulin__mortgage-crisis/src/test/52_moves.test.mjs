import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("moves: placeCmdsForUid orders existing sets then newSet", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });

  const moves = ctx.MC.engine.legalMoves(state);
  const byUid = new Map();
  for (const m of moves) {
    if (!m || m.kind !== "playProp") continue;
    if (!m.card || !m.card.uid) continue;
    const uid = m.card.uid;
    const arr = byUid.get(uid) ?? [];
    arr.push(m);
    byUid.set(uid, arr);
  }

  // Pick a property uid with both setI + newSet options.
  let uidPick = null;
  for (const [uid, arr] of byUid.entries()) {
    let hasSet = false;
    let hasNew = false;
    for (const m of arr) {
      if (m.dest && m.dest.newSet) hasNew = true;
      if (m.dest && m.dest.setI != null) hasSet = true;
    }
    if (hasSet && hasNew) { uidPick = uid; break; }
  }
  assert.ok(uidPick, "expected a playProp uid with both set and newSet destinations");

  const def = ctx.MC.state.defByUid(state, uidPick);
  assert.ok(def && def.kind === ctx.MC.CardKind.Property);
  assert.ok(!ctx.MC.rules.isWildDef(def), "expected a non-wild property for this scenario");

  const cmds = ctx.MC.moves.placeCmdsForUid(state, uidPick, def, ctx.MC.state.NO_COLOR);
  assert.ok(cmds.length >= 2);

  // All set destinations come before any newSet destination.
  let seenNew = false;
  for (const c of cmds) {
    if (c.dest && c.dest.newSet) seenNew = true;
    if (c.dest && c.dest.setI != null) assert.equal(seenNew, false, "expected set destinations before newSet");
  }

  // setI destinations are sorted ascending.
  const setIs = cmds.filter((c) => c.dest && c.dest.setI != null).map((c) => c.dest.setI);
  for (let i = 1; i < setIs.length; i++) assert.ok(setIs[i - 1] <= setIs[i], "expected ascending setI order");
});

test("moves: defaultWildColorForPlace returns one of wildColors", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 });

  const hand = state.players[0].hand;
  const uid = hand.find((u) => ctx.MC.rules.isWildDef(ctx.MC.state.defByUid(state, u)));
  assert.ok(uid, "expected a wild property uid in hand");
  const def = ctx.MC.state.defByUid(state, uid);

  const c = ctx.MC.moves.defaultWildColorForPlace(state, uid, def);
  assert.ok(def.wildColors.includes(c), "expected chosen color to be one of def.wildColors");
});

test("moves: destForCmd maps cmd kinds to board destinations", async () => {
  const ctx = await loadSrcIntoVm();

  // Bank
  {
    const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
    const uid = s.players[0].hand[0];
    const bank = ctx.MC.moves.bankCmdsForUid(s, uid)[0];
    if (bank) {
      const d = ctx.MC.moves.destForCmd(bank);
      assert.ok(d);
      assert.equal(d.kind, "bankEnd");
    }
  }

  // Place: newSet + existing set
  {
    const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
    const moves = ctx.MC.engine.legalMoves(s).filter((m) => m && m.kind === "playProp");
    const newSet = moves.find((m) => m.dest && m.dest.newSet);
    assert.ok(newSet, "expected a playProp move with newSet destination");
    {
      const d = ctx.MC.moves.destForCmd(newSet);
      assert.ok(d);
      assert.equal(d.kind, "newSet");
      assert.equal(d.p, newSet.dest.p);
    }

    const setEnd = moves.find((m) => m.dest && m.dest.setI != null);
    assert.ok(setEnd, "expected a playProp move with setI destination");
    {
      const d = ctx.MC.moves.destForCmd(setEnd);
      assert.ok(d);
      assert.equal(d.kind, "setEnd");
      assert.equal(d.p, setEnd.dest.p);
      assert.equal(d.setI, setEnd.dest.setI);
    }
  }

  // Build
  {
    const s = ctx.MC.state.newGame({ scenarioId: "houseBasic", seedU32: 1 });
    const mv = ctx.MC.engine.legalMoves(s).find((m) => m && m.kind === "playHouse");
    assert.ok(mv, "expected a playHouse move");
    {
      const d = ctx.MC.moves.destForCmd(mv);
      assert.ok(d);
      assert.equal(d.kind, "setEnd");
      assert.equal(d.p, mv.dest.p);
      assert.equal(d.setI, mv.dest.setI);
    }
  }

  // Rent
  {
    const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
    const mv = ctx.MC.engine.legalMoves(s).find((m) => m && m.kind === "playRent");
    assert.ok(mv, "expected a playRent move");
    {
      const d = ctx.MC.moves.destForCmd(mv);
      assert.ok(d);
      assert.equal(d.kind, "setTop");
      assert.equal(d.p, mv.card.loc.p);
      assert.equal(d.setI, mv.setI);
    }
  }

  // Source
  {
    const d = ctx.MC.moves.destForCmd({ kind: "source" });
    assert.ok(d);
    assert.equal(d.kind, "source");
  }
  assert.equal(ctx.MC.moves.destForCmd({ kind: "nope" }), null);
});

test("cmdProfiles.rent: defaultCmdI uses loc.p (not hardcoded 0)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  ctx.MC.scenarios.resetForScenario(s);

  // Build two sets for P1 such that setI=1 has higher rent than setI=0.
  // If the sort mistakenly uses p=0 (no sets), it will fall back to setI order and fail.
  const setC = ctx.MC.state.newEmptySet();
  ctx.MC.scenarios.setAddPropByDefId(s, setC, "prop_cyan", ctx.MC.state.NO_COLOR);
  ctx.MC.scenarios.setAddPropByDefId(s, setC, "prop_cyan", ctx.MC.state.NO_COLOR);
  s.players[1].sets.push(setC); // setI=0 (lower rent)

  const setB = ctx.MC.state.newEmptySet();
  ctx.MC.scenarios.setAddPropByDefId(s, setB, "prop_black", ctx.MC.state.NO_COLOR);
  ctx.MC.scenarios.setAddPropByDefId(s, setB, "prop_black", ctx.MC.state.NO_COLOR);
  ctx.MC.scenarios.setAddPropByDefId(s, setB, "prop_black", ctx.MC.state.NO_COLOR);
  ctx.MC.scenarios.setAddPropByDefId(s, setB, "prop_black", ctx.MC.state.NO_COLOR);
  s.players[1].sets.push(setB); // setI=1 (higher rent)

  // Give P1 a rent-any card and make them active.
  s.players[1].hand.push(ctx.MC.state.takeUid(s, "rent_any"));
  s.activeP = 1;
  s.playsLeft = 3;
  s.winnerP = ctx.MC.state.NO_WINNER;

  const uid = s.players[1].hand[0];
  const rentMoves = ctx.MC.moves.rentMovesForUid(s, uid);
  assert.ok(rentMoves.length >= 2, "expected >=2 rent moves");

  const a0 = ctx.MC.rules.rentAmountForSet(s, 1, 0);
  const a1 = ctx.MC.rules.rentAmountForSet(s, 1, 1);
  assert.ok(a1 > a0, "expected setI=1 to have higher rent than setI=0");

  const di = ctx.MC.cmdProfiles.rent.defaultCmdI(s, rentMoves, { p: 1, zone: "hand", i: 0 });
  assert.equal(rentMoves[di].setI, 1, "expected highest-rent set chosen by default");
});

test("moves: cmdsForTargeting(place) returns cmds + wildColor and includes Source for hand loc", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 });
  const uid = s.players[0].hand.find((u) => ctx.MC.rules.isWildDef(ctx.MC.state.defByUid(s, u)));
  assert.ok(uid, "expected wild uid in hand");
  const def = ctx.MC.state.defByUid(s, uid);
  const loc = { p: 0, zone: "hand", i: 0 };

  const r = ctx.MC.moves.cmdsForTargeting(s, "place", uid, loc);
  assert.ok(r && Array.isArray(r.cmds));
  assert.ok(def.wildColors.includes(r.wildColor), "expected default wildColor within wildColors");
  assert.ok(r.cmds.some((c) => c && c.kind === "source"), "expected Source included for hand loc");
});

