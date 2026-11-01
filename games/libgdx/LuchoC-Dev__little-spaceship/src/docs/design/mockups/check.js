/**
 * Verifies the mocks without a browser.
 *
 *     node docs/design/mockups/check.js
 *
 * Three things, in order of how quietly they fail:
 *
 *   1. Every sprite matches the size it declares in docs/design/02-sprite-sizes.md, uses only
 *      palette characters, and has odd dimensions. A silhouette that lies about its footprint
 *      forces hitbox rework across the code lane, and nothing else would catch it.
 *   2. Every scene obeys the palette split: no colour outside ls32, no gameplay colour in the
 *      background, no background colour in a gameplay sprite, and enemy fire clear of the
 *      brightest background pixel actually drawn.
 *   3. Each page's interface code runs against a stub DOM and finds every element it looks up.
 */

const fs = require('fs');
const path = require('path');

const SRC = path.join(__dirname, 'src');
const engineFiles = fs.readdirSync(SRC).filter(f => /^\d\d-.*\.js$/.test(f)).sort();
const engine = engineFiles.map(f => fs.readFileSync(path.join(SRC, f), 'utf8')).join('\n');

let failed = false;
function report(ok, text) {
  if (!ok) failed = true;
  console.log((ok ? '  pass  ' : '  FAIL  ') + text);
}

// The engine is written to run without a DOM, which is the whole reason it can be checked here.
const api = new Function(engine + '\nreturn { validateSprites, audit, SCENES, SCREENS, renderScreen, SPRITES };')();

console.log('sprites');
const problems = api.validateSprites();
if (!problems.length) report(true, Object.keys(api.SPRITES).length + ' sprites match their declared size, characters and odd dimensions');
problems.forEach(p => report(false, p));

console.log('scenes');
for (const key of Object.keys(api.SCENES)) {
  console.log('  ' + key);
  api.audit(key).findings.forEach(f => report(f.ok, '  ' + f.text));
}

console.log('screens');
for (const key of Object.keys(api.SCREENS)) {
  const fb = api.renderScreen(key);
  report(fb.d.length === 480 * 270, key + ' rasterises to a full 480x270 frame');
}

console.log('pages');
function ctxStub() {
  return new Proxy({
    createImageData: (w, h) => ({ data: new Uint8ClampedArray(w * h * 4), width: w, height: h }),
    imageSmoothingEnabled: false, lineWidth: 1, strokeStyle: ''
  }, { get: (t, k) => (k in t ? t[k] : () => {}), set: (t, k, v) => { t[k] = v; return true; } });
}
function elStub(id) {
  return {
    id, width: 0, height: 0, className: '', textContent: '', innerHTML: '', type: '', children: [],
    getContext: () => ctxStub(),
    getBoundingClientRect() { return { width: this.width, height: this.height }; },
    appendChild(c) { this.children.push(c); return c; },
    append(...c) { this.children.push(...c); },
    setAttribute() {}, addEventListener() {},
    classList: { toggle() {}, add() {}, remove() {} }, style: {}
  };
}

for (const file of fs.readdirSync(SRC).filter(f => f.endsWith('.ui.js')).sort()) {
  const name = file.slice(0, -'.ui.js'.length);
  const markup = fs.readFileSync(path.join(SRC, name + '.page.html'), 'utf8');
  const looked = new Set();
  const registry = new Map();
  const document = {
    getElementById(id) {
      looked.add(id);
      if (!registry.has(id)) registry.set(id, elStub(id));
      return registry.get(id);
    },
    createElement: tag => elStub(tag)
  };
  const ui = fs.readFileSync(path.join(SRC, file), 'utf8');
  try {
    new Function('document', 'requestAnimationFrame', 'cancelAnimationFrame', 'addEventListener',
      engine + '\n' + ui)(document, () => 1, () => {}, () => {});
    report(true, name + ': interface ran without throwing');
  } catch (e) {
    report(false, name + ': interface threw - ' + e.message);
    continue;
  }
  const missing = [...looked].filter(id => !markup.includes('id="' + id + '"'));
  report(missing.length === 0, missing.length
    ? name + ': markup is missing ' + missing.join(', ')
    : name + ': all ' + looked.size + ' elements it looks up exist in the markup');
}

console.log(failed ? '\nsomething is wrong' : '\nall checks passed');
process.exit(failed ? 1 : 0);
