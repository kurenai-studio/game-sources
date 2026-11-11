// Row-model overlays: helpers for MC.ui.computeRowModels.
// Kept in a separate module to reduce nesting + keep policy localized.

MC.ui.rowModels = {};

// Strategy-style helpers: pure functions that operate on a ctx object.
// This keeps ctx construction lightweight (no per-frame closure allocation).
MC.ui.rowModels.ops = {};

MC.ui.rowModels.ops.pushOverlay = function (ctx, row0, it0) {
  if (!ctx || row0 == null) return;
  var models = ctx.models;
  var rm0 = models ? models[row0] : null;
  if (!rm0 || !rm0.overlayItems) return;
  rm0.overlayItems.push(it0);
};

MC.ui.rowModels.ops.findItemByUidLoc = function (ctx, uid, loc) {
  if (!ctx || !uid || !loc) return null;
  var models = ctx.models;
  if (!models) return null;
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
      return it;
    }
  }
  return null;
};

MC.ui.rowModels.ops.stackX = function (st, depth) {
  if (!st) return 0;
  return st.x0 + depth * st.stride * st.fanDir;
};

MC.ui.rowModels.ops.tableStack = function (ctx, setI) {
  var models = ctx ? ctx.models : null;
  var rmTable = models ? models[MC.render.ROW_P_TABLE] : null;
  var stacks = (rmTable && rmTable.stacks) ? rmTable.stacks : null;
  return stacks ? stacks["set:p0:set" + setI] : null;
};

MC.ui.rowModels.ops.slotNewSet = function (ctx) {
  var models = ctx ? ctx.models : null;
  var L = ctx ? ctx.L : null;
  var rmTable = models ? models[MC.render.ROW_P_TABLE] : null;
  var newSetX = (rmTable && rmTable.newSetX != null) ? rmTable.newSetX : (L ? L.rowPadX : 0);
  return { row: 3, x: newSetX, y: ctx ? ctx.yTable : 0, stackKey: "newSet:p0:row3", depth: 0 };
};

MC.ui.rowModels.ops.slotSetEnd = function (ctx, setI) {
  var st = MC.ui.rowModels.ops.tableStack(ctx, setI);
  if (!st) return null;
  return { row: 3, x: MC.ui.rowModels.ops.stackX(st, st.nReal), y: st.y, stackKey: "set:p0:set" + setI, depth: st.nReal };
};

MC.ui.rowModels.ops.slotSetTop = function (ctx, setI) {
  var st = MC.ui.rowModels.ops.tableStack(ctx, setI);
  if (!st || st.nReal <= 0) return null;
  return { row: 3, x: MC.ui.rowModels.ops.stackX(st, st.nReal - 1), y: st.y, stackKey: "set:p0:set" + setI, depth: st.nReal };
};

MC.ui.rowModels.ops.slotBankEnd = function (ctx) {
  var models = ctx ? ctx.models : null;
  var rmHand = models ? models[MC.render.ROW_P_HAND] : null;
  var bankSt = (rmHand && rmHand.stacks) ? rmHand.stacks["bank:p0:row4"] : null;
  if (!bankSt) return null;
  return { row: 4, x: MC.ui.rowModels.ops.stackX(bankSt, bankSt.nReal), y: bankSt.y, stackKey: "bank:p0:row4", depth: bankSt.nReal };
};

MC.ui.rowModels.ops.slotForCmd = function (ctx, cmd, srcSlot) {
  var d = MC.moves.destForCmd(cmd);
  if (!d) return null;
  if (d.kind === "newSet") return MC.ui.rowModels.ops.slotNewSet(ctx);
  if (d.kind === "setEnd") return MC.ui.rowModels.ops.slotSetEnd(ctx, d.setI);
  if (d.kind === "setTop") return MC.ui.rowModels.ops.slotSetTop(ctx, d.setI);
  if (d.kind === "bankEnd") return MC.ui.rowModels.ops.slotBankEnd(ctx);
  if (d.kind === "source") return srcSlot || null;
  return null;
};

MC.ui.rowModels.ops.pushGhost = function (ctx, slot) {
  if (!slot) return;
  MC.ui.rowModels.ops.pushOverlay(ctx, slot.row, { kind: "ghost", x: slot.x, y: slot.y, stackKey: slot.stackKey, depth: slot.depth });
};

