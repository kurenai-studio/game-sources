import test from "node:test";
import assert from "node:assert/strict";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

function makeRecorder() {
  const calls = [];
  const push = (kind, args) => calls.push({ kind, args: [...args] });
  return {
    calls,
    globals: {
      cls: (...a) => push("cls", a),
      print: (...a) => push("print", a),
      rect: (...a) => push("rect", a),
      rectb: (...a) => push("rectb", a),
      line: (...a) => push("line", a),
      spr: (...a) => push("spr", a),
      btn: () => 0,
      btnp: () => 0
    }
  };
}

function newView(ctx) {
  return ctx.MC.ui.newView();
}

function drawFrame(ctx, state, view) {
  const c0 = ctx.MC.ui.computeRowModels(state, view);
  ctx.MC.ui.updateCameras(state, view, c0);
  const computed = ctx.MC.ui.computeRowModels(state, view);
  ctx.MC.render.drawFrame({ state, view, computed });
  return computed;
}

test("render: highlight is drawn last for selected card", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const debug = ctx.MC.debug;
  ctx.MC.debug.reset({ skipGameStartAnim: true });
  debug.state.activeP = 0;
  debug.view.cursor.row = ctx.MC.render.ROW_P_HAND;
  debug.view.cursor.i = 0;

  drawFrame(ctx, debug.state, debug.view);

  assert.ok(rec.calls.length > 0, "expected draw calls");

  const handFaceY = 110; // row5 y=109..135; face inset is +1
  const faceBordersInHandRow = rec.calls
    .map((c, idx) => ({ c, idx }))
    .filter(({ c }) => c.kind === "rect" && c.args[2] === 17 && c.args[3] === 25 && c.args[1] === handFaceY);
  assert.ok(faceBordersInHandRow.length > 0, "expected face border draws in player hand row");

  const highlightCalls = rec.calls
    .map((c, idx) => ({ c, idx }))
    .filter(({ c }) => c.kind === "rectb" && c.args[2] === 19 && c.args[3] === 27);
  assert.ok(highlightCalls.length > 0, "expected highlight rectb call(s) with 19x27");

  const lastHighlightIdx = highlightCalls.at(-1).idx;
  const lastHandFaceIdx = faceBordersInHandRow.at(-1).idx;
  assert.ok(lastHighlightIdx > lastHandFaceIdx, "expected highlight to be drawn after hand cards");
});

test("render: feedback blink turns highlight red", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  ctx.MC.debug.reset({ skipGameStartAnim: true });
  const s = ctx.MC.debug.state;
  const v = ctx.MC.debug.view;
  s.activeP = 0;
  v.cursor.row = ctx.MC.render.ROW_P_HAND;
  v.cursor.i = 0;

  // Force blink-on phase.
  v.feedback.blinkFrames = 1;
  v.feedback.blinkPhase = 0;

  drawFrame(ctx, s, v);

  const highlightCalls = rec.calls.filter((c) => c.kind === "rectb" && c.args[2] === 19 && c.args[3] === 27);
  assert.ok(highlightCalls.length > 0, "expected highlight rectb call(s) with 19x27");

  const last = highlightCalls.at(-1);
  assert.equal(last.args[4], ctx.MC.Pal.Red, "expected highlight to be red while feedback blink is active");
});

test("render: stack uses stride=8 and shadow at xFace-1", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  // Create a deterministic table state with at least one stack of 2 cards.
  ctx.MC.debug.reset({ skipGameStartAnim: true });
  // Ensure P0 has a set with 2 props via scenario.
  const s2 = ctx.MC.state.newGame({ scenarioId: "houseBasic", seedU32: 1 });
  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_P_TABLE;
  view.cursor.i = 0;

  drawFrame(ctx, s2, view);

  // Find two face border rect calls for the table row.
  // Card face base draws a border rect with width=17 and height=25.
  const tableFaceY = 83; // row4 y=82..108; face inset is +1
  const faceBorders = rec.calls.filter((c) => c.kind === "rect" && c.args[2] === 17 && c.args[3] === 25 && c.args[1] === tableFaceY);
  assert.ok(faceBorders.length >= 2, "expected at least 2 face border rect calls");

  // Find two shadow bars (rect w=1, h=25) and ensure they align with xFace-1.
  const shadows = rec.calls.filter((c) => c.kind === "rect" && c.args[2] === 1 && c.args[3] === 25 && c.args[1] === tableFaceY);
  assert.ok(shadows.length >= 2, "expected shadow bar rect calls");

  // Ensure there exists at least one adjacent face pair with stride=8.
  const xs = faceBorders.map((c) => c.args[0]).sort((a, b) => a - b);
  let sawStride = false;
  for (let i = 1; i < xs.length; i++) {
    if (xs[i] - xs[i - 1] === 8) {
      sawStride = true;
      break;
    }
  }
  assert.ok(sawStride, "expected to find at least one 8px stride in table faces");

  // For each face x, there should be a shadow at x-1.
  const shadowXs = new Set(shadows.map((c) => c.args[0]));
  for (const x of xs) assert.ok(shadowXs.has(x - 1), `expected shadow at xFace-1 for face x=${x}`);
});

test("render: rotated digit uses (-4,-2) anchor offsets with rotate=2", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  // Put a wild property into opponent table so it's drawn flip180=true.
  const s = ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 });
  const wildUid = s.players[0].hand.find((uid) => ctx.MC.state.defByUid(s, uid).id === "wild_mo");
  assert.ok(wildUid, "expected wild_mo uid");

  const set = ctx.MC.state.newEmptySet();
  set.props.push([wildUid, ctx.MC.Color.Magenta]);
  s.players[1].sets = [set];
  s.players[1].hand = [];
  s.players[0].hand = [];
  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_OP_TABLE;
  view.cursor.i = 0;
  drawFrame(ctx, s, view);

  // Opponent table first card xFace is at 240-4-17 = 219, yFace is row2 start (12) + inset (1) = 13.
  // Note: row-local camera may shift xFace; draw uses xFaceScreen = xFace - camX.
  // Wild top-half value digit local is at (1,1) with size 3x5; after flip180, glyph TL is at:
  // x = xFace + (17-(1+3)) = xFace+13; y = yFace + (25-(1+5)) = yFace+19
  // drawDigitGlyph then draws spr at (x-4, y-2) with rotate=2 (inset=1 border in tile).
  const cam = view.camX[ctx.MC.render.ROW_OP_TABLE] ?? 0;
  const xFace = 219 - cam;
  const yFace = 13;
  const expectedX = xFace + 13 - 4; // 228
  const expectedY = yFace + 19 - 2; // 30

  const sprRot2AtExpected = rec.calls.find(
    (c) => c.kind === "spr" && c.args[6] === 2 && c.args[1] === expectedX && c.args[2] === expectedY
  );
  assert.ok(sprRot2AtExpected, `expected rotate=2 digit spr at (${expectedX},${expectedY})`);
});

