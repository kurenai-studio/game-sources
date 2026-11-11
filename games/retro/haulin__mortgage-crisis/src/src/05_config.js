// MC.config: central gameplay/UI/render tuning knobs (validated in tests; avoid runtime fallbacks).
MC.config = {
  screenW: 240,
  screenH: 136,
  seedBase: 1005
};

MC.config.meta = {
  version: "Demo v0.22"
};

MC.config.debug = {
  enabled: false
};

// Controller UX knobs. All values are in frames (TIC runs at 60fps).
MC.config.controls = {
  dpadRepeatDelayFrames: 12,
  dpadRepeatPeriodFrames: 4,
  aHoldFallbackFrames: 18,
  xInspectDelayFrames: 6
};

// Mouse/touch UX knobs.
MC.config.mouse = {
  enabled: true,
  // Drag starts when the pointer moves >= this many pixels while left is held.
  dragStartPx: 3,
  // Extra padding around snap hitboxes (pixels).
  snapPadPx: 2,
  // Map scroll wheel to nav Up/Down pulses.
  wheelNav: true,
  // Invert scroll wheel Y mapping to Up/Down nav.
  wheelInvertY: true,
  // Allow hover to move the selection outline.
  hoverSelect: true
};

// UI/navigation tuning.
MC.config.ui = {
  // Directional navigation cone penalty multiplier (per-axis):
  // used by MC.ui.navPickInDirection scoring:
  // score = along^2 + (perp^2)*k
  //
  // Bigger k => narrower cone (harder to jump across rows/columns).
  // k must be > 0. Typical values are ~4..30.
  //
  // - Left/Right usually wants a *narrower* cone to avoid jumping to other rows.
  // - Up/Down can stay more permissive.
  navConeKLeftRight: 18,
  navConeKUpDown: 6,

  // Debug aid: multiply timings for slow-motion debugging (1 = normal speed).
  animSpeedMult: 1.5,
  dealFramesPerCard: 8,
  dealGapFrames: 2,
  xferFramesPerCard: 8,
  xferGapFrames: 2,
  xferHoldFromFrames: 18,
  xferHoldFrames: 12,
  gameStartToastFrames: 60,
  shuffleAnimFrames: 42,
  shuffleToastFrames: 42,

  // Game-over presentation FX (purely visual; should not lock input).
  gameOverFxParticles: 420,
  gameOverFxFlashChance1In: 20,
  gameOverFxFlashFrames: 18,
  gameOverFxNudgeChance1In: 12,

  aiStepDelayFrames: 60,
  aiNarrateToastFrames: 60,

  toast: {
    infoFrames: 90,
    errorFrames: 90
  },

  slyShowTargetGhosts: false
};

MC.config.title = {
  // Marketing screenshot mode: hide Title chrome (menu/controls/subtitle/version/toasts).
  marketingCaptureMode: false,

  menuW: 90,

  logoScale: 3,
  logoX: 10,
  logoY: 18,

  subtitleText: "Inspired by Monopoly Deal",
  subtitleX: 34,
  subtitleY: 69,

  controlsX: 20,
  controlsW: 117,
  controlsH: 40,
  controlsBottomY: 8,

  menuY: 50,
  menuDy: 12,
  menuArrowX: 6,
  menuTextX: 12,
  menuItemBoxes: true,
  menuItemGapY: 4,
  menuItemBoxPadY: 4,

  bgTileSprId: 34
};

MC.config.ai = {
  // Per-player policy IDs (0=player, 1=opponent by default).
  policyByP: ["defaultHeuristic", "defaultHeuristic"],

  // Policy weight multipliers; 1 means neutral (equivalent to uniform random).
  biasExistingSetK: 8,
  biasPayDebtFromBankK: 8,

  biasEarlyBankBufferTarget: 3,
  biasEarlyEmptyHandKeepActionsMaxHand: 2,
  biasEarlyBankMoneyK: 6,
  biasEarlyEndTurnOverBankActionsK: 6,
  biasEarlyPlayRentIfPayableK: 3,
  biasEarlyPlaceWhenHoldingRentK: 2,

  biasPlayRentK: 4,
  biasPlaySlyDealK: 8,
  biasPlayJustSayNoK: 8,
  biasMoveWildK: 8
};

MC.config.rules = {
  // List of enabled RuleNote IDs to show in Inspect.
  // Note: keep this intentionally small; it's easy to mislead players with future-rule text.
  enabledRuleNotes: [
    MC.RuleNote.SlyDeal_NotFromFullSet
  ]
};

// TIC-80 default palette is Sweetie-16.
// These are palette *indices* (0..15), not RGB values.
MC.Pal = {
  Black: 0,       // #1a1c2c
  Purple: 1,      // #5d275d
  Red: 2,         // #b13e53
  Orange: 3,      // #ef7d57
  Yellow: 4,      // #ffcd75
  LightGreen: 5,  // #a7f070
  Green: 6,       // #38b764
  DarkGreen: 7,   // #257179
  DarkBlue: 8,    // #29366f
  Blue: 9,        // #3b5dc9
  LightBlue: 10,  // #41a6f6
  Cyan: 11,       // #73eff7
  White: 12,      // #f4f4f4
  LightGrey: 13,  // #94b0c2
  Grey: 14,       // #566c86
  DarkGrey: 15,   // #333c57
};