MC.ui.rowModels.ops.setFocus = function (ctx, slot, uid, color, forCmdKind, focusSrcGhost) {
  if (!ctx || !slot) return;
  var meta = ctx.meta;
  var L = ctx.L;
  if (!meta || !L) return;
  meta.focus = {
    kind: "preview",
    row: slot.row,
    forCmdKind: forCmdKind,
    focusSrcGhost: !!focusSrcGhost,
    uid: uid,
    color: color,
    x: slot.x,
    y: slot.y,
    w: L.faceW,
    h: L.faceH,
    stackKey: slot.stackKey,
    depth: slot.depth
  };
  MC.ui.rowModels.ops.pushOverlay(ctx, slot.row, meta.focus);
};

MC.ui.rowModels.ops.previewForCmd = function (ctx, cmd, srcSlot, card) {
  if (!ctx || !cmd || !cmd.kind) return null;
  var slot = MC.ui.rowModels.ops.slotForCmd(ctx, cmd, srcSlot);
  if (!slot) return null;
  var prev = MC.cmd.previewForCmd(ctx.state, cmd, card);
  if (!prev) return null;
  return { slot: slot, uid: prev.uid, color: prev.color, forCmdKind: prev.forCmdKind, focusSrcGhost: prev.focusSrcGhost };
};

MC.ui.rowModels.ops.setFocusForCmd = function (ctx, cmd, srcSlot, card) {
  var prev = MC.ui.rowModels.ops.previewForCmd(ctx, cmd, srcSlot, card);
  if (!prev) return;
  MC.ui.rowModels.ops.setFocus(ctx, prev.slot, prev.uid, prev.color, prev.forCmdKind, prev.focusSrcGhost);
};

// Targeting overlay strategies (per action kind + per UI mode).
MC.ui.rowModels.targetingPasses = {};
MC.ui.rowModels.targetingStrategies = {
  preview: { id: "preview", passIds: ["prep", "hideSrc", "holdChainGhosts", "previewMode"] },
  cursor: { id: "cursor", passIds: ["prep", "hideSrc", "holdChainGhosts", "cursorMode"] }
};

// Optional override hook: pick a strategy per targeting kind.
// Default behavior uses cmd profile UI mode ("cursor" vs "preview").
MC.ui.rowModels.targetingStrategyByKind = {
  // sly: "cursor",
};

// Optional override hook: append extra passes per targeting kind.
// Use this for true exceptions; keep the base strategies shared.
MC.ui.rowModels.targetingExtraPassIdsByKind = {
  // place: ["someExtraPass"],
};

MC.ui.rowModels.targetingStrategyIdFor = function (kind, uiMode) {
  kind = String(kind || "");
  uiMode = String(uiMode || "");
  var byKind = MC.ui.rowModels.targetingStrategyByKind;
  if (byKind && byKind[kind]) return String(byKind[kind]);
  return (uiMode === "cursor") ? "cursor" : "preview";
};

MC.ui.rowModels.targetingPasses.prep = function (ctx, profT, uiT, uiMode) {
  var view = ctx.view;
  var models = ctx.models;
  var ops = MC.ui.rowModels.ops;

  var t = view.targeting;
  var onlyRealCmd = MC.cmd.wildSingleDestPlaceCmd(t);
  var cmds = t.cmds;
  var cmdI = MC.ui.clampI(t.cmdI, cmds.length);
  t.cmdI = cmdI;
  var cmdSel0 = (cmds && cmds.length) ? cmds[cmdI] : null;

  var isSourceSel = !!(cmdSel0 && cmdSel0.kind === "source");
  var mouseDragNoSnap = !!(t.mouse && t.mouse.dragMode && t.mouse.dragging && !t.mouse.snapped);
  var isCursorMode = (String(uiMode || "") === "cursor");

  // Find source slot in models (for hold-targeting Source destination).
  var srcX = null, srcY = null, srcRow = null;
  if (t.card && t.card.uid && t.card.loc) {
    var srcLoc = t.card.loc;
    var z = String(srcLoc.zone || "");
    if (z === "hand" || z === "recvProps") {
      var rowHand = MC.render.ROW_P_HAND;
      var rmHand = models[rowHand];
      if (rmHand && rmHand.items) {
        var hi;
        for (hi = 0; hi < rmHand.items.length; hi++) {
          var itH = rmHand.items[hi];
          if (!itH || itH.kind !== "hand" || !itH.loc) continue;
          if (itH.loc.p !== srcLoc.p) continue;
          if (String(itH.loc.zone) !== String(srcLoc.zone)) continue;
          if (itH.loc.i !== srcLoc.i) continue;
          if (itH.uid !== t.card.uid) continue;
          srcX = itH.x;
          srcY = itH.y;
          srcRow = rowHand;
          break;
        }
      }
    } else {
      // Generic fallback: locate source in current models (supports setProps moveWild targeting).
      var itSrc = ops.findItemByUidLoc(ctx, t.card.uid, srcLoc);
      if (itSrc) {
        srcX = itSrc.x;
        srcY = itSrc.y;
        srcRow = itSrc.row;
      }
    }
  }

  var srcSlot = (srcX != null && srcY != null && srcRow != null)
    ? { row: srcRow, x: srcX, y: srcY, stackKey: "overlay:src:row" + srcRow, depth: 0 }
    : null;

  ctx.tgt = {
    t: t,
    kind: String(t.kind || ""),
    cmds: cmds,
    cmdI: cmdI,
    cmdSel0: cmdSel0,
    onlyRealCmd: onlyRealCmd,
    profT: profT || null,
    uiT: uiT || null,
    uiMode: String(uiMode || ""),
    isCursorMode: isCursorMode,
    isSourceSel: isSourceSel,
    mouseDragNoSnap: mouseDragNoSnap,
    srcX: srcX,
    srcY: srcY,
    srcRow: srcRow,
    srcSlot: srcSlot
  };
};

