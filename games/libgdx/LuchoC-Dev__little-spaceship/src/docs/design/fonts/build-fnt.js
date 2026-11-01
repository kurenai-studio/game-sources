/**
 * Turn the two hand-drawn font sheets into a game-loadable AngelCode `.fnt` + `.png` pair, the same
 * "committed script generates a committed asset" pattern `docs/design/atlas/build-atlas.js` uses for
 * sprites: this script is the design-time generator, `assets/fonts/` is where the output ships from.
 *
 *     node docs/design/fonts/build-fnt.js
 *
 * The pixels are not re-rasterised here — `docs/design/fonts/font-mini.png` and `font-title.png`
 * already exist, produced by `python docs/design/fonts/build-fonts.py` from the glyph bitmasks in
 * `docs/design/mockups/src/00-palette.js`. This script copies those PNGs verbatim into
 * `assets/fonts/` and writes the `.fnt` describing them, computed from `03-typography.md`'s grid
 * rule rather than hand-authored: cell index = code - 32, 16 columns, and the glyph fills the whole
 * cell (no per-glyph metric table, per that document).
 *
 * `03-typography.md` rules out `FreeTypeFontGenerator` outright, so the plain AngelCode text format
 * is the loadable shape: `new BitmapFont(FileHandle)`, no reflection, nothing to verify under TeaVM
 * beyond ordinary file loading.
 *
 * The `.fnt`'s "metrics" line matters more than it looks. `03-typography.md` says the region is the
 * whole cell and no glyph needs a Y offset, but `BitmapFontData` derives `ascent`/`capHeight`/`down`
 * from the tallest glyph AABB unless told otherwise — with every glyph region the full cell, that
 * would read the cell height (10 or 13) as the cap height (7 or 11), pushing every line down. The
 * override below is what makes `BitmapFont.draw`'s `y` land on the top of the cell exactly, which is
 * the "top of most capital letters" contract `HudRenderer.yGdxTop` already assumes.
 *
 * The AngelCode parser has one undocumented ordering requirement, found by reading
 * `BitmapFont$BitmapFontData.load` (libGDX 1.14.2): the "metrics" override line is only picked up if
 * it is preceded by a "kernings count=" line. Without one, the loader's kerning-reading loop
 * silently consumes the metrics line's successor instead of the metrics line itself, and the
 * override never applies. Hence the harmless `kernings count=0` line below.
 */
'use strict';

const fs = require('fs');
const path = require('path');

const HERE = __dirname;
const ASSETS_FONTS = path.join(HERE, '..', '..', '..', 'assets', 'fonts');

const COLUMNS = 16;
const FIRST = 32;
const LAST = 126;

/**
 * `font-title` covers only 43 of the 95 ASCII codes; `03-typography.md` is explicit that the rest of
 * its cells are transparent on purpose, "so an unsupported character draws as a blank rather than as
 * whatever glyph happened to sit at that offset". A `char` line with width/height 0 is that blank: it
 * still advances by the fixed width (so a caller that forgets to uppercase does not desync a tabular
 * layout further down the line), but samples nothing.
 */
const FONTS = [
  {
    name: 'font-mini',
    cw: 6, ch: 10, base: 7, capHeight: 7, xHeight: 5,
    sheetW: 96, sheetH: 60,
    coverage: fullCoverage(),
  },
  {
    name: 'font-title',
    cw: 8, ch: 13, base: 11, capHeight: 11, xHeight: 11,
    sheetW: 128, sheetH: 78,
    coverage: titleCoverage(),
  },
];

function fullCoverage() {
  const set = new Set();
  for (let code = FIRST; code <= LAST; code++) set.add(code);
  return set;
}

function titleCoverage() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,:-!?';
  const set = new Set();
  for (const c of chars) set.add(c.charCodeAt(0));
  return set;
}

function buildFnt(font) {
  const rows = Math.ceil((LAST - FIRST + 1) / COLUMNS);
  const lineHeight = font.ch;
  const descent = -(font.ch - font.base);
  const ascent = -lineHeight;
  const down = -lineHeight;

  const lines = [];
  lines.push(
    `info face="${font.name}" size=${font.capHeight} bold=0 italic=0 charset="" unicode=0 ` +
    'stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=0,0'
  );
  lines.push(
    `common lineHeight=${lineHeight} base=${font.base} scaleW=${font.sheetW} ` +
    `scaleH=${font.sheetH} pages=1 packed=0`
  );
  lines.push(`page id=0 file="${font.name}.png"`);
  lines.push(`chars count=${font.coverage.size}`);

  for (let code = FIRST; code <= LAST; code++) {
    if (!font.coverage.has(code)) {
      continue;
    }
    const index = code - FIRST;
    const col = index % COLUMNS;
    const row = Math.floor(index / COLUMNS);
    const x = col * font.cw;
    const y = row * font.ch;
    // yoffset is written in the non-flip convention BitmapFontData.load expects: it stores
    // `-(height + writtenValue)` as the final offset, so `-height` here is what makes the final
    // offset land on 0 — the cell's top-left corner, per the class javadoc above.
    const yoffsetToken = -font.ch;
    lines.push(
      `char id=${code} x=${x} y=${y} width=${font.cw} height=${font.ch} xoffset=0 ` +
      `yoffset=${yoffsetToken} xadvance=${font.cw} page=0 chnl=15`
    );
  }

  lines.push('kernings count=0');
  lines.push(
    `metrics ascent=${ascent} descent=${descent} down=${down} capHeight=${font.capHeight} ` +
    `lineHeight=${lineHeight} spaceXadvance=${font.cw} xHeight=${font.xHeight}`
  );
  lines.push('');
  return lines.join('\n');
}

function main() {
  fs.mkdirSync(ASSETS_FONTS, { recursive: true });

  for (const font of FONTS) {
    const sourcePng = path.join(HERE, font.name + '.png');
    if (!fs.existsSync(sourcePng)) {
      console.error(
        font.name + '.png missing under docs/design/fonts/ - run build-fonts.py first'
      );
      process.exitCode = 1;
      return;
    }
    fs.copyFileSync(sourcePng, path.join(ASSETS_FONTS, font.name + '.png'));

    const fnt = buildFnt(font);
    fs.writeFileSync(path.join(ASSETS_FONTS, font.name + '.fnt'), fnt);
    console.log(font.name + '.fnt + .png - ' + font.coverage.size + ' glyphs');
  }
}

main();
