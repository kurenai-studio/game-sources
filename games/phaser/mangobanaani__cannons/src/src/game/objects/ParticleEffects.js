export default class ParticleEffects {
  constructor(scene) {
    this.scene = scene;

    if (!scene.textures.exists('particle')) {
      const gfx = scene.make.graphics({ add: false });
      gfx.fillStyle(0xffffff);
      gfx.fillCircle(4, 4, 4);
      gfx.generateTexture('particle', 8, 8);
      gfx.destroy();
    }

    this.dirtEmitter = scene.add.particles(0, 0, 'particle', {
      speed: { min: 50, max: 200 },
      angle: { min: 220, max: 320 },
      scale: { start: 0.6, end: 0 },
      lifespan: { min: 400, max: 800 },
      gravityY: 300,
      tint: [0x8B6914, 0x6B4F12, 0x4a3610],
      emitting: false,
    });

    this.fireEmitter = scene.add.particles(0, 0, 'particle', {
      speed: { min: 30, max: 120 },
      angle: { min: 0, max: 360 },
      scale: { start: 0.8, end: 0 },
      lifespan: { min: 100, max: 300 },
      tint: [0xff6600, 0xff9900, 0xffcc00],
      blendMode: 'ADD',
      emitting: false,
    });

    this.smokeEmitter = scene.add.particles(0, 0, 'particle', {
      speed: { min: 10, max: 40 },
      angle: { min: 240, max: 300 },
      scale: { start: 0.5, end: 0 },
      lifespan: { min: 500, max: 1200 },
      tint: [0x888888, 0x666666, 0x444444],
      alpha: { start: 0.4, end: 0 },
      emitting: false,
    });
  }

  explode(x, y, intensity = 1) {
    this.dirtEmitter.emitParticleAt(x, y, Math.floor(30 * intensity));
    this.fireEmitter.emitParticleAt(x, y, Math.floor(15 * intensity));
    this.smokeEmitter.emitParticleAt(x, y, Math.floor(10 * intensity));
  }

  splash(x, y) {
    this.dirtEmitter.emitParticleAt(x, y, 10);
  }

  muzzleFlash(x, y) {
    this.fireEmitter.emitParticleAt(x, y, 5);
  }
}
