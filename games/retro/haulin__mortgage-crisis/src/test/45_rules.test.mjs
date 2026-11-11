import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

function findUidsInHandByDefId(ctx, state, defId) {
  const p = state.activeP;
  const out = [];
  const hand = state.players[p].hand;
  for (let i = 0; i < hand.length; i++) {
    const uid = hand[i];
    const di = state.uidToDefI[uid];
    const id = ctx.MC.CARD_DEFS[di].id;
    if (id === defId) out.push(uid);
  }
  return out;
}

function cardRefInActiveHand(state, uid) {
  const p = state.activeP;
  const i = state.players[p].hand.indexOf(uid);
  assert.ok(i >= 0, "expected uid in active hand");
  return { uid, loc: { p, zone: "hand", i } };
}

test("placeBasic scenario: can play property to new set and existing set; playsLeft decrements", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  assert.equal(state.activeP, 0);
  assert.equal(state.players[0].sets.length, 1);

  const [u1, u2] = findUidsInHandByDefId(ctx, state, "prop_orange");
  assert.ok(u1 && u2, "expected 2 orange properties in hand");

  // Play first orange to a new set.
  let res = ctx.MC.engine.applyCommand(state, {
    kind: "playProp",
    card: cardRefInActiveHand(state, u1),
    dest: { newSet: true }
  });
  assert.ok(res.events.some((e) => e.kind === "createSet"));
  assert.equal(state.players[0].sets.length, 2);
  assert.equal(state.playsLeft, 2);

  // Play second orange into the original set (setI=0).
  res = ctx.MC.engine.applyCommand(state, {
    kind: "playProp",
    card: cardRefInActiveHand(state, u2),
    dest: { setI: 0 }
  });
  assert.equal(state.players[0].sets[0].props.length, 2);
  assert.equal(state.playsLeft, 1);
});

test("bank command moves bankable card from hand to bank and decrements playsLeft", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const [m1] = findUidsInHandByDefId(ctx, state, "money_1");
  assert.ok(m1, "expected money_1 in hand");

  const beforeHand = state.players[0].hand.length;
  const beforeBank = state.players[0].bank.length;

  ctx.MC.engine.applyCommand(state, { kind: "bank", card: cardRefInActiveHand(state, m1) });

  assert.equal(state.players[0].hand.length, beforeHand - 1);
  assert.equal(state.players[0].bank.length, beforeBank + 1);
  assert.equal(state.playsLeft, 2);
});

test("wildBasic scenario: can play wild with chosen color; illegal color throws", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 });
  const [w] = findUidsInHandByDefId(ctx, state, "wild_mo");
  assert.ok(w, "expected wild_mo in hand");

  // Legal: choose Orange and start new set.
  ctx.MC.engine.applyCommand(state, {
    kind: "playProp",
    card: cardRefInActiveHand(state, w),
    dest: { newSet: true },
    color: ctx.MC.Color.Orange
  });
  assert.equal(state.players[0].sets.length, 1);
  assert.equal(state.players[0].sets[0].props[0][1], ctx.MC.Color.Orange);

  // Fresh scenario for illegal test.
  const state2 = ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 });
  const [w2] = findUidsInHandByDefId(ctx, state2, "wild_mo");
  assert.throws(() => {
    ctx.MC.engine.applyCommand(state2, {
      kind: "playProp",
      card: cardRefInActiveHand(state2, w2),
      dest: { newSet: true },
      color: ctx.MC.Color.Cyan
    });
  });
});

test("houseBasic scenario: house allowed on complete set only; max 1 house per set", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "houseBasic", seedU32: 1 });
  const houses = findUidsInHandByDefId(ctx, state, "house");
  assert.equal(houses.length, 2);

  // setI=0 is complete Cyan, setI=1 is incomplete Black.
  ctx.MC.engine.applyCommand(state, {
    kind: "playHouse",
    card: cardRefInActiveHand(state, houses[0]),
    dest: { setI: 0 }
  });
  assert.ok(state.players[0].sets[0].houseUid);

  // Second house onto same set should throw.
  assert.throws(() => {
    ctx.MC.engine.applyCommand(state, {
      kind: "playHouse",
      card: cardRefInActiveHand(state, houses[1]),
      dest: { setI: 0 }
    });
  });

  // New scenario: house onto incomplete set throws.
  const state2 = ctx.MC.state.newGame({ scenarioId: "houseBasic", seedU32: 1 });
  const [h] = findUidsInHandByDefId(ctx, state2, "house");
  assert.throws(() => {
    ctx.MC.engine.applyCommand(state2, {
      kind: "playHouse",
      card: cardRefInActiveHand(state2, h),
      dest: { setI: 1 }
    });
  });
});

