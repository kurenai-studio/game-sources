import { expect, test, type Page } from '@playwright/test';
import { boot, collectErrors, metrics } from './helpers';

/**
 * The shell, measured on the glass.
 *
 * Criterion 1 asks for a screen-friendly palette and an interface stripped to the
 * end, and until this file existed neither half of that was a number. The suite
 * knew whether a control was *reachable* - `shell.spec.ts` proves every door still
 * opens - and knew nothing at all about whether the writing on it can be read or
 * the target under it can be hit. Those are the two ways a stripped-back interface
 * goes wrong, and they are the two things nothing here could see.
 *
 * Both are measured rather than computed, and that distinction cost the first
 * attempt. Reading `getComputedStyle(el).color` and the ancestor's
 * `background-color` gives an answer for every element on the screen and the
 * answer is wrong for most of them: this shell paints on radial gradients, a
 * `backdrop-filter: blur(8px)` card, three blurred shafts of light and a wordmark
 * whose ink is a `background-clip: text` gradient with `color: transparent` on it -
 * so half the elements report a background of `rgba(0,0,0,0)` inherited from a
 * parent that never painted, and the wordmark reports no ink at all. What is
 * measured instead is the panel: two screenshots of the same screen, one with the
 * text painted and one with it not, and the difference between them is the ink.
 *
 * The ratio is WCAG's, because that is the number Apple and Google both check
 * against and criterion 6 is about being checked. 4.5:1 for body text, 3:1 for
 * large - and the point of the exercise is not the badge. It is that a tier of
 * type nobody can read is not a quiet tier, it is a tier that should have been
 * deleted; every number below 4.5 in here is either something to lift or something
 * to remove, and this file's job is to say which of the two it is.
 */

/** WCAG AA, small text. Everything in this shell is small text but the wordmark. */
const AA_SMALL = 4.5;
/** ...and large: 24px, or 18.66px at 700. */
const AA_LARGE = 3;

/**
 * The reach a finger needs, in CSS pixels: the gate, and the one above it.
 *
 * Apple asks 44pt and Google asks 48dp. The gate is the smaller because that is
 * what the shell is built to, and §6.9's comment for it got the logic backwards -
 * it called 44 "the one that has to be cleared on both platforms", which is true
 * of necessary and false of sufficient. `REACH_PX_MDC` is the number that would
 * actually clear both, and it is reported rather than gated: §7.3 measured what
 * moving `--reach` to it costs and the answer was a layout change on the circuit
 * screen, which is not a decision this file gets to take. See `docs/EDITORIAL.md`.
 *
 * Both are printed every run. A census whose only output is "nothing was under
 * the line" cannot tell a shell with margin from one sitting exactly on the line,
 * and sitting exactly on it is what this one turned out to be doing: all
 * sixty-five live controls measure 44 on their short side, because all sixty-five
 * come off one stylesheet variable.
 */
const REACH_PX = 44;
/** Material's minimum touch target. Reported, not gated. */
const REACH_PX_MDC = 48;

interface Ink {
  screen: string;
  /** The class that decides how this reads, which is the thing to go and change. */
  label: string;
  text: string;
  fontPx: number;
  weight: number;
  /** What the stylesheet says it is painted in, so a tier can be counted. */
  declared: string;
  /** WCAG large-text: the threshold is 3:1 rather than 4.5:1. */
  large: boolean;
  /**
   * Below the fold. The map is taller than a phone and scrolls, by design, so
   * some of it is genuinely not on the glass when the screenshot is taken - and
   * a rectangle off the panel has no pixels to measure. Counted, never gated.
   */
  offscreen: boolean;
  /**
   * An act nobody has reached, or a control that is switched off.
   *
   * These are the one kind of text that is *supposed* to be under the threshold:
   * the map draws what is ahead of you as an absence, and WCAG exempts a disabled
   * control for the same reason. They are measured and printed like everything
   * else and they are not gated - but they are printed, because "deliberately
   * faint" and "forgotten" look identical from inside a stylesheet.
   */
  unlit: boolean;
  /**
   * Behind the pinned primary.
   *
   * The third kind of run with no readable measurement, after the two above, and
   * the newest: the map's BEGIN is held at the bottom of the scrollport and is
   * opaque there, so a row passing under it is painted in the button's fill in
   * both passes and reads 1:1. Exempt for the same reason `offscreen` is - there
   * are no pixels of that run on the screen to measure - and printed for the
   * same reason `unlit` is, because "under the button" and "invisible" look
   * identical from inside a stylesheet.
   */
  covered: boolean;
  ratio: number;
  ink: string;
  bg: string;
}

interface Target {
  screen: string;
  label: string;
  w: number;
  h: number;
  /** A disabled control is not a target. WCAG exempts them and so does this. */
  off: boolean;
  /**
   * How much of its height is not under the pinned primary, with nothing
   * scrolled. Equal to `h` for every control on every screen but the map, and
   * on the map only for a column short enough that the button never pins.
   *
   * Printed rather than gated at a fraction, because the honest floor is zero:
   * a control the button sits on *entirely* is a control that has been deleted
   * from that screen at rest, and one it sits on partly is a row that comes out
   * from under it as the map moves.
   */
  exposed: number;
}

interface Census {
  screen: string;
  ink: Ink[];
  targets: Target[];
  /** How many separate pieces of writing the screen puts in front of the player. */
  runs: number;
  /** ...and how many sizes of type it says them in. A pile has more than a page. */
  sizes: number[];
}

