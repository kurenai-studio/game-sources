import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

function rawButtons({ downIds = [], pressedIds = [] } = {}) {
  const down = Array(8).fill(false);
  const pressed = Array(8).fill(false);
  for (const id of downIds) down[id] = true;
  for (const id of pressedIds) pressed[id] = true;
  return { down, pressed };
}

function rawMouse({ x = 0, y = 0, left = false, middle = false, right = false, scrollx = 0, scrolly = 0 } = {}) {
  return { x, y, left, middle, right, scrollx, scrolly };
}

function rawInput({ downIds = [], pressedIds = [], mouse = null } = {}) {
  const r = rawButtons({ downIds, pressedIds });
  if (mouse) r.mouse = mouse;
  return r;
}

test("controls: inspect becomes active after hold delay", async () => {
  const ctx = await loadSrcIntoVm();
  const st = ctx.MC.controls.newState();

  // Hold X (id=6) for 5 frames: still inactive (default delay=6).
  for (let f = 0; f < 5; f++) {
    const raw = rawButtons({ downIds: [6], pressedIds: f === 0 ? [6] : [] });
    const a = ctx.MC.controls.actions(st, raw, ctx.MC.config.controls);
    assert.equal(a.x.inspectActive, false);
  }

  // On frame 6 it becomes active.
  {
    const raw = rawButtons({ downIds: [6] });
    const a = ctx.MC.controls.actions(st, raw, ctx.MC.config.controls);
    assert.equal(a.x.inspectActive, true);
  }
});

test("controls: mouse middle-click becomes inspect after hold delay", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.mouse.enabled = true;
  const st = ctx.MC.controls.newState();
  const cfg = ctx.MC.config.controls;

  // Hold middle for 5 frames: still inactive (default delay=6).
  for (let f = 0; f < 5; f++) {
    const a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 10, y: 10, middle: true }) }), cfg);
    assert.equal(a.x.inspectActive, false);
    assert.equal(a.x.down, true);
  }

  // On frame 6 it becomes active.
  {
    const a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 10, y: 10, middle: true }) }), cfg);
    assert.equal(a.x.inspectActive, true);
    assert.equal(a.x.down, true);
  }

  // Release -> inactive.
  {
    const a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 10, y: 10, middle: false }) }), cfg);
    assert.equal(a.x.inspectActive, false);
    assert.equal(a.x.down, false);
  }
});

test("controls: A tap vs hold+move grab", async () => {
  const ctx = await loadSrcIntoVm();
  const cfg = { ...ctx.MC.config.controls, aHoldFallbackFrames: 18 };

  // Tap A: press then release without movement.
  {
    const st = ctx.MC.controls.newState();
    let a;
    a = ctx.MC.controls.actions(st, rawButtons({ downIds: [4], pressedIds: [4] }), cfg);
    assert.equal(a.a.tap, false);
    a = ctx.MC.controls.actions(st, rawButtons({ downIds: [] }), cfg);
    assert.equal(a.a.tap, true);
  }

  // Hold+move: press A, then while held press Left -> grabStart fires once, tap never fires.
  {
    const st = ctx.MC.controls.newState();
    let a;
    a = ctx.MC.controls.actions(st, rawButtons({ downIds: [4], pressedIds: [4] }), cfg);
    assert.equal(a.a.grabStart, false);

    a = ctx.MC.controls.actions(st, rawButtons({ downIds: [2, 4], pressedIds: [2] }), cfg);
    assert.equal(a.a.grabStart, true);

    a = ctx.MC.controls.actions(st, rawButtons({ downIds: [2, 4] }), cfg);
    assert.equal(a.a.grabStart, false);

    a = ctx.MC.controls.actions(st, rawButtons({ downIds: [] }), cfg);
    assert.equal(a.a.tap, false);
  }
});

test("controls: mouse click vs drag (A tap vs grabStart)", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.mouse.dragStartPx = 3;
  const cfg = ctx.MC.config.controls;

  // Click: press then release without moving -> tap.
  {
    const st = ctx.MC.controls.newState();
    let a;
    a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 10, y: 10, left: true }) }), cfg);
    assert.equal(a.a.pressed, true);
    assert.equal(a.a.grabStart, false);
    assert.equal(a.a.tap, false);

    a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 10, y: 10, left: false }) }), cfg);
    assert.equal(a.a.tap, true);
    assert.equal(a.mouse.left.tap, true);
  }

  // Drag: move beyond threshold while left held -> grabStart once, no tap.
  {
    const st = ctx.MC.controls.newState();
    let a;
    a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 10, y: 10, left: true }) }), cfg);
    assert.equal(a.a.grabStart, false);

    a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 20, y: 10, left: true }) }), cfg);
    assert.equal(a.a.grabStart, true);
    assert.equal(a.mouse.dragStart, true);
    assert.equal(a.mouse.dragging, true);

    a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 21, y: 10, left: true }) }), cfg);
    assert.equal(a.a.grabStart, false);

    a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 21, y: 10, left: false }) }), cfg);
    assert.equal(a.a.tap, false);
    assert.equal(a.mouse.left.tap, false);
  }
});

test("controls: wheel invert knob flips Up/Down mapping", async () => {
  const ctx = await loadSrcIntoVm();
  const cfg = ctx.MC.config.controls;
  const st = ctx.MC.controls.newState();

  ctx.MC.config.mouse.enabled = true;
  ctx.MC.config.mouse.wheelNav = true;

  // Baseline mapping (wheelInvertY=false): negative => Up.
  ctx.MC.config.mouse.wheelInvertY = false;
  let a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 0, y: 0, scrolly: -1 }) }), cfg);
  assert.equal(!!a.nav.up, true);
  assert.equal(!!a.nav.down, false);

  // Inverted mapping (wheelInvertY=true): negative => Down.
  ctx.MC.config.mouse.wheelInvertY = true;
  a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 0, y: 0, scrolly: -1 }) }), cfg);
  assert.equal(!!a.nav.up, false);
  assert.equal(!!a.nav.down, true);
});

test("ui: early hold-A grab does not move cursor selection", async () => {
  const ctx = await loadSrcIntoVm();

  // Build a deterministic hand with 2 known properties so we can detect drift.
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  function takeFromDeckByDefId(defId) {
    const uid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === defId);
    assert.ok(uid, `expected ${defId} uid in deck`);
    s.deck = s.deck.filter((u) => u !== uid);
    return uid;
  }

  // Use money cards (always bankable) so grabStart reliably enters targeting.
  const uidA = takeFromDeckByDefId("money_1");
  const uidB = takeFromDeckByDefId("money_2");
  s.players[0].hand = [uidA, uidB];
  s.players[0].bank = [];
  s.players[0].sets = [];
  s.players[1].hand = [];
  s.players[1].bank = [];
  s.players[1].sets = [];

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  const st = ctx.MC.controls.newState();
  const cfg = ctx.MC.config.controls;

  // Frame 1: press A (start holding).
  const a1 = ctx.MC.controls.actions(st, rawButtons({ downIds: [4], pressedIds: [4] }), cfg);
  ctx.MC.ui.step(s, view, a1);

  // Frame 2: while holding A, press Right. This should trigger grabStart,
  // but must NOT move the cursor to the right-hand card before entering targeting.
  const a2 = ctx.MC.controls.actions(st, rawButtons({ downIds: [3, 4], pressedIds: [3] }), cfg);
  ctx.MC.ui.step(s, view, a2);

  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active, "expected targeting to be active");
  assert.equal(view.targeting.card.uid, uidA, "expected grabbed uid to remain the original selection");
  assert.equal(view.cursor.i, 0, "expected cursor index to remain unchanged on early-grab frame");
});

test("ui: mouse hover moves cursor selection (browse)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const view = ctx.MC.ui.newView();
  view.mode = "browse";
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Pick a different hand card in the same row.
  const before = ctx.MC.ui.computeRowModels(s, view);
  const rm = before.models[ctx.MC.render.ROW_P_HAND];
  const pickI = rm.items.findIndex((it) => it && it.kind === "hand" && it.loc && it.loc.zone === "hand" && it.loc.p === 0 && it.loc.i === 1);
  assert.ok(pickI >= 0, "expected a second hand card");
  const it = rm.items[pickI];
  const cam = (view.camX && view.camX[ctx.MC.render.ROW_P_HAND] != null) ? view.camX[ctx.MC.render.ROW_P_HAND] : 0;
  const x = it.x - cam + 2;
  const y = it.y + 2;

  ctx.MC.ui.step(s, view, {
    nav: {},
    a: {},
    b: {},
    x: {},
    mouse: { avail: true, x, y, moved: true, scrollX: 0, scrollY: 0, left: { down: false, pressed: false, released: false, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: false, dragStart: false }
  });

  assert.equal(view.cursor.row, ctx.MC.render.ROW_P_HAND);
  assert.equal(view.cursor.i, pickI);
});

