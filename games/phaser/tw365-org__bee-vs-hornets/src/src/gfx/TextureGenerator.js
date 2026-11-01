/**
 * 程式化像素紋理生成器 (Procedural Pixel Art Generator)
 * 於記憶體中使用原生 Canvas 繪製點陣紋理，並注入 Phaser 3 TextureManager
 * 保證零外連依賴、零 404 斷圖、絕對像素對齊
 */
export class TextureGenerator {
  static generateAll(scene) {
    this.createPlayerTextures(scene);
    this.createHornetTextures(scene);
    this.createArmoredHornetTextures(scene);
    this.createQueenTextures(scene);
    this.createBulletTextures(scene);
    this.createParticleTextures(scene);
    this.createBuzzardTextures(scene);
  }

  // 輔助繪製像素方塊
  static drawPixel(ctx, x, y, color, size = 2) {
    ctx.fillStyle = color;
    ctx.fillRect(x * size, y * size, size, size);
  }

  // 1. 玩家小蜜蜂 (雙影格拍翅動畫)
  static createPlayerTextures(scene) {
    [1, 2].forEach(frame => {
      const canvas = document.createElement('canvas');
      canvas.width = 32;
      canvas.height = 32;
      const ctx = canvas.getContext('2d');
      const s = 2; // 16x16 網格放大

      // 身體 (金黃色底)
      const bodyPixels = [
        [7, 4], [8, 4],
        [6, 5], [7, 5], [8, 5], [9, 5],
        [6, 6], [7, 6], [8, 6], [9, 6],
        [6, 7], [7, 7], [8, 7], [9, 7],
        [6, 8], [7, 8], [8, 8], [9, 8],
        [7, 9], [8, 9],
        [7, 10], [8, 10], // 尾針
        [7, 11], [8, 11]
      ];
      bodyPixels.forEach(([x, y]) => this.drawPixel(ctx, x, y, '#ffcc00', s));

      // 黑色條紋
      const blackStripes = [
        [6, 6], [7, 6], [8, 6], [9, 6],
        [6, 8], [7, 8], [8, 8], [9, 8],
        [7, 11], [8, 11] // 尖針
      ];
      blackStripes.forEach(([x, y]) => this.drawPixel(ctx, x, y, '#222222', s));

      // 眼睛 (大萌眼)
      this.drawPixel(ctx, 6, 4, '#00ffff', s);
      this.drawPixel(ctx, 9, 4, '#00ffff', s);

      // 觸角
      this.drawPixel(ctx, 5, 2, '#ffffff', s);
      this.drawPixel(ctx, 6, 3, '#ffffff', s);
      this.drawPixel(ctx, 10, 2, '#ffffff', s);
      this.drawPixel(ctx, 9, 3, '#ffffff', s);

      // 翅膀 (半透明天藍色)
      const wingColor = 'rgba(120, 220, 255, 0.85)';
      if (frame === 1) {
        // 翅膀展開
        [[3, 4], [4, 4], [5, 4], [2, 5], [3, 5], [4, 5], [5, 5],
         [10, 4], [11, 4], [12, 4], [10, 5], [11, 5], [12, 5], [13, 5]
        ].forEach(([x, y]) => this.drawPixel(ctx, x, y, wingColor, s));
      } else {
        // 翅膀收縮
        [[4, 5], [5, 5], [3, 6], [4, 6], [5, 6],
         [10, 5], [11, 5], [10, 6], [11, 6], [12, 6]
        ].forEach(([x, y]) => this.drawPixel(ctx, x, y, wingColor, s));
      }

      scene.textures.addCanvas(`player_bee_${frame}`, canvas);
    });
  }

  // 2. 普通虎頭蜂 (兇猛紅眼、毒針)
  static createHornetTextures(scene) {
    const canvas = document.createElement('canvas');
    canvas.width = 32;
    canvas.height = 32;
    const ctx = canvas.getContext('2d');
    const s = 2;

    // 橙紅危險體色
    const body = [
      [7, 3], [8, 3],
      [6, 4], [7, 4], [8, 4], [9, 4],
      [6, 5], [7, 5], [8, 5], [9, 5],
      [5, 6], [6, 6], [7, 6], [8, 6], [9, 6], [10, 6],
      [6, 7], [7, 7], [8, 7], [9, 7],
      [7, 8], [8, 8],
      [7, 9], [8, 9] // 毒針
    ];
    body.forEach(([x, y]) => this.drawPixel(ctx, x, y, '#ff5500', s));

    // 黑色劇毒環節
    const stripes = [
      [6, 5], [7, 5], [8, 5], [9, 5],
      [6, 7], [7, 7], [8, 7], [9, 7],
      [7, 9], [8, 9]
    ];
    stripes.forEach(([x, y]) => this.drawPixel(ctx, x, y, '#1a0500', s));

    // 兇暴赤紅複眼
    this.drawPixel(ctx, 6, 3, '#ff0033', s);
    this.drawPixel(ctx, 9, 3, '#ff0033', s);

    // 翅膀 (薄紫色)
    [[3, 5], [4, 5], [2, 6], [3, 6], [4, 6],
     [11, 5], [12, 5], [11, 6], [12, 6], [13, 6]
    ].forEach(([x, y]) => this.drawPixel(ctx, x, y, 'rgba(230, 180, 255, 0.75)', s));

    scene.textures.addCanvas('hornet_normal', canvas);
  }

