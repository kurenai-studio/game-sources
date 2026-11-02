import os from 'node:os';
import path from 'node:path';
import { describe, expect, test } from 'vitest';

import formatDirectory from './formatDirectory.js';

const home = os.homedir();

describe('formatDirectory', () => {
  test('replaces home directory with ~', () => {
    expect(formatDirectory(home)).toBe('~');
  });

  test('replaces home prefix with ~/', () => {
    expect(formatDirectory(`${home}/Projects/warriorjs`)).toBe('~/Projects/warriorjs');
  });

  test('resolves relative paths before replacing', () => {
    expect(formatDirectory('.')).toBe(path.resolve('.').replace(home, '~'));
  });

  test('returns absolute path when not under home', () => {
    expect(formatDirectory('/tmp/warriorjs')).toBe('/tmp/warriorjs');
  });

  test('does not replace partial home match', () => {
    expect(formatDirectory(`${home}-extra/foo`)).toBe(`${home}-extra/foo`);
  });
});
