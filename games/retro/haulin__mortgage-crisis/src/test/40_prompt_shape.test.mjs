import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

function assertPromptShape(ctx, pr) {
  assert.ok(pr && typeof pr === "object", "expected prompt object");
  assert.equal(typeof pr.kind, "string", "expected prompt.kind string");
  assert.ok(pr.kind.length > 0, "expected prompt.kind non-empty");
  assert.ok(pr.p === 0 || pr.p === 1, "expected prompt.p to be 0 or 1");

  const assertSrcActionShape = (srcAction) => {
    assert.ok(srcAction && typeof srcAction === "object", "expected srcAction object");
    assert.equal(typeof srcAction.kind, "string", "expected srcAction.kind string");
    assert.ok(srcAction.kind.length > 0, "expected srcAction.kind non-empty");
    assert.ok(srcAction.fromP === 0 || srcAction.fromP === 1, "expected srcAction.fromP to be 0 or 1");
    assert.equal(typeof srcAction.actionUid, "number", "expected srcAction.actionUid number");
    assert.ok(Number.isFinite(srcAction.actionUid));
    assert.ok(Number.isInteger(srcAction.actionUid));
    assert.ok(srcAction.actionUid > 0);
  };

  if (pr.kind === "discardDown") {
    assert.equal(typeof pr.nDiscarded, "number");
    assert.ok(Number.isFinite(pr.nDiscarded));
    assert.ok(Number.isInteger(pr.nDiscarded));
    assert.ok(pr.nDiscarded >= 0);
    return;
  }

  if (pr.kind === "payDebt") {
    assert.ok(pr.toP === 0 || pr.toP === 1, "expected prompt.toP to be 0 or 1");
    assert.equal(typeof pr.rem, "number");
    assert.ok(Number.isFinite(pr.rem));
    assert.ok(Number.isInteger(pr.rem));
    assert.ok(Array.isArray(pr.buf), "expected prompt.buf array");
    if (pr.srcAction != null) assertSrcActionShape(pr.srcAction);
    return;
  }

  if (pr.kind === "respondAction") {
    if (pr.srcAction != null) assertSrcActionShape(pr.srcAction);
    assert.ok(pr.target && typeof pr.target === "object", "expected prompt.target object");
    assert.equal(typeof pr.target.uid, "number", "expected prompt.target.uid number");
    assert.ok(Number.isFinite(pr.target.uid));
    assert.ok(Number.isInteger(pr.target.uid));
    assert.ok(pr.target.uid > 0);
    assert.ok(pr.target.loc && typeof pr.target.loc === "object", "expected prompt.target.loc object");
    assert.ok(pr.target.loc.p === 0 || pr.target.loc.p === 1, "expected target.loc.p 0|1");
    assert.equal(typeof pr.target.loc.zone, "string", "expected target.loc.zone string");
    assert.ok(pr.target.loc.zone.length > 0, "expected target.loc.zone non-empty");
    if (pr.target.loc.zone === "setProps") {
      assert.equal(typeof pr.target.loc.setI, "number");
      assert.ok(Number.isInteger(pr.target.loc.setI));
      assert.ok(pr.target.loc.setI >= 0);
      assert.equal(typeof pr.target.loc.i, "number");
      assert.ok(Number.isInteger(pr.target.loc.i));
      assert.ok(pr.target.loc.i >= 0);
    }
    return;
  }

  if (pr.kind === "placeReceived") {
    assert.ok(Array.isArray(pr.uids), "expected prompt.uids array");
    return;
  }

  if (pr.kind === "replaceWindow") {
    assert.equal(typeof pr.srcSetI, "number");
    assert.ok(Number.isFinite(pr.srcSetI));
    assert.ok(Number.isInteger(pr.srcSetI));
    assert.ok(pr.srcSetI >= 0);

    assert.equal(typeof pr.excludeUid, "number");
    assert.ok(Number.isFinite(pr.excludeUid));
    assert.ok(Number.isInteger(pr.excludeUid));
    assert.ok(pr.excludeUid > 0);

    if (pr.resume != null) {
      assert.ok(pr.resume && typeof pr.resume === "object", "expected resume object");
      assert.equal(pr.resume.kind, "placeReceived");
      assert.ok(Array.isArray(pr.resume.uids), "expected resume.uids array");
    }
    return;
  }

  assert.fail(`unexpected prompt kind: ${pr.kind}`);
}

