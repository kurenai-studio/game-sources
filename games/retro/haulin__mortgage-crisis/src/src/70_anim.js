// MC.anim: UI-owned animation plumbing (turn events into timed, input-locking “watch moments”).
// This module owns view.anim queue/steps, but still manipulates UI view state
// (mode/menu/targeting) because animations are a UI-owned “watch” moment.

MC.anim.onEvents = function (state, view, events) {
  if (!state || !view || !events || events.length === 0) return;
  var anim = view.anim;

  // Clear overlays: animations are a read-only “watch” moment.
  if (view.mode !== "prompt") view.mode = "browse";
  if (view.menu) view.menu.items = [];
  if (view.targeting) view.targeting.active = false;

  var uiCfg = MC.config.ui;
  var animSpeedMult = uiCfg.animSpeedMult;
  var dealFrames = Math.floor(uiCfg.dealFramesPerCard * animSpeedMult);
  var dealGap = Math.floor(uiCfg.dealGapFrames * animSpeedMult);
  var xferFrames = Math.floor(uiCfg.xferFramesPerCard * animSpeedMult);
  var xferGap = Math.floor(uiCfg.xferGapFrames * animSpeedMult);
  var xferHoldFromFrames = Math.floor(uiCfg.xferHoldFromFrames * animSpeedMult);
  var xferHoldFrames = Math.floor(uiCfg.xferHoldFrames * animSpeedMult);
  var shuffleFrames = Math.floor(uiCfg.shuffleAnimFrames * animSpeedMult);
  var shuffleToastFrames = Math.floor(uiCfg.shuffleToastFrames * animSpeedMult);
  if (shuffleFrames < shuffleToastFrames) shuffleFrames = shuffleToastFrames;

  var didPromptBufOutHold = false;

  function payBufAnchor() {
    var L = MC.config.render.layout;
    var rowCenter = MC.render.ROW_CENTER;
    return { x: L.centerPayBufX, y: L.rowY[rowCenter] + L.centerTopInsetY };
  }

  var i;
  for (i = 0; i < events.length; i++) {
    var ev = events[i];
    if (!ev || !ev.kind) continue;

    if (ev.kind === "reshuffle") {
      // Toast + simple deck animation; input locked until finished.
      MC.ui.toastPush(view, { id: "deck_shuffle", kind: "info", text: "Deck ran out. Shuffling", frames: shuffleToastFrames });
      anim.q.push({
        kind: "shuffle",
        t: 0,
        frames: shuffleFrames,
        // Visual masking: during shuffle, show deck as empty and discard as empty.
        // Conceptually the discard has already been consumed into the deck; we only animate the deck.
        deckNVis: 0,
        discardNVis: 0
      });
      continue;
    }

    if (ev.kind === "draw") {
      var p = ev.p;
      if (!(p === 0 || p === 1)) continue;
      var uids = ev.uids;
      if (uids.length === 0) continue;

      // Find the hand indices for these drawn uids (engine already moved them into hand).
      var hand = state.players[p].hand;
      var handIs = [];
      var j;
      for (j = 0; j < uids.length; j++) {
        var uid = uids[j];
        var k;
        var found = -1;
        for (k = 0; k < hand.length; k++) {
          if (hand[k] === uid) found = k;
        }
        handIs.push(found);
        if (found >= 0) anim.hiddenByP[p][uid] = true;
      }

      anim.q.push({
        kind: "deal",
        p: p,
        uids: uids.slice(),
        handIs: handIs,
        dealFrames: dealFrames,
        gapFrames: dealGap,
        i: 0,
        phase: "move",
        t: 0
      });
    }

    if (ev.kind === "move") {
      var uidM = ev.uid;
      var from = ev.from;
      var to = ev.to;
      if (!uidM || !from || !to) continue;
      var fz = String(from.zone || "");
      var tz = String(to.zone || "");
      var selectedByP = ev.selectedByP;

      var isPromptBufOut = (fz === "promptBuf");
      var isPromptBufIn = (tz === "promptBuf");
      var isSlySteal = (fz === "setProps" && tz === "recvProps");

      var animate = false;
      if (isPromptBufIn) {
        // payDebt selection into the buffer: animate only when AI chose it.
        animate = (selectedByP != null && selectedByP !== 0);
      } else if (isPromptBufOut) {
        if (tz === "bank") animate = true;
        else if (tz === "recvProps") animate = true;
      } else if (isSlySteal) {
        animate = true; // to.p may be 0 (visible) or 1 (invisible -> fly to buffer anchor)
      }
      if (!animate) continue;

      if (xferFrames < 1) xferFrames = 1;
      if (xferGap < 0) xferGap = 0;

      // Source position is taken from the last rendered snapshot when possible.
      var fromX = null, fromY = null;
      if (fz === "promptBuf") {
        var pb = payBufAnchor();
        fromX = pb.x;
        fromY = pb.y;
      } else if (anim.lastPosByUid && anim.lastPosByUid[uidM]) {
        fromX = anim.lastPosByUid[uidM].x;
        fromY = anim.lastPosByUid[uidM].y;
      } else {
        var pb2 = payBufAnchor();
        fromX = pb2.x;
        fromY = pb2.y;
      }

      // Source presentation hints (used for hold-at-source readability).
      var fromRow = MC.render.ROW_CENTER;
      var fromFlip180 = false;
      var fromStackKey = null;
      if (fz === "bank") {
        fromRow = (from.p === 0) ? MC.render.ROW_P_HAND : MC.render.ROW_OP_HAND;
        fromFlip180 = (fromRow === MC.render.ROW_OP_HAND);
        fromStackKey = "bank:p" + from.p + ":row" + fromRow;
      } else if (fz === "setProps" || fz === "setHouse") {
        fromRow = (from.p === 0) ? MC.render.ROW_P_TABLE : MC.render.ROW_OP_TABLE;
        fromFlip180 = (fromRow === MC.render.ROW_OP_TABLE);
        fromStackKey = "set:p" + from.p + ":set" + from.setI;
      } else if (fz === "recvProps") {
        fromRow = (from.p === 0) ? MC.render.ROW_P_HAND : MC.render.ROW_OP_HAND;
        fromFlip180 = (fromRow === MC.render.ROW_OP_HAND);
        fromStackKey = "recvProps:p" + from.p + ":row" + fromRow;
      } else if (fz === "hand") {
        fromRow = (from.p === 0) ? MC.render.ROW_P_HAND : MC.render.ROW_OP_HAND;
        fromFlip180 = (fromRow === MC.render.ROW_OP_HAND);
      }

      // Hide the moved card until it “lands” (presentation-only).
      anim.hiddenByUid[uidM] = true;

      // Keep the pay/transfer buffer visible while promptBuf-sourced transfers drain out.
      if (isPromptBufOut) {
        anim.payBufUids.push(uidM);
      }

      var holdFrom = 0;
      if (selectedByP != null && selectedByP !== 0 && fz !== "promptBuf") holdFrom = xferHoldFromFrames;

      // After the final payDebt selection, promptBuf can drain immediately; insert a short hold
      // before the first promptBuf->dest transfer so the player can register the full buffer.
      if (isPromptBufOut && !didPromptBufOutHold && xferHoldFrames > 0) {
        anim.q.push({ kind: "xferHold", t: 0, frames: xferHoldFrames });
        didPromptBufOutHold = true;
      }

      anim.q.push({
        kind: "xfer",
        uid: uidM,
        fromX: fromX,
        fromY: fromY,
        fromRow: fromRow,
        fromFlip180: fromFlip180,
        fromStackKey: fromStackKey,
        to: {
          p: (to.p != null) ? to.p : 0,
          zone: tz,
          setI: (to.setI != null) ? to.setI : null,
          i: (to.i != null) ? to.i : null
        },
        fromPromptBuf: !!isPromptBufOut,
        t: 0,
        holdFromFrames: holdFrom,
        frames: xferFrames,
        gapFrames: xferGap,
        phase: (holdFrom > 0) ? "holdFrom" : "move"
      });
    }
  }

  // Start immediately if idle so the very first queued step can be presented this frame.
  // (MC.ui.step ticks anim before commands apply; without this, new anims would start 1 frame later.)
  if (!anim.active && anim.q && anim.q.length > 0) {
    anim.active = anim.q.shift();
  }

  anim.lock = !!(anim.active || (anim.q && anim.q.length));
};