test("ui: mouse DnD cancels when released off-target", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const view = ctx.MC.ui.newView();
  view.mode = "browse";
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Mouse should start on the selected hand card (the thing we're dragging).
  const c0 = ctx.MC.ui.computeRowModels(s, view);
  ctx.MC.ui.updateCameras(s, view, c0);
  const sel0 = c0.selected;
  assert.ok(sel0, "expected a selected item");
  const cam0 = (view.camX && view.camX[sel0.row] != null) ? view.camX[sel0.row] : 0;
  const x0 = sel0.x - cam0 + 2;
  const y0 = sel0.y + 2;

  // Enter targeting via mouse drag-start.
  ctx.MC.ui.step(s, view, {
    nav: {},
    a: { grabStart: true },
    mouse: { avail: true, x: x0, y: y0, moved: false, scrollX: 0, scrollY: 0, left: { down: true, pressed: true, released: false, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: true, dragStart: true }
  });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.ok(view.targeting.mouse && view.targeting.mouse.dragMode, "expected dragMode targeting");

  // Drag somewhere irrelevant.
  ctx.MC.ui.step(s, view, {
    nav: {},
    a: { down: true },
    mouse: { avail: true, x: 0, y: 0, moved: true, scrollX: 0, scrollY: 0, left: { down: true, pressed: false, released: false, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: true, dragStart: false }
  });
  assert.equal(view.targeting.mouse.snapped, false);

  // Release off-target -> cancel targeting, no intent.
  const intent = ctx.MC.ui.step(s, view, {
    nav: {},
    a: { released: true },
    mouse: { avail: true, x: 0, y: 0, moved: false, scrollX: 0, scrollY: 0, left: { down: false, pressed: false, released: true, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: false, dragStart: false }
  });
  assert.equal(intent, null);
  assert.equal(view.mode, "browse");
});

test("ui: mouse DnD cancels when released back on source (hysteresis)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  ctx.MC.config.mouse.enabled = true;
  ctx.MC.config.mouse.dragStartPx = 3;

  const view = ctx.MC.ui.newView();
  view.mode = "browse";
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Mouse should start on the selected hand card (the thing we're dragging).
  const c0 = ctx.MC.ui.computeRowModels(s, view);
  ctx.MC.ui.updateCameras(s, view, c0);
  const sel0 = c0.selected;
  assert.ok(sel0, "expected a selected item");
  const cam0 = (view.camX && view.camX[sel0.row] != null) ? view.camX[sel0.row] : 0;
  const x0 = sel0.x - cam0 + 2;
  const y0 = sel0.y + 2;

  // Enter targeting via mouse drag-start.
  ctx.MC.ui.step(s, view, {
    nav: {},
    a: { grabStart: true },
    mouse: { avail: true, x: x0, y: y0, moved: false, scrollX: 0, scrollY: 0, left: { down: true, pressed: true, released: false, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: true, dragStart: true }
  });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.ok(view.targeting.mouse && view.targeting.mouse.dragMode, "expected dragMode targeting");

  // Snap to a real destination first (so we can test "snap back to source").
  const c1 = ctx.MC.ui.computeRowModels(s, view);
  const rowT1 = ctx.MC.render.ROW_P_TABLE;
  const rmT1 = c1.models[rowT1];
  assert.ok(rmT1 && rmT1.newSetX != null, "expected newSetX in targeting");
  const xDest = rmT1.newSetX - (view.camX[rowT1] || 0) + 2;
  const yDest = ctx.MC.layout.faceYForRow(rowT1) + 2;

  ctx.MC.ui.step(s, view, {
    nav: {},
    a: { down: true },
    mouse: { avail: true, x: xDest, y: yDest, moved: true, scrollX: 0, scrollY: 0, left: { down: true, pressed: false, released: false, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: true, dragStart: false }
  });
  assert.equal(view.targeting.mouse.snapped, true);

  // Move back onto source; hysteresis should snap to Source.
  ctx.MC.ui.step(s, view, {
    nav: {},
    a: { down: true },
    mouse: { avail: true, x: x0, y: y0, moved: true, scrollX: 0, scrollY: 0, left: { down: true, pressed: false, released: false, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: true, dragStart: false }
  });
  assert.equal(view.targeting.mouse.snapped, true);

  // Release on source -> cancel targeting, no intent, cursor restored to source.
  const intent = ctx.MC.ui.step(s, view, {
    nav: {},
    a: { released: true },
    mouse: { avail: true, x: x0, y: y0, moved: false, scrollX: 0, scrollY: 0, left: { down: false, pressed: false, released: true, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: false, dragStart: false }
  });
  assert.equal(intent, null);
  assert.equal(view.mode, "browse");
  assert.equal(view.cursor.row, ctx.MC.render.ROW_P_HAND);
  assert.equal(view.cursor.i, 0);
});

test("ui: unsnapped mouse drag shows ghosts for all legal destinations", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const view = ctx.MC.ui.newView();
  view.mode = "browse";
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Mouse should start on the selected hand card (the thing we're dragging).
  const c0 = ctx.MC.ui.computeRowModels(s, view);
  ctx.MC.ui.updateCameras(s, view, c0);
  const sel0 = c0.selected;
  assert.ok(sel0, "expected a selected item");
  const cam0 = (view.camX && view.camX[sel0.row] != null) ? view.camX[sel0.row] : 0;
  const x0 = sel0.x - cam0 + 2;
  const y0 = sel0.y + 2;

  // Enter targeting via mouse drag-start.
  ctx.MC.ui.step(s, view, {
    nav: {},
    a: { grabStart: true },
    mouse: { avail: true, x: x0, y: y0, moved: false, scrollX: 0, scrollY: 0, left: { down: true, pressed: true, released: false, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: true, dragStart: true }
  });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);

  // Drag somewhere irrelevant (stay unsnapped).
  ctx.MC.ui.step(s, view, {
    nav: {},
    a: { down: true },
    mouse: { avail: true, x: 0, y: 0, moved: true, scrollX: 0, scrollY: 0, left: { down: true, pressed: false, released: false, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: true, dragStart: false }
  });
  assert.ok(view.targeting.mouse && view.targeting.mouse.dragMode, "expected dragMode");
  assert.equal(view.targeting.mouse.snapped, false);

  const c = ctx.MC.ui.computeRowModels(s, view);
  const rowT = c.models[ctx.MC.render.ROW_P_TABLE];
  assert.ok(rowT && rowT.overlayItems, "expected table overlayItems during targeting");

  const keys = new Set(rowT.overlayItems.filter((it) => it && it.kind === "ghost" && it.stackKey).map((it) => String(it.stackKey)));
  assert.ok(keys.has("newSet:p0:row3"), "expected ghost for newSet");
  assert.ok(keys.has("set:p0:set0"), "expected ghost for existing set0");
});

test("ui: mouse DnD confirms when released on a valid destination", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const view = ctx.MC.ui.newView();
  view.mode = "browse";
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Mouse should start on the selected hand card (the thing we're dragging).
  const c0 = ctx.MC.ui.computeRowModels(s, view);
  ctx.MC.ui.updateCameras(s, view, c0);
  const sel0 = c0.selected;
  assert.ok(sel0, "expected a selected item");
  const cam0 = (view.camX && view.camX[sel0.row] != null) ? view.camX[sel0.row] : 0;
  const x0 = sel0.x - cam0 + 2;
  const y0 = sel0.y + 2;

  // Enter targeting via mouse drag-start.
  ctx.MC.ui.step(s, view, {
    nav: {},
    a: { grabStart: true },
    mouse: { avail: true, x: x0, y: y0, moved: false, scrollX: 0, scrollY: 0, left: { down: true, pressed: true, released: false, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: true, dragStart: true }
  });
  assert.equal(view.mode, "targeting");

  const c = ctx.MC.ui.computeRowModels(s, view);
  const rowT = ctx.MC.render.ROW_P_TABLE;
  const rmT = c.models[rowT];
  assert.ok(rmT && rmT.newSetX != null, "expected newSetX in targeting");
  const camT = (view.camX && view.camX[rowT] != null) ? view.camX[rowT] : 0;
  const x = rmT.newSetX - camT + 2;
  const y = ctx.MC.layout.faceYForRow(rowT) + 2;

  // Hover over newSet while dragging.
  ctx.MC.ui.step(s, view, {
    nav: {},
    a: { down: true },
    mouse: { avail: true, x, y, moved: true, scrollX: 0, scrollY: 0, left: { down: true, pressed: false, released: false, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: true, dragStart: false }
  });
  assert.equal(view.targeting.mouse.snapped, true);

  // Release on destination -> confirm cmd.
  const intent = ctx.MC.ui.step(s, view, {
    nav: {},
    a: { released: true },
    mouse: { avail: true, x, y, moved: false, scrollX: 0, scrollY: 0, left: { down: false, pressed: false, released: true, tap: false }, middle: { down: false, pressed: false, released: false }, right: { down: false, pressed: false, released: false }, dragging: false, dragStart: false }
  });
  assert.ok(intent && intent.kind === "applyCmd", "expected applyCmd intent");
  assert.ok(intent.cmd && intent.cmd.kind, "expected cmd");
});

test("ui: mouse click in empty space does not trigger last selection", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const view = ctx.MC.ui.newView();
  view.mode = "browse";
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  const st = ctx.MC.controls.newState();
  const cfg = ctx.MC.config.controls;

  // Frame 1: press in empty space.
  let a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 0, y: 0, left: true }) }), cfg);
  ctx.MC.ui.step(s, view, a);

  // Frame 2: release (tap) in empty space => should do nothing (no menu, no targeting).
  a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 0, y: 0, left: false }) }), cfg);
  const intent = ctx.MC.ui.step(s, view, a);
  assert.equal(intent, null);
  assert.equal(view.mode, "browse");
  assert.ok(!view.menu || !view.menu.items || view.menu.items.length === 0, "expected no menu from empty click");
});

test("ui: mouse dragStart in empty space does not enter targeting", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.mouse.dragStartPx = 3;

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const view = ctx.MC.ui.newView();
  view.mode = "browse";
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  const st = ctx.MC.controls.newState();
  const cfg = ctx.MC.config.controls;

  // Press in empty space.
  let a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 0, y: 0, left: true }) }), cfg);
  ctx.MC.ui.step(s, view, a);

  // Move far enough to trigger dragStart while still in empty space.
  a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: 10, y: 0, left: true }) }), cfg);
  ctx.MC.ui.step(s, view, a);

  assert.equal(view.mode, "browse");
  assert.ok(!view.targeting || !view.targeting.active, "expected not to enter targeting from empty drag");
});

test("controls: d-pad repeat pulses after delay", async () => {
  const ctx = await loadSrcIntoVm();
  const st = ctx.MC.controls.newState();
  const cfg = { dpadRepeatDelayFrames: 3, dpadRepeatPeriodFrames: 2, aHoldFallbackFrames: 999, xInspectDelayFrames: 999 };

  // Hold Right (id=3) for 6 frames.
  const pulses = [];
  for (let f = 0; f < 6; f++) {
    const raw = rawButtons({ downIds: [3], pressedIds: f === 0 ? [3] : [] });
    const a = ctx.MC.controls.actions(st, raw, cfg);
    pulses.push(!!a.nav.right);
  }

  // Frame-by-frame expectation:
  // f0: pressed -> true
  // f1,f2: false (count < delay)
  // f3: true (first repeat)
  // f4: false
  // f5: true
  assert.deepEqual(pulses, [true, false, false, true, false, true]);
});

test("ui: findBestCursorTarget picks first match in preferred row order", async () => {
  const ctx = await loadSrcIntoVm();

  const models = [
    { items: [{ kind: "a" }] },          // row 0
    { items: [{ kind: "b" }] },          // row 1
    { items: [{ kind: "c" }, { kind: "x" }] }, // row 2
    { items: [] },                       // row 3
    { items: [{ kind: "x" }] },          // row 4
  ];

  const pick = ctx.MC.ui.findBestCursorTarget(models, [4, 2, 1], (it) => it.kind === "x");
  assert.ok(pick);
  assert.equal(pick.row, 4);
  assert.equal(pick.i, 0);
  assert.equal(pick.item.kind, "x");
});

test("ui: findBestCursorTarget returns null when no match", async () => {
  const ctx = await loadSrcIntoVm();

  const models = [
    { items: [{ kind: "a" }] },
    { items: [] },
    { items: [{ kind: "b" }] },
    { items: [] },
    { items: [] },
  ];

  const pick = ctx.MC.ui.findBestCursorTarget(models, [2, 0], (it) => it.kind === "nope");
  assert.equal(pick, null);
});

test("ui: center buttons remain visible during Inspect", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const view = ctx.MC.ui.newView();
  view.mode = "browse";
  view.inspectActive = true;

  const c = ctx.MC.ui.computeRowModels(s, view);
  const center = c.models[ctx.MC.render.ROW_CENTER];
  assert.ok(center && center.items && center.items.length > 0, "expected center items");
  assert.ok(center.items.some((it) => it && it.kind === "btn" && it.id === "endTurn"), "expected End button during Inspect");
});

test("ui: targeting defaults to existing set when available (Place)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Enter targeting via hold-A grab.
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true } });

  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "place");
  assert.ok(view.targeting.cmds.length >= 2, "expected existing + newSet options");
  assert.ok(view.targeting.cmds[0].dest && view.targeting.cmds[0].dest.setI != null, "expected first option to be existing set");
});

test("ui: place preview reserves width so later sets shift (no overlap)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;

  // Add a second set to the right so shifting is observable.
  // Use a Cyan property so colors differ (set legality doesn't matter for shifting).
  const uidC = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_cyan");
  assert.ok(uidC, "expected prop_cyan uid in deck");
  s.deck = s.deck.filter((u) => u !== uidC);
  const set2 = ctx.MC.state.newEmptySet();
  set2.props.push([uidC, ctx.MC.Color.Cyan]);
  s.players[0].sets.push(set2);

  const view = ctx.MC.ui.newView();
  view.mode = "browse";
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Baseline layout (no targeting): record the second set's left edge.
  const before = ctx.MC.ui.computeRowModels(s, view);
  const rowT = before.models[ctx.MC.render.ROW_P_TABLE];
  const xsBefore = rowT.items.filter((it) => it && it.setI === 1).map((it) => it.x);
  assert.ok(xsBefore.length > 0, "expected items for setI=1");
  const xMinBefore = Math.min(...xsBefore);

  // Enter targeting and ensure we are previewing placement into an existing set (setI=0).
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true } });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "place");
  assert.ok(view.targeting.cmds[0] && view.targeting.cmds[0].dest && view.targeting.cmds[0].dest.setI === 0);
  view.targeting.cmdI = 0;

  const after = ctx.MC.ui.computeRowModels(s, view);
  const rowT2 = after.models[ctx.MC.render.ROW_P_TABLE];
  const xsAfter = rowT2.items.filter((it) => it && it.setI === 1).map((it) => it.x);
  assert.ok(xsAfter.length > 0, "expected items for setI=1 after targeting");
  const xMinAfter = Math.min(...xsAfter);

  assert.equal(xMinAfter - xMinBefore, ctx.MC.config.render.layout.stackStrideX);
});

test("ui: wild color toggles and updates cmd list", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 });
  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Enter targeting.
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true } });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "place");

  const def = ctx.MC.state.defByUid(s, view.targeting.card.uid);
  assert.ok(ctx.MC.rules.isWildDef(def), "expected wild card");
  const c0 = def.wildColors[0];
  const c1 = def.wildColors[1];

  // Default is first color when no existing set exists.
  assert.equal(view.targeting.wildColor, c0);

  // Toggle color via Down.
  ctx.MC.ui.step(s, view, { nav: { down: true }, a: {}, b: {}, x: {} });
  assert.equal(view.targeting.wildColor, c1);
  assert.ok(view.targeting.cmds.length >= 1, "expected at least newSet option for wild");
});

