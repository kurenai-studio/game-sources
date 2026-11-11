// MC.ui: controller UX view-state machine + model computation (drives commands; does not author rules).
MC.ui.newView = function () {
  return {
    // View-only state (cursor/camera/menu focus). This is intentionally not part of GameState.
    cursor: { row: 4, i: 0 }, // default to player hand
    camX: [0, 0, 0, 0, 0],

    // browse | menu | targeting | prompt
    mode: "browse",

    // Menu (center panel)
    menu: {
      items: [],
      i: 0,
      // Source selection snapshot when menu opened.
      src: null
    },

    // Targeting (Place/Build via hold or via menu)
    targeting: {
      active: false,
      // kind: "place" | "build" | "bank"
      kind: "",
      // true if entered from A-hold (confirm on A release)
      hold: false,
      // "controller" | "mouseClick" | "mouseDrag"
      hintMode: "controller",
      // source: { uid, loc }
      card: null,
      // for wilds
      wildColor: MC.state.NO_COLOR,
      // list of concrete engine commands (subset of MC.engine.legalMoves)
      cmds: [],
      cmdI: 0,

      // Hold-A chain: compose multiple targeting kinds (e.g. Sly→Bank→Source)
      // so cursor-mode targeting doesn't have to impersonate preview-mode destinations.
      chainActive: false,
      chainSegs: [],
      chainI: 0,
      // Cursor location to snap back to when entering non-cursor segments (bank/source).
      srcCursor: { row: 4, i: 0 },

      // Mouse targeting (hover + drag-and-drop).
      // When dragMode is true, releasing without a snap cancels instead of confirming a default.
      mouse: { active: false, dragMode: false, dragging: false, x: 0, y: 0, snapped: false, leftSource: false }
    },

    // Inspect (hold X with delay)
    inspectActive: false,

    // Toasts: stacked notifications at screen top.
    // Each toast: { id?, kind?, text, frames?, persistent? }
    toasts: [],

    // Animations: shuffle + staged dealing. Purely view-owned.
    anim: {
      q: [],
      active: null,
      lock: false,
      // hiddenByP[p][uid] = true means uid is in-hand but not yet revealed.
      hiddenByP: [{}, {}],
      // Hide cards that are mid-transfer (any zone, any player).
      hiddenByUid: {},
      // Last seen screen-space face origins by uid (for transfer animations).
      lastPosByUid: {},
      // Visual list of cards in the pay/transfer buffer stack (center row).
      // Used to keep the buffer visible while promptBuf-sourced transfers drain after the prompt clears.
      payBufUids: [],

      // Game-over presentation FX state (owned by MC.anim; purely visual).
      gameOverFx: null
    },

    // Feedback: blink + message, plus attempt counts.
    feedback: {
      blinkFrames: 0,
      blinkPhase: 0,
      lastCode: "",
      attemptsByCode: {}
    },

    // Small UX memory (used for one-shot nudges like snapping to End when out of plays).
    ux: {
      lastActiveP: null,
      lastPlaysLeft: null,
      lastHandLenP0: null,
      lastWinnerP: MC.state.NO_WINNER,
      lastPromptKind: "",
      lastPromptForP0: false,
      lastFocusRuleId: "",
      pendingFocusErrorCode: "",
      autoFocusPausedByDebug: false,
      autoFocusPausedByMouse: false,
      selAnchor: null
    }
  };
};

MC.ui.toastPush = function (view, toast) {
  var t = {
    id: toast.id,
    kind: toast.kind,
    text: toast.text,
    frames: toast.frames,
    persistent: toast.persistent
  };

  // Replace-by-id if provided.
  var i;
  for (i = 0; i < view.toasts.length; i++) {
    var ex = view.toasts[i];
    if (ex && ex.id === t.id) { view.toasts[i] = t; return; }
  }
  view.toasts.push(t);
};

MC.ui.feedbackNoMovesLeft = function (state, view) {
  MC.anim.feedbackError(view, "no_actions", "No moves left");
};

MC.ui.findSourceCmdI = function (cmds) {
  var i;
  for (i = 0; i < cmds.length; i++) if (cmds[i] && cmds[i].kind === "source") return i;
  return 0;
};

MC.ui.kindAllowsAutoApply = function (kind, def) {
  kind = String(kind || "");
  // Wild Place always implies a follow-up choice (color), even when exactly one real destination exists.
  if (kind === "place" && def && MC.rules.isWildDef(def)) return false;
  return true;
};

MC.ui.menuLabelForKind = function (kind, baseLabel, def) {
  kind = String(kind || "");
  // Wild Place always leads to targeting (color choice).
  if (kind === "place" && def && MC.rules.isWildDef(def)) return "Place...";
  return String(baseLabel || "");
};

MC.ui.targetingResetCommon = function (state, view, hold, uid, loc) {
  if (!view || !view.targeting) return null;
  var t = view.targeting;
  t.active = true;
  t._profileSorted = false;
  t._profileSyncCmdI = -1;
  t.hold = !!hold;
  t.hintMode = "controller";
  t.cmds = [];
  t.cmdI = 0;
  t.wildColor = MC.state.NO_COLOR;
  t.srcCursor = { row: view.cursor ? view.cursor.row : 4, i: view.cursor ? view.cursor.i : 0 };
  MC.ui.mouse.resetTargeting(t);

  var def = MC.state.defByUid(state, uid);
  t.card = { uid: uid, loc: loc || null, def: def || null };
  return t;
};

MC.ui.targetingApplyProfileDefaultCmdI = function (state, t) {
  if (!t || !t.cmds || t.cmds.length === 0) return;
  var profD = MC.cmd.getProfile(t.kind);
  if (profD && typeof profD.defaultCmdI === "function") {
    var di = profD.defaultCmdI(state, t.cmds, t.card ? t.card.loc : null);
    if (di != null) t.cmdI = MC.ui.clampI(di, t.cmds.length);
  }
};

MC.ui.toastsTick = function (view) {
  var out = [];
  var i;
  for (i = 0; i < view.toasts.length; i++) {
    var t = view.toasts[i];
    if (t.persistent) { out.push(t); continue; }
    t.frames -= 1;
    if (t.frames > 0) out.push(t);
  }
  view.toasts = out;
};

MC.ui.syncPromptToast = function (state, view) {
  // Game over: hide prompt toast so Winner toast can take over.
  if (state && state.winnerP !== MC.state.NO_WINNER) {
    var iGo;
    for (iGo = 0; iGo < view.toasts.length; iGo++) {
      var tGo = view.toasts[iGo];
      if (tGo && tGo.id === "prompt") { view.toasts.splice(iGo, 1); break; }
    }
    return;
  }

  var pr = state.prompt;
  var has = !!(pr && pr.kind && pr.p === 0);
  var i;
  var idx = -1;
  for (i = 0; i < view.toasts.length; i++) {
    var t = view.toasts[i];
    if (t && t.id === "prompt") { idx = i; break; }
  }

  if (!has) {
    if (idx >= 0) view.toasts.splice(idx, 1);
    return;
  }

  var txt = "";
  if (pr.kind === "discardDown") {
    var over = state.players[0].hand.length - MC.state.HAND_MAX;
    txt = "Too many cards. Discard " + over;
  } else if (pr.kind === "payDebt") {
    // If action-sourced debt and JSN is available, teach the response window.
    var jsnAvail = !!(pr.srcAction && pr.buf && pr.buf.length === 0 && MC.rules.handHasActionKind(state, 0, MC.ActionKind.JustSayNo));
    if (jsnAvail && pr.srcAction && String(pr.srcAction.kind || "") === "rent") {
      txt = "Rent: Pay $" + pr.rem + " or Just Say No";
    } else if (jsnAvail) {
      txt = "Pay $" + pr.rem + " or Just Say No";
    } else {
      txt = "Pay debt: $" + pr.rem + " left";
    }
  } else if (pr.kind === "placeReceived") {
    txt = "Place received properties: " + pr.uids.length;
  } else if (pr.kind === "replaceWindow") {
    var useMouseRW = !!(view && view.ux && view.ux.autoFocusPausedByMouse);
    txt = useMouseRW ? "Move a Wild? Click:move  Right:skip" : "Move a Wild? A:move B:skip";
  } else if (pr.kind === "respondAction") {
    var col = MC.state.NO_COLOR;
    if (pr.target && pr.target.loc && pr.target.loc.zone === "setProps") {
      var tp = pr.target.loc.p;
      var setI = pr.target.loc.setI;
      var iP = pr.target.loc.i;
      var set = state.players[tp].sets[setI];
      if (set && set.props && set.props[iP]) col = set.props[iP][1];
    }
    txt = "Sly Deal: " + MC.fmt.colorName(col) + " or Just Say No";
  } else {
    txt = "Prompt: " + pr.kind;
  }

  var toast = { id: "prompt", kind: "prompt", text: txt, persistent: true };
  if (idx >= 0) {
    view.toasts[idx] = toast;
    // Keep prompt toast at the top.
    if (idx !== 0) {
      view.toasts.splice(idx, 1);
      view.toasts.unshift(toast);
    }
  } else {
    view.toasts.unshift(toast);
  }
};

MC.ui.syncWinnerToast = function (state, view) {
  if (!state || !view) return;
  var has = (state.winnerP !== MC.state.NO_WINNER);
  var i;
  var idx = -1;
  for (i = 0; i < view.toasts.length; i++) {
    var t = view.toasts[i];
    if (t && t.id === "winner") { idx = i; break; }
  }

  if (!has) {
    if (idx >= 0) view.toasts.splice(idx, 1);
    return;
  }

  var name = (state.winnerP === 0) ? "Player" : "Opponent";
  var toast = { id: "winner", kind: "info", text: "Winner: " + name, persistent: true };
  if (idx >= 0) {
    view.toasts[idx] = toast;
    if (idx !== 0) {
      view.toasts.splice(idx, 1);
      view.toasts.unshift(toast);
    }
  } else {
    view.toasts.unshift(toast);
  }
};

MC.ui.clampI = function (i, n) {
  if (n <= 0) return 0;
  if (i < 0) return 0;
  if (i >= n) return n - 1;
  return i;
};

MC.ui.itemMatchesUidLoc = function (it, uid, loc) {
  if (!it || !it.loc || !loc) return false;
  if (it.uid !== uid) return false;
  if (it.loc.p !== loc.p) return false;
  if (String(it.loc.zone) !== String(loc.zone)) return false;
  if ((it.loc.setI != null) && (loc.setI != null) && it.loc.setI !== loc.setI) return false;
  if ((it.loc.i != null) && (loc.i != null) && it.loc.i !== loc.i) return false;
  return true;
};

MC.ui.wrapI = function (i, n) {
  if (n <= 0) return 0;
  i = i % n;
  if (i < 0) i = i + n;
  return i;
};

// Pick the first item matching a predicate from the given row order.
// Returns { row, i, item } or null.
MC.ui.findBestCursorTarget = function (models, rowOrder, predicate) {
  if (!models) return null;
  rowOrder = rowOrder || [0, 1, 2, 3, 4];
  predicate = predicate || function () { return true; };

  var ri;
  for (ri = 0; ri < rowOrder.length; ri++) {
    var row = rowOrder[ri];
    if (row < 0 || row > 4) continue;

    var rm = models[row];
    if (!rm || !rm.items || rm.items.length === 0) continue;

    var i;
    for (i = 0; i < rm.items.length; i++) {
      var it = rm.items[i];
      if (!it) continue;
      if (!predicate(it)) continue;
      return { row: row, i: i, item: it };
    }
  }
  return null;
};

