import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";
import { loadSrcIntoVm } from "./helpers/loadSrcIntoVm.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..");
const SRC_DIR = path.join(REPO_ROOT, "src");

async function loadSrcFilesIntoVm(fileNames) {
  const context = vm.createContext({
    cls: () => {},
    print: () => {},
    rect: () => {},
    rectb: () => {},
    line: () => {},
    spr: () => {},
    btn: () => 0,
    btnp: () => 0,
    console
  });

  for (const fileName of fileNames) {
    const source = await fs.readFile(path.join(SRC_DIR, fileName), "utf8");
    new vm.Script(source, { filename: `src/${fileName}` }).runInContext(context);
  }

  return context;
}

test("config sanity: render.layout/style/spr/moneyBgByValue shape", async () => {
  // Load only prelude+defs+config so this test can't be masked by later modules.
  const ctx = await loadSrcFilesIntoVm(["00_prelude.js", "04_defs.js", "05_config.js"]);
  const { MC } = ctx;
  assert.equal(typeof MC, "object", "expected MC object");
  assert.equal(typeof MC.config, "object", "expected MC.config");
  assert.equal(typeof MC.config.render, "object", "expected MC.config.render");

  const r = MC.config.render;
  assert.equal(typeof r.layout, "object", "expected MC.config.render.layout");
  assert.equal(typeof r.style, "object", "expected MC.config.render.style");
  assert.equal(typeof r.spr, "object", "expected MC.config.render.spr");
  assert.ok(Array.isArray(r.moneyBgByValue), "expected MC.config.render.moneyBgByValue array");

  const L = r.layout;
  const S = r.style;

  const requireNum = (obj, key) =>
    assert.equal(typeof obj[key], "number", `expected ${key} to be a number`);

  const requirePosNum = (obj, key) => {
    requireNum(obj, key);
    assert.ok(Number.isFinite(obj[key]), `expected ${key} to be finite`);
    assert.ok(obj[key] > 0, `expected ${key} > 0`);
  };

  // (Background + vbank workflow are renderer concerns; config keeps only sprite IDs + style.)

  assert.ok(Array.isArray(L.rowY) && L.rowY.length === 5, "expected layout.rowY[5]");
  assert.ok(Array.isArray(L.rowH) && L.rowH.length === 5, "expected layout.rowH[5]");

  [
    "screenW",
    "screenH",
    "faceW",
    "faceH",
    "highlightPad",
    "faceInsetY",
    "stackStrideX",
    "stackGapX",
    "shadowBarDx",
    "handStrideX",
    "camMarginX",
    "rowPadX",
    "hudLineX",
    "hudLineY",
    "centerTopInsetY",
    "centerDeckX",
    "centerPileGapX",
    "centerPayBufX",
    "centerPreviewX",
    "centerPreviewGapX",
    "centerDescDy",
    "centerBtnStripW",
    "centerBtnStripPadRight",
    "inspectPanelX0",
    "inspectPanelY0",
    "inspectPanelX1",
    "inspectPanelY1",
    "inspectPanelPadX",
    "inspectPanelPadY",
    "inspectTitleGapX",
    "inspectDescDy",
    "pileUnderDx1",
    "pileUnderDy1",
    "pileUnderDx2",
    "pileUnderDy2"
  ].forEach((k) => requireNum(L, k));

  [
    "digitGlyphW",
    "digitGlyphH",
    "digitTile",
    "glyphInsetX",
    "glyphInsetY",
    "sprColorkey",
    "propValueX",
    "propValueY",
    "propBarX",
    "propBarY",
    "propBarW",
    "propBarH",
    "propRentX",
    "propRentY",
    "propRentDx",
    "valX",
    "valY",
    "iconX",
    "iconY",
    "colBg",
    "colText",
    "colCardBorder",
    "colCardInterior",
    "colShadow",
    "colHighlight",
    "colCenterPanelBorder",
    "colHudLine",
    "colToastBgAi",
    "colPileShadowOutline",
    "colPileOutlineUnder1",
    "colPileOutlineUnder2",
    "colInspectPanelFill",
    "pileCountDx",
    "pileCountDy"
  ].forEach((k) => requireNum(S, k));

  requirePosNum(r.spr, "digit0");
  requirePosNum(r.spr, "bgTileTL");
  requirePosNum(r.spr, "cardBackTL");
  requirePosNum(r.spr, "centerPanelFillTile");
});

