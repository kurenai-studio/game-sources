// MC.debug: dev harness (scenario cycling/reset/step) + main tick wiring for playtesting.
MC.debug.scenarioI = 0;
MC.debug.scenarios = ["default"].concat(MC.scenarios.IDS);
MC.debug.state = null;
MC.debug.view = MC.ui.newView();
MC.debug.ctrl = MC.controls.newState();
MC.debug.ai = { wait: 0 };
MC.debug.lastCmd = "";
MC.debug.lastEvents = [];
MC.debug.lastRaw = null;
MC.debug.lastUiIntentSummary = "";

MC.debug.reset = function (opts) {
  var d = MC.debug;
  var keepPrevPause = !(opts && opts.keepPrevAutoFocusPause === false);
  var prevPaused = keepPrevPause ? !!d.view.ux.autoFocusPausedByDebug : false;
  var shouldPause = !!(opts && opts.pauseAutoFocus) || prevPaused;
  var skipGameStartAnim = !!(opts && opts.skipGameStartAnim);
  var seedU32 = MC.seed.computeSeedU32();
  var scenarioId = d.scenarios[d.scenarioI];
  if (scenarioId === "default") {
    d.state = MC.state.newGame({ seedU32: seedU32 });
  } else {
    d.state = MC.state.newGame({ seedU32: seedU32, scenarioId: scenarioId });
  }
  d.view = MC.ui.newView();
  if (shouldPause) d.view.ux.autoFocusPausedByDebug = true;
  // Default newGame starts in the final 5/7 state; animate the initial deal.
  // Skip scenarios so resets stay fast and deterministic for debugging.
  if (scenarioId === "default" && !skipGameStartAnim) MC.anim.beginGameStart(d.state, d.view);
  d.ctrl = MC.controls.newState();
  d.ai = { wait: 0 };
  d.lastCmd = "";
  d.lastEvents = [];
  d.lastRaw = null;
  d.lastUiIntentSummary = "";
};

MC.debug.startNewGame = function () {
  var d = MC.debug;
  d.scenarioI = 0;
  MC.debug.reset({ keepPrevAutoFocusPause: false });
};

MC.debug.nextScenario = function () {
  var d = MC.debug;
  d.scenarioI = (d.scenarioI + 1) % d.scenarios.length;
  MC.debug.reset({ pauseAutoFocus: true });

  // Keep cursor on Next after switching scenarios (debug harness ergonomics).
  var view = d.view;
  var state = d.state;
  if (view && state && MC.ui && MC.render) {
    var computed = MC.ui.computeRowModels(state, view);
    MC.ui.updateCameras(state, view, computed);
    computed = MC.ui.computeRowModels(state, view);
    var pick = MC.ui.findBestCursorTarget(computed.models, [MC.render.ROW_CENTER], function (it) {
      return it && it.kind === "btn" && it.id === "nextScenario" && !it.disabled;
    });
    if (pick) MC.ui.cursorMoveTo(view, pick);
  }
};

MC.debug.step = function () {
  var d = MC.debug;
  var state = d.state;
  var moves = MC.engine.legalMoves(state);
  var p = MC.ai.actor(state);
  var policy = MC.ai.policyForP(p);
  var cmd = MC.ai.pickMove(state, moves, policy);
  if (!cmd) return;

  var res = MC.engine.applyCommand(state, cmd);
  d.lastCmd = cmd.kind;
  d.lastEvents = (res && res.events) ? res.events : [];
};

MC.debug.eventsToLine = function (events) {
  if (!events || events.length === 0) return "(none)";
  var parts = [];
  var i;
  for (i = 0; i < events.length; i++) {
    parts.push(events[i].kind);
  }
  return parts.join(",");
};