test("endTurn swaps active player, draws 2, resets playsLeft", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const p0 = state.activeP;
  const p1 = p0 ^ 1;

  const before = state.players[p1].hand.length;
  const res = ctx.MC.engine.applyCommand(state, { kind: "endTurn" });

  assert.equal(state.activeP, p1);
  // In this scenario, the incoming player starts with an empty hand, so they draw 5 instead of 2.
  assert.equal(state.players[p1].hand.length, before + 5);
  assert.equal(state.playsLeft, 3);
  assert.ok(res.events.some((e) => e.kind === "draw"));
});

test("startTurn draws 2 when the incoming player hand is non-empty", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const p0 = state.activeP;
  const p1 = p0 ^ 1;

  // Give the incoming player a card so startTurn draws the normal 2.
  const uid = state.deck.pop();
  state.players[p1].hand.push(uid);
  const before = state.players[p1].hand.length;

  ctx.MC.engine.applyCommand(state, { kind: "endTurn" });

  assert.equal(state.activeP, p1);
  assert.equal(state.players[p1].hand.length, before + 2);
  assert.equal(state.playsLeft, 3);
});

test("endTurn enters discardDown prompt when active hand is over 7 (then discarding completes endTurn)", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ seedU32: 1 });
  const p = state.activeP;
  const o = p ^ 1;

  // Starting player normally has 7 cards; force it to 8 by moving one from deck to hand.
  state.players[p].hand.push(state.deck.pop());
  assert.ok(state.players[p].hand.length > 7, "expected active hand > 7");

  const moves = ctx.MC.engine.legalMoves(state);
  assert.ok(moves.some((m) => m.kind === "endTurn"), "expected endTurn to be legal even when hand > 7");

  const playsBefore = state.playsLeft;
  ctx.MC.engine.applyCommand(state, { kind: "endTurn" });

  // Turn does not pass yet; we enter a forced discard prompt instead.
  assert.equal(state.activeP, p);
  assert.equal(state.playsLeft, playsBefore);
  assert.ok(state.prompt, "expected prompt to be set");
  assert.equal(state.prompt.kind, "discardDown");
  assert.equal(state.prompt.p, p);

  // While prompt is active, only discard moves are returned.
  const m2 = ctx.MC.engine.legalMoves(state);
  assert.ok(m2.length > 0, "expected discard moves during prompt");
  assert.ok(
    m2.every((m) => m.kind === "discard" || m.kind === "cancelPrompt"),
    "expected only discard/cancelPrompt moves during prompt"
  );

  // Discard until prompt clears; this auto-finishes endTurn and starts opponent turn.
  while (state.prompt) {
    const mv = ctx.MC.engine.legalMoves(state).find((m) => m.kind === "discard");
    ctx.MC.engine.applyCommand(state, mv);
  }

  assert.equal(state.activeP, o);
  assert.equal(state.playsLeft, 3);
});

test("cancelPrompt cancels discardDown only before any discard", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ seedU32: 1 });
  const p = state.activeP;

  // Force prompt via endTurn attempt.
  state.players[p].hand.push(state.deck.pop());
  ctx.MC.engine.applyCommand(state, { kind: "endTurn" });
  assert.ok(state.prompt && state.prompt.kind === "discardDown");

  // Cancel immediately (no discards yet).
  ctx.MC.engine.applyCommand(state, { kind: "cancelPrompt" });
  assert.equal(state.prompt, null);
  assert.equal(state.activeP, p);

  // Re-enter prompt, discard once, then cancel should be rejected.
  ctx.MC.engine.applyCommand(state, { kind: "endTurn" });
  assert.ok(state.prompt && state.prompt.kind === "discardDown");

  const mv = ctx.MC.engine.legalMoves(state).find((m) => m.kind === "discard");
  assert.ok(mv, "expected discard move");
  ctx.MC.engine.applyCommand(state, mv);

  assert.throws(() => ctx.MC.engine.applyCommand(state, { kind: "cancelPrompt" }));
});

