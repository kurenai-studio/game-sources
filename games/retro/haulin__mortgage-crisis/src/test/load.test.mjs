import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("src bundle loads and exposes MC + TIC", async () => {
  const context = await loadSrcIntoVm();

  assert.equal(typeof context.MC, "object");
  assert.equal(typeof context.MC.mainTick, "function");
  assert.equal(typeof context.TIC, "function");
  assert.equal(typeof context.MC.bootTick, "undefined");

  // Animation module should always exist (avoid defensive checks in cartridge code).
  assert.equal(typeof context.MC.anim, "object");
  assert.equal(typeof context.MC.anim.present, "function");
  assert.equal(typeof context.MC.anim.tick, "function");
  assert.equal(typeof context.MC.anim.onEvents, "function");
  assert.equal(typeof context.MC.anim.feedbackTick, "function");
  assert.equal(typeof context.MC.anim.feedbackError, "function");

  // Core modules should always exist (avoid MC.* existence checks in cartridge code).
  assert.equal(typeof context.MC.ui, "object");
  assert.equal(typeof context.MC.ui.newView, "function");
  assert.equal(typeof context.MC.ui.computeRowModels, "function");
  assert.equal(typeof context.MC.ui.step, "function");

  assert.equal(typeof context.MC.controls, "object");
  assert.equal(typeof context.MC.controls.newState, "function");
  assert.equal(typeof context.MC.controls.pollGlobals, "function");
  assert.equal(typeof context.MC.controls.actions, "function");

  assert.equal(typeof context.MC.render, "object");
  assert.equal(typeof context.MC.render.drawFrame, "function");
});

