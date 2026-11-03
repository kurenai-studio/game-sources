/**
 * A canvas that records instead of painting.
 *
 * `tests/fish.test.ts` proved the idea on one function: a stub context is the only way
 * to assert the *shape* of something the renderer draws without looking at a
 * screenshot. This is the same trick grown up enough for the whole render layer - it
 * carries every method the drawing code touches, keeps the numbers that went through
 * it, and remembers which compositing modes were used.
 *
 * The single most valuable thing it catches is a non-finite coordinate. A `NaN` in a
 * path is invisible in a screenshot - Canvas2D silently drops the subpath - so a
 * geometry bug in a rarely-seen sequence (an ending, say) can ship looking like
 * "nothing happened". `expectFinite` turns that into a failing test.
 */

interface Point {
  x: number;
  y: number;
}

export class FakeContext {
  /** Every coordinate that passed through a path or a rect, in order. */
  numbers: number[] = [];
  /** Path points only: enough to reconstruct an outline. */
  points: Point[] = [];
  /**
   * Circles and ellipses, which is how every ring in the game is drawn.
   *
   * `ccw` is kept because it is the difference between a disc and an annulus,
   * and that difference has already been one invisible bug: a radial gradient
   * clamps to its first stop inside its inner radius, so an atmosphere drawn as
   * a filled circle rather than as a ring paints the whole planet the colour of
   * its own innermost stop.
   */
  arcs: { x: number; y: number; r: number; ccw: boolean }[] = [];
  subpaths = 0;
  fills = 0;
  strokes = 0;
  clips = 0;
  gradients = 0;
  /** Which composite modes were set at least once. */
  composites = new Set<string>();
  /** Every colour string assigned to fillStyle or strokeStyle. */
  styles: string[] = [];
  /** Index into `points` of the first arc/ellipse, i.e. where outlines stop. */
  firstArc = -1;
  /** Every angle passed to `rotate`, in order. See the method. */
  rotations: number[] = [];
  /**
   * Filled rectangles, radial gradients and scale factors, each in its own list.
   *
   * All three are in `numbers` as well, and reading them out of there is exactly
   * what a test should not have to do. They are kept apart because one question
   * needs them side by side: **does a fill stop while the gradient inside it is
   * still lit?** That is the defect the campaign has now shipped three times - the
   * anvil's light band, the canopy's shafts, the sunlit zone's - and it is a
   * relation between a rect, a gradient and the transform they were drawn under,
   * so a test can only ask it if all three survive the recording.
   */
  rects: { x: number; y: number; w: number; h: number }[] = [];
  radials: { x0: number; y0: number; r0: number; x1: number; y1: number; r1: number }[] = [];
  scales: { x: number; y: number }[] = [];
  /** Every gradient's stops, in creation order, so an alpha can be attributed. */
  gradientStops: { offset: number; colour: string }[][] = [];

  fillStyle: string | object = '';
  strokeStyle: string | object = '';
  lineWidth = 1;
  lineCap = 'butt';
  lineJoin = 'miter';
  globalAlpha = 1;
  lineDashOffset = 0;
  font = '';
  textAlign = 'left';
  textBaseline = 'alphabetic';

  private mode = 'source-over';

  get globalCompositeOperation(): string {
    return this.mode;
  }

  set globalCompositeOperation(value: string) {
    this.mode = value;
    this.composites.add(value);
  }

  private num(...values: number[]): void {
    for (const v of values) this.numbers.push(v);
  }

  private style(): void {
    for (const s of [this.fillStyle, this.strokeStyle]) {
      if (typeof s === 'string' && s !== '') this.styles.push(s);
    }
  }

  save(): void {}
  restore(): void {}
  beginPath(): void {}
  closePath(): void {}
  setLineDash(): void {}

  moveTo(x: number, y: number): void {
    this.num(x, y);
    this.points.push({ x, y });
    this.subpaths++;
  }

  lineTo(x: number, y: number): void {
    this.num(x, y);
    this.points.push({ x, y });
  }

  quadraticCurveTo(cx: number, cy: number, x: number, y: number): void {
    this.num(cx, cy, x, y);
    this.points.push({ x, y });
  }

  bezierCurveTo(c1x: number, c1y: number, c2x: number, c2y: number, x: number, y: number): void {
    this.num(c1x, c1y, c2x, c2y, x, y);
    this.points.push({ x, y });
  }

  arc(x: number, y: number, r: number, from: number, to: number, ccw = false): void {
    if (this.firstArc < 0) this.firstArc = this.points.length;
    this.num(x, y, r, from, to);
    this.arcs.push({ x, y, r, ccw });
  }

