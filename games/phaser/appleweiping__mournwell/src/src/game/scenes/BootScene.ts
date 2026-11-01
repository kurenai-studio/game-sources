import Phaser from 'phaser';
import { ITEM_DEFINITIONS } from '@/game/data/items';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('BootScene');
  }

  create(): void {
    this.createActorTextures();
    this.createProjectileTextures();
    this.createWorldTextures();
    this.createRelicTextures();
    this.scene.start('MenuScene');
  }

  private createActorTextures(): void {
    const graphics = this.make.graphics({ x: 0, y: 0 });

    // Vey, the adult well-keeper: stitched mantle, bell-mask, and a live ember.
    graphics.fillStyle(0x08070a, 0.35).fillEllipse(32, 56, 38, 11);
    graphics
      .fillStyle(0x302b35)
      .lineStyle(3, 0x09080b)
      .fillTriangle(11, 58, 53, 58, 32, 22)
      .strokeTriangle(11, 58, 53, 58, 32, 22);
    graphics.fillStyle(0x524957).lineStyle(3, 0x09080b).fillCircle(32, 23, 17).strokeCircle(32, 23, 17);
    graphics.fillStyle(0xcbbf9d).fillEllipse(32, 24, 20, 23);
    graphics.lineStyle(2, 0x18141a).strokeEllipse(32, 24, 20, 23);
    graphics.fillStyle(0x141117).fillCircle(27, 23, 2.4).fillCircle(37, 23, 2.4);
    graphics.lineStyle(2, 0x675d66).lineBetween(27, 32, 37, 32);
    graphics.fillStyle(0xd78e54).fillCircle(32, 7, 3.2);
    graphics.lineStyle(1, 0xf1c077).strokeCircle(32, 7, 5.5);
    graphics.generateTexture('player', 64, 64);
    graphics.clear();

    // Siltling: low crawling ink-beast with an offset jaw.
    graphics.fillStyle(0x09080b, 0.3).fillEllipse(32, 50, 44, 10);
    graphics.lineStyle(4, 0x111015);
    for (let leg = 0; leg < 4; leg += 1) {
      const y = 25 + leg * 7;
      graphics.lineBetween(18, y, 5 + (leg % 2) * 4, y + 7);
      graphics.lineBetween(46, y, 59 - (leg % 2) * 4, y + 7);
    }
    graphics
      .fillStyle(0x536052)
      .lineStyle(3, 0x0b0a0d)
      .fillEllipse(32, 32, 34, 29)
      .strokeEllipse(32, 32, 34, 29);
    graphics.fillStyle(0x8e9c79).fillCircle(24, 28, 4).fillCircle(38, 27, 3);
    graphics.fillStyle(0x111015).fillCircle(24, 28, 1.8).fillCircle(38, 27, 1.4);
    graphics.lineStyle(3, 0x19131a).beginPath().moveTo(22, 40).lineTo(31, 44).lineTo(43, 39).strokePath();
    graphics.generateTexture('enemy-siltling', 64, 64);
    graphics.clear();

    // Wickspitter: wax bloom with a glowing, telegraphed mouth.
    graphics.fillStyle(0x08070a, 0.35).fillEllipse(32, 52, 38, 10);
    graphics.fillStyle(0x78675a).lineStyle(3, 0x0a090c).fillCircle(32, 32, 20).strokeCircle(32, 32, 20);
    graphics.fillStyle(0xa18a70).fillCircle(24, 25, 7).fillCircle(42, 28, 8).fillCircle(29, 41, 9);
    graphics.fillStyle(0x171319).fillCircle(26, 28, 3).fillCircle(39, 29, 2.4);
    graphics
      .fillStyle(0x4c2425)
      .lineStyle(2, 0x151116)
      .fillEllipse(34, 40, 15, 9)
      .strokeEllipse(34, 40, 15, 9);
    graphics.fillStyle(0xe4a460).fillTriangle(29, 12, 35, 12, 32, 2);
    graphics.lineStyle(2, 0xf2c078).strokeTriangle(29, 12, 35, 12, 32, 2);
    graphics.generateTexture('enemy-wickspitter', 64, 64);
    graphics.clear();

    // Knellguard: plated ram-mask, visibly front-heavy.
    graphics.fillStyle(0x09080b, 0.35).fillEllipse(32, 53, 42, 9);
    graphics
      .fillStyle(0x343642)
      .lineStyle(4, 0x09080b)
      .fillRoundedRect(13, 16, 38, 40, 10)
      .strokeRoundedRect(13, 16, 38, 40, 10);
    graphics
      .fillStyle(0xa3916d)
      .lineStyle(3, 0x141219)
      .fillTriangle(32, 8, 52, 32, 32, 46)
      .strokeTriangle(32, 8, 52, 32, 32, 46);
    graphics.fillStyle(0x645940).fillTriangle(32, 8, 12, 32, 32, 46);
    graphics.lineStyle(3, 0x141219).strokeTriangle(32, 8, 12, 32, 32, 46);
    graphics.fillStyle(0xd2bc86).fillCircle(32, 26, 4);
    graphics.fillStyle(0x17141a).fillCircle(32, 26, 1.8);
    graphics.lineStyle(3, 0x8f805f).lineBetween(12, 20, 4, 12).lineBetween(52, 20, 60, 12);
    graphics.generateTexture('enemy-knellguard', 64, 64);
    graphics.clear();

    // Ashmoth: a moth of soot with ember-edged wings (Depth II).
    graphics.fillStyle(0x09080b, 0.28).fillEllipse(32, 54, 30, 8);
    graphics
      .fillStyle(0x3a3134)
      .lineStyle(3, 0x0a090c)
      .fillTriangle(30, 30, 6, 14, 10, 44)
      .strokeTriangle(30, 30, 6, 14, 10, 44)
      .fillTriangle(34, 30, 58, 14, 54, 44)
      .strokeTriangle(34, 30, 58, 14, 54, 44);
    graphics.lineStyle(2, 0xd9733f, 0.85).lineBetween(8, 16, 12, 42).lineBetween(56, 16, 52, 42);
    graphics
      .fillStyle(0x59494c)
      .lineStyle(3, 0x0a090c)
      .fillEllipse(32, 32, 12, 24)
      .strokeEllipse(32, 32, 12, 24);
    graphics.fillStyle(0xf0b36a).fillCircle(29, 25, 2).fillCircle(35, 25, 2);
    graphics.lineStyle(2, 0x2a2224).lineBetween(30, 20, 25, 11).lineBetween(34, 20, 39, 11);
    graphics.generateTexture('enemy-ashmoth', 64, 64);
    graphics.clear();

    // Chimewraith: a hanging chime-tube with a drowned, hollow face (Depth II).
    graphics.fillStyle(0x09080b, 0.3).fillEllipse(32, 57, 30, 8);
    graphics.lineStyle(2, 0x5f7c7d).lineBetween(32, 2, 32, 9);
    graphics
      .fillStyle(0x3e5a5d)
      .lineStyle(3, 0x09080b)
      .fillRoundedRect(19, 9, 26, 40, 9)
      .strokeRoundedRect(19, 9, 26, 40, 9);
    graphics.fillStyle(0x7fa8a4).fillRoundedRect(23, 13, 6, 30, 3);
    graphics
      .fillStyle(0x0d1213)
      .fillEllipse(27, 26, 6, 9)
      .fillEllipse(37, 26, 6, 9)
      .fillEllipse(32, 39, 8, 5);
    graphics
      .fillStyle(0x2b3f41)
      .lineStyle(3, 0x09080b)
      .fillTriangle(17, 47, 47, 47, 32, 58)
      .strokeTriangle(17, 47, 47, 47, 32, 58);
    graphics.fillStyle(0xbfe3dc).fillCircle(32, 56, 2.5);
    graphics.generateTexture('enemy-chimewraith', 64, 64);
    graphics.clear();

    // The Tollmother: original bell-and-roots silhouette, no borrowed character geometry.
    graphics.fillStyle(0x09080b, 0.4).fillEllipse(48, 86, 74, 15);
    graphics
      .fillStyle(0x25212b)
      .lineStyle(5, 0x08070a)
      .fillTriangle(13, 84, 83, 84, 48, 18)
      .strokeTriangle(13, 84, 83, 84, 48, 18);
    graphics
      .fillStyle(0x8b7657)
      .lineStyle(4, 0x0e0c10)
      .fillEllipse(48, 34, 44, 49)
      .strokeEllipse(48, 34, 44, 49);
    graphics.lineStyle(3, 0x2c252b).lineBetween(35, 24, 61, 46).lineBetween(60, 22, 36, 47);
    graphics.fillStyle(0xb8524f).fillCircle(36, 35, 4).fillCircle(60, 35, 4);
    graphics.fillStyle(0x130f14).fillCircle(36, 35, 2).fillCircle(60, 35, 2);
    graphics.lineStyle(5, 0x121016).beginPath().moveTo(34, 55).lineTo(48, 61).lineTo(63, 54).strokePath();
    graphics.fillStyle(0xd79a5c).fillCircle(48, 10, 5);
    graphics.lineStyle(2, 0xf0c37d).strokeCircle(48, 10, 8);
    graphics.lineStyle(4, 0x4b3d42).lineBetween(18, 74, 5, 90).lineBetween(78, 74, 91, 90);
    graphics.generateTexture('boss-tollmother', 96, 96);
    graphics.destroy();
  }

  private createProjectileTextures(): void {
    const graphics = this.make.graphics({ x: 0, y: 0 });
    graphics.fillStyle(0x0a090c, 0.3).fillCircle(10, 11, 7);
    graphics.fillStyle(0xded3b4).fillCircle(9, 9, 6);
    graphics.fillStyle(0xf3e7c4).fillCircle(7, 6, 2.5);
    graphics.lineStyle(2, 0x342d35).strokeCircle(9, 9, 6);
    graphics.generateTexture('player-projectile', 20, 20);
    graphics.clear();

    graphics.fillStyle(0x0a090c, 0.3).fillCircle(10, 11, 7);
    graphics.fillStyle(0xa43c3f).fillCircle(9, 9, 6);
    graphics.fillStyle(0xe08a68).fillCircle(7, 6, 2);
    graphics.lineStyle(2, 0x32171d).strokeCircle(9, 9, 6);
    graphics.generateTexture('enemy-projectile', 20, 20);
    graphics.clear();

    graphics.fillStyle(0xd99355).fillCircle(4, 4, 3.5);
    graphics.generateTexture('ash-particle', 8, 8);
    graphics.clear();

    graphics.fillStyle(0xa7c1a0, 0.35).fillCircle(16, 16, 14);
    graphics.fillStyle(0x9cb79b).lineStyle(2, 0x18201a).fillCircle(16, 16, 8).strokeCircle(16, 16, 8);
    graphics.fillStyle(0xd9dfbd).fillRect(14, 9, 4, 14).fillRect(9, 14, 14, 4);
    graphics.generateTexture('oil-pickup', 32, 32);
    graphics.destroy();
  }

  private createWorldTextures(): void {
    const graphics = this.make.graphics({ x: 0, y: 0 });
    graphics.fillStyle(0xffffff).fillRect(0, 0, 8, 8);
    graphics.generateTexture('wall-block', 8, 8);
    graphics.clear();

    graphics.fillStyle(0x08070a, 0.45).fillEllipse(32, 24, 48, 13);
    graphics
      .fillStyle(0x494047)
      .lineStyle(3, 0x0b090d)
      .fillRoundedRect(7, 5, 50, 35, 6)
      .strokeRoundedRect(7, 5, 50, 35, 6);
    graphics.lineStyle(2, 0x8b7455).strokeRoundedRect(13, 10, 38, 24, 4);
    graphics.fillStyle(0xc59054).fillCircle(32, 22, 4);
    graphics.generateTexture('chest', 64, 48);
    graphics.clear();

    graphics.fillStyle(0x0a090c, 0.45).fillEllipse(32, 32, 56, 18);
    graphics.fillStyle(0x17131a).lineStyle(3, 0x51424a).fillCircle(32, 26, 20).strokeCircle(32, 26, 20);
    graphics.lineStyle(2, 0xd08f55).strokeCircle(32, 26, 12);
    graphics.lineStyle(2, 0x725260).lineBetween(22, 16, 42, 36).lineBetween(42, 16, 22, 36);
    graphics.generateTexture('floor-exit', 64, 64);
    graphics.clear();

    graphics.fillStyle(0x0a090c, 0.25).fillEllipse(32, 20, 50, 14);
    graphics.generateTexture('shadow', 64, 40);
    graphics.destroy();
  }

  private createRelicTextures(): void {
    const graphics = this.make.graphics({ x: 0, y: 0 });
    ITEM_DEFINITIONS.forEach((item, index) => {
      graphics.clear();
      graphics.fillStyle(0x08070a, 0.38).fillEllipse(24, 40, 38, 9);
      graphics.fillStyle(0x222027).lineStyle(3, 0x08070a).fillCircle(24, 23, 16).strokeCircle(24, 23, 16);
      graphics.fillStyle(item.color).fillCircle(24, 23, 9);
      graphics.lineStyle(2, 0xe3d7b6, 0.72);
      if (index % 4 === 0) graphics.strokeTriangle(24, 12, 34, 29, 14, 29);
      if (index % 4 === 1) graphics.strokeCircle(24, 23, 7);
      if (index % 4 === 2) graphics.strokeRect(17, 16, 14, 14);
      if (index % 4 === 3) graphics.lineBetween(15, 23, 33, 23).lineBetween(24, 14, 24, 32);
      graphics.generateTexture(`item-${item.id}`, 48, 48);
    });
    graphics.destroy();
  }
}
