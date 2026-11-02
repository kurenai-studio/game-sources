// The printer: enclosure, Z rods, LED bar, gantry and print head. Shared by title and game.
import { CW, CH, C } from './theme.js';
import { COLS } from './levels.js';

export const PX = 330;          // printer centre x
export const BED_Y = 452;       // top of the build plate
export const GRID_X0 = PX - (COLS * CW) / 2;
export const rowY = (r) => BED_Y - (r + 1) * CH;     // top y of layer r
export const colX = (c) => GRID_X0 + c * CW;         // left x of column c
export const TIP_OFFSET = 70;   // head texture: nozzle tip y relative to head top

export function buildPrinter(scene) {
  const g = scene.add.graphics();
  const L = 150, R = 510, T = 64, B = 492;

  // enclosure glass
  g.fillStyle(0x0b1220, 0.85).fillRoundedRect(L, T, R - L, B - T, 14);
  g.fillGradientStyle(0x1a2a44, 0x1a2a44, 0x0a0f18, 0x0a0f18, 0.55).fillRoundedRect(L + 6, T + 6, R - L - 12, B - T - 12, 10);
  // frame
  g.lineStyle(6, C.frame, 1).strokeRoundedRect(L, T, R - L, B - T, 14);
  g.lineStyle(1, C.frameHi, 0.8).strokeRoundedRect(L + 3, T + 3, R - L - 6, B - T - 6, 12);
  // Z lead screws
  for (const x of [L + 26, R - 26]) {
    g.fillStyle(0x3a465c, 1).fillRect(x - 3, T + 20, 6, B - T - 40);
    g.lineStyle(1, 0x5d6b82, 0.6);
    for (let y = T + 24; y < B - 22; y += 6) g.lineBetween(x - 3, y, x + 3, y + 3);
  }
  // LED bar
  g.fillStyle(0xd9fbe6, 1).fillRoundedRect(L + 40, T + 12, R - L - 80, 4, 2);
  const led = scene.add.image(PX, T + 14, 'glow').setScale(7, 0.9).setTint(C.greenGlow).setAlpha(0.35).setBlendMode('ADD');
  // light cone from the LED bar
  const cone = scene.add.graphics();
  cone.fillGradientStyle(0x9dffc4, 0x9dffc4, 0x9dffc4, 0x9dffc4, 0.07, 0.07, 0, 0);
  cone.fillRect(L + 10, T + 16, R - L - 20, B - T - 60);
  // bed carriage + PEI plate
  g.fillStyle(0x1f2736, 1).fillRoundedRect(PX - 190, BED_Y + 10, 380, 14, 4);
  scene.add.image(PX, BED_Y + 6, 'pei').setDisplaySize(COLS * CW + 24, 12);
  // feet + brand plate
  g.fillStyle(C.frame, 1).fillRoundedRect(L + 20, B - 2, 40, 10, 3).fillRoundedRect(R - 60, B - 2, 40, 10, 3);

  // gantry (moves with the head in Z) and head (moves in X)
  const gantry = scene.add.container(0, 0);
  const rail = scene.add.graphics();
  rail.fillStyle(0x2e3a50, 1).fillRoundedRect(L + 14, -5, R - L - 28, 10, 4);
  rail.fillStyle(0x6a7891, 1).fillRect(L + 20, -3, R - L - 40, 2);
  gantry.add(rail);

  const head = scene.add.container(PX, 0);
  const nozzleGlow = scene.add.image(0, TIP_OFFSET - 4, 'glow').setScale(0.55).setTint(C.hot).setBlendMode('ADD').setAlpha(0.25);
  const body = scene.add.image(0, 0, 'head').setOrigin(0.5, 0);
  const fan = scene.add.image(0, 25, 'fan');
  head.add([nozzleGlow, body, fan]);
  scene.tweens.add({ targets: fan, angle: 360, duration: 380, repeat: -1 });

  // Put the nozzle tip at (x, y).
  const placeHead = (x, y) => {
    head.setPosition(x, y - TIP_OFFSET);
    gantry.setY(y - TIP_OFFSET + 18);
  };
  placeHead(PX, rowY(0));
  return { g, led, gantry, head, nozzleGlow, placeHead };
}