/**
 * Everything that moves, stopped - in both passes, so the two frames differ by the
 * text and by nothing else.
 *
 * `animation: none` rather than `animation-play-state: paused`, because paused
 * freezes each animation wherever it happens to be and the two screenshots are
 * taken a few hundred milliseconds apart. None sends every animated property back
 * to its declared value, which the stylesheet was written to make a resting state
 * rather than a starting one - see `.ui-veil-shaft`'s own comment. It is also
 * exactly the screen a player with Reduce Motion on is looking at.
 */
const FREEZE = `*, *::before, *::after {
  animation: none !important;
  transition: none !important;
}`;

/**
 * The same screen with the writing taken off it.
 *
 * `color: transparent` covers ordinary text and `fill` covers the SVG on the map.
 * The wordmark needs the third rule and is the reason this is not a one-liner: its
 * ink is a linear gradient clipped to the glyphs, so it is not painted with `color`
 * at all and `color: transparent` is already what it says. Dropping the background
 * is what removes it - and the drop shadow with it, which is part of the same ink.
 */
const INK_OFF = `*, *::before, *::after {
  color: transparent !important;
  -webkit-text-fill-color: transparent !important;
  text-shadow: none !important;
}
svg text, svg tspan { fill: transparent !important; }
.ui-title { background: none !important; filter: none !important; }`;

interface Run {
  label: string;
  text: string;
  fontPx: number;
  weight: number;
  declared: string;
  unlit: boolean;
  /** Behind the one control in this shell that leaves the column. See `Ink.covered`. */
  covered: boolean;
  rect: { x: number; y: number; w: number; h: number };
}

/**
 * What is on the screen and where, one text run at a time.
 *
 * A run rather than an element, and the range is what makes the difference: an
 * element's own box is the wrong rectangle for this twice over.
 * `.ui-map-core-kicker` holds a text node *and* a `<span>` with different ink in
 * it, so its box would measure whichever of the two happens to be further from
 * the background; and a heading that wraps to two lines has a box with a wide
 * empty corner in it, which dilutes the background the second line is actually
 * read against. `Range` returns the line boxes of one text node and nothing else.
 */
async function collectRuns(page: Page): Promise<Run[]> {
  return page.evaluate(() => {
    const SURFACES = ['.ui', '.ui-corner', '.ui-mix'];
    const out: {
      label: string;
      text: string;
      fontPx: number;
      weight: number;
      declared: string;
      unlit: boolean;
      covered: boolean;
      rect: { x: number; y: number; w: number; h: number };
    }[] = [];
    // The map's own word for an act nobody has reached, and the DOM's word for a
    // control that is off. Both draw an absence on purpose; see `Ink.unlit`.
    const isUnlit = (el: Element): boolean =>
      el.matches('.locked, .locked *, [disabled], [disabled] *') ||
      el.closest('[disabled]') !== null;
    /*
     * The one box in this shell that is not in the column.
     *
     * The map's primary is `position: sticky` - see `index.html` and the fold
     * test at the bottom of this file - so on that screen there is a rectangle
     * the panel scrolls *under*, and a run beneath it is painted in the button's
     * own opaque fill in both passes. That reads as 1:1 and it is not a tier
     * nobody can read; it is a row that comes out from under the button as the
     * screen moves. Read from the computed style rather than the class, so this
     * exemption disappears by itself if the rule ever does.
     */
    const pin = document.querySelector('.ui:not(.hidden) .ui-btn.primary');
    const pinned =
      pin !== null && getComputedStyle(pin).position === 'sticky'
        ? pin.getBoundingClientRect()
        : null;
    const isCovered = (el: Element, r: { x: number; y: number; w: number; h: number }): boolean =>
      pinned !== null &&
      !pin!.contains(el) &&
      r.x < pinned.right &&
      r.x + r.w > pinned.left &&
      r.y < pinned.bottom &&
      r.y + r.h > pinned.top;
    const name = (el: Element): string => {
      const cls = el.getAttribute('class') ?? '';
      return cls === '' ? el.tagName.toLowerCase() : `.${cls.trim().split(/\s+/).join('.')}`;
    };
    const seen = new Set<Element>();
    for (const root of SURFACES.flatMap((s) => [...document.querySelectorAll(s)])) {
      // `.hidden` is `display: none` in this shell, and a surface that is off is
      // off for all of its children - the walk below only checks each element's
      // own computed style, which inherits nothing about display.
      if (getComputedStyle(root).display === 'none') continue;
      const walk = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT);
      for (let el: Node | null = root; el !== null; el = walk.nextNode()) {
        if (!(el instanceof Element) || seen.has(el)) continue;
        seen.add(el);
        const style = getComputedStyle(el);
        if (style.visibility === 'hidden' || style.display === 'none') continue;
        const fontPx = parseFloat(style.fontSize);
        const weight = Number(style.fontWeight) || 400;

        // SVG text has no useful ranges; its own box is already tight round the
        // glyphs, which is the thing a range is needed for elsewhere.
        if (el instanceof SVGTextElement) {
          const r = el.getBoundingClientRect();
          if (r.width < 2 || r.height < 2) continue;
          const rect = { x: r.x, y: r.y, w: r.width, h: r.height };
          out.push({
            label: name(el),
            text: (el.textContent ?? '').trim().slice(0, 24),
            fontPx,
            weight,
            declared: style.fill,
            unlit: isUnlit(el),
            covered: isCovered(el, rect),
            rect,
          });
          continue;
        }

        for (const node of [...el.childNodes]) {
          if (node.nodeType !== Node.TEXT_NODE) continue;
          const text = (node.textContent ?? '').trim();
          if (text === '') continue;
          const range = document.createRange();
          range.selectNodeContents(el);
          range.setStart(node, 0);
          range.setEnd(node, node.textContent!.length);
          // The widest line box: one number per run, and the line with the most
          // glyphs on it is the one the run is actually read on.
          let best: DOMRect | null = null;
          for (const r of range.getClientRects()) {
            if (r.width < 2 || r.height < 2) continue;
            if (best === null || r.width > best.width) best = r;
          }
          if (best === null) continue;
          const rect = { x: best.x, y: best.y, w: best.width, h: best.height };
          out.push({
            label: name(el),
            text: text.slice(0, 24),
            fontPx,
            weight,
            // What the tier *says* it is, which is what a stylesheet can be
            // counted in. `background-clip: text` reports `rgba(0, 0, 0, 0)`
            // here and is measured on the panel like everything else.
            declared: style.webkitTextFillColor === '' ? style.color : style.webkitTextFillColor,
            unlit: isUnlit(el),
            covered: isCovered(el, rect),
            rect,
          });
        }
      }
    }
    return out;
  });
}

