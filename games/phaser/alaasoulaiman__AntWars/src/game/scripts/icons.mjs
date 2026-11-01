// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Draws the home screen icons from one picture (ours): the ant of the Yard on its nest, a dart in flight, on grass.
// The picture fills the square and keeps the ant inside the middle circle, so one file serves as a plain icon and as a
// maskable one (Android crops to a circle or a rounded square). Renders with the installed Google Chrome:
//   node scripts/icons.mjs        writes public/icon-512.png, public/icon-192.png and public/icon-180.png (Apple)
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright-core';

const here = path.dirname(fileURLToPath(import.meta.url));
const pub = path.resolve(here, '..', 'public');

/** The icon at 512 units; every size is the same picture scaled. */
const SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <radialGradient id="yard" cx="50%" cy="46%" r="70%">
      <stop offset="0" stop-color="#6cbf4e"/>
      <stop offset="0.62" stop-color="#3f8a32"/>
      <stop offset="1" stop-color="#1f4d1c"/>
    </radialGradient>
    <radialGradient id="mound" cx="50%" cy="40%" r="60%">
      <stop offset="0" stop-color="#b07a3e"/>
      <stop offset="1" stop-color="#6b4320"/>
    </radialGradient>
  </defs>
  <rect width="512" height="512" fill="url(#yard)"/>
  <g fill="#2c6a25" opacity="0.85">
    <path d="M40 470 q10 -40 18 0 q6 -34 14 0 q8 -30 12 0z"/>
    <path d="M430 480 q10 -42 18 0 q6 -36 14 0 q8 -30 12 0z"/>
    <path d="M24 92 q10 -36 16 0 q6 -30 12 0z"/>
    <path d="M452 70 q10 -36 16 0 q6 -30 12 0z"/>
  </g>
  <g fill="#8fd16f" opacity="0.6">
    <circle cx="70" cy="200" r="9"/><circle cx="84" cy="206" r="9"/><circle cx="76" cy="192" r="9"/>
    <circle cx="446" cy="300" r="9"/><circle cx="460" cy="306" r="9"/><circle cx="452" cy="292" r="9"/>
  </g>
  <ellipse cx="256" cy="402" rx="150" ry="44" fill="url(#mound)"/>
  <ellipse cx="256" cy="396" rx="56" ry="16" fill="#3a230e"/>
  <g stroke="#1f1206" stroke-width="16" stroke-linecap="round" fill="none">
    <path d="M214 288 L150 352 M256 300 L256 370 M298 288 L362 352"/>
    <path d="M216 236 L150 186 M296 236 L362 186"/>
    <path d="M232 132 L196 78 M280 132 L316 78"/>
  </g>
  <circle cx="196" cy="78" r="12" fill="#1f1206"/>
  <circle cx="316" cy="78" r="12" fill="#1f1206"/>
  <ellipse cx="256" cy="300" rx="70" ry="82" fill="#ffb627" stroke="#1f1206" stroke-width="14"/>
  <path d="M206 286 Q256 306 306 286" stroke="#c97c10" stroke-width="10" fill="none" stroke-linecap="round"/>
  <path d="M212 322 Q256 340 300 322" stroke="#c97c10" stroke-width="10" fill="none" stroke-linecap="round"/>
  <circle cx="256" cy="176" r="72" fill="#ffc94a" stroke="#1f1206" stroke-width="14"/>
  <circle cx="226" cy="166" r="24" fill="#ffffff"/>
  <circle cx="286" cy="166" r="24" fill="#ffffff"/>
  <circle cx="231" cy="172" r="12" fill="#111111"/>
  <circle cx="291" cy="172" r="12" fill="#111111"/>
  <path d="M232 212 Q256 226 280 212" stroke="#1f1206" stroke-width="9" fill="none" stroke-linecap="round"/>
  <g transform="rotate(-38 382 166)">
    <rect x="300" y="160" width="74" height="12" rx="6" fill="#fff3b0" opacity="0.75"/>
    <path d="M372 150 L410 166 L372 182 Z" fill="#ffe14d" stroke="#1f1206" stroke-width="6" stroke-linejoin="round"/>
  </g>
</svg>`;

const SIZES = [
  ['icon-512.png', 512],
  ['icon-192.png', 192],
  ['icon-180.png', 180],
];

const browser = await chromium.launch({ channel: 'chrome', headless: true });
try {
  for (const [file, size] of SIZES) {
    const page = await browser.newPage({ viewport: { width: size, height: size }, deviceScaleFactor: 1 });
    const html = `<!doctype html><html><head><style>html,body{margin:0;padding:0;background:#16301a}svg{display:block;width:${size}px;height:${size}px}</style></head><body>${SVG}</body></html>`;
    await page.setContent(html, { waitUntil: 'load' });
    const out = path.join(pub, file);
    await page.locator('svg').screenshot({ path: out, omitBackground: false });
    await page.close();
    console.log('wrote', out, `${size}x${size}`);
  }
} finally {
  await browser.close();
}