test("ui: hold-chain wild can toggle color while Source segment is active (no duplicate Source)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "moveStress", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  ctx.MC.state.clearPrompt(s);

  const wildUid = s.players[0].hand.find((u) => ctx.MC.state.defByUid(s, u).id === "wild_cb");
  assert.ok(wildUid, "expected wild_cb in moveStress hand");
  const wildI = s.players[0].hand.indexOf(wildUid);
  assert.ok(wildI >= 0);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = wildI;

  // Enter hold-chain targeting via hold-A grab.
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.chainActive, "expected hold-chain targeting");
  assert.equal(view.targeting.kind, "place");

  const def = ctx.MC.state.defByUid(s, wildUid);
  assert.ok(ctx.MC.rules.isWildDef(def), "expected wild def");
  const c0 = def.wildColors[0];
  const c1 = def.wildColors[1];
  assert.ok(view.targeting.wildColor === c0 || view.targeting.wildColor === c1);

  // Cycle to Source segment.
  const nPlace = view.targeting.cmds.length;
  for (let step = 0; step < nPlace; step++) ctx.MC.ui.step(s, view, { nav: { right: true }, a: {}, b: {}, x: {} });
  assert.equal(view.targeting.kind, "source");
  assert.ok(view.targeting.cmds && view.targeting.cmds.length === 1);
  assert.equal(view.targeting.cmds[0].kind, "source");

  // While Source segment is active, U/D should still toggle wild color (updates Place segment).
  const prev = view.targeting.wildColor;
  ctx.MC.ui.step(s, view, { nav: { down: true }, a: {}, b: {}, x: {} });
  assert.notEqual(view.targeting.wildColor, prev);
  assert.equal(view.targeting.kind, "source");

  // Cycle back to Place and ensure Place cmds do not include a Source cmd (Source is its own segment).
  ctx.MC.ui.step(s, view, { nav: { left: true }, a: {}, b: {}, x: {} });
  assert.equal(view.targeting.kind, "place");
  assert.equal(view.targeting.cmds.some((c) => c && c.kind === "source"), false);
});

test("ui: browse directional nav - Up from End picks opponent table if present", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  // Give opponent a single table property; clear opponent hand so table is the only Up candidate.
  const takeFromDeckOrHand = (defId) => {
    const zones = [s.deck, s.players[0].hand, s.players[1].hand];
    for (const z of zones) {
      const i = z.findIndex((u) => ctx.MC.state.defByUid(s, u).id === defId);
      if (i >= 0) return z.splice(i, 1)[0];
    }
    return 0;
  };
  const uid = takeFromDeckOrHand("prop_cyan");
  assert.ok(uid, "expected prop_cyan uid in deck or hand");

  const set = ctx.MC.state.newEmptySet();
  set.props.push([uid, ctx.MC.Color.Cyan]);
  s.players[1].sets = [set];
  s.players[1].hand = [];
  s.players[1].bank = [];

  const view = ctx.MC.ui.newView();
  // Select center-row End button: items are [deck, discard, End, ...].
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 2;

  // Ensure cameras are initialized for directional screen-space.
  const c0 = ctx.MC.ui.computeRowModels(s, view);
  ctx.MC.ui.updateCameras(s, view, c0);

  ctx.MC.ui.step(s, view, { nav: { up: true }, a: {}, b: {}, x: {} });
  const c1 = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c1.selected.row, ctx.MC.render.ROW_OP_TABLE);
});

test("ui: browse directional nav - Up from End picks opponent hand if no table", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.players[1].sets = [];
  // Keep exactly 1 opponent hand card to avoid ambiguity.
  const keep = s.players[1].hand[0];
  s.players[1].hand = keep ? [keep] : [];

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 2;

  const c0 = ctx.MC.ui.computeRowModels(s, view);
  ctx.MC.ui.updateCameras(s, view, c0);

  ctx.MC.ui.step(s, view, { nav: { up: true }, a: {}, b: {}, x: {} });
  const c1 = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c1.selected.row, ctx.MC.render.ROW_OP_HAND);
});

test("ui: browse directional nav - Left from End prefers center piles (not opponent hand)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  // Default start: opponent has 5 hand cards, no table sets.
  s.players[1].sets = [];

  const view = ctx.MC.ui.newView();
  // Select center-row End button: items are [deck, discard, End, ...].
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 2;

  const c0 = ctx.MC.ui.computeRowModels(s, view);
  ctx.MC.ui.updateCameras(s, view, c0);

  ctx.MC.ui.step(s, view, { nav: { left: true }, a: {}, b: {}, x: {} });
  const c1 = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c1.selected.row, ctx.MC.render.ROW_CENTER);
  assert.ok(c1.selected.kind === "discard" || c1.selected.kind === "deck");
});

test("ui: browse directional nav - global axis-wrap fallback triggers when no Up candidates", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  // Remove all opponent items so nothing exists above the center row.
  s.players[1].hand = [];
  s.players[1].bank = [];
  s.players[1].sets = [];

  const view = ctx.MC.ui.newView();
  // Start from End (top-most center button), so Up has no candidates.
  const c0 = ctx.MC.ui.computeRowModels(s, view);
  const rmC0 = c0.models[ctx.MC.render.ROW_CENTER];
  const endI = rmC0.items.findIndex((it) => it && it.kind === "btn" && it.id === "endTurn");
  assert.ok(endI >= 0, "expected endTurn button");
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = endI;

  ctx.MC.ui.updateCameras(s, view, c0);

  ctx.MC.ui.step(s, view, { nav: { up: true }, a: {}, b: {}, x: {} });
  const c1 = ctx.MC.ui.computeRowModels(s, view);
  // Wrap should go to the bottom-most row (player hand).
  assert.equal(c1.selected.row, ctx.MC.render.ROW_P_HAND);
});

test("ui: out of plays snaps to End button (one-shot)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;

  const view = ctx.MC.ui.newView();
  // Start somewhere else.
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Prime ux memory at playsLeft=1.
  s.playsLeft = 1;
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  // Transition to 0 plays (no input): should snap to End.
  s.playsLeft = 0;
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "endTurn");
});

test("ui: discardDown prompt locks to hand and A discards a hand card", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  // Force discard prompt.
  ctx.MC.state.setPrompt(s, { kind: "discardDown", p: 0 });

  const view = ctx.MC.ui.newView();
  // Start somewhere else to prove prompt forces us into hand.
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 2;

  // First step: mode sync + cursor lock.
  const intent0 = ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(intent0, null);
  assert.equal(view.mode, "prompt");

  const c0 = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c0.selected, "expected selected item in prompt mode");
  assert.equal(c0.selected.row, ctx.MC.render.ROW_P_HAND);
  assert.equal(c0.selected.kind, "hand");

  // Tap A: discard highlighted hand card.
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.ok(intent && intent.kind === "applyCmd", "expected applyCmd intent");
  assert.equal(intent.cmd.kind, "discard");
  assert.equal(intent.cmd.card.loc.zone, "hand");
  assert.equal(intent.cmd.card.loc.p, 0);
});

test("ui: discardDown prompt allows B to cancel before any discard", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  ctx.MC.state.setPrompt(s, { kind: "discardDown", p: 0 });

  const view = ctx.MC.ui.newView();
  // Enter prompt mode.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: { pressed: true }, x: {} });
  assert.ok(intent && intent.kind === "applyCmd");
  assert.equal(intent.cmd.kind, "cancelPrompt");
});

test("ui: discardDown prompt B after discarding gives negative feedback (no cancel)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  ctx.MC.state.setPrompt(s, { kind: "discardDown", p: 0 });
  // Simulate a discard having already happened.
  if (s.prompt) s.prompt.nDiscarded = 1;

  const view = ctx.MC.ui.newView();
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: { pressed: true }, x: {} });
  assert.equal(intent, null);
  assert.ok(view.feedback && view.feedback.blinkFrames > 0, "expected negative feedback blink");
});

test("ui: menu Place auto-applies when only one destination exists", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  // Add a property color that does not match any existing set => only New set is legal.
  const uid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_cyan");
  assert.ok(uid, "expected prop_cyan uid in deck");
  s.deck = s.deck.filter((u) => u !== uid);
  s.players[0].hand.push(uid);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = s.players[0].hand.length - 1;

  // Tap A to open menu, then tap A again to choose Place (only menu item).
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");
  assert.equal(view.menu.items.length, 2);
  assert.equal(view.menu.items[0].id, "place");
  assert.equal(view.menu.items[0].label, "Place -> New set");
  assert.equal(view.menu.items[1].id, "source");

  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.ok(intent && intent.kind === "applyCmd", "expected applyCmd intent");
  assert.equal(intent.cmd.kind, "playProp");
  assert.equal(view.mode, "browse");
});

test("ui: menu Place for Wild enters targeting even when only one destination exists (color choice)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  // Ensure Wild has no matching existing set destinations: only New set remains.
  s.players[0].sets = [];

  const wildUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "wild_mo");
  assert.ok(wildUid, "expected wild_mo uid in deck");
  s.deck = s.deck.filter((u) => u !== wildUid);
  s.players[0].hand.push(wildUid);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = s.players[0].hand.length - 1;

  // Tap A to open menu, then tap A again to choose Place.
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");
  assert.equal(view.menu.items[0].id, "place");
  assert.equal(view.menu.items[0].label, "Place...");

  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(intent, null, "expected no immediate apply; should enter targeting for Wild color choice");
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "place");
  assert.equal(view.targeting.cmds.at(-1).kind, "source");

  // Regression guard: while selection starts on Source (only one real destination),
  // do not preview/ghost the destination on the table row.
  assert.equal(view.targeting.cmds[view.targeting.cmdI].kind, "source");
  const computed = ctx.MC.ui.computeRowModels(s, view);
  const rowT = computed.models[ctx.MC.render.ROW_P_TABLE];
  const overlaysT = rowT && rowT.overlayItems ? rowT.overlayItems : [];
  assert.equal(overlaysT.length, 0, "expected no table overlays while on Source for single-dest Wild place");

  const c0 = view.targeting.wildColor;
  ctx.MC.ui.step(s, view, { nav: { up: true }, a: {}, b: {}, x: {} });
  assert.notEqual(view.targeting.wildColor, c0, "expected U/D to toggle Wild color while targeting");
});

test("ui: hold-A targeting includes a Source destination (release-A cancels)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Enter targeting via hold-A grab.
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.hold, true);
  assert.ok(view.targeting.chainActive, "expected hold-chain targeting");

  // Cycle to Source segment and release A.
  ctx.MC.ui.step(s, view, { nav: { right: true }, a: {}, b: {}, x: {} });
  ctx.MC.ui.step(s, view, { nav: { right: true }, a: {}, b: {}, x: {} });
  assert.equal(view.targeting.kind, "source");
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { released: true }, b: {}, x: {} });
  assert.equal(intent, null);
  assert.equal(view.mode, "browse");
});

test("ui: menu targeting includes a Source destination (tap-A cancels)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Open menu on a property.
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");
  assert.ok(view.menu.items.some((it) => it && it.id === "place"), "expected Place in menu");

  // Pick Place (index 0 in our current menu composition for properties).
  view.menu.i = 0;
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.hold, false);
  assert.equal(view.targeting.kind, "place");
  assert.equal(view.targeting.cmds.at(-1).kind, "source", "expected Source destination");

  // Select source and tap A to cancel.
  view.targeting.cmdI = view.targeting.cmds.length - 1;
  {
    const c = ctx.MC.ui.computeRowModels(s, view);
    assert.equal(!!(c.meta && c.meta.hideSrc), false, "expected source card visible when Source is selected");
  }
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(intent, null);
  assert.equal(view.mode, "browse");
});

test("ui: moveWild targeting includes a Source destination (tap-A cancels)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  // Trigger replaceWindow then enter moveWild targeting (tap-A flow).
  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  ctx.MC.engine.applyCommand(s, mv);
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "moveWild");
  assert.equal(view.targeting.hold, false);
  assert.equal(view.targeting.cmds.at(-1).kind, "source", "expected Source destination last");

  // Select source and ensure we show the real source card.
  view.targeting.cmdI = view.targeting.cmds.length - 1;
  {
    const c = ctx.MC.ui.computeRowModels(s, view);
    assert.equal(!!(c.meta && c.meta.hideSrc), true, "expected source card hidden while Cancel is selected for Wild");
  }
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(intent, null);
  assert.equal(view.mode, "browse");
});

