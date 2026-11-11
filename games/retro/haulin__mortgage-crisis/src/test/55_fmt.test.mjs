import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

test("fmt: targetingTitle shows Drop when drag unsnapped even if cmd is Source", async () => {
  const ctx = await loadSrcIntoVm();
  const t = { mouse: { dragMode: true, dragging: true, snapped: false } };
  const cmd = { kind: "source" };
  assert.equal(ctx.MC.fmt.targetingTitle(t, cmd), "Drop");
});

test("fmt: targetingTitle shows Cancel for Source when snapped", async () => {
  const ctx = await loadSrcIntoVm();
  const t = {
    kind: "bank",
    hold: false,
    cmds: [{ kind: "source" }],
    card: { def: { kind: ctx.MC.CardKind.Money } },
    mouse: { dragMode: true, dragging: true, snapped: true }
  };
  const cmd = { kind: "source" };
  assert.equal(ctx.MC.fmt.targetingTitle(t, cmd), "Cancel");
});

test("fmt: targetingHelp uses Confirm (not Drop) for drag-release when snapped", async () => {
  const ctx = await loadSrcIntoVm();
  const t = {
    kind: "sly",
    hold: true,
    hintMode: "controller",
    card: { def: { kind: ctx.MC.CardKind.Action } },
    mouse: { dragMode: true, dragging: true, snapped: true }
  };
  const h = ctx.MC.fmt.targetingHelp(t);
  assert.ok(String(h).includes("Release:Confirm"), "expected drag hint to say Release:Confirm");
  assert.equal(String(h).includes("Release:Drop"), false, "expected drag hint to not say Release:Drop");
});

test("fmt: targetingHelp uses Confirm (not Drop) for hold-release A", async () => {
  const ctx = await loadSrcIntoVm();
  const t = {
    kind: "rent",
    hold: true,
    hintMode: "controller",
    card: { def: { kind: ctx.MC.CardKind.Action } },
    mouse: { dragMode: false, dragging: false, snapped: false }
  };
  const h = ctx.MC.fmt.targetingHelp(t);
  assert.ok(String(h).includes("Release A: Confirm"), "expected hold hint to say Release A: Confirm");
  assert.equal(String(h).includes("Release A: Drop"), false, "expected hold hint to not say Release A: Drop");
});

test("fmt: targetingHelp mouseClick is two lines (Click then Right)", async () => {
  const ctx = await loadSrcIntoVm();
  const t = {
    kind: "place",
    hold: false,
    hintMode: "mouseClick",
    card: { def: { kind: ctx.MC.CardKind.Property } },
    mouse: { dragMode: false, dragging: false, snapped: false }
  };
  const h = ctx.MC.fmt.targetingHelp(t);
  assert.equal(String(h), "Click:Confirm\nRight:Cancel");
});

