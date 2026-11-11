import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

function takeUidAndRemoveEverywhere(MC, s, defId) {
  let uid = 0;
  const a = s._pool && s._pool[defId] ? s._pool[defId] : null;
  if (a && a.length > 0) {
    uid = MC.state.takeUid(s, defId);
  } else {
    // Fallback: pick a matching uid from the current state zones (scenario states may have an exhausted pool).
    const all = [];
    if (s.deck) all.push(...s.deck);
    if (s.discard) all.push(...s.discard);
    for (let p = 0; p < 2; p++) {
      if (s.players[p].hand) all.push(...s.players[p].hand);
      if (s.players[p].bank) all.push(...s.players[p].bank);
      for (const set of (s.players[p].sets || [])) {
        if (!set) continue;
        if (set.props) for (const [u] of set.props) all.push(u);
        if (set.houseUid) all.push(set.houseUid);
      }
    }
    uid = all.find((u) => {
      const def = MC.state.defByUid(s, u);
      return def && def.id === defId;
    }) || 0;
    assert.ok(uid, `expected to find uid for ${defId} in state zones`);
  }

  // Remove from all zones so we don't duplicate uids (pool is defId-first, deck is uid-first).
  s.deck = s.deck.filter((u) => u !== uid);
  s.discard = s.discard.filter((u) => u !== uid);
  for (let p = 0; p < 2; p++) {
    s.players[p].hand = s.players[p].hand.filter((u) => u !== uid);
    s.players[p].bank = s.players[p].bank.filter((u) => u !== uid);
    for (const set of (s.players[p].sets || [])) {
      if (!set) continue;
      if (set.props) set.props = set.props.filter(([u]) => u !== uid);
      if (set.houseUid === uid) set.houseUid = 0;
    }
  }
  return uid;
}

test("ai: actor uses prompt.p when prompting, else activeP", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  assert.equal(MC.ai.actor({ activeP: 1, prompt: null }), 1);
  assert.equal(MC.ai.actor({ activeP: 0, prompt: { p: 1, kind: "payDebt" } }), 1);
});

test("ai: configured policy ids exist in registry", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  const ids = MC.config.ai.policyByP;
  assert.ok(Array.isArray(ids));
  assert.equal(ids.length, 2);
  assert.ok(MC.ai.policies && typeof MC.ai.policies === "object");
  assert.ok(MC.ai.policies.uniform, "expected uniform policy");

  assert.ok(MC.ai.policies[ids[0]], `expected policyByP[0]=${ids[0]} to exist`);
  assert.ok(MC.ai.policies[ids[1]], `expected policyByP[1]=${ids[1]} to exist`);
});

test("ai: pickRandomLegalMove returns null for no moves", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  // A tiny fake state where legalMoves can be stubbed.
  const saved = MC.engine.legalMoves;
  MC.engine.legalMoves = () => [];
  try {
    assert.equal(MC.ai.pickRandomLegalMove({ seed: 1 }), null);
  } finally {
    MC.engine.legalMoves = saved;
  }
});

test("ai: describeCmd is stable for common cmd kinds", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  const saved = MC.fmt.destLabelForCmd;
  try {
    MC.fmt.destLabelForCmd = () => "Bank";

    assert.equal(MC.ai.describeCmd({}, { kind: "endTurn" }), "AI: End turn");
    assert.equal(MC.ai.describeCmd({}, { kind: "bank" }), "AI: Bank");
    assert.equal(MC.ai.describeCmd({}, { kind: "playRent" }), "AI: Rent");
    assert.equal(MC.ai.describeCmd({}, { kind: "playHouse" }), "AI: Build");
    assert.equal(MC.ai.describeCmd({}, { kind: "payDebt" }), "AI: Pay");
    assert.equal(MC.ai.describeCmd({}, { kind: "discard" }), "AI: Discard");
    assert.equal(MC.ai.describeCmd({}, { kind: "cancelPrompt" }), "AI: Cancel");
    assert.equal(MC.ai.describeCmd({}, { kind: "playProp" }), "AI: Place -> Bank");

    MC.fmt.destLabelForCmd = () => "";
    assert.equal(MC.ai.describeCmd({}, { kind: "playProp" }), "AI: Place");

    assert.equal(MC.ai.describeCmd({}, { kind: "someFutureCmd" }), "AI: someFutureCmd");
  } finally {
    MC.fmt.destLabelForCmd = saved;
  }
});