MC.debug.tickTextMode = function () {
  var d = MC.debug;

  // A: step, B: next scenario, X: reset
  if (btnp(4)) MC.debug.step();
  if (btnp(5)) MC.debug.nextScenario();
  if (btnp(6)) MC.debug.reset({ pauseAutoFocus: true });

  var s = d.state;

  function printSmall(msg, x, y, col) {
    if (col == null) col = 12;
    // smallfont=true and fixed=true keeps layout predictable.
    print(String(msg || ""), x, y, col, true, 1, true);
  }

  function bool01(v) { return v ? 1 : 0; }

  cls(0);
  var x = 0;
  var y = 6;
  var step = 6;
  var xR = 120;

  printSmall("Debug", x, y, 12); y += step;
  var sid = d.scenarios[d.scenarioI];
  var info = (MC.scenarios.INFO && sid) ? MC.scenarios.INFO[String(sid)] : null;
  var title = (info && info.title) ? String(info.title) : String(sid);
  printSmall("Scn:" + title, x, y, 12); y += step;
  var pendingDesc = (info && info.desc) ? String(info.desc) : "";
  printSmall("Seed:" + MC.seed.computeSeedU32(), x, y, 12); y += step;

  if (MC.render && MC.render.debug && typeof MC.render.debug.selectedLines === "function") {
    var sel = MC.render.debug.selectedLines(d);
    if (sel && sel.length) {
      printSmall(sel[0] || "", x, y, 12); y += step;
      if (sel[1]) { printSmall(sel[1], x, y, 12); y += step; }
    }
  }

  printSmall("Active:P" + s.activeP + " Plays:" + s.playsLeft, x, y, 12); y += step;
  printSmall((function (state) {
    if (!state) return "Prompt:(none)";
    var pr = state.prompt;
    if (!pr || !pr.kind) return "Prompt:(none)";
    var k = String(pr.kind);

    if (k === "payDebt") {
      var rem = pr.rem;
      var bufN = (pr.buf && pr.buf.length) ? pr.buf.length : 0;
      return "Prompt:payDebt rem:$" + rem + " buf:" + bufN;
    }

    if (k === "placeReceived") {
      var uN = (pr.uids && pr.uids.length) ? pr.uids.length : 0;
      return "Prompt:placeRecv n:" + uN;
    }

    if (k === "discardDown") {
      var p = pr.p;
      var hand = (state.players && state.players[p] && state.players[p].hand) ? state.players[p].hand : [];
      var handLen = hand.length;
      var nDiscarded = pr.nDiscarded;
      // Stable target count: initialHand - HAND_MAX.
      var nToDiscard = (handLen + nDiscarded) - MC.state.HAND_MAX;
      if (nToDiscard < 0) nToDiscard = 0;
      var left = handLen - MC.state.HAND_MAX;
      if (left < 0) left = 0;
      return "Prompt:discardDown to:" + nToDiscard + " left:" + left;
    }

    return "Prompt:" + k;
  })(s), x, y, 12); y += step;
  var w = s.winnerP;
  if (w !== MC.state.NO_WINNER) { printSmall("Winner:P" + w, x, y, 11); y += step; }

  printSmall("Deck:" + s.deck.length + " Disc:" + s.discard.length, x, y, 12); y += step;
  printSmall("Hand0/1:" + s.players[0].hand.length + "/" + s.players[1].hand.length, x, y, 12); y += step;
  printSmall(
    "Bank0/1:" +
    s.players[0].bank.length + "($" + MC.util.bankValueTotal(s, 0) + ")/" +
    s.players[1].bank.length + "($" + MC.util.bankValueTotal(s, 1) + ")",
    x,
    y,
    12
  ); y += step;
  printSmall("Sets0/1:" + s.players[0].sets.length + "/" + s.players[1].sets.length, x, y, 12); y += step;

  var moves = MC.engine.legalMoves(s);
  printSmall("Legal:" + moves.length, x, y, 12); y += step;
  printSmall("LastCmd:" + (d.lastCmd || "(none)"), x, y, 12); y += step;
  printSmall("Events:" + MC.debug.eventsToLine(d.lastEvents), x, y, 12); y += step;

  // Long focus rule ids don't fit well in the right column; render them full-width here.
  var vFocus = d.view;
  if (vFocus && vFocus.ux && vFocus.ux.lastFocusRuleId) {
    printSmall("FocusRule:" + String(vFocus.ux.lastFocusRuleId), x, y, 12); y += step;
  }

  // Render scenario description after Events so it doesn't overlap the right UI column.
  if (pendingDesc) {
    var lines = (function (txt, maxChars) {
      txt = String(txt || "");
      maxChars = maxChars || 55;
      if (!txt) return [];

      // Preserve explicit newlines, but word-wrap within each paragraph.
      var paras = txt.split("\n");
      var out = [];
      var pi;
      for (pi = 0; pi < paras.length; pi++) {
        var p = String(paras[pi] || "").trim();
        if (!p) { out.push(""); continue; }

        var words = p.split(/\s+/);
        var line = "";
        var wi;
        for (wi = 0; wi < words.length; wi++) {
          var w = words[wi];
          if (!w) continue;
          if (!line) { line = w; continue; }
          if ((line.length + 1 + w.length) <= maxChars) {
            line += " " + w;
          } else {
            out.push(line);
            line = w;
          }
        }
        if (line) out.push(line);
      }
      return out;
    })(pendingDesc, 55);
    var li;
    for (li = 0; li < lines.length; li++) {
      if (lines[li]) printSmall(lines[li], x, y, 13);
      y += step;
    }
  }

  // Right column: UI snapshot (from last Render-mode tick).
  var v = d.view;
  var yR = 6;
  if (v) {
    var isDragging = !!(v.mode === "targeting" && v.targeting && v.targeting.active && v.targeting.hold);
    printSmall("UI:" + String(v.mode || "?") + " I:" + bool01(v.inspectActive) + " Drag:" + bool01(isDragging), xR, yR, 12); yR += step;
    if (v.cursor) printSmall("Cur:r" + v.cursor.row + " i" + v.cursor.i, xR, yR, 12);
    yR += step;

    if (v.ux) {
      var a = v.ux.selAnchor;
      if (a) {
        var zone = (a.loc && a.loc.zone) ? String(a.loc.zone) : "?";
        var head = "Anchor:";
        if (a.uid != null && a.uid !== 0) head += "uid" + String(a.uid);
        else if (a.id) head += String(a.id);
        else if (a.kind) head += String(a.kind);
        else head += "?";
        printSmall(head + " " + zone, xR, yR, 12); yR += step;
      }
      if (v.ux.pendingFocusErrorCode) {
        printSmall("FocusErr:" + String(v.ux.pendingFocusErrorCode), xR, yR, 12); yR += step;
      }
    }

    if (v.mode === "menu" && v.menu && v.menu.items) {
      var nM = v.menu.items.length;
      var mi = (nM > 0) ? MC.ui.clampI(v.menu.i, nM) : 0;
      var it = (nM > 0) ? v.menu.items[mi] : null;
      var id = it ? String(it.id || "?") : "(none)";
      printSmall("Menu:" + mi + "/" + nM + " " + id, xR, yR, 12); yR += step;
    }

    if (v.mode === "targeting" && v.targeting && v.targeting.active) {
      var t = v.targeting;
      var nC = (t.cmds && t.cmds.length) ? t.cmds.length : 0;
      var ci = (nC > 0) ? MC.ui.clampI(t.cmdI, nC) : 0;
      printSmall("Tgt:" + String(t.kind || "?") + " " + ci + "/" + nC + " h:" + bool01(t.hold), xR, yR, 12); yR += step;
    }

    if (v.mode === "prompt" && s.prompt && s.prompt.kind) {
      printSmall("Prompt:" + String(s.prompt.kind), xR, yR, 12); yR += step;
    }
  } else {
    printSmall("UI:(no view)", xR, yR, 12); yR += step;
  }

  // Inputs/state (favor persistent states over one-frame pulses).
  var raw0 = d.lastRaw;
  var down0 = raw0 && raw0.down ? raw0.down : null;
  if (down0) {
    printSmall(
      "Down:U" + bool01(down0[0]) + "D" + bool01(down0[1]) + "L" + bool01(down0[2]) + "R" + bool01(down0[3]) +
      " A" + bool01(down0[4]) + "B" + bool01(down0[5]) + "X" + bool01(down0[6]) + "Y" + bool01(down0[7]),
      xR,
      yR,
      13
    ); yR += step;
  } else {
    printSmall("Down:(no raw yet)", xR, yR, 13); yR += step;
  }

  var st = d.ctrl;
  if (st && st.held) {
    var held = st.held;
    var heldA = held[4];
    var heldX = held[6];
    printSmall(
      "Held:A" + heldA + " X" + heldX + " Grab:" + bool01(st.aGrabActive) + " XLatch:" + bool01(st.xInspectActive),
      xR,
      yR,
      13
    ); yR += step;
  } else {
    printSmall("Held:(no ctrl yet)", xR, yR, 13); yR += step;
  }

  printSmall("Intent:" + (d.lastUiIntentSummary || "(none)"), xR, yR, 13);

  printSmall("A:Step  B:Next  X:Reset  Y:Mode", 6, 128, 13);
};