MC.ui.pickReplaceWindowWild = function (state, computed) {
  var pr = state ? state.prompt : null;
  if (!pr || String(pr.kind || "") !== "replaceWindow" || pr.p !== 0) return null;
  var models = computed ? computed.models : null;
  if (!models) return null;

  var srcSetI = pr.srcSetI;
  var excludeUid = pr.excludeUid;
  return MC.ui.findBestCursorTarget(models, [MC.render.ROW_P_TABLE], function (it) {
    if (!it || it.kind !== "setProp" || !it.loc) return false;
    if (it.loc.p !== 0) return false;
    if (it.loc.zone !== "setProps") return false;
    if (it.loc.setI !== srcSetI) return false;
    if (it.uid === excludeUid) return false;
    var def = MC.state.defByUid(state, it.uid);
    return !!(def && MC.rules.isWildDef(def));
  });
};

MC.ui.cursorMoveTo = function (view, pick) {
  if (!view || !view.cursor || !pick) return;
  view.cursor.row = pick.row;
  view.cursor.i = pick.i;
};

// Directional navigation: pick closest selectable in a direction,
// based on screen-space geometry (includes row camera offsets).

MC.ui.itemScreenCenter = function (view, item) {
  if (!item) return { cx: 0, cy: 0 };
  var row = item.row;
  var cam = view.camX[row];
  var x = item.x - cam;
  var y = item.y;
  var w = item.w;
  var h = item.h;
  return { cx: x + (w / 2), cy: y + (h / 2) };
};

MC.ui.itemScreenRect = function (view, item, pad) {
  if (!item || !view || !view.camX) return { x0: 0, y0: 0, x1: 0, y1: 0 };
  if (pad == null) pad = 0;
  var row = item.row;
  var cam = (view.camX[row] != null) ? view.camX[row] : 0;
  var x0 = ((item.x != null) ? item.x : 0) - cam - pad;
  var y0 = ((item.y != null) ? item.y : 0) - pad;
  var w = (item.w != null) ? item.w : 0;
  var h = (item.h != null) ? item.h : 0;
  return { x0: x0, y0: y0, x1: x0 + w - 1 + 2 * pad, y1: y0 + h - 1 + 2 * pad };
};

MC.ui.findItemByUidLoc = function (models, uid, loc) {
  if (!models || !uid || !loc) return null;
  var row;
  for (row = 0; row < models.length; row++) {
    var rm = models[row];
    if (!rm || !rm.items) continue;
    var i;
    for (i = 0; i < rm.items.length; i++) {
      var it = rm.items[i];
      if (!it || it.uid !== uid || !it.loc) continue;
      if (it.loc.p !== loc.p) continue;
      if (String(it.loc.zone) !== String(loc.zone)) continue;
      if ((it.loc.setI != null) && (loc.setI != null) && it.loc.setI !== loc.setI) continue;
      if ((it.loc.i != null) && (loc.i != null) && it.loc.i !== loc.i) continue;
      return { row: row, i: i, item: it };
    }
  }
  return null;
};

MC.ui.pickItemAtScreen = function (view, computed, x, y, predicate) {
  if (!view || !computed || !computed.models) return null;
  if (x == null || y == null) return null;
  if (!isFinite(x) || !isFinite(y)) return null;
  predicate = predicate || function () { return true; };

  var best = null;
  var bestZ = -999999;
  var models = computed.models;
  var row;
  for (row = 0; row < models.length; row++) {
    var rm = models[row];
    if (!rm || !rm.items) continue;
    var i;
    for (i = 0; i < rm.items.length; i++) {
      var it = rm.items[i];
      if (!it) continue;
      if (!predicate(it)) continue;
      var r = MC.ui.itemScreenRect(view, it, 0);
      if (x < r.x0 || x > r.x1 || y < r.y0 || y > r.y1) continue;
      var z = (it.depth != null) ? it.depth : 0;
      if (z >= bestZ) { bestZ = z; best = { row: row, i: i, item: it }; }
    }
  }
  return best;
};

MC.ui.stackRectForKey = function (view, computed, row, stackKey, pad) {
  if (!view || !computed || !computed.models) return null;
  if (pad == null) pad = 0;
  if (row < 0 || row >= computed.models.length) return null;
  var rm = computed.models[row];
  if (!rm || !rm.stacks) return null;
  var st = rm.stacks[String(stackKey)];
  if (!st) return null;
  var cam = (view.camX && view.camX[row] != null) ? view.camX[row] : 0;
  var L = MC.config.render.layout;
  var nSlots = (st.nSlots != null) ? st.nSlots : ((st.nReal != null) ? st.nReal : 0);
  if (nSlots <= 0) nSlots = 1;
  var xA = st.x0;
  var xB = st.x0 + (nSlots - 1) * st.stride * st.fanDir;
  var minX = xA < xB ? xA : xB;
  var maxX = xA < xB ? xB : xA;
  maxX += L.faceW - 1;
  return { x0: minX - cam - pad, y0: st.y - pad, x1: maxX - cam + pad, y1: st.y + L.faceH - 1 + pad };
};

MC.ui.navPickInDirection = function (view, computed, dir) {
  if (!view || !computed || !computed.models) return null;
  if (!computed.selected) return null;

  dir = String(dir || "");
  var cur = computed.selected;
  var curC = MC.ui.itemScreenCenter(view, cur);
  var curCx = curC.cx;
  var curCy = curC.cy;

  var models = computed.models;
  var cand = [];
  var row;
  for (row = 0; row < 5; row++) {
    var rm = models[row];
    if (!rm || !rm.items) continue;
    var i;
    for (i = 0; i < rm.items.length; i++) {
      var it = rm.items[i];
      if (!it) continue;
      if (it === cur) continue;
      var c = MC.ui.itemScreenCenter(view, it);
      cand.push({ row: row, i: i, it: it, cx: c.cx, cy: c.cy });
    }
  }
  if (cand.length === 0) return null;

  function inDir(c) {
    if (dir === "left") return c.cx < curCx;
    if (dir === "right") return c.cx > curCx;
    if (dir === "up") return c.cy < curCy;
    if (dir === "down") return c.cy > curCy;
    return false;
  }

  function scoreCone(c) {
    var dx = c.cx - curCx;
    var dy = c.cy - curCy;
    var along = (dir === "left" || dir === "right") ? Math.abs(dx) : Math.abs(dy);
    var perp = (dir === "left" || dir === "right") ? Math.abs(dy) : Math.abs(dx);
    var uiCfg = MC.config.ui;
    var k = (dir === "left" || dir === "right") ? uiCfg.navConeKLeftRight : uiCfg.navConeKUpDown;
    return (along * along) + (perp * perp) * k;
  }

  // Primary: closest candidate in the pressed direction.
  // For Left/Right, if the current row has any candidates in that direction,
  // prefer staying in-row (prevents surprising jumps to other rows when the
  // center row contains valid left/right targets like deck/discard).
  var preferSameRow = ((dir === "left" || dir === "right") && (cur && cur.row != null));
  var hasSameRowCandidate = false;
  if (preferSameRow) {
    for (j = 0; j < cand.length; j++) {
      var cs = cand[j];
      if (!inDir(cs)) continue;
      if (cs.it && cs.it.row === cur.row) { hasSameRowCandidate = true; break; }
    }
  }

  var best = null;
  var bestScore = 999999999;
  var j;
  for (j = 0; j < cand.length; j++) {
    var c = cand[j];
    if (!inDir(c)) continue;
    if (hasSameRowCandidate && (!c.it || c.it.row !== cur.row)) continue;
    var s = scoreCone(c);
    if (s < bestScore) { bestScore = s; best = c; }
  }
  if (best) return { row: best.row, i: best.i };

  // Fallback: global axis-wrap (pick farthest extreme on the opposite side).
  var extreme = null;
  if (dir === "up") extreme = -Infinity;
  else if (dir === "down") extreme = Infinity;
  else if (dir === "left") extreme = -Infinity;
  else if (dir === "right") extreme = Infinity;

  // Determine extreme along the axis.
  for (j = 0; j < cand.length; j++) {
    var cc = cand[j];
    if (dir === "up") { if (cc.cy > extreme) extreme = cc.cy; }
    else if (dir === "down") { if (cc.cy < extreme) extreme = cc.cy; }
    else if (dir === "left") { if (cc.cx > extreme) extreme = cc.cx; }
    else if (dir === "right") { if (cc.cx < extreme) extreme = cc.cx; }
  }

  best = null;
  bestScore = 999999999;
  for (j = 0; j < cand.length; j++) {
    var cw = cand[j];
    var atExtreme = false;
    if (dir === "up" || dir === "down") atExtreme = (cw.cy === extreme);
    else atExtreme = (cw.cx === extreme);
    if (!atExtreme) continue;
    // Use the same cone scoring to pick the most aligned extreme target.
    var sw = scoreCone(cw);
    if (sw < bestScore) { bestScore = sw; best = cw; }
  }
  if (best) return { row: best.row, i: best.i };

  return null;
};

MC.ui.layoutHint = function (state, view) {
  // Reservation hint: which stacks need an extra slot so ghosts/previews don't overlap.
  // Keep the policy here so buildRowItems + computeRowModels stay consistent.
  var hint = { bankReserve: false, needsExtraSlotBySetI: null, menuHoverCmd: null };
  if (!state || !view) return hint;

  // Targeting mode: reserve for all legal destinations.
  if (view.mode === "targeting" && view.targeting && view.targeting.active && view.targeting.cmds) {
    var needs = {};
    var t = view.targeting;

    // Hold-chain: reserve for the union of destinations across all segments (so bank can be
    // reserved/ghosted even while a cursor-mode segment is active).
    var segs = (t.chainActive && t.chainSegs && t.chainSegs.length) ? t.chainSegs : [{ cmds: t.cmds }];
    var si;
    for (si = 0; si < segs.length; si++) {
      var seg = segs[si];
      if (!seg || !seg.cmds) continue;
      var j;
      for (j = 0; j < seg.cmds.length; j++) {
        var cS = seg.cmds[j];
        var dS = MC.moves.destForCmd(cS);
        if (!dS) continue;
        if (dS.kind === "bankEnd") hint.bankReserve = true;
        if (dS.kind === "setEnd") needs[dS.setI] = true;
      }
    }
    hint.needsExtraSlotBySetI = needs;
    return hint;
  }

  // Menu-hover preview: reserve only when unambiguous (exactly 1 legal cmd).
  if (view.mode === "menu" && view.menu && view.menu.items && view.menu.items.length > 0 && view.menu.src && view.menu.src.uid) {
    var nMenuItems = view.menu.items.length;
    var mi = MC.ui.clampI(view.menu.i, nMenuItems);
    view.menu.i = mi;
    var it = view.menu.items[mi];
    var src = view.menu.src;
    if (!it || !src || !src.uid) return hint;

    var uid = src.uid;
    var kindM = String(it.id || "");
    var profM = MC.cmd.getProfile(kindM);
    if (!profM) return hint;
    if (!profM.menuHoverPreview) return hint;
    var rM = MC.moves.cmdsForTargeting(state, kindM, uid, src.loc || null);
    if (!rM || !rM.cmds) return hint;
    var cmdsM = MC.moves.cmdsWithoutSource(rM.cmds);

    // Only preview when unambiguous (exactly 1 legal cmd). Multi-target actions show "..." and should not
    // imply a default destination highlight while browsing the menu.
    if (cmdsM.length === 1) {
      hint.menuHoverCmd = cmdsM[0];
      var d2 = MC.moves.destForCmd(hint.menuHoverCmd);
      if (d2 && d2.kind === "bankEnd") hint.bankReserve = true;
      if (d2 && d2.kind === "setEnd") {
        var needs2 = {};
        needs2[d2.setI] = true;
        hint.needsExtraSlotBySetI = needs2;
      }
    }
  }

  return hint;
};

