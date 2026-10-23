import getData from '../data.js';

// 经验与等级。曲线从 balance.json 读取：base + level*linear，lateAt 级后放缓为 base + level*lateLinear。
export default class XPSystem {
  constructor(scene) {
    this.scene = scene;
    this.level = 1;
    this.xp = 0;
  }

  need() {
    const c = getData(this.scene, 'balance').xpCurve;
    const l = this.level;
    return c.base + (l < c.lateAt ? l * c.linear : l * c.lateLinear);
  }

  // 返回本次触发的升级次数
  add(n) {
    const mods = this.scene.levelConfig.mods || {};
    n = Math.round(n * (mods.xpMul || 1));
    this.xp += n;
    let ups = 0;
    while (this.xp >= this.need()) {
      this.xp -= this.need();
      this.level++;
      ups++;
    }
    return ups;
  }
}