// Game-start animation orchestration.
// Default newGame mutates directly into the final 5/7 start state; this function hides cards
// and schedules synthetic draw events to make the start readable.
MC.anim.beginGameStart = function (state, view) {
  if (!state || !view || !view.anim) return false;
  var anim = view.anim;
  if (!state.players || !state.players[0] || !state.players[1]) return false;
  var h0 = state.players[0].hand ? state.players[0].hand.length : 0;
  var h1 = state.players[1].hand ? state.players[1].hand.length : 0;
  var starterP = state.activeP;
  if (!(starterP === 0 || starterP === 1)) return false;

  // Only arm for the canonical default start shape (avoid surprising animations in scenarios).
  if (!((h0 === 7 && h1 === 5) || (h0 === 5 && h1 === 7))) return false;

  // Clear any prior anim state.
  anim.q = [];
  anim.active = null;
  anim.lock = false;
  anim.hiddenByP = [{}, {}];
  anim.hiddenByUid = {};
  anim.payBufUids = [];
  if (anim.lastPosByUid) {
    var kPos;
    for (kPos in anim.lastPosByUid) delete anim.lastPosByUid[kPos];
  }

  // Initial 5-card deal per player (starter has 2 extra cards appended).
  var deal0 = state.players[0].hand.slice(0, 5);
  var deal1 = state.players[1].hand.slice(0, 5);

  // Starter's draw-2 cards are the last 2 in their hand.
  var handS = state.players[starterP].hand;
  var draw2 = [];
  if (handS && handS.length >= 7) {
    draw2 = [handS[handS.length - 2], handS[handS.length - 1]];
  }

  // Hide the starter's draw-2 until after the initial deal + toast.
  var i;
  for (i = 0; i < draw2.length; i++) {
    var uidD = draw2[i];
    if (uidD) anim.hiddenByP[starterP][uidD] = true;
  }

  // Schedule initial deal as synthetic draws.
  MC.anim.onEvents(state, view, [
    { kind: "draw", p: 0, uids: deal0 },
    { kind: "draw", p: 1, uids: deal1 }
  ]);

  // Then show toast + deal the starter's draw-2.
  var hold = Math.floor(MC.config.ui.gameStartToastFrames * MC.config.ui.animSpeedMult);
  if (!(hold > 0)) hold = 1;
  anim.q.push({
    kind: "gameStart",
    starterP: starterP,
    drawUids: draw2.slice(),
    didToast: false,
    t: 0,
    frames: hold
  });

  anim.lock = true;
  return true;
};