MC.ui.buildRowItems = function (state, view, row, hint) {
  var L = MC.config.render.layout;

  var out = { items: [], minX: 0, maxX: 0 };
  var isOp = MC.layout.isOpponentRow(row);
  var p = MC.layout.playerForRow(row);
  var yFace = MC.layout.faceYForRow(row);
  var padX = L.rowPadX;

  var i;

  if (row === 4 || row === 0) {
    // Hand row: hand cards + bank stack on opposite side.
    var hand = state.players[p].hand;
    var bank = state.players[p].bank;
    var nHand = hand.length;
    var nBank = bank.length;
    var minX = 999999, maxX = -999999;
    out.stacks = {};

    function pushHandRowItem(kind, uid, xFace, depth, fanDir) {
      out.items.push({
        kind: kind,
        row: row,
        p: p,
        uid: uid,
        depth: depth,
        fanDir: fanDir,
        x: xFace,
        y: yFace,
        w: L.faceW,
        h: L.faceH,
        loc: (kind === "hand") ? { p: p, zone: "hand", i: depth } : ((kind === "bank") ? { p: p, zone: "bank", i: depth } : null),
        stackKey: (kind === "bank") ? ("bank:p" + p + ":row" + row) : null
      });
      var xLo = xFace;
      var xHi = xFace + L.faceW - 1;
      // Include 1px shadow pixels that can be drawn outside the face.
      if (kind === "hand") {
        xLo = xFace + L.shadowBarDx;
      } else if (kind === "bank") {
        if (fanDir < 0) xHi = xFace + L.faceW;
        else xLo = xFace + L.shadowBarDx;
      }
      if (xLo < minX) minX = xLo;
      if (xHi > maxX) maxX = xHi;
    }

    function pushRecvHandItem(uid, xFace, depth) {
      out.items.push({
        kind: "hand",
        row: row,
        p: p,
        uid: uid,
        depth: depth,
        fanDir: isOp ? -1 : 1,
        x: xFace,
        y: yFace,
        w: L.faceW,
        h: L.faceH,
        loc: { p: p, zone: "recvProps", i: depth },
        stackKey: "recvProps:p" + p + ":row" + row
      });
      var xLo = xFace + L.shadowBarDx;
      var xHi = xFace + L.faceW - 1;
      if (xLo < minX) minX = xLo;
      if (xHi > maxX) maxX = xHi;
    }

    // Hand zone (spaced).
    var pr = state.prompt;
    var isRecvPrompt = !!(pr && pr.kind === "placeReceived" && pr.p === p);
    var recv = isRecvPrompt ? pr.uids : null;
    var nRecv = recv ? recv.length : 0;

    var xHandStart = isOp ? (L.screenW - padX - L.faceW) : padX;
    var handStep = isOp ? (-L.handStrideX) : L.handStrideX;

    if (!isOp && isRecvPrompt && nRecv > 0) {
      for (i = 0; i < nRecv; i++) {
        pushRecvHandItem(recv[i], padX + i * L.handStrideX, i);
      }
      var recvW = (nRecv > 0) ? ((nRecv - 1) * L.handStrideX + L.faceW) : 0;
      xHandStart = padX + recvW + L.stackGapX + 2;
    } else if (isOp && isRecvPrompt && nRecv > 0) {
      var xRecvStart = xHandStart;
      for (i = 0; i < nRecv; i++) {
        pushRecvHandItem(recv[i], xRecvStart - i * L.handStrideX, i);
      }
      var recvW2 = (nRecv > 0) ? ((nRecv - 1) * L.handStrideX + L.faceW) : 0;
      xHandStart = xRecvStart - recvW2 - L.stackGapX - 2;
    }

    for (i = 0; i < nHand; i++) {
      var uidH = hand[i];
      pushHandRowItem("hand", uidH, xHandStart + i * handStep, i, 0);
    }

    // Bank zone (overlapped stack), opposite side.
    var stride = L.stackStrideX;
    var gap = L.stackGapX;

    if (!isOp) {
      // Player bank: fan right, anchored on the right.
      var bankRightX = L.screenW - padX - L.faceW;
      // Reserve one extra slot when a bank destination is being indicated (ghost/preview),
      // so the "new top" location doesn't overlap the current top card.
      var bankReserve = !!(hint && hint.bankReserve);
      var bankLeftX = bankRightX - (nBank > 0 ? (((nBank - 1) + (bankReserve ? 1 : 0)) * stride) : 0);
      var handMaxX = (nHand > 0) ? (xHandStart + (nHand - 1) * L.handStrideX + L.faceW - 1) : (padX - 1);
      if (nBank > 0 && bankLeftX <= (handMaxX + gap)) bankLeftX = handMaxX + gap + 1;
      var bankKey = "bank:p" + p + ":row" + row;
      if (nBank > 0 || bankReserve) {
        out.stacks[bankKey] = { kind: "bank", x0: bankLeftX, y: yFace, stride: stride, fanDir: 1, nReal: nBank, nSlots: nBank + (bankReserve ? 1 : 0) };
      }
      for (i = 0; i < nBank; i++) {
        pushHandRowItem("bank", bank[i], bankLeftX + i * stride, i, 1);
      }
    } else {
      // Opponent bank: fan left, anchored on the left.
      var bankLeftX2 = padX;
      var bankRightX2 = bankLeftX2 + (nBank > 0 ? ((nBank - 1) * stride) : 0);
      var handMinX = (nHand > 0) ? (xHandStart + (nHand - 1) * handStep) : (xHandStart + 1);
      var bankMaxX = bankRightX2 + L.faceW - 1;
      if (nBank > 0 && (bankMaxX + gap) >= handMinX) {
        var desiredBankMax = handMinX - gap - 1;
        bankRightX2 = desiredBankMax - (L.faceW - 1);
      }
      var bankKey2 = "bank:p" + p + ":row" + row;
      if (nBank > 0) {
        out.stacks[bankKey2] = { kind: "bank", x0: bankRightX2, y: yFace, stride: stride, fanDir: -1, nReal: nBank, nSlots: nBank };
      }
      for (i = 0; i < nBank; i++) {
        pushHandRowItem("bank", bank[i], bankRightX2 - i * stride, i, -1);
      }
    }

    out.minX = (minX === 999999) ? 0 : minX;
    out.maxX = (maxX === -999999) ? 0 : maxX;
    out.items.sort(function (a, b) {
      var ax = (a && a.x != null) ? a.x : 0;
      var bx = (b && b.x != null) ? b.x : 0;
      var dx = ax - bx;
      if (dx) return dx;
      var ay = (a && a.y != null) ? a.y : 0;
      var by = (b && b.y != null) ? b.y : 0;
      return ay - by;
    });
    return out;
  }

  if (row === 3 || row === 1) {
    // Table row: property sets (with house as last card in stack).
    var sets = state.players[p].sets;
    var setCount = sets.length;
    var stride2 = L.stackStrideX;
    var minX2 = 999999, maxX2 = -999999;
    var fanDir = isOp ? -1 : 1;
    out.stacks = {};

    if (!isOp) {
      // While targeting, ghost destinations may include an extra slot at the end of a stack.
      // Reserve width so adjacent stacks shift and ghosts/previews don't overlap.
      var needsExtraSlot = (hint && hint.needsExtraSlotBySetI) ? hint.needsExtraSlotBySetI : {};

      var cursorX = padX;
      for (i = 0; i < setCount; i++) {
        var set = sets[i];
        if (!set) continue;
        var cards = [];
        var k;
        for (k = 0; k < set.props.length; k++) cards.push({ kind: "setProp", setI: i, depth: k, uid: set.props[k][0], color: set.props[k][1] });
        if (set.houseUid) cards.push({ kind: "setHouse", setI: i, depth: cards.length, uid: set.houseUid });

        var nCards = cards.length;
        if (nCards <= 0) continue;
        var stackKey = "set:p" + p + ":set" + i;
        out.stacks[stackKey] = { kind: "set", x0: cursorX, y: yFace, stride: stride2, fanDir: fanDir, nReal: nCards, nSlots: nCards + (needsExtraSlot[i] ? 1 : 0) };

        var depth;
        for (depth = 0; depth < nCards; depth++) {
          var xFaceP = cursorX + depth * stride2;
          out.items.push({
            kind: cards[depth].kind,
            row: row,
            p: p,
            uid: cards[depth].uid,
            color: cards[depth].color,
            setI: cards[depth].setI,
            depth: cards[depth].depth,
            fanDir: fanDir,
            stackKey: stackKey,
            x: xFaceP,
            y: yFace,
            w: L.faceW,
            h: L.faceH,
            loc: (cards[depth].kind === "setProp")
              ? { p: p, zone: "setProps", setI: cards[depth].setI, i: cards[depth].depth }
              : { p: p, zone: "setHouse", setI: cards[depth].setI }
          });
          var xLoP = xFaceP;
          var xHiP = xFaceP + L.faceW - 1;
          if (fanDir > 0) xLoP = xFaceP + L.shadowBarDx;
          else xHiP = xFaceP + L.faceW;
          if (xLoP < minX2) minX2 = xLoP;
          if (xHiP > maxX2) maxX2 = xHiP;
        }

        var stackW = L.faceW + (nCards - 1) * stride2;
        if (needsExtraSlot[i]) stackW += stride2;
        cursorX = cursorX + stackW + L.stackGapX;
      }
      out.newSetX = cursorX;
    } else {
      var rightCursor = L.screenW - padX - L.faceW;
      for (i = 0; i < setCount; i++) {
        var setO = sets[i];
        if (!setO) continue;
        var cardsO = [];
        var kk;
        for (kk = 0; kk < setO.props.length; kk++) cardsO.push({ kind: "setProp", setI: i, depth: kk, uid: setO.props[kk][0], color: setO.props[kk][1] });
        if (setO.houseUid) cardsO.push({ kind: "setHouse", setI: i, depth: cardsO.length, uid: setO.houseUid });

        var nCardsO = cardsO.length;
        if (nCardsO <= 0) continue;
        var stackKeyO = "set:p" + p + ":set" + i;
        out.stacks[stackKeyO] = { kind: "set", x0: rightCursor, y: yFace, stride: stride2, fanDir: fanDir, nReal: nCardsO, nSlots: nCardsO };

        var d2;
        for (d2 = 0; d2 < nCardsO; d2++) {
          var xFaceO = rightCursor - d2 * stride2;
          out.items.push({
            kind: cardsO[d2].kind,
            row: row,
            p: p,
            uid: cardsO[d2].uid,
            color: cardsO[d2].color,
            setI: cardsO[d2].setI,
            depth: cardsO[d2].depth,
            fanDir: fanDir,
            stackKey: stackKeyO,
            x: xFaceO,
            y: yFace,
            w: L.faceW,
            h: L.faceH,
            loc: (cardsO[d2].kind === "setProp")
              ? { p: p, zone: "setProps", setI: cardsO[d2].setI, i: cardsO[d2].depth }
              : { p: p, zone: "setHouse", setI: cardsO[d2].setI }
          });
          var xLoO = xFaceO;
          var xHiO = xFaceO + L.faceW - 1;
          if (fanDir > 0) xLoO = xFaceO + L.shadowBarDx;
          else xHiO = xFaceO + L.faceW;
          if (xLoO < minX2) minX2 = xLoO;
          if (xHiO > maxX2) maxX2 = xHiO;
        }

        var leftEdge = rightCursor - (nCardsO - 1) * stride2;
        rightCursor = leftEdge - L.stackGapX - L.faceW;
      }
    }

    out.minX = (minX2 === 999999) ? 0 : minX2;
    out.maxX = (maxX2 === -999999) ? 0 : maxX2;
    out.items.sort(function (a, b) {
      var ax = (a && a.x != null) ? a.x : 0;
      var bx = (b && b.x != null) ? b.x : 0;
      var dx = ax - bx;
      if (dx) return dx;
      var ay = (a && a.y != null) ? a.y : 0;
      var by = (b && b.y != null) ? b.y : 0;
      return ay - by;
    });
    return out;
  }

  if (row === 2) {
    // Center row: deck, discard, and UI buttons.
    var C = MC.config.render.layout;
    var top = C.rowY[2] + C.centerTopInsetY;
    var deckX = C.centerDeckX;
    var gapX = C.centerPileGapX;
    var x0 = deckX;
    out.items.push({ kind: "deck", row: 2, x: x0, y: top, w: C.faceW, h: C.faceH });
    out.items.push({ kind: "discard", row: 2, x: x0 + C.faceW + gapX, y: top, w: C.faceW, h: C.faceH });

    var dbgEnabled = !!(MC.config.debug.enabled && MC.debug.toolsOn);

    // Hide buttons while an overlay is active (menu/targeting).
    // Inspect should keep buttons visible/selectable so they can be inspected too.
    var overlayActive = !!(view && (view.mode === "menu" || view.mode === "targeting"));
    if (!overlayActive) {
      // Right-side vertical strip.
      //
      // Original layout: End/Step/Reset/Next were 10px tall with 1px gaps and filled the full
      // center row. Menu is below End; in dev mode this intentionally spills below the center
      // row band (acceptable dev-only overlap).
      var stripW = C.centerBtnStripW;
      var stripH = 10;
      var stripX = C.screenW - C.centerBtnStripPadRight - stripW;
      var stripY0 = C.rowY[2];

      function pushBtn(id, label, y, disabled) {
        out.items.push({ kind: "btn", id: id, label: label, disabled: !!disabled, row: 2, x: stripX, y: y, w: stripW, h: stripH });
      }

      // End is always available on your turn; if hand > HAND_MAX the engine enters a discard-down prompt.
      var endDisabled = (state.winnerP !== MC.state.NO_WINNER) || (state.activeP !== 0);
      pushBtn("endTurn", "End", stripY0, endDisabled);
      pushBtn("mainMenu", "Menu", stripY0 + 11, false);
      if (dbgEnabled) {
        // Game over: Step would attempt to mutate state via debugStep and can throw.
        // Keep Reset/Next available for recovery.
        pushBtn("step", "Step", stripY0 + 22, (state.winnerP !== MC.state.NO_WINNER));
        pushBtn("reset", "Reset", stripY0 + 33, false);
        pushBtn("nextScenario", "Next", stripY0 + 44, false);
      }
    }

    out.minX = 0;
    out.maxX = C.screenW - 1;
    out.items.sort(function (a, b) {
      var ax = (a && a.x != null) ? a.x : 0;
      var bx = (b && b.x != null) ? b.x : 0;
      var dx = ax - bx;
      if (dx) return dx;
      var ay = (a && a.y != null) ? a.y : 0;
      var by = (b && b.y != null) ? b.y : 0;
      return ay - by;
    });
    return out;
  }

  return out;
};