test("drawToHand reshuffles discard into deck when needed (continues drawing)", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ seedU32: 1 });
  const p = state.activeP;

  // Move almost the entire deck into discard so a draw must reshuffle.
  while (state.deck.length > 1) state.discard.push(state.deck.shift());
  assert.equal(state.deck.length, 1);
  assert.ok(state.discard.length > 0);

  const before = state.players[p].hand.length;
  const events = [];
  ctx.MC.state.drawToHand(state, p, 5, events);

  assert.equal(state.players[p].hand.length, before + 5);
  assert.equal(state.discard.length, 0, "expected discard to be consumed into deck during reshuffle");
  assert.ok(events.some((e) => e && e.kind === "reshuffle"), "expected reshuffle event");
});

test("drawToHand draws partially when the deck is short (no throw)", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const p0 = state.activeP;
  const p1 = p0 ^ 1;

  // Make the deck very small *and* keep discard empty so the draw is forced to be partial.
  // drawToHand reshuffles discard into deck when available.
  while (state.deck.length > 2) state.players[p0].bank.push(state.deck.shift());
  state.discard = [];

  const before = state.players[p1].hand.length; // 0 in this scenario
  const res = ctx.MC.engine.applyCommand(state, { kind: "endTurn" });

  assert.equal(state.activeP, p1);
  assert.equal(state.players[p1].hand.length, before + 2);

  const drawEv = res.events.find((e) => e.kind === "draw");
  assert.ok(drawEv, "expected draw event");
  assert.equal(drawEv.uids.length, 2);
});

test("winCheck scenario: evaluateWin detects winner", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "winCheck", seedU32: 1 });
  assert.equal(ctx.MC.rules.evaluateWin(state), 0);
  assert.equal(state.winnerP, 0);
});

test("legalMoves only returns commands that applyCommand accepts", async () => {
  const ctx = await loadSrcIntoVm();

  function cloneState(s) {
    return JSON.parse(JSON.stringify(s));
  }

  const cases = [
    { label: "default newGame", build: () => ctx.MC.state.newGame({ seedU32: 1 }) },
    { label: "scenario placeBasic", build: () => ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 }) },
    { label: "scenario wildBasic", build: () => ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 }) },
    { label: "scenario houseBasic", build: () => ctx.MC.state.newGame({ scenarioId: "houseBasic", seedU32: 1 }) },
    { label: "scenario winCheck (game over)", build: () => ctx.MC.state.newGame({ scenarioId: "winCheck", seedU32: 1 }) }
  ];

  for (const tcase of cases) {
    const state = tcase.build();
    const moves = ctx.MC.engine.legalMoves(state);
    assert.ok(Array.isArray(moves), `${tcase.label}: expected legalMoves to return an array`);

    for (const move of moves) {
      const copy = cloneState(state);
      assert.doesNotThrow(
        () => ctx.MC.engine.applyCommand(copy, move),
        `${tcase.label}: expected move kind=${move && move.kind} to be applyable`
      );
    }
  }
});

test("prompt actor is prompt.p (can act even if activeP differs)", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });

  // Force mismatch: prompt actor is P0, but active turn is P1.
  assert.ok(state.prompt && state.prompt.kind === "payDebt");
  assert.equal(state.prompt.p, 0);
  state.activeP = 1;

  const moves = ctx.MC.engine.legalMoves(state);
  assert.ok(moves.length > 0, "expected payDebt moves");
  assert.ok(moves.some((m) => m.kind === "payDebt"), "expected at least one payDebt move during payDebt prompt");
  assert.ok(
    moves.every((m) => m.kind === "payDebt" || m.kind === "playJustSayNo"),
    "expected only payDebt/playJustSayNo moves during payDebt prompt"
  );

  // Applying a legal prompt move should succeed even though activeP is different.
  const mv = moves.find((m) => m.kind === "payDebt") || moves[0];
  assert.doesNotThrow(() => ctx.MC.engine.applyCommand(state, mv));
});

