import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("scenario: showcase loads (busy board, no prompt, no winner)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "showcase", seedU32: 1 });

  assert.equal(s.winnerP, ctx.MC.state.NO_WINNER);
  assert.equal(s.prompt, null);
  assert.equal(s.activeP, 0);
  assert.equal(s.playsLeft, 3);

  assert.equal(s.players[0].sets.length, 4);
  assert.equal(s.players[1].sets.length, 2);

  assert.equal(s.players[0].hand.length, 7);
  const def2 = ctx.MC.state.defByUid(s, s.players[0].hand[2]);
  assert.equal(def2.id, "rent_any", "expected Rent Any at hand index 2");

  assert.ok(s.players[0].bank.length >= 1, "expected player to have a bank (includes a banked action)");
  assert.ok(s.players[1].hand.length >= 4, "expected opponent hand to be non-empty/busy");
  assert.ok(s.discard.length >= 3, "expected discard depth for screenshot readability");
});

