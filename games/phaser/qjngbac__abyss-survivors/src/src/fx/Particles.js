// 特效封装：击杀爆浆 + 拾取金光（占精致感的代码部分，与贴图无关）
export default class FX {
  constructor(scene) {
    this.blood = scene.add.particles(0, 0, 'particle', {
      speed: { min: 60, max: 170 },
      lifespan: 350,
      scale: { start: 1, end: 0 },
      tint: [0xb13e53, 0xef7d57],
      emitting: false
    }).setDepth(8);

    this.gold = scene.add.particles(0, 0, 'particle', {
      speed: { min: 40, max: 120 },
      lifespan: 400,
      scale: { start: 1, end: 0 },
      tint: 0xffcd75,
      emitting: false
    }).setDepth(8);

    this.spark = scene.add.particles(0, 0, 'particle', {
      speed: { min: 20, max: 70 },
      lifespan: 160,
      scale: { start: 0.7, end: 0 },
      tint: [0x70d6ff, 0xa5f3fc],
      emitting: false
    }).setDepth(8);
  }

  killBurst(x, y) { this.blood.explode(8, x, y); }
  pickupBurst(x, y) { this.gold.explode(5, x, y); }
  critBurst(x, y) { this.gold.explode(6, x, y); }
  dissipateBurst(x, y, tint = 0x70d6ff) {
    if (this.spark) {
      this.spark.setParticleTint(tint);
      this.spark.explode(3, x, y);
    }
  }
}
