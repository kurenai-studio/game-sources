// MC.howto: in-game How to Play screen.
(function initHowtoModule() {
  var H = MC.howto;

  H.ctrl = MC.controls.newState();
  H.st = {
    pageI: 0,
    scrollByPage: [],
    layoutByPage: null,
    layoutForN: 0
  };

  H._demoState = null;

  function clamp(v, lo, hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
  }

  function wrapI(i, n) {
    if (n <= 0) return 0;
    i = i % n;
    if (i < 0) i += n;
    return i;
  }

  function rectSafe(x, y, w, h, c) { rect(x, y, w, h, c); }
  function printExSafe(s, x, y, c, fixed, smallfont) {
    // scale=1 always in this screen for predictable metrics.
    return print(String(s), x, y, c, !!fixed, 1, !!smallfont);
  }

  function ensureDemoState() {
    if (H._demoState) return H._demoState;
    var s = { uidToDefI: [0], totalUids: 0 };
    MC.state.buildAllUids(s);
    H._demoState = s;
    return s;
  }

  function uidForCardId(cardId) {
    var di = (MC.DEF_INDEX_BY_ID && MC.DEF_INDEX_BY_ID[String(cardId)]) != null ? MC.DEF_INDEX_BY_ID[String(cardId)] : -1;
    if (di < 0) return 0;
    var uid = 1;
    var i;
    for (i = 0; i < di; i++) {
      uid += (MC.CARD_DEFS[i] && MC.CARD_DEFS[i].count) ? MC.CARD_DEFS[i].count : 0;
    }
    return uid;
  }

  H.drawMiniCardById = function (cardId, xFace, yFace, assignedColor) {
    if (!MC.render || typeof MC.render.drawMiniCard !== "function") return;
    var uid = uidForCardId(cardId);
    if (!uid) return;
    var s = ensureDemoState();
    MC.render.drawMiniCard(s, uid, xFace, yFace, false, assignedColor);
  };

  function parseMarkupTokens(txt, defaultCol) {
    txt = String(txt || "");
    var tokens = [];
    var curCol = defaultCol;
    var i = 0;

    function pushText(s) {
      if (!s) return;
      tokens.push({ text: s, col: curCol });
    }

    while (i < txt.length) {
      var lt = txt.indexOf("<", i);
      if (lt < 0) { pushText(txt.slice(i)); break; }
      if (lt > i) pushText(txt.slice(i, lt));

      // Try parse a tag.
      var gt = txt.indexOf(">", lt + 1);
      if (gt < 0) { pushText("<"); i = lt + 1; continue; }

      var tag = txt.slice(lt + 1, gt); // without < >
      // Opening: cN
      if (tag.length >= 2 && tag.charAt(0) === "c") {
        var num = tag.slice(1);
        if (/^\d+$/.test(num)) {
          curCol = Number(num);
          i = gt + 1;
          continue;
        }
      }
      // Closing: /c or /cN
      if (tag.length >= 2 && tag.charAt(0) === "/" && tag.charAt(1) === "c") {
        curCol = defaultCol;
        i = gt + 1;
        continue;
      }

      // Not a recognized tag: keep literal.
      pushText("<");
      i = lt + 1;
    }

    return tokens;
  }

  function wordsFromTokens(tokens) {
    var out = [];
    var cur = [];
    var curLen = 0;

    function flush() {
      if (!curLen) { cur = []; return; }
      out.push({ tokens: cur, len: curLen });
      cur = [];
      curLen = 0;
    }

    var ti;
    for (ti = 0; ti < tokens.length; ti++) {
      var t = tokens[ti];
      if (!t || !t.text) continue;
      var s = String(t.text);
      var col = t.col;
      var j = 0;
      while (j < s.length) {
        var ch = s.charAt(j);
        var isSpace = (ch === " " || ch === "\t");
        if (isSpace) {
          flush();
          // Skip consecutive whitespace.
          while (j < s.length && (s.charAt(j) === " " || s.charAt(j) === "\t")) j++;
          continue;
        }
        // Consume a non-space run.
        var k = j;
        while (k < s.length) {
          var ch2 = s.charAt(k);
          if (ch2 === " " || ch2 === "\t") break;
          k++;
        }
        var part = s.slice(j, k);
        cur.push({ text: part, col: col });
        curLen += part.length;
        j = k;
      }
    }
    flush();
    return out;
  }

  function wrapTokens(tokens, maxChars, spaceCol) {
    if (!(maxChars > 0)) return [];
    var words = wordsFromTokens(tokens);
    var lines = [];
    var line = [];
    var lineLen = 0;
    var wi;

    function pushLine() {
      lines.push({ tokens: line, len: lineLen });
      line = [];
      lineLen = 0;
    }

    for (wi = 0; wi < words.length; wi++) {
      var w = words[wi];
      if (!w || !w.len) continue;

      if (w.len > maxChars) {
        // Finish current line, then allow the long word to overflow.
        if (lineLen) pushLine();
        lines.push({ tokens: w.tokens, len: w.len });
        continue;
      }

      if (!lineLen) {
        line = w.tokens.slice();
        lineLen = w.len;
        continue;
      }

      if ((lineLen + 1 + w.len) <= maxChars) {
        line.push({ text: " ", col: spaceCol });
        Array.prototype.push.apply(line, w.tokens);
        lineLen += 1 + w.len;
      } else {
        pushLine();
        line = w.tokens.slice();
        lineLen = w.len;
      }
    }

    if (lineLen) pushLine();
    return lines;
  }

  function layoutPage(page, cfg, textCol, headingCol) {
    var items = [];
    var y = 0;
    var blocks = page && page.blocks ? page.blocks : [];

    var i;
    for (i = 0; i < blocks.length; i++) {
      var b = blocks[i];
      if (!b || !b.kind) continue;

      var yBlock0 = y;

      var demo = b.demo || null;
      var demoLayout = demo ? String(demo.layout || "") : "";
      var demoW = demo && demo.w != null ? demo.w : 0;
      var demoH = demo && demo.h != null ? demo.h : 0;

      var textX = 0;
      var maxW = cfg.contentW + 16;
      if (demo && demoLayout === "left" && demoW > 0) {
        textX = demoW + cfg.demoGapX;
        maxW = cfg.contentW - textX;
        if (maxW < cfg.bodyCharW * 10) maxW = cfg.bodyCharW * 10;
        items.push({ kind: "demo", x: 0, y: yBlock0, w: demoW, h: demoH, draw: demo.draw });
      }

      if (demo && demoLayout === "above" && demoH > 0) {
        items.push({ kind: "demo", x: 0, y: yBlock0, w: demoW, h: demoH, draw: demo.draw });
        y += demoH + cfg.demoGapY;
      }

      if (b.kind === "h") {
        var hTxt = String(b.text || "");
        var parasH = hTxt.split("\n");
        var piH;
        for (piH = 0; piH < parasH.length; piH++) {
          var pH = String(parasH[piH] || "");
          if (!pH.trim()) { y += cfg.headingLineH; continue; }
          var tH = parseMarkupTokens(pH, headingCol);
          var maxCharsH = Math.floor(maxW / cfg.headingCharW);
          var linesH = wrapTokens(tH, maxCharsH, headingCol);
          var liH;
          for (liH = 0; liH < linesH.length; liH++) {
            items.push({ kind: "text", x: textX, y: y, tokens: linesH[liH].tokens, small: false });
            y += cfg.headingLineH - 6;
          }
        }
      }
      else if (b.kind === "p") {
        var pTxt = String(b.text || "");
        var paras = pTxt.split("\n");
        var pi;
        for (pi = 0; pi < paras.length; pi++) {
          var p = String(paras[pi] || "");
          if (!p.trim()) { y += cfg.bodyLineH; continue; }
          var t = parseMarkupTokens(p, textCol);
          var maxChars = Math.floor(maxW / cfg.bodyCharW);
          var lines = wrapTokens(t, maxChars, textCol);
          var li;
          for (li = 0; li < lines.length; li++) {
            items.push({ kind: "text", x: textX, y: y, tokens: lines[li].tokens, small: true });
            y += cfg.bodyLineH;
          }
        }
      }
      else if (b.kind === "bullets") {
        var bulletItems = b.items;
        if (!bulletItems || bulletItems.length === 0) { y += cfg.blockGapY; continue; }
        var bi;
        for (bi = 0; bi < bulletItems.length; bi++) {
          var sIt = String(bulletItems[bi] || "");
          if (!sIt.trim()) continue;
          var tIt = parseMarkupTokens(sIt, textCol);
          var bulletPrefix = "-";
          var prefixW = cfg.bodyCharW * 2; // "- "
          var bulletTextX = textX + prefixW;
          var maxWB = maxW - prefixW;
          if (maxWB < cfg.bodyCharW * 10) maxWB = cfg.bodyCharW * 10;
          var maxCharsB = Math.floor(maxWB / cfg.bodyCharW);
          var linesB = wrapTokens(tIt, maxCharsB, textCol);
          var liB;
          for (liB = 0; liB < linesB.length; liB++) {
            items.push({
              kind: "text",
              x: bulletTextX,
              y: y,
              tokens: linesB[liB].tokens,
              small: true,
              prefix: (liB === 0) ? bulletPrefix : null,
              prefixX: textX
            });
            y += cfg.bodyLineH;
          }
          y += 1;
        }
      }

      // If demo is left-aligned, make sure block height accounts for it.
      if (demo && demoLayout === "left" && demoH > 0) {
        var demoBottom = yBlock0 + demoH;
        if (demoBottom > y) y = demoBottom;
      }

      y += cfg.blockGapY;
    }

    return { items: items, contentH: y };
  }

  function ensureLayouts(cfg, pages, st) {
    var n = pages.length;
    if (st.layoutByPage && st.layoutForN === n) return;

    var hc = cfg.howto;
    var screenW = cfg.screenW;
    var padX = hc.padX;
    var bodyX0 = padX;
    var bodyX1 = screenW - padX - 1;
    var contentW = bodyX1 - bodyX0 + 1;

    var perCfg = {
      contentW: contentW,
      padX: hc.padX,
      padY: hc.padY,
      demoGapX: hc.demoGapX,
      demoGapY: hc.demoGapY,
      blockGapY: hc.blockGapY,
      headingCharW: hc.headingCharW,
      headingLineH: hc.headingLineH,
      bodyCharW: hc.bodyCharW,
      bodyLineH: hc.bodyLineH
    };

    var layouts = [];
    var i;
    for (i = 0; i < n; i++) {
      layouts[i] = layoutPage(pages[i], perCfg, hc.colText, hc.colHeading);
    }
    st.layoutByPage = layouts;
    st.layoutForN = n;
  }

  function ensureScrollMemory(nPages, st) {
    var arr = st.scrollByPage;
    var i;
    for (i = 0; i < nPages; i++) {
      if (arr[i] == null) arr[i] = 0;
    }
    if (arr.length > nPages) arr.length = nPages;
  }

  function pagesFromContent(content) {
    var c = content;
    var pages = c && c.pages ? c.pages : [];
    if (!pages || !pages.length) return [];
    return pages;
  }

  function drawTokensLine(tokens, x, y, charW, fixed, smallfont, defaultCol) {
    var dx = 0;
    var i;
    for (i = 0; i < tokens.length; i++) {
      var t = tokens[i];
      if (!t || !t.text) continue;
      var s = String(t.text);
      if (!s) continue;
      var col = (t.col != null) ? t.col : defaultCol;
      var w = print(String(s), x + dx, y, col, !!fixed, 1, !!smallfont);
      if (typeof w === "number" && Number.isFinite(w)) dx += w;
      else dx += s.length * charW;
    }
  }

  function drawDocScreen(cfg, pages, layout, pageI, scrollY, opts) {
    var hc = cfg.howto;
    var W = cfg.screenW;
    var Hh = cfg.screenH;

    // Background (blue-only; no inner panel).
    cls(hc.colBg);

    var headerH = hc.headerH;
    var footerH = hc.footerH;
    var bodyY0 = headerH;
    var bodyY1 = Hh - footerH - 1;

    // Header (drawn last; background bar masks any overdraw while scrolling).
    var page = pages[pageI];
    var title = page ? String(page.title || "") : "";

    // Body content window (with padding).
    var contentX0 = hc.padX;
    var contentX1 = W - hc.padX - 1;
    var contentY0 = bodyY0 + hc.padY;
    var contentY1 = bodyY1 - hc.padY;

    // Draw items. Header/footer bars mask any overflow.
    var items = layout ? layout.items : [];
    var itI;
    for (itI = 0; itI < items.length; itI++) {
      var it = items[itI];
      if (!it) continue;
      var yScreen = contentY0 + it.y - scrollY;

      if (it.kind === "demo") {
        if (typeof it.draw === "function") {
          it.draw({
            x: contentX0 + it.x,
            y: yScreen,
            w: it.w,
            h: it.h,
            clipX0: contentX0,
            clipY0: contentY0,
            clipX1: contentX1,
            clipY1: contentY1
          });
        }
        continue;
      }

      if (it.kind === "text") {
        if (it.prefix) {
          printExSafe("- ", contentX0 + it.prefixX, yScreen, hc.colText, false, true);
        }

        var xx = contentX0 + it.x;
        var charW = it.small ? hc.bodyCharW : hc.headingCharW;
        var toks = it.tokens;
        if (toks && toks.length) {
          drawTokensLine(toks, xx, yScreen, charW, false, !!it.small, hc.colText);
        }
      }
    }

    // Scrollbar (only when needed).
    var contentH = layout ? layout.contentH : 0;
    var viewH = (contentY1 - contentY0 + 1);
    if (contentH > viewH && viewH > 0) {
      var trackX = contentX1 + 2;
      if (trackX < W - 2) {
        var trackY0 = contentY0;
        var trackH = viewH;
        rectSafe(trackX, trackY0, 2, trackH, hc.colBorder);
        var maxScroll = contentH - viewH;
        var thumbH = Math.floor((viewH * viewH) / contentH);
        if (thumbH < 6) thumbH = 6;
        if (thumbH > trackH) thumbH = trackH;
        var thumbY = trackY0 + Math.floor((scrollY * (trackH - thumbH)) / maxScroll);
        rectSafe(trackX, thumbY, 2, thumbH, hc.colAccent);
      }
    }

    // Header/footer masks (to hide any demo overdraw in the margins).
    if (headerH > 0) rectSafe(0, 0, W, headerH, hc.colPanel);
    if (footerH > 0) rectSafe(0, Hh - footerH, W, footerH, hc.colPanel);
    if (footerH > 0) rectSafe(0, Hh - footerH - 1, W, 1, hc.colBg);

    // Single-line header: "<Title> (1/3): Page Title" + controls on the right.
    if (headerH > 0) {
      // Separator line under the header bar.
      rectSafe(0, headerH - 1, W, 1, hc.colBorder);
      rectSafe(0, headerH, W, 1, hc.colBg);

      var headerTitle = (opts.headerTitle != null) ? String(opts.headerTitle) : "How to Play";
      var allowPaging = (opts.allowPaging != null) ? !!opts.allowPaging : true;
      var showPageCount = (opts.showPageCount != null) ? !!opts.showPageCount : true;
      var showPagingControls = allowPaging && pages.length > 1;

      var controls = "B:Back" + (showPagingControls ? " L/R:Page" : "") + " U/D:Scroll";
      var charW = hc.bodyCharW;
      var yH = Math.floor((headerH - hc.bodyLineH) / 2);
      if (yH < 0) yH = 0;

      var xCtrl = W - hc.padX - controls.length * charW;
      if (xCtrl < hc.padX) xCtrl = hc.padX;
      printExSafe(controls, xCtrl, yH, hc.colMuted, true, true);

      var prefix = headerTitle;
      if (showPageCount) prefix += " (" + (pageI + 1) + "/" + pages.length + ")";
      if (title) prefix += ": ";
      var x0 = hc.padX;
      var gapPx = 2 * charW;
      var wPrefix = printExSafe(prefix, x0, yH, hc.colMuted, false, true);
      var hasPrefixW = (typeof wPrefix === "number" && Number.isFinite(wPrefix));
      if (!hasPrefixW) wPrefix = prefix.length * charW;

      var xTitle = x0 + wPrefix;

      var xMax = xCtrl - gapPx;
      if (xMax < xTitle) xMax = xTitle;

      var availPx = xMax - xTitle;
      var availChars = hasPrefixW ? Math.floor(availPx / charW) : title.length;
      if (availChars < 0) availChars = 0;

      var titleDraw = title;
      if (titleDraw.length > availChars) {
        if (availChars <= 3) titleDraw = titleDraw.slice(0, availChars);
        else titleDraw = titleDraw.slice(0, availChars - 3) + "...";
      }

      if (titleDraw) {
        printExSafe(titleDraw, xTitle, yH, hc.colTitle, false, true);
      }
    }
  }

  H.tickDocScreen = function (raw, opts) {
    var cfg = MC.config;
    if (!raw) raw = MC.controls.pollGlobals();

    var content = opts.content;
    var pages = pagesFromContent(content);
    var headerTitle = (opts.headerTitle != null) ? String(opts.headerTitle) : "How to Play";
    var st = opts.st;
    var ctrl = opts.ctrl;
    var intentBack = opts.intentBack;

    if (!pages || pages.length === 0) {
      cls(MC.Pal.Black);
      printExSafe(headerTitle, 8, 8, MC.Pal.White, false, false);
      printExSafe("(missing content)", 8, 18, MC.Pal.LightGrey, false, true);
      return null;
    }

    ensureLayouts(cfg, pages, st);
    ensureScrollMemory(pages.length, st);

    st.pageI = wrapI(st.pageI, pages.length);

    var actions = MC.controls.actions(ctrl, raw, cfg.controls);

    // Mouse: header click pages left/right (Back is handled via right-click -> B).
    var allowPaging = (opts.allowPaging != null) ? !!opts.allowPaging : true;
    var mouseCfg = cfg.mouse;
    var m = actions && actions.mouse ? actions.mouse : null;
    if (allowPaging && pages.length > 1 && mouseCfg && mouseCfg.enabled && m && m.avail && actions.a && actions.a.tap && m.left && m.left.tap) {
      var hc0 = cfg.howto;
      if (m.y < hc0.headerH) {
        if (m.x < (cfg.screenW / 2)) st.pageI = wrapI(st.pageI - 1, pages.length);
        else st.pageI = wrapI(st.pageI + 1, pages.length);
      }
    }

    if (actions.b && actions.b.pressed) {
      return intentBack;
    }

    if (allowPaging && pages.length > 1) {
      if (actions.nav && actions.nav.left) st.pageI = wrapI(st.pageI - 1, pages.length);
      if (actions.nav && actions.nav.right) st.pageI = wrapI(st.pageI + 1, pages.length);
    }

    var layout = st.layoutByPage ? st.layoutByPage[st.pageI] : null;

    // Scroll input.
    var hc = cfg.howto;
    var headerH = hc.headerH;
    var footerH = hc.footerH;
    var bodyY0 = headerH;
    var bodyY1 = cfg.screenH - footerH - 1;
    var contentY0 = bodyY0 + hc.padY;
    var contentY1 = bodyY1 - hc.padY;
    var viewH = (contentY1 - contentY0 + 1);
    var contentH = layout ? layout.contentH : 0;
    var maxScroll = (contentH > viewH) ? (contentH - viewH) : 0;

    var scroll = st.scrollByPage[st.pageI];
    if (actions.nav && actions.nav.up) scroll -= hc.scrollStepPx;
    if (actions.nav && actions.nav.down) scroll += hc.scrollStepPx;
    scroll = clamp(scroll, 0, maxScroll);
    st.scrollByPage[st.pageI] = scroll;

    drawDocScreen(cfg, pages, layout, st.pageI, scroll, opts);
    return null;
  };

  H.tick = function (raw) {
    return H.tickDocScreen(raw, {
      content: H.CONTENT,
      st: H.st,
      ctrl: H.ctrl,
      headerTitle: "How to Play",
      showPageCount: true,
      allowPaging: true,
      intentBack: { kind: "backToTitle" }
    });
  };
})();