test("house-pay-first enforced (cannot pay property from housed set)", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });

  const set0 = state.players[0].sets[0];
  assert.ok(set0.houseUid, "expected housed set");
  const propUid = set0.props[0][0];

  // Engine rejects paying a property from the housed set.
  assert.throws(() => {
    ctx.MC.engine.applyCommand(state, {
      kind: "payDebt",
      card: { uid: propUid, loc: { p: 0, zone: "setProps", setI: 0, i: 0 } }
    });
  }, /house_pay_first/);
});

test("paying house can overpay and resolves debt; house goes to recipient bank", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });

  const before = state.players[1].bank.length;
  const houseUid = state.players[0].sets[0].houseUid;
  assert.ok(houseUid, "expected house uid");

  // Pay with the house.
  const res = ctx.MC.engine.applyCommand(state, {
    kind: "payDebt",
    card: { uid: houseUid, loc: { p: 0, zone: "setHouse", setI: 0 } }
  });

  assert.ok(res.events.some((e) => e.kind === "payDebt"), "expected payDebt event");
  assert.ok(
    res.events.some(
      (e) => e && e.kind === "move" && e.uid === houseUid && e.from && e.from.zone === "promptBuf" && e.to && e.to.zone === "bank" && e.to.p === 1
    ),
    "expected move event for house transfer to recipient bank"
  );
  assert.equal(state.players[0].sets[0].houseUid, 0, "expected house removed from set");
  assert.equal(state.players[1].bank.length, before + 1, "expected house transferred to bank");
  assert.equal(state.players[1].bank[state.players[1].bank.length - 1], houseUid);
  assert.equal(state.prompt, null, "expected prompt cleared (no properties received)");
});

test("payDebt: property transfer emits move promptBuf->recvProps", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ seedU32: 1 });

  // Force a simple prompt where a single property overpays and is received.
  state.activeP = 0;
  state.playsLeft = 3;
  ctx.MC.state.clearPrompt(state);

  const propUid = state.deck.find((u) => ctx.MC.state.defByUid(state, u).id === "prop_orange");
  assert.ok(propUid, "expected prop_orange in deck");
  state.deck = state.deck.filter((u) => u !== propUid);

  const set = ctx.MC.state.newEmptySet();
  set.props.push([propUid, ctx.MC.Color.Orange]);
  state.players[0].sets = [set];
  state.players[0].bank = [];

  ctx.MC.state.setPrompt(state, { kind: "payDebt", p: 0, toP: 1, rem: 1, buf: [], srcAction: null });
  assert.ok(state.prompt && state.prompt.kind === "payDebt");

  const res = ctx.MC.engine.applyCommand(state, {
    kind: "payDebt",
    card: { uid: propUid, loc: { p: 0, zone: "setProps", setI: 0, i: 0 } }
  });

  assert.ok(
    res.events.some(
      (e) => e && e.kind === "move" && e.uid === propUid && e.from && e.from.zone === "promptBuf" && e.to && e.to.zone === "recvProps" && e.to.p === 1
    ),
    "expected move event for property transfer to recvProps"
  );
  assert.ok(state.prompt && state.prompt.kind === "placeReceived", "expected placeReceived prompt for recipient");
  assert.equal(state.prompt.p, 1);
});

test("placeReceived allows placing from recvProps without consuming plays", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
  assert.ok(state.prompt && state.prompt.kind === "placeReceived");
  assert.equal(state.prompt.p, 0);

  const playsBefore = state.playsLeft;
  const mv = ctx.MC.engine.legalMoves(state).find((m) => m.kind === "playProp" && m.card && m.card.loc && m.card.loc.zone === "recvProps");
  assert.ok(mv, "expected a playProp move from recvProps");

  ctx.MC.engine.applyCommand(state, mv);
  assert.equal(state.playsLeft, playsBefore, "expected playsLeft unchanged during placement prompt");
});