  // 3. 裝甲虎頭蜂 (重裝甲紫黑硬殼)
  static createArmoredHornetTextures(scene) {
    const canvas = document.createElement('canvas');
    canvas.width = 40;
    canvas.height = 40;
    const ctx = canvas.getContext('2d');
    const s = 2;

    // 厚重甲殼
    for (let x = 6; x <= 13; x++) {
      for (let y = 5; y <= 13; y++) {
        this.drawPixel(ctx, x, y, '#5a189a', s);
      }
    }
    // 外骨骼防護條紋
    for (let x = 7; x <= 12; x++) {
      this.drawPixel(ctx, x, 7, '#ffaa00', s);
      this.drawPixel(ctx, x, 10, '#ffaa00', s);
    }
    // 毒刺與巨顎
    this.drawPixel(ctx, 9, 14, '#ff0055', s);
    this.drawPixel(ctx, 10, 14, '#ff0055', s);
    this.drawPixel(ctx, 8, 4, '#ff0055', s);
    this.drawPixel(ctx, 11, 4, '#ff0055', s);

    scene.textures.addCanvas('hornet_armored', canvas);
  }

  // 4. 虎頭蜂女王 Boss (超巨型 48x48)
  static createQueenTextures(scene) {
    const canvas = document.createElement('canvas');
    canvas.width = 64;
    canvas.height = 64;
    const ctx = canvas.getContext('2d');
    const s = 2;

    // 女王軀幹
    for (let x = 11; x <= 20; x++) {
      for (let y = 8; y <= 22; y++) {
        this.drawPixel(ctx, x, y, '#800f2f', s);
      }
    }
    // 金色皇冠
    [[14, 5], [15, 6], [16, 5], [17, 6], [18, 5]].forEach(([x, y]) => {
      this.drawPixel(ctx, x, y, '#ffd700', s);
    });
    // 蜂皇金紋
    for (let x = 12; x <= 19; x++) {
      this.drawPixel(ctx, x, 11, '#ffb703', s);
      this.drawPixel(ctx, x, 15, '#ffb703', s);
      this.drawPixel(ctx, x, 19, '#ffb703', s);
    }
    // 巨大毒刺雙角
    this.drawPixel(ctx, 15, 23, '#ff0054', s);
    this.drawPixel(ctx, 16, 23, '#ff0054', s);
    this.drawPixel(ctx, 15, 24, '#ff0054', s);
    this.drawPixel(ctx, 16, 24, '#ff0054', s);

    // 女王四翼
    const wingColor = 'rgba(255, 100, 200, 0.7)';
    for (let w = 4; w <= 10; w++) {
      this.drawPixel(ctx, w, 10, wingColor, s);
      this.drawPixel(ctx, w, 14, wingColor, s);
      this.drawPixel(ctx, 31 - w, 10, wingColor, s);
      this.drawPixel(ctx, 31 - w, 14, wingColor, s);
    }

    scene.textures.addCanvas('hornet_queen', canvas);
  }

  // 5. 各階重武器子彈
  static createBulletTextures(scene) {
    // Lv0: 雙發尖針
    let cv = document.createElement('canvas');
    cv.width = 6;
    cv.height = 14;
    let ctx = cv.getContext('2d');
    ctx.fillStyle = '#00ffff';
    ctx.fillRect(1, 0, 4, 14);
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(2, 2, 2, 8);
    scene.textures.addCanvas('bullet_needle', cv);

    // Lv1: 散彈蜂針 (金黃菱形)
    cv = document.createElement('canvas');
    cv.width = 10;
    cv.height = 12;
    ctx = cv.getContext('2d');
    ctx.fillStyle = '#ffdd00';
    ctx.beginPath();
    ctx.moveTo(5, 0);
    ctx.lineTo(10, 6);
    ctx.lineTo(5, 12);
    ctx.lineTo(0, 6);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(4, 4, 2, 4);
    scene.textures.addCanvas('bullet_spread', cv);

    // Lv2: 追蹤微導彈
    cv = document.createElement('canvas');
    cv.width = 10;
    cv.height = 18;
    ctx = cv.getContext('2d');
    ctx.fillStyle = '#33ff55';
    ctx.fillRect(2, 2, 6, 12);
    ctx.fillStyle = '#ff0055'; // 彈頭
    ctx.fillRect(3, 0, 4, 3);
    ctx.fillStyle = '#ffaa00'; // 推進火箭火花
    ctx.fillRect(3, 14, 4, 4);
    scene.textures.addCanvas('bullet_missile', cv);

    // Lv3: 等離子轟爆砲 (超大 24x24 能量球)
    cv = document.createElement('canvas');
    cv.width = 24;
    cv.height = 24;
    ctx = cv.getContext('2d');
    let grad = ctx.createRadialGradient(12, 12, 2, 12, 12, 11);
    grad.addColorStop(0, '#ffffff');
    grad.addColorStop(0.4, '#ff00ff');
    grad.addColorStop(0.9, '#8800ff');
    grad.addColorStop(1, 'transparent');
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(12, 12, 11, 0, Math.PI * 2);
    ctx.fill();
    scene.textures.addCanvas('bullet_plasma', cv);

    // 敵方毒針彈
    cv = document.createElement('canvas');
    cv.width = 8;
    cv.height = 12;
    ctx = cv.getContext('2d');
    ctx.fillStyle = '#ff2200';
    ctx.fillRect(2, 0, 4, 12);
    ctx.fillStyle = '#ffff00';
    ctx.fillRect(3, 3, 2, 6);
    scene.textures.addCanvas('bullet_enemy', cv);
  }

