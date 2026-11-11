import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("cmd profiles: menu kinds define menu hooks (avoid runtime fallbacks)", async () => {
  const ctx = await loadSrcIntoVm();
  const { MC } = ctx;

  assert.ok(Array.isArray(MC.cmd.menuKinds) && MC.cmd.menuKinds.length > 0, "expected MC.cmd.menuKinds");
  assert.equal(typeof MC.cmd.buildHoldChain, "function", "expected MC.cmd.buildHoldChain");
  assert.equal(typeof MC.cmd.previewForCmd, "function", "expected MC.cmd.previewForCmd");

  for (const kind of MC.cmd.menuKinds) {
    const prof = MC.cmd.getProfile(kind);
    assert.ok(prof, `expected cmd profile for menu kind '${kind}'`);
    assert.equal(typeof prof.menuLabel, "function", `expected ${kind}.menuLabel(state, cmds)`);
    assert.equal(typeof prof.menuHoverPreview, "boolean", `expected ${kind}.menuHoverPreview boolean`);
    assert.ok(prof.ui && typeof prof.ui.mode === "string", `expected ${kind}.ui.mode`);
  }

  const sly = MC.cmd.getProfile("sly");
  assert.ok(sly && sly.ui && sly.ui.mode === "cursor", "expected sly to be cursor-mode");
});