/** Every control on the screen, and the rectangle a thumb has to find. */
async function collectTargets(
  page: Page,
): Promise<{ label: string; w: number; h: number; off: boolean; exposed: number }[]> {
  return page.evaluate(() => {
    const nodes = [
      ...document.querySelectorAll<HTMLElement>('.ui button, .ui input, .ui-corner, .ui-mix button, .ui-mix input'),
    ];
    // The pinned primary again - see `isCovered` in `collectRuns`. What it costs
    // on the target side is a row it sits partly on top of, and that is a number
    // rather than a judgement: how much of a control's height is still exposed
    // with nothing scrolled.
    const pin = document.querySelector('.ui:not(.hidden) .ui-btn.primary');
    const pinned =
      pin !== null && getComputedStyle(pin).position === 'sticky'
        ? pin.getBoundingClientRect()
        : null;
    return nodes
      .filter((el) => el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden')
      .map((el) => {
        const r = el.getBoundingClientRect();
        const cls = el.getAttribute('class') ?? el.tagName.toLowerCase();
        const under =
          pinned === null || pin!.contains(el) || el.contains(pin!)
            ? 0
            : Math.max(
                0,
                Math.min(r.bottom, pinned.bottom) - Math.max(r.top, pinned.top),
              ) * (r.right > pinned.left && r.left < pinned.right ? 1 : 0);
        return {
          label: `.${cls.trim().split(/\s+/).join('.')}`,
          w: Math.round(r.width * 10) / 10,
          h: Math.round(r.height * 10) / 10,
          off: el.hasAttribute('disabled'),
          exposed: Math.round((r.height - under) * 10) / 10,
        };
      });
  });
}

/**
 * The ink, from the panel.
 *
 * For each run: the mean of the background under it with the text off, and the one
 * pixel in that box that the text moved furthest with the text on. That pixel is
 * the middle of a stem - at three device pixels to the CSS pixel even nine-pixel
 * type has one - so it is the ink at full coverage rather than an antialiased edge,
 * and it is a pixel that was really on the screen rather than a colour composited
 * in arithmetic.
 *
 * Mean background rather than the background under that one pixel, deliberately.
 * A run set across a gradient is read against the whole gradient, and picking the
 * darkest pixel under a glyph would report the best moment of a line that is being
 * read as a line.
 */
async function measureInk(page: Page, screen: string, runs: Run[]): Promise<Ink[]> {
  const lit = (await page.screenshot()).toString('base64');
  await page.evaluate((css) => {
    const style = document.createElement('style');
    style.dataset.inkOff = '';
    style.textContent = css;
    document.head.append(style);
  }, INK_OFF);
  const dark = (await page.screenshot()).toString('base64');
  await page.evaluate(() => document.querySelector('style[data-ink-off]')?.remove());

  const measured = await page.evaluate(
    async ({ litB64, darkB64, boxes }) => {
      const load = async (b64: string): Promise<ImageData> => {
        const img = new Image();
        img.src = `data:image/png;base64,${b64}`;
        await img.decode();
        const cv = document.createElement('canvas');
        cv.width = img.naturalWidth;
        cv.height = img.naturalHeight;
        const ctx = cv.getContext('2d')!;
        ctx.drawImage(img, 0, 0);
        return ctx.getImageData(0, 0, cv.width, cv.height);
      };
      const a = await load(litB64);
      const b = await load(darkB64);
      const scale = a.width / window.innerWidth;

      // WCAG's relative luminance, and its ratio. sRGB, not the Rec.601 the frame
      // sweeps use: this is a readability threshold with a published definition,
      // and the definition is this one.
      const chan = (v: number): number => {
        const s = v / 255;
        return s <= 0.04045 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
      };
      const lum = (r: number, g: number, bl: number): number =>
        0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(bl);

      return boxes.map((box) => {
        // The panel, not the document: a box that scrolled off the bottom of the
        // map has no pixels in either screenshot, and clamping it to the edge
        // would measure the last row of the screen instead of saying so.
        const off =
          box.y + box.h <= 0 ||
          box.y >= window.innerHeight ||
          box.x + box.w <= 0 ||
          box.x >= window.innerWidth;
        if (off) return { ratio: 0, ink: '-', bg: '-', offscreen: true };
        const x0 = Math.max(0, Math.floor(box.x * scale));
        const y0 = Math.max(0, Math.floor(box.y * scale));
        const x1 = Math.min(a.width, Math.ceil((box.x + box.w) * scale));
        const y1 = Math.min(a.height, Math.ceil((box.y + box.h) * scale));
        let sr = 0;
        let sg = 0;
        let sb = 0;
        let n = 0;
        let best = -1;
        const ink = [0, 0, 0];
        for (let y = y0; y < y1; y++) {
          for (let x = x0; x < x1; x++) {
            const i = (y * a.width + x) * 4;
            const br = b.data[i]!;
            const bg = b.data[i + 1]!;
            const bb = b.data[i + 2]!;
            sr += br;
            sg += bg;
            sb += bb;
            n++;
            const d = Math.abs(lum(a.data[i]!, a.data[i + 1]!, a.data[i + 2]!) - lum(br, bg, bb));
            if (d > best) {
              best = d;
              ink[0] = a.data[i]!;
              ink[1] = a.data[i + 1]!;
              ink[2] = a.data[i + 2]!;
            }
          }
        }
        if (n === 0) return { ratio: 0, ink: '-', bg: '-', offscreen: true };
        const mean = [sr / n, sg / n, sb / n];
        const li = lum(ink[0]!, ink[1]!, ink[2]!);
        const lb = lum(mean[0]!, mean[1]!, mean[2]!);
        const ratio = (Math.max(li, lb) + 0.05) / (Math.min(li, lb) + 0.05);
        const hex = (c: number[]): string =>
          `#${c.map((v) => Math.round(v).toString(16).padStart(2, '0')).join('')}`;
        return {
          ratio: Math.round(ratio * 100) / 100,
          ink: hex(ink),
          bg: hex(mean),
          offscreen: false,
        };
      });
    },
    { litB64: lit, darkB64: dark, boxes: runs.map((r) => r.rect) },
  );

  return runs.map((run, i) => ({
    screen,
    label: run.label,
    text: run.text,
    fontPx: Math.round(run.fontPx * 10) / 10,
    weight: run.weight,
    declared: run.declared,
    large: run.fontPx >= 24 || (run.fontPx >= 18.66 && run.weight >= 700),
    offscreen: measured[i]!.offscreen,
    unlit: run.unlit,
    covered: run.covered,
    ratio: measured[i]!.ratio,
    ink: measured[i]!.ink,
    bg: measured[i]!.bg,
  }));
}

async function census(page: Page, screen: string): Promise<Census> {
  await page.addStyleTag({ content: FREEZE });
  const runs = await collectRuns(page);
  const ink = await measureInk(page, screen, runs);
  const targets = (await collectTargets(page)).map((t) => ({ screen, ...t }));
  const sizes = [...new Set(ink.map((r) => r.fontPx))].sort((a, b) => b - a);
  return { screen, ink, targets, runs: runs.length, sizes };
}

/** What a run has to clear, or `null` if it is one of the three exempt kinds. */
function needed(r: Ink): number | null {
  if (r.offscreen || r.unlit || r.covered) return null;
  return r.large ? AA_LARGE : AA_SMALL;
}

interface Report {
  ink: Ink[];
  targets: Target[];
  /** Every run that is on the glass, lit, and under its threshold. */
  failed: Ink[];
  /** Every live control smaller than a finger. */
  short: Target[];
  /** ...and every one the pinned primary has taken off the screen entirely. */
  buried: Target[];
  /** How many different inks the shell paints text in. This is the clutter. */
  tiers: string[];
  /** ...and how many sizes it sets type in, which is the same clutter measured
   * the other way: ten sizes between 8.5 and 18 on one screen is not a
   * hierarchy either, because half the steps are half a pixel. */
  sizes: number[];
}

function report(all: Census[]): Report {
  const ink = all.flatMap((c) => c.ink);
  const targets = all.flatMap((c) => c.targets);
  for (const c of all) {
    const lit = c.ink.filter((r) => needed(r) !== null);
    const worst = [...lit].sort((a, b) => a.ratio - b.ratio)[0];
    console.log(
      `[shell ${c.screen}] ${JSON.stringify({
        runs: c.runs,
        onGlass: lit.length,
        typeSizes: c.sizes.length,
        sizes: c.sizes,
        controls: c.targets.length,
        worstInk: worst === undefined ? null : `${worst.label} ${worst.ratio}:1`,
      })}`,
    );
  }
  const failed = ink
    .filter((r) => needed(r) !== null && r.ratio < needed(r)!)
    .sort((a, b) => a.ratio - b.ratio);
  const line = (tag: string, r: Ink): void =>
    console.log(
      `[shell ${tag}] ${JSON.stringify({
        screen: r.screen,
        label: r.label,
        text: r.text,
        px: r.fontPx,
        ratio: r.ratio,
        need: r.large ? AA_LARGE : AA_SMALL,
        ink: r.ink,
        bg: r.bg,
      })}`,
    );
  for (const r of failed) line('ink', r);
  // The absences, printed rather than gated: an act nobody has reached is drawn
  // faint on purpose, and this is where anybody who wants to argue with that
  // decision can see what it actually measures.
  const dim = [...new Map(ink.filter((r) => r.unlit && !r.offscreen).map((r) => [r.label, r])).values()];
  for (const r of dim.sort((a, b) => a.ratio - b.ratio)) line('unlit', r);
  // ...and the rows under the pinned button, for the same reason. There is one
  // screen in the shell that can produce these, and if that ever stops being
  // true this is where it will say so.
  for (const r of ink.filter((r) => r.covered && !r.offscreen)) line('covered', r);

  const short = targets
    .filter((t) => !t.off && (t.w < REACH_PX || t.h < REACH_PX))
    .sort((a, b) => Math.min(a.w, a.h) - Math.min(b.w, b.h));
  for (const t of [...new Map(short.map((t) => [t.label, t])).values()]) {
    console.log(`[shell reach] ${JSON.stringify({ label: t.label, w: t.w, h: t.h, seen: short.filter((s) => s.label === t.label).length })}`);
  }
  // The same census against the other store's number, and the smallest live
  // control in the shell whether or not anything failed.
  const live = targets.filter((t) => !t.off);
  // ...and what the pinned primary sits on. One line per control it touches.
  for (const t of live.filter((t) => t.exposed < t.h)) {
    console.log(
      `[shell under-pin] ${JSON.stringify({ screen: t.screen, label: t.label, h: t.h, exposed: t.exposed })}`,
    );
  }
  const shortMdc = live.filter((t) => t.w < REACH_PX_MDC || t.h < REACH_PX_MDC);
  const smallest = [...live].sort((a, b) => Math.min(a.w, a.h) - Math.min(b.w, b.h))[0];
  console.log(
    `[shell reach48] ${JSON.stringify({
      under: shortMdc.length,
      of: live.length,
      smallest: smallest === undefined ? null : `${smallest.label} ${smallest.w}x${smallest.h}`,
      need: REACH_PX_MDC,
    })}`,
  );
  const tiers = [...new Set(ink.filter((r) => !r.offscreen).map((r) => r.declared))].sort();
  const sizes = [...new Set(ink.filter((r) => !r.offscreen).map((r) => r.fontPx))].sort(
    (a, b) => b - a,
  );
  console.log(`[shell tiers] ${JSON.stringify({ count: tiers.length, tiers })}`);
  console.log(`[shell sizes] ${JSON.stringify({ count: sizes.length, sizes })}`);
  console.log(
    `[shell total] ${JSON.stringify({
      runs: ink.length,
      onGlass: ink.filter((r) => needed(r) !== null).length,
      offscreen: ink.filter((r) => r.offscreen).length,
      unlit: ink.filter((r) => r.unlit && !r.offscreen).length,
      covered: ink.filter((r) => r.covered && !r.offscreen).length,
      belowAA: failed.length,
      controls: targets.filter((t) => !t.off).length,
      belowReach: short.length,
      inkTiers: tiers.length,
      typeSizes: sizes.length,
    })}`,
  );
  return { ink, targets, failed, short, buried: live.filter((t) => t.exposed <= 0), tiers, sizes };
}

/**
 * Every screen the shell has, in one pass.
 *
 * One test rather than seven, because the product is the table: a threshold that
 * seven separate tests each check a seventh of tells nobody which screen is the
 * worst one, and the worst one is the whole question.
 */
test('every screen: what can be read, and what can be hit', async ({ page }) => {
  const errors = collectErrors(page);
  const all: Census[] = [];

  await page.goto('/?skipIntro');
  await expect(page.locator('button.ui-btn.primary')).toBeVisible();
  all.push(await census(page, 'title'));

  // ...and the same screen with a journey behind it, which is a different screen:
  // the record line, the mode notes and the two lines the journey card only has
  // once there is something to count exist nowhere on a fresh profile, and a
  // fresh profile is the only one anything here had ever been looked at on.
  await seedProfile(page);
  await page.goto('/?skipIntro&second=1');
  await expect(page.locator('.ui-stat-row')).toBeVisible();
  all.push(await census(page, 'title-record'));

  await page.locator('.ui-journey').click();
  await expect(page.locator('.ui-map')).toBeVisible();
  all.push(await census(page, 'circuit'));
  await page.locator('.ui-map-core-open').click();
  await expect(page.locator('.ui-stations')).toBeVisible();
  all.push(await census(page, 'circuit-stations'));

  await page.goto('/?skipIntro&seed=12345');
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  await page.locator('.ui-corner-mix').click();
  await expect(page.locator('.ui-mix')).toBeVisible();
  all.push(await census(page, 'mixer'));
  await page.locator('.ui-mix-close').click();

  await page.locator('.ui-corner-pause').click();
  await expect(page.locator('.ui-heading')).toBeVisible();
  all.push(await census(page, 'paused'));
  await page.getByRole('button', { name: /resume/i }).click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');

  await page.evaluate(() => window.__slowblue!.world.run.fail('depleted'));
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
  await expect(page.locator('.ui-score')).toBeVisible();
  all.push(await census(page, 'over'));

  /*
   * ...and the same screen over the brightest water in the game.
   *
   * Results and pause are the two screens that keep the picture behind them, on
   * purpose - so they are the two whose background this shell does not own. The
   * ink on them was chosen over act I, which is a trench, and act II's Anvil is
   * the top of a thunderhead: §6.8 measured the shoal itself flipping from L 0.24
   * to L 0.97 inside that one act. Quiet ink on a dark field and quiet ink on a
   * white one are not the same claim, and only one of them had ever been checked.
   */
  await page.goto('/?act=air&seed=12345');
  await page.locator('button.ui-btn.primary').first().click();
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
  await page.evaluate(() => {
    window.__slowblue!.jump('air', 5);
    for (let i = 0; i < 240; i++) window.__slowblue!.advance(1 / 60);
    window.__slowblue!.world.run.fail('depleted');
  });
  await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
  await expect(page.locator('.ui-score')).toBeVisible();
  all.push(await census(page, 'over-anvil'));

  const { ink, targets, failed, short, buried, tiers, sizes } = report(all);
  expect(errors).toEqual([]);
  // Enough of the shell was actually looked at for the totals to mean anything.
  // It was 150 when the walk still had the sound card and the comfort screen in
  // it; both were withdrawn, and the floor came down by the two screens' worth of
  // writing rather than by whatever the walk happens to read today.
  expect(ink.length).toBeGreaterThan(140);
  expect(targets.length).toBeGreaterThan(50);

  // The four budgets, and every one of them was a finding before it was a
  // budget: thirty-one runs on the glass under AA, thirty-five controls under a
  // finger, thirty-six inks and fifteen sizes of type.
  expect(failed).toEqual([]);
  expect(short).toEqual([]);
  // ...and the fifth, which is the price of the map's pinned button: a control
  // it overlaps is still a control, and one it covers completely is not.
  expect(buried).toEqual([]);
  expect(tiers.length).toBeLessThanOrEqual(8);
  expect(sizes.length).toBeLessThanOrEqual(12);
});

/**
 * The one part of the interface neither census above can see: the canvas under
 * the shell.
 *
 * Everything in this file measures the DOM against itself - what a rectangle is
 * painted in, how big it is, what is behind it in the same tree - and the game's
 * own readouts are not in that tree at all. They are drawn on a canvas that runs
 * the full height of the glass, *under* the two fixed buttons in the top right,
 * and the two layers lay themselves out from two different sets of numbers that
 * nothing has ever compared.
 *
 * They had disagreed for some time. The streak badge was placed to clear the
 * pause button, the mixer button was later put underneath the pause button, and
 * from then on `×1.00` was drawn straight through a speaker icon on every run
 * with a streak in it. It is in the shipped store screenshots. See
 * `HUD_COLUMN_TOP` in `render/Renderer.ts`.
 *
 * Rectangles rather than pixels, deliberately: both layers are right-aligned to
 * the same edge, so once the column starts below the lowest button the two
 * cannot intersect whatever either of them paints, and an assertion that says
 * that cannot fail for a reason about colour, motion or a frame's timing.
 */
test('the readouts on the glass start below the buttons over them', async ({ page }) => {
  const errors = collectErrors(page);
  await boot(page);
  // A streak the badge will actually draw, and no calm mode, which hides it.
  await page.evaluate(() => {
    window.__slowblue!.world.run.streak = 4;
    window.__slowblue!.world.run.recomputeScore(window.__slowblue!.world.shoalCount);
    window.__slowblue!.advance(0.2);
  });

  const chrome = await page.evaluate(() => {
    const rect = (sel: string): { label: string; top: number; bottom: number } | null => {
      const el = document.querySelector(sel);
      if (el === null) return null;
      const r = el.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) return null;
      return { label: sel, top: r.top, bottom: r.bottom };
    };
    return ['.ui-corner:not(.ui-corner-mix)', '.ui-corner-mix']
      .map(rect)
      .filter((r): r is { label: string; top: number; bottom: number } => r !== null);
  });
  const column = (await metrics(page)).hudColumnTop as number;
  const lowest = Math.max(...chrome.map((c) => c.bottom));
  console.log(
    `[shell column] ${JSON.stringify({ column, lowest, buttons: chrome, clearance: column - lowest })}`,
  );

  // Both buttons are up during a run, and if they are not, this test proves
  // nothing about the corner it is named for.
  expect(chrome.length).toBe(2);
  expect(column).toBeGreaterThanOrEqual(lowest);
  expect(errors).toEqual([]);
});