test("render: rent card draws 2px color bars at bottom", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  // Put a rent(Cyan/Black) card as the only card in player hand.
  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const rentUid = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "rent_cb");
  assert.ok(rentUid, "expected rent_cb uid in deck");
  s.deck = s.deck.filter((uid) => uid !== rentUid);
  s.players[0].hand = [rentUid];
  s.players[1].hand = [];
  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;
  drawFrame(ctx, s, view);

  // Player hand first card: xFace=4, yFace=110 (row5 y=109..135; inset +1).
  // Note: row-local camera may shift xFace; draw uses xFaceScreen = xFace - camX.
  const cam = view.camX[ctx.MC.render.ROW_P_HAND] ?? 0;
  const xFace = 4 - cam;
  // Bars are inside the 1px border: local x=1, w=15; local y=22 (bottom) then 20.
  const x0 = xFace + 1;
  const y0 = 132; // 110 + 22
  const y1 = 130; // 110 + 20

  const bars = rec.calls.filter(
    (c) => c.kind === "rect" && c.args[0] === x0 && (c.args[1] === y0 || c.args[1] === y1) && c.args[2] === 15 && c.args[3] === 2
  );
  assert.equal(bars.length, 2, "expected exactly two 15x2 rent bar rects at y=132 and y=130");

  const colByY = new Map(bars.map((b) => [b.args[1], b.args[4]]));
  assert.equal(colByY.get(y0), ctx.MC.Pal.Cyan, "expected bottom bar cyan");
  assert.equal(colByY.get(y1), ctx.MC.Pal.Black, "expected top bar black");
});

test("render: money card center icon draws as a 2x2 sprite block", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  const uid = ctx.MC.state.takeUid(s, "money_1");
  assert.ok(uid, "expected money_1 uid");

  // Minimal visible state: only this money card in player hand.
  s.deck = s.deck.filter((u) => u !== uid);
  s.discard = s.discard.filter((u) => u !== uid);
  for (let p = 0; p < 2; p++) {
    s.players[p].hand = s.players[p].hand.filter((u) => u !== uid);
    s.players[p].bank = s.players[p].bank.filter((u) => u !== uid);
    s.players[p].sets = [];
  }
  s.players[0].hand = [uid];
  s.activeP = 0;
  s.playsLeft = 3;

  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;
  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const S = ctx.MC.config.render.style;
  const sprId = ctx.MC.config.render.spr.iconMoney;

  const cam = view.camX[ctx.MC.render.ROW_P_HAND] ?? 0;
  const xFace = (L.rowPadX) - cam;
  const yFace = L.rowY[ctx.MC.render.ROW_P_HAND] + L.faceInsetY;
  const expectedX = xFace + S.iconX;
  const expectedY = yFace + S.iconY;

  const sprCall = rec.calls.find(
    (c) =>
      c.kind === "spr" &&
      c.args[0] === sprId &&
      c.args[1] === expectedX &&
      c.args[2] === expectedY &&
      c.args[3] === S.sprColorkey &&
      c.args[4] === 1 &&
      c.args[5] === 0 &&
      c.args[6] === 0 &&
      c.args[7] === 2 &&
      c.args[8] === 2
  );
  assert.ok(sprCall, `expected 2x2 money icon spr at (${expectedX},${expectedY})`);
});

test("render: opponent table stack shadow is mirrored", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  // Build a state with a 2-card opponent set (fan left).
  const s = ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 });
  const uidA = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "prop_cyan");
  assert.ok(uidA, "expected prop_cyan uid in deck");
  s.deck = s.deck.filter((uid) => uid !== uidA);
  const uidB = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "prop_cyan");
  assert.ok(uidB, "expected second prop_cyan uid in deck");
  s.deck = s.deck.filter((uid) => uid !== uidB);

  const set = ctx.MC.state.newEmptySet();
  set.props.push([uidA, ctx.MC.Color.Cyan]);
  set.props.push([uidB, ctx.MC.Color.Cyan]);
  s.players[1].sets = [set];
  s.players[1].hand = [];
  s.players[0].sets = [];
  s.players[0].hand = [];
  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_OP_TABLE;
  view.cursor.i = 0;
  drawFrame(ctx, s, view);

  const cfg = ctx.MC.config.render.layout;
  const cam = view.camX[ctx.MC.render.ROW_OP_TABLE] ?? 0;
  const rightCursor = cfg.screenW - cfg.rowPadX - cfg.faceW; // 240-4-17 = 219
  const xTopFace = (rightCursor - cfg.stackStrideX) - cam; // depth 1
  const yFace = cfg.rowY[ctx.MC.render.ROW_OP_TABLE] + cfg.faceInsetY; // 12 + 1
  const expectedShadowX = xTopFace + cfg.faceW;

  const shadows = rec.calls.filter(
    (c) => c.kind === "rect" && c.args[2] === 1 && c.args[3] === cfg.faceH && c.args[1] === yFace
  );
  assert.ok(shadows.length > 0, "expected shadow bar rect calls in opponent table row");
  assert.ok(
    shadows.some((c) => c.args[0] === expectedShadowX),
    `expected mirrored shadow at xFace+faceW (x=${expectedShadowX}) for opponent stack`
  );
});