test("ui: moveWild targeting cycles leftward in screen space", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  // Trigger replaceWindow then enter moveWild targeting (tap-A flow).
  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  assert.ok(mv, "expected playProp into set 0");
  ctx.MC.engine.applyCommand(s, mv);

  // Ensure we have at least one matching-color destination set for one of the eligible Wild colors,
  // so moveWild has 3+ real destinations (existing + newSet for one color, plus newSet for the other).
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow" && s.prompt.p === 0);
  const pr = s.prompt;
  const srcSetI = pr.srcSetI;
  const excl = pr.excludeUid;
  const srcSet = s.players[0].sets[srcSetI];
  let wildUid = 0;
  let wildDef = null;
  let placedColor = ctx.MC.state.NO_COLOR;
  for (const tup of (srcSet && srcSet.props) ? srcSet.props : []) {
    const uid = tup ? tup[0] : 0;
    if (!uid || uid === excl) continue;
    const def = ctx.MC.state.defByUid(s, uid);
    if (def && ctx.MC.rules.isWildDef(def)) { wildUid = uid; wildDef = def; placedColor = tup[1]; break; }
  }
  assert.ok(wildUid && wildDef, "expected an eligible Wild in src set");
  const wantColor = placedColor;

  function takeAnyFixedPropUidsFromDeck(n) {
    const out = [];
    for (let take = 0; take < n; take++) {
      let pickI = -1;
      for (let i = 0; i < s.deck.length; i++) {
        const uid = s.deck[i];
        const def = ctx.MC.state.defByUid(s, uid);
        if (!def) continue;
        if (def.kind !== ctx.MC.CardKind.Property) continue;
        if (ctx.MC.rules.isWildDef(def)) continue;
        pickI = i;
        break;
      }
      if (pickI < 0) break;
      const uidPicked = s.deck[pickI];
      s.deck.splice(pickI, 1);
      out.push(uidPicked);
    }
    return out;
  }

  const propUids = takeAnyFixedPropUidsFromDeck(2);
  assert.ok(propUids.length === 2, "expected two fixed-color properties in deck");
  for (const propUid of propUids) {
    const extraSet = ctx.MC.state.newEmptySet();
    extraSet.props.push([propUid, wantColor]);
    s.players[0].sets.push(extraSet);
  }

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "moveWild");

  // One tick in targeting mode to allow profile sorting and camera sync.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  const t = view.targeting;
  const cmds = t.cmds || [];
  const srcI2 = cmds.findIndex((c) => c && c.kind === "source");
  const nReal = srcI2 >= 0 ? srcI2 : cmds.length;
  assert.ok(nReal >= 3, "expected multiple moveWild destinations");

  function focusX() {
    const c = ctx.MC.ui.computeRowModels(s, view);
    assert.ok(c.meta && c.meta.focus, "expected focus preview");
    return c.meta.focus.x - view.camX[c.meta.focus.row];
  }

  const xs = [];
  for (let i = 0; i < nReal; i++) { t.cmdI = i; xs.push(focusX()); }

  // Find an index with a strict left neighbor (avoid ties: newSet slots for both colors can share X).
  let idx = -1;
  for (let i = 1; i < xs.length; i++) if (xs[i] > xs[i - 1]) { idx = i; break; }
  assert.ok(idx >= 1, "expected at least one strict x step in moveWild destinations");

  t.cmdI = idx;
  const x1 = focusX();
  ctx.MC.ui.step(s, view, { nav: { left: true }, a: {}, b: {}, x: {} });
  assert.equal(t.cmdI, idx - 1);
  const x2 = focusX();
  assert.ok(x2 < x1, `expected left to move preview left (x2=${x2} < x1=${x1})`);
});

test("ui: moveWild targeting includes a Source destination (release-A cancels when hold=true)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  // Trigger replaceWindow then enter moveWild targeting (hold-A flow).
  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  ctx.MC.engine.applyCommand(s, mv);
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "moveWild");
  assert.equal(view.targeting.hold, true);
  assert.equal(view.targeting.cmds.at(-1).kind, "source", "expected Source destination last");

  // Select source and release A to cancel.
  view.targeting.cmdI = view.targeting.cmds.length - 1;
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { released: true }, b: {}, x: {} });
  assert.equal(intent, null);
  assert.equal(view.mode, "browse");
});

test("ui: targeting help switches to mouseClick when mouse latch is active", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.mouse.enabled = true;

  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  // Trigger the real prompt by playing into set 0, then enter prompt mode.
  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  assert.ok(mv, "expected playProp into set 0");
  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow");

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  // Enter moveWild targeting via tap-A flow (controller or mouse tap both map to A tap).
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "moveWild");

  // Simulate that the mouse was used recently.
  view.ux.autoFocusPausedByMouse = true;
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {}, mouse: { avail: true, moved: true, x: 0, y: 0 } });
  const help = ctx.MC.fmt.targetingHelp(view.targeting);
  assert.ok(String(help).includes("Click:Confirm"), "expected mouse click hint");
});

test("ui: winCheck scenario is navigable (cursor relocates off empty hand)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ scenarioId: "winCheck", seedU32: 1 });
  const view = ctx.MC.ui.newView();
  // Default view cursor is player hand, which is empty in winCheck.
  assert.equal(view.cursor.row, ctx.MC.render.ROW_P_HAND);

  // Relocation is now handled by focus policy during ui.step().
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected, "expected a selected item even when the current row is empty");
  // winCheck gives P0 multiple table stacks; selection should relocate to something selectable.
  assert.notEqual(c.selected.row, ctx.MC.render.ROW_P_HAND);
});

test("ui: pressing disabled End (opponent turn) gives feedback + moves to Menu", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 1;
  s.playsLeft = 3;
  // Keep P0 hand under limit so "disabled" is strictly opponent-turn.
  s.players[0].hand = s.players[0].hand.slice(0, ctx.MC.state.HAND_MAX);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 2; // End

  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(intent, null);
  assert.ok(view.feedback && view.feedback.blinkFrames > 0, "expected negative feedback blink");

  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "mainMenu");
});

test("ui: bank targeting produces a preview in the bank stack row", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  // Force a simple state: one money card in hand, empty bank/sets.
  const moneyUid = ctx.MC.state.takeUid(s, "money_1");
  assert.ok(moneyUid, "expected money_1 uid");
  // Remove uid from any zone it might already be in.
  s.deck = s.deck.filter((u) => u !== moneyUid);
  s.discard = s.discard.filter((u) => u !== moneyUid);
  for (let p = 0; p < 2; p++) {
    s.players[p].hand = s.players[p].hand.filter((u) => u !== moneyUid);
    s.players[p].bank = s.players[p].bank.filter((u) => u !== moneyUid);
    for (const set of (s.players[p].sets || [])) {
      if (!set) continue;
      if (set.props) set.props = set.props.filter(([u]) => u !== moneyUid);
      if (set.houseUid === moneyUid) set.houseUid = 0;
    }
  }
  s.players[0].hand = [moneyUid];
  s.players[0].bank = [];
  s.players[0].sets = [];
  s.activeP = 0;
  s.playsLeft = 3;

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "bank");

  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.meta && c.meta.focus, "expected focus preview for bank targeting");
  assert.equal(c.meta.focus.row, ctx.MC.render.ROW_P_HAND);
});

test("ui: menu hover Bank produces a preview when unambiguous", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  const moneyUid = ctx.MC.state.takeUid(s, "money_1");
  assert.ok(moneyUid, "expected money_1 uid");
  // Force a simple state: one money card in hand, empty bank/sets.
  s.deck = s.deck.filter((u) => u !== moneyUid);
  s.discard = s.discard.filter((u) => u !== moneyUid);
  for (let p = 0; p < 2; p++) {
    s.players[p].hand = s.players[p].hand.filter((u) => u !== moneyUid);
    s.players[p].bank = s.players[p].bank.filter((u) => u !== moneyUid);
    for (const set of (s.players[p].sets || [])) {
      if (!set) continue;
      if (set.props) set.props = set.props.filter(([u]) => u !== moneyUid);
      if (set.houseUid === moneyUid) set.houseUid = 0;
    }
  }
  s.players[0].hand = [moneyUid];
  s.players[0].bank = [];
  s.players[0].sets = [];
  s.activeP = 0;
  s.playsLeft = 3;

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Open menu on the money card.
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");
  assert.equal(view.menu.items.length, 2);
  assert.equal(view.menu.items[0].id, "bank");
  assert.equal(view.menu.items[1].id, "source");

  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.meta && c.meta.focus, "expected focus preview while hovering Bank in menu mode");
  assert.equal(c.meta.focus.row, ctx.MC.render.ROW_P_HAND);
  assert.equal(c.meta.focus.forCmdKind, "bank");
});

test("ui: menu is actionable-only (no plays left gives feedback; no menu)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  const moneyUid = ctx.MC.state.takeUid(s, "money_1");
  assert.ok(moneyUid, "expected money_1 uid");

  // Force a simple state: one money card in hand, no plays left.
  s.deck = s.deck.filter((u) => u !== moneyUid);
  s.discard = s.discard.filter((u) => u !== moneyUid);
  for (let p = 0; p < 2; p++) {
    s.players[p].hand = s.players[p].hand.filter((u) => u !== moneyUid);
    s.players[p].bank = s.players[p].bank.filter((u) => u !== moneyUid);
    for (const set of (s.players[p].sets || [])) {
      if (!set) continue;
      if (set.props) set.props = set.props.filter(([u]) => u !== moneyUid);
      if (set.houseUid === moneyUid) set.houseUid = 0;
    }
  }
  s.players[0].hand = [moneyUid];
  s.players[0].bank = [];
  s.players[0].sets = [];
  s.activeP = 0;
  s.playsLeft = 0;
  ctx.MC.state.clearPrompt(s);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "browse");
  assert.equal(view.menu.items.length, 0);
  assert.ok(view.feedback && view.feedback.blinkFrames > 0, "expected feedback blink on disallowed action");
  assert.equal(view.feedback.lastCode, "no_actions");
});

test("ui: onEvents stages dealing and hides drawn cards until revealed", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  const p = 0;
  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 1; // intentionally not 0 to exercise selection after filtering

  // Force a known draw and capture events.
  const events = [];
  const beforeHand = s.players[p].hand.slice();
  ctx.MC.state.drawToHand(s, p, 2, events);
  const drawEv = events.find((e) => e && e.kind === "draw" && e.p === p);
  assert.ok(drawEv, "expected draw event");
  assert.equal(drawEv.uids.length, 2);

  // Feed events to UI: should hide the newly drawn cards and lock input while animating.
  ctx.MC.anim.onEvents(s, view, events);
  assert.ok(view.anim && view.anim.lock, "expected anim lock after draw events");

  const uid0 = drawEv.uids[0];
  const uid1 = drawEv.uids[1];
  assert.ok(view.anim.hiddenByP[p][uid0], "expected first drawn uid hidden initially");
  assert.ok(view.anim.hiddenByP[p][uid1], "expected second drawn uid hidden initially");

  // Before revealing, computeRowModels should not include hidden uids in the hand row.
  let c = ctx.MC.ui.computeRowModels(s, view);
  const handItems0 = c.models[ctx.MC.render.ROW_P_HAND].items.filter((it) => it && it.kind === "hand");
  const visibleUids0 = handItems0.map((it) => it.uid);
  assert.ok(!visibleUids0.includes(uid0), "expected uid0 hidden from hand row models");
  assert.ok(!visibleUids0.includes(uid1), "expected uid1 hidden from hand row models");
  assert.ok(!(c.selected && c.selected.kind === "hand" && (c.selected.uid === uid0 || c.selected.uid === uid1)), "expected selection to not reveal hidden dealt cards");

  // Tick until first card is revealed.
  assert.ok(view.anim && view.anim.active && view.anim.active.kind === "deal", "expected active deal anim after draw events");
  const frames = view.anim.active.dealFrames;
  const gap = view.anim.active.gapFrames;
  for (let f = 0; f < frames; f++) ctx.MC.anim.tick(s, view);
  assert.ok(!view.anim.hiddenByP[p][uid0], "expected uid0 revealed after dealFramesPerCard");
  assert.ok(view.anim.hiddenByP[p][uid1], "expected uid1 still hidden");

  // Tick through gap + second reveal.
  for (let f = 0; f < gap; f++) ctx.MC.anim.tick(s, view);
  for (let f = 0; f < frames; f++) ctx.MC.anim.tick(s, view);
  assert.ok(!view.anim.hiddenByP[p][uid1], "expected uid1 revealed after second deal");

  // Once done, lock should clear.
  ctx.MC.anim.tick(s, view);
  assert.equal(!!view.anim.lock, false, "expected anim lock cleared after dealing completes");

  // Ensure original hand cards are still present (sanity).
  for (const u of beforeHand) assert.ok(s.players[p].hand.includes(u), "expected original hand uid to remain");
});

