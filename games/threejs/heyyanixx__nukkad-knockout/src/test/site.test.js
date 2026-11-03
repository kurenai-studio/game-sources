import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SITE = new URL('../site/', import.meta.url).pathname;
const read = (p) => readFileSync(join(SITE, p), 'utf8');

test('built v2 site: title, viewport, manifest, icons, font licence, local assets only, no placeholders', () => {
  assert.ok(existsSync(join(SITE, 'index.html')), 'run npm run build first');
  const html = read('index.html');
  assert.match(html, /<title>Nukkad Knockout 3D/);
  assert.match(html, /name="viewport" content="width=device-width/);
  assert.match(html, /rel="manifest" href="manifest.webmanifest"/);
  for (const m of html.matchAll(/(?:src|href)="([^"]+)"/g)) {
    const ref = m[1];
    if (/^https?:/.test(ref)) assert.fail('remote asset: ' + ref);
    const p = join(SITE, ref.replace(/^\.\//, ''));
    assert.ok(existsSync(p) || existsSync(join(p, 'index.html')), 'missing local asset ' + ref);
  }
  assert.doesNotMatch(html, /lorem ipsum|TODO|PLACEHOLDER/i);
  for (const id of ['game', 'title', 'select', 'pause', 'settings', 'result', 'touch', 'rotate', 'hud', 'cutin', 'classic-link']) assert.match(html, new RegExp(`id="${id}"`));
  for (const set of ['sfx', 'music', 'meme', 'vibe', 'fps']) assert.match(html, new RegExp(`data-set="${set}"`));
  for (const q of ['auto', 'low', 'med', 'high']) assert.match(html, new RegExp(`data-q="${q}"`));
  assert.match(html, /fictional parodies; not affiliated with any real person/);
  assert.match(html, /Meme-style SFX are original synth sounds/);
  const man = JSON.parse(read('manifest.webmanifest'));
  assert.equal(man.orientation, 'landscape');
  for (const ic of man.icons) assert.ok(existsSync(join(SITE, ic.src)));
  assert.ok(existsSync(join(SITE, 'fonts/Anton-Regular.ttf')) && read('fonts/OFL.txt').includes('SIL OPEN FONT LICENSE'));
});

test('built v2 bundle: three.js 3D renderer, full roster, no audio files, no trackers', () => {
  const js = readdirSync(join(SITE, 'assets')).filter((f) => f.endsWith('.js'));
  assert.equal(js.length, 1);
  const code = readFileSync(join(SITE, 'assets', js[0]), 'utf8');
  for (const name of ['CHAIWALA CHHOTU', 'HEYY ANISH', 'CARRY MINTU', 'CHAPPAL BOOMERANG', 'NUKKAD JN', 'WebGLRenderer', 'MeshToonMaterial', 'EMOTIONAL DAMAGE']) assert.ok(code.includes(name), name);
  assert.doesNotMatch(code, /\.mp3|\.ogg|\.wav"|googletagmanager|fonts\.googleapis|gtag\(/);
});

test('PWA: service worker cache bumped for v2 and precaches the real build', () => {
  const sw = read('sw.js');
  assert.match(sw, /nukkad-ko-v2/);
  assert.doesNotMatch(sw, /'nukkad-ko-v1'/);
  const shell = JSON.parse(sw.match(/const SHELL = (\[[^\]]*\]);/)[1]);
  for (const f of shell) assert.ok(existsSync(join(SITE, f.endsWith('/') ? f + 'index.html' : f)), 'precache entry exists: ' + f);
  assert.ok(shell.some((f) => /assets\/index-.*\.js$/.test(f)) && shell.includes('./classic/'));
});

test('classic 2D v1 kept playable at /classic/ with a link back', () => {
  const html = read('classic/index.html');
  assert.match(html, /Classic 2D/);
  assert.match(html, /href="\.\.\/"/);
  const js = readdirSync(join(SITE, 'classic/assets')).filter((f) => f.endsWith('.js'));
  assert.equal(js.length, 1);
  const code = readFileSync(join(SITE, 'classic/assets', js[0]), 'utf8');
  assert.ok(code.includes('CHAPPAL BOOMERANG') && code.includes('getContext("2d")') || code.includes("getContext('2d')"));
});
