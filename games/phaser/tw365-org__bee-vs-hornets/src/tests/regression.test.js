import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

import { applyAreaDamage } from '../src/logic/areaDamage.js';
import { createOnceHitTracker } from '../src/logic/onceHitTracker.js';
import { shouldSummonMinions } from '../src/logic/minionCap.js';
import { getDifficulty } from '../src/logic/difficulty.js';
import { detonatePollen, buzzardStrike, isEnemyDamageEligible } from '../src/logic/abilities.js';

test('1. applyAreaDamage: 7 隻工蜂(HP 20) 核爆120 後，應 100% 全部被處理 (無漏殺)', () => {
  class MockGroup {
    constructor() {
      this.entries = [];
    }
    add(item) {
      this.entries.push(item);
    }
    delete(item) {
      const idx = this.entries.indexOf(item);
      if (idx > -1) this.entries.splice(idx, 1);
    }
  }

  const group = new MockGroup();
  for (let i = 0; i < 7; i++) {
    group.add({ id: i, hp: 20, active: true, state: 'FLYING' });
  }

  const processed = applyAreaDamage(
    group.entries,
    120,
    target => target.active,
    (target, dmg) => {
      target.hp -= dmg;
      if (target.hp <= 0) {
        target.active = false;
        group.delete(target);
      }
    }
  );

  assert.equal(processed, 7, '應處理全部 7 隻工蜂');
  assert.equal(group.entries.length, 0, '所有工蜂皆應被消滅，無遺漏殘留');
});

test('2. onceHitTracker: 單一目標第二次 tryHit 應回傳 false，不同目標互不影響', () => {
  const tracker = createOnceHitTracker();
  const enemyA = { name: 'Hornet-A' };
  const enemyB = { name: 'Hornet-B' };

  assert.equal(tracker.tryHit(enemyA), true, '第一下命中應為 true');
  assert.equal(tracker.tryHit(enemyA), false, '同一目標第二幀命中應為 false');
  assert.equal(tracker.tryHit(enemyB), true, '不同目標 B 第一下命中應為 true');
  assert.equal(tracker.tryHit(enemyB), false, '目標 B 重複判定應為 false');
});

test('3. shouldSummonMinions: 活躍護衛 <= 4 時允許召喚，5 以上禁止召喚', () => {
  assert.equal(shouldSummonMinions(0), true);
  assert.equal(shouldSummonMinions(4), true);
  assert.equal(shouldSummonMinions(5), false);
  assert.equal(shouldSummonMinions(6), false);
});

test('4. getDifficulty: 驗證難度數值公式與 Boss 波次判定', () => {
  const w1 = getDifficulty(1);
  assert.equal(w1.speedMultiplier, 1.0);
  assert.equal(w1.isBossWave, false);
  assert.equal(w1.turnAroundChance, 0);

  const w2 = getDifficulty(2);
  assert.equal(Math.round(w2.speedMultiplier * 100) / 100, 1.06);
  assert.equal(w2.isBossWave, false);

  const w3 = getDifficulty(3);
  assert.equal(Math.round(w3.speedMultiplier * 100) / 100, 1.12);
  assert.equal(w3.isBossWave, true, '第 3 波應為 Boss 戰');
  assert.equal(w3.turnAroundChance, 0.3, '第 3 波起解鎖回馬槍 (30%)');

  const w6 = getDifficulty(6);
  assert.equal(w6.isBossWave, true, '第 6 波應為 Boss 戰');
});