test("config sanity: controls + ui knobs exist (avoid runtime fallbacks)", async () => {
  // Load only prelude+defs+config so we validate what ships in the cartridge.
  const ctx = await loadSrcFilesIntoVm(["00_prelude.js", "04_defs.js", "05_config.js"]);
  const { MC } = ctx;

  assert.equal(typeof MC.config.meta, "object", "expected MC.config.meta");
  assert.equal(typeof MC.config.meta.version, "string", "expected MC.config.meta.version string");
  assert.ok(MC.config.meta.version.length > 0, "expected MC.config.meta.version non-empty");

  assert.equal(typeof MC.config.controls, "object", "expected MC.config.controls");
  assert.equal(typeof MC.config.mouse, "object", "expected MC.config.mouse");
  assert.equal(typeof MC.config.ui, "object", "expected MC.config.ui");
  assert.equal(typeof MC.config.title, "object", "expected MC.config.title");
  assert.equal(typeof MC.config.howto, "object", "expected MC.config.howto");
  assert.equal(typeof MC.config.ai, "object", "expected MC.config.ai");
  assert.equal(typeof MC.config.ui.toast, "object", "expected MC.config.ui.toast");

  const requirePosNum = (obj, key) => {
    assert.equal(typeof obj[key], "number", `expected ${key} to be a number`);
    assert.ok(Number.isFinite(obj[key]), `expected ${key} to be finite`);
    assert.ok(obj[key] > 0, `expected ${key} > 0`);
  };

  const requireNum = (obj, key) => {
    assert.equal(typeof obj[key], "number", `expected ${key} to be a number`);
    assert.ok(Number.isFinite(obj[key]), `expected ${key} to be finite`);
  };

  const requireBool = (obj, key) =>
    assert.equal(typeof obj[key], "boolean", `expected ${key} to be a boolean`);

  // Controls (frames).
  requirePosNum(MC.config.controls, "dpadRepeatDelayFrames");
  requirePosNum(MC.config.controls, "dpadRepeatPeriodFrames");
  requirePosNum(MC.config.controls, "aHoldFallbackFrames");
  requirePosNum(MC.config.controls, "xInspectDelayFrames");

  // Mouse.
  requireBool(MC.config.mouse, "enabled");
  requirePosNum(MC.config.mouse, "dragStartPx");
  requireNum(MC.config.mouse, "snapPadPx");
  requireBool(MC.config.mouse, "wheelNav");
  requireBool(MC.config.mouse, "wheelInvertY");
  requireBool(MC.config.mouse, "hoverSelect");

  // Directional navigation cone penalties.
  requirePosNum(MC.config.ui, "navConeKLeftRight");
  requirePosNum(MC.config.ui, "navConeKUpDown");

  // Animation timings (frames).
  requirePosNum(MC.config.ui, "animSpeedMult");
  requirePosNum(MC.config.ui, "dealFramesPerCard");
  requirePosNum(MC.config.ui, "dealGapFrames");
  requirePosNum(MC.config.ui, "xferFramesPerCard");
  requirePosNum(MC.config.ui, "xferGapFrames");
  requirePosNum(MC.config.ui, "xferHoldFromFrames");
  requirePosNum(MC.config.ui, "xferHoldFrames");
  requirePosNum(MC.config.ui, "gameStartToastFrames");
  requirePosNum(MC.config.ui, "shuffleAnimFrames");
  requirePosNum(MC.config.ui, "shuffleToastFrames");
  requirePosNum(MC.config.ui, "gameOverFxParticles");
  requirePosNum(MC.config.ui, "gameOverFxFlashChance1In");
  requirePosNum(MC.config.ui, "gameOverFxFlashFrames");
  requirePosNum(MC.config.ui, "gameOverFxNudgeChance1In");
  requirePosNum(MC.config.ui, "aiStepDelayFrames");
  requirePosNum(MC.config.ui, "aiNarrateToastFrames");

  // Toast timings (frames).
  requirePosNum(MC.config.ui.toast, "infoFrames");
  requirePosNum(MC.config.ui.toast, "errorFrames");

  // UI knobs: Sly Deal targeting.
  assert.equal(typeof MC.config.ui.slyShowTargetGhosts, "boolean", "expected slyShowTargetGhosts boolean");

  // Title screen knobs.
  requireBool(MC.config.title, "marketingCaptureMode");
  requirePosNum(MC.config.title, "menuW");
  requirePosNum(MC.config.title, "logoScale");
  requirePosNum(MC.config.title, "logoX");
  requirePosNum(MC.config.title, "logoY");
  assert.equal(typeof MC.config.title.subtitleText, "string", "expected subtitleText string");
  assert.ok(MC.config.title.subtitleText.length > 0, "expected subtitleText non-empty");
  requirePosNum(MC.config.title, "subtitleX");
  requirePosNum(MC.config.title, "subtitleY");
  requirePosNum(MC.config.title, "controlsX");
  requirePosNum(MC.config.title, "controlsW");
  requirePosNum(MC.config.title, "controlsH");
  requirePosNum(MC.config.title, "controlsBottomY");
  requirePosNum(MC.config.title, "menuY");
  requirePosNum(MC.config.title, "menuDy");
  requirePosNum(MC.config.title, "menuArrowX");
  requirePosNum(MC.config.title, "menuTextX");
  assert.equal(typeof MC.config.title.menuItemBoxes, "boolean", "expected menuItemBoxes boolean");
  requireNum(MC.config.title, "menuItemGapY");
  requirePosNum(MC.config.title, "menuItemBoxPadY");
  requireNum(MC.config.title, "bgTileSprId");

  // How-to-play screen knobs.
  requirePosNum(MC.config.howto, "padX");
  requirePosNum(MC.config.howto, "padY");
  requirePosNum(MC.config.howto, "headerH");
  requirePosNum(MC.config.howto, "footerH");
  requirePosNum(MC.config.howto, "headingCharW");
  requirePosNum(MC.config.howto, "headingLineH");
  requirePosNum(MC.config.howto, "bodyCharW");
  requirePosNum(MC.config.howto, "bodyLineH");
  requirePosNum(MC.config.howto, "blockGapY");
  requirePosNum(MC.config.howto, "demoGapX");
  requirePosNum(MC.config.howto, "demoGapY");
  requirePosNum(MC.config.howto, "scrollStepPx");
  requireNum(MC.config.howto, "colBg");
  requireNum(MC.config.howto, "colPanel");
  requireNum(MC.config.howto, "colBorder");
  requireNum(MC.config.howto, "colTitle");
  requireNum(MC.config.howto, "colHeading");
  requireNum(MC.config.howto, "colText");
  requireNum(MC.config.howto, "colMuted");
  requireNum(MC.config.howto, "colAccent");

  // AI policy knobs.
  assert.ok(Array.isArray(MC.config.ai.policyByP), "expected MC.config.ai.policyByP array");
  assert.equal(MC.config.ai.policyByP.length, 2, "expected MC.config.ai.policyByP length=2");
  assert.equal(typeof MC.config.ai.policyByP[0], "string");
  assert.ok(MC.config.ai.policyByP[0].length > 0);
  assert.equal(typeof MC.config.ai.policyByP[1], "string");
  assert.ok(MC.config.ai.policyByP[1].length > 0);
  requirePosNum(MC.config.ai, "biasExistingSetK");
  requirePosNum(MC.config.ai, "biasPayDebtFromBankK");
  requirePosNum(MC.config.ai, "biasEarlyBankBufferTarget");
  requirePosNum(MC.config.ai, "biasEarlyEmptyHandKeepActionsMaxHand");
  requirePosNum(MC.config.ai, "biasEarlyBankMoneyK");
  requirePosNum(MC.config.ai, "biasEarlyEndTurnOverBankActionsK");
  requirePosNum(MC.config.ai, "biasEarlyPlayRentIfPayableK");
  requirePosNum(MC.config.ai, "biasEarlyPlaceWhenHoldingRentK");
  requirePosNum(MC.config.ai, "biasPlayRentK");
  requirePosNum(MC.config.ai, "biasPlaySlyDealK");
  requirePosNum(MC.config.ai, "biasPlayJustSayNoK");
  requirePosNum(MC.config.ai, "biasMoveWildK");
});

test("config sanity: rule notes are configured", async () => {
  const ctx = await loadSrcFilesIntoVm(["00_prelude.js", "04_defs.js", "05_config.js"]);
  const { MC } = ctx;

  assert.equal(typeof MC.RuleNote, "object", "expected MC.RuleNote");
  assert.equal(typeof MC.config.rules, "object", "expected MC.config.rules");
  assert.ok(Array.isArray(MC.config.rules.enabledRuleNotes), "expected enabledRuleNotes array");
  assert.ok(MC.config.rules.enabledRuleNotes.length > 0, "expected enabledRuleNotes to be non-empty");
});

test("sanity: scenarios are registered after full load", async () => {
  const ctx = await loadSrcIntoVm();
  assert.ok(Array.isArray(ctx.MC.scenarios.IDS), "expected MC.scenarios.IDS to be an array");
  assert.ok(ctx.MC.scenarios.IDS.length > 0, "expected MC.scenarios.IDS to be non-empty");
});

