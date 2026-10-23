// 局外进度持久化：金币、商店等级、成就（localStorage，带容错；内存缓存避免每帧读写）
const KEY = {
  gold: 'abyss-gold', shop: 'abyss-shop', cleared: 'abyss-cleared',
  clearedByDiff: 'abyss-cleared-diff',
  achv: 'abyss-achv', chars: 'abyss-chars', char: 'abyss-char',
  vol: 'abyss-vol', best: 'abyss-best', diff: 'abyss-diff', evoBest: 'abyss-evobest'
};

let _gold = null, _shop = null, _achv = null, _cleared = null, _clearedByDiff = null, _chars = null, _char = null;
let _best = null, _diff = null, _evoBest = null;

function lsGet(k) { try { return localStorage.getItem(k); } catch (e) { return null; } }
function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* file:// 等环境不可用时静默 */ } }
function lsDel(k) { try { localStorage.removeItem(k); } catch (e) { } }

function ensure() {
  if (_gold !== null) return;
  _gold = parseInt(lsGet(KEY.gold) || '0', 10) || 0;
  try { _shop = JSON.parse(lsGet(KEY.shop) || '{}'); } catch (e) { _shop = {}; }
  try { _achv = JSON.parse(lsGet(KEY.achv) || '{}'); } catch (e) { _achv = {}; }
  _cleared = parseInt(lsGet(KEY.cleared) || '0', 10) || 0;
  try { _clearedByDiff = JSON.parse(lsGet(KEY.clearedByDiff) || '{}'); } catch (e) { _clearedByDiff = {}; }
  if (typeof _clearedByDiff !== 'object' || _clearedByDiff === null) _clearedByDiff = {};
  if (_clearedByDiff[1] === undefined && _cleared > 0) _clearedByDiff[1] = _cleared;
  if (_clearedByDiff[1] === undefined) _clearedByDiff[1] = 0;
  if (_clearedByDiff[2] === undefined) _clearedByDiff[2] = 0;
  if (_clearedByDiff[3] === undefined) _clearedByDiff[3] = 0;

  try { _chars = JSON.parse(lsGet(KEY.chars) || '{}'); } catch (e) { _chars = {}; }
  _char = lsGet(KEY.char) || 'mage';
  try { _best = JSON.parse(lsGet(KEY.best) || '{}'); } catch (e) { _best = {}; }
  _diff = Math.max(1, Math.min(3, parseInt(lsGet(KEY.diff) || '1', 10) || 1));
  _evoBest = parseInt(lsGet(KEY.evoBest) || '0', 10) || 0;
}

export default {
  // 金币
  getGold() { ensure(); return _gold; },
  addGold(n) { ensure(); _gold += n; lsSet(KEY.gold, String(_gold)); return _gold; },
  spendGold(n) {
    ensure();
    if (_gold < n) return false;
    _gold -= n;
    lsSet(KEY.gold, String(_gold));
    return true;
  },
  // 商店永久强化等级
  getShopLevel(id) { ensure(); return _shop[id] || 0; },
  setShopLevel(id, lv) { ensure(); _shop[id] = lv; lsSet(KEY.shop, JSON.stringify(_shop)); },
  // 通关进度（不同难度独立：难度 1、2、3 各自记录从第 1 关开始的进度）
  getCleared(diff) {
    ensure();
    const d = diff || _diff || 1;
    return _clearedByDiff[d] || 0;
  },
  setCleared(n, diff) {
    ensure();
    const d = diff || _diff || 1;
    _clearedByDiff[d] = Math.max(_clearedByDiff[d] || 0, n);
    lsSet(KEY.clearedByDiff, JSON.stringify(_clearedByDiff));
    if (d === 1) {
      _cleared = Math.max(_cleared, _clearedByDiff[1]);
      lsSet(KEY.cleared, String(_cleared));
    }
  },
  // 成就
  isAchvUnlocked(id) { ensure(); return !!_achv[id]; },
  // 返回 true 表示首次解锁
  unlockAchievement(id) {
    ensure();
    if (_achv[id]) return false;
    _achv[id] = true;
    lsSet(KEY.achv, JSON.stringify(_achv));
    return true;
  },
  // 角色解锁与选择
  isCharUnlocked(id) { ensure(); return id === 'mage' || !!_chars[id]; },
  unlockCharacter(id) {
    ensure();
    if (_chars[id]) return false;
    _chars[id] = true;
    lsSet(KEY.chars, JSON.stringify(_chars));
    return true;
  },
  getCharacter() { ensure(); return _char || 'mage'; },
  setCharacter(id) { ensure(); _char = id; lsSet(KEY.char, id); },
  // 每关最佳纪录（按难度独立存储）：普通关记录通关用时（越小越好），无尽记录生存秒数（越大越好）
  getBest(id, diff) {
    ensure();
    const d = diff || _diff || 1;
    const k = `${id}_d${d}`;
    return _best[k] !== undefined ? _best[k] : (_best[id] || 0);
  },
  setBest(id, sec, higherBetter, diff) {
    ensure();
    const d = diff || _diff || 1;
    const k = `${id}_d${d}`;
    const cur = _best[k] || 0;
    if (higherBetter ? sec > cur : (cur === 0 || sec < cur)) {
      _best[k] = Math.round(sec);
      if (d === 1) _best[id] = Math.round(sec);
      lsSet(KEY.best, JSON.stringify(_best));
    }
  },
  // 关卡难度（1: 普通, 2: 困难, 3: 噩梦）
  getDifficulty() { ensure(); return _diff || 1; },
  setDifficulty(d) {
    ensure();
    _diff = Math.max(1, Math.min(3, parseInt(d, 10) || 1));
    lsSet(KEY.diff, String(_diff));
    return _diff;
  },
  // 进化模式最高到达波次
  getEvoBest() { ensure(); return _evoBest || 0; },
  setEvoBest(wave) {
    ensure();
    if (wave > (_evoBest || 0)) {
      _evoBest = wave;
      lsSet(KEY.evoBest, String(_evoBest));
    }
  },
  // 清空全部进度
  wipe() {
    _gold = 0; _shop = {}; _achv = {}; _cleared = 0; _clearedByDiff = { 1: 0, 2: 0, 3: 0 };
    _chars = {}; _char = 'mage'; _best = {}; _diff = 1; _evoBest = 0;
    for (const k of Object.values(KEY)) lsDel(k);
  }
};
