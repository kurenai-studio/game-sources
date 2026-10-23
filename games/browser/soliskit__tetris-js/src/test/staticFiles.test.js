// Checks the files the browser loads directly: page, manifest, service worker
// and icons. These are served from GitHub Pages under /tetris-js/, so every
// reference must be relative and every file must exist.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const publicDir = fileURLToPath(new URL('../public/', import.meta.url));
const read = file => fs.readFileSync(path.join(publicDir, file), 'utf8');
const exists = file => fs.existsSync(path.join(publicDir, file));

const html = read('index.html');
const manifest = JSON.parse(read('manifest.webmanifest'));
const serviceWorker = read('sw.js');
const appShell = JSON.parse(serviceWorker.match(/const APP_SHELL = (\[[\s\S]*?\]);/)[1].replace(/'/g, '"'));

function pngSize(file) {
  const data = fs.readFileSync(path.join(publicDir, file));
  assert.equal(data.toString('ascii', 1, 4), 'PNG', `${file} is a PNG`);
  return `${data.readUInt32BE(16)}x${data.readUInt32BE(20)}`;
}

test('every file the page references exists and uses a relative path [APP-3]', () => {
  const references = [...html.matchAll(/(?:src|href)="([^"]+)"/g)].map(match => match[1]);
  assert.ok(references.length >= 5);
  for (const reference of references) {
    assert.ok(!reference.startsWith('/') && !/^https?:/.test(reference), `${reference} must be relative`);
    assert.ok(exists(reference), `${reference} exists`);
  }
});

test('the page preloads exactly the modules script.js imports, directly or not [APP-5]', () => {
  const imported = new Set();
  const visit = file => {
    for (const [, specifier] of read(file).matchAll(/^import .* from '(\.[^']+)';$/gm)) {
      const target = path.posix.join(path.posix.dirname(file), specifier);
      if (!imported.has(target)) {
        imported.add(target);
        visit(target);
      }
    }
  };
  visit('script.js');
  assert.ok(imported.size >= 7, `${imported.size} modules`);
  const preloaded = [...html.matchAll(/<link rel="modulepreload" href="([^"]+)">/g)].map(match => match[1]);
  assert.deepEqual([...preloaded].sort(), [...imported].sort());
});

test('the page ids used by script.js all exist, canvases are canvases, and the dialog is a dialog [APP-3]', () => {
  const script = read('script.js');
  const ids = [...script.matchAll(/\belement\('([^']+)'\)/g)].map(match => match[1]);
  const canvasIds = [...script.matchAll(/\bcanvasElement\('([^']+)'\)/g)].map(match => match[1]);
  canvasIds.push(...JSON.parse(script.match(/(\[[^\]]*\])\.map\(canvasElement\)/)[1].replace(/'/g, '"')));
  assert.ok(ids.length >= 7 && canvasIds.length === 5, `${ids.length} elements, ${canvasIds.length} canvases`);
  for (const id of ids) assert.match(html, new RegExp(`id="${id}"`), id);
  for (const id of canvasIds) assert.match(html, new RegExp(`<canvas id="${id}"`), `${id} is a canvas`);
  assert.match(html, /<dialog id="newGameDialog"/, 'newGameDialog is a dialog');
  assert.doesNotMatch(script, /getElementById\('/, 'elements are looked up through element() or canvasElement()');
});

test('the viewport fits notches and blocks zooming [DSP-4] [APP-4]', () => {
  const viewport = html.match(/<meta name="viewport" content="([^"]+)"/)[1];
  for (const part of ['width=device-width', 'initial-scale=1.0', 'maximum-scale=1.0', 'user-scalable=no', 'viewport-fit=cover']) {
    assert.ok(viewport.includes(part), part);
  }
});

test('the page has the tags iPhone needs to install the game [APP-1] [APP-4]', () => {
  for (const tag of [
    '<link rel="manifest" href="manifest.webmanifest">',
    '<link rel="apple-touch-icon" href="icons/apple-touch-icon.png">',
    '<meta name="apple-mobile-web-app-capable" content="yes">',
    '<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">'
  ]) {
    assert.ok(html.includes(tag), tag);
  }
});

test('the manifest describes a portrait, full screen app that starts in its own folder [APP-1]', () => {
  assert.equal(manifest.name, 'Tetris');
  assert.equal(manifest.short_name, 'Tetris');
  assert.equal(manifest.display, 'fullscreen');
  assert.equal(manifest.orientation, 'portrait');
  assert.equal(manifest.start_url, './');
  assert.equal(manifest.scope, './');
  assert.match(manifest.theme_color, /^#[0-9a-f]{6}$/i);
  assert.match(manifest.background_color, /^#[0-9a-f]{6}$/i);
});

test('manifest icons exist, match their declared sizes and include a maskable one [APP-1]', () => {
  for (const icon of manifest.icons) {
    assert.ok(!icon.src.startsWith('/'), `${icon.src} must be relative`);
    assert.equal(pngSize(icon.src), icon.sizes, icon.src);
    assert.equal(icon.type, 'image/png');
  }
  const sizes = manifest.icons.map(icon => icon.sizes);
  assert.ok(sizes.includes('192x192') && sizes.includes('512x512'));
  assert.ok(manifest.icons.some(icon => icon.purpose === 'maskable'));
  assert.equal(pngSize('icons/apple-touch-icon.png'), '180x180');
});

test('the offline cache lists only files that exist, with relative paths [APP-2] [APP-3]', () => {
  for (const file of appShell) {
    assert.ok(!file.startsWith('/'), `${file} must be relative`);
    if (file !== './') assert.ok(exists(file), `${file} exists`);
  }
});

test('the offline cache includes every file the game needs to start [APP-2]', () => {
  const gameModules = fs.readdirSync(path.join(publicDir, 'game')).map(file => `game/${file}`);
  const required = ['./', 'index.html', 'style.css', 'script.js', 'manifest.webmanifest', ...gameModules];
  for (const file of required) assert.ok(appShell.includes(file), `${file} is cached for offline play`);
  for (const icon of manifest.icons) assert.ok(appShell.includes(icon.src), `${icon.src} is cached`);
});

test('the service worker is registered with a relative path [APP-2] [APP-3]', () => {
  assert.match(read('script.js'), /serviceWorker\.register\('sw\.js'\)/);
});
