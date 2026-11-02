// Single-file build (index.html with JS and fonts inlined) for previewing the game anywhere.
import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
let html = readFileSync('dist/index.html', 'utf8');
for (const f of readdirSync('dist/fonts')) {
  const b64 = readFileSync(`dist/fonts/${f}`).toString('base64');
  html = html.replace(`url('fonts/${f}')`, `url(data:font/woff2;base64,${b64})`);
}
const js = readFileSync('dist/main.js', 'utf8').replace(/<\/script/gi, '<\\/script');
html = html.replace('<script src="main.js"></script>', () => `<script>${js}</script>`);
writeFileSync('dist/layer-shift.html', html);
console.log('dist/layer-shift.html', (html.length / 1024).toFixed(0), 'KB');