test("replaceWindow: playProp into an overfill-complete set opens prompt", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });

  const playsBefore = s.playsLeft;
  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  assert.ok(mv, "expected playProp into set 0");

  ctx.MC.engine.applyCommand(s, mv);
  assert.equal(s.playsLeft, playsBefore - 1, "expected playProp to consume a play");
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow", "expected replaceWindow prompt");
  assert.equal(s.prompt.p, 0);
  assert.equal(s.prompt.srcSetI, 0);
  assert.equal(s.prompt.excludeUid, mv.card.uid);
  assert.equal(s.prompt.resume, null);
});

test("replaceWindow: skipReplaceWindow clears prompt", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow");

  ctx.MC.engine.applyCommand(s, { kind: "skipReplaceWindow" });
  assert.equal(s.prompt, null);
});

test("replaceWindow: moveWild does not consume plays and disallows moving into the same set", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow");

  const playsBefore = s.playsLeft;
  const mw = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "moveWild");
  assert.ok(mw, "expected a moveWild move");

  // Same-set destination is disallowed.
  assert.throws(() => {
    ctx.MC.engine.applyCommand(s, { ...mw, dest: { p: 0, setI: s.prompt.srcSetI } });
  }, /replace_same_set/);

  ctx.MC.engine.applyCommand(s, mw);
  assert.equal(s.playsLeft, playsBefore, "expected moveWild not to consume plays");
});

test("replaceWindow disallows moving excludeUid", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow");

  const srcSetI = s.prompt.srcSetI;
  const excludeUid = s.prompt.excludeUid;
  const srcSet = s.players[0].sets[srcSetI];
  const excludeI = srcSet.props.findIndex((t) => t && t[0] === excludeUid);
  assert.ok(excludeI >= 0, "expected excludeUid to be in the source set");

  assert.throws(() => {
    ctx.MC.engine.applyCommand(s, {
      kind: "moveWild",
      card: { uid: excludeUid, loc: { p: 0, zone: "setProps", setI: srcSetI, i: excludeI } },
      dest: { p: 0, newSet: true },
      color: ctx.MC.Color.Orange
    });
  }, /replace_exclude/);
});

test("replaceWindow is not offered when removing a Wild would break source completeness", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });

  // Make the source set reach EXACT completion (3) after the play, not overfill (4).
  s.players[0].sets[0].props.splice(0, 1);

  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  assert.ok(mv, "expected playProp into set 0");
  ctx.MC.engine.applyCommand(s, mv);

  assert.equal(s.prompt, null, "expected no replaceWindow prompt when source would become incomplete");
});

test("winning after a playProp skips replaceWindow prompt", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });

  // Pre-arrange 3 complete sets so that the win is detected after the play.
  // Complete Magenta set (requiredSize=3).
  const magI = s.deck.findIndex((u) => ctx.MC.state.defByUid(s, u).id === "prop_magenta");
  assert.ok(magI >= 0, "expected prop_magenta in deck");
  const uidMag = s.deck.splice(magI, 1)[0];
  s.players[0].sets[1].props.push([uidMag, ctx.MC.Color.Magenta]);
  // Add complete Cyan set (requiredSize=2).
  const setC = ctx.MC.state.newEmptySet();
  const cyanI0 = s.deck.findIndex((u) => ctx.MC.state.defByUid(s, u).id === "prop_cyan");
  assert.ok(cyanI0 >= 0, "expected first prop_cyan in deck");
  const uidC0 = s.deck.splice(cyanI0, 1)[0];
  const cyanI1 = s.deck.findIndex((u) => ctx.MC.state.defByUid(s, u).id === "prop_cyan");
  assert.ok(cyanI1 >= 0, "expected second prop_cyan in deck");
  const uidC1 = s.deck.splice(cyanI1, 1)[0];
  setC.props.push([uidC0, ctx.MC.Color.Cyan]);
  setC.props.push([uidC1, ctx.MC.Color.Cyan]);
  s.players[0].sets.push(setC);

  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  assert.ok(mv, "expected playProp into set 0");

  ctx.MC.engine.applyCommand(s, mv);
  assert.equal(s.winnerP, 0, "expected win detected");
  assert.equal(s.prompt, null, "expected replaceWindow skipped on win");
});