MC.ui.rowModels.targetingPasses.hideSrc = function (ctx) {
  var meta = ctx.meta;
  var ops = MC.ui.rowModels.ops;
  if (!ctx.tgt) return;
  var t = ctx.tgt.t;

  // While targeting, hide the source card so the source slot can be represented by a ghost/preview.
  // Exception: when the selected destination is Source, show the real source card + normal highlight.
  // Mouse DnD nuance: while dragging unsnapped, keep hiding the source even if cmdI is Source,
  // otherwise the real source would duplicate against the floating card under the cursor.
  var isWildCard = !!(t.card && t.card.def && MC.rules.isWildDef(t.card.def));
  var showRealSource = !!(ctx.tgt.isSourceSel && !ctx.tgt.mouseDragNoSnap && !isWildCard);

  if (!showRealSource) if (t.card && t.card.uid && t.card.loc && (t.card.loc.zone === "hand" || t.card.loc.zone === "recvProps" || t.card.loc.zone === "setProps")) {
    meta.hideSrc = { uid: t.card.uid, loc: t.card.loc };
  }
};

MC.ui.rowModels.targetingPasses.holdChainGhosts = function (ctx) {
  var ops = MC.ui.rowModels.ops;
  if (!ctx.tgt) return;
  var t = ctx.tgt.t;
  if (!(t.chainActive && t.chainSegs && t.chainSegs.length)) return;

  var sgi;
  for (sgi = 0; sgi < t.chainSegs.length; sgi++) {
    var segG = t.chainSegs[sgi];
    if (!segG || !segG.kind || !segG.cmds) continue;
    var kindG = String(segG.kind);
    if (kindG === String(t.kind || "")) continue;
    if (kindG === "source") continue;

    var profG = MC.cmd.getProfile(kindG);
    var uiG = (profG && profG.ui) ? profG.ui : null;
    var modeG = (uiG && uiG.mode) ? String(uiG.mode) : "preview";
    if (modeG === "cursor") continue; // cursor-mode cross-ghosting handled separately (optional)

    var ciG;
    for (ciG = 0; ciG < segG.cmds.length; ciG++) {
      var cmdG = segG.cmds[ciG];
      if (!cmdG || !cmdG.kind) continue;
      ops.pushGhost(ctx, ops.slotForCmd(ctx, cmdG, ctx.tgt.srcSlot));
    }
  }
};

