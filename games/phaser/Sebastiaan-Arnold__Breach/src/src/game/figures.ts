import Phaser from 'phaser';

export interface FigureStyle {
  /** Shoulders / clothing. Keep to the colour code: red hostiles, yellow civilians. */
  body: number;
  /** Lighter centre of the torso. */
  chest: number;
  head: number;
  gun?: boolean;
  /** A long gun (shotgun or rifle) instead of a handgun. */
  longGun?: boolean;
  handsUp?: boolean;
  /** Kneeling with hands behind the back. */
  restrained?: boolean;
}

/** Draws a standing person seen from above, facing +x, at the origin of `g`. */
export function drawFigure(g: Phaser.GameObjects.Graphics, s: FigureStyle): void {
  g.fillStyle(0x000000, 0.3);
  g.fillEllipse(1.5, 2.5, 22, 30);
  if (s.gun) {
    g.lineStyle(4.5, darken(s.body, 0.75), 1);
    g.lineBetween(0, -8.5, 10, -1.5);
    g.lineBetween(0, 8.5, 7, 1.8);
    const len = s.longGun ? 20 : 12;
    g.fillStyle(0x3a4048, 1);
    g.fillRect(6, -1.8, len, 3.6);
    g.fillStyle(0x8b95a3, 1);
    g.fillRect(6, -1.8, len, 1);
    g.fillStyle(0xd6b08c, 1);
    g.fillCircle(10, -1.5, 2.2);
    g.fillCircle(7, 1.8, 2.2);
  } else if (s.handsUp) {
    g.fillStyle(0xd6b08c, 1);
    g.fillCircle(3, -12, 2.6);
    g.fillCircle(3, 12, 2.6);
  } else if (s.restrained) {
    g.fillStyle(0x2563eb, 1);
    g.fillRect(-9, -2, 3, 4);
  }
  g.fillStyle(s.body, 1);
  g.fillEllipse(0, 0, 15, 25);
  g.fillStyle(s.chest, 1);
  g.fillEllipse(1, 0, 10, 18);
  g.lineStyle(1, 0x000000, 0.5);
  g.strokeEllipse(0, 0, 15, 25);
  g.fillStyle(s.head, 1);
  g.fillCircle(1, 0, 5.8);
  g.fillStyle(0xffffff, 0.15);
  g.fillCircle(0, -1.6, 2.5);
}

/** Someone who is down: slumped on the floor. */
export function drawDowned(g: Phaser.GameObjects.Graphics, s: FigureStyle): void {
  g.fillStyle(darken(s.body, 0.7), 1);
  g.fillEllipse(-2, 0, 24, 15);
  g.fillStyle(s.head, 1);
  g.fillCircle(-14, 2, 5.5);
  g.fillStyle(darken(s.body, 0.6), 1);
  g.fillEllipse(8, -6, 10, 4);
  g.fillEllipse(9, 6, 12, 4);
}

function darken(color: number, f: number): number {
  const c = Phaser.Display.Color.IntegerToColor(color);
  return Phaser.Display.Color.GetColor(Math.round(c.red * f), Math.round(c.green * f), Math.round(c.blue * f));
}
