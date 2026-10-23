// 关卡环境危害（由 levels.json 的 hazard 字段驱动，进化模式与无尽模式不启用）：
// lava —— 地面熔岩池，站进去周期掉血，可走位规避，池子会周期性重定位
// wisp —— 游荡幽魂，沿直线穿越场地，触碰扣血，不受伤害、不计击杀、不吃索敌
const KINDS = {
  lava: { name: '熔岩池', warn: '⚠ 本关地面有熔岩池，别站在火里打' },
  wisp: { name: '游荡幽魂', warn: '⚠ 本关有幽魂直线穿过场地，注意走位' }
};

export default class Hazards {
  constructor(scene) {
    this.scene = scene;
    this.kind = scene.levelConfig.hazard || null;
    this.enabled = !!this.kind && !!KINDS[this.kind] && !scene.isBrotato && !scene.levelConfig.endless;
    this.items = [];
    this.relocT = 0;
    const e = (scene.diffConfig && scene.diffConfig.enemy) || {};
    this.dmgMul = e.dmg || 1;
    this.spdMul = e.speed || 1;
    const b = scene.physics.world.bounds;
    this.w = b.width;
    this.h = b.height;
  }

  info() { return this.enabled ? KINDS[this.kind] : null; }

  spawnAtStart() {
    if (!this.enabled) return;
    if (this.kind === 'lava') for (let i = 0; i < 7; i++) this.addLava();
    else if (this.kind === 'wisp') for (let i = 0; i < 4; i++) this.addWisp();
  }

  nearPlayer(minD, maxD) {
    const p = this.scene.player;
    const a = Math.random() * Math.PI * 2;
    const r = minD + Math.random() * (maxD - minD);
    return {
      x: Math.min(this.w - 90, Math.max(90, p.x + Math.cos(a) * r)),
      y: Math.min(this.h - 90, Math.max(90, p.y + Math.sin(a) * r))
    };
  }

  addLava() {
    const pos = this.nearPlayer(150, 520);
    const r = 58 + Math.random() * 22;
    const img = this.scene.add.image(pos.x, pos.y, 'fx-flame-ground')
      .setDisplaySize(r * 2, r * 2).setDepth(2).setAlpha(0.92);
    this.items.push({ type: 'lava', img, x: pos.x, y: pos.y, r, ft: 0, tick: 0 });
  }

  addWisp() {
    const pos = this.nearPlayer(420, 700);
    const img = this.scene.add.image(pos.x, pos.y, 'enemy-ghost')
      .setScale(1.5).setAlpha(0.6).setTint(0xbfe9ff).setDepth(5);
    const a = Phaser.Math.Angle.Between(pos.x, pos.y, this.scene.player.x, this.scene.player.y)
      + Phaser.Math.Between(-30, 30) * Math.PI / 180;
    const sp = 100 * this.spdMul;
    this.items.push({ type: 'wisp', img, x: pos.x, y: pos.y, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, life: 26 });
  }

  update(dt) {
    if (!this.enabled || this.scene.gameOver) return;
    const p = this.scene.player;
    if (p.dead) return;

    for (let i = this.items.length - 1; i >= 0; i--) {
      const hz = this.items[i];
      if (hz.type === 'lava') {
        hz.ft += dt;
        if (hz.ft > 0.2) {
          hz.ft = 0;
          hz.img.setTexture(Math.random() < 0.5 ? 'fx-flame-ground' : 'fx-flame-ground-2');
        }
        hz.tick -= dt;
        if (hz.tick <= 0) {
          hz.tick = 0.5;
          if (Phaser.Math.Distance.Between(hz.x, hz.y, p.x, p.y) < hz.r) {
            p.hurt(Math.round(12 * this.dmgMul));
          }
        }
      } else {
        hz.x += hz.vx * dt;
        hz.y += hz.vy * dt;
        hz.img.setPosition(hz.x, hz.y);
        hz.life -= dt;
        const far = Phaser.Math.Distance.Between(hz.x, hz.y, p.x, p.y) > 900;
        const edge = hz.x < 40 || hz.y < 40 || hz.x > this.w - 40 || hz.y > this.h - 40;
        if (hz.life <= 0 || far || edge) {
          hz.img.destroy();
          this.items.splice(i, 1);
          this.addWisp();
          continue;
        }
        if (Phaser.Math.Distance.Between(hz.x, hz.y, p.x, p.y) < 36) {
          p.hurt(Math.round(14 * this.dmgMul));
        }
      }
    }

    // 熔岩池每 7 秒把离玩家最远的一池拉回玩家附近，避免"跑开之后 7 个池子全留在身后、危害形同消失"
    if (this.kind === 'lava') {
      this.relocT += dt;
      if (this.relocT >= 7) {
        this.relocT = 0;
        let far = null, fd = -1;
        for (const hz of this.items) {
          const d = Phaser.Math.Distance.Between(hz.x, hz.y, p.x, p.y);
          if (d > fd) { fd = d; far = hz; }
        }
        if (far && fd > 420) {
          const pos = this.nearPlayer(180, 460);
          far.x = pos.x; far.y = pos.y;
          far.img.setPosition(pos.x, pos.y);
        }
      }
    }
  }
}
