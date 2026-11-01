/**
 * Export the real sprite atlas from the single source of truth, `docs/design/mockups/src/01-sprites.js`.
 *
 *     node docs/design/atlas/build-atlas.js
 *
 * Writes, into `assets/atlas/` (the directory `PackedSpriteAtlas.ATLAS_PATH` names, not next to this
 * script the way the font/fx/skin builders do — those three have nothing loading them from disk yet,
 * this is the first design-time script whose output is the thing the game actually ships):
 *
 *     sprites.png     one page, every sprite packed left-to-right in shelves, 1px gap
 *     sprites.atlas   the region index, legacy libGDX text format, one block per region
 *
 * and, next to this script, for looking at:
 *
 *     specimen.png    every packed sprite on an N2 ground, at 3x
 *
 * No third-party libraries, per `CLAUDE.md` — Node's built-in `zlib` writes the PNG, and this file
 * implements the 4-byte CRC32 each chunk needs since `zlib` does not export one.
 *
 * The engine is not reimplemented here. `01-sprites.js` builds the wide archetypes with `sym()`,
 * called inline while the `SPRITES` object literal is evaluated — loading the file with `new
 * Function`, the same trick `docs/design/mockups/check.js` already uses to run the mocks without a
 * DOM, means every sprite arrives here pre-mirrored and already validated against its own rules by
 * `validateSprites()`. A second parser that re-expanded `sym()` rows would be exactly the kind of
 * transcription fork the brief asked not to create.
 */
'use strict';

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const HERE = __dirname;
const MOCKUP_SRC = path.join(HERE, '..', 'mockups', 'src');
const ATLAS_OUT = path.join(HERE, '..', '..', '..', 'assets', 'atlas');

/**
 * A handful of ids the ECS emits do not match the id the art was authored under. The pickups were
 * proposed in `02-sprite-sizes.md` under one name and grew their own `PickupSystem.KIND_*`-derived
 * name by the time content wired them up; `boss-shot` was never proposed at all. Each alias renders
 * identically to its source — same pixels, a second name pointing at the same packed rectangle — so
 * nothing here forks the art, and every case is reported back in the handoff rather than silently
 * decided.
 */
const ALIASES = {
  // WorldRenderer/CleanupSystem read `pickup-<PickupSystem.KIND_*>`; 01-sprites.js proposed the
  // shorter names below for the same five capsules plus the attachment's own larger one.
  'pickup-weapon-upgrade': 'pickup-weapon',
  'pickup-extra-life': 'pickup-life',
  'pickup-bomb-recharge': 'pickup-bomb',
  'pickup-invulnerability': 'pickup-invuln',
  'pickup-attachment': 'pickup-module',
  // BossSystem.SHOT_SPRITE is 'boss-shot' at PROJECTILE_RADIUS 2.0 — exactly shot-e-small's radius
  // and the same "compact, magenta-family hostile fire" reading. No fifth projectile silhouette was
  // ever drawn for it, so it reuses shot-e-small rather than inventing new art on this pass.
  'boss-shot': 'shot-e-small',
};

const GAP = 1;

function loadEngine() {
  const palette = fs.readFileSync(path.join(MOCKUP_SRC, '00-palette.js'), 'utf8');
  const sprites = fs.readFileSync(path.join(MOCKUP_SRC, '01-sprites.js'), 'utf8');
  const body = palette + '\n' + sprites + '\nreturn { PALETTE, CHARS, SPRITES, validateSprites };';
  return new Function(body)();
}

function rasterize(sprite, palette, chars) {
  const w = sprite.w, h = sprite.h;
  const px = [];
  for (let y = 0; y < h; y++) {
    const row = [];
    const line = sprite.art[y];
    for (let x = 0; x < w; x++) {
      const idx = chars[line[x]];
      if (idx === undefined) {
        throw new Error(sprite.id + ': unknown character "' + line[x] + '" at row ' + y);
      }
      if (idx < 0) {
        row.push([0, 0, 0, 0]);
        continue;
      }
      const hex = palette[idx];
      row.push([
        parseInt(hex.slice(1, 3), 16),
        parseInt(hex.slice(3, 5), 16),
        parseInt(hex.slice(5, 7), 16),
        255,
      ]);
    }
    px.push(row);
  }
  return px;
}

/** Shelf packing, tallest first so a run of small icons does not fragment a shelf a boss part needs. */
function pack(entries) {
  const order = entries.slice().sort((a, b) => b.h - a.h || b.w - a.w);
  const totalArea = entries.reduce((sum, e) => sum + (e.w + GAP) * (e.h + GAP), 0);
  let width = Math.max(64, Math.ceil(Math.sqrt(totalArea * 1.15) / 4) * 4);

  let x = GAP, y = GAP, shelfHeight = 0, height = 0;
  const placed = {};
  for (const e of order) {
    if (x + e.w + GAP > width) {
      x = GAP;
      y += shelfHeight + GAP;
      shelfHeight = 0;
    }
    placed[e.id] = { x, y, w: e.w, h: e.h };
    x += e.w + GAP;
    shelfHeight = Math.max(shelfHeight, e.h);
    height = Math.max(height, y + shelfHeight + GAP);
  }
  return { placed, width, height };
}