  ellipse(x: number, y: number, rx: number, ry: number, rot: number): void {
    if (this.firstArc < 0) this.firstArc = this.points.length;
    this.num(x, y, rx, ry, rot);
    this.arcs.push({ x, y, r: rx, ccw: false });
  }

  rect(x: number, y: number, w: number, h: number): void {
    this.num(x, y, w, h);
  }

  fillRect(x: number, y: number, w: number, h: number): void {
    this.num(x, y, w, h);
    this.rects.push({ x, y, w, h });
    this.style();
    this.fills++;
  }

  strokeRect(x: number, y: number, w: number, h: number): void {
    this.num(x, y, w, h);
    this.style();
    this.strokes++;
  }

  fill(): void {
    this.style();
    this.fills++;
  }

  stroke(): void {
    this.style();
    this.strokes++;
  }

  clip(): void {
    this.clips++;
  }

  translate(x: number, y: number): void {
    this.num(x, y);
  }

  /**
   * Kept separately from `numbers`, because exactly one thing in the game rotates
   * the frame - `render/Overview.ts`, once, at the campaign's turn - and whether
   * it did, by how much, and whether reduced motion switched it off are the three
   * facts that film is asserted on.
   */
  rotate(angle: number): void {
    this.num(angle);
    this.rotations.push(angle);
  }

  scale(x: number, y: number): void {
    this.num(x, y);
    this.scales.push({ x, y });
  }

  transform(a: number, b: number, c: number, d: number, e: number, f: number): void {
    this.num(a, b, c, d, e, f);
  }

  setTransform(a: number, b: number, c: number, d: number, e: number, f: number): void {
    this.num(a, b, c, d, e, f);
  }

  /**
   * Text, and the string as well as the coordinates.
   *
   * The banner is the only text in the game drawn on the canvas, and what it
   * *says* is half of what it has to get right - which act it is closing, in
   * which words - so the strings are kept alongside the numbers.
   */
  texts: {
    text: string;
    x: number;
    y: number;
    style: string;
    font: string;
    /** Only meaningful on a stroked entry: how wide the rim round the glyph is. */
    width: number;
    stroked: boolean;
  }[] = [];

  private wrote(text: string, x: number, y: number, style: string, stroked: boolean): void {
    this.num(x, y);
    this.style();
    this.texts.push({ text, x, y, style, font: this.font, width: this.lineWidth, stroked });
  }

  fillText(text: string, x: number, y: number): void {
    this.wrote(text, x, y, String(this.fillStyle), false);
    this.fills++;
  }

  strokeText(text: string, x: number, y: number): void {
    this.wrote(text, x, y, String(this.strokeStyle), true);
    this.strokes++;
  }

  createLinearGradient(x0: number, y0: number, x1: number, y1: number): CanvasGradient {
    this.num(x0, y0, x1, y1);
    this.gradients++;
    return stops(this);
  }

  createRadialGradient(
    x0: number,
    y0: number,
    r0: number,
    x1: number,
    y1: number,
    r1: number,
  ): CanvasGradient {
    this.num(x0, y0, r0, x1, y1, r1);
    this.gradients++;
    this.radials.push({ x0, y0, r0, x1, y1, r1 });
    return stops(this);
  }

  /** The context, typed as the real thing for the code under test. */
  get as2d(): CanvasRenderingContext2D {
    return this as unknown as CanvasRenderingContext2D;
  }
}

/**
 * Gradient stops are where alphas end up, and an alpha built from a `NaN` is the other
 * half of the invisible-bug problem, so their offsets and colours are recorded too.
 */
function stops(rec: FakeContext): CanvasGradient {
  const mine: { offset: number; colour: string }[] = [];
  rec.gradientStops.push(mine);
  return {
    addColorStop(offset: number, colour: string): void {
      rec.numbers.push(offset);
      rec.styles.push(colour);
      mine.push({ offset, colour });
    },
  } as unknown as CanvasGradient;
}

/** Fails with the offending index if anything drawn was not a finite number. */
export function expectFinite(rec: FakeContext, what: string): void {
  const bad = rec.numbers.findIndex((n) => !Number.isFinite(n));
  if (bad >= 0) {
    throw new Error(`${what}: non-finite value at draw call ${bad} (${String(rec.numbers[bad])})`);
  }
  const badStyle = rec.styles.find((s) => s.includes('NaN'));
  if (badStyle !== undefined) throw new Error(`${what}: colour with NaN in it: ${badStyle}`);
}