MC.anim.tick = function (state, view) {
  if (!view) return;
  var anim = view.anim;

  // Tick non-locking FX (independent of the main anim queue).
  MC.anim.tickGameOverFx(state, view);

  // Start next step if idle.
  if (!anim.active && anim.q && anim.q.length > 0) {
    anim.active = anim.q.shift();
  }

  var a = anim.active;
  if (!a) {
    anim.lock = false;
    return;
  }

  if (a.kind === "shuffle") {
    a.t += 1;
    if (a.t >= a.frames) anim.active = null;
    anim.lock = !!(anim.active || (anim.q && anim.q.length));
    return;
  }

  if (a.kind === "gameStart") {
    if (!a.didToast) {
      var starterP = a.starterP;
      var txt = (starterP === 0) ? "You start" : "AI starts";
      MC.ui.toastPush(view, { id: "game_start", kind: "info", text: txt, frames: Math.floor(MC.config.ui.gameStartToastFrames * MC.config.ui.animSpeedMult) });
      a.didToast = true;
    }

    a.t += 1;
    if (a.t >= a.frames) {
      var starterP2 = a.starterP;
      var uids2 = a.drawUids;
      if (uids2 && uids2.length > 0) {
        MC.anim.onEvents(state, view, [{ kind: "draw", p: starterP2, uids: uids2.slice() }]);
      }
      anim.active = null;
    }

    anim.lock = !!(anim.active || (anim.q && anim.q.length));
    return;
  }

  if (a.kind === "xferHold") {
    a.t += 1;
    if (a.t >= a.frames) anim.active = null;
    anim.lock = !!(anim.active || (anim.q && anim.q.length));
    return;
  }

  if (a.kind === "xfer") {
    var uidX = a.uid;
    if (!uidX) { anim.active = null; anim.lock = !!(anim.q && anim.q.length); return; }

    // Keep the moved uid hidden from its state location for the full duration of the step.
    // (Important for multi-step chains where the same uid flies into promptBuf, then out.)
    if (a.phase !== "gap") anim.hiddenByUid[uidX] = true;

    a.t += 1;
    if (a.phase === "holdFrom") {
      if (a.t >= a.holdFromFrames) {
        a.phase = "move";
        a.t = 0;
      }
    } else if (a.phase === "move") {
      if (a.t >= a.frames) {
        // Reveal at destination (but promptBuf is not a rendered zone; buffer is drawn separately).
        var tzX = String(a.to.zone || "");
        if (tzX !== "promptBuf") delete anim.hiddenByUid[uidX];
        if (a.fromPromptBuf) {
          var bi = anim.payBufUids.indexOf(uidX);
          if (bi >= 0) anim.payBufUids.splice(bi, 1);
        }

        a.t = 0;
        if (a.gapFrames > 0) {
          a.phase = "gap";
        } else {
          anim.active = null;
        }
      }
    } else {
      // gap
      if (a.t >= a.gapFrames) {
        anim.active = null;
      }
    }

    anim.lock = !!(anim.active || (anim.q && anim.q.length));
    return;
  }

  if (a.kind === "deal") {
    var p = a.p;
    var uids = a.uids;
    if (uids.length === 0) { anim.active = null; anim.lock = !!(anim.q && anim.q.length); return; }

    if (a.i >= uids.length) { anim.active = null; anim.lock = !!(anim.q && anim.q.length); return; }

    a.t += 1;
    if (a.phase === "move") {
      if (a.t >= a.dealFrames) {
        // Reveal current card.
        var uid = uids[a.i];
        delete anim.hiddenByP[p][uid];
        a.i += 1;
        a.t = 0;
        if (a.i >= uids.length) {
          anim.active = null;
        } else {
          a.phase = "gap";
        }
      }
    } else {
      // gap
      if (a.t >= a.gapFrames) {
        a.phase = "move";
        a.t = 0;
      }
    }

    anim.lock = !!(anim.active || (anim.q && anim.q.length));
    return;
  }

  // Unknown anim kind: drop it.
  anim.active = null;
  anim.lock = !!(anim.q && anim.q.length);
};