// `MC.ui.computeRowModels` lives in `src/67_ui_row_models.js`.

MC.ui.ensureCamForSelection = function (rowModel, row, selItem, camArr) {
  var L = MC.config.render.layout;
  if (!camArr) return;

  var cam = camArr[row];
  var margin = L.camMarginX;

  if (!rowModel || !rowModel.items || rowModel.items.length === 0 || !selItem) {
    camArr[row] = 0;
    return;
  }

  var contentW = (rowModel.maxX - rowModel.minX + 1);
  if (contentW <= L.screenW) { camArr[row] = 0; return; }

  var x0 = selItem.x;
  var x1 = selItem.x + selItem.w - 1;
  var maxVisibleX = (L.screenW - 1 - margin);

  if ((x0 - cam) < margin) cam = (x0 - margin);
  if ((x1 - cam) > maxVisibleX) cam = (x1 - maxVisibleX);

  var camA = (rowModel.minX - margin);
  var camB = (rowModel.maxX - maxVisibleX);
  var camLo = camA < camB ? camA : camB;
  var camHi = camA < camB ? camB : camA;
  if (cam < camLo) cam = camLo;
  if (cam > camHi) cam = camHi;

  camArr[row] = Math.floor(cam);
};

MC.ui.updateCameras = function (state, view, computed) {
  if (!view || !view.camX) return;
  if (!computed || !computed.models) return;

  var models = computed.models;
  var row;
  for (row = 0; row < 5; row++) {
    if (!(row === 0 || row === 1 || row === 3 || row === 4)) continue;

    // Default selection is the cursor selection when in that row.
    var selItem = null;
    if (view.cursor.row === row) {
      var rm = models[row];
      if (rm && rm.items && rm.items.length) {
        var i = MC.ui.clampI(view.cursor.i, rm.items.length);
        selItem = rm.items[i];
      }
    } else {
      // For non-active rows, use first item to keep cam stable.
      var rm2 = models[row];
      if (rm2 && rm2.items && rm2.items.length) selItem = rm2.items[0];
    }

    // In overlay modes, have the preview destination row camera follow the preview.
    if ((view.mode === "targeting" || view.mode === "menu") && computed.meta && computed.meta.focus && row === computed.meta.focus.row) selItem = computed.meta.focus;

    MC.ui.ensureCamForSelection(models[row], row, selItem, view.camX);
  }
};

MC.ui.menuOpenForSelection = function (state, view, sel) {
  if (!view || !view.menu) return;
  if (state && state.winnerP !== MC.state.NO_WINNER) return;
  view.menu.items = [];
  view.menu.i = 0;
  view.menu.src = sel ? { row: sel.row, i: view.cursor.i, uid: sel.uid, loc: sel.loc || null } : null;

  if (!sel || !sel.loc) return;
  var zSel = String(sel.loc.zone || "");
  if (!(zSel === "hand" || zSel === "recvProps")) return;
  if (sel.loc.p !== 0) return;

  var uid = sel.uid;
  var defSel = MC.state.defByUid(state, uid);
  var kinds = MC.cmd.menuKinds;
  var iKind;
  for (iKind = 0; iKind < kinds.length; iKind++) {
    var kind = kinds[iKind];
    var prof = MC.cmd.getProfile(kind);
    if (!prof) continue;

    var r = MC.moves.cmdsForTargeting(state, kind, uid, sel.loc || null);
    if (!r || !r.cmds) continue;
    var realCmds = MC.moves.cmdsWithoutSource(r.cmds);
    if (!realCmds || realCmds.length === 0) continue; // actionable-only

    var label = prof.menuLabel(state, realCmds);
    label = MC.ui.menuLabelForKind(kind, label, defSel);
    view.menu.items.push({ id: kind, label: label });
  }

  // Explicit cancel option so A-confirm can cancel too (in addition to B).
  // Only add when there's at least one actionable item; otherwise let callers treat it as "no actions".
  if (view.menu.items.length > 0) view.menu.items.push({ id: "source", label: "Cancel" });

  // Always allow cancel/back with B; no explicit menu item needed.
};

MC.ui.targetingEnter = function (state, view, kind, hold, uid, loc) {
  if (!view || !view.targeting) return;
  var t = MC.ui.targetingResetCommon(state, view, hold, uid, loc);
  if (!t) return;
  t.kind = String(kind || "");
  t.chainActive = false;
  t.chainSegs = [];
  t.chainI = 0;

  var r = MC.moves.cmdsForTargeting(state, t.kind, uid, t.card ? t.card.loc : null);
  if (!r) {
    t.active = false;
    view.mode = "browse";
    return;
  }

  t.cmds = r.cmds;
  t.wildColor = (r.wildColor != null) ? r.wildColor : MC.state.NO_COLOR;
  t.cmdI = 0; // default always-existing if any

  // Unknown targeting kind.
  if (!t.cmds || t.cmds.length === 0) {
    t.active = false;
    view.mode = "browse";
    return;
  }

  // If the only legal destination is Source/cancel, disallow entering targeting.
  if (MC.moves.cmdsWithoutSource(t.cmds).length === 0) {
    MC.ui.feedbackNoMovesLeft(state, view);
    t.active = false;
    view.mode = "browse";
    return;
  }

  // Profile-driven default selection (e.g. Rent: highest amount, without changing cycle order).
  MC.ui.targetingApplyProfileDefaultCmdI(state, t);

  // Wild menu-place nuance: if only one real destination exists, start at Source so it doesn't
  // look like we pre-selected the drop target (ellipsis implies follow-up choice).
  if (MC.cmd.wildSingleDestPlaceCmd(t)) t.cmdI = MC.ui.findSourceCmdI(t.cmds);

  view.mode = "targeting";
};

MC.ui.targetingEnterHoldChain = function (state, view, kinds, uid, loc) {
  if (!view || !view.targeting) return;
  var t = MC.ui.targetingResetCommon(state, view, true, uid, loc);
  if (!t) return;
  t.chainActive = true;
  t.chainSegs = [];
  t.chainI = 0;

  var chain = MC.cmd.buildHoldChain(state, uid, t.card ? t.card.loc : null, kinds);
  if (chain && chain.segs) t.chainSegs = chain.segs;

  if (!t.chainSegs || t.chainSegs.length === 0) {
    MC.ui.feedbackNoMovesLeft(state, view);
    t.active = false;
    view.mode = "browse";
    return;
  }

  // Apply first segment (default).
  var seg0 = t.chainSegs[0];
  t.chainI = 0;
  t.kind = seg0.kind;
  t.cmds = seg0.cmds;
  t.cmdI = 0;
  t.wildColor = (chain && chain.wildColor != null) ? chain.wildColor : MC.state.NO_COLOR;

  // Profile-driven default selection for the first segment (notably Rent).
  MC.ui.targetingApplyProfileDefaultCmdI(state, t);
  seg0.cmdI = t.cmdI;

  view.mode = "targeting";
};

MC.ui.targetingRetargetWild = function (state, view, dir) {
  if (!view || !view.targeting || !view.targeting.active) return;
  var t = view.targeting;
  if (!t.card || !t.card.def || !MC.rules.isWildDef(t.card.def)) return;

  var def = t.card.def;
  var c0 = def.wildColors[0];
  var c1 = def.wildColors[1];
  var prevColor = t.wildColor;
  var nextColor = (prevColor === c0) ? c1 : c0;
  if (dir < 0) nextColor = (prevColor === c1) ? c0 : c1;

  var uid = t.card.uid;
  var loc = t.card ? t.card.loc : null;

  function pickSelI(cmds, keepNewSet, keepSetI, keepSource) {
    var selI = 0;
    var i;
    if (keepNewSet) {
      for (i = 0; i < cmds.length; i++) if (cmds[i] && cmds[i].dest && cmds[i].dest.newSet) { selI = i; break; }
    } else if (keepSetI != null) {
      for (i = 0; i < cmds.length; i++) if (cmds[i] && cmds[i].dest && cmds[i].dest.setI === keepSetI) { selI = i; break; }
    } else if (keepSource) {
      for (i = 0; i < cmds.length; i++) if (cmds[i] && cmds[i].kind === "source") { selI = i; break; }
    }
    return selI;
  }

  t.wildColor = nextColor;

  // Hold-chain: retarget the appropriate segment (even when the active segment is Source),
  // and never inject Source into segment cmd lists (Source is a dedicated segment).
  if (t.chainActive && t.chainSegs && t.chainSegs.length) {
    var segI = MC.ui.clampI(t.chainI, t.chainSegs.length);
    var seg = t.chainSegs[segI];
    var profSeg = seg ? MC.cmd.getProfile(seg.kind) : null;
    if (!profSeg || !profSeg.cmdsForWildColor) {
      var si;
      for (si = 0; si < t.chainSegs.length; si++) {
        var cand = t.chainSegs[si];
        var profC = cand ? MC.cmd.getProfile(cand.kind) : null;
        if (profC && profC.cmdsForWildColor) { segI = si; seg = cand; profSeg = profC; break; }
      }
    }
    if (!seg || !profSeg || !profSeg.cmdsForWildColor) return;

    var prevCmdS = (seg.cmds && seg.cmds.length) ? seg.cmds[MC.ui.clampI(seg.cmdI, seg.cmds.length)] : null;
    var keepNewSetS = !!(prevCmdS && prevCmdS.dest && prevCmdS.dest.newSet);
    var keepSetIS = (prevCmdS && prevCmdS.dest && prevCmdS.dest.setI != null) ? prevCmdS.dest.setI : null;

    var cmdsS = profSeg.cmdsForWildColor(state, uid, def, nextColor, loc);
    var realCmdsS = MC.moves.cmdsWithoutSource(cmdsS);
    seg.cmds = realCmdsS;
    seg.cmdI = pickSelI(seg.cmds, keepNewSetS, keepSetIS, false);

    // If we retargeted the currently active segment, update the active targeting view too.
    if (segI === MC.ui.clampI(t.chainI, t.chainSegs.length)) {
      t.cmds = seg.cmds;
      t.cmdI = seg.cmdI;
      t._profileSorted = false;
      t._profileSyncCmdI = -1;
    }

    return;
  }

  // Non-chain targeting: retarget the current kind/profile (may include Source in cmds list).
  var prof = MC.cmd.getProfile(t.kind);
  if (!prof || !prof.cmdsForWildColor) return;
  var prevCmd = (t.cmds && t.cmds.length) ? t.cmds[MC.ui.clampI(t.cmdI, t.cmds.length)] : null;
  var keepNewSet = !!(prevCmd && prevCmd.dest && prevCmd.dest.newSet);
  var keepSetI = (prevCmd && prevCmd.dest && prevCmd.dest.setI != null) ? prevCmd.dest.setI : null;
  var keepSource = !!(prevCmd && prevCmd.kind === "source");

  var cmds = prof.cmdsForWildColor(state, uid, def, nextColor, loc);
  var include = prof.includeSource ? prof.includeSource(loc) : false;
  if (include) cmds.push({ kind: "source" });

  t.cmds = cmds;
  t._profileSorted = false;
  t._profileSyncCmdI = -1;
  t.cmdI = pickSelI(cmds, keepNewSet, keepSetI, keepSource);

  // Note: no hold-chain persistence here because chain retargeting is handled above.
};

