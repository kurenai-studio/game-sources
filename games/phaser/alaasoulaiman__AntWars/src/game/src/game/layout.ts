// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Where the HUD's two card stacks sit, as plain numbers in HUD units (720 wide, H tall). The shop's three cards sit low
// on the right. The pick sheet sits low under the thumb during a round and, in the break, high under the countdown,
// so a waiting pick never hides the shop (VG3 note 6).
import { GROUP_TITLES, rowText, type StatRow } from '../sim/stats';
import { CAMERA_LEAD_Y } from './tuning';

export const SHOP_CARD_H = 104;
export const SHOP_GAP = 12;
export const SHOP_BOTTOM = 28;
export const PICK_CARD_H = 112;
export const PICK_GAP = 12;
export const PICK_BOTTOM = 28;

export interface Band {
  top: number;
  bottom: number;
}

/** Slice 4: the shop is two columns of four rows (the repeatable lines on the left, the extra dart over the perks on the right). */
export const SHOP_ROWS = 4;
export const SHOP_CARD_W = 340;

/**
 * The shop's cards: cardsTop is the first perk's top, where slices 1 to 3 put it (the perks keep their cells), gridTop the
 * top row of the grid, titleY the shop title's centre, and the band the title and the cards cover.
 */
export function shopLayout(H: number): { cardsTop: number; gridTop: number; titleY: number; band: Band } {
  const cardsTop = H - 3 * (SHOP_CARD_H + SHOP_GAP) - SHOP_BOTTOM;
  const gridTop = H - SHOP_ROWS * (SHOP_CARD_H + SHOP_GAP) - SHOP_BOTTOM;
  return { cardsTop, gridTop, titleY: gridTop - 22, band: { top: gridTop - 38, bottom: cardsTop + 3 * SHOP_CARD_H + 2 * SHOP_GAP } };
}

/** The top left corner of the shop cell in column col (0 left, 1 right) and row row (0 top), on a screen W wide. */
export function shopCell(col: number, row: number, W: number, H: number): { x: number; y: number } {
  const x = col === 0 ? 12 : W - SHOP_CARD_W - 12;
  return { x, y: shopLayout(H).gridTop + row * (SHOP_CARD_H + SHOP_GAP) };
}

export type SheetPlace = 'low' | 'high';

/** In the break the sheet goes high so the shop below it stays in reach; in a round (no shop then) it sits low. */
export function pickPlace(phase: string): SheetPlace {
  return phase === 'break' ? 'high' : 'low';
}

/** The sheet's title centre, its first card top and the band it covers. High sits under the countdown and nest line. */
export function pickLayout(place: SheetPlace, H: number): { titleY: number; cardsTop: number; band: Band } {
  const height = 3 * PICK_CARD_H + 2 * PICK_GAP;
  const cardsTop = place === 'low' ? H - PICK_BOTTOM - height : Math.round(H * 0.2) + 132;
  const titleY = cardsTop - 32;
  return { titleY, cardsTop, band: { top: titleY - 18, bottom: cardsTop + height } };
}

export function overlaps(a: Band, b: Band): boolean {
  return a.top < b.bottom && b.top < a.bottom;
}

/** The nest screen between runs: six upgrade cards under the header, PLAY and Back below them, fitted to the height. */
export const NEST_CARDS_TOP = 300;
export const NEST_GAP = 10;
export const NEST_PLAY_H = 110;
export const NEST_BACK_H = 76;
export function nestLayout(H: number): { cardsTop: number; cardH: number; gap: number; playY: number; backY: number } {
  const playY = H - 210;
  const backY = H - 84;
  const room = playY - NEST_PLAY_H / 2 - 20 - NEST_CARDS_TOP;
  const cardH = Math.max(72, Math.min(124, Math.floor((room - 5 * NEST_GAP) / 6)));
  return { cardsTop: NEST_CARDS_TOP, cardH, gap: NEST_GAP, playY, backY };
}

/** The low health vignette shows in a run (the round or the break) once health is down to this share or less. */
export const LOW_HEALTH_SHARE = 0.3;
export function lowHealth(phase: string, hp: number, maxHp: number): boolean {
  return (phase === 'active' || phase === 'break') && hp > 0 && maxHp > 0 && hp / maxHp <= LOW_HEALTH_SHARE;
}