test("render: player bank renders as fanned stack in hand row", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const uid1 = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "money_2");
  assert.ok(uid1, "expected money_2 uid in deck");
  s.deck = s.deck.filter((uid) => uid !== uid1);
  const uid2 = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "sly_deal");
  assert.ok(uid2, "expected sly_deal uid in deck");
  s.deck = s.deck.filter((uid) => uid !== uid2);

  s.players[0].hand = [];
  s.players[0].bank = [uid1, uid2];
  s.players[0].sets = [];
  s.players[1].hand = [];
  s.players[1].bank = [];
  s.players[1].sets = [];
  const view = newView(ctx);
  // Select a different row so the bank stack is NOT the selected item.
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 0;
  drawFrame(ctx, s, view);

  const cfg = ctx.MC.config.render.layout;
  const yFace = cfg.rowY[ctx.MC.render.ROW_P_HAND] + cfg.faceInsetY; // 109 + 1
  const cam = view.camX[ctx.MC.render.ROW_P_HAND] ?? 0;
  assert.equal(cam, 0, "expected no scrolling when bank stack fits in player hand row");

  const faces = rec.calls
    .filter((c) => c.kind === "rect" && c.args[2] === cfg.faceW && c.args[3] === cfg.faceH && c.args[1] === yFace)
    .map((c) => c.args[0])
    .sort((a, b) => a - b);
  assert.ok(faces.length >= 2, "expected at least 2 mini-card face rects in player hand row");

  // Bank uses stride=8: expect adjacent faces differ by 8.
  let sawStride = false;
  for (let i = 1; i < faces.length; i++) {
    if (faces[i] - faces[i - 1] === cfg.stackStrideX) {
      sawStride = true;
      break;
    }
  }
  assert.ok(sawStride, "expected to find bank fanning stride in hand row faces");

  // Player bank fanDir=+1 uses shadow on left edge: shadow x should equal xFace-1 for at least one face.
  const shadows = rec.calls
    .map((c, idx) => ({ c, idx }))
    .filter(({ c }) => c.kind === "rect" && c.args[2] === 1 && c.args[3] === cfg.faceH && c.args[1] === yFace);
  assert.ok(shadows.length > 0, "expected shadow bar rect calls in player hand row");
  const shadowXs = new Set(shadows.map(({ c }) => c.args[0]));
  assert.ok(faces.some((x) => shadowXs.has(x - 1)), "expected at least one bank shadow at xFace-1");

  // Shadow that creates the 7px peek must be drawn after the left card,
  // but before drawing the right/top card (since it's emitted just before that card's face).
  const xLeft = faces[0];
  const xRight = faces[1];
  const faceCallIdx = (x) =>
    rec.calls.findIndex((c) => c.kind === "rect" && c.args[0] === x && c.args[1] === yFace && c.args[2] === cfg.faceW && c.args[3] === cfg.faceH);
  const idxLeftFace = faceCallIdx(xLeft);
  const idxRightFace = faceCallIdx(xRight);
  assert.ok(idxLeftFace >= 0, "expected leftmost bank face rect call");
  assert.ok(idxRightFace >= 0, "expected rightmost bank face rect call");
  const idxShadow = shadows.find(({ c }) => c.args[0] === xRight - 1)?.idx ?? -1;
  assert.ok(idxShadow > idxLeftFace, "expected overlap shadow to be drawn after left card face");
  assert.ok(idxShadow < idxRightFace, "expected overlap shadow to be drawn before right card face");
});

test("render: opponent bank renders as mirrored fanned stack in hand row", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const uid1 = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "money_2");
  assert.ok(uid1, "expected money_2 uid in deck");
  s.deck = s.deck.filter((uid) => uid !== uid1);
  const uid2 = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "sly_deal");
  assert.ok(uid2, "expected sly_deal uid in deck");
  s.deck = s.deck.filter((uid) => uid !== uid2);

  s.players[1].hand = [];
  s.players[1].bank = [uid1, uid2];
  s.players[1].sets = [];
  s.players[0].hand = [];
  s.players[0].bank = [];
  s.players[0].sets = [];
  const view = newView(ctx);
  // Select a different row so the bank stack is NOT the selected item.
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 0;
  drawFrame(ctx, s, view);

  const cfg = ctx.MC.config.render.layout;
  const yFace = cfg.rowY[ctx.MC.render.ROW_OP_HAND] + cfg.rowH[ctx.MC.render.ROW_OP_HAND] - cfg.faceH;
  const cam = view.camX[ctx.MC.render.ROW_OP_HAND] ?? 0;
  assert.equal(cam, 0, "expected no scrolling when bank stack fits in opponent hand row");

  const faces = rec.calls
    .filter((c) => c.kind === "rect" && c.args[2] === cfg.faceW && c.args[3] === cfg.faceH && c.args[1] === yFace)
    .map((c) => c.args[0])
    .sort((a, b) => a - b);
  assert.ok(faces.length >= 2, "expected at least 2 mini-card face rects in opponent hand row");

  // Opponent bank fanDir=-1 uses shadow on right edge: shadow x should equal xFace+faceW.
  const shadows = rec.calls
    .map((c, idx) => ({ c, idx }))
    .filter(({ c }) => c.kind === "rect" && c.args[2] === 1 && c.args[3] === cfg.faceH && c.args[1] === yFace);
  assert.ok(shadows.length > 0, "expected shadow bar rect calls in opponent hand row");

  const xLeft = faces[0];
  const xRight = faces[1];
  const faceCallIdx = (x) =>
    rec.calls.findIndex((c) => c.kind === "rect" && c.args[0] === x && c.args[1] === yFace && c.args[2] === cfg.faceW && c.args[3] === cfg.faceH);
  const idxLeftFace = faceCallIdx(xLeft);
  const idxRightFace = faceCallIdx(xRight);
  assert.ok(idxLeftFace >= 0, "expected leftmost opponent bank face rect call");
  assert.ok(idxRightFace >= 0, "expected rightmost opponent bank face rect call");

  const expectedOverlapShadowX = xLeft + cfg.faceW;
  const idxShadow = shadows.find(({ c }) => c.args[0] === expectedOverlapShadowX)?.idx ?? -1;
  assert.ok(idxShadow >= 0, `expected overlap shadow at xFace+faceW (x=${expectedOverlapShadowX})`);
  assert.ok(idxShadow > idxRightFace, "expected overlap shadow to be drawn after right card face");
  assert.ok(idxShadow < idxLeftFace, "expected overlap shadow to be drawn before left card face");
});