// Treat cursor-flash feedback as an animation/fx owned here.
MC.anim.feedbackError = function (view, code, msg) {
  if (!view || !view.feedback) return;
  code = String(code || "error");
  msg = String(msg || "");

  var fb = view.feedback;
  fb.lastCode = code;

  // Focus policy can optionally respond to the *next* idle tick after an invalid action.
  // Keep the first error until consumed so repeated blinks don't overwrite the trigger.
  if (view.ux && !view.ux.pendingFocusErrorCode) view.ux.pendingFocusErrorCode = code;
  var attempts = fb.attemptsByCode[code] || 0;
  attempts += 1;
  fb.attemptsByCode[code] = attempts;

  // Always blink; only show message on repeated attempts.
  fb.blinkFrames = 18;
  fb.blinkPhase = 0;

  if (attempts >= 2 && msg) {
    // Toast UI lives in MC.ui; this just triggers it as part of the feedback FX.
    MC.ui.toastPush(view, { id: "err:" + code, kind: "error", text: msg, frames: MC.config.ui.toast.errorFrames });
  }
};

MC.anim.feedbackTick = function (view) {
  if (!view || !view.feedback) return;
  var fb = view.feedback;

  var blinkFrames = fb.blinkFrames;
  if (blinkFrames > 0) {
    blinkFrames = blinkFrames - 1;
    fb.blinkFrames = blinkFrames;
    // 2 blinks: toggle every 3 frames.
    fb.blinkPhase = Math.floor(blinkFrames / 3);
  } else {
    fb.blinkFrames = 0;
    fb.blinkPhase = 0;
    fb.lastCode = "";
    if (view.ux) view.ux.pendingFocusErrorCode = "";
  }
};

