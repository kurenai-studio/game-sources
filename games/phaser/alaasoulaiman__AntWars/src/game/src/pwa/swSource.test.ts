// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
import { describe, expect, it } from 'vitest';
import { SW_FILE, buildVersion, hash53, precachePath, precacheUrls, serviceWorkerSource } from './swSource';

const enc = new TextEncoder();
const file = (path: string, text: string) => ({ path, bytes: enc.encode(text) });

describe('the files the worker keeps', () => {
  it.each([
    ['index.html', true],
    ['assets/index-CdlbQkDO.js', true],
    ['manifest.webmanifest', true],
    ['icon-192.png', true],
    ['icon-512.png', true],
    ['icon-180.png', true],
    ['favicon.svg', true],
    [SW_FILE, false],
    ['assets/index-CdlbQkDO.js.map', false],
    ['.DS_Store', false],
    ['assets/.hidden', false],
    ['_headers', false],
    ['_redirects', false],
    ['netlify.toml', false],
  ])('%s kept: %s', (path, kept) => {
    expect(precachePath(path)).toBe(kept);
  });

  it('keeps index.html as the game address ./ , in order, once, never the worker itself', () => {
    expect(precacheUrls(['index.html', 'sw.js', 'assets/b.js', 'favicon.svg', 'assets/a.js', 'assets/a.js.map'])).toEqual([
      './',
      './assets/a.js',
      './assets/b.js',
      './favicon.svg',
    ]);
  });
});

describe('the version stamp', () => {
  it('hash53 gives the published cyrb53 values', () => {
    expect(hash53(enc.encode('a'))).toBe(7929297801672961);
    expect(hash53(enc.encode('b'))).toBe(8684336938537663);
    expect(hash53(enc.encode('Ant Wars'))).toBe(8848004520303359);
    expect(hash53(new Uint8Array(0))).toBe(3338908027751811);
  });

  const build = [file('index.html', '<html>'), file('assets/a.js', 'x')];

  it('is 14 hex digits, pinned for a known build, and the same whatever order the files are listed in', () => {
    expect(buildVersion(build)).toBe('1b981d72d3d0b7');
    expect(buildVersion([...build].reverse())).toBe('1b981d72d3d0b7');
    expect(buildVersion(build)).toMatch(/^[0-9a-f]{14}$/);
  });

  it('changes when only the worker code changes (the same files, a new worker)', () => {
    expect(buildVersion(build, 'worker code')).toBe('031ccbfaab6c9c');
    expect(buildVersion(build, 'worker code')).not.toBe(buildVersion(build, 'worker code 2'));
    expect(buildVersion(build, 'worker code')).not.toBe(buildVersion(build));
  });

  it('changes when one byte of one file changes, when a file is renamed, added or dropped', () => {
    const v = buildVersion(build);
    expect(buildVersion([file('index.html', '<html>'), file('assets/a.js', 'y')])).not.toBe(v);
    expect(buildVersion([file('index.html', '<html>'), file('assets/b.js', 'x')])).not.toBe(v);
    expect(buildVersion([...build, file('icon-192.png', 'p')])).not.toBe(v);
    expect(buildVersion([build[0]])).not.toBe(v);
  });

  it('ignores the files the worker does not keep (its own text and the source maps)', () => {
    const v = buildVersion(build);
    expect(buildVersion([...build, file(SW_FILE, 'anything')])).toBe(v);
    expect(buildVersion([...build, file('assets/a.js.map', '{}')])).toBe(v);
  });
});

describe('the worker source', () => {
  const src = serviceWorkerSource('0be7381123b753', ['./', './assets/a.js']);

  it('names its version and the kept files, and answers skip-waiting', () => {
    expect(src).toContain('const VERSION = "0be7381123b753";');
    expect(src).toContain('const FILES = ["./","./assets/a.js"];');
    expect(src).toContain("if (type === 'skip-waiting') self.skipWaiting();");
    expect(src).toContain("caches.delete(key)");
    expect(src).toContain('self.clients.claim()');
  });

  it('answers a kept file whatever Vary the server sent (the module script carries an Origin header)', () => {
    expect(src).toContain("c.match('./', { ignoreVary: true })");
    expect(src).toContain('c.match(req, { ignoreVary: true })');
  });

  it('is a script that parses', () => {
    expect(() => new Function(src)).not.toThrow();
  });

  it('holds no dash punctuation in its text', () => {
    expect(src).not.toMatch(/[\u2013\u2014]/);
    expect(src).not.toMatch(/ -- /);
  });
});