MC.ui.rowModels.targetingPasses.cursorMode = function (ctx) {
  var ops = MC.ui.rowModels.ops;
  if (!ctx.tgt || !ctx.tgt.isCursorMode) return;

  var t = ctx.tgt.t;
  var cmds = ctx.tgt.cmds;
  var cmdI = ctx.tgt.cmdI;
  var isDragging = !!(t.mouse && t.mouse.dragMode && t.mouse.dragging);
  var isSnapped = !!(t.mouse && t.mouse.dragMode && t.mouse.dragging && t.mouse.snapped);

  // Source slot is represented by a ghost when the real source card is hidden.
  if (ctx.meta.hideSrc && ctx.tgt.srcRow != null && ctx.tgt.srcX != null && ctx.tgt.srcY != null) {
    ops.pushOverlay(ctx, ctx.tgt.srcRow, { kind: "ghost", x: ctx.tgt.srcX, y: ctx.tgt.srcY, stackKey: "overlay:src:row" + ctx.tgt.srcRow, depth: 0 });
  }

  // Mouse DnD in cursor-mode targeting: avoid cursor highlight "sticking" to the last hovered target.
  // Instead, draw a preview highlight only while snapped.
  if (isDragging && isSnapped && cmds && cmds.length && ctx.tgt.uiT && ctx.tgt.uiT.findItemForCmd) {
    var cmdSel = cmds[cmdI];
    if (cmdSel && cmdSel.kind !== "source") {
      var ctxC2 = { state: ctx.state, view: ctx.view, computed: ctx.computed };
      var pickSel = ctx.tgt.uiT.findItemForCmd(ctxC2, cmdSel);
      if (pickSel && pickSel.item) {
        var itSel = pickSel.item;
        ops.setFocus(
          ctx,
          // Depth bump ensures the preview is drawn on top of the fanned stack.
          { row: itSel.row, x: itSel.x, y: itSel.y, stackKey: itSel.stackKey, depth: (itSel.depth != null ? itSel.depth : 0) + 1000 },
          itSel.uid,
          itSel.color != null ? itSel.color : null,
          String(cmdSel.kind || ""),
          false
        );
      }
    }
  }

  // Optional: ghost outlines for non-selected targets.
  // While mouse-dragging, keep the screen clean (no overlapping ghosts); snap-preview above is the affordance.
  var showGhosts = !!MC.config.ui.slyShowTargetGhosts && !isDragging;
  if (showGhosts && cmds && cmds.length && ctx.tgt.uiT && ctx.tgt.uiT.findItemForCmd) {
    var ctxC = { state: ctx.state, view: ctx.view, computed: ctx.computed };
    var jS;
    for (jS = 0; jS < cmds.length; jS++) {
      var cS = cmds[jS];
      if (!cS || cS.kind === "source") continue;
      if (!ctx.tgt.isSourceSel && jS === cmdI) continue;
      var pick = ctx.tgt.uiT.findItemForCmd(ctxC, cS);
      if (!pick || !pick.item) continue;
      var itT = pick.item;
      ops.pushOverlay(ctx, itT.row, { kind: "ghost", x: itT.x, y: itT.y, stackKey: itT.stackKey, depth: (itT.depth != null ? itT.depth + 100 : 100) });
    }
  }
};

