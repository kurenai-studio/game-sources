/*
 * Generates the PNG icons with no image dependencies at all.
 *
 * A game with no runtime dependencies at all should not pull in a rasteriser to
 * make six squares. PNG is a container around zlib, and `node:zlib` is in the
 * standard library, so the whole encoder is the CRC table plus three chunks. The
 * artwork is the title screen's mark: one ring with the water running through it.
 *
 *   node tools/make-icons.mjs
 */
import { deflateSync } from 'node:zlib';
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const OUT = join(dirname(fileURLToPath(import.meta.url)), '..', 'public');

// --- PNG encoding -----------------------------------------------------------

const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (const byte of buf) c = CRC_TABLE[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

/** `rgba` is a Uint8Array of size w*h*4. */
function encodePng(rgba, w, h) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // colour type: RGBA
  const raw = Buffer.alloc(h * (w * 4 + 1));
  for (let y = 0; y < h; y++) {
    raw[y * (w * 4 + 1)] = 0; // filter: none
    Buffer.from(rgba.buffer, y * w * 4, w * 4).copy(raw, y * (w * 4 + 1) + 1);
  }
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// --- the mark ---------------------------------------------------------------

/*
 * The mark is `titleMark()` from src/ui/Shell.ts, kept in its own 48-unit box so
 * the two can be compared line for line: a ring at r=17 and two quadratic waves
 * clipped to its disc. The amplitudes look halved against the source path because
 * they are - a quadratic reaches half of its control point's offset, so
 * `q6 -5 12 0` peaks 2.5 units above its baseline, not 5.
 *
 * The screen tints the strokes with alpha over a lit background. An icon is read at
 * sixty pixels against a wallpaper nobody chose for it, so the same three hues are
 * carried further toward opaque. The order the title screen puts them in survives:
 * the near wave is the brightest thing here and the far wave the faintest, with the
 * ring lifted out of last place because at this size the ring is the silhouette.
 *
 * The colours here are those tints already composited onto the plate, and they are
 * drawn opaque. The ring straddles the edge of the disc, so half of it hangs over
 * whatever is behind the icon; left as an alpha it would go pale on a light home
 * screen and dark on a black one, and the mark would change colour depending on the
 * wallpaper. Baked, it is the same ring everywhere.
 */
const MARK = {
  cx: 24,
  cy: 24,
  ringR: 17,
  ringW: 1.2,
  waveW: 1.7,
  period: 24,
  waves: [
    { y: 26, amp: 2.5, rgb: [159, 228, 255] }, // the screen's 0.72, opaque
    { y: 33, amp: 2.0, rgb: [87, 146, 179] }, // 0.72 of (120,196,236) over the plate
  ],
  ring: { rgb: [128, 186, 210] }, // 0.80 of (159,228,255) over the plate
};

/*
 * Flat, and the same navy as `theme-color`. A gradient plate was tried and is
 * wrong twice over: the launcher paints `background_color` behind this icon on the
 * splash screen, where any lighter top edge reads as a pale square floating on the
 * navy, and the game's own direction is hard flat vector with the depth carried by
 * discrete planes rather than by a wash.
 *
 * It is also the only thing the icon fills, and it fills the disc rather than the
 * tile: outside the ring the icon is transparent, so what stands on the home screen
 * is the mark and not a card with the mark printed on it. The exception is the
 * maskable pair - see the output list at the foot of the file.
 */
const PLATE = [2, 16, 31];

/*
 * A lone circle reads smaller than the square it sits in, so the uncropped icons
 * take the mark out to 80.9% of the tile - a ring of r=18.75 in the 48 box - which
 * is as far as it can go and still clear the corner mask iOS cuts. The maskable
 * pair stays at the mark's true proportions: their padding is not decoration, it is
 * the 20% the launcher is allowed to crop, and the mark already carries it.
 */
const FILL = 18.75 / 17;

/*
 * Under about a pixel and a half a stroke stops being a thin line and becomes a row
 * of unrelated grey dots. The floor is in device pixels rather than mark units, so
 * it only bites where a device pixel is the problem: it moves nothing at 180 and
 * above, and is the whole reason the 32 still reads as a closed ring.
 */
const MIN_STROKE_PX = 1.5;

/**
 * Source-over onto a straight-alpha RGBA pixel.
 *
 * The buffer starts empty rather than filled, so this has to carry the alpha as
 * well as the colour: a stroke laid on nothing keeps its own edge instead of
 * dissolving into a plate that is not there.
 */
function over(buf, i, rgb, a) {
  if (a <= 0) return;
  const da = buf[i + 3] / 255;
  const out = a + da * (1 - a);
  buf[i] = Math.round((rgb[0] * a + buf[i] * da * (1 - a)) / out);
  buf[i + 1] = Math.round((rgb[1] * a + buf[i + 1] * da * (1 - a)) / out);
  buf[i + 2] = Math.round((rgb[2] * a + buf[i + 2] * da * (1 - a)) / out);
  buf[i + 3] = Math.round(out * 255);
}

const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);

