// Game-feel helpers for Phaser scenes.
import Phaser from 'phaser';

export function shake(scene, intensity = 0.006, dur = 120) {
  scene.cameras.main.shake(dur, intensity);
}

export function hitStop(scene, ms = 60) {
  scene.physics?.world && (scene.physics.world.isPaused = true);
  scene.time.delayedCall(ms, () => { scene.physics?.world && (scene.physics.world.isPaused = false); });
}

export function flash(scene, color = 0xffffff, dur = 80) {
  const c = Phaser.Display.Color.IntegerToColor(color);
  scene.cameras.main.flash(dur, c.red, c.green, c.blue);
}

export function squash(scene, target, sx = 1.3, sy = 0.7, dur = 90) {
  scene.tweens.add({ targets: target, scaleX: sx, scaleY: sy, duration: dur, yoyo: true, ease: 'Quad.easeOut' });
}

// Generates a 1-pixel-ish particle texture once and bursts particles
export function burst(scene, x, y, color = 0xffffff, count = 14, speed = 220) {
  if (!scene.textures.exists('px')) {
    const g = scene.make.graphics({ x: 0, y: 0, add: false });
    g.fillStyle(0xffffff).fillRect(0, 0, 4, 4);
    g.generateTexture('px', 4, 4);
    g.destroy();
  }
  const em = scene.add.particles(x, y, 'px', {
    speed: { min: speed * 0.3, max: speed },
    angle: { min: 0, max: 360 },
    lifespan: { min: 250, max: 600 },
    scale: { start: 1.6, end: 0 },
    tint: color,
    emitting: false,
  });
  em.explode(count);
  scene.time.delayedCall(800, () => em.destroy());
}

export function floatText(scene, x, y, text, color = '#ffffff') {
  const t = scene.add.text(x, y, text, { fontFamily: 'Poppins, Arial, sans-serif', fontStyle: '700', fontSize: '16px', color, stroke: '#000', strokeThickness: 4 }).setOrigin(0.5).setDepth(1000);
  scene.tweens.add({ targets: t, y: y - 40, alpha: 0, duration: 700, ease: 'Cubic.easeOut', onComplete: () => t.destroy() });
}