MC.config.howto = {
  padX: 8,
  padY: 6,

  headerH: 10,
  footerH: 2,

  // Typography: fixed-width for predictable wrapping.
  headingCharW: 6,
  headingLineH: 7,
  bodyCharW: 4,
  bodyLineH: 6,

  // Layout spacing.
  blockGapY: 10,
  demoGapX: 6,
  demoGapY: 3,

  scrollStepPx: 6,

  colBg: MC.Pal.Black,
  colPanel: MC.Pal.DarkBlue,
  colBorder: MC.Pal.Grey,
  colTitle: MC.Pal.White,
  colHeading: MC.Pal.White,
  colText: MC.Pal.LightGrey,
  colMuted: MC.Pal.LightGrey,
  colAccent: MC.Pal.Yellow,
};

MC.config.render = {
  // Layout knobs: geometry + positions.
  layout: {
    screenW: MC.config.screenW,
    screenH: MC.config.screenH,

    // Row bands (0-based, inclusive bounds are derived).
    rowY: [0, 12, 39, 82, 109],
    rowH: [12, 27, 43, 27, 27],

    faceW: 17,
    faceH: 25,
    highlightPad: 1, // outside face border

    // Row placement rules for rows 2/4/5 (27px tall).
    faceInsetY: 1,

    // Stacks
    stackStrideX: 8, // next face origin
    stackGapX: 2,
    shadowBarDx: -1, // xFace-1

    // Hands
    handStrideX: 18,

    // Camera
    camMarginX: 12,
    rowPadX: 4,

    // Plays left indicator
    hudLineEnabled: true,
    hudLineX: 6,
    hudLineY: 74,

    // Center row
    centerTopInsetY: 4,
    centerDeckX: 6,
    centerPileGapX: 6,
    // Payment/transfer buffer anchor (screen-space x).
    // Y uses rowY[ROW_CENTER] + centerTopInsetY to match deck/discard.
    centerPayBufX: 48,
    centerPreviewX: 70,
    centerPreviewGapX: 8,
    centerDescDy: 8,

    // Center row button strip.
    centerBtnStripW: 39,
    centerBtnStripPadRight: 1,

    // Inspect panel: screen-space panel bounds.
    // These are absolute so we can tune without coupling to centerPreviewX.
    inspectPanelX0: 48,
    inspectPanelY0: 35,
    inspectPanelX1: 198,
    inspectPanelY1: 85,
    // Content anchors derived from the panel.
    inspectPanelPadX: 2,
    inspectPanelPadY: 2,
    inspectTitleGapX: 2,
    inspectDescDy: 8,

    // Pile depth under-layers (visual only)
    pileUnderDx1: 2,
    pileUnderDy1: 2,
    pileUnderDx2: 4,
    pileUnderDy2: 4
  },

  // Style knobs: colors + template anchors + glyph/icon parameters.
  style: {
    // Digit glyph placement is 3x5; sprite tile may include a 1px border.
    digitGlyphW: 3,
    digitGlyphH: 5,
    digitTile: 8,
    glyphInsetX: 1, // inner glyph top-left in the 8x8 tile
    glyphInsetY: 1,
    sprColorkey: 15,

    // Dual-color property anchors (0-based, card-local).
    propValueX: 1,
    propValueY: 1,
    propBarX: 5,
    propBarY: 1,
    propBarW: 11,
    propBarH: 5,
    propRentX: 1,
    propRentY: 7,
    propRentDx: 4, // 3px glyph + 1px gap

    // Money/Action/House template anchors (card-local).
    valX: 1,
    valY: 1,
    // 15x15 (effective) center icon (2x2 sprite block with colorkey padding row/col).
    iconX: 1,
    iconY: 6,

    colBg: MC.Pal.Black,
    colText: MC.Pal.White,
    colCardBorder: MC.Pal.White,
    colCardInterior: MC.Pal.White,
    colShadow: MC.Pal.Black,
    colHighlight: MC.Pal.Yellow,
    colCenterPanelBorder: MC.Pal.LightGrey,
    colHudLine: MC.Pal.White,
    colToastBgAi: MC.Pal.DarkBlue,

    // Center pile depth outlines
    colPileShadowOutline: MC.Pal.Black,
    colPileOutlineUnder1: MC.Pal.LightGrey,
    colPileOutlineUnder2: MC.Pal.Grey,

    colInspectPanelFill: MC.Pal.DarkGreen,

    // Deck/Discard pile count digit offset.
    pileCountDx: 1,
    pileCountDy: 1
  },

  // Sprite IDs (kept together for easy remap).
  spr: {
    // Reserve 0 as blank (convention).
    digit0: 1, // digit sprite IDs are digit0 + n

    // Gameplay background: top-left tile id of a 2x2 (16x16) tile.
    bgTileTL: 96,

    // Card back: top-left 8x8 tile id used as a repeatable pattern.
    cardBackTL: 32,

    // Center panel dither fill (8x8 tile; uses colorkey holes so bg shows through).
    centerPanelFillTile: 78,

    // Optional icons (0 = skip).
    iconMoney: 36,
    iconRent: 44,
    iconSlyDeal: 40,
    iconJSN: 42,
    iconHouse: 38
  },

  moneyBgByValue: [
    0,
    MC.Pal.Yellow,     // 1
    MC.Pal.Red,        // 2
    MC.Pal.LightGreen, // 3
    MC.Pal.LightBlue,  // 4
    MC.Pal.Purple      // 5
  ]
};