test("render: wild in set uses assigned color for visual top", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 });
  const wildUid = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "wild_cb");
  assert.ok(wildUid, "expected wild_cb uid in deck");
  s.deck = s.deck.filter((uid) => uid !== wildUid);

  const set = ctx.MC.state.newEmptySet();
  set.props.push([wildUid, ctx.MC.Color.Black]); // assign black
  s.players[0].sets = [set];
  s.players[0].hand = [];
  s.players[1].sets = [];
  s.players[1].hand = [];
  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_P_TABLE;
  view.cursor.i = 0;
  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const S = ctx.MC.config.render.style;
  const cam = view.camX[ctx.MC.render.ROW_P_TABLE] ?? 0;
  const xFace = L.rowPadX - cam; // first set starts at padX
  const yFace = L.rowY[ctx.MC.render.ROW_P_TABLE] + L.faceInsetY; // 82 + 1

  // Top-half property bar rect at local (5,1) with size 11x5.
  const xBar = xFace + S.propBarX;
  const yBar = yFace + S.propBarY;
  const bar = rec.calls.find(
    (c) => c.kind === "rect" && c.args[0] === xBar && c.args[1] === yBar && c.args[2] === S.propBarW && c.args[3] === S.propBarH
  );
  assert.ok(bar, "expected to find top-half property color bar rect");
  assert.equal(bar.args[4], ctx.MC.Pal.Black, "expected assigned black to render as black (avoid index 15 reserved for transparency)");
});

test("render: opponent wild in set keeps assigned color on owner-facing half", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "wildBasic", seedU32: 1 });
  const wildUid = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "wild_cb");
  assert.ok(wildUid, "expected wild_cb uid in deck");
  s.deck = s.deck.filter((uid) => uid !== wildUid);

  const set = ctx.MC.state.newEmptySet();
  set.props.push([wildUid, ctx.MC.Color.Black]); // assign black
  s.players[1].sets = [set];
  s.players[1].hand = [];
  s.players[0].sets = [];
  s.players[0].hand = [];
  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_OP_TABLE;
  view.cursor.i = 0;
  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const S = ctx.MC.config.render.style;
  const cam = view.camX[ctx.MC.render.ROW_OP_TABLE] ?? 0;
  const xFace = (L.screenW - L.rowPadX - L.faceW) - cam;
  const yFace = L.rowY[ctx.MC.render.ROW_OP_TABLE] + L.faceInsetY;

  // Owner-facing half for opponent is the screen-bottom half (card is drawn flip180=true).
  // propBar local rect is (S.propBarX,S.propBarY,S.propBarW,S.propBarH); with flip180=true:
  // x = xFace + (faceW - (x+w)), y = yFace + (faceH - (y+h))
  const xBar = xFace + (L.faceW - (S.propBarX + S.propBarW));
  const yBar = yFace + (L.faceH - (S.propBarY + S.propBarH));

  const bar = rec.calls.find(
    (c) => c.kind === "rect" && c.args[0] === xBar && c.args[1] === yBar && c.args[2] === S.propBarW && c.args[3] === S.propBarH
  );
  assert.ok(bar, "expected to find owner-facing property color bar rect for opponent wild");
  assert.equal(bar.args[4], ctx.MC.Pal.Black, "expected assigned black to render as black (avoid index 15 reserved for transparency)");
});

test("render: no scroll when content fits (opponent hand row)", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const uidBank = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "money_1");
  assert.ok(uidBank, "expected money_1 uid in deck");
  s.deck = s.deck.filter((uid) => uid !== uidBank);
  const uidHand = s.deck.find((uid) => ctx.MC.state.defByUid(s, uid).id === "money_2");
  assert.ok(uidHand, "expected money_2 uid in deck");
  s.deck = s.deck.filter((uid) => uid !== uidHand);

  s.players[1].bank = [uidBank];
  s.players[1].hand = [uidHand];
  s.players[0].bank = [];
  s.players[0].hand = [];
  const view = newView(ctx);
  // Select a different row so ROW_OP_HAND uses selI=0 camera update.
  view.cursor.row = ctx.MC.render.ROW_P_TABLE;
  view.cursor.i = 0;
  drawFrame(ctx, s, view);

  const cam = view.camX[ctx.MC.render.ROW_OP_HAND] ?? 0;
  assert.equal(cam, 0, "expected no scrolling when opponent hand+bank fit");
});

test("render: opponent hand back tiles start at interior origin", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  assert.ok(s.players[1].hand.length > 0, "expected opponent to have at least 1 card");
  const uid = s.players[1].hand[0];

  // Make a minimal state: one opponent hand card so we know which back to target.
  s.players[1].hand = [uid];
  s.players[0].hand = [];
  s.players[0].bank = [];
  s.players[1].bank = [];
  s.players[0].sets = [];
  s.players[1].sets = [];
  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_OP_HAND;
  view.cursor.i = 0;
  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const cam = view.camX[ctx.MC.render.ROW_OP_HAND] ?? 0;
  const xFace = (L.screenW - L.rowPadX - L.faceW) - cam;
  const yFace = L.rowY[ctx.MC.render.ROW_OP_HAND] + L.rowH[ctx.MC.render.ROW_OP_HAND] - L.faceH;
  const backId = ctx.MC.config.render.spr.cardBackTL;

  const sprCall = rec.calls.find(
    (c) =>
      c.kind === "spr" &&
      c.args[0] === backId &&
      c.args[1] === (xFace + 1) &&
      c.args[2] === (yFace + 1) &&
      c.args[6] === 0 &&
      c.args[7] === 1 &&
      c.args[8] === 1
  );
  assert.ok(sprCall, `expected card back tile spr at (${xFace + 1},${yFace + 1})`);
});

test("render: center button strip uses dark fill and selected uses highlight fill", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const view = newView(ctx);

  // Move selection to center row. We expect deck, discard, then endTurn button.
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 2; // first button (End)

  const computed = drawFrame(ctx, s, view);
  const rowM = computed.models[ctx.MC.render.ROW_CENTER];
  const endBtn = rowM.items.find((it) => it && it.kind === "btn" && it.id === "endTurn");
  assert.ok(endBtn, "expected to find End button model item");

  // Selected button should draw a filled rect with highlight color at its bounds.
  const fillHighlight = rec.calls.find(
    (c) =>
      c.kind === "rect" &&
      c.args[0] === endBtn.x &&
      c.args[1] === endBtn.y &&
      c.args[2] === endBtn.w &&
      c.args[3] === endBtn.h &&
      c.args[4] === ctx.MC.config.render.style.colHighlight
  );
  assert.ok(fillHighlight, "expected selected End button to have highlight fill rect");

  // Some non-selected debug button (if present) should have no fill (transparent),
  // so the center-panel dither shows through.
  const otherBtn = rowM.items.find((it) => it && it.kind === "btn" && it.id !== "endTurn");
  if (otherBtn) {
    const anyFill = rec.calls.find(
      (c) =>
        c.kind === "rect" &&
        c.args[0] === otherBtn.x &&
        c.args[1] === otherBtn.y &&
        c.args[2] === otherBtn.w &&
        c.args[3] === otherBtn.h
    );
    assert.ok(!anyFill, "expected non-selected button to have no fill rect (transparent)");
  }
});