test("ui: deal lock keeps bank selection stable while new hand cards appear", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  s.winnerP = ctx.MC.state.NO_WINNER;
  ctx.MC.state.clearPrompt(s);

  // Force a simple state: empty hands, known bank stack, and a known 2-card draw.
  const b0 = ctx.MC.state.takeUid(s, "money_1");
  const b1 = ctx.MC.state.takeUid(s, "money_2");
  const b2 = ctx.MC.state.takeUid(s, "money_3");
  const d0 = ctx.MC.state.takeUid(s, "money_4");
  const d1 = ctx.MC.state.takeUid(s, "money_5");

  for (let p = 0; p < 2; p++) {
    s.players[p].hand = [];
    s.players[p].bank = [];
    s.players[p].sets = [];
  }
  s.players[0].bank = [b0, b1, b2];
  s.deck = [d0, d1]; // drawToHand pops from the end
  s.discard = [];

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;

  // Select the middle bank card and snapshot focus anchor.
  let c0 = ctx.MC.ui.computeRowModels(s, view);
  const rm0 = c0.models[ctx.MC.render.ROW_P_HAND];
  const iB = rm0.items.findIndex((it) => it && it.kind === "bank" && it.uid === b1);
  assert.ok(iB >= 0, "expected to find bank item b1");
  view.cursor.i = iB;
  c0 = ctx.MC.ui.computeRowModels(s, view);
  ctx.MC.ui.focus.snapshot(s, view, c0);
  assert.ok(view.ux && view.ux.selAnchor && view.ux.selAnchor.uid === b1, "expected selAnchor uid to be bank b1");

  // Trigger a draw->deal animation.
  const events = [];
  ctx.MC.state.drawToHand(s, 0, 2, events);
  ctx.MC.anim.onEvents(s, view, events);
  assert.ok(view.anim && view.anim.lock, "expected anim lock during deal");

  function assertSelectedBankUid() {
    const c = ctx.MC.ui.computeRowModels(s, view);
    assert.ok(c.selected && c.selected.uid === b1, "expected selected uid to stay on b1 during deal lock");
    assert.ok(c.selected.loc && c.selected.loc.zone === "bank" && c.selected.loc.p === 0, "expected selection to remain in bank zone");
  }

  const frames = ctx.MC.config.ui.dealFramesPerCard;
  const gap = ctx.MC.config.ui.dealGapFrames;
  const act = { nav: {}, a: {}, b: {}, x: {} };

  // Before and during first reveal.
  assertSelectedBankUid();
  for (let f = 0; f < frames; f++) {
    ctx.MC.ui.step(s, view, act);
    if (view.anim && view.anim.lock) assertSelectedBankUid();
  }

  // Gap + second reveal.
  for (let f = 0; f < gap; f++) {
    ctx.MC.ui.step(s, view, act);
    if (view.anim && view.anim.lock) assertSelectedBankUid();
  }
  for (let f = 0; f < frames; f++) {
    ctx.MC.ui.step(s, view, act);
    if (view.anim && view.anim.lock) assertSelectedBankUid();
  }
});

test("ui: payDebt bank selection does not jump when xfer lock clears (mid-stack payment)", async () => {
  const ctx = await loadSrcIntoVm();

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  s.winnerP = ctx.MC.state.NO_WINNER;

  // Minimal board: no hand/sets; 5-card bank so paying index 3 causes a splice+shift.
  for (let p = 0; p < 2; p++) {
    s.players[p].hand = [];
    s.players[p].bank = [];
    s.players[p].sets = [];
  }

  const b0 = ctx.MC.state.takeUid(s, "money_1");
  const b1 = ctx.MC.state.takeUid(s, "money_2");
  const b2 = ctx.MC.state.takeUid(s, "money_3");
  const b3 = ctx.MC.state.takeUid(s, "money_4");
  const b4 = ctx.MC.state.takeUid(s, "money_5");
  s.players[0].bank = [b0, b1, b2, b3, b4];

  // Open a simple payDebt prompt that can be covered by a single money card.
  ctx.MC.state.setPrompt(s, { kind: "payDebt", p: 0, toP: 1, rem: 1, buf: [] });

  const view = ctx.MC.ui.newView();
  // Enter prompt mode and build initial models/cameras.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  // Select bank card at loc.i===3.
  let c0 = ctx.MC.ui.computeRowModels(s, view);
  const rm0 = c0.models[ctx.MC.render.ROW_P_HAND];
  const iPay = rm0.items.findIndex((it) => it && it.loc && it.loc.zone === "bank" && it.loc.p === 0 && it.loc.i === 3);
  assert.ok(iPay >= 0, "expected to find bank card at loc.i=3");
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = iPay;

  // Pay with the selected card (this snapshots selAnchor to the paid uid).
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.ok(intent && intent.kind === "applyCmd" && intent.cmd && intent.cmd.kind === "payDebt");

  const res = ctx.MC.engine.applyCommand(s, intent.cmd);
  ctx.MC.anim.onEvents(s, view, (res && res.events) ? res.events : []);
  assert.ok(view.anim && view.anim.lock, "expected xfer anim lock after payDebt");

  // After splice, cursor index should now point at the card that used to be loc.i===4.
  // The bug: when the lock clears, focus.preserve used to snap back toward the removed card's
  // old screen position (right-anchored bank), which is nearest to loc.i===2.
  const act = { nav: {}, a: {}, b: {}, x: {} };
  let guard = 0;
  while (view.anim && view.anim.lock) {
    guard += 1;
    assert.ok(guard < 500, "expected xfer lock to clear quickly");

    const prevLock = !!view.anim.lock;
    const cBefore = ctx.MC.ui.computeRowModels(s, view);
    assert.ok(cBefore.selected && cBefore.selected.loc && cBefore.selected.loc.zone === "bank", "expected selection to remain in bank during lock");
    const uidBefore = cBefore.selected.uid;

    ctx.MC.ui.step(s, view, act);

    const nowLock = !!(view.anim && view.anim.lock);
    if (prevLock && !nowLock) {
      const cAfter = ctx.MC.ui.computeRowModels(s, view);
      assert.ok(cAfter.selected && cAfter.selected.loc && cAfter.selected.loc.zone === "bank");
      assert.equal(cAfter.selected.uid, uidBefore, "expected bank selection uid to not jump when xfer lock clears");
      break;
    }
  }
});

test("ui: placeReceived prompt - A on real hand snaps back to faux-hand", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  // Enter prompt mode (sync happens inside step).
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");
  assert.ok(s.prompt && s.prompt.kind === "placeReceived");

  const computed = ctx.MC.ui.computeRowModels(s, view);
  const rm = computed.models[ctx.MC.render.ROW_P_HAND];
  const realHandI = rm.items.findIndex((it) => it && it.loc && it.loc.zone === "hand");
  assert.ok(realHandI >= 0, "expected a real hand card item");

  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = realHandI;

  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });

  assert.equal(view.cursor.row, ctx.MC.render.ROW_P_HAND);
  assert.equal(view.cursor.i, 0);
});

test("ui: placeReceived prompt - A on faux-hand enters targeting", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0; // first faux-hand card

  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.equal(view.targeting.kind, "place");
});

test("ui: placeReceived prompt - Wild single-dest does not use menu-place Source/title nuance", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
  s.activeP = 0;

  // Ensure placement has only one real destination (New set).
  s.players[0].sets = [];

  // Swap in a Wild as the received property.
  assert.ok(s.prompt && s.prompt.kind === "placeReceived" && s.prompt.p === 0);
  let wildUid = 0;
  for (let uid = 1; uid <= s.totalUids; uid++) {
    const def = ctx.MC.state.defByUid(s, uid);
    if (def && def.id === "wild_mo") { wildUid = uid; break; }
  }
  assert.ok(wildUid, "expected wild_mo uid in uid pool");
  s.deck = s.deck.filter((u) => u !== wildUid);
  s.discard = s.discard.filter((u) => u !== wildUid);
  for (let p = 0; p < s.players.length; p++) {
    const pl = s.players[p];
    pl.hand = pl.hand.filter((u) => u !== wildUid);
    pl.bank = pl.bank.filter((u) => u !== wildUid);
    for (let si = 0; si < pl.sets.length; si++) {
      const set = pl.sets[si];
      if (!set) continue;
      if (set.houseUid === wildUid) set.houseUid = 0;
      if (set.props) set.props = set.props.filter(([u]) => u !== wildUid);
    }
  }
  if (s.prompt && s.prompt.kind === "placeReceived" && s.prompt.uids) {
    s.prompt.uids = s.prompt.uids.filter((u) => u !== wildUid);
  }
  s.prompt.uids = [wildUid];

  const view = ctx.MC.ui.newView();
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  // Tap-A workflow: enter place targeting from recvProps.
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.equal(view.targeting.kind, "place");
  assert.ok(view.targeting.card && view.targeting.card.loc && view.targeting.card.loc.zone === "recvProps");

  // Unlike menu-place from hand, we should start on the (only) real destination, not Source.
  const srcI = ctx.MC.ui.findSourceCmdI(view.targeting.cmds);
  assert.ok(srcI >= 0, "expected Source option");
  assert.notEqual(view.targeting.cmdI, srcI, "expected cmdI to not start on Source in placeReceived");

  // And if we do move to Source, the title should be Cancel (not Place).
  const title = ctx.MC.fmt.targetingTitle(view.targeting, { kind: "source" });
  assert.equal(title, "Cancel");

  // Ensure we show a destination preview focus (otherwise click/tap flow feels like it has no targets).
  const computed = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(computed.meta && computed.meta.focus, "expected destination preview focus");
  assert.equal(computed.meta.focus.row, ctx.MC.render.ROW_P_TABLE);
});

test("ui: placeReceived prompt - auto-focus snaps to a received property", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  // Start somewhere else (center row) then enter prompt.
  view.cursor.row = 2;
  view.cursor.i = 0;

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  const c = ctx.MC.ui.computeRowModels(s, view);
  const rm = c.models[ctx.MC.render.ROW_P_HAND];
  const sel = rm.items[ctx.MC.ui.clampI(view.cursor.i, rm.items.length)];
  assert.ok(sel && sel.loc && sel.loc.zone === "recvProps", "expected cursor snapped onto recvProps");
});

test("ui: replaceWindow prompt - auto-focus snaps to an eligible Wild in the source set", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  // Trigger the real prompt by playing into set 0.
  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  assert.ok(mv, "expected playProp into set 0");
  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow");

  // Start somewhere else then enter prompt.
  view.cursor.row = 2;
  view.cursor.i = 0;

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  const c = ctx.MC.ui.computeRowModels(s, view);
  const rmT = c.models[ctx.MC.render.ROW_P_TABLE];
  const sel = rmT.items[ctx.MC.ui.clampI(view.cursor.i, rmT.items.length)];
  assert.ok(sel && sel.loc && sel.loc.zone === "setProps" && sel.loc.setI === 0, "expected focus on source set");
  const def = ctx.MC.state.defByUid(s, sel.uid);
  assert.ok(def && ctx.MC.rules.isWildDef(def), "expected focused card to be a Wild");
});

test("ui: replaceWindow prompt - A tap enters moveWild targeting", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow");

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.equal(view.targeting.kind, "moveWild");
  assert.equal(view.targeting.hold, false);
});

test("ui: replaceWindow prompt - hold-A grabStart enters moveWild targeting (hold=true)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow");

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.equal(view.targeting.kind, "moveWild");
  assert.equal(view.targeting.hold, true);
});

test("ui: replaceWindow prompt - B skips prompt (skipReplaceWindow intent)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  ctx.MC.engine.applyCommand(s, mv);
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow");

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: { pressed: true }, x: {} });
  assert.ok(intent && intent.kind === "applyCmd");
  assert.equal(intent.cmd.kind, "skipReplaceWindow");
});

test("ui: placeReceived prompt - hold-A grabStart on received prop enters place targeting (hold=true)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.equal(view.targeting.kind, "place");
  assert.equal(view.targeting.hold, true);
  assert.ok(view.targeting.card && view.targeting.card.loc && view.targeting.card.loc.zone === "recvProps");
  assert.ok(view.targeting.cmds.some((c) => c && c.kind === "source"), "expected Source option for recvProps targeting");
});

test("ui: placeReceived prompt - A on End is disallowed and snaps back to received properties", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  // Move cursor to End button.
  const c = ctx.MC.ui.computeRowModels(s, view);
  const rmC = c.models[2];
  const endI = rmC.items.findIndex((it) => it && it.kind === "btn" && it.id === "endTurn");
  assert.ok(endI >= 0, "expected endTurn button");
  view.cursor.row = 2;
  view.cursor.i = endI;

  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(intent, null);

  const c2 = ctx.MC.ui.computeRowModels(s, view);
  const rmH = c2.models[ctx.MC.render.ROW_P_HAND];
  const sel = rmH.items[ctx.MC.ui.clampI(view.cursor.i, rmH.items.length)];
  assert.ok(sel && sel.loc && sel.loc.zone === "recvProps", "expected snap back to recvProps");
});

test("ui: placeReceived prompt - A on Step is allowed (debug action)", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.debug.enabled = true;
  ctx.MC.debug.toolsOn = true;
  const s = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  const c = ctx.MC.ui.computeRowModels(s, view);
  const rmC = c.models[2];
  const stepI = rmC.items.findIndex((it) => it && it.kind === "btn" && it.id === "step");
  assert.ok(stepI >= 0, "expected Step button");
  view.cursor.row = 2;
  view.cursor.i = stepI;

  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.ok(intent && intent.kind === "debug");
  assert.equal(intent.action, "step");
});

