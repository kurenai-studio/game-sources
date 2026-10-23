import getData from '../data.js';

// 诅咒选项定义（强力但带代价，每局每种一次）
const CURSES = [
  { id: 'demon',     name: '恶魔契约', desc: '伤害 +80%，最大生命 -30%',     apply: p => { p.curseDmg = 1.8; p.hpMulCurse = 0.7; } },
  { id: 'frenzy',    name: '狂热',     desc: '冷却 -25%，受到伤害 +25%',     apply: p => { p.curseCd = 0.75; p.curseTaken = 1.25; } },
  { id: 'bloodpact', name: '血债血偿', desc: '伤害 +40%，每秒流失 1.5 生命', apply: p => { p.curseDmg = Math.max(p.curseDmg, 1.4); p.curseDrain = 1.5; } }
];

// 三选一升级正式规则：
// - 选项池 = 未持有武器（新获取）+ 已持有武器升级 + 未持有被动 + 已有被动升级
// - 武器/被动槽位各 6 格；满槽后不再出"新获取"项
// - 按权重无放回抽 3 张（不产生重复卡面），已持有武器升级与进化权重更高，鼓励聚焦构筑
// - 全部满级时兜底出烤鸡腿回血
export default class UpgradeSystem {
  constructor(scene) {
    this.scene = scene;
  }

  roll3() {
    const gs = this.scene;
    const defs = getData(gs, 'weapons');
    const opts = [];

    for (const [id, def] of Object.entries(defs)) {
      if (id === 'passives') continue;
      const cur = gs.weaponLevels[id] || 0;
      if (cur === 0) {
        if (gs.weapons.length < 6) {
          opts.push({ kind: 'weapon', id, name: def.name, desc: def.desc, icon: def.icon, isNew: true, level: 1, w: 2 });
        }
      } else if (cur < def.maxLevel) {
        opts.push({ kind: 'weapon', id, name: def.name, desc: `Lv ${cur} → ${cur + 1}`, icon: def.icon, isNew: false, level: cur + 1, w: 3.2 });
      }
    }

    // 进化选项：武器满级 + 持有对应被动 + 未进化
    for (const w of gs.weapons) {
      const def = defs[w.id];
      if (w.level >= def.maxLevel && def.evolve && !w.evolved) {
        if ((gs.player.passiveLevels[def.evolve.with] || 0) > 0) {
          opts.push({ kind: 'evolve', id: w.id, name: def.evolve.name,
                      desc: def.evolve.desc, icon: def.icon, isNew: true, level: 0, w: 6 });
        }
      }
    }

    for (const [id, def] of Object.entries(defs.passives)) {
      const cur = gs.player.passiveLevels[id] || 0;
      if (cur === 0) {
        if (gs.passiveCount < 6) {
          opts.push({ kind: 'passive', id, name: def.name, desc: def.desc, icon: def.icon, isNew: true, level: 1, w: 2 });
        }
      } else if (cur < def.maxLevel) {
        opts.push({ kind: 'passive', id, name: def.name, desc: `${def.desc}（Lv ${cur} → ${cur + 1}）`, icon: def.icon, isNew: false, level: cur + 1, w: 2.4 });
      }
    }

    if (!opts.length) {
      return [{ kind: 'heal', name: '烤鸡腿', desc: '回复 50 点生命', isNew: false, level: 0 }];
    }

    const pool = opts.slice();
    const picked = [];
    while (picked.length < 3 && pool.length) {
      let total = 0;
      for (const o of pool) total += (o.w || 1);
      let roll = Math.random() * total;
      let idx = pool.length - 1;
      for (let i = 0; i < pool.length; i++) {
        roll -= (pool[i].w || 1);
        if (roll <= 0) { idx = i; break; }
      }
      picked.push(pool[idx]);
      pool.splice(idx, 1);
    }
    const shuffled = Phaser.Utils.Array.Shuffle(picked);
    // 诅咒：中后期 30% 概率混入一张强力诅咒（每局每种一次）
    // 进化模式按波次解锁（第 6 波起），不再依赖"上次玩过的经典关卡 id"
    const curseUnlocked = gs.isBrotato ? (gs.brotoWave >= 6) : (gs.levelConfig.endless || gs.levelId >= 3);
    if (curseUnlocked) {
      const avail = CURSES.filter(c => !gs.cursesTaken[c.id]);
      if (Math.random() < 0.3 && avail.length && shuffled.length) {
        const def = Phaser.Utils.Array.GetRandom(avail);
        shuffled[Phaser.Math.Between(0, shuffled.length - 1)] = {
          kind: 'curse', id: def.id, name: def.name, desc: def.desc, icon: 'icon-weapon-lightning', isNew: false, level: 0
        };
      }
    }
    return shuffled;
  }

  apply(opt) {
    const gs = this.scene;
    const p = gs.player;

    if (opt.kind === 'evolve') {
      gs.evolveWeapon(opt.id);
    } else if (opt.kind === 'curse') {
      gs.takeCurse(opt.id);
    } else if (opt.kind === 'weapon') {
      if (opt.isNew) {
        gs.addWeapon(opt.id);
      } else {
        const targetLv = Math.max(1, parseInt(opt.level, 10) || ((gs.weaponLevels[opt.id] || 1) + 1));
        // 进化模式可能持有多把同名武器：升级"等级最高的那一把"，与卡面显示（weaponLevels 记录最高级）保持一致
        const list = gs.weapons.filter(w => w.id === opt.id);
        const w = list.length ? list.reduce((a, b) => (b.level > a.level ? b : a)) : null;
        if (w) {
          w.level = targetLv;
          gs.weaponLevels[opt.id] = w.level;
        } else {
          gs.weaponLevels[opt.id] = targetLv;
        }
      }
    } else if (opt.kind === 'passive') {
      p.passiveLevels[opt.id] = (p.passiveLevels[opt.id] || 0) + 1;
      if (opt.id === 'heart') p.heal(20); // maxHp 由 getter 自动 +20
    } else if (opt.kind === 'heal') {
      p.heal(50);
    }
  }
}