// Presentation (render-facing view of state/models).
// Renderer should not depend on `view.anim`; instead, UI calls this after building models.
MC.anim.present = function (state, view, computed) {
  if (!state || !view || !computed || !computed.models) return computed;
  var anim = view.anim;
  var a = anim ? anim.active : null;

  // Reset any prior overlay presentation (computed is rebuilt each call, but be explicit).
  computed.animOverlay = null;
  computed.gameOverFx = null;
  if (anim && anim.gameOverFx) computed.gameOverFx = anim.gameOverFx;

  // Provide highlight color for render (cursor flash on disallowed actions).
  // Default highlight color lives in render config.
  var colDefault = MC.config.render.style.colHighlight;
  var hl = colDefault;
  if (view.feedback && view.feedback.blinkFrames > 0) {
    if ((view.feedback.blinkPhase % 2) === 0) hl = MC.Pal.Red;
  }
  computed.highlightCol = hl;

  // Hide in-flight dealt cards until revealed (presentation-only).
  if (anim && anim.hiddenByP) {
    var rowPH = MC.render.ROW_P_HAND;
    var rowOH = MC.render.ROW_OP_HAND;
    var rows = [rowOH, rowPH];
    var ri;
    for (ri = 0; ri < rows.length; ri++) {
      var row = rows[ri];
      var rm = computed.models[row];
      if (!rm || !rm.items) continue;
      var p = (row === rowPH) ? 0 : 1;
      var hidden = anim.hiddenByP[p];
      if (!hidden) continue;
      var out = [];
      var i;
      for (i = 0; i < rm.items.length; i++) {
        var it0 = rm.items[i];
        if (!it0 || it0.kind !== "hand") { out.push(it0); continue; }
        var uid0 = it0.uid;
        if (hidden[uid0]) continue;
        out.push(it0);
      }
      rm.items = out;

      // If the cursor is on this row, recompute selection from the filtered items so
      // hidden cards can't be revealed via the selection redraw path in the renderer.
      if (view.cursor && view.cursor.row === row) {
        if (rm.items.length === 0) computed.selected = null;
        else {
          var ci = MC.ui.clampI(view.cursor.i, rm.items.length);
          computed.selected = rm.items[ci];
        }
      }
    }
  }

  // Hide in-flight transfer cards until they “land” (presentation-only).
  if (anim && anim.hiddenByUid) {
    var hidU = anim.hiddenByUid;
    var rowH;
    for (rowH = 0; rowH < computed.models.length; rowH++) {
      var rmH = computed.models[rowH];
      if (!rmH || !rmH.items) continue;
      var outH = [];
      var ii;
      for (ii = 0; ii < rmH.items.length; ii++) {
        var itH = rmH.items[ii];
        if (!itH || !itH.uid) { outH.push(itH); continue; }
        if (hidU[itH.uid]) continue;
        outH.push(itH);
      }
      rmH.items = outH;

      // If the cursor is on this row, recompute selection from the filtered items so
      // hidden cards can't be revealed via the selection redraw path in the renderer.
      if (view.cursor && view.cursor.row === rowH) {
        if (rmH.items.length === 0) computed.selected = null;
        else {
          var ci2 = MC.ui.clampI(view.cursor.i, rmH.items.length);
          computed.selected = rmH.items[ci2];
        }
      } else if (computed.selected && computed.selected.uid && hidU[computed.selected.uid]) {
        computed.selected = null;
      }
    }
  }

  // Avoid duplicating in-flight cards in the center buffer stack.
  // - promptBuf->dest: remove the leaving card from the stack during flight
  // - src->promptBuf (AI selection): don't show the card in the stack until its flight lands
  var hidePayBufByUid = {};
  var hidePayBufAny = false;
  function hidePayBuf(uid) {
    if (!uid) return;
    hidePayBufByUid[uid] = true;
    hidePayBufAny = true;
  }

  if (a && a.kind === "xfer" && a.uid && a.phase !== "gap") {
    if (a.fromPromptBuf) hidePayBuf(a.uid);
    var tzH = (a.to && a.to.zone) ? String(a.to.zone) : "";
    if (tzH === "promptBuf") hidePayBuf(a.uid);
  }

  if (anim && anim.q && anim.q.length) {
    var qi;
    for (qi = 0; qi < anim.q.length; qi++) {
      var qit = anim.q[qi];
      if (!qit || qit.kind !== "xfer" || !qit.uid || qit.phase === "gap") continue;
      var tzQ = (qit.to && qit.to.zone) ? String(qit.to.zone) : "";
      if (tzQ === "promptBuf") hidePayBuf(qit.uid);
    }
  }

  if (hidePayBufAny) {
    var rowCenterPB = MC.render.ROW_CENTER;
    var rmPB = computed.models[rowCenterPB];
    if (rmPB && rmPB.overlayItems) {
      var oiPB;
      for (oiPB = 0; oiPB < rmPB.overlayItems.length; oiPB++) {
        var ovPB = rmPB.overlayItems[oiPB];
        if (!ovPB || ovPB.kind !== "payBuf" || !ovPB.uids) continue;
        var uOutPB = [];
        var uiPB;
        for (uiPB = 0; uiPB < ovPB.uids.length; uiPB++) {
          var uidPB = ovPB.uids[uiPB];
          if (!uidPB) continue;
          if (hidePayBufByUid[uidPB]) continue;
          uOutPB.push(uidPB);
        }
        ovPB.uids = uOutPB;
        ovPB.nVis = uOutPB.length;
      }
    }
  }

  if (!a || !a.kind) return computed;

  // When AI selects a payment card (xfer-to-promptBuf), keep the source
  // stack visually stable during the hold-at-source so it doesn't collapse under the highlight.
  if (a.kind === "xfer" && a.phase === "holdFrom" && String(a.to.zone || "") === "promptBuf") {
    var rowF = a.fromRow;
    var stKeyF = a.fromStackKey;
    if (stKeyF && anim && anim.lastPosByUid && computed.models[rowF] && computed.models[rowF].items) {
      var rmF = computed.models[rowF];
      var camF = (view.camX && view.camX[rowF] != null) ? view.camX[rowF] : 0;
      var Lf = MC.config.render.layout;

      var iF;
      for (iF = 0; iF < rmF.items.length; iF++) {
        var itF = rmF.items[iF];
        if (!itF || !itF.uid || !itF.stackKey) continue;
        if (String(itF.stackKey) !== String(stKeyF)) continue;
        var posF = anim.lastPosByUid[itF.uid];
        if (!posF) continue;
        itF.x = posF.x + camF;
        itF.y = posF.y;
      }

      // Recompute bounds to keep camera stable while frozen.
      var minXF = 999999, maxXF = -999999;
      for (iF = 0; iF < rmF.items.length; iF++) {
        var itB = rmF.items[iF];
        if (!itB || itB.x == null || itB.w == null) continue;
        var xFaceB = itB.x;
        var xLoB = xFaceB;
        var xHiB = xFaceB + itB.w - 1;
        var kindB = String(itB.kind || "");
        var fanB = (itB.fanDir != null) ? itB.fanDir : 0;
        if (kindB === "hand") {
          xLoB = xFaceB + Lf.shadowBarDx;
        } else if (kindB === "bank" || kindB === "setProp" || kindB === "setHouse") {
          if (fanB < 0) xHiB = xFaceB + itB.w;
          else xLoB = xFaceB + Lf.shadowBarDx;
        }
        if (xLoB < minXF) minXF = xLoB;
        if (xHiB > maxXF) maxXF = xHiB;
      }
      rmF.minX = (minXF === 999999) ? 0 : minXF;
      rmF.maxX = (maxXF === -999999) ? 0 : maxXF;
    }
  }

  var rowCenter = MC.render.ROW_CENTER;
  var rmC = computed.models[rowCenter];

  if (a.kind === "shuffle") {
    // Drive deck/discard pile presentation via model item hints.
    if (rmC && rmC.items) {
      var i;
      for (i = 0; i < rmC.items.length; i++) {
        var it = rmC.items[i];
        if (!it || !it.kind) continue;
        if (it.kind === "deck") {
          it.nVis = (a.deckNVis != null) ? a.deckNVis : null;
          // Cycle 0/1/2 underlayers to suggest shuffling.
          var phase = a.t % 12;
          var layers = 0;
          if (phase >= 4 && phase < 8) layers = 1;
          else if (phase >= 8) layers = 2;
          it.pileLayers = layers;
        } else if (it.kind === "discard") {
          // Discard is conceptually consumed at reshuffle time.
          it.nVis = 0;
          it.topUidVis = 0;
        }
      }
    }
    return computed;
  }

  if (a.kind === "deal") {
    if (a.phase !== "move") return computed;
    var p = a.p;
    var uids = a.uids;
    var handIs = a.handIs;
    var iCard = a.i;
    if (iCard < 0 || iCard >= uids.length) return computed;

    var frames = a.dealFrames;
    if (frames < 1) frames = 1;
    var t = a.t;
    if (t < 0) t = 0;
    if (t > frames) t = frames;
    var u = t / frames;

    // Find deck position from computed center-row model.
    var deckX = null, deckY = null;
    if (rmC && rmC.items) {
      var j;
      for (j = 0; j < rmC.items.length; j++) {
        var it2 = rmC.items[j];
        if (it2 && it2.kind === "deck") { deckX = it2.x; deckY = it2.y; break; }
      }
    }
    if (deckX == null || deckY == null) return computed;

    var rowHand = (p === 0) ? MC.render.ROW_P_HAND : MC.render.ROW_OP_HAND;

    var camCenter = view.camX[rowCenter];
    var camH = view.camX[rowHand];

    var L = MC.config.render.layout;
    var padX = L.rowPadX;
    var xHandStart = (p === 0) ? padX : (L.screenW - padX - L.faceW);
    var handStep = (p === 0) ? L.handStrideX : (-L.handStrideX);
    var handI = handIs[iCard];
    if (handI < 0) return computed;

    var xToW = xHandStart + handI * handStep;
    var yToW = L.rowY[rowHand] + 1;

    // Screen-space endpoints (camera-adjusted).
    var xFromS = (deckX - camCenter);
    var yFromS = deckY;
    var xToS = (xToW - camH);
    var yToS = yToW;

    var x = Math.floor(xFromS + (xToS - xFromS) * u);
    var y = Math.floor(yFromS + (yToS - yFromS) * u);

    computed.animOverlay = {
      kind: "dealCard",
      x: x,
      y: y,
      p: p,
      uid: uids[iCard]
    };
    return computed;
  }

  if (a.kind === "xfer") {
    if (a.phase === "gap") return computed;
    var framesX = a.frames;
    if (framesX < 1) framesX = 1;
    var uX = 0;
    if (a.phase === "move") {
      var tX = a.t;
      if (tX < 0) tX = 0;
      if (tX > framesX) tX = framesX;
      uX = tX / framesX;
    }

    function payBufAnchor() {
      var Lp = MC.config.render.layout;
      var rowC = MC.render.ROW_CENTER;
      return { x: Lp.centerPayBufX, y: Lp.rowY[rowC] + Lp.centerTopInsetY, flip180: false };
    }

    function screenPosForLoc(loc) {
      if (!loc) return null;
      var p = loc.p;
      var z = String(loc.zone || "");
      var L = MC.config.render.layout;

      // Prompt buffer and AI received props are not rendered; use the center buffer anchor.
      if (z === "promptBuf") return payBufAnchor();
      if (z === "recvProps" && p === 1) {
        var rowHandO = MC.render.ROW_OP_HAND;
        var camO = (view.camX && view.camX[rowHandO] != null) ? view.camX[rowHandO] : 0;
        var idxO = (loc.i != null) ? loc.i : 0;
        var xWO = (L.screenW - L.rowPadX - L.faceW) - idxO * L.handStrideX;
        var yWO = MC.layout.faceYForRow(rowHandO);
        return { x: xWO - camO, y: yWO, flip180: true };
      }

      if (z === "recvProps" && p === 0) {
        var rowHand = MC.render.ROW_P_HAND;
        var camH = (view.camX && view.camX[rowHand] != null) ? view.camX[rowHand] : 0;
        var idxR = (loc.i != null) ? loc.i : 0;
        var xW = L.rowPadX + idxR * L.handStrideX;
        var yW = MC.layout.faceYForRow(rowHand);
        return { x: xW - camH, y: yW, flip180: false };
      }

      if (z === "bank") {
        var rowB = (p === 0) ? MC.render.ROW_P_HAND : MC.render.ROW_OP_HAND;
        var rmB = computed.models[rowB];
        var stKeyB = "bank:p" + p + ":row" + rowB;
        var stB = (rmB && rmB.stacks) ? rmB.stacks[stKeyB] : null;
        if (!stB) return null;
        var camB = (view.camX && view.camX[rowB] != null) ? view.camX[rowB] : 0;
        var depthB = (loc.i != null) ? loc.i : 0;
        var xBW = stB.x0 + depthB * stB.stride * stB.fanDir;
        return { x: xBW - camB, y: stB.y, flip180: (rowB === MC.render.ROW_OP_HAND) };
      }

      if (z === "setProps") {
        var rowT = (p === 0) ? MC.render.ROW_P_TABLE : MC.render.ROW_OP_TABLE;
        var rmT = computed.models[rowT];
        var stKeyT = "set:p" + p + ":set" + loc.setI;
        var stT = (rmT && rmT.stacks) ? rmT.stacks[stKeyT] : null;
        if (!stT) return null;
        var camT = (view.camX && view.camX[rowT] != null) ? view.camX[rowT] : 0;
        var depthT = (loc.i != null) ? loc.i : 0;
        var xTW = stT.x0 + depthT * stT.stride * stT.fanDir;
        return { x: xTW - camT, y: stT.y, flip180: (rowT === MC.render.ROW_OP_TABLE) };
      }

      return null;
    }

    var toPos = screenPosForLoc(a.to);
    if (!toPos) return computed;

    var xFromS = a.fromX;
    var yFromS = a.fromY;
    var xToS = toPos.x;
    var yToS = toPos.y;

    var xX = Math.floor(xFromS + (xToS - xFromS) * uX);
    var yX = Math.floor(yFromS + (yToS - yFromS) * uX);

    computed.animOverlay = {
      kind: "moveCard",
      x: xX,
      y: yX,
      uid: a.uid,
      flip180: !!((a.phase === "holdFrom" || (a.phase === "move" && a.t === 0)) ? a.fromFlip180 : toPos.flip180),
      outlinePal: (a.phase === "holdFrom") ? MC.Pal.Green : null
    };
    return computed;
  }

  return computed;
};

