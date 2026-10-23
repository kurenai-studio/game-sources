// 启动场景：加载全部素材 + 少量代码贴图（粒子、闪电形状）
// 单文件打包版（build-singlefile.js 生成）会注入 window.ABYSS_EMBED（JSON 数值 + 图片 base64），
// 此时所有资源走内嵌数据，不再发 HTTP 请求；平时开发则从 data/ 与 assets/ 目录加载。
const JSON_FILES = [
  ['balance', 'data/balance.json'],
  ['weapons', 'data/weapons.json'],
  ['enemies', 'data/enemies.json'],
  ['levels', 'data/levels.json'],
  ['shop', 'data/shop.json'],
  ['achievements', 'data/achievements.json'],
  ['characters', 'data/characters.json']
];

const IMAGE_FILES = [
  // 角色
  ['char-hero-idle', 'assets/sprites/char-hero-idle.png'],
  ['char-hero-walk-down-1', 'assets/sprites/char-hero-walk-down-1.png'],
  ['char-hero-walk-down-2', 'assets/sprites/char-hero-walk-down-2.png'],
  ['char-hero-walk-up-1', 'assets/sprites/char-hero-walk-up-1.png'],
  ['char-hero-walk-up-2', 'assets/sprites/char-hero-walk-up-2.png'],
  ['char-hero-walk-left-1', 'assets/sprites/char-hero-walk-left-1.png'],
  ['char-hero-walk-left-2', 'assets/sprites/char-hero-walk-left-2.png'],
  ['char-hero-walk-right-1', 'assets/sprites/char-hero-walk-right-1.png'],
  ['char-hero-walk-right-2', 'assets/sprites/char-hero-walk-right-2.png'],
  // 怪物
  ['enemy-bat-fly-1', 'assets/sprites/enemy-bat-fly-1.png'],
  ['enemy-bat-fly-2', 'assets/sprites/enemy-bat-fly-2.png'],
  ['enemy-zombie-walk-1', 'assets/sprites/enemy-zombie-walk-1.png'],
  ['enemy-zombie-walk-2', 'assets/sprites/enemy-zombie-walk-2.png'],
  ['enemy-skeleton-archer', 'assets/sprites/enemy-skeleton-archer.png'],
  ['enemy-ghost', 'assets/sprites/enemy-ghost.png'],
  ['enemy-boar', 'assets/sprites/enemy-boar.png'],
  ['enemy-troll-elite', 'assets/sprites/enemy-troll-elite.png'],
  ['enemy-reaper-boss', 'assets/sprites/enemy-reaper-boss.png'],
  // 掉落物
  ['item-gem-xp', 'assets/sprites/item-gem-xp.png'],
  ['item-gem-xp-2', 'assets/sprites/item-gem-xp-2.png'],
  ['item-gem-xp-3', 'assets/sprites/item-gem-xp-3.png'],
  ['item-coin', 'assets/sprites/item-coin.png'],
  ['item-chicken', 'assets/sprites/item-chicken.png'],
  // 特效
  ['fx-knife', 'assets/sprites/fx-knife.png'],
  ['fx-whip-slash', 'assets/sprites/fx-whip-slash.png'],
  ['fx-axe', 'assets/sprites/fx-axe.png'],
  ['fx-orb-protect', 'assets/sprites/fx-orb-protect.png'],
  ['fx-flame-ground', 'assets/sprites/fx-flame-ground.png'],
  ['fx-flame-ground-2', 'assets/sprites/fx-flame-ground-2.png'],
  // UI
  ['ui-chest', 'assets/sprites/ui-chest.png'],
  ['ui-portrait-hero', 'assets/sprites/ui-portrait-hero.png'],
  ['ui-title-logo', 'assets/sprites/ui-title-logo.png'],
  // 图标：其中 4 把新武器的图标暂由代码占位（见 ensureOptionalIcons），
  // 之后把同名 PNG 放进 assets/ui/ 即自动替换，无需改代码
  ['icon-weapon-wand', 'assets/ui/icon-weapon-wand.png'],
  ['icon-weapon-knife', 'assets/ui/icon-weapon-knife.png'],
  ['icon-weapon-whip', 'assets/ui/icon-weapon-whip.png'],
  ['icon-weapon-axe', 'assets/ui/icon-weapon-axe.png'],
  ['icon-weapon-orbit', 'assets/ui/icon-weapon-orbit.png'],
  ['icon-weapon-holywater', 'assets/ui/icon-weapon-holywater.png'],
  ['icon-weapon-lightning', 'assets/ui/icon-weapon-lightning.png'],
  ['icon-weapon-drain', 'assets/ui/icon-weapon-drain.png'],
  ['icon-weapon-boomerang', 'assets/ui/icon-weapon-boomerang.png'],
  ['icon-weapon-spore', 'assets/ui/icon-weapon-spore.png'],
  ['icon-weapon-laser', 'assets/ui/icon-weapon-laser.png'],
  ['icon-weapon-frost', 'assets/ui/icon-weapon-frost.png'],
  ['icon-passive-heart', 'assets/ui/icon-passive-heart.png'],
  ['icon-passive-boots', 'assets/ui/icon-passive-boots.png'],
  ['icon-passive-bracelet', 'assets/ui/icon-passive-bracelet.png'],
  ['icon-passive-hourglass', 'assets/ui/icon-passive-hourglass.png'],
  ['icon-passive-magnet', 'assets/ui/icon-passive-magnet.png'],
  ['icon-passive-coin', 'assets/ui/icon-passive-coin.png'],
  ['icon-passive-armor', 'assets/ui/icon-passive-armor.png'],
  ['icon-passive-ring', 'assets/ui/icon-passive-ring.png'],
  // 地形
  ['tile-ground-base', 'assets/tiles/tile-ground-base.png'],
  ['tile-ground-detail-1', 'assets/tiles/tile-ground-detail-1.png'],
  ['tile-ground-detail-2', 'assets/tiles/tile-ground-detail-2.png'],
  ['tile-ground-detail-3', 'assets/tiles/tile-ground-detail-3.png']
];

