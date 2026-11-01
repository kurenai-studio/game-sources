// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Table tests for the HUD's card stacks: a waiting pick never hides the shop in the break (VG3 note 6).
import { describe, expect, it } from 'vitest';
import { LADDER_NAME, emptyLevels } from '../sim/colony';
import { MAX_ALIVE } from '../sim/curve';
import { emptyLines, type PerkId } from '../sim/economy';
import { POWERS, emptyStacks, type PowerId } from '../sim/growth';
import { statsSheet, type StatsInput } from '../sim/stats';
import {
  HP_BAR,
  NEST_BACK_H,
  NEST_PLAY_H,
  SHOP_CARD_W,
  STATS_PANEL_FILL,
  STATS_PANEL_W,
  STATS_TEXT_FLOOR,
  TOP_STRIP_H,
  bossBar,
  boxesOverlap,
  ladderLine,
  levelBar,
  lowHealth,
  muteButton,
  nectarReadout,
  nestLayout,
  overlaps,
  pickLayout,
  pickPlace,
  shopCell,
  shopLayout,
  statsCap,
  statsHit,
  statsLayout,
  statsPanelPlan,
  statsShown,
  titleLayout,
  wrapPhrases,
  type Band,
  type Box,
  type StatsFitLevel,
  type StatsMeasure,
} from './layout';

// Every phone sees 720 units across; the height runs from 1280 (a 16:9 screen) to 1800 (the tallest shape allowed).
const HEIGHTS = [1280, 1558, 1800];

describe('the pick sheet and the shop', () => {
  it.each([['break', 'high'], ['active', 'low'], ['intro', 'low'], ['title', 'low'], ['dead', 'low']])('in the %s phase the sheet sits %s', (phase, place) => {
    expect(pickPlace(phase)).toBe(place);
  });

  it.each(HEIGHTS)('at height %i the sheet in the break and the shop never overlap, both on screen', (H) => {
    const sheet = pickLayout('high', H).band;
    const shop = shopLayout(H).band;
    expect(overlaps(sheet, shop)).toBe(false);
    expect(sheet.bottom).toBeLessThan(shop.top);
    // Under the countdown (H x 0.2) and the nest line 50 below it, and inside the screen.
    expect(sheet.top).toBeGreaterThan(H * 0.2 + 64);
    expect(shop.bottom).toBeLessThanOrEqual(H);
  });

  it.each(HEIGHTS)('at height %i the sheet in a round sits low under the thumb, as slice 2 shipped', (H) => {
    expect(pickLayout('low', H).cardsTop).toBe(H - 388);
    expect(shopLayout(H).cardsTop).toBe(H - 376);
  });

  it.each(HEIGHTS)('at height %i the slice 4 grid keeps the perks in their cells and adds one row above them', (H) => {
    const L = shopLayout(H);
    expect(L.gridTop).toBe(H - 492);
    // The right column's rows 1 to 3 are the three perk cells of slices 1 to 3.
    for (let row = 1; row <= 3; row++) expect(shopCell(1, row, 720, H)).toEqual({ x: 368, y: L.cardsTop + (row - 1) * 116 });
    expect(shopCell(0, 0, 720, H)).toEqual({ x: 12, y: H - 492 });
    // The two columns never touch: 12 to 352 and 368 to 708.
    expect(shopCell(0, 0, 720, H).x + SHOP_CARD_W).toBeLessThan(shopCell(1, 0, 720, H).x);
    expect(L.band.top).toBeLessThan(L.titleY);
  });
});

describe('the nest screen between runs', () => {
  it.each(HEIGHTS)('at height %i the six cards end above PLAY, and Back sits under PLAY inside the screen', (H) => {
    const L = nestLayout(H);
    const cardsBottom = L.cardsTop + 6 * L.cardH + 5 * L.gap;
    expect(cardsBottom).toBeLessThanOrEqual(L.playY - NEST_PLAY_H / 2 - 20);
    expect(L.playY + NEST_PLAY_H / 2).toBeLessThan(L.backY - NEST_BACK_H / 2);
    expect(L.backY + NEST_BACK_H / 2).toBeLessThanOrEqual(H);
    expect(L.cardH).toBeGreaterThanOrEqual(100);
  });
});

describe('the low health vignette', () => {
  it.each([
    ['active', 180, 600, true], ['active', 181, 600, false], ['break', 90, 600, true], ['active', 600, 600, false],
    ['dead', 0, 600, false], ['active', 0, 600, false], ['title', 100, 600, false], ['intro', 100, 600, false],
  ])('in the %s phase at %i of %i health it shows: %s', (phase, hp, max, shows) => {
    expect(lowHealth(phase as string, hp as number, max as number)).toBe(shows);
  });
});