/**
 * The line under the round number: the run's tag (the ladder's name, or DAILY on a Daily run) in the intro and in a
 * round, the tag and cleared in the break, and nothing on the title or the death screen. It is handed the snapshot with
 * the round's two counts, so a table test can prove they never reach the screen.
 * Design note, 2026-10-30: the round line hides the remaining count, so the player cannot see when the round ends. The
 * snapshot still carries alive and left for the smoke harness.
 */
export function ladderLine(s: { phase: string; alive: number; left: number }, tag: string): string {
  return s.phase === 'active' || s.phase === 'intro' ? tag : s.phase === 'break' ? `${tag}   cleared` : '';
}

/** Lane N1: a box in HUD units, its top left corner and its size. */
export interface Box {
  x: number;
  y: number;
  w: number;
  h: number;
}

export function boxesOverlap(a: Box, b: Box): boolean {
  return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
}

export function inBox(x: number, y: number, b: Box): boolean {
  return x >= b.x && x < b.x + b.w && y >= b.y && y < b.y + b.h;
}

/** The top strip and its readouts, and the boss bar under it, where HudScene draws them (lane N1: the stats tab keeps clear). */
export const TOP_STRIP_H = 152;
export const HP_BAR: Box = { x: 22, y: 112, w: 324, h: 28 };
export function levelBar(W: number): Box {
  return { x: W - 346, y: 112, w: 324, h: 28 };
}
/** The sound switch: a 64 unit square icon, its middle 20 right of the screen's middle and 44 down. */
export function muteButton(W: number): Box {
  return { x: W / 2 + 20 - 32, y: 12, w: 64, h: 64 };
}
/** The nectar count (right aligned 58 in from the edge, 44 tall type) and its bead, with room for 9,999,999 drops. */
export function nectarReadout(W: number): Box {
  return { x: W - 330, y: 14, w: 318, h: 60 };
}
export const BOSS_BAR_Y = 202;
export const BOSS_BAR_H = 30;
export function bossBar(W: number): Box {
  return { x: 24, y: BOSS_BAR_Y, w: W - 48, h: BOSS_BAR_H };
}

/**
 * Lane N1, M2: the stats tab. The button sits on the left under the top strip and the boss bar, 88 units square (48
 * points on a 390 point phone, over a 44 point tap target). The panel opens under it, half the screen wide, from under
 * the break's countdown and nest line (H x 0.2, the line 50 below it) down to above the shop's grid, the pick sheet's
 * low place and the ant, so it never covers the shop's cards, a round's level up cards, or the ant and its health bar.
 * The close x is a tap target as big as the button, in the panel's top right corner.
 * Design note, 2026-10-30: the tab is small and see through. At two thirds of the width, 70 percent fill and no floor on
 * its text it covered the ant in ordinary play and its notes shrank to about 5 points on the smallest phone; it is now
 * half the width, half filled, ends above the ant, and keeps its text at 0.8 or more by showing less (statsPanelPlan).
 */
export const STATS_BTN = 88;
export const STATS_PANEL_W = 360;
/** How opaque the panel's dark fill is: the Yard shows through the other half. */
export const STATS_PANEL_FILL = 0.5;
/**
 * The camera keeps the ant this share of the screen down (tuning.ts CAMERA_LEAD_Y below the middle), and the panel ends
 * this many units above that point: the ant's health bar tops out 42 units above its middle (GameScene drawAnt).
 */
export const STATS_ANT_Y = 0.5 + CAMERA_LEAD_Y;
export const STATS_ANT_CLEARANCE = 60;
const STATS_X = 12;
const STATS_GAP = 8;
export interface StatsPlace {
  button: Box;
  /** The panel's largest box; the HUD draws it as tall as its rows need, never taller. */
  panel: Box;
  close: Box;
}