test("ai: biasPlayRent only boosts when opponent has payables", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  const s = MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  MC.state.clearPrompt(s);

  // Opponent has no payables.
  s.players[1].bank = [];
  s.players[1].sets = [];

  const moves0 = MC.engine.legalMoves(s);
  const rentMove0 = moves0.find((m) => m && m.kind === "playRent");
  assert.ok(rentMove0, "expected a playRent move to exist");

  assert.equal(MC.ai.policies.biasPlayRent.weight(s, rentMove0, moves0), 1);

  // Give opponent something payable.
  const payUid = takeUidAndRemoveEverywhere(MC, s, "money_1");
  s.players[1].bank = [payUid];

  const moves1 = MC.engine.legalMoves(s);
  const rentMove1 = moves1.find((m) => m && m.kind === "playRent");
  assert.ok(rentMove1, "expected a playRent move to exist");
  assert.equal(MC.ai.policies.biasPlayRent.weight(s, rentMove1, moves1), MC.config.ai.biasPlayRentK);
});

test("ai: biasPlaySlyDeal boosts playSlyDeal moves when a target exists", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  const s = MC.state.newGame({ scenarioId: "moveStress", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  MC.state.clearPrompt(s);

  const moves = MC.engine.legalMoves(s);
  const slyMove = moves.find((m) => m && m.kind === "playSlyDeal");
  assert.ok(slyMove, "expected a playSlyDeal move to exist");

  assert.equal(MC.ai.policies.biasPlaySlyDeal.weight(s, slyMove, moves), MC.config.ai.biasPlaySlyDealK);
});

test("ai: earlyTurnDiscipline prefers EndTurn over banking actions when only actions are bankable (hand>2)", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  const s = MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  MC.state.clearPrompt(s);
  s.players[0].bank = [];
  s.players[0].sets = [];
  s.players[1].bank = [];
  s.players[1].sets = [];

  const a0 = takeUidAndRemoveEverywhere(MC, s, "rent_cb");
  const a1 = takeUidAndRemoveEverywhere(MC, s, "sly_deal");
  const a2 = takeUidAndRemoveEverywhere(MC, s, "just_say_no");
  s.players[0].hand = [a0, a1, a2];

  const moves = MC.engine.legalMoves(s);
  const endTurn = moves.find((m) => m && m.kind === "endTurn");
  const bankAction = moves.find((m) => m && m.kind === "bank");
  assert.ok(endTurn, "expected endTurn move");
  assert.ok(bankAction, "expected bank move");

  const pol = MC.ai.policies.earlyTurnDiscipline;
  const wEnd = pol.weight(s, endTurn, moves);
  const wBank = pol.weight(s, bankAction, moves);
  assert.equal(wEnd, MC.config.ai.biasEarlyEndTurnOverBankActionsK);
  assert.equal(wBank, 1);
  assert.ok(wEnd > wBank, "expected EndTurn weight > bank action weight");
});

test("ai: earlyTurnDiscipline does not boost EndTurn when hand<=2 (allow empty-hand draw-5 chase)", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  const s = MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  MC.state.clearPrompt(s);
  s.players[0].bank = [];
  s.players[0].sets = [];
  s.players[1].bank = [];
  s.players[1].sets = [];

  const a0 = takeUidAndRemoveEverywhere(MC, s, "rent_cb");
  const a1 = takeUidAndRemoveEverywhere(MC, s, "just_say_no");
  s.players[0].hand = [a0, a1];

  const moves = MC.engine.legalMoves(s);
  const endTurn = moves.find((m) => m && m.kind === "endTurn");
  const bankAction = moves.find((m) => m && m.kind === "bank");
  assert.ok(endTurn, "expected endTurn move");
  assert.ok(bankAction, "expected bank move");

  const pol = MC.ai.policies.earlyTurnDiscipline;
  assert.equal(pol.weight(s, endTurn, moves), 1);
  assert.equal(pol.weight(s, bankAction, moves), 1);
});

test("ai: earlyTurnDiscipline prefers banking money until buffer is reached", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  const s = MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  MC.state.clearPrompt(s);
  s.players[0].bank = [];
  s.players[0].sets = [];
  s.players[1].bank = [];
  s.players[1].sets = [];

  const money = takeUidAndRemoveEverywhere(MC, s, "money_1");
  s.players[0].hand = [money];

  const moves = MC.engine.legalMoves(s);
  const bankMoney = moves.find((m) => m && m.kind === "bank" && m.card && m.card.uid === money);
  assert.ok(bankMoney, "expected bank money move");

  const pol = MC.ai.policies.earlyTurnDiscipline;
  assert.equal(pol.weight(s, bankMoney, moves), MC.config.ai.biasEarlyBankMoneyK);
});