test("render: End button shows green recommendation when out of plays", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 0;
  // Ensure End is legal (hand size <= 7).
  s.players[0].hand = s.players[0].hand.slice(0, 5);

  const view = newView(ctx);
  // Do not select the End button (recommendation should still appear).
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 0; // deck

  const computed = drawFrame(ctx, s, view);
  const rowM = computed.models[ctx.MC.render.ROW_CENTER];
  const endBtn = rowM.items.find((it) => it && it.kind === "btn" && it.id === "endTurn");
  assert.ok(endBtn, "expected to find End button model item");

  const greenBorder = rec.calls.find(
    (c) =>
      c.kind === "rectb" &&
      c.args[0] === endBtn.x &&
      c.args[1] === endBtn.y &&
      c.args[2] === endBtn.w &&
      c.args[3] === endBtn.h &&
      c.args[4] === ctx.MC.Pal.Green
  );
  assert.ok(greenBorder, "expected End button border to be green when out of plays");
});

test("render: shuffle masking shows discard empty while deck shuffles", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  // Minimal state: no cards drawn on-screen except piles.
  s.players[0].hand = [];
  s.players[1].hand = [];
  s.players[0].bank = [];
  s.players[1].bank = [];
  s.players[0].sets = [];
  s.players[1].sets = [];

  // Post-reshuffle state: deck has 3 cards, discard is empty.
  const keep = [s.deck.pop(), s.deck.pop(), s.deck.pop()];
  s.deck = keep;
  s.discard = [];

  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_CENTER;
  view.cursor.i = 0; // deck
  // During shuffle animation we mask pile visuals: deck shows 0, discard shows 0.
  view.anim = {
    q: [],
    lock: true,
    hiddenByP: [{}, {}],
    hiddenByUid: {},
    lastPosByUid: {},
    payBufUids: [],
    // t=9 ensures the renderer is in the "2 underlayers" shuffle phase.
    active: { kind: "shuffle", t: 9, frames: 42, deckNVis: 0, discardNVis: 0 }
  };

  function expectedDigitSprXY(xFace, yFace) {
    const L = ctx.MC.config.render.layout;
    const S = ctx.MC.config.render.style;
    const xEnd = L.faceW - 1 - S.digitGlyphW + S.pileCountDx;
    const yTL = L.faceH - 1 - S.digitGlyphH + S.pileCountDy;
    return {
      x: xFace + xEnd - S.glyphInsetX,
      y: yFace + yTL - S.glyphInsetY
    };
  }

  const L = ctx.MC.config.render.layout;
  const rowCenter = ctx.MC.render.ROW_CENTER;
  const yPile = L.rowY[rowCenter] + L.centerTopInsetY;
  const xDeck = L.centerDeckX;
  const xDisc = L.centerDeckX + L.faceW + L.centerPileGapX;

  const deckDigitPos = expectedDigitSprXY(xDeck, yPile);
  const discDigitPos = expectedDigitSprXY(xDisc, yPile);
  const digit0 = ctx.MC.config.render.spr.digit0;

  // Frame 1 (shuffle active): deck shows 0, discard shows 0.
  drawFrame(ctx, s, view);

  const sprDeck0 = rec.calls.find(
    (c) => c.kind === "spr" && c.args[0] === (digit0 + 0) && c.args[1] === deckDigitPos.x && c.args[2] === deckDigitPos.y
  );
  const sprDeck3 = rec.calls.find(
    (c) => c.kind === "spr" && c.args[0] === (digit0 + 3) && c.args[1] === deckDigitPos.x && c.args[2] === deckDigitPos.y
  );
  const sprDisc0 = rec.calls.find(
    (c) => c.kind === "spr" && c.args[0] === (digit0 + 0) && c.args[1] === discDigitPos.x && c.args[2] === discDigitPos.y
  );
  assert.ok(sprDeck0, "expected deck count to be masked to 0 during shuffle");
  assert.ok(!sprDeck3, "expected deck count not to show actual value during shuffle");
  assert.ok(sprDisc0, "expected discard to be shown as empty during shuffle");

  // Ensure discard underlayer outlines are NOT drawn (discard is empty).
  const discUnderlayerRectbIdxs = [];
  const dx1 = L.pileUnderDx1;
  const dy1 = L.pileUnderDy1;
  const dx2 = L.pileUnderDx2;
  const dy2 = L.pileUnderDy2;
  for (let i = 0; i < rec.calls.length; i++) {
    const c = rec.calls[i];
    if (!c || c.kind !== "rectb") continue;
    if (c.args[2] !== L.faceW || c.args[3] !== L.faceH) continue;
    const x = c.args[0], y = c.args[1];
    const isDx1 = (x === (xDisc + dx1 - 1) && y === (yPile + dy1 - 1)) || (x === (xDisc + dx1) && y === (yPile + dy1));
    const isDx2 = (x === (xDisc + dx2 - 1) && y === (yPile + dy2 - 1)) || (x === (xDisc + dx2) && y === (yPile + dy2));
    if (isDx1 || isDx2) discUnderlayerRectbIdxs.push(i);
  }
  assert.equal(discUnderlayerRectbIdxs.length, 0, "expected no discard underlayer outlines during shuffle");

  // Also assert shuffle underlayers are drawn BEFORE the deck's top card back,
  // so the underlayer "shadows" never render on top of the card.
  const cardBackTL = ctx.MC.config.render.spr.cardBackTL;
  const deckCardBackSprIdx = rec.calls.findIndex(
    (c) =>
      c.kind === "spr" &&
      c.args[0] === cardBackTL &&
      c.args[1] === (xDeck + 1) &&
      c.args[2] === (yPile + 1)
  );
  assert.ok(deckCardBackSprIdx >= 0, "expected to find deck card-back sprite draw");

  const underlayerRectbIdxs = [];
  for (let i = 0; i < rec.calls.length; i++) {
    const c = rec.calls[i];
    if (!c || c.kind !== "rectb") continue;
    if (c.args[2] !== L.faceW || c.args[3] !== L.faceH) continue;
    const x = c.args[0], y = c.args[1];
    const isDx1 = (x === (xDeck + dx1 - 1) && y === (yPile + dy1 - 1)) || (x === (xDeck + dx1) && y === (yPile + dy1));
    const isDx2 = (x === (xDeck + dx2 - 1) && y === (yPile + dy2 - 1)) || (x === (xDeck + dx2) && y === (yPile + dy2));
    if (isDx1 || isDx2) underlayerRectbIdxs.push(i);
  }
  assert.ok(underlayerRectbIdxs.length >= 4, "expected shuffle to draw two underlayer outlines (4 rectb calls)");
  const maxUnderlayerIdx = Math.max(...underlayerRectbIdxs);
  assert.ok(
    deckCardBackSprIdx > maxUnderlayerIdx,
    "expected deck top card back to be drawn after shuffle underlayers"
  );

  // Frame 2 (shuffle finished): deck shows 3, discard shows 0.
  rec.calls.length = 0;
  view.anim.active = null;
  view.anim.lock = false;
  drawFrame(ctx, s, view);

  const sprDeck3After = rec.calls.find(
    (c) => c.kind === "spr" && c.args[0] === (digit0 + 3) && c.args[1] === deckDigitPos.x && c.args[2] === deckDigitPos.y
  );
  const sprDisc0After = rec.calls.find(
    (c) => c.kind === "spr" && c.args[0] === (digit0 + 0) && c.args[1] === discDigitPos.x && c.args[2] === discDigitPos.y
  );
  assert.ok(sprDeck3After, "expected deck count to show actual value after shuffle");
  assert.ok(sprDisc0After, "expected discard count to show 0 after shuffle");
});

