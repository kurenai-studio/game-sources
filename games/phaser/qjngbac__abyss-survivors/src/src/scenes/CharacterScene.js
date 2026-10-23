import getData from '../data.js';
import meta from '../meta.js';
import audio from '../audio.js';

const FONT = '"Microsoft YaHei", "PingFang SC", sans-serif';

// 角色选择页：解锁 / 选择出战角色（主菜单「出战角色」进入）
export default class CharacterScene extends Phaser.Scene {
  constructor() { super('CharacterScene'); }

  create() {
    const W = this.scale.width, H = this.scale.height;
    const chars = getData(this, 'characters').list;
    const weapons = getData(this, 'weapons');

    this.add.rectangle(W / 2, H / 2, W, H, 0x1a1c2c);
    this.add.text(W / 2, 45, '出 战 角 色', {
      fontFamily: FONT, fontSize: '36px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0.5);
    this.add.text(W / 2, 75, '选择你的英雄出战 · 拥有各异的初始武器与能力特长', {
      fontFamily: FONT, fontSize: '13px', color: '#94b0c2'
    }).setOrigin(0.5);

    this.goldText = this.add.text(W - 24, 26, '', {
      fontFamily: FONT, fontSize: '21px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(1, 0);
    this.refreshGold();

    const back = this.add.text(45, 26, '← 返回', {
      fontFamily: FONT, fontSize: '20px', color: '#41a6f6'
    }).setOrigin(0, 0);
    back.setInteractive({ useHandCursor: true }).on('pointerdown', () => this.scene.start('MenuScene'));

    // 缩小单个角色选择框所占大小，使用 5 列 × 2 行紧凑网格展示全部 10 位角色
    chars.forEach((ch, i) => {
      const col = i % 5;
      const row = Math.floor(i / 5);
      const x = W / 2 + (col - 2) * 246;
      const y = 210 + row * 236;

      const unlocked = meta.isCharUnlocked(ch.id);
      const selected = meta.getCharacter() === ch.id;
      const wDef = weapons[ch.weapon] || {};
      const weaponName = wDef.name || ch.weapon;
      const wIcon = wDef.icon || 'icon-weapon-wand';

      const c = this.add.container(x, y);
      const borderColor = selected ? 0x41a6f6 : (unlocked ? 0xffcd75 : 0x3a3d52);
      const bg = this.add.rectangle(0, 0, 232, 222, unlocked ? 0x20222f : 0x14151f)
        .setStrokeStyle(selected ? 3 : (unlocked ? 2 : 1), borderColor);

      // 角色名称
      const name = this.add.text(0, -82, ch.name, {
        fontFamily: FONT, fontSize: '20px',
        color: unlocked ? (selected ? '#41a6f6' : '#ffcd75') : '#565a73', fontStyle: 'bold'
      }).setOrigin(0.5);

      // 武器图标与名称
      const wImg = this.add.image(-28, -50, wIcon).setDisplaySize(26, 26);
      if (!unlocked) wImg.setTint(0x565a73);
      const weaponT = this.add.text(12, -50, weaponName, {
        fontFamily: FONT, fontSize: '14px', color: unlocked ? '#ffcd75' : '#565a73', fontStyle: 'bold'
      }).setOrigin(0.5);

      // 属性特征标签
      const statsBadge = this.add.text(0, -18, ch.statsSummary || '', {
        fontFamily: FONT, fontSize: '11px', color: unlocked ? '#41a6f6' : '#4a4d63',
        align: 'center', wordWrap: { width: 216 }
      }).setOrigin(0.5);

      // 风格描述
      const desc = this.add.text(0, 20, ch.desc, {
        fontFamily: FONT, fontSize: '11px', color: unlocked ? '#94b0c2' : '#4a4d63',
        align: 'center', wordWrap: { width: 210 }, lineSpacing: 2
      }).setOrigin(0.5);

      c.add([bg, name, wImg, weaponT, statsBadge, desc]);

      // 状态与操作按钮
      if (selected) {
        const markBg = this.add.rectangle(0, 75, 140, 32, 0x1e3a2f).setStrokeStyle(1, 0x38b764);
        const mark = this.add.text(0, 75, '✓ 出战中', {
          fontFamily: FONT, fontSize: '15px', color: '#38b764', fontStyle: 'bold'
        }).setOrigin(0.5);
        c.add([markBg, mark]);
      } else if (unlocked) {
        const btn = this.add.rectangle(0, 75, 150, 32, 0x20222f).setStrokeStyle(2, 0x41a6f6);
        const bt = this.add.text(0, 75, '选 择 出 战', {
          fontFamily: FONT, fontSize: '14px', color: '#41a6f6', fontStyle: 'bold'
        }).setOrigin(0.5);
        btn.setInteractive({ useHandCursor: true }).on('pointerdown', () => {
          meta.setCharacter(ch.id);
          audio.click();
          this.scene.restart();
        });
        c.add([btn, bt]);
      } else {
        const affordable = meta.getGold() >= ch.cost;
        const btn = this.add.rectangle(0, 75, 160, 32, 0x20222f)
          .setStrokeStyle(2, affordable ? 0xffcd75 : 0x3a3d52);
        const bt = this.add.text(0, 75, `🔓 ${ch.cost} 金币`, {
          fontFamily: FONT, fontSize: '14px', color: affordable ? '#ffcd75' : '#565a73', fontStyle: 'bold'
        }).setOrigin(0.5);
        btn.setInteractive({ useHandCursor: affordable }).on('pointerdown', () => {
          if (!meta.spendGold(ch.cost)) {
            this.tweens.add({ targets: btn, x: btn.x - 8, duration: 45, yoyo: true, repeat: 3 });
            return;
          }
          meta.unlockCharacter(ch.id);
          meta.setCharacter(ch.id);
          audio.achievement();
          this.refreshGold();
          this.scene.restart();
        });
        c.add([btn, bt]);
      }
    });

    this.add.text(W / 2, H - 24, '可在「商店」购买永久强化，对所有角色与关卡生效', {
      fontFamily: FONT, fontSize: '13px', color: '#565a73'
    }).setOrigin(0.5);
  }

  refreshGold() {
    this.goldText.setText(`金 币　${meta.getGold()}`);
  }
}
