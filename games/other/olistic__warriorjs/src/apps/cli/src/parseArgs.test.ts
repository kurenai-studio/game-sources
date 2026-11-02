import { describe, expect, test } from 'vitest';

import parseArgs from './parseArgs.js';

test("doesn't fail when no args are supplied", () => {
  parseArgs([]);
});

describe('--directory', () => {
  test('parses correctly', () => {
    expect(parseArgs(['--directory', '/path/to/run']).directory).toBe('/path/to/run');
  });

  test('has alias -d', () => {
    expect(parseArgs(['-d', '/path/to/run']).directory).toBe('/path/to/run');
  });

  test("defaults to '.'", () => {
    expect(parseArgs([]).directory).toBe('.');
  });
});

describe('--level', () => {
  test('parses correctly', () => {
    expect(parseArgs(['--level', '4']).level).toBe(4);
  });

  test('has alias -l', () => {
    expect(parseArgs(['-l', '4']).level).toBe(4);
  });

  test('throws if not a number', () => {
    expect(() => parseArgs(['-l', 'invalid'])).toThrow('Invalid argument: level must be a number');
  });
});

describe('--silent', () => {
  test('parses correctly', () => {
    expect(parseArgs(['--silent']).silent).toBe(true);
  });

  test('has alias -s', () => {
    expect(parseArgs(['-s']).silent).toBe(true);
  });

  test('defaults to false', () => {
    expect(parseArgs([]).silent).toBe(false);
  });
});