/**
 * The same corner, on a window that got short while the run was live.
 *
 * The test above cannot find this one and no threshold would help: it runs on a
 * phone-shaped viewport, and on anything that tall the rail starts two hundred
 * pixels below the buttons whatever it does. The rail is placed at a *fraction*
 * of the height while the two buttons are a fixed stack under the top inset, so
 * the collision only exists at the short end - the counter crosses the mixer
 * button's bottom edge below 480 CSS pixels of height. No iPhone screen is that
 * short and the phone is locked to portrait anyway; an iPad window is resizable,
 * which is what the port put on the table.
 *
 * Resized mid-run rather than booted small, because that is the case the picture
 * has to survive on an iPad - the window changes size while the ocean is being
 * flown - and because it also proves the resize actually reaches the renderer.
 *
 * With a streak running, because the corner has three things in it and the badge
 * is the one that only exists sometimes. The first floor written for this cleared
 * the two buttons and put the counter on exactly the badge's line - a collision
 * with `×1.00` bought with a collision with a speaker - and a test that booted a
 * fresh run would have called that fixed.
 */
test('the progress rail clears the same buttons on a short window', async ({ page }) => {
  const errors = collectErrors(page);
  await boot(page);
  await page.setViewportSize({ width: 1024, height: 400 });
  await page.evaluate(() => {
    // Settled rather than popping: the badge is at its 12 px height for all but
    // the first 0.45 s, and the floor is written for the 16 px it starts at.
    window.__slowblue!.world.run.streak = 4;
    window.__slowblue!.world.run.sinceStreakChange = 2;
    window.__slowblue!.world.run.recomputeScore(window.__slowblue!.world.shoalCount);
    window.__slowblue!.advance(0.2);
  });

  const read = await page.evaluate(() => {
    const rect = (sel: string): number => document.querySelector(sel)!.getBoundingClientRect().bottom;
    const m = window.__slowblue!.metrics();
    return {
      counter: m.railCounterTop as number,
      lowest: Math.max(rect('.ui-corner:not(.ui-corner-mix)'), rect('.ui-corner-mix')),
      column: m.hudColumnTop as number,
      badge: m.streakBadgeBottom as number,
      height: window.innerHeight,
    };
  });
  console.log(`[rail on a short window] ${JSON.stringify(read)}`);

  // The window really is short, or this test is measuring the same trivial pass
  // the one above already gets.
  expect(read.height).toBeLessThan(480);
  // The badge is on the glass, or the row it owns is not being checked at all.
  expect(read.badge).toBeGreaterThan(read.column);
  expect(read.counter).toBeGreaterThanOrEqual(read.lowest);
  expect(read.counter).toBeGreaterThanOrEqual(read.badge);
  expect(errors).toEqual([]);
});

