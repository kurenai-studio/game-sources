// MC.ui.mouse: mouse-specific UI adapter helpers (hit-testing + mode helpers).
MC.ui.mouse = {};

MC.ui.mouse._cfg = function () {
  return MC.config.mouse;
};

MC.ui.mouse._m = function (actions) {
  return (actions && actions.mouse) ? actions.mouse : null;
};

MC.ui.mouse.isAvail = function (actions) {
  var cfg = MC.ui.mouse._cfg();
  var m = MC.ui.mouse._m(actions);
  return !!(cfg.enabled && m && m.avail);
};

MC.ui.mouse.leftTap = function (actions) {
  var m = MC.ui.mouse._m(actions);
  return !!(m && m.avail && m.left && m.left.tap);
};

MC.ui.mouse.leftReleased = function (actions) {
  var m = MC.ui.mouse._m(actions);
  return !!(m && m.avail && m.left && m.left.released);
};

MC.ui.mouse.dragStart = function (actions) {
  var m = MC.ui.mouse._m(actions);
  return !!(m && m.avail && m.dragStart);
};

MC.ui.mouse.pressPos = function (actions) {
  var m = MC.ui.mouse._m(actions);
  if (!m || !m.avail) return { x: 0, y: 0 };
  var x = (m.pressX != null) ? m.pressX : m.x;
  var y = (m.pressY != null) ? m.pressY : m.y;
  if (!isFinite(x)) x = 0;
  if (!isFinite(y)) y = 0;
  return { x: x, y: y };
};

MC.ui.mouse.pointerPos = function (actions) {
  var m = MC.ui.mouse._m(actions);
  if (!m || !m.avail) return { x: 0, y: 0 };
  var x = m.x;
  var y = m.y;
  if (!isFinite(x)) x = 0;
  if (!isFinite(y)) y = 0;
  return { x: x, y: y };
};

MC.ui.mouse.shouldHoverPick = function (actions) {
  var cfg = MC.ui.mouse._cfg();
  if (!cfg.enabled || !cfg.hoverSelect) return false;
  var m = MC.ui.mouse._m(actions);
  if (!m || !m.avail) return false;
  if (m.left && m.left.pressed) return true;
  if (m.moved && !(m.left && m.left.down)) return true;
  return false;
};

MC.ui.mouse.usedNow = function (actions) {
  var m = MC.ui.mouse._m(actions);
  if (!m || !m.avail) return false;
  return !!(
    m.moved ||
    m.scrollX ||
    m.scrollY ||
    m.dragStart ||
    m.dragging ||
    (m.left && (m.left.down || m.left.pressed || m.left.released || m.left.tap)) ||
    (m.right && (m.right.down || m.right.pressed || m.right.released)) ||
    (m.middle && (m.middle.down || m.middle.pressed || m.middle.released))
  );
};

// Latch autofocus pause while using the mouse, so hover-driven selection doesn't fight
// controller-first autofocus rules. Clear the latch when controller input happens.
MC.ui.mouse.syncAutoFocusPause = function (view, actions) {
  if (!view || !view.ux) return;
  var cfg = MC.ui.mouse._cfg();
  if (!cfg.enabled) { view.ux.autoFocusPausedByMouse = false; return; }
  var m = MC.ui.mouse._m(actions);
  var mAvail = !!(m && m.avail);
  // Important: when the debug harness suppresses player input (AI turn), it passes emptyActions()
  // which sets mouse.avail=false. Don't clear the latch in that case; keep "last input wins"
  // semantics until controller input happens.
  if (!mAvail) {
    var nav0 = actions.nav;
    var a0 = actions.a;
    var hasNav0 = !!(nav0 && (nav0.up || nav0.down || nav0.left || nav0.right));
    var hasA0 = !!(a0 && (a0.tap || a0.grabStart));
    var hasB0 = !!(actions.b && actions.b.pressed);
    if (hasNav0 || hasA0 || hasB0) view.ux.autoFocusPausedByMouse = false;
    return;
  }

  var nav = actions.nav;
  var a = actions.a;
  var hasNav = !!(nav && (nav.up || nav.down || nav.left || nav.right));
  var hasA = !!(a && (a.tap || a.grabStart));

  // Nav pulses may be synthesized from the wheel.
  var navFromMouse = !!(hasNav && mAvail && (m.scrollX || m.scrollY));

  // A tap/grabStart may come from the mouse (left tap / dragStart).
  var aFromMouse = false;
  if (hasA && mAvail) {
    if (a.tap && m.left && m.left.tap) aFromMouse = true;
    else if (a.grabStart && m.dragStart) aFromMouse = true;
  }

  // B pressed may come from the mouse (right click).
  var bFromMouse = !!(mAvail && m.right && m.right.pressed);

  var controllerUsed = !!((hasNav && !navFromMouse) || (hasA && !aFromMouse) || (actions.b && actions.b.pressed && !bFromMouse));
  if (controllerUsed) { view.ux.autoFocusPausedByMouse = false; return; }
  if (MC.ui.mouse.usedNow(actions)) view.ux.autoFocusPausedByMouse = true;
};

