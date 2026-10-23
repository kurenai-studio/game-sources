import getData from '../data.js';
import meta from '../meta.js';

const FONT = '"Microsoft YaHei", "PingFang SC", sans-serif';

// 商店：金币购买永久强化（对局开始时生效），进度存 localStorage
export default class ShopScene extends Phaser.Scene {
  constructor() { super('ShopScene'); }

  create() {
    const W = this.scale.width, H = this.scale.height;
    const items = getData(this, 'shop').items;

    this.add.rectangle(W / 2, H / 2, W, H, 0x1a1c2c);
    this.add.text(W / 2, 40, '冒 险 商 店', {
      fontFamily: FONT, fontSize: '36px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0.5);
    this.add.text(W / 2, 72, '永久强化，购买后对所有模式与角色生效', {
      fontFamily: FONT, fontSize: '13px', color: '#94b0c2'
    }).setOrigin(0.5);

    this.goldText = this.add.text(W - 24, 26, '', {
      fontFamily: FONT, fontSize: '21px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(1, 0);
    this.refreshGold();

    // 12 项强化：3 列 × 4 行 紧凑网格
    items.forEach((it, i) => {
      const col = i % 3;
      const row = Math.floor(i / 3);
      const x = W / 2 + (col - 1) * 400;
      const y = 152 + row * 135;
      this.makeItemCard(it, x, y);
    });

    const back = this.add.text(45, 26, '← 返回', {
      fontFamily: FONT, fontSize: '20px', color: '#41a6f6'
    }).setOrigin(0, 0);
    back.setInteractive({ useHandCursor: true }).on('pointerdown', () => this.scene.start('MenuScene'));

    this.add.text(W / 2, H - 24, '金币可通过闯关、竞技场与击败 Boss 获得，死亡或通关时自动存入银行', {
      fontFamily: FONT, fontSize: '13px', color: '#565a73'
    }).setOrigin(0.5);
  }

  makeItemCard(it, x, y) {
    const lv = meta.getShopLevel(it.id);
    const maxed = lv >= it.max;
    const cost = maxed ? 0 : it.costs[lv];
    const affordable = meta.getGold() >= cost;
    const c = this.add.container(x, y);

    const bg = this.add.rectangle(0, 0, 382, 120, 0x20222f)
      .setStrokeStyle(maxed ? 2 : 1.5, maxed ? 0x38b764 : (affordable ? 0xffcd75 : 0x3a3d52));
    const icon = this.add.image(-148, 0, it.icon).setDisplaySize(46, 46);
    const title = this.add.text(-114, -34, `${it.name}　Lv ${lv}/${it.max}`, {
      fontFamily: FONT, fontSize: '17px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0, 0.5);
    const desc = this.add.text(-114, -6, it.desc, {
      fontFamily: FONT, fontSize: '12px', color: '#94b0c2', wordWrap: { width: 185 }
    }).setOrigin(0, 0.5);

    // 星级点亮
    let starStr = '';
    for (let s = 0; s < it.max; s++) starStr += s < lv ? '★' : '☆';
    const stars = this.add.text(-114, 26, starStr, {
      fontFamily: FONT, fontSize: '14px', color: '#ffcd75'
    }).setOrigin(0, 0.5);

    c.add([bg, icon, title, desc, stars]);

    if (maxed) {
      const maxBg = this.add.rectangle(138, 0, 78, 38, 0x1e3a2f).setStrokeStyle(1, 0x38b764);
      const buyText = this.add.text(138, 0, '已满级', { fontFamily: FONT, fontSize: '15px', color: '#38b764', fontStyle: 'bold' }).setOrigin(0.5);
      c.add([maxBg, buyText]);
    } else {
      const buyBg = this.add.rectangle(138, 0, 78, 42, 0x14151f).setStrokeStyle(1.5, affordable ? 0x41a6f6 : 0x3a3d52);
      const buyText = this.add.text(138, 0, `${cost}金\n购买`, {
        fontFamily: FONT, fontSize: '14px', color: affordable ? '#41a6f6' : '#565a73',
        align: 'center', fontStyle: 'bold'
      }).setOrigin(0.5);
      c.add([buyBg, buyText]);

      bg.setInteractive({ useHandCursor: true }).on('pointerdown', () => this.buy(it, c));
    }
  }

  buy(it, card) {
    const lv = meta.getShopLevel(it.id);
    if (lv >= it.max) return;
    const cost = it.costs[lv];
    if (!meta.spendGold(cost)) {
      // 金币不足：卡片抖一下
      this.tweens.add({ targets: card, x: card.x - 8, duration: 45, yoyo: true, repeat: 3 });
      return;
    }
    meta.setShopLevel(it.id, lv + 1);
    this.refreshGold();
    // 重建整个场景以刷新显示
    this.scene.restart();
  }

  refreshGold() {
    this.goldText.setText(`金 币　${meta.getGold()}`);
  }
}