// Design note, 2026-10-30: the round line hides the remaining count, so the player cannot see when the round ends.
describe('the round line under the round number', () => {
  it.each([
    ['intro', 'PURE', 0, 0, 'PURE'],
    ['active', 'PURE', 0, 6, 'PURE'],
    ['active', 'COLONY', 9, 20, 'COLONY'],
    ['active', 'DAILY', 20, 40, 'DAILY'],
    ['active', 'PURE', 1, 1, 'PURE'],
    ['break', 'COLONY', 0, 0, 'COLONY   cleared'],
    ['break', 'DAILY', 0, 0, 'DAILY   cleared'],
    ['title', 'PURE', 0, 0, ''],
    ['dead', 'PURE', 3, 0, ''],
  ] as Array<[string, string, number, number, string]>)('in the %s phase with the tag %s, %i alive and %i left, the line reads "%s"', (phase, tag, alive, left, line) => {
    expect(ladderLine({ phase, alive, left }, tag)).toBe(line);
  });

  it.each([LADDER_NAME.colony, LADDER_NAME.pure, 'DAILY'])(`in a round the line is the tag %s alone, no digit after it, from 0 to ${MAX_ALIVE} alive and up to 99 left`, (tag) => {
    for (let alive = 0; alive <= MAX_ALIVE; alive++) {
      for (let left = alive; left <= 99; left++) {
        const line = ladderLine({ phase: 'active', alive, left }, tag);
        expect(line.startsWith(tag)).toBe(true);
        expect(line.slice(tag.length)).not.toMatch(/\d/);
      }
    }
  });
});

describe('the title (lane G7, M2)', () => {
  it.each(HEIGHTS.flatMap((H) => [[H, false], [H, true]] as Array<[number, boolean]>))(
    'at height %i (saved run: %s) the buttons stack under the best rounds, never touch, and stay above the New version line',
    (H, saved) => {
      const L = titleLayout(H, saved);
      expect(L.rows.map((r) => r.row)).toEqual(saved ? ['cont', 'play', 'daily', 'ladder', 'nest'] : ['play', 'daily', 'ladder', 'nest']);
      expect(L.nameY).toBeLessThan(L.tagY);
      expect(L.tagY).toBeLessThan(L.artY);
      expect(L.artY).toBeLessThan(L.bestY);
      expect(L.rows[0].y - L.rows[0].h / 2).toBeGreaterThan(L.bestY + 40);
      for (let i = 0; i + 1 < L.rows.length; i++) {
        const a = L.rows[i];
        const b = L.rows[i + 1];
        // The small line under a button (about 22 tall) ends before the next button starts.
        expect(a.subY + 14).toBeLessThan(b.y - b.h / 2);
      }
      const last = L.rows[L.rows.length - 1];
      // The New version line sits 52 above the bottom, 64 tall.
      expect(last.subY + 14).toBeLessThan(H - 52 - 32);
      // Every button stays a thumb sized target: 80 units is 43 points across a 390 point phone.
      for (const r of L.rows) expect(r.h).toBeGreaterThanOrEqual(80);
    },
  );

  it('pins the 390 by 844 phone (1558 tall): Play, the Daily challenge, the ladder and the nest without a save', () => {
    const L = titleLayout(1558, false);
    expect(L.rows.map((r) => [r.row, r.y, r.h])).toEqual([
      ['play', 650, 116],
      ['daily', 861, 104],
      ['ladder', 1071, 96],
      ['nest', 1281, 88],
    ]);
  });
});

// Lane N1, M2 (design note, 2026-10-29): the stats tab at the top left. 44 points on a 390 point phone are
// 44 x 720 / 390 = 81.2 units, the least a tap target may be.
const W = 720;
const TAP_UNITS = (44 * W) / 390;
const across = (b: Band): Box => ({ x: 0, y: b.top, w: W, h: b.bottom - b.top });