MC.ui.mouse.resetTargeting = function (t) {
  var tm = t.mouse;
  tm.active = false;
  tm.dragMode = false;
  tm.dragging = false;
  tm.x = 0;
  tm.y = 0;
  tm.snapped = false;
  tm.leftSource = false;
};

MC.ui.mouse.pickAtPress = function (view, computed, actions, predicate) {
  if (!MC.ui.mouse.isAvail(actions)) return null;
  var p = MC.ui.mouse.pressPos(actions);
  return MC.ui.pickItemAtScreen(view, computed, p.x, p.y, predicate || function () { return true; });
};

MC.ui.mouse.pickAtPointer = function (view, computed, actions, predicate) {
  if (!MC.ui.mouse.isAvail(actions)) return null;
  var p = MC.ui.mouse.pointerPos(actions);
  return MC.ui.pickItemAtScreen(view, computed, p.x, p.y, predicate || function () { return true; });
};

MC.ui.mouse.menuTick = function (view, actions) {
  var cfg = MC.ui.mouse._cfg();
  if (!cfg.enabled || !cfg.hoverSelect) return false;
  var m = MC.ui.mouse._m(actions);
  if (!m || !m.avail) return false;
  if (!view || view.mode !== "menu" || !view.menu || !view.menu.items || view.menu.items.length <= 0) return false;

  var items = view.menu.items;
  var C = MC.render.center;
  var L = MC.config.render.layout;
  var xDesc = C.desc.x;
  var yDesc = C.desc.y;
  var yBase = yDesc - 1;
  var boxX = xDesc - 2;
  var boxY = yBase - 2;
  var boxW = L.screenW - boxX - L.rowPadX;
  var y0 = L.rowY[MC.render.ROW_CENTER];
  var y1 = y0 + L.rowH[MC.render.ROW_CENTER] - 1;
  var hintY = y1 - 7;
  var boxH = (items.length * 7 + 10);
  var maxH = (hintY - 2) - boxY;
  if (maxH > 0 && boxH > maxH) boxH = maxH;
  if (boxH < 16) boxH = 16;

  var inBox = (m.x >= boxX && m.x <= (boxX + boxW - 1) && m.y >= boxY && m.y <= (boxY + boxH - 1));
  if (m.moved || (m.left && m.left.pressed)) {
    if (inBox) {
      var j = Math.floor((m.y - yBase) / 7);
      if (j < 0) j = 0;
      if (j >= items.length) j = items.length - 1;
      view.menu.i = j;
    }
  }

  // Mouse click outside closes the menu.
  if (MC.ui.mouse.leftTap(actions) && !inBox) {
    view.mode = "browse";
    view.menu.items = [];
    return true;
  }

  return false;
};