export function statsLayout(H: number): StatsPlace {
  const panelTop = Math.max(BOSS_BAR_Y + BOSS_BAR_H + STATS_GAP + STATS_BTN + STATS_GAP, Math.round(H * 0.2) + 78);
  const bottom = Math.min(shopLayout(H).band.top - 12, pickLayout('low', H).band.top - 12, statsCap(H));
  const panel: Box = { x: STATS_X, y: panelTop, w: STATS_PANEL_W, h: bottom - panelTop };
  return {
    button: { x: STATS_X, y: panelTop - STATS_GAP - STATS_BTN, w: STATS_BTN, h: STATS_BTN },
    panel,
    close: { x: panel.x + panel.w - STATS_BTN, y: panel.y, w: STATS_BTN, h: STATS_BTN },
  };
}

/** The lowest the panel may reach on a screen H units tall: round(0.58 x H) less 60, clear of the ant and its health bar. */
export function statsCap(H: number): number {
  return Math.round(STATS_ANT_Y * H) - STATS_ANT_CLEARANCE;
}

/**
 * Lane N1: the tab shows only in a run (never on the title or the death screen); the panel when it is open, except
 * while the cards of a pick sit high in the break, where it would cover them (it comes back after the tap).
 */
export function statsShown(open: boolean, phase: string, sheetUp: boolean): { button: boolean; panel: boolean } {
  const run = phase === 'intro' || phase === 'active' || phase === 'break';
  return { button: run, panel: run && open && !(sheetUp && pickPlace(phase) === 'high') };
}

export type StatsHit = 'button' | 'close' | 'panel' | null;

/**
 * Lane N1: what a press at (x, y) lands on: the button, the close x, the rest of the open panel, or nothing of the tab.
 * panelH is the panel's drawn height. The HUD gives any of the three to the tab alone: the stick never takes it.
 */
export function statsHit(x: number, y: number, place: StatsPlace, panelH: number, shown: { button: boolean; panel: boolean }): StatsHit {
  if (shown.button && inBox(x, y, place.button)) return 'button';
  if (!shown.panel || !inBox(x, y, { ...place.panel, h: Math.min(place.panel.h, panelH) })) return null;
  return inBox(x, y, place.close) ? 'close' : 'panel';
}

/**
 * Lane N1: the stats panel's body as plain lines in HUD units at scale 1, ready to draw. The title row (YOUR ANT and the
 * close x) sits above it, STATS_HEAD_H tall; each stat row is a label on the left and its value and note beside it;
 * the upgrades follow under their headings.
 */
export type StatsLineKind = 'label' | 'value' | 'note' | 'head' | 'item' | 'more' | 'empty';
export interface StatsLine {
  kind: StatsLineKind;
  text: string;
  x: number;
  y: number;
  size: number;
}
/** How much the body shows: everything, the notes dropped, one line of counts per kind, then kinds cut to "+N more". */
export type StatsFitLevel = 'full' | 'no notes' | 'collapsed' | 'cut';
export interface StatsPanelPlan {
  level: StatsFitLevel;
  /** The body's scale: 1 when it fits, never under STATS_TEXT_FLOOR while the six stat rows alone fit at it. */
  scale: number;
  /** The body's height at scale 1, and the whole panel's drawn height (title row, body at its scale, bottom pad). */
  height: number;
  drawnH: number;
  /** Upgrades the list leaves out (the "+N more" line). */
  hidden: number;
  lines: StatsLine[];
}
/** The width of a text at a type size in HUD units: the HUD measures its own text, a test passes an estimate. */
export type StatsMeasure = (text: string, size: number) => number;

export const STATS_TEXT_FLOOR = 0.8;
export const STATS_HEAD_H = 64;
export const STATS_PAD = 16;
export const STATS_BOTTOM_PAD = 10;
/** The label column: "Fire rate" fits it at 16; "Damage taken" takes two lines. */
export const STATS_LABEL_W = 100;
export const STATS_SIZE: Readonly<Record<StatsLineKind, number>> = { label: 16, value: 20, note: 15, head: 16, item: 18, more: 16, empty: 16 };
/** A line's height as a share of its type size (the bold face with its 3 unit stroke). */
export const STATS_LEADING = 1.25;
export const STATS_EMPTY_TEXT = 'No upgrades yet: level ups and the nest shop add them here';
const STATS_ROW_GAP = 6;
const STATS_GROUP_GAP = 6;

const statsLineH = (kind: StatsLineKind): number => Math.round(STATS_SIZE[kind] * STATS_LEADING);