test("ui: payDebt prompt - A on housed setProp redirects to setHouse; second A emits payDebt", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  // Enter prompt mode.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");
  assert.ok(s.prompt && s.prompt.kind === "payDebt");

  // Select a property in the housed set.
  let c = ctx.MC.ui.computeRowModels(s, view);
  const rmT = c.models[ctx.MC.render.ROW_P_TABLE];
  const propI = rmT.items.findIndex((it) => it && it.kind === "setProp" && it.loc && it.loc.zone === "setProps");
  assert.ok(propI >= 0, "expected a setProp item");

  view.cursor.row = ctx.MC.render.ROW_P_TABLE;
  view.cursor.i = propI;

  // First A: should redirect selection to the House, no intent.
  const intent1 = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(intent1, null);

  c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_P_TABLE);
  assert.equal(c.selected.kind, "setHouse");

  // Second A: should emit a payDebt command for the House.
  const intent2 = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.ok(intent2 && intent2.kind === "applyCmd");
  assert.equal(intent2.cmd.kind, "payDebt");
  assert.equal(intent2.cmd.card.loc.zone, "setHouse");
});

test("ui: payDebt prompt - Step button returns debug intent and debugStep pays debt", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.debug.enabled = true;
  ctx.MC.debug.toolsOn = true;
  const s = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  // Enter prompt mode.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");
  assert.ok(s.prompt && s.prompt.kind === "payDebt");

  // Move cursor to Step button.
  const c = ctx.MC.ui.computeRowModels(s, view);
  const rmC = c.models[2];
  const stepI = rmC.items.findIndex((it) => it && it.kind === "btn" && it.id === "step");
  assert.ok(stepI >= 0, "expected Step button");
  view.cursor.row = 2;
  view.cursor.i = stepI;

  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.ok(intent && intent.kind === "debug");
  assert.equal(intent.action, "step");

  // Simulate Render-mode debug handling: debugStep applies a legal move.
  ctx.MC.debug.state = s;
  ctx.MC.debug.step();
  assert.ok(!s.prompt || s.prompt.kind !== "payDebt", "expected debt prompt to progress/resolve after step");
});

test("ui: rent card menu shows Rent (not just Bank) when a matching set exists", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  // Find rent_mo in hand and set cursor to it.
  const uid = s.players[0].hand.find((u) => ctx.MC.state.defByUid(s, u).id === "rent_mo");
  assert.ok(uid, "expected rent_mo in hand");
  const i = s.players[0].hand.indexOf(uid);
  assert.ok(i >= 0);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = i;

  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");
  assert.ok(view.menu.items.some((it) => it && it.id === "rent"), "expected Rent menu item");
  assert.ok(view.menu.items.some((it) => it && it.id === "bank"), "expected Bank menu item");
  assert.ok(view.menu.items.some((it) => it && it.id === "source"), "expected Cancel/Source menu item");
});

test("ui: sly card menu shows Sly Deal when a legal target exists", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "moveStress", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const uid = s.players[0].hand.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(uid, "expected sly_deal in hand");
  const i = s.players[0].hand.indexOf(uid);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = i;

  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");
  assert.ok(view.menu.items.some((it) => it && it.id === "sly"), "expected Sly Deal menu item");
  assert.ok(view.menu.items.some((it) => it && it.id === "bank"), "expected Bank menu item");
  assert.ok(view.menu.items.some((it) => it && it.id === "source"), "expected Cancel menu item");
});

test("ui: menu Sly Deal with one target previews destination and auto-applies on select", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  ctx.MC.state.clearPrompt(s);

  // Give P0 a Sly Deal in hand.
  const slyUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(slyUid, "expected sly_deal uid");
  s.deck = s.deck.filter((u) => u !== slyUid);
  s.players[0].hand.push(slyUid);

  // Give opponent exactly one eligible property target.
  const propUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_orange");
  assert.ok(propUid, "expected prop_orange uid");
  s.deck = s.deck.filter((u) => u !== propUid);
  const set0 = ctx.MC.state.newEmptySet();
  set0.props.push([propUid, ctx.MC.Color.Orange]);
  s.players[1].sets = [set0];

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = s.players[0].hand.indexOf(slyUid);

  // Open menu.
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");

  const slyI = view.menu.items.findIndex((it) => it && it.id === "sly");
  assert.ok(slyI >= 0, "expected Sly Deal menu item");
  view.menu.i = slyI;

  // Hover Sly: label should include destination, source should be ghosted, and the (single) target should be highlighted.
  assert.ok(String(view.menu.items[slyI].label || "").includes("->"), "expected single-target Sly Deal label to include destination");
  const c0 = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c0.meta && c0.meta.hideSrc, "expected menu hover preview to ghost source card");
  assert.ok(c0.meta && c0.meta.focus, "expected focus preview on the single target");
  assert.equal(c0.meta.focus.kind, "preview");
  assert.equal(c0.meta.focus.uid, propUid);
  assert.equal(c0.meta.focus.row, ctx.MC.render.ROW_OP_TABLE);

  // Confirm Sly: should auto-apply immediately.
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.ok(intent && intent.kind === "applyCmd", "expected applyCmd intent");
  assert.ok(intent.cmd && intent.cmd.kind === "playSlyDeal", "expected playSlyDeal cmd");
});

test("ui: mouse-drag unsnapped in cursor-mode targeting does not preselect a target", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.mouse.enabled = true;
  ctx.MC.config.mouse.dragStartPx = 3;

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  ctx.MC.state.clearPrompt(s);

  // Give P0 a Sly Deal in hand.
  const slyUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(slyUid, "expected sly_deal uid");
  s.deck = s.deck.filter((u) => u !== slyUid);
  s.players[0].hand.push(slyUid);

  // Give opponent two separate 1-card sets so we have multiple targets.
  const u0 = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_orange");
  assert.ok(u0);
  s.deck = s.deck.filter((u) => u !== u0);
  const u1 = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_magenta");
  assert.ok(u1);
  s.deck = s.deck.filter((u) => u !== u1);
  const set0 = ctx.MC.state.newEmptySet();
  set0.props.push([u0, ctx.MC.Color.Orange]);
  const set1 = ctx.MC.state.newEmptySet();
  set1.props.push([u1, ctx.MC.Color.Magenta]);
  s.players[1].sets = [set0, set1];

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = s.players[0].hand.indexOf(slyUid);

  // Initialize cameras and find screen position of the sly card.
  let c0 = ctx.MC.ui.computeRowModels(s, view);
  ctx.MC.ui.updateCameras(s, view, c0);
  c0 = ctx.MC.ui.computeRowModels(s, view);
  const rmH = c0.models[ctx.MC.render.ROW_P_HAND];
  const itSly = rmH.items.find((it) => it && it.uid === slyUid);
  assert.ok(itSly, "expected sly card item in row model");
  const x0 = itSly.x - view.camX[itSly.row] + 2;
  const y0 = itSly.y + 2;

  const st = ctx.MC.controls.newState();
  const cfg = ctx.MC.config.controls;

  // Frame 1: mouse press down on the sly card.
  let a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: x0, y: y0, left: true }) }), cfg);
  ctx.MC.ui.step(s, view, a);

  // Frame 2: move enough while held to trigger dragStart/grabStart.
  a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: x0 + 10, y: y0, left: true }) }), cfg);
  ctx.MC.ui.step(s, view, a);
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.equal(view.targeting.kind, "sly");
  assert.ok(view.targeting.mouse && view.targeting.mouse.dragMode, "expected drag mode");
  assert.ok(view.targeting.mouse.dragging, "expected dragging");
  assert.equal(view.targeting.mouse.snapped, false, "expected unsnapped at drag start");

  const srcCursor = view.targeting.srcCursor;

  // Frame 3: while still unsnapped, cursor should not jump to an opponent target.
  a = ctx.MC.controls.actions(st, rawInput({ mouse: rawMouse({ x: x0 + 11, y: y0, left: true }) }), cfg);
  ctx.MC.ui.step(s, view, a);
  assert.equal(view.cursor.row, srcCursor.row);
});

test("ui: hold-A on Sly Deal enters hold-chain: sly targets -> bank -> source", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  ctx.MC.state.clearPrompt(s);

  // Give P0 a Sly Deal in hand.
  const slyUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(slyUid, "expected sly_deal in deck");
  s.deck = s.deck.filter((u) => u !== slyUid);
  s.players[0].hand.push(slyUid);

  // Give opponent two separate 1-card sets so we have two targets.
  const u0 = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_orange");
  assert.ok(u0);
  s.deck = s.deck.filter((u) => u !== u0);
  const u1 = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_magenta");
  assert.ok(u1);
  s.deck = s.deck.filter((u) => u !== u1);
  const set0 = ctx.MC.state.newEmptySet();
  set0.props.push([u0, ctx.MC.Color.Orange]); // setI=0 (rightmost)
  const set1 = ctx.MC.state.newEmptySet();
  set1.props.push([u1, ctx.MC.Color.Magenta]); // setI=1 (left of set0)
  s.players[1].sets = [set0, set1];

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = s.players[0].hand.indexOf(slyUid);

  // Enter targeting via hold-A.
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.equal(view.targeting.kind, "sly");
  assert.equal(view.targeting.hold, true);
  assert.ok(view.targeting.chainActive, "expected hold-chain targeting");

  // Tick once: cursor should jump to the leftmost target (setI=1).
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  let c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected && c.selected.loc);
  assert.equal(c.selected.loc.zone, "setProps");
  assert.equal(c.selected.loc.p, 1);
  assert.equal(c.selected.loc.setI, 1);

  // Right: cycle to next target (setI=0).
  ctx.MC.ui.step(s, view, { nav: { right: true }, a: {}, b: {}, x: {} });
  c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected && c.selected.loc);
  assert.equal(c.selected.loc.zone, "setProps");
  assert.equal(c.selected.loc.p, 1);
  assert.equal(c.selected.loc.setI, 0);

  // Right: cycle past last target -> bank segment.
  ctx.MC.ui.step(s, view, { nav: { right: true }, a: {}, b: {}, x: {} });
  assert.equal(view.targeting.kind, "bank");
  assert.equal(view.targeting.cmds[view.targeting.cmdI].kind, "bank");

  // Right: cycle to source segment (Sly card reappears and is selected).
  ctx.MC.ui.step(s, view, { nav: { right: true }, a: {}, b: {}, x: {} });
  assert.equal(view.targeting.kind, "source");
  assert.equal(view.targeting.cmds[view.targeting.cmdI].kind, "source");
  c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected && c.selected.loc);
  assert.equal(c.selected.loc.zone, "hand");
  assert.equal(c.selected.uid, slyUid);
  assert.equal(!!(c.meta && c.meta.hideSrc), false, "expected source card not to be hidden when Source is selected");
});

test("ui: sly hold-chain left-cycle is symmetric (source->bank->lastTarget->...)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  ctx.MC.state.clearPrompt(s);

  // Give P0 a Sly Deal in hand.
  const slyUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(slyUid, "expected sly_deal in deck");
  s.deck = s.deck.filter((u) => u !== slyUid);
  s.players[0].hand.push(slyUid);

  // Give opponent two separate 1-card sets so we have two targets.
  const u0 = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_orange");
  assert.ok(u0);
  s.deck = s.deck.filter((u) => u !== u0);
  const u1 = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_magenta");
  assert.ok(u1);
  s.deck = s.deck.filter((u) => u !== u1);
  const set0 = ctx.MC.state.newEmptySet();
  set0.props.push([u0, ctx.MC.Color.Orange]); // setI=0 (rightmost)
  const set1 = ctx.MC.state.newEmptySet();
  set1.props.push([u1, ctx.MC.Color.Magenta]); // setI=1 (leftmost)
  s.players[1].sets = [set0, set1];

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = s.players[0].hand.indexOf(slyUid);

  // Enter targeting via hold-A.
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.equal(view.targeting.kind, "sly");
  assert.ok(view.targeting.chainActive);

  // Tick once so cursor sync lands on default target (leftmost, setI=1).
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  let c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected && c.selected.loc);
  assert.equal(c.selected.loc.zone, "setProps");
  assert.equal(c.selected.loc.p, 1);
  assert.equal(c.selected.loc.setI, 1);

  // Left from first target should go to Source, then Bank, then last target (setI=0), then back to setI=1.
  ctx.MC.ui.step(s, view, { nav: { left: true }, a: {}, b: {}, x: {} });
  assert.equal(view.targeting.kind, "source");

  ctx.MC.ui.step(s, view, { nav: { left: true }, a: {}, b: {}, x: {} });
  assert.equal(view.targeting.kind, "bank");

  ctx.MC.ui.step(s, view, { nav: { left: true }, a: {}, b: {}, x: {} });
  assert.equal(view.targeting.kind, "sly");
  c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected && c.selected.loc);
  assert.equal(c.selected.loc.zone, "setProps");
  assert.equal(c.selected.loc.p, 1);
  assert.equal(c.selected.loc.setI, 0);

  ctx.MC.ui.step(s, view, { nav: { left: true }, a: {}, b: {}, x: {} });
  c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected && c.selected.loc);
  assert.equal(c.selected.loc.zone, "setProps");
  assert.equal(c.selected.loc.p, 1);
  assert.equal(c.selected.loc.setI, 1);
});