describe('the stats tab (lane N1, M2)', () => {
  it.each(HEIGHTS)('at height %i the button and the open panel stay clear of the health bar, the level bar, the sound switch, the nectar and the boss bar', (H) => {
    const L = statsLayout(H);
    for (const b of [HP_BAR, levelBar(W), muteButton(W), nectarReadout(W), bossBar(W)]) {
      expect(boxesOverlap(L.button, b)).toBe(false);
      expect(boxesOverlap(L.panel, b)).toBe(false);
    }
    // Under the top strip, on the left, the panel no wider than 70 percent of the screen, all inside the screen.
    expect(L.button.y).toBeGreaterThanOrEqual(TOP_STRIP_H);
    expect(L.panel.y).toBeGreaterThan(L.button.y + L.button.h);
    expect(L.button.x).toBeLessThan(W / 4);
    expect(L.panel.x).toBeGreaterThanOrEqual(0);
    expect(L.panel.x + L.panel.w).toBeLessThanOrEqual(0.7 * W);
    expect(L.panel.y + L.panel.h).toBeLessThanOrEqual(H);
  });

  it.each(HEIGHTS)('at height %i the panel never covers a round\'s pick cards or the shop\'s, and the button no cards at all', (H) => {
    const L = statsLayout(H);
    const low = across(pickLayout('low', H).band);
    const high = across(pickLayout('high', H).band);
    const shop = across(shopLayout(H).band);
    expect(boxesOverlap(L.panel, low)).toBe(false);
    expect(boxesOverlap(L.panel, shop)).toBe(false);
    for (const b of [low, high, shop]) expect(boxesOverlap(L.button, b)).toBe(false);
    // In the break a pick's cards sit high, where the panel would lie over them, so the panel steps aside while they are up.
    expect(boxesOverlap(L.panel, high)).toBe(true);
    expect(statsShown(true, 'break', true).panel).toBe(false);
  });

  it.each(HEIGHTS)('at height %i the button and the close x are thumb sized, and the panel starts under the countdown and the nest line', (H) => {
    const L = statsLayout(H);
    for (const b of [L.button, L.close]) {
      expect(b.w).toBeGreaterThanOrEqual(TAP_UNITS);
      expect(b.h).toBeGreaterThanOrEqual(TAP_UNITS);
    }
    // The close x sits inside the panel, in its top right corner.
    expect(L.close.x + L.close.w).toBe(L.panel.x + L.panel.w);
    expect(L.close.y).toBe(L.panel.y);
    // NEXT ROUND IN sits at H x 0.2 (42 tall type), "Walk to the nest to shop" 50 under it (28 tall type).
    expect(L.panel.y).toBeGreaterThan(H * 0.2 + 50 + 17);
    // Room for the title row and the six stat rows on the smallest screen (346 units at 1280).
    expect(L.panel.h).toBeGreaterThanOrEqual(340);
  });

  it('pins the 390 by 844 screen (1558 tall): the button at 12, 294 (88 square), the panel 360 by 454 from 12, 390', () => {
    const L = statsLayout(1558);
    expect(L.button).toEqual({ x: 12, y: 294, w: 88, h: 88 });
    expect(L.panel).toEqual({ x: 12, y: 390, w: STATS_PANEL_W, h: 454 });
    expect(L.close).toEqual({ x: 284, y: 390, w: 88, h: 88 });
  });

  // [phase, open, a pick's cards up, the button shows, the panel shows]
  it.each([
    ['title', true, false, false, false],
    ['dead', true, false, false, false],
    ['intro', true, false, true, true],
    ['active', false, false, true, false],
    ['active', true, false, true, true],
    ['active', true, true, true, true],
    ['break', true, false, true, true],
    ['break', true, true, true, false],
    ['break', false, true, true, false],
  ] as const)('in the %s phase, open %s, cards up %s: the button %s, the panel %s', (phase, open, cards, button, panel) => {
    expect(statsShown(open, phase, cards)).toEqual({ button, panel });
    // A round's cards sit low and a break's sit high (layout.ts pickPlace), which is why the two differ.
    if (cards && open && (phase === 'active' || phase === 'break')) expect(pickPlace(phase)).toBe(phase === 'break' ? 'high' : 'low');
  });

  it('a press on the button or the open panel belongs to the tab; anywhere else it is the stick\'s', () => {
    const L = statsLayout(1558);
    const open = { button: true, panel: true };
    const shut = { button: true, panel: false };
    const drawn = 300;
    const mid = (b: Box) => [b.x + b.w / 2, b.y + b.h / 2] as const;
    expect(statsHit(...mid(L.button), L, drawn, open)).toBe('button');
    expect(statsHit(...mid(L.button), L, drawn, shut)).toBe('button');
    expect(statsHit(...mid(L.close), L, drawn, open)).toBe('close');
    expect(statsHit(L.panel.x + 100, L.panel.y + 200, L, drawn, open)).toBe('panel');
    // Below the drawn panel, inside its largest box: the stick's.
    expect(L.panel.h).toBeGreaterThan(drawn + 10);
    expect(statsHit(L.panel.x + 100, L.panel.y + drawn + 10, L, drawn, open)).toBeNull();
    // The panel shut: the same point is the stick's, and so is the close x's.
    expect(statsHit(L.panel.x + 100, L.panel.y + 200, L, drawn, shut)).toBeNull();
    expect(statsHit(...mid(L.close), L, drawn, shut)).toBeNull();
    // On the title or the death screen nothing of the tab answers.
    expect(statsHit(...mid(L.button), L, drawn, { button: false, panel: false })).toBeNull();
    // The thumb's usual place, low on the left, and the screen's middle are always the stick's.
    expect(statsHit(180, 1215, L, drawn, open)).toBeNull();
    expect(statsHit(W / 2 + 200, 700, L, drawn, open)).toBeNull();
  });
});