/**
 * Breaks text into lines no wider than width: between its comma phrases first ("150 a dart, 150 a shot" breaks after
 * the comma), between words only inside a phrase wider than the line, and never between "a" and the word after it, so
 * "a dart" and "a shot" stay whole on one line.
 */
export function wrapPhrases(text: string, size: number, width: number, measure: StatsMeasure): string[] {
  const lines: string[] = [];
  let cur = '';
  const place = (piece: string): void => {
    const cand = cur ? `${cur} ${piece}` : piece;
    if (!cur || measure(cand, size) <= width) cur = cand;
    else {
      lines.push(cur);
      cur = piece;
    }
  };
  const parts = text.split(', ');
  parts.forEach((p, i) => {
    const phrase = i < parts.length - 1 ? `${p},` : p;
    if (measure(phrase, size) <= width) {
      place(phrase);
      return;
    }
    const words: string[] = [];
    for (const w of phrase.split(' ')) {
      if (words.length > 0 && words[words.length - 1] === 'a') words[words.length - 1] = `a ${w}`;
      else words.push(w);
    }
    for (const w of words) place(w);
  });
  if (cur) lines.push(cur);
  return lines.length > 0 ? lines : [''];
}

/** The body at one level; keep is how many kinds a cut list keeps (the rest go to "+N more"). */
function statsBody(rows: readonly StatRow[], width: number, measure: StatsMeasure, level: StatsFitLevel, keep: number): { height: number; hidden: number; lines: StatsLine[] } {
  const lines: StatsLine[] = [];
  const valueX = STATS_PAD + STATS_LABEL_W;
  const valueW = width - valueX - STATS_PAD;
  const innerW = width - 2 * STATS_PAD;
  const add = (kind: StatsLineKind, text: string, x: number, y: number): void => {
    lines.push({ kind, text, x, y, size: STATS_SIZE[kind] });
  };
  let y = 0;
  for (const r of rows) {
    if (r.group !== 'stat') continue;
    const labels = wrapPhrases(r.label, STATS_SIZE.label, STATS_LABEL_W - 8, measure);
    const values = wrapPhrases(r.value, STATS_SIZE.value, valueW, measure);
    const notes = level === 'full' && r.note !== '' ? wrapPhrases(r.note, STATS_SIZE.note, valueW, measure) : [];
    labels.forEach((t, i) => add('label', t, STATS_PAD, y + 3 + i * statsLineH('label')));
    values.forEach((t, i) => add('value', t, valueX, y + i * statsLineH('value')));
    const valuesH = values.length * statsLineH('value');
    notes.forEach((t, i) => add('note', t, valueX, y + valuesH + i * statsLineH('note')));
    y += Math.max(3 + labels.length * statsLineH('label'), valuesH + notes.length * statsLineH('note')) + STATS_ROW_GAP;
  }
  const groups = GROUP_TITLES.map(([group, title]) => ({ title, rows: rows.filter((r) => r.group === group) })).filter((g) => g.rows.length > 0);
  let hidden = 0;
  if (groups.length === 0) {
    for (const t of wrapPhrases(STATS_EMPTY_TEXT, STATS_SIZE.empty, innerW, measure)) {
      add('empty', t, STATS_PAD, y);
      y += statsLineH('empty');
    }
  } else if (level === 'full' || level === 'no notes') {
    for (const g of groups) {
      add('head', g.title, STATS_PAD, y);
      y += statsLineH('head');
      for (const t of wrapPhrases(g.rows.map((r) => rowText(r)).join(', '), STATS_SIZE.item, innerW, measure)) {
        add('item', t, STATS_PAD, y);
        y += statsLineH('item');
      }
      y += STATS_GROUP_GAP;
    }
  } else {
    // One line a kind, in the order of the headings and the full width without them: "Strong Jaw x2, Fork Darts x1"
    // while they fit; the rest are counted.
    groups.forEach((g, i) => {
      if (i >= keep) {
        hidden += g.rows.length;
        return;
      }
      let text = '';
      let shown = 0;
      for (const r of g.rows) {
        const cand = text ? `${text}, ${r.label} x${r.count ?? 1}` : `${r.label} x${r.count ?? 1}`;
        if (measure(cand, STATS_SIZE.item) > innerW) break;
        text = cand;
        shown += 1;
      }
      hidden += g.rows.length - shown;
      if (shown > 0) {
        add('item', text, STATS_PAD, y);
        y += statsLineH('item');
      }
    });
    if (hidden > 0) {
      add('more', `+${hidden} more`, STATS_PAD, y);
      y += statsLineH('more');
    }
  }
  return { height: y, hidden, lines };
}