test("ui: hold-A on Sly Deal with no targets falls back to bank segment (Bank)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  ctx.MC.state.clearPrompt(s);

  // Give P0 a Sly Deal in hand.
  const slyUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(slyUid, "expected sly_deal in deck");
  s.deck = s.deck.filter((u) => u !== slyUid);
  s.players[0].hand.push(slyUid);

  // Ensure opponent has no stealable props.
  s.players[1].sets = [];

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = s.players[0].hand.indexOf(slyUid);

  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.equal(view.targeting.kind, "bank");
  assert.equal(view.targeting.hold, true);
  assert.ok(view.targeting.cmds && view.targeting.cmds.length > 0);
  assert.ok(view.targeting.cmds.some((c) => c && c.kind === "bank"), "expected Bank cmd");

  // Release A should confirm the default option (bank).
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { released: true }, b: {}, x: {} });
  assert.ok(intent && intent.kind === "applyCmd");
  assert.equal(intent.cmd.kind, "bank");
});

test("ui: menu hover Rent previews default target set", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const uid = s.players[0].hand.find((u) => ctx.MC.state.defByUid(s, u).id === "rent_mo");
  assert.ok(uid, "expected rent_mo in hand");
  const i = s.players[0].hand.indexOf(uid);
  assert.ok(i >= 0);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = i;

  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");
  assert.ok(view.menu.items.length > 0);
  assert.equal(view.menu.items[0].id, "rent");
  assert.ok(String(view.menu.items[0].label || "").includes("->"), "expected single-target Rent label to include destination");

  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.meta && c.meta.focus, "expected focus preview while hovering Rent in menu mode");
  assert.equal(!!c.meta.focus.focusSrcGhost, true, "expected Rent preview to mark focusSrcGhost (preview card differs from source)");
  assert.equal(c.meta.focus.row, ctx.MC.render.ROW_P_TABLE);
  assert.equal(c.meta.focus.stackKey, "set:p0:set0");
  assert.ok(c.meta && c.meta.hideSrc, "expected Rent preview to ghost source (no double-highlight in hand)");
  assert.equal(c.meta.hideSrc.uid, uid);
  assert.equal(c.meta.hideSrc.loc.p, 0);
  assert.equal(String(c.meta.hideSrc.loc.zone), "hand");
  assert.equal(c.meta.hideSrc.loc.i, i);
});

test("ui: respondAction prompt auto-focuses the target; A on target yields respondPass intent", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "slyJSN", seedU32: 1 });
  assert.ok(s.prompt && s.prompt.kind === "respondAction");
  assert.equal(s.prompt.p, 0);

  const view = ctx.MC.ui.newView();
  // Start somewhere else to prove focus rule relocates us.
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 0;

  // First tick: sync prompt mode + apply focus rule.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");
  const c0 = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c0.selected && c0.selected.loc);
  assert.equal(c0.selected.uid, s.prompt.target.uid);
  assert.equal(c0.selected.loc.zone, "setProps");

  // Tap A on target -> respondPass intent.
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.ok(intent && intent.kind === "applyCmd");
  assert.equal(intent.cmd.kind, "respondPass");
});

test("ui: respondAction prompt shows target ghost outline only when cursor is away", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "slyJSN", seedU32: 1 });
  const view = ctx.MC.ui.newView();
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  // When cursor is on the target, there should be no ghost overlay for it.
  let c = ctx.MC.ui.computeRowModels(s, view);
  const rowPT = ctx.MC.render.ROW_P_TABLE;
  assert.ok(c.models[rowPT]);
  assert.equal((c.models[rowPT].overlayItems || []).some((it) => it && it.kind === "ghost"), false);

  // Move cursor to JSN in hand (manually) and recompute: expect a ghost overlay on the target.
  const jsnUid = s.players[0].hand.find((u) => ctx.MC.state.defByUid(s, u).id === "just_say_no");
  assert.ok(jsnUid);
  const cHand = ctx.MC.ui.computeRowModels(s, view);
  const rowHand = ctx.MC.render.ROW_P_HAND;
  const jsnI = cHand.models[rowHand].items.findIndex((it) => it && it.uid === jsnUid && it.loc && it.loc.zone === "hand");
  assert.ok(jsnI >= 0);
  view.cursor.row = rowHand;
  view.cursor.i = jsnI;

  c = ctx.MC.ui.computeRowModels(s, view);
  const ghosts = (c.models[rowPT].overlayItems || []).filter((it) => it && it.kind === "ghost");
  assert.ok(ghosts.length > 0, "expected a ghost overlay while cursor is away from target");
});

test("ui: menu hover Rent (multi-target) does not imply a default target while hovering", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  // Add a second eligible Magenta set with 3 props so its rent is higher than the Orange set.
  const mags = s.deck.filter((u) => ctx.MC.state.defByUid(s, u).id === "prop_magenta").slice(0, 3);
  assert.equal(mags.length, 3, "expected 3 prop_magenta uids in deck");
  s.deck = s.deck.filter((u) => !mags.includes(u));
  const setM = ctx.MC.state.newEmptySet();
  setM.props.push([mags[0], ctx.MC.Color.Magenta]);
  setM.props.push([mags[1], ctx.MC.Color.Magenta]);
  setM.props.push([mags[2], ctx.MC.Color.Magenta]);
  s.players[0].sets.push(setM); // setI=1

  const uid = s.players[0].hand.find((u) => ctx.MC.state.defByUid(s, u).id === "rent_mo");
  assert.ok(uid, "expected rent_mo in hand");

  const rentMoves = ctx.MC.moves.rentMovesForUid(s, uid);
  assert.ok(rentMoves.length >= 2, "expected 2+ rent targets");
  const di = ctx.MC.cmdProfiles.rent.defaultCmdI(s, rentMoves, { p: 0, zone: "hand", i: 0 });
  assert.equal(rentMoves[di].setI, 1, "expected default target to be the Magenta set (setI=1)");

  const i = s.players[0].hand.indexOf(uid);
  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = i;

  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");
  assert.equal(view.menu.items[0].id, "rent");
  assert.equal(view.menu.items[0].label, "Rent...", "expected multi-target Rent label to show ellipsis");

  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(!!(c.meta && c.meta.focus), false, "expected no focus preview while hovering Rent... (multi-target)");
});

test("ui: game over shows winner toast and hides prompt toast", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "winCheck", seedU32: 1 });
  assert.notEqual(s.winnerP, ctx.MC.state.NO_WINNER, "expected winner in winCheck scenario");

  const view = ctx.MC.ui.newView();
  // Tick once to allow UI to sync persistent toasts.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  const winner = view.toasts.find((t) => t && t.id === "winner");
  assert.ok(winner && winner.persistent, "expected persistent winner toast");
  assert.ok(String(winner.text || "").startsWith("Winner:"), "expected Winner: toast text");

  const prompt = view.toasts.find((t) => t && t.id === "prompt");
  assert.equal(!!prompt, false, "expected prompt toast to be suppressed during game over");
});

test("ui: game over blocks card tap-A actions (no menu/targeting; blink only)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "winCheck", seedU32: 1 });
  assert.notEqual(s.winnerP, ctx.MC.state.NO_WINNER);

  // Put a card in hand so we can press A on it.
  const uid = s.deck[0];
  assert.ok(uid, "expected at least 1 card in deck");
  s.deck = s.deck.slice(1);
  s.players[0].hand = [uid];

  const view = ctx.MC.ui.newView();
  // Prevent the one-shot game-over autofocus from moving the cursor away from the card.
  view.ux.lastWinnerP = s.winnerP;
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(intent, null, "expected no intent on game over card tap");
  assert.equal(view.mode, "browse", "expected browse mode (no menu/targeting)");
  assert.equal(view.menu.items.length, 0, "expected menu not to open");
  assert.ok(view.feedback && view.feedback.blinkFrames > 0, "expected feedback blink on disallowed action");
});

test("ui: game over transition auto-focuses Reset button (debug enabled)", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.debug.enabled = true;
  ctx.MC.debug.toolsOn = true;

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.winnerP = ctx.MC.state.NO_WINNER;

  const view = ctx.MC.ui.newView();
  // Establish prior ux state.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  // Simulate winner appearing between ticks.
  s.winnerP = 0;
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "reset");
});

test("ui: focus preservation keeps selection near removed hand card (avoids jumping to bank)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  s.winnerP = ctx.MC.state.NO_WINNER;
  ctx.MC.state.clearPrompt(s);

  // Build a minimal hand with 2 cards and an empty bank.
  const u1 = ctx.MC.state.takeUid(s, "money_1");
  const u2 = ctx.MC.state.takeUid(s, "money_2");
  const uB = ctx.MC.state.takeUid(s, "money_3");

  const strip = (uid) => {
    s.deck = s.deck.filter((u) => u !== uid);
    s.discard = s.discard.filter((u) => u !== uid);
    for (let p = 0; p < 2; p++) {
      s.players[p].hand = (s.players[p].hand || []).filter((u) => u !== uid);
      s.players[p].bank = (s.players[p].bank || []).filter((u) => u !== uid);
      for (const set of (s.players[p].sets || [])) {
        if (!set) continue;
        if (set.props) set.props = set.props.filter(([u]) => u !== uid);
        if (set.houseUid === uid) set.houseUid = 0;
      }
    }
  };
  [u1, u2, uB].forEach(strip);

  s.players[0].hand = [u1, u2];
  s.players[0].bank = [];
  s.players[0].sets = [];

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 1; // select the second hand card (u2)

  // Tick once to capture selection anchor.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  // Simulate mutation between ticks:
  // - selected hand card removed (played/discarded)
  // - bank becomes non-empty (received money)
  s.players[0].hand = [u1];
  s.players[0].bank = [uB];

  // Cursor index remains 1; naive clamping would now select the bank card.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected && c.selected.loc, "expected a selection");
  assert.equal(c.selected.loc.zone, "hand", "expected focus preservation to stay on a hand card, not bank");
});

test("ui: hand empty but plays left snaps to End", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  s.players[0].hand = [];
  s.winnerP = ctx.MC.state.NO_WINNER;
  ctx.MC.state.clearPrompt(s);

  const view = ctx.MC.ui.newView();
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "endTurn");
});

test("ui: hand becoming empty mid-turn nudges End (one-shot)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  s.winnerP = ctx.MC.state.NO_WINNER;
  ctx.MC.state.clearPrompt(s);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Prime ux memory with a non-empty hand.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.ok(s.players[0].hand.length > 0, "expected non-empty hand after prime tick");

  // Simulate last-card spent mid-turn (e.g. banking/playing removed the final card).
  s.players[0].hand = [];

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "endTurn");
});

test("ui: exiting placeReceived prompt with playsLeft<=0 snaps to End", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 0;
  s.winnerP = ctx.MC.state.NO_WINNER;

  const view = ctx.MC.ui.newView();
  // Tick once while prompt is active so lastPromptKind is recorded.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.ok(s.prompt && s.prompt.kind === "placeReceived");

  // Prompt ends between ticks.
  ctx.MC.state.clearPrompt(s);
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "endTurn");
});

test("ui: exiting replaceWindow prompt with playsLeft<=0 snaps to End", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "replaceWindow", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 1;
  s.winnerP = ctx.MC.state.NO_WINNER;
  ctx.MC.state.clearPrompt(s);

  // Spend the last play on a prop placement that opens replaceWindow.
  const mv = ctx.MC.engine.legalMoves(s).find((m) => m.kind === "playProp" && m.dest && m.dest.setI === 0);
  assert.ok(mv, "expected playProp into set 0");
  ctx.MC.engine.applyCommand(s, mv);
  assert.equal(s.playsLeft, 0, "expected to be out of plays after the triggering playProp");
  assert.ok(s.prompt && s.prompt.kind === "replaceWindow");

  const view = ctx.MC.ui.newView();
  // Tick once while prompt is active so lastPromptKind is recorded.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  // Prompt ends between ticks (simulate player choosing to skip the optional move).
  ctx.MC.engine.applyCommand(s, { kind: "skipReplaceWindow" });
  assert.equal(s.prompt, null);
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  const c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "endTurn");
});

test("ui: payDebt prompt auto-focuses bank when available, else house/props", async () => {
  const ctx = await loadSrcIntoVm();

  // Bank available case.
  {
    const s = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });
    const pay = s.deck.find((u) => String(ctx.MC.state.defByUid(s, u).id || "").startsWith("money_"));
    assert.ok(pay, "expected a money card in deck");
    s.deck = s.deck.filter((u) => u !== pay);
    s.players[0].bank.push(pay);

    const view = ctx.MC.ui.newView();
    ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
    const c = ctx.MC.ui.computeRowModels(s, view);
    assert.ok(c.selected && c.selected.loc);
    assert.equal(c.selected.loc.zone, "bank");
  }

  // No bank case: should focus house (house-pay-first friendly).
  {
    const s = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });
    const view = ctx.MC.ui.newView();
    ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
    const c = ctx.MC.ui.computeRowModels(s, view);
    assert.ok(c.selected && c.selected.loc);
    assert.equal(c.selected.loc.zone, "setHouse");
  }
});

