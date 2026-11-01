import Phaser from 'phaser';

/** Create an off-screen graphics context for texture generation. */
function gfx(scene: Phaser.Scene): Phaser.GameObjects.Graphics {
  const g = scene.add.graphics();
  g.setVisible(false);
  return g;
}

/**
 * Procedurally generate all game textures (pixel art) so we don't need PNGs.
 * Each function draws onto a Phaser Graphics object, then saves as a texture.
 */
export function generateTextures(scene: Phaser.Scene): void {
  // Player ships
  generateF35(scene);
  generateValkyrie(scene);
  generateTitan(scene);
  generateSpectre(scene);

  // Player bullets (one per ship)
  generateBulletF35(scene);
  generateBulletValkyrie(scene);
  generateBulletTitan(scene);
  generateBulletSpectre(scene);

  // Power-up
  generatePowerUpPickup(scene);
  generatePowerUpDisguise(scene);
  generateBulletPowerUp(scene);

  // Enemies & environment
  generateAlien(scene);
  generateAlienBullet(scene);
  generateBoss(scene);
  generateBossBullet(scene);
  generateObstacle(scene);
  generateStar(scene);
  generateExplosionFrame(scene);
}

/* ------------------------------------------------------------------ */
/*  F-35 — top-down stealth fighter silhouette, 32×32                 */
/* ------------------------------------------------------------------ */
function generateF35(scene: Phaser.Scene): void {
  const g = gfx(scene);
  const s = 2; // pixel scale

  // Fuselage (dark grey)
  g.fillStyle(0x708090);
  g.fillRect(14 * s, 2 * s, 4 * s, 26 * s);

  // Nose cone
  g.fillStyle(0x556677);
  g.fillRect(15 * s, 0, 2 * s, 3 * s);

  // Main swept wings
  g.fillStyle(0x607080);
  g.fillRect(6 * s, 12 * s, 20 * s, 3 * s);
  // wing taper left
  g.fillRect(4 * s, 13 * s, 4 * s, 2 * s);
  g.fillRect(2 * s, 14 * s, 3 * s, 1 * s);
  // wing taper right
  g.fillRect(24 * s, 13 * s, 4 * s, 2 * s);
  g.fillRect(27 * s, 14 * s, 3 * s, 1 * s);

  // Tail wings
  g.fillStyle(0x556070);
  g.fillRect(10 * s, 24 * s, 12 * s, 2 * s);
  g.fillRect(8 * s, 25 * s, 4 * s, 2 * s);
  g.fillRect(20 * s, 25 * s, 4 * s, 2 * s);

  // Engine glow
  g.fillStyle(0x44aaff);
  g.fillRect(14 * s, 27 * s, 4 * s, 2 * s);

  // Cockpit canopy
  g.fillStyle(0x99ccff);
  g.fillRect(15 * s, 5 * s, 2 * s, 3 * s);

  g.generateTexture('f35', 32 * s, 32 * s);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Valkyrie — sleek swept-wing interceptor, 32×32                    */
/* ------------------------------------------------------------------ */
function generateValkyrie(scene: Phaser.Scene): void {
  const g = gfx(scene);
  const s = 2;

  // Slim fuselage (light blue-grey)
  g.fillStyle(0x8899aa);
  g.fillRect(15 * s, 2 * s, 2 * s, 24 * s);

  // Nose — sharp point
  g.fillStyle(0x99aacc);
  g.fillRect(15 * s, 0, 2 * s, 3 * s);
  g.fillRect(15.5 * s, 0, 1 * s, 1 * s);

  // Swept-back delta wings
  g.fillStyle(0x7788aa);
  g.fillRect(8 * s, 14 * s, 16 * s, 2 * s);
  g.fillRect(5 * s, 15 * s, 6 * s, 2 * s);
  g.fillRect(21 * s, 15 * s, 6 * s, 2 * s);
  g.fillRect(3 * s, 16 * s, 4 * s, 1 * s);
  g.fillRect(25 * s, 16 * s, 4 * s, 1 * s);

  // Canards (small forward wings)
  g.fillStyle(0x8899bb);
  g.fillRect(11 * s, 7 * s, 10 * s, 1 * s);

  // Tail fins
  g.fillStyle(0x667799);
  g.fillRect(12 * s, 24 * s, 2 * s, 3 * s);
  g.fillRect(18 * s, 24 * s, 2 * s, 3 * s);

  // Twin engine glow (cyan)
  g.fillStyle(0x00eeff);
  g.fillRect(14 * s, 26 * s, 1 * s, 2 * s);
  g.fillRect(17 * s, 26 * s, 1 * s, 2 * s);

  // Cockpit
  g.fillStyle(0xbbddff);
  g.fillRect(15 * s, 5 * s, 2 * s, 2 * s);

  g.generateTexture('valkyrie', 32 * s, 32 * s);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Titan — heavy armoured gunship, 32×32                             */
/* ------------------------------------------------------------------ */
function generateTitan(scene: Phaser.Scene): void {
  const g = gfx(scene);
  const s = 2;

  // Wide, heavy fuselage (dark olive/grey)
  g.fillStyle(0x556655);
  g.fillRect(10 * s, 4 * s, 12 * s, 24 * s);

  // Reinforced armour plating
  g.fillStyle(0x4a5a4a);
  g.fillRect(11 * s, 6 * s, 10 * s, 20 * s);

  // Blunt nose
  g.fillStyle(0x667766);
  g.fillRect(12 * s, 2 * s, 8 * s, 4 * s);

  // Thick stubby wings
  g.fillStyle(0x505f50);
  g.fillRect(4 * s, 12 * s, 24 * s, 4 * s);
  g.fillRect(2 * s, 13 * s, 4 * s, 3 * s);
  g.fillRect(26 * s, 13 * s, 4 * s, 3 * s);

  // Wing-mounted cannons
  g.fillStyle(0x444444);
  g.fillRect(3 * s, 10 * s, 2 * s, 6 * s);
  g.fillRect(27 * s, 10 * s, 2 * s, 6 * s);
  // Cannon tips (orange glow)
  g.fillStyle(0xff8800);
  g.fillRect(3 * s, 10 * s, 2 * s, 1 * s);
  g.fillRect(27 * s, 10 * s, 2 * s, 1 * s);

  // Tail section
  g.fillStyle(0x4a5a4a);
  g.fillRect(8 * s, 25 * s, 16 * s, 3 * s);

  // Big engine glow (orange-red)
  g.fillStyle(0xff6600);
  g.fillRect(12 * s, 27 * s, 8 * s, 3 * s);
  g.fillStyle(0xffaa44);
  g.fillRect(14 * s, 28 * s, 4 * s, 2 * s);

  // Cockpit (small, armoured)
  g.fillStyle(0x99bb99);
  g.fillRect(14 * s, 5 * s, 4 * s, 2 * s);

  g.generateTexture('titan', 32 * s, 32 * s);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Spectre — angular stealth striker, 32×32                          */
/* ------------------------------------------------------------------ */
function generateSpectre(scene: Phaser.Scene): void {
  const g = gfx(scene);
  const s = 2;

  // Angular fuselage (very dark blue-grey)
  g.fillStyle(0x334455);
  g.fillRect(13 * s, 3 * s, 6 * s, 22 * s);

  // Faceted nose (stealth angles)
  g.fillStyle(0x3d4f60);
  g.fillRect(14 * s, 1 * s, 4 * s, 4 * s);
  g.fillRect(15 * s, 0, 2 * s, 2 * s);

  // Diamond wings (angular, bat-like)
  g.fillStyle(0x2d3d4d);
  g.fillRect(7 * s, 12 * s, 18 * s, 3 * s);
  g.fillRect(4 * s, 13 * s, 6 * s, 3 * s);
  g.fillRect(22 * s, 13 * s, 6 * s, 3 * s);
  g.fillRect(2 * s, 15 * s, 4 * s, 2 * s);
  g.fillRect(26 * s, 15 * s, 4 * s, 2 * s);

  // Serrated trailing edge
  g.fillStyle(0x253545);
  g.fillRect(3 * s, 17 * s, 2 * s, 1 * s);
  g.fillRect(27 * s, 17 * s, 2 * s, 1 * s);

  // V-tail
  g.fillStyle(0x2a3a4a);
  g.fillRect(11 * s, 23 * s, 3 * s, 4 * s);
  g.fillRect(18 * s, 23 * s, 3 * s, 4 * s);

  // Hidden engine glow (dim purple — stealth)
  g.fillStyle(0x8844cc);
  g.fillRect(14 * s, 25 * s, 4 * s, 2 * s);

  // Targeting sensor (cockpit — red tint)
  g.fillStyle(0xff4466);
  g.fillRect(15 * s, 5 * s, 2 * s, 2 * s);

  g.generateTexture('spectre', 32 * s, 32 * s);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  F-35 bullet — cyan horizontal projectile, 10×4                    */
/* ------------------------------------------------------------------ */
function generateBulletF35(scene: Phaser.Scene): void {
  const g = gfx(scene);
  g.fillStyle(0x44eeff);
  g.fillRect(0, 1, 10, 2);
  g.fillStyle(0xffffff);
  g.fillRect(7, 1, 3, 2);
  g.generateTexture('bullet_f35', 10, 4);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Valkyrie bullet — rapid cyan-white needle, 8×2                    */
/* ------------------------------------------------------------------ */
function generateBulletValkyrie(scene: Phaser.Scene): void {
  const g = gfx(scene);
  g.fillStyle(0x00ccff);
  g.fillRect(0, 0, 8, 2);
  g.fillStyle(0xaaeeff);
  g.fillRect(5, 0, 3, 2);
  g.generateTexture('bullet_valkyrie', 8, 2);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Titan bullet — heavy orange bolt, 14×6                            */
/* ------------------------------------------------------------------ */
function generateBulletTitan(scene: Phaser.Scene): void {
  const g = gfx(scene);
  g.fillStyle(0xff6600);
  g.fillRect(0, 1, 14, 4);
  g.fillStyle(0xffaa44);
  g.fillRect(2, 2, 10, 2);
  g.fillStyle(0xffdd88);
  g.fillRect(10, 2, 4, 2);
  g.generateTexture('bullet_titan', 14, 6);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Spectre bullet — long purple rail-shot, 16×3                      */
/* ------------------------------------------------------------------ */
function generateBulletSpectre(scene: Phaser.Scene): void {
  const g = gfx(scene);
  g.fillStyle(0x8844cc);
  g.fillRect(0, 0, 16, 3);
  g.fillStyle(0xbb66ff);
  g.fillRect(4, 0, 8, 3);
  g.fillStyle(0xeeccff);
  g.fillRect(12, 0, 4, 3);
  g.generateTexture('bullet_spectre', 16, 3);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Power-up pickup — small glowing UFO saucer, 24×16                 */
/* ------------------------------------------------------------------ */
function generatePowerUpPickup(scene: Phaser.Scene): void {
  const g = gfx(scene);

  // Small disc body (same palette as alien, but smaller)
  g.fillStyle(0x445566);
  g.fillRect(4, 4, 16, 6);

  // Wider rim
  g.fillStyle(0x556677);
  g.fillRect(2, 6, 20, 3);

  // Mini dome — bright green to signal "pick me up"
  g.fillStyle(0x66ffaa);
  g.fillRect(8, 2, 8, 3);
  g.fillStyle(0xaaffdd);
  g.fillRect(10, 1, 4, 2);

  // Pulsing underside glow (yellow-green to distinguish from enemies)
  g.fillStyle(0xaaff44);
  g.fillRect(6, 10, 3, 2);
  g.fillRect(10, 11, 4, 2);
  g.fillRect(15, 10, 3, 2);

  // Side prongs
  g.fillStyle(0x334455);
  g.fillRect(0, 7, 3, 2);
  g.fillRect(21, 7, 3, 2);

  g.generateTexture('powerup_pickup', 24, 14);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Power-up disguise — player-as-UFO, saucer with blue cockpit glow  */
/*  Similar to alien but with a bright blue dome + chevron marking     */
/*  so the player can tell it apart, 32×32 at 2× scale                */
/* ------------------------------------------------------------------ */
function generatePowerUpDisguise(scene: Phaser.Scene): void {
  const g = gfx(scene);
  const s = 2;

  // Main disc body (same alien palette)
  g.fillStyle(0x445566);
  g.fillRect(4 * s, 6 * s, 20 * s, 8 * s);

  // Wider middle rim
  g.fillStyle(0x556677);
  g.fillRect(2 * s, 8 * s, 24 * s, 4 * s);

  // Dome — bright BLUE instead of green to distinguish from enemies
  g.fillStyle(0x4488ff);
  g.fillRect(10 * s, 4 * s, 8 * s, 4 * s);
  g.fillStyle(0x66aaff);
  g.fillRect(12 * s, 3 * s, 4 * s, 2 * s);

  // Chevron marking on hull (player identifier — enemies don't have this)
  g.fillStyle(0x44eeff);
  g.fillRect(13 * s, 10 * s, 2 * s, 1 * s);
  g.fillRect(12 * s, 11 * s, 4 * s, 1 * s);
  g.fillRect(11 * s, 12 * s, 6 * s, 1 * s);

  // Glowing underside lights — blue instead of red
  g.fillStyle(0x4488ff);
  g.fillRect(6 * s, 13 * s, 2 * s, 1 * s);
  g.fillRect(12 * s, 14 * s, 4 * s, 1 * s);
  g.fillRect(20 * s, 13 * s, 2 * s, 1 * s);

  // Side prongs
  g.fillStyle(0x334455);
  g.fillRect(0, 9 * s, 3 * s, 2 * s);
  g.fillRect(25 * s, 9 * s, 3 * s, 2 * s);

  g.generateTexture('powerup_disguise', 28 * s, 18 * s);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Power-up bullet — bright green-white plasma bolt, 12×4            */
/* ------------------------------------------------------------------ */
function generateBulletPowerUp(scene: Phaser.Scene): void {
  const g = gfx(scene);
  g.fillStyle(0x44ff88);
  g.fillRect(0, 1, 12, 2);
  g.fillStyle(0xaaffcc);
  g.fillRect(4, 0, 6, 4);
  g.fillStyle(0xffffff);
  g.fillRect(8, 1, 4, 2);
  g.generateTexture('bullet_powerup', 12, 4);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Alien ship — Independence-Day-style saucer, 28×28                 */
/* ------------------------------------------------------------------ */
function generateAlien(scene: Phaser.Scene): void {
  const g = gfx(scene);
  const s = 2;

  // Main disc body
  g.fillStyle(0x445566);
  g.fillRect(4 * s, 6 * s, 20 * s, 8 * s);

  // Wider middle rim
  g.fillStyle(0x556677);
  g.fillRect(2 * s, 8 * s, 24 * s, 4 * s);

  // Dome on top
  g.fillStyle(0x66ddaa);
  g.fillRect(10 * s, 4 * s, 8 * s, 4 * s);
  g.fillStyle(0x88ffcc);
  g.fillRect(12 * s, 3 * s, 4 * s, 2 * s);

  // Glowing underside lights
  g.fillStyle(0xff4444);
  g.fillRect(6 * s, 13 * s, 2 * s, 1 * s);
  g.fillRect(12 * s, 14 * s, 4 * s, 1 * s);
  g.fillRect(20 * s, 13 * s, 2 * s, 1 * s);

  // Side prongs (Independence Day style arms)
  g.fillStyle(0x334455);
  g.fillRect(0, 9 * s, 3 * s, 2 * s);
  g.fillRect(25 * s, 9 * s, 3 * s, 2 * s);

  g.generateTexture('alien', 28 * s, 18 * s);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Alien bullet                                                      */
/* ------------------------------------------------------------------ */
function generateAlienBullet(scene: Phaser.Scene): void {
  const g = gfx(scene);
  g.fillStyle(0xff4466);
  g.fillRect(1, 0, 3, 8);
  g.fillStyle(0xff8888);
  g.fillRect(1, 6, 3, 2);
  g.generateTexture('bullet_alien', 5, 8);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Boss mothership — large imposing vessel, 120×80                   */
/* ------------------------------------------------------------------ */
function generateBoss(scene: Phaser.Scene): void {
  const g = gfx(scene);

  // Main hull — dark metallic
  g.fillStyle(0x333d47);
  g.fillRect(20, 20, 80, 45);

  // Wider middle section
  g.fillStyle(0x2a333d);
  g.fillRect(10, 30, 100, 25);

  // Extended wing pylons
  g.fillStyle(0x252e38);
  g.fillRect(0, 35, 15, 15);
  g.fillRect(105, 35, 15, 15);

  // Top superstructure / bridge
  g.fillStyle(0x445566);
  g.fillRect(40, 10, 40, 15);
  g.fillStyle(0x556b7a);
  g.fillRect(50, 5, 20, 8);

  // Dome / command centre glow
  g.fillStyle(0x66ffaa);
  g.fillRect(55, 6, 10, 5);

  // Undercarriage detail rows
  g.fillStyle(0x44556a);
  for (let x = 20; x < 100; x += 8) {
    g.fillRect(x, 60, 5, 3);
  }

  // Glowing weapon ports
  g.fillStyle(0xff3333);
  g.fillRect(25, 62, 4, 4);
  g.fillRect(55, 65, 6, 4);
  g.fillRect(91, 62, 4, 4);

  // Engine glow at rear
  g.fillStyle(0xaa44ff);
  g.fillRect(30, 66, 60, 5);
  g.fillStyle(0xcc66ff);
  g.fillRect(40, 68, 40, 4);

  // Panel line details
  g.fillStyle(0x1e262f);
  g.fillRect(20, 40, 80, 1);
  g.fillRect(60, 20, 1, 45);

  g.generateTexture('boss', 120, 80);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Boss bullet                                                       */
/* ------------------------------------------------------------------ */
function generateBossBullet(scene: Phaser.Scene): void {
  const g = gfx(scene);
  g.fillStyle(0xff2266);
  g.fillRect(0, 0, 6, 12);
  g.fillStyle(0xff6699);
  g.fillRect(1, 9, 4, 3);
  g.generateTexture('bullet_boss', 6, 12);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Obstacle — asteroid-style jagged rock                             */
/* ------------------------------------------------------------------ */
function generateObstacle(scene: Phaser.Scene): void {
  const g = gfx(scene);
  const size = 32;

  // Base rock shape
  g.fillStyle(0x665544);
  g.fillRect(6, 2, 20, 28);
  g.fillRect(2, 6, 28, 20);
  g.fillRect(4, 4, 24, 24);

  // Shading
  g.fillStyle(0x554433);
  g.fillRect(8, 4, 8, 10);
  g.fillRect(18, 14, 8, 8);

  // Highlight spots
  g.fillStyle(0x887766);
  g.fillRect(12, 12, 4, 4);
  g.fillRect(6, 20, 3, 3);

  g.generateTexture('obstacle', size, size);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Background star                                                   */
/* ------------------------------------------------------------------ */
function generateStar(scene: Phaser.Scene): void {
  const g = gfx(scene);
  g.fillStyle(0xffffff);
  g.fillRect(0, 0, 2, 2);
  g.generateTexture('star', 2, 2);
  g.destroy();
}

/* ------------------------------------------------------------------ */
/*  Simple explosion frame (single orange/yellow burst)               */
/* ------------------------------------------------------------------ */
function generateExplosionFrame(scene: Phaser.Scene): void {
  const g = gfx(scene);
  const cx = 16, cy = 16;

  g.fillStyle(0xff6600);
  g.fillRect(cx - 10, cy - 10, 20, 20);
  g.fillStyle(0xffaa00);
  g.fillRect(cx - 6, cy - 6, 12, 12);
  g.fillStyle(0xffff44);
  g.fillRect(cx - 3, cy - 3, 6, 6);
  g.fillStyle(0xffffff);
  g.fillRect(cx - 1, cy - 1, 2, 2);

  g.generateTexture('explosion', 32, 32);
  g.destroy();
}