  // 6. 粒子效果
  static createParticleTextures(scene) {
    // 爆炸火花
    let cv = document.createElement('canvas');
    cv.width = 6;
    cv.height = 6;
    let ctx = cv.getContext('2d');
    ctx.fillStyle = '#ffaa00';
    ctx.fillRect(0, 0, 6, 6);
    scene.textures.addCanvas('particle_spark', cv);

    // 花粉核爆粒子 (金粉)
    cv = document.createElement('canvas');
    cv.width = 8;
    cv.height = 8;
    ctx = cv.getContext('2d');
    let grad = ctx.createRadialGradient(4, 4, 1, 4, 4, 4);
    grad.addColorStop(0, '#ffffff');
    grad.addColorStop(0.6, '#ffd700');
    grad.addColorStop(1, 'transparent');
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(4, 4, 4, 0, Math.PI * 2);
    ctx.fill();
    scene.textures.addCanvas('particle_pollen', cv);
  }

  // 7. 彩蛋實體：東方蜂鷹 (Oriental Honey Buzzard - 虎頭蜂天敵)
  static createBuzzardTextures(scene) {
    const canvas = document.createElement('canvas');
    canvas.width = 80;
    canvas.height = 64;
    const ctx = canvas.getContext('2d');
    const s = 2; // 40x32 網格放大

    // 蜂鷹軀體 (棕褐、栗色羽毛)
    for (let x = 16; x <= 23; x++) {
      for (let y = 10; y <= 26; y++) {
        this.drawPixel(ctx, x, y, '#582f0e', s);
      }
    }

    // 腹部條紋羽毛 (淡褐與白斑)
    for (let x = 17; x <= 22; x++) {
      this.drawPixel(ctx, x, 14, '#ddb892', s);
      this.drawPixel(ctx, x, 18, '#ddb892', s);
      this.drawPixel(ctx, x, 22, '#ddb892', s);
    }

    // 鷹頭與銳利黃喙
    for (let x = 17; x <= 22; x++) {
      for (let y = 5; y <= 9; y++) {
        this.drawPixel(ctx, x, y, '#7f4f24', s);
      }
    }
    // 金黃銳喙
    this.drawPixel(ctx, 19, 3, '#ffcc00', s);
    this.drawPixel(ctx, 20, 3, '#ffcc00', s);
    this.drawPixel(ctx, 19, 4, '#e67e22', s);
    this.drawPixel(ctx, 20, 4, '#e67e22', s);

    // 鷹眼 (金黃底 + 黑瞳)
    this.drawPixel(ctx, 18, 6, '#ffd700', s);
    this.drawPixel(ctx, 21, 6, '#ffd700', s);
    this.drawPixel(ctx, 18, 7, '#000000', s);
    this.drawPixel(ctx, 21, 7, '#000000', s);

    // 雄偉巨翼 (展開達 80px，深棕與漸層飛羽)
    for (let y = 10; y <= 22; y++) {
      const wingSpan = Math.floor((22 - y) * 1.5) + 6;
      for (let w = 0; w <= wingSpan; w++) {
        const c = (w % 2 === 0) ? '#6f4e37' : '#936639';
        this.drawPixel(ctx, 16 - w, y, c, s);
        this.drawPixel(ctx, 23 + w, y, c, s);
      }
    }

    // 尾羽
    for (let x = 17; x <= 22; x++) {
      for (let y = 27; y <= 30; y++) {
        this.drawPixel(ctx, x, y, '#3d2314', s);
      }
    }

    scene.textures.addCanvas('easter_honey_buzzard', canvas);

    // 特級蜂露 (救援掉落物，綠金光澤結晶)
    const dewCanvas = document.createElement('canvas');
    dewCanvas.width = 16;
    dewCanvas.height = 16;
    const dctx = dewCanvas.getContext('2d');
    let grad = dctx.createRadialGradient(8, 8, 1, 8, 8, 7);
    grad.addColorStop(0, '#ffffff');
    grad.addColorStop(0.4, '#00ffcc');
    grad.addColorStop(0.8, '#ffea00');
    grad.addColorStop(1, 'transparent');
    dctx.fillStyle = grad;
    dctx.beginPath();
    dctx.arc(8, 8, 7, 0, Math.PI * 2);
    dctx.fill();
    scene.textures.addCanvas('item_honey_dew', dewCanvas);
  }
}