// Game-over FX (non-locking): “golden rain” sparks behind the winner toast.
MC.anim._fxRespawnGameOverParticle = function (fx, p) {
  var W = MC.config.screenW;

  // Particle size: {2,3}×{1,2,3}
  p.w = (fx.rng.nextInt(10) < 3) ? 3 : 2;
  var rh = fx.rng.nextInt(10);
  if (rh <= 2) p.h = 1;
  else if (rh <= 7) p.h = 2;
  else p.h = 3;

  var maxX = W - p.w;
  p.x = fx.rng.nextInt(maxX + 1);

  // Spawn just above the viewport; delay staggers entry.
  // Keep the tail short so the effect can finish naturally without an abrupt cut.
  p.y = -1 - fx.rng.nextInt(24);
  p.delay = fx.rng.nextInt(120);

  // Base fall speed (weighted): 2-3 most common, with a few slower/faster.
  var rv = fx.rng.nextInt(10);
  if (rv === 0) p.vy = 1;
  else if (rv <= 4) p.vy = 2;
  else if (rv <= 8) p.vy = 3;
  else p.vy = 4;

  // Cohesive palette by winner (white is reserved for glisten).
  if (fx.winnerP === 0) {
    p.col = (fx.rng.nextInt(10) < 8) ? MC.Pal.Yellow : MC.Pal.Orange;
  } else {
    p.col = (fx.rng.nextInt(10) < 7) ? MC.Pal.Blue : MC.Pal.Purple;
  }

  p.flash = 0;
  p.done = false;
};

