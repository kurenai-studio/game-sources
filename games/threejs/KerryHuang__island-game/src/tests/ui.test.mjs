import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { MODELS } from '../scripts/validate.mjs';

const src = (f) => readFileSync(new URL(`../parts/${f}`, import.meta.url), 'utf8');
// 從 parts/50-ui.js 抽出純函式，在 node 裡單獨執行
const ui = src('50-ui.js').split('\n').filter((l) => /^const (STATUS|esc|statusLabel|heatDots) =/.test(l)).join('\n');
const { statusLabel, heatDots } = new Function('tr', `${ui}\nreturn { statusLabel, heatDots };`)((zh) => zh);

test('未知 status 會被跳脫', () => assert.equal(statusLabel('<b>x</b>'), '&lt;b&gt;x&lt;/b&gt;'));

test('heat 超出 0 到 3 不會丟錯', () => {
  assert.doesNotThrow(() => heatDots(5));
  assert.doesNotThrow(() => heatDots(-1));
  assert.match(heatDots(5), /●●●</);
});

test('每種模型至少在一個時段會亮', () => {
  const lit = [...src('10-data.js').matchAll(/lit: \[([^\]]*)\]/g)].flatMap((m) => m[1].match(/\w+/g) || []);
  assert.deepEqual(MODELS.filter((m) => !lit.includes(m)), []);
});