/**
 * A profile with a journey in it, which is most of the shell's writing.
 *
 * The same shape `shell.spec.ts` writes, for the same reason: the title screen's
 * record line, its two mode notes and the map's lit half only exist for somebody
 * who has played, and a suite that only ever boots a fresh profile has never seen
 * any of them.
 */
async function seedProfile(page: Page): Promise<void> {
  await page.evaluate(() => {
    localStorage.setItem(
      'tide.profile',
      JSON.stringify({
        version: 3,
        bestScore: 1200,
        bestDepth: 0,
        bestGates: 0,
        bestShoal: 0,
        deepestZone: 0,
        bestLevel: 0,
        completions: 1,
        runs: 23,
        totalRescued: 0,
        totalReforms: 0,
        totalSeconds: 0,
        seenHints: [],
        unlockedAct: 2,
        saved: null,
        bestCampaign: 900,
        bestCargo: 12,
        cycles: 1,
        stations: { water: 6, air: 3, thin: 0, orbit: 0, reentry: 0, rain: 0, home: 0 },
      }),
    );
    localStorage.setItem(
      'tide.settings',
      JSON.stringify({ ...JSON.parse(localStorage.getItem('tide.settings') ?? '{}'), calm: true }),
    );
  });
}

/**
 * The button the screen is for, on the glass when the screen opens.
 *
 * `offscreen` above is counted and never gated, and the comment on it says why:
 * the map is taller than a phone and scrolls, by design, so a rectangle below
 * the fold is a property of that screen rather than a defect in it. That is true
 * of a station list and it is false of the one control the screen exists to
 * offer, and nothing here could tell the two apart - so the census could report
 * a shell in which every door opens, every label reads and every target takes a
 * finger, while the door itself was half an inch below the bottom of the phone.
 *
 * It was. BEGIN on the map ended 23.7px past the fold at rest, and the reason it
 * took until now to be a number is the second thing this test does differently:
 * *it measures more than one glass*. The suite runs at 390x844, which is the
 * mildest case in the family. The same button at rest, before the sticky rule in
 * `index.html` that answers this:
 *
 *   - 390x844, first-time profile: on the glass, 23.3px to spare.
 *   - 390x844, once a circuit has been closed and the second toggle appears: 23.7 past.
 *   - 375x667, *first-time* profile: 76.4 past.
 *   - 375x667, circuit closed: 123.4 past.
 *   - 844x390: 400.2 past.
 *
 * One phone and one profile said "half a button". Four phones and two profiles
 * said the primary action of this screen is off the bottom of every phone
 * shorter than the one being tested on, for everybody, from the first launch.
 *
 * The gate is the whole family, and it holds every screen to it rather than the
 * map alone, because "the thing to press is where the player can see it" is not
 * a claim about the screen that happened to break it.
 */
