import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validate } from '../scripts/validate.mjs';

const ISLANDS = ['traffic', 'care', 'edu', 'elder', 'sport', 'green', 'culture', 'youth', 'digital', 'safety', 'eco', 'tour'];
const OPTS = { islandIds: ISLANDS, today: '2026-10-30', blocked: ['王小明'] };

const issue = (isl, n, over = {}) => ({
  id: `${isl.slice(0, 2)}-2026-10-item${n}`, name: '議題', en: 'Issue', model: 'house', status: 'debating', heat: 1,
  what: '發生什麼。', why: '為什麼有關。',
  views: [{ who: '家長團體', says: '支持。' }, { who: '市府', says: '評估中。' }],
  sources: [{ title: '報導', outlet: '某報', url: 'https://example.com/a', date: '2026-10-25' }],
  updated: '2026-10-30', ...over,
});
const good = () => Object.fromEntries(ISLANDS.map((i) => [i, [1, 2, 3].map((n) => issue(i, n))]));
const errs = (data) => validate(data, OPTS).errors.join('\n');

test('合法資料沒有錯誤', () => assert.equal(validate(good(), OPTS).errors.length, 0));

test('島數不對', () => {
  const d = good(); delete d.tour;
  assert.match(errs(d), /missing island/);
});

test('每島 3 到 8 則', () => {
  const d = good(); d.care = d.care.slice(0, 2);
  assert.match(errs(d), /care.*count/);
  const e = good(); e.care = [1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => issue('care', n));
  assert.match(errs(e), /care.*count/);
});

test('status 列舉', () => {
  const d = good(); d.edu[0].status = 'done';
  assert.match(errs(d), /status/);
});

test('heat 範圍', () => {
  for (const h of [4, -1, 1.5]) {
    const d = good(); d.edu[0].heat = h;
    assert.match(errs(d), /heat/, `heat ${h}`);
  }
});

test('heat 3 超過 6 則', () => {
  const d = good();
  ISLANDS.slice(0, 7).forEach((i) => { d[i][0].heat = 3; });
  assert.match(errs(d), /heat3/);
  const ok = good();
  ISLANDS.slice(0, 6).forEach((i) => { ok[i][0].heat = 3; });
  assert.doesNotMatch(errs(ok), /heat3/);
});

test('views 數量', () => {
  const d = good(); d.edu[0].views = d.edu[0].views.slice(0, 1);
  assert.match(errs(d), /views/);
  const e = good(); e.edu[0].views = [1, 2, 3, 4].map(() => ({ who: '學者', says: '…' }));
  assert.match(errs(e), /views/);
});

test('who 是黑名單人名', () => {
  const d = good(); d.edu[0].views[0].who = '王小明';
  assert.match(errs(d), /who/);
});

test('sources 數量與 https', () => {
  const d = good(); d.edu[0].sources = [];
  assert.match(errs(d), /sources/);
  const e = good(); e.edu[0].sources[0].url = 'http://example.com/a';
  assert.match(errs(e), /https/);
});

test('來源太舊', () => {
  const d = good(); d.edu[0].sources[0].date = '2026-10-10';
  assert.match(errs(d), /stale/);
});

test('id 格式與重複', () => {
  const d = good(); d.edu[0].id = 'tr1';
  assert.match(errs(d), /\bid\b/);
  const e = good(); e.edu[1].id = e.edu[0].id;
  assert.match(errs(e), /duplicate/);
});

test('model 不在 15 種', () => {
  const d = good(); d.edu[0].model = 'rocket';
  assert.match(errs(d), /model/);
});

test('含舊欄位 facts', () => {
  const d = good(); d.edu[0].facts = ['x'];
  assert.match(errs(d), /legacy/);
});

test('id 前綴要是該島縮寫', () => {
  const d = good(); d.care[0].id = 'tr-2026-10-item1';
  assert.match(errs(d), /care\/tr-2026-10-item1: id/);
});

test('來源 title 與 outlet 要是字串', () => {
  const d = good(); d.edu[0].sources[0].title = 123;
  assert.match(errs(d), /edu.*sources.*title/);
});