// Main modes:
// 0=DebugText, 1=Render, 2=Title, 3=HowTo, 4=About
MC.mainTick = function () {
  var dbgEnabled = !!(MC.config.debug.enabled && MC.debug.toolsOn);

  // Title mode: main entry point.
  if (MC._mainMode === 2) {
    var rawT = MC.controls.pollGlobals();
    var intentT = null;
    if (MC.title && typeof MC.title.tick === "function") intentT = MC.title.tick(rawT);

    if (intentT && intentT.kind) {
      if (intentT.kind === "howToPlay") {
        MC.render.vbankClearOverlay();
        MC._mainMode = 3;
        return;
      }
      if (intentT.kind === "about") {
        MC.render.vbankClearOverlay();
        MC._mainMode = 4;
        return;
      }

      if (intentT.kind === "startNewGame") {
        MC.render.vbankClearOverlay();
        if (MC.debug && typeof MC.debug.startNewGame === "function") MC.debug.startNewGame();
        MC._mainMode = 1;
        return;
      }

      if (intentT.kind === "continueGame") {
        if (MC.debug && MC.debug.state != null) {
          MC.render.vbankClearOverlay();
          MC._mainMode = 1;
          return;
        }
      }
    }

    return;
  }

  // How-to-Play mode.
  if (MC._mainMode === 3) {
    var rawH = MC.controls.pollGlobals();
    var intentH = null;
    MC.render.vbankBeginOverlay();
    if (MC.howto && typeof MC.howto.tick === "function") intentH = MC.howto.tick(rawH);
    vbank(0);
    if (intentH && intentH.kind === "backToTitle") {
      MC._mainMode = 2;
      return;
    }
    return;
  }

  // About mode.
  if (MC._mainMode === 4) {
    var rawA = MC.controls.pollGlobals();
    var intentA = null;
    MC.render.vbankBeginOverlay();
    if (MC.about && typeof MC.about.tick === "function") intentA = MC.about.tick(rawA);
    vbank(0);
    if (intentA && intentA.kind === "backToTitle") {
      MC._mainMode = 2;
      return;
    }
    return;
  }

  // Modes: 0=DebugText, 1=Render. Y toggles DebugText ↔ Render (dev-only).
  if (dbgEnabled && (MC._mainMode === 0 || MC._mainMode === 1) && btnp(7)) {
    MC._mainMode = MC._mainMode ? 0 : 1;
  }

  if (MC._mainMode === 0) {
    if (!dbgEnabled) { MC._mainMode = 1; return; }
    // DebugText renders only in vbank(0); clear any leftover gameplay UI overlay.
    MC.render.vbankClearOverlay();
    if (MC.debug.state == null) MC.debug.reset(null);
    MC.debug.tickTextMode();
    return;
  }

  // Render mode
  var d = MC.debug;
  if (d.state == null) { MC._mainMode = 2; return; }

  {
    var raw = MC.controls.pollGlobals();
    d.lastRaw = raw;
    var actions = MC.controls.actions(d.ctrl, raw, MC.config.controls);

    // AI acts for actor=1 (activeP or prompt.p). While AI is acting, suppress player input.
    var actor = MC.ai.actor(d.state);
    var gameOver = (d.state.winnerP !== MC.state.NO_WINNER);
    if (actor !== 0 && !gameOver) actions = MC.controls.emptyActions();

    var intent = MC.ui.step(d.state, d.view, actions);
    {
      var sum = "(none)";
      if (intent && intent.kind) {
        if (intent.kind === "applyCmd" && intent.cmd && intent.cmd.kind) sum = "applyCmd:" + String(intent.cmd.kind);
        else if (intent.kind === "debug" && intent.action) sum = "debug:" + String(intent.action);
        else sum = String(intent.kind);
      }
      d.lastUiIntentSummary = sum;
    }

    if (intent && intent.kind === "mainMenu") {
      MC._mainMode = 2;
      return;
    }

    if (actor === 0 && intent && intent.kind === "applyCmd" && intent.cmd) {
      try {
        var res = MC.engine.applyCommand(d.state, intent.cmd);
        d.lastCmd = intent.cmd.kind;
        d.lastEvents = (res && res.events) ? res.events : [];
        MC.anim.onEvents(d.state, d.view, d.lastEvents);
      } catch (err) {
        d.lastCmd = intent.cmd.kind + "(!)";
        d.lastEvents = [];
        var code = (err && err.message) ? String(err.message) : "error";
        var msg = MC.fmt.errorMessage(code);
        MC.anim.feedbackError(d.view, code, msg);
      }
    } else if ((actor === 0 || gameOver) && dbgEnabled && intent && intent.kind === "debug") {
      if (intent.action === "step") {
        MC.debug.step();
        MC.anim.onEvents(d.state, d.view, d.lastEvents);
      }
      else if (intent.action === "reset") MC.debug.reset({ pauseAutoFocus: true });
      else if (intent.action === "nextScenario") MC.debug.nextScenario();
    }

    // AI pacing loop (one command per step, with fixed delay).
    if (!gameOver && actor !== 0 && !(d.view && d.view.anim && d.view.anim.lock)) {
      if (d.ai.wait > 0) {
        d.ai.wait -= 1;
      } else {
        var cmdAi = MC.ai.pickRandomLegalMove(d.state);
        if (cmdAi) {
          var txt = MC.ai.describeCmd(d.state, cmdAi);
          if (txt) {
            MC.ui.toastPush(d.view, { id: "ai:narrate", kind: "ai", text: txt, frames: MC.config.ui.aiNarrateToastFrames });
          }
          try {
            var resAi = MC.engine.applyCommand(d.state, cmdAi);
            d.lastCmd = "ai:" + cmdAi.kind;
            d.lastEvents = (resAi && resAi.events) ? resAi.events : [];
            MC.anim.onEvents(d.state, d.view, d.lastEvents);
          } catch (errAi) {
            d.lastCmd = "ai:" + cmdAi.kind + "(!)";
            d.lastEvents = [];
            var codeAi = (errAi && errAi.message) ? String(errAi.message) : "error";
            var msgAi = MC.fmt.errorMessage(codeAi);
            MC.anim.feedbackError(d.view, codeAi, msgAi);
          }
          d.ai.wait = MC.config.ui.aiStepDelayFrames;
        } else {
          d.ai.wait = MC.config.ui.aiStepDelayFrames;
        }
      }
    }

    var computed = MC.ui.computeRowModels(d.state, d.view);
    MC.ui.updateCameras(d.state, d.view, computed);
    // Recompute after camera updates (selection/cam are orthogonal, but keep it stable).
    computed = MC.ui.computeRowModels(d.state, d.view);

    MC.render.drawFrame({ state: d.state, view: d.view, computed: computed });
  }
};

MC._mainMode = 2;