test("setPrompt creates canonical prompt shapes and clones arrays", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });

  // discardDown
  ctx.MC.state.setPrompt(s, { kind: "discardDown", p: 0 });
  assertPromptShape(ctx, s.prompt);
  assert.equal(s.prompt.kind, "discardDown");
  assert.equal(s.prompt.p, 0);
  assert.equal(s.prompt.nDiscarded, 0);

  // payDebt clones buf
  const buf = [1, 2, 3];
  const srcAction = { kind: "rent", fromP: 0, actionUid: 123 };
  ctx.MC.state.setPrompt(s, { kind: "payDebt", p: 1, toP: 0, rem: 7, buf, srcAction });
  assertPromptShape(ctx, s.prompt);
  assert.equal(s.prompt.kind, "payDebt");
  assert.notEqual(s.prompt.buf, buf, "expected buf to be cloned");
  assert.deepEqual(s.prompt.buf, buf);
  assert.equal(s.prompt.rem, 7);
  assert.ok(s.prompt.srcAction, "expected srcAction to be preserved when provided");
  assert.notEqual(s.prompt.srcAction, srcAction, "expected srcAction to be cloned");
  assert.equal(s.prompt.srcAction.kind, "rent");
  assert.equal(s.prompt.srcAction.fromP, 0);
  assert.equal(s.prompt.srcAction.actionUid, 123);

  // respondAction canonicalizes payload
  ctx.MC.state.setPrompt(s, {
    kind: "respondAction",
    p: 1,
    srcAction: { kind: "slyDeal", fromP: 0, actionUid: 77 },
    target: { uid: 88, loc: { p: 0, zone: "setProps", setI: 0, i: 0 } }
  });
  assertPromptShape(ctx, s.prompt);
  assert.equal(s.prompt.kind, "respondAction");
  assert.equal(s.prompt.p, 1);
  assert.equal(s.prompt.srcAction.kind, "slyDeal");
  assert.equal(s.prompt.target.uid, 88);

  // placeReceived clones uids
  const uids = [10, 11];
  ctx.MC.state.setPrompt(s, { kind: "placeReceived", p: 0, uids });
  assertPromptShape(ctx, s.prompt);
  assert.equal(s.prompt.kind, "placeReceived");
  assert.notEqual(s.prompt.uids, uids, "expected uids to be cloned");
  assert.deepEqual(s.prompt.uids, uids);

  // replaceWindow canonicalizes and clones resume
  const resumeUids = [12, 13];
  ctx.MC.state.setPrompt(s, { kind: "replaceWindow", p: 1, srcSetI: 2, excludeUid: 55, resume: { kind: "placeReceived", uids: resumeUids } });
  assertPromptShape(ctx, s.prompt);
  assert.equal(s.prompt.kind, "replaceWindow");
  assert.equal(s.prompt.p, 1);
  assert.equal(s.prompt.srcSetI, 2);
  assert.equal(s.prompt.excludeUid, 55);
  assert.ok(s.prompt.resume, "expected resume");
  assert.notEqual(s.prompt.resume.uids, resumeUids, "expected resume.uids to be cloned");
  assert.deepEqual(s.prompt.resume.uids, resumeUids);
});

test("setPrompt throws on unknown prompt kind", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  assert.throws(() => ctx.MC.state.setPrompt(s, { kind: "nope", p: 0 }));
});

test("engine-created prompts always satisfy prompt shape contract", async () => {
  const ctx = await loadSrcIntoVm();

  // discardDown via endTurn attempt when hand > 7
  {
    const s = ctx.MC.state.newGame({ seedU32: 1 });
    const p = s.activeP;
    s.players[p].hand.push(s.deck.pop());
    ctx.MC.engine.applyCommand(s, { kind: "endTurn" });
    assert.ok(s.prompt);
    assertPromptShape(ctx, s.prompt);
    assert.equal(s.prompt.kind, "discardDown");
  }

  // payDebt + placeReceived via scenarios.
  {
    const s = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });
    assert.ok(s.prompt);
    assertPromptShape(ctx, s.prompt);
    assert.equal(s.prompt.kind, "payDebt");
    assert.equal(s.prompt.buf.length, 0);
  }

  {
    const s = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
    assert.ok(s.prompt);
    assertPromptShape(ctx, s.prompt);
    assert.equal(s.prompt.kind, "placeReceived");
    assert.ok(s.prompt.uids.length > 0);
  }

  // replaceWindow via scenario (after a property play)
  {
    const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
    const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
    assert.ok(mv, "expected a playProp move into set 0");
    ctx.MC.engine.applyCommand(s, mv);
    assert.ok(s.prompt);
    assertPromptShape(ctx, s.prompt);
    assert.equal(s.prompt.kind, "replaceWindow");
  }
});