test("ui: payDebt cant_pay triggers refocus on next tick", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });
  const view = ctx.MC.ui.newView();

  // Enter prompt and let default focus happen.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  // Move cursor onto a non-payable hand card.
  const c0 = ctx.MC.ui.computeRowModels(s, view);
  const rmH = c0.models[ctx.MC.render.ROW_P_HAND];
  const handI = rmH.items.findIndex((it) => it && it.loc && it.loc.zone === "hand" && it.loc.p === 0);
  assert.ok(handI >= 0, "expected a hand card");
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = handI;

  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.feedback.lastCode, "cant_pay");
  assert.equal(view.ux.pendingFocusErrorCode, "cant_pay");

  // Next tick should refocus to the default payable item (house, since bank empty).
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  const c1 = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c1.selected && c1.selected.loc);
  assert.equal(c1.selected.loc.zone, "setHouse");
});

test("ui: payDebt prompt navigation does not snap back to bank next tick (selection anchor refresh)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "debtHouseFirst", seedU32: 1 });

  // Add a bank card so default focus picks bank.
  const pay = s.deck.find((u) => String(ctx.MC.state.defByUid(s, u).id || "").startsWith("money_"));
  assert.ok(pay, "expected a money card in deck");
  s.deck = s.deck.filter((u) => u !== pay);
  s.players[0].bank.push(pay);

  const view = ctx.MC.ui.newView();

  // Tick once to enter prompt mode + apply payDebt default focus (bank).
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  let c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected && c.selected.loc);
  assert.equal(c.selected.loc.zone, "bank");

  // Navigate left to a different selection (hand card, not payable but selectable).
  ctx.MC.ui.step(s, view, { nav: { left: true }, a: {}, b: {}, x: {} });
  c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected && c.selected.loc);
  assert.equal(c.selected.loc.zone, "hand", "expected navigation to move selection off bank onto hand");
  const movedUid = c.selected.uid;

  // Next tick with no nav should not snap back to the previous bank selection.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  c = ctx.MC.ui.computeRowModels(s, view);
  assert.ok(c.selected && c.selected.loc);
  assert.equal(c.selected.uid, movedUid, "expected selection to remain where the user navigated");
});

test("ui: pause autofocus after NextScenario prevents End snap", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.debug.enabled = true;
  ctx.MC.debug.toolsOn = true;
  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  // Keep hand non-empty so HandEmptySnapEnd doesn't steal focus before we press Next.
  s.players[0].hand = [s.players[0].hand[0]];
  s.winnerP = ctx.MC.state.NO_WINNER;
  ctx.MC.state.clearPrompt(s);

  const view = ctx.MC.ui.newView();
  // Move cursor to Next button.
  const c0 = ctx.MC.ui.computeRowModels(s, view);
  const rmC = c0.models[ctx.MC.render.ROW_CENTER];
  const nextI = rmC.items.findIndex((it) => it && it.kind === "btn" && it.id === "nextScenario");
  assert.ok(nextI >= 0, "expected Next button");
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = nextI;

  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.ok(intent && intent.kind === "debug" && intent.action === "nextScenario");
  assert.equal(view.ux.autoFocusPausedByDebug, true, "expected debug pause latch to be set");

  // Now make the state eligible for HandEmptySnapEnd; pause should keep us on Next.
  s.players[0].hand = [];
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  const c1 = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c1.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c1.selected.kind, "btn");
  assert.equal(c1.selected.id, "nextScenario");
});

test("ui: debug pause latch survives long opponent delay and clears on first non-debug input", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.debug.enabled = true;
  ctx.MC.debug.toolsOn = true;

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  s.winnerP = ctx.MC.state.NO_WINNER;
  ctx.MC.state.clearPrompt(s);

  const view = ctx.MC.ui.newView();

  // Move cursor to Next button.
  let c = ctx.MC.ui.computeRowModels(s, view);
  let rmC = c.models[ctx.MC.render.ROW_CENTER];
  const nextI = rmC.items.findIndex((it) => it && it.kind === "btn" && it.id === "nextScenario");
  assert.ok(nextI >= 0);
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = nextI;

  // Press NextScenario -> latch on.
  const intent = ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.ok(intent && intent.kind === "debug" && intent.action === "nextScenario");
  assert.equal(view.ux.autoFocusPausedByDebug, true);

  // Simulate a long opponent/AI delay (many ticks where activeP != 0).
  s.activeP = 1;
  for (let i = 0; i < 120; i++) ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.ux.autoFocusPausedByDebug, true);

  // Turn returns to player, but latch should suppress turn-start snap.
  s.activeP = 0;
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "nextScenario");

  // First non-debug input clears latch without retroactive snapping on that tick.
  ctx.MC.ui.step(s, view, { nav: { left: true }, a: {}, b: {}, x: {} });
  assert.equal(view.ux.autoFocusPausedByDebug, false);
});

test("debug: Next/Reset preserve autofocus pause latch across debugReset", async () => {
  const ctx = await loadSrcIntoVm();

  ctx.MC.debug.reset({ skipGameStartAnim: true });
  const v0 = ctx.MC.debug.view;
  assert.ok(v0 && v0.ux);
  assert.equal(v0.ux.autoFocusPausedByDebug, false);

  // NextScenario should recreate the view but keep the latch on.
  ctx.MC.debug.nextScenario();
  const v1 = ctx.MC.debug.view;
  assert.notEqual(v1, v0, "expected debugNextScenario to recreate the view");
  assert.ok(v1 && v1.ux);
  assert.equal(v1.ux.autoFocusPausedByDebug, true, "expected debugNextScenario to pause autofocus after reset");

  // A plain debugReset should preserve a previously latched pause.
  v1.ux.autoFocusPausedByDebug = true;
  ctx.MC.debug.reset({ skipGameStartAnim: true });
  const v2 = ctx.MC.debug.view;
  assert.notEqual(v2, v1, "expected debugReset to recreate the view");
  assert.ok(v2 && v2.ux);
  assert.equal(v2.ux.autoFocusPausedByDebug, true, "expected debugReset to preserve pause latch when previously set");
});

test("debug: game over does not freeze controls when actor!=0 (Reset still works)", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.debug.enabled = true;
  ctx.MC.debug.toolsOn = true;

  // Enter Render mode deterministically.
  ctx.MC._mainMode = 1;
  ctx.MC.debug.reset({ skipGameStartAnim: true });

  // Simulate opponent win while it's still opponent's turn.
  ctx.MC.debug.state.activeP = 1;
  ctx.MC.debug.state.winnerP = 1;

  // Put cursor on Reset.
  const c0 = ctx.MC.ui.computeRowModels(ctx.MC.debug.state, ctx.MC.debug.view);
  const rmC = c0.models[ctx.MC.render.ROW_CENTER];
  const resetI = rmC.items.findIndex((it) => it && it.kind === "btn" && it.id === "reset");
  assert.ok(resetI >= 0, "expected Reset button");
  ctx.MC.debug.view.cursor.row = ctx.MC.render.ROW_CENTER;
  ctx.MC.debug.view.cursor.i = resetI;

  // Fake a 2-tick A tap (press then release). Keep btnp(7)=false so mode doesn't toggle.
  let frame = 0;
  ctx.btn = (i) => {
    if (i === 4) return frame === 0; // A held on tick 0 only
    return false;
  };
  ctx.btnp = (i) => {
    if (i === 7) return false; // no Y toggle
    if (i === 4) return frame === 0; // A pressed pulse on tick 0
    return false;
  };

  frame = 0;
  ctx.MC.mainTick();
  frame = 1;
  ctx.MC.mainTick();

  assert.equal(ctx.MC.debug.state.winnerP, ctx.MC.state.NO_WINNER, "expected Reset to run even after opponent win");
});

test("ui: deck-empty style empty-hand nudges End once on turn start, but does not keep snapping while browsing", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.debug.enabled = true;
  ctx.MC.debug.toolsOn = true;

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  // Simulate: player turn just started, but no hand cards.
  s.activeP = 0;
  s.playsLeft = 3;
  s.players[0].hand = [];
  s.winnerP = ctx.MC.state.NO_WINNER;
  ctx.MC.state.clearPrompt(s);

  const view = ctx.MC.ui.newView();
  // Make the transition visible to the focus rule.
  view.ux.lastActiveP = 1;

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  let c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "endTurn");

  // Move cursor to Reset and idle-tick: should stay on Reset (no continuous empty-hand snapping).
  const rmC = c.models[ctx.MC.render.ROW_CENTER];
  const resetI = rmC.items.findIndex((it) => it && it.kind === "btn" && it.id === "reset");
  assert.ok(resetI >= 0, "expected Reset button");
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = resetI;

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "reset");
});

test("ui: empty-hand invalid action can nudge back to End (error-triggered)", async () => {
  const ctx = await loadSrcIntoVm();
  ctx.MC.config.debug.enabled = true;
  ctx.MC.debug.toolsOn = true;

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  s.players[0].hand = [];
  s.winnerP = ctx.MC.state.NO_WINNER;
  ctx.MC.state.clearPrompt(s);

  const view = ctx.MC.ui.newView();
  // Start browsing on Reset.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  let c = ctx.MC.ui.computeRowModels(s, view);
  const rmC = c.models[ctx.MC.render.ROW_CENTER];
  const resetI = rmC.items.findIndex((it) => it && it.kind === "btn" && it.id === "reset");
  assert.ok(resetI >= 0);
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = resetI;

  // Simulate an invalid action happening (e.g. player tried to do something impossible).
  ctx.MC.anim.feedbackError(view, "no_actions", "No moves left");
  assert.equal(view.ux.pendingFocusErrorCode, "no_actions");

  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  c = ctx.MC.ui.computeRowModels(s, view);
  assert.equal(c.selected.row, ctx.MC.render.ROW_CENTER);
  assert.equal(c.selected.kind, "btn");
  assert.equal(c.selected.id, "endTurn");
  assert.equal(view.ux.pendingFocusErrorCode, "");
});

test("ui: hold-A on rent card enters hold-chain: rent targets -> bank -> source (defaults to playRent)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const uid = s.players[0].hand.find((u) => ctx.MC.state.defByUid(s, u).id === "rent_mo");
  assert.ok(uid, "expected rent_mo in hand");
  const i = s.players[0].hand.indexOf(uid);
  assert.ok(i >= 0);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = i;

  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });

  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting && view.targeting.active);
  assert.equal(view.targeting.kind, "rent");
  assert.ok(view.targeting.chainActive);
  assert.ok(view.targeting.cmds && view.targeting.cmds.length > 0);
  assert.equal(view.targeting.cmds[0].kind, "playRent");
});

test("ui: hold-A rent hold-chain can cycle to bank segment", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const uid = s.players[0].hand.find((u) => ctx.MC.state.defByUid(s, u).id === "rent_mo");
  assert.ok(uid);
  const i = s.players[0].hand.indexOf(uid);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = i;

  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "rent");

  // Cycle right to bank segment.
  // The chain is rent cmds (>=1), then bank segment.
  for (let step = 0; step < view.targeting.cmds.length; step++) {
    ctx.MC.ui.step(s, view, { nav: { right: true }, a: {}, b: {}, x: {} });
  }
  assert.equal(view.targeting.kind, "bank");

  const sel = view.targeting.cmds[view.targeting.cmdI];
  assert.ok(sel);
  assert.equal(sel.kind, "bank");
});

test("ui: hold-A on House enters hold-chain: build targets -> bank -> source (defaults to playHouse)", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "houseBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const uid = s.players[0].hand.find((u) => ctx.MC.state.defByUid(s, u).id === "house");
  assert.ok(uid, "expected house in hand");
  const i = s.players[0].hand.indexOf(uid);
  assert.ok(i >= 0);

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = i;

  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "build");
  assert.ok(view.targeting.chainActive);
  assert.ok(view.targeting.cmds && view.targeting.cmds.length > 0);
  assert.equal(view.targeting.cmds[0].kind, "playHouse");
});

test("ui: menu includes Cancel/Source as last item", async () => {
  const ctx = await loadSrcIntoVm();
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;

  const uid = s.players[0].hand[0];
  assert.ok(uid, "expected at least 1 hand card");

  const view = ctx.MC.ui.newView();
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");
  assert.ok(view.menu.items.length > 0);
  assert.equal(view.menu.items[view.menu.items.length - 1].id, "source");
});

