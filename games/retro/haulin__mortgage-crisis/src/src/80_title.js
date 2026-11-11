// MC.title: boot title screen.
(function initTitleModule() {
  var T = MC.title;

  T.st = { menuI: 0, hoverI: -1, mouseMode: false, confirm: null };
  T.ctrl = MC.controls.newState();
  T.toastView = { toasts: [] };

  function printShadow(txt, x, y, col, opts) {
    txt = String(txt);
    if (opts == null) opts = {};
    var scale = (opts.scale == null) ? 1 : opts.scale;
    var small = !!opts.small;
    var shadowCol = (opts.shadowCol == null) ? MC.Pal.Black : opts.shadowCol;
    var dx = (opts.dx == null) ? 1 : opts.dx;
    var dy = (opts.dy == null) ? 1 : opts.dy;
    print(txt, x + dx, y + dy, shadowCol, false, scale, small);
    return print(txt, x, y, col, false, scale, small);
  }

  function drawControlsTable(tc, Pal, cx, cy, cw) {
    var x0 = cx + 2;
    var x1 = cx + Math.floor(cw * 0.34);
    var x2 = cx + Math.floor(cw * 0.55);
    var x3 = cx + Math.floor(cw * 0.80);
    var y = cy + 1;
    var dy = 8;

    printShadow("Controls", x0, y, Pal.White, { small: true, shadowCol: Pal.Black });
    printShadow("Pad", x1, y, Pal.LightGrey, { small: true, shadowCol: Pal.Black });
    printShadow("Keys", x2, y, Pal.LightGrey, { small: true, shadowCol: Pal.Black });
    printShadow("Mouse", x3, y, Pal.LightGrey, { small: true, shadowCol: Pal.Black });
    y += dy;

    function row(label, ctrl, kb, ms) {
      printShadow(label, x0, y, Pal.LightGrey, { small: true, shadowCol: Pal.Black });
      printShadow(ctrl, x1, y, Pal.Yellow, { small: true, shadowCol: Pal.Black });
      printShadow(kb, x2, y, Pal.Cyan, { small: true, shadowCol: Pal.Black });
      printShadow(ms, x3, y, Pal.LightGreen, { small: true, shadowCol: Pal.Black });
      y += dy;
    }

    row("Move", "D-pad", "Arrows", "Hover");
    row("Action", "A", "Z", "Left");
    row("Cancel", "B", "X", "Right");
    row("Inspect", "X", "A", "Middle");
  }

  function wrapI(i, n) {
    if (n <= 0) return 0;
    i = i % n;
    if (i < 0) i += n;
    return i;
  }

  function titleClearToasts(toastView) {
    toastView.toasts = [];
  }

  function titlePushToast(toastView, cfg, kind, text) {
    text = String(text || "");
    var id = "title:" + text;
    var frames = (kind === "error") ? cfg.ui.toast.errorFrames : cfg.ui.toast.infoFrames;
    MC.ui.toastPush(toastView, { id: id, kind: kind, text: text, frames: frames });
  }

  function titleBuildMenuItems(hasSession, devAvail, toolsOn) {
    var menuItems = [
      { id: "startNewGame", text: "New Game", enabled: true },
      { id: "continueGame", text: "Continue", enabled: hasSession },
      { id: "howToPlay", text: "How to Play", enabled: true },
      { id: "about", text: "About", enabled: true }
    ];
    if (devAvail) {
      menuItems.push({ id: "toggleDev", text: (toolsOn ? "Dev: ON" : "Dev: OFF"), enabled: true });
    }
    return menuItems;
  }

  function titleEnterConfirmOverwrite(st, toastView, mouseHint) {
    st.confirm = "overwriteNewGame";
    titleClearToasts(toastView);
    var text = mouseHint
      ? "Overwrite current game?\nClick:Confirm  Right:Cancel"
      : "Overwrite current game?\nA:Confirm  B:Cancel";
    MC.ui.toastPush(toastView, { id: "title:" + text, kind: "prompt", text: text, persistent: true });
  }

  function titleStep(st, cfg, actions, toastView, menuItems, hasSession) {
    var intent = null;
    var nItems = menuItems.length;
    st.menuI = wrapI(st.menuI, nItems);

    var m = actions && actions.mouse ? actions.mouse : null;
    var mouseTap = !!(m && m.avail && m.left && m.left.tap);

    // Confirm state: ignore nav and interpret A/B as confirm/cancel.
    if (String(st.confirm || "") === "overwriteNewGame") {
      if (actions.b && actions.b.pressed) {
        st.confirm = null;
        titleClearToasts(toastView);
      } else if (actions.a && actions.a.tap) {
        st.confirm = null;
        titleClearToasts(toastView);
        intent = { kind: "startNewGame" };
      }
      return intent;
    }

    // Mouse hover selects a menu item.
    var mouseCfg = cfg.mouse;
    if (mouseCfg && mouseCfg.enabled && mouseCfg.hoverSelect && m && m.avail && (m.moved || (m.left && m.left.pressed))) {
      st.mouseMode = true;
      var tc = cfg.title;
      var W = cfg.screenW;
      var menuW = tc.menuW;
      var leftW = W - menuW;
      var my0 = tc.menuY;
      var dy = tc.menuDy;
      var gap = tc.menuItemGapY;
      if (gap == null) gap = 0;
      var padY = tc.menuItemBoxPadY;
      var xBox = leftW + 2;
      var wBox = menuW - 8;
      var hBox = dy - 2 + padY;
      st.hoverI = -1;
      var i;
      for (i = 0; i < nItems; i++) {
        var y0 = my0 + i * (dy + gap);
        var x0 = xBox;
        var x1 = xBox + wBox - 1;
        var yTop = y0 - padY;
        var yBot = yTop + hBox - 1;
        if (m.x >= x0 && m.x <= x1 && m.y >= yTop && m.y <= yBot) {
          st.hoverI = i;
          st.menuI = i; // keep controller selection aligned with hover when on-item
          break;
        }
      }
    }

    // Controller/keyboard nav leaves mouse-hover mode.
    if (actions.nav && actions.nav.up) { st.mouseMode = false; st.hoverI = -1; st.menuI = wrapI(st.menuI - 1, nItems); }
    if (actions.nav && actions.nav.down) { st.mouseMode = false; st.hoverI = -1; st.menuI = wrapI(st.menuI + 1, nItems); }

    if (actions.a && actions.a.tap) {
      // Mouse click only confirms when the pointer is currently over an item.
      if (mouseTap) {
        if (!(st.mouseMode && st.hoverI >= 0 && st.hoverI < nItems)) return null;
        st.menuI = st.hoverI;
      } else {
        // Controller/keyboard confirm leaves mouse-hover mode.
        st.mouseMode = false;
        st.hoverI = -1;
      }

      var itSel = menuItems[st.menuI];
      if (itSel && itSel.enabled) {
        if (itSel.id === "startNewGame") {
          if (hasSession) {
            titleEnterConfirmOverwrite(st, toastView, !!mouseTap);
          } else {
            titleClearToasts(toastView);
            intent = { kind: "startNewGame" };
          }
        }
        else if (itSel.id === "continueGame") {
          titleClearToasts(toastView);
          intent = { kind: "continueGame" };
        }
        else if (itSel.id === "howToPlay") {
          titleClearToasts(toastView);
          intent = { kind: "howToPlay" };
        }
        else if (itSel.id === "about") {
          titleClearToasts(toastView);
          intent = { kind: "about" };
        }
        else if (itSel.id === "toggleDev") {
          MC.debug.toolsOn = !MC.debug.toolsOn;
          titlePushToast(toastView, cfg, "info", MC.debug.toolsOn ? "Dev tools enabled" : "Dev tools disabled");
        }
      } else if (itSel) {
        var msg = "Not available";
        if (itSel.id === "continueGame") msg = "No game to continue";
        titlePushToast(toastView, cfg, "error", msg);
      }
    }

    return intent;
  }

  function drawMenuItem(tc, Pal, leftW, menuW, mxA, mxT, my0, dy, gap, i, text, selected, enabled) {
    var y0 = my0 + i * (dy + gap);
    var padY = tc.menuItemBoxPadY;
    var xBox = leftW + 2;
    var wBox = menuW - 8;
    var hBox = dy - 2;
    // Keep borders understated and only "light up" enabled selections.
    var colB = selected && enabled ? Pal.White : Pal.Grey;
    var colT = enabled ? (selected ? Pal.White : Pal.LightGrey) : Pal.Grey;
    if (tc.menuItemBoxes) {
      rect(xBox, y0 - padY, wBox, hBox + padY, Pal.Black);
      rectb(xBox, y0 - padY, wBox, hBox + padY, colB);
    }
    if (selected) printShadow(">", mxA, y0, Pal.White, { shadowCol: Pal.Black });
    printShadow(text, mxT, y0, colT, { shadowCol: Pal.Black });
  }

  function drawTitle(cfg, st, menuItems, toastView) {
    var tc = cfg.title;
    var Pal = MC.Pal;
    var captureMode = !!tc.marketingCaptureMode;

    var W = cfg.screenW;
    var H = cfg.screenH;
    var menuW = tc.menuW;
    var leftW = W - menuW;

    // Render title into vbank(0) (background palette).
    // Ensure vbank(1) overlay is fully transparent so gameplay UI can't leak over the title.
    MC.render.vbankClearOverlay();
    cls(Pal.DarkBlue);
    MC.render.tileFillSpr(tc.bgTileSprId, 0, 0, W, H, 2, 2, cfg.render.style.sprColorkey);

    var logoScale = tc.logoScale;
    var logoX = tc.logoX;
    var logoY = tc.logoY;
    printShadow("MORTGAGE", logoX, logoY, Pal.White, { scale: logoScale, dx: 2, dy: 2 });
    printShadow("CRISIS", logoX + 20, logoY + 20, Pal.Yellow, { scale: logoScale, dx: 2, dy: 2 });

    if (!captureMode && tc.subtitleText) {
      rect(tc.subtitleX - 1, tc.subtitleY - 1, 12 * 8 - 1, 8, Pal.DarkBlue);
      printShadow(String(tc.subtitleText), tc.subtitleX, tc.subtitleY, Pal.LightGrey, { small: true, shadowCol: Pal.Black });
    }

    if (!captureMode) {
      var cx = tc.controlsX;
      var ch = tc.controlsH;
      var cy = H - tc.controlsBottomY - ch;
      var cw = tc.controlsW;
      if (cw > leftW - cx - 6) cw = leftW - cx - 6;
      if (cw < 60) cw = 60;
      rect(cx - 2, cy - 2, cw + 4, ch + 4, Pal.Black);
      rectb(cx - 2, cy - 2, cw + 4, ch + 4, Pal.Grey);
      drawControlsTable(tc, Pal, cx, cy, cw);
    }

    var mxA = leftW + tc.menuArrowX;
    var mxT = leftW + tc.menuTextX;
    var my0 = tc.menuY;
    var dy = tc.menuDy;
    var gap = tc.menuItemGapY;
    if (gap == null) gap = 0;

    if (!captureMode) {
      var mi;
      for (mi = 0; mi < menuItems.length; mi++) {
        var it = menuItems[mi];
        // Keep a stable selection even when the mouse is active but not hovering an item.
        // (TIC-80 mouse input may report "moved" on boot; don't render an unselected menu.)
        var selI = (st.mouseMode && st.hoverI >= 0) ? st.hoverI : st.menuI;
        drawMenuItem(tc, Pal, leftW, menuW, mxA, mxT, my0, dy, gap, mi, it.text, (mi === selI), !!it.enabled);
      }
    }

    if (!captureMode) {
      var ver = String(cfg.meta.version || "");
      if (ver) {
        var xVer = W + 3 - ver.length * 4;
        if (xVer < 0) xVer = 0;
        var yVer = H - 7;
        if (yVer < 0) yVer = 0;
        printShadow(ver, xVer, yVer, Pal.LightGrey, { small: true });
      }
    }

    if (!captureMode) {
      MC.render.drawToasts(toastView);
    }
  }

  T.tick = function (raw) {
    var cfg = MC.config;
    if (!raw) raw = MC.controls.pollGlobals();
    var actions = MC.controls.actions(T.ctrl, raw, cfg.controls);

    // Title owns its own toast view so messages don't leak into gameplay.
    var toastView = T.toastView;
    MC.ui.toastsTick(toastView);

    var hasSession = !!(MC.debug && MC.debug.state != null);
    var devAvail = !!(cfg.debug && cfg.debug.enabled);
    var menuItems = titleBuildMenuItems(hasSession, devAvail, !!MC.debug.toolsOn);

    var intent = titleStep(T.st, cfg, actions, toastView, menuItems, hasSession);
    drawTitle(cfg, T.st, menuItems, toastView);

    return intent;
  };
})();