test("replaceWindow can nest during placeReceived and resume remaining received props", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });

  // Build a placeReceived prompt using an Orange property (to trigger replaceWindow into set 0)
  // plus a second arbitrary property to verify resume.
  const uidOrangeI = s.players[0].hand.findIndex((u) => ctx.MC.state.defByUid(s, u).id === "prop_orange");
  assert.ok(uidOrangeI >= 0, "expected prop_orange in hand");
  const uidOrange = s.players[0].hand.splice(uidOrangeI, 1)[0];

  const uidOtherI = s.deck.findIndex((u) => ctx.MC.state.defByUid(s, u).kind === ctx.MC.CardKind.Property);
  assert.ok(uidOtherI >= 0, "expected a property in deck");
  const uidOther = s.deck.splice(uidOtherI, 1)[0];

  ctx.MC.state.setPrompt(s, { kind: "placeReceived", p: 0, uids: [uidOrange, uidOther] });
  assert.ok(s.prompt && s.prompt.kind === "placeReceived");

  const mvRecv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.card && m.card.uid === uidOrange && m.dest && m.dest.setI === 0);
  assert.ok(mvRecv, "expected recvProps play into set 0");

  ctx.MC.engine.applyCommand(s, mvRecv);
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow", "expected replaceWindow to interrupt placeReceived");
  assert.ok(s.prompt.resume && s.prompt.resume.kind === "placeReceived");
  assert.equal(s.prompt.resume.uids.length, 1);
  assert.equal(s.prompt.resume.uids[0], uidOther);

  // Skip should resume placeReceived with the remaining uid.
  ctx.MC.engine.applyCommand(s, { kind: "skipReplaceWindow" });
  assert.ok(s.prompt && s.prompt.kind === "placeReceived", "expected placeReceived resumed");
  assert.equal(s.prompt.uids.length, 1);
  assert.equal(s.prompt.uids[0], uidOther);
});

test("Rent: playRent discards rent card, decrements plays, and creates payDebt prompt for opponent (when payable)", async () => {
  const ctx = await loadSrcIntoVm();
  const state = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });

  // Find rent card uid in active hand.
  const rents = findUidsInHandByDefId(ctx, state, "rent_mo");
  assert.equal(rents.length, 1);
  const uid = rents[0];

  const moves = ctx.MC.engine.legalMoves(state);
  const mv = moves.find((m) => m.kind === "playRent" && m.card && m.card.uid === uid);
  assert.ok(mv, "expected a playRent move");

  const playsBefore = state.playsLeft;
  const handBefore = state.players[0].hand.length;
  const discBefore = state.discard.length;

  ctx.MC.engine.applyCommand(state, mv);

  assert.equal(state.playsLeft, playsBefore - 1);
  assert.equal(state.players[0].hand.length, handBefore - 1, "expected rent card removed from hand");
  assert.equal(state.discard.length, discBefore + 1, "expected rent card discarded");
  assert.ok(state.prompt && state.prompt.kind === "payDebt", "expected debt prompt to begin");
  assert.equal(state.prompt.p, 1, "expected opponent to be payer");
  assert.equal(state.prompt.toP, 0, "expected active player to be payee");
  assert.ok(state.prompt.srcAction, "expected action-sourced debt metadata");
  assert.equal(state.prompt.srcAction.kind, "rent");
  assert.equal(state.prompt.srcAction.fromP, 0);
  assert.equal(state.prompt.srcAction.actionUid, uid);
  assert.equal(typeof state.prompt.rem, "number", "expected numeric remaining rent");
  assert.ok(Number.isFinite(state.prompt.rem), "expected finite remaining rent");
  assert.ok(Number.isInteger(state.prompt.rem), "expected integer remaining rent");
  assert.ok(state.prompt.rem > 0, "expected positive remaining rent");
});

