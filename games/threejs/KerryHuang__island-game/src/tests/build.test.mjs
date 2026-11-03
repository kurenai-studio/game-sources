import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { taipeiToday } from '../scripts/validate.mjs';

const root = new URL('..', import.meta.url).pathname;
const real = JSON.parse(readFileSync(join(root, 'data/issues.json'), 'utf8'));
const withFixture = (mutate) => {
  const d = structuredClone(real); mutate(d.traffic[0]);
  const f = join(mkdtempSync(join(tmpdir(), 'isl-')), 'issues.json');
  writeFileSync(f, JSON.stringify(d));
  return spawnSync('sh', ['build.sh'], { cwd: root, env: { ...process.env, ISSUES_FILE: f }, encoding: 'utf8' });
};

test('台北時間 07:00 的今天是台北日期', () => {
  assert.equal(taipeiToday(new Date('2026-10-29T23:00:00Z')), '2026-10-30');
});

test('議題文字含 </script> 不會截斷頁面的 script', () => {
  const r = withFixture((it) => { it.what = '測試</script><b>x</b>'; });
  assert.equal(r.status, 0, r.stderr);
  const html = readFileSync(join(root, 'index.html'), 'utf8');
  assert.ok(!html.includes('測試</script>'));
  assert.ok(html.includes('測試<\\/script>'));
});

test('來源不是 https 時 build 失敗', () => {
  const r = withFixture((it) => { it.sources[0].url = 'javascript:alert(1)'; });
  assert.notEqual(r.status, 0);
});

test.after(() => execFileSync('sh', ['build.sh'], { cwd: root }));
