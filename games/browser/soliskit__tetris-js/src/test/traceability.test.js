// Requirements traceability: every requirement in REQUIREMENTS.md is
// verified by at least one test, and every test names the requirements it
// verifies, all of which must exist.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const requirementIds = [...fs.readFileSync(path.join(root, 'REQUIREMENTS.md'), 'utf8').matchAll(/^\| ([A-Z]{2,3}-\d+) \|/gm)].map(match => match[1]);

// Every test() call in the unit and browser test files, with its tags.
const tests = ['test', 'e2e'].flatMap(folder =>
  fs.readdirSync(path.join(root, folder))
    .filter(file => file.endsWith('.js'))
    .flatMap(file => fs.readFileSync(path.join(root, folder, file), 'utf8').split('\n')
      .filter(line => /^\s*test\(/.test(line))
      .map(line => ({ where: `${folder}/${file}`, line: line.trim(), tags: [...line.matchAll(/\[([A-Z]{2,3}-\d+)\]/g)].map(match => match[1]) }))));

test('requirements have unique IDs [QA-1]', () => {
  assert.ok(requirementIds.length >= 40);
  assert.equal(new Set(requirementIds).size, requirementIds.length);
});

test('every test names at least one requirement [QA-1]', () => {
  assert.ok(tests.length > 100);
  const untagged = tests.filter(t => t.tags.length === 0).map(t => `${t.where}: ${t.line}`);
  assert.deepEqual(untagged, []);
});

test('every requirement a test names exists [QA-1]', () => {
  const unknown = tests.flatMap(t => t.tags.filter(tag => !requirementIds.includes(tag)).map(tag => `${tag} in ${t.where}`));
  assert.deepEqual(unknown, []);
});

test('every requirement is verified by at least one test [QA-1]', () => {
  const tagged = new Set(tests.flatMap(t => t.tags));
  assert.deepEqual(requirementIds.filter(id => !tagged.has(id)), []);
});

test('npm test enforces 100% line, branch and function coverage of the game logic [QA-2]', () => {
  const script = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8')).scripts.test;
  for (const flag of ['--experimental-test-coverage', '--test-coverage-include="public/game/**"', '--test-coverage-lines=100', '--test-coverage-branches=100', '--test-coverage-functions=100']) {
    assert.ok(script.includes(flag), flag);
  }
});

test('npm run test:e2e enforces 100% browser coverage of the page script [QA-3]', () => {
  const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  assert.ok(pkg.scripts['test:e2e'].endsWith('&& node scripts/browser-coverage.js'));
  const script = fs.readFileSync(path.join(root, 'scripts/browser-coverage.js'), 'utf8');
  assert.match(script, /export const THRESHOLD = 100;/);
  assert.match(script, /\['lines', 'branches', 'functions'\]/);
});

test('the browser tests run in WebKit at iPhone size [QA-4]', () => {
  const config = fs.readFileSync(path.join(root, 'playwright.config.js'), 'utf8');
  assert.match(config, /browserName: 'webkit', viewport: \{ width: 430, height: 932 \}/);
  const workflow = fs.readFileSync(path.join(root, '.github/workflows/pages.yml'), 'utf8');
  assert.match(workflow, /playwright install --with-deps chromium webkit/);
  assert.match(workflow, /npm run test:e2e/);
});

test('the code the browser loads is type checked in strict mode, in CI [QA-5]', () => {
  const config = JSON.parse(fs.readFileSync(path.join(root, 'tsconfig.json'), 'utf8'));
  for (const option of ['checkJs', 'strict', 'noImplicitReturns', 'noUnusedLocals', 'exactOptionalPropertyTypes']) {
    assert.equal(config.compilerOptions[option], true, option);
  }
  assert.deepEqual(config.include, ['public/game/**/*.js', 'public/script.js']);
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root, 'tsconfig.sw.json'), 'utf8')).include, ['public/sw.js']);
  const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  assert.equal(pkg.scripts.typecheck, 'tsc -p tsconfig.json && tsc -p tsconfig.sw.json');
  assert.match(fs.readFileSync(path.join(root, '.github/workflows/pages.yml'), 'utf8'), /npm run typecheck/);
});

test('mutation testing must leave no mutant alive, and runs weekly and on pull requests in CI [QA-6]', () => {
  const config = JSON.parse(fs.readFileSync(path.join(root, 'stryker.config.json'), 'utf8'));
  assert.deepEqual(config.mutate, ['public/game/**/*.js']);
  assert.equal(config.thresholds.break, 100);
  assert.match(config.commandRunner.command, /^exec node --test --test-isolation=none /);
  const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  assert.equal(pkg.scripts['test:mutation'], 'stryker run');
  const workflow = fs.readFileSync(path.join(root, '.github/workflows/mutation.yml'), 'utf8');
  assert.match(workflow, /schedule:/);
  assert.match(workflow, /npm run test:mutation/);
  // Pull requests that change the game logic or its tests: the changed game
  // logic alone, or the full suite when the tests change.
  const pullRequests = fs.readFileSync(path.join(root, '.github/workflows/mutation-pr.yml'), 'utf8');
  assert.match(pullRequests, /pull_request:/);
  for (const changed of ["'public/game/**'", "'test/**'"]) assert.ok(pullRequests.includes(changed), changed);
  assert.match(pullRequests, /npx stryker run --mutate "\$engine"/, 'changed game logic is mutated');
  assert.match(pullRequests, /npm run test:mutation/, 'changed tests run the full suite');
  // Every unit test file that exercises the game logic takes part.
  for (const file of fs.readdirSync(path.join(root, 'test')).filter(name => name.endsWith('.test.js'))) {
    const source = fs.readFileSync(path.join(root, 'test', file), 'utf8');
    if (/^import .* from '\.\.\/public\/game\//m.test(source)) assert.ok(config.commandRunner.command.includes(`test/${file}`), file);
  }
});