test("payDebt(JSN) is legal only when srcAction exists and buf is empty", async () => {
  const ctx = await loadSrcIntoVm();

  // Scenario includes: payDebt prompt with srcAction and a JSN in P0 hand.
  const s = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });
  assert.ok(s.prompt && s.prompt.kind === "payDebt");
  assert.ok(s.prompt.srcAction, "expected srcAction in debtHouseFirst");
  assert.equal(s.prompt.buf.length, 0);

  const moves = ctx.MC.engine.legalMoves(s);
  assert.ok(moves.some((m) => m.kind === "playJustSayNo"), "expected JSN move");

  const jsnI = s.players[0].hand.findIndex((u) => ctx.MC.state.defByUid(s, u).id === "just_say_no");
  assert.ok(jsnI >= 0, "expected JSN in hand");
  const jsnUid = s.players[0].hand[jsnI];

  ctx.MC.engine.applyCommand(s, { kind: "playJustSayNo", card: { uid: jsnUid, loc: { p: 0, zone: "hand", i: jsnI } } });
  assert.equal(s.prompt, null, "expected prompt cleared after JSN");
  assert.ok(s.discard.includes(jsnUid), "expected JSN discarded");

  // Too late: once buf is non-empty, JSN is disallowed.
  const s2 = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });
  const jsnI2 = s2.players[0].hand.findIndex((u) => ctx.MC.state.defByUid(s2, u).id === "just_say_no");
  const jsnUid2 = s2.players[0].hand[jsnI2];
  s2.prompt.buf = [1]; // simulate partial payment started
  assert.equal(ctx.MC.engine.legalMoves(s2).some((m) => m.kind === "playJustSayNo"), false);
  assert.throws(() => {
    ctx.MC.engine.applyCommand(s2, { kind: "playJustSayNo", card: { uid: jsnUid2, loc: { p: 0, zone: "hand", i: jsnI2 } } });
  }, /response_too_late/);

  // No srcAction: JSN is disallowed even with empty buf.
  const s3 = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });
  const jsnI3 = s3.players[0].hand.findIndex((u) => ctx.MC.state.defByUid(s3, u).id === "just_say_no");
  const jsnUid3 = s3.players[0].hand[jsnI3];
  s3.prompt.srcAction = null;
  assert.equal(ctx.MC.engine.legalMoves(s3).some((m) => m.kind === "playJustSayNo"), false);
  assert.throws(() => {
    ctx.MC.engine.applyCommand(s3, { kind: "playJustSayNo", card: { uid: jsnUid3, loc: { p: 0, zone: "hand", i: jsnI3 } } });
  }, /no_response_window/);
});

test("Sly Deal: respondAction offered when defender has JSN; respondPass steals and opens placeReceived", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  // Move a Sly Deal into P0 hand.
  const slyUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(slyUid, "expected sly_deal in deck");
  s.deck = s.deck.filter((u) => u !== slyUid);
  s.players[0].hand.push(slyUid);

  // Opponent has one stealable property in a set.
  const propUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_orange");
  assert.ok(propUid, "expected prop_orange in deck");
  s.deck = s.deck.filter((u) => u !== propUid);
  const set = ctx.MC.state.newEmptySet();
  set.props.push([propUid, ctx.MC.Color.Orange]);
  s.players[1].sets = [set];

  // Opponent has JSN in hand.
  const jsnUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "just_say_no");
  assert.ok(jsnUid, "expected just_say_no in deck");
  s.deck = s.deck.filter((u) => u !== jsnUid);
  s.players[1].hand.push(jsnUid);

  const moves = ctx.MC.engine.legalMoves(s);
  const mv = moves.find((m) => m.kind === "playSlyDeal" && m.card && m.card.uid === slyUid);
  assert.ok(mv, "expected playSlyDeal move");

  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "respondAction", "expected respondAction prompt");
  assert.equal(s.prompt.p, 1, "expected defender to respond");

  // Defender passes -> steal resolves and opens placement prompt for attacker.
  const res2 = ctx.MC.engine.applyCommand(s, { kind: "respondPass" });
  assert.ok(
    res2.events.some(
      (e) =>
        e &&
        e.kind === "move" &&
        e.uid === propUid &&
        e.from &&
        e.from.zone === "setProps" &&
        e.to &&
        e.to.zone === "recvProps" &&
        e.to.p === 0
    ),
    "expected move event for sly steal setProps->recvProps"
  );
  assert.ok(s.prompt && s.prompt.kind === "placeReceived", "expected placeReceived prompt");
  assert.equal(s.prompt.p, 0, "expected attacker to place received property");
  assert.equal(s.prompt.uids.length, 1);
  assert.equal(s.prompt.uids[0], propUid);
  assert.equal(s.players[1].sets.length, 0, "expected defender set removed after stealing last prop");
});