// Design note, 2026-10-30: the tab is small and see through, half the width and half filled, never over the ant, and its
// text never under 0.8 of its size. The three screens: 375 by 667 (1281 units tall), a 390 point phone's home screen app
// inside its safe areas (390 by 763, 1409) and the full 390 by 844 (1558). The width estimate below (0.6 of the type size
// a character) runs wider than the bold face the game measures, so a plan that fits here fits on the phone.
const SCREENS = [1281, 1409, 1558];
const estimate: StatsMeasure = (text, size) => text.length * size * 0.6;
const maxStacks = Object.fromEntries(POWERS.map((p) => [p.id, p.max ?? 5])) as Record<PowerId, number>;
/** Every upgrade at its cap on a Colony run, at 1 health (Fury's note on): the longest sheet a run can make. */
const BIGGEST: StatsInput = {
  ladder: 'colony',
  colony: { stinger: 30, diet: 30, plates: 15, legs: 10, venom: 20, sweet: 20 },
  owned: ['chitin', 'chitin', 'chitin', 'twin', 'quick'] as PerkId[],
  lines: { damage: 20, rate: 12, health: 20, speed: 8, darts: 2 },
  stacks: maxStacks,
  hp: 1,
};
/** A mid run sheet (eight powers, a perk, three line buys, two colony steps), as the verifier's probe built it. */
const MID: StatsInput = {
  ladder: 'colony',
  colony: { ...emptyLevels(), stinger: 2, diet: 1 },
  owned: ['twin'] as PerkId[],
  lines: { ...emptyLines(), damage: 2, rate: 1 },
  stacks: { ...emptyStacks(), jaw: 2, glands: 1, eye: 1, shell: 1, fang: 1, fury: 1, stance: 1, fork: 1 },
  hp: 400,
};
const ORDER: StatsFitLevel[] = ['full', 'no notes', 'collapsed', 'cut'];

