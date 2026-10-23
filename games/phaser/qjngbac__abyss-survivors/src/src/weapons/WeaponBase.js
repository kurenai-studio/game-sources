// 武器基类：冷却计时 + 等级数值取自 weapons.json（按等级-1 索引）。
// 子类实现 fire()：返回 true 表示本次确实开火（冷却才会重新计时）。
// 持续型武器（护体环/毒孢子/吸血指环）不实现 fire，改为实现 updateExtra(dt) 每帧逻辑。
// 进化：def.evolve 定义进化所需被动与进化名；evolved 后伤害按 evoDmg 放大，行为变化由子类实现。
export default class WeaponBase {
  constructor(scene, id, def, level = 1) {
    this.scene = scene;
    this.id = id;
    this.def = def;
    this.level = Math.max(1, parseInt(level, 10) || 1);
    this.timer = 0;
    this.evolved = false;
  }

  // 获取该武器当前激活的羁绊增益（3 件 / 6 件同名武器）
  get synergy() {
    return (this.scene && this.scene.getSynergyBonus) ? this.scene.getSynergyBonus(this.id) : {};
  }

  // 按当前等级取数值表（安全容错，严防 undefined 或 NaN）
  stat(key) {
    const arr = this.def[key];
    if (!Array.isArray(arr) || arr.length === 0) return 0;
    const lv = Math.max(1, parseInt(this.level, 10) || 1);
    const max = this.def.maxLevel || arr.length;
    const idx = Math.max(0, Math.min(lv, max) - 1);
    return arr[idx] !== undefined ? arr[idx] : arr[0];
  }

  get cooldown() {
    if (!this.def.cooldown) return Infinity;
    const synCd = this.synergy.cdMul || 1;
    return this.stat('cooldown') * this.scene.player.cooldownMult * (this.scene.fireRate || 1) * synCd;
  }

  get damage() {
    const evo = this.evolved ? (this.def.evoDmg || 1.5) : 1;
    const synDmg = this.synergy.dmgMul || 1;
    return Math.round(this.stat('damage') * evo * this.scene.player.damageMult * synDmg);
  }

  get area() {
    return (this.scene && this.scene.player && this.scene.player.attackArea) ? this.scene.player.attackArea : 1.0;
  }

  get aimCap() {
    return (this.scene && this.scene.aimDist) ? this.scene.aimDist : 380;
  }

  fire() { return false; }

  update(dt) {
    if (this.updateExtra) this.updateExtra(dt);
    this.timer -= dt;
    if (this.timer <= 0 && this.fire()) {
      this.timer = this.cooldown;
    }
  }

  destroy() {
    // 供子类清理自建的持久 Sprites / Graphics
  }
}