const GLASSES = [
  /** The suite's own phone, and the one every other number in this file is from. */
  { name: '390x844', width: 390, height: 844 },
  /** iPhone SE, and the shortest glass anyone is still shipping to. */
  { name: '375x667', width: 375, height: 667 },
  /** ...and the tallest, where nothing has ever been tight. */
  { name: '430x932', width: 430, height: 932 },
  /** Turned over: 390 of height for a screen whose picture asks for 400. */
  { name: '844x390', width: 844, height: 390 },
] as const;

interface Reach {
  glass: string;
  screen: string;
  label: string;
  top: number;
  bottom: number;
  vh: number;
  /** How far past the bottom of the glass it ends. Negative is clearance. */
  past: number;
  /** Where the scrollport was when this was read. Zero is the screen as it opens. */
  scrolled: number;
}

/**
 * Where the primary is, and where the column was when it was read.
 *
 * Both, because a screen measured after something scrolled it is a different
 * claim: `scrolled` is gated by name below rather than assumed to be zero.
 */
async function primaryAtRest(page: Page, glass: string, screen: string): Promise<Reach | null> {
  const out = await page.evaluate(() => {
    const el = document.querySelector('.ui:not(.hidden) .ui-btn.primary');
    if (el === null) return null;
    const scroller = document.querySelector('.ui:not(.hidden)') as HTMLElement;
    const r = el.getBoundingClientRect();
    return {
      label: (el.textContent ?? '').trim().split('\n')[0]!.slice(0, 18),
      top: Math.round(r.top * 10) / 10,
      bottom: Math.round(r.bottom * 10) / 10,
      vh: window.innerHeight,
      scrolled: scroller.scrollTop,
    };
  });
  if (out === null) return null;
  const reach: Reach = {
    scrolled: out.scrolled,
    glass,
    screen,
    label: out.label,
    top: out.top,
    bottom: out.bottom,
    vh: out.vh,
    past: Math.round((out.bottom - out.vh) * 10) / 10,
  };
  console.log(`[shell fold] ${JSON.stringify(reach)}`);
  return reach;
}

