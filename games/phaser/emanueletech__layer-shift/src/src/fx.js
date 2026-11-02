// Extra visual effects shared by the scenes.
import Phaser from 'phaser';
import { W, H, C, txt, hex } from './theme.js';
import { isMuted, setMuted, resumeAudio } from './sfx.js';

const webgl = (scene) => scene.sys.game.renderer.type === Phaser.WEBGL;

// Slow dust motes drifting in the printer light.
export function dust(scene, x, y, w, h) {
  return scene.add.particles(0, 0, 'glow', {
    x: { min: x, max: x + w }, y: { min: y, max: y + h },
    speedX: { min: -6, max: 6 }, speedY: { min: -10, max: 3 },
    scale: { min: 0.03, max: 0.09 }, alpha: { start: 0, end: 0, ease: (t) => Math.sin(t * Math.PI) * 0.45 },
    lifespan: { min: 4000, max: 8000 }, frequency: 180, blendMode: 'ADD', tint: 0xbfffd8,
  }).setDepth(-1);
}

// Soft vignette + gentle bloom-like glow on the camera (WebGL only; canvas just skips it).
export function cameraLook(scene) {
  if (!webgl(scene)) return;
  scene.cameras.main.postFX.addVignette(0.5, 0.5, 0.88, 0.32);
}

// Short pixelate "glitch" on errors.
export function glitch(scene, strength = 6) {
  if (!webgl(scene)) return;
  const fx = scene.cameras.main.postFX.addPixelate(-1);
  scene.tweens.addCounter({
    from: strength, to: -1, duration: 260, ease: 'Quad.easeOut',
    onUpdate: (tw) => { fx.amount = Math.round(tw.getValue()); },
    onComplete: () => scene.cameras.main.postFX.remove(fx),
  });
}

// A bar of light sweeping across a printed row.
export function lightSweep(scene, x, y, w, h, color = C.greenGlow) {
  const bar = scene.add.image(x, y + h / 2, 'glow').setDisplaySize(40, h * 3.2).setTint(color).setBlendMode('ADD').setAlpha(0.9);
  scene.tweens.add({ targets: bar, x: x + w, duration: 260, ease: 'Sine.easeInOut', onComplete: () => bar.destroy() });
}

// Freshly extruded plastic glows hot, then cools down to its colour.
export function hotCell(scene, img) {
  const hot = scene.add.image(img.x, img.y, img.texture.key).setOrigin(0).setTintFill(0xffd9a0).setBlendMode('ADD').setAlpha(0.85);
  scene.tweens.add({ targets: hot, alpha: 0, duration: 650, ease: 'Quad.easeIn', onComplete: () => hot.destroy() });
}

// Afterimage left behind when a layer is shifted.
export function afterimage(scene, container) {
  container.list.forEach((img) => {
    const ghost = scene.add.image(img.x + container.x, img.y, img.texture.key).setOrigin(0).setAlpha(0.35).setTint(0x9dffc4);
    scene.tweens.add({ targets: ghost, alpha: 0, duration: 180, onComplete: () => ghost.destroy() });
  });
}

// Confetti in filament colours.
export function confetti(scene, x, y) {
  const colors = [C.green, C.greenGlow, C.amber, 0x5ab8ff, 0xff6fae, 0xffffff];
  return scene.add.particles(x, y, 'spark', {
    speed: { min: 180, max: 420 }, angle: { min: 220, max: 320 }, gravityY: 520,
    scale: { start: 1.3, end: 0.5 }, rotate: { min: 0, max: 360 }, lifespan: 1800,
    tint: colors, quantity: 70, emitting: false,
  }).explode(70);
}

// Sound toggle (button top-right + M key), remembered in this browser.
export function muteToggle(scene) {
  const label = () => (isMuted() ? 'SOUND OFF  ·  M' : 'SOUND ON  ·  M');
  const t = txt(scene, W - 16, 16, label(), 10, C.muted, { ox: 1, weight: '500', spacing: 1 }).setInteractive({ useHandCursor: true }).setDepth(50);
  const toggle = () => { resumeAudio(); setMuted(!isMuted()); t.setText(label()); };
  t.on('pointerdown', (p, lx, ly, e) => { e?.stopPropagation(); toggle(); });
  scene.input.keyboard.on('keydown-M', toggle);
  return t;
}

export { hex, H };