MC.ui.rowModels.targetingPasses.previewMode = function (ctx) {
  var ops = MC.ui.rowModels.ops;
  if (!ctx.tgt || ctx.tgt.isCursorMode) return;

  var t = ctx.tgt.t;
  var cmds = ctx.tgt.cmds;
  var cmdI = ctx.tgt.cmdI;

  // Ghosts for all non-selected legal destinations in this targeting mode.
  var hasSourceCmd = false;
  var j;
  for (j = 0; j < cmds.length; j++) if (cmds[j] && cmds[j].kind === "source") { hasSourceCmd = true; break; }

  // When dragging but not snapped, still show a ghost at the source slot so it doesn't look like the card vanished.
  if (ctx.tgt.mouseDragNoSnap && ctx.meta.hideSrc && ctx.tgt.srcRow != null && ctx.tgt.srcX != null && ctx.tgt.srcY != null) {
    ops.pushOverlay(ctx, ctx.tgt.srcRow, { kind: "ghost", x: ctx.tgt.srcX, y: ctx.tgt.srcY, stackKey: "overlay:src:row" + ctx.tgt.srcRow, depth: 0 });
  }

  var suppressDests = !!(ctx.tgt.onlyRealCmd && ctx.tgt.isSourceSel && !ctx.tgt.mouseDragNoSnap);
  if (!suppressDests) {
    for (j = 0; j < cmds.length; j++) {
      // While dragging but not snapped, ghost *all* destinations (including the default `cmdI`)
      // so the player sees every legal drop target even before a snap occurs.
      if (!ctx.tgt.mouseDragNoSnap && j === cmdI) continue;
      var c = cmds[j];
      if (!c || !c.kind) continue;
      if (ctx.tgt.mouseDragNoSnap && c.kind === "source") continue; // source is represented by the separate source ghost above
      ops.pushGhost(ctx, ops.slotForCmd(ctx, c, ctx.tgt.srcSlot));
    }
  }

  // Preview-in-stack for selected destination. If Source is selected, rely on the real card + highlight
  // (otherwise we would double-render the same card at the same position).
  var cmdSel = cmds[cmdI];
  if (!ctx.tgt.mouseDragNoSnap && cmdSel && (cmdSel.kind !== "source" || ctx.meta.hideSrc)) {
    ops.setFocusForCmd(ctx, cmdSel, ctx.tgt.srcSlot, { uid: (t.card && t.card.uid) ? t.card.uid : 0, def: (t.card && t.card.def) ? t.card.def : null, wildColor: t.wildColor });
  }

  // If the selected destination previews the same uid elsewhere, ensure the source slot is still readable.
  // (This keeps menu-targeting and recvProps placement consistent with hold-targeting: source becomes a ghost.)
  if (
    t.card &&
    t.card.uid &&
    ctx.tgt.srcX != null &&
    ctx.tgt.srcY != null &&
    ctx.tgt.srcRow != null &&
    ctx.meta.focus &&
    (ctx.meta.focus.uid === t.card.uid || ctx.meta.focus.focusSrcGhost) &&
    !hasSourceCmd
  ) {
    ops.pushOverlay(ctx, ctx.tgt.srcRow, { kind: "ghost", x: ctx.tgt.srcX, y: ctx.tgt.srcY, stackKey: "overlay:src:row" + ctx.tgt.srcRow, depth: 0 });
  }
};

MC.ui.rowModels.applyTargetingOverlays = function (ctx) {
  var view = ctx.view;
  if (!(view.mode === "targeting" && view.targeting && view.targeting.active)) return;
  var t = view.targeting;
  var profT = MC.cmd.getProfile(t.kind);
  var uiT = (profT && profT.ui) ? profT.ui : null;
  var uiMode = (uiT && uiT.mode) ? String(uiT.mode) : "preview";

  var stratId = MC.ui.rowModels.targetingStrategyIdFor(String(t.kind || ""), uiMode);
  var strat = MC.ui.rowModels.targetingStrategies[stratId] || MC.ui.rowModels.targetingStrategies.preview;
  if (!strat || !strat.passIds) return;

  var passes = MC.ui.rowModels.targetingPasses;
  var i;
  for (i = 0; i < strat.passIds.length; i++) {
    var pid = strat.passIds[i];
    var fn = passes[pid];
    if (!fn) continue;
    fn(ctx, profT, uiT, uiMode);
  }

  var byKind = MC.ui.rowModels.targetingExtraPassIdsByKind;
  var extra = (byKind && byKind[String(t.kind || "")]) ? byKind[String(t.kind || "")] : null;
  if (extra && extra.length) {
    for (i = 0; i < extra.length; i++) {
      var pidE = extra[i];
      var fnE = passes[pidE];
      if (!fnE) continue;
      fnE(ctx, profT, uiT, uiMode);
    }
  }
};