/**
 * Lane N1: how the stats panel shows the run in its box. The body may shrink to STATS_TEXT_FLOOR; past that it shows
 * less, in this order: the notes go, then the upgrades fold to one line of counts per kind, then whole kinds from the
 * end go into a final "+N more" line. The panel's drawn height never passes its box, so it never reaches the ant.
 */
export function statsPanelPlan(rows: readonly StatRow[], panel: Box, measure: StatsMeasure): StatsPanelPlan {
  const room = panel.h - STATS_HEAD_H - STATS_BOTTOM_PAD;
  const done = (level: StatsFitLevel, body: { height: number; hidden: number; lines: StatsLine[] }, scale: number): StatsPanelPlan => ({
    level,
    scale,
    height: body.height,
    drawnH: Math.min(panel.h, Math.ceil(STATS_HEAD_H + body.height * scale + STATS_BOTTOM_PAD - 1e-6)),
    hidden: body.hidden,
    lines: body.lines,
  });
  const scaleFor = (h: number) => Math.min(1, room / Math.max(1, h));
  const kinds = GROUP_TITLES.filter(([group]) => rows.some((r) => r.group === group)).length;
  for (const level of ['full', 'no notes', 'collapsed'] as const) {
    const body = statsBody(rows, panel.w, measure, level, kinds);
    if (scaleFor(body.height) >= STATS_TEXT_FLOOR) return done(level, body, scaleFor(body.height));
  }
  for (let keep = kinds - 1; keep > 0; keep--) {
    const body = statsBody(rows, panel.w, measure, 'cut', keep);
    if (scaleFor(body.height) >= STATS_TEXT_FLOOR) return done('cut', body, scaleFor(body.height));
  }
  // Every kind cut: if the stat rows are still too tall at the floor the box wins over the floor (no screen of 1280 to
  // 1800 units comes to that, layout.test.ts).
  const last = statsBody(rows, panel.w, measure, 'cut', 0);
  return done('cut', last, scaleFor(last.height));
}

/** Lane G7, M2 and M3: the title's buttons, top to bottom. Continue shows only with a saved run. */
export type TitleRow = 'cont' | 'play' | 'daily' | 'ladder' | 'nest';
export interface TitleRowPlace {
  row: TitleRow;
  /** The button's middle, its height and the middle of the small line under it. */
  y: number;
  h: number;
  subY: number;
}

/**
 * The title: the name, a short line under it, the ant and two predators (the art), the best rounds, then the buttons
 * spread down the screen between 35 and 89 percent of the height, each with its small line under it (M3: the Daily
 * challenge under Play). The How to play button sits in the top strip beside the sound switch, and the New version
 * line stays below the last button.
 */
export function titleLayout(H: number, saved: boolean): { nameY: number; tagY: number; artY: number; bestY: number; rows: TitleRowPlace[] } {
  const nameY = Math.round(H * 0.115);
  const tagY = nameY + 74;
  const artY = Math.round(H * 0.232);
  const bestY = Math.round(H * 0.3);
  const order: TitleRow[] = saved ? ['cont', 'play', 'daily', 'ladder', 'nest'] : ['play', 'daily', 'ladder', 'nest'];
  const top = H * 0.35;
  const step = (H * 0.89 - top) / order.length;
  const tall: Record<TitleRow, number> = { cont: 110, play: 116, daily: 104, ladder: 96, nest: 88 };
  const rows = order.map((row, i) => {
    const y = Math.round(top + step * (i + 0.5));
    const h = Math.min(tall[row], Math.round(step - 48));
    return { row, y, h, subY: y + Math.round(h / 2) + 22 };
  });
  return { nameY, tagY, artY, bestY, rows };
}