test('the primary action is on the glass when the screen opens', async ({ page }) => {
  const errors = collectErrors(page);
  const seen: Reach[] = [];
  const take = async (glass: string, screen: string): Promise<void> => {
    const r = await primaryAtRest(page, glass, screen);
    if (r !== null) seen.push(r);
  };

  for (const glass of GLASSES) {
    await page.setViewportSize({ width: glass.width, height: glass.height });

    // A first launch, which is the only state most players are ever in once.
    await page.goto('/?skipIntro');
    await expect(page.locator('button.ui-btn.primary')).toBeVisible();
    await take(glass.name, 'title');
    await page.locator('.ui-journey').click();
    await expect(page.locator('.ui-map')).toBeVisible();
    await take(glass.name, 'circuit-fresh');

    // ...and a profile with a closed circuit behind it, which is the taller map:
    // the record line, the second mode toggle and the erase button only exist
    // for somebody who has been round once.
    await seedProfile(page);
    await page.goto('/?skipIntro&second=1');
    await expect(page.locator('.ui-stat-row')).toBeVisible();
    await take(glass.name, 'title-record');
    await page.locator('.ui-journey').click();
    await expect(page.locator('.ui-map')).toBeVisible();
    await take(glass.name, 'circuit');
    await page.locator('.ui-map-core-open').click();
    await expect(page.locator('.ui-stations')).toBeVisible();
    await take(glass.name, 'circuit-stations');

    // The three that arrive mid-run. They keep the water behind them, so they
    // are the three whose height nothing here controls.
    await page.goto('/?skipIntro&seed=12345');
    await page.locator('button.ui-btn.primary').first().click();
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
    await page.locator('.ui-corner-pause').click();
    await expect(page.locator('.ui-heading')).toBeVisible();
    await take(glass.name, 'paused');
    await page.getByRole('button', { name: /resume/i }).click();
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'playing');
    await page.evaluate(() => window.__slowblue!.world.run.fail('depleted'));
    await page.waitForFunction(() => window.__slowblue!.metrics().mode === 'over');
    await expect(page.locator('.ui-score')).toBeVisible();
    await take(glass.name, 'over');
  }

  // Half a pixel of slack, for the reason `safearea.spec.ts` allows it: a
  // fractional layout on a 3x display is not an offence.
  const past = seen.filter((r) => r.past > 0.5);
  const tightest = [...seen].sort((a, b) => b.past - a.past)[0]!;
  console.log(
    `[shell fold total] ${JSON.stringify({
      measured: seen.length,
      past: past.length,
      tightest: `${tightest.glass} ${tightest.screen} ${-tightest.past} to spare`,
    })}`,
  );
  expect(errors).toEqual([]);
  // Enough of the shell was actually opened for the sweep to mean anything:
  // seven screens on four glasses, less the one that has no primary. It was
  // eight before the comfort screen was withdrawn.
  expect(seen.length).toBeGreaterThanOrEqual(28);
  expect(past).toEqual([]);
  // Every screen was read at the top of its own column but one. In landscape the
  // station disclosure is itself below the fold, so the tap that opens it is a
  // tap the driver has to scroll to reach - and the primary reads 322..370 on
  // that glass either side of the scroll, which is the rule this is measuring.
  expect(seen.filter((r) => r.scrolled !== 0).map((r) => `${r.glass} ${r.screen}`)).toEqual([
    '844x390 circuit-stations',
  ]);
});