MC.ui.mouse.applyTargeting = function (state, view, computed, actions) {
  var cfg = MC.ui.mouse._cfg();
  if (!cfg.enabled) return false;
  var m = MC.ui.mouse._m(actions);
  if (!m || !m.avail) return false;
  if (!view || view.mode !== "targeting") return false;
  var t = view.targeting;
  if (!t || !t.active) return false;
  if (!t.mouse) return false;

  var usedNow = !!(m.moved || m.scrollX || m.scrollY || (m.left && (m.left.down || m.left.pressed || m.left.released)) || (m.right && m.right.pressed));
  if (!usedNow) return false;

  t.mouse.active = true;
  t.mouse.x = m.x;
  t.mouse.y = m.y;
  t.mouse.dragging = !!(t.mouse.dragMode && m.dragging);
  t.mouse.snapped = false;

  function pointInRect(x, y, r) {
    return !!(r && x >= r.x0 && x <= r.x1 && y >= r.y0 && y <= r.y1);
  }

  function segIsCursorMode(kind) {
    var prof = MC.cmd.getProfile(kind);
    var ui = (prof && prof.ui) ? prof.ui : null;
    return !!(ui && String(ui.mode || "") === "cursor");
  }

  function newSetRectForP(p, pad) {
    var row = (p === 0) ? MC.render.ROW_P_TABLE : MC.render.ROW_OP_TABLE;
    var rm = computed.models[row];
    if (!rm || rm.newSetX == null) return null;
    var L = MC.config.render.layout;
    var cam = (view.camX && view.camX[row] != null) ? view.camX[row] : 0;
    var x0 = rm.newSetX - cam - pad;
    var y0 = MC.layout.faceYForRow(row) - pad;
    return { x0: x0, y0: y0, x1: x0 + L.faceW - 1 + 2 * pad, y1: y0 + L.faceH - 1 + 2 * pad };
  }

  function rectForCmdPreview(cmd, pad) {
    var d = MC.moves.destForCmd(cmd);
    if (!d) return null;
    if (d.kind === "newSet") return newSetRectForP(d.p, pad);
    if (d.kind === "bankEnd") {
      var rowB = (d.p === 0) ? MC.render.ROW_P_HAND : MC.render.ROW_OP_HAND;
      var keyB = "bank:p" + d.p + ":row" + rowB;
      return MC.ui.stackRectForKey(view, computed, rowB, keyB, pad);
    }
    if (d.kind === "setEnd" || d.kind === "setTop") {
      var rowS = (d.p === 0) ? MC.render.ROW_P_TABLE : MC.render.ROW_OP_TABLE;
      var keyS = "set:p" + d.p + ":set" + d.setI;
      return MC.ui.stackRectForKey(view, computed, rowS, keyS, pad);
    }
    if (d.kind === "source") {
      if (t.card && t.card.uid && t.card.loc) {
        var pickS = MC.ui.findItemByUidLoc(computed.models, t.card.uid, t.card.loc);
        if (pickS && pickS.item) return MC.ui.itemScreenRect(view, pickS.item, pad);
      }
    }
    return null;
  }

  function rectForCmdCursor(kind, cmd, pad) {
    var prof = MC.cmd.getProfile(kind);
    var ui = (prof && prof.ui) ? prof.ui : null;
    if (!ui || !ui.findItemForCmd) return null;
    var pick = ui.findItemForCmd({ state: state, view: view, computed: computed }, cmd);
    if (!pick || !pick.item) return null;
    return MC.ui.itemScreenRect(view, pick.item, pad);
  }

  var pad = (cfg.snapPadPx != null) ? cfg.snapPadPx : 0;
  if (!isFinite(pad) || pad < 0) pad = 0;

  // Source snap-back latch: do not allow snapping to Source until the pointer has
  // left the source area at least once after entering drag mode.
  if (t.mouse && t.mouse.dragMode && t.mouse.dragging && !t.mouse.leftSource) {
    var rSrcLeave = rectForCmdPreview({ kind: "source" }, pad);
    if (rSrcLeave && !pointInRect(m.x, m.y, rSrcLeave)) t.mouse.leftSource = true;
  }

  function pickCmdInSeg(kind, cmds) {
    if (!cmds || cmds.length === 0) return null;
    var isCursor = segIsCursorMode(kind);

    var i;
    for (i = 0; i < cmds.length; i++) {
      var c = cmds[i];
      if (!c || !c.kind) continue;
      // In drag mode, allow Source snapping only after leaving the source once.
      if (t.mouse && t.mouse.dragMode && c.kind === "source" && !t.mouse.leftSource) continue;
      var r = isCursor ? rectForCmdCursor(kind, c, pad) : rectForCmdPreview(c, pad);
      if (!r) continue;
      if (pointInRect(m.x, m.y, r)) return i;
    }
    return null;
  }

  function chainSetSeg(segI, cmdI) {
    if (!t.chainSegs || t.chainSegs.length === 0) return false;
    segI = MC.ui.wrapI(segI, t.chainSegs.length);
    var seg = t.chainSegs[segI];
    if (!seg || !seg.cmds || seg.cmds.length === 0) return false;

    // Persist current selection.
    var curSeg = t.chainSegs[MC.ui.clampI(t.chainI, t.chainSegs.length)];
    if (curSeg) curSeg.cmdI = t.cmdI;

    t.chainI = segI;
    t.kind = String(seg.kind || "");
    t.cmds = seg.cmds;
    t.cmdI = MC.ui.clampI(cmdI, seg.cmds.length);
    seg.cmdI = t.cmdI;
    t._profileSorted = false;
    t._profileSyncCmdI = -1;

    // Entering non-cursor segments should snap cursor back to the source selection.
    if (!segIsCursorMode(t.kind) && t.srcCursor) {
      view.cursor.row = t.srcCursor.row;
      view.cursor.i = t.srcCursor.i;
    }

    return true;
  }

  if (t.chainActive && t.chainSegs && t.chainSegs.length) {
    var si;
    for (si = 0; si < t.chainSegs.length; si++) {
      var seg = t.chainSegs[si];
      if (!seg || !seg.cmds) continue;
      var kind = String(seg.kind || "");
      var ci = pickCmdInSeg(kind, seg.cmds);
      if (ci == null) continue;
      chainSetSeg(si, ci);
      t.mouse.snapped = true;
      return true;
    }
    return true;
  }

  // Non-chain targeting: update cmdI if the pointer is over a destination/target.
  var ci2 = pickCmdInSeg(String(t.kind || ""), t.cmds);
  if (ci2 != null) {
    t.cmdI = MC.ui.clampI(ci2, t.cmds.length);
    t._profileSyncCmdI = -1;
    t.mouse.snapped = true;
  }
  return true;
};

MC.ui.mouse.dragModeEnter = function (view, actions) {
  if (!view || !view.targeting || !view.targeting.mouse) return false;
  if (!MC.ui.mouse.isAvail(actions)) return false;
  if (!MC.ui.mouse.dragStart(actions)) return false;
  var m = MC.ui.mouse._m(actions);
  view.targeting.mouse.active = true;
  view.targeting.mouse.dragMode = true;
  view.targeting.mouse.dragging = !!(m && m.dragging);
  view.targeting.mouse.x = m ? m.x : 0;
  view.targeting.mouse.y = m ? m.y : 0;
  view.targeting.mouse.snapped = false;
  view.targeting.mouse.leftSource = false;
  view.targeting.hintMode = "mouseDrag";
  return true;
};