test('5. detonatePollen & ENTERING: Boss 收到 200，普通蜂收到 120，ENTERING 工蜂完全免疫 (T8, T11)', () => {
  const normalHornet = { name: 'normal', active: true, state: 'FLYING', isBoss: false, hp: 20 };
  const boss = { name: 'queen', active: true, state: 'FLYING', isBoss: true, hp: 850 };
  const enteringHornet = { name: 'entering', active: true, state: 'ENTERING', isBoss: false, hp: 20 };

  const targets = [normalHornet, boss, enteringHornet];
  const damagedMap = new Map();

  const count = detonatePollen(targets, {
    minionDamage: 120,
    bossDamage: 200,
    isBoss: t => t.isBoss,
    onDamaged: (t, dmg) => {
      damagedMap.set(t.name, dmg);
      t.hp -= dmg;
    }
  });

  assert.equal(count, 2, '只有正常工蜂與 Boss 被處理，ENTERING 目標應被略過');
  assert.equal(damagedMap.get('normal'), 120, '普通蜂應收到 120 傷害');
  assert.equal(damagedMap.get('queen'), 200, 'Boss 應收到 200 傷害');
  assert.equal(damagedMap.has('entering'), false, 'ENTERING 工蜂不得收到任何傷害');
  assert.equal(enteringHornet.hp, 20, 'ENTERING 工蜂 HP 應維持不變');
});

test('6. buzzardStrike & ENTERING: 蜂鷹掠過路徑傷害判定與 ENTERING 免疫 (T9, T11)', () => {
  const tracker = createOnceHitTracker();
  const hornetA = { name: 'A', x: 200, y: 200, active: true, state: 'FLYING', isBoss: false, hp: 100 };
  const enteringHornet = { name: 'E', x: 200, y: 200, active: true, state: 'ENTERING', isBoss: false, hp: 100 };
  const farHornet = { name: 'F', x: 400, y: 400, active: true, state: 'FLYING', isBoss: false, hp: 100 };

  const targets = [hornetA, enteringHornet, farHornet];
  const buzzardPos = { x: 210, y: 210 }; // 距離 A 與 E 約 14px (< 95)

  const hit1 = buzzardStrike(targets, buzzardPos, {
    tracker,
    range: 95,
    minionDamage: 150,
    bossDamage: 250,
    onDamaged: (t, dmg) => { t.hp -= dmg; }
  });

  assert.equal(hit1.length, 1, '只有在範圍內且非 ENTERING 的目標 A 被命中');
  assert.equal(hit1[0].name, 'A');
  assert.equal(hornetA.hp, -50, 'A 目標應受到 150 點傷害');
  assert.equal(enteringHornet.hp, 100, 'ENTERING 目標應完全免疫');

  // 第二幀同位置重複判定，A 不得再次受傷
  const hit2 = buzzardStrike(targets, buzzardPos, {
    tracker,
    range: 95,
    minionDamage: 150,
    onDamaged: (t, dmg) => { t.hp -= dmg; }
  });

  assert.equal(hit2.length, 0, '同一目標在同一次俯衝中第二幀不可被重複命中');
});

test('7. 靜態代碼守門 (Static Guardrail): GameScene.js 原始碼不得殘留內嵌 takeDamage 迴圈或蜂鷹裸 new Set() (T10)', () => {
  const gameScenePath = path.resolve('src/scenes/GameScene.js');
  const code = fs.readFileSync(gameScenePath, 'utf8');

  // 1. 斷言不含內嵌 getChildren().forEach(... takeDamage) 或 getChildren().slice().forEach(... takeDamage)
  const inlineDmgLoopRegex = /getChildren\(\)(?:\.slice\(\))?\.forEach\([^)]*takeDamage/s;
  assert.equal(
    inlineDmgLoopRegex.test(code),
    false,
    'GameScene.js 不得包含內嵌的 getChildren().forEach(... takeDamage) 迴圈，必須委託 abilities.js'
  );

  // 2. 斷言蜂鷹不得使用裸 new Set()
  const bareSetInBuzzardRegex = /summonHoneyBuzzard[\s\S]*?new Set\(\)/;
  assert.equal(
    bareSetInBuzzardRegex.test(code),
    false,
    'summonHoneyBuzzard 不得使用裸 new Set()，必須使用 createOnceHitTracker()'
  );
});
