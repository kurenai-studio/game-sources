// MC.render: display-only renderer + TIC-80 draw-call boundary wrappers (no state mutation).
(function initRenderModule() {
  var R = MC.render;

  R.ROW_OP_HAND = 0;
  R.ROW_OP_TABLE = 1;
  R.ROW_CENTER = 2;
  R.ROW_P_TABLE = 3;
  R.ROW_P_HAND = 4;

  var renderCfg = MC.config.render;
  // Keep internal `cfg` for readability, but source-of-truth config is split
  // into `render.layout` and `render.style`.
  var layout = renderCfg.layout;
  var style = renderCfg.style;
  R.cfg = {};
  var k;
  for (k in layout) R.cfg[k] = layout[k];
  for (k in style) R.cfg[k] = style[k];
  R.spr = renderCfg.spr;
  R.moneyBgByValue = renderCfg.moneyBgByValue;
  R.center = (function () {
    var cfg = R.cfg;
    var row = R.ROW_CENTER;
    var y0 = cfg.rowY[row];
    var top = y0 + cfg.centerTopInsetY;
    var deckX = cfg.centerDeckX;
    var gapX = cfg.centerPileGapX;
    var prevX = cfg.centerPreviewX;
    var prevGapX = cfg.centerPreviewGapX;

    return {
      deck: { x: deckX, y: top },
      discard: { x: deckX + cfg.faceW + gapX, y: top },

      preview: { x: prevX, y: top },
      title: { x: prevX + cfg.faceW + prevGapX, y: top },
      desc: { x: prevX + cfg.faceW + prevGapX, y: top + cfg.centerDescDy }
    };
  })();

  R.propBarColByColor = [];
  var Pal = MC.Pal;
  R.propBarColByColor[MC.Color.Cyan] = Pal.Cyan;
  R.propBarColByColor[MC.Color.Magenta] = Pal.Purple;
  R.propBarColByColor[MC.Color.Orange] = Pal.Orange;
  R.propBarColByColor[MC.Color.Black] = Pal.Black;

  function rectSafe(x, y, w, h, c) {
    rect(x | 0, y | 0, w | 0, h | 0, c | 0);
  }

  function rectbSafe(x, y, w, h, c) {
    rectb(x | 0, y | 0, w | 0, h | 0, c | 0);
  }

  function sprSafe(id, x, y, colorkey, scale, flip, rotate, w, h) {
    spr(id | 0, x | 0, y | 0, colorkey, scale, flip, rotate, w, h);
  }

  function printSafe(s, x, y, c) {
    print(String(s), x | 0, y | 0, c | 0);
  }

  function printExSafe(s, x, y, c, fixed, scale, smallfont) {
    print(String(s), x | 0, y | 0, c | 0, !!fixed, (scale == null ? 1 : scale) | 0, !!smallfont);
  }

  // Fill a rectangle by tiling a sprite block.
  // Uses clip() so partial tiles at edges don't overdraw outside the region.
  R.tileFillSpr = function (tid, x0, y0, w, h, sprW, sprH, colorkey) {
    if (!tid) return;
    if (!(w > 0) || !(h > 0)) return;
    if (!(sprW > 0)) sprW = 1;
    if (!(sprH > 0)) sprH = 1;

    var stepX = sprW * 8;
    var stepY = sprH * 8;
    var x1 = x0 + w;
    var y1 = y0 + h;

    clip(x0 | 0, y0 | 0, w | 0, h | 0);
    var x, y;
    for (y = y0; y < y1; y += stepY) {
      for (x = x0; x < x1; x += stepX) {
        sprSafe(tid, x, y, colorkey, 1, 0, 0, sprW, sprH);
      }
    }
    clip();
  };

  // VRAM overlay hygiene: clear vbank(1) to the transparent index so stale UI
  // can't leak across modes (e.g. gameplay -> title/debug).
  R.vbankClearOverlay = function () {
    var t = R.cfg.sprColorkey;
    vbank(1);
    poke(0x03FF8, t);
    cls(t);
    vbank(0);
  };

  // Overlay begin: set transparency + clear to the transparent index.
  // Leaves vbank(1) active for the caller to draw UI.
  R.vbankBeginOverlay = function () {
    var t = R.cfg.sprColorkey;
    vbank(1);
    poke(0x03FF8, t);
    cls(t);
    return t;
  };

  function drawGameplayBg() {
    R.tileFillSpr(R.spr.bgTileTL, 0, 0, R.cfg.screenW, R.cfg.screenH, 2, 2, R.cfg.sprColorkey);
  }

  function rowY0(row) { return R.cfg.rowY[row]; }
  function rowY1(row) { return rowY0(row) + R.cfg.rowH[row] - 1; }

  // Row policy lives in MC.layout; renderer uses it for flip decisions.
  function cardLocalRectToScreen(xFace, yFace, lx, ly, w, h, flip180) {
    if (!flip180) {
      return { x: xFace + lx, y: yFace + ly, w: w, h: h };
    }
    // 180° rotation: top-left becomes (W - (lx+w), H - (ly+h))
    return {
      x: xFace + (R.cfg.faceW - (lx + w)),
      y: yFace + (R.cfg.faceH - (ly + h)),
      w: w,
      h: h
    };
  }

  function drawShadowBar(xFace, yFace) {
    rectSafe(xFace + R.cfg.shadowBarDx, yFace, 1, R.cfg.faceH, R.cfg.colShadow);
  }

  function drawFannedShadowBar(xFace, yFace, fanDir) {
    // fanDir=+1 (fan right): shadow at xFace-1
    // fanDir=-1 (fan left): shadow at xFace+faceW
    if (fanDir < 0) rectSafe(xFace + R.cfg.faceW, yFace, 1, R.cfg.faceH, R.cfg.colShadow);
    else drawShadowBar(xFace, yFace);
  }

  function drawFannedStack(stackItems, opts) {
    if (!stackItems || stackItems.length === 0) return;
    var state = opts ? opts.state : null;
    var fanDir = (opts && opts.fanDir != null) ? opts.fanDir : 1;
    var camX = (opts && opts.camX != null) ? opts.camX : 0;
    var flip180 = !!(opts && opts.flip180);
    var selectedItem = opts ? opts.selectedItem : null;
    var drawSelected = !(opts && opts.drawSelected === false);
    var onlySelected = !!(opts && opts.onlySelected);
    var highlightCol = (opts && opts.highlightCol != null) ? opts.highlightCol : null;

    // Draw bottom->top by depth.
    var items = stackItems.slice();
    items.sort(function (a, b) { return a.depth - b.depth; });

    function drawGhostAt(xFace, yFace, col) {
      var shadowCol = MC.Pal.Black;
      if (col == null) col = MC.Pal.Green;
      rectbSafe(xFace - 1, yFace - 1, R.cfg.faceW, R.cfg.faceH, shadowCol);
      rectbSafe(xFace, yFace, R.cfg.faceW, R.cfg.faceH, col);
    }

    var i;
    if (!onlySelected) {
      for (i = 0; i < items.length; i++) {
        var it = items[i];
        if (selectedItem && it === selectedItem) continue;
        var xFace = it.x - camX;
        var yFace = it.y;
        if (it.kind === "ghost") {
          drawGhostAt(xFace, yFace, it.pal);
          continue;
        }
        if (it.kind === "preview") {
          if (!it.uid) continue;
          drawFannedShadowBar(xFace, yFace, fanDir);
          drawMiniCard(state, it.uid, xFace, yFace, flip180, it.color);
          drawHighlight(xFace, yFace, highlightCol);
          continue;
        }
        drawFannedShadowBar(xFace, yFace, fanDir);
        drawMiniCard(state, it.uid, xFace, yFace, flip180, it.color);
      }
    }

    if (drawSelected && selectedItem) {
      var xs = selectedItem.x - camX;
      var ys = selectedItem.y;
      drawFannedShadowBar(xs, ys, fanDir);
      drawMiniCard(state, selectedItem.uid, xs, ys, flip180, selectedItem.color);

      drawHighlight(xs, ys, highlightCol);
    }
  }

  function drawCardFaceBase(xFace, yFace, bgCol) {
    // Border
    rectSafe(xFace, yFace, R.cfg.faceW, R.cfg.faceH, R.cfg.colCardBorder);
    // Interior
    rectSafe(xFace + 1, yFace + 1, R.cfg.faceW - 2, R.cfg.faceH - 2, bgCol);
  }

  function drawHighlight(xFace, yFace, col) {
    if (col == null) col = R.cfg.colHighlight;
    rectbSafe(
      xFace - R.cfg.highlightPad,
      yFace - R.cfg.highlightPad,
      R.cfg.faceW + 2 * R.cfg.highlightPad,
      R.cfg.faceH + 2 * R.cfg.highlightPad,
      col
    );
  }

  function drawDigitGlyph(n, xGlyphTL, yGlyphTL, flip180) {
    if (n < 0 || n > 9) return;
    var id = R.spr.digit0 + n;
    var ck = R.cfg.sprColorkey;
    var insetX = R.cfg.glyphInsetX;
    var insetY = R.cfg.glyphInsetY;
    var tile = R.cfg.digitTile;
    var w = R.cfg.digitGlyphW;
    var h = R.cfg.digitGlyphH;
    if (!flip180) {
      sprSafe(id, xGlyphTL - insetX, yGlyphTL - insetY, ck, 1, 0, 0, 1, 1);
      return;
    }
    // Rotate 180, but keep inner-glyph top-left anchored.
    sprSafe(
      id,
      xGlyphTL - (tile - insetX - w),
      yGlyphTL - (tile - insetY - h),
      ck,
      1,
      0,
      2,
      1,
      1
    );
  }

  function drawDualPropHalf(xFace, yFace, color, cardValue, flip180) {
    var barCol = R.propBarColByColor[color] != null ? R.propBarColByColor[color] : R.cfg.colText;
    var v = cardValue;
    var pv = cardLocalRectToScreen(xFace, yFace, R.cfg.propValueX, R.cfg.propValueY, R.cfg.digitGlyphW, R.cfg.digitGlyphH, flip180);
    drawDigitGlyph(v, pv.x, pv.y, flip180);

    // Color bar
    var pr = cardLocalRectToScreen(
      xFace,
      yFace,
      R.cfg.propBarX,
      R.cfg.propBarY,
      R.cfg.propBarW,
      R.cfg.propBarH,
      flip180
    );
    rectSafe(pr.x, pr.y, pr.w, pr.h, barCol);

    // Rent row (rent table)
    var rent = (MC.SET_RULES && MC.SET_RULES[color]) ? MC.SET_RULES[color].rent : null;
    if (rent && rent.length > 0) {
      var i;
      for (i = 0; i < rent.length; i++) {
        var v = rent[i];
        if (v < 0 || v > 9) continue;
        var lx = R.cfg.propRentX + i * R.cfg.propRentDx;
        var ly = R.cfg.propRentY;
        var p = cardLocalRectToScreen(xFace, yFace, lx, ly, R.cfg.digitGlyphW, R.cfg.digitGlyphH, flip180);
        drawDigitGlyph(v, p.x, p.y, flip180);
      }
    }
  }

  function iconForDef(def) {
    if (!def) return 0;
    if (def.kind === MC.CardKind.Money) {
      return R.spr.iconMoney || 0;
    }
    if (def.kind === MC.CardKind.House) return R.spr.iconHouse;
    if (def.kind === MC.CardKind.Action) {
      if (def.actionKind === MC.ActionKind.Rent) return R.spr.iconRent;
      if (def.actionKind === MC.ActionKind.SlyDeal) return R.spr.iconSlyDeal;
      if (def.actionKind === MC.ActionKind.JustSayNo) return R.spr.iconJSN;
    }
    return 0;
  }

  function drawRentBars(xFace, yFace, colors, flip180) {
    if (!colors || colors.length <= 0) return;
    var barH = 2;
    var maxBars = 4;
    var count = colors.length;
    if (count > maxBars) count = maxBars;

    var lx = 1;
    var w = R.cfg.faceW - 2;
    var bottomY = R.cfg.faceH - 1 - barH;
    var i;
    for (i = 0; i < count; i++) {
      var ly = bottomY - i * barH;
      var p = cardLocalRectToScreen(xFace, yFace, lx, ly, w, barH, flip180);
      var color = colors[i];
      var c;
      if (color === MC.Color.Black) c = MC.Pal.Black;
      else c = R.propBarColByColor[color];
      rectSafe(p.x, p.y, p.w, p.h, c != null ? c : R.cfg.colText);
    }
  }

  function drawValueDigit(xFace, yFace, value, flip180) {
    if (value < 0) value = 0;
    if (value > 9) value = 9;
    var p = cardLocalRectToScreen(xFace, yFace, R.cfg.valX, R.cfg.valY, R.cfg.digitGlyphW, R.cfg.digitGlyphH, flip180);
    drawDigitGlyph(value, p.x, p.y, flip180);
  }

  function drawCenterIcon(xFace, yFace, iconId, flip180) {
    if (!iconId) return;
    var ck = R.cfg.sprColorkey;
    // 15x15 effective icon implemented as a 2x2 (16x16) sprite block with
    // the last row/col padded in the colorkey color.
    var p = cardLocalRectToScreen(xFace, yFace, R.cfg.iconX, R.cfg.iconY, 15, 15, flip180);
    // When rotated 180°, the padded colorkey row/col becomes top/left; shift
    // origin so the visible 15x15 stays anchored at p.x,p.y.
    var sx = flip180 ? (p.x - 1) : p.x;
    var sy = flip180 ? (p.y - 1) : p.y;
    sprSafe(iconId, sx, sy, ck, 1, 0, flip180 ? 2 : 0, 2, 2);
  }

  function drawMiniCard(state, uid, xFace, yFace, flip180, assignedColor) {
    var def = state ? MC.state.defByUid(state, uid) : null;
    if (!def) {
      drawCardFaceBase(xFace, yFace, R.cfg.colCardInterior);
      return;
    }

    if (def.kind === MC.CardKind.Property) {
      drawCardFaceBase(xFace, yFace, R.cfg.colCardInterior);
      var payV = def.propertyPayValue != null ? def.propertyPayValue : 0;
      if (MC.rules.isWildDef(def)) {
        // Two halves: top (halfFlip=false), bottom (halfFlip=true). Effective flip is XOR.
        var c0 = def.wildColors[0];
        var c1 = def.wildColors[1];
        var a = (assignedColor == null) ? MC.state.NO_COLOR : assignedColor;
        var colHalfFalse = c0;
        var colHalfTrue = c1;
        if (a === c0 || a === c1) {
          var other = (a === c0) ? c1 : c0;
          // Keep the assigned color on the owner-facing half.
          // `colHalfFalse` is always drawn with the card's `flip180`, which maps to the owner-facing half.
          colHalfFalse = a;
          colHalfTrue = other;
        }
        drawDualPropHalf(xFace, yFace, colHalfFalse, payV, !!flip180);
        drawDualPropHalf(xFace, yFace, colHalfTrue, payV, !flip180);
      } else {
        var c = def.propertyColor;
        drawDualPropHalf(xFace, yFace, c, payV, !!flip180);
      }
      return;
    }

    if (def.kind === MC.CardKind.Action && def.actionKind === MC.ActionKind.Rent) {
      drawCardFaceBase(xFace, yFace, R.cfg.colCardInterior);
      var colors = def.rentAllowedColors;
      if (!(colors && colors.length)) {
        colors = [MC.Color.Cyan, MC.Color.Black, MC.Color.Magenta, MC.Color.Orange];
      }
      drawRentBars(xFace, yFace, colors, !!flip180);
      var rv = def.bankValue;
      drawValueDigit(xFace, yFace, rv, !!flip180);
      // Draw icon last so rent stripes never cover it.
      var rIcon = iconForDef(def);
      drawCenterIcon(xFace, yFace, rIcon, !!flip180);
      return;
    }

    // Money / Action / House
    var v = def.bankValue;
    var bg = (v >= 1 && v <= 5) ? R.moneyBgByValue[v] : R.cfg.colCardInterior;
    drawCardFaceBase(xFace, yFace, bg);
    drawValueDigit(xFace, yFace, v, !!flip180);
    var icon = iconForDef(def);
    drawCenterIcon(xFace, yFace, icon, !!flip180);
  }

  // Expose mini-card drawing so other modes (e.g. How-to-Play) can reuse it.
  R.drawMiniCard = drawMiniCard;

  function drawCardBack(xFace, yFace) {
    var cfg = R.cfg;
    drawCardFaceBase(xFace, yFace, cfg.colCardInterior);
    // Fill interior (15x23) with the top-left 8x8 tile as a repeatable pattern.
    R.tileFillSpr(R.spr.cardBackTL, xFace + 1, yFace + 1, 15, 23, 1, 1, cfg.sprColorkey);
  }

  function drawCenter(state, view, computed, selectedItem, hlCol) {
    var s = state;

    var cfg = R.cfg;
    var row = R.ROW_CENTER;
    var y0 = rowY0(row);
    var y1 = rowY1(row);
    var h = y1 - y0 + 1;
    R.tileFillSpr(R.spr.centerPanelFillTile, 0, y0, 240, h, 1, 1, cfg.sprColorkey);
    rectbSafe(0, y0, 239, h, cfg.colCenterPanelBorder);

    var dbgEnabled = !!(MC.config.debug.enabled && MC.debug.toolsOn);
    if (hlCol == null) hlCol = cfg.colHighlight;

    // Deck/discard pile count digits (3x5 glyphs).
    function drawCountDigits(n, xFace, yFace) {
      var sN = String(n);
      if (sN.length > 2) sN = sN.slice(-2);
      var len = sN.length;
      var yTL = cfg.faceH - 1 - cfg.digitGlyphH + cfg.pileCountDy;
      var xEnd = cfg.faceW - 1 - cfg.digitGlyphW + cfg.pileCountDx;
      var xStart = xEnd - (len - 1) * cfg.propRentDx;
      var i;
      for (i = 0; i < len; i++) {
        var ch = sN.charCodeAt(i) - 48;
        if (ch < 0 || ch > 9) continue;
        drawDigitGlyph(ch, xFace + xStart + i * cfg.propRentDx, yFace + yTL, false);
      }
    }

    function drawUnderLayerOutline(xFace, yFace, dx, dy) {
      var colMain = cfg.colPileOutlineUnder1;
      if (dx === cfg.pileUnderDx2 && dy === cfg.pileUnderDy2) colMain = cfg.colPileOutlineUnder2;
      rectbSafe(xFace + dx - 1, yFace + dy - 1, cfg.faceW, cfg.faceH, cfg.colPileShadowOutline);
      rectbSafe(xFace + dx, yFace + dy, cfg.faceW, cfg.faceH, colMain);
    }

    function drawDeckAt(xFace, yFace, nVis, layersOverride) {
      var n = (nVis != null) ? nVis : s.deck.length;
      var layers = (layersOverride != null) ? layersOverride : -1;
      if (layers < 0) {
        if (n > 2) layers = 2;
        else if (n > 1) layers = 1;
        else layers = 0;
      }

      if (layers >= 2) drawUnderLayerOutline(xFace, yFace, cfg.pileUnderDx2, cfg.pileUnderDy2);
      if (layers >= 1) drawUnderLayerOutline(xFace, yFace, cfg.pileUnderDx1, cfg.pileUnderDy1);
      drawShadowBar(xFace, yFace);
      drawCardBack(xFace, yFace);
      drawCountDigits(n, xFace, yFace);
    }

    function drawDiscardAt(xFace, yFace, nVis, topUidVis) {
      var n = (nVis != null) ? nVis : s.discard.length;
      if (n > 2) {
        drawUnderLayerOutline(xFace, yFace, cfg.pileUnderDx2, cfg.pileUnderDy2);
        drawUnderLayerOutline(xFace, yFace, cfg.pileUnderDx1, cfg.pileUnderDy1);
      } else if (n > 1) {
        drawUnderLayerOutline(xFace, yFace, cfg.pileUnderDx1, cfg.pileUnderDy1);
      }

      if (n <= 0) {
        rectbSafe(xFace, yFace, cfg.faceW, cfg.faceH, cfg.colText);
        rectSafe(xFace + cfg.shadowBarDx, yFace, 1, cfg.faceH, cfg.colShadow);
        drawCountDigits(0, xFace, yFace);
        return;
      }

      var topUid = (topUidVis != null) ? topUidVis : s.discard[n - 1];
      drawShadowBar(xFace, yFace);
      if (topUid) drawMiniCard(s, topUid, xFace, yFace, false);
      else {
        // Masked-top fallback (used during shuffle animation): show an empty pile face with count.
        rectbSafe(xFace, yFace, cfg.faceW, cfg.faceH, cfg.colText);
      }
      drawCountDigits(n, xFace, yFace);
    }

    // Center row items (deck/discard/buttons). Presentation hints come from computed models.
    var rowM = computed.models ? computed.models[row] : null;
    var i;
    if (rowM && rowM.items) {
      for (i = 0; i < rowM.items.length; i++) {
        var it = rowM.items[i];
        if (!it) continue;
        if (it.kind === "deck") drawDeckAt(it.x, it.y, it.nVis, it.pileLayers);
        else if (it.kind === "discard") drawDiscardAt(it.x, it.y, it.nVis, it.topUidVis);
        else if (it.kind === "btn") {
          // Flat UI button: dark fill + white text; selected uses highlight fill + black text.
          // Note: debug gating and overlay hiding is handled in MC.ui.computeRowModels.

          var enabled = !it.disabled;

          var isSel = !!(selectedItem && selectedItem === it);
          var recommend = false;
          if (it.id === "endTurn" && enabled && (s.activeP === 0) && (s.playsLeft != null) && (s.playsLeft <= 0)) recommend = true;

          var border = isSel ? MC.Pal.Black : (recommend ? MC.Pal.Green : cfg.colCenterPanelBorder);
          var colText = enabled ? (isSel ? MC.Pal.Black : cfg.colText) : MC.Pal.Grey;
          if (!isSel && recommend && enabled) colText = MC.Pal.Green;

          // Unselected buttons are transparent so the center-panel dither shows through.
          if (isSel) rectSafe(it.x, it.y, it.w, it.h, hlCol);
          rectbSafe(it.x, it.y, it.w, it.h, border);

          // Vertically center 6px font in button height.
          var labelY = it.y + Math.floor((it.h - 6) / 2);
          printSafe(String(it.label || it.id || ""), it.x + 2, labelY, colText);
        }
      }
    }

    // Non-selectable center overlays (e.g. payDebt buffer stack).
    if (rowM && rowM.overlayItems) {
      for (i = 0; i < rowM.overlayItems.length; i++) {
        var itO = rowM.overlayItems[i];
        if (!itO) continue;
        if (itO.kind === "payBuf") {
          var uids = itO.uids;
          if (!uids || uids.length === 0) continue;
          var strideB = cfg.stackStrideX;
          var stack = [];
          var jB;
          for (jB = 0; jB < uids.length; jB++) {
            var uidB = uids[jB];
            if (!uidB) continue;
            stack.push({ kind: "payBufCard", uid: uidB, x: itO.x + jB * strideB, y: itO.y, depth: jB });
          }
          drawFannedStack(stack, { state: s, fanDir: 1, flip180: false, camX: 0, selectedItem: null, drawSelected: false, highlightCol: hlCol });
        }
      }
    }

    // Overlay content area (right side).
    var C = R.center;
    var xPrev = C.preview.x;
    var yPrev = C.preview.y;
    var xTitle = C.title.x;
    var yTitle = C.title.y;
    var xDesc = C.desc.x;
    var yDesc = C.desc.y;

    var panel = null;
    if (view.inspectActive) {
      var Lp = MC.config.render.layout;
      panel = {
        x0: Lp.inspectPanelX0,
        y0: Lp.inspectPanelY0,
        x1: Lp.inspectPanelX1,
        y1: Lp.inspectPanelY1
      };
      rectSafe(panel.x0, panel.y0, panel.x1 - panel.x0 + 1, panel.y1 - panel.y0 + 1, cfg.colInspectPanelFill);
      rectbSafe(panel.x0, panel.y0, panel.x1 - panel.x0 + 1, panel.y1 - panel.y0 + 1, cfg.colCenterPanelBorder);

      var padX = Lp.inspectPanelPadX;
      var padY = Lp.inspectPanelPadY;
      var gapX = Lp.inspectTitleGapX;
      var descDy = Lp.inspectDescDy;
      xPrev = panel.x0 + padX;
      yPrev = panel.y0 + padY;
      xTitle = xPrev + cfg.faceW + gapX;
      yTitle = yPrev;
      xDesc = xTitle;
      yDesc = yTitle + descDy;
    }

    function drawInspectForSelection(sel) {
      if (!sel) return;

      // Non-card center widgets.
      if (sel.row === R.ROW_CENTER && !sel.uid) {
        if (sel.kind === "deck") {
          printSafe("Deck", xTitle, yTitle, cfg.colText);
          var deckDesc = "Cards: " + s.deck.length;
          if (dbgEnabled && s.deck.length > 0) {
            var topUid = s.deck[s.deck.length - 1];
            drawMiniCard(s, topUid, xPrev, yPrev, false);
            var defT = MC.state.defByUid(s, topUid);
            if (defT && defT.name) deckDesc += "\nTop: " + String(defT.name);
          }
          printExSafe(deckDesc, xDesc, yDesc, cfg.colText, false, 1, true);
          return;
        }
        if (sel.kind === "discard") {
          printSafe("Discard", xTitle, yTitle, cfg.colText);
          var discardDesc = "Cards: " + s.discard.length;
          if (s.discard.length > 0) {
            var topUid2 = s.discard[s.discard.length - 1];
            drawMiniCard(s, topUid2, xPrev, yPrev, false);
            var defD = MC.state.defByUid(s, topUid2);
            if (defD && defD.name) discardDesc += "\nTop: " + String(defD.name);
          }
          printExSafe(discardDesc, xDesc, yDesc, cfg.colText, false, 1, true);
          return;
        }
        if (sel.kind === "btn") {
          var title = String(sel.label || sel.id || "");
          printSafe(title, xTitle, yTitle, cfg.colText);
          var help = "";
          if (sel.id === "endTurn") help = "End your turn.\nIf hand > 7, discard down.";
          else if (sel.id === "mainMenu") help = "Return to the title\nscreen.";
          else if (sel.id === "step") help = "Debug: step 1 random\nlegal move.";
          else if (sel.id === "reset") help = "Debug: reset current\nscenario.";
          else if (sel.id === "nextScenario") help = "Debug: switch to next\nscenario.";
          printExSafe(help, xDesc, yDesc, cfg.colText, false, 1, true);
          return;
        }
      }

      // Card selection.
      if (!sel.uid) return;
      var uid = sel.uid;
      var def = MC.state.defByUid(s, uid);
      if (!def) return;

      // Opponent hand is hidden unless debug enabled.
      if (!dbgEnabled && sel.row === R.ROW_OP_HAND) {
        printSafe("Opponent card", xTitle, yTitle, cfg.colText);
        printExSafe("(hidden)", xDesc, yDesc, cfg.colText, false, 1, false);
        return;
      }

      drawMiniCard(s, uid, xPrev, yPrev, false, sel.color);
      printSafe(MC.fmt.inspectTitleForDef(def), xTitle, yTitle, cfg.colText);
      var desc = MC.fmt.inspectDescForDef(def, sel.color);
      printExSafe(desc, xDesc, yDesc, cfg.colText, false, 1, true);
    }

    function drawMenuOverlay() {
      var src = view.menu && view.menu.src ? view.menu.src : null;
      if (src && src.uid) drawMiniCard(s, src.uid, xPrev, yPrev, false);
      printSafe("Menu", xTitle, yTitle - 1, cfg.colText);
      var items = (view.menu && view.menu.items) ? view.menu.items : [];
      var selI = view.menu ? view.menu.i : 0;
      if (selI < 0) selI = 0;
      if (selI >= items.length) selI = items.length - 1;
      var j;
      var y = yDesc - 1;
      var boxX = xDesc - 2;
      var boxY = y - 2;
      var boxW = cfg.screenW - boxX - cfg.rowPadX;
      // Menu height is clamped so the border never overlaps the control hints line.
      var hintY = y1 - 7; // smallfont
      var boxH = (items.length * 7 + 10);
      // Let the box sit 1px closer to the hint band to fit 3 items cleanly.
      var maxH = (hintY - 2) - boxY;
      if (maxH > 0 && boxH > maxH) boxH = maxH;
      if (boxH < 16) boxH = 16;
      rectSafe(boxX, boxY, boxW, boxH, MC.Pal.Black);
      rectbSafe(boxX, boxY, boxW, boxH, cfg.colCenterPanelBorder);

      for (j = 0; j < items.length; j++) {
        var yy = y + j * 7;
        var label = String(items[j].label || items[j].id || "");
        if (j === selI) {
          rectSafe(boxX + 1, yy - 1, boxW - 2, 7, hlCol);
          printSafe(label, xDesc, yy, MC.Pal.Black);
        } else {
          printSafe(label, xDesc, yy, cfg.colText);
        }
      }
      var useMouse = !!view.ux.autoFocusPausedByMouse;
      var hint = useMouse ? "Click:Select  Right:Back" : "A:Select  B:Back";
      printExSafe(hint, xDesc, hintY, cfg.colText, false, 1, true);
    }

    function drawTargetingOverlay() {
      var t = view.targeting;
      if (!t || !t.active) return;
      if (t.card && t.card.uid) drawMiniCard(s, t.card.uid, xPrev, yPrev, false, (t.wildColor !== MC.state.NO_COLOR) ? t.wildColor : null);

      var cmd = (t.cmds && t.cmds.length) ? t.cmds[t.cmdI % t.cmds.length] : null;

      var title = MC.fmt.targetingTitle(t, cmd);
      printSafe(title, xTitle, yTitle, cfg.colText);
      var destLine = MC.fmt.targetingDestLine(s, t, cmd);
      var boxX = xDesc - 2;
      var boxY = yDesc - 2;
      var boxW = cfg.screenW - boxX - cfg.rowPadX;
      var boxH = 30;
      rectSafe(boxX, boxY, boxW, boxH, MC.Pal.Black);
      rectbSafe(boxX, boxY, boxW, boxH, cfg.colCenterPanelBorder);

      printExSafe(destLine, xDesc, yDesc, cfg.colText, false, 1, false);

      var help = MC.fmt.targetingHelp(t);
      printExSafe(help, xDesc, y1 - 18, cfg.colText, false, 1, true);
    }

    if (view.mode === "menu") drawMenuOverlay();
    else if (view.mode === "targeting") drawTargetingOverlay();
    else if (view.inspectActive) {
      drawInspectForSelection(selectedItem);
    }
  }

  function drawPlaysPips(state) {
    var cfg = R.cfg;
    if (!state) return;
    if (cfg.hudLineEnabled === false) return;
    var maxPlays = 3;
    var playsLeft = state.playsLeft;
    if (playsLeft < 0) playsLeft = 0;
    if (playsLeft > maxPlays) playsLeft = maxPlays;
    var used = maxPlays - playsLeft;
    if (used < 0) used = 0;
    if (used > maxPlays) used = maxPlays;

    var x0 = cfg.hudLineX;
    var y0 = cfg.hudLineY;
    var dx = 6; // 6px font cell width
    var i;
    for (i = 0; i < maxPlays; i++) {
      var col = (i < used) ? MC.Pal.Red : MC.Pal.Green;
      printSafe("o", x0 + i * dx, y0, col);
    }
  }

  function drawModeHintNearButtons(view, computed) {
    var cfg = R.cfg;
    if (cfg.hudLineEnabled === false) return;
    var dbgEnabled = !!(MC.config.debug.enabled && MC.debug.toolsOn);
    if (!dbgEnabled) return;
    // Prompts don't overlap this hint, so keep it visible in prompt mode too.
    if (!view || (view.mode !== "browse" && view.mode !== "prompt") || view.inspectActive) return;
    if (!computed || !computed.models) return;
    var rowM = computed.models[R.ROW_CENTER];
    if (!rowM || !rowM.items) return;

    // Only show this hint when debug buttons exist (Step/Reset/Next visible).
    var hasDebugBtn = false;
    var minBtnX = null;
    var maxBtnY = null;
    var i;
    for (i = 0; i < rowM.items.length; i++) {
      var it = rowM.items[i];
      if (!it || it.kind !== "btn") continue;
      if (it.id === "step" || it.id === "reset" || it.id === "nextScenario") hasDebugBtn = true;
      if (minBtnX == null || it.x < minBtnX) minBtnX = it.x;
      var yy = it.y + it.h;
      if (maxBtnY == null || yy > maxBtnY) maxBtnY = yy;
    }
    if (!hasDebugBtn || minBtnX == null || maxBtnY == null) return;

    // If debug buttons extend below the center row band (e.g. due to extra buttons),
    // keep the hint anchored inside the center row so it doesn't overlap gameplay rows.
    var yMaxCenter = rowY1(R.ROW_CENTER) + 1;
    if (maxBtnY > yMaxCenter) maxBtnY = yMaxCenter;

    // Place left of the strip, aligned to its bottom.
    var x = minBtnX - 52;
    if (x < cfg.rowPadX) x = cfg.rowPadX;
    var y = maxBtnY - 7; // 6px font + 1
    printSafe("Y:Mode", x, y, cfg.colHudLine);
  }

  function drawToasts(view) {
    var cfg = R.cfg;
    if (!view || !view.toasts || view.toasts.length === 0) return;

    var charW = 6;
    var lineH = 7;
    var padX = 6;
    var padY = 4;

    var yCursor = 2;
    var ti;
    for (ti = 0; ti < view.toasts.length; ti++) {
      var t = view.toasts[ti];
      if (!t || !t.text) continue;
      var msg = String(t.text);
      if (!msg) continue;

      var parts = msg.split("\n");
      if (parts.length > 2) parts = [parts[0], parts[1]];
      var maxLen = 0;
      var i;
      for (i = 0; i < parts.length; i++) if (parts[i].length > maxLen) maxLen = parts[i].length;

      var kind = t.kind ? String(t.kind) : "";
      var isError = (kind === "error");
      var iconW = isError ? 10 : 0;
      var boxW = (padX * 2) + iconW + maxLen * charW;
      if (boxW > cfg.screenW - 8) boxW = cfg.screenW - 8;
      var boxH = (padY * 2) + parts.length * lineH;

      var x0 = Math.floor((cfg.screenW - boxW) / 2);
      var y0 = yCursor;

      var bgCol = MC.Pal.Black;
      if (kind === "ai") bgCol = cfg.colToastBgAi;
      rectSafe(x0, y0, boxW, boxH, bgCol);
      rectbSafe(x0, y0, boxW, boxH, cfg.colCenterPanelBorder);
      rectSafe(x0, y0 + boxH, boxW, 1, cfg.colShadow);

      var textX = x0 + padX + iconW;
      if (isError) {
        printSafe("X", x0 + 4, y0 + padY, MC.Pal.Red);
      }
      for (i = 0; i < parts.length; i++) {
        // Fixed-width makes centering math exact (avoids proportional font whitespace).
        printExSafe(parts[i], textX, y0 + padY + i * lineH, cfg.colText, true, 1, false);
      }

      yCursor += boxH + 2;
      if (yCursor > cfg.screenH - 8) break;
    }
  }

  R.drawToasts = drawToasts;

  function groupStacksByKey(items, camX) {
    var byKey = {};
    var keys = [];
    var i;
    for (i = 0; i < items.length; i++) {
      var it = items[i];
      if (!it || !it.stackKey) continue;
      var k = String(it.stackKey);
      var a = byKey[k];
      if (!a) {
        a = [];
        byKey[k] = a;
        keys.push(k);
      }
      a.push(it);
    }

    // Stable visual ordering: sort stacks by their left edge on screen (after camera).
    keys.sort(function (ka, kb) {
      var aa = byKey[ka];
      var bb = byKey[kb];
      var mina = 999999;
      var minb = 999999;
      var j;
      for (j = 0; j < aa.length; j++) {
        var xa = aa[j].x - camX;
        if (xa < mina) mina = xa;
      }
      for (j = 0; j < bb.length; j++) {
        var xb = bb[j].x - camX;
        if (xb < minb) minb = xb;
      }
      return mina - minb;
    });

    return { byKey: byKey, keys: keys };
  }

  function drawRowCards(state, view, computed, rowModel, row, selected, cam, highlightCol) {
    var cfg = R.cfg;
    if (cam == null) cam = 0;
    if (highlightCol == null) highlightCol = cfg.colHighlight;
    var flipCards = MC.layout.isOpponentRow(row);
    var i;

    var overlayItems = rowModel && rowModel.overlayItems ? rowModel.overlayItems : null;
    var itemsForStacks = rowModel.items;
    if (overlayItems && overlayItems.length) itemsForStacks = itemsForStacks.concat(overlayItems);

    // Hide the source card when UI wants to represent its slot as a ghost/preview.
    var hideSrc = (computed && computed.meta && computed.meta.hideSrc) ? computed.meta.hideSrc : null;

    if (row === R.ROW_OP_TABLE || row === R.ROW_P_TABLE) {
      // When targeting moveWild, hide the source card in the table stack to avoid duplicating it
      // at both the source and preview destination.
      var selT = selected;
      if (hideSrc && hideSrc.loc && String(hideSrc.loc.zone) === "setProps") {
        // Remove the hidden card from the draw list.
        var outItems = [];
        for (i = 0; i < itemsForStacks.length; i++) {
          var itHid = itemsForStacks[i];
          if (!itHid || !itHid.loc) { outItems.push(itHid); continue; }
          if (itHid.uid === hideSrc.uid && itHid.loc.p === hideSrc.loc.p && String(itHid.loc.zone) === "setProps" && itHid.loc.setI === hideSrc.loc.setI && itHid.loc.i === hideSrc.loc.i) {
            continue;
          }
          outItems.push(itHid);
        }
        itemsForStacks = outItems;

        // Also suppress highlight if the selected item is the hidden one.
        if (selT && selT.loc && selT.uid === hideSrc.uid && selT.loc.p === hideSrc.loc.p && String(selT.loc.zone) === "setProps" && selT.loc.setI === hideSrc.loc.setI && selT.loc.i === hideSrc.loc.i) {
          selT = null;
        }
      }

      // Table rows must be drawn by stack depth (bottom->top), not x-order,
      // otherwise fan-left stacks layer incorrectly.
      var grouped = groupStacksByKey(itemsForStacks, cam);
      var byKey = grouped.byKey;
      var keys = grouped.keys;

      // Draw all stacks bottom->top, skipping selected.
      var si;
      for (si = 0; si < keys.length; si++) {
        var key = keys[si];
        var cards = byKey[key];
        var fanDir = (cards.length > 0 && cards[0].fanDir != null) ? cards[0].fanDir : (flipCards ? -1 : 1);
        drawFannedStack(cards, { state: state, fanDir: fanDir, flip180: !!flipCards, camX: cam, selectedItem: selT, drawSelected: false, highlightCol: highlightCol });
      }

      // Selected last + highlight.
      if (selT) {
        var sFan = (selT.fanDir != null) ? selT.fanDir : (flipCards ? -1 : 1);
        var sk = String(selT.stackKey);
        var stack = byKey[sk] || [selT];
        drawFannedStack(stack, { state: state, fanDir: sFan, flip180: !!flipCards, camX: cam, selectedItem: selT, onlySelected: true, highlightCol: highlightCol });
      }
      return;
    }

    // Hand rows (and opponent back row): simple x-order is fine for non-stack items.
    var groupedH = groupStacksByKey(itemsForStacks, cam);
    var byKeyH = groupedH.byKey;
    var keysH = groupedH.keys;

    // Draw non-bank hand items in x-order first.
    for (i = 0; i < rowModel.items.length; i++) {
      var it = rowModel.items[i];
      if (!it || it.stackKey) continue;
      if (selected && it === selected) continue;
      if (hideSrc && row === R.ROW_P_HAND && it.loc && (it.loc.zone === "hand" || it.loc.zone === "recvProps")) {
        if (it.uid === hideSrc.uid && it.loc.p === hideSrc.loc.p && String(it.loc.zone) === String(hideSrc.loc.zone) && it.loc.i === hideSrc.loc.i) {
          continue;
        }
      }
      var x = it.x - cam;
      var y = it.y;
      if (row === R.ROW_OP_HAND) {
        drawShadowBar(x, y);
        drawCardBack(x, y);
      } else if (row === R.ROW_P_HAND) {
        drawShadowBar(x, y);
        drawMiniCard(state, it.uid, x, y, !!flipCards);
      }
    }

    // Draw stack(s) bottom->top so overlap shadows remain visible (bank is a stack in hand rows).
    var ki;
    for (ki = 0; ki < keysH.length; ki++) {
      var k0 = keysH[ki];
      var stack0 = byKeyH[k0];
      if (!stack0 || stack0.length === 0) continue;
      var fanDirB = (stack0[0].fanDir != null) ? stack0[0].fanDir : 1;
      var flipBank = (row === R.ROW_OP_HAND);
      var selInThis = (selected && selected.stackKey === k0) ? selected : null;
      var camForThis = cam;
      drawFannedStack(stack0, { state: state, fanDir: fanDirB, flip180: !!flipBank, camX: camForThis, selectedItem: selInThis, drawSelected: false, highlightCol: highlightCol });
    }

    // Skip drawing the source selection highlight during hold-targeting; preview handles the feedback.
    var sel = selected;
    if (hideSrc && row === R.ROW_P_HAND && sel && sel.loc && (sel.loc.zone === "hand" || sel.loc.zone === "recvProps")) {
      if (sel.uid === hideSrc.uid && sel.loc.p === hideSrc.loc.p && String(sel.loc.zone) === String(hideSrc.loc.zone) && sel.loc.i === hideSrc.loc.i) {
        sel = null;
      }
    }

    if (sel) {
      var xs = sel.x - cam;
      var ys = sel.y;
      if (row === R.ROW_OP_HAND) {
        if (sel.stackKey) {
          var sFanO = (sel.fanDir != null) ? sel.fanDir : -1;
          var stackO = byKeyH[String(sel.stackKey)] || [sel];
          drawFannedStack(stackO, { state: state, fanDir: sFanO, flip180: true, camX: cam, selectedItem: sel, onlySelected: true, highlightCol: highlightCol });
        } else {
          drawShadowBar(xs, ys);
          drawCardBack(xs, ys);
          drawHighlight(xs, ys, highlightCol);
        }
      } else if (row === R.ROW_P_HAND) {
        if (sel.stackKey) {
          var sFanP = (sel.fanDir != null) ? sel.fanDir : 1;
          var stackP = byKeyH[String(sel.stackKey)] || [sel];
          drawFannedStack(stackP, { state: state, fanDir: sFanP, flip180: false, camX: cam, selectedItem: sel, onlySelected: true, highlightCol: highlightCol });
        } else {
          drawShadowBar(xs, ys);
          drawMiniCard(state, sel.uid, xs, ys, !!flipCards);
          drawHighlight(xs, ys, highlightCol);
        }
      }
    }
  }

  R.debug = {};

  // DebugText support: summarize current Render selection without drawing.
  R.debug.selectedLines = function (debug) {
    if (!debug || !debug.state) return ["Sel:(none)", ""];
    var it = null;
    if (debug.view) {
      var computed = MC.ui.computeRowModels(debug.state, debug.view);
      it = computed ? computed.selected : null;
    }
    if (!it) return ["Sel:(none)", ""];

    if (it.row === R.ROW_CENTER) {
      if (it.kind === "deck") return ["Sel:Deck", "Cards:" + debug.state.deck.length];
      if (it.kind === "discard") return ["Sel:Discard", "Cards:" + debug.state.discard.length];
      return ["Sel:" + String(it.kind || "?"), ""];
    }

    if (it.uid) {
      var uid = it.uid;
      var def = MC.state.defByUid(debug.state, uid);
      var defId = def ? def.id : "?";
      var line2 = (def && def.name) ? def.name : "";

      if (def && def.kind === MC.CardKind.Property) {
        if (MC.rules.isWildDef(def)) {
          var c0 = def.wildColors[0];
          var c1 = def.wildColors[1];
          line2 = "Wild:" + MC.fmt.colorName(c0) + "/" + MC.fmt.colorName(c1);
          if (it.color != null && it.color !== MC.state.NO_COLOR) {
            line2 += " as " + MC.fmt.colorName(it.color);
          }
        } else {
          line2 = "Prop:" + MC.fmt.colorName(def.propertyColor);
        }
      }

      return ["Sel:" + defId + " uid:" + uid, line2];
    }

    return ["Sel:" + String(it.kind || "?"), ""];
  };

  // Renderer is oblivious to `view.anim`; UI/anim modules provide presentation in `computed`.
  function drawAnimOverlay(state, view, computed) {
    if (!state || !view || !computed) return;
    var ov = computed.animOverlay;
    if (!ov || !ov.kind) return;
    if (ov.kind === "dealCard") {
      var x = ov.x;
      var y = ov.y;
      var p = ov.p;
      var uid = ov.uid;
      drawShadowBar(x, y);
      if (p === 1) drawCardBack(x, y);
      else drawMiniCard(state, uid, x, y, false);
    } else if (ov.kind === "moveCard") {
      var x2 = ov.x;
      var y2 = ov.y;
      var uid2 = ov.uid;
      var flip180 = !!ov.flip180;
      drawShadowBar(x2, y2);
      drawMiniCard(state, uid2, x2, y2, flip180);
      if (ov.outlinePal != null) {
        rectbSafe(x2 - 1, y2 - 1, R.cfg.faceW, R.cfg.faceH, MC.Pal.Black);
        rectbSafe(x2, y2, R.cfg.faceW, R.cfg.faceH, ov.outlinePal);
      }
    }
  }

  function drawGameOverFx(computed) {
    if (!computed || !computed.gameOverFx) return;
    var fx = computed.gameOverFx;
    if (!fx || !fx.parts || fx.parts.length === 0) return;

    var cfg = R.cfg;
    var W = cfg.screenW;
    var H = cfg.screenH;

    var parts = fx.parts;
    var i;
    for (i = 0; i < parts.length; i++) {
      var p = parts[i];
      if (!p || p.delay > 0 || p.done) continue;
      var x = p.x;
      var y = p.y;
      var w = p.w;
      var h = p.h;
      if (!(w > 0)) w = 1;
      if (!(h > 0)) h = 1;
      if (w > 3) w = 3;
      if (h > 3) h = 3;

      // Clip vertically.
      var y0 = y;
      var y1 = y + h - 1;
      if (y1 < 0 || y0 >= H) continue;
      if (y0 < 0) y0 = 0;
      if (y1 >= H) y1 = H - 1;
      var hh = y1 - y0 + 1;
      if (!(hh > 0)) continue;

      // Note: x is wrapped during tick; clamp defensively.
      if (x < 0 || x >= W) continue;
      if (x + w > W) w = W - x;
      if (!(w > 0)) continue;

      rectSafe(x, y0, w, hh, p.col);

      // Glisten band (more noticeable than a single pixel).
      if (p.flash > 0 && hh > 0) {
        var yH = ((p.flash % 2) === 0) ? y0 : (y0 + hh - 1);
        rectSafe(x, yH, w, 1, MC.Pal.White);
      }
    }
  }

  function drawGameplayUiScene(state, view, computed, models, sel, hlCol) {
    var cfg = R.cfg;

    // Draw non-center rows.
    var row;
    for (row = 0; row < 5; row++) {
      if (row === R.ROW_CENTER) continue;
      var rm = models[row];
      if (!rm || !rm.items) continue;
      var cam = (view.camX && view.camX[row] != null) ? view.camX[row] : 0;
      var selected = (sel && sel.row === row) ? sel : null;
      drawRowCards(state, view, computed, rm, row, selected, cam, hlCol);
    }

    // Center panel last (so text overlays are readable).
    drawCenter(state, view, computed, sel, hlCol);

    // Animations on top of scene (but under toasts).
    drawAnimOverlay(state, view, computed);

    // Game-over FX on top of scene (under UI chrome + toasts).
    drawGameOverFx(computed);

    // Highlight center widgets if selected.
    if (sel && sel.row === R.ROW_CENTER) {
      rectbSafe(sel.x - 1, sel.y - 1, sel.w + 2, sel.h + 2, hlCol);
    }

    drawPlaysPips(state);
    drawModeHintNearButtons(view, computed);

    // Mouse drag-and-drop: floating source card under cursor when dragging and not snapped.
    if (
      view.mode === "targeting" &&
      view.targeting &&
      view.targeting.active &&
      view.targeting.mouse &&
      view.targeting.mouse.dragMode &&
      view.targeting.mouse.dragging &&
      !view.targeting.mouse.snapped
    ) {
      var uidDrag = (view.targeting.card && view.targeting.card.uid) ? view.targeting.card.uid : 0;
      if (uidDrag) {
        var faceW = cfg.faceW;
        var faceH = cfg.faceH;
        var xF = view.targeting.mouse.x - Math.floor(faceW / 2);
        var yF = view.targeting.mouse.y - Math.floor(faceH / 2);
        if (xF < 0) xF = 0;
        if (yF < 0) yF = 0;
        if (xF > (cfg.screenW - faceW)) xF = cfg.screenW - faceW;
        if (yF > (cfg.screenH - faceH)) yF = cfg.screenH - faceH;
        var asColor = (view.targeting.wildColor !== MC.state.NO_COLOR) ? view.targeting.wildColor : null;
        drawShadowBar(xF, yF);
        drawMiniCard(state, uidDrag, xF, yF, false, asColor);
        drawHighlight(xF, yF, hlCol);
      }
    }
    drawToasts(view);
  }

  R.drawFrame = function (args) {
    if (!args) return;
    var state = args.state || (args.debug && args.debug.state) || args.state;
    var view = args.view || (args.debug && args.debug.view) || args.view;
    if (!state || !view) return;

    var computed = args.computed;
    if (!computed) computed = MC.ui.computeRowModels(state, view);
    if (!computed || !computed.models) return;

    var models = computed.models;
    // UI owns cursor/selection policy (clamping, relocation off empty rows, etc.).
    // Renderer should trust the computed selection rather than re-deriving from view.cursor.
    var sel = computed.selected || null;

    var cfg = R.cfg;
    var hlCol = (computed.highlightCol != null) ? computed.highlightCol : cfg.colHighlight;

    // Base bank: background (uses vbank(0) palette).
    vbank(0);
    cls(cfg.colBg);
    drawGameplayBg();

    // Overlay bank: UI (cleared to transparent index each frame).
    R.vbankBeginOverlay();

    drawGameplayUiScene(state, view, computed, models, sel, hlCol);

    // Always restore bank 0 so other modes render normally.
    vbank(0);
  };
})();