MC.ui.rowModels.applyMenuHoverPreview = function (ctx) {
  var state = ctx.state;
  var view = ctx.view;
  var hint = ctx.hint;
  var models = ctx.models;
  var meta = ctx.meta;

  var ops = MC.ui.rowModels.ops;
  var pushOverlay = ops.pushOverlay;
  var findItemByUidLoc = ops.findItemByUidLoc;
  var setFocus = ops.setFocus;
  var setFocusForCmd = ops.setFocusForCmd;

  // Menu-hover destination preview (only when unambiguous).
  if (meta.focus) return;
  if (!(view.mode === "menu" && view.menu && view.menu.items && view.menu.items.length > 0 && view.menu.src)) return;

  var srcM = view.menu.src;
  var uidM = (srcM && srcM.uid) ? srcM.uid : 0;
  var cm = (hint && hint.menuHoverCmd) ? hint.menuHoverCmd : null;
  if (uidM && cm) {
    if (cm.kind === "playSlyDeal" && cm.target && cm.target.loc) {
      // Cursor-mode menu hover preview: highlight the (single) target and ghost the source card.
      var itT = findItemByUidLoc(ctx, cm.target.uid, cm.target.loc);
      // Reuse preview overlay to get the standard yellow highlight (no new overlay kinds).
      if (itT) {
        var slotT = { row: itT.row, x: itT.x, y: itT.y, stackKey: itT.stackKey, depth: (itT.depth != null ? itT.depth + 100 : 100) };
        setFocus(ctx, slotT, cm.target.uid, null, "playSlyDeal", false);
      }

      if (srcM.uid && srcM.loc && (srcM.loc.zone === "hand" || srcM.loc.zone === "recvProps")) {
        meta.hideSrc = { uid: srcM.uid, loc: srcM.loc };
        var rowHandS = MC.render.ROW_P_HAND;
        var rmHandS = models[rowHandS];
        if (rmHandS && rmHandS.items) {
          var hiS;
          for (hiS = 0; hiS < rmHandS.items.length; hiS++) {
            var itHS = rmHandS.items[hiS];
            if (!itHS || itHS.kind !== "hand" || !itHS.loc) continue;
            if (itHS.uid !== uidM) continue;
            if (itHS.loc.p !== srcM.loc.p) continue;
            if (String(itHS.loc.zone) !== String(srcM.loc.zone)) continue;
            if (itHS.loc.i !== srcM.loc.i) continue;
            pushOverlay(ctx, rowHandS, { kind: "ghost", x: itHS.x, y: itHS.y, stackKey: "overlay:menuSrc:row" + rowHandS, depth: 0 });
            break;
          }
        }
      }
    } else {
      var defM = MC.state.defByUid(state, uidM);
      setFocusForCmd(ctx, cm, null, { uid: uidM, def: defM, wildColor: (defM && MC.rules.isWildDef(defM)) ? cm.color : null });
    }
  }

  // When menu hover produces a preview of the same uid (or Rent preview where the preview card differs),
  // ghost the source slot so it doesn't look duplicated.
  if (meta.focus && uidM && srcM && srcM.loc && (meta.focus.uid === uidM || meta.focus.focusSrcGhost)) {
    if (srcM.uid && srcM.loc && (srcM.loc.zone === "hand" || srcM.loc.zone === "recvProps")) {
      meta.hideSrc = { uid: srcM.uid, loc: srcM.loc };
    }
    var rowHandM = MC.render.ROW_P_HAND;
    var rmHandM = models[rowHandM];
    if (rmHandM && rmHandM.items) {
      var hiM;
      for (hiM = 0; hiM < rmHandM.items.length; hiM++) {
        var itHM = rmHandM.items[hiM];
        if (!itHM || itHM.kind !== "hand" || !itHM.loc) continue;
        if (itHM.uid !== uidM) continue;
        if (itHM.loc.p !== srcM.loc.p) continue;
        if (String(itHM.loc.zone) !== String(srcM.loc.zone)) continue;
        if (itHM.loc.i !== srcM.loc.i) continue;
        pushOverlay(ctx, rowHandM, { kind: "ghost", x: itHM.x, y: itHM.y, stackKey: "overlay:menuSrc:row" + rowHandM, depth: 0 });
        break;
      }
    }
  }
};

MC.ui.rowModels.applyPromptOverlays = function (ctx) {
  var state = ctx.state;
  var sel = ctx.sel;

  var ops = MC.ui.rowModels.ops;
  var pushOverlay = ops.pushOverlay;
  var findItemByUidLoc = ops.findItemByUidLoc;

  // RespondAction prompt: keep a ghost outline on the forced target when cursor is away.
  var pr = state ? state.prompt : null;
  if (pr && pr.kind === "respondAction" && pr.p === 0 && pr.target && pr.target.loc) {
    var tgt = pr.target;
    var onTarget = false;
    if (sel && sel.loc) {
      onTarget = MC.ui.itemMatchesUidLoc(sel, tgt.uid, tgt.loc);
    }
    if (!onTarget) {
      var itT2 = findItemByUidLoc(ctx, tgt.uid, tgt.loc);
      if (itT2) {
        pushOverlay(ctx, itT2.row, { kind: "ghost", x: itT2.x, y: itT2.y, stackKey: itT2.stackKey, depth: (itT2.depth != null ? itT2.depth + 100 : 100) });
      }
    }
  }
};