describe('the stats panel is small, see through and clear of the ant (lane N1, design note of 2026-10-30)', () => {
  it.each(SCREENS)('at height %i: 360 wide, half filled, its box ending at or above round(0.58 x H) less 60', (H) => {
    const L = statsLayout(H);
    expect(L.panel.w).toBe(360);
    expect(STATS_PANEL_FILL).toBe(0.5);
    expect(statsCap(H)).toBe(Math.round(0.58 * H) - 60);
    expect(L.panel.y + L.panel.h).toBeLessThanOrEqual(statsCap(H));
    // The ant sits at 0.58 H; its disc reaches 16 above that and its health bar 42.
    expect(L.panel.y + L.panel.h).toBeLessThan(Math.round(0.58 * H) - 42);
  });

  it('pins the caps: 683 at 1281 units, 757 at 1409, 844 at 1558', () => {
    expect(SCREENS.map((H) => statsCap(H))).toEqual([683, 757, 844]);
    expect(SCREENS.map((H) => statsLayout(H).panel.h)).toEqual([347, 397, 454]);
  });

  it.each(SCREENS)('at height %i the biggest sheet stays in the box with its text at 0.8 or more, the rest in "+N more"', (H) => {
    const L = statsLayout(H);
    const plan = statsPanelPlan(statsSheet(BIGGEST).rows, L.panel, estimate);
    expect(plan.scale).toBeGreaterThanOrEqual(STATS_TEXT_FLOOR);
    expect(L.panel.y + plan.drawnH).toBeLessThanOrEqual(statsCap(H));
    expect(['collapsed', 'cut']).toContain(plan.level);
    expect(plan.hidden).toBeGreaterThan(0);
    const last = plan.lines[plan.lines.length - 1];
    expect(last).toMatchObject({ kind: 'more', text: `+${plan.hidden} more` });
    // Every line inside the panel's width, by the same estimate.
    for (const l of plan.lines) expect(l.x + estimate(l.text, l.size)).toBeLessThanOrEqual(L.panel.w - 16 + 1e-9);
  });

  // [height, the deepest the mid run sheet may fold]
  it.each([
    [1281, 'cut'],
    [1409, 'collapsed'],
    [1558, 'collapsed'],
  ] as const)('at height %i a mid run sheet keeps its text at 0.8 or more and folds no deeper than "%s"', (H, deepest) => {
    const plan = statsPanelPlan(statsSheet(MID).rows, statsLayout(H).panel, estimate);
    expect(plan.scale).toBeGreaterThanOrEqual(STATS_TEXT_FLOOR);
    expect(ORDER.indexOf(plan.level)).toBeLessThanOrEqual(ORDER.indexOf(deepest));
    expect(statsLayout(H).panel.y + plan.drawnH).toBeLessThanOrEqual(statsCap(H));
  });

  it('as the room shrinks the panel first shrinks to 0.8, then drops the notes, then folds the list to counts, then cuts', () => {
    const rows = statsSheet(MID).rows;
    const seen: Array<{ h: number; level: StatsFitLevel; scale: number }> = [];
    for (let h = 900; h >= 330; h -= 5) {
      const plan = statsPanelPlan(rows, { x: 12, y: 0, w: 360, h }, estimate);
      seen.push({ h, level: plan.level, scale: plan.scale });
      expect(plan.scale).toBeGreaterThanOrEqual(STATS_TEXT_FLOOR);
      expect(plan.drawnH).toBeLessThanOrEqual(h);
      const notes = plan.lines.filter((l) => l.kind === 'note').length;
      const heads = plan.lines.filter((l) => l.kind === 'head').length;
      const items = plan.lines.filter((l) => l.kind === 'item').length;
      if (plan.level === 'full') expect(notes).toBeGreaterThan(0);
      if (plan.level !== 'full') expect(notes).toBe(0);
      // Folded, a kind is one line of counts and the headings go: four kinds at most, four lines at most.
      if (plan.level === 'collapsed' || plan.level === 'cut') {
        expect(heads).toBe(0);
        expect(items).toBeLessThanOrEqual(4);
      } else expect(heads).toBe(4);
      if (plan.level === 'cut') expect(plan.lines[plan.lines.length - 1].kind).toBe('more');
    }
    // The levels come in order and never go back as the room shrinks; each of the four shows up.
    const idx = seen.map((s) => ORDER.indexOf(s.level));
    for (let i = 1; i < idx.length; i++) expect(idx[i]).toBeGreaterThanOrEqual(idx[i - 1]);
    expect(new Set(seen.map((s) => s.level))).toEqual(new Set(ORDER));
    // Before any line is dropped the text shrinks: the full list is shown below scale 1 at some room.
    expect(seen.some((s) => s.level === 'full' && s.scale < 1), JSON.stringify(seen.filter((s, i) => i === 0 || s.level !== seen[i - 1].level))).toBe(true);
    // The folded list reads "Name xN": two Strong Jaws are "Strong Jaw x2".
    const folded = statsPanelPlan(rows, { x: 12, y: 0, w: 360, h: seen.find((s) => s.level === 'collapsed')!.h }, estimate);
    expect(folded.lines.some((l) => l.kind === 'item' && l.text.startsWith('Strong Jaw x2, ')), JSON.stringify(folded.lines.filter((l) => l.kind === 'item'))).toBe(true);
  });

  it.each([
    ['150 a dart, 150 a shot', 216],
    ['1,234.5 a dart, 9,876.5 a shot', 216],
    ['115.5 a dart, 231 a shot', 120],
    ['150 a dart, 150 a shot', 60],
  ] as const)('the damage value "%s" in %i units breaks between its two phrases, never inside "a dart" or "a shot"', (text, width) => {
    const lines = wrapPhrases(text, 22, width, estimate);
    expect(lines.join(' ')).toBe(text);
    for (const l of lines) {
      expect(l).not.toMatch(/(^| )a$/);
      expect(l).not.toMatch(/^(dart|shot)/);
    }
    expect(lines.some((l) => l.includes('a dart'))).toBe(true);
    expect(lines.some((l) => l.includes('a shot'))).toBe(true);
  });

  it('the damage row of the biggest sheet keeps "a dart" and "a shot" whole on the phone', () => {
    const plan = statsPanelPlan(statsSheet(BIGGEST).rows, statsLayout(1558).panel, estimate);
    const values = plan.lines.filter((l) => l.kind === 'value');
    const damage = values.filter((l) => / a (dart|shot)/.test(l.text) || /^a (dart|shot)/.test(l.text));
    expect(damage.length).toBeGreaterThanOrEqual(1);
    for (const l of values) {
      expect(l.text).not.toMatch(/(^| )a$/);
      expect(l.text).not.toMatch(/^(dart|shot)/);
    }
  });
});
