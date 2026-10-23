import getData from '../data.js';
import meta from '../meta.js';

const FONT = '"Microsoft YaHei", "PingFang SC", sans-serif';

// 成就：达成条件自动解锁并发金币奖励，此处为总览
export default class AchievementsScene extends Phaser.Scene {
  constructor() { super('AchievementsScene'); }

  create() {
    const W = this.scale.width, H = this.scale.height;
    const list = getData(this, 'achievements').list;

    this.add.rectangle(W / 2, H / 2, W, H, 0x1a1c2c);
    this.add.text(W / 2, 50, '成 就 殿 堂', {
      fontFamily: FONT, fontSize: '40px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0.5);

    const unlockedCount = list.filter(a => meta.isAchvUnlocked(a.id)).length;
    this.add.text(W / 2, 92, `已解锁 ${unlockedCount} / ${list.length}`, {
      fontFamily: FONT, fontSize: '15px', color: '#94b0c2'
    }).setOrigin(0.5);

    // 11 个成就：2 列 × 6 行（精简高度防止第 11 项超出屏幕）
    list.forEach((a, i) => {
      const col = i % 2, row = Math.floor(i / 2);
      const x = W / 2 + (col - 0.5) * 470;
      const y = 145 + row * 90;
      const got = meta.isAchvUnlocked(a.id);

      const c = this.add.container(x, y);
      const bg = this.add.rectangle(0, 0, 440, 78, got ? 0x252a38 : 0x1e2028)
        .setStrokeStyle(3, got ? 0x38b764 : 0x3a3d52);
      const mark = this.add.text(-195, 0, got ? '🏆' : '🔒', {
        fontFamily: FONT, fontSize: '28px'
      }).setOrigin(0.5);
      const name = this.add.text(-140, -18, a.name, {
        fontFamily: FONT, fontSize: '19px', color: got ? '#ffcd75' : '#565a73', fontStyle: 'bold'
      }).setOrigin(0, 0.5);
      const desc = this.add.text(-140, 14, a.desc, {
        fontFamily: FONT, fontSize: '13px', color: got ? '#94b0c2' : '#4a4d63'
      }).setOrigin(0, 0.5);
      const reward = this.add.text(175, 0, `+${a.reward}\n金币`, {
        fontFamily: FONT, fontSize: '16px', color: got ? '#38b764' : '#4a4d63',
        align: 'center', fontStyle: 'bold'
      }).setOrigin(0.5);
      c.add([bg, mark, name, desc, reward]);
    });

    const back = this.add.text(60, 26, '← 返回', {
      fontFamily: FONT, fontSize: '22px', color: '#41a6f6'
    }).setOrigin(0, 0);
    back.setInteractive({ useHandCursor: true }).on('pointerdown', () => this.scene.start('MenuScene'));
  }
}