MC.ui.step = function (state, view, actions) {
  if (!state || !view) return null;

  // Tick feedback timers.
  MC.anim.feedbackTick(view);
  MC.ui.toastsTick(view);
  MC.ui.syncPromptToast(state, view);
  MC.ui.syncWinnerToast(state, view);
  MC.anim.tick(state, view);

  // Track recent mouse usage (for hover UX + focus policy).
  MC.ui.mouse.syncAutoFocusPause(view, actions);

  // Targeting overlay hint mode should follow the "last input device" latch.
  // (Prompt toasts already use view.ux.autoFocusPausedByMouse; keep targeting hints consistent.)
  if (view && view.mode === "targeting" && view.targeting && view.targeting.active) {
    var tHm = view.targeting;
    var isDraggingHm = !!(tHm.mouse && tHm.mouse.dragMode && tHm.mouse.dragging);
    if (!isDraggingHm) {
      if (!tHm.hold && view.ux && view.ux.autoFocusPausedByMouse) tHm.hintMode = "mouseClick";
      else tHm.hintMode = "controller";
    }
  }

  var gameOver = (state.winnerP !== MC.state.NO_WINNER);
  var prevWinner = (view.ux && view.ux.lastWinnerP != null) ? view.ux.lastWinnerP : MC.state.NO_WINNER;
  var justEnded = (gameOver && prevWinner === MC.state.NO_WINNER);

  // Game over: arm a short celebration FX (visual only; does not lock input).
  if (justEnded) MC.anim.beginGameOverFx(state, view);

  // Game over: close overlays and allow free navigation/inspect.
  if (gameOver) {
    if (view.mode === "menu") { view.menu.items = []; }
    if (view.targeting) view.targeting.active = false;
    view.mode = "browse";
  }

  // Prompt mode sync: prompts are rules-owned, UI adopts a dedicated mode.
  var pr = state.prompt;
  var hasPrompt = !!pr;
  var promptForP0 = !!(hasPrompt && pr.p === 0);
  if (!gameOver && promptForP0) {
    var k = pr && pr.kind ? String(pr.kind) : "";
    var allowOverlays = (k === "placeReceived" || k === "replaceWindow");
    if (!allowOverlays) {
      // Prompts override overlays.
      if (view.mode === "menu") { view.menu.items = []; }
      if (view.targeting) view.targeting.active = false;
      view.mode = "prompt";
    } else {
      // Keep menu/targeting when active; otherwise remain in prompt mode.
      if (!(view.mode === "menu" || view.mode === "targeting")) view.mode = "prompt";
    }
  } else {
    // If a prompt ended while we were in a prompt-only targeting flow, drop it.
    if (view.mode === "targeting" && view.targeting && view.targeting.active && view.targeting.card && view.targeting.card.loc && view.targeting.card.loc.zone === "recvProps") {
      view.targeting.active = false;
      view.mode = "browse";
    }
    if (view.mode === "prompt") view.mode = "browse";
  }

  // Inspect is meaningful in browse + prompt mode.
  view.inspectActive = !!((view.mode === "browse" || view.mode === "prompt") && actions.x.inspectActive);

  // Compute models for navigation helpers.
  var computed = MC.ui.computeRowModels(state, view);
  MC.ui.updateCameras(state, view, computed);

  // While animating (shuffle/deal), lock input and just keep the view stable.
  if (view.anim && view.anim.lock) {
    computed = MC.ui.computeRowModels(state, view);
    MC.ui.updateCameras(state, view, computed);

    // During deal animations, keep cursor stable by anchored uid so
    // the selection highlight doesn't drift through the bank as new hand cards appear.
    if (view.anim.active && view.anim.active.kind === "deal" && view.ux && view.ux.selAnchor && view.ux.selAnchor.uid && view.ux.selAnchor.loc) {
      var a = view.ux.selAnchor;
      var rowA = a.row;
      if (rowA != null && rowA >= 0 && rowA < computed.models.length) {
        var rmA = computed.models[rowA];
        if (rmA && rmA.items) {
          var iA;
          var pick = null;
          for (iA = 0; iA < rmA.items.length; iA++) {
            var itA = rmA.items[iA];
            if (!itA || !itA.uid || !itA.loc) continue;
            if (itA.uid !== a.uid) continue;
            if (String(itA.loc.zone || "") !== String(a.loc.zone || "")) continue;
            if ((itA.loc.p != null) && (a.loc.p != null) && itA.loc.p !== a.loc.p) continue;
            pick = { row: rowA, i: iA, item: itA };
            break;
          }

          if (pick) {
            MC.ui.cursorMoveTo(view, pick);
            computed = MC.ui.computeRowModels(state, view);
            MC.ui.updateCameras(state, view, computed);
          }
        }
      }
    }

    // During non-deal animation locks (notably xfer), refresh the selection
    // anchor so focus preservation doesn't "snap" when the lock clears after list splices
    // (e.g., paying with a mid-stack bank card).
    if (!(view.anim.active && view.anim.active.kind === "deal")) {
      MC.ui.focus.snapshot(state, view, computed);
    }
    return null;
  }

  // Focus policy (selection preservation + centralized autofocus rules).
  // (Defined in a later-concatenated module; safe to call at runtime.)
  var allowFocus = (view.mode === "browse" || view.mode === "prompt");
  var isHardLockedPrompt = !!(promptForP0 && pr && pr.kind === "discardDown");
  if (allowFocus && !isHardLockedPrompt) {
    var didFocus = MC.ui.focus.apply(state, view, computed, actions);
    if (didFocus) {
      computed = MC.ui.computeRowModels(state, view);
      MC.ui.updateCameras(state, view, computed);
    }
  }

  // Track transitions for focus rules (after applying them).
  view.ux.lastActiveP = state.activeP;
  view.ux.lastPlaysLeft = state.playsLeft;
  view.ux.lastHandLenP0 = state.players[0].hand.length;
  view.ux.lastWinnerP = state.winnerP;
  view.ux.lastPromptForP0 = !!promptForP0;
  view.ux.lastPromptKind = promptForP0 && pr && pr.kind ? String(pr.kind) : "";

  // Prevent accidental immediate Reset/Next activation if the player is pressing A
  // during the same frame the win becomes visible.
  if (justEnded && (actions.a.tap || actions.a.grabStart)) {
    MC.anim.feedbackError(view, "game_over", "");
    return null;
  }

  function focusSnapshot() {
    MC.ui.focus.snapshot(state, view, computed);
  }

  function setAutoFocusPauseForCenterBtn(id) {
    if (id === "step" || id === "nextScenario" || id === "reset") {
      view.ux.autoFocusPausedByDebug = true;
    }
  }

  function currentSelection() {
    var row = view.cursor.row;
    var rm = computed.models[row];
    if (!rm || !rm.items || rm.items.length === 0) return null;
    var i = MC.ui.clampI(view.cursor.i, rm.items.length);
    return rm.items[i];
  }

  function promptPickHandItemIndices() {
    var out = [];
    if (!computed || !computed.models) return out;
    var rowHand = MC.render.ROW_P_HAND;
    var rm = computed.models[rowHand];
    if (!rm || !rm.items) return out;
    var i;
    for (i = 0; i < rm.items.length; i++) {
      var it = rm.items[i];
      if (!it || it.kind !== "hand" || !it.loc) continue;
      if (it.loc.zone !== "hand") continue;
      if (it.loc.p !== 0) continue;
      out.push(i);
    }
    return out;
  }

  function promptSnapCursorToHand(handItemIs) {
    var rowHand = MC.render.ROW_P_HAND;
    view.cursor.row = rowHand;
    if (!handItemIs || handItemIs.length === 0) { view.cursor.i = 0; return; }
    // If current cursor isn't on a hand card, snap to the first hand card.
    var rm = computed.models[rowHand];
    var cur = rm && rm.items ? rm.items[MC.ui.clampI(view.cursor.i, rm.items.length)] : null;
    if (!cur || cur.kind !== "hand" || !cur.loc || cur.loc.zone !== "hand") {
      view.cursor.i = handItemIs[0];
      return;
    }
    // Otherwise, ensure i is an actual hand-item index.
    var j;
    for (j = 0; j < handItemIs.length; j++) if (handItemIs[j] === view.cursor.i) return;
    view.cursor.i = handItemIs[0];
  }

  function promptCycleHand(handItemIs, dir) {
    if (!handItemIs || handItemIs.length === 0) return;
    var curI = view.cursor.i;
    var k;
    var curK = 0;
    for (k = 0; k < handItemIs.length; k++) if (handItemIs[k] === curI) { curK = k; break; }
    var nextK = curK + dir;
    nextK = MC.ui.wrapI(nextK, handItemIs.length);
    view.cursor.i = handItemIs[nextK];
  }

  // Menu mode
  if (view.mode === "menu") {
    if (actions.b.pressed) {
      view.mode = "browse";
      view.menu.items = [];
      return null;
    }

    // Mouse menu hover + click-outside behavior.
    if (MC.ui.mouse.menuTick(view, actions)) return null;

    var nItems = view.menu.items ? view.menu.items.length : 0;
    if (nItems > 0) {
      if (actions.nav.up) view.menu.i = MC.ui.wrapI(view.menu.i - 1, nItems);
      if (actions.nav.down) view.menu.i = MC.ui.wrapI(view.menu.i + 1, nItems);
    }

    if (actions.a.tap) {
      if (!view.menu.items || view.menu.items.length === 0) {
        view.mode = "browse";
        return null;
      }
      var mi = MC.ui.clampI(view.menu.i, view.menu.items.length);
      var it = view.menu.items[mi];
      var src = view.menu.src;
      view.mode = "browse";
      view.menu.items = [];

      if (!it || !src) return null;
      if (it.id === "source") return null;
      if (!src.loc || src.loc.p !== 0) return null;
      var uid = src.uid;

      // Cmd-profile-driven menu execution.
      var kind = String(it.id || "");
      var prof = MC.cmd.getProfile(kind);
      if (!prof) return null;

      var r = MC.moves.cmdsForTargeting(state, kind, uid, src.loc || null);
      if (!r || !r.cmds) return null;
      var realCmds = MC.moves.cmdsWithoutSource(r.cmds);
      if (!realCmds || realCmds.length === 0) return null;

      // Auto-apply when unambiguous.
      var def = MC.state.defByUid(state, uid);
      var allowAutoApply = MC.ui.kindAllowsAutoApply(kind, def);
      if (realCmds.length === 1 && allowAutoApply) {
        focusSnapshot();
        return { kind: "applyCmd", cmd: realCmds[0] };
      }

      MC.ui.targetingEnter(state, view, kind, false, uid, src.loc);
      // If entered via mouse click, keep mouse-centric help text.
      if (MC.ui.mouse.leftTap(actions)) view.targeting.hintMode = "mouseClick";
      return null;
    }

    return null;
  }

  // Targeting mode
  if (view.mode === "targeting" && view.targeting && view.targeting.active) {
    var t = view.targeting;

    // Cancel
    if (actions.b.pressed) {
      t.active = false;
      view.mode = "browse";
      return null;
    }

    function sortCmdsByScreenX(cmds, rankFn, screenXFn, tieCmp) {
      if (!cmds || cmds.length <= 1) return cmds;
      var out = cmds.slice();
      out.sort(function (a, b) {
        var ar = rankFn ? rankFn(a) : 0;
        var br = rankFn ? rankFn(b) : 0;
        var dr = ar - br;
        if (dr) return dr;
        var ax = screenXFn ? screenXFn(a) : 0;
        var bx = screenXFn ? screenXFn(b) : 0;
        var dx = ax - bx;
        if (dx) return dx;
        return tieCmp ? tieCmp(a, b) : 0;
      });
      return out;
    }

    // Optional: profile-driven screen-space sorting and cursor-moving targeting.
    // IMPORTANT: `t.kind` can change mid-frame via hold-chain segment switching, so always
    // resolve the current profile/UI dynamically inside helpers (avoid capturing stale `ui`).
    function curUi() {
      var prof = MC.cmd.getProfile(t.kind);
      return (prof && prof.ui) ? prof.ui : null;
    }

    function profileEnsureSortedOnce() {
      var ui = curUi();
      if (!ui || !ui.screenXForCmd) return;
      if (!t.cmds || t.cmds.length === 0) return;
      if (t._profileSorted) return;

      var prev = t.cmds[MC.ui.clampI(t.cmdI, t.cmds.length)];
      var keepSource = !!(prev && prev.kind === "source");
      // Preserve selection across sort only when we're not at the default index 0.
      // This avoids letting pre-sort engine order influence the default selection on first entry.
      var preserveNonDefault = (t.cmdI !== 0);
      // Preserve selection by interpreted destination semantics (supports cmds that don't have cmd.dest,
      // e.g. Rent uses cmd.setI).
      var keepDest = preserveNonDefault ? MC.moves.destForCmd(prev) : null;
      var keepTargetUid = preserveNonDefault && (prev && prev.target && prev.target.uid) ? prev.target.uid : 0;
      var keepTargetLoc = preserveNonDefault && (prev && prev.target && prev.target.loc) ? prev.target.loc : null;

      var cmds = sortCmdsByScreenX(
        t.cmds,
        ui.sortRank || null,
        function (c) { return ui.screenXForCmd({ state: state, view: view, computed: computed }, c); },
        ui.tieCmp || null
      );
      t.cmds = cmds;

      // Preserve selection if possible.
      var selI = 0;
      var i;
      if (keepSource) {
        for (i = 0; i < cmds.length; i++) if (cmds[i] && cmds[i].kind === "source") { selI = i; break; }
      } else if (keepDest && keepDest.kind) {
        var k = keepDest.kind;
        var kp = (keepDest.p != null) ? keepDest.p : null;
        var kSetI = (keepDest.setI != null) ? keepDest.setI : null;
        for (i = 0; i < cmds.length; i++) {
          var cD = cmds[i];
          if (!cD || !cD.kind) continue;
          var dD = MC.moves.destForCmd(cD);
          if (!dD || dD.kind !== k) continue;
          if (kp != null && dD.p != null && dD.p !== kp) continue;
          if ((k === "setEnd" || k === "setTop") && kSetI != null && dD.setI !== kSetI) continue;
          selI = i;
          break;
        }
      } else if (keepTargetUid && keepTargetLoc) {
        for (i = 0; i < cmds.length; i++) {
          var c = cmds[i];
          if (!c || !c.kind) continue;
          if (!c.target || c.target.uid !== keepTargetUid || !c.target.loc) continue;
          var al = c.target.loc;
          var bl = keepTargetLoc;
          if (al.p !== bl.p) continue;
          if (String(al.zone || "") !== String(bl.zone || "")) continue;
          if ((al.setI != null) && (bl.setI != null) && al.setI !== bl.setI) continue;
          if ((al.i != null) && (bl.i != null) && al.i !== bl.i) continue;
          selI = i;
          break;
        }
      }
      t.cmdI = selI;
      t._profileSorted = true;

      // If this targeting is part of a hold-chain, persist the sorted cmd order in the active segment
      // so segment switching doesn't keep reintroducing an unsorted order.
      if (t.chainActive && t.chainSegs && t.chainSegs.length) {
        var seg = t.chainSegs[MC.ui.clampI(t.chainI, t.chainSegs.length)];
        if (seg) { seg.cmds = t.cmds; seg.cmdI = t.cmdI; }
      }
    }

    function profileSyncCursor() {
      var ui = curUi();
      if (!ui || ui.mode !== "cursor" || !ui.findItemForCmd) return false;
      if (!t.cmds || t.cmds.length === 0) return false;
      // Mouse-driven targeting: don't move the cursor highlight onto targets.
      // Cursor highlight is a strong "selection" signal; use preview overlays on snap instead.
      if (view.ux && view.ux.autoFocusPausedByMouse) return false;
      if (t.mouse && t.mouse.dragMode && t.mouse.dragging) return false;
      var cmdI = MC.ui.clampI(t.cmdI, t.cmds.length);
      t.cmdI = cmdI;
      if (t._profileSyncCmdI === cmdI) return false;
      var cmdSel = t.cmds[cmdI];
      var pick = ui.findItemForCmd({ state: state, view: view, computed: computed }, cmdSel);
      if (pick) MC.ui.cursorMoveTo(view, pick);
      t._profileSyncCmdI = cmdI;
      return true;
    }

    profileEnsureSortedOnce();
    var mouseDid = MC.ui.mouse.applyTargeting(state, view, computed, actions);
    if (mouseDid) profileEnsureSortedOnce();

    // Cycle destinations
    var nCmds = t.cmds ? t.cmds.length : 0;
    if (nCmds > 0) {
      function kindIsCursorMode(kind) {
        var profK = MC.cmd.getProfile(kind);
        var uiK = (profK && profK.ui) ? profK.ui : null;
        return !!(uiK && String(uiK.mode || "") === "cursor");
      }

      function chainApplySeg(nextSegI, dirSeg) {
        if (!t.chainActive || !t.chainSegs || t.chainSegs.length === 0) return false;

        // Persist current cmdI into current segment.
        var curSeg = t.chainSegs[MC.ui.clampI(t.chainI, t.chainSegs.length)];
        if (curSeg) curSeg.cmdI = t.cmdI;

        nextSegI = MC.ui.wrapI(nextSegI, t.chainSegs.length);
        var seg = t.chainSegs[nextSegI];
        if (!seg || !seg.cmds || seg.cmds.length === 0) return false;

        t.chainI = nextSegI;
        t.kind = String(seg.kind || "");
        t.cmds = seg.cmds;
        // Directional segment entry: land on start/end (keeps a stable global cycle).
        t.cmdI = (dirSeg < 0) ? (seg.cmds.length - 1) : 0;
        seg.cmdI = t.cmdI;
        t._profileSorted = false;
        t._profileSyncCmdI = -1;

        // Entering non-cursor segments should snap cursor back to the source selection,
        // to avoid leaving a stale highlight on a previous cursor-mode target.
        if (!kindIsCursorMode(t.kind) && t.srcCursor) {
          view.cursor.row = t.srcCursor.row;
          view.cursor.i = t.srcCursor.i;
        }

        return true;
      }

      if (actions.nav.left) {
        if (t.chainActive && t.chainSegs && t.chainSegs.length) {
          if (t.cmdI > 0) t.cmdI -= 1;
          else chainApplySeg(t.chainI - 1, -1);
        } else {
          t.cmdI = MC.ui.wrapI(t.cmdI - 1, nCmds);
        }
      }
      if (actions.nav.right) {
        if (t.chainActive && t.chainSegs && t.chainSegs.length) {
          if (t.cmdI < (nCmds - 1)) t.cmdI += 1;
          else chainApplySeg(t.chainI + 1, 1);
        } else {
          t.cmdI = MC.ui.wrapI(t.cmdI + 1, nCmds);
        }
      }
    }

    // Wild color toggle (Up/Down)
    if (actions.nav.up || actions.nav.down) {
      var dir = actions.nav.down ? 1 : -1;
      MC.ui.targetingRetargetWild(state, view, dir);
    }

    // Confirm: tap-A (menu targeting) OR release-A (hold targeting).
    var shouldConfirm = false;
    var mouseTap = MC.ui.mouse.leftTap(actions);
    var mouseReleased = MC.ui.mouse.leftReleased(actions);
    var mouseSnapped = !!(t.mouse && t.mouse.active && t.mouse.snapped);

    if (!t.hold && actions.a.tap) {
      // Mouse click should only confirm when the pointer is over a destination/target.
      if (mouseTap && t.mouse && t.mouse.active && !mouseSnapped) {
        MC.anim.feedbackError(view, "no_targets", "Pick a target");
        return null;
      }
      shouldConfirm = true;
    }

    if (t.hold && actions.a.released) {
      // Mouse DnD: releasing without a snap cancels (prevents accidental default drops).
      if (mouseReleased && t.mouse && t.mouse.dragMode && !mouseSnapped) {
        t.active = false;
        view.mode = "browse";
        if (t.srcCursor) {
          view.cursor.row = t.srcCursor.row;
          view.cursor.i = t.srcCursor.i;
        }
        return null;
      }
      shouldConfirm = true;
    }
    if (!shouldConfirm) {
      // Update cameras to follow destination preview / cursor-moving selection.
      computed = MC.ui.computeRowModels(state, view);
      profileSyncCursor();
      MC.ui.updateCameras(state, view, computed);
      return null;
    }

    if (!t.cmds || t.cmds.length === 0) {
      MC.anim.feedbackError(view, "no_targets", "No valid target");
      t.active = false;
      view.mode = "browse";
      return null;
    }

    var cmdI = MC.ui.clampI(t.cmdI, t.cmds.length);
    var cmdSel = t.cmds[cmdI];
    t.active = false;
    view.mode = "browse";

    if (!cmdSel) return null;
    // Mouse DnD: snapping back to Source should behave like cancel (restore cursor).
    if (cmdSel.kind === "source") {
      // Wild menu-place nuance: if only one real destination exists, allow confirm while "on source"
      // so the player can pick color first without cycling to the (only) destination.
      var onlyReal = MC.cmd.wildSingleDestPlaceCmd(t);
      if (onlyReal) { focusSnapshot(); return { kind: "applyCmd", cmd: onlyReal }; }
      if (mouseReleased && t.mouse && t.mouse.dragMode && t.srcCursor) {
        view.cursor.row = t.srcCursor.row;
        view.cursor.i = t.srcCursor.i;
      }
      return null;
    }
    focusSnapshot();
    return { kind: "applyCmd", cmd: cmdSel };
  }

  // Browse mode
  if (view.mode !== "prompt") view.mode = "browse";

  // Prompt mode: rules-owned prompts.
  if (view.mode === "prompt") {
    var prompt = state.prompt;
    if (!prompt || prompt.p !== 0) {
      view.mode = "browse";
      return null;
    }

    function applyPromptNav() {
      var dir = null;
      if (actions.nav.up) dir = "up";
      else if (actions.nav.down) dir = "down";
      else if (actions.nav.left) dir = "left";
      else if (actions.nav.right) dir = "right";
      if (!dir) return;
      var pick = MC.ui.navPickInDirection(view, computed, dir);
      if (pick) {
        view.cursor.row = pick.row;
        view.cursor.i = pick.i;
      }
    }

    function snapCursorToFirstRecv() {
      var pick = MC.ui.findBestCursorTarget(computed.models, [MC.render.ROW_P_HAND], function (it) {
        return it && it.kind === "hand" && it.loc && it.loc.zone === "recvProps" && it.loc.p === 0;
      });
      if (pick) MC.ui.cursorMoveTo(view, pick);
    }

    function snapReplaceWildAndResync() {
      var pick = MC.ui.pickReplaceWindowWild(state, computed);
      if (pick) MC.ui.cursorMoveTo(view, pick);
      computed = MC.ui.computeRowModels(state, view);
      MC.ui.updateCameras(state, view, computed);
      MC.ui.focus.snapshot(state, view, computed);
    }

    // Mouse hover selection in prompts (discardDown is handled separately below).
    // When mouse autofocus pause is latched, keep selection under the pointer even if the mouse is stationary
    // (e.g. immediately after a drop/play changes the UI under the cursor).
    var hoverEnabledP = !!(MC.config.mouse.enabled && MC.config.mouse.hoverSelect);
    if (hoverEnabledP && (view.ux.autoFocusPausedByMouse || MC.ui.mouse.shouldHoverPick(actions))) {
      var pickP = MC.ui.mouse.pickAtPointer(view, computed, actions, function (it) { return !!it; });
      if (pickP) MC.ui.cursorMoveTo(view, pickP);
    }

    if (prompt.kind === "discardDown") {
      // Lock cursor to player hand cards only (not bank).
      var handIs = promptPickHandItemIndices();
      promptSnapCursorToHand(handIs);

      // Recompute after snapping cursor.
      computed = MC.ui.computeRowModels(state, view);
      MC.ui.updateCameras(state, view, computed);

      // Mouse hover selects a specific hand card to discard.
      var hoverEnabledD = !!(MC.config.mouse.enabled && MC.config.mouse.hoverSelect);
      if (hoverEnabledD && (view.ux.autoFocusPausedByMouse || MC.ui.mouse.shouldHoverPick(actions))) {
        var pickD = MC.ui.mouse.pickAtPointer(view, computed, actions, function (it) {
          return it && it.kind === "hand" && it.loc && it.loc.zone === "hand" && it.loc.p === 0;
        });
        if (pickD) {
          MC.ui.cursorMoveTo(view, pickD);
          computed = MC.ui.computeRowModels(state, view);
          MC.ui.updateCameras(state, view, computed);
        }
      }

      // Left/Right cycle within hand.
      if (actions.nav.left) promptCycleHand(handIs, -1);
      if (actions.nav.right) promptCycleHand(handIs, 1);

      // Cancel: only before any discard has happened in this prompt instance.
      if (actions.b.pressed) {
        if (prompt.nDiscarded <= 0) {
          focusSnapshot();
          return { kind: "applyCmd", cmd: { kind: "cancelPrompt" } };
        }
        MC.anim.feedbackError(view, "prompt_forced", "Must discard");
        return null;
      }

      // Discard with A tap.
      if (actions.a.tap) {
        computed = MC.ui.computeRowModels(state, view);
        MC.ui.updateCameras(state, view, computed);
        var selP = currentSelection();
        if (selP && selP.loc && selP.loc.zone === "hand" && selP.loc.p === 0) {
          focusSnapshot();
          return { kind: "applyCmd", cmd: { kind: "discard", card: { uid: selP.uid, loc: selP.loc } } };
        }
      }

      return null;
    }

    // Hold-A grab: enter targeting *before* directional nav so the nudge that triggers
    // grabStart doesn't also move the cursor to a different card in the same frame.
    if (prompt.kind === "placeReceived" && actions.a.grabStart) {
      // Mouse drag-start must originate on an actual received property.
      if (MC.ui.mouse.dragStart(actions)) {
        var pickM = MC.ui.mouse.pickAtPress(view, computed, actions, function (it) {
          return it && it.loc && it.loc.zone === "recvProps" && it.loc.p === 0;
        });
        if (!pickM) return null;
        MC.ui.cursorMoveTo(view, pickM);
        computed = MC.ui.computeRowModels(state, view);
        MC.ui.updateCameras(state, view, computed);
      }
      var selGrabP = currentSelection();
      if (!selGrabP || !selGrabP.loc) { MC.ui.feedbackNoMovesLeft(state, view); if (!MC.ui.mouse.dragStart(actions)) snapCursorToFirstRecv(); return null; }
      if (selGrabP.loc.zone !== "recvProps") {
        MC.anim.feedbackError(view, "place_recv_only", "Select a received property");
        if (!MC.ui.mouse.dragStart(actions)) snapCursorToFirstRecv();
        return null;
      }
      MC.ui.targetingEnter(state, view, "place", true, selGrabP.uid, selGrabP.loc);
      MC.ui.mouse.dragModeEnter(view, actions);
      return null;
    }
    if (prompt.kind === "replaceWindow" && actions.a.grabStart) {
      // Mouse drag-start must originate on an actual eligible Wild in the source set.
      if (MC.ui.mouse.dragStart(actions)) {
        var pickW = MC.ui.mouse.pickAtPress(view, computed, actions, function (it) {
          return it && it.loc && it.loc.zone === "setProps" && it.loc.p === 0;
        });
        if (!pickW) return null;
        MC.ui.cursorMoveTo(view, pickW);
        computed = MC.ui.computeRowModels(state, view);
        MC.ui.updateCameras(state, view, computed);
      }
      var selGrabW = currentSelection();
      if (!selGrabW || !selGrabW.loc) { MC.ui.feedbackNoMovesLeft(state, view); if (!MC.ui.mouse.dragStart(actions)) snapReplaceWildAndResync(); return null; }
      if (selGrabW.loc.zone !== "setProps" || selGrabW.loc.p !== 0 || selGrabW.loc.setI == null || selGrabW.loc.setI !== prompt.srcSetI) {
        MC.anim.feedbackError(view, "replace_pick_wild", "Select a Wild");
        if (!MC.ui.mouse.dragStart(actions)) {
          snapReplaceWildAndResync();
        }
        return null;
      }
      if (selGrabW.uid === prompt.excludeUid) {
        MC.anim.feedbackError(view, "replace_pick_wild", "Select a Wild");
        if (!MC.ui.mouse.dragStart(actions)) {
          snapReplaceWildAndResync();
        }
        return null;
      }
      var defW = MC.state.defByUid(state, selGrabW.uid);
      if (!defW || !MC.rules.isWildDef(defW)) {
        MC.anim.feedbackError(view, "replace_pick_wild", "Select a Wild");
        if (!MC.ui.mouse.dragStart(actions)) {
          snapReplaceWildAndResync();
        }
        return null;
      }
      MC.ui.targetingEnter(state, view, "moveWild", true, selGrabW.uid, selGrabW.loc);
      MC.ui.mouse.dragModeEnter(view, actions);
      return null;
    }

    applyPromptNav();
    computed = MC.ui.computeRowModels(state, view);
    MC.ui.updateCameras(state, view, computed);
    // Refresh selection anchor during prompt ticks so selection preservation doesn't fight user navigation.
    MC.ui.focus.snapshot(state, view, computed);

    // Global prompt escape: allow returning to the title screen via the center Menu button.
    if (actions.a.tap) {
      var selPromptBtn = currentSelection();
      if (selPromptBtn && selPromptBtn.kind === "btn" && selPromptBtn.id === "mainMenu") {
        setAutoFocusPauseForCenterBtn("mainMenu");
        focusSnapshot();
        return { kind: "mainMenu" };
      }
    }

    if (prompt.kind === "payDebt") {
      if (actions.b.pressed) {
        MC.anim.feedbackError(view, "prompt_forced", "Must pay");
        return null;
      }

      if (actions.a.tap) {
        var selD = currentSelection();
        // Allow debug buttons (Step/Reset/Next) during this prompt; End remains disallowed.
        if (selD && selD.kind === "btn") {
          if (selD.id === "step") { setAutoFocusPauseForCenterBtn("step"); focusSnapshot(); return { kind: "debug", action: "step" }; }
          if (selD.id === "reset") { setAutoFocusPauseForCenterBtn("reset"); focusSnapshot(); return { kind: "debug", action: "reset" }; }
          if (selD.id === "nextScenario") { setAutoFocusPauseForCenterBtn("nextScenario"); focusSnapshot(); return { kind: "debug", action: "nextScenario" }; }
          if (selD.id === "endTurn") { MC.anim.feedbackError(view, "prompt_forced", "Must pay"); return null; }
        }
        if (!selD || !selD.loc) { MC.ui.feedbackNoMovesLeft(state, view); return null; }

        if (selD.loc.zone === "hand" && selD.loc.p === 0) {
          var canJsn = !!(prompt.srcAction && prompt.buf && prompt.buf.length === 0);
          if (canJsn) {
            var defJ = MC.state.defByUid(state, selD.uid);
            if (defJ && defJ.kind === MC.CardKind.Action && defJ.actionKind === MC.ActionKind.JustSayNo) {
              focusSnapshot();
              return { kind: "applyCmd", cmd: { kind: "playJustSayNo", card: { uid: selD.uid, loc: selD.loc } } };
            }
          }
        }

        // House-pay-first redirect: selecting a property in a housed set snaps to the House.
        if (selD.loc.zone === "setProps" && selD.loc.setI != null) {
          var setI = selD.loc.setI;
          var set = state.players[0].sets[setI];
          if (set && set.houseUid) {
            var rmT = computed.models[MC.render.ROW_P_TABLE];
            if (rmT && rmT.items) {
              var ii;
              for (ii = 0; ii < rmT.items.length; ii++) {
                var itH = rmT.items[ii];
                if (!itH || itH.kind !== "setHouse" || !itH.loc) continue;
                if (itH.loc.p !== 0) continue;
                if (itH.loc.setI !== setI) continue;
                view.cursor.row = MC.render.ROW_P_TABLE;
                view.cursor.i = ii;
                MC.ui.toastPush(view, { id: "err:house_pay_first", kind: "error", text: "House must be paid first", frames: MC.config.ui.toast.errorFrames });
                MC.anim.feedbackError(view, "house_pay_first", "");
                return null;
              }
            }
            MC.anim.feedbackError(view, "house_pay_first", "House must be paid first");
            return null;
          }
        }

        if (selD.loc.zone === "bank" || selD.loc.zone === "setProps" || selD.loc.zone === "setHouse") {
          focusSnapshot();
          return { kind: "applyCmd", cmd: { kind: "payDebt", card: { uid: selD.uid, loc: selD.loc } } };
        }

        MC.anim.feedbackError(view, "cant_pay", "Can't pay with that");
      }

      return null;
    }

    if (prompt.kind === "respondAction") {
      if (actions.b.pressed) {
        MC.anim.feedbackError(view, "prompt_forced", "Must respond");
        return null;
      }

      if (actions.a.tap) {
        var selR0 = currentSelection();
        // Allow debug buttons (Step/Reset/Next) during this prompt; End remains disallowed.
        if (selR0 && selR0.kind === "btn") {
          if (selR0.id === "step") { setAutoFocusPauseForCenterBtn("step"); focusSnapshot(); return { kind: "debug", action: "step" }; }
          if (selR0.id === "reset") { setAutoFocusPauseForCenterBtn("reset"); focusSnapshot(); return { kind: "debug", action: "reset" }; }
          if (selR0.id === "nextScenario") { setAutoFocusPauseForCenterBtn("nextScenario"); focusSnapshot(); return { kind: "debug", action: "nextScenario" }; }
          if (selR0.id === "endTurn") { MC.anim.feedbackError(view, "must_respond", "Select the target or Just Say No"); return null; }
          // Any other center widget: treat as invalid selection for this prompt.
          MC.anim.feedbackError(view, "must_respond", "Select the target or Just Say No");
          return null;
        }
        if (!selR0 || !selR0.loc) { MC.anim.feedbackError(view, "must_respond", "Select the target or Just Say No"); return null; }

        var tgt = prompt.target;
        var isTarget =
          tgt &&
          tgt.loc &&
          (selR0.uid === tgt.uid) &&
          (selR0.loc.p === tgt.loc.p) &&
          (String(selR0.loc.zone) === String(tgt.loc.zone)) &&
          ((selR0.loc.setI == null) || (selR0.loc.setI === tgt.loc.setI)) &&
          ((selR0.loc.i == null) || (selR0.loc.i === tgt.loc.i));

        if (isTarget) {
          focusSnapshot();
          return { kind: "applyCmd", cmd: { kind: "respondPass" } };
        }

        if (selR0.loc.zone === "hand" && selR0.loc.p === 0) {
          var defRJ = MC.state.defByUid(state, selR0.uid);
          if (defRJ && defRJ.kind === MC.CardKind.Action && defRJ.actionKind === MC.ActionKind.JustSayNo) {
            focusSnapshot();
            return { kind: "applyCmd", cmd: { kind: "playJustSayNo", card: { uid: selR0.uid, loc: selR0.loc } } };
          }
        }

        MC.anim.feedbackError(view, "must_respond", "Select the target or Just Say No");
        return null;
      }

      return null;
    }

    if (prompt.kind === "placeReceived") {
      if (actions.b.pressed) {
        MC.anim.feedbackError(view, "prompt_forced", "Must place");
        snapCursorToFirstRecv();
        return null;
      }

      if (actions.a.tap) {
        var mouseTapPR = MC.ui.mouse.leftTap(actions);
        var selR = currentSelection();
        // Allow debug buttons (Step/Reset/Next) during this prompt; End remains disallowed.
        if (selR && selR.kind === "btn") {
          if (selR.id === "step") { setAutoFocusPauseForCenterBtn("step"); focusSnapshot(); return { kind: "debug", action: "step" }; }
          if (selR.id === "reset") { setAutoFocusPauseForCenterBtn("reset"); focusSnapshot(); return { kind: "debug", action: "reset" }; }
          if (selR.id === "nextScenario") { setAutoFocusPauseForCenterBtn("nextScenario"); focusSnapshot(); return { kind: "debug", action: "nextScenario" }; }
          if (selR.id === "endTurn") {
            MC.anim.feedbackError(view, "prompt_forced", "Must place");
            if (!mouseTapPR) snapCursorToFirstRecv();
            return null;
          }
        }
        if (!selR || !selR.loc) { MC.ui.feedbackNoMovesLeft(state, view); if (!mouseTapPR) snapCursorToFirstRecv(); return null; }
        if (selR.loc.zone !== "recvProps") {
          MC.anim.feedbackError(view, "place_recv_only", "Select a received property");
          if (!mouseTapPR) snapCursorToFirstRecv();
          return null;
        }
        // Tap-A workflow: go directly to placement targeting (only action in this prompt).
        MC.ui.targetingEnter(state, view, "place", false, selR.uid, selR.loc);
        if (MC.ui.mouse.leftTap(actions)) view.targeting.hintMode = "mouseClick";
        return null;
      }

      return null;
    }

    if (prompt.kind === "replaceWindow") {
      if (actions.b.pressed) {
        focusSnapshot();
        return { kind: "applyCmd", cmd: { kind: "skipReplaceWindow" } };
      }

      if (actions.a.tap) {
        var mouseTapRW = MC.ui.mouse.leftTap(actions);
        var selW = currentSelection();
        // Allow debug buttons (Step/Reset/Next) during this prompt; End remains disallowed.
        if (selW && selW.kind === "btn") {
          if (selW.id === "step") { setAutoFocusPauseForCenterBtn("step"); focusSnapshot(); return { kind: "debug", action: "step" }; }
          if (selW.id === "reset") { setAutoFocusPauseForCenterBtn("reset"); focusSnapshot(); return { kind: "debug", action: "reset" }; }
          if (selW.id === "nextScenario") { setAutoFocusPauseForCenterBtn("nextScenario"); focusSnapshot(); return { kind: "debug", action: "nextScenario" }; }
          if (selW.id === "endTurn") { MC.anim.feedbackError(view, "prompt_forced", "Move a Wild or skip"); if (!mouseTapRW) snapReplaceWildAndResync(); return null; }
        }
        if (!selW || !selW.loc) { MC.ui.feedbackNoMovesLeft(state, view); if (!mouseTapRW) snapReplaceWildAndResync(); return null; }
        if (selW.loc.zone !== "setProps" || selW.loc.p !== 0 || selW.loc.setI == null || selW.loc.setI !== prompt.srcSetI) {
          MC.anim.feedbackError(view, "replace_pick_wild", "Select a Wild");
          if (!mouseTapRW) {
            snapReplaceWildAndResync();
          }
          return null;
        }
        if (selW.uid === prompt.excludeUid) {
          MC.anim.feedbackError(view, "replace_pick_wild", "Select a Wild");
          if (!mouseTapRW) {
            snapReplaceWildAndResync();
          }
          return null;
        }
        var defW2 = MC.state.defByUid(state, selW.uid);
        if (!defW2 || !MC.rules.isWildDef(defW2)) {
          MC.anim.feedbackError(view, "replace_pick_wild", "Select a Wild");
          if (!mouseTapRW) {
            snapReplaceWildAndResync();
          }
          return null;
        }
        // Tap-A workflow: enter moveWild targeting.
        MC.ui.targetingEnter(state, view, "moveWild", false, selW.uid, selW.loc);
        if (MC.ui.mouse.leftTap(actions)) view.targeting.hintMode = "mouseClick";
        return null;
      }

      return null;
    }

    // Unknown prompt kind (UI doesn't handle yet).
    view.mode = "browse";
    return null;
  }

  // Mouse hover selection in browse mode.
  if (view.mode === "browse") {
    var hoverEnabledB = !!(MC.config.mouse.enabled && MC.config.mouse.hoverSelect);
    if (hoverEnabledB && (view.ux.autoFocusPausedByMouse || MC.ui.mouse.shouldHoverPick(actions))) {
      var pickB = MC.ui.mouse.pickAtPointer(view, computed, actions, function (it) { return !!it; });
      if (pickB) {
        MC.ui.cursorMoveTo(view, pickB);
        computed = MC.ui.computeRowModels(state, view);
        MC.ui.updateCameras(state, view, computed);
      }
    }
  }

  // Navigation (directional, screen-space).
  // Hold-A grab: enter targeting *before* directional nav so the nudge that triggers
  // grabStart doesn't also move the cursor to a different card in the same frame.
  if (gameOver && actions.a.grabStart) {
    MC.anim.feedbackError(view, "game_over", "");
    return null;
  }
  if (actions.a.grabStart) {
    // Mouse drag-start must originate on an actual on-screen item; otherwise ignore it.
    if (MC.ui.mouse.dragStart(actions)) {
      var pickDrag = MC.ui.mouse.pickAtPress(view, computed, actions, function (it) { return !!it; });
      if (!pickDrag) return null;
      MC.ui.cursorMoveTo(view, pickDrag);
      computed = MC.ui.computeRowModels(state, view);
      MC.ui.updateCameras(state, view, computed);
    }
    var selGrab = currentSelection();
    if (selGrab && selGrab.loc && selGrab.loc.zone === "hand" && selGrab.loc.p === 0) {
      var uidGrab = selGrab.uid;
      var defGrab = MC.state.defByUid(state, uidGrab);
      var kinds = MC.cmd.holdChainKindsForDef(defGrab);
      if (kinds) {
        MC.ui.targetingEnterHoldChain(state, view, kinds, uidGrab, selGrab.loc);
        MC.ui.mouse.dragModeEnter(view, actions);
        return null;
      }
      MC.anim.feedbackError(view, "hold_noop", "Can't do that");
      return null;
    }
  }

  var dir = null;
  if (actions.nav.up) dir = "up";
  else if (actions.nav.down) dir = "down";
  else if (actions.nav.left) dir = "left";
  else if (actions.nav.right) dir = "right";

  if (dir) {
    var pick = MC.ui.navPickInDirection(view, computed, dir);
    if (pick) {
      view.cursor.row = pick.row;
      view.cursor.i = pick.i;
    }
  }

  // Recompute after nav, then update cameras.
  computed = MC.ui.computeRowModels(state, view);
  MC.ui.updateCameras(state, view, computed);

  // Context actions on tap A.
  if (actions.a.tap) {
    // Mouse click must originate on an item; clicking empty space does nothing.
    if (MC.ui.mouse.leftTap(actions)) {
      var pickClick = MC.ui.mouse.pickAtPress(view, computed, actions, function (it) { return !!it; });
      if (!pickClick) return null;
      MC.ui.cursorMoveTo(view, pickClick);
      computed = MC.ui.computeRowModels(state, view);
      MC.ui.updateCameras(state, view, computed);
    }
    var sel = currentSelection();
    if (!sel) return null;

    // Game over: only allow Reset/Next debug buttons; everything else is a no-op with feedback blink.
    if (gameOver) {
      var allowBtn = !!(sel.row === 2 && sel.kind === "btn" && (sel.id === "mainMenu" || sel.id === "reset" || sel.id === "nextScenario"));
      if (!allowBtn) {
        MC.anim.feedbackError(view, "game_over", "");
        return null;
      }
    }

    // Center buttons.
    if (sel.row === 2 && sel.kind === "btn") {
      if (sel.disabled) {
        var msg = "Not available";
        if (sel.id === "endTurn" && state.activeP !== 0) msg = "Opponent turn";
        MC.anim.feedbackError(view, "disabled_btn", msg);

        // Move selection to next available center button (prefer Step).
        var pickNext =
          MC.ui.findBestCursorTarget(computed.models, [2], function (it) {
            return it && it.kind === "btn" && it.id === "step" && !it.disabled;
          }) ||
          MC.ui.findBestCursorTarget(computed.models, [2], function (it) {
            return it && it.kind === "btn" && !it.disabled && it.id !== "endTurn";
          }) ||
          MC.ui.findBestCursorTarget(computed.models, [2], function (it) {
            return it && (it.kind === "discard" || it.kind === "deck");
          });

        if (pickNext) {
          MC.ui.cursorMoveTo(view, pickNext);
          computed = MC.ui.computeRowModels(state, view);
          MC.ui.updateCameras(state, view, computed);
        }

        return null;
      }

      if (sel.id === "mainMenu") { setAutoFocusPauseForCenterBtn("mainMenu"); focusSnapshot(); return { kind: "mainMenu" }; }
      if (sel.id === "endTurn") { setAutoFocusPauseForCenterBtn("endTurn"); focusSnapshot(); return { kind: "applyCmd", cmd: { kind: "endTurn" } }; }
      if (sel.id === "step") { setAutoFocusPauseForCenterBtn("step"); focusSnapshot(); return { kind: "debug", action: "step" }; }
      if (sel.id === "reset") { setAutoFocusPauseForCenterBtn("reset"); focusSnapshot(); return { kind: "debug", action: "reset" }; }
      if (sel.id === "nextScenario") { setAutoFocusPauseForCenterBtn("nextScenario"); focusSnapshot(); return { kind: "debug", action: "nextScenario" }; }
      return null;
    }

    // Hand card menu (P0 only).
    if (sel.loc && sel.loc.zone === "hand" && sel.loc.p === 0) {
      MC.ui.menuOpenForSelection(state, view, sel);
      if (view.menu.items && view.menu.items.length > 0) {
        view.mode = "menu";
      } else {
        MC.ui.feedbackNoMovesLeft(state, view);
      }
    }
  }

  // If hold targeting is active and A is no longer held, auto-confirm is handled in targeting mode.

  // Keep selection anchor fresh for the next tick.
  focusSnapshot();
  return null;
};