export default class BootScene extends Phaser.Scene {
  constructor() { super('BootScene'); }

  preload() {
    const embed = window.ABYSS_EMBED;
    if (embed) { // 单文件版：数值直接注入缓存（图片在 create 后用 addBase64 异步注入）
      for (const [key, obj] of Object.entries(embed.json)) this.cache.json.add(key, obj);
    } else {
      for (const [key, path] of JSON_FILES) this.load.json(key, path);
      for (const [key, path] of IMAGE_FILES) this.load.image(key, path);
      this.load.once('loaderror', file => console.warn('素材加载失败:', file.key, file.src));
    }
  }

  create() {
    this.makeTextures();
    if (window.ABYSS_EMBED) {
      this.embedImages(); // 纹理全部就绪后才创建走路动画并进入菜单（动画帧依赖贴图，顺序不能反）
    } else {
      this.ensureOptionalIcons(); // 为缺失的可选图标生成代码占位
      this.makeAnims();
      this.scene.start('MenuScene');
    }
  }

  // 可选图标占位：文件未提供时用代码画一个，游戏逻辑不受影响；
  // 之后把真图放进 assets/ui/ 同名文件即自动替换。
  ensureOptionalIcons() {
    const need = id => !this.textures.exists(id);
    if (need('icon-weapon-boomerang')) {
      const g = this.add.graphics();
      g.fillStyle(0x20222f); g.fillRect(0, 0, 48, 48);
      g.fillStyle(0xff8a3c);
      g.fillPoints([{ x: 10, y: 10 }, { x: 24, y: 24 }, { x: 38, y: 10 }, { x: 38, y: 18 }, { x: 24, y: 32 }, { x: 10, y: 18 }], true);
      g.generateTexture('icon-weapon-boomerang', 48, 48);
      g.clear(); g.destroy();
    }
    if (need('icon-weapon-spore')) {
      const g = this.add.graphics();
      g.fillStyle(0x20222f); g.fillRect(0, 0, 48, 48);
      g.fillStyle(0x7ec850); g.fillCircle(24, 26, 14);
      g.fillStyle(0x38b764); g.fillCircle(20, 22, 5); g.fillCircle(29, 29, 3);
      g.generateTexture('icon-weapon-spore', 48, 48);
      g.clear(); g.destroy();
    }
    if (need('icon-weapon-laser')) {
      const g = this.add.graphics();
      g.fillStyle(0x20222f); g.fillRect(0, 0, 48, 48);
      g.fillStyle(0xff4d4d); g.fillRect(4, 20, 40, 8);
      g.fillStyle(0xffffff); g.fillRect(10, 23, 28, 2);
      g.generateTexture('icon-weapon-laser', 48, 48);
      g.clear(); g.destroy();
    }
    if (need('icon-weapon-frost')) {
      const g = this.add.graphics();
      g.fillStyle(0x20222f); g.fillRect(0, 0, 48, 48);
      g.fillStyle(0x9bd7ff);
      g.fillRect(22, 8, 4, 32);
      g.save(); g.translateCanvas(24, 24); g.rotateCanvas(Math.PI / 3); g.fillRect(-2, -16, 4, 32); g.rotateCanvas(Math.PI / 3); g.fillRect(-2, -16, 4, 32); g.restore();
      g.generateTexture('icon-weapon-frost', 48, 48);
      g.clear(); g.destroy();
    }
  }