test("render: bank hold-chain draws preview in bank stack", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  const moneyUid = ctx.MC.state.takeUid(s, "money_1");
  assert.ok(moneyUid, "expected money_1 uid");
  const bankUid = ctx.MC.state.takeUid(s, "money_2");
  assert.ok(bankUid, "expected money_2 uid");
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
  s.players[0].bank = [bankUid];
  s.players[0].sets = [];
  s.activeP = 0;
  s.playsLeft = 3;

  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Enter bank hold-chain via hold-A grab.
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "bank");
  assert.ok(view.targeting.chainActive);

  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const bankRightX = L.screenW - L.rowPadX - L.faceW; // 219
  const yFace = L.rowY[ctx.MC.render.ROW_P_HAND] + L.faceInsetY; // 110

  const previewBorder = rec.calls.find(
    (c) => c.kind === "rect" && c.args[0] === bankRightX && c.args[1] === yFace && c.args[2] === L.faceW && c.args[3] === L.faceH
  );
  assert.ok(previewBorder, `expected bank preview border rect at (${bankRightX},${yFace})`);

  // Existing bank stack should shift left by one stride during bank targeting.
  const shiftedX = bankRightX - L.stackStrideX;
  const existingBorder = rec.calls.find(
    (c) => c.kind === "rect" && c.args[0] === shiftedX && c.args[1] === yFace && c.args[2] === L.faceW && c.args[3] === L.faceH
  );
  assert.ok(existingBorder, `expected existing bank card border rect at (${shiftedX},${yFace})`);

  // Source destination should show as a green ghost outline at the grabbed slot (x=rowPadX).
  const xSource = L.rowPadX;
  const ghostSource = rec.calls.find(
    (c) =>
      c.kind === "rectb" &&
      c.args[0] === xSource &&
      c.args[1] === yFace &&
      c.args[2] === L.faceW &&
      c.args[3] === L.faceH &&
      c.args[4] === ctx.MC.Pal.Green
  );
  assert.ok(ghostSource, `expected green ghost outline at Source (${xSource},${yFace})`);
});

test("render: bank hold-chain shows green ghost for bank when Source segment is selected", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  const moneyUid = ctx.MC.state.takeUid(s, "money_1");
  // Remove uid from any zone it might already be in.
  s.deck = s.deck.filter((u) => u !== moneyUid);
  s.discard = s.discard.filter((u) => u !== moneyUid);
  for (let p = 0; p < 2; p++) {
    s.players[p].hand = s.players[p].hand.filter((u) => u !== moneyUid);
    s.players[p].bank = s.players[p].bank.filter((u) => u !== moneyUid);
  }
  s.players[0].hand = [moneyUid];
  s.players[0].bank = [];
  s.players[0].sets = [];
  s.activeP = 0;
  s.playsLeft = 3;

  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.ok(view.targeting.chainActive);

  // Cycle to Source segment, so bank becomes non-selected and should be ghosted.
  ctx.MC.ui.step(s, view, { nav: { right: true }, a: {}, b: {}, x: {} });
  assert.equal(view.targeting.kind, "source");
  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const bankRightX = L.screenW - L.rowPadX - L.faceW;
  const yFace = L.rowY[ctx.MC.render.ROW_P_HAND] + L.faceInsetY;
  const ghostBank = rec.calls.find(
    (c) =>
      c.kind === "rectb" &&
      c.args[0] === bankRightX &&
      c.args[1] === yFace &&
      c.args[2] === L.faceW &&
      c.args[3] === L.faceH &&
      c.args[4] === ctx.MC.Pal.Green
  );
  assert.ok(ghostBank, `expected green ghost outline at Bank (${bankRightX},${yFace}) when Source selected`);
});

