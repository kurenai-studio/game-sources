// SVG renderer for boards and contact sheets, in the house style. Colors come from the design tokens.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { FACING } from "./board.mjs";

const tokensPath = fileURLToPath(
  new URL("../../packages/design-tokens/tokens.json", import.meta.url),
);
const TOKENS = JSON.parse(readFileSync(tokensPath, "utf8")).tokens;

export function palette(theme) {
  const p = {};
  for (const t of TOKENS) p[t.name.replace(/-([a-z])/g, (_, c) => c.toUpperCase())] = t[theme];
  return p;
}

const r2 = (n) => Math.round(n * 100) / 100;
const chamfer = (x, y, w, h, c) =>
  `M${x} ${y}H${r2(x + w - c)}L${r2(x + w)} ${r2(y + c)}V${r2(y + h)}H${x}Z`;
const ANGLE = { east: 0, south: 90, west: 180, north: 270 };

/** One board as SVG elements, `size` units on its longest side. */
export function boardSvg(rows, size, t, uid) {
  const width = rows[0].length;
  const height = rows.length;
  const gap = 2;
  const n = Math.max(width, height);
  const cell = (size - gap * (n - 1)) / n;
  let out = `<defs><pattern id="h${uid}" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="10" height="10" fill="${t.wall}"/><rect width="4" height="10" fill="${t.wallHatch}"/></pattern></defs>`;
  rows.forEach((row, y) =>
    [...row].forEach((c, x) => {
      const px = r2(x * (cell + gap));
      const py = r2(y * (cell + gap));
      const s = r2(cell);
      const mx = px + cell / 2;
      const my = py + cell / 2;
      if (c === "#")
        out += `<rect x="${px}" y="${py}" width="${s}" height="${s}" fill="url(#h${uid})"/>`;
      else if (c === "G") {
        out += `<rect x="${px}" y="${py}" width="${s}" height="${s}" fill="${t.signal}"/>`;
        out += `<circle cx="${r2(mx)}" cy="${r2(my)}" r="${r2(cell * 0.28)}" fill="none" stroke="${t.ink}" stroke-width="${r2(cell * 0.06)}"/>`;
        out += `<circle cx="${r2(mx)}" cy="${r2(my)}" r="${r2(cell * 0.09)}" fill="${t.ink}"/>`;
      } else out += `<rect x="${px}" y="${py}" width="${s}" height="${s}" fill="${t.floor}"/>`;
      if (c in FACING) {
        const block = cell * 0.74;
        const bx = px + (cell - block) / 2;
        const by = py + (cell - block) / 2;
        const wedge = block * 0.46;
        out += `<path d="${chamfer(r2(bx), r2(by), r2(block), r2(block), r2(block * 0.22))}" fill="${t.ink}"/>`;
        out += `<path d="M${r2(mx + wedge * 0.5)} ${r2(my)}L${r2(mx - wedge * 0.4)} ${r2(my - wedge * 0.5)}V${r2(my + wedge * 0.5)}Z" fill="${t.signal}" transform="rotate(${ANGLE[FACING[c]]} ${r2(mx)} ${r2(my)})"/>`;
      }
    }),
  );
  return out;
}

/** A contact sheet: each entry is { title, rows, caption }. */
export function sheetSvg(entries, { title, theme = "light", columns = 3, boardSize = 190 } = {}) {
  const t = palette(theme);
  const cellW = boardSize + 60;
  const cellH = boardSize + 190;
  const rowsCount = Math.ceil(entries.length / columns);
  const width = 40 + columns * cellW;
  const height = 110 + rowsCount * cellH;
  let body = "";
  entries.forEach((e, i) => {
    const x = 40 + (i % columns) * cellW;
    const y = 110 + Math.floor(i / columns) * cellH;
    body += `<g transform="translate(${x} ${y})"><rect width="${boardSize + 20}" height="2" fill="${t.ink}"/>`;
    body += `<text y="26" font-size="12" letter-spacing="2" fill="${t.mute}">${e.label ?? ""}</text>`;
    body += `<text y="52" font-size="22" letter-spacing="1" fill="${t.ink}">${(e.title ?? "").toUpperCase()}</text>`;
    body += `<g transform="translate(0 66)">${boardSvg(e.rows, boardSize, t, `${theme}${i}`)}</g>`;
    (e.caption ?? []).forEach((line, k) => {
      body += `<text y="${66 + boardSize + 22 + k * 17}" font-size="13" fill="${t.mute}">${line}</text>`;
    });
    body += "</g>";
  });
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" font-family="'Avenir Next Condensed','DIN Condensed','Arial Narrow',sans-serif" font-weight="700"><rect width="${width}" height="${height}" fill="${t.ground}"/><text x="40" y="62" font-size="32" letter-spacing="1" fill="${t.ink}">${(title ?? "").toUpperCase()}</text>${body}</svg>`;
}