MC.ui.rowModels.applyPayBufOverlay = function (ctx) {
  var state = ctx.state;
  var view = ctx.view;
  var models = ctx.models;
  var L = ctx.L;

  // Visualize the pay/transfer buffer as a non-selectable center-row stack.
  // - During payDebt: show prompt.buf (what has been committed so far).
  // - While draining: show view.anim.payBufUids even after the prompt clears.
  var pr = state ? state.prompt : null;
  var payBufUids = null;
  if (pr && pr.kind === "payDebt" && pr.buf && pr.buf.length > 0) {
    payBufUids = pr.buf.slice();
  } else if (view.anim.payBufUids.length > 0) {
    payBufUids = view.anim.payBufUids.slice();
  }

  if (payBufUids && payBufUids.length > 0) {
    var rowCenter2 = MC.render.ROW_CENTER;
    var rmCenter2 = models[rowCenter2];
    if (rmCenter2 && rmCenter2.overlayItems) {
      var topC = L.rowY[rowCenter2] + L.centerTopInsetY;
      rmCenter2.overlayItems.push({
        kind: "payBuf",
        row: rowCenter2,
        x: L.centerPayBufX,
        y: topC,
        w: L.faceW,
        h: L.faceH,
        uids: payBufUids,
        nVis: payBufUids.length
      });
    }
  }
};

MC.ui.rowModels.applyOverlays = function (ctx) {
  MC.ui.rowModels.applyTargetingOverlays(ctx);
  MC.ui.rowModels.applyMenuHoverPreview(ctx);
  MC.ui.rowModels.applyPromptOverlays(ctx);
  MC.ui.rowModels.applyPayBufOverlay(ctx);
};

MC.ui.rowModels.buildCtx = function (state, view, hint, models, meta, sel) {
  var computed = { models: models, selected: sel, meta: meta };
  return {
    state: state,
    view: view,
    hint: hint,
    models: models,
    meta: meta,
    sel: sel,
    computed: computed,
    L: MC.config.render.layout,
    yTable: MC.layout.faceYForRow(3)
  };
};

MC.ui.computeRowModels = function (state, view) {
  var hint = MC.ui.layoutHint(state, view);
  var models = [
    MC.ui.buildRowItems(state, view, 0, hint),
    MC.ui.buildRowItems(state, view, 1, hint),
    MC.ui.buildRowItems(state, view, 2, hint),
    MC.ui.buildRowItems(state, view, 3, hint),
    MC.ui.buildRowItems(state, view, 4, hint)
  ];

  // Render overlays (ghosts/previews) live alongside row models, not in the renderer.
  var ri;
  for (ri = 0; ri < models.length; ri++) models[ri].overlayItems = [];

  // Small render meta so the renderer doesn't have to rediscover intent.
  var meta = { hideSrc: null, focus: null };

  // Clamp cursor to existing rows/items.
  if (!view || !view.cursor) return { models: models, selected: null, meta: meta };
  var row = view.cursor.row;
  if (row < 0) row = 0;
  if (row > 4) row = 4;
  view.cursor.row = row;

  var rm = models[row];
  var n = (rm && rm.items) ? rm.items.length : 0;
  view.cursor.i = MC.ui.clampI(view.cursor.i, n);

  var sel = (rm && rm.items && rm.items.length) ? rm.items[view.cursor.i] : null;

  // Note: cursor relocation off empty selections is handled by MC.ui.focus.preserve().
  var ctx = MC.ui.rowModels.buildCtx(state, view, hint, models, meta, sel);
  MC.ui.rowModels.applyOverlays(ctx);
  var computed = MC.anim.present(state, view, ctx.computed) || ctx.computed;

  // Snapshot last-seen screen-space positions for transfer animations.
  if (view && view.anim && view.anim.lastPosByUid && computed && computed.models) {
    var posByUid = view.anim.lastPosByUid;
    var k;
    for (k in posByUid) delete posByUid[k];

    var row;
    for (row = 0; row < computed.models.length; row++) {
      var rmSnap = computed.models[row];
      if (!rmSnap || !rmSnap.items) continue;
      var camSnap = (view.camX && view.camX[row] != null) ? view.camX[row] : 0;
      var iSnap;
      for (iSnap = 0; iSnap < rmSnap.items.length; iSnap++) {
        var itSnap = rmSnap.items[iSnap];
        if (!itSnap || !itSnap.uid) continue;
        posByUid[itSnap.uid] = { x: (itSnap.x - camSnap), y: itSnap.y, row: row };
      }
    }
  }

  return computed;
};