function crc32(buf) {
  let table = crc32.table;
  if (!table) {
    table = crc32.table = new Uint32Array(256);
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      table[n] = c >>> 0;
    }
  }
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) crc = table[(crc ^ buf[i]) & 0xFF] ^ (crc >>> 8);
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function writePng(filePath, canvas, width, height) {
  const rowBytes = width * 4;
  const raw = Buffer.alloc((rowBytes + 1) * height);
  for (let y = 0; y < height; y++) {
    const base = y * (rowBytes + 1);
    raw[base] = 0; // filter: none
    for (let x = 0; x < width; x++) {
      const [r, g, b, a] = canvas[y][x];
      const o = base + 1 + x * 4;
      raw[o] = r; raw[o + 1] = g; raw[o + 2] = b; raw[o + 3] = a;
    }
  }

  function chunk(tag, data) {
    const typeAndData = Buffer.concat([Buffer.from(tag, 'ascii'), data]);
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length, 0);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(typeAndData), 0);
    return Buffer.concat([len, typeAndData, crc]);
  }

  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;   // bit depth
  ihdr[9] = 6;   // colour type: RGBA
  ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;

  const idat = zlib.deflateSync(raw, { level: 9 });
  const signature = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  fs.writeFileSync(
    filePath,
    Buffer.concat([signature, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))]));
}

function main() {
  const { PALETTE, CHARS, SPRITES, validateSprites } = loadEngine();

  const problems = validateSprites();
  if (problems.length) {
    console.error('sprite validation failed, refusing to pack:');
    problems.forEach((p) => console.error('  ' + p));
    process.exit(1);
  }

  const ids = Object.keys(SPRITES);
  const entries = ids.map((id) => ({ id, w: SPRITES[id].w, h: SPRITES[id].h }));
  const { placed, width, height } = pack(entries);

  const canvas = [];
  for (let y = 0; y < height; y++) canvas.push(new Array(width).fill([0, 0, 0, 0]));
  for (const id of ids) {
    const rect = placed[id];
    const px = rasterize(SPRITES[id], PALETTE, CHARS);
    for (let y = 0; y < rect.h; y++) {
      for (let x = 0; x < rect.w; x++) canvas[rect.y + y][rect.x + x] = px[y][x];
    }
  }

  fs.mkdirSync(ATLAS_OUT, { recursive: true });
  writePng(path.join(ATLAS_OUT, 'sprites.png'), canvas, width, height);

  const lines = [
    'sprites.png',
    'size: ' + width + ',' + height,
    'format: RGBA8888',
    'filter: Nearest,Nearest',
    'repeat: none',
  ];
  function region(name, rect) {
    lines.push(name);
    lines.push('  rotate: false');
    lines.push('  xy: ' + rect.x + ', ' + rect.y);
    lines.push('  size: ' + rect.w + ', ' + rect.h);
    lines.push('  orig: ' + rect.w + ', ' + rect.h);
    lines.push('  offset: 0, 0');
    lines.push('  index: -1');
  }
  for (const id of ids) region(id, placed[id]);
  for (const [alias, source] of Object.entries(ALIASES)) {
    if (!placed[source]) throw new Error('alias ' + alias + ' points at unknown sprite ' + source);
    region(alias, placed[source]);
  }
  fs.writeFileSync(path.join(ATLAS_OUT, 'sprites.atlas'), lines.join('\n') + '\n');

  console.log('sprites.png - ' + width + 'x' + height + ', ' + ids.length + ' sprites');
  console.log('sprites.atlas - ' + ids.length + ' regions + ' + Object.keys(ALIASES).length + ' aliases');

  // Specimen: the same canvas, framed on an N2 ground, at 3x, for looking at rather than for loading.
  const ground = [0x24, 0x2C, 0x3B, 255];
  const scale = 3;
  const spec = [];
  for (let y = 0; y < height * scale; y++) {
    const row = new Array(width * scale);
    for (let x = 0; x < width * scale; x++) {
      const px = canvas[Math.floor(y / scale)][Math.floor(x / scale)];
      row[x] = px[3] === 0 ? ground : px;
    }
    spec.push(row);
  }
  writePng(path.join(HERE, 'specimen.png'), spec, width * scale, height * scale);
  console.log('specimen.png - ' + (width * scale) + 'x' + (height * scale));
}

main();