/**
 * ...and the two things being pinned there has to not cost.
 *
 * A control held at the bottom of a scrollport is a control that has left the
 * column, so it owes the two answers the column used to give for it: that it is
 * still out of the home indicator's way, and that it is not sitting on whatever
 * was under it. The second one is why the rule is `position: sticky` rather than
 * `fixed` - there are 150px of column below BEGIN, so scrolling to the end puts
 * its resting place above the pin line and it lets go on its own.
 */
test('the pinned primary clears the cutout and lets go at the end of the column', async ({
  page,
}) => {
  const errors = collectErrors(page);
  await page.goto('/?skipIntro');
  await seedProfile(page);
  await page.goto('/?skipIntro&second=1');
  await expect(page.locator('.ui-journey')).toBeVisible();

  // The three bottom insets `safearea.spec.ts` wears: none, an iPhone's home
  // indicator, and an Android navigation bar.
  for (const inset of [0, 34, 48]) {
    await page.evaluate((v) => {
      document.documentElement.style.setProperty('--safe-b', `${v}px`);
    }, inset);
    await page.locator('.ui-journey').click();
    await expect(page.locator('.ui-map')).toBeVisible();
    const seat = await page.evaluate(() => {
      const r = document
        .querySelector('.ui:not(.hidden) .ui-btn.primary')!
        .getBoundingClientRect();
      return { bottom: Math.round(r.bottom * 10) / 10, vh: window.innerHeight };
    });
    const clearance = Math.round((seat.vh - inset - seat.bottom) * 10) / 10;
    console.log(`[shell pinned] ${JSON.stringify({ inset, bottom: seat.bottom, clearance })}`);
    // The shell's own gutter, and no more: an offset that repeated the inset
    // arithmetic the scrollport has already done would seat it two gutters up.
    expect(clearance).toBeCloseTo(20, 1);
    await page.getByRole('button', { name: /^back$/i }).last().click();
    await expect(page.locator('.ui-journey')).toBeVisible();
  }

  await page.evaluate(() => {
    document.documentElement.style.setProperty('--safe-b', '0px');
  });
  await page.locator('.ui-journey').click();
  await expect(page.locator('.ui-map')).toBeVisible();
  await page.evaluate(() => {
    const ui = document.querySelector('.ui:not(.hidden)') as HTMLElement;
    ui.scrollTop = ui.scrollHeight;
  });
  const ends = await page.evaluate(() => {
    const box = (s: string): { top: number; bottom: number } => {
      const r = document.querySelector(`.ui:not(.hidden) ${s}`)!.getBoundingClientRect();
      return { top: Math.round(r.top * 10) / 10, bottom: Math.round(r.bottom * 10) / 10 };
    };
    return {
      primary: box('.ui-btn.primary'),
      danger: box('.ui-btn.danger'),
      ghost: box('.ui-btn.ghost'),
      vh: window.innerHeight,
    };
  });
  console.log(`[shell released] ${JSON.stringify(ends)}`);
  // Let go: the two controls below it are whole, on the glass, and under it.
  expect(ends.primary.bottom).toBeLessThanOrEqual(ends.danger.top);
  expect(ends.danger.bottom).toBeLessThanOrEqual(ends.ghost.top);
  expect(ends.ghost.bottom).toBeLessThanOrEqual(ends.vh + 0.5);
  expect(errors).toEqual([]);
});
