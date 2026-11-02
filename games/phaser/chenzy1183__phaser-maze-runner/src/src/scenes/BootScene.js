// 启动场景：用 Graphics 程序化生成所有贴图（无需外部图片素材）
class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  create() {
    const g = this.make.graphics({ x: 0, y: 0, add: false });

    // 玩家：带眼睛的小圆球
    g.fillStyle(0x0369a1, 1);
    g.fillCircle(32, 34, 27);
    g.fillStyle(COLORS.player, 1);
    g.fillCircle(32, 32, 26);
    g.fillStyle(0xbae6fd, 0.6);
    g.fillCircle(22, 20, 7);
    g.fillStyle(0xffffff, 1);
    g.fillCircle(26, 30, 7);
    g.fillCircle(42, 30, 7);
    g.fillStyle(0x0f172a, 1);
    g.fillCircle(28, 31, 3.5);
    g.fillCircle(44, 31, 3.5);
    g.generateTexture('player', 64, 64);
    g.clear();

    // 金币
    g.fillStyle(0xb45309, 1);
    g.fillCircle(32, 32, 24);
    g.fillStyle(COLORS.coin, 1);
    g.fillCircle(32, 32, 20);
    g.fillStyle(0xeab308, 1);
    g.fillRect(29, 20, 6, 24);
    g.fillStyle(0xfef9c3, 1);
    g.fillCircle(25, 25, 5);
    g.generateTexture('coin', 64, 64);
    g.clear();

    // 出口：绿色传送门
    g.fillStyle(0x14532d, 1);
    g.fillRoundedRect(4, 4, 56, 56, 12);
    g.fillStyle(COLORS.exit, 1);
    g.fillRoundedRect(9, 9, 46, 46, 10);
    g.fillStyle(0xdcfce7, 1);
    g.fillTriangle(25, 19, 25, 45, 46, 32);
    g.generateTexture('exit', 64, 64);
    g.clear();

    // 粒子
    g.fillStyle(0xffffff, 1);
    g.fillCircle(8, 8, 8);
    g.generateTexture('dot', 16, 16);

    g.destroy();
    this.scene.start('Menu');
  }
}
