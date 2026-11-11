import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("anim.present: queued xfer-to-promptBuf hides uid from payBuf overlay", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });

  const uid = s.deck[0];
  assert.ok(uid, "expected a uid");

  // Show a payDebt buffer with this uid.
  ctx.MC.state.setPrompt(s, { kind: "payDebt", p: 1, toP: 0, rem: 7, buf: [uid], srcAction: null });

  const view = ctx.MC.ui.newView();
  view.anim.q.push({ kind: "xfer", uid, phase: "move", to: { p: 1, zone: "promptBuf", i: 0 } });

  const c1 = ctx.MC.ui.computeRowModels(s, view);
  const rowC1 = c1.models[ctx.MC.render.ROW_CENTER];
  const payBuf1 = rowC1.overlayItems.find((it) => it && it.kind === "payBuf");
  assert.ok(payBuf1, "expected payBuf overlay");
  assert.ok(Array.isArray(payBuf1.uids));
  assert.ok(!payBuf1.uids.includes(uid), "expected uid hidden while queued xfer-to-promptBuf exists");

  // With no queued xfer-to-promptBuf, the buffer should show the uid again.
  view.anim.q = [];
  const c2 = ctx.MC.ui.computeRowModels(s, view);
  const rowC2 = c2.models[ctx.MC.render.ROW_CENTER];
  const payBuf2 = rowC2.overlayItems.find((it) => it && it.kind === "payBuf");
  assert.ok(payBuf2, "expected payBuf overlay");
  assert.ok(payBuf2.uids.includes(uid), "expected uid visible when no xfer-to-promptBuf exists");
});

test("anim.tick: xfer-to-promptBuf does not unhide uid at destination", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });

  const uid = s.deck[0];
  assert.ok(uid, "expected a uid");

  // Simulate the uid already being in the (rendered) destination due to rules mutating state.
  s.players[0].bank = [uid];

  const view = ctx.MC.ui.newView();
  view.anim.hiddenByUid = {};
  view.anim.active = {
    kind: "xfer",
    uid,
    fromPromptBuf: false,
    t: 0,
    frames: 1,
    gapFrames: 0,
    phase: "move",
    to: { p: 1, zone: "promptBuf", i: 0 }
  };

  ctx.MC.anim.tick(s, view);
  assert.equal(view.anim.hiddenByUid[uid], true, "expected uid to remain hidden after landing in promptBuf");

  const c = ctx.MC.ui.computeRowModels(s, view);
  const rmHand = c.models[ctx.MC.render.ROW_P_HAND];
  const hasBankUid = rmHand.items.some((it) => it && it.kind === "bank" && it.uid === uid);
  assert.ok(!hasBankUid, "expected destination bank not to show uid while hiddenByUid is held");
});

test("anim.present: holdFrom to promptBuf freezes source stack positions", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });

  const u0 = s.deck[0];
  const u1 = s.deck[1];
  const u2 = s.deck[2];
  assert.ok(u0 && u1 && u2, "expected 3 uids");

  // Create a small bank stack and snapshot it.
  s.players[0].hand = [];
  s.players[0].bank = [u0, u1, u2];
  const view = ctx.MC.ui.newView();
  ctx.MC.ui.computeRowModels(s, view);
  const snap = { ...view.anim.lastPosByUid };

  // Remove one card (as if it was selected to pay) and enter a holdFrom xfer-to-promptBuf.
  s.players[0].bank = [u0, u2];
  view.anim.active = {
    kind: "xfer",
    uid: u1,
    phase: "holdFrom",
    t: 0,
    holdFromFrames: 10,
    frames: 8,
    gapFrames: 2,
    fromRow: ctx.MC.render.ROW_P_HAND,
    fromStackKey: "bank:p0:row4",
    to: { p: 0, zone: "promptBuf", i: 0 }
  };

  const c2 = ctx.MC.ui.computeRowModels(s, view);
  const rm2 = c2.models[ctx.MC.render.ROW_P_HAND];
  const cam = view.camX[ctx.MC.render.ROW_P_HAND];

  for (const uid of [u0, u2]) {
    const it = rm2.items.find((x) => x && x.kind === "bank" && x.uid === uid);
    assert.ok(it, `expected bank item for uid ${uid}`);
    assert.equal(it.x - cam, snap[uid].x, "expected bank item to keep prior screen-x during holdFrom");
  }
});

