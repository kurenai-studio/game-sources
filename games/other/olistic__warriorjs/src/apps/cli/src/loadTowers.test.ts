import { expect, test, vi } from 'vitest';

import { memfsGlobbySync, mockFs } from './testing/index.js';

vi.mock('node:fs', async () => {
  const memfs = await import('memfs');
  return { default: memfs.fs, ...memfs.fs };
});

vi.mock('globby', () => ({
  globbySync: (patterns: string | string[], options?: Record<string, unknown>) =>
    memfsGlobbySync(patterns, options),
}));

import loadTowers from './loadTowers.js';
import Tower from './Tower.js';

const { mockRequire } = vi.hoisted(() => {
  const mockRequire = vi.fn();
  return { mockRequire };
});

vi.mock('module', async (importOriginal) => {
  const original = (await importOriginal()) as any;
  return {
    ...original,
    createRequire: () => mockRequire,
  };
});

vi.mock('find-up', () => ({
  findUpSync: vi.fn().mockReturnValue('/path/to/node_modules'),
}));
vi.mock('./Tower.js');

test('loads internal towers', () => {
  mockRequire.mockReturnValue({
    name: 'The Narrow Path',
    description: 'A corridor of stone where the only way out is forward',
    warrior: 'warrior',
    levels: ['level1', 'level2'],
  });
  mockFs({ '/path/to/node_modules/@warriorjs/cli': {} });
  loadTowers();
  mockFs.restore();
  expect(Tower).toHaveBeenCalledWith(
    'the-narrow-path',
    'The Narrow Path',
    'A corridor of stone where the only way out is forward',
    'warrior',
    ['level1', 'level2'],
  );
});

test('loads external official towers', () => {
  mockRequire.mockImplementation((path: string) => {
    if (path.includes('tower-foo')) {
      return {
        name: 'Foo',
        description: 'bar',
        warrior: 'warrior',
        levels: ['level1', 'level2'],
      };
    }
    return {
      name: 'The Narrow Path',
      description: 'A corridor of stone where the only way out is forward',
      warrior: 'warrior',
      levels: ['level1', 'level2'],
    };
  });
  mockFs({
    '/path/to/node_modules': {
      '@warriorjs': {
        cli: {},
        'tower-foo': {
          'package.json': '',
          'index.js':
            "module.exports = { name: 'Foo', description: 'bar', warrior: 'warrior, levels: ['level1', 'level2'] }",
        },
      },
    },
  });
  loadTowers();
  mockFs.restore();
  expect(Tower).toHaveBeenCalledWith('foo', 'Foo', 'bar', 'warrior', ['level1', 'level2']);
});

test('loads external community towers', () => {
  mockRequire.mockImplementation((path: string) => {
    if (path.includes('warriorjs-tower-foo')) {
      return {
        name: 'Foo',
        description: 'bar',
        warrior: 'warrior',
        levels: ['level1', 'level2'],
      };
    }
    return {
      name: 'The Narrow Path',
      description: 'A corridor of stone where the only way out is forward',
      warrior: 'warrior',
      levels: ['level1', 'level2'],
    };
  });
  mockFs({
    '/path/to/node_modules': {
      '@warriorjs': {
        cli: {},
      },
      'warriorjs-tower-foo': {
        'package.json': '',
        'index.js':
          "module.exports = { name: 'Foo', description: 'bar', warrior: 'warrior, levels: ['level1', 'level2'] }",
      },
    },
  });
  loadTowers();
  mockFs.restore();
  expect(Tower).toHaveBeenCalledWith('foo', 'Foo', 'bar', 'warrior', ['level1', 'level2']);
});

test("ignores directories that are seemingly towers but don't have a package.json", () => {
  mockRequire.mockReturnValue({
    name: 'The Narrow Path',
    description: 'A corridor of stone where the only way out is forward',
    warrior: 'warrior',
    levels: ['level1', 'level2'],
  });
  mockFs({
    '/path/to/node_modules': {
      '@warriorjs': {
        cli: {},
        'tower-foo': {
          'index.js':
            "module.exports = { name: 'Foo', description: 'baz', warrior: 'warrior, levels: ['level1', 'level2'] }",
        },
      },
      'warriorjs-tower-bar': {
        'index.js':
          "module.exports = { name: 'Bar', description: 'baz', warrior: 'warrior, levels: ['level1', 'level2'] }",
      },
    },
  });
  loadTowers();
  mockFs.restore();
  expect(Tower).not.toHaveBeenCalledWith('foo', 'Foo', 'baz', 'warrior', ['level1', 'level2']);
  expect(Tower).not.toHaveBeenCalledWith('bar', 'Bar', 'baz', 'warrior', ['level1', 'level2']);
});

test("doesn't throw when @warriorjs/cli doesn't exist", async () => {
  mockRequire.mockReturnValue({
    name: 'The Narrow Path',
    description: 'A corridor of stone where the only way out is forward',
    warrior: 'warrior',
    levels: ['level1', 'level2'],
  });
  const { findUpSync } = await import('find-up');
  (findUpSync as any).mockReturnValue(null);
  loadTowers();
});