test("render: rent hold-chain shows bank ghost and shifts existing bank stack left", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  const rentUid = ctx.MC.state.takeUid(s, "rent_mo");
  const propUid = ctx.MC.state.takeUid(s, "prop_orange");
  const bankUid = ctx.MC.state.takeUid(s, "money_2");

  // Remove uids from any zone they might already be in.
  for (const uid of [rentUid, propUid, bankUid]) {
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
  }

  // One eligible set so Rent has a legal destination.
  const defProp = ctx.MC.state.defByUid(s, propUid);
  const set = ctx.MC.state.newEmptySet();
  set.props.push([propUid, defProp.propertyColor]);

  s.players[0].hand = [rentUid];
  s.players[0].bank = [bankUid];
  s.players[0].sets = [set];
  s.activeP = 0;
  s.playsLeft = 3;

  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;

  // Enter rent hold-chain targeting via hold-A grab on the Rent card.
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "rent");
  assert.ok(view.targeting.chainActive);

  // Default rent targeting prefers playRent, so bank should be non-selected and ghosted.
  const cmdSel = view.targeting.cmds[view.targeting.cmdI];
  assert.ok(cmdSel && cmdSel.kind === "playRent", "expected rent targeting default selection to be playRent");

  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const bankRightX = L.screenW - L.rowPadX - L.faceW;
  const yFace = L.rowY[ctx.MC.render.ROW_P_HAND] + L.faceInsetY;

  const ghostBank = rec.calls.find(
    (c) =>
      c.kind === "rectb" &&
      c.args[0] === bankRightX &&
      c.args[1] === yFace &&
      c.args[2] === L.faceW &&
      c.args[3] === L.faceH &&
      c.args[4] === ctx.MC.Pal.Green
  );
  assert.ok(ghostBank, `expected green ghost outline at Bank (${bankRightX},${yFace}) during rent hold-chain`);

  // Existing bank card border rect should be shifted left by one stride while the bank ghost is shown.
  const shiftedX = bankRightX - L.stackStrideX;
  const existingBorderShifted = rec.calls.find(
    (c) => c.kind === "rect" && c.args[0] === shiftedX && c.args[1] === yFace && c.args[2] === L.faceW && c.args[3] === L.faceH
  );
  assert.ok(existingBorderShifted, `expected existing bank card border rect at (${shiftedX},${yFace}) during rent hold-chain`);

  const existingBorderUnshifted = rec.calls.find(
    (c) => c.kind === "rect" && c.args[0] === bankRightX && c.args[1] === yFace && c.args[2] === L.faceW && c.args[3] === L.faceH
  );
  assert.equal(!!existingBorderUnshifted, false, `expected existing bank card border rect not at (${bankRightX},${yFace}) during rent hold-chain`);
});

test("render: sly hold-chain shows bank ghost while cursor targets opponent cards", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  ctx.MC.state.clearPrompt(s);

  // Give P0 a Sly Deal in hand.
  const slyUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "sly_deal");
  assert.ok(slyUid, "expected sly_deal uid");
  s.deck = s.deck.filter((u) => u !== slyUid);
  s.players[0].hand.push(slyUid);

  // Give opponent a 1-card incomplete set so Sly has a legal target.
  const propUid = s.deck.find((u) => ctx.MC.state.defByUid(s, u).id === "prop_orange");
  assert.ok(propUid, "expected prop_orange uid");
  s.deck = s.deck.filter((u) => u !== propUid);
  const set = ctx.MC.state.newEmptySet();
  set.props.push([propUid, ctx.MC.Color.Orange]);
  s.players[1].sets = [set];

  const view = newView(ctx);
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = s.players[0].hand.indexOf(slyUid);

  // Enter hold-chain targeting via hold-A grab.
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "sly");
  assert.ok(view.targeting.chainActive);

  // Tick once so cursor-mode sync jumps to a target.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });

  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const bankRightX = L.screenW - L.rowPadX - L.faceW;
  const yFace = L.rowY[ctx.MC.render.ROW_P_HAND] + L.faceInsetY;

  const ghostBank = rec.calls.find(
    (c) =>
      c.kind === "rectb" &&
      c.args[0] === bankRightX &&
      c.args[1] === yFace &&
      c.args[2] === L.faceW &&
      c.args[3] === L.faceH &&
      c.args[4] === ctx.MC.Pal.Green
  );
  assert.ok(ghostBank, `expected green ghost outline at Bank (${bankRightX},${yFace}) during sly hold-chain`);
});

test("render: targeting draws ghost outlines and preview overlay", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const view = newView(ctx);

  // Select first card in player hand and enter targeting (hold-A grab).
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;
  ctx.MC.ui.step(s, view, { nav: {}, a: { grabStart: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");

  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const cam = view.camX[ctx.MC.render.ROW_P_TABLE] ?? 0;
  const yFace = L.rowY[ctx.MC.render.ROW_P_TABLE] + L.faceInsetY; // 82 + 1

  // Scenario has 1 orange set at x=padX=4. Preview placement onto that set is at x=4+stride=12.
  const xPreview = (L.rowPadX + L.stackStrideX) - cam; // 4 + 8 = 12
  const previewBorder = rec.calls.find(
    (c) => c.kind === "rect" && c.args[0] === xPreview && c.args[1] === yFace && c.args[2] === L.faceW && c.args[3] === L.faceH
  );
  assert.ok(previewBorder, `expected preview card border rect at (${xPreview},${yFace})`);

  // The other destination is New Set. While targeting previews a card onto the existing set,
  // the table layout reserves one extra slot so New Set shifts right by one stride.
  const xGhost = (L.rowPadX + L.faceW + L.stackStrideX + L.stackGapX) - cam;
  const ghostGreen = rec.calls.find(
    (c) => c.kind === "rectb" && c.args[0] === xGhost && c.args[1] === yFace && c.args[2] === L.faceW && c.args[3] === L.faceH && c.args[4] === ctx.MC.Pal.Green
  );
  assert.ok(ghostGreen, `expected green ghost outline rectb at (${xGhost},${yFace})`);

  // Source destination should also be ghosted in the hand row.
  const yHandFace = L.rowY[ctx.MC.render.ROW_P_HAND] + L.faceInsetY;
  const xSource = L.rowPadX;
  const ghostSource = rec.calls.find(
    (c) =>
      c.kind === "rectb" &&
      c.args[0] === xSource &&
      c.args[1] === yHandFace &&
      c.args[2] === L.faceW &&
      c.args[3] === L.faceH &&
      c.args[4] === ctx.MC.Pal.Green
  );
  assert.ok(ghostSource, `expected green ghost outline at Source (${xSource},${yHandFace})`);
});

test("render: menu Place targeting hides source card (no duplicate) and ghosts source slot", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  s.activeP = 0;
  s.playsLeft = 3;
  const view = newView(ctx);

  // Open menu on first hand card, choose Place (enter targeting from menu, not hold).
  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "menu");

  const placeI = view.menu.items.findIndex((it) => it && it.id === "place");
  assert.ok(placeI >= 0, "expected Place menu item");
  view.menu.i = placeI;
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "place");

  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const xSource = L.rowPadX;
  const yHandFace = L.rowY[ctx.MC.render.ROW_P_HAND] + L.faceInsetY;

  // The preview draws the grabbed uid at the destination, so the source-slot spr for that uid should be absent.
  const uid = view.targeting.card.uid | 0;
  const def = ctx.MC.state.defByUid(s, uid);
  const sprId = def ? (def.sprTL | 0) : -1;
  assert.ok(sprId >= 0, "expected a sprite id for grabbed card");

  const sprAtSource = rec.calls.find((c) => c.kind === "spr" && c.args[0] === sprId && c.args[1] === xSource && c.args[2] === yHandFace);
  assert.equal(!!sprAtSource, false, "expected source card sprite not drawn at its origin during targeting");

  const ghostSource = rec.calls.find(
    (c) =>
      c.kind === "rectb" &&
      c.args[0] === xSource &&
      c.args[1] === yHandFace &&
      c.args[2] === L.faceW &&
      c.args[3] === L.faceH &&
      c.args[4] === ctx.MC.Pal.Green
  );
  assert.ok(ghostSource, `expected green ghost outline at Source (${xSource},${yHandFace})`);
});

