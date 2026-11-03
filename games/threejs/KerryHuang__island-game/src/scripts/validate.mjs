// 驗證 data/issues.json：node scripts/validate.mjs [data/issues.json]
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

export const MODELS = 'house hall booth classroom clinic busstop bikes court farm river stage book coin clock globe'.split(' ');
const STATUS = ['new', 'debating', 'progress', 'settled'];
const LEGACY = ['phase', 'desc', 'facts'];
const ID_RE = /^[a-z]{2}-\d{4}-\d{2}-[a-z0-9-]+$/;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const days = (a, b) => (Date.parse(b) - Date.parse(a)) / 864e5;
// 例行任務在台北早上跑，「今天」要用台北日期，不能用 UTC
export const taipeiToday = (d = new Date()) => new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Taipei' }).format(d);

export function validate(issues, { islandIds, today, blocked = [] }) {
  const errors = [], warnings = [], seen = new Set();
  let heat3 = 0;
  for (const isl of islandIds) if (!Array.isArray(issues[isl])) errors.push(`${isl}: missing island`);
  for (const key of Object.keys(issues)) if (!islandIds.includes(key)) errors.push(`${key}: unknown island`);

  for (const isl of islandIds) {
    const list = issues[isl];
    if (!Array.isArray(list)) continue;
    if (list.length < 3 || list.length > 8) errors.push(`${isl}: count ${list.length}（每島 3 到 8 則）`);
    for (const it of list) {
      const at = `${isl}/${it.id}`, err = (code, msg) => errors.push(`${at}: ${code} ${msg}`);
      if (typeof it.id !== 'string' || !ID_RE.test(it.id)) err('id', '格式應為 <島縮寫>-<YYYY-MM>-<slug>');
      else if (!it.id.startsWith(isl.slice(0, 2) + '-')) err('id', `前綴應為 ${isl.slice(0, 2)}`);
      else if (seen.has(it.id)) err('duplicate', 'id 重複');
      seen.add(it.id);
      for (const k of ['name', 'en', 'what', 'why']) if (typeof it[k] !== 'string' || !it[k].trim()) err('field', `缺少 ${k}`);
      for (const k of LEGACY) if (k in it) err('legacy', `舊欄位 ${k} 要移除`);
      if (!MODELS.includes(it.model)) err('model', `不支援 ${it.model}`);
      if (!STATUS.includes(it.status)) err('status', `不支援 ${it.status}`);
      if (!Number.isInteger(it.heat) || it.heat < 0 || it.heat > 3) err('heat', `應為 0 到 3 的整數，得到 ${it.heat}`);
      if (it.heat === 3) heat3++;
      if (typeof it.updated !== 'string' || !DATE_RE.test(it.updated)) err('updated', '日期格式應為 YYYY-MM-DD');
      else if (days(today, it.updated) > 0) err('updated', '晚於今天');

      const views = Array.isArray(it.views) ? it.views : [];
      if (views.length < 2 || views.length > 3) err('views', `應為 2 到 3 筆，得到 ${views.length}`);
      for (const v of views) {
        if (!v || typeof v.who !== 'string' || !v.who.trim() || typeof v.says !== 'string' || !v.says.trim()) err('views', '每筆要有 who 與 says');
        else if (blocked.some((n) => v.who.includes(n))) err('who', `「${v.who}」是人名，請改成角色`);
      }

      const srcs = Array.isArray(it.sources) ? it.sources : [];
      if (srcs.length < 1 || srcs.length > 3) err('sources', `應為 1 到 3 筆，得到 ${srcs.length}`);
      let fresh = false;
      for (const s of srcs) {
        if (!s || typeof s.url !== 'string' || !s.url.startsWith('https://')) err('https', `來源網址必須是 https：${s && s.url}`);
        if (!s || typeof s.title !== 'string' || !s.title.trim() || typeof s.outlet !== 'string' || !s.outlet.trim()) err('sources', '來源要有 title 與 outlet 字串');
        if (!s || !DATE_RE.test(s.date || '')) err('sources', '來源 date 格式應為 YYYY-MM-DD');
        else if (DATE_RE.test(it.updated || '')) { const d = days(s.date, it.updated); if (d >= 0 && d <= 14) fresh = true; }
      }
      if (srcs.length && !fresh) err('stale', '沒有在 updated 之前 14 天內的來源');
    }
  }
  if (heat3 > 6) errors.push(`all: heat3 ${heat3} 則（全城最多 6 則）`);
  return { errors, warnings };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const root = new URL('..', import.meta.url);
  const file = process.argv[2] || fileURLToPath(new URL('data/issues.json', root));
  const islandIds = [...readFileSync(new URL('parts/10-data.js', root), 'utf8').matchAll(/id: '(\w+)', no: '\d\d'/g)].map((m) => m[1]);
  const blocked = readFileSync(new URL('data/blocked-names.txt', root), 'utf8').split('\n').map((s) => s.trim()).filter((s) => s && !s.startsWith('#'));
  const issues = JSON.parse(readFileSync(file, 'utf8'));
  const { errors, warnings } = validate(issues, { islandIds, today: taipeiToday(), blocked });
  warnings.forEach((w) => console.warn('warn', w));
  if (errors.length) { errors.forEach((e) => console.error(e)); process.exit(1); }
  console.log(`ok ${Object.values(issues).flat().length} issues`);
}