MC.anim.beginGameOverFx = function (state, view) {
  if (!state || !view || !view.anim) return false;
  var anim = view.anim;
  var winnerP = state.winnerP;
  if (winnerP === MC.state.NO_WINNER) { anim.gameOverFx = null; return false; }

  // Only arm once per game-over entry (don’t re-arm during animation locks).
  var ex = anim.gameOverFx;
  if (ex && ex.winnerP === winnerP) return false;

  var nParts = Math.floor(MC.config.ui.gameOverFxParticles);

  // Derive an effect RNG seed from the state RNG + winner to make it stable/replayable.
  var seed = state.rngS + 1337 + winnerP * 99991 + Math.floor(tstamp());

  var fx = {
    winnerP: winnerP,
    rng: new MC.rng.RNG(seed),
    parts: []
  };

  var i;
  for (i = 0; i < nParts; i++) {
    var p = { x: 0, y: 0, vy: 2, delay: 0, w: 2, h: 2, col: MC.Pal.Yellow, flash: 0, done: false };
    MC.anim._fxRespawnGameOverParticle(fx, p);
    fx.parts.push(p);
  }

  anim.gameOverFx = fx;
  return true;
};

MC.anim.tickGameOverFx = function (state, view) {
  if (!view || !view.anim) return;
  var anim = view.anim;
  var fx = anim.gameOverFx;
  if (!fx) return;

  // If game-over cleared (e.g., reset) but view persisted, drop the FX.
  if (!state || state.winnerP === MC.state.NO_WINNER) { anim.gameOverFx = null; return; }
  if (fx.winnerP !== state.winnerP) { anim.gameOverFx = null; return; }

  var W = MC.config.screenW;
  var H = MC.config.screenH;

  var parts = fx.parts;
  if (!parts || parts.length === 0) return;

  var remaining = 0;
  var i;
  for (i = 0; i < parts.length; i++) {
    var p = parts[i];
    if (!p) continue;
    if (p.done) continue;

    if (p.delay > 0) { p.delay -= 1; remaining += 1; continue; }

    // Glisten: more frequent + longer, as a shimmer band in render (not full white blocks).
    if (p.flash > 0) {
      p.flash -= 1;
    } else {
      var kFlash = MC.config.ui.gameOverFxFlashChance1In;
      var fFlash = MC.config.ui.gameOverFxFlashFrames;
      if (fx.rng.nextInt(kFlash) === 0) {
        p.flash = fFlash;
      }
    }

    // Random horizontal nudge (rare; avoids constant diagonal drift).
    var kNudge = MC.config.ui.gameOverFxNudgeChance1In;
    if (fx.rng.nextInt(kNudge) === 0) {
      p.x += (fx.rng.nextInt(2) === 0) ? -1 : 1;
    }

    // Fall.
    var vy = p.vy;
    // Occasional small jitter so the fall doesn't read as uniform.
    var rJ = fx.rng.nextInt(12);
    if (rJ === 0) vy += 2;
    else if (rJ <= 2) vy += 1;
    else if (rJ === 3 && vy > 1) vy -= 1;
    if (vy < 1) vy = 1;
    if (vy > 6) vy = 6;
    p.y += vy;

    // Wrap X, respawn on Y out-of-bounds.
    var maxX = W - p.w;
    if (p.x < 0) p.x = maxX;
    else if (p.x > maxX) p.x = 0;

    if (p.y > H + 2) { p.done = true; continue; }
    remaining += 1;
  }

  // Natural finish: stop once everything has drained.
  if (remaining === 0) anim.gameOverFx = null;
};