test("render: placeReceived targeting hides recvProps source card (no duplicate) and ghosts faux-hand slot", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeReceived", seedU32: 1 });
  const view = newView(ctx);

  // Enter prompt mode then enter targeting from faux-hand.
  ctx.MC.ui.step(s, view, { nav: {}, a: {}, b: {}, x: {} });
  assert.equal(view.mode, "prompt");

  view.cursor.row = ctx.MC.render.ROW_P_HAND;
  view.cursor.i = 0;
  ctx.MC.ui.step(s, view, { nav: {}, a: { tap: true }, b: {}, x: {} });
  assert.equal(view.mode, "targeting");
  assert.equal(view.targeting.kind, "place");
  assert.ok(view.targeting.card && view.targeting.card.loc && view.targeting.card.loc.zone === "recvProps");

  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const xSource = L.rowPadX;
  const yHandFace = L.rowY[ctx.MC.render.ROW_P_HAND] + L.faceInsetY;

  const uid = view.targeting.card.uid | 0;
  const def = ctx.MC.state.defByUid(s, uid);
  const sprId = def ? (def.sprTL | 0) : -1;
  assert.ok(sprId >= 0, "expected a sprite id for grabbed card");

  const sprAtSource = rec.calls.find((c) => c.kind === "spr" && c.args[0] === sprId && c.args[1] === xSource && c.args[2] === yHandFace);
  assert.equal(!!sprAtSource, false, "expected recvProps source card sprite not drawn at faux-hand origin during targeting");

  const ghostSource = rec.calls.find(
    (c) =>
      c.kind === "rectb" &&
      c.args[0] === xSource &&
      c.args[1] === yHandFace &&
      c.args[2] === L.faceW &&
      c.args[3] === L.faceH &&
      c.args[4] === ctx.MC.Pal.Green
  );
  assert.ok(ghostSource, `expected green ghost outline at faux-hand Source (${xSource},${yHandFace})`);
});

test("render: plays indicator draws 3 pips (green remaining, red used)", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const view = newView(ctx);

  // Force a known value.
  s.playsLeft = 2; // => 1 used (red), 2 remaining (green)

  drawFrame(ctx, s, view);

  const L = ctx.MC.config.render.layout;
  const x0 = L.hudLineX;
  const y0 = L.hudLineY;

  const pipPrints = rec.calls.filter(
    (c) => c.kind === "print" && c.args[0] === "o" && c.args[2] === y0
  );
  const byX = new Map(pipPrints.map((c) => [c.args[1], c]));
  const p0 = byX.get(x0);
  const p1 = byX.get(x0 + 6);
  const p2 = byX.get(x0 + 12);
  assert.ok(p0 && p1 && p2, "expected 3 pip prints at hudLineX + 0/6/12");

  assert.equal(p0.args[3], ctx.MC.Pal.Red, "expected first pip red (used)");
  assert.equal(p1.args[3], ctx.MC.Pal.Green, "expected second pip green (remaining)");
  assert.equal(p2.args[3], ctx.MC.Pal.Green, "expected third pip green (remaining)");
});

test("render: feedback message draws a screen-top toast with background, border, and red X", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const view = newView(ctx);
  view.toasts = [{ kind: "error", text: "No moves left", frames: 10 }];

  drawFrame(ctx, s, view);

  // Toast is at y=2 with a black rect background and a border rectb.
  const bg = rec.calls.find((c) => c.kind === "rect" && c.args[1] === 2 && c.args[4] === ctx.MC.Pal.Black);
  assert.ok(bg, "expected toast black background rect at y=2");

  const border = rec.calls.find((c) => c.kind === "rectb" && c.args[1] === 2);
  assert.ok(border, "expected toast border rectb at y=2");

  const redX = rec.calls.find((c) => c.kind === "print" && c.args[0] === "X" && c.args[3] === ctx.MC.Pal.Red);
  assert.ok(redX, "expected red X print in toast");

  const msg = rec.calls.find((c) => c.kind === "print" && c.args[0] === "No moves left");
  assert.ok(msg, "expected toast message print");
});

test("render: ai narration toast uses configured background color", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const view = newView(ctx);
  view.toasts = [{ kind: "ai", text: "AI: Rent", frames: 10 }];

  drawFrame(ctx, s, view);

  const bgCol = ctx.MC.config.render.style.colToastBgAi;
  const bg = rec.calls.find((c) => c.kind === "rect" && c.args[1] === 2 && c.args[4] === bgCol);
  assert.ok(bg, "expected ai toast to use cfg.colToastBgAi as background");
});

test("render: toasts stack top-to-bottom (prompt then error)", async () => {
  const rec = makeRecorder();
  const ctx = await loadSrcIntoVm({ extraGlobals: rec.globals });

  const s = ctx.MC.state.newGame({ scenarioId: "placeBasic", seedU32: 1 });
  const view = newView(ctx);
  view.toasts = [
    { kind: "prompt", text: "Discard 1 more (A:Discard)", persistent: true },
    { kind: "error", text: "No plays left", frames: 10 },
  ];

  drawFrame(ctx, s, view);

  // Expect 2 toast backgrounds at different y positions.
  const toastBgs = rec.calls
    .filter((c) => c.kind === "rect" && c.args[4] === ctx.MC.Pal.Black && c.args[1] <= 30)
    .map((c) => c.args[1]);
  assert.ok(toastBgs.includes(2), "expected first toast at y=2");
  assert.ok(toastBgs.some((y) => y > 2 && y <= 30), "expected second toast below the first");

  const redX = rec.calls.find((c) => c.kind === "print" && c.args[0] === "X" && c.args[3] === ctx.MC.Pal.Red);
  assert.ok(redX, "expected red X for error toast");
});