/**
 * Distance from a pixel centre to a segment.
 *
 * Every edge in this mark is a stroked curve, and the cheapest honest way to
 * antialias one is to ask how far the pixel is from the curve and to fill the last
 * pixel by that distance. It hands us the round caps for nothing, too: the distance
 * to a segment's endpoint is a disc around the endpoint, which is what a round cap
 * is.
 */
function distToSegment(px, py, ax, ay, bx, by) {
  const vx = bx - ax;
  const vy = by - ay;
  const wx = px - ax;
  const wy = py - ay;
  const len2 = vx * vx + vy * vy;
  const t = len2 === 0 ? 0 : clamp01((wx * vx + wy * vy) / len2);
  const dx = wx - vx * t;
  const dy = wy - vy * t;
  return Math.sqrt(dx * dx + dy * dy);
}

/**
 * How much of each pixel a stroked polyline covers, into a coverage buffer.
 *
 * Coverage is the maximum over the segments rather than their sum, because a wave
 * doubles back over its own joins and summing would print a bright bead at every
 * one of them.
 */
function strokePolyline(cov, size, points, width) {
  const half = width / 2;
  const pad = half + 1;
  for (let s = 0; s + 1 < points.length; s++) {
    const [ax, ay] = points[s];
    const [bx, by] = points[s + 1];
    const minX = Math.max(0, Math.floor(Math.min(ax, bx) - pad));
    const maxX = Math.min(size - 1, Math.ceil(Math.max(ax, bx) + pad));
    const minY = Math.max(0, Math.floor(Math.min(ay, by) - pad));
    const maxY = Math.min(size - 1, Math.ceil(Math.max(ay, by) + pad));
    for (let y = minY; y <= maxY; y++) {
      for (let x = minX; x <= maxX; x++) {
        const c = clamp01(half + 0.5 - distToSegment(x + 0.5, y + 0.5, ax, ay, bx, by));
        const i = y * size + x;
        if (c > cov[i]) cov[i] = c;
      }
    }
  }
}

/**
 * One icon. `scale` is how much of the tile the mark is allowed to take: `FILL` for
 * anything shown whole, 1 for the maskable pair the launcher crops. `bleed` fills
 * the tile with the plate first, which only the maskable pair wants.
 */