test("Sly Deal: JSN cancels the action (no steal)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const slyUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(slyUid);
  s.deck = s.deck.filter((u) => u !== slyUid);
  s.players[0].hand.push(slyUid);

  const propUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_orange");
  assert.ok(propUid);
  s.deck = s.deck.filter((u) => u !== propUid);
  const set = ctx.MC.state.newEmptySet();
  set.props.push([propUid, ctx.MC.Color.Orange]);
  s.players[1].sets = [set];

  const jsnUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "just_say_no");
  assert.ok(jsnUid);
  s.deck = s.deck.filter((u) => u !== jsnUid);
  s.players[1].hand.push(jsnUid);
  const jsnI = s.players[1].hand.indexOf(jsnUid);

  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playSlyDeal" && m.card && m.card.uid === slyUid);
  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "respondAction");

  ctx.MC.engine.applyCommand(s, { kind: "playJustSayNo", card: { uid: jsnUid, loc: { p: 1, zone: "hand", i: jsnI } } });
  assert.equal(s.prompt, null, "expected prompt cleared after JSN");
  assert.equal(s.players[1].sets[0].props.length, 1, "expected target property not stolen");
});

test("Sly Deal: when defender has no JSN, it resolves immediately into placeReceived", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const slyUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(slyUid);
  s.deck = s.deck.filter((u) => u !== slyUid);
  s.players[0].hand.push(slyUid);

  const propUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_orange");
  assert.ok(propUid);
  s.deck = s.deck.filter((u) => u !== propUid);
  const set = ctx.MC.state.newEmptySet();
  set.props.push([propUid, ctx.MC.Color.Orange]);
  s.players[1].sets = [set];
  s.players[1].hand = []; // no JSN

  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playSlyDeal" && m.card && m.card.uid === slyUid);
  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "placeReceived", "expected immediate placeReceived");
  assert.equal(s.prompt.p, 0);
});

test("Sly Deal: cannot target properties in a complete set", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const slyUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(slyUid);
  s.deck = s.deck.filter((u) => u !== slyUid);
  s.players[0].hand.push(slyUid);

  // Build a complete Cyan set (2) for opponent.
  const takeFromDeckOrHand = (defId) => {
    const zones = [s.deck, s.players[0].hand, s.players[1].hand];
    for (const z of zones) {
      const i = z.findIndex((u) => ctx.MC.state.defByUid(s, u).id === defId);
      if (i >= 0) return z.splice(i, 1)[0];
    }
    return 0;
  };
  const c0 = takeFromDeckOrHand("prop_cyan");
  assert.ok(c0);
  const c1 = takeFromDeckOrHand("prop_cyan");
  assert.ok(c1);
  const setC = ctx.MC.state.newEmptySet();
  setC.props.push([c0, ctx.MC.Color.Cyan]);
  setC.props.push([c1, ctx.MC.Color.Cyan]);
  s.players[1].sets = [setC];

  const moves = ctx.MC.engine.legalMoves(s).filter((m) => m.kind === "playSlyDeal" && m.card && m.card.uid === slyUid);
  assert.equal(moves.length, 0, "expected no sly targets from a complete set");

  assert.throws(() => {
    ctx.MC.engine.applyCommand(s, {
      kind: "playSlyDeal",
      card: { uid: slyUid, loc: { p: 0, zone: "hand", i: s.players[0].hand.indexOf(slyUid) } },
      target: { uid: c0, loc: { p: 1, zone: "setProps", setI: 0, i: 0 } }
    });
  }, /sly_full_set/);
});