  // 单文件版：把 base64 图片逐一注入纹理管理器，全部就绪后创建动画并进入菜单。
  // 三重保险：ADD 事件计数 + 轮询实际纹理数 + 6 秒超时强放，任何一张图解码失败都不会卡死启动。
  embedImages() {
    const images = window.ABYSS_EMBED.images;
    const keys = Object.keys(images);
    let remaining = keys.length;
    let started = false;
    const go = () => {
      if (started || remaining > 0) return;
      started = true;
      this.ensureOptionalIcons(); // 构建时缺失的可选图标在此生成占位
      this.makeAnims(); // 关键：必须在贴图全部就绪之后创建动画，否则动画帧为空引用
      this.scene.start('MenuScene');
    };
    this.textures.on(Phaser.Textures.Events.ADD, tkey => {
      if (images[tkey]) { remaining--; go(); }
    });
    for (const key of keys) {
      if (this.textures.exists(key)) { remaining--; continue; }
      this.textures.addBase64(key, images[key]);
    }
    const poll = window.setInterval(() => {
      let have = 0;
      for (const key of keys) if (this.textures.exists(key)) have++;
      if (have >= keys.length) remaining = 0;
      go();
      if (started || have >= keys.length) window.clearInterval(poll);
    }, 250);
    window.setTimeout(() => { started = true; this.scene.start('MenuScene'); }, 6000); // 终极兜底
  }

  makeTextures() {
    const g = this.add.graphics();

    // 粒子（白色方块，染色靠 emitter tint）
    g.fillStyle(0xffffff); g.fillRect(0, 0, 4, 4);
    g.generateTexture('particle', 4, 4);
    g.clear();

    // 闪电形状（闪电武器落点特效，无对应素材）
    g.fillStyle(0xffcd75);
    g.fillPoints([
      { x: 7, y: 0 }, { x: 15, y: 0 }, { x: 9, y: 16 }, { x: 14, y: 16 },
      { x: 1, y: 42 }, { x: 6, y: 20 }, { x: 0, y: 20 }
    ], true);
    g.generateTexture('fx-lightning-zig', 16, 44);
    g.clear();

    // 新武器弹道占位（真图就绪后放 assets/sprites/ 同名文件替换）
    // 回旋镖：橙色 V 形
    g.fillStyle(0xff8a3c);
    g.fillPoints([{ x: 2, y: 2 }, { x: 8, y: 8 }, { x: 14, y: 2 }, { x: 14, y: 7 }, { x: 8, y: 13 }, { x: 2, y: 7 }], true);
    g.generateTexture('fx-boomerang', 16, 16);
    g.clear();

    // 毒孢子：绿色毒液球
    g.fillStyle(0x7ec850); g.fillCircle(7, 7, 6);
    g.fillStyle(0x38b764); g.fillCircle(5, 5, 2);
    g.generateTexture('fx-spore', 14, 14);
    g.clear();

    // 激光：红色光束长条
    g.fillStyle(0xff4d4d); g.fillRect(0, 0, 64, 8);
    g.fillStyle(0xffffff); g.fillRect(6, 3, 52, 2);
    g.generateTexture('fx-laser', 64, 8);
    g.clear();

    // 能量光球（远程怪与全模式远程攻击圆球，完美圆形，分层高光与光晕）
    const orbCanvas = 32, orbCenter = 16;
    g.fillStyle(0xffffff, 0.22);
    g.fillCircle(orbCenter, orbCenter, 14);
    g.fillStyle(0xffffff, 0.55);
    g.fillCircle(orbCenter, orbCenter, 10);
    g.fillStyle(0xffffff, 0.95);
    g.fillCircle(orbCenter, orbCenter, 7);
    g.fillStyle(0xffffff, 1.0);
    g.fillCircle(orbCenter - 2, orbCenter - 2, 3);
    g.generateTexture('fx-energy-orb', orbCanvas, orbCanvas);
    g.clear();

    // 木桶：可破坏场景物件
    g.fillStyle(0x8a5a2b); g.fillRect(6, 2, 20, 28);
    g.fillStyle(0x6b4420); g.fillRect(6, 2, 20, 4); g.fillRect(6, 26, 20, 4);
    g.fillStyle(0x4a3a20); g.fillRect(6, 10, 20, 3); g.fillRect(6, 19, 20, 3);
    g.fillStyle(0xa87740); g.fillRect(9, 6, 3, 20);
    g.generateTexture('enemy-barrel', 32, 32);
    g.clear();

    g.destroy();
  }

  makeAnims() {
    const dirs = ['down', 'up', 'left', 'right'];
    for (const dir of dirs) {
      this.anims.create({
        key: `hero-walk-${dir}`,
        frames: [
          { key: `char-hero-walk-${dir}-1` },
          { key: `char-hero-walk-${dir}-2` }
        ],
        frameRate: 7,
        repeat: -1
      });
    }
  }
}