function draw(size, scale, bleed) {
  const buf = new Uint8Array(size * size * 4);
  if (bleed) {
    for (let i = 0; i < size * size; i++) {
      buf[i * 4] = PLATE[0];
      buf[i * 4 + 1] = PLATE[1];
      buf[i * 4 + 2] = PLATE[2];
      buf[i * 4 + 3] = 255;
    }
  }

  const k = (size / 48) * scale;
  const map = (v) => (v - 24) * k + size / 2;
  const stroke = (w) => Math.max(MIN_STROKE_PX, w * k);

  const cx = map(MARK.cx);
  const cy = map(MARK.cy);
  const ringR = MARK.ringR * k;

  // The disc: both the icon's whole background and the shape the waves are clipped
  // to, with one soft edge doing both jobs, so the water ends exactly where the ring
  // is instead of a pixel either side of it.
  const discCov = new Float32Array(size * size);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const dx = x + 0.5 - cx;
      const dy = y + 0.5 - cy;
      const c = clamp01(ringR - Math.sqrt(dx * dx + dy * dy) + 0.5);
      discCov[y * size + x] = c;
      over(buf, (y * size + x) * 4, PLATE, c);
    }
  }

  /*
   * `q6 -5 12 0 t12 0 ...` is a chain of quadratics whose control point sits over
   * the middle of each half period. That makes x linear in t and leaves y as a
   * parabola, `amp * 4s(1-s)` off the baseline, flipping side every half period -
   * so the curve can be sampled straight from x with no Bezier stepping, and what
   * is sampled is the title screen's curve rather than a sine that resembles it.
   *
   * The phase is the source path's own, unshifted: a trough a quarter period left
   * of centre and a crest a quarter period right of it. Centring a crest instead
   * nests the two waves into a bowl and turns the mark into a generic wave-in-a-
   * circle; the authored phase draws a waterline crossing the disc, which is the
   * thing the game is about.
   */
  for (const wave of MARK.waves) {
    const cov = new Float32Array(size * size);
    const points = [];
    const half = MARK.period / 2;
    const step = Math.max(0.6 / k, MARK.period / 96);
    // The source path's own extent: six half periods from -24, which is two clear
    // periods wider than the disc, so the clip only ever meets open water.
    for (let x = -MARK.period; x <= 48 + MARK.period; x += step) {
      const t = (x + MARK.period) / half;
      const seg = Math.floor(t);
      const s = t - seg;
      const dir = seg % 2 === 0 ? -1 : 1;
      points.push([map(x), map(wave.y + dir * wave.amp * 4 * s * (1 - s))]);
    }
    strokePolyline(cov, size, points, stroke(MARK.waveW));
    for (let i = 0; i < cov.length; i++) {
      const a = cov[i] * discCov[i];
      if (a > 0) over(buf, i * 4, wave.rgb, a);
    }
  }

  // The ring last, so the water passes behind it rather than over it, and so its
  // outer half overhangs the cut edge of the plate and hides the seam - which is
  // also what keeps the icon's own outline clean where the transparency begins.
  const ringHalf = stroke(MARK.ringW) / 2;
  const reach = ringR + ringHalf + 2;
  const x0 = Math.max(0, Math.floor(cx - reach));
  const x1 = Math.min(size - 1, Math.ceil(cx + reach));
  for (let y = Math.max(0, Math.floor(cy - reach)); y <= Math.min(size - 1, Math.ceil(cy + reach)); y++) {
    for (let x = x0; x <= x1; x++) {
      const dx = x + 0.5 - cx;
      const dy = y + 0.5 - cy;
      const c = clamp01(ringHalf + 0.5 - Math.abs(Math.sqrt(dx * dx + dy * dy) - ringR));
      if (c > 0) over(buf, (y * size + x) * 4, MARK.ring.rgb, c);
    }
  }
  return buf;
}

/*
 * Everything is transparent outside the ring except the maskable pair, and that is
 * not an oversight in either direction. A maskable icon is a promise that the image
 * fills its tile, because the launcher is going to cut its own shape out of it; hand
 * it a transparent one and some launchers put their own white card behind the hole
 * they cut. So the pair keeps the plate edge to edge, and gets cropped into whatever
 * silhouette the phone likes - which on a round-icon launcher is this same disc.
 */
for (const [name, size, scale, bleed] of [
  ['icon-32.png', 32, FILL, false],
  ['icon-180.png', 180, FILL, false],
  ['icon-192.png', 192, FILL, false],
  ['icon-512.png', 512, FILL, false],
  ['icon-maskable-192.png', 192, 1, true],
  ['icon-maskable-512.png', 512, 1, true],
]) {
  writeFileSync(join(OUT, name), encodePng(draw(size, scale, bleed), size, size));
  process.stdout.write(`wrote public/${name} (${size}x${size}${bleed ? ', full bleed' : ''})\n`);
}
